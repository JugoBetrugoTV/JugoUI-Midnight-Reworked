--[[
    JugoUI - UnitFrames/Elements/Range.lua
    Range check element (fades out of range units)
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateRange(frame)
    local range = {}
    range.insideAlpha = 1
    range.outsideAlpha = 0.4
    range.checkInterval = 0.2
    range.elapsed = 0

    return range
end

function UF:UpdateRange(frame)
    if not frame or not frame.Range then return end

    local unit = frame.unit
    if not UnitExists(unit) then return end

    local range = frame.Range
    local inRange = UnitInRange(unit)

    -- Handle nil return (unit is not a party/raid member)
    if inRange == nil then
        -- Check if we're the player
        if UnitIsUnit(unit, "player") then
            frame:SetAlpha(range.insideAlpha)
        else
            -- Use IsSpellInRange as fallback for other units
            frame:SetAlpha(range.insideAlpha)
        end
        return
    end

    if inRange then
        frame:SetAlpha(range.insideAlpha)
    else
        frame:SetAlpha(range.outsideAlpha)
    end
end

UF:RegisterElement("Range", UF.CreateRange)
