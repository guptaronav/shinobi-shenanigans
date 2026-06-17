local player = game.Players.LocalPlayer

local ReplicatedStorage = game:GetService('ReplicatedStorage')

type Character = Model

local client_skill = {}

client_skill.SpawnFX = function(char: Character, pos: Vector3)
    local spawnFX = game.ReplicatedStorage.Assets.SkillAssets.HalfDevil.WeaponSpawnFX:Clone()
    spawnFX.Parent = workspace.UnobstructiveAssets
    spawnFX.CFrame = CFrame.new(pos)
    spawnFX:WaitForChild('Attachment'):WaitForChild('ParticleEmitter'):Emit(3)
end

client_skill.Splatter = function(_, pos: Vector3)

    local splatter = game.ReplicatedStorage.Assets.SkillAssets.HalfDevil.IceShardSplatter:Clone()
    splatter.Parent = workspace.UnobstructiveAssets
    splatter.CFrame = CFrame.new(pos)
    splatter:WaitForChild('Attachment'):WaitForChild('Shockwave'):Emit(5)

    local sound = game.ReplicatedStorage.Assets.Sounds.HalfDevil.ShardStab:Clone()
    sound.Parent = splatter
    sound:Destroy()

    task.wait(.3)
    splatter:Destroy()
end

client_skill.BackdashFX = function(char: Character)
    local rng = Random.new()
    local humRoot = char.HumanoidRootPart

    local sfx: Sound = ReplicatedStorage.Assets.Sounds.HalfDevil.AmbushDash:Clone()
    sfx.Parent = humRoot
    sfx:Destroy()

    local rubbleDeb = 0
    local exhaust = os.clock()
    while task.wait() do
        if os.clock() - exhaust > .3 then break end

        if os.clock() - rubbleDeb >= .02 then
            rubbleDeb = os.clock()
    
            local rParams = RaycastParams.new(); rParams.FilterDescendantsInstances = {char, workspace.UnobstructiveAssets}; rParams.FilterType = Enum.RaycastFilterType.Exclude
            local ray = workspace:Raycast(humRoot.Position, -Vector3.yAxis * 4.1, rParams)
            if ray and ray.Instance then
                local rubble1, rubble2 = Instance.new('Part'), Instance.new('Part')
                rubble1.CanCollide = false; rubble2.CanCollide = false; rubble1.CanQuery = false; rubble2.CanQuery = false
                rubble1.Anchored = true; rubble2.Anchored = true
                rubble1.Material = ray.Instance.Material; rubble2.Material = ray.Instance.Material
                rubble1.Color = ray.Instance.Color; rubble2.Color = ray.Instance.Color
                rubble1.Size = Vector3.one * .5; rubble2.Size = Vector3.one * .5
    
                rubble1.CFrame = CFrame.new(ray.Position + humRoot.CFrame.RightVector) * CFrame.Angles(math.rad(rng:NextNumber(0, 359)),math.rad(rng:NextNumber(0, 359)),math.rad(rng:NextNumber(0, 359)))
                rubble2.CFrame = CFrame.new(ray.Position - humRoot.CFrame.RightVector) * CFrame.Angles(math.rad(rng:NextNumber(0, 359)),math.rad(rng:NextNumber(0, 359)),math.rad(rng:NextNumber(0, 359)))
                
                rubble1.Parent = workspace.UnobstructiveAssets; rubble2.Parent = workspace.UnobstructiveAssets
                task.delay(8, function()
                    rubble1:Destroy(); rubble2:Destroy()
                end)
            end
        end
    end

    -- local fx = ReplicatedStorage.Assets.SkillAssets.HalfDevil.BackdashFX:Clone()
    -- fx.Parent = workspace.UnobstructiveAssets
    -- fx.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(180), 0) - Vector3.yAxis * 2 - char.HumanoidRootPart.CFrame.LookVector * 4
    -- for i=1, 5 do
    --     fx:WaitForChild('FWOOSH'):Emit(20)
    --     fx:WaitForChild('LINES'):Emit(20)
    --     task.wait(.05)
    -- end
    -- task.wait(1)
    -- fx:Destroy()
end

return client_skill