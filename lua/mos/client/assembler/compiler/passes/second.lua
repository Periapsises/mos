local instructions = Mos.Assembler.Instructions

--[[
    @class SecondPass
    @desc The second pass performed by the compiler.
    @desc Compiles the AST into binary and writes it to the output
]]
Mos.Assembler.Compiler.passes[2] = Mos.Assembler.Compiler.passes[2] or {}
local Pass = Mos.Assembler.Compiler.passes[2]

Pass.__index = Pass
setmetatable( Pass, Mos.Assembler.Visitor )

--[[
    @name SecondPass.Perform()
    @desc Passes over the ast and compiles it to binary

    @param AST ast: The ast to pass over
    @param Table labels: The labels taken from the previous pass
    @param Compiler compiler: The compiler currently running
]]
function Pass.Perform( ast, labels, compiler )
    local pass = setmetatable( {}, Pass )

    pass.address = 0
    pass.labels = labels
    pass.compiler = compiler
    pass.isSecondPass = true

    pass:visit( ast )
end

--[[
    Visitor methods for the pass.
    They are called automatically with the Pass:visit() method
]]

function Pass:visitInstruction( node )
    local name = string.lower( node.NAME:getText() )
    local mode = node.operand.MODE:getText()
    local shortMode = instructions.modeLookup[mode]

    self.compiler:write( instructions.bytecodes[name][shortMode] )
    if node.operand.value then
        local value = self:visit( node.operand.value )

        if shortMode == "abs" or shortMode == "absx" or shortMode == "absy" then
            self:writeAbsolute( value )
        elseif shortMode == "rel" then
            self:writeRelative( value )
        else
            self.compiler:write( value )
        end
    end

    self.address = self.address + instructions.modeByteSize[mode] + 1
end

function Pass:writeAbsolute( value )
    local hb = bit.rshift( bit.band( value, 0xff00 ), 8 )
    local lb = bit.band( value, 0xff )

    self.compiler:write( lb )
    self.compiler:write( hb )
end

function Pass:writeRelative( value )
    local offset = value - ( self.address + 2 )

    if offset < -128 or offset > 127 then
        -- TODO: Properly throw errors
        error( "Unreachable address" )
    end

    --? Converts the offset into a signed 8 bit number
    if offset < 0 then
        offset = bit.bxor( 0xff, bit.bnot( offset ) )
    end

    self.compiler:write( offset )
end

function Pass:visitOperation( node )
    local op = node.OPERATOR:getText()
    local left = self:visit( node.left )
    local right = self:visit( node.right )

    if op == "+" then
        return left + right
    elseif op == "-" then
        return left - right
    elseif op == "*" then
        return left * right
    elseif op == "/" then
        return left / right
    end
end

function Pass:visitNumber( node )
    return tonumber( node.VALUE:getText() )
end

function Pass:visitIdentifier( node )
    local name = node.VALUE:getText()

    if not self.labels[name] then
        error( "Label '" .. name .. "' does not exist" )
    end

    return self.labels[name].address
end
