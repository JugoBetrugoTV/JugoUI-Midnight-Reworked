--[[
    JugoUI - Modules.lua
    Module registration and management system
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

-- Module storage
E.modules = {}
E.moduleOrder = {}
E.enabledModules = {}

--[[
    Module Creation
    Creates a new module with the given name
]]
function E:NewModule(name, ...)
    if type(name) ~= "string" then
        E:Error("NewModule: name must be a string, got", type(name))
        return nil
    end

    if E.modules[name] then
        E:Debug("Module already exists:", name)
        return E.modules[name]
    end

    -- Create module as a simple table with mixin
    local module = {}
    module.name = name
    module.enabled = false
    module.initialized = false
    module.db = nil

    -- Apply module mixin for common functionality
    E:ApplyModuleMixin(module)

    -- Store reference
    E.modules[name] = module
    table.insert(E.moduleOrder, name)

    E:Debug("Module created:", name)
    return module
end

--[[
    Get Module
    Returns an existing module by name
]]
function E:GetModule(name, silent)
    local module = E.modules[name]
    if not module and not silent then
        E:Error("Module not found:", name)
    end
    return module
end

--[[
    Module Initialization
]]
function E:InitializeModules()
    for _, name in ipairs(E.moduleOrder) do
        local module = E.modules[name]
        if module and not module.initialized then
            E:InitializeModule(module)
        end
    end
end

function E:InitializeModule(module)
    if module.initialized then return end

    -- Get module database
    if E.db[module.name:lower()] then
        module.db = E.db[module.name:lower()]
    end

    -- Call OnInitialize if exists
    if module.OnInitialize then
        local success, err = pcall(module.OnInitialize, module)
        if not success then
            E:Error("Error initializing module", module.name, ":", err)
            return
        end
    end

    module.initialized = true

    -- Enable if configured
    if module.db and module.db.enabled ~= false then
        E:EnableModule(module.name)
    elseif not module.db then
        -- Module has no db entry, enable by default
        E:EnableModule(module.name)
    end
end

--[[
    Enable/Disable Modules
]]
function E:EnableModule(name)
    local module = E.modules[name]
    if not module then
        E:Error("Cannot enable unknown module:", name)
        return
    end

    if module.enabled then return end

    if module.OnEnable then
        local success, err = pcall(module.OnEnable, module)
        if not success then
            E:Error("Error enabling module", name, ":", err)
            return
        end
    end

    module.enabled = true
    E.enabledModules[name] = module

    E.callbacks:Fire("JugoUI_ModuleEnabled", name, module)
    E:Debug("Module enabled:", name)
end

function E:DisableModule(name)
    local module = E.modules[name]
    if not module then return end

    if not module.enabled then return end

    if module.OnDisable then
        local success, err = pcall(module.OnDisable, module)
        if not success then
            E:Error("Error disabling module", name, ":", err)
        end
    end

    module.enabled = false
    E.enabledModules[name] = nil

    E.callbacks:Fire("JugoUI_ModuleDisabled", name, module)
    E:Debug("Module disabled:", name)
end

function E:ToggleModule(name)
    local module = E.modules[name]
    if not module then return end

    if module.enabled then
        E:DisableModule(name)
    else
        E:EnableModule(name)
    end
end

--[[
    Module Status
]]
function E:IsModuleEnabled(name)
    local module = E.modules[name]
    return module and module.enabled
end

function E:PrintModuleStatus()
    E:Print("Module Status:")
    for _, name in ipairs(E.moduleOrder) do
        local module = E.modules[name]
        local status = module.enabled and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"
        print("  - " .. name .. ": " .. status)
    end
end

--[[
    Module Database Update
    Called when profile changes
]]
function E:UpdateModuleDatabases()
    for name, module in pairs(E.modules) do
        if E.db[name:lower()] then
            module.db = E.db[name:lower()]
        end

        if module.ProfileChanged then
            module:ProfileChanged()
        end
    end
end

--[[
    Module Options
    Returns options table for a module (for AceConfig)
]]
function E:GetModuleOptions(name)
    local module = E.modules[name]
    if module and module.GetOptions then
        return module:GetOptions()
    end
    return nil
end

--[[
    Module Iteration
]]
function E:IterateModules()
    return pairs(E.modules)
end

function E:IterateEnabledModules()
    return pairs(E.enabledModules)
end

--[[
    Module Dependencies
]]
function E:CheckModuleDependencies(name, dependencies)
    if not dependencies then return true end

    for _, dep in ipairs(dependencies) do
        if not E:IsModuleEnabled(dep) then
            E:Warning("Module", name, "requires", dep, "to be enabled")
            return false
        end
    end

    return true
end

--[[
    Base Module Mixin
    Provides common functionality for all modules
]]
E.ModuleMixin = {}

function E.ModuleMixin:GetDB()
    return self.db
end

function E.ModuleMixin:SetDB(db)
    self.db = db
end

function E.ModuleMixin:Print(...)
    E:Print("|cffaaaaaa[" .. self.name .. "]|r", ...)
end

function E.ModuleMixin:Debug(...)
    if E.debug then
        E:Debug("|cffaaaaaa[" .. self.name .. "]|r", ...)
    end
end

function E.ModuleMixin:RegisterEvent(event, handler)
    E:RegisterEvent(event, handler or event, self)
end

function E.ModuleMixin:UnregisterEvent(event)
    E:UnregisterEvent(event, self)
end

function E.ModuleMixin:RegisterCallback(event, handler)
    E.callbacks.RegisterCallback(self, event, handler)
end

function E.ModuleMixin:UnregisterCallback(event)
    E.callbacks.UnregisterCallback(self, event)
end

function E.ModuleMixin:ScheduleTimer(callback, delay, ...)
    return C_Timer.NewTimer(delay, function(...)
        callback(self, ...)
    end)
end

function E.ModuleMixin:ScheduleRepeatingTimer(callback, interval, ...)
    return C_Timer.NewTicker(interval, function(...)
        callback(self, ...)
    end)
end

function E.ModuleMixin:CancelTimer(timer)
    if timer then
        timer:Cancel()
    end
end

-- Apply mixin to module prototype
function E:ApplyModuleMixin(module)
    for k, v in pairs(E.ModuleMixin) do
        if not module[k] then
            module[k] = v
        end
    end
    return module
end
