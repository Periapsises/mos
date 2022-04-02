if SERVER then
    return util.AddNetworkString( "mos_editor_open" )
end

include( "mos/editor/filebrowser.lua" )
include( "mos/editor/mostextentry.lua" )

local defaultWidth, defaultHeight = ScrW() / 3 * 2, ScrH() / 3 * 2
local defaultX, defaultY = defaultWidth / 4, defaultHeight / 4

local editorWidth = CreateConVar( "mos_editor_width", defaultWidth, FCVAR_ARCHIVE, "The width of the Mos Editor", 240 )
local editorHeight = CreateConVar( "mos_editor_height", defaultHeight, FCVAR_ARCHIVE, "The height of the Mos Editor", 135 )

local editorPosX = CreateConVar( "mos_editor_pos_x", defaultX, FCVAR_ARCHIVE, "The x position of the Mos Editor" )
local editorPosY = CreateConVar( "mos_editor_pos_y", defaultY, FCVAR_ARCHIVE, "The y position of the Mos Editor" )

local PANEL = {}

function PANEL:Init()
    local x, y = editorPosX:GetInt(), editorPosY:GetInt()
    local w, h = editorWidth:GetInt(), editorHeight:GetInt()

    self:SetTitle( "Mos6502 Editor" )
    self:SetPos( x, y )
    self:SetSize( w, h )
    self:SetSizable( true )

    local hDivider = vgui.Create( "DHorizontalDivider", self )
    hDivider:Dock( FILL )

    local browser = vgui.Create( "MosFileBrowser" )
    hDivider:SetLeft( browser )

    function browser:Paint( w, h )
        surface.SetDrawColor( Color( 20, 20, 20 ) )
        surface.DrawRect( 0, 0, w, h )
    end

    local container = vgui.Create( "DPanel" )
    hDivider:SetRight( container )

    local vDivider = vgui.Create( "DVerticalDivider", container )
    vDivider:Dock( FILL )

    local entry = vgui.Create( "MosTextEntry" )
    vDivider:SetTop( entry )
    entry:Dock( FILL )

    vDivider:SetTopHeight( 600 )
    hDivider:SetLeftWidth( 240 )

    self._PerformLayout = self.PerformLayout
    function self:PerformLayout( ... )
        editorWidth:SetInt( self:GetWide() )
        editorHeight:SetInt( self:GetTall() )
        editorPosX:SetInt( self:GetX() )
        editorPosY:SetInt( self:GetY() )

        return self:_PerformLayout( ... )
    end

    self.entry = entry
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
