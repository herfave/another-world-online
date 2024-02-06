local module = {}

local StarterPlayer = game:GetService("StarterPlayer")

function module:Setup(simulation)
	-- base speed
	simulation.constants.maxSpeed = 16 --Units per second
	simulation.state.groundSpeed = simulation.constants.maxSpeed --Units per second
	simulation.state.currentSpeed = 0

	-- camera
	simulation.state.targetFov = 0

	-- air speed vars
	simulation.constants.maxAirSpeed = 16 --Units per second
	simulation.state.airSpeed = simulation.constants.maxAirSpeed --Units per second

	-- boost vars
	simulation.constants.boostSpeed = 56 -- Units per second
	simulation.constants.boostAcceleration = 100 -- Units per second
	simulation.constants.maxBoostMeter = 4 -- Seconds of boost available

	simulation.state.boostMeter = 1

	-- air boost vars
	simulation.constants.airBoostSpeed = simulation.constants.boostSpeed -- can be adjusted
	simulation.constants.boostLockout = 1
	simulation.constants.airBoostCost = 0.4 -- in seconds

	simulation.state.usedAirBoost = false
	simulation.state.airBoostVector = Vector3.zAxis

	-- trick vars
	simulation.state.didTrick = 0

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

	-- -- setup flow moves
	-- local MoveTypeWallride = require(script.Parent.utils.MoveTypeWallride)
	-- MoveTypeWallride:ModifySimulation(simulation)

	-- local MoveTypeRailgrind = require(script.Parent.utils.MoveTypeRailgrind)
	-- MoveTypeRailgrind:ModifySimulation(simulation)

	-- local MoveTypeSplinegrind = require(script.Parent.utils.MoveTypeSplinegrind)
	-- MoveTypeSplinegrind:ModifySimulation(simulation)

	-- setup base walking state
	local MoveTypeBase = require(script.Parent.utils.MoveTypeBase)
	MoveTypeBase:ModifySimulation(simulation)
end

function module:GetCharacterModel(userId, source)
	local srcModel
	local result, err = pcall(function()

		-- --Bot id?
		-- if (string.sub(userId, 1, 1) == "-") then
		-- 	userId = string.sub(userId, 2, string.len(userId)) --drop the -
		-- end

		userId = tonumber(userId)

		local player = game.Players:GetPlayerByUserId(userId)
		local description
		if StarterPlayer.LoadCharacterAppearance then
			description = game.Players:GetHumanoidDescriptionFromUserId(player.CharacterAppearanceId)
		else
			description = game.ReplicatedStorage:WaitForChild("DefaultDescription")
		end
		local dC = description:Clone()
		srcModel = game:GetService("Players"):CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
		
		-- copy template humanoid to player
		local h = srcModel:WaitForChild("Humanoid")
		local animate = srcModel:WaitForChild("Animate") 
		h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		
		h:ClearAllChildren()
		dC.Parent = h
		for _, item in source.template:FindFirstChild("Humanoid"):GetChildren() do
			item:Clone().Parent = h
		end

		local animator = h:WaitForChild("Animator")

		-- clone equipped anims
		local idle = animate.idle:GetChildren()[1]
		animator.Idle.AnimationId = idle.AnimationId
		
		local walk = animate.run:GetChildren()[1]
		animator.Walk.AnimationId = walk.AnimationId

		local jump = animate.jump:GetChildren()[1]
		animator.Jump.AnimationId = jump.AnimationId

		local fall = animate.fall:GetChildren()[1]
		animator.Fall.AnimationId = fall.AnimationId
		
		animate:Destroy()

		srcModel.Parent = game.Lighting
		srcModel.Name = tostring(userId)
		h.DisplayName = player.DisplayName

		-- create nametag
		local head = srcModel:FindFirstChild("Head")
		if head then
			local nameTag = source.template.Head:FindFirstChild("NameTag")
			if nameTag then
				nameTag = nameTag:Clone()
				nameTag.Label.Text = player.DisplayName
				nameTag.PlayerToHideFrom = player
				nameTag.Parent = head
			end
		end
	end)

	if (result == false) then
		warn("Error loading " .. userId .. ": " ..err)
	elseif srcModel then

		local hip = (srcModel.HumanoidRootPart.Size.y
				* 0.5) +srcModel.Humanoid.hipHeight

		local data = { 
			model =	srcModel, 
			modelOffset = Vector3.yAxis * (hip - 2.55)
		}

		return data
	end
end


return module