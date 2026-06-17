local Prom = require(game.ReplicatedStorage.Shared.Services.Promise)
local StateService = require(game.ServerStorage.RojoStorage.Modules.StateService)
local RagdollService = require(game.ServerStorage.RojoStorage.Modules.RagdollService)
local SkillService = require(game.ReplicatedStorage.Shared.Services.SkillService)
local Hitbox = require(game.ReplicatedStorage.Shared.Services.Hitbox)
local DamageService = require(game.ServerStorage.RojoStorage.Modules.DamageService)
local VoxelService = require(game.ReplicatedStorage.Shared.Services.VoxelService)
local WeldService = require(game.ReplicatedStorage.Modules.WeldService)
local AnimationService = require(game.ReplicatedStorage.Shared.Services.AnimationService)
-- local VoxelService = require(game.ReplicatedStorage.Shared.Services.VoxelService2)
local utility = require(game.ReplicatedStorage.Modules.Utility)
local BezierCurve = require(game.ReplicatedStorage.Modules.bezierCurve)

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local ts = game:GetService('TweenService')

-- Ex: 'Unfreeze', Vector3.one * 14, hit.HumanoidRootPart.CFrame, Enum.PartType.Ball, nil, 20
type VoxelSender = {
    FireAllClients: (
        _self: VoxelSender, Type: string, Size: Vector3, Origin: CFrame, Shape: Enum.PartType?, MinimumVoxelSize: number?, VoxelDuration: number, LaunchDirection: Vector3?
    ) -> nil,
}
local Voxelize: VoxelSender = game.ReplicatedStorage.Remotes.Voxelize

type Character = Model
type SkillRoute = {
    FireClient: (_self: SkillRoute, Player: Player, Skill: string, Character: Character, Route: string, any) -> nil,
    FireAllClients: (_self: SkillRoute, Skill: string, Character: Character, Route: string, any) -> nil
}

local skillRoute: SkillRoute = game.ReplicatedStorage.Remotes.SkillRoute
local animations = game.ReplicatedStorage.Assets.Animations

local sk_server = {}
sk_server['Rental Goa'] = {}

local selfGoaTimings = {}

sk_server['Rental Goa'].Init = function(char: Character, extra: table)
    SkillService.UsingSkill(char, true, 'Rental Goa')

    local state = StateService.Get(char)
    state:SetWalkspeed('RentalGoaCast', 4, 0)
    state:Superarmor(true)

    local humRoot = char.HumanoidRootPart
    local hum: Humanoid = char.Humanoid
    -- hum.AutoRotate = false

    -- Global variables
    local laSpirit: BasePart
    --

    local skillHandler = SkillService.CreateSkill(char, 'Rental Goa', {
        ['Start'] = 4,
    })

    skillHandler.Runtime = function()
        AnimationService.AddHands(char, 'Right')
        local castAnim = AnimationService.LoadAnimation(char, animations.SpiritKnight.RentalGoa, 'Skill')
        castAnim:Play()

        castAnim:GetMarkerReachedSignal('Spawn'):Wait()

        laSpirit = ReplicatedStorage.Assets.SkillAssets.SpiritKnight.LaSpirit:Clone()
        laSpirit.Name = 'LaSpirit/'..char.Name
        laSpirit.Parent = workspace.UnobstructiveAssets
        laSpirit.Anchored = false

        local accurateHumRootCFrame = SkillService.RouteToClient('Rental Goa', char, 'LookCFrame_Return', game.Players:GetPlayerFromCharacter(char))
        if accurateHumRootCFrame then
            laSpirit.CFrame = humRoot.CFrame + humRoot.CFrame.LookVector * 4.6 + humRoot.CFrame.RightVector * .8 + humRoot.CFrame.UpVector
        else
            laSpirit.CFrame = humRoot.CFrame + humRoot.CFrame.LookVector * 4.6 + humRoot.CFrame.RightVector * .8 + humRoot.CFrame.UpVector
        end

        local weld = Instance.new('WeldConstraint')
        weld.Part0 = laSpirit
        weld.Part1 = humRoot
        weld.Parent = laSpirit

        selfGoaTimings[char] = os.clock()

        local hasFired = false

        castAnim:GetMarkerReachedSignal('Fire'):Once(function()
            hasFired = true
        end)

        repeat
            task.wait()
        until hasFired or selfGoaTimings[char] == true

        if selfGoaTimings[char] == true then
            castAnim:Stop()
            return
        else
            selfGoaTimings[char] = nil
            castAnim.Stopped:Once(function()
                AnimationService.RemoveHands(char, 'Right')
            end)
        end

        skillHandler.CurrentSection = 'Fire'
        
        laSpirit.Anchored = true
        weld:Destroy()

        local accurateHumRootCFrame = SkillService.RouteToClient('Rental Goa', char, 'LookCFrame_Return', game.Players:GetPlayerFromCharacter(char))
        if accurateHumRootCFrame then
            laSpirit.CFrame = humRoot.CFrame + humRoot.CFrame.LookVector * 4 + humRoot.CFrame.RightVector * .5
        else
            laSpirit.CFrame = humRoot.CFrame + humRoot.CFrame.LookVector * 4 + humRoot.CFrame.RightVector * .5
        end

        local hitbox = Hitbox.new()
        hitbox.CoreMode = true
        hitbox.Core = laSpirit
        hitbox.Size = Vector3.one * 4
        hitbox.OverlapParams.FilterDescendantsInstances = {char}
        hitbox.Single = true

        state:Superarmor(false)
    
        local tween = ts:Create(laSpirit, TweenInfo.new(.8), {CFrame = laSpirit.CFrame + laSpirit.CFrame.LookVector * 12})
        
        hitbox.HitEvent:Connect(function()
            tween:Cancel()
        end)

        hitbox:Start()
        tween:Play()
        
        repeat task.wait() until tween.PlaybackState == Enum.PlaybackState.Completed or tween.PlaybackState == Enum.PlaybackState.Cancelled
        hitbox:Stop()

        SkillService.VoxelDestruction(laSpirit.CFrame, Vector3.one * 8, 20, Enum.PartType.Ball, 40, 50, 'Explosion_45')

        local hits = Hitbox.instant(laSpirit.CFrame, Vector3.one * 7, char)
        for _, hit in hits do
            DamageService.Damage(hit, char, 7)
            local hitState = StateService.Get(hit)
            local ragdoll = RagdollService.Get(hit)
            ragdoll:Ragdoll(hit, 3)
            hitState:Knockback(char, (hit.HumanoidRootPart.Position - laSpirit.Position).Unit * 20, .2, nil, nil, {Vector3.yAxis})
        end

        SkillService.RouteToClient('Rental Goa', char, 'Explosion', 'All', laSpirit)
    end

    skillHandler.CleanUp = function()
        state:EndWalkspeed('RentalGoaCast')
        hum.AutoRotate = true

        if skillHandler:HasCompleted(true) then
            state:Superarmor(false)
        end
        if laSpirit then
            laSpirit:Destroy()
        end

        SkillService.Cooldown(char, 'Rental Goa')
        if selfGoaTimings[char] ~= true then
            SkillService.UsingSkill(char, false, 'Rental Goa')
        end
    end

    skillHandler:Run()
end

sk_server['Rental Goa'].Init2 = function(char: Character, extra: table)
    if not selfGoaTimings[char] then
        return false
    end
    selfGoaTimings[char] = true

    -- SkillService.UsingSkill(char, true, 'Self Goa')

    local state = StateService.Get(char)
    state:SetWalkspeed('SelfGoaCast', 4, 0)

    local humRoot = char.HumanoidRootPart
    local hum: Humanoid = char.Humanoid
    hum.AutoRotate = false

    -- Global variables
    
    --

    local skillHandler = SkillService.CreateSkill(char, 'Self Goa', {
        -- ['Start'] = 0,
    })

    local laSpirit: BasePart = workspace.UnobstructiveAssets:FindFirstChild('LaSpirit/'..char.Name)
    skillHandler.Runtime = function()
        if not laSpirit then return end 

        local castAnim = AnimationService.LoadAnimation(char, animations.SpiritKnight.SelfGoa, 'Skill')
        castAnim:Play()

        castAnim.Stopped:Wait()
        task.wait(.02)

        SkillService.VoxelDestruction(laSpirit.CFrame, Vector3.one * 20, 20, Enum.PartType.Ball, 40, 50, 'Explosion_50')

        local hits = Hitbox.instant(laSpirit.CFrame, Vector3.one * 15)
        for _, hit in hits do
            if hit == char then
                DamageService.Damage(hit, char, 11)
            else
                DamageService.Damage(hit, char, 12)
            end
            local hitState = StateService.Get(hit)
            local ragdoll = RagdollService.Get(hit)
            ragdoll:Ragdoll(hit, 3)
            hitState:Knockback(char, (hit.HumanoidRootPart.Position - laSpirit.Position).Unit * 28, .2, nil, nil, {Vector3.yAxis})
        end

        SkillService.RouteToClient('Rental Goa', char, 'Explosion', 'All', laSpirit)

        if laSpirit then
            laSpirit:Destroy()
        end
    end

    skillHandler.CleanUp = function()
        -- print('are you even cleaning up')
        state:EndWalkspeed('SelfGoaCast')
        hum.AutoRotate = true

        if skillHandler:HasCompleted(true) then
            if laSpirit then
                laSpirit:Destroy()
            end
        end

        SkillService.UsingSkill(char, false, 'Rental Goa')
        AnimationService.RemoveHands(char, 'Right')
    end

    skillHandler:Run()
end

sk_server['Level 100 Punch'] = {}
sk_server['Level 100 Punch'].Init = function(char: Character)
    SkillService.UsingSkill(char, true, 'Level 100 Punch')

    local state = StateService.Get(char)
    state:SetWalkspeed('Level100Punch', 4, 0.01)

    local humRoot = char.HumanoidRootPart
    local hum: Humanoid = char.Humanoid
    -- hum.AutoRotate = false

    -- Global variables
    

    local skillHandler = SkillService.CreateSkill(char, 'Level 100 Punch', {
        ['Start'] = 0,
        ['Run'] = 1,
    })

    skillHandler.Runtime = function()
        local punchAnim = AnimationService.LoadAnimation(char, animations.SpiritKnight.HeavyPunch, 'Skill')
        punchAnim:Play()

        punchAnim:GetMarkerReachedSignal('Move'):Wait()
        skillHandler.CurrentSection = 'Run'
        state:Superarmor(true)

        SkillService.RouteToClient('Level 100 Punch', char, 'Run', 'All')
        local lookCFrame = SkillService.RouteToClient('Rental Goa', char, 'LookCFrame_Return', game.Players:GetPlayerFromCharacter(char))
        state:Velocity(lookCFrame.LookVector * 65, .35, nil, {Vector3.yAxis})

        punchAnim:GetMarkerReachedSignal('Hit'):Wait()
        skillHandler.CurrentSection = 'Punch'
        state:Superarmor(false)

        local lookCFrame = SkillService.RouteToClient('Rental Goa', char, 'LookCFrame_Return', game.Players:GetPlayerFromCharacter(char))

        local hits = Hitbox.instant({Core = humRoot, OffsetIsRelativeTo = {'LookVector'}, Offset = {3}}, Vector3.one * 7, char, nil, nil, game.Players:GetPlayerFromCharacter(char))
        for _,hit in hits do
            DamageService.Damage(hit, char, 10)
            local hitState = StateService.Get(hit)
            hitState:Knockback(char, lookCFrame.LookVector * 40, .2, nil, nil, {Vector3.yAxis})
            local ragdoll = RagdollService.Get(hit)
            ragdoll:Ragdoll(hit, 3)
        end
        SkillService.CoreVoxelDestruction({Core = humRoot, OffsetRelativeTo = {'LookVector'}, Offset = {3}, LaunchDirection = lookCFrame.LookVector * 50},
         Vector3.one * 9, 0, Enum.PartType.Ball, 40, 50, true)

        SkillService.RouteToClient('Level 100 Punch', char, 'Burst', 'All', hits)
    
        task.wait(1.2)
    end

    skillHandler.CleanUp = function()
        state:EndWalkspeed('Level100Punch')
        hum.AutoRotate = true

        if skillHandler:HasCompleted(true) then
            state:Superarmor(false)
        end

        SkillService.Cooldown(char, 'Level 100 Punch')
        SkillService.UsingSkill(char, false, 'Level 100 Punch')
    end

    skillHandler:Run()
end

