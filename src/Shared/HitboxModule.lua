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

export type Hitbox = {
    OriginPart: BasePart,
    ObjectHit: Signal.Signal,
    _janitor: Janitor.Janitor,
    _character: Model,
    Hits: {Instance}
}

function module.new(character, params)
    local self = {
        OriginPart = params.OriginPart,
        ObjectHit = Signal.new(),
        _janitor = Janitor.new(),
        _character = character,
        Hits = {},
    }

    self._overlapParams = OverlapParams.new()
    self._overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    self._overlapParams.MaxParts = 10

    if DEBUG_ENABLED then
        self.DEBUG_PART = Instance.new("Part")
        self.DEBUG_PART.Color = Color3.fromRGB(255, 0, 0)
        self.DEBUG_PART.CanCollide = false
        self.DEBUG_PART.CanQuery = false
        self.DEBUG_PART.CanTouch = false
        self.DEBUG_PART.Transparency = 1
        self.DEBUG_PART.Parent = workspace
        self.DEBUG_PART.Anchored = true
        self.DEBUG_PART.Material = Enum.Material.Neon
        self.DEBUG_PART.Size = params.OriginPart.Size * 1.1
        self._janitor:Add(self.DEBUG_PART)
    end

    setmetatable(self, module)
    return self
end

function module:Destroy()
    self._janitor:Destroy()
    self.ObjectHit:Destroy()
    self = nil
end

function module:Start(getParts: boolean?, endTime: number?)
    self._janitor:Cleanup()

    self._janitor:Add(function()
        self.Hits = {}
    end)

    if DEBUG_ENABLED then
        self.DEBUG_PART.Transparency = 0.7
    end

    self.Hits = {self._character, workspace.MobVisuals}
    self._overlapParams.FilterDescendantsInstances = self.Hits
   
    self._janitor:Add(RunService.PreAnimation:Connect(function(dt)
        local parts = workspace:GetPartBoundsInBox(
            self.OriginPart.CFrame,
            self.OriginPart.Size * 1.1,
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
            self.DEBUG_PART.CFrame = self.OriginPart.CFrame
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
    if DEBUG_ENABLED then
        self.DEBUG_PART.Transparency = 1
    end
end

return module