-- Bedfight Hub v2.1 – Fully Fixed
-- Features: Block Reach, Kill Aura (Silent), Projectile Aimbot, Iron Stealer, Remote Scanner
-- Improvements: Better remote detection, proper error handling, optimized performance

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
Main.Size = UDim2.new(0, 250, 0, 400)
Main.Position = UDim2.new(0.5, -125, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "Bedfight Hub v2.1"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20

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
    local count = 0
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            warn("Remote found: " .. remote:GetFullName())
            count = count + 1
        end
    end
    warn("Total remotes found: " .. count)
    warn("=== End of scan ===")
end)

-- Status label
local statusLabel = Instance.new("TextLabel", Main)
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 305)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- // Core logic
local Char, Hum, Root
local function onChar(char)
    Char = char
    Hum = char:WaitForChild("Humanoid")
    Root = char:WaitForChild("HumanoidRootPart")
    statusLabel.Text = "Status: Character loaded"
end
if Player.Character then onChar(Player.Character) end
Player.CharacterAdded:Connect(onChar)

-- Improved remote finder with caching
local remoteCache = {}
local function findRemote(parent, patterns)
    local parentPath = parent:GetFullName()
    if remoteCache[parentPath] then
        return remoteCache[parentPath]
    end
    
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local nameLower = obj.Name:lower()
            for _, pat in ipairs(patterns) do
                if nameLower:find(pat:lower()) then
                    remoteCache[parentPath] = obj
                    return obj
                end
            end
        end
    end
    return nil
end

local meleePatterns = {"sword","melee","hit","attack","slash","damage","strike","swing"}
local placePatterns = {"place","build","put","setblock","block","wool","construct"}
local projPatterns = {"shoot","bow","fire","projectile","launch","throw","arrow"}

-- // Kill Aura (Silent) – IMPROVED
local lastSwing = 0
RunService.Heartbeat:Connect(function()
    if not killAuraEnabled or not Char or not Root or not Hum or Hum.Health <= 0 then return end
    if tick() - lastSwing < 0.35 then return end

    local nearest = nil
    local nearestDist = 13
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == Player or plr.Character == nil then continue end
        local c = plr.Character
        local targetHum = c:FindFirstChild("Humanoid")
        local targetRoot = c:FindFirstChild("HumanoidRootPart")
        
        if targetHum and targetHum.Health > 0 and targetRoot then
            local dist = (Root.Position - targetRoot.Position).Magnitude
            if dist <= nearestDist then
                nearestDist = dist
                nearest = c
            end
        end
    end
    
    if not nearest then return end

    -- Find/equip melee tool
    local tool = Char:FindFirstChildOfClass("Tool")
    if not tool then
        tool = nil
        for _, item in ipairs(Player.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                Hum:EquipTool(item)
                tool = item
                wait(0.1)
                break
            end
        end
    end
    if not tool then return end

    local remote = findRemote(tool, meleePatterns)
    if not remote then
        remote = findRemote(ReplicatedStorage, meleePatterns)
    end
    if not remote then return end

    local targetHead = nearest:FindFirstChild("Head")
    if targetHead then
        pcall(function() remote:FireServer(targetHead) end)
        pcall(function() remote:FireServer(nearest) end)
        pcall(function() remote:FireServer(targetHead.Position) end)
    end
    lastSwing = tick()
end)

-- // Projectile Aimbot – IMPROVED
local chargeStart = 0
local charging = false
local bowTool = nil

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not projectileAimbotEnabled or not Char then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local tool = Char:FindFirstChildOfClass("Tool")
        if tool then
            local toolNameLower = tool.Name:lower()
            if toolNameLower:find("bow") or toolNameLower:find("arc") or toolNameLower:find("blaster") then
                bowTool = tool
                chargeStart = tick()
                charging = true
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and charging then
        charging = false
        if not projectileAimbotEnabled or not bowTool or not Root then return end
        
        local chargeTime = math.min(tick() - chargeStart, 3)
        local power = chargeTime / 3

        local targetPos = nil
        local minDist = 75
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == Player or plr.Character == nil then continue end
            local c = plr.Character
            local head = c:FindFirstChild("Head")
            local root = c:FindFirstChild("HumanoidRootPart")
            
            if head and root then
                local predicted = head.Position + (root.Velocity or Vector3.zero) * 0.2
                local dist = (Root.Position - predicted).Magnitude
                if dist < minDist then
                    minDist = dist
                    targetPos = predicted
                end
            end
        end
        
        if not targetPos then return end

        local remote = findRemote(bowTool, projPatterns)
        if not remote then
            remote = findRemote(ReplicatedStorage, projPatterns)
        end
        
        if remote then
            local playerHead = Char:FindFirstChild("Head")
            local shootPos = playerHead and playerHead.Position or Root.Position
            local dir = (targetPos - shootPos).Unit
            
            pcall(function() remote:FireServer(power, dir) end)
            pcall(function() remote:FireServer(dir, power) end)
            pcall(function() remote:FireServer(targetPos, power) end)
            pcall(function() remote:FireServer(power, targetPos) end)
        end
    end
end)

