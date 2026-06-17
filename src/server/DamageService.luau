local ServerStorage = game:GetService("ServerStorage")
local SkillService = require(game.ReplicatedStorage.Shared.Services.SkillService)
local CombatService = require(game.ReplicatedStorage.Shared.Services.CombatService)
local StateService = require(ServerStorage.RojoStorage.Modules.StateService)

local service = {}

type Character = Model

service.DamageEvents = {}

function service.Damage(target: Model, char: Model, amount: number, haltKilling: boolean?, dontEndBlock: boolean?)
    if target.Values:FindFirstChild('IFrame') then return 'Interruption' end

    local results = {}
    if service.DamageEvents[target] then
        for i,v in service.DamageEvents[target] do
            local result = v(char, amount, haltKilling)
            service.DamageEvents[target][i] = nil
            if result then
                table.insert(results, result)
            end
        end
    end

    if table.find(results, 'Interruption') then
        print('interrupted')
        return "Interruption"
    end

    local hum = target:FindFirstChild('Humanoid')
    local state = StateService.Get(target)

    if haltKilling then
        hum.Health = math.max(hum.Health - amount, 1)
    else
        task.spawn(function()
            if hum.Health - amount <= 0 then
                local results = state:_ExecuteDeathEvents()
                if not table.find(results, 'StopDamage') then
                    SkillService.EndGrab(target)
                    hum.Health -= amount
                end
            else
                hum.Health -= amount
            end

            if hum.Health <= 0 and target ~= char and char then
                char.Humanoid.Health += 15
            end
        end)
    end

    if char then
        local attackerIndex = target.Values.Attackers:FindFirstChild(char.Name)
        if not attackerIndex then
            attackerIndex = Instance.new('NumberValue')
            attackerIndex.Name = char.Name
            attackerIndex:SetAttribute('Damage', 0)
            attackerIndex.Parent = target.Values.Attackers
        end
        attackerIndex.Value = os.clock()
        attackerIndex:SetAttribute('Damage', attackerIndex:GetAttribute('Damage') + amount)

        local plr = game.Players:GetPlayerFromCharacter(char)
        if plr and char:GetAttribute("Form") ~= "Awakening" then
            SkillService.ChangeUltimateMeter(plr, math.min(15,amount*.5))
        end
    end

    if not dontEndBlock then
        -- target:SetAttribute('Blocking', nil)
        CombatService.Block(target, false)
    end

    game.ReplicatedStorage.Remotes.BodyFlash:FireAllClients(target)

    return true
end

function service.AddDamageEvent(char: Model, skill: string, callback)
    if not service.DamageEvents[char] then service.DamageEvents[char] = {} end

    service.DamageEvents[char][skill] = callback
end

return service