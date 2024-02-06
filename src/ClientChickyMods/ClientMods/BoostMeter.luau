local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage.Shared.Utils)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local createElement = React.createElement
local useState = React.useState

local module = {}


local function BoostMeter()
    boost, setBoost = useState({
        boostMeter = 0,
        maxBoost = 1
    })
    
    local boostMeter, maxBoost = boost.boostMeter, boost.maxBoost

    return createElement("ScreenGui", {
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Name = "BoostMeter",
        ResetOnSpawn = false
    }, {
        Container = createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            BackgroundColor3 = Color3.fromHSV(0, 0, 1),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 1, -30),
            Size = UDim2.new(0.3, 0, 0, 10),
        }, {
            Bar = createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.fromScale(0.5,0),
                BackgroundColor3 = Color3.fromHSV(0.558, 1, 1),
                BorderColor3 = Color3.fromHSV(0.558333, 1.0, 0.470588),
                BorderSizePixel = 2,
                Size = UDim2.fromScale(
                    boostMeter / maxBoost,
                    1
                ),

                Visible = boostMeter > 0
            }), 

            Boost = createElement("TextLabel", {
                FontFace = Font.new(
                    "rbxasset://fonts/families/JosefinSans.json",
                    Enum.FontWeight.Bold,
                    Enum.FontStyle.Normal
                ),
                Text = "BOOST | " .. tostring(math.floor(boostMeter * 100)),
                TextColor3 = Color3.fromHSV(0.557823, 0.192156, 1),
                TextSize = 14,
                TextStrokeColor3 = Color3.fromHSV(0.559405, 1.0, 0.396078),
                TextStrokeTransparency = 0.5,
                AnchorPoint = Vector2.new(0.5, 1),
                BackgroundColor3 = Color3.fromHSV(0, 0, 1),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0),
                Size = UDim2.fromOffset(200, 20),
            })
        })
    })
end

function module:Setup(_client)
    self.boost = 0.5
    self.maxBoost = 1.2

    self.meterElement = createElement(BoostMeter, {
        boostMeter = self.boost,
        maxBoost = self.maxBoost
    })

    self.root = ReactRoblox.createRoot(Instance.new("Folder"))
    self.root:render(ReactRoblox.createPortal({
        App = self.meterElement
    }, PlayerGui))

    print(self.meterElement)
end

function module:Step(_client, _deltaTime)
    local chickynoid = _client:GetClientChickynoid()
    if chickynoid then
        local simulation = chickynoid.simulation

        setBoost({
            boostMeter = simulation.state.boostMeter,
            maxBoost = simulation.constants.maxBoostMeter
        })
    end
end

return module