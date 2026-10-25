"""Exercise the real QML client against a local, read-only Moonraker mock.

Requires Qt 6's qml executable and Python's websockets package.
"""
import asyncio
import json
import os
from pathlib import Path
import shutil

from websockets.asyncio.server import serve

ROOT = Path(__file__).resolve().parents[1]


async def main():
    connections = 0
    subscriptions = 0
    methods = []

    async def handle(socket):
        nonlocal connections, subscriptions
        connections += 1
        connection = connections
        async for raw in socket:
            message = json.loads(raw)
            method = message["method"]
            methods.append(method)
            if method == "server.connection.identify":
                result = {"connection_id": connection}
            elif method == "server.info":
                result = {"klippy_state": "ready"}
            elif method == "server.history.totals":
                result = {"job_totals": {"total_jobs": 673}}
            elif method == "printer.objects.list":
                # Optional display_status is intentionally absent.
                result = {"objects": ["print_stats", "virtual_sdcard"]}
            elif method == "printer.objects.subscribe":
                subscriptions += 1
                assert set(message["params"]["objects"]) == {"print_stats", "virtual_sdcard"}
                result = {"status": {
                    "print_stats": {"filename": "test.gcode", "state": "printing",
                                    "info": {"current_layer": 1, "total_layer": 123}},
                    "virtual_sdcard": {"progress": 0.5},
                }}
            elif method == "server.files.metadata":
                result = {"filename": "test.gcode", "estimated_time": 5000}
            else:
                raise AssertionError(f"Unexpected API call: {method}")
            await socket.send(json.dumps({"jsonrpc": "2.0", "id": message["id"], "result": result}))
            if method == "printer.objects.subscribe":
                await asyncio.sleep(0.05)
                await socket.send(json.dumps({"jsonrpc": "2.0", "method": "notify_status_update",
                                             "params": [{"print_stats": {"info": {"current_layer": 25}}}, 10]}))
                if connection == 1:
                    await socket.close()
                    return
                if subscriptions == 2:
                    await socket.send(json.dumps({"method": "notify_klippy_disconnected"}))
                    await socket.send(json.dumps({"method": "notify_klippy_ready"}))
                    await socket.send(json.dumps({"method": "notify_history_changed", "params": [{"action": "finished"}]}))

    qml = shutil.which("qml") or "/usr/lib64/qt6/bin/qml"
    async with serve(handle, "127.0.0.1", 0) as server:
        port = server.sockets[0].getsockname()[1]
        env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_FORCE_STDERR_LOGGING="1",
                   QT_LOGGING_RULES="qml.debug=true", QML_DISABLE_DISK_CACHE="1")
        process = await asyncio.create_subprocess_exec(
            qml, str(ROOT / "tools/probe.qml"), "--", f"http://127.0.0.1:{port}",
            env=env, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.STDOUT)
        try:
            output, _ = await asyncio.wait_for(process.communicate(), timeout=20)
        finally:
            if process.returncode is None:
                process.kill()
                await process.wait()
        text = output.decode()
        assert process.returncode == 0, text
        snapshots = [json.loads(line.split("Status: ", 1)[1]) for line in text.splitlines() if "Status: {" in line]
        assert any(s["print_stats"]["info"] == {"current_layer": 25, "total_layer": 123}
                   and s["print_stats"]["filename"] == "test.gcode" for s in snapshots), text
        assert connections >= 2, (connections, text)
        assert subscriptions >= 3, (subscriptions, methods, text)
        assert 'History: {"total_jobs":673}' in text, text
        assert '"estimated_time":5000' in text, text
        assert methods.count("server.history.totals") >= 3, methods
        assert "Ready: false" in text, text
        print("PASS: live QML subscription, nested deltas, optional objects, metadata, history, reconnect and Klipper recovery")


if __name__ == "__main__":
    asyncio.run(main())
