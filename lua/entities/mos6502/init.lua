AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "sh_init.lua" )
include( "sh_init.lua" )

include( "mos/server/processor/processor.lua" )
include( "mos/server/processor/memory_generator.lua" )
local Processor = Mos.Processor

function ENT:Initialize()
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetCollisionGroup( COLLISION_GROUP_WORLD )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )

    self.cpu = setmetatable( {}, Processor )
    self.cpu.memory = {}
    self.cpu:Reset()

    if WireLib then
        self.Inputs = WireLib.CreateInputs( self, {"On", "Clock", "ClockSpeed", "Reset", "Nmi", "Irq"} )
        self.Outputs = WireLib.CreateOutputs( self, {"ProgramCounter", "Memory"} )
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:Think()
    if self.Inputs.On.Value == 0 then return end

    local maxTime = os.clock() + 0.001

    while os.clock() < maxTime do
        self.cpu:Clock()
    end

    if WireLib then
        Wire_TriggerOutput( self, "ProgramCounter", self.cpu.pc )
    end
end

local isMethod = {
    Clock = true,
    Reset = true,
    Nmi = true,
    Irq = true
}

function ENT:TriggerInput( name, value )
    if not isMethod[name] then return end
    if value == 0 then return end

    self.cpu[name]( self.cpu )

    if WireLib then
        Wire_TriggerOutput( self, "ProgramCounter", self.cpu.pc )
    end
end

function ENT:ReadCell( address )
    if address < 0 then return nil end
    if address > 0xffff then return nil end

    return self.cpu.memory[address] or 0
end

function ENT:WriteCell( address )
    if address < 0 then return false end
    if address > 0xffff then return false end

    self.cpu.memory = bit.band( math.floor( address ), 0xff )
end

function ENT:SetCode( code )
    self.cpu:GenerateMemory( code )
    self.cpu:Reset()
end
