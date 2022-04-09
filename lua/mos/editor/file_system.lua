Mos.FileSystem = Mos.FileSystem or {}
local FileSystem = Mos.FileSystem

include( "mos/editor/file_functions/files.lua" )
include( "mos/editor/file_functions/folders.lua" )

--------------------------------------------------
-- FileSystem API

FileSystem.dataPath = "mos6502/"
FileSystem.codePath = "asm/"
FileSystem.binPath = "bin/"

-- Taken from https://wiki.facepunch.com/gmod/file.Write
FileSystem.allowedExtensions = {".txt", ".dat", ".json", ".xml", ".csv", ".jpg", ".jpeg", ".png", ".vtf", ".vmt", ".mp3", ".wav", ".ogg"}

--[[
    @name FileSystem:Verify()
    @desc Ensures all default folders and files exist
]]
function FileSystem:Verify()
    file.CreateDir( self.dataPath )
    file.CreateDir( self.dataPath .. self.codePath )
    file.CreateDir( self.dataPath .. self.codePath )
end

--[[
    @name FileSystem:HasAllowedExtension( path )
    @desc Checks if a filepath ends with a valid extension

    @param string path - The filepath to check

    @return bool - Whether the extension is valid or not
]]
function FileSystem:HasAllowedExtension( path )
    for _, extension in ipairs( self.allowedExtensions ) do
        if string.EndsWith( path, extension ) then return true end
    end
end

--------------------------------------------------
-- File browser

local FILEBROWSER = {}

function FILEBROWSER:Init()

end

vgui.Register( "MosEditor_FileBrowser", FILEBROWSER, "DTree" )
