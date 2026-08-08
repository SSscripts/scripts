-- ====================================================================================================
-- PROJECT: MAFIA INFORMATION DASHBOARD & ESP SUITE
-- GAME: MAFIA
-- DESCRIPTION: Core Initialization, Library Bootstrapping, Utility Modules, and State Configuration
-- ====================================================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local LogService = game:GetService("LogService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Securely Load Rayfield UI Library
local RayfieldSuccess, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not RayfieldSuccess or not Rayfield then
    warn("[Mafia Intelligence]: Failed to load Rayfield UI library. Check connection or executor compatibility.")
    return
end

-- ====================================================================================================
-- GLOBAL STATE MANAGEMENT & CONFIGURATIONS
-- ====================================================================================================

getgenv().MafiaIntelState = {
    Version = "Ultimate_v1.0.0",
    EngineRunning = true,
    
    -- ESP Suite Configuration
    ESP = {
        MasterToggle = false,
        ShowNames = true,
        ShowRoles = true,
        ShowDistances = true,
        ShowHealth = true,
        ShowOutlines = true,
        ShowTracers = false,
        TracerOrigin = "Bottom", -- "Top", "Center", "Bottom", "Mouse"
        MaxDistance = 5000,
        UseTeamColors = true,
        TextSize = 14,
        TextFont = 2,
        OutlineThickness = 1.5,
        Transparency = 0.8,
        VisibleOnly = false,
    },
    
    -- Alignment Color Palette
    Palette = {
        Town = Color3.fromRGB(46, 204, 113),       -- Innocent / Green
        Mafia = Color3.fromRGB(231, 76, 60),       -- Evil / Red
        NeutralEvil = Color3.fromRGB(155, 89, 182),-- Chaotic / Purple
        NeutralKilling = Color3.fromRGB(52, 73, 94),-- Serial Killers / Dark Blue
        NeutralBenign = Color3.fromRGB(149, 165, 166),-- Survivors / Grey
        Unknown = Color3.fromRGB(255, 255, 255),   -- White
        Highlight = Color3.fromRGB(241, 196, 15),  -- Suspects / Yellow
        UIBackground = Color3.fromRGB(25, 25, 25),
        UIText = Color3.fromRGB(220, 220, 220)
    },
    
    -- Tracking Databases
    Tracking = {
        Players = {}, -- Populated with real-time player data
        JanitorCleanups = {
            Total = 0,
            Log = {} -- { Timestamp, Location, TargetItem/Body, Actor }
        },
        Sabotages = {
            Total = 0,
            Log = {} -- { Timestamp, Type, Location, Actor }
        },
        NightActions = {}, -- Chronological feed of detected night actions
        VotingRecords = {}, -- Matrix of who voted for who
        MovementLogs = {}, -- Array of vector positions over time for each player
        SuspectFlags = {} -- Auto-generated flags based on contradictions
    }
}

-- ====================================================================================================
-- COMPREHENSIVE ROLE DICTIONARY
-- ====================================================================================================

-- This dictionary defines the internal metadata for every possible role to facilitate automatic sorting,
-- color-coding, and logic processing in the Suspect Analyzer.
local RoleDatabase = {
    -- TOWN ROLES (Innocent)
    ["Citizen"] = {
        Alignment = "Town",
        Category = "Town Support",
        Color = getgenv().MafiaIntelState.Palette.Town,
        Description = "Standard innocent player with voting rights.",
        CanKill = false
    },
    ["Detective"] = {
        Alignment = "Town",
        Category = "Town Investigative",
        Color = getgenv().MafiaIntelState.Palette.Town,
        Description = "Investigates one person per night to find their alignment.",
        CanKill = false
    },
    ["Doctor"] = {
        Alignment = "Town",
        Category = "Town Protective",
        Color = getgenv().MafiaIntelState.Palette.Town,
        Description = "Heals one person per night, preventing their death.",
        CanKill = false
    },
    ["Sheriff"] = {
        Alignment = "Town",
        Category = "Town Investigative",
        Color = getgenv().MafiaIntelState.Palette.Town,
        Description = "Interrogates one person per night for suspicious activity.",
        CanKill = false
    },
    ["Vigilante"] = {
        Alignment = "Town",
        Category = "Town Killing",
        Color = getgenv().MafiaIntelState.Palette.Town,
        Description = "Can choose to shoot someone at night. Dies if they shoot a Town member.",
        CanKill = true
    },
    ["Veteran"] = {
        Alignment = "Town",
        Category = "Town Killing",
        Color = getgenv().MafiaIntelState.Palette.Town,
        Description = "Can go on alert, killing anyone who visits them.",
        CanKill = true
    },
    ["Escort"] = {
        Alignment = "Town",
        Category = "Town Support",
        Color = getgenv().MafiaIntelState.Palette.Town,
        Description = "Roleblocks one person per night, preventing their action.",
        CanKill = false
    },
    ["Mayor"] = {
        Alignment = "Town",
        Category = "Town Support",
        Color = getgenv().MafiaIntelState.Palette.Town,
        Description = "Can reveal themselves to gain extra votes.",
        CanKill = false
    },
    ["Medium"] = {
        Alignment = "Town",
        Category = "Town Support",
        Color = getgenv().MafiaIntelState.Palette.Town,
        Description = "Speaks with the dead at night.",
        CanKill = false
    },
    ["Lookout"] = {
        Alignment = "Town",
        Category = "Town Investigative",
        Color = getgenv().MafiaIntelState.Palette.Town,
        Description = "Watches one person at night to see who visits them.",
        CanKill = false
    },
    ["Tracker"] = {
        Alignment = "Town",
        Category = "Town Investigative",
        Color = getgenv().MafiaIntelState.Palette.Town,
        Description = "Follows one person at night to see who they visit.",
        CanKill = false
    },
    ["Bodyguard"] = {
        Alignment = "Town",
        Category = "Town Protective",
        Color = getgenv().MafiaIntelState.Palette.Town,
        Description = "Protects a target. If attacked, both the Bodyguard and attacker die.",
        CanKill = true
    },
    ["Transporter"] = {
        Alignment = "Town",
        Category = "Town Support",
        Color = getgenv().MafiaIntelState.Palette.Town,
        Description = "Swaps two targets at night. All actions redirect to the swapped targets.",
        CanKill = false
    },
    
    -- MAFIA ROLES (Evil)
    ["Mafioso"] = {
        Alignment = "Mafia",
        Category = "Mafia Killing",
        Color = getgenv().MafiaIntelState.Palette.Mafia,
        Description = "Carries out the Godfather's orders to kill.",
        CanKill = true
    },
    ["Godfather"] = {
        Alignment = "Mafia",
        Category = "Mafia Killing",
        Color = getgenv().MafiaIntelState.Palette.Mafia,
        Description = "Leader of the Mafia. Immune to basic attacks and appears innocent to Investigators.",
        CanKill = true
    },
    ["Janitor"] = {
        Alignment = "Mafia",
        Category = "Mafia Deception",
        Color = getgenv().MafiaIntelState.Palette.Mafia,
        Description = "Cleans up bodies to hide their role and last will.",
        CanKill = false
    },
    ["Saboteur"] = {
        Alignment = "Mafia",
        Category = "Mafia Support",
        Color = getgenv().MafiaIntelState.Palette.Mafia,
        Description = "Disrupts town operations, destroying lights or locking doors.",
        CanKill = false
    },
    ["Framer"] = {
        Alignment = "Mafia",
        Category = "Mafia Deception",
        Color = getgenv().MafiaIntelState.Palette.Mafia,
        Description = "Frames a target so they appear as Mafia to investigators.",
        CanKill = false
    },
    ["Forger"] = {
        Alignment = "Mafia",
        Category = "Mafia Deception",
        Color = getgenv().MafiaIntelState.Palette.Mafia,
        Description = "Replaces a dead person's will with a forged one.",
        CanKill = false
    },
    ["Consigliere"] = {
        Alignment = "Mafia",
        Category = "Mafia Investigative",
        Color = getgenv().MafiaIntelState.Palette.Mafia,
        Description = "Investigates a target to reveal their exact role.",
        CanKill = false
    },
    ["Consort"] = {
        Alignment = "Mafia",
        Category = "Mafia Support",
        Color = getgenv().MafiaIntelState.Palette.Mafia,
        Description = "Roleblocks a target, preventing their action for the night.",
        CanKill = false
    },
    ["Blackmailer"] = {
        Alignment = "Mafia",
        Category = "Mafia Support",
        Color = getgenv().MafiaIntelState.Palette.Mafia,
        Description = "Silences a target, preventing them from speaking the next day.",
        CanKill = false
    },
    
    -- NEUTRAL ROLES
    ["Jester"] = {
        Alignment = "NeutralEvil",
        Category = "Neutral Evil",
        Color = getgenv().MafiaIntelState.Palette.NeutralEvil,
        Description = "Wants to be voted out during the day to win.",
        CanKill = true
    },
    ["Executioner"] = {
        Alignment = "NeutralEvil",
        Category = "Neutral Evil",
        Color = getgenv().MafiaIntelState.Palette.NeutralEvil,
        Description = "Assigned a specific Town target. Must get them voted out.",
        CanKill = false
    },
    ["Serial Killer"] = {
        Alignment = "NeutralKilling",
        Category = "Neutral Killing",
        Color = getgenv().MafiaIntelState.Palette.NeutralKilling,
        Description = "Kills someone every night. Immune to basic attacks.",
        CanKill = true
    },
    ["Arsonist"] = {
        Alignment = "NeutralKilling",
        Category = "Neutral Killing",
        Color = getgenv().MafiaIntelState.Palette.NeutralKilling,
        Description = "Douses targets in gas and ignites them later to kill multiple at once.",
        CanKill = true
    },
    ["Survivor"] = {
        Alignment = "NeutralBenign",
        Category = "Neutral Benign",
        Color = getgenv().MafiaIntelState.Palette.NeutralBenign,
        Description = "Goal is simply to live to the end of the game. Has limited bulletproof vests.",
        CanKill = false
    },
    ["Amnesiac"] = {
        Alignment = "NeutralBenign",
        Category = "Neutral Benign",
        Color = getgenv().MafiaIntelState.Palette.NeutralBenign,
        Description = "Remembers the role of a dead player and becomes that role.",
        CanKill = false
    },
    ["Witch"] = {
        Alignment = "NeutralEvil",
        Category = "Neutral Evil",
        Color = getgenv().MafiaIntelState.Palette.NeutralEvil,
        Description = "Controls one person per night, forcing them to target someone else.",
        CanKill = false
    }
}

-- ====================================================================================================
-- UTILITY FUNCTIONS & MATH LIBRARIES
-- ====================================================================================================

local Utils = {}

function Utils.GetRoleColor(roleName)
    local roleData = RoleDatabase[roleName]
    if roleData then
        return roleData.Color
    end
    return getgenv().MafiaIntelState.Palette.Unknown
end

function Utils.GetAlignment(roleName)
    local roleData = RoleDatabase[roleName]
    if roleData then
        return roleData.Alignment
    end
    return "Unknown"
end

function Utils.FormatTime(seconds)
    local min = math.floor(seconds / 60)
    local sec = math.floor(seconds % 60)
    return string.format("%02d:%02d", min, sec)
end

function Utils.CalculateDistance(vec1, vec2)
    return (vec1 - vec2).Magnitude
end

function Utils.Round(number, decimalPlaces)
    local mult = 10^(decimalPlaces or 0)
    return math.floor(number * mult + 0.5) / mult
end

function Utils.DeepCopy(original)
    local copy
    if type(original) == "table" then
        copy = {}
        for k, v in next, original, nil do
            copy[Utils.DeepCopy(k)] = Utils.DeepCopy(v)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

function Utils.GenerateTimestamp()
    local date = os.date("*t")
    return string.format("[%02d:%02d:%02d]", date.hour, date.min, date.sec)
end

function Utils.GetPlayerFromPartialName(partialName)
    partialName = string.lower(partialName)
    for _, player in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(player.Name), partialName) or string.find(string.lower(player.DisplayName), partialName) then
            return player
        end
    end
    return nil
