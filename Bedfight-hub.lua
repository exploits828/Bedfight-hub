-- Bedfight Hub Script (LocalScript) - Updated with Block Reach & Robust Detection
-- Place in StarterGui or run with your executor.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ========== GUI Setup ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BedfightHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 240, 0, 340)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -170)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Bedfight Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame

-- Helper to create toggles
local function createToggle(parent, name, yPos, callback)
    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(1, -20, 0, 30)
    Toggle.Position = UDim2.new(0, 10, 0, yPos)
    Toggle.BackgroundTransparency = 1
    Toggle.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 140, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Toggle

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 40, 0, 20)
    Button.Position = UDim2.new(1, -50, 0.5, -10)
    Button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    Button.Text = ""
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 10)
    Button.Parent = Toggle

    local enabled = false
    Button.MouseButton1Click:Connect(function()
        enabled = not enabled
        Button.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(80, 80, 80)
        callback(enabled)
    end)

    return Toggle
end

-- Helper to create a slider
local function createSlider(parent, name, yPos, min, max, default, callback)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, yPos)
    Label.BackgroundTransparency = 1
    Label.Text = name .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = parent

    local Slider = Instance.new("Frame")
    Slider.Size = UDim2.new(1, -20, 0, 20)
    Slider.Position = UDim2.new(0, 10, 0, yPos + 25)
    Slider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Slider.BorderSizePixel = 0
    Instance.new("UICorner", Slider).CornerRadius = UDim.new(0, 4)
    Slider.Parent = parent

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(0, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    Fill.BorderSizePixel = 0
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 4)
    Fill.Parent = Slider

    local current = default
    local function setValue(percent)
        current = math.floor(min + percent * (max - min))
        Fill.Size = UDim2.new(percent, 0, 1, 0)
        Label.Text = name .. ": " .. current
        callback(current)
    end

    Slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local connection
            connection = RunService.RenderStepped:Connect(function()
                local mousePos = UserInputService:GetMouseLocation()
                local sliderPos = Slider.AbsolutePosition.X
                local sliderSize = Slider.AbsoluteSize.X
                local percent = math.clamp((mousePos.X - sliderPos) / sliderSize, 0, 1)
                setValue(percent)
            end)
            local endConn
            endConn = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    connection:Disconnect()
                    endConn:Disconnect()
                end
            end)
        end
    end)
    setValue((default - min) / (max - min))
end

-- ========== Feature Toggles & Sliders ==========
local scaffoldEnabled = false
local killAuraEnabled = false
local projectileAimbotEnabled = false
local stealIronEnabled = false
local blockReachValue = 10  -- default

createToggle(MainFrame, "Auto Scaffold", 45, function(state) scaffoldEnabled = state end)

createSlider(MainFrame, "Block Reach", 85, 5, 30, 15, function(val)
    blockReachValue = val
end)

createToggle(MainFrame, "Kill Aura (Silent)", 140, function(state) killAuraEnabled = state end)
createToggle(MainFrame, "Projectile Aimbot", 180, function(state) projectileAimbotEnabled = state end)
createToggle(MainFrame, "Steal Everyone's Iron", 220, function(state) stealIronEnabled = state end)

-- ========== Core Functions ==========
local Character, Humanoid, RootPart
local function onCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
end
onCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
LocalPlayer.CharacterAdded:Connect(onCharacter)

