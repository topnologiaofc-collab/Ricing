import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "."

Item {
    id: root
    width: 220
    height: 30

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            model: 8
            delegate: Item {
                width: 26
                height: 22

                readonly property int wsId: index + 1
                readonly property var wsObj: Hyprland.workspaces.values.find(w => w.id === wsId)
                readonly property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                readonly property bool occupied: wsObj && wsObj.lastIpcObject && wsObj.lastIpcObject.windows > 0

                Rectangle {
                    anchors.centerIn: parent
                    width: isActive ? 24 : occupied ? 8 : 6
                    height: isActive ? 20 : occupied ? 8 : 6
                    radius: isActive ? 8 : width / 2
                    color: isActive ? Theme.accent : occupied ? Qt.rgba(1,1,1,0.14) : Qt.rgba(1,1,1,0.05)

                    Text {
                        visible: isActive
                        anchors.centerIn: parent
                        text: wsId
                        color: "white"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch(`workspace ${wsId}`)
                }
            }
        }
    }
}
