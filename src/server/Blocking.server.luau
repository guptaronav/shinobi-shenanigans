local char = script.Parent

while task.wait(3) do
	game.ReplicatedStorage.Remotes.BlockNPC:Fire(char, true)
end