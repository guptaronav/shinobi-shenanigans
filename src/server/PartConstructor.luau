local PartConstructor = {}

local Types = require(script.Parent:WaitForChild("Types"))
local ObjectCache = require(script.Parent:WaitForChild("ObjectCache"))
local Settings = require(script.Parent:WaitForChild("Settings"))

local templatePart = script.Parent:WaitForChild("TemplatePart")
local CS = game:GetService("CollectionService")
local cacheF


if Settings.UseCache then
	local cacheFolder = Instance.new("Folder")
	cacheFolder.Name = "Cache"
	cacheFolder.Parent = workspace
	cacheF = cacheFolder
	PartConstructor.CacheFolder = cacheFolder
	cache = ObjectCache.new(templatePart,Settings.DefaultPartCacheSize,cacheFolder)

end



local ids = {1} 

function generateCode()
	local code = #ids + 1  -- for testing, there are better ways
	-- now we check if it exists
	if table.find(ids, code) then
		task.wait()
		generateCode() -- call the function again
	else
		table.insert(ids, code)
		return code
	end
end

function removeCode(code)
	table.remove(ids,table.find(ids,code))	
end


local destructionSchedule = {} -- Keeps track of parts and their destruction timers


local function Destroy(part:Instance, timeToDestroy:number?)

	-- If the part is already scheduled for destruction, cancel the previous timer
	if destructionSchedule[part] then
		task.cancel(destructionSchedule[part])
	end

	-- Schedule a new destruction timer
	destructionSchedule[part] = task.delay(timeToDestroy, function()
		if part then
			if Settings.UseCache then
				for i, v in pairs(part:GetChildren()) do
					v.Parent = cacheF.ObjectCache
					cache:ReturnPart(v)
				end
				
				part:Destroy()

			else
				part:Destroy()
			end
		end
		destructionSchedule[part] = nil -- Remove the part from the schedule once it's destroyed
	end)
end

local restoreSchedule = {} -- Keeps track of parts and their destruction timers

local function Restore(info:Types.VoxelInfo, timeToRestore:number?)
	-- If the part is already scheduled for destruction, cancel the previous timer
	if restoreSchedule[info.OriginalPart] then
		task.cancel(restoreSchedule[info.OriginalPart])
	end

	-- Schedule a new destruction timer
	restoreSchedule[info.OriginalPart] = task.delay(timeToRestore, function()
		local code
		for i,v in info.OriginalPart:GetTags() do
			if tonumber(v) and table.find(ids,tonumber(v)) then
				--removeCode(tonumber(v))
				info.OriginalPart:RemoveTag(v)
			end			
		end
		info.OriginalPart.Transparency = info.Transparency
		info.OriginalPart.CanCollide = info.CanCollide
		info.OriginalPart:AddTag(Settings.TagName)
		restoreSchedule[info.OriginalPart] = nil -- Remove the part from the schedule once it's destroyed
	end)
end


function PartConstructor:ConstructVoxels(PartTable:Types.VoxelInfoTable):Types.PartTable
	local Constructed:Types.PartTable = {}

	if PartTable then
		for i,partInfo in PartTable do
				if Settings.UseCache then

					local Parent = partInfo.Parent


					if partInfo.Parent then
						if not (partInfo.Parent:HasTag("VoxelHolder")) then
							local Holder = Instance.new("Model")
							Holder = Instance.new("Model")
							Holder.Parent = Settings.VoxelFolder
							Holder.Name = "VoxelHolder"
							Holder:AddTag("VoxelHolder")
							local newCode = generateCode()
							Holder:AddTag(tostring(newCode))
							partInfo.OriginalPart:AddTag(tostring(newCode))
							Parent = Holder
							partInfo.Parent = Holder

							for i,v in PartTable do
								v.Parent = Holder
							end
						else
							local part
							local tagged = CS:GetTagged(partInfo.Parent:GetTags()[2])
							for i,v in tagged do
								if v:IsA("Part") then
									part = v
								end
							end
							if part then
								partInfo.OriginalPart = part
							end
						end
					end
					Destroy(Parent,partInfo.ResetTime)
					Restore(partInfo,partInfo.ResetTime)

					local Voxel = cache:GetPart(partInfo.CFrame)
					Voxel.CFrame = partInfo.CFrame
					Voxel.Parent = Parent
					Voxel.CanCollide = partInfo.CanCollide
					Voxel.Anchored = partInfo.Anchored
					Voxel.Size = partInfo.Size
					Voxel.Transparency = partInfo.Transparency
					if Settings.RandomColors then
						Voxel.Color = Color3.fromRGB(math.random(1,255),math.random(1,255),math.random(1,255))
					else
						Voxel.Color = partInfo.Color
					end
					
					Voxel.Name = tostring(math.random(1,100000))

					Voxel.Material = partInfo.Material
					Voxel:AddTag(Settings.TagName)
					Voxel:AddTag("Voxel")
					

					table.insert(Constructed,Voxel)
				else
					local Parent = partInfo.Parent


					if partInfo.Parent then
						if not (partInfo.Parent:HasTag("VoxelHolder")) then
							local Holder = Instance.new("Model")
							Holder = Instance.new("Model")
							Holder.Parent = Settings.VoxelFolder
							Holder.Name = "VoxelHolder"
							Holder:AddTag("VoxelHolder")
							local newCode = generateCode()
							Holder:AddTag(tostring(newCode))
							partInfo.OriginalPart:AddTag(tostring(newCode))
							Parent = Holder
							partInfo.Parent = Holder

							for i,v in PartTable do
								v.Parent = Holder
							end
						else
							local part
							local tagged = CS:GetTagged(partInfo.Parent:GetTags()[2])
							for i,v in tagged do
								if v:IsA("Part") then
									part = v
								end
							end
							if part then
								partInfo.OriginalPart = part
							end
						end
					end
					Destroy(Parent,partInfo.ResetTime)
					Restore(partInfo,partInfo.ResetTime)

					local Voxel = Instance.new("Part")
					Voxel.CFrame = partInfo.CFrame
					Voxel.Parent = Parent
					Voxel.CanCollide = partInfo.CanCollide
					Voxel.Anchored = partInfo.Anchored
					Voxel.Size = partInfo.Size
					Voxel.Transparency = partInfo.Transparency
					if Settings.RandomColors then
						Voxel.Color = Color3.fromRGB(math.random(1,255),math.random(1,255),math.random(1,255))
					else
						Voxel.Color = partInfo.Color
					end
					Voxel.Material = partInfo.Material
					Voxel:AddTag(Settings.TagName)
					Voxel:AddTag("Voxel")

					table.insert(Constructed,Voxel)
				end
		end		
	end

	return Constructed
end

function PartConstructor:CheckIfPartIsInCache(part:Part)
	if Settings.UseCache  then
		return cache:IsInUse(part)
	else
		return false
	end
end

function PartConstructor:ReturnPart(Part:Part)
	assert(Settings.UseCache,"Cannot return part, Cache is not currently enabled.")
	Part.Parent = cacheF.ObjectCache
	cache:ReturnPart(Part)
end

return PartConstructor
