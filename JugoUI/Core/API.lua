--[[
    JugoUI - API.lua
    API wrapper for Patch 12.0 (Midnight) compatibility
    Handles Secret Values and deprecated function replacements
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

-- Create API namespace
E.API = {}

--[[
    Patch 12.0 Secret Value System
    These functions handle the new secret value restrictions in combat
]]

-- Check if we're in a situation where secrets are enforced
function E.API:SecretsEnforced()
    if C_Secrets and C_Secrets.HasSecretRestrictions then
        return C_Secrets.HasSecretRestrictions()
    end
    return false
end

-- Safe health value getter that handles secrets
function E.API:GetUnitHealth(unit)
    local health = UnitHealth(unit)
    local healthMax = UnitHealthMax(unit)

    if E:IsSecretValue(health) then
        -- Return percentage-based curve for display
        return health, healthMax, true
    end

    return health, healthMax, false
end

-- Safe health percentage getter
function E.API:GetUnitHealthPercent(unit)
    -- Use new 12.0 API if available
    if UnitHealthPercent then
        return UnitHealthPercent(unit)
    end

    local health, healthMax = UnitHealth(unit), UnitHealthMax(unit)
    if healthMax > 0 then
        return (health / healthMax) * 100
    end
    return 0
end

-- Safe power value getter
function E.API:GetUnitPower(unit, powerType)
    local power = UnitPower(unit, powerType)
    local powerMax = UnitPowerMax(unit, powerType)

    if E:IsSecretValue(power) then
        return power, powerMax, true
    end

    return power, powerMax, false
end

-- Safe power percentage getter
function E.API:GetUnitPowerPercent(unit, powerType)
    -- Use new 12.0 API if available
    if UnitPowerPercent then
        return UnitPowerPercent(unit, powerType)
    end

    local power, powerMax = UnitPower(unit, powerType), UnitPowerMax(unit, powerType)
    if powerMax > 0 then
        return (power / powerMax) * 100
    end
    return 0
end

--[[
    Nameplate APIs (12.0 changes)
]]
function E.API:SetNamePlateSize(plateType, width, height)
    if C_NamePlate then
        if plateType == "enemy" and C_NamePlate.SetNamePlateEnemySize then
            C_NamePlate.SetNamePlateEnemySize(width, height)
        elseif plateType == "friendly" and C_NamePlate.SetNamePlateFriendlySize then
            C_NamePlate.SetNamePlateFriendlySize(width, height)
        elseif plateType == "self" and C_NamePlate.SetNamePlateSelfSize then
            C_NamePlate.SetNamePlateSelfSize(width, height)
        end
    end
end

function E.API:GetNamePlates()
    return C_NamePlate.GetNamePlates()
end

--[[
    Action Bar APIs (12.0 consolidation to C_ActionBar)
]]
function E.API:GetActionInfo(slot)
    if C_ActionBar and C_ActionBar.GetActionInfo then
        return C_ActionBar.GetActionInfo(slot)
    end
    -- Fallback for older API
    return GetActionInfo(slot)
end

function E.API:GetActionCooldown(slot)
    if C_ActionBar and C_ActionBar.GetActionCooldown then
        return C_ActionBar.GetActionCooldown(slot)
    end
    return GetActionCooldown(slot)
end

function E.API:GetActionTexture(slot)
    if C_ActionBar and C_ActionBar.GetActionTexture then
        return C_ActionBar.GetActionTexture(slot)
    end
    return GetActionTexture(slot)
end

function E.API:GetActionCount(slot)
    if C_ActionBar and C_ActionBar.GetActionDisplayCount then
        return C_ActionBar.GetActionDisplayCount(slot)
    end
    return GetActionCount(slot)
end

function E.API:HasAction(slot)
    if C_ActionBar and C_ActionBar.HasAction then
        return C_ActionBar.HasAction(slot)
    end
    return HasAction(slot)
end

function E.API:IsActionInRange(slot, unit)
    if C_ActionBar and C_ActionBar.IsActionInRange then
        return C_ActionBar.IsActionInRange(slot, unit)
    end
    return IsActionInRange(slot)
end

function E_API:IsUsableAction(slot)
    if C_ActionBar and C_ActionBar.IsUsableAction then
        return C_ActionBar.IsUsableAction(slot)
    end
    return IsUsableAction(slot)
end

--[[
    Spell Book APIs (12.0 consolidation to C_SpellBook)
]]
function E.API:GetSpellInfo(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
        end
    end
    -- Fallback
    return GetSpellInfo(spellID)
end

function E.API:GetSpellCooldown(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if info then
            return info.startTime, info.duration, info.isEnabled, info.modRate
        end
    end
    return GetSpellCooldown(spellID)
end

function E.API:IsSpellKnown(spellID)
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        return C_SpellBook.IsSpellKnown(spellID)
    end
    return IsSpellKnown(spellID)
end

--[[
    Combat Log APIs (12.0 consolidation to C_CombatLog)
]]
function E.API:GetCurrentEventInfo()
    if C_CombatLog and C_CombatLog.GetCurrentEventInfo then
        return C_CombatLog.GetCurrentEventInfo()
    end
    return CombatLogGetCurrentEventInfo()
end

--[[
    Aura APIs
]]
function E.API:GetAuraDataByIndex(unit, index, filter)
    -- Use C_UnitAuras in 12.0+
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        return C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
    end

    -- Fallback to old API
    local auraData = {}
    local name, icon, count, debuffType, duration, expirationTime, source, isStealable,
          nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer,
          nameplateShowAll, timeMod = UnitAura(unit, index, filter)

    if name then
        auraData.name = name
        auraData.icon = icon
        auraData.applications = count
        auraData.dispelName = debuffType
        auraData.duration = duration
        auraData.expirationTime = expirationTime
        auraData.sourceUnit = source
        auraData.isStealable = isStealable
        auraData.nameplateShowPersonal = nameplateShowPersonal
        auraData.spellId = spellId
        auraData.canApplyAura = canApplyAura
        auraData.isBossAura = isBossDebuff
        auraData.isFromPlayerOrPlayerPet = castByPlayer
        auraData.nameplateShowAll = nameplateShowAll
        auraData.timeMod = timeMod
        return auraData
    end

    return nil
end

function E.API:GetAuraDataBySpellName(unit, spellName, filter)
    if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
        return C_UnitAuras.GetAuraDataBySpellName(unit, spellName, filter)
    end
    return nil
end

function E.API:GetPlayerAuraBySpellID(spellID)
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        return C_UnitAuras.GetPlayerAuraBySpellID(spellID)
    end
    return nil
end

--[[
    Instance/Encounter APIs
]]
function E.API:IsEncounterInProgress()
    if C_InstanceEncounter and C_InstanceEncounter.IsEncounterInProgress then
        return C_InstanceEncounter.IsEncounterInProgress()
    end
    -- Fallback check
    return IsEncounterInProgress and IsEncounterInProgress() or false
end

function E.API:GetInstanceInfo()
    return GetInstanceInfo()
end

function E.API:IsInInstance()
    return IsInInstance()
end

--[[
    Chat APIs
]]
function E.API:PerformEmote(emoteToken, target)
    if C_ChatInfo and C_ChatInfo.PerformEmote then
        C_ChatInfo.PerformEmote(emoteToken, target)
    else
        DoEmote(emoteToken, target)
    end
end

--[[
    String Utilities (12.0 C_StringUtil)
]]
function E.API:TruncateString(str, maxLength, ellipsis)
    if C_StringUtil and C_StringUtil.TruncateString then
        return C_StringUtil.TruncateString(str, maxLength, ellipsis)
    end
    -- Fallback
    if not str or #str <= maxLength then return str end
    ellipsis = ellipsis or "..."
    return str:sub(1, maxLength - #ellipsis) .. ellipsis
end

function E.API:WrapString(str, maxWidth)
    if C_StringUtil and C_StringUtil.WrapString then
        return C_StringUtil.WrapString(str, maxWidth)
    end
    return str
end

--[[
    Color Utilities (12.0 C_ColorUtil)
]]
function E.API:ConvertRGBtoHSV(r, g, b)
    if C_ColorUtil and C_ColorUtil.ConvertRGBtoHSV then
        return C_ColorUtil.ConvertRGBtoHSV(r, g, b)
    end
    -- Fallback conversion
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, v
    v = max

    local d = max - min
    if max == 0 then
        s = 0
    else
        s = d / max
    end

    if max == min then
        h = 0
    else
        if max == r then
            h = (g - b) / d
            if g < b then h = h + 6 end
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, v
end

function E.API:ConvertHSVtoRGB(h, s, v)
    if C_ColorUtil and C_ColorUtil.ConvertHSVtoRGB then
        return C_ColorUtil.ConvertHSVtoRGB(h, s, v)
    end
    -- Fallback conversion
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return r, g, b
end

--[[
    Cooldown Display (12.0 DurationObject support)
]]
function E.API:SetCooldownFromDuration(cooldown, start, duration, enable, modRate)
    -- Use new 12.0 method if available
    if cooldown.SetCooldownFromDurationObject then
        local durationObj = {
            startTime = start,
            duration = duration,
            isEnabled = enable,
            modRate = modRate or 1,
        }
        cooldown:SetCooldownFromDurationObject(durationObj)
    else
        cooldown:SetCooldown(start, duration, modRate)
    end
end

function E.API:SetCooldownFromExpiration(cooldown, expirationTime, duration, enable, modRate)
    if cooldown.SetCooldownFromExpirationTime then
        cooldown:SetCooldownFromExpirationTime(expirationTime, duration, enable, modRate)
    else
        local start = expirationTime - duration
        cooldown:SetCooldown(start, duration, modRate)
    end
end

--[[
    Event Registration (12.0 EventCallback system)
]]
function E.API:RegisterEventCallback(event, callback)
    if RegisterEventCallback then
        return RegisterEventCallback(event, callback)
    end
    -- Fallback to frame-based events
    return nil
end

function E.API:RegisterUnitEventCallback(event, unit, callback)
    if RegisterUnitEventCallback then
        return RegisterUnitEventCallback(event, unit, callback)
    end
    return nil
end

--[[
    Curve System (12.0 for secret value display)
]]
function E.API:CreateHealthCurve()
    -- Create a curve for health bar coloring (green->yellow->red)
    if CreateCurve then
        local curve = CreateCurve()
        curve:AddPoint(0, 1, 0, 0) -- 0%: Red
        curve:AddPoint(0.5, 1, 1, 0) -- 50%: Yellow
        curve:AddPoint(1, 0, 1, 0) -- 100%: Green
        return curve
    end
    return nil
end

function E.API:CreateColorCurve(...)
    if CreateColorCurve then
        return CreateColorCurve(...)
    end
    return nil
end

--[[
    Heal Prediction (12.0 UnitHealPredictionCalculator)
]]
function E.API:GetHealPrediction(unit)
    if UnitHealPredictionCalculator then
        local calc = UnitHealPredictionCalculator()
        return calc:Calculate(unit)
    end

    -- Fallback to old API
    local incomingHeal = UnitGetIncomingHeals and UnitGetIncomingHeals(unit) or 0
    local absorb = UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit) or 0
    local healAbsorb = UnitGetTotalHealAbsorbs and UnitGetTotalHealAbsorbs(unit) or 0

    return {
        incomingHeal = incomingHeal,
        absorb = absorb,
        healAbsorb = healAbsorb,
    }
end

--[[
    Backward Compatibility Layer
    Map old function names to new ones
]]
E.API.Compat = {}

-- These are safety wrappers in case old code tries to call deprecated functions
setmetatable(E.API.Compat, {
    __index = function(t, key)
        -- Log deprecated function usage in debug mode
        if E.debug then
            E:Debug("Deprecated API called:", key)
        end
        return function() end
    end
})
