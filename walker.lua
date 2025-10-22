local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local module = require(player.PlayerScripts:WaitForChild("PlayerModule"))
local ClickToMove = module:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")

-- Default parameters
local distanceThreshold = 10
local healthThreshold = 5
local range = 30
local waitInterval = 0.5
local active = false

-- GUI
local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Follower")

-- Active toggle
local activeBox = window:addCheckbox("Active")
activeBox.Checked.Changed:Connect(function(value)
    active = value
end)

-- Adjustable parameters
local rangeBox = window:addTextBoxF("Range", function(val)
    local num = tonumber(val)
    if num then range = num end
end)
rangeBox.Value = tostring(range)

local healthBox = window:addTextBoxF("Health Threshold", function(val)
    local num = tonumber(val)
    if num then healthThreshold = num end
end)
healthBox.Value = tostring(healthThreshold)

local intervalBox = window:addTextBoxF("Interval", function(val)
    local num = tonumber(val)
    if num then waitInterval = num end
end)
intervalBox.Value = tostring(waitInterval)

-- Mob tracking
local nearest = nil
local shortest = math.huge

spawn(function()
    while true do
        task.wait(waitInterval)
        if not active then continue end

        -- Update player and rootPart in case of respawn
        player = Players.LocalPlayer
        character = player.Character or player.CharacterAdded:Wait()
        rootPart = character:WaitForChild("HumanoidRootPart")

        nearest = nil
        shortest = math.huge
        local destination = nil

        for _, mob in ipairs(mobsFolder:GetChildren()) do
            if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Entity") and mob.Entity:FindFirstChild("Health") then
                local health = mob.Entity.Health.Value
                local dist = (mob.HumanoidRootPart.Position - rootPart.Position).Magnitude

                -- Destroy mobs below health threshold within range
                if health <= healthThreshold and dist < range then
                    mob:Destroy()
                    break
                end

                -- Track nearest mob
                if not nearest or dist < shortest - distanceThreshold then
                    nearest = mob
                    shortest = dist
                    destination = mob.HumanoidRootPart.Position

                    local success = pcall(function()
                        ClickToMove:MoveTo(destination)
                    end)
                    if not success then
                        nearest = nil
                        shortest = math.huge
                        break
                    end
                end
            end
        end

        -- Move to nearest if exists
        if nearest and nearest.Parent and destination then
            local distToDest = (destination - rootPart.Position).Magnitude
            if distToDest > range then
                pcall(function()
                    ClickToMove:MoveTo(destination)
                end)
            end
            shortest = (nearest.HumanoidRootPart.Position - rootPart.Position).Magnitude
        else
            nearest = nil
            shortest = math.huge
        end
    end
end)
