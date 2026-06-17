-- State service - Manages the state of players
-- States:
-- Knockback, Stun, Superarmor, Invincibility Frames, etc.
local utility = require(game.ReplicatedStorage.Modules.Utility)
-- local AnimationService = require(game.ReplicatedStorage.Shared.Services.AnimationService)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rs = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local service = {}
service.__index = service

type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: Part}

local characters = {}

function service.init(char): nil
    local self = {}

    self._Timer = nil
    self._AttackTimer = nil
    self._DeathEvents = {}
    self.Character = char

    local stunFolder = Instance.new('Folder')
    stunFolder.Name = 'Stuns'
    stunFolder.Parent = char.Values

    local cooldownFolder=  Instance.new('Folder')
    cooldownFolder.Name = 'Cooldowns'
    cooldownFolder.Parent = char.Values

    local walkSpeedFolder = Instance.new('Folder')
    walkSpeedFolder.Name = 'WalkspeedPriorities'
    walkSpeedFolder.Parent = char.Values

    local attackerFolder = Instance.new('Folder')
    attackerFolder.Name = 'Attackers'
    attackerFolder.Parent = char.Values

    characters[char] = self
    setmetatable(self, service)
end

function service.Get(char)
    if not characters[char] then
        repeat
            task.wait()
        until characters[char]
    end
    return characters[char]
end

local stunDurations = {}
--[=[
    Adds a stun to the character. If given a duration, it will expire once the time is up.

    A priority is in which how the stun will affect a character who is currently using a skill.
    If the priority is lower or equal to the skill's priority, the stun will not affect ethe character.

    Priority ranking:
    - 1: Punching/Blocking
    - 2: Lower-end skill
    - 3: Mid-end skill
    - 4: Higher-end skill
    - 5-8: Free
    - 9: 
    - 10: Awakening
]=]
function service:Stun(id: string, duration: number?, priority: number?): boolean
    local char = self.Character
    if char:GetAttribute('Superarmor') or char:GetAttribute('IFrame') then return end

    local stun = Instance.new('NumberValue')
  
    stun.Name = id
    
    stun.Value = priority or 1

    local hum = char.Humanoid
   
    self:SetWalkspeed('Stun_'..id, 10, 0)
    hum.JumpHeight = 0

    if not duration then stun.Parent = char.Values.Stuns; return true end

    if not stunDurations[char] then stunDurations[char] = {} end
    if stunDurations[char][id] then 
        task.cancel(stunDurations[char][id]) 
        local pastStun = char.Values.Stuns:FindFirstChild(id)
        if pastStun then
            pastStun:Destroy()
        end
    end

    stunDurations[char][id] = task.delay(duration, function()
        self:UnStun(id)
    end)

    stun.Parent = char.Values.Stuns

    return true
end

function service:UnStun(id)
    print('Ending stun: '..id)
    local char = self.Character
    local stun = char.Values.Stuns:FindFirstChild(id)
    if stun then
        stun:Destroy()
    end

    self:EndWalkspeed('Stun_'..id)

    if not char.Values.Stuns:FindFirstChildWhichIsA('NumberValue') then
        local hum = char.Humanoid
        hum.JumpHeight = game.StarterPlayer.CharacterJumpHeight
    end
end

function service:DisableAttackState(disable: boolean, duration: number?)
    self.Character:SetAttribute('AttackDisabled', disable or nil)

    if not disable or not duration then return end

    if self._Timer then coroutine.close(self._Timer) end
    self._Timer = coroutine.create(function()
        task.wait(duration)
        self.Character:SetAttribute('AttackDisabled', nil)
    end)
    coroutine.resume(self._Timer)
end

function service:Superarmor(enable: boolean, duration: number?)
    self.Character:SetAttribute('Superarmor', enable or nil)

    if not enable or not duration then return end

    if self._STimer then coroutine.close(self._STimer) end
    self._STimer = coroutine.create(function()
        task.wait(duration)
        self.Character:SetAttribute('Superarmor', nil)
    end)
    coroutine.resume(self._STimer)
