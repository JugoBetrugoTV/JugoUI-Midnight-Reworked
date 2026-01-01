--[[
    JugoUI - Bags/Core.lua
    Bag replacement module
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local B = E:NewModule("Bags", "AceEvent-3.0", "AceHook-3.0")
E.Bags = B

B.BagFrame = nil
B.BankFrame = nil
B.slots = {}

function B:OnInitialize()
    self.db = E.db.bags
end

function B:OnEnable()
    self:CreateBagFrame()
    self:HookBlizzardBags()

    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("BAG_UPDATE_DELAYED")
    self:RegisterEvent("ITEM_LOCK_CHANGED")
    self:RegisterEvent("QUEST_ACCEPTED")
    self:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
end

function B:OnDisable()
    if self.BagFrame then
        self.BagFrame:Hide()
    end
end

function B:CreateBagFrame()
    local db = self.db
    local frame = CreateFrame("Frame", "JugoUI_Bags", UIParent, "BackdropTemplate")

    local numSlots = self:GetNumBagSlots()
    local cols = db.bagWidth
    local rows = ceil(numSlots / cols)
    local size = db.buttonSize
    local spacing = db.buttonSpacing

    local width = cols * size + (cols - 1) * spacing + 20
    local height = rows * size + (rows - 1) * spacing + 60

    frame:SetSize(width, height)

    local point = db.bagPoint
    frame:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)

    frame:SetBackdrop({
        bgFile = E.media.textures.flat,
        edgeFile = E.media.textures.flat,
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2)

    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetFrameStrata("HIGH")
    frame:Hide()

    -- Title
    frame.title = E:CreateFontString(frame, 14, "OUTLINE")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -8)
    frame.title:SetText("Bags")

    -- Close button
    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    frame.closeButton:SetScript("OnClick", function() B:CloseBags() end)

    -- Gold display
    frame.gold = E:CreateFontString(frame, 12, "OUTLINE")
    frame.gold:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)

    -- Search box
    frame.search = CreateFrame("EditBox", "JugoUI_BagSearch", frame, "SearchBoxTemplate")
    frame.search:SetSize(150, 20)
    frame.search:SetPoint("TOPRIGHT", frame.closeButton, "TOPLEFT", -10, -5)
    frame.search:SetScript("OnTextChanged", function(self)
        B:SearchBags(self:GetText())
    end)

    -- Create slots
    frame.slots = {}
    self:CreateSlots(frame)

    -- Drag functionality
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
    end)

    self.BagFrame = frame
end

function B:GetNumBagSlots()
    local numSlots = 0
    for bag = 0, 4 do
        numSlots = numSlots + C_Container.GetContainerNumSlots(bag)
    end
    return numSlots
end

function B:CreateSlots(frame)
    local db = self.db
    local size = db.buttonSize
    local spacing = db.buttonSpacing
    local cols = db.bagWidth

    local slotIndex = 1
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local button = self:CreateSlot(frame, bag, slot, slotIndex)
            frame.slots[slotIndex] = button

            local row = floor((slotIndex - 1) / cols)
            local col = (slotIndex - 1) % cols

            button:SetPoint("TOPLEFT", frame, "TOPLEFT", 10 + col * (size + spacing), -40 - row * (size + spacing))

            slotIndex = slotIndex + 1
        end
    end
end

function B:CreateSlot(parent, bag, slot, index)
    local db = self.db
    local size = db.buttonSize
    local name = "JugoUI_BagSlot" .. index

    local button = CreateFrame("Button", name, parent, "ContainerFrameItemButtonTemplate")
    button:SetSize(size, size)
    button.bag = bag
    button.slot = slot

    -- Style
    button:SetNormalTexture(nil)
    button:SetPushedTexture(nil)

    if button.icon then
        button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    button.border = E:CreateBackdrop(button, "Default")

    -- Item level text
    button.ilvl = E:CreateFontString(button, 10, "OUTLINE")
    button.ilvl:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 2)

    -- New item glow
    button.newGlow = button:CreateTexture(nil, "OVERLAY")
    button.newGlow:SetAllPoints()
    button.newGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    button.newGlow:SetBlendMode("ADD")
    button.newGlow:SetVertexColor(0.3, 0.9, 0.3, 0.8)
    button.newGlow:Hide()

    self.slots[name] = button
    return button
end

function B:UpdateSlot(button)
    local bag = button.bag
    local slot = button.slot
    local db = self.db

    local info = C_Container.GetContainerItemInfo(bag, slot)

    if info then
        button.icon:SetTexture(info.iconFileID)
        button.icon:Show()

        -- Count
        if info.stackCount > 1 then
            button.Count:SetText(info.stackCount)
            button.Count:Show()
        else
            button.Count:Hide()
        end

        -- Quality border
        if db.qualityColors and info.quality and info.quality > 1 then
            local color = E.media.colors.quality[info.quality]
            if color then
                button.border:SetBackdropBorderColor(color[1], color[2], color[3])
            end
        else
            button.border:SetBackdropBorderColor(0.2, 0.2, 0.2)
        end

        -- Item level
        if db.showItemLevel and info.itemLink then
            local ilvl = C_Item.GetCurrentItemLevel(info.itemLink)
            if ilvl and ilvl > 1 then
                button.ilvl:SetText(ilvl)
            else
                button.ilvl:SetText("")
            end
        end

        -- New item
        if C_NewItems and C_NewItems.IsNewItem(bag, slot) then
            button.newGlow:Show()
        else
            button.newGlow:Hide()
        end
    else
        button.icon:Hide()
        button.Count:Hide()
        button.ilvl:SetText("")
        button.newGlow:Hide()
        button.border:SetBackdropBorderColor(0.2, 0.2, 0.2)
    end
end

function B:UpdateBags()
    if not self.BagFrame then return end

    for _, button in pairs(self.BagFrame.slots) do
        self:UpdateSlot(button)
    end

    -- Update gold
    local gold = GetMoney()
    self.BagFrame.gold:SetText(GetCoinTextureString(gold))
end

function B:OpenBags()
    if not self.BagFrame then return end
    self.BagFrame:Show()
    self:UpdateBags()
end

function B:CloseBags()
    if not self.BagFrame then return end
    self.BagFrame:Hide()
end

function B:ToggleBags()
    if self.BagFrame and self.BagFrame:IsShown() then
        self:CloseBags()
    else
        self:OpenBags()
    end
end

function B:SearchBags(text)
    if not self.BagFrame then return end
    text = text and text:lower() or ""

    for _, button in pairs(self.BagFrame.slots) do
        local info = C_Container.GetContainerItemInfo(button.bag, button.slot)
        if info and info.itemLink then
            local name = C_Item.GetItemInfo(info.itemLink)
            if name and name:lower():find(text, 1, true) then
                button:SetAlpha(1)
            else
                button:SetAlpha(0.3)
            end
        else
            button:SetAlpha(1)
        end
    end
end

function B:HookBlizzardBags()
    self:RawHook("OpenAllBags", function() self:OpenBags() end, true)
    self:RawHook("CloseAllBags", function() self:CloseBags() end, true)
    self:RawHook("ToggleAllBags", function() self:ToggleBags() end, true)
end

function B:BAG_UPDATE()
    self:UpdateBags()
end

function B:BAG_UPDATE_DELAYED()
    self:UpdateBags()
end

function B:ITEM_LOCK_CHANGED()
    self:UpdateBags()
end

function B:QUEST_ACCEPTED()
    self:UpdateBags()
end

function B:UNIT_QUEST_LOG_CHANGED()
    self:UpdateBags()
end

function B:ProfileChanged()
    self.db = E.db.bags
end
