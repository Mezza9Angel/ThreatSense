-- ThreatSense: SlashCommands.lua
-- Provides /ts, /ts config, /ts settings, and a help command.
-- Includes a future‑proof dispatch table for easy expansion.

local ADDON_NAME, TS = ...
local Slash = {}
TS.SlashCommands = Slash

------------------------------------------------------------
-- Safely open the ThreatSense parent settings panel
------------------------------------------------------------
local function OpenSettings()
    -- Defensive guard: Settings API should always exist, but
    -- this prevents silent failures if Blizzard changes something.
    if not Settings or not Settings.OpenToCategory then
        print("|cffff4444ThreatSense:|r Settings API unavailable.")
        return
    end

    Settings.OpenToCategory("ThreatSense")
end

------------------------------------------------------------
-- Print help information
------------------------------------------------------------
local function PrintHelp()
    print("|cffffff00ThreatSense Commands:|r")
    print("  /ts              – Open settings")
    print("  /ts config       – Open settings")
    print("  /ts settings     – Open settings")
    print("  /ts help         – Show this help message")
end

------------------------------------------------------------
-- Command dispatch table
-- This makes future expansion trivial.
------------------------------------------------------------
local commands = {
    [""]         = OpenSettings,
    ["config"]   = OpenSettings,
    ["settings"] = OpenSettings,
    ["help"]     = PrintHelp,
}

------------------------------------------------------------
-- Slash command handler
------------------------------------------------------------
local function HandleSlashCommand(msg)
    msg = msg and msg:lower() or ""

    -- Look up the command in the dispatch table
    local fn = commands[msg]

    if fn then
        fn()
        return
    end

    -- Unknown command fallback
    print("|cffff4444ThreatSense:|r Unknown command. Use |cffffff00/ts help|r for options.")
end

------------------------------------------------------------
-- Register slash commands
------------------------------------------------------------
function Slash:Initialize()
    -- Two aliases for convenience
    SLASH_THREATSENSE1 = "/ts"
    SLASH_THREATSENSE2 = "/threatsense"

    -- Bind handler
    SlashCmdList["THREATSENSE"] = HandleSlashCommand
end