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

                error( "Not fully implemented" )
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
