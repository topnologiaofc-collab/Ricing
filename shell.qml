import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

PanelWindow {
    id: root
    anchors.left: true
    anchors.right: true
    anchors.top: true
    exclusiveZone: 84
    color: "transparent"

    implicitHeight: 84

    function closeOthers(name) {
        if (name !== "calendar" && clockLoader.item) clockLoader.item.open = false;
    }

    Process {
        id: matugenProbe
        command: ["bash", "-lc", "python3 - <<'PY'\nimport json, os, re\npath = os.path.expanduser('~/.config/Code/User/matugen-colors.json')\nfallback = '#7c3aed'\ntry:\n    with open(path, 'r', encoding='utf-8') as f:\n        data = json.load(f)\n    wc = data.get('workbench.colorCustomizations', {})\n    raw = wc.get('focusBorder') or wc.get('editorCursor.foreground') or wc.get('list.activeSelectionForeground') or ''\n    m = re.search(r'#[0-9a-fA-F]{6,8}', str(raw))\n    print(m.group(0) if m else fallback)\nexcept Exception:\n    print(fallback)\nPY"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const c = text.trim();
                if (/^#[0-9a-fA-F]{6,8}$/.test(c))
                    Theme.accent = c;
            }
        }
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: matugenProbe.running = true
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 0
        height: 76
        radius: Theme.sidebarRadius
        color: Qt.rgba(13/255,17/255,23/255,0.85)
        border.width: 1
        border.color: Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 0

            Loader {
                id: clockLoader
                Layout.alignment: Qt.AlignVCenter
                source: Qt.resolvedUrl("SidebarClock.qml")
                onLoaded: if (item && item.requestCloseOthers) item.requestCloseOthers.connect(root.closeOthers)
            }

            Rectangle { Layout.alignment: Qt.AlignVCenter; width: 1; height: 28; color: Theme.separator; Layout.leftMargin: 6; Layout.rightMargin: 6 }

            Loader { Layout.alignment: Qt.AlignVCenter; Layout.leftMargin: 2; Layout.rightMargin: 2; source: Qt.resolvedUrl("SidebarWorkspaces.qml") }

            Rectangle { Layout.alignment: Qt.AlignVCenter; width: 1; height: 28; color: Theme.separator; Layout.leftMargin: 6; Layout.rightMargin: 6 }

            Loader { Layout.alignment: Qt.AlignVCenter; source: Qt.resolvedUrl("SidebarMedia.qml") }

            Item { Layout.fillWidth: true }

            Loader { Layout.alignment: Qt.AlignVCenter; Layout.rightMargin: 8; source: Qt.resolvedUrl("QuickSettings.qml") }
            Loader { Layout.alignment: Qt.AlignVCenter; source: Qt.resolvedUrl("SidebarBattery.qml") }
        }
    }
}
