local Ast = Mos.Assembler.Ast

--[[
    @class Leaf
    @desc The standard leaf for assembling an Ast
]]
Ast.Leaf = Ast.Leaf or {}
local Leaf = Ast.Leaf

Leaf.__index = Leaf

--[[
    @name Leaf.Create()
    @desc Creates a new leaf object

    @param string type: The type of the leaf
    @param Leaf value: Another leaf type to be visted
]]
function Leaf.Create( token )
    local leaf = {}
    leaf._type = token.type
    leaf._value = token.value
    leaf._line = token.line
    leaf._char = token.char

    return setmetatable( leaf, Leaf )
end

function Leaf:__tostring()
    return string.format( "%sLeaf( %s )", self.type, self.value )
end

--[[
    @name Ast:leaf()
    @desc Creates a new leaf object
    
    @param string type: The type of the leaf
    @param Leaf value: Another leaf type to be visted
]]
function Ast:leaf( type )
    return Leaf.Create( type )
end
