-- Bedfight Hub v2 – by request
-- Features: Block Reach, Kill Aura (Silent), Projectile Aimbot, Iron Stealer, Remote Scanner

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera

-- // GUI Setup
local ScreenGui = Instance.new("ScreenGui", Player.PlayerGui)
ScreenGui.Name = "BedfightHubV2"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 250, 0, 360)
Main.Position = UDim2.new(0.5, -125, 0.5, -180)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

-- Title bar
local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "Bedfight Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20

-- Close button
local Close = Instance.new("TextButton", Main)
Close.Size = UDim2.new(0, 25, 0, 25)
Close.Position = UDim2.new(1, -30, 0, 5)
Close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
Close.Text = "✕"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 14
Close.AutoButtonColor = false
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 6)
Close.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Helper: toggle creation
local function createToggle(y, name, callback)
    local Frame = Instance.new("Frame", Main)
    Frame.Size = UDim2.new(1, -20, 0, 32)
    Frame.Position = UDim2.new(0, 10, 0, y)
    Frame.BackgroundTransparency = 1

    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(0, 130, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Button = Instance.new("TextButton", Frame)
    Button.Size = UDim2.new(0, 42, 0, 22)
    Button.Position = UDim2.new(1, -50, 0.5, -11)
    Button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    Button.Text = ""
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 11)

    local enabled = false
    Button.MouseButton1Click:Connect(function()
        enabled = not enabled
        Button.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(80, 80, 80)
        callback(enabled)
    end)
    return Frame
end

-- Helper: slider creation
local function createSlider(y, name, min, max, default, callback)
    local Label = Instance.new("TextLabel", Main)
    Label.Size = UDim2.new(1, -20, 0, 18)
    Label.Position = UDim2.new(0, 10, 0, y)
    Label.BackgroundTransparency = 1
    Label.Text = name .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local SliderBg = Instance.new("Frame", Main)
    SliderBg.Size = UDim2.new(1, -20, 0, 20)
    SliderBg.Position = UDim2.new(0, 10, 0, y + 22)
    SliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    SliderBg.BorderSizePixel = 0
    Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(0, 4)

    local Fill = Instance.new("Frame", SliderBg)
    Fill.Size = UDim2.new(0, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    Fill.BorderSizePixel = 0
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 4)

    local val = default
    local function set(pct)
        val = math.floor(min + (max - min) * pct)
        Fill.Size = UDim2.new(pct, 0, 1, 0)
        Label.Text = name .. ": " .. val
        callback(val)
    end

    SliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local conn = RunService.RenderStepped:Connect(function()
                local mousePos = UserInputService:GetMouseLocation()
                local pos = SliderBg.AbsolutePosition.X
                local size = SliderBg.AbsoluteSize.X
                local pct = math.clamp((mousePos.X - pos) / size, 0, 1)
                set(pct)
            end)
            local endConn
            endConn = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    conn:Disconnect()
                    endConn:Disconnect()
                end
            end)
        end
    end)
    set((default - min) / (max - min))
    return {Label = Label, Slider = SliderBg}
end

-- // Features state
local scaffoldEnabled = false
local blockReachValue = 15
local killAuraEnabled = false
local projectileAimbotEnabled = false
local stealIronEnabled = false

-- Create UI elements
createToggle(45, "Auto Scaffold", function(e) scaffoldEnabled = e end)
createSlider(85, "Block Reach", 5, 30, 15, function(v) blockReachValue = v end)
createToggle(135, "Kill Aura (Silent)", function(e) killAuraEnabled = e end)
createToggle(175, "Projectile Aimbot", function(e) projectileAimbotEnabled = e end)
createToggle(215, "Steal Iron", function(e) stealIronEnabled = e end)

-- Remote scanner button
local scanBtn = Instance.new("TextButton", Main)
scanBtn.Size = UDim2.new(1, -20, 0, 30)
scanBtn.Position = UDim2.new(0, 10, 0, 265)
scanBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
scanBtn.Text = "🔍 Scan Remotes (open console)"
scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = 13
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 6)
scanBtn.MouseButton1Click:Connect(function()
    warn("=== RemoteEvent Scan ===")
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            warn("Remote found: " .. remote:GetFullName())
        end
    end
    warn("=== End of scan ===")
    -- Also log remotes fired (hook later)
end)

-- // Core logic
local Char, Hum, Root
local function onChar(char)
    Char = char
    Hum = char:WaitForChild("Humanoid")
    Root = char:WaitForChild("HumanoidRootPart")
end
if Player.Character then onChar(Player.Character) end
Player.CharacterAdded:Connect(onChar)

-- Remote finder with multiple patterns
local function findRemote(parent, patterns)
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            for _, pat in ipairs(patterns) do
                if obj.Name:lower():find(pat:lower()) then
                    return obj
                end
            end
        end
    end
    return nil
end

-- Melee remote patterns
local meleePatterns = {"sword","melee","hit","attack","slash","damage","strike"}
-- Block place patterns
local placePatterns = {"place","build","put","setblock","block","wool"}
-- Projectile patterns
local projPatterns = {"shoot","bow","fire","projectile","launch","throw"}

