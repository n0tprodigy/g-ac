local _hook_Add = hook.Add
local _hook_Remove = hook.Remove
local _util_JSONToTable = util.JSONToTable
local _tonumber = tonumber
local _print = print
local _http_Post = http.Post
local _game_KickID = game.KickID
local _util_SteamIDFrom64 = util.SteamIDFrom64

_hook_Add('Think', 'g-AC_getGlobalInfo', function()
    _hook_Remove('Think', 'g-AC_getGlobalInfo')
    _http_Post( "https://stats.g-ac.dev/api/server/id", { license = gAC.config.LICENSE, hostname = GetHostName() }, function( result )
        local resp = _util_JSONToTable(result)
        if resp == nil then 
            gAC.Print("[Global Bans] Welp I guess the api is dead... contact the developers about this.")
            return
        end
        if(resp["success"] == "false") then
            gAC.Print("[Global Bans] Retreiving Server ID failed: "..resp["error"])
            gAC.server_id = 0
        else
            gAC.Print("[Global Bans] Server ID has been assigned ("..resp["id"]..").")
            gAC.server_id = resp["id"]
        end
    end, function( failed )
        gAC.Print("[Global Bans] Retreiving Server ID failed: " .. failed )
    end )
end)

function gAC.GetFormattedGlobalText( displayReason, banTime )
    local banString = "g-AC Global Ban ["..displayReason.."]".. '\n'

    banTime = _tonumber( banTime )
    if( banTime == -1 ) then
        banString = banString .. "Type: Kick"
    elseif( banTime >= 0 ) then
        if( banTime == 0 ) then
            banString = banString .. "Type: Permanent Ban\n\nPlease appeal if you believe this is false"
        else
            banString = banString .. "Type: Temporary Ban\n\nPlease appeal if you believe this is false"
        end
    end

    return banString
end

-- Due to how admin systems prevent any other system from using CheckPassword, :shrug:
local GAMEMODE = GAMEMODE or GM
if GAMEMODE.CheckPassword then
    gAC.CheckPassword_Old = GAMEMODE.CheckPassword
    function GAMEMODE.CheckPassword(SteamID, IP, sv_Pass, cl_Pass, Name)
        _http_Post( "https://stats.g-ac.dev/api/checkban", { player = SteamID }, function( result )
            local resp = _util_JSONToTable(result)
            if resp == nil then return end
            if(resp["success"] == "false") then
                gAC.Print("[Global Bans] Fetching global ban data failed: "..resp["error"])
            else    
                if(resp["banned"] == "true") then
                    _game_KickID(_util_SteamIDFrom64(SteamID), gAC.GetFormattedGlobalText(resp["id"], 0));
                end
            end
        end, function( failed )
            gAC.Print("[Global Bans] Fetching global ban data failed: " .. failed )
        end )
    end
    --[[_hook_Add("CheckPassword", "g-AC_getGlobalInfo", function(SteamID, IP, sv_Pass, cl_Pass, Name)
        _http_Post( "https://stats.g-ac.dev/api/checkban", { player = SteamID }, function( result )
            local resp = _util_JSONToTable(result)
            if resp == nil then return end
            if(resp["success"] == "false") then
                gAC.Print("[Global Bans] Fetching global ban data failed: "..resp["error"])
            else    
                if(resp["banned"] == "true") then
                    _game_KickID(_util_SteamIDFrom64(SteamID), gAC.GetFormattedGlobalText(resp["id"], 0));
                end
            end
        end, function( failed )
            gAC.Print("[Global Bans] Fetching global ban data failed: " .. failed )
        end )
    end)]]
else
    _hook_Add("PlayerAuthed", "g-AC_getGlobalInfo", function(ply)
        _http_Post( "https://stats.g-ac.dev/api/checkban", { player = ply:SteamID64() }, function( result )
            local resp = _util_JSONToTable(result)
            if resp == nil then return end
            if(resp["success"] == "false") then
                gAC.Print("[Global Bans] Fetching global ban data failed: "..resp["error"])
            else    
                if(resp["banned"] == "true") then
                    ply:Kick(gAC.GetFormattedGlobalText(resp["id"], 0))
                end
            end
        end, function( failed )
            gAC.Print("[Global Bans] Fetching global ban data failed: " .. failed )
        end )
    end)
end