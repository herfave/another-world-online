local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}

function module:Setup(simulation)
    -- base speed
	simulation.constants.maxSpeed = 8 --Units per second
	simulation.state.groundSpeed = simulation.constants.maxSpeed --Units per second
	simulation.state.currentSpeed = 0

	-- camera
	simulation.state.targetFov = 0

	-- air speed vars
	simulation.constants.maxAirSpeed = 16 --Units per second
	simulation.state.airSpeed = simulation.constants.maxAirSpeed --Units per second

	simulation.constants.accel = 10 --Units per second per second
	simulation.constants.airAccel = 10 --Uses a different function than ground accel!
	simulation.constants.jumpPunch = 35 --Raw velocity, just barely enough to climb on a 7 unit tall block
	simulation.constants.turnSpeedFrac = 10 --seems about right? Very fast.
	simulation.constants.runFriction = 0.01 --friction applied after max speed
	simulation.constants.brakeFriction = 0.03 --Lower is brake harder, dont use 0
	simulation.constants.maxGroundSlope = 0.55 --about 45o
	simulation.constants.jumpThrustPower = 75 --If you keep holding jump, how much extra vel per second is there?  (turn this off for no variable height jumps)
	simulation.constants.jumpThrustDecay = 0.15 --Smaller is faster
	simulation.constants.gravity = -90
    simulation.state.look = Vector3.new()

	simulation.constants.dynamicCollide = false

    -- setup base walking state
	local MoveTypeBase = require(script.Parent.utils.MoveTypeBase)
	MoveTypeBase:ModifySimulation(simulation)
end

function module:GetCharacterModel()
	local enemymodel = game.Lighting:FindFirstChild("MystFig") 
	if not enemymodel then
    	enemymodel = ReplicatedStorage.Assets.Models.MystFig:Clone()
    	enemymodel.Parent = game.Lighting
    	enemymodel:AddTag("CameraIgnore")
	end

    local hip = (enemymodel.HumanoidRootPart.Size.y
				* 0.5) +enemymodel.Humanoid.hipHeight
    return {
        model = enemymodel,
        modelOffset = Vector3.yAxis * (hip - 2.55)
    }
end

return module