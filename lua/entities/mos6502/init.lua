AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "sh_init.lua" )
include( "sh_init.lua" )

include( "mos/server/processor/processor.lua" )

function ENT:Initialize()
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetCollisionGroup( COLLISION_GROUP_WORLD )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )

    self.Processor = Mos.Processor.Create()

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
        self.Processor.emulator:clock()
    end

    if WireLib then
        Wire_TriggerOutput( self, "ProgramCounter", self.cpu.pc )
    end
end

function ENT:TriggerInput( name, value )
    if not isMethod[name] then return end
    if value == 0 then return end

    if self.Processor.emulator[name] then
        self.Processor.emulator[name]()
    end

    if WireLib then
        Wire_TriggerOutput( self, "ProgramCounter", self.cpu.pc )
    end
end

function ENT:ReadCell( address )
    return self.Processor.memory:read( address )
end

function ENT:WriteCell( address, value )
    self.Processor.memory:write( address, value )
end

function ENT:SetCode( code )
    self.Processor.memory:generate( code )
end
