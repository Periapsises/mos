TOOL.Tab = "Wire"
TOOL.Category = "Input, Output/Data Transfer"
TOOL.Name = "Mos Memory Map"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add( "tool.mos_memory_map.name", "Mos Memory Map" )
    language.Add( "tool.mos_memory_map.desc", "Spawn a memory map for use with a Mos Processor." )
    language.Add( "tool.mos_memory_map.left", "Spawn a memory map" )

    TOOL.Information = { "left" }
end

TOOL.ClientConVar.addr_start = 0
TOOL.ClientConVar.addr_end = 1024
TOOL.ClientConVar.addr_map = 0

function TOOL:LeftClick( trace )
    if not trace.HitPos or trace.Entity:IsPlayer() then
        return false
    end

    if CLIENT then return true end

    local ang = trace.HitNormal:Angle()
    ang.pitch = ang.pitch + 90

    local mapper = ents.Create( "mos_memory_map" )
    mapper:SetModel( "models/mos/processor.mdl" )
    mapper:SetPos( trace.HitPos - trace.HitNormal * mapper:OBBMins().z )
    mapper:SetAngles( ang )
    mapper:SetOwner( self:GetOwner() )
    mapper:Spawn()

    mapper.AddrStart = self:GetClientNumber( "addr_start" )
    mapper.AddrEnd = self:GetClientNumber( "addr_end" )
    mapper.AddrMap = self:GetClientNumber( "addr_map" )

    undo.Create( "Mos Memory Map" )
    undo.AddEntity( mapper )
    undo.SetPlayer( self:GetOwner() )
    undo.Finish()
end

if SERVER then return end

function TOOL.BuildCPanel( panel )
    local memStartSlider = vgui.Create( "DNumSlider" )
    memStartSlider:SetText( "Address Start" )
    memStartSlider:SetMinMax( 0, 65535 )
    memStartSlider:SetDecimals( 0 )
    memStartSlider:SetConVar( "mos_memory_map_addr_start" )

    local memEndSlider = vgui.Create( "DNumSlider" )
    memEndSlider:SetText( "Address End" )
    memEndSlider:SetMinMax( 0, 65535 )
    memEndSlider:SetDecimals( 0 )
    memEndSlider:SetConVar( "mos_memory_map_addr_end" )

    local memMapSlider = vgui.Create( "DNumSlider" )
    memMapSlider:SetText( "Mapped Address" )
    memMapSlider:SetMinMax( 0, 65535 )
    memMapSlider:SetDecimals( 0 )
    memMapSlider:SetConVar( "mos_memory_map_addr_map" )

    panel:AddItem( memStartSlider )
    panel:AddItem( memEndSlider )
    panel:AddItem( memMapSlider )
end
