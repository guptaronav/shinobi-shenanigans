--[[
	'Weld' two characters together.
	This is done by welding both characters to an assembly and giving the first player network ownership over both.
	
	A localscript is inserted to playerscripts for all players that join.
	This handles the movement for all welds that are owned by that player.
	
	Advantages:
		* Smooth movement (similar to vehicle assemblies with seats)
		* Server doesn't have to handle updates every frame; clients handle it
	Disadvantages:
		* Weld 'owner' is given full movement control over the target character, so succeptible to exploits
]]
local TAG = "CustomPlayerWeldAssemblyPart"

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local weldModel = script.WeldModel

-- Update collisions enabled/disabled for the character (char that doesn't have network ownership)
local function updateCollisions(char, canCollide)
	if not canCollide then
		-- Disable collisions, and keep track of which we disabled using an attribute, so we can re-enable collisions later
		for _, v in pairs(char:GetDescendants()) do
			if (v:IsA("BasePart") or v:IsA("MeshPart")) and v.CanCollide == true then
				v.CanCollide = false
				v:SetAttribute("WasCanCollideEnabledBeforeWeld", true)
			end
		end
	else
		-- Enable collisions; only for parts that had collisions enabled originally
		for _, v in pairs(char:GetDescendants()) do
			if v:GetAttribute("WasCanCollideEnabledBeforeWeld") then
				v.CanCollide = true
				v:SetAttribute("WasCanCollideEnabledBeforeWeld", nil)
			end
		end
	end
end

-- Insert client force update localscript on join
-- We have to use 'PlayerGui', since the server can't see 'PlayerScripts'
local function insertLocalScript(player)
	local playerGui = player:WaitForChild("PlayerGui", 60)
	if not playerGui then
		return
	end
	-- We have to parent the localscript to a screengui, as otherwise it'll be destroyed
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = script.Name .. "ScreenGui"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	
	local clone = script.WeldPlayersTogetherClientHandler:Clone()
	clone.Parent = screenGui
	
	screenGui.Parent = playerGui
end
Players.PlayerAdded:Connect(insertLocalScript)
for _, v in pairs(Players:GetPlayers()) do
	coroutine.wrap(insertLocalScript)(v)
end

local module = {}
module.CurrentWelds = {
	-- Format: player1 = weldModel, ...
}
module.ConnectionsPerAssembly = {
	-- Format: weldModel = { conn1, conn2, ... }, ...
}

-- Weld 'part' and 'to' using a WeldConstraint
local function weld(part, to)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "PlayerWeldConstraint"
	weld.Part0 = to
	weld.Part1 = part
	weld.Parent = to
end

-- Add weld between two players
-- 'offsetCFrame' is an offset starting from player1's rootpart
-- 'player1' gets network ownership of both characters; 'player2' is the player that initiated the weld
function module.Setup(player1, player2, offsetCFrame)
	local char1, char2 = player1, player2
	player1 = game.Players:GetPlayerFromCharacter(char1)
	player2 = game.Players:GetPlayerFromCharacter(char2) or char2
	local root1, root2 = char1:FindFirstChild("HumanoidRootPart"), char2:FindFirstChild("HumanoidRootPart")
	if not root1 or not root2 then
		return
	end
	local humanoid1, humanoid2 = char1:FindFirstChild("Humanoid"), char2:FindFirstChild("Humanoid")
	if not humanoid1 or not humanoid2 then
		return
	end
	
	-- Disable collisions on the char that is moved around by the assembly forces (prevent collision issues and physics flings)
	updateCollisions(char2, false)
	
	local model = weldModel:Clone()
	
	-- For some reason we can't change the relative cframes when the weldconstraint is enabled, so we briefly disable it here...
	model.BasePart.WeldConstraint.Enabled = false
	
	-- Setup defaults: assembly floats at char1's root position
	model.BasePart.CFrame = root1.CFrame
	model.BasePart.AlignOrientation.CFrame = model.BasePart.CFrame
	model.BasePart.AlignPosition.Position = model.BasePart.Position
	
	-- Set relative cframe of 'BasePart' and 'Part'
	model.Part.CFrame = model.BasePart.CFrame * offsetCFrame
	
	model.BasePart.WeldConstraint.Enabled = true
	
	-- Instantly teleport second character towards dest and weld them to assembly
	char2:SetPrimaryPartCFrame(model.Part.CFrame)
	weld(root2, model.Part)
	
	model.Parent = workspace
	
	-- Set NetworkOwner of assembly to be 'char1'
	if not player1 then
		model.BasePart:SetNetworkOwner(nil)
		model.BasePart:SetAttribute("UserId", -1)
	else	
		model.BasePart:SetNetworkOwner(player1)
		model.BasePart:SetAttribute("UserId", player1.UserId)
	end
	
	-- Set attribute and tag, so 'player1' knows they can control the assembly to their rootpart
	
	CollectionService:AddTag(model.BasePart, TAG)
		
	-- Save assembly so we can cleanup later (save to 'player2' instead of 'player1'!)
	module.CurrentWelds[player2] = model
	
	-- Cleanup if either character dies (humanoid.Died or removed from workspace)
	module.ConnectionsPerAssembly[model] = {}
	table.insert(module.ConnectionsPerAssembly[model], humanoid1:GetPropertyChangedSignal("Health"):Connect(function()
		if not humanoid1 or humanoid1.Health <= 0 then
			module.Cleanup(player2)
		end
	end))
	table.insert(module.ConnectionsPerAssembly[model], humanoid2:GetPropertyChangedSignal("Health"):Connect(function()
		if not humanoid2 or humanoid2.Health <= 0 then
			module.Cleanup(player2)
		end
	end))
	table.insert(module.ConnectionsPerAssembly[model], char1:GetPropertyChangedSignal("Parent"):Connect(function()
		if not char1 or not char1.Parent then
			module.Cleanup(player2)
		end
	end))
	table.insert(module.ConnectionsPerAssembly[model], char2:GetPropertyChangedSignal("Parent"):Connect(function()
		if not char2 or not char2.Parent then
			module.Cleanup(player2)
		end
	end))
	
	return model.BasePart
end

-- Cleanup assembly, and release both players from welds
-- NOTE: Pass 'player2'; NOT the player that has network ownership!
function module.Cleanup(player2)
	if not player2 then
		return
	end
	local char2 = player2:IsA('Model') and player2 or player2.Character
	if char2 then
		-- Re-enable collisions on the char that is moved around by the assembly forces
		updateCollisions(char2, true)
	end
	
	local model = module.CurrentWelds[player2]
	if model then
		-- Cleanup connections for this assembly
		if module.ConnectionsPerAssembly[model] then
			for _, v in pairs(module.ConnectionsPerAssembly[model]) do
				v:Disconnect()
			end
			module.ConnectionsPerAssembly[model] = nil
		end
		-- Cleanup assembly model
		char2.HumanoidRootPart.CFrame = char2.HumanoidRootPart.CFrame
		model:Destroy()
		module.CurrentWelds[player2] = nil
	end
end

function module.UpdateOffset(player2, offsetCFrame)
	if not player2 then
		return
	end
	
	local model = module.CurrentWelds[player2]
	if model then
		model.BasePart.WeldConstraint.Enabled = false
		model.Part.CFrame = model.BasePart.CFrame * offsetCFrame
		model.BasePart.WeldConstraint.Enabled = true
	end
end

return module
