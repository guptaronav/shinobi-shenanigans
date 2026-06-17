--local leaderboard = workspace:WaitForChild('LeaderboardPart'):WaitForChild('Leaderboard'):WaitForChild('Frame')
local leaderboard = script.Parent:WaitForChild('Frame')
local sections = leaderboard:WaitForChild('Sections')

task.wait(3)

local function Switch(sec)
	for _,v in leaderboard:GetChildren() do
		if v:IsA('ScrollingFrame') then
			v.Visible = false
		end
	end
	
	leaderboard[sec].Visible = true
end

for _,sec in sections:GetChildren() do
	if not sec:IsA('TextButton') then continue end
	sec.Activated:Connect(function()
		Switch(sec.Name)
	end)
end