local Ast = Mos.Assembler.Ast

--[[
    @class Table
    @desc Like a list but stored with keys
]]
Ast.Table = Ast.Table or {}
local Table = Ast.Table

setmetatable( Table, Ast )

--[[
    @name Table.Create()
    @desc Creates a new table object
]]
function Table.Create( type, reference )
    if not reference then
        return error("No reference to create table", 2)
    end

    local tbl = {}
    tbl._type = type
    tbl._value = {}
    tbl._line = reference.line
    tbl._char = reference.char

    return setmetatable( tbl, Table )
end

function Table:_visitor( node, ... )
    for key, value in pairs( node._value ) do
        local visitorName = "visit" .. node._type .. key
        local visitor = self[visitorName]

        if not visitor then
            error( "No visitor for " .. node._type .. key, 3 )
            return
        end

        visitor( self, value, key, ... )
    end
end

function Table:__index( key )
    if Table[key] then
        return Table[key]
    end

    return rawget(self, "_value")[key]
end

function Table:__newindex( key, value )
    self._value[key] = value
end

function Table:__tostring()
    return string.format( "%sTable( %s )", self._type, self._value )
end

function Table:_parent() end

--[[
    @name Ast:table()
    @desc Creates a new table object
]]
function Ast:table( type, reference )
    local tbl = Table.Create( type, reference )
    self:_parent( tbl )

    return tbl
end
