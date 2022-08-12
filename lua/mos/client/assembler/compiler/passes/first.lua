local instructions = Mos.Assembler.Instructions

--[[
    @class FirstPass
    @desc The first pass performed by the compiler.
    @desc Locates and stores all labels
]]
local Pass = Mos.Assembler.Visitor.Create()
Pass.__index = Pass
Mos.Assembler.Compiler.passes[1] = Pass

--[[
    @name FirstPass.Perform()
    @desc Passes over the ast and stores all labels

    @param AST ast: The ast to pass over

    @return Table: The labels discovered
]]
function Pass.Perform( ast )
    local pass = setmetatable( {}, Pass )

    pass.address = 0
    pass.labels = {}
    pass.isFirstPass = true

    pass:visit( ast )

    return pass.labels
end

--[[
    Visitor methods for the pass.
    They are called automatically with the Pass:visit() method
]]
function Pass:visitLabel( node )
    local name = node.LABEL:getText()

    if self.labels[name] then
        error( "Label '" .. name .. "' already exists at line " .. self.labels[label._value].line )
    end

    print( "Defining label " .. name )
    self.labels[name] = {
        line = node.LABEL._line,
        address = self.address
    }
end

function Pass:visitInstruction( node )
    local name = string.lower( node.NAME:getText() )
    local data = instructions.bytecodes[name]

    if not data then
        error( "Invalid instruction " .. name .. " at line " .. node.line )
    end

    local mode = node.operand.MODE:getText()
    local id = instructions.modeLookup[mode]

    if not data[id] then
        error( "Invalid addressing mode for " .. name .. ", '" .. mode .. "' not supported" )
    end

    self.address = self.address + instructions.modeByteSize[mode] + 1
end
