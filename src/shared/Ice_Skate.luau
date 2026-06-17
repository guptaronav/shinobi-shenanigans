local player = game.Players.LocalPlayer

local TweenService = game:GetService('TweenService')

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

client_skill.Init = function(char: Character)
    local mouse = player:GetMouse()
    local hit = mouse.Hit

    if hit then
        SkillService.VoxelDestruction(hit + mouse.UnitRay.Direction * 2, Vector3.one * 15, 0, Enum.PartType.Ball, 20, 30, nil)
    end
end

client_skill.SkateJump = function(char: Character)
    local humRoot = char.HumanoidRootPart
    local skateVelocity = Instance.new('BodyVelocity')
    skateVelocity.Parent = humRoot
    skateVelocity.MaxForce = Vector3.new(30000, 30000, 30000)
    skateVelocity.Velocity = humRoot.CFrame.LookVector * 30 + Vector3.yAxis * 5

    local exhaust = os.clock()
    while task.wait() and os.clock() - exhaust <= 1.3 do
        if os.clock() - exhaust > .8 then
            skateVelocity.MaxForce = Vector3.new(30000, 0, 30000)
        end
        skateVelocity.Velocity = humRoot.CFrame.LookVector * 30 + Vector3.yAxis * 5
    end

    skateVelocity:Destroy()
end

local iceRayParams = RaycastParams.new()
iceRayParams.FilterDescendantsInstances = {workspace.Characters, workspace.UnobstructiveAssets}
iceRayParams.FilterType = Enum.RaycastFilterType.Exclude

local iceScrapes = {}

client_skill.Skate = function(char: Character)
    local humRoot = char.HumanoidRootPart
    
    local skateVelocity: BodyVelocity
    if player.Character == char then
        skateVelocity = Instance.new('BodyVelocity')
        skateVelocity.Parent = humRoot
        skateVelocity.MaxForce = Vector3.new(30000, 0, 30000)
        skateVelocity.Velocity = humRoot.CFrame.LookVector * 50
    end

    char:AddTag('IceSkating')

    local skateParticles = ReplicatedStorage.Assets.SkillAssets.HalfDevil.SkateParticles:Clone()
    skateParticles.Parent = workspace.UnobstructiveAssets
    skateParticles.CFrame = humRoot.CFrame - humRoot.CFrame.LookVector * .5 - Vector3.yAxis * 3
    utility.Weld(skateParticles, humRoot)

    local skateChargeFX = ReplicatedStorage.Assets.SkillAssets.HalfDevil.SkateChargeFX:Clone()
    skateChargeFX.Parent = workspace.UnobstructiveAssets
    skateChargeFX.CFrame = humRoot.CFrame
    utility.Weld(skateChargeFX, humRoot)

    iceScrapes[char] = ReplicatedStorage.Assets.Sounds.HalfDevil.IceScrape:Clone()
    iceScrapes[char].Parent = humRoot
    iceScrapes[char]:Play()

    local windBurstSFX: Sound = ReplicatedStorage.Assets.Sounds.HalfDevil.WindBurst:Clone()
    windBurstSFX.Parent = humRoot
    windBurstSFX:Play()
    windBurstSFX.TimePosition = .7

    local iceFolder: Folder = Instance.new('Folder')
    iceFolder.Parent = workspace.UnobstructiveAssets    

    local exhaust = os.clock()
    while task.wait() and char:HasTag('IceSkating') do
        if player.Character == char then
            skateVelocity.Velocity = humRoot.CFrame.LookVector * 50
        end

        if os.clock() - exhaust < .04 then continue end
        exhaust = os.clock()

        local ray = workspace:Raycast(humRoot.Position, -Vector3.yAxis * 4, iceRayParams)
        local pos = humRoot.CFrame.Position - Vector3.yAxis * 3.1
        if ray and ray.Position then 
            pos = ray.Position
        end

        local ice = ReplicatedStorage.Assets.SkillAssets.HalfDevil.SkatePanel:Clone()
        ice.Transparency = 0
        ice.Material = Enum.Material.Glass
        ice.Anchored = true
        ice.CanCollide = false--player.Character == char
        ice.CFrame = CFrame.new(pos) * humRoot.CFrame.Rotation
        -- ice.CFrame = 
        ice.Size = Vector3.new(3, .2, 3)
        ice.Color = Color3.fromRGB(144, 198, 255)
        ice.Parent = iceFolder
        -- SkillService.VoxelDestruction(humRoot.CFrame + humRoot.CFrame.LookVector * 5, Vector3.one * 6, 10, nil, 30, 40, humRoot.CFrame.LookVector * 10)
    end

    if player.Character == char then
        if skateVelocity then
            skateVelocity:Destroy()
        end
    end

    skateParticles:Destroy()
    skateChargeFX:Destroy()

    task.wait(10)
    windBurstSFX:Destroy()

    for _,v in iceFolder:GetChildren() do
        local iceShards = v:FindFirstChild('SkateShards')
        if iceShards then
            iceShards.ParticleEmitter:Emit(10)
            v.Transparency = 1
        end
    end

    task.wait(.6)

    iceFolder:Destroy()
