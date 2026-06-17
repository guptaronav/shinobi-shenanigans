--!strict

local VoxBreaker = {}
VoxBreaker.__index = VoxBreaker

local OctreeAlgorithm = require(script:WaitForChild("OctreeAlgorithm"))
local NewAlgorithm = require(script:WaitForChild("NewAlgorithm"))
local Settings = require(script:WaitForChild("Settings"))
local Types = require(script:WaitForChild("Types"))
local Constructor = require(script:WaitForChild("PartConstructor"))
local GreedyMesher = require(script:WaitForChild("GreedyMesher"))
local rs = game:GetService("RunService")

export type VoxelInfoTable = Types.VoxelInfoTable
export type VoxelInfo = Types.VoxelInfo
export type PartTable = Types.PartTable
export type MoveableHitbox = Types.MoveableHitbox






local function CheckIfPartIsGreaterThanMinimum(Part:Part,Minimum:number|string)
	local check = false

	if typeof(Minimum) == "number" then
		if math.floor(Part.Size.X) > Minimum or math.floor(Part.Size.Y) > Minimum or math.floor(Part.Size.Z) > Minimum then
			check = true
		end		
	end

	return check
end

local function FindPartsInHitbox(Hitbox : BasePart, Params : OverlapParams) --Used to get all the parts within a part.
	local results = {}
	local touching
	if Params then
		touching = workspace:GetPartsInPart(Hitbox,Params)
	else
		touching = workspace:GetPartsInPart(Hitbox)
	end

	for i,v in pairs(touching) do
		if v:IsA("Part") then
			if v:HasTag(Settings.TagName) == true then
				table.insert(results,v)
			end			
		end
	end

	return results --Returns a table of all eligible parts touching the specified part
end

local function Octrees(Parts:PartTable,Minimum:number|string,TimeToReset:number,Hitbox:BasePart?):PartTable

	local Constructed = Constructor:ConstructVoxels(OctreeAlgorithm.DivideBlock(Parts,Minimum,TimeToReset,Hitbox))

	return Constructed
end

local function New(Parts:PartTable,Minimum:number|string,TimeToReset:number,Hitbox:BasePart?):PartTable

	local Constructed = Constructor:ConstructVoxels(NewAlgorithm.DivideBlock(Parts,Minimum,TimeToReset,Hitbox))

	return Constructed
end

local function getLargestAxis(part : Part)  --Returns Largest Axis of Part size
	return math.max(part.Size.X, part.Size.Y, part.Size.Z)
end


function VoxBreaker:CreateHitbox(Size : Vector3 | string, Cframe : CFrame , Shape : Enum.PartType|MeshPart , MinimumVoxelSize : number|string , TimeToReset : number, Params : OverlapParams)
	
	local hitboxPart
	if typeof(Shape) == "BasePart"  then
		hitboxPart = Shape:Clone()
	else
		hitboxPart = Instance.new("Part")
		hitboxPart.Shape = Shape or Settings.DefaultHitboxShape
	end

	hitboxPart.Size = Size or Settings.DefaultHitboxSize
	hitboxPart.CFrame = Cframe or CFrame.new()
	hitboxPart.Anchored = true
	hitboxPart.CanCollide = false
	hitboxPart.CanQuery = false
	hitboxPart.Material = Enum.Material.Neon
	hitboxPart.Color = Color3.fromRGB(255, 0, 0)
	hitboxPart.Transparency = 0.6


	if Settings.Visualizer then
		hitboxPart.Parent = game.Workspace			
	else
		hitboxPart.Parent = script.HitboxStorage
	end
	task.delay(1,function()
		hitboxPart:Destroy()
	end)

	local function HitboxCheck()
		local touchingParts = FindPartsInHitbox(hitboxPart,Params or Settings.DefaultOverlapParams)


		local Parts
		if Settings.Algorithm == "Octrees" then

			local minimum
			if MinimumVoxelSize == "Relative" then
				local largest = getLargestAxis(hitboxPart)
				minimum = largest * Settings.RelativityRatio
			else
				minimum = MinimumVoxelSize
			end
			if touchingParts and #touchingParts > 0 then


				Parts = Octrees(touchingParts,minimum,TimeToReset,hitboxPart)				
			end
		elseif Settings.Algorithm == "New" then		
			local minimum
			if MinimumVoxelSize == "Relative" then
				local largest = getLargestAxis(hitboxPart)
				minimum = largest * Settings.RelativityRatio
			else
				minimum = MinimumVoxelSize
			end
			

			for i,v in touchingParts do
				if math.max(v.Size.X,v.Size.Y,v.Size.Z) == minimum then
					table.remove(touchingParts,i)
				end
			end
			
			if touchingParts and #touchingParts > 0 then
				Parts = New(touchingParts,minimum,TimeToReset,hitboxPart)				
			end
		end	
		

		
		local fireTable:PartTable = {}

		for i,v in touchingParts do
			if not v:HasTag("Voxel") then
				v.Transparency = 1
				v.CanCollide = false
			else
				if CheckIfPartIsGreaterThanMinimum(v,MinimumVoxelSize) then
					if Settings.UseCache then
						Constructor:ReturnPart(v)
					else
						v:Destroy()
					end
				end				
			end
		end
		
		local newTouching = FindPartsInHitbox(hitboxPart,Params or Settings.DefaultOverlapParams)
		for i,v in newTouching do
			if v:HasTag("Voxel") then
				table.insert(fireTable,v)
			end
		end
		
		
		return fireTable

	end
	
	return HitboxCheck()
	
