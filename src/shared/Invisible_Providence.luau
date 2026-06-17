-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService('TweenService')

-- Services
local Services = require(ReplicatedStorage.Shared.Services)
local StateService = Services.StateService
local SkillService = Services.SkillService
local AnimationService = Services.AnimationService
local HitboxService = Services.HitboxService
local DamageService = Services.DamageService
local RagdollService = Services.RagdollService

local utility = require(ReplicatedStorage.Modules.Utility)
local BezierCurve = require(ReplicatedStorage.Modules.bezierCurve)

-- Resources / Assets
local Assets = ReplicatedStorage.Assets
local Animations = Assets.Animations
local Remotes = ReplicatedStorage.Remotes

local skill = {}

type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: BasePart}

skill.Init = function(char: Character, extra)
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

        SkillService.RouteToClient('Invisible Providence', char, 'Limbs', 'All', limbs)

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

        hitbox = HitboxService.new()
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
            
            if not lungeMode then
                -- ragdoll:Ragdoll(hit, 3)
                ragdoll:Ragdoll_(3, {DestructionPower = 12})
                hitState:Knockback(char, Vector3.yAxis * 50, .3)
                -- task.wait(.2)
                -- HitboxService.CollisionEvent(target, function(collidedPart, direction, ray)
                --     SkillService.CoreVoxelDestruction({Core = target.HumanoidRootPart, LaunchDirection = humRoot.CFrame.LookVector * 30}, Vector3.one * 7, 0, nil, 30, 40, true)
                -- end, 3, nil, 3, false, {-Vector3.yAxis}, false)
            else
                ragdoll:Ragdoll_(3, {DestructionPower = 4, GainVerticalVelocity = true})
                hitState:Knockback(char, humRoot.CFrame.LookVector * 35, .3)
                -- task.wait(.2)
                -- HitboxService.CollisionEvent(target, function(collidedPart, direction, ray)
                --     SkillService.CoreVoxelDestruction({Core = target.HumanoidRootPart, LaunchDirection = humRoot.CFrame.LookVector * 30}, Vector3.one * 7, 0, nil, 30, 40, true)
                -- end, 2, nil, 3, false)
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
        -- print('dude are you reenabling autorotate')
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
                TweenService:Create(v, TweenInfo.new(2), {Transparency = 1}):Play()
            end
            task.wait(2)
            limbs:Destroy()
        end
    end
    
    skillObj:Run()
end

return skill