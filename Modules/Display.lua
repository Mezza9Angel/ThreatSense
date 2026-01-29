-- Modules/Display.lua
-- UI display for threat information (single bar + multi-bar list)

local ADDON_NAME, TS = ...

TS.Display = {}
local Display = TS.Display

Display.frame = nil
Display.bar = nil
Display.text = nil
Display.background = nil
Display.listFrame = nil
Display.rows = {}

local ROW_HEIGHT = 16
local ROW_SPACING = 2

function Display:Initialize()
    self:CreateFrame()
    self:ApplySettings()
    TS.Utils:Debug("Display initialized")
end

function Display:CreateFrame()
    local settings = TS.db.profile.display

    local frame = CreateFrame("Frame", "ThreatSenseFrame", UIParent)
    frame:SetSize(settings.width, settings.height)
    frame:SetPoint(
        TS.db.profile.position.point,
        UIParent,
        TS.db.profile.position.relativePoint,
        TS.db.profile.position.xOffset,
        TS.db.profile.position.yOffset
    )
    frame:SetMovable(true)
    frame:EnableMouse(not TS.db.profile.locked)
    frame:SetClampedToScreen(true)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetColorTexture(unpack(TS.COLORS.BACKGROUND))
    self.background = bg

    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    bar:SetHeight(settings.height - 4)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    bar:SetStatusBarColor(unpack(TS.COLORS.SAFE))
    self.bar = bar

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetFont(STANDARD_TEXT_FONT, settings.fontSize, "OUTLINE")
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    text:SetTextColor(1, 1, 1, 1)
    text:SetText("")
    self.text = text

    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetAllPoints(frame)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    -- List container (for multi-bar threat rows)
    local listFrame = CreateFrame("Frame", nil, frame)
    listFrame:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -4)
    listFrame:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
    listFrame:SetHeight(1) -- will be updated in ApplySettings
    self.listFrame = listFrame

    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not TS.db.profile.locked then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Display:SavePosition()
    end)

    frame:SetScript("OnEnter", function(self)
        Display:ShowTooltip()
    end)
    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    self.frame = frame
    self.frame:Hide()
end

-- Create a single row for the multi-bar list
function Display:CreateRow(index)
    local row = CreateFrame("StatusBar", nil, self.listFrame)
    row:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    row:SetMinMaxValues(0, 100)
    row:SetHeight(ROW_HEIGHT)

    if index == 1 then
        row:SetPoint("TOPLEFT", self.listFrame, "TOPLEFT", 0, 0)
        row:SetPoint("TOPRIGHT", self.listFrame, "TOPRIGHT", 0, 0)
    else
        local prev = self.rows[index - 1]
        row:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -ROW_SPACING)
        row:SetPoint("TOPRIGHT", prev, "BOTTOMRIGHT", 0, -ROW_SPACING)
    end

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetColorTexture(0, 0, 0, 0.4)
    row.bg = bg

    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(STANDARD_TEXT_FONT, TS.db.profile.display.fontSize - 1, "OUTLINE")
    nameText:SetPoint("LEFT", row, "LEFT", 4, 0)
    nameText:SetJustifyH("LEFT")
    row.nameText = nameText

    local valueText = row:CreateFontString(nil, "OVERLAY")
    valueText:SetFont(STANDARD_TEXT_FONT, TS.db.profile.display.fontSize - 1, "OUTLINE")
    valueText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    valueText:SetJustifyH("RIGHT")
    row.valueText = valueText

    self.rows[index] = row
    return row
end

function Display:Update()
    if not self.frame then return end

    local threatData = TS.ThreatEngine:GetThreatData()

    if not threatData.target then
        self:Hide()
        return
    end

    self:Show()

    local playerRole = TS.Utils:GetPlayerRole()
    local displayPct = threatData.playerThreatPct or 0

    if playerRole ~= "TANK" then
        displayPct = threatData.relativePct or threatData.playerThreatPct or 0
    end

    self.bar:SetValue(math.min(displayPct, 100))
    local r, g, b = TS.Utils:GetThreatColor(displayPct)
    self.bar:SetStatusBarColor(r, g, b, 1)

    if TS.db.profile.display.showText then
        local textStr = ""

        if TS.db.profile.display.showPercentage then
            textStr = string.format("%.0f%%", displayPct)
        end

        if threatData.target then
            if textStr ~= "" then
                textStr = threatData.target .. ": " .. textStr
            else
                textStr = threatData.target
            end
        end

        self.text:SetText(textStr)
    else
        self.text:SetText("")
    end

    self:UpdateList(threatData.threatList)
end

