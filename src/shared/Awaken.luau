-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService('TweenService')

-- Services
local Services = require(ReplicatedStorage.Shared.Services)
local SkillService = Services.SkillService
local StateService = Services.StateService
local AnimationService = Services.AnimationService

-- Resources / Assets
local Assets = ReplicatedStorage.Assets

local skill = {}

type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: BasePart}

skill.Init = function(char:Character)
    SkillService.UsingSkill(char, true, 'Awaken')

    local state = StateService.Get(char)
    state:SetWalkspeed('Awakening', 9, 0.01)
    state:IFrame(true)
    
    SkillService.RouteToClient('Awaken', char, 'Init', 'All')
    
    local anim = AnimationService.LoadAnimation(char, Assets.Animations.HalfDevil.Awakening.Awaken, 'Skill')
    anim:Play()

    local humRoot = char.HumanoidRootPart
    
    for i=10, 40, 10 do
        local voxels = SkillService.CoreVoxelDestruction({Core = humRoot}, Vector3.one * i, 4, Enum.PartType.Ball, 40, 60, nil, true, true)

        for _,v in voxels do
            -- if v:GetAttribute('Voxel') then continue end
            v.Material = Enum.Material.Ice
            v.Color = Color3.new(0.882352, 0.921568, 1)
            v.Anchored = true
            v:SetAttribute('Frozen', true)
        end
        task.wait(1.125)
    end
    -- task.wait(4)
    
    state:IFrame(false)
    state:EndWalkspeed('Awakening')
    SkillService.Cooldown(char, 'Awaken', 30)
    SkillService.UsingSkill(char, false, 'Awaken')
end

return skill