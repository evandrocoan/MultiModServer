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
new country[33][100]
new ip[33][32]

new g_played_time[33]
new connect_soundfile[64]
new disconnect_soundfile[64]

/**
 * The file on the './addons/amxmodx/logs' folder, to save the debugging text output.
 */
new const DEBUGGER_OUTPUT_LOG_FILE_NAME[] = "GHW_connect.txt";

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

/**
 * Write debug messages to server's console and log file.
 *
 * @param message      the debug message, if omitted its default value is ""
 * @param any          the variable number of formatting parameters
 *
 * @see the stock writeToTheDebugFile( log_file[], formated_message[] ) for the output log
 *      'DEBUGGER_OUTPUT_LOG_FILE_NAME'.
 */
stock print_logger( const message[] = "", any:... )
{
    static formated_message[ 256 ];
    vformat( formated_message, charsmax( formated_message ), message, 2 );

    writeToTheDebugFile( DEBUGGER_OUTPUT_LOG_FILE_NAME, formated_message );
}

/**
 * Write messages to the debug log file on 'addons/amxmodx/logs'.
 *
 * @param log_file               the log file name.
 * @param formated_message       the formatted message to write down to the debug log file.
 */
stock writeToTheDebugFile( const log_file[], const formated_message[] )
{
    log_to_file( log_file, "{%6.3f} %s", get_gametime(), formated_message );
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

            g_played_time[ id ] = get_systime()
            print_logger( "is_admin: %5d, played_time: %5d, %-20s, %-16s, %s", get_user_flags( id ), 0, authid[id], ip[id], string )

            new num, players[32], player
            get_players(players,num,"ch")

            for(new i=0;i<num;i++)
            {
                player = players[i]

                message_begin(MSG_ONE, saytext_msgid,{0,0,0}, player)
                write_byte(player)
                write_string(string)
                message_end()

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
    new written_chars = geoip_country_ex( ip[id], country[id], charsmax( country[] ), -1 )

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

        written_chars = strlen( country[id] )
    }

    written_chars += copy( country[ id ][ written_chars ], charsmax( country[] ) - written_chars, "/" )
    written_chars += geoip_region_name( ip[ id ], country[ id ][ written_chars ], charsmax( country[] ) - written_chars, -1 )

    written_chars += copy( country[ id ][ written_chars ], charsmax( country[] ) - written_chars, "/" )
    geoip_city( ip[ id ], country[ id ][ written_chars ], charsmax( country[] ) - written_chars, -1 )
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

            new played_time = get_systime() - g_played_time[ id ]
            print_logger( "is_admin: %5d, played_time: %5d, %-20s, %-16s, %s", get_user_flags( id ), played_time, authid[id], ip[id], string )

            for(new i=0;i<num;i++)
            {
                player = players[i]

                message_begin(MSG_ONE,saytext_msgid,{0,0,0},player)
                write_byte(player)
                write_string(string)
                message_end()

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
