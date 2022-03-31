if not file.Exists( "mos6502", "DATA" ) then
    file.CreateDir( "mos6502" )
    file.CreateDir( "mos6502/asm" )
    file.CreateDir( "mos6502/bin" )
end

local PANEL = {}

local function onFileNameSet( self, name )
    self:SetIcon( "icon16/page_code.png" )

    return self:_SetFileName( name )
end

local function onFolderSet( self, folder )
    return self:_SetFolder( folder )
end

local function onNodeAdded( self, node )
    node._SetFileName = node.SetFileName
    node._SetFolder = node.SetFolder

    node.SetFileName = onFileNameSet
    node.SetFolder = onFolderSet

    node.OnNodeAdded = onNodeAdded
end

function PANEL:Init()
    local root = self:Root()
    root.OnNodeAdded = onNodeAdded

    local asm = root:AddFolder( "Assembly", "mos6502/asm", "DATA", true )
    asm:SetIcon( "icon16/package_green.png" )

    local bin = root:AddFolder( "Binaries", "mos6502/bin", "DATA", true )
    bin:SetIcon( "icon16/brick.png" )
end

local function create( node, folder )
    local new = node:AddNode( "", folder and "icon16/folder.png" or "icon16/page_code.png" )
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

        if folder then
            local path = node:GetFolder() .. "/" .. text

            file.CreateDir( path )
            new:SetFolder( path )
        else
            if not string.EndsWith( text, ".txt" ) then
                text = text .. ".txt"
            end

            local path = node:GetFolder() .. "/" .. text

            file.Write( path, "" )
            new:SetFileName( text )
        end

        new.Label:SetText( text )

        self:Remove()
    end
end

local function rename( node, folder )
    local name, func

    if folder then
        name, func = node:GetFolder(), node.SetFolder
    else
        name, func = node:GetFileName(), node.SetFileName
    end

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

        if not folder and not string.EndsWith( text, ".txt" ) then
            text = text .. ".txt"
        end

        local path = string.GetPathFromFilename( name )

        file.Rename( name, path .. "/" .. text )
        func( node, path .. "/" .. text )
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

local function delete( node, folder )
    local type = folder and "folder" or "file"
    local path = node:GetFileName() or node:GetFolder()
    local name = string.GetFileFromFilename( path )

    Derma_Query( "Are you sure you want to delete " .. name .. ( folder and " and its contents" or "" ) .. "?", "Delete " .. type,
        "Delete", function()
            if folder then
                deleteRecursive( path )
            else
                file.Delete( path )
            end

            node:Remove()
        end,
        "Cancel"
    )
end

function PANEL:DoRightClick( node )
    local menu = vgui.Create( "DMenu", self:GetParent() )

    if node:GetFileName() then
        menu:AddOption( "Open", function() end )
        menu:AddOption( "Rename", function() rename( node ) end )

        menu:AddSpacer()
        menu:AddOption( "Delete", function() delete( node ) end )
    else
        menu:AddOption( "Add file", function() create( node ) end )
        menu:AddOption( "Add folder", function() create( node, true ) end )

        menu:AddSpacer()
        menu:AddOption( "Rename", function() rename( node, true ) end )

        menu:AddSpacer()
        menu:AddOption( "Delete", function() delete( node, true ) end )
    end

    menu:Open()
end

vgui.Register( "MosFileBrowser", PANEL, "DTree" )
