local Editor = Mos.Editor

local Tab = Editor.Tab or {}
Editor.Tab = Tab
Tab.__index = Tab

function Tab.Create( path )
    local tab = {
        file = path,
        panel = vgui.Create( "MosEditor_Tab" )
    }

    return setmetatable( tab, Tab )
end

function Tab:Close()

end

function Tab:Focus()
    Editor.TabHandler.SetFocused( self )
end

function Tab:SetName( name )
    self.panel:SetName( name )
end
