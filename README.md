# ThreatSense - World of Warcraft Threat Addon

A modern threat management addon designed to replace TinyThreat from Details!, providing comprehensive threat tracking for all roles and classes in World of Warcraft.

## Features

### Core Features
- **Real-time Threat Tracking** - Updates 10 times per second for accurate threat information
- **Role-Aware Display** - Automatically adjusts display based on your spec (Tank/DPS/Healer)
- **Multi-Target Support** - Ready for tracking threat on multiple enemies (M+ dungeons)
- **Smart Warnings** - Configurable audio and visual alerts when approaching threat cap
- **Draggable Display** - Position the threat bar anywhere on your screen
- **Lightweight** - Minimal performance impact

### Visual Features
- **Color-Coded Threat Bar** - Green → Yellow → Orange → Red as threat increases
- **Percentage Display** - Clear threat percentage overlay
- **Detailed Tooltips** - Hover to see full threat table for your group
- **Customizable Size** - Adjust width, height, and scale to your preference

### Warning System
- **Three Warning Levels** - Warning (85%), Danger (95%), Critical (100%)
- **Audio Alerts** - Uses WoW's built-in sound effects
- **Visual Alerts** - On-screen flash with threat percentage
- **Smart Cooldown** - Prevents alert spam

## Installation

### Manual Installation
1. Download or clone this repository
2. Copy the `ThreatSense` folder to your WoW addons directory:
   - **Windows**: `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\`
   - **Mac**: `/Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or reload UI (`/reload`)

### Note About Libraries
This addon currently runs in standalone mode without Ace3 libraries. For enhanced features in the future, you may want to download Ace3 libraries:
1. Download Ace3 from [CurseForge](https://www.curseforge.com/wow/addons/ace3)
2. Extract the libraries to the `Libs` folder in the ThreatSense directory

## Usage

### Slash Commands
- `/ts` or `/threatsense` - Show available commands
- `/ts toggle` - Enable/disable the addon
- `/ts lock` - Lock/unlock the display position
- `/ts reset` - Reset display to center of screen
- `/ts debug` - Toggle debug mode (for troubleshooting)

### Basic Usage
1. The threat bar appears automatically when you have a valid enemy target
2. Drag the bar to reposition it (unlock with `/ts lock` if needed)
3. Hover over the bar to see detailed threat information for your group
4. Configure warning thresholds by editing saved variables (GUI coming soon!)

### For Tanks
- Shows threat relative to the second-highest threat (how much threat buffer you have)
- No audio warnings (you're supposed to have aggro!)

### For DPS & Healers
- Shows threat relative to the tank or highest threat
- Audio and visual warnings when approaching threat cap
- Warning at 85%, Danger at 95%, Critical at 100%

## Configuration

### Current Configuration
Settings are stored in `SavedVariables/ThreatSense.lua` in your WoW folder.

You can edit these directly when WoW is closed, or use the slash commands listed above.

### Upcoming GUI
A full configuration interface using AceConfig is planned for a future release, which will allow you to:
- Adjust warning thresholds per role
- Customize colors and visual appearance
- Configure sound alerts
- Set up multiple profiles
- And much more!

## File Structure

```
ThreatSense/
├── ThreatSense.toc          # Addon metadata and file load order
├── ThreatSense.lua           # Main addon initialization
├── README.md                 # This file
├── Core/
│   ├── Constants.lua         # Global constants and defaults
│   └── Utils.lua            # Utility functions
├── Modules/
│   ├── ThreatEngine.lua     # Threat calculation and tracking
│   ├── Display.lua          # UI display system
│   ├── Warnings.lua         # Audio/visual warning system
│   └── Config.lua           # Configuration (placeholder)
└── Libs/                    # Optional: Ace3 libraries go here
```

## Development Roadmap

### Version 0.1.0 (Current)
- ✅ Basic threat tracking
- ✅ Simple bar display
- ✅ Warning system
- ✅ Slash commands
- ✅ Role detection

### Version 0.2.0 (Planned)
- [ ] AceConfig GUI integration
- [ ] Multiple display modes (compact, detailed, list)
- [ ] Threat projection (predict threat 2-3 seconds ahead)
- [ ] Multi-target display for M+ packs
- [ ] Custom color schemes

### Version 0.3.0 (Planned)
- [ ] WeakAuras integration
- [ ] Boss-specific profiles
- [ ] Threat cooldown suggestions
- [ ] Historical threat analysis
- [ ] Import/export profiles

## Known Issues
- Ace3 libraries are referenced but not required (will be optional until GUI is implemented)
- No GUI configuration yet (use slash commands)
- Multi-target display not yet implemented

## Contributing
This is an open-source project! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests
- Share your experience

## Credits
- Inspired by TinyThreat (Details! addon)
- Built for the WoW community
- Uses Blizzard's threat API

## License
This addon is provided as-is for free use by the World of Warcraft community.

## Support
For bugs, suggestions, or questions:
1. Check the README for solutions
2. Enable debug mode: `/ts debug`
3. Check your Lua errors with BugSack or similar addon
4. Report issues with details about your WoW version, other addons, and error messages

---

**Enjoy ThreatSense and may your tanks hold aggro!** 🛡️
