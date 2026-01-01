--[[
    JugoUI - UnitFrames/Elements/HealPrediction.lua
    Heal prediction overlay element
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateHealPrediction(frame)
    if not frame.Health then return nil end

    local hp = {}

    -- My heals
    hp.myBar = CreateFrame("StatusBar", nil, frame.Health)
    hp.myBar:SetPoint("TOPLEFT", frame.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
    hp.myBar:SetPoint("BOTTOMLEFT", frame.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
    hp.myBar:SetWidth(frame.Health:GetWidth())
    hp.myBar:SetStatusBarTexture(E.media.textures.flat)
    hp.myBar:SetStatusBarColor(0.3, 0.8, 0.3, 0.6)
    hp.myBar:SetMinMaxValues(0, 1)
    hp.myBar:SetValue(0)

    -- Other heals
    hp.otherBar = CreateFrame("StatusBar", nil, frame.Health)
    hp.otherBar:SetPoint("TOPLEFT", hp.myBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
    hp.otherBar:SetPoint("BOTTOMLEFT", hp.myBar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
    hp.otherBar:SetWidth(frame.Health:GetWidth())
    hp.otherBar:SetStatusBarTexture(E.media.textures.flat)
    hp.otherBar:SetStatusBarColor(0.3, 0.8, 0.3, 0.4)
    hp.otherBar:SetMinMaxValues(0, 1)
    hp.otherBar:SetValue(0)

    -- Absorbs
    hp.absorbBar = CreateFrame("StatusBar", nil, frame.Health)
    hp.absorbBar:SetPoint("TOPLEFT", hp.otherBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
    hp.absorbBar:SetPoint("BOTTOMLEFT", hp.otherBar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
    hp.absorbBar:SetWidth(frame.Health:GetWidth())
    hp.absorbBar:SetStatusBarTexture(E.media.textures.flat)
    hp.absorbBar:SetStatusBarColor(0.3, 0.6, 0.8, 0.6)
    hp.absorbBar:SetMinMaxValues(0, 1)
    hp.absorbBar:SetValue(0)

    -- Heal absorb (negative healing)
    hp.healAbsorbBar = CreateFrame("StatusBar", nil, frame.Health)
    hp.healAbsorbBar:SetPoint("TOPRIGHT", frame.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
    hp.healAbsorbBar:SetPoint("BOTTOMRIGHT", frame.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
    hp.healAbsorbBar:SetWidth(frame.Health:GetWidth())
    hp.healAbsorbBar:SetStatusBarTexture(E.media.textures.flat)
    hp.healAbsorbBar:SetStatusBarColor(0.8, 0.3, 0.3, 0.6)
    hp.healAbsorbBar:SetMinMaxValues(0, 1)
    hp.healAbsorbBar:SetValue(0)
    hp.healAbsorbBar:SetReverseFill(true)

    return hp
end

function UF:UpdateHealPrediction(frame)
    if not frame or not frame.HealPrediction then return end

    local unit = frame.unit
    if not UnitExists(unit) then return end

    local hp = frame.HealPrediction
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)

    if E:IsSecretValue(health) or E:IsSecretValue(maxHealth) then
        -- Can't show heal prediction with secret values
        hp.myBar:SetValue(0)
        hp.otherBar:SetValue(0)
        hp.absorbBar:SetValue(0)
        hp.healAbsorbBar:SetValue(0)
        return
    end

    if maxHealth <= 0 then return end

    -- Get prediction data using 12.0 API
    local prediction = E.API:GetHealPrediction(unit)

    -- Calculate bar values
    local myIncoming = UnitGetIncomingHeals(unit, "player") or 0
    local allIncoming = prediction.incomingHeal or (UnitGetIncomingHeals(unit) or 0)
    local otherIncoming = allIncoming - myIncoming
    local absorb = prediction.absorb or (UnitGetTotalAbsorbs(unit) or 0)
    local healAbsorb = prediction.healAbsorb or (UnitGetTotalHealAbsorbs(unit) or 0)

    -- Width of health bar
    local barWidth = frame.Health:GetWidth()
    local healthFraction = health / maxHealth
    local availableWidth = barWidth * (1 - healthFraction)

    -- My heals
    if myIncoming > 0 then
        local myWidth = min((myIncoming / maxHealth) * barWidth, availableWidth)
        hp.myBar:SetWidth(max(1, myWidth))
        hp.myBar:SetValue(1)
        hp.myBar:Show()
    else
        hp.myBar:Hide()
    end

    -- Other heals
    if otherIncoming > 0 then
        local myWidth = (myIncoming / maxHealth) * barWidth
        local otherWidth = min((otherIncoming / maxHealth) * barWidth, availableWidth - myWidth)
        hp.otherBar:SetWidth(max(1, otherWidth))
        hp.otherBar:SetValue(1)
        hp.otherBar:Show()
    else
        hp.otherBar:Hide()
    end

    -- Absorbs
    if absorb > 0 then
        local absorbWidth = min((absorb / maxHealth) * barWidth, availableWidth)
        hp.absorbBar:SetWidth(max(1, absorbWidth))
        hp.absorbBar:SetValue(1)
        hp.absorbBar:Show()
    else
        hp.absorbBar:Hide()
    end

    -- Heal absorb
    if healAbsorb > 0 then
        local absorbWidth = min((healAbsorb / maxHealth) * barWidth, barWidth * healthFraction)
        hp.healAbsorbBar:SetWidth(max(1, absorbWidth))
        hp.healAbsorbBar:SetValue(1)
        hp.healAbsorbBar:Show()
    else
        hp.healAbsorbBar:Hide()
    end
end

UF:RegisterElement("HealPrediction", UF.CreateHealPrediction)
