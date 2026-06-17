local OctreeDivision = {}


local Types = require(script.Parent:WaitForChild("Types"))
local Settings = require(script.Parent:WaitForChild("Settings"))
local Constructor = require(script.Parent:WaitForChild("PartConstructor"))


local function partCanSubdivide(part : Part) --Checks if part is rectangular.

	local Threshold = 1.5  -- How much of a difference there can be between the largest axis and the smallest axis 

	local largest = math.max(part.Size.X, part.Size.Y, part.Size.Z) --Largest Axis
	local smallest = math.min(part.Size.X,part.Size.Y, part.Size.Z) -- Smallest Axis

	if smallest == part.Size.X then 
		smallest = math.min(part.Size.Y, part.Size.Z)
	elseif smallest == part.Size.Y then
		smallest = math.min(part.Size.X, part.Size.Z)
	elseif smallest == part.Size.Z then
		smallest = math.min(part.Size.X, part.Size.Y)
	end

	return largest >= Threshold * smallest 
	--Returns true if part is rectangular. 
	--Part is rectangular if the largest axis is at least 1.5x bigger than the smallest axis
end



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

local function getLargestAxis(part : Part)  --Returns Largest Axis of Part size
	return math.max(part.Size.X, part.Size.Y, part.Size.Z)
end

local function CutPartinHalf(block : Types.VoxelInfo, TimeToReset : number) --Cuts part into two evenly shaped pieces.
	local partTable:Types.VoxelInfoTable = {} --Table of parts to be returned
	local bipolarVectorSet = {} --Offset on where to place halves
		
	
	
	local X = block.Size.X
	local Y = block.Size.Y
	local Z = block.Size.Z

	if getLargestAxis(block) == X then --Changes offset vectors depending on what the largest axis is.
		X /= 2

		bipolarVectorSet = {
			Vector3.new(1,0,0),
			Vector3.new(-1,0,0),
		}

	elseif getLargestAxis(block) == Y then 
		Y/=2

		bipolarVectorSet = {
			Vector3.new(0,1,0),
			Vector3.new(0,-1,0),
		}

	elseif getLargestAxis(block) == Z then
		Z/=2

		bipolarVectorSet = {
			Vector3.new(0,0,1),
			Vector3.new(0,0,-1),
		}

	end




	local halfSize = Vector3.new(X,Y,Z)

	for _, offsetVector in pairs(bipolarVectorSet) do
		local info:Types.VoxelInfo = {
			Size = halfSize,
			CFrame = block.CFrame + block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
			Parent = block.Parent,
			CanCollide = block.CanCollide,
			Transparency = block.Transparency,
			Material = block.Material,
			Anchored = block.Anchored,
			Color = block.Color,
			AlreadyExistsInWorkspace = false,
			AlreadyDivided = false,
			ResetTime = TimeToReset,
			OriginalPart = block.OriginalPart
		}

		table.insert(partTable,info)
		
	end

	return partTable -- Returns a table containing the two halves
end

