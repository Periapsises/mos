Mos.Assembler.Preprocessor.directives = Mos.Assembler.Preprocessor.directives or {}
local directives = Mos.Assembler.Preprocessor.directives

--------------------------------------------------
-- Callbacks for preprocessor

local function discard( statements, index )
    table.remove( statements, index )

    return index
end

local function insertStatements( statements, index, toInsert )
    table.remove( statements, index )

    for _, statement in ipairs( toInsert ) do
        table.insert( statements, index, statement )
        index = index + 1
    end

    return index
end

--------------------------------------------------
-- Directives

function directives:db( arguments )
    for _, arg in ipairs( arguments ) do
        self:visit( arg )
    end
end

function directives:define( arguments )
    local definition = tostring( arguments[1].value )

    if not arguments[2] then
        self.definitions[definition] = {type = "Bool", value = true}
    end

    self:visit( arguments[2] )
    self.definitions[definition] = {type = "Definition", value = arguments[2]}

    return discard
end

function directives:ifdef( arguments, value )
    local definition = tostring( arguments[1].value )
    if not self.definitions[definition] then return discard end

    if self.definitions[definition].type == "Bool" then
        if self.definitions[definition].value then
            return insertStatements, value.default
        else
            return insertStatements, value.fallback
        end
    end
end

function directives:ifndef( arguments, value )
    local definition = tostring( arguments[1].value )
    if not self.definitions[definition] then return discard end

    if self.definitions[definition].type == "Bool" then
        if self.definitions[definition].value then
            return insertStatements, value.fallback
        else
            return insertStatements, value.default
        end
    end
end
