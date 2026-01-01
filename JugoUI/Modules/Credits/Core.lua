--[[
    JugoUI - Credits/Core.lua
    Credits and about information
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local CR = E:NewModule("Credits")
E.Credits = CR

CR.authors = {
    "JugoBetrugoTV",
}

CR.contributors = {
    -- Add contributors here
}

CR.libraries = {
    "Ace3 (AceAddon, AceDB, AceConfig, AceConsole, AceEvent, AceHook, AceTimer, AceComm, AceSerializer, AceGUI)",
    "LibStub",
    "CallbackHandler-1.0",
    "LibSharedMedia-3.0",
    "LibDataBroker-1.1",
    "LibDBIcon-1.0",
    "LibActionButton-1.0",
    "LibCustomGlow-1.0",
    "LibRangeCheck-3.0",
    "LibDispellable-1.0",
    "LibDeflate",
    "LibSerialize",
    "LibDualSpec-1.0",
}

CR.inspirations = {
    "ElvUI",
    "Tukui",
    "ShadowedUnitFrames",
    "Bartender4",
    "Dominos",
    "Bagnon",
    "Prat",
    "TipTac",
    "SexyMap",
    "Masque",
}

function CR:OnInitialize()
    -- Nothing to initialize
end

function CR:OnEnable()
    -- Nothing to enable
end

function CR:GetOptions()
    return {
        type = "group",
        name = "Credits",
        args = {
            header = {
                type = "header",
                name = "|cff00ffffJugo|r|cffffffffUI|r v" .. E.version,
                order = 1,
            },
            desc = {
                type = "description",
                name = "\nA complete UI replacement for World of Warcraft: Midnight (Patch 12.0)\n",
                order = 2,
                fontSize = "medium",
            },
            authors = {
                type = "group",
                name = "Authors",
                inline = true,
                order = 10,
                args = {
                    list = {
                        type = "description",
                        name = table.concat(CR.authors, "\n"),
                        fontSize = "medium",
                    },
                },
            },
            libraries = {
                type = "group",
                name = "Libraries Used",
                inline = true,
                order = 20,
                args = {
                    list = {
                        type = "description",
                        name = table.concat(CR.libraries, "\n"),
                        fontSize = "small",
                    },
                },
            },
            inspirations = {
                type = "group",
                name = "Inspired By",
                inline = true,
                order = 30,
                args = {
                    list = {
                        type = "description",
                        name = table.concat(CR.inspirations, ", "),
                        fontSize = "small",
                    },
                },
            },
            support = {
                type = "group",
                name = "Support",
                inline = true,
                order = 40,
                args = {
                    desc = {
                        type = "description",
                        name = "Report issues and get help at:\nhttps://github.com/JugoBetrugoTV/JugoUI\n\nThank you for using JugoUI!",
                        fontSize = "medium",
                    },
                },
            },
        },
    }
end
