-- ThreatSense: Constants.lua
-- Core immutable constants for ThreatSense

local ADDON_NAME, TS = ...

------------------------------------------------------------
-- Addon metadata
------------------------------------------------------------
TS.VERSION = "0.1.0"
TS.ADDON_NAME = ADDON_NAME

------------------------------------------------------------
-- Threat thresholds (percentage)
-- Used by ThreatEngine and UI color logic
------------------------------------------------------------
TS.THREAT_THRESHOLDS = {
    SAFE     = 70,
    WARNING  = 85,
    DANGER   = 95,
    CRITICAL = 100,
}

------------------------------------------------------------
-- Core colors (RGB 0–1 scale)
-- UI modules may reference these for fallback values
------------------------------------------------------------
TS.COLORS = {
    SAFE       = { 0,   1,   0   },
    WARNING    = { 1,   1,   0   },
    DANGER     = { 1,   0.5, 0   },
    CRITICAL   = { 1,   0,   0   },
    TANK       = { 0.2, 0.5, 1   },
    TEXT       = { 1,   1,   1   },
    BACKGROUND = { 0,   0,   0, 0.7 },
}

------------------------------------------------------------
-- Update frequency (seconds)
-- Used by ThreatEngine and WarningEngine
------------------------------------------------------------
TS.UPDATE_INTERVAL = 0.1

------------------------------------------------------------
-- Default UI anchor position
-- Used by ThreatBar and ThreatList when no profile data exists
------------------------------------------------------------
TS.DEFAULT_POSITION = {
    point = "CENTER",
    relativePoint = "CENTER",
    xOffset = 0,
    yOffset = -200,
}