local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WaypointTemplate = ReplicatedStorage.Assets.UI:WaitForChild("Waypoint")
local Component = require(ReplicatedStorage.Packages.Component)

local CollectionService = game:GetService("CollectionService")

local WaypointComponent = Component.new({
	Tag = "Waypoint",
})

WaypointComponent.RenderPriority = Enum.RenderPriority.Camera.Value + 1

function WaypointComponent:Construct()
	self.ScreenWaypoint = WaypointTemplate:Clone()
    self.ScreenWaypoint.Parent = PlayerGui
end

function WaypointComponent:Start()
    self.Camera = workspace.CurrentCamera
    self.Position, self.OnScreen = self.Camera:WorldToScreenPoint(self.Instance.Position)
end

function WaypointComponent:Stop()
    self.ScreenWaypoint:Destroy()
end

function WaypointComponent:HeartbeatUpdate(dt)
end

function WaypointComponent:SteppedUpdate(dt)
end

function WaypointComponent:RenderSteppedUpdate(dt)
    if true then return end
    if not self.Camera.CameraSubject then return end

    local nextPosition, onScreen = self.Camera:WorldToScreenPoint(self.Instance.Position)
    -- update waypoint marker
    local Distance = (nextPosition - self.Position).Magnitude
    local Main = self.ScreenWaypoint.Main
    if Main then
        Main.Position = UDim2.fromOffset(nextPosition.X, nextPosition.Y)
        Main.Visible = onScreen
        Main.Distance.Text = tostring(math.floor((self.Instance.Position - self.Camera.CameraSubject.Position).Magnitude)) .. "m"

        local img = Main.Image
        if CollectionService:HasTag(self.Instance, "RaceEvent") then
            img.Image = "rbxassetid://12914304656"
        else
            img.Image = "rbxassetid://12832628460"
        end

        self.Position, self.OnScreen = nextPosition, onScreen
    end
end

return WaypointComponent