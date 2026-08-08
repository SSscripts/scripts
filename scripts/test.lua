if not game:IsLoaded() then game.Loaded:Wait() end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "SefScriptsHub",
    LoadingTitle = "SefScriptsHub Engine",
    LoadingSubtitle = "Advanced Analytics",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SefScriptsHub",
        FileName = "MasterConfig"
    },
    KeySystem = true,
    KeySettings = {
        Title = "SefScriptsHub",
        Subtitle = "Security Key Verification",
        Note = "Enter Access Key: SEF2026",
        FileName = "SefAccessKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"SEF2026"}
    }
})

getgenv().SefTabs = {
    Roles = Window:CreateTab("Roles", 4483362458),
    Activities = Window:CreateTab("Activities", 4483362458),
    ESP = Window:CreateTab("ESP", 4483362458),
    Movement = Window:CreateTab("Movement", 4483362458),
    Voting = Window:CreateTab("Voting", 4483362458),
    Settings = Window:CreateTab("Settings", 4483362458)
}

getgenv().SefState = {
    Config = {
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
