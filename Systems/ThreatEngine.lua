-- ThreatSense: ThreatEngine.lua
-- Core threat collection and tracking (event-driven, multi-unit, ThreatMath 2.0 aware)

local ADDON_NAME, TS = ...
TS.ThreatEngine = TS.ThreatEngine or {}
local Engine = TS.ThreatEngine

local Math = TS.ThreatMath

------------------------------------------------------------
-- Internal state
------------------------------------------------------------
Engine.state = {
    targetUnit       = nil,
    targetName       = nil,
    byUnit           = {},   -- [unit] = entry
    list             = {},   -- sorted entries
    topThreat        = 0,
    tankThreat       = 0,
    secondThreat     = 0,
    tankUnit         = nil,
    player = {
        threat       = 0,
        threatPct    = 0,
        isTanking    = false,
        relToTank    = 0,
        category     = "SAFE",
    },
}

Engine.inCombat      = false
Engine.hasTargetData = false

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function IsValidThreatTarget(unit)
    if not UnitExists(unit) then return false end
    if not UnitCanAttack("player", unit) then return false end
    if UnitIsDeadOrGhost(unit) then return false end
    return true
end

local function GetPrimaryTarget()
    -- Priority: current target → focus → bosses
    if IsValidThreatTarget("target") then
        return "target"
    end

    if IsValidThreatTarget("focus") then
        return "focus"
    end

    for i = 1, 5 do
        local bossUnit = "boss" .. i
        if IsValidThreatTarget(bossUnit) then
            return bossUnit
        end
    end

    return nil
end

local function ClearState()
    local s = Engine.state
    s.targetUnit    = nil
    s.targetName    = nil
    s.byUnit        = {}
    s.list          = {}
    s.topThreat     = 0
    s.tankThreat    = 0
    s.secondThreat  = 0
    s.tankUnit      = nil
    s.player.threat    = 0
    s.player.threatPct = 0
    s.player.isTanking = false
    s.player.relToTank = 0
    s.player.category  = "SAFE"
    Engine.hasTargetData = false
end

------------------------------------------------------------
-- Core update
------------------------------------------------------------
function Engine:Update()
    local target = GetPrimaryTarget()

    -- If no valid target and we had data before → reset once
    if not target then
        if self.hasTargetData then
            self:Reset()
        end
        return
    end

    local targetName = UnitName(target)
    local s = self.state

    s.targetUnit = target
    s.targetName = targetName

    self:UpdateThreatForTarget(target)
end

function Engine:UpdateThreatForTarget(target)
    if not TS.GroupManager or not TS.GroupManager.GetUnits then
        return
    end

    local units = TS.GroupManager:GetUnits()
    local s = self.state

    local byUnit = {}
    local list   = {}
    local threatTable = {}

    local topThreat   = 0
    local tankThreat  = 0
    local tankUnit    = nil

    local playerThreat    = 0
    local playerThreatPct = 0
    local playerIsTanking = false

    for _, unit in ipairs(units) do
        local threatData = TS.Utils:GetUnitThreat(unit, target)
        if threatData and threatData.threatValue > 0 then
            local name = UnitName(unit)
            local _, class = UnitClass(unit)

            local entry = {
                unit      = unit,
                name      = name,
                class     = class,
                threat    = threatData.threatValue,
                threatPct = threatData.threatPct,
                isTanking = threatData.isTanking,
            }

            byUnit[unit] = entry
            table.insert(list, entry)
            threatTable[unit] = threatData.threatValue

            if threatData.threatValue > topThreat then
                topThreat = threatData.threatValue
            end

            if threatData.isTanking and threatData.threatValue > tankThreat then
                tankThreat = threatData.threatValue
                tankUnit   = unit
            end

            if unit == "player" then
                playerThreat    = threatData.threatValue
                playerThreatPct = threatData.threatPct
                playerIsTanking = threatData.isTanking
            end
        end
    end

    if #list == 0 then
        -- No meaningful threat data → treat as reset of target data
        if self.hasTargetData then
            self:Reset()
        end
        return
    end

    table.sort(list, function(a, b)
        return a.threat > b.threat
    end)

    local highest, second = Math:GetTopTwoThreats(threatTable)

    s.byUnit       = byUnit
    s.list         = list
    s.topThreat    = highest
    s.tankThreat   = tankThreat
    s.secondThreat = second
    s.tankUnit     = tankUnit

    s.player.threat    = playerThreat
    s.player.threatPct = playerThreatPct
    s.player.isTanking = playerIsTanking

    if tankThreat > 0 and playerThreat > 0 then
        s.player.relToTank = Math:GetRelativeThreat(playerThreat, tankThreat)
    else
        s.player.relToTank = 0
    end

    s.player.category = Math:GetThreatCategory(s.player.relToTank)

    self.hasTargetData = true
    self:EmitThreatEvents()
