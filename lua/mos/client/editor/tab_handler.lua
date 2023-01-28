local Editor = Mos.Editor

local TabHandler = Editor.TabHandler or {}
Editor.TabHandler = TabHandler

local tabs = {}

function TabHandler.AddTab( name, path )
    local tab = TabHandler.GetTabByFile( path )
    if tab then return tab end

    tab = Editor.Tab.Create( path )
    tab:SetName( name )
    tab:Focus()

    tabs[path] = tab
end

function TabHandler.GetTabByFile( path )
    return tabs[path]
end

function TabHandler.SetFocused( tab )

end
