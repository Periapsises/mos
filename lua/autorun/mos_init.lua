AddCSLuaFile()

Mos = {}

-- Recursively adds clientside files from a specified folder
local function AddCSLuaFiles( path )
    local files, folders = file.Find( path .. "*", "LUA" )

    for _, f in ipairs( folders ) do
        AddCSLuaFiles( path .. f .. "/" )
    end

    for _, f in ipairs( files ) do
        AddCSLuaFile( path .. f )
    end
end

AddCSLuaFiles( "mos/client/" )
AddCSLuaFiles( "mos/shared/" )

AddCSLuaFile( "mos/tests/tests.lua" )
AddCSLuaFiles( "mos/tests/client/" )
AddCSLuaFiles( "mos/tests/shared/" )

include( "mos/shared/sh_init.lua" )

if SERVER then
    include( "mos/server/sv_init.lua" )
else
    include( "mos/client/cl_init.lua" )
end
