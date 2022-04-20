Mos.Editor = Mos.Editor or {}
local Editor = Mos.Editor

include( "mos/editor/file_system.lua" )
include( "mos/editor/tab_system.lua" )
include( "mos/editor/utils/dhtml_window.lua" )
include( "mos/editor/utils/close_button.lua" )
include( "mos/editor/utils/header_button.lua" )
include( "mos/editor/utils/notifications.lua" )

--------------------------------------------------
-- Editor API

function Editor:Open()
    if not IsValid( self.panel ) then
        self.panel = vgui.Create( "MosEditor" )
    end

    self.panel:Open()
end

function Editor:AddTab( path )
    if not self.tabs then return end

    self.tabs:AddTab( path )
end

function Editor:GetActiveTab()
    if not self.tabs then return end

    return self.tabs.activeTab
end

function Editor:SetCode( code )
    code = string.gsub( code, "\\", "\\\\" )
    self.dhtml:QueueJavascript( "Editor.setCode( `" .. code .. "` )" )
end

local function onCodeRequest()
    local entIndex = net.ReadUInt( 16 )

    local tab = Editor:GetActiveTab()
    if not tab or not tab.file then return end

    local path = Mos.FileSystem:GetCompiledPath( tab.file )
    if not Mos.FileSystem:Exists( path ) then return end

    local code = util.Compress( Mos.FileSystem:Read( path ) )
    local length = string.len( code )

    net.Start( "mos_apply_code" )
    net.WriteUInt( entIndex, 16 )
    net.WriteUInt( length, 16 )
    net.WriteData( code, length )
    net.SendToServer()
end

net.Receive( "mos_code_request", onCodeRequest )

--------------------------------------------------
-- Editor panel

local defaultWidth, defaultHeight = ScrW() / 3 * 2, ScrH() / 3 * 2
local defaultX, defaultY = defaultWidth / 4, defaultHeight / 4

local editorWidth = CreateConVar( "mos_editor_width", defaultWidth, FCVAR_ARCHIVE, "The width of the Mos Editor", 240 )
local editorHeight = CreateConVar( "mos_editor_height", defaultHeight, FCVAR_ARCHIVE, "The height of the Mos Editor", 135 )

local editorPosX = CreateConVar( "mos_editor_pos_x", defaultX, FCVAR_ARCHIVE, "The x position of the Mos Editor" )
local editorPosY = CreateConVar( "mos_editor_pos_y", defaultY, FCVAR_ARCHIVE, "The y position of the Mos Editor" )

local editorDividerPos = CreateConVar( "mos_editor_divider_pos", 256, FCVAR_ARCHIVE, "The position of the divider between the file browser and the editor in pixels from the left", 0 )

local EDITOR = {}

function EDITOR:Init()
    local x, y = editorPosX:GetInt(), editorPosY:GetInt()
    local w, h = editorWidth:GetInt(), editorHeight:GetInt()

    self:SetTitle( "" )
    self:SetPos( x, y )
    self:SetSize( w, h )
    self:SetSizable( true )
    self:SetScreenLock( true )
    self:SetDeleteOnClose( false )
    self:ShowCloseButton( false )
    self:DockPadding( 0, 0, 0, 0 )

    local header = vgui.Create( "DPanel", self )
    header:SetSize( w, 30 )
    header:Dock( TOP )
    header:SetPaintBackground( false )

    local icon = vgui.Create( "DImage", header )
    icon:SetSize( 16, 16 )
    icon:DockMargin( 11, 7, 11, 7 )
    icon:Dock( LEFT )
    icon:SetImage( "icon16/tag.png" )

    local closeButton = vgui.Create( "MosEditor_CloseButton", header )
    closeButton:SetSize( 46, 30 )
    closeButton:Dock( RIGHT )
    closeButton.window = self

    local footer = vgui.Create( "DPanel", self )
    footer:SetTall( 22 )
    footer:Dock( BOTTOM )
    footer:SetPaintBackground( false )

    local horizontalDivider = vgui.Create( "DHorizontalDivider", self )
    horizontalDivider:Dock( FILL )
    horizontalDivider:SetLeftWidth( editorDividerPos:GetInt() )

    horizontalDivider._SetDragging = horizontalDivider.SetDragging
    function horizontalDivider:SetDragging( isDragging )
        if not isDragging then
            editorDividerPos:SetInt( self:GetLeftWidth() )
        end

        return self:_SetDragging( isDragging )
    end

    function horizontalDivider:Paint( _, height )
        local pos = self:GetLeftWidth() + self:GetDividerWidth() - 1

        surface.SetDrawColor( 169, 115, 255, 255 )
        surface.DrawLine( pos, 0, pos, height )
    end

    local browser = vgui.Create( "MosEditor_FileBrowser" )
    browser:Dock( LEFT )
    browser:SetWide( 256 )

    horizontalDivider:SetLeft( browser )

    local right = vgui.Create( "DPanel" )
    right:SetPaintBackground( false )

    horizontalDivider:SetRight( right )

    local tabs = Editor.Tabs:CreateHandler( right )
    tabs.container:Dock( TOP )
    tabs.container:SetTall( 32 )

    local dhtml = vgui.Create( "MosEditor_DHTMLWindow", right )
    dhtml:Dock( FILL )

    function tabs:OnTabChanged( _, newTab )
        local text = Mos.FileSystem:Read( newTab.file or "mos6502/asm/default.asm" ) or ""
        Editor:SetCode( text )
    end

    function tabs:OnLastTabRemoved()
        self:AddTab()
    end

    tabs:AddTab()

    self.header = header
    self.footer = footer

    hook.Run( "MosEditor_CreateEditor", self )
end

function EDITOR:Open()
    self:SetVisible( true )
    self:MakePopup()
end

function EDITOR:Paint( w, h )
    surface.SetDrawColor( 18, 18, 18, 255 )
    surface.DrawRect( 0, 0, w, h )
end

vgui.Register( "MosEditor", EDITOR, "DFrame" )

local function onEditorOpen()
    Editor:Open()
end

net.Receive( "mos_editor_open", onEditorOpen )
