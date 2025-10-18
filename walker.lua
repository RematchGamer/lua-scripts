local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ClickToMove = PlayerModule:GetClickToMoveController()

local mobsFolder = workspace:WaitForChild("Mobs")
local mobs = {}
local checkboxes = {}
local loopInterval = 0.05
local healthThreshold = 6333
local distanceThreshold = 50

-- Safe GUI loader
local success, library = pcall(function()
    return loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
end)
if not success or not library then
    warn("GUI library failed, using dummy library")
    library = {
        MakeWindow = function() 
            return {
                addTextBoxF = function(_, f) return {Value="", Changed={Connect=function() end}} end,
                addCheckbox = function(_) return {Checked={Value=false, Changed={Connect=function() end}}, Frame={Destroy=function() end}} end,
                addButton = function() end
            } 
        end
    }
end

local window = library:MakeWindow("Mob Selector")

-- Threshold textboxes
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

-- Update tracked mobs from checkboxes
local function updateTrackedMobs()
	mobs = {}
	for name, cb in pairs(checkboxes) do
		if cb.Checked.Value then
			table.insert(mobs, name)
		end
	end
end

-- Safe clipboard function
local function safeSetClipboard(text)
    if setclipboard then
        pcall(setclipboard, text)
    else
        print("Clipboard unavailable. Copy manually:\n"..text)
    end
end

-- Add button to copy current mob list
window:addButton("Copy Mob List", function()
	local mobNames = {}
	for _, obj in ipairs(mobsFolder:GetChildren()) do
		if obj:IsA("Model") then
			table.insert(mobNames, obj.Name)
		end
	end
	safeSetClipboard(table.concat(mobNames, ", "))
	print("Current mobs: "..table.concat(mobNames, ", "))
end)

-- Main loop
while true do
	task.wait(loopInterval)

	local closestObj
	local shortestDist = math.huge

	-- rebuild tracked mobs set (unique names only)
	local uniqueMobs = {}
	for name, cb in pairs(checkboxes) do
		if cb.Checked.Value and cb.Frame.Parent then
			uniqueMobs[name] = true
		end
	end

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
						continue
					end

					-- track closest mob only if its name hasn't been added yet
					if next(uniqueMobs) == nil or uniqueMobs[obj.Name] then
						if dist < shortestDist then
							shortestDist = dist
							closestObj = obj
							-- mark this name as "already counted"
							uniqueMobs[obj.Name] = nil
						end
					end
				end
			end
		end
	end

	-- update mobs table with remaining unique names
	mobs = {}
	for name, _ in pairs(uniqueMobs) do
		table.insert(mobs, name)
	end

	if closestObj then
		ClickToMove:MoveTo(closestObj.HumanoidRootPart.Position)
	end
end

