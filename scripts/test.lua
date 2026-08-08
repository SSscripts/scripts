-- Loading RayField
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
end)


-- Window
local Window = Rayfield:CreateWindow({
   Name = "SefScript Hub",
   Icon = nil,
   LoadingTitle = "SefScript Hub | TimeBomb Duels",
   LoadingSubtitle = "by SefScript",
   ShowText = "SefScript Hub",
   Theme = "Default",

   ToggleUIKeybind = "K",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = "SefScript",
      FileName = "SefScript Hub"
   },

   Discord = {
      Enabled = true,
      Invite = "WFxU9nfs3E",
      RememberJoins = true
   },

   KeySystem = true,
   KeySettings = {
      Title = "Sef Script's Key System",
      Subtitle = "Easy Key System",
      Note = "Key is SUBSCRIBE. Join our discord server to see more scripts from us!",
      FileName = "SefScriptKey",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"SUBSCRIBE"}
   }
})

-- Tab Creation
local HomeTab = Window:CreateTab("Home", nil)
local MiscTab = Window:CreateTab("Misc", nil)
local SettingsTab = Window:CreateTab("Settings", nil)
local ExperimentalTab = Window:CreateTab("Experimental")

-- Section Creation
local HomeSection = HomeTab:CreateSection("Time Bomb Duels")
local MiscSection = MiscTab:CreateSection("Misc")
local ExperimentalSection = ExperimentalTab:CreateSection("Not Recommended to Use.")

-- Keep character references updated on respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
end)

-- | HOME |

-- AI Configuration and Neural Engine State
local AIConfig = {
    AutoPlayEnabled = false,
    WallhopEnabled = false,
    Provider = "CustomNeural",
    APIKey = "",
    Endpoint = "",
    Model = "",
    ReactionDelay = 0.14,
    SmoothingFactor = 0.25,
    JitterIntensity = 1.5,
    PredictionLead = 0.2,
    SafeDistance = 22,
    ChaseSpeed = 16,
    EvadeSpeed = 20,
    TargetNearestOnly = true,
    AutoEquipBomb = true
}

local CustomNeuralNetwork = {
    Weights = {0.45, -0.32, 0.88, 0.12},
    Bias = 0.05
}

function CustomNeuralNetwork:Evaluate(distance, hasBomb, enemySpeed, healthPercent)
    local rawActivation = (distance * self.Weights[1]) + 
                          ((hasBomb and 1 or 0) * self.Weights[2]) + 
                          (enemySpeed * self.Weights[3]) + 
                          (healthPercent * self.Weights[4]) + self.Bias
    return 1 / (1 + math.exp(-rawActivation))
end

local AIAPIBridge = {
    Provider = "CustomNeural",
    APIKey = "",
    Endpoint = "",
    Model = ""
}

function AIAPIBridge:Configure(provider, apiKey, endpoint, model)
    self.Provider = provider
    self.APIKey = apiKey or ""
    self.Endpoint = endpoint or ""
    self.Model = model or ""
    AIConfig.Provider = provider
    AIConfig.APIKey = apiKey or ""
    AIConfig.Endpoint = endpoint or ""
    AIConfig.Model = model or ""
end

function AIAPIBridge:QueryTacticalDecision(gameStateData)
    if self.Provider == "CustomNeural" then
        local score = CustomNeuralNetwork:Evaluate(
            gameStateData.Distance, 
            gameStateData.HasBomb, 
            gameStateData.EnemySpeed, 
            gameStateData.HealthPercent
        )
        return {
            Action = score > 0.5 and "AGGRESSIVE_CHASE" or "DEFENSIVE_EVADE",
            Confidence = score,
            OffsetVector = Vector3.new(math.sin(score * 10), 0, math.cos(score * 10)) * 5
        }
    end

    local headers = {["Content-Type"] = "application/json"}
    local requestBody = {}
    local url = self.Endpoint

    if self.Provider == "Gemini" then
        url = "https://generativelanguage.googleapis.com/v1beta/models/" .. self.Model .. ":generateContent?key=" .. self.APIKey
        requestBody = {
            contents = {{parts = {{text = HttpService:JSONEncode(gameStateData)}}}}
        }
    elseif self.Provider == "OpenAI" or self.Provider == "OpenRouter" then
        headers["Authorization"] = "Bearer " .. self.APIKey
        requestBody = {
            model = self.Model,
            messages = {{role = "user", content = HttpService:JSONEncode(gameStateData)}}
        }
    elseif self.Provider == "Ollama" then
        url = self.Endpoint ~= "" and self.Endpoint or "http://localhost:11434/api/generate"
        requestBody = {
            model = self.Model,
            prompt = HttpService:JSONEncode(gameStateData),
            stream = false
        }
    end

    local success, response = pcall(function()
        return HttpService:PostAsync(url, HttpService:JSONEncode(requestBody), Enum.HttpContentType.ApplicationJson, false, headers)
    end)

    if success and response then
        local decoded = HttpService:JSONDecode(response)
        return { Action = "DYNAMIC_AI_MOVE", Data = decoded }
    else
        return self:QueryTacticalDecision({Provider = "CustomNeural", Distance = gameStateData.Distance, HasBomb = gameStateData.HasBomb, EnemySpeed = 0, HealthPercent = 1})
    end
