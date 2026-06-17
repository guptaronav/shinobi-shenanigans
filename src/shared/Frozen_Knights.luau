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

local groundParams = RaycastParams.new()
groundParams.FilterDescendantsInstances = {workspace.Map}
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.RespectCanCollide = true

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