pragma Singleton
import QtQuick

QtObject {
    readonly property color sidebarBg: "#0d1117"
    readonly property color popupBg: "#0b0f19"
    readonly property color accent: "#7c3aed"
    readonly property color textPrimary: "#e2e8f0"
    readonly property color textMuted: "#64748b"
    readonly property color border: Qt.rgba(1, 1, 1, 0.12)
    readonly property color separator: Qt.rgba(1, 1, 1, 0.09)

    readonly property int sidebarWidth: 64
    readonly property int sidebarRadius: 18
    readonly property int popupRadius: 14
    readonly property int buttonRadius: 8

    readonly property int popupWidth: 220
}
