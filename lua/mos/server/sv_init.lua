--------------------------------------------------
-- Network strings

--? Server -> Client : Requests the client to open the editor
util.AddNetworkString( "mos_editor_open" )

--? Server -> Client : Requests the client to upload compiled code
util.AddNetworkString( "mos_code_request" )

--? Client -> Server : Client sending code over to the server
util.AddNetworkString( "mos_apply_code" )

--------------------------------------------------
-- Includes

include( "mos/server/transfer/transfer.lua" )
