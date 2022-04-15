Mos.Compiler.Lexer = Mos.Compiler.Lexer or {}
local Lexer = Mos.Compiler.Lexer

Lexer.__index = Lexer

--------------------------------------------------
-- Lexer API

function Lexer:Create( text )
    local lexer = {}
    lexer.text = string.lower( text )
    lexer.pos = 1

    lexer.line = 1
    lexer.char = 1

    return setmetatable( lexer, self )
end

--------------------------------------------------
-- Lexer metamethods

Lexer.patterns = {
    {token = "identifier", pattern = "^[_%a][_%.%w]*"},
    {token = "number", pattern = "^%d+"},
    {token = "number", pattern = "^0[bdhx]%x+"},
    {token = "lparen", pattern = "^%("},
    {token = "rparen", pattern = "^%)"},
    {token = "operator", pattern = "^[%+%-%*/]"},
    {token = "comma", pattern = "^,"},
    {token = "colon", pattern = "^:"}
}

function Lexer:Token( type, value )
    return {type = type, value = value, line = self.line, char = self.char}
end

function Lexer:GetNextToken()
    local text = string.sub( self.text, self.pos )
    local match, size, info = "", 0, {}

    for _, pattern in ipairs( self.patterns ) do
        local result = string.match( text, pattern.pattern )

        if string.len( result ) > size then
            match = result
            size = string.len( result )
            info = pattern
        end
    end

    if size > 0 then
        local lines = string.Explode( "\n", match, false )

        self.pos = self.pos + string.len( match )

        self.line = self.line + ( #lines - 1 )
        self.char = ( #lines == 1 ) and self.char + string.len( match ) or string.len( lines[#lines] )

        return self:Token( info.token, match )
    end

    return self:Token( "eof", "" )
end
