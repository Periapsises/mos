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

    undo.Create( "Mos Memory Map" )
    undo.AddEntity( mapper )
    undo.SetPlayer( self:GetOwner() )
    undo.Finish()
end
