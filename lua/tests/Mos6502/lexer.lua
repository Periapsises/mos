return {
    cases = {
        {
            name = "Lexer should return the proper stream of tokens.",
            clientside = true,
            func = function()
                local lexer = Mos.Assembler.Lexer.Create( "// Comment\n/*\nMultiline\nComment\n*/#.iD._09[],:+-*/()\"String\"'String'\"\\n\"0123456789\n0b0101\n0d1234\n0xabcd\n0hf000" )

                expect( lexer:getNextToken().type ).to.equal( "Newline" )       -- \n
                expect( lexer:getNextToken().type ).to.equal( "Hash" )          -- #
                expect( lexer:getNextToken().type ).to.equal( "Dot" )           -- .
                expect( lexer:getNextToken().type ).to.equal( "Identifier" )    -- iD._09
                expect( lexer:getNextToken().type ).to.equal( "LSqrBracket" )   -- [
                expect( lexer:getNextToken().type ).to.equal( "RSqrBracket" )   -- ]
                expect( lexer:getNextToken().type ).to.equal( "Comma" )         -- ,
                expect( lexer:getNextToken().type ).to.equal( "Colon" )         -- :
                expect( lexer:getNextToken().type ).to.equal( "Operator" )      -- +
                expect( lexer:getNextToken().type ).to.equal( "Operator" )      -- -
                expect( lexer:getNextToken().type ).to.equal( "Operator" )      -- *
                expect( lexer:getNextToken().type ).to.equal( "Operator" )      -- /
                expect( lexer:getNextToken().type ).to.equal( "LParen" )        -- (
                expect( lexer:getNextToken().type ).to.equal( "RParen" )        -- )
                expect( lexer:getNextToken().type ).to.equal( "String" )        -- "String"
                expect( lexer:getNextToken().type ).to.equal( "String" )        -- 'String'
                expect( lexer:getNextToken().type ).to.equal( "String" )        -- "\n"
                expect( lexer:getNextToken().type ).to.equal( "Number" )        -- 0123456789
                expect( lexer:getNextToken().type ).to.equal( "Newline" )       -- \n
                expect( lexer:getNextToken().type ).to.equal( "Number" )        -- 0b0101
                expect( lexer:getNextToken().type ).to.equal( "Newline" )       -- \n
                expect( lexer:getNextToken().type ).to.equal( "Number" )        -- 0d1234
                expect( lexer:getNextToken().type ).to.equal( "Newline" )       -- \n
                expect( lexer:getNextToken().type ).to.equal( "Number" )        -- 0xabcd
                expect( lexer:getNextToken().type ).to.equal( "Newline" )       -- \n
                expect( lexer:getNextToken().type ).to.equal( "Number" )        -- 0hf000
            end
        }
    }
}
