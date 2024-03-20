--[=[
@class 	init
    Author: Aaron Jay (seyai_one)

]=]

local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)

local init = Knit.CreateController({ Name = "init" })


function init:KnitStart()
    Knit.GetController("CharacterController").CharacterAddedEvent:Connect(function(character)
        local root = ReactRoblox.createRoot(Instance.new("Folder"))
        local portal = ReactRoblox.createPortal({
            App = React.createElement(require(script.Screens.BottomBar), {
                humanoid = character:WaitForChild("Humanoid")
            })
        },
            game.Players.LocalPlayer:WaitForChild("PlayerGui")
        )
        root:render(portal)
    end)
end


function init:KnitInit()
    
end


return init