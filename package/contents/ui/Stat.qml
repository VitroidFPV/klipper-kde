import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: root
    required property string label
    required property string value
    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents.Label {
        Layout.fillWidth: true
        text: root.label
        color: Kirigami.Theme.textColor
        opacity: 0.65
        font: Kirigami.Theme.smallFont
        elide: Text.ElideRight
    }
    PlasmaComponents.Label {
        Layout.fillWidth: true
        text: root.value
        font.weight: 600
        elide: Text.ElideRight
    }
}
