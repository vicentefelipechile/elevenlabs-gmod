--[[----------------------------------------------------------------------------
                        Elevenlabs Client-side Script
----------------------------------------------------------------------------]]--

CreateClientConVar("openai_elevenlabs_voice", "josh", true, true, "What voice response the elevenlabs module?")

--[[------------------------
        Main Functions
------------------------]]--

local g_sound
function Elevenlabs.PlaySound(ply, path)
    sound.PlayFile("data/" .. path, "3d noplay", function(channel, errID, errStr)
        
    end)
end


local g_file = {}
function Elevenlabs.ReceiveData()
    local IsOnePart = net.ReadBool()
    local FileID = net.ReadString()
    local ply = net.ReadEntity()

    if not IsValid(ply) then
        ply = LocalPlayer()
    end

    if IsOnePart then
        local FileSize = net.ReadUInt(16)
        local FileContent = util.Decompress( net.ReadData(FileSize) )

        g_file[FileID] = FileContent

        local FilePath = Elevenlabs.SetFileName("voice")
        file.Write(FilePath, FileContent)

        Elevenlabs.PlaySound(ply, FilePath)
        return
    end

    local FileCurrentPart = net.ReadUInt(4)
    local FileLastPart = net.ReadUInt(4)

    if FileCurrentPart == FileLastPart then
        local FileSize = net.ReadUInt(16)
        local FileData = net.ReadData(FileSize)

        g_file[FileID] = g_file[FileID] .. FileData

        local FileContent = util.Decompress( g_file[FileID] )

        local FilePath = Elevenlabs.SetFileName("voice")
        file.Write(FilePath, FileContent)

        Elevenlabs.PlaySound(ply, FilePath)
        return
    end

    local FileSize = net.ReadUInt(16)
    local FileData = net.ReadData(FileSize)

    g_file[FileID] = g_file[FileID] and g_file[FileID] .. FileData or FileData
end

net.Receive("Elevenlabs.SVtoCL", Elevenlabs.ReceiveData)