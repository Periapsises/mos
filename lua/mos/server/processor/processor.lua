local Processor = {}
Mos.Processor = Processor

local Memory = include( "mos/server/processor/memory.lua" )
local Emulator = include( "mos/server/processor/emulator.lua" )

function Processor.Create()
    local processor = {}

    processor.memory = Memory.Create()
    processor.emulator = Emulator.Create( processor.memory )

    return setmetatable( processor, Processor )
end
