/*********************** Licensing *******************************************************
*
*   Copyleft 2015-2016 @ Addons zz
*
*   Plugin Thread: https://forums.alliedmods.net/showthread.php?t=273020
*
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation; either version 2 of the License, or ( at
*  your option ) any later version.
*
*  This program is distributed in the hope that it will be useful, but
*  WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
*  General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
***************************************************************************************
*/

new const VERSION[] = "1.1-rc1.1"

#include <amxmodx>
#include <amxmisc>

/** This is to view internal program data while execution. See the function 'debugMesssageLogger(...)'
 * and the variable 'g_debug_level' for more information. Default value: 0  - which is disabled.
 */
#define IS_DEBUG_ENABLED 0

#if IS_DEBUG_ENABLED > 0
    #define DEBUG_LOGGER(%1) debugMesssageLogger( %1 )

/**
 * ( 00000 ) 0 disabled all debug.
 * ( 00001 ) 1 displays basic debug messages.
 * ( 00010 ) 2 displays each mod loaded.
 * ( 00100 ) 4 displays the keys pressed/mods loaded during voting.
 * ( 01000 ) 8 displays the the mapcycle configuration.
 *
 * ( 100.. ) 64 displays messages related 'client_print_color_internal'.
 * ( 111.. ) 127 displays all debug levels.
 */
new g_debug_level = 79

/**
 * Write debug messages to server's console accordantly to the global variable g_debug_level.
 *
 * @param mode the debug mode level, see the variable 'g_debug_level' for the levels.
 * @param message[] the text formatting rules to display.
 * @param any the variable number of formatting parameters.
 */
stock debugMesssageLogger( mode, message[], any: ... )
{
    if( mode & g_debug_level )
    {
        static formated_message[ 256 ]

        vformat( formated_message, charsmax( formated_message ), message, 3 )

        server_print( "%s", formated_message )
    }
}

#else
    #define DEBUG_LOGGER(%1) //
#endif

new const PLUGIN_NAME[]        = "Multi-Mod Manager"
new const PLUGIN_AUTHOR_NAME[] = "Addons zz"

#define TASK_VOTEMOD      2487002
#define TASK_CHVOMOD      2487004
#define TASKID_PRINT_HELP 648215

#define LONG_STRING   256
#define COLOR_MESSAGE 192
#define SHORT_STRING  64

/**
 * The client console lines number to print when is showed the help command.
 */
#define LINES_PER_PAGE 10

#define MENU_ITEMS_PER_PAGE 8

/**
 * Convert colored strings codes '!g for green', '!y for yellow', '!t for team'.
 */
#define INSERT_COLOR_TAGS(%1) \
{ \
    replace_all( %1, charsmax( %1 ), "!g", "^4" ); \
    replace_all( %1, charsmax( %1 ), "!t", "^3" ); \
    replace_all( %1, charsmax( %1 ), "!n", "^1" ); \
    replace_all( %1, charsmax( %1 ), "!y", "^1" ); \
}

#define REMOVE_COLOR_TAGS(%1) \
{ \
    replace_all( %1, charsmax( %1 ), "^1", "" ); \
    replace_all( %1, charsmax( %1 ), "^2", "" ); \
    replace_all( %1, charsmax( %1 ), "^3", "" ); \
    replace_all( %1, charsmax( %1 ), "^4", "" ); \
}

#define PRINT_COLORED_MESSAGE(%1,%2) \
{ \
    message_begin( MSG_ONE_UNRELIABLE, g_user_msgid, _, %1 ); \
    write_byte( %1 ); \
    write_string( %2 ); \
    message_end(); \
}

new bool:g_is_color_chat_supported

new g_user_msgid
new g_coloredmenus
new g_menu_total_pages
new g_currentMod_id
new g_mapManagerType
new g_isFirstTime_serverLoad
new g_dynamic_array_size_temp

new Array:g_mod_names
new Array:g_mod_shortNames
new Array:g_votemodcount

new g_mod_name_temp      [ SHORT_STRING ]
new g_mod_short_name_temp[ SHORT_STRING ]

new g_modCounter             = 0
new g_isTimeTo_changeMapcyle = false
new g_menuname[]             = "VOTE MOD MENU"

new g_menuPosition        [ 33 ]
new g_currentMod_shortName[ SHORT_STRING ]
new g_current_print_page  [ 33 ]

new g_configFolder                 [ LONG_STRING ]
new g_masterConfig_filePath        [ LONG_STRING ]
new g_masterPlugin_filePath        [ LONG_STRING ]
new g_votingFinished_filePath      [ LONG_STRING ]
new g_currentMod_id_filePath       [ LONG_STRING ]
new g_currentMod_shortName_filePath[ LONG_STRING ]
new g_votingList_filePath          [ LONG_STRING ]

new gp_allowedvote
new gp_endmapvote
new gp_mintime
new gp_timelimit
new gp_mapcyclefile

new g_alertMultiMod[ 512 ] = ";Configuration files of Multi-Mod System^n//\
which is run every time the server starts and defines which mods are enabled.^n//\
This file is managed automatically by multimod_manager.sma plugin^n//\
and any modification will be discarded in the activation of some mod.^n^n"

new g_helpamx_setmod[ SHORT_STRING ] = "help 1  | for help."
new g_helpamx_setmods[ 128 ]         = "shortModName <1 or 0> to restart or not  \
| Enable/Disable any mod, loaded or not ( silent mod ). "

new g_cmdsAvailables[][ 72 ] =
{
    "^namx_setmod help 1                | To show this help.",
    "amx_setmod disable 1             | To deactivate any active Mod.",
    "amx_votemod                      | To force a votemod.",
    "say_team nextmod                 | To see which is the next mod.",
    "say currentmod                   | To see which is the current mod.",
    "say votemod                      | To try start a vote mod.",
    "say_team votemod                 | To try start a vote mod."
}

/**
 * Register plugin commands and load configurations.
 */
public plugin_init()
{
    register_plugin( PLUGIN_NAME, VERSION, PLUGIN_AUTHOR_NAME )

    register_cvar( "MultiModManager", VERSION, FCVAR_SERVER | FCVAR_SPONLY )

    register_dictionary_colored( "multimodmanager.txt" )

    gp_mintime     = register_cvar( "amx_mintime", "10" )
    gp_allowedvote = register_cvar( "amx_multimod_voteallowed", "1" )
    gp_endmapvote  = register_cvar( "amx_multimod_endmapvote", "0" )

    g_mod_names      = ArrayCreate( SHORT_STRING )
    g_mod_shortNames = ArrayCreate( SHORT_STRING )
    g_votemodcount   = ArrayCreate( 1 )

    register_clcmd( "amx_votemod", "start_vote", ADMIN_MAP, "Vote for the next mod" )
    register_clcmd( "say currentmod", "user_currentmod" )
    register_clcmd( "say_team currentmod", "user_currentmod" )
    register_clcmd( "say votemod", "user_votemod" )
    register_clcmd( "say_team votemod", "user_votemod" )

    register_concmd( "amx_setmod", "receiveCommand", ADMIN_CFG, g_helpamx_setmod )
    register_concmd( "amx_setmods", "receiveCommandSilent", ADMIN_IMMUNITY, g_helpamx_setmods )
    register_menucmd( register_menuid( g_menuname ), 2047, "player_vote" )

    g_user_msgid   = get_user_msgid( "SayText" );
    g_coloredmenus = colored_menus()
}

/**
 * Auto configure the mapchooser plugin by switching between multimod_mapchooser and galileo.
 *
 * Also gets the current game mods cvars pointer for global variables.
 * And adjust the localinfo variable to store the current mod loaded, reading the current mod file.
 */
public plugin_cfg()
{
    gp_timelimit    = get_cvar_pointer( "mp_timelimit" )
    gp_mapcyclefile = get_cvar_pointer( "mapcyclefile" )

    get_configsdir( g_configFolder, charsmax( g_configFolder ) )

    formatex( g_masterPlugin_filePath, charsmax( g_masterPlugin_filePath ),
            "%s/plugins-multi.ini", g_configFolder )

    formatex( g_masterConfig_filePath, charsmax( g_masterConfig_filePath ),
            "%s/multimod/multimod.cfg", g_configFolder )

    formatex( g_currentMod_id_filePath, charsmax( g_currentMod_id_filePath ),
            "%s/multimod/currentmod_id.ini", g_configFolder )

    formatex( g_currentMod_shortName_filePath, charsmax( g_currentMod_shortName_filePath ),
            "%s/multimod/currentmod_shortname.ini", g_configFolder )

    formatex( g_votingList_filePath, charsmax( g_votingList_filePath ),
            "%s/multimod/voting_list.ini", g_configFolder )

    formatex( g_votingFinished_filePath, charsmax( g_votingFinished_filePath ),
            "%s/multimod/votingfinished.cfg", g_configFolder )

    g_is_color_chat_supported = ( is_running( "czero" )
                                  || is_running( "cstrike" ) )

    switchMapManager()

    build_first_mods()
    load_votingList()

    loadCurrentMod()

    unloadLastActiveMod()

    if( get_pcvar_num( gp_endmapvote ) )
    {
        set_task( 15.0, "check_task", TASK_VOTEMOD, "", 0, "b" )
    }
}

