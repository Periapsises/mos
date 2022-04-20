Mos.Processor = Mos.Processor or {}
local Processor = Mos.Processor

local band, bor, lshift, rshift, bxor, bnot = bit.band, bit.bor, bit.lshift, bit.rshift, bit.bxor, bit.bnot

local lookup

local addressingModes = {}
local instructions = {}

local resetVector = 0xfffc
local irqVector = 0xfffe
local nmiVector = 0xfffa

local c, z, i, d, b, u, v, n = 1, 2, 4, 8, 16, 32, 64, 128

--------------------------------------------------
-- Memory read and write

local function read( cpu, addr )
    return cpu.memory[addr] or 0
end

local function write( cpu, addr, value )
    cpu.memory[band(addr, 0xffff)] = band( value, 0xff )
end

--------------------------------------------------
-- Execution

Processor.__index = Processor

function Processor:Clock()
    self:SetFlag( u, 1 )

    local opcode = read( self, self.pc )
    self.pc = band( self.pc + 1, 0xffff )

    local instruction = lookup[opcode]

    local value = addressingModes[instruction[3]]( self )
    instructions[instruction[2]]( self, value )

    self:SetFlag( u, 1 )
end

--------------------------------------------------
-- Flags

function Processor:SetFlag( flag, value )
    if value ~= 0 or value == true then
        self.flags = bor( self.flags, flag )
    end

    self.flags = band( self.flags, bnot( flag ) )
end

function Processor:GetFlag( flag )
    local result = band( self.flags, flag )

    return result == 0 and 0 or 1
end

--------------------------------------------------
-- External inputs

function Processor:Reset()
    self.addrAbs = resetVector

    local lo = read( self, resetVector )
    local hi = read( self, resetVector + 1 )

    self.pc = bor( lshift( hi, 8 ), lo )

    self.a, self.x, self.y = 0, 0, 0
    self.stkp = 0xfd
    self.flags = u
end

function Processor:Irq()
    if self:GetFlag( i ) ~= 0 then return end

    write( self, 0x0100 + self.stkp, rshift( self.pc, 8 ) )
    self.stkp = band( self.stkp - 1, 0xff )

    write( self, 0x0100 + self.stkp, self.pc )
    self.stkp = band( self.stkp - 1, 0xff )

    self:SetFlag( b, 0 )
    self:SetFlag( u, 1 )
    self:SetFlag( i, 1 )

    write( self, 0x0100 + self.stkp, self.flags )
    self.stkp = band( self.stkp - 1, 0xff )

    self.addrAbs = irqVector

    local lo = read( self, irqVector )
    local hi = read( self, irqVector + 1 )

    self.pc = bor( lshift( hi, 8 ), lo )
end

function Processor:Nmi()
    write( self, 0x0100 + self.stkp, rshift( self.pc, 8 ) )
    self.stkp = band( self.stkp - 1, 0xff )

    write( self, 0x0100 + self.stkp, self.pc )
    self.stkp = band( self.stkp - 1, 0xff )

    self:SetFlag( b, 0 )
    self:SetFlag( u, 1 )
    self:SetFlag( i, 1 )

    write( self, 0x0100 + self.stkp, self.flags )
    self.stkp = band( self.stkp - 1, 0xff )

    self.addrAbs = nmiVector

    local lo = read( self, nmiVector )
    local hi = read( self, nmiVector + 1 )

    self.pc = bor( lshift( hi, 8 ), lo )
end

--------------------------------------------------
-- Addressing modes

function addressingModes.acc( cpu )
    return cpu.a
end

function addressingModes.abs( cpu )
    local lo = read( cpu, cpu.pc )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    local hi = read( cpu, cpu.pc )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    cpu.addrAbs = bor( lshift( hi, 8 ), lo )
    return read( cpu, cpu.addrAbs )
end

function addressingModes.abx( cpu )
    local lo = read( cpu, cpu.pc )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    local hi = read( cpu, cpu.pc )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    cpu.addrAbs = bor( lshift( hi, 8 ), lo ) + cpu.x
    return read( cpu, cpu.addrAbs )
end

function addressingModes.aby( cpu )
    local lo = read( cpu, cpu.pc )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    local hi = read( cpu, cpu.pc )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    cpu.addrAbs = bor( lshift( hi, 8 ), lo ) + cpu.y
    return read( cpu, cpu.addrAbs )
end

function addressingModes.imm( cpu )
    cpu.addrAbs = cpu.pc

    local value = read( cpu, cpu.pc )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    return value
