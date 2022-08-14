local Processor = {}
Mos.Processor = Processor

function Processor.Create()
    local processor = {}

    processor.memory = Processor.Memory.Create()
    processor.emulator = Processor.Emulator.Create( processor.memory )

    return setmetatable( processor, Processor )
end
