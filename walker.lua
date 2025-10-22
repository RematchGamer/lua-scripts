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
local active = true

-- GUI
local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Follower")

local activeBox = window:addCheckbox("Active")
activeBox.Checked.Value = true
activeBox.Checked.Changed:Connect(function(value)
    active = value
    print("Active changed:", active)
end)

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

local mobListLabels = {}

local function updateMobList(mob)
    local mobName = mob and mob:GetFullName() or "Unknown Mob"
    for _, label in ipairs(mobListLabels) do
        if label.Text == mobName then return end
    end
    --local cb = window:addCheckbox(mob.Name)
    table.insert(mobListLabels, label)
end

local function getPos(obj)
    pcall(function()
            return obj.Position
        end)
end

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

        for _, mob in ipairs(mobsFolder:GetChildren()) do
            if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Entity") and mob.Entity:FindFirstChild("Health") then
                local health = mob.Entity.Health.Value
                local dist = (mob.HumanoidRootPart.Position - rootPart.Position).Magnitude

                if health <= healthThreshold and dist < range then
                    print("Destroying mob:", mob.Name or "Unknown", "Health:", health)
                    mob:Destroy()
                    break
                end

                if not nearest or dist < shortest - distanceThreshold then
                    nearest = mob
                    shortest = dist
                    destination = mob.HumanoidRootPart.Position
                    print("Targeting mob:", mob.Name or "Unknown", "Distance:", shortest)

                    local success = pcall(function()
                        ClickToMove:MoveTo(destination)
                    end)
                    if not success then
                        if not (nearest and nearest.Parent and destination) then
                            print("Failed to MoveTo:", nearest.Name or "Unknown")
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
            
            shortest = (nearest.HumanoidRootPart.Position - rootPart.Position).Magnitude
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