-- // Kill Aura (Silent)
local lastSwing = 0
RunService.Heartbeat:Connect(function()
    if not killAuraEnabled or not Char or not Root or not Hum then return end
    if tick() - lastSwing < 0.3 then return end

    local nearest = nil
    local nearestDist = 12 -- base melee reach
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == Player then continue end
        local c = plr.Character
        if c and c:FindFirstChild("HumanoidRootPart") and c.Humanoid.Health > 0 then
            local dist = (Root.Position - c.HumanoidRootPart.Position).Magnitude
            if dist <= nearestDist and dist < (nearestDist or 999) then
                nearestDist = dist
                nearest = c
            end
        end
    end
    if not nearest then return end

    -- Equip any tool that has a melee remote
    local tool = Char:FindFirstChildOfClass("Tool")
    if not tool or not findRemote(tool, meleePatterns) then
        for _, item in ipairs(Player.Backpack:GetChildren()) do
            if item:IsA("Tool") and findRemote(item, meleePatterns) then
                Hum:EquipTool(item)
                tool = item
                break
            end
        end
    end
    if not tool then return end

    local remote = findRemote(tool, meleePatterns) or findRemote(ReplicatedStorage, meleePatterns)
    if not remote then return end

    local targetPart = nearest.Head or nearest:FindFirstChild("Head")
    if targetPart then
        pcall(function() remote:FireServer(targetPart) end)
        pcall(function() remote:FireServer(nearest) end)
    end
    lastSwing = tick()
end)

-- // Projectile Aimbot
local chargeStart = 0
local charging = false
local bowTool = nil
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and projectileAimbotEnabled then
        local tool = Char and Char:FindFirstChildOfClass("Tool")
        if tool and (tool.Name:lower():find("bow") or tool.Name:lower():find("arc") or findRemote(tool, projPatterns)) then
            bowTool = tool
            chargeStart = tick()
            charging = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and charging then
        charging = false
        if not projectileAimbotEnabled or not bowTool then return end
        local chargeTime = math.min(tick() - chargeStart, 3)
        local power = chargeTime / 3

        local targetPos = nil
        local minDist = 50
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == Player then continue end
            local c = plr.Character
            if c and c:FindFirstChild("Head") then
                local predicted = c.Head.Position + (c.HumanoidRootPart and c.HumanoidRootPart.Velocity or Vector3.zero) * 0.3
                local dist = (Root.Position - predicted).Magnitude
                if dist < minDist then
                    minDist = dist
                    targetPos = predicted
                end
            end
        end
        if not targetPos then return end

        local remote = findRemote(bowTool, projPatterns) or findRemote(ReplicatedStorage, projPatterns)
        if remote then
            local dir = (targetPos - (Char.Head and Char.Head.Position or Root.Position)).Unit
            pcall(function() remote:FireServer(power, dir) end)
            pcall(function() remote:FireServer(dir, power) end)
            pcall(function() remote:FireServer(targetPos) end)
        end
    end
end)

-- // Auto Scaffold
local lastScaffold = 0
RunService.RenderStepped:Connect(function()
    if not scaffoldEnabled or not Char or not Root or not Hum then return end
    if Hum.MoveDirection.Magnitude < 0.1 then return end
    if tick() - lastScaffold < 0.25 then return end

    local tool = Char:FindFirstChildOfClass("Tool")
    if not tool or not (tool.Name:lower():find("wool") or tool.Name:lower():find("block") or tool.Name:lower():find("concrete")) then
        for _, item in ipairs(Player.Backpack:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("wool") or item.Name:lower():find("block") or item.Name:lower():find("concrete")) then
                Hum:EquipTool(item)
                tool = item
                break
            end
        end
    end
    if not tool then return end

    local remote = findRemote(tool, placePatterns) or findRemote(ReplicatedStorage, placePatterns)
    if not remote then return end

    local pos = Root.Position
    local blockPos = Vector3.new(math.floor(pos.X) + 0.5, math.floor(pos.Y - 3) + 0.5, math.floor(pos.Z) + 0.5)
    pcall(function() remote:FireServer(blockPos, "wool") end)
    pcall(function() remote:FireServer(blockPos) end)
    lastScaffold = tick()
end)

-- // Block Reach (extended placement)
local lastPlace = 0
Mouse.Button1Down:Connect(function()
    if blockReachValue <= 10 then return end -- default reach, let game handle
    local tool = Char and Char:FindFirstChildOfClass("Tool")
    if not tool or not (tool.Name:lower():find("wool") or tool.Name:lower():find("block") or tool.Name:lower():find("concrete")) then return end
    if tick() - lastPlace < 0.2 then return end

    local remote = findRemote(tool, placePatterns) or findRemote(ReplicatedStorage, placePatterns)
    if not remote then return end

    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {Char}
    local result = workspace:Raycast(ray.Origin, ray.Direction * blockReachValue, params)
    if result then
        local hitPos = result.Position + result.Normal * 0.5
        local blockPos = Vector3.new(math.floor(hitPos.X) + 0.5, math.floor(hitPos.Y) + 0.5, math.floor(hitPos.Z) + 0.5)
        pcall(function() remote:FireServer(blockPos, tool.Name) end)
        pcall(function() remote:FireServer(blockPos) end)
        lastPlace = tick()
    end
end)

-- // Iron Stealer
local function getIronVal(plr)
    local leaderstats = plr:FindFirstChild("leaderstats")
    if leaderstats then
        for _, v in ipairs(leaderstats:GetChildren()) do
            if v:IsA("IntValue") and (v.Name:lower():find("iron") or v.Name:lower():find("fe")) then
                return v
            end
        end
    end
    -- alternative in Resources
    local resources = plr:FindFirstChild("Resources")
    if resources then
        for _, v in ipairs(resources:GetChildren()) do
            if v:IsA("IntValue") and (v.Name:lower():find("iron") or v.Name:lower():find("fe")) then
                return v
            end
        end
    end
    return nil
end

spawn(function()
    while true do
        if stealIronEnabled and Player.Character then
            local myIron = getIronVal(Player)
            if myIron then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= Player then
                        local theirIron = getIronVal(plr)
                        if theirIron and theirIron.Value > 0 then
                            myIron.Value += theirIron.Value
                            theirIron.Value = 0
                        end
                    end
                end
            end
        end
        wait(0.5)
    end
end)
