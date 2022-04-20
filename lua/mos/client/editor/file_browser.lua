local FileSystem = Mos.FileSystem

include( "mos/editor/file_functions/files.lua" )
include( "mos/editor/file_functions/folders.lua" )

local ERROR_FAILED_SORT = [[
[mos6502] A set of files or folders failed to be sorted.
File A:
    Is file: %s
    Name: %s

File B:
    Is file: %s
    Name: %s

Please report this error at: https://github.com/Periapsises/Mos6502/issues
]]

local function sortFilesAndFolders( node )
    local originalState = node:GetParentNode():GetExpanded()

    local parent = node:GetParent()
    local children = parent:GetChildren()

    for _, child in ipairs( children ) do child:SetParent() end

    table.sort( children, function( a, b )
        local aIsFile, bIsFile = a:GetFileName() ~= nil, b:GetFileName() ~= nil

        if aIsFile and bIsFile then
            return a.Label:GetText() < b.Label:GetText()
        elseif not aIsFile and bIsFile then
            return true
        elseif aIsFile and not bIsFile then
            return false
        elseif not aIsFile and not bIsFile then
            return a.Label:GetText() < b.Label:GetText()
        end

        ErrorNoHalt( string.format( ERROR_FAILED_SORT, aIsFile, a.Label:GetText(), bIsFile, b.Label:GetText() ) )
    end )

    for _, child in ipairs( children ) do child:SetParent( parent ) end

    parent:InvalidateLayout()
    node:GetParentNode():SetExpanded( originalState )
end

local function onFileNameSet( self, fileName )
    self.path = fileName
    self.dirty = FileSystem:GetDirtyPath( fileName )

    self:_SetFileName( fileName )
    self.Label:SetText( string.GetFileFromFilename( self.dirty ) )

    local extension = string.GetExtensionFromFilename( self.dirty )
    self:SetIcon( FileSystem.associations.files[extension] or "icon16/page_white.png" )

    sortFilesAndFolders( self )
end

local function onFolderSet( self, folder )
    self:_SetFolder( folder )

    local folderName = string.lower( string.match( folder, "/([^/]+)$" ) or "" )
    self:SetIcon( FileSystem.associations.folders[folderName] or self:GetIcon() )

    sortFilesAndFolders( self )
end

--? Custom function to add callbacks to every node in the DTree once they are added
--? Makes stuff like file and folder icon association possible, as well as cleaning up the names
local function onNodeAdded( self, node )
    node._SetFileName = node.SetFileName
    node._SetFolder = node.SetFolder

    node.SetFileName = onFileNameSet
    node.SetFolder = onFolderSet

    node.OnNodeAdded = onNodeAdded
end

local FILEBROWSER = {}

function FILEBROWSER:Init()
    local root = self:Root()
    root.OnNodeAdded = onNodeAdded

    local asm = root:AddFolder( "Assembly", "mos6502/asm", "DATA", true )
    asm:SetIcon( "icon16/package_green.png" )

    local bin = root:AddFolder( "Binaries", "mos6502/bin", "DATA", true )
    bin:SetIcon( "icon16/brick.png" )
end

function FILEBROWSER:Paint( w, h )
    surface.SetDrawColor( 18, 18, 18, 255 )
    surface.DrawRect( 0, 0, w, h )
end

function FILEBROWSER:DoRightClick( node )
    local options = vgui.Create( "DMenu", self:GetParent() )

    if node:GetFileName() then
        options:AddOption( "Open", function() FileSystem.FileFunctions:Open( node ) end )
        options:AddOption( "Rename", function() FileSystem.FileFunctions:Rename( node ) end )

        options:AddSpacer()
        options:AddOption( "Delete", function() FileSystem.FileFunctions:Delete( node ) end )
    else
        options:AddOption( "Add File", function() FileSystem.FolderFunctions:AddFile( node ) end )
        options:AddOption( "Add Folder", function() FileSystem.FolderFunctions:AddFolder( node ) end )

        options:AddSpacer()
        options:AddOption( "Rename", function() FileSystem.FolderFunctions:Rename( node ) end )

        options:AddSpacer()
        options:AddOption( "Delete", function() FileSystem.FolderFunctions:Delete( node ) end )
    end

    options:Open()
end

vgui.Register( "MosEditor_FileBrowser", FILEBROWSER, "DTree" )
