local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Services = require(ReplicatedStorage.Shared.Services)
local StateService = Services.StateService
local SkillService = Services.SkillService
local AnimationService = Services.AnimationService
local Hitbox = Services.HitboxService
local DamageService = Services.DamageService
local RagdollService = Services.RagdollService
local utility = require(ReplicatedStorage.Modules.Utility)

local Assets = ReplicatedStorage.Assets
local animations = Assets.Animations

local skill = {}

type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: BasePart}

local function GetClosestTarget(position: Vector3, character: Model)
	local closestHumanoid = nil
	local closestDistance = math.huge

	for _, obj in pairs(workspace.Characters:GetChildren()) do
		if obj:IsA("Model") and obj ~= character then
			local humanoid = obj:FindFirstChildOfClass("Humanoid")
			local root = obj:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and root then
				local distance = (root.Position - position).Magnitude
				if distance < closestDistance then
					closestDistance = distance
					closestHumanoid = root
				end
			end
		end
	end

	return closestHumanoid
end

local groundParams = RaycastParams.new()
groundParams.RespectCanCollide = true
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.FilterDescendantsInstances = {workspace.UnobstructiveAssets, workspace.Characters}

skill.Init = function(char: Character, extra)
	char:SetAttribute('UsingSkill', 'Minya')

    local humRoot = char.HumanoidRootPart
    
    local state = StateService.Get(char)
    state:SetWalkspeed('MinyaCast', 3, 4)

	local skillHandler = SkillService.CreateSkill(char, 'Minya', {Start=0, Attack=9})

	skillHandler.Runtime = function()
		local castAnim = AnimationService.LoadAnimation(char, animations.SpiritKnight.Minya_Player, "Skill")
		if castAnim then
			castAnim.Priority = Enum.AnimationPriority.Action
			castAnim:Play()
			castAnim:AdjustSpeed(.5)
		end

		local bea = Assets.SkillAssets.SpiritKnight:FindFirstChild("BeatriceRig"):Clone()
		bea.Name = "BeatriceRig"
		bea:SetPrimaryPartCFrame(humRoot.CFrame * CFrame.new(5, 0, 0))
		bea.Parent = workspace

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = bea.PrimaryPart
		weld.Part1 = humRoot
		weld.Parent = bea.PrimaryPart

		local beaAnim = AnimationService.LoadAnimation(bea, animations.SpiritKnight.Minya_Beatrice, "Skill")
		if beaAnim then
			beaAnim.Priority = Enum.AnimationPriority.Action
			beaAnim:Play()
			beaAnim:AdjustSpeed(.5)
		end

		task.delay(1.8, function()
			if weld then weld:Destroy() end
			if bea and bea.PrimaryPart then
				bea.PrimaryPart.Anchored = true
			end
			task.wait(3-1.8)
			bea:Destroy()
		end)

		task.wait(1.2)

		skillHandler.CurrentSection = 'Attack'

		local sound = Assets.Sounds.SpiritKnight.ElMinya:Clone()
		sound.Parent = humRoot
		sound:Play()

		for row=1, 6 do
			for spot= -6, 6, 3 do
				local shard: BasePart = game.ReplicatedStorage.Assets.SkillAssets.MinyaShard:Clone()
				shard.Parent = workspace.UnobstructiveAssets
				shard.Anchored = true

				local x = spot--rng:NextNumber(3, 8) * (neg and -1 or 1); neg = not neg
				local z = -4--rng:NextNumber(3, 6) * -1
				local y = 4.5--rng:NextNumber(3, 8)
		
				shard.CFrame = humRoot.CFrame + humRoot.CFrame.RightVector * x + humRoot.CFrame.LookVector * z + Vector3.yAxis * y
				shard.Size = Vector3.zero
		
				task.defer(function()
					task.wait()
					shard:WaitForChild('Attachment'):WaitForChild('Dots 2'):Emit(12)
					shard.Attachment:WaitForChild('Smoke'):Emit(1)
		
					task.wait(.2)
		
					TweenService:Create(shard, TweenInfo.new(.3), {CFrame = CFrame.lookAt(shard.Position, humRoot.Position + humRoot.CFrame.LookVector * 50) * CFrame.Angles(math.rad(90), 0, 0), Size = Vector3.new(0.519, 2.78, 0.615)}):Play()
				
					task.wait(.32)
		
					local ray = workspace:Raycast(humRoot.CFrame.Position + humRoot.CFrame.LookVector * (7+row*10) + humRoot.CFrame.RightVector * x, -Vector3.yAxis * 100, groundParams)
					local finalPos = ray and ray.Position or humRoot.Position + humRoot.CFrame.LookVector * (7+row*10) + humRoot.CFrame.RightVector * x - Vector3.yAxis * 2
		
					TweenService:Create(shard, TweenInfo.new(.3), {CFrame = CFrame.lookAt(shard.Position, finalPos) * CFrame.Angles(math.rad(90), 0, 0)}):Play()
					-- shard.CFrame= CFrame.lookAt(shard.Position, finalPos ) * CFrame.Angles(math.rad(90), 0, 0)
					task.wait(.3)
		
					local hitbox = Hitbox.new()
					hitbox.CoreMode = true
					hitbox.Core = shard
					hitbox.Size = Vector3.one * 3
					hitbox.Single = true
					hitbox.OverlapParams.FilterDescendantsInstances = {char, workspace.UnobstructiveAssets}
					hitbox.OverlapParams.FilterType = Enum.RaycastFilterType.Exclude
					hitbox.Mode = 'Any'
		
					hitbox.HitEvent:Connect(function(hit: any, hitOriginal: any)
						local finalCFrame = shard.CFrame
						shard:Destroy()
		
						if hit:FindFirstChild('Humanoid') and hit:GetAttribute('Combo') then
							DamageService.Damage(hit, char, 5)
		
							if hit.Humanoid:GetState() == Enum.HumanoidStateType.Dead then
								hit.Torso:ClearAllChildren()
							end
		
							local limb: BasePart = hitOriginal
		
							-- local iceClone = limb:Clone()
							-- iceClone:ClearAllChildren()
							-- iceClone.CanCollide = false; iceClone.CanQuery = false
							-- iceClone.Material = Enum.Material.Ice; iceClone.Reflectance = .2; iceClone.Massless = true; iceClone.Transparency = .4
							-- iceClone.Size += Vector3.one * .1; iceClone.Color = Color3.new(0.396078, 0.2, 0.607843)
							-- iceClone.Parent = workspace.UnobstructiveAssets
							-- iceClone.CFrame = limb.CFrame
							-- utility.Weld(iceClone, limb)
		
						elseif hit:IsA('BasePart') then
							-- print('hit part')
							-- VoxelService:DestroyPartsInBounds(finalCFrame, 1.5)
							-- VoxelService:UnfreezePartsInBounds(finalCFrame, 3)
							SkillService.VoxelDestruction(finalCFrame, Vector3.one * 3, 3, Enum.PartType.Ball, 0, 60)
							-- game.ReplicatedStorage.Remotes.Voxelize:FireAllClients('Destroy', Vector3.one * 3, finalCFrame, Enum.PartType.Ball, nil, 20)
							-- game.ReplicatedStorage.Remotes.Voxelize:FireAllClients('Unfreeze', Vector3.one * 6, finalCFrame, Enum.PartType.Ball, nil, 20)
						end
		
						SkillService.RouteToClient('Minya', char, 'ShardShatter', 'All', finalCFrame)
						-- skillRoute:FireAllClients('Minya', char, 'ShardShatter', finalCFrame)
					end)
		
					hitbox:Start()
		
					TweenService:Create(shard, TweenInfo.new(1), {CFrame = CFrame.lookAt(shard.Position + (finalPos - shard.Position).Unit * 70, shard.Position + (finalPos - shard.Position).Unit * 75) * CFrame.Angles(math.rad(90),0,0)}):Play()
		
					-- local bv = Instance.new('BodyVelocity')
					-- bv.MaxForce = Vector3.one * 100000
					-- bv.Velocity = (finalPos - shard.Position).Unit * 5
					-- bv.Parent = shard
		
					-- shard.Anchored = false
					-- shard:SetNetworkOwner(nil)
		
					task.wait(10)
					hitbox:Stop()
					shard:Destroy()
		
				end)
			end
			task.wait(.2)
		end
	end

	skillHandler.CleanUp = function()
		state:EndWalkspeed('MinyaCast')

		SkillService.Cooldown(char, 'Minya')
		SkillService.UsingSkill(char, false, 'Minya')
	end

	skillHandler:Run()
