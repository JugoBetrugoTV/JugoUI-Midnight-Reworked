--[[ LibActionButton-1.0 - A library for creating action buttons
     Simplified implementation for JugoUI ]]

local MAJOR, MINOR = "LibActionButton-1.0", 100
local LibActionButton = LibStub:NewLibrary(MAJOR, MINOR)
if not LibActionButton then return end

local type = type
local pairs = pairs
local setmetatable = setmetatable
local CreateFrame = CreateFrame
local GetActionInfo = GetActionInfo
local GetActionTexture = GetActionTexture
local GetActionText = GetActionText
local GetActionCount = GetActionCount
local GetActionCooldown = GetActionCooldown
local IsUsableAction = IsUsableAction
local IsCurrentAction = IsCurrentAction
local IsAutoRepeatAction = IsAutoRepeatAction
local IsActionInRange = IsActionInRange
local HasAction = HasAction
local UseAction = UseAction
local PickupAction = PickupAction

LibActionButton.buttonRegistry = LibActionButton.buttonRegistry or {}
LibActionButton.activeButtons = LibActionButton.activeButtons or {}

local buttonRegistry = LibActionButton.buttonRegistry
local activeButtons = LibActionButton.activeButtons

local ButtonPrototype = {}
local ButtonMeta = {__index = ButtonPrototype}

function ButtonPrototype:SetState(state, type, action)
    self.state = self.state or {}
    self.state[state] = self.state[state] or {}
    self.state[state].type = type
    self.state[state].action = action
end

function ButtonPrototype:GetAction()
    local state = self:GetAttribute("state") or 0
    if self.state and self.state[state] then
        return self.state[state].action
    end
    return self._state_action or 0
end

function ButtonPrototype:UpdateAction(force)
    local action = self:GetAction()
    if action ~= self.action or force then
        self.action = action
        self:Update()
    end
end

function ButtonPrototype:Update()
    if not self.action then return end

    self:UpdateIcon()
    self:UpdateCount()
    self:UpdateCooldown()
    self:UpdateUsable()
    self:UpdateFlash()
end

function ButtonPrototype:UpdateIcon()
    local action = self.action
    if HasAction(action) then
        local texture = GetActionTexture(action)
        self.icon:SetTexture(texture)
        self.icon:Show()
    else
        self.icon:Hide()
    end
end

function ButtonPrototype:UpdateCount()
    local action = self.action
    if HasAction(action) then
        local count = GetActionCount(action)
        if count > 0 then
            self.count:SetText(count)
        else
            self.count:SetText("")
        end
    else
        self.count:SetText("")
    end
end

function ButtonPrototype:UpdateCooldown()
    local action = self.action
    if HasAction(action) then
        local start, duration, enable = GetActionCooldown(action)
        if start and start > 0 and duration > 0 then
            self.cooldown:SetCooldown(start, duration)
            self.cooldown:Show()
        else
            self.cooldown:Hide()
        end
    else
        self.cooldown:Hide()
    end
end

function ButtonPrototype:UpdateUsable()
    local action = self.action
    if HasAction(action) then
        local isUsable, notEnoughMana = IsUsableAction(action)
        if isUsable then
            self.icon:SetVertexColor(1, 1, 1)
        elseif notEnoughMana then
            self.icon:SetVertexColor(0.5, 0.5, 1)
        else
            self.icon:SetVertexColor(0.4, 0.4, 0.4)
        end
    end
end

function ButtonPrototype:UpdateFlash()
    local action = self.action
    if HasAction(action) then
        if IsCurrentAction(action) or IsAutoRepeatAction(action) then
            self:StartFlash()
        else
            self:StopFlash()
        end
    else
        self:StopFlash()
    end
end

function ButtonPrototype:StartFlash()
    self.flashing = true
end

function ButtonPrototype:StopFlash()
    self.flashing = false
    if self.flash then
        self.flash:Hide()
    end
end

function ButtonPrototype:ShowGrid()
    self:SetAlpha(1)
end

function ButtonPrototype:HideGrid()
    if not HasAction(self.action) then
        self:SetAlpha(0)
    end
end

function ButtonPrototype:SetKey(key)
    self.hotkey:SetText(key or "")
end

function ButtonPrototype:ClearBindings()
    self.hotkey:SetText("")
end

function LibActionButton:CreateButton(id, name, header, config)
    local button = CreateFrame("CheckButton", name, header, "SecureActionButtonTemplate, ActionButtonTemplate")
    button:SetID(id)

    button.icon = _G[name .. "Icon"] or button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetAllPoints()

    button.cooldown = _G[name .. "Cooldown"] or CreateFrame("Cooldown", name .. "Cooldown", button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()

    button.count = _G[name .. "Count"] or button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", -2, 2)

    button.hotkey = _G[name .. "HotKey"] or button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    button.hotkey:SetPoint("TOPRIGHT", -2, -2)

    button.flash = _G[name .. "Flash"] or button:CreateTexture(nil, "OVERLAY")
    button.flash:SetAllPoints()
    button.flash:SetTexture("Interface\\Buttons\\UI-QuickslotRed")
    button.flash:Hide()

    button.pushed = button:CreateTexture(nil, "OVERLAY")
    button.pushed:SetAllPoints()
    button.pushed:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    button:SetPushedTexture(button.pushed)

    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints()
    button.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    button:SetHighlightTexture(button.highlight)

    setmetatable(button, ButtonMeta)

    button:SetAttribute("type", "action")
    button:SetAttribute("action", id)
    button._state_action = id
    button.action = id

    button:RegisterForClicks("AnyUp", "AnyDown")
    button:RegisterForDrag("LeftButton", "RightButton")

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetAction(self.action)
    end)

    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    button:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then
            PickupAction(self.action)
            self:Update()
        end
    end)

    button:SetScript("OnReceiveDrag", function(self)
        if not InCombatLockdown() then
            PlaceAction(self.action)
            self:Update()
        end
    end)

    buttonRegistry[button] = true
    activeButtons[button] = config

    return button
end

function LibActionButton:GetAllButtons()
    local buttons = {}
    for button in pairs(buttonRegistry) do
        buttons[#buttons + 1] = button
    end
    return buttons
end

local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnEvent", function(self, event, ...)
    for button in pairs(buttonRegistry) do
        button:Update()
    end
end)

updateFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
updateFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
updateFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
updateFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
updateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
updateFrame:RegisterEvent("UPDATE_BINDINGS")
