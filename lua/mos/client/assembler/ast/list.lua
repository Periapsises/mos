local Ast = Mos.Assembler.Ast

--[[
    @class List
    @desc Like a node, but holds a list of sub nodes instead
]]
Ast.List = Ast.List or {}
local List = Ast.List

List.__index = List
setmetatable( List, Ast )

--[[
    @name List.Create()
    @desc Creates a new list object
]]
function List.Create()
    local list = {}
    list._type = "list"
    list._value = {}

    return setmetatable( list, List )
end

--[[
    @name List:append()
    @desc Appends a child to the list

    @param Node child: The child to append
]]
function List:append( child )
    table.insert( self._value, child )
end

-- Override of Ast's parent method
function List:_parent( node )
    self:append( node )
end

function List:__tostring()
    return string.format( "%sList( %s )", self.type, self.value )
end

--[[
    @name Ast:list()
    @desc Creates a new list object
]]
function Ast:list()
    local list = List.Create()
    self:_parent( list )

    return list
end
