-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService('TweenService')
local Workspace = game:GetService("Workspace")

-- Services
local Services = require(ReplicatedStorage.Shared.Services)
local StateService = Services.StateService
local SkillService = Services.SkillService
local AnimationService = Services.AnimationService
local Hitbox = Services.HitboxService
local DamageService = Services.DamageService
local RagdollService = Services.RagdollService
local VoxelService = Services.VoxelService

-- Resources / Assets
local Assets = ReplicatedStorage.Assets
local animations = Assets.Animations
local Remotes = ReplicatedStorage.Remotes

local skill = {}

type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: BasePart}

local charges = {}

skill.Init = function(char: Character, extra: table)
    SkillService.UsingSkill(char, true, 'Lightning Rod')
    local accurateCFrame = extra.StartCFrame

    local hum: Humanoid = char.Humanoid
    local humRoot = char.HumanoidRootPart

    local skillHandler = SkillService.CreateSkill(char, 'LightningStrike', {})

    local state = StateService.Get(char)
    state:SetWalkspeed('LightningStrike', 4, 0)

    skillHandler.Runtime = function()
        if not charges[char] then
            local anim = AnimationService.LoadAnimation(char, animations.FollowingStar['Lightning Rod'].SwordCharge, 'Skill')
            anim:Play()

            anim:GetMarkerReachedSignal('Activation'):Wait()

            Remotes.DisplayEffect:FireAllClients(
                'Camera', {
                    Magnitude = 3, Roughness = 5, FadeInTime = .1, FadeOutTime = 1, 
                    PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                    Origin = humRoot.Position, Radius = 20
                }
            )
        
            anim.Stopped:Wait()
        end
    end

    skillHandler.CleanUp = function()
        if charges[char] then 
            SkillService.Cooldown(char, 'Lightning Rod')
            charges[char] = nil
        else
            charges[char] = true
        end
        
        state:EndWalkspeed('LightningStrike')
        SkillService.UsingSkill(char, false, 'Lightning Rod')
        -- SkillService.Cooldown(char, 'Lightning Rod')
        -- SkillService.UsingSkill(char, false, 'Lightning Rod')
    end

    skillHandler:Run()
end

-- skill.Init2 = function(char: Character)
--     SkillService.UsingSkill(char, false, 'Lightning Rod')
--     SkillService.Cooldown(char, 'Lightning Rod')
-- end

return skill