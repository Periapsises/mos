local Processor = {}
Mos.Processor = Processor

local Memory = include( "mos/server/processor/memory.lua" )
local Emulator = include( "mos/server/processor/emulator.lua" )

function Processor.Create( pos, ang, model, owner )
    local processor = ents.Create( "mos_processor" )
    chip:SetModel( model )
    chip:SetPos( pos )
    chip:SetAngles( ang )
    chip:SetOwner( owner )
    chip:Spawn()

    local phys = chip:GetPhysicsObject()
    if IsValid( phys ) then
        phys:EnableMotion( false )
    end

    processor.memory = Memory.Create()
    processor.emulator = Emulator.Create( processor.memory )

    undo.Create( "Mos 6502 Processor" )
    undo.AddEntity( chip )
    undo.SetPlayer( owner )
    undo.Finish()

    return processor
end
