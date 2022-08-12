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

function Token:prettyPrint( spacing, key )
    spacing = spacing or ""
    key = key and key .. " = " or ""

    print( spacing .. key .. "Token( " .. self._type .. ", " .. self._value .. ", " .. self._line .. ":" .. self._char .. " )" )
end

return Token
