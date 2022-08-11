local Ast = {}
Mos.Assembler.Ast = Ast

local Node = include( "mos/client/assembler/ast/node.lua" )
local Token = include( "mos/client/assembler/ast/token.lua" )

Ast.__index = Ast

function Ast.Node( type )
    return Node.Create( type )
end

function Ast.Token( token )
    return Token.Create( token )
end
