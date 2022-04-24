Mos.Assembler.Compiler.directives = Mos.Assembler.Compiler.directives or {}
local directives = Mos.Assembler.Compiler.directives

function directives:db( arguments )
    for _, arg in ipairs( arguments ) do
        local t = arg.type

        if t == "String" then
            self.file:Write( arg.value )
        elseif t == "Number" then
            self:Write( arg.value )
        elseif t == "Identifier" then
            -- TODO: Preprocessor identifiers
            self:Write( 0 )
        end
    end
end
