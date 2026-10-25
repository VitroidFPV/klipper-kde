import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: root
    required property var printer
    property string printerState: "Offline"
    property bool tintModelImage: false
    property var temperatureHistory: []
    property var temperatureStatus: ({})
    property bool showTemperatures: false
    QQC2.ButtonGroup {
        id: viewButtonGroup
        exclusive: true
    }
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
                objectName: "printerStateLabel"
                text: root.printerState
                color: root.printerState === "Error" || root.printerState === "Shutdown" ? Kirigami.Theme.negativeTextColor
                    : root.offline || root.printerState === "Connecting" ? Kirigami.Theme.disabledTextColor
                    : root.printerState === "Paused" ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.positiveTextColor
            }
        }
        PlasmaComponents.ToolButton {
            objectName: "modelViewButton"
            text: qsTr("Model")
            display: QQC2.AbstractButton.IconOnly
            icon.name: "draw-cuboid"
            checkable: true
            QQC2.ButtonGroup.group: viewButtonGroup
            checked: !root.showTemperatures
            onClicked: root.showTemperatures = false
            PlasmaComponents.ToolTip.text: text
            PlasmaComponents.ToolTip.visible: hovered
        }
        PlasmaComponents.ToolButton {
            objectName: "temperatureViewButton"
            text: qsTr("Graph")
            display: QQC2.AbstractButton.IconOnly
            icon.name: "view-media-chart"
            checkable: true
            QQC2.ButtonGroup.group: viewButtonGroup
            checked: root.showTemperatures
            onClicked: root.showTemperatures = true
            Accessible.name: qsTr("Temperature graph")
            PlasmaComponents.ToolTip.text: qsTr("Temperature graph")
            PlasmaComponents.ToolTip.visible: hovered
        }
        Kirigami.Heading {
            visible: root.hasJob
            level: 2
            text: Math.round(root.printer.progress * 100) + "%"
        }
    }

    PlasmaComponents.ProgressBar {
        objectName: "printProgress"
        Layout.fillWidth: true
        visible: root.hasJob
        value: root.printer.progress
        Accessible.name: qsTr("Print progress")
    }

    TemperatureGraph {
        objectName: "temperatureGraph"
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.showTemperatures
        history: root.temperatureHistory
        status: root.temperatureStatus
    }

    Image {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Kirigami.Units.gridUnit * 5
        Layout.preferredHeight: Kirigami.Units.gridUnit * 9
        visible: root.hasJob && !root.showTemperatures && source.toString().length > 0 && status !== Image.Error
        source: root.printer.thumbnail
        fillMode: Image.PreserveAspectFit
        sourceSize.width: 640
        Accessible.name: qsTr("Print preview")
        layer.enabled: root.tintModelImage
        layer.effect: MultiEffect {
            // Full colorization replaces the source hue; saturation would also desaturate the tint.
            colorization: 1.0
            colorizationColor: Kirigami.Theme.highlightColor
        }
    }

    PlasmaComponents.Label {
        objectName: "printFilename"
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
        objectName: "printStats"
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
            text: qsTr("Last updated: %1").arg(root.printer.lastUpdated)
            color: Kirigami.Theme.textColor
            opacity: 0.65
            font: Kirigami.Theme.smallFont
        }
    }

    Item {
        Layout.fillHeight: true
        visible: !root.hasJob && !root.showTemperatures
    }
}
