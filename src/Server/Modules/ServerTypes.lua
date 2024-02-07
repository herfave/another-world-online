local Packages = game:GetService("ReplicatedStorage").Packages
local Janitor = require(Packages.Janitor)
local Signal = require(Packages.Signal)

local Modules = game:GetService("ServerStorage").Modules
local ChickyZone = Modules.ChickyZone
local BaseEvent = Modules.BaseEvent

export type ChickyZone = typeof(setmetatable({} :: {
    PlayerEntered: Signal.Signal,
    PlayerLeft: Signal.Signal,
    PlayersInside: {Player},
    DisplayName: string,
    ActiveEvent: EventObject | nil;
    EventCooldown: number;

    _zonePart: BasePart,
    _janitor:  Janitor.Janitor,
    _boundCheck: RBXScriptConnection;
}, ChickyZone))

export type EventObject = typeof(setmetatable({} :: {
    OptedIn: {Player},
    OptedOut: {Player},
    Players: {Player},
    EventParams: {string: any},
    Active: boolean,
    Finished: boolean,
    EventStateSignal: Signal.Signal,
    Duration: number,

    _zone: ChickyZone,
    _janitor: Janitor.Janitor,
    _update: typeof(function() end),
}, BaseEvent))

return {}