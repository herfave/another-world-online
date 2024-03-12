local Components = require(game.ReplicatedStorage.Shared.ECS.Components)

return function(world)
    for id, hbRecord in world:queryChanged(Components.MobHitboxes) do
        if hbRecord.new == nil then
            if hbRecord.old and hbRecord.old.hitboxes then
                for name, hb in hbRecord.old.hitboxes do
                    hb:Destroy()
                    print("destroyed", name, "hitbox")
                end
            end
        end
    end
end