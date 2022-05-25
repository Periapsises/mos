return {
    cases = {
        {
            name = "Supported gmod extensions should be allowed.",
            clientside = true,
            func = function()
                for _, extension in ipairs( FileSystem.allowedExtensions ) do
                    expect( Mos.FileSystem.HasAllowedExtension( "some/file" .. extension ).to.beTrue() )
                end
            end
        },
        {
            name = "Unsupported gmod extensions should be disallowed.",
            clientside = true,
            func = function()
                for _, extension in ipairs( {".asm", ".bin", ".exe", ".lib"} ) do
                    expect( Mos.FileSystem.HasAllowedExtension( "some/file" .. extension ).to.beFalse() )
                end
            end
        },
        {
            name = "File paths should be properly sanitized.",
            clientside = true,
            func = function()
                expect( Mos.FileSystem.GetSanitizedPath( "some/file.txt" ) ).to.equal( "some/file.txt" )
                expect( Mos.FileSystem.GetSanitizedPath( "some/file.asm" ) ).to.equal( "some/file.asm~.txt" )
                expect( Mos.FileSystem.GetDirtyPath( "some/file.txt" ).to.equal( "some/file.txt" ) )
                expect( Mos.FileSystem.GetDirtyPath( "some/file.asm~.txt" ).to.equal( "some/file.asm" ) )
            end
        },
        {
            name = "Files should be properly be written and read from.",
            clientside = true,
            func = function()
                expect( Mos.FileSystem.Exists( "_glua_test.asm" ) ).to.beFalse()
                Mos.FileSystem.Write( "_glua_test.asm", "Hello, world!" )
                expect( Mos.FileSystem.Exists( "_glua_test.asm" ) ).to.beTrue()
                expect( Mos.FileSystem.Read( "_glua_test.asm" ) ).to.equal( "Hello, world!" )
                file.Delete( "_glua_test.asm~.txt" )
                expect( Mos.FileSystem.Exists( "_glua_test.asm" ) ).to.beFalse()
            end
        }
    }
}
