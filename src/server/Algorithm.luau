local Settings = require(script.Parent.Settings)

type VoxelInfo = {
	AlreadyExistsInWorkspace:boolean,
	Size:Vector3,
	CFrame:CFrame,
	CanCollide:boolean,
	Parent:Instance,
	Color:Color3,
	Material:Enum.Material,
	Anchored:boolean,
	Transparency:number,
	AlreadyDivided:boolean,
	ResetTime:number,
	OriginalPart:Instance
}

local NewDivision = {}

-- Checks if the box/BasePart is within the given voxel.
local function IsBoxWithinPart(data: Part, part: VoxelInfo): boolean
	local op = OverlapParams.new()
	op.FilterDescendantsInstances = {data}
	op.CollisionGroup = 'VoxelParts'
	op.FilterType = Enum.RaycastFilterType.Include
	return #workspace:GetPartBoundsInBox(part.CFrame, part.Size, op)>0
end

local function CheckForNewVoxelsInHitbox(Voxels: {VoxelInfo}, hitbox:BasePart): {VoxelInfo} -- Vector3,Instance
	local partsInHitbox: {VoxelInfo} = {}

	for i,v in Voxels do
		if IsBoxWithinPart(hitbox,v) then
			table.insert(partsInHitbox,v)
		end
	end
	return partsInHitbox
end

local function CheckForNewVoxelsNotInHitbox(Voxels: {VoxelInfo}, hitbox:BasePart): {VoxelInfo} -- Vector3,Instance
	local partsInHitbox: {VoxelInfo} = {}

	for i,v in Voxels do
		if not IsBoxWithinPart(hitbox,v) then
			table.insert(partsInHitbox,v)
		end
	end
	return partsInHitbox
end

local function partCanSubdivide(part : Part) --Checks if part is rectangular.
	local Threshold = 1.5

	local largest = math.max(part.Size.X, part.Size.Y, part.Size.Z) --Largest Axis
	local smallest = math.min(part.Size.X,part.Size.Y, part.Size.Z) -- Smallest Axis

	local smallestAxis: Vector3
	if smallest == part.Size.X then
		smallestAxis = 'X' 
		smallest = math.min(part.Size.Y, part.Size.Z)
	elseif smallest == part.Size.Y then
		smallestAxis = 'Y'
		smallest = math.min(part.Size.X, part.Size.Z)
	elseif smallest == part.Size.Z then
		smallestAxis = 'Z'
		smallest = math.min(part.Size.X, part.Size.Y)
	end

	return largest >= Threshold * smallest, smallestAxis
	--Returns true if part is rectangular. 
	--Part is rectangular if the largest axis is at least 1.5x bigger than the smallest axis
