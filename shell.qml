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
        if (name !== "calendar" && clockLoader.item) clockLoader.item.open = false;
        if (name !== "wifi" && wifiLoader.item) wifiLoader.item.open = false;
        if (name !== "bt" && btLoader.item) btLoader.item.open = false;
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

            Loader {
                id: clockLoader
                Layout.alignment: Qt.AlignHCenter
                source: Qt.resolvedUrl("SidebarClock.qml")
                onLoaded: if (item && item.requestCloseOthers) item.requestCloseOthers.connect(root.closeOthers)
            }

            Rectangle { Layout.alignment: Qt.AlignHCenter; width: 36; height: 1; color: Theme.separator; Layout.topMargin: 6; Layout.bottomMargin: 6 }

            Loader { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 2; Layout.bottomMargin: 2; source: Qt.resolvedUrl("SidebarWorkspaces.qml") }

            Rectangle { Layout.alignment: Qt.AlignHCenter; width: 36; height: 1; color: Theme.separator; Layout.topMargin: 6; Layout.bottomMargin: 6 }

            Loader { Layout.alignment: Qt.AlignHCenter; source: Qt.resolvedUrl("SidebarMedia.qml") }

            Item { Layout.fillHeight: true }

            Rectangle { Layout.alignment: Qt.AlignHCenter; width: 36; height: 1; color: Theme.separator; Layout.topMargin: 6; Layout.bottomMargin: 6 }

            Row {
                Layout.alignment: Qt.AlignHCenter
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

            Loader { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 4; source: Qt.resolvedUrl("SidebarBattery.qml") }
            Item { Layout.preferredHeight: 6 }
        }
    }
}
