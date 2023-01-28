local FILE_BROWSER = {}

function FILE_BROWSER:Init()
    local root = self:Root()

    function root:OnNodeAdded( node )
        node.OnNodeAdded = self.OnNodeAdded

        local name = node:GetText()
        if not name or not name:find( "~%.[^~]*$" ) then return end

        node:SetText( name:gsub( "~%.[^~]*$", "" ) )
    end

    local node = self:AddNode( "Mos", "icon16/package_green.png" )
    node:AddFolder( "Source", "mos/asm", "DATA", true ):SetIcon( "icon16/folder_brick.png" )
    node:AddFolder( "Binary", "mos/bin", "DATA", true ):SetIcon( "icon16/folder_database.png" )
    node:SetExpanded( true )
end

vgui.Register( "MosFileBrowser", FILE_BROWSER, "DTree" )
