local function onApplyCode()
    local entIndex = net.ReadUInt( 16 )
    local length = net.ReadUInt( 16 )
    local code = util.Decompress( net.ReadData( length ) )

    local chip = Entity( entIndex )
    if not IsValid( chip ) then return end

    chip:SetCode( code )
end

net.Receive( "mos_apply_code", onApplyCode )
