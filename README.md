# klipper-kde

A KDE Plasma desktop widget for Klipper printers.

The widget shows live status and statistics from Moonraker.
Open the widget settings and set a printer name and Moonraker URL
(for example, `http://printer.local:7125`). Use one widget per printer.
Enable **Tint model image with the theme highlight color** in the widget settings
to fully desaturate the print preview and tint it with KDE’s current highlight color.
The widget currently connects to Moonraker instances that allow access from your
computer without authentication. API keys are supported by the standalone client,
but are not stored or configured by the widget.

## Installation

KDE Plasma 6 and QtWebSockets are required. From the repository directory, run:

```sh
kpackagetool6 --type Plasma/Applet --install ./package
```

This installs the widget for your user; no `sudo` is needed.
Right-click the desktop or panel, choose **Add Widgets**, and search for
**Klipper Printers**. Add it, then open its settings to enter the printer name
and Moonraker URL.

After changing the code, update the installed copy:

```sh
kpackagetool6 --type Plasma/Applet --upgrade ./package
```

Remove and re-add the widget to reload it. If Plasma retains old QML components,
log out and back in.

To uninstall:

```sh
kpackagetool6 --type Plasma/Applet --remove com.github.vitroidfpv.klipper-kde
```

## Widget preview

Qt 6 and the Plasma SDK are required.

```sh
./tools/preview.sh
```

Configure the printer through the preview’s widget settings.
The SDK refresh button recreates the widget, but can retain old QML components.
Close and reopen the preview to load file changes reliably.
The command uses a temporary package link. It does not install the widget.
The link is removed when the preview stops.

Edit `package/contents/ui/PrinterCard.qml` to change the layout.
Edit `package/contents/ui/PrinterData.js` to change how printer data is displayed.

## Connection

`package/contents/ui/MoonrakerClient.qml` uses Qt 6 and QtWebSockets.
It supplies the widget’s live data. Use one component for each printer.

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

Progress, layers, slicer filament usage, thumbnails, and history come from Moonraker.
Expected total time uses elapsed print time divided by progress, falling back to the
slicer estimate until progress is available. Finish time is hidden while paused.
Unavailable values show `—`. After a disconnection, history remains visible with
the last update time until the client reconnects.

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
python3 tests/test_preview_reload.py
QT_QPA_PLATFORM=offscreen /usr/lib64/qt6/bin/qmltestrunner -input tests/tst_printerdata.qml
```

See the [Moonraker API documentation](https://moonraker.readthedocs.io/en/latest/external_api/introduction/).
