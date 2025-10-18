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
local healthThreshold = 0
local distanceThreshold = 0

local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Selector")

-- Health and distance textboxes
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
	local closestObj
	local shortestDist = math.huge

	for _, obj in ipairs(mobsFolder:GetChildren()) do
		if obj:IsA("Model") and obj:FindFirstChild("Entity") then
			local healthValue = obj.Entity:FindFirstChild("Health")
			if healthValue and obj:FindFirstChild("HumanoidRootPart") then

				-- Dynamically add to GUI if not added yet
				if not checkboxes[obj.Name] then
					local cb = window:addCheckbox(obj.Name)
					checkboxes[obj.Name] = cb
					cb.Checked.Changed:Connect(updateTrackedMobs)
					updateTrackedMobs()
				end

				if #mobs == 0 or table.find(mobs, obj.Name) then
					local dist = (obj.HumanoidRootPart.Position - rootPart.Position).Magnitude

					-- If no target or closer than current target, set as closest
					if not currentTarget or dist < (currentTarget.HumanoidRootPart.Position - rootPart.Position).Magnitude then
						closestObj = obj
						shortestDist = dist
					end
				end
			end
		end
	end

	-- Switch target if closer found
	if closestObj then
		currentTarget = closestObj
		ClickToMove:MoveTo(currentTarget.HumanoidRootPart.Position)
	end

	-- Destroy dead target
	if currentTarget and (not currentTarget.Parent or (currentTarget.Entity and currentTarget.Entity.Health.Value <= 0)) then
		if currentTarget.Parent then
			currentTarget:Destroy()
		end
		currentTarget = nil
	end
end
