--[[ AceDB-3.0 - A library to handle profile based saved variables
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceDB-3.0", 27
local AceDB = LibStub:NewLibrary(MAJOR, MINOR)
if not AceDB then return end

local type = type
local pairs, next = pairs, next
local rawget, rawset = rawget, rawset
local setmetatable = setmetatable

AceDB.db_registry = AceDB.db_registry or {}
AceDB.frame = AceDB.frame or CreateFrame("Frame")

local CallbackHandler = LibStub("CallbackHandler-1.0", true)
local CallbackDummy = { Fire = function() end }

local DBObjectLib = {}

local function copyTable(src, dest)
    if type(dest) ~= "table" then dest = {} end
    if type(src) == "table" then
        for k, v in pairs(src) do
            if type(v) == "table" then
                v = copyTable(v, dest[k])
            end
            dest[k] = v
        end
    end
    return dest
end

local function copyDefaults(dest, src)
    for k, v in pairs(src) do
        if k == "*" or k == "**" then
            if type(v) == "table" then
                setmetatable(dest, {
                    __index = function(t, key)
                        if key == nil then return nil end
                        local value = rawget(t, key)
                        if value == nil then
                            value = copyTable(v)
                            rawset(t, key, value)
                        end
                        return value
                    end,
                })
            else
                setmetatable(dest, {
                    __index = function(t, key)
                        if key == nil then return nil end
                        local value = rawget(t, key)
                        if value == nil then
                            value = v
                            rawset(t, key, value)
                        end
                        return value
                    end,
                })
            end
        elseif type(v) == "table" then
            if type(dest[k]) ~= "table" then dest[k] = {} end
            copyDefaults(dest[k], v)
            if src['**'] then
                copyDefaults(dest[k], src['**'])
            end
        else
            if dest[k] == nil then
                dest[k] = v
            end
        end
    end
end

local function removeDefaults(db, defaults, blocker)
    setmetatable(db, nil)
    for k, v in pairs(defaults) do
        if k == "*" or k == "**" then
            -- skip
        elseif k == "profiles" then
            -- skip
        elseif type(v) == "table" and type(db[k]) == "table" then
            removeDefaults(db[k], v, blocker)
            if next(db[k]) == nil then
                db[k] = nil
            end
        else
            if db[k] == defaults[k] and (not blocker or blocker[k] == nil) then
                db[k] = nil
            end
        end
    end
end

local function initSection(db, section, svstore, key, defaults)
    local sv = rawget(db, "sv")

    local tableCreated
    if not sv[svstore] then sv[svstore] = {} end
    if not sv[svstore][key] then
        sv[svstore][key] = {}
        tableCreated = true
    end

    local tbl = sv[svstore][key]

    if defaults then
        copyDefaults(tbl, defaults)
    end
    rawset(db, section, tbl)

    return tableCreated, tbl
end

local dbmt = {
    __index = function(t, section)
        local keys = rawget(t, "keys")
        local key = keys[section]
        if key then
            local defaultTbl = rawget(t, "defaults")
            local defaults = defaultTbl and defaultTbl[section]

            if section == "profile" then
                local new = initSection(t, section, "profiles", key, defaults)
            elseif section == "profiles" then
                local sv = rawget(t, "sv")
                if not sv.profiles then sv.profiles = {} end
                rawset(t, "profiles", sv.profiles)
            elseif section == "global" then
                local sv = rawget(t, "sv")
                if not sv.global then sv.global = {} end
                if defaults then
                    copyDefaults(sv.global, defaults)
                end
                rawset(t, section, sv.global)
            elseif section == "char" then
                initSection(t, section, "char", key, defaults)
            elseif section == "realm" then
                initSection(t, section, "realm", key, defaults)
            elseif section == "class" then
                initSection(t, section, "class", key, defaults)
            elseif section == "race" then
                initSection(t, section, "race", key, defaults)
            elseif section == "faction" then
                initSection(t, section, "faction", key, defaults)
            elseif section == "factionrealm" then
                initSection(t, section, "factionrealm", key, defaults)
            elseif section == "factionrealmregion" then
                initSection(t, section, "factionrealmregion", key, defaults)
            end
        end

        return rawget(t, section)
    end
}

local function validateDefaults(defaults, keyTbl, offset)
    if not defaults then return end
    offset = offset or 0
    for k in pairs(defaults) do
        if not keyTbl[k] or k == "profiles" then
            error(("Usage: AceDBObject:RegisterDefaults(defaults): '%s' is not a valid datatype."):format(k), 3 + offset)
        end
    end
end

local preserve_keys = {
    ["callbacks"] = true,
    ["RegisterCallback"] = true,
    ["UnregisterCallback"] = true,
    ["UnregisterAllCallbacks"] = true,
    ["children"] = true,
}

local realmKey = GetRealmName()
local charKey = UnitName("player") .. " - " .. realmKey
local _, classKey = UnitClass("player")
local _, raceKey = UnitRace("player")
local factionKey = UnitFactionGroup("player")
local factionrealmKey = factionKey .. " - " .. realmKey
local factionrealmregionKey = factionrealmKey .. " - " .. GetCurrentRegion()

local keyTbl = {
    ["char"] = charKey,
    ["realm"] = realmKey,
    ["class"] = classKey,
    ["race"] = raceKey,
    ["faction"] = factionKey,
    ["factionrealm"] = factionrealmKey,
    ["factionrealmregion"] = factionrealmregionKey,
    ["profile"] = true,
    ["global"] = true,
    ["profiles"] = true,
}

function DBObjectLib:RegisterDefaults(defaults)
    if defaults and type(defaults) ~= "table" then
        error("Usage: AceDBObject:RegisterDefaults(defaults): 'defaults' - table or nil expected.", 2)
    end

    validateDefaults(defaults, keyTbl)

    local sv = rawget(self, "sv")
    local parent = rawget(self, "parent")

    if defaults then
        for section, key in pairs(keyTbl) do
            if defaults[section] then
                if section == "profile" then
                    if rawget(sv, "profiles") then
                        for profile, profileTbl in pairs(sv.profiles) do
                            copyDefaults(profileTbl, defaults.profile)
                        end
                    end
                elseif section == "global" then
                    if rawget(sv, "global") then
                        copyDefaults(sv.global, defaults.global)
                    end
                else
                    if type(key) == "string" then
                        if rawget(sv, section) and rawget(sv[section], key) then
                            copyDefaults(sv[section][key], defaults[section])
                        end
                    end
                end
            end
        end
    end

    rawset(self, "defaults", defaults)
end

function DBObjectLib:SetProfile(name)
    if type(name) ~= "string" then
        error("Usage: AceDBObject:SetProfile(name): 'name' - string expected.", 2)
    end

    local oldProfile = self.keys.profile
    local defaults = rawget(self, "defaults")

    if defaults then
        local sv = rawget(self, "sv")
        removeDefaults(sv.profiles[oldProfile], defaults.profile)
    end

    self.keys["profile"] = name
    self:FireCallbacks("OnProfileChanged", self, name)
end

function DBObjectLib:GetProfiles(tbl)
    if tbl and type(tbl) ~= "table" then
        error("Usage: AceDBObject:GetProfiles(tbl): 'tbl' - table or nil expected.", 2)
    end

    tbl = tbl or {}
    local curProfile = self.keys.profile

    local sv = rawget(self, "sv")
    if sv.profiles then
        for profileKey in pairs(sv.profiles) do
            tbl[#tbl+1] = profileKey
        end
    end

    if rawget(sv, "profiles") then
        for profileKey in pairs(sv.profiles) do
            if tbl[profileKey] == nil then
                tbl[#tbl+1] = profileKey
            end
        end
    end

    return tbl, curProfile
end

function DBObjectLib:GetCurrentProfile()
    return self.keys.profile
end

function DBObjectLib:DeleteProfile(name, silent)
    if type(name) ~= "string" then
        error("Usage: AceDBObject:DeleteProfile(name): 'name' - string expected.", 2)
    end

    if self.keys.profile == name then
        error("Cannot delete the active profile in an AceDB database.", 2)
    end

    local sv = rawget(self, "sv")
    if sv.profiles then
        sv.profiles[name] = nil
    end

    self:FireCallbacks("OnProfileDeleted", self, name)
end

function DBObjectLib:CopyProfile(name, silent)
    if type(name) ~= "string" then
        error("Usage: AceDBObject:CopyProfile(name): 'name' - string expected.", 2)
    end

    local sv = rawget(self, "sv")
    if not (sv.profiles and sv.profiles[name]) then
        error("Cannot copy profile '" .. name .. "' - it doesn't exist.", 2)
    end

    local profile = self.profile
    for k, v in pairs(profile) do
        profile[k] = nil
    end

    copyTable(sv.profiles[name], profile)
    self:FireCallbacks("OnProfileCopied", self, name)
end

function DBObjectLib:ResetProfile(noChildren, noCallbacks)
    local profile = self.profile
    for k, v in pairs(profile) do
        profile[k] = nil
    end

    local defaults = rawget(self, "defaults")
    if defaults and defaults.profile then
        copyDefaults(profile, defaults.profile)
    end

    if not noCallbacks then
        self:FireCallbacks("OnProfileReset", self)
    end
end

function DBObjectLib:ResetDB(defaultProfile)
    local sv = rawget(self, "sv")
    for k, v in pairs(sv) do
        sv[k] = nil
    end

    local parent = rawget(self, "parent")

    initdb(sv, rawget(self, "defaults"), defaultProfile, rawget(self, "keys"), parent)

    self:FireCallbacks("OnDatabaseReset", self)
    self:FireCallbacks("OnProfileChanged", self, self.keys["profile"])
end

function DBObjectLib:RegisterNamespace(name, defaults)
    if type(name) ~= "string" then
        error("Usage: AceDBObject:RegisterNamespace(name, defaults): 'name' - string expected.", 2)
    end
    if defaults and type(defaults) ~= "table" then
        error("Usage: AceDBObject:RegisterNamespace(name, defaults): 'defaults' - table or nil expected.", 2)
    end

    local sv = rawget(self, "sv")
    if not sv.namespaces then sv.namespaces = {} end
    if not sv.namespaces[name] then
        sv.namespaces[name] = {}
    end

    local namespace = sv.namespaces[name]

    local child = {}
    child.sv = namespace
    child.defaults = defaults
    child.keys = rawget(self, "keys")
    child.parent = self
    child.callbacks = CallbackDummy

    for funcName, func in pairs(DBObjectLib) do
        child[funcName] = func
    end

    if defaults then
        child:RegisterDefaults(defaults)
    end

    setmetatable(child, dbmt)

    if not self.children then self.children = {} end
    self.children[name] = child
    return child
end

function DBObjectLib:GetNamespace(name, silent)
    if type(name) ~= "string" then
        error("Usage: AceDBObject:GetNamespace(name): 'name' - string expected.", 2)
    end

    if not self.children or not self.children[name] then
        if not silent then
            error("Usage: AceDBObject:GetNamespace(name): namespace '" .. name .. "' does not exist.", 2)
        end
        return nil
    end

    return self.children[name]
end

function DBObjectLib:FireCallbacks(name, ...)
    if self.callbacks then
        self.callbacks:Fire(name, ...)
    end
end

local function initdb(sv, defaults, defaultProfile, oldKeys, parent)
    local profileKey

    if oldKeys and oldKeys.profile then
        profileKey = oldKeys.profile
    else
        profileKey = defaultProfile or UnitName("player") .. " - " .. GetRealmName()
    end

    local keys = {
        ["char"] = charKey,
        ["realm"] = realmKey,
        ["class"] = classKey,
        ["race"] = raceKey,
        ["faction"] = factionKey,
        ["factionrealm"] = factionrealmKey,
        ["factionrealmregion"] = factionrealmregionKey,
        ["profile"] = profileKey,
        ["global"] = true,
        ["profiles"] = true,
    }

    return keys
end

function AceDB:New(tbl, defaults, defaultProfile)
    if type(tbl) == "string" then
        local name = tbl
        tbl = _G[name]
        if not tbl then
            tbl = {}
            _G[name] = tbl
        end
    end

    if type(tbl) ~= "table" then
        error("Usage: AceDB:New(tbl, defaults, defaultProfile): 'tbl' - table or string expected.", 2)
    end

    if defaults and type(defaults) ~= "table" then
        error("Usage: AceDB:New(tbl, defaults, defaultProfile): 'defaults' - table expected.", 2)
    end

    if defaultProfile and type(defaultProfile) ~= "string" and defaultProfile ~= true then
        error("Usage: AceDB:New(tbl, defaults, defaultProfile): 'defaultProfile' - string or true expected.", 2)
    end

    local keys = initdb(tbl, defaults, defaultProfile)

    local db = {}
    db.sv = tbl
    db.keys = keys
    db.defaults = defaults
    db.callbacks = CallbackHandler and CallbackHandler:New(db) or CallbackDummy

    for funcName, func in pairs(DBObjectLib) do
        db[funcName] = func
    end

    if defaults then
        db:RegisterDefaults(defaults)
    end

    setmetatable(db, dbmt)

    AceDB.db_registry[db] = true
    return db
end

function AceDB.OnEmbedEnable(AceDB, self)
end

function AceDB.OnEmbedDisable(AceDB, self)
end

function AceDB.OnEmbedInitialize(AceDB, self)
end
