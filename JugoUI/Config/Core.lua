--[[
    JugoUI - Config/Core.lua
    Configuration system using Ace3 and Blizzard Settings API
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local AceConfig = LibStub("AceConfig-3.0", true)
local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)

-- Config panel reference
E.configFrame = nil
E.settingsCategory = nil

--[[
    Open Configuration
]]
function E:OpenConfig()
    -- Use Blizzard Settings API for 12.0+
    if Settings and Settings.OpenToCategory and E.settingsCategory then
        Settings.OpenToCategory(E.settingsCategory:GetID())
    elseif AceConfigDialog then
        AceConfigDialog:Open("JugoUI")
    else
        E:Print("Configuration not available.")
    end
end

--[[
    Register with Blizzard Settings (12.0+)
]]
function E:RegisterBlizzardSettings()
    if not Settings then
        E:Debug("Settings API not available")
        return
    end

    -- Create main category
    local category = Settings.RegisterCanvasLayoutCategory(E.configFrame or CreateFrame("Frame"), "JugoUI")
    category.ID = "JugoUI"
    Settings.RegisterAddOnCategory(category)
    E.settingsCategory = category

    E:Debug("Registered JugoUI in Blizzard Settings")
end

--[[
    Create Configuration Frame
]]
function E:CreateConfigFrame()
    if E.configFrame then return E.configFrame end

    -- Create main config frame
    local frame = CreateFrame("Frame", "JugoUIConfigFrame", UIParent)
    frame.name = "JugoUI"
    frame:Hide()

    -- Create scroll frame for options
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -16)
    scrollFrame:SetPoint("BOTTOMRIGHT", -32, 16)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(scrollChild)

    -- Header
    local header = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetText("|cff00ffffJugo|r|cffffffffUI|r - Configuration")

    -- Version info
    local version = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    version:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)
    version:SetText("Version: " .. (E.version or "1.0.0") .. " | WoW Build: " .. (E.wowbuild or "Unknown"))
    version:SetTextColor(0.7, 0.7, 0.7)

    -- Description
    local desc = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -16)
    desc:SetText("A complete UI replacement for World of Warcraft: Midnight (Patch 12.0)")
    desc:SetWidth(500)
    desc:SetJustifyH("LEFT")

    -- Open Full Config button
    local openButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    openButton:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    openButton:SetSize(200, 30)
    openButton:SetText("Open Full Configuration")
    openButton:SetScript("OnClick", function()
        if AceConfigDialog then
            HideUIPanel(SettingsPanel)
            AceConfigDialog:Open("JugoUI")
        end
    end)

    -- Module status section
    local moduleHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    moduleHeader:SetPoint("TOPLEFT", openButton, "BOTTOMLEFT", 0, -30)
    moduleHeader:SetText("Installed Modules:")

    local yOffset = -20
    local moduleList = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    moduleList:SetPoint("TOPLEFT", moduleHeader, "BOTTOMLEFT", 10, yOffset)
    moduleList:SetJustifyH("LEFT")
    moduleList:SetWidth(400)

    local modules = {
        "ActionBars", "Bags", "Buffs", "Chat", "InfoBar",
        "Minimap", "Misc", "Nameplates", "RaidFrames", "Skins",
        "Tooltip", "UnitFrames", "XPBar"
    }
    moduleList:SetText(table.concat(modules, ", "))

    -- Slash commands info
    local slashHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    slashHeader:SetPoint("TOPLEFT", moduleList, "BOTTOMLEFT", -10, -30)
    slashHeader:SetText("Slash Commands:")

    local slashInfo = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    slashInfo:SetPoint("TOPLEFT", slashHeader, "BOTTOMLEFT", 10, -8)
    slashInfo:SetJustifyH("LEFT")
    slashInfo:SetWidth(400)
    slashInfo:SetText([[
/jui or /jugoui - Open configuration
/jui debug - Toggle debug mode
/jui version - Show version info
/jui reload - Reload UI
/jui status - Show module status
]])

    -- Calculate scroll child height
    scrollChild:SetHeight(400)

    E.configFrame = frame
    return frame
