Mos.Editor.Tabs = Mos.Editor.Tabs or {}
local Tabs = Mos.Editor.Tabs

local gamma = include( "mos/client/editor/utils/gamma.lua" )

local TAB_PADDING = 8
local TAB_SPACING = 8
local TAB_ICON_SIZE = 16
local TAB_STATUS_WIDTH = 8

--------------------------------------------------
-- Tab API

Tabs.__index = Tabs

--[[
    @name Table Tabs:CreateHandler()
    @desc Creates a new Tab Handler as well as its container panel. Inherits the functions of the Tabs API.

    @return TabHandler: The new tab handler
]]
function Tabs:CreateHandler( parent )
    local handler = {}
    handler.container = vgui.Create( "MosEditor_TabContainer", parent )
    handler.container.handler = handler
    handler.tabs = {}
    handler.files = {}
    handler.history = {}

    Mos.Editor.tabs = handler

    return setmetatable( handler, self )
end

--[[
    @name Panel TabHandler:AddTab()
    @desc Adds a tab to the handler's container and assigns it to the specified filepath.

    @param string filepath: The path to the file represented by the tab

    @return Tab: The tab added
]]
function Tabs:AddTab( filepath )
    if filepath and self.files[filepath] then
        local tab = self.files[filepath]
        tab:Select()

        return tab
    end

    local tab = vgui.Create( "MosEditor_Tab", self.container )
    tab:SetFile( filepath )
    tab:Dock( LEFT )
    tab:Select()

    table.insert( self.tabs, tab )
    self.files[filepath or tostring( tab )] = tab

    return tab
end

--[[
    @name TabHandler:SelectTab()
    @desc Sets a new tab as active and cleans up the previously selected tab. Calls TabHandler:OnTabChanged()

    @param Tab tab: The tab to select
]]
function Tabs:SelectTab( tab )
    if self.activeTab == tab then return end

    local oldtab = self.activeTab

    if IsValid( oldtab ) then
        oldtab:Deselect()
    end

    self.activeTab = tab

    for i = #self.history, 1, -1 do
        if self.history[i] == tab then
            table.remove( self.history, i )
        end
    end

    table.insert( self.history, tab )
    self:OnTabChanged( oldtab, tab )
end

