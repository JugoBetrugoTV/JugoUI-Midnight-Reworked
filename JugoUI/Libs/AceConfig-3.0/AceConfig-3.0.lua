--[[ AceConfig-3.0 - A wrapper for AceConfigRegistry, AceConfigDialog, and AceConfigCmd
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceConfig-3.0", 3
local AceConfig = LibStub:NewLibrary(MAJOR, MINOR)
if not AceConfig then return end

local cfgreg = LibStub("AceConfigRegistry-3.0")
local cfgcmd = LibStub("AceConfigCmd-3.0")
local cfgdlg = LibStub("AceConfigDialog-3.0")

function AceConfig:RegisterOptionsTable(appName, options, slashcmd)
    cfgreg:RegisterOptionsTable(appName, options)
    if slashcmd then
        if type(slashcmd) == "table" then
            for _, cmd in pairs(slashcmd) do
                cfgcmd:CreateChatCommand(cmd, appName)
            end
        else
            cfgcmd:CreateChatCommand(slashcmd, appName)
        end
    end
end
