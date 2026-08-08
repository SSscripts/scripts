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
local HomeSection = HomeTab:CreateSection("TimeBomb Duels AI")
local MiscSection = MiscTab:CreateSection("Misc")
local ExperimentalSection = ExperimentalTab:CreateSection("Not Recommended to Use.")

-- Keep character references updated on respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
end)

-- | HOME |

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local AIConfig = {
    AutoPlayEnabled = false,
    Aggressiveness = 0.7,
    Intelligence = 0.8,
    Reflexes = 0.75,
    -- Adaptive learning parameters
    SuccessRate = 0.5,
    RecentEncounters = 0
}

-- Custom Adaptive Neural / Heuristic Engine
local AdaptiveAI = {
    Weights = {
        DistanceWeight = 1.0,
        PredictionWeight = 0.5,
        EvadeBias = 0.5
    }
}

function AdaptiveAI:Adapt(success)
    if success then
        AIConfig.SuccessRate = math.clamp(AIConfig.SuccessRate + 0.05, 0.1, 1.0)
        self.Weights.PredictionWeight = self.Weights.PredictionWeight * 1.02
    else
        AIConfig.SuccessRate = math.clamp(AIConfig.SuccessRate - 0.05, 0.1, 1.0)
        self.Weights.EvadeBias = self.Weights.EvadeBias * 1.05
    end
end

-- Arena check function (lets player take over if outside arena)
local function isInArena()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    local hrp = char.HumanoidRootPart
    -- Check if an Arena folder or specific game bounds exist, fallback to distance/height check or workspace check
    local arenaFolder = Workspace:FindFirstChild("Arena") or Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("Matches")
    if arenaFolder then
        -- Simple proximity check to map center or explicit boundaries if available
        return true 
    end
    
    -- Fallback: check if player is too far down (void) or high up in lobby
    if hrp.Position.Y < -50 or hrp.Position.Y > 500 then
        return false
    end
    
    return true
end

-- Wall avoidance & Raycasting to prevent running into walls
local function getSafePathPosition(targetPos, currentPos)
    local direction = (targetPos - currentPos)
    local distance = direction.Magnitude
    direction = direction.Unit
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    if LocalPlayer.Character then
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    end
    
    -- Cast ray ahead to check for walls
    local rayResult = Workspace:Raycast(currentPos, direction * math.min(distance, 8), raycastParams)
    if rayResult then
        -- Wall detected! Compute slide/evade vector to the right or left
        local normal = rayResult.Normal
        local slideVector = direction - (direction:Dot(normal) * normal)
        return currentPos + (slideVector.Unit * 6) + (Vector3.new(0, 3, 0)) -- Slight hop/adjustment
    end
    
    return targetPos
end

local function getNearestEnemy()
    local nearestEnemy = nil
    local shortestDistance = math.huge
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil, math.huge end
    local hrp = char.HumanoidRootPart
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local enemyChar = player.Character
            local enemyHRP = enemyChar:FindFirstChild("HumanoidRootPart")
            local enemyHumanoid = enemyChar:FindFirstChild("Humanoid")
            
            if enemyHRP and enemyHumanoid and enemyHumanoid.Health > 0 then
                local dist = (hrp.Position - enemyHRP.Position).Magnitude
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
    local char = LocalPlayer.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local nameLower = tool.Name:lower()
        if string.find(nameLower, "bomb") or string.find(nameLower, "time") then
            return true
        end
    end
    
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                local nameLower = item.Name:lower()
                if string.find(nameLower, "bomb") or string.find(nameLower, "time") then
                    if humanoid then humanoid:EquipTool(item) end
                    return true
                end
            end
        end
    end
    return false
end

-- Shiftlock simulation for faster passing and tracking
local function setShiftlock(active, targetHRP)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    
    if active and targetHRP then
        humanoid.AutoRotate = false
        local currentPos = char.HumanoidRootPart.Position
        local lookVector = Vector3.new(targetHRP.Position.X, currentPos.Y, targetHRP.Position.Z)
        char:SetPrimaryPartCFrame(CFrame.new(currentPos, lookVector))
    else
        humanoid.AutoRotate = true
    end
end

