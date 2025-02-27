local Matter = require(game.ReplicatedStorage.Packages.Matter)

local componentNames = {
    -- SHARED (replicated)
    "Player", -- { userid: number }
    "Enemy", -- {name : string} - name of Enemy type
    "Health", -- {value : number} - amount of health an entity has before dying
    "MaxHealth", -- { value : number }
    "Model", -- {value : Instance} - self-explanatory
    "Mob", -- {value : string}

    "ATK", -- {value: number} - damage dealt by basic attacks
    "DamageMod", -- {value : number} - modifier to damage, starts at 0
    "FireRateMod", -- {value: number} - modifier for fire rate, starts at 0

    -- SHARED (non-replicated)
    -- SERVER ONLY
    "FlatDamage", -- {value : number} - applies flat damage amount once
    "DoTDamage", -- {dps : number, duration ; number} - applies damage per second, ex, dps = 4 == 1/0.25s
    "ClientReady", -- {value : boolean} - created when the client has an active model
    "LastAttacker", -- { player : Player } - the last player to attack a mob
    "Origin", -- { position: Vector3 } - spawn point of mob

    -- CLIENT ONLY
    "MobVisual", -- { value : Model }
    "MobAnimations",  -- {player : AnimationPlayer}
    "MobHitboxes", -- { hitboxes : {Hitbox} }
    "MobState", -- { value : boolean }
}

-- value names to get serialized
local commonValues = {
    "userid",
    "name",
    "value",
    "waypoint",
    "destinations",
    "destAlpha",
}

local components = { _componentNames = componentNames, _commonValues = commonValues }
for _, v in componentNames do
    components[v] = Matter.component(v)
end

return components