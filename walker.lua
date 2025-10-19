local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ClickToMove = PlayerModule:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")
local loopInterval = 0.1

local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Selector")

local healthThreshold = 0
local distanceThreshold = 1

local healthBox = window:addTextBoxF("Health Threshold", function(val)
	local num = tonumber(val)
	if num then healthThreshold = num end
end)
healthBox.Value = tostring(healthThreshold)

local distanceBox = window:addTextBoxF("Distance Threshold", function(val)
	local num = tonumber(val)
	if num then distanceThreshold = num end
end)
distanceBox.Value = tostring(distanceThreshold)

local uniqueMobNames = {}
local checkboxes = {}
local trackedMobs = {}

local function updateTrackedMobs()
	trackedMobs = {}
	for name, cb in pairs(checkboxes) do
		if cb.Checked.Value then
			table.insert(trackedMobs, name)
		end
	end
end

local function noClip(target)
	if not target or not target:IsA("Model") then return end
	for _, part in ipairs(target:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

local function addMobToGUI(name)
	local cb = window:addCheckbox(name)
	checkboxes[name] = cb
	cb.Checked.Changed:Connect(updateTrackedMobs)
	updateTrackedMobs()
end

local function cleanupWorkspace()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.CanCollide == false and 
           not obj:IsDescendantOf(mobsFolder) and 
           not obj:IsDescendantOf(character) then
            obj:Destroy()
        end
    end
end

local lastPos = rootPart.Position
local shortestDist = math.huge

local function moveToMobTarget(mob)
	if not mob or not mob.Parent then return end
	local hrp = mob:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local targetPos = hrp.Position
	local dist = (rootPart.Position - targetPos).Magnitude

	if dist > distanceThreshold then
		lastPos = targetPos
		shortestDist = dist
		pcall(function()
			ClickToMove:MoveTo(lastPos)
		end)
		cleanupWorkspace()
	end
end

spawn(function()
	local nearestMob

	while task.wait(loopInterval) do
		nearestMob = nil
		shortestDist = math.huge

		for _, mob in ipairs(mobsFolder:GetChildren()) do
			if mob:IsA("Model") and mob:FindFirstChild("Entity") and mob.Entity:FindFirstChild("Health") then
				local hrp = mob:FindFirstChild("HumanoidRootPart")
				if not hrp then continue end

				if not uniqueMobNames[mob.Name] then
					uniqueMobNames[mob.Name] = true
					addMobToGUI(mob.Name)
				end

				if #trackedMobs > 0 and not table.find(trackedMobs, mob.Name) then
					continue
				end

				local health = mob.Entity.Health.Value
				local dist = (hrp.Position - rootPart.Position).Magnitude

				if health == 0 or (health <= healthThreshold and dist <= distanceThreshold) then
					mob:Destroy()
					continue
				end

				if dist + distanceThreshold < shortestDist then
					shortestDist = dist
					if mob ~= nearestMob then
						nearestMob = mob
						noClip(mob)
					end
				end
			end
		end

		moveToMobTarget(nearestMob)
	end
end)
