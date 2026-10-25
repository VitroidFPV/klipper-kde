import QtQuick
import "../package/contents/ui"
import "../package/contents/ui/PrinterData.js" as PrinterData

Item {
    id: probe
    property bool receivedStatus: false
    property int updates: 0
    property var args: Qt.application.arguments
    property int separator: args.indexOf("--")

    readonly property var printer: PrinterData.printer("Test printer", client.address, client.status,
        client.metadata, client.historyTotals, client.lastStatusAt, client.historyUpdatedAt, client.ready)
    onPrinterChanged: console.log("Card:", JSON.stringify(printer))

    MoonrakerClient {
        id: client
        address: probe.separator >= 0 ? probe.args[probe.separator + 1] : ""
        onErrorChanged: if (error) console.warn(error)
        onReadyChanged: console.log("Ready:", ready, "Klipper:", klippyState)
        onLastStatusAtChanged: {
            if (!lastStatusAt) return;
            probe.receivedStatus = true;
            probe.updates++;
            console.log("Status:", JSON.stringify(status));
        }
        onMetadataChanged: console.log("Metadata:", JSON.stringify(metadata))
        onHistoryTotalsChanged: console.log("History:", JSON.stringify(historyTotals))
        onTemperatureHistoryChanged: if (temperatureHistory.length > 1)
            console.log("Temperature history:", JSON.stringify({ length: temperatureHistory.length,
                first: temperatureHistory[0], last: temperatureHistory[temperatureHistory.length - 1] }))
    }

    Timer {
        interval: 12000
        running: true
        onTriggered: {
            console.log("Status snapshots/updates:", probe.updates);
            Qt.exit(probe.receivedStatus ? 0 : 1);
        }
    }
    Component.onCompleted: {
        if (!client.address) {
            console.error("Usage: qml tools/probe.qml -- http://printer-address");
            Qt.exit(1);
        }
    }
}
