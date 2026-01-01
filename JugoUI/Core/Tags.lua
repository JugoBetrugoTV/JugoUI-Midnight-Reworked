--[[
    JugoUI - Tags.lua
    Text tag system for dynamic text formatting
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

-- Tag storage
E.tags = {}
E.tagEvents = {}
E.tagFunctions = {}
E.registeredTagStrings = {}

--[[
    Tag Registration
]]
function E:RegisterTag(name, events, func)
    E.tags[name] = true
    E.tagEvents[name] = events or {}
    E.tagFunctions[name] = func
end

function E:UnregisterTag(name)
    E.tags[name] = nil
    E.tagEvents[name] = nil
    E.tagFunctions[name] = nil
end

--[[
    Tag Parsing
]]
local function ParseTags(str, unit)
    if not str then return "" end

    return str:gsub("%[([^%]]+)%]", function(tag)
        local func = E.tagFunctions[tag]
        if func then
            local result = func(unit)
            -- Handle secret values in 12.0
            if E:IsSecretValue(result) then
                return result -- Pass through, let widget handle it
            end
            return result or ""
        end
        return ""
    end)
end

E.ParseTags = ParseTags

--[[
    Create Tag String (FontString with tag updating)
]]
function E:CreateTagString(parent, fontString, tagStr, unit)
    if not fontString or not tagStr then return end

    local tagData = {
        fontString = fontString,
        tagStr = tagStr,
        unit = unit,
        events = {},
    }

    -- Collect events from all tags in the string
    tagStr:gsub("%[([^%]]+)%]", function(tag)
        local events = E.tagEvents[tag]
        if events then
            for _, event in ipairs(events) do
                tagData.events[event] = true
            end
        end
    end)

    -- Create update function
    tagData.Update = function()
        local text = ParseTags(tagStr, unit)
        fontString:SetText(text)
    end

    -- Register events
    for event in pairs(tagData.events) do
        E:RegisterEvent(event, tagData.Update, tagData)
    end

    -- Initial update
    tagData.Update()

    E.registeredTagStrings[fontString] = tagData
    return tagData
end

function E:UpdateTagString(fontString)
    local tagData = E.registeredTagStrings[fontString]
    if tagData then
        tagData.Update()
    end
end

function E:SetTagStringUnit(fontString, unit)
    local tagData = E.registeredTagStrings[fontString]
    if tagData then
        tagData.unit = unit
        tagData.Update()
    end
end

function E:UnregisterTagString(fontString)
    local tagData = E.registeredTagStrings[fontString]
    if tagData then
        for event in pairs(tagData.events) do
            E:UnregisterEvent(event, tagData)
        end
        E.registeredTagStrings[fontString] = nil
    end
end

--[[
    Default Tags
]]

-- Name tags
E:RegisterTag("name", {"UNIT_NAME_UPDATE"}, function(unit)
    return UnitName(unit) or ""
end)

E:RegisterTag("name:short", {"UNIT_NAME_UPDATE"}, function(unit)
    local name = UnitName(unit)
    if name then
        return E:Truncate(name, 10)
    end
    return ""
end)

E:RegisterTag("name:veryshort", {"UNIT_NAME_UPDATE"}, function(unit)
    local name = UnitName(unit)
    if name then
        return E:Truncate(name, 5)
    end
    return ""
end)

E:RegisterTag("name:abbrev", {"UNIT_NAME_UPDATE"}, function(unit)
    local name = UnitName(unit)
    if name then
        return name:gsub("(%S+) ", function(t) return t:sub(1, 1) .. ". " end)
    end
    return ""
end)

E:RegisterTag("name:colored", {"UNIT_NAME_UPDATE"}, function(unit)
    local name = UnitName(unit)
    if not name then return "" end

    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local color = E:GetClassColor(class, true)
        return color .. name .. "|r"
    end

    local reaction = UnitReaction(unit, "player")
    if reaction then
        local color = E.media.colors.reaction[reaction]
        if color then
            return format("|cff%02x%02x%02x%s|r", color[1] * 255, color[2] * 255, color[3] * 255, name)
        end
    end

    return name
end)

-- Health tags
E:RegisterTag("health:current", {"UNIT_HEALTH", "UNIT_MAXHEALTH"}, function(unit)
    local health = UnitHealth(unit)
    if E:IsSecretValue(health) then return health end
    return E:ShortValue(health)
end)

E:RegisterTag("health:max", {"UNIT_HEALTH", "UNIT_MAXHEALTH"}, function(unit)
    local healthMax = UnitHealthMax(unit)
    if E:IsSecretValue(healthMax) then return healthMax end
    return E:ShortValue(healthMax)
end)

E:RegisterTag("health:percent", {"UNIT_HEALTH", "UNIT_MAXHEALTH"}, function(unit)
    local percent = E.API:GetUnitHealthPercent(unit)
    if E:IsSecretValue(percent) then return percent end
    return format("%.0f%%", percent)
end)

E:RegisterTag("health:current-max", {"UNIT_HEALTH", "UNIT_MAXHEALTH"}, function(unit)
    local health = UnitHealth(unit)
    local healthMax = UnitHealthMax(unit)
    if E:IsSecretValue(health) or E:IsSecretValue(healthMax) then
        return health -- Will be handled as secret
    end
    return format("%s / %s", E:ShortValue(health), E:ShortValue(healthMax))
end)

E:RegisterTag("health:deficit", {"UNIT_HEALTH", "UNIT_MAXHEALTH"}, function(unit)
    local health = UnitHealth(unit)
    local healthMax = UnitHealthMax(unit)
    if E:IsSecretValue(health) or E:IsSecretValue(healthMax) then return "" end

    local deficit = healthMax - health
    if deficit > 0 then
        return "-" .. E:ShortValue(deficit)
    end
    return ""
end)

-- Power tags
E:RegisterTag("power:current", {"UNIT_POWER_UPDATE", "UNIT_MAXPOWER"}, function(unit)
    local power = UnitPower(unit)
    if E:IsSecretValue(power) then return power end
    return E:ShortValue(power)
end)

E:RegisterTag("power:max", {"UNIT_POWER_UPDATE", "UNIT_MAXPOWER"}, function(unit)
    local powerMax = UnitPowerMax(unit)
    if E:IsSecretValue(powerMax) then return powerMax end
    return E:ShortValue(powerMax)
end)

E:RegisterTag("power:percent", {"UNIT_POWER_UPDATE", "UNIT_MAXPOWER"}, function(unit)
    local percent = E.API:GetUnitPowerPercent(unit)
    if E:IsSecretValue(percent) then return percent end
    return format("%.0f%%", percent)
end)

-- Level tag
E:RegisterTag("level", {"UNIT_LEVEL"}, function(unit)
    local level = UnitLevel(unit)
    if level == -1 then
        return "??"
    end
    return tostring(level)
end)

E:RegisterTag("level:colored", {"UNIT_LEVEL"}, function(unit)
    local level = UnitLevel(unit)
    if level == -1 then
        return "|cffff0000??|r"
    end

    local playerLevel = E.mylevel
    local color = GetCreatureDifficultyColor(level)
    return format("|cff%02x%02x%02x%d|r", color.r * 255, color.g * 255, color.b * 255, level)
end)

-- Class tag
E:RegisterTag("class", {"UNIT_CLASSIFICATION_CHANGED"}, function(unit)
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        return class
    end
    return UnitCreatureType(unit) or ""
end)

E:RegisterTag("class:colored", {"UNIT_CLASSIFICATION_CHANGED"}, function(unit)
    if UnitIsPlayer(unit) then
        local className, class = UnitClass(unit)
        local color = E:GetClassColor(class, true)
        return color .. className .. "|r"
    end
    return UnitCreatureType(unit) or ""
end)

-- Classification tag (Elite, Rare, etc.)
E:RegisterTag("classification", {"UNIT_CLASSIFICATION_CHANGED"}, function(unit)
    local classification = UnitClassification(unit)
    if classification == "worldboss" then
        return "Boss"
    elseif classification == "rareelite" then
        return "Rare+"
    elseif classification == "elite" then
        return "+"
    elseif classification == "rare" then
        return "Rare"
    end
    return ""
end)

-- Status tags
E:RegisterTag("status", {"UNIT_HEALTH", "UNIT_CONNECTION", "PLAYER_FLAGS_CHANGED"}, function(unit)
    if UnitIsDead(unit) then
        return "Dead"
    elseif UnitIsGhost(unit) then
        return "Ghost"
    elseif not UnitIsConnected(unit) then
        return "Offline"
    elseif UnitIsAFK(unit) then
        return "AFK"
    elseif UnitIsDND(unit) then
        return "DND"
    end
    return ""
end)

-- Guild tag
E:RegisterTag("guild", {"UNIT_NAME_UPDATE"}, function(unit)
    if UnitIsPlayer(unit) then
        local guildName = GetGuildInfo(unit)
        return guildName or ""
    end
    return ""
end)

-- Realm tag
E:RegisterTag("realm", {"UNIT_NAME_UPDATE"}, function(unit)
    local _, realm = UnitName(unit)
    return realm or ""
end)

-- Target tag
E:RegisterTag("target", {"UNIT_TARGET"}, function(unit)
    local targetUnit = unit .. "target"
    return UnitName(targetUnit) or ""
end)

-- Race tag
E:RegisterTag("race", {"UNIT_NAME_UPDATE"}, function(unit)
    if UnitIsPlayer(unit) then
        return UnitRace(unit) or ""
    end
    return UnitCreatureFamily(unit) or ""
end)

-- Threat tag
E:RegisterTag("threat", {"UNIT_THREAT_SITUATION_UPDATE"}, function(unit)
    local status = UnitThreatSituation("player", unit)
    if status then
        if status >= 3 then
            return "|cffff0000AGGRO|r"
        elseif status >= 2 then
            return "|cffff6600DANGER|r"
        elseif status >= 1 then
            return "|cffffff00WARNING|r"
        end
    end
    return ""
end)

-- Combo points tag
E:RegisterTag("cpoints", {"UNIT_POWER_UPDATE", "UNIT_MAXPOWER"}, function(unit)
    local cp = UnitPower("player", Enum.PowerType.ComboPoints)
    if cp and cp > 0 then
        return tostring(cp)
    end
    return ""
end)

-- Group/Raid tags
E:RegisterTag("group", {"GROUP_ROSTER_UPDATE"}, function(unit)
    if not UnitInRaid("player") then return "" end
    local name = UnitName(unit)
    if name then
        local raidID = UnitInRaid(name)
        if raidID then
            local _, _, group = GetRaidRosterInfo(raidID)
            return tostring(group)
        end
    end
    return ""
end)

E:RegisterTag("leader", {"PARTY_LEADER_CHANGED", "GROUP_ROSTER_UPDATE"}, function(unit)
    if UnitIsGroupLeader(unit) then
        return "L"
    end
    return ""
end)

E:RegisterTag("role", {"PLAYER_ROLES_ASSIGNED", "GROUP_ROSTER_UPDATE"}, function(unit)
    local role = UnitGroupRolesAssigned(unit)
    if role == "TANK" then
        return "T"
    elseif role == "HEALER" then
        return "H"
    elseif role == "DAMAGER" then
        return "D"
    end
    return ""
end)

-- PvP tag
E:RegisterTag("pvp", {"UNIT_FACTION"}, function(unit)
    if UnitIsPVP(unit) then
        return "PvP"
    end
    return ""
end)

-- Resting tag
E:RegisterTag("resting", {"PLAYER_UPDATE_RESTING"}, function(unit)
    if unit == "player" and IsResting() then
        return "zzz"
    end
    return ""
end)
