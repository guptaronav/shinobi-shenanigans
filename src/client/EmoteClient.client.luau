local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService('TweenService')
local UIS = game:GetService('UserInputService')

local AnimationService = require(ReplicatedStorage.Shared.Services.AnimationService)
local EmoteModule = require(ReplicatedStorage.Shared.Data.Emotes)
local EmoteData = EmoteModule.Emotes

local player = game.Players.LocalPlayer
repeat task.wait() until player:HasTag('Loaded')

local PlayerGui = player:WaitForChild('PlayerGui', 50)

local Data = player:WaitForChild('Data')
local EquippedEmotes = Data:WaitForChild('EquippedEmotes')
local OwnedEmotes = Data:WaitForChild('Emotes')

local MenuGui = PlayerGui:WaitForChild('Menu', 30)
local EmoteWheel: ImageLabel & Frame = MenuGui:WaitForChild('EmoteWheel')

local function OwnsEmote(emote: string)
    for _,v in OwnedEmotes:GetChildren() do
        if v.Value == emote then
            return true
        end
    end
end

local selectionMode: 'Shop' | 'Replace' = 'Replace'
local slotToReplace: number = 1

---- EMOTE WHEEL ----

local nameColors = {
    Admin = Color3.new(1, 0.298039, 0.298039),
    Rare = Color3.new(0.286274, 0.749019, 1),
    Legendary = Color3.new(1, 0.549019, 0.286274),
}

local function UpdateEmoteWheel()
    for _,slot in EmoteWheel:GetChildren() do
        if not slot then repeat task.wait() until slot end
        if not slot:IsA('ViewportFrame') then continue end

        local index = string.sub(slot.Name, 5,5)
        local emote: StringValue = EquippedEmotes:FindFirstChild(tostring(index))

        local emoteInfo = EmoteData[emote and emote.Value or 'Moonwalk']

        slot:WaitForChild('EmoteName').Text = emote and emote.Value or 'Moonwalk'
        if emoteInfo.Tier ~= 'Common' then
            slot.EmoteName.TextColor3 = nameColors[emoteInfo.Tier]
        else
            slot.EmoteName.TextColor3 = Color3.new(1,1,1)
        end

        local viewportCamera = slot:FindFirstChild('Camera')  
        if not viewportCamera then
            viewportCamera = Instance.new("Camera")
            viewportCamera.CameraType =Enum.CameraType.Scriptable
            slot.CurrentCamera = viewportCamera
            viewportCamera.Parent = slot
        end

        local subject = slot:FindFirstChild('WorldModel')
        if not subject then
            subject = Instance.new('WorldModel')
            subject.Parent = slot

            local rig =ReplicatedStorage.Assets.EmoteAssets.EmoteRig:Clone()
            rig.Parent = subject
            for _,v in rig:GetChildren() do
                v.Parent = subject
            end
            
            subject.PrimaryPart = subject.HumanoidRootPart
            rig:Destroy()
        else
            for _,v in subject:WaitForChild('Humanoid'):WaitForChild('Animator'):GetPlayingAnimationTracks() do
                v:SetAttribute('Disable', true)
                v:Stop()
            end
        end

        local humRoot = subject:WaitForChild('HumanoidRootPart')

        task.wait()

        AnimationService.RemoveHands(subject, 'Both')
        if emoteInfo.UsesHands then
            AnimationService.AddHands(subject, emoteInfo.UsesHands)
        end

        local anim: AnimationTrack = subject:WaitForChild('Humanoid'):WaitForChild('Animator'):LoadAnimation(emoteInfo.MainAnimation)
        anim:Play()
        -- print('playing?', anim.IsPlaying)
        if not anim.Looped then
            anim.Ended:Connect(function()
                if anim:GetAttribute('Disable') then return end
                task.wait(.5)
                anim:Play()
            end)
        end

        -- viewportCamera.CameraSubject = subject
        viewportCamera.CFrame = CFrame.lookAt(humRoot.Position + humRoot.CFrame.LookVector * 5 + Vector3.yAxis * .5, humRoot.Position)
    
        local button: TextButton = slot:WaitForChild('Button')
        local replaceTimer = os.clock()
        button.MouseButton1Down:Connect(function(x, y)
            replaceTimer = os.clock()
        end)
        button.MouseButton1Up:Connect(function()
            if os.clock() - replaceTimer < .3 then
                ReplicatedStorage.Remotes.Emote:FireServer(emote and emote.Value or 'Moonwalk')
                EmoteWheel.Visible = false
            else
                selectionMode = 'Replace'
                slotToReplace = index
                EmoteWheel.Visible = false
                MenuGui.EmoteShop.Visible = true
            end
        end)
    end
end

UpdateEmoteWheel()

EmoteWheel:WaitForChild('ShopButton').Activated:Connect(function()
    selectionMode = 'Shop'
    EmoteWheel.Visible = false
    MenuGui.EmoteShop.Visible = true
end)

