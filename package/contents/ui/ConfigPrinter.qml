import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_printerName: printerName.text
    property alias cfg_address: address.text
    property alias cfg_tintModelImage: tintModelImage.checked

    Kirigami.FormLayout {
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
        QQC2.CheckBox {
            id: tintModelImage
            text: qsTr("Tint model image with the theme highlight color")
        }
    }
}
