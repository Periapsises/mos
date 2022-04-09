local fileFunctions = include( "mos/editor/functions/files.lua" )
local folderFunctions = include( "mos/editor/functions/folders.lua" )

if not file.Exists( "mos6502", "DATA" ) then
    file.CreateDir( "mos6502" )
    file.CreateDir( "mos6502/asm" )
    file.CreateDir( "mos6502/bin" )
end

if not file.Exists( "mos6502/asm/default.asm.txt", "DATA" ) then
    file.Write( "mos6502/asm/default.asm.txt", "/*\n    Mos6502 Editor\n*/\n" )
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

function PANEL:DoRightClick( node )
    local menu = vgui.Create( "DMenu", self:GetParent() )

    if node:GetFileName() then
        menu:AddOption( "Open", function() fileFunctions.open( node, true ) end )
        menu:AddOption( "Rename", function() fileFunctions.rename( node ) end )

        menu:AddSpacer()
        menu:AddOption( "Delete", function() fileFunctions.delete( node ) end )
    else
        menu:AddOption( "Add file", function() folderFunctions.addFile( node ) end )
        menu:AddOption( "Add folder", function() folderFunctions.addFolder( node ) end )

        menu:AddSpacer()
        menu:AddOption( "Rename", function() folderFunctions.rename( node, true ) end )

        menu:AddSpacer()
        menu:AddOption( "Delete", function() folderFunctions.delete( node ) end )
    end

    menu:Open()
end

function PANEL:Paint( w, h )
    surface.SetDrawColor( 16, 16, 16, 255 )
    surface.DrawRect( 0, 0, w, h )

    return true
end


vgui.Register( "MosFileBrowser", PANEL, "DTree" )