end

function addressingModes.imp( cpu )
    return
end

function addressingModes.ind( cpu )
    local ptrLo = read( cpu, cpu.pc )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    local ptrHi = read( cpu, cpu.pc )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    local ptr = bor( lshift( ptrHi, 8 ), ptrLo )

    --? Simulation of the page boundary hardware bug
    if ptr_lo == 0xff then
        local addr = bor( lshift( read( cpu, band( ptr, 0xff ) ), 8 ), read( cpu, ptr ) )
        return read( cpu, addr )
    end

    cpu.addrAbs = bor( lshift( read( cpu, ptr + 1 ), 8 ), read( cpu, ptr ) )
    return read( cpu, cpu.addrAbs )
end

function addressingModes.inx( cpu )
    local ptr = read( cpu, cpu.pc ) + cpu.x
    cpu.pc = band( cpu.pc + 1, 0xffff )

    local lo = read( cpu, ptr )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    local hi = read( cpu, ptr + 1 )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    cpu.addrAbs = bor( lshift( hi, 8 ), lo )
    return read( cpu, cpu.addrAbs )
end

function addressingModes.iny( cpu )
    local ptr = read( cpu, cpu.pc )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    local lo = read( cpu, ptr )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    local hi = read( cpu, ptr + 1 )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    cpu.addrAbs = bor( lshift( hi, 8 ), lo ) + cpu.y
    return read( cpu, cpu.addrAbs )
end

function addressingModes.rel( cpu )
    local addr = read( cpu, cpu.pc )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    if band( addr, 0x80 ) ~= 0 then
        addr = bor( addr, 0xff00 )
    end

    return addr
end

--------------------------------------------------
-- Instructions

function instructions.adc( cpu, value )
    local result = cpu.a + value + cpu:GetFlag( c )

    cpu:SetFlag( c, band( result, 0xff00 ) )
    cpu:SetFlag( z, band( result, 0x00ff ) == 0 )
    cpu:SetFlag( v, band( band( bnot( bxor( cpu.a, value ) ), bxor( cpu.a, result ) ), 0x80 ) )
    cpu:SetFlag( n, band( result, 0x80 ) )

    cpu.a = band( result, 0xff )
end

function instructions.sbc( cpu, value )
    local result = cpu.a + bxor( value, 0xff ) + cpu:GetFlag( c )

    cpu:SetFlag( c, band( result, 0xff00 ) )
    cpu:SetFlag( z, band( result, 0x00ff ) == 0 )
    cpu:SetFlag( v, band( band( bxor( result, cpu.a ), bxor( result, value ) ), 0x80 ) )
    cpu:SetFlag( n, band( result, 0x80 ) )

    cpu.a = band( result, 0xff )
end

instructions["and"] = function( cpu, value )
    cpu.a = band( cpu.a, value )

    cpu:SetFlag( z, cpu.a == 0 )
    cpu:SetFlag( n, band( a, 0x80 ) )
end

function instructions.asl( cpu, value )
    local result = lshift( value, 1 )

    cpu:SetFlag( c, band( result, 0xff00 ) )
    cpu:SetFlag( z, band( result, 0x00ff ) == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )

    if cpu.mode == "imp" or cpu.mode == "acc" then
        cpu.a = band( result, 0xff )
        return
    end

    write( cpu, cpu.addrAbs, result )
end

-- Branching instructions

function instructions.bcc( cpu, value )
    if cpu:GetFlag( c ) ~= 0 then return end

    cpu.pc = band( cpu.pc + value, 0xffff )
end

function instructions.bcs( cpu, value )
    if cpu:GetFlag( c ) == 0 then return end

    cpu.pc = band( cpu.pc + value, 0xffff )
end

function instructions.beq( cpu, value )
    if cpu:GetFlag( z ) ~= 0 then return end

    cpu.pc = band( cpu.pc + value, 0xffff )
end

function instructions.bne( cpu, value )
    if cpu:GetFlag( z ) == 0 then return end

    cpu.pc = band( cpu.pc + value, 0xffff )
end

function instructions.bpl( cpu, value )
    if cpu:GetFlag( n ) ~= 0 then return end

    cpu.pc = band( cpu.pc + value, 0xffff )
end

function instructions.bmi( cpu, value )
    if cpu:GetFlag( n ) == 0 then return end

    cpu.pc = band( cpu.pc + value, 0xffff )
end

function instructions.bvc( cpu, value )
    if cpu:GetFlag( v ) ~= 0 then return end

    cpu.pc = band( cpu.pc + value, 0xffff )
