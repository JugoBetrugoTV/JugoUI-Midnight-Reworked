--[[ AceHook-3.0 - A library that allows for hooking of functions
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceHook-3.0", 8
local AceHook = LibStub:NewLibrary(MAJOR, MINOR)
if not AceHook then return end

AceHook.embeds = AceHook.embeds or {}
AceHook.registry = AceHook.registry or setmetatable({}, {__index = function(tbl, key) tbl[key] = {} return tbl[key] end})

local _G = _G
local pairs = pairs
local type = type
local format = string.format
local next = next

local registry = AceHook.registry

local protectedScripts = {
    OnClick = true,
}

local function errorhandler(err)
    return geterrorhandler()(err)
end

local function safecall(func, ...)
    if func then
        return xpcall(func, errorhandler, ...)
    end
end

local function hook(self, obj, method, handler, script, secure, raw, forceSecure, usage)
    if type(handler) == "string" then
        if type(self[handler]) ~= "function" then
            error(format("%s: handler '%s' is not a function", usage, handler), 4)
        end
    elseif type(handler) ~= "function" then
        error(format("%s: handler is not a function", usage), 4)
    end

    if script then
        if obj:GetScript(method) == nil and obj:HasScript(method) then
            return
        end
    end

    local uid
    if obj then
        uid = registry[self][obj] and registry[self][obj][method]
    else
        uid = registry[self][method]
    end

    if uid then
        if obj then
            if registry[self][obj][method] then
                return
            end
        else
            if registry[self][method] then
                return
            end
        end
    end

    local orig
    if script then
        orig = obj:GetScript(method) or function() end
    elseif obj then
        orig = obj[method]
    else
        orig = _G[method]
    end

    local hookFunc
    if type(handler) == "string" then
        hookFunc = function(...)
            return self[handler](self, ...)
        end
    else
        hookFunc = function(...)
            return handler(...)
        end
    end

    if script then
        if secure then
            obj:HookScript(method, hookFunc)
        else
            local func = function(...)
                hookFunc(...)
                return orig(...)
            end
            obj:SetScript(method, func)
        end
    elseif obj then
        if secure then
            hooksecurefunc(obj, method, hookFunc)
        else
            local func = function(...)
                hookFunc(...)
                return orig(...)
            end
            obj[method] = func
        end
    else
        if secure then
            hooksecurefunc(method, hookFunc)
        else
            local func = function(...)
                hookFunc(...)
                return orig(...)
            end
            _G[method] = func
        end
    end

    if obj then
        if not registry[self][obj] then registry[self][obj] = {} end
        registry[self][obj][method] = hookFunc
    else
        registry[self][method] = hookFunc
    end
end

local function donothing() end

function AceHook:Hook(obj, method, handler, hookSecure)
    if type(obj) == "string" then
        method, handler, hookSecure = obj, method, handler
        obj = nil
    end

    if handler == true then
        handler, hookSecure = nil, true
    end

    handler = handler or method

    local usage = "Usage: Hook([object], method, [handler], [hookSecure])"

    if obj and type(obj) ~= "table" then
        error(format("%s: 'object' - table expected, got %s", usage, type(obj)), 2)
    end
    if type(method) ~= "string" then
        error(format("%s: 'method' - string expected, got %s", usage, type(method)), 2)
    end

    hook(self, obj, method, handler, false, hookSecure, false, false, usage)
end

function AceHook:HookScript(frame, script, handler)
    if type(frame) ~= "table" or type(frame.IsObjectType) ~= "function" or not frame:IsObjectType("Frame") then
        error("Usage: HookScript(frame, script, [handler]): 'frame' - Frame expected", 2)
    end
    if type(script) ~= "string" then
        error("Usage: HookScript(frame, script, [handler]): 'script' - string expected", 2)
    end

    handler = handler or script

    local usage = "Usage: HookScript(frame, script, [handler])"
    hook(self, frame, script, handler, true, false, false, false, usage)
end

function AceHook:SecureHook(obj, method, handler)
    if type(obj) == "string" then
        method, handler = obj, method
        obj = nil
    end

    handler = handler or method

    local usage = "Usage: SecureHook([object], method, [handler])"

    if obj and type(obj) ~= "table" then
        error(format("%s: 'object' - table expected, got %s", usage, type(obj)), 2)
    end
    if type(method) ~= "string" then
        error(format("%s: 'method' - string expected, got %s", usage, type(method)), 2)
    end

    hook(self, obj, method, handler, false, true, false, false, usage)
end

function AceHook:SecureHookScript(frame, script, handler)
    if type(frame) ~= "table" or type(frame.IsObjectType) ~= "function" or not frame:IsObjectType("Frame") then
        error("Usage: SecureHookScript(frame, script, [handler]): 'frame' - Frame expected", 2)
    end
    if type(script) ~= "string" then
        error("Usage: SecureHookScript(frame, script, [handler]): 'script' - string expected", 2)
    end

    handler = handler or script

    local usage = "Usage: SecureHookScript(frame, script, [handler])"
    hook(self, frame, script, handler, true, true, false, false, usage)
end

function AceHook:RawHook(obj, method, handler, hookSecure)
    if type(obj) == "string" then
        method, handler, hookSecure = obj, method, handler
        obj = nil
    end

    if handler == true then
        handler, hookSecure = nil, true
    end

    handler = handler or method

    local usage = "Usage: RawHook([object], method, [handler], [hookSecure])"

    if obj and type(obj) ~= "table" then
        error(format("%s: 'object' - table expected, got %s", usage, type(obj)), 2)
    end
    if type(method) ~= "string" then
        error(format("%s: 'method' - string expected, got %s", usage, type(method)), 2)
    end

    hook(self, obj, method, handler, false, hookSecure, true, false, usage)
end

function AceHook:RawHookScript(frame, script, handler)
    if type(frame) ~= "table" or type(frame.IsObjectType) ~= "function" or not frame:IsObjectType("Frame") then
        error("Usage: RawHookScript(frame, script, [handler]): 'frame' - Frame expected", 2)
    end
    if type(script) ~= "string" then
        error("Usage: RawHookScript(frame, script, [handler]): 'script' - string expected", 2)
    end

    handler = handler or script

    local usage = "Usage: RawHookScript(frame, script, [handler])"
    hook(self, frame, script, handler, true, false, true, false, usage)
end

function AceHook:Unhook(obj, method)
    if type(obj) == "string" then
        method = obj
        obj = nil
    end

    if obj then
        if registry[self][obj] and registry[self][obj][method] then
            registry[self][obj][method] = nil
        end
    else
        if registry[self][method] then
            registry[self][method] = nil
        end
    end
end

function AceHook:UnhookAll()
    for obj, hooks in pairs(registry[self]) do
        if type(hooks) == "table" then
            for method in pairs(hooks) do
                hooks[method] = nil
            end
        else
            registry[self][obj] = nil
        end
    end
end

function AceHook:IsHooked(obj, method)
    if type(obj) == "string" then
        method = obj
        obj = nil
    end

    if obj then
        return registry[self][obj] and registry[self][obj][method] and true or false
    else
        return registry[self][method] and true or false
    end
end

local mixins = {
    "Hook", "SecureHook", "HookScript", "SecureHookScript",
    "RawHook", "RawHookScript", "Unhook", "UnhookAll", "IsHooked"
}

function AceHook:Embed(target)
    for _, v in pairs(mixins) do
        target[v] = self[v]
    end
    self.embeds[target] = true
    return target
end

function AceHook:OnEmbedDisable(target)
    target:UnhookAll()
end

for addon in pairs(AceHook.embeds) do
    AceHook:Embed(addon)
end
