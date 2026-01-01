--[[ AceConfigRegistry-3.0 - Central registry for AceConfig options tables
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceConfigRegistry-3.0", 21
local AceConfigRegistry = LibStub:NewLibrary(MAJOR, MINOR)
if not AceConfigRegistry then return end

local CallbackHandler = LibStub("CallbackHandler-1.0")

AceConfigRegistry.tables = AceConfigRegistry.tables or {}

if not AceConfigRegistry.callbacks then
    AceConfigRegistry.callbacks = CallbackHandler:New(AceConfigRegistry)
end

local type = type
local pairs = pairs
local tostring = tostring
local error = error
local select = select

local tables = AceConfigRegistry.tables

local function validateOpts(opts, name)
    return true
end

function AceConfigRegistry:RegisterOptionsTable(appName, options, skipValidation)
    if type(appName) ~= "string" then
        error("Usage: AceConfigRegistry:RegisterOptionsTable(appName, options): 'appName' - string expected", 2)
    end
    if type(options) ~= "table" and type(options) ~= "function" then
        error("Usage: AceConfigRegistry:RegisterOptionsTable(appName, options): 'options' - table or function expected", 2)
    end

    if type(options) == "table" then
        if not skipValidation then
            validateOpts(options, appName)
        end
        tables[appName] = options
    else
        tables[appName] = options
    end

    self.callbacks:Fire("ConfigTableChange", appName)
end

function AceConfigRegistry:GetOptionsTable(appName, uiType, uiName)
    if type(appName) ~= "string" then
        error("Usage: AceConfigRegistry:GetOptionsTable(appName): 'appName' - string expected", 2)
    end

    local options = tables[appName]

    if not options then
        return nil
    end

    if type(options) == "function" then
        return options(uiType, uiName)
    end

    return options
end

function AceConfigRegistry:IterateOptionsTables()
    return pairs(tables)
end

function AceConfigRegistry:NotifyChange(appName)
    if type(appName) ~= "string" then
        error("Usage: AceConfigRegistry:NotifyChange(appName): 'appName' - string expected", 2)
    end
    self.callbacks:Fire("ConfigTableChange", appName)
end
