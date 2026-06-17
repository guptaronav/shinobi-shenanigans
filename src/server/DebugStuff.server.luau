local enemyNpc = workspace.Characters:WaitForChild('Honored One')
local DamageService = require(game.ServerStorage.RojoStorage.Modules.DamageService)

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		-- Start repeating damage loop
		task.spawn(function()
			while char and char.Parent do
				DamageService.Damage(char, enemyNpc, 1, true, true)
				task.wait(10)
			end
		end)

		-- DeLoPrime debug cash
		if player.Name == "DeLoPrime" then
			local data = player:WaitForChild("Data", 5)
			if data and data:FindFirstChild("Money") then
				data.Money.Value += 1000
				warn("✅ Gave $1000 to DeLoPrime")
			else
				warn("❌ Couldn't find Money in Data for DeLoPrime")
			end
		end
	end)
end)
