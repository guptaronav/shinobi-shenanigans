--[[
	Update assembly bodyforces to our rootpart for assemblies that are network-owned by us.
	CFrame updates are applied every frame for optimal UX (no 'laggy'/'choppy' movement).
]]
local TAG = "CustomPlayerWeldAssemblyPart"

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

-- Update our rootpart on respawn, or change (probably not needed for most games, but handy)
local rootPart
local conn
local function charAdded(char)
	if conn then
		conn:Disconnect()
		conn = nil
	end
	-- Update on new rootpart added
	conn = char.ChildAdded:Connect(function(v)
		if v:IsA("BasePart") and v.Name == "HumanoidRootPart" then
			rootPart = v
		end
	end)
	
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end
	rootPart = root
end
charAdded(localPlayer.Character or localPlayer.CharacterAdded:Wait())
localPlayer.CharacterAdded:Connect(charAdded)

local assembliesToUpdate = {
	-- Format: assemblyRootPart = { alignOrientation, alignPosition }
}

-- Keep reference on stream in
CollectionService:GetInstanceAddedSignal(TAG):Connect(function(v)
	if v:GetAttribute("UserId") == localPlayer.UserId then
		local alignOrientation, alignPosition = v:WaitForChild("AlignOrientation", 10), v:WaitForChild("AlignPosition", 10)
		if not alignOrientation or not alignPosition then
			return	-- Unable to get forces within reasonable time frame -> cancel
		end
		assembliesToUpdate[v] = {  alignOrientation, alignPosition }
	end
end)
-- Remove on stream out
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(v)
	if assembliesToUpdate[v] then
		assembliesToUpdate[v] = nil
	end
end)

-- Update forces every frame before phsyics are calculated
RunService.Stepped:Connect(function()
	if not rootPart then
		return
	end
	local cf = rootPart.CFrame
	local pos = rootPart.CFrame.Position
	for _, v in pairs(assembliesToUpdate) do
		v[1].CFrame = cf
		v[2].Position = pos
	end
end)