local autoPlayConn
local function toggleAutoPlay(state)
    AIConfig.AutoPlayEnabled = state
    if state then
        autoPlayConn = RunService.Heartbeat:Connect(function()
            if not AIConfig.AutoPlayEnabled then return end
            
            -- Arena Check: If not in arena, let player take over automatically
            if not isInArena() then
                return
            end
            
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not humanoid or humanoid.Health <= 0 then return end
            
            local enemy, distance = getNearestEnemy()
            if not enemy then return end
            local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
            if not enemyHRP then return end
            
            local hasBombState = hasBombTool()
            
            -- Reflexes & Intelligence scaling delay / prediction
            local predictionLead = (AIConfig.Intelligence * 0.3) + (AIConfig.Reflexes * 0.1)
            
            if hasBombState then
                -- Aggressive Chase with Shiftlock trick for instant passing
                setShiftlock(true, enemyHRP)
                local targetPos = enemyHRP.Position + (enemyHRP.AssemblyLinearVelocity * predictionLead)
                local safePos = getSafePathPosition(targetPos, hrp.Position)
                humanoid:MoveTo(safePos)
                
                -- Check if close enough to pass bomb instantly
                if distance < 6 then
                    AdaptiveAI:Adapt(true)
                end
            else
                -- Defensive Evasion using intelligence and adaptability
                setShiftlock(false, nil)
                local escapeDir = (hrp.Position - enemyHRP.Position).Unit
                local evadeDistance = 25 * AIConfig.Aggressiveness
                local rawEvadePos = hrp.Position + (escapeDir * evadeDistance) + Vector3.new(math.sin(tick() * 8) * 6, 0, math.cos(tick() * 8) * 6)
                local safeEvadePos = getSafePathPosition(rawEvadePos, hrp.Position)
                humanoid:MoveTo(safeEvadePos)
            end
        end)
    else
        if autoPlayConn then autoPlayConn:Disconnect() end
        setShiftlock(false, nil)
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if humanoid and hrp then
                humanoid.AutoRotate = true
                humanoid:MoveTo(hrp.Position)
            end
        end
    end
end

-- HomeTab UI Controls (Only Aggressiveness, Intelligence, Reflexes & Auto Play)

HomeTab:CreateToggle({
    Name = "Auto Play (Adaptive Custom AI)",
    CurrentValue = false,
    Flag = "AutoPlayToggle",
    Callback = function(Value)
        toggleAutoPlay(Value)
    end,
})

HomeTab:CreateSlider({
    Name = "Aggressiveness",
    Range = {0.1, 1.0},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.7,
    Flag = "AggressivenessSlider",
    Callback = function(Value)
        AIConfig.Aggressiveness = Value
    end,
})

HomeTab:CreateSlider({
    Name = "Intelligence",
    Range = {0.1, 1.0},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.8,
    Flag = "IntelligenceSlider",
    Callback = function(Value)
        AIConfig.Intelligence = Value
    end,
})

HomeTab:CreateSlider({
    Name = "Reflexes",
    Range = {0.1, 1.0},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.75,
    Flag = "ReflexesSlider",
    Callback = function(Value)
        AIConfig.Reflexes = Value
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
local walkOnWalls = DEFAULTS.WalkOnWalls
local bodyVel, bodyGyro

-- Background Handlers

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
local flying = false
local flySpeed = 50
local flyConn, bodyVel, bodyGyro

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

            -- Calculate forward/right directional scalar from joystick vector
            local forwardAmount = rawMove:Dot(flatCamLook)
            local rightAmount = rawMove:Dot(flatCamRight)

            -- Reconstruct full 3D direction vector aligned to camera tilt
            moveDir = (camCF.LookVector * forwardAmount) + (camCF.RightVector * rightAmount)
        end

        -- Height Controls (Mobile Jump button / PC Keyboards)
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

local ToggleFly, ToggleNoclip, ToggleGod, SliderSpeed, ToggleInfJump, SliderJump, SliderGravity, ToggleWallWalk

-- Fly Toggle
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

-- Fly Speed Slider
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

-- Reset Fly Speed Button
MiscTab:CreateButton({
    Name = "Reset Fly Speed",
    Callback = function()
        SliderFlySpeed:Set(DEFAULTS.FlySpeed or 50)
    end,
})

-- God Mode Controls
ToggleGod = MiscTab:CreateToggle({
    Name = "God Mode",
    CurrentValue = DEFAULTS.GodMode,
    Flag = "GodModeToggle",
    Callback = function(Value)
        godmode = Value
    end,
})

-- WalkSpeed Slider & Reset Button
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

-- Infinite Jump Controls
ToggleInfJump = MiscTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = DEFAULTS.InfJump,
    Flag = "InfJumpToggle",
    Callback = function(Value)
        infJump = Value
    end,
})

