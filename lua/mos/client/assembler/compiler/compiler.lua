Mos.Assembler.Compiler = Mos.Assembler.Compiler or {}
local Compiler = Mos.Assembler.Compiler

include( "mos/client/assembler/compiler/directives.lua" )

local Instructions = Mos.Assembler.Instructions

--------------------------------------------------
-- Compiler API

Compiler.__index = Compiler
setmetatable( Compiler, Mos.Assembler.NodeVisitor )

function Compiler.Create()
    local compiler = {}

    return setmetatable( compiler, Compiler )
end

function Compiler:compile()
    self.output = Mos.FileSystem.GetCompiledPath( self.assembly.main )

    Mos.FileSystem.Write( self.output, "" )
    self.file = Mos.FileSystem.Open( self.output, "wb" )

    self.file:Write( "GMOS6502" )
    self:startBlock()
    local sucess, msg = pcall( function() self:visit( self.assembly.ast ) end )
    if not sucess then
        ErrorNoHalt( msg )
    end

    self:endBlock()
    self.file:Close()
end

function Compiler:startBlock( address )
    self.block = self.file:Tell()
    self.file:WriteUShort( 0x0000 )
    self.file:WriteUShort( address )
end

function Compiler:endBlock()
    local pos = self.file:Tell()
    self.file:Seek( self.block )
    self.file:WriteUShort( pos - self.block - 4 )
    self.file:Seek( pos )
    self.block = nil
end

function Compiler:write( byte )
    self.file:WriteByte( byte )
end

--------------------------------------------------
-- Compiler visit methods

function Compiler:visitProgram( statements )
    for _, statement in ipairs( statements ) do
        self:visit( statement )
    end
end

function Compiler:visitLabel() end

function Compiler:visitInstruction( data )
    local mode = Instructions.modeLookup[data.operand.value.type]
    self:write( Instructions.bytecodes[data.instruction.value][mode] )

    self:visit( data.operand, data.address )
end

function Compiler:visitAdressingMode( mode, _, address )
    self:visit( mode, address )
end

--* Addressing modes

function Compiler:visitAccumulator() end
function Compiler:visitImplied() end

function Compiler:visitAbsolute( abs )
    local value = self:visit( abs )

    local hb = bit.rshift( bit.band( value, 0xff00 ), 8 )
    local lb = bit.band( value, 0xff )

    self:write( lb )
    self:write( hb )
end

Compiler.visitAbsoluteX = Compiler.visitAbsolute
Compiler.visitAbsoluteY = Compiler.visitAbsolute

function Compiler:visitImmediate( imm )
    self:write( self:visit( imm ) )
end

function Compiler:visitIndirect( ind )
    self:write( self:visit( ind ) )
end

function Compiler:visitXIndirect( xind )
    self:write( self:visit( xind ) )
end

function Compiler:visitIndirectY( indy )
    self:write( self:visit( indy ) )
end

function Compiler:visitRelative( rel, _, address )
    local value = self:visit( rel )
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

    self:write( offset )
end

--* Operations

function Compiler:visitOperation( data )
    local op = data.operator.value
    local left = self:visit( data.left )
    local right = self:visit( data.right )

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

function Compiler:visitNumber( num )
    return num
end

function Compiler:visitIdentifier( id )
    return self.preprocessor.labels[id] or self.preprocessor.definitions[id]
end

--* Preprocessor directives

function Compiler:visitDirective( data )
    if not self.directives[data.directive.value] then return end

    self.directives[data.directive.value]( self, data.arguments, data.value )
end
