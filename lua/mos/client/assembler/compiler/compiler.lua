Mos.Compiler = Mos.Compiler or {}
local Compiler = Mos.Compiler

include( "mos/client/compiler/instructions.lua" )
include( "mos/client/compiler/parser.lua" )
include( "mos/client/compiler/ast/node_visitor.lua" )
include( "mos/client/compiler/preprocessor.lua" )

include( "mos/client/compiler/directives/compiler.lua" )

local Instructions = Mos.Compiler.Instructions

--------------------------------------------------
-- Compiler API

Compiler.__index = Compiler
setmetatable( Compiler, Mos.Compiler.NodeVisitor )

function Compiler:Compile()
    local activeTab = Mos.Editor:GetActiveTab()
    if not activeTab or not activeTab.file then return end

    local code = Mos.FileSystem.Read( activeTab.file )
    local parser = self.Parser:Create( code )

    local ast = parser:Parse()

    local compiler = setmetatable( {}, self )
    compiler.preprocessor = self.Preprocessor:Process( ast )

    local fileName = Mos.FileSystem.GetCompiledPath( activeTab.file )
    Mos.FileSystem.Write( fileName, "" )
    compiler.file = Mos.FileSystem.Open( fileName, "wb" )

    compiler.file:Write( "GMOS6502" )
    compiler:StartBlock()
    local sucess, msg = pcall( function() compiler:Visit( ast ) end )
    if not sucess then
        ErrorNoHalt( msg )
    end

    compiler:EndBlock()
    compiler.file:Close()
end

function Compiler:StartBlock( address )
    self.block = self.file:Tell()
    self.file:WriteUShort( 0x0000 )
    self.file:WriteUShort( address )
end

function Compiler:EndBlock()
    local pos = self.file:Tell()
    self.file:Seek( self.block )
    self.file:WriteUShort( pos - self.block - 4 )
    self.file:Seek( pos )
    self.block = nil
end

function Compiler:Write( byte )
    self.file:WriteByte( byte )
end

--------------------------------------------------
-- Compiler visit methods

function Compiler:VisitProgram( statements )
    for _, statement in ipairs( statements ) do
        self:Visit( statement )
    end
end

function Compiler:VisitLabel() end

function Compiler:VisitInstruction( data )
    local mode = Instructions.modeLookup[data.operand.value.type]
    self:Write( Instructions.bytecodes[data.instruction.value][mode] )

    self:Visit( data.operand, data.address )
end

function Compiler:VisitAdressingMode( mode, _, address )
    self:Visit( mode, address )
end

--* Adressing modes

function Compiler:VisitAccumulator() end
function Compiler:VisitImplied() end

function Compiler:VisitAbsolute( abs )
    local value = self:Visit( abs )

    local hb = bit.rshift( bit.band( value, 0xff00 ), 8 )
    local lb = bit.band( value, 0xff )

    self:Write( lb )
    self:Write( hb )
end

Compiler.VisitAbsoluteX = Compiler.VisitAbsolute
Compiler.VisitAbsoluteY = Compiler.VisitAbsolute

function Compiler:VisitImmediate( imm )
    self:Write( self:Visit( imm ) )
end

function Compiler:VisitIndirect( ind )
    self:Write( self:Visit( ind ) )
end

function Compiler:VisitXIndirect( xind )
    self:Write( self:Visit( xind ) )
end

function Compiler:VisitIndirectY( indy )
    self:Write( self:Visit( indy ) )
end

function Compiler:VisitRelative( rel, _, address )
    local value = self:Visit( rel )
    print( address, value )
    local offset = value - ( address + 2 )

    if offset < -128 or offset > 127 then
        -- TODO: Properly throw errors
        error( "Unreachable address" )
    end

    --? Converts the offset into a signed 8 bit number
    if offset < 0 then
        offset = bit.bxor( 0xff, bit.bnot( offset ) )
    end

    self:Write( offset )
end

--* Operations

function Compiler:VisitOperation( data )
    local op = data.operator.value
    local left = self:Visit( data.left )
    local right = self:Visit( data.right )

    if op == "+" then
        return left + right
    elseif op == "-" then
        return left - right
    elseif op == "*" then
        return left * right
    elseif op == "/" then
        return left / right
    end
end

--* Literals

function Compiler:VisitNumber( num )
    return num
end

function Compiler:VisitIdentifier( id )
    return self.preprocessor.labels[id] or self.preprocessor.definitions[id]
end

--* Preprocessor directives

function Compiler:VisitDirective( data )
    if not self.Directives[data.directive.value] then return end

    self.Directives[data.directive.value]( self, data.arguments, data.value )
end
