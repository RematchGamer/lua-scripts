local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

local savedPosition = root.Position
local interval = 1
local stay = false

local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()
local window = library:MakeWindow("Stay")

window:addTextBoxF("Interval", function(value)
	local num = tonumber(value)
	if num and num >= 0 then
		interval = num
	end
end)

window:addButton("Save Position", function()
	savedPosition = root.Position
end)

local stayCheckbox = window:addCheckbox("Stay")
stayCheckbox.Checked.Changed:Connect(function()
	stay = stayCheckbox.Checked.Value
end)

task.spawn(function()
	while wait(interval) and stay do
		humanoid:MoveTo(savedPosition)
	end
end)