/**
 * After the first time the server loads, this function runs the late configuration file
 * used to restore the last active mod cvars changed and the first mapcycle used.
 *
 * This function also detect when the current mod is changed due specific maps configuration
 * files like, "./configs/maps/plugins-zm.ini", which activates the zombie plague mod.
 *
 * In order to this works, you must configure the file "./configs/maps/prefix_zm.cfg"
 * with the command:
 *          localinfo amx_lastmod zp50Money
 *
 * Note: zp50Money is the zombie plague mod, short mod name defined on your configuration file.
 */
public unloadLastActiveMod()
{
    new lastMod_shortName    [ SHORT_STRING ]
    new firstServer_Mapcycle [ SHORT_STRING ]
    new lateConfig_filePath  [ LONG_STRING ]

    get_localinfo( "amx_lastmod", lastMod_shortName, charsmax( lastMod_shortName ) )
    get_localinfo( "firstMapcycle_loaded", firstServer_Mapcycle, charsmax( firstServer_Mapcycle ) )

    if( !equal( lastMod_shortName, g_currentMod_shortName )
        && g_isFirstTime_serverLoad != 0 )
    {
        lateConfig_pathCoder( lastMod_shortName, lateConfig_filePath, charsmax( lateConfig_filePath ) )

        if( file_exists( lateConfig_filePath ) )
        {
            print_at_console_to_all( "Executing the deactivation mod configuration file ( %s ).", lateConfig_filePath )
            server_cmd( "exec %s", lateConfig_filePath )
        }

        if( g_isFirstTime_serverLoad == 2 )
        {
            server_cmd( "mapcyclefile %s", firstServer_Mapcycle )
        }
    }
}

/**
 * Process the input command "amx_setmod OPITON1 OPITON2".
 *
 * @param player_id        - will hold the players id who started the command
 * @param level            - will hold the access level of the command
 * @param cid              - will hold the commands internal id
 *
 * @ARG1 firstCommand_lineArgument       the modShortName to enable
 * @ARG2 secondCommand_lineArgument      inform to start a vote map "1" or not "0"
 */
public receiveCommand( player_id, level, cid )
{
    //Make sure this user is an admin
    if( !cmd_access( player_id, level, cid, 3 ) )
    {
        return PLUGIN_HANDLED
    }
    new firstCommand_lineArgument [ SHORT_STRING ]
    new secondCommand_lineArgument[ SHORT_STRING ]

    //Get the command arguments from the console
    read_argv( 1, firstCommand_lineArgument,   charsmax( firstCommand_lineArgument ) )
    read_argv( 2, secondCommand_lineArgument, charsmax( secondCommand_lineArgument ) )

    new isTimeToRestart      = equal( secondCommand_lineArgument, "1" )
    g_isTimeTo_changeMapcyle = true

    if( primitiveFunctions( player_id, firstCommand_lineArgument, isTimeToRestart ) )
    {
        if( activateMod_byShortName( firstCommand_lineArgument )  )
        {
            configureModID( firstCommand_lineArgument )
            messageModActivated( firstCommand_lineArgument, isTimeToRestart, true )
        }
        else
        {
            printHelp( player_id )
        }
    }
    g_isTimeTo_changeMapcyle = false

    return PLUGIN_HANDLED
}

/**
 * Given a mod short name like "predator", set its plugin internal mod id.
 *
 * @param shortName        the mod short name.
 *
 * @return boolean         true if shortName is a valid mod, false otherwise.
 */
public configureModID( shortName[] )
{
    for( new mod_id_number = 3; mod_id_number <= g_modCounter; mod_id_number++ )
    {
        ArrayGetString( g_mod_shortNames, mod_id_number, g_mod_short_name_temp, charsmax( g_mod_short_name_temp ) )

        if( equal( shortName, g_mod_short_name_temp ) )
        {
            g_currentMod_id = mod_id_number
            saveCurrentModBy_id( mod_id_number )
        }
    }
}

/**
 * Checks the activation function for disableMods and help commands.
 *
 * @param firstCommand_lineArgument[]       the first command line argument
 * @param secondCommand_lineArgument[]      the second command line argument
 * @param player_id                         the player id
 *
 * @return boolean        true if was not asked for a primitive function, false otherwise.
 */
public primitiveFunctions( player_id, firstCommand_lineArgument[], isTimeToRestart )
{
    if( equal( firstCommand_lineArgument, "disable" ) )
    {
        disableMods()

        if( isTimeToRestart )
        {
            msgResourceActivated( "disable", isTimeToRestart, true )
        }
        return false
    }

    if( equal( firstCommand_lineArgument, "help" ) )
    {
        printHelp( player_id )
        return false
    }
    return true
}

/**
 * Given a player id, prints to him and at server console, usage for the command "amx_setmod".
 *
 * @param player_id         the player id
 */
public printHelp( player_id )
{
    new formatted_string[ 32 ]

    if( player_id )
    {
        player_id = player_id - TASKID_PRINT_HELP

        new current_print_page_total      = g_current_print_page[ player_id ] * LINES_PER_PAGE
        g_current_print_page[ player_id ] = g_current_print_page[ player_id ] + 1

        DEBUG_LOGGER( 1, "current_print_page_total: %d, g_current_print_page[ player_id ]: %d", \
                current_print_page_total, g_current_print_page[ player_id ] )

        // print the page header
        if( !current_print_page_total )
        {
            for( new i = 0; i < sizeof( g_cmdsAvailables ); i++ )
            {
                client_print( player_id, print_console, g_cmdsAvailables[ i ] )
                DEBUG_LOGGER( 1, g_cmdsAvailables[ i ] )
            }

            set_task( 1.0, "printHelp", player_id + TASKID_PRINT_HELP )
            return
        }

        // print the page body
        if( current_print_page_total - LINES_PER_PAGE < g_modCounter )
        {
            new internal_current_page_limit = 0

            new menu_page_total_int = g_modCounter / LINES_PER_PAGE
            new menu_page_total     = floatround( float( g_modCounter ) / float( LINES_PER_PAGE ), floatround_ceil )

            if( g_modCounter < LINES_PER_PAGE + 3 )
            {
                menu_page_total_int = 1
                menu_page_total     = 1
            }

            client_print( player_id, print_console, "^nPrinting Page: %d of %d",
                    g_current_print_page[ player_id ] - 1,
                    ( g_modCounter % LINES_PER_PAGE < 2 ) ? menu_page_total_int : menu_page_total )

            DEBUG_LOGGER( 1, "^nPrinting Page: %d of %d", \
                    g_current_print_page[ player_id ] - 1, \
                    ( g_modCounter % LINES_PER_PAGE < 2 ) ? menu_page_total_int : menu_page_total )

            for( new i = 3 + current_print_page_total - LINES_PER_PAGE; i <= g_modCounter; i++ )
            {
                ArrayGetString( g_mod_names, i, g_mod_name_temp, charsmax( g_mod_name_temp ) )
                ArrayGetString( g_mod_shortNames, i, g_mod_short_name_temp, charsmax( g_mod_short_name_temp ) )

                formatex( formatted_string, charsmax( formatted_string ), "%s 1", g_mod_short_name_temp )

                client_print( player_id, print_console, "amx_setmod %-22s| to use %s", formatted_string,
                        g_mod_name_temp )

                DEBUG_LOGGER( 1, "amx_setmod %-22s| to use %s", formatted_string, g_mod_name_temp )

                if( internal_current_page_limit++ >= ( LINES_PER_PAGE - 1 )
                    && i < g_modCounter )
                {
                    set_task( 0.5, "printHelp", player_id + TASKID_PRINT_HELP )
                    break
                }
            }
        }

        // Resets the page number as we finished printing everything.
        if( current_print_page_total > g_modCounter )
        {
            g_current_print_page[ player_id ] = 0
        }
    }
    else
    {
        for( new i = 0; i < sizeof( g_cmdsAvailables ); i++ )
        {
            server_print( g_cmdsAvailables[ i ] )
        }

        for( new i = 3; i <= g_modCounter; i++ )
        {
            ArrayGetString( g_mod_names, i, g_mod_name_temp, charsmax( g_mod_name_temp ) )
            ArrayGetString( g_mod_shortNames, i, g_mod_short_name_temp, charsmax( g_mod_short_name_temp ) )

            formatex( formatted_string, charsmax( formatted_string ), "%s 1", g_mod_short_name_temp )
            server_print( "amx_setmod %-22s| to use %s", formatted_string, g_mod_name_temp )
        }

        server_print( "^n" )
    }
}

