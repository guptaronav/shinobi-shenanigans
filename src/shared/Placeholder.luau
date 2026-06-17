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
local CombatService = Services.CombatService

-- Resources / Assets
local Assets = ReplicatedStorage.Assets
local animations = Assets.Animations
local Remotes = ReplicatedStorage.Remotes

local skill = {}

type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: BasePart}

local groundParams = RaycastParams.new()
groundParams.FilterDescendantsInstances = {workspace.Map}
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.RespectCanCollide = true

skill.Init = function(char)
    -- SkillService.RouteToClient('El Huma', char, 'Init', 'All')
    -- char:SetAttribute('UsingSkill', 'Ice Skate')
    SkillService.UsingSkill(char, true, 'Ice Skate')

    local state = StateService.Get(char)
    state:SetWalkspeed('Ice Skate', 4, 0.01)

    local humRoot = char.HumanoidRootPart
    local hum = char.Humanoid
    hum.JumpHeight = 0

    local skillHandler = SkillService.CreateSkill(char, 'Ice Skate', {
        ['Start'] = 0,
        ['Skate'] = 0,
        ['Attack'] = 2,
    })

    local skateLoopAnim
    local sword
    local target
    local hitState
    skillHandler.Runtime = function()
        -- SkillService.RouteToClient('Ice Skate', char, 'SkateJump', game.Players:GetPlayerFromCharacter(char))

        local tags = {}

        local jumpAnim: AnimationTrack = AnimationService.LoadAnimation(char, animations.HalfDevil.SkateJump, 'Skill')
        jumpAnim:Play()
        jumpAnim:AdjustSpeed(.3)

        skillHandler:AddEvent(jumpAnim:GetMarkerReachedSignal('Pressure'), function()
            local groundRay = workspace:Raycast(humRoot.Position, -Vector3.yAxis * 100, groundParams)
            if groundRay then
                SkillService.VoxelDestruction(CFrame.new(groundRay.Position), Vector3.new(4,1,4), 0, nil, 20, 30, nil, true)
                Remotes.DisplayEffect:FireAllClients(
                'Camera', {
                    Magnitude = 1, Roughness = 4, FadeInTime = .1, FadeOutTime = 1, 
                    PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                    Origin = humRoot.Position, Radius = 20
                })
            end


        end)

        local stillCharging = false
        local requiredPosition:Vector3
        skillHandler:AddEvent(jumpAnim:GetMarkerReachedSignal('Charge'), function()
            jumpAnim:AdjustSpeed(1.5)
            SkillService.RouteToClient('Ice Skate', char, 'Skate', 'All')

			local knockbackHits, hitboxCFrame = Hitbox.instant({Core = humRoot, OffsetIsRelativeTo = {'LookVector'}, Offset = {2.5}}, Vector3.new(10, 5, 14), char, nil, nil, true)

            for _,hit in knockbackHits do
                DamageService.Damage(hit, char, 4)
                table.insert(tags, hit)
                
                local ragdoll = RagdollService.Get(hit)
                ragdoll:Ragdoll_(1.5, {DestructionPower = 4, SizeScale = 1})

                hitState = StateService.Get(hit)
                hitState:Stun('PushOffIceSkate', .7, 3)
                hitState:Knockback(char, hitboxCFrame.LookVector * 50 + Vector3.yAxis * 6, .2, nil, nil)

                requiredPosition = hitboxCFrame.Position + hitboxCFrame.LookVector * 20

                -- local alignment = Instance.new('AlignPosition')
                -- alignment.Position = hitboxCFrame.Position + hitboxCFrame.LookVector * 20
                -- alignment.Responsiveness = 20
                -- -- alignment.RigidityEnabled = true
                -- alignment.MaxAxesForce = Vector3.new(30000, 0, 30000)
                -- alignment.ForceRelativeTo = Enum.ActuatorRelativeTo.World
                -- alignment.Attachment0 = hit.HumanoidRootPart.RootAttachment
                -- alignment.ForceLimitMode = Enum.ForceLimitMode.PerAxis
                -- alignment.Mode =Enum.PositionAlignmentMode.OneAttachment
                -- alignment.Parent = hit.HumanoidRootPart
                -- task.delay(1.5, function()
                --     alignment:Destroy()
                -- end)
            end
        end)

        skillHandler:AddEvent(jumpAnim:GetMarkerReachedSignal('FollowUp'), function()
            -- warn('Event is working trust')
            skillHandler.CurrentSection = 'Attack'
            -- local target = Hitbox.instant({Core = humRoot, OffsetIsRelativeTo = {'LookVector'}, Offset = {3}}, Vector3.one * 6, char, nil, true, true)
            -- target = Hitbox.instant({Core = humRoot, OffsetIsRelativeTo = {'LookVector'}, Offset = {3}}, Vector3.new(6,5,9), char, nil, true, true)

            if requiredPosition and (humRoot.Position - requiredPosition).Magnitude <= 11 then
                local closestDistance = math.huge
                for _,v in tags do
                    local dist = (v.HumanoidRootPart.Position - requiredPosition).Magnitude
                    if v:FindFirstChild('HumanoidRootPart') and dist < closestDistance and v:GetAttribute('Ragdolled') then
                        target = v
                        closestDistance = dist
                    end
                end
            end

            if target and table.find(tags, target) then
                skillHandler.CurrentSection = 'Attack'
                SkillService.RouteToClient('Ice Skate', char, 'EndSkate', 'All')

                if target:GetAttribute('Superamor') or target:GetAttribute('IFrame') then return end
                if target:GetAttribute('Blocking') then
                    if CombatService.Blockable(target, char) then
                        target = false
                        return
                    else
                        CombatService.Block(target, false)
                    end
                end

                state:SetWalkspeed('Ice Skate', 4, .1)

                local weapon = char:FindFirstChild('Weapon')
                if weapon then
                    weapon.Handle.Transparency = 1
                end

                hitState = StateService.Get(target)
                hitState:Stun('ElHumaGrab', nil, 3)
                SkillService.Grab(char, target, (humRoot.CFrame + humRoot.CFrame.LookVector * 4) * CFrame.Angles(0, math.rad(180), 0))

                
                -- Add animation attack here and whatever
                local victimAnim = AnimationService.LoadAnimation(target, animations.HalfDevil.SkateAttack.Victim, 'TargetSkill')
                victimAnim:Play()

                SkillService.RouteToClient('Ice Skate', char, 'AttackVelocity', game.Players:GetPlayerFromCharacter(char))
                
                local attackAnim = AnimationService.LoadAnimation(char, animations.HalfDevil.SkateAttack.User, 'Skill')
                attackAnim:Play()

                attackAnim:GetMarkerReachedSignal('SwordSpawn'):Once(function()
                    sword = Assets.SkillAssets.HalfDevil.Weapons.Sword:Clone()
                    sword.Parent = char

                    local motor = Instance.new('Motor6D')
                    motor.Name = 'Handle'
                    motor.Parent = char['Right Arm']
                    motor.Part0 = char['Right Arm']
                    motor.Part1 = sword.Handle
                    motor.C0 = CFrame.new(0.10000038146972656, -0.9856352806091309, -1.5883512496948242, -2.9103830456733704e-11, 1, -7.28278548578487e-12, 1, -2.9103830456733704e-11, 5.820766091346741e-11, -5.820766091346741e-11, 7.28278548578487e-12, -1)
                end)

                for i=1, 3 do
                    attackAnim:GetMarkerReachedSignal('Hit'..i):Wait()
                    DamageService.Damage(target, char, 3, true)
                end

                attackAnim:GetMarkerReachedSignal('Launch'):Wait()

                DamageService.Damage(target, char, 2)

                local blastCFrame = CFrame.lookAt(humRoot.Position + humRoot.CFrame.LookVector*10 + Vector3.yAxis * 2.5, humRoot.Position + humRoot.CFrame.LookVector*20 + Vector3.yAxis * 5)
                SkillService.VoxelDestruction(blastCFrame, Vector3.new(5, 5, 20), 0, nil, 60, 70, humRoot.CFrame.LookVector * 40 + Vector3.yAxis * 6)

                SkillService.EndGrab(char)

                hitState:UnStun('ElHumaGrab')
                
                local ragdoll = RagdollService.Get(target)
                ragdoll:Ragdoll_(3, {DestructionPower = 18, SizeScale = .55, GainVerticalVelocity = true, Delay = .2})

                hitState:Knockback(char, humRoot.CFrame.LookVector * 65 + Vector3.yAxis * 20, .2)
            else

                skateLoopAnim = AnimationService.LoadAnimation(char, animations.HalfDevil.SkateAttack.SkateLoop, 'Skill')
                skateLoopAnim:Play()

                local hitbox = Hitbox.new()
                hitbox.CoreMode = true
                hitbox.Core = humRoot
                hitbox.OverlapParams = char
                hitbox.Size = Vector3.new(5,5,5)

                hitbox.HitEvent:Connect(function(target)
                    DamageService.Damage(target, char, 4)
                    
                    local ragdoll = RagdollService.Get(target)
                    ragdoll:Ragdoll_(1.5, {DestructionPower = 4, SizeScale = 1})

                    hitState = StateService.Get(target)
                    hitState:Stun('PushOffIceSkate', .7, 3)
                    hitState:Knockback(char, humRoot.CFrame.LookVector * 60, .2, nil, nil, {Vector3.yAxis})
                end)

                hitbox:Start(game.Players:GetPlayerFromCharacter(char))

                local ev = skillHandler:AddEvent(jumpAnim.Stopped, function()
                    SkillService.RouteToClient('Ice Skate', char, 'Fail', game.Players:GetPlayerFromCharacter(char))
                    
                    local skateFailAnim = AnimationService.LoadAnimation(char, Assets.Animations.HalfDevil.SkateAttack.SkateFail, 'Skill')
                    skateFailAnim:Play()
                    skateFailAnim:AdjustSpeed(.6)
                    skateFailAnim.Stopped:Wait()
                end)

                task.wait(.4)

                hitbox:Stop()

                skateLoopAnim:Stop()
                SkillService.RouteToClient('Ice Skate', char, 'EndSkate', 'All')

                ev:Wait()
            end

            hum.JumpHeight = game.StarterPlayer.CharacterJumpHeight
        end):Wait()
    end

    skillHandler.CleanUp = function()
        state:EndWalkspeed('Ice Skate')

        SkillService.Cooldown(char, 'Ice Skate')
        -- char:SetAttribute('UsingSkill', nil)
        SkillService.UsingSkill(char, false, 'Ice Skate')
        -- SkillService.RouteToClient('Ice Skate', char, 'EndSkate', 'All')

        if skillHandler:HasCompleted(true) then
            SkillService.EndGrab(char)
            if skateLoopAnim then skateLoopAnim:Stop() end
            
            if hitState then
                hitState:UnStun('ElHumaGrab')
            end

            if skillHandler.CurrentSection == 'Skate' then
                SkillService.RouteToClient('Ice Skate', char, 'EndSkate', 'All')
            end
        end

        local weapon = char:FindFirstChild('Weapon')
            if weapon then
                weapon.Handle.Transparency = 0
            end

        if sword then
            sword:Destroy()
        end
    end

    skillHandler:Run()
