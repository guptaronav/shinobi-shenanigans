local remote = game.ReplicatedStorage.Remotes.Command

remote.OnServerEvent:Connect(function(player, cmd)
	if player.Name ~= 'SaviorNoGame' and player.Name ~= 'vMaxI5' then return end
	
	local char = player.Character
	
	if cmd == 'Spawn Dummy' then
		local dummy = game.ReplicatedStorage.Assets.Weakest:Clone()
		dummy.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + char.HumanoidRootPart.CFrame.LookVector * 2.5
		dummy.Parent = workspace.Characters
	elseif cmd == 'Spawn Punching Dummy' then
		local dummy = game.ReplicatedStorage.Assets.Fraud:Clone()
		dummy.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + char.HumanoidRootPart.CFrame.LookVector * 2.5
		dummy.Parent = workspace.Characters
	elseif cmd == 'Reset Cooldowns' then
		for _,v in char.Values.Cooldowns:GetChildren() do
			v:Destroy()
		end
	elseif cmd == 'Fill Ultimate' then
		player.Data.UltimateMeter.Value = 100
	elseif cmd == 'Activate Ultimate' then
		player.Data.UltimateActivated.Value = true
	end
end)