sk_server['Shamak'] = {}
sk_server['Shamak'].Init = function(char)
    char:SetAttribute('UsingSkill', 'Shamak')

    local humRoot = char.HumanoidRootPart
    local hum = char.Humanoid

    -- local ORIGIN = humRoot.Position
    -- local TIMER = os.clock()

    local caught = {}

    local skillHandler = SkillService.CreateSkill(char, 'Shamak', {
        ['Start'] = 0,
        ['FollowUpAttack'] = 1,
    })

    skillHandler.Runtime = function()
        local cState = StateService.Get(char)
        cState:Superarmor(true)
        cState:SetWalkspeed('ShamakCast', 5, 10)
        
        local shamakBlock = game.ReplicatedStorage.Assets.SkillAssets.Shamak:Clone()
        local att: Attachment = shamakBlock:WaitForChild("Attachment")
        shamakBlock.Parent = workspace.UnobstructiveAssets
        shamakBlock.CFrame = humRoot.CFrame + Vector3.yAxis
        utility.Weld(shamakBlock, humRoot)

        local shamakCastAnim: AnimationTrack = char.Humanoid.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.SkillAnimations.Shamak)
        shamakCastAnim:Play()
        -- shamakCastAnim:GetMarkerReachedSignal('Pause'):Wait()
        -- shamakCastAnim:AdjustSpeed(.9)

        -- shamakCastAnim:GetMarkerReachedSignal('Spawn'):Wait()
        task.wait(.2)
        att:WaitForChild('SmokeParticles').TimeScale = 4
        att:WaitForChild('SmokeParticles'):Emit(20)
        task.wait(.4)
        -- task.wait(.1)
        

        local hits = Hitbox.instant(humRoot.CFrame + humRoot.CFrame.LookVector * 3, Vector3.new(6, 2, 4), char)
        for _,v in hits do
            table.insert(caught, v)

            local hitState = StateService.Get(v)
            hitState:Stun('ShamakHit', 2, 2)

            local plr = game.Players:GetPlayerFromCharacter(v)
            if plr then
                skillRoute:FireClient(plr, 'Shamak', char, 'ShamakHit')
            end

            local blindnessAnim = hum.Animator:LoadAnimation(animations.SpiritKnight.ShamakBlindness)
            blindnessAnim:Play()
        end

        local function FollowUpAttack(target)
            -- local inBetween = (target.HumanoidRootPart.Position - humRoot.Position)

            -- humRoot.CFrame = CFrame.lookAt(humRoot.Position + inBetween - (inBetween.Unit * 2.5), target.HumanoidRootPart.Position)
            -- humRoot.CFrame += inBetween - (inBetween.Unit * 2.5)
            task.wait(.6)

            local punchAnim = char.Humanoid.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.Punches.Punch3)
            punchAnim:Play()

            task.wait(.2)

            local punchHits = Hitbox.instant(humRoot.CFrame + humRoot.CFrame.LookVector * 3, Vector3.new(5, 1.5, 3.5), char)
            for _,v in punchHits do
                DamageService.Damage(target, char, 3)
            
                local tState = StateService.Get(v)
                tState:Stun('ShamakPunch', 2, 1)

                tState:Knockback(char, humRoot.CFrame.LookVector * 25, .3)

                v.HumanoidRootPart.CFrame = CFrame.lookAt(v.HumanoidRootPart.Position, humRoot.Position)

                local stomachDamageTrans = v.Humanoid.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.EMM.StomachDamageTransition)
                stomachDamageTrans:Play()
                stomachDamageTrans.Stopped:Wait()
                local stomachDamage = v.Humanoid.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.EMM.StomachDamage)
                stomachDamage:Play()
                task.delay(1.75, function()
                    stomachDamage:Stop()
                end)
            end

            
            -- local ragdoll = RagdollService.Get(target)
            -- ragdoll:Ragdoll(target, 1.8)
            -- local tState = StateService.Get(target)
            -- tState:Knockback(char, humRoot.CFrame.LookVector * 150, .75, nil, true)    
        end

        local target = SkillService.GetTarget(char, caught, true)
        print('Target:',target)
        if target then
            FollowUpAttack(target) -- YIELDS (.13 secs max)
        else
            task.wait(.5)
        end
    end

    skillHandler.CleanUp = function()
        SkillService.Cooldown(char, 'Shamak')
        char:SetAttribute('UsingSkill', nil)

        local cState = StateService.Get(char)

        cState:Superarmor(false)
        cState:EndWalkspeed('ShamakCast')
    end

    skillHandler:Run()
end

local murakAnims = animations.Murak
sk_server['Murak'] = {}
sk_server['Murak'].Init = function(char: Model)
    SkillService.UsingSkill(char, true, 'Murak')

    local hum = char.Humanoid
    local humRoot = char.HumanoidRootPart
    -- humRoot.Anchored = true

    local skillHandler = SkillService.CreateSkill(char, 'Murak', {
        ['Start'] = 0,
        ['Rush'] = 2,
    })

    local userState = StateService.Get(char)
    local hitState; local ragdoll
    local rushHit: Character
    skillHandler.Runtime = function()
        
        userState:SetWalkspeed('Murak', 5, 0)
        -- char:SetAttribute('WalkSpeedDisabled', true)
        hum.AutoRotate = false

        task.wait(.4)

        skillHandler.CurrentSection = 'Rush'

        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char, workspace.UnobstructiveAssets}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude

        local DISTANCE: number = 40

        -- local ray = workspace:Raycast(humRoot.Position + humRoot.CFrame.LookVector * DISTANCE, -Vector3.yAxis * 300, rayParams)
        -- if not ray or not ray.Instance then
        --     while not ray or not ray.Instance do
        --         DISTANCE -= 4
        --         ray = workspace:Raycast(humRoot.Position + humRoot.CFrame.LookVector * DISTANCE, -Vector3.yAxis * 300, rayParams)

        --         if DISTANCE < 0 then
        --             DISTANCE = 40
        --             break
        --         end
        --     end
        -- end

        rushHit = Hitbox.instant(humRoot.CFrame + humRoot.CFrame.LookVector * DISTANCE/2, Vector3.new(10, 4, DISTANCE), char,nil, true, game.Players:GetPlayerFromCharacter(char))
        
        if not rushHit then
            return
        end

        local inBetween: Vector3 = (rushHit.HumanoidRootPart.Position - humRoot.Position)
        
        -- Unfreezes all voxels in rush path
        SkillService.CoreVoxelDestruction({Core = humRoot, OffsetRelativeTo = {'LookVector'}, Offset = {(inBetween.Magnitude+5)/2}}, Vector3.new(15, 7, inBetween.Magnitude+5), 0, nil, 40, 50, true)
        -- Voxelize:FireAllClients('Unfreeze', Vector3.new(15, 7, inBetween.Magnitude + 5), humRoot.CFrame + humRoot.CFrame.LookVector * (inBetween.Magnitude+5)/2, nil, nil, 20, humRoot.CFrame.LookVector * 100)

        humRoot.CFrame += humRoot.CFrame.LookVector * inBetween.Magnitude

        -- local weldPart: BasePart = WeldService.Setup(char, rushHit, CFrame.lookAt(CFrame.new(0,0,-3).Position ,humRoot.Position))
        SkillService.Grab(char, rushHit, char.HumanoidRootPart.CFrame.LookVector * 4)

        -------------------------------------------------------------
        skillHandler.CurrentSection = 'RushFollowUp'

        hitState = StateService.Get(rushHit)
        hitState:Stun('MurakRushHit', nil, 3)

        local plr = game.Players:GetPlayerFromCharacter(char)

        -- userState:SetWalkspeed('MurakRush', 6, 28)
        -- hum:MoveTo(humRoot.Position + humRoot.CFrame.LookVector * 30)

        local voxelizing = true
        task.defer(function()
            while task.wait(.07) and voxelizing do
                SkillService.CoreVoxelDestruction({Core = humRoot, OffsetRelativeTo = {'LookVector'}, Offset = {5}}, Vector3.one * 8, 2.5, nil, 40, 50, true)
            end
        end)

        userState:Velocity(humRoot.CFrame.LookVector * 32, .5, nil, {Vector3.yAxis})

        task.wait(.5)
        userState:IFrame(true)

        -- WeldService.UpdateOffset(rushHit, CFrame.new(CFrame.new(-1,0,-3).Position - Vector3.yAxis * 2.5))

        skillRoute:FireAllClients('Murak', char, 'Slam', rushHit)

        for i=1, 10 do
            DamageService.Damage(rushHit, char, 1, true) 
            task.wait(.2)
        end

        voxelizing = false
        -- userState:EndWalkspeed('MurakRush')
        --------------------------------------------------------------
        task.wait(.5)
        skillHandler.CurrentSection = 'Attack'

        local skyVelocity = Instance.new('BodyVelocity')
        skyVelocity.Velocity = Vector3.yAxis * 200
        skyVelocity.MaxForce = Vector3.yAxis * 200000
        skyVelocity.Parent = humRoot

        local orientation = Instance.new('AlignOrientation')
        orientation.Responsiveness = 3
        orientation.Attachment0 = humRoot.RootAttachment
        orientation.CFrame = humRoot.CFrame
        orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        orientation.RigidityEnabled = true
        
        local keepRotating = true
        task.defer(function()
            local deg = 0
            while task.wait() and keepRotating do
                deg += 10
                orientation.CFrame = CFrame.Angles(0, math.rad(deg), 0)
            end
        end)

        orientation.Parent = humRoot

        local tween = ts:Create(skyVelocity, TweenInfo.new(.5), {Velocity = Vector3.yAxis * 20})
        tween:Play()
        tween.Completed:Wait()

        task.wait(1)

        skyVelocity:Destroy()
        humRoot.Anchored = true
        
        task.wait(.2)

        -- hitState:Knockback(char, Vector3.yAxis * 500, .5, nil, true)
        -- humRoot.CFrame = CFrame.lookAt(rushHit.HumanoidRootPart.Position - humRoot.CFrame.LookVector * 3, rushHit.HumanoidRootPart.Position)
        local alignPosition = Instance.new('AlignPosition')
        alignPosition.Attachment0 = humRoot.RootAttachment
        alignPosition.Position = humRoot.Position
        alignPosition.RigidityEnabled = true
        alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
        alignPosition.Parent = humRoot

        -- orientation:Destroy()
        local ao = Instance.new('AlignOrientation')
        -- ao.Attachment0 = humRoot.RootAttachment
        -- ao.Attachment1 = humRoot.RootAttachment
        -- -- ao.PrimaryAxis = Vector3.zAxis
        -- -- ao.PrimaryAxisOnly = true
        -- -- ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
        -- -- ao.CFrame = CFrame.lookAt(humRoot.Position, rushHit.HumanoidRootPart.Position)
        -- ao.MaxTorque = 100000
        -- ao.RigidityEnabled = true
        -- ao.Parent = humRoot

        hum.AutoRotate = true

        
        skillRoute:FireClient(plr, 'Murak', char, 'Aim')

        task.wait(.6)
        -- task.wait(5)

        -- local leapAttackAnim = hum.Animator:LoadAnimation(murakAnims.LeapAttack)
        -- leapAttackAnim:Play()
        -- leapAttackAnim:AdjustSpeed(1.5)
        -- leapAttackAnim.Stopped:Wait()

        local mouseCFrame: CFrame = SkillService.GetMouse(char, 'Murak')
        if not mouseCFrame then
            mouseCFrame = humRoot.CFrame
        end

        SkillService.EndGrab(char, true)
        
        orientation:Destroy()
        alignPosition:Destroy()

        -- 
        ragdoll = RagdollService.Get(rushHit)
        ragdoll:Ragdoll(rushHit)
        hitState:Knockback(char, (mouseCFrame.Position - humRoot.Position).Unit * 160, .3)

        Hitbox.CollisionEvent(rushHit, function(collidedPart, direction, ray)
            DamageService.Damage(rushHit, char, 9)

            for i,v in rushHit.HumanoidRootPart:GetChildren() do
                if v:IsA('LinearVelocity') then
                    v:Destroy()
                end
            end

            rushHit.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero -- So that the opponent doesnt slide farther off
            -- rushHit.HumanoidRootPart.Anchored = true
            -- rushHit.HumanoidRootPart.CFrame = CFrame.lookAt(crashPosition, crashPosition + rushHit.HumanoidRootPart.CFrame.LookVector)

            -- if direction == -Vector3.yAxis or direction == Vector3.yAxis then
            --     Voxelize:FireAllClients('Destroy', Vector3.one * 15, rushHit.HumanoidRootPart.CFrame, Enum.PartType.Ball, nil, 20)
            --     Voxelize:FireAllClients('Unfreeze', Vector3.one * 20, rushHit.HumanoidRootPart.CFrame, Enum.PartType.Ball, nil, 20)
            -- else
            --     Voxelize:FireAllClients('Destroy', Vector3.one * 11, rushHit.HumanoidRootPart.CFrame, Enum.PartType.Ball, nil, 20)
            --     Voxelize:FireAllClients('Unfreeze', Vector3.one * 16, rushHit.HumanoidRootPart.CFrame, Enum.PartType.Ball, nil, 20)
            -- end

            game.ReplicatedStorage.Remotes.DisplayEffect:FireAllClients(
                'Crater', {
                    CFrame = rushHit.HumanoidRootPart.CFrame, Size = 12,
                    Direction = direction * 20, Rows = 2,
                    emitDebris = true, emitSmoke = true, createSound = false,
                },
                'Camera', {
                    Magnitude = 12, Roughness = 4, FadeInTime = .1, FadeOutTime = 1, 
                    PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                    Origin = rushHit.HumanoidRootPart.Position, Radius = 100
                }
            )

            task.wait(.7)

            -- alignPosition.Attachment1 = rushHit.HumanoidRootPart.RootAttachment
            -- alignPosition.Responsiveness = 8
            -- alignPosition.RigidityEnabled = false
            -- alignPosition.Mode = Enum.PositionAlignmentMode.TwoAttachment
            
            -- repeat
            --     RunService.Heartbeat:Wait()
            -- until (humRoot.Position - rushHit.HumanoidRootPart.Position).Magnitude <= 20

            local hitPos = rushHit.HumanoidRootPart.Position
            local unit = (hitPos - humRoot.Position)

            -- Voxelize:FireAllClients('Unfreeze', Vector3.new(12, 12, unit.Magnitude), humRoot.CFrame + unit.Unit * unit.Magnitude/2, nil, nil, 22, humRoot.CFrame.LookVector * 80)

            ao:Destroy()
        end, 3, nil, 10, true)
    end

    skillHandler.CleanUp = function()
        SkillService.UsingSkill(char, false, 'Murak')
        userState:EndWalkspeed('Murak')
        userState:IFrame(false)
    
        hum.AutoRotate = true
        if skillHandler.CurrentSection == 'Attack' then
            humRoot.Anchored = false

            if rushHit then
                rushHit.HumanoidRootPart.Anchored = false
            end
        end

        if hitState then
            hitState:UnStun('MurakRushHit')
        end
        if ragdoll then
            ragdoll:UnRagdoll(rushHit)
        end
    end

    skillHandler:Run()

    ---------------------------------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------------------------------
    if true then return end


    local userState = StateService.Get(char)
    userState:SetWalkspeed('Murak', 5, 0)
    char:SetAttribute('WalkSpeedDisabled', true)
    hum.AutoRotate = false

    local hit; local hitState

    local runtime = Prom.try(function()
        ------------------------------
        -- KICK SEQUENCE
        ------------------------------
        local keyDirection = humRoot.CFrame.LookVector

        local kickAnim = hum.Animator:LoadAnimation(murakAnims.Kick)

        local charState = StateService.Get(char)
        -- charState:Knockback(char, humRoot.CFrame.LookVector * 10, .6)

        kickAnim:Play()
        kickAnim:AdjustSpeed(1.3)
        kickAnim:GetMarkerReachedSignal('Hit'):Wait()

        hit = Hitbox.instant(humRoot.CFrame + humRoot.CFrame.LookVector * 3, Vector3.new(5, 1.5, 5), char, nil, true)
        if not hit or utility.IsLooking(hit, humRoot) and hit:GetAttribute('Blocking') then
            return 'NoHitKick'
        end
        if kickAnim.IsPlaying then kickAnim.Stopped:Wait() end
        userState:Superarmor(true)

        humRoot.CFrame = CFrame.lookAt(humRoot.Position, humRoot.Position + keyDirection)
        hit.HumanoidRootPart.CFrame = CFrame.lookAt(hit.HumanoidRootPart.Position, humRoot.Position)

        hitState = StateService.Get(hit)

        hitState:Knockback(char, humRoot.CFrame.LookVector * 20 + Vector3.yAxis * 7, .4, hit.HumanoidRootPart.Position + humRoot.CFrame.LookVector * 28)
        local knockbackAnim = hit.Humanoid.Animator:LoadAnimation(animations.KnockbackLong)
        knockbackAnim:Play()
        knockbackAnim:AdjustSpeed(1.8)

        hitState:Stun('Murak', 3.5)
        hitState:Knockdown(hit, 3.5)
        -- state:Collision(false)

        DamageService.Damage(hit, char, 5, true)

        game.ReplicatedStorage.Remotes.DisplayEffect:FireAllClients(
            'Camera', {
                Magnitude = 4, Roughness = 4, FadeInTime = .1, FadeOutTime = 2, 
                PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                Origin = hit.HumanoidRootPart.Position, Radius = 100
            }
        )

        ------------------------------
        -- HORIZONTAL ATTACK SEQUENCE
        ------------------------------
        task.wait(1)
        local horizontalLeapAnim = hum.Animator:LoadAnimation(murakAnims.HorizontalLeap)

        skillRoute:FireAllClients('Murak', char, 'HorizontalLeap')

        horizontalLeapAnim:Play()
        horizontalLeapAnim:GetMarkerReachedSignal('Leap'):Wait()

        charState:Knockback(char, humRoot.CFrame.LookVector * 10, 1, hit.HumanoidRootPart.Position + (humRoot.Position - hit.HumanoidRootPart.Position).Unit * 2.5)
        task.wait(.8)

        local hAttackAnim = hum.Animator:LoadAnimation(murakAnims.HorizontalAttack)
        hAttackAnim:Play()

        hAttackAnim:GetMarkerReachedSignal('Grab'):Wait()
        humRoot.Anchored = true

        local op = OverlapParams.new(); op.FilterDescendantsInstances = {hit}; op.FilterType = Enum.RaycastFilterType.Include
        local hit = Hitbox.instant(humRoot.CFrame + humRoot.CFrame.LookVector * 1.5, Vector3.new(3.5, 1.5, 3.5), op, nil, true)
        if not hit then hAttackAnim:Stop(.5); return 'NoHitHorizontal' end

        hitState:Stun('MurakNonAvoidable')
        DamageService.Damage(hit, char, 8, true)

        local ragdoll = RagdollService.Get(hit)
        ragdoll:Ragdoll(hit)

        hitState:Collision(false, false)

        local weld: BallSocketConstraint = utility.Weld(char['Right Arm'], hit.Head, 'BallSocketConstraint')
        local att0: Attachment, att1: Attachment = Instance.new('Attachment'), Instance.new('Attachment')
        att0.Parent = hit.Head; att0.WorldCFrame = hit.Head.CFrame + hit.Head.CFrame.LookVector * .3
        att1.Parent = char['Right Arm']; att1.WorldCFrame = char['Right Arm'].CFrame - char['Right Arm'].CFrame.UpVector
        weld.Attachment0 = att0; weld.Attachment1 = att1
        weld.Restitution = 10

        -- SLAM

        hAttackAnim:GetMarkerReachedSignal('Slam'):Wait()
        hAttackAnim:AdjustSpeed(.5)

        -- Send to client for debris effect or smth
        DamageService.Damage(hit, char, 2, true)
        skillRoute:FireAllClients('Murak', char, 'Slam', hit)
        
        hAttackAnim:GetMarkerReachedSignal('Throw'):Wait()
        humRoot.Anchored = false
        hAttackAnim:AdjustSpeed(1)
        hit.Head.CanCollide = true
        hit.Torso.CanCollide = true
        hit.HumanoidRootPart.CanCollide = true
        
        weld:Destroy()
        local bv = Instance.new("BodyVelocity")
        bv.Parent = hit.HumanoidRootPart
        bv.MaxForce = Vector3.new(100000,100000,100000)
        bv.Velocity = Vector3.yAxis * 100
        local tween = ts:Create(bv, TweenInfo.new(1), {Velocity = Vector3.yAxis})
        tween:Play()
        tween.Completed:Wait()
        bv.Velocity = Vector3.yAxis * .5
        -- hit.HumanoidRootPart.Anchored = true
        -- bv:Destroy()

        local ao = Instance.new('AlignOrientation')
        ao.Attachment0 = Instance.new('Attachment'); ao.Attachment0.Parent = hit.HumanoidRootPart
        ao.PrimaryAxis = Vector3.zero
        ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
        ao.MaxTorque = 100000
        ao.RigidityEnabled = true
        ao.Parent = hit.HumanoidRootPart
        
        ------------------------------
        -- LEAP SEQUENCE
        ------------------------------
        humRoot.CFrame = CFrame.lookAt(humRoot.Position, humRoot.Position + keyDirection)
        local leapAnim = hum.Animator:LoadAnimation(murakAnims.Leap)
        leapAnim:Play()
        leapAnim:GetMarkerReachedSignal('Leap'):Wait()

        local bv2 = Instance.new("BodyVelocity")
        bv2.Parent = char.HumanoidRootPart
        bv2.MaxForce = Vector3.new(100000,100000,100000)
        bv2.Velocity = Vector3.yAxis * 87
        local tween = ts:Create(bv2, TweenInfo.new(1), {Velocity = Vector3.yAxis})
        tween:Play()

        skillRoute:FireAllClients('Murak', char, 'VerticalLeap')

        tween.Completed:Wait()
        bv2:Destroy() 
        humRoot.Anchored = true
        -- leapAnim.Stopped:Wait()
        hitState:Collision(true)
        
        ------------------------------
        -- MIDAIR ATTACK SEQUENCE
        ------------------------------
        local leapAttackAnim = hum.Animator:LoadAnimation(murakAnims.LeapAttack)
        leapAttackAnim:Play()
        leapAttackAnim:AdjustSpeed(1.5)

        leapAttackAnim.Stopped:Connect(function()
            humRoot.Anchored = false
            hum.AutoRotate = true
        end)

        leapAttackAnim:GetMarkerReachedSignal('Grab'):Wait()
        
        hit.HumanoidRootPart.CFrame = humRoot.CFrame + Vector3.yAxis * 4
        ao:Destroy(); bv:Destroy()
        -- hit.HumanoidRootPart.Anchored = false

        skillRoute:FireAllClients('Murak', char, 'Cleanup_Hit', hit)

        local weld = utility.Weld(char['Right Arm'], hit['Left Leg'])
        leapAttackAnim:GetMarkerReachedSignal('Throw'):Wait()
        weld:Destroy()

        hitState:Knockback(char, humRoot.CFrame.LookVector * 10 - Vector3.yAxis * 75, .4)

        task.spawn(function()
            local collision, direction = Hitbox.WaitForCollision(hit, true)
            -- if direction == -Vector3.yAxis then
            if collision then
                DamageService.Damage(hit, char, 9)

                hit.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero -- So that the opponent doesnt slide farther off

                if direction == -Vector3.yAxis or direction == Vector3.yAxis then
                    game.ReplicatedStorage.Remotes.Voxelize:FireAllClients('Destroy', Vector3.one * 12, hit.HumanoidRootPart.CFrame, Enum.PartType.Ball, nil, 20)
                    game.ReplicatedStorage.Remotes.Voxelize:FireAllClients('Unfreeze', Vector3.one * 14, hit.HumanoidRootPart.CFrame, Enum.PartType.Ball, nil, 20)
                    -- VoxelService:DestroyPartsInBounds(hit.HumanoidRootPart.CFrame, Vector3.one * 13)
                    -- VoxelService:UnfreezePartsInBounds(hit.HumanoidRootPart.CFrame, Vector3.xAxis * 14 + Vector3.zAxis * 14 + Vector3.yAxis * 3)
                else
                    game.ReplicatedStorage.Remotes.Voxelize:FireAllClients('Destroy', Vector3.one * 8, hit.HumanoidRootPart.CFrame, Enum.PartType.Ball, nil, 20)
                    game.ReplicatedStorage.Remotes.Voxelize:FireAllClients('Unfreeze', Vector3.one * 10, hit.HumanoidRootPart.CFrame, Enum.PartType.Ball, nil, 20)
                    -- VoxelService:DestroyPartsInBounds(hit.HumanoidRootPart.CFrame, 4.5)
                    -- VoxelService:UnfreezePartsInBounds(hit.HumanoidRootPart.CFrame, 5)
                end

                game.ReplicatedStorage.Remotes.DisplayEffect:FireAllClients(
                    'Crater', {
                        CFrame = hit.HumanoidRootPart.CFrame, Size = 12,
                        Direction = direction * 20, Rows = 2,
                        emitDebris = true, emitSmoke = true, createSound = false,
                    },
                    'Camera', {
                        Magnitude = 12, Roughness = 4, FadeInTime = .1, FadeOutTime = 1, 
                        PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                        Origin = hit.HumanoidRootPart.Position, Radius = 100
                    }
                )
                -- remotes.Debris:FireAllClients('RadialV', 4, 2, hit.HumanoidRootPart.Position, true, 25)
            end

        end)

        task.wait(1)



        userState:Superarmor(false)
        skillRoute:FireAllClients('Murak', char, 'Cleanup')
        char:SetAttribute('WalkSpeedDisabled', nil)
        task.wait(1)
        
        ragdoll:UnRagdoll(hit)
        hitState:UnStun('MurakNonAvoidable')
    end):andThen(function(result)
        if result == 'NoHitHorizontal' then
            skillRoute:FireAllClients('Murak', char, 'Cleanup')
            -- char:SetAttribute('WalkSpeedDisabled', nil)
        end
    end):finally(function()
        SkillService.Cooldown(char, 'Murak')
        char:SetAttribute('UsingSkill', nil)

        userState:EndWalkspeed('Murak')
        hum.AutoRotate = true
        humRoot.Anchored = false
        char:SetAttribute('WalkSpeedDisabled', nil)

        if hit then
            hit.Humanoid.AutoRotate = true
            hit.HumanoidRootPart.Anchored = false
            local state = StateService.Get(hit)
            state:UnStun('MurakNonAvoidable')
        end
    end):catch(function(err)
        userState:EndWalkspeed('Murak')
        hum.AutoRotate = true
        humRoot.Anchored = false
        skillRoute:FireAllClients('Murak', char, 'Cleanup')
        skillRoute:FireAllClients('Murak', char, 'Cleanup_Hit', hit)
        error(err)
    end)

    char.Values.Attackers.ChildAdded:Once(function(val)
        if char:GetAttribute('Superarmor') then return end
        runtime:cancel()
        print('cancel')
    end)