#if AMXX_VERSION_NUM < 183
public client_disconnect( player_id )
#else
public client_disconnected( player_id )
#endif
{
    remove_task( player_id + TASKID_PRINT_HELP )
}

/**
 * Process the input command "amx_setmod OPITON1 OPITON2".
 *
 * Straight restarting the server ( silent mod ) and configures the mapcycle file if there is one.
 *
 * @param player_id         - will hold the players id who started the command
 * @param level             - will hold the access level of the command
 * @param cid               - will hold the commands internal id
 *
 * @arg firstCommand_lineArgument         the modShortName to enable silently
 * @arg secondCommand_lineArgument        inform to restart the current map "1" or not "0"
 */
public receiveCommandSilent( player_id, level, cid )
{
    //Make sure this user is an admin
    if( !cmd_access( player_id, level, cid, 3 ) )
    {
        return PLUGIN_HANDLED
    }
    new firstCommand_lineArgument            [ SHORT_STRING ]
    new secondCommand_lineArgument        [ SHORT_STRING ]

    read_argv( 1, firstCommand_lineArgument, charsmax( firstCommand_lineArgument ) )
    read_argv( 2, secondCommand_lineArgument, charsmax( secondCommand_lineArgument ) )

    new isTimeToRestart      = equal( secondCommand_lineArgument, "1" )
    g_isTimeTo_changeMapcyle = true

    if( equal( firstCommand_lineArgument, "disable" ) )
    {
        disableMods()
        msgResourceActivated( "disable", isTimeToRestart, false )
    }
    else if( activateMod_byShortName( firstCommand_lineArgument ) )
    {
        g_currentMod_id = 0
        saveCurrentModBy_id( 2 )

        saveCurrentModBy_ShortName( firstCommand_lineArgument             )
        messageModActivated(               firstCommand_lineArgument, isTimeToRestart, false )
    }
    g_isTimeTo_changeMapcyle = false

    return PLUGIN_HANDLED
}

/**
 * A simple instantly server restart.
 */
public restartTheServer()
{
    server_cmd( "restart" )
}

/**
 * Loads the 'currentmod_id.ini' and 'currentmod_shortname.ini', at ".configs/multimod" directory,
 * that stores the current mod actually active and the current mod was activated by
 * silent mode, respectively.
 *
 * If the mod_id stored at 'currentmod_id.ini' is:
 *     1. greater than 0, then, it is any mod saved.
 *     2. 0, then, it is a silent mod is activated.
 *     3. -1, then, the server mods are disabled.
 *
 * When 'currentmod_id.ini' is 0, the 'currentmod_shortname.ini' defines the current mod.
 * When 'currentmod_id.ini' is anything different than 0, the 'currentmod_id.ini' has the current mod.
 */
public loadCurrentMod()
{
    new currentModCode
    new unused_lenghtInteger

    new currentModCode_String[ SHORT_STRING ]
    new currentMod_shortName[ SHORT_STRING ]

    // normal mod activation (laud, i.e., messages sounds, announcements)
    if( file_exists( g_currentMod_id_filePath ) )
    {
        read_file(   g_currentMod_id_filePath, 0, currentModCode_String,
                charsmax( currentModCode_String ), unused_lenghtInteger )

        currentModCode = str_to_num( currentModCode_String )
    }
    else
    {
        currentModCode = -1
        write_file( g_currentMod_id_filePath,    "-1"     )
    }

    // silent mod activation, i.e., without any notice.
    if( file_exists( g_currentMod_shortName_filePath ) )
    {
        read_file( g_currentMod_shortName_filePath, 0, currentMod_shortName,
                charsmax( currentMod_shortName ), unused_lenghtInteger )
    }
    else
    {
        currentModCode = -1
        write_file( g_currentMod_shortName_filePath, "" )
    }

    configureMod_byModCode( currentModCode, currentMod_shortName )
}

/**
 * Configure the current mod action after it was loaded from the settings file at map server start.
 *
 * @param currentModCode             the code loaded from the current mod file. If it is:
 *                                       1. -1, then, there is no mod active.
 *                                       2. 0, then, the current mod was activated by silent mode.
 *
 * @param currentMod_shortName[]     the current mod short name loaded from the
 *                                   current mod silent file.
 */
public configureMod_byModCode( currentModCode, currentMod_shortName[] )
{
    DEBUG_LOGGER( 1,  "^n^ncurrentModCode: %d | currentMod_shortName: %s^n", \
            currentModCode, currentMod_shortName )

    switch( currentModCode )
    {
        case -1:
        {
            g_currentMod_id = 2

            ArrayGetString( g_mod_shortNames, g_currentMod_id, g_mod_short_name_temp, charsmax( g_mod_short_name_temp ) )
            setCurrentMod_atLocalInfo( g_mod_short_name_temp )
        }
        case 0:
        {
            g_currentMod_id = 0
            setCurrentMod_atLocalInfo( currentMod_shortName )
        }
        default:
        {
            g_currentMod_id = currentModCode + 2

            ArrayGetString( g_mod_shortNames, g_currentMod_id, g_mod_short_name_temp, charsmax( g_mod_short_name_temp ) )
            setCurrentMod_atLocalInfo( g_mod_short_name_temp )
        }
    }
}

/**
 * Configure the current mod action after the next mod is voted.
 *
 * @param mostVoted_modID       the mod most voted during the vote mod:
 *                                  If 1, is to keep the current mod
 *                                  If 2, is to disable the current mod.
 */
public configureMod_byModID( mostVoted_modID )
{
    g_currentMod_id = mostVoted_modID

    switch( mostVoted_modID )
    {
        case 1:
        {
            DEBUG_LOGGER( 1, "^nAT configureMod_byModID, we are keeping the current mod" )
        }
        case 2:
        {
            disableMods()
        }
        default:
        {
            saveCurrentModBy_id( mostVoted_modID )
            ArrayGetString( g_mod_shortNames, mostVoted_modID, g_mod_short_name_temp, charsmax( g_mod_short_name_temp ) )
            activateMod_byShortName( g_mod_short_name_temp )
        }
    }
}

/**
 * Saves the last mod activated at localinfo "amx_lastmod" and sets the localinfo
 * "amx_correntmod" and the global variable "g_currentMod_shortName" to the mod
 * short name currently activated.
 *
 * @param currentMod_shortName          the current just activated mod short name.
 */
public setCurrentMod_atLocalInfo( currentMod_shortName[] )
{
    retrievesCurrentMod_atLocalInfo()

    configureMapcycle( currentMod_shortName )

    set_localinfo( "amx_lastmod", g_currentMod_shortName )
    set_localinfo( "amx_correntmod", currentMod_shortName )

    copy( g_currentMod_shortName, charsmax( g_currentMod_shortName ), currentMod_shortName )
}

/**
 * Retrieves the localinfo "amx_correntmod" as a mod short name to the global variable
 * "g_currentMod_shortName".
 */
public retrievesCurrentMod_atLocalInfo()
{
    get_localinfo( "amx_correntmod", g_currentMod_shortName, charsmax( g_currentMod_shortName ) );
}

/**
 * Given a mod_id_number, salves it to file "currentmod_id.ini", at multimod directory.
 *
 * @param mod_id_number    the mod id. If the mod_id_number is:
 *                             1. greater than 2, it is any mod.
 *                             2. 2, then, is a silent mod activated.
 *                             3. 1, then, the mods are disabled.
 */
saveCurrentModBy_id( mod_id_number )
{
    new mod_idString[ SHORT_STRING ]

    if( file_exists( g_currentMod_id_filePath ) )
    {
        delete_file( g_currentMod_id_filePath )
    }

    formatex( mod_idString, charsmax( mod_idString ), "%d", mod_id_number - 2 )

    write_file( g_currentMod_id_filePath, mod_idString )
}

