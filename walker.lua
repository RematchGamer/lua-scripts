local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ClickToMove = PlayerModule:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")
local ignoreList = {}
local mobs = {} -- will populate from GUI

local loopInterval = 0.05
local healthThreshold = 6000
local distanceThreshold = 10

local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()

-- Create GUI window
local window = library:MakeWindow("Mob Selector")
local checkboxes = {}

-- Get mob names from Profiles for menu only
local profileMobsFolder = ReplicatedStorage:WaitForChild("Profiles"):WaitForChild(player.Name):WaitForChild("Mobs")
local mobNames = {}
for _, mob in ipairs(profileMobsFolder:GetChildren()) do
	table.insert(mobNames, mob.Name)
end

-- Add checkboxes for each mob
for _, name in ipairs(mobNames) do
	local cb = window:addCheckbox(name)
	checkboxes[name] = cb
end

-- Add textboxes for health and distance thresholds
local healthBox = window:addTextBoxF("Health Threshold", function(val)
	local num = tonumber(val)
	if num then
		healthThreshold = num
	end
end)
healthBox.Value = tostring(healthThreshold)

local distanceBox = window:addTextBoxF("Distance Threshold", function(val)
	local num = tonumber(val)
	if num then
		distanceThreshold = num
	end
end)
distanceBox.Value = tostring(distanceThreshold)

-- Function to update tracked mobs from checkboxes
local function updateTrackedMobs()
	mobs = {}
	for name, cb in pairs(checkboxes) do
		if cb.Checked.Value then
			table.insert(mobs, name)
		end
	end
end

-- Listen to checkbox changes
for _, cb in pairs(checkboxes) do
	cb.Checked.Changed:Connect(updateTrackedMobs)
end

updateTrackedMobs()

-- Function to update ignore queue
local function updateIgnoreQueue(mob)
	table.insert(ignoreList, mob)
	if #ignoreList > 3 then
		table.remove(ignoreList, 1)
	end
end

-- Main loop
while true do
	task.wait(loopInterval)

	local closestObj
	local shortestDist = math.huge

	for _, obj in ipairs(mobsFolder:GetChildren()) do
		if obj:IsA("Model") then
			local entityFolder = obj:FindFirstChild("Entity")
			if entityFolder then
				local healthValue = entityFolder:FindFirstChild("Health")
				if healthValue and healthValue.Value > 0 then
					if #mobs == 0 or table.find(mobs, obj.Name) then
						if obj:FindFirstChild("HumanoidRootPart") then
							local dist = (obj.HumanoidRootPart.Position - rootPart.Position).Magnitude

							if healthValue.Value < healthThreshold and dist < distanceThreshold then
								if not table.find(ignoreList, obj) then
									updateIgnoreQueue(obj)
								end
								continue
							end

							if table.find(ignoreList, obj) then
								continue
							end

							if dist < shortestDist then
								shortestDist = dist
								closestObj = obj
							end
						end
					end
				end
			end
		end
	end

	if closestObj then
		ClickToMove:MoveTo(closestObj.HumanoidRootPart.Position)
	end
end
