local Ast = Mos.Assembler.Ast

--[[
    @class List
    @desc Like a node, but holds a list of sub nodes instead
]]
Ast.List = Ast.List or {}
local List = Ast.List

List.__index = List

--[[
    @name List.Create()
    @desc Creates a new list object
]]
function List.Create()
    local list = {}
    list._type = type
    list._value = {}

    return setmetatable( list, Node )
end

--[[
    @name List:append()
    @desc Appends a child to the list

    @param Node child: The child to append
]]
function List:append( child )
    table.insert( self._value, child )
end

function List:__tostring()
    return string.format( "%sList( %s )", self.type, self.value )
end

--[[
    @name Ast:list()
    @desc Creates a new list object
]]
function Ast:list()
    return List.Create()
end
