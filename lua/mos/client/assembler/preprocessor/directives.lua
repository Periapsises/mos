Mos.Assembler.Preprocessor.directives = Mos.Assembler.Preprocessor.directives or {}
local directives = Mos.Assembler.Preprocessor.directives

--------------------------------------------------
-- Callbacks for preprocessor

-- Discards a statement at the given index
local function discard( statements, index )
    table.remove( statements, index )

    return index
end

-- Inserts a list of statements at a given index
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

--- directive: db
-- [byte | word | string]+
-- Define bytes: Adds raw bytes at the current address in the order given.
function directives:db( arguments )
    for _, arg in ipairs( arguments ) do
        self:visit( arg )
    end
end

--- directive: dw
-- [byte | word]+
-- Define words: Adds raw words at the current address in the order given.
-- Unlike 'Define bytes', the bytes will be added in little-endian mode.
function directives:dw( arguments )
    for _, arg in ipairs( arguments ) do
        self:visit( arg )
    end
end

--- directive: org
-- [byte | word]
-- Changes the address at which the following code will be located
function directives:org( arguments )
    for _, arg in ipairs( arguments ) do
        self:visit( arg )
    end
end

--- directive: define
-- [identifier], [expression]?
-- Defines an identifier in the preprocessor
-- If an expression is specified, the value of the identifier will equal its result
function directives:define( arguments )
    local definition = tostring( arguments[1].value )

    if not arguments[2] then
        self.definitions[definition] = {type = "Bool", value = true}
    end

    self:visit( arguments[2] )
    self.definitions[definition] = {type = "Definition", value = arguments[2]}

    return discard
end

--- directive: ifdef
-- [expression]
-- Evaluates if the given expression is true
-- If not, the following code will be ignored up to the closing #endif
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

--- directive: ifndef
-- [expression]
-- Evaluates if the given expression is false
-- If not, the following code will be ignored up to the closing #endif
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

--- directive: endif
-- Ends a segment of code started with either #ifdef or #ifndef
function directives:endif() end
