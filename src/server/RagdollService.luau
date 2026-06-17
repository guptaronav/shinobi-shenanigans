local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StateService = require(game.ServerStorage.RojoStorage.Modules.StateService)
local HitboxService = require(ReplicatedStorage.Shared.Services.Hitbox)

type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: Part}

--- Ragdoll
local service = {}
service.__index = service

local offsets = require(game.ServerStorage.RojoStorage.Data.RagdollOffsets)
local instances = {}

function service.init(char)
    local self = {}

    self._RagdollTimers = {}
    self.Character = char

    setmetatable(self, service)

    local hum = char:WaitForChild("Humanoid")
    hum.RequiresNeck = false
    hum.BreakJointsOnDeath = false
    self:BuildRagdollColliders(char)
    self:BuildJoints(char)

    -- local humRoot = char:WaitForChild('HumanoidRootPart')
    -- local torsoAttachment = Instance.new('Attachment')
    -- torsoAttachment.Parent = char:WaitForChild('Torso')
    -- local torsoWeld = Instance.new('RigidConstraint')
    -- torsoWeld.Enabled = false
    -- torsoWeld.Name = 'RagdollTorsoWeld'
    -- torsoWeld.Attachment0 = humRoot:WaitForChild('RootAttachment')
    -- -- torsoWeld.Part0 = humRoot
    -- torsoWeld.Attachment1 = torsoAttachment
    -- -- torsoWeld.Part1 = char:WaitForChild('Torso')
    -- torsoWeld.Parent = char:WaitForChild('Torso')

    instances[char] = self
    return self
end

function service.Get(char)
    -- print(instances[char])
    return instances[char]
end

function service:BuildRagdollColliders(char)
    for _,v in char:GetChildren() do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            local p = v:Clone()
            p.Parent = v
            p.CanCollide = false
            p.Massless = true
            p.Size = Vector3.one
            p.Name = "Collider"
            p.Transparency = 1
            -- p.CustomPhysicalProperties = PhysicalProperties.new(40, 2, 0, 10, 10)
            p:ClearAllChildren()

            local weld = Instance.new("Weld")
            weld.Parent = p
            weld.Part0 = v
            weld.Part1 = p
        end
    end
end

function service:EnableRagdollColliders(char, enable)
    for _,v in char:GetChildren() do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.CanCollide = not enable
            v.Collider.CanCollide = enable
        end
    end
end

function service:EnableMotor6D(char, enable: boolean)
    for i,v in char:GetDescendants() do
        if v.Name == "Handle" or v.Name == "RootJoint" or v.Name == "Neck" then continue end
        if v:IsA("Motor6D") then v.Enabled = enable end
        -- if v:IsA("BasePart") then v.CollisionGroup = if enable then "Character" else "Ragdoll" end
    end
end

