Mos.Compiler.Parser = Mos.Compiler.Parser or {}
local Parser = Mos.Compiler.Parser

include( "mos/compiler/lexer.lua" )

--------------------------------------------------
-- Parser API

function Parser:Create()
    local parser = {}

    return setmetatable( parser, self )
end

--------------------------------------------------
-- Parser metamethods

function Parser:Next()
    self.token = self.token or self.lexer:GetNextToken()
    return self.token
end

function Parser:Eat( type )
    local token = self.token
    if token.type ~= type then
        -- TODO: Properly throw errors
        error( string.format( "Expected %s got %s at line %d, char %d", type, token.type, token.line, token.char ) )
    end

    self.token = self.lexer:GetNextToken()

    return token
end

function Parser:Shift( token )
    table.insert( self.stack, token )
end

function Parser:Reduce( name, amount )
    if amount == -1 then amount = #self.stack end

    if not ammount or amount == 1 then
        local token = table.remove( self.stack )

        return self:Shift( {type = name, value = token, line = token.line, char = token.char} )
    end

    local tokens = {}

    for i = 1, amount do
        table.insert( tokens, 1, table.remove( self.stack ) )
    end

    local top = tokens[1]
    return self:Shift( {type = name, value = tokens, line = top.line, char = top.char} )
end

--------------------------------------------------
-- Parsing

function Parser:Parse()
    --? Make sure there is a token we can read
    self:Next()

    while self.token.type ~= "eof" do
        local token = self.token

        if token.type == "identifier" then
            self:Identifier()
        elseif token.type == "hash" then
            self:Preprocessor()
        elseif token.type == "dot" then
            self:Directive()
        else
            self:Eat( "identifier" )
        end
    end

    return self:Reduce( "program", -1 )
end


