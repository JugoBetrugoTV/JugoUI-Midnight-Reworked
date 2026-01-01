--[[
    JugoUI - Config/Options.lua
    Module-specific options definitions
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

--[[
    UnitFrames Options
]]
function E:GetUnitFramesOptions()
    return {
        type = "group",
        name = "Unit Frames",
        order = 1,
        childGroups = "tab",
        args = {
            player = {
                type = "group",
                name = "Player",
                order = 1,
                args = {
                    header = {
                        type = "header",
                        name = "Player Frame",
                        order = 1,
                    },
                    enabled = {
                        type = "toggle",
                        name = "Enable",
                        order = 2,
                        get = function() return E.db.unitframes.player.enabled end,
                        set = function(_, v) E.db.unitframes.player.enabled = v end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        min = 100, max = 400, step = 1,
                        order = 3,
                        get = function() return E.db.unitframes.player.width end,
                        set = function(_, v) E.db.unitframes.player.width = v end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        min = 20, max = 100, step = 1,
                        order = 4,
                        get = function() return E.db.unitframes.player.height end,
                        set = function(_, v) E.db.unitframes.player.height = v end,
                    },
                    showPower = {
                        type = "toggle",
                        name = "Show Power Bar",
                        order = 5,
                        get = function() return E.db.unitframes.player.showPower end,
                        set = function(_, v) E.db.unitframes.player.showPower = v end,
                    },
                    showCastbar = {
                        type = "toggle",
                        name = "Show Castbar",
                        order = 6,
                        get = function() return E.db.unitframes.player.showCastbar end,
                        set = function(_, v) E.db.unitframes.player.showCastbar = v end,
                    },
                    classColor = {
                        type = "toggle",
                        name = "Use Class Color",
                        order = 7,
                        get = function() return E.db.unitframes.player.classColor end,
                        set = function(_, v) E.db.unitframes.player.classColor = v end,
                    },
                },
            },
            target = {
                type = "group",
                name = "Target",
                order = 2,
                args = {
                    header = {
                        type = "header",
                        name = "Target Frame",
                        order = 1,
                    },
                    enabled = {
                        type = "toggle",
                        name = "Enable",
                        order = 2,
                        get = function() return E.db.unitframes.target.enabled end,
                        set = function(_, v) E.db.unitframes.target.enabled = v end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        min = 100, max = 400, step = 1,
                        order = 3,
                        get = function() return E.db.unitframes.target.width end,
                        set = function(_, v) E.db.unitframes.target.width = v end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        min = 20, max = 100, step = 1,
                        order = 4,
                        get = function() return E.db.unitframes.target.height end,
                        set = function(_, v) E.db.unitframes.target.height = v end,
                    },
                    showPower = {
                        type = "toggle",
                        name = "Show Power Bar",
                        order = 5,
                        get = function() return E.db.unitframes.target.showPower end,
                        set = function(_, v) E.db.unitframes.target.showPower = v end,
                    },
                    showCastbar = {
                        type = "toggle",
                        name = "Show Castbar",
                        order = 6,
                        get = function() return E.db.unitframes.target.showCastbar end,
                        set = function(_, v) E.db.unitframes.target.showCastbar = v end,
                    },
                },
            },
            focus = {
                type = "group",
                name = "Focus",
                order = 3,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Enable",
                        order = 1,
                        get = function() return E.db.unitframes.focus.enabled end,
                        set = function(_, v) E.db.unitframes.focus.enabled = v end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        min = 80, max = 300, step = 1,
                        order = 2,
                        get = function() return E.db.unitframes.focus.width end,
                        set = function(_, v) E.db.unitframes.focus.width = v end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        min = 15, max = 80, step = 1,
                        order = 3,
                        get = function() return E.db.unitframes.focus.height end,
                        set = function(_, v) E.db.unitframes.focus.height = v end,
                    },
                },
            },
            pet = {
                type = "group",
                name = "Pet",
                order = 4,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Enable",
                        order = 1,
                        get = function() return E.db.unitframes.pet.enabled end,
                        set = function(_, v) E.db.unitframes.pet.enabled = v end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        min = 80, max = 300, step = 1,
                        order = 2,
                        get = function() return E.db.unitframes.pet.width end,
                        set = function(_, v) E.db.unitframes.pet.width = v end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        min = 15, max = 80, step = 1,
                        order = 3,
                        get = function() return E.db.unitframes.pet.height end,
                        set = function(_, v) E.db.unitframes.pet.height = v end,
                    },
                },
            },
        },
    }
