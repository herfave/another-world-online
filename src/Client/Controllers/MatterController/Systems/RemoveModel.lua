--[[
    RemoveModel.lua
    Author: Aaron Jay

    Removes the model instance when the component is removed, either by entity
    despawn or component removal

]]

local Knit = require(game.ReplicatedStorage.Packages.Knit)
local Matter = require(game.ReplicatedStorage.Packages.Matter)
local Components = require(game.ReplicatedStorage.Shared.ECS.Components)
local MobVisual = Components.MobVisual

local function system(world)
    for _id, modelRecord in world:queryChanged(MobVisual) do
        if modelRecord.new == nil then
            if modelRecord.old and modelRecord.old.value then
                modelRecord.old.value:Destroy()
                -- print("Removed model for dead entity")
                Knit.GetController("MobController"):DestroyMobStateMachine(_id)
            end
        end
    end
end

return {
    system = system,

}