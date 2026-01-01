--[[
    JugoUI - UnitFrames/Core.lua
    Core unit frame functionality
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

-- Create module
local UF = E:NewModule("UnitFrames", "AceEvent-3.0", "AceTimer-3.0")
E.UnitFrames = UF

-- Storage for created frames
UF.frames = {}
UF.headers = {}
UF.elements = {}

-- Unit map for quick lookups
UF.units = {
    "player", "target", "targettarget",
    "focus", "focustarget",
    "pet", "pettarget",
    "party", "boss", "arena"
}

--[[
    Module Initialization
]]
function UF:OnInitialize()
    self.db = E.db.unitframes

    -- Register element constructors
    self:RegisterElements()
end

function UF:OnEnable()
    -- Create unit frames
    self:CreateAllFrames()

    -- Register events
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("PLAYER_FOCUS_CHANGED")
    self:RegisterEvent("UNIT_PET")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")

    -- Disable Blizzard frames
    self:DisableBlizzardFrames()
end

function UF:OnDisable()
    -- Hide all frames
    for unit, frame in pairs(self.frames) do
        if frame then
            frame:Hide()
        end
    end
end

--[[
    Create All Frames
]]
function UF:CreateAllFrames()
    -- Create individual unit frames
    if self.db.player.enabled then
        self:CreatePlayerFrame()
    end

    if self.db.target.enabled then
        self:CreateTargetFrame()
    end

    if self.db.targettarget.enabled then
        self:CreateTargetTargetFrame()
    end

    if self.db.focus.enabled then
        self:CreateFocusFrame()
    end

    if self.db.focustarget.enabled then
        self:CreateFocusTargetFrame()
    end

    if self.db.pet.enabled then
        self:CreatePetFrame()
    end

    -- Create headers for party/boss/arena
    if self.db.party.enabled then
        self:CreatePartyFrames()
    end

    if self.db.boss.enabled then
        self:CreateBossFrames()
    end

    if self.db.arena.enabled then
        self:CreateArenaFrames()
    end
end

--[[
    Base Frame Creation
]]
function UF:CreateUnitFrame(unit, name, config)
    -- Don't create in combat
    if InCombatLockdown() then
        E:DelayUntilOutOfCombat(function()
            self:CreateUnitFrame(unit, name, config)
        end)
        return nil
    end

    local frameName = name or ("JugoUI_" .. unit:gsub("^%l", string.upper))
    local frame = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate")

    -- Basic setup
    frame:SetSize(config.width or 200, config.height or 40)
    frame.unit = unit
    frame.config = config

    -- Register unit
    frame:SetAttribute("unit", unit)
    RegisterUnitWatch(frame)

    -- Click handling
    frame:RegisterForClicks("AnyUp")
    frame:SetAttribute("*type1", "target")
    frame:SetAttribute("*type2", "togglemenu")

    -- Background
    frame.backdrop = E:CreateBackdrop(frame, "Transparent")

    -- Create health bar
    frame.Health = self:CreateHealth(frame)

    -- Create power bar if enabled
    if config.powerHeight and config.powerHeight > 0 then
        frame.Power = self:CreatePower(frame)
    end

    -- Create portrait if enabled
    if config.portrait and config.portrait.enabled then
        frame.Portrait = self:CreatePortrait(frame, config.portrait)
    end

    -- Create name text
    frame.Name = self:CreateName(frame)

    -- Create level text
    frame.Level = self:CreateLevel(frame)

    -- Create auras if enabled
    if config.buffs and config.buffs.enabled then
        frame.Buffs = self:CreateAuras(frame, "HELPFUL", config.buffs)
    end

    if config.debuffs and config.debuffs.enabled then
        frame.Debuffs = self:CreateAuras(frame, "HARMFUL", config.debuffs)
    end

    -- Create class power if applicable
    if config.classbar and config.classbar.enabled then
        frame.ClassPower = self:CreateClassPower(frame, config.classbar)
    end

    -- Create indicators
    frame.RaidTargetIndicator = self:CreateRaidIcon(frame)
    frame.ReadyCheckIndicator = self:CreateReadyCheck(frame)
    frame.ResurrectIndicator = self:CreateResurrectIcon(frame)
    frame.RoleIcon = self:CreateRoleIcon(frame)

    -- Threat indicator
    if self.db.threatDisplay then
        frame.ThreatIndicator = self:CreateThreatIndicator(frame)
    end

    -- Heal prediction
    frame.HealPrediction = self:CreateHealPrediction(frame)

    -- Range check
    frame.Range = self:CreateRange(frame)

    -- Position the frame
    self:PositionFrame(frame, config.point)

    -- Enable updates
    frame:SetScript("OnEvent", self.OnUnitEvent)
    frame:SetScript("OnUpdate", self.OnUnitUpdate)

    -- Register events
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_MAXPOWER")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")
    frame:RegisterEvent("UNIT_NAME_UPDATE")
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("UNIT_LEVEL")
    frame:RegisterEvent("UNIT_FACTION")
    frame:RegisterEvent("UNIT_CONNECTION")
    frame:RegisterEvent("PARTY_MEMBER_ENABLE")
    frame:RegisterEvent("PARTY_MEMBER_DISABLE")
    frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
    frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    frame:RegisterEvent("READY_CHECK")
    frame:RegisterEvent("READY_CHECK_FINISHED")
    frame:RegisterEvent("UNIT_ENTERED_VEHICLE")
    frame:RegisterEvent("UNIT_EXITED_VEHICLE")

    -- Store reference
    self.frames[unit] = frame

    -- Initial update
    self:UpdateFrame(frame)

    return frame
end

--[[
    Frame Positioning
]]
function UF:PositionFrame(frame, point)
    if not point then return end

    if InCombatLockdown() then
        E:DelayUntilOutOfCombat(function()
            self:PositionFrame(frame, point)
        end)
        return
    end

    frame:ClearAllPoints()

    if type(point[2]) == "string" then
        -- Point references another frame by name
        local relativeTo = _G[point[2]] or UIParent
        frame:SetPoint(point[1], relativeTo, point[3], point[4] or 0, point[5] or 0)
    else
        -- Point references a frame object
        frame:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)
    end
