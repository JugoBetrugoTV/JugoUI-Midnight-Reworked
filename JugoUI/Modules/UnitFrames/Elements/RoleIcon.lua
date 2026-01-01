--[[
    JugoUI - UnitFrames/Elements/RoleIcon.lua
    Group role indicator element
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateRoleIcon(frame)
    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(14, 14)
    icon:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
    icon:Hide()

    return icon
end

function UF:UpdateRoleIcon(frame)
    if not frame or not frame.RoleIcon then return end

    local unit = frame.unit
    if not UnitExists(unit) then
        frame.RoleIcon:Hide()
        return
    end

    local role = UnitGroupRolesAssigned(unit)
    if role == "TANK" then
        frame.RoleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        frame.RoleIcon:SetTexCoord(0, 0.296875, 0.328125, 0.625)
        frame.RoleIcon:Show()
    elseif role == "HEALER" then
        frame.RoleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        frame.RoleIcon:SetTexCoord(0.296875, 0.59375, 0.328125, 0.625)
        frame.RoleIcon:Show()
    elseif role == "DAMAGER" then
        frame.RoleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        frame.RoleIcon:SetTexCoord(0.296875, 0.59375, 0, 0.296875)
        frame.RoleIcon:Show()
    else
        frame.RoleIcon:Hide()
    end
end

UF:RegisterElement("RoleIcon", UF.CreateRoleIcon)
