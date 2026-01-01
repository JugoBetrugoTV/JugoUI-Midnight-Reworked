--[[ LibDataBroker-1.1 - A library for creating data sources
     https://www.wowace.com/projects/libdatabroker-1-1 ]]

local MAJOR, MINOR = "LibDataBroker-1.1", 4
local LibDataBroker = LibStub:NewLibrary(MAJOR, MINOR)
if not LibDataBroker then return end

local pairs = pairs
local type = type
local next = next
local setmetatable = setmetatable
local rawset = rawset

LibDataBroker.callbacks = LibDataBroker.callbacks or LibStub("CallbackHandler-1.0"):New(LibDataBroker)
LibDataBroker.attributestorage = LibDataBroker.attributestorage or {}
LibDataBroker.namestorage = LibDataBroker.namestorage or {}
LibDataBroker.proxystorage = LibDataBroker.proxystorage or {}

local attributestorage = LibDataBroker.attributestorage
local namestorage = LibDataBroker.namestorage
local proxystorage = LibDataBroker.proxystorage
local callbacks = LibDataBroker.callbacks

local domt = {
    __metatable = "access denied",
    __index = function(self, key) return attributestorage[self] and attributestorage[self][key] end,
}

function domt:__newindex(key, value)
    if not attributestorage[self] then attributestorage[self] = {} end
    if attributestorage[self][key] == value then return end
    attributestorage[self][key] = value
    local name = namestorage[self]
    if name then
        callbacks:Fire("LibDataBroker_AttributeChanged", name, key, value, self)
        callbacks:Fire("LibDataBroker_AttributeChanged_" .. name, name, key, value, self)
        callbacks:Fire("LibDataBroker_AttributeChanged_" .. name .. "_" .. key, name, key, value, self)
        callbacks:Fire("LibDataBroker_AttributeChanged__" .. key, name, key, value, self)
    end
end

function LibDataBroker:NewDataObject(name, dataobj)
    if proxystorage[name] then return end

    if dataobj then
        for k, v in pairs(dataobj) do
            if type(v) == "table" then
                dataobj[k] = nil
            end
        end
    end

    local dataobj_mt = setmetatable(dataobj or {}, domt)
    proxystorage[name] = dataobj_mt
    namestorage[dataobj_mt] = name
    attributestorage[dataobj_mt] = {}

    callbacks:Fire("LibDataBroker_DataObjectCreated", name, dataobj_mt)
    return dataobj_mt
end

function LibDataBroker:DataObjectIterator()
    return pairs(proxystorage)
end

function LibDataBroker:GetDataObjectByName(name)
    return proxystorage[name]
end

function LibDataBroker:GetNameByDataObject(dataobj)
    return namestorage[dataobj]
end
