--[[
    @class Parser
    @desc Generates an AST from a stream of tokens
]]
Mos.Assembler.Parser = Mos.Assembler.Parser or {}
local Parser = Mos.Assembler.Parser

local instructions = Mos.Assembler.Instructions

include( "mos/client/assembler/lexer.lua" )

-- Formated error message, takes a string and extra arguments like string.format and generates an error from it.
local function errorf( str, ... )
    error( string.format( str, ... ), 3 )
end

--------------------------------------------------
-- Parser API

Parser.__index = Parser

--[[
    @name Parser.Create()
    @desc Creates a new parser object

    @param string code: The code to generate an AST for

    @return Parser: The newly created object
]]
function Parser.Create( code )
    local parser = {}
    parser.lexer = Mos.Assembler.Lexer.Create( code )
    parser.allowedDirectives = {
        ["define"] = true,
        ["ifdef"] = true,
        ["ifndef"] = true,
        ["org"] = true,
        ["db"] = true,
        ["dw"] = true
    }

    return setmetatable( parser, Parser )
end

--------------------------------------------------
-- Parser metamethods

--[[
    @name Parser:eat( type )
    @desc Pops a token from the stream and returns it. Throws an error if the type isn't the one we expect

    @param string type: The type of token expected
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

--[[
    @name Parser:parse()
    @desc Starts generating the AST

    @return AST: The generated AST
]]
function Parser:parse()
    self.token = self.lexer:getNextToken()

    local program = Tree.Create()
    self:program( program )
    self:eat( "Eof" )

    return program
end

function Parser:program( node )
    local statements = Tree.List( "Statements" )

    while self.token.type ~= "Eof" do
        statements:append( self:statement() )
    end

    node:attach( statements )
end

function Parser:statement()
    local type = self.token.type

    if type == "Newline" then
        self:eat( "Newline" )
        return
    elseif type == "Hash" or type == "Dot" then
        return self:directive()
    else
        return self:Identifier()
    end
end

function Parser:directive()
    local ref = self:eat( self.token.type )

    local name = self:eat( "Identifier" )
    local arguments = self:arguments()

    self:eat( "Newline" )

    if not self.allowedDirectives[name.value] then
        errorf( "Unexpected directive %s at line %d, char %d", name.value, name.line, name.char )
    end

    local directive = Tree.Table( "Directive", ref )
    directive.name = Tree.Leaf( name )
    directive.args = arguments
    directive.value = self[name.value] and self[name.value]( self )

    return directive
end

function Parser:identifier()
    local id = self:eat( "Identifier" )

    if self.token.type == "Colon" then
        self:eat( "Colon" )
        self:eat( "Newline" )

        local label = Tree.Node( "Label" )
        label:attach( Tree.Leaf( id ) )

        return label
    end

    local instruction = Tree.Table( "Instruction", id )
    instruction.name = Tree.Leaf( id )
    instruction.operand = self:instruction( id.value )

    return instruction
end

function Parser:instruction( name )
    local addressingModes = instructions.bytecodes[name]
    if not addressingModes then
        errorf( "Invalid instruction name '%s' at line %d, char %d", name, instruction.line, instruction.char )
    end

    local operand = self:addressingMode()
    self:eat( "Newline" )

    return operand
end

local addressingMode = {
    LSqrBracket = "indirect",
    Hash = "immediate",
    Newline = "implied"
}

function Parser:addressingMode()
    local mode = addressingMode[self.token.type] or "maybeAbsolute"

    return self[mode]( self )
end

function Parser:indirect()
    local ref = self:eat( "LSqrBracket" )

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
        if mode ~= "Indirect" then
            errorf( "Cannot index two registers at once" )
        end

        local register = self:registerIndex()

        if register.value ~= "y" then
            errorf( "Invalid index register. 'y' expected, got 'x'" )
        end

        mode = "Indirect,Y"
    end

    local addrMode = Tree.Table( "Operand", ref )
    addrMode.mode = Tree.Leaf( {type = "Mode", value = mode, line = ref.line, char = ref.char} )
    addrMode.value = operand

    return addrMode
end

--[[
function Parser:immediate()
    self:eat( "Hash" )
    local operand = self:operand()

    return {type = "AddressingMode", value = {type = "Immediate", value = operand, line = operand.line, char = operand.char}, line = operand.line, char = operand.char}
end

function Parser:implied( instruction )
    --! Don't eat the newline. All instructions are expected to end with one and :instruction() will take care of it

    return {type = "AddressingMode", value = {type = "Implied", value = nil, line = instruction.line, char = instruction.char}, line = instruction.line, char = instruction.char}
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
        return {type = "AddressingMode", value = {type = "Relative", value = operand, line = operand.line, char = operand.char}, line = operand.line, char = operand.char}
    end

    if self.token.type == "Comma" then
        local register = string.upper( self:registerIndex().value )

        return {type = "AddressingMode", value = {type = "Absolute," .. register, value = operand, line = operand.line, char = operand.char}, line = operand.line, char = operand.char}
    end

    return {type = "AddressingMode", value = {type = "Absolute", value = operand, line = operand.line, char = operand.char}, line = operand.line, char = operand.char}
end

function Parser:accumulator()
    local acc = self:eat( "Identifier" )

    return {type = "AddressingMode", value = {type = "Accumulator", value = acc, line = acc.line, char = acc.char}, line = acc.line, char = acc.char}
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
    local result = {default = {}, fallback = {}}
    local statements = result.default
    local accepts = {["else"] = true, ["endif"] = true}

    self.allowedDirectives["else"] = true
    self.allowedDirectives["endif"] = true

    while true do
        local statement = self:statement()
        if statement.type == "Directive" then
            local value = string.sub( statement.value.directive.value, 1 )

            if accepts[value] and value == "else" then
                statements = result.fallback
                accepts[value] = false
                statement = nil
            elseif accepts[value] then
                break
            end
        end

        if statement then table.insert( statements, statement ) end
    end

    self.allowedDirectives["else"] = false
    self.allowedDirectives["endif"] = false

    return result
end

Parser.ifndef = Parser.ifdef

function Parser:define() end
--]]
