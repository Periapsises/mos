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
    --? Make sure there is a token we can read
    self.token = self.lexer:GetNextToken()

    local program = {type = "program", value = self:Statements( "eof" ), line = 1, char = 1}
    self:Eat( "eof" )

    return program
end

function Parser:Statements( condition )
    local program = {type = "program", value = {}, line = 1, char = 1}

    local shouldContinue = true
    local function exit()
        shouldContinue = false
    end

    while shouldContinue and self.token.type ~= "eof" do
        local token = self.token
        local node

        if token.type == "hash" then
            node = self:Preprocessor( exit )
        elseif token.type == "dot" then
            node = self:Directive()
        elseif token.type == "newline" then
            self:Eat( "newline" )
        else
            node = self:Identifier()
        end

        table.insert( program.value, node )
    end

    if shouldContinue and condition ~= self.token.type then
        errorf( "Expected %s got %s at line %d, char %d", condition, self.token.type, self.token.line, self.token.char )
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

    local operand = self:AddressingMode( instruction )
    self:Eat( "newline" )

    local value = {instruction = instruction, operand = operand}
    return {type = "instruction", value = value, line = instruction.line, char = instruction.char}
end

local adressingMode = {
    lsqrbracket = "Indirect",
    hash = "Immediate",
    newline = "Implied"
}

function Parser:AddressingMode( instruction )
    local token = self.token
    local mode = adressingMode[token.type] or "MaybeAbsolute"

    return self[mode]( self, instruction )
end

function Parser:Indirect()
    self:Eat( "lsqrbracket" )
    local operand = self:Operand()

    local mode = "Indirect"

    if self.token.type == "comma" then
        local register = self:RegisterIndex()

        if register.value ~= "x" then
            errorf( "Invalid index register. 'x' expected, got 'y'" )
        end

        mode = "X,Indirect"
    end

    self:Eat( "rsqrbracket" )

    if self.token.type == "comma" then
        local register = self:RegisterIndex()

        if register.value ~= "y" then
            errorf( "Invalid index register. 'y' expected, got 'x'" )
        end

        mode = "Indirect,Y"
    end

    return {type = "adressing_mode", value = operand, mode = mode, line = operand.line, char = operand.char}
end

function Parser:Immediate()
    self:Eat( "hash" )
    local operand = self:Operand()

    return {type = "adressing_mode", value = operand, mode = "Immediate", line = operand.line, char = operand.char}
end

function Parser:Implied( instruction )
    --! Don't eat the newline. All instructions are expected to end with one and :Instruction() will take care of it

    return {type = "adressing_mode", mode = "Implied", line = instruction.line, char = instruction.char}
end

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

function Parser:MaybeAbsolute( instruction )
    if self.token.type == "identifier" and self.token.value == "a" then
        return self:Accumulator()
    end

    local operand = self:Operand()

    if isBranchInstruction[instruction.value] then
        return {type = "adressing_mode", value = operand, mode = "Relative", line = operand.line, char = operand.char}
    end

    if self.token.type == "comma" then
        local register = string.upper( self:RegisterIndex().value )

        return {type = "adressing_mode", value = operand, mode = "Absolute," .. register, line = operand.line, char = operand.char}
    end

    return {type = "adressing_mode", value = operand, mode = "Absolute", line = operand.line, char = operand.char}
end

function Parser:Accumulator()
    local acc = self:Eat( "identifier" )

    return {type = "adressing_mode", value = acc, mode = "Accumulator", line = acc.line, char = acc.char}
end

function Parser:RegisterIndex()
    self:Eat( "comma" )
    local register = self:Eat( "identifier" )

    if register.value ~= "x" and register.value ~= "y" then
        -- TODO: Properly throw errors
        errorf( "Invalid register '%s' at line %d, char %d", register.value, register.line, register.char )
    end

    return register
end

function Parser:Preprocessor( exit )
    self:Eat( "hash" )
    local operation = self:Eat( "identifier" )

    local value = self[operation.value]( self, exit )

    return {type = operation.value, value = value, line = operation.line, char = operation.char}
end

--------------------------------------------------
-- Preprocessor

function Parser:define()
    local operand = self:Operand()
    self:Eat( "newline" )

    return operand
end

function Parser:ifdef()
    local condition = self:Operand()
    self:Eat( "newline" )

    return {condition = condition, statements = self:Statements( "#endif" )}
end

function Parser:endif( exit )
    exit()
end

--------------------------------------------------
-- Operands

function Parser:Operand()
    return self:Expression()
end

local validTermOperation = {
    ["+"] = true,
    ["-"] = true,
}

function Parser:Expression()
    local term = self:Term()
    if not validTermOperation[self.token.value] then return term end

    local operator = self:Eat( "operator" )

    return {type = "operation", value = {left = term, right = self:Term(), operator = operator}, line = term.line, char = term.char}
end

local validFactorOperation = {
    ["*"] = true,
    ["/"] = true
}

function Parser:Term()
    local factor = self:Factor()
    if not validFactorOperation[self.token.value] then return factor end

    local operator = self:Eat( "operator" )

    return {type = "operation", value = {left = factor, right = self:Factor(), operator = operator}, line = factor.line, char = factor.char}
end

local validFactor = {
    identifier = true,
    number = true
}

function Parser:Factor()
    if self.token.type == "lparen" then
        self:Eat( "lparen" )
        local expression = self:Expression()
        self:Eat( "rparen" )

        return expression
    end

    if not validFactor[self.token.type] then return end

    return self:Eat( self.token.type )
end

--------------------------------------------------
-- Testing

include( "tests/parsing_test.lua" )
