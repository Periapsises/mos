if SERVER then
    return util.AddNetworkString( "mos_editor_open" )
end

include( "mos/editor/filebrowser.lua" )

local editorWidth = CreateConVar( "mos_editor_width", 960, FCVAR_ARCHIVE, "The width of the Mos Editor", 240 )
local editorHeight = CreateConVar( "mos_editor_height", 540, FCVAR_ARCHIVE, "The height of the Mos Editor", 135 )

local PANEL = {}

function PANEL:Init()
    self:SetTitle( "Mos6502 Editor" )

    local w, h = editorWidth:GetInt(), editorHeight:GetInt()

    self:SetSize( w, h )
    self:Center()
    self:SetSizable( true )

    local divider = vgui.Create( "DHorizontalDivider", self )
    divider:Dock( FILL )
    divider:SetLeftWidth( 240 )

    local browser = vgui.Create( "MosFileBrowser" )

    local right = vgui.Create( "DPanel" )
    divider:SetLeft( browser )
    divider:SetRight( right )

    local options = vgui.Create( "DPanel", right )
    options:SetTall( 24 )
    options:Dock( TOP )

    local entry = vgui.Create( "RichText", right )
    entry:Dock( FILL )

    self.entry = entry
end

function PANEL:OnSizeChanged( width, height )
    editorWidth:SetInt( width )
    editorHeight:SetInt( height )
end

function PANEL:Open()
    self:MakePopup()
    self.entry:RequestFocus()
end

vgui.Register( "MosEditor", PANEL, "DFrame" )

local editor = {}
Mos.editor = editor

function editor:open()
    if not IsValid( self.panel ) then
        self.panel = vgui.Create( "MosEditor" )
    end

    self.panel:Open()
end

local function onEditorOpen()
    editor:open()
end

net.Receive( "mos_editor_open", onEditorOpen )
