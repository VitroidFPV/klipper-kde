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
            elif method == "server.history.list":
                assert message["params"] == {"limit": 11, "order": "desc"}
                result = {"jobs": [{"job_id": "1", "filename": "recent.gcode",
                                    "status": "completed", "print_duration": 120,
                                    "end_time": 1700000000}]}
            elif method == "server.temperature_store":
                result = {
                    "extruder": {"temperatures": [200.0, 205.0, 210.0], "targets": [210.0, 215.0, 215.0]},
                    "heater_bed": {"temperatures": [59.0, 60.0], "targets": [60.0, 60.0]},
                }
            elif method == "printer.objects.list":
                # Optional display_status is intentionally absent.
                result = {"objects": ["print_stats", "virtual_sdcard", "extruder", "heater_bed"]}
            elif method == "printer.objects.subscribe":
                subscriptions += 1
                assert set(message["params"]["objects"]) == {
                    "print_stats", "virtual_sdcard", "extruder", "heater_bed"}
                result = {"status": {
                    "print_stats": {"filename": "test.gcode", "state": "printing",
                                    "info": {"current_layer": 1, "total_layer": 123}},
                    "virtual_sdcard": {"progress": 0.5},
                    "extruder": {"temperature": 210.0, "target": 215.0},
                    "heater_bed": {"temperature": 60.0, "target": 60.0},
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
        assert any(s.get("extruder", {}).get("temperature") == 210.0
                   and s.get("heater_bed", {}).get("target") == 60.0 for s in snapshots), text
        cards = [json.loads(line.split("Card: ", 1)[1]) for line in text.splitlines() if "Card: {" in line]
        assert any(card["filename"] == "test.gcode" and card["layer"] == "25 of 123"
                   and card["progress"] == 0.5 and card["slicer"] == "1h 23m" for card in cards), text
        assert connections >= 2, (connections, text)
        assert subscriptions >= 3, (subscriptions, methods, text)
        assert 'History: {"total_jobs":673}' in text, text
        assert '"estimated_time":5000' in text, text
        assert methods.count("server.history.totals") >= 3, methods
        assert methods.count("server.history.list") >= 3, methods
        recent = [json.loads(line.split("Recent jobs: ", 1)[1])
                  for line in text.splitlines() if "Recent jobs: [" in line]
        assert any(jobs and jobs[0]["filename"] == "recent.gcode" for jobs in recent), text
        assert methods.count("server.temperature_store") >= 1, methods
        temperatures = [json.loads(line.split("Temperature history: ", 1)[1])
                        for line in text.splitlines() if "Temperature history: {" in line]
        assert any(entry["length"] >= 3 and entry["first"]["extruder"] == 200.0
                   and "bed" not in entry["first"]
                   and entry["last"]["extruder"] == 210.0
                   and entry["last"]["bed"] == 60.0 for entry in temperatures), text
        assert "Ready: false" in text, text
        print("PASS: live QML subscription, temperature cache, nested deltas, metadata, history, reconnect and Klipper recovery")


if __name__ == "__main__":
    asyncio.run(main())
