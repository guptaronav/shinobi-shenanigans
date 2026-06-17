local gui = script.Parent
local char = gui.Parent

local frame = gui:WaitForChild('Frame')

local function Update(disabled)
	if disabled then
		frame.BackgroundColor3 = Color3.new(1,0,0)
	else
		frame.BackgroundColor3 = Color3.new(0,1,0)
	end
end

char:WaitForChild('Values'):WaitForChild('Stuns').ChildAdded:Connect(function()
	Update(true)
end)

char.Values.Stuns.ChildRemoved:Connect(function()
	Update(char.Values.Stuns:GetChildren() == 0)
end)