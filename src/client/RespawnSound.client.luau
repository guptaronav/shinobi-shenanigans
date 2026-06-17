local Players = game:GetService("Players")
local player = Players.LocalPlayer

local playOnNextRespawn = false

local function playSounds()
	-- Woosh
	local woosh = Instance.new("Sound")
	woosh.SoundId = "rbxassetid://18597544476"
	woosh.Volume = .4
	woosh.PlayOnRemove = true
	woosh.Parent = workspace
	woosh:Destroy()
end

local function onCharacterAdded(char)
	if playOnNextRespawn then
		playOnNextRespawn = false
		playSounds()
	end

	local hum = char:WaitForChild("Humanoid", 3)
	if hum then
		hum.Died:Connect(function()
			playOnNextRespawn = true
		end)
	end
end

-- Hook in
if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
