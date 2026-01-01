--[[ AceConsole-3.0 - A library for registering and handling slash commands
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceConsole-3.0", 7
local AceConsole = LibStub:NewLibrary(MAJOR, MINOR)
if not AceConsole then return end

AceConsole.embeds = AceConsole.embeds or {}
AceConsole.commands = AceConsole.commands or {}

local _G = _G
local type = type
local pairs = pairs
local select = select
local tostring = tostring
local format = string.format
local strfind = string.find
local strsub = string.sub
local strlower = string.lower
local max = math.max

local commands = AceConsole.commands

function AceConsole:RegisterChatCommand(command, func, persist)
    if type(command) ~= "string" then
        error([[Usage: AceConsole:RegisterChatCommand(command, func, persist): 'command' - string expected]], 2)
    end
    if type(func) ~= "string" and type(func) ~= "function" then
        error([[Usage: AceConsole:RegisterChatCommand(command, func, persist): 'func' - string or function expected]], 2)
    end

    command = strlower(command)

    if func == nil then
        func = command
    end

    local name = "ACECONSOLE_" .. command:upper()

    if type(func) == "string" then
        local handlerFunc = self[func]
        if type(handlerFunc) ~= "function" then
            error(([[Usage: AceConsole:RegisterChatCommand(command, func): 'func' - method '%s' not found]]):format(func), 2)
        end
        func = function(msg, editBox)
            handlerFunc(self, msg, editBox)
        end
    end

    if not commands[command] then
        commands[command] = {func, name, self}
        SlashCmdList[name] = function(msg, editBox)
            commands[command][1](msg, editBox)
        end
        _G["SLASH_" .. name .. "1"] = "/" .. command
    else
        commands[command][1] = func
        commands[command][3] = self
    end
end

function AceConsole:UnregisterChatCommand(command)
    if type(command) ~= "string" then
        error([[Usage: AceConsole:UnregisterChatCommand(command): 'command' - string expected]], 2)
    end

    command = strlower(command)

    if commands[command] then
        local name = commands[command][2]
        SlashCmdList[name] = nil
        _G["SLASH_" .. name .. "1"] = nil
        commands[command] = nil
    end
end

function AceConsole:Print(...)
    local text = ""
    local n = select("#", ...)
    for i = 1, n do
        text = text .. tostring(select(i, ...))
        if i < n then text = text .. " " end
    end
    DEFAULT_CHAT_FRAME:AddMessage(text)
end

function AceConsole:Printf(fmt, ...)
    if type(fmt) ~= "string" then
        error("Usage: AceConsole:Printf(format, ...): 'format' - string expected", 2)
    end
    DEFAULT_CHAT_FRAME:AddMessage(format(fmt, ...))
end

local mixins = {
    "RegisterChatCommand", "UnregisterChatCommand",
    "Print", "Printf"
}

function AceConsole:Embed(target)
    for _, v in pairs(mixins) do
        target[v] = self[v]
    end
    self.embeds[target] = true
    return target
end

for addon in pairs(AceConsole.embeds) do
    AceConsole:Embed(addon)
end
