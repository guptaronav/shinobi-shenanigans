local ReplicatedStorage = game:GetService('ReplicatedStorage')
local CAS = game:GetService('ContextActionService')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local Debris = game:GetService("Debris")

local AnimationService = require(ReplicatedStorage.Shared.Services.AnimationService)
local utility = require(ReplicatedStorage.Modules.Utility)
local HitboxService = require(ReplicatedStorage.Shared.Services.Hitbox)

local player = game.Players.LocalPlayer
repeat task.wait() until player:HasTag('Loaded')

local char = player.Character or player.CharacterAdded:Wait()
local humRoot: BasePart = char:WaitForChild('HumanoidRootPart')
local hum: Humanoid = char:WaitForChild('Humanoid')

local stuns = char:WaitForChild('Values'):WaitForChild('Stuns')

-------- WALLJUMPING

local oParams = OverlapParams.new()
oParams.FilterDescendantsInstances = {workspace.Characters, workspace.UnobstructiveAssets}
oParams.FilterType = Enum.RaycastFilterType.Exclude

local walljumpAnims = game.ReplicatedStorage.Assets.Animations.Walljumps
local wallJumpDebounces = {}
local currentWalls = {}
local wallJumpDebTimer = 0
local stamina = 3
local inAir = false

local w1Part = Instance.new('Part'); w1Part.Transparency = 1; w1Part.CanCollide = false; w1Part.Size = Vector3.new(1, .2, 1.5)
w1Part.Parent = workspace.UnobstructiveAssets; 
local w2Part = w1Part:Clone(); w2Part.Parent = workspace.UnobstructiveAssets
w1Part.CFrame = humRoot.CFrame + humRoot.CFrame.RightVector * 1.5 - Vector3.yAxis - humRoot.CFrame.LookVector * .7; w2Part.CFrame = humRoot.CFrame - humRoot.CFrame.RightVector * 1.5 - Vector3.yAxis - humRoot.CFrame.LookVector * .7
utility.Weld(w1Part, humRoot); utility.Weld(w2Part, humRoot)

local wjDelay
local function WallJump(_, inputState, _, isIteration)
    if not isIteration then
        task.defer(function()
            task.wait(.1)
            while UIS:IsKeyDown(Enum.KeyCode.Space) and task.wait() do
                -- print('attempt to walljump')
                WallJump(nil, inputState, nil, true)
            end
        end)
    end
    
    if inputState == Enum.UserInputState.Begin then
        if inAir and UIS:IsKeyDown(Enum.KeyCode.W)then
            if os.clock() - wallJumpDebTimer <= .4 then 
                repeat
                    task.wait()
                until os.clock() - wallJumpDebTimer > .4
            end

            local hitboxRight = workspace:GetPartsInPart(w1Part, oParams)
            local hitboxLeft = workspace:GetPartsInPart(w2Part, oParams)

            local side
            local anim
            local idleAnim
            -- print(wallJumpDebounces)
            if #hitboxRight > 0 and UIS:IsKeyDown(Enum.KeyCode.D) then
                side = 1
                anim = AnimationService.LoadAnimation(char, walljumpAnims.WallJumpLeft, 'WallJump')
                -- anim = hum.Animator:LoadAnimation(walljumpAnims.WallJumpLeft)
                -- idleAnim = hum.Animator:LoadAnimation(walljumpAnims.WallJumpLeftIdle)
            elseif #hitboxLeft > 0 and UIS:IsKeyDown(Enum.KeyCode.A) then
                side = 2
                anim = AnimationService.LoadAnimation(char, walljumpAnims.WallJumpRight, 'WallJump')

                -- anim = hum.Animator:LoadAnimation(walljumpAnims.WallJumpRight)
                -- idleAnim = hum.Animator:LoadAnimation(walljumpAnims.WallJumpRightIdle)
            else 
                return 
            end

            -- if wallJumpDebTimer then task.cancel(wallJumpDebTimer) end
            -- wallJumpDebTimer = task.delay(.2, function()
            --     table.clear(wallJumpDebounces)
            -- end)

            print('walljumping')

            if stamina <= 0 then 
                wallJumpDebTimer = os.clock() + .2 
                return 
            end
            wallJumpDebTimer = os.clock()
            stamina -= 1
            
            if wjDelay then task.cancel(wjDelay) end
            wjDelay = task.delay(1, function()
                stamina = 3
            end)
            
            print(stamina)

            if humRoot:FindFirstChild('WalljumpBV') then humRoot.WalljumpBV:Destroy() end
            local bv = Instance.new('BodyVelocity')
            bv.Name = 'WalljumpBV'
            bv.Parent = humRoot

            AnimationService.StopAnimationsOfOrigin(char, 'WallJump', .1)
            anim:Play()
            anim:AdjustSpeed(1.2)
            -- anim.Stopped:Once(function()
            --     idleAnim:Play()
            --     repeat task.wait() until bv.Parent ~= humRoot
            --     idleAnim:Stop()
            -- end)

            bv.MaxForce = Vector3.new(30000, 30000, 30000)
            bv.Velocity = (side == 1 and humRoot.CFrame.RightVector * 3 or -humRoot.CFrame.RightVector * 3) + humRoot.CFrame.LookVector * 5 + Vector3.yAxis * 1.5
            task.wait(.1)
            bv.MaxForce = Vector3.new(6000, 10000, 6000)
            bv.Velocity = (side == 1 and -humRoot.CFrame.RightVector * 46 or humRoot.CFrame.RightVector * 46) + humRoot.CFrame.LookVector * 45 + Vector3.yAxis * 35
            game.Debris:AddItem(bv, .22)
        end
    end
end

local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = {workspace.Characters, workspace.UnobstructiveAssets}
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

