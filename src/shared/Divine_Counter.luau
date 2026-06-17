-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService('TweenService')

-- Services
local Services = require(ReplicatedStorage.Shared.Services)
local StateService = Services.StateService
local SkillService = Services.SkillService
local AnimationService = Services.AnimationService
local HitboxService = Services.HitboxService
local DamageService = Services.DamageService
local RagdollService = Services.RagdollService

-- Resources / Assets
local Assets = ReplicatedStorage.Assets
local Animations = Assets.Animations
local Remotes = ReplicatedStorage.Remotes

local skill = {}

type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: BasePart}

skill.Init = function(char: Character, extra)
    SkillService.UsingSkill(char, true, 'Divine Counter')
    local humRoot = char.HumanoidRootPart
    local startCFrame = extra.StartCFrame

    local skillHandler = SkillService.CreateSkill(char, 'Divine Counter', {
        ['Start'] = 0, Counter=7
    })

    local state = StateService.Get(char)
    state:SetWalkspeed('Divine Counter', 7, 0)
    -- char.Humanoid.AutoRotate = false

    local counterAnim

    skillHandler.Runtime = function()
        local startAnim: AnimationTrack = AnimationService.LoadAnimation(char, Assets.Animations.OneMostLoved.DivineCounter.Start, 'Skill')
        startAnim:Play()
        startAnim.Stopped:Wait()

        skillHandler.CurrentSection = 'Counter'
        
        counterAnim = AnimationService.LoadAnimation(char, Assets.Animations.OneMostLoved.DivineCounter.Static, 'Skill')

        DamageService.AddDamageEvent(char, 'Divine Counter', function(hit, dmg, haltKilling)
            if counterAnim.IsPlaying and not skillHandler:HasCompleted() then
                state:IFrame(true, .75)
                local attackAnim = AnimationService.LoadAnimation(char, Assets.Animations.OneMostLoved.DivineCounter.Attack, 'Skill')
                attackAnim:Play()

                attackAnim:GetMarkerReachedSignal('Hitbox'):Once(function()
                    DamageService.Damage(hit, char, 8)
                    local hitState = StateService.Get(hit)
                -- hitState:Stun('DivineCountered', nil, 4)

                    local ragdoll = RagdollService.Get(hit)
                    ragdoll:Ragdoll(hit, 1)

                    hitState:Velocity(humRoot.CFrame.RightVector * 40, .2, nil, {Vector3.yAxis})

                    Remotes.BodyFlash:FireAllClients(hit)
                    SkillService.RouteToClient('Divine Counter', char, 'Burst', 'All', {hit})
                end)

                return 'Interruption'
            end
        end)

        counterAnim:Play()

        task.wait(.6)
    end

    skillHandler.CleanUp = function()
        if counterAnim then
            counterAnim:Stop()
        end

        state:EndWalkspeed('Divine Counter')
        -- char.Humanoid.AutoRotate = true
        SkillService.UsingSkill(char, false, 'Divine Counter')
        SkillService.Cooldown(char, 'Divine Counter')
    end

    skillHandler:Run()
end

return skill