end


-- skill.Init = function(char)
--     -- SkillService.RouteToClient('El Huma', char, 'Init', 'All')
--     -- char:SetAttribute('UsingSkill', 'Ice Skate')
--     SkillService.UsingSkill(char, true, 'Ice Skate')

--     local state = StateService.Get(char)
--     state:SetWalkspeed('Ice Skate', 4, 0.01)

--     local humRoot = char.HumanoidRootPart
--     local hum = char.Humanoid
--     hum.JumpHeight = 0

--     local skillHandler = SkillService.CreateSkill(char, 'Ice Skate', {
--         ['Start'] = 0,
--         ['Skate'] = 2,
--         ['Attack'] = 1,
--     })

--     local skateLoopAnim
--     local sword
--     local hitState
--     skillHandler.Runtime = function()
--         SkillService.RouteToClient('Ice Skate', char, 'SkateJump', game.Players:GetPlayerFromCharacter(char))

--         -- state:Velocity(humRoot.CFrame.LookVector * 30 + Vector3.yAxis * 5, .8)
--         -- task.delay(.8, function()
--         --     state:Velocity(humRoot.CFrame.LookVector * 30, .6, nil, {Vector3.yAxis})
--         -- end)

--         local jumpAnim: AnimationTrack = AnimationService.LoadAnimation(char, animations.HalfDevil.SkateJump, 'Skill')
--         jumpAnim:Play()
--         jumpAnim.Stopped:Wait()