--[[
    @name TabHandler:RemoveTab()
    @desc Removes a tab from the handler and goes back to the last opened tab. Calls TabHandler:OnTabRemoved()

    @param Tab tab: The tab to remove
]]
function Tabs:RemoveTab( tab )
    if self.container:IsMarkedForDeletion() then return end

    table.remove( self.history, tab.historyIndex )

    if tab.file then
        self.files[tab.file] = nil
    end

    if self.activeTab == tab then
        local newTab = self.history[#self.history]

        if newTab then
            newTab:Select()
        else
            self:OnLastTabRemoved( tab )
        end
    end

    self:OnTabRemoved( tab )
end

--[[
    @name TabHandler:OnTabChanged()
    @desc Called when the active tab is changed

    @param Tab oldTab: The tab that was previously active
    @param Tab newTab: The tab that will be set as active instead
]]
function Tabs:OnTabChanged() end

--[[
    @name TabHandler:OnTabRemoved()
    @desc Called when a tab is removed

    @param Tab tab: The tab being removed
]]
function Tabs:OnTabRemoved() end

--[[
    @name TabHandler:OnLastTabRemoved()
    @desc Called when a tab is removed and there is no tab left to switch to

    @param Tab tab: The tab being removed
]]
function Tabs:OnLastTabRemoved() end

--------------------------------------------------
-- Tab Container Panel

local CONTAINER = {}

function CONTAINER:Init()

end

local containerR, containerG, containerB = gamma.applyToRGB( 30, 34, 39 )
function CONTAINER:Paint( w, h )
    surface.SetDrawColor( containerR, containerG, containerB, 255 )
    surface.DrawRect( 0, 0, w, h )
end

vgui.Register( "MosEditor_TabContainer", CONTAINER, "DPanel" )

--------------------------------------------------
-- Tab Panel

local TAB = {}

function TAB:Init()
    self:SetText( "" )
    self:SetTall( self:GetParent():GetTall() )

    local icon = vgui.Create( "DImage", self )
    icon:SetSize( TAB_ICON_SIZE, 16 )
    icon:DockMargin( 0, 0, TAB_SPACING, 0 )
    icon:Dock( LEFT )
    icon:SetImage( "icon16/page_white.png" )

    local label = vgui.Create( "DLabel", self )
    label:DockMargin( 0, 0, TAB_SPACING, 0 )
    label:Dock( LEFT )
    label:SetText( "Unknown" )

    local status = vgui.Create( "DLabel", self )
    status:SetSize( TAB_STATUS_WIDTH, 16 )
    status:DockMargin( 0, 0, TAB_SPACING, 0 )
    status:Dock( LEFT )
    status:SetText( "" )
    status:SetContentAlignment( 4 )

    local closeButton = vgui.Create( "DButton", self )
    closeButton:SetSize( TAB_ICON_SIZE, 16 )
    closeButton:Dock( LEFT )
    closeButton:SetText( "" )

    function closeButton.DoClick()
        self:Remove()
    end

    local hoverR, hoverG, hoverB = gamma.applyToRGB( 63, 68, 75 )
    function closeButton:Paint( w, h )
        local parent = self:GetParent()
        local hovered = self:IsHovered()

        if hovered then
            draw.RoundedBox( 4, 0, 0, w, h, Color( hoverR, hoverG, hoverB, 255 ) )
        end

        if not parent.isActive and not ( parent:IsHovered() or hovered ) then return end

        draw.NoTexture()
        surface.SetDrawColor( 128, 128, 128, 255 )
        surface.DrawTexturedRectRotated( w / 2, h / 2, 10, 2, 45 )
        surface.DrawTexturedRectRotated( w / 2, h / 2, 2, 10, 45 )
    end

    self.isActive = true

    self.icon = icon
    self.label = label
    self.status = status
    self.button = closeButton

    self:CalculateSize()
end

function TAB:OnRemove()
    self:GetHandler():RemoveTab( self )
end

--? Icons and text inside are 16 pixels tall and must remain in the center.
--? Here we calculate the padding needed to achieve that
function TAB:PerformLayout()
    local padding = math.max( self:GetTall() - 16, 0 ) / 2

    self:DockPadding( TAB_PADDING, padding, TAB_PADDING, padding )
end

-- Padding + Icon + Spacing + Label Size + Spacing + Status + Spacing + Button + Padding
local TAB_EXTRA_SIZE = TAB_PADDING * 2 + TAB_ICON_SIZE * 3 + TAB_SPACING * 3

--? Calculates the width of the tab to fit all the content inside
--? Then invalidate the layout to update it
function TAB:CalculateSize()
    self.label:SizeToContentsX()

    local width = TAB_EXTRA_SIZE + self.label:GetTextSize()
    self:SetWide( width )

    self:InvalidateLayout()
end

local tabR, tabG, tabB = gamma.applyToRGB( 35, 39, 46 )
local hoverR, hoverG, hoverB = gamma.applyToRGB( 50, 56, 66 )
local lineR, lineG, lineB = gamma.applyToRGB( 24, 26, 31 )
function TAB:Paint( w, h )
    if self:IsHovered() or self.button:IsHovered() then
        surface.SetDrawColor( hoverR, hoverG, hoverB, 255 )
        surface.DrawRect( 0, 0, w, h )
    elseif self.isActive then
        surface.SetDrawColor( tabR, tabG, tabB, 255 )
        surface.DrawRect( 0, 0, w, h )
    end

    surface.SetDrawColor( lineR, lineG, lineB, 255 )
    surface.DrawRect( w - 1, 0, 1, h )
end

function TAB:DoClick()
    self:Select()
end

function TAB:GetHandler()
    return self:GetParent().handler
end

function TAB:Select()
    self.isActive = true
    self:GetHandler():SelectTab( self )
end

function TAB:Deselect()
    self.isActive = false
end

function TAB:SetFile( filepath )
    if filepath then
        local name = string.GetFileFromFilename( Mos.FileSystem.GetDirtyPath( filepath ) )
        self.label:SetText( name )

        local extension = string.GetExtensionFromFilename( name )
        self.icon:SetImage( Mos.FileSystem.associations.files[extension] or "icon16/page_white.png" )
    else
        self.label:SetText( "Unknown" )
        self.icon:SetImage( "icon16/page_white.png" )
    end

    self.file = filepath
    self:CalculateSize()
end

function TAB:SetChanged( changed )
    self.status:SetText( changed and "*" or "" )
end

vgui.Register( "MosEditor_Tab", TAB, "DButton" )
