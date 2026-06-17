local player = game.Players.LocalPlayer

local utility = require(game.ReplicatedStorage.Modules.Utility)
local Cutscene = require(game.ReplicatedStorage.Shared.EffectPresets.Cutscene)

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SocialService = game:GetService('SocialService')
local ts = game:GetService('TweenService')

type Dialogue = {
    Fire: (_self: Dialogue, Text: string, Duration: number, Color: Color3, Extra: {
        Outline: Color3 | nil,
    }|nil) -> nil
}
local addDialogue: Dialogue = game.ReplicatedStorage.Remotes.AddDialogue

type Character = Model

local sk_client = {}

sk_client['Rental Goa'] = {}
sk_client['Rental Goa'].Explosion = function(char: Character, laSpirit: BasePart)
    local explosionVFX = ReplicatedStorage.Assets.SkillAssets.SpiritKnight.RentalGoaExplosion:Clone()
    explosionVFX.CFrame = laSpirit.CFrame
    explosionVFX.Parent = workspace.UnobstructiveAssets

    for _,v in explosionVFX:WaitForChild('Attachment'):GetChildren() do
        if not v then 
            repeat
                task.wait()
            until v
        end

        v:Emit(5)
    end

    task.wait(2)

    explosionVFX:Destroy()
end

sk_client['Rental Goa'].LookCFrame_Return = function(char)
    return char.HumanoidRootPart.CFrame
end

sk_client['Level 100 Punch'] = {}

local smokeParams = RaycastParams.new(); smokeParams.FilterDescendantsInstances = {workspace.Map}; smokeParams.FilterType=Enum.RaycastFilterType.Include
sk_client['Level 100 Punch'].Run = function(char: Character)
    local smokeFolder = Instance.new('Folder')
    smokeFolder.Parent = workspace.UnobstructiveAssets

    local humRoot = char.HumanoidRootPart
    local exhaust = os.clock()
    while task.wait() and os.clock() - exhaust < .5 do
        local ray = workspace:Raycast(humRoot.Position, -Vector3.yAxis * 7, smokeParams)
        if ray then
            local groundSmoke = ReplicatedStorage.Assets.Effects.GroundSmoke:Clone()
            groundSmoke.Transparency = 1
            groundSmoke.Parent = smokeFolder
            local smokeFX = groundSmoke:WaitForChild('SMOKE')

            groundSmoke.CFrame = CFrame.new(ray.Position)
            local rawColor: Color3 = ray.Instance.Color
            local color = Color3.new(rawColor.R + .1, rawColor.G + .1, rawColor.B + .1)
            smokeFX.Color = ColorSequence.new(color)
            smokeFX:Emit(5)
        end
    end

    task.wait(1)
    smokeFolder:Destroy()
end
sk_client['Level 100 Punch'].Burst = function(char: Character, hits: {Character})
    if #hits > 0 then
        warn('BURST')
        local burstFX = ReplicatedStorage.Assets.SkillAssets.SpiritKnight.WindBurst:Clone()
        burstFX.Transparency = 1
        burstFX.CFrame = char.HumanoidRootPart.CFrame + char.HumanoidRootPart.CFrame.LookVector * 3
        burstFX.Parent = workspace.UnobstructiveAssets

        for _,v in burstFX:GetDescendants() do
            if v:IsA('ParticleEmitter') then
                v:Emit(5)
            end
        end

        local burstSound = ReplicatedStorage.Assets.Sounds.SpiritKnight.Level100Punch:Clone()
        burstSound.Parent = char.HumanoidRootPart
        burstSound:Destroy()
        
        task.wait(1)
        burstFX:Destroy()
    else
        local burstSound = ReplicatedStorage.Assets.Sounds.SpiritKnight.Level100PunchMiss:Clone()
        burstSound.Parent = char.HumanoidRootPart
        burstSound:Destroy()
    end
end

