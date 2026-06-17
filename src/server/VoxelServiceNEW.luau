--!strict
-- Roblox Services
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- Modules
local VoxelConstructor = require(script.VoxelConstructor)
local Algorithm = require(script.Algorithm)
local OctreesAlgorithm = require(script.OctreesAlgorithm)

local VoxelService = {}
VoxelService.__index = VoxelService

---- [SETTINGS] ----
local TagName: string = 'Voxable'
local Visualizer: boolean = RunService:IsStudio() and true

-- Types
type VoxablePart = Part
type Voxel = Part

-- Local Functions
local function CheckIfPartIsGreaterThanMinimum(Part: Part, Minimum: number|string): boolean
	local check: boolean = false

	if typeof(Minimum) == "number" then
		if math.floor(Part.Size.X) > Minimum or math.floor(Part.Size.Y) > Minimum or math.floor(Part.Size.Z) > Minimum then
			check = true
		end		
	end

	return check
end

local DefaultParams: OverlapParams = OverlapParams.new()
DefaultParams.FilterDescendantsInstances = {workspace.Map}
DefaultParams.FilterType = Enum.RaycastFilterType.Include
local function FindPartsInHitbox(Hitbox : BasePart, Params : OverlapParams): {VoxablePart | Voxel} --Used to get all the parts within a part.
	local results: {VoxablePart | Voxel} = {}
	local touching: {Part}
	if Params then
		touching = workspace:GetPartsInPart(Hitbox, Params)
	else
		touching = workspace:GetPartsInPart(Hitbox, DefaultParams)
	end

	for _, v in pairs(touching) do
		if v:IsA("Part") then
			if v:HasTag(TagName) then
				table.insert(results,v)
			end
		end
	end

	return results --Returns a table of all eligible parts touching the specified part
end

local function getLargestAxis(part : Part): number  --Returns Largest Axis of Part size
	return math.max(part.Size.X, part.Size.Y, part.Size.Z)
end

