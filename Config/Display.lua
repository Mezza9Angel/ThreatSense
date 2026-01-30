-- ThreatSense: Display.lua
-- Display settings panel (profile-aware, Settings API category)

local ADDON_NAME, TS = ...
local Display = {}
TS.Display = Display

------------------------------------------------------------
-- Initialize the Display Settings Panel
------------------------------------------------------------
function Display:Initialize()
    if not TS.db or not TS.db.profile then
        return
    end

    local db = TS.db.profile.display or {}
    TS.db.profile.display = db

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

    --------------------------------------------------------
    -- Create panel frame
    --------------------------------------------------------
    local panel = CreateFrame("Frame", "ThreatSenseConfigDisplay", UIParent)
    panel.name   = TS.ConfigCategories.DISPLAY
    panel.parent = TS.ConfigCategories.ROOT

    --------------------------------------------------------
    -- Header
    --------------------------------------------------------
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ThreatSense - Display Settings")

    local y = -60
    local function NextLine(offset)
        y = y - (offset or 30)
        return y
    end

    --------------------------------------------------------
    -- Helper: Label
    --------------------------------------------------------
    local function CreateLabel(text)
        local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", 16, NextLine())
        fs:SetText(text)
        return fs
    end

    --------------------------------------------------------
    -- DISPLAY MODE DROPDOWN
    --------------------------------------------------------
    CreateLabel("Display Mode")

    local modeDropdown = CreateFrame("Frame", "ThreatSenseDisplayModeDropdown", panel, "UIDropDownMenuTemplate")
    modeDropdown:SetPoint("TOPLEFT", 10, NextLine(-10))

    local modes = {
        { text = "Automatic (Role-Based)", value = "AUTO" },
        { text = "Bar Only",               value = "BAR_ONLY" },
        { text = "List Only",              value = "LIST_ONLY" },
        { text = "Bar + List",             value = "BAR_AND_LIST" },
    }

    local function SetMode(value)
        db.mode = value
        UIDropDownMenu_SetSelectedValue(modeDropdown, value)
        if TS.DisplayMode and TS.DisplayMode.Set then
            TS.DisplayMode:Set(value)
        end
        if TS.DisplayPreview and TS.DisplayPreview.IsActive and TS.DisplayPreview:IsActive() then
            TS.DisplayPreview:Start()
        end
    end

    UIDropDownMenu_Initialize(modeDropdown, function(self, level)
        for _, opt in ipairs(modes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.text
            info.value = opt.value
            info.func = function()
                SetMode(opt.value)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetWidth(modeDropdown, 180)
    UIDropDownMenu_SetSelectedValue(modeDropdown, db.mode or "AUTO")
    UIDropDownMenu_SetText(modeDropdown, (function()
        local current = db.mode or "AUTO"
        for _, opt in ipairs(modes) do
            if opt.value == current then
                return opt.text
            end
        end
        return "Automatic (Role-Based)"
    end)())

    --------------------------------------------------------
    -- THREAT BAR SETTINGS
    --------------------------------------------------------
    CreateLabel("Threat Bar Settings")

    -- Bar Height Slider
    local barHeightSlider = CreateFrame("Slider", "ThreatSenseBarHeightSlider", panel, "OptionsSliderTemplate")
    barHeightSlider:SetPoint("TOPLEFT", 16, NextLine(-10))
    barHeightSlider:SetMinMaxValues(10, 40)
    barHeightSlider:SetValueStep(1)
    barHeightSlider:SetObeyStepOnDrag(true)
    barHeightSlider:SetWidth(200)
    _G[barHeightSlider:GetName() .. "Text"]:SetText("Bar Height")
    _G[barHeightSlider:GetName() .. "Low"]:SetText("10")
    _G[barHeightSlider:GetName() .. "High"]:SetText("40")

    barHeightSlider:SetValue(db.barHeight or 18)
    barHeightSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        db.barHeight = value
        if TS.EventBus and TS.EventBus.Send then
            TS.EventBus:Send("PROFILE_CHANGED")
        end
    end)

    --------------------------------------------------------
    -- Bar Texture Dropdown (LSM)
    --------------------------------------------------------
    if LSM then
        CreateLabel("Bar Texture")

        local texDropdown = CreateFrame("Frame", "ThreatSenseBarTextureDropdown", panel, "UIDropDownMenuTemplate")
        texDropdown:SetPoint("TOPLEFT", 10, NextLine(-10))

        local textures = {}
        for _, key in ipairs(LSM:List("statusbar")) do
            table.insert(textures, key)
        end

        local function SetTexture(value)
            db.barTexture = value
            UIDropDownMenu_SetSelectedValue(texDropdown, value)
            UIDropDownMenu_SetText(texDropdown, value)
            if TS.EventBus and TS.EventBus.Send then
                TS.EventBus:Send("PROFILE_CHANGED")
            end
        end

        UIDropDownMenu_Initialize(texDropdown, function(self, level)
            for _, key in ipairs(textures) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = key
                info.value = key
                info.func = function()
                    SetTexture(key)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)

        UIDropDownMenu_SetWidth(texDropdown, 180)
        UIDropDownMenu_SetSelectedValue(texDropdown, db.barTexture or "Blizzard")
        UIDropDownMenu_SetText(texDropdown, db.barTexture or "Blizzard")
    end

    --------------------------------------------------------
    -- THREAT LIST SETTINGS
    --------------------------------------------------------
    CreateLabel("Threat List Settings")

    -- Max Entries Slider
    local maxEntriesSlider = CreateFrame("Slider", "ThreatSenseMaxEntriesSlider", panel, "OptionsSliderTemplate")
    maxEntriesSlider:SetPoint("TOPLEFT", 16, NextLine(-10))
    maxEntriesSlider:SetMinMaxValues(3, 10)
    maxEntriesSlider:SetValueStep(1)
    maxEntriesSlider:SetObeyStepOnDrag(true)
    maxEntriesSlider:SetWidth(200)
    _G[maxEntriesSlider:GetName() .. "Text"]:SetText("Max List Entries")
    _G[maxEntriesSlider:GetName() .. "Low"]:SetText("3")
    _G[maxEntriesSlider:GetName() .. "High"]:SetText("10")

    maxEntriesSlider:SetValue(db.maxEntries or 5)
    maxEntriesSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        db.maxEntries = value
        if TS.EventBus and TS.EventBus.Send then
            TS.EventBus:Send("PROFILE_CHANGED")
        end
    end)

    -- List Font Size Slider
    local fontSizeSlider = CreateFrame("Slider", "ThreatSenseListFontSizeSlider", panel, "OptionsSliderTemplate")
    fontSizeSlider:SetPoint("TOPLEFT", 16, NextLine(-40))
    fontSizeSlider:SetMinMaxValues(8, 24)
    fontSizeSlider:SetValueStep(1)
    fontSizeSlider:SetObeyStepOnDrag(true)
    fontSizeSlider:SetWidth(200)
    _G[fontSizeSlider:GetName() .. "Text"]:SetText("List Font Size")
    _G[fontSizeSlider:GetName() .. "Low"]:SetText("8")
    _G[fontSizeSlider:GetName() .. "High"]:SetText("24")

    fontSizeSlider:SetValue(db.fontSize or 12)
    fontSizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        db.fontSize = value
        if TS.EventBus and TS.EventBus.Send then
            TS.EventBus:Send("PROFILE_CHANGED")
        end
    end)

    --------------------------------------------------------
    -- SMOOTHING
    --------------------------------------------------------
    local smoothingCheck = CreateFrame("CheckButton", "ThreatSenseSmoothingCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    smoothingCheck:SetPoint("TOPLEFT", 16, NextLine(-40))
    _G[smoothingCheck:GetName() .. "Text"]:SetText("Enable Smoothing")

    smoothingCheck:SetChecked(db.smoothing ~= false)
    smoothingCheck:SetScript("OnClick", function(self)
        db.smoothing = self:GetChecked() and true or false
        if TS.EventBus and TS.EventBus.Send then
            TS.EventBus:Send("PROFILE_CHANGED")
        end
    end)

    --------------------------------------------------------
    -- Register with Settings API
    --------------------------------------------------------
    local category = Settings.RegisterCanvasLayoutCategory(panel, TS.ConfigCategories.DISPLAY)
    Settings.RegisterAddOnCategory(category)

    self.panel = panel
end

return Display