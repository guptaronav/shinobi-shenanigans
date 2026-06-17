local service = {}

type Character = Model

-- Adds the priorities folder to the character
function service.Init(char: Character)
	local WalkSpeedPriorities = Instance.new('Folder')
	WalkSpeedPriorities.Name = 'WalkspeedPriorities'
	WalkSpeedPriorities.Parent = char
end

--[=[
	Creates a WalkSpeed priority with the given parameters.

	(Example)
    Priorities:
    - 1: Run/Walk
    - 2: Blocking
    - 3: Punching/Other basic combat actions
    - 4: Minor actions
    - 5: Intermediate actions
    - 6: Major actions
    - 7-8: Free
    - 9: Awakening
    - 10: Stun
]=]
function service.SetWalkspeed(char: Character, id: string, priority: number, walkSpeed: number)
	local hum = char.Humanoid
	local priorities = char.WalkspeedPriorities:GetChildren()

	-- Checks to see if the priority of the same ID already exists. If so, it removes it.
	if char.WalkspeedPriorities:FindFirstChild(id) then
		char.WalkspeedPriorities:FindFirstChild(id):Destroy()
	end

	-- Creates a priority intValue which will stay until deleted
	local newPriority = Instance.new('IntValue')
	newPriority.Value = priority
	newPriority.Name = id
	newPriority.Parent = char.WalkspeedPriorities

	-- Stores the WalkSpeed value
	local wValue = Instance.new('NumberValue')
	wValue.Name = 'WalkSpeed'
	wValue.Value = walkSpeed
	wValue.Parent = newPriority

	-- Checks to see if the new priority is higher than the current priority. If so, it updates the walkspeed
	local update: boolean = true
	for _, v in priorities do
		if v.Value > priority then update = false; break end
	end

	if update then
		hum.WalkSpeed = walkSpeed
	end
end

-- Ends the WalkSpeed priority of the given ID
function service.EndWalkspeed(char: Character, id: string)
	local hum = char.Humanoid

	local foundPriority = char.WalkspeedPriorities:FindFirstChild(id)
	if foundPriority then
		local priority = foundPriority.Value

		-- Removes the priority from the list of priorities before iterating through them
		foundPriority:Destroy()

		local priorities = char.WalkspeedPriorities:GetChildren()

		-- Finds the currently highest priority to switch the WalkSpeed to, else it defaults to the game designated WalkSpeed 
		local highest: NumberValue = Instance.new('NumberValue'); highest.Value = -1
		for _,v in priorities do
			if v.Value > priority then return end
			if v.Value > highest.Value and v.Value <= priority then
				highest = v
			end
		end

		-- Sets the new WalkSpeed
		if highest.Value ~= -1 then
			hum.WalkSpeed = highest.WalkSpeed.Value
		else
			hum.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed
		end
	end
end

return service
