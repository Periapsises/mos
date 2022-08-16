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

TOOL.ClientConVar.model = "models/mos/processor.mdl"
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
    mapper:SetModel( self:GetClientInfo( "model" ) )
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

function TOOL:Think()
    local model = self:GetClientInfo( "model" )
    local ghost = self.GhostEntity or self:MakeGhostEntity( model, Vector(), Angle() )

    if not IsValid( ghost ) then return end

    if ghost:GetModel() ~= model then
        ghost:SetModel( model )
    end

    local trace = self:GetOwner():GetEyeTrace()
    local ent = trace.Entity

    if IsValid( ent ) and ( ent:GetClass() == "mos_memory_map" or ent:IsPlayer() ) then
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

if SERVER then return end

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

    panel:PropSelect( "Model", "mos_memory_map_model", models )

    local presetContainer = vgui.Create( "DPanel" )
    presetContainer:SetHeight( 24 )

    local presetSave = vgui.Create( "DButton", presetContainer )
    presetSave:SetText( "" )
    presetSave:SetIcon( "icon16/disk.png" )
    presetSave:SetWidth( 24 )
    presetSave:Dock( RIGHT )

    local presetSelection = vgui.Create( "DComboBox", presetContainer )
    presetSelection:Dock( FILL )
    presetSelection:AddChoice( "Default", nil, true )

    panel:AddItem( presetContainer )

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
