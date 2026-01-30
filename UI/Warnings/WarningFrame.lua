-- ThreatSense: WarningFrame.lua
-- Snapshot-driven, profile-based warning display frame

local ADDON_NAME, TS = ...

TS.WarningFrame = TS.WarningFrame or {}
local WF = TS.WarningFrame

------------------------------------------------------------
-- Internal state
------------------------------------------------------------
WF.frame = nil
WF.activeType = nil

------------------------------------------------------------
-- Safe profile access with defaults
------------------------------------------------------------
local function GetProfile()
    local p = TS.db and TS.db.profile and TS.db.profile.warnings
    if not p then
        return {
            enabled = true,
            visualEnabled = true,
            soundEnabled = true,
            warningThreshold = 85,
            dangerThreshold = 95,
            width = 240,
            height = 60,
            scale = 1,
            position = {
                point = "CENTER",
                relativePoint = "CENTER",
                x = 0,
                y = 200,
            },
        }
    end

    -- Ensure required fields exist
    p.width  = p.width  or 240
    p.height = p.height or 60
    p.scale  = p.scale  or 1
    p.position = p.position or {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 200,
    }

    return p
end

------------------------------------------------------------
-- Apply profile settings
------------------------------------------------------------
function WF:ApplyProfile()
    if not self.frame then return end

    local profile = GetProfile()

    self.frame:SetSize(profile.width, profile.height)
    self.frame:SetScale(profile.scale)

    self.frame:ClearAllPoints()
    self.frame:SetPoint(
        profile.position.point,
        UIParent,
        profile.position.relativePoint,
        profile.position.x,
        profile.position.y
    )
end

------------------------------------------------------------
-- Create the warning frame
------------------------------------------------------------
function WF:Create()
    if self.frame then return end

    local profile = GetProfile()

    local f = CreateFrame("Frame", "ThreatSense_WarningFrame", UIParent)
    f:SetSize(profile.width, profile.height)
    f:SetScale(profile.scale)
    f:SetFrameStrata("HIGH")
    f:Hide()

    -- Background
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.6)
    f.bg = bg

    -- Text
    local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    text:SetPoint("CENTER")
    text:SetText("")
    f.text = text

    self.frame = f
    self:ApplyProfile()

    --------------------------------------------------------
    -- Event listeners
    --------------------------------------------------------
    TS.EventBus:Register("WARNING_TRIGGERED", function(payload)
        self:OnWarning(payload)
    end, {
        namespace = "WarningFrame",
        source    = "WarningFrame",
    })

    TS.EventBus:Register("WARNING_CLEARED", function(payload)
        self:OnWarningCleared(payload)
    end, {
        namespace = "WarningFrame",
        source    = "WarningFrame",
    })

    TS.EventBus:Register("PROFILE_CHANGED", function()
        self:ApplyProfile()
    end, {
        namespace = "WarningFrame",
        source    = "WarningFrame",
    })

    TS.Utils:Debug("WarningFrame 2.0 initialized")
end

------------------------------------------------------------
-- Warning display logic
------------------------------------------------------------
local CATEGORY_COLORS = {
    SAFE     = { r = 0.20, g = 0.80, b = 0.20 },
    WARNING  = { r = 0.90, g = 0.80, b = 0.20 },
    DANGER   = { r = 0.95, g = 0.50, b = 0.10 },
    CRITICAL = { r = 0.95, g = 0.20, b = 0.20 },
}

local function GetColorForType(type)
    if type == "AGGRO_LOST" or type == "AGGRO_PULLED" then
        return CATEGORY_COLORS.CRITICAL
    elseif type == "LOSING_AGGRO" or type == "PULLING_AGGRO" then
        return CATEGORY_COLORS.DANGER
    elseif type == "TAUNT" or type == "DROP_THREAT" then
        return CATEGORY_COLORS.WARNING
    end

    return CATEGORY_COLORS.SAFE
end

------------------------------------------------------------
-- Handle warning triggered
------------------------------------------------------------
function WF:OnWarning(payload)
    local profile = GetProfile()
    if not profile.enabled or not profile.visualEnabled then return end

    local f = self.frame
    if not f then return end

    self.activeType = payload.type

    -- Set text
    local msg = payload.type:gsub("_", " ")
    f.text:SetText(msg)

    -- Color
    local c = GetColorForType(payload.type)
    f.bg:SetColorTexture(c.r, c.g, c.b, 0.6)

    -- Animation
    if TS.WarningAnimations and TS.WarningAnimations.Play then
        TS.WarningAnimations:Play(f, payload.type)
    end

    f:Show()
end

------------------------------------------------------------
-- Handle warning cleared
------------------------------------------------------------
function WF:OnWarningCleared(payload)
    if not self.frame then return end

    self.activeType = nil

    if TS.WarningAnimations and TS.WarningAnimations.Stop then
        TS.WarningAnimations:Stop(self.frame)
    end

    self.frame:Hide()
end

------------------------------------------------------------
-- Show / Hide
------------------------------------------------------------
function WF:Show()
    if self.frame then self.frame:Show() end
end

function WF:Hide()
    if self.frame then self.frame:Hide() end
end

return WF