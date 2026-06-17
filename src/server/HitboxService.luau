local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hitbox = {}

-- If true, hitboxes will be visualized.
local debugHitboxes = ReplicatedStorage:GetAttribute('DebugMode') or false
ReplicatedStorage:GetAttributeChangedSignal('DebugMode'):Connect(function()
	debugHitboxes = ReplicatedStorage:GetAttribute('DebugMode')
end)

type Character = Model
type callback = (Hit: Character) -> any?
type CoreFields = {Core: BasePart, Offset: Vector3 | {number}, OffsetIsRelativeTo: nil | {'LookVector' | 'UpVector' | 'RightVector'}}

type HitEvent = {
	_Event: HitEvent,
	Connect: (_self: HitEvent, callback) -> nil,
	Wait: () -> Character | {Character},
}

type Hitbox = {
	Running: boolean,

	Hits: {Character},
	Single: boolean,
	Mode: 'Characters' | 'Non-Characters' | 'All',

	CoreMode: boolean,
	Core: BasePart,
	CFrame: CFrame,
	Size: Vector3,
	OffsetIsRelativeTo: nil | {'LookVector' | 'UpVector' | 'RightVector'},
	Offset: Vector3 | {number},
	OverlapParams: OverlapParams | Character,
	Shape: Enum.PartType,

	Start: (_self: Hitbox) -> nil,
	Stop: () -> nil,
	GetHits: () -> {Character | BasePart},
	ResetHits: () -> nil,
	HitEvent: HitEvent,
}

local HitboxObject = {}
HitboxObject.__index = HitboxObject

--[=[
    Creates an object version of Hitbox.instant().
    Read Hitbox.instant() documentation for more information about the hitbox itself.

    ----

    The hitbox will become active once ``:Start()`` is called, and can be stopped with ``Stop()``.

    ``:GetHits()`` returns a table with the current hits the hitbox has made.

    ``.Single``, when ``true``, will cancel the hitbox once a hit occurs.

    ----

    There are two modes the hitbox can be in, controlled by ``.CoreMode``.

    When ``false``: ``CFrame`` will be where the hitbox will be positioned/rotated at.

    When ``true``: ``Core`` will be the ``BasePart`` the hitbox's CFrame will follow.

    ----

    ``Offset`` will be the offset Vector3 relative to the ``Core``.

    ``OffsetIsRelativeTo`` determined if the offset is relative to the core through its LookVector, UpVector, and RightVector. If used, ``Offset`` must become a table with the respective order.

    ----

    ``HitEvent`` is an event that can be used to fire a callback once a hit/s is detected. This event has 2 methods.
    
    -``:Connect()`` includes callback that fires everytime a hit is detected.

    -``Wait()`` yields until a hit is detected, and returns it.

    ----
    Example 1 - CFrame:
    ```lua
        local hitbox = HitboxService.new()
        hitbox.Size = Vector3.one * 10
        hitbox.CFrame = part.CFrame + Vector3.yAxis * 2
        hitbox.Single = true

        hitbox:Start()
        task.wait(.5)
        hitbox:Stop()

        local hit = hitbox:GetHits()
        hit.Humanoid.Health -= 5
    ```

    Example 2 - CoreMode is True:
    ```lua
        local hitbox = HitboxService.new()
        hitbox.Size = Vector3.one * 10
        hitbox.CoreMode = true
        hitbox.Core = char.HumanoidRootPart
        hitbox.OffsetIsRelativeTo = {'LookVector', 'UpVector'}
        hitbox.Offset = {3, 1}
        hitbox.OverlapParams.FilterDescendantInstances = {char}

        hitbox:Start()
        task.wait(.5)
        hitbox:Stop()

        local hits = hitbox:GetHits()
        for _,v in hits do
            v.Humanoid.Health -= 10
        end
    ```

    Example 3 - HitEvent:
    ```lua
        local hitbox = HitboxService.new()
        hitbox.Size = Vector3.one * 10
        hitbox.CoreMode = true
        hitbox.Core = char.HumanoidRootPart
        hitbox.Offset = Vector3.yAxis * 5
        hitbox.OverlapParams = char

        hitbox.HitEvent:Connect(function(hit: Character)
            hit.Humanoid.Health += 25
        end)

        hitbox:Start()
        task.wait(1)
        hitbox:Stop()
    ```
]=]
function hitbox.new(): Hitbox
	local self: Hitbox = setmetatable({}, HitboxObject)

	-- Backend properties.
	self.Running = false
	self.Hits = {} :: {Character}
	self.HitEvent = {}
	self.HitEvent._Event = nil :: callback

	self.Single = false
	self.CoreMode = false
	self.Mode = 'Characters'

	-- Frontend properties.
	local op: OverlapParams = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	self.OverlapParams = op :: OverlapParams

	self.Size = Vector3.one * 3
	self.Core = nil :: BasePart; self.CFrame = nil :: CFrame
	self.OffsetIsRelativeTo = nil
	self.Offset = Vector3.zero :: Vector3 | {}
	self.Shape = Enum.PartType.Block

	function self.HitEvent:Connect(callback: callback): nil
		self._Event = callback
	end
	function self.HitEvent.Wait(): Character | {Character}
		repeat
			RunService.Heartbeat:Wait()
		until self.Single and self.Hits or not self.Single and #self.Hits > 0
		return self.Hits
	end

	return self
