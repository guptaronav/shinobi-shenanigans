local rs = game:GetService("RunService")
local Promise = {} 
local pLocation = game.ReplicatedStorage:FindFirstDescendant('Promise')
if pLocation then
	Promise = require(pLocation)
end

local hitbox = {}

local debug: boolean = game.ReplicatedStorage:GetAttribute('DebugMode') or false
--game.ReplicatedStorage:GetAttributeChangedSignal('DebugMode'):Connect(function()
--	debug = game.ReplicatedStorage:GetAttribute('DebugMode')
--end)

type Character = Model
type callback = () -> nil

type Hitbox = {
	HitEvent: {Connect: (callback) -> nil, Once: (callback) -> nil},
	OverlapParams: OverlapParams,
	Size: Vector3,
	Core: BasePart,
	Offset: Vector3,
	CFrame: CFrame,
	CoreMode: boolean,
	Mode: 'Characters' | 'Non-Characters' | 'All',
	Single: boolean,
	Hits: {Character},

	Start: (onClient: Player) -> nil,
	Stop: () -> nil,
	GetHits: () -> {Character | BasePart},
	ResetHits: () -> nil,
}

--[=[
    Creates an object version of Hitbox.instant().

    ----

    The hitbox will become active once ``Start()`` is called, and can be stopped when ``Stop()`` is called.

    ``GetHits()`` returns a table with the current hits the hitbox has made.

    ``Single``, when ``true``, will cancel the hitbox once a hit occurs.

    ----

    There are two modes the hitbox can be in, controlled by ``CoreMode``.

    When ``false``:

    -``CFrame`` will be where the hitbox will be positioned at.

    When ``true``:

    -``Core`` will be the ``BasePart`` the hitbox will follow.

    -``Offset`` will be the offset Vector3 relative to the ``Core``.

    ----

    ``HitEvent`` is an event that calls the ``callback`` given once a hit occurs.

    ----

    Example:
    ```lua
        local hitbox = HitboxService.new()
        hitbox.Size = Vector3.one * 10
        hitbox.CoreMode = true
        hitbox.Core = char.HumanoidRootPart
        hitbox.Offset = char.HumanoidRootPart.UpVector * 15
        
        hitbox:Start()
        task.wait(.5)
        hitbox:Stop()

        local hits = hitbox:GetHits()
        for _,v in hits do
            v.Humanoid.Health -= 10
        end
    ```
]=]
function hitbox.new(): Hitbox
	local hitEvent: callback

	local self: Hitbox = setmetatable({}, {})

	self.HitEvent = {}
	function self.HitEvent:Connect(callback: callback): nil
		hitEvent = callback
	end

	local op: OverlapParams = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	self.OverlapParams = op :: OverlapParams

	self.Size = Vector3.one * 3 :: Vector3
	self.CFrame = nil :: CFrame
	self.Offset = Vector3.zero :: Vector3
	self.Core = nil :: BasePart
	self.Single = false :: boolean
	self.CoreMode = false :: boolean
	self.Mode = 'Characters'

	self.Hits = {} :: {Character}

	local running: boolean = false
	function self:Start(onClient: Player?): nil
		running = true

		task.spawn(function()
			while rs.Heartbeat:Wait() and running do
				local hits: {Character}

				if self.CoreMode then
					hits = hitbox.instant({Core=self.Core, Offset=self.Offset}, self.Size, self.OverlapParams, self.Single, onClient)
				else
					hits = hitbox.instant(self.CFrame, self.Size, self.OverlapParams, self.Single, onClient)
				end

				if self.Single and hits then
					if hitEvent then
						hitEvent(hits)
					end

					if self.Single then
						self:Stop()
						break
					end
				elseif hits then
					for _,v in hits do
						if table.find(self.Hits, v) then continue end
						table.insert(self.Hits, v)

						if hitEvent then
							hitEvent(v)
						end
					end
				end
			end
		end)
	end

	function self:Stop(): nil
		running = false
	end

	function self:GetHits(): {Character}
		return self.Hits
	end

	function self:ResetHits(): nil
		self.Hits = {}
	end

	return self
end

