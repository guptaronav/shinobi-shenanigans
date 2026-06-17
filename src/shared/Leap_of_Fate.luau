-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Services
local Services = require(ReplicatedStorage.Shared.Services)
local SkillService = Services.SkillService
local AnimationService = Services.AnimationService
local StateService = Services.StateService
local HitboxService = Services.HitboxService
local DamageService = Services.DamageService
local RagdollService = Services.RagdollService

local Utility = require(ReplicatedStorage.Modules.Utility)

-- Resources / Assets
local Assets = ReplicatedStorage.Assets

local skill = {}

type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: BasePart}

local groundParams = RaycastParams.new()
groundParams.FilterDescendantsInstances = {workspace.Map}
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.RespectCanCollide = true

function skill.Init(char: Character, extra: table)
	SkillService.UsingSkill(char, true, "Leap of Fate")

	local skillHandler = SkillService.CreateSkill(char, "Leap of Fate", { Start = 0, Stop = 5})

	local humRoot = char.HumanoidRootPart
    local hum = char.Humanoid
	local state = StateService.Get(char)
	state:SetWalkspeed("Leap of Fate", 5, 0)
    char.Humanoid.AutoRotate = false

    local hitbox
    local chargeAnim
    local alignment
    local beatriceRig: Model = Assets.SkillAssets.SpiritKnight.BeatriceRig:Clone()

	skillHandler.Runtime = function()

        beatriceRig.Parent = workspace.UnobstructiveAssets
        -- beatriceRig.HumanoidRootPart.Anchored = true
        local beatriceAnim = AnimationService.LoadAnimation(beatriceRig, Assets.Animations.SpiritKnight.Awakening.LeapOfFate_Beatrice, 'Stand')
        beatriceAnim:Play()

        -- beatriceRig.HumanoidRootPart.Anchored = false
        beatriceRig.HumanoidRootPart.CFrame = humRoot.CFrame
        local weld = Instance.new('WeldConstraint')
        weld.Parent = beatriceRig.HumanoidRootPart
        weld.Part0 = beatriceRig.HumanoidRootPart
        weld.Part1 = char.HumanoidRootPart

        SkillService.RouteToClient('Leap of Fate', char, 'BeatricePoof', 'All', beatriceRig)

        skillHandler:AddEvent(beatriceAnim:GetMarkerReachedSignal('Detach'), function()
            if weld then
                weld:Destroy()
            end
            beatriceRig.HumanoidRootPart.Anchored = true
        end)

        local jumpAnim = AnimationService.LoadAnimation(char, Assets.Animations.SpiritKnight.Awakening.LeapOfFate_Jump, 'Skill')
        jumpAnim:Play()

        SkillService.RouteToClient('Leap of Fate', char, 'HorizontalLeap', 'All')
        
        skillHandler:AddEvent(jumpAnim:GetMarkerReachedSignal('Jump'), function()
            local alignmentPos = humRoot.CFrame.Position + humRoot.CFrame.LookVector * 10 + Vector3.yAxis * 24
            local aPosUnit = ((humRoot.CFrame.Position + humRoot.CFrame.LookVector * 13 + Vector3.yAxis * 24) - humRoot.CFrame.Position).Unit
            local aPosMagnitude = ((humRoot.CFrame.Position + humRoot.CFrame.LookVector * 13 + Vector3.yAxis * 24) - humRoot.CFrame.Position).Magnitude

            SkillService.VoxelDestruction(CFrame.lookAt(humRoot.CFrame.Position + aPosUnit * aPosMagnitude*.5, alignmentPos), Vector3.new(5, 5, aPosMagnitude), 3, nil, 30, 40, aPosUnit * 100)

            alignment = Instance.new("AlignPosition")
            alignment.Attachment0 = humRoot.RootAttachment
            alignment.Position = alignmentPos
            alignment.ForceLimitMode = Enum.ForceLimitMode.PerAxis
            alignment.Mode = Enum.PositionAlignmentMode.OneAttachment
            alignment.Responsiveness = 20
            -- alignment.RigidityEnabled = true
            alignment.Parent = humRoot
            
            hum.PlatformStand = true

            SkillService.RouteToClient('Leap of Fate', char, 'VerticalLeap', 'All')
        end):Wait()

        skillHandler:AddEvent(jumpAnim:GetMarkerReachedSignal('Stop'), function()
            skillHandler.CurrentSection = 'Stop'
            jumpAnim:AdjustSpeed(.6)
            beatriceAnim:AdjustSpeed(.6)

            char:AddTag('DisableRotating')
            SkillService.RouteToClient('Leap of Fate', char, 'Aim_Air', game.Players:GetPlayerFromCharacter(char))
            SkillService.RouteToClient('Leap of Fate', char, 'Vita', 'All')
        end):Wait()

        skillHandler:AddEvent(jumpAnim.Stopped, function()
            local mouse = SkillService.GetMouse(char, "Leap of Fate")
            local finalPos = mouse and mouse.Position or humRoot.Position + humRoot.CFrame.LookVector * 70
            local tooFar = false
            if mouse then
                if (finalPos - humRoot.CFrame.Position).Magnitude > 80 then
                    finalPos = humRoot.CFrame.Position + (finalPos - humRoot.CFrame.Position).Unit * 80
                    tooFar = true
                end
            end

            chargeAnim = AnimationService.LoadAnimation(char, Assets.Animations.SpiritKnight.Awakening.LeapOfFate_Charge, 'Skill')
            chargeAnim:Play()

            alignment:Destroy()
            SkillService.RouteToClient('Leap of Fate', char, 'Aim_Straight', game.Players:GetPlayerFromCharacter(char), finalPos)
            -- state:Velocity((finalPos - humRoot.Position).Unit * 100, 5)

            local unit = (finalPos - humRoot.Position).Unit
            local originalCFrame = CFrame.lookAt(humRoot.Position, finalPos)
            local intervals = math.ceil((finalPos - humRoot.Position).Magnitude / 80 * 12)
            for i=1, intervals do
                humRoot.CFrame = originalCFrame:Lerp(CFrame.lookAt(finalPos, finalPos + unit), i/intervals)--
                task.wait()
            end
            -- local chargeTween = TweenService:Create(humRoot, TweenInfo.new(.3), {CFrame = CFrame.lookAt(finalPos, finalPos + unit)})
            -- chargeTween:Play()
            -- chargeTween.Completed:Wait()

            hum.PlatformStand = false
            
            if not tooFar then
                humRoot.AssemblyLinearVelocity = Vector3.zero
                local hits = HitboxService.instant(CFrame.new(finalPos), Vector3.one * 15, char, Enum.PartType.Ball, false)
                for _, hit in hits do
                    DamageService.Damage(hit, char, 20)
                    local tState = StateService.Get(hit)
                    tState:Stun('FateDenied', 3, 3)
                    local ragdoll = RagdollService.Get(hit)
                    ragdoll:Ragdoll(hit, 4)
                    tState:Knockback(char, Vector3.yAxis * 45, .3)
                end
                SkillService.VoxelDestruction(CFrame.new(finalPos), Vector3.new(15, 15, 15), 3, Enum.PartType.Ball, 40, 60, 'Explosion_35')
                game.ReplicatedStorage.Remotes.DisplayEffect:FireAllClients(
                    'Camera', {
                        Magnitude = 9, Roughness = 10, FadeInTime = .1, FadeOutTime = 1, 
                        PosInfluence = Vector3.one, RotInfluence = Vector3.zero, 
                        Origin = humRoot.Position, Radius = 100
                    }
                )
            else
                state:Stun('VitaFail', 3, 4)
                local ragdoll = RagdollService.Get(char)
                task.delay(.1, function()
                    ragdoll:Ragdoll(char, 3)
                end)
                state:Velocity(unit* 70, .2, nil, {Vector3.yAxis})
            end

            SkillService.RouteToClient('Leap of Fate', char, 'Stop_Aim_Straight', game.Players:GetPlayerFromCharacter(char))
            SkillService.RouteToClient('Leap of Fate', char, 'Cleanup', 'All', nil, finalPos)
        end):Wait()
	end

	skillHandler.CleanUp = function()
        if hitbox then
            hitbox:Stop()
        end
        if alignment then
            alignment:Destroy()
        end
        if chargeAnim then
            chargeAnim:Stop()
        end
        if skillHandler.CurrentSection == 'Start' then
            -- SkillService.RouteToClient('Leap of Fate', char, 'Aim_Air', game.Players:GetPlayerFromCharacter(char))
            SkillService.RouteToClient('Leap of Fate', char, 'Cleanup', 'All', true)
        end
        char.Humanoid.AutoRotate = true
        char.Humanoid.PlatformStand = false
        char:RemoveTag("DisableRotating")

		state:EndWalkspeed("Leap of Fate")
		SkillService.Cooldown(char, "Leap of Fate")
		SkillService.UsingSkill(char, false, "Leap of Fate")

        if beatriceRig then
            beatriceRig:Destroy()
        end
	end

	skillHandler:Run()
end

return skill