pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: root
    property var jobs: []
    property bool tintModelImage: false
    Layout.minimumHeight: Kirigami.Units.gridUnit * 9
    spacing: Kirigami.Units.largeSpacing

    Kirigami.Heading {
        level: 4
        text: qsTr("Recent prints")
    }

    ListView {
        id: list
        objectName: "recentPrintList"
        visible: root.jobs.length > 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.jobs
        spacing: Kirigami.Units.largeSpacing
        boundsBehavior: Flickable.StopAtBounds
        Kirigami.WheelHandler {
            target: list
        }
        PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar {
            id: scrollbar
            objectName: "recentPrintScrollBar"
            width: Kirigami.Units.smallSpacing * 2
            leftPadding: 0
            rightPadding: 0
        }
        delegate: RowLayout {
            id: row
            required property var modelData
            width: list.width - (scrollbar.visible ? scrollbar.width + Kirigami.Units.smallSpacing : 0)
            spacing: Kirigami.Units.largeSpacing

            Item {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3

                Image {
                    id: thumbnail
                    objectName: "recentPrintThumbnail"
                    anchors.fill: parent
                    source: row.modelData.thumbnail
                    asynchronous: true
                    sourceSize.width: 128
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: root.tintModelImage
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: Kirigami.Theme.highlightColor
                    }
                }
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.medium
                    height: width
                    source: "draw-cuboid"
                    visible: thumbnail.status !== Image.Ready
                    opacity: 0.5
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: row.modelData.filename
                    elide: Text.ElideMiddle
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: filenameHover.hovered
                    HoverHandler { id: filenameHover }
                }
                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents.Label {
                        text: row.modelData.status
                        color: row.modelData.failed ? Kirigami.Theme.negativeTextColor
                            : Kirigami.Theme.disabledTextColor
                        font: Kirigami.Theme.smallFont
                    }
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: row.modelData.duration
                        horizontalAlignment: Text.AlignRight
                        color: Kirigami.Theme.disabledTextColor
                        font: Kirigami.Theme.smallFont
                    }
                }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: row.modelData.date
                    color: Kirigami.Theme.disabledTextColor
                    font: Kirigami.Theme.smallFont
                }
            }
        }
    }

    PlasmaComponents.Label {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.jobs.length === 0
        text: qsTr("No recent prints")
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: Kirigami.Theme.disabledTextColor
    }
}
