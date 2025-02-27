--[[
    BuildModel.lua
    Author: Aaron Jay

    Creates model instances for entities with specific components, using the
    defined component's value for the basis of the asset

    for example, entities with a "Tower" component that has the value "Gunner" should
    have a "Gunner" model created for them if it doesn't exist

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local Matter = require(ReplicatedStorage.Packages.Matter)
local Knit = require(ReplicatedStorage.Packages.Knit)
local AnimationPlayer = require(ReplicatedStorage.Shared.AnimationPlayer)
local HitboxModule = require(ReplicatedStorage.Shared.HitboxModule)

local Model = Components.Model
local Mob = Components.Mob
local MobVisual = Components.MobVisual
local MobAnimations = Components.MobAnimations
local MobHitboxes = Components.MobHitboxes

local models = ReplicatedStorage.Assets.Models

return function(world: Matter.World)
    for id, entity, serverModel in world:query(Mob, Model):without(MobVisual) do


        local baseModel = models:FindFirstChild(entity.value)
        if not baseModel then continue end
        local model = baseModel:Clone()
        model.Name = tostring(id)
        model.Parent = workspace:FindFirstChild("MobVisuals")
        

        -- load animations onto model
        local player = AnimationPlayer.new(model:FindFirstChild("Animator", true))
        local animations = ReplicatedStorage.Assets.Animations.MobAnimations[entity.value]:GetDescendants()
        for _, anim in animations do
            if anim:IsA("Animation") then
                player:WithAnimation(anim)
            end
        end


        -- load state machine
        Knit.GetController("MobController"):CreateMobStateMachine(
            id,
            serverModel.value:FindFirstChildOfClass("ControllerManager"),
            player
        )

        -- load hitboxes
        local hitboxes = {}
        for _, part in model:GetChildren() do
            if part:IsA("BasePart") and part:HasTag("_Hitbox") then
                local newHitbox = HitboxModule.new(model, {
                    OriginPart = part
                })
                hitboxes[part.Name] = newHitbox
            end
        end

        world:insert(id, 
            MobVisual({
                value = model
            }),
            MobAnimations({
                player = player
            }),

            MobHitboxes({
                hitboxes = hitboxes
            }),

            Components.MobState({
                value = "Idle"
            })
        )

        task.spawn(function()
            task.wait()
            for _, v in model:GetDescendants() do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                    v.CollisionGroup = "Mobs"
                end
            end

            local serverEntityId = Knit.GetController("MatterController"):GetServerEntityId(id)
            Knit.GetService("MatterService").ClientModelReady:Fire(serverEntityId)
            world:insert(id, Components.ClientReady { value = true })

            if model:FindFirstChild("Range") then
                model:FindFirstChild("Range").Transparency = 1
            end
        end)
    end
end