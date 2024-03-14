local Promise = require(game.ReplicatedStorage.Packages.Promise)
local AnimationClipProvider = game:GetService("AnimationClipProvider")
local animations = game.ReplicatedStorage.Assets.Animations.MobAnimations

local Utils = require(game.ReplicatedStorage.Shared.Utils)

local data = {}
for _, v in animations:GetDescendants() do
    if v:IsA("Animation") and v.Parent.Name == "Attacks" then
        Utils.getAnimationTimes(v.AnimationId, "Attack")
        :andThen(function(times)
            data[v.Name] = times
        end)
    end
end

return data