end

function instructions.bvs( cpu, value )
    if cpu:GetFlag( v ) == 0 then return end

    cpu.pc = band( cpu.pc + value, 0xffff )
end

function instructions.bit( cpu, value )
    local result = band( cpu.a, value )

    cpu:SetFlag( z, band( result, 0xff ) == 0 )
    cpu:SetFlag( n, band( value, 0x80 ) )
    cpu:SetFlag( v, band( value, 0x40 ) )
end

function instructions.brk( cpu )
    cpu.pc = band( cpu.pc + 1, 0xffff )

    write( cpu, 0x0100 + cpu.stkp, rshift( cpu.pc, 8 ) )
    cpu.stkp = band( cpu.stkp - 1, 0xff )

    write( cpu, 0x0100 + cpu.stkp, cpu.pc )
    cpu.stkp = band( cpu.stkp - 1, 0xff )

    cpu:SetFlag( i, 1 )
    cpu:SetFlag( b, 1 )

    write( cpu, 0x0100 + cpu.stkp, cpu.flags )
    cpu.stkp = band( cpu.stkp - 1, 0xff )

    cpu:SetFlag( b, 0 )

    cpu.pc = bor( read( cpu, irqVector ), lshift( read( cpu, irqVector + 1 ), 8 ) )
end

function instructions.clc( cpu )
    cpu:SetFlag( c, 0 )
end

function instructions.cld( cpu )
    cpu:SetFlag( d, 0 )
end

function instructions.cli( cpu )
    cpu:SetFlag( i, 0 )
end

function instructions.clv( cpu )
    cpu:SetFlag( v, 0 )
end

function instructions.clc( cpu )
    cpu:SetFlag( c, 0 )
end

function instructions.cmp( cpu, value )
    local result = cpu.a - value

    cpu:SetFlag( c, cpu.a >= value )
    cpu:SetFlag( z, band( result, 0xff ) == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )
end

function instructions.cpx( cpu, value )
    local result = cpu.x - value

    cpu:SetFlag( c, cpu.x >= value )
    cpu:SetFlag( z, band( result, 0xff ) == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )
end

function instructions.cpy( cpu, value )
    local result = cpu.y - value

    cpu:SetFlag( c, cpu.y >= value )
    cpu:SetFlag( z, band( result, 0xff ) == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )
end

function instructions.dec( cpu, value )
    local result = value - 1

    write( cpu, cpu.addrAbs, result )

    cpu:SetFlag( z, band( result, 0xff ) == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )
end

function instructions.dex( cpu, value )
    local result = cpu.x - 1
    cpu.x = band( result, 0xff )

    cpu:SetFlag( z, band( result, 0xff ) == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )
end

function instructions.dey( cpu, value )
    local result = cpu.y - 1
    cpu.y = band( result, 0xff )

    cpu:SetFlag( z, band( result, 0xff ) == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )
end

function instructions.eor( cpu, value )
    local result = bxor( cpu.a, value )

    cpu:SetFlag( z, result == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )

    cpu.a = result
end

function instructions.inc( cpu, value )
    local result = value + 1

    write( cpu, cpu.addrAbs, result )

    cpu:SetFlag( z, band( result, 0xff ) == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )
end

function instructions.inx( cpu, value )
    local result = cpu.x + 1
    cpu.x = band( result, 0xff )

    cpu:SetFlag( z, band( result, 0xff ) == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )
end

function instructions.iny( cpu, value )
    local result = cpu.y + 1
    cpu.y = band( result, 0xff )

    cpu:SetFlag( z, band( result, 0xff ) == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )
end

function instructions.jmp( cpu, value )
    cpu.pc = value
end

function instructions.jsr( cpu, value )
    cpu.pc = band( cpu.pc - 1, 0xffff )

    write( cpu, 0x0100 + cpu.stkp, rshift( cpu.pc, 8 ) )
    cpu.stkp = band( cpu.stkp - 1, 0xff )

    write( cpu, 0x0100 + cpu.stkp, cpu.pc )
    cpu.stkp = band( cpu.stkp - 1, 0xff )

    cpu.pc = value
end

function instructions.lda( cpu, value )
    cpu.a = value

    cpu:SetFlag( z, value == 0 )
    cpu:SetFlag( n, band( value, 0x80 ) )
end

function instructions.ldx( cpu, value )
    cpu.x = value

    cpu:SetFlag( z, value == 0 )
    cpu:SetFlag( n, band( value, 0x80 ) )
