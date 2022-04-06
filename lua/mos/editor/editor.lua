if SERVER then
    return util.AddNetworkString( "mos_editor_open" )
end

include( "mos/editor/filebrowser.lua" )

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

    local dhtml = vgui.Create( "DHTML", self )
    dhtml:Dock( FILL )
    dhtml:OpenURL( "https://periapsises.github.io/" )
end

function PANEL:Open()
    self:MakePopup()
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
