local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ClickToMove = PlayerModule:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")
local checkboxes = {} -- mapping name -> checkbox object
local mobs = {} -- currently tracked mob names
local foundMobs = {} -- saved { [placeID] = {mobName1, mobName2...} }

local loopInterval = 0.05
local healthThreshold = 0
local distanceThreshold = 0

local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Selector")

-- Add textboxes for health/distance thresholds
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

-- Update mobs list from checkboxes
local function updateTrackedMobs()
	mobs = {}
	for name, cb in pairs(checkboxes) do
		if cb.Checked.Value then
			table.insert(mobs, name)
		end
	end
end

local currentTarget

while true do
	task.wait(loopInterval)

	-- Remove currentTarget if it’s dead or destroyed
	if currentTarget then
		if not currentTarget.Parent or not currentTarget:FindFirstChild("Entity") or currentTarget.Entity.Health.Value <= 0 then
			currentTarget:Destroy()
			currentTarget = nil
		end
	end

	-- Only find a new target if none exists
	if not currentTarget then
		local mobList = {}
		for _, obj in ipairs(mobsFolder:GetChildren()) do
			if obj:IsA("Model") and obj:FindFirstChild("Entity") then
				local healthValue = obj.Entity:FindFirstChild("Health")
				if healthValue and healthValue.Value > 0 and (#mobs == 0 or table.find(mobs, obj.Name)) then
					if not checkboxes[obj.Name] then
						local cb = window:addCheckbox(obj.Name)
						checkboxes[obj.Name] = cb
						cb.Checked.Changed:Connect(updateTrackedMobs)
						updateTrackedMobs()
					end
					if obj:FindFirstChild("HumanoidRootPart") then
						local dist = (obj.HumanoidRootPart.Position - rootPart.Position).Magnitude
						table.insert(mobList, {obj = obj, dist = dist})
					end
				end
			end
		end

		-- Sort mobs by distance
		table.sort(mobList, function(a, b) return a.dist < b.dist end)

		-- Pick the closest valid mob as target
		if #mobList > 0 then
			local target = mobList[1].obj

			-- Skip if health < threshold & distance < threshold (delete immediately)
			local h = target.Entity.Health.Value
			local d = mobList[1].dist
			if h < healthThreshold and d < distanceThreshold then
				target:Destroy()
			else
				currentTarget = target

				-- Save mob name with placeID
				local placeID = game.PlaceId
				if not foundMobs[placeID] then foundMobs[placeID] = {} end
				if not table.find(foundMobs[placeID], target.Name) then
					table.insert(foundMobs[placeID], target.Name)
				end
			end
		end
	end

	-- Move to current target if it exists
	if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
		ClickToMove:MoveTo(currentTarget.HumanoidRootPart.Position)
	end
end
