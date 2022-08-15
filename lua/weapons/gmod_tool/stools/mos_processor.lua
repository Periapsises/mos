TOOL.Tab = "Wire"
TOOL.Category = "Chips, Gates"
TOOL.Name = "Mos6502"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add( "tool.mos_processor.name", "Mos6502 Processor" )
    language.Add( "tool.mos_processor.desc", "Spawn or open the editor for a Mos6502 Processor." )
    language.Add( "tool.mos_processor.left", "Spawn a processor" )
    language.Add( "tool.mos_processor.right", "Open the editor" )
    language.Add( "tool.mos_processor.reload", "Reload the currently running code" )

    TOOL.Information = { "left", "right", "reload" }
end

TOOL.ClientConVar.model = "models/mos6502/mos6502.mdl"

function TOOL:LeftClick( trace )
    if not trace.HitPos or trace.Entity:IsPlayer() then
        return false
    end

    if CLIENT then return true end

    local chip = trace.Entity

    if not IsValid( chip ) or chip:GetClass() ~= "mos_processor" then
        chip = ents.Create( "mos_processor" )
        if not IsValid( chip ) then return false end

        local ang = trace.HitNormal:Angle()
        ang.pitch = ang.pitch + 90

        chip:SetModel( self:GetClientInfo( "model" ) )
        chip:SetPos( trace.HitPos - trace.HitNormal * chip:OBBMins().z )
        chip:SetAngles( ang )
        chip:SetOwner( self:GetOwner() )
        chip:Spawn()

        local phys = chip:GetPhysicsObject()
        if IsValid( phys ) then
            phys:EnableMotion( false )
        end

        undo.Create( "Mos 6502 Processor" )
        undo.AddEntity( chip )
        undo.SetPlayer( self:GetOwner() )
        undo.Finish()
    end

    chip:RequestCode()
end

local function openEditor() end

if SERVER then
    openEditor = function( ply )
        net.Start( "mos_editor_open" )
        net.Send( ply )
    end
end

function TOOL:RightClick( trace )
    local ply = self:GetOwner()
    local ent = trace.Entity

    if IsValid( ent ) and ent:GetClass() == "mos_processor" then
        if gamemode.Call( "CanTool", ply, trace ) ~= false then
            openEditor( ply )
        end
    else
        openEditor( ply )
    end

    return false
end

function TOOL:Reload( trace )
    local ply = self:GetOwner()
    local ent = trace.Entity

    if not IsValid( ent ) or ent:GetClass() ~= "mos_processor" then return false end

    if gamemode.Call( "CanTool", ply, trace ) ~= false then
        return true
    end
end

function TOOL:Think()
    local model = self:GetClientInfo( "model" )
    local ghost = self.GhostEntity or self:MakeGhostEntity( model, Vector(), Angle() )

    if not IsValid( ghost ) then return end

    if ghost:GetModel() ~= model then
        ghost:SetModel( model )
    end

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

function TOOL.BuildCPanel( panel )
    local availableModels = { ["models/mos/processor.mdl"] = true }

    local wireModels = list.Get( "Wire_gate_Models" )
    if next( wireModels ) then
        table.Merge( availableModels, wireModels )
    end

    local starfallModels = list.Get( "Wire_gate_Models" )
    if next( starfallModels ) then
        table.Merge( availableModels, starfallModels )
    end

    local models = {}
    for model in pairs( availableModels ) do
        models[model] = { model = model }
    end

    panel:PropSelect( "Model", "mos_processor_model", models )

    panel:Help( "Settings Preset" )

    local presetContainer = vgui.Create( "DPanel" )
    presetContainer:SetHeight( 24 )

    local presetSave = vgui.Create( "DButton", presetContainer )
    presetSave:SetWide( 24 )
    presetSave:Dock( RIGHT )
    presetSave:SetText( "" )
    presetSave:SetIcon( "icon16/disk.png" )

    local presetSelection = vgui.Create( "DComboBox", presetContainer )
    presetSelection:Dock( FILL )
    presetSelection:AddChoice( "Default", nil, true )

    panel:AddItem( presetContainer )
end
