-- ThreatSense: WarningsAdvanced.lua
-- Advanced warning configuration using the modern Settings API

local ADDON_NAME, TS = ...
local ConfigWarningsAdvanced = {}
TS.ConfigWarningsAdvanced = ConfigWarningsAdvanced

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
-- Helper: Create a checkbox
------------------------------------------------------------
local function CreateCheckbox(layout, label, key, default, description)
    local setting = Settings.RegisterAddOnSetting(
        layout:GetCategory(),
        label,
        "ThreatSenseDB_" .. key,
        Settings.VarType.Boolean,
        default
    )

    Settings.CreateCheckbox(
        layout,
        setting,
        label,
        description
    )

    setting:SetValueChangedCallback(function(value)
        PM:Set(key, value)
        TS.EventBus:Emit("WARNING_SETTING_CHANGED", key, value)
        if TS.WarningPreview:IsActive() then
            TS.WarningPreview:Start()
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
        TS.EventBus:Emit("WARNING_SETTING_CHANGED", key, value)
        if TS.WarningPreview:IsActive() then
            TS.WarningPreview:Start()
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
        TS.EventBus:Emit("WARNING_SETTING_CHANGED", key, value)
        if TS.WarningPreview:IsActive() then
            TS.WarningPreview:Start()
        end
    end)
end

------------------------------------------------------------
-- Initialize the Advanced Warnings Panel
------------------------------------------------------------
function ConfigWarningsAdvanced:Initialize()
    local category, layout = Settings.RegisterVerticalLayoutCategory("ThreatSense - Warnings (Advanced)")
    self.category = category

    ------------------------------------------------------------
    -- Section: Warning Types
    ------------------------------------------------------------
    CreateHeader(layout, "Warning Types")

    CreateCheckbox(
        layout,
        "Taunt Warning",
        "warnTaunt",
        true,
        "Show a warning when another player is tanking your target."
    )

    CreateCheckbox(
        layout,
        "Losing Aggro Warning",
        "warnLosingAggro",
        true,
        "Show a warning when another player is close to overtaking your threat."
    )

    CreateCheckbox(
        layout,
        "Aggro Lost Warning",
        "warnAggroLost",
        true,
        "Show a warning when you lose aggro on your target."
    )

    CreateCheckbox(
        layout,
        "Pulling Aggro Warning",
        "warnPullingAggro",
        true,
        "Show a warning when you are close to pulling aggro."
    )

    CreateCheckbox(
        layout,
        "Aggro Pulled Warning",
        "warnAggroPulled",
        true,
        "Show a warning when you pull aggro."
    )

    CreateCheckbox(
        layout,
        "Drop Threat Warning",
        "warnDropThreat",
        true,
        "Show a warning when you should reduce threat."
    )

    ------------------------------------------------------------
    -- Section: Thresholds
    ------------------------------------------------------------
    CreateHeader(layout, "Thresholds")

    CreateSlider(
        layout,
        "Tank: Losing Aggro %",
        "tankLosingAggroThreshold",
        50,
        100,
        1,
        80,
        "Show a warning when another player reaches this percentage of your threat."
    )

    CreateSlider(
        layout,
        "DPS: Pulling Aggro %",
        "dpsPullingAggroThreshold",
        50,
        100,
        1,
        90,
        "Show a warning when you reach this percentage of the tank's threat."
    )

    CreateSlider(
        layout,
        "DPS: Drop Threat %",
        "dpsDropThreatThreshold",
        50,
        100,
        1,
        95,
        "Show a warning when you should reduce threat."
    )

    CreateSlider(
        layout,
        "Healer: Pulling Aggro %",
        "healerPullingAggroThreshold",
        50,
        100,
        1,
        90,
        "Show a warning when you reach this percentage of the tank's threat."
    )

    ------------------------------------------------------------
    -- Section: Visuals
    ------------------------------------------------------------
    CreateHeader(layout, "Visuals")

    CreateSlider(
        layout,
        "Icon Size",
        "warningIconSize",
        16,
        128,
        1,
        64,
        "Adjust the size of the warning icon."
    )

    local styleSetting = Settings.RegisterAddOnSetting(
        category,
        "Warning Style",
        "ThreatSenseDB_warningStyle",
        Settings.VarType.String,
        "ICON"
    )

    local styleOptions = {
        { text = "Icon Only", value = "ICON" },
        { text = "Text Only", value = "TEXT" },
        { text = "Icon + Text", value = "BOTH" },
    }

    Settings.CreateDropdown(
        layout,
        styleSetting,
        styleOptions,
        "Warning Style",
        "Choose how warnings are displayed."
    )

    styleSetting:SetValueChangedCallback(function(value)
        PM:Set("warningStyle", value)
        TS.EventBus:Emit("WARNING_SETTING_CHANGED", "warningStyle", value)
        if TS.WarningPreview:IsActive() then
            TS.WarningPreview:Start()
        end
    end)

    ------------------------------------------------------------
    -- Section: Audio
    ------------------------------------------------------------
    CreateHeader(layout, "Audio")

    CreateLSMDropdown(
        layout,
        "Warning Sound",
        "warningSound",
        "sound",
        "Select a sound to play when a warning triggers."
    )

    CreateSlider(
        layout,
        "Sound Volume",
        "warningVolume",
        0,
        1,
        0.05,
        1,
        "Adjust the volume of warning sounds."
    )

    Settings.CreateControlButton(
        layout,
        "Test Sound",
        "Play the selected warning sound.",
        function()
            local sound = PM:Get("warningSound", "")
            if sound and sound ~= "" then
                local path = LSM:Fetch("sound", sound)
                if path then
                    PlaySoundFile(path, "Master")
                end
            end
        end
    )

    ------------------------------------------------------------
    -- Section: Preview
    ------------------------------------------------------------
    CreateHeader(layout, "Preview")

    Settings.CreateControlButton(
        layout,
        "Preview Warning",
        "Show a live preview of warning alerts.",
        function()
            if TS.WarningPreview:IsActive() then
                TS.WarningPreview:Stop()
            else
                TS.WarningPreview:Start()
            end
        end
    )

    ------------------------------------------------------------
    -- Register Category
    ------------------------------------------------------------
    Settings.RegisterAddOnCategory(category)
end