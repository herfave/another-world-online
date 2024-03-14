--[=[
@class 	MobController
    Author: Aaron Jay (seyai_one)

]=]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Components = require(Shared.ECS.Components)
local HitboxModule = require(Shared.HitboxModule)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Matter = require(Packages.Matter)
local Janitor = require(Packages.Janitor)

-- Comm setup
local ClientComm = require(Packages.Comm).ClientComm
local CombatComm = ClientComm.new(ReplicatedStorage:WaitForChild("Comms"), true, "CombatComm")
local SendMobAttack = CombatComm:GetSignal("SendMobAttack")

local MobController = Knit.CreateController({ Name = "MobController" })

-- TODO: setup animation state machine for movement and actions outside of attacking
function MobController:CreateMobStateMachine(entityId: number, cm: ControllerManager, animations)

end

function MobController:KnitStart()
    SendMobAttack:Connect(function(entityId: number, attackType: string)
        local clientEntityId = Knit.GetController("MatterController"):GetClientEntityId(entityId)
        local mob = self.VisualsFolder:FindFirstChild(tostring(clientEntityId))
        -- print(mob)
        if mob then
            local world: Matter.World = Knit.GetController("MatterController"):GetWorld()
            if world:contains(clientEntityId) then
                local _janitor = Janitor.new()
                local anims, hbs, model, mobType = world:get(
                    clientEntityId,
                    Components.MobAnimations,
                    Components.MobHitboxes,
                    Components.MobVisual,
                    Components.Mob
                )
                local track = anims.player:GetTrack(mobType.value .. attackType)

                for hbName, hitbox in hbs.hitboxes do
                    _janitor:Add(hitbox.ObjectHit:Connect(function(model: Model)
                        if Players:GetPlayerFromCharacter(model) == LocalPlayer then
                            -- fire event that they were hit by a mob
                            -- print(`hit {model.Name} with {hbName}`)
                            Knit.GetService("CombatService").MobHitPlayer:Fire(entityId, attackType)
                        end
                    end))
                end

                _janitor:Add(track:GetMarkerReachedSignal("Attack"):Connect(function(hitboxName: string)
                    if hbs.hitboxes[hitboxName] then
                        hbs.hitboxes[hitboxName]:Start()
                    end
                end))

                _janitor:Add(track:GetMarkerReachedSignal("AttackEnd"):Connect(function(hitboxName: string)
                    if hbs.hitboxes[hitboxName] then
                        hbs.hitboxes[hitboxName]:Stop()
                    end
                end))

                _janitor:Add(track.Stopped:Connect(function()
                    _janitor:Destroy()
                end))

                -- do spark, then play animation
                local attackSpark = model.value:FindFirstChild("AttackSpark", true)
                if attackSpark then
                    local emitter: ParticleEmitter = attackSpark:FindFirstChild("Emitter")
                    emitter:Emit(1)
                    task.delay(emitter.Lifetime.Max, function()
                        anims.player:PlayTrack(mobType.value .. attackType)
                    end)
                else
                    task.delay(0.5, function()
                        anims.player:PlayTrack(mobType.value .. attackType)
                    end)
                end
                -- print(attackType)
            end
        end
    end)
end


function MobController:KnitInit()
    self.VisualsFolder = Instance.new("Folder", workspace)
    self.VisualsFolder.Name = "MobVisuals"
    self.VisualsFolder:AddTag("_CameraIgnore")
    self.ServerMobs = workspace:WaitForChild("Mobs")
end


return MobController