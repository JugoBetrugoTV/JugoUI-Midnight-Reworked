--[[
    JugoUI - XPRepBar/Core.lua
    Experience/Reputation bar module
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local XP = E:NewModule("XPRepBar", "AceEvent-3.0")
E.XPRepBar = XP

function XP:OnInitialize()
    self.db = E.db.xprepbar
end

function XP:OnEnable()
    self:CreateBar()
    self:RegisterEvent("PLAYER_XP_UPDATE")
    self:RegisterEvent("PLAYER_LEVEL_UP")
    self:RegisterEvent("UPDATE_EXHAUSTION")
    self:RegisterEvent("UPDATE_FACTION")
    self:RegisterEvent("HONOR_XP_UPDATE")
end

function XP:CreateBar()
    local db = self.db
    local frame = CreateFrame("Frame", "JugoUI_XPRepBar", UIParent, "BackdropTemplate")
    frame:SetSize(db.width, db.height)

    local point = db.point
    frame:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)

    frame:SetBackdrop({
        bgFile = E.media.textures.flat,
        edgeFile = E.media.textures.flat,
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.03, 0.03, 0.03, 0.8)
    frame:SetBackdropBorderColor(0.1, 0.1, 0.1)

    -- XP bar
    frame.xp = CreateFrame("StatusBar", nil, frame)
    frame.xp:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.xp:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    frame.xp:SetStatusBarTexture(E.media.textures.flat)
    frame.xp:SetStatusBarColor(unpack(E.media.colors.experience.xp))
    frame.xp:SetMinMaxValues(0, 1)

    -- Rested XP overlay
    frame.rested = CreateFrame("StatusBar", nil, frame)
    frame.rested:SetPoint("TOPLEFT", frame.xp:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
    frame.rested:SetPoint("BOTTOMLEFT", frame.xp:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
    frame.rested:SetStatusBarTexture(E.media.textures.flat)
    frame.rested:SetStatusBarColor(unpack(E.media.colors.experience.rested))
    frame.rested:SetMinMaxValues(0, 1)

    -- Rep bar (hidden by default)
    frame.rep = CreateFrame("StatusBar", nil, frame)
    frame.rep:SetAllPoints(frame.xp)
    frame.rep:SetStatusBarTexture(E.media.textures.flat)
    frame.rep:SetMinMaxValues(0, 1)
    frame.rep:Hide()

    -- Text
    frame.text = E:CreateFontString(frame, 10, "OUTLINE")
    frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)

    -- Tooltip
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        XP:ShowTooltip()
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Click to toggle XP/Rep
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            XP:ToggleMode()
        end
    end)

    self.bar = frame
    self.mode = "XP"

    self:UpdateBar()
end

function XP:UpdateBar()
    if not self.bar then return end
    local db = self.db

    if self.mode == "XP" then
        self:UpdateXP()
    elseif self.mode == "REP" then
        self:UpdateRep()
    elseif self.mode == "HONOR" then
        self:UpdateHonor()
    end
end

function XP:UpdateXP()
    local bar = self.bar
    local db = self.db

    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local exhaustion = GetXPExhaustion() or 0
    local level = UnitLevel("player")

    bar.xp:Show()
    bar.rep:Hide()

    if level >= GetMaxLevelForPlayerExpansion() then
        bar.xp:SetValue(1)
        bar.rested:SetValue(0)
        bar.text:SetText("Max Level")
        return
    end

    local percent = currentXP / maxXP
    bar.xp:SetMinMaxValues(0, maxXP)
    bar.xp:SetValue(currentXP)
    bar.xp:SetStatusBarColor(unpack(E.media.colors.experience.xp))

    -- Rested
    if exhaustion > 0 and db.showRested then
        local restedPercent = min(exhaustion, maxXP - currentXP) / maxXP
        bar.rested:SetWidth(bar.xp:GetWidth() * restedPercent)
        bar.rested:SetMinMaxValues(0, 1)
        bar.rested:SetValue(1)
        bar.rested:Show()
    else
        bar.rested:Hide()
    end

    if db.showText then
        if db.textFormat == "PERCENT" then
            bar.text:SetFormattedText("%.1f%%", percent * 100)
        else
            bar.text:SetFormattedText("%s / %s", E:ShortValue(currentXP), E:ShortValue(maxXP))
        end
    else
        bar.text:SetText("")
    end
end

function XP:UpdateRep()
    local bar = self.bar
    local db = self.db

    local name, standing, min, max, value = GetWatchedFactionInfo()

    bar.xp:Hide()
    bar.rested:Hide()
    bar.rep:Show()

    if name then
        local color = E.media.colors.reputation[standing] or {0.5, 0.5, 0.5}
        bar.rep:SetStatusBarColor(unpack(color))
        bar.rep:SetMinMaxValues(min, max)
        bar.rep:SetValue(value)

        local percent = (value - min) / (max - min)
        if db.showText then
            if db.textFormat == "PERCENT" then
                bar.text:SetFormattedText("%s: %.1f%%", name, percent * 100)
            else
                bar.text:SetFormattedText("%s: %s / %s", name, E:ShortValue(value - min), E:ShortValue(max - min))
            end
        end
    else
        bar.rep:SetValue(0)
        bar.text:SetText("No Faction")
    end
end

function XP:UpdateHonor()
    local bar = self.bar
    local db = self.db

    local current = UnitHonor("player")
    local max = UnitHonorMax("player")
    local level = UnitHonorLevel("player")

    bar.xp:Show()
    bar.rep:Hide()
    bar.rested:Hide()

    bar.xp:SetStatusBarColor(1.0, 0.24, 0.24)
    bar.xp:SetMinMaxValues(0, max)
    bar.xp:SetValue(current)

    local percent = max > 0 and (current / max) or 0
    if db.showText then
        bar.text:SetFormattedText("Honor %d: %.1f%%", level, percent * 100)
    end
end

function XP:ToggleMode()
    if self.mode == "XP" then
        self.mode = "REP"
    elseif self.mode == "REP" then
        self.mode = "HONOR"
    else
        self.mode = "XP"
    end
    self:UpdateBar()
end

function XP:ShowTooltip()
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local exhaustion = GetXPExhaustion() or 0
    local level = UnitLevel("player")

    GameTooltip:AddLine("Experience", 1, 1, 1)
    GameTooltip:AddDoubleLine("Current:", format("%s / %s (%.1f%%)", E:CommaValue(currentXP), E:CommaValue(maxXP), (currentXP / maxXP) * 100), 1, 1, 1, 0.8, 0.8, 0.8)
    GameTooltip:AddDoubleLine("Remaining:", E:CommaValue(maxXP - currentXP), 1, 1, 1, 0.8, 0.8, 0.8)
    if exhaustion > 0 then
        GameTooltip:AddDoubleLine("Rested:", format("%s (%.1f%%)", E:CommaValue(exhaustion), (exhaustion / maxXP) * 100), 0.3, 0.5, 0.9, 0.8, 0.8, 0.8)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Right-click to cycle modes", 0.7, 0.7, 0.7)
end

function XP:PLAYER_XP_UPDATE()
    self:UpdateBar()
end

function XP:PLAYER_LEVEL_UP()
    self:UpdateBar()
end

function XP:UPDATE_EXHAUSTION()
    self:UpdateBar()
end

function XP:UPDATE_FACTION()
    if self.mode == "REP" then
        self:UpdateBar()
    end
end

function XP:HONOR_XP_UPDATE()
    if self.mode == "HONOR" then
        self:UpdateBar()
    end
end

function XP:ProfileChanged()
    self.db = E.db.xprepbar
end
