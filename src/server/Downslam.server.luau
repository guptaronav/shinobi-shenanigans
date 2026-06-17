local remote = game.ReplicatedStorage.Remotes.NPCM1
local char = script.Parent
local hum: Humanoid = char:WaitForChild('Humanoid')

while task.wait(.5) do
	--print('m1ing')
	local extra = {}
	if char:GetAttribute('Combo') == 3 then
		hum.Jump = true
		extra.Variant = 'Arieal'
	end
	remote:Fire(char, extra)
end