Mos = {}

AddCSLuaFile( "mos/editor/editor.lua" )
AddCSLuaFile( "mos/editor/file_system.lua" )
AddCSLuaFile( "mos/editor/tab_system.lua" )
AddCSLuaFile( "mos/editor/file_functions/files.lua" )
AddCSLuaFile( "mos/editor/file_functions/folders.lua" )

AddCSLuaFile( "mos/compiler/instructions.lua" )
AddCSLuaFile( "mos/compiler/compiler.lua" )
AddCSLuaFile( "mos/compiler/parser.lua" )
AddCSLuaFile( "mos/compiler/lexer.lua" )

for _, f in ipairs( file.Find( "mos/tests/*.lua", "LUA" ) ) do
    AddCSLuaFile( "mos/tests/" .. f )
end

include( "mos/editor/editor.lua" )

if CLIENT then
    include( "mos/compiler/compiler.lua" )
    include( "mos/tests/tests.lua" )
end
