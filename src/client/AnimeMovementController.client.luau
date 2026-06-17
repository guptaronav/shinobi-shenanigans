local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationController = require(ReplicatedStorage:WaitForChild("AnimationController"))

local baseController = require(player.PlayerScripts.PlayerModule.ControlModule)
local baseKeyboard = baseController.activeController
local baseMoveVector = baseController.activeMoveVector or Vector3.new()

local state = {
	sprinting = false,
	sliding = false,
	wallJumpCooldown = 0,
	lastJumpTime = 0,
	dashCooldown = 0,
	stamina = 100,
	maxStamina = 100,
	slideTimer = 0,
	coyoteTime = 0,
	wallHit = nil,
}

local ANIMS = {
	Walk = "Sneak Walk Animation",
	Slide = "Sliding Animation",
	DoubleJump = "Double Jump Backflip Animation",
}

local currentAnim = nil
local currentAnimName = nil
local function playAnim(name: string, speed: number?)
	if currentAnim and currentAnimName == name then
		if speed then currentAnim:AdjustSpeed(speed) end
		return currentAnim
	end
	if currentAnim then
		currentAnim:Stop()
	end
	currentAnim = AnimationController.Play(name, speed or 1, true)
	currentAnimName = name
	return currentAnim
end

local function stopAnim()
	if currentAnim then
		currentAnim:Stop()
		currentAnim = nil
		currentAnimName = nil
	end
end

-- Stamina regen
RunService.Heartbeat:Connect(function(dt)
	if state.sliding then
		state.stamina = math.clamp(state.stamina - 40 * dt, 0, state.maxStamina)
	elseif state.sprinting then
		state.stamina = math.clamp(state.stamina - 18 * dt, 0, state.maxStamina)
	else
		state.stamina = math.clamp(state.stamina + 28 * dt, 0, state.maxStamina)
	end

	if state.wallJumpCooldown > 0 then
		state.wallJumpCooldown -= dt
	end
	if state.dashCooldown > 0 then
		state.dashCooldown -= dt
	end
	if state.slideTimer > 0 then
		state.slideTimer -= dt
		if state.slideTimer <= 0 then
			state.sliding = false
			humanoid.CameraOffset = Vector3.new(0, 0, 0)
		end
	end
end)

-- Grounded detection
RunService.Heartbeat:Connect(function(dt)
	local isGrounded = humanoid.FloorMaterial ~= Enum.Material.Air
	if isGrounded then
		state.coyoteTime = 0.15
	else
		state.coyoteTime = math.max(0, state.coyoteTime - dt)
	end
end)

-- Wall-sense
RunService.Heartbeat:Connect(function()
	if not root then return end
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {character}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local forward = root.CFrame.LookVector
	local wallRay = workspace:Raycast(root.Position + Vector3.new(0, 0.5, 0), forward * 2.2, params)
	state.wallHit = if wallRay and wallRay.Instance then wallRay.Instance else nil
end)

-- Chained presses for bunny hop
local jumpPresses = 0
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Space then
		jumpPresses += 1
	end
end)

RunService.Heartbeat:Connect(function()
	if not root or not humanoid or humanoid.Health <= 0 then return end

	local isGrounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local moveDir = baseController.activeMoveVector and baseController.activeMoveVector() or Vector3.new()
	local speed = moveDir.Magnitude
	local forwardFacing = root.CFrame.LookVector
	local rightFacing = root.CFrame.RightVector

	if state.sliding then
		humanoid.WalkSpeed = 28
		playAnim(ANIMS.Slide, 1)
	elseif state.sprinting then
		humanoid.WalkSpeed = 26
		playAnim(ANIMS.Walk, 1.8)
	elseif speed > 0.1 and isGrounded then
		humanoid.WalkSpeed = 18
		playAnim(ANIMS.Walk, 1.2)
	elseif not isGrounded then
		playAnim(ANIMS.Walk, 0.8)
	else
		stopAnim()
	end

	-- Sprint
	if not state.sliding and state.stamina > 0 then
		state.sprinting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
	else
		state.sprinting = false
	end

	-- Slide: shift + crouch feel
	if isGrounded and speed > 0.2 and state.sprinting and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		state.sliding = true
		state.slideTimer = 0.5
	end
	if not isGrounded or speed < 0.2 then
		state.sliding = false
		state.slideTimer = 0
	end

	-- Bunny hop: double-tap space while grounded
	if jumpPresses >= 2 and isGrounded and state.coyoteTime > 0 and humanoid.JumpPower > 0 then
		jumpPresses = 0
		humanoid.JumpPower = 52
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		task.delay(0.1, function()
			humanoid.JumpPower = 48
		end)
	end

	-- Air strafing
	if not isGrounded then
		if speed > 0.1 then
			local airForward = moveDir.Z
			local airRight = moveDir.X
			local wishDir = (forwardFacing * airForward + rightFacing * airRight).Unit
			local airSpeed = math.clamp(speed * 1.15, 0, 32)
			root.AssemblyLinearVelocity = Vector3.new(wishDir.X * airSpeed, root.AssemblyLinearVelocity.Y, wishDir.Z * airSpeed)
		end
	end

	-- Wall jump
	if state.wallHit and not isGrounded and state.wallJumpCooldown <= 0 and speed > 0.05 then
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			local away = root.CFrame.LookVector
			local up = Vector3.new(0, 1, 0)
			local wallJumpVel = (away + up * 1.25).Unit * 32
			root.AssemblyLinearVelocity = Vector3.new(wallJumpVel.X, 24, wallJumpVel.Z)
			state.wallJumpCooldown = 0.6
			playAnim(ANIMS.DoubleJump, 1.1)
		end
	end

	-- Dash on Q
	if UserInputService:IsKeyDown(Enum.KeyCode.Q) and state.dashCooldown <= 0 and state.stamina >= 25 and not state.sliding then
		local dashDir = moveDir.Magnitude > 0.1 and moveDir or forwardFacing
		local dashVel = dashDir.Unit * 48
		root.AssemblyLinearVelocity = Vector3.new(dashVel.X, root.AssemblyLinearVelocity.Y, dashVel.Z)
		state.dashCooldown = 1.2
		state.stamina -= 25
		task.delay(0.12, function()
			playAnim(ANIMS.DoubleJump, 1)
		end)
	end
end)
