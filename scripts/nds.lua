-- =================================================================
-- SefScriptsHub | NDS OVERLORD ENGINE (FE COMPATIBLE)
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

local Window = Rayfield:CreateWindow({
    Name = "SefScriptsHub",
    LoadingTitle = "SefScriptsHub | NDS OVERLORD",
    LoadingSubtitle = "FE Debris Swarm & Flight Engine",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

-- Core Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Hub Tabs
local MovementTab = Window:CreateTab("Movement", 4483362458)
local OrbitTab = Window:CreateTab("Debris Swarm", 4483362458)
local CombatTab = Window:CreateTab("Annihilation", 4483362458)

-- Global State Variables
local isFlying = false
local flySpeed = 50
local isOrbiting = false
local isExecuting = false
local maxOrbitParts = 50
local orbitParts = {}
local orbitData = {}
local selectedTargetName = ""

-- =================================================================
-- FLIGHT ENGINE (Wallhop Logic Adapted)
-- =================================================================

local function GetMoveVector()
    local vec = Vector3.new()
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then vec = vec + Vector3.new(0, 0, -1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then vec = vec + Vector3.new(0, 0, 1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then vec = vec + Vector3.new(-1, 0, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then vec = vec + Vector3.new(1, 0, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vec = vec + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vec = vec + Vector3.new(0, -1, 0) end
    return vec
end

RunService.RenderStepped:Connect(function()
    if not isFlying then return end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
        local hrp = char.HumanoidRootPart
        char.Humanoid.PlatformStand = true
        workspace.Gravity = 0
        local camCFrame = Camera.CFrame
        local moveVec = GetMoveVector()
        local targetVelocity = (camCFrame.RightVector * moveVec.X + camCFrame.LookVector * moveVec.Z + Vector3.new(0, moveVec.Y, 0)) * flySpeed
        hrp.AssemblyLinearVelocity = targetVelocity
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end)

MovementTab:CreateToggle({
    Name = "Enable Flight",
    CurrentValue = false,
    Flag = "FlightToggle",
    Callback = function(Value)
        isFlying = Value
        if not isFlying then
            workspace.Gravity = 196.2
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.PlatformStand = false
            end
        end
    end,
})

MovementTab:CreateSlider({
    Name = "Flight Speed",
    Range = {10, 200},
    Increment = 5,
    Suffix = "Studs/s",
    CurrentValue = 50,
    Flag = "FlightSpeedSlider",
    Callback = function(Value) flySpeed = Value end,
})

-- =================================================================
-- FE DEBRIS SCANNER & SWARM ENGINE
-- =================================================================

local function ScanAndGatherDebris()
    orbitParts = {}
    orbitData = {}
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and obj.Parent ~= char then
            -- 1. SIZE FILTER: Ignore giant parts (Baseplates, huge walls)
            if obj.Size.Magnitude < 25 then
                -- 2. FE OWNERSHIP FILTER: Only grab parts near the player to ensure Network Ownership
                if (obj.Position - hrp.Position).Magnitude <= 100 then
                    table.insert(orbitParts, obj)
                    table.insert(orbitData, {
                        radius = math.random(10, 30),
                        speed = (math.random(3, 8) + math.random()) * (math.random(1, 2) == 1 and 1 or -1),
                        offsetX = math.random() * math.pi * 2,
                        offsetY = math.random() * math.pi * 2,
                        offsetZ = math.random() * math.pi * 2
                    })
                    if #orbitParts >= maxOrbitParts then break end
                end
            end
        end
    end
    
    Rayfield:Notify({
        Title = "Swarm Locked",
        Content = "Secured " .. tostring(#orbitParts) .. " FE-controlled parts.",
        Duration = 3,
        Image = 4483362458
    })
end

OrbitTab:CreateToggle({
    Name = "Enable Debris Swarm",
    CurrentValue = false,
    Flag = "SwarmToggle",
    Callback = function(Value)
        isOrbiting = Value
        if isOrbiting then ScanAndGatherDebris() else orbitParts = {} end
    end,
})

OrbitTab:CreateSlider({
    Name = "Max Swarm Parts",
    Range = {10, 150},
    Increment = 5,
    Suffix = "Parts",
    CurrentValue = 50,
    Flag = "MaxSwarmSlider",
    Callback = function(Value)
        maxOrbitParts = Value
        if isOrbiting then ScanAndGatherDebris() end
    end,
})

RunService.RenderStepped:Connect(function()
    if not isOrbiting or #orbitParts == 0 or isExecuting then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local timeVal = tick()
    
    for i, part in ipairs(orbitParts) do
        if part and part.Parent then
            local data = orbitData[i]
            if data then
                local angle = timeVal * data.speed
                local targetCFrame = CFrame.new(hrp.Position) 
                    * CFrame.Angles(data.offsetX, angle, data.offsetZ) 
                    * CFrame.new(0, 0, -data.radius)
                
                pcall(function()
                    part.CFrame = targetCFrame
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end)
            end
        end
    end
end)

-- =================================================================
-- TARGETING & FE KILL ENGINE
-- =================================================================

local function GetPlayerNames()
    local pList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(pList, p.Name) end
    end
    if #pList == 0 then table.insert(pList, "No Players Found") end
    return pList
end

local targetDropdown = CombatTab:CreateDropdown({
    Name = "Select Strike Target",
    Options = GetPlayerNames(),
    CurrentOption = GetPlayerNames()[1],
    Flag = "TargetDropdown",
    Callback = function(option) selectedTargetName = option end,
})

CombatTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function() targetDropdown:Refresh(GetPlayerNames(), true) end,
})

local function ExecuteFEKill(targetPlayer)
    isExecuting = true
    local targetChar = targetPlayer.Character
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    
    Rayfield:Notify({
        Title = "Executing Target",
        Content = "Bombarding " .. targetPlayer.Name .. " to trigger physics damage!",
        Duration = 3,
        Image = 4483362458
    })

    task.spawn(function()
        local startTime = tick()
        -- FE Kill Logic: Constantly teleport parts into the player with massive downward velocity for 1.5 seconds.
        -- This forces the server's physics engine to calculate a high-speed collision, dealing lethal damage in NDS.
        while tick() - startTime < 1.5 do
            if not targetHRP or not targetHRP.Parent or targetChar.Humanoid.Health <= 0 then break end
            
            for _, part in ipairs(orbitParts) do
                if part and part.Parent then
                    pcall(function()
                        -- Smash the part directly into their torso
                        part.CFrame = targetHRP.CFrame + Vector3.new(math.random(-1,1), math.random(1,3), math.random(-1,1))
                        part.AssemblyLinearVelocity = Vector3.new(0, -5000, 0) -- Extreme downward force
                        part.AssemblyAngularVelocity = Vector3.new(5000, 5000, 5000)
                    end)
                end
            end
            task.wait() -- Run every frame
        end
        
        orbitParts = {}
        orbitData = {}
        isExecuting = false
        if Window.Flags["SwarmToggle"] then Window.Flags["SwarmToggle"]:Set(false) end
    end)
end

CombatTab:CreateButton({
    Name = "EXECUTE FE SWARM STRIKE",
    Callback = function()
        if isExecuting then return end
        if not isOrbiting or #orbitParts == 0 then
            Rayfield:Notify({ Title = "Error", Content = "Gather a Swarm first!", Duration = 3, Image = 4483362458 })
            return
        end
        local targetPlayer = Players:FindFirstChild(selectedTargetName)
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            return
        end
        ExecuteFEKill(targetPlayer)
    end,
})

Rayfield:Notify({
    Title = "SefScriptsHub Fully Loaded",
    Content = "FE Overlord Engine is active. Stay close to parts to claim Network Ownership.",
    Duration = 5,
    Image = 4483362458
})
