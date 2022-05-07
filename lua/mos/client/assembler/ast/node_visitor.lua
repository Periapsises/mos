--[[
    @class NodeVisitor
    @desc provides functions to traverse an AST
]]
Mos.Assembler.NodeVisitor = Mos.Assembler.NodeVisitor or {}
local NodeVisitor = Mos.Assembler.NodeVisitor

NodeVisitor.__index = NodeVisitor

--[[
    @name NodeVisitor:visit()
    @desc Attempts to aall a visitor function based on the node type passed

    @param Node node: The node to visit
    @param any ...: Additional arguments to pass to the visitor function

    @return any: The return values from the visitor
]]
function NodeVisitor:visit( node, ... )
    if not node then error( "Trying to visit a nil value", 2 ) end

    local nodeType = string.gsub( node.type or "", ",", "")
    local visitor = self["visit" .. nodeType]

    if not visitor then
        self:genericVisit( node )
        return
    end

    return visitor( self, node.value, node, ... )
end

--[[
    @name NodeVisitor:genericVisit( node )
    @desc If no visitor is found for a node type, it will default tho this method.
    @desc Throws an error with the missing visitor type

    @param Node node - The node to visit
]]
function NodeVisitor:genericVisit( node )
    error( "No visitor for " .. node.type, 3 )
end
