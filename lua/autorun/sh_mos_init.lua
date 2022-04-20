Mos = {}

local function AddCSLuaFiles( path )
    for _, f in ipairs( file.Find( path .. "*.lua", "LUA" ) ) do
        AddCSLuaFile( path .. f )
    end
end

AddCSLuaFiles( "mos/editor/" )
AddCSLuaFiles( "mos/editor/file_functions/" )
AddCSLuaFiles( "mos/editor/utils/" )
AddCSLuaFiles( "mos/compiler/" )
AddCSLuaFiles( "mos/compiler/ast/" )

AddCSLuaFiles( "mos/tests/" )

include( "mos/editor/editor.lua" )

if CLIENT then
    include( "mos/compiler/compiler.lua" )
    include( "mos/tests/tests.lua" )
else
    include( "mos/cpu/transfer.lua" )
end
