import QtQuick
import QtQuick.Layouts
import Quickshell
import "."

PanelWindow {
    id: root
    anchors.left: true
    anchors.top: true
    anchors.bottom: true
    exclusiveZone: Theme.sidebarWidth + 8
    color: "transparent"

    implicitWidth: Theme.sidebarWidth + 16

    function closeOthers(name) {
        if (name !== "calendar") clock.open = false;
        if (name !== "wifi") wifi.open = false;
        if (name !== "bt") bt.open = false;
    }

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 0
        width: Theme.sidebarWidth
        radius: Theme.sidebarRadius
        color: Qt.rgba(13/255,17/255,23/255,0.85)
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 14
            anchors.bottomMargin: 10
            spacing: 0

            SidebarClock {
                id: clock
                Layout.alignment: Qt.AlignHCenter
                onRequestCloseOthers: (who) => root.closeOthers(who)
            }

            Rectangle { Layout.alignment: Qt.AlignHCenter; width: 36; height: 1; color: Theme.separator; Layout.topMargin: 6; Layout.bottomMargin: 6 }

            SidebarWorkspaces { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 2; Layout.bottomMargin: 2 }

            Rectangle { Layout.alignment: Qt.AlignHCenter; width: 36; height: 1; color: Theme.separator; Layout.topMargin: 6; Layout.bottomMargin: 6 }

            SidebarMedia { Layout.alignment: Qt.AlignHCenter }

            Item { Layout.fillHeight: true }

            Rectangle { Layout.alignment: Qt.AlignHCenter; width: 36; height: 1; color: Theme.separator; Layout.topMargin: 6; Layout.bottomMargin: 6 }

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4
                SidebarWifi { id: wifi; onRequestCloseOthers: (who) => root.closeOthers(who) }
                SidebarBluetooth { id: bt; onRequestCloseOthers: (who) => root.closeOthers(who) }
            }

            SidebarBattery { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 4 }
            Item { Layout.preferredHeight: 6 }
        }
    }
}
