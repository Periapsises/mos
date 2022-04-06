local tabs = {}
Mos.tabs = tabs

--------------------------------------------------
-- Tab

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

function CONTAINER:CreateTab()
    local tab = vgui.Create( "MosEditorTab", self )
    tab:Dock( LEFT )
    tab:SetSize( 128, self:GetTall() )
    tab:Droppable( "MosEditor_TabDragNDrop" )

    return tab
end

vgui.Register( "MosTabContainer", CONTAINER, "DPanel" )
