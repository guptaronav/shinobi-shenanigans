local player = game.Players.LocalPlayer

local utility = require(game.ReplicatedStorage.Modules.Utility)
local Cutscene = require(game.ReplicatedStorage.Shared.EffectPresets.Cutscene)
local SkillService = require(game.ReplicatedStorage.Shared.Services.SkillService)

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ts = game:GetService('TweenService')

type Dialogue = {
    Fire: (_self: Dialogue, Text: string, Duration: number, Color: Color3, Extra: {
        Outline: Color3 | nil,
    }|nil) -> nil
}
local addDialogue: Dialogue = game.ReplicatedStorage.Remotes.AddDialogue

type Character = Model

local client_skill = {}

client_skill.ShockwaveFX = function(char: Character, coreCFrame: CFrame)
    local shockwave = ReplicatedStorage.Assets.SkillAssets.HalfDevil.PillarShockwave:Clone()
    shockwave.CFrame = coreCFrame + Vector3.yAxis
    shockwave.Parent = workspace.UnobstructiveAssets
    local tween = ts:Create(shockwave, TweenInfo.new(.8), {Size = Vector3.new(5.955 * 5, 0.584 * 3, 6.083 * 5), Transparency = 1})
    tween:Play()
    tween.Completed:Wait()
    shockwave:Destroy()
end

client_skill.Look_Return = function(char)
    return char.HumanoidRootPart.CFrame
end

return client_skill