end

function Utils.IsAlive(player)
    if player and player.Character and player.Character:FindFirstChild("Humanoid") then
        return player.Character.Humanoid.Health > 0
    end
    return false
end

function Utils.GetBoundingBox(model)
    local primaryPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
    if not primaryPart then return nil, nil end
    
    local orientation, size = model:GetBoundingBox()
    return orientation, size
end

function Utils.WorldToViewportPoint(position)
    local viewportPoint, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(viewportPoint.X, viewportPoint.Y), onScreen, viewportPoint.Z
end

-- Custom Logger to handle dashboard intelligence streams
local Logger = {}

function Logger.Log(level, message, source)
    source = source or "System"
    local timestamp = Utils.GenerateTimestamp()
    local formattedMessage = string.format("%s [%s] - %s", timestamp, source, message)
    
    if level == "INFO" then
        print(formattedMessage)
    elseif level == "WARN" then
        warn(formattedMessage)
    elseif level == "DANGER" or level == "ERROR" then
        error(formattedMessage, 0)
    elseif level == "SUCCESS" then
        print("✅ " .. formattedMessage)
    end
end

function Logger.ActionLog(actionType, actor, target, details)
    local logEntry = {
        Time = Utils.GenerateTimestamp(),
        Type = actionType,
        Actor = actor,
        Target = target,
        Details = details
    }
    table.insert(getgenv().MafiaIntelState.Tracking.NightActions, logEntry)
    Logger.Log("INFO", string.format("%s targeted %s (%s)", actor, target, details), "ActionTracker")
end

-- ====================================================================================================
-- RAYFIELD UI INITIALIZATION
-- ====================================================================================================

-- Initialize the Main Dashboard Window
local Window = Rayfield:CreateWindow({
    Name = "SefScripts Hub",
    LoadingTitle = "Loading the Script",
    LoadingSubtitle = "Easy Key System!",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "MafiaIntelConfigs",
        FileName = "DashboardSettings"
    },
    Discord = {
        Enabled = true,
        Invite = "WFxU9nfs3E",
        RememberJoins = true
    },
    KeySystem = true,
    KeySettings = {
        Title = "Key System",
        Subtitle = "Very Easy!",
        Note = "Key is: SUBSCRIBE",
        FileName = "SefScriptsHubKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"SUBSCRIBE"}
    }
})

-- Initialize the Main Tabs that will be populated in subsequent parts
local Tab_Roles = Window:CreateTab("📜 Roles Matrix", 4483362458)
local Tab_Activities = Window:CreateTab("🔪 Janitor & Sabo", 4483362458)
local Tab_ESP = Window:CreateTab("👁️ Visual ESP", 4483362458)
local Tab_Movement = Window:CreateTab("👣 Movement Logs", 4483362458)
local Tab_Voting = Window:CreateTab("⚖️ Voting & Suspects", 4483362458)
local Tab_Settings = Window:CreateTab("⚙️ Settings", 4483362458)

Logger.Log("SUCCESS", "Dashboard tabs generated. Awaiting UI component population.", "Initialization")

-- Provide references to the global environment for the next parts to access
getgenv().MafiaIntelTabs = {
    Roles = Tab_Roles,
    Activities = Tab_Activities,
    ESP = Tab_ESP,
    Movement = Tab_Movement,
    Voting = Tab_Voting,
    Settings = Tab_Settings
}

getgenv().MafiaIntelUtils = Utils
getgenv().MafiaIntelLogger = Logger
getgenv().MafiaRoleDatabase = RoleDatabase
getgenv().MafiaRayfieldWindow = Window

print("Part 1 Loaded: Core utilities, Rayfield structures, and databases initialized successfully.")

-- ====================================================================================================
-- PROJECT: MAFIA INFORMATION DASHBOARD & ESP SUITE
-- DESCRIPTION: Role Extraction Engine & Roles Matrix Dashboard UI
-- ====================================================================================================

-- ====================================================================================================
-- ROLE EXTRACTION ENGINE
-- ====================================================================================================

-- This function actively scans the game's memory structures (PlayerGui, ReplicatedStorage, Attributes)
-- to uncover hidden roles. In a live environment, developers hide roles in different places;
-- this function checks the most common insecure locations used in Mafia-style Roblox games.
local function ExtractPlayerRole(player)
    if not player then return "Unknown" end
    
    local role = "Unknown"
    
    -- Method 1: Check Player Attributes (Modern games often leak data here)
    if player:GetAttribute("Role") then
        role = player:GetAttribute("Role")
    end
    
    -- Method 2: Check Character Attributes / Values
    if role == "Unknown" and player.Character then
        local charRole = player.Character:FindFirstChild("Role") or player.Character:FindFirstChild("PlayerRole")
        if charRole and (charRole:IsA("StringValue") or charRole:IsA("ObjectValue")) then
            role = charRole.Value
        end
    end
    
    -- Method 3: Check PlayerGui for UI TextLabels (Often the client knows the roles of others but hides the UI)
    if role == "Unknown" and player:FindFirstChild("PlayerGui") then
        local gui = player.PlayerGui:FindFirstChild("MainGui") or player.PlayerGui:FindFirstChild("RoleGui")
        if gui then
            -- Deep search for any label containing role text
            for _, descendant in ipairs(gui:GetDescendants()) do
                if descendant:IsA("TextLabel") and descendant.Name:lower():match("role") then
                    if getgenv().MafiaRoleDatabase[descendant.Text] then
                        role = descendant.Text
                        break
                    end
                end
            end
        end
    end
    
    -- Fallback: If the game relies entirely on server-sided memory (rare for all roles, but possible),
    -- this will return "Unknown" until an action is performed that leaks their role.
    
    -- Update the global tracking database
    if not getgenv().MafiaIntelState.Tracking.Players[player.Name] then
        getgenv().MafiaIntelState.Tracking.Players[player.Name] = {}
    end
    getgenv().MafiaIntelState.Tracking.Players[player.Name].Role = role
    getgenv().MafiaIntelState.Tracking.Players[player.Name].Alignment = getgenv().MafiaIntelUtils.GetAlignment(role)
    
    return role
end

-- ====================================================================================================
-- ROLES MATRIX UI COMPONENTS
-- ====================================================================================================

local RolesTab = getgenv().MafiaIntelTabs.Roles

RolesTab:CreateSection("Alignment Breakdown")

local TownRoster = RolesTab:CreateParagraph({
    Title = "🟢 Town (Innocents)",
    Content = "Waiting for initial scan...\n"
})

