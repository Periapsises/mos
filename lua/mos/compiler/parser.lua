Mos.Compiler.Parser = Mos.Compiler.Parser or {}
local Parser = Mos.Compiler.Parser

local Instructions = Mos.Compiler.Instructions

include( "mos/compiler/lexer.lua" )

local function errorf( str, ... )
    error( string.format( str, ... ), 3 )
end

--------------------------------------------------
-- Parser API

Parser.__index = Parser

function Parser:Create( code )
    local parser = {}
    parser.lexer = Mos.Compiler.Lexer:Create( code )

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
        errorf( "Expected %s got %s at line %d, char %d", type, token.type, token.line, token.char )
    end

    self.token = self.lexer:GetNextToken()

    return token
end

--------------------------------------------------
-- Parsing

function Parser:Parse()
    --? Make sure there is a token we can read and discard extra newlines
    while not self.token or self.token.type == "newline" do
        self.token = self.lexer:GetNextToken()
    end

    local program = {type = "program", value = {}, line = 1, char = 1}

    while self.token.type ~= "eof" do
        local token = self.token
        local node

        if token.type == "hash" then
            node = self:Preprocessor()
        elseif token.type == "dot" then
            node = self:Directive()
        else
            node = self:Identifier()
        end

        table.insert( program.value, node )
    end

    return program
end

function Parser:Identifier()
    local id = self:Eat( "identifier" )

    if self.token.type == "colon" then
        self:Label()

        return {type = "label", value = id, line = id.line, char = id.char}
    end

    return self:Instruction( id )
end

function Parser:Label()
    self:Eat( "colon" )
    self:Eat( "newline" )
end

function Parser:Instruction( instruction )
    local name = instruction.value
    local adressingModes = Instructions.bytecodes[name]

    if not adressingModes then
        -- TODO: Properly throw errors
        errorf( "Invalid instruction name '%s' at line %d, char %d", name, instruction.line, instruction.char )
    end

    self:AddressingMode( instruction )
end

--[[

    OK - Zeropage will be ignored for now as it's hard to differenciate from absolute.

    OK - Immediate and idirect have special tokens that let the parser identify them.

    For the rest:
        Start as absolute and perform extra steps after.

        If there are no operands -> Implied
        If there is one identifier with value a -> Accumulator

        Else, if the instruction is a branching instruction -> Relative
]]

local adressingMode = {
    lsqrbracket = "Indirect",
    hash = "Immediate"
}

local isBranchInstruction = {
    bcc = true,
    bcs = true,
    beq = true,
    bmi = true,
    bne = true,
    bpl = true,
    bvc = true,
    bvs = true
}

function Parser:AddressingMode( instruction )
    local token = self.token
    local mode = adressingMode[token.type]

    if mode then
        self:Eat( token.type )
    end

    self:Operand()

    if not mode then
        local stackSize = #self.stack
        mode = "Absolute"

        local validAccStart = self.stack[stackSize - 1] and self.stack[stackSize - 1]
        local validAccToken = self.stack[stackSize].type == "identifier" and self.stack[stackSize].value == "a"

        if validAccStart and validAccToken then
            mode = "Accumulator"
        elseif self.stack[stackSize] == token then
            mode = "Implied"
        elseif isBranchInstruction[instruction.value] then
            mode = "Relative"
        end
    end

    if mode == "Absolute" and self.token.type ~= "comma" then
        local register = string.upper( self:RegisterIndex() )

        mode = "Absolute," .. register
    elseif mode == "Indirect" then
        if self.token.type == "comma" then
            local register = self:RegisterIndex()

            if register == "y" then
                errorf( "Invalid index register: x expected, got y" )
            elseif register == "x" then
                mode = "X,Indirect"
            end
        elseif self.token.type == "rsqrbracket" then
            local register = self:RegisterIndex()

            if register == "x" then
                errorf( "Invalid index register: y expected, got x" )
            elseif register == "y" then
                mode = "Indirect,Y"
            end
        end
    end
end

function Parser:RegisterIndex()
    self:Eat( "comma" )
    local register = self:Eat( "identifier" )

    if register.value ~= "x" and register.value ~= "y" then
        -- TODO: Properly throw errors
        errorf( "Invalid register : %s at line %d, char %d", register.value, register.line, register.char )
    end

    return register.value
end

function Parser:Operand()
end

function Parser:Preprocessor()
    self:Eat( "hash" )
    local operation = self:Eat( "identifier" )

    self[operation.value]( self )

    self:Eat( "newline" )

    return operation.value
end

--------------------------------------------------
-- Preprocessor

function Parser:define()
    self:Eat( "identifier" )
end

function Parser:ifdef()
    while self.token.type ~= "eof" do
        if self.token.type == "hash" and self:Preprocessor() == "endif" then
            return
        end

        local token = self:Eat( self.token.type )
    end
end

function Parser:endif() end

--------------------------------------------------
-- Testing

include( "tests/parsing_test.lua" )
