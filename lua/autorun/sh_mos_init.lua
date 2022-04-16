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

AddCSLuaFile( "tests/parsing_test.lua" )

include( "mos/editor/editor.lua" )

if CLIENT then
    include( "mos/compiler/compiler.lua" )
end
