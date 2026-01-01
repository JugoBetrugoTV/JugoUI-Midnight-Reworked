--[[
    JugoUI - InfoBar/Core.lua
    Data bar module (top/bottom info panels)
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local IB = E:NewModule("InfoBar", "AceEvent-3.0", "AceTimer-3.0")
E.InfoBar = IB

IB.panels = {}
IB.dataTexts = {}

function IB:OnInitialize()
    self.db = E.db.infobar
end

function IB:OnEnable()
    if self.db.topPanel then
        self:CreatePanel("top")
    end
    if self.db.bottomPanel then
        self:CreatePanel("bottom")
    end

    self:RegisterDataTexts()
    self:UpdatePanels()
end

function IB:CreatePanel(position)
    local db = self.db
    local name = "JugoUI_InfoBar_" .. position:gsub("^%l", string.upper)

    local panel = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    panel:SetHeight(db.height)

    if position == "top" then
        panel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        panel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
    else
        panel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
        panel:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    end

    panel:SetBackdrop({
        bgFile = E.media.textures.flat,
        edgeFile = E.media.textures.flat,
        edgeSize = 1,
    })
    panel:SetBackdropColor(0.03, 0.03, 0.03, 0.8)
    panel:SetBackdropBorderColor(0.1, 0.1, 0.1)

    panel.dataTexts = {}
    self.panels[position] = panel
end

function IB:RegisterDataTexts()
    -- Durability
    self:RegisterDataText("Durability", {
        events = {"UPDATE_INVENTORY_DURABILITY"},
        update = function(self)
            local min = 100
            for i = 1, 18 do
                local current, maximum = GetInventoryItemDurability(i)
                if current and maximum and maximum > 0 then
                    min = math.min(min, (current / maximum) * 100)
                end
            end
            self.text:SetFormattedText("Dur: %.0f%%", min)
        end,
    })

    -- Gold
    self:RegisterDataText("Gold", {
        events = {"PLAYER_MONEY"},
        update = function(self)
            local gold = floor(GetMoney() / 10000)
            self.text:SetText(E:CommaValue(gold) .. "g")
        end,
    })

    -- Bags
    self:RegisterDataText("Bags", {
        events = {"BAG_UPDATE"},
        update = function(self)
            local free, total = 0, 0
            for i = 0, 4 do
                free = free + C_Container.GetContainerNumFreeSlots(i)
                total = total + C_Container.GetContainerNumSlots(i)
            end
            self.text:SetFormattedText("Bags: %d/%d", free, total)
        end,
    })

    -- FPS
    self:RegisterDataText("FPS", {
        onUpdate = 1,
        update = function(self)
            self.text:SetFormattedText("FPS: %d", floor(GetFramerate()))
        end,
    })

    -- Latency
    self:RegisterDataText("Latency", {
        onUpdate = 5,
        update = function(self)
            local _, _, home, world = GetNetStats()
            self.text:SetFormattedText("MS: %d / %d", home, world)
        end,
    })

    -- Time
    self:RegisterDataText("Time", {
        onUpdate = 1,
        update = function(self)
            local hour, minute = GetGameTime()
            self.text:SetFormattedText("%02d:%02d", hour, minute)
        end,
    })

    -- Friends
    self:RegisterDataText("Friends", {
        events = {"FRIENDLIST_UPDATE", "BN_FRIEND_INFO_CHANGED"},
        update = function(self)
            local numBNOnline = select(2, BNGetNumFriends())
            local numOnline = C_FriendList.GetNumOnlineFriends()
            self.text:SetFormattedText("Friends: %d", numBNOnline + numOnline)
        end,
        onClick = function()
            ToggleFriendsFrame(1)
        end,
    })

    -- Guild
    self:RegisterDataText("Guild", {
        events = {"GUILD_ROSTER_UPDATE"},
        update = function(self)
            local numOnline = select(3, GetNumGuildMembers())
            if IsInGuild() then
                self.text:SetFormattedText("Guild: %d", numOnline or 0)
            else
                self.text:SetText("No Guild")
            end
        end,
        onClick = function()
            ToggleGuildFrame()
        end,
    })

    -- Talents
    self:RegisterDataText("Talents", {
        events = {"PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED"},
        update = function(self)
            local spec = GetSpecialization()
            if spec then
                local _, name = GetSpecializationInfo(spec)
                self.text:SetText(name or "None")
            else
                self.text:SetText("No Spec")
            end
        end,
        onClick = function()
            ToggleTalentFrame()
        end,
    })

    -- Loot
    self:RegisterDataText("Loot", {
        events = {"PLAYER_LOOT_SPEC_UPDATED"},
        update = function(self)
            local lootSpec = GetLootSpecialization()
            if lootSpec and lootSpec > 0 then
                local _, name = GetSpecializationInfoByID(lootSpec)
                self.text:SetText("Loot: " .. (name or "?"))
            else
                self.text:SetText("Loot: Current")
            end
        end,
    })

    -- Volume
    self:RegisterDataText("Volume", {
        events = {"CVAR_UPDATE"},
        update = function(self)
            local volume = tonumber(GetCVar("Sound_MasterVolume")) or 0
            self.text:SetFormattedText("Vol: %.0f%%", volume * 100)
        end,
        onClick = function()
            Settings.OpenToCategory("Audio")
        end,
    })
end

function IB:RegisterDataText(name, data)
    self.dataTexts[name] = data
end

function IB:UpdatePanels()
    local db = self.db

    -- Update top panel
    if self.panels.top then
        self:PopulatePanel(self.panels.top, db.topLeft, "LEFT")
        self:PopulatePanel(self.panels.top, db.topRight, "RIGHT")
    end

    -- Update bottom panel
    if self.panels.bottom then
        self:PopulatePanel(self.panels.bottom, db.bottomLeft, "LEFT")
        self:PopulatePanel(self.panels.bottom, db.bottomRight, "RIGHT")
    end
end

function IB:PopulatePanel(panel, elements, side)
    local db = self.db

    for i, elementName in ipairs(elements) do
        local data = self.dataTexts[elementName]
        if data then
            local frame = self:CreateDataTextFrame(panel, elementName, data)

            frame:ClearAllPoints()
            if side == "LEFT" then
                if i == 1 then
                    frame:SetPoint("LEFT", panel, "LEFT", 10, 0)
                else
                    local prev = panel.dataTexts[elements[i - 1]]
                    if prev then
                        frame:SetPoint("LEFT", prev, "RIGHT", 20, 0)
                    end
                end
            else
                if i == 1 then
                    frame:SetPoint("RIGHT", panel, "RIGHT", -10, 0)
                else
                    local prev = panel.dataTexts[elements[i - 1]]
                    if prev then
                        frame:SetPoint("RIGHT", prev, "LEFT", -20, 0)
                    end
                end
            end

            panel.dataTexts[elementName] = frame
        end
    end
end

function IB:CreateDataTextFrame(parent, name, data)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(100, parent:GetHeight())

    frame.text = E:CreateFontString(frame, self.db.fontSize, "OUTLINE")
    frame.text:SetPoint("CENTER")

    if data.events then
        for _, event in ipairs(data.events) do
            frame:RegisterEvent(event)
        end
        frame:SetScript("OnEvent", function()
            data.update(frame)
        end)
    end

    if data.onUpdate then
        self:ScheduleRepeatingTimer(function()
            data.update(frame)
        end, data.onUpdate)
    end

    if data.onClick then
        frame:SetScript("OnClick", data.onClick)
    end

    -- Initial update
    data.update(frame)

    return frame
end

function IB:ProfileChanged()
    self.db = E.db.infobar
    self:UpdatePanels()
end
