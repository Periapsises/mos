local len, byte = string.len, string.byte
local bor, band, lshift = bit.bor, bit.band, bit.lshift

local Processor = Mos.Processor

-- Given a formated binary file from the client, this function generates a memory for a processor entity
function Processor:GenerateMemory( code )
    self.memory = {}

    if not string.StartWith( code, "GMOS6502" ) then return end

    local memory = self.memory
    local address = 0

    local i = 9
    while i <= len( code ) do
        local lo, hi = byte( code[i] ), byte( code[i + 1] )
        address = band( bor( lshift( hi, 8 ), lo ), 0xffff )

        lo, hi = byte( code[i + 2] ), byte( code[i + 3] )
        local blockSize = bor( lshift( hi, 8 ), lo )

        i = i + 4

        for j = 0, blockSize - 1 do
            memory[address + j] = byte( code[i + j] )
        end

        i = i + blockSize
    end
end
