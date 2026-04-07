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
    property bool showButton: true
    property bool wifiOn: true
    property bool btOn: true
    property bool dndOn: false
    property bool nightOn: false
    property var wifiNetworks: []
    property var btDevices: []

    function refreshWifi() { if (wifiOn) wifiScan.running = true; }
    function refreshBt() { if (btOn) btScan.running = true; }

    Rectangle {
        id: button
        visible: root.showButton
        anchors.centerIn: parent
        width: 28
        height: 28
        radius: 8
        border.width: 1
        border.color: root.open ? Qt.alpha(Theme.accent, 0.6) : Qt.rgba(1,1,1,0.08)
        color: root.open ? Qt.alpha(Theme.accent, 0.18) : "transparent"
        Text { anchors.centerIn: parent; text: "⚙"; color: Theme.textPrimary; font.pixelSize: 11 }
        MouseArea {
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
        anchor.rect.x: (root.parent ? root.parent.x : root.x) + root.width - 240
        anchor.rect.y: (root.parent ? root.parent.y : root.y) + root.height + 8
        implicitWidth: 240
        implicitHeight: mainCol.implicitHeight + 28

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(11/255,15/255,25/255,0.97)
            border.width: 1
            border.color: Qt.rgba(1,1,1,0.12)
            radius: 14

            Column {
                id: mainCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text { text: "CONEXÕES"; font.pixelSize: 9; font.weight: Font.DemiBold; color: "#475569"; font.letterSpacing: 1.5 }

                // Wi-Fi row
                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 8
                    color: wifiHover.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
                    Row {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 10
                        Rectangle {
                            width: 28; height: 28; radius: 8
                            color: root.wifiOn ? Qt.alpha(Theme.accent, 0.2) : Qt.rgba(1,1,1,0.06)
                            Text { anchors.centerIn: parent; text: "W"; color: root.wifiOn ? Theme.accent : Theme.textMuted; font.pixelSize: 13; font.weight: Font.Bold }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: "Wi-Fi"; font.pixelSize: 11; color: Theme.textPrimary }
                            Text { text: root.wifiOn ? (root.wifiNetworks.find(n => n.active)?.ssid || "ligado") : "desligado"; font.pixelSize: 9; color: Theme.textMuted }
                        }
                        Item { width: parent.width - 150; height: 1 }
                        Rectangle {
                            width: 32; height: 17; radius: 9
                            color: root.wifiOn ? Qt.alpha(Theme.accent, 0.7) : Qt.rgba(1,1,1,0.12)
                            Rectangle {
                                width: 13; height: 13; radius: 6.5; y: 2
                                x: root.wifiOn ? 17 : 2
                                color: root.wifiOn ? "white" : Theme.textMuted
                                Behavior on x { NumberAnimation { duration: 200 } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.wifiOn = !root.wifiOn;
                                    wifiRadio.command = ["bash", "-lc", root.wifiOn ? "nmcli radio wifi on" : "nmcli radio wifi off"];
                                    wifiRadio.running = true;
                                    if (root.wifiOn) root.refreshWifi();
                                }
                            }
                        }
                    }
                    MouseArea { id: wifiHover; anchors.fill: parent; hoverEnabled: true }
                }

                Column {
                    visible: root.wifiOn
                    width: parent.width
                    spacing: 2
                    leftPadding: 8

                    Repeater {
                        model: root.wifiNetworks
                        delegate: Rectangle {
                            width: parent.width
                            height: 26
                            radius: 7
                            color: modelData.active ? Qt.alpha(Theme.accent, 0.15) : hover.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8
                                Row {
                                    spacing: 1.5
                                    anchors.verticalCenter: parent.verticalCenter
                                    Repeater {
                                        model: 4
                                        delegate: Rectangle {
                                            width: 2.5
                                            height: [3,5,8,11][index]
                                            radius: 1
                                            anchors.bottom: parent.bottom
                                            color: modelData.active ? Theme.accent : (index < modelData.signal ? Theme.textMuted : Qt.rgba(100/255,116/255,139/255,0.25))
                                        }
                                    }
                                }
                                Text { text: modelData.ssid; color: modelData.active ? Theme.textPrimary : Qt.rgba(226/255,232/255,240/255,0.7); font.pixelSize: 10; width: 136; elide: Text.ElideRight }
                                Text { text: modelData.secured ? "🔒" : ""; color: "#334155"; font.pixelSize: 8 }
                                Text { text: modelData.active ? "✓" : ""; color: Theme.accent; font.pixelSize: 10 }
                            }
                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    wifiConnect.command = ["bash", "-lc", `nmcli device wifi connect '${modelData.ssid.replace(/'/g, "'\\''")}'`];
                                    wifiConnect.running = true;
                                }
                            }
                        }
                    }
                }

                // Bluetooth row
                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 8
                    color: btHover.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
                    Row {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 10
                        Rectangle {
                            width: 28; height: 28; radius: 8
                            color: root.btOn ? Qt.alpha(Theme.accent, 0.2) : Qt.rgba(1,1,1,0.06)
                            Text { anchors.centerIn: parent; text: "B"; color: root.btOn ? Theme.accent : Theme.textMuted; font.pixelSize: 13; font.weight: Font.Bold }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: "Bluetooth"; font.pixelSize: 11; color: root.btOn ? Theme.textPrimary : Theme.textMuted }
                            Text { text: root.btOn ? "ligado" : "desligado"; font.pixelSize: 9; color: Theme.textMuted }
                        }
                        Item { width: parent.width - 170; height: 1 }
                        Rectangle {
                            width: 32; height: 17; radius: 9
                            color: root.btOn ? Qt.alpha(Theme.accent, 0.7) : Qt.rgba(1,1,1,0.12)
                            Rectangle {
                                width: 13; height: 13; radius: 6.5; y: 2
                                x: root.btOn ? 17 : 2
                                color: root.btOn ? "white" : Theme.textMuted
                                Behavior on x { NumberAnimation { duration: 200 } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.btOn = !root.btOn;
                                    btPower.command = ["bash", "-lc", root.btOn ? "bluetoothctl power on" : "bluetoothctl power off"];
                                    btPower.running = true;
                                    if (root.btOn) root.refreshBt();
                                }
                            }
                        }
                    }
                    MouseArea { id: btHover; anchors.fill: parent; hoverEnabled: true }
                }

                Column {
                    visible: root.btOn
                    width: parent.width
                    spacing: 2
                    leftPadding: 8

                    Repeater {
                        model: root.btDevices
                        delegate: Rectangle {
                            width: parent.width
                            height: 26
                            radius: 7
                            color: modelData.connected ? Qt.alpha(Theme.accent, 0.15) : hover.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8
                                Text { text: "◈"; color: modelData.connected ? Theme.accent : Theme.textMuted; font.pixelSize: 11; width: 14; horizontalAlignment: Text.AlignHCenter }
                                Text { text: modelData.name; color: modelData.connected ? Theme.textPrimary : Qt.rgba(226/255,232/255,240/255,0.7); font.pixelSize: 10; width: 140; elide: Text.ElideRight }
                                Text { text: modelData.connected ? "✓" : ""; color: Theme.accent; font.pixelSize: 10 }
                            }
                            MouseArea {
                                id: hover
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

                Text { text: "PREFERÊNCIAS"; font.pixelSize: 9; font.weight: Font.DemiBold; color: "#475569"; font.letterSpacing: 1.5 }

                // DND
                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 8
                    color: dndHover.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
                    Row {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 10
                        Rectangle { width: 28; height: 28; radius: 8; color: Qt.rgba(1,1,1,0.06); Text { anchors.centerIn: parent; text: "🌙"; color: Theme.textMuted; font.pixelSize: 12 } }
                        Text { text: "Não perturbe"; color: Theme.textPrimary; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: parent.width - 150; height: 1 }
                        Rectangle {
                            width: 32; height: 17; radius: 9
                            color: root.dndOn ? Qt.alpha(Theme.accent, 0.7) : Qt.rgba(1,1,1,0.12)
                            Rectangle { width: 13; height: 13; radius: 6.5; y: 2; x: root.dndOn ? 17 : 2; color: root.dndOn ? "white" : Theme.textMuted; Behavior on x { NumberAnimation { duration: 200 } } }
                            MouseArea { anchors.fill: parent; onClicked: root.dndOn = !root.dndOn }
                        }
                    }
                    MouseArea { id: dndHover; anchors.fill: parent; hoverEnabled: true }
                }

                // Night light
                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 8
                    color: nightHover.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
                    Row {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 10
                        Rectangle { width: 28; height: 28; radius: 8; color: Qt.rgba(1,1,1,0.06); Text { anchors.centerIn: parent; text: "☀"; color: Theme.textMuted; font.pixelSize: 12 } }
                        Column { anchors.verticalCenter: parent.verticalCenter; Text { text: "Night light"; color: Theme.textPrimary; font.pixelSize: 11 }; Text { text: "Redshift via hyprsunset"; color: Theme.textMuted; font.pixelSize: 9 } }
                        Item { width: parent.width - 180; height: 1 }
                        Rectangle {
                            width: 32; height: 17; radius: 9
                            color: root.nightOn ? Qt.alpha(Theme.accent, 0.7) : Qt.rgba(1,1,1,0.12)
                            Rectangle { width: 13; height: 13; radius: 6.5; y: 2; x: root.nightOn ? 17 : 2; color: root.nightOn ? "white" : Theme.textMuted; Behavior on x { NumberAnimation { duration: 200 } } }
                            MouseArea { anchors.fill: parent; onClicked: root.nightOn = !root.nightOn }
                        }
                    }
                    MouseArea { id: nightHover; anchors.fill: parent; hoverEnabled: true }
                }

                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.07) }

                Text { text: "SISTEMA"; font.pixelSize: 9; font.weight: Font.DemiBold; color: "#475569"; font.letterSpacing: 1.5 }

                Column {
                    width: parent.width
                    spacing: 2
                    Repeater {
                        model: [
                            { icon: "🔒", label: "Bloquear", cmd: "hyprlock", danger: false },
                            { icon: "💤", label: "Suspender", cmd: "systemctl suspend", danger: false },
                            { icon: "🔁", label: "Reiniciar Hyprland", cmd: "hyprctl dispatch exit", danger: false },
                            { icon: "⏻", label: "Desligar", cmd: "systemctl poweroff", danger: true }
                        ]
                        delegate: Rectangle {
                            width: parent.width
                            height: 34
                            radius: 8
                            color: hover.containsMouse ? (modelData.danger ? Qt.rgba(239/255,68/255,68/255,0.12) : Qt.rgba(1,1,1,0.06)) : "transparent"
                            Row {
                                anchors.fill: parent
                                anchors.margins: 7
                                spacing: 10
                                Rectangle { width: 28; height: 28; radius: 8; color: modelData.danger ? Qt.rgba(239/255,68/255,68/255,0.1) : Qt.rgba(1,1,1,0.06); Text { anchors.centerIn: parent; text: modelData.icon; color: modelData.danger ? "#ef4444" : Theme.textPrimary; font.pixelSize: 13 } }
                                Text { text: modelData.label; color: modelData.danger ? "#ef4444" : Theme.textPrimary; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea {
                                id: hover
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
