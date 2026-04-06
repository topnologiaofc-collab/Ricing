# Quickshell Sidebar (v0.2.0)

Pixel-faithful sidebar recreation from the provided HTML reference, adapted for Quickshell **0.2.0**.

## Files

- `shell.qml` — root `PanelWindow`, left/top/bottom anchored, exclusive zone enabled.
- `Theme.qml` — color + size tokens.
- `Clock.qml` — clock widget and right-side calendar popup.
- `Workspaces.qml` — Hyprland workspace indicators and switching.
- `MediaPlayer.qml` — MPRIS track data, controls, seek and progress.
- `Wifi.qml` — sidebar Wi-Fi state + popup list and `nmcli` connect fallback.
- `Bluetooth.qml` — sidebar Bluetooth state + popup with toggle/devices.
- `Battery.qml` — battery indicator + percentage (UPower with fallback support).

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

- Popup windows are implemented with `PopupWindow` and anchored to the sidebar window.
- Wi-Fi uses `nmcli` scanning/connection as a practical fallback path.
- Styling tokens mirror the provided design: radius, spacing, muted/primary text, and accent behavior.