/**
 * Saves the current silent mod activated to file "currentmod_shortname.ini", at multimod directory.
 *
 * @param modShortName[]       the mod short name. Ex: surf.
 */
public saveCurrentModBy_ShortName( modShortName[] )
{
    if( file_exists( g_currentMod_shortName_filePath ) )
    {
        delete_file( g_currentMod_shortName_filePath )
    }
    write_file( g_currentMod_shortName_filePath, modShortName )
}

/**
 * Makes at votemod menu, display the first mod as the option: "Keep Current Mod". And at
 * votemod menu, display the second mod as the option: "No mod - Disable Mod".
 */
public build_first_mods()
{
    g_modCounter = g_modCounter + 2

    ArrayPushString( g_mod_names, "Silent Mod Currently" )
    ArrayPushString( g_mod_shortNames, "silentMod" )

    ArrayPushString( g_mod_names, "Extend Current Mod" )
    ArrayPushString( g_mod_shortNames, "extendCurrent" )

    ArrayPushString( g_mod_names, "Disable Current Mod" )
    ArrayPushString( g_mod_shortNames, "disableMod" )
}

/**
 * Loads the config file "voting_list.ini" and all mods stored there.
 */
public load_votingList()
{
    new currentLine         [ LONG_STRING ]
    new currentLine_splited [ SHORT_STRING ]
    new unusedLast_string   [ SHORT_STRING ]

    new votingList_filePointer = fopen( g_votingList_filePath, "rt" )

    while( !feof( votingList_filePointer ) )
    {
        fgets( votingList_filePointer, currentLine, charsmax( currentLine ) )
        trim( currentLine )

        // skip commentaries while reading file
        if( !currentLine[ 0 ]
            || currentLine[ 0 ] == ';'
            || ( currentLine[ 0 ] == '/'
                 && currentLine[ 1 ] == '/' ) )
        {
            continue
        }

        if( currentLine[ 0 ] == '[' )
        {
            g_modCounter++

            // remove line delimiters [ and ]
            replace_all( currentLine, charsmax( currentLine ), "[", "" )
            replace_all( currentLine, charsmax( currentLine ), "]", "" )

            // broke the current config line, in modname ( g_mod_name_temp ), modtag ( g_mod_short_name_temp )
            strtok( currentLine, g_mod_name_temp, charsmax( g_mod_name_temp ), currentLine_splited,
                    charsmax( currentLine_splited ), ':', 0 )
            strtok( currentLine_splited, g_mod_short_name_temp, charsmax( g_mod_short_name_temp ), unusedLast_string,
                    charsmax( unusedLast_string ), ':', 0 )

            // stores at memory the modname and the modShortName
            ArrayPushString( g_mod_names, g_mod_name_temp )
            ArrayPushString( g_mod_shortNames, g_mod_short_name_temp )

        #if IS_DEBUG_ENABLED > 0
            ArrayGetString( g_mod_names, g_modCounter, g_mod_name_temp, charsmax( g_mod_name_temp ) )
            DEBUG_LOGGER( 1, "[AMX MOD Loaded] %d - %s",  g_modCounter - 2, g_mod_name_temp )

            if( g_debug_level & 2 )
            {
                new mapcycle_filePath       [ SHORT_STRING ]
                new config_filePath         [ SHORT_STRING ]
                new plugin_filePath         [ SHORT_STRING ]
                new message_filePath        [ SHORT_STRING ]
                new messageResource_filePath[ SHORT_STRING ]
                new lateConfig_filePath     [ SHORT_STRING ]

                mapcycle_pathCoder( g_mod_short_name_temp, mapcycle_filePath, charsmax( mapcycle_filePath ) )
                config_pathCoder( g_mod_short_name_temp, config_filePath, charsmax( config_filePath ) )
                plugin_pathCoder( g_mod_short_name_temp, plugin_filePath, charsmax( plugin_filePath ) )
                message_pathCoder( g_mod_short_name_temp, message_filePath, charsmax( message_filePath ) )

                messageResource_pathCoder( g_mod_short_name_temp, messageResource_filePath,
                        charsmax( messageResource_filePath ) )

                lateConfig_pathCoder( g_mod_short_name_temp, lateConfig_filePath, charsmax( lateConfig_filePath ) )

                DEBUG_LOGGER( 1, "[AMX MOD Loaded] %s", g_mod_short_name_temp )
                DEBUG_LOGGER( 1, "[AMX MOD Loaded] %s", mapcycle_filePath )
                DEBUG_LOGGER( 1, "[AMX MOD Loaded] %s", plugin_filePath )
                DEBUG_LOGGER( 1, "[AMX MOD Loaded] %s", config_filePath )
                DEBUG_LOGGER( 1, "[AMX MOD Loaded] %s", message_filePath )
                DEBUG_LOGGER( 1, "[AMX MOD Loaded] %s", lateConfig_filePath )
                DEBUG_LOGGER( 1, "[AMX MOD Loaded] %s^n", messageResource_filePath )
            }
        #endif
        }
    }
    fclose( votingList_filePointer )
}

/**
 * Hard code the message recourse file location at the string parameter messageResource_filePath[].
 * These are the resource messages files at ".configs/multimod/" directory. executed when a
 *   resource as disable, is activated by the command "amx_setmod".
 *
 * @param modShortName[]                  the mod short name without extension. Ex: surf
 * @param messageResource_filePath[]      the message resource file path containing its file extension.
 *                                        Ex: mapcycles/surf.txt
 *
 * @param stringReturnSize         the messageResource_filePath[] charsmax value.
 */
public messageResource_pathCoder( resourceName[], messageResource_filePath[], stringReturnSize )
{
    formatex( messageResource_filePath, stringReturnSize, "%s/multimod/%s.cfg", g_configFolder, resourceName )
}

/**
 * Hard code the message file location at the string parameter message_filePath[].
 * These are the messages files at ".configs/multimod/msg/" directory, executed when a
 *   mod is activated by the command "amx_setmod".
 *
 * @param modShortName[]             the mod short name without extension. Ex: surf
 * @param message_filePath[]         the message file path containing its file extension. Ex: mapcycles/surf.txt
 * @param stringReturnSize           the message_filePath[] charsmax value.
 */
public message_pathCoder( modShortName[], message_filePath[], stringReturnSize )
{
    formatex( message_filePath, stringReturnSize, "%s/multimod/msg/%s.cfg", g_configFolder, modShortName )
}

/**
 * Hard code the plugin file location at the string parameter plugin_filePath[].
 * These are the mods plugins files, to be activated at ".configs/multimod/plugins/" directory.
 *
 * @param modShortName[]           the mod short name without extension. Ex: surf
 * @param plugin_filePath[]        the plugin file path containing its file extension. Ex: mapcycles/surf.txt
 * @param stringReturnSize         the plugin_filePath[] charsmax value.
 */
public plugin_pathCoder( modShortName[], plugin_filePath[], stringReturnSize )
{
    formatex( plugin_filePath, stringReturnSize, "%s/multimod/plugins/%s.ini", g_configFolder, modShortName )
}

/**
 * Hard code the config file location at the string parameter config_filePath[].
 * These are the mods configuration files, to be loaded at ".configs/multimod/cfg/" directory.
 *
 * @param modShortName[]          the mod short name without extension. Ex: surf
 * @param config_filePath[]       the config file path containing its file extension. Ex: mapcycles/surf.txt
 * @param stringReturnSize        the config_filePath[] charsmax value.
 */
public config_pathCoder( modShortName[], config_filePath[], stringReturnSize )
{
    formatex( config_filePath, stringReturnSize, "%s/multimod/cfg/%s.cfg", g_configFolder, modShortName )
}

/**
 * Hard code the late config file location at the string parameter lateConfig_filePath[].
 * These are the mods configuration files, to be loaded at ".configs/multimod/latecfg/" directory.
 * These files are only executed once when the mod is deactivated.
 *
 * @param modShortName[]              the mod short name without extension. Ex: surf
 * @param lateConfig_filePath[]       the late config file path containing its file extension. Ex: mapcycles/surf.txt
 * @param stringReturnSize            the lateConfig_filePath[] charsmax value.
 */
public lateConfig_pathCoder( modShortName[], lateConfig_filePath[], stringReturnSize )
{
    formatex( lateConfig_filePath, stringReturnSize, "%s/multimod/latecfg/%s.cfg", g_configFolder, modShortName )
}

