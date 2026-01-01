--[[
    JugoUI - Config/Core.lua
    Configuration system using Ace3
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

-- Config panel reference
E.configFrame = nil

function E:OpenConfig()
    if not E.configFrame then
        E:CreateConfigFrame()
    end

    -- Use AceConfigDialog
    AceConfigDialog:Open("JugoUI")
end

function E:CreateConfigFrame()
    -- Register main options table
    AceConfig:RegisterOptionsTable("JugoUI", E:GetMainOptions())

    -- Register module options as sub-categories
    for name, module in E:IterateModules() do
        if module.GetOptions then
            local options = module:GetOptions()
            if options then
                AceConfig:RegisterOptionsTable("JugoUI_" .. name, options)
                AceConfigDialog:AddToBlizOptions("JugoUI_" .. name, name, "JugoUI")
            end
        end
    end

    -- Add to Blizzard options
    E.configFrame = AceConfigDialog:AddToBlizOptions("JugoUI", "JugoUI")
end

function E:GetMainOptions()
    return {
        type = "group",
        name = "|cff00ffffJugo|r|cffffffffUI|r",
        args = {
            header = {
                type = "header",
                name = "|cff00ffffJugo|r|cffffffffUI|r Configuration",
                order = 1,
            },
            general = {
                type = "group",
                name = "General",
                order = 10,
                args = {
                    uiScale = {
                        type = "range",
                        name = "UI Scale",
                        desc = "Set the global UI scale",
                        min = 0.5,
                        max = 1.5,
                        step = 0.01,
                        order = 1,
                        get = function() return E.db.general.uiScale end,
                        set = function(_, v)
                            E.db.general.uiScale = v
                            UIParent:SetScale(v)
                        end,
                    },
                    autoScale = {
                        type = "toggle",
                        name = "Auto Scale",
                        desc = "Automatically scale the UI based on resolution",
                        order = 2,
                        get = function() return E.db.general.autoScale end,
                        set = function(_, v) E.db.general.autoScale = v end,
                    },
                    lockUI = {
                        type = "toggle",
                        name = "Lock UI",
                        desc = "Lock all UI elements in place",
                        order = 3,
                        get = function() return E.db.general.lockUI end,
                        set = function(_, v) E.db.general.lockUI = v end,
                    },
                    loginMessage = {
                        type = "toggle",
                        name = "Login Message",
                        desc = "Show login message",
                        order = 4,
                        get = function() return E.db.general.loginMessage end,
                        set = function(_, v) E.db.general.loginMessage = v end,
                    },
                },
            },
            fonts = {
                type = "group",
                name = "Fonts",
                order = 20,
                args = {
                    font = {
                        type = "select",
                        name = "Primary Font",
                        desc = "Select the primary font",
                        dialogControl = "LSM30_Font",
                        values = AceGUIWidgetLSMlists.font,
                        order = 1,
                        get = function() return E.db.general.font end,
                        set = function(_, v) E.db.general.font = v end,
                    },
                    fontSize = {
                        type = "range",
                        name = "Font Size",
                        desc = "Set the default font size",
                        min = 8,
                        max = 24,
                        step = 1,
                        order = 2,
                        get = function() return E.db.general.fontSize end,
                        set = function(_, v) E.db.general.fontSize = v end,
                    },
                    fontOutline = {
                        type = "select",
                        name = "Font Outline",
                        desc = "Set the font outline style",
                        values = {
                            ["NONE"] = "None",
                            ["OUTLINE"] = "Outline",
                            ["THICKOUTLINE"] = "Thick Outline",
                            ["MONOCHROME"] = "Monochrome",
                        },
                        order = 3,
                        get = function() return E.db.general.fontOutline end,
                        set = function(_, v) E.db.general.fontOutline = v end,
                    },
                },
            },
            textures = {
                type = "group",
                name = "Textures",
                order = 30,
                args = {
                    statusBarTexture = {
                        type = "select",
                        name = "Status Bar Texture",
                        desc = "Select the texture for status bars",
                        dialogControl = "LSM30_Statusbar",
                        values = AceGUIWidgetLSMlists.statusbar,
                        order = 1,
                        get = function() return E.db.general.statusBarTexture end,
                        set = function(_, v) E.db.general.statusBarTexture = v end,
                    },
                },
            },
            modules = {
                type = "group",
                name = "Modules",
                order = 40,
                args = {
                    desc = {
                        type = "description",
                        name = "Enable or disable individual modules below.\n",
                        order = 1,
                    },
                },
            },
            profiles = E.Profiles and E.Profiles:GetOptions() or {},
            credits = E.Credits and E.Credits:GetOptions() or {},
        },
    }
end

-- Add module toggle options
function E:AddModuleOptions()
    local moduleOptions = E:GetMainOptions().args.modules.args
    local order = 10

    for name, module in E:IterateModules() do
        if module.db and module.db.enabled ~= nil then
            moduleOptions[name:lower()] = {
                type = "toggle",
                name = name,
                desc = "Enable/disable the " .. name .. " module",
                order = order,
                get = function() return module.db.enabled end,
                set = function(_, v)
                    module.db.enabled = v
                    if v then
                        E:EnableModule(name)
                    else
                        E:DisableModule(name)
                    end
                end,
            }
            order = order + 1
        end
    end
end
