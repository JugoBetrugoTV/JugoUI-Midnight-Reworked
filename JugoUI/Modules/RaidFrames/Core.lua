--[[
    JugoUI - RaidFrames/Core.lua
    Raid frame module
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local RF = E:NewModule("RaidFrames", "AceEvent-3.0")
E.RaidFrames = RF

RF.frames = {}
RF.groups = {}

function RF:OnInitialize()
    self.db = E.db.raidframes
end

function RF:OnEnable()
    self:CreateRaidFrames()

    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("UNIT_MAXHEALTH")
    self:RegisterEvent("UNIT_POWER_UPDATE")
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("READY_CHECK")
    self:RegisterEvent("READY_CHECK_FINISHED")
    self:RegisterEvent("UNIT_CONNECTION")

    -- Hide Blizzard raid frames
    self:HideBlizzardRaidFrames()
end

function RF:HideBlizzardRaidFrames()
    if CompactRaidFrameManager then
        CompactRaidFrameManager:UnregisterAllEvents()
        CompactRaidFrameManager:Hide()
    end
    if CompactRaidFrameContainer then
        CompactRaidFrameContainer:UnregisterAllEvents()
        CompactRaidFrameContainer:Hide()
    end
end

function RF:CreateRaidFrames()
    local db = self.db

    if InCombatLockdown() then
        E:DelayUntilOutOfCombat(function()
            self:CreateRaidFrames()
        end)
        return
    end

    -- Create header container
    local container = CreateFrame("Frame", "JugoUI_RaidFrames", UIParent)
    container:SetSize(db.width * db.groupsPerRow + db.horizontalSpacing * (db.groupsPerRow - 1), db.height * 8 + db.verticalSpacing * 7)

    local point = db.point
    container:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)

    container:SetMovable(true)
    container:EnableMouse(true)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart", function(self) self:StartMoving() end)
    container:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    self.container = container

    -- Create frames for up to 40 raid members
    for i = 1, 40 do
        self:CreateRaidUnitFrame(i)
    end

    self:UpdateVisibility()
end

function RF:CreateRaidUnitFrame(index)
    local db = self.db
    local unit = "raid" .. index
    local name = "JugoUI_Raid" .. index

    local frame = CreateFrame("Button", name, self.container, "SecureUnitButtonTemplate")
    frame:SetSize(db.width, db.height)
    frame:SetAttribute("unit", unit)
    frame:SetAttribute("*type1", "target")
    frame:SetAttribute("*type2", "togglemenu")
    frame:RegisterForClicks("AnyUp")

    RegisterUnitWatch(frame)

    -- Backdrop
    frame.backdrop = E:CreateBackdrop(frame, "Transparent")

    -- Health bar
    frame.Health = CreateFrame("StatusBar", nil, frame)
    frame.Health:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.Health:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, db.showPower and db.height * db.powerHeight + 1 or 1)
    frame.Health:SetStatusBarTexture(E.media.textures.flat)
    frame.Health:SetMinMaxValues(0, 1)
    frame.Health:SetValue(1)

    frame.Health.bg = frame.Health:CreateTexture(nil, "BACKGROUND")
    frame.Health.bg:SetAllPoints()
    frame.Health.bg:SetTexture(E.media.textures.flat)
    frame.Health.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    -- Power bar
    if db.showPower then
        frame.Power = CreateFrame("StatusBar", nil, frame)
        frame.Power:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
        frame.Power:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        frame.Power:SetHeight(db.height * db.powerHeight)
        frame.Power:SetStatusBarTexture(E.media.textures.flat)
        frame.Power:SetMinMaxValues(0, 1)

        frame.Power.bg = frame.Power:CreateTexture(nil, "BACKGROUND")
        frame.Power.bg:SetAllPoints()
        frame.Power.bg:SetTexture(E.media.textures.flat)
        frame.Power.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    end

    -- Name
    if db.showName then
        frame.Name = E:CreateFontString(frame.Health, 10, "OUTLINE")
        frame.Name:SetPoint("CENTER", frame.Health, "CENTER", 0, 0)
        frame.Name:SetWidth(db.width - 4)
        frame.Name:SetWordWrap(false)
    end

    -- Role icon
    if db.showRoleIcon then
        frame.RoleIcon = frame:CreateTexture(nil, "OVERLAY")
        frame.RoleIcon:SetSize(12, 12)
        frame.RoleIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    end

    -- Raid icon
    if db.showRaidIcon then
        frame.RaidIcon = frame:CreateTexture(nil, "OVERLAY")
        frame.RaidIcon:SetSize(14, 14)
        frame.RaidIcon:SetPoint("TOP", frame, "TOP", 0, 5)
        frame.RaidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    end

    -- Ready check
    if db.showReadyCheck then
        frame.ReadyCheck = frame:CreateTexture(nil, "OVERLAY")
        frame.ReadyCheck:SetSize(16, 16)
        frame.ReadyCheck:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame.ReadyCheck:Hide()
    end

    -- Resurrect
    if db.showResurrect then
        frame.Resurrect = frame:CreateTexture(nil, "OVERLAY")
        frame.Resurrect:SetSize(20, 20)
        frame.Resurrect:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame.Resurrect:SetTexture("Interface\\RaidFrame\\Raid-Icon-Rez")
        frame.Resurrect:Hide()
    end

    -- Threat border
    if db.threatBorder then
        frame.Threat = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.Threat:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
        frame.Threat:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
        frame.Threat:SetBackdrop({edgeFile = E.media.textures.glowBorder, edgeSize = 3})
        frame.Threat:Hide()
    end

    frame.unit = unit
    frame.index = index
    self.frames[index] = frame

    frame:Hide()