-- Remote finder with multiple patterns
local function findRemote(parent, patterns)
    for _, obj in pairs(parent:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            for _, pattern in ipairs(patterns) do
                if obj.Name:lower():find(pattern:lower()) then
                    return obj
                end
            end
        end
    end
    return nil
end

-- Get tool remote
local function getToolRemote(tool, patterns)
    if not tool then return nil end
    for _, child in ipairs(tool:GetDescendants()) do
        if child:IsA("RemoteEvent") then
            for _, pattern in ipairs(patterns) do
                if child.Name:lower():find(pattern:lower()) then
                    return child
                end
            end
        end
    end
    return findRemote(ReplicatedStorage, patterns)
end

-- ========== Kill Aura (Silent Aim Melee) ==========
local lastAttack = 0
RunService.Heartbeat:Connect(function()
    if not killAuraEnabled or not Character or not RootPart then return end
    if tick() - lastAttack < 0.3 then return end

    local nearest, nearestDist = nil, 25
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local enemyChar = player.Character
        if enemyChar and enemyChar:FindFirstChild("HumanoidRootPart") and enemyChar.Humanoid.Health > 0 then
            local dist = (RootPart.Position - enemyChar.HumanoidRootPart.Position).Magnitude
            if dist <= 12 and dist < nearestDist then  -- melee reach
                nearestDist = dist
                nearest = enemyChar
            end
        end
    end
    if not nearest then return end

    -- Equip sword
    local tool = Character:FindFirstChildOfClass("Tool")
    if not tool or not getToolRemote(tool, {"sword","melee","hit","attack","slash","damage"}) then
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") and getToolRemote(item, {"sword","melee","hit","attack","slash","damage"}) then
                Humanoid:EquipTool(item)
                tool = item
                break
            end
        end
    end
    if not tool then return end

    local remote = getToolRemote(tool, {"sword","melee","hit","attack","slash","damage"})
    if not remote then return end

    local targetPart = nearest.Head or nearest:FindFirstChild("Head")
    if targetPart then
        pcall(function() remote:FireServer(targetPart) end)
        pcall(function() remote:FireServer(nearest) end)
    end
    lastAttack = tick()
end)

-- ========== Projectile Aimbot ==========
local chargeStart = 0
local isCharging = false
local currentBow = nil

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and projectileAimbotEnabled then
        local tool = Character and Character:FindFirstChildOfClass("Tool")
        if tool and (tool.Name:lower():find("bow") or tool.Name:lower():find("arc")) then
            currentBow = tool
            chargeStart = tick()
            isCharging = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and isCharging then
        isCharging = false
        if not projectileAimbotEnabled or not currentBow then return end

        local chargeTime = math.min(tick() - chargeStart, 3.0)
        local power = chargeTime / 3.0

        local targetPos = nil
        local minDist = 50
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local enemyChar = player.Character
            if enemyChar and enemyChar:FindFirstChild("Head") then
                local headPos = enemyChar.Head.Position
                local enemyVel = enemyChar.HumanoidRootPart and enemyChar.HumanoidRootPart.Velocity or Vector3.zero
                local predictedPos = headPos + enemyVel * (chargeTime * 0.3)
                local dist = (RootPart.Position - predictedPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    targetPos = predictedPos
                end
            end
        end
        if not targetPos then return end

        local remote = getToolRemote(currentBow, {"shoot","bow","fire","projectile","launch"})
        if remote then
            local origin = (Character.Head and Character.Head.Position) or RootPart.Position
            local direction = (targetPos - origin).Unit
            pcall(function() remote:FireServer(power, direction) end)
            pcall(function() remote:FireServer(direction, power) end)
            pcall(function() remote:FireServer(targetPos) end)
        end
    end
end)

-- ========== Auto Scaffold ==========
local lastScaffold = 0
RunService.RenderStepped:Connect(function()
    if not scaffoldEnabled or not Character or not RootPart then return end
    local moveDir = Humanoid.MoveDirection
    if moveDir.Magnitude < 0.1 then return end
    if tick() - lastScaffold < 0.25 then return end

    local tool = Character:FindFirstChildOfClass("Tool")
    if not tool or not (tool.Name:lower():find("wool") or tool.Name:lower():find("block") or tool.Name:lower():find("concrete")) then
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("wool") or item.Name:lower():find("block") or item.Name:lower():find("concrete")) then
                Humanoid:EquipTool(item)
                tool = item
                break
            end
        end
    end
    if not tool then return end

    local remote = getToolRemote(tool, {"place","build","put","setblock"})
    if not remote then return end

    local pos = RootPart.Position
    local blockPos = Vector3.new(math.floor(pos.X) + 0.5, math.floor(pos.Y - 3) + 0.5, math.floor(pos.Z) + 0.5)
    pcall(function() remote:FireServer(blockPos, "wool") end)
    pcall(function() remote:FireServer(blockPos) end)
    lastScaffold = tick()
end)