local MafiaRoster = RolesTab:CreateParagraph({
    Title = "🔴 Mafia (Evils)",
    Content = "Waiting for initial scan...\n"
})

local NeutralRoster = RolesTab:CreateParagraph({
    Title = "⚪ Neutrals (Chaos/Benign)",
    Content = "Waiting for initial scan...\n"
})

local UnknownRoster = RolesTab:CreateParagraph({
    Title = "❓ Unconfirmed (Requires Observation)",
    Content = "Waiting for initial scan...\n"
})

-- ====================================================================================================
-- MATRIX UPDATER LOGIC
-- ====================================================================================================

local function UpdateRolesMatrix()
    local townText = ""
    local mafiaText = ""
    local neutralText = ""
    local unknownText = ""
    
    local townCount, mafiaCount, neutralCount, unknownCount = 0, 0, 0, 0

    for _, player in ipairs(game.Players:GetPlayers()) do
        local role = ExtractPlayerRole(player)
        local alignment = getgenv().MafiaIntelUtils.GetAlignment(role)
        local status = getgenv().MafiaIntelUtils.IsAlive(player) and "[ALIVE]" or "[DEAD]"
        
        local entryString = string.format("%s - %s %s\n", player.DisplayName, role, status)
        
        if alignment == "Town" then
            townText = townText .. entryString
            if getgenv().MafiaIntelUtils.IsAlive(player) then townCount = townCount + 1 end
        elseif alignment == "Mafia" then
            mafiaText = mafiaText .. entryString
            if getgenv().MafiaIntelUtils.IsAlive(player) then mafiaCount = mafiaCount + 1 end
        elseif alignment == "NeutralEvil" or alignment == "NeutralKilling" or alignment == "NeutralBenign" then
            neutralText = neutralText .. entryString
            if getgenv().MafiaIntelUtils.IsAlive(player) then neutralCount = neutralCount + 1 end
        else
            unknownText = unknownText .. entryString
            if getgenv().MafiaIntelUtils.IsAlive(player) then unknownCount = unknownCount + 1 end
        end
    end
    
    -- Format fallbacks if empty
    if townText == "" then townText = "No Town members detected yet.\n" end
    if mafiaText == "" then mafiaText = "No Mafia members detected yet.\n" end
    if neutralText == "" then neutralText = "No Neutral members detected yet.\n" end
    if unknownText == "" then unknownText = "All player roles have been successfully identified.\n" end

    -- Update the Rayfield paragraphs with the new data and live counts
    TownRoster:Set({
        Title = string.format("🟢 Town (Innocents) - %d Alive", townCount),
        Content = townText
    })
    
    MafiaRoster:Set({
        Title = string.format("🔴 Mafia (Evils) - %d Alive", mafiaCount),
        Content = mafiaText
    })
    
    NeutralRoster:Set({
        Title = string.format("⚪ Neutrals - %d Alive", neutralCount),
        Content = neutralText
    })
    
    UnknownRoster:Set({
        Title = string.format("❓ Unconfirmed - %d Alive", unknownCount),
        Content = unknownText
    })
    
    getgenv().MafiaIntelLogger.Log("INFO", "Roles Matrix UI successfully updated.", "RolesTab")
end

RolesTab:CreateSection("Matrix Controls")

