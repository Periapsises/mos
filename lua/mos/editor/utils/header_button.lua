local HEADERBUTTON = {}

function HEADERBUTTON:Init()
    self:SetTextColor( Color( 193, 193, 193 ) )
end

function HEADERBUTTON:Paint( w, h )
    if not self:IsHovered() and not self.showHovered then return end

    surface.SetDrawColor( 58, 58, 58, 255 )
    surface.DrawRect( 0, 0, w, h )
end

function HEADERBUTTON:DoClick()
    local menu = vgui.Create( "DMenu", self )
    self:BuildMenu( menu )

    self.showHovered = true
    function menu.OnRemove()
        self.showHovered = false
    end

    local x, y = self:LocalToScreen( 0, self:GetTall() )
    menu:Open( x, y )
end

function HEADERBUTTON:SetName( text )
    self:SetText( text )
    self:SizeToContentsX()
    self:SetWide( self:GetWide() + 16 )
end

function HEADERBUTTON:BuildMenu( menu ) end

vgui.Register( "MosEditor_HeaderButton", HEADERBUTTON, "DButton" )
