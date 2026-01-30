-- ThreatSense: RoleManager.lua
-- Detects player role (Tank/Healer/DPS) and emits events

local ADDON_NAME, TS = ...
local RM = {}
TS.RoleManager = RM

RM.currentRole = nil

------------------------------------------------------------
-- Internal: Determine role using Blizzard API
------------------------------------------------------------
local function DetectRole()
    -- Retail: specialization-based
    if GetSpecialization then
        local spec = GetSpecialization()
        if spec then
            local role = GetSpecializationRole(spec)
            if role then
                return role -- "TANK", "HEALER", "DAMAGER"
            end
        end
    end

    -- Classic fallback: group role assignment
    local assigned = UnitGroupRolesAssigned("player")
    if assigned and assigned ~= "NONE" then
        return assigned
    end

    -- Last fallback: DPS
    return "DAMAGER"
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------
function RM:GetRole()
    return self.currentRole or "DAMAGER"
end

function RM:IsTank()
    return self:GetRole() == "TANK"
end

function RM:IsHealer()
    return self:GetRole() == "HEALER"
end

function RM:IsDPS()
    return self:GetRole() == "DAMAGER"
end

------------------------------------------------------------
-- Update role and emit events
------------------------------------------------------------
function RM:UpdateRole()
    local newRole = DetectRole()
    if newRole ~= self.currentRole then
        self.currentRole = newRole
        TS.Utils:Debug("RoleManager: Role changed to " .. newRole)
        TS.EventBus:Emit("ROLE_CHANGED", newRole)
    end
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function RM:Initialize()
    self:UpdateRole()

    -- Retail: spec changes
    if C_EventUtils and C_EventUtils.IsEventValid("PLAYER_SPECIALIZATION_CHANGED") then
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        f:SetScript("OnEvent", function() self:UpdateRole() end)
    end

    -- Classic: group role assignment changes
    local f2 = CreateFrame("Frame")
    f2:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    f2:SetScript("OnEvent", function() self:UpdateRole() end)

    TS.Utils:Debug("RoleManager initialized")
end

return RM