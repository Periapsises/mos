local Instructions = Mos.Assembler.Instructions

Mos.Assembler.Compiler.passes[1] = Mos.Assembler.Compiler.passes[1] or {}
local Pass = Mos.Assembler.Compiler.passes[1]

Pass.__index = Pass
setmetatable( Pass, Mos.Assembler.NodeVisitor )

function Pass.Perform( ast )
    local pass = setmetatable( {}, Pass )

    pass.address = 0
    pass.labels = {}

    pass:visit( ast )

    return pass.labels
end

function Pass:visitProgram( statements )
    for _, statement in ipairs( statements ) do
        self:visit( statement )
    end
end

function Pass:visitLabel( label )
    if self.labels[label.value] then
        error( "Label '" .. label.value .. "' already exists at line " .. self.labels[label.value].line )
    end

    self.labels[label.value] = {
        line = label.line,
        address = self.address
    }
end

function Pass:visitInstruction( instruction )
    local name = string.lower( instruction.instruction.value )
    local data = Instructions.bytecodes[name]

    if not data then
        error( "Invalid instruction " .. name .. " at line " .. instruction.line )
    end

    local mode = instruction.operand.value.type
    local id = Instructions.modeLookup[mode]

    if not data[id] then
        error( "Invalid addressing mode for " .. name .. ", '" .. mode .. "' not supported" )
    end

    self.address = self.address + Instructions.modeByteSize[mode] + 1
end
