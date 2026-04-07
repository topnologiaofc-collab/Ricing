import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "."

Item {
    id: root
    width: 360
    height: 74

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

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            id: artBox
            width: 44
            height: 44
            radius: 10
            color: Qt.rgba(124/255,58/255,237/255,0.18)
            border.color: Qt.rgba(124/255,58/255,237/255,0.28)
            border.width: 1
            clip: true

            Image {
                anchors.fill: parent
                source: root.activePlayer ? root.activePlayer.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: source !== ""
            }
            Text {
                anchors.centerIn: parent
                text: (root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing) ? "⏸" : "▶"
                color: Theme.accent
                font.pixelSize: 14
                visible: !parent.children[0].visible
            }
            MouseArea {
                anchors.fill: parent
                onClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
            }
        }

        Rectangle {
            width: 24
            height: 24
            radius: 12
            color: prevMouse.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
            anchors.verticalCenter: artBox.verticalCenter
            Text { anchors.centerIn: parent; text: "«"; color: Theme.textMuted; font.pixelSize: 10 }
            MouseArea {
                id: prevMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (!root.activePlayer) return;
                    if (typeof root.activePlayer.previous === "function") root.activePlayer.previous();
                }
            }
        }

        Column {
            width: 250
            anchors.verticalCenter: artBox.verticalCenter
            spacing: 3

            Row {
                spacing: 6
                Text {
                    width: 150
                    text: root.activePlayer ? (root.activePlayer.trackTitle || "Sem mídia") : "Sem mídia"
                    color: Theme.textPrimary
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
                Text {
                    width: 90
                    text: root.activePlayer ? (root.activePlayer.trackArtist || "") : ""
                    color: Theme.textMuted
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                id: progressBg
                width: parent.width
                height: 4
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
                MouseArea {
                    anchors.fill: parent
                    onPressed: (m) => {
                        if (!root.activePlayer || !root.activePlayer.length || root.activePlayer.length <= 0)
                            return;
                        const ratio = Math.max(0, Math.min(1, m.x / width));
                        root.activePlayer.position = ratio * root.activePlayer.length;
                    }
                }
            }

            Row {
                width: parent.width
                Text { id: left; text: root.activePlayer ? msToClock(root.activePlayer.position) : "0:00"; color: Theme.textMuted; font.pixelSize: 7 }
                Item { width: Math.max(0, parent.width - left.implicitWidth - right.implicitWidth); height: 1 }
                Text { id: right; text: root.activePlayer ? msToClock(root.activePlayer.length || 0) : "0:00"; color: Theme.textMuted; font.pixelSize: 7 }
            }
        }

        Rectangle {
            width: 24
            height: 24
            radius: 12
            color: nextMouse.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
            anchors.verticalCenter: artBox.verticalCenter
            Text { anchors.centerIn: parent; text: "»"; color: Theme.textMuted; font.pixelSize: 10 }
            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (!root.activePlayer) return;
                    if (typeof root.activePlayer.next === "function") root.activePlayer.next();
                }
            }
        }
    }
}