sk_client['Wipeout Flash'] = {}
sk_client['Wipeout Flash'].Flash = function(char)
    local phone = char:FindFirstChild('FlipPhone')
    if not phone then return end
    phone.Top.Flashlight.SpotLight.Enabled = true
end

sk_client['Wipeout Flash'].Flash2 = function(char, i)
    local phone = char:FindFirstChild('FlipPhone')
    if not phone then return end

    local camFlash: BasePart = ReplicatedStorage.Assets.SkillAssets.SpiritKnight.CameraFlash:Clone()
    camFlash.Parent = workspace.UnobstructiveAssets
    camFlash.CFrame = phone.Top.Flashlight.CFrame - phone.Top.Flashlight.CFrame.UpVector *.2
    utility.Weld(camFlash, phone.Top.Flashlight)

    camFlash:WaitForChild('Attachment'):WaitForChild('Core'):Emit(5)
    if i == 4 then
        phone.Top.Flashlight.SpotLight.Enabled = false
    end

    local sfx: Sound = ReplicatedStorage.Assets.Sounds.SpiritKnight.CameraFlash:Clone()
    sfx.Parent = phone.Top.Flashlight
    sfx:Destroy()

    task.wait(.2)
    camFlash:Destroy()
end

sk_client['Shamak'] = {}
sk_client['Shamak'].ShamakHit = function(user)
    local char = player.Character
    local hrp = char.HumanoidRootPart

    -- Clones the part which has the shamak vfx and particles
    

    -- Creats the black screen and white highlight around the character
    local TIMER = os.clock()
    local cc = Instance.new('ColorCorrectionEffect')
    cc.Enabled = true
    cc.Parent = game.Lighting
    cc.TintColor = Color3.new(1,1,1)

    local highlight = Instance.new('Highlight')
    highlight.OutlineColor = Color3.new(1,1,1)
    highlight.OutlineTransparency = 1
    highlight.FillTransparency = 1
    highlight.Adornee = char
    highlight.Parent = char

    -- In case a player dies, it will remove the blackscreen so it doesnt stay
    player.Character.Humanoid.Died:Once(function()
        cc:Destroy()
        highlight:Destroy()
    end)

    -- BLACKSCREEN PROCESS

    
    if char.Name == user.Name or char.Humanoid:GetState() == Enum.HumanoidStateType.Dead then return end
        
    ts:Create(cc, TweenInfo.new(.8, Enum.EasingStyle.Quad), {TintColor = Color3.new(0,0,0)}):Play()
    ts:Create(highlight, TweenInfo.new(.8, Enum.EasingStyle.Quad), {OutlineTransparency = 0}):Play()
    task.wait(1)
    ts:Create(cc, TweenInfo.new(.8, Enum.EasingStyle.Quad), {TintColor = Color3.new(1,1,1)}):Play()
    ts:Create(highlight, TweenInfo.new(.8, Enum.EasingStyle.Quad), {OutlineTransparency = 1}):Play()
        

    --Cleanup
    cc:Destroy()
    highlight:Destroy()
end

sk_client['Shamak'].Target = function()
    
end

sk_client['Warp'] = {}
sk_client['Warp'].SpiritBurst = function(char: Character)
    local burstVFX = ReplicatedStorage.Assets.SkillAssets.SpiritKnight.SpiritBurst:Clone()
    burstVFX.Parent = workspace.UnobstructiveAssets
    burstVFX.CFrame = char.HumanoidRootPart.CFrame
    -- task.wait()
    for _,v in burstVFX:GetDescendants() do
        if v:IsA('ParticleEmitter') then
            v:Emit(2)
        end
    end
    task.wait(1)
    burstVFX:Destroy()
end

sk_client['Murak'] = {}

sk_client['Murak'].Aim = function()
    local char = player.Character
    local mouse = player:GetMouse()

    local timer = os.clock()
    repeat
        local finalPos = mouse.Hit.Position
        char.HumanoidRootPart.CFrame = CFrame.lookAt(char.HumanoidRootPart.Position, finalPos)
        task.wait()
    until os.clock() - timer > 2.5
