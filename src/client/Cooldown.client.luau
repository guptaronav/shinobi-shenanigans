local player = game.Players.LocalPlayer
repeat task.wait() until player:HasTag('Loaded')

local char = player.Character or player.CharacterAdded:Wait()

local GUI = player:WaitForChild('PlayerGui')
local skillsGui = GUI:WaitForChild('Skills')
local skillsBar: Frame = skillsGui:WaitForChild('SkillsBar')

-- Makes it so the slider hides if a different moveset appears
for _, v in skillsBar:GetChildren() do
    if not v:IsA('TextButton') then
        continue
    end

    v:WaitForChild('SkillName'):GetPropertyChangedSignal('Text'):Connect(function()
        local slider: Frame = v:WaitForChild("Slider")
        local cooldown = char:WaitForChild('Values'):WaitForChild('Cooldowns'):FindFirstChild(v.SkillName.Text)
        
        if cooldown and cooldown:GetAttribute('TimeLeft') then
            slider.Size = UDim2.new(1, cooldown:GetAttribute('TimeLeft')/cooldown.Value)
            slider:TweenSize(UDim2.fromScale(1,0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, cooldown:GetAttribute('TimeLeft'), true)
        else
            slider.Visible = false
        end
    end)
end

char:WaitForChild('Values'):WaitForChild('Cooldowns').ChildAdded:Connect(function(obj)
    if obj.Name == 'Special' then
        local bar: Frame = skillsBar:WaitForChild('SpecialBar'):WaitForChild('Bar')
        bar.Size = UDim2.fromScale(1, 0)
        bar:TweenSize(UDim2.fromScale(1,1), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, obj.Value, true)
        return
    end

    for _, v in skillsBar:GetChildren() do
        if not v:IsA('TextButton') then
            continue
        end
        if v:WaitForChild('SkillName').Text == obj.Name then
            local slider: Frame = v:WaitForChild("Slider")
            slider.Size = UDim2.fromScale(1,1)
            slider.Visible = true
            slider:TweenSize(UDim2.fromScale(1,0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, obj.Value, true)
            break
        end
    end
end)

char.Values.Cooldowns.ChildRemoved:Connect(function(obj)
    if obj.Name == 'Special' then
        local bar: Frame = skillsBar:WaitForChild('SpecialBar'):WaitForChild('Bar')
        bar:TweenSize(UDim2.fromScale(1,1), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, .3, true)
        return
    end

    for _, v in skillsBar:GetChildren() do
        if not v:IsA('TextButton') then
            continue
        end
        if v:WaitForChild('SkillName').Text == obj.Name then
            local slider: Frame = v:WaitForChild("Slider")
            slider.Visible = false
            break
        end    
    end
end)