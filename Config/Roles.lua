-- ThreatSense: ConfigRoles.lua
-- Role-based profile settings

local ADDON_NAME, TS = ...
local ConfigRoles = {}
TS.ConfigRoles = ConfigRoles

local PM = TS.ProfileManager

function ConfigRoles:Initialize()
    local category, layout = Settings.RegisterVerticalLayoutCategory("ThreatSense - Roles")
    self.category = category

    ------------------------------------------------------------
    -- Auto-switch toggle
    ------------------------------------------------------------
    local autoVar = Settings.RegisterAddOnSetting(
        category,
        "Auto Switch Profiles",
        "ThreatSenseDB_AutoSwitchProfiles",
        Settings.VarType.Boolean,
        false -- Option B: disabled by default
    )

    Settings.CreateCheckbox(
        layout,
        autoVar,
        "Enable Auto-Switch Profiles",
        "Automatically switch profiles when changing roles."
    )

    ------------------------------------------------------------
    -- Role → Profile mapping
    ------------------------------------------------------------
    local roles = { "TANK", "HEALER", "DAMAGER" }

    for _, role in ipairs(roles) do
        local var = Settings.RegisterAddOnSetting(
            category,
            role .. " Profile",
            "ThreatSenseDB_RoleProfile_" .. role,
            Settings.VarType.String,
            "Default"
        )

        Settings.CreateDropdown(
            layout,
            var,
            function()
                local opts = {}
                for name in pairs(ThreatSenseDB.profiles) do
                    table.insert(opts, { text = name, value = name })
                end
                return opts
            end,
            role .. " Profile",
            "Profile to use when playing as " .. role .. "."
        )
    end

    Settings.RegisterAddOnCategory(category)
end