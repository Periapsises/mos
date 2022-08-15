local Memory = {}
Memory.__index = Memory

local len, byte = string.len, string.byte
local bor, band, lshift = bit.bor, bit.band, bit.lshift

function Memory.Create( processor )
    return setmetatable( { processor = processor }, Memory )
end

function Memory:generate( code )
    if not string.StartWith( code, "GMOS6502" ) then return end

    local address = 0

    local i = 9
    while i <= len( code ) do
        local lo, hi = byte( code[i] ), byte( code[i + 1] )
        address = band( bor( lshift( hi, 8 ), lo ), 0xffff )

        lo, hi = byte( code[i + 2] ), byte( code[i + 3] )
        local blockSize = bor( lshift( hi, 8 ), lo )

        i = i + 4

        for j = 0, blockSize - 1 do
            self[address + j] = byte( code[i + j] )
        end

        i = i + blockSize
    end
end

function Memory:write( address, value )
    if IsValid( self.processor.WirelinkEnt ) then
        return self.processor.WirelinkEnt:WriteCell( address, value )
    end

    self[address] = value
end

function Memory:read( address )
    if IsValid( self.processor.WirelinkEnt ) then
        return self.processor.WirelinkEnt:ReadCell( address ) or 0
    end

    return self[address] or 0
end

return Memory
