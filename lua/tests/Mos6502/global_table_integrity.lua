return {
    cases = {
        {
            name = "Global table 'Mos' and it's utilities should exist.",
            func = function()
                -- Global table
                expect( Mos ).to.exist()

                -- Assembler
                expect( Mos.Assembler ).to.exist()
                -- Assembler Utilities
                expect( Mos.Assembler.Ast ).to.exist()
                expect( Mos.Assembler.Compiler ).to.exists()
                expect( Mos.Assembler.Instructions ).to.exist()
                expect( Mos.Assembler.Lexer ).to.exist()
                expect( Mos.Assembler.Parser ).to.exist()
                expect( Mos.Assembler.Preprocessor ).to.exist()

                -- Editor
                expect( Mos.Editor ).to.exist()
                expect( Mos.Editor.Tabs ).to.exist()

                -- FileSystem
                expect( Mos.FileSystem ).to.exist()
                expect( Mos.FileSystem.FileFunctions ).to.exist()
                expect( Mos.FileSystem.FolderFunctions ).to.exist()
            end
        }
    }
}
