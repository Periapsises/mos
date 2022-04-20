Mos.FileSystem.FolderFunctions = {}
local FolderFunctions = Mos.FileSystem.FolderFunctions

--[[
    @name Folder:AddFile( node )
    @desc Adds a new file in the folder

    @param FolderNode node - The node pointing to the folder to which the file will be added
]]
function FolderFunctions:AddFile( node )
    local new = node:AddNode( "", "icon16/page_white.png" )
    new:ExpandTo( true )

    local entry = vgui.Create( "DTextEntry", new )
    entry:DockMargin( 38, 0, 0, 0 )
    entry:Dock( FILL )
    entry:RequestFocus()

    function entry:OnEnter()
        local fileName = self:GetValue()

        if fileName == "" then
            return self:Remove()
        end

        fileName = Mos.FileSystem.GetSanitizedPath( fileName )
        local path = node:GetFolder() .. "/" .. fileName

        file.Write( path, "" )
        new:SetFileName( path )

        self:Remove()
    end
end

--[[
    @name Folder:AddFolder( node )
    @desc Adds a subfolder in the folder

    @param FolderNode node - The node pointing to the folder to which a new subfolder will be added
]]
function FolderFunctions:AddFolder( node )
    local new = node:AddNode( "", "icon16/folder.png" )
    new:ExpandTo( true )

    local entry = vgui.Create( "DTextEntry", new )
    entry:DockMargin( 38, 0, 0, 0 )
    entry:Dock( FILL )
    entry:RequestFocus()

    function entry:OnEnter()
        local text = self:GetValue()

        if text == "" then
            return self:Remove()
        end

        local path = node:GetFolder() .. "/" .. text

        file.CreateDir( path )
        new:SetFolder( path )

        new.Label:SetText( text )

        self:Remove()
    end
end

--[[
    @name Folder:Rename( node )
    @desc Renames a folder

    @param FolderNode node - The node pointing to the folder to be renamed
]]
function FolderFunctions:Rename( node )
    local name = node:GetFolder()

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

        local path = string.GetPathFromFilename( name )

        file.Rename( name, path .. "/" .. text )
        node.SetFolder( node, path .. "/" .. text )
        node.Label:SetText( text )

        self:Remove()
    end
end

local function deleteRecursive( path )
    local files, folders = file.Find( path .. "/*", "DATA" )

    for _, folder in ipairs( folders ) do
        deleteRecursive( path .. "/" .. folder )
    end

    for _, _file in ipairs( files ) do
        file.Delete( path .. "/" .. _file )
    end

    file.Delete( path )
end

--[[
    @name Folder:Delete( node )
    @desc Deletes a folder

    @param FolderNode node - The node pointing to the folder to be deleted
]]
function FolderFunctions:Delete( node )
    local path = node:GetFolder()
    local name = string.GetFileFromFilename( path )

    Derma_Query( "Are you sure you want to delete " .. name .. " and its contents?", "Delete Folder",
        "Delete", function()
            deleteRecursive( path )

            node:Remove()
        end,
        "Cancel"
    )
end
