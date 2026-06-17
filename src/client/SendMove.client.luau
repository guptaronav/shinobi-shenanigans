task.wait(2)
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

local uis = game:GetService("UserInputService")
local util = require(game.ReplicatedStorage.Modules:WaitForChild('Utility'))

local infoFolder = game.Players.LocalPlayer:WaitForChild("Information")

local ability = infoFolder:WaitForChild("Technique")

local techData = require(game.ReplicatedStorage.Modules.TechniqueData)
local moveData = techData[ability.Value].Skills

local ts = game:GetService("TweenService")

local activeAlts = {}

local function getMoveName(n, bypassAlt)
	if type(n) ~= 'string' then
		for i,v in pairs(moveData) do
			if v.Order == n and v.Form == char:WaitForChild('Form').Value then
				if not bypassAlt then
					if activeAlts[i] then
						return v.Alts[activeAlts[i]]
					end
				end
				return i
			end
		end	
	else
		for i,v in pairs(moveData) do
			if v.Form == 'Domain Expansion' then
				return i
			end
		end	
	end
end

local function updateMoves()
	script.Parent.Frame.Move1.MoveName.Text = getMoveName(1)
	script.Parent.Frame.Move2.MoveName.Text = getMoveName(2)
	script.Parent.Frame.Move3.MoveName.Text = getMoveName(3)
	script.Parent.Frame.Move4.MoveName.Text = getMoveName(4)
	if char:WaitForChild('Form').Value == 'Ultimate' then
		script.Parent.Frame.MoveUlt.MoveName.Text = getMoveName('G')
		script.Parent.Frame.MoveUlt.Visible = true
	else
		script.Parent.Frame.MoveUlt.Visible = false
	end
end
updateMoves()

char:WaitForChild('Form').Changed:Connect(updateMoves)

local function getMoveSlot(s)
	for i,v in pairs(script.Parent.Frame:GetChildren()) do
		if not v:IsA('TextButton') then continue end
		if v.MoveName.Text == s then
			return v
		end
	end
	for u,o in pairs(activeAlts) do
		if u == s then
			for i,v in pairs(script.Parent.Frame:GetChildren()) do
				if not v:IsA('TextButton') then continue end
				if v.MoveName.Text == techData[player.Information.Technique.Value].Skills[u].Alts[o] then
					return v
				end
			end
		end
	end
end

-- sorry ima test smth
--uis.InputBegan:Connect(function(input,chat)

--	if chat then return end

--	if input.KeyCode == Enum.KeyCode.One then

--		game.ReplicatedStorage.Remotes.Moves:FireServer(script.Parent.Frame.Move1.Text)

--	elseif input.KeyCode == Enum.KeyCode.Two then


--		game.ReplicatedStorage.Remotes.Moves:FireServer(script.Parent.Frame.Move2.Text)

--	elseif input.KeyCode == Enum.KeyCode.Three then


--		game.ReplicatedStorage.Remotes.Moves:FireServer(script.Parent.Frame.Move3.Text)

--	elseif input.KeyCode == Enum.KeyCode.Four then


--		game.ReplicatedStorage.Remotes.Moves:FireServer(script.Parent.Frame.Move4.Text)

--	end

--end)

local techniqueData = require(game.ReplicatedStorage.Modules.TechniqueData)
local idleTime = os.clock()

local Remotes = game.ReplicatedStorage.Remotes

local function routeSkill(name, action)
	if char:FindFirstChild("Move/"..name) then return end
	local fxMod = require(game.ReplicatedStorage.SkillsFX[ability.Value])
	fxMod[name](char, {
		IsCaster = true,
		Skill = name,
		Action = action,
		Alt = techniqueData[player.Information.Technique.Value].Skills[name].Alts[activeAlts[name]]
	})
end

uis.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if not player.Character or not player.Character:FindFirstChild("Humanoid") then return end

	local action = 'None'
	if uis:IsKeyDown(Enum.KeyCode.W) or uis:IsKeyDown(Enum.KeyCode.Up) then
		action = 'Forward'
	end

	-- Mouse 1 / Left click
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Remotes.AttackM1:FireServer({})
		return
	end

	-- Number keys (#)
	if input.KeyCode == Enum.KeyCode.One then
		routeSkill(getMoveName(1, true), action)
		return
	end
	if input.KeyCode == Enum.KeyCode.Two then
		routeSkill(getMoveName(2, true), action)
		return
	end
	if input.KeyCode == Enum.KeyCode.Three then
		routeSkill(getMoveName(3, true), action)
		return
	end
	if input.KeyCode == Enum.KeyCode.Four then
		routeSkill(getMoveName(4, true), action)
		return
	end

	-- R: special
	if input.KeyCode == Enum.KeyCode.R then
		local targetName = getMoveName('R')
		if targetName then
			routeSkill(targetName, action)
		end
		return
	end

	-- F: block
	if input.KeyCode == Enum.KeyCode.F then
		Remotes.Block:FireServer()
		return
	end

	-- Default ultimate key G stays, plus handle Q as alternate loadout/order swap
	if input.KeyCode == Enum.KeyCode.G then
		if char.Form.Value == 'Ultimate' then
			local m = getMoveName('G')
			if m then
				routeSkill(m, action)
			end
		else
			if player.Character.Humanoid.FloorMaterial ~= Enum.Material.Air and os.clock() - idleTime > 0 and player.Information.UltimateMeter.Value >= 100 then
				local ultimateFxMod = require(game.ReplicatedStorage.SkillsFX[ability.Value])
				ultimateFxMod['Ultimate'](game.Players.LocalPlayer.Character, {IsCaster = true, Skill='Ultimate', Action = action})
			end
		end
	end
end)

player.Character.Humanoid:GetPropertyChangedSignal('MoveDirection'):Connect(function()
	idleTime = os.clock()
end)

game.ReplicatedStorage.Remotes.Cooldowns.OnClientEvent:Connect(function(duration,move)
	local slot = getMoveSlot(move).Name
	script.Parent.Frame[slot].Slider.Size = UDim2.new(1,0,1,0)
	script.Parent.Frame[slot].Slider.Visible = true
	ts:Create(script.Parent.Frame[slot].Slider,TweenInfo.new(duration,Enum.EasingStyle.Linear),{Size = UDim2.new(1,0,0,0)}):Play()
	
end)

game.ReplicatedStorage.Remotes.AlternateSkill.OnClientEvent:Connect(function(skill, alt, duration)
	print('alting')
	activeAlts[skill] = alt
	updateMoves()
	if typeof(duration) == 'function' then
		while task.wait() do
			local stop = duration()
			if stop then activeAlts[skill] = nil; updateMoves() end
		end
	elseif typeof(duration) == 'number' then
		task.wait(duration)
		activeAlts[skill] = nil
		updateMoves()
	end
end)