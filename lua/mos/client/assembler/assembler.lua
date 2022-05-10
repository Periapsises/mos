--[[
    @class Assembler
    @desc Handles the entire process of compiling source code into binary executables
]]
Mos.Assembler = Mos.Assembler or {}
local Assembler = Mos.Assembler

include( "mos/client/assembler/ast/ast.lua" )
include( "mos/client/assembler/ast/node_visitor.lua" )
include( "mos/client/assembler/instructions.lua" )
include( "mos/client/assembler/parser.lua" )
include( "mos/client/assembler/preprocessor/preprocessor.lua" )
include( "mos/client/assembler/compiler/compiler.lua" )

--------------------------------------------------
-- Assembler API

Assembler.__index = Assembler

--[[
    @name Assembler.Assemble()
    @desc Create a new assembler object and initializes default values based on the currently open file

    @return Table: A generated assembly
]]
function Assembler.Assemble()
    local main = Assembler.GetActiveFile()
    if not main then error( "No file currently open" ) end

    local preprocessor = Assembler.Preprocessor.Create()
    local compiler = Assembler.Compiler.Create()

    local assembly = {
        main = main,
        files = {},
        preprocessor = preprocessor,
        compiler = compiler
    }

    setmetatable( assembly, Assembler )

    preprocessor.assembly = assembly
    compiler.assembly = assembly

    assembly.ast = preprocessor:process()
    compiler:compile()

    return assembly
end

--[[
    @name Assembler.GetActiveFile()
    @desc Returns the file opened in the editor

    @return string: The path to the file
]]
function Assembler.GetActiveFile()
    local activeTab = Mos.Editor:GetActiveTab()
    if not activeTab then return end

    return activeTab.file
end

--------------------------------------------------
-- Assembly metamethods

--[[
    @name Assembler:parseFile()
    @desc Fetches the contents of a file and parses them to produce an ast

    @param string path: The path of the file

    @return AST: The generated ast
]]
function Assembler:parseFile( path )
    if self.files[path] then return end

    local contents = Mos.FileSystem.Read( path )

    local parser = self.Parser.Create( contents )
    self.files[path] = parser:parse()

    return self.files[path]
end

--------------------------------------------------
-- Editor interactions

local function addAssemblerOptions( editor )
    local runButton = vgui.Create( "MosEditor_HeaderButton", editor.header )
    runButton:SetName( "Run" )
    runButton:Dock( LEFT )

    function runButton:BuildMenu( menu )
        menu:AddOption( "Assemble", Assembler.Assemble )
    end
end

hook.Add( "MosEditor_CreateEditor", "MosAssembler_AddCompilerOptions", addAssemblerOptions )
