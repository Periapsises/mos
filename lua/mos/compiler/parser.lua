Mos.Compiler.Parser = Mos.Compiler.Parser or {}
local Parser = Mos.Compiler.Parser

include( "mos/compiler/lexer.lua" )

--------------------------------------------------
-- Parser API

function Parser:Create()
    local parser = {}

    return setmetatable( parser, self )
end

--------------------------------------------------
-- Parser metamethods