--         skillHandler.CurrentSection = 'Skate'

--         skateLoopAnim = AnimationService.LoadAnimation(char, animations.HalfDevil.SkateAttack.SkateLoop, 'Skill')
--         skateLoopAnim:Play()

--         SkillService.RouteToClient('Ice Skate', char, 'Skate', 'All')

--         local hitbox = Hitbox.new()
--         hitbox.CoreMode = true
--         hitbox.Core = humRoot
--         hitbox.OffsetIsRelativeTo = {'LookVector'}
--         hitbox.Offset = {5}
--         hitbox.OverlapParams = char
--         hitbox.Single = true
--         hitbox.Size = Vector3.one * 5

--         local target: Character = nil

--         hitbox.HitEvent:Connect(function(hit)
--             if hit:GetAttribute('Superamor') or hit:GetAttribute('IFrame') or hit:GetAttribute('Ragdolled') then return end
--             if hit:GetAttribute('Blocking') then
--                 if CombatService.Blockable(hit, char) then
--                     target = false
--                     return
--                 else
--                     CombatService.Block(hit, false)
--                 end
--             end

--             print(hit)

--             target = hit
--         end)

--         hitbox:Start(game.Players:GetPlayerFromCharacter(char))
--         -- hitbox:Start()

--         local exhaust = os.clock()
--         repeat task.wait() until os.clock() - exhaust > 2 or target or target == false

