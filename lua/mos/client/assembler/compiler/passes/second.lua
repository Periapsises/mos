local instructions = Mos.Assembler.Instructions
local directives = Mos.Assembler.Compiler.directives

--[[
    @class SecondPass
    @desc The second pass performed by the compiler.
    @desc Compiles the AST into binary and writes it to the output
]]
Mos.Assembler.Compiler.passes[2] = Mos.Assembler.Compiler.passes[2] or {}
local Pass = Mos.Assembler.Compiler.passes[2]

Pass.__index = Pass
setmetatable( Pass, Mos.Assembler.NodeVisitor )

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

function Pass:visitProgram( statements )
    for _, statement in ipairs( statements ) do
        self:visit( statement )
    end
end

function Pass:visitLabel() end

function Pass:visitInstruction( instruction )
    local name = string.lower( instruction.instruction.value )
    local mode = instruction.operand.value.type
    local shortName = instructions.modeLookup[mode]

    self.compiler:write( instructions.bytecodes[name][shortName] )

    self:visit( instruction.operand )

    self.address = self.address + instructions.modeByteSize[mode] + 1
end

function Pass:visitAddressingMode( mode )
    if not mode.value then return end

    self:visit( mode )
end

function Pass:visitAccumulator() end
function Pass:visitImplied() end

function Pass:visitAbsolute( abs )
    local value = self:visit( abs )

    local hb = bit.rshift( bit.band( value, 0xff00 ), 8 )
    local lb = bit.band( value, 0xff )

    self.compiler:write( lb )
    self.compiler:write( hb )
end

Pass.visitAbsoluteX = Pass.visitAbsolute
Pass.visitAbsoluteY = Pass.visitAbsolute

function Pass:visitImmediate( imm )
    self.compiler:write( self:visit( imm ) )
end

function Pass:visitIndirect( ind )
    self.compiler:write( self:visit( ind ) )
end

function Pass:visitXIndirect( xind )
    self.compiler:write( self:visit( xind ) )
end

function Pass:visitIndirectY( indy )
    self.compiler:write( self:visit( indy ) )
end

function Pass:visitRelative( rel )
    local value = self:visit( rel )
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

function Pass:visitOperation( data )
    local op = data.operator.value
    local left = self:visit( data.left )
    local right = self:visit( data.right )

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

function Pass:visitNumber( num )
    return num
end

function Pass:visitIdentifier( id )
    if not self.labels[id] then
        error( "Label '" .. id .. "' does not exists" )
    end

    return self.labels[id].address
end

function Pass:visitDirective( directive )
    directives[directive.directive.value]( self, directive.arguments )
end