local function DivideBlock(voxInfo : Types.VoxelInfoTable, MinimumVoxelSize : number, TimeToReset : number, Hitbox:BasePart) --Divides part into evenly shaped cubes.
	--MinimumvVoxelSize Parameter is used to describe the minimum possible size that the parts can be divided. To avoid confusion, this is not the size that the parts will be divided into, but rather the minimum allowed
	--You CANNOT change the size of the resulting parts. They are dependent on the size of the original part.

	--if Hitbox == nil then
	--	return voxInfo	
	--end
	


	
	local partTable:Types.VoxelInfoTable = {} -- Table of parts to be returned
	local minimum = MinimumVoxelSize or Settings.DefaultMinimumVoxelSize
	
	local inHitbox
	local NotInHitbox
	
	if Hitbox then
		inHitbox = CheckForNewVoxelsInHitbox(voxInfo,Hitbox)
		NotInHitbox = CheckForNewVoxelsNotInHitbox(voxInfo,Hitbox)
	else
		inHitbox = voxInfo
		--NotInHitbox = voxInfo
	end
	
	 

	
	for i,block in inHitbox do
		if (block.Size.X > minimum or block.Size.Y > minimum or block.Size.Z > minimum) then
			if partCanSubdivide(block) then --If part is rectangular then it is cut in half, otherwise it is divided into cubes.
				partTable = CutPartinHalf(block,TimeToReset)
			else
				local Threshold = 1.5  -- How much of a difference there can be between the largest axis and the smallest axis 

				local largest = math.max(block.Size.X, block.Size.Y, block.Size.Z) --Largest Axis
				local smallest = math.min(block.Size.X,block.Size.Y, block.Size.Z) -- Smallest Axis




				if smallest == block.Size.Y and smallest * Threshold <= largest then







					local bipolarVectorSet = {}

					local X = block.Size.X
					local Y = block.Size.Y
					local Z = block.Size.Z

					X /= 2
					Z /= 2
					bipolarVectorSet = { --Offset Vectors
						Vector3.new(-1,0,1),
						Vector3.new(1,0,-1),
						Vector3.new(1,0,1),
						Vector3.new(-1,0,-1),

					}


					local halfSize = Vector3.new(X,Y,Z)



					for _, offsetVector in pairs(bipolarVectorSet) do
						local info:Types.VoxelInfo = {
							Size = halfSize,
							CFrame = block.CFrame + block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
							Parent = block.Parent,
							CanCollide = block.CanCollide,
							Transparency = block.Transparency,
							Material = block.Material,
							Anchored = block.Anchored,
							Color = block.Color,
							AlreadyExistsInWorkspace = false,
							AlreadyDivided = false,
							ResetTime = TimeToReset,
							OriginalPart = block.OriginalPart
						}
						table.insert(partTable,info)
					end




				elseif smallest == block.Size.X and smallest * Threshold <= largest then







					local bipolarVectorSet = {}

					local X = block.Size.X
					local Y = block.Size.Y
					local Z = block.Size.Z

					Y /= 2
					Z /= 2
					bipolarVectorSet = { --Offset Vectors
						Vector3.new(0,-1,1),
						Vector3.new(0,1,1),
						Vector3.new(0,-1,-1),
						Vector3.new(0,1,-1),

					}


					local halfSize = Vector3.new(X,Y,Z)



					for _, offsetVector in pairs(bipolarVectorSet) do
						local info:Types.VoxelInfo = {
							Size = halfSize,
							CFrame = block.CFrame + block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
							Parent = block.Parent,
							CanCollide = block.CanCollide,
							Transparency = block.Transparency,
							Material = block.Material,
							Anchored = block.Anchored,
							Color = block.Color,
							AlreadyExistsInWorkspace = false,
							AlreadyDivided = false,
							ResetTime = TimeToReset,
							OriginalPart = block.OriginalPart
						}
						table.insert(partTable,info)
					end 
				elseif smallest == block.Size.Z and smallest * Threshold <= largest then








					local bipolarVectorSet = {}

					local X = block.Size.X
					local Y = block.Size.Y
					local Z = block.Size.Z

					X /= 2
					Y /= 2
					bipolarVectorSet = { --Offset Vectors
						Vector3.new(1,-1,0),
						Vector3.new(1,1,0),
						Vector3.new(-1,-1,0),
						Vector3.new(-1,1,0),

					}


					local halfSize = Vector3.new(X,Y,Z)



					for _, offsetVector in pairs(bipolarVectorSet) do
						local info:Types.VoxelInfo = {
							Size = halfSize,
							CFrame = block.CFrame + block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
							Parent = block.Parent,
							CanCollide = block.CanCollide,
							Transparency = block.Transparency,
							Material = block.Material,
							Anchored = block.Anchored,
							Color = block.Color,
							AlreadyExistsInWorkspace = false,
							AlreadyDivided = false,
							ResetTime = TimeToReset,
							OriginalPart = block.OriginalPart
						}
						table.insert(partTable,info)
					end





				else




					local bipolarVectorSet = { --Offset Vectors
						Vector3.new(1,1,1),
						Vector3.new(1,1,-1),
						Vector3.new(1,-1,1),
						Vector3.new(1,-1,-1),
						Vector3.new(-1,1,1),
						Vector3.new(-1,1,-1),
						Vector3.new(-1,-1,1),
						Vector3.new(-1,-1,-1),
					}

					local halfSize = block.Size / 2.0

					for _, offsetVector in pairs(bipolarVectorSet) do
						local info:Types.VoxelInfo = {
							Size = halfSize,
							CFrame = block.CFrame + block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
							Parent = block.Parent,
							CanCollide = block.CanCollide,
							Transparency = block.Transparency,
							Material = block.Material,
							Anchored = block.Anchored,
							Color = block.Color,
							AlreadyExistsInWorkspace = false,
							AlreadyDivided = false,
							ResetTime = TimeToReset,
							OriginalPart = block.OriginalPart
						}
						table.insert(partTable,info)
					end




				end
			end
		else
			table.insert(partTable,block)
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
		return DivideBlock(partTable,MinimumVoxelSize,TimeToReset,Hitbox)
	else	
		return partTable --Returns resulting parts
	end
end



function OctreeDivision.DivideBlock(Parts:Types.PartTable,Minimum:number|string,timeToReset:number,Hitbox:BasePart):Types.VoxelInfoTable
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
	


	return DivideBlock(voxelTable,minimum,timeToReset,Hitbox)
end

return OctreeDivision
