/** AMX Mod X Script
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or ( at
 *  your option ) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *  See the GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ***********************************************************
 *
 * Originally posted on:
 * https://forums.alliedmods.net/showthread.php?t=286034
 
Do you want to something like this below?
It will save the "complaints.txt" file on the './addons/amxmodx/logs' folder.

It is doing this, to the log file:
[code]
L 08/06/2016 - 15:51:20: STEAM_0:0:55161613   Addons zz          de_dust2's          83.42   minutes    This server is super cool. I want to play here for ever.
L 08/06/2016 - 13:31:03: STEAM_0:0:24626492   Addons zz          aim_headshot's      6.53    minutes    pain in my ass
L 08/07/2016 - 05:08:40: STEAM_0:0:76126614   Addons zz          aim_nuts's          8.01    minutes    This admin is a cheater, BAN HIM! STEAM_0:0:37528372
[/code]

To use complain just enter on "say" or "say_team" message mode and type:
[code]
/complain
type_your_complain: This server is super cool. I want to play here for ever.
[/code]
Or go to the console and type:
[code]
type_your_complain "pain in my ass"
type_your_complain "This admin is a cheater, BAN HIM! STEAM_0:0:37528372"
[/code]
 
 */


new const VERSION[] = "2.0.1";

#include <amxmodx>

/**
 * The file on the './addons/amxmodx/logs' folder, to save the text output.
 */
new const OUTPUT_LOG_FILE_NAME[] = "complaints.txt";
new const LOG_KEYWORD[]          = "type_your_complain";

const MAX_SHORT_STRING_SIZE  = 64;
new g_currentMap[ MAX_SHORT_STRING_SIZE ];


/**
 * Called just after server activation.
 *
 * Good place to initialize most of the plugin, such as registering
 * cvars, commands or forwards, creating data structures for later use, or
 * generating and loading other required configurations.
 */
public plugin_init()
{
    new mapNameSize;
    register_plugin( "Complaints", VERSION, "Addons zz" );

    if( ( mapNameSize = get_mapname( g_currentMap, charsmax( g_currentMap ) ) ) < sizeof g_currentMap - 2 )
    {
        g_currentMap[ mapNameSize ]     =  ''';
        g_currentMap[ mapNameSize + 1 ] =  's';
        g_currentMap[ mapNameSize + 2 ] = '^0';
    }

    register_clcmd( "say /complain", "cmd_say", -1 );
    register_clcmd( "say_team /complain", "cmd_say", -1 );

    register_clcmd( LOG_KEYWORD, "log_complain", -1 );
}

/**
 * Write messages to the log file on 'addons/amxmodx/logs'.
 *
 * @param player_id              the player id.
 * @param formated_message       the formatted message to write down the log file.
 */
stock writeToTheLogFile( const player_id, const formated_message[] )
{
    new Float:gameTime;
    gameTime = get_gametime();

    new formatterHelper[ 200 ];
    new complainerName [ MAX_SHORT_STRING_SIZE ];
    new complainerSteamId[ MAX_SHORT_STRING_SIZE ];

    get_user_name( player_id, complainerName, charsmax( complainerName ) );
    get_user_authid( player_id, complainerSteamId, charsmax( complainerSteamId ) );

    formatex( formatterHelper, charsmax( formatterHelper ), "%20s %19s %19s %-7.2f minutes", complainerSteamId, complainerName, g_currentMap, gameTime / 60 );
    log_to_file( OUTPUT_LOG_FILE_NAME, "%80s %s", formatterHelper, formated_message );
}

/**
 * Generic say handler to determine if we need to act on what was said.
 */
public cmd_say( const player_id )
{
    client_cmd( player_id, "messagemode %s", LOG_KEYWORD );
    return PLUGIN_HANDLED_MAIN;
}

public log_complain( const player_id )
{
    new sentence [ 190 ];
    sentence[ 0 ] = '^0';

    read_args( sentence, charsmax( sentence ) );
    remove_quotes( sentence );

    writeToTheLogFile( player_id, sentence );
    client_print( player_id, print_chat, "Your complain was successfully registered: %s", sentence );

    return PLUGIN_HANDLED;
}