end

sk_client['Murak'].HorizontalLeap = function(char)
    local humRoot = char.HumanoidRootPart

    -- Just creates all the particles and positions it to the user

    local murakHighlight: Highlight = game.ReplicatedStorage.Assets.SkillAssets.MurakHighlight:Clone()
    murakHighlight.Name = 'MurakHighlight'
    murakHighlight.OutlineTransparency = 1
    murakHighlight.FillTransparency = 1
    ts:Create(murakHighlight, TweenInfo.new(1, Enum.EasingStyle.Quad), {OutlineTransparency = .3, FillTransparency = .6}):Play()
    murakHighlight.Parent = char

    local murakSmoke = game.ReplicatedStorage.Assets.SkillAssets.MurakSmoke:Clone()
    murakSmoke.Name = 'MurakSmoke_'..char.Name
    murakSmoke.CFrame = humRoot.CFrame
    murakSmoke.Parent = workspace.UnobstructiveAssets
    utility.Weld(murakSmoke, humRoot)

    local murakRing = game.ReplicatedStorage.Assets.SkillAssets.MurakRing:Clone()
    murakRing.Name = 'MurakRing_'..char.Name
    murakRing.CFrame = humRoot.CFrame - Vector3.yAxis * 2.5
    murakRing.Parent = workspace.UnobstructiveAssets
    murakRing:WaitForChild("Attachment"):WaitForChild('ParticleEmitter'):Emit(1)
    game.Debris:AddItem(murakRing, 5)
end

sk_client['Murak'].VerticalLeap = function(user)
    local humRoot = user.HumanoidRootPart

    local murakRing = game.ReplicatedStorage.Assets.SkillAssets.MurakRing:Clone()
    murakRing.Name = 'MurakRing_'..user.Name..'-2'
    murakRing.CFrame = humRoot.CFrame - Vector3.yAxis * 2.5
    murakRing.Parent = workspace.UnobstructiveAssets
    murakRing:WaitForChild("Attachment"):WaitForChild("ParticleEmitter").Size = NumberSequence.new(0, 20)
    murakRing:WaitForChild("Attachment"):WaitForChild("ParticleEmitter").Lifetime = NumberRange.new(3)
    murakRing:WaitForChild("Attachment"):WaitForChild('ParticleEmitter'):Emit(1)
    game.Debris:AddItem(murakRing, 5)
end

sk_client['Murak'].Slam = function(user, hit: Model)
    local murakHighlight2 = game.ReplicatedStorage.Assets.SkillAssets.MurakHighlight:Clone()
    task.delay(.2, function()
        murakHighlight2.OutlineTransparency = 1
        murakHighlight2.FillTransparency = 1
        ts:Create(murakHighlight2, TweenInfo.new(1, Enum.EasingStyle.Quad), {OutlineTransparency = .3, FillTransparency = .6}):Play()
        murakHighlight2.Parent = hit
    end)

    local murakSmoke2 = game.ReplicatedStorage.Assets.SkillAssets.MurakSmoke:Clone()
    murakSmoke2.Name = 'MurakSmoke_'..hit.Name
    murakSmoke2.CFrame = hit.HumanoidRootPart.CFrame
    murakSmoke2.Parent = workspace.UnobstructiveAssets
    utility.Weld(murakSmoke2, hit.HumanoidRootPart)

    local head = hit.Head

    local cameraShaker = require(game.ReplicatedStorage.Modules.CameraShaker)
    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
        workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * shakeCFrame
    end)
    
    camShake:Start()
    camShake:StartShake(3, 10, 0, Vector3.one, Vector3.zero, user.HumanoidRootPart.Position, 50)

    local debris = require(game.ReplicatedStorage.Shared.EffectPresets.Debris)
    for i=1, 20 do
        local ray = debris.Raycast(head.Position, -Vector3.yAxis * 20)
        debris.Create({
            CFrame = head.CFrame,
            Size = .4,
            Direction = Vector3.yAxis * 2,
            Amount = 3,
            presetPart = ray and ray.Instance or Instance.new('Part'),
            DisableCollision = true,
	    })
        task.wait(.1)
    end
    camShake:Stop()
