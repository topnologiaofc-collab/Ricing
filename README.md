# Quickshell Sidebar (v0.2.0)

Pixel-faithful sidebar recreation from the provided HTML reference, adapted for Quickshell **0.2.0**.

## Files

- `shell.qml` — root `PanelWindow`, top/left/right anchored as a horizontal desktop bar, exclusive zone enabled.
- `Theme.qml` — color + size tokens.
- `SidebarClock.qml` — clock widget and downward calendar popup.
- `SidebarWorkspaces.qml` — Hyprland workspace indicators and switching.
- `SidebarMedia.qml` — horizontal MPRIS row: album art (play/pause on click), previous, progress, next.
- `QuickSettings.qml` — gear button + unified quick settings popup (Wi-Fi, Bluetooth, DND, system actions).
- `SidebarBattery.qml` — battery indicator + percentage (UPower with fallback support).

## Dependencies

- Quickshell `0.2.0`
- QtQuick / QtQuick.Layouts
- Modules:
  - `Quickshell`
  - `Quickshell.Hyprland`
  - `Quickshell.Services.Mpris`
  - `Quickshell.Services.UPower`
  - `Quickshell.Bluetooth`
  - `Quickshell.Io`
- System tools (for Wi-Fi fallback):
  - `nmcli`

## Run

From your Quickshell config entrypoint, load:

```qml
import "./shell.qml" as Sidebar

Sidebar {}
```

Or directly reference `shell.qml` in your active Quickshell configuration.

## Notes

- Popup windows are implemented with `PopupWindow` and anchored below the clicked widget (downward open).
- Accent color is synced from `~/.config/Code/User/matugen-colors.json` (`focusBorder` fallback chain) and auto-refreshes periodically.
- Quick settings uses `nmcli` and `bluetoothctl` fallbacks for network and Bluetooth controls.
- Styling tokens mirror the provided design: radius, spacing, muted/primary text, and accent behavior.