end

--[[
    Nameplates Options
]]
function E:GetNameplatesOptions()
    return {
        type = "group",
        name = "Nameplates",
        order = 2,
        args = {
            header = {
                type = "header",
                name = "Nameplate Settings",
                order = 1,
            },
            enabled = {
                type = "toggle",
                name = "Enable Custom Nameplates",
                order = 2,
                get = function() return E.db.nameplates.enabled end,
                set = function(_, v) E.db.nameplates.enabled = v end,
            },
            width = {
                type = "range",
                name = "Width",
                min = 80, max = 200, step = 1,
                order = 3,
                get = function() return E.db.nameplates.width end,
                set = function(_, v) E.db.nameplates.width = v end,
            },
            height = {
                type = "range",
                name = "Height",
                min = 6, max = 30, step = 1,
                order = 4,
                get = function() return E.db.nameplates.height end,
                set = function(_, v) E.db.nameplates.height = v end,
            },
            showName = {
                type = "toggle",
                name = "Show Name",
                order = 5,
                get = function() return E.db.nameplates.showName end,
                set = function(_, v) E.db.nameplates.showName = v end,
            },
            showLevel = {
                type = "toggle",
                name = "Show Level",
                order = 6,
                get = function() return E.db.nameplates.showLevel end,
                set = function(_, v) E.db.nameplates.showLevel = v end,
            },
            showCastbar = {
                type = "toggle",
                name = "Show Castbar",
                order = 7,
                get = function() return E.db.nameplates.showCastbar end,
                set = function(_, v) E.db.nameplates.showCastbar = v end,
            },
            classColors = {
                type = "toggle",
                name = "Class Colors on Players",
                order = 8,
                get = function() return E.db.nameplates.classColors end,
                set = function(_, v) E.db.nameplates.classColors = v end,
            },
            threatColors = {
                type = "toggle",
                name = "Threat Colors",
                order = 9,
                get = function() return E.db.nameplates.threatColors end,
                set = function(_, v) E.db.nameplates.threatColors = v end,
            },
        },
    }
end

--[[
    ActionBars Options
]]
function E:GetActionBarsOptions()
    return {
        type = "group",
        name = "Action Bars",
        order = 3,
        childGroups = "tab",
        args = {
            general = {
                type = "group",
                name = "General",
                order = 1,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Enable Custom Action Bars",
                        order = 1,
                        get = function() return E.db.actionbars.enabled end,
                        set = function(_, v) E.db.actionbars.enabled = v end,
                    },
                    buttonSize = {
                        type = "range",
                        name = "Button Size",
                        min = 20, max = 60, step = 1,
                        order = 2,
                        get = function() return E.db.actionbars.buttonSize end,
                        set = function(_, v) E.db.actionbars.buttonSize = v end,
                    },
                    buttonSpacing = {
                        type = "range",
                        name = "Button Spacing",
                        min = 0, max = 10, step = 1,
                        order = 3,
                        get = function() return E.db.actionbars.buttonSpacing end,
                        set = function(_, v) E.db.actionbars.buttonSpacing = v end,
                    },
                    showHotkeys = {
                        type = "toggle",
                        name = "Show Hotkeys",
                        order = 4,
                        get = function() return E.db.actionbars.showHotkeys end,
                        set = function(_, v) E.db.actionbars.showHotkeys = v end,
                    },
                    showMacroNames = {
                        type = "toggle",
                        name = "Show Macro Names",
                        order = 5,
                        get = function() return E.db.actionbars.showMacroNames end,
                        set = function(_, v) E.db.actionbars.showMacroNames = v end,
                    },
                    showCooldownText = {
                        type = "toggle",
                        name = "Show Cooldown Text",
                        order = 6,
                        get = function() return E.db.actionbars.showCooldownText end,
                        set = function(_, v) E.db.actionbars.showCooldownText = v end,
                    },
                    rangeIndicator = {
                        type = "toggle",
                        name = "Out of Range Indicator",
                        order = 7,
                        get = function() return E.db.actionbars.rangeIndicator end,
                        set = function(_, v) E.db.actionbars.rangeIndicator = v end,
                    },
                },
            },
            bar1 = {
                type = "group",
                name = "Bar 1 (Main)",
                order = 2,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Enable",
                        order = 1,
                        get = function() return E.db.actionbars.bar1.enabled end,
                        set = function(_, v) E.db.actionbars.bar1.enabled = v end,
                    },
                    buttons = {
                        type = "range",
                        name = "Buttons",
                        min = 1, max = 12, step = 1,
                        order = 2,
                        get = function() return E.db.actionbars.bar1.buttons end,
                        set = function(_, v) E.db.actionbars.bar1.buttons = v end,
                    },
                    buttonsPerRow = {
                        type = "range",
                        name = "Buttons Per Row",
                        min = 1, max = 12, step = 1,
                        order = 3,
                        get = function() return E.db.actionbars.bar1.buttonsPerRow end,
                        set = function(_, v) E.db.actionbars.bar1.buttonsPerRow = v end,
                    },
                },
            },
        },
    }
