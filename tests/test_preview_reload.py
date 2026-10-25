"""Trigger the SDK refresh action in an isolated, offscreen preview.

Requires plasmoidviewer, dbus-run-session, and timeout.
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SHELL = Path("/usr/share/plasma/shells/org.kde.plasma.plasmoidviewershell")


def main():
    with tempfile.TemporaryDirectory(prefix="klipper-reload-") as temporary:
        temp = Path(temporary)
        shell = temp / "plasma/shells" / SHELL.name
        shutil.copytree(SHELL, shell)
        desktop = shell / "contents/views/Desktop.qml"
        source = desktop.read_text()
        # This is the same internal action used by the SDK's refresh button.
        timer = '''
    Timer {
        property int step: 0
        interval: 1500
        running: true
        repeat: true
        onTriggered: {
            const applets = root.containment?.plasmoid.applets;
            if (!applets || !applets.length) {
                console.warn("RELOAD_TEST: missing applet");
                running = false;
                return;
            }
            if (step === 0) {
                console.warn("RELOAD_TEST: trigger refresh");
                applets[0].internalAction("remove").trigger();
            } else {
                console.warn("RELOAD_TEST: refresh complete");
                running = false;
            }
            step++;
        }
    }
'''
        index = source.rfind("}")
        desktop.write_text(source[:index] + timer + source[index:])
        env = dict(
            os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
            QT_FORCE_STDERR_LOGGING="1", QT_LOGGING_RULES="qml.debug=true",
            TMPDIR=str(temp), XDG_CONFIG_HOME=str(temp / "config"),
            XDG_DATA_DIRS=str(temp) + ":" + os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share"),
        )
        log = temp / "output.log"
        with log.open("w") as output:
            result = subprocess.run(
                ["dbus-run-session", "--", "timeout", "6s", str(ROOT / "tools/preview.sh")],
                env=env, stdout=output, stderr=subprocess.STDOUT, timeout=15,
            )
        text = log.read_text()
        assert result.returncode in (0, 124), text
        assert "RELOAD_TEST: refresh complete" in text, text
        assert "RELOAD_TEST: missing applet" not in text, text
        assert "does not exist" not in text, text
        assert "error when loading applet" not in text, text
        widget_lines = [line for line in text.splitlines()
                        if str(ROOT) in line or "com.github.vitroidfpv.klipper-kde/" in line]
        assert not any(error in line for line in widget_lines
                       for error in ("TypeError:", "ReferenceError:",
                                     "Cannot assign to non-existent property")), text
        assert not list(temp.glob("klipper-kde-preview.*")), "Temporary package link was not removed"
        print("PASS: SDK refresh loads the widget by ID and removes the temporary package link")


if __name__ == "__main__":
    main()
