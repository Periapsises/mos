include( "mos/language/parser.lua" )
local parser = Mos.parser
local tokenType = parser.tokenTypes

surface.CreateFont( "MosEditorFont", {
    font = "Courier New",
    extended = false,
    size = 20,
    weight = 520,
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
    self:SetFontInternal( "MosEditorFont" )

    self.line = 1
    self.char = 0
end

local theme = {
    [tokenType.comment]       = Color( 100, 200, 75 ),
    [tokenType.label]         = Color( 250, 175, 50 ),
    [tokenType.instruction]   = Color( 100, 125, 255 ),
    [tokenType.number]        = Color( 250, 100, 100 ),
    [tokenType.lquote]        = Color( 75, 255, 75 ),
    [tokenType.rquote]        = Color( 75, 255, 75 ),
    [tokenType.text]          = Color( 125, 255, 125 ),
    [tokenType.escape]        = Color( 255, 255, 150 ),
    [tokenType.shortcut]      = Color( 100, 200, 255 ),
    [tokenType.preprocessor]  = Color( 255, 255, 100 ),
    [tokenType.directive]     = Color( 255, 255, 150 ),
    [tokenType.name]          = Color( 175, 125, 225 )
}

function PANEL:Paint( w, h )
    surface.SetDrawColor( Color( 20, 20, 20 ) )
    surface.DrawRect( 0, 0, w, h )

    local tokens = parser:tokenize( self:GetValue() )
    local drawLine = 1

    surface.SetFont( "MosEditorFont" )
    surface.SetTextPos( 3, drawLine )

    for _, token in ipairs( tokens ) do
        surface.SetTextColor( ( theme[token.type] or Color( 255, 255, 255 ) ):Unpack() )
        surface.DrawText( token.value )

        if token.type == tokenType.newline then
            drawLine = drawLine + charHeight + 1
            surface.SetTextPos( 3, drawLine )
        end
    end

    self:DrawTextEntryText( Color( 0, 0, 0, 0 ), Color( 185, 207, 255), Color( 255, 255, 255, 255 ) )

    return true
end

SEARCH_LEFT = -1
SEARCH_RIGHT = 1

function PANEL:SearchChar( pos, char, direction )
    local text = self:GetValue()
    local count = 0

    while text[pos] ~= "" do
        if text[pos] == char then
            return true, count
        end

        count = count + direction
        pos = pos + direction
    end

    return false, count
end

function PANEL:OnKeyCodeTyped( code )
    if code == KEY_TAB then
        local pos = self:GetCaretPos()
        local text = self:GetValue()

        self:SetText( string.sub( text, 1, pos ) .. "    " .. string.sub( text, pos + 1 ) )
        self:SetCaretPos( pos + 4 )

        return true
    end
end

vgui.Register( "MosTextEntry", PANEL, "TextEntry" )
