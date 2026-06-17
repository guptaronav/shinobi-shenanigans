--[VoxBreaker V 2.0, Written by @Bartokens, purely in Luau]

--    ▄   ████▄     ▄  ███   █▄▄▄▄ ▄███▄   ██   █  █▀ ▄███▄   █▄▄▄▄ 
--     █  █   █ ▀▄   █ █  █  █  ▄▀ █▀   ▀  █ █  █▄█   █▀   ▀  █  ▄▀ 
--█     █ █   █   █ ▀  █ ▀ ▄ █▀▀▌  ██▄▄    █▄▄█ █▀▄   ██▄▄    █▀▀▌  
-- █    █ ▀████  ▄ █   █  ▄▀ █  █  █▄   ▄▀ █  █ █  █  █▄   ▄▀ █  █  
--  █  █        █   ▀▄ ███     █   ▀███▀      █   █   ▀███▀     █   
--   █▐          ▀            ▀              █   ▀             ▀    
--   ▐                                      ▀                     

--[MAJORLY IMPORTANT] The module is currently not finished. There is one major bug where the module will just not create parts and leave empty chunks. 
--Additionally, there a few key features which have not been added yet, such as textures being applied to voxels and greedy meshing

--[<INTRO>]-----------------------
--VoxBreaker is a Voxel Destruction module made by @Bartokens. It's free to use but please credit me for any project you use it in.
--With VoxBreaker, you can do heavily optimized Voxel Destruction on either the server or the client, similar to what you see in a game like Teardown.
--See the original DevForum Post for more details, Examples, and Updates: https://devforum.roblox.com/t/voxbreaker-an-oop-voxel-destruction-module/2935099/

--[<HOW TO USE>]-----------------------

--1.Put VoxBreaker wherever you'd like. I reccommend replicated storage for reference on both the server and the client.
--But if you'd like it to be server exclusive then just put it in server storage
--2. Give any part you'd like to be checked by the module the tag "Destroyable". The tag name can be changed in the module settings
--3. You can now use any of the module's methods for Voxel Destruction.

--[IMPORTANT] Make sure all parts you tag are block shaped. Ball, Cylinder, and Wedge shaped parts will not work.
--[IMPORTANT] While optional, you should anchor your destructive parts to prevent some weird looking results.


--[<METHODS>]-----------------------

-- The module currently has 4 methods, one of which is OOP based.

--		* VoxelizePart()
--			Repeatedly voxelizes a part until it meets the specified voxel size

--      		-Parameters: (Part : Part, MinimumVoxelSize : number, TimeToReset : number)
--					Part: Describes the part being voxelized
--					MinimumVoxelSize: Minimum possible size that Voxels can have. Module will try to match that size as accurately as possible. 5 by default.
--					TimeToReset: Time it takes in seconds to reset voxels back to normal. Will not reset if this is less than zero. 50 by default.

--				-Returns all voxels
--			

--			   -[EXAMPLE CODE] -- Prints all parts after voxelization
--				|	local VoxBreaker = require(game.ReplicatedStorage.VoxBreaker)						
--				|	local Part = workspace.Part
--				|	local Voxels = VoxBreaker:VoxelizePart(Part)
--				|	for i, v in pairs(Voxels) do
--				|		print(v)
--				|	end
--				|

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--		* CreateHitbox()
--			Creates one hitbox which divides any applicable parts that are touching it.


--      		-Parameters: (Size : Vector3, Cframe : CFrame , Shape : Enum.PartType , MinimumVoxelSize : number , TimeToReset : number,  Params : OverlapParams)
--					Size: Size of the hitbox. (1,1,1) By default
--					Cframe: CFrame of the hitbox. (0,0,0) By default
--					Shape: Shape of the hitbox. Block by default.
--					MinimumVoxelSize: Minimum possible size that Voxels can have. Module will try to match that size as accurately as possible. 5 by default.
--					TimeToReset: Time it takes in seconds to reset voxels back to normal. Will not reset if this is less than zero. 50 by default.

--				-Tip: the larger the hitbox is, the larger I reccommend setting the MinimumVoxelSize. This helps tremendously with performance.

--				-Returns all voxels touching the hitbox
--			

--			   -[EXAMPLE CODE] --Destroys all voxels in hitbox.
--				|	local VoxBreaker = require(game.ReplicatedStorage.VoxBreaker)						
--				|	local Size = Vector3.new(10,10,10)
--				| 	local Cframe = CFrame.new(5,5,5)
--				| 	local Shape = Enum.PartType.Ball
--				| 	local MinimumSize = 8
--				|	local Seconds = 20
--				|
--				|	local Voxels = VoxBreaker:CreateHitbox(Size,Cframe,Shape,MinimumSize,Seconds)
--				|   VoxBreaker:ReturnPart(Voxels)
--				|
--			   -[EXAMPLE CODE] -- Unanchors all voxels in hitbox.
--				|	local VoxBreaker = require(game.ReplicatedStorage.VoxBreaker)						
--				|
--				|	local Voxels = VoxBreaker:CreateHitbox()
--				|	for i, v in pairs(Voxels) do
--				|		v.Anchored = false
--				|	end
--				|

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--		* CreateMoveableHitbox() --OOP BASED
--			Creates a moveable hitbox that can be controlled manually or welded to a specified part.

