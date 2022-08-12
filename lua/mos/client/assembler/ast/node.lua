local Node = {}
setmetatable( Node, Mos.Assembler.Visitor )

function Node.Create( type )
    local node = {
        _type = type,
        _children = {}
    }

    return setmetatable( node, Node )
end

function Node:insert( node )
    self._children[#self._children + 1] = node
end

function Node:__index( key )
    return self._children[key] or Node[key]
end

function Node:__newindex( key, value )
    self._children[key] = value
end

function Node:prettyPrint( spacing )
    spacing = spacing or ""

    print( spacing .. self._type )
    for name, node in pairs( self._children ) do
        print( spacing .. "  [" .. name .. "]" )
        node:prettyPrint( spacing .. "    " )
    end
end

return Node
