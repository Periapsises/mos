local Processor = {}
Mos.Processor = Processor

local Memory = include( "mos/server/processor/memory.lua" )
local Emulator = include( "mos/server/processor/emulator.lua" )

function Processor.Create( pos, ang, model, owner )
    local processor = ents.Create( "mos_processor" )
    processor:SetModel( model )
    processor:SetPos( pos )
    processor:SetAngles( ang )
    processor:SetOwner( owner )
    processor:Spawn()

    local phys = processor:GetPhysicsObject()
    if IsValid( phys ) then
        phys:EnableMotion( false )
    end

    processor.memory = Memory.Create( processor )
    processor.emulator = Emulator.Create( processor.memory )

    undo.Create( "Mos 6502 Processor" )
    undo.AddEntity( processor )
    undo.SetPlayer( owner )
    undo.Finish()

    return processor
end