-- // Auto Scaffold – IMPROVED
local lastScaffold = 0
RunService.RenderStepped:Connect(function()
    if not scaffoldEnabled or not Char or not Root or not Hum or Hum.Health <= 0 then return end
    if Hum.MoveDirection.Magnitude < 0.1 then return end
    if tick() - lastScaffold < 0.3 then return end

    local tool = Char:FindFirstChildOfClass("Tool")
    local hasBlockTool = false
    
    if tool then
        local toolNameLower = tool.Name:lower()
        hasBlockTool = toolNameLower:find("wool") or toolNameLower:find("block") or toolNameLower:find("concrete") or toolNameLower:find("platform")
    end
    
    if not hasBlockTool then
        for _, item in ipairs(Player.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                local itemNameLower = item.Name:lower()
                if itemNameLower:find("wool") or itemNameLower:find("block") or itemNameLower:find("concrete") or itemNameLower:find("platform") then
                    Hum:EquipTool(item)
                    tool = item
                    wait(0.1)
                    break
                end
            end
        end
    end
    
    if not tool then return end

    local remote = findRemote(tool, placePatterns)
    if not remote then
        remote = findRemote(ReplicatedStorage, placePatterns)
    end
    if not remote then return end

    local pos = Root.Position
    local blockPos = Vector3.new(math.floor(pos.X) + 0.5, math.floor(pos.Y - 3.5) + 0.5, math.floor(pos.Z) + 0.5)
    
    pcall(function() remote:FireServer(blockPos, tool.Name) end)
    pcall(function() remote:FireServer(blockPos) end)
    pcall(function() remote:FireServer(blockPos, "wool") end)
    lastScaffold = tick()
end)

-- // Block Reach (extended placement) – IMPROVED
local lastPlace = 0
Mouse.Button1Down:Connect(function()
    if blockReachValue <= 10 or not Char or not Root then return end
    
    local tool = Char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local toolNameLower = tool.Name:lower()
    if not (toolNameLower:find("wool") or toolNameLower:find("block") or toolNameLower:find("concrete") or toolNameLower:find("platform")) then return end
    
    if tick() - lastPlace < 0.25 then return end

    local remote = findRemote(tool, placePatterns)
    if not remote then
        remote = findRemote(ReplicatedStorage, placePatterns)
    end
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
        pcall(function() remote:FireServer(blockPos, "block") end)
        lastPlace = tick()
    end
end)

-- // Iron Stealer – IMPROVED
local function getIronVal(plr)
    if not plr or plr.Parent == nil then return nil end
    
    local leaderstats = plr:FindFirstChild("leaderstats")
    if leaderstats then
        for _, v in ipairs(leaderstats:GetChildren()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") then
                local vNameLower = v.Name:lower()
                if vNameLower:find("iron") or vNameLower:find("fe") or vNameLower:find("ore") then
                    return v
                end
            end
        end
    end
    
    local resources = plr:FindFirstChild("Resources")
    if resources then
        for _, v in ipairs(resources:GetChildren()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") then
                local vNameLower = v.Name:lower()
                if vNameLower:find("iron") or vNameLower:find("fe") or vNameLower:find("ore") then
                    return v
                end
            end
        end
    end
    return nil
end

spawn(function()
    while true do
        pcall(function()
            if stealIronEnabled and Player.Character then
                local myIron = getIronVal(Player)
                if myIron then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= Player and plr.Character then
                            local theirIron = getIronVal(plr)
                            if theirIron and theirIron.Value and theirIron.Value > 0 then
                                myIron.Value = myIron.Value + theirIron.Value
                                theirIron.Value = 0
                            end
                        end
                    end
                end
            end
        end)
        wait(0.5)
    end
end)

print("✅ Bedfight Hub v2.1 loaded successfully!")
