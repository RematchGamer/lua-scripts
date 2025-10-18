local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ClickToMove = PlayerModule:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")
local placeId = game.PlaceId
local foundMobs = {}
local checkboxes = {}
local mobs = {}
local currentTarget = nil

local loopInterval = 0.05
local healthThreshold = 0
local distanceThreshold = 0

local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Mob Selector")

-- Button to copy list of found mobs
local copyButton = window:addButton("Copy Mob List", function()
	local formatted = "MobList = {\n    [" .. placeId .. "] = { "
	for i, mobName in ipairs(foundMobs) do
		formatted = formatted .. string.format("'%s'%s", mobName, i < #foundMobs and ", " or "")
	end
	formatted = formatted .. " }\n}"
	setclipboard(formatted)
	print("Mob list copied to clipboard!")
end)

local success, err = pcall(function()
	while true do
		task.wait(loopInterval)

		if not character or not rootPart then
			character = player.Character or player.CharacterAdded:Wait()
			rootPart = character:WaitForChild("HumanoidRootPart")
		end

		local closestObj
		local shortestDist = math.huge

		for _, obj in ipairs(mobsFolder:GetChildren()) do
			if obj:IsA("Model") and obj:FindFirstChild("Entity") then
				local healthValue = obj.Entity:FindFirstChild("Health")
				if healthValue and obj:FindFirstChild("HumanoidRootPart") then
					if healthValue.Value <= 0 then
						obj:Destroy()
						continue
					end

					if not checkboxes[obj.Name] then
						local cb = window:addCheckbox(obj.Name)
						checkboxes[obj.Name] = cb
						cb.Checked.Changed:Connect(function()
							mobs = {}
							for name, box in pairs(checkboxes) do
								if box.Checked.Value then
									table.insert(mobs, name)
								end
							end
						end)
						table.insert(foundMobs, obj.Name)
					end

					if #mobs == 0 or table.find(mobs, obj.Name) then
						local dist = (obj.HumanoidRootPart.Position - rootPart.Position).Magnitude

						if currentTarget then
							if currentTarget.Parent == nil or currentTarget.Entity.Health.Value <= 0 then
								currentTarget:Destroy()
								currentTarget = nil
							end
						end

						if not currentTarget then
							if dist < shortestDist then
								shortestDist = dist
								closestObj = obj
							end
						else
							local currentDist = (currentTarget.HumanoidRootPart.Position - rootPart.Position).Magnitude
							if dist < currentDist then
								currentTarget = obj
							end
						end
					end
				else
					obj:Destroy()
				end
			end
		end

		if not currentTarget and closestObj then
			currentTarget = closestObj
		end

		if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
			ClickToMove:MoveTo(currentTarget.HumanoidRootPart.Position)
		end
	end
end)

if not success then
	warn("Error occurred, closing window:", err)
	if window and window.Destroy then
		window:Destroy()
	end
end