end

function service:IFrame(enable: boolean, duration: number?)
    self.Character:SetAttribute('IFrame', enable or nil)

    if not enable or not duration then return end

    if self._ITimer then coroutine.close(self._ITimer) end
    self._ITimer = coroutine.create(function()
        task.wait(duration)
        self.Character:SetAttribute('IFrame', nil)
    end)
    coroutine.resume(self._ITimer)
end

--[=[
    Priorities:
    - 1: Run/Walk
    - 2: Blocking
    - 3: Punching/Other basic combat actions
    - 4: Minor actions
    - 5: Intermediate actions
    - 6: Major actions
    - 7-8: Free
    - 9: Awakening
    - 10: Stun
]=]
function service:SetWalkspeed(id: string, priority: number, walkSpeed: number, dontKeep: boolean?)
    local hum = self.Character.Humanoid
    local priorities = self.Character.Values.WalkspeedPriorities:GetChildren()
    
    -- Creates a priority which will stay until deleted if dontKeep is false
    if not dontKeep then
        if self.Character.Values.WalkspeedPriorities:FindFirstChild(id) then
            self.Character.Values.WalkspeedPriorities:FindFirstChild(id):Destroy()
        end

        local newPriority = Instance.new('IntValue')
        newPriority.Value = priority
        newPriority.Name = id
        newPriority:AddTag('SafelyAdded')
        newPriority.Parent = self.Character.Values.WalkspeedPriorities

        local wValue = Instance.new('NumberValue')
        wValue.Name = 'WalkSpeed'
        wValue.Value = walkSpeed
        wValue.Parent = newPriority

        wValue:SetAttribute('StartTime', os.clock())
    end

    local update: boolean = true
    for _, v in priorities do
        if v.Value > priority then update = false; break end
    end

    if update then
        hum.WalkSpeed = walkSpeed
    end
end

function service:EndWalkspeed(id: string)
    local hum = self.Character.Humanoid

    local foundPriority = self.Character.Values.WalkspeedPriorities:FindFirstChild(id)
    if foundPriority then
        local priority = foundPriority.Value
        foundPriority:Destroy()

        local priorities = self.Character.Values.WalkspeedPriorities:GetChildren()

        local highest: NumberValue = Instance.new('NumberValue'); highest.Value = -1
        for _,v in priorities do
            if v.Value > priority then return end
            if v.Value > highest.Value and v.Value <= priority then
                highest = v
            end
        end

        if highest.Value ~= -1 then
            -- print('priority: '..highest.Value, 'walkspeed: '..highest.WalkSpeed.Value)
            hum.WalkSpeed = highest.WalkSpeed.Value
        else
            -- print('default speed')
            hum.WalkSpeed = self.Character:GetAttribute('WalkSpeed')
        end
    end
end

function service:HasWalkspeed(id: string)
    return self.Character.Values.WalkspeedPriorities:FindFirstChild(id)
end

function service:UpdateWalkSpeed()
    local hum = self.Character.Humanoid
    local priorities = self.Character.Values.WalkspeedPriorities:GetChildren()

    local highest: NumberValue = Instance.new('NumberValue'); highest.Value = -1
    for _,v in priorities do
        if v.Value > highest.Value then
            highest = v
        end
    end

    if highest.Value == -1 then 
        -- print('default speed')
        hum.WalkSpeed = self.Character:GetAttribute('WalkSpeed') 
    else
        hum.WalkSpeed = highest.WalkSpeed.Value
    end
end

