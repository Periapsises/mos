return {
    cases = {
        {
            name = "Parser should eat tokens properly.",
            clientside = true,
            func = function()
                local parser = Mos.Assembler.Parser.Create( "id\n'Hello'" )
                parser.token = parser.lexer:getNextToken()

                expect( parser.eat, parser, "Identifier" ).to.succeed()
                expect( parser.eat, parser, "Newline" ).to.succeed()
                expect( parser.eat, parser, "String" ).to.succeed()
                expect( parser.eat, parser, "Identifier" ).to.errWith( "Expected Identifier got Newline at line 2, char 8" )
                expect( parser.eat, parser, "Newline" ).to.succeed()
                expect( parser.eat, parser, "Number" ).to.errWith( "Expected Number got Eof at line 3, char 1" )
            end
        },
        {
            name = "Parser should generate proper ASTs.",
            clientside = true,
            func = function()
                local parser = Mos.Assembler.Parser.Create( "// Hello\nlabel:\n    jmp label" )
                local ast

                expect( function() ast = parser:parse() end ).to.succeed()
                expect( ast ).to.exist()
                expect( ast._type ).to.equal( "Program" )
                expect( ast._value ).to.exist()
                expect( ast._value._type ).to.equal( "List" )
                expect( ast._value._value ).to.exist()
                expect( ast._value._value[1] ).to.exist()
                expect( ast._value._value[1]._type ).to.equal( "Label" )
                expect( ast._value._value[1]._value ).to.exist()
                expect( ast._value._value[1]._value._type ).to.equal( "Identifier" )
                expect( ast._value._value[1]._value._value ).to.equal( "label" )
                expect( ast._value._value[2] ).to.exist()
                expect( ast._value._value[2]._type ).to.equal( "Instruction" )
                expect( ast._value._value[2]._value ).to.exist()
                expect( ast._value._value[2]._value.Name ).to.exist()
                expect( ast._value._value[2]._value.Name._type ).to.equal( "Identifier" )
                expect( ast._value._value[2]._value.Name._value ).to.equal( "jmp" )
                expect( ast._value._value[2]._value.Operand ).to.exist()
                expect( ast._value._value[2]._value.Operand._type ).to.equal( "Operand" )
                expect( ast._value._value[2]._value.Operand._value ).to.exist()
                expect( ast._value._value[2]._value.Operand._value.Mode ).to.exist()
                expect( ast._value._value[2]._value.Operand._value.Mode._type ).to.equal( "Identifier" )
                expect( ast._value._value[2]._value.Operand._value.Mode._value ).to.equal( "Absolute" )
                expect( ast._value._value[2]._value.Operand._value.Value ).to.exist()
                expect( ast._value._value[2]._value.Operand._value.Value._type ).to.equal( "Expression" )
            end
        },
        -- Test that the parser can handle an empty line.
        {
            name = "Parser should handle empty lines.",
            clientside = true,
            func = function()
                local parser = Mos.Assembler.Parser.Create( "\n" )

                expect( function() parser:parse() end ).to.succeed()
            end
        },
        -- Test that the parser can handle a line with only a comment.
        {
            name = "Parser should handle comments.",
            clientside = true,
            func = function()
                local parser = Mos.Assembler.Parser.Create( "// Hello" )

                expect( function() parser:parse() end ).to.succeed()
            end
        },
        -- Test that the parser throws an error when it encounters an unknown token.
        {
            name = "Parser should throw an error when it encounters an unknown token.",
            clientside = true,
            func = function()
                local parser = Mos.Assembler.Parser.Create( "1234" )

                expect( function() parser:parse() end ).to.errWith( "Expected Identifier got Number at line 1, char 1" )
            end
        },
        -- Test that the parser can handle a line with a label.
        {
            name = "Parser should handle labels.",
            clientside = true,
            func = function()
                local parser = Mos.Assembler.Parser.Create( "label:" )
                local ast

                expect( function() ast = parser:parse() end ).to.succeed()
                expect( ast ).to.exist()
            end
        }
    }
}
