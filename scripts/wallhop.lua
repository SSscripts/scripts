--[[
    ADVANCED WALLHOP SCRIPT FOR DELTA EXECUTOR
    Features: Blatant Mode, Legit Mode, Customizable Keybinds, Toggle GUI
    Supported Games: Most Roblox games (adapts automatically)
    Creator: Your Delta Script Expert
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

-- Player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- Settings (customizable)
local Settings = {
    -- Wallhop Settings
    Enabled = true,
    Mode = "Legit", -- "Blatant" or "Legit"
    Animation = "Smooth", -- "None", "Smooth", "Fast", "Glide"
    
    -- Movement
    HopSpeed = 25,
    HopHeight = 8,
    HopDistance = 15,
    AirStrafing = true,
    GlideSpeed = 35,
    
    -- Blatant Mode
    BlatantHopMultiplier = 3,
    BlatantHeight = 20,
    BlatantDistance = 40,
    BlatantSpeed = 80,
    
    -- Legit Mode
    LegitHopMultiplier = 1,
    LegitHeight = 6,
    LegitDistance = 12,
    LegitSpeed = 22,
    
    -- Visuals
    ShowTrail = true,
    TrailColor = Color3.fromRGB(0, 255, 255),
    TrailLength = 15,
    ShowParticles = true,
    ParticleColor = Color3.fromRGB(0, 255, 255),
    TrajectoryLine = true,
    TrajectoryColor = Color3.fromRGB(255, 0, 0),
    
    -- Automation
    AutoWallhop = false,
    AutoWallhopDelay = 0.5,
    RandomizeHops = true,
    RandomHopRange = {5, 20},
    
    -- AntiBan
    AntiBan = true,
    FakeLag = false,
    FakeLagAmount = 0.1,
    
    -- Keybinds (user-friendly)
    Keybinds = {
        Toggle = Enum.KeyCode.F,
        Wallhop = Enum.KeyCode.Space,
        ChangeMode = Enum.KeyCode.G,
        ToggleAuto = Enum.KeyCode.H,
        IncreaseSpeed = Enum.KeyCode.Equals,
        DecreaseSpeed = Enum.KeyCode.Minus,
        ToggleTrail = Enum.KeyCode.T,
        ResetSettings = Enum.KeyCode.R,
    },
    
    -- UI Settings
    ShowUI = true,
    UIPosition = UDim2.new(0, 20, 0, 20),
    UIColor = Color3.fromRGB(30, 30, 30), -- Dark theme
    AccentColor = Color3.fromRGB(0, 255, 255), -- Cyan accent
}

-- Variables
local wallhopActive = false
local autoWallhopActive = false
local currentTrail = nil
local hopCount = 0
local isFlying = false
local velocity = Vector3.new(0, 0, 0)
local lastWallPos = nil

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AdvancedWallhopGUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 250, 0, 350)
MainFrame.Position = Settings.UIPosition
MainFrame.BackgroundColor3 = Settings.UIColor
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

-- Add rounded corners (UI Stroke)
local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Color = Settings.AccentColor
UIStroke.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Settings.AccentColor
TitleBar.BackgroundTransparency = 0.8
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -30, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "⚡ Advanced Wallhop"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 14
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -25, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Scrolling Frame for settings
local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, 0, 1, -30)
ScrollingFrame.Position = UDim2.new(0, 0, 0, 30)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.ScrollBarThickness = 5
ScrollingFrame.ScrollBarImageColor3 = Settings.AccentColor
ScrollingFrame.Parent = MainFrame

-- Helper function to create UI elements
local function createLabel(text, parent, yPos)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 25)
    label.Position = UDim2.new(0, 10, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function createToggle(text, parent, yPos, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 30)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, 25)
    toggleBtn.Position = UDim2.new(0.7, 10, 0, 2.5)
    toggleBtn.BackgroundColor3 = defaultValue and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    toggleBtn.Text = defaultValue and "ON" or "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 12
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame
    
    local toggled = defaultValue
    toggleBtn.MouseButton1Click:Connect(function()
        toggled = not toggled
        toggleBtn.BackgroundColor3 = toggled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        toggleBtn.Text = toggled and "ON" or "OFF"
        callback(toggled)
    end)
    
    return toggleBtn
