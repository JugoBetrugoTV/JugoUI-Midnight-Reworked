--[[
    JugoUI - UnitFrames/Units/Boss.lua
    Boss unit frames
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateBossFrames()
    local db = self.db.boss

    for i = 1, 8 do -- Support up to 8 boss frames
        self:CreateBossFrame(i)
    end
end

function UF:CreateBossFrame(index)
    local db = self.db.boss
    local unit = "boss" .. index
    local frameName = "JugoUI_Boss" .. index

    local frame = self:CreateUnitFrame(unit, frameName, db)
    if not frame then return end

    -- Position
    if index == 1 then
        local point = db.point
        frame:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)
    else
        local offset = db.growthDirection == "DOWN" and -db.spacing or db.spacing
        frame:SetPoint("TOP", self.frames["boss" .. (index - 1)], "BOTTOM", 0, offset)
    end

    -- Register boss-specific events
    frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    frame:RegisterEvent("UNIT_TARGETABLE_CHANGED")

    local oldHandler = frame:GetScript("OnEvent")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
            UF:UpdateFrame(frame)
        elseif event == "UNIT_TARGETABLE_CHANGED" then
            UF:UpdateFrame(frame)
        else
            oldHandler(self, event, ...)
        end
    end)

    return frame
end
