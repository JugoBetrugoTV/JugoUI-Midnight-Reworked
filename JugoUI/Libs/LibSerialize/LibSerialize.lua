--[[ LibSerialize - A library for serializing Lua tables
     Simplified implementation for JugoUI ]]

local MAJOR, MINOR = "LibSerialize", 1
local LibSerialize = LibStub:NewLibrary(MAJOR, MINOR)
if not LibSerialize then return end

local type = type
local pairs = pairs
local tostring = tostring
local tonumber = tonumber
local string_format = string.format
local string_gsub = string.gsub
local string_byte = string.byte
local string_char = string.char
local string_sub = string.sub
local table_concat = table.concat
local math_huge = math.huge

local function serializeValue(val, result)
    local t = type(val)

    if t == "nil" then
        result[#result + 1] = "N"
    elseif t == "boolean" then
        result[#result + 1] = val and "T" or "F"
    elseif t == "number" then
        if val ~= val then
            result[#result + 1] = "n"
        elseif val == math_huge then
            result[#result + 1] = "I"
        elseif val == -math_huge then
            result[#result + 1] = "i"
        elseif val % 1 == 0 and val >= -2147483648 and val <= 2147483647 then
            result[#result + 1] = "D" .. val .. ";"
        else
            result[#result + 1] = "d" .. string_format("%.17g", val) .. ";"
        end
    elseif t == "string" then
        local escaped = string_gsub(val, "([\\~])", "\\%1")
        result[#result + 1] = "S" .. #escaped .. "~" .. escaped
    elseif t == "table" then
        result[#result + 1] = "{"
        local isArray = true
        local arrayLen = 0

        for k, v in pairs(val) do
            if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
                isArray = false
                break
            end
            if k > arrayLen then arrayLen = k end
        end

        if isArray and arrayLen > 0 then
            for i = 1, arrayLen do
                serializeValue(val[i], result)
            end
        else
            for k, v in pairs(val) do
                serializeValue(k, result)
                serializeValue(v, result)
            end
        end

        result[#result + 1] = "}"
    else
        error("Cannot serialize value of type '" .. t .. "'")
    end
end

function LibSerialize:Serialize(...)
    local result = {"^"}
    local n = select("#", ...)

    for i = 1, n do
        serializeValue(select(i, ...), result)
    end

    return table_concat(result)
end

local function parseString(data, pos)
    local lenEnd = string.find(data, "~", pos)
    if not lenEnd then
        error("Invalid serialized string: missing length delimiter")
    end

    local len = tonumber(string_sub(data, pos, lenEnd - 1))
    if not len then
        error("Invalid serialized string: bad length")
    end

    local strStart = lenEnd + 1
    local strEnd = strStart + len - 1
    local str = string_sub(data, strStart, strEnd)

    str = string_gsub(str, "\\(.)", "%1")

    return str, strEnd + 1
end

local function parseNumber(data, pos)
    local numEnd = string.find(data, ";", pos)
    if not numEnd then
        error("Invalid serialized number: missing delimiter")
    end

    local num = tonumber(string_sub(data, pos, numEnd - 1))
    return num, numEnd + 1
end

local function deserializeValue(data, pos)
    local marker = string_sub(data, pos, pos)

    if marker == "N" then
        return nil, pos + 1
    elseif marker == "T" then
        return true, pos + 1
    elseif marker == "F" then
        return false, pos + 1
    elseif marker == "n" then
        return 0/0, pos + 1
    elseif marker == "I" then
        return math_huge, pos + 1
    elseif marker == "i" then
        return -math_huge, pos + 1
    elseif marker == "D" or marker == "d" then
        return parseNumber(data, pos + 1)
    elseif marker == "S" then
        return parseString(data, pos + 1)
    elseif marker == "{" then
        local tbl = {}
        pos = pos + 1

        while string_sub(data, pos, pos) ~= "}" do
            local key, value
            key, pos = deserializeValue(data, pos)
            value, pos = deserializeValue(data, pos)
            if key ~= nil then
                tbl[key] = value
            end
        end

        return tbl, pos + 1
    else
        error("Invalid serialized data at position " .. pos .. ": " .. marker)
    end
end

function LibSerialize:Deserialize(data)
    if type(data) ~= "string" then
        error("Usage: LibSerialize:Deserialize(data): 'data' - string expected", 2)
    end

    if string_sub(data, 1, 1) ~= "^" then
        return false, "Invalid serialized data: missing header"
    end

    local results = {}
    local pos = 2

    local success, err = pcall(function()
        while pos <= #data do
            local value
            value, pos = deserializeValue(data, pos)
            results[#results + 1] = value
        end
    end)

    if not success then
        return false, err
    end

    return true, unpack(results)
end

function LibSerialize:SerializeEx(options, ...)
    return self:Serialize(...)
end

function LibSerialize:DeserializeEx(data)
    return self:Deserialize(data)
end
