import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "."

Item {
    id: root
    width: 84
    height: 48
    property int fallbackPct: 0

    readonly property int pct: {
        if (UPower.displayDevice && UPower.displayDevice.isLaptopBattery)
            return Math.round(UPower.displayDevice.percentage * 100);
        return fallbackPct;
    }

    readonly property color battBorder: pct < 20 ? Qt.rgba(239/255, 68/255, 68/255, 0.8) : Qt.rgba(34/255, 197/255, 94/255, 0.8)

    Column {
        anchors.centerIn: parent
        spacing: 4

        Item {
            width: 30
            height: 16

            Rectangle {
                x: 0; y: 0; width: 26; height: 16; radius: 4
                border.width: 1.8
                border.color: root.battBorder
                color: "transparent"
            }
            Rectangle {
                x: 2.5; y: 3; width: Math.max(3, 20 * (root.pct / 100)); height: 10; radius: 2
                color: root.pct < 20 ? Qt.rgba(239/255, 68/255, 68/255, 0.65) : Qt.alpha(Theme.accent, 0.7)
            }
            Rectangle {
                x: 26; y: 5; width: 4; height: 6; radius: 1
                color: Qt.rgba(1,1,1,0.25)
            }
        }

        Text {
            text: `${root.pct}%`
            color: Theme.textPrimary
            font.pixelSize: 11
            font.weight: Font.Medium
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
