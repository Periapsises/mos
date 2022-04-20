local len, byte = string.len, string.byte
local bor, lshift = bit.bor, bit.lshift

local Processor = Mos.Processor

function Processor:GenerateMemory( code )
    self.memory = {}

    if not string.StartWith( code, "GMOS6502" ) then return end

    local memory = self.memory
    local address = 0

    local i = 8
    while i <= len( code ) do
        local lo, hi = byte( code[i] ), byte( code[i + 1] )
        local blockSize = bor( lshift( hi, 8 ), lo )

        lo, hi = byte( code[i + 2] ), byte( code[i + 3] )
        address = bor( lshift( hi, 8 ), lo ) - 1

        i = i + 4

        for j = 1, blockSize do
            memory[address + j] = byte( code[i + j] )
        end

        i = i + blockSize
    end
end