end

--[[
    Frame Updates
]]
function UF:UpdateFrame(frame)
    if not frame or not frame.unit then return end

    local unit = frame.unit

    -- Update health
    if frame.Health then
        self:UpdateHealth(frame)
    end

    -- Update power
    if frame.Power then
        self:UpdatePower(frame)
    end

    -- Update portrait
    if frame.Portrait then
        self:UpdatePortrait(frame)
    end

    -- Update name
    if frame.Name then
        self:UpdateName(frame)
    end

    -- Update level
    if frame.Level then
        self:UpdateLevel(frame)
    end

    -- Update auras
    if frame.Buffs then
        self:UpdateAuras(frame, "HELPFUL")
    end

    if frame.Debuffs then
        self:UpdateAuras(frame, "HARMFUL")
    end

    -- Update class power
    if frame.ClassPower then
        self:UpdateClassPower(frame)
    end

    -- Update indicators
    if frame.RaidTargetIndicator then
        self:UpdateRaidIcon(frame)
    end

    if frame.RoleIcon then
        self:UpdateRoleIcon(frame)
    end

    -- Update threat
    if frame.ThreatIndicator then
        self:UpdateThreatIndicator(frame)
    end

    -- Update heal prediction
    if frame.HealPrediction then
        self:UpdateHealPrediction(frame)
    end

    -- Update range
    if frame.Range then
        self:UpdateRange(frame)
    end
end

--[[
    Event Handlers
]]
function UF.OnUnitEvent(frame, event, unit, ...)
    if unit and unit ~= frame.unit then return end

    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        UF:UpdateHealth(frame)
        UF:UpdateHealPrediction(frame)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        UF:UpdatePower(frame)
    elseif event == "UNIT_NAME_UPDATE" then
        UF:UpdateName(frame)
        UF:UpdatePortrait(frame)
    elseif event == "UNIT_AURA" then
        UF:UpdateAuras(frame, "HELPFUL")
        UF:UpdateAuras(frame, "HARMFUL")
    elseif event == "UNIT_LEVEL" then
        UF:UpdateLevel(frame)
    elseif event == "UNIT_FACTION" then
        UF:UpdateHealth(frame) -- Colors may change
    elseif event == "UNIT_CONNECTION" or event == "PARTY_MEMBER_ENABLE" or event == "PARTY_MEMBER_DISABLE" then
        UF:UpdateFrame(frame)
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" then
        UF:UpdateThreatIndicator(frame)
    elseif event == "PLAYER_ROLES_ASSIGNED" then
        UF:UpdateRoleIcon(frame)
    elseif event == "READY_CHECK" or event == "READY_CHECK_FINISHED" then
        UF:UpdateReadyCheck(frame)
    elseif event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" then
        UF:UpdateFrame(frame)
    end
