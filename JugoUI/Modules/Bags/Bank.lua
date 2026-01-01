--[[
    JugoUI - Bags/Bank.lua
    Bank frame
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local B = E.Bags

function B:CreateBankFrame()
    local db = self.db
    local frame = CreateFrame("Frame", "JugoUI_Bank", UIParent, "BackdropTemplate")

    local numSlots = self:GetNumBankSlots()
    local cols = db.bankWidth
    local rows = ceil(numSlots / cols)
    local size = db.buttonSize
    local spacing = db.buttonSpacing

    local width = cols * size + (cols - 1) * spacing + 20
    local height = rows * size + (rows - 1) * spacing + 60

    frame:SetSize(width, height)

    local point = db.bankPoint
    frame:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)

    frame:SetBackdrop({
        bgFile = E.media.textures.flat,
        edgeFile = E.media.textures.flat,
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2)

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetFrameStrata("HIGH")
    frame:Hide()

    frame.title = E:CreateFontString(frame, 14, "OUTLINE")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -8)
    frame.title:SetText("Bank")

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    frame.closeButton:SetScript("OnClick", function() B:CloseBank() end)

    self.BankFrame = frame
end

function B:GetNumBankSlots()
    local numSlots = NUM_BANKGENERIC_SLOTS or 28
    for bag = 5, 11 do
        numSlots = numSlots + C_Container.GetContainerNumSlots(bag)
    end
    return numSlots
end

function B:OpenBank()
    if not self.BankFrame then
        self:CreateBankFrame()
    end
    self.BankFrame:Show()
end

function B:CloseBank()
    if self.BankFrame then
        self.BankFrame:Hide()
    end
end
