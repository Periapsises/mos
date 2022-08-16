AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "sh_init.lua" )
include( "sh_init.lua" )

function ENT:Initialize()
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetCollisionGroup( COLLISION_GROUP_WORLD )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )

    if WireLib then
        self.Inputs = WireLib.CreateSpecialInputs( self, { "Processor", "Device" }, { "WIRELINK", "WIRELINK" }, { "", "" } )
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:Think()
end

function ENT:TriggerInput()
end

function ENT:ReadCell( address )
    if address < self.AddrStart or address > self.AddrEnd then return end
    if not IsValid( self.Inputs.Device.Value ) then return end

    return self.Inputs.Device.Value:ReadCell( address - self.AddrStart + self.AddrMap )
end

function ENT:WriteCell( address, value )
    if address < self.AddrStart or address > self.AddrEnd then return end
    if not IsValid( self.Inputs.Device.Value ) then return end

    self.Inputs.Device.Value:WriteCell( address - self.AddrStart + self.AddrMap, value )
end
