--[[
    JugoUI - Misc/Core.lua
    Quality of Life improvements
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local MISC = E:NewModule("Misc", "AceEvent-3.0", "AceHook-3.0")
E.Misc = MISC

function MISC:OnInitialize()
    self.db = E.db.misc
end

function MISC:OnEnable()
    -- Auto repair
    if self.db.autoRepair then
        self:RegisterEvent("MERCHANT_SHOW")
    end

    -- Auto sell junk
    if self.db.autoSellJunk then
        self:RegisterEvent("MERCHANT_SHOW", "AutoSellJunk")
    end

    -- Fast loot
    if self.db.fastLoot then
        self:EnableFastLoot()
    end

    -- Combat alert
    if self.db.combatAlert then
        self:RegisterEvent("PLAYER_REGEN_DISABLED", "CombatAlert")
        self:RegisterEvent("PLAYER_REGEN_ENABLED", "CombatAlert")
    end

    -- Interrupt announce
    if self.db.interruptAnnounce then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end

    -- AFK camera
    if self.db.afkCamera then
        self:RegisterEvent("PLAYER_FLAGS_CHANGED")
    end

    -- Enhanced mail
    if self.db.enhancedMail then
        self:HookScript(MailFrame, "OnShow", "EnhanceMail")
    end

    -- Hide errors
    if self.db.hideErrors then
        UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
    end
end

function MISC:MERCHANT_SHOW()
    local db = self.db

    -- Auto repair
    if db.autoRepair and CanMerchantRepair() then
        local cost = GetRepairAllCost()
        if cost > 0 then
            local useGuild = db.autoRepairGuild and IsInGuild() and CanGuildBankRepair()
            if useGuild then
                local guildMoney = GetGuildBankWithdrawMoney()
                if guildMoney >= cost or guildMoney == -1 then
                    RepairAllItems(true)
                    E:Print("Repaired using guild funds:", GetCoinTextureString(cost))
                    return
                end
            end

            if GetMoney() >= cost then
                RepairAllItems(false)
                E:Print("Repaired:", GetCoinTextureString(cost))
            end
        end
    end
end

function MISC:AutoSellJunk()
    local totalPrice = 0

    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.quality == Enum.ItemQuality.Poor and not info.isLocked then
                local price = select(11, C_Item.GetItemInfo(info.itemLink))
                if price and price > 0 then
                    totalPrice = totalPrice + (price * info.stackCount)
                    C_Container.UseContainerItem(bag, slot)
                end
            end
        end
    end

    if totalPrice > 0 then
        E:Print("Sold junk:", GetCoinTextureString(totalPrice))
    end
end

function MISC:EnableFastLoot()
    local delay = 0

    local function FastLoot()
        if GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE") then
            if GetTime() - delay >= 0.3 then
                delay = GetTime()
                for i = GetNumLootItems(), 1, -1 do
                    LootSlot(i)
                end
            end
        end
    end

    self:RegisterEvent("LOOT_READY", FastLoot)
end

function MISC:CombatAlert(event)
    if event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat
        RaidNotice_AddMessage(RaidBossEmoteFrame, "|cffff0000COMBAT|r", ChatTypeInfo["RAID_WARNING"])
        PlaySound(8959, "Master")
    else
        -- Leaving combat
        RaidNotice_AddMessage(RaidBossEmoteFrame, "|cff00ff00SAFE|r", ChatTypeInfo["RAID_WARNING"])
    end
end

function MISC:COMBAT_LOG_EVENT_UNFILTERED()
    local _, event, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()

    if event == "SPELL_INTERRUPT" and sourceGUID == UnitGUID("player") then
        local msg = format("Interrupted %s's %s!", destName or "Unknown", spellName or "Unknown")

        if IsInGroup() then
            local channel = IsInRaid() and "RAID" or "PARTY"
            SendChatMessage(msg, channel)
        end
    end
end

function MISC:PLAYER_FLAGS_CHANGED(event, unit)
    if unit ~= "player" then return end

    if UnitIsAFK("player") then
        -- Start AFK camera
        if not self.afkFrame then
            self:CreateAFKFrame()
        end
        self.afkFrame:Show()
        UIParent:Hide()
    else
        -- Stop AFK camera
        if self.afkFrame then
            self.afkFrame:Hide()
        end
        UIParent:Show()
    end
end

function MISC:CreateAFKFrame()
    local frame = CreateFrame("Frame", "JugoUI_AFKFrame", WorldFrame)
    frame:SetAllPoints(WorldFrame)
    frame:SetFrameStrata("FULLSCREEN")

    -- Player model
    frame.model = CreateFrame("PlayerModel", nil, frame)
    frame.model:SetSize(600, 600)
    frame.model:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 200, -200)
    frame.model:SetUnit("player")
    frame.model:SetRotation(math.rad(-15))
    frame.model:SetAnimation(0)

    -- Bottom bar
    frame.bar = CreateFrame("Frame", nil, frame)
    frame.bar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.bar:SetHeight(100)

    frame.bar.bg = frame.bar:CreateTexture(nil, "BACKGROUND")
    frame.bar.bg:SetAllPoints()
    frame.bar.bg:SetTexture(E.media.textures.flat)
    frame.bar.bg:SetGradient("VERTICAL", CreateColor(0, 0, 0, 1), CreateColor(0, 0, 0, 0))

    -- Name
    frame.name = E:CreateFontString(frame.bar, 24, "OUTLINE")
    frame.name:SetPoint("BOTTOMLEFT", frame.bar, "BOTTOMLEFT", 20, 50)
    frame.name:SetText(E:UnitNameWithColor("player"))

    -- Guild
    frame.guild = E:CreateFontString(frame.bar, 14, "OUTLINE")
    frame.guild:SetPoint("TOPLEFT", frame.name, "BOTTOMLEFT", 0, -5)
    local guildName = GetGuildInfo("player")
    if guildName then
        frame.guild:SetText("<" .. guildName .. ">")
    end

    -- Time
    frame.time = E:CreateFontString(frame.bar, 18, "OUTLINE")
    frame.time:SetPoint("BOTTOMRIGHT", frame.bar, "BOTTOMRIGHT", -20, 50)

    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 1 then
            self.elapsed = 0
            self.time:SetText(date("%H:%M:%S"))
        end
    end)

    -- Click to exit
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function()
        if UnitIsAFK("player") then
            SendChatMessage("", "AFK")
        end
    end)

    frame:Hide()
    self.afkFrame = frame
end

function MISC:EnhanceMail()
    -- Add open all button
    if not InboxFrame.openAllButton then
        local button = CreateFrame("Button", nil, InboxFrame, "UIPanelButtonTemplate")
        button:SetSize(100, 22)
        button:SetPoint("BOTTOM", InboxFrame, "BOTTOM", 0, 100)
        button:SetText("Open All")
        button:SetScript("OnClick", function()
            MISC:OpenAllMail()
        end)
        InboxFrame.openAllButton = button
    end
end

function MISC:OpenAllMail()
    local numItems = GetInboxNumItems()
    if numItems == 0 then return end

    for i = 1, numItems do
        local _, _, _, _, money, cod, _, hasItem = GetInboxHeaderInfo(i)
        if cod == 0 then
            if hasItem then
                AutoLootMailItem(i)
            end
            if money > 0 then
                TakeInboxMoney(i)
            end
        end
    end
end

function MISC:ProfileChanged()
    self.db = E.db.misc
end
