--[[
    JugoUI - UnitFrames/Units/Arena.lua
    Arena enemy unit frames
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateArenaFrames()
    local db = self.db.arena

    for i = 1, 5 do
        self:CreateArenaFrame(i)
    end
end

function UF:CreateArenaFrame(index)
    local db = self.db.arena
    local unit = "arena" .. index
    local frameName = "JugoUI_Arena" .. index

    local frame = self:CreateUnitFrame(unit, frameName, db)
    if not frame then return end

    -- Position
    if index == 1 then
        local point = db.point
        frame:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)
    else
        local offset = db.growthDirection == "DOWN" and -db.spacing or db.spacing
        frame:SetPoint("TOP", self.frames["arena" .. (index - 1)], "BOTTOM", 0, offset)
    end

    -- Trinket indicator
    if db.showTrinkets then
        frame.Trinket = self:CreateTrinketIndicator(frame)
    end

    -- Arena-specific events
    frame:RegisterEvent("ARENA_OPPONENT_UPDATE")
    frame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")

    local oldHandler = frame:GetScript("OnEvent")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "ARENA_OPPONENT_UPDATE" then
            UF:UpdateFrame(frame)
        elseif event == "ARENA_COOLDOWNS_UPDATE" and frame.Trinket then
            UF:UpdateTrinketIndicator(frame)
        else
            oldHandler(self, event, ...)
        end
    end)

    return frame
end

-- Trinket indicator for arena frames
function UF:CreateTrinketIndicator(frame)
    local trinket = CreateFrame("Frame", nil, frame)
    trinket:SetSize(24, 24)
    trinket:SetPoint("RIGHT", frame, "LEFT", -5, 0)

    trinket.icon = trinket:CreateTexture(nil, "ARTWORK")
    trinket.icon:SetAllPoints()
    trinket.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    trinket.cooldown = CreateFrame("Cooldown", nil, trinket, "CooldownFrameTemplate")
    trinket.cooldown:SetAllPoints()

    trinket.border = E:CreateBackdrop(trinket, "Default")

    return trinket
end

function UF:UpdateTrinketIndicator(frame)
    if not frame or not frame.Trinket then return end

    local unit = frame.unit
    if not UnitExists(unit) then
        frame.Trinket:Hide()
        return
    end

    frame.Trinket:Show()

    -- Get trinket cooldown using C_PvP API
    local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo and C_PvP.GetArenaCrowdControlInfo(unit)

    if spellID then
        local spellInfo = E.API:GetSpellInfo(spellID)
        if spellInfo then
            frame.Trinket.icon:SetTexture(GetSpellTexture(spellID))
        end

        if startTime and duration and duration > 0 then
            frame.Trinket.cooldown:SetCooldown(startTime, duration)
        else
            frame.Trinket.cooldown:Clear()
        end
    else
        -- Default trinket icon
        frame.Trinket.icon:SetTexture("Interface\\Icons\\INV_Jewelry_TrinketPvP_01")
        frame.Trinket.cooldown:Clear()
    end
end
