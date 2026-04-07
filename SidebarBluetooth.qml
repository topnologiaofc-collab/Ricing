import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "."

Item {
    id: root
    width: 76
    height: 36
    property bool open: false
    signal requestCloseOthers(string who)

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter ? adapter.powered : false

    Row {
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            id: btn
            width: 28
            height: 28
            radius: 8
            color: (root.open || mouse.containsMouse) && root.powered ? Qt.alpha(Theme.accent, 0.15) : "transparent"
            Text { anchors.centerIn: parent; text: "BT"; color: root.powered ? Theme.accent : Theme.textMuted; font.pixelSize: 10 }
            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.open = !root.open;
                    if (root.open)
                        root.requestCloseOthers("bt");
                }
            }
        }

        Text {
            text: root.powered ? "on" : "off"
            color: root.powered ? Theme.accent : Theme.textMuted
            font.pixelSize: 9
            verticalAlignment: Text.AlignVCenter
        }
    }

    PopupWindow {
        visible: root.open
        color: "transparent"
        anchor.window: root.QsWindow.window
        anchor.rect.x: Math.max(6, root.mapToItem(null, 0, 0).x - 4)
        anchor.rect.y: root.mapToItem(null, 0, 0).y + btn.height + 8
        implicitWidth: Theme.popupWidth
        implicitHeight: 180

        Rectangle {
            anchors.fill: parent
            radius: Theme.popupRadius
            color: Qt.rgba(11/255,15/255,25/255,0.96)
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "BLUETOOTH"; color: "#475569"; font.pixelSize: 9; font.letterSpacing: 1 }
                    Item { Layout.fillWidth: true }
                    Text { text: root.powered ? "ON" : "OFF"; color: Theme.accent; font.pixelSize: 8 }
                    Rectangle {
                        width: 26; height: 14; radius: 7
                        color: root.powered ? Qt.alpha(Theme.accent, 0.5) : Qt.rgba(1,1,1,0.1)
                        Rectangle {
                            width: 10; height: 10; radius: 5
                            y: 2
                            x: root.powered ? 13 : 3
                            color: root.powered ? "white" : Theme.textMuted
                            Behavior on x { NumberAnimation { duration: 150 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (root.adapter) root.adapter.powered = !root.adapter.powered
                        }
                    }
                }

                Repeater {
                    model: root.powered ? Bluetooth.devices : []
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: 8
                        color: modelData.connected ? Qt.alpha(Theme.accent, 0.18) : rowMouse.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8
                            Text { text: "◈"; color: modelData.connected ? Theme.accent : Theme.textMuted; font.pixelSize: 11 }
                            Column {
                                width: 136
                                Text { text: modelData.name || modelData.address; color: modelData.connected ? Theme.textPrimary : Qt.rgba(226/255,232/255,240/255,0.65); font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                                Text { text: modelData.icon || "device"; color: "#334155"; font.pixelSize: 8 }
                            }
                            Text { text: modelData.connected ? "✓" : ""; color: Theme.accent; font.pixelSize: 10 }
                        }
                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                        }
                    }
                }

                Text {
                    visible: root.powered && Bluetooth.devices.length === 0
                    text: "Nenhum dispositivo"
                    color: "#334155"
                    font.pixelSize: 10
                }

                Text {
                    visible: !root.powered
                    text: "Bluetooth desligado"
                    color: "#334155"
                    font.pixelSize: 10
                }
            }
        }
    }
}
