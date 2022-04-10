if SERVER then
    return util.AddNetworkString( "mos_editor_open" )
end

Mos.Editor = Mos.Editor or {}
local Editor = Mos.Editor

include( "mos/editor/file_system.lua" )
include( "mos/editor/tab_system.lua" )

--------------------------------------------------
-- Editor API

function Editor:Open()
    if not IsValid( self.panel ) then
        self.panel = vgui.Create( "MosEditor" )
    end

    self.panel:Open()
end

function Editor:AddTab( path )
    if not IsValid( self.panel ) then return end

    self.panel.tabs:AddTab( path )
end

--------------------------------------------------
-- Editor panel

local defaultWidth, defaultHeight = ScrW() / 3 * 2, ScrH() / 3 * 2
local defaultX, defaultY = defaultWidth / 4, defaultHeight / 4

local editorWidth = CreateConVar( "mos_editor_width", defaultWidth, FCVAR_ARCHIVE, "The width of the Mos Editor", 240 )
local editorHeight = CreateConVar( "mos_editor_height", defaultHeight, FCVAR_ARCHIVE, "The height of the Mos Editor", 135 )

local editorPosX = CreateConVar( "mos_editor_pos_x", defaultX, FCVAR_ARCHIVE, "The x position of the Mos Editor" )
local editorPosY = CreateConVar( "mos_editor_pos_y", defaultY, FCVAR_ARCHIVE, "The y position of the Mos Editor" )

local editorDividerPos = CreateConVar( "mos_editor_divider_pos", 256, FCVAR_ARCHIVE, "The position of the divider between the file browser and the editor in pixels from the left", 0 )

local PANEL = {}

function PANEL:Init()
    local x, y = editorPosX:GetInt(), editorPosY:GetInt()
    local w, h = editorWidth:GetInt(), editorHeight:GetInt()

    self:SetTitle( "" )
    self:SetPos( x, y )
    self:SetSize( w, h )
    self:SetSizable( true )
    self:SetScreenLock( true )
    -- TODO: Uncomment this when releasing (Only for testing purpose)
    --self:SetDeleteOnClose( false )
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

    local closeButton = vgui.Create( "DButton", header )
    closeButton:SetSize( 46, 30 )
    closeButton:Dock( RIGHT )
    closeButton:SetText( "" )
    closeButton.editor = self

    function closeButton:Paint( w, h )
        if self:IsHovered() then
            surface.SetDrawColor( 255, 50, 50, 255 )
            surface.DrawRect( 0, 0, w, h )
        end

        draw.NoTexture()
        surface.SetDrawColor( 193, 193, 193, 255 )
        surface.DrawTexturedRectRotated( w / 2, h / 2, 15, 2, 45 )
        surface.DrawTexturedRectRotated( w / 2, h / 2, 2, 14, 45 )

        return true
    end

    function closeButton:OnMousePressed()
        self.editor:Close()
    end

    local footer = vgui.Create( "DPanel", self )
    footer:SetTall( 24 )
    footer:Dock( BOTTOM )
    footer:SetPaintBackground( false )

    local horizontalDivider = vgui.Create( "DHorizontalDivider", self )
    horizontalDivider:Dock( FILL )
    horizontalDivider:SetLeftWidth( editorDividerPos:GetInt() )

    horizontalDivider._SetDragging = horizontalDivider.SetDragging
    function horizontalDivider:SetDragging( isDragging )
        if not isDraggin then
            editorDividerPos:SetInt( self:GetLeftWidth() )
        end

        return self:_SetDragging( isDragging )
    end

    function horizontalDivider:Paint( w, h )
        local pos = self:GetLeftWidth() + self:GetDividerWidth() - 1

        surface.SetDrawColor( 169, 115, 255, 255 )
        surface.DrawLine( pos, 0, pos, h )
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

    local dhtml = vgui.Create( "DHTML", right )
    dhtml:Dock( FILL )
    dhtml:OpenURL( "https://periapsises.github.io/" )

    dhtml:AddFunction( "GLua", "onTextChanged", function( text, changed )
        if not tabs.activeTab then return end

        tabs.activeTab:SetChanged( changed )
    end )

    dhtml:AddFunction( "GLua", "onSave", function( content )
        if not tabs.activeTab then return end

        -- TODO: Add save to new file feature
        if not tabs.activeTab.file then return end

        surface.PlaySound( "ambient/water/drip3.wav" )

        local saveNotif = vgui.Create( "DLabel", footer )
        saveNotif:SetSize( 64, 24 )
        saveNotif:SetFont( "DermaDefaultBold" )
        saveNotif:SetText( "Saved" )
        saveNotif:SetTextColor( Color( 255, 255, 255 ) )
        saveNotif.SetColor = saveNotif.SetBGColor
        saveNotif:SetContentAlignment( 5 )
        saveNotif:SetPaintBackgroundEnabled( true )
        saveNotif:SetBGColor( Color( 255, 255, 255 ) )
        saveNotif:SetX( footer:GetWide() )
        saveNotif:MoveBy( -64, 0, 0.1, 0, -1, function()
            timer.Simple( 1, function()
                if not IsValid( saveNotif ) then return end
                saveNotif:MoveBy( 64, 0, 0.1, 0, -1, function() saveNotif:Remove() end )
            end )
        end )
        saveNotif:ColorTo( Color( 150, 255, 150 ), 0.25 )

        tabs.activeTab:SetChanged( false )
        file.Write( tabs.activeTab.file, content )
    end )

    function tabs:OnTabChanged( oldTab, newTab )
        local text = Mos.FileSystem:Read( newTab.file or "mos6502/asm/default.asm" ) or ""
        dhtml:QueueJavascript( "Editor.setCode(`" .. text .. "`);" )
    end

    function tabs:OnLastTabRemoved( tab )
        self:AddTab()
    end

    tabs:AddTab()

    self.tabs = tabs
    self.dhtml = dhtml
end

function PANEL:Open()
    self:SetVisible( true )
    self:MakePopup()
end

function PANEL:Paint( w, h )
    surface.SetDrawColor( 18, 18, 18, 255 )
    surface.DrawRect( 0, 0, w, h )
end

vgui.Register( "MosEditor", PANEL, "DFrame" )

local function onEditorOpen()
    Editor:Open()
end

net.Receive( "mos_editor_open", onEditorOpen )