end

sk_client['Murak'].Cleanup_Hit = function(_, hit)
    local murakHighlight2 = hit:FindFirstChild('MurakHighlight')
    if murakHighlight2 then
        local dTween =ts:Create(murakHighlight2, TweenInfo.new(1, Enum.EasingStyle.Quad), {OutlineTransparency = 1, FillTransparency = 1})
        dTween:Play()
        dTween.Completed:Connect(function()
            murakHighlight2:Destroy()
            workspace.UnobstructiveAssets:FindFirstChild('MurakSmoke_'..hit.Name):Destroy()
        end)
    end
end

sk_client['Murak'].Cleanup = function(char)
    local murakHighlight = char:FindFirstChild('MurakHighlight')
    if murakHighlight then
        local dTween =ts:Create(murakHighlight, TweenInfo.new(1, Enum.EasingStyle.Quad), {OutlineTransparency = 1, FillTransparency = 1})
        dTween:Play()
        dTween.Completed:Connect(function()
            murakHighlight:Destroy()
            workspace.UnobstructiveAssets:FindFirstChild('MurakSmoke_'..char.Name):Destroy()
        end)
    end
end

sk_client['Invisible Providence'] = {}
sk_client['Invisible Providence'].Limbs = function(char:Model, limbs: Folder)
    if player.Character.Name == char.Name then

        local function MakeVisible(p: Part)
            p.Color = Color3.new(0.435294, 0.325490, 0.882352)
            p.Material = Enum.Material.Neon
            p.Transparency = 0
            p.Reflectance = 0
        end
        
        for i,v in limbs:GetChildren() do
            MakeVisible(v)
        end

        limbs.ChildAdded:Connect(MakeVisible)
    end

    local wind = game.ReplicatedStorage.Assets.Effects.Wind:Clone()
    wind.Parent = workspace.UnobstructiveAssets
    wind.CFrame = (char.HumanoidRootPart.CFrame + char.HumanoidRootPart.CFrame.LookVector) * CFrame.Angles(math.rad(90),0,0)
    wind:WaitForChild('Main'):WaitForChild('Windspin1').TimeScale = 2
    wind:WaitForChild('Main'):WaitForChild('Windspin1'):Emit(7)
    wind:WaitForChild('Main'):WaitForChild('Windspin2').TimeScale = 2
    wind:WaitForChild('Main'):WaitForChild('Windspin2'):Emit(7)
    task.wait(5)
    wind:Destroy()
end


sk_client['Awaken'] = {}
sk_client['Awaken'].Init = function(char: Model)
    local kneelAnim = char.Humanoid.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.SKAwakening.Kneel)
    kneelAnim:Play()

    addDialogue:Fire(char.Name..' is a weak, petty, irredeemable huge idiot.', 6)
    task.wait(2)

    char.Archivable = true
    local ghostClone = char:Clone()
    char.Archivable = false
    ghostClone:WaitForChild('Humanoid').DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    print(ghostClone)
    ghostClone.Name = 'Projection'
    for _,v in ghostClone:GetDescendants() do
        if v:IsA('BasePart') then
            v.Transparency = 1
            ts:Create(v, TweenInfo.new(2), {Transparency = .5}):Play()
        end
    end
    ghostClone.HumanoidRootPart.CFrame = CFrame.lookAt(char.HumanoidRootPart.Position + char.HumanoidRootPart.CFrame.LookVector * 4, char.HumanoidRootPart.Position)
    ghostClone.Parent = workspace.UnobstructiveAssets

    local stanceAnim = ghostClone.Humanoid.Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.SKAwakening.AmazingStance)
    stanceAnim:Play()

    task.wait(2)
    addDialogue:Fire("That’s not wrong.", 6, Color3.new(0.823529, 0.737254, 1)) 
    task.wait(2)
    addDialogue:Fire("But.", 6)
    task.wait(2)
    addDialogue:Fire("...", 6, Color3.new(0.823529, 0.737254, 1))
    task.wait(2)
    addDialogue:Fire("You are an amazing guy, "..char.Name, 6)

    task.wait(1)
    for _,v in ghostClone:GetDescendants() do
        if v:IsA('BasePart') then
            local t = ts:Create(v, TweenInfo.new(2), {Transparency = 1})
            t:Play()
        end
    end
    task.wait(2)
    ghostClone:Destroy()

    kneelAnim:Stop()

    local awakeningAura = game.ReplicatedStorage.Assets.SkillAssets.SKAwakeningAura:Clone()
    awakeningAura.Name = 'SKAwakeningAura_'..char.Name
    awakeningAura.Parent = workspace.UnobstructiveAssets
    awakeningAura.CFrame = char.HumanoidRootPart.CFrame
    utility.Weld(awakeningAura, char.HumanoidRootPart)
