local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationController = require(ReplicatedStorage:WaitForChild("AnimationController"))

local lastMoveTime = os.clock()
local idleAnim = nil

humanoid.Running:Connect(function(speed)
	lastMoveTime = os.clock()
end)

task.spawn(function()
	while task.wait(0.5) do
		if not character or not character:IsDescendantOf(workspace) then
			character = player.Character or player.CharacterAdded:Wait()
			humanoid = character:WaitForChild("Humanoid")
		end

		if os.clock() - lastMoveTime > 3 and not idleAnim then
			idleAnim = AnimationController.Play("Punching Animation", 0.5, true)
		elseif os.clock() - lastMoveTime <= 0.5 and idleAnim then
			idleAnim:Stop()
			idleAnim = nil
		end
	end
end)