-- Module Methods
function VoxelService:CreateHitbox(Size : Vector3 | string, Cframe : CFrame, Shape : Enum.PartType|MeshPart , MinimumVoxelSize : number|string , TimeToReset : number, Params : OverlapParams)
	local hitboxPart: Part = Instance.new('Part')

	hitboxPart.Shape = Shape or Enum.PartType.Block
    hitboxPart.Size = Size or Vector3.one * 5
	hitboxPart.CFrame = Cframe or CFrame.new()
	hitboxPart.Anchored = true
	hitboxPart.CanCollide = false
	-- hitboxPart.CanQuery = false
	hitboxPart.Material = Enum.Material.Neon
	hitboxPart.Color = Color3.fromRGB(255, 0, 0)
	hitboxPart.Transparency = 0.6

	if Visualizer then
		hitboxPart.Parent = game.Workspace.UnobstructiveAssets
	else
		hitboxPart.Parent = ReplicatedStorage.HitboxStorage
	end
	
	task.delay(.2,function()
		hitboxPart:Destroy()
	end)

	local function HitboxCheck()
		local touchingParts = FindPartsInHitbox(hitboxPart)
		--print(touchingParts)
		
		local Parts: {Voxel | VoxablePart} = {}
		
		if true then
			local minimum
			if MinimumVoxelSize == "Relative" then
				-- local largest = getLargestAxis(hitboxPart)
				-- minimum = largest * Settings.RelativityRatio
			else
				minimum = MinimumVoxelSize
			end
			if touchingParts and #touchingParts > 0 then
				Parts = VoxelConstructor:ConstructVoxels(OctreesAlgorithm.DivideBlock(touchingParts,minimum,TimeToReset,hitboxPart))			
			end
		else
			local minimum
			if MinimumVoxelSize == "Relative" then
				-- local largest = getLargestAxis(hitboxPart)
				-- minimum = largest * Settings.RelativityRatio
				error('Relativity is not supported yet, goofy.')
			else
				minimum = MinimumVoxelSize
			end
			
	
			-- for i,v in touchingParts do
			--     if math.max(v.Size.X,v.Size.Y,v.Size.Z) == minimum then
			--         table.remove(touchingParts,i)
			--     end
			-- end
			
			if touchingParts and #touchingParts > 0 then
				--print('new partS!!')
				Parts = VoxelConstructor:ConstructVoxels(Algorithm.DivideBlock(touchingParts,minimum,TimeToReset,hitboxPart))		
			end
		end
		
		local voxels: {Voxel} = {}

		for i,v in touchingParts do
			if not v:HasTag("Voxel") then
				v.Transparency = 1
				v.CanCollide = false
			else
				if CheckIfPartIsGreaterThanMinimum(v,MinimumVoxelSize) then
					VoxelConstructor:ReturnPart(v)
				end
			end
		end
		
		local newTouching = FindPartsInHitbox(hitboxPart)
		for i,v in newTouching do
			if v:HasTag("Voxel") then
				table.insert(voxels, v)
				-- v:AddTag('UnanchoredVoxel')
			end
		end
		warn(#voxels)
		
		return voxels
	end

	return HitboxCheck()
end

function VoxelService:ReturnPart(Part:Part|{Part})
	if typeof(Part) == "Instance" then
		if VoxelConstructor:CheckIfPartIsInCache(Part) then
			VoxelConstructor:ReturnPart(Part)
			Part.Parent = VoxelConstructor.CacheFolder.ObjectCache
		else
			warn("Part is not in cache.")
		end	
	elseif typeof(Part) == "table" then
		for i,v in Part do
			VoxelConstructor:ReturnPart(v)
		end
	else
		warn("Must be a part or a table of parts.")	
	end
end

local groundRayParams = RaycastParams.new()
groundRayParams.FilterType = Enum.RaycastFilterType.Exclude
groundRayParams.FilterDescendantsInstances = {workspace.UnobstructiveAssets, workspace.Characters}

function VoxelService.SetupVoxel(voxel: Part, voxelDuration: number, destructionDuration: number, launchDirection: Vector3, groundAnchored: boolean?)
	-- v.Massless = true
	-- v.CustomPhysicalProperties = PhysicalProperties.new(2, .6, 1, 1, 1)
	voxel.CustomPhysicalProperties = PhysicalProperties.new(.7, .2, .5, .75, 1)
	if not voxel:GetAttribute('Frozen') and not groundAnchored then
		voxel.Anchored = false
	end
	if not voxel:GetAttribute('SizeDecreased') then
		voxel.Size -= Vector3.one * .1
		voxel:SetAttribute('SizeDecreased', true)
	end

	if launchDirection then
		voxel:ClearAllChildren()

		local bv = Instance.new('BodyVelocity')
		bv.MaxForce = Vector3.new(10000, 10000, 10000) 

		if typeof(launchDirection) == 'string' and string.split(launchDirection, '_')[1] == 'Explosion' then
			bv.Velocity = (voxel.Position - voxel:GetAttribute('HitboxCFrame').Position).Unit * tonumber(string.split(launchDirection, '_')[2])
		else
			bv.Velocity = launchDirection --+ Vector3.new(math.random(-2, 2),math.random(-2, 2),math.random(-2, 2))
		end

		bv.Parent = voxel
		game:GetService('Debris'):AddItem(bv, .3)
		-- task.delay(.3, function()
		-- 	if bv.Parent == voxel then
		-- 		bv:Destroy()
		-- 	end
		-- end)
	end

	-- TO PREVENT FLINGING. DO NOT REMOVE
	local curParent = voxel.Parent
	task.spawn(function()
		while curParent == voxel.Parent do
			if voxel.Anchored then
				voxel.AssemblyLinearVelocity = Vector3.zero
				voxel.AssemblyAngularVelocity = Vector3.zero 
			end
			RunService.Heartbeat:Wait()
		end
	end)

	task.spawn(function()
		task.wait(.15)
		if voxel:GetAttribute('Frozen') or groundAnchored then return end
		local timeout = os.clock()
		repeat 

			if voxel.AssemblyLinearVelocity.Magnitude == 0 or voxel:GetAttribute('HaltPhysics') then
				local groundRay = workspace:Raycast(voxel.Position, -Vector3.yAxis * (voxel.Size.Y+1), groundRayParams)

				if groundRay and groundRay.Instance or voxel:GetAttribute('HaltPhysics') then
					voxel.Anchored = true
				else
					voxel.Anchored = false
				end
			else
				voxel.Anchored = false
			end

			task.wait(.1)
		until os.clock() - timeout > voxelDuration - 1 or voxel:GetAttribute('Frozen')
		voxel.Anchored = true
	end)

	if destructionDuration then
		task.delay(voxelDuration, function()
			if not voxel:IsDescendantOf(workspace) then return end
			local fade = game:GetService('TweenService'):Create(voxel, TweenInfo.new(1), {Transparency = 1})
			fade:Play()
			fade.Completed:Wait()
			voxel.CanCollide = false
			voxel.Anchored = true
		end)
	end
end


return VoxelService