end

--[[
    Initialize Configuration System
]]
function E:InitializeConfig()
    -- Create config frame first
    E:CreateConfigFrame()

    -- Register with AceConfig if available
    if AceConfig then
        AceConfig:RegisterOptionsTable("JugoUI", function() return E:GetMainOptions() end)

        -- Register module options
        for name, module in pairs(E.modules or {}) do
            if module.GetOptions then
                local options = module:GetOptions()
                if options then
                    AceConfig:RegisterOptionsTable("JugoUI_" .. name, options)
                end
            end
        end
    end

    -- Register with Blizzard Settings (12.0+)
    E:RegisterBlizzardSettings()

    E:Debug("Configuration system initialized")
end

--[[
    Main Options Table for AceConfig
]]
function E:GetMainOptions()
    local options = {
        type = "group",
        name = "|cff00ffffJugo|r|cffffffffUI|r",
        childGroups = "tab",
        args = {
            general = {
                type = "group",
                name = "General",
                order = 1,
                args = {
                    header = {
                        type = "header",
                        name = "General Settings",
                        order = 1,
                    },
                    desc = {
                        type = "description",
                        name = "Configure global JugoUI settings.\n\n",
                        order = 2,
                    },
                    uiScale = {
                        type = "range",
                        name = "UI Scale",
                        desc = "Set the global UI scale for JugoUI elements",
                        min = 0.5,
                        max = 1.5,
                        step = 0.01,
                        order = 10,
                        get = function()
                            return E.db and E.db.general and E.db.general.uiScale or 1
                        end,
                        set = function(_, v)
                            if E.db and E.db.general then
                                E.db.general.uiScale = v
                            end
                        end,
                    },
                    autoScale = {
                        type = "toggle",
                        name = "Auto Scale",
                        desc = "Automatically scale the UI based on resolution",
                        order = 11,
                        get = function()
                            return E.db and E.db.general and E.db.general.autoScale
                        end,
                        set = function(_, v)
                            if E.db and E.db.general then
                                E.db.general.autoScale = v
                            end
                        end,
                    },
                    lockUI = {
                        type = "toggle",
                        name = "Lock UI",
                        desc = "Lock all UI elements in place (prevents dragging)",
                        order = 12,
                        get = function()
                            return E.db and E.db.general and E.db.general.lockUI
                        end,
                        set = function(_, v)
                            if E.db and E.db.general then
                                E.db.general.lockUI = v
                            end
                        end,
                    },
                    loginMessage = {
                        type = "toggle",
                        name = "Login Message",
                        desc = "Show JugoUI welcome message on login",
                        order = 13,
                        get = function()
                            return E.db and E.db.general and E.db.general.loginMessage ~= false
                        end,
                        set = function(_, v)
                            if E.db and E.db.general then
                                E.db.general.loginMessage = v
                            end
                        end,
                    },
                    spacer1 = {
                        type = "description",
                        name = "\n",
                        order = 20,
                    },
                    debugMode = {
                        type = "toggle",
                        name = "Debug Mode",
                        desc = "Enable debug output in chat",
                        order = 21,
                        get = function() return E.debug end,
                        set = function(_, v) E.debug = v end,
                    },
                    reloadUI = {
                        type = "execute",
                        name = "Reload UI",
                        desc = "Reload the user interface",
                        order = 100,
                        func = function() ReloadUI() end,
                    },
                },
            },
            fonts = {
                type = "group",
                name = "Fonts",
                order = 2,
                args = {
                    header = {
                        type = "header",
                        name = "Font Settings",
                        order = 1,
                    },
                    desc = {
                        type = "description",
                        name = "Configure fonts used throughout the UI.\n\n",
                        order = 2,
                    },
                    primaryFont = {
                        type = "select",
                        name = "Primary Font",
                        desc = "Select the primary font for UI text",
                        dialogControl = "LSM30_Font",
                        values = function()
                            if E.LSM then
                                return E.LSM:HashTable("font")
                            end
                            return {}
                        end,
                        order = 10,
                        get = function()
                            return E.db and E.db.general and E.db.general.font or "JugoUI Normal"
                        end,
                        set = function(_, v)
                            if E.db and E.db.general then
                                E.db.general.font = v
                            end
                        end,
                    },
                    fontSize = {
                        type = "range",
                        name = "Default Font Size",
                        desc = "Set the default font size",
                        min = 8,
                        max = 24,
                        step = 1,
                        order = 11,
                        get = function()
                            return E.db and E.db.general and E.db.general.fontSize or 12
                        end,
                        set = function(_, v)
                            if E.db and E.db.general then
                                E.db.general.fontSize = v
                            end
                        end,
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
                        order = 12,
                        get = function()
                            return E.db and E.db.general and E.db.general.fontOutline or "OUTLINE"
                        end,
                        set = function(_, v)
                            if E.db and E.db.general then
                                E.db.general.fontOutline = v
                            end
                        end,
                    },
                },
            },
            textures = {
                type = "group",
                name = "Textures",
                order = 3,
                args = {
                    header = {
                        type = "header",
                        name = "Texture Settings",
                        order = 1,
                    },
                    desc = {
                        type = "description",
                        name = "Configure textures used for bars and backgrounds.\n\n",
                        order = 2,
                    },
                    statusBarTexture = {
                        type = "select",
                        name = "Status Bar Texture",
                        desc = "Select the texture for status bars",
                        dialogControl = "LSM30_Statusbar",
                        values = function()
                            if E.LSM then
                                return E.LSM:HashTable("statusbar")
                            end
                            return {}
                        end,
                        order = 10,
                        get = function()
                            return E.db and E.db.general and E.db.general.statusBarTexture or "JugoUI Flat"
                        end,
                        set = function(_, v)
                            if E.db and E.db.general then
                                E.db.general.statusBarTexture = v
                            end
                        end,
                    },
                },
            },
            colors = {
                type = "group",
                name = "Colors",
                order = 4,
                args = {
                    header = {
                        type = "header",
                        name = "Color Settings",
                        order = 1,
                    },
                    desc = {
                        type = "description",
                        name = "Customize colors used throughout the UI.\n\n",
                        order = 2,
                    },
                    healthColor = {
                        type = "color",
                        name = "Health Bar Color",
                        desc = "Default health bar color",
                        hasAlpha = false,
                        order = 10,
                        get = function()
                            local c = E.media and E.media.colors and E.media.colors.health and E.media.colors.health.value
                            if c then return c[1], c[2], c[3] end
                            return 0.31, 0.45, 0.63
                        end,
                        set = function(_, r, g, b)
                            if E.media and E.media.colors and E.media.colors.health then
                                E.media.colors.health.value = {r, g, b}
                            end
                        end,
                    },
                    useClassColors = {
                        type = "toggle",
                        name = "Class Colors",
                        desc = "Use class colors for health bars",
                        order = 11,
                        get = function()
                            return E.db and E.db.general and E.db.general.useClassColors
                        end,
                        set = function(_, v)
                            if E.db and E.db.general then
                                E.db.general.useClassColors = v
                            end
                        end,
                    },
                    useReactionColors = {
                        type = "toggle",
                        name = "Reaction Colors",
                        desc = "Use reaction colors for NPC health bars",
                        order = 12,
                        get = function()
                            return E.db and E.db.general and E.db.general.useReactionColors
                        end,
                        set = function(_, v)
                            if E.db and E.db.general then
                                E.db.general.useReactionColors = v
                            end
                        end,
                    },
                },
            },
            modules = {
                type = "group",
                name = "Modules",
                order = 5,
                args = {
                    header = {
                        type = "header",
                        name = "Module Settings",
                        order = 1,
                    },
                    desc = {
                        type = "description",
                        name = "Enable or disable individual modules. Changes may require a UI reload.\n\n",
                        order = 2,
                    },
                },
            },
            profiles = {
                type = "group",
                name = "Profiles",
                order = 100,
                args = E:GetProfileOptions(),
            },
            credits = {
                type = "group",
                name = "Credits",
                order = 200,
                args = {
                    header = {
                        type = "header",
                        name = "Credits",
                        order = 1,
                    },
                    desc = {
                        type = "description",
                        name = [[
|cff00ffffJugo|r|cffffffffUI|r

Created for World of Warcraft: Midnight (Patch 12.0)

|cffff8800Libraries Used:|r
- Ace3 Framework (AceAddon, AceDB, AceConfig, etc.)
- LibSharedMedia-3.0
- LibDataBroker-1.1
- LibDBIcon-1.0
- LibActionButton-1.0
- LibCustomGlow-1.0

|cffff8800Special Thanks:|r
- The WoW addon community
- Blizzard Entertainment
- All testers and contributors

|cff00ff00Type /jui for quick access!|r
]],
                        order = 2,
                        fontSize = "medium",
                    },
                },
            },
        },
    }

    -- Add module toggle options dynamically
    E:AddModuleToggles(options.args.modules.args)

    return options
