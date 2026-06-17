local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Services = require(ReplicatedStorage.Shared.Services)
local SkillService = Services.SkillService
local StateService = Services.StateService
local DamageService = Services.DamageService
local HitboxService = Services.HitboxService
local AnimationService = Services.AnimationService

local Assets = ReplicatedStorage.Assets
local Effects = Assets.Effects

local skill = {}

function skill.Init(char)
	SkillService.UsingSkill(char, 'Al Shamak', true)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	if not hrp or not hum then return end
	local humRoot =hrp

	local state = StateService.Get(char)
	state:SetWalkspeed("AlShamak", 9, 0.01)

	local voiceline = Assets.Sounds.SpiritKnight.AlShamakVoiceline:Clone()
	-- voiceline.SoundId = "rbxassetid://96684295953194"
	-- voiceline.Volume = 2
	-- voiceline.Looped = false
	-- voiceline.Name = "MainVoiceline"
	voiceline.Parent = hrp
	voiceline:Play()
	Debris:AddItem(voiceline, 10)

	local skillHandler = SkillService.CreateSkill(char, 'Al Shamak', {Start=0})

	local bea = Assets.SkillAssets.SpiritKnight:FindFirstChild("BeatriceRig"):Clone()
	local weld
	local startTrack, loopTrack

	skillHandler.Runtime = function()
		bea.Name = "BeatriceRig"
		bea:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(3, -1, 0))
		for _, p in bea:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored = false
				p.CanCollide = false
			end
		end
		bea.Parent = workspace.UnobstructiveAssets

		local beaHRP = bea:FindFirstChild("HumanoidRootPart")
		if beaHRP then
			weld = Instance.new("WeldConstraint")
			weld.Part0 = beaHRP
			weld.Part1 = hrp
			weld.Parent = beaHRP
		end

		local beaHum = bea:FindFirstChildOfClass("Humanoid")
		local beaAnimator = beaHum and beaHum:FindFirstChildOfClass("Animator") or Instance.new("Animator", beaHum)
		local beaStartAnim = Instance.new("Animation")
		beaStartAnim.AnimationId = "rbxassetid://114630084542880"
		local beaLoopAnim = Instance.new("Animation")
		beaLoopAnim.AnimationId = "rbxassetid://78540149041930"
		local beaStartTrack = beaAnimator:LoadAnimation(beaStartAnim)
		local beaLoopTrack = beaAnimator:LoadAnimation(beaLoopAnim)
		beaStartTrack.Priority = Enum.AnimationPriority.Action
		beaLoopTrack.Priority = Enum.AnimationPriority.Action
		beaStartTrack:Play()
		task.delay(1.5, function() beaLoopTrack:Play() end)

		local startAnim = Instance.new("Animation")
		startAnim.AnimationId = "rbxassetid://127549004162184"
		local loopAnim = Instance.new("Animation")
		loopAnim.AnimationId = "rbxassetid://76531101925176"
		startTrack = AnimationService.LoadAnimation(char, startAnim, 'Skill') --hum:LoadAnimation(startAnim)
		loopTrack = AnimationService.LoadAnimation(char, loopAnim, 'Skill')--hum:LoadAnimation(loopAnim)
		startTrack.Priority = Enum.AnimationPriority.Action
		loopTrack.Priority = Enum.AnimationPriority.Action
		startTrack:Play()
		task.delay(1.12, function() if not skillHandler:HasCompleted() then loopTrack:Play() end end)

		task.wait(8)

		if bea then
			local finalAnim = Instance.new("Animation")
			finalAnim.AnimationId = "rbxassetid://74648464980613"
			local finalTrack = AnimationService.LoadAnimation(bea, finalAnim, 'Beatrice')
			finalTrack.Priority = Enum.AnimationPriority.Action
			finalTrack:Play()
		end

		task.wait(.7)

		local alShamakBlock = Instance.new('Part')
		alShamakBlock.Transparency = 1
		alShamakBlock.CanCollide = false
		alShamakBlock.Anchored = true
		alShamakBlock.CFrame = humRoot.CFrame + humRoot.CFrame.LookVector * 20
		alShamakBlock.Name = 'AlShamakBlock'..char.Name
		alShamakBlock.Parent = workspace.UnobstructiveAssets

        skillHandler.CurrentSection = 'Summoning'

        local killbox = HitboxService.new()
        killbox.CoreMode = true
        killbox.Core = alShamakBlock
        killbox.Offset = Vector3.zero
        killbox.Size = Vector3.one * 50
        killbox.OverlapParams.FilterDescendantsInstances = {char}

        local att2 = Instance.new('Attachment')
        att2.Parent = alShamakBlock

        local caught = {}
        
        killbox.HitEvent:Connect(function(hit)
			table.insert(caught, hit)

			local alignPosition = Instance.new('AlignPosition')
			alignPosition.Mode = Enum.PositionAlignmentMode.TwoAttachment
			
			local att1 = Instance.new('Attachment')
			att1.Parent = hit.HumanoidRootPart

			alignPosition.Attachment0 = att1
			alignPosition.Attachment1 = att2

			alignPosition.Parent = hit.HumanoidRootPart
			-- alignPosition.MaxVelocity = Vector3.one * 10000
			alignPosition.RigidityEnabled = true
        end)

        killbox:Start()
        task.spawn(function()
            SkillService.RouteToClient('Al Shamak', char, 'VoidVfx', 'All', alShamakBlock)

            for i=1, 7 do
				SkillService.VoxelDestruction(humRoot.CFrame + humRoot.CFrame.LookVector * 20, Vector3.one * (50/7 * i), 4, Enum.PartType.Ball, 0, 60)
                task.wait(1/7)
            end

			SkillService.VoxelDestruction(humRoot.CFrame + humRoot.CFrame.LookVector * 20, Vector3.one * 62, 4, Enum.PartType.Ball, 50, 60)
        
            local tween = TweenService:Create(alShamakBlock, TweenInfo.new(3.5), {CFrame = alShamakBlock.CFrame + Vector3.yAxis * 30})
            tween:Play()
            tween.Completed:Wait()

            task.wait(2)

            killbox:Stop()
            alShamakBlock:Destroy()

            for _, hit in caught do
                local result = DamageService.Damage(hit, char, 100)
				if hit.Humanoid.Health > 0 or result == 'Interruption' then continue end
				for _,limb in hit:GetDescendants() do
					if limb:IsA('BasePart') then
						limb.Transparency = 1
					end
				end

                local plr = game.Players:GetPlayerFromCharacter(hit)
                if plr then
					SkillService.RouteToClient('Al Shamak', char, 'Killed', plr)
                end
            end
        end)

		SkillService.RouteToClient('Al Shamak', char, 'Summoning', 'All')

        local summonSound: Sound = ReplicatedStorage.Assets.Sounds.SpiritKnight.AlShamakSummon:Clone()
        summonSound.Parent = char.HumanoidRootPart
        summonSound:Play()
        summonSound.Ended:Once(function()
            summonSound:Destroy()
        end)
	end

	skillHandler.CleanUp = function()
		state:EndWalkspeed("AlShamak")
		if startTrack then
			startTrack:Stop()
		end
		if loopTrack then
			loopTrack:Stop()
		end
		if weld then weld:Destroy() end
		if bea and bea:FindFirstChild("HumanoidRootPart") then
			bea.HumanoidRootPart.Anchored = true
		end
		if skillHandler:HasCompleted(true) then
			voiceline:Destroy()
		end

		SkillService.Cooldown(char, "Al Shamak", 110)
		SkillService.UsingSkill(char, 'Al Shamak', false)

		task.delay(7, function()
			if bea and bea.Parent then
				bea:Destroy()
			end
		end)
	end

	skillHandler:Run()
end

return skill