end
sk_client['Awaken'].End = function(char: Model)
    local aura = workspace.UnobstructiveAssets:FindFirstChild('SKAwakeningAura_'..char.Name)
    if aura then
        aura:Destroy()
    end
end

sk_client['Minya'] = {}
sk_client['Minya'].User = function(char: Model)
    local utilMouse = utility.GetUtilMouse()
    local timer = os.clock()
    while task.wait() do
        if os.clock() - timer >= 8 then
            return
        end
        game.ReplicatedStorage.Remotes.UpdateMouse:FireServer('Minya', utilMouse.Hit())
    end
end

sk_client['Minya'].ShardShatter = function(char:Model, finalCFrame: CFrame)
    local shatterBlock = game.ReplicatedStorage.Assets.SkillAssets.MinyaShardShatterBlock:Clone()
    shatterBlock.CFrame = finalCFrame
    shatterBlock.Parent = workspace.UnobstructiveAssets

    task.wait()
    shatterBlock:WaitForChild('Attachment'):WaitForChild('Dots 2'):Emit(12)
    shatterBlock:WaitForChild('Attachment'):WaitForChild('Dust'):Emit(2)
    task.wait(4)
    shatterBlock:Destroy()
end

sk_client['EMM'] = {}
sk_client['EMM'].Cutscene = function(char: Model, scene: string)
    local humRoot = char.HumanoidRootPart

    -- local cut = Cutscene.Get('EMM_Counter', char)

    -- if scene == nil then
    --     cut:StartCutscene(true)
    -- elseif scene == false then
    --     cut:EndCutscene()
    -- else
    --     local ti
    --     if scene == 'Throwing' then ti = TweenInfo.new(.7, Enum.EasingStyle.Quad) end
    --     cut:SetScene(scene, ti)
    -- end
end

