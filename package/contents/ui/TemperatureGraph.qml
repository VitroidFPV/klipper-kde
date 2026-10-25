pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.quickcharts as Charts
import org.kde.quickcharts.controls as ChartsControls

ColumnLayout {
    id: root
    property var history: []
    property var status: ({})
    readonly property color extruderColor: Kirigami.Theme.negativeTextColor
    readonly property color bedColor: Kirigami.Theme.highlightColor
    spacing: Kirigami.Units.largeSpacing

    function degrees(value) {
        return typeof value === "number" && isFinite(value) ? value.toFixed(1) + " °C" : "—";
    }

    function series(key) {
        if (!history.length) return [];
        var values = [];
        var end = history[history.length - 1].time;
        var cursor = history.length - 1;
        for (var second = 0; second < 1200; ++second) {
            var time = end - second * 1000;
            while (cursor > 0 && history[cursor].time > time)
                --cursor;
            var sample = history[cursor];
            var value = sample[key];
            values.push(sample.time <= time && time - sample.time <= 30000
                && typeof value === "number" && isFinite(value) ? value : NaN);
        }
        return values;
    }

    function maximum() {
        var value = 100;
        for (var i = 0; i < history.length; ++i) {
            var sample = history[i];
            value = Math.max(value, sample.extruder || 0, sample.extruderTarget || 0,
                sample.bed || 0, sample.bedTarget || 0);
        }
        return Math.ceil(value / 50) * 50;
    }

    RowLayout {
        Layout.fillWidth: true
        PlasmaComponents.Label { Layout.fillWidth: true; text: qsTr("Temperature") }
        PlasmaComponents.Label {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
            horizontalAlignment: Text.AlignRight
            text: qsTr("Current")
        }
        PlasmaComponents.Label {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
            horizontalAlignment: Text.AlignRight
            text: qsTr("Target")
        }
    }

    Repeater {
        model: [
            { label: qsTr("Extruder"), data: root.status.extruder || {}, color: root.extruderColor },
            { label: qsTr("Heated bed"), data: root.status.heater_bed || {}, color: root.bedColor }
        ]
        delegate: RowLayout {
            id: temperatureRow
            required property var modelData
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            Rectangle {
                Layout.preferredWidth: Kirigami.Units.smallSpacing
                Layout.preferredHeight: Kirigami.Units.smallSpacing
                radius: Kirigami.Units.smallSpacing / 2
                color: temperatureRow.modelData.color
            }
            PlasmaComponents.Label { Layout.fillWidth: true; text: temperatureRow.modelData.label }
            PlasmaComponents.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                horizontalAlignment: Text.AlignRight
                text: root.degrees(temperatureRow.modelData.data.temperature)
            }
            PlasmaComponents.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                horizontalAlignment: Text.AlignRight
                text: root.degrees(temperatureRow.modelData.data.target)
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Kirigami.Units.gridUnit * 8
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing
            visible: root.history.length > 0

            ChartsControls.AxisLabels {
                Layout.fillHeight: true
                direction: ChartsControls.AxisLabels.VerticalBottomTop
                source: Charts.ChartAxisSource {
                    chart: chart
                    axis: Charts.ChartAxisSource.YAxis
                    itemCount: 5
                }
                delegate: QQC2.Label {
                    anchors.right: parent.right
                    font: Kirigami.Theme.smallFont
                    text: Math.round(ChartsControls.AxisLabels.label)
                    opacity: 0.65
                }
            }

            Charts.LineChart {
                id: chart
                objectName: "temperatureLineChart"
                Layout.fillWidth: true
                Layout.fillHeight: true
                direction: Charts.XYChart.ZeroAtEnd
                fillOpacity: 0.1
                lineWidth: 2
                xRange { automatic: false; from: 0; to: 1200 }
                yRange { automatic: false; from: 0; to: root.maximum() }
                colorSource: Charts.ArraySource {
                    array: [root.extruderColor, root.bedColor,
                        Qt.rgba(root.extruderColor.r, root.extruderColor.g, root.extruderColor.b, 0.4),
                        Qt.rgba(root.bedColor.r, root.bedColor.g, root.bedColor.b, 0.4)]
                }
                valueSources: [
                    Charts.ArraySource { array: root.series("extruder") },
                    Charts.ArraySource { array: root.series("bed") },
                    Charts.ArraySource { array: root.series("extruderTarget") },
                    Charts.ArraySource { array: root.series("bedTarget") }
                ]
                ChartsControls.GridLines {
                    anchors.fill: parent
                    z: -1
                    chart: chart
                    direction: ChartsControls.GridLines.Vertical
                    major.count: 5
                    major.color: Kirigami.ColorUtils.linearInterpolation(
                        Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.2)
                    minor.visible: false
                }
            }
        }

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            visible: root.history.length === 0
            text: qsTr("Waiting for temperature data…")
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit * 2
            visible: root.history.length > 0
            PlasmaComponents.Label {
                text: Qt.formatTime(new Date(root.history[root.history.length - 1].time - 20 * 60 * 1000), "hh:mm")
                font: Kirigami.Theme.smallFont
                color: Kirigami.Theme.disabledTextColor
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents.Label {
                text: Qt.formatTime(new Date(root.history[root.history.length - 1].time), "hh:mm")
                font: Kirigami.Theme.smallFont
                color: Kirigami.Theme.disabledTextColor
            }
        }
    }
}
