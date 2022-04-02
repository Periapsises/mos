local parser = {}
Mos.parser = parser

local tokenization = {}

local prepStart     = "preprocessor.start"
local prepDirective = "preprocessor.directive"
local prepComment   = "preprocessor.comment"
local prepShort     = "preprocessor.shortcut"

local newline    = "operator.newline"
local whitespace = "operator.whitespace"
local colon      = "operator.colon"
local comma      = "operator.comma"
local lparen     = "operator.paren.left"
local rparen     = "operator.paren.right"
local hash       = "operator.hash"

local lquote = "string.start"
local rquote = "string.end"
local text   = "string.text"
local escape = "string.escape"

local number = "number"

local label       = "identifier.label"
local instruction = "identifier.instruction"
local name        = "identifier.name"

tokenization[1] = {
    ["^\n"]             = {type = newline, extra = false},
    ["^ +"]             = {type = whitespace},
    ["^:"]              = {type = colon, func = function( token, tokens )
        if not tokens:get( 0, instruction ) then return end
        tokens:get( 0 ).type = label
    end},
    ["^[_%a][_%w]*"]    = {type = instruction, extra = true, func = function( token, tokens )
        if not tokens.extra then return end
        token.type = name
    end},
    ["^%d+"]            = {type = number},
    ["^0[bdhxBDHX]%d+"] = {type = number, func = function( token, tokens ) token.format = token.value[2] end},
    ["^,"]              = {type = comma},
    ["^[%(]"]           = {type = lparen},
    ["^[%)]"]           = {type = rparen},
    ["^%.%a+"]          = {type = prepShort},
    ["^#%a+"]           = {type = prepStart, extra = true, func = function(token, tokens)
        if not tokens.extra then
            tokens:insert( {type = prepStart, value = "#"} )
            tokens:insert( {type = prepDirective, value = string.sub( token.value, 2 )} )
        else
            tokens:insert( {type = hash, value = "#"} )
            tokens:insert( {type = name, value = string.sub( token.value, 2 )} )
        end

        return true
    end},
    ["^\""]             = {type = lquote, state = 2},
    ["^'"]              = {type = lquote, state = 3},
    ["^//"]             = {type = prepComment, state = 4},
    ["^/%*"]            = {type = prepComment, state = 5}
}

tokenization[2] = {
    ["^[^\"\n\\]+"] = {type = text},
    ["^\\."] = {type = escape},
    ["^\""] = {type = rquote, state = 1},
    ["^\n"] = {type = newline, state = 1}
}

tokenization[3] = {
    ["^[^\\'\n]+"] = {type = text},
    ["^\\."] = {type = escape},
    ["^'"] = {type = rquote, state = 1},
    ["^\n"] = {type = newline, state = 1}
}

tokenization[4] = {
    ["^\n"] = {type = newline, state = 1},
    ["^[^\n ]+"] = {type = prepComment},
    ["^ +"] = {type = whitespace}
}

tokenization[5] = {
    ["^\n"] = {type = newline},
    -- Can't match more than 1 character at the time, otherwise the parser misses the end of comment (*/)
    -- Instead we use a function that tries to add characters to the pervious token if it is a comment
    ["^[^\n ]"] = {type = prepComment, func = function( token, tokens )
        local comment = tokens:get( 0, prepComment )
        if not comment then return end

        comment.value = comment.value .. token.value
        return true
    end},
    ["^%*/"] = {type = prepComment, state = 1},
    ["^ +"] = {type = whitespace}
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

parser.tokenTypes = {
    preprocessor = prepStart,
    directive = prepDirective,
    shortcut = prepShort,
    comment = prepComment,
    newline = newline,
    whitespace = whitespace,
    colon = colon,
    comma = comma,
    lparen = lparen,
    rparen = rparen,
    hash = hash,
    lquote = lquote,
    rquote = rquote,
    text = text,
    escape = escape,
    number = number,
    label = label,
    instruction = instruction,
    name = name
}
