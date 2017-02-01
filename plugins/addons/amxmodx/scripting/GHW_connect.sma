/*
*   _______     _      _  __          __
*  | _____/    | |    | | \ \   __   / /
*  | |         | |    | |  | | /  \ | |
*  | |         | |____| |  | |/ __ \| |
*  | |   ___   | ______ |  |   /  \   |
*  | |  |_  |  | |    | |  |  /    \  |
*  | |    | |  | |    | |  | |      | |
*  | |____| |  | |    | |  | |      | |
*  |_______/   |_|    |_|  \_/      \_/
*
*
*
*  Last Edited: 12-06-09
*
*  ============
*   Changelog:
*  ============
*
*  v1.1
*    -Bug Fixes
*
*  v1.0
*    -Initial Release
*
*/

#define VERSION    "1.1"

#include <amxmodx>
#include <amxmisc>
#include <geoip>

#define SHOW_COLOR        1
#define SHOW_CONNECT        2
#define SHOW_DISCONNECT        4
#define PLAY_SOUND_CONNECT    8
#define PLAY_SOUND_DISCONNECT    16

new display_type_pcvar

new name[33][32]
new authid[33][32]
new country[33][46]
new ip[33][32]

new connect_soundfile[64]
new disconnect_soundfile[64]

new saytext_msgid

public plugin_init()
{
    register_plugin("GHW Connect Messages",VERSION,"GHW_Chronic")
    display_type_pcvar = register_cvar("cm_flags","31")
    register_cvar("cm_connect_string","[AMXX] %name (%steamid) has connected (%country).")
    register_cvar("cm_disconnect_string","[AMXX] %name (%steamid) has disconnected (%country).")

    saytext_msgid = get_user_msgid("SayText")
}

public plugin_precache()
{
    register_cvar("cm_connect_sound","buttons/bell1.wav")
    register_cvar("cm_disconnect_sound","fvox/blip.wav")

    get_cvar_string("cm_connect_sound",connect_soundfile,63)
    get_cvar_string("cm_disconnect_sound",disconnect_soundfile,63)

    precache_sound(connect_soundfile)
    precache_sound(disconnect_soundfile)
}

public client_putinserver(id)
{
    if( !is_user_bot(id) )
    {
        new display_type = get_pcvar_num(display_type_pcvar)
        get_client_info(id)

        if(display_type & SHOW_CONNECT)
        {
            new string[200]
            get_cvar_string("cm_connect_string",string,199)
            format(string,199,"^x01%s",string)

            if(display_type & SHOW_COLOR)
            {
                new holder[46]

                format(holder,45,"^x04%s^x01",name[id])
                replace(string,199,"%name",holder)

                format(holder,45,"^x04%s^x01",authid[id])
                replace(string,199,"%steamid",holder)

                format(holder,45,"^x04%s^x01",country[id])
                replace(string,199,"%country",holder)

                format(holder,45,"^x04%s^x01",ip[id])
                replace(string,199,"%ip",holder)
            }
            else
            {
                replace(string,199,"%name",name[id])
                replace(string,199,"%steamid",authid[id])
                replace(string,199,"%country",country[id])
                replace(string,199,"%ip",ip[id])
            }

            new num, players[32], player
            get_players(players,num,"ch")
            for(new i=0;i<num;i++)
            {
                player = players[i]

                message_begin(MSG_ONE, saytext_msgid,{0,0,0}, player)
                write_byte(player)
                write_string(string)
                message_end()

                server_print(string)

                if(display_type & PLAY_SOUND_CONNECT)
                {
                    new stringlen = strlen(connect_soundfile)
                    if(connect_soundfile[stringlen - 1]=='v' && connect_soundfile[stringlen - 2]=='a' && connect_soundfile[stringlen - 3]=='w') //wav
                    {
                        client_cmd(player,"spk ^"sound/%s^"",connect_soundfile)
                    }
                    if(connect_soundfile[stringlen - 1]=='3' && connect_soundfile[stringlen - 2]=='p' && connect_soundfile[stringlen - 3]=='m') //wav
                    {
                        client_cmd(player,"mp3 play ^"sound/%s^"",connect_soundfile)
                    }
                }
            }
        }
    }
}

public get_client_info(id)
{
    get_user_name(id,name[id],31)
    get_user_authid(id,authid[id],31)

    get_user_ip(id,ip[id],31)
    geoip_country(ip[id],country[id])

    if(equal(country[id],"error"))
    {
        if(contain(ip[id],"192.168") == 0 || equal(ip[id],"127.0.0.1") || contain(ip[id],"10.")==0 ||  contain(ip[id],"172.")==0)
        {
            country[id] = "LAN"
        } 
        else if(equal(ip[id],"loopback"))
        {
            country[id] = "ListenServer User"
        }
        else
        {
            country[id] = "Unknown Country"
        }
    }
}

public client_infochanged(id)
{
    if(!is_user_bot(id))
    {
        get_user_info(id,"name",name[id],31)
    }
}

public client_disconnect(id)
{
    if(!is_user_bot(id))
    {
        new display_type = get_pcvar_num(display_type_pcvar)

        if(display_type & SHOW_DISCONNECT)
        {
            new string[200]
            get_cvar_string("cm_disconnect_string",string,199)
            format(string,199,"^x01%s",string)

            if(display_type & SHOW_COLOR)
            {
                new holder[46]

                format(holder,45,"^x04%s^x01",name[id])
                replace(string,199,"%name",holder)

                format(holder,45,"^x04%s^x01",authid[id])
                replace(string,199,"%steamid",holder)

                format(holder,45,"^x04%s^x01",country[id])
                replace(string,199,"%country",holder)

                format(holder,45,"^x04%s^x01",ip[id])
                replace(string,199,"%ip",holder)
            }
            else
            {
                replace(string,199,"%name",name[id])
                replace(string,199,"%steamid",authid[id])
                replace(string,199,"%country",country[id])
                replace(string,199,"%ip",ip[id])
            }

            new num, players[32], player
            get_players(players,num,"ch")
            for(new i=0;i<num;i++)
            {
                player = players[i]

                message_begin(MSG_ONE,saytext_msgid,{0,0,0},player)
                write_byte(player)
                write_string(string)
                message_end()

                server_print(string)

                if(display_type & PLAY_SOUND_DISCONNECT)
                {
                    new stringlen = strlen(connect_soundfile)
                    if(connect_soundfile[stringlen - 1]=='v' && connect_soundfile[stringlen - 2]=='a' && connect_soundfile[stringlen - 3]=='w') //wav
                    {
                        client_cmd(player,"spk ^"sound/%s^"",connect_soundfile)
                    }
                    if(connect_soundfile[stringlen - 1]=='3' && connect_soundfile[stringlen - 2]=='p' && connect_soundfile[stringlen - 3]=='m') //wav
                    {
                        client_cmd(player,"mp3 play ^"sound/%s^"",connect_soundfile)
                    }
                }
            }
        }
    }
}
