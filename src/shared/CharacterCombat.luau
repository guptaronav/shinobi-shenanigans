
local RepStorage: ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage: ServerStorage = game:GetService('ServerStorage')
local TweenService = game:GetService('TweenService')
local animations: Folder = RepStorage.Assets.Animations
local remotes: Folder = RepStorage.Remotes
local RunService = game:GetService('RunService')

local AnimationService = require(RepStorage.Shared.Services.AnimationService)
local CombatService = require(RepStorage.Shared.Services.CombatService)
local HitboxService = require(RepStorage.Shared.Services.Hitbox)
local Promise = require(RepStorage.Shared.Services.Promise)
local SkillService = require(RepStorage.Shared.Services.SkillService)

local DamageService, StateService, RagdollService
if RunService:IsServer() then
    DamageService = require(ServerStorage.RojoStorage.Modules.DamageService)
    StateService = require(ServerStorage.RojoStorage.Modules.StateService)
    RagdollService = require(ServerStorage.RojoStorage.Modules.RagdollService)
end

local utility = require(RepStorage.Modules.Utility)

local sk_combat = {}

type Character = Model

--- LOCAL FUNCTIONS

local function DeltaTime(Type)
    local dt
    if Type == 'Stepped' then
        local _, d = RunService.Stepped:Wait()
        dt = d
    else
        dt = RunService[Type]:Wait()
    end
    -- local _, dt = RunService[Type]:Wait()
    return dt
end

local function DeltaWait(time: number)
    local a = os.clock()
    repeat
        RunService.RenderStepped:Wait()
    until os.clock() - a > time
    -- print(os.clock() - a)
end

----

local CombatStats = {
    M1Animation = function(char: Character, index: number): Folder
        return animations.Punches['Punch'..index]
    end,
    M1Interval =  function(char: Character, isFinal: boolean): number
        return isFinal and 1.5 or 0.5
    end,
    M1Damage = function(char: Character): number
        return 3
    end,
    SpeedAnimation = function(char: Character, running: boolean): Animation
        if running then
            return animations.Run
        end
    end,
    Speed = function(char: Character, running: boolean): number
        local plr = game.Players:GetPlayerFromCharacter(char)
        if plr and plr.Data.UltimateActivated.Value then
            return running and 23 or 13
        end
        return running and 21 or 13
    end,
}

sk_combat['Update'] = function(char: Character)
    CombatService.UpdateCombo(char, 4)
end

local vfx: Part = game.ReplicatedStorage.Assets.Effects.PunchSpark:Clone(); vfx.Parent = workspace.UnobstructiveAssets
sk_combat['BasicAttack'] = {}

