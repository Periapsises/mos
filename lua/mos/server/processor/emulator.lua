local Emulator = {}
Mos.Processor.Emulator = Emulator

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

local function read( emulator, addr )
    return emulator.memory:read( addr )
end

local function write( emulator, addr, value )
    emulator.memory:write( addr, value )
end

--------------------------------------------------
-- Execution

Emulator.__index = Emulator

function Emulator.Create( memory )
    local emulator = setmetatable( { memory = memory }, Emulator )
    emulator:reset()

    return emulator
end

function Emulator:clock()
    self:setFlag( u, 1 )

    local opcode = read( self, self.pc )
    self.pc = band( self.pc + 1, 0xffff )

    local instruction = lookup[opcode]

    if addressingModes[instruction[3]] then
        local value = addressingModes[instruction[3]]( self )
        instructions[instruction[2]]( self, value )
    end

    self:setFlag( u, 1 )
end

--------------------------------------------------
-- Flags

function Emulator:setFlag( flag, value )
    if value ~= 0 or value == true then
        self.flags = bor( self.flags, flag )
    end

    self.flags = band( self.flags, bnot( flag ) )
end

function Emulator:getFlag( flag )
    local result = band( self.flags, flag )

    return result == 0 and 0 or 1
end

--------------------------------------------------
-- External inputs

function Emulator:reset()
    self.addrAbs = resetVector

    local lo = read( self, resetVector )
    local hi = read( self, resetVector + 1 )

    self.pc = bor( lshift( hi, 8 ), lo )

    self.a, self.x, self.y = 0, 0, 0
    self.stkp = 0xfd
    self.flags = u
end

function Emulator:irq()
    if self:getFlag( i ) ~= 0 then return end

    write( self, 0x0100 + self.stkp, rshift( self.pc, 8 ) )
    self.stkp = band( self.stkp - 1, 0xff )

    write( self, 0x0100 + self.stkp, self.pc )
    self.stkp = band( self.stkp - 1, 0xff )

    self:setFlag( b, 0 )
    self:setFlag( u, 1 )
    self:setFlag( i, 1 )

    write( self, 0x0100 + self.stkp, self.flags )
    self.stkp = band( self.stkp - 1, 0xff )

    self.addrAbs = irqVector

    local lo = read( self, irqVector )
    local hi = read( self, irqVector + 1 )

    self.pc = bor( lshift( hi, 8 ), lo )
end

function Emulator:nmi()
    write( self, 0x0100 + self.stkp, rshift( self.pc, 8 ) )
    self.stkp = band( self.stkp - 1, 0xff )

    write( self, 0x0100 + self.stkp, self.pc )
    self.stkp = band( self.stkp - 1, 0xff )

    self:setFlag( b, 0 )
    self:setFlag( u, 1 )
    self:setFlag( i, 1 )

    write( self, 0x0100 + self.stkp, self.flags )
    self.stkp = band( self.stkp - 1, 0xff )

    self.addrAbs = nmiVector

    local lo = read( self, nmiVector )
    local hi = read( self, nmiVector + 1 )

    self.pc = bor( lshift( hi, 8 ), lo )
end

--------------------------------------------------
-- Addressing modes

function addressingModes.acc( emulator )
    return emulator.a
end

function addressingModes.abs( emulator )
    local lo = read( emulator, emulator.pc )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    local hi = read( emulator, emulator.pc )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    emulator.addrAbs = bor( lshift( hi, 8 ), lo )
    return read( emulator, emulator.addrAbs )
end

function addressingModes.abx( emulator )
    local lo = read( emulator, emulator.pc )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    local hi = read( emulator, emulator.pc )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    emulator.addrAbs = bor( lshift( hi, 8 ), lo ) + emulator.x
    return read( emulator, emulator.addrAbs )
end

function addressingModes.aby( emulator )
    local lo = read( emulator, emulator.pc )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    local hi = read( emulator, emulator.pc )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    emulator.addrAbs = bor( lshift( hi, 8 ), lo ) + emulator.y
    return read( emulator, emulator.addrAbs )
end

function addressingModes.imm( emulator )
    emulator.addrAbs = emulator.pc

    local value = read( emulator, emulator.pc )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    return value
end

function addressingModes.imp()
    return
end

