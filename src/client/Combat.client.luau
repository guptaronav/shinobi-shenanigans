local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local cas = game:GetService('ContextActionService')
local ts = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local player = game.Players.LocalPlayer
repeat task.wait() until player:HasTag('Loaded')

---- RESOURCES
local Hitbox = require(game.ReplicatedStorage.Shared.Services.Hitbox)
local utility = require(game.ReplicatedStorage.Modules.Utility)
local MobileTouch = require(game.ReplicatedStorage.Shared.Utility.MobileTouch)
local CombatService = require(game.ReplicatedStorage.Shared.Services.CombatService)
local AnimationService = require(ReplicatedStorage.Shared.Services.AnimationService)

local remotes: Folder = game.ReplicatedStorage.Remotes
local m1AttackRemote: RemoteEvent = remotes.AttackM1
local grabRemote: RemoteEvent = remotes.Grab
local blockRemote: RemoteEvent = remotes.Block

----- CONSTANTS
local char = player.Character or player.CharacterAdded:Wait()
local hum: Humanoid = char:WaitForChild("Humanoid")
local humRoot = char:WaitForChild("HumanoidRootPart")

local data: Folder = player:WaitForChild('Data', 30)
local settingsData: Folder = player:WaitForChild('Settings', 30)

local cam: Camera = workspace.CurrentCamera

----- VARIABLES
local sideDashCooldown: number = 0
local frontDashCooldown: number = 0
local blockCooldown: number = 0
local jumping = false

local function PickupItem()
	if char:GetAttribute('Item') then
		remotes.PickupItem:FireServer(workspace.Map.Voxels:FindFirstChild(char:GetAttribute('Item'), true))
		return true
	end    

	for _,v in CollectionService:GetTagged('Pickupable') do
		if (v.Root.Position - humRoot.Position).Magnitude <= 6 then
			local unit: Vector3 = (humRoot.Position - v.Root.Position).Unit
			local lookVector = humRoot.CFrame.LookVector


			if unit:Dot(lookVector) <= (-0.2) then

				local nearestGrabPoint: Attachment
				local nearestDistance = math.huge
				for _,att: Attachment in v.Root:GetChildren() do
					if att.Name == 'GrabAttachment' then
						if (att.WorldCFrame.Position - humRoot.Position).Magnitude < nearestDistance then
							nearestGrabPoint = att
							nearestDistance = (att.WorldCFrame.Position - humRoot.Position).Magnitude
						end
					end
				end

				warn(v, nearestGrabPoint)
				remotes.PickupItem:FireServer(v, nearestGrabPoint)
				return true
			end
		end
	end

	for _,v in CollectionService:GetTagged('Kickable') do
		if (v.Root.Position - humRoot.Position).Magnitude <= 15 then
			for _,k in v.Root:GetChildren() do
				if k.Name == 'KickAttachment' then
					local unit: Vector3 = (humRoot.Position - k.WorldCFrame.Position).Unit
					local lookVector = humRoot.CFrame.LookVector

					if unit:Dot(lookVector) <= (0) and (k.WorldCFrame.Position - humRoot.Position).Magnitude <= 6 then
						remotes.PickupItem:FireServer(v, k)                
						return true
					end
				end
			end
		end
	end
end

local function M1(_, inputState, inputObject, isIteration: boolean?)
	if inputState and inputState ~= Enum.UserInputState.Begin then return end

	local onConsole = uis:GetLastInputType() == Enum.UserInputType.Gamepad1
	-- if onConsole then return end
	-- print(inputObject.KeyCode, onConsole)
	if onConsole and (inputObject.KeyCode == Enum.KeyCode.ButtonR2 or inputObject.KeyCode == Enum.KeyCode.Unknown) then return end

	-- Checks if the player can pick up or use an item. If so, the M1 doesn't occur.
	-- if PickupItem() then return end

	if player:GetAttribute('NoM1s') then return end

	local extra = {}

	if jumping or hum.FloorMaterial == Enum.Material.Air or hum.FloorMaterial == nil then
		extra.Variant = "Arieal"
	end

	extra.LookVector = humRoot.CFrame.LookVector

	local blocking = char:GetAttribute("Blocking")
	local attackDisabled = char:GetAttribute('AttackDisabled')
	local usingSkill = char:GetAttribute('UsingSkill') and char:GetAttribute('UsingSkill') ~= 'SideDash'
	local stunned: boolean = char.Values.Stuns:FindFirstChildWhichIsA('NumberValue')
	local ragdolled = char:GetAttribute('Ragdolled')

	task.spawn(function()
		if stunned or ragdolled or blocking or usingSkill or attackDisabled then return end
		if not CombatService.CanM1(char) then return end

		remotes.AttackM1:FireServer(extra)
	end)

	if isIteration or not inputState then return end

	while task.wait() and (uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or uis:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonB)) do
		M1(nil, inputState, inputObject, true)
	end
end