sk_combat['BasicAttack'].ClientInit = function(char: Character, extra)
    local humRoot = char.HumanoidRootPart
    local hum = char.Humanoid

    local punchId = 'Punch'..char:GetAttribute('Combo')
    -- if char:GetAttribute('Combo') < 4 then
    --     state:SetWalkspeed(punchId, 3, char:GetAttribute('WalkSpeed') - 3)
    --     task.delay(.2, function() state:EndWalkspeed(punchId) end)
    -- else
    --     state:SetWalkspeed(punchId, 3, 0)
    --     task.delay(.62, function() state:EndWalkspeed(punchId) end) -- 1 // Also add this to Spirit Knight noob
    -- end

    if char:GetAttribute('Combo') == 4 then
        CombatService.M1Cooldown(char, CombatStats.M1Interval(char, true))
    else
        CombatService.M1Cooldown(char, CombatStats.M1Interval(char))
    end 

    local playPunchAnim = hum.Animator:LoadAnimation(CombatStats.M1Animation(char, char:GetAttribute('Combo')))
    playPunchAnim:Play()
    -- task.wait(.05)
    
    -- playPunchAnim:GetMarkerReachedSignal("Hit"):Once(function()

    local caught = {}
    task.spawn(function()
        -- Promise.try(function(resolve, reject, onCancel)
        remotes.AttackM1:FireServer({Begin = true, Combo = char:GetAttribute('Combo')})
        
        task.wait(.15)
        for i=1, 2 do
            local hits = HitboxService.instant(humRoot.CFrame + humRoot.CFrame.LookVector * 4 * .5, Vector3.new(4.5, 1.5, 4), char, nil, false)
            for _,v in hits do
                table.insert(caught, v)
            end
            task.wait(.01)
        end

        local hits = {}

        for _,v in caught do
            if not table.find(hits, v) then
                table.insert(hits, v)
            end
        end

        for _,v in hits do
            if char.Values.Stuns:FindFirstChildWhichIsA('NumberValue') or v:GetAttribute('IFrame') or v:GetAttribute('Ragdolled') then return end

            if v:GetAttribute('Blocking')then
                if CombatService.Blockable(v, char) then
                    remotes.AttackM1:FireServer({Target = v, Combo = char:GetAttribute('Combo'), Blocked = true})
                    continue 
                end
            end

            remotes.AttackM1:FireServer({Target = v, Combo = char:GetAttribute('Combo')})
        end

        if #caught > 0 then
            game.ReplicatedStorage.Remotes.DisplayEffect_Client:Fire(
                'Camera', {
                    Magnitude = .5, Roughness = 2, FadeInTime = .1, FadeOutTime = 1, 
                    PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                    Origin = humRoot.Position, Radius = 20
                }
            )
        end
        -- char:SetAttribute("Attacking",false)
    end)

    local swingSound = RepStorage.Assets.Sounds.PunchSwings:GetChildren()[math.random(#RepStorage.Assets.Sounds.PunchSwings:GetChildren())]:Clone()
    swingSound.Parent = humRoot
    swingSound:Destroy()
end

sk_combat['BasicAttack'].Server = function(char: Character, extra: table)
    local humRoot = char.HumanoidRootPart
    local v = extra.Target
    local state = StateService.Get(char)
    
    if extra.Begin then
        -- print('begin?', extra.Combo)
        local punchId = 'Punch'..extra.Combo
        if extra.Combo < 4 then
            state:SetWalkspeed(punchId, 3, char:GetAttribute('WalkSpeed') - 3)
            task.delay(.2, function() state:EndWalkspeed(punchId) end)
        else
            state:SetWalkspeed(punchId, 3, 0)
            task.delay(.62, function() state:EndWalkspeed(punchId) end) -- 1 // Also add this to Spirit Knight noob

            SkillService.CoreVoxelDestruction({
                Core = humRoot, OffsetRelativeTo = {'LookVector'}, Offset = {2.5}, LaunchDirectionRelativeTo = {'LookVector'}, LaunchDirection = {20} 
            }, Vector3.one * 5, 0, Enum.PartType.Ball, 5, 15)
        end
        return
    end

    if char.Values.Stuns:FindFirstChildWhichIsA('NumberValue') or  v:GetAttribute('IFrame') or v:GetAttribute('Ragdolled') then return end

    if extra.Blocked then
        local sfx = game.ReplicatedStorage.Assets.Sounds.Misc.BlockImpact:Clone()
        sfx.Parent = v.Head
        sfx:WaitForChild('EqualizerSoundEffect').HighGain = math.random(-15, -10)
        sfx:Destroy()
    end

    if v:GetAttribute('Blocking')then
        if CombatService.Blockable(v, char) then
            return 
        else
            CombatService.Block(v, false)
        end
    end

    local result = DamageService.Damage(v, char, CombatStats.M1Damage(char))
    if result == 'Interruption' then return end

    -- if extra.Weapon == 'Sword' then return end

    local hitState = StateService.Get(v)
    hitState:Stun('LightPunch', 1)

    if extra.Combo == 4 then
        hitState:Knockback(char, humRoot.CFrame.LookVector * 80, 1, nil, true, {Vector3.yAxis})

        local KnockbackAnim = v.Humanoid.Animator:LoadAnimation(animations.Backdash)
        KnockbackAnim:Play(); --KnockbackAnim:AdjustSpeed(1.4)

        HitboxService.CollisionEvent(v, function(collidedPart, direction, ray)
            local ragdoll = RagdollService.Get(v)
            if ragdoll then
                ragdoll:Ragdoll(v, 1.75)
            end     
            SkillService.CoreVoxelDestruction({Core = v.HumanoidRootPart, LaunchDirection = humRoot.CFrame.LookVector * 20}, Vector3.one * 7, 0, Enum.PartType.Ball, 25, 32)
        end, 2, nil, 1, false, {Vector3.yAxis, -Vector3.yAxis}, true)
    else
        state:Velocity((v.HumanoidRootPart.Position - humRoot.Position).Unit * 3, .2, nil, {Vector3.yAxis})

        hitState:Knockback(char, humRoot.CFrame.LookVector * 1, .1)
        task.defer(function()
            local anim = v.Humanoid.Animator:LoadAnimation(animations.Punched['Punched'..extra.Combo]); anim:Play()
        end)
    end

    remotes.BodyFlash:FireAllClients(v)

    local sfx = game.ReplicatedStorage.Assets.Sounds.PunchSounds:GetChildren()[math.random(1,5)]:Clone()
    sfx.Parent = v.Head
    sfx:Play()
    game.Debris:AddItem(sfx,5)

    task.spawn(function()
        --sup
        vfx.CFrame = v.HumanoidRootPart.CFrame
        vfx:WaitForChild('Attachment'):WaitForChild('Hit1'):Emit(2)
    end)
end

sk_combat['AerialAttack'] = {}
sk_combat['AerialAttack'].ClientInit = function(char: Character)
    print"downslam"

    local humRoot = char.HumanoidRootPart
    local hum = char.Humanoid

    -- CombatService.UpdateCombo(char, 4)
    CombatService.M1Cooldown(char, CombatStats.M1Interval(char, true))
    -- local state = StateService.Get(char)
    -- state:SetWalkspeed('Downslam', 3, 0)
    -- task.delay(.5, function()
    --     state:EndWalkspeed('Downslam')
    -- end)

    local downslamAnim = AnimationService.LoadAnimation(char, game.ReplicatedStorage.Assets.Animations.Downslam)-- hum.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.Downslam)
    downslamAnim:GetMarkerReachedSignal('hitreg'):Once(function()
        char:SetAttribute("Attacking",0)

        local hits = HitboxService.instant({Core=humRoot, OffsetIsRelativeTo = {'LookVector', 'UpVector'}, Offset = {2, -2}}, Vector3.new(5,4,5.5), char, nil)--, game.Players:GetPlayerFromCharacter(char))
        for _,v in hits do
            if v:GetAttribute("Ragdolled") or v:GetAttribute('IFrame') or char.Values.Stuns:FindFirstChildWhichIsA('NumberValue') then continue end

            remotes.AttackM1:FireServer({Variant = 'Aerial', Target = v})
        end

        if #hits > 0 then
            remotes.DisplayEffect_Client:Fire(
                'Crater', {
                CFrame = hits[1].HumanoidRootPart.CFrame, Size = 6,
                Direction = -Vector3.yAxis * 20, Rows = 1,
                emitDebris = true, emitSmoke = false, createSound = false,
                },
                'Camera', {
                    Magnitude = 3, Roughness = 4, FadeInTime = .1, FadeOutTime = 1, 
                    PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                    Origin = humRoot.Position, Radius = 20
            })

            local downslamSound = RepStorage.Assets.Sounds.Explosions.Downslam:Clone()
            downslamSound.Parent = humRoot
            downslamSound:Destroy()
        end

        print('do aerial stuff')
        remotes.AttackM1:FireServer({Variant = 'Aerial'})
    end)
    downslamAnim:Play()
end

sk_combat['AerialAttack'].Server = function(char, extra)
    local target = extra.Target

    if not target then
        SkillService.CoreVoxelDestruction({
            Core = char.HumanoidRootPart, OffsetRelativeTo = {'UpVector'}, Offset = {-2}, LaunchDirection = -Vector3.yAxis*5  
        }, Vector3.new(5,3,5), 0, nil, 8, 15)
        return
    end

    if target:GetAttribute("Ragdolled") or target:GetAttribute('Superarmor') or target:GetAttribute('IFrame') or char.Values.Stuns:FindFirstChildWhichIsA('NumberValue') then return end

    DamageService.Damage(target, char, 6)

    local state = StateService.Get(target)
    state:Stun('Downslam', .1)

    local ragdoll = RagdollService.Get(target)
    ragdoll:Ragdoll(target, 3.2)
    state:Knockback(char, -Vector3.yAxis * 20, .2)

    remotes.BodyFlash:FireAllClients(target)
end

local grabQueue = {}
sk_combat['UpperAttack'] = function(char: Character)
    CombatService.UpdateCombo(char, 4)
    CombatService.M1Cooldown(char, CombatStats.M1Interval(char, true))

    local hum = char.Humanoid
    local humRoot = char.HumanoidRootPart

    local state = StateService.Get(char)

    grabQueue[char] = true

    state:SetWalkspeed('Grab/Uppercut', 3, 4)

    local lungeAnim = hum.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.ArmLungeStart)
    lungeAnim:Play()
    lungeAnim.Stopped:Wait()

    local doUppercut = not grabQueue[char]
    grabQueue[char] = nil

    if doUppercut then
        task.delay(.7, function() state:EndWalkspeed('Grab/Uppercut') end)

        local anim = hum.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.Uppercut)
        anim:Play()
        -- anim:GetMarkerReachedSignal("hitreg"):Connect(function()
        -- char:SetAttribute("Attacking", false)

        local hits = HitboxService.instant(humRoot.CFrame + humRoot.CFrame.LookVector * 3, Vector3.new(4, 1.5, 4), char, nil, false, game.Players:GetPlayerFromCharacter(char))
        for _,v in hits do
            if v:GetAttribute('Blocking') then
                if CombatService.Blockable(v, char) then
                    continue 
                else
                    CombatService.Block(v, false)
                end
            end

            if v:GetAttribute('IFrame') or char.Values.Stuns:FindFirstChildWhichIsA('NumberValue') then continue end

            DamageService.Damage(v, char, 3)
            local state = StateService.Get(v)
                state:Stun('Uppercut', 1.8)
            local ragdoll = RagdollService.Get(v)
            ragdoll:Ragdoll(v, 3.2)
            state:Knockback(char, Vector3.yAxis * 45, .2)

            remotes.BodyFlash:FireAllClients(v)
        end
    else
        local charLookVector = humRoot.CFrame.LookVector

        -- char:SetAttribute("Attacking", false)
    
        local anim: AnimationTrack = hum.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.Grab)
        anim:Play()
        -- anim:GetMarkerReachedSignal("hit"):Connect(function()
        local hit = HitboxService.instant(humRoot.CFrame + humRoot.CFrame.LookVector * 3, Vector3.one * 5, char, nil, true, game.Players:GetPlayerFromCharacter(char))
        if not hit then anim:Stop(.3) 
            task.delay(.4, function() state:EndWalkspeed('Grab/Uppercut') end)
            return
        else
            task.delay(1.2, function() state:EndWalkspeed('Grab/Uppercut') end)
        end

        if CombatService.Blockable(hit, char, -.6) and not hit:GetAttribute('Blocking') then return end

        if hit:GetAttribute('IFrame') or char.Values.Stuns:FindFirstChildWhichIsA('NumberValue') then return end

        local state = StateService.Get(hit)
        if not state then return end

        state:Stun('GrabAttack', 6)
        hit.Humanoid.PlatformStand = true
        local ragdoll = RagdollService.Get(hit)
        ragdoll:Ragdoll(hit, 6)

        for _,v in hit:GetChildren() do
            if v:IsA('BasePart') then
                v.Massless = true
            end
        end

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = char["Right Arm"]
        weld.Part1 = hit.HumanoidRootPart
        weld.Parent = weld.Part0

        anim:GetMarkerReachedSignal('throw'):Wait()
        weld:Destroy()
        state:Knockback(char, -charLookVector * 50 + Vector3.yAxis * 8, .2)

        for _,v in hit:GetChildren() do
            if v:IsA('BasePart') then
                v.Massless = false
            end
        end

        local collision, direction, position = HitboxService.WaitForCollision(hit, true)
        if direction == -Vector3.yAxis then
            DamageService.Damage(hit, char, 5)
            -- remotes.Debris:FireAllClients('RadialV', 4, 2, hit.HumanoidRootPart.Position, true, 25)
        end
    end
end

if RunService:IsServer() then
    game.ReplicatedStorage.Remotes.Grab.OnServerEvent:Connect(function(player) 
        grabQueue[player.Character] = nil
    end)
end

sk_combat['FrontDash'] = {}
sk_combat['FrontDash'].ServerInit = function(char: Character)

    local soundEffect: Sound = RepStorage.Assets.Sounds.DashSounds.BasicDashOld:Clone()
    soundEffect.Parent = char.HumanoidRootPart
    soundEffect:Play()

    task.delay(.8, function ()
        soundEffect:Destroy()
    end)
    return true
end

sk_combat['FrontDash'].ClientInit = function(char: Character)
    local hum = char.Humanoid
    local humRoot = char.HumanoidRootPart

    local bv = Instance.new("BodyVelocity")
    bv.Parent = char.HumanoidRootPart
    bv.MaxForce = Vector3.new(25000,0,25000)
    
    local amt = 75
    if hum.FloorMaterial == Enum.Material.Air or hum.FloorMaterial == nil then
        amt = 60
    end

    bv.Velocity = humRoot.CFrame.LookVector*amt 

    local dashLockAnim = game.ReplicatedStorage.Assets.Animations.DashLock
    local anim = hum.Animator:LoadAnimation(dashLockAnim)
    anim:Play()

    task.spawn(function()
        while task.wait() and bv.Parent == char.HumanoidRootPart do
            amt /= 1.03
            bv.Velocity = humRoot.CFrame.LookVector*amt
        end
    end)

    local dashRing = game.ReplicatedStorage.Assets.Effects.DashRing:Clone()
    dashRing.CFrame = (humRoot.CFrame + humRoot.CFrame.LookVector * 2.5) * CFrame.Angles(math.rad(90), 0, 0)
    dashRing.Parent = workspace.UnobstructiveAssets
    local tw = TweenService:Create(dashRing, TweenInfo.new(.5), {Transparency = 1, Size = Vector3.new(6, .5, 6), CFrame = dashRing.CFrame - humRoot.CFrame.LookVector * 2.5}); tw:Play()
    tw.Completed:Once(function()
        dashRing:Destroy()
    end)

    -- TweenService:Create(bv, TweenInfo.new(.45), {MaxForce = Vector3.zero})
    task.wait(.5)

    bv:Destroy()

    anim:Stop()
    remotes.Dash:InvokeServer({Type = 'Front', Route = 'Attack'})
end

sk_combat['FrontDash'].Attack = function(char: Character)
    -- local char = player.Character or player.CharacterAdded:Wait()
    local humRoot = char:FindFirstChild('HumanoidRootPart')
    local hum = char:FindFirstChild('Humanoid')

    local anim = hum.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.DashFinal)
    -- anim:GetMarkerReachedSignal('hit'):Connect(function()
        local hits = HitboxService.instant({Core = humRoot, OffsetIsRelativeTo = {'LookVector'}, Offset = {2.8}}, Vector3.new(5,1.5,5), char, nil, nil, game.Players:GetPlayerFromCharacter(char))

        for _,v in hits do
            if (v.HumanoidRootPart.Position - humRoot.Position).Magnitude > 20 or v == char then continue end
            if v:GetAttribute('Blocking') then
                if CombatService.Blockable(v, char) then
                   continue 
                else
                    CombatService.Block(v, false)
                end
            end
            if v:GetAttribute('IFrame') or char.Values.Stuns:FindFirstChildWhichIsA('NumberValue') then continue end

            DamageService.Damage(v, char, 3)
            local state = StateService.Get(v)
            state:Stun('DashAttack', 1)
            state:Knockback(char, humRoot.CFrame.LookVector * 1, .1)
            local anim = v.Humanoid.Animator:LoadAnimation(animations.Punched["Punched1"]); anim:Play()

            remotes.BodyFlash:FireAllClients(v)

            local sfx = game.ReplicatedStorage.Assets.Sounds.PunchSounds:GetChildren()[math.random(1,5)]:Clone()
		    sfx.Parent = v.Head
			sfx:Play()
			game.Debris:AddItem(sfx,5)
        end

    SkillService.CoreVoxelDestruction({
        Core = humRoot, OffsetRelativeTo = {'LookVector'}, Offset = {2.5}, LaunchDirectionRelativeTo = {'LookVector'}, LaunchDirection = {20} 
    }, Vector3.one * 6, 0, Enum.PartType.Ball, 5, 12)
        -- end)
    anim:Play()

    local state = StateService.Get(char)
    state:SetWalkspeed('DashAttack', 3, 0)

    local exhaust = os.clock()
    repeat game:GetService"RunService".Heartbeat:Wait()
        char.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
    until os.clock() - exhaust >= .5

    state:EndWalkspeed('DashAttack')
