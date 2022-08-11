local Visitor = {}
Mos.Assembler.Visitor = Visitor

local Node = include( "mos/client/assembler/ast/node.lua" )
local Token = include( "mos/client/assembler/ast/token.lua" )

Visitor.__index = Visitor

function Visitor.Create()
    local visitor = {}

    return setmetatable( visitor, Visitor )
end

function Visitor:visit( node )
end

function Visitor:node( type )
    return Node.Create( type )
end

function Visitor:token( token )
    return Token.Create( token )
end
