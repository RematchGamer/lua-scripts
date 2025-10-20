-- basic player / character setup
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- click-to-move
local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ClickToMove = PlayerModule:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")
local loopInterval = 0.1

local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Selector")

local healthThreshold = 0
local distanceThreshold = 0

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
		-- assume the UI puts a BoolValue at cb.Checked
		if cb and cb.Checked and cb.Checked.Value then
			table.insert(trackedMobs, name)
		end
	end
end

local function addMobToGUI(name)
	if checkboxes[name] then return end
	local cb = window:addCheckbox(name)
	checkboxes[name] = cb
	-- assume cb.Checked is a BoolValue with Changed, as in your working version
	cb.Checked.Changed:Connect(updateTrackedMobs)
	updateTrackedMobs()
end

local function noClip(target)
	if not target or not target:IsA("Model") then return end
	for _, part in ipairs(target:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

spawn(function()
	local nearestMob = nil
	local shortestDist = math.huge
	local lastPos = rootPart.Position

	while true do
		task.wait(loopInterval)

		-- recalc per-loop
		nearestMob = nil
		shortestDist = math.huge

		-- cache player pos once per loop
		local playerPos = rootPart.Position

		for _, mob in ipairs(mobsFolder:GetChildren()) do
			if mob:IsA("Model") and mob:FindFirstChild("Entity") and mob.Entity:FindFirstChild("Health") then
				local hrp = mob:FindFirstChild("HumanoidRootPart")
				if not hrp then
					continue
				end

				if not uniqueMobNames[mob.Name] then
					uniqueMobNames[mob.Name] = true
					addMobToGUI(mob.Name)
				end

				if #trackedMobs > 0 and not table.find(trackedMobs, mob.Name) then
					continue
				end

				local health = mob.Entity.Health.Value
				local dist = (hrp.Position - playerPos).Magnitude

				-- destroy if dead or meets thresholds
				if health == 0 or (health <= healthThreshold and dist <= distanceThreshold) then
					mob:Destroy()
					continue
				end

				-- choose nearest (require it to be closer by threshold buffer)
				if dist + distanceThreshold < shortestDist then
					shortestDist = dist
					nearestMob = mob
				end
			end
		end

		-- move once per loop if a valid nearest exists and has moved enough
		if nearestMob and nearestMob.Parent then
			local hrp = nearestMob:FindFirstChild("HumanoidRootPart")
			if hrp then
				local targetPos = hrp.Position
				if (targetPos - lastPos).Magnitude > distanceThreshold then
					-- update lastPos and shortestDist properly (numbers stay numbers)
					lastPos = targetPos
					shortestDist = (targetPos - rootPart.Position).Magnitude
					pcall(function()
						ClickToMove:MoveTo(targetPos)
					end)
				end
			end
		end
	end
end)
