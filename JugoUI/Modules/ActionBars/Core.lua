--[[
    JugoUI - ActionBars/Core.lua
    Action bar module
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local AB = E:NewModule("ActionBars", "AceEvent-3.0", "AceHook-3.0")
E.ActionBars = AB

AB.bars = {}
AB.buttons = {}

-- Try to use LibActionButton
local LAB = LibStub("LibActionButton-1.0", true)

function AB:OnInitialize()
    self.db = E.db.actionbars
end

function AB:OnEnable()
    -- Hide Blizzard action bars
    self:HideBlizzardBars()

    -- Create action bars
    for i = 1, 5 do
        local key = "bar" .. i
        if self.db[key] and self.db[key].enabled then
            self:CreateActionBar(i)
        end
    end

    -- Create special bars
    if self.db.stanceBar and self.db.stanceBar.enabled then
        self:CreateStanceBar()
    end

    if self.db.petBar and self.db.petBar.enabled then
        self:CreatePetBar()
    end

    if self.db.microMenu and self.db.microMenu.enabled then
        self:CreateMicroMenu()
    end

    if self.db.bagBar and self.db.bagBar.enabled then
        self:CreateBagBar()
    end

    -- Events
    self:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    self:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    self:RegisterEvent("UPDATE_BINDINGS")
end

function AB:OnDisable()
    for name, bar in pairs(self.bars) do
        bar:Hide()
    end
end

function AB:CreateActionBar(barNum)
    local db = self.db["bar" .. barNum]
    local barName = "JugoUI_ActionBar" .. barNum

    if InCombatLockdown() then
        E:DelayUntilOutOfCombat(function()
            self:CreateActionBar(barNum)
        end)
        return
    end

    local bar = CreateFrame("Frame", barName, UIParent, "SecureHandlerStateTemplate")

    -- Calculate size
    local rows = ceil(db.buttons / db.buttonsPerRow)
    local cols = min(db.buttons, db.buttonsPerRow)
    local width = cols * db.buttonSize + (cols - 1) * db.buttonSpacing + 6
    local height = rows * db.buttonSize + (rows - 1) * db.buttonSpacing + 6

    bar:SetSize(width, height)

    -- Position
    local point = db.point
    bar:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)

    -- Backdrop
    bar.backdrop = E:CreateBackdrop(bar, "Transparent")

    -- Create buttons
    bar.buttons = {}
    for i = 1, db.buttons do
        local button = self:CreateActionButton(bar, barNum, i)
        bar.buttons[i] = button
    end

    -- Layout buttons
    self:LayoutBar(bar, db)

    -- Visibility state
    if db.visibility then
        RegisterStateDriver(bar, "visibility", db.visibility)
    end

    -- Page state for bar 1
    if barNum == 1 then
        local page = "[bar:6]6;[bar:5]5;[bar:4]4;[bar:3]3;[bar:2]2;[overridebar]14;[shapeshift]13;[vehicleui]12;[possessbar]12;1"
        bar:SetAttribute("actionpage", 1)
        RegisterStateDriver(bar, "page", page)
        bar:SetAttribute("_onstate-page", [[
            self:SetAttribute("actionpage", newstate)
            for i, button in ipairs(buttons) do
                button:SetAttribute("actionpage", newstate)
            end
        ]])
    end

    self.bars[barName] = bar
    return bar
end

function AB:CreateActionButton(parent, barNum, buttonNum)
    local db = self.db["bar" .. barNum]
    local buttonName = "JugoUI_ActionButton" .. barNum .. "_" .. buttonNum

    local actionID = (barNum - 1) * 12 + buttonNum

    local button
    if LAB then
        button = LAB:CreateButton(buttonNum, buttonName, parent, nil)
        button:SetState(0, "action", actionID)
        for k = 1, 14 do
            button:SetState(k, "action", (k - 1) * 12 + buttonNum)
        end
    else
        button = CreateFrame("CheckButton", buttonName, parent, "SecureActionButtonTemplate, ActionButtonTemplate")
        button:SetAttribute("type", "action")
        button:SetAttribute("action", actionID)
    end

    button:SetSize(db.buttonSize, db.buttonSize)

    -- Style the button
    self:StyleButton(button)

    -- Show keybind
    if db.showKeybinds or self.db.showKeybinds then
        button.HotKey:Show()
    else
        button.HotKey:Hide()
    end

    -- Show macro name
    if not (db.showMacroNames or self.db.showMacroNames) then
        button.Name:Hide()
    end

    self.buttons[buttonName] = button
    return button
end

function AB:StyleButton(button)
    if button.styled then return end

    -- Remove default border
    if button.Border then
        button.Border:SetTexture(nil)
    end

    -- Style icon
    local icon = button.icon or button.Icon
    if icon then
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetDrawLayer("ARTWORK", 1)
    end

    -- Create custom border
    if not button.customBorder then
        button.customBorder = button:CreateTexture(nil, "OVERLAY")
        button.customBorder:SetAllPoints()
        button.customBorder:SetTexture(E.media.textures.buttonBorder)
    end

    -- Style cooldown
    if button.cooldown then
        button.cooldown:SetDrawEdge(false)
        button.cooldown:SetSwipeColor(0, 0, 0, 0.8)
    end

    -- Style count text
    if button.Count then
        button.Count:SetFont(E.media.fonts.number, 12, "OUTLINE")
        button.Count:ClearAllPoints()
        button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end

    -- Style hotkey
    if button.HotKey then
        button.HotKey:SetFont(E.media.fonts.normal, 10, "OUTLINE")
        button.HotKey:ClearAllPoints()
        button.HotKey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
    end

    -- Style macro name
    if button.Name then
        button.Name:SetFont(E.media.fonts.normal, 9, "OUTLINE")
    end

    button.styled = true
end

function AB:LayoutBar(bar, db)
    local buttons = bar.buttons
    local buttonsPerRow = db.buttonsPerRow
    local buttonSize = db.buttonSize
    local spacing = db.buttonSpacing

    for i, button in ipairs(buttons) do
        button:ClearAllPoints()

        local row = floor((i - 1) / buttonsPerRow)
        local col = (i - 1) % buttonsPerRow

        local xOffset = 3 + col * (buttonSize + spacing)
        local yOffset = -3 - row * (buttonSize + spacing)

        button:SetPoint("TOPLEFT", bar, "TOPLEFT", xOffset, yOffset)
    end
end

function AB:HideBlizzardBars()
    if InCombatLockdown() then
        E:DelayUntilOutOfCombat(function()
            self:HideBlizzardBars()
        end)
        return
    end

    -- Main action bars
    local blizzBars = {
        MainMenuBar,
        MultiBarBottomLeft,
        MultiBarBottomRight,
        MultiBarRight,
        MultiBarLeft,
        MicroButtonAndBagsBar,
        StanceBar,
        PetActionBar,
        PossessActionBar,
    }

    for _, bar in pairs(blizzBars) do
        if bar then
            bar:UnregisterAllEvents()
            bar:SetParent(E.hiddenFrame)
            bar:Hide()
        end
    end

    -- Action bar buttons
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            button:UnregisterAllEvents()
            button:SetAttribute("statehidden", true)
            button:Hide()
        end
    end
end

function AB:ACTIONBAR_UPDATE_STATE()
    self:UpdateAllButtons()
end

function AB:ACTIONBAR_UPDATE_USABLE()
    self:UpdateAllButtons()
end

function AB:ACTIONBAR_UPDATE_COOLDOWN()
    self:UpdateAllButtons()
end

function AB:UPDATE_BINDINGS()
    self:UpdateKeybinds()
end

function AB:UpdateAllButtons()
    for name, button in pairs(self.buttons) do
        if button.Update then
            button:Update()
        end
    end
end

function AB:UpdateKeybinds()
    for name, button in pairs(self.buttons) do
        if button.UpdateHotkeys then
            button:UpdateHotkeys()
        end
    end
end

function AB:ProfileChanged()
    self.db = E.db.actionbars
    E:DelayUntilOutOfCombat(function()
        for name, bar in pairs(self.bars) do
            local barNum = tonumber(name:match("%d+"))
            if barNum then
                local db = self.db["bar" .. barNum]
                if db then
                    self:LayoutBar(bar, db)
                end
            end
        end
    end)
end
