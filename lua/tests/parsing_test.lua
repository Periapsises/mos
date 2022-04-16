-- Tests only run on myself, Periapsis :D
if SERVER then return end
if LocalPlayer():SteamID() ~= "STEAM_0:1:115301653" then return end

local Lexer = Mos.Compiler.Lexer
local Parser = Mos.Compiler.Parser

local validCodeTest = [[
// Single line comment

/*
    Multi line comment
*/

#define VAR
#ifdef VAR
    nop
#endif

label:
    nop
    NOP // Comment after instruction
    adc #0
    adc #0b0
    adc #0d0
    adc #0x0
    adc #0h0

    adc 0
    adc 0,x
    adc 0,X
    adc 0,y
    adc (0,x)
    adc (0),y
]]

print( "\n----------------------------------------\n" )

local padding = ""

Parser.__index = function( self, key )
    local value = Parser[key]

    if type( value ) == "function" and key ~= "Eat" then
        local _padding = padding

        return function( ... )
            padding = padding .. "  "
            print( _padding .. "Enter: " .. key )

            local ret = {value( ... )}

            print( _padding .. "Exit: " .. key )
            padding = _padding

            return unpack( ret )
        end
    end

    return value
end

local sucess, msg = pcall( function()
    local parser = Parser:Create( validCodeTest )
    parser:Parse()
end )

if not sucess then
    print( "\n", msg )
end

Parser.__index = Parser
