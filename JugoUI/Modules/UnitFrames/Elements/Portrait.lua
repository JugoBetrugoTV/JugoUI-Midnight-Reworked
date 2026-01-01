--[[
    JugoUI - UnitFrames/Elements/Portrait.lua
    Portrait element for unit frames
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

--[[
    Create Portrait
]]
function UF:CreatePortrait(frame, config)
    local portrait

    if config.style == "3D" then
        portrait = CreateFrame("PlayerModel", nil, frame)
    else
        portrait = frame:CreateTexture(nil, "ARTWORK")
    end

    local width = config.width or frame.config.height
    portrait:SetSize(width, frame.config.height - 4)

    -- Position based on unit
    if frame.unit == "target" or frame.unit == "focus" then
        portrait:SetPoint("TOPRIGHT", frame, "TOPLEFT", -2, -2)
    else
        portrait:SetPoint("TOPLEFT", frame, "TOPRIGHT", 2, -2)
    end

    -- Border
    portrait.border = E:CreateBackdrop(portrait, "Default")

    portrait.style = config.style
    portrait.config = config

    return portrait
end

--[[
    Update Portrait
]]
function UF:UpdatePortrait(frame)
    if not frame or not frame.Portrait then return end

    local unit = frame.unit
    if not UnitExists(unit) then
        frame.Portrait:Hide()
        if frame.Portrait.border then
            frame.Portrait.border:Hide()
        end
        return
    end

    frame.Portrait:Show()
    if frame.Portrait.border then
        frame.Portrait.border:Show()
    end

    if frame.Portrait.style == "3D" then
        -- 3D model portrait
        frame.Portrait:ClearModel()
        frame.Portrait:SetUnit(unit)
        frame.Portrait:SetCamera(0)
        frame.Portrait:SetModelScale(1)
        frame.Portrait:SetPosition(0, 0, 0)
    else
        -- 2D texture portrait
        SetPortraitTexture(frame.Portrait, unit)
    end

    -- Grayscale for dead/ghost/offline
    if frame.Portrait.style ~= "3D" then
        if UnitIsDead(unit) or UnitIsGhost(unit) or not UnitIsConnected(unit) then
            frame.Portrait:SetDesaturated(true)
        else
            frame.Portrait:SetDesaturated(false)
        end
    end
end

-- Register element
UF:RegisterElement("Portrait", UF.CreatePortrait)
