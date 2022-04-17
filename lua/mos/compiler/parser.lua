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

    local program = {type = "Program", value = self:Statements( "Eof" ), line = 1, char = 1}
    self:Eat( "Eof" )

    return program
end

function Parser:Statements( condition )
    local statements = {}

    local shouldContinue = true
    local function exit()
        shouldContinue = false
    end

    while shouldContinue and self.token.type ~= "Eof" do
        local token = self.token
        local node

        if token.type == "Hash" then
            node = self:Preprocessor( exit )
        elseif token.type == "Dot" then
            node = self:Directive()
        elseif token.type == "Newline" then
            self:Eat( "Newline" )
        else
            node = self:Identifier()
        end

        table.insert( statements, node )
    end

    if shouldContinue and condition ~= self.token.type then
        errorf( "Expected %s got %s at line %d, char %d", condition, self.token.type, self.token.line, self.token.char )
    end

    return statements
end

function Parser:Identifier()
    local id = self:Eat( "Identifier" )

    if self.token.type == "Colon" then
        self:Label()

        return {type = "Label", value = id, line = id.line, char = id.char}
    end

    return self:Instruction( id )
end

function Parser:Label()
    self:Eat( "Colon" )
    self:Eat( "Newline" )
end

function Parser:Instruction( instruction )
    local name = instruction.value
    local adressingModes = Instructions.bytecodes[name]

    if not adressingModes then
        -- TODO: Properly throw errors
        errorf( "Invalid instruction name '%s' at line %d, char %d", name, instruction.line, instruction.char )
    end

    local operand = self:AddressingMode( instruction )
    self:Eat( "Newline" )

    local value = {instruction = instruction, operand = operand}
    return {type = "Instruction", value = value, line = instruction.line, char = instruction.char}
end

local adressingMode = {
    LSqrBracket = "Indirect",
    Hash = "Immediate",
    Newline = "Implied"
}

function Parser:AddressingMode( instruction )
    local token = self.token
    local mode = adressingMode[token.type] or "MaybeAbsolute"

    return self[mode]( self, instruction )
end

function Parser:Indirect()
    self:Eat( "LSqrBracket" )
    local operand = self:Operand()

    local mode = "Indirect"

    if self.token.type == "Comma" then
        local register = self:RegisterIndex()

        if register.value ~= "x" then
            errorf( "Invalid index register. 'x' expected, got 'y'" )
        end

        mode = "X,Indirect"
    end

    self:Eat( "RSqrBracket" )

    if self.token.type == "Comma" then
        local register = self:RegisterIndex()

        if register.value ~= "y" then
            errorf( "Invalid index register. 'y' expected, got 'x'" )
        end

        mode = "Indirect,Y"
    end

    return {type = "AdressingMode", value = operand, mode = mode, line = operand.line, char = operand.char}
end

function Parser:Immediate()
    self:Eat( "Hash" )
    local operand = self:Operand()

    return {type = "AdressingMode", value = operand, mode = "Immediate", line = operand.line, char = operand.char}
end

function Parser:Implied( instruction )
    --! Don't eat the newline. All instructions are expected to end with one and :Instruction() will take care of it

    return {type = "AdressingMode", mode = "Implied", line = instruction.line, char = instruction.char}
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
    if self.token.type == "Identifier" and self.token.value == "a" then
        return self:Accumulator()
    end

    local operand = self:Operand()
    if not operand then
        errorf( "Expected Operand got %s at line %d, char %d", self.token.type, self.token.line, self.token.char )
    end

    if isBranchInstruction[instruction.value] then
        return {type = "AdressingMode", value = operand, mode = "Relative", line = operand.line, char = operand.char}
    end

    if self.token.type == "Comma" then
        local register = string.upper( self:RegisterIndex().value )

        return {type = "AdressingMode", value = operand, mode = "Absolute," .. register, line = operand.line, char = operand.char}
    end

    return {type = "AdressingMode", value = operand, mode = "Absolute", line = operand.line, char = operand.char}
end

function Parser:Accumulator()
    local acc = self:Eat( "Identifier" )

    return {type = "AdressingMode", value = acc, mode = "Accumulator", line = acc.line, char = acc.char}
end

function Parser:RegisterIndex()
    self:Eat( "Comma" )
    local register = self:Eat( "Identifier" )

    if register.value ~= "x" and register.value ~= "y" then
        -- TODO: Properly throw errors
        errorf( "Invalid register '%s' at line %d, char %d", register.value, register.line, register.char )
    end

    return register
end

function Parser:Preprocessor( exit )
    self:Eat( "Hash" )
    local operation = self:Eat( "Identifier" )
    local name = string.upper( operation.value[1] ) .. string.sub( operation.value, 2 )

    local value = self[name]( self, exit )

    return {type = name, value = value, line = operation.line, char = operation.char}
end

--------------------------------------------------
-- Preprocessor

function Parser:Define()
    local operand = self:Operand()
    self:Eat( "Newline" )

    return operand
end

function Parser:Ifdef()
    local condition = self:Operand()
    self:Eat( "Newline" )

    return {condition = condition, statements = self:Statements( "#endif" )}
end

function Parser:Endif( exit )
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

    local operator = self:Eat( "Operator" )

    return {type = "Operation", value = {left = term, right = self:Term(), operator = operator}, line = term.line, char = term.char}
end

local validFactorOperation = {
    ["*"] = true,
    ["/"] = true
}

function Parser:Term()
    local factor = self:Factor()
    if not validFactorOperation[self.token.value] then return factor end

    local operator = self:Eat( "Operator" )

    return {type = "Operation", value = {left = factor, right = self:Factor(), operator = operator}, line = factor.line, char = factor.char}
end

local validFactor = {
    ["Identifier"] = true,
    ["Number"] = true,
    ["String"] = true
}

function Parser:Factor()
    if self.token.type == "LParen" then
        self:Eat( "LParen" )
        local expression = self:Expression()
        self:Eat( "RParen" )

        return expression
    end

    if not validFactor[self.token.type] then return end

    return self:Eat( self.token.type )
end

function Parser:Directive()
    self:Eat( "Dot" )
    local directive = self:Eat( "Identifier" )
    local argument = self:Arguments()

    return {type = "Directive", value = {directive = directive, argument = argument}, line = directive.line, char = directive.char}
end

function Parser:Arguments()
    local arg = self:Expression()
    if not arg then return end

    local args = {type = "Arguments", value = {arg}, line = arg.line, char = arg.char}

    while self.token.type == "Comma" do
        self:Eat( "Comma" )
        table.insert( args.value, self:Expression() )
    end
end