end

--[[
    Chat Options
]]
function E:GetChatOptions()
    return {
        type = "group",
        name = "Chat",
        order = 4,
        args = {
            header = {
                type = "header",
                name = "Chat Settings",
                order = 1,
            },
            enabled = {
                type = "toggle",
                name = "Enable Custom Chat",
                order = 2,
                get = function() return E.db.chat.enabled end,
                set = function(_, v) E.db.chat.enabled = v end,
            },
            width = {
                type = "range",
                name = "Width",
                min = 200, max = 600, step = 1,
                order = 3,
                get = function() return E.db.chat.width end,
                set = function(_, v) E.db.chat.width = v end,
            },
            height = {
                type = "range",
                name = "Height",
                min = 100, max = 400, step = 1,
                order = 4,
                get = function() return E.db.chat.height end,
                set = function(_, v) E.db.chat.height = v end,
            },
            fontSize = {
                type = "range",
                name = "Font Size",
                min = 8, max = 20, step = 1,
                order = 5,
                get = function() return E.db.chat.fontSize end,
                set = function(_, v) E.db.chat.fontSize = v end,
            },
            timestamps = {
                type = "toggle",
                name = "Show Timestamps",
                order = 6,
                get = function() return E.db.chat.timestamps end,
                set = function(_, v) E.db.chat.timestamps = v end,
            },
            classColors = {
                type = "toggle",
                name = "Class Colored Names",
                order = 7,
                get = function() return E.db.chat.classColors end,
                set = function(_, v) E.db.chat.classColors = v end,
            },
            copyChat = {
                type = "toggle",
                name = "Enable Copy Chat",
                order = 8,
                get = function() return E.db.chat.copyChat end,
                set = function(_, v) E.db.chat.copyChat = v end,
            },
            urlCopy = {
                type = "toggle",
                name = "Clickable URLs",
                order = 9,
                get = function() return E.db.chat.urlCopy end,
                set = function(_, v) E.db.chat.urlCopy = v end,
            },
        },
    }
end

--[[
    Minimap Options
]]
function E:GetMinimapOptions()
    return {
        type = "group",
        name = "Minimap",
        order = 5,
        args = {
            header = {
                type = "header",
                name = "Minimap Settings",
                order = 1,
            },
            enabled = {
                type = "toggle",
                name = "Enable Custom Minimap",
                order = 2,
                get = function() return E.db.minimap.enabled end,
                set = function(_, v) E.db.minimap.enabled = v end,
            },
            size = {
                type = "range",
                name = "Size",
                min = 100, max = 300, step = 1,
                order = 3,
                get = function() return E.db.minimap.size end,
                set = function(_, v) E.db.minimap.size = v end,
            },
            shape = {
                type = "select",
                name = "Shape",
                values = {
                    ["ROUND"] = "Round",
                    ["SQUARE"] = "Square",
                },
                order = 4,
                get = function() return E.db.minimap.shape end,
                set = function(_, v) E.db.minimap.shape = v end,
            },
            showClock = {
                type = "toggle",
                name = "Show Clock",
                order = 5,
                get = function() return E.db.minimap.showClock end,
                set = function(_, v) E.db.minimap.showClock = v end,
            },
            showZone = {
                type = "toggle",
                name = "Show Zone Text",
                order = 6,
                get = function() return E.db.minimap.showZone end,
                set = function(_, v) E.db.minimap.showZone = v end,
            },
            showCoords = {
                type = "toggle",
                name = "Show Coordinates",
                order = 7,
                get = function() return E.db.minimap.showCoords end,
                set = function(_, v) E.db.minimap.showCoords = v end,
            },
        },
    }
