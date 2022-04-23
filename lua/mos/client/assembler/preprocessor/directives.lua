Mos.Assembler.Preprocessor.directives = Mos.Assembler.Preprocessor.directives or {}
local directives = Mos.Assembler.Preprocessor.directives

function directives:db( arguments )
    for _, arg in ipairs( arguments ) do
        self:visit( arg )
    end
end

function directives:define( arguments )
    local definition = tostring( arguments[1].value )

    if not arguments[2] then
        self.definitions[definition] = {type = "Bool", value = true}
    end

    self:visit( arguments[2] )
    self.definitions[definition] = {type = "Definition", value = arguments[2]}

    return true
end

function directives:ifdef( arguments, value )
    local definition = tostring( arguments[1].value )
    if not self.definitions[definition] then return true end

    if self.definitions[definition].type == "Bool" and not self.definitions[definition].value then return true end

    for _, statement in ipairs( value ) do
        self:visit( statement )
    end
end

function directives:endif() end