/**
 * Hard code the mapcycle file location at the string parameter mapcycle_filePath[].
 * These are the mods mapcycles files at ".gamemod/mapcycles/" directory, to be used when a mod is
 *   activated.
 *
 * @param modShortName[]               the mod short name without extension. Ex: surf
 * @param mapcycle_filePath[]          the mapcycle file path containing its file extension. Ex: mapcycles/surf.txt
 * @param stringReturnSize             the mapcycle_filePath[] charsmax value.
 */
public mapcycle_pathCoder( modShortName[], mapcycle_filePath[], stringReturnSize )
{
    formatex( mapcycle_filePath, stringReturnSize, "mapcycles/%s.txt", modShortName )
}

/**
 * Configure which map cycles the server will use at start up and after each mod is loaded.
 *
 * @param modShortName[] the mod short name to configure is mapcycle. Ex: csdm
 */
configureMapcycle( modShortName[] )
{
    new mapcycle_filePath[ SHORT_STRING ]

    mapcycle_pathCoder( modShortName, mapcycle_filePath, charsmax( mapcycle_filePath ) )

    configMapManager( mapcycle_filePath )
    configDailyMaps( mapcycle_filePath )
}

/**
 * Makes the autoswitch between mapchooser and galileo_reloaded. If both are
 * active, prevails galileo_reloaded.
 */
public switchMapManager()
{
    if( is_plugin_loaded( "Galileo" ) != -1 )
    {
        g_mapManagerType = 2
    }
    else if( find_plugin_byfile( "Nextmap Chooser" ) != -1 )
    {
        g_mapManagerType = 1
    }
}

/**
 * Setup the map manager to work with votemod menu at Silent mode. That is, configures
 * the compatibility with galileo_reloaded, multimod_mapchooser and daily_maps, because now
 * there is no mod_id_number, hence because the mod is not loaded from the mod file configs.
 *
 * @param mapcycle_filePath[]         the mapcycle file name with extension and path. Ex: mapcycles/surf.txt
 */
public configMapManager( mapcycle_filePath[] )
{
    if( file_exists( mapcycle_filePath ) )
    {
        switch( g_mapManagerType )
        {
            case 1:
            {
                if( callfunc_begin( "plugin_init", "multimod_mapchooser.amxx" ) == 1 )
                {
                    callfunc_end()
                }
                else
                {
                    log_error( AMX_ERR_NOTFOUND, "Error at configMapManager!! multimod_mapchooser.amxx NOT FOUND!^n" )
                    print_at_console_to_all( "Error at configMapManager!! multimod_mapchooser.amxx NOT FOUND!^n" )
                }
            }
            case 2:
            {
                new galileo_mapfile = get_cvar_pointer( "gal_vote_mapfile" )

                if( galileo_mapfile )
                {
                    set_pcvar_string( galileo_mapfile, mapcycle_filePath )
                }
            }
        }
    }

    if( file_exists( mapcycle_filePath ) )
    {
        set_pcvar_string( gp_mapcyclefile, mapcycle_filePath )
    }

    server_exec()
}

/**
 * Change the game global variable at localinfo isFirstTime_serverLoad to 1 or 2, after
 * the first map load. It is to avoid mapcycle re-change, causing the first mapcycle
 * map, always being the nextmap.
 *
 * The localinfo isFirstTime_serverLoad as 1, is used by multimod_manager.sma,
 * to know if there is a game mod mapcycle file being used.
 *
 * The localinfo isFirstTime_serverLoad as 2, is used by multimod_daily_changer.sma,
 * to know if its can define which one is the mapcycle.
 *
 * @param mapcycle_filePath[]        the mapcycle file name with its extension and path. Ex: mapcycles/surf.txt
 */
public configDailyMaps( mapcycle_filePath[] )
{
    new isFirstTime[ 32 ]

    get_localinfo(       "isFirstTime_serverLoad", isFirstTime, charsmax( isFirstTime ) );
    g_isFirstTime_serverLoad = str_to_num( isFirstTime )

    if( g_isFirstTime_serverLoad  == 0 )
    {
        new currentMapcycle_filePath[ SHORT_STRING ]

        g_isTimeTo_changeMapcyle = true

        get_pcvar_string( gp_mapcyclefile, currentMapcycle_filePath, charsmax( currentMapcycle_filePath ) )

        set_localinfo(   "firstMapcycle_loaded",         currentMapcycle_filePath )
    }

#if IS_DEBUG_ENABLED > 0
    DEBUG_LOGGER( 1, "( Inside ) configDailyMaps()" )
    DEBUG_LOGGER( 1, "g_isFirstTime_serverLoad is: %d",         g_isFirstTime_serverLoad         )
    DEBUG_LOGGER( 1, "g_isTimeTo_changeMapcyle is: %d",         g_isTimeTo_changeMapcyle         )
    DEBUG_LOGGER( 1, "file_exists( mapcycle_filePath ) is: %d", file_exists( mapcycle_filePath ) )
    DEBUG_LOGGER( 1, "mapcycle_filePath is: %s^n",              mapcycle_filePath                )
#endif

    if( g_isTimeTo_changeMapcyle )
    {
        g_isTimeTo_changeMapcyle = false

        if( file_exists( mapcycle_filePath ) )
        {
            set_pcvar_string(   gp_mapcyclefile,           mapcycle_filePath )
            set_localinfo(  "isFirstTime_serverLoad",         "1"                 )
            server_exec()
        }
        else
        {
            set_localinfo( "isFirstTime_serverLoad", "2" );
        }
    }
}

/**
 * Deactivate any loaded/active mod.
 */
public disableMods()
{
    DEBUG_LOGGER( 1, "^n AT disableMods, the g_currentMod_shortName is: %s^n", g_currentMod_shortName )

    if( file_exists( g_currentMod_id_filePath ) )
    {
        delete_file( g_currentMod_id_filePath )
    }

    if( file_exists( g_masterConfig_filePath ) )
    {
        delete_file( g_masterConfig_filePath )
    }

    if( file_exists( g_currentMod_shortName_filePath ) )
    {
        delete_file( g_currentMod_shortName_filePath )
    }

    if( file_exists( g_masterPlugin_filePath ) )
    {
        delete_file( g_masterPlugin_filePath )
    }

    write_file( g_masterConfig_filePath,                     g_alertMultiMod )
    write_file( g_masterPlugin_filePath,                                     g_alertMultiMod )
    write_file( g_currentMod_shortName_filePath,         ""                             )
    write_file( g_currentMod_id_filePath,                         "-1"                             )
}

/**
 * Actives a mod by its short name. If the the short name plugin file exists and
 * change the current mod to 'Keep Current Mod'.
 *
 * @param modShortName[]         the mod short name to active. Ex: surf
 *
 * @throws error                 any configuration file is missing!
 */
public activateMod_byShortName( modShortName[] )
{
    new plugin_filePath[ LONG_STRING ]

    plugin_pathCoder( modShortName, plugin_filePath, charsmax( plugin_filePath ) )

    if( file_exists( plugin_filePath ) )
    {
        new config_filePath[ LONG_STRING ]

        config_pathCoder( modShortName, config_filePath, charsmax( config_filePath ) )

        if( file_exists( config_filePath ) )
        {
            copyFiles( config_filePath, g_masterConfig_filePath, g_alertMultiMod )
        }
        copyFiles( plugin_filePath, g_masterPlugin_filePath, g_alertMultiMod )

        configureMapcycle( modShortName )

        print_at_console_to_all( "[AMX MOD Loaded] Setting multimod to %s", modShortName )

        return true
    }
    else
    {
        log_error( AMX_ERR_NOTFOUND, "Error at activateMod_byShortName!! plugin_filePath: %s", plugin_filePath )
        print_at_console_to_all( "Error at activateMod_byShortName!! plugin_filePath: %s", plugin_filePath )
    }

    DEBUG_LOGGER( 1, "^n activateMod_byShortName, plugin_filePath: %s^n", plugin_filePath )

    return false
}

/**
 * Copy the sourceFilePath to destinationFilePath, replacing the existing file destination and
 * adding to its beginning the contents of the String inicialFileText.
 *
 * @param sourceFilePath[]              the source file
 * @param destinationFilePath[]         the destination file
 * @param inicialFileText[]             an additional text
 */
public copyFiles( sourceFilePath[], destinationFilePath[], inicialFileText[] )
{
    if( file_exists( destinationFilePath ) )
    {
        delete_file( destinationFilePath )
    }

    write_file( destinationFilePath, inicialFileText, 0 )

    new sourceFilePathPointer = fopen( sourceFilePath, "rt" )
    new Text[ 512 ];

    while( !feof( sourceFilePathPointer ) )
    {
        fgets( sourceFilePathPointer, Text, sizeof( Text ) - 1 )
        trim( Text )
        write_file( destinationFilePath, Text, -1 )
    }

    fclose( sourceFilePathPointer )
}