end

--[[
    Tooltip Options
]]
function E:GetTooltipOptions()
    return {
        type = "group",
        name = "Tooltip",
        order = 6,
        args = {
            header = {
                type = "header",
                name = "Tooltip Settings",
                order = 1,
            },
            enabled = {
                type = "toggle",
                name = "Enable Custom Tooltip",
                order = 2,
                get = function() return E.db.tooltip.enabled end,
                set = function(_, v) E.db.tooltip.enabled = v end,
            },
            showIDs = {
                type = "toggle",
                name = "Show Spell/Item IDs",
                order = 3,
                get = function() return E.db.tooltip.showIDs end,
                set = function(_, v) E.db.tooltip.showIDs = v end,
            },
            showGuild = {
                type = "toggle",
                name = "Show Guild",
                order = 4,
                get = function() return E.db.tooltip.showGuild end,
                set = function(_, v) E.db.tooltip.showGuild = v end,
            },
            showRealm = {
                type = "toggle",
                name = "Show Realm",
                order = 5,
                get = function() return E.db.tooltip.showRealm end,
                set = function(_, v) E.db.tooltip.showRealm = v end,
            },
            showTargetInfo = {
                type = "toggle",
                name = "Show Target of Target",
                order = 6,
                get = function() return E.db.tooltip.showTargetInfo end,
                set = function(_, v) E.db.tooltip.showTargetInfo = v end,
            },
            healthBar = {
                type = "toggle",
                name = "Show Health Bar",
                order = 7,
                get = function() return E.db.tooltip.healthBar end,
                set = function(_, v) E.db.tooltip.healthBar = v end,
            },
            anchorType = {
                type = "select",
                name = "Anchor Position",
                values = {
                    ["CURSOR"] = "At Cursor",
                    ["TOPLEFT"] = "Top Left",
                    ["TOPRIGHT"] = "Top Right",
                    ["BOTTOMLEFT"] = "Bottom Left",
                    ["BOTTOMRIGHT"] = "Bottom Right",
                },
                order = 8,
                get = function() return E.db.tooltip.anchorType end,
                set = function(_, v) E.db.tooltip.anchorType = v end,
            },
        },
    }
end

--[[
    Bags Options
]]
function E:GetBagsOptions()
    return {
        type = "group",
        name = "Bags",
        order = 7,
        args = {
            header = {
                type = "header",
                name = "Bag Settings",
                order = 1,
            },
            enabled = {
                type = "toggle",
                name = "Enable Custom Bags",
                order = 2,
                get = function() return E.db.bags.enabled end,
                set = function(_, v) E.db.bags.enabled = v end,
            },
            sortDirection = {
                type = "select",
                name = "Sort Direction",
                values = {
                    ["ASC"] = "Ascending",
                    ["DESC"] = "Descending",
                },
                order = 3,
                get = function() return E.db.bags.sortDirection end,
                set = function(_, v) E.db.bags.sortDirection = v end,
            },
            itemLevel = {
                type = "toggle",
                name = "Show Item Level",
                order = 4,
                get = function() return E.db.bags.itemLevel end,
                set = function(_, v) E.db.bags.itemLevel = v end,
            },
            junkIcon = {
                type = "toggle",
                name = "Show Junk Icon",
                order = 5,
                get = function() return E.db.bags.junkIcon end,
                set = function(_, v) E.db.bags.junkIcon = v end,
            },
            scrapIcon = {
                type = "toggle",
                name = "Show Scrap Icon",
                order = 6,
                get = function() return E.db.bags.scrapIcon end,
                set = function(_, v) E.db.bags.scrapIcon = v end,
            },
            newItemGlow = {
                type = "toggle",
                name = "New Item Glow",
                order = 7,
                get = function() return E.db.bags.newItemGlow end,
                set = function(_, v) E.db.bags.newItemGlow = v end,
            },
        },
    }
end

