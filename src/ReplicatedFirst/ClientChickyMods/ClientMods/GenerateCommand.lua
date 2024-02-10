local module = {}
local Commands = script:GetChildren()
module.client = nil

local UserInputService = game:GetService("UserInputService")

--For access to control vectors
local ControlModule = nil --require(PlayerModule:WaitForChild("ControlModule"))

local function GetControlModule()
    if ControlModule == nil then
        local LocalPlayer = game.Players.LocalPlayer
        local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if scripts == nil then
            return nil
        end

        local playerModule = scripts:FindFirstChild("PlayerModule")
        if playerModule == nil then
            return nil
        end

        local controlModule = playerModule:FindFirstChild("ControlModule")
        if controlModule == nil then
            return nil
        end

        ControlModule = require(
            LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule")
        )
    end

    return ControlModule
end

--TODO: Use Setup and create timings with renderstepped/heartbeat things

function module:Setup(_client)
    self.client = _client

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe then
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self.m1down = true
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                self.m2down = true
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                self.m3down = true
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gpe)
        if not gpe then
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self.m1down = false
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                self.m2down = false
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                self.m3down = false
            end
        end
    end)
end

function module:Step(_client, _deltaTime)

end


function module:GenerateCommand(command, serverTime: number, dt: number)
	
	if (command == nil) then
		command = {}
	end
	
    command.x = 0
    command.y = 0
    command.z = 0
    command.deltaTime = dt
    command.serverTime = serverTime
    command.boost = 0
    command.a = 0
    command.la = Vector3.zero
    command.p = Vector3.zero

    GetControlModule()
    if ControlModule ~= nil then
        local moveVector = ControlModule:GetMoveVector() :: Vector3
        if moveVector.Magnitude > 0 then
            moveVector = moveVector.Unit
            command.x = moveVector.X
            command.y = moveVector.Y
            command.z = moveVector.Z
        end
    end
    
    -- This approach isn't ideal but it's the easiest right now
    if not UserInputService:GetFocusedTextBox() then
        local jump = UserInputService:IsKeyDown(Enum.KeyCode.Space)
        local boost = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.Q)
        local lmb = self.m1down
        local rmb = self.m2down
        local mmb = self.m3down
        
        command.y = 0
        if (jump) then
            command.y = 1
        else
            if (self.didAttack == 0) then
                if lmb then
                    self.didAttack = 1
                    command.a = 1
                elseif rmb then
                    self.didAttack = 1
                    command.a = 2
                elseif mmb then
                    self.didAttack = 1
                    command.a = 3
                end
            elseif not self.m1down and not self.m2down and not self.m3down then
                self.didAttack = 0
            end
        end

        if (boost) then
            command.boost = 1
        end

        --Fire!
        command.f = UserInputService:IsKeyDown(Enum.KeyCode.B) and 1 or 0

        -- --Fly?
        -- if UserInputService:IsKeyDown(Enum.KeyCode.F) then
        --     command.flying = 1
        -- end

        -- --Cheat #1 - speed cheat!
        -- if UserInputService:IsKeyDown(Enum.KeyCode.P) then
        --     command.deltaTime *= 3
        -- end

        -- --Cheat #2 - suspend!
        -- if UserInputService:IsKeyDown(Enum.KeyCode.L) then
        --     local function test(f)
        --         return f
        --     end
        --     for j = 1, 2000000 do
        --         local a = j * 12
        --         test(a)
        --     end
        -- end
    end

    if self:GetIsJumping() == true then
        command.y = 1
    end
    
    --fire angles
     command.fa = self:GetAimPoint()
    
    -- camera look direction
    local Camera = workspace.CurrentCamera
    local x,y,z = Camera.CFrame:ToEulerAnglesYXZ()
    command.la = Vector3.new(x,y,z) -- radians!
    command.p = Camera.CFrame.Position

    --Translate the move vector relative to the camera
    local rawMoveVector = self:CalculateRawMoveVector(Vector3.new(command.x, 0, command.z))
    command.x = rawMoveVector.X
    command.z = rawMoveVector.Z

    return command
end

function module:CalculateRawMoveVector(cameraRelativeMoveVector: Vector3)
    local Camera = workspace.CurrentCamera
    local _, yaw = Camera.CFrame:ToEulerAnglesYXZ()
    return CFrame.fromEulerAnglesYXZ(0, yaw, 0) * Vector3.new(cameraRelativeMoveVector.X, 0, cameraRelativeMoveVector.Z)
end

function module:GetIsJumping()
    if ControlModule == nil then
        return false
    end
    if ControlModule.activeController == nil then
        return false
    end

    return ControlModule.activeController:GetIsJumping()
        or (ControlModule.touchJumpController and ControlModule.touchJumpController:GetIsJumping())
end


function module:GetAimPoint()
    local mouse = game.Players.LocalPlayer:GetMouse()
    local ray = game.Workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Whitelist

    local whiteList = { game.Workspace.Terrain }
    local collisionRoot = self.client:GetCollisionRoot()
    if (collisionRoot) then
        table.insert(whiteList, collisionRoot)
    end
    raycastParams.FilterDescendantsInstances = whiteList

    local raycastResults = game.Workspace:Raycast(ray.Origin, ray.Direction * 2000, raycastParams)
    if raycastResults then
        return raycastResults.Position
    end
    --We hit the sky perhaps?
    return ray.Origin + (ray.Direction * 2000)
end

return module