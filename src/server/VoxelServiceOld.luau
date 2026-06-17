local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

if RunService:IsClient() then return {} end

-- if RunService:IsServer() then return {} end

local VoxBreaker = {}
VoxBreaker.__index = VoxBreaker

--Module by @Bartokens
--@Bartokens on discord and  @bartoken on tiktok
--Find information here: https://devforum.roblox.com/t/voxbreaker-an-oop-voxel-destruction-module/2935099

-----[ SETTINGS ]-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local TagName = "Voxable" --Name of Attribute that module will check parts for
local RandomColors = RunService:IsStudio() and false  -- Will make every part a random color. Set this to true if you want a visual representation of how the parts are being divided.
local Visualizer = RunService:IsStudio() and false -- Will make hitboxes visible when set to true
local miniumCubeSize = 4 --Default Minimum possible size that divided cubes can be.
local voxelFolder = workspace.Map:WaitForChild('UnfrozenVoxels'):WaitForChild('VoxelFolder') --Where the voxels are stored. Workspace by default.
local AutoStartMoveable = false --Toggle this to true if you want your moveable hitboxes to activate automatically without having to use :Start()
local PartCacheEnabled = true --Enables PartCache. This significantly improves performance so I reccommend keeping it on. 

local BatchVoxelLimit = 30
local AbsoluteVoxelLimit = 1200

-- local SettingsData = Players.LocalPlayer:WaitForChild('Settings', 30)
-- local BatchVoxelLimitEnabled = SettingsData:WaitForChild('VoxelBatchLimit')
-- local VoxelFPSLimitEnabled = SettingsData:WaitForChild('VoxelFPSLimit')
-- local VoxelSizeLimitEnabled = SettingsData:WaitForChild('VoxelSizeLimit')
-- local VoxelHitboxDistanceLimitEnabled = SettingsData:WaitForChild('VoxelHitboxDistanceLimit')
-- local AbsoluteVoxelLimitEnabled = SettingsData:WaitForChild('VoxelAbsoluteLimit')

local VoxelPresets = require(game.ReplicatedStorage.Shared.EffectPresets.VoxelPresets)
----[ RESOURCES ]------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local rs = game:GetService("RunService")

local cache
local PartFolder

if PartCacheEnabled then
	local PC = require(script.PartCache)

	PartFolder = Instance.new("Folder")
	PartFolder.Name = "PartCache"..tostring(math.random(1,5))
	PartFolder.Parent = workspace

	local TemplatePart = Instance.new("Part")
	TemplatePart.Anchored = true
	cache = PC.new(TemplatePart,3000,PartFolder)
	cache.ExpansionSize = 3000
	TemplatePart:Destroy()	
end

local existingVoxels = {}

-----[ LOCAL FUNCTIONS ]--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function RemoveVoxel(voxel: Part)
	voxel.Anchored = true
	voxel.Transparency = 1
	voxel.CanCollide = false
	voxel.CFrame =  CFrame.new(0, 9e3, 0)
end

local destructionSchedule = {} -- Keeps track of parts and their destruction timers
local rng = Random.new()

local function DestroyPart(v)
	if table.find(existingVoxels, v) then
		table.remove(existingVoxels, table.find(existingVoxels, v))
	end

	if table.find(cache.InUse,v) then
		for i,child in pairs(v:GetChildren()) do
			child:Destroy()
		end
		cache:ReturnPart(v)
		v.Parent = PartFolder
	else
		v:Destroy()
	end
end

