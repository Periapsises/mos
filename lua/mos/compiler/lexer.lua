local lower, len, explode = string.lower, string.len, string.Explode

Mos.Compiler.Lexer = Mos.Compiler.Lexer or {}
local Lexer = Mos.Compiler.Lexer

Lexer.__index = Lexer

--------------------------------------------------
-- Lexer API

function Lexer:Create( text )
    local lexer = {}
    lexer.text = string.gsub( lower( text ), "\n+", "\n" )
    lexer.pos = 1

    lexer.line = 1
    lexer.char = 1

    return setmetatable( lexer, self )
end

--------------------------------------------------
-- Lexer metamethods

Lexer.patterns = {
    {token = "Identifier", pattern = "^[_%a][_%.%w]*"},
    {token = "Number", pattern = "^%d+"},
    {token = "Number", pattern = "^0[bdhx]%x+"},
    {token = "String", pattern = "^\".-[^\\]\""},
    {token = "String", pattern = "^'.-[^\\]'"},
    {token = "LParen", pattern = "^%("},
    {token = "RParen", pattern = "^%)"},
    {token = "LSqrBracket", pattern  = "^%["},
    {token = "RSqrBracket", pattern  = "^%]"},
    {token = "Operator", pattern = "^[%+%-%*/]"},
    {token = "Comma", pattern = "^,"},
    {token = "Colon", pattern = "^:"},
    {token = "Hash", pattern = "^#"},
    {token = "Dot", pattern = "^%."},
    {token = "Whitespace", pattern = "^ +", discard = true},
    {token = "Newline", pattern = "^\n"},
    {token = "Comment", pattern = "^//[^\n]*", discard = true},
    {token = "Comment", pattern = "^/%*.-%*/", discard = true}
}

function Lexer:Token( type, value )
    return {type = type, value = value, line = self.line, char = self.char}
end

function Lexer:GetNextToken()
    local text = string.sub( self.text, self.pos )
    local match, size, info = "", 0, {}

    for _, pattern in ipairs( self.patterns ) do
        local result = string.match( text, pattern.pattern )

        if result and len( result ) > size then
            match = result
            size = len( result )
            info = pattern
        end
    end

    if size > 0 then
        local lines = explode( "\n", match, false )
        local lcount = #lines

        self.pos = self.pos + len( match )

        self.line = self.line + ( lcount - 1 )
        self.char = self.char + len( match )

        if lcount > 1 then
            self.char = len( lines[lcount] ) + 1
        end

        if info.discard then
            return self:GetNextToken()
        end

        return self:Token( info.token, match )
    end

    return self:Token( "Eof", "" )
end
