local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sift = require(ReplicatedStorage.Packages.Sift)
local React = require(ReplicatedStorage.Packages.React)
local useState, useEffect = React.useState, React.useEffect

return function(props: {native: {[any]: any}})
    return React.createElement("Frame", Sift.Dictionary.merge({
        BackgroundTransparency = 1,
    }, props.native))
end