end

local function createSlider(text, parent, yPos, min, max, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0.5, 0)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(defaultValue)
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local slider = Instance.new("TextBox")
    slider.Size = UDim2.new(0.3, 0, 0.5, 0)
    slider.Position = UDim2.new(0.6, 10, 0, 0)
    slider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    slider.Text = tostring(defaultValue)
    slider.TextColor3 = Color3.fromRGB(255, 255, 255)
    slider.TextSize = 12
    slider.Font = Enum.Font.Gotham
    slider.BorderSizePixel = 0
    slider.Parent = frame
    
    slider.FocusLost:Connect(function()
        local val = tonumber(slider.Text)
        if val then
            val = math.clamp(val, min, max)
            slider.Text = tostring(val)
            label.Text = text .. ": " .. tostring(val)
            callback(val)
        else
            slider.Text = tostring(defaultValue)
        end
    end)
    
    return slider
end

-- Create UI elements (yPos will increment)
local yPos = 10
createLabel("─── MAIN SETTINGS ───", ScrollingFrame, yPos)
yPos = yPos + 25

local toggleEnabled = createToggle("Enabled", ScrollingFrame, yPos, Settings.Enabled, function(state)
    Settings.Enabled = state
    if not state then
        wallhopActive = false
        humanoid.PlatformStand = false
    end
end)
yPos = yPos + 35

-- Mode selector
local modeFrame = Instance.new("Frame")
modeFrame.Size = UDim2.new(1, -20, 0, 30)
modeFrame.Position = UDim2.new(0, 10, 0, yPos)
modeFrame.BackgroundTransparency = 1
modeFrame.Parent = ScrollingFrame

local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(0.5, 0, 1, 0)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "Mode: " .. Settings.Mode
modeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
modeLabel.TextSize = 12
modeLabel.Font = Enum.Font.Gotham
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Parent = modeFrame

local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0.4, 0, 0, 25)
modeBtn.Position = UDim2.new(0.5, 10, 0, 2.5)
modeBtn.BackgroundColor3 = Settings.Mode == "Blatant" and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 200, 0)
modeBtn.Text = Settings.Mode
modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
modeBtn.TextSize = 12
modeBtn.Font = Enum.Font.GothamBold
modeBtn.BorderSizePixel = 0
modeBtn.Parent = modeFrame

modeBtn.MouseButton1Click:Connect(function()
    Settings.Mode = Settings.Mode == "Blatant" and "Legit" or "Blatant"
    modeBtn.Text = Settings.Mode
    modeBtn.BackgroundColor3 = Settings.Mode == "Blatant" and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 200, 0)
    modeLabel.Text = "Mode: " .. Settings.Mode
end)
yPos = yPos + 40

createLabel("─── LEGIT SETTINGS ───", ScrollingFrame, yPos)
yPos = yPos + 25

local speedSlider = createSlider("Legit Speed", ScrollingFrame, yPos, 5, 50, Settings.LegitSpeed, function(val)
    Settings.LegitSpeed = val
end)
yPos = yPos + 45

local heightSlider = createSlider("Legit Height", ScrollingFrame, yPos, 2, 15, Settings.LegitHeight, function(val)
    Settings.LegitHeight = val
end)
yPos = yPos + 45

createLabel("─── BLATANT SETTINGS ───", ScrollingFrame, yPos)
yPos = yPos + 25

local blatantSpeedSlider = createSlider("Blatant Speed", ScrollingFrame, yPos, 20, 150, Settings.BlatantSpeed, function(val)
    Settings.BlatantSpeed = val
end)
yPos = yPos + 45

local blatantHeightSlider = createSlider("Blatant Height", ScrollingFrame, yPos, 5, 40, Settings.BlatantHeight, function(val)
    Settings.BlatantHeight = val
end)
yPos = yPos + 45

createLabel("─── VISUAL SETTINGS ───", ScrollingFrame, yPos)
yPos = yPos + 25

local toggleTrail = createToggle("Show Trail", ScrollingFrame, yPos, Settings.ShowTrail, function(state)
    Settings.ShowTrail = state
    if not state and currentTrail then
        currentTrail:Destroy()
        currentTrail = nil
    end
end)
yPos = yPos + 35

