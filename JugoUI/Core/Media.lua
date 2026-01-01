--[[
    JugoUI - Media.lua
    Media definitions (fonts, textures, sounds)
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

-- Media table
E.media = {
    fonts = {},
    textures = {},
    sounds = {},
    borders = {},
    colors = {},
}

local LSM = E.LSM
local mediaPath = E.mediaPath

--[[
    Fonts
]]
E.media.fonts = {
    normal = mediaPath .. "Fonts\\PTSansNarrow-Regular.ttf",
    bold = mediaPath .. "Fonts\\PTSansNarrow-Bold.ttf",
    number = mediaPath .. "Fonts\\Continuum-Medium.ttf",
    combat = mediaPath .. "Fonts\\Continuum-Bold.ttf",
    header = mediaPath .. "Fonts\\Morpheus.ttf",
    pixel = mediaPath .. "Fonts\\Homespun.ttf",
}

-- Register with LibSharedMedia
if LSM then
    LSM:Register("font", "JugoUI Normal", E.media.fonts.normal)
    LSM:Register("font", "JugoUI Bold", E.media.fonts.bold)
    LSM:Register("font", "JugoUI Number", E.media.fonts.number)
    LSM:Register("font", "JugoUI Combat", E.media.fonts.combat)
    LSM:Register("font", "JugoUI Header", E.media.fonts.header)
    LSM:Register("font", "JugoUI Pixel", E.media.fonts.pixel)
end

--[[
    Textures
]]
E.media.textures = {
    -- Status bars
    blank = mediaPath .. "Textures\\blank.tga",
    flat = mediaPath .. "Textures\\flat.tga",
    gradient = mediaPath .. "Textures\\gradient.tga",
    gloss = mediaPath .. "Textures\\gloss.tga",
    smooth = mediaPath .. "Textures\\smooth.tga",
    minimalist = mediaPath .. "Textures\\minimalist.tga",

    -- Borders
    glowBorder = mediaPath .. "Textures\\glowBorder.tga",
    shadowBorder = mediaPath .. "Textures\\shadowBorder.tga",
    buttonBorder = mediaPath .. "Textures\\buttonBorder.tga",

    -- Icons and misc
    logo = mediaPath .. "Textures\\logo.tga",
    arrow = mediaPath .. "Textures\\arrow.tga",
    close = mediaPath .. "Textures\\close.tga",
    copy = mediaPath .. "Textures\\copy.tga",
    warning = mediaPath .. "Textures\\warning.tga",

    -- Role icons
    roleIcons = mediaPath .. "Textures\\roles.tga",
    tankIcon = mediaPath .. "Textures\\tank.tga",
    healerIcon = mediaPath .. "Textures\\healer.tga",
    dpsIcon = mediaPath .. "Textures\\dps.tga",

    -- Raid markers
    raidIcons = "Interface\\TargetingFrame\\UI-RaidTargetingIcons",

    -- Class icons
    classIcons = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",

    -- Threat
    threat = mediaPath .. "Textures\\threat.tga",

    -- Auras
    auraBorder = mediaPath .. "Textures\\auraBorder.tga",
    debuffBorder = mediaPath .. "Textures\\debuffBorder.tga",
    buffBorder = mediaPath .. "Textures\\buffBorder.tga",

    -- Nameplates
    castbar = mediaPath .. "Textures\\castbar.tga",
    spark = mediaPath .. "Textures\\spark.tga",
}

-- Register textures with LibSharedMedia
if LSM then
    LSM:Register("statusbar", "JugoUI Blank", E.media.textures.blank)
    LSM:Register("statusbar", "JugoUI Flat", E.media.textures.flat)
    LSM:Register("statusbar", "JugoUI Gradient", E.media.textures.gradient)
    LSM:Register("statusbar", "JugoUI Gloss", E.media.textures.gloss)
    LSM:Register("statusbar", "JugoUI Smooth", E.media.textures.smooth)
    LSM:Register("statusbar", "JugoUI Minimalist", E.media.textures.minimalist)

    LSM:Register("border", "JugoUI Glow", E.media.textures.glowBorder)
    LSM:Register("border", "JugoUI Shadow", E.media.textures.shadowBorder)
end

--[[
    Borders
]]
E.media.borders = {
    default = {
        texture = E.media.textures.glowBorder,
        size = 3,
        offset = 2,
    },
    shadow = {
        texture = E.media.textures.shadowBorder,
        size = 4,
        offset = 3,
    },
    button = {
        texture = E.media.textures.buttonBorder,
        size = 2,
        offset = 1,
    },
}

--[[
    Colors
]]
-- Class colors (use Blizzard's RAID_CLASS_COLORS but allow overrides)
E.media.colors.class = {}
for class, color in pairs(RAID_CLASS_COLORS) do
    E.media.colors.class[class] = {color.r, color.g, color.b}
end

-- Power colors
E.media.colors.power = {
    MANA = {0.31, 0.45, 0.63},
    RAGE = {0.78, 0.25, 0.25},
    FOCUS = {0.71, 0.43, 0.27},
    ENERGY = {0.65, 0.63, 0.35},
    RUNIC_POWER = {0.00, 0.82, 1.00},
    LUNAR_POWER = {0.30, 0.52, 0.90},
    MAELSTROM = {0.00, 0.50, 1.00},
    INSANITY = {0.40, 0.00, 0.80},
    FURY = {0.788, 0.259, 0.992},
    PAIN = {1.00, 0.61, 0.00},
    SOUL_SHARDS = {0.50, 0.32, 0.55},
    HOLY_POWER = {0.95, 0.90, 0.60},
    CHI = {0.71, 1.00, 0.92},
    ARCANE_CHARGES = {0.10, 0.10, 0.98},
    COMBO_POINTS = {1.00, 0.96, 0.41},
    RUNES = {0.50, 0.50, 0.50},
    ESSENCE = {0.00, 0.80, 0.80},
    ALTERNATE = {0.50, 0.50, 0.50},
}

-- Reaction colors
E.media.colors.reaction = {
    [1] = {0.87, 0.36, 0.36}, -- Hated
    [2] = {0.87, 0.36, 0.36}, -- Hostile
    [3] = {0.87, 0.36, 0.36}, -- Unfriendly
    [4] = {0.85, 0.77, 0.36}, -- Neutral
    [5] = {0.29, 0.67, 0.30}, -- Friendly
    [6] = {0.29, 0.67, 0.30}, -- Honored
    [7] = {0.29, 0.67, 0.30}, -- Revered
    [8] = {0.29, 0.67, 0.30}, -- Exalted
}

-- Health colors
E.media.colors.health = {
    value = {0.31, 0.45, 0.63},
    tapped = {0.55, 0.55, 0.55},
    disconnected = {0.50, 0.50, 0.50},
    dead = {0.40, 0.40, 0.40},
}

-- Threat colors
E.media.colors.threat = {
    [0] = {0.80, 0.80, 0.80}, -- No threat
    [1] = {1.00, 1.00, 0.47}, -- Warning
    [2] = {1.00, 0.60, 0.00}, -- Pull aggro
    [3] = {1.00, 0.00, 0.00}, -- Have aggro
}

-- Experience colors
E.media.colors.experience = {
    xp = {0.58, 0.00, 0.55},
    rested = {0.00, 0.39, 0.88},
}

-- Reputation colors
E.media.colors.reputation = {
    [1] = {0.80, 0.30, 0.22}, -- Hated
    [2] = {0.80, 0.30, 0.22}, -- Hostile
    [3] = {0.75, 0.27, 0.00}, -- Unfriendly
    [4] = {0.90, 0.70, 0.00}, -- Neutral
    [5] = {0.00, 0.60, 0.10}, -- Friendly
    [6] = {0.00, 0.60, 0.10}, -- Honored
    [7] = {0.00, 0.60, 0.10}, -- Revered
    [8] = {0.00, 0.60, 0.10}, -- Exalted
}

-- Debuff type colors
E.media.colors.debuffType = {
    Magic = {0.20, 0.60, 1.00},
    Curse = {0.60, 0.00, 1.00},
    Disease = {0.60, 0.40, 0.00},
    Poison = {0.00, 0.60, 0.00},
    Physical = {0.80, 0.80, 0.80},
    none = {0.80, 0.00, 0.00},
}

-- Difficulty colors
E.media.colors.difficulty = {
    impossible = {1.00, 0.10, 0.10},
    verydifficult = {1.00, 0.50, 0.25},
    difficult = {1.00, 1.00, 0.00},
    standard = {0.25, 0.75, 0.25},
    trivial = {0.50, 0.50, 0.50},
}

-- Quality colors (item rarity)
E.media.colors.quality = {
    [0] = {0.62, 0.62, 0.62}, -- Poor
    [1] = {1.00, 1.00, 1.00}, -- Common
    [2] = {0.12, 1.00, 0.00}, -- Uncommon
    [3] = {0.00, 0.44, 0.87}, -- Rare
    [4] = {0.64, 0.21, 0.93}, -- Epic
    [5] = {1.00, 0.50, 0.00}, -- Legendary
    [6] = {0.90, 0.80, 0.50}, -- Artifact
    [7] = {0.00, 0.80, 1.00}, -- Heirloom
    [8] = {0.00, 0.80, 1.00}, -- Wow Token
}

-- Cast colors
E.media.colors.castbar = {
    casting = {1.00, 0.70, 0.00},
    channeling = {0.00, 1.00, 0.00},
    empowering = {0.47, 0.30, 0.97},
    success = {0.00, 1.00, 0.00},
    failed = {1.00, 0.00, 0.00},
    interrupted = {1.00, 0.00, 0.00},
    interruptible = {0.69, 0.31, 0.31},
    notInterruptible = {0.40, 0.40, 0.40},
}

-- UI accent colors
E.media.colors.ui = {
    accent = {0.00, 1.00, 1.00},
    background = {0.05, 0.05, 0.05, 0.90},
    border = {0.20, 0.20, 0.20},
    highlight = {1.00, 1.00, 1.00, 0.30},
}

--[[
    Sound effects
]]
E.media.sounds = {
    warning = 567458, -- Sound ID for warning
    levelup = 567431, -- Level up sound
    buff = 567507,    -- Buff applied
    debuff = 567508,  -- Debuff applied
    click = 567482,   -- Button click
}

--[[
    Helper functions
]]
function E:GetClassColor(class, useHex)
    class = class or E.myclass
    local color = E.media.colors.class[class] or {1, 1, 1}
    if useHex then
        return format("|cff%02x%02x%02x", color[1] * 255, color[2] * 255, color[3] * 255)
    end
    return unpack(color)
end

function E:GetPowerColor(powerType, useHex)
    local color = E.media.colors.power[powerType] or E.media.colors.power.MANA
    if useHex then
        return format("|cff%02x%02x%02x", color[1] * 255, color[2] * 255, color[3] * 255)
    end
    return unpack(color)
end

function E:GetReactionColor(reaction, useHex)
    local color = E.media.colors.reaction[reaction] or E.media.colors.reaction[4]
    if useHex then
        return format("|cff%02x%02x%02x", color[1] * 255, color[2] * 255, color[3] * 255)
    end
    return unpack(color)
end

function E:GetQualityColor(quality, useHex)
    local color = E.media.colors.quality[quality] or E.media.colors.quality[1]
    if useHex then
        return format("|cff%02x%02x%02x", color[1] * 255, color[2] * 255, color[3] * 255)
    end
    return unpack(color)
end

function E:GetTexture(name)
    return E.media.textures[name] or E.media.textures.flat
end

function E:GetFont(name)
    return E.media.fonts[name] or E.media.fonts.normal
end

-- Update colors from database (for custom color support)
function E:UpdateMediaColors()
    if E.db and E.db.general and E.db.general.colors then
        -- Merge custom colors from database
        for category, colors in pairs(E.db.general.colors) do
            if E.media.colors[category] then
                for key, color in pairs(colors) do
                    E.media.colors[category][key] = color
                end
            end
        end
    end

    E.callbacks:Fire("JugoUI_MediaUpdated")
end
