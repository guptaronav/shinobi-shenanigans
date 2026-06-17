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

skill.Init = function(char: Character)
    SkillService.UsingSkill(char, true, 'Wipeout Flash')

    local state = StateService.Get(char)
    state:SetWalkspeed('Wipeout Flash', 4, 0.1)

    local humRoot = char.HumanoidRootPart
    local hum: Humanoid = char.Humanoid
    -- hum.AutoRotate = false

    -- Global variables

    local skillHandler = SkillService.CreateSkill(char, 'Wipeout Flash', {
        ['Start'] = 0,
    })

    local phone
    skillHandler.Runtime = function()
        phone = ReplicatedStorage.Assets.SkillAssets.SpiritKnight.FlipPhone:Clone()
        local root = phone:WaitForChild('Bottom'):WaitForChild('Root')
        phone.Parent = char
        root.CFrame = char['Right Arm'].CFrame
        local joint = phone.Part
        joint.Parent = char['Right Arm']
        joint.Part0 = char['Right Arm']
        joint.Part1 = root

        local anim = AnimationService.LoadAnimation(char, Animations.SpiritKnight.WipeoutFlash, 'Skill')
        anim:Play()

        SkillService.RouteToClient('Wipeout Flash', char, 'Flash', 'All', anim)

        for i=1, 4 do
            anim:GetMarkerReachedSignal('Flash'..i):Wait()

            local hits = HitboxService.instant({Core = humRoot, OffsetIsRelativeTo = {'LookVector'}, Offset = {3}}, Vector3.one * 7, char, nil, nil, game.Players:GetPlayerFromCharacter(char))
            for _,hit in hits do
                if hit:GetAttribute('Ragdolled') or hit:GetAttribute('Blocking') then continue end

                DamageService.Damage(hit, char, 1)
                local hitState = StateService.Get(hit)
                hitState:Stun('FlipPhoneFlash', 1, 3)
            end

            SkillService.RouteToClient('Wipeout Flash', char, 'Flash2', 'All', i)
        end
        
        anim.Stopped:Wait()
    end

    skillHandler.CleanUp = function()
        state:EndWalkspeed('Wipeout Flash')

        if phone then
            phone:Destroy()
        end

        SkillService.Cooldown(char, 'Wipeout Flash')
        SkillService.UsingSkill(char, false, 'Wipeout Flash')
    end

    skillHandler:Run()
end

return skill