CAS:BindActionAtPriority('Wall Jump', WallJump, false, 0, Enum.KeyCode.Space)
RunService.RenderStepped:Connect(function(deltaTime)
    if workspace:Raycast(humRoot.Position, -Vector3.yAxis * 3, rayParams) then
        inAir = false
    else
        inAir = true
        -- print('in air')
    end
end)

-------- VAULTING

local vaultDebounce = 0
local vaultRayLowerBound = -.5
local vaultRayUpperBound = 1.9
local vaultRayUpperLimit = 2

RunService:BindToRenderStep('Vaulting', 110, function()
    if not char:IsDescendantOf(workspace) or char.Humanoid.Health <= 0 then return end
    if not UIS:IsKeyDown(Enum.KeyCode.W) then return end
    if char.HumanoidRootPart.CollisionGroup == 'Ragdolls' or char.HumanoidRootPart.CollisionGroup == 'Ghosts' then return end
    if os.clock() - char:GetAttribute('Attacking') < .6 or char:GetAttribute('UsingSkill') or char:GetAttribute('Blocking') or char:GetAttribute('Ragdolled') or #stuns:GetChildren() > 0 then return end
    if os.clock() - vaultDebounce <= .4 then return end

    local partHits = {}
    for i=vaultRayLowerBound, vaultRayUpperBound, .2 do
        local ray = workspace:Raycast(humRoot.Position + Vector3.yAxis * i, humRoot.CFrame.LookVector * 4, rayParams)
        if ray and ray.Instance and not ray.Instance:IsA('UnionOperation') then
            if ray.Instance.Shape ~= Enum.PartType.Block then continue end
            table.insert(partHits, ray)
        end
    end

    table.sort(partHits, function(a, b)
        return a.Position.Y > b.Position.Y
    end)

    -- local rayLow = workspace:Raycast(humRoot.Position - Vector3.yAxis * 2.95, humRoot.CFrame.LookVector * 1.2, rayParams)
    -- local rayHigh =  workspace:Raycast(humRoot.Position - Vector3.yAxis * 2, humRoot.CFrame.LookVector * 1.2, rayParams)
    -- if #partHits > 0 then
        -- print(partHits)
    -- end

    local rayLimit = workspace:Raycast(humRoot.Position + Vector3.yAxis * vaultRayUpperLimit, humRoot.CFrame.LookVector * 7, rayParams)
    -- if not rayLow or not rayHigh then return end
    -- if rayLow.Instance ~= rayHigh.Instance then return end
    -- if rayLimit and (rayLimit.Instance == rayHigh.Instance or rayLimit.Instance == rayLow.Instance) then return end
    if rayLimit then return end
    if #partHits == 0 then return end

    -- local recognizedParts = {}
    local vaultDistance = math.abs(humRoot.Position.Y - partHits[1].Position.Y)
    -- for _,v in partHits do
    --     if table.find(recognizedParts, v.Instance) then continue end
    --     table.insert(recognizedParts, v.Instance)

    --     vaultDistance += v.Instance.Size.Y
    -- end
    -- vaultDistance -= 1

    vaultDebounce = os.clock()
    -- print('vault')
    local exhaust = os.clock()

    local velocity = Instance.new('BodyVelocity')
    velocity.MaxForce = Vector3.one * 30000
    velocity.Velocity = humRoot.CFrame.LookVector * 21 + Vector3.yAxis * (10 + vaultDistance)
    velocity.Parent = humRoot
    Debris:AddItem(velocity, .4)

    task.spawn(function()
        repeat task.wait()
            if os.clock() -  exhaust >= .2 then
                velocity.Velocity = humRoot.CFrame.LookVector * 21
            else
                velocity.Velocity = humRoot.CFrame.LookVector * 21 + Vector3.yAxis * (10 + vaultDistance) 
            end
        until os.clock() - exhaust >= .4
    end)

    -----------

    local vaultAnim = AnimationService.LoadAnimation(char, ReplicatedStorage.Assets.Animations.Parkour.VaultGround, 'Parkour')
    vaultAnim:Play()
end)

----- DROP ROLL
-- local timeSinceGrounded = 0
local falling = false
local droprollDebounce = 0
local oldHeight = humRoot.Position.Y
RunService:BindToRenderStep('DropRoll', 111, function()
    if os.clock() - droprollDebounce < 1 then return end

    local ray = workspace:Raycast(humRoot.Position, -Vector3.yAxis * 3, rayParams)
    if not ray then
        if not falling then
            -- timeSinceGrounded = os.clock()
            oldHeight = humRoot.Position.Y
        elseif humRoot.Position.Y > oldHeight then
            oldHeight = humRoot.Position.Y
        end
        falling = true
    else
        if falling then
            falling = false

            if char:GetAttribute('UsingSkill') or char:GetAttribute('Ragdolled') or #stuns:GetChildren() > 0 then return end

            if oldHeight - humRoot.Position.Y > 30 then
                droprollDebounce = os.clock()

                local rollAnim = AnimationService.LoadAnimation(char, ReplicatedStorage.Assets.Animations.Parkour.DropRoll, 'Parkour')
                rollAnim:Play()

                local velocity = Instance.new('BodyVelocity')
                velocity.MaxForce = Vector3.one * 30000
                velocity.Velocity = humRoot.CFrame.LookVector * 25
                velocity.Parent = humRoot
                Debris:AddItem(velocity, .4)

                local exhaust = os.clock()

                task.spawn(function()
                    repeat task.wait()
                        velocity.Velocity = humRoot.CFrame.LookVector * 25 + Vector3.yAxis
                    until os.clock() - exhaust >= .4
                end)
            end
        end
    end    
end)