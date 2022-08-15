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

    if WireLib then
        self.Inputs = WireLib.CreateInputs( self, {"On", "Clock", "ClockSpeed", "Reset", "Nmi", "Irq"} )
        self.Outputs = WireLib.CreateOutputs( self, {"ProgramCounter", "Memory"} )
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:Think()
    if not self.Inputs then return end
    if self.Inputs.On.Value == 0 then return end

    local maxTime = os.clock() + 0.001

    while os.clock() < maxTime do
        self.emulator:clock()
    end

    if WireLib then
        Wire_TriggerOutput( self, "ProgramCounter", self.emulator.pc )
    end
end

local validMethods = {
    Clock = "clock"
}

function ENT:TriggerInput( name, value )
    if value == 0 then return end

    local method = validMethods[name]
    if method then
        self.emulator[method]( self.emulator )
    end

    if WireLib then
        WireLib.TriggerOutput( self, "ProgramCounter", self.emulator.pc )
    end
end

function ENT:ReadCell( address )
    return self.memory:read( address )
end

function ENT:WriteCell( address, value )
    self.memory:write( address, value )
end

function ENT:RequestCode()
    net.Start( "mos_code_request" )
    net.WriteUInt( self:EntIndex(), 16 )
    net.Send( self:GetOwner() )
end

function ENT:SetCode( code )
    self.memory:generate( code )
end
