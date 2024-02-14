--[[
    InteractionService.lua
    Author: Aaron Jay (se_yai)

    Description: 
]]

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local InteractionService = Knit.CreateService {
    Name = "InteractionService";
    Client = {
        Interacted = Knit.CreateSignal()
    };
}


function InteractionService:KnitStart()
    self.Client.Interacted:Connect(function(player, root)
        
    end)
end


function InteractionService:KnitInit()

end


return InteractionService