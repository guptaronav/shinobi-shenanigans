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

local selfGoaTimings = {}

skill.Init = function(char: Character, extra: table)
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
        local castAnim = AnimationService.LoadAnimation(char, Animations.SpiritKnight.RentalGoa, 'Skill')
        castAnim:Play()
        castAnim:AdjustSpeed(3)

        castAnim:GetMarkerReachedSignal('Spawn'):Wait()
        castAnim:AdjustSpeed(1)

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

        local hitbox = HitboxService.new()
        hitbox.CoreMode = true
        hitbox.Core = laSpirit
        hitbox.Size = Vector3.one * 4
        hitbox.OverlapParams.FilterDescendantsInstances = {char}
        hitbox.Single = true

        state:Superarmor(false)
    
        local tween = TweenService:Create(laSpirit, TweenInfo.new(.8), {CFrame = laSpirit.CFrame + laSpirit.CFrame.LookVector * 12})
        
        hitbox.HitEvent:Connect(function()
            tween:Cancel()
        end)

        hitbox:Start()
        tween:Play()
        
        repeat task.wait() until tween.PlaybackState == Enum.PlaybackState.Completed or tween.PlaybackState == Enum.PlaybackState.Cancelled
        hitbox:Stop()

        -- SkillService.VoxelDestruction(laSpirit.CFrame, Vector3.one * 8, 0, Enum.PartType.Ball, 40, 50, 'Explosion_45')

        local hits = HitboxService.instant(laSpirit.CFrame, Vector3.one * 11, char)
        for _, hit in hits do
            DamageService.Damage(hit, char, 7)
            local hitState = StateService.Get(hit)
            local ragdoll = RagdollService.Get(hit)
            ragdoll:Ragdoll(hit, 3)
            hitState:Knockback(char, (hit.HumanoidRootPart.Position - laSpirit.Position).Unit * 20, .2, nil, nil, {Vector3.yAxis})
        end

        SkillService.RouteToClient('Rental Goa', char, 'Explosion', 'All', laSpirit)
        SkillService.VoxelDestruction(laSpirit.CFrame, Vector3.one * 10, 3, Enum.PartType.Ball, 30, 40, 'Explosion_20')
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

skill.Init2 = function(char: Character, extra: table)
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

        local castAnim = AnimationService.LoadAnimation(char, Animations.SpiritKnight.SelfGoa, 'Skill')
        castAnim:Play()
        castAnim:AdjustSpeed(.9)

        castAnim.Stopped:Wait()
        task.wait(.02)

        SkillService.VoxelDestruction(laSpirit.CFrame, Vector3.one * 20, 3, Enum.PartType.Ball, 40, 50, 'Explosion_50')

        local hits = HitboxService.instant(laSpirit.CFrame, Vector3.one * 15)
        for _, hit in hits do
            if hit == char then
                DamageService.Damage(hit, char, 7)
            else
                DamageService.Damage(hit, char, 10)
            end
            local hitState = StateService.Get(hit)
            local ragdoll = RagdollService.Get(hit)
            ragdoll:Ragdoll(hit, 3)
            hitState:Knockback(char, (hit.HumanoidRootPart.Position - laSpirit.Position).Unit * 28, .2, nil, nil, {Vector3.yAxis})
        end

        SkillService.RouteToClient('Rental Goa', char, 'Explosion', 'All', laSpirit, true)

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
        state:Superarmor(false)

        SkillService.UsingSkill(char, false, 'Rental Goa')
        AnimationService.RemoveHands(char, 'Right')
    end

    skillHandler:Run()
end

return skill