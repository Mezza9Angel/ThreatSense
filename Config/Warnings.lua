-- ThreatSense: Warnings.lua
-- Warning configuration panel (profile-aware, Settings API category)

local ADDON_NAME, TS = ...
local Warnings = {}
TS.Warnings = Warnings

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

------------------------------------------------------------
-- Internal helpers
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
function Warnings:Initialize()
    if not TS.db or not TS.db.profile then
        return
    end

    local db = TS.db.profile.warnings or {}
    TS.db.profile.warnings = db

    TS.db.profile.colors = TS.db.profile.colors or {}
    TS.db.profile.colors.warnings = TS.db.profile.colors.warnings or {}
    local colorDB = TS.db.profile.colors.warnings

    --------------------------------------------------------
    -- Create panel frame
    --------------------------------------------------------
    local panel = CreateFrame("Frame", "ThreatSenseConfigWarnings", UIParent)
    panel.name   = TS.ConfigCategories.WARNINGS
    panel.parent = TS.ConfigCategories.ROOT

    --------------------------------------------------------
    -- Layout helpers
    --------------------------------------------------------
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
        slider:SetWidth(200)

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

    --------------------------------------------------------
    -- ENABLE / DISABLE
    --------------------------------------------------------
    Header("Warning System")
    Checkbox("Enable Warnings", "enabled", "Turn the warning system on or off.")

    --------------------------------------------------------
    -- WARNING STYLE
    --------------------------------------------------------
    Header("Warning Style")

    Label("Warning Style")

    local styleDropdown = CreateFrame("Frame", "ThreatSenseWarningStyleDropdown", panel, "UIDropDownMenuTemplate")
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
    -- THRESHOLDS
    --------------------------------------------------------
    Header("Warning Thresholds")

    Slider("Aggro Warning Threshold", "aggroThreshold", 50, 100, 1,
        "Trigger warnings when threat exceeds this percentage.")

    Slider("Losing Aggro Threshold", "losingAggroThreshold", 50, 100, 1,
        "Trigger warnings when another player approaches your threat.")

    --------------------------------------------------------
    -- ANIMATION SETTINGS
    --------------------------------------------------------
    Header("Warning Animations")

    Label("Animation Style")

    local animDropdown = CreateFrame("Frame", "ThreatSenseWarningAnimDropdown", panel, "UIDropDownMenuTemplate")
    animDropdown:SetPoint("TOPLEFT", 10, NextLine(-10))

    local anims = {
        { text = "Flash", value = "FLASH" },
        { text = "Pulse", value = "PULSE" },
        { text = "Shake", value = "SHAKE" },
        { text = "Fade",  value = "FADE"  },
    }

    local function SetAnim(value)
        db.animation = value
        UIDropDownMenu_SetSelectedValue(animDropdown, value)
        UIDropDownMenu_SetText(animDropdown, (function()
            for _, opt in ipairs(anims) do
                if opt.value == value then
                    return opt.text
                end
            end
            return "Flash"
        end)())
        FireProfileChanged()
    end

    UIDropDownMenu_Initialize(animDropdown, function(self, level)
        for _, opt in ipairs(anims) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.text
            info.value = opt.value
            info.func = function()
                SetAnim(opt.value)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetWidth(animDropdown, 180)
    UIDropDownMenu_SetSelectedValue(animDropdown, db.animation or "FLASH")
    UIDropDownMenu_SetText(animDropdown, (function()
        local current = db.animation or "FLASH"
        for _, opt in ipairs(anims) do
            if opt.value == current then
                return opt.text
            end
        end
        return "Flash"
    end)())

    --------------------------------------------------------
    -- SOUND SETTINGS
    --------------------------------------------------------
    Header("Warning Sounds")

    LSMDropdown("Warning Sound", "sound", "sound", "Sound played when a warning triggers.")

    Slider("Sound Cooldown (seconds)", "soundCooldown", 0, 10, 0.5,
        "Minimum time between repeated warning sounds.")

    --------------------------------------------------------
    -- WARNING COLORS
    --------------------------------------------------------
    Header("Warning Colors")

    ColorSwatch("Aggro Lost",      "AGGRO_LOST",     { r = 1,   g = 0.2, b = 0.2, a = 1 })
    ColorSwatch("Taunt Needed",    "TAUNT",          { r = 1,   g = 0.5, b = 0.1, a = 1 })
    ColorSwatch("Losing Aggro",    "LOSING_AGGRO",   { r = 1,   g = 0.8, b = 0.1, a = 1 })
    ColorSwatch("Pulling Aggro",   "PULLING_AGGRO",  { r = 1,   g = 0.8, b = 0.1, a = 1 })
    ColorSwatch("Aggro Pulled",    "AGGRO_PULLED",   { r = 1,   g = 0.2, b = 0.2, a = 1 })

    --------------------------------------------------------
    -- PREVIEW
    --------------------------------------------------------
    Header("Preview")

    local function Button(label, tooltip, onClick)
        local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        btn:SetSize(220, 24)
        btn:SetPoint("TOPLEFT", 16, NextLine())
        btn:SetText(label)
        btn.tooltipText = tooltip
        btn:SetScript("OnClick", onClick)
        return btn
    end

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
    local category = Settings.RegisterCanvasLayoutCategory(panel, TS.ConfigCategories.WARNINGS)
    Settings.RegisterAddOnCategory(category)

    self.panel = panel
end

return Warnings