/**
 * Copies the contents of sourceFilePath to the beginning of destinationFilePath
 *
 * @param sourceFilePath[]            the source file
 * @param destinationFilePath[]       the destination file
 */
public copyFiles2( sourceFilePath[], destinationFilePath[] )
{
    new sourceFilePathPointer = fopen( sourceFilePath, "rt" )
    new Text[ 512 ];

    while( !feof( sourceFilePathPointer ) )
    {
        fgets( sourceFilePathPointer, Text, sizeof( Text ) - 1 )
        trim( Text )
        write_file( destinationFilePath, Text, -1 )
    }

    fclose( sourceFilePathPointer )
}

/**
 * Displays a message to all server players about a command line Mod active with "amx_setmod".
 *
 * @param modShortName[]                 the activated mod mod long name. Ex: surf
 * @param isTimeToRestart                inform to restart the server
 * @param isTimeTo_executeMessage        instruct to execute the message activation file. Ex: "msg/csdm.cfg"
 */
public messageModActivated( modShortName[], isTimeToRestart, isTimeTo_executeMessage )
{
    client_print_color_internal( 0, "^1The mod ( ^4%s^1 ) will be activated at ^4next server restart^1.", modShortName )

    if( isTimeToRestart )
    {
        new message_filePath[ LONG_STRING ]

        message_pathCoder( modShortName, message_filePath, charsmax( message_filePath ) )

        if( file_exists( message_filePath )
            && isTimeTo_executeMessage )
        {
            server_cmd( "exec %s", message_filePath )
        }
        else
        {
            // freeze the game and show the scoreboard
            message_begin( MSG_ALL, SVC_INTERMISSION );
            message_end();

            set_task( 5.0, "restartTheServer" );
        }
    }
}

/**
 * Displays a message to all server player about a command line Resource active with "amx_setmod".
 * Its must match the file msg name at "multimod" directory.
 *
 * @param resourceName[]               the name of the activated resource. Ex: disable
 * @param isTimeToRestart              inform to restart the server
 * @param isTimeTo_executeMessage      instruct to execute the message activation file. Ex: "msg/csdm.cfg"
 */
public msgResourceActivated( resourceName[], isTimeToRestart, isTimeTo_executeMessage )
{
    client_print_color_internal( 0, "^1The resource ( ^4%s^1 ) will be activated at ^4next server restart^1.", resourceName )

    if( isTimeToRestart )
    {
        new messageResource_filePath[ LONG_STRING ]

        messageResource_pathCoder( resourceName, messageResource_filePath, charsmax( messageResource_filePath ) )

        if( file_exists( messageResource_filePath )
            && isTimeTo_executeMessage )
        {
            server_cmd( "exec %s", messageResource_filePath )
        }
        else
        {
            // freeze the game and show the scoreboard
            message_begin( MSG_ALL, SVC_INTERMISSION );
            message_end();

            set_task( 5.0, "restartTheServer" );
        }
    }
}

/**
 * Displays a message to a specific server player show the current mod.
 *
 * @param player_id     the player id
 */
public user_currentmod( player_id )
{
    ArrayGetString(               g_mod_names, g_currentMod_id, g_mod_name_temp, charsmax( g_mod_name_temp ) )
    client_print_color_internal( player_id, "^1L%", player_id, "MM_HUDMSG", g_mod_name_temp )

    return PLUGIN_HANDLED
}

/**
 * Called with "say votemod". Checks:
 *     1. If users can invoke voting.
 *     2. If its already voted.
 *
 * @param player_id the player id
 */
public user_votemod( player_id )
{
    if( get_pcvar_num( gp_allowedvote ) )
    {
        ArrayGetString(               g_mod_names, g_currentMod_id, g_mod_name_temp, charsmax( g_mod_name_temp ) )
        client_print_color_internal( player_id, "^1%L", player_id, "MM_VOTEMOD", g_mod_name_temp )

        return PLUGIN_HANDLED
    }
    new Float:elapsedTime = get_pcvar_float( gp_timelimit ) - ( float( get_timeleft() ) / 60.0 )
    new Float:minTime
    minTime = get_pcvar_float( gp_mintime )

    if( elapsedTime < minTime )
    {
        client_print_color_internal( player_id, "^4[AMX MultiMod]^1 %L", player_id, "MM_PL_WAIT",
                floatround( minTime - elapsedTime, floatround_ceil ) )

        return PLUGIN_HANDLED
    }
    new timeleft = get_timeleft()

    if( timeleft < 180 )
    {
        client_print_color_internal( player_id, "^1%L", player_id, "MM_PL_WAIT", timeleft )

        return PLUGIN_HANDLED
    }
    start_vote()
    return PLUGIN_HANDLED
}

public check_task()
{
    new timeleft = get_timeleft()

    if( timeleft < 300
        || timeleft > 330 )
    {
        return
    }
    start_vote()
}

/**
 * Start multi mod voting.
 *
 * If a new voting was invoked:
 *     1. Restart voting count.
 *     2. Restart voting players menu position.
 */
public start_vote()
{
    remove_task( TASK_VOTEMOD )
    remove_task( TASK_CHVOMOD )

    for( new i = 0; i < 33; i++ )
    {
        g_menuPosition[ i ] = 0
    }

    ArrayClear( g_votemodcount )

    for( new i = 0; i < ArraySize( g_mod_names ); i++ )
    {
        ArrayPushCell( g_votemodcount, 0 )
    }

    display_votemod_menu( 0, 0 )
    client_cmd( 0, "spk Gman/Gman_Choose2" )

#if IS_DEBUG_ENABLED > 0
    set_task( 6.0, "check_vote", TASK_CHVOMOD )
#else
    set_task( 30.0, "check_vote", TASK_CHVOMOD )
#endif
}

/**
 * Create the vote mod menu with multiple pages.
 *
 * @param player_id             the player id to display the menu.
 * @param menu_current_page     the number of the current menu page to draw the menu.
 */
public display_votemod_menu( player_id, menu_current_page )
{
    if( menu_current_page < 0 )
    {
        return
    }

    new menu_body[ 1024 ]
    new menu_valid_keys
    new current_write_position
    new current_page_itens
    new g_menusNumber = g_modCounter

    // calculates the g_menu_total_pages
    if( ( g_menusNumber % MENU_ITEMS_PER_PAGE ) > 0 )
    {
        g_menu_total_pages = ( g_menusNumber / MENU_ITEMS_PER_PAGE ) + 1
    }
    else
    {
        g_menu_total_pages = ( g_menusNumber / MENU_ITEMS_PER_PAGE )
    }

    // calculates the Menu titles
    if( g_coloredmenus )
    {
        current_write_position = formatex( menu_body, charsmax( menu_body ), "\y%L: \R%d/%d\w^n^n",
                player_id, "MM_CHOOSE", menu_current_page + 1, g_menu_total_pages )
    }
    else
    {
        current_write_position = formatex( menu_body, charsmax( menu_body ), "%L: %d/%d^n^n",
                player_id, "MM_CHOOSE", menu_current_page + 1, g_menu_total_pages )
    }

    // calculates the the number of current_page_itens
    if( g_menu_total_pages == menu_current_page + 1 )
    {
        current_page_itens = g_menusNumber % MENU_ITEMS_PER_PAGE
    }
    else
    {
        current_page_itens = MENU_ITEMS_PER_PAGE
    }

    // calculates the the current page menu body
    new for_index = 0
    new mod_vote_id

    for( new vote_mod_code = menu_current_page * 10;
         vote_mod_code < menu_current_page * 10 + current_page_itens; vote_mod_code++ )
    {
        mod_vote_id = convert_octal_to_decimal( vote_mod_code )

        ArrayGetString( g_mod_names, mod_vote_id + 1, g_mod_name_temp, charsmax( g_mod_name_temp ) )

        current_write_position += formatex( menu_body[ current_write_position ],
                sizeof( menu_body ) - current_write_position, "%d. %s^n", for_index + 1, g_mod_name_temp )

        DEBUG_LOGGER( 4, "( inside ) display_votemod_menu()| mod_vote_id:%d", mod_vote_id )
        for_index++
    }

    // create valid keys ( 0 to 9 )
    menu_valid_keys = MENU_KEY_0

    for( new i = 0; i < 9; i++ )
    {
        menu_valid_keys |= ( 1 << i )
    }

    menu_valid_keys |= MENU_KEY_9

    // calculates the final page buttons
    if( menu_current_page )
    {
        if( g_menu_total_pages == menu_current_page + 1 )
        {
            current_write_position += formatex( menu_body[ current_write_position ],
                    sizeof( menu_body ) - current_write_position, "^n0. Back" )
        }
        else
        {
            current_write_position += formatex( menu_body[ current_write_position ],
                    sizeof( menu_body ) - current_write_position, "^n9. More...^n0. Back" )
        }
    }
    else
    {
        if( g_menu_total_pages != menu_current_page + 1 )
        {
            current_write_position += formatex( menu_body[ current_write_position ],
                    sizeof( menu_body ) - current_write_position, "^n9. More...^n" )
        }
    }

#if IS_DEBUG_ENABLED > 0
    new debug_player_name[ 64 ]

    get_user_name( player_id, debug_player_name, 63 )

    DEBUG_LOGGER( 1, "Player: %s^nMenu body %s ^nMenu name: %s ^nMenu valid keys: %i", \
            debug_player_name, menu_body, g_menuname, menu_valid_keys )

    show_menu( player_id, menu_valid_keys, menu_body, 5, g_menuname )
#else
    show_menu( player_id, menu_valid_keys, menu_body, 25, g_menuname )
#endif
}

