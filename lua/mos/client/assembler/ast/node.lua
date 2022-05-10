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
function Node.Create( type )
    local node = {}
    node._type = type

    return setmetatable( node, Node )
end

--[[
    @name Node:attach()
    @desc Attaches a node to this one

    @param Node node the node to attach
]]
function Node:attach( node )
    self._value = node
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
function Ast:node( type )
    return Node.Create( type )
end