-- For PC players
uis.InputBegan:Connect(function(input, gameProcessedEvent)
	-- if gameProcessedEvent then return end
	-- print('input pls?')
	-- if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessedEvent then
		-- print('m1? pls')
		-- M1(nil, Enum.UserInputState.Begin, input)
	if input.KeyCode == Enum.KeyCode.Space and not jumping then
		jumping = true
		task.delay(.3, function()
			jumping = false
		end)
	end
end)

cas:BindActionAtPriority('M1', M1, false, 1, Enum.KeyCode.ButtonB, Enum.UserInputType.MouseButton1)
cas:SetPosition('M1', UDim2.fromScale(.1, -.1))
cas:SetTitle('M1', 'Punch')

MobileTouch.WaitForButton('M1')
MobileTouch.Button_Activated('M1', 'HoldPress', M1, 0)

local onMobile = uis.TouchEnabled and not uis.KeyboardEnabled

local function getMobileDirection(moveDirection: Vector3)
	if math.round(moveDirection.X) == -1 then
		return 'Side', -1
	elseif math.round(moveDirection.X) == 1 then
		return 'Side', 1
	elseif math.round(moveDirection.Z) == -1 then
		return 'Front'
	elseif math.round(moveDirection.Z) == 1 then
		return 'Back', -2
	end
end

local function Dash(_, inputState)
	if inputState and inputState ~= Enum.UserInputState.Begin then return end

	if #char.Values.Stuns:GetChildren() > 0 or char:GetAttribute('WalkSpeedDisabled') then return end
	if char:GetAttribute('UsingSkill') then return end

	local direction
	local side
	if not onMobile then
		direction = (uis:IsKeyDown(Enum.KeyCode.D) or uis:IsKeyDown(Enum.KeyCode.A)) and 'Side' or uis:IsKeyDown(Enum.KeyCode.S) and 'Back' or 'Front'
		if direction == 'Back' then
			side = -2
		end
	else
		direction, side = getMobileDirection(workspace.CurrentCamera.CFrame:VectorToObjectSpace(hum.MoveDirection))
	end

	if direction == 'Front' and char:GetAttribute("AttackDisabled") then return end
	if not player:GetAttribute('NoDashCooldown') and (direction == 'Side' or direction == 'Back') and os.clock() - sideDashCooldown < 2 or not player:GetAttribute('NoDashCooldown') and direction == 'Front' and os.clock() - frontDashCooldown < 6 then return end

	local dashSend: any, ragdollCancel: boolean
	if char:GetAttribute('Ragdolled') then
		dashSend, ragdollCancel = game.ReplicatedStorage.Remotes.Dash:InvokeServer({Type = direction, Route = 'Init'})
	else
		dashSend = true; ragdollCancel = false
		task.spawn(function()
			game.ReplicatedStorage.Remotes.Dash:InvokeServer({Type = direction, Route = 'Init'})
		end)
	end

	if dashSend == false then return end

	if ragdollCancel then
		hum.PlatformStand = false
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	local CharacterCombat = require(game.ReplicatedStorage.Skills.Default.Combat)

	if direction == 'Side' or direction == 'Back' then
		sideDashCooldown = os.clock()
		CharacterCombat.SideDash.ClientInit(char, side)
	elseif direction == 'Front' then
		frontDashCooldown = os.clock()
		CharacterCombat.FrontDash.ClientInit(char)
	end
end

cas:BindAction('Dash', Dash, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonY)
MobileTouch.WaitForButton('Dash')
MobileTouch.Button_Activated('Dash', 'Pressed', Dash)

local isBlocking = false
local function BlockStart()
	if os.clock() - blockCooldown >= .2 then
		isBlocking = true
		blockCooldown = os.clock()
		blockRemote:FireServer(true)

		AnimationService.StopAnimationsOfOrigin(char, 'Run')
		-- Run(nil, Enum.UserInputState.Begin, Enum.KeyCode.W)

		while task.wait() and isBlocking do
			blockRemote:FireServer(true)
		end
	end
end

local function BlockEnd()
	isBlocking = false
	blockRemote:FireServer(false)

	if char.Values.WalkspeedPriorities:FindFirstChild('Run') then
		local CombatStats = require(ReplicatedStorage.Skills[player.Data.Character.Value or 'Half-Devil'].Server.Combat)
		AnimationService.LoadAnimation(char, CombatStats.Run.Animation(char, true), 'Run'):Play()
	end
end