function addressingModes.ind( emulator )
    local ptrLo = read( emulator, emulator.pc )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    local ptrHi = read( emulator, emulator.pc )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    local ptr = bor( lshift( ptrHi, 8 ), ptrLo )

    --? Simulation of the page boundary hardware bug
    if ptr_lo == 0xff then
        local addr = bor( lshift( read( emulator, band( ptr, 0xff ) ), 8 ), read( emulator, ptr ) )
        return read( emulator, addr )
    end

    emulator.addrAbs = bor( lshift( read( emulator, ptr + 1 ), 8 ), read( emulator, ptr ) )
    return read( emulator, emulator.addrAbs )
end

function addressingModes.inx( emulator )
    local ptr = read( emulator, emulator.pc ) + emulator.x
    emulator.pc = band( emulator.pc + 1, 0xffff )

    local lo = read( emulator, ptr )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    local hi = read( emulator, ptr + 1 )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    emulator.addrAbs = bor( lshift( hi, 8 ), lo )
    return read( emulator, emulator.addrAbs )
end

function addressingModes.iny( emulator )
    local ptr = read( emulator, emulator.pc )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    local lo = read( emulator, ptr )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    local hi = read( emulator, ptr + 1 )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    emulator.addrAbs = bor( lshift( hi, 8 ), lo ) + emulator.y
    return read( emulator, emulator.addrAbs )
end

function addressingModes.rel( emulator )
    local addr = read( emulator, emulator.pc )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    if band( addr, 0x80 ) ~= 0 then
        addr = bor( addr, 0xff00 )
    end

    emulator.addrAbs = addr
    return addr
end

--------------------------------------------------
-- Instructions

function instructions.adc( emulator, value )
    local result = emulator.a + value + emulator:getFlag( c )

    emulator:setFlag( c, band( result, 0xff00 ) )
    emulator:setFlag( z, band( result, 0x00ff ) == 0 )
    emulator:setFlag( v, band( band( bnot( bxor( emulator.a, value ) ), bxor( emulator.a, result ) ), 0x80 ) )
    emulator:setFlag( n, band( result, 0x80 ) )

    emulator.a = band( result, 0xff )
end

function instructions.sbc( emulator, value )
    local result = emulator.a + bxor( value, 0xff ) + emulator:getFlag( c )

    emulator:setFlag( c, band( result, 0xff00 ) )
    emulator:setFlag( z, band( result, 0x00ff ) == 0 )
    emulator:setFlag( v, band( band( bxor( result, emulator.a ), bxor( result, value ) ), 0x80 ) )
    emulator:setFlag( n, band( result, 0x80 ) )

    emulator.a = band( result, 0xff )
end

instructions["and"] = function( emulator, value )
    emulator.a = band( emulator.a, value )

    emulator:setFlag( z, emulator.a == 0 )
    emulator:setFlag( n, band( a, 0x80 ) )
end

function instructions.asl( emulator, value )
    local result = lshift( value, 1 )

    emulator:setFlag( c, band( result, 0xff00 ) )
    emulator:setFlag( z, band( result, 0x00ff ) == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )

    if emulator.mode == "imp" or emulator.mode == "acc" then
        emulator.a = band( result, 0xff )
        return
    end

    write( emulator, emulator.addrAbs, result )
end

-- Branching instructions

function instructions.bcc( emulator, value )
    if emulator:getFlag( c ) ~= 0 then return end

    emulator.pc = band( emulator.pc + value, 0xffff )
end

function instructions.bcs( emulator, value )
    if emulator:getFlag( c ) == 0 then return end

    emulator.pc = band( emulator.pc + value, 0xffff )
end

function instructions.beq( emulator, value )
    if emulator:getFlag( z ) ~= 0 then return end

    emulator.pc = band( emulator.pc + value, 0xffff )
end

function instructions.bne( emulator, value )
    if emulator:getFlag( z ) == 0 then return end

    emulator.pc = band( emulator.pc + value, 0xffff )
end

function instructions.bpl( emulator, value )
    if emulator:getFlag( n ) ~= 0 then return end

    emulator.pc = band( emulator.pc + value, 0xffff )
end

function instructions.bmi( emulator, value )
    if emulator:getFlag( n ) == 0 then return end

    emulator.pc = band( emulator.pc + value, 0xffff )
end

function instructions.bvc( emulator, value )
    if emulator:getFlag( v ) ~= 0 then return end

    emulator.pc = band( emulator.pc + value, 0xffff )
end

function instructions.bvs( emulator, value )
    if emulator:getFlag( v ) == 0 then return end

    emulator.pc = band( emulator.pc + value, 0xffff )
end

