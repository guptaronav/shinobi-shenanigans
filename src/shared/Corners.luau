local module = {}

function module.load(notification)
	local FrameCorner = Instance.new("UICorner")
	local ButtonCorner = Instance.new("UICorner")
	FrameCorner.CornerRadius = UDim.new(0, 5)
	FrameCorner.Parent = notification.Frame
	ButtonCorner.CornerRadius = UDim.new(0, 5)
	ButtonCorner.Parent = notification.Frame.TestButton
end

return module