import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root
    width: 34
    height: 34

    property bool open: false
    property bool wifiOn: true
    property bool btOn: true
    property bool dndOn: false
    property var wifiNetworks: []
    property var btDevices: []

    function refreshWifi() { wifiScan.running = wifiOn; }
    function refreshBt() { btScan.running = btOn; }

    Rectangle {
        id: btn
        anchors.centerIn: parent
        width: 28; height: 28; radius: 8
        border.width: 1
        border.color: root.open ? Qt.alpha(Theme.accent, 0.6) : Qt.rgba(1,1,1,0.08)
        color: root.open || mouse.containsMouse ? Qt.alpha(Theme.accent, 0.16) : "transparent"
        Text { anchors.centerIn: parent; text: "⚙"; color: Theme.textPrimary; font.pixelSize: 11 }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                root.open = !root.open;
                if (root.open) {
                    root.refreshWifi();
                    root.refreshBt();
                }
            }
        }
    }

    PopupWindow {
        visible: root.open
        color: "transparent"
        anchor.window: root.QsWindow.window
        anchor.rect.x: ((root.parent ? root.parent.x : root.x) + root.width - Theme.popupWidth)
        anchor.rect.y: (root.parent ? root.parent.y : root.y) + root.height + 8
        implicitWidth: 220
        implicitHeight: contentCol.implicitHeight + 24

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(11/255,15/255,25/255,0.96)
            radius: 14
            border.width: 1
            border.color: Theme.border

            Column {
                id: contentCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text { text: "CONEXÕES"; color: "#475569"; font.pixelSize: 9; font.letterSpacing: 1 }

                // Wi-Fi row
                Row {
                    width: parent.width
                    spacing: 6
                    Text { text: "◉"; color: Theme.accent; font.pixelSize: 11 }
                    Text { text: "WI-FI"; color: Theme.textPrimary; font.pixelSize: 10 }
                    Item { width: parent.width - 80; height: 1 }
                    Rectangle {
                        width: 26; height: 14; radius: 7
                        color: root.wifiOn ? Qt.alpha(Theme.accent, 0.5) : Qt.rgba(1,1,1,0.1)
                        Rectangle { width: 10; height: 10; radius: 5; y: 2; x: root.wifiOn ? 13 : 3; color: root.wifiOn ? "white" : Theme.textMuted; Behavior on x { NumberAnimation { duration: 120 } } }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.wifiOn = !root.wifiOn;
                                wifiRadio.command = ["bash","-lc", root.wifiOn ? "nmcli radio wifi on" : "nmcli radio wifi off"];
                                wifiRadio.running = true;
                                root.refreshWifi();
                            }
                        }
                    }
                }

                Column {
                    visible: root.wifiOn
                    width: parent.width
                    spacing: 4
                    Repeater {
                        model: root.wifiNetworks
                        delegate: Rectangle {
                            width: parent.width
                            height: 24
                            radius: 8
                            color: modelData.active ? Qt.alpha(Theme.accent, 0.18) : wMouse.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8
                                Row {
                                    spacing: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    Repeater {
                                        model: 4
                                        delegate: Rectangle { width: 3; height: [3,5,8,11][index]; radius: 1; anchors.bottom: parent.bottom; color: modelData.active ? Theme.accent : (index < modelData.signal ? Theme.textMuted : Qt.rgba(100/255,116/255,139/255,0.2)) }
                                    }
                                }
                                Text { text: modelData.ssid; color: modelData.active ? Theme.accent : Qt.rgba(226/255,232/255,240/255,0.8); font.pixelSize: 10; width: 120; elide: Text.ElideRight }
                                Text { text: modelData.secured ? "🔒" : ""; color: "#334155"; font.pixelSize: 8 }
                                Text { text: modelData.active ? "✓" : ""; color: Theme.accent; font.pixelSize: 10 }
                            }
                            MouseArea {
                                id: wMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    wifiConnect.command = ["bash","-lc", `nmcli device wifi connect '${modelData.ssid.replace(/'/g, "'\\''")}'`];
                                    wifiConnect.running = true;
                                }
                            }
                        }
                    }
                }

                // Bluetooth row
                Row {
                    width: parent.width
                    spacing: 6
                    Text { text: "◈"; color: Theme.accent; font.pixelSize: 11 }
                    Text { text: "BLUETOOTH"; color: Theme.textPrimary; font.pixelSize: 10 }
                    Item { width: parent.width - 112; height: 1 }
                    Rectangle {
                        width: 26; height: 14; radius: 7
                        color: root.btOn ? Qt.alpha(Theme.accent, 0.5) : Qt.rgba(1,1,1,0.1)
                        Rectangle { width: 10; height: 10; radius: 5; y: 2; x: root.btOn ? 13 : 3; color: root.btOn ? "white" : Theme.textMuted; Behavior on x { NumberAnimation { duration: 120 } } }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.btOn = !root.btOn;
                                btPower.command = ["bash","-lc", root.btOn ? "bluetoothctl power on" : "bluetoothctl power off"];
                                btPower.running = true;
                                root.refreshBt();
                            }
                        }
                    }
                }

                Column {
                    visible: root.btOn
                    width: parent.width
                    spacing: 4
                    Repeater {
                        model: root.btDevices
                        delegate: Rectangle {
                            width: parent.width
                            height: 28
                            radius: 8
                            color: modelData.connected ? Qt.alpha(Theme.accent, 0.18) : bMouse.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8
                                Text { text: "◈"; color: modelData.connected ? Theme.accent : Theme.textMuted; font.pixelSize: 11 }
                                Column {
                                    width: 126
                                    Text { text: modelData.name; color: modelData.connected ? Theme.accent : Qt.rgba(226/255,232/255,240/255,0.8); font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                                    Text { text: modelData.type; color: "#334155"; font.pixelSize: 8 }
                                }
                                Text { text: modelData.connected ? "✓" : ""; color: Theme.accent; font.pixelSize: 10 }
                            }
                            MouseArea {
                                id: bMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    btConnect.command = ["bash", "-lc", modelData.connected ? `bluetoothctl disconnect ${modelData.mac}` : `bluetoothctl connect ${modelData.mac}`];
                                    btConnect.running = true;
                                }
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.07) }

                Text { text: "PREFERÊNCIAS"; color: "#475569"; font.pixelSize: 9; font.letterSpacing: 1 }
                Row {
                    width: parent.width
                    spacing: 6
                    Text { text: "🌙"; color: Theme.textPrimary; font.pixelSize: 10 }
                    Text { text: "NÃO PERTURBE"; color: Theme.textPrimary; font.pixelSize: 10 }
                    Item { width: parent.width - 126; height: 1 }
                    Rectangle {
                        width: 26; height: 14; radius: 7
                        color: root.dndOn ? Qt.alpha(Theme.accent, 0.5) : Qt.rgba(1,1,1,0.1)
                        Rectangle { width: 10; height: 10; radius: 5; y: 2; x: root.dndOn ? 13 : 3; color: root.dndOn ? "white" : Theme.textMuted; Behavior on x { NumberAnimation { duration: 120 } } }
                        MouseArea { anchors.fill: parent; onClicked: root.dndOn = !root.dndOn }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.07) }

                Text { text: "SISTEMA"; color: "#475569"; font.pixelSize: 9; font.letterSpacing: 1 }

                Repeater {
                    model: [
                        { icon: "🔒", label: "Bloquear", cmd: "hyprlock", danger: false },
                        { icon: "💤", label: "Suspender", cmd: "systemctl suspend", danger: false },
                        { icon: "🔁", label: "Reiniciar Hyprland", cmd: "hyprctl dispatch exit", danger: false },
                        { icon: "⏻", label: "Desligar", cmd: "systemctl poweroff", danger: true }
                    ]
                    delegate: Rectangle {
                        width: parent.width
                        height: 28
                        radius: 8
                        color: mouse.containsMouse ? (modelData.danger ? Qt.rgba(239/255,68/255,68/255,0.15) : Qt.rgba(1,1,1,0.06)) : "transparent"
                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8
                            Text { text: modelData.icon; color: mouse.containsMouse && modelData.danger ? "#ef4444" : Theme.textPrimary; font.pixelSize: 10 }
                            Text { text: modelData.label; color: mouse.containsMouse && modelData.danger ? "#ef4444" : Theme.textPrimary; font.pixelSize: 10 }
                        }
                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                sysExec.command = ["bash", "-lc", modelData.cmd];
                                sysExec.running = true;
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: wifiScan
        command: ["bash", "-lc", "nmcli -t -f SSID,SIGNAL,SECURITY,ACTIVE device wifi list --rescan auto | head -n 12"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(Boolean);
                root.wifiNetworks = lines.map(l => {
                    const p = l.split(":");
                    const sig = Number(p[1] || 0);
                    return {
                        ssid: p[0] || "(hidden)",
                        signal: sig >= 75 ? 4 : sig >= 50 ? 3 : sig >= 25 ? 2 : 1,
                        secured: (p[2] || "").length > 0,
                        active: (p[3] || "").trim().toLowerCase() === "yes"
                    };
                });
            }
        }
    }

    Process { id: wifiRadio }
    Process { id: wifiConnect; stdout: StdioCollector { onStreamFinished: root.refreshWifi() } }

    Process {
        id: btScan
        command: ["bash", "-lc", "bluetoothctl devices | awk '{mac=$2; $1=$2=\"\"; name=substr($0,3); print mac\"|\"name}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(Boolean);
                root.btDevices = lines.map(l => {
                    const p = l.split("|");
                    return { mac: p[0], name: p[1] || p[0], type: "Dispositivo", connected: false };
                });
                btStatus.running = true;
            }
        }
    }

    Process {
        id: btStatus
        command: ["bash", "-lc", "for mac in $(bluetoothctl devices | awk '{print $2}'); do c=$(bluetoothctl info $mac 2>/dev/null | awk -F': ' '/Connected/{print $2}'); echo \"$mac|$c\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const status = {};
                text.trim().split("\n").filter(Boolean).forEach(l => {
                    const p = l.split("|");
                    status[p[0]] = (p[1] || "").trim().toLowerCase() === "yes";
                });
                root.btDevices = root.btDevices.map(d => ({ mac: d.mac, name: d.name, type: d.type, connected: !!status[d.mac] }));
            }
        }
    }

    Process { id: btPower }
    Process {
        id: btConnect
        stdout: StdioCollector { onStreamFinished: root.refreshBt() }
        stderr: StdioCollector { onStreamFinished: root.refreshBt() }
    }

    Process { id: sysExec }

    Timer {
        interval: 12000
        running: true
        repeat: true
        onTriggered: {
            root.refreshWifi();
            root.refreshBt();
        }
    }
}
