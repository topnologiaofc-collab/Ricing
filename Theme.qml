pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root
    visible: false
    readonly property color sidebarBg: "#0d1117"
    readonly property color popupBg: "#0b0f19"
    property color accent: accentSource
    readonly property color textPrimary: "#e2e8f0"
    readonly property color textMuted: "#64748b"
    readonly property color border: Qt.rgba(1, 1, 1, 0.12)
    readonly property color separator: Qt.rgba(1, 1, 1, 0.09)
    property color accentSource: "#7c3aed"

    readonly property int sidebarWidth: 64
    readonly property int sidebarRadius: 18
    readonly property int popupRadius: 14
    readonly property int buttonRadius: 8

    readonly property int popupWidth: 220

    Process {
        id: matugenProbe
        command: ["bash", "-lc", "python3 - <<'PY'\nimport json, os, re\npath = os.path.expanduser('~/.config/Code/User/matugen-colors.json')\nfallback = '#7c3aed'\ntry:\n    with open(path, 'r', encoding='utf-8') as f:\n        data = json.load(f)\n    wc = data.get('workbench.colorCustomizations', {})\n    raw = wc.get('focusBorder') or wc.get('editorCursor.foreground') or wc.get('list.activeSelectionForeground') or ''\n    m = re.search(r'#[0-9a-fA-F]{6,8}', str(raw))\n    print(m.group(0) if m else fallback)\nexcept Exception:\n    print(fallback)\nPY"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const c = text.trim();
                if (/^#[0-9a-fA-F]{6,8}$/.test(c))
                    root.accentSource = c;
            }
        }
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: matugenProbe.running = true
    }
}
