--[[----------------------------------------------------------------------------
                        Elevenlabs Client-side Script
----------------------------------------------------------------------------]]--

CreateClientConVar("elevenlabs_voice", "josh", true, true, "What voice response the elevenlabs module?")
CreateClientConVar("elevenlabs_download", 1, true, true, "Toggle to download voice files", 0, 1)

--[[------------------------
        Main Functions
------------------------]]--

function Elevenlabs.Request(msg)

    if msg:len() >= Elevenlabs.Config.maxtext:GetInt() then
        msg:sub(1,40)
    end

    net.Start("Elevenlabs.Command")
        net.WriteString(msg)
    net.SendToServer()

end

local g_sound
function Elevenlabs.PlaySound(ply, path)
    sound.PlayFile("data/" .. path, "3d noplay", function(channel, errID, errStr)
        local soundID = os.time()
        g_sound = nil

        if IsValid(channel) then
            g_sound = channel
            g_sound:Play()

            hook.Add("Think", "elevenlabs_" .. soundID, function()
                g_sound:SetPos( ply:GetPos() )

                if g_sound:GetState() == GMOD_CHANNEL_STOPPED then
                    hook.Remove("Think", "elevenlabs_" .. soundID)
                end
            end)
        end
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


--[[------------------------
           Command
------------------------]]--

concommand.Add("elevenlabs_makerequest", function(_, _, _, msg)
    Elevenlabs.Request(msg)
end)

--[[------------------------
           Network
------------------------]]--

net.Receive("Elevenlabs.SVtoCL", Elevenlabs.ReceiveData)