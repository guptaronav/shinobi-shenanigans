--[[
	Place this script in ServerScriptService

	For instructions on how to use, refer to the devforum post:
	https://devforum.roblox.com/t/smooth-r6-ragdoll-for-players-and-npcs-plug-and-play
]]

local PhysicsService = game:GetService("PhysicsService")
local module = require(script.ModuleScript)
local ragParts = script.RagdollParts:GetChildren()
local r6Client = script.R6RagdollClient

PhysicsService:CreateCollisionGroup("Ragdoll")

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		-- Setup ragdoll
		local humanoid = char:WaitForChild("Humanoid")
		local torso = char:WaitForChild("Torso")
		char:WaitForChild("Head").Size = Vector3.new(1, 1, 1)
		humanoid.BreakJointsOnDeath = false
		humanoid.RequiresNeck = false

		local clones = {}
		for _, v in ipairs(ragParts) do
			clones[v.Name] = v:Clone()
		end

		local folder1 = Instance.new("Folder")
		folder1.Name = "RagdollConstraints"
		for _, v in pairs(clones) do
			if v:IsA("Attachment") then
				v.Parent = char:WaitForChild(v:GetAttribute("Parent"))
			elseif v:IsA("BallSocketConstraint") then
				v.Attachment0 = clones[v:GetAttribute("0")]
				v.Attachment1 = clones[v:GetAttribute("1")]
				v.Parent = folder1
			end
		end
		folder1.Parent = char

		local folder2 = Instance.new("Folder")
		folder2.Name = "Motors"
		local value
		for _, v in ipairs(torso:GetChildren()) do
			if v:IsA("Motor6D") then
				value = Instance.new("ObjectValue")
				value.Value = v
				value.Parent = folder2
			end
		end
		folder2.Parent = folder1

		-- Ragdoll trigger
		local trigger = Instance.new("BoolValue")
		trigger.Name = "RagdollTrigger"
		trigger.Parent = char

		trigger.Changed:Connect(function(bool)
			if bool then
				module:Ragdoll(char)
			else
				module:Unragdoll(char)
			end
		end)
		
		r6Client:Clone().Parent = char
	end)
end)
