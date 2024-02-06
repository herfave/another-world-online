local Enums = {}

Enums.EventType = {
	ChickynoidAdded = 0,
	ChickynoidRemoving = 1,
	Command = 2,
	State = 3,
	Snapshot = 4,
	WorldState = 5,
	CollisionData = 6,
	ResetConnection = 7,

	WeaponDataChanged = 8,
	BulletFire = 9,
	BulletImpact = 10,

	DebugBox = 11,

	PlayerDisconnected = 12,
}

Enums.NetworkProblemState = {
	None = 0,
	TooFarBehind = 1,
	TooFarAhead = 2,
	TooManyCommands = 3,
}

Enums.FpsMode = {
	Uncapped = 0,
	Hybrid = 1,
	Fixed60 = 2,
}

Enums.Anims = {
	Stop = 0,
	Idle = 1,
	Walk = 2,
	Run = 3,
	Push = 4,
	Jump = 5,
	Fall = 6,

	WallrideR = 7,
	WallrideL = 8,
	WalljumpR = 9,
	WalljumpL = 10,
	Railgrind = 11,
	Land = 12,

	-- Rollerskates/Blades Railgrind Tricks
	RailTrick1 = 13,
	RailTrick2 = 14,
	RailTrick3 = 15,

	-- Boost anims
	GroundBoost = 16,
	RailBoost = 17,

	-- Aerial Tricks
	AirTrick1 = 18,
	AirTrick2 = 19,
	AirTrick3 = 20, 

	-- Ground Tricks
	GroundTrick1 = 21,
	GroundTrick2 = 22,
	GroundTrick3 = 23
}

Enums.AnimChannel = {
	Channel0 = 0,
	Channel1 = 1,
	Channel2 = 2,
	Channel3 = 3,
}

Enums.RootSounds = {
	Stop = 0,
	Railgrind = 1,
	Land = 2,
	Jump = 3,
	Boost = 4,
	AirBoost = 5
}

Enums.SoundChannel = {
	Channel0 = 0, -- idle
	Channel1 = 1, -- movement anims
	Channel2 = 2, -- movement actions
	Channel3 = 3, -- tricks
}

Enums.Particles = {
	Stop = 0,
	Boost = 1
}

Enums.ParticleChannel = {
	Channel0 = 0,
	Channel1 = 1
}

Enums.WeaponData = {
	WeaponAdd = 0,
	WeaponRemove = 1,
	WeaponState = 2,
	Equip = 3,
	Dequip = 4,
}

Enums.Crashland = {
	STOP = 0,
	FULL_BHOP = 1,
	FULL_BHOP_FORWARD = 2,
	CAPPED_BHOP = 3,
	CAPPED_BHOP_FORWARD = 4,

}

return Enums