end

-- Helper Functions for AI
local function getNearestEnemy()
    local nearestEnemy = nil
    local shortestDistance = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local enemyChar = player.Character
            local enemyHRP = enemyChar:FindFirstChild("HumanoidRootPart")
            local enemyHumanoid = enemyChar:FindFirstChild("Humanoid")
            
            if enemyHRP and enemyHumanoid and enemyHumanoid.Health > 0 then
                local dist = (HumanoidRootPart.Position - enemyHRP.Position).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    nearestEnemy = enemyChar
                end
            end
        end
    end
    return nearestEnemy, shortestDistance
end

local function hasBombTool()
    if not Character then return false end
    local tool = Character:FindFirstChildOfClass("Tool")
    if tool then
        local nameLower = tool.Name:lower()
        if string.find(nameLower, "bomb") or string.find(nameLower, "time") then
            return true
        end
    end
    
    if AIConfig.AutoEquipBomb then
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") then
                    local nameLower = item.Name:lower()
                    if string.find(nameLower, "bomb") or string.find(nameLower, "time") then
                        Humanoid:EquipTool(item)
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Auto Play Core Loop
local autoPlayConn
local function toggleAutoPlay(state)
    AIConfig.AutoPlayEnabled = state
    if state then
        autoPlayConn = RunService.Heartbeat:Connect(function()
            if not AIConfig.AutoPlayEnabled or not Character or not HumanoidRootPart or not Humanoid then return end
            
            local enemy, distance = getNearestEnemy()
            if not enemy then return end
            local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
            if not enemyHRP then return end
            
            local hasBombState = hasBombTool()
            local gameState = {
                Distance = distance,
                HasBomb = hasBombState,
                EnemySpeed = enemyHRP.AssemblyLinearVelocity.Magnitude,
                HealthPercent = Humanoid.Health / Humanoid.MaxHealth
            }
            
            local decision = AIAPIBridge:QueryTacticalDecision(gameState)
            
            if hasBombState then
                Humanoid:MoveTo(enemyHRP.Position + (enemyHRP.AssemblyLinearVelocity * AIConfig.PredictionLead))
            else
                local escapeVector = (HumanoidRootPart.Position - enemyHRP.Position).Unit
                local evadePosition = HumanoidRootPart.Position + (escapeVector * AIConfig.SafeDistance) + Vector3.new(math.sin(tick() * 5) * AIConfig.JitterIntensity * 4, 0, math.cos(tick() * 5) * AIConfig.JitterIntensity * 4)
                Humanoid:MoveTo(evadePosition)
            end
        end)
    else
        if autoPlayConn then autoPlayConn:Disconnect() end
        if Humanoid and HumanoidRootPart then
            Humanoid:MoveTo(HumanoidRootPart.Position)
        end
    end
end

-- Wallhop Engine
local wallhopConn
local wallhopCooldown = false
local wallhopDetectionRange = 4.0
local wallhopClimbPower = Vector3.new(0, 42, 0)