end


function VoxBreaker:VoxelizePart(Part:Part,Minimum,ResetTime:number)
	local constructed 
	if Settings.Algorithm == "New" then
		constructed = New({Part},Minimum or Settings.DefaultMinimumVoxelSize,ResetTime or Settings.DefaultResetTime,nil)
	else
		constructed = Octrees({Part},Minimum or Settings.DefaultMinimumVoxelSize,ResetTime or Settings.DefaultResetTime,nil)
	end
	Part.Transparency = 1
	Part.CanCollide = false
	return constructed
end

function VoxBreaker.CreateMoveableHitbox(MinimumVoxelSize : number | string, TimeToReset : number, Size : Vector3, Cframe : CFrame , Shape : Enum.PartType|BasePart, Params : OverlapParams)

	local bindable = Instance.new("BindableEvent")
	bindable.Name = "Touched"

	local destroyBindable = Instance.new("BindableEvent")
	destroyBindable.Name = "Destroyed"

	local hitboxPart:BasePart
	if typeof(Shape) == "Instance"  then
		hitboxPart = Shape:Clone()
	else
		hitboxPart = Instance.new("Part")
		hitboxPart.Shape = Shape or Settings.DefaultHitboxShape
	end

	hitboxPart.Size = Size or Settings.DefaultHitboxSize
	hitboxPart.CFrame = Cframe or CFrame.new()
	hitboxPart.Anchored = true
	hitboxPart.CanCollide = false
	hitboxPart.CanQuery = false
	hitboxPart.Material = Enum.Material.Neon
	hitboxPart.Color = Color3.fromRGB(255, 0, 0)
	hitboxPart.Transparency = 0.6


	if Settings.Visualizer then
		hitboxPart.Parent = game.Workspace	
	else
		hitboxPart.Parent = script.HitboxStorage
	end

	local self:MoveableHitbox = {
		WeldedTo = nil,
		WeldOffset = nil,
		Active = false,
		Event = bindable,
		MinimumVoxelSize = MinimumVoxelSize or Settings.DefaultMinimumVoxelSize,
		Shape = Shape or Settings.DefaultHitboxShape,
		Touched = bindable.Event,
		CurrentlyTouching = {},
		HitboxPart = hitboxPart,
		DestroyEvent = destroyBindable,
		Destroyed = destroyBindable.Event,
	}



	local function HitboxCheck()
		local touchingParts = FindPartsInHitbox(self.HitboxPart,Params or Settings.DefaultOverlapParams)
		local minimum
		local Parts
		

		if MinimumVoxelSize == "Relative" then
			local largest = getLargestAxis(hitboxPart)
			minimum = largest * Settings.RelativityRatio
		else
			minimum = self.MinimumVoxelSize
		end
		
		
		for i,v in touchingParts do
			if table.find(self.CurrentlyTouching,v) then
				table.remove(touchingParts,i)
			end
		end
		
		
		if touchingParts and #touchingParts > 0 then
			if Settings.Algorithm == "Octrees" then
				Parts = Octrees(touchingParts,minimum,TimeToReset,hitboxPart)				
			else
				Parts = New(touchingParts,minimum,TimeToReset,hitboxPart)				
			end
		end
		
		local newParts = FindPartsInHitbox(self.HitboxPart,Params)
		for i,v in newParts do
			table.insert(touchingParts,v)
		end
		
		for index,p in self.CurrentlyTouching do
			if table.find(touchingParts,p) == nil then
				table.remove(self.CurrentlyTouching,index)
			end
		end

		
		for i,v in touchingParts do
		
			if not v:HasTag("Voxel") then
				v.Transparency = 1
				v.CanCollide = false
			else
				if CheckIfPartIsGreaterThanMinimum(v,minimum) or Settings.Algorithm == "New" then
					if Settings.UseCache then
						Constructor:ReturnPart(v)
					else
						v:Destroy()
					end
				end		
			end
			
			
			
			
		
	
		end
		
		local fireTable:PartTable = {}


		for i,part in touchingParts do
			if table.find(self.CurrentlyTouching,part) == nil and part:HasTag("Voxel") then
				table.insert(fireTable,part)
				table.insert(self.CurrentlyTouching,part)
			end			
		end
		if #fireTable > 0 then
			self.Event:Fire(fireTable)
		end

		
		if Parts then
			self.CurrentlyTouching = Parts

		end
		
	end


	if Settings.AutoStartMoveable then
		self.Active = true
	end

	if Settings.UseRunService then
		task.spawn(function()
			local connection
			connection = rs.Heartbeat:Connect(function()
				if self.Active then
					if self.WeldedTo then
						if self.WeldOffset then
							self.HitboxPart.CFrame = self.WeldedTo.CFrame * self.WeldOffset
						else
							self.HitboxPart.CFrame = self.WeldedTo.CFrame
						end
					end
					HitboxCheck()					
				end
			end)

			self.Destroyed:Once(function()
				connection:Disconnect()
			end)

		end)
	else
		task.spawn(function()
			local hitboxExists = true

			while hitboxExists do
				if self.Active then
					if self.WeldedTo then
						if self.WeldOffset then
							self.HitboxPart.CFrame = self.WeldedTo.CFrame * self.WeldOffset
						else
							self.HitboxPart.CFrame = self.WeldedTo.CFrame
						end
					end

					HitboxCheck()


				end
				task.wait()
			end

			self.Destroyed:Once(function()
				hitboxExists = false
			end)
		end)
	end

	self.Destroyed:Once(function()
		self.DestroyEvent:Destroy()
		self.Event:Destroy()
		self.HitboxPart:Destroy()
	end)

	return setmetatable(self,VoxBreaker)