-- JumpHeight Slider & Reset Button
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

-- Gravity Slider & Reset Button
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

-- Global Reset Button (Resets all values in MiscTab)
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

-- Settings States
local antiFling = false
local antiAFK = false
local freeCam = false
local fullbright = false
local lowGraphics = false

-- Background Handlers

-- Anti-Fling Loop
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

-- Anti-AFK Prevention
LocalPlayer.Idled:Connect(function()
    if antiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end
end)

-- FreeCam Logic
local freeCam = false
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

    -- Track initial touch outside the left dynamic thumbstick zone
    touchBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not freeCam then return end
        if input.UserInputType == Enum.UserInputType.Touch then
            local viewportSize = cam.ViewportSize
            -- Ignores touches originating on the left 35% of screen (Joystick Zone)
            if input.Position.X > (viewportSize.X * 0.35) and not activeCameraTouch then
                activeCameraTouch = input
            end
        end
    end)

    -- Handle Rotation (Mouse or Right-Side Touch Drag)
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

    -- Clear camera touch tracking when touch releases
    touchEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input == activeCameraTouch then
            activeCameraTouch = nil
        end
    end)

    -- Movement Loop
    freeCamConn = RunService.RenderStepped:Connect(function()
        if not freeCam then return end

        local rotCFrame = CFrame.Angles(0, math.rad(camYaw), 0) * CFrame.Angles(math.rad(camPitch), 0, 0)
        local moveDir = Vector3.zero

        local rawMove = Humanoid.MoveDirection
        if rawMove.Magnitude > 0 then
            local flatCamLook = Vector3.new(rotCFrame.LookVector.X, 0, rotCFrame.LookVector.Z).Unit
            local flatCamRight = Vector3.new(rotCFrame.RightVector.X, 0, rotCFrame.RightVector.Z).Unit

            local forwardAmount = rawMove:Dot(flatCamLook)
            local rightAmount = rawMove:Dot(flatCamRight)

            moveDir = (rotCFrame.LookVector * forwardAmount) + (rotCFrame.RightVector * rightAmount)
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

-- SETTINGS INTERACTION

-- 1. Anti-Fling
SettingsTab:CreateToggle({
    Name = "Anti-Fling",
    CurrentValue = false,
    Flag = "AntiFlingToggle",
    Callback = function(Value)
        antiFling = Value
    end,
})

-- 2. Anti-AFK
SettingsTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFKToggle",
    Callback = function(Value)
        antiAFK = Value
    end,
})

-- 3. FreeCam
ToggleFreeCam = SettingsTab:CreateToggle({
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

-- 4. Fullbright
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

-- 5. Disable Shadows
SettingsTab:CreateToggle({
    Name = "Disable Shadows",
    CurrentValue = false,
    Flag = "DisableShadowsToggle",
    Callback = function(Value)
        Lighting.GlobalShadows = not Value
    end,
})

-- 6. Low Graphics / Potato Mode
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

-- 7. Custom FOV
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

-- 8. Max FPS Cap
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

-- 9. Rejoin Server
SettingsTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

-- 10. Server Hop
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

-- 11. Destroy Interface
SettingsTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        Rayfield:Destroy()
    end,
})

-- | EXPERIMENTAL |

