local Matter = require(game.ReplicatedStorage.Packages.Matter)

local componentNames = {
    -- SHARED (replicated)
    "Owner", -- { userid : number } - UserId of the player that owns this entity, typically towers
    "Player", -- {name : string, user : string} - player name info
    "Enemy", -- {name : string} - name of Enemy type
    "Health", -- {damage : number} - amount of health an entity has before dying
    "Range", -- {value : number} - num of studs to attack someone
    "FireRate", -- {value : number} - amount of time between attacks, not per second

    "ATK", -- {value: number} - enemy damage to nexus
    "DamageMod", -- {value : number} - modifier to damage, starts at 0
    "FireRateMod", -- {value: number} - modifier for fire rate, starts at 0

    -- SHARED (non-replicated)
    "Model", -- {value : Instance} - self-explanatory
    "Travel", -- {speed : number, destAlpha : number} - time+position between waypoints
    "Path", -- {destinations : {Vector3}} - array of waypoints to follow
    "Position", -- {value : Vector3} - self-explanatory
    "Rotation", -- {value : Vector3} - correlates to Orientation

    -- SERVER ONLY
    "FlatDamage", -- {value : number} - applies flat damage amount once
    "DoTDamage", -- {dps : number, duration ; number} - applies damage per second, ex, dps = 4 == 1/0.25s
    "ClientReady", -- {value : boolean} - created when the client has an active model

    -- CLIENT ONLY
    "Animation",  -- {value : string} - play animation of name on a model
    "AnimationTracks", -- {tracks : {)} - stored AnimationTracks in Animator
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