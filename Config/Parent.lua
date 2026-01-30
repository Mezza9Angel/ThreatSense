-- ThreatSense: ConfigParent.lua
-- Root settings panel for the addon

local ADDON_NAME, TS = ...
local ConfigParent = {}
TS.ConfigParent = ConfigParent

local VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "Unknown"
local AUTHOR  = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Author") or "Unknown"

------------------------------------------------------------
-- Helper: Create a navigation button
------------------------------------------------------------
local function CreateNavButton(layout, text, description, callback)
    Settings.CreateControlButton(
        layout,
        text,
        description,
        callback
    )
end

------------------------------------------------------------
-- Initialize the Parent Settings Panel
------------------------------------------------------------
function ConfigParent:Initialize()
    local category, layout = Settings.RegisterVerticalLayoutCategory("ThreatSense")
    self.category = category

    ------------------------------------------------------------
    -- Header: Addon Info
    ------------------------------------------------------------
    local header = layout:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetText("ThreatSense")
    header:SetPoint("TOPLEFT", 0, -4)

    local info = layout:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    info:SetText("Version: " .. VERSION .. "\nAuthor: " .. AUTHOR)
    info:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)

    ------------------------------------------------------------
    -- Navigation Buttons
    ------------------------------------------------------------
    CreateNavButton(
        layout,
        "Open Display Settings",
        "Configure threat bars, list, textures, fonts, and layout.",
        function()
            Settings.OpenToCategory("ThreatSense - Display")
        end
    )

    CreateNavButton(
        layout,
        "Open Advanced Display Settings",
        "Configure textures, fonts, colors, layout, and behavior.",
        function()
            Settings.OpenToCategory("ThreatSense - Display (Advanced)")
        end
    )

    CreateNavButton(
        layout,
        "Open Warning Settings",
        "Configure warning types, thresholds, visuals, and sounds.",
        function()
            Settings.OpenToCategory("ThreatSense - Warnings")
        end
    )

    CreateNavButton(
        layout,
        "Open Advanced Warning Settings",
        "Configure advanced warning visuals, thresholds, and audio.",
        function()
            Settings.OpenToCategory("ThreatSense - Warnings (Advanced)")
        end
    )

    CreateNavButton(
        layout,
        "Open Role Settings",
        "Configure role detection and optional auto-switch profiles.",
        function()
            Settings.OpenToCategory("ThreatSense - Roles")
        end
    )

    CreateNavButton(
        layout,
        "Open Profile Settings",
        "Manage profiles: create, copy, delete, and switch.",
        function()
            Settings.OpenToCategory("ThreatSense - Profiles")
        end
    )

    ------------------------------------------------------------
    -- Preview Buttons
    ------------------------------------------------------------
    CreateNavButton(
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

    CreateNavButton(
        layout,
        "Preview Warnings",
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
    -- Test Mode Button
    ------------------------------------------------------------
    CreateNavButton(
        layout,
        "Start Test Mode",
        "Simulate combat, threat, and warnings for full UI testing.",
        function()
            TS.EventBus:Emit("TEST_MODE_STARTED")
        end
    )

    ------------------------------------------------------------
    -- Register Category
    ------------------------------------------------------------
    Settings.RegisterAddOnCategory(category)
end