-- ThreatSense: SharedMedia.lua
-- Registers ThreatSense with LibSharedMedia and provides a unified media API

local ADDON_NAME, TS = ...
local Media = {}
TS.Media = Media

local LSM = LibStub("LibSharedMedia-3.0")

------------------------------------------------------------
-- Register addon namespace with LSM
------------------------------------------------------------
function Media:Initialize()
    -- No custom textures/fonts bundled (Option B)
    -- But we still register our addon name for clarity
    LSM:Register("statusbar", "ThreatSense Default", "Interface\\TARGETINGFRAME\\UI-StatusBar")
    LSM:Register("background", "ThreatSense Default", "Interface\\Buttons\\WHITE8x8")
    LSM:Register("font", "ThreatSense Default", "Fonts\\FRIZQT__.TTF")
end

------------------------------------------------------------
-- Fetch a statusbar texture
------------------------------------------------------------
function Media:Statusbar(name)
    if name and name ~= "" then
        local tex = LSM:Fetch("statusbar", name, true)
        if tex then return tex end
    end
    return LSM:Fetch("statusbar", "ThreatSense Default")
end

------------------------------------------------------------
-- Fetch a background texture
------------------------------------------------------------
function Media:Background(name)
    if name and name ~= "" then
        local tex = LSM:Fetch("background", name, true)
        if tex then return tex end
    end
    return LSM:Fetch("background", "ThreatSense Default")
end

------------------------------------------------------------
-- Fetch a font
------------------------------------------------------------
function Media:Font(name)
    if name and name ~= "" then
        local font = LSM:Fetch("font", name, true)
        if font then return font end
    end
    return LSM:Fetch("font", "ThreatSense Default")
end

------------------------------------------------------------
-- Fetch a sound
------------------------------------------------------------
function Media:Sound(name)
    if name and name ~= "" then
        local sound = LSM:Fetch("sound", name, true)
        if sound then return sound end
    end
    return nil
end