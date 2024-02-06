local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Janitor = require(game:GetService("ReplicatedStorage").Packages.Janitor)
local CatmullRomSpline = require(script:WaitForChild("CatmullRomSpline"))

local NumPoints = 200
return function(name, points, parent, tension)
    tension = tension or 0.5
    local _janitor = Janitor.new()
    local newSpline = CatmullRomSpline.new(points, tension)

    -- only create visual points on the server
    local DefaultPoints, Lines
    if RunService:IsServer() then
         -- hide base points
        for _, p in points do
            p.Transparency = 1
            p.CanCollide = false
        end

        local BezierFolder = Instance.new("Folder", parent)
        local PointsFolder = Instance.new("Folder", BezierFolder)
        local LinesFolder = Instance.new("Folder", BezierFolder)
        BezierFolder.Name = name
        PointsFolder.Name = "Points"
        LinesFolder.Name = "Lines"

        _janitor:Add(BezierFolder)

        DefaultPoints, Lines = {}, {}
        for i = 1, NumPoints do
            local TargetPart = Instance.new("Part", PointsFolder)
            TargetPart.Size = Vector3.new(0.85, 0.85, 0.85)
            TargetPart.Color = Color3.fromRGB(255, 15, 159)
            TargetPart.Transparency = 1
            TargetPart.CanCollide = false
            TargetPart.Anchored = true
            TargetPart.Name = "Default" .. tostring(i)
            table.insert(DefaultPoints, TargetPart)
        end

        for i = 1, NumPoints - 1 do
            local TargetPart = Instance.new("Part", LinesFolder)
            TargetPart.Size = Vector3.new(1, 1, 1)
            TargetPart.Color = Color3.fromRGB(33, 33, 40)
            TargetPart.CanCollide = true
            TargetPart.Anchored = true
            TargetPart.TopSurface = Enum.SurfaceType.Smooth
            TargetPart.BottomSurface = Enum.SurfaceType.Smooth

            -- create attachments
            local posA = Instance.new("Attachment", TargetPart)
            local negA = Instance.new("Attachment", TargetPart)
            posA.Name = "1"
            negA.Name = "-1"

            TargetPart.Name = tostring(i)
            CollectionService:AddTag(TargetPart, "SplineRail")
            CollectionService:AddTag(TargetPart, "FlowPart")
            table.insert(Lines, TargetPart)
        end

        local function UpdateBezier()
            for i = 1, NumPoints do
                local t = (i - 1) / (#DefaultPoints - 1)
                local p1 = newSpline:CalculatePositionAt(t)
                local d1 = newSpline:CalculateDerivativeAt(t)
                DefaultPoints[i].CFrame = CFrame.new(p1, p1 + d1)
            end
            for i = 1, #Lines do
                local line = Lines[i]
                local p1, p2 = DefaultPoints[i].Position, DefaultPoints[i + 1].Position
                local thisLength = (p2 - p1).Magnitude

                line.Size = Vector3.new(line.Size.X, line.Size.Y, thisLength)

                line:FindFirstChild("1").Position = Vector3.new(0, 0, (line.Size.Z/2))
                line:FindFirstChild("-1").Position = Vector3.new(0, 0, (-line.Size.Z/2))

                line.CFrame = CFrame.new(0.5 * (p1 + p2), p2)
            end
        end
        UpdateBezier()
        local LastChangeTick = tick()
        for _, controlPart in pairs(points) do
            controlPart.Changed:Connect(function()
                if tick() - LastChangeTick > 0 then
                    LastChangeTick = tick()
                    UpdateBezier()
                end
            end)
        end
    end


    local t
    t = {
        Name = name,
        Spline = newSpline,
        Points = DefaultPoints,
        NumPoints = NumPoints,
        Lines = Lines,
        Destroy = function()
            _janitor:Destroy()
            _janitor = nil
            t = nil
        end
    }

    return t
end