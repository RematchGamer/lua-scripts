local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ClickToMove = PlayerModule:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")
local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Selector")

local healthThreshold = 6333
local distanceThreshold = 50
local loopInterval = 0.05

local placeId = tostring(game.PlaceId)
local trackedMobs = {} -- { [placeId] = { "mobName1", "mobName2", ... } }
trackedMobs[placeId] = trackedMobs[placeId] or {}

local checkboxes = {}

-- GUI elements
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

local copyButton = window:addButton("Copy mob list", function()
	print("Mob list for place", placeId, ":", table.concat(trackedMobs[placeId], ", "))
	setclipboard(table.concat(trackedMobs[placeId], ", "))
end)

-- Helper: add mob to tracked list only once
local function addMob(name)
	for _, existingName in ipairs(trackedMobs[placeId]) do
		if existingName == name then return end
	end
	table.insert(trackedMobs[placeId], name)
end

-- Add checkbox GUI
local function addCheckboxForMob(name)
	if not checkboxes[name] then
		local cb = window:addCheckbox(name)
		checkboxes[name] = cb
		cb.Checked.Value = true
		addMob(name)
	end
end

-- Main loop
while true do
	task.wait(loopInterval)

	local closestObj
	local shortestDist = math.huge

	for _, obj in ipairs(mobsFolder:GetChildren()) do
		if obj:IsA("Model") and obj:FindFirstChild("Entity") then
			local healthValue = obj.Entity:FindFirstChild("Health")
			if healthValue then
				-- delete mobs with 0 health
				if healthValue.Value <= 0 then
					obj:Destroy()
					if checkboxes[obj.Name] then
						checkboxes[obj.Name].Frame:Destroy()
						checkboxes[obj.Name] = nil
					end
					for i, n in ipairs(trackedMobs[placeId]) do
						if n == obj.Name then table.remove(trackedMobs[placeId], i) break end
					end
					continue
				end

				-- delete mobs below thresholds
				if obj:FindFirstChild("HumanoidRootPart") then
					local dist = (obj.HumanoidRootPart.Position - rootPart.Position).Magnitude
					if healthValue.Value < healthThreshold and dist < distanceThreshold then
						obj:Destroy()
						if checkboxes[obj.Name] then
							checkboxes[obj.Name].Frame:Destroy()
							checkboxes[obj.Name] = nil
						end
						for i, n in ipairs(trackedMobs[placeId]) do
							if n == obj.Name then table.remove(trackedMobs[placeId], i) break end
						end
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

	-- Add new mobs to GUI
	for _, obj in ipairs(mobsFolder:GetChildren()) do
		if obj:IsA("Model") and obj:FindFirstChild("Entity") then
			addCheckboxForMob(obj.Name)
		end
	end

	if closestObj then
		ClickToMove:MoveTo(closestObj.HumanoidRootPart.Position)
	end
end
