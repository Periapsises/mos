local Ast = Mos.Assembler.Ast

--[[
    @class Node
    @desc The standard node for assembling an Ast
]]
Ast.Node = Ast.Node or {}
local Node = Ast.Node

Node.__index = Node

--[[
    @name Node.Create()
    @desc Creates a new node object

    @param string type: The type of the node
    @param Node value: Another node type to be visted
]]
function Node.Create( type, value )
    local node = {}
    node._type = type
    node._value = value

    return setmetatable( node, Node )
end

function Node:__tostring()
    return string.format( "%sNode( %s )", self.type, self.value )
end

--[[
    @name Ast:node()
    @desc Creates a new node object
    
    @param string type: The type of the node
    @param Node value: Another node type to be visted
]]
function Ast:node( type, value )
    return Node.Create( type, value )
end
