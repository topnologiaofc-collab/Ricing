import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "."

Item {
    id: root
    width: 360
    height: 74

    readonly property var playersList: (Mpris.players && Mpris.players.values) ? Mpris.players.values : (Mpris.players || [])
    readonly property var spotifyPlayer: {
        for (const p of playersList) {
            const id = String(p.identity || p.desktopEntry || p.service || "").toLowerCase();
            if (id.includes("spotify"))
                return p;
        }
        return null;
    }

    property string cachedTitle: "Spotify"
    property string cachedArtist: ""
    property string cachedArtUrl: ""
    property real cachedPosition: 0
    property real cachedLength: 1
    property bool cachedPlaying: false

    readonly property string displayTitle: spotifyPlayer && spotifyPlayer.trackTitle ? spotifyPlayer.trackTitle : cachedTitle
    readonly property string displayArtist: spotifyPlayer && spotifyPlayer.trackArtist ? spotifyPlayer.trackArtist : cachedArtist
    readonly property string displayArtUrl: spotifyPlayer && spotifyPlayer.trackArtUrl ? spotifyPlayer.trackArtUrl : cachedArtUrl
    readonly property real displayLength: spotifyPlayer && spotifyPlayer.length > 0 ? spotifyPlayer.length : Math.max(1, cachedLength)
    readonly property real displayPosition: spotifyPlayer ? spotifyPlayer.position : cachedPosition
    readonly property bool isPlaying: spotifyPlayer ? (spotifyPlayer.playbackState === MprisPlaybackState.Playing) : cachedPlaying

    function msToClock(ms) {
        const s = Math.max(0, Math.floor(ms / 1000));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    function refreshCache() {
        if (!spotifyPlayer) return;
        if (spotifyPlayer.trackTitle) cachedTitle = spotifyPlayer.trackTitle;
        if (spotifyPlayer.trackArtist !== undefined) cachedArtist = spotifyPlayer.trackArtist;
        if (spotifyPlayer.trackArtUrl) cachedArtUrl = spotifyPlayer.trackArtUrl;
        if (spotifyPlayer.length > 0) cachedLength = spotifyPlayer.length;
        if (spotifyPlayer.position >= 0) cachedPosition = spotifyPlayer.position;
        cachedPlaying = spotifyPlayer.playbackState === MprisPlaybackState.Playing;
    }

    function doPlayPause() {
        if (spotifyPlayer) {
            if (typeof spotifyPlayer.playPause === "function") spotifyPlayer.playPause();
            else if (typeof spotifyPlayer.togglePlaying === "function") spotifyPlayer.togglePlaying();
        }
    }

    function doPrevious() {
        if (!spotifyPlayer) return;
        if (typeof spotifyPlayer.previous === "function") spotifyPlayer.previous();
    }

    function doNext() {
        if (!spotifyPlayer) return;
        if (typeof spotifyPlayer.next === "function") spotifyPlayer.next();
    }

    onSpotifyPlayerChanged: refreshCache()

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            root.refreshCache();
            if (!root.spotifyPlayer && root.cachedPlaying) {
                root.cachedPlaying = false;
            }
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            id: artBox
            width: 44
            height: 44
            radius: 10
            color: Qt.alpha(Theme.accent, 0.18)
            border.color: Qt.alpha(Theme.accent, 0.28)
            border.width: 1
            clip: true

            Image {
                id: artImg
                anchors.fill: parent
                source: root.displayArtUrl
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready && source !== ""
                onStatusChanged: if (status === Image.Error) source = ""
            }
            Text {
                anchors.centerIn: parent
                text: root.isPlaying ? "⏸" : "▶"
                color: Theme.accent
                font.pixelSize: 14
                visible: !artImg.visible
            }
            MouseArea { anchors.fill: parent; onClicked: root.doPlayPause() }
        }

        Rectangle {
            width: 24; height: 24; radius: 12
            color: prevMouse.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
            anchors.verticalCenter: artBox.verticalCenter
            Text { anchors.centerIn: parent; text: "«"; color: Theme.textMuted; font.pixelSize: 10 }
            MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.doPrevious() }
        }

        Column {
            width: 250
            anchors.verticalCenter: artBox.verticalCenter
            spacing: 3

            Row {
                spacing: 6
                Text {
                    width: root.displayArtist.length > 0 ? 150 : 240
                    text: root.displayTitle
                    color: Theme.textPrimary
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
                Text {
                    visible: root.displayArtist.length > 0
                    width: 90
                    text: root.displayArtist
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
                    width: progressBg.width * Math.min(1, Math.max(0, root.displayPosition / root.displayLength))
                    height: parent.height
                    radius: 2
                    color: Theme.accent
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: (m) => {
                        const ratio = Math.max(0, Math.min(1, m.x / width));
                        const pos = ratio * root.displayLength;
                        root.cachedPosition = pos;
                        if (root.spotifyPlayer && typeof root.spotifyPlayer.setPosition === "function")
                            root.spotifyPlayer.setPosition(pos);
                        else if (root.spotifyPlayer)
                            root.spotifyPlayer.position = pos;
                    }
                }
            }

            Row {
                width: parent.width
                Text { id: left; text: root.msToClock(root.displayPosition); color: Theme.textMuted; font.pixelSize: 7 }
                Item { width: Math.max(0, parent.width - left.implicitWidth - right.implicitWidth); height: 1 }
                Text { id: right; text: root.msToClock(root.displayLength); color: Theme.textMuted; font.pixelSize: 7 }
            }
        }

        Rectangle {
            width: 24; height: 24; radius: 12
            color: nextMouse.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
            anchors.verticalCenter: artBox.verticalCenter
            Text { anchors.centerIn: parent; text: "»"; color: Theme.textMuted; font.pixelSize: 10 }
            MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.doNext() }
        }
    }
}
