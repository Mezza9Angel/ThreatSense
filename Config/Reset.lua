-- ThreatSense: Reset.lua
-- Reset active profile to defaults and reapply role-based defaults

local ADDON_NAME, TS = ...
local ConfigReset = {}
TS.ConfigReset = ConfigReset

local PM = TS.ProfileManager
local RM = TS.RoleManager

------------------------------------------------------------
-- Apply role-aware defaults to the active profile
------------------------------------------------------------
local function ApplyRoleDefaults()
    local role = RM:GetRole()

    local defaults = {
        TANK = {
            displayMode = "BAR_AND_LIST",
            enableWarnings = true,
            warningStyle = "ICON",
            barTexture = "",
            backgroundTexture = "",
            font = "",
            fontSize = 12,
            barColor = { r = 0.8, g = 0.1, b = 0.1, a = 1 },
            threatGradient = true,
            barHeight = 18,
            barSpacing = 2,
            rowHeight = 16,
            rowSpacing = 1,
            smoothSpeed = 0.2,
            combatFade = false,
            combatFadeOpacity = 0.4,
            warnTaunt = true,
            warnLosingAggro = true,
            warnAggroLost = true,
            warnPullingAggro = true,
            warnAggroPulled = true,
            warnDropThreat = true,
            tankLosingAggroThreshold = 80,
            dpsPullingAggroThreshold = 90,
            dpsDropThreatThreshold = 95,
            healerPullingAggroThreshold = 90,
            warningIconSize = 64,
            warningSound = "",
            warningVolume = 1,
        },

        HEALER = {
            displayMode = "LIST_ONLY",
            enableWarnings = true,
            warningStyle = "TEXT",
            barTexture = "",
            backgroundTexture = "",
            font = "",
            fontSize = 12,
            barColor = { r = 0.8, g = 0.1, b = 0.1, a = 1 },
            threatGradient = true,
            barHeight = 18,
            barSpacing = 2,
            rowHeight = 16,
            rowSpacing = 1,
            smoothSpeed = 0.2,
            combatFade = false,
            combatFadeOpacity = 0.4,
            warnTaunt = false,
            warnLosingAggro = false,
            warnAggroLost = false,
            warnPullingAggro = true,
            warnAggroPulled = false,
            warnDropThreat = false,
            tankLosingAggroThreshold = 80,
            dpsPullingAggroThreshold = 90,
            dpsDropThreatThreshold = 95,
            healerPullingAggroThreshold = 90,
            warningIconSize = 64,
            warningSound = "",
            warningVolume = 1,
        },

        DAMAGER = {
            displayMode = "BAR_ONLY",
            enableWarnings = true,
            warningStyle = "ICON",
            barTexture = "",
            backgroundTexture = "",
            font = "",
            fontSize = 12,
            barColor = { r = 0.8, g = 0.1, b = 0.1, a = 1 },
            threatGradient = true,
            barHeight = 18,
            barSpacing = 2,
            rowHeight = 16,
            rowSpacing = 1,
            smoothSpeed = 0.2,
            combatFade = false,
            combatFadeOpacity = 0.4,
            warnTaunt = false,
            warnLosingAggro = false,
            warnAggroLost = false,
            warnPullingAggro = true,
            warnAggroPulled = true,
            warnDropThreat = true,
            tankLosingAggroThreshold = 80,
            dpsPullingAggroThreshold = 90,
            dpsDropThreatThreshold = 95,
            healerPullingAggroThreshold = 90,
            warningIconSize = 64,
            warningSound = "",
            warningVolume = 1,
        }
    }

    local profile = PM:GetProfile()
    local roleDefaults = defaults[role]

    for key, value in pairs(roleDefaults) do
        profile[key] = value
    end
end

------------------------------------------------------------
-- Reset active profile
------------------------------------------------------------
local function ResetActiveProfile()
    ApplyRoleDefaults()

    TS.EventBus:Emit("PROFILE_RESET")
    TS.EventBus:Emit("PROFILE_CHANGED", PM:GetActiveProfileName())

    if TS.DisplayPreview:IsActive() then
        TS.DisplayPreview:Stop()
    end

    if TS.WarningPreview:IsActive() then
        TS.WarningPreview:Stop()
    end
end

------------------------------------------------------------
-- Initialize the Reset Panel
------------------------------------------------------------
function ConfigReset:Initialize()
    local category, layout = Settings.RegisterVerticalLayoutCategory("ThreatSense - Reset")
    self.category = category

    Settings.CreateControlButton(
        layout,
        "Reset Active Profile",
        "Reset all settings in the active profile and reapply role-based defaults.",
        function()
            ResetActiveProfile()
        end
    )

    Settings.RegisterAddOnCategory(category)
end