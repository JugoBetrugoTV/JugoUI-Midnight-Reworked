--[[ AceAddon-3.0 - A framework for creating addon objects
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceAddon-3.0", 13
local AceAddon, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not AceAddon then return end

AceAddon.frame = AceAddon.frame or CreateFrame("Frame")
AceAddon.addons = AceAddon.addons or {}
AceAddon.statuses = AceAddon.statuses or {}
AceAddon.initializequeue = AceAddon.initializequeue or {}
AceAddon.enablequeue = AceAddon.enablequeue or {}
AceAddon.embeds = AceAddon.embeds or {}

local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
local fmt = string.format
local pairs, next, type, unpack = pairs, next, type, unpack
local loadstring, assert, error = loadstring, assert, error
local setmetatable, getmetatable, rawset, rawget = setmetatable, getmetatable, rawset, rawget

local xpcall = xpcall
local function errorhandler(err)
    return geterrorhandler()(err)
end

local function safecall(func, ...)
    if func then
        return xpcall(func, errorhandler, ...)
    end
end

local Dispatchers = {}
setmetatable(Dispatchers, {__index = function(self, k)
    local dispatcher = function(...)
        local ob = self[0]
        if ob then
            local method = ob[k]
            if method then
                return method(ob, ...)
            end
        end
    end
    rawset(self, k, dispatcher)
    return dispatcher
end})

local function EmbedAndStoreName(addon, name)
    addon.name = addon.name or name
    return addon
end

local function NewModule(self, name, prototype, ...)
    if type(name) ~= "string" then error(("Usage: NewModule(name, [prototype, [lib, lib, lib, ...]]): 'name' - string expected got '%s'."):format(type(name)), 2) end
    if self.modules[name] then error(("Usage: NewModule(name, [prototype, [lib, lib, lib, ...]]): 'name' - Module '%s' already exists."):format(name), 2) end

    if type(prototype) == "string" then
        prototype = LibStub:GetLibrary(prototype)
    end

    local module = AceAddon:NewAddon(fmt("%s_%s", self.name or tostring(self), name))
    module.IsModule = function() return true end
    module:SetEnabledState(self.defaultModuleState)
    module.moduleName = name

    if type(prototype) == "table" then
        local mt = getmetatable(module)
        mt.__index = prototype
        setmetatable(module, mt)
    end

    for i = 1, select("#", ...) do
        local libname = select(i, ...)
        safecall(module.Embed, module, LibStub:GetLibrary(libname))
    end

    self.modules[name] = module
    tinsert(self.orderedModules, module)

    return module
end

local function GetModule(self, name, silent)
    if not self.modules[name] and not silent then
        error(("Usage: GetModule(name, silent): 'name' - Cannot find module '%s'."):format(tostring(name)), 2)
    end
    return self.modules[name]
end

local function SetDefaultModuleState(self, state)
    self.defaultModuleState = state
end

local function SetDefaultModulePrototype(self, prototype)
    if type(prototype) == "string" then
        prototype = LibStub:GetLibrary(prototype)
    end
    self.defaultModulePrototype = prototype
end

local function SetEnabledState(self, state)
    self.enabledState = state
end

local function Enable(self)
    self:SetEnabledState(true)
    return AceAddon:EnableAddon(self)
end

local function Disable(self)
    self:SetEnabledState(false)
    return AceAddon:DisableAddon(self)
end

local function EnableModule(self, name)
    local module = self:GetModule(name)
    return module:Enable()
end

local function DisableModule(self, name)
    local module = self:GetModule(name)
    return module:Disable()
end

local function IterateModules(self) return pairs(self.modules) end
local function IterateEmbeds(self) return pairs(AceAddon.embeds[self]) end

local function GetName(self)
    return self.name
end

local function IsEnabled(self)
    return self.enabledState
end

local mixins = {
    NewModule = NewModule,
    GetModule = GetModule,
    Enable = Enable,
    Disable = Disable,
    EnableModule = EnableModule,
    DisableModule = DisableModule,
    IsEnabled = IsEnabled,
    SetEnabledState = SetEnabledState,
    SetDefaultModuleState = SetDefaultModuleState,
    SetDefaultModulePrototype = SetDefaultModulePrototype,
    IterateModules = IterateModules,
    IterateEmbeds = IterateEmbeds,
    GetName = GetName,
}

local function IsModule(self) return false end

function AceAddon:NewAddon(name, ...)
    if type(name) ~= "string" then
        error(("Usage: NewAddon(name, [lib, lib, ...]): 'name' - string expected got '%s'."):format(type(name)), 2)
    end
    if self.addons[name] then
        error(("Usage: NewAddon(name, [lib, lib, ...]): 'name' - Addon '%s' already exists."):format(name), 2)
    end

    local addon = {}
    addon.name = name
    addon.modules = {}
    addon.orderedModules = {}
    addon.defaultModuleState = true
    addon.enabledState = true
    addon.IsModule = IsModule

    for k, v in pairs(mixins) do
        addon[k] = v
    end

    self.addons[name] = addon
    AceAddon.embeds[addon] = {}

    for i = 1, select("#", ...) do
        local libname = select(i, ...)
        self:EmbedLibrary(addon, libname)
    end

    tinsert(AceAddon.initializequeue, addon)
    return addon
end

function AceAddon:GetAddon(name, silent)
    if not silent and not self.addons[name] then
        error(("Usage: GetAddon(name): 'name' - Cannot find an addon named '%s'."):format(tostring(name)), 2)
    end
    return self.addons[name]
end

function AceAddon:EmbedLibrary(addon, libname, silent, offset)
    local lib = LibStub:GetLibrary(libname, true)
    if not lib and not silent then
        error(("Usage: EmbedLibrary(addon, libname, silent, offset): 'libname' - Cannot find a library instance of %q."):format(tostring(libname)), offset or 2)
        return
    elseif not lib then
        return
    end

    if type(lib.Embed) == "function" then
        lib:Embed(addon)
        AceAddon.embeds[addon][libname] = true
    end
    return true
end

function AceAddon:EmbedLibraries(addon, ...)
    for i = 1, select("#", ...) do
        local libname = select(i, ...)
        self:EmbedLibrary(addon, libname)
    end
end

function AceAddon:InitializeAddon(addon)
    safecall(addon.OnInitialize, addon)

    local embeds = self.embeds[addon]
    for libname, v in pairs(embeds) do
        local lib = LibStub:GetLibrary(libname, true)
        if lib then
            safecall(lib.OnEmbedInitialize, lib, addon)
        end
    end

    for name, module in addon:IterateModules() do
        self:InitializeAddon(module)
    end
end

function AceAddon:EnableAddon(addon)
    if type(addon) == "string" then addon = AceAddon:GetAddon(addon) end
    if AceAddon.statuses[addon.name] or not addon.enabledState then return false end

    if not AceAddon.statuses[addon.name] then
        AceAddon.statuses[addon.name] = true
    end

    safecall(addon.OnEnable, addon)

    local embeds = self.embeds[addon]
    for libname, v in pairs(embeds) do
        local lib = LibStub:GetLibrary(libname, true)
        if lib then
            safecall(lib.OnEmbedEnable, lib, addon)
        end
    end

    for name, module in addon:IterateModules() do
        self:EnableAddon(module)
    end

    return true
end

function AceAddon:DisableAddon(addon)
    if type(addon) == "string" then addon = AceAddon:GetAddon(addon) end
    if not AceAddon.statuses[addon.name] then return false end

    safecall(addon.OnDisable, addon)

    local embeds = self.embeds[addon]
    for libname, v in pairs(embeds) do
        local lib = LibStub:GetLibrary(libname, true)
        if lib then
            safecall(lib.OnEmbedDisable, lib, addon)
        end
    end

    for name, module in addon:IterateModules() do
        self:DisableAddon(module)
    end

    AceAddon.statuses[addon.name] = false

    return true
end

function AceAddon:IterateAddons() return pairs(self.addons) end
function AceAddon:IterateAddonStatus() return pairs(self.statuses) end

local function onEvent(this, event, arg1)
    if event == "ADDON_LOADED" then
        for i = #AceAddon.initializequeue, 1, -1 do
            local addon = AceAddon.initializequeue[i]
            if IsAddOnLoaded(addon.name) or IsAddOnLoaded("!" .. addon.name) then
                AceAddon:InitializeAddon(addon)
                tremove(AceAddon.initializequeue, i)
                tinsert(AceAddon.enablequeue, addon)
            end
        end

        if IsLoggedIn() then
            for i = #AceAddon.enablequeue, 1, -1 do
                local addon = AceAddon.enablequeue[i]
                AceAddon:EnableAddon(addon)
                tremove(AceAddon.enablequeue, i)
            end
        end
    elseif event == "PLAYER_LOGIN" then
        for i = #AceAddon.initializequeue, 1, -1 do
            local addon = AceAddon.initializequeue[i]
            AceAddon:InitializeAddon(addon)
            tremove(AceAddon.initializequeue, i)
            tinsert(AceAddon.enablequeue, addon)
        end

        for i = #AceAddon.enablequeue, 1, -1 do
            local addon = AceAddon.enablequeue[i]
            AceAddon:EnableAddon(addon)
            tremove(AceAddon.enablequeue, i)
        end
    end
end

AceAddon.frame:RegisterEvent("ADDON_LOADED")
AceAddon.frame:RegisterEvent("PLAYER_LOGIN")
AceAddon.frame:SetScript("OnEvent", onEvent)
