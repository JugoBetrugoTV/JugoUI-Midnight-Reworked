--[[ LibDeflate - A library for data compression/decompression
     Simplified implementation for JugoUI ]]

local MAJOR, MINOR = "LibDeflate", 10
local LibDeflate = LibStub:NewLibrary(MAJOR, MINOR)
if not LibDeflate then return end

local type = type
local pairs = pairs
local string_byte = string.byte
local string_char = string.char
local string_sub = string.sub
local string_len = string.len
local string_gsub = string.gsub
local table_concat = table.concat
local math_floor = math.floor
local bit = bit

local function CreateDictionary()
    local dict = {}
    for i = 0, 255 do
        dict[string_char(i)] = i
    end
    return dict
end

local function CreateReverseDictionary()
    local dict = {}
    for i = 0, 255 do
        dict[i] = string_char(i)
    end
    return dict
end

function LibDeflate:CompressDeflate(data)
    if type(data) ~= "string" then
        error("Usage: LibDeflate:CompressDeflate(data): 'data' - string expected", 2)
    end

    local dict = CreateDictionary()
    local dictSize = 256
    local result = {}
    local w = ""

    for i = 1, #data do
        local c = string_sub(data, i, i)
        local wc = w .. c
        if dict[wc] then
            w = wc
        else
            result[#result + 1] = dict[w]
            if dictSize < 65536 then
                dict[wc] = dictSize
                dictSize = dictSize + 1
            end
            w = c
        end
    end

    if w ~= "" then
        result[#result + 1] = dict[w]
    end

    local output = {}
    for i = 1, #result do
        local code = result[i]
        output[#output + 1] = string_char(math_floor(code / 256))
        output[#output + 1] = string_char(code % 256)
    end

    return table_concat(output)
end

function LibDeflate:DecompressDeflate(data)
    if type(data) ~= "string" then
        error("Usage: LibDeflate:DecompressDeflate(data): 'data' - string expected", 2)
    end

    if #data == 0 then
        return ""
    end

    if #data % 2 ~= 0 then
        return nil, "Invalid compressed data length"
    end

    local codes = {}
    for i = 1, #data, 2 do
        local high = string_byte(data, i)
        local low = string_byte(data, i + 1)
        codes[#codes + 1] = high * 256 + low
    end

    if #codes == 0 then
        return ""
    end

    local dict = CreateReverseDictionary()
    local dictSize = 256
    local result = {}

    local w = dict[codes[1]]
    if not w then
        return nil, "Invalid first code"
    end
    result[1] = w

    for i = 2, #codes do
        local code = codes[i]
        local entry

        if dict[code] then
            entry = dict[code]
        elseif code == dictSize then
            entry = w .. string_sub(w, 1, 1)
        else
            return nil, "Invalid code: " .. code
        end

        result[#result + 1] = entry

        if dictSize < 65536 then
            dict[dictSize] = w .. string_sub(entry, 1, 1)
            dictSize = dictSize + 1
        end

        w = entry
    end

    return table_concat(result)
end

local base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64Encode(data)
    return ((data:gsub('.', function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
        return base64Chars:sub(c + 1, c + 1)
    end) .. ({'', '==', '='})[#data % 3 + 1])
end

local function base64Decode(data)
    data = string_gsub(data, '[^' .. base64Chars .. '=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (base64Chars:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
        return string_char(c)
    end))
end

function LibDeflate:EncodeForWoWAddonChannel(data)
    if type(data) ~= "string" then
        error("Usage: LibDeflate:EncodeForWoWAddonChannel(data): 'data' - string expected", 2)
    end
    return base64Encode(data)
end

function LibDeflate:DecodeForWoWAddonChannel(data)
    if type(data) ~= "string" then
        error("Usage: LibDeflate:DecodeForWoWAddonChannel(data): 'data' - string expected", 2)
    end
    return base64Decode(data)
end

function LibDeflate:EncodeForPrint(data)
    return base64Encode(data)
end

function LibDeflate:DecodeForPrint(data)
    return base64Decode(data)
end

function LibDeflate:CompressZlib(data)
    return self:CompressDeflate(data)
end

function LibDeflate:DecompressZlib(data)
    return self:DecompressDeflate(data)
end
