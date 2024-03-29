local path = script.Parent.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- react packages
local React = require(Packages.React)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local e = React.createElement
local useContext = React.useContext
local useEventConnection = require(path.Hooks.useEventConnection)
local useState = React.useState

local source = ReplicatedStorage.Assets.UI.BottomBar
local bottomBarTemp = RoactTemplate.fromInstance(React, source)

return function(props: {
    humanoid: Humanoid
})
    local health, setHealth = useState(props.humanoid.Health)
    useEventConnection(props.humanoid:GetPropertyChangedSignal("Health"), function()
        setHealth(props.humanoid.Health)
    end)
    return e(bottomBarTemp, {
        HealthDisplay = {
            Size = UDim2.fromScale(health/props.humanoid.MaxHealth, 1)
        },

        
    })
end