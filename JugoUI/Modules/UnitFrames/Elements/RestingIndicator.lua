--[[
    JugoUI - UnitFrames/Elements/RestingIndicator.lua
    Resting indicator element (player only)
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateRestingIndicator(frame)
    local resting = frame:CreateTexture(nil, "OVERLAY")
    resting:SetSize(20, 20)
    resting:SetPoint("TOPLEFT", frame, "TOPLEFT", -5, 5)
    resting:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    resting:SetTexCoord(0, 0.5, 0, 0.421875)
    resting:Hide()

    return resting
end

function UF:UpdateRestingIndicator(frame)
    if not frame or not frame.RestingIndicator then return end

    if frame.unit ~= "player" then
        frame.RestingIndicator:Hide()
        return
    end

    if IsResting() then
        frame.RestingIndicator:Show()
    else
        frame.RestingIndicator:Hide()
    end
end

UF:RegisterElement("RestingIndicator", UF.CreateRestingIndicator)
