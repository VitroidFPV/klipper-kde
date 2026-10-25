import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_printerName: printerName.text
    property alias cfg_address: address.text

    QQC2.TextField {
        id: printerName
        Kirigami.FormData.label: qsTr("Printer name:")
    }
    QQC2.TextField {
        id: address
        Kirigami.FormData.label: qsTr("Moonraker URL:")
        placeholderText: "http://printer.local:7125"
        inputMethodHints: Qt.ImhUrlCharactersOnly
    }
}
