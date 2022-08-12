local Visitor = {}
Mos.Assembler.Visitor = Visitor

Visitor.__index = Visitor

function Visitor.Create()
    local visitor = {}

    return setmetatable( visitor, Visitor )
end

function Visitor:visit( node )
    if not node then error( "Cannot visit a nil value", 2 ) end
    if not node._children then
        if not node._type then error( "Visitor can only visit nodes and tokens" ) end
        return
    end

    local visitorName = "visit" .. node._type
    local visitor = self[visitorName] or self.visitChildren

    return visitor( self, node )
end

function Visitor:visitChildren( node )
    for _, child in pairs( node._children ) do
        self:visit( child )
    end
end
