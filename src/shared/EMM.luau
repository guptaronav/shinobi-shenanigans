local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local client_skill = {}

local utility=  require(ReplicatedStorage.Modules.Utility)

client_skill.EMMAura = function(char: Model)
    local highlight = game.ReplicatedStorage.Assets.SkillAssets.EMMHighlight:Clone()
    highlight.Parent = char
    highlight.FillTransparency = .15
    highlight.FillColor = Color3.new(0.6, 0.250980, 1)

    task.wait(.8)
    local fade = TweenService:Create(highlight, TweenInfo.new(.5), {FillTransparency = 1}); fade:Play()
    fade.Completed:Wait()
    highlight:Destroy()
end

client_skill.CounterAttackVfx = function(char: Model, beatriceRig: Model)
    local vfx = ReplicatedStorage.Assets.SkillAssets.SpiritKnight.EMMCounterVfx:Clone()
    vfx.Parent = workspace.UnobstructiveAssets
    vfx.CFrame = beatriceRig.HumanoidRootPart.CFrame + Vector3.yAxis * 2

    for _,v in vfx:GetDescendants() do
        if v:IsA("ParticleEmitter") then
            v:Emit(6)
        end
    end

    task.wait(2)
    vfx:Destroy()
end

return client_skill