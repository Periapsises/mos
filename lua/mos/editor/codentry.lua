include( "mos/language/parser.lua" )

surface.CreateFont( "MosEditorFont", {
    font = "Courier New", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
    extended = false,
    size = 24,
    weight = 600,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = false
} )

surface.SetFont( "MosEditorFont" )
local charWidth, charHeight = surface.GetTextSize( " " )

local PANEL = {}

function PANEL:Init()
    self:SetMultiline( true )

    self.line = 0
    self.chars = 0
end

function PANEL:Paint( w, h )
    surface.SetDrawColor( Color( 20, 20, 20 ) )
    surface.DrawRect( 0, 0, w, h )

    surface.SetDrawColor( Color( 255, 255, 255 ) )
    surface.DrawLine( 64, 0, 64, h )

    local tokens = Mos.parser:tokenize( self:GetValue() )

    local theme = {
        comment = Color( 100, 200, 75 ),
        label = Color( 250, 175, 50 ),
        instruction = Color( 100, 125, 255 ),
        number = Color( 250, 100, 100 ),
        ["string.start"] = Color( 75, 255, 75 ),
        ["string.end"] = Color( 75, 255, 75 ),
        ["string.text"] = Color( 125, 255, 125 ),
        ["string.escape"] = Color( 255, 255, 150 ),
        directive = Color( 100, 200, 255 ),
        preprocessor = Color( 255, 255, 100 ),
        identifier = Color( 175, 125, 225 )
    }

    local x, y = 68, 0

    for _, token in ipairs( tokens ) do
        x = x + draw.SimpleText( token.value, "MosEditorFont", x, y, theme[token.type] or Color( 255, 255, 255 ) )

        if token.type == "newline" then
            x = 68
            y = y + charHeight
        end
    end

    local pos = self:GetCaretPos()

    surface.SetDrawColor( Color( 255, 255, 255 ) )
    surface.DrawRect( 68 + ( pos - self.chars ) * charWidth, self.line * charHeight, 2, 24 )

    return true
end

function PANEL:OnKeyCodeTyped( key )
    if key == KEY_ENTER then
        self.line = self.line + 1
        self.chars = string.len( self:GetValue() ) + 1
    end
end

vgui.Register( "MosCodeEntry", PANEL, "TextEntry" )
