local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ClickToMove = PlayerModule:GetClickToMoveController()
local mobsFolder = workspace:WaitForChild("Mobs")

local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Selector")

local loopInterval = 0.1
local healthThreshold, distanceThreshold = 0, 1
local checkboxes, trackedMobs = {}, {}

-- UI setup
window:addTextBoxF("Health Threshold", function(v)
	local n = tonumber(v)
	if n then healthThreshold = n end
end).Value = tostring(healthThreshold)

window:addTextBoxF("Distance Threshold", function(v)
	local n = tonumber(v)
	if n then distanceThreshold = n end
end).Value = tostring(distanceThreshold)

-- Tracking
local function updateTracked()
	trackedMobs = {}
	for name, cb in pairs(checkboxes) do
		if cb.Checked.Value then
			trackedMobs[#trackedMobs + 1] = name
		end
	end
end

local function addMobToGUI(name)
	local cb = window:addCheckbox(name)
	checkboxes[name] = cb
	cb.Checked.Changed:Connect(updateTracked)
	updateTracked()
end

-- Utility
local function noClip(model)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CanCollide = false
		end
	end
end

local function safeMoveTo(pos)
	if typeof(pos) ~= "Vector3" then return end
	local ok, err = pcall(function()
		ClickToMove:MoveTo(pos)
	end)
	if not ok then
		warn("MoveTo failed:", err)
	end
end

local function moveToMob(mob)
	local hrp = mob:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if (rootPart.Position - hrp.Position).Magnitude > distanceThreshold then
		safeMoveTo(hrp.Position)
	end
end

-- Main loop
task.spawn(function()
	while task.wait(loopInterval) do
		local nearest, nearestDist = nil, math.huge

		for _, mob in ipairs(mobsFolder:GetChildren()) do
			local entity = mob:FindFirstChild("Entity")
			local hrp = mob:FindFirstChild("HumanoidRootPart")

			if not (mob:IsA("Model") and entity and hrp) then continue end

			local healthObj = entity:FindFirstChild("Health")
			if not healthObj then continue end

			if not checkboxes[mob.Name] then
				addMobToGUI(mob.Name)
			end
			if #trackedMobs > 0 and not table.find(trackedMobs, mob.Name) then
				continue
			end

			local health = healthObj.Value
			if health == 0 then
				mob:Destroy()
				continue
			end

			local dist = (hrp.Position - rootPart.Position).Magnitude
			if dist < nearestDist then
				nearest, nearestDist = mob, dist
			end
		end

		if nearest then
			noClip(nearest)
			moveToMob(nearest)
		end
	end
end)
