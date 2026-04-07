# Quickshell Sidebar (v0.2.0)

Pixel-faithful sidebar recreation from the provided HTML reference, adapted for Quickshell **0.2.0**.

## Files

- `shell.qml` — root `PanelWindow`, left/top/bottom anchored, exclusive zone enabled.
- `Theme.qml` — color + size tokens.
- `SidebarClock.qml` — clock widget and right-side calendar popup.
- `SidebarWorkspaces.qml` — Hyprland workspace indicators and switching.
- `SidebarMedia.qml` — MPRIS track data, controls, seek and progress.
- `SidebarWifi.qml` — sidebar Wi-Fi state + popup list and `nmcli` connect fallback.
- `SidebarBluetooth.qml` — sidebar Bluetooth state + popup with toggle/devices.
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
- Wi-Fi uses `nmcli` scanning/connection as a practical fallback path.
- Styling tokens mirror the provided design: radius, spacing, muted/primary text, and accent behavior.