end

function RF:UpdateVisibility()
    local db = self.db

    if not IsInRaid() then
        for i, frame in ipairs(self.frames) do
            frame:Hide()
        end
        return
    end

    local numMembers = GetNumGroupMembers()

    for i = 1, 40 do
        local frame = self.frames[i]
        if i <= numMembers then
            self:PositionFrame(frame, i)
            frame:Show()
            self:UpdateFrame(frame)
        else
            frame:Hide()
        end
    end
end

function RF:PositionFrame(frame, index)
    local db = self.db
    local groupsPerRow = db.groupsPerRow
    local width = db.width
    local height = db.height
    local hSpacing = db.horizontalSpacing
    local vSpacing = db.verticalSpacing

    -- Calculate position based on growth direction
    local group = ceil(index / 5)
    local groupIndex = ((index - 1) % 5) + 1

    local groupCol = ((group - 1) % groupsPerRow)
    local groupRow = floor((group - 1) / groupsPerRow)

    local x = groupCol * (width + hSpacing)
    local y = -(groupRow * 5 + groupIndex - 1) * (height + vSpacing)

    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", self.container, "TOPLEFT", x, y)
end

function RF:UpdateFrame(frame)
    if not frame or not frame.unit then return end

    local unit = frame.unit
    if not UnitExists(unit) then return end

    -- Update health
    self:UpdateHealth(frame)

    -- Update power
    if frame.Power then
        self:UpdatePower(frame)
    end

    -- Update name
    if frame.Name then
        self:UpdateName(frame)
    end

    -- Update role icon
    if frame.RoleIcon then
        self:UpdateRoleIcon(frame)
    end

    -- Update raid icon
    if frame.RaidIcon then
        self:UpdateRaidIcon(frame)
    end

    -- Update threat
    if frame.Threat then
        self:UpdateThreat(frame)
    end

    -- Update range
    self:UpdateRange(frame)
end

function RF:UpdateHealth(frame)
    local unit = frame.unit
    local db = self.db

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
    if not UnitIsConnected(unit) then
        frame.Health:SetStatusBarColor(0.5, 0.5, 0.5)
    elseif UnitIsDead(unit) or UnitIsGhost(unit) then
        frame.Health:SetStatusBarColor(0.4, 0.4, 0.4)
    elseif db.healthColor == "CLASS" and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class then
            local r, g, b = E:GetClassColor(class)
            frame.Health:SetStatusBarColor(r, g, b)
        end
    else
        frame.Health:SetStatusBarColor(0.3, 0.3, 0.3)
    end
end

