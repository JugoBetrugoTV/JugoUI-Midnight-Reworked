--[[
    JugoUI - Chat/Core.lua
    Chat enhancement module
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local CH = E:NewModule("Chat", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
E.Chat = CH

local gsub = string.gsub

-- Channel abbreviations
local SHORT_CHANNELS = {
    ["Schlachtfeld"] = "[BG]",
    ["Battleground"] = "[BG]",
    ["Gilde"] = "[G]",
    ["Guild"] = "[G]",
    ["Gruppe"] = "[P]",
    ["Party"] = "[P]",
    ["Schlachtzug"] = "[R]",
    ["Raid"] = "[R]",
    ["Schlachtzugsleiter"] = "[RL]",
    ["Raid Leader"] = "[RL]",
    ["Instanz"] = "[I]",
    ["Instance"] = "[I]",
    ["Instanzführer"] = "[IL]",
    ["Instance Leader"] = "[IL]",
    ["Offizier"] = "[O]",
    ["Officer"] = "[O]",
    ["Allgemein"] = "[1]",
    ["General"] = "[1]",
    ["Handel"] = "[2]",
    ["Trade"] = "[2]",
    ["Weltverteidigung"] = "[WD]",
    ["WorldDefense"] = "[WD]",
    ["LokaleVerteidigung"] = "[LD]",
    ["LocalDefense"] = "[LD]",
    ["SucheNachGruppe"] = "[LFG]",
    ["LookingForGroup"] = "[LFG]",
}

function CH:OnInitialize()
    self.db = E.db.chat
end

function CH:OnEnable()
    self:StyleChat()
    self:RegisterEvent("CHAT_MSG_CHANNEL")
    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("CHAT_MSG_BN_WHISPER")

    -- Hook message formatting
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        if frame then
            self:HookChatFrame(frame)
        end
    end
end

function CH:OnDisable()
    -- Unhook all
end

function CH:StyleChat()
    local db = self.db

    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        local tab = _G["ChatFrame" .. i .. "Tab"]

        if frame then
            -- Style chat frame
            frame:SetFont(E:GetFont(db.font), db.fontSize, db.fontOutline)
            frame:SetClampedToScreen(true)
            frame:SetClampRectInsets(-10, 10, 30, -10)
            frame:SetMaxLines(db.historySize)
            frame:SetFading(true)
            frame:SetTimeVisible(db.fadeTime)

            -- Remove textures
            for _, texName in pairs({"Background", "TopLeftTexture", "TopRightTexture", "BottomLeftTexture", "BottomRightTexture", "LeftTexture", "RightTexture", "TopTexture", "BottomTexture"}) do
                local tex = _G["ChatFrame" .. i .. texName]
                if tex then tex:SetTexture(nil) end
            end

            -- Add custom backdrop
            if not frame.backdrop then
                frame.backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
                frame.backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", -5, 5)
                frame.backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 5, -5)
                frame.backdrop:SetFrameStrata("BACKGROUND")
                frame.backdrop:SetBackdrop({
                    bgFile = E.media.textures.flat,
                    edgeFile = E.media.textures.flat,
                    edgeSize = 1,
                })
                frame.backdrop:SetBackdropColor(0.03, 0.03, 0.03, 0.7)
                frame.backdrop:SetBackdropBorderColor(0.1, 0.1, 0.1, 0.5)
            end
        end

        if tab then
            -- Style tab
            tab:SetAlpha(1)
            local tabText = _G["ChatFrame" .. i .. "TabText"]
            if tabText then
                tabText:SetFont(E:GetFont(db.font), db.tabFontSize, "OUTLINE")
            end

            -- Remove tab textures
            for _, texName in pairs({"Left", "Middle", "Right", "SelectedLeft", "SelectedMiddle", "SelectedRight", "HighlightLeft", "HighlightMiddle", "HighlightRight", "ActiveLeft", "ActiveMiddle", "ActiveRight"}) do
                local tex = _G["ChatFrame" .. i .. "Tab" .. texName]
                if tex then tex:SetTexture(nil) end
            end
        end
    end

    -- Style edit box
    local editBox = ChatFrame1EditBox
    if editBox then
        editBox:ClearAllPoints()
        if db.editBoxPosition == "BELOW" then
            editBox:SetPoint("TOPLEFT", ChatFrame1, "BOTTOMLEFT", -5, -5)
            editBox:SetPoint("TOPRIGHT", ChatFrame1, "BOTTOMRIGHT", 5, -5)
        else
            editBox:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", -5, 5)
            editBox:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 5, 5)
        end
        editBox:SetHeight(22)
    end

    -- Hide buttons if configured
    if not db.showButtons then
        ChatFrameMenuButton:Hide()
        ChatFrameChannelButton:Hide()
        QuickJoinToastButton:Hide()
    end
end

function CH:HookChatFrame(frame)
    if frame.hooked then return end

    local oldAddMessage = frame.AddMessage
    frame.AddMessage = function(self, msg, ...)
        if msg then
            msg = CH:ProcessMessage(msg)
        end
        return oldAddMessage(self, msg, ...)
    end

    frame.hooked = true
end

function CH:ProcessMessage(msg)
    local db = self.db

    -- Shorten channel names
    if db.shortChannels then
        for long, short in pairs(SHORT_CHANNELS) do
            msg = gsub(msg, "%[" .. long .. "%]", short)
            msg = gsub(msg, long .. ":", short)
        end
    end

    -- Make URLs clickable
    if db.copyURL then
        msg = self:ParseURLs(msg)
    end

    return msg
end

function CH:ParseURLs(msg)
    -- Match various URL patterns
    msg = gsub(msg, "(https?://[%w_.~!*:@&+$/?%%#=-]+)", "|cff00ffff|Hurl:%1|h[%1]|h|r")
    msg = gsub(msg, "(www%.[%w_.~!*:@&+$/?%%#=-]+)", "|cff00ffff|Hurl:http://%1|h[%1]|h|r")
    return msg
end

function CH:CHAT_MSG_WHISPER(event, msg, author, ...)
    if self.db.whisperSound then
        PlaySound(567455, "Master") -- UI_BnetToast
    end
end

function CH:CHAT_MSG_BN_WHISPER(event, msg, author, ...)
    if self.db.whisperSound then
        PlaySound(567455, "Master")
    end
end

function CH:CHAT_MSG_CHANNEL()
    -- Future: channel-specific handling
end

-- Timestamp formatting
function CH:AddTimestamp(msg)
    if self.db.customTimestamps then
        local timestamp = date(self.db.timestampFormat)
        return "|cff888888" .. timestamp .. "|r" .. msg
    end
    return msg
end

function CH:ProfileChanged()
    self.db = E.db.chat
    self:StyleChat()
end
