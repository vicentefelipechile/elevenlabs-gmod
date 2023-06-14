--[[----------------------------------------------------------------------------
                                Elevenlabs
----------------------------------------------------------------------------]]--
if SERVER then
    AddCSLuaFile("enum_color.lua")
end
include("enum_color.lua")

Elevenlabs = Elevenlabs or {}
Elevenlabs.Name = "Elevenlabs"

--[[------------------------
        Functions
------------------------]]--

function Elevenlabs.AddFile(path)
    local prefix = path:sub(1,3)
    path = "elevenlabs/" .. path

    if prefix == "sv_" then
        if SERVER then
            include(path)

            MsgC(COLOR_WHITE, "[", COLOR_BLUE, Elevenlabs.Name, COLOR_WHITE, "] ", "Loaded: ", COLOR_STATE, path)
        end
    elseif prefix == "cl_" then
        if SERVER then
            AddCSLuaFile(path)
            MsgC(COLOR_WHITE, "[", COLOR_BLUE, Elevenlabs.Name, COLOR_WHITE, "] ", "Sended: ", COLOR_STATE, path)
        elseif CLIENT then
            include(path)
            MsgC(COLOR_WHITE, "[", COLOR_BLUE, Elevenlabs.Name, COLOR_WHITE, "] ", "Loaded: ", COLOR_STATE, path)
        end
    elseif prefix == "sh_" then
        if SERVER then
            AddCSLuaFile(path)
        end
        include(path)
        MsgC(COLOR_WHITE, "[", COLOR_BLUE, Elevenlabs.Name, COLOR_WHITE, "] ", "Loaded: ", COLOR_STATE, path)
    end

    MsgC("\n")
end

Elevenlabs.AddFile("sh_main.lua")
Elevenlabs.AddFile("sh_http.lua")
Elevenlabs.AddFile("cl_main.lua")
Elevenlabs.AddFile("sv_main.lua")