--[[
    JugoUI - UnitFrames/Elements/PvPIndicator.lua
    PvP flag indicator element
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreatePvPIndicator(frame)
    local pvp = frame:CreateTexture(nil, "OVERLAY")
    pvp:SetSize(30, 30)
    pvp:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, 5)
    pvp:Hide()

    return pvp
end

function UF:UpdatePvPIndicator(frame)
    if not frame or not frame.PvPIndicator then return end

    local unit = frame.unit
    if not UnitExists(unit) then
        frame.PvPIndicator:Hide()
        return
    end

    local factionGroup = UnitFactionGroup(unit)
    if UnitIsPVP(unit) then
        if factionGroup == "Horde" then
            frame.PvPIndicator:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
        elseif factionGroup == "Alliance" then
            frame.PvPIndicator:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
        else
            frame.PvPIndicator:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
        end
        frame.PvPIndicator:Show()
    else
        frame.PvPIndicator:Hide()
    end
end

UF:RegisterElement("PvPIndicator", UF.CreatePvPIndicator)
