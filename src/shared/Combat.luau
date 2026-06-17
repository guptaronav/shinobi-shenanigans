local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = require(ReplicatedStorage.Shared.Services)
local DamageService = Services.DamageService
local AnimationService = Services.AnimationService

local CombatTypes = require(ReplicatedStorage.Shared.Data.Characters.Combat)

local animations = ReplicatedStorage.Assets.Animations

local Combat: CombatTypes.Combat = CombatTypes.new()

type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: Part}

Combat.M1.BasicHit = function(char: Character, target: Character, extra: table)
    return
end

Combat.M1.M1Animation = function(char: Character, index: number): Folder
    if char:GetAttribute('Weapon') == 'Sword' then
        return animations.HalfDevil.SwordBasicAttacks['M'..index]
    elseif char:GetAttribute('Weapon') == 'Hammer' then
        return animations.HalfDevil.HammerBasicAttacks['M'..index]
    else
        return animations.HalfDevil.M1s['M'..index]
    end
end

Combat.M1.M1Interval =  function(char: Character, isFinal: boolean): number
    -- if char:GetAttribute('Weapon') == 'Sword' then
    --     return isFinal and 1.2 or 0.4
    -- elseif char:GetAttribute('Weapon') == 'Hammer' then
    --     return isFinal and 2 or 0.65
    -- else
    --     return isFinal and 1 or 0.45
    -- end
    return isFinal and 1.1 or .45
end

Combat.M1.M1Damage = function(char: Character): number
    return 3.5
end

Combat.Dash.FrontDashAnimation = function(char: Character): AnimationTrack
    return AnimationService.LoadAnimation(char, ReplicatedStorage.Assets.Animations.DashFinal, 'Dash')
end

Combat.Run.Animation = function(char: Character, running: boolean): Animation
    if running then
        return animations.Run
    end
end

Combat.Run.Speed = function(char: Character, running: boolean): number
    return running and 21 or 15
end

return Combat