Mos.FileSystem.FileFunctions = {}
local FileFunctions = Mos.FileSystem.FileFunctions

--[[
    @name File:Open( node )
    @desc Opens a file in a new tab

    @param FileNode node - The node pointing to the file to open
]]
function FileFunctions:Open( node )
    Mos.Editor:AddTab( node:GetFileName() )
end

--[[
    @name File:Rename( node )
    @desc Renames a file

    @param FileNode node - The node pointing to the file to be renamed
]]
function FileFunctions:Rename( node )
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

--[[
    @name File:Delete( node )
    @desc Deletes a file

    @param FileNode node - The node pointing to the file to be deleted
]]
function FileFunctions:Delete( node )
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
