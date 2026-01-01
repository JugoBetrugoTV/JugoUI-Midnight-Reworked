--[[
    JugoUI - ActionBars/MicroMenu.lua
    Micro menu bar
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local AB = E.ActionBars

local MICRO_BUTTONS = {
    "CharacterMicroButton",
    "SpellbookMicroButton",
    "TalentMicroButton",
    "AchievementMicroButton",
    "QuestLogMicroButton",
    "GuildMicroButton",
    "LFDMicroButton",
    "CollectionsMicroButton",
    "EJMicroButton",
    "StoreMicroButton",
    "MainMenuMicroButton",
}

function AB:CreateMicroMenu()
    local db = self.db.microMenu
    if InCombatLockdown() then
        E:DelayUntilOutOfCombat(function() self:CreateMicroMenu() end)
        return
    end

    local bar = CreateFrame("Frame", "JugoUI_MicroMenu", UIParent)
    local numButtons = #MICRO_BUTTONS
    local buttonWidth = 24
    local buttonHeight = 33
    local spacing = 1

    bar:SetSize(numButtons * buttonWidth + (numButtons - 1) * spacing + 6, buttonHeight + 6)

    local point = db.point
    bar:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)

    bar.backdrop = E:CreateBackdrop(bar, "Transparent")

    -- Reparent micro buttons
    for i, name in ipairs(MICRO_BUTTONS) do
        local button = _G[name]
        if button then
            button:SetParent(bar)
            button:ClearAllPoints()
            button:SetPoint("LEFT", bar, "LEFT", 3 + (i - 1) * (buttonWidth + spacing), 0)
            button:Show()
        end
    end

    self.bars.microMenu = bar
end

function AB:CreateBagBar()
    local db = self.db.bagBar
    if not db then return end

    local bar = CreateFrame("Frame", "JugoUI_BagBar", UIParent)
    local size = 30
    local spacing = 2
    local numBags = 5

    bar:SetSize(numBags * size + (numBags - 1) * spacing + 6, size + 6)

    local point = db.point
    bar:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)

    bar.backdrop = E:CreateBackdrop(bar, "Transparent")

    -- Reparent bag buttons
    local bagButtons = {
        MainMenuBarBackpackButton,
        CharacterBag0Slot,
        CharacterBag1Slot,
        CharacterBag2Slot,
        CharacterBag3Slot,
    }

    for i, button in ipairs(bagButtons) do
        if button then
            button:SetParent(bar)
            button:ClearAllPoints()
            button:SetPoint("LEFT", bar, "LEFT", 3 + (i - 1) * (size + spacing), 0)
            button:SetSize(size, size)
            button:Show()
        end
    end

    self.bars.bagBar = bar
end
