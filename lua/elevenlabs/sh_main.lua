--[[----------------------------------------------------------------------------
                            Elevenlabs Shared Script
----------------------------------------------------------------------------]]--

Elevenlabs.Config = {}

--[[------------------------
      Shared Definitions
------------------------]]--

Elevenlabs.Config.enabled = CreateConVar("elevenlabs_enabled", 1, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Toggle the elevenlabs module", 0, 1)
Elevenlabs.Config.volume = CreateConVar("openai_elevenlabs_volume", 1, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Volume of the voice from elevenlabs module", 0, 5)
Elevenlabs.Config.display = CreateConVar("openai_elevenlabs_noshow", 1, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Should show the command in the chat?", 0, 1)


--[[------------------------
          Functions
------------------------]]--

function Elevenlabs.SetFileName(name)
    local unixtime = os.time()
    local name = string.lower( name:gsub("[%p%c]", ""):gsub("%s+", "_") )

    if not file.Exists("elevenlabs", "DATA") then
        file.CreateDir("elevenlabs")
    end

    local format = "elevenlabs/%s_%s.mp3"
    
    return string.format(format, unixtime, name)
end