local function Destroy(part:Instance, timeToDestroy)

	-- If the part is already scheduled for destruction, cancel the previous timer
	if destructionSchedule[part] then
		task.cancel(destructionSchedule[part])
	end

	-- Schedule a new destruction timer
	destructionSchedule[part] = task.defer(function()
		local timer = os.clock()
		repeat
			task.wait()
		until os.clock() - timer > timeToDestroy --or AbsoluteVoxelLimitEnabled.Value and #voxelFolder:GetDescendants() > AbsoluteVoxelLimit and index == LastRunningContainerIndex

		if part and part.Parent then
			if PartCacheEnabled then
				if part:IsA("Model") then
					for i, v in part:GetChildren() do
						DestroyPart(v)
					end
					part:Destroy()
				else
					DestroyPart(part)
				end
			else
				part:Destroy()
			end
		end
		destructionSchedule[part] = nil -- Remove the part from the schedule once it's destroyed
	end)
end



local function partCanSubdivide(part : Part, givenTreshold: number?) --Checks if part is rectangular.

	local Threshold =givenTreshold or .2
	-- local Threshold = .2--1.5  -- How much of a difference there can be between the largest axis and the smallest axis 

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

local function getLargestAxis(part : Part)  --Returns Largest Axis of Part size
	return math.max(part.Size.X, part.Size.Y, part.Size.Z)
end

local function CutPartinHalf(block : Part, TimeToReset : number) --Cuts part into two evenly shaped pieces.
	local partTable = {} --Table of parts to be returned
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

	local model 
	
	if block.Parent:IsA("Model") and block.Parent:GetAttribute("VoxelHolder") then
		model = block.Parent
	else
		model = Instance.new("Model")
		model.Name = "VoxelHolder"
		model.Parent = voxelFolder
		model:SetAttribute("VoxelHolder",true)
	end
	
	if TimeToReset and TimeToReset >= 0 then
		Destroy(model,TimeToReset)
	end


	local halfSize = Vector3.new(X,Y,Z)

	for _, offsetVector in pairs(bipolarVectorSet) do
		
		
		local clone
		if PartCacheEnabled then
			clone = cache:GetPart()
			CopyProperties(block,clone)
		else
			clone = block:Clone()
		end
		
		
		
		if RandomColors then
			clone.Color = Color3.fromRGB(math.random(1,255),math.random(1,255),math.random(1,255))
		end

		
		clone.Parent = model
		clone.Size = halfSize
		clone.CFrame += block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector)
		table.insert(partTable,clone)
	end

	if not TimeToReset or TimeToReset < 0 then
		block:Destroy()
	else
		if block:GetAttribute("Transparency") == nil then
			block:SetAttribute("Transparency",block.Transparency)
			block:SetAttribute("Collide",block.CanCollide)
			block:SetAttribute("Query",block.CanQuery)
		end
		block.Transparency = 1
		block.CanCollide = false
		block.CanQuery = false
		block:SetAttribute(TagName,false)
		
		for i,v in block:GetChildren() do
			task.spawn(function()
				if v:IsA("SurfaceGui") then
					local enabled = v.Enabled
					v.Enabled = false
					repeat task.wait()

					until model.Parent == nil
					v.Enabled = enabled
				elseif v:IsA("Decal") then
					local transparency = v.Transparency
					v.Transparency = 1
					repeat task.wait()

					until model.Parent == nil
					v.Transparency = transparency
				elseif v:IsA("Texture") then
					local transparency = v.Transparency
					v.Transparency = 1
					repeat task.wait()

					until model.Parent == nil
					v.Transparency = transparency					
				end
			end)
		end

		task.spawn(function()
			repeat task.wait()

			until model.Parent == nil
			
			block.Transparency = block:GetAttribute("Transparency")
			block.CanQuery =  block:GetAttribute("Query")
			block.CanCollide = block:GetAttribute("Collide")
			block:SetAttribute(TagName,true)
		end)



	end
	

	if block.Parent:IsA("Model") and block.Parent:GetAttribute("VoxelHolder") then
		if PartCacheEnabled then
			for i,v in pairs(block:GetChildren()) do
				v:Destroy()
			end
			cache:ReturnPart(block)
			block.Parent = PartFolder
		else
			block:Destroy()
		end
	end

	return partTable -- Returns a table containing the two halves
end


