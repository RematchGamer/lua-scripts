local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ClickToMove = PlayerModule:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")
local mobs = {} -- names of mobs to track
local checkboxes = {} -- mapping name -> checkbox object

local loopInterval = 0.05
local healthThreshold = 6333
local distanceThreshold = 50

local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Selector")

-- Threshold textboxes
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

-- Update tracked mobs
local function updateTrackedMobs()
	mobs = {}
	for name, cb in pairs(checkboxes) do
		if cb.Checked.Value then
			table.insert(mobs, name)
		end
	end
end

-- Button to print or copy current mobs
window:addButton("Print Mob List", function()
	local mobNames = {}
	for _, obj in ipairs(mobsFolder:GetChildren()) do
		if obj:IsA("Model") and obj:FindFirstChild("Entity") then
			table.insert(mobNames, obj.Name)
		end
	end
	print("Current mobs:", table.concat(mobNames, ", "))
	setclipboard(table.concat(mobNames, ", ")) -- copies to clipboard
end)

-- Main loop
while true do
	task.wait(loopInterval)

	local closestObj
	local shortestDist = math.huge

	for _, obj in ipairs(mobsFolder:GetChildren()) do
		if obj:IsA("Model") and obj:FindFirstChild("Entity") then
			local healthValue = obj.Entity:FindFirstChild("Health")
			if healthValue then
				local dist = obj:FindFirstChild("HumanoidRootPart") and (obj.HumanoidRootPart.Position - rootPart.Position).Magnitude or math.huge

				-- Delete mobs with 0 health or below thresholds
				if healthValue.Value <= 0 or (healthValue.Value < healthThreshold and dist < distanceThreshold) then
					if checkboxes[obj.Name] then
						checkboxes[obj.Name].Frame:Destroy()
						checkboxes[obj.Name] = nil
					end
					obj:Destroy()
					continue
				end

				-- Add mob checkbox dynamically
				if not checkboxes[obj.Name] then
					local cb = window:addCheckbox(obj.Name)
					checkboxes[obj.Name] = cb
					cb.Checked.Changed:Connect(updateTrackedMobs)
					updateTrackedMobs()
				end

				if #mobs == 0 or table.find(mobs, obj.Name) then
					if dist < shortestDist then
						shortestDist = dist
						closestObj = obj
					end
				end
			end
		end
	end

	if closestObj then
		ClickToMove:MoveTo(closestObj.HumanoidRootPart.Position)
	end
end
