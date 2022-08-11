--[[
    @class Compiler
    @desc Takes care of performing necessary passes to compile the code into it's binary form
]]
Mos.Assembler.Compiler = Mos.Assembler.Compiler or {}
local Compiler = Mos.Assembler.Compiler

Compiler.passes = {}

include( "mos/client/assembler/compiler/passes/first.lua" )
include( "mos/client/assembler/compiler/passes/second.lua" )

--------------------------------------------------
-- Compiler API

Compiler.__index = Compiler
setmetatable( Compiler, Mos.Assembler.Ast )

--[[
    @name Compiler.Create()
    @desc Creates a new compiler object

    @return Compiler: The newly created object
]]
function Compiler.Create()
    local compiler = {}

    return setmetatable( compiler, Compiler )
end

--[[
    @name Compiler:compile()
    @desc Starts compilation from the assembly assigned to the compiler
]]
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

--[[
    @name Compiler:startBlock()
    @desc Starts a new address block
    @desc Used when the effective address of the code changes

    @param number address: The address of the block
]]
function Compiler:startBlock( address )
    self.block = self.file:Tell()
    self.file:WriteUShort( 0x0000 )
    self.file:WriteUShort( address )
end

--[[
    @name Compiler:endBlock()
    @desc Ends the current block and adds extra info like the block size in the header
]]
function Compiler:endBlock()
    local pos = self.file:Tell()
    self.file:Seek( self.block )
    self.file:WriteUShort( pos - self.block - 4 )
    self.file:Seek( pos )
    self.block = nil
end

--[[
    @name Compiler:write()
    @desc Writes a byte to the compiler output
    
    @param number byte: The byte to write
]]
function Compiler:write( byte )
    self.file:WriteByte( byte )
end
