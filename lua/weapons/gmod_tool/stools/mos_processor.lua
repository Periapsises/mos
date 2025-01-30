TOOL.Tab = "Wire"
TOOL.Category = "Chips, Gates"
TOOL.Name = "Mos Processor"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add( "tool.mos_processor.name", "Mos Processor" )
    language.Add( "tool.mos_processor.desc", "Spawn or open the editor for a Mos Processor." )
    language.Add( "tool.mos_processor.left", "Spawn a processor." )
    language.Add( "tool.mos_processor.right", "Open the editor." )
    language.Add( "tool.mos_processor.reload", "Reload the currently running code." )

    TOOL.Information = { "left", "right", "reload" }
end

TOOL.ClientConVar.model = "models/mos/processor.mdl"

function TOOL:LeftClick( trace )
    if not trace.HitPos or trace.Entity:IsPlayer() then return false end

    if CLIENT then return true end

    local chip = ents.Create( "mos_processor" )
    if not IsValid( chip ) then return false end

    local ang = trace.HitNormal:Angle()
    ang.pitch = ang.pitch + 90

    local model = self:GetClientInfo( "model" ) or "models/mos/processor.mdl"

    chip:SetModel( model )
    chip:SetPos( trace.HitPos - trace.HitNormal * chip:OBBMins().z )
    chip:SetAngles( ang )
    chip:Spawn()

    undo.Create( "Mos Processor" )
    undo.AddEntity( chip )
    undo.SetPlayer( self:GetOwner() )
    undo.Finish()

    return true
end

function TOOL:RightClick( trace )
    local ply = self:GetOwner()
    local ent = trace.Entity

    if IsValid( ent ) and ent:getClas() == "mos_processor" then
        if gamemode.Call( "CanTool", ply, trace ) ~= false then
            -- TODO: Open editor for entity
            return true
        end
    else
        -- TODO: Open new editor
        return true
    end
end

function TOOL:Reload( trace )
    local ply = self:GetOwner()
    local ent = trace.Entity

    if not IsValid( ent ) or ent:GetClass() ~= "mos_processor" then return false end

    if gamemode.Call( "CanTool", ply, trace ) ~= false then
        -- TODO: Reload code
        return true
    end

    return false
end

function TOOL:Think()
    local model = self:GetClientInfo( "model" )
    local ghost = self.GhostEntity or self:MakeGhostEntity( "models/mos/processor.mdl", Vector( 0, 0, 0 ), Angle( 0, 0, 0 ) )
    if not IsValid( ghost ) then return end

    if ghost:GetModel() ~= model then
        ghost:SetModel( model )
    end

    local trace = self:GetOwner():GetEyeTrace()
    local ent = trace.Entity

    if IsValid( ent ) and ( ent:GetClass() == "mos_processor" or ent:IsPlayer() ) then
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

function TOOL.BuildCPanel( panel )
    local availableModels = { ["models/mos/processor.mdl"] = true }

    local wireModels = list.Get( "Wire_gate_Models" )
    if next( wireModels ) then
        table.Merge( availableModels, wireModels )
    end

    local starfallModels = list.Get( "Starfall_gate_Models" )
    if next( starfallModels ) then
        table.Merge( availableModels, starfallModels )
    end

    local models = {}
    for model in pairs( availableModels ) do
        models[model] = { model = model }
    end

    panel:PropSelect( "Model", "mos_processor_model", models )
end
