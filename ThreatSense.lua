-- ThreatSense.lua
-- Main addon initialization and core functionality

local ADDON_NAME, TS = ...

-- Default database structure
local defaults = {
    profile = {
        enabled = true,
        locked = false,
        debug = false,

        display = {
            width = 200,
            height = 20,
            scale = 1.0,
            showText = true,
            showPercentage = true,
            maxEntries = 5,
            barTexture = "Blizzard",
            font = "Friz Quadrata TT",
            fontSize = 12,
            showInCombatOnly = false,
            fadeWhenNoCombat = true
        },

        position = {
            point = "CENTER",
            relativeFrame = "UIParent",
            relativePoint = "CENTER",
            xOffset = 0,
            yOffset = -200
        },

        warnings = {
            enabled = true,
            soundEnabled = true,
            visualEnabled = true,
            warningThreshold = 85,
            dangerThreshold = 95
        },

        roleSettings = {
            TANK = { showWarnings = false },
            DAMAGER = { warningThreshold = 85 },
            HEALER = { warningThreshold = 90 }
        }
    }
}

-- Event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

-- Initialize saved variables
function TS:InitializeDB()
    if not ThreatSenseDB then
        ThreatSenseDB = TS.Utils:CopyTable(defaults)
        TS.Utils:Print("Database initialized with defaults")
    end

    TS.db = ThreatSenseDB

    -- Ensure top-level defaults exist
    for key, value in pairs(defaults.profile) do
        if TS.db.profile[key] == nil then
            TS.db.profile[key] = TS.Utils:CopyTable(value)
        end
    end
end

-- Main initialization
function TS:Initialize()
    TS.Utils:Print("v" .. TS.VERSION .. " loaded. Type /ts for options")

    -- Core systems first
    if TS.ThreatEngine then TS.ThreatEngine:Initialize() end

    -- Register ALL config panels before UI modules
    if TS.Config then TS.Config:Initialize() end          -- parent
    if TS.ConfigDisplay then TS.ConfigDisplay:Initialize() end  -- child
    if TS.ConfigWarnings then TS.ConfigWarnings:Initialize() end -- child

    -- Now initialize UI modules that depend on settings
    if TS.Display then TS.Display:Initialize() end
    if TS.Warnings then TS.Warnings:Initialize() end
	
    if TS.db.profile.enabled then
        TS:StartUpdates()
    end
end

-- Start update cycle
function TS:StartUpdates()
    if TS.updateTicker then
        TS.updateTicker:Cancel()
    end

    TS.updateTicker = C_Timer.NewTicker(TS.UPDATE_INTERVAL, function()
        TS:OnUpdate()
    end)
end

-- Stop update cycle
function TS:StopUpdates()
    if TS.updateTicker then
        TS.updateTicker:Cancel()
        TS.updateTicker = nil
    end
end

-- Main update function
function TS:OnUpdate()
    if not TS.db or not TS.db.profile or not TS.db.profile.enabled then return end

    local inCombat = InCombatLockdown()
    local showInCombatOnly = TS.db.profile.display.showInCombatOnly

    if showInCombatOnly and not inCombat then
        if TS.Display then TS.Display:Hide() end
        return
    end

    if TS.ThreatEngine then TS.ThreatEngine:Update() end
    if TS.Display then TS.Display:Update() end
    if TS.Warnings then TS.Warnings:CheckThreat() end
end

-- Slash command handler
SLASH_THREATSENSE1 = "/threatsense"
SLASH_THREATSENSE2 = "/ts"
SlashCmdList["THREATSENSE"] = function(msg)
    msg = TS.Utils:Trim((msg or ""):lower())

    if msg == "" or msg == "config" or msg == "options" then
        TS.Utils:Print("Config GUI coming soon! For now, use commands:")
        TS.Utils:Print("/ts toggle - Enable/disable addon")
        TS.Utils:Print("/ts lock - Lock/unlock display position")
        TS.Utils:Print("/ts reset - Reset position to center")

    elseif msg == "toggle" then
        TS.db.profile.enabled = not TS.db.profile.enabled
        if TS.db.profile.enabled then
            TS:StartUpdates()
            TS.Utils:Print("Enabled")
        else
            TS:StopUpdates()
            if TS.Display then TS.Display:Hide() end
            TS.Utils:Print("Disabled")
        end

    elseif msg == "lock" then
        TS.db.profile.locked = not TS.db.profile.locked
        if TS.Display then TS.Display:SetLocked(TS.db.profile.locked) end
        TS.Utils:Print(TS.db.profile.locked and "Display locked" or "Display unlocked")

    elseif msg == "reset" then
        TS.db.profile.position = TS.Utils:CopyTable(defaults.profile.position)
        if TS.Display then TS.Display:ResetPosition() end
        TS.Utils:Print("Position reset to center")

    elseif msg == "debug" then
        TS.db.profile.debug = not TS.db.profile.debug
        TS.Utils:Print("Debug mode: " .. (TS.db.profile.debug and "ON" or "OFF"))

    else
        TS.Utils:Print("Unknown command. Type /ts for help")
    end
end

-- Event handler
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        TS:InitializeDB()

    elseif event == "PLAYER_LOGIN" then
        TS:Initialize()

    elseif event == "PLAYER_ENTERING_WORLD" then
        if TS.Display then TS.Display:Refresh() end

    elseif event == "PLAYER_REGEN_DISABLED" then
        TS.inCombat = true

    elseif event == "PLAYER_REGEN_ENABLED" then
        TS.inCombat = false
        if TS.Warnings then TS.Warnings:Reset() end
    end
end)