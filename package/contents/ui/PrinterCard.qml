import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: root
    required property var printer
    property string printerState: "Printing"
    readonly property bool hasJob: printerState === "Printing" || printerState === "Paused"
    readonly property bool offline: printerState === "Offline"
    spacing: Kirigami.Units.largeSpacing

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Heading {
                Layout.fillWidth: true
                level: 3
                text: root.printer.name
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                text: root.printerState
                color: root.offline ? Kirigami.Theme.disabledTextColor : root.printerState === "Paused" ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.positiveTextColor
            }
        }
        Kirigami.Heading {
            visible: root.hasJob
            level: 2
            text: Math.round(root.printer.progress * 100) + "%"
        }
    }

    PlasmaComponents.ProgressBar {
        Layout.fillWidth: true
        visible: root.hasJob
        value: root.printer.progress
        Accessible.name: qsTr("Print progress")
    }

    Image {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Kirigami.Units.gridUnit * 5
        Layout.preferredHeight: Kirigami.Units.gridUnit * 9
        visible: root.hasJob
        source: root.printer.thumbnail
        fillMode: Image.PreserveAspectFit
        sourceSize.width: 640
        Accessible.name: qsTr("Sample print: two storage bins")
    }

    PlasmaComponents.Label {
        Layout.fillWidth: true
        visible: root.hasJob
        text: root.printer.filename
        elide: Text.ElideMiddle
        maximumLineCount: 1
        PlasmaComponents.ToolTip.text: text
        PlasmaComponents.ToolTip.visible: filenameHover.hovered
        HoverHandler {
            id: filenameHover
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    GridLayout {
        Layout.fillWidth: true
        visible: root.hasJob
        columns: 3
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.largeSpacing

        Stat {
            Layout.fillWidth: true
            label: qsTr("Filament")
            value: root.printer.filament
        }
        Stat {
            Layout.fillWidth: true
            label: qsTr("Layer")
            value: root.printer.layer
        }
        Stat {
            Layout.fillWidth: true
            label: qsTr("Remaining")
            value: root.printer.remaining
        }
        Stat {
            Layout.fillWidth: true
            label: qsTr("Slicer estimate")
            value: root.printer.slicer
        }
        Stat {
            Layout.fillWidth: true
            label: qsTr("Expected total")
            value: root.printer.total
        }
        Stat {
            Layout.fillWidth: true
            label: qsTr("Finish time")
            value: root.printerState === "Paused" ? "—" : root.printer.eta
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: !root.hasJob
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Heading {
            level: 4
            text: qsTr("Statistics")
        }
        Repeater {
            model: root.printer.history
            delegate: RowLayout {
                id: historyRow
                required property var modelData
                Layout.fillWidth: true
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: historyRow.modelData.label
                    color: Kirigami.Theme.textColor
                    opacity: 0.65
                }
                PlasmaComponents.Label {
                    text: historyRow.modelData.value
                }
            }
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            visible: root.offline
            text: qsTr("Last updated: 25 Oct, 16:08")
            color: Kirigami.Theme.textColor
            opacity: 0.65
            font: Kirigami.Theme.smallFont
        }
    }

    Item {
        Layout.fillHeight: true
        visible: !root.hasJob
    }
}
