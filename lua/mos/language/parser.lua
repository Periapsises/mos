local parser = {}
Mos.parser = parser

local tokenization = {}

tokenization[1] = {
    ["^\n"]             = {type = "newline", extra = false},
    ["^ +"]             = {type = "whitespace"},
    ["^:"]              = {type = "colon", func = function( token, tokens )
        if not tokens:get( 0, "instruction" ) then return end
        tokens:get( 0 ).type = "label"
    end},
    ["^[_%a][_%w]*"]    = {type = "instruction", extra = true, func = function( token, tokens )
        if not tokens.extra then return end
        token.type = "identifier"
    end},
    ["^%d+"]            = {type = "number"},
    ["^0[bdhxBDHX]%d+"] = {type = "number", func = function( token, tokens ) token.format = token.value[2] end},
    ["^,"]              = {type = "comma"},
    ["^[%(%)]"]         = {type = "paren"},
    ["^%.%a+"]          = {type = "directive"},
    ["^#%a+"]           = {type = "preprocessor", extra = true, func = function(token, tokens)
        if not tokens.extra then return end

        tokens:insert( {type = "hash", value = "#"} )
        tokens:insert( {type = "identifier", value = string.sub( token.value, 2 )} )
        return true
    end},
    ["^\""]             = {type = "string.start", state = 2},
    ["^'"]              = {type = "string.start", state = 3},
    ["^//"]             = {type = "comment", state = 4},
    ["^/%*"]            = {type = "comment", state = 5}
}

tokenization[2] = {
    ["^[^\\\"]+"] = {type = "string.text"},
    ["^\\."] = {type = "string.escape"},
    ["^\""] = {type = "string.end", state = 1}
}

tokenization[3] = {
    ["^[^\\']+"] = {type = "string.text"},
    ["^\\."] = {type = "string.escape"},
    ["^'"] = {type = "string.end", state = 1}
}

tokenization[4] = {
    ["^\n"] = {type = "newline", state = 1},
    ["^[^\n ]+"] = {type = "comment"},
    ["^ +"] = {type = "whitespace"}
}

tokenization[5] = {
    ["^\n"] = {type = "newline"},
    -- Can't match more than 1 character at the time, otherwise the parser misses the end of comment (*/)
    -- Instead we use a function that tries to add characters to the pervious token if it is a comment
    ["^[^\n ]"] = {type = "comment", func = function( token, tokens )
        local comment = tokens:get( 0, "comment" )
        if not comment then return end

        comment.value = comment.value .. token.value
        return true
    end},
    ["^%*/"] = {type = "comment", state = 1},
    ["^ +"] = {type = "whitespace"}
}

function parser:tokenize( text, startPos, endPos, callback )
    local tokens = {}
    tokens.list = {}

    function tokens:get( pos, type )
        local token = self.list[#self.list - pos]

        if not token or ( type and token.type ~= type ) then
            return
        end

        return token
    end

    function tokens:insert( token )
        table.insert( self.list, token )
    end

    local state = 1
    tokens.extra = false

    while text ~= "" do
        local patterns = tokenization[state]
        local match, data = "", ""

        for pattern, _data in pairs( patterns ) do
            local possibility = string.match( text, pattern ) or ""

            if string.len( possibility ) > string.len( match ) then
                match = possibility
                data = _data
            end
        end

        if match == "" then
            match = text[1]
            data = {type = "unknown"}
        end

        local token = {type = data.type, value = match}

        if not data.func or ( data.func and not data.func( token, tokens ) ) then
            tokens:insert( token )
        end

        state = data.state or state

        if data.extra ~= nil then
            tokens.extra = data.extra
        end

        text = string.sub( text, string.len( token.value ) + 1 )
    end

    return tokens.list
end

function parser:validate( tokens )

end
