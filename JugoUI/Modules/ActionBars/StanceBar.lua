--[[
    JugoUI - ActionBars/StanceBar.lua
    Stance/Shapeshift bar
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local AB = E.ActionBars

function AB:CreateStanceBar()
    local db = self.db.stanceBar
    if InCombatLockdown() then
        E:DelayUntilOutOfCombat(function() self:CreateStanceBar() end)
        return
    end

    local numForms = GetNumShapeshiftForms()
    if numForms == 0 then return end

    local bar = CreateFrame("Frame", "JugoUI_StanceBar", UIParent, "SecureHandlerStateTemplate")
    local size = db.buttonSize
    local spacing = 2
    local width = numForms * size + (numForms - 1) * spacing + 6

    bar:SetSize(width, size + 6)

    local point = db.point
    bar:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)

    bar.backdrop = E:CreateBackdrop(bar, "Transparent")
    bar.buttons = {}

    for i = 1, numForms do
        local button = CreateFrame("CheckButton", "JugoUI_StanceButton" .. i, bar, "StanceButtonTemplate")
        button:SetSize(size, size)
        button:SetPoint("LEFT", bar, "LEFT", 3 + (i - 1) * (size + spacing), 0)
        button:SetID(i)

        self:StyleButton(button)
        bar.buttons[i] = button
    end

    bar:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
    bar:SetScript("OnEvent", function() AB:UpdateStanceBar() end)

    self.bars.stanceBar = bar
end

function AB:UpdateStanceBar()
    local bar = self.bars.stanceBar
    if not bar then return end

    local numForms = GetNumShapeshiftForms()
    for i = 1, #bar.buttons do
        if i <= numForms then
            bar.buttons[i]:Show()
        else
            bar.buttons[i]:Hide()
        end
    end
end
