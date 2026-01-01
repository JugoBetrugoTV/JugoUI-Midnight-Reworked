--[[
    JugoUI - UnitFrames/Units/Party.lua
    Party unit frames
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreatePartyFrames()
    local db = self.db.party

    if InCombatLockdown() then
        E:DelayUntilOutOfCombat(function()
            self:CreatePartyFrames()
        end)
        return
    end

    -- Create header for party frames
    local header = CreateFrame("Frame", "JugoUI_PartyHeader", UIParent, "SecureGroupHeaderTemplate")
    header:SetAttribute("template", "SecureUnitButtonTemplate")
    header:SetAttribute("showParty", true)
    header:SetAttribute("showRaid", db.showInRaid)
    header:SetAttribute("showPlayer", db.showPlayer)
    header:SetAttribute("showSolo", false)
    header:SetAttribute("point", db.growthDirection == "DOWN" and "TOP" or "BOTTOM")
    header:SetAttribute("xOffset", 0)
    header:SetAttribute("yOffset", db.growthDirection == "DOWN" and -db.spacing or db.spacing)

    -- Position
    local point = db.point
    header:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)

    -- Store header
    self.headers.party = header

    -- Create individual party frames
    for i = 1, 4 do
        self:CreatePartyMemberFrame(i)
    end

    -- Show header
    header:Show()

    -- Register for roster updates
    header:RegisterEvent("GROUP_ROSTER_UPDATE")
    header:SetScript("OnEvent", function()
        UF:UpdatePartyVisibility()
    end)

    self:UpdatePartyVisibility()
end

function UF:CreatePartyMemberFrame(index)
    local db = self.db.party
    local unit = "party" .. index
    local frameName = "JugoUI_Party" .. index

    local frame = self:CreateUnitFrame(unit, frameName, db)
    if not frame then return end

    -- Position relative to header
    if index == 1 then
        local point = db.point
        frame:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)
    else
        local offset = db.growthDirection == "DOWN" and -db.spacing or db.spacing
        frame:SetPoint("TOP", self.frames["party" .. (index - 1)], "BOTTOM", 0, offset)
    end

    return frame
end

function UF:UpdatePartyVisibility()
    local db = self.db.party
    local inRaid = IsInRaid()
    local inParty = IsInGroup()

    for i = 1, 4 do
        local frame = self.frames["party" .. i]
        if frame then
            if inRaid and not db.showInRaid then
                frame:Hide()
            elseif inParty then
                -- Secure template handles visibility
            else
                frame:Hide()
            end
        end
    end
end
