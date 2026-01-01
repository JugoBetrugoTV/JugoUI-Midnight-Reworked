--[[
    JugoUI - ActionBars/PetBar.lua
    Pet action bar
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local AB = E.ActionBars

function AB:CreatePetBar()
    local db = self.db.petBar
    if InCombatLockdown() then
        E:DelayUntilOutOfCombat(function() self:CreatePetBar() end)
        return
    end

    local bar = CreateFrame("Frame", "JugoUI_PetBar", UIParent, "SecureHandlerStateTemplate")
    local size = db.buttonSize
    local spacing = 2
    local numButtons = 10
    local width = numButtons * size + (numButtons - 1) * spacing + 6

    bar:SetSize(width, size + 6)

    local point = db.point
    bar:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)

    bar.backdrop = E:CreateBackdrop(bar, "Transparent")
    bar.buttons = {}

    for i = 1, numButtons do
        local button = CreateFrame("CheckButton", "JugoUI_PetButton" .. i, bar, "PetActionButtonTemplate")
        button:SetSize(size, size)
        button:SetPoint("LEFT", bar, "LEFT", 3 + (i - 1) * (size + spacing), 0)
        button:SetID(i)

        self:StyleButton(button)
        bar.buttons[i] = button
    end

    if db.visibility then
        RegisterStateDriver(bar, "visibility", db.visibility)
    end

    self.bars.petBar = bar
end
