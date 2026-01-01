--[[ LibSharedMedia-3.0 - A library for shared media like fonts, textures, and sounds
     https://www.wowace.com/projects/libsharedmedia-3-0 ]]

local MAJOR, MINOR = "LibSharedMedia-3.0", 8
local LibSharedMedia = LibStub:NewLibrary(MAJOR, MINOR)
if not LibSharedMedia then return end

local type = type
local pairs = pairs

LibSharedMedia.MediaTable = LibSharedMedia.MediaTable or {}
LibSharedMedia.DefaultMedia = LibSharedMedia.DefaultMedia or {}
LibSharedMedia.MediaList = LibSharedMedia.MediaList or {}
LibSharedMedia.callbacks = LibSharedMedia.callbacks or LibStub("CallbackHandler-1.0"):New(LibSharedMedia)

local MediaTable = LibSharedMedia.MediaTable
local DefaultMedia = LibSharedMedia.DefaultMedia
local MediaList = LibSharedMedia.MediaList

LibSharedMedia.MediaType = LibSharedMedia.MediaType or {}
local MediaType = LibSharedMedia.MediaType

MediaType.BACKGROUND = "background"
MediaType.BORDER = "border"
MediaType.FONT = "font"
MediaType.STATUSBAR = "statusbar"
MediaType.SOUND = "sound"

local SML_MT_font = MediaType.FONT
local SML_MT_sound = MediaType.SOUND
local SML_MT_statusbar = MediaType.STATUSBAR
local SML_MT_background = MediaType.BACKGROUND
local SML_MT_border = MediaType.BORDER

for _, t in pairs(MediaType) do
    MediaTable[t] = MediaTable[t] or {}
    MediaList[t] = MediaList[t] or {}
end

local function rebuildList(mediatype)
    local list = MediaList[mediatype]
    for k in pairs(list) do
        list[k] = nil
    end
    for k in pairs(MediaTable[mediatype]) do
        list[#list + 1] = k
    end
    table.sort(list)
end

function LibSharedMedia:Register(mediatype, key, data, langmask)
    if type(mediatype) ~= "string" then
        error("Usage: LibSharedMedia:Register(mediatype, key, data): 'mediatype' - string expected", 2)
    end
    if type(key) ~= "string" then
        error("Usage: LibSharedMedia:Register(mediatype, key, data): 'key' - string expected", 2)
    end

    mediatype = mediatype:lower()
    if not MediaTable[mediatype] then
        MediaTable[mediatype] = {}
        MediaList[mediatype] = {}
    end

    MediaTable[mediatype][key] = data
    rebuildList(mediatype)

    self.callbacks:Fire("LibSharedMedia_Registered", mediatype, key)
    return true
end

function LibSharedMedia:Fetch(mediatype, key, noDefault)
    if not MediaTable[mediatype] then
        return nil
    end

    local media = MediaTable[mediatype][key]
    if media then
        return media
    end

    if not noDefault then
        return MediaTable[mediatype][DefaultMedia[mediatype]]
    end

    return nil
end

function LibSharedMedia:IsValid(mediatype, key)
    return MediaTable[mediatype] and MediaTable[mediatype][key] and true or false
end

function LibSharedMedia:HashTable(mediatype)
    return MediaTable[mediatype]
end

function LibSharedMedia:List(mediatype)
    return MediaList[mediatype]
end

function LibSharedMedia:SetDefault(mediatype, key)
    if not MediaTable[mediatype] then
        return false
    end
    if not MediaTable[mediatype][key] then
        return false
    end

    DefaultMedia[mediatype] = key
    return true
end

function LibSharedMedia:GetDefault(mediatype)
    return DefaultMedia[mediatype]
end

function LibSharedMedia:GetGlobal(mediatype)
    return DefaultMedia[mediatype]
end

LibSharedMedia:Register(SML_MT_font, "Arial Narrow", "Fonts\\ARIALN.TTF")
LibSharedMedia:Register(SML_MT_font, "Friz Quadrata TT", "Fonts\\FRIZQT__.TTF")
LibSharedMedia:Register(SML_MT_font, "Morpheus", "Fonts\\MORPHEUS.TTF")
LibSharedMedia:Register(SML_MT_font, "Skurri", "Fonts\\SKURRI.TTF")

LibSharedMedia:Register(SML_MT_statusbar, "Blizzard", "Interface\\TargetingFrame\\UI-StatusBar")
LibSharedMedia:Register(SML_MT_statusbar, "Blizzard Character Skills Bar", "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
LibSharedMedia:Register(SML_MT_statusbar, "Blizzard Raid Bar", "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")

LibSharedMedia:Register(SML_MT_background, "Blizzard Dialog Background", "Interface\\DialogFrame\\UI-DialogBox-Background")
LibSharedMedia:Register(SML_MT_background, "Blizzard Dialog Background Dark", "Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
LibSharedMedia:Register(SML_MT_background, "Blizzard Dialog Background Gold", "Interface\\DialogFrame\\UI-DialogBox-Gold-Background")
LibSharedMedia:Register(SML_MT_background, "Blizzard Garrison Background", "Interface\\Garrison\\GarrisonUIBackground")
LibSharedMedia:Register(SML_MT_background, "Blizzard Low Health", "Interface\\FullScreenTextures\\LowHealth")
LibSharedMedia:Register(SML_MT_background, "Blizzard Marble", "Interface\\FrameGeneral\\UI-Background-Marble")
LibSharedMedia:Register(SML_MT_background, "Blizzard Out of Control", "Interface\\FullScreenTextures\\OutOfControl")
LibSharedMedia:Register(SML_MT_background, "Blizzard Parchment", "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal")
LibSharedMedia:Register(SML_MT_background, "Blizzard Parchment 2", "Interface\\AchievementFrame\\UI-GuildAchievement-Parchment-Horizontal")
LibSharedMedia:Register(SML_MT_background, "Blizzard Rock", "Interface\\FrameGeneral\\UI-Background-Rock")
LibSharedMedia:Register(SML_MT_background, "Blizzard Tabard Background", "Interface\\TabardFrame\\TabardFrameBackground")
LibSharedMedia:Register(SML_MT_background, "Blizzard Tooltip", "Interface\\Tooltips\\UI-Tooltip-Background")
LibSharedMedia:Register(SML_MT_background, "Solid", "Interface\\Buttons\\WHITE8X8")

LibSharedMedia:Register(SML_MT_border, "Blizzard Dialog", "Interface\\DialogFrame\\UI-DialogBox-Border")
LibSharedMedia:Register(SML_MT_border, "Blizzard Dialog Gold", "Interface\\DialogFrame\\UI-DialogBox-Gold-Border")
LibSharedMedia:Register(SML_MT_border, "Blizzard Party", "Interface\\CHARACTERFRAME\\UI-Party-Border")
LibSharedMedia:Register(SML_MT_border, "Blizzard Tooltip", "Interface\\Tooltips\\UI-Tooltip-Border")
LibSharedMedia:Register(SML_MT_border, "None", "")

LibSharedMedia:SetDefault(SML_MT_font, "Friz Quadrata TT")
LibSharedMedia:SetDefault(SML_MT_statusbar, "Blizzard")
LibSharedMedia:SetDefault(SML_MT_background, "Blizzard Tooltip")
LibSharedMedia:SetDefault(SML_MT_border, "Blizzard Tooltip")