end

sk_server['Invisible Providence'] = {}
sk_server['Invisible Providence'].Init = function(char: Model)
    local target = SkillService.GetTarget(char)
    if not target then return end

    local hum = char.Humanoid
    local humRoot = char.HumanoidRootPart

    SkillService.UsingSkill(char, true, 'Invisible Providence')

    local skillObj = SkillService.CreateSkill(char, 'Invisible Providence', {
        ['Start'] = 0,
        ['SummonHand'] = 2,
    })

    local hitbox
    local limbs: table
    local alignOrientation1
    skillObj.Runtime = function()

        local state = StateService.Get(char)
        state:SetWalkspeed('Invisible Providence', 4, 0, nil)
        hum.AutoRotate = false

        local windUpAnim = hum.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.SpiritKnight.InvProvidence)
        windUpAnim:Play()
        -- task.wait(.75)
        windUpAnim:AdjustSpeed(.75)
        -- local bodyGyro: BodyGyro = utility.GyroCharacter(char)
        alignOrientation1 = utility.AlignCharacter(char, true)
        alignOrientation1.CFrame = CFrame.lookAt(humRoot.Position, target.HumanoidRootPart.Position)
        -- alignOrientation1.LookAtPosition = target.HumanoidRootPart.Position
        windUpAnim.Stopped:Wait()
        -- alignOrientation1.LookAtPosition = target.HumanoidRootPart.Position
        alignOrientation1.CFrame = CFrame.lookAt(humRoot.Position, target.HumanoidRootPart.Position)

        game.Debris:AddItem(alignOrientation1, .8)

        game.ReplicatedStorage.Remotes.DisplayEffect:FireAllClients(
            'Camera', {
                Magnitude = 4, Roughness = 4, FadeInTime = .1, FadeOutTime = 1, 
                PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                Origin = humRoot.Position, Radius = 100
            }
        )

        -----------
        -----------

        skillObj.CurrentSection = 'SummonHand'

        local targetPos = target.HumanoidRootPart.Position
        local charPos = humRoot.Position + humRoot.CFrame.LookVector * 2.5

        limbs = Instance.new('Folder');
        limbs.Name = 'InvisibleLimbs'..char.Name
        limbs.Parent = workspace.UnobstructiveAssets

        skillRoute:FireAllClients('Invisible Providence', char, 'Limbs', limbs)

        -- local fist = Instance.new('Part')
        local fist = game.ReplicatedStorage.Assets.SkillAssets.InvisibleFist:Clone()
        fist.CanCollide = false
        fist.Material = 'Glass'
        -- fist.Size = Vector3.new(1, 1, 3)
        fist.Color = Color3.new(1,1,1)
        fist.Transparency = .9
        fist.Reflectance = .6
        fist.Anchored = true

        fist.CFrame = CFrame.lookAt(charPos, targetPos)
        fist.Parent = limbs

        hitbox = Hitbox.new()
        hitbox.CoreMode = true
        hitbox.Core = fist
        hitbox.Size = Vector3.one * 4
        hitbox.Single = true
        hitbox.OverlapParams.FilterDescendantsInstances = {char, workspace.UnobstructiveAssets}

        local lungeMode = true

        hitbox.HitEvent:Connect(function(hit: Model, hitBase: BasePart)
            DamageService.Damage(hit, char, 5)
            local ragdoll = RagdollService.Get(hit)
            local hitState = StateService.Get(hit)
            
            ragdoll:Ragdoll(hit, 3)
            if not lungeMode then
                hitState:Knockback(char, Vector3.yAxis * 50, .3)
                task.wait(.2)
                Hitbox.CollisionEvent(target, function(collidedPart, direction, ray)
                    SkillService.CoreVoxelDestruction({Core = target.HumanoidRootPart, LaunchDirection = humRoot.CFrame.LookVector * 30}, Vector3.one * 7, 0, nil, 30, 40, true)
                end, 3, nil, 3, false, {-Vector3.yAxis}, false)
            else
                hitState:Knockback(char, humRoot.CFrame.LookVector * 35, .3)
                task.wait(.2)
                Hitbox.CollisionEvent(target, function(collidedPart, direction, ray)
                    SkillService.CoreVoxelDestruction({Core = target.HumanoidRootPart, LaunchDirection = humRoot.CFrame.LookVector * 30}, Vector3.one * 7, 0, nil, 30, 40, true)
                end, 2, nil, 3, false)
            end
        end)

        hitbox:Start()


        local function SwingPart(part: Part)
            local unit = (targetPos - charPos)
            local startPos = charPos + unit.Unit * math.clamp(unit.Magnitude, 0, 35) * .8
            -- local tw = ts:Create(part, TweenInfo.new(.2), {CFrame = CFrame.lookAt(startPos, targetPos)}); tw:Play()

            for i=1, math.clamp(unit.Magnitude, 0, 35), 2 do
                task.wait()
                part.CFrame = CFrame.lookAt(charPos + unit.Unit * unit.Magnitude * .8 * (i/(unit.Magnitude)), targetPos) 
            end
            
            -- tw.Completed:Wait()

            lungeMode = false

            local curve = BezierCurve.new(startPos, startPos + unit.Unit * 5, startPos + unit.Unit * 5 + Vector3.yAxis * 8)
            local path = curve:GetPath(1/15)
            local orientation = part.CFrame - part.CFrame.Position
            for i,v in path do
                local point = v
                if i == #path then
                    part.CFrame = CFrame.new(point + Vector3.yAxis*.2) * orientation
                else
                    part.CFrame = CFrame.new(point + Vector3.yAxis*.2) * orientation * CFrame.Angles(math.rad(i*6), 0, 0)
                end
                task.wait()
            end
        end

        task.defer(function()
            local pastPart = fist
            for i=1, 14 do
                -- task.wait(.05)
                local p = Instance.new('Part')
                p.Material = Enum.Material.Glass
                p.Size = Vector3.new(1, 1, 5)
                -- p.Color = Color3.new(1,1,1)
                p.Transparency = .9
                p.Reflectance = .6
                p.Anchored = true; p.CanCollide = false; p.CanQuery = false
                p.Parent = limbs
                -- p.CFrame = CFrame.lookAt(humRoot.Position, targetPos)
                local pastCFrame: CFrame = p.CFrame
                local iPastPart = pastPart
                local iPastCFrame = iPastPart.CFrame
                task.spawn(function()
                    while RunService.Heartbeat:Wait() and limbs.Parent == workspace.UnobstructiveAssets do
                        iPastCFrame = iPastPart.CFrame
                        if lungeMode and (iPastCFrame.Position - pastCFrame.Position).Magnitude >= 4.5 or (iPastCFrame.Position - pastCFrame.Position).Magnitude >= 1.5 then
                            p.CFrame = pastCFrame
                            pastCFrame = iPastPart.CFrame
                            if not lungeMode and i <= 5 then
                                p.Size = Vector3.new(1, 1, 2.5)
                            end
                        end
                    end
                end)
                -- task.spawn(SwingPart, p)
                pastPart = p
            end
        end)

        SwingPart(fist)
    end

    skillObj.CleanUp = function()
        print('dude are you reenabling autorotate')
        hum.AutoRotate = true

        if alignOrientation1 then
            alignOrientation1:Destroy()
        end

        if hitbox then
            hitbox:Stop()
        end

        task.wait(1.1)

        local state = StateService.Get(char)
        state:EndWalkspeed('Invisible Providence')
        SkillService.Cooldown(char, 'Invisible Providence')
        SkillService.UsingSkill(char, false, 'Invisible Providence')

        if limbs then
            for _,v in limbs:GetChildren() do
                ts:Create(v, TweenInfo.new(2), {Transparency = 1}):Play()
            end
            task.wait(2)
            limbs:Destroy()
        end
    end
    
    skillObj:Run()