local function Block(actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		BlockStart()
	elseif inputState == Enum.UserInputState.End then
		BlockEnd()
	end
end

cas:BindAction('Block', Block, false, Enum.KeyCode.F, Enum.KeyCode.ButtonX)
MobileTouch.WaitForButton('Block')
MobileTouch.Button_Activated('Block', 'PressDown', BlockStart)
MobileTouch.Button_Activated('Block', 'PressUp', BlockEnd)

-- cas:BindAction('Grab/Uppercut', function(_, inputState)
-- 	if inputState == Enum.UserInputState.Begin then
-- 		m1AttackRemote:FireServer({Variant = 'Lunge', LookVector = humRoot.CFrame.LookVector})
-- 	elseif inputState == Enum.UserInputState.End then
-- 		grabRemote:FireServer()
-- 	end
-- end, false, Enum.KeyCode.E)
-- cas:SetPosition('Grab/Uppercut', UDim2.fromScale(.5, -.1))
-- cas:SetTitle('Grab/Uppercut', 'Grab')

local running = false
local canRun = 0

local autoRun = settingsData:WaitForChild('AutoRun')
local CombatModule = require(ReplicatedStorage.Skills.Default.Combat)

char:WaitForChild('Values'):WaitForChild(('WalkspeedPriorities')).ChildAdded:Connect(function(child)
	if not child:HasTag('SafelyAdded') then
		local update: boolean = true
		local priorities = char.Values.WalkspeedPriorities:GetChildren()

		for _, v in priorities do
			if v.Value > child.Value then update = false; break end
		end

		if update then
			hum.WalkSpeed = child:WaitForChild('WalkSpeed').Value
		end
	end
end)

char:WaitForChild('Values'):WaitForChild(('WalkspeedPriorities')).ChildRemoved:Connect(function(child)
	if not child:HasTag('SafelyAdded') then
		local highestPriority
		local priorities = char.Values.WalkspeedPriorities:GetChildren()

		for _, v in priorities do
			if v.Value > child.Value then highestPriority = v; break end
		end

		if highestPriority then
			hum.WalkSpeed = highestPriority:WaitForChild('WalkSpeed').Value
			-- print(hum.WalkSpeed)
		else
			hum.WalkSpeed = char:GetAttribute('WalkSpeed')
		end
	else
		local runPriority = char.Values.WalkspeedPriorities:FindFirstChild('Run')
		if not runPriority then return end
		local highestPriority = runPriority
		local priorities = char.Values.WalkspeedPriorities:GetChildren()

		for _, v in priorities do
			if v.Value > highestPriority.Value then highestPriority = v; continue end
		end

		if highestPriority == runPriority then
			hum.WalkSpeed = highestPriority:WaitForChild('WalkSpeed').Value
		end
	end
end)

function Run(actionName, inputState, _inputObject: InputObject, blockEnd: boolean)
	if not autoRun.Value and canRun ~= -1 and not _inputObject then  
		return
	end

	if inputState == Enum.UserInputState.Begin and (not running or blockEnd) then
		if not blockEnd and not autoRun.Value and _inputObject and os.clock() - canRun > .35 then
			canRun = os.clock()
			return
		end

		running = true
		-- runRemote:FireServer(true)
		if char:GetAttribute('Blocking') then
			repeat
				task.wait()
			until not char:GetAttribute('Blocking')
			if not running then return end

			CombatModule.Run(char, true)            
		else
			CombatModule.Run(char, true)
		end
	elseif inputState == Enum.UserInputState.End and running then
		running = false
		-- runRemote:FireServer(false)
		CombatModule.Run(char, false)            
	end
end

cas:BindActionAtPriority('Run', Run, false, 0, Enum.KeyCode.W)
uis.TouchMoved:Connect(function(touch, gp)
	-- if gp then return end
	print(hum.MoveDirection)
	if hum.MoveDirection.Magnitude ~= 0 then
		Run(nil, Enum.UserInputState.Begin)
	end
end)
uis.TouchEnded:Connect(function(touch, gameProcessedEvent)
	Run(nil, Enum.UserInputState.End)
end)

char:GetAttributeChangedSignal('Form'):Connect(function()
	if char:GetAttribute('Form') == 'Awakening' then
		Run(nil, Enum.UserInputState.End)
	end
end)

MobileTouch.WaitForButton('Run')
MobileTouch.Button_Activated('Run', 'Pressed', function()
	canRun = canRun == -1 and 0 or -1
end)


-- local regenRemote = game.ReplicatedStorage.Remotes.Regenerate
-- local regenCooldown = os.clock()
-- cas:BindAction('Regenerate', function(_, inputState)
-- 	if inputState == Enum.UserInputState.Begin then
-- 		if os.clock() - regenCooldown >= .2 then
-- 			regenCooldown = os.clock()
-- 			regenRemote:FireServer(true)

-- 		end
-- 	elseif inputState == Enum.UserInputState.End then 
-- 		regenRemote:FireServer(false)
-- 	end
-- end, false, Enum.KeyCode.C)

local mouse = player:GetMouse()
-- Setting the mouse icon

uis:GetPropertyChangedSignal("MouseBehavior"):Connect(function()
	if uis.MouseBehavior == Enum.MouseBehavior.LockCenter then
		mouse.Icon = 'http://www.roblox.com/asset/?id=100589429049043'
	elseif uis.MouseBehavior == Enum.MouseBehavior.Default then
		mouse.Icon = ''
	end
end)