local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getWorkspace()
	local ws = game:GetService("Workspace")
	if not ws then
		warn("[EquipHeadbands] Workspace service not available yet, retrying...")
		task.wait(0.5)
		return getWorkspace()
	end
	return ws
end

local function main()
	local workspace = getWorkspace()
	if not workspace then return end

	local NarutoHeadband = ReplicatedStorage:WaitForChild("NarutoHeadband")
	local Characters = workspace:WaitForChild("Characters")

	local function equipHeadband(character: Model)
		if not character:IsA("Model") then return end
		if character:FindFirstChild("NarutoHeadband") then return end

		local head = character:FindFirstChild("Head")
		if not head or not head:IsA("BasePart") then return end

		local headband = NarutoHeadband:Clone()
		headband.Name = "NarutoHeadband"

		local attachmentOffset = CFrame.new(0, 0.25, 0) * CFrame.Angles(0, 0, math.rad(-6))
		headband.CFrame = head.CFrame * attachmentOffset

		local weld = Instance.new("Weld")
		weld.Part0 = head
		weld.Part1 = headband
		weld.C0 = attachmentOffset:Inverse()
		weld.C1 = CFrame.identity
		weld.Parent = character

		headband.Parent = character
	end

	for _, char in Characters:GetChildren() do
		task.spawn(equipHeadband, char)
	end

	Characters.ChildAdded:Connect(equipHeadband)
end

task.spawn(main)
