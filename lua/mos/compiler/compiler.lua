Mos.Compiler = Mos.Compiler or {}
local Compiler = Mos.Compiler

include( "mos/compiler/instructions.lua" )
include( "mos/compiler/parser.lua" )

--------------------------------------------------
-- Compiler API

function Compiler:Compile()
    local activeTab = self:GetActiveTab()
    if not activeTab then return end

    local code = Mos.FileSystem:Read( activeTab.file )
    local parser = self.Parser:Create( code )

    local success, ast = pcall( parser.Parser, parser )

    if not success then
        print( ast )
    end
end

--------------------------------------------------
-- Editor interactions

local function addCompilerOptions( editor )
    local runButton = vgui.Create( "MosEditor_HeaderButton", editor.header )
    runButton:SetName( "Run" )
    runButton:Dock( LEFT )

    function runButton:BuildMenu( menu )
        menu:AddOption( "Compile", function()
            Compiler:Compile()
        end )
    end
end

hook.Add( "MosEditor_CreateEditor", "MosCompiler_AddCompilerOptions", addCompilerOptions )
