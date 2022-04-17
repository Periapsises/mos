local function runTests()
    for _, f in ipairs( file.Find( "mos/tests/*.lua", "LUA" ) ) do
        if f ~= "tests.lua" then
            include( "mos/tests/" .. f )
        end
    end
end

concommand.Add( "_mos_run_tests", runTests, nil, "Runs the test files for the Mos6502 addon" )