local function DivideBlock(block : Part, MinimumVoxelSize : number, Parent : Instance, TimeToReset : number) --Divides part into evenly shaped cubes.
	--MinimumvVoxelSize Parameter is used to describe the minimum possible size that the parts can be divided. To avoid confusion, this is not the size that the parts will be divided into, but rather the minimum allowed
	--You CANNOT change the size of the resulting parts. They are dependent on the size of the original part.

	local partTable = {} -- Table of parts to be returned
	local minimum = MinimumVoxelSize or miniumCubeSize

	if block.Parent:HasTag('Pickupable') then
		block.Parent:RemoveTag('Pickupable')
	end

	if block.Size.X > minimum or block.Size.Y > minimum or block.Size.Z > minimum then
		if partCanSubdivide(block) then --If part is rectangular then it is cut in half, otherwise it is divided into cubes.
			partTable = CutPartinHalf(block,TimeToReset)
			
		else
			local model 
			if block.Parent:IsA("Model") and block.Parent:GetAttribute("VoxelHolder") then
				model = block.Parent
			else
				model = Instance.new("Model")
				model.Name = "VoxelHolder"
				model.Parent = voxelFolder
				model:SetAttribute("VoxelHolder",true)
			end

			if TimeToReset and TimeToReset >= 0 then
				Destroy(model,TimeToReset)
			end

			local Threshold = .2 -- 1.5  -- How much of a difference there can be between the largest axis and the smallest axis 

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

					local clone
					if PartCacheEnabled then
						clone = cache:GetPart()
						CopyProperties(block,clone)
					else
						clone = block:Clone()
					end
					clone:SetAttribute("Voxel",true)
					if RandomColors then
						clone.Color = Color3.fromRGB(math.random(1,255),math.random(1,255),math.random(1,255))
					end

					clone.Parent = Parent or model
					clone.Size = halfSize
					clone.CFrame += block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector)
					table.insert(partTable,clone)
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

					local clone
					if PartCacheEnabled then
						clone = cache:GetPart()
						CopyProperties(block,clone)
					else
						clone = block:Clone()
					end
					clone:SetAttribute("Voxel",true)
					if RandomColors then
						clone.Color = Color3.fromRGB(math.random(1,255),math.random(1,255),math.random(1,255))
					end

					clone.Parent = Parent or model
					clone.Size = halfSize
					clone.CFrame += block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector)
					table.insert(partTable,clone)
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

					local clone
					if PartCacheEnabled then
						clone = cache:GetPart()
						CopyProperties(block,clone)
					else
						clone = block:Clone()
					end
					clone:SetAttribute("Voxel",true)
					if RandomColors then
						clone.Color = Color3.fromRGB(math.random(1,255),math.random(1,255),math.random(1,255))
					end

					clone.Parent = Parent or model
					clone.Size = halfSize
					clone.CFrame += block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector)
					table.insert(partTable,clone)
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

					local clone
					if PartCacheEnabled then
						clone = cache:GetPart()
						CopyProperties(block,clone)
					else
						clone = block:Clone()
					end
					if RandomColors then
						clone.Color = Color3.fromRGB(math.random(1,255),math.random(1,255),math.random(1,255))
					end

					clone.Parent = Parent or model
					clone.Size = halfSize
					clone.CFrame += block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector)
					table.insert(partTable,clone)
				end
			end

			if block.Parent:IsA("Model") and block.Parent:GetAttribute("VoxelHolder") then
				if PartCacheEnabled then
					for i,v in pairs(block:GetChildren()) do
						v:Destroy()
					end
					cache:ReturnPart(block)
					block.Parent = PartFolder
				else
					block:Destroy()
				end
			end


			if not TimeToReset or TimeToReset < 0 then
				block:SetAttribute(TagName,false)
				block:Destroy()

			else


				if block:GetAttribute("Transparency") == nil then
					block:SetAttribute("Transparency",block.Transparency)
					block:SetAttribute("Collide",block.CanCollide)
					block:SetAttribute("Query",block.CanQuery)
				end



				block.Transparency = 1
				block.CanCollide = false
				block.CanQuery = false
				block:SetAttribute(TagName,false)

				for i,v in block:GetChildren() do
					task.spawn(function()
						if v:IsA("SurfaceGui") then
							local enabled = v.Enabled
							v.Enabled = false
							repeat task.wait()

							until model.Parent == nil
							v.Enabled = enabled
						elseif v:IsA("Decal") then
							local transparency = v.Transparency
							v.Transparency = 1
							repeat task.wait()

							until model.Parent == nil
							v.Transparency = transparency
						elseif v:IsA("Texture") then
							local transparency = v.Transparency
							v.Transparency = 1
							repeat task.wait()

							until model.Parent == nil
							v.Transparency = transparency					
						end
					end)
				end

				task.spawn(function()
					repeat task.wait()
					until model.Parent == nil





					block.Transparency = block:GetAttribute("Transparency")
					block.CanQuery =  block:GetAttribute("Query")
					block.CanCollide = block:GetAttribute("Collide")

					block:SetAttribute(TagName,true)
				end)



			end
		end


		
	elseif block.Parent:GetAttribute("VoxelHolder") == nil and block:GetAttribute("Voxel") == nil then

		if block:GetAttribute("Transparency") == nil then
			block:SetAttribute("Transparency",block.Transparency)
			block:SetAttribute("Collide",block.CanCollide)
			block:SetAttribute("Query",block.CanQuery)
		end
		local clone
		if PartCacheEnabled then
			clone = cache:GetPart()
			CopyProperties(block,clone)
		else
			clone = block:Clone()
		end
		clone.Parent = block.Parent	
		if TimeToReset and TimeToReset >= 0 then
			Destroy(clone,TimeToReset)
		end



		if not TimeToReset or TimeToReset < 0 then
			block:SetAttribute(TagName,false)
			
		block:Destroy()
			
		else
			block.Transparency = 1
			block.CanCollide = false
			block.CanQuery = false
			block:SetAttribute(TagName,false)
			
			
			for i,v in block:GetChildren() do
				task.spawn(function()
					if v:IsA("SurfaceGui") then
						local enabled = v.Enabled
						v.Enabled = false
						task.wait(TimeToReset)
						v.Enabled = enabled
					elseif v:IsA("Decal") then
						local transparency = v.Transparency
						v.Transparency = 1
						task.wait(TimeToReset)
						v.Transparency = transparency
					elseif v:IsA("Texture") then
						local transparency = v.Transparency
						v.Transparency = 1
						task.wait(TimeToReset)
						v.Transparency = transparency					
					end
				end)
			end
			

			task.spawn(function()
				task.wait(TimeToReset)


				block.Transparency = block:GetAttribute("Transparency")
				block.CanQuery =  block:GetAttribute("Query")
				block.CanCollide = block:GetAttribute("Collide")
				block:SetAttribute(TagName,true)
			end)



		end

	end




	return partTable --Returns resulting parts
