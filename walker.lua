local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local module = require(player.PlayerScripts:WaitForChild("PlayerModule"))
local ClickToMove = module:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")

local distanceThreshold = 20
local healthThreshold = 5
local range = 30
local waitInterval = 0.5
local active = false
local deleteMobs = false

local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Follower")

local activeBox = window:addCheckbox("Active")
activeBox.Checked.Value = false
activeBox.Checked.Changed:Connect(function(value)
    active = value
    print("Active changed:", active)
end)

local deleteBox = window:addCheckbox("Delete")
deleteBox.Checked.Value = false
deleteBox.Checked.Changed:Connect(function(value)
    deleteMobs = value
    print("Delete changed:", deleteMobs)
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

local target = nil
local closest = math.huge
local nextTarget = nil
local nextClosest = math.huge
local destination = nil
local nextDes = nil

spawn(function()
    while true do
        task.wait(waitInterval)
        if not active then continue end

        print(mobsFolder:GetChildren())
        for _, mob in ipairs(mobsFolder:GetChildren()) do
            if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Entity") and mob.Entity:FindFirstChild("Health") then
                local dist = (mob.HumanoidRootPart.Position - rootPart.Position).Magnitude
                local health = mob.Entity.Health.Value

                if target and mob == target and nextTarget and nextTarget.Parent and health <= healthThreshold and dist <= range then
                    destination = nextTarget.HumanoidRootPart.Position
                    print("Destroying", target.Name)
                    pcall(function()
                        ClickToMove:MoveTo(destination)
                    end)
                    mob:Destroy()
                    target = nextTarget
                    closest = nextClosest
                    continue
                end

                if not closest or closest == math.huge then
                    print("New target ", mob)
                    closest = dist
                    target = mob
                elseif dist < closest - distanceThreshold then
                    nextClosest = closest
                    nextTarget = target
                    closest = dist
                    target = mob
                end
            end
        end
        print("Target ", mob)
        if target and target.Parent then
            local targetPos = target.HumanoidRootPart.Position
            if not destination or (targetPos - destination).Magnitude > distanceThreshold then
                print("Attemping to move")
                pcall(function()
                    ClickToMove:MoveTo(targetPos)
                end)
                destination = targetPos  
            end
        elseif nextTarget and nextTarget.Parent then
            local targetPos = nextTarget.HumanoidRootPart.Position
            print("Attemping to move next")
            pcall(function()
                ClickToMove:MoveTo(targetPos)
            end)
            destination = targetPos
            target = nextTarget
            closest = nextClosest
        end
    end
end)
