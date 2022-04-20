local CLOSEBUTTON = {}

function CLOSEBUTTON:Init()
    self:SetText( "" )
end

function CLOSEBUTTON:Paint( w, h )
    if self:IsHovered() then
        surface.SetDrawColor( 255, 50, 50, 255 )
        surface.DrawRect( 0, 0, w, h )
    end

    draw.NoTexture()
    surface.SetDrawColor( 193, 193, 193, 255 )
    surface.DrawTexturedRectRotated( w / 2, h / 2, 15, 2, 45 )
    surface.DrawTexturedRectRotated( w / 2, h / 2, 2, 14, 45 )

    return true
end

function CLOSEBUTTON:OnMousePressed()
    self.window:Close()
end

vgui.Register( "MosEditor_CloseButton", CLOSEBUTTON, "DButton" )