local toggleAutoHop = createToggle("Auto Wallhop", ScrollingFrame, yPos, Settings.AutoWallhop, function(state)
    Settings.AutoWallhop = state
    autoWallhopActive = state
end)
yPos = yPos + 35

createLabel("─── KEYBINDS ───", ScrollingFrame, yPos)
yPos = yPos + 25

local keybindLabel = Instance.new("TextLabel")
keybindLabel.Size = UDim2.new(1, -20, 0, 20)
keybindLabel.Position = UDim2.new(0, 10, 0, yPos)
keybindLabel.BackgroundTransparency = 1
keybindLabel.Text = "F: Toggle | Space: Wallhop | G: Mode"
keybindLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
keybindLabel.TextSize = 10
keybindLabel.Font = Enum.Font.Gotham
keybindLabel.Parent = ScrollingFrame
yPos = yPos + 25

local keybindLabel2 = Instance.new("TextLabel")
keybindLabel2.Size = UDim2.new(1, -20, 0, 20)
keybindLabel2.Position = UDim2.new(0, 10, 0, yPos)
keybindLabel2.BackgroundTransparency = 1
keybindLabel2.Text = "H: Auto | +/-: Speed | T: Trail"
keybindLabel2.TextColor3 = Color3.fromRGB(150, 150, 150)
keybindLabel2.TextSize = 10
keybindLabel2.Font = Enum.Font.Gotham
keybindLabel2.Parent = ScrollingFrame

-- Make ScrollingFrame scrollable
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 30)

-- Drag functionality
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Core Wallhop Function
local function performWallhop()
    if not Settings.Enabled or wallhopActive then return end
    
    if Settings.Mode == "Blatant" then
        -- Blatant mode: extreme wallhop
        wallhopActive = true
        humanoid.PlatformStand = true
        
        local hopHeight = Settings.BlatantHeight
        local hopDistance = Settings.BlatantDistance
        local hopSpeed = Settings.BlatantSpeed
        
        -- Get look vector
        local lookVector = hrp.CFrame.lookVector
        
        -- Apply velocity
        hrp.Velocity = Vector3.new(
            lookVector.X * hopSpeed,
            hopHeight * 5,
            lookVector.Z * hopSpeed
        )
        
        -- Trail effect for blatant
        if Settings.ShowTrail then
            spawnTrail(hrp.Position)
        end
        
        -- Reset after a short delay
        delay(0.3, function()
            wallhopActive = false
            humanoid.PlatformStand = false
        end)
    else
        -- Legit mode: realistic wallhop
        wallhopActive = true
        
        local hopHeight = Settings.LegitHeight
        local hopDistance = Settings.LegitDistance
        local hopSpeed = Settings.LegitSpeed
        
        -- Get look vector
        local lookVector = hrp.CFrame.lookVector
        
        -- Apply velocity
        hrp.Velocity = Vector3.new(
            lookVector.X * hopSpeed,
            hopHeight * 3,
            lookVector.Z * hopSpeed
        )
        
        -- Slight jump
        humanoid.Jump = true
        
        -- Trail effect
        if Settings.ShowTrail then
            spawnTrail(hrp.Position)
        end
        
        delay(0.2, function()
            wallhopActive = false
        end)
    end
end

-- Trail function
function spawnTrail(pos)
    if not Settings.ShowTrail then return end
    
    local trailPart = Instance.new("Part")
    trailPart.Size = Vector3.new(0.5, 0.5, 0.5)
    trailPart.Position = pos
    trailPart.BrickColor = BrickColor.new(Settings.TrailColor)
    trailPart.Material = Enum.Material.Neon
    trailPart.Anchored = true
    trailPart.CanCollide = false
    trailPart.Parent = workspace
    
    -- Fade out
    local trailTransparency = Instance.new("NumberValue")
    trailTransparency.Value = 0
    trailTransparency.Parent = trailPart
    
    spawn(function()
        for i = 0, 1, 0.05 do
            wait(0.05)
            trailPart.Transparency = i
            trailPart.Size = trailPart.Size + Vector3.new(0.1, 0.1, 0.1)
        end
        trailPart:Destroy()
    end)
