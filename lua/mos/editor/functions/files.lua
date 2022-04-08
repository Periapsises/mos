local fileFunctions = {}

function fileFunctions.open( node )
    Mos.editor.panel.tabs:AddTab( node:GetFileName() )
end

function fileFunctions.rename( node )
    local name = node:GetFileName()

    local entry = vgui.Create( "DTextEntry", node )
    entry:DockMargin( 38, 0, 0, 0 )
    entry:Dock( FILL )
    entry:RequestFocus()
    entry:SetValue( string.GetFileFromFilename( name ) )
    entry:SelectAllText()

    function entry:OnEnter()
        local text = self:GetValue()

        if text == "" then
            return self:Remove()
        end

        if not string.EndsWith( text, ".txt" ) then
            text = text .. ".txt"
        end

        local path = string.GetPathFromFilename( name )

        file.Rename( name, path .. "/" .. text )
        node.SetFileName( node, path .. "/" .. text )
        node.Label:SetText( text )

        self:Remove()
    end
end

function fileFunctions.delete( node )
    local path = node:GetFileName()
    local name = string.GetFileFromFilename( path )

    Derma_Query( "Are you sure you want to delete " .. name .. "?", "Delete File",
        "Delete", function()
            file.Delete( path )

            node:Remove()
        end,
        "Cancel"
    )
end

return fileFunctions
