import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import "SampleData.js" as SampleData

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation

    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 17
        Layout.minimumHeight: Kirigami.Units.gridUnit * 24
        Layout.preferredWidth: Kirigami.Units.gridUnit * 21
        Layout.preferredHeight: Kirigami.Units.gridUnit * 28
        spacing: Kirigami.Units.largeSpacing

        PrinterCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            printer: SampleData.printer
            printerState: sampleState.currentText
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: qsTr("Sample data")
                color: Kirigami.Theme.textColor
                opacity: 0.65
                font: Kirigami.Theme.smallFont
            }
            PlasmaComponents.ComboBox {
                id: sampleState
                model: ["Printing", "Paused", "Idle", "Offline"]
                Accessible.name: qsTr("Sample printer state")
            }
        }
    }
}