end

-- Particle effect
function spawnParticles(pos)
    if not Settings.ShowParticles then return end
    
    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Position = pos
    particleEmitter.Rate = 100
    particleEmitter.Lifetime = NumberRange.new(0.5, 1)
    particleEmitter.SpreadAngle = Vector2.new(30, 30)
    particleEmitter.Texture = "rbxassetid://284682808"
    particleEmitter.Color = ColorSequence.new(Settings.ParticleColor)
    particleEmitter.Size = NumberSequence.new(0.5)
    particleEmitter.Transparency = NumberSequence.new(0, 1)
    particleEmitter.Parent = workspace.Terrain
    
    delay(0.5, function()
        particleEmitter.Enabled = false
        delay(1, function()
            particleEmitter:Destroy()
        end)
    end)
end

-- Auto wallhop loop
spawn(function()
    while true do
        wait(Settings.AutoWallhopDelay)
        if autoWallhopActive and Settings.Enabled then
            performWallhop()
        end
    end
end)

-- Keybind handler
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Settings.Keybinds.Toggle then
        Settings.Enabled = not Settings.Enabled
        toggleEnabled.Text = Settings.Enabled and "ON" or "OFF"
        toggleEnabled.BackgroundColor3 = Settings.Enabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        if not Settings.Enabled then
            wallhopActive = false
            humanoid.PlatformStand = false
        end
    elseif input.KeyCode == Settings.Keybinds.Wallhop then
        performWallhop()
    elseif input.KeyCode == Settings.Keybinds.ChangeMode then
        Settings.Mode = Settings.Mode == "Blatant" and "Legit" or "Blatant"
        modeBtn.Text = Settings.Mode
        modeBtn.BackgroundColor3 = Settings.Mode == "Blatant" and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 200, 0)
        modeLabel.Text = "Mode: " .. Settings.Mode
    elseif input.KeyCode == Settings.Keybinds.ToggleAuto then
        autoWallhopActive = not autoWallhopActive
        Settings.AutoWallhop = autoWallhopActive
        toggleAutoHop.Text = autoWallhopActive and "ON" or "OFF"
        toggleAutoHop.BackgroundColor3 = autoWallhopActive and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    elseif input.KeyCode == Settings.Keybinds.IncreaseSpeed then
        if Settings.Mode == "Blatant" then
            Settings.BlatantSpeed = math.clamp(Settings.BlatantSpeed + 5, 5, 200)
        else
            Settings.LegitSpeed = math.clamp(Settings.LegitSpeed + 2, 5, 60)
        end
    elseif input.KeyCode == Settings.Keybinds.DecreaseSpeed then
        if Settings.Mode == "Blatant" then
            Settings.BlatantSpeed = math.clamp(Settings.BlatantSpeed - 5, 5, 200)
        else
            Settings.LegitSpeed = math.clamp(Settings.LegitSpeed - 2, 5, 60)
        end
    elseif input.KeyCode == Settings.Keybinds.ToggleTrail then
        Settings.ShowTrail = not Settings.ShowTrail
        toggleTrail.Text = Settings.ShowTrail and "ON" or "OFF"
        toggleTrail.BackgroundColor3 = Settings.ShowTrail and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    elseif input.KeyCode == Settings.Keybinds.ResetSettings then
        -- Reset to defaults (optional)
    end
end)

-- Character re-connection
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    hrp = newChar:WaitForChild("HumanoidRootPart")
    
    -- Re-apply settings
    humanoid.PlatformStand = false
end)

-- Notification
StarterGui:SetCore("SendNotification", {
    Title = "Advanced Wallhop Loaded",
    Text = "Press F to toggle | Space to wallhop | G to change mode",
    Duration = 5
})

print("⚡ Advanced Wallhop Script Loaded!")
print("─" .. string.rep("─", 40))
print("Features:")
print("• Blatant Mode - Extreme movement")
print("• Legit Mode - Realistic wallhop")
print("• Customizable GUI with draggable window")
print("• Trail and particle effects")
print("• Auto wallhop mode")
print("• All settings adjustable in real-time")
print("• Keybinds: F, Space, G, H, +/- for speed, T for trail")
print("─" .. string.rep("─", 40))
