--[[
    JugoUI - UnitFrames/Elements/Health.lua
    Health bar element for unit frames
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

--[[
    Create Health Bar
]]
function UF:CreateHealth(frame)
    local config = frame.config
    local healthHeight = config.healthHeight or 0.75

    local health = CreateFrame("StatusBar", nil, frame)
    health:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    health:SetHeight((config.height - 4) * healthHeight)
    health:SetStatusBarTexture(E.media.textures.flat)
    health:SetStatusBarColor(0.2, 0.2, 0.2)
    health:SetMinMaxValues(0, 1)
    health:SetValue(1)

    -- Background
    health.bg = health:CreateTexture(nil, "BACKGROUND")
    health.bg:SetAllPoints()
    health.bg:SetTexture(E.media.textures.flat)
    health.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    -- Text
    health.value = E:CreateFontString(health, 11, "OUTLINE")
    health.value:SetPoint("RIGHT", health, "RIGHT", -5, 0)

    health.percent = E:CreateFontString(health, 11, "OUTLINE")
    health.percent:SetPoint("LEFT", health, "LEFT", 5, 0)

    -- Smooth bar
    if E.db.unitframes.smoothBars then
        E.Animation:CreateSmoothBar(health, 0.3)
    end

    -- Color curve for 12.0 secret values
    if CreateColorCurve then
        health.colorCurve = CreateColorCurve()
        health.colorCurve:AddPoint(0, 1, 0, 0)    -- 0%: Red
        health.colorCurve:AddPoint(0.5, 1, 1, 0)  -- 50%: Yellow
        health.colorCurve:AddPoint(1, 0, 1, 0)    -- 100%: Green
    end

    -- Store config reference
    health.config = config

    return health
end

--[[
    Update Health Bar
]]
function UF:UpdateHealth(frame)
    if not frame or not frame.Health then return end

    local unit = frame.unit
    if not UnitExists(unit) then return end

    local health = frame.Health
    local db = frame.config

    -- Get health values (handles secrets in 12.0)
    local currentHealth, maxHealth, isSecret = E.API:GetUnitHealth(unit)

    -- Set min/max
    if isSecret then
        health:SetMinMaxValues(0, 1)
    else
        health:SetMinMaxValues(0, maxHealth)
    end

    -- Set value
    if health.SmoothSetValue and E.db.unitframes.smoothBars then
        if isSecret then
            local percent = E.API:GetUnitHealthPercent(unit)
            if not E:IsSecretValue(percent) then
                health:SmoothSetValue(percent / 100)
            end
        else
            health:SmoothSetValue(currentHealth)
        end
    else
        if isSecret then
            local percent = E.API:GetUnitHealthPercent(unit)
            if not E:IsSecretValue(percent) then
                health:SetValue(percent / 100)
            end
        else
            health:SetValue(currentHealth)
        end
    end

    -- Update text
    self:UpdateHealthText(frame, currentHealth, maxHealth, isSecret)

    -- Update color
    self:UpdateHealthColor(frame, currentHealth, maxHealth, isSecret)
end

--[[
    Update Health Text
]]
function UF:UpdateHealthText(frame, currentHealth, maxHealth, isSecret)
    local health = frame.Health
    local unit = frame.unit

    -- Check for dead/ghost/offline states
    if UnitIsDead(unit) then
        health.value:SetText("Dead")
        health.percent:SetText("")
        return
    elseif UnitIsGhost(unit) then
        health.value:SetText("Ghost")
        health.percent:SetText("")
        return
    elseif not UnitIsConnected(unit) then
        health.value:SetText("Offline")
        health.percent:SetText("")
        return
    end

    if isSecret then
        -- Can't show numeric values for secrets
        local percent = E.API:GetUnitHealthPercent(unit)
        if E:IsSecretValue(percent) then
            health.value:SetText("")
            health.percent:SetText("")
        else
            health.value:SetText("")
            health.percent:SetText(format("%.0f%%", percent))
        end
    else
        -- Normal display
        if maxHealth > 0 then
            local percent = (currentHealth / maxHealth) * 100
            health.value:SetText(E:ShortValue(currentHealth))
            health.percent:SetText(format("%.0f%%", percent))
        else
            health.value:SetText("0")
            health.percent:SetText("0%")
        end
    end
end

--[[
    Update Health Color
]]
function UF:UpdateHealthColor(frame, currentHealth, maxHealth, isSecret)
    local health = frame.Health
    local unit = frame.unit
    local db = E.db.unitframes

    -- Dead/Ghost/Offline colors
    if UnitIsDead(unit) or UnitIsGhost(unit) then
        health:SetStatusBarColor(0.4, 0.4, 0.4)
        return
    elseif not UnitIsConnected(unit) then
        health:SetStatusBarColor(0.5, 0.5, 0.5)
        return
    end

    -- Tapped color
    if UnitIsTapDenied(unit) then
        health:SetStatusBarColor(0.55, 0.55, 0.55)
        return
    end

    -- Class color for players
    if db.classColorHealth and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class then
            local r, g, b = E:GetClassColor(class)
            health:SetStatusBarColor(r, g, b)
            return
        end
    end

    -- Reaction color for NPCs
    if db.colorByReaction and not UnitIsPlayer(unit) then
        local reaction = UnitReaction(unit, "player")
        if reaction then
            local color = E.media.colors.reaction[reaction]
            if color then
                health:SetStatusBarColor(color[1], color[2], color[3])
                return
            end
        end
    end

    -- Gradient based on health percentage
    if not isSecret and maxHealth > 0 then
        local percent = currentHealth / maxHealth
        local r, g
        if percent > 0.5 then
            r = (1 - percent) * 2
            g = 1
        else
            r = 1
            g = percent * 2
        end
        health:SetStatusBarColor(r, g, 0)
    elseif isSecret and health.colorCurve then
        -- Use color curve for secret values
        if health.SetVertexColorFromCurve then
            health:SetVertexColorFromCurve(health.colorCurve)
        else
            -- Fallback to a neutral color
            health:SetStatusBarColor(0.3, 0.3, 0.3)
        end
    else
        -- Default color
        health:SetStatusBarColor(unpack(E.media.colors.health.value))
    end
end

-- Register element
UF:RegisterElement("Health", UF.CreateHealth)