end

sk_server['Wipeout Flash'] = {}
sk_server['Wipeout Flash'].Init = function(char: Character)
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

        local anim = AnimationService.LoadAnimation(char, animations.SpiritKnight.WipeoutFlash, 'Skill')
        anim:Play()

        SkillService.RouteToClient('Wipeout Flash', char, 'Flash', 'All', anim)

        for i=1, 4 do
            anim:GetMarkerReachedSignal('Flash'..i):Wait()

            local hits = Hitbox.instant({Core = humRoot, OffsetIsRelativeTo = {'LookVector'}, Offset = {3}}, Vector3.one * 5, char, nil, nil, game.Players:GetPlayerFromCharacter(char))
            for _,hit in hits do
                if hit:GetAttribute('Ragdolled') or hit:GetAttribute('Blocking') then continue end

                DamageService.Damage(hit, char, 1)
                local hitState = StateService.Get(hit)
                hitState:Stun('FlipPhoneFlash', 1, 3)
            end

            SkillService.RouteToClient('Wipeout Flash', char, 'Flash2', 'All', i)
        end
        -- local lookCFrame = SkillService.RouteToClient('Rental Goa', char, 'LookCFrame_Return', game.Players:GetPlayerFromCharacter(char))
        anim.Stopped:Wait()
    end

    skillHandler.CleanUp = function()
        state:EndWalkspeed('Wipeout Flash')

        if skillHandler:HasCompleted(true) then

        end
        if phone then
            phone:Destroy()
        end

        SkillService.Cooldown(char, 'Wipeout Flash')
        SkillService.UsingSkill(char, false, 'Wipeout Flash')
    end

    skillHandler:Run()
end

sk_server['Special'] = {}
sk_server['Special'].Init_Normal = function(char: Character)
    SkillService.UsingSkill(char, true, 'Special')

    local state = StateService.Get(char)
    state:SetWalkspeed('BeatriceSpecial', 4, 0.1)

    local humRoot = char.HumanoidRootPart
    local hum: Humanoid = char.Humanoid
    -- hum.AutoRotate = false

    -- Global variables

    local skillHandler = SkillService.CreateSkill(char, 'Beatrice Special', {
        -- ['Start'] = 0,
    })

    local beatrice: Model
    skillHandler.Runtime = function()
        state:Superarmor(true)

        beatrice = ReplicatedStorage.Assets.SkillAssets.SpiritKnight.Beatrice:Clone()
        beatrice.Name = 'Beatrice/'..char.Name
        beatrice.Parent = workspace.UnobstructiveAssets
        beatrice:WaitForChild('HumanoidRootPart').CFrame = humRoot.CFrame + humRoot.CFrame.RightVector * 5
        utility.Weld(beatrice.HumanoidRootPart, humRoot)

        char:SetAttribute('Form', 'Beatrice')
    end

    skillHandler.CleanUp = function()
        state:EndWalkspeed('BeatriceSpecial')
        state:Superarmor(false)

        if skillHandler:HasCompleted(true) then
            if beatrice then
                beatrice:Destroy()
            end
        end

        SkillService.Cooldown(char, 'Special', 2)
        SkillService.UsingSkill(char, false, 'Special')
    end

    skillHandler:Run()
end

sk_server['Special'].Init_Beatrice = function(char: Character)
    SkillService.UsingSkill(char, true, 'Special')

    local state = StateService.Get(char)
    state:SetWalkspeed('Warp', 4, 0.1)

    local humRoot = char.HumanoidRootPart
    local hum: Humanoid = char.Humanoid
    -- hum.AutoRotate = false

    -- Global variables

    local skillHandler = SkillService.CreateSkill(char, 'Warp', {
        -- ['Start'] = 0,
    })

    local beatrice: Model
    local spiritBall; local warpPillar
    skillHandler.Runtime = function()
        state:IFrame(true)

        task.wait(.5)
        warpPillar = ReplicatedStorage.Assets.SkillAssets.SpiritKnight.WarpPillar:Clone()
        warpPillar.Parent = workspace.UnobstructiveAssets
        warpPillar.CFrame = humRoot.CFrame - Vector3.yAxis * 2

        local sfx = ReplicatedStorage.Assets.Sounds.SpiritKnight.WarpOpen:Clone()
        sfx.Parent = warpPillar
        sfx:Destroy()--

        task.wait(.5)

        local heightLimit = humRoot.CFrame.Position.Y + 1
        SkillService.CoreVoxelDestruction({Core = humRoot, OffsetRelativeTo = {'UpVector'}, Offset = {50}}, Vector3.new(8, 100, 8), 0, nil, 40, 50)

        for _,v in char:GetDescendants() do
            if v:IsA('BasePart') then
                v.CanCollide = false
                v.Transparency = 1
                if v.Parent == char then
                    v.CollisionGroup = 'Ragdolls'
                end
            end
        end

        
        state:Velocity(Vector3.yAxis * 130, 1)
        state:SetWalkspeed('WarpDown', 6, 50)

        local beatrice = workspace.UnobstructiveAssets:FindFirstChild('Beatrice/'..char.Name)
        if beatrice then
            beatrice:Destroy()
        end
        
        task.wait(1)

        ReplicatedStorage.Remotes.DisplayEffect:FireAllClients(
            'Crater', {
                CFrame = char.HumanoidRootPart.CFrame, Size = 8,
                Direction = -Vector3.yAxis * 20, Rows = 2,
                emitDebris = true, emitSmoke = true, createSound = false,
            },
            'Camera', {
                Magnitude = 3, Roughness = 4, FadeInTime = .1, FadeOutTime = 1, 
                PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                Origin = char.HumanoidRootPart.Position, Radius = 100
            }
        )

        spiritBall = ReplicatedStorage.Assets.SkillAssets.SpiritKnight.SpiritBall:Clone()
        spiritBall.Parent = workspace.UnobstructiveAssets
        spiritBall.CFrame = humRoot.CFrame
        utility.Weld(spiritBall, humRoot)
        warpPillar:Destroy(); warpPillar = nil

        state:Velocity(Vector3.yAxis * 0.1, 1.4, nil, {Vector3.zAxis, Vector3.xAxis})
        task.wait(1.5)
        state:EndWalkspeed('WarpDown')

        for _,v in spiritBall:WaitForChild('FallAttachment'):GetChildren() do
            v.Enabled = true
        end

        local foundPart = false

        task.spawn(function()
            while task.wait() and not skillHandler:HasCompleted() and not foundPart do
                SkillService.CoreVoxelDestruction({Core = humRoot}, Vector3.new(6, 15, 6), 0, nil, 0, 60)

                -- SkillService.CoreVoxelDestruction({Core = humRoot, OffsetRelativeTo = {'UpVector'}, Offset = {-20}}, Vector3.new(6, 30, 6), 100, nil, 50, 60)
            end
        end)

        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {workspace.Map}
        params.FilterType = Enum.RaycastFilterType.Include
        params.RespectCanCollide = true
        while task.wait() and not foundPart do
            local ray = workspace:Raycast(humRoot.Position, -Vector3.yAxis * 12, params)
            local collidedPart = ray and ray.Instance
            if not collidedPart then continue end

            local foundVoxablePart = false
            if collidedPart:GetAttribute('Voxable') then
                foundVoxablePart = true
            end

            -- warn(collidedParts, direction, ray)
            if ray.Position.Y > heightLimit and foundVoxablePart then 
                SkillService.CoreVoxelDestruction({Core = humRoot}, Vector3.new(6, 15, 6), 100, nil, 0, 60)
            else
                foundPart = true
            end
        end

        local hits = Hitbox.instant({Core = humRoot}, Vector3.one * 18, char, nil, nil, game.Players:GetPlayerFromCharacter(char))
        for _,hit in hits do
            DamageService.Damage(hit, char, 6)
            local hitState = StateService.Get(hit)
            local ragdoll = RagdollService.Get(hit)
            ragdoll:Ragdoll(hit, 2.2)
            hitState:Knockback(char, (hit.HumanoidRootPart.Position - humRoot.Position).Unit * 50, .2, nil, nil, {Vector3.yAxis})
        end

        SkillService.CoreVoxelDestruction({Core = humRoot, LaunchDirection = 'Explosion_70', OffsetRelativeTo = {'UpVector'}, Offset = {5}}, Vector3.new(25, 11, 25), 0, nil, 50, 60, true)
        ReplicatedStorage.Remotes.DisplayEffect:FireAllClients(
            'Crater', {
                CFrame = char.HumanoidRootPart.CFrame, Size = 8,
                Direction = -Vector3.yAxis * 20, Rows = 2,
                emitDebris = true, emitSmoke = true, createSound = false,
            },
            'Camera', {
                Magnitude = 10, Roughness = 4, FadeInTime = .1, FadeOutTime = 1, 
                PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                Origin = char.HumanoidRootPart.Position, Radius = 100
            }
        )
        SkillService.RouteToClient('Warp', char, 'SpiritBurst', 'All')
    end

    skillHandler.CleanUp = function()
        state:IFrame(false)
        for _,v in char:GetDescendants() do
            if v:IsA('BasePart') then
                if v.Name == 'Torso' or v.Name == 'Head' then
                    v.CanCollide = false
                end
                if v.Name ~= 'HumanoidRootPart' then
                    v.Transparency = 0
                end
                if v.Parent == char then
                    v.CollisionGroup = 'Characters'    
                end
            end
        end

        state:EndWalkspeed('Warp')
        state:EndWalkspeed('WarpDown')
        state:Superarmor(false)

        char:SetAttribute('Form', 'Base')

        if skillHandler:HasCompleted(true) then
            if beatrice then
                beatrice:Destroy()
            end
        end

        if spiritBall then
            spiritBall:Destroy()
        end
        if warpPillar then
            warpPillar:Destroy()
        end

        SkillService.Cooldown(char, 'Special', 30)
        SkillService.UsingSkill(char, false, 'Special')
    end

    skillHandler:Run()
end

-- sk_server['Special'].Init_Normal = function(char: Character)
--     local hum = char.Humanoid
--     local humRoot = char.HumanoidRootPart

