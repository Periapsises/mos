Mos.FileSystem.FileFunctions = {}
local FileFunctions = Mos.FileSystem.FileFunctions

--[[
    @name File:Open()
    @desc Opens a file in a new tab

    @param FileNode node: The node pointing to the file to open
]]
function FileFunctions:Open( node )
    Mos.Editor:AddTab( node:GetFileName() )
end

--[[
    @name File:Rename()
    @desc Renames a file

    @param FileNode node: The node pointing to the file to be renamed
]]
function FileFunctions:Rename( node )
    local name = node:GetFileName()

    local entry = vgui.Create( "DTextEntry", node )
    entry:DockMargin( 38, 0, 0, 0 )
    entry:Dock( FILL )
    entry:RequestFocus()
    entry:SetValue( Mos.FileSystem.GetDirtyPath( string.GetFileFromFilename( name ) ) )
    entry:SelectAllText()

    function entry:OnEnter()
        local fileName = self:GetValue()

        if fileName == "" then
            return self:Remove()
        end

        fileName = Mos.FileSystem.GetSanitizedPath( fileName )

        local path = string.GetPathFromFilename( name )

        file.Rename( name, path .. "/" .. fileName )
        node.SetFileName( node, path .. "/" .. fileName )
        node.Label:SetText( Mos.FileSystem.GetDirtyPath( fileName ) )

        self:Remove()
    end
end

--[[
    @name File:Delete()
    @desc Deletes a file

    @param FileNode node: The node pointing to the file to be deleted
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
