local skillService = require(game.ReplicatedStorage.Shared.Services.SkillService)

local block = script.Parent
while task.wait(.2) do
	skillService.VoxelDestruction(block.CFrame, block.Size, 0, nil, 1000, 1000, nil)
end