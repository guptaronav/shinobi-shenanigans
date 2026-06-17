local char= script.Parent
local hum = char:WaitForChild("Humanoid")

hum.Died:Connect(function()
	task.wait(5)
	local newChar = game.ReplicatedStorage.Assets.Weakest:Clone()
	newChar.Parent = workspace.Characters
	char:Destroy()
end)