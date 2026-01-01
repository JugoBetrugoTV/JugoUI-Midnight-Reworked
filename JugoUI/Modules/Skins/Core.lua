--[[
    JugoUI - Skins/Core.lua
    UI skinning module
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local SK = E:NewModule("Skins", "AceHook-3.0", "AceEvent-3.0")
E.Skins = SK

SK.skinnedFrames = {}

function SK:OnInitialize()
    self.db = E.db.skins
end

function SK:OnEnable()
    if self.db.blizzard.enabled then
        self:SkinBlizzardFrames()
    end

    if self.db.addons.enabled then
        self:RegisterEvent("ADDON_LOADED")
    end
end

-- Helper: Skin a frame
function SK:SkinFrame(frame, template)
    if not frame or self.skinnedFrames[frame] then return end

    template = template or "Default"

    if template == "Default" then
        if frame.SetBackdrop then
            frame:SetBackdrop({
                bgFile = E.media.textures.flat,
                edgeFile = E.media.textures.flat,
                edgeSize = 1,
            })
            frame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
            frame:SetBackdropBorderColor(0.2, 0.2, 0.2)
        end
    elseif template == "Transparent" then
        if frame.SetBackdrop then
            frame:SetBackdrop({
                bgFile = E.media.textures.flat,
                edgeFile = E.media.textures.flat,
                edgeSize = 1,
            })
            frame:SetBackdropColor(0.03, 0.03, 0.03, 0.7)
            frame:SetBackdropBorderColor(0.15, 0.15, 0.15)
        end
    end

    self.skinnedFrames[frame] = true
end

-- Helper: Skin a button
function SK:SkinButton(button)
    if not button or self.skinnedFrames[button] then return end

    -- Remove default textures
    if button.Left then button.Left:SetAlpha(0) end
    if button.Right then button.Right:SetAlpha(0) end
    if button.Middle then button.Middle:SetAlpha(0) end

    -- Remove highlight texture and replace
    if button:GetHighlightTexture() then
        button:GetHighlightTexture():SetColorTexture(1, 1, 1, 0.1)
    end

    -- Apply backdrop
    if not button.backdrop then
        button.backdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.backdrop:SetPoint("TOPLEFT", 1, -1)
        button.backdrop:SetPoint("BOTTOMRIGHT", -1, 1)
        button.backdrop:SetFrameLevel(button:GetFrameLevel() - 1)
        button.backdrop:SetBackdrop({
            bgFile = E.media.textures.flat,
            edgeFile = E.media.textures.flat,
            edgeSize = 1,
        })
        button.backdrop:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        button.backdrop:SetBackdropBorderColor(0.3, 0.3, 0.3)
    end

    self.skinnedFrames[button] = true
end

-- Helper: Skin a close button
function SK:SkinCloseButton(button)
    if not button then return end

    self:SkinButton(button)

    -- Style the X
    if button:GetNormalTexture() then
        button:GetNormalTexture():SetVertexColor(1, 0.2, 0.2)
    end
end

-- Helper: Skin a scroll bar
function SK:SkinScrollBar(scrollBar)
    if not scrollBar or self.skinnedFrames[scrollBar] then return end

    -- Hide default textures
    local name = scrollBar:GetName()
    if name then
        local track = _G[name .. "Track"]
        if track then track:SetAlpha(0) end
        local top = _G[name .. "Top"]
        if top then top:SetAlpha(0) end
        local bottom = _G[name .. "Bottom"]
        if bottom then bottom:SetAlpha(0) end
        local middle = _G[name .. "Middle"]
        if middle then middle:SetAlpha(0) end

        local up = _G[name .. "ScrollUpButton"]
        if up then self:SkinButton(up) end
        local down = _G[name .. "ScrollDownButton"]
        if down then self:SkinButton(down) end
    end

    self.skinnedFrames[scrollBar] = true
end

-- Helper: Skin a tab
function SK:SkinTab(tab)
    if not tab or self.skinnedFrames[tab] then return end

    -- Remove default textures
    if tab.Left then tab.Left:SetAlpha(0) end
    if tab.Right then tab.Right:SetAlpha(0) end
    if tab.Middle then tab.Middle:SetAlpha(0) end
    if tab.LeftDisabled then tab.LeftDisabled:SetAlpha(0) end
    if tab.RightDisabled then tab.RightDisabled:SetAlpha(0) end
    if tab.MiddleDisabled then tab.MiddleDisabled:SetAlpha(0) end

    -- Create backdrop
    if not tab.backdrop then
        tab.backdrop = CreateFrame("Frame", nil, tab, "BackdropTemplate")
        tab.backdrop:SetPoint("TOPLEFT", 5, -3)
        tab.backdrop:SetPoint("BOTTOMRIGHT", -5, 3)
        tab.backdrop:SetFrameLevel(tab:GetFrameLevel() - 1)
        tab.backdrop:SetBackdrop({
            bgFile = E.media.textures.flat,
            edgeFile = E.media.textures.flat,
            edgeSize = 1,
        })
        tab.backdrop:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        tab.backdrop:SetBackdropBorderColor(0.3, 0.3, 0.3)
    end

    self.skinnedFrames[tab] = true
end

-- Helper: Skin an edit box
function SK:SkinEditBox(editbox)
    if not editbox or self.skinnedFrames[editbox] then return end

    local name = editbox:GetName()
    if name then
        local left = _G[name .. "Left"]
        if left then left:SetAlpha(0) end
        local mid = _G[name .. "Mid"] or _G[name .. "Middle"]
        if mid then mid:SetAlpha(0) end
        local right = _G[name .. "Right"]
        if right then right:SetAlpha(0) end
    end

    editbox:SetBackdrop({
        bgFile = E.media.textures.flat,
        edgeFile = E.media.textures.flat,
        edgeSize = 1,
    })
    editbox:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    editbox:SetBackdropBorderColor(0.3, 0.3, 0.3)

    self.skinnedFrames[editbox] = true
end

-- Helper: Skin a dropdown
function SK:SkinDropDown(dropdown)
    if not dropdown or self.skinnedFrames[dropdown] then return end

    local name = dropdown:GetName()
    if name then
        local left = _G[name .. "Left"]
        if left then left:SetAlpha(0) end
        local middle = _G[name .. "Middle"]
        if middle then middle:SetAlpha(0) end
        local right = _G[name .. "Right"]
        if right then right:SetAlpha(0) end

        local button = _G[name .. "Button"]
        if button then self:SkinButton(button) end
    end

    dropdown:SetBackdrop({
        bgFile = E.media.textures.flat,
        edgeFile = E.media.textures.flat,
        edgeSize = 1,
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    dropdown:SetBackdropBorderColor(0.3, 0.3, 0.3)

    self.skinnedFrames[dropdown] = true
end

-- Helper: Skin a status bar
function SK:SkinStatusBar(statusbar)
    if not statusbar or self.skinnedFrames[statusbar] then return end

    statusbar:SetStatusBarTexture(E.media.textures.flat)

    if not statusbar.bg then
        statusbar.bg = statusbar:CreateTexture(nil, "BACKGROUND")
        statusbar.bg:SetAllPoints()
        statusbar.bg:SetTexture(E.media.textures.flat)
        statusbar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    end

    self.skinnedFrames[statusbar] = true
end

function SK:ADDON_LOADED(event, addon)
    self:SkinAddon(addon)
end

function SK:ProfileChanged()
    self.db = E.db.skins
end