end

sk_combat['SideDash'] = {}
sk_combat['SideDash'].ServerInit = function(char: Character)

    local dashBlocks = {}
    for i,v in char:GetChildren() do
        if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' and v.Name ~= 'Torso' then
            dashBlocks[i] = game.ReplicatedStorage.Assets.Effects.DashBlock:Clone()
            dashBlocks[i].Parent = workspace.UnobstructiveAssets
            dashBlocks[i].CFrame = v.CFrame
            utility.Weld(dashBlocks[i], v)
        end
    end
    
    local soundEffect: Sound = RepStorage.Assets.Sounds.DashSounds.BasicDash:Clone()
    soundEffect.Parent = char.HumanoidRootPart
    soundEffect:Play()

    task.delay(.8, function()
        for _,v in dashBlocks do
            v:Destroy()
        end
        soundEffect:Destroy()
    end)

    return true
end

sk_combat['SideDash'].ClientInit = function(char: Character)
    local humRoot = char.HumanoidRootPart
    local hum = char.Humanoid
    local cam = workspace.CurrentCamera

    local uis = game:GetService('UserInputService')

    local isLeft = uis:IsKeyDown(Enum.KeyCode.A)

    -- local bv = Instance.new("BodyVelocity")
    -- bv.Parent = char.HumanoidRootPart
    -- bv.MaxForce = Vector3.new(25000,0,25000)
    local bv = Instance.new('LinearVelocity')
    bv.Parent = humRoot
    bv.Attachment0 = humRoot.RootAttachment
    -- bv.MaxForce = 25000
    bv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    bv.RelativeTo = Enum.ActuatorRelativeTo.World
    bv.ForceLimitsEnabled = true
    bv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    bv.MaxAxesForce = Vector3.new(25000, 0, 25000)

    local amt = 50
    -- Velocity is greater while in the air so this balances it out.
    if hum.FloorMaterial == Enum.Material.Air or hum.FloorMaterial == nil then 
        amt = 45
    end
    amt *= isLeft and -1 or 1
    bv.VectorVelocity = cam.CFrame.RightVector*amt 

    task.spawn(function()
        local sideDashAnim = game.ReplicatedStorage.Assets.Animations[isLeft and "SideDashLeft" or "SideDashRight"]
        local anim = hum.Animator:LoadAnimation(sideDashAnim)
        anim:Play()
        -- anim:AdjustSpeed(1.7)

        local rubbleDeb = 0
        local rng = Random.new()
        local tweenTimer = os.clock()
        -- local executionLimit = 60 * 0.5
        -- local executions = 0
        -- local executionLimitReached = os.clock()
        while bv.Parent == char.HumanoidRootPart do
            local dt = DeltaTime('Stepped'); --print(dt)
            
            if os.clock()- tweenTimer >= .4 then -- original: .1
                amt /= 1.45
                -- print(60 - 60 * dt)
                -- for i=1, 60 - 60 * dt do
                -- for i=1, math.max(0, (1/60 - dt)*(1/dt)) + 1 do
                    -- if executions >= executionLimit then 
                        -- if executionLimitReached ~= -1 then
                            -- warn('Execution limit reach within '..(os.clock() - executionLimitReached)..' seconds')
                            -- executionLimitReached = -1
                        -- end
                        -- break 
                    -- end
                    -- executions += 1
                    -- print(math.round(30-fps/2))
                -- end
            end
            bv.VectorVelocity = cam.CFrame.RightVector*amt

            if os.clock() - rubbleDeb >= rng:NextNumber(.1, .4) then
                rubbleDeb = os.clock()

                local rParams = RaycastParams.new(); rParams.FilterDescendantsInstances = {char, workspace.UnobstructiveAssets}; rParams.FilterType = Enum.RaycastFilterType.Exclude
                local ray = workspace:Raycast(humRoot.Position, -Vector3.yAxis * 4.1, rParams)
                if ray and ray.Instance then
                    local rubble1, rubble2 = Instance.new('Part'), Instance.new('Part')
                    rubble1.CanCollide = false; rubble2.CanCollide = false; rubble1.CanQuery = false; rubble2.CanQuery = false
                    rubble1.Anchored = true; rubble2.Anchored = true
                    rubble1.Material = ray.Instance.Material; rubble2.Material = ray.Instance.Material
                    rubble1.Color = ray.Instance.Color; rubble2.Color = ray.Instance.Color
                    rubble1.Size = Vector3.one * .5; rubble2.Size = Vector3.one * .5

                    rubble1.CFrame = CFrame.new(ray.Position + humRoot.CFrame.LookVector) * CFrame.Angles(math.rad(rng:NextNumber(0, 359)),math.rad(rng:NextNumber(0, 359)),math.rad(rng:NextNumber(0, 359)))
                    rubble2.CFrame = CFrame.new(ray.Position - humRoot.CFrame.LookVector) * CFrame.Angles(math.rad(rng:NextNumber(0, 359)),math.rad(rng:NextNumber(0, 359)),math.rad(rng:NextNumber(0, 359)))
                    
                    rubble1.Parent = workspace.UnobstructiveAssets; rubble2.Parent = workspace.UnobstructiveAssets
                    task.delay(8, function()
                        rubble1:Destroy(); rubble2:Destroy()
                    end)
                end
            end
        end
        -- warn("AMT:",amt)
    end)

    local bodyGyro = Instance.new('BodyGyro')
    bodyGyro.Parent = humRoot
    bodyGyro.MaxTorque = Vector3.new(9999999, 9999999, 0)
    bodyGyro.D = 50
    bodyGyro.CFrame = CFrame.lookAt(humRoot.Position, workspace.CurrentCamera.CFrame.LookVector * 1000000)
    -- bodyGyro.P = 500

    DeltaWait(.5)
    -- task.wait(.5)
    bv:Destroy()
    bodyGyro:Destroy()