--     if char.Values.Cooldowns:FindFirstChild('Special') or char.Values.Stuns:FindFirstChildWhichIsA('NumberValue') or char:GetAttribute('SkillsDisabled') then return end

--     if hum.FloorMaterial == Enum.Material.Air or not hum.FloorMaterial then
--         return
--     end

--     SkillService.Cooldown(char, 'Special', 10)

--     local state = StateService.Get(char)

--     state:Velocity(Vector3.yAxis * 50, .2)

--     local bounceAnim = hum.Animator:LoadAnimation(animations.Backdash)
--     bounceAnim:Play()

--     local dontMakeHitbox: boolean = false
--     local timer = os.clock()
--     task.wait(.42)
    
--     if hum.FloorMaterial ~= Enum.Material.Air and hum.FloorMaterial ~= nil then
--         dontMakeHitbox = true
--     end

--     if not dontMakeHitbox then
--         -- local hitbox = Hitbox.new()
--         -- hitbox.Core = humRoot
--         -- hitbox.Offset = -Vector3.yAxis * 4
--         -- hitbox.Size = Vector3.one * 4.5
--         -- hitbox.OverlapParams.FilterDescendantsInstances = {char, workspace.UnobstructiveAssets}
--         -- hitbox.Visualize = true

--         -- hitbox.HitEvent:Connect(function(hit: Character | BasePart, baseHit: BasePart)
--         --     hitbox:Stop()

--         --     if not hit:IsA('Model') then return end

--         --     local hitState = StateService.Get(hit)

--         --     hitState:Stun('LeapAttack', 2, 2)
--         -- end)

--         -- hitbox:Start()

--         timer = os.clock()
--         local hits
--         repeat
--             hits = Hitbox.instant({Core = humRoot, Offset = -Vector3.yAxis * 7}, Vector3.one * 4.5, char, false, game.Players:GetPlayerFromCharacter(char))

--             task.wait(.02)
--         until os.clock() - timer >= 1 or hum.FloorMaterial ~= Enum.Material.Air and hum.FloorMaterial ~= nil or #hits > 0
--         -- hitbox:Stop()

--         for _,v in hits do
--             local hitState = StateService.Get(v)

--             hitState:Stun('LeapAttack', 2, 2)
--         end

--         if #hits > 0 then
--             state:Velocity(Vector3.yAxis * 35 - humRoot.CFrame.LookVector * 37, .2)
--             bounceAnim:Play()
--         end
--     end
-- end