function instructions.bit( emulator, value )
    local result = band( emulator.a, value )

    emulator:setFlag( z, band( result, 0xff ) == 0 )
    emulator:setFlag( n, band( value, 0x80 ) )
    emulator:setFlag( v, band( value, 0x40 ) )
end

function instructions.brk( emulator )
    emulator.pc = band( emulator.pc + 1, 0xffff )

    write( emulator, 0x0100 + emulator.stkp, rshift( emulator.pc, 8 ) )
    emulator.stkp = band( emulator.stkp - 1, 0xff )

    write( emulator, 0x0100 + emulator.stkp, emulator.pc )
    emulator.stkp = band( emulator.stkp - 1, 0xff )

    emulator:setFlag( i, 1 )
    emulator:setFlag( b, 1 )

    write( emulator, 0x0100 + emulator.stkp, emulator.flags )
    emulator.stkp = band( emulator.stkp - 1, 0xff )

    emulator:setFlag( b, 0 )

    emulator.pc = bor( read( emulator, irqVector ), lshift( read( emulator, irqVector + 1 ), 8 ) )
end

function instructions.clc( emulator )
    emulator:setFlag( c, 0 )
end

function instructions.cld( emulator )
    emulator:setFlag( d, 0 )
end

function instructions.cli( emulator )
    emulator:setFlag( i, 0 )
end

function instructions.clv( emulator )
    emulator:setFlag( v, 0 )
end

function instructions.clc( emulator )
    emulator:setFlag( c, 0 )
end

function instructions.cmp( emulator, value )
    local result = emulator.a - value

    emulator:setFlag( c, emulator.a >= value )
    emulator:setFlag( z, band( result, 0xff ) == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )
end

function instructions.cpx( emulator, value )
    local result = emulator.x - value

    emulator:setFlag( c, emulator.x >= value )
    emulator:setFlag( z, band( result, 0xff ) == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )
end

function instructions.cpy( emulator, value )
    local result = emulator.y - value

    emulator:setFlag( c, emulator.y >= value )
    emulator:setFlag( z, band( result, 0xff ) == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )
end

function instructions.dec( emulator, value )
    local result = value - 1

    write( emulator, emulator.addrAbs, result )

    emulator:setFlag( z, band( result, 0xff ) == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )
end

function instructions.dex( emulator )
    local result = emulator.x - 1
    emulator.x = band( result, 0xff )

    emulator:setFlag( z, band( result, 0xff ) == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )
end

function instructions.dey( emulator )
    local result = emulator.y - 1
    emulator.y = band( result, 0xff )

    emulator:setFlag( z, band( result, 0xff ) == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )
end

function instructions.eor( emulator, value )
    local result = bxor( emulator.a, value )

    emulator:setFlag( z, result == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )

    emulator.a = result
end

function instructions.inc( emulator, value )
    local result = value + 1

    write( emulator, emulator.addrAbs, result )

    emulator:setFlag( z, band( result, 0xff ) == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )
end

function instructions.inx( emulator )
    local result = emulator.x + 1
    emulator.x = band( result, 0xff )

    emulator:setFlag( z, band( result, 0xff ) == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )
end

function instructions.iny( emulator )
    local result = emulator.y + 1
    emulator.y = band( result, 0xff )

    emulator:setFlag( z, band( result, 0xff ) == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )
end

function instructions.jmp( emulator )
    emulator.pc = emulator.addrAbs
end

function instructions.jsr( emulator, value )
    emulator.pc = band( emulator.pc - 1, 0xffff )

    write( emulator, 0x0100 + emulator.stkp, rshift( emulator.pc, 8 ) )
    emulator.stkp = band( emulator.stkp - 1, 0xff )

    write( emulator, 0x0100 + emulator.stkp, emulator.pc )
    emulator.stkp = band( emulator.stkp - 1, 0xff )

    emulator.pc = value
end

function instructions.lda( emulator, value )
    emulator.a = value

    emulator:setFlag( z, value == 0 )
    emulator:setFlag( n, band( value, 0x80 ) )
end

function instructions.ldx( emulator, value )
    emulator.x = value

    emulator:setFlag( z, value == 0 )
    emulator:setFlag( n, band( value, 0x80 ) )
end

function instructions.ldy( emulator, value )
    emulator.y = value

    emulator:setFlag( z, value == 0 )
    emulator:setFlag( n, band( value, 0x80 ) )
end

function instructions.lsr( emulator, value )
    local result = rshift( value, 1 )

    emulator:setFlag( c, band( value, 1 ) )
    emulator:setFlag( z, band( result, 0xff ) == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )

    if emulator.mode == "imp" or emulator.mode == "acc" then
        emulator.a = band( result, 0xff )
        return
    end

    write( emulator, emulator.addrAbs, result )
