--[[ AceSerializer-3.0 - A library for serializing and deserializing Lua tables
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceSerializer-3.0", 5
local AceSerializer = LibStub:NewLibrary(MAJOR, MINOR)
if not AceSerializer then return end

AceSerializer.embeds = AceSerializer.embeds or {}

local type = type
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local tconcat = table.concat
local gsub = string.gsub
local gmatch = string.gmatch
local format = string.format
local strbyte = string.byte
local strchar = string.char
local strsub = string.sub

local inf = math.huge

local serNaN
local serInf
local serNegInf

local function SerializeValue(v, res, nres)
    local t = type(v)

    if t == "string" then
        res[nres+1] = "^S"
        res[nres+2] = gsub(v, "[%c~\\]", function(c)
            local b = strbyte(c)
            if b == 94 then return "~^"
            elseif b == 126 then return "~~"
            elseif b == 92 then return "~\\"
            else return format("~%03d", b)
            end
        end)
        nres = nres + 2
    elseif t == "number" then
        local str = tostring(v)
        if tonumber(str) == v or str == inf or str == -inf or str ~= str then
            res[nres+1] = "^N"
            res[nres+2] = str
        else
            res[nres+1] = "^F"
            res[nres+2] = format("%.17g", v)
        end
        nres = nres + 2
    elseif t == "table" then
        res[nres+1] = "^T"
        nres = nres + 1
        for k, val in pairs(v) do
            nres = SerializeValue(k, res, nres)
            nres = SerializeValue(val, res, nres)
        end
        res[nres+1] = "^t"
        nres = nres + 1
    elseif t == "boolean" then
        res[nres+1] = v and "^B" or "^b"
        nres = nres + 1
    elseif t == "nil" then
        res[nres+1] = "^Z"
        nres = nres + 1
    else
        error("Cannot serialize a value of type '" .. t .. "'")
    end

    return nres
end

local function DeserializeValue(iter)
    local t = iter()
    if not t then
        return nil, "Premature end of serialized data"
    end

    if t == "^^" then
        return DeserializeValue(iter)
    elseif t == "^S" then
        local str = iter()
        if not str then
            return nil, "Premature end of serialized string"
        end
        str = gsub(str, "~(.)", function(c)
            if c == "^" then return "^"
            elseif c == "~" then return "~"
            elseif c == "\\" then return "\\"
            else
                local b = tonumber(c, 10)
                if b then
                    return strchar(b)
                end
                return ""
            end
        end)
        str = gsub(str, "~(%d%d%d)", function(d)
            return strchar(tonumber(d, 10))
        end)
        return str
    elseif t == "^N" then
        local num = iter()
        if not num then
            return nil, "Premature end of serialized number"
        end
        return tonumber(num)
    elseif t == "^F" then
        local num = iter()
        if not num then
            return nil, "Premature end of serialized float"
        end
        return tonumber(num)
    elseif t == "^B" then
        return true
    elseif t == "^b" then
        return false
    elseif t == "^Z" then
        return nil
    elseif t == "^T" then
        local tbl = {}
        local k, v, err

        while true do
            k, err = DeserializeValue(iter)
            if err then return nil, err end
            if k == nil then break end

            v, err = DeserializeValue(iter)
            if err then return nil, err end

            tbl[k] = v
        end

        return tbl
    elseif t == "^t" then
        return nil
    else
        return nil, "Unknown serialized type: " .. tostring(t)
    end
end

function AceSerializer:Serialize(...)
    local nres = 0
    local res = {}

    for i = 1, select("#", ...) do
        local v = select(i, ...)
        nres = SerializeValue(v, res, nres)
    end

    return "^1" .. tconcat(res) .. "^^"
end

function AceSerializer:Deserialize(str)
    if type(str) ~= "string" then
        error("Usage: AceSerializer:Deserialize(str): 'str' - string expected", 2)
    end

    if strsub(str, 1, 2) ~= "^1" then
        return false, "Invalid serialized data (no version marker)"
    end

    local iter = gmatch(str, "(^.)([^^]*)")
    iter()

    local res = {}
    local nres = 0
    local val, err

    while true do
        val, err = DeserializeValue(iter)
        if err then
            return false, err
        end
        if val == nil then
            break
        end
        nres = nres + 1
        res[nres] = val
    end

    return true, unpack(res, 1, nres)
end

local mixins = {
    "Serialize", "Deserialize"
}

function AceSerializer:Embed(target)
    for _, v in pairs(mixins) do
        target[v] = self[v]
    end
    self.embeds[target] = true
    return target
end

for addon in pairs(AceSerializer.embeds) do
    AceSerializer:Embed(addon)
end
