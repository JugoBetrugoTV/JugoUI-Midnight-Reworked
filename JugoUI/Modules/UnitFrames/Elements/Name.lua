--[[
    JugoUI - UnitFrames/Elements/Name.lua
    Name text element for unit frames
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

--[[
    Create Name Text
]]
function UF:CreateName(frame)
    local name = E:CreateFontString(frame.Health, 12, "OUTLINE", "LEFT")
    name:SetPoint("LEFT", frame.Health, "LEFT", 5, 0)
    name:SetPoint("RIGHT", frame.Health.percent, "LEFT", -5, 0)
    name:SetWordWrap(false)

    return name
end

--[[
    Create Level Text
]]
function UF:CreateLevel(frame)
    local level = E:CreateFontString(frame.Health, 10, "OUTLINE", "RIGHT")
    level:SetPoint("BOTTOMRIGHT", frame.Health, "TOPRIGHT", 0, 2)

    return level
end

--[[
    Update Name
]]
function UF:UpdateName(frame)
    if not frame or not frame.Name then return end

    local unit = frame.unit
    if not UnitExists(unit) then
        frame.Name:SetText("")
        return
    end

    local name = UnitName(unit)

    -- Handle secret names in 12.0
    if E:IsSecretValue(name) then
        -- Use colored placeholder
        frame.Name:SetText("|cff888888???|r")
        return
    end

    if not name then
        frame.Name:SetText("")
        return
    end

    -- Truncate if needed
    local maxLen = frame.config.nameLength or 20
    if #name > maxLen then
        name = E:Truncate(name, maxLen)
    end

    -- Class color for players
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class then
            local color = E:GetClassColor(class, true)
            name = color .. name .. "|r"
        end
    end

    frame.Name:SetText(name)
end

--[[
    Update Level
]]
function UF:UpdateLevel(frame)
    if not frame or not frame.Level then return end

    local unit = frame.unit
    if not UnitExists(unit) then
        frame.Level:SetText("")
        return
    end

    local level = UnitLevel(unit)

    if level == -1 then
        frame.Level:SetText("|cffff0000??|r")
    else
        -- Color by difficulty
        local color = GetCreatureDifficultyColor(level)
        frame.Level:SetFormattedText("|cff%02x%02x%02x%d|r", color.r * 255, color.g * 255, color.b * 255, level)
    end

    -- Add classification
    local classification = UnitClassification(unit)
    local classStr = ""
    if classification == "worldboss" then
        classStr = " |cffff0000Boss|r"
    elseif classification == "rareelite" then
        classStr = " |cff00ff00R+|r"
    elseif classification == "elite" then
        classStr = " |cffffff00+|r"
    elseif classification == "rare" then
        classStr = " |cff00ff00R|r"
    end

    frame.Level:SetText(frame.Level:GetText() .. classStr)
end

-- Register elements
UF:RegisterElement("Name", UF.CreateName)
UF:RegisterElement("Level", UF.CreateLevel)
