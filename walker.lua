local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local module = require(player.PlayerScripts:WaitForChild("PlayerModule"))
local ClickToMove = module:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")

local distanceThreshold = 10
local healthThreshold = 5
local range = 30
local waitInterval = 0.5
local active = false
local deleteMobs = false
local cleanup = false

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

local cleanupBox = window:addCheckbox("Cleanup")
cleanupBox.Checked.Value = false
cleanupBox.Checked.Changed:Connect(function(value)
    cleanup = value
    print("Cleanup changed:", cleanup)
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

local distanceBox = window:addTextBoxF("Distance Threshold", function(val)
    local num = tonumber(val)
    if num then
        distanceThreshold = num
        print("Distance threshold set to:", distanceThreshold)
    end
end)
distanceBox.Value = tostring(distanceThreshold)

local target = nil
local closest = math.huge
local nextTarget = nil
local nextClosest = math.huge
local destination = nil

local function cleanupWorkspace()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and
           obj.CanCollide == false and
           not obj:IsDescendantOf(mobsFolder) and
           not obj:IsDescendantOf(character) and
           obj.Name ~= "HumanoidRootPart" then
            obj:Destroy()
        end
    end
end

local function isValidMob(mob)
    return mob and mob.Parent and mob:IsA("Model") and
           mob:FindFirstChild("HumanoidRootPart") and
           mob:FindFirstChild("Entity") and
           mob.Entity:FindFirstChild("Health")
end

spawn(function()
    while true do
        task.wait(waitInterval)
        if not active then
            target = nil
            nextTarget = nil
            closest = math.huge
            nextClosest = math.huge
            destination = nil
            continue
        end

        -- Reset targets if they are no longer valid
        if target and not isValidMob(target) then
            target = nil
            closest = math.huge
            destination = nil
        end
        if nextTarget and not isValidMob(nextTarget) then
            nextTarget = nil
            nextClosest = math.huge
        end

        -- Find the closest and next closest mobs
        for _, mob in ipairs(mobsFolder:GetChildren()) do
            if isValidMob(mob) then
                local dist = (mob.HumanoidRootPart.Position - rootPart.Position).Magnitude
                local health = mob.Entity.Health.Value

                -- Destroy mob if conditions are met and move to nextTarget immediately
                if deleteMobs and target == mob and health <= healthThreshold and dist <= range then
                    mob:Destroy()
                    target = nil
                    closest = math.huge
                    destination = nil

                    -- Immediately transition to nextTarget if valid
                    if nextTarget and isValidMob(nextTarget) then
                        target = nextTarget
                        closest = nextClosest
                        nextTarget = nil
                        nextClosest = math.huge
                        destination = target.HumanoidRootPart.Position
                        pcall(function()
                            ClickToMove:MoveTo(destination)
                        end)
                    end
                    continue
                end

                -- Update closest and next closest mobs using distanceThreshold
                if dist < closest - distanceThreshold then
                    nextClosest = closest
                    nextTarget = target
                    closest = dist
                    target = mob
                elseif dist < nextClosest - distanceThreshold then
                    nextClosest = dist
                    nextTarget = mob
                end
            end
        end

        -- Move to the current target if valid
        if target and isValidMob(target) then
            local targetPos = target.HumanoidRootPart.Position
            if not destination or (targetPos - destination).Magnitude > range then
                destination = targetPos
                pcall(function()
                    ClickToMove:MoveTo(destination)
                end)
                if cleanup then
                    cleanupWorkspace()
                end
            end
        elseif nextTarget and isValidMob(nextTarget) then
            -- Fallback to nextTarget if no target is set
            target = nextTarget
            closest = nextClosest
            nextTarget = nil
            nextClosest = math.huge
            destination = target.HumanoidRootPart.Position
            pcall(function()
                ClickToMove:MoveTo(destination)
            end)
        else
            -- No valid targets, reset everything
            target = nil
            nextTarget = nil
            closest = math.huge
            nextClosest = math.huge
            destination = nil
        end
    end
end)