end

function VoxBreaker:Destroy()
	self.DestroyEvent:Fire()
end

function VoxBreaker:WeldTo(Part:BasePart,Offset:CFrame?)
	self.WeldedTo = Part
	if Offset then
		self.WeldOffset = Offset
	end
end

function VoxBreaker:Start()
	assert(self,"Hitbox not found")
	self.Active = true
end

function VoxBreaker:Stop()
	assert(self,"Hitbox not found")
	self.Active = false
end

function VoxBreaker:UnWeld()
	assert(self.WeldedTo,"Your Hitbox is not currently welded to anything.")

	self.WeldedTo = nil
	self.WeldOffset = nil
end

function VoxBreaker:GetTouching(overlapParams:OverlapParams)
	assert(self.HitboxPart,"Hitbox Part cannot be found.")
	return self.CurrentlyTouching
end

function VoxBreaker:ReturnPart(Part:Part|{Part})
	assert(Settings.UseCache, "Cannot use ReturnPart if cache is disabled.")
	if typeof(Part) == "Part" then
		if Constructor:CheckIfPartIsInCache(Part) then
			Constructor:ReturnPart(Part)
			Part.Parent = Constructor.CacheFolder.ObjectCache

		else
			warn("Part is not in cache.")
		end	
	elseif typeof(Part) == "table" then
		for i,v in Part do
			Constructor:ReturnPart(v)
		end
	else
		warn("Must be a part or a table of parts.")	
	end
end



return VoxBreaker