---- EMOTE SHOP / SELECTION ----
local EmoteShopGui = MenuGui:WaitForChild('EmoteShop')
local EmoteSelectionGui = EmoteShopGui:WaitForChild('EmoteSelection')
local EmoteSlotRef = EmoteSelectionGui:WaitForChild('UIListLayout'):WaitForChild('EmoteSlot')
local ActionButton: TextButton = EmoteShopGui:WaitForChild('ActionButton')
local EmoteSelect: RemoteFunction = ReplicatedStorage.Remotes.EmoteSelect

local selectedEmote: string
local function UpdateEmoteSelection()
    for _, v in EmoteSelectionGui:GetChildren() do
        if v:IsA('ViewportFrame') then
            v:Destroy()
        end
    end

    for emote,data in EmoteData do

        local slot: ViewportFrame = EmoteSlotRef:Clone()
        slot:WaitForChild('EmoteName').Text = emote
        slot.Parent = EmoteSelectionGui
        -- if emoteInfo.Tier ~= 'Common' then
            -- slot.EmoteName.TextColor3 = nameColors[emoteInfo.Tier]
        -- end
        if data.Tier == 'Common' then
            slot.LayoutOrder = 2
        elseif data.Tier == 'Rare' then
            slot.LayoutOrder = 4
        elseif data.Tier == 'Legendary' then
            slot.LayoutOrder = 6
        elseif data.Tier == 'Admin' then
            slot.LayoutOrder = 8
            if not OwnsEmote(emote) then
                slot:Destroy()
                continue
            end
        else
            slot.LayoutOrder = 10
        end

        local viewportCamera = slot:FindFirstChild('Camera')  
        if not viewportCamera then
            viewportCamera = Instance.new("Camera")
            viewportCamera.CameraType =Enum.CameraType.Scriptable
            slot.CurrentCamera = viewportCamera
            viewportCamera.Parent = slot
        end

        local subject = slot:FindFirstChild('WorldModel')
        if not subject then
            subject = Instance.new('WorldModel')
            subject.Parent = slot

            local rig =ReplicatedStorage.Assets.EmoteAssets.EmoteRig:Clone()
            rig.Parent = subject
            for _,v in rig:GetChildren() do
                v.Parent = subject
            end
            
            subject.PrimaryPart = subject.HumanoidRootPart
            rig:Destroy()
        else
            for _,v in subject:WaitForChild('Humanoid'):WaitForChild('Animator'):GetPlayingAnimationTracks() do
                v:SetAttribute('Disable', true)
                v:Stop()
            end
        end

        local humRoot = subject:WaitForChild('HumanoidRootPart')

        task.wait()

        AnimationService.RemoveHands(subject, 'Both')
        if data.UsesHands then
            AnimationService.AddHands(subject, data.UsesHands)
        end

        local anim: AnimationTrack = subject:WaitForChild('Humanoid'):WaitForChild('Animator'):LoadAnimation(data.MainAnimation)
        anim:Play()
        -- print('playing?', anim.IsPlaying)
        if not anim.Looped then
            anim.Ended:Connect(function()
                if anim:GetAttribute('Disable') then return end
                task.wait(.5)
                anim:Play()
            end)
        end

        -- viewportCamera.CameraSubject = subject
        viewportCamera.CFrame = CFrame.lookAt(humRoot.Position + humRoot.CFrame.LookVector * 5 + Vector3.yAxis * .5, humRoot.Position)
    
        slot:WaitForChild('Button').Activated:Connect(function()
            selectedEmote = emote
            if selectionMode == 'Shop' then
                if OwnsEmote(selectedEmote) then 
                    ActionButton.Text = 'Owned'
                else
                    ActionButton.Text = 'Buy ('..(EmoteModule.Costs[data.Tier] or 'N/A')..' Tokens)'
                end
            else
                ActionButton.Text = 'Use'
            end
            ActionButton.Visible = true
        end)

        if not OwnsEmote(emote) then
            slot.Button.BackgroundTransparency = .5
        end

        slot.Parent = EmoteSelectionGui
    end
end

ActionButton.Activated:Connect(function(inputObject, clickCount)
    if not selectedEmote then return end
    
    local result: string
    if selectionMode == 'Shop' then
        result = EmoteSelect:InvokeServer(selectedEmote, 'Shop')
    else
        result = EmoteSelect:InvokeServer(selectedEmote, 'Replace', slotToReplace)
        if result == "Success" then
            ActionButton.Visible = false
            EmoteShopGui.Visible = false
            -- UpdateEmoteWheel()
        end
    end

    ActionButton.Text = result
    task.wait(2)
    ActionButton.Visible = false
end)

OwnedEmotes.ChildAdded:Connect(UpdateEmoteSelection)
EquippedEmotes.ChildAdded:Connect(UpdateEmoteWheel)
for _,slot in EquippedEmotes:GetChildren() do
    slot.Changed:Connect(UpdateEmoteWheel)
end

UpdateEmoteSelection()

local function UpdateTokens()
    EmoteShopGui:WaitForChild('Tokens').Text = 'Tokens: '..Data:WaitForChild('CosmeticTokens').Value
end
UpdateTokens()
Data.CosmeticTokens.Changed:Connect(UpdateTokens)

UIS.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.B then
        if EmoteShopGui.Visible then
            EmoteShopGui.Visible = false
            return
        end
        EmoteWheel.Visible = not EmoteWheel.Visible
    end
end)