local function triggerAdvancedWallhopAnimation(char)
    local h = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not h or not hrp then return end

    local animInfo = TweenInfo.new(0.15, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, true, 0)
    local joints = {}

    if h.RigType == Enum.HumanoidRigType.R15 then
        local lower = char:FindFirstChild("LowerTorso")
        local upper = char:FindFirstChild("UpperTorso")
        if lower and upper then
            joints = {
                Root = lower:FindFirstChild("Root"),
                Waist = upper:FindFirstChild("Waist"),
                RightHip = char:FindFirstChild("RightUpperLeg") and char.RightUpperLeg:FindFirstChild("RightHip"),
                LeftHip = char:FindFirstChild("LeftUpperLeg") and char.LeftUpperLeg:FindFirstChild("LeftHip"),
                RightArm = char:FindFirstChild("RightUpperArm") and char.RightUpperArm:FindFirstChild("RightShoulder"),
                LeftArm = char:FindFirstChild("LeftUpperArm") and char.LeftUpperArm:FindFirstChild("LeftShoulder")
            }
        end
    else
        local torso = char:FindFirstChild("Torso")
        if torso then
            joints = {
                Root = hrp:FindFirstChild("RootJoint"),
                RightHip = torso:FindFirstChild("Right Hip"),
                LeftHip = torso:FindFirstChild("Left Hip"),
                RightArm = torso:FindFirstChild("Right Shoulder"),
                LeftArm = torso:FindFirstChild("Left Shoulder")
            }
        end
    end

    local poses = {
        Root = CFrame.Angles(math.rad(-20), math.rad(10), 0),
        Waist = CFrame.Angles(math.rad(-15), 0, 0),
        RightHip = CFrame.Angles(math.rad(65), 0, math.rad(-10)),
        LeftHip = CFrame.Angles(math.rad(-30), 0, 0),
        RightArm = CFrame.Angles(math.rad(45), math.rad(-20), 0),
        LeftArm = CFrame.Angles(math.rad(-50), math.rad(20), 0)
    }

    for name, joint in pairs(joints) do
        if joint and poses[name] then
            local targetC0 = joint.C0 * poses[name]
            TweenService:Create(joint, animInfo, {C0 = targetC0}):Play()
        end
    end
end

local function toggleWallhop(state)
    AIConfig.WallhopEnabled = state
    if state then
        wallhopConn = RunService.Heartbeat:Connect(function()
            if wallhopCooldown or not Character or not HumanoidRootPart or not Humanoid then return end
            if Humanoid.FloorMaterial ~= Enum.Material.Air then return end
            if Humanoid.MoveDirection.Magnitude < 0.1 then return end

            local hrp = HumanoidRootPart
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {Character}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            local moveDir = Humanoid.MoveDirection
            local rightVector = CFrame.lookAt(Vector3.zero, moveDir).RightVector
            local spread = 1.4
            
            local origins = {
                Center = hrp.Position,
                Left = hrp.Position - (rightVector * spread),
                Right = hrp.Position + (rightVector * spread)
            }

            local legOffset = (Humanoid.RigType == Enum.HumanoidRigType.R15) and 2 or 2.5
            local validWallFound = false
            local detectedNormal = nil

            for _, origin in pairs(origins) do
                local angledDir = (moveDir + (rightVector * 0.3)).Unit
                local torsoRay = Workspace:Raycast(origin, angledDir * wallhopDetectionRange, rayParams)
                local legRay = Workspace:Raycast(origin - Vector3.new(0, legOffset, 0), angledDir * wallhopDetectionRange, rayParams)

                if torsoRay and torsoRay.Instance and torsoRay.Instance.CanCollide then
                    local legHitInstance = legRay and legRay.Instance or nil
                    if torsoRay.Instance ~= legHitInstance then
                        validWallFound = true
                        detectedNormal = torsoRay.Normal
                        break
                    end
                end
            end

            if validWallFound and detectedNormal then
                wallhopCooldown = true
                local tangent = (moveDir - (detectedNormal * moveDir:Dot(detectedNormal))).Unit
                hrp.AssemblyLinearVelocity = wallhopClimbPower + (tangent * 18) + (detectedNormal * 5)
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                triggerAdvancedWallhopAnimation(Character)
                
                task.delay(0.35, function()
                    wallhopCooldown = false
                end)
            end
        end)
    else
        if wallhopConn then wallhopConn:Disconnect() end
        wallhopCooldown = false
    end
end

-- Home Tab GUI Controls (20+ AI Customizations)
HomeSection:CreateToggle({
    Name = "Auto Play (Timebomb AI)",
    CurrentValue = false,
    Flag = "AutoPlayToggle",
    Callback = function(Value)
        toggleAutoPlay(Value)
    end,
})

HomeSection:CreateToggle({
    Name = "Advanced Wallhop Engine",
    CurrentValue = false,
    Flag = "WallhopToggle",
    Callback = function(Value)
        toggleWallhop(Value)
    end,
})

