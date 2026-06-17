--local remote = game.ReplicatedStorage.Remotes.NPCM1
local CharacterCombat = require(game.ReplicatedStorage.Skills.Dummy.CharacterCombat)

while task.wait(.5) do
	--remote:Fire(script.Parent, {})
	CharacterCombat.BasicAttack.ClientInit(script.Parent)
end