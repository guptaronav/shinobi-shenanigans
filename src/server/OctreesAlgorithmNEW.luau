local OctreeDivision = {}

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


local Settings = require(script.Parent:WaitForChild("Settings"))

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

function getCorners(part: VoxelInfo) --by post
	local cf = part.CFrame
	local size = part.Size
	local corners = {}

	local frontFaceCenter = (cf + cf.LookVector * size.Z/2)
	local backFaceCenter = (cf - cf.LookVector * size.Z/2)
	local topFrontEdgeCenter = frontFaceCenter + frontFaceCenter.UpVector * size.Y/2
	local bottomFrontEdgeCenter = frontFaceCenter - frontFaceCenter.UpVector * size.Y/2
	local topBackEdgeCenter = backFaceCenter + backFaceCenter.UpVector * size.Y/2
	local bottomBackEdgeCenter = backFaceCenter - backFaceCenter.UpVector * size.Y/2

	corners.topFrontRight = (topFrontEdgeCenter + topFrontEdgeCenter.RightVector * size.X/2).Position
	corners.topFrontLeft = (topFrontEdgeCenter - topFrontEdgeCenter.RightVector * size.X/2).Position

	corners.bottomFrontRight = (bottomFrontEdgeCenter + bottomFrontEdgeCenter.RightVector * size.X/2).Position
	corners.bottomFrontLeft = (bottomFrontEdgeCenter - bottomFrontEdgeCenter.RightVector * size.X/2).Position

	corners.topBackRight = (topBackEdgeCenter + topBackEdgeCenter.RightVector * size.X/2).Position
	corners.topBackLeft = (topBackEdgeCenter - topBackEdgeCenter.RightVector * size.X/2).Position

	corners.bottomBackRight = (bottomBackEdgeCenter + bottomBackEdgeCenter.RightVector * size.X/2).Position
	corners.bottomBackLeft = (bottomBackEdgeCenter - bottomBackEdgeCenter.RightVector * size.X/2).Position
	return corners
end

-- local function IsBoxWithinPart(data: Part, part: VoxelInfo)
--     local partCorners = getCorners(part)
--     local hitboxCorners = getCorners(data)

--     return (partCorners.bottomBackLeft - data.CFrame.Position).Magnitude <= (hitboxCorners.bottomBackLeft - data.CFrame.Position).Magnitude
--     and (partCorners.bottomBackRight - data.CFrame.Position).Magnitude <= (hitboxCorners.bottomBackRight - data.CFrame.Position).Magnitude
--     and (partCorners.bottomFrontLeft - data.CFrame.Position).Magnitude <= (hitboxCorners.bottomFrontLeft - data.CFrame.Position).Magnitude
--     and (partCorners.bottomFrontRight - data.CFrame.Position).Magnitude <= (hitboxCorners.bottomFrontRight - data.CFrame.Position).Magnitude
    
--     and (partCorners.topBackLeft - data.CFrame.Position).Magnitude <= (hitboxCorners.topBackLeft - data.CFrame.Position).Magnitude
--     and (partCorners.topBackRight - data.CFrame.Position).Magnitude <= (hitboxCorners.topBackRight - data.CFrame.Position).Magnitude
--     and (partCorners.topFrontLeft - data.CFrame.Position).Magnitude <= (hitboxCorners.topFrontLeft - data.CFrame.Position).Magnitude
--     and (partCorners.topFrontRight - data.CFrame.Position).Magnitude <= (hitboxCorners.topFrontRight - data.CFrame.Position).Magnitude
-- end

-- local function IsBoxWithinPart(data: Part, part: VoxelInfo)
--     local op = OverlapParams.new()
--     op.FilterDescendantsInstances = {data}
--     op.FilterType = Enum.RaycastFilterType.Include
--     return #workspace:GetPartBoundsInBox(part.CFrame, part.Size, op) > 0
-- end

-- Checks if the box/BasePart is within the given voxel.
local function IsBoxWithinPart(data: Part, part: VoxelInfo): boolean
	local op = OverlapParams.new()
	op.FilterDescendantsInstances = {data}
	op.CollisionGroup = 'VoxelParts'
	op.FilterType = Enum.RaycastFilterType.Include
	return #workspace:GetPartBoundsInBox(part.CFrame, part.Size, op)>0
end

