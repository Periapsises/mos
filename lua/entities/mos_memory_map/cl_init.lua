include( "sh_init.lua" )
DEFINE_BASECLASS( "base_gmodentity" )

function ENT:Initialize()
end

if WireLib then
    function ENT:DrawTranslucent()
        self:DrawModel()
        Wire_Render( self )
    end
else
    function ENT:DrawTranslucent()
        self:DrawModel()
    end
end
