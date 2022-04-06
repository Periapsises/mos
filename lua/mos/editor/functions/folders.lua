local folderFunctions = {}

function folderFunctions.addFile( node )
    local new = node:AddNode( "", "icon16/page_code.png" )
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

        if not string.EndsWith( text, ".txt" ) then
            text = text .. ".txt"
        end

        local path = node:GetFolder() .. "/" .. text

        file.Write( path, "" )
        new:SetFileName( text )

        new.Label:SetText( text )

        self:Remove()
    end
end

function folderFunctions.addFolder( node )
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

function folderFunctions.rename( node )
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

function folderFunctions.delete( node )
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

return folderFunctions
