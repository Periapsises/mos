TOOL.Tab = "Wire"
TOOL.Category = "Chips, Gates"
TOOL.Name = "Mos6502"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add( "tool.mos6502.name", "Mos6502 Processor" )
    language.Add( "tool.mos6502.desc", "Spawn or open the editor for a Mos6502 Processor." )
    language.Add( "tool.mos6502.left", "Spawn a processor" )
    language.Add( "tool.mos6502.right", "Open the editor" )
    language.Add( "tool.mos6502.reload", "Reload the currently running code" )

    TOOL.Information = { "left", "right", "reload" }
end

function TOOL:LeftClick( trace )
    if not trace.HitPos or trace.Entity:IsPlayer() then
        return false
    end

    if CLIENT then return true end

    local chip = ents.Create( "mos6502" )
    if not IsValid( chip ) then return false end

    local ang = trace.HitNormal:Angle()
    ang.pitch = ang.pitch + 90

    chip:SetModel( "models/mos6502/mos6502.mdl" )
    chip:SetPos( trace.HitPos - trace.HitNormal * chip:OBBMins().z )
    chip:SetAngles( ang )
    chip:Spawn()

    undo.Create( "Mos6502 Processor" )
    undo.AddEntity( chip )
    undo.SetPlayer( self:GetOwner() )
    undo.Finish()
end

function TOOL:RightClick( trace )
    local ply = self:GetOwner()
    local ent = trace.Entity

    if IsValid( ent ) and ent:GetClass() == "mos6502" then
        if gamemode.Call( "CanTool", ply, trace ) ~= false then
            
        end
    else

    end

    return false
end

function TOOL:Reload( trace )
    local ply = self:GetOwner()
    local ent = trace.Entity

    if not IsValid( ent ) or ent:GetClass() ~= "mos6502" then return false end

    if gamemode.Call( "CanTool", ply, trace ) ~= false then
        return true
    end
end

function TOOL:Think()
    local ghost = self.GhostEntity or self:MakeGhostEntity( "models/mos6502/mos6502.mdl", Vector(), Angle() )

    if IsValid( ghost ) then
        local trace = self:GetOwner():GetEyeTrace()
        local ent = trace.Entity

        if IsValid( ent ) and ( ent:GetClass() == "mos6502" or ent:IsPlayer() ) then
            ghost:SetNoDraw( true )
        else
            local ang = trace.HitNormal:Angle()
            ang.pitch = ang.pitch + 90

            local min = ghost:OBBMins()

            ghost:SetPos( trace.HitPos - trace.HitNormal * min.z )
            ghost:SetAngles( ang )

            ghost:SetNoDraw( false )
        end
    end
end
