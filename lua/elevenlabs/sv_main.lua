--[[----------------------------------------------------------------------------
                        Elevenlabs Server-side Script
----------------------------------------------------------------------------]]--

util.AddNetworkString("Elevenlabs.SVtoCL")
Elevenlabs.Cache = {}

--[[------------------------
      Local Definitions
------------------------]]--

local FileMaxSize = 63000
local voices = {
    ["rachel"]  = "21m00Tcm4TlvDq8ikWAM",
    ["doni"]    = "AZnzlk1XvdvUeBnXmlld",
    ["bella"]   = "EXAVITQu4vr4xnSDxMaL",
    ["antoni"]  = "ErXwobaYiN019PkySvjV",
    ["elli"]    = "MF3mGyEYCl7XYWbV9V6O",
    ["josh"]    = "TxGEqnHWrfWFTfGW9XjX",
    ["arnold"]  = "VR6AewLTigWG4xSOukaG",
    ["adam"]    = "pNInz6obpgDQGcFmaJgB",
    ["sam"]     = "yoZ06aMxZJJ28mfd3POQ",
}

--[[------------------------
     Private Definitions
------------------------]]--

Elevenlabs.Config.Key = CreateConVar("elevenlabs_enabled", 1, {FCVAR_ARCHIVE, FCVAR_DONTRECORD, FCVAR_PROTECTED, FCVAR_UNLOGGED}, "The key to use Elevenlabs", 0, 1)
Elevenlabs.Config.Time = CreateConVar("elevenlabs_time", 20, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Time (in ms) between sending packets", 20, 1000)

--[[------------------------
        Main Functions
------------------------]]--

function Elevenlabs.WriteData(ply, IsOnePart, FileID, FileData, FileCurrentPart, FileLastPart)
    local FileSize = #FileData

    net.Start("Elevenlabs.SVtoCL")
        net.WriteBool(IsOnePart)
        net.WriteString(FileID)
        net.WriteEntity(ply)
    
        if IsOnePart then

            net.WriteUInt(16)
            net.WriteData(FileData, FileSize)

        else

            -- Send in what queue is in the file
            net.WriteUInt(FileCurrentPart, 4)
            net.WriteUInt(FileLastPart, 4)

            -- Send FileData
            net.WriteUInt(FileSize, 16)
            net.WriteData(FileData, FileSize)

        end

    net.Broadcast()

end


function Elevenlabs.Request(ply, msg)

    local voice = voices[ ply:GetInfo("openai_elevenlabs_voice") ] or voice

    local headers = {
        ["Accept"] = "audio/mpeg",
        ["Content-Type"] = "application/json",
        ["xi-api-key"] = Elevenlabs.Config.Key:GetString()
    }

    local url = string.format([[https://api.elevenlabs.io/v1/text-to-speech/%s]], voice )
    
    HTTP({
        url         = url,
        method      = "POST",
        body        = util.TableToJSON({ text = msg }),
        headers     = headers,
        type        = "application/json",
        success     = function(code, body, header)

            if not code == 200 then
                print(code)
                PrintTable( util.JSONToTable(body) )
                return
            end


            local FileContent = util.Compress( body )
            local FileSize = #FileContent
            local FileID = os.time()

            if FileSize > FileMaxSize then
                local FileParts = math.ceil( FileSize, FileMaxSize )
                local FileTable = {}

                for i = 1, FileParts - 1 do
                    local IndexStart = (i - 1) * FileMaxSize + 1
                    local IndexEnd = i * FileMaxSize
                    local FileData = string.sub(FileContent, IndexStart, IndexEnd)

                    FileTable[i] = FileData
                end

                local IndexStart = (numParts - 1) * FileMaxSize + 1
                local FileData = string.sub(FileContent, IndexStart)
                FileTable[FileParts] = FileData

                Elevenlabs.Cache[FileID] = FileTable
                Elevenlabs.Cache[FileID .. "_pos"] = 0


                timer.Create("elevenlabs_send_", 1000 / Elevenlabs.Config.Time:GetInt() or 20, #Elevenlabs.Cache[FileID], function()
                    local FileID = FileID
                    local FilePos = Elevenlabs.Cache[FileID .. "_pos"] + 1
                    Elevenlabs.Cache[FileID .. "_pos"] = FilePos
    
                    Elevenlabs.WriteData(ply, false, FileID, FilePos, FileParts)
                end)
            else
                Elevenlabs.WriteData(ply, true, FileID)
            end



        end,
        failed      = function(err)
            MsgC("Error: ", err, "\n")
        end
    })
end