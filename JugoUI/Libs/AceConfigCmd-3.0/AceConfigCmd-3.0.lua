--[[ AceConfigCmd-3.0 - Command-line interface for AceConfig options
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceConfigCmd-3.0", 14
local AceConfigCmd = LibStub:NewLibrary(MAJOR, MINOR)
if not AceConfigCmd then return end

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConsole = LibStub("AceConsole-3.0", true)

local type = type
local pairs = pairs
local print = print
local format = string.format
local strlower = string.lower
local strmatch = string.match
local strsplit = strsplit
local tostring = tostring

AceConfigCmd.commands = AceConfigCmd.commands or {}
local commands = AceConfigCmd.commands

local function IterateArgs(options, key)
    if options.args then
        return pairs(options.args)
    end
    return pairs({})
end

local function HandleCommand(slashcmd, appName, input)
    local options = AceConfigRegistry:GetOptionsTable(appName)
    if not options then
        print(format("No options registered for '%s'", appName))
        return
    end

    if not input or input == "" then
        if options.type == "group" then
            print(format("%s options:", options.name or appName))
            for key, opt in IterateArgs(options) do
                if opt.type ~= "header" and opt.type ~= "description" then
                    print(format("  %s - %s", key, opt.name or key))
                end
            end
        end
        return
    end

    local path = {}
    for part in input:gmatch("[^ ]+") do
        path[#path + 1] = strlower(part)
    end

    local current = options
    for i, key in pairs(path) do
        if current.type == "group" and current.args and current.args[key] then
            current = current.args[key]
        else
            print(format("Unknown option: %s", key))
            return
        end
    end

    if current.type == "group" then
        print(format("%s options:", current.name or path[#path]))
        for key, opt in IterateArgs(current) do
            if opt.type ~= "header" and opt.type ~= "description" then
                print(format("  %s - %s", key, opt.name or key))
            end
        end
    elseif current.type == "execute" then
        if current.func then
            current.func()
        end
    else
        print(format("Option '%s' (%s)", current.name, current.type))
        if current.desc then
            print(format("  %s", current.desc))
        end
    end
end

function AceConfigCmd:CreateChatCommand(slashcmd, appName)
    if type(slashcmd) ~= "string" then
        error("Usage: AceConfigCmd:CreateChatCommand(slashcmd, appName): 'slashcmd' - string expected", 2)
    end
    if type(appName) ~= "string" then
        error("Usage: AceConfigCmd:CreateChatCommand(slashcmd, appName): 'appName' - string expected", 2)
    end

    commands[slashcmd] = appName

    slashcmd = slashcmd:lower()
    local name = "ACECONFIGCMD_" .. slashcmd:upper()

    SlashCmdList[name] = function(input)
        HandleCommand(slashcmd, appName, input)
    end
    _G["SLASH_" .. name .. "1"] = "/" .. slashcmd

    return true
end