end
local function Voxelize(voxInfo: {VoxelInfo}, minimumVoxelSize: number, Hitbox: Part, TimeToReset: number)
	local voxelInfoTable: {VoxelInfo} = {} -- Table of parts to be returned
	local minimum: number = minimumVoxelSize or Settings.DefaultMinimumVoxelSize

	local inHitbox: {VoxelInfo}
	local NotInHitbox: {VoxelInfo}

    -- Checks which voxelinfo are within the hitbox.
	if Hitbox then
		inHitbox = CheckForNewVoxelsInHitbox(voxInfo,Hitbox)
		NotInHitbox = CheckForNewVoxelsNotInHitbox(voxInfo,Hitbox)
	else
		inHitbox = voxInfo
	end

	warn(inHitbox, NotInHitbox)

	for _, volume: VoxelInfo in inHitbox do
        local biggestAxis: number = math.max(volume.Size.X,volume.Size.Z,volume.Size.Y)
		local minimumRelativeToLargest: number = biggestAxis * 0.5

		local unit: number

        -- Checks if the minminumRelativeToLarget is smaller than the absolute minimum voxel size.
		if minimumRelativeToLargest < minimum then
			unit = minimum
		else
			unit = minimumRelativeToLargest
		end

		local left_lower_front_corner = -volume.Size / 2
		local first_block_pos = left_lower_front_corner + Vector3.new(unit / 2, unit / 2, unit / 2)

		local function roundUp(x, n)
			return n * math.ceil(x / n)
		end

		local size = Vector3.new(
			roundUp(volume.Size.X, unit),
			roundUp(volume.Size.Y, unit),
			roundUp(volume.Size.Z, unit)
		)

		for x = 0, size.X - unit, unit do
			for y = 0, size.Y - unit, unit do
				for z = 0, size.Z - unit, unit do
					local block_offset_objectspace = Vector3.new(x, y, z)
					local block_cframe = volume.CFrame * CFrame.new(first_block_pos + block_offset_objectspace)
					local new_block_size = Vector3.new(
						math.min(unit, volume.Size.X - x),
						math.min(unit, volume.Size.Y - y),
						math.min(unit, volume.Size.Z - z)
					)
					local adjusted_block_pos = block_offset_objectspace + (new_block_size / 2) - (Vector3.new(unit, unit, unit) / 2)
					local new_block_cframe = volume.CFrame * CFrame.new(first_block_pos + adjusted_block_pos)

					local function createPart()
						local info: VoxelInfo = {
							Size = new_block_size,
							CFrame = new_block_cframe,
							Parent = volume.Parent,
							CanCollide = volume.CanCollide,
							Transparency = volume.Transparency,
							Material = volume.Material,
							Anchored = volume.Anchored,
							Color = volume.Color,
							AlreadyExistsInWorkspace = false,
							AlreadyDivided = false,
							ResetTime = TimeToReset,
							OriginalPart = volume.OriginalPart
						}

						return info
					end

					table.insert(voxelInfoTable, createPart())
				end    
			end
		end
	end

	local sizeOutsideMinimumBounds = false
	for i, v in pairs(voxelInfoTable) do
		if math.floor(v.Size.X) > minimum or math.floor(v.Size.Y) > minimum or math.floor(v.Size.Z) > minimum then
			sizeOutsideMinimumBounds = true
		end
	end	

	if NotInHitbox then
		for i,v in NotInHitbox do
			table.insert(voxelInfoTable,v)
		end
	end

	if sizeOutsideMinimumBounds then
		for i,partInfo in pairs(voxelInfoTable) do
			if partInfo.AlreadyDivided then
				table.remove(voxelInfoTable, i)
			end
		end

		return Voxelize(voxelInfoTable,minimum,Hitbox,TimeToReset)
	else
		local function checkIfPartMeetsMinimum(Part:Part)
			if (Part.Size.X <= minimum and Part.Size.Y <= minimum and Part.Size.Z <= minimum) then
				return true
			end
		end

		local newVoxelInfoTable = CheckForNewVoxelsInHitbox(voxelInfoTable,Hitbox)
		for i,v in newVoxelInfoTable do
			local isCubic = checkIfPartMeetsMinimum(v)
			if isCubic ~= true and not Settings.IncludePartsBelowMinimum then
				
				-- if not isCubic then
				-- 	v.Size = Vector3.one * Settings.DefaultMinimumVoxelSize
				-- else
				-- 	local axixs = {'X', 'Y', 'Z'}
				-- 	table.remove(axixs, table.find(axixs, isCubic))
				-- 	v.Size = Vector3[string.lower(isCubic)..'Axis']
				-- 	for _,axis in axixs do
				-- 		v.Size += Vector3[string.lower(axis)..'Axis'] * Settings.DefaultMinimumVoxelSize
				-- 	end
				-- end
				-- -- table.remove(voxelInfoTable, table.find(voxelInfoTable, v))
			end
		end

		return voxelInfoTable --Returns resulting parts
	end
end


function NewDivision.DivideBlock(Parts: {Part}, Minimum:number|string, timeToReset:number, Hitbox:BasePart): {VoxelInfo}
	local voxelTable: {VoxelInfo} = {}

	local minimum = Minimum or Settings.DefaultMinimumVoxelSize

	for _, v in Parts do
		if v:HasTag(Settings.TagName) then
			v:RemoveTag(Settings.TagName)
		end

		local temp: VoxelInfo = {
			Parent = v.Parent,
			Size = v.Size,
			CFrame = v.CFrame,
			Material = v.Material,
			CanCollide = v.CanCollide,
			Transparency = v.Transparency,
			Color = v.Color,
			Anchored = v.Anchored,
			AlreadyDivided = true,
			AlreadyExistsInWorkspace = true,
			ResetTime = timeToReset,
			OriginalPart = v,
		}

		table.insert(voxelTable,temp)
	end

	return Voxelize(voxelTable,minimum,Hitbox,timeToReset)
end

return NewDivision