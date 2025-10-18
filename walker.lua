local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ClickToMove = PlayerModule:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")

local healthThreshold = 0
local distanceThreshold = 0
local loopInterval = 0.05

local library = loadstring(game:HttpGet(
	"https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"
))()

local window = library:MakeWindow("Mob Selector")

-- User threshold boxes (kept for convenience)
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

-- Store checkbox objects
local checkboxes = {}
local mobs = {} -- list of selected mob names
local placeMobs = {} -- dict of placeID -> mob names
local running = true

-- Update tracked mob list from user selections
local function updateTrackedMobs()
	mobs = {}
	for name, cb in pairs(checkboxes) do
		if cb.Checked.Value then
			table.insert(mobs, name)
		end
	end
end

-- Add copy button (for console output of place+mob names)
local copyButton = window:addButton("Copy Mob List", function()
	local placeID = game.PlaceId
	placeMobs[placeID] = {}
	for _, mobName in ipairs(mobs) do
		table.insert(placeMobs[placeID], mobName)
	end
	print("Mobs for place " .. placeID .. ":")
	for id, mobList in pairs(placeMobs) do
		print("[" .. id .. "] = { " .. table.concat(mobList, ", ") .. " }")
	end
end)

-- Add manual close button
local closeButton = window:addButton("Close Program", function()
	print("Program manually closed by user.")
	running = false
	if window and window.Close then
		window:Close()
	end
end)

-- Safe main loop
task.spawn(function()
	local currentTarget = nil

	while running do
		task.wait(loopInterval)
		local success, err = pcall(function()
			if not character or not rootPart or not ClickToMove then
				error("Player missing components")
			end

			local closestObj
			local shortestDist = math.huge

			-- Detect new mobs and add them to GUI ONCE
			for _, obj in ipairs(mobsFolder:GetChildren()) do
				if obj:IsA("Model") and obj:FindFirstChild("Entity") then
					if not checkboxes[obj.Name] then
						local cb = window:addCheckbox(obj.Name)
						checkboxes[obj.Name] = cb
						cb.Checked.Changed:Connect(updateTrackedMobs)
					end
				end
			end

			updateTrackedMobs()

			-- Keep targeting same mob if still alive
			if currentTarget and currentTarget.Parent and currentTarget:FindFirstChild("Entity") then
				local healthValue = currentTarget.Entity:FindFirstChild("Health")
				if healthValue and healthValue.Value > 0 then
					continue
				else
					currentTarget:Destroy()
					currentTarget = nil
				end
			end

			for _, obj in ipairs(mobsFolder:GetChildren()) do
				if not table.find(mobs, obj.Name) then
					continue
				end
				if obj:IsA("Model") and obj:FindFirstChild("Entity") then
					local entity = obj.Entity
					local healthValue = entity:FindFirstChild("Health")
					local hrp = obj:FindFirstChild("HumanoidRootPart")

					if not healthValue or not hrp then
						obj:Destroy()
						continue
					end

					if healthValue.Value <= 0 then
						obj:Destroy()
						continue
					end

					local dist = (hrp.Position - rootPart.Position).Magnitude
					if dist < shortestDist then
						shortestDist = dist
						closestObj = obj
					end
				end
			end

			if closestObj then
				currentTarget = closestObj
				ClickToMove:MoveTo(closestObj.HumanoidRootPart.Position)
			end
		end)

		if not success then
			warn("Error: " .. tostring(err))
			if window and window.Close then
				window:Close()
			end
			running = false
		end
	end
end)
