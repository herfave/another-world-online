--[=[
@class 	CombatService
    Author: Aaron Jay (seyai_one)

]=]

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Components = require(Shared.ECS.Components)
local MobAnimationTimes = require(Shared.MobAnimationTimes)
local MobData = require(Shared.MobData)

local Packages = ReplicatedStorage.Packages
local Matter = require(Packages.Matter)
local Knit = require(Packages.Knit)

local ServerComm = require(Packages.Comm).ServerComm
local CombatComm = ServerComm.new(ReplicatedStorage:WaitForChild("Comms"), "CombatComm")
local CombatService = Knit.CreateService({
    Name = "CombatService";
    Client = {
        MobHitPlayer = Knit.CreateSignal()
    };
})


--[=[
    Make an attack on the server, and tell clients to play the animation for it. Also performs
    server sided attack on a delay in case the server doesn't receive a hit
]=]
function CombatService:MobAttack(entityId: number, attackType: string)
    local world = Knit.GetService("MatterService"):GetWorld()
    if not world:contains(entityId) then return end
    local mob = world:get(entityId, Components.Mob)

    -- get attack data animation
    local attackTimes = MobAnimationTimes[mob.value .. attackType]

    -- send attack to client for animations
    self.SendHitRequest:FireFilter(function(player)
        local character = player.Character
        if not character then return false end

        local serverModel = world:get(entityId, Components.Model)
        if not serverModel.value then return false end
        if not serverModel.value:IsA("Model") then return false end

        -- check distance
        local dist = (character:GetPivot().Position - serverModel.value:GetPivot().Position).Magnitude
        return dist <= 100
    end, entityId, attackType)
end

--[=[
    Sanitize hit inputs sent from the client
]=]
function CombatService:SanitizeInput(player: Player, targetId: number, attackType: string)
    local character: Model = player.Character
    local world = Knit.GetService("MatterService"):GetWorld()
    if not world:contains(targetId) then return false end

    local mob, model = world:get(targetId, Components.Mob, Components.Model)

    if mob and model.value then
        local serverModel: Model = model.value
        if not serverModel or not character then return end
        -- perform sanity checks
        --// DISTANCE CHECK
        local distance = (serverModel:GetPivot().Position - character:GetPivot().Position).Magnitude
        -- TODO: change MaxDistance to dynamic value from data
        local MaxDistance = 15
        if distance > MaxDistance then -- too far away for attack
            return false
        end
        --// TIMING CHECK
    end

    return true
end

function CombatService:KnitStart()
    self.Client.MobHitPlayer:Connect(function(player: Player, mobId: number, attackType: string)
        local character = player.Character
        local humanoid = player.Character:WaitForChild("Humanoid", 2)

        local world: Matter.World = Knit.GetService("MatterService"):GetWorld()
        if world:contains(mobId) then
            local mobType, atk = world:get(mobId,
                Components.Mob,
                Components.ATK
            )
            local animTimes = MobAnimationTimes[mobType.value .. attackType]
            local damagePerHit = math.floor(atk.value / #animTimes)
            if humanoid then
                humanoid:TakeDamage(damagePerHit)
            end
        end
    end)

    self.SendHitRequest:Connect(function(player: Player, targetId: number, attackType: string)
        local world: Matter.World = Knit.GetService("MatterService"):GetWorld()
        -- print(`{player.Name} hit {targetId} with {attackType}`)
        local sanity = self:SanitizeInput(player, targetId, attackType)
        if sanity then
            -- figure out last attacker
            local lastAttacker = world:get(targetId, Components.LastAttacker)
            if lastAttacker then
                lastAttacker = lastAttacker:patch({userId = player.UserId})
            else
                lastAttacker = Components.LastAttacker { userId = player.UserId }
            end

            -- apply damage
            world:insert(targetId,
                Components.FlatDamage { value = 10 },
                lastAttacker
            )

            local serverModel = world:get(targetId, Components.Model)
            if not serverModel.value then return end
            -- get direction of attacker
            local direction = CFrame.lookAt(
                player.Character:GetPivot().Position,
                serverModel.value:GetPivot().Position
            ).LookVector

            direction *= 5
        end
    end)
end


function CombatService:KnitInit()
    self.SendHitRequest = CombatComm:CreateSignal("SendHitRequest", true)
end


return CombatService
