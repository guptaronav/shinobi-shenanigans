local ReplicatedStorage = game:GetService('ReplicatedStorage')
local uis = game:GetService('UserInputService')
local cas = game:GetService('ContextActionService')

local skillRoute = game.ReplicatedStorage.Remotes.SkillRoute
local characters = require(game.ReplicatedStorage.Shared.Data.Characters)
local MobileTouch = require(game.ReplicatedStorage.Shared.Utility.MobileTouch)

local player = game.Players.LocalPlayer
repeat task.wait() until player:HasTag('Loaded')

local char = player.Character or player.CharacterAdded:Wait()

local GUI = player:WaitForChild('PlayerGui')
local skillsGui = GUI:WaitForChild('Skills')
local skillsBar: Frame = skillsGui:WaitForChild('SkillsBar')
local ultGui = skillsGui:WaitForChild('Ult')

local character = player:WaitForChild('Data'):WaitForChild('Character').Value
local skillsData = characters[character].Skills


local jumping = false

local skillKeys = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four] = 4,
    [Enum.KeyCode.ButtonL2] = 1,
    [Enum.KeyCode.ButtonL1] = 2,
    [Enum.UserInputType.MouseButton1] = 3,
    [Enum.KeyCode.ButtonR1] = 4,
}

local function sendSkill(keycode, form, inputEnded)
    if skillKeys[keycode] and not char:FindFirstChild('Skill_'..skillKeys[keycode]) then -- Skill
        local skillSets = characters[player.Data.Character.Value].Skills
        local skill
        for i,v in skillSets do
            if v.Order == skillKeys[keycode] and v.Form == form then
                skill = i
                break
            end            
        end
        if not skill then return end
        print(skill)

        if not inputEnded then
            skillRoute:FireServer(skill, 'Init', {StartCFrame = char.HumanoidRootPart.CFrame, IsInAir = (jumping or char.Humanoid.FloorMaterial == Enum.Material.Air or char.Humanoid.FloorMaterial == nil)})
        else
            -- skillRoute:FireServer(skill, 'InputEnded', {StartCFrame = char.HumanoidRootPart.CFrame, IsInAir = (char.Humanoid.FloorMaterial == Enum.Material.Air or char.Humanoid.FloorMaterial == nil)})
        end
    elseif keycode == Enum.KeyCode.R or keycode == Enum.KeyCode.DPadLeft then
        skillRoute:FireServer('Special', nil, {StartCFrame = char.HumanoidRootPart.CFrame,IsInAir = (jumping or char.Humanoid.FloorMaterial == Enum.Material.Air or char.Humanoid.FloorMaterial == nil)})
    end
end

local function HandleSkillInput(_, inputState, inputObject)
    if uis:GetLastInputType() ~= Enum.UserInputType.Gamepad1 and inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
        return Enum.ContextActionResult.Pass
    end
    if inputState and inputState ~= Enum.UserInputState.Begin then return end

    if (inputObject.KeyCode == Enum.KeyCode.Space or inputObject.KeyCode == Enum.KeyCode.ButtonA) and not jumping then
        jumping = true
        task.delay(.3, function()
            jumping = false
        end)
    end

    if os.clock() - char:GetAttribute('Attacking') < .4 then
        local startTime = os.clock()
        repeat
            task.wait()
        until os.clock() - char:GetAttribute('Attacking') >= .4 or os.clock() - startTime >= .4
        print('Buffer time: ', os.clock() - startTime)
    end

    local isConsoleMouse = uis:GetLastInputType() == Enum.UserInputType.Gamepad1 and inputObject.UserInputType == Enum.UserInputType.MouseButton1

    sendSkill(isConsoleMouse and inputObject.UserInputType or inputObject.KeyCode, char:GetAttribute('Form') or 'Base')   
end

cas:BindActionAtPriority('SkillUse', HandleSkillInput, false, 2, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonL2, Enum.KeyCode.DPadLeft, Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.R)

MobileTouch.WaitForButton('Special')
MobileTouch.Button_Activated('Special', 'Pressed', function()
    skillRoute:FireServer('Special', nil, {StartCFrame = char.HumanoidRootPart.CFrame, IsInAir = (jumping or char.Humanoid.FloorMaterial == Enum.Material.Air or char.Humanoid.FloorMaterial == nil)})
end)

local cons = {}
local function UpdateSkills(form)
    for _,v in skillsBar:GetChildren() do
        if not v:IsA('TextButton') then continue end
        v:WaitForChild('SkillName').Text = 'Move'
        v.Visible = true
    end

    for i,v in skillsData do
        if v.Form ~= form or v.Locked then continue end
    
        local skillSlot = skillsBar:WaitForChild('Skill'..v.Order)
        -- skillSlot:WaitForChild('SkillName').TextScaled = false
        -- local name = string.gsub(i, ' ', '\n')
        local name = i
        skillSlot:WaitForChild('SkillName').Text = name
    
        if cons[skillSlot] then
            cons[skillSlot]:Disconnect()
            cons[skillSlot] = nil
        end

        cons[skillSlot] = skillSlot.Activated:Connect(function()
            local s
            if skillSlot.Name == 'Skill1' then
                s = Enum.KeyCode.One
            elseif skillSlot.Name == 'Skill2' then
                s = Enum.KeyCode.Two
            elseif skillSlot.Name == 'Skill3' then
                s = Enum.KeyCode.Three
            else
                s = Enum.KeyCode.Four
            end
            sendSkill(s, form)
        end)

        skillSlot:WaitForChild('ExecutionLabel').Visible = false
        if v.ExecutionAmount then
            skillSlot.ExecutionLabel.Text = 'Press '..v.ExecutionAmount..'x'
            skillSlot.ExecutionLabel.Visible = true
        end
    end

    for _,v in skillsBar:GetChildren() do
        if not v:IsA('TextButton') then continue end
        if v.SkillName.Text == 'Move' then
            v.Visible = false
        end
    end
end
UpdateSkills(char:GetAttribute('Form') or 'Base')
char:GetAttributeChangedSignal('Form'):Connect(function()
    UpdateSkills(char:GetAttribute('Form'))
end)

-------
local skillCrackImg = ReplicatedStorage.Assets.UIAssets.SkillCrack

local function UpdateCrack()
    local disabledSkill = char:GetAttribute('DisabledSkill')

    for _,skillSlot in skillsBar:GetChildren() do
        if not skillSlot:IsA("TextButton") then continue end

        if skillSlot.SkillName.Text == disabledSkill then
            if not skillSlot:FindFirstChild('SkillCrack') then
                local newSkillCrack = skillCrackImg:Clone()
                newSkillCrack.Parent = skillSlot
            end
        else
            local skillCrack = skillSlot:FindFirstChild('SkillCrack')
            if skillCrack then
                skillCrack:Destroy()
            end
        end
    end
end

char:GetAttributeChangedSignal('DisabledSkill'):Connect(UpdateCrack)
UpdateCrack()