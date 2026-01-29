-- Core/Utils.lua
-- Utility functions for ThreatSense

local ADDON_NAME, TS = ...

TS.Utils = {}

-- Trim whitespace
function TS.Utils:Trim(str)
    if not str then return "" end
    return str:gsub("^%s+", ""):gsub("%s+$", "")
end

-- Get color based on threat percentage
function TS.Utils:GetThreatColor(threatPct)
    if threatPct < TS.THREAT_THRESHOLDS.SAFE then
        return unpack(TS.COLORS.SAFE)
    elseif threatPct < TS.THREAT_THRESHOLDS.WARNING then
        return unpack(TS.COLORS.WARNING)
    elseif threatPct < TS.THREAT_THRESHOLDS.DANGER then
        return unpack(TS.COLORS.DANGER)
    else
        return unpack(TS.COLORS.CRITICAL)
    end
end

-- Format threat percentage
function TS.Utils:FormatThreatPercent(rawPct, scaledPct)
    return string.format("%.0f%%", scaledPct or rawPct)
end

-- Get player role
function TS.Utils:GetPlayerRole()
    local spec = GetSpecialization()
    if not spec then return "DAMAGER" end

    local role = select(5, GetSpecializationInfo(spec))
    return role or "DAMAGER"
end

-- Check if player is in valid instance
function TS.Utils:IsInValidInstance()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then return false end

    return instanceType == "party"
        or instanceType == "raid"
        or instanceType == "scenario"
end

-- Get unit threat data
function TS.Utils:GetUnitThreat(unit, mobUnit)
    mobUnit = mobUnit or "target"

    if not UnitExists(mobUnit) or not UnitCanAttack("player", mobUnit) then
        return nil
    end

    local isTanking, status, threatPct, rawPct, threatValue =
        UnitDetailedThreatSituation(unit, mobUnit)

    return {
        isTanking = isTanking or false,
        status = status or 0,
        threatPct = threatPct or 0,
        rawPct = rawPct or 0,
        threatValue = threatValue or 0
    }
end

-- Deep copy table
function TS.Utils:CopyTable(orig)
    if type(orig) ~= "table" then
        return orig
    end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = type(v) == "table" and self:CopyTable(v) or v
    end
    return copy
end

-- Print debug message
function TS.Utils:Debug(...)
    if TS.db and TS.db.profile and TS.db.profile.debug then
        print("|cFF00FF00[ThreatSense]|r", ...)
    end
end

-- Print message to chat
function TS.Utils:Print(...)
    print("|cFF00FF00[ThreatSense]|r", ...)
end

-- Helper function to format large numbers
function TS.Utils:FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return string.format("%.0f", num)
    end
end