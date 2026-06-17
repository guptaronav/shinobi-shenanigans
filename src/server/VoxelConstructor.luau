local PartConstructor = {}
local CS = game:GetService("CollectionService")

local ObjectCache = require(script.Parent:WaitForChild("ObjectCache"))
local Settings = require(script.Parent:WaitForChild("Settings"))

type Voxel = Part
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

local templatePart: Part = Instance.new('Part')

local cacheFolder: Folder = Instance.new("Folder")
cacheFolder.Name = "Cache"
cacheFolder.Parent = workspace
PartConstructor.CacheFolder = cacheFolder

local cache = ObjectCache.new(templatePart,Settings.DefaultPartCacheSize,cacheFolder)

local ids = {1} 

function generateCode()
	local code = #ids + 1  -- for testing, there are better ways
	-- now we check if it exists
	if table.find(ids, code) then
		error('id already exists:', code)
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
            for _, v in pairs(part:GetChildren()) do
                v.Parent = cacheFolder.ObjectCache
                cache:ReturnPart(v)
            end
            
            part:Destroy()
		end
		destructionSchedule[part] = nil -- Remove the part from the schedule once it's destroyed
	end)
end

local restoreSchedule = {} -- Keeps track of parts and their destruction timers

local function Restore(info: VoxelInfo, timeToRestore:number?)
	-- If the part is already scheduled for destruction, cancel the previous timer
	if restoreSchedule[info.OriginalPart] then
		task.cancel(restoreSchedule[info.OriginalPart])
	end

	-- Schedule a new destruction timer
	restoreSchedule[info.OriginalPart] = task.delay(timeToRestore, function()
		warn('RESTOREEE', info)
		local code
		for i,v in info.OriginalPart:GetTags() do
			if tonumber(v) and table.find(ids,tonumber(v)) then
				--removeCode(tonumber(v))
				info.OriginalPart:RemoveTag(v)
			end
		end

		info.OriginalPart.Transparency = info.Transparency
		info.OriginalPart.CanCollide = info.CanCollide
		print(info.OriginalPart.CanCollide)
		info.OriginalPart:AddTag(Settings.TagName)

		restoreSchedule[info.OriginalPart] = nil -- Remove the part from the schedule once it's destroyed
	end)
end


function PartConstructor:ConstructVoxels(VoxelInfoTable: {VoxelInfo}): {Voxel}
	local Constructed: {Voxel} = {}
	
	if VoxelInfoTable then
		warn(VoxelInfoTable)
		for i,partInfo in VoxelInfoTable do
			-- if partInfo.Parent:GetAttribute('UnanchoredVoxel') then continue end
			--if partInfo.Parent and partInfo.Parent:GetAttribute('Voxel') then continue end
            local Parent = partInfo.Parent

			if partInfo.OriginalPart then
				partInfo.OriginalPart:RemoveTag('Voxel')
				print('removing voxel tag')
			end

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
                
                    --if partInfo.OriginalPart:IsDescendantOf(workspace.Map.Voxels) then
                        --partInfo.OriginalPart:SetAttribute('Unvoxable', true)
                    --end
                
                    Parent = Holder
                    partInfo.Parent = Holder

                    for _, voxelInfo in VoxelInfoTable do
                        voxelInfo.Parent = Holder
                    end
                else
                    local part
                    local tagged = CS:GetTagged(partInfo.Parent:GetTags()[2])
                    for _, v in tagged do
                        if v:IsA("Part") then
                            part = v
                        end
                    end
                    if part then
                        partInfo.OriginalPart = part
                    end
                end
            end
            
            Destroy(Parent, partInfo.ResetTime)
            Restore(partInfo, partInfo.ResetTime)
            
            -- if partInfo.AlreadyExistsInWorkspace then continue end
            
            --warn(Parent)
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
		end
	end

	warn(#Constructed, Constructed)
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
	Part.Parent = cacheFolder.ObjectCache
	cache:ReturnPart(Part)
end

return PartConstructor