sk_server['Awaken'] = {}
sk_server['Awaken'].Init = function(char: Model)
    local hum = char.Humanoid
    hum.AutoRotate = false
    local state = StateService.Get(char)
    SkillService.Cooldown(char, 'Awaken', 30)
    state:IFrame(true, 19.5)
    state:SetWalkspeed('Awakening_SK', 9, 0)
    char:SetAttribute('WalkSpeedDisabled', true)

    skillRoute:FireAllClients('Awaken', char, 'Init')

    task.spawn(function()
        while task.wait(.1) and hum.Health < 50 do
            hum.Health += 1
        end
    end)

    task.wait(13)

    local kneelPunchAnim = hum.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.SKAwakening.KneelPunch)
    kneelPunchAnim:Play()
    kneelPunchAnim:GetMarkerReachedSignal('HIt'):Wait()

    local RADIUS = 12
    for _,v in workspace.Characters:GetChildren() do
        if v:FindFirstChild('HumanoidRootPart') and v ~= char and (v.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude <= RADIUS then
            local rag = RagdollService.Get(v)
            rag:Ragdoll(v, 1.1)
            local hitState = StateService.Get(v)
            hitState:Knockback(char, Vector3.yAxis * 20, .3)
            DamageService.Damage(v, char, 3)
        end
    end

    game.ReplicatedStorage.Remotes.Voxelize:FireAllClients('Unfreeze', Vector3.new(12, 8, 12), char.HumanoidRootPart.CFrame, Enum.PartType.Ball, nil, 20, Vector3.yAxis * 3 )
    -- VoxelService:UnfreezePartsInBounds(char.HumanoidRootPart.CFrame - Vector3.yAxis * 3, Vector3.new(7, 2.5, 7), nil, Vector3.yAxis * 4)

    game.ReplicatedStorage.Remotes.DisplayEffect:FireAllClients(
        'Crater', {
            CFrame = char.HumanoidRootPart.CFrame, Size = 12,
            Direction = -Vector3.yAxis * 20, Rows = 2,
            emitDebris = true, emitSmoke = true, createSound = false,
        },
        'Camera', {
            Magnitude = 12, Roughness = 4, FadeInTime = .1, FadeOutTime = 1, 
            PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
            Origin = char.HumanoidRootPart.Position, Radius = 100
        }
    )

    char:SetAttribute('WalkSpeedDisabled', nil)
    state:EndWalkspeed('Awakening_SK')
    hum.AutoRotate = true
end

local minyaVariantTimings = {}

sk_server['Minya'] = {}

local function RemoveLimbs(Hit)
	local HitPlayer = Hit
	local Torso = HitPlayer.Torso
	
	local Motors = {}
	
	--Appending all the motors inside a player
	for _, Motor: Instance in ipairs(Torso:GetChildren()) do
		if Motor:IsA("Motor6D") then
			table.insert(Motors, Motor)
		end
	end
	
	--Checks if their are still more motors left in the player to remove
	if Motors then
		local Humanoid = Hit:WaitForChild("Humanoid")
		if Humanoid.Health < Humanoid.MaxHealth / 2 then
			local Motor = Motors[math.random(1, #Motors)]
			table.remove(Motors, table.find(Motors, Motor))

			if Motor.Name == "Left Shoulder" then
				HitPlayer["Left Arm"].CanCollide = true
				Motor:Destroy()
			end

			if Motor.Name == "Right Hip" then
				HitPlayer["Right Leg"].CanCollide = true
				Motor:Destroy()
			end
		end
	end
end

sk_server['Minya'].Init = function(char: Character)
    char:SetAttribute('UsingSkill', 'Minya')

    local humRoot = char.HumanoidRootPart
    
    local state = StateService.Get(char)
    -- state:SetWalkspeed('MinyaCast', 3, 4)

    skillRoute:FireClient(game.Players:GetPlayerFromCharacter(char), 'Minya', char, 'User')

    -- local rng = Random.new()

    -- local neg = rng:NextInteger(0,1) == 0

    local fullCircle = 2 * math.pi
    local radius = 8

    local function getXAndZPositions(angle)
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        return x, z
    end

	local shards = Instance.new('Part')
	shards.CanCollide = false; shards.Anchored = false; shards.Transparency = 1
	shards.Name = 'MinyaShards'
    shards.Massless = true
	shards.Parent = workspace.UnobstructiveAssets
	
	local attachment1 = Instance.new('Attachment')
	attachment1.Parent = shards
	local attachment2 = Instance.new('Attachment')
	attachment2.Parent = humRoot
	
	shards.CFrame = CFrame.new(humRoot.Position)
	
	local weld: RigidConstraint = utility.Weld(shards, humRoot, 'RigidConstraint')
	weld.Attachment0 = attachment1
	weld.Attachment1 = attachment2
	
	
	for i=1, 8 do
		local shard: BasePart = game.ReplicatedStorage.Assets.SkillAssets.MinyaShard:Clone()
        shard.Massless = true
		shard.Parent = shards
		
		local angle = i * (fullCircle / 8)
		local x, z = getXAndZPositions(angle)
		
		local position = (humRoot.CFrame * CFrame.new(x, 0, z)).Position
		shard.CFrame = CFrame.new(position) + Vector3.yAxis * 9.2
		utility.Weld(shard, shards)
		shard.Transparency = 1
	end
	
	local finishedRotating = false
	
	task.defer(function()
		local rotation2 = ts:Create(attachment1, TweenInfo.new(2), {Orientation = Vector3.new(0, 360, 0)})
		rotation2:Play()
		rotation2.Completed:Wait()
		finishedRotating = true
	end)

	for i,shard in shards:GetChildren() do
		if not shard:IsA('BasePart') then continue end
		
        -- local angle = i * (fullCircle / 8)
        -- local x, z = getXAndZPositions(angle)
        
        shard.Size = Vector3.zero
        --shard.Parent = workspace.UnobstructiveAssets

        task.defer(function()
            task.wait()
            shard:WaitForChild('Attachment'):WaitForChild('Dots 2'):Emit(12)
            shard.Attachment:WaitForChild('Smoke'):Emit(1)
			
            task.delay(i/8, function()
                ts:Create(shard, TweenInfo.new(.5), {Transparency = 0, Size = Vector3.new(0.519, 2.78, 0.615) * 2}):Play()
                while shard.Parent == shards and task.wait() do
                    shard.Orientation += Vector3.yAxis
                end
            end)
			
			repeat task.wait() until finishedRotating
            local CENTER: Vector3 = shards.Position

            shard.WeldConstraint:Destroy()
            -- shard.Parent = workspace.UnobstructiveAssets
            shard.Anchored = true

            local hitbox = Hitbox.new()
            hitbox.CoreMode = true
            hitbox.Core = shard; hitbox.OverlapParams.FilterDescendantsInstances = {char, workspace.UnobstructiveAssets}
            hitbox.Single = true; hitbox.Size = Vector3.new(5, 3, 5)
            hitbox.Visualize = true
            --hi 
            local shootTween: Tween
            
            hitbox.HitEvent:Connect(function(hit: Character | BasePart, hitOriginal: BasePart)
                if shootTween then
                    shootTween:Cancel()
                end

                if not hit:FindFirstChild('Humanoid') then return end

                DamageService.Damage(hit, char, 5)

                local hitState = StateService.Get(hit)
                local frozenLimbs = {}
                local function Shatter()
                    print('shattering')
                    hitState:UnStun('MinyaFreeze')

                    if hit.Humanoid.Health <= 0 then
                        -- RemoveLimbs(hit)
                        hit.Head.Transparency = 1
                    end
                    for _,limb in frozenLimbs do
                        limb:Destroy()
                    end
                end

                local hasShattered = false
                
                hitState:Stun('MinyaFreeze', nil, 4)

                task.delay(6, function()
                    if not hasShattered then
                        hasShattered = true
                        Shatter()
                    end
                end)

                local oldHealth = hit.Humanoid.Health
                local shatterDamage = 0
                local hCon; hCon = hit.Humanoid:GetPropertyChangedSignal('Health'):Connect(function()
                    if hasShattered then
                        hCon:Disconnect()
                    end

                    if oldHealth > hit.Humanoid.Health then
                        shatterDamage += oldHealth - hit.Humanoid.Health
                        if shatterDamage >= 10 then
                            hasShattered = true
                            Shatter()
                        end
                    end
                    oldHealth = hit.Humanoid.Health
                end)

                if hit.Humanoid.Health <= 0 then
                    Shatter()
                end

                for _, limb in hit:GetChildren() do
                    if not limb:IsA('BasePart') or limb.Name == 'HumanoidRootPart' then continue end

                    local iceClone = limb:Clone()
                    iceClone:ClearAllChildren()
                    iceClone.CanCollide = false; iceClone.CanQuery = false
                    iceClone.Material = Enum.Material.Ice; iceClone.Reflectance = .2; iceClone.Massless = true; iceClone.Transparency = .4
                    iceClone.Size += Vector3.one * .1; iceClone.Color = Color3.new(0.396078, 0.2, 0.607843)
                    iceClone.Parent = workspace.UnobstructiveAssets
                    iceClone.CFrame = limb.CFrame
                    utility.Weld(iceClone, limb)
                    table.insert(frozenLimbs, iceClone)
                end

                skillRoute:FireAllClients('Minya', char, 'ShardShatter', shard.CFrame)
                shard:Destroy()
            end)

            hitbox:Start()

            local rayParams = RaycastParams.new(); rayParams.FilterDescendantsInstances = {char, workspace.UnobstructiveAssets}; rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local ray = workspace:Raycast(shard.Position, -Vector3.yAxis * 400, rayParams)
            if ray and ray.Position then
                shootTween = ts:Create(shard, TweenInfo.new((ray.Position - shard.Position).Magnitude * .02), {CFrame = CFrame.new(ray.Position)})
                shootTween:Play()

                shootTween.Completed:Wait()
                hitbox:Stop()

                if shard.Position == ray.Position then
                    print('landed')
                    print((shard.Position - humRoot.Position).Magnitude)
                    task.wait(2.5)
                    skillRoute:FireAllClients('Minya', char, 'ShardShatter', shard.CFrame)

                    local knockbackHits = Hitbox.instant(shard.CFrame, Vector3.one * 4, char)
                    
                    for _,hit in knockbackHits do
                        local hitState = StateService.Get(hit)
                        hitState:Stun('MinyaKnockback', .5, 2)
                        local ragdoll = RagdollService.Get(hit)
                        ragdoll:Ragdoll(hit, 1)
                        hitState:Knockback(char, (shard.Position - CENTER).Unit * 30 + Vector3.yAxis * 10, .3)
                    end

                    shard:Destroy()
                end
            end
        end)
    end

    task.wait(1)

    SkillService.Cooldown(char, 'Minya')
    char:SetAttribute('UsingSkill', nil)
end
sk_server['Minya'].Init3 = function(char: Character)
    char:SetAttribute('UsingSkill', 'Minya')

    local humRoot = char.HumanoidRootPart
    
    local state = StateService.Get(char)
    -- state:SetWalkspeed('MinyaCast', 3, 4)

    skillRoute:FireClient(game.Players:GetPlayerFromCharacter(char), 'Minya', char, 'User')

    -- local rng = Random.new()

    -- local neg = rng:NextInteger(0,1) == 0

    local fullCircle = 2 * math.pi
    local radius = 8

    local function getXAndZPositions(angle)
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        return x, z
    end

	local shards = Instance.new('Part')
	shards.CanCollide = false; shards.Anchored = false; shards.Transparency = 1
	shards.Name = 'MinyaShards'
    shards.Massless = true
	shards.Parent = workspace.UnobstructiveAssets
	
	local attachment1 = Instance.new('Attachment')
	attachment1.Parent = shards
	local attachment2 = Instance.new('Attachment')
	attachment2.Parent = humRoot
	
	shards.CFrame = CFrame.new(humRoot.Position)
	
	local weld: RigidConstraint = utility.Weld(shards, humRoot, 'RigidConstraint')
	weld.Attachment0 = attachment1
	weld.Attachment1 = attachment2
	
	
	for i=1, 8 do
		local shard: BasePart = game.ReplicatedStorage.Assets.SkillAssets.MinyaShard:Clone()
        shard.Massless = true
		shard.Parent = shards
		
		local angle = i * (fullCircle / 8)
		local x, z = getXAndZPositions(angle)
		
		local position = (humRoot.CFrame * CFrame.new(x, 0, z)).Position
		shard.CFrame = CFrame.new(position) + Vector3.yAxis * 9.2
		utility.Weld(shard, shards)
		shard.Transparency = 1
	end
	
	local finishedRotating = false
	
	task.defer(function()
		local rotation2 = ts:Create(attachment1, TweenInfo.new(2), {Orientation = Vector3.new(0, 360, 0)})
		rotation2:Play()
		rotation2.Completed:Wait()
		finishedRotating = true
	end)

	for i,shard in shards:GetChildren() do
		if not shard:IsA('BasePart') then continue end
		
        -- local angle = i * (fullCircle / 8)
        -- local x, z = getXAndZPositions(angle)
        
        shard.Size = Vector3.zero
        --shard.Parent = workspace.UnobstructiveAssets

        task.defer(function()
            task.wait()
            shard:WaitForChild('Attachment'):WaitForChild('Dots 2'):Emit(12)
            shard.Attachment:WaitForChild('Smoke'):Emit(1)
			
            task.delay(i/8, function()
                ts:Create(shard, TweenInfo.new(.5), {Transparency = 0, Size = Vector3.new(0.519, 2.78, 0.615) * 2}):Play()
                while shard.Parent == shards and task.wait() do
                    shard.Orientation += Vector3.yAxis
                end
            end)
			
			repeat task.wait() until finishedRotating
            local CENTER: Vector3 = shards.Position

            shard.WeldConstraint:Destroy()
            -- shard.Parent = workspace.UnobstructiveAssets
            shard.Anchored = true

            local hitbox = Hitbox.new()
            hitbox.CoreMode = true
            hitbox.Core = shard; hitbox.OverlapParams.FilterDescendantsInstances = {char, workspace.UnobstructiveAssets}
            hitbox.Single = true; hitbox.Size = Vector3.new(5, 3, 5)
            hitbox.Visualize = true
            --hi 
            local shootTween: Tween
            
            hitbox.HitEvent:Connect(function(hit: Character | BasePart, hitOriginal: BasePart)
                if shootTween then
                    shootTween:Cancel()
                end

                if not hit:FindFirstChild('Humanoid') then return end

                DamageService.Damage(hit, char, 5)

                local hitState = StateService.Get(hit)
                local frozenLimbs = {}
                local function Shatter()
                    print('shattering')
                    hitState:UnStun('MinyaFreeze')

                    if hit.Humanoid.Health <= 0 then
                        -- RemoveLimbs(hit)
                        hit.Head.Transparency = 1
                    end
                    for _,limb in frozenLimbs do
                        limb:Destroy()
                    end
                end

                local hasShattered = false
                
                hitState:Stun('MinyaFreeze', nil, 4)

                task.delay(6, function()
                    if not hasShattered then
                        hasShattered = true
                        Shatter()
                    end
                end)

                local oldHealth = hit.Humanoid.Health
                local shatterDamage = 0
                local hCon; hCon = hit.Humanoid:GetPropertyChangedSignal('Health'):Connect(function()
                    if hasShattered then
                        hCon:Disconnect()
                    end

                    if oldHealth > hit.Humanoid.Health then
                        shatterDamage += oldHealth - hit.Humanoid.Health
                        if shatterDamage >= 10 then
                            hasShattered = true
                            Shatter()
                        end
                    end
                    oldHealth = hit.Humanoid.Health
                end)

                if hit.Humanoid.Health <= 0 then
                    Shatter()
                end

                for _, limb in hit:GetChildren() do
                    if not limb:IsA('BasePart') or limb.Name == 'HumanoidRootPart' then continue end

                    local iceClone = limb:Clone()
                    iceClone:ClearAllChildren()
                    iceClone.CanCollide = false; iceClone.CanQuery = false
                    iceClone.Material = Enum.Material.Ice; iceClone.Reflectance = .2; iceClone.Massless = true; iceClone.Transparency = .4
                    iceClone.Size += Vector3.one * .1; iceClone.Color = Color3.new(0.396078, 0.2, 0.607843)
                    iceClone.Parent = workspace.UnobstructiveAssets
                    iceClone.CFrame = limb.CFrame
                    utility.Weld(iceClone, limb)
                    table.insert(frozenLimbs, iceClone)
                end

                skillRoute:FireAllClients('Minya', char, 'ShardShatter', shard.CFrame)
                shard:Destroy()
            end)

            hitbox:Start()

            local rayParams = RaycastParams.new(); rayParams.FilterDescendantsInstances = {char, workspace.UnobstructiveAssets}; rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local ray = workspace:Raycast(shard.Position, -Vector3.yAxis * 400, rayParams)
            if ray and ray.Position then
                shootTween = ts:Create(shard, TweenInfo.new((ray.Position - shard.Position).Magnitude * .02), {CFrame = CFrame.new(ray.Position)})
                shootTween:Play()

                shootTween.Completed:Wait()
                hitbox:Stop()

                if shard.Position == ray.Position then
                    print('landed')
                    print((shard.Position - humRoot.Position).Magnitude)
                    task.wait(2.5)
                    skillRoute:FireAllClients('Minya', char, 'ShardShatter', shard.CFrame)

                    local knockbackHits = Hitbox.instant(shard.CFrame, Vector3.one * 4, char)
                    
                    for _,hit in knockbackHits do
                        local hitState = StateService.Get(hit)
                        hitState:Stun('MinyaKnockback', .5, 2)
                        local ragdoll = RagdollService.Get(hit)
                        ragdoll:Ragdoll(hit, 1)
                        hitState:Knockback(char, (shard.Position - CENTER).Unit * 30 + Vector3.yAxis * 10, .3)
                    end

                    shard:Destroy()
                end
            end
        end)
    end

    task.wait(1)

    SkillService.Cooldown(char, 'Minya')
    char:SetAttribute('UsingSkill', nil)
end
sk_server['Minya'].Init2 = function(char: Model)
    char:SetAttribute('UsingSkill', 'Minya')

    local humRoot = char.HumanoidRootPart
    
    local state = StateService.Get(char)
    state:SetWalkspeed('MinyaCast', 3, 4)

    skillRoute:FireClient(game.Players:GetPlayerFromCharacter(char), 'Minya', char, 'User')

    local rng = Random.new()

    local neg = rng:NextInteger(0,1) == 0
    for i=1, 12 do
        local shard: BasePart = game.ReplicatedStorage.Assets.SkillAssets.MinyaShard:Clone()
        -- local shard = Instance.new('Part'); shard.Anchored = true; shard.CanCollide = false
        shard.Parent = workspace.UnobstructiveAssets

        local x = rng:NextNumber(3, 8) * (neg and -1 or 1); neg = not neg
        local z = rng:NextNumber(3, 6) * -1
        local y = rng:NextNumber(3, 8)

        shard.CFrame = humRoot.CFrame + humRoot.CFrame.RightVector * x + humRoot.CFrame.LookVector * z + Vector3.yAxis * y
        shard.Size = Vector3.zero

        task.spawn(function()
            task.wait()
            shard:WaitForChild('Attachment'):WaitForChild('Dots 2'):Emit(12)
            shard.Attachment:WaitForChild('Smoke'):Emit(1)

            task.wait(.2)

            ts:Create(shard, TweenInfo.new(.5), {CFrame = CFrame.lookAt(shard.Position, humRoot.Position + humRoot.CFrame.LookVector * 50) * CFrame.Angles(math.rad(90), 0, 0), Size = Vector3.new(0.519, 2.78, 0.615)}):Play()
        
            task.wait(.55)

            local mouse: table = SkillService.GetMouse(char, 'Minya')
            local finalPos: Vector3 = mouse and mouse.Position or humRoot.Position + humRoot.CFrame.LookVector * 50
            finalPos += Vector3.new(rng:NextNumber(0, i/3), 0, rng:NextInteger(0, i/3))

            ts:Create(shard, TweenInfo.new(.3), {CFrame = CFrame.lookAt(shard.Position, finalPos) * CFrame.Angles(math.rad(90), 0, 0)}):Play()
            -- shard.CFrame= CFrame.lookAt(shard.Position, finalPos ) * CFrame.Angles(math.rad(90), 0, 0)
            task.wait(.3)

            local hitbox = Hitbox.new()
            hitbox.CoreMode = true
            hitbox.Core = shard
            hitbox.Size = Vector3.one * 1.5
            hitbox.Single = true
            hitbox.OverlapParams.FilterDescendantsInstances = {char, workspace.UnobstructiveAssets}
            hitbox.OverlapParams.FilterType = Enum.RaycastFilterType.Exclude
            hitbox.Mode = 'Any'

            hitbox.HitEvent:Connect(function(hit: any, hitOriginal: any)
                local finalCFrame = shard.CFrame
                shard:Destroy()

                if hit:FindFirstChild('Humanoid') and hit:GetAttribute('Combo') then
                    DamageService.Damage(hit, char, 3)

                    if hit.Humanoid:GetState() == Enum.HumanoidStateType.Dead then
                        hit.Torso:ClearAllChildren()
                    end

                    local limb: BasePart = hitOriginal

                    local iceClone = limb:Clone()
                    iceClone:ClearAllChildren()
                    iceClone.CanCollide = false; iceClone.CanQuery = false
                    iceClone.Material = Enum.Material.Ice; iceClone.Reflectance = .2; iceClone.Massless = true; iceClone.Transparency = .4
                    iceClone.Size += Vector3.one * .1; iceClone.Color = Color3.new(0.396078, 0.2, 0.607843)
                    iceClone.Parent = workspace.UnobstructiveAssets
                    iceClone.CFrame = limb.CFrame
                    utility.Weld(iceClone, limb)

                elseif hit:IsA('BasePart') then
                    print('hit part')
                    -- VoxelService:DestroyPartsInBounds(finalCFrame, 1.5)
                    -- VoxelService:UnfreezePartsInBounds(finalCFrame, 3)
                    game.ReplicatedStorage.Remotes.Voxelize:FireAllClients('Destroy', Vector3.one * 3, finalCFrame, Enum.PartType.Ball, nil, 20)
                    game.ReplicatedStorage.Remotes.Voxelize:FireAllClients('Unfreeze', Vector3.one * 6, finalCFrame, Enum.PartType.Ball, nil, 20)
                end

                skillRoute:FireAllClients('Minya', char, 'ShardShatter', finalCFrame)
            end)

            hitbox:Start()

            ts:Create(shard, TweenInfo.new(1), {CFrame = CFrame.lookAt(shard.Position + (finalPos - shard.Position).Unit * 70, shard.Position + (finalPos - shard.Position).Unit * 75) * CFrame.Angles(math.rad(90),0,0)}):Play()

            -- local bv = Instance.new('BodyVelocity')
            -- bv.MaxForce = Vector3.one * 100000
            -- bv.Velocity = (finalPos - shard.Position).Unit * 5
            -- bv.Parent = shard

            -- shard.Anchored = false
            -- shard:SetNetworkOwner(nil)

            task.wait(15)
            hitbox:Stop()
            shard:Destroy()

        end)
        if i == 6 then
            task.wait(1)
        end
    end

    task.wait(1.5)
    state:EndWalkspeed('MinyaCast')

    SkillService.Cooldown(char, 'Minya')
    char:SetAttribute('UsingSkill', nil)
end

sk_server['EMM'] = {}
local timings = {}
sk_server['EMM'].Init = function(char: Model)
    SkillService.UsingSkill(char, true, 'EMM') 

    local plr = game.Players:GetPlayerFromCharacter(char)

    local hum = char.Humanoid
    local humRoot = char.HumanoidRootPart

    local keyDirection = -humRoot.CFrame.LookVector

    local state = StateService.Get(char)

    -- Makes the character not affected by attacks but still have damage sent to them
    state:Superarmor(true, 1)
    state:SetWalkspeed('EMM', 6, 0)

    local counterAnim = hum.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.EMM.Counter)
    counterAnim:Play()

    local timer = os.clock()
    local hasCountered = false
    DamageService.AddDamageEvent(char, 'EMM', function(attacker:Model, damage: number, haltKilling: boolean?)
        if os.clock() - timer > .6 then return end
        hasCountered = true

        skillRoute:FireClient(plr, 'EMM', char, 'Cutscene')

        task.spawn(function()
            counterAnim:Stop()
            
            state:IFrame(true, 2)
            hum.AutoRotate = false
            
            print('countered!!')
            local hitState = StateService.Get(attacker)
            hitState:Stun('EMMCounter')

            local attackAnim = hum.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.EMM.Attack)
            attackAnim:Play()
            attackAnim:AdjustSpeed(.7)

            -- GRAB SEQUENCE
            attacker.HumanoidRootPart.CFrame = CFrame.lookAt(attacker.HumanoidRootPart.Position, humRoot.Position)

            attackAnim:GetMarkerReachedSignal('Grab1'):Wait()
            humRoot.Anchored = true

            local rag = RagdollService.Get(attacker)
            rag:Ragdoll(attacker)

            attacker.Head.CFrame = char['Left Arm'].CFrame - char['Left Arm'].CFrame.UpVector * 1.5

            local weld: BallSocketConstraint = utility.Weld(char['Left Arm'], attacker.Head, 'BallSocketConstraint')
            local att0: Attachment, att1: Attachment = Instance.new('Attachment'), Instance.new('Attachment')
            att0.Parent = attacker.Head; att0.WorldCFrame = attacker.Head.CFrame + attacker.Head.CFrame.LookVector * .3
            att1.Parent = char['Left Arm']; att1.WorldCFrame = char['Left Arm'].CFrame - char['Left Arm'].CFrame.UpVector
            weld.Attachment0 = att0; weld.Attachment1 = att1
            weld.Restitution = 10

            attackAnim:GetMarkerReachedSignal('ThrowScene'):Wait()
            skillRoute:FireClient(plr, 'EMM', char, 'Cutscene', 'Throwing')

            -- SLAM SEQUENCE

            attackAnim:GetMarkerReachedSignal('Throw'):Wait()
            attacker.HumanoidRootPart.CFrame = humRoot.CFrame - humRoot.CFrame.LookVector * 2.2 - Vector3.yAxis

            weld.Parent = nil
            hitState:Knockback(char, -Vector3.yAxis*10, .7)
            -- rag:UnRagdoll(attacker)

            game.ReplicatedStorage.Remotes.Voxelize:FireAllClients('Unfreeze', Vector3.one * 6, attacker.HumanoidRootPart.CFrame, Enum.PartType.Ball, nil, 20)

            game.ReplicatedStorage.Remotes.DisplayEffect:FireAllClients(
                'Crater', {
                    CFrame = attacker.HumanoidRootPart.CFrame, Size = 5,
                    Direction = -Vector3.yAxis * 20, Rows = 2,
                    emitDebris = true, emitSmoke = true, createSound = false,
                },
                'Camera', {
                    Magnitude = 4, Roughness = 4, FadeInTime = .1, FadeOutTime = 1, 
                    PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                    Origin = attacker.HumanoidRootPart.Position, Radius = 100
                }
            )

            DamageService.Damage(attacker, char, 5, true)

            -- NECKHOLD SEQUENCE

            attackAnim:GetMarkerReachedSignal('Grab2'):Wait()

            weld.Parent = char['Left Arm']

            for i=1, 2 do
                attackAnim:GetMarkerReachedSignal('Punch'..i):Wait()

                DamageService.Damage(attacker, char, 2, true)

                game.ReplicatedStorage.Remotes.DisplayEffect:FireAllClients(
                    'Camera', {
                        Magnitude = 2, Roughness = 4, FadeInTime = .1, FadeOutTime = 1, 
                        PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                        Origin = attacker.HumanoidRootPart.Position, Radius = 100
                    }
                )

                if i == 2 then
                    skillRoute:FireClient(plr, 'EMM', char, 'Cutscene', 'GutPunch')
                end
            end

            -- STOMACH THRUST SEQUENCE
            attackAnim:GetMarkerReachedSignal('TwicePress'):Wait()

            timings[char] = attacker

            attackAnim:GetMarkerReachedSignal('Thrust'):Wait()
            
            DamageService.Damage(attacker, char, 10)
            weld:Destroy()
            
            hitState:Knockback(char, keyDirection * 50, .1)

            if timings[char] == false then
                attackAnim:Stop()
                humRoot.CFrame = CFrame.lookAt(humRoot.Position, humRoot.Position + keyDirection * 5)
                skillRoute:FireAllClients('EMM', char, 'Thrust', attacker)
                print('init1 endeeeed')
                task.spawn(function()
                    task.wait(1.2)

                    rag:UnRagdoll(attacker)

                    task.wait(5.8)
                    hitState:UnStun('EMMCounter')
                end)
                return
            else
                timings[char] = nil
                skillRoute:FireClient(plr, 'EMM', char, 'Cutscene', false)
            end

            state:EndWalkspeed('EMM')
            humRoot.Anchored = false

            attackAnim.Stopped:Wait()
            humRoot.CFrame = CFrame.lookAt(humRoot.Position, humRoot.Position + keyDirection)
            hum.AutoRotate = true

            SkillService.UsingSkill(char, false)
            SkillService.Cooldown(char, 'EMM')

            task.wait(1.2)

            rag:UnRagdoll(attacker)

            task.wait(2.8)
            hitState:UnStun('EMMCounter')
        end)

        return 'Interruption'
    end)

    local highlight = game.ReplicatedStorage.Assets.SkillAssets.EMMHighlight:Clone()
    highlight.Parent = char

    local fade = ts:Create(highlight, TweenInfo.new(1), {FillTransparency = 1}); fade:Play()
    fade.Completed:Wait()
    highlight:Destroy()

    repeat
        RunService.Heartbeat:Wait()
    until os.clock() - timer > .6

    if not hasCountered then
        state:EndWalkspeed('EMM')
        counterAnim:Stop()

        SkillService.UsingSkill(char, false)
        SkillService.Cooldown(char, 'EMM')
    end
end

sk_server['EMM'].Init2 = function(char: Model)
    if timings[char] then
        local attacker = timings[char]
        timings[char] = false
        print('attack 2!')

        local plr1 = game.Players:GetPlayerFromCharacter(char)

        local humRoot = char.HumanoidRootPart
        local hum = char.Humanoid
        Prom.try(function()
            local state = StateService.Get(char)
            state:EndWalkspeed('EMM')
            humRoot.Anchored = false

            humRoot.CFrame = CFrame.lookAt(humRoot.Position, Vector3.new(attacker.HumanoidRootPart.Position.X, humRoot.Position.Y, attacker.HumanoidRootPart.Position.Z))

            print('playing animation')
            local minyaCastAnim = hum.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.EMM.MinyaCall)
            minyaCastAnim:Play()
            minyaCastAnim:AdjustSpeed(.2)

            skillRoute:FireClient(plr1, 'EMM', char, 'MinyaCutscene', attacker)

            minyaCastAnim:GetMarkerReachedSignal('Call'):Wait()

            local shard: BasePart = game.ReplicatedStorage.Assets.SkillAssets.MinyaShard:Clone()
            shard.Parent = workspace.UnobstructiveAssets

            shard.CFrame = humRoot.CFrame + humRoot.CFrame.LookVector * 2 - humRoot.CFrame.RightVector * .6
            shard.Size = Vector3.zero

            task.wait()
            shard:WaitForChild('Attachment'):WaitForChild('Dots 2'):Emit(12)
            shard.Attachment:WaitForChild('Smoke'):Emit(1)

            ts:Create(shard, TweenInfo.new(.5), {CFrame = CFrame.lookAt(shard.Position, attacker.HumanoidRootPart.Position) * CFrame.Angles(math.rad(90), 0, 0), Size = Vector3.new(0.519, 2.78, 0.615) * 3}):Play()
            
            task.wait(.6)

            local tw = ts:Create(shard, TweenInfo.new(.2), {CFrame = CFrame.lookAt(attacker.Torso.Position, shard.Position + (attacker.HumanoidRootPart.Position - shard.Position).Unit * 75) * CFrame.Angles(math.rad(90),0,0)})
                        
            tw:Play()

            tw.Completed:Wait()
            shard:Destroy()

            -------

            local finalCFrame = shard.CFrame
            shard:Destroy()
            minyaCastAnim:Stop()

            skillRoute:FireAllClients('Minya', char, 'ShardShatter', finalCFrame)

            DamageService.Damage(attacker, char, 3, true)

            local limb: BasePart = attacker.Torso

            local iceClone = limb:Clone()
            iceClone:ClearAllChildren()
            iceClone.CanCollide = false; iceClone.CanQuery = false
            iceClone.Material = Enum.Material.Ice; iceClone.Reflectance = .2; iceClone.Massless = true; iceClone.Transparency = .4
            iceClone.Size += Vector3.one * .1; iceClone.Color = Color3.new(0.396078, 0.2, 0.607843)
            iceClone.Parent = workspace.UnobstructiveAssets
            iceClone.CFrame = limb.CFrame
            utility.Weld(iceClone, limb)

            local sprintAnim = hum.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.EMM.Sprint)
            sprintAnim:Play()

            -- state:Knockback(char, humRoot.CFrame.LookVector * 28, .5)
            local tw2 = ts:Create(humRoot, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.lookAt(attacker.HumanoidRootPart.Position + attacker.HumanoidRootPart.CFrame.LookVector * 3.5, attacker.HumanoidRootPart.Position)})

            tw2:Play()
            tw2.Completed:Wait()

            sprintAnim:Stop()

            SkillService.UsingSkill(char, false)
            SkillService.Cooldown(char, 'EMM')

            hum.AutoRotate = true -- remove after

            SkillService.UsingSkill(char, false)
            SkillService.Cooldown(char, 'EMM')

           
        end):andThen(function(result)
            skillRoute:FireClient(plr1, 'EMM', char, 'Cutscene', false)
            if result == 'MinyaFail' then
                hum.AutoRotate = true

                SkillService.UsingSkill(char, false)
                SkillService.Cooldown(char, 'EMM')

                task.wait(1.2)

                -- local rag = RagdollService.Get(attacker)
                -- rag:UnRagdoll(attacker)

                -- task.wait(2.8)

                -- local hitState = StateService.Get(attacker)
                -- hitState:UnStun('EMMCounter')
            end
        end):catch(function(err)
            
            warn(err)
        end)
    else
        timings[char] = nil
    end
