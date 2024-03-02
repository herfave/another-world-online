local module = {}
 

local CrunchTable = require(script.Parent.Parent.Vendor.CrunchTable)

function module:GetCommandLayout()
	
	if (self.commandLayout == nil) then
		self.commandLayout = CrunchTable:CreateLayout()	
			
		self.commandLayout:Add("localFrame",CrunchTable.Enum.INT32)
		self.commandLayout:Add("serverTime", CrunchTable.Enum.FLOAT)
		self.commandLayout:Add("deltaTime", CrunchTable.Enum.FLOAT)
		self.commandLayout:Add("snapshotServerFrame", CrunchTable.Enum.INT32)	
		self.commandLayout:Add("playerStateFrame", CrunchTable.Enum.INT32)
		self.commandLayout:Add("shiftLock", CrunchTable.Enum.UBYTE)
		self.commandLayout:Add("x", CrunchTable.Enum.FLOAT)
		self.commandLayout:Add("y", CrunchTable.Enum.FLOAT)
		self.commandLayout:Add("z", CrunchTable.Enum.FLOAT)
		self.commandLayout:Add("fa", CrunchTable.Enum.VECTOR3)
		self.commandLayout:Add("f", CrunchTable.Enum.FLOAT)
		self.commandLayout:Add("j", CrunchTable.Enum.FLOAT)

		self.commandLayout:Add("a", CrunchTable.Enum.INT32) -- attack command
		self.commandLayout:Add("la", CrunchTable.Enum.VECTOR3) -- camera rotation
		self.commandLayout:Add("p", CrunchTable.Enum.VECTOR3) -- camera position
		self.commandLayout:Add("t", CrunchTable.Enum.VECTOR3) -- target
		self.commandLayout:Add("am", CrunchTable.Enum.FLOAT) -- attack multiplier
	end
	
	return self.commandLayout
end

function module:EncodeCommand(command)
	return CrunchTable:BinaryEncodeTable(command, self:GetCommandLayout())
end

function module:DecodeCommand(command)
	return CrunchTable:BinaryDecodeTable(command, self:GetCommandLayout())
end

return module