--[[
    JugoUI - Init.lua
    Core initialization for the addon
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...

-- Create main addon object using Ace3
local JugoUI = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "AceComm-3.0", "AceSerializer-3.0")

-- Engine namespace for internal use
Engine[1] = JugoUI           -- E (addon object)
Engine[2] = {}               -- L (locale table)
Engine[3] = {}               -- V (private variables)
Engine[4] = {}               -- P (profile defaults)
Engine[5] = {}               -- G (global defaults)

-- Expose to global namespace
_G[ADDON_NAME] = Engine

-- Shortcuts
local E, L, V, P, G = unpack(Engine)

-- Version info
E.version = "1.0.0"
E.wowpatch = "12.0.0"
E.wowbuild = select(4, GetBuildInfo())
E.addonName = ADDON_NAME
E.isMidnight = E.wowbuild >= 120000

-- Player info cache
E.myname = UnitName("player")
E.myrealm = GetRealmName()
E.myclass = select(2, UnitClass("player"))
E.mylocalizedclass = select(1, UnitClass("player"))
E.myrace = select(2, UnitRace("player"))
E.myfaction = UnitFactionGroup("player")
E.mylevel = UnitLevel("player")
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

-- Callback storage for inter-module communication
E.callbacks = LibStub("CallbackHandler-1.0"):New(E)

-- Shared Media library
E.LSM = LibStub("LibSharedMedia-3.0")

-- DataBroker
E.LDB = LibStub("LibDataBroker-1.1", true)
E.LDBIcon = LibStub("LibDBIcon-1.0", true)

-- Frame pool for recycling frames
E.framePool = {}

-- Delayed updates queue
E.updateQueue = {}

-- Debug mode
E.debug = false

--[[
    Print functions
]]
function E:Print(...)
    print("|cff00ffffJugo|r|cffffffffUI:|r", ...)
end

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

--[[
    Addon Initialization
]]
function JugoUI:OnInitialize()
    -- Initialize saved variables
    self.db = LibStub("AceDB-3.0"):New("JugoUIDB", {
        profile = P,
        global = G,
    }, true)

    -- Character-specific private settings
    if not JugoUICharDB then JugoUICharDB = {} end
    E.private = JugoUICharDB

    -- Merge defaults
    E.db = self.db.profile
    E.global = self.db.global

    -- Setup profile callbacks
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

    -- Initialize dual spec support if available
    local LibDualSpec = LibStub("LibDualSpec-1.0", true)
    if LibDualSpec then
        LibDualSpec:EnhanceDatabase(self.db, ADDON_NAME)
    end

    -- Register slash commands
    self:RegisterChatCommand("jugoui", "SlashCommand")
    self:RegisterChatCommand("jui", "SlashCommand")

    -- Get player GUID
    E.myguid = UnitGUID("player")

    E:Print("v" .. E.version .. " loaded. Type /jui for options.")
end

function JugoUI:OnEnable()
    -- Register events
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_LEVEL_UP")
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    self:RegisterEvent("UI_SCALE_CHANGED")

    -- Initialize modules
    E:InitializeModules()

    -- Fire callback for addons waiting on JugoUI
    E.callbacks:Fire("JugoUI_Initialized")
end

function JugoUI:OnDisable()
    -- Disable all modules
    for name, module in pairs(E.modules) do
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
        E.mylevel = UnitLevel("player")
        E.myguid = UnitGUID("player")

        -- Delayed initialization for some modules
        C_Timer.After(0.5, function()
            E.callbacks:Fire("JugoUI_Ready")
        end)
    end
end

function JugoUI:PLAYER_LEVEL_UP(event, level)
    E.mylevel = level
    E.callbacks:Fire("JugoUI_LevelUp", level)
end

function JugoUI:ACTIVE_TALENT_GROUP_CHANGED()
    E.callbacks:Fire("JugoUI_SpecChanged")
end

function JugoUI:UI_SCALE_CHANGED()
    E.uiscale = UIParent:GetScale()
    E.callbacks:Fire("JugoUI_ScaleChanged")
end

--[[
    Profile Management
]]
function JugoUI:OnProfileChanged(event, database, newProfileKey)
    E.db = database.profile
    E.callbacks:Fire("JugoUI_ProfileChanged")

    -- Refresh all modules
    for name, module in pairs(E.modules) do
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
        E:OpenConfig()
    elseif input == "debug" then
        E.debug = not E.debug
        E:Print("Debug mode:", E.debug and "|cff00ff00ON|r" or "|cffff0000OFF|r")
    elseif input == "version" or input == "ver" then
        E:Print("Version:", E.version, "| WoW Build:", E.wowbuild)
    elseif input == "reload" or input == "rl" then
        ReloadUI()
    elseif input == "status" then
        E:PrintModuleStatus()
    else
        E:Print("Available commands:")
        E:Print("/jui - Open configuration")
        E:Print("/jui debug - Toggle debug mode")
        E:Print("/jui version - Show version info")
        E:Print("/jui reload - Reload UI")
        E:Print("/jui status - Show module status")
    end
end

--[[
    Addon Compartment (Minimap button menu for 10.0+)
]]
function JugoUI_OnAddonCompartmentClick(addonName, buttonName)
    E:OpenConfig()
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
