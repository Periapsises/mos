local EDITOR = {}
local EDITOR_MIN_SIZE = 50      -- The minimum size the panel can be resized to
local EDITOR_TOOLBAR_SIZE = 24  -- The size of the toolbar
local EDITOR_HANDLE_SIZE = 20   -- The size of the handles on the sides of the panel

function EDITOR:Init()
    self:SetFocusTopLevel( true )

    self:SetPaintBackgroundEnabled( false )
    self:SetPaintBorderEnabled( false )

    local fileBrowser = vgui.Create( "MosFileBrowser", self )
    fileBrowser:SetWide( 300 )
    fileBrowser:Dock( LEFT )
end

function EDITOR:Think()
    local mouseX = math.Clamp( gui.MouseX(), 1, ScrW() - 1 )
    local mouseY = math.Clamp( gui.MouseY(), 1, ScrH() - 1 )

    if self.SizingLeft then
        local x = mouseX - self.SizingLeft[1]
        x = math.Clamp( x, 0, self.SizingLeft[2] - EDITOR_MIN_SIZE )

        local w = self.SizingLeft[2] - x

        self:SetX( x )
        self:SetWide( w )
    end

    if self.SizingRight then
        local x = mouseX - self.SizingRight
        x = math.Clamp( x, EDITOR_MIN_SIZE, ScrW() - self:GetX() )

        self:SetWide( x )
    end

    if self.SizingBottom then
        local y = mouseY - self.SizingBottom
        y = math.Clamp( y, EDITOR_MIN_SIZE, ScrH() - self:GetY() )

        self:SetTall( y )
    end

    if self.Dragging then
        local x = mouseX - self.Dragging[1]
        local y = mouseY - self.Dragging[2]

        x = math.Clamp( x, 0, ScrW() - self:GetWide() )
        y = math.Clamp( y, 0, ScrH() - self:GetTall() )

        self:SetPos( x, y )
    end

    local screenX, screenY = self:LocalToScreen( 0, 0 )

    if self.Hovered and mouseY < screenY + EDITOR_TOOLBAR_SIZE then
        self:SetCursor( "sizeall" )
        return
    end

    if self.Hovered and mouseY > screenY + self:GetTall() - EDITOR_HANDLE_SIZE then
        if mouseX < screenX + EDITOR_HANDLE_SIZE then
            self:SetCursor( "sizenesw" )
            return
        elseif mouseX > screenX + self:GetWide() - EDITOR_HANDLE_SIZE then
            self:SetCursor( "sizenwse" )
            return
        end

        self:SetCursor( "sizens" )
        return
    end

    if mouseX < screenX + EDITOR_HANDLE_SIZE or mouseX > screenX + self:GetWide() - EDITOR_HANDLE_SIZE then
        self:SetCursor( "sizewe" )
        return
    end

    self:SetCursor( "arrow" )
end

function EDITOR:Paint( w, h )
    surface.SetDrawColor( 255, 255, 255, 255 )
    surface.DrawRect( 0, 0, w, h )
end

function EDITOR:OnMousePressed()
    local screenX, screenY = self:LocalToScreen( 0, 0 )
    local mouseX, mouseY = gui.MousePos()

    if mouseX < screenX + EDITOR_HANDLE_SIZE then
        self.SizingLeft = { mouseX - screenX, screenX + self:GetWide() }
        self:MouseCapture( true )
    end

    if mouseX > screenX + self:GetWide() - EDITOR_HANDLE_SIZE then
        self.SizingRight = mouseX - self:GetWide()
        self:MouseCapture( true )
    end

    if mouseY > screenY + self:GetTall() - EDITOR_HANDLE_SIZE then
        self.SizingBottom = mouseY - self:GetTall()
        self:MouseCapture( true )
    end

    if mouseY < screenY + EDITOR_TOOLBAR_SIZE then
        self.Dragging = { mouseX - screenX, mouseY - screenY }
        self:MouseCapture( true )
    end
end

function EDITOR:OnMouseReleased()
    self.SizingLeft = nil
    self.SizingRight = nil
    self.SizingBottom = nil
    self.Dragging = nil

    self:MouseCapture( false )
end

vgui.Register( "MosEditor", EDITOR, "EditablePanel" )
