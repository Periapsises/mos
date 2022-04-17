local NOTIFICATION = {}

function NOTIFICATION:Init()
    local parent = self:GetParent()

    self:SetSize( 64, parent:GetTall() )

    self:SetPaintBackgroundEnabled( true )
    self:SetBGColor( Color( 255, 255, 255 ) )
    self:SetTextColor( Color( 255, 255, 255 ) )

    self:SetContentAlignment( 5 )
    self:SetFont( "DermaDefaultBold" )
    self:SetText( "" )

    self:SetX( parent:GetWide() )
end

function NOTIFICATION:Start( time, speed, color )
    self:MoveBy( -64, 0, speed, 0, -1 )
    self:MoveBy( 64, 0, speed, time, -1, function() self:Remove() end )
    self:ColorTo( color, 0.25 )
end

function NOTIFICATION:SetColor( color )
    return self:SetBGColor( color )
end

vgui.Register( "MosEditor_Notification", NOTIFICATION, "DLabel" )