end

-- skill.Init = function(char: Character, extra)
-- 	SkillService.UsingSkill(char, true, 'Minya')
-- 	local hum = char.Humanoid
-- 	local root = char:FindFirstChild("HumanoidRootPart")
-- 	if not root then return end

-- 	local skillHandler = SkillService.CreateSkill(char, "Minya", {["Start"] = 0})
-- 	local userState = StateService.Get(char)

-- 	userState:SetWalkspeed("Minya", 9, 0.01)

-- 	skillHandler.Runtime = function()
-- 		local castAnim = AnimationService.LoadAnimation(char, animations.SpiritKnight.Minya_Player, "Skill")
-- 		if castAnim then
-- 			castAnim.Priority = Enum.AnimationPriority.Action
-- 			castAnim:Play()
-- 		end

-- 		task.wait(0.15)

-- 		local bea = Assets.SkillAssets.SpiritKnight:FindFirstChild("BeatriceRig"):Clone()
-- 		bea.Name = "BeatriceRig"
-- 		bea:SetPrimaryPartCFrame(root.CFrame * CFrame.new(5, 0, 0))
-- 		bea.Parent = workspace

-- 		local weld = Instance.new("WeldConstraint")
-- 		weld.Part0 = bea.PrimaryPart
-- 		weld.Part1 = root
-- 		weld.Parent = bea.PrimaryPart

