pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root
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
        command: ["bash", "-lc", "for f in \"$HOME/.config/Code/User/matugen-colors.json\" \"$HOME/.config/Code - OSS/User/matugen-colors.json\" \"$HOME/.config/hypr/colors.conf\" \"$HOME/.config/waybar/colors.css\" \"$HOME/.cache/wal/colors.json\"; do [ -f \"$f\" ] || continue; c=$(grep -Eio '(primary|accent|mauve|color7|tertiary)[^#]*#[0-9a-f]{6,8}' \"$f\" | grep -Eo '#[0-9A-Fa-f]{6,8}' | head -n1); [ -n \"$c\" ] || c=$(grep -Eo '#[0-9A-Fa-f]{6,8}' \"$f\" | head -n1); if [ -n \"$c\" ]; then echo \"$c\"; exit 0; fi; done; echo '#7c3aed'"]
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