/**
 * Given a vote_mod_code ( octal number ), calculates and return the mod internal id
 * ( decimal number ).
 */
stock convert_octal_to_decimal( octal_number )
{
    new decimal = 0
    new i       = 0
    new remainder

    while( octal_number != 0 )
    {
        remainder     = octal_number % 10
        octal_number /= 10
        decimal      += remainder * power( 8, i );
        ++i
    }
    return decimal;
}

/**
 * Compute a player mod vote.
 *
 * @param player_id     the player id
 * @param key           the player pressed/option key.
 */
public player_vote( player_id, key )
{
    DEBUG_LOGGER( 4, "Key before switch: %d", key )

    /* Well, I dont know why, but it doesnt even matter, how hard you try...
     * You press the key 0, you gets 9 here. ...
     * So here, i made the switch back.  */
    switch( key )
    {
        case 9: key = 0
        case 0: key = 1
        case 1: key = 2
        case 2: key = 3
        case 3: key = 4
        case 4: key = 5
        case 5: key = 6
        case 6: key = 7
        case 7: key = 8
        case 8: key = 9
    }

    DEBUG_LOGGER( 4, "Key after switch: %d", key )

    if( key == 9 )
    {
        if( g_menuPosition[ player_id ] + 1 != g_menu_total_pages )
        {
            display_votemod_menu( player_id, ++g_menuPosition[ player_id ] )
        }
        else
        {
            display_votemod_menu( player_id, g_menuPosition[ player_id ] )
        }
    }
    else
    {
        if( key == 0 )
        {
            if( g_menuPosition[ player_id ] != 0 )
            {
                display_votemod_menu( player_id, --g_menuPosition[ player_id ] )
            }
            else
            {
                display_votemod_menu( player_id, g_menuPosition[ player_id ] )
            }
        }
        else
        {
            new mod_vote_id = get_mod_vote_id( g_menuPosition[ player_id ], key )

            if( mod_vote_id <= g_modCounter )
            {
                new player_name[ SHORT_STRING ]

                get_user_name(  player_id, player_name, charsmax( player_name ) )
                ArrayGetString( g_mod_names, mod_vote_id, g_mod_name_temp, charsmax( g_mod_name_temp ) )

                client_print_color_internal( 0, "^1%L", LANG_PLAYER, "X_CHOSE_X", player_name, g_mod_name_temp )
                DEBUG_LOGGER( 1, "^1%L", player_id, "X_CHOSE_X", player_name, g_mod_name_temp )

                new current_votes = ArrayGetCell( g_votemodcount, mod_vote_id )

                ArraySetCell( g_votemodcount, mod_vote_id, current_votes + 1 )
            }
            else
            {
                display_votemod_menu( player_id, g_menuPosition[ player_id ] )
            }
        }
    }
}

/**
 * Given a current_menu_page and a current_pressed_key, returns the internal vote mod id.
 *
 * @param current_menu_page        the current page of player vote menu.
 * @param current_pressed_key      the key pressed by the player to vote.
 */
public get_mod_vote_id( current_menu_page, current_pressed_key )
{
    new vote_mod_code = current_menu_page * 10 + current_pressed_key
    new mod_vote_id   = convert_octal_to_decimal( vote_mod_code )

    return mod_vote_id
}

/**
 * Start computing the mod voting results.
 */
public check_vote()
{
    new mostVoted_modID = 1
    new totalVotes

    for( new possible_most_voted_index = 0; possible_most_voted_index <= g_modCounter;
         possible_most_voted_index++ )
    {
        g_dynamic_array_size_temp = ArrayGetCell( g_votemodcount, possible_most_voted_index )

        if( ArrayGetCell( g_votemodcount, mostVoted_modID ) < g_dynamic_array_size_temp )
        {
            mostVoted_modID = possible_most_voted_index
        }

        totalVotes = totalVotes + g_dynamic_array_size_temp

        DEBUG_LOGGER( 1, "( inside ) check_vote()| totalVotes:%d, g_dynamic_array_size_temp: %d", \
                totalVotes, g_dynamic_array_size_temp )
    }
    displayVoteResults( mostVoted_modID, totalVotes )
}

/**
 * Calculates the minimum votes required and print to server users the mod voting results.
 *
 * @param mostVoted_modID     the most voted mod id.
 * @param totalVotes          the number total of votes.
 */
public displayVoteResults( mostVoted_modID, totalVotes )
{
    new playerMin = players_currently_playing( 0.3 )

    ArrayGetString( g_mod_names, mostVoted_modID, g_mod_name_temp, charsmax( g_mod_name_temp ) )

    if( totalVotes > playerMin )
    {
        g_isTimeTo_changeMapcyle = true

        configureMod_byModID(       mostVoted_modID    )
        client_print_color_internal( 0,  "^1%L", LANG_PLAYER, "MM_VOTEMOD", g_mod_name_temp )
        server_cmd(        "exec %s", g_votingFinished_filePath )
    }
    else
    {
        client_print_color_internal( 0,  "^1The vote did not reached the ^3required minimum! \
                ^4The next mod remains: %s", g_mod_name_temp )
    }

    print_at_console_to_all( "Total Mod Votes: %d  | Player Min: %d  | Most Voted: %s",
            totalVotes, playerMin, g_mod_name_temp )
}

/**
 * Returns the percent of players playing at game server, skipping bots and spectators.
 *
 * @param percent       a percent of the total playing players, in decimal. Example for 30%: 0.3
 *
 * @return integer      an integer of the parameter percent of players
 */
public players_currently_playing( Float:percent )
{
    new players[ 32 ]
    new players_count
    new count = 0

    // get the players in the server skipping bots
    get_players( players, players_count, "c" )

    for( new i = 0; i < players_count; i++ )
    {
        switch( get_user_team( players[ i ] ) )
        {
            case 1:
            {
                count++ // terror
            }
            case 2:
            {
                count++ // ct
            }
        }
    }
    return floatround( count * percent )
}

/**
 * Displays a message all players and server consoles.
 *
 * @param message[] the text formatting rules to display.
 * @param any the variable number of formatting parameters.
 */
public print_at_console_to_all( message[], any: ... )
{
    static formated_message[ LONG_STRING ]

    vformat( formated_message, charsmax( formated_message ), message, 2 )

    client_print( 0, print_console, formated_message )
    server_print( formated_message )
}