end

function UF.OnUnitUpdate(frame, elapsed)
    -- Throttle updates
    frame.elapsed = (frame.elapsed or 0) + elapsed
    if frame.elapsed < 0.1 then return end
    frame.elapsed = 0

    -- Update range
    if frame.Range then
        UF:UpdateRange(frame)
    end
end

--[[
    Global Event Handlers
]]
function UF:PLAYER_ENTERING_WORLD()
    for unit, frame in pairs(self.frames) do
        self:UpdateFrame(frame)
    end
end

function UF:PLAYER_TARGET_CHANGED()
    if self.frames.target then
        self:UpdateFrame(self.frames.target)
    end
    if self.frames.targettarget then
        self:UpdateFrame(self.frames.targettarget)
    end
end

function UF:PLAYER_FOCUS_CHANGED()
    if self.frames.focus then
        self:UpdateFrame(self.frames.focus)
    end
    if self.frames.focustarget then
        self:UpdateFrame(self.frames.focustarget)
    end
end

function UF:UNIT_PET(event, unit)
    if unit == "player" and self.frames.pet then
        self:UpdateFrame(self.frames.pet)
    end
end

function UF:GROUP_ROSTER_UPDATE()
    -- Update party/raid frames
    for i = 1, 4 do
        local frame = self.frames["party" .. i]
        if frame then
            self:UpdateFrame(frame)
        end
    end
end

function UF:PLAYER_REGEN_ENABLED()
    -- Process any queued frame operations
end

--[[
    Disable Blizzard Frames
]]
function UF:DisableBlizzardFrames()
    -- Player frame
    if self.db.player.enabled then
        E:Kill(PlayerFrame)
    end

    -- Target frame
    if self.db.target.enabled then
        E:Kill(TargetFrame)
        E:Kill(ComboFrame)
    end

    -- Focus frame
    if self.db.focus.enabled then
        E:Kill(FocusFrame)
    end

    -- Party frames
    if self.db.party.enabled and not self.db.party.showInRaid then
        for i = 1, 4 do
            local frame = _G["PartyMemberFrame" .. i]
            if frame then
                E:Kill(frame)
            end
        end
    end

    -- Boss frames
    if self.db.boss.enabled then
        for i = 1, 5 do
            local frame = _G["Boss" .. i .. "TargetFrame"]
            if frame then
                E:Kill(frame)
            end
        end
    end

    -- Arena frames
    if self.db.arena.enabled then
        -- Arena frames are created dynamically
        if ArenaEnemyFrames then
            E:Kill(ArenaEnemyFrames)
        end
    end
end

--[[
    Element Registration
]]
function UF:RegisterElements()
    -- Elements are registered by their individual files
    self.elements = {}
end

function UF:RegisterElement(name, constructor)
    self.elements[name] = constructor
end

--[[
    Get Frame by Unit
]]
function UF:GetFrame(unit)
    return self.frames[unit]
end

--[[
    Profile Changed
]]
function UF:ProfileChanged()
    self.db = E.db.unitframes

    -- Recreate frames with new settings
    E:DelayUntilOutOfCombat(function()
        for unit, frame in pairs(self.frames) do
            if frame then
                -- Update frame with new config
                local config = self.db[unit] or self.db.player
                frame.config = config
                self:UpdateFrame(frame)
            end
        end
    end)
end

--[[
    Options
]]
function UF:GetOptions()
    return {
        type = "group",
        name = "Unit Frames",
        args = {
            enabled = {
                type = "toggle",
                name = "Enable",
                desc = "Enable the UnitFrames module",
                order = 1,
                get = function() return self.db.enabled end,
                set = function(_, v)
                    self.db.enabled = v
                    if v then
                        self:OnEnable()
                    else
                        self:OnDisable()
                    end
                end,
            },
            -- Add more options here
        },
    }
end
