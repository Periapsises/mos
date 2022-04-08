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
function Tabs:CreateHandler()
    local handler = {}
    handler.container = vgui.Create( "MosEditor_TabContainer" )
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
    if self.files[filepath] then
        return self.files[filepath]
    end

    local tab = vgui.Create( "MosEditor_Tab", self.container )
    tab:SetFile( filepath )

    table.insert( self.tabs, tab )
    self.files[filepath] = tab

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

end

function TAB:SetFile( filepath )

end

vgui.Register( "MosEditor_Tab", TAB, "DButton" )
