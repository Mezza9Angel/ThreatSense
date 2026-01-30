-- ThreatSense: Init.lua
-- Central initialization and module loading

local ADDON_NAME, TS = ...

------------------------------------------------------------
-- Export addon namespace globally
------------------------------------------------------------
_G.TS = TS
TS.name = ADDON_NAME
TS.VERSION = "0.2.1"

------------------------------------------------------------
-- Namespace Setup
------------------------------------------------------------
TS.Core = TS.Core or {}
local Core = TS.Core

TS.db = TS.db or nil

------------------------------------------------------------
-- Event Frame
------------------------------------------------------------
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == ADDON_NAME then
            Core:OnAddonLoaded()
        end

    elseif event == "PLAYER_LOGIN" then
        Core:OnPlayerLogin()
    end
end)

------------------------------------------------------------
-- ADDON_LOADED
-- Load saved variables, initialize systems, register config
------------------------------------------------------------
function Core:OnAddonLoaded()
    --------------------------------------------------------
    -- Saved variables
    --------------------------------------------------------
    ThreatSenseDB = ThreatSenseDB or {}
    TS.db = ThreatSenseDB

    --------------------------------------------------------
    -- Migrations
    --------------------------------------------------------
    if TS.Migration and TS.Migration.Run then
        TS.Migration:Run()
    end

    --------------------------------------------------------
    -- Core systems
    --------------------------------------------------------
    if TS.Utils and TS.Utils.Initialize then TS.Utils:Initialize() end
    if TS.EventBus and TS.EventBus.Initialize then TS.EventBus:Initialize() end
    if TS.Media and TS.Media.Initialize then TS.Media:Initialize() end
    if TS.ProfileManager and TS.ProfileManager.Initialize then TS.ProfileManager:Initialize() end
    if TS.RoleManager and TS.RoleManager.Initialize then TS.RoleManager:Initialize() end
    if TS.GroupManager and TS.GroupManager.Initialize then TS.GroupManager:Initialize() end
    if TS.Smoothing and TS.Smoothing.Initialize then TS.Smoothing:Initialize() end
    if TS.ThreatEngine and TS.ThreatEngine.Initialize then TS.ThreatEngine:Initialize() end
    if TS.WarningEngine and TS.WarningEngine.Initialize then TS.WarningEngine:Initialize() end

    --------------------------------------------------------
    -- Config Panels (must load BEFORE PLAYER_LOGIN)
    --------------------------------------------------------
	if TS.Parent and TS.Parent.Initialize then TS.Parent:Initialize() end
	if TS.Display and TS.Display.Initialize then TS.Display:Initialize() end
	if TS.DisplayAdvanced and TS.DisplayAdvanced.Initialize then TS.DisplayAdvanced:Initialize() end
	if TS.Warnings and TS.Warnings.Initialize then TS.Warnings:Initialize() end
	if TS.WarningsAdvanced and TS.WarningsAdvanced.Initialize then TS.WarningsAdvanced:Initialize() end
	if TS.Profiles and TS.Profiles.Initialize then TS.Profiles:Initialize() end
	if TS.Roles and TS.Roles.Initialize then TS.Roles:Initialize() end
	if TS.Reset and TS.Reset.Initialize then TS.Reset:Initialize() end
end

------------------------------------------------------------
-- PLAYER_LOGIN
-- Initialize UI and preview systems
------------------------------------------------------------
function Core:OnPlayerLogin()
    --------------------------------------------------------
    -- UI: Display
    --------------------------------------------------------
    if TS.ThreatBar and TS.ThreatBar.Initialize then TS.ThreatBar:Initialize() end
    if TS.ThreatList and TS.ThreatList.Initialize then TS.ThreatList:Initialize() end

    --------------------------------------------------------
    -- UI: Warnings
    --------------------------------------------------------
    if TS.WarningFrame and TS.WarningFrame.Initialize then TS.WarningFrame:Initialize() end

    --------------------------------------------------------
    -- UI: Display Mode
    --------------------------------------------------------
    if TS.DisplayMode and TS.DisplayMode.Set then
        TS.DisplayMode:Set(TS.DisplayMode.mode or "BAR_ONLY")
    end

    --------------------------------------------------------
    -- UI: Preview Systems
    --------------------------------------------------------
    if TS.DisplayPreview and TS.DisplayPreview.Initialize then TS.DisplayPreview:Initialize() end
    if TS.WarningPreview and TS.WarningPreview.Initialize then TS.WarningPreview:Initialize() end

    --------------------------------------------------------
    -- Optional developer tools
    --------------------------------------------------------
    if TS.DevMode and TS.DevMode.Initialize then TS.DevMode:Initialize() end

    print("|cff00ff00ThreatSense loaded successfully.|r")
end