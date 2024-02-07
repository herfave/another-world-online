local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage.Shared.Utils)
local Roact = require(ReplicatedStorage.Packages.React)

local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local module = {}

local BoostMeter = Roact.Component:extend("BoostMeter")

function BoostMeter:render()
    return Roact.createElement("ScreenGui", {
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Name = "BoostMeter"
    }, {
        container = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            BackgroundColor3 = Color3.fromHSV(0, 0, 1),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 1, -30),
            Size = UDim2.new(0.3, 0, 0, 10),
        }, {
            bar = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.fromScale(0.5,0),
                BackgroundColor3 = Color3.fromHSV(0.558, 1, 1),
                BorderColor3 = Color3.fromHSV(0.558333, 1.0, 0.470588),
                BorderSizePixel = 2,
                Size = UDim2.fromScale(
                    self.props.boostMeter / self.props.maxBoost,
                    1
                ),

                Visible = self.props.boostMeter > 0
            }),
    
            bOOST = Roact.createElement("TextLabel", {
                FontFace = Font.new(
                    "rbxasset://fonts/families/JosefinSans.json",
                    Enum.FontWeight.Bold,
                    Enum.FontStyle.Normal
                ),
                Text = "BOOST | " .. tostring(math.floor(self.props.boostMeter * 100)),
                TextColor3 = Color3.fromHSV(0.557823, 0.192156, 1),
                TextSize = 14,
                TextStrokeColor3 = Color3.fromHSV(0.559405, 1.0, 0.396078),
                TextStrokeTransparency = 0.5,
                AnchorPoint = Vector2.new(0.5, 1),
                BackgroundColor3 = Color3.fromHSV(0, 0, 1),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0),
                Size = UDim2.fromOffset(200, 20),
            }),
        }),
    })
end

function module:Setup(_client)
    self.boost = 0.5
    self.maxBoost = 1.2

    local meterElement = Roact.createElement(BoostMeter, {
        boostMeter = self.boost,
        maxBoost = self.maxBoost
    })

    self.meter = Roact.mount(meterElement, PlayerGui)
end

function module:Step(_client, _deltaTime)
    local chickynoid = _client:GetClientChickynoid()
    if chickynoid then
        local simulation = chickynoid.simulation
        -- vel = vel - Vector3.new(0, vel.Y, 0)
        self.maxBoost = simulation.constants.maxBoostMeter
        self.boost = simulation.state.boostMeter
        -- if self.speed > 0 then

            self.meter = Roact.update(self.meter, Roact.createElement(BoostMeter, {
                boostMeter = self.boost,
                maxBoost = self.maxBoost
            }))
        -- end
    end
end

return module