local function runAllTests()
    local path = SERVER and "mos/tests/server/" or "mos/tests/client/"
    local files = file.Find( path .. "*.lua", "LUA" )

    for _, f in ipairs( files ) do
        include( path .. f )
    end
end

concommand.Add( "_mos_run_all_tests", runAllTests, nil, "Runs all test files on both realms" )

if SERVER then
    concommand.Add( "_mos_run_server_tests", runAllTests, nil, "Runs all server side test files" )
else
    concommand.Add( "_mos_run_client_tests", runAllTests, nil, "Runs all client side test files" )
end
