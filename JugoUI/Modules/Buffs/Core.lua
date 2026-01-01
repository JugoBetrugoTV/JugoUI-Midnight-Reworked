--[[
    JugoUI - Buffs/Core.lua
    Buff/Debuff frame replacement
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local BF = E:NewModule("Buffs", "AceEvent-3.0")
E.Buffs = BF

BF.BuffFrame = nil
BF.DebuffFrame = nil

function BF:OnInitialize()
    self.db = E.db.buffs
end

function BF:OnEnable()
    self:HideBlizzardBuffs()
    self:CreateBuffFrame()
    self:CreateDebuffFrame()

    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function BF:HideBlizzardBuffs()
    if BuffFrame then
        BuffFrame:UnregisterAllEvents()
        BuffFrame:Hide()
    end
    if DebuffFrame then
        DebuffFrame:UnregisterAllEvents()
        DebuffFrame:Hide()
    end
end

function BF:CreateBuffFrame()
    local db = self.db
    local frame = CreateFrame("Frame", "JugoUI_BuffFrame", UIParent)

    local width = db.buffSize * db.buffsPerRow + db.buffSpacing * (db.buffsPerRow - 1)
    local height = db.buffSize * 3 + db.buffSpacing * 2

    frame:SetSize(width, height)

    local point = db.buffPoint
    frame:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)

    frame.buttons = {}
    self.BuffFrame = frame
end

function BF:CreateDebuffFrame()
    local db = self.db
    local frame = CreateFrame("Frame", "JugoUI_DebuffFrame", UIParent)

    local width = db.debuffSize * db.debuffsPerRow + db.debuffSpacing * (db.debuffsPerRow - 1)
    local height = db.debuffSize * 2 + db.debuffSpacing

    frame:SetSize(width, height)

    local point = db.debuffPoint
    frame:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)

    frame.buttons = {}
    self.DebuffFrame = frame
end

function BF:CreateAuraButton(parent, index, size, isDebuff)
    local button = CreateFrame("Frame", nil, parent)
    button:SetSize(size, size)

    -- Icon
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 1, -1)
    button.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Border
    button.border = E:CreateBackdrop(button, "Default")

    -- Cooldown
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button.icon)
    button.cooldown:SetReverse(true)
    button.cooldown:SetHideCountdownNumbers(false)

    -- Count
    button.count = E:CreateFontString(button, 11, "OUTLINE")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)

    -- Duration
    if self.db.showBuffDuration or self.db.showDebuffDuration then
        button.duration = E:CreateFontString(button, 10, "OUTLINE")
        button.duration:SetPoint("TOP", button, "BOTTOM", 0, -2)
    end

    -- Tooltip
    button:EnableMouse(true)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        if self.auraData then
            GameTooltip:SetUnitAura("player", self.auraIndex, self.filter)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Right-click to cancel (buffs only)
    if not isDebuff then
        button:SetScript("OnMouseUp", function(self, btn)
            if btn == "RightButton" and self.auraIndex then
                CancelUnitBuff("player", self.auraIndex)
            end
        end)
    end

    button:Hide()
    return button
end

function BF:UpdateAuras()
    self:UpdateBuffs()
    self:UpdateDebuffs()
end

function BF:UpdateBuffs()
    local db = self.db
    local frame = self.BuffFrame
    if not frame then return end

    -- Hide all existing buttons
    for i, button in ipairs(frame.buttons) do
        button:Hide()
    end

    local index = 1
    for i = 1, 40 do
        local auraData = E.API:GetAuraDataByIndex("player", i, "HELPFUL")
        if not auraData then break end

        local button = frame.buttons[index]
        if not button then
            button = self:CreateAuraButton(frame, index, db.buffSize, false)
            frame.buttons[index] = button
        end

        self:SetupButton(button, auraData, i, "HELPFUL", index)
        index = index + 1
    end
end

function BF:UpdateDebuffs()
    local db = self.db
    local frame = self.DebuffFrame
    if not frame then return end

    for i, button in ipairs(frame.buttons) do
        button:Hide()
    end

    local index = 1
    for i = 1, 40 do
        local auraData = E.API:GetAuraDataByIndex("player", i, "HARMFUL")
        if not auraData then break end

        local button = frame.buttons[index]
        if not button then
            button = self:CreateAuraButton(frame, index, db.debuffSize, true)
            frame.buttons[index] = button
        end

        self:SetupButton(button, auraData, i, "HARMFUL", index)
        index = index + 1
    end
end

function BF:SetupButton(button, auraData, auraIndex, filter, displayIndex)
    local db = self.db
    local size = filter == "HELPFUL" and db.buffSize or db.debuffSize
    local perRow = filter == "HELPFUL" and db.buffsPerRow or db.debuffsPerRow
    local spacing = filter == "HELPFUL" and db.buffSpacing or db.debuffSpacing
    local growthX = filter == "HELPFUL" and db.buffGrowthX or db.debuffGrowthX
    local growthY = filter == "HELPFUL" and db.buffGrowthY or db.debuffGrowthY

    button.auraData = auraData
    button.auraIndex = auraIndex
    button.filter = filter

    -- Position
    local row = floor((displayIndex - 1) / perRow)
    local col = (displayIndex - 1) % perRow

    local xMult = growthX == "LEFT" and -1 or 1
    local yMult = growthY == "DOWN" and -1 or 1

    local x = col * (size + spacing) * xMult
    local y = row * (size + spacing) * yMult

    button:ClearAllPoints()
    local parent = filter == "HELPFUL" and self.BuffFrame or self.DebuffFrame
    local anchor = growthX == "LEFT" and "TOPRIGHT" or "TOPLEFT"
    button:SetPoint(anchor, parent, anchor, x, y)

    -- Icon
    button.icon:SetTexture(auraData.icon)

    -- Count
    if auraData.applications and auraData.applications > 1 then
        button.count:SetText(auraData.applications)
    else
        button.count:SetText("")
    end

    -- Cooldown
    if auraData.duration and auraData.duration > 0 then
        E.API:SetCooldownFromExpiration(button.cooldown, auraData.expirationTime, auraData.duration, true)
    else
        button.cooldown:Clear()
    end

    -- Border color for debuffs
    if filter == "HARMFUL" and db.colorByType and auraData.dispelName then
        local color = E.media.colors.debuffType[auraData.dispelName]
        if color then
            button.border:SetBackdropBorderColor(color[1], color[2], color[3])
        else
            button.border:SetBackdropBorderColor(0.8, 0, 0)
        end
    else
        button.border:SetBackdropBorderColor(0.2, 0.2, 0.2)
    end

    button:Show()
end

function BF:UNIT_AURA(event, unit)
    if unit == "player" then
        self:UpdateAuras()
    end
end

function BF:PLAYER_ENTERING_WORLD()
    self:UpdateAuras()
end

function BF:ProfileChanged()
    self.db = E.db.buffs
end
