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

client_skill.NewCFrame_Return = function(char: Character)
    return char.HumanoidRootPart.CFrame
end


return client_skill