Mos.Assembler.Parser = Mos.Assembler.Parser or {}
local Parser = Mos.Assembler.Parser

local Instructions = Mos.Assembler.Instructions

include( "mos/client/assembler/lexer.lua" )

local function errorf( str, ... )
    error( string.format( str, ... ), 3 )
end

--------------------------------------------------
-- Parser API

Parser.__index = Parser

function Parser.Create( code )
    local parser = {}
    parser.lexer = Mos.Assembler.Lexer.Create( code )

    return setmetatable( parser, Parser )
end

--------------------------------------------------
-- Parser metamethods

--[[
    @name Parser:eat( type )
    @desc Pops a token from the stream and returns it. Throws an error if the type isn't the one we expect

    @param string type - The type of token expected
]]
function Parser:eat( type )
    local token = self.token
    if token.type ~= type then
        -- TODO: Properly throw errors
        errorf( "Expected %s got %s at line %d, char %d", type, token.type, token.line, token.char )
    end

    self.token = self.lexer:getNextToken()

    return token
end

--------------------------------------------------
-- Parsing

function Parser:parse()
    --? Make sure there is a token we can read
    self.token = self.lexer:getNextToken()

    local program = {type = "Program", value = self:statements( "Eof" ), line = 1, char = 1}
    self:eat( "Eof" )

    return program
end

function Parser:statements( condition )
    local statements = {}

    local shouldContinue = true
    local function exit()
        shouldContinue = false
    end

    while shouldContinue and self.token.type ~= "Eof" do
        local token = self.token
        local node

        if token.type == "Hash" or token.type == "Dot" then
            node = self:directive( exit )
        elseif token.type == "Newline" then
            self:eat( "Newline" )
        else
            node = self:identifier()
        end

        table.insert( statements, node )
    end

    if shouldContinue and condition ~= self.token.type then
        errorf( "Expected %s got %s at line %d, char %d", condition, self.token.type, self.token.line, self.token.char )
    end

    return statements
end

function Parser:identifier()
    local id = self:eat( "Identifier" )

    if self.token.type == "Colon" then
        self:label()

        return {type = "Label", value = id, line = id.line, char = id.char}
    end

    return self:instruction( id )
end

function Parser:label()
    self:eat( "Colon" )
    self:eat( "Newline" )
end

function Parser:instruction( instruction )
    local name = instruction.value
    local adressingModes = Instructions.bytecodes[name]

    if not adressingModes then
        -- TODO: Properly throw errors
        errorf( "Invalid instruction name '%s' at line %d, char %d", name, instruction.line, instruction.char )
    end

    local operand = self:addressingMode( instruction )
    self:eat( "Newline" )

    local value = {instruction = instruction, operand = operand}
    return {type = "Instruction", value = value, line = instruction.line, char = instruction.char}
end

local adressingMode = {
    LSqrBracket = "Indirect",
    Hash = "Immediate",
    Newline = "Implied"
}

function Parser:addressingMode( instruction )
    local token = self.token
    local mode = adressingMode[token.type] or "MaybeAbsolute"
    local func = string.lower( mode[1] ) .. string.sub( mode, 2 )

    return self[func]( self, instruction )
end

function Parser:indirect()
    self:eat( "LSqrBracket" )
    local operand = self:operand()

    local mode = "Indirect"

    if self.token.type == "Comma" then
        local register = self:registerIndex()

        if register.value ~= "x" then
            errorf( "Invalid index register. 'x' expected, got 'y'" )
        end

        mode = "X,Indirect"
    end

    self:eat( "RSqrBracket" )

    if self.token.type == "Comma" then
        local register = self:registerIndex()

        if register.value ~= "y" then
            errorf( "Invalid index register. 'y' expected, got 'x'" )
        end

        mode = "Indirect,Y"
    end

    return {type = "AdressingMode", value = {type = mode, value = operand, line = operand.line, char = operand.char}, line = operand.line, char = operand.char}
end