end

------------------------------------------------------------
-- Event emission
------------------------------------------------------------
function Engine:EmitThreatEvents()
    if not TS.EventBus or not TS.EventBus.Send then
        return
    end

    local s = self.state

    TS.EventBus:Send("THREAT_SNAPSHOT_UPDATED", {
        targetUnit   = s.targetUnit,
        targetName   = s.targetName,
        list         = s.list,
        byUnit       = s.byUnit,
        topThreat    = s.topThreat,
        tankThreat   = s.tankThreat,
        secondThreat = s.secondThreat,
        tankUnit     = s.tankUnit,
        player       = {
            threat    = s.player.threat,
            threatPct = s.player.threatPct,
            isTanking = s.player.isTanking,
            relToTank = s.player.relToTank,
            category  = s.player.category,
        },
    })
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------
function Engine:GetCurrentTarget()
    local s = self.state
    return s.targetUnit, s.targetName
end

function Engine:GetThreatList()
    return self.state.list
end

function Engine:GetThreatForUnit(unit)
    return self.state.byUnit[unit]
end

function Engine:GetPlayerThreat()
    local p = self.state.player
    return p.threat, p.threatPct, p.isTanking, p.relToTank, p.category
end

function Engine:GetSnapshot()
    return self.state
end

------------------------------------------------------------
-- Reset state
------------------------------------------------------------
function Engine:Reset()
    ClearState()

    if TS.EventBus and TS.EventBus.Send then
        TS.EventBus:Send("THREAT_RESET")
    end
end

------------------------------------------------------------
-- Event-driven update scheduling
------------------------------------------------------------
local updateFrame
local elapsedSinceUpdate = 0
local pendingUpdate      = false
local UPDATE_INTERVAL    = TS.UPDATE_INTERVAL or 0.2

local function ScheduleUpdate()
    pendingUpdate = true
end

local function OnEvent(_, event, arg1, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        Engine.inCombat = true
        ScheduleUpdate()
    elseif event == "PLAYER_REGEN_ENABLED" then
        Engine.inCombat = false
        Engine:Reset()
    elseif event == "PLAYER_TARGET_CHANGED" then
        ScheduleUpdate()
    elseif event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
        ScheduleUpdate()
    elseif event == "GROUP_ROSTER_UPDATE" then
        ScheduleUpdate()
    end
end

local function OnUpdate(_, delta)
    if not pendingUpdate then return end

    elapsedSinceUpdate = elapsedSinceUpdate + delta
    if elapsedSinceUpdate < UPDATE_INTERVAL then
        return
    end

    elapsedSinceUpdate = 0
    pendingUpdate = false

    -- Only update if we have a meaningful context:
    -- either in combat or we have a valid hostile target
    local target = GetPrimaryTarget()
    if not Engine.inCombat and not target then
        Engine:Reset()
        return
    end

    Engine:Update()
end

------------------------------------------------------------
-- Initialization
------------------------------------------------------------
function Engine:Initialize()
    TS.Utils:Debug("ThreatEngine 2.0 initialized (event-driven)")

    if not updateFrame then
        updateFrame = CreateFrame("Frame")

        updateFrame:SetScript("OnEvent", OnEvent)
        updateFrame:SetScript("OnUpdate", OnUpdate)

        updateFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        updateFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        updateFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        updateFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
        updateFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
        updateFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    end
end

return Engine