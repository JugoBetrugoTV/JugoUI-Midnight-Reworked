--[[
    JugoUI - UnitFrames/Elements/ReadyCheck.lua
    Ready check indicator element
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateReadyCheck(frame)
    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", frame, "CENTER", 0, 0)
    icon:Hide()

    return icon
end

function UF:UpdateReadyCheck(frame)
    if not frame or not frame.ReadyCheckIndicator then return end

    local unit = frame.unit
    if not UnitExists(unit) then
        frame.ReadyCheckIndicator:Hide()
        return
    end

    local status = GetReadyCheckStatus(unit)
    if status then
        if status == "ready" then
            frame.ReadyCheckIndicator:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        elseif status == "notready" then
            frame.ReadyCheckIndicator:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        elseif status == "waiting" then
            frame.ReadyCheckIndicator:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
        end
        frame.ReadyCheckIndicator:Show()
    else
        frame.ReadyCheckIndicator:Hide()
    end
end

UF:RegisterElement("ReadyCheck", UF.CreateReadyCheck)
