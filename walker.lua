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

local function addMobToGUI(name)
	local cb = window:addCheckbox(name)
	checkboxes[name] = cb
	cb.Checked.Changed:Connect(updateTrackedMobs)
	updateTrackedMobs()
end

spawn(function()
	local nearestMob
	local shortestDist = math.huge
	local lastPos = rootPart.Position
	
	while task.wait(loopInterval) do			
		for _, mob in ipairs(mobsFolder:GetChildren()) do
			if mob:IsA("Model") and mob:FindFirstChild("Entity") and mob.Entity:FindFirstChild("Health") then
				local hrp = mob:FindFirstChild("HumanoidRootPart")
				if not hrp then continue end
				-- Add to unique list if not already added
				if not uniqueMobNames[mob.Name] then
					uniqueMobNames[mob.Name] = true
					addMobToGUI(mob.Name)
				end
				-- Skip mob if it’s not checked
				if #trackedMobs > 0 and not table.find(trackedMobs, mob.Name) then
					continue
				end
				
				local health = mob.Entity.Health.Value
				local dist = (hrp.Position - rootPart.Position).Magnitude
				-- Destroy mob if below thresholds
				if health == 0 or (health <= healthThreshold and dist <= distanceThreshold) then
					if nearestMob == mob then
						nearestMob = nil
						shortestDist = math.huge
					end
					mob:Destroy()
					continue
				end
				-- Track nearest mob
				if dist + distanceThreshold < shortestDist then
				    shortestDist = dist
				    nearestMob = mob
				end
			end
		end

		if nearestMob and nearestMob.Parent and (rootPart.Position-nearestMob.HumanoidRootPart.Position).Magnitude > distanceThreshold then
			lastPos = nearestMob.HumanoidRootPart.Position
			shortestDist = (nearestMob.HumanoidRootPart.Position - rootPart.Position).Magnitude
			ClickToMove:MoveTo(lastPos)
		end
	end
end)