end

function HitboxObject:Start(): nil
	-- Remove the asserts once you're used to the module if you want to.
	assert(not (self.CFrame and self.CoreMode), 'CFrame cannot be used while CoreMode is active.')
	assert(not (self.Core and not self.CoreMode), "Core cannot be used while CoreMode isn't active.")
	assert(not (self.CFrame and self.Core), 'Core and CFrame cannot be used at the same time.')
	if self.OffsetIsRelativeTo then
		assert(typeof(self.OffsetIsRelativeTo) == 'table', 'OffsetIsRelativeTo must be a table.')
		assert(typeof(self.Offset) == 'table', 'Offset must be a table when OffsetIsRelativeTo is being used.')
	end
	assert(self.Shape == Enum.PartType.Block or self.Shape == Enum.PartType.Ball, 'Current shape is not supported.')

	self.Running = true

	task.spawn(function()
		while RunService.Heartbeat:Wait() and self.Running do
			local hits: {Character}

			if self.CoreMode then
				hits = hitbox.instant({Core=self.Core, Offset=self.Offset, OffsetIsRelativeTo = self.OffsetIsRelativeTo}, self.Size, self.OverlapParams, self.Shape, self.Single, self.Mode)
			else
				hits = hitbox.instant(self.CFrame, self.Size, self.OverlapParams, self.Shape, self.Single, self.Mode)
			end

			if self.Single and hits then
				if self.HitEvent._Event then
					self.HitEvent._Event(hits)
				end

				self.Hits = hits

				self:Stop()
				break
			elseif hits then
				for _, hit in hits do
					if table.find(self.Hits, hit) then continue end
					table.insert(self.Hits, hit)

					if self.HitEvent._Event then
						self.HitEvent._Event(hit)
					end
				end
			end
		end

		self.Running = false
	end)
end

function HitboxObject:Stop(): nil
	self.Running = false
end

function HitboxObject:GetHits(): {Character}
	return self.Hits
end

function HitboxObject:ResetHits(): nil
	self.Hits = {}
end


--[=[
    Creates a hitbox.
    Example:
    ```lua
        local op = OverlapParams.new()
        op.FilterDescendantInstances = {workspace.Map}
        op.FilterType = Enum.RaycastFilterType.Exclude
        local hits = HitboxService.instant(part1.CFrame, Vector3.one * 20, op)
        for _,v in hits do
            v.Humanoid:TakeDamage(5)
        end
    ```

    The ``OverlapParams`` argument can be given an ``Instance`` which will become a part of a generated ``FilterDescendantInstances``.
    Example:
    ```lua
        local char = player.Character or player.CharacterAdded:Wait()
        local hits = HitboxService.instant(char.HumanoidRootPart.CFrame, Vector3.one * 5, char)
    ```

    ``shape`` determines the shape of the hitbox, which can either be ``Enum.PartType.Block`` or ``Enum.PartType.Ball``. 
    If not set, it defaults to Block. If Ball is used, the radius is determined by the highest axis of the Vector3 provided in ``size``.

    ``single``, when set to ``true``, will make the function only return a single hit instead of an array of hits.

    ``mode`` can be given 3 different strings that determines what gets detected:
    ```
        'Characters' -- Hits will only contain character models.
        'Non-Characters' -- Hits will only contain non-character BaseParts.
        'All' -- Hits will contain both BaseParts of Non-Characters and models of Characters.
    ```
    By default, the mode is Characters.

    ```
    @return FilteredHits : {Character | BasePart}
    ```
]=]
function hitbox.instant(cframe: CFrame | CoreFields, size: Vector3, op: OverlapParams | Character?, shape: Enum.PartType?, single: boolean?, mode: 'Characters'|'Non-Characters'|'All'?): table

	if typeof(op) == "Instance" then
		local newOp = OverlapParams.new()
		newOp.FilterDescendantsInstances = {op, workspace.UnobstructiveAssets}
		newOp.FilterType = Enum.RaycastFilterType.Exclude
		op = newOp
	end

	if not shape then shape = Enum.PartType.Block end
	if not mode then mode = 'Characters' end

	local currentCFrame = typeof(cframe) == 'CFrame' and cframe or cframe.Core:IsA('Attachment') and cframe.Core.WorldCFrame or cframe.Core.CFrame
	local CFramePlusOffset = currentCFrame
	if typeof(cframe) == 'table' then 
		if cframe.OffsetIsRelativeTo then
			for i,off in cframe.OffsetIsRelativeTo do
				CFramePlusOffset += cframe.Core.CFrame[off] * cframe.Offset[i]
			end
		elseif cframe.Offset then
			CFramePlusOffset += cframe.Offset
		end
	end

	if debugHitboxes then
		task.defer(function()
			local visualPart = Instance.new('Part')
			visualPart.Anchored = true
			visualPart.CanCollide = false
			visualPart.Color = Color3.new(1,0,0)
			visualPart.Transparency = .5
			visualPart.Size = size
			visualPart.CFrame = typeof(cframe) == "CFrame" and cframe or CFramePlusOffset
			visualPart.CanQuery = false
			visualPart.Shape = shape
			visualPart.Parent = workspace.UnobstructiveAssets
			task.wait(.1)
			visualPart:Destroy()
		end)
	end

	local hits
	if shape == Enum.PartType.Block then
		hits = workspace:GetPartBoundsInBox(typeof(cframe) == "CFrame" and cframe or CFramePlusOffset, size, op)
	else
		local highestMagnitude = size.X > size.Y and size.X > size.Z and size.X or size.Y > size.X and size.Y > size.Z and size.Y or size.Z
		hits = workspace:GetPartBoundsInRadius(typeof(cframe) == "CFrame" and cframe.Position or CFramePlusOffset.Position, highestMagnitude, op)
	end

	local filteredHits = {}

	local function ConditionCheck(v: BasePart)
		if mode == 'Characters' then
			if v.Parent:FindFirstChild("Humanoid") and v.Parent:GetAttribute("Combo") and not table.find(filteredHits, v.Parent) then return true end
		elseif mode == 'Non-Characters' then
			if not v.Parent:FindFirstChild("Humanoid") then return true end
		else
			if v.Parent:FindFirstChild("Humanoid") and v.Parent:GetAttribute("Combo") and not table.find(filteredHits, v.Parent) or not v.Parent:FindFirstChild('Humanoid') then return true end
		end
	end

	for _,v in hits do
		if ConditionCheck(v) then
			if v.Parent:GetAttribute('IFrame') then continue end
			if single then return v.Parent end
			table.insert(filteredHits, v.Parent)
		end
	end

	if single then return nil end
	return filteredHits