--[[
    Buffs/Debuffs Options
]]
function E:GetBuffsOptions()
    return {
        type = "group",
        name = "Buffs & Debuffs",
        order = 8,
        args = {
            header = {
                type = "header",
                name = "Buff Settings",
                order = 1,
            },
            enabled = {
                type = "toggle",
                name = "Enable Custom Buffs",
                order = 2,
                get = function() return E.db.buffs.enabled end,
                set = function(_, v) E.db.buffs.enabled = v end,
            },
            iconSize = {
                type = "range",
                name = "Icon Size",
                min = 20, max = 50, step = 1,
                order = 3,
                get = function() return E.db.buffs.iconSize end,
                set = function(_, v) E.db.buffs.iconSize = v end,
            },
            iconsPerRow = {
                type = "range",
                name = "Icons Per Row",
                min = 6, max = 20, step = 1,
                order = 4,
                get = function() return E.db.buffs.iconsPerRow end,
                set = function(_, v) E.db.buffs.iconsPerRow = v end,
            },
            showDuration = {
                type = "toggle",
                name = "Show Duration",
                order = 5,
                get = function() return E.db.buffs.showDuration end,
                set = function(_, v) E.db.buffs.showDuration = v end,
            },
            sortByTime = {
                type = "toggle",
                name = "Sort by Time Remaining",
                order = 6,
                get = function() return E.db.buffs.sortByTime end,
                set = function(_, v) E.db.buffs.sortByTime = v end,
            },
            debuffHeader = {
                type = "header",
                name = "Debuff Settings",
                order = 10,
            },
            debuffIconSize = {
                type = "range",
                name = "Debuff Icon Size",
                min = 20, max = 50, step = 1,
                order = 11,
                get = function() return E.db.buffs.debuffIconSize end,
                set = function(_, v) E.db.buffs.debuffIconSize = v end,
            },
            debuffColorByType = {
                type = "toggle",
                name = "Color by Debuff Type",
                order = 12,
                get = function() return E.db.buffs.debuffColorByType end,
                set = function(_, v) E.db.buffs.debuffColorByType = v end,
            },
        },
    }
end

--[[
    XP/Rep Bar Options
]]
function E:GetXPBarOptions()
    return {
        type = "group",
        name = "XP & Reputation Bar",
        order = 9,
        args = {
            header = {
                type = "header",
                name = "XP Bar Settings",
                order = 1,
            },
            enabled = {
                type = "toggle",
                name = "Enable",
                order = 2,
                get = function() return E.db.xpbar.enabled end,
                set = function(_, v) E.db.xpbar.enabled = v end,
            },
            width = {
                type = "range",
                name = "Width",
                min = 200, max = 800, step = 1,
                order = 3,
                get = function() return E.db.xpbar.width end,
                set = function(_, v) E.db.xpbar.width = v end,
            },
            height = {
                type = "range",
                name = "Height",
                min = 5, max = 30, step = 1,
                order = 4,
                get = function() return E.db.xpbar.height end,
                set = function(_, v) E.db.xpbar.height = v end,
            },
            showText = {
                type = "toggle",
                name = "Show Text",
                order = 5,
                get = function() return E.db.xpbar.showText end,
                set = function(_, v) E.db.xpbar.showText = v end,
            },
            textFormat = {
                type = "select",
                name = "Text Format",
                values = {
                    ["PERCENT"] = "Percentage",
                    ["CURRENT_MAX"] = "Current / Max",
                    ["REMAINING"] = "Remaining",
                },
                order = 6,
                get = function() return E.db.xpbar.textFormat end,
                set = function(_, v) E.db.xpbar.textFormat = v end,
            },
            showRested = {
                type = "toggle",
                name = "Show Rested XP",
                order = 7,
                get = function() return E.db.xpbar.showRested end,
                set = function(_, v) E.db.xpbar.showRested = v end,
            },
            repHeader = {
                type = "header",
                name = "Reputation Bar",
                order = 10,
            },
            showReputation = {
                type = "toggle",
                name = "Show Reputation Bar",
                order = 11,
                get = function() return E.db.xpbar.showReputation end,
                set = function(_, v) E.db.xpbar.showReputation = v end,
            },
        },
    }
end

