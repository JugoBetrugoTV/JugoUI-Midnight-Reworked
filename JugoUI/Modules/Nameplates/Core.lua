--[[
    JugoUI - Nameplates/Core.lua
    Nameplate customization module
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local NP = E:NewModule("Nameplates", "AceEvent-3.0", "AceHook-3.0")
E.Nameplates = NP

NP.plates = {}
NP.activeNameplates = {}

function NP:OnInitialize()
    self.db = E.db.nameplates
end

function NP:OnEnable()
    -- Set nameplate CVars
    self:SetNameplateCVars()

    -- Hook nameplate creation
    self:RegisterEvent("NAME_PLATE_CREATED")
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

    -- Apply to existing nameplates
    for _, plate in pairs(C_NamePlate.GetNamePlates()) do
        self:OnNamePlateCreated(plate)
        local unit = plate.namePlateUnitToken
        if unit then
            self:OnNamePlateUnitAdded(nil, unit)
        end
    end
end

function NP:OnDisable()
    self:UnregisterAllEvents()
end

function NP:SetNameplateCVars()
    -- Use new 12.0 APIs if available
    if C_NamePlate.SetNamePlateEnemySize then
        C_NamePlate.SetNamePlateEnemySize(self.db.width, self.db.height)
    end
    if C_NamePlate.SetNamePlateFriendlySize then
        C_NamePlate.SetNamePlateFriendlySize(self.db.width, self.db.height)
    end

    SetCVar("nameplateShowFriendlyNPCs", self.db.showFriendly and "1" or "0")
    SetCVar("nameplateShowEnemyTotems", "1")
    SetCVar("nameplateShowEnemyGuardians", "1")
    SetCVar("nameplateShowEnemyPets", "1")
    SetCVar("nameplateShowEnemyMinions", "1")
    SetCVar("nameplateMotion", self.db.motionType == "STACKING" and "1" or "0")
    SetCVar("nameplateShowSelf", self.db.showSelf and "1" or "0")
end

function NP:NAME_PLATE_CREATED(_, plate)
    self:OnNamePlateCreated(plate)
end

function NP:NAME_PLATE_UNIT_ADDED(_, unit)
    self:OnNamePlateUnitAdded(nil, unit)
end

function NP:NAME_PLATE_UNIT_REMOVED(_, unit)
    self:OnNamePlateUnitRemoved(nil, unit)
end

function NP:OnNamePlateCreated(plate)
    if self.plates[plate] then return end

    local frame = CreateFrame("Frame", nil, plate)
    frame:SetAllPoints()
    frame:SetFrameStrata("BACKGROUND")

    -- Backdrop
    frame.backdrop = E:CreateBackdrop(frame, "Transparent")

    -- Health bar
    frame.Health = self:CreateHealthBar(frame)

    -- Castbar
    if self.db.castbar.enabled then
        frame.Castbar = self:CreateCastbar(frame)
    end

    -- Auras
    if self.db.auras.enabled then
        frame.Auras = self:CreateAuras(frame)
    end

    -- Name text
    frame.Name = E:CreateFontString(frame.Health, 10, "OUTLINE")
    frame.Name:SetPoint("BOTTOM", frame.Health, "TOP", 0, 3)

    -- Level text
    frame.Level = E:CreateFontString(frame, 9, "OUTLINE")
    frame.Level:SetPoint("RIGHT", frame.Health, "LEFT", -3, 0)

    -- Raid icon
    frame.RaidIcon = frame:CreateTexture(nil, "OVERLAY")
    frame.RaidIcon:SetSize(16, 16)
    frame.RaidIcon:SetPoint("BOTTOM", frame.Name, "TOP", 0, 2)
    frame.RaidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    frame.RaidIcon:Hide()

    -- Target indicator
    frame.TargetIndicator = self:CreateTargetIndicator(frame)

    -- Store reference
    frame.plate = plate
    self.plates[plate] = frame

    -- Hide default elements
    self:HideDefaultElements(plate)
end

function NP:OnNamePlateUnitAdded(_, unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if not plate then return end

    local frame = self.plates[plate]
    if not frame then return end

    frame.unit = unit
    frame:Show()

    self.activeNameplates[unit] = frame

    -- Update all elements
    self:UpdateNameplate(frame)

    -- Register for updates
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:RegisterEvent("UNIT_NAME_UPDATE")
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("UNIT_LEVEL")
    frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("RAID_TARGET_UPDATE")

    frame:SetScript("OnEvent", function(self, event, eventUnit, ...)
        if event == "PLAYER_TARGET_CHANGED" or event == "RAID_TARGET_UPDATE" then
            NP:UpdateNameplate(frame)
        elseif eventUnit == unit then
            NP:UpdateNameplate(frame)
        end
    end)
end

function NP:OnNamePlateUnitRemoved(_, unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if not plate then return end

    local frame = self.plates[plate]
    if not frame then return end

    frame.unit = nil
    frame:UnregisterAllEvents()
    frame:Hide()

    self.activeNameplates[unit] = nil
end

function NP:UpdateNameplate(frame)
    if not frame or not frame.unit then return end

    local unit = frame.unit

    -- Update health
    self:UpdateHealth(frame)

    -- Update name
    self:UpdateName(frame)

    -- Update level
    self:UpdateLevel(frame)

    -- Update castbar
    if frame.Castbar then
        self:UpdateCastbar(frame)
    end

    -- Update auras
    if frame.Auras then
        self:UpdateAuras(frame)
    end

    -- Update raid icon
    self:UpdateRaidIcon(frame)

    -- Update target indicator
    self:UpdateTargetIndicator(frame)

    -- Update threat
    self:UpdateThreat(frame)
end

function NP:CreateHealthBar(parent)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(self.db.width, self.db.height)
    bar:SetPoint("CENTER", parent, "CENTER", 0, 0)
    bar:SetStatusBarTexture(E.media.textures.flat)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetTexture(E.media.textures.flat)
    bar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    if self.db.healthText then
        bar.text = E:CreateFontString(bar, 9, "OUTLINE")
        bar.text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    end

    return bar
end

function NP:UpdateHealth(frame)
    local unit = frame.unit
    local health, maxHealth, isSecret = E.API:GetUnitHealth(unit)

    if isSecret then
        frame.Health:SetMinMaxValues(0, 1)
        local percent = E.API:GetUnitHealthPercent(unit)
        if not E:IsSecretValue(percent) then
            frame.Health:SetValue(percent / 100)
        end
    else
        frame.Health:SetMinMaxValues(0, maxHealth)
        frame.Health:SetValue(health)
    end

    -- Color
    self:UpdateHealthColor(frame)

    -- Text
    if frame.Health.text then
        if isSecret then
            frame.Health.text:SetText("")
        else
            local percent = (health / maxHealth) * 100
            if self.db.healthTextFormat == "PERCENT" then
                frame.Health.text:SetText(format("%.0f%%", percent))
            else
                frame.Health.text:SetText(E:ShortValue(health))
            end
        end
    end
end

function NP:UpdateHealthColor(frame)
    local unit = frame.unit

    if UnitIsTapDenied(unit) then
        frame.Health:SetStatusBarColor(0.55, 0.55, 0.55)
        return
    end

    if self.db.healthColor == "CLASS" and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class then
            local r, g, b = E:GetClassColor(class)
            frame.Health:SetStatusBarColor(r, g, b)
            return
        end
    end

    local reaction = UnitReaction(unit, "player")
    if reaction then
        local color = E.media.colors.reaction[reaction]
        if color then
            frame.Health:SetStatusBarColor(color[1], color[2], color[3])
            return
        end
    end

    frame.Health:SetStatusBarColor(0.5, 0.5, 0.5)
end

function NP:UpdateName(frame)
    local unit = frame.unit
    local name = UnitName(unit)

    if E:IsSecretValue(name) then
        frame.Name:SetText("|cff888888???|r")
    else
        frame.Name:SetText(name or "")
    end
end

function NP:UpdateLevel(frame)
    local unit = frame.unit
    local level = UnitLevel(unit)

    if level == -1 then
        frame.Level:SetText("|cffff0000??|r")
    else
        local color = GetCreatureDifficultyColor(level)
        frame.Level:SetFormattedText("|cff%02x%02x%02x%d|r", color.r * 255, color.g * 255, color.b * 255, level)
    end
end

function NP:UpdateRaidIcon(frame)
    local unit = frame.unit
    local index = GetRaidTargetIndex(unit)

    if index then
        SetRaidTargetIconTexture(frame.RaidIcon, index)
        frame.RaidIcon:Show()
    else
        frame.RaidIcon:Hide()
    end
end

function NP:CreateTargetIndicator(parent)
    local indicator = CreateFrame("Frame", nil, parent)
    indicator:SetSize(20, 20)
    indicator:SetPoint("LEFT", parent.Health, "RIGHT", 5, 0)

    indicator.arrow = indicator:CreateTexture(nil, "OVERLAY")
    indicator.arrow:SetAllPoints()
    indicator.arrow:SetTexture("Interface\\BUTTONS\\Arrow-Down-Up")
    indicator.arrow:SetRotation(math.pi / 2)
    indicator.arrow:SetVertexColor(1, 1, 0)

    indicator:Hide()

    return indicator
end

function NP:UpdateTargetIndicator(frame)
    local unit = frame.unit
    if UnitIsUnit(unit, "target") then
        frame.TargetIndicator:Show()
    else
        frame.TargetIndicator:Hide()
    end
end

function NP:UpdateThreat(frame)
    local unit = frame.unit
    local status = UnitThreatSituation("player", unit)

    if status and status > 0 and self.db.threat.enabled then
        local color = E.media.colors.threat[status]
        if color then
            if self.db.threat.style == "GLOW" then
                if not frame.threatGlow then
                    frame.threatGlow = E:CreateShadow(frame.Health, 4, color[1], color[2], color[3], 0.8)
                end
                frame.threatGlow:SetBackdropBorderColor(color[1], color[2], color[3], 0.8)
                frame.threatGlow:Show()
            else
                frame.Health:SetStatusBarColor(color[1], color[2], color[3])
            end
        end
    else
        if frame.threatGlow then
            frame.threatGlow:Hide()
        end
    end
end

function NP:HideDefaultElements(plate)
    -- Hide Blizzard elements
    if plate.UnitFrame then
        plate.UnitFrame:Hide()
        plate.UnitFrame:UnregisterAllEvents()
    end
end

function NP:ProfileChanged()
    self.db = E.db.nameplates
    self:SetNameplateCVars()

    for unit, frame in pairs(self.activeNameplates) do
        self:UpdateNameplate(frame)
    end
end
