--[[
    @class Ast
    @desc The base for building an AST
]]
Mos.Assembler.Ast = Mos.Assembler.Ast or {}
local Ast = Mos.Assembler.Ast

Ast.__index = Ast

-- Default function to attach a node. Can be overwriten for custom behavior
function Ast:_parent( node )
    self._value = node
end

--[[
    @name Ast:visit()
    @desc Attempts to aall a visitor function based on the node type passed

    @param Node node: The node to visit
    @param any ...: Additional arguments to pass to the visitor function

    @return any: The return values from the visitor
]]
function Ast:visit( node, ... )
    if not node then error( "Trying to visit a nil value", 2 ) end

    if node._visitor then
        return node:_visitor( ... )
    end

    local nodeType = string.gsub( node._type or "", ",", "")
    local visitor = self["visit" .. nodeType]

    if not visitor then
        error( "No visitor for " .. node._type, 2 )
        return
    end

    return visitor( self, node._value, node, ... )
end

--[[
    @name Ast:visitList()
    @desc Default visitor for lists. Visits all nodes in the list.
    @desc Passes the list node as the first argument followed by the index and any extra arguments from the caller.
]]
function Ast:visitList( list, node, ... )
    for index, value in ipairs( list ) do
        self:visit( value, node, index, ... )
    end
end

include( "mos/client/assembler/ast/node.lua" )
include( "mos/client/assembler/ast/list.lua" )
include( "mos/client/assembler/ast/table.lua" )
include( "mos/client/assembler/ast/leaf.lua" )
