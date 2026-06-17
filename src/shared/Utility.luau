

local eq
eq = {
	GiveCommas = function(amount)
		amount= tostring(amount)
		local formatted = amount
		local k
		while true do 
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
			if (k==0) then
				break
			end
		end
		return formatted
	end,
	ElementAmount = function(t, matchString)
		if matchString then
			local n = 0
			for i,_ in pairs(t) do
				if tostring(i):split("_")[1] == matchString then
					n += 1
				end
			end
			return n
		else
			local n = 0
			for _,_ in pairs(t) do
				n += 1
			end
			return n
		end
	end,
	CutFloats = function(raw: number, amount)
		local cutRaw = tostring(raw):split(".")[2]
		if not cutRaw then return raw end
		local cut = cutRaw:sub(1, amount or 2)
		return tostring(raw):split(".")[1].."."..cut
	end,
	Lerp = function(p0, p1, t)
		return (1-t)*p0 + t*p1
	end,
	Quad = function(p0, p1, p2, t)
		local l1 = eq.Lerp(p0,p1,t)
		local l2 = eq.Lerp(p1, p2, t)
		return eq.Lerp(l1,l2,t)
	end,
	CFrameTurn= function(mycframe, -- current cframe
		V3		  -- orientation offset-- Example: if u want to turn left, the V3 should be {X = 0, Y = 90, Z = 0}
	)
		return mycframe:ToWorldSpace(
			CFrame.Angles(	math.rad(V3.X),math.rad(V3.Y),math.rad(V3.Z)))
	end,
	CircleAround = function(radius, angle, source)
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local newCFrame = (source.CFrame * CFrame.new(x, 0, z)).p
		return CFrame.lookAt(newCFrame, source.Position)
	end,
	ColorPresets = {
		["Red"] = Color3.new(1, 0, 0), -- Default
		["Blue"] = Color3.new(0, 0, 1), -- Default
		["Green"] = Color3.new(0, 1, 0), -- Default
		["Forest"] = Color3.new(0, 0.541176, 0.0352941),
		["White"] = Color3.new(1, 1, 1),
		["Black"] = Color3.new(0, 0, 0),
		["Orange"] = Color3.new(1, 0.333333, 0),
		["Sunset"] = Color3.new(1, 0.705882, 0.341176),
		["Purple"] = Color3.new(0.541176, 0, 0.756863),
		["Sky"] = Color3.new(0, 1, 0.917647),
		["Pigment"] = Color3.new(0.584314, 0.611765, 1),
		["Lavender"] = Color3.new(0.760784, 0.560784, 1), -- Default
		["Pink"] = Color3.new(1, 0.415686, 0.717647),
		["Blurple"] = Color3.new(0.737255, 0.647059, 1),
		["Brown"] = Color3.new(0.345098, 0.176471, 0.0117647), -- Default
		["Coffee"] = Color3.new(0.819608, 0.666667, 0.533333),
		["Navy"] = Color3.new(0.0823529, 0.0862745, 0.313725),
		["Lime"] = Color3.new(0.654902, 1, 0.505882),
		["Supporter"] = Color3.new(1, 0.933333, 0.580392),
		["Cyan"] = Color3.new(0.27451, 1, 0.611765), -- Default
		["Lemonade"] = Color3.new(0.843137, 1, 0.133333),
		["Princess"] = Color3.new(1, 0.490196, 0.960784),
		["Blood"] = Color3.new(0.439216, 0, 0),
		["Rage"] = Color3.new(1, 0.560784, 0.0235294),
		["Gray"] = Color3.new(0.564706, 0.564706, 0.564706), -- Default for testers
		["Artic"] = Color3.new(0, 0.564706, 0.545098),
		["Rust"] = Color3.new(0.219608, 0.196078, 0),
		["Yellow"] = Color3.new(1, 1, 0), -- Default
		["Magenta"] = Color3.new(1,0,1), -- Default
		["Bagel"] = Color3.new(0.670588, 0.443137, 0.027451),
	},
	GetHit = function(hit: BasePart)
		local target = hit:FindFirstChild("Humanoid")
		target = hit.Parent and hit.Parent:FindFirstChild("Humanoid")
		if target and hit.Parent ~= workspace then
			return hit.Parent
		end
	end,
	ChangeMaterial = function(part: BasePart, material: Enum.Material, revert: boolean, dontHidePart: boolean)
		if not revert then
			--Clones the players head and sets the original head to be transparent
			local fakePart = part.Name ~= "Head" and part:Clone() or game.ReplicatedStorage.Assets.VFX.FakeHead:Clone()
			fakePart.Parent = workspace.Effects
			fakePart.Name = "fakepart"
			fakePart.Material = material
			fakePart.CanQuery = false
			fakePart.CanCollide = false
			fakePart.CanTouch = false

			--Deleting all the irrelevant items in the head like the attachments, motor6d, etc. And just keeping the face
			for _, p in pairs(fakePart:GetChildren())do
				if(p.Name ~= "face")then
					p:Destroy()
				end
			end

			local objValue = Instance.new("ObjectValue")
			objValue.Name = "RealPart"
			objValue.Value = part
			objValue.Parent = fakePart

			--	part:GetPropertyChangedSignal("Color"):Connect(function()
			--		fakePart.Color = part.Color
			--	end)

			part.Transparency = not dontHidePart and 1 or part.Transparency
			if dontHidePart then
				fakePart.Size += Vector3.new(.01,.01,.01)
			end

			--IMPORTANT PART
			--Creating a weld constraint to connect the new fake head onto the player
			fakePart.CFrame = part.CFrame
			local WeldConstraint = Instance.new("WeldConstraint")
			WeldConstraint.Parent = fakePart
			WeldConstraint.Part0 = fakePart
			WeldConstraint.Part1 = part

			return fakePart
		else
			for i,v in pairs(workspace.Effects:GetChildren()) do
				if v.Name == "fakepart" and v:FindFirstChild("RealPart") and v.RealPart.Value == part then
					v:Destroy()
				end
			end
			part.Transparency = 0
		end

	end,
	CheckDistance = function(a, b, cap, invert)
		a = typeof(a) == "Vector3" and a or a:FindFirstChild("HumanoidRootPart") and a.HumanoidRootPart.Position or a.Position
		b = typeof(b) == "Vector3" and b or b:FindFirstChild("HumanoidRootPart") and b.HumanoidRootPart.Position or b.Position
		if not invert then
			return (a - b).Magnitude <= cap
		else
			return (a - b).Magnitude >= cap
		end
	end,
	ApplyToNearUsers = function(origin, distance, callback)
		for i,v in pairs(workspace.Attackable:GetChildren()) do
			if v:FindFirstChild('Humanoid') and v:FindFirstChild('Effects') then
				if eq.CheckDistance(v.HumanoidRootPart, origin, distance) then
					task.spawn(callback, v)
				end
			end
		end
	end,
	Weld = function(a:Part, b:Part, contraintType: Constraint)
		local weld = Instance.new(contraintType or "WeldConstraint")
		if not contraintType then
			weld.Part0 = a
			weld.Part1 = b
		end
		weld.Parent = a
		return weld
	end,
	FaceVector = function(normalId, part: Part)
		local faces = {
			["Front"] = part.CFrame.LookVector,
			["Back"] = -part.CFrame.LookVector,
			["Top"] = part.CFrame.UpVector,
			["Bottom"] = -part.CFrame.UpVector,
			["Right"] = part.CFrame.RightVector,
			["Left"] =-part.CFrame.RightVector,
		}
		return faces[normalId.Name]
	end,
	RandomTableValue = function(t, seed) -- getting a random value from dictionaries (indexes are strings)
		local array = {}
		for i,v in pairs(t) do
			table.insert(array, v)
		end
		return array[(seed and Random.new(seed):NextInteger(1, #array) or Random.new():NextInteger(1, #array))]
	end,
	Cutscene = function(duration)
		local cutscenegui = game.Players.LocalPlayer.PlayerGui.Cutscene
		local ts =game:GetService("TweenService")
		ts:Create(cutscenegui.Bottom,TweenInfo.new(.1),{Position = UDim2.new(0, 0,0.855,0)}):Play()
		ts:Create(cutscenegui.Top,TweenInfo.new(.1),{Position = UDim2.new(0, 0,0,0)}):Play()
		
		for _,v in pairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
			if v.Name ~= "Cutscene" then
			local oldValue = v.Enabled
			v.Enabled = false
			task.delay(duration,function()
				v.Enabled = oldValue
			end)
			end
		end
		
		task.delay(duration,function()
			ts:Create(cutscenegui.Bottom,TweenInfo.new(.1),{Position = UDim2.new(0, 0,1,0)}):Play()
			ts:Create(cutscenegui.Top,TweenInfo.new(.1),{Position = UDim2.new(0, 0,-.16,0)}):Play()
		end)
		
		-- errors..... get good smh fixed! -- real....i think
		
	end,
	Transition = function(duration,speed)
		
		local ts =game:GetService("TweenService")
		
		ts:Create(game.Players.LocalPlayer.PlayerGui.Transition.Frame,TweenInfo.new(speed,Enum.EasingStyle.Sine),{BackgroundTransparency = 0}):Play()
		wait(speed*2)
		ts:Create(game.Players.LocalPlayer.PlayerGui.Transition.Frame,TweenInfo.new(speed,Enum.EasingStyle.Sine),{BackgroundTransparency = 1}):Play()
		
	end,
	GetUtilMouse = function()
		local userInput = game:GetService("UserInputService")
		local Mouse = {}
		local RAY_DISTANCE = 3000 -- default ray distance like mouse.Hit
		local cam = workspace.CurrentCamera

		function Mouse.Hit(distance, raycastParams, originDepth)
			if not raycastParams then
				raycastParams = RaycastParams.new()
				raycastParams.FilterDescendantsInstances = {workspace.UnobstructiveAssets, (game.Players.LocalPlayer and game.Players.LocalPlayer.Character)} --{game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()}
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			end
			
			local inset = game.GuiService:GetGuiInset() 
			local mousePos = userInput:GetMouseLocation() - inset
			local viewportMouseRay = cam:ScreenPointToRay(mousePos.X, mousePos.Y, originDepth)
			local rayCastResult = workspace:Raycast(viewportMouseRay.Origin, viewportMouseRay.Direction * (distance or RAY_DISTANCE), raycastParams)
			local hitPosition
			if rayCastResult then
				hitPosition =  rayCastResult.Position
				return {Position = hitPosition, Unit = rayCastResult.Normal, Distance = rayCastResult.Distance, Instance = rayCastResult.Instance}
			else
				hitPosition = viewportMouseRay.Origin+viewportMouseRay.Direction * (distance or RAY_DISTANCE)
				return {Position = hitPosition, Unit = viewportMouseRay.Direction, Distance = (distance or RAY_DISTANCE)}

			end
		end
		return Mouse
	end,
	IsLooking = function(hit, humRoot, radius: number?, reverse: boolean?)
		local unit = (humRoot.Position - hit.HumanoidRootPart.Position).unit
		local lookVector = hit.HumanoidRootPart.CFrame.LookVector

		--print(unit:Dot(lookVector))
		if not reverse then
			if unit:Dot(lookVector) >= (radius or -.6) then return true else return false end
		else
			if unit:Dot(lookVector) <= (radius or -.6) then return true else return false end
		end
	end,
	AlignCharacter = function(char: Model, setDefault: boolean?): AlignOrientation
		local alignOrientation = Instance.new('AlignOrientation')
		alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		alignOrientation.Attachment0 = char.HumanoidRootPart.RootAttachment
		alignOrientation.Parent = char.HumanoidRootPart
		
		if setDefault then
			alignOrientation.MaxTorque = 100000
			alignOrientation.MaxAngularVelocity = 100
			alignOrientation.Responsiveness = 20
		end
		return alignOrientation
	end,
	GyroCharacter = function(char: Model, cframe: CFrame): BodyGyro
		local bodyGyro = Instance.new('BodyGyro')
		bodyGyro.CFrame = cframe
		return bodyGyro
	end,
}

return eq
