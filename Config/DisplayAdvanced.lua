-- ThreatSense: DisplayAdvanced.lua
-- Advanced display configuration (profile-aware, DisplayMode 2.0)

local ADDON_NAME, TS = ...
local DisplayAdvanced = {}
TS.DisplayAdvanced = DisplayAdvanced

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function RefreshPreview()
    if TS.DisplayPreview and TS.DisplayPreview.IsActive and TS.DisplayPreview:IsActive() then
        TS.DisplayPreview:Start()
    end
end

local function FireProfileChanged()
    if TS.EventBus and TS.EventBus.Send then
        TS.EventBus:Send("PROFILE_CHANGED")
    end
    RefreshPreview()
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function DisplayAdvanced:Initialize()
    if not TS.db or not TS.db.profile then
        return
    end

    local db = TS.db.profile.display or {}
    TS.db.profile.display = db

    TS.db.profile.colors = TS.db.profile.colors or {}
    local colorDB = TS.db.profile.colors

    --------------------------------------------------------
    -- Panel frame
    --------------------------------------------------------
    local panel = CreateFrame("Frame", "ThreatSenseConfigDisplayAdvanced", UIParent)
    panel.name   = TS.ConfigCategories.DISPLAY_ADV
    panel.parent = TS.ConfigCategories.ROOT

    local y = -16
    local function NextLine(offset)
        y = y - (offset or 24)
        return y
    end

    local function Header(text)
        local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        fs:SetPoint("TOPLEFT", 16, NextLine(32))
        fs:SetText(text)
        return fs
    end

    local function Label(text)
        local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", 16, NextLine())
        fs:SetText(text)
        return fs
    end

    local function Slider(label, key, min, max, step, description)
        Label(label)

        local slider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 16, NextLine(-10))
        slider:SetMinMaxValues(min, max)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        slider:SetWidth(220)

        local name = slider:GetName()
        if name then
            _G[name .. "Text"]:SetText(label)
            _G[name .. "Low"]:SetText(tostring(min))
            _G[name .. "High"]:SetText(tostring(max))
        end

        slider:SetValue(db[key] or min)
        slider:SetScript("OnValueChanged", function(self, value)
            if step >= 1 then
                value = math.floor(value + 0.5)
            end
            db[key] = value
            FireProfileChanged()
        end)

        return slider
    end

    local function Checkbox(label, key, description)
		local check = CreateFrame(
			"CheckButton",
			"ThreatSenseDisplayAdvanced_" .. key,
			panel,
			"InterfaceOptionsCheckButtonTemplate"
		)

		check:SetPoint("TOPLEFT", 16, NextLine())
		_G[check:GetName() .. "Text"]:SetText(label)
		check.tooltipText = description

		check:SetChecked(db[key] ~= false)
		check:SetScript("OnClick", function(self)
			db[key] = self:GetChecked() and true or false
			FireProfileChanged()
		end)

		return check
	end

    local function ColorSwatch(label, key, default)
        Label(label)

        local btn = CreateFrame("Button", nil, panel)
        btn:SetSize(24, 24)
        btn:SetPoint("TOPLEFT", 16, NextLine(-10))

        local tex = btn:CreateTexture(nil, "BACKGROUND")
        tex:SetAllPoints()
        btn.tex = tex

        local function GetColor()
            local c = colorDB[key] or default
            return c.r, c.g, c.b, c.a or 1
        end

        local function SetColor(r, g, b, a)
            colorDB[key] = { r = r, g = g, b = b, a = a or 1 }
            tex:SetColorTexture(r, g, b, a or 1)
            FireProfileChanged()
        end

        do
            local r, g, b, a = GetColor()
            tex:SetColorTexture(r, g, b, a)
        end

        btn:SetScript("OnClick", function()
            local r, g, b, a = GetColor()
            ColorPickerFrame:Hide()
            ColorPickerFrame.hasOpacity = true
            ColorPickerFrame.opacity = 1 - (a or 1)
            ColorPickerFrame.previousValues = { r, g, b, a }
            ColorPickerFrame.func = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = 1 - (OpacitySliderFrame:GetValue() or 0)
                SetColor(nr, ng, nb, na)
            end
            ColorPickerFrame.opacityFunc = ColorPickerFrame.func
            ColorPickerFrame.cancelFunc = function(prev)
                SetColor(prev[1], prev[2], prev[3], prev[4])
            end
            ColorPickerFrame:SetColorRGB(r, g, b)
            ColorPickerFrame:Show()
        end)

        return btn
    end

    local function LSMDropdown(label, key, mediaType, description)
        if not LSM then return end

        Label(label)

        local dropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", 10, NextLine(-10))

        local values = {}
        for _, name in ipairs(LSM:List(mediaType)) do
            table.insert(values, name)
        end

        local function SetValue(value)
            db[key] = value
            UIDropDownMenu_SetSelectedValue(dropdown, value)
            UIDropDownMenu_SetText(dropdown, value)
            FireProfileChanged()
        end

        UIDropDownMenu_Initialize(dropdown, function(self, level)
            for _, name in ipairs(values) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = name
                info.value = name
                info.func = function()
                    SetValue(name)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)

        UIDropDownMenu_SetWidth(dropdown, 180)
        UIDropDownMenu_SetSelectedValue(dropdown, db[key])
        UIDropDownMenu_SetText(dropdown, db[key] or (values[1] or ""))

        return dropdown
    end

    --------------------------------------------------------
    -- TEXTURES
    --------------------------------------------------------
    Header("Textures")

    LSMDropdown("Bar Texture", "barTexture", "statusbar",
        "Texture used for threat bars.")

    LSMDropdown("Background Texture", "backgroundTexture", "background",
        "Background texture for the display.")

    --------------------------------------------------------
    -- FONTS
    --------------------------------------------------------
    Header("Fonts")

    LSMDropdown("Font", "font", "font",
        "Font used for text in the display.")

    Slider("Font Size", "fontSize", 8, 32, 1,
        "Adjust the size of display text.")

    --------------------------------------------------------
    -- COLORS
    --------------------------------------------------------
    Header("Colors")

    ColorSwatch("Bar Color", "barColor",
        { r = 0.8, g = 0.1, b = 0.1, a = 1 })

    Checkbox("Enable Threat Gradient", "threatGradient",
        "Automatically adjust bar color based on threat percentage.")

    --------------------------------------------------------
    -- LAYOUT
    --------------------------------------------------------
    Header("Layout")

    Slider("Bar Height", "barHeight", 8, 40, 1,
        "Height of each threat bar.")

    Slider("Bar Spacing", "barSpacing", 0, 10, 1,
        "Spacing between bars.")

    Slider("List Row Height", "rowHeight", 10, 40, 1,
        "Height of each row in the threat list.")

    Slider("List Row Spacing", "rowSpacing", 0, 10, 1,
        "Spacing between rows in the threat list.")

    --------------------------------------------------------
    -- BEHAVIOR
    --------------------------------------------------------
    Header("Behavior")

    Slider("Smooth Animation Speed", "smoothSpeed", 0, 1, 0.05,
        "Speed of bar smoothing animations.")

    Checkbox("Combat Fade", "combatFade",
        "Fade the display when out of combat.")

    Slider("Combat Fade Opacity", "combatFadeOpacity", 0, 1, 0.05,
        "Opacity of the display when faded.")

    --------------------------------------------------------
    -- PREVIEW
    --------------------------------------------------------
    Header("Preview")

    local previewBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    previewBtn:SetSize(200, 24)
    previewBtn:SetPoint("TOPLEFT", 16, NextLine())
    previewBtn:SetText("Preview Display")
    previewBtn:SetScript("OnClick", function()
        if TS.DisplayPreview and TS.DisplayPreview.IsActive and TS.DisplayPreview:IsActive() then
            TS.DisplayPreview:Stop()
        elseif TS.DisplayPreview and TS.DisplayPreview.Start then
            TS.DisplayPreview:Start()
        end
    end)

    --------------------------------------------------------
    -- Register with Settings API
    --------------------------------------------------------
    local category = Settings.RegisterCanvasLayoutCategory(panel, TS.ConfigCategories.DISPLAY_ADV)
    Settings.RegisterAddOnCategory(category)

    self.panel = panel
end

return DisplayAdvanced