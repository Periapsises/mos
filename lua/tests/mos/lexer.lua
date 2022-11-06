return {
    cases = {
        {
            name = "Lexer should return the proper stream of tokens.",
            clientside = true,
            func = function()
                local lexer = Mos.Assembler.Lexer.Create( [[
                    // Comment
                    /*
                        Multiline
                        Comment
                    */#.iD._09[],:+-*/()"String"'String'"\\n"0123456789
                    0b0101
                    0d1234
                    0xabcd
                    0hf000
                ]] )

                local function getNextToken()
                    return lexer:getNextToken().type
                end

                expect( getNextToken() ).to.equal( "Newline" )       -- \n
                expect( getNextToken() ).to.equal( "Hash" )          -- #
                expect( getNextToken() ).to.equal( "Dot" )           -- .
                expect( getNextToken() ).to.equal( "Identifier" )    -- iD._09
                expect( getNextToken() ).to.equal( "LSqrBracket" )   -- [
                expect( getNextToken() ).to.equal( "RSqrBracket" )   -- ]
                expect( getNextToken() ).to.equal( "Comma" )         -- ,
                expect( getNextToken() ).to.equal( "Colon" )         -- :
                expect( getNextToken() ).to.equal( "Operator" )      -- +
                expect( getNextToken() ).to.equal( "Operator" )      -- -
                expect( getNextToken() ).to.equal( "Operator" )      -- *
                expect( getNextToken() ).to.equal( "Operator" )      -- /
                expect( getNextToken() ).to.equal( "LParen" )        -- (
                expect( getNextToken() ).to.equal( "RParen" )        -- )
                expect( getNextToken() ).to.equal( "String" )        -- "String"
                expect( getNextToken() ).to.equal( "String" )        -- 'String'
                expect( getNextToken() ).to.equal( "String" )        -- "\n"
                expect( getNextToken() ).to.equal( "Number" )        -- 0123456789
                expect( getNextToken() ).to.equal( "Newline" )       -- \n
                expect( getNextToken() ).to.equal( "Number" )        -- 0b0101
                expect( getNextToken() ).to.equal( "Newline" )       -- \n
                expect( getNextToken() ).to.equal( "Number" )        -- 0d1234
                expect( getNextToken() ).to.equal( "Newline" )       -- \n
                expect( getNextToken() ).to.equal( "Number" )        -- 0xabcd
                expect( getNextToken() ).to.equal( "Newline" )       -- \n
                expect( getNextToken() ).to.equal( "Number" )        -- 0hf000
            end
        }
    }
}