HomeSection:CreateDropdown({
    Name = "AI Provider",
    Values = {"CustomNeural", "Gemini", "OpenAI", "OpenRouter", "Ollama"},
    CurrentValue = "CustomNeural",
    Flag = "AIProviderDropdown",
    Callback = function(Value)
        AIAPIBridge:Configure(Value, AIConfig.APIKey, AIConfig.Endpoint, AIConfig.Model)
    end,
})

HomeSection:CreateTextbox({
    Name = "AI API Key",
    PlaceholderText = "Enter API Key...",
    Flag = "APIKeyBox",
    Callback = function(Text)
        AIAPIBridge:Configure(AIConfig.Provider, Text, AIConfig.Endpoint, AIConfig.Model)
    end,
})

HomeSection:CreateTextbox({
    Name = "API Endpoint URL",
    PlaceholderText = "https://...",
    Flag = "EndpointBox",
    Callback = function(Text)
        AIAPIBridge:Configure(AIConfig.Provider, AIConfig.APIKey, Text, AIConfig.Model)
    end,
})

HomeSection:CreateTextbox({
    Name = "AI Model Name",
    PlaceholderText = "e.g., gemini-2.5-flash",
    Flag = "ModelBox",
    Callback = function(Text)
        AIAPIBridge:Configure(AIConfig.Provider, AIConfig.APIKey, AIConfig.Endpoint, Text)
    end,
})

HomeSection:CreateSlider({
    Name = "AI Reaction Delay",
    Range = {0.05, 0.5},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.14,
    Flag = "ReactionDelaySlider",
    Callback = function(Value)
        AIConfig.ReactionDelay = Value
    end,
})

HomeSection:CreateSlider({
    Name = "Path Smoothing Factor",
    Range = {0.05, 1.0},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.25,
    Flag = "SmoothingSlider",
    Callback = function(Value)
        AIConfig.SmoothingFactor = Value
    end,
})

HomeSection:CreateSlider({
    Name = "Evasion Jitter Intensity",
    Range = {0.0, 5.0},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 1.5,
    Flag = "JitterSlider",
    Callback = function(Value)
        AIConfig.JitterIntensity = Value
    end,
})

HomeSection:CreateSlider({
    Name = "Prediction Lead Time",
    Range = {0.0, 1.0},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.2,
    Flag = "PredictionSlider",
    Callback = function(Value)
        AIConfig.PredictionLead = Value
    end,
})

HomeSection:CreateSlider({
    Name = "Safe Evade Distance",
    Range = {10, 50},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 22,
    Flag = "SafeDistSlider",
    Callback = function(Value)
        AIConfig.SafeDistance = Value
    end,
})

HomeSection:CreateSlider({
    Name = "Chase Speed Multiplier",
    Range = {16, 100},
    Increment = 2,
    Suffix = "",
    CurrentValue = 16,
    Flag = "ChaseSpeedSlider",
    Callback = function(Value)
        AIConfig.ChaseSpeed = Value
    end,
})

HomeSection:CreateSlider({
    Name = "Evade Speed Multiplier",
    Range = {16, 100},
    Increment = 2,
    Suffix = "",
    CurrentValue = 20,
    Flag = "EvadeSpeedSlider",
    Callback = function(Value)
        AIConfig.EvadeSpeed = Value
    end,
})

HomeSection:CreateSlider({
    Name = "Neural Weight 1 (Distance)",
    Range = {-1.0, 1.0},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.45,
    Flag = "Weight1Slider",
    Callback = function(Value)
        CustomNeuralNetwork.Weights[1] = Value
    end,
})

HomeSection:CreateSlider({
    Name = "Neural Weight 2 (Bomb)",
    Range = {-1.0, 1.0},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = -0.32,
    Flag = "Weight2Slider",
    Callback = function(Value)
        CustomNeuralNetwork.Weights[2] = Value
    end,
})

HomeSection:CreateSlider({
    Name = "Neural Weight 3 (Enemy Speed)",
    Range = {-1.0, 1.0},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.88,
    Flag = "Weight3Slider",
    Callback = function(Value)
        CustomNeuralNetwork.Weights[3] = Value
    end,
})

