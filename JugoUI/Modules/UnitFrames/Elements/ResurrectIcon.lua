--[[
    JugoUI - UnitFrames/Elements/ResurrectIcon.lua
    Resurrect indicator element
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateResurrectIcon(frame)
    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(24, 24)
    icon:SetPoint("CENTER", frame, "CENTER", 0, 0)
    icon:SetTexture("Interface\\RaidFrame\\Raid-Icon-Rez")
    icon:Hide()

    return icon
end

function UF:UpdateResurrectIcon(frame)
    if not frame or not frame.ResurrectIndicator then return end

    local unit = frame.unit
    if not UnitExists(unit) then
        frame.ResurrectIndicator:Hide()
        return
    end

    local hasRes = UnitHasIncomingResurrection(unit)
    if hasRes then
        frame.ResurrectIndicator:Show()
    else
        frame.ResurrectIndicator:Hide()
    end
end

UF:RegisterElement("ResurrectIcon", UF.CreateResurrectIcon)
