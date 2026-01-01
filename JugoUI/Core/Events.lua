--[[
    JugoUI - Events.lua
    Central event handling system
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

-- Event frame
local eventFrame = CreateFrame("Frame", "JugoUIEventFrame")

-- Registered handlers
local eventHandlers = {}

--[[
    Event Registration
]]
function E:RegisterEvent(event, handler, owner)
    if not eventHandlers[event] then
        eventHandlers[event] = {}
        eventFrame:RegisterEvent(event)
    end

    local key = owner or handler
    eventHandlers[event][key] = handler
end

function E:UnregisterEvent(event, owner)
    if eventHandlers[event] then
        eventHandlers[event][owner] = nil

        -- Unregister from frame if no handlers left
        local hasHandlers = false
        for _ in pairs(eventHandlers[event]) do
            hasHandlers = true
            break
        end

        if not hasHandlers then
            eventFrame:UnregisterEvent(event)
            eventHandlers[event] = nil
        end
    end
end

function E:UnregisterAllEvents(owner)
    for event, handlers in pairs(eventHandlers) do
        handlers[owner] = nil

        local hasHandlers = false
        for _ in pairs(handlers) do
            hasHandlers = true
            break
        end

        if not hasHandlers then
            eventFrame:UnregisterEvent(event)
            eventHandlers[event] = nil
        end
    end
end

--[[
    Unit Event Registration (12.0 style)
]]
function E:RegisterUnitEvent(event, unit1, unit2, handler, owner)
    local key = event .. (unit1 or "") .. (unit2 or "")

    if not eventHandlers[key] then
        eventHandlers[key] = {}
        if unit2 then
            eventFrame:RegisterUnitEvent(event, unit1, unit2)
        else
            eventFrame:RegisterUnitEvent(event, unit1)
        end
    end

    local handlerKey = owner or handler
    eventHandlers[key][handlerKey] = {
        handler = handler,
        event = event,
    }
end

--[[
    Event Frame Script
]]
eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- Check for direct event handlers
    if eventHandlers[event] then
        for owner, handler in pairs(eventHandlers[event]) do
            if type(handler) == "function" then
                handler(event, ...)
            elseif type(handler) == "string" then
                if owner[handler] then
                    owner[handler](owner, event, ...)
                end
            end
        end
    end
end)

--[[
    Commonly Used Events Preregistration
    These are registered by default for core functionality
]]
local coreEvents = {
    "ADDON_LOADED",
    "PLAYER_LOGIN",
    "PLAYER_LOGOUT",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_LEAVING_WORLD",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED",
    "ZONE_CHANGED",
    "ZONE_CHANGED_NEW_AREA",
    "ZONE_CHANGED_INDOORS",
    "CVAR_UPDATE",
    "DISPLAY_SIZE_CHANGED",
    "UI_SCALE_CHANGED",
}

for _, event in ipairs(coreEvents) do
    eventFrame:RegisterEvent(event)
end

-- Combat state tracking
local inCombat = false

eventHandlers["PLAYER_REGEN_DISABLED"] = {
    core = function()
        inCombat = true
        E.callbacks:Fire("JugoUI_CombatEnter")
    end
}

eventHandlers["PLAYER_REGEN_ENABLED"] = {
    core = function()
        inCombat = false
        E.callbacks:Fire("JugoUI_CombatLeave")

        -- Process combat-delayed functions
        if E.delayedFunctions then
            for _, func in ipairs(E.delayedFunctions) do
                func()
            end
            E.delayedFunctions = nil
        end
    end
}

--[[
    Helper to delay function until out of combat
]]
function E:DelayUntilOutOfCombat(func)
    if not inCombat then
        func()
    else
        E.delayedFunctions = E.delayedFunctions or {}
        tinsert(E.delayedFunctions, func)
    end
end

--[[
    Check combat state
]]
function E:InCombat()
    return inCombat
end

--[[
    12.0 Event Callback System Integration
]]
if RegisterEventCallback then
    -- Store callback handles
    E.eventCallbackHandles = {}

    function E:RegisterEventCallback(event, callback)
        local handle = RegisterEventCallback(event, callback)
        E.eventCallbackHandles[callback] = handle
        return handle
    end

    function E:UnregisterEventCallback(callback)
        local handle = E.eventCallbackHandles[callback]
        if handle and UnregisterEventCallback then
            UnregisterEventCallback(handle)
            E.eventCallbackHandles[callback] = nil
        end
    end
end

--[[
    Secure Frame for Combat Lockdown Handling
]]
E.secureFrame = CreateFrame("Frame", "JugoUISecureFrame", UIParent, "SecureHandlerStateTemplate")

-- State driver for combat
RegisterStateDriver(E.secureFrame, "combat", "[combat] combat; nocombat")

E.secureFrame:SetAttribute("_onstate-combat", [[
    local state = newstate
    if state == "combat" then
        -- In combat - apply restrictions
        control:CallMethod("OnCombatEnter")
    else
        -- Out of combat - remove restrictions
        control:CallMethod("OnCombatLeave")
    end
]])

function E.secureFrame:OnCombatEnter()
    -- Called from secure handler when entering combat
end

function E.secureFrame:OnCombatLeave()
    -- Called from secure handler when leaving combat
end