HomeSection:CreateSlider({
    Name = "Neural Weight 4 (Health)",
    Range = {-1.0, 1.0},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.12,
    Flag = "Weight4Slider",
    Callback = function(Value)
        CustomNeuralNetwork.Weights[4] = Value
    end,
})

HomeSection:CreateSlider({
    Name = "Neural Bias Offset",
    Range = {-1.0, 1.0},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.05,
    Flag = "BiasSlider",
    Callback = function(Value)
        CustomNeuralNetwork.Bias = Value
    end,
})

HomeSection:CreateToggle({
    Name = "Target Nearest Enemy Only",
    CurrentValue = true,
    Flag = "TargetNearestToggle",
    Callback = function(Value)
        AIConfig.TargetNearestOnly = Value
    end,
})

HomeSection:CreateToggle({
    Name = "Auto-Equip Bomb Tool",
    CurrentValue = true,
    Flag = "AutoEquipToggle",
    Callback = function(Value)
        AIConfig.AutoEquipBomb = Value
    end,
})

HomeSection:CreateButton({
    Name = "Reset AI Configuration",
    Callback = function()
        AIConfig.ReactionDelay = 0.14
        AIConfig.SmoothingFactor = 0.25
        AIConfig.JitterIntensity = 1.5
        AIConfig.PredictionLead = 0.2
        AIConfig.SafeDistance = 22
        CustomNeuralNetwork.Weights = {0.45, -0.32, 0.88, 0.12}
        CustomNeuralNetwork.Bias = 0.05
    end,
})


-- | MISC TAB |

-- Misc Defaults
local DEFAULTS = {
    Fly = false,
    FlySpeed = 50,
    Noclip = false,
    GodMode = false,
    WalkSpeed = 16,
    InfJump = false,
    JumpHeight = 7.2,
    Gravity = 196.2
}

local flying = DEFAULTS.Fly
local flySpeed = DEFAULTS.FlySpeed
local noclip = DEFAULTS.Noclip
local godmode = DEFAULTS.GodMode
local infJump = DEFAULTS.InfJump
local bodyVel, bodyGyro

-- God Mode Loop
RunService.RenderStepped:Connect(function()
    if godmode and Humanoid then
        Humanoid.Health = Humanoid.MaxHealth
    end
end)

-- Infinite Jump Listener
UserInputService.JumpRequest:Connect(function()
    if infJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Fly Function
local flyConn

local function startFly()
    if not HumanoidRootPart or not Humanoid then return end
    
    Humanoid.PlatformStand = true

    bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyVel.Velocity = Vector3.zero
    bodyVel.Parent = HumanoidRootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro.P = 9e4
    bodyGyro.CFrame = HumanoidRootPart.CFrame
    bodyGyro.Parent = HumanoidRootPart

    flyConn = RunService.RenderStepped:Connect(function()
        if not flying or not HumanoidRootPart then return end
        
        local cam = Workspace.CurrentCamera
        local moveDir = Vector3.zero

        local rawMove = Humanoid.MoveDirection
        if rawMove.Magnitude > 0 then
            local camCF = cam.CFrame
            local flatCamLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
            local flatCamRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit

            local forwardAmount = rawMove:Dot(flatCamLook)
            local rightAmount = rawMove:Dot(flatCamRight)

            moveDir = (camCF.LookVector * forwardAmount) + (camCF.RightVector * rightAmount)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or Humanoid.Jump then 
            moveDir = moveDir + Vector3.new(0, 1, 0) 
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then 
            moveDir = moveDir - Vector3.new(0, 1, 0) 
        end

        bodyVel.Velocity = moveDir * flySpeed
        bodyGyro.CFrame = cam.CFrame
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect() end
    if bodyVel then bodyVel:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    if Humanoid then Humanoid.PlatformStand = false end
end

-- MISC INTERACTION
local ToggleFly, ToggleNoclip, ToggleGod, SliderSpeed, ToggleInfJump, SliderJump, SliderGravity

ToggleFly = MiscTab:CreateToggle({
    Name = "Fly",
    CurrentValue = DEFAULTS.Fly,
    Flag = "FlyToggle",
    Callback = function(Value)
        flying = Value
        if flying then
            startFly()
        else
            stopFly()
        end
    end,
})

local SliderFlySpeed = MiscTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 500},
    Increment = 5,
    Suffix = "Speed",
    CurrentValue = DEFAULTS.FlySpeed or 50,
    Flag = "FlySpeedSlider",
    Callback = function(Value)
        flySpeed = Value
    end,
})

