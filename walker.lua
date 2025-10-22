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
local active = true -- Active by default

-- GUI
local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Follower")

-- Active toggle
local activeBox = window:addCheckbox("Active")
activeBox.Checked.Value = true
activeBox.Checked.Changed:Connect(function(value)
    active = value
    print("Active changed:", active)
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

-- Mob list (merged into main window)
local mobListLabels = {}

local function updateMobList(mob)
    for _, label in ipairs(mobListLabels) do
        if label.Text == mob.Name then return end
    end
    local label = window:addLabel(mob.Name)
    table.insert(mobListLabels, label)
end

-- Mob tracking
local nearest = nil
local shortest = math.huge

spawn(function()
    while true do
        task.wait(waitInterval)
        if not active then
            print("Script inactive, waiting...")
            for _, mob in ipairs(mobsFolder:GetChildren()) do
                if mob:IsA("Model") then
                    updateMobList(mob)
                end
            end
            continue
        end

        player = Players.LocalPlayer
        character = player.Character or player.CharacterAdded:Wait()
        rootPart = character:WaitForChild("HumanoidRootPart")

        local destination = nil

        for _, mob in ipairs(mobsFolder:GetChildren()) do
            if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Entity") and mob.Entity:FindFirstChild("Health") then
                local health = mob.Entity.Health.Value
                local dist = (mob.HumanoidRootPart.Position - rootPart.Position).Magnitude

                if health <= healthThreshold and dist < range then
                    print("Destroying mob:", mob.Name, "Health:", health)
                    mob:Destroy()
                    break
                end

                if not nearest or dist < shortest - distanceThreshold then
                    nearest = mob
                    shortest = dist
                    destination = mob.HumanoidRootPart.Position
                    print("Targeting mob:", nearest.Name, "Distance:", shortest)

                    local success = pcall(function()
                        ClickToMove:MoveTo(destination)
                    end)
                    if not success then
                        if not (nearest and nearest.Parent and destination) then
                            print("Failed to MoveTo:", nearest.Name)
                            nearest = nil
                            shortest = math.huge
                            break
                        end
                    end
                end

                updateMobList(mob)
            end
        end

        if nearest and nearest.Parent and destination then
            shortest = (destination - rootPart.Position).Magnitude
            if shortest > range then 
                print("Adjusting move to:", destination)
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