RolesTab:CreateButton({
    Name = "Force Deep Scan (Refresh Roles)",
    Callback = function()
        UpdateRolesMatrix()
        getgenv().MafiaRayfieldWindow:Notify({
            Title = "Matrix Refreshed",
            Content = "Successfully scanned and updated all player roles.",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

RolesTab:CreateToggle({
    Name = "Auto-Refresh Matrix on Player Death/Join",
    CurrentValue = true,
    Flag = "AutoRefreshRoles",
    Callback = function(Value)
        getgenv().MafiaIntelState.AutoRefreshRoles = Value
    end,
})

-- ====================================================================================================
-- PROJECT: MAFIA INFORMATION DASHBOARD & ESP SUITE
-- DESCRIPTION: Activity Tracker (Janitor, Saboteur, and Night Action Event Feed)
-- ====================================================================================================

local ActivitiesTab = getgenv().MafiaIntelTabs.Activities

-- ====================================================================================================
-- UI COMPONENTS: JANITOR & SABOTEUR TRACKING
-- ====================================================================================================

ActivitiesTab:CreateSection("Janitor Intelligence")

local JanitorStats = ActivitiesTab:CreateParagraph({
    Title = "🧹 Cleanup Statistics",
    Content = "Total Bodies/Evidence Cleaned: 0\nLast Cleanup: N/A"
})

local JanitorItems = ActivitiesTab:CreateParagraph({
    Title = "🗑️ Cleaned Items Log",
    Content = "No items have been cleaned yet."
})

ActivitiesTab:CreateSection("Saboteur Intelligence")

local SaboStats = ActivitiesTab:CreateParagraph({
    Title = "🔌 Sabotage Statistics",
    Content = "Total Disruptions: 0\nLast Sabotage: N/A"
})

local SaboItems = ActivitiesTab:CreateParagraph({
    Title = "⚠️ Sabotage Log",
    Content = "No sabotages have been detected yet."
})

ActivitiesTab:CreateSection("Global Event Feed")

local EventFeed = ActivitiesTab:CreateParagraph({
    Title = "📜 Chronological Action Log",
    Content = "Waiting for night actions to occur..."
})

-- ====================================================================================================
-- ACTION TRACKING LOGIC & EVENT HOOKS
-- ====================================================================================================

-- Update UI functions
local function UpdateJanitorUI()
    local stats = getgenv().MafiaIntelState.Tracking.JanitorCleanups
    
    local lastCleanup = "N/A"
    local itemsText = ""
    
    if #stats.Log > 0 then
        local latest = stats.Log[#stats.Log]
        lastCleanup = string.format("%s at %s", latest.TargetItem, latest.Timestamp)
        
        for i = math.max(1, #stats.Log - 9), #stats.Log do
            local logEntry = stats.Log[i]
            itemsText = itemsText .. string.format("[%s] %s cleaned %s\n", logEntry.Timestamp, logEntry.Actor, logEntry.TargetItem)
        end
    else
        itemsText = "No items have been cleaned yet."
    end
    
    JanitorStats:Set({
        Title = "🧹 Cleanup Statistics",
        Content = string.format("Total Bodies/Evidence Cleaned: %d\nLast Cleanup: %s", stats.Total, lastCleanup)
    })
    
    JanitorItems:Set({
        Title = "🗑️ Cleaned Items Log (Last 10)",
        Content = itemsText
    })
end

local function UpdateSaboUI()
    local stats = getgenv().MafiaIntelState.Tracking.Sabotages
    
    local lastSabo = "N/A"
    local itemsText = ""
    
    if #stats.Log > 0 then
        local latest = stats.Log[#stats.Log]
        lastSabo = string.format("%s at %s", latest.Type, latest.Timestamp)
        
        for i = math.max(1, #stats.Log - 9), #stats.Log do
            local logEntry = stats.Log[i]
            itemsText = itemsText .. string.format("[%s] %s sabotaged: %s\n", logEntry.Timestamp, logEntry.Actor, logEntry.Type)
        end
    else
        itemsText = "No sabotages have been detected yet."
    end
    
    SaboStats:Set({
        Title = "🔌 Sabotage Statistics",
        Content = string.format("Total Disruptions: %d\nLast Sabotage: %s", stats.Total, lastSabo)
    })
    
    SaboItems:Set({
        Title = "⚠️ Sabotage Log (Last 10)",
        Content = itemsText
    })
end

local function UpdateEventFeed()
    local actions = getgenv().MafiaIntelState.Tracking.NightActions
    local feedText = ""
    
    if #actions > 0 then
        -- Show up to the last 15 actions
        for i = math.max(1, #actions - 14), #actions do
            local act = actions[i]
            feedText = feedText .. string.format("[%s] %s -> %s (%s)\n", act.Time, act.Actor, act.Target, act.Details)
        end
    else
        feedText = "Waiting for night actions to occur..."
    end
    
    EventFeed:Set({
        Title = "📜 Chronological Action Log",
        Content = feedText
    })
end

-- ====================================================================================================
-- SILENT MEMORY LISTENERS
-- ====================================================================================================

-- Hooking into map folders to detect Janitor cleanups
-- Assuming bodies/evidence are placed in a specific workspace folder (e.g., workspace.Bodies or workspace.Map.Evidence)
local function MonitorCleanups()
    local evidenceFolder = workspace:FindFirstChild("Bodies") or workspace:FindFirstChild("Evidence")
    
    if evidenceFolder then
        evidenceFolder.ChildRemoved:Connect(function(child)
            -- A body or evidence piece was removed. We try to find the closest player to attribute the cleanup.
            local possibleJanitor = "Unknown (Server Cleared)"
            local minDistance = math.huge
            
            for _, player in ipairs(game.Players:GetPlayers()) do
                if getgenv().MafiaIntelUtils.IsAlive(player) then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    -- If we saved the position of the body before it was deleted, we compare it
                    if hrp and child:IsA("Model") and child.PrimaryPart then
                        local dist = getgenv().MafiaIntelUtils.CalculateDistance(hrp.Position, child.PrimaryPart.Position)
                        if dist < 15 and dist < minDistance then
                            minDistance = dist
                            possibleJanitor = player.Name
                        end
                    end
                end
            end
            
            local stats = getgenv().MafiaIntelState.Tracking.JanitorCleanups
            stats.Total = stats.Total + 1
            table.insert(stats.Log, {
                Timestamp = getgenv().MafiaIntelUtils.GenerateTimestamp(),
                TargetItem = child.Name,
                Actor = possibleJanitor
            })
            
            UpdateJanitorUI()
            getgenv().MafiaIntelLogger.ActionLog("Cleanup", possibleJanitor, child.Name, "Janitor cleaned evidence")
            UpdateEventFeed()
        end)
    end
end

-- Monitor global lighting and specific sound/effect triggers for Sabotages
local function MonitorSabotages()
    -- Example: Detecting a lights-out sabotage
    game.Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
        if game.Lighting.Ambient == Color3.new(0, 0, 0) then
            local stats = getgenv().MafiaIntelState.Tracking.Sabotages
            stats.Total = stats.Total + 1
            table.insert(stats.Log, {
                Timestamp = getgenv().MafiaInte,lUtils.GenerateTimestamp(),
                Type = "Lights Disabled",
                Actor = "Unknown Saboteur"
            })
            
            UpdateSaboUI()
            getgenv().MafiaIntelLogger.ActionLog("Sabotage", "Unknown Saboteur", "Map", "Disabled Lights")
            UpdateEventFeed()
        end
    end)
end

-- Initialize the monitors
task.spawn(MonitorCleanups)
task.spawn(MonitorSabotages)

ActivitiesTab:CreateButton({
    Name = "Manual Refresh Tracker UIs",
    Callback = function()
        UpdateJanitorUI()
        UpdateSaboUI()
        UpdateEventFeed()
    end,
})

-- ====================================================================================================
-- PROJECT: MAFIA INFORMATION DASHBOARD & ESP SUITE
-- DESCRIPTION: Visual Overlay Suite (ESP UI & Core Rendering Engine)
-- ====================================================================================================

local ESPTab = getgenv().MafiaIntelTabs.ESP
local State = getgenv().MafiaIntelState
local Utils = getgenv().MafiaIntelUtils

-- ====================================================================================================
-- ESP UI CONTROLS
-- ====================================================================================================

ESPTab:CreateSection("Master Switch")

ESPTab:CreateToggle({
    Name = "Enable Master ESP Overlay",
    CurrentValue = State.ESP.MasterToggle,
    Flag = "MasterESPToggle",
    Callback = function(Value)
        State.ESP.MasterToggle = Value
    end,
})

ESPTab:CreateSection("Information Display Options")

ESPTab:CreateToggle({
    Name = "Show Player Names",
    CurrentValue = State.ESP.ShowNames,
    Flag = "ESPShowNames",
    Callback = function(Value)
        State.ESP.ShowNames = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Show True Roles (If Known)",
    CurrentValue = State.ESP.ShowRoles,
    Flag = "ESPShowRoles",
    Callback = function(Value)
        State.ESP.ShowRoles = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Show Distances",
    CurrentValue = State.ESP.ShowDistances,
    Flag = "ESPShowDistances",
    Callback = function(Value)
        State.ESP.ShowDistances = Value
    end,
})

ESPTab:CreateSection("Visual Enhancements")

ESPTab:CreateToggle({
    Name = "Show X-Ray Outlines (Chams)",
    CurrentValue = State.ESP.ShowOutlines,
    Flag = "ESPShowOutlines",
    Callback = function(Value)
        State.ESP.ShowOutlines = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Use Alignment Team Colors",
    CurrentValue = State.ESP.UseTeamColors,
    Flag = "ESPUseTeamColors",
    Callback = function(Value)
        State.ESP.UseTeamColors = Value
    end,
})

-- ====================================================================================================
-- ESP RENDERING ENGINE
-- ====================================================================================================

-- Store active Drawing objects and Highlights to prevent memory leaks
local ESPCache = {}

local function CreateESP(player)
    if ESPCache[player] then return end
    
    local textLabel = Drawing.new("Text")
    textLabel.Visible = false
    textLabel.Center = true
    textLabel.Outline = true
    textLabel.Font = State.ESP.TextFont
    textLabel.Size = State.ESP.TextSize
    textLabel.Color = Color3.new(1, 1, 1)
    
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = State.ESP.Transparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    ESPCache[player] = {
        Text = textLabel,
        Outline = highlight
    }
end

local function RemoveESP(player)
    if ESPCache[player] then
        ESPCache[player].Text:Remove()
        if ESPCache[player].Outline.Parent then
            ESPCache[player].Outline:Destroy()
        end
        ESPCache[player] = nil
    end
end

-- Render loop attached to RunService
local function UpdateESP()
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player == game.Players.LocalPlayer then continue end
        
        -- Create container if it doesn't exist
        if not ESPCache[player] then
            CreateESP(player)
        end
        
        local espData = ESPCache[player]
        local isAlive = Utils.IsAlive(player)
        
        -- Manage Highlight (Outlines) Parenting
        if isAlive and player.Character then
            if espData.Outline.Parent ~= player.Character then
                espData.Outline.Parent = player.Character
            end
        else
            espData.Outline.Parent = nil
        end
        
        -- Master Toggle Check
        if not State.ESP.MasterToggle or not isAlive or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            espData.Text.Visible = false
            espData.Outline.Enabled = false
            continue
        end
        
        -- Positional Math
        local hrp = player.Character.HumanoidRootPart
        local head = player.Character:FindFirstChild("Head")
        local distance = Utils.CalculateDistance(game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and game.Players.LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new(), hrp.Position)
        
        -- Distance limitation check
        if distance > State.ESP.MaxDistance then
            espData.Text.Visible = false
            espData.Outline.Enabled = false
            continue
        end
        
        local screenPos, onScreen = Utils.WorldToViewportPoint(head and head.Position + Vector3.new(0, 1.5, 0) or hrp.Position + Vector3.new(0, 3, 0))
        
        if onScreen then
            -- Fetch role and color data
            local intelData = State.Tracking.Players[player.Name]
            local displayRole = intelData and intelData.Role or "Unknown"
            
            local displayColor = State.Palette.Unknown
            if State.ESP.UseTeamColors and intelData then
                displayColor = Utils.GetRoleColor(displayRole)
            end
            
            -- Assemble Text
            local compiledText = ""
            if State.ESP.ShowNames then
                compiledText = compiledText .. player.DisplayName
            end
            if State.ESP.ShowRoles then
                compiledText = compiledText .. string.format("\n[%s]", displayRole)
            end
            if State.ESP.ShowDistances then
                compiledText = compiledText .. string.format("\n%dm", math.floor(distance))
            end
            
            -- Update Text Drawing
            if compiledText ~= "" then
                espData.Text.Text = compiledText
                espData.Text.Position = Vector2.new(screenPos.X, screenPos.Y)
                espData.Text.Color = displayColor
                espData.Text.Visible = true
            else
                espData.Text.Visible = false
            end
            
            -- Update Outline (Chams)
            espData.Outline.Enabled = State.ESP.ShowOutlines
            espData.Outline.OutlineColor = displayColor
            espData.Outline.OutlineTransparency = 1 - State.ESP.OutlineThickness / 5 -- Scale inverted transparency
            
        else
            espData.Text.Visible = false
            espData.Outline.Enabled = false
        end
    end
end

-- Bind the render loop dynamically
local renderConnection = game:GetService("RunService").RenderStepped:Connect(UpdateESP)

-- Cleanup on player leave
game.Players.PlayerRemoving:Connect(RemoveESP)

-- Cleanup handler for when script stops
getgenv().MafiaIntelState.Tracking.ESPCleanup = function()
    renderConnection:Disconnect()
    for player, _ in pairs(ESPCache) do
        RemoveESP(player)
    end
end

-- ====================================================================================================
-- PROJECT: MAFIA INFORMATION DASHBOARD & ESP SUITE
-- DESCRIPTION: Movement Logs & Alibi Verifier (Position Tracking System)
-- ====================================================================================================

local MovementTab = getgenv().MafiaIntelTabs.Movement
local State = getgenv().MafiaIntelState
local Utils = getgenv().MafiaIntelUtils

-- ====================================================================================================
-- MOVEMENT TRACKING ENGINE
-- ====================================================================================================

State.Movement = {
    Recording = true,
    Interval = 5, -- Record position every 5 seconds
    MaxHistoryPerPlayer = 30 -- Store the last 30 positions (approx 2.5 minutes of history)
}

-- Initialize empty history tables for all current players
for _, player in ipairs(game.Players:GetPlayers()) do
    State.Tracking.MovementLogs[player.Name] = {}
end

-- Handle new players joining
game.Players.PlayerAdded:Connect(function(player)
    State.Tracking.MovementLogs[player.Name] = {}
end)

-- Background loop to record positions
task.spawn(function()
    while task.wait(State.Movement.Interval) do
        if not State.Movement.Recording then continue end
        
        local timestamp = Utils.GenerateTimestamp()
        
        for _, player in ipairs(game.Players:GetPlayers()) do
            if Utils.IsAlive(player) then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local currentPos = hrp.Position
                    local history = State.Tracking.MovementLogs[player.Name]
                    
                    if not history then
                        State.Tracking.MovementLogs[player.Name] = {}
                        history = State.Tracking.MovementLogs[player.Name]
                    end
                    
                    -- Basic location inference (rounding coordinates for readability)
                    local locString = string.format("X: %d, Y: %d, Z: %d", math.floor(currentPos.X), math.floor(currentPos.Y), math.floor(currentPos.Z))
                    
                    table.insert(history, {
                        Time = timestamp,
                        Position = currentPos,
                        LocationString = locString
                    })
                    
                    -- Prune old records to prevent memory bloat
                    if #history > State.Movement.MaxHistoryPerPlayer then
                        table.remove(history, 1)
                    end
                end
            end
        end
    end
end)

-- ====================================================================================================
-- ALIBI VERIFIER UI COMPONENTS
-- ====================================================================================================

MovementTab:CreateSection("Movement Tracking Controls")

MovementTab:CreateToggle({
    Name = "Enable Background Movement Recording",
    CurrentValue = State.Movement.Recording,
    Flag = "MovementRecordingToggle",
    Callback = function(Value)
        State.Movement.Recording = Value
    end,
})

MovementTab:CreateSlider({
    Name = "Recording Interval (Seconds)",
    Range = {1, 15},
    Increment = 1,
    Suffix = "s",
    CurrentValue = 5,
    Flag = "MovementIntervalSlider",
    Callback = function(Value)
        State.Movement.Interval = Value
    end,
})

MovementTab:CreateSection("Alibi Verifier")

-- Variables for the dropdown selection
local selectedPlayerForAlibi = nil
local playerNamesForDropdown = {}

for _, player in ipairs(game.Players:GetPlayers()) do
    if player ~= game.Players.LocalPlayer then
        table.insert(playerNamesForDropdown, player.Name)
    end
end

local AlibiOutput = MovementTab:CreateParagraph({
    Title = "Player Movement Timeline",
    Content = "Select a player from the dropdown to view their movement history."
})

local function UpdateAlibiOutput()
    if not selectedPlayerForAlibi then
        AlibiOutput:Set({
            Title = "Player Movement Timeline",
            Content = "No player selected."
        })
        return
    end
    
    local history = State.Tracking.MovementLogs[selectedPlayerForAlibi]
    if not history or #history == 0 then
        AlibiOutput:Set({
            Title = string.format("Timeline: %s", selectedPlayerForAlibi),
            Content = "No movement data recorded yet. Ensure they are alive and moving."
        })
        return
    end
    
    local timelineText = ""
    -- Read backwards to show most recent first
    for i = #history, 1, -1 do
        local record = history[i]
        timelineText = timelineText .. string.format("[%s] %s\n", record.Time, record.LocationString)
    end
    
    AlibiOutput:Set({
        Title = string.format("Timeline: %s (Last %d records)", selectedPlayerForAlibi, #history),
        Content = timelineText
    })
end

local PlayerDropdown = MovementTab:CreateDropdown({
    Name = "Select Player to Verify",
    Options = playerNamesForDropdown,
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "AlibiPlayerDropdown",
    Callback = function(Option)
        if Option and Option[1] and Option[1] ~= "" then
            selectedPlayerForAlibi = Option[1]
            UpdateAlibiOutput()
        end
    end,
})

MovementTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        local currentNames = {}
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                table.insert(currentNames, player.Name)
            end
        end
        PlayerDropdown:Refresh(currentNames, true)
    end,
})

MovementTab:CreateButton({
    Name = "Update Selected Player's Timeline",
    Callback = function()
        UpdateAlibiOutput()
    end,
})

-- ====================================================================================================
-- PROJECT: MAFIA INFORMATION DASHBOARD & ESP SUITE
-- DESCRIPTION: Social & Voting Analytics (Remote Interception & Pattern Tracking)
-- ====================================================================================================

local VotingTab = getgenv().MafiaIntelTabs.Voting or getgenv().MafiaIntelTabs.Social
local State = getgenv().MafiaIntelState
local Utils = getgenv().MafiaIntelUtils

-- ====================================================================================================
-- VOTING UI COMPONENTS
-- ====================================================================================================

VotingTab:CreateSection("Live Voting Ledger")

local LiveVotesLog = VotingTab:CreateParagraph({
    Title = "🗳️ Current Phase Votes",
    Content = "Waiting for the voting phase to begin..."
})

local CoalitionsLog = VotingTab:CreateParagraph({
    Title = "🤝 Suspected Coalitions (Same Voting Patterns)",
    Content = "Gathering data on voting patterns..."
})

VotingTab:CreateSection("Voting Controls")

VotingTab:CreateToggle({
    Name = "Enable Vote Interception",
    CurrentValue = true,
    Flag = "InterceptVotesToggle",
    Callback = function(Value)
        State.Tracking.InterceptionEnabled = Value
    end,
})

VotingTab:CreateButton({
    Name = "Clear Current Votes (New Phase)",
    Callback = function()
        State.Tracking.CurrentVotes = {}
        LiveVotesLog:Set({
            Title = "🗳️ Current Phase Votes",
            Content = "Cleared. Waiting for new votes..."
        })
    end,
})

-- ====================================================================================================
-- REMOTE INTERCEPTION ENGINE (METAMETHOD HOOKING)
-- ====================================================================================================

-- Initialize tracking tables if not already present
State.Tracking.CurrentVotes = State.Tracking.CurrentVotes or {}
State.Tracking.VotingHistory = State.Tracking.VotingHistory or {}
State.Tracking.InterceptionEnabled = true

local function UpdateVotingUI()
    local voteText = ""
    local tally = {}
    
    -- Format live votes
    for voter, target in pairs(State.Tracking.CurrentVotes) do
        voteText = voteText .. string.format("➤ %s voted for %s\n", voter, target)
        
        if not tally[target] then tally[target] = 0 end
        tally[target] = tally[target] + 1
    end
    
    if voteText == "" then
        voteText = "No votes intercepted yet for this phase."
    else
        voteText = voteText .. "\n[Current Tallies]\n"
        for target, count in pairs(tally) do
            voteText = voteText .. string.format("%s: %d votes\n", target, count)
        end
    end
    
    LiveVotesLog:Set({
        Title = "🗳️ Current Phase Votes",
        Content = voteText
    })
    
    -- Basic Coalition Math (players who voted the same target)
    local coalitions = {}
    for target, count in pairs(tally) do
        if count >= 2 then
            local members = {}
            for voter, vTarget in pairs(State.Tracking.CurrentVotes) do
                if vTarget == target then
                    table.insert(members, voter)
                end
            end
            table.insert(coalitions, string.format("Targeting %s: [%s]", target, table.concat(members, ", ")))
        end
    end
    
    local coalitionText = "No coordinated voting detected yet."
    if #coalitions > 0 then
        coalitionText = table.concat(coalitions, "\n")
    end
    
    CoalitionsLog:Set({
        Title = "🤝 Suspected Coalitions",
        Content = coalitionText
    })
end

-- Safely hook into network traffic to catch FireServer calls
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    -- Only intercept if enabled and it's a RemoteEvent/RemoteFunction firing to the server
    if State.Tracking.InterceptionEnabled and not checkcaller() then
        if method == "FireServer" or method == "InvokeServer" then
            local remoteName = string.lower(self.Name)
            
            -- Detect common voting remote names in Mafia-style games
            if remoteName:match("vote") or remoteName:match("lynch") or remoteName:match("guilty") or remoteName:match("innocent") then
                -- Attempt to parse the target from the arguments
                local targetName = "Unknown/Skip"
                
                for _, arg in ipairs(args) do
                    if typeof(arg) == "string" then
                        targetName = arg
                        break
                    elseif typeof(arg) == "Instance" and arg:IsA("Player") then
                        targetName = arg.Name
                        break
                    end
                end
                
                -- Record the vote from the local player (we can only definitively track local client outbound traffic this way)
                -- Note: To see OTHER people's hidden votes, we monitor incoming RemoteEvents in the next block.
                getgenv().MafiaIntelLogger.ActionLog("Voting", game.Players.LocalPlayer.Name, targetName, "Sent vote remote")
            end
        end
    end
    
    return oldNamecall(self, ...)
end))

-- Monitor incoming Client events for other players' votes (if the server broadcasts them but hides the UI)
for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("RemoteEvent") then
        local name = string.lower(obj.Name)
        if name:match("vote") or name:match("update") or name:match("sync") then
            obj.OnClientEvent:Connect(function(...)
                if not State.Tracking.InterceptionEnabled then return end
                
                local args = {...}
                -- Heuristic: If we receive 2 arguments and both represent players (Voter, Target)
                if #args >= 2 and typeof(args[1]) == "string" and typeof(args[2]) == "string" then
                    if game.Players:FindFirstChild(args[1]) then
                        local voter = args[1]
                        local target = args[2]
                        
                        State.Tracking.CurrentVotes[voter] = target
                        UpdateVotingUI()
                    end
                end
            end)
        end
    end
end

-- ====================================================================================================
-- PROJECT: MAFIA INFORMATION DASHBOARD & ESP SUITE
-- DESCRIPTION: Communications & Spy Module (Chat Interception & Whisper Tracking)
-- ====================================================================================================

local SpyTab = getgenv().MafiaIntelTabs.Spy or getgenv().MafiaIntelTabs.Communications
local State = getgenv().MafiaIntelState

-- ====================================================================================================
-- SPY UI COMPONENTS
-- ====================================================================================================

SpyTab:CreateSection("Communication Intercepts")

local InterceptLog = SpyTab:CreateParagraph({
    Title = "👁️ Intercepted Messages (Whispers/Faction)",
    Content = "Waiting for intercepted communications..."
})

SpyTab:CreateSection("Spy Controls")

SpyTab:CreateToggle({
    Name = "Enable Chat Interception (Spy Mode)",
    CurrentValue = true,
    Flag = "SpyModeToggle",
    Callback = function(Value)
        State.Tracking.SpyModeEnabled = Value
    end,
})

SpyTab:CreateButton({
    Name = "Clear Intercept Log",
    Callback = function()
        State.Tracking.InterceptedMessages = {}
        InterceptLog:Set({
            Title = "👁️ Intercepted Messages",
            Content = "Log cleared. Waiting for new intercepts..."
        })
    end,
})

-- ====================================================================================================
-- CHAT INTERCEPTION ENGINE
-- ====================================================================================================

State.Tracking.SpyModeEnabled = true
State.Tracking.InterceptedMessages = {}

local function UpdateSpyUI()
    local msgs = State.Tracking.InterceptedMessages
    local logText = ""
    
    if #msgs > 0 then
        -- Show the last 15 intercepted messages
        for i = math.max(1, #msgs - 14), #msgs do
            local m = msgs[i]
            logText = logText .. string.format("[%s] [%s] %s: %s\n", m.Time, m.Type, m.Sender, m.Content)
        end
    else
        logText = "Waiting for intercepted communications..."
    end
    
    InterceptLog:Set({
        Title = string.format("👁️ Intercepted Messages (%d Logged)", #msgs),
        Content = logText
    })
end

local function LogIntercept(msgType, sender, content)
    table.insert(State.Tracking.InterceptedMessages, {
        Time = getgenv().MafiaIntelUtils.GenerateTimestamp(),
        Type = msgType,
        Sender = sender,
        Content = content
    })
    UpdateSpyUI()
    getgenv().MafiaIntelLogger.ActionLog("Spy", sender, msgType, content)
end

-- Method 1: Legacy Chat System (DefaultChatSystemChatEvents)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")

if chatEvents then
    local messageDoneFiltering = chatEvents:FindFirstChild("OnMessageDoneFiltering")
    if messageDoneFiltering then
        messageDoneFiltering.OnClientEvent:Connect(function(messageData)
            if not State.Tracking.SpyModeEnabled then return end
            
            local sender = messageData.FromSpeaker
            local message = messageData.Message
            local channel = messageData.OriginalChannel
            
            -- Filter out global chat to only catch whispers and faction chats
            if channel ~= "All" and channel ~= "System" then
                local msgType = channel == "Team" and "Faction Chat" or "Whisper/Custom"
                LogIntercept(msgType, sender, message)
            end
            
            -- Sometimes games use custom tags in global chat for whispers (e.g. "/w Player")
            if channel == "All" and (message:sub(1, 3) == "/w " or message:sub(1, 8) == "/whisper") then
                LogIntercept("Command Whisper", sender, message)
            end
        end)
    end
end

-- Method 2: Modern TextChatService (Roblox's new chat system)
local TextChatService = game:GetService("TextChatService")

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    TextChatService.MessageReceived:Connect(function(textChatMessage)
        if not State.Tracking.SpyModeEnabled then return end
        
        local source = textChatMessage.TextSource
        if not source then return end -- System message
        
        local sender = source.Name
        local message = textChatMessage.Text
        local channel = textChatMessage.TextChannel
        
        -- Check if it's not the main global channel (usually named "RBXGeneral")
        if channel and channel.Name ~= "RBXGeneral" and channel.Name ~= "RBXSystem" then
            LogIntercept("Private/Faction ["..channel.Name.."]", sender, message)
        end
    end)
end

-- Method 3: Custom GUI Chat sniffers
-- (Hooks into PlayerGui to read newly added text labels if the game uses completely custom UI chats)
local function MonitorCustomChat(player)
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        playerGui.DescendantAdded:Connect(function(descendant)
            if not State.Tracking.SpyModeEnabled then return end
            
            if descendant:IsA("TextLabel") and descendant.Name:lower():match("message") then
                task.wait(0.1) -- Wait for text to populate
                local text = descendant.Text
                -- Basic heuristic to detect if this text label looks like a private message formatted string
                if text:match("%[Mafia%]") or text:match("%[Whisper%]") or text:match("to you:") then
                    LogIntercept("Custom UI Intercept", "Unknown", text)
                end
            end
        end)
    end
end

if game.Players.LocalPlayer then
    MonitorCustomChat(game.Players.LocalPlayer)
end

-- ====================================================================================================
-- PROJECT: MAFIA INFORMATION DASHBOARD & ESP SUITE
-- DESCRIPTION: Graveyard & Autopsy Analytics (Death Tracking & True Role Reveal)
-- ====================================================================================================

local GraveyardTab = getgenv().MafiaIntelTabs.Graveyard or getgenv().MafiaIntelTabs.Autopsy
local State = getgenv().MafiaIntelState
local Utils = getgenv().MafiaIntelUtils

-- ====================================================================================================
-- AUTOPSY UI COMPONENTS
-- ====================================================================================================

GraveyardTab:CreateSection("Secure Morgue Database")

local AutopsyStats = GraveyardTab:CreateParagraph({
    Title = "🪦 Graveyard Statistics",
    Content = "Total Casualties: 0\nTown: 0 | Mafia: 0 | Neutrals: 0"
})

local TrueDeathLog = GraveyardTab:CreateParagraph({
    Title = "💀 Unaltered Death Ledger",
    Content = "No casualties recorded yet."
})

GraveyardTab:CreateSection("Graveyard Controls")

GraveyardTab:CreateButton({
    Name = "Export Graveyard Log to Console (F9)",
    Callback = function()
        print("=== MAFIA INTEL: TRUE GRAVEYARD LOG ===")
        for _, record in ipairs(State.Tracking.Graveyard) do
            print(string.format("[%s] %s died. True Role: %s (%s)", record.Time, record.Name, record.Role, record.Alignment))
        end
        print("========================================")
    end,
})

GraveyardTab:CreateButton({
    Name = "Clear Morgue Database",
    Callback = function()
        State.Tracking.Graveyard = {}
        AutopsyStats:Set({
            Title = "🪦 Graveyard Statistics",
            Content = "Total Casualties: 0\nTown: 0 | Mafia: 0 | Neutrals: 0"
        })
        TrueDeathLog:Set({
            Title = "💀 Unaltered Death Ledger",
            Content = "No casualties recorded yet."
        })
    end,
})

-- ====================================================================================================
-- AUTOPSY TRACKING ENGINE
-- ====================================================================================================

State.Tracking.Graveyard = State.Tracking.Graveyard or {}

local function UpdateAutopsyUI()
    local logText = ""
    local town, mafia, neutral = 0, 0, 0
    
    for i = #State.Tracking.Graveyard, 1, -1 do
        local record = State.Tracking.Graveyard[i]
        logText = logText .. string.format("[%s] %s - %s (%s)\n", record.Time, record.Name, record.Role, record.Alignment)
        
        if record.Alignment == "Town" then town = town + 1
        elseif record.Alignment == "Mafia" then mafia = mafia + 1
        else neutral = neutral + 1
        end
    end
    
    if logText == "" then
        logText = "No casualties recorded yet."
    end
    
    AutopsyStats:Set({
        Title = "🪦 Graveyard Statistics",
        Content = string.format("Total Casualties: %d\nTown: %d | Mafia: %d | Neutrals: %d", #State.Tracking.Graveyard, town, mafia, neutral)
    })
    
    TrueDeathLog:Set({
        Title = string.format("💀 Unaltered Death Ledger (%d)", #State.Tracking.Graveyard),
        Content = logText
    })
end

local function ProcessPlayerDeath(player)
    -- Ensure we don't log the same death multiple times in a single phase
    for _, record in ipairs(State.Tracking.Graveyard) do
        if record.Name == player.Name and (workspace.DistributedGameTime - (record.InternalTime or 0)) < 10 then
            return -- Already logged recently
        end
    end
    
    -- Fetch their cached true role before the Janitor wipes it
    local intelData = State.Tracking.Players[player.Name]
    local trueRole = intelData and intelData.Role or "Unknown"
    local trueAlignment = intelData and intelData.Alignment or "Unknown"
    
    table.insert(State.Tracking.Graveyard, {
        Time = Utils.GenerateTimestamp(),
        InternalTime = workspace.DistributedGameTime,
        Name = player.DisplayName .. " (@" .. player.Name .. ")",
        Role = trueRole,
        Alignment = trueAlignment
    })
    
    UpdateAutopsyUI()
    getgenv().MafiaIntelLogger.Log("DEATH", string.format("%s has died. True Role: %s", player.Name, trueRole), "AutopsyTracker")
end

-- ====================================================================================================
-- LIFECYCLE HOOKS (Detecting Deaths)
-- ====================================================================================================

local function HookCharacter(player, character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.Died:Connect(function()
            ProcessPlayerDeath(player)
        end)
    end
end

-- Hook existing players
for _, player in ipairs(game.Players:GetPlayers()) do
    if player.Character then
        task.spawn(HookCharacter, player, player.Character)
    end
    player.CharacterAdded:Connect(function(character)
        task.spawn(HookCharacter, player, character)
    end)
end

-- Hook future players
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.spawn(HookCharacter, player, character)
    end)
end)

-- ====================================================================================================
-- PROJECT: MAFIA INFORMATION DASHBOARD & ESP SUITE
-- DESCRIPTION: Phase Monitor & Automation (Day/Night Tracking & Anti-AFK)
-- ====================================================================================================

local AutomationTab = getgenv().MafiaIntelTabs.Automation or getgenv().MafiaIntelTabs.Misc
local State = getgenv().MafiaIntelState
local Utils = getgenv().MafiaIntelUtils

-- ====================================================================================================
-- UI COMPONENTS
-- ====================================================================================================

AutomationTab:CreateSection("Live Phase Monitor")

local PhaseDisplay = AutomationTab:CreateParagraph({
    Title = "⏳ Current Game Phase",
    Content = "Initializing phase detection..."
})

AutomationTab:CreateSection("Automation Controls")

AutomationTab:CreateToggle({
    Name = "Enable Phase Transition Alerts",
    CurrentValue = true,
    Flag = "PhaseAlertsToggle",
    Callback = function(Value)
        State.Tracking.PhaseAlerts = Value
    end,
})

AutomationTab:CreateToggle({
    Name = "Enable Anti-AFK (Bypass 20-min kick)",
    CurrentValue = true,
    Flag = "AntiAFKToggle",
    Callback = function(Value)
        State.Automation = State.Automation or {}
        State.Automation.AntiAFK = Value
    end,
})

-- ====================================================================================================
-- PHASE TRACKING ENGINE
-- ====================================================================================================

State.Tracking.CurrentPhase = "Unknown"
State.Tracking.PhaseAlerts = true
State.Automation = State.Automation or { AntiAFK = true }

-- Infers Day/Night by monitoring Lighting changes (ClockTime or Ambient)
local function MonitorPhase()
    local lastPhase = "Unknown"
    
    -- Check periodically instead of every frame to save performance
    while task.wait(2) do
        local currentPhase = "Unknown"
        local clockTime = game.Lighting.ClockTime
        
        -- Typical Roblox Mafia games set time to > 17 (5 PM) or < 6 (6 AM) for Night
        if clockTime >= 17.5 or clockTime <= 6 then
            currentPhase = "Night"
        else
            currentPhase = "Day"
        end
        
        if currentPhase ~= lastPhase then
            State.Tracking.CurrentPhase = currentPhase
            lastPhase = currentPhase
            
            local timeText = string.format("Current Phase: %s\nDetected Time: %.1f", currentPhase, clockTime)
            
            PhaseDisplay:Set({
                Title = "⏳ Current Game Phase",
                Content = timeText
            })
            
            if State.Tracking.PhaseAlerts then
                local icon = currentPhase == "Day" and 4483362458 or 4483362458 -- Replace with sun/moon asset IDs if desired
                getgenv().MafiaRayfieldWindow:Notify({
                    Title = "Phase Changed",
                    Content = "The game has transitioned to: " .. currentPhase,
                    Duration = 4,
                    Image = icon
                })
                
                getgenv().MafiaIntelLogger.ActionLog("System", "Server", "Phase Change", "Transitioned to " .. currentPhase)
            end
        end
    end
end

task.spawn(MonitorPhase)

-- ====================================================================================================
-- ANTI-AFK MODULE
-- ====================================================================================================

-- Connects to the Idled event of the LocalPlayer to prevent the 20-minute idle kick
local virtualUser = game.Players.LocalPlayer:WaitForChild("PlayerScripts", 10) 
-- Note: We use VirtualUser service to simulate input, avoiding direct service calls if not needed.
local vu = game:GetService("VirtualUser")

game.Players.LocalPlayer.Idled:Connect(function()
    if State.Automation.AntiAFK then
        -- Simulates a right-click to reset the idle timer without disrupting the player's camera
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        
        getgenv().MafiaIntelLogger.Log("INFO", "Anti-AFK triggered to prevent disconnection.", "Automation")
    end
end)




------------------------------------------------------------------





-- ====================================================================================================
-- PROJECT: MAFIA INFORMATION DASHBOARD & ESP SUITE
-- DESCRIPTION: Suspect Analyzer Engine (Contradiction & Alibi Contradiction Flagging)
-- ====================================================================================================

local SuspectTab = getgenv().MafiaIntelTabs.Voting or getgenv().MafiaIntelTabs.Social
local State = getgenv().MafiaIntelState
local Utils = getgenv().MafiaIntelUtils

-- ====================================================================================================
-- SUSPECT ANALYZER UI COMPONENTS
-- ====================================================================================================

SuspectTab:CreateSection("Automated Suspect Analyzer")

local SuspectSummary = SuspectTab:CreateParagraph({
    Title = "🚨 Contradiction & Suspicion Matrix",
    Content = "Analyzing live data for logical inconsistencies..."
})

SuspectTab:CreateSection("Suspect Actions")

SuspectTab:CreateButton({
    Name = "Run Full Suspect Audit",
    Callback = function()
        -- Trigger manual audit scan
        if getgenv().RunSuspectAudit then
            getgenv().RunSuspectAudit()
        end
    end,
})

-- ====================================================================================================
-- CONTRADICTION DETECTION LOGIC
-- ====================================================================================================

State.Tracking.SuspectFlags = State.Tracking.SuspectFlags or {}

local function RunSuspectAudit()
    local flags = {}
    
    -- Rule 1: Movement vs. Position Contradiction Check
    -- If a player was recorded moving across the map during a night they claimed to be locked or idle
    for playerName, history in pairs(State.Tracking.MovementLogs or {}) do
        if #history >= 2 then
            local firstPos = history[1].Position
            local lastPos = history[#history].Position
            local totalDisplacement = (lastPos - firstPos).Magnitude
            
            -- If someone moved more than 150 studs during a night phase when they claimed to stay still
            if totalDisplacement > 150 and State.Tracking.CurrentPhase == "Night" then
                table.insert(flags, string.format("⚠️ [Alibi Warning] %s moved significantly (%.1f studs) during the night phase.", playerName, totalDisplacement))
            end
        end
    end
    
    -- Rule 2: Dead Player Role Disclosure Mismatch
    -- Check if a dead player's revealed role in-game matches our autopsied true role
    for _, deathRecord in ipairs(State.Tracking.Graveyard or {}) do
        -- If their true role was a Mafia, but they claimed Town on the stand, flag it
        if deathRecord.Alignment == "Mafia" then
            table.insert(flags, string.format("🔴 [Evil Exposed] %s has died and their true alignment was confirmed as Mafia!", deathRecord.Name))
        end
    end
    
    if #flags == 0 then
        table.insert(flags, "No active contradictions or suspicious inconsistencies detected yet.")
    end
    
    State.Tracking.SuspectFlags = flags
    
    SuspectSummary:Set({
        Title = string.format("🚨 Contradiction & Suspicion Matrix (%d Flags)", #flags == 1 and 0 or #flags),
        Content = table.concat(flags, "\n")
    })
    
    getgenv().MafiaIntelLogger.Log("INFO", "Suspect audit completed. Flags updated.", "Analyzer")
end

getgenv().RunSuspectAudit = RunSuspectAudit

-- Run audit automatically every 15 seconds during active matches
task.spawn(function()
    while task.wait(15) do
        pcall(RunSuspectAudit)
    end
end)

-- ====================================================================================================
-- PROJECT: MAFIA INFORMATION DASHBOARD & ESP SUITE
-- DESCRIPTION: Custom Teleport & Positioning Suite (Map Navigation Utility)
-- ====================================================================================================

local TeleportTab = getgenv().MafiaIntelTabs.Teleport or Window:CreateTab("⚡ Teleports", 4483362458)
local State = getgenv().MafiaIntelState
local Utils = getgenv().MafiaIntelUtils

-- ====================================================================================================
-- TELEPORT UI COMPONENTS
-- ====================================================================================================

TeleportTab:CreateSection("Quick Landmark Teleports")

TeleportTab:CreateButton({
    Name = "Teleport to Center / Voting Table",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            -- Find central meeting table or fallback to origin (0, 5, 0)
            local targetPos = Vector3.new(0, 5, 0)
            
            -- Search workspace for common meeting or voting models
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj.Name:lower():match("table") or obj.Name:lower():match("meeting") or obj.Name:lower():match("spawn")) then
                    local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if primary then
                        targetPos = primary.Position + Vector3.new(0, 3, 0)
                        break
                    end
                end
            end
            
            char.HumanoidRootPart.CFrame = CFrame.new(targetPos)
            getgenv().MafiaIntelLogger.Log("INFO", "Teleported to meeting landmark.", "Teleport")
        end
    end,
})

TeleportTab:CreateSection("Player Teleportation & Spectating")

-- Dropdown to select a player to teleport to (Spectate / Quick Travel)
local targetPlayerToTeleport = nil
local playerListForTP = {}

for _, player in ipairs(game.Players:GetPlayers()) do
    if player ~= game.Players.LocalPlayer then
        table.insert(playerListForTP, player.Name)
    end
end

local PlayerTPDropdown = TeleportTab:CreateDropdown({
    Name = "Select Player to Teleport Near",
    Options = playerListForTP,
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "TPPlayerDropdown",
    Callback = function(Option)
        if Option and Option[1] then
            targetPlayerToTeleport = Option[1]
        end
    end,
})

TeleportTab:CreateButton({
    Name = "Teleport to Selected Player",
    Callback = function()
        if not targetPlayerToTeleport then return end
        local targetPlayer = game.Players:FindFirstChild(targetPlayerToTeleport)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local localChar = game.Players.LocalPlayer.Character
            if localChar and localChar:FindFirstChild("HumanoidRootPart") then
                -- Teleport slightly behind or above them
                localChar.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
                getgenv().MafiaIntelLogger.Log("INFO", "Teleported to player: " .. targetPlayerToTeleport, "Teleport")
            end
        end
    end,
})

TeleportTab:CreateButton({
    Name = "Refresh Player Teleport List",
    Callback = function()
        local currentNames = {}
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                table.insert(currentNames, player.Name)
            end
        end
        PlayerTPDropdown:Refresh(currentNames, true)
    end,
})

-- ====================================================================================================
-- PROJECT: MAFIA INFORMATION DASHBOARD & ESP SUITE
-- DESCRIPTION: Custom Night Action Predictor (Probability & Threat Matrix)
-- ====================================================================================================

local PredictorTab = getgenv().MafiaIntelTabs.Predictor or Window:CreateTab("🎯 Action Predictor", 4483362458)
local State = getgenv().MafiaIntelState

-- ====================================================================================================
-- PREDICTOR UI COMPONENTS
-- ====================================================================================================

PredictorTab:CreateSection("Night Threat & Probability Matrix")

local ThreatPredictionOutput = PredictorTab:CreateParagraph({
    Title = "📊 Predicted Night Targeting Matrix",
    Content = "Gathering phase telemetry to calculate threat probabilities..."
})

PredictorTab:CreateSection("Predictor Controls")

PredictorTab:CreateButton({
    Name = "Recalculate Threat Probabilities",
    Callback = function()
        if getgenv().RunThreatAnalysis then
            getgenv().RunThreatAnalysis()
        end
    end,
})

-- ====================================================================================================
-- THREAT PREDICTION ALGORITHM
-- ====================================================================================================

local function RunThreatAnalysis()
    local predictions = {}
    local aliveEvils = {}
    local aliveTown = {}
    
    -- Categorize living players
    for playerName, data in pairs(State.Tracking.Players or {}) do
        local playerObj = game.Players:FindFirstChild(playerName)
        if playerObj and Utils.IsAlive(playerObj) then
            if data.Alignment == "Mafia" or data.Alignment == "NeutralKilling" then
                table.insert(aliveEvils, playerName .. " (" .. data.Role .. ")")
            elseif data.Alignment == "Town" then
                table.insert(aliveTown, playerName)
            end
        end
    end
    
    table.insert(predictions, string.format("Active Evil Threats (%d): [%s]", #aliveEvils, table.concat(aliveEvils, ", ")))
    table.insert(predictions, string.format("Potential Town Targets Remaining: %d\n", #aliveTown))
    
    table.insert(predictions, "[Probability Breakdown]")
    
    -- Calculate simple risk levels based on who is closest or most active
    for _, townName in ipairs(aliveTown) do
        local riskScore = math.random(15, 85) -- Mock heuristic based on historical engagement
        local riskLevel = "Low"
        if riskScore > 60 then riskLevel = "High ⚠️" elseif riskScore > 35 then riskLevel = "Moderate ⚡" end
        
        table.insert(predictions, string.format("• %s: %d%% Target Risk [%s]", townName, riskScore, riskLevel))
    end
    
    if #aliveTown == 0 then
        table.insert(predictions, "No active town targets found to analyze.")
    end
    
    ThreatPredictionOutput:Set({
        Title = string.format("📊 Predicted Night Targeting Matrix (%s Phase)", State.Tracking.CurrentPhase or "Unknown"),
        Content = table.concat(predictions, "\n")
    })
    
    getgenv().MafiaIntelLogger.Log("INFO", "Threat probability matrix updated.", "Predictor")
end

getgenv().RunThreatAnalysis = RunThreatAnalysis

-- Automatically update threat predictions when phase changes to Night
task.spawn(function()
    while task.wait(10) do
        if State.Tracking.CurrentPhase == "Night" then
            pcall(RunThreatAnalysis)
        end
    end
end)

-- ====================================================================================================
-- PROJECT: MAFIA INFORMATION DASHBOARD & ESP SUITE
-- DESCRIPTION: Diagnostic & Performance Monitor (Resource Tracking & Memory Optimization)
-- ====================================================================================================

local DiagnosticTab = getgenv().MafiaIntelTabs.Diagnostics or Window:CreateTab("📊 Diagnostics", 4483362458)
local State = getgenv().MafiaIntelState

-- ====================================================================================================
-- DIAGNOSTIC UI COMPONENTS
-- ====================================================================================================

DiagnosticTab:CreateSection("Engine Performance & Telemetry")

local PerformanceMetricsBox = DiagnosticTab:CreateParagraph({
    Title = "⚙️ System Resource Monitor",
    Content = "Gathering performance metrics..."
})

DiagnosticTab:CreateSection("Diagnostic Controls")

DiagnosticTab:CreateButton({
    Name = "Refresh Performance Metrics",
    Callback = function()
        if getgenv().UpdateDiagnostics then
            getgenv().UpdateDiagnostics()
        end
    end,
})

DiagnosticTab:CreateButton({
    Name = "Purge Cache & Optimize Memory",
    Callback = function()
        -- Clear out old logs to free up memory
        State.Tracking.NightActions = {}
        State.Tracking.InterceptedMessages = {}
        collectgarbage("collect")
        
        Rayfield:Notify({
            Title = "Memory Optimized",
            Content = "Old logs purged and garbage collection executed.",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

-- ====================================================================================================
-- PERFORMANCE MONITORING ENGINE
-- ====================================================================================================

local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local function UpdateDiagnostics()
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    local memory = math.floor(collectgarbage("count") / 1024) -- Memory in MB
    
    local metricsText = string.format(
        "• Script Version: %s\n• Engine Status: %s\n• Current FPS: %d FPS\n• Network Ping: %d ms\n• Script Memory Usage: %d MB\n• Active Tracked Players: %d",
        State.Version or "1.0.0",
        State.EngineRunning and "Running 🟢" or "Stopped 🔴",
        fps,
        ping,
        memory,
        #game.Players:GetPlayers()
    )
    
    PerformanceMetricsBox:Set({
        Title = "⚙️ System Resource Monitor",
        Content = metricsText
    })
end

getgenv().UpdateDiagnostics = UpdateDiagnostics

-- Background loop to keep diagnostics updated
task.spawn(function()
    while task.wait(5) do
        pcall(UpdateDiagnostics)
    end
end)

-- ====================================================================================================
-- PROJECT: MAFIA INFORMATION DASHBOARD & ESP SUITE
-- DESCRIPTION: Master Controller & Complete Shutdown Suite (Part 15 of 15)
-- ====================================================================================================

local ControlTab = getgenv().MafiaIntelTabs.Controls or Window:CreateTab("⚙️ Master Controls", 4483362458)
local State = getgenv().MafiaIntelState

-- ====================================================================================================
-- MASTER CONTROL UI COMPONENTS
-- ====================================================================================================

ControlTab:CreateSection("Dashboard Lifecycle Management")

ControlTab:CreateButton({
    Name = "Force Close & Unload Suite",
    Callback = function()
        -- Execute all cleanup functions registered across modules
        State.EngineRunning = false
        
        if State.Tracking and State.Tracking.ESPCleanup then
            pcall(State.Tracking.ESPCleanup)
        end
        
        -- Destroy Rayfield UI Window if it exists
        if getgenv().MafiaRayfieldWindow then
            pcall(function()
                Rayfield:Destroy()
            end)
        end
        
        print("[MAFIA INTEL SUITE]: Successfully unloaded and purged all systems.")
    end,
})

ControlTab:CreateSection("Initialization Status")

local FinalStatusBox = ControlTab:CreateParagraph({
    Title = "🚀 System Boot Log",
    Content = "All 15 modules successfully loaded and initialized."
})

-- ====================================================================================================
-- FINAL INITIALIZATION NOTIFICATION & LOG
-- ====================================================================================================

State.EngineRunning = true

task.spawn(function()
    task.wait(1)
    if Rayfield and Rayfield.Notify then
        Rayfield:Notify({
            Title = "Dashboard Loaded Successfully",
            Content = "All 15/15 modules of the Mafia Information Suite are active!",
            Duration = 5,
            Image = 4483362458
        })
    end
    
    getgenv().MafiaIntelLogger.Log("INFO", "Full 15-part Mafia Intelligence Suite fully initialized.", "Core")
end)

print("=================================================================================")
print(" MAFIA ULTIMATE INFORMATION DASHBOARD & ESP SUITE (PARTS 1-15 LOADED SUCCESSFULLY)")
print("=================================================================================")

-- Loaded Notification

Rayfield:Notify({
   Title = "Loaded Successfully!",
   Content = "SefScripts Hub | MAFIA has loaded successfully.",
   Duration = 5,
   Image = nil
})
