local Ast = Mos.Assembler.Ast

--[[
    @class Table
    @desc Like a list but stored with keys
]]
Ast.Table = Ast.Table or {}
local Table = Ast.Table

Table.__index = Table
setmetatable( Table, Ast )

--[[
    @name Table.Create()
    @desc Creates a new table object
]]
function Table.Create()
    local tbl = {}
    tbl._type = "Table"
    tbl._value = {}

    return setmetatable( tbl, Table )
end

function Table:__newindex( key, value )
    self._value[key] = value
end

function Table:__tostring()
    return string.format( "%sTable( %s )", self.type, self.value )
end

--[[
    @name Ast:table()
    @desc Creates a new table object
]]
function Ast:table()
    local tbl = Table.Create()
    self:_parent( tbl )

    return tbl
end
