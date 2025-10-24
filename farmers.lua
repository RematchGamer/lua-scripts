local library = loadstring(game:HttpGet("https://gist.githubusercontent.com/oufguy/62dbf2a4908b3b6a527d5af93e7fca7d/raw/6b2a0ecf0e24bbad7564f7f886c0b8d727843a92/Swordburst%25202%2520KILL%2520AURA%2520GUI(not%2520script)"))()

local window = library:MakeWindow("Farmers")

local active = false
local activeBox = window:addCheckbox("Active")
local targetBox = window:addTextBox("Enter Mob Name")
local yOffsetBox = window:addTextBox("Y Offset (e.g. -20)")
local rangeBox = window:addTextBox("Range (e.g. 10)")

activeBox.Checked.Changed:Connect(function(value)
	active = value
end)

task.spawn(function()
	while task.wait(0.2) do
		if not active then continue end

		local player = game.Players.LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		local targetName = targetBox.Text.Value or "Aeganatos, The Sunken Sovereign"
		if targetName == "" then continue end

		local yOffset = tonumber(yOffsetBox.Text.Value) or -20
		local range = tonumber(rangeBox.Text.Value) or 10

		local mobsFolder = workspace:FindFirstChild("Mobs")
		if not mobsFolder then continue end

		local mob = mobsFolder:FindFirstChild(targetName)
		if mob and mob:FindFirstChild("HumanoidRootPart") then
			local mobPos = mob.HumanoidRootPart.Position
			if (mobPos - root.Position).Magnitude <= range or (mobPos - root.Position).Magnitude <= math.abs(yOffset) then
				root.CFrame = mob.HumanoidRootPart.CFrame + Vector3.new(0, yOffset, 0)
			end
		end
	end
end)