sk_client['EMM'].MinyaCutscene = function(char: Model, attacker: Model?)
    local humRoot = char.HumanoidRootPart

    local cut = Cutscene.Get('EMM_Counter', char)
    warn(cut)
    cut:SetScene('MinyaCast')
    
    task.wait(1.3)
    local unit = (attacker.HumanoidRootPart.Position - humRoot.Position).Unit * 25

    -- ts:Create(workspace.CurrentCamera, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    --     CFrame = workspace.CurrentCamera.CFrame + Vector3.new(unit.X, workspace.CurrentCamera.CFrame.Position.Y, unit.Z)
    -- }):Play()

    cut:SetScene('MinyaEnd', TweenInfo.new(.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
end

sk_client['EMM'].Thrust = function(char:Model, target:Model)
    local humRoot = player.Character.HumanoidRootPart
    
    if (humRoot.Position - char.HumanoidRootPart.Position).Magnitude <= 52 then
        print('impact frame')

        game.ReplicatedStorage.Remotes.DisplayEffect_Client:Fire('ImpactFrame', {
            Duration = .2, IF1Weight = .4, IF2Weight = .2, IF3Weight = .4, IF1Color = Color3.new(1,.6,1), IF3Color = Color3.new(1,.6,1)})
    end
end

sk_client['EMT'] = {}
sk_client['EMT'].Mouse = function()
    local utilMouse = utility.GetUtilMouse()
    local timer = os.clock()
    while task.wait() do
        if os.clock() - timer >= 7 then
            return
        end
        game.ReplicatedStorage.Remotes.UpdateMouse:FireServer('EMT', utilMouse.Hit())
    end
end

sk_client['Al Shamak'] = {}
sk_client['Al Shamak'].DarkBlink = function()
    local cc = game.Lighting.AlShamakBlink
    cc.Saturation = 0
    cc.Brightness = 0
    cc.Enabled = true

    local tween= ts:Create(cc, TweenInfo.new(.4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true), {Saturation = -1, Brightness = -.3}); tween:Play()
    tween.Completed:Wait()
    cc.Enabled = false
end

sk_client['Al Shamak'].Killed = function(char: Model)

    local tChar = player.Character

    local highlight = Instance.new('Highlight')
    highlight.OutlineColor = Color3.new(1,1,1)
    highlight.OutlineTransparency = 1
    highlight.FillTransparency = 1
    highlight.Adornee = tChar
    highlight.Parent = tChar

    local cc = game.Lighting.AlShamakBlink
    cc.Saturation = 0
    cc.Brightness = 0
    cc.Enabled = true

    ts:Create(highlight, TweenInfo.new(.6), {OutlineTransparency = 0}):Play()
    local tween= ts:Create(cc, TweenInfo.new(.5), {Saturation = -1, Brightness = -1}); tween:Play()
    tween.Completed:Wait()
    task.wait(5)
    cc.Enabled = false
    highlight:Destroy()
end

sk_client['Al Shamak'].Summoning = function(char: Model)
    local tChar = player.Character

    print('dialogue should show')
    if (char.HumanoidRootPart.Position - tChar.HumanoidRootPart.Position).Magnitude <= 70 then
        addDialogue:Fire("AL SHAMAK", 6, Color3.new(0.086274, 0.058823, 0.145098), {Outline = Color3.new(1,1,1)}) 
    end
end

sk_client['Special'] = {}

sk_client['Special'].Call = function(char: Character)
    local RADIUS = 40

    local humRoot = player.Character.HumanoidRootPart

    if (humRoot.Position - char.HumanoidRootPart.Position).Magnitude <= RADIUS then
        addDialogue:Fire('I can Return By-', 1, Color3.new(0.286274, 0.121568, 0.419607))

        local shout = game.ReplicatedStorage.Assets.Sounds.SpiritKnight.RBDShout:Clone()
        shout.Parent = workspace
        shout:Destroy()
    end
end

sk_client['Special'].Mist = function(char: Character)

    local humRoot = player.Character.HumanoidRootPart
    humRoot.Anchored = true

    local anims = player.Character.Humanoid.Animator:GetPlayingAnimationTracks()
    local oldSpeeds = {}
    for i,v: AnimationTrack in anims do
        v:AdjustSpeed(0)
    end

    local cc = game.Lighting.ReturnByDeath
    cc.Enabled = true

    local rbdCall = game.ReplicatedStorage.Assets.Sounds.SpiritKnight.RBDCall:Clone()
    rbdCall.Parent = workspace
    rbdCall:Play()

    task.wait(5.5)
    rbdCall:Destroy()

    -- task.wait(2)

    humRoot.Anchored = false
    cc.Enabled = false

    for i,v: AnimationTrack in anims do
        v:Stop(0)
    end

    local rbdAh = game.ReplicatedStorage.Assets.Sounds.SpiritKnight.RBDAh:Clone()
    rbdAh.Parent = workspace
    rbdAh:Destroy()
end

return sk_client