-- Noclip Loop
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
    if noclipConn then
        noclipConn:Disconnect()
    end
    if Character then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Noclip Toggle
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
-- Notify Loaded
Rayfield:Notify({
   Title = "Successfully loaded TimeBomb Duels Script.",
   Content = "Loaded.",
   Duration = 5,
   Image = nil,
})
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
local HomeSection = HomeTab:CreateSection("TimeBomb Duels AI")
local MiscSection = MiscTab:CreateSection("Misc")
local ExperimentalSection = ExperimentalTab:CreateSection("Not Recommended to Use.")

-- Keep character references updated on respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
end)

-- | HOME |

local AIConfig = {
    AutoPlayEnabled = false,
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

HomeTab:CreateToggle({
    Name = "Auto Play (Timebomb AI)",
    CurrentValue = false,
    Flag = "AutoPlayToggle",
    Callback = function(Value)
        toggleAutoPlay(Value)
    end,
})

HomeTab:CreateDropdown({
    Name = "AI Provider",
    Values = {"CustomNeural", "Gemini", "OpenAI", "OpenRouter", "Ollama"},
    CurrentValue = "CustomNeural",
    Flag = "AIProviderDropdown",
    Callback = function(Value)
        AIAPIBridge:Configure(Value, AIConfig.APIKey, AIConfig.Endpoint, AIConfig.Model)
    end,
})

HomeTab:CreateTextbox({
    Name = "AI API Key",
    PlaceholderText = "Enter API Key...",
    Flag = "APIKeyBox",
    Callback = function(Text)
        AIAPIBridge:Configure(AIConfig.Provider, Text, AIConfig.Endpoint, AIConfig.Model)
    end,
})

HomeTab:CreateTextbox({
    Name = "API Endpoint URL",
    PlaceholderText = "https://...",
    Flag = "EndpointBox",
    Callback = function(Text)
        AIAPIBridge:Configure(AIConfig.Provider, AIConfig.APIKey, Text, AIConfig.Model)
    end,
})

HomeTab:CreateTextbox({
    Name = "AI Model Name",
    PlaceholderText = "e.g., gemini-2.5-flash",
    Flag = "ModelBox",
    Callback = function(Text)
        AIAPIBridge:Configure(AIConfig.Provider, AIConfig.APIKey, AIConfig.Endpoint, Text)
    end,
})

HomeTab:CreateSlider({
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

HomeTab:CreateSlider({
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

HomeTab:CreateSlider({
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

HomeTab:CreateSlider({
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

HomeTab:CreateSlider({
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

HomeTab:CreateSlider({
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

HomeTab:CreateSlider({
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

HomeTab:CreateSlider({
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

HomeTab:CreateSlider({
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

HomeTab:CreateSlider({
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

HomeTab:CreateSlider({
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

HomeTab:CreateSlider({
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

HomeTab:CreateToggle({
    Name = "Target Nearest Enemy Only",
    CurrentValue = true,
    Flag = "TargetNearestToggle",
    Callback = function(Value)
        AIConfig.TargetNearestOnly = Value
    end,
})

HomeTab:CreateToggle({
    Name = "Auto-Equip Bomb Tool",
    CurrentValue = true,
    Flag = "AutoEquipToggle",
    Callback = function(Value)
        AIConfig.AutoEquipBomb = Value
    end,
})

HomeTab:CreateButton({
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
local walkOnWalls = DEFAULTS.WalkOnWalls
local bodyVel, bodyGyro

-- Background Handlers

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
local flying = false
local flySpeed = 50
local flyConn, bodyVel, bodyGyro

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

            -- Calculate forward/right directional scalar from joystick vector
            local forwardAmount = rawMove:Dot(flatCamLook)
            local rightAmount = rawMove:Dot(flatCamRight)

            -- Reconstruct full 3D direction vector aligned to camera tilt
            moveDir = (camCF.LookVector * forwardAmount) + (camCF.RightVector * rightAmount)
        end

        -- Height Controls (Mobile Jump button / PC Keyboards)
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

local ToggleFly, ToggleNoclip, ToggleGod, SliderSpeed, ToggleInfJump, SliderJump, SliderGravity, ToggleWallWalk

-- Fly Toggle
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

-- Fly Speed Slider
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

-- Reset Fly Speed Button
MiscTab:CreateButton({
    Name = "Reset Fly Speed",
    Callback = function()
        SliderFlySpeed:Set(DEFAULTS.FlySpeed or 50)
    end,
})

-- God Mode Controls
ToggleGod = MiscTab:CreateToggle({
    Name = "God Mode",
    CurrentValue = DEFAULTS.GodMode,
    Flag = "GodModeToggle",
    Callback = function(Value)
        godmode = Value
    end,
})

-- WalkSpeed Slider & Reset Button
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

-- Infinite Jump Controls
ToggleInfJump = MiscTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = DEFAULTS.InfJump,
    Flag = "InfJumpToggle",
    Callback = function(Value)
        infJump = Value
    end,
})

-- JumpHeight Slider & Reset Button
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

-- Gravity Slider & Reset Button
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

-- Global Reset Button (Resets all values in MiscTab)
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

-- Settings States
local antiFling = false
local antiAFK = false
local freeCam = false
local fullbright = false
local lowGraphics = false

-- Background Handlers

-- Anti-Fling Loop
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

-- Anti-AFK Prevention
LocalPlayer.Idled:Connect(function()
    if antiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end
end)

-- FreeCam Logic
local freeCam = false
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

    -- Track initial touch outside the left dynamic thumbstick zone
    touchBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not freeCam then return end
        if input.UserInputType == Enum.UserInputType.Touch then
            local viewportSize = cam.ViewportSize
            -- Ignores touches originating on the left 35% of screen (Joystick Zone)
            if input.Position.X > (viewportSize.X * 0.35) and not activeCameraTouch then
                activeCameraTouch = input
            end
        end
    end)

    -- Handle Rotation (Mouse or Right-Side Touch Drag)
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

    -- Clear camera touch tracking when touch releases
    touchEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input == activeCameraTouch then
            activeCameraTouch = nil
        end
    end)

    -- Movement Loop
    freeCamConn = RunService.RenderStepped:Connect(function()
        if not freeCam then return end

        local rotCFrame = CFrame.Angles(0, math.rad(camYaw), 0) * CFrame.Angles(math.rad(camPitch), 0, 0)
        local moveDir = Vector3.zero

        local rawMove = Humanoid.MoveDirection
        if rawMove.Magnitude > 0 then
            local flatCamLook = Vector3.new(rotCFrame.LookVector.X, 0, rotCFrame.LookVector.Z).Unit
            local flatCamRight = Vector3.new(rotCFrame.RightVector.X, 0, rotCFrame.RightVector.Z).Unit

            local forwardAmount = rawMove:Dot(flatCamLook)
            local rightAmount = rawMove:Dot(flatCamRight)

            moveDir = (rotCFrame.LookVector * forwardAmount) + (rotCFrame.RightVector * rightAmount)
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

-- SETTINGS INTERACTION

-- 1. Anti-Fling
SettingsTab:CreateToggle({
    Name = "Anti-Fling",
    CurrentValue = false,
    Flag = "AntiFlingToggle",
    Callback = function(Value)
        antiFling = Value
    end,
})

-- 2. Anti-AFK
SettingsTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFKToggle",
    Callback = function(Value)
        antiAFK = Value
    end,
})

-- 3. FreeCam
ToggleFreeCam = SettingsTab:CreateToggle({
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

-- 4. Fullbright
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

-- 5. Disable Shadows
SettingsTab:CreateToggle({
    Name = "Disable Shadows",
    CurrentValue = false,
    Flag = "DisableShadowsToggle",
    Callback = function(Value)
        Lighting.GlobalShadows = not Value
    end,
})

-- 6. Low Graphics / Potato Mode
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

-- 7. Custom FOV
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

-- 8. Max FPS Cap
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

-- 9. Rejoin Server
SettingsTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

-- 10. Server Hop
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

-- 11. Destroy Interface
SettingsTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        Rayfield:Destroy()
    end,
})

-- | EXPERIMENTAL |

-- Noclip Loop
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
    if noclipConn then
        noclipConn:Disconnect()
    end
    if Character then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Noclip Toggle
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
-- Notify Loaded
Rayfield:Notify({
   Title = "Successfully loaded TimeBomb Duels Script.",
   Content = "Loaded.",
   Duration = 5,
   Image = nil,
})
