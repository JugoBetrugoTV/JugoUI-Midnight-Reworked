--[[
    JugoUI - UnitFrames/Elements/Power.lua
    Power bar element for unit frames
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

--[[
    Create Power Bar
]]
function UF:CreatePower(frame)
    local config = frame.config
    local healthHeight = config.healthHeight or 0.75
    local powerHeight = config.powerHeight or 0.25

    local power = CreateFrame("StatusBar", nil, frame)
    power:SetPoint("TOPLEFT", frame.Health, "BOTTOMLEFT", 0, -1)
    power:SetPoint("TOPRIGHT", frame.Health, "BOTTOMRIGHT", 0, -1)
    power:SetHeight((config.height - 4) * powerHeight)
    power:SetStatusBarTexture(E.media.textures.flat)
    power:SetMinMaxValues(0, 1)
    power:SetValue(1)

    -- Background
    power.bg = power:CreateTexture(nil, "BACKGROUND")
    power.bg:SetAllPoints()
    power.bg:SetTexture(E.media.textures.flat)
    power.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    -- Text
    power.value = E:CreateFontString(power, 10, "OUTLINE")
    power.value:SetPoint("CENTER", power, "CENTER", 0, 0)

    -- Smooth bar
    if E.db.unitframes.smoothBars then
        E.Animation:CreateSmoothBar(power, 0.3)
    end

    power.config = config

    return power
end

--[[
    Update Power Bar
]]
function UF:UpdatePower(frame)
    if not frame or not frame.Power then return end

    local unit = frame.unit
    if not UnitExists(unit) then return end

    local power = frame.Power

    -- Get power type
    local powerType, powerToken = UnitPowerType(unit)

    -- Get power values
    local currentPower, maxPower, isSecret = E.API:GetUnitPower(unit, powerType)

    -- Check if unit has power
    if maxPower == 0 or (not isSecret and currentPower == nil) then
        power:Hide()
        return
    else
        power:Show()
    end

    -- Set min/max
    if isSecret then
        power:SetMinMaxValues(0, 1)
    else
        power:SetMinMaxValues(0, maxPower)
    end

    -- Set value
    if power.SmoothSetValue and E.db.unitframes.smoothBars then
        if isSecret then
            local percent = E.API:GetUnitPowerPercent(unit, powerType)
            if not E:IsSecretValue(percent) then
                power:SmoothSetValue(percent / 100)
            end
        else
            power:SmoothSetValue(currentPower)
        end
    else
        if isSecret then
            local percent = E.API:GetUnitPowerPercent(unit, powerType)
            if not E:IsSecretValue(percent) then
                power:SetValue(percent / 100)
            end
        else
            power:SetValue(currentPower)
        end
    end

    -- Update color
    local color = E.media.colors.power[powerToken] or E.media.colors.power.MANA
    power:SetStatusBarColor(color[1], color[2], color[3])
    power.bg:SetVertexColor(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3)

    -- Update text
    if not isSecret then
        if maxPower > 0 then
            power.value:SetText(E:ShortValue(currentPower))
        else
            power.value:SetText("")
        end
    else
        power.value:SetText("")
    end
end

-- Register element
UF:RegisterElement("Power", UF.CreatePower)
