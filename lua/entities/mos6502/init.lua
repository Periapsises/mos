AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "sh_init.lua" )
include( "sh_init.lua" )

include( "mos/cpu/processor.lua" )
local Processor = Mos.Processor

function ENT:Initialize()
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )

    self.cpu = setmetatable( {}, Processor )
    self.cpu.memory = {}
    self.cpu:Reset()

    if WireLib then
        self.Inputs = WireLib.CreateSpecialInputs( self, {"On", "Speed"}, {"NORMAL", "NORMAL"}, {"Wether the processor is On or Off", "The speed at which the processor runs"} )
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:Think()
    if self.Inputs.On.Value == 0 then return end

    self.cpu:Clock()
end