--[[
    InfoBar Options
]]
function E:GetInfoBarOptions()
    return {
        type = "group",
        name = "Info Bar",
        order = 10,
        args = {
            header = {
                type = "header",
                name = "Info Bar Settings",
                order = 1,
            },
            enabled = {
                type = "toggle",
                name = "Enable",
                order = 2,
                get = function() return E.db.infobar.enabled end,
                set = function(_, v) E.db.infobar.enabled = v end,
            },
            showFPS = {
                type = "toggle",
                name = "Show FPS",
                order = 3,
                get = function() return E.db.infobar.showFPS end,
                set = function(_, v) E.db.infobar.showFPS = v end,
            },
            showLatency = {
                type = "toggle",
                name = "Show Latency",
                order = 4,
                get = function() return E.db.infobar.showLatency end,
                set = function(_, v) E.db.infobar.showLatency = v end,
            },
            showMemory = {
                type = "toggle",
                name = "Show Memory Usage",
                order = 5,
                get = function() return E.db.infobar.showMemory end,
                set = function(_, v) E.db.infobar.showMemory = v end,
            },
            showDurability = {
                type = "toggle",
                name = "Show Durability",
                order = 6,
                get = function() return E.db.infobar.showDurability end,
                set = function(_, v) E.db.infobar.showDurability = v end,
            },
            showGold = {
                type = "toggle",
                name = "Show Gold",
                order = 7,
                get = function() return E.db.infobar.showGold end,
                set = function(_, v) E.db.infobar.showGold = v end,
            },
            showClock = {
                type = "toggle",
                name = "Show Clock",
                order = 8,
                get = function() return E.db.infobar.showClock end,
                set = function(_, v) E.db.infobar.showClock = v end,
            },
            use24Hour = {
                type = "toggle",
                name = "24-Hour Clock",
                order = 9,
                get = function() return E.db.infobar.use24Hour end,
                set = function(_, v) E.db.infobar.use24Hour = v end,
            },
        },
    }
end

--[[
    Raid Frames Options
]]
function E:GetRaidFramesOptions()
    return {
        type = "group",
        name = "Raid Frames",
        order = 11,
        args = {
            header = {
                type = "header",
                name = "Raid Frame Settings",
                order = 1,
            },
            enabled = {
                type = "toggle",
                name = "Enable Custom Raid Frames",
                order = 2,
                get = function() return E.db.raidframes.enabled end,
                set = function(_, v) E.db.raidframes.enabled = v end,
            },
            width = {
                type = "range",
                name = "Width",
                min = 50, max = 150, step = 1,
                order = 3,
                get = function() return E.db.raidframes.width end,
                set = function(_, v) E.db.raidframes.width = v end,
            },
            height = {
                type = "range",
                name = "Height",
                min = 20, max = 80, step = 1,
                order = 4,
                get = function() return E.db.raidframes.height end,
                set = function(_, v) E.db.raidframes.height = v end,
            },
            showPower = {
                type = "toggle",
                name = "Show Power Bars",
                order = 5,
                get = function() return E.db.raidframes.showPower end,
                set = function(_, v) E.db.raidframes.showPower = v end,
            },
            showName = {
                type = "toggle",
                name = "Show Names",
                order = 6,
                get = function() return E.db.raidframes.showName end,
                set = function(_, v) E.db.raidframes.showName = v end,
            },
            showRole = {
                type = "toggle",
                name = "Show Role Icons",
                order = 7,
                get = function() return E.db.raidframes.showRole end,
                set = function(_, v) E.db.raidframes.showRole = v end,
            },
            groupBy = {
                type = "select",
                name = "Group By",
                values = {
                    ["GROUP"] = "Group",
                    ["CLASS"] = "Class",
                    ["ROLE"] = "Role",
                },
                order = 8,
                get = function() return E.db.raidframes.groupBy end,
                set = function(_, v) E.db.raidframes.groupBy = v end,
            },
            dispelHighlight = {
                type = "toggle",
                name = "Dispel Highlight",
                order = 9,
                get = function() return E.db.raidframes.dispelHighlight end,
                set = function(_, v) E.db.raidframes.dispelHighlight = v end,
            },
        },
    }
end