end

local runAnims = {}
sk_combat['Run'] = function(char: Character, enable: boolean)
    local state = StateService.Get(char)
    local runAnimation = runAnims[char] or char.Humanoid.Animator:LoadAnimation(CombatStats.SpeedAnimation(char, true))
    if not runAnims[char] then runAnims[char] = runAnimation end

    if enable then
        char:SetAttribute('WalkSpeed', 21)
        state:SetWalkspeed('Run', 1, 21)
        runAnimation:Play()
    else
        char:SetAttribute('WalkSpeed', 13)
        state:SetWalkspeed('Walk', 1, 13)
        runAnimation:Stop()
    end
end

sk_combat['Regenerate'] = function(char: Character, enable: boolean): nil
    local state = StateService.Get(char)
    local hum = char.Humanoid

    if enable then
        state:SetWalkspeed('Regenerating', 4, 0)

        local spirits = game.ReplicatedStorage.Assets.Effects.Spirits:Clone()
        spirits.Name = char.Name..'Spirits'
        spirits.CFrame = char.HumanoidRootPart.CFrame
        spirits.Parent = workspace.UnobstructiveAssets
        
        while task.wait(.75) and char:GetAttribute('Regenerating') do
            if char:GetAttribute('Ragdolled') or char.Values:FindFirstChildWhichIsA('NumberValue') or char:GetAttribute('Blocking') or char:GetAttribute('UsingSkill') then return end
            hum.Health += 1
        end
    else
        state:EndWalkspeed('Regenerating')

        local spirits = workspace.UnobstructiveAssets:FindFirstChild(char.Name..'Spirits')
        if spirits then
            spirits:Destroy()
        end
    end
end

return sk_combat