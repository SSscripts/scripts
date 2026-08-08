-- =================================================================
-- PART 1: Core Environment Initialization & Rayfield UI Framework
-- =================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- Load Rayfield UI Library safely
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("Failed to load Rayfield UI library!")
    return
end

-- Create the main hub window with configuration and security key system
local Window = Rayfield:CreateWindow({
    Name = "SefScriptsHub",
    LoadingTitle = "SefScriptsHub | NDS DISASTER ENGINE",
    LoadingSubtitle = "Modular Cinematic Orbit & Strike System (Part 1)",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SefScriptsHub",
        FileName = "NDSMasterConfig"
    },
    KeySystem = true,
    KeySettings = {
nex        Title = "SefScriptsHub",
        Subtitle = "Security Key Verification",
        Note = "Enter Access Key: SUBSCRIBE",
        FileName = "SefAccessKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"SUBSCRIBE"}
    }
})

-- Core Services Definition
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Initialize Hub Tabs for subsequent parts
local OrbitTab = Window:CreateTab("Disaster Orbit", 4483362458)
local CombatTab = Window:CreateTab("Disaster Strike", 4483362458)

Rayfield:Notify({
    Title = "Part 1 Initialized",
    Content = "UI Framework & Core Services loaded successfully.",
    Duration = 4,
    Image = 4483362458
})

-- =================================================================
-- PART 2: Global State Variables & Multi-Layer Orbit Configuration
-- =================================================================

-- Core State Flags
local isOrbiting = false
local isExecuting = false

-- Collections and Tracking Tables
local orbitParts = {}      -- Stores the 12 physical BaseParts gathered from NDS
local orbitData = {}       -- Stores individual physics parameters (radius, height, speed, phase)
local selectedTargetName = ""
local playerList = {}
local activeProjectile = nil

-- Configuration Constants for the 12-part system
local MAX_ORBIT_PARTS = 12
local SCAN_RADIUS = 80

Rayfield:Notify({
    Title = "Part 2 Initialized",
    Content = "State variables and multi-layer data structures configured.",
    Duration = 3,
    Image = 4483362458
})

-- =================================================================
-- PART 3: NDS Debris Scanner & Multi-Layer Property Generator
-- =================================================================

