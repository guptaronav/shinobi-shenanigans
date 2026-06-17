local remote = game.ReplicatedStorage.Remotes.NPCM1

while task.wait(1) do
	remote:Fire(script.Parent, {})
end