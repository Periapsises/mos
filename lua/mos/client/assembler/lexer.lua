local len, explode = string.len, string.Explode

--[[
    @class Lexer
    @desc Takes raw text and attempts to convert it into a stream of tokens
]]
Mos.Assembler.Lexer = Mos.Assembler.Lexer or {}
local Lexer = Mos.Assembler.Lexer

Lexer.__index = Lexer

--------------------------------------------------
-- Lexer API

--[[
    @name Lexer.Create()
    @desc Creates a new lexer object

    @param string text: The text input to tokenize

    @return Lexer: The newly created lexer
]]
function Lexer.Create( text )
    local lexer = {}
    lexer.text = string.gsub( text, "\n+", "\n" ) .. "\n"
    lexer.pos = 1

    lexer.line = 1
    lexer.char = 1

    return setmetatable( lexer, Lexer )
end

--------------------------------------------------
-- Lexer metamethods

Lexer.patterns = {
    {token = "Identifier", pattern = "^[_%a][_%.%w]*"},
    {token = "Number", pattern = "^%d+"},
    {token = "Number", pattern = "^0[bdhxBDHX]%x+"},
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

--[[
    @name Lexer:token()
    @desc Creates a token with a type and value and stores the current line and character

    @param string type: The type of token
    @param string value: The value the token holds

    @return Token: The generated token
]]
function Lexer:token( type, value )
    return {type = type, value = value, line = self.line, char = self.char}
end

--[[
    @name Lexer:getNextToken()
    @desc Attempts to tokenize the text input to return the next token

    @return Token: The next token in the stream
]]
function Lexer:getNextToken()
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
            return self:getNextToken()
        end

        return self:token( info.token, match )
    end

    return self:token( "Eof", "" )
end
