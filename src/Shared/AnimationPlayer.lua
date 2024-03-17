--- Makes playing and loading tracks into a humanoid easy
-- @classmod AnimationPlayer
local RunService = game:GetService("RunService")
local Knit = require(game.ReplicatedStorage.Packages.Knit)
local Signal = require(game.ReplicatedStorage.Packages.Signal)

local AnimationPlayer = {}
AnimationPlayer.__index = AnimationPlayer
AnimationPlayer.ClassName = "AnimationPlayer"

export type AnimationPlayer = {
	Humanoid: Animator,
	Tracks: {[string]: AnimationTrack},
	FadeTime: number,
	TrackPlayed: Signal.Signal,
	TrackPlaying: boolean,
	_tracker: RBXScriptConnection,

	ClearAllTracks: (AnimationPlayer) -> AnimationPlayer,
	RemoveTrack: (AnimationPlayer, string) -> AnimationPlayer,
	WithAnimation: (AnimationPlayer, Animation, string?) -> AnimationTrack,
	AddAnimation: (AnimationPlayer, string, number | string) -> AnimationTrack,
	GetTrack: (AnimationPlayer, string) -> AnimationTrack,
	AdjustWeight: (AnimationPlayer, string, number) -> (),
	PlayTrack: (AnimationPlayer, string, ...number?) -> AnimationTrack,
	StopTrack: (AnimationPlayer, string, number?) -> AnimationTrack,
	StopAllTracks: (AnimationPlayer, number?) -> (),
	GetTracks: (AnimationPlayer) -> {[string]: AnimationTrack},
	Destroy: (AnimationPlayer) -> (),
}

--- Constructs a new animation player
-- @constructor
-- @tparam Humanoid Humanoid
function AnimationPlayer.new(Humanoid): AnimationPlayer
	local self = setmetatable({} :: AnimationPlayer, AnimationPlayer)
	-- if type(Humanoid) == "table" then
	-- 	for i, v in pairs(Humanoid) do
	-- 		print(i, v)
	-- 	end
	-- end
	self.Humanoid = Humanoid or error("No Humanoid")
	self.Tracks = {}
	self.FadeTime = 0.2 -- Default

	self.TrackPlayed = Signal.new()
	self.TrackPlaying = false

	self._tracker = RunService.Heartbeat:Connect(function()
		for _, track in pairs(self.Tracks) do
			if track.IsPlaying then
				self.TrackPlaying = true
				return
			end
		end
		self.TrackPlaying = false
	end)

	return self
end

function AnimationPlayer.ClearAllTracks(self: AnimationPlayer)
	for i, v in pairs(self.Tracks) do
		self.Tracks[i]:Destroy()
		self.Tracks[i] = nil
	end
	return self
end

function AnimationPlayer.RemoveTrack(self: AnimationPlayer, Name: string)
	if self.Tracks[Name] ~= nil then
		self.Tracks[Name]:Destroy()
	end

	self.Tracks[Name] = nil
	return self
end

function AnimationPlayer.WithAnimation(self: AnimationPlayer, Animation: Animation, name: string | nil)
	self.Tracks[name or Animation.Name] = self.Humanoid:LoadAnimation(Animation)

	return self.Tracks[name or Animation.Name]
end

--- Adds an animation to play
function AnimationPlayer.AddAnimation(self: AnimationPlayer, Name: string, AnimationId: number | string)
	local Animation = Instance.new("Animation")

	if tonumber(AnimationId) then
		Animation.AnimationId = "http://www.roblox.com/Asset?ID=" .. tonumber(AnimationId) or error("No AnimationId")
	else
		Animation.AnimationId = AnimationId
	end

	Animation.Name = Name or error("No name")

	return self:WithAnimation(Animation)
end

--- Returns a track in the player
function AnimationPlayer.GetTrack(self: AnimationPlayer, TrackName: string)
	return self.Tracks[TrackName] --or error("Track does not exist")
end

function AnimationPlayer:AdjustWeight(self: AnimationPlayer, TrackName: string, weight: number)
	local track = self:GetTrack(TrackName)
	track:AdjustWeight(weight)
end

---Plays a track
-- @tparam string TrackName Name of the track to play
-- @tparam[opt=0.4] number FadeTime How much time it will take to transition into the animation.
-- @tparam[opt=1] number Weight Acts as a multiplier for the offsets and rotations of the playing animation
	-- This parameter is extremely unstable.
	-- Any parameter higher than 1.5 will result in very shaky motion, and any parameter higher '
	-- than 2 will almost always result in NAN errors. Use with caution.
-- @tparam[opt=1] number Speed The time scale of the animation.
	-- Setting this to 2 will make the animation 2x faster, and setting it to 0.5 will make it
	-- run 2x slower.
-- @tparam[opt=0.4] number StopFadeTime
function AnimationPlayer.PlayTrack(self: AnimationPlayer, TrackName: string, FadeTime: number?, ...: number?): AnimationTrack
	local args = {...}
	FadeTime = FadeTime or self.FadeTime
	local Weight = args[1] or 0.95
	local Speed = args[2] or 1
	local Track = self:GetTrack(TrackName)

	if not Track.IsPlaying then
		self.TrackPlayed:Fire(TrackName, FadeTime, table.unpack({...}))

		self:StopAllTracks(FadeTime)
		Track:Play(FadeTime, 1, Speed)
	else
		self.TrackPlayed:Fire(TrackName, FadeTime, table.unpack({...}))
		Track:AdjustWeight(Weight)
	end

	return Track
end

--- Stops a track from being played
-- @tparam string TrackName
-- @tparam[opt=0.4] number FadeTime
-- @treturn AnimationTrack
function AnimationPlayer.StopTrack(self: AnimationPlayer, TrackName: string, FadeTime: number)
	FadeTime = FadeTime or self.FadeTime

	local Track = self:GetTrack(TrackName)
	if Track.IsPlaying then
		Track:Stop()
	end
	return Track
end

--- Stops all tracks playing
function AnimationPlayer.StopAllTracks(self: AnimationPlayer, FadeTime): ()
	for TrackName, _ in pairs(self.Tracks) do
		self:StopTrack(TrackName, FadeTime)
	end
end

function AnimationPlayer.GetTracks(self: AnimationPlayer): {[string]: AnimationTrack}
	return self.Tracks
end
---
function AnimationPlayer.Destroy(self: AnimationPlayer): ()
	self:StopAllTracks()
	setmetatable(self, nil)
end

return AnimationPlayer