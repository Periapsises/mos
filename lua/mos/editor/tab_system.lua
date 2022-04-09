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
    handler.container.handler = handler
    handler.tabs = {}
    handler.files = {}
    handler.history = {}

    return setmetatable( handler, self )
end

--[[
    * Panel TabHandler:AddTab( filepath )

    ? Adds a tab to the handler's container and assigns it to
    ? the specified filepath.
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
    * TabHandler:SelectTab( tab )

    ? Sets a new tab as active and cleans up the previously selected tab
    ? Calls TabHandler:OnTabChanged()
]]
function Tabs:SelectTab( tab )
    if self.activeTab == tab then return end

    local oldtab = self.activeTab

    if oldtab then
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
    * TabHandler:RemoveTab( tab )

    ? Removes a tab from the handler and goes back to the last opened tab
    ? Calls TabHandler:OnTabRemoved()
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
    * TabHandler:OnTabChanged( oldTab, newTab )

    ? Called when the active tab is changed
]]
function Tabs:OnTabChanged( oldTab, newTab ) end

--[[
    * TabHandler:OnTabRemoved( tab )

    ? Called when a tab is removed
]]
function Tabs:OnTabRemoved( tab ) end

--[[
    * TabHandler:OnLastTabRemoved( tab )

    ? Called when a tab is removed and there is no tab left to switch to
]]
function Tabs:OnLastTabRemoved( tab ) end

--------------------------------------------------
-- Tab Container Panel

local CONTAINER = {}

function CONTAINER:Init()

end

function CONTAINER:Paint( w, h )
    surface.SetDrawColor( 64, 64, 64, 255 )
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
    icon:SetSize( 16, 16 )
    icon:DockMargin( 0, 0, 8, 0 )
    icon:Dock( LEFT )
    icon:SetImage( "icon16/page_white.png" )

    local label = vgui.Create( "DLabel", self )
    label:DockMargin( 0, 0, 8, 0 )
    label:Dock( LEFT )
    label:SetText( "Unknown" )

    local status = vgui.Create( "DLabel", self )
    status:SetSize( 8, 16 )
    status:DockMargin( 0, 0, 8, 0 )
    status:Dock( LEFT )
    status:SetText( "" )
    status:SetContentAlignment( 4 )

    local closeButton = vgui.Create( "DButton", self )
    closeButton:SetSize( 16, 16 )
    closeButton:Dock( LEFT )
    closeButton:SetText( "" )

    function closeButton.DoClick()
        self:Remove()
    end

    function closeButton:Paint( w, h )
        local parent = self:GetParent()
        local shouldPaintBackground = self:IsHovered() or parent:IsHovered()

        if shouldPaintBackground then
            draw.RoundedBox( 4, 0, 0, w, h, Color( 64, 64, 64, 255 ) )
        end

        if not shouldPaintBackground and not parent.isActive then return end

        draw.NoTexture()
        surface.SetDrawColor( 128, 128, 128, 255 )
        surface.DrawTexturedRectRotated( w / 2, h / 2, 10, 2, 45 )
        surface.DrawTexturedRectRotated( w / 2, h / 2, 2, 10, 45 )
    end

    self.isActive = true

    self.icon = icon
    self.label = label
    self.status = status

    self:CalculateSize()
end

function TAB:OnRemove()
    self:GetHandler():RemoveTab( self )
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
    -- Padding + Icon + Spacing + Label Size + Spacing + Status + Spacing + Button + Padding
    -- 8 + 16 + 8 + Label Size + 8 + 8 + 8 + 16 + 8 = 80 + Label Sizeà
    -- TODO: Might wanna use contstants and precalculate the result into another variable
    self.label:SizeToContentsX()

    local width = 80 + self.label:GetTextSize()
    self:SetWide( width )

    self:InvalidateLayout()
end

function TAB:Paint( w, h )
    if not self.isActive then return end

    surface.SetDrawColor( 32, 32, 32, 255 )
    surface.DrawRect( 0, 0, w, h )
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
    local name = filepath and string.GetFileFromFilename( filepath ) or "Unknown"
    self.label:SetText( name )
    self.file = filepath

    self:CalculateSize()
end

function TAB:SetChanged( changed )
    self.status:SetText( changed and "*" or "" )
end

vgui.Register( "MosEditor_Tab", TAB, "DButton" )