end

local function GetTouchingParts(part : Part, Params : OverlapParams) --Used to get all the parts within a part.
	local results = {}
	local touching
	if Params then
		touching = workspace:GetPartsInPart(part,Params)
	else
		touching = workspace:GetPartsInPart(part)
	end
	
	for i,v in pairs(touching) do
		if v:IsA("Part") then
			if v:GetAttribute(TagName) == true then
				table.insert(results,v)
			end
		end
	end
	return results --Returns a table of all eligible parts touching the specified part
end

function CopyProperties(PartOne:Part,PartTwo:Part)
	PartTwo.Anchored = PartOne.Anchored
	PartTwo.Transparency = PartOne.Transparency
	PartTwo.CanCollide = PartOne.CanCollide
	PartTwo.CanQuery = PartOne.CanQuery
	PartTwo.CanTouch = PartOne.CanTouch
	PartTwo.CastShadow = PartOne.CastShadow
	PartTwo.CFrame = PartOne.CFrame
	PartTwo.Color = PartOne.Color
	PartTwo.Name = PartOne.Name
	PartTwo.Size = PartOne.Size
	PartTwo.Material = PartOne.Material
	PartTwo.Shape = PartOne.Shape
	PartTwo.CollisionGroup = PartOne.CollisionGroup
	-- for i,v in PartOne:GetAttributes() do
	-- 	if i == TagName then continue end
	-- 	PartTwo:SetAttribute(i, v)
	-- end

	PartTwo:SetAttribute(TagName,PartOne:GetAttribute(TagName))
	
	for i,v in PartOne:GetChildren() do
		local clone = v:Clone()
		clone.Parent = PartTwo
	end

