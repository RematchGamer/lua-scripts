local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ClickToMove = PlayerModule:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")
local mobs = {} -- names of mobs to track
local checkboxes = {} -- mapping name -> checkbox object
local aliveMobs = {} -- table of placeID -> mobName -> true
local loopInterval = 0.05
local healthThreshold = 6333
local distanceThreshold = 50

local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Selector")

-- Health and distance textboxes
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

-- Copy button
window:addButton("Copy mob list", function()
	local str = "{\n"
	for placeID, mobTable in pairs(aliveMobs) do
		str = str .. string.format("\t[%s] = {", tostring(placeID))
		local first = true
		for mobName in pairs(mobTable) do
			if not first then str = str .. ", " end
			str = str .. string.format("'%s'", mobName)
			first = false
		end
		str = str .. "},\n"
	end
	str = str .. "}"
	setclipboard(str)
	print("Mob list copied to clipboard!")
end)

-- Update tracked mobs from checkboxes
local function updateTrackedMobs()
	mobs = {}
	for name, cb in pairs(checkboxes) do
		if cb.Checked.Value then
			table.insert(mobs, name)
		end
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
				-- Destroy physical mob if health is 0
				if healthValue.Value <= 0 then
					obj:Destroy()
					continue
				end

				-- Destroy mob if below thresholds
				if obj:FindFirstChild("HumanoidRootPart") then
					local dist = (obj.HumanoidRootPart.Position - rootPart.Position).Magnitude
					if healthValue.Value < healthThreshold and dist < distanceThreshold then
						obj:Destroy()
						continue
					end
				end

				-- Add checkbox once per mob name
				if not checkboxes[obj.Name] then
					local cb = window:addCheckbox(obj.Name)
					checkboxes[obj.Name] = cb
					cb.Checked.Changed:Connect(updateTrackedMobs)
					updateTrackedMobs()
				end

				-- Track first occurrence of mob name by place ID
				local placeID = game.PlaceId
				if not aliveMobs[placeID] then aliveMobs[placeID] = {} end
				if not aliveMobs[placeID][obj.Name] then
					aliveMobs[placeID][obj.Name] = true
				end

				-- Find closest target
				if #mobs == 0 or table.find(mobs, obj.Name) then
					if obj:FindFirstChild("HumanoidRootPart") then
						local dist = (obj.HumanoidRootPart.Position - rootPart.Position).Magnitude
						if dist < shortestDist then
							shortestDist = dist
							closestObj = obj
						end
					end
				end
			end
		end
	end

	-- Move to closest mob
	if closestObj then
		ClickToMove:MoveTo(closestObj.HumanoidRootPart.Position)
	end
end
