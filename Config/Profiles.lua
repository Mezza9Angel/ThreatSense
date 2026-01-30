-- ThreatSense: Profiles.lua
-- Modern profile management (AceDB, ProfileManager 2.0)

local ADDON_NAME, TS = ...
local Profiles = {}
TS.Profiles = Profiles

local PM = TS.ProfileManager

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function FireProfileChanged()
    if TS.EventBus and TS.EventBus.Send then
        TS.EventBus:Send("PROFILE_CHANGED")
    end

    if TS.DisplayPreview and TS.DisplayPreview.IsActive and TS.DisplayPreview:IsActive() then
        TS.DisplayPreview:Stop()
    end
    if TS.WarningPreview and TS.WarningPreview.IsActive and TS.WarningPreview:IsActive() then
        TS.WarningPreview:Stop()
    end
end

local function BuildProfileList()
    local list = {}
    for name in pairs(TS.db.profiles) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function Profiles:Initialize()
    if not TS.db or not TS.db.profile then
        return
    end

    local roleDB = TS.db.profile.roles or {}
    TS.db.profile.roles = roleDB

    --------------------------------------------------------
    -- Create panel frame
    --------------------------------------------------------
    local panel = CreateFrame("Frame", "ThreatSenseConfigProfiles", UIParent)
    panel.name   = TS.ConfigCategories.PROFILES
    panel.parent = TS.ConfigCategories.ROOT

    local y = -16
    local function NextLine(offset)
        y = y - (offset or 26)
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

    local function Button(label, tooltip, onClick)
        local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        btn:SetSize(200, 24)
        btn:SetPoint("TOPLEFT", 16, NextLine())
        btn:SetText(label)
        btn.tooltipText = tooltip
        btn:SetScript("OnClick", onClick)
        return btn
    end

    local function Dropdown(label, getValue, setValue, values)
        Label(label)

        local dropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", 10, NextLine(-10))

        local function Refresh()
            UIDropDownMenu_SetSelectedValue(dropdown, getValue())
            UIDropDownMenu_SetText(dropdown, getValue())
        end

        UIDropDownMenu_Initialize(dropdown, function(self, level)
            for _, name in ipairs(values()) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = name
                info.value = name
                info.func = function()
                    setValue(name)
                    Refresh()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)

        UIDropDownMenu_SetWidth(dropdown, 180)
        Refresh()

        return dropdown
    end

    --------------------------------------------------------
    -- ACTIVE PROFILE
    --------------------------------------------------------
    Header("Active Profile")

    Dropdown(
        "Active Profile",
        function() return PM:GetActiveProfileName() end,
        function(newProfile)
            TS.db:SetProfile(newProfile)
            FireProfileChanged()
        end,
        BuildProfileList
    )

    --------------------------------------------------------
    -- PROFILE MANAGEMENT
    --------------------------------------------------------
    Header("Profile Management")

    Button("Create New Profile",
        "Create a new empty profile.",
        function()
            local name = "Profile " .. math.random(1000, 9999)
            TS.db:SetProfile(name)
            FireProfileChanged()
        end
    )

    Button("Copy Current Profile",
        "Duplicate the active profile.",
        function()
            local current = PM:GetActiveProfileName()
            local name = current .. " Copy"

            TS.db:CopyProfile(current)
            TS.db:SetProfile(name)

            FireProfileChanged()
        end
    )

    Button("Reset Profile",
        "Reset the active profile to default settings.",
        function()
            TS.db:ResetProfile()
            FireProfileChanged()
        end
    )

    Button("Delete Profile",
        "Delete the active profile (except Default).",
        function()
            local current = PM:GetActiveProfileName()
            if current ~= "Default" then
                TS.db:DeleteProfile(current)
                TS.db:SetProfile("Default")
                FireProfileChanged()
            end
        end
    )

    --------------------------------------------------------
    -- ROLE-BASED PROFILE SWITCHING
    --------------------------------------------------------
    Header("Role-Based Profile Switching")

    -- Enable auto-switch
    local autoSwitch = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    autoSwitch:SetPoint("TOPLEFT", 16, NextLine())
    _G[autoSwitch:GetName() .. "Text"]:SetText("Enable Auto-Switch")
    autoSwitch.tooltipText = "Automatically switch profiles when your role changes."

    autoSwitch:SetChecked(roleDB.autoSwitch ~= false)
    autoSwitch:SetScript("OnClick", function(self)
        roleDB.autoSwitch = self:GetChecked() and true or false
        FireProfileChanged()
    end)

    -- Role dropdowns
    local roles = { "TANK", "HEALER", "DPS" }

    for _, role in ipairs(roles) do
        Dropdown(
            role .. " Profile",
            function() return roleDB[role] end,
            function(value)
                roleDB[role] = value
                FireProfileChanged()
            end,
            BuildProfileList
        )
    end

    --------------------------------------------------------
    -- Register with Settings API
    --------------------------------------------------------
    local category = Settings.RegisterCanvasLayoutCategory(panel, TS.ConfigCategories.PROFILES)
    Settings.RegisterAddOnCategory(category)

    self.panel = panel
end

return Profiles