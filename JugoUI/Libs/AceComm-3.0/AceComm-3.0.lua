--[[ AceComm-3.0 - A library for sending and receiving messages
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceComm-3.0", 12
local AceComm = LibStub:NewLibrary(MAJOR, MINOR)
if not AceComm then return end

local CallbackHandler = LibStub("CallbackHandler-1.0")

AceComm.embeds = AceComm.embeds or {}
AceComm.frame = AceComm.frame or CreateFrame("Frame")

local type = type
local pairs = pairs
local tostring = tostring
local strsub = string.sub
local strlen = string.len
local strfind = string.find
local format = string.format

local COMM_TYPES = {
    ["PARTY"] = true,
    ["RAID"] = true,
    ["GUILD"] = true,
    ["OFFICER"] = true,
    ["BATTLEGROUND"] = true,
    ["WHISPER"] = true,
    ["CHANNEL"] = true,
    ["SAY"] = true,
    ["YELL"] = true,
}

local messageQueue = {}
local messageRegistry = CallbackHandler:New(AceComm, "RegisterComm", "UnregisterComm", "UnregisterAllComm")

function AceComm:SendCommMessage(prefix, message, distribution, target, prio, callbackFn, callbackArg)
    if type(prefix) ~= "string" then
        error("Usage: SendCommMessage(prefix, message, distribution, target, prio, callbackFn, callbackArg): 'prefix' - string expected", 2)
    end
    if type(message) ~= "string" then
        error("Usage: SendCommMessage(prefix, message, distribution, target, prio, callbackFn, callbackArg): 'message' - string expected", 2)
    end
    if type(distribution) ~= "string" then
        error("Usage: SendCommMessage(prefix, message, distribution, target, prio, callbackFn, callbackArg): 'distribution' - string expected", 2)
    end
    if not COMM_TYPES[distribution:upper()] then
        error("Usage: SendCommMessage(prefix, message, distribution, target, prio, callbackFn, callbackArg): 'distribution' - invalid type", 2)
    end

    distribution = distribution:upper()

    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(prefix, message, distribution, target)
    end
end

function AceComm:OnEvent(event, prefix, message, distribution, sender)
    if event == "CHAT_MSG_ADDON" then
        messageRegistry:Fire(prefix, message, distribution, sender)
    end
end

AceComm.frame:RegisterEvent("CHAT_MSG_ADDON")
AceComm.frame:SetScript("OnEvent", function(self, event, ...)
    AceComm:OnEvent(event, ...)
end)

if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix("JugoUI")
end

local mixins = {
    "SendCommMessage", "RegisterComm", "UnregisterComm", "UnregisterAllComm"
}

function AceComm:Embed(target)
    for _, v in pairs(mixins) do
        target[v] = self[v]
    end
    self.embeds[target] = true
    return target
end

for addon in pairs(AceComm.embeds) do
    AceComm:Embed(addon)
end
