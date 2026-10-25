# klipper-kde

A KDE Plasma desktop widget for Klipper printers.

The Moonraker connection component is available. The widget interface and
installation package are not available yet.

## Connection

`package/contents/ui/MoonrakerClient.qml` uses Qt 6 and QtWebSockets.
Use one component for each printer.

```qml
MoonrakerClient {
    address: "http://printer.local/"
    onStatusChanged: console.log(JSON.stringify(status))
}
```

Set `address` to the Moonraker URL. If necessary, include port `7125`.
Set `apiKey` if the connection requires authentication.
Set `connectionEnabled` to `false` to disconnect.

The component supplies print status, file metadata, and history totals.
It connects again automatically after a connection failure.
Use `ready` to check that print status is current.

The component does not send printer control commands.
It keeps data in memory during a connection failure.
It does not save data between sessions or store credentials.

## Printer test

Qt 6 and QtWebSockets are required.
Replace the printer URL in this command.
Change the QML executable path if necessary.

```sh
QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 QT_LOGGING_RULES='qml.debug=true' \
    /usr/lib64/qt6/bin/qml tools/probe.qml -- http://printer.local/
```

The test shows printer data for 12 seconds, then stops.
Exit code `0` means that it received print status.
Exit code `1` means that it did not receive print status.

## Software checks

The connection test also requires the Python `websockets` package.
It uses a local test server.

```sh
/usr/lib64/qt6/bin/qmllint package/contents/ui/MoonrakerClient.qml tools/probe.qml
python3 tests/test_connection.py
```

See the [Moonraker API documentation](https://moonraker.readthedocs.io/en/latest/external_api/introduction/).
