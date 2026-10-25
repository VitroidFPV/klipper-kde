pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import "PrinterData.js" as PrinterData

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.configurationRequired: !Plasmoid.configuration.address.trim()

    MoonrakerClient {
        id: client
        address: Plasmoid.configuration.address
    }

    fullRepresentation: QQC2.Control {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 17
        Layout.minimumHeight: Kirigami.Units.gridUnit * 24
        Layout.preferredWidth: Kirigami.Units.gridUnit * 21
        Layout.preferredHeight: Kirigami.Units.gridUnit * 28
        padding: Kirigami.Units.largeSpacing

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            PrinterCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                printer: PrinterData.printer(Plasmoid.configuration.printerName, client.address,
                    client.status, client.metadata, client.historyTotals, client.lastStatusAt,
                    client.historyUpdatedAt, client.ready)
                printerState: PrinterData.state(client.ready, client.connected, client.klippyState, client.status)
                tintModelImage: Plasmoid.configuration.tintModelImage
                temperatureHistory: client.temperatureHistory
                temperatureStatus: client.status
                recentPrints: PrinterData.recentPrints(client.address, client.recentJobs)
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: text.length > 0
                text: client.error || (client.ready ? (client.status.print_stats || {}).message || ""
                    : client.connected ? qsTr("Waiting for Klipper (%1)…").arg(client.klippyState)
                    : qsTr("Connecting to Moonraker…"))
                wrapMode: Text.Wrap
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
            }
        }
    }
}
