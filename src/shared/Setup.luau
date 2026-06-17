local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = require(ReplicatedStorage.Shared.Services)
local DamageService = Services.DamageService
local AnimationService = Services.AnimationService

local animations = ReplicatedStorage.Assets.Animations
type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: Part}

local Setup = {}

function Setup.init(char: Character)
    local rightArm = char:WaitForChild('Right Arm')

    local dragonSword = ReplicatedStorage.Assets.SkillAssets.OneMostLoved.DragonSword:Clone()
    dragonSword.Parent =char

    local joint = Instance.new('Motor6D')
    joint.C0 = CFrame.new(-0.0371246337890625, -1.0116896629333496, -0.15070533752441406, -1, 0, 0, 0, 0, 1, 0, 1, 0 )
    joint.Part0 = char:WaitForChild('Right Arm')
    joint.Part1 = dragonSword.Handle
    joint.Parent =  char['Right Arm']
end

return Setup