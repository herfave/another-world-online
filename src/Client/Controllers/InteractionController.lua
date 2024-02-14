--[[
    InteractionController.lua
    Author: Aaron (se_yai)

    Description: Manage player spawning and interactions with the server involving data
]]
local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")

local CollectionService = game:GetService("CollectionService")
local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Streamable = require(Packages.Streamable).Streamable

local InteractionController = Knit.CreateController { Name = "InteractionController" }
local CharacterController

function InteractionController:SetupInteract(root)
    local attributes = root:GetAttributes()
    -- clone template ui
    local prompt = self.template:Clone()

    -- populate
    local main = prompt:FindFirstChild("PromptFrame")
    local actionText = main:FindFirstChild("ActionText")
    local objectText = main:FindFirstChild("ObjectText")

    objectText.Text = attributes.ObjectText
    actionText.Text = attributes.ActionText

    local input = main:WaitForChild("InputFrame").Frame
    local button = input:FindFirstChild("ButtonText")
    button.Text = attributes.Button

    prompt.Parent = PlayerGui

    local rootStreamable = Streamable.primary(root)
    rootStreamable:Observe(function(primary, trove)

        prompt.Adornee = primary
        print("item entered")

        trove:Add(function()
            prompt.Adornee = nil
        end)
    end)

    if rootStreamable.Instance then
        prompt.Adornee = root
    end

    root.Destroying:Connect(function()
        if prompt then
            prompt:Destroy()
        end
        rootStreamable:Destroy()
    end)

    table.insert(self._prompts, {prompt, attributes.Range or 15})
end

function InteractionController:KnitStart()
    -- attach ui prompt to all tagged objects

    local interactables = CollectionService:GetTagged("Interactable")
    for _, root in interactables do
        self:SetupInteract(root)
        print("Setup " .. root.Name .. " interact")
    end

    -- update proximity prompts
    local toRemove = {}
    local inRange = {}
    RunService.PostSimulation:Connect(function(dt)
        local simulation = CharacterController:GetSimulation()
        if not simulation then
            for index, info in self._prompts do
                local prompt = info[1]
                if prompt then
                    prompt.Enabled = false
                end
            end
            return
        end

        table.clear(toRemove)
        table.clear(inRange)

        for index, info in self._prompts do
            local prompt = info[1]
            if not info[2] then
                -- schedule for removal from table
                table.insert(toRemove, index)
                continue
            end
            if prompt.Adornee then
                prompt.Enabled = false
                local dist = (simulation.state.position - prompt.Adornee:GetPivot().Position).Magnitude
                if dist <= info[2] then
                    table.insert(inRange, {index, dist})
                elseif dist > info[2] and prompt.Enabled then
                end
            end
        end

        if #inRange >= 1 then
            if #inRange > 1 then
                table.sort(inRange, function(a, b)
                    local aDist = a[2]
                    local bDist = b[2]
                    return aDist < bDist
                end)
            end
            self.targetIndex = inRange[1][1]
        else
            self.targetIndex = nil
        end

        if self.targetIndex then
            local target = self._prompts[self.targetIndex][1]
            target.Enabled = true
        end

        -- remove by FILO
        for _, index in toRemove do
            table.remove(self._prompts[index])
        end
    end)
end


function InteractionController:KnitInit()
    self._prompts = {}
    self.template = ReplicatedStorage.Assets:WaitForChild("PromptTemplate")
    self.targetIndex = nil

    CharacterController = Knit.GetController("CharacterController")
end


return InteractionController