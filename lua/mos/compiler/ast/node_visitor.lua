Mos.Compiler.NodeVisitor = Mos.Compiler.NodeVisitor or {}
local NodeVisitor = Mos.Compiler.NodeVisitor

NodeVisitor.__index = NodeVisitor

function NodeVisitor:Visit( node )
    if not node then error( "Trying to visit a nil value", 2 ) end

    local nodeType = node.type or ""
    local visitor = self["Visit" .. nodeType]

    if not visitor then
        self:GenericVisit( node )
        return
    end

    return visitor( self, node.value, node )
end

function NodeVisitor:GenericVisit( node )
    error( "No visitor for " .. node.type, 3 )
end
