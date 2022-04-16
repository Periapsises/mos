Mos.Compiler.Parser = Mos.Compiler.Parser or {}
local Parser = Mos.Compiler.Parser

local Instructions = Mos.Compiler.Instructions

include( "mos/compiler/lexer.lua" )

--------------------------------------------------
-- Parser API

function Parser:Create()
    local parser = {}

    return setmetatable( parser, self )
end

--------------------------------------------------
-- Parser metamethods

--[[
    @name Parser:Eat( type )
    @desc Pops a token from the stream and returns it. Throws an error if the type isn't the one we expect

    @param string type - The type of token expected
]]
function Parser:Eat( type )
    local token = self.token
    if token.type ~= type then
        -- TODO: Properly throw errors
        error( string.format( "Expected %s got %s at line %d, char %d", type, token.type, token.line, token.char ) )
    end

    self.token = self.lexer:GetNextToken()

    return token
end

--[[
    @name Parser:Shift( token )
    @desc Shifts a token on the stack

    @param Table token - The token to shift
]]
function Parser:Shift( token )
    table.insert( self.stack, token )
end

--[[
    @name Parser:Reduce( name, amount )
    @desc Reduces 'amount' of tokens from the stack into a single token 'name'

    @param string name - The name of the new token
    @param number amount - How many tokens to pop (nil = 1, >1 = stack size - amount)
]]
function Parser:Reduce( name, amount )
    if amount <= 0 then
        amount = #self.stack + amount
    end

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
    self.token = self.token or self.lexer:GetNextToken()

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

    return self:Reduce( "program", 0 )
end

function Parser:Identifier()
    self:Eat( "identifier" )

    if self.token.type == "colon" then
        return self:Label()
    end

    self:Instruction()
end

function Parser:Label()
    self:Eat( "colon" )
    self:Reduce( "label", 1 )
end

function Parser:Instruction()
    local instruction = self:Eat( "identifier" )
    local name = instruction.value

    local adressingModes = Instructions.opcodes[name]

    if not adressingModes then
        -- TODO: Properly throw errors
        error( "Invalid instruction name '" .. name .. "' at line " .. instruction.line .. ", char " .. instruction.char )
    end

    self:AddressingMode()
end

local isAddressingModeToken = {
    ["lsqrbracket"] = "ind",
    ["hash"] = "imm",
}

function Parser:AddressingMode()
    local mode = isAddressingModeToken[self.token.type]
    local token = self:Eat( self.token.type )

    self:Operand()
    self:RegisterIndex()
end

function Parser:RegisterIndex()
    if self.token.type ~= "comma" then return end

    self:Eat( "comma" )
    local register = self:Eat( "identifier" )

    if register.value ~= "x" and register.value ~= "y" then
        -- TODO: Properly throw errors
        error( string.format( "Invalid register : %s at line %d, char %d", token.value, token.line, token.char ) )
    end

    register.type = register.value .. "index"

    self:Shift( register )
end

function Parser:Operand()

end