--      		-Parameters: (MinimumVoxelSize : number, TimeToReset : number, Size : Vector3, Cframe : CFrame , Shape : Enum.PartType, Params : OverlapParams )
--					MinimumVoxelSize: Minimum possible size that Voxels can have. Module will try to match that size as accurately as possible. 5 by default.
--					TimeToReset: Time it takes in seconds to reset voxels back to normal. Will not reset if this is less than zero. 50 by default.
--					Size: Size of the hitbox. (1,1,1) By default
--					Cframe: CFrame of the hitbox. (0,0,0) By default
--					Shape: Shape of the hitbox. Block by default.

				--Note, you can set the minimum voxel size to 'Relative', and the minimum size will change depending on the size of the hitbox.


--				-Returns hitbox object
					
--				-Events:
--					.Touched(Parts)
--						Fires on every frame that the hitbox is touching applicable parts.
--						The parts argument contains the parts being touched.
--				-Functions:
--					:Start()
--						Starts the moveable hitbox.
--					:Stop()
--						Stops the moveable hitbox.
--					:Destroy()
--						Destroys the moveable hitbox.
--					:GetTouchingParts()
--						returns all parts touching the hitbox.
--					:WeldTo(Part,Offset)
--						Welds the hitbox to a specified part.
--					:UnWeld()
--						Unwelds the hitbox


--			   -[EXAMPLE CODE] --Creates a hitbox that is welded to a part and prints whenever touched
--				|
--				|	local VoxBreaker = require(game.ReplicatedStorage.VoxBreaker)						
--				|	local Size = Vector3.new(10,10,10)
--				| 	local Cframe = CFrame.new(5,5,5)
--				| 	local Shape = Enum.PartType.Ball
--				| 	local MinimumSize = 8
--				|	local Seconds = 20
--				|	local Projectile = Instance.new("Part")
--				| 	Projectile.Parent = workspace
--				|	
--				|	local Hitbox = VoxBreaker.CreateMoveableHitbox(MinimumSize,Seconds,Size,Cframe,Shape)
--				|	Hitbox:Start()
--				|	Hitbox:WeldTo(Projectile)
--				|	Hitbox.Touched:Connect(function()
--				|		print("Touched")
--				|	end)
--				|
--				|
--			   -[EXAMPLE CODE] -- Creates a hitbox that can be moved manually, and stops after 5 seconds
--				|
--				|	local VoxBreaker = require(game.ReplicatedStorage.VoxBreaker)						
--				|	local Size = Vector3.new(10,10,10)
--				| 	local Cframe = CFrame.new(5,5,5)
--				| 	local Shape = Enum.PartType.Ball
--				| 	local MinimumSize = 8
--				|	local Seconds = 20
--				|	local Projectile = Instance.new("Part")
--				| 	Projectile.Parent = workspace
--				|
--				|	local Hitbox = VoxBreaker.CreateMoveableHitbox(nil,MinimumSize,Seconds,Size,Cframe,Shape)
--				|	Hitbox:Start()
--				|	Hitbox.Part.Position = Vector3.new(10,10,10)
--				|	task.wait(2)
--				|	print(Hitbox:GetTouchingParts())
--				|	task.wait(3)
--				|	
--				|	Hitbox:Stop()
--				|



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--		* ReturnPart()
--			Used to return Voxels to cache. Only works when cache is enabled.
--      		-Parameters: (Part : Part | {Part} )
--					Part: Part to return. Can be a single part or a table of parts.


--[<TIPS>]------------------------------

--[TIP] You can easily tag all your parts by pasting this code into the command bar: 
--{
		--for i,v in ObjectReference:GetDescendants() do 
			--if v:IsA("Part") and v.Shape == Enum.PartType.Block then
			--	v:AddTag("Your Tag Name")
			--end
		--end
--}


--[TIP] When it comes to physics replication with Voxels, I suggest creating Voxels on the server and then cloning them on the client. The easiest way to do this is:
--{
	--[SERVER]
		--local Voxels = {} --Your Voxel Table
		--for _,Voxel in Voxels do --Loop Through table
		--	Voxel.Parent = game.ReplicatedStorage --Parent them to replicated storage so the client can reference them.
		--end
		--RemoteEvent:FireAllClients(Voxels) --Fire Voxels to client with a remote event.
		--VoxBreaker:ReturnPart(Voxels) --Returns them to the cache. Destroy them instead if you have cache disabled.
		
	--[CLIENT]
		--RemoteEvent.OnClientEvent:Connect(function(Voxels) --Connect to remote event
		--	for _,Voxel in Voxels do --Loop through Voxels
		--		local Clone = Voxel:Clone() --Clone each voxel
		--		Clone.Parent = workspace 
		--	end
		--end)

--}

--[TIP] Instead of just destroying Voxels, you can use :ReturnPart() to return them to the cache. This saves a ton on performance, though this only works if you have cache enabled.

--[TIP] The module has several types for you to reference when working with Voxels. Check them out under the Types module.