end

sk_server['EMT'] = {}

sk_server['EMT'].Init = function(char: Character)
    local humRoot = char.HumanoidRootPart
    local hum = char.Humanoid

    local skillHandler = SkillService.CreateSkill(char, 'EMT', {})

    local userState = StateService.Get(char)
    skillHandler.Runtime = function()
        userState:SetWalkspeed('EMT', 5, 0)

        SkillService.UsingSkill(char, true, 'EMT')

        local ORIGIN = humRoot.Position

        local fullCircle = 2 * math.pi
        local radius = 20

        local lookVector = humRoot.CFrame.LookVector
        local angleOffset = math.deg(math.atan2(lookVector.x, -lookVector.z))
        local function getXAndZPositions(angle)
            local x = (math.cos(angle)) * radius
            local z = (math.sin(angle)) * radius
            return x, z
        end

        local barrier = game.ReplicatedStorage.Assets.SkillAssets.SpiritKnight.EMTBarrierCube:Clone()
        barrier.Parent = workspace.UnobstructiveAssets
        local field = barrier:WaitForChild('Field')
        local core = barrier:WaitForChild('Core')
        -- core:SetNetworkOwner(nil)
        field:SetNetworkOwner(nil)
        core.Anchored = true
        -- field.Anchored = true

        local hitbox = Hitbox.new()
        hitbox.CoreMode = true
        hitbox.Core = core
        hitbox.OverlapParams.FilterDescendantsInstances = {char}
        hitbox.Size = field.Size

        hitbox.HitEvent:Connect(function(hit: Character)
            local state = StateService.Get(hit)
            state:Stun('EMTWave', .3, 4)

            local ragdoll = RagdollService.Get(hit)
            ragdoll:Ragdoll(hit, 1.5)

            DamageService.Damage(hit, char, 10)

            hit:SetAttribute('SkillsDisabled', true)

            task.delay(7, function()
                hit:SetAttribute('SkillsDisabled', nil)
            end)
        end)
        
        hitbox:Start()

        userState:EndWalkspeed('EMT')

        core.Size = Vector3.zero
        field.Size = Vector3.zero
        ts:Create(core, TweenInfo.new(.3), {Size = Vector3.one * 9}):Play()
        ts:Create(field, TweenInfo.new(.3), {Size = Vector3.one * 10}):Play()

        skillRoute:FireClient(game.Players:GetPlayerFromCharacter(char), 'EMT', char, 'Mouse')

        local lookVector = humRoot.CFrame.LookVector
        -- print(lookVector)

        local lengthA = lookVector.X
        local lengthB = lookVector.Z

        local angleOffset = math.abs(math.deg(math.atan(lengthB/lengthA)))

        local AIsPositive = math.abs(lengthA) == lengthA
        local BIsPositive = math.abs(lengthB) == lengthB
        
        if not AIsPositive and BIsPositive then -- Quadrant 2
            angleOffset = 180 - angleOffset
        elseif not AIsPositive and not AIsPositive then -- Quadrant 3
            angleOffset = 180 + angleOffset
        elseif AIsPositive and not BIsPositive then -- Quadrant 4
            angleOffset = 360 - angleOffset
        end
       
        local startLevel = humRoot.Position.Y
        local voxelExhaust = os.clock()
        for i=angleOffset, angleOffset + 360, 3 do
            local currentDeg = i
            if i > 360 then
                currentDeg = i - 360
            end
            local angle = currentDeg * (fullCircle/360) --+ angleOffset
            local x, z = getXAndZPositions(angle)
            local endPosition: Vector3 = Vector3.new(humRoot.Position.X + x, startLevel, humRoot.Position.Z + z)

            local xAngle, yAngle, zAngle = core.CFrame:ToOrientation()
            core.CFrame = CFrame.new(endPosition) * CFrame.Angles(xAngle + math.rad(math.random(2)), yAngle +math.rad(math.random(2)), zAngle + math.rad(math.random(2)))

            task.wait()

            if os.clock() - voxelExhaust >= .1 then
                voxelExhaust = os.clock()
                Voxelize:FireAllClients('Unfreeze', Vector3.new(12, .5, 12), CFrame.new(core.CFrame.Position - Vector3.yAxis * 3.1), nil, nil, 15)
            end
        end        

        hitbox:Stop()

        core.Anchored = true
        local finalPos = core.Position

        local mouse: CFrame = SkillService.GetMouse(char, 'EMT')

        local unit: Vector3 | nil = mouse and (humRoot.Position - mouse.Position).Unit or nil
        if mouse and unit:Dot((humRoot.Position - core.Position).Unit) >= .98 then
            ts:Create(field, TweenInfo.new(.4), {Size = field.Size * 1.6}):Play()
            local grow = ts:Create(core, TweenInfo.new(.3), {Size = core.Size * 1.6})
            grow:Play()
            grow.Completed:Wait()

            for i=.75, .25, -.25 do
                if i == .75 then
                    print('first iteration')
                    local caught = Hitbox.instant(core.CFrame, core.Size, char)
                    for _,opp in caught do
                        local state = StateService.Get(opp)
                        state:Stun('EMTGridlock', nil, 5)
                    end
                else
                    task.wait(.4)
                end
                ts:Create(field, TweenInfo.new(.4), {Size = field.Size * (i - .25)}):Play()
                local shrink = ts:Create(core, TweenInfo.new(.3), {Size = core.Size * (i - .25)})
                shrink:Play()
                shrink.Completed:Wait()
            end
            
            local endCatches = Hitbox.instant(CFrame.new(finalPos), Vector3.one * 9, char)
            for _, opp in endCatches do
                DamageService.Damage(opp, char, 15)

                local ragdoll = RagdollService.Get(opp)
                ragdoll:Ragdoll(opp, 2)
                local state = StateService.Get(opp)
                local rng = Random.new()
                state:Knockback(char, Vector3.new(rng:NextNumber(0,1), rng:NextNumber(0,1), rng:NextNumber(0,1)) * 70, .2)

                task.delay(1, function()
                    state:UnStun('EMTGridlock')
                end)
            end

            Voxelize:FireAllClients('Destroy', Vector3.one * 10, CFrame.new(finalPos), Enum.PartType.Ball, nil, 35)
            Voxelize:FireAllClients('Unfreeze', Vector3.one * 22, CFrame.new(finalPos), Enum.PartType.Ball, nil, 35, Vector3.yAxis * 10)

            game.ReplicatedStorage.Remotes.DisplayEffect:FireAllClients(
                'Camera', {
                    Magnitude = 8, Roughness = 4, FadeInTime = .1, FadeOutTime = 1, 
                    PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                    Origin = core.Position, Radius = 100
                }
            )
        else
            ts:Create(field, TweenInfo.new(1), {Size = Vector3.zero}):Play()
            local shrink = ts:Create(core, TweenInfo.new(1), {Size = Vector3.zero})
            shrink:Play()
            shrink.Completed:Wait()

            game.ReplicatedStorage.Remotes.DisplayEffect:FireAllClients(
                'Camera', {
                    Magnitude = 1.7, Roughness = 4, FadeInTime = .1, FadeOutTime = 1, 
                    PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                    Origin = core.Position, Radius = 100
                }
            )
        end

        barrier:Destroy()
    end

    skillHandler.CleanUp = function()
        SkillService.Cooldown(char, 'EMT')
        SkillService.UsingSkill(char, false, 'EMT')
    end

    skillHandler:Run()
