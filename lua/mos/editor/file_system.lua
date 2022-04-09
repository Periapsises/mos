Mos.FileSystem = Mos.FileSystem or {}
local FileSystem = Mos.FileSystem

include( "mos/editor/file_functions/files.lua" )
include( "mos/editor/file_functions/folders.lua" )

--------------------------------------------------
-- FileSystem API

-- Taken from https://wiki.facepunch.com/gmod/file.Write
FileSystem.allowedExtensions = {".txt", ".dat", ".json", ".xml", ".csv", ".jpg", ".jpeg", ".png", ".vtf", ".vmt", ".mp3", ".wav", ".ogg"}

--[[
    @name FileSystem:Verify()
    @desc Ensures all default folders and files exist
]]
function FileSystem:Verify()
    file.CreateDir( "mos6502/" )
    file.CreateDir( "mos6502/asm/" )
    file.CreateDir( "mos6502/bin/" )

    if not self:Exists( "mos6502/asm/default.asm" ) then
        self:Write( "mos6502/asm/default.asm", "/*\n    Mos6502 Assembly Editor\n*/\n" )
    end
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

--[[
    @name FileSystem:GetSanitizedPath( path )
    @desc Returns a path with a valid extension

    @param string path - The path to sanitize

    @return string - The sanitized path
]]
function FileSystem:GetSanitizedPath( path )
    if self:HasAllowedExtension( path ) then return path end

    return path .. "~.txt"
end

--[[
    @name FileSystem:GetDirtyPath( path )
    @desc Gets rid of extra extensions required for validity

    @param string path - The path to make dirty

    @return string - The dirty path
]]
function FileSystem:GetDirtyPath( path )
    return string.match( path, "^([^~]+)" )
end

--[[
    @name FileSystem:Write( path, data )
    @desc Checks if a file exists in the DATA folder just like file.Exists() would but ensures the path is sanitized

    @param string path - The path to the file
]]
function FileSystem:Exists( path )
    path = self:GetSanitizedPath( path )

    return file.Exists( path, "DATA" )
end

--[[
    @name FileSystem:Write( path, data )
    @desc Writes a file in the DATA folder just like file.Write() would but ensures the path is sanitized

    @param string path - The path to write the file to
    @param string data - The data to write in the file
]]
function FileSystem:Write( path, data )
    path = self:GetSanitizedPath( path )

    return file.Write( path, data )
end

--[[
    @name FileSystem:Read( path )
    @desc Reads a file in the DATA folder just like file.Read() would but ensures the path is sanitized

    @param string path - The path to read the file from
]]
function FileSystem:Read( path, data )
    path = self:GetSanitizedPath( path )

    return file.Read( path, "DATA" )
end

--------------------------------------------------
-- File browser

local FILEBROWSER = {}

function FILEBROWSER:Init()

end

vgui.Register( "MosEditor_FileBrowser", FILEBROWSER, "DTree" )

FileSystem:Verify()