local function ScanAndGatherDebris()
    orbitParts = {}
    orbitData = {}
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    
    -- Scan workspace for loose disaster parts
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and obj.Parent ~= char then
            local dist = (obj.Position - hrp.Position).Magnitude
            if dist < SCAN_RADIUS then
                table.insert(orbitParts, obj)
                
                -- Reset assembly velocities to prepare for client physics control
                pcall(function()
                    obj.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    obj.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end)
                
                -- Assign unique multi-layer orbital parameters for each part
                table.insert(orbitData, {
                    radius = math.random(8, 20),
                    height = math.random(-3, 8),
                    speed = math.random(3, 7) * (math.random(1, 2) == 1 and 1 or -1),
                    phase = math.random() * (math.pi * 2)
                })
                
                if #orbitParts >= MAX_ORBIT_PARTS then break end
            end
        end
    end
    
    if #orbitParts == 0 then
        Rayfield:Notify({
            Title = "Waiting for Disaster",
            Content = "No loose debris found nearby! Wait for a disaster to hit.",
            Duration = 4,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Debris Captured",
            Content = "Locked onto " .. tostring(#orbitParts) .. " disaster parts across multi-layers!",
            Duration = 3,
            Image = 4483362458
        })
    end
end

Rayfield:Notify({
    Title = "Part 3 Initialized",
    Content = "NDS Debris Scanner and Property Generator ready.",
    Duration = 3,
    Image = 4483362458
})

-- =================================================================
-- PART 4: Disaster Orbit Tab & Toggle Interface
-- =================================================================

OrbitTab:CreateSection("Natural Disasters Debris Orbit Controls")

OrbitTab:CreateToggle({
    Name = "Enable Disaster Debris Orbit (12 Parts)",
    CurrentValue = false,
    Flag = "NDSOrbitEnabled",
    Callback = function(v)
        isOrbiting = v
        if isOrbiting then
            ScanAndGatherDebris()
        else
            orbitParts = {}
            orbitData = {}
            Rayfield:Notify({
                Title = "Orbit Disabled",
                Content = "Released control of orbiting debris.",
                Duration = 2,
                Image = 4483362458
            })
        end
    end,
})

OrbitTab:CreateButton({
    Name = "Rescan Nearby Debris",
    Callback = function()
        if isOrbiting then
            ScanAndGatherDebris()
        else
            Rayfield:Notify({
                Title = "Notice",
                Content = "Enable orbit first before rescanning!",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

Rayfield:Notify({
    Title = "Part 4 Initialized",
    Content = "Disaster Orbit UI controls added successfully.",
    Duration = 3,
    Image = 4483362458
})

-- =================================================================
-- PART 5: Multi-Layer Orbit Simulation Render Loop
-- =================================================================

RunService.RenderStepped:Connect(function()
    if not isOrbiting or #orbitParts == 0 then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local timeVal = tick()
    
    for i, part in ipairs(orbitParts) do
        -- Skip updating normal orbit position if this specific part is currently engaged in the cinematic execution
        if not (isExecuting and part == activeProjectile) then
            if part and part.Parent then
                local data = orbitData[i]
                if data then
                    -- Calculate multi-layer circular coordinates
                    local angle = (timeVal * data.speed) + data.phase
                    local xOffset = math.cos(angle) * data.radius
                    local zOffset = math.sin(angle) * data.radius
                    local targetPos = hrp.Position + Vector3.new(xOffset, data.height, zOffset)
                    
                    -- Force client physics authority via CFrame update
                    pcall(function()
                        part.CFrame = CFrame.new(targetPos)
                        part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    end)
                end
            end
        end
    end
end)

Rayfield:Notify({
    Title = "Part 5 Initialized",
    Content = "Multi-layer orbit simulation engine active.",
    Duration = 3,
    Image = 4483362458
})

-- =================================================================
-- PART 6: Target Selection UI & Player Management
-- =================================================================

CombatTab:CreateSection("Target Elimination Engine")

local function GetPlayerNames()
    playerList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(playerList, p.Name)
        end
    end
    if #playerList == 0 then table.insert(playerList, "No Players Found") end
    return playerList
end

local targetDropdown = CombatTab:CreateDropdown({
    Name = "Select NDS Target Player",
    Options = GetPlayerNames(),
    CurrentOption = GetPlayerNames()[1],
    Flag = "NDSTargetDropdown",
    Callback = function(option)
        selectedTargetName = option
    end,
})

CombatTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        targetDropdown:Refresh(GetPlayerNames(), true)
        Rayfield:Notify({
            Title = "Refreshed",
            Content = "Player list updated successfully.",
            Duration = 2,
            Image = 4483362458
        })
    end,
})

Rayfield:Notify({
    Title = "Part 6 Initialized",
    Content = "Target selection interface ready.",
    Duration = 3,
    Image = 4483362458
})

-- =================================================================
-- PART 7: Cinematic Sequence Phase 1 & 2 - Anticipation & Projectile Rise
-- =================================================================

local function RunAnticipationAndRise()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    local hrp = char.HumanoidRootPart
    local startTime = tick()
    local animDuration = 0.5
    
    while tick() - startTime < animDuration do
        local alpha = (tick() - startTime) / animDuration
        if activeProjectile and activeProjectile.Parent then
            -- Smoothly interpolate projectile from orbit ring up to the right-hand hover point
            local targetHoverPos = hrp.Position + (hrp.CFrame.RightVector * 2) + Vector3.new(0, 3 + (alpha * 4), 0)
            pcall(function()
                activeProjectile.CFrame = CFrame.new(targetHoverPos)
                activeProjectile.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                activeProjectile.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
        end
        task.wait()
    end
    
    return true
end

Rayfield:Notify({
    Title = "Part 7 Initialized",
    Content = "Anticipation and projectile rising sequence loaded.",
    Duration = 3,
    Image = 4483362458
})

-- =================================================================
-- PART 8: Cinematic Sequence Phase 3 - One-Second Hold & Secondary Motion
-- =================================================================

local function RunDramaticHold()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local holdStart = tick()
    local holdDuration = 1.0
    
    while tick() - holdStart < holdDuration do
        if activeProjectile and activeProjectile.Parent then
            -- Apply subtle breathing/floating motion during the 1-second pause
            local hoverPos = hrp.Position + (hrp.CFrame.RightVector * 2) + Vector3.new(0, 7 + math.sin(tick() * 6) * 0.4, 0)
            pcall(function()
                activeProjectile.CFrame = CFrame.new(hoverPos)
                activeProjectile.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                activeProjectile.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
        end
        task.wait()
    end
end

Rayfield:Notify({
    Title = "Part 8 Initialized",
    Content = "Dramatic hold and secondary motion sequence loaded.",
    Duration = 3,
    Image = 4483362458
})

-- =================================================================
-- PART 9: Cinematic Sequence Phase 4 & 5 - Head Searching & Environmental Scan
-- =================================================================

local function RunHeadSearchSequence()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local searchStart = tick()
    local searchDuration = 1.5
    
    while tick() - searchStart < searchDuration do
        if activeProjectile and activeProjectile.Parent then
            -- Keep projectile hovering steady while the character performs the search scan
            pcall(function()
                activeProjectile.CFrame = hrp.CFrame + Vector3.new(0, 7, 0)
                activeProjectile.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                activeProjectile.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
        end
        task.wait()
    end
end

Rayfield:Notify({
    Title = "Part 9 Initialized",
    Content = "Head searching and environmental scan sequence loaded.",
    Duration = 3,
    Image = 4483362458
})

-- =================================================================
-- PART 10: Cinematic Sequence Phase 6 - Target Lock & Body Rotation
-- =================================================================

local function RunTargetLockAndRotate(targetPlayer)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    local hrp = char.HumanoidRootPart
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local targetHRP = targetPlayer.Character.HumanoidRootPart
    
    -- Smoothly rotate character to face the target (replicates via server physics/CFrame)
    pcall(function()
        hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetHRP.Position.X, hrp.Position.Y, targetHRP.Position.Z))
    end)
    
    -- Keep active projectile locked above the hand during rotation pause
    if activeProjectile and activeProjectile.Parent then
        pcall(function()
            activeProjectile.CFrame = hrp.CFrame + Vector3.new(0, 7, 0)
            activeProjectile.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            activeProjectile.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
    end
    
    task.wait(0.2) -- Short dramatic pause before launch
    return true
end

Rayfield:Notify({
    Title = "Part 10 Initialized",
    Content = "Target lock and body rotation sequence loaded.",
    Duration = 3,
    Image = 4483362458
})

-- =================================================================
-- PART 11: Cinematic Sequence Phase 7 - Projectile Launch & Strike Execution
-- =================================================================

local function ExecuteProjectileLaunch(targetPlayer)
    if not activeProjectile or not activeProjectile.Parent then
        Rayfield:Notify({
            Title = "Launch Error",
            Content = "Active projectile is missing or destroyed!",
            Duration = 3,
            Image = 4483362458
        })
        return
    end
    
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local targetHRP = targetPlayer.Character.HumanoidRootPart
    
    -- Calculate precise direction vector toward target and apply high-speed physics launch
    pcall(function()
        local fireDir = (targetHRP.Position - activeProjectile.Position).Unit
        activeProjectile.AssemblyLinearVelocity = fireDir * 5000
        activeProjectile.AssemblyAngularVelocity = Vector3.new(6000, 6000, 6000)
    end)
    
    Rayfield:Notify({
        Title = "Strike Delivered",
        Content = "Disaster debris hurled at " .. targetPlayer.Name .. "!",
        Duration = 3,
        Image = 4483362458
    })
end

Rayfield:Notify({
    Title = "Part 11 Initialized",
    Content = "Projectile launch and strike execution sequence loaded.",
    Duration = 3,
    Image = 4483362458
})

-- =================================================================
-- PART 12: Master Execution Button, Config Loading & Initialization
-- =================================================================

CombatTab:CreateButton({
    Name = "Execute Cinematic Disaster Strike Sequence",
    Callback = function()
        if isExecuting then return end
        
        local targetPlayer = Players:FindFirstChild(selectedTargetName)
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            Rayfield:Notify({
                Title = "Execution Error",
                Content = "Invalid target selected or character missing!",
                Duration = 3,
                Image = 4483362458
            })
            return
        end
        
        if #orbitParts == 0 then
            Rayfield:Notify({
                Title = "Execution Error",
                Content = "Enable Disaster Orbit first to gather debris parts!",
                Duration = 3,
                Image = 4483362458
            })
            return
        end
        
        isExecuting = true
        activeProjectile = orbitParts[1] -- Select the first orbiting part as the projectile
        
        task.spawn(function()
            -- Run the complete sequential cinematic animation and strike phases
            RunAnticipationAndRise()
            RunDramaticHold()
            RunHeadSearchSequence()
            
            local success = RunTargetLockAndRotate(targetPlayer)
            if success then
                ExecuteProjectileLaunch(targetPlayer)
            end
            
            isExecuting = false
        end)
    end,
})

-- Load Rayfield UI configurations and final notification
Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title = "SefScriptsHub Fully Loaded",
    Content = "All 12 parts assembled! NDS Orbit & Strike Engine is ready.",
    Duration = 5,
    Image = 4483362458
})-- Input field to target the player by name
ChatTab:CreateInput({
    Name = "Target Player Name",
    PlaceholderText = "Type exact player name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        targetName = text
    end,
})

-- Input field to specify the message content to display
ChatTab:CreateInput({
    Name = "Message Content",
    PlaceholderText = "Type fake chat message...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        chatMessage = text
    end,
})

-- Button to trigger the chat bubble over the target player's head securely
ChatTab:CreateButton({
    Name = "Send Fake Bubble",
    Callback = function()
        local target = Players:FindFirstChild(targetName)
        if target and target.Character and target.Character:FindFirstChild("Head") then
            pcall(function()
                ChatService:Chat(target.Character.Head, chatMessage, Enum.ChatColor.White)
            end)
            Rayfield:Notify({
                Title = "Success",
                Content = "Fake chat bubble sent to " .. target.Name,
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Player not found or character missing head!",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title = "SefScriptsHub Loaded",
    Content = "Fake chat bubble utility initialized successfully!",
    Duration = 5,
    Image = 4483362458
})
        Threshold = 60,
        VelocityAlerts = true,
        NameESP = true,
        HealthESP = true,
        MaxDistance = 2500,
        DebugMode = false
    },
    Tracking = {
        Sabotages = { Total = 0, Log = {} },
        Votes = {},
        Players = {}
    },
    FullyLoaded = false
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local RoleDetectionEngine = {
    Weights = {},
    InitializePlayer = function(player)
        RoleDetectionEngine.Weights[player.Name] = { Innocent = 50, Mafia = 25, Neutral = 25, Confidence = 0, Suspicion = "Low", History = {} }
    end,
    UpdateWeight = function(playerName, cat, delta, reason)
        local data = RoleDetectionEngine.Weights[playerName]
        if not data then return end
        data[cat] = math.clamp(data[cat] + delta, 0, 100)
        data.Confidence = math.floor(((math.abs(data.Mafia - 50) + math.abs(data.Innocent - 50)) / 100) * 100)
        if data.Mafia > 75 then 
            data.Suspicion = "Critical Threat"
        elseif data.Mafia > 55 then 
            data.Suspicion = "Suspicious"
        elseif data.Innocent > 70 then 
            data.Suspicion = "Trusted"
        else 
            data.Suspicion = "Neutral" 
        end
        if reason then 
            table.insert(data.History, {Time = os.date("%H:%M:%S"), Reason = reason}) 
        end
    end,
    AnalyzeChat = function(player, msg)
        local l = string.lower(msg)
        if string.find(l, "not mafia") or string.find(l, "with me") or string.find(l, "trusted") then
            RoleDetectionEngine.UpdateWeight(player.Name, "Innocent", 5, "Defensive text structure")
        elseif string.find(l, "sus") or string.find(l, "vote") or string.find(l, "who") or string.find(l, "vent") then
            RoleDetectionEngine.UpdateWeight(player.Name, "Mafia", 6, "Accusatory/redirection marker")
        end
    end,
    AnalyzeMovement = function(player, char)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end
        local last = hrp.Position
        task.spawn(function()
            while char and char.Parent do
                task.wait(1)
                if not hrp or not hrp.Parent then break end
                local dist = (hrp.Position - last).Magnitude
                if dist > 45 then
                    RoleDetectionEngine.UpdateWeight(player.Name, "Mafia", 4, "High velocity shift: " .. math.floor(dist))
                end
                last = hrp.Position
            end
        end)
    end
}

for _, p in ipairs(Players:GetPlayers()) do
    RoleDetectionEngine.InitializePlayer(p)
    if p.Character then 
        RoleDetectionEngine.AnalyzeMovement(p, p.Character) 
    end
    p.CharacterAdded:Connect(function(c) 
        RoleDetectionEngine.AnalyzeMovement(p, c) 
    end)
    p.Chatted:Connect(function(m) 
        RoleDetectionEngine.AnalyzeChat(p, m) 
    end)
end

Players.PlayerAdded:Connect(function(p)
    RoleDetectionEngine.InitializePlayer(p)
    p.CharacterAdded:Connect(function(c) 
        RoleDetectionEngine.AnalyzeMovement(p, c) 
    end)
    p.Chatted:Connect(function(m) 
        RoleDetectionEngine.AnalyzeChat(p, m) 
    end)
end)

Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
    if Lighting.Ambient == Color3.new(0, 0, 0) then
        getgenv().SefState.Tracking.Sabotages.Total = getgenv().SefState.Tracking.Sabotages.Total + 1
        table.insert(getgenv().SefState.Tracking.Sabotages.Log, {Time = os.date("%H:%M:%S"), Event = "Blackout"})
    end
end)

local ESPDrawings = {}
local TracerDrawings = {}

local function SetupVisuals(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(0, 255, 120)
    box.Thickness = 1
    box.Filled = false
    ESPDrawings[player] = box
    
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Color3.fromRGB(0, 255, 120)
    tracer.Thickness = 1
    TracerDrawings[player] = tracer
    
    RunService.RenderStepped:Connect(function()
        local cfg = getgenv().SefState.Config
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            box.Visible = false
            tracer.Visible = false
            return
        end
        local hrp = player.Character.HumanoidRootPart
        local vec, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            if cfg.ESPEnabled then
                box.Size = Vector2.new(2000 / vec.Z, 3000 / vec.Z)
                box.Position = Vector2.new(vec.X - box.Size.X / 2, vec.Y - box.Size.Y / 2)
                local w = RoleDetectionEngine.Weights[player.Name]
                if w and w.Mafia > cfg.Threshold then
                    box.Color = Color3.fromRGB(255, 50, 50)
                else
                    box.Color = Color3.fromRGB(50, 255, 50)
                end
                box.Visible = true
            else
                box.Visible = false
            end
            if cfg.TracersEnabled then
                tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                tracer.To = Vector2.new(vec.X, vec.Y)
                local w = RoleDetectionEngine.Weights[player.Name]
                if w and w.Mafia > cfg.Threshold then
                    tracer.Color = Color3.fromRGB(255, 50, 50)
                else
                    tracer.Color = Color3.fromRGB(50, 255, 50)
                end
                tracer.Visible = true
            else
                tracer.Visible = false
            end
        else
            box.Visible = false
            tracer.Visible = false
        end
    end)
    
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            pcall(function() box:Remove() end)
            pcall(function() tracer:Remove() end)
            ESPDrawings[player] = nil
            TracerDrawings[player] = nil
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do 
    SetupVisuals(p) 
end

Players.PlayerAdded:Connect(function(p) 
    SetupVisuals(p) 
end)

local RolesTab = getgenv().SefTabs.Roles
local ActivitiesTab = getgenv().SefTabs.Activities
local ESPTab = getgenv().SefTabs.ESP
local MovementTab = getgenv().SefTabs.Movement
local VotingTab = getgenv().SefTabs.Voting
local SettingsTab = getgenv().SefTabs.Settings

RolesTab:CreateSection("Live Player Suspect Matrix")
local PlayerParagraphs = {}

local function UpdatePlayerMatrices()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local w = RoleDetectionEngine.Weights[player.Name] or {Mafia = 25, Innocent = 50}
            local infoText = string.format("Target: %s | Mafia Prob: %s%% | Innocent Prob: %s%%", player.Name, tostring(w.Mafia), tostring(w.Innocent))
            if PlayerParagraphs[player.Name] then
                PlayerParagraphs[player.Name]:Set(infoText)
            else
                PlayerParagraphs[player.Name] = RolesTab:CreateParagraph({Title = player.Name, Content = infoText})
            end
        end
    end
end

ActivitiesTab:CreateSection("Event History Log")
local LogParagraph = ActivitiesTab:CreateParagraph({Title = "Recent Sabotages & Alarms", Content = "Total Blackouts Recorded: 0"})

ESPTab:CreateSection("Visual Parameters")
ESPTab:CreateToggle({
    Name = "Enable ESP Boxes",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(v) getgenv().SefState.Config.ESPEnabled = v end,
})

ESPTab:CreateToggle({
    Name = "Enable Snaplines",
    CurrentValue = false,
    Flag = "TracersEnabled",
    Callback = function(v) getgenv().SefState.Config.TracersEnabled = v end,
})

ESPTab:CreateSlider({
    Name = "Threat Threshold",
    Range = {20, 90},
    Increment = 5,
    CurrentValue = 60,
    Flag = "Threshold",
    Callback = function(v) getgenv().SefState.Config.Threshold = v end,
})

MovementTab:CreateSection("Telemetry")
local MovementInfo = MovementTab:CreateParagraph({Title = "Local Telemetry Monitor", Content = "Current Speed: 16 studs/s"})
MovementTab:CreateToggle({
    Name = "High-Velocity Warning Alerts",
    CurrentValue = true,
    Flag = "VelocityAlerts",
    Callback = function(v) getgenv().SefState.Config.VelocityAlerts = v end,
})

VotingTab:CreateSection("Voting Analytics")
VotingTab:CreateParagraph({Title = "Vote Stream Monitor", Content = "Tracking ballot distributions."})
VotingTab:CreateButton({
    Name = "Simulate Vote Scan",
    Callback = function() UpdatePlayerMatrices() end,
})

SettingsTab:CreateSection("Configuration")
SettingsTab:CreateToggle({
    Name = "Debug Mode",
    CurrentValue = false,
    Flag = "DebugMode",
    Callback = function(v) getgenv().SefState.Config.DebugMode = v end,
})
SettingsTab:CreateButton({
    Name = "Save Configuration",
    Callback = function() pcall(function() Rayfield:SaveConfiguration() end) end,
})
SettingsTab:CreateButton({
    Name = "Unload Hub",
    Callback = function()
        for _, d in pairs(ESPDrawings) do pcall(function() d:Remove() end) end
        for _, t in pairs(TracerDrawings) do pcall(function() t:Remove() end) end
        Rayfield:Destroy()
    end,
})

Rayfield:LoadConfiguration()

task.spawn(function()
    while true do
        task.wait(3)
        pcall(function()
            local totalSabo = getgenv().SefState.Tracking.Sabotages.Total
            LogParagraph:Set(string.format("Total Blackouts Recorded: %d\nLast Checked: %s", totalSabo, os.date("%H:%M:%S")))
            UpdatePlayerMatrices()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                local speed = math.floor(char.HumanoidRootPart.Velocity.Magnitude)
                local state = char.Humanoid:GetState().Name
                MovementInfo:Set(string.format("Current Speed: %d studs/s | State: %s", speed, state))
            end
        end)
    end
end)

getgenv().SefState.FullyLoaded = true

Rayfield:Notify({
    Title = "SefScriptsHub Loaded",
    Content = "All systems and detection modules initialized successfully!",
    Duration = 5,
    Image = 4483362458
})
        ESPEnabled = false,
        TracersEnabled = false,
        Threshold = 60,
        VelocityAlerts = true,
        NameESP = true,
        HealthESP = true,
        MaxDistance = 2500,
        DebugMode = false
    },
    Tracking = {
        Sabotages = { Total = 0, Log = {} },
        Votes = {},
        Players = {}
    },
    FullyLoaded = false
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local RoleDetectionEngine = {
    Weights = {},
    InitializePlayer = function(player)
        RoleDetectionEngine.Weights[player.Name] = { Innocent = 50, Mafia = 25, Neutral = 25, Confidence = 0, Suspicion = "Low", History = {} }
    end,
    UpdateWeight = function(playerName, cat, delta, reason)
        local data = RoleDetectionEngine.Weights[playerName]
        if not data then return end
        data[cat] = math.clamp(data[cat] + delta, 0, 100)
        data.Confidence = math.floor(((math.abs(data.Mafia - 50) + math.abs(data.Innocent - 50)) / 100) * 100)
        if data.Mafia > 75 then 
            data.Suspicion = "Critical Threat"
        elseif data.Mafia > 55 then 
            data.Suspicion = "Suspicious"
        elseif data.Innocent > 70 then 
            data.Suspicion = "Trusted"
        else 
            data.Suspicion = "Neutral" 
        end
        if reason then 
            table.insert(data.History, {Time = os.date("%H:%M:%S"), Reason = reason}) 
        end
    end,
    AnalyzeChat = function(player, msg)
        local l = string.lower(msg)
        if string.find(l, "not mafia") or string.find(l, "with me") or string.find(l, "trusted") then
            RoleDetectionEngine.UpdateWeight(player.Name, "Innocent", 5, "Defensive text structure")
        elseif string.find(l, "sus") or string.find(l, "vote") or string.find(l, "who") or string.find(l, "vent") then
            RoleDetectionEngine.UpdateWeight(player.Name, "Mafia", 6, "Accusatory/redirection marker")
        end
    end,
    AnalyzeMovement = function(player, char)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end
        local last = hrp.Position
        task.spawn(function()
            while char and char.Parent do
                task.wait(1)
                if not hrp or not hrp.Parent then break end
                local dist = (hrp.Position - last).Magnitude
                if dist > 45 then
                    RoleDetectionEngine.UpdateWeight(player.Name, "Mafia", 4, "High velocity shift: " .. math.floor(dist))
                end
                last = hrp.Position
            end
        end)
    end
}

for _, p in ipairs(Players:GetPlayers()) do
    RoleDetectionEngine.InitializePlayer(p)
    if p.Character then 
        RoleDetectionEngine.AnalyzeMovement(p, p.Character) 
    end
    p.CharacterAdded:Connect(function(c) 
        RoleDetectionEngine.AnalyzeMovement(p, c) 
    end)
    p.Chatted:Connect(function(m) 
        RoleDetectionEngine.AnalyzeChat(p, m) 
    end)
end

Players.PlayerAdded:Connect(function(p)
    RoleDetectionEngine.InitializePlayer(p)
    p.CharacterAdded:Connect(function(c) 
        RoleDetectionEngine.AnalyzeMovement(p, c) 
    end)
    p.Chatted:Connect(function(m) 
        RoleDetectionEngine.AnalyzeChat(p, m) 
    end)
end)

Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
    if Lighting.Ambient == Color3.new(0, 0, 0) then
        getgenv().SefState.Tracking.Sabotages.Total = getgenv().SefState.Tracking.Sabotages.Total + 1
        table.insert(getgenv().SefState.Tracking.Sabotages.Log, {Time = os.date("%H:%M:%S"), Event = "Blackout"})
    end
end)

local ESPDrawings = {}
local TracerDrawings = {}

local function SetupVisuals(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(0, 255, 120)
    box.Thickness = 1
    box.Filled = false
    ESPDrawings[player] = box
    
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Color3.fromRGB(0, 255, 120)
    tracer.Thickness = 1
    TracerDrawings[player] = tracer
    
    RunService.RenderStepped:Connect(function()
        local cfg = getgenv().SefState.Config
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            box.Visible = false
            tracer.Visible = false
            return
        end
        local hrp = player.Character.HumanoidRootPart
        local vec, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            if cfg.ESPEnabled then
                box.Size = Vector2.new(2000 / vec.Z, 3000 / vec.Z)
                box.Position = Vector2.new(vec.X - box.Size.X / 2, vec.Y - box.Size.Y / 2)
                local w = RoleDetectionEngine.Weights[player.Name]
                if w and w.Mafia > cfg.Threshold then
                    box.Color = Color3.fromRGB(255, 50, 50)
                else
                    box.Color = Color3.fromRGB(50, 255, 50)
                end
                box.Visible = true
            else
                box.Visible = false
            end
            if cfg.TracersEnabled then
                tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                tracer.To = Vector2.new(vec.X, vec.Y)
                local w = RoleDetectionEngine.Weights[player.Name]
                if w and w.Mafia > cfg.Threshold then
                    tracer.Color = Color3.fromRGB(255, 50, 50)
                else
                    tracer.Color = Color3.fromRGB(50, 255, 50)
                end
                tracer.Visible = true
            else
                tracer.Visible = false
            end
        else
            box.Visible = false
            tracer.Visible = false
        end
    end)
    
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            pcall(function() box:Remove() end)
            pcall(function() tracer:Remove() end)
            ESPDrawings[player] = nil
            TracerDrawings[player] = nil
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do 
    SetupVisuals(p) 
end

Players.PlayerAdded:Connect(function(p) 
    SetupVisuals(p) 
end)

local RolesTab = getgenv().SefTabs.Roles
local ActivitiesTab = getgenv().SefTabs.Activities
local ESPTab = getgenv().SefTabs.ESP
local MovementTab = getgenv().SefTabs.Movement
local VotingTab = getgenv().SefTabs.Voting
local SettingsTab = getgenv().SefTabs.Settings

RolesTab:CreateSection("Live Player Suspect Matrix")
local PlayerParagraphs = {}

local function UpdatePlayerMatrices()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local w = RoleDetectionEngine.Weights[player.Name] or {Mafia = 25, Innocent = 50}
            local infoText = string.format("Target: %s | Mafia Prob: %s%% | Innocent Prob: %s%%", player.Name, tostring(w.Mafia), tostring(w.Innocent))
            if PlayerParagraphs[player.Name] then
                PlayerParagraphs[player.Name]:Set(infoText)
            else
                PlayerParagraphs[player.Name] = RolesTab:CreateParagraph({Title = player.Name, Content = infoText})
            end
        end
    end
end

ActivitiesTab:CreateSection("Event History Log")
local LogParagraph = ActivitiesTab:CreateParagraph({Title = "Recent Sabotages & Alarms", Content = "Total Blackouts Recorded: 0"})

ESPTab:CreateSection("Visual Parameters")
ESPTab:CreateToggle({
    Name = "Enable ESP Boxes",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(v) getgenv().SefState.Config.ESPEnabled = v end,
})

ESPTab:CreateToggle({
    Name = "Enable Snaplines",
    CurrentValue = false,
    Flag = "TracersEnabled",
    Callback = function(v) getgenv().SefState.Config.TracersEnabled = v end,
})

ESPTab:CreateSlider({
    Name = "Threat Threshold",
    Range = {20, 90},
    Increment = 5,
    CurrentValue = 60,
    Flag = "Threshold",
    Callback = function(v) getgenv().SefState.Config.Threshold = v end,
})

MovementTab:CreateSection("Telemetry")
local MovementInfo = MovementTab:CreateParagraph({Title = "Local Telemetry Monitor", Content = "Current Speed: 16 studs/s"})
MovementTab:CreateToggle({
    Name = "High-Velocity Warning Alerts",
    CurrentValue = true,
    Flag = "VelocityAlerts",
    Callback = function(v) getgenv().SefState.Config.VelocityAlerts = v end,
})

VotingTab:CreateSection("Voting Analytics")
VotingTab:CreateParagraph({Title = "Vote Stream Monitor", Content = "Tracking ballot distributions."})
VotingTab:CreateButton({
    Name = "Simulate Vote Scan",
    Callback = function() UpdatePlayerMatrices() end,
})

SettingsTab:CreateSection("Configuration")
SettingsTab:CreateToggle({
    Name = "Debug Mode",
    CurrentValue = false,
    Flag = "DebugMode",
    Callback = function(v) getgenv().SefState.Config.DebugMode = v end,
})
SettingsTab:CreateButton({
    Name = "Save Configuration",
    Callback = function() pcall(function() Rayfield:SaveConfiguration() end) end,
})
SettingsTab:CreateButton({
    Name = "Unload Hub",
    Callback = function()
        for _, d in pairs(ESPDrawings) do pcall(function() d:Remove() end) end
        for _, t in pairs(TracerDrawings) do pcall(function() t:Remove() end) end
        Rayfield:Destroy()
    end,
})

Rayfield:LoadConfiguration()

task.spawn(function()
    while true do
        task.wait(3)
        pcall(function()
            local totalSabo = getgenv().SefState.Tracking.Sabotages.Total
            LogParagraph:Set(string.format("Total Blackouts Recorded: %d\nLast Checked: %s", totalSabo, os.date("%H:%M:%S")))
            UpdatePlayerMatrices()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                local speed = math.floor(char.HumanoidRootPart.Velocity.Magnitude)
                local state = char.Humanoid:GetState().Name
                MovementInfo:Set(string.format("Current Speed: %d studs/s | State: %s", speed, state))
            end
        end)
    end
end)

getgenv().SefState.FullyLoaded = true

Rayfield:Notify({
    Title = "SefScriptsHub Loaded",
    Content = "All systems and detection modules initialized successfully!",
    Duration = 5,
    Image = 4483362458
})