end

sk_server['EMT'].Init_OLD = function(char: Character)
    local humRoot = char.HumanoidRootPart
    local hum = char.Humanoid

    local skillHandler = SkillService.CreateSkill(char, 'EMT', {['Start'] = 0})

    local userState = StateService.Get(char)
    skillHandler.Runtime = function()
        userState:SetWalkspeed('EMT', 5, 0)

        SkillService.UsingSkill(char, true, 'EMT')

        local ORIGIN = humRoot.Position

        local fullCircle = 2 * math.pi
        local radius = 20

        local function getXAndZPositions(angle)
            local x = math.cos(angle) * radius
            local z = math.sin(angle) * radius
            return x, z
        end
        
        local lines = Instance.new('Folder')
        lines.Name = 'Lines_'..char.Name
        lines.Parent = workspace.UnobstructiveAssets

        local groundPosition: Vector3

        local params = RaycastParams.new(); params.FilterDescendantsInstances = {workspace.Characters, workspace.UnobstructiveAssets}; params.FilterType = Enum.RaycastFilterType.Exclude
        local ray = workspace:Raycast(humRoot.Position, -Vector3.yAxis * 500, params)
        if ray and ray.Position then
            groundPosition = ray.Position
        else
            groundPosition = humRoot.Position - Vector3.yAxis * 3
        end

        local tweensFinished = false

        for i=1, 8 do
            local angle = i * (fullCircle / 8)
            local x, z = getXAndZPositions(angle)
            local endPosition: Vector3 = groundPosition + Vector3.new(x,0,z)
            
            local line = Instance.new('Part')
            line.CanCollide = false
            line.CanQuery = false; line.Anchored = true
            line.CFrame = CFrame.lookAt(groundPosition, endPosition)
            line.Size = Vector3.new(1, .3, 1)
            line.Color = Color3.new(0.831372, 0.486274, 0.992156)
            line.Material = Enum.Material.SmoothPlastic
            line.Parent = lines

            local tween = ts:Create(line, TweenInfo.new(.5), {CFrame = CFrame.lookAt(groundPosition + (endPosition - groundPosition)/2, endPosition), Size = Vector3.new(1,.3, radius/2 * 1.5)})
            tween:Play()
            tween.Completed:Connect(function(playbackState)
                local tween2 = ts:Create(line, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.lookAt(endPosition, endPosition + line.CFrame.LookVector), Size = Vector3.new(1,.3, 1)})
                tween2:Play()
                tween2.Completed:Wait()

                local tween3 = ts:Create(line, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.lookAt(endPosition, endPosition + line.CFrame.LookVector), Size = Vector3.new(16,.3, 1)})
                tween3:Play()
                tween3.Completed:Wait()

                local tween4 = ts:Create(line, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.lookAt(endPosition, endPosition + line.CFrame.LookVector), Size = Vector3.new(16, 4, 1)})
                tween4:Play()
                tween4.Completed:Wait()

                tweensFinished = true

                -- local tween5 = ts:Create(line, TweenInfo.new(.3), {CFrame = CFrame.lookAt(groundPosition, endPosition), Size = Vector3.new(5,4, 1)})
                local tween5 = ts:Create(line, TweenInfo.new(.7), {Transparency = 1})
                tween5:Play()
                tween5.Completed:Wait()

                -- line.Transparency = 1
            end)
        end

        repeat
            RunService.Heartbeat:Wait()
        until tweensFinished

        local hits = Hitbox.instant(humRoot.CFrame, Vector3.new(radius*2, 4, radius*2), char)

        userState:EndWalkspeed('EMT')

        for _,v in hits do
            v:SetAttribute('SkillsDisabled', true)

            local state = StateService.Get(v)
            state:Stun('EMTQuake', 1.5, 4)

            local ragdoll = RagdollService.Get(v)
            ragdoll:Ragdoll(v, 2)

            state:Knockback(char, Vector3.yAxis * 30, .3)

            task.delay(5, function()
                v:SetAttribute('SkillsDisabled', false)
            end)
        end

        Voxelize:FireAllClients('Unfreeze', Vector3.new(22, 5, 22), CFrame.new(groundPosition), nil, 4, 20, Vector3.yAxis * 25)
    end

    skillHandler.CleanUp = function()
        SkillService.UsingSkill(char, false, 'EMT')
    end

    skillHandler:Run()
end

local alShamakRing = game.ReplicatedStorage.Assets.SkillAssets.SpiritKnight.AlShamakRing:Clone()
sk_server['Al Shamak'] = {}
sk_server['Al Shamak'].Init = function(char: Model)
    local humRoot = char.HumanoidRootPart
    local hum = char.Humanoid

    local skillHandler = SkillService.CreateSkill(char, 'Al Shamak', {
        ['Start'] = 0,
    })

    local state = StateService.Get(char)

    state:SetWalkspeed('Al Shamak', 6, 0)
    SkillService.UsingSkill(char, true, 'Al Shamak')
    hum.AutoRotate = false

    local summonAnim: AnimationTrack

    skillHandler.Runtime = function()
        summonAnim = hum.Animator:LoadAnimation(animations.SkillAnimations.ShamakCast)
        summonAnim:Play()
        task.wait(.6)
        summonAnim:AdjustSpeed(0)
        task.wait(.4)

        local sound: Sound = ReplicatedStorage.Assets.Sounds.SpiritKnight.AlShamakBlink:Clone()
        sound.Parent = char
        for i=1, 2 do
            alShamakRing.Parent = workspace.UnobstructiveAssets
            alShamakRing.CFrame = humRoot.CFrame - Vector3.yAxis * 2.2

            if i == 1 then
                alShamakRing:WaitForChild("Attachment"):WaitForChild('ParticleEmitter').Size = NumberSequence.new(4, 7)
            else
                alShamakRing:WaitForChild("Attachment"):WaitForChild('ParticleEmitter').Size = NumberSequence.new(7,10)
            end

            alShamakRing.Attachment.ParticleEmitter:Emit(3)

            sound:Play()
            print('tick.')

            local darkHits = Hitbox.instant(humRoot.CFrame + humRoot.CFrame.LookVector * 20, Vector3.one * 55)
            for _,v in darkHits do
                local plr = game.Players:GetPlayerFromCharacter(v)
                if plr then
                    skillRoute:FireClient(plr, 'Al Shamak', char, 'DarkBlink')
                end
            end

            task.wait(1.3)
            sound:Stop()
        end
        sound:Destroy()

        local alShamakBlock = ReplicatedStorage.Assets.SkillAssets.SpiritKnight.AlShamakBlock:Clone()
        alShamakBlock.Name = 'AlShamakBlock'..char.Name
        alShamakBlock.CFrame = humRoot.CFrame + humRoot.CFrame.LookVector * 20
        alShamakBlock.Parent = workspace.UnobstructiveAssets

        skillHandler.CurrentSection = 'Summoning'

        local killbox = Hitbox.new()
        killbox.CoreMode = true
        killbox.Core = alShamakBlock
        killbox.Offset = Vector3.zero
        killbox.Size = Vector3.one * 50
        killbox.OverlapParams.FilterDescendantsInstances = {char}

        local att2 = Instance.new('Attachment')
        att2.Parent = alShamakBlock

        local caught = {}
        
        killbox.HitEvent:Connect(function(hit: Character | BasePart, baseHit: BasePart)
            if hit:IsA('Model') then
                -- 
                table.insert(caught, hit)

                local alignPosition = Instance.new('AlignPosition')
                alignPosition.Mode = Enum.PositionAlignmentMode.TwoAttachment
                
                local att1 = Instance.new('Attachment')
                att1.Parent = hit.HumanoidRootPart

                alignPosition.Attachment0 = att1
                alignPosition.Attachment1 = att2

                alignPosition.Parent = hit.HumanoidRootPart
                -- alignPosition.MaxVelocity = Vector3.one * 10000
                alignPosition.RigidityEnabled = true
            end
        end)

        killbox:Start()
        task.spawn(function()

            for i=1, 7 do
                game.ReplicatedStorage.Remotes.Voxelize:FireAllClients('Destroy', Vector3.one * (50/7 * i), humRoot.CFrame + humRoot.CFrame.LookVector * 20, Enum.PartType.Ball, nil, 50)
                task.wait(1/7)
            end

            game.ReplicatedStorage.Remotes.Voxelize:FireAllClients('Unfreeze', Vector3.one * 62, humRoot.CFrame + humRoot.CFrame.LookVector * 20, Enum.PartType.Ball, nil, 50)
        
            local tween = ts:Create(alShamakBlock, TweenInfo.new(3.5), {CFrame = alShamakBlock.CFrame + Vector3.yAxis * 30})
            tween:Play()
            tween.Completed:Wait()

            for _, hit in caught do
                for _,limb in hit:GetDescendants() do
                    if limb:IsA('BasePart') then
                        limb.Transparency = 1
                    end
                end
            end

            for _,v in alShamakBlock:WaitForChild('Attachment'):GetChildren() do
                task.defer(function()
                    for i = 0, 3, .05 do
                        v.Size = NumberSequence.new(v.Size.Keypoints[1].Value - i/3 * v.Size.Keypoints[1].Value)
                        task.wait(.05)
                    end
                end)
                -- ts:Create(v, TweenInfo.new(3), {Size = NumberSequence.new(0)}):Play()
            end

            task.wait(2)

            killbox:Stop()
            alShamakBlock:Destroy()

            for _, hit in caught do
                DamageService.Damage(hit, char, hit.Humanoid.MaxHealth)

                local plr = game.Players:GetPlayerFromCharacter(hit)
                if plr then
                    skillRoute:FireClient(plr, 'Al Shamak', char, 'Killed')
                end
            end
        end)

        skillRoute:FireAllClients('Al Shamak', char, 'Summoning')

        local summonSound: Sound = ReplicatedStorage.Assets.Sounds.SpiritKnight.AlShamakSummon:Clone()
        summonSound.Parent = char.HumanoidRootPart
        summonSound:Play()
        summonSound.Ended:Once(function()
            summonSound:Destroy()
        end)
    end

    skillHandler.CleanUp = function()
        if summonAnim and summonAnim.IsPlaying then
            summonAnim:Stop()
        end

        SkillService.UsingSkill(char, false, 'Al Shamak')
        state:EndWalkspeed('Al Shamak')
        SkillService.Cooldown(char, 'Al Shamak')
        hum.AutoRotate = true
    end

    skillHandler:Run()
end

sk_server['Special'].Init_Awakened = function(char: Character)
    local stuns = char.Values.Stuns

    if #stuns:GetChildren() > 0 then
        SkillService.UsingSkill(char, true, 'Special')

        skillRoute:FireAllClients('Special', char, 'Call')
        task.wait(1)

        local closestAttackers = {}
        for _,v in char.Values.Attackers:GetChildren() do
            if os.clock() - v.Value <= 10 and (workspace.Characters[v.Name].HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude <= 20 then
                table.insert(closestAttackers, workspace.Characters[v.Name])
            end
        end

        local DURATION = 5.5

        local humRoot = char.HumanoidRootPart

        local userState = StateService.Get(char)
        userState:Stun('Return By Death', DURATION, 8)
        userState:IFrame(true, DURATION)
        skillRoute:FireClient(game.Players:GetPlayerFromCharacter(char), 'Special', char, 'Mist')
        -- humRoot.Anchored = true

        for _,opp in closestAttackers do
            local opponentState = StateService.Get(opp)
            opponentState:Stun('Return By Death', DURATION, 8)
            opponentState:IFrame(true, DURATION)
            local plr = game.Players:GetPlayerFromCharacter(char)
            if not plr then -- In case it's an NPC
                local humRoot = opp.HumanoidRootPart
                humRoot.Anchored = true
            
                local anims = opp.Humanoid.Animator:GetPlayingAnimationTracks()
                local oldSpeeds = {}
                for i,v: AnimationTrack in anims do
                    oldSpeeds[v] = v.Speed
                    v:AdjustSpeed(0)
                end
            
                task.delay(4, function()
                    humRoot.Anchored = false
            
                    for i,v: AnimationTrack in anims do
                        v:AdjustSpeed(oldSpeeds[v])
                    end
                end)
            else
                skillRoute:FireClient(plr, 'Special', char, 'Mist')
            end
            -- v.HumanoidRootPart.Anchored = true
        end

        -- to freeze camera just set camera to scriptable

        task.wait(DURATION)

        for _, opp in closestAttackers do
            local opponentState = StateService.Get(opp)
            opponentState:Stun('RBD End', .4, 2)
            local ragdoll = RagdollService.Get(opp)
            ragdoll:Ragdoll(opp, 1.5)
            opponentState:Knockback(char, (opp.HumanoidRootPart.Position - humRoot.Position).Unit * 10, .2)
        end

        SkillService.UsingSkill(char, false, 'Special')
        SkillService.Cooldown(char, 'Special', 30)
    end
end

return sk_server