end

--[[
    Add Module Toggle Options
]]
function E:AddModuleToggles(args)
    local order = 10
    local moduleInfo = {
        {name = "ActionBars", desc = "Action bar replacement with button customization"},
        {name = "Bags", desc = "Bag and inventory management"},
        {name = "Buffs", desc = "Buff and debuff display"},
        {name = "Chat", desc = "Chat frame enhancements"},
        {name = "InfoBar", desc = "Information bar with stats display"},
        {name = "Minimap", desc = "Minimap customization"},
        {name = "Misc", desc = "Miscellaneous quality of life features"},
        {name = "Nameplates", desc = "Nameplate customization"},
        {name = "RaidFrames", desc = "Raid and party frame replacement"},
        {name = "Skins", desc = "UI skinning for Blizzard frames"},
        {name = "Tooltip", desc = "Tooltip enhancements"},
        {name = "UnitFrames", desc = "Unit frame replacement"},
        {name = "XPBar", desc = "Experience and reputation bar"},
    }

    for _, info in ipairs(moduleInfo) do
        args[info.name:lower()] = {
            type = "toggle",
            name = info.name,
            desc = info.desc,
            order = order,
            get = function()
                local module = E.modules and E.modules[info.name]
                if module and module.db then
                    return module.db.enabled ~= false
                end
                return true
            end,
            set = function(_, v)
                local module = E.modules and E.modules[info.name]
                if module then
                    if module.db then
                        module.db.enabled = v
                    end
                    if v then
                        E:EnableModule(info.name)
                    else
                        E:DisableModule(info.name)
                    end
                end
            end,
        }
        order = order + 1
    end
end

--[[
    Profile Options
]]
function E:GetProfileOptions()
    local options = {
        header = {
            type = "header",
            name = "Profile Management",
            order = 1,
        },
        desc = {
            type = "description",
            name = "Manage your JugoUI profiles. Profiles allow you to save different configurations.\n\n",
            order = 2,
        },
    }

    -- Add AceDB profile options if available
    if E.db and E.db.RegisterDefaults then
        local LibDualSpec = LibStub("LibDualSpec-1.0", true)
        if LibDualSpec then
            options.dualSpec = {
                type = "toggle",
                name = "Dual Spec Profiles",
                desc = "Enable separate profiles per specialization",
                order = 10,
                get = function()
                    return E.db and E.db.isDualSpec
                end,
                set = function(_, v)
                    if E.db then
                        if v then
                            LibDualSpec:EnhanceDatabase(E.db, "JugoUI")
                        end
                    end
                end,
            }
        end
    end

    return options
end

-- Register callback to initialize config after PLAYER_LOGIN
if E.RegisterEvent then
    E:RegisterEvent("PLAYER_LOGIN", function()
        C_Timer.After(1, function()
            E:InitializeConfig()
        end)
    end)
end