function service:BuildJoints(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")

    for _,v in char:GetDescendants() do
        if not v:IsA("BasePart") or v:FindFirstAncestorOfClass("Accessory") or v.Name == "Handle" or v.Name == "Torso" or v.Name == "HumanoidRootPart" then continue end
        if not offsets[v.Name] then continue end

        -- print('creating joint')
        local a0: Attachment, a1: Attachment = Instance.new("Attachment"), Instance.new("Attachment")
        local joint: Constraint = game.ReplicatedStorage.Assets.RagdollJoints[v.Name]:Clone()

        a0.Name = "RAGDOLL_ATTACHMENT"
        a0.Parent = v
        a0.CFrame = offsets[v.Name].CFrame[2]

        a1.Name = "RAGDOLL_ATTACHMENT"
        a1.Parent = hrp
        -- a1.Parent = char.Torso
        a1.CFrame = offsets[v.Name].CFrame[1]

        joint.Name = "RAGDOLL_CONSTRAINT"
        joint.Enabled = false
        joint.Parent = v
        joint.Attachment0 = a0
        joint.Attachment1 = a1

        -- joint.Radius = 0.15
        -- joint.LimitsEnabled = true
        -- joint.TwistLimitsEnabled = false
        -- joint.MaxFrictionTorque = 0
        -- joint.Restitution = 0
        -- joint.UpperAngle = 90
        -- joint.TwistLowerAngle = -45
        -- joint.TwistUpperAngle = 45

        -- v.Massless = true
    end
end

function service:DestroyJoints(char)
    char.HumanoidRootPart.Massless = false
    char.Head.Massless = false
    char['Left Arm'].Massless = false;char['Right Arm'].Massless = false;char['Left Leg'].Massless = false;char['Right Leg'].Massless = false
    char.Torso.Massless = false

    for _,v in char:GetDescendants() do
        if v.Name == "RAGDOLL_ATTACHMENT" or v.Name == "RAGDOLL_CONSTRAINT" then 
            v:Destroy()
        end
    end
end

function service:EnableJoints(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")

    for _,v in char:GetDescendants() do
        if not v:IsA("BasePart") or v:FindFirstAncestorOfClass("Accessory") or v.Name == "Handle" or v.Name == "Torso" or v.Name == "HumanoidRootPart" then continue end
        if not offsets[v.Name] then continue end

        local joint = v:FindFirstChild('RAGDOLL_CONSTRAINT')
        if not joint then
            continue
        end
        -- joint.Name = "RAGDOLL_CONSTRAINT"
        joint.Enabled = true
        -- joint.Parent = v
        -- joint.Attachment0 = a0
        -- joint.Attachment1 = a1

        v.Massless = true
    end
end

function service:DisableJoints(char)
    char.HumanoidRootPart.Massless = false
    char.Head.Massless = false
    char['Left Arm'].Massless = false;char['Right Arm'].Massless = false;char['Left Leg'].Massless = false;char['Right Leg'].Massless = false
    char.Torso.Massless = false

    for _,v in char:GetDescendants() do
        if  v.Name == "RAGDOLL_CONSTRAINT" then 
            v.Enabled = false
        end
    end
end

--[=[
    Ragdolls the character and unragdolls it after a specified duration (if provided).
]=]
function service:Ragdoll(char, duration: number?, voxelPhaseDuration: number?)
    return self:Ragdoll_(duration)
end


local collisionParams = OverlapParams.new()
collisionParams.FilterDescendantsInstances = {workspace.Map}
collisionParams.FilterType = Enum.RaycastFilterType.Include
collisionParams.RespectCanCollide = true

--[=[
    Ragdolls the character and unragdolls it after a specified duration (if provided).
]=]
type DestructionFields = {
    DestructionPower: number,
    SizeScale: number?,
    GainVerticalVelocity: boolean?,
    VoxelSize: number?,
}
function service:Ragdoll_(duration: number?, destructionFields: DestructionFields?)
    local char: Character = self.Character
    if char:GetAttribute('IFrame') or char:GetAttribute('Superarmor') then return end
    local hum: Humanoid = char.Humanoid

    if not char:GetAttribute('Ragdolled') then
        if not char:FindFirstChild("HumanoidRootPart") then return end
        char:SetAttribute("Ragdolled", true)
    
        service:EnableMotor6D(char, false)
        -- service:BuildJoints(char)
        service:EnableJoints(char)
        service:EnableRagdollColliders(char, true)

        -- hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
        -- hum:ChangeState(Enum.HumanoidStateType.PlatformStanding)
        hum.PlatformStand = true
        local platCon; platCon = RunService.Heartbeat:Connect(function()
            -- print('BROKENNNN!!!!')
            if char:GetAttribute('Ragdolled') then
                hum.PlatformStand = true
            end
        end)
        char:GetAttributeChangedSignal('Ragdolled'):Once(function()
            platCon:Disconnect()
        end)
        hum.AutoRotate = false
        
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        local plr = game.Players:GetPlayerFromCharacter(char)
    
        pcall(function()
            for _,v: Part in char:GetChildren() do
                if v:IsA('BasePart') then
                    if not v.Anchored then
                        if plr then
                            v:SetNetworkOwner(plr)
                        else
                            v:SetNetworkOwner(nil)
                        end
                    end
                    -- v.CustomPhysicalProperties = PhysicalProperties.new(.7, 0, 0, 0, 0)
                end
            end
        end)
    
        hum.JumpHeight = 0
    end

    --- Voxel destruction part
    local humRoot = char.HumanoidRootPart
    local hitboxSize = Vector3.one * 6

    if destructionFields then
        local SkillService = require(ReplicatedStorage.Shared.Services.SkillService)
        if not destructionFields.SizeScale then destructionFields.SizeScale = 1 end
        
        for _,v in char:GetDescendants() do
            if v:IsA('BasePart') and v.Name == 'Collider' then
                v.Massless = false
            end
        end
        -- task.spawn(function()
        --     while task.wait() and char:GetAttribute('Ragdolled') do
        --         if destructionFields.DestructionPower >= 15 then
        --             for _,v in char:GetDescendants() do
        --                 if v:IsA('BasePart') and v.Name == 'Collider' then
        --                     v.CollisionGroup = 'Ragdolls'
        --                 end
        --             end
        --         else
        --             task.wait(.1)
        --             for _,v in char:GetDescendants() do
        --                 if v:IsA('BasePart') and v.Name == 'Collider' then
        --                     v.CollisionGroup = 'Characters'
        --                 end
        --             end
        --         end
        --     end
        -- end)

        local exhaust = os.clock()
        HitboxService.CollisionEvent(char, function()
            if not char:GetAttribute('Ragdolled') then return end
            if destructionFields.Delay and os.clock() - exhaust < destructionFields.Delay then return 1 end
            -- exhaust = os.clock()
    
            local velocity = humRoot.AssemblyLinearVelocity
            local unitVelocity = velocity.Unit
    
            local power = destructionFields.DestructionPower
            if destructionFields.GainVerticalVelocity then
                -- print(math.abs(velocity.Y)/15)
                power += math.abs(velocity.Y)/15
            end

            local voxels, hitNonVoxel = SkillService.CoreVoxelDestruction(
                {Core = char.HumanoidRootPart, LaunchDirection = unitVelocity * power + Vector3.yAxis*3},
                hitboxSize,--* power * destructionFields.SizeScale,
                destructionFields.VoxelSize or 2,
                Enum.PartType.Ball,
                30, 40,
                power <= 5, true)
    
            if hitNonVoxel then
                destructionFields.DestructionPower /= 2
            end

            return 1
        end, {HitboxSize = 9}, {Timeout = duration, Yields = false, RequiresConfirmedStop = true, Interval = .1})
    end

    if not duration then return end
    if self._RagdollTimers[char] then task.cancel(self._RagdollTimers[char]) end
    self._RagdollTimers[char] = task.delay(duration, function()
        self:UnRagdoll(char)
    end)
end

function service:UnRagdoll(char)
    if not char:GetAttribute('Ragdolled') then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")

    if hum:GetState() == Enum.HumanoidStateType.Dead then return end

    local plr = game.Players:GetPlayerFromCharacter(char) 

    if not plr then
        if char.HumanoidRootPart.Anchored == false then
            char.HumanoidRootPart:SetNetworkOwner(nil)
        end
    end

    for _,v in char:GetDescendants() do
        if v:IsA('BasePart') and v.Name == 'Collider' then
            v.Massless = true
        end
    end

    char.HumanoidRootPart.RootJoint.Enabled=  true
    -- char.Torso.RagdollTorsoWeld.Enabled = falses
    -- service:DestroyJoints(char)
    service:DisableJoints(char)
    service:EnableMotor6D(char, true)
    service:EnableRagdollColliders(char, false)

    if hum:GetState() ~= Enum.HumanoidStateType.Dead then
        if plr then
            game.ReplicatedStorage.Remotes.UnRagdoll:FireClient(plr)
        else
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            -- hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end

    local state = StateService.Get(char)
    state:Superarmor(true, .4)

    char:SetAttribute("Ragdolled", false)
    hum.PlatformStand = false

    hum.AutoRotate = true
    hum.JumpHeight = 5

    -- for _,v: BasePart in char:GetChildren() do
    --     if v:IsA('BasePart') then
    --         v.CustomPhysicalProperties = PhysicalProperties.new(.7, .3, .5, 1, 1)
    --     end
    -- end
end

return service