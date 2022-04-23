Mos.Compiler.Preprocessor = Mos.Compiler.Preprocessor or {}
local Preprocessor = Mos.Compiler.Preprocessor

include( "mos/client/compiler/directives/preprocessor.lua" )

setmetatable( Preprocessor, Mos.Compiler.NodeVisitor )

--------------------------------------------------
-- Preprocessor API

Preprocessor.__index = Preprocessor

function Preprocessor.Create()
    local preprocessor = {}

    return setmetatable( preprocessor, Preprocessor )
end

function Preprocessor:process()
    local preprocessor = setmetatable( {}, self )
    preprocessor.address = 0
    preprocessor.labels = {}
    preprocessor.definitions = {
        ["SERVER"] = SERVER,
        ["CLIENT"] = CLIENT
    }
    preprocessor:visit( ast )

    return preprocessor
end

--------------------------------------------------
-- Visitor methods

function Preprocessor:visitProgram( statements )
    for _, statement in ipairs( statements ) do
        self:visit( statement )
    end
end

function Preprocessor:visitLabel( name )
    if self.labels[name.value] then
        -- TODO: Properly throw errors
        error( "A label with name '" .. name .. "' already exists!" )
    end

    self.labels[name.value] = self.address
end

function Preprocessor:visitInstruction( data )
    data.address = self.address
    local byteCount = 1 + self:visit( data.operand )

    self.address = self.address + byteCount
end

function Preprocessor:visitAdressingMode( mode )
    return Mos.Compiler.Instructions.modeByteSize[mode.type]
end

function Preprocessor:visitDirective( data )
    self.Directives[data.directive.value]( self, data.arguments, data.value )
end

function Preprocessor:visitNumber( number, node )
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

function Preprocessor:visitString( str, node )
    node.value = string.gsub( string.sub( str, 2, -2 ), "\\([nt])", {n = "\n", t = "\t"} )
    return node.value
end