function RF:UpdatePower(frame)
    local unit = frame.unit
    local powerType, powerToken = UnitPowerType(unit)
    local power, powerMax = E.API:GetUnitPower(unit, powerType)

    if powerMax > 0 then
        frame.Power:SetMinMaxValues(0, powerMax)
        frame.Power:SetValue(power)

        local color = E.media.colors.power[powerToken] or E.media.colors.power.MANA
        frame.Power:SetStatusBarColor(color[1], color[2], color[3])
    end
end

function RF:UpdateName(frame)
    local unit = frame.unit
    local name = UnitName(unit)
    local db = self.db

    if name then
        if #name > db.nameLength then
            name = strsub(name, 1, db.nameLength)
        end
        frame.Name:SetText(name)
    else
        frame.Name:SetText("")
    end
end

function RF:UpdateRoleIcon(frame)
    local unit = frame.unit
    local role = UnitGroupRolesAssigned(unit)

    if role == "TANK" then
        frame.RoleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        frame.RoleIcon:SetTexCoord(0, 0.296875, 0.328125, 0.625)
        frame.RoleIcon:Show()
    elseif role == "HEALER" then
        frame.RoleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        frame.RoleIcon:SetTexCoord(0.296875, 0.59375, 0.328125, 0.625)
        frame.RoleIcon:Show()
    else
        frame.RoleIcon:Hide()
    end
end

function RF:UpdateRaidIcon(frame)
    local unit = frame.unit
    local index = GetRaidTargetIndex(unit)

    if index then
        SetRaidTargetIconTexture(frame.RaidIcon, index)
        frame.RaidIcon:Show()
    else
        frame.RaidIcon:Hide()
    end
end

function RF:UpdateThreat(frame)
    local unit = frame.unit
    local status = UnitThreatSituation(unit)

    if status and status > 0 then
        local color = E.media.colors.threat[status]
        if color then
            frame.Threat:SetBackdropBorderColor(color[1], color[2], color[3], 0.8)
            frame.Threat:Show()
        end
    else
        frame.Threat:Hide()
    end
end

function RF:UpdateRange(frame)
    local db = self.db
    local unit = frame.unit

    if not db.rangeCheck then return end

    local inRange = UnitInRange(unit)
    if inRange == nil then inRange = true end

    if inRange then
        frame:SetAlpha(1)
    else
        frame:SetAlpha(db.rangeAlpha)
    end
end

function RF:GROUP_ROSTER_UPDATE()
    self:UpdateVisibility()
end

function RF:PLAYER_ENTERING_WORLD()
    self:UpdateVisibility()
end

function RF:UNIT_HEALTH(event, unit)
    if unit:match("^raid%d+$") then
        local index = tonumber(unit:match("%d+"))
        if self.frames[index] then
            self:UpdateHealth(self.frames[index])
        end
    end
end

function RF:UNIT_MAXHEALTH(event, unit)
    self:UNIT_HEALTH(event, unit)
end

function RF:UNIT_POWER_UPDATE(event, unit)
    if unit:match("^raid%d+$") then
        local index = tonumber(unit:match("%d+"))
        if self.frames[index] and self.frames[index].Power then
            self:UpdatePower(self.frames[index])
        end
    end
end

function RF:UNIT_AURA(event, unit)
    -- Future: Update debuff display
end

function RF:READY_CHECK()
    for i, frame in ipairs(self.frames) do
        if frame.ReadyCheck and UnitExists(frame.unit) then
            local status = GetReadyCheckStatus(frame.unit)
            if status then
                if status == "ready" then
                    frame.ReadyCheck:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
                elseif status == "notready" then
                    frame.ReadyCheck:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
                else
                    frame.ReadyCheck:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
                end
                frame.ReadyCheck:Show()
            end
        end
    end
end

function RF:READY_CHECK_FINISHED()
    for i, frame in ipairs(self.frames) do
        if frame.ReadyCheck then
            frame.ReadyCheck:Hide()
        end
    end
end

function RF:UNIT_CONNECTION(event, unit)
    if unit:match("^raid%d+$") then
        local index = tonumber(unit:match("%d+"))
        if self.frames[index] then
            self:UpdateFrame(self.frames[index])
        end
    end
end

function RF:ProfileChanged()
    self.db = E.db.raidframes
end
