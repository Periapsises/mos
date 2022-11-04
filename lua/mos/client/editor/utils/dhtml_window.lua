local Editor = Mos.Editor

local DHTMLWINDOW = {}

function DHTMLWINDOW:Init()
    Editor.dhtml = self

    self:OpenURL( "https://periapsises.github.io/mos/editor/" )

    self:AddFunction( "GLua", "onTextChanged", function( _, changed )
        local activeTab = Editor:GetActiveTab()
        if not activeTab then return end

        activeTab:SetChanged( changed )
    end )

    self:AddFunction( "GLua", "onSave", function( content )
        local activeTab = Editor:GetActiveTab()

        if not activeTab then return end
        -- TODO: Add save to new file feature
        if not activeTab.file then return end

        surface.PlaySound( "ambient/water/drip3.wav" )

        local notif = vgui.Create( "MosEditor_Notification", Editor.panel.footer )
        notif:SetText( "Saved" )
        notif:Start( 1, 0.1, Color( 150, 255, 150 ) )

        activeTab:SetChanged( false )
        Mos.FileSystem.Write( activeTab.file, string.gsub( content, "\\\\", "\\" ) )
    end )
end

vgui.Register( "MosEditor_DHTMLWindow", DHTMLWINDOW, "DHTML" )