end

function instructions.nop()
end

function instructions.ora( emulator, value )
    local result = bor( emulator.a, value )

    emulator:setFlag( z, result == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )

    emulator.a = result
end

function instructions.pha( emulator )
    write( emulator, 0x0100 + emulator.stkp, emulator.a )
    emulator.stkp = band( emulator.stkp - 1, 0xff )
end

function instructions.php( emulator )
    write( emulator, 0x0100 + emulator.stkp, bor( emulator.flags, b + u ) )
    emulator.stkp = band( emulator.stkp - 1, 0xff )

    emulator:setFlag( b, 0 )
    emulator:setFlag( u, 0 )
end

function instructions.pla( emulator )
    emulator.stkp = band( emulator.stkp + 1, 0xff )
    local result = read( emulator, 0x0100 + emulator.stkp )

    emulator:setFlag( z, result == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )

    emulator.a = result
end

function instructions.plp( emulator )
    emulator.stkp = band( emulator.stkp + 1, 0xff )
    emulator.flags = read( emulator, 0x0100 + emulator.stkp )

    emulator:setFlag( u, 1 )
end

function instructions.rol( emulator, value )
    local result = bor( lshift( value, 1 ), emulator:getFlag( c ) )

    emulator:setFlag( c, band( result, 0xff00 ) )
    emulator:setFlag( z, band( result, 0xff ) == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )

    if emulator.mode == "imp" or emulator.mode == "acc" then
        emulator.a = band( result, 0xff )
        return
    end

    write( emulator, emulator.addrAbs, result )
end

function instructions.ror( emulator, value )
    local result = bor( rshift( value, 1 ), lshift( emulator:getFlag( c ), 7 ) )

    emulator:setFlag( c, band( value, 1 ) )
    emulator:setFlag( z, band( result, 0xff ) == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )

    if emulator.mode == "imp" or emulator.mode == "acc" then
        emulator.a = band( result, 0xff )
        return
    end

    write( emulator, emulator.addrAbs, result )
end

function instructions.rti( emulator )
    emulator.stkp = band( emulator.stkp + 1, 0xff )
    emulator.flags = read( emulator, 0x0100 + emulator.stkp )
    emulator.flags = band( emulator.flags, bnot( b + u ) )

    emulator.stkp = band( emulator.stkp + 1, 0xff )
    local lo = read( emulator, 0x0100 + emulator.stkp )

    emulator.stkp = band( emulator.stkp + 1, 0xff )
    local hi = read( emulator, 0x0100 + emulator.stkp )

    emulator.pc = bor( lshift( hi, 8 ), lo )
end

function instructions.rts( emulator )
    emulator.stkp = band( emulator.stkp + 1, 0xff )
    local lo = read( emulator, 0x0100 + emulator.stkp )

    emulator.stkp = band( emulator.stkp + 1, 0xff )
    local hi = read( emulator, 0x0100 + emulator.stkp )

    emulator.pc = bor( lshift( hi, 8 ), lo )
end

function instructions.sec( emulator )
    emulator:setFlag( c, 1 )
end

function instructions.sed( emulator )
    emulator:setFlag( d, 1 )
end

function instructions.sei( emulator )
    emulator:setFlag( i, 1 )
end

function instructions.sta( emulator )
    write( emulator, emulator.addrAbs, emulator.a )
end

function instructions.stx( emulator )
    write( emulator, emulator.addrAbs, emulator.x )
end

function instructions.sty( emulator )
    write( emulator, emulator.addrAbs, emulator.y )
end

function instructions.tax( emulator )
    local result = emulator.a

    emulator:setFlag( z, result == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )

    emulator.x = result
end

function instructions.tay( emulator )
    local result = emulator.a

    emulator:setFlag( z, result == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )

    emulator.y = result
end

function instructions.tsx( emulator )
    local result = emulator.stkp

    emulator:setFlag( z, result == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )

    emulator.x = result
end

function instructions.txa( emulator )
    local result = emulator.x

    emulator:setFlag( z, result == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )

    emulator.a = result
end

function instructions.txs( emulator )
    emulator.stkp = emulator.x
end

function instructions.tya( emulator )
    local result = emulator.y

    emulator:setFlag( z, result == 0 )
    emulator:setFlag( n, band( result, 0x80 ) )

    emulator.a = result
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

return Emulator
