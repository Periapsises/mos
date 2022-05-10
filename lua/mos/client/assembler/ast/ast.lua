Mos.Assembler.Ast = Mos.Assembler.Ast or {}
local Ast = Mos.Assembler.Ast

Ast.__index = Ast

-- Default function to attach a node. Can be overwriten for custom behavior
function Ast:_parent( node )
    self._value = node
end

include( "mos/client/assembler/ast/node.lua" )
include( "mos/client/assembler/ast/list.lua" )
include( "mos/client/assembler/ast/table.lua" )
include( "mos/client/assembler/ast/leaf.lua" )
