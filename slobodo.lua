-- Kaitun Autofarm Script v3.0
-- CONFIGURATION (Edit these values as needed)
local TROOP = "Pekka" -- Change this to "Pekka", "Wizard", "Giant", or "Archer"
local DISCORD_WEBHOOK = "" -- Paste your Discord webhook URL here for stats reporting
local REPORT_INTERVAL = 900 -- Report stats every 15 minutes (in seconds)

-- Main script (don't edit below unless you know what you're doing)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- Configuration
local CONFIG = {
    TARGET_POSITION = Vector3.new(-4, 28, 108),
    DEPLOYMENT_SPOT = CFrame.new(34.639644622802734, 15.748180389404297, -145.63433837890625, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    SPIN_SPEED = 60,
    HITBOX_SIZE = Vector3.new(15, 15, 15),
    UNITS = {"Pekka", "Wizard", "Giant", "Archer"},
    TEAM = "Blue",
    MIN_ELIXIR = 7
}

-- State management
local STATE = {
    Running = true, -- Automatically start
    SelectedUnit = TROOP,
    StartStats = {Gems = 0, Trophies = 0},
    CurrentStats = {Gems = 0, Trophies = 0},
    StartTime = os.time(),
    LastReportTime = os.time(),
    Performance = {
        GemsPerHour = 0,
        TrophiesPerHour = 0,
        BattlesPerHour = 0
    }
}

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
    mainFrame.Size = UDim2.new(0.4, 0, 0.5, 0)
    mainFrame.Position = UDim2.new(0.6, 0, 0.25, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = gui

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0.1, 0)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(0.9, 0, 1, 0)
    titleText.Position = UDim2.new(0.05, 0, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "KAITUN AUTOFARM v3.0"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextScaled = true
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.1, 0, 1, 0)
    closeButton.Position = UDim2.new(0.9, 0, 0, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleBar

    closeButton.MouseButton1Click:Connect(function()
        gui:Destroy()
        STATE.Running = false
    end)

    -- Stats display
    local statsContainer = Instance.new("Frame")
    statsContainer.Name = "StatsContainer"
    statsContainer.Size = UDim2.new(0.95, 0, 0.9, 0)
    statsContainer.Position = UDim2.new(0.025, 0, 0.1, 0)
    statsContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    statsContainer.BackgroundTransparency = 0.3
    statsContainer.Parent = mainFrame

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
        while gui.Parent and STATE.Running do
            local currentTime = os.time()
            local elapsedTime = currentTime - STATE.StartTime
            
            -- Update current stats
            STATE.CurrentStats.Gems = player.leaderstats.Gems.Value
            STATE.CurrentStats.Trophies = player.leaderstats.Trophies.Value
            
            -- Calculate performance metrics
            if elapsedTime > 0 then
                STATE.Performance.GemsPerHour = math.floor((STATE.CurrentStats.Gems - STATE.StartStats.Gems) * 3600 / elapsedTime)
                STATE.Performance.TrophiesPerHour = math.floor((STATE.CurrentStats.Trophies - STATE.StartStats.Trophies) * 3600 / elapsedTime)
                STATE.Performance.BattlesPerHour = math.floor(elapsedTime / 180 * 3600 / elapsedTime)
            end
            
            -- Update UI
            gemsLabel.Text = "GEMS: " .. tostring(STATE.CurrentStats.Gems)
            trophiesLabel.Text = "TROPHIES: " .. tostring(STATE.CurrentStats.Trophies)
            gemsPerHourLabel.Text = "GEMS/H: " .. tostring(STATE.Performance.GemsPerHour)
            trophiesPerHourLabel.Text = "TROPHIES/H: " .. tostring(STATE.Performance.TrophiesPerHour)
            battlesPerHourLabel.Text = "BATTLES/H: " .. tostring(STATE.Performance.BattlesPerHour)
            sessionTimeLabel.Text = "SESSION TIME: " .. formatTime(elapsedTime)
            
            -- Send Discord report at intervals
            if DISCORD_WEBHOOK ~= "" and currentTime - STATE.LastReportTime >= REPORT_INTERVAL then
                sendDiscordReport()
                STATE.LastReportTime = currentTime
            end
            
            task.wait(1)
        end
    end)()

    return gui
end

-- Discord reporting function
local function sendDiscordReport()
    if DISCORD_WEBHOOK == "" then return end
    
    local elapsedTime = os.time() - STATE.StartTime
    local formattedTime = string.format("%02d:%02d:%02d", 
        math.floor(elapsedTime / 3600),
        math.floor((elapsedTime % 3600) / 60),
        math.floor(elapsedTime % 60)
    
    local embed = {
        {
            ["title"] = "📊 Kaitun Autofarm Stats Report",
            ["description"] = "Current farming session statistics",
            ["color"] = 10181046, -- Purple color
            ["fields"] = {
                {
                    ["name"] = "⏱ Session Duration",
                    ["value"] = formattedTime,
                    ["inline"] = true
                },
                {
                    ["name"] = "💎 Current Gems",
                    ["value"] = tostring(STATE.CurrentStats.Gems),
                    ["inline"] = true
                },
                {
                    ["name"] = "🏆 Current Trophies",
                    ["value"] = tostring(STATE.CurrentStats.Trophies),
                    ["inline"] = true
                },
                {
                    ["name"] = "⚡ Gems/Hour",
                    ["value"] = tostring(STATE.Performance.GemsPerHour),
                    ["inline"] = true
                },
                {
                    ["name"] = "⚡ Trophies/Hour",
                    ["value"] = tostring(STATE.Performance.TrophiesPerHour),
                    ["inline"] = true
                },
                {
                    ["name"] = "⚡ Battles/Hour",
                    ["value"] = tostring(STATE.Performance.BattlesPerHour),
                    ["inline"] = true
                },
                {
                    ["name"] = "🛡 Selected Troop",
                    ["value"] = STATE.SelectedUnit,
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "Kaitun Autofarm v3.0 | " .. os.date("%Y-%m-%d %H:%M:%S")
            }
        }
    }
    
    local data = {
        ["embeds"] = embed,
        ["username"] = "Kaitun Autofarm",
        ["avatar_url"] = "https://i.imgur.com/J7l1tO7.png"
    }
    
    local success, err = pcall(function()
        HttpService:PostAsync(DISCORD_WEBHOOK, HttpService:JSONEncode(data))
    end)
    
    if not success then
        warn("Failed to send Discord report: " .. tostring(err))
    end
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
    -- Initialize start stats
    STATE.StartStats.Gems = Players.LocalPlayer.leaderstats.Gems.Value
    STATE.StartStats.Trophies = Players.LocalPlayer.leaderstats.Trophies.Value
    
    -- Join team if not already
    ReplicatedStorage.Team:InvokeServer(CONFIG.TEAM)
    
    -- Start routines
    attackRoutine()
    task.spawn(deploymentRoutine)
    
    -- Create UI
    createCustomUI()
    
    -- Initial Discord report
    if DISCORD_WEBHOOK ~= "" then
        sendDiscordReport()
    end
end

-- Automatically start the autofarm
startAutoBattle()