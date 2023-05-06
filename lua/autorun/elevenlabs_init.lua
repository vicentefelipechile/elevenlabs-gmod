--[[----------------------------------------------------------------------------
                                Elevenlabs
----------------------------------------------------------------------------]]--
include("enum_color.lua")

Elevenlabs = Elevenlabs or {}
Elevenlabs.Name = "Elevenlabs"

--[[------------------------
        Functions
------------------------]]--

function Elevenlabs.AddFile(path)
    local prefix = path:sub(1,3)

    if prefix == "sv_" then
        if SERVER then
            include(path)

            MsgC(COLOR_WHITE, "[", COLOR_BLUE, Elevenlabs.Name, COLOR_WHITE, "] ", "Loaded:         ", COLOR_STATE, path)
        end
    elseif prefix == "cl_" then
        if SERVER then
            AddCSLuaFile(path)
            MsgC(COLOR_WHITE, "[", COLOR_BLUE, Elevenlabs.Name, COLOR_WHITE, "] ", "Send to Client: ", COLOR_STATE, path)
        elseif CLIENT then
            include(path)
            MsgC(COLOR_WHITE, "[", COLOR_BLUE, Elevenlabs.Name, COLOR_WHITE, "] ", "Loaded:         ", COLOR_STATE, path)
        end
    elseif prefix == "sh_" then
        if SERVER then
            AddCSLuaFile(path)
        end
        include(path)
        MsgC(COLOR_WHITE, "[", COLOR_BLUE, Elevenlabs.Name, COLOR_WHITE, "] ", "Loaded:         ", COLOR_STATE, path)
    end
end

Elevenlabs.AddFile("elevenlabs/sh_main.lua")
Elevenlabs.AddFile("elevenlabs/cl_main.lua")
Elevenlabs.AddFile("elevenlabs/sv_main.lua")