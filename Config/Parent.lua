-- ThreatSense: Parent.lua
-- Root settings panel using the modern Blizzard Settings API

local ADDON_NAME, TS = ...
local Parent = {}
TS.Parent = Parent

local VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "Unknown"
local AUTHOR  = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Author") or "Unknown"

------------------------------------------------------------
-- Central category registry (used by all config modules)
------------------------------------------------------------
TS.ConfigCategories = {
    ROOT            = "ThreatSense",
    DISPLAY         = "ThreatSense - Display",
    DISPLAY_ADV     = "ThreatSense - Display (Advanced)",
    WARNINGS        = "ThreatSense - Warnings",
    WARNINGS_ADV    = "ThreatSense - Warnings (Advanced)",
    ROLES           = "ThreatSense - Roles",
    PROFILES        = "ThreatSense - Profiles",
    MEDIA           = "ThreatSense - Media",
    COLORS          = "ThreatSense - Colors",
    FONTS           = "ThreatSense - Fonts",
    TEXTURES        = "ThreatSense - Textures",
    DEVELOPER       = "ThreatSense - Developer",
}

------------------------------------------------------------
-- Helper: Create a navigation button
------------------------------------------------------------
local function CreateNavButton(panel, label, tooltip, callback)
    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetSize(200, 24)
    btn:SetText(label)
    btn.tooltipText = tooltip
    btn:SetScript("OnClick", callback)
    return btn
end

------------------------------------------------------------
-- Initialize the Parent Settings Panel
------------------------------------------------------------
function Parent:Initialize()
    --------------------------------------------------------
    -- Create the actual frame for the settings panel
    --------------------------------------------------------
    local panel = CreateFrame("Frame", "ThreatSenseConfigRoot", UIParent)
    panel.name = TS.ConfigCategories.ROOT

    --------------------------------------------------------
    -- Title
    --------------------------------------------------------
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ThreatSense")

    --------------------------------------------------------
    -- Info text
    --------------------------------------------------------
    local info = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    info:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    info:SetText("Version: " .. VERSION .. "\nAuthor: " .. AUTHOR)

    --------------------------------------------------------
    -- Navigation Buttons
    --------------------------------------------------------
    local y = -80
    local function AddButton(label, tooltip, callback)
        local btn = CreateNavButton(panel, label, tooltip, callback)
        btn:SetPoint("TOPLEFT", 16, y)
        y = y - 30
    end

    AddButton("Display Settings",
        "Configure threat bars, list, textures, fonts, and layout.",
        function() Settings.OpenToCategory(TS.ConfigCategories.DISPLAY) end)

    AddButton("Advanced Display Settings",
        "Configure textures, fonts, colors, layout, and behavior.",
        function() Settings.OpenToCategory(TS.ConfigCategories.DISPLAY_ADV) end)

    AddButton("Warning Settings",
        "Configure warning types, thresholds, visuals, and sounds.",
        function() Settings.OpenToCategory(TS.ConfigCategories.WARNINGS) end)

    AddButton("Advanced Warning Settings",
        "Configure advanced warning visuals, thresholds, and audio.",
        function() Settings.OpenToCategory(TS.ConfigCategories.WARNINGS_ADV) end)

    AddButton("Role Settings",
        "Configure role detection and optional auto-switch profiles.",
        function() Settings.OpenToCategory(TS.ConfigCategories.ROLES) end)

    AddButton("Profile Settings",
        "Manage profiles: create, copy, delete, and switch.",
        function() Settings.OpenToCategory(TS.ConfigCategories.PROFILES) end)

    AddButton("Media Settings",
        "Configure fonts, textures, and shared media.",
        function() Settings.OpenToCategory(TS.ConfigCategories.MEDIA) end)

    AddButton("Color Settings",
        "Configure threat colors, role colors, and warning colors.",
        function() Settings.OpenToCategory(TS.ConfigCategories.COLORS) end)

    AddButton("Font Settings",
        "Configure fonts for all UI elements.",
        function() Settings.OpenToCategory(TS.ConfigCategories.FONTS) end)

    AddButton("Texture Settings",
        "Configure textures for bars and backgrounds.",
        function() Settings.OpenToCategory(TS.ConfigCategories.TEXTURES) end)

    AddButton("Developer Tools",
        "Debug tools, raw data views, and event logs.",
        function() Settings.OpenToCategory(TS.ConfigCategories.DEVELOPER) end)

    --------------------------------------------------------
    -- Preview Buttons
    --------------------------------------------------------
    AddButton("Preview Display",
        "Show a live preview of the threat display.",
        function()
            if TS.DisplayPreview:IsActive() then
                TS.DisplayPreview:Stop()
            else
                TS.DisplayPreview:Start()
            end
        end)

    AddButton("Preview Warnings",
        "Show a live preview of warning alerts.",
        function()
            if TS.WarningPreview:IsActive() then
                TS.WarningPreview:Stop()
            else
                TS.WarningPreview:StartRandom()
            end
        end)

    --------------------------------------------------------
    -- Test Mode
    --------------------------------------------------------
    AddButton("Start Test Mode",
        "Simulate combat, threat, and warnings for full UI testing.",
        function()
            TS.EventBus:Send("TEST_MODE_STARTED")
        end)

    --------------------------------------------------------
    -- Register with the new Settings API
    --------------------------------------------------------
    local category = Settings.RegisterCanvasLayoutCategory(panel, TS.ConfigCategories.ROOT)
    Settings.RegisterAddOnCategory(category)

    self.panel = panel
end

return Parent