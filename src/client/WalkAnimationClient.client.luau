local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

local AnimationController = require(ReplicatedStorage:WaitForChild("AnimationController"))

local currentAnim = nil

local function playWalk()
	if currentAnim and currentAnim.Animation == "Sneak Walk Animation" then return end
	currentAnim = AnimationController.Play("Sneak Walk Animation", 0.6, true)
end

local function stopWalk()
	if currentAnim then
		currentAnim:Stop()
		currentAnim = nil
	end
end

RunService.Heartbeat:Connect(function()
	if humanoid.MoveDirection.Magnitude > 0.1 and humanoid.FloorMaterial ~= Enum.Material.Air then
		playWalk()
	else
		stopWalk()
	end
end)
