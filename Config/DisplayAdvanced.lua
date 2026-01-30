-- ThreatSense: DisplayAdvanced.lua
-- Advanced display configuration using the modern Settings API

local ADDON_NAME, TS = ...
local ConfigDisplayAdvanced = {}
TS.ConfigDisplayAdvanced = ConfigDisplayAdvanced

local PM = TS.ProfileManager
local LSM = LibStub("LibSharedMedia-3.0")

------------------------------------------------------------
-- Helper: Create a grouped header
------------------------------------------------------------
local function CreateHeader(layout, text)
    local header = layout:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetText(text)
    header:SetPoint("TOPLEFT", 0, -12)
    return header
end

------------------------------------------------------------
-- Helper: Create a color picker
------------------------------------------------------------
local function CreateColorPicker(layout, label, key, default)
    local setting = Settings.RegisterAddOnSetting(
        layout:GetCategory(),
        label,
        "ThreatSenseDB_" .. key,
        Settings.VarType.Color,
        default
    )

    Settings.CreateColorPicker(
        layout,
        setting,
        label,
        "Adjust the color used for this display element."
    )

    setting:SetValueChangedCallback(function(value)
        PM:Set(key, value)
        TS.EventBus:Emit("DISPLAY_SETTING_CHANGED", key, value)
        if TS.DisplayPreview:IsActive() then
            TS.DisplayPreview:Refresh()
        end
    end)
end

------------------------------------------------------------
-- Helper: Create a slider
------------------------------------------------------------
local function CreateSlider(layout, label, key, min, max, step, default, description)
    local setting = Settings.RegisterAddOnSetting(
        layout:GetCategory(),
        label,
        "ThreatSenseDB_" .. key,
        Settings.VarType.Number,
        default
    )

    Settings.CreateSlider(
        layout,
        setting,
        label,
        description,
        min,
        max,
        step
    )

    setting:SetValueChangedCallback(function(value)
        PM:Set(key, value)
        TS.EventBus:Emit("DISPLAY_SETTING_CHANGED", key, value)
        if TS.DisplayPreview:IsActive() then
            TS.DisplayPreview:Refresh()
        end
    end)
end

------------------------------------------------------------
-- Helper: Create a dropdown (LSM)
------------------------------------------------------------
local function CreateLSMDropdown(layout, label, key, mediaType, description)
    local setting = Settings.RegisterAddOnSetting(
        layout:GetCategory(),
        label,
        "ThreatSenseDB_" .. key,
        Settings.VarType.String,
        ""
    )

    local function BuildOptions()
        local opts = {}
        for _, name in ipairs(LSM:List(mediaType)) do
            table.insert(opts, { text = name, value = name })
        end
        return opts
    end

    Settings.CreateDropdown(
        layout,
        setting,
        BuildOptions(),
        label,
        description
    )

    setting:SetValueChangedCallback(function(value)
        PM:Set(key, value)
        TS.EventBus:Emit("DISPLAY_SETTING_CHANGED", key, value)
        if TS.DisplayPreview:IsActive() then
            TS.DisplayPreview:Refresh()
        end
    end)
end

------------------------------------------------------------
-- Initialize the Advanced Display Panel
------------------------------------------------------------
function ConfigDisplayAdvanced:Initialize()
    local category, layout = Settings.RegisterVerticalLayoutCategory("ThreatSense - Display (Advanced)")
    self.category = category

    ------------------------------------------------------------
    -- Section: Textures
    ------------------------------------------------------------
    CreateHeader(layout, "Textures")

    CreateLSMDropdown(
        layout,
        "Bar Texture",
        "barTexture",
        "statusbar",
        "Select the texture used for threat bars."
    )

    CreateLSMDropdown(
        layout,
        "Background Texture",
        "backgroundTexture",
        "background",
        "Select the background texture for the display."
    )

    ------------------------------------------------------------
    -- Section: Fonts
    ------------------------------------------------------------
    CreateHeader(layout, "Fonts")

    CreateLSMDropdown(
        layout,
        "Font",
        "font",
        "font",
        "Select the font used for text in the display."
    )

    CreateSlider(
        layout,
        "Font Size",
        "fontSize",
        8,
        32,
        1,
        12,
        "Adjust the size of the display font."
    )

    ------------------------------------------------------------
    -- Section: Colors
    ------------------------------------------------------------
    CreateHeader(layout, "Colors")

    CreateColorPicker(
        layout,
        "Bar Color",
        "barColor",
        { r = 0.8, g = 0.1, b = 0.1, a = 1 }
    )

    local gradientSetting = Settings.RegisterAddOnSetting(
        category,
        "Threat Gradient",
        "ThreatSenseDB_threatGradient",
        Settings.VarType.Boolean,
        true
    )

    Settings.CreateCheckbox(
        layout,
        gradientSetting,
        "Enable Threat Gradient",
        "Automatically adjust bar color based on threat percentage."
    )

    gradientSetting:SetValueChangedCallback(function(value)
        PM:Set("threatGradient", value)
        TS.EventBus:Emit("DISPLAY_SETTING_CHANGED", "threatGradient", value)
        if TS.DisplayPreview:IsActive() then
            TS.DisplayPreview:Refresh()
        end
    end)

    ------------------------------------------------------------
    -- Section: Layout
    ------------------------------------------------------------
    CreateHeader(layout, "Layout")

    CreateSlider(
        layout,
        "Bar Height",
        "barHeight",
        8,
        40,
        1,
        18,
        "Adjust the height of each threat bar."
    )

    CreateSlider(
        layout,
        "Bar Spacing",
        "barSpacing",
        0,
        10,
        1,
        2,
        "Adjust the spacing between bars."
    )

    CreateSlider(
        layout,
        "List Row Height",
        "rowHeight",
        10,
        40,
        1,
        16,
        "Adjust the height of each row in the threat list."
    )

    CreateSlider(
        layout,
        "List Row Spacing",
        "rowSpacing",
        0,
        10,
        1,
        1,
        "Adjust the spacing between rows in the threat list."
    )

    ------------------------------------------------------------
    -- Section: Behavior
    ------------------------------------------------------------
    CreateHeader(layout, "Behavior")

    CreateSlider(
        layout,
        "Smooth Animation Speed",
        "smoothSpeed",
        0,
        1,
        0.05,
        0.2,
        "Adjust the speed of bar smoothing animations."
    )

    local fadeSetting = Settings.RegisterAddOnSetting(
        category,
        "Combat Fade",
        "ThreatSenseDB_combatFade",
        Settings.VarType.Boolean,
        false
    )

    Settings.CreateCheckbox(
        layout,
        fadeSetting,
        "Enable Combat Fade",
        "Fade the display when out of combat."
    )

    fadeSetting:SetValueChangedCallback(function(value)
        PM:Set("combatFade", value)
        TS.EventBus:Emit("DISPLAY_SETTING_CHANGED", "combatFade", value)
    end)

    CreateSlider(
        layout,
        "Combat Fade Opacity",
        "combatFadeOpacity",
        0,
        1,
        0.05,
        0.4,
        "Adjust the opacity of the display when faded."
    )

    ------------------------------------------------------------
    -- Section: Preview
    ------------------------------------------------------------
    CreateHeader(layout, "Preview")

    Settings.CreateControlButton(
        layout,
        "Preview Display",
        "Show a live preview of the threat display.",
        function()
            if TS.DisplayPreview:IsActive() then
                TS.DisplayPreview:Stop()
            else
                TS.DisplayPreview:Start()
            end
        end
    )

    ------------------------------------------------------------
    -- Register Category
    ------------------------------------------------------------
    Settings.RegisterAddOnCategory(category)
end