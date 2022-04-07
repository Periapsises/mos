local tabs = {}
Mos.tabs = tabs

--------------------------------------------------
-- API

tabs.__index = tabs

function tabs:getHandler( parent )
    local handler = {}
    handler.panel = vgui.Create( "MosTabContainer", parent )

    return setmetatable( handler, self )
end

function tabs:CreateTab()
    local tab = vgui.Create( "MosEditorTab", self.panel )
    tab:Dock( LEFT )
    tab:SetSize( 128, self.panel:GetTall() )
    tab:Droppable( "MosEditor_TabDragNDrop" )

    self.activeTab = tab

    return tab
end

function tabs:saveActive( content )
    if not self.activeTab then return end

    -- TODO: Add save to new file feature
    if not self.activeTab.file then return end

    file.Write( self.activeTab.file, content )
end

--------------------------------------------------
-- Tab

surface.CreateFont( "MosTabName_Preview", {
    font = "Verdana",
    extended = false,
    size = 13,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = true,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = false,
} )

local TAB = {}

function TAB:Init()
    local icon = vgui.Create( "DImage", self )
    icon:Dock( LEFT )
    icon:DockMargin( 0, 0, 8, 0 )
    icon:SetSize( 16, 16 )
    icon:SetImage( "icon16/page_white.png" )

    local label = vgui.Create( "DLabel", self )
    label:Dock( LEFT )
    label:SetText( "Unknown" )
    label:SetFont( "MosTabName_Preview" )

    self.mode = "preview"

    self.label = label
    self.icon = icon
end

function TAB:Paint( w, h )
    surface.SetDrawColor( 200, 200, 200, 255 )
    surface.DrawRect( 0, 0, w, h )

    surface.SetDrawColor( 32, 32, 32, 255 )
    surface.DrawRect( 1, 1, w - 2, h - 2 )
end

function TAB:PerformLayout()
    local h = math.floor( math.max( self:GetTall() - 16, 0 ) / 2 )
    self:DockPadding( 8, h, 0, h )
end

function TAB:SetFile( path )
    self.file = path

    self.label:SetText( string.GetFileFromFilename( path ) )
    self.icon:SetImage( "icon16/page_code.png" )
end

function TAB:SetMode( mode )
    self.mode = mode

    if mode == "edit" then
        self.label:SetFont( "DermaDefault" )
    elseif mode == "preview" then
        self.label:SetFont( "MosTabName_Preview" )
    end
end

vgui.Register( "MosEditorTab", TAB, "DPanel" )

--------------------------------------------------
-- Tab container

local CONTAINER = {}

function CONTAINER:Init()
    self:Receiver( "MosEditor_TabDragNDrop", self.DoDrop )
end

function CONTAINER:Paint( w, h )
    surface.SetDrawColor( 64, 64, 64, 255 )
    surface.DrawRect( 0, 0, w, h )
end

function CONTAINER:DoDrop( panel, panels, dropped, index, x, y )

end

vgui.Register( "MosTabContainer", CONTAINER, "DPanel" )