-- ========== Block Reach (extend placement distance) ==========
-- Hook into the tool's remote and modify the placement position to allow further reach
-- We'll intercept the remote arguments when we detect a block placement click.
-- This uses Mouse.Button1Down to capture the target position, then calculate extended reach.
local originalPlaceRemote = nil
local blockTool = nil

local function getBlockTool()
    local tool = Character and Character:FindFirstChildOfClass("Tool")
    if tool and (tool.Name:lower():find("wool") or tool.Name:lower():find("block") or tool.Name:lower():find("concrete")) then
        return tool
    end
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") and (item.Name:lower():find("wool") or item.Name:lower():find("block") or item.Name:lower():find("concrete")) then
            return item
        end
    end
    return nil
end

local function hookBlockReach()
    -- Continuously update the tool and remote
    local newTool = getBlockTool()
    if newTool ~= blockTool then
        blockTool = newTool
        if blockTool then
            originalPlaceRemote = getToolRemote(blockTool, {"place","build","put","setblock"})
        else
            originalPlaceRemote = nil
        end
    end
end

-- Listen for mouse clicks and if we have a block tool, override the placement distance
local function onMouseButton1Down()
    hookBlockReach()
    if not blockReachValue or blockReachValue <= 10 then return end -- skip if default
    if not blockTool or not originalPlaceRemote then return end

    -- Calculate desired placement position based on mouse hit (Raycast)
    local camera = workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {Character}
    local result = workspace:Raycast(ray.Origin, ray.Direction * blockReachValue, raycastParams)
    if result then
        -- result.Instance is the hit part; we need to place the block on the face
        local normal = result.Normal
        local hitPos = result.Position
        -- Adjust to block grid (assuming 1 stud grid)
        local blockPos = Vector3.new(
            math.floor(hitPos.X) + 0.5,
            math.floor(hitPos.Y) + 0.5,
            math.floor(hitPos.Z) + 0.5
        )
        -- Offset by face normal to place on correct side
        blockPos = blockPos + normal * 0.5
        -- Fire remote with extended position
        pcall(function() originalPlaceRemote:FireServer(blockPos, blockTool.Name) end)
        pcall(function() originalPlaceRemote:FireServer(blockPos) end)
    end
end

-- Hook mouse down; we need to avoid interfering with the normal placement if reach is default.
Mouse.Button1Down:Connect(function()
    if blockReachValue > 10 then
        onMouseButton1Down()
    end
end)

-- ========== Steal Everyone's Iron ==========
local function getIronValue(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        for _, child in ipairs(leaderstats:GetChildren()) do
            if child:IsA("IntValue") and (child.Name:lower():find("iron") or child.Name:lower():find("fe")) then
                return child
            end
        end
    end
    local resources = player:FindFirstChild("Resources")
    if resources then
        for _, child in ipairs(resources:GetChildren()) do
            if child:IsA("IntValue") and (child.Name:lower():find("iron") or child.Name:lower():find("fe")) then
                return child
            end
        end
    end
    return nil
end

spawn(function()
    while true do
        if stealIronEnabled and LocalPlayer.Character then
            local myIron = getIronValue(LocalPlayer)
            if myIron then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        local theirIron = getIronValue(player)
                        if theirIron and theirIron.Value > 0 then
                            local stolen = theirIron.Value
                            theirIron.Value = 0
                            myIron.Value = myIron.Value + stolen
                        end
                    end
                end
            end
        end
        wait(0.5)
    end
end)

-- Close button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Position = UDim2.new(1, -25, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 10)
CloseButton.Parent = MainFrame
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)