end

function instructions.ldy( cpu, value )
    cpu.y = value

    cpu:SetFlag( z, value == 0 )
    cpu:SetFlag( n, band( value, 0x80 ) )
end

function instructions.lsr( cpu, value )
    local result = rshift( value, 1 )

    cpu:SetFlag( c, band( value, 1 ) )
    cpu:SetFlag( z, band( result, 0xff ) == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )

    if cpu.mode == "imp" or cpu.mode == "acc" then
        cpu.a = band( result, 0xff )
        return
    end

    write( cpu, cpu.addrAbs, result )
end

function instructions.nop()
end

function instructions.ora( cpu, value )
    local result = bor( cpu.a, value )

    cpu:SetFlag( z, result == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )

    cpu.a = result
end

function instructions.pha( cpu )
    write( cpu, 0x0100 + cpu.stkp, cpu.a )
    cpu.stkp = band( cpu.stkp - 1, 0xff )
end

function instructions.php( cpu )
    write( cpu, 0x0100 + cpu.stkp, bor( cpu.flags, b + u ) )
    cpu.stkp = band( cpu.stkp - 1, 0xff )

    cpu:SetFlag( b, 0 )
    cpu:SetFlag( u, 0 )
end

function instructions.pla( cpu )
    cpu.stkp = band( cpu.stkp + 1, 0xff )
    local result = read( cpu, 0x0100 + cpu.stkp )

    cpu:SetFlag( z, result == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )

    cpu.a = result
end

function instructions.plp( cpu )
    cpu.stkp = band( cpu.stkp + 1, 0xff )
    cpu.flags = read( cpu, 0x0100 + cpu.stkp )

    cpu:SetFlag( u, 1 )
end

function instructions.rol( cpu, value )
    local result = bor( lshift( value, 1 ), cpu:GetFlag( c ) )

    cpu:SetFlag( c, band( result, 0xff00 ) )
    cpu:SetFlag( z, band( result, 0xff ) == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )

    if cpu.mode == "imp" or cpu.mode == "acc" then
        cpu.a = band( result, 0xff )
        return
    end

    write( cpu, cpu.addrAbs, result )
end

function instructions.ror( cpu, value )
    local result = bor( rshift( value, 1 ), lshift( cpu:GetFlag( c ), 7 ) )

    cpu:SetFlag( c, band( value, 1 ) )
    cpu:SetFlag( z, band( result, 0xff ) == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )

    if cpu.mode == "imp" or cpu.mode == "acc" then
        cpu.a = band( result, 0xff )
        return
    end

    write( cpu, cpu.addrAbs, result )
end

function instructions.rti( cpu )
    cpu.stkp = band( cpu.stkp + 1, 0xff )
    cpu.flags = read( cpu, 0x0100 + cpu.stkp )
    cpu.flags = band( cpu.flags, bnot( b + u ) )

    cpu.stkp = band( cpu.stkp + 1, 0xff )
    local lo = read( cpu, 0x0100 + cpu.stkp )

    cpu.stkp = band( cpu.stkp + 1, 0xff )
    local hi = read( cpu, 0x0100 + cpu.stkp )

    cpu.pc = bor( lshift( hi, 8 ), lo )
end

function instructions.rts( cpu )
    cpu.stkp = band( cpu.stkp + 1, 0xff )
    local lo = read( cpu, 0x0100 + cpu.stkp )

    cpu.stkp = band( cpu.stkp + 1, 0xff )
    local hi = read( cpu, 0x0100 + cpu.stkp )

    cpu.pc = bor( lshift( hi, 8 ), lo )
end

function instructions.sec( cpu )
    cpu:SetFlag( c, 1 )
end

function instructions.sed( cpu )
    cpu:SetFlag( d, 1 )
end

function instructions.sei( cpu )
    cpu:SetFlag( i, 1 )
end

function instructions.sta( cpu )
    write( cpu.addrAbs, cpu.a )
end

function instructions.stx( cpu )
    write( cpu.addrAbs, cpu.x )
end

function instructions.sty( cpu )
    write( cpu.addrAbs, cpu.y )
end

function instructions.tax( cpu )
    local result = cpu.a

    cpu:SetFlag( z, result == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )

    cpu.x = result
end

function instructions.tay( cpu )
    local result = cpu.a

    cpu:SetFlag( z, result == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )

    cpu.y = result
end

function instructions.tsx( cpu )
    local result = cpu.stkp

    cpu:SetFlag( z, result == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )

    cpu.x = result
