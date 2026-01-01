--[[ AceEvent-3.0 - Provides event registration and secure dispatching
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceEvent-3.0", 4
local AceEvent = LibStub:NewLibrary(MAJOR, MINOR)
if not AceEvent then return end

local CallbackHandler = LibStub("CallbackHandler-1.0")

AceEvent.frame = AceEvent.frame or CreateFrame("Frame")
AceEvent.embeds = AceEvent.embeds or {}

local eventRegistry = CallbackHandler:New(AceEvent, "RegisterEvent", "UnregisterEvent", "UnregisterAllEvents")

function eventRegistry:OnUsed(target, eventname)
    AceEvent.frame:RegisterEvent(eventname)
end

function eventRegistry:OnUnused(target, eventname)
    AceEvent.frame:UnregisterEvent(eventname)
end

local messageRegistry = CallbackHandler:New(AceEvent, "RegisterMessage", "UnregisterMessage", "UnregisterAllMessages")

local mixins = {
    "RegisterEvent", "UnregisterEvent", "UnregisterAllEvents",
    "RegisterMessage", "UnregisterMessage", "UnregisterAllMessages",
    "SendMessage"
}

function AceEvent:Embed(target)
    for _, v in pairs(mixins) do
        target[v] = self[v]
    end
    self.embeds[target] = true
    return target
end

function AceEvent:OnEmbedDisable(target)
    target:UnregisterAllEvents()
    target:UnregisterAllMessages()
end

function AceEvent:SendMessage(message, ...)
    if type(message) ~= "string" then
        error("Usage: SendMessage(message, ...): 'message' - string expected.", 2)
    end
    messageRegistry:Fire(message, ...)
end

AceEvent.frame:SetScript("OnEvent", function(this, event, ...)
    eventRegistry:Fire(event, ...)
end)

for addon in pairs(AceEvent.embeds) do
    AceEvent:Embed(addon)
end
