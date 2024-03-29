--[[----------------------------------------------------------------------------
                        Elevenlabs Server-side Script
----------------------------------------------------------------------------]]--

local stringStart = string.StartWith or string.StartsWith

util.AddNetworkString("Elevenlabs.SVtoCL")
util.AddNetworkString("Elevenlabs.Command")
Elevenlabs.Cache = {}

--[[------------------------
      Local Definitions
------------------------]]--

local FileMaxSize = 63000
local Voices = {
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
      Global Definitions
------------------------]]--

Elevenlabs.Headers = {
    ["Accept"] = "audio/mpeg",
    ["Content-Type"] = "application/json",
    ["xi-api-key"] = "YOUR_API_KEY_HERE"
}


--[[------------------------
     Private Definitions
------------------------]]--

Elevenlabs.Config.Key = CreateConVar("elevenlabs_key", "YOUR_API_KEY_HERE", {FCVAR_ARCHIVE, FCVAR_DONTRECORD, FCVAR_PROTECTED, FCVAR_UNLOGGED}, "The key to use Elevenlabs")
Elevenlabs.Config.Time = CreateConVar("elevenlabs_time", 20, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Time (in ms) between sending packets", 20, 1000)
Elevenlabs.Config.Multilingual = CreateConVar("elevenlabs_voice_multilingual", 0, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Toggle the multilingual system", 0, 1)
Elevenlabs.Config.Stability = CreateConVar("elevenlabs_voice_stability", 0.2, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Voice Setting Stability", 0, 1)
Elevenlabs.Config.Similarity = CreateConVar("elevenlabs_voice_similarity", 0.8, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Voice Setting Similarity", 0, 1)
Elevenlabs.Config.NotAllowedMsg = CreateConVar("elevenlabs_notallowed_msg", "You are not allowed to use Elevenlabs", {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE}, "What message will show to the player when isn't allowed to use Elevenlabs")
Elevenlabs.Config.StringSafe = CreateConVar("elevenlabs_stringsafe", 0, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Check and replace malicious string", 0, 1)

--[[------------------------
        Main Functions
------------------------]]--

function Elevenlabs.GetPlayers()
    local tbl = {}

    for _, ply in ipairs(player.GetAll()) do
        if ply:GetInfoNum("elevenlabs_download", 1) == 1 then
            table.insert(tbl, ply)
        end
    end

    return tbl
end

function Elevenlabs.WriteData(ply, IsOnePart, FileID, FileData, FileCurrentPart, FileLastPart)
    local FileSize = #FileData

    net.Start("Elevenlabs.SVtoCL")
        net.WriteBool(IsOnePart)
        net.WriteString(FileID)
        net.WriteEntity(ply)

        if IsOnePart then

            net.WriteUInt(FileSize, 16)
            net.WriteData(FileData, FileSize)

        else

            -- Send in what queue is in the file
            net.WriteUInt(FileCurrentPart, 4)
            net.WriteUInt(FileLastPart, 4)

            -- Send FileData
            net.WriteUInt(FileSize, 16)
            net.WriteData(FileData, FileSize)

        end

    net.Send( Elevenlabs.GetPlayers() )

end

function Elevenlabs.Request(ply, msg)

    if not Elevenlabs.Config.enabled:GetBool() then return end

    local Voice = Voices[ ply:GetInfo("elevenlabs_voice") ] or ply:GetInfo("elevenlabs_voice")
    local Headers = table.Copy(Elevenlabs.Headers)
    Headers["xi-api-key"] = Elevenlabs.Config.Key:GetString()

    local Body = {
        text = msg,
        model_id = Elevenlabs.Config.Multilingual:GetBool() and "eleven_multilingual_v1" or "eleven_monolingual_v1",
        voice_settings = {
            stability = Elevenlabs.Config.Stability:GetFloat(),
            similarity_boost = Elevenlabs.Config.Similarity:GetFloat()
        }
    }

    local url = string.format([[https://api.elevenlabs.io/v1/text-to-speech/%s]], Voice )

    HTTP({
        url         = url,
        method      = "POST",
        body        = util.TableToJSON(Body),
        headers     = Headers,
        type        = "application/json",
        success     = function(code, body, header)
            Elevenlabs.GetStatusDescription(code)

            if code == 200 then

                local FileContent = util.Compress( body )
                local FileSize = #FileContent
                local FileID = os.time()

                if FileSize > FileMaxSize then
                    local FileParts = math.ceil( FileSize / FileMaxSize )
                    local FileTable = {}

                    for i = 1, FileParts - 1 do
                        local IndexStart = (i - 1) * FileMaxSize + 1
                        local IndexEnd = i * FileMaxSize
                        local FileData = string.sub(FileContent, IndexStart, IndexEnd)

                        FileTable[i] = FileData
                    end

                    local IndexStart = (FileParts - 1) * FileMaxSize + 1
                    local FileData = string.sub(FileContent, IndexStart)
                    FileTable[FileParts] = FileData

                    Elevenlabs.Cache[FileID] = FileTable
                    Elevenlabs.Cache[FileID .. "_pos"] = 0


                    timer.Create("elevenlabs_send_" .. FileID, 1 / Elevenlabs.Config.Time:GetInt() or 20, #Elevenlabs.Cache[FileID], function()
                        local FilePos = Elevenlabs.Cache[FileID .. "_pos"] + 1
                        Elevenlabs.Cache[FileID .. "_pos"] = FilePos

                        Elevenlabs.WriteData(ply, false, FileID, Elevenlabs.Cache[FileID][FilePos], FilePos, FileParts)
                    end)
                else
                    Elevenlabs.WriteData(ply, true, FileID, FileContent)
                end

            end

        end,
        failed      = function(err)
            MsgC("Error: ", err, "\n")
        end
    })
end

function Elevenlabs.PlayerCommand(_, ply)
    local msg = net.ReadString()

    if Elevenlabs.IsBlacklistedPlayer(ply) then
        ply:ChatPrint( Elevenlabs.Config.NotAllowedMsg:GetString() )
        return ( not Elevenlabs.Config.display:GetBool() ) and Elevenlabs.Config.NotAllowedMsg:GetString() or ""
    end

    if msg:len() >= Elevenlabs.Config.maxtext:GetInt() then
        msg:sub(1, 40)
    end

    msg = Elevenlabs.Config.StringSafe:GetBool() and Elevenlabs.SanitizeString(msg) or msg
    Elevenlabs.Request(ply, msg)
end

--[[------------------------
            Hook
------------------------]]--

hook.Add("PlayerSay", "elevenlabssay", function(ply, text)
    if stringStart(text, "!tts ") then

        if Elevenlabs.IsBlacklistedPlayer(ply) then
            ply:ChatPrint( Elevenlabs.Config.NotAllowedMsg:GetString() )
            return not ( Elevenlabs.Config.display:GetBool() ) and text or ""
        end

        local msg = string.sub(text, 5)
        if msg:len() >= Elevenlabs.Config.maxtext:GetInt() then
            msg:sub(1, 40)
        end

        msg = Elevenlabs.Config.StringSafe:GetBool() and Elevenlabs.SanitizeString(msg) or msg
        Elevenlabs.Request(ply, msg)

        return not ( Elevenlabs.Config.display:GetBool() ) and text or ""
    end
end)

--[[------------------------
           Network
------------------------]]--

net.Receive("Elevenlabs.Command", Elevenlabs.PlayerCommand)