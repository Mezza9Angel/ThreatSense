-- ThreatSense: Roles.lua
-- Modern role-based profile settings (AceDB, ProfileManager 2.0)

local ADDON_NAME, TS = ...
local Roles = {}
TS.Roles = Roles

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
function Roles:Initialize()
    if not TS.db or not TS.db.profile then
        return
    end

    local roleDB = TS.db.profile.roles or {}
    TS.db.profile.roles = roleDB

    --------------------------------------------------------
    -- Create panel frame
    --------------------------------------------------------
    local panel = CreateFrame("Frame", "ThreatSenseConfigRoles", UIParent)
    panel.name   = TS.ConfigCategories.ROLES
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

    local function Checkbox(label, key, description)
        local check = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
        check:SetPoint("TOPLEFT", 16, NextLine())
        _G[check:GetName() .. "Text"]:SetText(label)
        check.tooltipText = description

        check:SetChecked(roleDB[key] ~= false)
        check:SetScript("OnClick", function(self)
            roleDB[key] = self:GetChecked() and true or false
            FireProfileChanged()
        end)

        return check
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
    -- AUTO-SWITCH
    --------------------------------------------------------
    Header("Automatic Role Switching")

    Checkbox(
        "Enable Auto-Switch Profiles",
        "autoSwitch",
        "Automatically switch profiles when your role changes."
    )

    --------------------------------------------------------
    -- ROLE → PROFILE MAPPING
    --------------------------------------------------------
    Header("Role-Based Profile Mapping")

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
    -- ROLE DETECTION PREVIEW
    --------------------------------------------------------
    Header("Role Detection")

    local detectBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    detectBtn:SetSize(200, 24)
    detectBtn:SetPoint("TOPLEFT", 16, NextLine())
    detectBtn:SetText("Detect Current Role")
    detectBtn.tooltipText = "Show what role ThreatSense currently detects."
    detectBtn:SetScript("OnClick", function()
        local role = TS.RoleManager:GetCurrentRole() or "UNKNOWN"
        print("|cff00ff00ThreatSense|r detected role: " .. role)
    end)

    --------------------------------------------------------
    -- Register with Settings API
    --------------------------------------------------------
    local category = Settings.RegisterCanvasLayoutCategory(panel, TS.ConfigCategories.ROLES)
    Settings.RegisterAddOnCategory(category)

    self.panel = panel
end

return Roles