local function CheckForNewVoxelsInHitbox(Voxels: {VoxelInfo}, hitbox:BasePart) -- Vector3,Instance
	local partsInHitbox: {VoxelInfo} = {}
	for i,v in Voxels do
		if IsBoxWithinPart(hitbox,v) then
            -- warn('It is within!!', v)
			table.insert(partsInHitbox,v)
		end
	end
	return partsInHitbox
end
local function CheckForNewVoxelsNotInHitbox(Voxels: {VoxelInfo}, hitbox:BasePart) -- Vector3,Instance
	local partsInHitbox: {VoxelInfo} = {}
	for i,v in Voxels do
		if not IsBoxWithinPart(hitbox,v) then
            -- warn('it is not within!!!', v)
			table.insert(partsInHitbox,v)
		end
	end
	return partsInHitbox
end

local function getLargestAxis(part : Part)  --Returns Largest Axis of Part size
	return math.max(part.Size.X, part.Size.Y, part.Size.Z)
end

local function CutPartinHalf(block : {VoxelInfo}, TimeToReset : number) --Cuts part into two evenly shaped pieces.
	local partTable: {VoxelInfo} = {} --Table of parts to be returned
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
		local info: VoxelInfo = {
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



local function DivideBlock(voxInfo : {VoxelInfo}, MinimumVoxelSize : number, TimeToReset : number, Hitbox:BasePart) --Divides part into evenly shaped cubes.
	--MinimumvVoxelSize Parameter is used to describe the minimum possible size that the parts can be divided. To avoid confusion, this is not the size that the parts will be divided into, but rather the minimum allowed
	--You CANNOT change the size of the resulting parts. They are dependent on the size of the original part.

	local partTable: {VoxelInfo} = {} -- Table of parts to be returned
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
	
	warn(inHitbox, NotInHitbox)
	
	for i,block in inHitbox do
		if (block.Size.X > minimum or block.Size.Y > minimum or block.Size.Z > minimum) then
			if partCanSubdivide(block) then --If part is rectangular then it is cut in half, otherwise it is divided into cubes.
				for _,v in CutPartinHalf(block,TimeToReset) do
                    table.insert(partTable, v)
                end
			else
				local Threshold = 1  -- How much of a difference there can be between the largest axis and the smallest axis 

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
						local info: VoxelInfo = {
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
						local info: VoxelInfo = {
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
						local info: VoxelInfo= {
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
						local info: VoxelInfo = {
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

function OctreeDivision.DivideBlock(Parts: {Part},Minimum:number|string,timeToReset:number,Hitbox:BasePart): {VoxelInfo}
	local voxelTable: {VoxelInfo} = {}
	
	local minimum = Minimum or Settings.DefaultMinimumVoxelSize

	for i,v in Parts do
		if v:HasTag(Settings.TagName) then
			v:RemoveTag(Settings.TagName)
		end
		
		local temp: {VoxelInfo} = {
			Parent = v.Parent,
			Size = v.Size,
			CFrame = v.CFrame,
			Material = v.Material,
			CanCollide = v.CanCollide,
			Transparency = v.Transparency,
			Color = v.Color,
			Anchored = v.Anchored,
			AlreadyDivided = true, -- TRUE
			AlreadyExistsInWorkspace = true,
			ResetTime = timeToReset,
			OriginalPart = v,
		}
		table.insert(voxelTable,temp)
	end
	


	return DivideBlock(voxelTable,minimum,timeToReset,Hitbox)
end

return OctreeDivision


-- local function DivideBlock(voxels: {VoxelInfo}, MinimumVoxelSize: number, TimeToReset: number, Hitbox: Part)
-- --     local generatedVoxels: {VoxelInfo} = {}
-- --     local minimum = MinimumVoxelSize or Settings.DefaultMinimumVoxelSize

-- --     local inHitbox = CheckForNewVoxelsInHitbox(voxels, Hitbox)
-- --     local notInHitbox = CheckForNewVoxelsNotInHitbox(voxels, Hitbox)

-- --     for _, voxel in voxels do
-- --         local newSubdivisions: {VoxelInfo} = {}
-- --         local currentSubdivisions: {VoxelInfo} = {voxel}

-- --         local function Subdivide()
-- --             newSubdivisions = {}

-- --             for _, currentSubdivision in currentSubdivisions do
                
-- --                 if (currentSubdivision.Size.X > minimum or currentSubdivision.Size.Y > minimum or currentSubdivision.Size.Z > minimum) then
-- --                     if partCanSubdivide(currentSubdivision) then --If part is rectangular then it is cut in half, otherwise it is divided into cubes.
-- --                         table.insert(newSubdivisions, CutPartinHalf(currentSubdivision,TimeToReset))
-- --                     else
-- --                         local Threshold = 1.5  -- How much of a difference there can be between the largest axis and the smallest axis 
        
-- --                         local largest = math.max(currentSubdivision.Size.X, currentSubdivision.Size.Y, currentSubdivision.Size.Z) --Largest Axis
-- --                         local smallest = math.min(currentSubdivision.Size.X,currentSubdivision.Size.Y, currentSubdivision.Size.Z) -- Smallest Axis
        
-- --                         if smallest == currentSubdivision.Size.Y and smallest * Threshold <= largest then
-- --                             local bipolarVectorSet = {}
        
-- --                             local X = currentSubdivision.Size.X
-- --                             local Y = currentSubdivision.Size.Y
-- --                             local Z = currentSubdivision.Size.Z
        
-- --                             X /= 2
-- --                             Z /= 2
-- --                             bipolarVectorSet = { --Offset Vectors
-- --                                 Vector3.new(-1,0,1),
-- --                                 Vector3.new(1,0,-1),
-- --                                 Vector3.new(1,0,1),
-- --                                 Vector3.new(-1,0,-1),
        
-- --                             }
        
-- --                             local halfSize = Vector3.new(X,Y,Z)
        
-- --                             for _, offsetVector in pairs(bipolarVectorSet) do
-- --                                 local info: VoxelInfo = {
-- --                                     Size = halfSize,
-- --                                     CFrame = currentSubdivision.CFrame + currentSubdivision.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
-- --                                     Parent = currentSubdivision.Parent,
-- --                                     CanCollide = currentSubdivision.CanCollide,
-- --                                     Transparency = currentSubdivision.Transparency,
-- --                                     Material = currentSubdivision.Material,
-- --                                     Anchored = currentSubdivision.Anchored,
-- --                                     Color = currentSubdivision.Color,
-- --                                     AlreadyExistsInWorkspace = false,
-- --                                     AlreadyDivided = false,
-- --                                     ResetTime = TimeToReset,
-- --                                     OriginalPart = currentSubdivision.OriginalPart
-- --                                 }
-- --                                 table.insert(newSubdivisions, info)
-- --                             end
-- --                         elseif smallest == currentSubdivision.Size.X and smallest * Threshold <= largest then
-- --                             local bipolarVectorSet = {}
        
-- --                             local X = currentSubdivision.Size.X
-- --                             local Y = currentSubdivision.Size.Y
-- --                             local Z = currentSubdivision.Size.Z
        
-- --                             Y /= 2
-- --                             Z /= 2
-- --                             bipolarVectorSet = { --Offset Vectors
-- --                                 Vector3.new(0,-1,1),
-- --                                 Vector3.new(0,1,1),
-- --                                 Vector3.new(0,-1,-1),
-- --                                 Vector3.new(0,1,-1),
        
-- --                             }
        
-- --                             local halfSize = Vector3.new(X,Y,Z)
        
-- --                             for _, offsetVector in pairs(bipolarVectorSet) do
-- --                                 local info: VoxelInfo = {
-- --                                     Size = halfSize,
-- --                                     CFrame = currentSubdivision.CFrame + currentSubdivision.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
-- --                                     Parent = currentSubdivision.Parent,
-- --                                     CanCollide = currentSubdivision.CanCollide,
-- --                                     Transparency = currentSubdivision.Transparency,
-- --                                     Material = currentSubdivision.Material,
-- --                                     Anchored = currentSubdivision.Anchored,
-- --                                     Color = currentSubdivision.Color,
-- --                                     AlreadyExistsInWorkspace = false,
-- --                                     AlreadyDivided = false,
-- --                                     ResetTime = TimeToReset,
-- --                                     OriginalPart = currentSubdivision.OriginalPart
-- --                                 }
-- --                                 table.insert(newSubdivisions,info)
-- --                             end 
-- --                         elseif smallest == currentSubdivision.Size.Z and smallest * Threshold <= largest then
-- --                             local bipolarVectorSet = {}
        
-- --                             local X = currentSubdivision.Size.X
-- --                             local Y = currentSubdivision.Size.Y
-- --                             local Z = currentSubdivision.Size.Z
        
-- --                             X /= 2
-- --                             Y /= 2
-- --                             bipolarVectorSet = { --Offset Vectors
-- --                                 Vector3.new(1,-1,0),
-- --                                 Vector3.new(1,1,0),
-- --                                 Vector3.new(-1,-1,0),
-- --                                 Vector3.new(-1,1,0),
        
-- --                             }
        
-- --                             local halfSize = Vector3.new(X,Y,Z)
        
-- --                             for _, offsetVector in pairs(bipolarVectorSet) do
-- --                                 local info: VoxelInfo = {
-- --                                     Size = halfSize,
-- --                                     CFrame = currentSubdivision.CFrame + currentSubdivision.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
-- --                                     Parent = currentSubdivision.Parent,
-- --                                     CanCollide = currentSubdivision.CanCollide,
-- --                                     Transparency = currentSubdivision.Transparency,
-- --                                     Material = currentSubdivision.Material,
-- --                                     Anchored = currentSubdivision.Anchored,
-- --                                     Color = currentSubdivision.Color,
-- --                                     AlreadyExistsInWorkspace = false,
-- --                                     AlreadyDivided = false,
-- --                                     ResetTime = TimeToReset,
-- --                                     OriginalPart = currentSubdivision.OriginalPart
-- --                                 }
-- --                                 table.insert(newSubdivisions,info)
-- --                             end
-- --                         else
-- --                             local bipolarVectorSet = { --Offset Vectors
-- --                                 Vector3.new(1,1,1),
-- --                                 Vector3.new(1,1,-1),
-- --                                 Vector3.new(1,-1,1),
-- --                                 Vector3.new(1,-1,-1),
-- --                                 Vector3.new(-1,1,1),
-- --                                 Vector3.new(-1,1,-1),
-- --                                 Vector3.new(-1,-1,1),
-- --                                 Vector3.new(-1,-1,-1),
-- --                             }
        
-- --                             local halfSize = currentSubdivision.Size / 2.0
        
-- --                             for _, offsetVector in pairs(bipolarVectorSet) do
-- --                                 local info: VoxelInfo = {
-- --                                     Size = halfSize,
-- --                                     CFrame = currentSubdivision.CFrame + currentSubdivision.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
-- --                                     Parent = currentSubdivision.Parent,
-- --                                     CanCollide = currentSubdivision.CanCollide,
-- --                                     Transparency = currentSubdivision.Transparency,
-- --                                     Material = currentSubdivision.Material,
-- --                                     Anchored = currentSubdivision.Anchored,
-- --                                     Color = currentSubdivision.Color,
-- --                                     AlreadyExistsInWorkspace = false,
-- --                                     AlreadyDivided = false,
-- --                                     ResetTime = TimeToReset,
-- --                                     OriginalPart = currentSubdivision.OriginalPart
-- --                                 }
-- --                                 table.insert(newSubdivisions,info)
-- --                             end
-- --                         end
                        
-- --                     end
-- --                 elseif table.find(inHitbox, currentSubdivision) then
-- --                     table.insert(generatedVoxels, currentSubdivision)
-- --                 end
-- --             end

-- --             currentSubdivisions = workspace:GetPartBoundsInBox()
-- --             Subdivide()
-- --         end
-- --         Subdivide()
-- --     end

-- --     return generatedVoxels
-- -- end

-- local function DivideBlockOld(voxInfo : {VoxelInfo}, MinimumVoxelSize : number, TimeToReset : number, Hitbox:BasePart) --Divides part into evenly shaped cubes.
-- 	--MinimumvVoxelSize Parameter is used to describe the minimum possible size that the parts can be divided. To avoid confusion, this is not the size that the parts will be divided into, but rather the minimum allowed
-- 	--You CANNOT change the size of the resulting parts. They are dependent on the size of the original part.
	
-- 	local partTable: {VoxelInfo} = {} -- Table of parts to be returned
-- 	local minimum = MinimumVoxelSize or Settings.DefaultMinimumVoxelSize
	
-- 	local inHitbox
-- 	local NotInHitbox
	
-- 	inHitbox = CheckForNewVoxelsInHitbox(voxInfo,Hitbox)
-- 	NotInHitbox = CheckForNewVoxelsNotInHitbox(voxInfo,Hitbox)
	
--     warn('Blocks to check and divide', voxInfo, inHitbox, NotInHitbox)
    
--     if #inHitbox == 0 then
--         local exhaust = os.clock()
--         while #inHitbox == 0 do
--             if os.clock() - exhaust > .1 then break end

--             for i,block in NotInHitbox do
--                 if (block.Size.X > minimum or block.Size.Y > minimum or block.Size.Z > minimum) then
--                     if partCanSubdivide(block) then --If part is rectangular then it is cut in half, otherwise it is divided into cubes.
--                         partTable = CutPartinHalf(block,TimeToReset)
--                     else
--                         local Threshold = 1.5  -- How much of a difference there can be between the largest axis and the smallest axis 
        
--                         local largest = math.max(block.Size.X, block.Size.Y, block.Size.Z) --Largest Axis
--                         local smallest = math.min(block.Size.X,block.Size.Y, block.Size.Z) -- Smallest Axis
        
--                         if smallest == block.Size.Y and smallest * Threshold <= largest then
--                             local bipolarVectorSet = {}
        
--                             local X = block.Size.X
--                             local Y = block.Size.Y
--                             local Z = block.Size.Z
        
--                             X /= 2
--                             Z /= 2
--                             bipolarVectorSet = { --Offset Vectors
--                                 Vector3.new(-1,0,1),
--                                 Vector3.new(1,0,-1),
--                                 Vector3.new(1,0,1),
--                                 Vector3.new(-1,0,-1),
        
--                             }
        
--                             local halfSize = Vector3.new(X,Y,Z)
        
--                             for _, offsetVector in pairs(bipolarVectorSet) do
--                                 local info: VoxelInfo = {
--                                     Size = halfSize,
--                                     CFrame = block.CFrame + block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
--                                     Parent = block.Parent,
--                                     CanCollide = block.CanCollide,
--                                     Transparency = block.Transparency,
--                                     Material = block.Material,
--                                     Anchored = block.Anchored,
--                                     Color = block.Color,
--                                     AlreadyExistsInWorkspace = false,
--                                     AlreadyDivided = false,
--                                     ResetTime = TimeToReset,
--                                     OriginalPart = block.OriginalPart
--                                 }
--                                 table.insert(partTable,info)
--                             end
--                         elseif smallest == block.Size.X and smallest * Threshold <= largest then
--                             local bipolarVectorSet = {}
        
--                             local X = block.Size.X
--                             local Y = block.Size.Y
--                             local Z = block.Size.Z
        
--                             Y /= 2
--                             Z /= 2
--                             bipolarVectorSet = { --Offset Vectors
--                                 Vector3.new(0,-1,1),
--                                 Vector3.new(0,1,1),
--                                 Vector3.new(0,-1,-1),
--                                 Vector3.new(0,1,-1),
        
--                             }
        
--                             local halfSize = Vector3.new(X,Y,Z)
        
--                             for _, offsetVector in pairs(bipolarVectorSet) do
--                                 local info: VoxelInfo = {
--                                     Size = halfSize,
--                                     CFrame = block.CFrame + block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
--                                     Parent = block.Parent,
--                                     CanCollide = block.CanCollide,
--                                     Transparency = block.Transparency,
--                                     Material = block.Material,
--                                     Anchored = block.Anchored,
--                                     Color = block.Color,
--                                     AlreadyExistsInWorkspace = false,
--                                     AlreadyDivided = false,
--                                     ResetTime = TimeToReset,
--                                     OriginalPart = block.OriginalPart
--                                 }
--                                 table.insert(partTable,info)
--                             end 
--                         elseif smallest == block.Size.Z and smallest * Threshold <= largest then
--                             local bipolarVectorSet = {}
        
--                             local X = block.Size.X
--                             local Y = block.Size.Y
--                             local Z = block.Size.Z
        
--                             X /= 2
--                             Y /= 2
--                             bipolarVectorSet = { --Offset Vectors
--                                 Vector3.new(1,-1,0),
--                                 Vector3.new(1,1,0),
--                                 Vector3.new(-1,-1,0),
--                                 Vector3.new(-1,1,0),
        
--                             }
        
--                             local halfSize = Vector3.new(X,Y,Z)
        
--                             for _, offsetVector in pairs(bipolarVectorSet) do
--                                 local info: VoxelInfo = {
--                                     Size = halfSize,
--                                     CFrame = block.CFrame + block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
--                                     Parent = block.Parent,
--                                     CanCollide = block.CanCollide,
--                                     Transparency = block.Transparency,
--                                     Material = block.Material,
--                                     Anchored = block.Anchored,
--                                     Color = block.Color,
--                                     AlreadyExistsInWorkspace = false,
--                                     AlreadyDivided = false,
--                                     ResetTime = TimeToReset,
--                                     OriginalPart = block.OriginalPart
--                                 }
--                                 table.insert(partTable,info)
--                             end
--                         else
--                             local bipolarVectorSet = { --Offset Vectors
--                                 Vector3.new(1,1,1),
--                                 Vector3.new(1,1,-1),
--                                 Vector3.new(1,-1,1),
--                                 Vector3.new(1,-1,-1),
--                                 Vector3.new(-1,1,1),
--                                 Vector3.new(-1,1,-1),
--                                 Vector3.new(-1,-1,1),
--                                 Vector3.new(-1,-1,-1),
--                             }
        
--                             local halfSize = block.Size / 2.0
        
--                             for _, offsetVector in pairs(bipolarVectorSet) do
--                                 local info: VoxelInfo = {
--                                     Size = halfSize,
--                                     CFrame = block.CFrame + block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
--                                     Parent = block.Parent,
--                                     CanCollide = block.CanCollide,
--                                     Transparency = block.Transparency,
--                                     Material = block.Material,
--                                     Anchored = block.Anchored,
--                                     Color = block.Color,
--                                     AlreadyExistsInWorkspace = false,
--                                     AlreadyDivided = false,
--                                     ResetTime = TimeToReset,
--                                     OriginalPart = block.OriginalPart
--                                 }
--                                 table.insert(partTable,info)
--                             end
--                         end
--                     end
--                 else
--                     table.insert(partTable,block)
--                 end
--             end
            
--             warn(partTable)
--             inHitbox = CheckForNewVoxelsInHitbox(partTable,Hitbox)
--             NotInHitbox = CheckForNewVoxelsNotInHitbox(partTable,Hitbox)

--             partTable = {}
--         end
--         print('Exhausted?', os.clock() - exhaust > .1)
--     end

--     for i,block in inHitbox do
--         if (block.Size.X > minimum or block.Size.Y > minimum or block.Size.Z > minimum) then
--             if partCanSubdivide(block) then --If part is rectangular then it is cut in half, otherwise it is divided into cubes.
--                 partTable = CutPartinHalf(block,TimeToReset)
--             else
--                 local Threshold = 1.5  -- How much of a difference there can be between the largest axis and the smallest axis 

--                 local largest = math.max(block.Size.X, block.Size.Y, block.Size.Z) --Largest Axis
--                 local smallest = math.min(block.Size.X,block.Size.Y, block.Size.Z) -- Smallest Axis

--                 if smallest == block.Size.Y and smallest * Threshold <= largest then
--                     local bipolarVectorSet = {}

--                     local X = block.Size.X
--                     local Y = block.Size.Y
--                     local Z = block.Size.Z

--                     X /= 2
--                     Z /= 2
--                     bipolarVectorSet = { --Offset Vectors
--                         Vector3.new(-1,0,1),
--                         Vector3.new(1,0,-1),
--                         Vector3.new(1,0,1),
--                         Vector3.new(-1,0,-1),

--                     }

--                     local halfSize = Vector3.new(X,Y,Z)

--                     for _, offsetVector in pairs(bipolarVectorSet) do
--                         local info: VoxelInfo = {
--                             Size = halfSize,
--                             CFrame = block.CFrame + block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
--                             Parent = block.Parent,
--                             CanCollide = block.CanCollide,
--                             Transparency = block.Transparency,
--                             Material = block.Material,
--                             Anchored = block.Anchored,
--                             Color = block.Color,
--                             AlreadyExistsInWorkspace = false,
--                             AlreadyDivided = false,
--                             ResetTime = TimeToReset,
--                             OriginalPart = block.OriginalPart
--                         }
--                         table.insert(partTable,info)
--                     end
--                 elseif smallest == block.Size.X and smallest * Threshold <= largest then
--                     local bipolarVectorSet = {}

--                     local X = block.Size.X
--                     local Y = block.Size.Y
--                     local Z = block.Size.Z

--                     Y /= 2
--                     Z /= 2
--                     bipolarVectorSet = { --Offset Vectors
--                         Vector3.new(0,-1,1),
--                         Vector3.new(0,1,1),
--                         Vector3.new(0,-1,-1),
--                         Vector3.new(0,1,-1),

--                     }

--                     local halfSize = Vector3.new(X,Y,Z)

--                     for _, offsetVector in pairs(bipolarVectorSet) do
--                         local info: VoxelInfo = {
--                             Size = halfSize,
--                             CFrame = block.CFrame + block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
--                             Parent = block.Parent,
--                             CanCollide = block.CanCollide,
--                             Transparency = block.Transparency,
--                             Material = block.Material,
--                             Anchored = block.Anchored,
--                             Color = block.Color,
--                             AlreadyExistsInWorkspace = false,
--                             AlreadyDivided = false,
--                             ResetTime = TimeToReset,
--                             OriginalPart = block.OriginalPart
--                         }
--                         table.insert(partTable,info)
--                     end 
--                 elseif smallest == block.Size.Z and smallest * Threshold <= largest then
--                     local bipolarVectorSet = {}

--                     local X = block.Size.X
--                     local Y = block.Size.Y
--                     local Z = block.Size.Z

--                     X /= 2
--                     Y /= 2
--                     bipolarVectorSet = { --Offset Vectors
--                         Vector3.new(1,-1,0),
--                         Vector3.new(1,1,0),
--                         Vector3.new(-1,-1,0),
--                         Vector3.new(-1,1,0),

--                     }

--                     local halfSize = Vector3.new(X,Y,Z)

--                     for _, offsetVector in pairs(bipolarVectorSet) do
--                         local info: VoxelInfo = {
--                             Size = halfSize,
--                             CFrame = block.CFrame + block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
--                             Parent = block.Parent,
--                             CanCollide = block.CanCollide,
--                             Transparency = block.Transparency,
--                             Material = block.Material,
--                             Anchored = block.Anchored,
--                             Color = block.Color,
--                             AlreadyExistsInWorkspace = false,
--                             AlreadyDivided = false,
--                             ResetTime = TimeToReset,
--                             OriginalPart = block.OriginalPart
--                         }
--                         table.insert(partTable,info)
--                     end
--                 else
--                     local bipolarVectorSet = { --Offset Vectors
--                         Vector3.new(1,1,1),
--                         Vector3.new(1,1,-1),
--                         Vector3.new(1,-1,1),
--                         Vector3.new(1,-1,-1),
--                         Vector3.new(-1,1,1),
--                         Vector3.new(-1,1,-1),
--                         Vector3.new(-1,-1,1),
--                         Vector3.new(-1,-1,-1),
--                     }

--                     local halfSize = block.Size / 2.0

--                     for _, offsetVector in pairs(bipolarVectorSet) do
--                         local info: VoxelInfo = {
--                             Size = halfSize,
--                             CFrame = block.CFrame + block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector),
--                             Parent = block.Parent,
--                             CanCollide = block.CanCollide,
--                             Transparency = block.Transparency,
--                             Material = block.Material,
--                             Anchored = block.Anchored,
--                             Color = block.Color,
--                             AlreadyExistsInWorkspace = false,
--                             AlreadyDivided = false,
--                             ResetTime = TimeToReset,
--                             OriginalPart = block.OriginalPart
--                         }
--                         table.insert(partTable,info)
--                     end
--                 end
--             end
--         else
--             table.insert(partTable,block)
--         end
--     end

--     -- warn('Divided parts', partTable)
-- 	local check = false
-- 	for i, v in pairs(partTable) do
-- 		if math.floor(v.Size.X) > minimum or math.floor(v.Size.Y) > minimum or math.floor(v.Size.Z) > minimum then
-- 			check = true
--         end
-- 	end	
	
-- 	if NotInHitbox then
-- 		for i,v in NotInHitbox do
-- 			table.insert(partTable,v)
-- 		end
-- 	end
	
-- 	if check then
-- 		for i,partInfo in pairs(partTable) do
-- 			if partInfo.AlreadyDivided then
-- 				table.remove(partTable,i)
-- 			end
-- 		end
--         warn('TURN SMALLER YOU DUMB SHGETwaf')
--         -- return DivideBlock(partTable,MinimumVoxelSize,TimeToReset,Hitbox)
-- 	else	
-- 		return partTable --Returns resulting parts
-- 	end
-- end