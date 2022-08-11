local Token = {}
Token.__index = Token
setmetatable( Token, Mos.Assembler.Visitor )

function Token.Create( tokenInfo )
    local token = {
        _type = tokenInfo.type,
        _value = tokenInfo.value,
        _line = tokenInfo.line,
        _char = tokenInfo.char
    }

    return setmetatable( token, Token )
end

function Token:getType()
    return self._type
end

function Token:getText()
    return self._value
end

return Token
