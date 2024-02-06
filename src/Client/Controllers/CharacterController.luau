--[[
    CharacterController.lua
    Author: Aaron (se_yai)

    Description: Manage character state
]]
local LocalPlayer = game.Players.LocalPlayer
local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local SpeedLines = Assets:WaitForChild("SpeedLines")

local Chickynoid = require(Shared.Chickynoid)
local ChickyClient = Chickynoid.ChickynoidClient
local ClientMods = Chickynoid.ClientMods

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local WaitFor = require(Packages.WaitFor)
local Keyboard = require(Packages.Input).Keyboard
local Janitor = require(Packages.Janitor)

local ClientComm = require(Packages.Comm).ClientComm
local ChickynoidComm = ClientComm.new(ReplicatedStorage:WaitForChild("Comms"), true, "ChickynoidComm")

local CharacterController = Knit.CreateController { Name = "CharacterController" }

function CharacterController:GetSimulation()
    if not self.localChickynoid then
        -- warn("Could not get localChickynoid simulation")
        return nil
    end

    return self.localChickynoid.simulation
end

function CharacterController:KnitStart()
    -- --// register mods
    ClientMods:RegisterMods("clientmods", ReplicatedFirst.ClientChickyMods.ClientMods)
    ClientMods:RegisterMods("characters", ReplicatedFirst.ClientChickyMods.Characters)
    ClientMods:RegisterMods("weapons", ReplicatedFirst.ClientChickyMods.Weapons)

    --// setup the client
    ChickyClient:Setup()
    

    -- // TODO: change to when chickynoid character is initialized
    repeat
        task.wait()
        print("waiting for client")
    until ChickyClient.localChickynoid ~= nil

    self.localChickynoid = ChickyClient.localChickynoid

    --// load in SPEED
    local CurrentCamera = workspace.CurrentCamera
    local newLines = SpeedLines:Clone()
    self.speedJanitor:Add(newLines)
    local emitter = newLines:FindFirstChild("Emitter", true)
    newLines.Parent = CurrentCamera
    RunService:BindToRenderStep("SpeedLines", Enum.RenderPriority.Camera.Value + 1, function()
        if not newLines then
            RunService:UnbindFromRenderStep("SpeedLines")
            return
        end
        newLines.CFrame = CurrentCamera.CFrame
        local simulation = self:GetSimulation()
        if simulation then
            if simulation.state.currentSpeed > simulation.constants.maxSpeed + 15 then
                if not emitter.Enabled then 
                    emitter.Enabled = true
                end
                return
            elseif emitter.Enabled then
                emitter.Enabled = false
            end
        end
    end)

    self.Keyboard = Keyboard.new()
    local toggleMoveset = ChickynoidComm:GetFunction("ToggleMoveset")
    self.Keyboard.KeyDown:Connect(function(key: Enum.KeyCode)
        if key == Enum.KeyCode.Y then
            print("Y down!")
            toggleMoveset():andThen(function(result)
                if result then
                    print("Swap success!")
                else
                    print("Swap fail!")
                end
            end)
        end
    end)
end

function CharacterController:KnitInit()
    self.speedJanitor = Janitor.new()
    self.CharacterAddedEvent = Signal.new() -- // Knit Controllers should connect to this event if the character is needed
end


return CharacterController