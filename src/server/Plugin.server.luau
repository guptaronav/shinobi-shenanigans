local toolbar = plugin:CreateToolbar('Camera Unit')
local pluginButton = toolbar:CreateButton(
	"Camera To Part Snapshots", --Text that will appear below button
	"Create a snapshot between a part and the camera.", --Text that will appear if you hover your mouse on button
	"rbxassetid://8740888472") --Button icon

local repStorage = game.ReplicatedStorage
local snapshots = repStorage:FindFirstChild('CameraUnitSnapshots')
if not snapshots then
	snapshots = Instance.new('Folder')
	snapshots.Name = 'CameraUnitSnapshots'
	snapshots.Parent = repStorage
end

local SelectionService = game:GetService('Selection')

local info = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float, --From what side gui appears
	false, --Widget will be initially enabled
	false, --Don't overdrive previouse enabled state
	200, --default weight
	300, --default height
	150, --minimum weight (optional)
	150 --minimum height (optional)
)

local widget = plugin:CreateDockWidgetPluginGui(
	"CameraUnit", --A unique and consistent identifier used to storing the widget’s dock state and other internal details
	info --dock widget info
)

widget.Title = 'Camera Unit'

--- PROCESS

local part = nil
local partNameCon
local folder = nil
local folderNameCon

local gui = script.Parent:WaitForChild('Frame')
gui.Parent = widget
local spLabel = gui:WaitForChild('SelectedPartLabel')
local sfLabel = gui:WaitForChild('SelectedFolderLabel')

local camUnitSample = script.Parent:WaitForChild('CameraUnit')

local function NewSelection()
	local selections = SelectionService:Get()
	if #selections == 1 then
		local obj = selections[1]
		
		if obj:IsA('BasePart') and not obj:GetAttribute('CameraUnitContainer') then 
			part = obj
			spLabel.Text = 'Selected Part: <b>'..part.Name..'</b>'
			
			if partNameCon then partNameCon:Disconnect() end
			partNameCon = part:GetPropertyChangedSignal('Name'):Connect(function()
				spLabel.Text = 'Selected Part: <b>'..part.Name..'</b>'
			end)
		elseif obj:IsA('BasePart') and obj:GetAttribute('CameraUnitContainer') then
			folder = obj
			sfLabel.Text = 'Selected container: <b>'..obj.Name..'</b>'
			
			if folderNameCon then folderNameCon:Disconnect() end
			folderNameCon = folder:GetPropertyChangedSignal('Name'):Connect(function()
				sfLabel.Text = 'Selected container: <b>'..obj.Name..'</b>'
			end)
		elseif obj:IsA('Folder') and obj:FindFirstAncestor(snapshots.Name) then
			folder = obj
			sfLabel.Text = 'Selected Folder: <b>'..obj.Name..'</b>'
			
			if folderNameCon then folderNameCon:Disconnect() end
			folderNameCon = folder:GetPropertyChangedSignal('Name'):Connect(function()
				sfLabel.Text = 'Selected container: <b>'..obj.Name..'</b>'
			end)
		end
	end
end

SelectionService.SelectionChanged:Connect(NewSelection)
NewSelection()

gui:WaitForChild('Create').Activated:Connect(function()
	if not part or not folder then return end
	
	local snapshotName = gui.NameField.Text
	if snapshotName == '' then
		snapshotName = 'Snapshot '..#snapshots:GetChildren()
	end
	gui.NameField.Text = ''
	
	local camera = workspace.Camera
	
	local snapshot = camUnitSample:Clone()
	snapshot.CFrame = camera.CFrame
	snapshot.Name = snapshotName
	
	if folder:IsA('Folder') then
		local newContainer = part:Clone()
		newContainer.Parent = folder.Parent
		newContainer.Name = folder.Name
		newContainer:ClearAllChildren()
		newContainer.Transparency = 1
		newContainer.CanCollide = false
		newContainer.CanQuery = false
		newContainer.Anchored = false
		folder:Destroy()
		folder = newContainer
		folder:SetAttribute('CameraUnitContainer', true)
		folder:SetAttribute('WeldOnto', part.Name)
		
		sfLabel.Text = 'Selected container: <b>'..newContainer.name..'</b>'
	end
	
	local weld: WeldConstraint = Instance.new('WeldConstraint')
	weld.Part0 = snapshot
	weld.Part1 = folder
	weld.Parent = snapshot
	
	snapshot.Parent = folder
end)

gui:WaitForChild('InstructionsButton').Activated:Connect(function()
	gui:WaitForChild("Instructions").Visible = true
end)

gui:WaitForChild('Instructions'):WaitForChild("Close").Activated:Connect(function()
	gui.Instructions.Visible = false
end)


pluginButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	NewSelection()
end)