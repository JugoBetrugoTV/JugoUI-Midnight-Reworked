--[[
    JugoUI - Defaults.lua
    Default configuration values for all modules
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

--[[
    Profile Defaults (per character/profile)
]]
P.general = {
    -- Global settings
    uiScale = 1.0,
    autoScale = true,
    lockUI = false,
    loginMessage = true,

    -- Colors
    classColoredBorders = false,
    valueColors = true,

    -- Fonts
    font = "JugoUI Normal",
    fontSize = 12,
    fontOutline = "OUTLINE",

    -- Textures
    statusBarTexture = "JugoUI Flat",
    borderTexture = "JugoUI Glow",

    -- Misc
    smoothingAmount = 0.33,
    afkMode = true,
}

P.unitframes = {
    enabled = true,

    -- Global unitframe settings
    smoothBars = true,
    classColorHealth = true,
    colorByReaction = true,
    displayPowerBars = true,
    displayCastBars = true,
    threatDisplay = true,
    targetHighlight = true,

    -- Player frame
    player = {
        enabled = true,
        width = 220,
        height = 40,
        healthHeight = 0.75,
        powerHeight = 0.25,
        point = {"CENTER", UIParent, "CENTER", -280, -200},
        portrait = {
            enabled = true,
            style = "3D",
            width = 40,
        },
        castbar = {
            enabled = true,
            width = 220,
            height = 20,
            icon = true,
            latency = true,
        },
        buffs = {
            enabled = true,
            num = 8,
            size = 24,
            spacing = 2,
        },
        debuffs = {
            enabled = true,
            num = 8,
            size = 24,
            spacing = 2,
        },
        classbar = {
            enabled = true,
            height = 8,
        },
    },

    -- Target frame
    target = {
        enabled = true,
        width = 220,
        height = 40,
        healthHeight = 0.75,
        powerHeight = 0.25,
        point = {"CENTER", UIParent, "CENTER", 280, -200},
        portrait = {
            enabled = true,
            style = "3D",
            width = 40,
        },
        castbar = {
            enabled = true,
            width = 220,
            height = 20,
            icon = true,
        },
        buffs = {
            enabled = true,
            num = 16,
            size = 24,
            spacing = 2,
        },
        debuffs = {
            enabled = true,
            num = 16,
            size = 24,
            spacing = 2,
        },
        comboPoints = {
            enabled = true,
            height = 8,
        },
    },

    -- Target of Target
    targettarget = {
        enabled = true,
        width = 100,
        height = 25,
        point = {"LEFT", "JugoUI_Target", "RIGHT", 10, 0},
    },

    -- Focus
    focus = {
        enabled = true,
        width = 180,
        height = 35,
        point = {"CENTER", UIParent, "CENTER", -400, 100},
        castbar = {
            enabled = true,
            width = 180,
            height = 18,
        },
    },

    -- Focus Target
    focustarget = {
        enabled = true,
        width = 100,
        height = 25,
        point = {"LEFT", "JugoUI_Focus", "RIGHT", 10, 0},
    },

    -- Pet
    pet = {
        enabled = true,
        width = 100,
        height = 30,
        point = {"TOPRIGHT", "JugoUI_Player", "BOTTOMRIGHT", 0, -10},
    },

    -- Party
    party = {
        enabled = true,
        width = 180,
        height = 45,
        point = {"TOPLEFT", UIParent, "TOPLEFT", 20, -200},
        growthDirection = "DOWN",
        spacing = 5,
        showInRaid = false,
        showPlayer = false,
        showPets = true,
        buffSize = 20,
        debuffSize = 24,
    },

    -- Boss frames
    boss = {
        enabled = true,
        width = 200,
        height = 50,
        point = {"RIGHT", UIParent, "RIGHT", -100, 0},
        growthDirection = "DOWN",
        spacing = 30,
    },

    -- Arena frames
    arena = {
        enabled = true,
        width = 200,
        height = 50,
        point = {"RIGHT", UIParent, "RIGHT", -100, 0},
        growthDirection = "DOWN",
        spacing = 30,
        showTrinkets = true,
    },
}

P.nameplates = {
    enabled = true,

    -- General settings
    showFriendly = true,
    showEnemy = true,
    showSelf = false,
    clampToScreen = true,
    motionType = "STACKING",

    -- Size
    width = 120,
    height = 12,

    -- Health
    healthColor = "CLASS",
    healthText = true,
    healthTextFormat = "PERCENT",

    -- Castbar
    castbar = {
        enabled = true,
        height = 8,
        icon = true,
        interruptHighlight = true,
    },

    -- Auras
    auras = {
        enabled = true,
        size = 20,
        maxAuras = 5,
        showDebuffs = true,
        showBuffs = false,
        onlyPlayer = true,
    },

    -- Threat
    threat = {
        enabled = true,
        style = "GLOW",
    },

    -- Target indicator
    targetIndicator = {
        enabled = true,
        style = "ARROW",
    },

    -- Class power on nameplates
    classPower = {
        enabled = true,
    },
}

P.castbars = {
    enabled = true,

    player = {
        enabled = true,
        width = 250,
        height = 22,
        point = {"CENTER", UIParent, "CENTER", 0, -200},
        icon = true,
        latency = true,
        spark = true,
        ticks = true,
        interruptHighlight = true,
    },

    target = {
        enabled = true,
        width = 250,
        height = 22,
        point = {"CENTER", UIParent, "CENTER", 0, -250},
        icon = true,
        spark = true,
        interruptHighlight = true,
    },

    focus = {
        enabled = true,
        width = 180,
        height = 18,
        icon = true,
    },
}

P.actionbars = {
    enabled = true,

    -- Global settings
    lockBars = true,
    showGrid = true,
    showKeybinds = true,
    showMacroNames = false,
    showCooldownText = true,
    desaturateOnCooldown = true,
    globalFade = false,
    globalFadeAlpha = 0.3,

    -- Button style
    buttonSize = 36,
    buttonSpacing = 2,
    buttonStyle = "NORMAL",

    -- Individual bars
    bar1 = {
        enabled = true,
        buttons = 12,
        buttonsPerRow = 12,
        point = {"BOTTOM", UIParent, "BOTTOM", 0, 30},
        visibility = "[petbattle] hide; show",
    },

    bar2 = {
        enabled = true,
        buttons = 12,
        buttonsPerRow = 12,
        point = {"BOTTOM", UIParent, "BOTTOM", 0, 70},
        visibility = "[petbattle] hide; show",
    },

    bar3 = {
        enabled = true,
        buttons = 12,
        buttonsPerRow = 6,
        point = {"BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 300},
        visibility = "[petbattle] hide; show",
    },

    bar4 = {
        enabled = true,
        buttons = 12,
        buttonsPerRow = 6,
        point = {"BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 300},
        visibility = "[petbattle] hide; show",
    },

    bar5 = {
        enabled = true,
        buttons = 12,
        buttonsPerRow = 12,
        point = {"BOTTOM", UIParent, "BOTTOM", 0, 110},
        visibility = "[petbattle] hide; show",
    },

    stanceBar = {
        enabled = true,
        buttons = 10,
        buttonsPerRow = 10,
        buttonSize = 28,
        point = {"BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 150},
    },

    petBar = {
        enabled = true,
        buttons = 10,
        buttonsPerRow = 10,
        buttonSize = 28,
        point = {"BOTTOM", UIParent, "BOTTOM", 0, 150},
        visibility = "[@pet,exists] show; hide",
    },

    vehicleBar = {
        enabled = true,
    },

    microMenu = {
        enabled = true,
        point = {"BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -5, 5},
    },

    bagBar = {
        enabled = true,
        point = {"BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -5, 40},
    },
}

P.bags = {
    enabled = true,

    -- General
    sortInverted = false,
    showJunk = true,
    showNewItem = true,
    showQuality = true,
    showItemLevel = true,
    showBindType = false,

    -- Size
    bagWidth = 10,
    buttonSize = 37,
    buttonSpacing = 4,

    -- Bank
    bankWidth = 12,

    -- Position
    bagPoint = {"BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 50},
    bankPoint = {"BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 50},

    -- Colors
    qualityColors = true,
    professionBagColors = true,

    -- Currencies
    showCurrencies = true,
}

P.chat = {
    enabled = true,

    -- General
    fontSize = 12,
    font = "JugoUI Normal",
    fontOutline = "OUTLINE",
    tabFontSize = 11,
    fadeTime = 120,
    historySize = 500,

    -- Features
    copyURL = true,
    copyText = true,
    shortChannels = true,
    classColorNames = true,
    customTimestamps = true,
    timestampFormat = "[%H:%M] ",
    whisperSound = true,

    -- Layout
    width = 400,
    height = 200,
    point = {"BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 30},

    -- Buttons
    showButtons = true,
    buttonStyle = "MINIMAL",

    -- Edit box
    editBoxPosition = "BELOW",

    -- Right chat
    separateRightChat = true,
    rightChatWidth = 400,
    rightChatHeight = 200,
}

P.minimap = {
    enabled = true,

    size = 175,
    point = {"TOPRIGHT", UIParent, "TOPRIGHT", -10, -10},

    -- Display
    zoneText = true,
    time = true,
    timeFormat = "24H",
    coordinates = false,
    mail = true,
    calendar = true,

    -- Icons
    tracking = true,
    garrison = true,
    difficulty = true,

    -- Style
    style = "SQUARE",
    borderSize = 2,
}

P.tooltip = {
    enabled = true,

    -- Anchoring
    cursorAnchor = false,
    point = {"BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 200},

    -- Display
    showTitle = true,
    showRealm = true,
    showGuild = true,
    showTarget = true,
    showTalents = true,
    showItemLevel = true,
    showRole = true,

    -- Health
    healthBar = true,
    healthText = true,

    -- Colors
    classColoredBorder = true,
    guildColor = {0.7, 0.3, 1},

    -- Combat hide
    hideInCombat = false,
}

P.infobar = {
    enabled = true,

    -- Position
    topPanel = true,
    bottomPanel = true,
    height = 22,

    -- Top elements
    topLeft = {"Durability", "Gold", "Bags"},
    topRight = {"Guild", "Friends", "Latency", "FPS"},

    -- Bottom elements
    bottomLeft = {"Talents", "Loot"},
    bottomRight = {"Time", "Volume"},

    -- Style
    font = "JugoUI Normal",
    fontSize = 11,
    classColorText = true,
}

P.xprepbar = {
    enabled = true,

    width = 400,
    height = 10,
    point = {"TOP", UIParent, "TOP", 0, -5},

    -- Display
    showText = true,
    textFormat = "PERCENT",
    showRested = true,
    showArtifact = false,
    showHonor = true,
    showAzerite = false, -- Legacy, might be removed

    -- Style
    separateBars = false,
    fade = true,
}

P.skins = {
    enabled = true,

    -- What to skin
    blizzard = {
        enabled = true,
        character = true,
        spellbook = true,
        talent = true,
        quest = true,
        gossip = true,
        merchant = true,
        mail = true,
        friends = true,
        guild = true,
        lfg = true,
        collections = true,
        achievements = true,
        calendar = true,
        worldmap = true,
        encounterjournal = true,
        communities = true,
        misc = true,
    },

    addons = {
        enabled = true,
        weakauras = true,
        details = true,
        dbm = true,
        bigwigs = true,
    },
}

P.buffs = {
    enabled = true,

    -- Buffs
    buffSize = 30,
    buffSpacing = 2,
    buffsPerRow = 12,
    buffPoint = {"TOPRIGHT", UIParent, "TOPRIGHT", -200, -5},
    buffGrowthX = "LEFT",
    buffGrowthY = "DOWN",
    buffSortMethod = "TIME",
    showBuffDuration = true,

    -- Debuffs
    debuffSize = 36,
    debuffSpacing = 2,
    debuffsPerRow = 12,
    debuffPoint = {"TOPRIGHT", UIParent, "TOPRIGHT", -200, -55},
    debuffGrowthX = "LEFT",
    debuffGrowthY = "DOWN",
    debuffSortMethod = "TIME",
    showDebuffDuration = true,
    colorByType = true,
}

P.misc = {
    -- Auto repair
    autoRepair = true,
    autoRepairGuild = false,

    -- Auto sell junk
    autoSellJunk = true,

    -- UI enhancements
    enhancedMail = true,
    fastLoot = true,
    autoAcceptInvite = false,
    autoAcceptSummon = false,

    -- Combat
    combatAlert = true,
    interruptAnnounce = false,
    autoScreenshot = true,

    -- Misc
    hideErrors = false,
    hideZoneText = false,
    afkCamera = true,
}

P.raidframes = {
    enabled = true,

    -- Size
    width = 80,
    height = 40,

    -- Layout
    point = {"TOPLEFT", UIParent, "TOPLEFT", 10, -250},
    growthDirection = "RIGHT_DOWN",
    groupsPerRow = 5,
    horizontalSpacing = 4,
    verticalSpacing = 4,
    sortMethod = "GROUP",

    -- Display
    showPets = false,
    showMainTanks = true,
    showMainAssist = true,
    showPartyFramesInRaid = false,

    -- Health
    healthColor = "CLASS",
    smoothBars = true,
    deficit = false,

    -- Power
    showPower = true,
    powerHeight = 0.2,

    -- Name
    showName = true,
    nameLength = 8,

    -- Auras
    debuffs = {
        enabled = true,
        size = 18,
        num = 3,
        onlyDispellable = false,
    },
    buffs = {
        enabled = true,
        size = 16,
        num = 3,
        onlyShowPlayer = true,
    },

    -- Range
    rangeCheck = true,
    rangeAlpha = 0.35,

    -- Role/Raid icons
    showRoleIcon = true,
    showRaidIcon = true,

    -- Threat
    threatBorder = true,

    -- Ready check / Summon
    showReadyCheck = true,
    showSummon = true,
    showResurrect = true,
}

P.profiles = {
    -- Profile management handled by AceDB
}

P.credits = {
    -- Credits data (read-only)
}

--[[
    Global Defaults (account-wide)
]]
G.general = {
    version = E.version,
    firstRun = true,
    profileSync = false,
}

G.profiles = {
    -- List of profile data for sharing
}

--[[
    Private Defaults (character-specific, not in profile)
]]
V.general = {
    install = false,
    installComplete = false,
}

V.actionbars = {
    -- Character-specific action bar settings
}
