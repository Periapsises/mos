Mos.Assembler.Tree = Mos.Assembler.Tree or {}
local Tree = Mos.Assembler.Tree

Tree.__index = Tree

function Tree.Create()
    local tree = {}

    return setmetatable( tree, Tree )
end

function Tree.Node( name )
    local node = {
        _name = name,
        _type = "Node"
    }

    return setmetatable( node, Tree )
end

function Tree.List( name )
    local list = {
        _name = name,
        _type = "List",
        _value = {}
    }

    return setmetatable( list, Tree )
end

local tblMeta = {}

function tblMeta.__index( self, key )
    return rawget( self, "_value" )[key] or Tree[key]
end

function tblMeta.__newindex( self, key, value )
    rawget( self, "_value" )[key] = value
end

function Tree.Table( name, refToken )
    local tbl = {
        _name = name,
        _type = "Table",
        _value = {},
        _line = refToken.line,
        _char = refToken.char
    }

    return setmetatable( tbl, tblMeta )
end

function Tree.Leaf( token )
    local leaf = {
        _name = token.type,
        _type = "Leaf",
        _value = token.value,
        _line = token.line,
        _char = token.char
    }

    return setmetatable( leaf, Tree )
end

--------------------------------------------------
-- Metamethods

function Tree:attach( node )
    if self.value then
        error( "A node is already attached" )
    end

    self._line = node._line
    self._char = node._char
end

function Tree:append( node )
    if node._type ~= "List" then
        error( "Cannot append a node to a " .. node._type )
    end

    if table.insert( self, node ) == 1 then
        self._line = node._line
        self._char = node._char
    end
end
