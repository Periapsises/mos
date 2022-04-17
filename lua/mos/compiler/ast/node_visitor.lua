local NodeVisitor = {}

function NodeVisitor:Create()
    local nodeVisitor = {}

    return setmetatable( nodeVisitor, self )
end

function NodeVisitor:Visit( node )
    if not node then self:Fatal() end

    local nodeType = node.type or ""
    local visitor = self["Visit" .. nodeType]

    if not visitor then
        self:GenericVisit( node )
        return
    end

    visitor( self, node.value )
end

function NodeVisitor:GenericVisit( node )
    error( "No visitor for " .. node.type )
end
