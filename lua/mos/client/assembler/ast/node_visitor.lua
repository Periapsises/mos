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

    local nodeType = string.gsub( node._type or "", ",", "")
    local visitor = self["visit" .. nodeType]

    if not visitor then
        error( "No visitor for " .. node._type, 2 )
        return
    end

    return visitor( self, node._value, node, ... )
end

--[[
    @name NodeVisitor:visitList()
    @desc Default visitor for lists. Visits all nodes in the list.
    @desc Passes the index as the first argument followed by any extra arguments from the caller.
]]
function NodeVisitor:visitList( list, node, ... )
    for index, value in ipairs( list ) do
        self:visit( value, index, ... )
    end
end

--[[
    @name NodeVisitor:visitTable()
    @desc Visits all keys in a table node using the name of the key as the visit type.
    @desc Passes the key name as the first argument followed by extra arguments from the caller.
]]
function NodeVisitor:visitTable( node, tbl, ... )
    for key, value in pairs( tbl ) do
        local visitor = self["visit" .. key]

        if not visitor then
            error( "No visitor for " .. key, 2 )
            return
        end

        return visitor( self, value, node, key, ... )
    end
end
