-- Kaitun Autofarm Script with Webhook Integration
-- Features:
-- - Full-screen custom UI
-- - Performance tracking (gems/trophies per hour)
-- - Enhanced auto-battle system
-- - Custom deployment logic
-- - Real-time stats monitoring
-- - Discord webhook notifications

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Configuration
local CONFIG = {
    TARGET_POSITION = Vector3.new(-4, 28, 108),
    DEPLOYMENT_SPOT = CFrame.new(34.639644622802734, 15.748180389404297, -145.63433837890625, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    SPIN_SPEED = 60,
    HITBOX_SIZE = Vector3.new(15, 15, 15),
    UNITS = {"Pekka", "Wizard", "Giant", "Archer"},
    TEAM = "Blue",
    MIN_ELIXIR = 7,
    WEBHOOK_URL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE", -- Replace with your webhook URL
    WEBHOOK_INTERVAL = 300 -- Send webhook every 5 minutes (300 seconds)
}

-- State management
local STATE = {
    Running = false,
    SelectedUnit = "Pekka",
    StartStats = {Gems = 0, Trophies = 0},
    CurrentStats = {Gems = 0, Trophies = 0},
    StartTime = 0,
    LastWebhookTime = 0,
    Performance = {
        GemsPerHour = 0,
        TrophiesPerHour = 0,
        BattlesPerHour = 0
    }
}

-- Webhook functions
local function sendWebhook(data)
    if CONFIG.WEBHOOK_URL == "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE" then
        warn("Please set your Discord webhook URL in the CONFIG.WEBHOOK_URL field")
        return
    end
    
    local success, response = pcall(function()
        return HttpService:PostAsync(CONFIG.WEBHOOK_URL, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
    end)
    
    if not success then
        warn("Webhook failed to send: " .. tostring(response))
    end
end

local function createWebhookEmbed(title, description, color)
    local player = Players.LocalPlayer
    local currentTime = os.time()
    local elapsedTime = currentTime - STATE.StartTime
    
    local embed = {
        embeds = {{
            title = title,
            description = description,
            color = color or 3447003, -- Default blue color
            fields = {
                {
                    name = "👤 Player",
                    value = player.Name,
                    inline = true
                },
                {
                    name = "🎯 Selected Troop",
                    value = STATE.SelectedUnit,
                    inline = true
                },
                {
                    name = "💎 Current Gems",
                    value = tostring(STATE.CurrentStats.Gems),
                    inline = true
                },
                {
                    name = "🏆 Current Trophies",
                    value = tostring(STATE.CurrentStats.Trophies),
                    inline = true
                },
                {
                    name = "📈 Gems/Hour",
                    value = tostring(STATE.Performance.GemsPerHour),
                    inline = true
                },
                {
                    name = "📊 Trophies/Hour",
                    value = tostring(STATE.Performance.TrophiesPerHour),
                    inline = true
                },
                {
                    name = "⚔️ Battles/Hour",
                    value = tostring(STATE.Performance.BattlesPerHour),
                    inline = true
                },
                {
                    name = "⏱️ Session Time",
                    value = string.format("%02d:%02d:%02d", 
                        math.floor(elapsedTime / 3600),
                        math.floor((elapsedTime % 3600) / 60),
                        math.floor(elapsedTime % 60)
                    ),
                    inline = true
                },
                {
                    name = "📅 Timestamp",
                    value = os.date("%Y-%m-%d %H:%M:%S"),
                    inline = false
                }
            },
            thumbnail = {
                url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
            },
            footer = {
                text = "Kaitun Autofarm v2.0 • " .. game.PlaceId
            }
        }}
    }
    
    return embed
end

local function sendStartNotification()
    local embed = createWebhookEmbed(
        "🚀 Autofarm Started",
        "Kaitun Autofarm has been activated and is now running!",
        65280 -- Green color
    )
    sendWebhook(embed)
end

local function sendStopNotification()
    local embed = createWebhookEmbed(
        "⏹️ Autofarm Stopped",
        "Kaitun Autofarm has been deactivated.",
        16711680 -- Red color
    )
    sendWebhook(embed)
end

local function sendPeriodicUpdate()
    local embed = createWebhookEmbed(
        "📊 Periodic Stats Update",
        "Here are your current farming statistics:",
        3447003 -- Blue color
    )
    sendWebhook(embed)
end

-- UI Creation
local function createCustomUI()
    local player = Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = "KaitunAutofarmUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Main background frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = gui

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0.05, 0)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, 0, 1, 0)
    titleText.Position = UDim2.new(0, 0, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "KAITUN AUTOFARM v2.0 + WEBHOOK"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextScaled = true
    titleText.Font = Enum.Font.GothamBold
    titleText.Parent = titleBar

    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.05, 0, 1, 0)
    closeButton.Position = UDim2.new(0.95, 0, 0, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleBar

    closeButton.MouseButton1Click:Connect(function()
        if STATE.Running then
            STATE.Running = false
            sendStopNotification()
        end
        gui:Destroy()
    end)

    -- Main content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 0.95, 0)
    contentFrame.Position = UDim2.new(0, 0, 0.05, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    -- Left panel (controls)
    local leftPanel = Instance.new("Frame")
    leftPanel.Name = "LeftPanel"
    leftPanel.Size = UDim2.new(0.3, 0, 1, 0)
    leftPanel.Position = UDim2.new(0, 0, 0, 0)
    leftPanel.BackgroundTransparency = 1
    leftPanel.Parent = contentFrame

    -- Right panel (stats)
    local rightPanel = Instance.new("Frame")
    rightPanel.Name = "RightPanel"
    rightPanel.Size = UDim2.new(0.7, 0, 1, 0)
    rightPanel.Position = UDim2.new(0.3, 0, 0, 0)
    rightPanel.BackgroundTransparency = 1
    rightPanel.Parent = contentFrame

    -- Toggle button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0.9, 0, 0.1, 0)
    toggleButton.Position = UDim2.new(0.05, 0, 0.05, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    toggleButton.Text = "START AUTOFARM"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Parent = leftPanel

    toggleButton.MouseButton1Click:Connect(function()
        STATE.Running = not STATE.Running
        if STATE.Running then
            toggleButton.Text = "STOP AUTOFARM"
            toggleButton.BackgroundColor3 = Color3.fromRGB(80, 50, 50)
            STATE.StartTime = os.time()
            STATE.LastWebhookTime = os.time()
            STATE.StartStats.Gems = player.leaderstats.Gems.Value
            STATE.StartStats.Trophies = player.leaderstats.Trophies.Value
            startAutoBattle()
            sendStartNotification()
        else
            toggleButton.Text = "START AUTOFARM"
            toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
            sendStopNotification()
        end
    end)

    -- Team select button
    local teamButton = Instance.new("TextButton")
    teamButton.Name = "TeamButton"
    teamButton.Size = UDim2.new(0.9, 0, 0.1, 0)
    teamButton.Position = UDim2.new(0.05, 0, 0.2, 0)
    teamButton.BackgroundColor3 = Color3.fromRGB(50, 80, 50)
    teamButton.Text = "JOIN BLUE TEAM"
    teamButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    teamButton.TextScaled = true
    teamButton.Font = Enum.Font.GothamBold
    teamButton.Parent = leftPanel

    teamButton.MouseButton1Click:Connect(function()
        ReplicatedStorage.Team:InvokeServer(CONFIG.TEAM)
    end)

    -- Unit selection dropdown
    local unitSelectionFrame = Instance.new("Frame")
    unitSelectionFrame.Name = "UnitSelectionFrame"
    unitSelectionFrame.Size = UDim2.new(0.9, 0, 0.2, 0)
    unitSelectionFrame.Position = UDim2.new(0.05, 0, 0.35, 0)
    unitSelectionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    unitSelectionFrame.Parent = leftPanel

    local unitSelectionLabel = Instance.new("TextLabel")
    unitSelectionLabel.Name = "UnitSelectionLabel"
    unitSelectionLabel.Size = UDim2.new(1, 0, 0.3, 0)
    unitSelectionLabel.Position = UDim2.new(0, 0, 0, 0)
    unitSelectionLabel.BackgroundTransparency = 1
    unitSelectionLabel.Text = "SELECT UNIT TO DEPLOY:"
    unitSelectionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    unitSelectionLabel.TextScaled = true
    unitSelectionLabel.Font = Enum.Font.Gotham
    unitSelectionLabel.Parent = unitSelectionFrame

    for i, unit in ipairs(CONFIG.UNITS) do
        local unitButton = Instance.new("TextButton")
        unitButton.Name = unit .. "Button"
        unitButton.Size = UDim2.new(1, 0, 0.7/#CONFIG.UNITS, 0)
        unitButton.Position = UDim2.new(0, 0, 0.3 + (i-1)*(0.7/#CONFIG.UNITS), 0)
        unitButton.BackgroundColor3 = unit == STATE.SelectedUnit and Color3.fromRGB(80, 80, 120) or Color3.fromRGB(50, 50, 70)
        unitButton.Text = unit:upper()
        unitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        unitButton.TextScaled = true
        unitButton.Font = Enum.Font.Gotham
        unitButton.Parent = unitSelectionFrame
        
        unitButton.MouseButton1Click:Connect(function()
            STATE.SelectedUnit = unit
            for _, btn in ipairs(unitSelectionFrame:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = btn.Name == unit.."Button" and Color3.fromRGB(80, 80, 120) or Color3.fromRGB(50, 50, 70)
                end
            end
        end)
    end

    -- Webhook settings frame
    local webhookFrame = Instance.new("Frame")
    webhookFrame.Name = "WebhookFrame"
    webhookFrame.Size = UDim2.new(0.9, 0, 0.15, 0)
    webhookFrame.Position = UDim2.new(0.05, 0, 0.6, 0)
    webhookFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    webhookFrame.Parent = leftPanel

    local webhookLabel = Instance.new("TextLabel")
    webhookLabel.Name = "WebhookLabel"
    webhookLabel.Size = UDim2.new(1, 0, 0.4, 0)
    webhookLabel.Position = UDim2.new(0, 0, 0, 0)
    webhookLabel.BackgroundTransparency = 1
    webhookLabel.Text = "WEBHOOK CONTROLS:"
    webhookLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    webhookLabel.TextScaled = true
    webhookLabel.Font = Enum.Font.Gotham
    webhookLabel.Parent = webhookFrame

    local testWebhookButton = Instance.new("TextButton")
    testWebhookButton.Name = "TestWebhookButton"
    testWebhookButton.Size = UDim2.new(1, 0, 0.6, 0)
    testWebhookButton.Position = UDim2.new(0, 0, 0.4, 0)
    testWebhookButton.BackgroundColor3 = Color3.fromRGB(50, 70, 90)
    testWebhookButton.Text = "TEST WEBHOOK"
    testWebhookButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    testWebhookButton.TextScaled = true
    testWebhookButton.Font = Enum.Font.Gotham
    testWebhookButton.Parent = webhookFrame

    testWebhookButton.MouseButton1Click:Connect(function()
        sendPeriodicUpdate()
    end)

    -- Stats display
    local statsContainer = Instance.new("Frame")
    statsContainer.Name = "StatsContainer"
    statsContainer.Size = UDim2.new(0.95, 0, 0.9, 0)
    statsContainer.Position = UDim2.new(0.025, 0, 0.05, 0)
    statsContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    statsContainer.BackgroundTransparency = 0.3
    statsContainer.Parent = rightPanel

    -- Current stats
    local currentStatsLabel = Instance.new("TextLabel")
    currentStatsLabel.Name = "CurrentStatsLabel"
    currentStatsLabel.Size = UDim2.new(1, 0, 0.1, 0)
    currentStatsLabel.Position = UDim2.new(0, 0, 0, 0)
    currentStatsLabel.BackgroundTransparency = 1
    currentStatsLabel.Text = "CURRENT STATS"
    currentStatsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    currentStatsLabel.TextScaled = true
    currentStatsLabel.Font = Enum.Font.GothamBold
    currentStatsLabel.Parent = statsContainer

    local gemsLabel = Instance.new("TextLabel")
    gemsLabel.Name = "GemsLabel"
    gemsLabel.Size = UDim2.new(1, 0, 0.1, 0)
    gemsLabel.Position = UDim2.new(0, 0, 0.1, 0)
    gemsLabel.BackgroundTransparency = 1
    gemsLabel.Text = "GEMS: 0"
    gemsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    gemsLabel.TextScaled = true
    gemsLabel.Font = Enum.Font.Gotham
    gemsLabel.TextXAlignment = Enum.TextXAlignment.Left
    gemsLabel.Parent = statsContainer

    local trophiesLabel = Instance.new("TextLabel")
    trophiesLabel.Name = "TrophiesLabel"
    trophiesLabel.Size = UDim2.new(1, 0, 0.1, 0)
    trophiesLabel.Position = UDim2.new(0, 0, 0.2, 0)
    trophiesLabel.BackgroundTransparency = 1
    trophiesLabel.Text = "TROPHIES: 0"
    trophiesLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    trophiesLabel.TextScaled = true
    trophiesLabel.Font = Enum.Font.Gotham
    trophiesLabel.TextXAlignment = Enum.TextXAlignment.Left
    trophiesLabel.Parent = statsContainer

    -- Performance stats
    local performanceLabel = Instance.new("TextLabel")
    performanceLabel.Name = "PerformanceLabel"
    performanceLabel.Size = UDim2.new(1, 0, 0.1, 0)
    performanceLabel.Position = UDim2.new(0, 0, 0.35, 0)
    performanceLabel.BackgroundTransparency = 1
    performanceLabel.Text = "PERFORMANCE METRICS"
    performanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    performanceLabel.TextScaled = true
    performanceLabel.Font = Enum.Font.GothamBold
    performanceLabel.Parent = statsContainer

    local gemsPerHourLabel = Instance.new("TextLabel")
    gemsPerHourLabel.Name = "GemsPerHourLabel"
    gemsPerHourLabel.Size = UDim2.new(1, 0, 0.1, 0)
    gemsPerHourLabel.Position = UDim2.new(0, 0, 0.45, 0)
    gemsPerHourLabel.BackgroundTransparency = 1
    gemsPerHourLabel.Text = "GEMS/H: 0"
    gemsPerHourLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    gemsPerHourLabel.TextScaled = true
    gemsPerHourLabel.Font = Enum.Font.Gotham
    gemsPerHourLabel.TextXAlignment = Enum.TextXAlignment.Left
    gemsPerHourLabel.Parent = statsContainer

    local trophiesPerHourLabel = Instance.new("TextLabel")
    trophiesPerHourLabel.Name = "TrophiesPerHourLabel"
    trophiesPerHourLabel.Size = UDim2.new(1, 0, 0.1, 0)
    trophiesPerHourLabel.Position = UDim2.new(0, 0, 0.55, 0)
    trophiesPerHourLabel.BackgroundTransparency = 1
    trophiesPerHourLabel.Text = "TROPHIES/H: 0"
    trophiesPerHourLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    trophiesPerHourLabel.TextScaled = true
    trophiesPerHourLabel.Font = Enum.Font.Gotham
    trophiesPerHourLabel.TextXAlignment = Enum.TextXAlignment.Left
    trophiesPerHourLabel.Parent = statsContainer

    local battlesPerHourLabel = Instance.new("TextLabel")
    battlesPerHourLabel.Name = "BattlesPerHourLabel"
    battlesPerHourLabel.Size = UDim2.new(1, 0, 0.1, 0)
    battlesPerHourLabel.Position = UDim2.new(0, 0, 0.65, 0)
    battlesPerHourLabel.BackgroundTransparency = 1
    battlesPerHourLabel.Text = "BATTLES/H: 0"
    battlesPerHourLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    battlesPerHourLabel.TextScaled = true
    battlesPerHourLabel.Font = Enum.Font.Gotham
    battlesPerHourLabel.TextXAlignment = Enum.TextXAlignment.Left
    battlesPerHourLabel.Parent = statsContainer

    -- Session time
    local sessionTimeLabel = Instance.new("TextLabel")
    sessionTimeLabel.Name = "SessionTimeLabel"
    sessionTimeLabel.Size = UDim2.new(1, 0, 0.1, 0)
    sessionTimeLabel.Position = UDim2.new(0, 0, 0.8, 0)
    sessionTimeLabel.BackgroundTransparency = 1
    sessionTimeLabel.Text = "SESSION TIME: 00:00:00"
    sessionTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sessionTimeLabel.TextScaled = true
    sessionTimeLabel.Font = Enum.Font.Gotham
    sessionTimeLabel.Parent = statsContainer

    -- Make the UI draggable
    local dragging = false
    local dragInput, dragStart, startPos

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Update stats continuously
    local function formatTime(seconds)
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        local secs = math.floor(seconds % 60)
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    end

    coroutine.wrap(function()
        while gui.Parent do
            if STATE.Running then
                local currentTime = os.time()
                local elapsedTime = currentTime - STATE.StartTime
                
                -- Update current stats
                STATE.CurrentStats.Gems = player.leaderstats.Gems.Value
                STATE.CurrentStats.Trophies = player.leaderstats.Trophies.Value
                
                -- Calculate performance metrics
                if elapsedTime > 0 then
                    STATE.Performance.GemsPerHour = math.floor((STATE.CurrentStats.Gems - STATE.StartStats.Gems) * 3600 / elapsedTime)
                    STATE.Performance.TrophiesPerHour = math.floor((STATE.CurrentStats.Trophies - STATE.StartStats.Trophies) * 3600 / elapsedTime)
                    -- Estimate battles per hour (assuming ~3 minutes per battle)
                    STATE.Performance.BattlesPerHour = math.floor(elapsedTime / 180 * 3600 / elapsedTime)
                end
                
                -- Send periodic webhook updates
                if currentTime - STATE.LastWebhookTime >= CONFIG.WEBHOOK_INTERVAL then
                    sendPeriodicUpdate()
                    STATE.LastWebhookTime = currentTime
                end
                
                -- Update UI
                gemsLabel.Text = "GEMS: " .. tostring(STATE.CurrentStats.Gems)
                trophiesLabel.Text = "TROPHIES: " .. tostring(STATE.CurrentStats.Trophies)
                gemsPerHourLabel.Text = "GEMS/H: " .. tostring(STATE.Performance.GemsPerHour)
                trophiesPerHourLabel.Text = "TROPHIES/H: " .. tostring(STATE.Performance.TrophiesPerHour)
                battlesPerHourLabel.Text = "BATTLES/H: " .. tostring(STATE.Performance.BattlesPerHour)
                sessionTimeLabel.Text = "SESSION TIME: " .. formatTime(elapsedTime)
            end
            
            task.wait(1)
        end
    end)()

    return gui
end

-- Game functions
local function godModeAttack()
    local character = Players.LocalPlayer.Character
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Equip all tools
    for _, tool in pairs(Players.LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = character
        end
    end
    
    -- Spin for wide coverage
    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(CONFIG.SPIN_SPEED), 0)
    
    -- Activate all tools with enlarged hitboxes
    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            local handle = tool:FindFirstChild("Handle")
            if handle then
                handle.Size = CONFIG.HITBOX_SIZE
                handle.Transparency = 0.5
                handle.CanCollide = false
            end
            
            for _ = 1, 3 do 
                tool:Activate()
                task.wait()
            end
        end
    end
end

local function attackRoutine()
    RunService.Heartbeat:Connect(function()
        if not STATE.Running then return end
        
        -- Ensure we're on the correct team
        if not Players.LocalPlayer.Team or Players.LocalPlayer.Team.Name ~= CONFIG.TEAM then
            ReplicatedStorage.Team:InvokeServer(CONFIG.TEAM)
            return
        end
        
        local character = Players.LocalPlayer.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        
        if not character or not humanoid or not root then return end
        
        -- Teleport to target position if not already there
        if (root.Position - CONFIG.TARGET_POSITION).Magnitude > 5 then
            root.CFrame = CFrame.new(CONFIG.TARGET_POSITION)
        end
        
        -- Perform god mode attack
        godModeAttack()
    end)
end

local function deploymentRoutine()
    while STATE.Running do
        if ReplicatedStorage.Game.ElixirB.Value >= CONFIG.MIN_ELIXIR then
            pcall(function()
                ReplicatedStorage.Deploy:InvokeServer("RequestDeploy", STATE.SelectedUnit)
                task.wait()
                ReplicatedStorage.Deploy:InvokeServer("Deploy", STATE.SelectedUnit, CONFIG.DEPLOYMENT_SPOT)
            end)
        end
        task.wait(0.1)
    end
end

function startAutoBattle()
    -- Join team if not already
    ReplicatedStorage.Team:InvokeServer(CONFIG.TEAM)
    
    -- Start routines
    attackRoutine()
    task.spawn(deploymentRoutine)
end

-- Initialize
createCustomUI()
