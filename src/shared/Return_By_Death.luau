-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Services
local Services = require(ReplicatedStorage.Shared.Services)
local SkillService = Services.SkillService
local AnimationService = Services.AnimationService
local StateService = Services.StateService
local HitboxService = Services.HitboxService
local DamageService = Services.DamageService
local RagdollService = Services.RagdollService

-- Resources / Assets
local Assets = ReplicatedStorage.Assets

local skill = {}

type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: BasePart}

local groundParams = RaycastParams.new()
groundParams.FilterDescendantsInstances = {workspace.Map}
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.RespectCanCollide = true

function skill.Init(char: Character, extra: table)
    -- local skillHandler = SkillService.CreateSkill(char, "Return By Death", { Start = 10 })

	local humRoot = char.HumanoidRootPart
    local awakeningPos = humRoot.CFrame
    local hum = char.Humanoid
	local state = StateService.Get(char)
    
    local witchHeart = Assets.SkillAssets.SpiritKnight.WitchHeart:Clone()
    witchHeart.Parent = workspace.UnobstructiveAssets
    witchHeart.CFrame = char.Torso.CFrame
    
    local weld = Instance.new('WeldConstraint')
    weld.Parent = witchHeart
    weld.Part0 = witchHeart
    weld.Part1 = char.Torso

    -- DamageService.AddDamageEvent(char, 'Return By Death', function()
        
    -- end)
    local enabled: boolean = true
    state:DeathEvent(function()
        if not enabled then return end
        if witchHeart then
            witchHeart:Destroy()
        end
        SkillService.RouteToClient('Return By Death', char, 'Respawn', 'All')

        local plr = game.Players:GetPlayerFromCharacter(char)
        hum.MaxHealth = plr.Data.UltimateMeter.Value * 0.7
        hum.Health = hum.MaxHealth

        plr.Data.UltimateMeter.Value = 0

        state:IFrame(true, 1)

        task.defer(function()
            local enabled = true
            char:GetAttributeChangedSignal('Form'):Once(function()
                enabled = false
            end)
            while task.wait(10) and hum:IsDescendantOf(workspace) and enabled do
                hum.MaxHealth += 7
                if hum.MaxHealth > 100 then
                    hum.MaxHealth = 100
                    break
                end
            end
        end)

        humRoot.CFrame = awakeningPos

        return 'StopDamage'
    end)

    char:GetAttributeChangedSignal('Form'):Once(function()
        enabled = false
        if witchHeart then
            witchHeart:Destroy()
        end
    end)

	-- skillHandler.Runtime = function()
    --     skillHandler:AddEvent()
	-- end

	-- skillHandler.CleanUp = function()
		
	-- end

	-- skillHandler:Run()
end

return skill