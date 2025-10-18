local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do
    task.wait(0.1)
    player = Players.LocalPlayer
end

local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ClickToMove = PlayerModule:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")
local mobs = {} -- names of mobs to track
local checkboxes = {} -- mapping name -> checkbox object

local loopInterval = 0.05
local healthThreshold = 0
local distanceThreshold = 0

local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Selector")

-- Threshold boxes (can be ignored since set to 0)
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

-- Update list of tracked mobs based on checkboxes
local function updateTrackedMobs()
	mobs = {}
	for name, cb in pairs(checkboxes) do
		if cb.Checked.Value then
			table.insert(mobs, name)
		end
	end
end

-- Button to print selected mobs (copy for later)
local copyButton = window:addButton("Copy Selected Mobs", function()
	print("Selected Mobs for PlaceID " .. game.PlaceId .. ":")
	for _, name in ipairs(mobs) do
		print(name)
	end
end)

-- Main loop
local currentTarget
while true do
	task.wait(loopInterval)
	pcall(function()
		local closestObj
		local shortestDist = math.huge

		for _, obj in ipairs(mobsFolder:GetChildren()) do
			if obj:IsA("Model") and obj:FindFirstChild("Entity") then
				local healthValue = obj.Entity:FindFirstChild("Health")
				if healthValue and healthValue.Value > 0 then

					-- Dynamically add checkbox if not already in GUI
					if not checkboxes[obj.Name] then
						local cb = window:addCheckbox(obj.Name)
						checkboxes[obj.Name] = cb
						cb.Checked.Changed:Connect(updateTrackedMobs)
						updateTrackedMobs()
					end

					if #mobs == 0 or table.find(mobs, obj.Name) then
						if obj:FindFirstChild("HumanoidRootPart") then
							local dist = (obj.HumanoidRootPart.Position - rootPart.Position).Magnitude

							-- Choose closest mob as target
							if not currentTarget or (dist < shortestDist and currentTarget ~= obj) then
								shortestDist = dist
								closestObj = obj
							end
						end
					end
				elseif healthValue and healthValue.Value <= 0 then
					-- Destroy dead mobs immediately
					obj:Destroy()
					if currentTarget == obj then
						currentTarget = nil
					end
				end
			end
		end

		if closestObj then
			currentTarget = closestObj
			ClickToMove:MoveTo(closestObj.HumanoidRootPart.Position)
		end
	end)
end
