import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root
    width: 28
    property bool open: false
    signal requestCloseOthers(string who)

    property var networks: []
    property string activeSsid: "--"

    function signalToLevel(v) {
        const n = Number(v);
        if (n >= 75) return 4;
        if (n >= 50) return 3;
        if (n >= 25) return 2;
        return 1;
    }

    function refresh() {
        scan.running = true;
    }

    Rectangle {
        id: btn
        width: 28
        height: 28
        radius: 8
        color: root.open || mouse.containsMouse ? Qt.rgba(124/255,58/255,237/255,0.15) : "transparent"
        Text { anchors.centerIn: parent; text: "W"; color: root.activeSsid !== "--" ? Theme.accent : Theme.textMuted; font.pixelSize: 11 }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                root.open = !root.open;
                if (root.open) {
                    root.requestCloseOthers("wifi");
                    root.refresh();
                }
            }
        }
    }

    Text {
        anchors.top: btn.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: btn.horizontalCenter
        width: 28
        text: (root.activeSsid || "--").slice(0, 5)
        color: root.activeSsid !== "--" ? Theme.accent : Theme.textMuted
        font.pixelSize: 7
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
    }

    Process {
        id: scan
        command: ["bash", "-lc", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan auto | head -n 10"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(Boolean);
                const list = [];
                let active = "--";
                for (const l of lines) {
                    const p = l.split(":");
                    const inUse = p[0].trim() === "*";
                    const ssid = p[1] || "(hidden)";
                    const signal = root.signalToLevel(p[2] || "0");
                    const secured = (p[3] || "").length > 0;
                    if (inUse) active = ssid;
                    list.push({ ssid, signal, secured, active: inUse });
                }
                root.networks = list;
                root.activeSsid = active;
            }
        }
    }

    Timer { interval: 15000; running: true; repeat: true; onTriggered: root.refresh() }

    PopupWindow {
        visible: root.open
        color: "transparent"
        anchor.window: root.QsWindow.window
        anchor.rect.x: Math.max(6, root.mapToItem(null, 0, 0).x - 4)
        anchor.rect.y: root.mapToItem(null, 0, 0).y + btn.height + 8
        implicitWidth: Theme.popupWidth
        implicitHeight: Math.max(120, 26 + root.networks.length * 28)

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

                Text { text: "WI-FI"; color: "#475569"; font.pixelSize: 9; font.letterSpacing: 1 }
                Repeater {
                    model: root.networks
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 24
                        radius: 8
                        color: modelData.active ? Qt.rgba(124/255,58/255,237/255,0.18) : rowMouse.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8

                            Row {
                                spacing: 1
                                anchors.verticalCenter: parent.verticalCenter
                                Repeater {
                                    model: 4
                                    delegate: Rectangle {
                                        width: 3
                                        height: [3,5,8,11][index]
                                        radius: 1
                                        anchors.bottom: parent.bottom
                                        color: modelData.active ? Theme.accent : (index < modelData.signal ? Theme.textMuted : Qt.rgba(100/255,116/255,139/255,0.2))
                                    }
                                }
                            }
                            Text { text: modelData.ssid; color: modelData.active ? Theme.textPrimary : Qt.rgba(226/255,232/255,240/255,0.7); font.pixelSize: 10; elide: Text.ElideRight; width: 120 }
                            Text { text: modelData.secured ? "🔒" : ""; color: "#334155"; font.pixelSize: 8 }
                            Text { text: modelData.active ? "✓" : ""; color: Theme.accent; font.pixelSize: 10 }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: connect.command = ["bash","-lc", `nmcli dev wifi connect '${modelData.ssid.replace(/'/g, "'\\''")}'`], connect.running = true
                        }
                    }
                }
            }
        }
    }

    Process { id: connect; stdout: StdioCollector { onStreamFinished: root.refresh() }; stderr: StdioCollector { onStreamFinished: root.refresh() } }
}
