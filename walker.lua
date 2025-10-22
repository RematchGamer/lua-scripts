local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local module = require(player.PlayerScripts:WaitForChild("PlayerModule"))
local ClickToMove = module:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")

-- Default parameters
local distanceThreshold = 20
local healthThreshold = 5
local range = 30
local waitInterval = 0.5
local active = false
local deleteMobs = false

-- GUI
local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Follower")

-- Active toggle
local activeBox = window:addCheckbox("Active")
activeBox.Checked.Value = false
activeBox.Checked.Changed:Connect(function(value)
    active = value
    print("Active changed:", active)
end)

-- Delete toggle
local deleteBox = window:addCheckbox("Delete")
deleteBox.Checked.Value = false
deleteBox.Checked.Changed:Connect(function(value)
    deleteMobs = value
    print("Delete changed:", deleteMobs)
end)

-- Adjustable parameters
local rangeBox = window:addTextBoxF("Range", function(val)
    local num = tonumber(val)
    if num then
        range = num
        print("Range set to:", range)
    end
end)
rangeBox.Value = tostring(range)

local healthBox = window:addTextBoxF("Health Threshold", function(val)
    local num = tonumber(val)
    if num then
        healthThreshold = num
        print("Health threshold set to:", healthThreshold)
    end
end)
healthBox.Value = tostring(healthThreshold)

local intervalBox = window:addTextBoxF("Interval", function(val)
    local num = tonumber(val)
    if num then
        waitInterval = num
        print("Interval set to:", waitInterval)
    end
end)
intervalBox.Value = tostring(waitInterval)

local nearest = nil
local shortest = math.huge
local destination = nil
local nextDes = nil

spawn(function()
    while true do
        task.wait(waitInterval)
        if not active then continue end

        player = Players.LocalPlayer
        character = player.Character or player.CharacterAdded:Wait()
        rootPart = character:WaitForChild("HumanoidRootPart")

        for _, mob in ipairs(mobsFolder:GetChildren()) do
            if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Entity") and mob.Entity:FindFirstChild("Health") then
                local health = mob.Entity.Health.Value
                local dist = (mob.HumanoidRootPart.Position - rootPart.Position).Magnitude

                if deleteMobs and health <= healthThreshold and dist < range and nextDes then
                    pcall(function()
                        ClickToMove:MoveTo(nextDes)
                    end)
                    mob:Destroy()
                    nearest = nil
                    shortest = math.huge
                    continue
                end

                if not nearest then
                    destination = mob.HumanoidRootPart.Position
                    pcall(function()
                        ClickToMove:MoveTo(destination)
                    end)
                    nearest = mob
                    shortest = dist
                elseif dist < shortest - distanceThreshold then
                    nextDes = nearest and nearest:FindFirstChild("HumanoidRootPart") and nearest.HumanoidRootPart.Position or nil
                    destination = mob.HumanoidRootPart.Position
                    pcall(function()
                        ClickToMove:MoveTo(destination)
                    end)
                    nearest = mob
                    shortest = dist
                end
            end
        end

        if nearest and nearest.Parent and destination then
            shortest = (nearest.HumanoidRootPart.Position - rootPart.Position).Magnitude
            if shortest > range then
                pcall(function()
                    ClickToMove:MoveTo(destination)
                end)
            end
        else
            nearest = nil
            shortest = math.huge
        end
    end
end)