end

-----[ MODULE FUNCTIONS ]----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function VoxBreaker:VoxelizePart(Part : Part, MinimumVoxelSize : number, TimeToReset : number) --Repeatedly voxelizes a part until it meets the specified voxel size
	local minimum = MinimumVoxelSize  or 5

	local parts = DivideBlock(Part,minimum,nil,TimeToReset)
	repeat

		for i, v in pairs(parts) do
			if v:IsDescendantOf(workspace) then
				local parts2 = DivideBlock(v,minimum)
				for _, p in  pairs(parts2) do
					table.insert(parts,p)
				end
			else
				table.remove(parts,i)
			end
		end

		local check = true
		for i, v in pairs(parts) do
			if math.floor(v.Size.X) > minimum or math.floor(v.Size.Y) > minimum or math.floor(v.Size.Z) > minimum then
				check = false
			end
		end
	until check == true
	return parts
end

function VoxBreaker:VoxelizeModel(model: Model, TimeToReset: number)
	local DefaultSize = Vector3.new(1,1,1) -- Default Hitbox Size
	local DefaultShape = Enum.PartType.Block -- Default Shape of hitbox
	local DefaultTimeToReset = 50 --Default time in seconds it takes for divided parts to reset	

	local minimum = miniumCubeSize --+ (size.Magnitude*.1)
	-- minimum = math.max(miniumCubeSize, size.Magnitude*.1)
	local timetoreset = TimeToReset or DefaultTimeToReset



	local partTable = {} --Table of parts to be returned

	for _,Part in model:GetDescendants() do
		if not Part:IsA('Part') then continue end

		local parts = DivideBlock(Part,minimum,nil,timetoreset)
		repeat
			for i, v in pairs(parts) do
				if v:IsDescendantOf(workspace) and v:GetAttribute(TagName) and (not v:GetAttribute('Voxel')) then
					local parts2 = DivideBlock(v,minimum, nil, TimeToReset)
					for _, p in  pairs(parts2) do
						table.insert(parts,p)
					end
				else
					table.remove(parts,i)
				end
			end

			local check = true
			for i, v in pairs(partTable) do
				if v:IsA("Part") and v:GetAttribute(TagName) then			
					if math.floor(v.Size.X) > minimum or math.floor(v.Size.Y) > minimum or math.floor(v.Size.Z) > minimum then
						check = false
					end
				else
					table.remove(partTable,i)
				end
			end
		until check == true
	end
	
	for _,v in partTable do
		table.insert(existingVoxels, v)
	end

	return partTable --Returns all parts touching the hitbox
end

