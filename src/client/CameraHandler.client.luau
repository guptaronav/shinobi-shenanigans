local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local head = char:WaitForChild('Head')
local hum = char:WaitForChild('Humanoid')

local camera = workspace.CurrentCamera

local settingsData = player:WaitForChild('Settings', 30)
local headFollowEnabled=  settingsData:WaitForChild('HeadCameraFollow')

local function UpdateHeadFollow(enable: boolean)
    if enable then
        camera.CameraSubject = head
    else
        camera.CameraSubject = hum
    end
end
UpdateHeadFollow(headFollowEnabled.Value)
headFollowEnabled.Changed:Connect(UpdateHeadFollow)

-------- SOUND SERVICE
local SoundService = game:GetService('SoundService')
-- SoundService:SetListener(Enum.ListenerType.ObjectCFrame, char:WaitForChild('HumanoidRootPart'))