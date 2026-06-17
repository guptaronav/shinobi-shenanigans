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
	SkillService.UsingSkill(char, true, "Guiltywhip")

	local skillHandler = SkillService.CreateSkill(char, "Guiltywhip", { Start = 0 })

	local humRoot = char.HumanoidRootPart
	local state = StateService.Get(char)
	state:SetWalkspeed("Guiltywhip", 5, 0)

    local whip = Assets.SkillAssets.SpiritKnight.Whip:Clone()
    whip.Parent = char
    local hitbox
    
	skillHandler.Runtime = function()
        local joint = Instance.new('Motor6D')
        joint.Part1 = whip.Handle
        joint.Part0 = char['Right Arm']
        joint.C0 = CFrame.new(0.0999908447265625, -0.799997091293335, -0.3000020980834961, 1, 0, 0, 0, 1, 0, 0, 0, 1)
        joint.Parent = whip.Handle
		
        -- char:AddTag('DisableRotating')
        char.Humanoid.AutoRotate = false

        local attackAnim: AnimationTrack = AnimationService.LoadAnimation(char, Assets.Animations.SpiritKnight.WhipAttack, 'Skill')
        attackAnim:Play()

        skillHandler:AddEvent(attackAnim:GetMarkerReachedSignal('Hitbox'), function()
            SkillService.RouteToClient('Guiltywhip', char, 'Whipslash', 'All')
            hitbox = HitboxService.new()
            hitbox.CFrame = humRoot.CFrame + humRoot.CFrame.LookVector * 7.5
            hitbox.Size = Vector3.new(13, 4, 15)
            hitbox.OverlapParams = char
            hitbox.HitEvent:Connect(function(hit)
                if hit:GetAttribute('Ragdolled') then return end
                DamageService.Damage(hit, char, 10)
                local state = StateService.Get(hit)
                state:Stun('Whipped', 2, 4)
                local ragdoll = RagdollService.Get(hit)
                ragdoll:Ragdoll(hit, 2.5)
                state:Velocity(humRoot.CFrame.LookVector * 50, .2, nil, {Vector3.yAxis})
                -- ReplicatedStorage.Remotes.BodyFlash:FireAllClients(hit)
                SkillService.RouteToClient('Guiltywhip', char, 'Whipsound', 'All', hit)
            end)
            hitbox:Start()

            SkillService.VoxelDestruction(hitbox.CFrame, Vector3.new(13, 2, 15), 3, nil, 30, 50, 'Explosion_40')
        end)

        skillHandler:AddEvent(attackAnim:GetMarkerReachedSignal('HitboxEnd'), function()
            hitbox:Stop()
        end)

        attackAnim.Stopped:Wait()
	end

	skillHandler.CleanUp = function()
        if hitbox then
            hitbox:Stop()
        end
        whip:Destroy()
        -- char:RemoveTag('DisableRotating')
        -- char:SetAttribute('DisableRotating', false)
        char.Humanoid.AutoRotate = true

		state:EndWalkspeed("Guiltywhip")
		SkillService.Cooldown(char, "Guiltywhip")
		SkillService.UsingSkill(char, false, "Guiltywhip")
	end

	skillHandler:Run()
end

return skill