-- Update the multi-bar threat list
function Display:UpdateList(threatList)
    if not self.listFrame then return end

    local maxEntries = TS.db.profile.display.maxEntries or 5

    -- If only 1 entry is configured, effectively disable the list
    if maxEntries <= 1 then
        for _, row in ipairs(self.rows) do
            row:Hide()
        end
        return
    end

    for i = 1, maxEntries do
        local row = self.rows[i] or self:CreateRow(i)
        local data = threatList[i]

        if data then
            row:Show()

            local pct = data.threatPct or 0
            row:SetValue(math.min(pct, 100))

            local r, g, b = TS.Utils:GetThreatColor(pct)
            row:SetStatusBarColor(r, g, b, 1)

            local classColor = RAID_CLASS_COLORS[data.class] or { r = 1, g = 1, b = 1 }
            row.nameText:SetText(data.name or "Unknown")
            row.nameText:SetTextColor(classColor.r, classColor.g, classColor.b, 1)

            if TS.db.profile.display.showPercentage then
                row.valueText:SetText(string.format("%.0f%%", pct))
            else
                row.valueText:SetText("")
            end
        else
            row:Hide()
        end
    end
end

function Display:Show()
    if self.frame and TS.db.profile.enabled then
        self.frame:Show()
    end
end

function Display:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function Display:Refresh()
    if not self.frame then return end
    self:ApplySettings()
end

function Display:ApplySettings()
    if not self.frame then return end

    local settings = TS.db.profile.display

    self.frame:SetSize(settings.width, settings.height)
    self.frame:SetScale(settings.scale)

    if self.text then
        self.text:SetFont(STANDARD_TEXT_FONT, settings.fontSize, "OUTLINE")
    end

    -- Update row fonts and list height
    local maxEntries = settings.maxEntries or 5
    local listHeight = 0

    if maxEntries > 1 then
        listHeight = maxEntries * ROW_HEIGHT + (maxEntries - 1) * ROW_SPACING
    end

    if self.listFrame then
        self.listFrame:SetHeight(listHeight)
    end

    for i, row in ipairs(self.rows) do
        row.nameText:SetFont(STANDARD_TEXT_FONT, settings.fontSize - 1, "OUTLINE")
        row.valueText:SetFont(STANDARD_TEXT_FONT, settings.fontSize - 1, "OUTLINE")
    end

    self.frame:EnableMouse(not TS.db.profile.locked)
end

function Display:SetLocked(locked)
    if self.frame then
        self.frame:EnableMouse(not locked)
    end
end

function Display:SavePosition()
    local point, _, relativePoint, xOffset, yOffset = self.frame:GetPoint()
    TS.db.profile.position.point = point
    TS.db.profile.position.relativePoint = relativePoint
    TS.db.profile.position.xOffset = xOffset
    TS.db.profile.position.yOffset = yOffset
    TS.Utils:Debug("Position saved:", point, xOffset, yOffset)
end

function Display:ResetPosition()
    if not self.frame then return end

    self.frame:ClearAllPoints()
    self.frame:SetPoint(
        TS.db.profile.position.point,
        UIParent,
        TS.db.profile.position.relativePoint,
        TS.db.profile.position.xOffset,
        TS.db.profile.position.yOffset
    )
end

function Display:ShowTooltip()
    if not self.frame then return end

    local threatData = TS.ThreatEngine:GetThreatData()
    if not threatData.target then return end

    GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
    GameTooltip:SetText("ThreatSense", 1, 1, 1, 1, true)
    GameTooltip:AddLine(" ")

    GameTooltip:AddDoubleLine("Target:", threatData.target, 1, 1, 1, 1, 1, 0)

    local pct = threatData.relativePct or threatData.playerThreatPct or 0
    local r, g, b = TS.Utils:GetThreatColor(pct)

    GameTooltip:AddDoubleLine(
        "Your Threat:",
        string.format("%.0f%% (%s)", pct, TS.Utils:FormatNumber(threatData.playerThreat)),
        1, 1, 1,
        r, g, b
    )

    if #threatData.threatList > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Top Threats:", 0.7, 0.7, 0.7)

        local maxShow = math.min(5, #threatData.threatList)
        for i = 1, maxShow do
            local member = threatData.threatList[i]
            local classColor = RAID_CLASS_COLORS[member.class] or { r = 1, g = 1, b = 1 }

            GameTooltip:AddDoubleLine(
                member.name,
                string.format("%.0f%%", member.threatPct or 0),
                classColor.r, classColor.g, classColor.b,
                1, 1, 1
            )
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cFF888888Drag to move|r", 0.5, 0.5, 0.5)
    GameTooltip:AddLine("|cFF888888/ts lock to lock position|r", 0.5, 0.5, 0.5)

    GameTooltip:Show()
end

return Display