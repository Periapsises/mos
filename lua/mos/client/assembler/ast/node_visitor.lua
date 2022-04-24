Mos.Assembler.NodeVisitor = Mos.Assembler.NodeVisitor or {}
local NodeVisitor = Mos.Assembler.NodeVisitor

NodeVisitor.__index = NodeVisitor

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

function NodeVisitor:genericVisit( node )
    error( "No visitor for " .. node.type, 3 )
end