--[=[
    Creates a hitbox that only runs once.
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

    ``single``, when set to ``true``, will make the function only return a single hit.

    ``onClient``, when set to ``true``, will make hitbox run on the client. (You must manually code this process).

    ``mode`` can be given 3 different strings that all do a different purpose:
    ```
        'Characters' -- The list will only contain characters.
        'Non-Characters' -- The list will only contain BaseParts.
        'All' -- The list will contain both BaseParts of Non-Characters and models of Characters.
    ```

    ```
    @return FilteredHits : {Character | BasePart}
    ```
]=]
function hitbox.instant(cframe: CFrame | {Offset: Vector3, Core: BasePart}, size: Vector3, op: OverlapParams | Character?, single: boolean?, onClient: Player?, mode: 'Characters'|'Non-Characters'|'All'?): table
	if onClient then
		return Promise.new(function(resolve)
			local hits = game.ReplicatedStorage.Remotes.ClientHitbox:InvokeClient(onClient, cframe, size, op, single, nil, mode)
			resolve(hits)
			-- return hits
		end):timeout(.1):catch(function() -- if client doesnt respond in time, then it will just calculate the hitbox on the server
			warn('timeout client box')
			return hitbox.instant(cframe, size, op, single, nil, mode)
		end):expect()
	end

	if typeof(op) == "Instance" then
		local newOp = OverlapParams.new()
		newOp.FilterDescendantsInstances = {op}
		newOp.FilterType = Enum.RaycastFilterType.Exclude
		op = newOp
	end

	if not mode then mode = 'Characters' end

	if debug then
		task.defer(function()
			local visualPart = Instance.new('Part')
			visualPart.Anchored = true
			visualPart.CanCollide = false
			visualPart.Color = Color3.new(1,0,0)
			visualPart.Transparency = .5
			visualPart.Size = size
			visualPart.CFrame = typeof(cframe) == "CFrame" and cframe or cframe.Core.CFrame + cframe.Offset
			visualPart.CanQuery = false
			visualPart.Parent = workspace.UnobstructiveAssets
			task.wait(.1)
			visualPart:Destroy()
		end)
	end

	local hits = workspace:GetPartBoundsInBox(typeof(cframe) == "CFrame" and cframe or cframe.Core.CFrame + cframe.Offset, size, op)
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
			if single then return v.Parent end
			table.insert(filteredHits, v.Parent)
		end
	end

	if single then return nil end
	return filteredHits
end

--[=[
    Waits until the given character collides with the environment.
    If a collision is not found after 3 seconds, the function will return ``nil``.    
]=]
function hitbox.WaitForCollision(char: Model, whitelist: table?, excludeWhitelist: boolean?, rayLength: number?): BasePart & Vector3 & Vector3
	local timeout = os.clock()

	while rs.Heartbeat:Wait() do
		if char.Parent ~= workspace.Characters then
			return nil
		end

		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {workspace.Characters, workspace.UnobstructiveAssets}
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		local rays = {
			[-Vector3.yAxis] = workspace:Raycast(char.HumanoidRootPart.Position, -Vector3.yAxis * (rayLength or 2.1), rayParams),
			[Vector3.yAxis] = workspace:Raycast(char.HumanoidRootPart.Position, Vector3.yAxis * (rayLength or 2.1), rayParams),
			[Vector3.xAxis] = workspace:Raycast(char.HumanoidRootPart.Position, Vector3.xAxis * (rayLength or 2.1), rayParams),
			[-Vector3.xAxis] = workspace:Raycast(char.HumanoidRootPart.Position, -Vector3.xAxis * (rayLength or 2.1), rayParams),
			[Vector3.zAxis] = workspace:Raycast(char.HumanoidRootPart.Position, Vector3.zAxis * (rayLength or 2.1), rayParams),
			[-Vector3.zAxis] = workspace:Raycast(char.HumanoidRootPart.Position, -Vector3.zAxis * (rayLength or 2.1), rayParams),
		}

		if whitelist and typeof(whitelist) == 'table' then
			for i,_ in rays do
				if excludeWhitelist and table.find(whitelist, i) or not excludeWhitelist and not table.find(whitelist, i) then
					rays[i] = nil
				end
			end
		end

		for i: Vector3, v: Ray in rays do
			if v.Instance and v.Position then
				return v.Instance, i, v.Position
			end
		end

		if os.clock() - timeout >= 3 then return nil end
	end
end

return hitbox