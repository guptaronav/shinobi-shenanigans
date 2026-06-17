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

local earlyStops = {}

skill.Init = function(char: Character, extra)
    SkillService.UsingSkill(char, true, 'Level 100 Punch')

    local state = StateService.Get(char)
    state:SetWalkspeed('Level100Punch', 4, 0.01)

    local humRoot = char.HumanoidRootPart
    local hum: Humanoid = char.Humanoid
    -- hum.AutoRotate = 

    -- Global variables
    earlyStops[char] = nil

    local skillHandler = SkillService.CreateSkill(char, 'Level 100 Punch', {
        ['Start'] = 0,
        ['Run'] = 1,
    })

    local punchHitbox

    skillHandler.Runtime = function()
        local punchAnim = AnimationService.LoadAnimation(char, Animations.SpiritKnight.HeavyPunch, 'Skill')
        punchAnim:Play()
        punchAnim:AdjustSpeed(.4)

        punchAnim:GetMarkerReachedSignal('Move'):Wait()
        skillHandler.CurrentSection = 'Run'
        punchAnim:AdjustSpeed(1)
        state:Superarmor(true)
        -- char:AddTag('DisableRotating')

        SkillService.RouteToClient('Level 100 Punch', char, 'Run', 'All')
        local lookCFrame = SkillService.RouteToClient('Rental Goa', char, 'LookCFrame_Return', game.Players:GetPlayerFromCharacter(char))
        state:Velocity(lookCFrame.LookVector * 65, .35, nil, {Vector3.yAxis})

        punchHitbox = HitboxService.new()
        punchHitbox.CoreMode = true
        punchHitbox.Core = humRoot
        punchHitbox.OffsetIsRelativeTo = {'LookVector'}
        punchHitbox.Offset = {3}
        punchHitbox.Size = Vector3.new(5, 5, 7)
        punchHitbox.OverlapParams = char
        punchHitbox.HitEvent:Connect(function(hit)
            if hit:GetAttribute('Ragdolled') then return end

            DamageService.Damage(hit, char, 10)
            local hitState = StateService.Get(hit)
            hitState:Knockback(char, lookCFrame.LookVector * 40, .2, nil, nil, {Vector3.yAxis})
            local ragdoll = RagdollService.Get(hit)
            ragdoll:Ragdoll(hit, 3)

            SkillService.RouteToClient('Level 100 Punch', char, 'Burst', 'All', {hit})
        end)

        punchHitbox:Start(game.Players:GetPlayerFromCharacter(char))

        local fullyCompleted = false
        skillHandler:AddEvent(punchAnim:GetMarkerReachedSignal('Hit'), function()
            fullyCompleted = true
        end)

        repeat
            task.wait()
        until fullyCompleted or earlyStops[char]

        punchHitbox:Stop()

        skillHandler.CurrentSection = 'Punch'
        state:Superarmor(false)

        SkillService.CoreVoxelDestruction({Core = humRoot, OffsetRelativeTo = {'LookVector'}, Offset = {3}, LaunchDirection = lookCFrame.LookVector * 50},
         Vector3.one * 9, 0, Enum.PartType.Ball, 40, 50, true)
    
        task.wait(1.2)
    end

    skillHandler.CleanUp = function()
        if punchHitbox then
            punchHitbox:Stop()
        end

        state:EndWalkspeed('Level100Punch')
        hum.AutoRotate = true
        -- char:RemoveTag('DisableRotating')

        if skillHandler:HasCompleted(true) then
            state:Superarmor(false)
        end

        SkillService.Cooldown(char, 'Level 100 Punch')
        SkillService.UsingSkill(char, false, 'Level 100 Punch')
    end

    skillHandler:Run()
end

-- skill.Init2 = function(char: Character)
--     earlyStops[char] = true
-- end

return skill