-- 		local beaAnim = AnimationService.LoadAnimation(bea, animations.SpiritKnight.Minya_Beatrice, "Skill")
-- 		if beaAnim then
-- 			beaAnim.Priority = Enum.AnimationPriority.Action
-- 			beaAnim:Play()
-- 		end

-- 		task.delay(1.8, function()
-- 			if weld then weld:Destroy() end
-- 			if bea and bea.PrimaryPart then
-- 				bea.PrimaryPart.Anchored = true
-- 			end
-- 			task.wait(3-1.8)
-- 			bea:Destroy()
-- 		end)

-- 		local sound = Instance.new("Sound")
-- 		sound.SoundId = "rbxassetid://127549873039692"
-- 		sound.Volume = 1
-- 		sound.Parent = root
-- 		sound:Play()

-- 		local folder = Instance.new("Folder")
-- 		folder.Name = "MinyaShards"
-- 		folder.Parent = workspace.UnobstructiveAssets

-- 		for i = 1, 6 do			
-- 			local shard = Assets.SkillAssets.MinyaShard:Clone()

-- 			local target = GetClosestTarget(root.Position, char)
-- 			if not target then
-- 				shard:Destroy()
-- 				return
-- 			end
-- 			shard.CFrame = CFrame.lookAt(root.Position + Vector3.new(math.random(-5,5), 8 + math.random(), math.random(-5,5)), target.Position) * CFrame.Angles(math.rad(90), 0, 0) 

-- 			local direction = (target.Position - shard.Position).Unit
-- 			local goal = shard.Position + direction * 100
-- 			local timeToTarget = (goal - shard.Position).Magnitude * 0.1

-- 			shard.Anchored = true
-- 			shard.Name = "MinyaShard_" .. i
-- 			shard.Parent = folder

-- 			task.delay(.6, function()
-- 				local tween = TweenService:Create(shard, TweenInfo.new(timeToTarget), {
-- 					CFrame = shard.CFrame + direction * 100
-- 				})

-- 				local hitbox = Hitbox.new()
-- 				hitbox.CoreMode = true
-- 				hitbox.Core = shard
-- 				hitbox.Size = Vector3.new(4, 4, 4)
-- 				hitbox.Single = true
-- 				hitbox.OverlapParams.FilterDescendantsInstances = {char}

-- 				hitbox.HitEvent:Connect(function(hit)
-- 					tween:Cancel()
-- 					DamageService.Damage(hit, char, 3)
-- 					local state = StateService.Get(hit)
-- 					state:Stun("MinyaHit", 0.2, 2)
-- 					local rag = RagdollService.Get(hit)
-- 					rag:Ragdoll_(0.5, {DestructionPower = 2, GainVerticalVelocity = true})
-- 					state:Knockback(char, direction * 40, 0.2)
-- 					shard:Destroy()
-- 				end)

-- 				hitbox:Start()
-- 				tween:Play()

-- 				tween.Completed:Connect(function()
-- 					hitbox:Stop()
-- 					shard:Destroy()
-- 				end)
-- 			end)
-- 		end

-- 		task.wait(1)

-- 		if castAnim then castAnim:Stop() end
-- 	end

-- 	skillHandler.CleanUp = function()
-- 		userState:EndWalkspeed("Minya")
-- 		SkillService.Cooldown(char, 'Minya')
-- 		SkillService.UsingSkill(char, false, 'Minya')
-- 	end

-- 	skillHandler:Run()
-- end

return skill