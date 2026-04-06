import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "."

Item {
    id: root
    width: 64
    property int fallbackPct: 0

    readonly property int pct: {
        if (UPower.displayDevice && UPower.displayDevice.isLaptopBattery)
            return Math.round(UPower.displayDevice.percentage * 100);
        return fallbackPct;
    }

    readonly property color battColor: pct < 20 ? "#ef4444" : "#22c55e"
    readonly property color battBorder: pct < 20 ? Qt.rgba(239/255, 68/255, 68/255, 0.65) : Qt.rgba(34/255, 197/255, 94/255, 0.65)

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 3
        topPadding: 4

        Item {
            width: 22
            height: 11

            Rectangle {
                x: 0; y: 0; width: 19; height: 11; radius: 3
                border.width: 1.5
                border.color: root.battBorder
                color: "transparent"
            }
            Rectangle {
                x: 2; y: 2; width: Math.max(2, 15 * (root.pct / 100)); height: 7; radius: 2
                color: Qt.rgba(1,1,1,0.5)
            }
            Rectangle {
                x: 19; y: 3; width: 3; height: 5; radius: 1
                color: Qt.rgba(1,1,1,0.25)
            }
        }

        Text {
            text: `${root.pct}%`
            color: Theme.textPrimary
            font.pixelSize: 9
            font.weight: Font.Medium
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
