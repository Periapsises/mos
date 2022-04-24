Mos.Assembler.Compiler.directives = Mos.Assembler.Compiler.directives or {}
local directives = Mos.Assembler.Compiler.directives

function directives:db( arguments )
    for _, arg in ipairs( arguments ) do
        local t = arg.type

        if t == "String" then
            self.address = self.address + string.len( arg.value )

            if self.isFirstPass then return end
            self.compiler.file:Write( arg.value )
        elseif t == "Number" then
            self.address = self.address + 1

            if self.isFirstPass then return end
            self.compiler:write( arg.value )
        elseif t == "Identifier" then
            if self.isFirstPass then return end
            -- TODO: Preprocessor identifiers
            error( "Not implemented" )
        end
    end
end
