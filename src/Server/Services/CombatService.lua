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

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local ServerComm = require(Packages.Comm).ServerComm
local CombatComm = ServerComm.new(ReplicatedStorage:WaitForChild("Comms"), "CombatComm")
local CombatService = Knit.CreateService({
    Name = "CombatService";
    Client = {};
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
    self.SendMobAttack:FireAll(entityId, attackType)

    -- late attack based off attack data + 10% delay
    for i, t in attackTimes do
        -- store attacks and disregard client hits
        task.delay(t * 3, function()
            print("hit", i)
        end)
    end
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
    self.SendHitRequest:Connect(function(player: Player, targetId: number, attackType: string)
        local world = Knit.GetService("MatterService"):GetWorld()
        print(`{player.Name} hit {targetId} with {attackType}`)
        local sanity = self:SanitizeInput(player, targetId, attackType)
        if sanity then
            -- apply damage
            world:insert(targetId, Components.FlatDamage { value = 10 })
        end
    end)
end


function CombatService:KnitInit()
    self.SendHitRequest = CombatComm:CreateSignal("SendHitRequest", true)
    self.SendMobAttack = CombatComm:CreateSignal("SendMobAttack")
end


return CombatService
