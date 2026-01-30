-- ThreatSense: SlashCommands.lua
-- Provides /ts, /ts config, /ts settings

local ADDON_NAME, TS = ...
local Slash = {}
TS.SlashCommands = Slash

------------------------------------------------------------
-- Open the ThreatSense parent settings panel
------------------------------------------------------------
local function OpenSettings()
    Settings.OpenToCategory("ThreatSense")
end

------------------------------------------------------------
-- Slash command handler
------------------------------------------------------------
local function HandleSlashCommand(msg)
    msg = msg and msg:lower() or ""

    if msg == "" or msg == "config" or msg == "settings" then
        OpenSettings()
        return
    end

    print("|cffff4444ThreatSense:|r Unknown command. Use |cffffff00/ts|r to open settings.")
end

------------------------------------------------------------
-- Register slash commands
------------------------------------------------------------
function Slash:Initialize()
    SLASH_THREATSENSE1 = "/ts"
    SLASH_THREATSENSE2 = "/threatsense"

    SlashCmdList["THREATSENSE"] = HandleSlashCommand
end