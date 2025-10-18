local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ClickToMove = PlayerModule:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")

-- Settings
local loopInterval = 0.1
local healthThreshold = 1000
local distanceThreshold = 50

-- GUI library (replace with your preferred)
local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Selector")

-- Threshold boxes
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

-- Mob list checkboxes
local checkboxes = {}
local uniqueMobNames = {}

local function updateTrackedMobs()
	-- Returns list of names that are checked
	local tracked = {}
	for name, cb in pairs(checkboxes) do
		if cb.Checked.Value then
			table.insert(tracked, name)
		end
	end
	return tracked
end

local function addMobToGUI(name)
	if not checkboxes[name] then
		local cb = window:addCheckbox(name)
		checkboxes[name] = cb
		cb.Checked.Changed:Connect(function()
			-- nothing extra needed, updateTrackedMobs reads fresh each loop
		end)
	end
end

-- Main targeting loop
spawn(function()
	local currentTarget
	while true do
		task.wait(loopInterval)
		local closestMob
		local shortestDist = math.huge

		for _, mob in ipairs(mobsFolder:GetChildren()) do
			if mob:IsA("Model") and mob:FindFirstChild("Entity") and mob.Entity:FindFirstChild("Health") then
				local health = mob.Entity.Health.Value
				if health <= 0 then
					mob:Destroy()
					continue
				end

				-- Add to unique mob list for GUI
				if not uniqueMobNames[mob.Name] then
					uniqueMobNames[mob.Name] = true
					addMobToGUI(mob.Name)
				end

				-- Check if we should target this mob
				local tracked = updateTrackedMobs()
				if #tracked > 0 and not table.find(tracked, mob.Name) then
					continue
				end

				local dist = (mob:FindFirstChild("HumanoidRootPart") and (mob.HumanoidRootPart.Position - rootPart.Position).Magnitude) or math.huge
				if dist < shortestDist then
					shortestDist = dist
					closestMob = mob
				end
			end
		end

		-- Move to the closest target
		if closestMob then
			currentTarget = closestMob
			ClickToMove:MoveTo(closestMob.HumanoidRootPart.Position)

			-- Destroy if below thresholds
			local health = closestMob.Entity.Health.Value
			local dist = (closestMob.HumanoidRootPart.Position - rootPart.Position).Magnitude
			if health <= healthThreshold or dist <= distanceThreshold then
				closestMob:Destroy()
				currentTarget = nil
			end
		end
	end
end)