end

type CollisionCallback = (collidedPart: BasePart, direction: Vector3, ray: Ray?) -> nil
local colRayParams = RaycastParams.new()
colRayParams.FilterDescendantsInstances = {workspace.Characters, workspace.UnobstructiveAssets}
colRayParams.FilterType = Enum.RaycastFilterType.Exclude

--[=[
    Creates an event that fires a callback when the player's character collides with a part.
    
    ----

    By default, once the callback is fired, the event stops running. However, if the callback returns ``false``,
    the event will continue to run until another fired callback does not return false or when the event times out.

    ----

    ``hitboxSize`` multiplies the size of each limb's hitbox by the given amount. By default, it is set to 1.2.

    ``overlapParams`` is the provided OverlapParams used for the hitbox. If not provided, a default one is generated and can be edited if needed.
    
    ``yield`` determines if the method yields the script until a collision is detected or when the event times out.

    ``timeout`` determines how long the event will last for until detection ceases.

    ``directionFilterList``, if provided, only uses the given directions (axixes) when detecting collision. 
    If ``excludeFilter`` is enabled, then it will exclude the axixes given.
]=]
function hitbox.CollisionEvent(char: Character, callback: CollisionCallback, hitboxSize: number?, overlapParams: OverlapParams | table?, timeout: number?, yield: boolean?, directionFilterList: table?, excludeFilter: boolean?)

	if not hitboxSize then hitboxSize = 1.2 end
	if not timeout then timeout = 2 end

	local op = overlapParams
	if not op or typeof(op) ~= "OverlapParams" then
		op = OverlapParams.new()
		op.FilterDescendantsInstances = {workspace.Characters, workspace.UnobstructiveAssets}
		if typeof(overlapParams) == 'table' then
			op.FilterDescendantsInstances = overlapParams
		end
		op.FilterType =Enum.RaycastFilterType.Exclude
		op.RespectCanCollide = true
	end

	local exhaust = os.clock()
	
	local function Runtime()
		while RunService.Heartbeat:Wait() do
			if char.Parent ~= workspace.Characters then
				return nil
			end

			for _,limb in char:GetChildren() do
				if limb.Name == 'HumanoidRootPart' or not limb:IsA('BasePart') then continue end 

				local hitboxDimensions = limb.Size * hitboxSize

				local collisions = workspace:GetPartBoundsInBox(limb.CFrame, hitboxDimensions, op)
				if #collisions > 0 then
					for i,d in {-Vector3.yAxis, Vector3.yAxis, Vector3.xAxis, -Vector3.xAxis, -Vector3.zAxis, Vector3.zAxis} do
						if excludeFilter and table.find(directionFilterList, d) or not excludeFilter and directionFilterList and not table.find(directionFilterList, d) then
							continue
						end

						local ray = workspace:Raycast(limb.Position, d * (hitboxSize + .5), colRayParams)
						if ray and table.find(collisions, ray.Instance) then
							warn(limb, os.clock() - exhaust)
							local result = callback(collisions[1], d, ray)
							if result ~= false then
								return result
							end
						end
					end
				end
			end

			if os.clock() - exhaust > timeout then return nil end
		end
	end

	if yield then
		Runtime()
	else
		task.spawn(Runtime)
	end	
end

return hitbox