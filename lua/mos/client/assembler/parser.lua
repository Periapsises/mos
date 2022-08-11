--[[
    @class Parser
    @desc Generates an AST from a stream of tokens
]]
Mos.Assembler.Parser = Mos.Assembler.Parser or {}
local Parser = Mos.Assembler.Parser

include( "mos/client/assembler/lexer.lua" )
include( "mos/client/assembler/ast/visitor.lua" )

local Ast = Mos.Assembler.Ast
local instructions = Mos.Assembler.Instructions

-- Formated error message, takes a string and extra arguments like string.format and generates an error from it.
local function errorf( str, ... )
    error( string.format( str, ... ), 2 )
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
        error( string.format( "Expected %s got %s at line %d, char %d", type, token.type, token.line, token.char ), 2 )
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

    local program = Ast.Node( "Program" )
    self:program( program )
    self:eat( "Eof" )

    return program
end

function Parser:program( node )
    node.statements = Ast.Node( "Statements" )

    while self.token.type ~= "Eof" do
        local statement = self:statement( node.statements )
        node.statements:insert( statement )
    end
end

function Parser:statement( node )
    local type = self.token.type

    if type == "Newline" then
        self:eat( "Newline" )
    else
        return self:identifier( node )
    end
end

function Parser:identifier( node )
    local id = self:eat( "Identifier" )
    local statement = Ast.Node( "Statement" )

    if self.token.type == "Colon" then
        self:eat( "Colon" )
        self:eat( "Newline" )

        statement.LABEL = Ast.Token( id )
        return statement
    end

    statement.instruction = Ast.Node( "Instruction" )
    statement.instruction.NAME = Ast.Token( id )

    self:instruction( statement.instruction, string.lower( id.value ) )
    return statement
end

function Parser:instruction( node, name )
    local addressingModes = instructions.bytecodes[name]
    if not addressingModes then
        errorf( "Invalid instruction name '%s' at line %d, char %d", name, node._line, node._char )
    end

    self:operand( node, name )
    self:eat( "Newline" )
end

local addressingMode = {
    LSqrBracket = "indirect",
    Hash = "immediate",
    Newline = "implied"
}

function Parser:operand( node, name )
    node.operand = Ast.Node( "Operand" )

    local mode = addressingMode[self.token.type] or "maybeAbsolute"
    self[mode]( self, node.operand, name )
end

function Parser:indirect( node )
    local mode = self:eat( "LSqrBracket" )
    mode.value = "Indirect"

    node.value = self:expression( node )

    if self.token.type == "Comma" then
        local register = self:registerIndex()

        if register == "y" then
            errorf( "Invalid index register. 'x' expected, got 'y'" )
        end

        mode.value = "Indirect,X"
    end

    self:eat( "RSqrBracket" )

    if self.token.type == "Comma" then
        if mode.value ~= "Indirect" then
            errorf( "Cannot index two registers at once" )
        end

        local register = self:registerIndex()

        if register == "x" then
            errorf( "Invalid index register. 'y' expected, got 'x'" )
        end

        mode.value = "Indirect,Y"
    end

    node.MODE = Ast.Token( mode )
end

function Parser:immediate( node )
    local mode = self:eat( "Hash" )
    mode.value = "Immediate"
    node.MODE = Ast.Token( mode )

    node.value = self:expression( node )
end

function Parser:implied( node )
    --! Don't eat the newline. All instructions are expected to end with one and :instruction() will take care of it
    local mode = self.token
    mode.Value = "Implied"
    node.MODE = Ast.Token( mode )
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

function Parser:maybeAbsolute( node, name )
    if self.token.type == "Identifier" and self.token.value == "a" then
        return self:accumulator( node )
    end

    local mode = self.token

    node.value = self:expression( node )

    if isBranchInstruction[name] then
        mode.value = "Relative"
        node.MODE = Ast.Token( mode )
        return
    end

    mode.value = "Absolute"

    if self.token.type == "Comma" then
        local register = string.upper( self:registerIndex() )
        mode.value = "Absolute," .. register
    end

    node.MODE = Ast.Token( mode )
end

function Parser:accumulator( node )
    local mode = self:eat( "Identifier" )
    mode.value = "Accumulator"
    node.MODE = Ast.Token( mode )
end

function Parser:registerIndex()
    self:eat( "Comma" )
    local register = self:eat( "Identifier" )
    local name = string.lower( register.value )

    if name ~= "x" and name ~= "y" then
        errorf( "Invalid register '%s' at line %d, char %d", register.value, register.line, register.char )
    end

    return register.value
end

local validTermOperation = {
    ["+"] = true,
    ["-"] = true,
}

function Parser:expression( node )
    local left = self:term( node )
    if not validTermOperation[self.token.value] then
        return left
    end

    local operator = self:eat( "Operator" )

    local operation = Ast.Node( "Operation" )
    operation.Left = left
    operation.OPERATOR = operation:token( operator )
    operation.Right = self:term( node )
end

local validFactorOperation = {
    ["*"] = true,
    ["/"] = true
}

function Parser:term( node )
    local left = self:factor( node )
    if not validFactorOperation[self.token.value] then
        return left
    end

    local operator = self:eat( "Operator" )

    local operation = Ast.Node( "Operation" )
    operation.Left = left
    operation.OPERATOR = operation:token( operator )
    operation.Right = self:factor( node )
end

local validFactor = {
    ["Identifier"] = true,
    ["Number"] = true,
    ["String"] = true
}

function Parser:factor( node )
    if self.token.type == "LParen" then
        self:eat( "LParen" )
        local expr = self:expression( node )
        self:eat( "RParen" )

        return expr
    end

    if not validFactor[self.token.type] then return end

    local factor = self:eat( self.token.type )
    return Node.Token( factor )
end

function Parser:arguments( node )
    local arguments = node:list()
    node.Arguments = arguments

    self:argument( arguments )

    while self.token.type == "Comma" or self.token.type ~= "Newline" do
        self:eat( "Comma" )
        self:argument( arguments )
    end
end

function Parser:argument( node )
    local arg = Ast.Node( "Argument" )
    self:expression( arg )
end