--         SkillService.RouteToClient('Ice Skate', char, 'EndSkate', 'All')

--         hitbox:Stop()

--         skateLoopAnim:Stop()

--         if target and target ~= false then
--             skillHandler.CurrentSection = 'Attack'

--             state:SetWalkspeed('Ice Skate', 4, .1)

--             local weapon = char:FindFirstChild('Weapon')
--             if weapon then
--                 weapon.Handle.Transparency = 1
--             end

--             hitState = StateService.Get(target)
--             hitState:Stun('ElHumaGrab', nil, 3)
--             SkillService.Grab(char, target, (humRoot.CFrame + humRoot.CFrame.LookVector * 4) * CFrame.Angles(0, math.rad(180), 0))

            
--             -- Add animation attack here and whatever
--             local victimAnim = AnimationService.LoadAnimation(target, animations.HalfDevil.SkateAttack.Victim, 'TargetSkill')
--             victimAnim:Play()

--             SkillService.RouteToClient('Ice Skate', char, 'AttackVelocity', game.Players:GetPlayerFromCharacter(char))
            
--             local attackAnim = AnimationService.LoadAnimation(char, animations.HalfDevil.SkateAttack.User, 'Skill')
--             attackAnim:Play()

--             attackAnim:GetMarkerReachedSignal('SwordSpawn'):Once(function()
--                 sword = Assets.SkillAssets.HalfDevil.Weapons.Sword:Clone()
--                 sword.Parent = char

--                 local motor = Instance.new('Motor6D')
--                 motor.Name = 'Handle'
--                 motor.Parent = char['Right Arm']
--                 motor.Part0 = char['Right Arm']
--                 motor.Part1 = sword.Handle
--                 motor.C0 = CFrame.new(0.10000038146972656, -0.9856352806091309, -1.5883512496948242, -2.9103830456733704e-11, 1, -7.28278548578487e-12, 1, -2.9103830456733704e-11, 5.820766091346741e-11, -5.820766091346741e-11, 7.28278548578487e-12, -1)
--             end)

--             for i=1, 3 do
--                 attackAnim:GetMarkerReachedSignal('Hit'..i):Wait()
--                 DamageService.Damage(target, char, 3, true)
--             end

--             attackAnim:GetMarkerReachedSignal('Launch'):Wait()

--             DamageService.Damage(target, char, 2)

--             local blastCFrame = CFrame.lookAt(humRoot.Position + humRoot.CFrame.LookVector*10 + Vector3.yAxis * 2.5, humRoot.Position + humRoot.CFrame.LookVector*20 + Vector3.yAxis * 5)
--             SkillService.VoxelDestruction(blastCFrame, Vector3.new(5, 5, 20), 0, nil, 60, 70, humRoot.CFrame.LookVector * 40 + Vector3.yAxis * 6)

--             SkillService.EndGrab(char)

--             hitState:UnStun('ElHumaGrab')
--             hitState:Knockback(char, humRoot.CFrame.LookVector * 65 + Vector3.yAxis * 20, .2)
            
--             local ragdoll = RagdollService.Get(target)
--             ragdoll:Ragdoll_(3, {DestructionPower = 18, SizeScale = .55, GainVerticalVelocity = true, Delay = .2})

--             task.wait(.5)
--             -- Hitbox.CollisionEvent(target, function(collidedPart, direction, ray)
--                 -- SkillService.CoreVoxelDestruction({Core = target.HumanoidRootPart, LaunchDirection = humRoot.CFrame.LookVector * 30}, Vector3.one * 7, 0, nil, 30, 40)
--             -- end, 2, nil, 1, false)
--         end

--         hum.JumpHeight = game.StarterPlayer.CharacterJumpHeight
--     end

--     skillHandler.CleanUp = function()
--         state:EndWalkspeed('Ice Skate')

--         SkillService.Cooldown(char, 'Ice Skate')
--         -- char:SetAttribute('UsingSkill', nil)
--         SkillService.UsingSkill(char, false, 'Ice Skate')

--         if skillHandler:HasCompleted(true) then
--             SkillService.EndGrab(char)
--             if skateLoopAnim then skateLoopAnim:Stop() end
            
--             if hitState then
--                 hitState:UnStun('ElHumaGrab')
--             end

--             if skillHandler.CurrentSection == 'Skate' then
--                 SkillService.RouteToClient('Ice Skate', char, 'EndSkate', 'All')
--             end
--         end

--         local weapon = char:FindFirstChild('Weapon')
--             if weapon then
--                 weapon.Handle.Transparency = 0
--             end

--         if sword then
--             sword:Destroy()
--         end
--     end

--     skillHandler:Run()
-- end

return skill