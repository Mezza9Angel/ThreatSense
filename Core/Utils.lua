-- ThreatSense: Utils.lua
-- General-purpose utility helpers

local ADDON_NAME, TS = ...

TS.Utils = {}

------------------------------------------------------------
-- Trim whitespace from both ends of a string
------------------------------------------------------------
function TS.Utils:Trim(str)
    if not str then return "" end
    return str:gsub("^%s+", ""):gsub("%s+$", "")
end

------------------------------------------------------------
-- Fallback threat color based on percentage
-- Display modules should prefer profile-defined colors.
------------------------------------------------------------
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

------------------------------------------------------------
-- Format threat percentage
------------------------------------------------------------
function TS.Utils:FormatThreatPercent(rawPct, scaledPct)
    return string.format("%.0f%%", scaledPct or rawPct)
end

------------------------------------------------------------
-- Get player role (delegates to RoleManager)
------------------------------------------------------------
function TS.Utils:GetPlayerRole()
    if TS.RoleManager and TS.RoleManager.GetRole then
        return TS.RoleManager:GetRole()
    end
    return "DAMAGER"
end

------------------------------------------------------------
-- Check if player is in a valid instance type
------------------------------------------------------------
function TS.Utils:IsInValidInstance()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then return false end

    return instanceType == "party"
        or instanceType == "raid"
        or instanceType == "scenario"
end

------------------------------------------------------------
-- Get unit threat data
------------------------------------------------------------
function TS.Utils:GetUnitThreat(unit, mobUnit)
    mobUnit = mobUnit or "target"

    if not unit or not UnitExists(unit) then
        return nil
    end

    if not UnitExists(mobUnit) or not UnitCanAttack("player", mobUnit) then
        return nil
    end

    local isTanking, status, threatPct, rawPct, threatValue =
        UnitDetailedThreatSituation(unit, mobUnit)

    return {
        isTanking   = isTanking or false,
        status      = status or 0,
        threatPct   = threatPct or 0,
        rawPct      = rawPct or 0,
        threatValue = threatValue or 0,
    }
end

------------------------------------------------------------
-- Deep copy a table
------------------------------------------------------------
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

------------------------------------------------------------
-- Print debug message (only if enabled in profile)
------------------------------------------------------------
function TS.Utils:Debug(...)
    if not TS.db or not TS.db.profile then return end
    if TS.db.profile.debug then
        print("|cFF00FF00[ThreatSense]|r", ...)
    end
end

------------------------------------------------------------
-- Print message to chat
------------------------------------------------------------
function TS.Utils:Print(...)
    print("|cFF00FF00[ThreatSense]|r", ...)
end

------------------------------------------------------------
-- Format large numbers (e.g., 1500 → 1.5K)
------------------------------------------------------------
function TS.Utils:FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return string.format("%.0f", num)
    end
end