function VoxBreaker:CreateHitbox(Size : Vector3 | string, Cframe : CFrame , Shape : Enum.PartType , MinimumVoxelSize : number , TimeToReset : number, Params : OverlapParams, bypassLimit: boolean?, discountVoxels: boolean?) --Creates one hitbox which divides any applicable parts that are touching it. 
	--If the TimeToReset parameter is less than 0, then the parts will not reset.

	local DefaultSize = Vector3.new(1,1,1) -- Default Hitbox Size
	local DefaultShape = Enum.PartType.Block -- Default Shape of hitbox
	local DefaultTimeToReset = 50 --Default time in seconds it takes for divided parts to reset	

	local size = Size or DefaultSize
	local shape = Shape or DefaultShape
	local minimum = MinimumVoxelSize or miniumCubeSize --+ (size.Magnitude*.1)
	-- minimum = math.max(miniumCubeSize, size.Magnitude*.1)
	local timetoreset = TimeToReset or DefaultTimeToReset



	local partTable = {} --Table of parts to be returned

	local part = Instance.new("Part") --Creating the hitbox

	Destroy(part,0.5) --Destroys hitbox in 0.5 seconds

	part.Size = Size or DefaultSize 
	part.CFrame = Cframe or CFrame.new(0,0,0)
	part.Anchored = true
	part.Massless = true
	part.Transparency = 0.6
	if Shape then
		part.Shape = Shape
	end
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 0, 0)
	
	if MinimumVoxelSize == "Relative" then
		local ratio = 1/3
		local largest = getLargestAxis(part)
		minimum = largest * ratio
	end

	if Visualizer or game.ReplicatedStorage:GetAttribute('VoxelDebugMode') then
		part.Parent = game.Workspace.UnobstructiveAssets
	end

	repeat
		local touching = GetTouchingParts(part,Params) --Initial check

		local check = true



		for i, v in pairs(touching) do
			if v:IsA("Part") and v:GetAttribute(TagName) and (not discountVoxels or not v:GetAttribute('Voxel')) then
				if v:HasTag('Pickupable') then
					v:RemoveTag('Pickupable')
				end

				DivideBlock( v , minimum , nil , timetoreset)

			end
		end

		partTable = GetTouchingParts(part,Params)

		for i, v in pairs(partTable) do
			if v:IsA("Part") and v:GetAttribute(TagName) then			
				if math.floor(v.Size.X) > minimum or math.floor(v.Size.Y) > minimum or math.floor(v.Size.Z) > minimum then
					check = false
				end
			else
				table.remove(partTable,i)
			end
		end

	until check == true

	for _,v in partTable do
		if partCanSubdivide(v, 1.5) then
			table.remove(partTable, table.find(partTable, v))
		end
	end

	-- for _,v in partTable do
	-- 	v:SetAttribute('Voxel', true)	

	-- end

	-- if VoxelHitboxDistanceLimitEnabled.Value and Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
	-- 	local distance = (Players.LocalPlayer.Character.HumanoidRootPart.Position - Cframe.Position).Magnitude
	-- 	if distance > 200 then
	-- 		warn('Hitbox too far from player by about: '..(distance - 200)..' studs')
	-- 		for i,v in partTable do
	-- 			local voxel = partTable[i]
	-- 			RemoveVoxel(voxel)
	-- 		end
	-- 		-- if partTable[1].Parent:GetAttribute('VoxelHolder') then
	-- 		-- 	Destroy(partTable[1].Parent, rng:NextNumber(.5, 2))
	-- 		-- end
	-- 		return {}
	-- 	end
	-- end

	-- if true then
	-- -- if VoxelSizeLimitEnabled.Value then
	-- 	local filteredTable = {}
	-- 	for i, voxel in partTable do
	-- 		if voxel.Size.Magnitude < miniumCubeSize * .7 then
	-- 			RemoveVoxel(voxel)
	-- 		else
	-- 			table.insert(filteredTable, voxel)
	-- 		end
	-- 	end
	-- 	local amountLost = #partTable - #filteredTable
	-- 	if amountLost > 0 then
	-- 		warn(amountLost..' voxel were too small')
	-- 	end
	-- 	partTable = filteredTable
	-- end
	
	-- if #partTable > BatchVoxelLimit and not bypassLimit then
	-- -- if BatchVoxelLimitEnabled.Value and #partTable > BatchVoxelLimit and not bypassLimit then
	-- 	warn('batch limit reached, overflow of: '..#partTable - BatchVoxelLimit)
	-- 	local filteredTable = {}
	-- 	for i=1, #partTable do
	-- 		if i > BatchVoxelLimit then 
	-- 			local voxel = partTable[i]
	-- 			RemoveVoxel(voxel)
	-- 			continue
	-- 		end
	-- 		table.insert(filteredTable, partTable[i])
	-- 	end
	-- 	partTable = filteredTable
	-- end

	-- print('Parts in batch:', #partTable, bypassLimit)
	
	for _,v in partTable do
		table.insert(existingVoxels, v)
	end
	-- print(#existingVoxels)

	-- if #existingVoxels > AbsoluteVoxelLimit then -- and AbsoluteVoxelLimitEnabled.Value then
	-- 	for i=1, #existingVoxels - AbsoluteVoxelLimit do
	-- 		RemoveVoxel(existingVoxels[i])
	-- 		table.remove(existingVoxels, i)
	-- 	end
	-- end

	return partTable --Returns all parts touching the hitbox

end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function VoxBreaker.DestroyVoxels(Size: Vector3, Cframe: CFrame , Shape: Enum.PartType , MinimumVoxelSize: number , TimeToReset: number, Params: OverlapParams?)
    local voxels = VoxBreaker:CreateHitbox(Size, Cframe, Shape, MinimumVoxelSize, TimeToReset, Params)
    for _,v in voxels do
        v:Destroy()
    end
end

function VoxBreaker.UnfreezeVoxels(Size: Vector3, Cframe: CFrame , Shape: Enum.PartType , MinimumVoxelSize: number , TimeToReset: number, launchDirection: Vector3?, Params: OverlapParams?) 
    local voxels = VoxBreaker:CreateHitbox(Size, Cframe, Shape, MinimumVoxelSize, TimeToReset, Params)

    for _,v in voxels do
		v.Massless = true
		-- v.CustomPhysicalProperties = PhysicalProperties.new(2, .6, 1, 1, 1)
		v.CustomPhysicalProperties = PhysicalProperties.new(2, .1, 1, .1, 1)
		v.Anchored = false
        v.Size -= Vector3.one * .1

		if launchDirection  then
			local bv = Instance.new('BodyVelocity')
			bv.MaxForce = Vector3.new(10000, 10000, 10000) 
			bv.Velocity = launchDirection + Vector3.new(math.random(-5, 5),math.random(-5, 5),math.random(-5, 5))
			bv.Parent = v
			task.delay(.3, function()
				bv:Destroy()
			end)
		end

		-- TO PREVENT FLINGING. DO NOT REMOVE
		local curParent = v.Parent
		task.spawn(function()
			while curParent == v.Parent do
				if v.Anchored then
					v.AssemblyLinearVelocity = Vector3.zero
					v.AssemblyAngularVelocity = Vector3.zero 
				end
				rs.Heartbeat:Wait()
			end
		end)

		-- print(v.AssemblyLinearVelocity, v.AssemblyAngularVelocity)
		-- v.AssemblyLinearVelocity = Vector3.zero

        task.spawn(function()
            task.wait(.1)
            local timeout = os.clock()
            repeat task.wait() until v.AssemblyLinearVelocity.Magnitude == 0 or os.clock() - timeout > 5.5
            v.Anchored = true
        end)

		if TimeToReset then
			task.delay(TimeToReset - 1, function()
				game:GetService('TweenService'):Create(v, TweenInfo.new(1), {Transparency = 1}):Play()
			end)
		end
    end

    print('unfreezing')
end

local groundRayParams = RaycastParams.new()
groundRayParams.FilterType = Enum.RaycastFilterType.Exclude
groundRayParams.FilterDescendantsInstances = {workspace.UnobstructiveAssets, workspace.Characters}
local player = game.Players.LocalPlayer

local function TogglePhysics(voxel: Part, enable: boolean?)
	if not enable then
		-- DestroyPart(voxel)
		voxel.Anchored = true
		voxel.CanCollide = false
		voxel.CastShadow = false
		voxel.CanQuery = false
		voxel.CanTouch = false
	else
		
		voxel.Anchored = false
		voxel.CanCollide = true
		voxel.CastShadow = true
		voxel.CanQuery = true
	end
end

function VoxBreaker.SetupVoxel(voxel: Part, voxelDuration, destructionDuration, launchDirection, groundAnchored: boolean?)
	-- v.Massless = true
    -- v.CustomPhysicalProperties = PhysicalProperties.new(2, .6, 1, 1, 1)
    voxel.CustomPhysicalProperties = VoxelPresets.PhysicalProperties[voxel.Material] or VoxelPresets.PhysicalProperties[Enum.Material.SmoothPlastic]
	if not voxel:GetAttribute('Frozen') and not groundAnchored then
		voxel.Anchored = false
		-- voxel:SetNetworkOwner()
	elseif groundAnchored then
		warn('grounded voxel!')
	end
	if not voxel:HasTag('SizeDecreased') then
		voxel.Size -= Vector3.one * .2
		voxel:AddTag('SizeDecreased')
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
        task.wait(2)
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

if RunService:IsClient() then
	local FPS = 60
	local TimeFunction = RunService:IsRunning() and time or os.clock

	local LastIteration, Start
	local FrameUpdateTable = {}

	local function HeartbeatUpdate()
		LastIteration = TimeFunction()
		for Index = #FrameUpdateTable, 1, -1 do
			FrameUpdateTable[Index + 1] = FrameUpdateTable[Index] >= LastIteration - 1 and FrameUpdateTable[Index] or nil
		end

		FrameUpdateTable[1] = LastIteration
		FPS = (math.floor(TimeFunction() - Start >= 1 and #FrameUpdateTable or #FrameUpdateTable / (TimeFunction() - Start)))
	end

	Start = TimeFunction()
	RunService.Heartbeat:Connect(HeartbeatUpdate)

	RunService.RenderStepped:Connect(function(deltaTimeSim)
		-- if not VoxelFPSLimitEnabled.Value then return end

		local renderDistance: number = math.max(30, math.pow(FPS, 1.8) - 300)
		local humRoot = player.Character and player.Character:FindFirstChild('HumanoidRootPart')
		if not humRoot then return end

		-- print(FPS)
		if FPS < 20 then
			-- print(FPS, renderDistance)
		end
	
		for i,v in voxelFolder:GetDescendants() do
			if not v:IsA('BasePart') then continue end
	
			if (humRoot.Position - v.Position).Magnitude > renderDistance then
				v:SetAttribute('HaltPhysics', true)
			else
				v:SetAttribute('HaltPhysics', false)
			end		
		end
	end)
end

-- RunService.PreSimulation:Connect(function(deltaTimeSim)
-- 	local amountOfVoxelsInViscinity = 0
-- 	for v, m in PriorityList do
-- 		if m < ViscinityRadius then
-- 			amountOfVoxelsInViscinity += 1
-- 		end
-- 	end

-- 	if true then return end
-- 	if amountOfVoxelsInViscinity > VoxelViscinityLimit then
-- 		-- for v, m in PriorityList do
-- 		-- 	if m > topMagnitude then
-- 		-- 		topMagnitude = m
-- 		-- 	end
-- 		-- end

-- 		-- local treshhold = ((#voxelFolder:GetChildren() - TotalVoxelLimit)*.01)/topMagnitude
-- 		print(amountOfVoxelsInViscinity)
-- 		local treshhold = 50

-- 		for v, m in PriorityList do
-- 			if m > treshhold then
-- 				v:SetAttribute('HaltPhysics', true)
-- 			else
-- 				v:SetAttribute('HaltPhysics', false)
-- 			end
-- 		end
-- 	else
-- 		for v, m in PriorityList do
-- 			v:SetAttribute('HaltPhysics', false)
-- 		end
-- 	end
-- end)

return VoxBreaker