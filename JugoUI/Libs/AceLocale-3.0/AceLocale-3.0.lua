--[[ AceLocale-3.0 - A library for handling localization
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceLocale-3.0", 6
local AceLocale = LibStub:NewLibrary(MAJOR, MINOR)
if not AceLocale then return end

local gameLocale = GetLocale()
if gameLocale == "enGB" then
    gameLocale = "enUS"
end

AceLocale.apps = AceLocale.apps or {}
AceLocale.appnames = AceLocale.appnames or {}

local readmeta = {
    __index = function(self, key)
        rawset(self, key, key)
        return key
    end
}

local writemeta = {
    __newindex = function(self, key, value)
        rawset(self, key, value == true and key or value)
    end,
    __index = readmeta.__index
}

function AceLocale:NewLocale(application, locale, isDefault, silent)
    if type(application) ~= "string" then
        error("Usage: AceLocale:NewLocale(application, locale[, isDefault[, silent]]): 'application' - string expected", 2)
    end
    if type(locale) ~= "string" then
        error("Usage: AceLocale:NewLocale(application, locale[, isDefault[, silent]]): 'locale' - string expected", 2)
    end

    local app = AceLocale.apps[application]

    if isDefault then
        if app and app.defaultLocale then
            app.defaultLocale = app.defaultLocale or {}
            return setmetatable(app.defaultLocale, writemeta)
        end

        app = {defaultLocale = {}}
        AceLocale.apps[application] = app
        AceLocale.appnames[#AceLocale.appnames + 1] = application
        return setmetatable(app.defaultLocale, writemeta)
    end

    if locale == gameLocale then
        if not app then
            app = {defaultLocale = {}}
            AceLocale.apps[application] = app
            AceLocale.appnames[#AceLocale.appnames + 1] = application
        end
        app.currentLocale = app.currentLocale or {}
        return setmetatable(app.currentLocale, writemeta)
    end

    return nil
end

function AceLocale:GetLocale(application, silent)
    if type(application) ~= "string" then
        error("Usage: AceLocale:GetLocale(application[, silent]): 'application' - string expected", 2)
    end

    local app = AceLocale.apps[application]

    if not app then
        if silent then
            return nil
        end
        error(("AceLocale:GetLocale(application[, silent]): No locale data registered for '%s'"):format(tostring(application)), 2)
    end

    if app.currentLocale then
        setmetatable(app.currentLocale, readmeta)
        return app.currentLocale
    elseif app.defaultLocale then
        setmetatable(app.defaultLocale, readmeta)
        return app.defaultLocale
    end

    if silent then
        return nil
    end

    error(("AceLocale:GetLocale(application[, silent]): No locale data registered for '%s'"):format(tostring(application)), 2)
end
