local NewDivision = {}


local Types = require(script.Parent:WaitForChild("Types"))
local Settings = require(script.Parent:WaitForChild("Settings"))
local Constructor = require(script.Parent:WaitForChild("PartConstructor"))


function IsBoxWithinPart(data:BasePart, part:Types.VoxelInfo)
	local partPosition = part.CFrame.Position
	local partSize = part.Size
	local halfPartSize = partSize / 2

	local dataMin = data.CFrame.Position - (data.Size / 2)
	local dataMax = data.CFrame.Position + (data.Size / 2)

	local partMin = partPosition - halfPartSize
	local partMax = partPosition + halfPartSize

	return dataMin.X <= partMax.X and dataMax.X >= partMin.X and
		dataMin.Y <= partMax.Y and dataMax.Y >= partMin.Y and
		dataMin.Z <= partMax.Z and dataMax.Z >= partMin.Z
end




local function CheckForNewVoxelsInHitbox(Voxels:Types.VoxelInfoTable, hitbox:BasePart) -- Vector3,Instance
	local partsInHitbox:Types.VoxelInfoTable = {}
	for i,v in Voxels do
		if IsBoxWithinPart(hitbox,v) then
			table.insert(partsInHitbox,v)
		end
	end
	return partsInHitbox
end
local function CheckForNewVoxelsNotInHitbox(Voxels:Types.VoxelInfoTable, hitbox:BasePart) -- Vector3,Instance
	local partsInHitbox:Types.VoxelInfoTable = {}
	for i,v in Voxels do
		if not IsBoxWithinPart(hitbox,v) then
			table.insert(partsInHitbox,v)
		end
	end
	return partsInHitbox
end



function voxelize(voxInfo: Types.VoxelInfoTable, minimumVoxelSize: number,Hitbox,TimeToReset)

	local partTable:Types.VoxelInfoTable = {} -- Table of parts to be returned
	local minimum = minimumVoxelSize or Settings.DefaultMinimumVoxelSize
	local inHitbox
	local NotInHitbox

	if Hitbox then
		inHitbox = CheckForNewVoxelsInHitbox(voxInfo,Hitbox)
		NotInHitbox = CheckForNewVoxelsNotInHitbox(voxInfo,Hitbox)
	else
		inHitbox = voxInfo
	end

	for i,volume in inHitbox do

		local minimumRelativeToLargest = math.max(volume.Size.X,volume.Size.Z,volume.Size.Y)/2

		local unit = minimumRelativeToLargest


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
						local info:Types.VoxelInfo = {
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



					table.insert(partTable, createPart() )


				end    
			end
		end
	end


	local check = false
	for i, v in pairs(partTable) do
		if math.floor(v.Size.X) > minimum or math.floor(v.Size.Y) > minimum or math.floor(v.Size.Z) > minimum then
			check = true
		end
	end	

	if NotInHitbox then
		for i,v in NotInHitbox do
			table.insert(partTable,v)
		end
	end
	if check == true then
		for i,partInfo in pairs(partTable) do
			if partInfo.AlreadyDivided then
				table.remove(partTable,i)
			end
		end
		return voxelize(partTable,minimum,Hitbox,TimeToReset)
	else	

		local function checkIfPartMeetsMinimum(Part:Part)
			if (Part.Size.X == minimum and Part.Size.Y == minimum and Part.Size.Z == minimum)  then
				return true
			end
			return false
		end


		local new = CheckForNewVoxelsInHitbox(partTable,Hitbox)
		for i,v in new do
			if not checkIfPartMeetsMinimum(v) and Settings.IncludePartsBelowMinimum == false then
				table.remove(partTable,table.find(partTable,v))
			end
		end

		return partTable --Returns resulting parts
	end
end


function NewDivision.DivideBlock(Parts:Types.PartTable,Minimum:number|string,timeToReset:number,Hitbox:BasePart):Types.VoxelInfoTable
	local voxelTable:Types.VoxelInfoTable = {}

	local minimum = Minimum or Settings.DefaultMinimumVoxelSize


	for i,v in Parts do
		if v:HasTag(Settings.TagName) then
			v:RemoveTag(Settings.TagName)


		end

		local temp:Types.VoxelInfo = {
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



	return voxelize(voxelTable,minimum,Hitbox,timeToReset)
end

return NewDivision
