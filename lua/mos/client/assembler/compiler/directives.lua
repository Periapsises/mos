Mos.Assembler.Compiler.directives = Mos.Assembler.Compiler.directives or {}
local directives = Mos.Assembler.Compiler.directives

function directives:db( arguments )
    for _, arg in ipairs( arguments ) do
        local t = arg.type

        if t == "String" then
            self.address = self.address + string.len( arg.value )

            if self.isSecondPass then
                self.compiler.file:Write( arg.value )
            end
        elseif t == "Number" then
            self.address = self.address + 1

            if self.isSecondPass then
                self.compiler:write( arg.value )
            end
        elseif t == "Identifier" then
            -- TODO: Preprocessor identifiers
            error( "Not implemented" )

            if self.isSecondPass then return end
        end
    end
end

function directives:dw( arguments )
    for _, arg in ipairs( arguments ) do
        if arg.type ~= "Number" then
            error( "Invalid argument for dw" )
        end

        self.address = self.address + 2

        if self.isSecondPass then
            local lo = bit.band( arg.value, 0xff )
            local hi = bit.band( bit.rshift( arg.value, 8 ), 0xff )

            self.compiler:write( lo )
            self.compiler:write( hi )
        end
    end
end

function directives:org( arguments )
    if not arguments[1] or arguments[1].type ~= "Number" then
        error( "Invalid argument for org" )
    end

    self.address = arguments[1].value

    if self.isFirstPass then return end

    self.compiler:endBlock()
    self.compiler:startBlock( self.address )
end
