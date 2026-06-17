--[[ //

 ______     ______     ______     __     ______     ______     ______     __  __    
/\  == \   /\  ___\   /\  == \   /\ \   /\  __ \   /\  == \   /\  ___\   /\ \/ /    
\ \  __<   \ \  __\   \ \  __<   \ \ \  \ \ \/\ \  \ \  __<   \ \  __\   \ \  _"-.  
 \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \_\  \ \_____\  \ \_\ \_\  \ \_____\  \ \_\ \_\ 
  \/_/ /_/   \/_____/   \/_/ /_/   \/_/   \/_____/   \/_/ /_/   \/_____/   \/_/\/_/ 
                                                                                    
Made by:
VanishedRerio @3MaksiO3pro

XRNotifications 
Version 1.3

docs

--// LoadGui

	local notifications = require(game.ReplicatedStorage.Notifications)
	notifications:LoadGui(game.Players.LocalPlayer)
	
--// Creating a new notification and notifing the player

	local notifications = require(game.ReplicatedStorage.Notifications)
	local notify = notifications.new({
		Description = "Test notification",
	})
	
	notify:Notify()
	
-- Adding buttons (max 2)

	notify:AddButton("Ok", function()
		--// scripting here
	end)
	
-- On Notifing Event

	notify.Notified:Connect(function()
		--// scripting here
	end)
	
	
API:

// notifications.new(table)
Creates new notification

// :Notify()
Displays the notification on screen


--// Inside the table

// Theme: ModuleScript,

// Description: string,

// Image: number,

// Viewport: {

	Distance: number,
	
	Rotatable: boolean,
	
	Speed: number,
	
	Model: Instance,
	
},

// Duration: number,

// Sound: number,

New documentation soon i think

// ]]

local notification = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = game.Players.LocalPlayer

local types = require(script.types)
local Signal = require(script.Signal)
local Maid = require(script.Maid)

export type XRNT = types.XRNT

function notification:LoadGui(Player : Player)
	local NotificationsUI = script.Gui.Notifications:Clone()
	NotificationsUI.Parent = Player.PlayerGui
end

function notification.new(Table : XRNT?)
	local self = {}
	setmetatable(self, notification)
	local buttons = {}
	
	local maid = Maid.new()
	self.Notified = maid:give(Signal.new())
	
	function self:AddButton(Text : string, func : string)
		-- // Ill mess with it later
		if #buttons >= 2 then
			error("Too Many buttons")
		else
			table.insert(buttons, {
				Text = Text;
				func = func;
			})
		end
	end
	
	function self:Notify()
		task.spawn(function()
			local CanHide = true
			local CanClick = true
			local debounce = false
			local runningcamera = nil
			local NewNotification = script.Gui.Notification:Clone()
			if Table.Theme ~= nil then
				require(script.Themes[Table.Theme]).load(NewNotification)
			end
			NewNotification.Parent = Player.PlayerGui:WaitForChild("Notifications").Main.List
			TweenService:Create(NewNotification.Frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0, -150, 0, 0) }):Play()
			NewNotification.Frame.Description.Text = Table.Description
			self.Notified:Fire()
			
			if Table.Sound ~= nil then
				task.spawn(function()
					local Sound = Instance.new("Sound")
					Sound.SoundId = "rbxassetid://"..Table.Sound
					Sound.Parent = NewNotification
					Sound.Volume = 0.5
					Sound:Play()
				end)
			end
			

			if Table.Viewport ~= nil then
				local ModelClone = Table.Viewport.Model:Clone()
				local Camera = Instance.new("Camera")
				ModelClone.Parent = NewNotification:WaitForChild("Frame").ViewportFrame
				Camera.Parent = NewNotification:WaitForChild("Frame").ViewportFrame
				NewNotification:WaitForChild("Frame").ViewportFrame.CurrentCamera = Camera
				NewNotification.Frame.Description.Position = UDim2.new(0, 100, 0, 10)
				NewNotification.Frame.Description.Size = UDim2.new(1, -110, 1, -20)
				if Table.Viewport.Rotatable then
					runningcamera = RunService.RenderStepped:Connect(function(dt)
						-- // Ill mess with it later
						local Rotation = 0.05 / Table.Viewport.Speed
						Camera.CFrame = CFrame.new(0, 0, Table.Viewport.Distance)
						ModelClone.CFrame *= CFrame.Angles(0, Rotation, 0)
					end)
				end
			elseif Table.Image ~= nil then
				NewNotification.Frame.Description.Position = UDim2.new(0, 100, 0, 10)
				NewNotification.Frame.Description.Size = UDim2.new(1, -110, 1, -20)
				NewNotification.Frame.Icon.Image = "rbxassetid://"..Table.Image
			else
				NewNotification.Frame.Description.Position = UDim2.new(0, 10, 0, 10)
				NewNotification.Frame.Description.Size = UDim2.new(1, -20, 1, -20)
			end
			
			if #buttons > 0 then
				NewNotification.Size = UDim2.new(0, 0, 0, 135)
				for i, button in buttons do
					local newButton = NewNotification.Frame.TestButton:Clone()
					if i > 1 then
						newButton.Position = UDim2.new(1 / i, 0, 0, 105)
					else
						newButton.Position = UDim2.new(0, 0, 0, 105)
					end
					if i == #buttons then
						newButton.Size = UDim2.new(1 / #buttons, 0, 0, 30)
					else
						newButton.Size = UDim2.new(1 / #buttons, -5, 0, 30)
					end
					newButton.Visible = true
					newButton.Parent = NewNotification.Frame
					newButton.Text = buttons[i].Text
					newButton.MouseButton1Click:Connect(function()
						if CanClick then
							CanHide = false
							CanClick = false
							buttons[i].func()
							TweenService:Create(NewNotification.Frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0, 150, 0, 0) }):Play()
							task.wait(0.5)
							if runningcamera ~= nil then
								runningcamera:Disconnect()
							end
							NewNotification:Destroy()
						end
					end)
				end
			else
				NewNotification.Size = UDim2.new(0, 0, 0, 100)
			end
			
			CanClick = true

			if Table.Duration ~= nil then
				task.wait(Table.Duration)
			else
				task.wait(5)
			end

			CanClick = false
			
			if CanHide then
				TweenService:Create(NewNotification.Frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0, 150, 0, 0) }):Play()
				task.wait(0.5)
				if runningcamera ~= nil then
					runningcamera:Disconnect()
				end
				NewNotification:Destroy()
			end
		end)
	end
	
	return self
end

return notification 