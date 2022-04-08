if SERVER then
    return util.AddNetworkString( "mos_editor_open" )
end

include( "mos/editor/filebrowser.lua" )
include( "mos/editor/tabs.lua" )

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

    self:SetTitle( "" )
    self:SetPos( x, y )
    self:SetSize( w, h )
    self:SetSizable( true )
    self:SetScreenLock( true )
    -- TODO: Uncomment this when releasing (Only for testing purpose)
    --self:SetDeleteOnClose( false )
    self:ShowCloseButton( false )

    local header = vgui.Create( "DPanel", self )
    header:SetSize( w, 26 )
    header:SetPaintBackground( false )

    local icon = vgui.Create( "DImage", header )
    icon:SetSize( 16, 16 )
    icon:DockMargin( 5, 5, 5, 5 )
    icon:Dock( LEFT )
    icon:SetImage( "icon16/tag.png" )

    local closeButton = vgui.Create( "DButton", header )
    closeButton:SetSize( 52, 26 )
    closeButton:Dock( RIGHT )
    closeButton:SetText( "" )
    closeButton.editor = self

    function closeButton:Paint( w, h )
        if self:IsHovered() then
            surface.SetDrawColor( 255, 50, 50, 255 )
            surface.DrawRect( 0, 0, w, h )
        end

        draw.NoTexture()
        surface.SetDrawColor( 150, 150, 150, 255 )
        surface.DrawTexturedRectRotated( w / 2, h / 2, 16, 3, 45 )
        surface.DrawTexturedRectRotated( w / 2, h / 2, 15, 3, 135 )

        return true
    end

    function closeButton:OnMousePressed()
        self.editor:Close()
    end

    local browser = vgui.Create( "MosFileBrowser", self )
    browser:Dock( LEFT )
    browser:SetWide( 256 )

    local tabHandler = Mos.tabs:getHandler( self )
    tabHandler.panel:Dock( TOP )
    tabHandler.panel:SetTall( 31 )

    local tab = tabHandler:CreateTab()
    tab:SetMode( "edit" )

    local dhtml = vgui.Create( "DHTML", self )
    dhtml:Dock( FILL )
    dhtml:OpenURL( "https://periapsises.github.io/" )

    dhtml:AddFunction( "GLua", "onTextChanged", function( text, changed )
        if not tabHandler.activeTab then return end

        tabHandler.activeTab:SetChanged( changed )
    end )

    dhtml:AddFunction( "GLua", "onSave", function( content )
        if not tabHandler.activeTab then return end

        -- TODO: Add save to new file feature
        if not tabHandler.activeTab.file then return end

        tabHandler.activeTab:SetChanged( false )
        file.Write( tabHandler.activeTab.file, content )
    end )

    self.tabHandler = tabHandler
    self.dhtml = dhtml
end

function PANEL:Open()
    self:SetVisible( true )
    self:MakePopup()
end

function PANEL:Paint( w, h )
    surface.SetDrawColor( 32, 32, 32, 255 )
    surface.DrawRect( 0, 0, w, h )
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