/**
 * Print colored text to a given player_id. It has to be called to each player using its player_id
 * instead of 'LANG_PLAYER' constant. Just use the 'LANG_PLAYER' constant when using this function
 * to display to all players.
 *
 * This includes the code:
 * ConnorMcLeod's [Dyn Native] ColorChat v0.3.2 (04 jul 2013) register_dictionary_colored function:
 *   <a href="https://forums.alliedmods.net/showthread.php?p=851160">ColorChat v0.3.2</a>
 *
 * If you are at the Amx Mod X 1.8.2, you can call this function using the player_id as 0. But it
 * will use more resources to decode its arguments. To be more optimized you should call it to every
 * player on the server, to display the colored message to all players using global scope. Example:
 * @code{.cpp}
 * #if AMXX_VERSION_NUM < 183
 * new g_colored_player_id
 * new g_colored_players_number
 * new g_colored_current_index
 * new g_colored_players_ids[ 32 ]
 * #endif
 *
 * some_function()
 * {
 *     ... some code
 * #if AMXX_VERSION_NUM < 183
 *     get_players( g_colored_players_ids, g_colored_players_number, "ch" );
 *
 *     for( g_colored_current_index = 0; g_colored_current_index < g_colored_players_number;
 *          g_colored_current_index++ )
 *     {
 *         g_colored_player_id = g_colored_players_ids[ g_colored_current_index ]
 *
 *         client_print_color_internal( g_colored_player_id, "^1%L %L %L",
 *                 g_colored_player_id, "LANG_A", g_colored_player_id, "LANG_B",
 *                 g_colored_player_id, "LANG_C", any_variable_used_on_LANG_C )
 *     }
 * #else
 *     client_print_color_internal( 0, "^1%L %L %L", LANG_PLAYER, "LANG_A",
 *             LANG_PLAYER, "LANG_B", LANG_PLAYER, "LANG_C", any_variable_used_on_LANG_C );
 * #endif
 *     ... some code
 * }
 * @endcode
 *
 * If you are at the Amx Mod X 1.8.3 or superior, you can call this function using the player_id
 * as 0, to display the colored message to all players on the server.
 *
 * If you run this function on a Game Mod that do not support colored messages, they will be
 * displayed as normal messages without any errors or bad formats.
 *
 * This allow you to use '!g for green', '!y for yellow', '!t for team' color with LANGs at a
 * register_dictionary_colored file. Otherwise use '^1', '^2', '^3' and '^4'.
 *
 * @param player_id the player id.
 * @param message[] the text formatting rules to display.
 * @param any the variable number of formatting parameters.
 *
 * @see <a href="https://www.amxmodx.org/api/amxmodx/client_print_color">client_print_color</a>
 * for Amx Mod X 1.8.3 or superior.
 */
stock client_print_color_internal( player_id, message[], any: ... )
{
    new formated_message[ COLOR_MESSAGE ]

    if( g_is_color_chat_supported )
    {
#if AMXX_VERSION_NUM < 183
        if( player_id )
        {
            vformat( formated_message, charsmax( formated_message ), message, 3 )
            DEBUG_LOGGER( 64, "( in ) Player_Id: %d, Chat printed: %s", player_id, formated_message )

            PRINT_COLORED_MESSAGE( player_id, formated_message )
        }
        else
        {
            new players_array[ 32 ]
            new players_number;

            get_players( players_array, players_number, "ch" );

            // Figure out if at least 1 player is connected
            // so we don't execute useless code
            if( !players_number )
            {
                DEBUG_LOGGER( 64, "!players_number. players_number = %d", players_number )
                return;
            }

            new player_id;
            new string_index
            new argument_index
            new multi_lingual_constants_number

            new params_number                     = numargs();
            new Array:multi_lingual_indexes_array = ArrayCreate();

            DEBUG_LOGGER( 64, "players_number: %d, params_number: %d", players_number, params_number )

            if( params_number >= 4 ) // ML can be used
            {
                for( argument_index = 2; argument_index < params_number; argument_index++ )
                {
                    DEBUG_LOGGER( 64, "argument_index: %d, getarg(argument_index): %d / %s", \
                            argument_index, getarg( argument_index ), getarg( argument_index ) )

                    // retrieve original param value and check if it's LANG_PLAYER value
                    if( getarg( argument_index ) == LANG_PLAYER )
                    {
                        string_index = 0;

                        // as LANG_PLAYER == -1, check if next param string is a registered language translation
                        while( ( formated_message[ string_index ] =
                                     getarg( argument_index + 1, string_index++ ) ) )
                        {
                        }
                        formated_message[ string_index ] = 0

                        DEBUG_LOGGER( 64, "Player_Id: %d, formated_message: %s, \
                                GetLangTransKey( formated_message ) != TransKey_Bad: %d", \
                                player_id, formated_message, \
                                GetLangTransKey( formated_message ) != TransKey_Bad )

                        DEBUG_LOGGER( 64, "(multi_lingual_constants_number: %d, string_index: %d", \
                                multi_lingual_constants_number, string_index )

                        if( GetLangTransKey( formated_message ) != TransKey_Bad )
                        {
                            // Store that argument as LANG_PLAYER so we can alter it later
                            ArrayPushCell( multi_lingual_indexes_array, argument_index++ );

                            // Update ML array, so we'll know 1st if ML is used,
                            // 2nd how many arguments we have to change
                            multi_lingual_constants_number++;
                        }

                        DEBUG_LOGGER( 64, "argument_index (after ArrayPushCell): %d", argument_index )
                    }
                }
            }

            DEBUG_LOGGER( 64, "(multi_lingual_constants_number: %d", multi_lingual_constants_number )

            for( --players_number; players_number >= 0; players_number-- )
            {
                player_id = players_array[ players_number ];

                if( multi_lingual_constants_number )
                {
                    for( argument_index = 0; argument_index < multi_lingual_constants_number; argument_index++ )
                    {
                        // Set all LANG_PLAYER args to player index ( = player_id )
                        // so we can format the text for that specific player
                        setarg( ArrayGetCell( multi_lingual_indexes_array, argument_index ), _, player_id );

                        DEBUG_LOGGER( 64, "(argument_index: %d, player_id: %d, \
                                ArrayGetCell( multi_lingual_indexes_array, argument_index ): %d", \
                                argument_index, player_id, \
                                ArrayGetCell( multi_lingual_indexes_array, argument_index ) )
                    }
                    vformat( formated_message, charsmax( formated_message ), message, 3 )
                }

                DEBUG_LOGGER( 64, "( in ) Player_Id: %d, Chat printed: %s", player_id, formated_message )
                PRINT_COLORED_MESSAGE( player_id, formated_message )
            }

            ArrayDestroy( multi_lingual_indexes_array );
        }
#else
        vformat( formated_message, charsmax( formated_message ), message, 3 )
        DEBUG_LOGGER( 64, "( in ) Player_Id: %d, Chat printed: %s", player_id, formated_message )

        client_print_color( player_id, print_team_default, formated_message )
#endif
    }
    else
    {
        vformat( formated_message, charsmax( formated_message ), message, 3 )
        DEBUG_LOGGER( 64, "( in ) Player_Id: %d, Chat printed: %s", player_id, formated_message )

        REMOVE_COLOR_TAGS( formated_message )
        client_print( player_id, print_chat, formated_message )
    }

    // this is to show the immediate results, as the plugin is usually controlled by the server
    // or the player console.
    if( player_id )
    {
        client_print( player_id, print_console, formated_message )
    }
    else
    {
        server_print( formated_message )
    }

    DEBUG_LOGGER( 64, "( out ) Player_Id: %d, Chat printed: %s", player_id, formated_message )
}

/**
 * ConnorMcLeod's [Dyn Native] ColorChat v0.3.2 (04 jul 2013) register_dictionary_colored function:
 * <a href="https://forums.alliedmods.net/showthread.php?p=851160">ColorChat v0.3.2</a>
 *
 * @param filename the dictionary file name including its file extension.
 */
stock register_dictionary_colored( const filename[] )
{
    if( !register_dictionary( filename ) )
    {
        return 0;
    }

    new szFileName[ 256 ];
    get_localinfo( "amxx_datadir", szFileName, charsmax( szFileName ) );
    formatex( szFileName, charsmax( szFileName ), "%s/lang/%s", szFileName, filename );
    new fp = fopen( szFileName, "rt" );

    if( !fp )
    {
        log_amx( "Failed to open %s", szFileName );
        return 0;
    }

    new szBuffer[ 512 ], szLang[ 3 ], szKey[ 64 ], szTranslation[ 256 ], TransKey:iKey;

    while( !feof( fp ) )
    {
        fgets( fp, szBuffer, charsmax( szBuffer ) );
        trim( szBuffer );

        if( szBuffer[ 0 ] == '[' )
        {
            strtok( szBuffer[ 1 ], szLang, charsmax( szLang ), szBuffer, 1, ']' );
        }
        else if( szBuffer[ 0 ] )
        {
        #if AMXX_VERSION_NUM < 183
            strbreak( szBuffer, szKey, charsmax( szKey ), szTranslation, charsmax( szTranslation ) );
        #else
            argbreak( szBuffer, szKey, charsmax( szKey ), szTranslation, charsmax( szTranslation ) );
        #endif
            iKey = GetLangTransKey( szKey );

            if( iKey != TransKey_Bad )
            {
                INSERT_COLOR_TAGS( szTranslation )
                AddTranslation( szLang, iKey, szTranslation[ 2 ] );
            }
        }
    }

    fclose( fp );
    return 1;
}
