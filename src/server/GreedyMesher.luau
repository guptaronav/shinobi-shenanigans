local GreedyMesher = {}

local Types = require(script.Parent:WaitForChild("Types"))

local function GreedyMeshOctrees(VoxelTable:Types.VoxelInfoTable)
	
	
	local function checkIfPartsAreAdjacentOnYAxis(partOne:Types.VoxelInfo,partTwo:Types.VoxelInfo)
		if partOne.CFrame.Rotation == partTwo.CFrame.Rotation and partOne.Size == partTwo.Size then
			if partOne.CFrame * CFrame.new(0,partOne.Size.Y,0) == partTwo.CFrame or partOne.CFrame * CFrame.new(0,-partOne.Size.Y,0) == partTwo.CFrame then
				return true
			else
				return false
			end
		else
			return false
		end
	end

	local function checkIfPartsAreAdjacentOnXAxis(partOne:Types.VoxelInfo,partTwo:Types.VoxelInfo)
		if partOne.CFrame.Rotation == partTwo.CFrame.Rotation and partOne.Size == partTwo.Size then
			if partOne.CFrame * CFrame.new(partOne.Size.X,0,0) == partTwo.CFrame or partOne.CFrame * CFrame.new(-partOne.Size.X,0,0) == partTwo.CFrame then
				return true
			else
				return false
			end
		else
			return false
		end
	end

	local function checkIfPartsAreAdjacentOnZAxis(partOne:Types.VoxelInfo,partTwo:Types.VoxelInfo)
		if partOne.CFrame.Rotation == partTwo.CFrame.Rotation and partOne.Size == partTwo.Size then
			if partOne.CFrame * CFrame.new(0,0,partOne.Size.Z) == partTwo.CFrame or partOne.CFrame * CFrame.new(0,0,-partOne.Size.Z) == partTwo.CFrame then
				return true	
			else
				return false
			end
		else
			return false
		end
	end



	local function greedyMesh(partTable,Ignore)

		for i,v in Ignore do
			if table.find(partTable,v) then
				table.remove(partTable,table.find(partTable,v))
			end
		end

		local function mergeParts(partOne:Part,partTwo:Part,Axis)
			local averagePosition = (partOne.CFrame.Position + partTwo.CFrame.Position)/2
			local averageCF = CFrame.new(averagePosition.X,averagePosition.Y,averagePosition.Z) * CFrame.Angles(math.rad(partOne.CFrame.Rotation.X),math.rad(partOne.CFrame.Rotation.Y),math.rad(partOne.CFrame.Rotation.Z))

			local newPart = Instance.new("Part")
			newPart.Parent = workspace
			newPart.Name = "gyat"
			newPart.Anchored = true
			newPart.CFrame = averageCF

			if Axis == "X" then
				newPart.Size = Vector3.new(partOne.Size.X *2,partOne.Size.Y,partOne.Size.Z)
			elseif Axis == "Y" then
				newPart.Size = Vector3.new(partOne.Size.X,partOne.Size.Y*2,partOne.Size.Z)
			elseif Axis == "Z" then	
				newPart.Size = Vector3.new(partOne.Size.X,partOne.Size.Y,partOne.Size.Z*2)
			end
			partOne:Destroy()
			partTwo:Destroy()
			table.insert(partTable,newPart)
			return newPart
		end

		for i,v in partTable do
			for s,d in partTable do
				if checkIfPartsAreAdjacentOnXAxis(v,d) then
					table.remove(partTable,i)
					table.remove(partTable,s)

					mergeParts(v,d,"X")
				elseif checkIfPartsAreAdjacentOnYAxis(v,d) then
					table.remove(partTable,i)
					table.remove(partTable,s)

					mergeParts(v,d,"Y")
				elseif checkIfPartsAreAdjacentOnZAxis(v,d) then
					table.remove(partTable,i)
					table.remove(partTable,s)

					mergeParts(v,d,"Z")
				end
			end
		end

	end

end

function GreedyMesher.GreedyMesh(VoxelTable:Types.VoxelInfoTable)
	local blocks = {}
	local sizes = {}

	local colors = {
		Color3.new(.24, .67, .05),
		Color3.new(.52, .29, .08),
		Color3.new(.43, .38, .35)
	}

	local amount = 8

	for x = 1, amount do
		blocks[x] = {}
		sizes[x] = {}

		for y = 1, amount do
			blocks[x][y] = {}
			sizes[x][y] = {}

			for z = 1, amount do
				blocks[x][y][z] = math.random(1, #colors)
				sizes[x][y][z] = {["X"] = 1, ["Y"] = 1, ["Z"] = 1}
			end
		end
	end

	for x, row in pairs(sizes) do
		for y, column in pairs(row) do
			for z, size in pairs(column) do
				if not sizes[x][y][z] then continue end
				if not sizes[x][y][z - 1] then continue end
				if blocks[x][y][z] ~= blocks[x][y][z - 1] then continue end
				sizes[x][y][z].Z += sizes[x][y][z - 1].Z
				sizes[x][y][z - 1] = nil
			end
		end
	end

	for x = 2, amount do
		for y, column in pairs(sizes[x]) do
			for z, size in pairs(sizes[x][y]) do
				if not sizes[x][y][z] then continue end
				if not sizes[x - 1][y][z] then continue end
				if size.Z ~= sizes[x - 1][y][z].Z then continue end
				if blocks[x][y][z] ~= blocks[x - 1][y][z] then continue end
				size.X += sizes[x - 1][y][z].X
				sizes[x - 1][y][z] = nil
			end
		end
	end

	for x, row in pairs(sizes) do
		for y = 2, amount do
			for z, size in pairs(sizes[x][y]) do
				if not sizes[x][y][z] then continue end
				if not sizes[x][y - 1][z] then continue end
				if size.Z ~= sizes[x][y - 1][z].Z then continue end
				if size.X ~= sizes[x][y - 1][z].X then continue end
				if blocks[x][y][z] ~= blocks[x][y - 1][z] then continue end
				size.Y += sizes[x][y - 1][z].Y
				sizes[x][y - 1][z] = nil
			end
		end
	end

	for x, row in pairs(sizes) do
		for y, column in pairs(row) do
			for z, size in pairs(column) do
				local part = Instance.new("Part")

				part.Anchored = true
				part.Position = Vector3.new(x - size.X / 2, y - size.Y / 2, z - size.Z / 2)
				part.Size = Vector3.new(size.X, size.Y, size.Z)
				part.Color = colors[blocks[x][y][z]]
				part.Parent = workspace
			end
		end
	end
end


return GreedyMesher
