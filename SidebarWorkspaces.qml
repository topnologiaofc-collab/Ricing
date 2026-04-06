import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "."

Item {
    id: root
    width: 64
    implicitHeight: wsCol.implicitHeight + 4

    Column {
        id: wsCol
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 5

        Repeater {
            model: 8
            delegate: Item {
                width: 32
                height: 26

                readonly property int wsId: index + 1
                readonly property var wsObj: Hyprland.workspaces.values.find(w => w.id === wsId)
                readonly property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                readonly property bool occupied: wsObj && wsObj.lastIpcObject && wsObj.lastIpcObject.windows > 0

                Rectangle {
                    anchors.centerIn: parent
                    width: isActive ? 28 : occupied ? 8 : 6
                    height: isActive ? 22 : occupied ? 8 : 6
                    radius: isActive ? 8 : width / 2
                    color: isActive ? Theme.accent : occupied ? Qt.rgba(1,1,1,0.14) : Qt.rgba(1,1,1,0.05)

                    Text {
                        visible: isActive
                        anchors.centerIn: parent
                        text: wsId
                        color: "white"
                        font.pixelSize: 11
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
