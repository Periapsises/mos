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
        }
    }
}