function service:Knockback(caster: Model, velocity: Vector3, duration: number, alignmentPosition: Vector3?, fade: boolean?, exemptions: table?)
    local char = self.Character

    if char ~= caster and ( char:GetAttribute('IFrame') or char:GetAttribute('Superarmor') ) then return end

    if char.HumanoidRootPart.Anchored then
        char.HumanoidRootPart.Anchored = false
    end

    local plr = game.Players:GetPlayerFromCharacter(char)
    if plr then
        game.ReplicatedStorage.Remotes.Knockback:FireClient(plr, velocity, duration, alignmentPosition, fade, exemptions)
    else
        if not alignmentPosition then
            -- local existingBV = char.HumanoidRootPart:FindFirstChildWhichIsA('BodyVelocity')
            for i,bv in char.HumanoidRootPart:GetChildren() do
                -- if bv:IsA('BodyVelocity') then
                if bv:IsA('BodyVelocity') then
                    bv:Destroy()
                end
            end
            -- if existingBV then existingBV:Destroy() end

            local bv= Instance.new('BodyVelocity')
            bv.Parent = char.HumanoidRootPart
            -- bv.Attachment0 = char.HumanoidRootPart.RootAttachment
            -- -- bv.MaxForce = 25000
            -- bv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
            -- bv.RelativeTo = Enum.ActuatorRelativeTo.World
            -- bv.ForceLimitsEnabled = true
            -- bv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
            bv.MaxForce = Vector3.new(300000, 300000, 300000)

            if exemptions then
                for _,v in exemptions do
                    bv.MaxForce -= v * 300000
                end
            end

            
            bv.Velocity = velocity
            
            local cPlr = game.Players:GetPlayerFromCharacter(caster)
            if cPlr then
                for _,v in char:GetChildren() do
                    if v:IsA('BasePart') and not v.Anchored then
                        v:SetNetworkOwner(cPlr)
                    end
                end
            end

            char.HumanoidRootPart.RootPriority = 127
            -- local bv = Instance.new("BodyVelocity")
            -- bv.Parent = char.HumanoidRootPart
            -- bv.MaxForce = Vector3.new(75000,75000,75000)
            -- if exemptions then
            --     for _,v in exemptions do
            --         bv.MaxForce -= v * 75000
            --     end
            -- end
            -- bv.Velocity = velocity

            if fade then
                TweenService:Create(bv, TweenInfo.new(duration), {Velocity = Vector3.zero}):Play()

                -- TweenService:Create(bv, TweenInfo.new(duration), {Velocity = Vector3.zero}):Play()
            end
            task.delay(duration, function()
                bv:Destroy()
            end)
            return bv
        else
            local ap = Instance.new('AlignPosition')
            ap.Attachment0 = Instance.new('Attachment')--; ap.Attachment1 = Instance.new('Attachment')
            ap.Attachment0.Parent = char.HumanoidRootPart
            ap.Mode = Enum.PositionAlignmentMode.OneAttachment
            ap.Position = alignmentPosition
            ap.ForceRelativeTo = Enum.ActuatorRelativeTo.Attachment0
            ap.MaxForce = 30000
            ap.Responsiveness = velocity.Magnitude
            ap.Parent = char
            task.delay(duration, function()
                ap:Destroy()
            end)

            return ap
        end
    end
end

function service:Velocity(velocity: Vector3, duration: number, fade: boolean?, exemptions: table)
    return self:Knockback(self.Character, velocity, duration, nil, fade, exemptions)
end

function service:Knockdown(char, duration) -- similar to stun but its visibly clear and usually after being midair

end

function service:Collision(enable: boolean, includeMap: boolean?)
    for _,v: BasePart in self.Character:GetDescendants() do
        if v:IsA('BasePart') and not v:FindFirstAncestorWhichIsA('Accessory') then
            v.CollisionGroup = enable and 'Characters' or not includeMap and 'Ghosts' or 'NonCollidable'
        end
    end
end

function service:DeathEvent(callback: (...any) -> nil): nil
    table.insert(self._DeathEvents, callback)
end

function service:_ExecuteDeathEvents()
    local results=  {}
    for _,callback in self._DeathEvents do
        table.insert(results, callback() or '')
    end
    table.clear(self._DeathEvents)
    return results
end

return service