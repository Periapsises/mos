Mos.Assembler = Mos.Assembler or {}
local Assembler = Mos.Assembler

include( "mos/client/assembler/preprocessor/preprocessor.lua" )
include( "mos/client/assembler/compiler/compiler.lua" )

--------------------------------------------------
-- Assembler API

Assembler.__index = Assembler

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

    preprocessor.assembly = assembly
    compiler.assembly = assembly

    preprocessor:process()

    return setmetatable( assembly, Assembler )
end

function Assembler.GetActiveFile()
    local activeTab = Mos.Editor:GetActiveTab()
    if not activeTab then return end

    return activeTab.file
end

--------------------------------------------------
-- Assembly metamethods

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
