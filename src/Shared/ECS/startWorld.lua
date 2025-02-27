-- https://github.com/YetAnotherClown/Net/blob/main/example/matter/src/shared/start.lua

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Signal = require(Packages.Signal)
local Timer = require(Packages.Timer)
local Matter = require(ReplicatedStorage.Packages.Matter)
local Plasma = require(Packages.Plasma)
local HotReloader = require(Packages.Rewire).HotReloader
local Net = require(Packages.Net)
local Components = require(script.Parent.Components)
local Routes = require(script.Parent.Routes)

local function start(containers)
	local world = Matter.World.new()
	local state = {
		debugServerModels = false
	}

	local debugger = Matter.Debugger.new(Plasma)

	debugger.findInstanceFromEntity = function(id)
		if not world:contains(id) then
			return
		end

		local model = world:get(id, Components.Model)

		return model and model.model or nil
	end

	local loop = Matter.Loop.new(world, state, debugger:getWidgets())

	-- Hook Net to middleware
	Net.start(loop, Routes)

	-- Set up hot reloading

	local hotReloader = HotReloader.new()

	local firstRunSystems = {}
	local systemsByModule = {}

	local function loadModule(module, context)
		local originalModule = context.originalModule

		local ok, system = pcall(require, module)

		if not ok then
			warn("Error when hot-reloading system", module.name, system)
			return
		end

		if firstRunSystems then
			table.insert(firstRunSystems, system)
		elseif systemsByModule[originalModule] then
			loop:replaceSystem(systemsByModule[originalModule], system)
			debugger:replaceSystem(systemsByModule[originalModule], system)
		else
			loop:scheduleSystem(system)
		end

		systemsByModule[originalModule] = system
	end

	local function unloadModule(_, context)
		if context.isReloading then
			return
		end

		local originalModule = context.originalModule
		if systemsByModule[originalModule] then
			loop:evictSystem(systemsByModule[originalModule])
			systemsByModule[originalModule] = nil
		end
	end

	for _, container in containers do
		hotReloader:scan(container, loadModule, unloadModule)
	end

	loop:scheduleSystems(firstRunSystems)
	firstRunSystems = {}

	debugger:autoInitialize(loop)

	-- Begin running our systems
	local step = Signal.new()
	local _event = Timer.Simple(1/20, function()
		step:Fire()
	end, true, RunService.PreAnimation)
	loop:begin({
		default = RunService.PreAnimation,
		MoveStep = step,
	})

	if RunService:IsClient() then
		UserInputService.InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.F4 then
				debugger:toggle()

				state.debugEnabled = debugger.enabled
			end
		end)
	end

	return world, state
end

return start