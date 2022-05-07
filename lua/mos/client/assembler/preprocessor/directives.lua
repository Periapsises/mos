Mos.Assembler.Preprocessor.directives = Mos.Assembler.Preprocessor.directives or {}
local directives = Mos.Assembler.Preprocessor.directives

--------------------------------------------------
-- Callbacks for preprocessor

--[[
    @name discard( statements, index )
    @desc Helper function to discard a statement. Used as a callback for the preprocessor
    @param Table statements - The statements from which to discard one
    @param number index - The index of the statement to discard
    @return number - The index given
]]
local function discard( statements, index )
    table.remove( statements, index )

    return index
end

--[[
    @name insertStatements( statements, index, toInsert )
    @desc Helper function to insert statements. Used as a callback for the preprocessor
    @param Table statements - The statements to insert into
    @param number index - The index at which to insert the statements
    @param Table toInsert - The statements to insert
    @return number - The last index that was inserted to
]]
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
