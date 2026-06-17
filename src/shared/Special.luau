-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService('TweenService')

-- Services
local Services = require(ReplicatedStorage.Shared.Services)
local SkillService = Services.SkillService
local DamageService = Services.DamageService
local StateService = Services.StateService

-- Resources / Assets
local Assets = ReplicatedStorage.Assets

local skill = {}

type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: BasePart}

local weaponSpawnFX = game.ReplicatedStorage.Assets.SkillAssets.HalfDevil.WeaponSpawnFX:Clone()
local weapons = game.ReplicatedStorage.Assets.SkillAssets.HalfDevil.Weapons

skill.Statuses = {}
skill.Domains = {}
skill.Verdicts = {}

skill.Init = function(char: Model, extra, forceRelease)
    SkillService.UsingSkill(char, true, 'Special')

    local skillHandler = SkillService.CreateSkill(char, 'Special_Al', {Start=10})

    local state = StateService.Get(char)

    skillHandler.Runtime = function()
        
    end

    skillHandler.CleanUp = function()
        SkillService.Cooldown(char, 'Special')
        SkillService.UsingSkill(char, false, 'Special')
    end

    skillHandler:Run()
end

return skill