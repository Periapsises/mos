AddCSLuaFile()

Mos = {}

-- Recursively adds clientside files from a specified folder only if the file is a lua file
local function AddCSLuaFiles( path )
    local files, folders = file.Find( path .. "*", "LUA" )

    for _, f in ipairs( folders ) do
        AddCSLuaFiles( path .. f .. "/" )
    end

    for _, f in ipairs( files ) do
        if f:sub( -4 ) == ".lua" then
            AddCSLuaFile( path .. f )
        end
    end
end

AddCSLuaFile( "mos/client/init.lua" )
AddCSLuaFiles( "mos/client/utils/" )
AddCSLuaFiles( "mos/client/vgui/" )

if SERVER then
else
    include( "mos/client/init.lua" )
end