function Parser:immediate()
    self:eat( "Hash" )
    local operand = self:operand()

    return {type = "AdressingMode", value = {type = "Immediate", value = operand, line = operand.line, char = operand.char}, line = operand.line, char = operand.char}
end

function Parser:implied( instruction )
    --! Don't eat the newline. All instructions are expected to end with one and :instruction() will take care of it

    return {type = "AdressingMode", value = {type = "Implied", value = nil, line = instruction.line, char = instruction.char}, line = instruction.line, char = instruction.char}
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

function Parser:maybeAbsolute( instruction )
    if self.token.type == "Identifier" and self.token.value == "a" then
        return self:accumulator()
    end

    local operand = self:operand()
    if not operand then
        errorf( "Expected Operand got %s at line %d, char %d", self.token.type, self.token.line, self.token.char )
    end

    if isBranchInstruction[instruction.value] then
        return {type = "AdressingMode", value = {type = "Relative", value = operand, line = operand.line, char = operand.char}, line = operand.line, char = operand.char}
    end

    if self.token.type == "Comma" then
        local register = string.upper( self:registerIndex().value )

        return {type = "AdressingMode", value = {type = "Absolute," .. register, value = operand, line = operand.line, char = operand.char}, line = operand.line, char = operand.char}
    end

    return {type = "AdressingMode", value = {type = "Absolute", value = operand, line = operand.line, char = operand.char}, line = operand.line, char = operand.char}
end

function Parser:accumulator()
    local acc = self:eat( "Identifier" )

    return {type = "AdressingMode", value = {type = "Accumulator", value = acc, line = acc.line, char = acc.char}, line = acc.line, char = acc.char}
end

function Parser:registerIndex()
    self:eat( "Comma" )
    local register = self:eat( "Identifier" )

    if register.value ~= "x" and register.value ~= "y" then
        -- TODO: Properly throw errors
        errorf( "Invalid register '%s' at line %d, char %d", register.value, register.line, register.char )
    end

    return register
end

function Parser:directive( exit )
    self:eat( self.token.type )

    local directive = self:eat( "Identifier" )
    local arguments = self:arguments()
    self:eat( "Newline" )

    local value

    if self[name] then
        value = self[name]( self, exit )
    end

    return {type = "Directive", value = {directive = directive, arguments = arguments, value = value}, line = directive.line, char = directive.char}
end

--------------------------------------------------
-- Operands

function Parser:operand()
    return self:expression()
end

local validTermOperation = {
    ["+"] = true,
    ["-"] = true,
}

function Parser:expression()
    local term = self:term()
    if not validTermOperation[self.token.value] then return term end

    local operator = self:eat( "Operator" )

    return {type = "Operation", value = {left = term, right = self:term(), operator = operator}, line = term.line, char = term.char}
end

local validFactorOperation = {
    ["*"] = true,
    ["/"] = true
}

function Parser:term()
    local factor = self:factor()
    if not validFactorOperation[self.token.value] then return factor end

    local operator = self:eat( "Operator" )

    return {type = "Operation", value = {left = factor, right = self:factor(), operator = operator}, line = factor.line, char = factor.char}
end

local validFactor = {
    ["Identifier"] = true,
    ["Number"] = true,
    ["String"] = true
}

function Parser:factor()
    if self.token.type == "LParen" then
        self:eat( "LParen" )
        local expression = self:expression()
        self:eat( "RParen" )

        return expression
    end

    if not validFactor[self.token.type] then return end

    return self:eat( self.token.type )
end

function Parser:arguments()
    local arg = self:expression()
    local args = {}

    if not arg then return args end
    table.insert( args, arg )

    while self.token.type == "Comma" or self.token.type ~= "Newline" do
        if self.token.type == "Comma" then self:eat( "Comma" ) end

        table.insert( args, self:expression() )
    end

    return args
end

--------------------------------------------------
-- Directives

function Parser:ifdef()
    return self:statements( "#endif" )
end

function Parser:endif( exit )
    exit()
end