end

function instructions.txa( cpu )
    local result = cpu.x

    cpu:SetFlag( z, result == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )

    cpu.a = result
end

function instructions.txs( cpu )
    cpu.stkp = cpu.x
end

function instructions.tya( cpu )
    local result = cpu.y

    cpu:SetFlag( z, result == 0 )
    cpu:SetFlag( n, band( result, 0x80 ) )

    cpu.a = result
end

function instructions.xxx()
end

lookup = {
    { "ora", "ora", "izx" },{ "???", "xxx", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "ora", "ora", "zp0" },{ "asl", "asl", "zp0" },{ "???", "xxx", "imp" },{ "php", "php", "imp" },{ "ora", "ora", "imm" },{ "asl", "asl", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "ora", "ora", "abs" },{ "asl", "asl", "abs" },{ "???", "xxx", "imp" },
    { "bpl", "bpl", "rel" },{ "ora", "ora", "izy" },{ "???", "xxx", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "ora", "ora", "zpx" },{ "asl", "asl", "zpx" },{ "???", "xxx", "imp" },{ "clc", "clc", "imp" },{ "ora", "ora", "aby" },{ "???", "nop", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "ora", "ora", "abx" },{ "asl", "asl", "abx" },{ "???", "xxx", "imp" },
    { "jsr", "jsr", "abs" },{ "and", "and", "izx" },{ "???", "xxx", "imp" },{ "???", "xxx", "imp" },{ "bit", "bit", "zp0" },{ "and", "and", "zp0" },{ "rol", "rol", "zp0" },{ "???", "xxx", "imp" },{ "plp", "plp", "imp" },{ "and", "and", "imm" },{ "rol", "rol", "imp" },{ "???", "xxx", "imp" },{ "bit", "bit", "abs" },{ "and", "and", "abs" },{ "rol", "rol", "abs" },{ "???", "xxx", "imp" },
    { "bmi", "bmi", "rel" },{ "and", "and", "izy" },{ "???", "xxx", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "and", "and", "zpx" },{ "rol", "rol", "zpx" },{ "???", "xxx", "imp" },{ "sec", "sec", "imp" },{ "and", "and", "aby" },{ "???", "nop", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "and", "and", "abx" },{ "rol", "rol", "abx" },{ "???", "xxx", "imp" },
    { "rti", "rti", "imp" },{ "eor", "eor", "izx" },{ "???", "xxx", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "eor", "eor", "zp0" },{ "lsr", "lsr", "zp0" },{ "???", "xxx", "imp" },{ "pha", "pha", "imp" },{ "eor", "eor", "imm" },{ "lsr", "lsr", "imp" },{ "???", "xxx", "imp" },{ "jmp", "jmp", "abs" },{ "eor", "eor", "abs" },{ "lsr", "lsr", "abs" },{ "???", "xxx", "imp" },
    { "bvc", "bvc", "rel" },{ "eor", "eor", "izy" },{ "???", "xxx", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "eor", "eor", "zpx" },{ "lsr", "lsr", "zpx" },{ "???", "xxx", "imp" },{ "cli", "cli", "imp" },{ "eor", "eor", "aby" },{ "???", "nop", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "eor", "eor", "abx" },{ "lsr", "lsr", "abx" },{ "???", "xxx", "imp" },
    { "rts", "rts", "imp" },{ "adc", "adc", "izx" },{ "???", "xxx", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "adc", "adc", "zp0" },{ "ror", "ror", "zp0" },{ "???", "xxx", "imp" },{ "pla", "pla", "imp" },{ "adc", "adc", "imm" },{ "ror", "ror", "imp" },{ "???", "xxx", "imp" },{ "jmp", "jmp", "ind" },{ "adc", "adc", "abs" },{ "ror", "ror", "abs" },{ "???", "xxx", "imp" },
    { "bvs", "bvs", "rel" },{ "adc", "adc", "izy" },{ "???", "xxx", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "adc", "adc", "zpx" },{ "ror", "ror", "zpx" },{ "???", "xxx", "imp" },{ "sei", "sei", "imp" },{ "adc", "adc", "aby" },{ "???", "nop", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "adc", "adc", "abx" },{ "ror", "ror", "abx" },{ "???", "xxx", "imp" },
    { "???", "nop", "imp" },{ "sta", "sta", "izx" },{ "???", "nop", "imp" },{ "???", "xxx", "imp" },{ "sty", "sty", "zp0" },{ "sta", "sta", "zp0" },{ "stx", "stx", "zp0" },{ "???", "xxx", "imp" },{ "dey", "dey", "imp" },{ "???", "nop", "imp" },{ "txa", "txa", "imp" },{ "???", "xxx", "imp" },{ "sty", "sty", "abs" },{ "sta", "sta", "abs" },{ "stx", "stx", "abs" },{ "???", "xxx", "imp" },
    { "bcc", "bcc", "rel" },{ "sta", "sta", "izy" },{ "???", "xxx", "imp" },{ "???", "xxx", "imp" },{ "sty", "sty", "zpx" },{ "sta", "sta", "zpx" },{ "stx", "stx", "zpy" },{ "???", "xxx", "imp" },{ "tya", "tya", "imp" },{ "sta", "sta", "aby" },{ "txs", "txs", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "sta", "sta", "abx" },{ "???", "xxx", "imp" },{ "???", "xxx", "imp" },
    { "ldy", "ldy", "imm" },{ "lda", "lda", "izx" },{ "ldx", "ldx", "imm" },{ "???", "xxx", "imp" },{ "ldy", "ldy", "zp0" },{ "lda", "lda", "zp0" },{ "ldx", "ldx", "zp0" },{ "???", "xxx", "imp" },{ "tay", "tay", "imp" },{ "lda", "lda", "imm" },{ "tax", "tax", "imp" },{ "???", "xxx", "imp" },{ "ldy", "ldy", "abs" },{ "lda", "lda", "abs" },{ "ldx", "ldx", "abs" },{ "???", "xxx", "imp" },
    { "bcs", "bcs", "rel" },{ "lda", "lda", "izy" },{ "???", "xxx", "imp" },{ "???", "xxx", "imp" },{ "ldy", "ldy", "zpx" },{ "lda", "lda", "zpx" },{ "ldx", "ldx", "zpy" },{ "???", "xxx", "imp" },{ "clv", "clv", "imp" },{ "lda", "lda", "aby" },{ "tsx", "tsx", "imp" },{ "???", "xxx", "imp" },{ "ldy", "ldy", "abx" },{ "lda", "lda", "abx" },{ "ldx", "ldx", "aby" },{ "???", "xxx", "imp" },
    { "cpy", "cpy", "imm" },{ "cmp", "cmp", "izx" },{ "???", "nop", "imp" },{ "???", "xxx", "imp" },{ "cpy", "cpy", "zp0" },{ "cmp", "cmp", "zp0" },{ "dec", "dec", "zp0" },{ "???", "xxx", "imp" },{ "iny", "iny", "imp" },{ "cmp", "cmp", "imm" },{ "dex", "dex", "imp" },{ "???", "xxx", "imp" },{ "cpy", "cpy", "abs" },{ "cmp", "cmp", "abs" },{ "dec", "dec", "abs" },{ "???", "xxx", "imp" },
    { "bne", "bne", "rel" },{ "cmp", "cmp", "izy" },{ "???", "xxx", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "cmp", "cmp", "zpx" },{ "dec", "dec", "zpx" },{ "???", "xxx", "imp" },{ "cld", "cld", "imp" },{ "cmp", "cmp", "aby" },{ "nop", "nop", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "cmp", "cmp", "abx" },{ "dec", "dec", "abx" },{ "???", "xxx", "imp" },
    { "cpx", "cpx", "imm" },{ "sbc", "sbc", "izx" },{ "???", "nop", "imp" },{ "???", "xxx", "imp" },{ "cpx", "cpx", "zp0" },{ "sbc", "sbc", "zp0" },{ "inc", "inc", "zp0" },{ "???", "xxx", "imp" },{ "inx", "inx", "imp" },{ "sbc", "sbc", "imm" },{ "nop", "nop", "imp" },{ "???", "sbc", "imp" },{ "cpx", "cpx", "abs" },{ "sbc", "sbc", "abs" },{ "inc", "inc", "abs" },{ "???", "xxx", "imp" },
    { "beq", "beq", "rel" },{ "sbc", "sbc", "izy" },{ "???", "xxx", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "sbc", "sbc", "zpx" },{ "inc", "inc", "zpx" },{ "???", "xxx", "imp" },{ "sed", "sed", "imp" },{ "sbc", "sbc", "aby" },{ "nop", "nop", "imp" },{ "???", "xxx", "imp" },{ "???", "nop", "imp" },{ "sbc", "sbc", "abx" },{ "inc", "inc", "abx" },{ "???", "xxx", "imp" }
}
lookup[0x00] = { "brk", "brk", "imm" }
