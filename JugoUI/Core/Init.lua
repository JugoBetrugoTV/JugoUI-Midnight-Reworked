--[[
    JugoUI - Init.lua
    Core initialization for the addon
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...

-- Initialize Engine namespace first (before any library calls)
Engine[1] = {}              -- E (addon object) - will be populated after AceAddon creation
Engine[2] = {}              -- L (locale table)
Engine[3] = {}              -- V (private variables)
Engine[4] = {}              -- P (profile defaults)
Engine[5] = {}              -- G (global defaults)

-- Expose to global namespace
_G[ADDON_NAME] = Engine

-- Get reference to E for setting up basic properties
local E = Engine[1]

-- Basic addon info (set before AceAddon)
E.version = "1.0.0"
E.wowpatch = "12.0.0"
E.wowbuild = select(4, GetBuildInfo())
E.addonName = ADDON_NAME
E.isMidnight = E.wowbuild >= 120000

-- Player info cache
E.myname = UnitName("player") or "Unknown"
E.myrealm = GetRealmName() or "Unknown"
E.myclass = select(2, UnitClass("player")) or "WARRIOR"
E.mylocalizedclass = select(1, UnitClass("player")) or "Warrior"
E.myrace = select(2, UnitRace("player")) or "Human"
E.myfaction = UnitFactionGroup("player") or "Alliance"
E.mylevel = UnitLevel("player") or 1
E.myguid = nil -- Set on PLAYER_LOGIN

-- Resolution and scaling
E.resolution = GetCVar("gxWindowedResolution") or "1920x1080"
E.screenwidth, E.screenheight = GetPhysicalScreenSize()
E.uiscale = UIParent:GetScale()

-- Global media paths
E.mediaPath = "Interface\\AddOns\\JugoUI\\Media\\"

-- Initialize databases
E.db = nil          -- Profile database
E.global = nil      -- Global database
E.private = nil     -- Character-specific database

-- Module storage
E.modules = {}
E.registeredModules = {}
E.initializedModules = {}

-- Frame pool for recycling frames
E.framePool = {}

-- Delayed updates queue
E.updateQueue = {}

-- Debug mode
E.debug = false

--[[
    Print functions (available before Ace3)
]]
local function Print(...)
    print("|cff00ffffJugo|r|cffffffffUI:|r", ...)
end

E.Print = function(self, ...) Print(...) end

function E:Debug(...)
    if self.debug then
        print("|cff00ffffJugo|r|cffff0000DEBUG:|r", ...)
    end
end

function E:Error(...)
    print("|cff00ffffJugo|r|cffff0000ERROR:|r", ...)
end

function E:Warning(...)
    print("|cff00ffffJugo|r|cffffff00WARNING:|r", ...)
end

--[[
    Secure Value Handling for Patch 12.0
    New APIs to handle secret values in combat
]]
function E:IsSecretValue(value)
    if issecretvalue then
        return issecretvalue(value)
    end
    return false
end

function E:CanAccessSecrets()
    if canaccesssecrets then
        return canaccesssecrets()
    end
    return true -- Pre-12.0 compatibility
end

function E:CanAccessValue(value)
    if canaccessvalue then
        return canaccessvalue(value)
    end
    return true
end

-- Check if LibStub exists
if not LibStub then
    Print("LibStub not found! Please ensure libraries are installed correctly.")
    return
end

-- Try to get required libraries
local AceAddon = LibStub("AceAddon-3.0", true)
if not AceAddon then
    Print("AceAddon-3.0 not found! Please ensure Ace3 libraries are installed correctly.")
    return
end

-- Create main addon object using Ace3
local JugoUI = AceAddon:NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0")

-- Copy all E properties to JugoUI
for k, v in pairs(E) do
    if JugoUI[k] == nil then
        JugoUI[k] = v
    end
end

-- Update Engine reference to use JugoUI
Engine[1] = JugoUI

-- Shortcuts for other files
local L, V, P, G = Engine[2], Engine[3], Engine[4], Engine[5]

-- Get optional libraries
JugoUI.callbacks = LibStub("CallbackHandler-1.0", true) and LibStub("CallbackHandler-1.0"):New(JugoUI) or nil
JugoUI.LSM = LibStub("LibSharedMedia-3.0", true)
JugoUI.LDB = LibStub("LibDataBroker-1.1", true)
JugoUI.LDBIcon = LibStub("LibDBIcon-1.0", true)

--[[
    Addon Initialization
]]
function JugoUI:OnInitialize()
    -- Initialize saved variables
    local AceDB = LibStub("AceDB-3.0", true)
    if AceDB then
        self.db = AceDB:New("JugoUIDB", {
            profile = P,
            global = G,
        }, true)

        -- Setup profile callbacks (check if RegisterCallback exists)
        if self.db and self.db.RegisterCallback then
            self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
            self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
            self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
        end

        -- Merge defaults
        self.profile = self.db.profile
        self.global = self.db.global
    end

    -- Character-specific private settings
    if not JugoUICharDB then JugoUICharDB = {} end
    self.private = JugoUICharDB

    -- Initialize dual spec support if available
    local LibDualSpec = LibStub("LibDualSpec-1.0", true)
    if LibDualSpec and self.db then
        LibDualSpec:EnhanceDatabase(self.db, ADDON_NAME)
    end

    -- Register slash commands
    self:RegisterChatCommand("jugoui", "SlashCommand")
    self:RegisterChatCommand("jui", "SlashCommand")

    -- Get player GUID
    self.myguid = UnitGUID("player")

    self:Print("v" .. self.version .. " loaded. Type /jui for options.")
end

function JugoUI:OnEnable()
    -- Register events
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_LEVEL_UP")
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    self:RegisterEvent("UI_SCALE_CHANGED")

    -- Initialize modules
    if self.InitializeModules then
        self:InitializeModules()
    end

    -- Fire callback for addons waiting on JugoUI
    if self.callbacks then
        self.callbacks:Fire("JugoUI_Initialized")
    end
end

function JugoUI:OnDisable()
    -- Disable all modules
    for name, module in pairs(self.modules or {}) do
        if module.Disable then
            module:Disable()
        end
    end
end

--[[
    Event Handlers
]]
function JugoUI:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
    if isLogin or isReload then
        -- Update player info
        self.mylevel = UnitLevel("player")
        self.myguid = UnitGUID("player")

        -- Delayed initialization for some modules
        C_Timer.After(0.5, function()
            if self.callbacks then
                self.callbacks:Fire("JugoUI_Ready")
            end
        end)
    end
end

function JugoUI:PLAYER_LEVEL_UP(event, level)
    self.mylevel = level
    if self.callbacks then
        self.callbacks:Fire("JugoUI_LevelUp", level)
    end
end

function JugoUI:ACTIVE_TALENT_GROUP_CHANGED()
    if self.callbacks then
        self.callbacks:Fire("JugoUI_SpecChanged")
    end
end

function JugoUI:UI_SCALE_CHANGED()
    self.uiscale = UIParent:GetScale()
    if self.callbacks then
        self.callbacks:Fire("JugoUI_ScaleChanged")
    end
end

--[[
    Profile Management
]]
function JugoUI:OnProfileChanged(event, database, newProfileKey)
    self.profile = database.profile
    if self.callbacks then
        self.callbacks:Fire("JugoUI_ProfileChanged")
    end

    -- Refresh all modules
    for name, module in pairs(self.modules or {}) do
        if module.ProfileChanged then
            module:ProfileChanged()
        end
    end
end

--[[
    Slash Command Handler
]]
function JugoUI:SlashCommand(input)
    input = input and input:trim():lower() or ""

    if input == "" or input == "config" or input == "options" then
        if self.OpenConfig then
            self:OpenConfig()
        else
            self:Print("Configuration not yet available.")
        end
    elseif input == "debug" then
        self.debug = not self.debug
        self:Print("Debug mode:", self.debug and "|cff00ff00ON|r" or "|cffff0000OFF|r")
    elseif input == "version" or input == "ver" then
        self:Print("Version:", self.version, "| WoW Build:", self.wowbuild)
    elseif input == "reload" or input == "rl" then
        ReloadUI()
    elseif input == "status" then
        local count = 0
        for _ in pairs(self.modules or {}) do count = count + 1 end
        self:Print("Modules loaded:", count)
    else
        self:Print("Available commands:")
        self:Print("/jui - Open configuration")
        self:Print("/jui debug - Toggle debug mode")
        self:Print("/jui version - Show version info")
        self:Print("/jui reload - Reload UI")
        self:Print("/jui status - Show module status")
    end
end

--[[
    Addon Compartment (Minimap button menu for 10.0+)
]]
function JugoUI_OnAddonCompartmentClick(addonName, buttonName)
    local E = _G[ADDON_NAME] and _G[ADDON_NAME][1]
    if E and E.OpenConfig then
        E:OpenConfig()
    end
end

function JugoUI_OnAddonCompartmentEnter(addonName, menuButtonFrame)
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
    GameTooltip:SetText("|cff00ffffJugo|r|cffffffffUI|r", 1, 1, 1)
    GameTooltip:AddLine("Click to open configuration", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end

function JugoUI_OnAddonCompartmentLeave(addonName, menuButtonFrame)
    GameTooltip:Hide()
end
