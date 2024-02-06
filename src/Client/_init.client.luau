local LocalPlayer = game.Players.LocalPlayer
-- set camera

local Player: Player = game.Players.LocalPlayer
local PlayerScripts = Player:WaitForChild("PlayerScripts")

local Knit = require(game.ReplicatedStorage.Packages.Knit)

Knit.AddControllers(PlayerScripts:WaitForChild("Controllers"))
-- load interfaces
-- Knit.AddControllers(PlayerScripts.Controllers:WaitForChild("Interface"))
for _, component in PlayerScripts.Components:GetChildren() do
    require(component)    
end

print("added knit controllers")
Knit.Start():catch()
print("loaded knit client")