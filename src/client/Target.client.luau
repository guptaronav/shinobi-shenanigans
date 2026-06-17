local UserInputService = game:GetService('UserInputService')

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

local mouse: Mouse = player:GetMouse()
local target: Model
local DISTANCE_LIMIT = 100

game.ReplicatedStorage.Remotes.GetTarget.OnClientInvoke = function(filterList: table, whitelist: boolean?)
    local shiftlockOn = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
    -- print(shiftlockOn)
    local finalPos = not shiftlockOn and mouse.Hit.Position or char.HumanoidRootPart.Position + char.HumanoidRootPart.CFrame.LookVector

    local unit = (finalPos - char.HumanoidRootPart.Position).Unit

    local distances = {
       .05, .1, .15, .2, .25, .3, .4, .5, .65, .8, 1
    }

    -- local tParams = RaycastParams.new()
    -- tParams.FilterDescendantsInstances = {workspace.Characters}
    -- tParams.FilterType = Enum.RaycastFilterType.Include

    local closest, closestDistance = nil, 5.1

    -- print(filterList)

    for _,v in distances do
        closestDistance = 5.1

        local pos = char.HumanoidRootPart.Position + unit * (DISTANCE_LIMIT * v)
        -- print('Distance: '..v)
        
        for _, subject in workspace.Characters:GetChildren() do
            if not subject:FindFirstChild('HumanoidRootPart') or subject == char then continue end
            if filterList then
                local inList = table.find(filterList, subject)
                if whitelist and not inList then continue end
                if not whitelist and inList then continue end
            end

            local subDistance = (subject.HumanoidRootPart.Position - pos).Magnitude
            -- print(subDistance, subject)
            if subDistance < closestDistance then
                closestDistance = subDistance
                closest = subject
                break
            end
        end
        
        if closest then break end
    end

    print(closest)

    return closest
end