MiscTab:CreateButton({
    Name = "Reset Fly Speed",
    Callback = function()
        SliderFlySpeed:Set(DEFAULTS.FlySpeed or 50)
    end,
})

ToggleGod = MiscTab:CreateToggle({
    Name = "God Mode",
    CurrentValue = DEFAULTS.GodMode,
    Flag = "GodModeToggle",
    Callback = function(Value)
        godmode = Value
    end,
})

SliderSpeed = MiscTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = DEFAULTS.WalkSpeed,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        if Humanoid then
            Humanoid.WalkSpeed = Value
        end
    end,
})

MiscTab:CreateButton({
    Name = "Reset WalkSpeed",
    Callback = function()
        SliderSpeed:Set(DEFAULTS.WalkSpeed)
    end,
})

ToggleInfJump = MiscTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = DEFAULTS.InfJump,
    Flag = "InfJumpToggle",
    Callback = function(Value)
        infJump = Value
    end,
})

SliderJump = MiscTab:CreateSlider({
    Name = "JumpHeight",
    Range = {7.2, 300},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = DEFAULTS.JumpHeight,
    Flag = "JumpHeightSlider",
    Callback = function(Value)
        if Humanoid then
            Humanoid.UseJumpPower = false
            Humanoid.JumpHeight = Value
        end
    end,
})

MiscTab:CreateButton({
    Name = "Reset JumpHeight",
    Callback = function()
        SliderJump:Set(DEFAULTS.JumpHeight)
    end,
})

SliderGravity = MiscTab:CreateSlider({
    Name = "Gravity",
    Range = {0, 196.2},
    Increment = 1,
    Suffix = "m/s²",
    CurrentValue = DEFAULTS.Gravity,
    Flag = "GravitySlider",
    Callback = function(Value)
        Workspace.Gravity = Value
    end,
})

MiscTab:CreateButton({
    Name = "Reset Gravity",
    Callback = function()
        SliderGravity:Set(DEFAULTS.Gravity)
    end,
})

MiscTab:CreateButton({
    Name = "RESET ALL",
    Callback = function()
        ToggleFly:Set(DEFAULTS.Fly)
        SliderFlySpeed:Set(DEFAULTS.FlySpeed)
        ToggleNoclip:Set(DEFAULTS.Noclip)
        ToggleGod:Set(DEFAULTS.GodMode)
        SliderSpeed:Set(DEFAULTS.WalkSpeed)
        ToggleInfJump:Set(DEFAULTS.InfJump)
        SliderJump:Set(DEFAULTS.JumpHeight)
        SliderGravity:Set(DEFAULTS.Gravity)
    end,
})


-- | SETTINGS |

local antiFling = false
local antiAFK = false
local freeCam = false
local fullbright = false
local lowGraphics = false

RunService.Stepped:Connect(function()
    if antiFling then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    if antiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end
end)

local freeCamConn, touchBeganConn, inputConn, touchEndedConn
local camYaw, camPitch = 0, 0
local sensitivity = 0.3
local activeCameraTouch = nil

local function startFreeCam()
    local cam = Workspace.CurrentCamera
    if HumanoidRootPart then HumanoidRootPart.Anchored = true end
    cam.CameraType = Enum.CameraType.Scriptable

    local rx, ry, _ = cam.CFrame:ToOrientation()
    camYaw = math.deg(ry)
    camPitch = math.deg(rx)

    touchBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not freeCam then return end
        if input.UserInputType == Enum.UserInputType.Touch then
            local viewportSize = cam.ViewportSize
            if input.Position.X > (viewportSize.X * 0.35) and not activeCameraTouch then
                activeCameraTouch = input
            end
        end
    end)

    inputConn = UserInputService.InputChanged:Connect(function(input)
        if not freeCam then return end
        local delta = Vector2.zero
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            delta = input.Delta
        elseif input.UserInputType == Enum.UserInputType.Touch and input == activeCameraTouch then
            delta = input.Delta
        end
        if delta ~= Vector2.zero then
            camYaw = camYaw - (delta.X * sensitivity)
            camPitch = math.clamp(camPitch - (delta.Y * sensitivity), -85, 85)
        end
    end)

    touchEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input == activeCameraTouch then
            activeCameraTouch = nil
        end
    end)

    freeCamConn = RunService.RenderStepped:Connect(function()
        if not freeCam then return end
        local rotCFrame = CFrame.Angles(0, math.rad(camYaw), 0) * CFrame.Angles(math.rad(camPitch), 0, 0)
        local moveDir = Vector3.zero

        local rawMove = Humanoid.MoveDirection
        if rawMove.Magnitude > 0 then
            local flatCamLook = Vector3.new(rotCFrame.LookVector.X, 0, rotCFrame.LookVector.Z).Unit
            local flatCamRight = Vector3.new(rotCFrame.RightVector.X, 0, rotCFrame.RightVector.Z).Unit
            moveDir = (rotCFrame.LookVector * rawMove:Dot(flatCamLook)) + (rotCFrame.RightVector * rawMove:Dot(flatCamRight))
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        cam.CFrame = CFrame.new(cam.CFrame.Position + (moveDir * 1.5)) * rotCFrame
    end)
