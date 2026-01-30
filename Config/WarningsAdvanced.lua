-- ThreatSense: WarningsAdvanced.lua
-- Advanced warning configuration (profile-aware, WarningEngine 2.0)

local ADDON_NAME, TS = ...
local WarningsAdvanced = {}
TS.WarningsAdvanced = WarningsAdvanced

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function FireProfileChanged()
    if TS.EventBus and TS.EventBus.Send then
        TS.EventBus:Send("PROFILE_CHANGED")
    end
    if TS.WarningPreview and TS.WarningPreview.IsActive and TS.WarningPreview:IsActive() then
        TS.WarningPreview:StartRandom()
    end
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function WarningsAdvanced:Initialize()
    if not TS.db or not TS.db.profile then
        return
    end

    local db = TS.db.profile.warnings or {}
    TS.db.profile.warnings = db

    TS.db.profile.colors = TS.db.profile.colors or {}
    TS.db.profile.colors.warnings = TS.db.profile.colors.warnings or {}
    local colorDB = TS.db.profile.colors.warnings

    --------------------------------------------------------
    -- Panel frame
    --------------------------------------------------------
    local panel = CreateFrame("Frame", "ThreatSenseConfigWarningsAdvanced", UIParent)
    panel.name   = TS.ConfigCategories.WARNINGS_ADV
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

    local function Checkbox(label, key, description)
        local check = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
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

    local function Button(label, tooltip, onClick)
        local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        btn:SetSize(220, 24)
        btn:SetPoint("TOPLEFT", 16, NextLine())
        btn:SetText(label)
        btn.tooltipText = tooltip
        btn:SetScript("OnClick", onClick)
        return btn
    end

    --------------------------------------------------------
    -- WARNING TYPES
    --------------------------------------------------------
    Header("Warning Types")

    Checkbox("Taunt Warning", "warnTaunt",
        "Show a warning when another player is tanking your target.")

    Checkbox("Losing Aggro Warning", "warnLosingAggro",
        "Show a warning when another player is close to overtaking your threat.")

    Checkbox("Aggro Lost Warning", "warnAggroLost",
        "Show a warning when you lose aggro on your target.")

    Checkbox("Pulling Aggro Warning", "warnPullingAggro",
        "Show a warning when you are close to pulling aggro.")

    Checkbox("Aggro Pulled Warning", "warnAggroPulled",
        "Show a warning when you pull aggro.")

    Checkbox("Drop Threat Warning", "warnDropThreat",
        "Show a warning when you should reduce threat.")

    --------------------------------------------------------
    -- THRESHOLDS
    --------------------------------------------------------
    Header("Thresholds")

    Slider("Tank: Losing Aggro %", "tankLosingAggroThreshold",
        50, 100, 1,
        "Show a warning when another player reaches this percentage of your threat.")

    Slider("DPS: Pulling Aggro %", "dpsPullingAggroThreshold",
        50, 100, 1,
        "Show a warning when you reach this percentage of the tank's threat.")

    Slider("DPS: Drop Threat %", "dpsDropThreatThreshold",
        50, 100, 1,
        "Show a warning when you should reduce threat.")

    Slider("Healer: Pulling Aggro %", "healerPullingAggroThreshold",
        50, 100, 1,
        "Show a warning when you reach this percentage of the tank's threat.")

    --------------------------------------------------------
    -- VISUALS
    --------------------------------------------------------
    Header("Visuals")

    Slider("Icon Size", "warningIconSize",
        16, 128, 1,
        "Adjust the size of the warning icon.")

    Label("Warning Style")

    local styleDropdown = CreateFrame("Frame", "ThreatSenseWarningStyleAdvancedDropdown", panel, "UIDropDownMenuTemplate")
    styleDropdown:SetPoint("TOPLEFT", 10, NextLine(-10))

    local styles = {
        { text = "Icon Only",   value = "ICON" },
        { text = "Text Only",   value = "TEXT" },
        { text = "Icon + Text", value = "BOTH" },
    }

    local function SetStyle(value)
        db.style = value
        UIDropDownMenu_SetSelectedValue(styleDropdown, value)
        UIDropDownMenu_SetText(styleDropdown, (function()
            for _, opt in ipairs(styles) do
                if opt.value == value then
                    return opt.text
                end
            end
            return "Icon + Text"
        end)())
        FireProfileChanged()
    end

    UIDropDownMenu_Initialize(styleDropdown, function(self, level)
        for _, opt in ipairs(styles) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.text
            info.value = opt.value
            info.func = function()
                SetStyle(opt.value)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetWidth(styleDropdown, 180)
    UIDropDownMenu_SetSelectedValue(styleDropdown, db.style or "BOTH")
    UIDropDownMenu_SetText(styleDropdown, (function()
        local current = db.style or "BOTH"
        for _, opt in ipairs(styles) do
            if opt.value == current then
                return opt.text
            end
        end
        return "Icon + Text"
    end)())

    --------------------------------------------------------
    -- AUDIO
    --------------------------------------------------------
    Header("Audio")

    LSMDropdown("Warning Sound", "sound", "sound",
        "Select a sound to play when a warning triggers.")

    Slider("Sound Volume", "soundVolume",
        0, 1, 0.05,
        "Adjust the volume of warning sounds.")

    Button("Test Sound",
        "Play the selected warning sound.",
        function()
            local sound = db.sound
            if sound and sound ~= "" and LSM then
                local path = LSM:Fetch("sound", sound)
                if path then
                    PlaySoundFile(path, "Master")
                end
            end
        end)

    --------------------------------------------------------
    -- WARNING COLORS
    --------------------------------------------------------
    Header("Warning Colors")

    ColorSwatch("Aggro Lost",      "AGGRO_LOST",
        { r = 1, g = 0.2, b = 0.2, a = 1 })

    ColorSwatch("Taunt Needed",    "TAUNT",
        { r = 1, g = 0.5, b = 0.1, a = 1 })

    ColorSwatch("Losing Aggro",    "LOSING_AGGRO",
        { r = 1, g = 0.8, b = 0.1, a = 1 })

    ColorSwatch("Pulling Aggro",   "PULLING_AGGRO",
        { r = 1, g = 0.8, b = 0.1, a = 1 })

    ColorSwatch("Aggro Pulled",    "AGGRO_PULLED",
        { r = 1, g = 0.2, b = 0.2, a = 1 })

    --------------------------------------------------------
    -- PREVIEW
    --------------------------------------------------------
    Header("Preview")

    Button("Preview Random Warning",
        "Show a random warning scenario.",
        function()
            if TS.WarningPreview and TS.WarningPreview.IsActive and TS.WarningPreview:IsActive() then
                TS.WarningPreview:Stop()
            elseif TS.WarningPreview and TS.WarningPreview.StartRandom then
                TS.WarningPreview:StartRandom()
            end
        end)

    Button("Preview: Tank Losing Aggro",
        "Simulate a tank losing aggro.",
        function()
            if TS.WarningPreview and TS.WarningPreview.StartScenario then
                TS.WarningPreview:StartScenario("TANK_LOSING")
            end
        end)

    Button("Preview: DPS Pulling",
        "Simulate a DPS pulling threat.",
        function()
            if TS.WarningPreview and TS.WarningPreview.StartScenario then
                TS.WarningPreview:StartScenario("DPS_PULLING")
            end
        end)

    Button("Stop Preview",
        "Stop all warning previews.",
        function()
            if TS.WarningPreview and TS.WarningPreview.Stop then
                TS.WarningPreview:Stop()
            end
        end)

    --------------------------------------------------------
    -- Register with Settings API
    --------------------------------------------------------
    local category = Settings.RegisterCanvasLayoutCategory(panel, TS.ConfigCategories.WARNINGS_ADV)
    Settings.RegisterAddOnCategory(category)

    self.panel = panel
end

return WarningsAdvanced