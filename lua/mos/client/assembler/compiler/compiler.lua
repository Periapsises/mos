Mos.Assembler.Compiler = Mos.Assembler.Compiler or {}
local Compiler = Mos.Assembler.Compiler

include( "mos/client/assembler/compiler/directives.lua" )

Compiler.passes = {}

include( "mos/client/assembler/compiler/passes/first.lua" )
include( "mos/client/assembler/compiler/passes/second.lua" )

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

    local sucess, msg = pcall( function()
        local labels = self.passes[1].Perform( self.assembly.ast )
        self.passes[2].Perform( self.assembly.ast, labels, self )
    end )

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
