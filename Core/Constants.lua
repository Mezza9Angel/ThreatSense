-- Core/Constants.lua
-- Core constants and configuration values for ThreatSense

local ADDON_NAME, TS = ...

-- Version info
TS.VERSION = "0.1.0"
TS.ADDON_NAME = ADDON_NAME

-- Threat thresholds (percentage)
TS.THREAT_THRESHOLDS = {
    SAFE = 70,
    WARNING = 85,
    DANGER = 95,
    CRITICAL = 100
}

-- Colors (RGB 0-1 scale)
TS.COLORS = {
    SAFE = {0, 1, 0},
    WARNING = {1, 1, 0},
    DANGER = {1, 0.5, 0},
    CRITICAL = {1, 0, 0},
    TANK = {0.2, 0.5, 1},
    TEXT = {1, 1, 1},
    BACKGROUND = {0, 0, 0, 0.7}
}

-- Role-specific settings
TS.ROLE_SETTINGS = {
    TANK = {
        showWarnings = false,
        warningThreshold = 0,
        displayMode = "simple"
    },
    DAMAGER = {
        showWarnings = true,
        warningThreshold = 85,
        displayMode = "detailed"
    },
    HEALER = {
        showWarnings = true,
        warningThreshold = 90,
        displayMode = "detailed"
    }
}

-- Update frequency (seconds)
TS.UPDATE_INTERVAL = 0.1

-- Warning sound files
TS.SOUNDS = {
    WARNING = 8959,
    DANGER = 8960,
    CRITICAL = 12867
}

-- Display settings defaults
TS.DISPLAY_DEFAULTS = {
    enabled = true,
    locked = false,
    width = 200,
    height = 20,
    scale = 1.0,
    showText = true,
    showPercentage = true,
    maxEntries = 5,
    barTexture = "Blizzard",
    font = "Friz Quadrata TT",
    fontSize = 12
}

-- Default position
TS.DEFAULT_POSITION = {
    point = "CENTER",
    relativePoint = "CENTER",
    xOffset = 0,
    yOffset = -200
}