end

client_skill.EndSkate = function(char: Character)
    char:RemoveTag('IceSkating')
end

client_skill.AttackVelocity = function(char: Character, animLength: number)
    local humRoot = char.HumanoidRootPart

    if iceScrapes[char] then
        local sTween = TweenService:Create(iceScrapes[char], TweenInfo.new(.5), {Volume = 0})
        sTween:Play()
        sTween.Completed:Once(function()
            iceScrapes[char]:Stop()
        end)
    end

    local skateVelocity = Instance.new('BodyVelocity')
    skateVelocity.Parent = humRoot
    skateVelocity.MaxForce = Vector3.new(30000, 0, 30000)
    skateVelocity.Velocity = humRoot.CFrame.LookVector * 2

    local exhaust = os.clock()
    while task.wait() and os.clock() - exhaust <= 2.8 do
        skateVelocity.Velocity = humRoot.CFrame.LookVector * 2
    end

    skateVelocity:Destroy()
end

client_skill.Fail = function(char: Character)
    local humRoot = char.HumanoidRootPart

    local vel = Instance.new('LinearVelocity')
    vel.Attachment0 = humRoot.RootAttachment
    vel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    vel.MaxAxesForce = Vector3.new(30000, 0, 30000)
    vel.VectorVelocity = humRoot.CFrame.LookVector * 50
    vel.Parent = humRoot

    -- local scrapeSfx: Sound = ReplicatedStorage.Assets.Sounds.HalfDevil.IceScrape:Clone()
    -- scrapeSfx.Parent = humRoot
    -- scrapeSfx:Play()

    local iceFolder: Folder = Instance.new('Folder')
    iceFolder.Parent = workspace.UnobstructiveAssets

    local sliding = true
    task.defer(function()
        local exhaust = os.clock()
        while task.wait() and sliding do
            if os.clock() - exhaust < .04 then continue end
            exhaust = os.clock()
    
            local ray = workspace:Raycast(humRoot.Position, -Vector3.yAxis * 4, iceRayParams)
            local pos = humRoot.CFrame.Position - Vector3.yAxis * 3.1
            if ray and ray.Position then 
                pos = ray.Position
            end
    
            local ice = ReplicatedStorage.Assets.SkillAssets.HalfDevil.SkatePanel:Clone()
            ice.Transparency = 0
            ice.Material = Enum.Material.Glass
            ice.Anchored = true
            ice.CanCollide = false--player.Character == char
            ice.CFrame = CFrame.new(pos) * humRoot.CFrame.Rotation
            -- ice.CFrame = 
            ice.Size = Vector3.new(3, .2, 3)
            ice.Color = Color3.fromRGB(144, 198, 255)
            ice.Parent = iceFolder
            -- SkillService.VoxelDestruction(humRoot.CFrame + humRoot.CFrame.LookVector * 5, Vector3.one * 6, 10, nil, 30, 40, humRoot.CFrame.LookVector * 10)
        end

        task.wait(8)

        for _,v in iceFolder:GetChildren() do
            local iceShards = v:FindFirstChild('SkateShards')
            if iceShards then
                iceShards.ParticleEmitter:Emit(10)
                v.Transparency = 1
            end
        end

        task.wait(.6)

        iceFolder:Destroy()
    end)

    local tw = TweenService:Create(vel, TweenInfo.new(1.7, Enum.EasingStyle.Quad), {VectorVelocity = Vector3.new(0,0,0)})
    tw:Play()
    tw.Completed:Wait()

    -- scrapeSfx:Destroy()
    if iceScrapes[char] then
        local sTween = TweenService:Create(iceScrapes[char], TweenInfo.new(.5), {Volume = 0})
        sTween:Play()
        sTween.Completed:Once(function()
            iceScrapes[char]:Stop()
        end)    
    end

    -- task.wait(.6)
    vel:Destroy()
    sliding = false
end

return client_skill