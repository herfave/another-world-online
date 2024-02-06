local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage.Shared.Utils)
local Roact = require(ReplicatedStorage.Packages.React)

local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local module = {}

local Speedometer = Roact.Component:extend("Speedometer")

function Speedometer:init()

end

function Speedometer:render()
    return Roact.createElement("ScreenGui", {
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Name = "Speedometer"
    }, {
        speed = Roact.createElement("TextLabel", {
            FontFace = Font.new(
                "rbxasset://fonts/families/JosefinSans.json",
                Enum.FontWeight.SemiBold,
                Enum.FontStyle.Normal
            ),
            TextColor3 = Color3.fromHSV(0, 0, 1),
            TextScaled = false,
            TextSize = 36,
            TextStrokeTransparency = 0.5,
            TextWrapped = true,
            AnchorPoint = Vector2.new(1, 1),
            BackgroundColor3 = Color3.fromHSV(0, 0, 1),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -20, 1, -20),
            Size = UDim2.fromOffset(100, 100),

            Text = self.props.speed
        }),
    })
end

function module:Setup(_client)
    -- create the ui here
    self.speed = 0

    -- use Roact17 to do stuff idk
    local meterElement = Roact.createElement(Speedometer, {
        speed = self.speed
    })
    self.meter = Roact.mount(meterElement, PlayerGui)
end

function module:Step(_client, _deltaTime)
    local chickynoid = _client:GetClientChickynoid()
    if chickynoid then
        local simulation = chickynoid.simulation
        self.speed = simulation.state.currentSpeed
        -- if self.speed > 0 then

        self.meter = Roact.update(self.meter, Roact.createElement(Speedometer, {
            speed = Utils.roundNumber(self.speed, 1)
        }))
        -- end
    end
end

return module