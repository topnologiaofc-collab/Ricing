import QtQuick
import QtQuick.Layouts
import Quickshell
import "."

PanelWindow {
    id: root
    anchors.left: true
    anchors.right: true
    anchors.top: true
    exclusiveZone: 148
    color: "transparent"

    implicitHeight: 148

    function closeOthers(name) {
        if (name !== "calendar" && clockLoader.item) clockLoader.item.open = false;
        if (name !== "wifi" && wifiLoader.item) wifiLoader.item.open = false;
        if (name !== "bt" && btLoader.item) btLoader.item.open = false;
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 0
        height: 136
        radius: Theme.sidebarRadius
        color: Qt.rgba(13/255,17/255,23/255,0.85)
        border.width: 1
        border.color: Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 0

            Loader {
                id: clockLoader
                Layout.alignment: Qt.AlignVCenter
                source: Qt.resolvedUrl("SidebarClock.qml")
                onLoaded: if (item && item.requestCloseOthers) item.requestCloseOthers.connect(root.closeOthers)
            }

            Rectangle { Layout.alignment: Qt.AlignVCenter; width: 1; height: 36; color: Theme.separator; Layout.leftMargin: 6; Layout.rightMargin: 6 }

            Loader { Layout.alignment: Qt.AlignVCenter; Layout.leftMargin: 2; Layout.rightMargin: 2; source: Qt.resolvedUrl("SidebarWorkspaces.qml") }

            Rectangle { Layout.alignment: Qt.AlignVCenter; width: 1; height: 36; color: Theme.separator; Layout.leftMargin: 6; Layout.rightMargin: 6 }

            Loader { Layout.alignment: Qt.AlignVCenter; source: Qt.resolvedUrl("SidebarMedia.qml") }

            Rectangle { Layout.alignment: Qt.AlignVCenter; width: 1; height: 36; color: Theme.separator; Layout.leftMargin: 6; Layout.rightMargin: 6 }

            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 4
                Loader {
                    id: wifiLoader
                    source: Qt.resolvedUrl("SidebarWifi.qml")
                    onLoaded: if (item && item.requestCloseOthers) item.requestCloseOthers.connect(root.closeOthers)
                }
                Loader {
                    id: btLoader
                    source: Qt.resolvedUrl("SidebarBluetooth.qml")
                    onLoaded: if (item && item.requestCloseOthers) item.requestCloseOthers.connect(root.closeOthers)
                }
            }

            Loader { Layout.alignment: Qt.AlignVCenter; Layout.leftMargin: 8; source: Qt.resolvedUrl("SidebarBattery.qml") }
        }
    }
}
