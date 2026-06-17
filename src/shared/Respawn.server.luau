local char= script.Parent
local hum = char:WaitForChild("Humanoid")

hum.Died:Connect(function()
	task.wait(7)
	local newChar = char:Clone()
	newChar.Parent = workspace.Characters
	char:Destroy()
end)