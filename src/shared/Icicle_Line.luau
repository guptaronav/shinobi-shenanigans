-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Services
local Services = require(ReplicatedStorage.Shared.Services)
local SkillService = Services.SkillService
local AnimationService = Services.AnimationService
local StateService = Services.StateService
local HitboxService = Services.HitboxService
local DamageService = Services.DamageService
local RagdollService = Services.RagdollService

local Utility = require(ReplicatedStorage.Modules.Utility)

-- Resources / Assets
local Assets = ReplicatedStorage.Assets

local skill = {}

type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: BasePart}

local SPEAR_FADE_TIME = 0.6
local UNHIT_SPEAR_LIFETIME = 6

local function fadeAndDestroy(model: Model)
	task.delay(SPEAR_FADE_TIME, function()
		if not model or not model.Parent then return end
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				TweenService:Create(part, TweenInfo.new(SPEAR_FADE_TIME), {Transparency = 1}):Play()
			end
		end
		task.delay(SPEAR_FADE_TIME, function()
			if model then model:Destroy() end
		end)
	end)
end

local groundParams = RaycastParams.new()
groundParams.FilterDescendantsInstances = {workspace.Map}
groundParams.FilterType = Enum.RaycastFilterType.Include

local spearMarks = {}

function skill.Init(char: Character, extra: table)
	SkillService.UsingSkill(char, true, "Icicle Line")

	local target
	if spearMarks[char] then
		target = SkillService.GetTarget(char, spearMarks[char], true)
	else
		spearMarks[char] = {}
	end

	local skillHandler = SkillService.CreateSkill(char, "IcicleLineCast", { Start = 0 })
	SkillService.RouteToClient("Icicle Line", char, "User", game.Players:GetPlayerFromCharacter(char))

	local humRoot = char.HumanoidRootPart
	local state = StateService.Get(char)
	state:SetWalkspeed("IcicleLineCast", 5, 0.01)

	local alignPosition: AlignPosition

	skillHandler.Runtime = function()
		local iceSpear = Assets.SkillAssets.HalfDevil.IceSpear:Clone()
		iceSpear.Parent = workspace.UnobstructiveAssets

		local joint = Instance.new("Motor6D")
		joint.Name = "IceSpearJoint"
		joint.Part1 = iceSpear:WaitForChild("Handle")
		joint.Part0 = char["Right Arm"]
		joint.C0 = CFrame.new(0, -1, 0)
		joint.Parent = char["Right Arm"]

		local windUpAnim = AnimationService.LoadAnimation(char, Assets.Animations.HalfDevil.Awakening.SpearWindUp, "Skill")
		windUpAnim:Play()

		if extra.IsInAir then
			char:AddTag("DisableRotating")
			alignPosition = Instance.new("AlignPosition")
			alignPosition.Attachment0 = humRoot.RootAttachment
			alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
			alignPosition.Position = extra.StartCFrame.Position + Vector3.yAxis * 4
			alignPosition.RigidityEnabled = true
			alignPosition.Parent = humRoot
			SkillService.RouteToClient("Icicle Line", char, "Aim_Air", game.Players:GetPlayerFromCharacter(char))
		end

		task.wait(1.5)

		skillHandler.CurrentSection = "Throw"
		windUpAnim:Stop()
		local throwAnim = AnimationService.LoadAnimation(char, Assets.Animations.HalfDevil.Awakening.SpearThrow, "Skill")
		throwAnim:Play()

		joint:Destroy()
		iceSpear.Handle.Anchored = true

		local mouse = SkillService.GetMouse(char, "Minya")
		local finalPos = extra.IsInAir and mouse and mouse.Position or humRoot.Position + humRoot.CFrame.LookVector * 70
		local midPos = extra.StartCFrame.Position + (finalPos - extra.StartCFrame.Position) / 2

		iceSpear.Handle.CFrame = CFrame.new(finalPos) * humRoot.CFrame.Rotation
		local pointCFrame = CFrame.lookAt(midPos, finalPos)

		local hits = HitboxService.instant(pointCFrame, Vector3.new(5, 5, 70), char)
		SkillService.VoxelDestruction(pointCFrame, Vector3.new(3, 7, 70), 4.2, nil, 0, 70, pointCFrame.LookVector * 50 + Vector3.yAxis * 2)

		local hitAnyone = false

		for _, hit in hits do
			hitAnyone = true
			if not table.find(spearMarks[char], hit) then
				table.insert(spearMarks[char], hit)

				local spear = Assets.SkillAssets.HalfDevil.IceSpear:Clone()
				spear.Name = "StabbedSpear"
				spear.Parent = hit
				spear.Handle.CFrame = hit.HumanoidRootPart.CFrame
				Utility.Weld(spear.Handle, hit.HumanoidRootPart)
			end

			DamageService.Damage(hit, char, 40)
			local hitState = StateService.Get(hit)
			hitState:Stun("SpearHit", 0.5, 4)
			local ragdoll = RagdollService.Get(hit)
			ragdoll:Ragdoll(hit, 1.7)
			hitState:Knockback(char, extra.StartCFrame.LookVector * 75)
		end

		if not hitAnyone then
			task.delay(UNHIT_SPEAR_LIFETIME, function()
				if iceSpear and iceSpear.Parent then
					fadeAndDestroy(iceSpear)
				end
			end)
		end

		char:RemoveTag("DisableRotating")
	end

	skillHandler.CleanUp = function()
		state:EndWalkspeed("IcicleLineCast")
		if alignPosition then alignPosition:Destroy() end
		SkillService.Cooldown(char, "Icicle Line")
		SkillService.UsingSkill(char, false, "Icicle Line")
	end

	skillHandler:Run()
end

return skill