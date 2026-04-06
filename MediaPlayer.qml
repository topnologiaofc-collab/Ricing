import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "."

Item {
    id: root
    width: 64
    signal requestCloseOthers(string who)

    readonly property var activePlayer: {
        for (const p of Mpris.players) {
            if (p.playbackState === MprisPlaybackState.Playing)
                return p;
        }
        return Mpris.players.length > 0 ? Mpris.players[0] : null;
    }

    function msToClock(ms) {
        const s = Math.max(0, Math.floor(ms / 1000));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 5
        width: parent.width

        Rectangle {
            width: 44; height: 44; radius: 10
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(124/255,58/255,237/255,0.18)
            border.color: Qt.rgba(124/255,58/255,237/255,0.28)
            border.width: 1
            clip: true
            Image { anchors.fill: parent; source: root.activePlayer ? root.activePlayer.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; visible: source !== "" }
            Text { anchors.centerIn: parent; text: "◉"; color: Theme.accent; opacity: 0.45; font.pixelSize: 18; visible: !parent.children[0].visible }
        }

        Text {
            width: 50
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.activePlayer ? (root.activePlayer.trackTitle || "Sem mídia") : "Sem mídia"
            color: Theme.textPrimary
            font.pixelSize: 8
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        Text {
            width: 50
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.activePlayer ? (root.activePlayer.trackArtist || "") : ""
            color: Theme.textMuted
            font.pixelSize: 7
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 1

            Repeater {
                model: ["«", "mid", "»"]
                delegate: Rectangle {
                    width: modelData === "mid" ? 24 : 20
                    height: modelData === "mid" ? 24 : 20
                    radius: width / 2
                    color: (modelData === "mid") ? (midMouse.containsMouse ? Qt.rgba(124/255,58/255,237/255,0.38) : Qt.rgba(124/255,58/255,237/255,0.22)) : (midMouse.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent")
                    Text {
                        anchors.centerIn: parent
                        text: modelData === "mid"
                              ? ((root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing) ? "⏸" : "▶")
                              : modelData
                        color: modelData === "mid" ? Theme.accent : Theme.textMuted
                        font.pixelSize: modelData === "mid" ? 10 : 8
                    }
                    MouseArea {
                        id: midMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (!root.activePlayer)
                                return;
                            if (modelData === "«") {
                                if (typeof root.activePlayer.previous === "function")
                                    root.activePlayer.previous();
                            } else if (modelData === "»") {
                                if (typeof root.activePlayer.next === "function")
                                    root.activePlayer.next();
                            } else {
                                root.activePlayer.togglePlaying();
                            }
                        }
                    }
                }
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2
            Rectangle {
                id: progressBg
                width: 50
                height: 3
                radius: 2
                color: Qt.rgba(1,1,1,0.09)

                Rectangle {
                    width: {
                        if (!root.activePlayer || !root.activePlayer.length || root.activePlayer.length <= 0)
                            return 0;
                        return progressBg.width * Math.min(1, root.activePlayer.position / root.activePlayer.length);
                    }
                    height: parent.height
                    radius: 2
                    color: Theme.accent
                }

                Rectangle {
                    visible: hoverProgress.containsMouse
                    width: 11
                    height: 11
                    radius: 5.5
                    border.color: Theme.sidebarBg
                    border.width: 2
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                    x: (root.activePlayer && root.activePlayer.length > 0) ? Math.max(0, Math.min(parent.width - width, (root.activePlayer.position / root.activePlayer.length) * parent.width - width / 2)) : 0
                }

                MouseArea {
                    id: hoverProgress
                    anchors.fill: parent
                    hoverEnabled: true
                    onPressed: (m) => {
                        if (!root.activePlayer || !root.activePlayer.length || root.activePlayer.length <= 0)
                            return;
                        const ratio = Math.max(0, Math.min(1, m.x / width));
                        root.activePlayer.position = ratio * root.activePlayer.length;
                    }
                }
            }

            Row {
                width: 50
                anchors.horizontalCenter: parent.horizontalCenter
                Text { id: left; text: root.activePlayer ? msToClock(root.activePlayer.position) : "0:00"; color: Theme.textMuted; font.pixelSize: 6 }
                Item { width: Math.max(0, 50 - left.implicitWidth - right.implicitWidth); height: 1 }
                Text { id: right; text: root.activePlayer ? msToClock(root.activePlayer.length || 0) : "0:00"; color: Theme.textMuted; font.pixelSize: 6 }
            }
        }
    }
}
