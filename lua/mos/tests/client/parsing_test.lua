local Parser = Mos.Assembler.Parser

local padding = ""

local function nodePrinter( self, key )
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

local function test( name, code, expected, printNodes, printTree )
    if printNodes then
        Parser.__index = nodePrinter
    end

    local success, msg = pcall( function()
        local parser = Parser.Create( code )
        return parser:parse()
    end )

    if success and printTree then
        local function printTable( tbl, padding )
            for key, value in pairs( tbl ) do
                if type( value ) == "table" then
                    print( padding .. key .. ": {" )
                    printTable( value, padding .. " |\t" )
                    print( padding .. "}" )
                else
                    if value == '\n' then value = '\\n' end

                    print( padding .. key .. ":\t" .. tostring( value ) )
                end
            end
        end

        printTable( msg, "" )
    end

    local sColor = Color( 139, 255, 178)
    local fColor = Color( 255, 147, 147)

    MsgC( "Test: ", Color( 217, 159, 255), name .. "\n" )
    MsgC( "    Result: ", success and sColor or fColor, ( success and "Success" or "Failure" ) .. "\n" )
    MsgC( "    Expected: ", expected and sColor or fColor, ( expected and "Success" or "Failure" ) .. "\n\n" )

    if not success then
        MsgC( "    Message: ", Color( 255, 214, 137), string.GetFileFromFilename( msg ) .. "\n\n" )
    end

    Parser.__index = Parser
end

--------------------------------------------------
-- Tests

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
    adc [0,x]
    adc [0],y
]]

print( "\n----- Tests -----\n" )

test( "Valid code", validCodeTest, true, false, true )
test( "Empty code", "\n", true )
test( "Invalid Instruction", "lol\n" )
test( "Invalid register", "adc 0,a\n" )
test( "Invalid index register", "adc [0,y]\n" )
test( "Expected identifier", "0\n" )

local validIfdefTest = [[
#ifdef VAR
    nop
    nop
#ifdef ANOTHER_VAR
    nop
#endif // ANOTHER_VAR
#endif // VAR
]]

test( "Valid #ifdef", validIfdefTest, true )
test( "Invalid #ifdef", "#ifdef VAR\n", false )
test( "Empty #ifdef", "#ifdef VAR\n#endif\n", true )

local validOperations = [[
adc 1+1
adc 1-1
adc 1*1
adc 1/1
adc 1+1*1
adc 1*1+1
adc (1+1)*1
]]

test( "Valid operations", validOperations, true )
test( "Unbalanced parenthesis", "adc (1 + (1 - 1)\n", false )

local validDirective = [[
.db "Hello, world!\n", 0x00
]]

test( "Valid directive", validDirective, true )
