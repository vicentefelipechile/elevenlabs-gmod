--[[----------------------------------------------------------------------------
                            Elevenlabs Shared Script
----------------------------------------------------------------------------]]--

if SERVER then
    util.AddNetworkString("Elevenlabs.BlackList")
end

Elevenlabs.Config = {}

--[[------------------------
      Shared Definitions
------------------------]]--

Elevenlabs.Config.enabled = CreateConVar("elevenlabs_enabled", 1, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Toggle the elevenlabs module", 0, 1)
Elevenlabs.Config.volume = CreateConVar("elevenlabs_volume", 1, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Volume of the voice from elevenlabs module", 0, 5)
Elevenlabs.Config.display = CreateConVar("elevenlabs_noshow", 1, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Should show the command in the chat?", 0, 1)
Elevenlabs.Config.maxtext = CreateConVar("elevenlabs_maxtext", 40, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE}, "What is the max amount of character to sent to Elevenlabs?", 10, 400)

Elevenlabs.Config.BadCharacters = {
    [";"] = "",   ["|"] = "",  ["<"] = "_", [">"] = "_", ['"'] = "_",
    ["'"] = "_",  ["{"] = "_", ["}"] = "_", ["`"] = "_", ["~"] = "_",
    ["\\"] = "_", ["/"] = "_", ["*"] = "_", ["@"] = "_", ["^"] = "_"
}


--[[------------------------
          Functions
------------------------]]--

function Elevenlabs.SetFileName(name)
    name = string.lower( name:gsub("[%p%c]", ""):gsub("%s+", "_") )

    if not file.Exists("elevenlabs", "DATA") then
        file.CreateDir("elevenlabs")
    end

    local format = "elevenlabs/%s_%s.mp3"

    return string.format(format, os.time(), name)
end


function Elevenlabs.SanitizeString(inputString)
    local sanitizedString = ""

    for i = 1, #inputString do
        local char = inputString:sub(i, i)
        local sanitizedChar = Elevenlabs.Config.BadCharacters[char]

        sanitizedString = sanitizedChar and ( sanitizedString .. sanitizedChar ) or ( sanitizedString .. char )
    end

    return sanitizedString
end


-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/util.lua#L351-L356
function Elevenlabs.BlacklistPlayer(ply, allow)
    if not IsEntity(ply) then return end
    if not ply:IsPlayer() then return end
    if not isbool(allow) then return end

    local name = string.format( "%s[%s]", ply:SteamID(), "ElevenlabsBlacklisted" )
    sql.Query( "REPLACE INTO playerpdata ( infoid, value ) VALUES ( " .. SQLStr( name ) .. ", " .. SQLStr( allow and "Allowed" or "NotAllowed" ) .. " )" )
end

-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/util.lua#L337-L345
function Elevenlabs.IsBlacklistedPlayer(ply)
    local name = string.format( "%s[%s]", ply:SteamID(), "ElevenlabsBlacklisted" )
    local val = sql.QueryValue( "SELECT value FROM playerpdata WHERE infoid = " .. SQLStr( name ) .. " LIMIT 1" )

    if ( val == nil ) then
        return false
    end

    return val == "NotAllowed"
end

--[[------------------------
          Net Message
------------------------]]--
if SERVER then
    net.Receive("Elevenlabs.BlackList", function(_, ply)
        if not ply:IsSuperAdmin() then return end

        local plyTarget = net.ReadEntity()
        local allow = net.ReadBool()

        Elevenlabs.BlacklistPlayer(plyTarget, allow)
    end)
end

--[[------------------------
          ConCommand
------------------------]]--

concommand.Add("elevenlabs_blacklist", function(ply, cmd, str)
    if not ( SERVER or ply:IsSuperAdmin() ) then return end

    if stringStart(str, "7656") or stringStart(str, "STEAM_") then
        local plyTarget = NULL

        plyTarget = player.GetBySteamID(str)
        plyTarget = IsValid(plyTarget) and plyTarget or player.GetByAccountID(str)

        if CLIENT then
            net.Start("Elevenlabs.BlackList")
                net.WriteEntity(plyTarget)
                net.WriteBool(false)
            net.SendToServer()
        else
            Elevenlabs.BlacklistPlayer(plyTarget, false)
        end
    end
end)

concommand.Add("elevenlabs_whitelist", function(ply, cmd, str)
    if not ( SERVER or ply:IsSuperAdmin() ) then return end

    if stringStart(str, "7656") or stringStart(str, "STEAM_") then
        local plyTarget = NULL

        plyTarget = player.GetBySteamID(str)
        plyTarget = IsValid(ply) and ply or player.GetByAccountID(str)

        if CLIENT then
            net.Start("Elevenlabs.BlackList")
                net.WriteEntity(plyTarget)
                net.WriteBool(true)
            net.SendToServer()
        else
            Elevenlabs.BlacklistPlayer(plyTarget, true)
        end
    end
end)