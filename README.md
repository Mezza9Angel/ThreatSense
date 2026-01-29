# ThreatSense

ThreatSense is a modern, lightweight threat display and warning addon for World of Warcraft.  
It provides a clean single-bar threat indicator, a multi-bar threat list, and a fully customizable warning system — all built using Blizzard’s modern Settings API.

## ✨ Features

### Threat Display
- Single-bar threat display
- Multi-bar threat list (TinyThreat-style)
- Display mode selector:
  - Single bar only
  - Single bar + list
  - List only (no main bar)
- Smooth animations (optional)
- Combat fade (optional)
- Rounded bar visuals
- Threat smoothing options

### Warnings
- Audio + visual threat warnings
- Warning levels: Warning / Danger / Critical
- Per-level color pickers
- Per-level sound dropdowns
- Cooldown slider
- Movable warning frame
- Custom warning text
- Pulse animation option
- Test Warning button
- Preview Warning Animation

### Configuration
- Modern Settings API integration
- Three configuration panels:
  - ThreatSense (parent)
  - ThreatSense – Display
  - ThreatSense – Warnings
- Bar textures dropdown
- Font dropdowns
- Color pickers
- Preview window
- Test Mode for display
- Reset to Defaults button

### Profiles & Overrides
- Per-role overrides (Tank / DPS / Healer)
- Per-spec profiles (optional)

### Convenience
- `/ts config` slash command
- Minimap button (optional)
- LibDataBroker launcher (optional)

## 📦 Installation

Place the `ThreatSense` folder into:
\World of Warcraft\_retail_\Interface\AddOns

## 🛠 Development

This addon is built with:
- Lua
- WoW’s modern Settings API
- No Ace3 required

## 📄 License

MIT License — see `LICENSE` for details.