-- Modules/Warnings.lua
-- Modernized threat warning system (audio + visual alerts)

local ADDON_NAME, TS = ...

TS.Warnings = {}
local Warnings = TS.Warnings

Warnings.lastWarningLevel = 0
Warnings.lastWarningTime = 0
Warnings.warningCooldown = 2

---------------------------------------------------------
-- Initialization
---------------------------------------------------------

function Warnings:Initialize()
    TS.Utils:Debug("Warnings initialized")
end

---------------------------------------------------------
-- Main threat check
---------------------------------------------------------

function Warnings:CheckThreat()
    if not TS.db.profile.warnings.enabled then return end

    local threatData = TS.ThreatEngine:GetThreatData()
    if not threatData.target then
        self:Reset()
        return
    end

    -- Tanks do not get warnings
    if TS.Utils:GetPlayerRole() == "TANK" then return end

    -- Use relative threat for DPS/healers
    local threatPct = threatData.relativePct or threatData.playerThreatPct or 0

    local warningLevel = self:GetWarningLevel(threatPct)

    if warningLevel > 0 then
        self:TriggerWarning(warningLevel, threatPct)
    else
        if self.lastWarningLevel > 0 then
            self:Reset()
        end
    end
end

---------------------------------------------------------
-- Determine warning level
---------------------------------------------------------

function Warnings:GetWarningLevel(threatPct)
    local settings = TS.db.profile.warnings

    if threatPct >= TS.THREAT_THRESHOLDS.CRITICAL then
        return 3
    elseif threatPct >= settings.dangerThreshold then
        return 2
    elseif threatPct >= settings.warningThreshold then
        return 1
    else
        return 0
    end
end

---------------------------------------------------------
-- Trigger warning
---------------------------------------------------------

function Warnings:TriggerWarning(level, threatPct)
    -- Do not warn when solo
    if not IsInGroup() then
        return
    end

    local now = GetTime()

    local shouldWarn =
        (level > self.lastWarningLevel) or
        (now - self.lastWarningTime >= self.warningCooldown)

    if not shouldWarn then return end

    self.lastWarningLevel = level
    self.lastWarningTime = now

    if TS.db.profile.warnings.soundEnabled then
        self:PlayWarningSound(level)
    end

    if TS.db.profile.warnings.visualEnabled then
        self:ShowVisualWarning(level, threatPct)
    end

    TS.Utils:Debug("Warning triggered:", level, threatPct)
end

---------------------------------------------------------
-- Sound warnings
---------------------------------------------------------

function Warnings:PlayWarningSound(level)
    if not TS.db.profile.warnings.soundEnabled then
        return
    end

    -- Fallback sound based on warning level
    local fallbackSound =
        (level == 3 and TS.SOUNDS.CRITICAL) or
        (level == 2 and TS.SOUNDS.DANGER) or
        TS.SOUNDS.WARNING

    -- Use dropdown sound if selected, otherwise fallback
    local soundToPlay = TS.db.profile.warnings.soundFile or fallbackSound

    PlaySound(soundToPlay, "Master")
end

---------------------------------------------------------
-- Visual warning frame
---------------------------------------------------------

function Warnings:CreateWarningFrame()
    local frame = CreateFrame("Frame", "ThreatSenseWarningFrame", UIParent, "BackdropTemplate")
    frame:SetSize(350, 60)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    frame:SetFrameStrata("HIGH")

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0, 0, 0, 0.6)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    frame:Hide()

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
    text:SetPoint("CENTER")
    text:SetText("")
    frame.text = text

    self.warningFrame = frame
end

---------------------------------------------------------
-- Show visual warning
---------------------------------------------------------

function Warnings:ShowVisualWarning(level, threatPct)
    if not self.warningFrame then
        self:CreateWarningFrame()
    end

    local frame = self.warningFrame

    local color =
        (level == 3 and TS.COLORS.CRITICAL) or
        (level == 2 and TS.COLORS.DANGER) or
        TS.COLORS.WARNING

    frame:SetBackdropColor(color[1], color[2], color[3], 0.35)

    local label =
        (level == 3 and "THREAT CRITICAL!") or
        (level == 2 and "HIGH THREAT!") or
        "Threat Warning"

    frame.text:SetText(string.format("%s (%.0f%%)", label, threatPct))
    frame.text:SetTextColor(color[1], color[2], color[3], 1)

    self:AnimateWarning()
end

---------------------------------------------------------
-- Fade animation
---------------------------------------------------------

function Warnings:AnimateWarning()
    local frame = self.warningFrame
    if not frame then return end

    -- Stop previous animation
    if frame.animGroup then
        frame.animGroup:Stop()
    end

    frame:SetAlpha(0)
    frame:Show()

    local anim = frame:CreateAnimationGroup()
    frame.animGroup = anim

    local fadeIn = anim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.2)
    fadeIn:SetSmoothing("IN")

    local fadeOut = anim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.8)
    fadeOut:SetStartDelay(1.2)
    fadeOut:SetSmoothing("OUT")

    anim:SetScript("OnFinished", function()
        frame:Hide()
    end)

    anim:Play()
end

---------------------------------------------------------
-- Reset warning state
---------------------------------------------------------

function Warnings:Reset()
    self.lastWarningLevel = 0
    self.lastWarningTime = 0

    if self.warningFrame then
        self.warningFrame:Hide()
    end
end

return Warnings