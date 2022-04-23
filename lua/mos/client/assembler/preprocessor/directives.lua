Mos.Assembler.Preprocessor.directives = Mos.Assembler.Preprocessor.directives or {}
local directives = Mos.Assembler.Preprocessor.directives

function directives:db( arguments )
    local size = 0

    for _, arg in ipairs( arguments ) do
        local t = arg.type

        if t == "String" then
            size = size + string.len( self:Visit( arg ) )
        elseif t == "Number" then
            size = size + ( self:Visit( arg ) > 0xff and 2 or 1 )
        elseif t == "Identifier" then
            -- TODO: Are identifiers two bytes? (16 bit addresses?)
            size = size + 1
        else
            -- TODO: Properly throw errors
            error( "Argument of type '" .. t .. "' is not supported for .db directive" )
        end
    end

    self.address = self.address + size
end

function directives:define( arguments )
    local definition = tostring( arguments[1].value )

    self.definitions[definition] = arguments[2] or ""
end
