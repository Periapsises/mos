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

local lexer = Lexer:Create( validCodeTest )
local token

repeat
    token = lexer:GetNextToken()
    print(token.type, token.value)
until (token.type == "eof")

local parser = Parser:Create( validCodeTest )
parser:Parse()
