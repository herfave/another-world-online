local RunService = game:GetService("RunService")
local MeleeHitbox = {}
MeleeHitbox.__index = MeleeHitbox

local path = game.ReplicatedFirst.Chickynoid
local EffectsModule = require(path.Client.Effects)
local WriteBuffer = require(path.Shared.Vendor.WriteBuffer)
local ReadBuffer = require(path.Shared.Vendor.ReadBuffer)
local Enums = require(path.Shared.Enums)


local isServer = false
if (game:GetService("RunService"):IsServer()) then
    isServer = true
end
local ServerFastProjectiles = nil
local ClientFastProjectiles = nil
local ServerMods = nil
if (isServer) then
	ServerFastProjectiles = require(game.ServerStorage.Modules.ServerChickyMods.ServerFastProjectiles)
	ServerMods = require(game.ServerStorage.Modules.Chickynoid.Server.ServerMods)
end
if (isServer ~= true) then
    ClientFastProjectiles = require(game.ReplicatedFirst.ClientChickyMods.ClientMods.ClientFastProjectiles)
end

function MeleeHitbox.new()
    local self = setmetatable({
        size = Vector3.new(3, 5, 3),

        serial = nil,
        name = nil,
        client = nil,
        weaponModule = nil,
        clientState = nil,
        serverState = nil,
        preservePredictedStateTimer = 0,
        serverStateDirty = false,
        playerRecord = nil,
        state = {},
        previousState = {},
    }, MeleeHitbox)
    return self
end

function MeleeHitbox:ClientThink(_deltaTime)
end

function MeleeHitbox:ClientProcessCommand(command)
    local currentTime = self.totalTime
    local state = self.clientState

    --Predict an attack
    if command.am and command.am ~= 0 then
        self:SetPredictedState()
        local clientChickynoid = self.client:GetClientChickynoid()
        if clientChickynoid then
            local simulation = clientChickynoid.simulation
            local playerRotation = CFrame.fromOrientation(0, simulation.state.angle, 0)
            local origin = simulation.state.position
            local vec = playerRotation.LookVector

            -- do some local effects

            local hitRecord = ClientFastProjectiles:FireBullet(origin, vec, 1000, 10, 0, -1)
            hitRecord.DoCollisionCheck = function(_record, old, new)
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Include
                rayParams.FilterDescendantsInstances = { game.Workspace.GameArea }
                local cf = CFrame.lookAt(old, new)
                return game.Workspace:Blockcast(cf, Vector3.new(5,5,5), cf.LookVector, rayParams)
            end
        end
    end
end


function MeleeHitbox:ClientOnHitImpact(_client, event)
end

function MeleeHitbox:ClientOnBulletFire(_client, event)
end

function MeleeHitbox:ClientSetup() end

function MeleeHitbox:ClientEquip() end

function MeleeHitbox:ClientDequip() end


function MeleeHitbox:ServerSetup()
end

function MeleeHitbox:ServerThink()
    local currentTime = self.totalTime
    local state = self.state
end

function MeleeHitbox:ServerProcessCommand(command)
    local currentTime = self.totalTime
    local state = self.state

    if command.am and command.am ~= 0 then
        local serverChickynoid = self.playerRecord.chickynoid
        if serverChickynoid then
            local simulation = clientChickynoid.simulation
            local playerRotation = CFrame.fromOrientation(0, simulation.state.angle, 0)
            local origin = simulation.state.position
            local vec = playerRotation.LookVector

            local raycastParams = nil

            local bulletRecord = ServerFastProjectiles:FireBullet(origin, vec, 1000, 10, 0, command.serverTime)
            bulletRecord.DoCollisionCheck = function(bulletRecord, old, new)
                --Math to do the collision check
                local vec = (new - old).Unit
                local range = (new - old).Magnitude
                local pos, normal, otherPlayer = self.weaponModule:QueryBullet(
                    self.playerRecord,
                    self.server,
                    old,
                    vec,
                    bulletRecord.serverTime,
                    nil,
                    raycastParams,
                    range,
                    Vector3.new(5,5,5)
                )
         
                if (normal ~= nil) then --hit something
                
                    local surface = 0 --Surface type
                    if otherPlayer then
                        surface = 1 --(blood!)
                    end          
                    bulletRecord.die = true
                    bulletRecord.surface = surface
                    bulletRecord.position = pos
                    bulletRecord.normal = normal
                    bulletRecord.otherPlayer = otherPlayer
                end
            end
        end
    end
end

function MeleeHitbox:BuildFirePacketString(origin, vec, speed, maxDistance, drop, bulletId)
    local buf = WriteBuffer.new()
    
	--these two first always
	buf:WriteI16(self.weaponId)
	buf:WriteU8(self.playerRecord.slot)
    
	buf:WriteVector3(origin)
	buf:WriteVector3(vec)
	buf:WriteFloat16(speed)
	buf:WriteFloat16(maxDistance)
	buf:WriteI16(bulletId)
    
    return buf:GetBuffer()
end

function MeleeHitbox:UnpackPacket(event)

    if (event.t == Enums.EventType.BulletImpact) then
		
		local buf = ReadBuffer.new(event.b)
        
        --these two first always
		event.weaponID = buf:ReadI16()
		event.slot = buf:ReadU8()

		event.position = buf:ReadVector3()
		event.bulletId = buf:ReadI16()
      

		local hasNormal = buf:ReadU8()
        if (hasNormal > 0) then
			event.normal = buf:ReadVector3()
			event.surface = buf:ReadU8()
        end

        return event
    elseif (event.t == Enums.EventType.BulletFire) then
		local buf = ReadBuffer.new(event.b)
        
        --these two first always
        event.weaponID = buf:ReadI16()
		event.slot = buf:ReadU8()
        
		event.origin = buf:ReadVector3()
		event.vec = buf:ReadVector3()
		event.speed = buf:ReadFloat16()
		event.maxDistance = buf:ReadFloat16()
		event.bulletId = buf:ReadI16()
        return event
    end
end

function MeleeHitbox:ServerEquip() end

function MeleeHitbox:ServerDequip() end

function MeleeHitbox:ClientRemoved() end

function MeleeHitbox:ServerRemoved() end

return MeleeHitbox