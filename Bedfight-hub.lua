-- Bedfight Hub – Deadcell Remake UI
-- Load Deadcell Library
local library = loadstring(game:HttpGet("https://github.com/GhostDuckyy/UI-Libraries/blob/main/DEADCELL%20REMAKE/Modified/source.lua?raw=true"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera

-- Wait for remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local placeBlockRemote = remotes:WaitForChild("PlaceBlock")
local shootProjectileRemote = remotes:WaitForChild("ShootProjectile")
local kitsRemotes = remotes:WaitForChild("KitsRemotes")
-- Melee remotes that might work – you can adjust the list later
local meleeRemoteNames = {"Smash", "Charge", "ChargeDamage", "Leap", "Hack"}

-- Character handling
local Char, Hum, Root
local function onCharacter(char)
    Char = char
    Hum = char:WaitForChild("Humanoid")
    Root = char:WaitForChild("HumanoidRootPart")
end
if Player.Character then onCharacter(Player.Character) end
Player.CharacterAdded:Connect(onCharacter)

-- Feature states
local killAuraEnabled = false
local projectileAimbotEnabled = false
local scaffoldEnabled = false
local blockReachValue = 15
local stealIronEnabled = false

-- ====================== UI ======================
local window = library:new_window({size = Vector2.new(600, 400)})

-- Combat page
local combatPage = window:new_page({name = "Combat"})
local combatSec = combatPage:new_section({name = "Aimbot & Aura", size = "Fill"})

combatSec:new_toggle({
    name = "Kill Aura (Silent)",
    flag = "killaura",
    callback = function(state)
        killAuraEnabled = state
    end
})

combatSec:new_toggle({
    name = "Projectile Aimbot",
    flag = "projaim",
    callback = function(state)
        projectileAimbotEnabled = state
    end
})

-- Building page
local buildPage = window:new_page({name = "Building"})
local buildSec = buildPage:new_section({name = "Scaffold & Reach", size = "Fill"})

buildSec:new_toggle({
    name = "Auto Scaffold",
    flag = "scaffold",
    callback = function(state)
        scaffoldEnabled = state
    end
})

buildSec:new_slider({
    name = "Block Reach",
    flag = "blockreach",
    min = 5,
    max = 30,
    default = 15,
    float = 0,
    callback = function(val)
        blockReachValue = val
    end
})

-- Misc page
local miscPage = window:new_page({name = "Misc"})
local miscSec = miscPage:new_section({name = "Iron & Scanner", size = "Fill"})

miscSec:new_toggle({
    name = "Steal Everyone's Iron",
    flag = "stealiron",
    callback = function(state)
        stealIronEnabled = state
    end
})

miscSec:new_button({
    name = "Scan Remotes (Check Console)",
    callback = function()
        warn("=== RemoteEvent Scan ===")
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                warn("Remote found: " .. remote:GetFullName())
            end
        end
        warn("=== End of scan ===")
    end
})

-- ====================== Features ======================

-- Kill Aura
local lastSwing = 0
RunService.Heartbeat:Connect(function()
    if not killAuraEnabled or not Char or not Root or not Hum then return end
    if tick() - lastSwing < 0.3 then return end

    local nearest = nil
    local nearestDist = 12
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == Player then continue end
        local c = plr.Character
        if not c then continue end
        local targetHum = c:FindFirstChild("Humanoid")
        local targetRoot = c:FindFirstChild("HumanoidRootPart")
        if targetHum and targetHum.Health > 0 and targetRoot then
            local dist = (Root.Position - targetRoot.Position).Magnitude
            if dist <= nearestDist and dist < (nearestDist or 999) then
                nearestDist = dist
                nearest = c
            end
        end
    end
    if not nearest then return end

    local targetPart = nearest:FindFirstChild("Head") or nearest:FindFirstChild("HumanoidRootPart")
    if targetPart then
        for _, name in ipairs(meleeRemoteNames) do
            local remote = kitsRemotes:FindFirstChild(name)
            if remote then
                pcall(function() remote:FireServer(targetPart) end)
                pcall(function() remote:FireServer(nearest) end)
                break
            end
        end
    end
    lastSwing = tick()
end)

-- Projectile Aimbot
local chargeStart = 0
local charging = false
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and projectileAimbotEnabled then
        local tool = Char and Char:FindFirstChildOfClass("Tool")
        if tool and (tool.Name:lower():find("bow") or tool.Name:lower():find("arc")) then
            chargeStart = tick()
            charging = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and charging then
        charging = false
        if not projectileAimbotEnabled then return end
        local chargeTime = math.min(tick() - chargeStart, 3)
        local power = chargeTime / 3

        local targetPos = nil
        local minDist = 50
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == Player then continue end
            local c = plr.Character
            if not c then continue end
            local head = c:FindFirstChild("Head")
            local root = c:FindFirstChild("HumanoidRootPart")
            if head then
                local predicted = head.Position + (root and root.Velocity or Vector3.zero) * 0.3
                local dist = (Root.Position - predicted).Magnitude
                if dist < minDist then
                    minDist = dist
                    targetPos = predicted
                end
            end
        end
        if not targetPos then return end

        local dir = (targetPos - (Char:FindFirstChild("Head") and Char.Head.Position or Root.Position)).Unit
        pcall(function() shootProjectileRemote:FireServer(power, dir) end)
        pcall(function() shootProjectileRemote:FireServer(dir, power) end)
    end
end)

-- Auto Scaffold
local lastScaffold = 0
RunService.RenderStepped:Connect(function()
    if not scaffoldEnabled or not Char or not Root or not Hum then return end
    if Hum.MoveDirection.Magnitude < 0.1 then return end
    if tick() - lastScaffold < 0.25 then return end

    local pos = Root.Position
    local blockPos = Vector3.new(math.floor(pos.X) + 0.5, math.floor(pos.Y - 3) + 0.5, math.floor(pos.Z) + 0.5)
    pcall(function() placeBlockRemote:FireServer(blockPos, "wool") end)
    pcall(function() placeBlockRemote:FireServer(blockPos) end)
    lastScaffold = tick()
end)

-- Block Reach
local lastPlace = 0
Mouse.Button1Down:Connect(function()
    if blockReachValue <= 10 then return end
    if not Char then return end
    if tick() - lastPlace < 0.2 then return end

    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {Char}
    local result = workspace:Raycast(ray.Origin, ray.Direction * blockReachValue, params)
    if result then
        local hitPos = result.Position + result.Normal * 0.5
        local blockPos = Vector3.new(math.floor(hitPos.X) + 0.5, math.floor(hitPos.Y) + 0.5, math.floor(hitPos.Z) + 0.5)
        pcall(function() placeBlockRemote:FireServer(blockPos, "wool") end)
        pcall(function() placeBlockRemote:FireServer(blockPos) end)
        lastPlace = tick()
    end
end)

-- Iron Stealer
local function getIronVal(plr)
    local leaderstats = plr:FindFirstChild("leaderstats")
    if leaderstats then
        for _, v in ipairs(leaderstats:GetChildren()) do
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

-- Keybind to close (End key)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.End then
        library:Close()
    end
end)
