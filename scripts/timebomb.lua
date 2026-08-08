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
local HomeSection = HomeTab:CreateSection("Wallhop")
local MiscSection = MiscTab:CreateSection("Misc")
local ExperimentalSection = ExperimentalTab:CreateSection("Not Recommended to Use.")

-- Keep character references updated on respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
end)

-- | HOME |

-- Background Handlers

-- AI TimeBomb Duels | Player Faking


-- HOME INTERACTION



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
    Name = "Destroy Interface",
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
   Title = "Successfully loaded Wallhop Script.",
   Content = "Loaded.",
   Duration = 5,
   Image = nil,
})
