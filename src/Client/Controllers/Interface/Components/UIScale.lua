local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")

local React = require(ReplicatedStorage.Packages.React)
local useState, useEffect = React.useState, React.useEffect

local Camera = Workspace.CurrentCamera
local TopInset, BottomInset = GuiService:GetGuiInset()
local TotalInset = TopInset + BottomInset

--[[
  Properties
    Size - Vector2
    DefaultSize - Vector2
    Maximum - Number
    Minimum - Number
]]

local function UIScale(props)
    local defaultSize = props.DefaultSize
    local maxSize, minSize = props.MaxSize, props.MinSize
    local frameSize = props.Size

    local scale, setScale = useState(1)

    useEffect(function()
        local cameraUpdate = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            local viewportSize = Camera.ViewportSize-TotalInset

            if frameSize and maxSize and minSize then
                local maxClamp = frameSize.X / maxSize
                local minClamp = frameSize.X / minSize

                if minClamp > maxClamp then
                    local placeholder = maxClamp
                    maxClamp = minClamp
                    minClamp = placeholder
                end

                setScale(1/math.clamp(math.max(defaultSize.X/viewportSize.X, defaultSize.Y/viewportSize.Y), minClamp, maxClamp))
            else
                setScale(1 / math.max(defaultSize.X/viewportSize.X, defaultSize.Y/viewportSize.Y))
            end
        end)

        return function()
            cameraUpdate:Disconnect()
        end
    end, {})

    return React.createElement("UIScale", {
        Scale = scale
    })
end

return UIScale