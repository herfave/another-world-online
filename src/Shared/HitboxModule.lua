--[[
    This module uses spatial queries rather than raycasts for considering when
    the hitbox is being activated while already touching something. Since margins
    don't exist yet with shapecasts, this is necessary.
]]

local RunService = game:GetService("RunService")
local Signal = require(game.ReplicatedStorage.Packages.Signal)
local Janitor = require(game.ReplicatedStorage.Packages.Janitor)
local CastVisuals = require(game.ReplicatedStorage.Shared.CastVisuals)
local module = {}
module.__index = module

local DEBUG_ENABLED = true

if DEBUG_ENABLED then
    CastVisual = CastVisuals.new(Color3.new(1,0,0), workspace)
end

function module.new(character, params)
    local self = {
        OriginPart = params.OriginPart,
        Size = params.Size,
        CastType = params.CastType or "Blockcast",
        ObjectHit = Signal.new(),
        _janitor = Janitor.new(),
        _character = character,
        Hits = {},
        Direction = params.Direction == "Forward" and params.OriginPart.CFrame.LookVector
            or params.OriginPart.CFrame.RightVector
    }

    self._overlapParams = OverlapParams.new()
    self._overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    self._overlapParams.MaxParts = 10

    if DEBUG_ENABLED then
        self.DEBUG_SPHERE = Instance.new("Part")
        self.DEBUG_SPHERE.Color = Color3.fromRGB(255, 0, 0)
        self.DEBUG_SPHERE.CanCollide = false
        self.DEBUG_SPHERE.CanQuery = false
        self.DEBUG_SPHERE.CanTouch = false
        self.DEBUG_SPHERE.Transparency = 0.7
        self.DEBUG_SPHERE.Parent = workspace
        self.DEBUG_SPHERE.Anchored = true
        self.DEBUG_SPHERE.Material = Enum.Material.Neon
        self.DEBUG_SPHERE.Size = params.Size.Magnitude * Vector3.one
        self.DEBUG_SPHERE.Shape = Enum.PartType.Ball
    end

    setmetatable(self, module)
    return self
end

function module:Start(getParts: boolean?, endTime: number?)
    self._janitor:Cleanup()

    self._janitor:Add(function()
        self.Hits = {}
    end)

    self.Hits = {self._character, workspace.MobVisuals}
    self._overlapParams.FilterDescendantsInstances = self.Hits
   
    self._janitor:Add(RunService.PreAnimation:Connect(function(dt)
        local parts = workspace:GetPartBoundsInRadius(
            self.OriginPart.Position,
            self.Size.Magnitude / 2,
            self._overlapParams
        )

        for _, result in parts do
            if result then
                if getParts then
                    table.insert(self.Hits, result)
                    self._overlapParams:AddToFilter(result)
                    self.ObjectHit:Fire(result)
                else
                    -- parse for model
                    local model = result:FindFirstAncestorOfClass("Model")
                    if model then
                        if table.find(self.Hits, model) then continue end
                        table.insert(self.Hits, model)
                        self._overlapParams:AddToFilter(model)
                        self.ObjectHit:Fire(model)
                    end
                end
            end
        end

        if DEBUG_ENABLED then
            self.DEBUG_SPHERE.CFrame = self.OriginPart.CFrame
        end
    end))

    if endTime then
        task.delay(endTime, function()
            self:Stop()
        end)
    end
end

function module:Stop()
    self._janitor:Cleanup()
end

return module