end

local function stopFreeCam()
    if freeCamConn then freeCamConn:Disconnect() end
    if touchBeganConn then touchBeganConn:Disconnect() end
    if inputConn then inputConn:Disconnect() end
    if touchEndedConn then touchEndedConn:Disconnect() end
    activeCameraTouch = nil

    if HumanoidRootPart then HumanoidRootPart.Anchored = false end
    Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

SettingsTab:CreateToggle({
    Name = "Anti-Fling",
    CurrentValue = false,
    Flag = "AntiFlingToggle",
    Callback = function(Value)
        antiFling = Value
    end,
})

SettingsTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFKToggle",
    Callback = function(Value)
        antiAFK = Value
    end,
})

SettingsTab:CreateToggle({
    Name = "FreeCam",
    CurrentValue = false,
    Flag = "FreeCamToggle",
    Callback = function(Value)
        freeCam = Value
        if freeCam then
            startFreeCam()
        else
            stopFreeCam()
        end
    end,
})

SettingsTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "FullbrightToggle",
    Callback = function(Value)
        fullbright = Value
        if fullbright then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 2
            Lighting.GlobalShadows = false
        else
            Lighting.Ambient = Color3.fromRGB(127, 127, 127)
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
        end
    end,
})

SettingsTab:CreateToggle({
    Name = "Disable Shadows",
    CurrentValue = false,
    Flag = "DisableShadowsToggle",
    Callback = function(Value)
        Lighting.GlobalShadows = not Value
    end,
})

SettingsTab:CreateToggle({
    Name = "Low Graphics Mode",
    CurrentValue = false,
    Flag = "LowGraphicsToggle",
    Callback = function(Value)
        lowGraphics = Value
        for _, object in pairs(Workspace:GetDescendants()) do
            if object:IsA("BasePart") then
                object.Material = lowGraphics and Enum.Material.SmoothPlastic or Enum.Material.Plastic
            end
        end
    end,
})

SettingsTab:CreateSlider({
    Name = "Field of View (FOV)",
    Range = {70, 120},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 70,
    Flag = "FOVSlider",
    Callback = function(Value)
        Workspace.CurrentCamera.FieldOfView = Value
    end,
})

SettingsTab:CreateSlider({
    Name = "Max FPS Cap",
    Range = {30, 240},
    Increment = 5,
    Suffix = "FPS",
    CurrentValue = 60,
    Flag = "FPSCapSlider",
    Callback = function(Value)
        if setfpscap then
            setfpscap(Value)
        end
    end,
})

SettingsTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

SettingsTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if success and result and result.data then
            for _, server in pairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    break
                end
            end
        end
    end,
})

SettingsTab:CreateButton({
    Name = "Destroy Interface",
    Callback = function()
        Rayfield:Destroy()
    end,
})


-- | EXPERIMENTAL |

local noclip = false
local noclipConn

local function startNoclip()
    noclipConn = RunService.Stepped:Connect(function()
        if not noclip or not Character then return end
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function stopNoclip()
    if noclipConn then noclipConn:Disconnect() end
    if Character then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

ToggleNoclip = ExperimentalTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = DEFAULTS.Noclip,
    Flag = "NoclipToggle",
    Callback = function(Value)
        noclip = Value
        if noclip then
            startNoclip()
        else
            stopNoclip()
        end
    end,
})


-- | MISCELLANEOUS |
Rayfield:Notify({
   Title = "Successfully loaded Wallhop Script.",
   Content = "Loaded.",
   Duration = 5,
   Image = nil,
})