--[[
    Skins Options
]]
function E:GetSkinsOptions()
    return {
        type = "group",
        name = "Skins",
        order = 12,
        args = {
            header = {
                type = "header",
                name = "UI Skins",
                order = 1,
            },
            desc = {
                type = "description",
                name = "Enable skinning for various Blizzard UI elements.\n\n",
                order = 2,
            },
            enabled = {
                type = "toggle",
                name = "Enable Skins",
                order = 3,
                get = function() return E.db.skins.enabled end,
                set = function(_, v) E.db.skins.enabled = v end,
            },
            characterFrame = {
                type = "toggle",
                name = "Character Frame",
                order = 10,
                get = function() return E.db.skins.characterFrame end,
                set = function(_, v) E.db.skins.characterFrame = v end,
            },
            spellbook = {
                type = "toggle",
                name = "Spellbook",
                order = 11,
                get = function() return E.db.skins.spellbook end,
                set = function(_, v) E.db.skins.spellbook = v end,
            },
            talents = {
                type = "toggle",
                name = "Talents",
                order = 12,
                get = function() return E.db.skins.talents end,
                set = function(_, v) E.db.skins.talents = v end,
            },
            questLog = {
                type = "toggle",
                name = "Quest Log",
                order = 13,
                get = function() return E.db.skins.questLog end,
                set = function(_, v) E.db.skins.questLog = v end,
            },
            worldMap = {
                type = "toggle",
                name = "World Map",
                order = 14,
                get = function() return E.db.skins.worldMap end,
                set = function(_, v) E.db.skins.worldMap = v end,
            },
            lfg = {
                type = "toggle",
                name = "LFG/Dungeon Finder",
                order = 15,
                get = function() return E.db.skins.lfg end,
                set = function(_, v) E.db.skins.lfg = v end,
            },
            tradeskill = {
                type = "toggle",
                name = "Tradeskill",
                order = 16,
                get = function() return E.db.skins.tradeskill end,
                set = function(_, v) E.db.skins.tradeskill = v end,
            },
            gossip = {
                type = "toggle",
                name = "Gossip/NPC Dialog",
                order = 17,
                get = function() return E.db.skins.gossip end,
                set = function(_, v) E.db.skins.gossip = v end,
            },
        },
    }
end

--[[
    Misc Options
]]
function E:GetMiscOptions()
    return {
        type = "group",
        name = "Miscellaneous",
        order = 13,
        args = {
            header = {
                type = "header",
                name = "Miscellaneous Settings",
                order = 1,
            },
            autoRepair = {
                type = "toggle",
                name = "Auto Repair",
                order = 2,
                get = function() return E.db.misc.autoRepair end,
                set = function(_, v) E.db.misc.autoRepair = v end,
            },
            autoSellJunk = {
                type = "toggle",
                name = "Auto Sell Junk",
                order = 3,
                get = function() return E.db.misc.autoSellJunk end,
                set = function(_, v) E.db.misc.autoSellJunk = v end,
            },
            autoAcceptInvite = {
                type = "toggle",
                name = "Auto Accept Guild Invites",
                order = 4,
                get = function() return E.db.misc.autoAcceptInvite end,
                set = function(_, v) E.db.misc.autoAcceptInvite = v end,
            },
            autoAcceptSummon = {
                type = "toggle",
                name = "Auto Accept Summons",
                order = 5,
                get = function() return E.db.misc.autoAcceptSummon end,
                set = function(_, v) E.db.misc.autoAcceptSummon = v end,
            },
            autoRelease = {
                type = "toggle",
                name = "Auto Release in BGs",
                order = 6,
                get = function() return E.db.misc.autoRelease end,
                set = function(_, v) E.db.misc.autoRelease = v end,
            },
            hideErrors = {
                type = "toggle",
                name = "Hide Error Messages",
                order = 7,
                get = function() return E.db.misc.hideErrors end,
                set = function(_, v) E.db.misc.hideErrors = v end,
            },
            afkScreen = {
                type = "toggle",
                name = "AFK Screen",
                order = 8,
                get = function() return E.db.misc.afkScreen end,
                set = function(_, v) E.db.misc.afkScreen = v end,
            },
            lootConfirm = {
                type = "toggle",
                name = "Skip Loot Confirmation",
                order = 9,
                get = function() return E.db.misc.lootConfirm end,
                set = function(_, v) E.db.misc.lootConfirm = v end,
            },
        },
    }
end
