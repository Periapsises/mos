Mos.Compiler.Preprocessor = Mos.Compiler.Preprocessor or {}
local Preprocessor = Mos.Compiler.Preprocessor

setmetatable( Preprocessor, Mos.Compiler.NodeVisitor )

--------------------------------------------------
-- Preprocessor API

Preprocessor.__index = Preprocessor

function Preprocessor:Process( ast )
    local preprocessor = setmetatable( {}, self )
    preprocessor.address = 0
    preprocessor.labels = {}
    preprocessor:Visit( ast )

    return preprocessor
end

--------------------------------------------------
-- Visitor methods

function Preprocessor:VisitProgram( statements )
    for _, statement in ipairs( statements ) do
        self:Visit( statement )
    end
end

function Preprocessor:VisitLabel( name )
    if self.labels[name.value] then
        -- TODO: Properly throw errors
        error( "A label with name '" .. name .. "' already exists!" )
    end

    self.labels[name.value] = self.address
end

function Preprocessor:VisitInstruction( data )
    local byteCount = 1 + self:Visit( data.operand )

    self.address = self.address + byteCount
end

function Preprocessor:VisitAdressingMode( _, node )
    return Mos.Compiler.Instructions.modeByteSize[node.mode]
end

function Preprocessor:VisitDirective( data )
    self.directives[data.directive.value]( self, data.arguments )
end

function Preprocessor:VisitNumber( number, node )
    local format = number[2]
    local result = 0

    if format == "h" or format == "x" then
        result = tonumber( "0x" .. string.sub( number, 3 ) )
    elseif format == "b" then
        number = string.sub( number, 3 )
        local size = string.len( number )

        for i = 0, size - 1 do
            local b = tonumber( number[size - i] )

            if b > 1 then
                -- TODO: Properly throw errors
                error( "Invalid binary format 0b" .. number )
            end

            result = result + ( 2 ^ i ) * b
        end
    elseif format == "d" then
        result = tonumber( string.sub( number, 3 ) )
    else
        result = tonumber( number )
    end

    node.value = result
    return result
end

function Preprocessor:VisitString( str, node )
    node.value = string.gsub( string.sub( str, 2, -2 ), "\\([nt])", {n = "\n", t = "\t"} )
    return node.value
end

--------------------------------------------------
-- Directives

Preprocessor.directives = {}
local directives = Preprocessor.directives

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
