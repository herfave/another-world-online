--[=[
@class 	MobController
    Author: Aaron Jay (seyai_one)

]=]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Components = require(Shared.ECS.Components)
local AnimationPlayer = require(Shared.AnimationPlayer)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Matter = require(Packages.Matter)
local Janitor = require(Packages.Janitor)

-- Comm setup
local ClientComm = require(Packages.Comm).ClientComm
local CombatComm = ClientComm.new(ReplicatedStorage:WaitForChild("Comms"), true, "CombatComm")
local SendHitRequest = CombatComm:GetSignal("SendHitRequest")

local RNG = Random.new()

local MobController = Knit.CreateController({ Name = "MobController" })

--[=[
    Sets up a simple state machine to play running and idle animations. Can be expanded
    upon for more animations in the future
]=]
function MobController:CreateMobStateMachine(entityId: number, cm: ControllerManager, animations: AnimationPlayer.AnimationPlayer)
    local world: Matter.World = Knit.GetController("MatterController"):GetWorld()
    if not world:contains(entityId) then return end

    local function updateState()
        if not world:contains(entityId) then return end
        local state = world:get(entityId, Components.MobState)
        if state.value == "Attacking" then return end

        if cm.MovingDirection.Magnitude > 0 and state.value ~= "Running" then
            animations:PlayTrack("Run")
            world:insert(entityId, state:patch({value = "Running"}))
        elseif cm.MovingDirection.Magnitude == 0 and state.value ~= "Idle" then
            animations:PlayTrack("Idle")
            world:insert(entityId, state:patch({value = "Idle"}))
        end
    end

    self._stateMachines[entityId] = RunService.PreAnimation:Connect(updateState)
    animations:PlayTrack("Idle")
end

function MobController:DestroyMobStateMachine(entityId: number)
    if self._stateMachines[entityId] then
        self._stateMachines[entityId]:Disconnect()
    end
end

function MobController:PlayAttackedShake(clientEntityId: number)
    local world: Matter.World = Knit.GetController("MatterController"):GetWorld()
    if world:contains(clientEntityId) then
        local mobVisual, serverModel = world:get(clientEntityId, Components.MobVisual, Components.Model)
        task.spawn(function()
            for i = 1, 3 do
                mobVisual.value:PivotTo(serverModel.value:GetPivot() * CFrame.new(
                    RNG:NextNumber(-0.75, 0.75),
                    RNG:NextNumber(-0.75, 0.75),
                    RNG:NextNumber(-0.75, 0.75)                                                                                                                                                                                                                                    
                ))
                task.wait()
                task.wait()
            end
        end)
    end
end

function MobController:KnitStart()
    SendHitRequest:Connect(function(entityId: number, attackType: string)
        local clientEntityId = Knit.GetController("MatterController"):GetClientEntityId(entityId)
        local mob = self.VisualsFolder:FindFirstChild(tostring(clientEntityId))
        -- print(mob)
        if mob then
            local world: Matter.World = Knit.GetController("MatterController"):GetWorld()
            if world:contains(clientEntityId) then
                local _janitor = Janitor.new()
                local anims, hbs, model, mobType, state = world:get(
                    clientEntityId,
                    Components.MobAnimations,
                    Components.MobHitboxes,
                    Components.MobVisual,
                    Components.Mob,
                    Components.MobState
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
                    if world:contains(clientEntityId) then
                        world:insert(clientEntityId, state:patch({value = "AttackEnded"}))
                    end
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
                        if world:contains(clientEntityId) then
                            world:insert(clientEntityId, state:patch({value = "Attacking"}))
                        end
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
   
    self._stateMachines = {}
end


return MobController