Mos.Editor.Tabs = Mos.Editor.Tabs or {}
local Tabs = Mos.Editor.Tabs

--------------------------------------------------
-- Tab API

Tabs.__index = Tabs

--[[
    * Table Tabs:CreateHandler()

    ? Creates a new Tab Handler as well as it's container panel.
    ? Inherits the functions of the Tabs API
]]
function Tabs:CreateHandler( parent )
    local handler = {}
    handler.container = vgui.Create( "MosEditor_TabContainer", parent )
    handler.tabs = {}
    handler.files = {}

    return setmetatable( handler, self )
end

--[[
    * Panel TabHandler:AddTab( filepath )

    ? Adds a tab to the handler's container and assigns it to
    ? the specified filepath.
]]
function Tabs:AddTab( filepath )
    if filepath and self.files[filepath] then
        return self.files[filepath]
    end

    local tab = vgui.Create( "MosEditor_Tab", self.container )
    tab:SetFile( filepath )

    table.insert( self.tabs, tab )
    self.files[filepath or tostring( tab )] = tab

    return tab
end

--[[
    * TabHandler:OnTabChanged( oldtab, newtab )

    ? Runs when the active tab is changed
]]
function Tabs:OnTabChanged( oldtab, newtab ) end

--------------------------------------------------
-- Tab Container Panel

local CONTAINER = {}

function CONTAINER:Init()

end

vgui.Register( "MosEditor_TabContainer", CONTAINER, "DPanel" )

--------------------------------------------------
-- Tab Panel

local TAB = {}

function TAB:Init()
    self:SetText( "" )
    self:SetTall( self:GetParent():GetTall() )

    local icon = vgui.Create( "DImage", self )
    icon:SetSize( 16, 16 )
    icon:DockMargin( 0, 0, 8, 0 )
    icon:Dock( LEFT )
    icon:SetImage( "icon16/page_white.png" )

    local label = vgui.Create( "DLabel", self )
    label:Dock( LEFT )
    label:SetText( "Unknown" )

    local closeButton = vgui.Create( "DButton", self )
    closeButton:SetSize( 16, 16 )
    closeButton:Dock( RIGHT )
    closeButton:SetText( "" )

    -- TODO: Add close tab functionality
    function closeButton:DoClick() end

    self.icon = icon
    self.label = label

    self:CalculateSize()
end

--? Icons and text inside are 16 pixels tall and must remain in the center.
--? Here we calculate the padding needed to achieve that
function TAB:PerformLayout()
    local padding = math.max( self:GetTall() - 16, 0 ) / 2

    self:DockPadding( 8, padding, 8, padding )
end

--? Calculates the width of the tab to fit all the content inside
--? Then invalidate the layout to update it
function TAB:CalculateSize()
    -- Padding + Space between elements + Two icons = 16 + ( 8 + 16 ) + ( 2 * 16 ) = 72
    local width = 72 + self.label:GetTextSize()
    self:SetWide( width )

    self:InvalidateLayout()
end

function TAB:SetFile( filepath )
    local name = filepath and string.GetFileFromFilename( filepath ) or "Unknown"
    self.label:SetText( name )

    self:CalculateSize()
end

vgui.Register( "MosEditor_Tab", TAB, "DButton" )
