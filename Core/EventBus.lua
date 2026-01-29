-- ThreatSense: EventBus.lua
-- Lightweight pub/sub event system for decoupled communication

local ADDON_NAME, TS = ...

TS.EventBus = {}
local Bus = TS.EventBus

-- Storage for listeners
Bus.listeners = {}

------------------------------------------------------------
-- Register a listener for an event
-- @param event (string)
-- @param callback (function)
------------------------------------------------------------
function Bus:Register(event, callback)
    if not event or type(callback) ~= "function" then
        return
    end

    if not Bus.listeners[event] then
        Bus.listeners[event] = {}
    end

    table.insert(Bus.listeners[event], {
        callback = callback,
        once = false,
    })
end

------------------------------------------------------------
-- Register a one-time listener
-- @param event (string)
-- @param callback (function)
------------------------------------------------------------
function Bus:RegisterOnce(event, callback)
    if not event or type(callback) ~= "function" then
        return
    end

    if not Bus.listeners[event] then
        Bus.listeners[event] = {}
    end

    table.insert(Bus.listeners[event], {
        callback = callback,
        once = true,
    })
end

------------------------------------------------------------
-- Unregister a callback from an event
-- @param event (string)
-- @param callback (function)
------------------------------------------------------------
function Bus:Unregister(event, callback)
    local list = Bus.listeners[event]
    if not list then return end

    for i = #list, 1, -1 do
        if list[i].callback == callback then
            table.remove(list, i)
        end
    end
end

------------------------------------------------------------
-- Send an event to all listeners
-- @param event (string)
-- @param ... (any)
------------------------------------------------------------
function Bus:Send(event, ...)
    local list = Bus.listeners[event]
    if not list then return end

    -- Iterate backwards so we can remove one-time listeners safely
    for i = #list, 1, -1 do
        local entry = list[i]

        -- Protected call so one bad listener doesn't break the addon
        local ok, err = pcall(entry.callback, ...)
        if not ok then
            print("|cffff0000[ThreatSense EventBus Error]|r", err)
        end

        if entry.once then
            table.remove(list, i)
        end
    end
end

------------------------------------------------------------
-- Initialize (reserved for future expansion)
------------------------------------------------------------
function Bus:Initialize()
    -- Nothing needed yet, but this keeps Init.lua clean
end