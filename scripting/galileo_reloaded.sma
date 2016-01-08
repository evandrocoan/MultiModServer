/*********************** Licensing *******************************************************
*
*   Copyright 2008-2010 @ Brad Jones
*   Copyright 2015-2016 @ Addons zz
*
*   Plugin Theard: https://forums.alliedmods.net/showthread.php?t=273019
*
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation; either version 3 of the License, or ( at
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
*****************************************************************************************



*/

#define PLUGIN_VERSION "1.0-3"

#include <amxmodx>
#include <amxmisc>


/** This is to view internal program data while execution. See the function 'debugMesssageLogger(...)'
 * at the end of this file, for more information. Default value: 0  - which is disabled.
 */
#define IS_DEBUG_ENABLED 1

#if IS_DEBUG_ENABLED > 0
    #define DEBUG_LOGGER(%1) debugMesssageLogger( %1 )
    new g_debug_level
#else
    #define DEBUG_LOGGER(%1) //
#endif

#define LONG_STRING       256
#define MAX_COLOR_MESSAGE 192
#define SHORT_STRING      64

#define TASKID_REMINDER                  52691153
#define TASKID_VOTE_MANAGEEND            52691152
#define TASKID_SHOW_LAST_ROUND_HUD       52691052
#define TASKID_EMPTYSERVER               98176977
#define TASKID_START_VOTING_BY_ROUNDS    52691160
#define TASKID_UNLOCK_VOTING             52691163
#define TASKID_VOTE_COUNTDOWNPENDINGVOTE 52691164
#define TASKID_VOTE_HANDLEDISPLAY        52691264
#define TASKID_VOTE_DISPLAY              52691165
#define TASKID_VOTE_EXPIRE               52691166
#define TASKID_DBG_FAKEVOTES             52691167
#define TASKID_VOTE_STARTDIRECTOR        52691168
#define TASKID_MAP_CHANGE                52691169

#define RTV_CMD_STANDARD  1
#define RTV_CMD_SHORTHAND 2
#define RTV_CMD_DYNAMIC   4

#define SOUND_GETREADYTOCHOOSE 1
#define SOUND_COUNTDOWN        2
#define SOUND_TIMETOCHOOSE     4
#define SOUND_RUNOFFREQUIRED   8

#define MAPFILETYPE_SINGLE 1
#define MAPFILETYPE_GROUPS 2

#define SHOWSTATUS_VOTE 1
#define SHOWSTATUS_END  2

#define SHOWSTATUSTYPE_COUNT      1
#define SHOWSTATUSTYPE_PERCENTAGE 2

#define ANNOUNCECHOICE_PLAYERS 1
#define ANNOUNCECHOICE_ADMINS  2

#define MAX_NOMINATION_CNT 5

#define MAX_PREFIX_CNT     32
#define MAX_RECENT_MAP_CNT 16

#define MAX_PLAYER_CNT       33
#define MAX_STANDARD_MAP_CNT 25
#define MAX_MAPNAME_LEN      31
#define MAX_MAPS_IN_VOTE     8
#define MAX_NOM_MATCH_CNT    1000

#define VOTE_IN_PROGRESS 1
#define VOTE_FORCED      2
#define VOTE_IS_RUNOFF   4
#define VOTE_IS_OVER     8
#define VOTE_IS_EARLY    16
#define VOTE_HAS_EXPIRED 32

#define SRV_START_CURRENTMAP 1
#define SRV_START_NEXTMAP    2
#define SRV_START_MAPVOTE    3
#define SRV_START_RANDOMMAP  4

#define LISTMAPS_USERID 0
#define LISTMAPS_LAST   1

#define START_VOTEMAP_MIN_TIME 151
#define START_VOTEMAP_MAX_TIME 129


/**
 * The rounds number before the mp_maxrounds/mp_winlimit to be reached to start the map voting.
 */
#define VOTE_START_ROUNDS 4


/**
 * Start a map voting delayed after the mp_maxrounds or mp_winlimit minimum to be reached.
 */
#define VOTE_START_ROUNDS_DELAY \
    { \
        g_is_maxrounds_vote_map = true; \
        set_task( get_pcvar_num( g_freezetime_pointer ) + 10.0, \
                "start_voting_by_rounds", TASKID_START_VOTING_BY_ROUNDS ); \
    }


/**
 * Determines if it is a end of map vote due time limit or max rounds expiration.
 */
#define IS_FINAL_VOTE \
    ( get_cvar_float( "mp_timelimit" ) < START_VOTEMAP_MIN_TIME ) \
    || ( g_is_maxrounds_vote_map )


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


/**
 * Call the internal function to perform its task and stop the current test execution to avoid
 * double failure at the test control system.
 */
#define SET_TEST_FAILURE(%1) \
    { \
        ( set_test_failure_internal( %1 ) ); \
        return; \
    }


/**
 * Contains all unit tests to execute.
 */
#define ALL_TESTS_TO_EXECUTE \
    { \
        test_register_test(); \
        test_gal_in_empty_cycle1(); \
        test_gal_in_empty_cycle2(); \
        test_gal_in_empty_cycle3(); \
        test_gal_in_empty_cycle4(); \
        test_is_map_extension_allowed1(); \
    }


/**
 * Test unit variables related to debug level 1, displays basic debug messages.
 */
new g_max_delay_result
new g_totalSuccessfulTests
new g_totalFailureTests
new Array: g_tests_idsAndNames
new Array: g_tests_delayed_ids
new Array: g_tests_failure_ids

new bool:g_is_test_changed_cvars

new Float:test_extendmap_max
new Float:test_mp_timelimit


/**
 * Lock the voting to fight concurrency problem between mp_maxrounds, mp_winlimit and mp_timelimit.
 */
new g_is_voting_locked


/**
 * Variables related to debug level 32: displays messages related to the rounds end map voting
 */
new g_originalMaxRounds
new g_originalWinLimit
new Float:g_originalTimelimit

new g_freezetime_pointer
new g_winlimit_pointer;
new g_maxrounds_pointer;

new g_total_rounds_played;
new g_total_terrorists_wins;
new g_total_CT_wins;

new g_is_maxrounds_extend
new g_is_maxrounds_vote_map
new g_isTimeToChangeLevel
new g_is_last_round
new g_isTimeToRestart
new g_isTimeLimitChanged
new g_is_map_extension_allowed


/**
 * Server cvars
 */
new cvar_emptyCycle;
new cvar_unnominateDisconnected;
new cvar_endOnRound
new cvar_endOnRound_msg
new cvar_endOnRound_players
new cvar_voteWeight
new cvar_voteWeightFlags
new cvar_extendmapMax;
new cvar_extendmapStep;
new cvar_extendmapStepRounds;
new cvar_endOfMapVote;
new cvar_emptyWait
new cvar_emptyMapFile
new cvar_rtvWait
new cvar_rtvRatio
new cvar_rtvCommands;
new cvar_cmdVotemap
new cvar_cmdListmaps
new cvar_listmapsPaginate;
new cvar_banRecent
new cvar_banRecentStyle
new cvar_voteDuration;
new cvar_nomMapFile
new cvar_nomPrefixes;
new cvar_nomQtyUsed
new cvar_nomPlayerAllowance;
new cvar_voteExpCountdown
new cvar_voteMapChoiceCnt
new cvar_voteAnnounceChoice
new cvar_voteUniquePrefixes;
new cvar_rtvReminder;
new cvar_srvStart;
new cvar_runoffEnabled
new cvar_runoffDuration;
new cvar_voteStatus
new cvar_voteStatusType;
new cvar_soundsMute;


/**
 * Various Artists
 */
new bool:g_is_supported_color_chat
new bool:g_is_to_cancel_end_vote
new bool:g_isUsingEmptyCycle
new Array: g_emptyCycleMap
new g_emptyMapCnt
new g_cntRecentMap;
new Array:g_nominationMap
new g_nominationMapCnt;
new Array:g_fillerMap;
new Float:g_rtvWait;
new g_rockedVoteCnt;

#if AMXX_VERSION_NUM < 183
new g_user_msgid
#endif

new MENU_CHOOSEMAP[] = "gal_menuChooseMap";
new DIR_CONFIGS[ 128 ];
new DIR_DATA[ 128 ];

new g_totalVoteOptions
new g_totalVoteOptions_temp

new g_choiceMax;
new g_voteStatus
new g_voteDuration
new g_totalVotesCounted;

new CLR_RED[ 3 ];    // \r
new CLR_WHITE[ 3 ];  // \w
new CLR_YELLOW[ 3 ]; // \y
new CLR_GREY[ 3 ];   // \d

new g_refreshVoteStatus = true
new g_voteWeightFlags[ 32 ];
new g_nextmap[ MAX_MAPNAME_LEN + 1 ];
new g_totalVoteAtMapType[ 3 ]
new g_snuffDisplay[ MAX_PLAYER_CNT + 1 ];

new g_mapPrefix[ MAX_PREFIX_CNT ][ 16 ]
new g_mapPrefixCnt = 1;
new g_currentMap[ MAX_MAPNAME_LEN + 1 ]

new g_nomination[ MAX_PLAYER_CNT + 1 ][ MAX_NOMINATION_CNT + 1 ]
new g_nominationCnt
new g_nominationMatchesMenu[ MAX_PLAYER_CNT ];

new g_vote[ 512 ];
new g_arrayOfRunOffChoices[ 2 ];
new bool:g_voted[ MAX_PLAYER_CNT + 1 ] = { true, ... }
new g_arrayOfMapsWithVotesNumber[ MAX_MAPS_IN_VOTE + 1 ];

new bool:g_rockedVote[ MAX_PLAYER_CNT + 1 ]
new g_recentMap[ MAX_RECENT_MAP_CNT ][ MAX_MAPNAME_LEN + 1 ]
new g_mapsVoteMenuNames[ MAX_MAPS_IN_VOTE + 1 ][ MAX_MAPNAME_LEN + 1 ]

new g_menuChooseMap;
new g_isRunOffNeedingKeepCurrentMap = false;

public plugin_init()
{
    register_plugin( "Galileo", PLUGIN_VERSION, "Addons zz/Brad Jones" );
    
    register_dictionary( "common.txt" );
    register_dictionary_colored( "galileo_reloaded.txt" );
    
    g_tests_idsAndNames = ArrayCreate( SHORT_STRING )
    g_tests_delayed_ids = ArrayCreate( 1 )
    g_tests_failure_ids = ArrayCreate( 1 )
    
    register_cvar( "GalileoReloaded", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY );
    register_cvar( "gal_server_starting", "1", FCVAR_SPONLY );
    register_cvar( "gal_debug", "0" );
    
    cvar_extendmapMax        = register_cvar( "amx_extendmap_max", "90" );
    cvar_extendmapStep       = register_cvar( "amx_extendmap_step", "15" );
    cvar_extendmapStepRounds = register_cvar( "amx_extendmap_step_rounds", "30" );
    
    cvar_emptyCycle             = register_cvar( "gal_in_empty_cycle", "0", FCVAR_SPONLY );
    cvar_unnominateDisconnected = register_cvar( "gal_unnominate_disconnected", "0" );
    cvar_endOnRound             = register_cvar( "gal_endonround", "2" );
    cvar_endOnRound_msg         = register_cvar( "gal_endonround_msg", "1" );
    cvar_endOnRound_players     = register_cvar( "gal_endonround_players", "1" );
    cvar_voteWeight             = register_cvar( "gal_vote_weight", "1" );
    cvar_voteWeightFlags        = register_cvar( "gal_vote_weightflags", "y" );
    cvar_cmdVotemap             = register_cvar( "gal_cmd_votemap", "0" );
    cvar_cmdListmaps            = register_cvar( "gal_cmd_listmaps", "2" );
    cvar_listmapsPaginate       = register_cvar( "gal_listmaps_paginate", "10" );
    cvar_banRecent              = register_cvar( "gal_banrecent", "3" );
    cvar_banRecentStyle         = register_cvar( "gal_banrecentstyle", "1" );
    cvar_endOfMapVote           = register_cvar( "gal_endofmapvote", "1" );
    cvar_emptyWait              = register_cvar( "gal_emptyserver_wait", "0" );
    cvar_emptyMapFile           = register_cvar( "gal_emptyserver_mapfile", "" );
    cvar_srvStart               = register_cvar( "gal_srv_start", "0" );
    cvar_rtvCommands            = register_cvar( "gal_rtv_commands", "3" );
    cvar_rtvWait                = register_cvar( "gal_rtv_wait", "10" );
    cvar_rtvRatio               = register_cvar( "gal_rtv_ratio", "0.60" );
    cvar_rtvReminder            = register_cvar( "gal_rtv_reminder", "2" );
    cvar_nomPlayerAllowance     = register_cvar( "gal_nom_playerallowance", "2" );
    cvar_nomMapFile             = register_cvar( "gal_nom_mapfile", "mapcycle" );
    cvar_nomPrefixes            = register_cvar( "gal_nom_prefixes", "1" );
    cvar_nomQtyUsed             = register_cvar( "gal_nom_qtyused", "0" );
    cvar_voteDuration           = register_cvar( "gal_vote_duration", "15" );
    cvar_voteExpCountdown       = register_cvar( "gal_vote_expirationcountdown", "1" );
    cvar_voteMapChoiceCnt       = register_cvar( "gal_vote_mapchoices", "5" );
    cvar_voteAnnounceChoice     = register_cvar( "gal_vote_announcechoice", "1" );
    cvar_voteStatus             = register_cvar( "gal_vote_showstatus", "1" );
    cvar_voteStatusType         = register_cvar( "gal_vote_showstatustype", "2" );
    cvar_voteUniquePrefixes     = register_cvar( "gal_vote_uniqueprefixes", "0" );
    cvar_runoffEnabled          = register_cvar( "gal_runoff_enabled", "0" );
    cvar_runoffDuration         = register_cvar( "gal_runoff_duration", "10" );
    cvar_soundsMute             = register_cvar( "gal_sounds_mute", "0" );
    
    register_logevent( "event_game_commencing", 2, "0=World triggered",
            "1=Game_Commencing", "1&Restart_Round_" )
    
    register_logevent( "team_win", 6, "0=Team" )
    register_logevent( "round_end", 2, "1=Round_End" )
    
    register_clcmd( "say", "cmd_say", -1 );
    register_clcmd( "votemap", "cmd_HL1_votemap" );
    register_clcmd( "listmaps", "cmd_HL1_listmaps" );
    
    register_concmd( "gal_startvote", "cmd_startVote", ADMIN_MAP );
    register_concmd( "gal_createmapfile", "cmd_createMapFile", ADMIN_RCON );
    
    g_menuChooseMap = register_menuid( MENU_CHOOSEMAP );

#if AMXX_VERSION_NUM < 183
    g_user_msgid = get_user_msgid( "SayText" )
#endif
    
    register_menucmd( g_menuChooseMap, MENU_KEY_1 | MENU_KEY_2 |
            MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 |
            MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9 | MENU_KEY_0,
            "vote_handleChoice" );
}

/**
 * Called when all plugins went through plugin_init( ).
 * When this forward is called, most plugins should have registered their
 * cvars and commands already.
 */
public plugin_cfg()
{
#if IS_DEBUG_ENABLED > 0
    g_debug_level = get_cvar_num( "gal_debug" );
#endif
    g_maxrounds_pointer  = get_cvar_pointer( "mp_maxrounds" )
    g_winlimit_pointer   = get_cvar_pointer( "mp_winlimit" )
    g_freezetime_pointer = get_cvar_pointer( "mp_freezetime" )
    
    reset_rounds_scores()
    
    formatex( DIR_CONFIGS[ get_configsdir( DIR_CONFIGS, sizeof( DIR_CONFIGS ) - 1 ) ],
            sizeof( DIR_CONFIGS ) - 1, "/galileo_reloaded" );
    
    formatex( DIR_DATA[ get_datadir( DIR_DATA, sizeof( DIR_DATA ) - 1 ) ],
            sizeof( DIR_DATA ) - 1, "/galileo_reloaded" );
    
    server_cmd( "exec %s/galileo_reloaded.cfg", DIR_CONFIGS );
    server_exec();
    
    g_is_supported_color_chat = ( is_running( "czero" )
                                  || is_running( "cstrike" ) )
    
    if( colored_menus() )
    {
        copy( CLR_RED, 2, "\r" );
        copy( CLR_WHITE, 2, "\w" );
        copy( CLR_YELLOW, 2, "\y" );
    }
    
    g_rtvWait   = get_pcvar_float( cvar_rtvWait );
    g_choiceMax = max( min( MAX_MAPS_IN_VOTE, get_pcvar_num( cvar_voteMapChoiceCnt ) ), 2 )
    
    get_pcvar_string( cvar_voteWeightFlags, g_voteWeightFlags, sizeof( g_voteWeightFlags ) - 1 );
    get_mapname( g_currentMap, sizeof( g_currentMap ) - 1 );
    
    g_fillerMap     = ArrayCreate( 32 );
    g_nominationMap = ArrayCreate( 32 );
    
    // initialize nominations table
    nomination_clearAll();
    
    if( get_pcvar_num( cvar_banRecent ) )
    {
        register_clcmd( "say recentmaps", "cmd_listrecent", 0 );
        
        map_loadRecentList();
        
        if( !( get_cvar_num( "gal_server_starting" )
               && get_pcvar_num( cvar_srvStart ) ) )
        {
            map_writeRecentList();
        }
    }
    
    if( get_pcvar_num( cvar_rtvCommands ) & RTV_CMD_STANDARD )
    {
        register_clcmd( "say rockthevote", "cmd_rockthevote", 0 );
    }
    
    if( get_pcvar_num( cvar_nomPlayerAllowance ) )
    {
        register_concmd( "gal_listmaps", "map_listAll" );
        register_clcmd( "say nominations", "cmd_nominations", 0, "- displays current nominations for next map" );
        
        if( get_pcvar_num( cvar_nomPrefixes ) )
        {
            map_loadPrefixList();
        }
        map_loadNominationList();
    }
    
    new mapName[ 32 ];
    get_mapname( mapName, 31 );
    DEBUG_LOGGER( 4, "[%s]", mapName )
    DEBUG_LOGGER( 4, "" )
    
    if( get_cvar_num( "gal_server_starting" ) )
    {
        srv_handleStart();
    }
    
    if( get_pcvar_num( cvar_emptyWait ) )
    {
        g_emptyCycleMap = ArrayCreate( 32 );
        map_loadEmptyCycleList();
        set_task( 60.0, "srv_initEmptyCheck" );
    }
    
    set_task( 10.0, "vote_setupEnd" );

#if IS_DEBUG_ENABLED > 0
    runTests()
#endif
}

public team_win()
{
    new winlimit_integer
    new wins_Terrorist_trigger
    new wins_CT_trigger
    new string_team_winner[ 16 ]
    
    read_logargv( 1, string_team_winner, charsmax( string_team_winner ) )
    
    if( string_team_winner[ 0 ] == 'T' )
    {
        g_total_terrorists_wins++
    }
    else if( string_team_winner[ 0 ] == 'C' )
    {
        g_total_CT_wins++
    }
    
    winlimit_integer = get_pcvar_num( g_winlimit_pointer )
    
    if( winlimit_integer )
    {
        wins_CT_trigger        = g_total_CT_wins + VOTE_START_ROUNDS
        wins_Terrorist_trigger = g_total_terrorists_wins + VOTE_START_ROUNDS
        
        if( ( ( wins_CT_trigger > winlimit_integer )
              || ( wins_Terrorist_trigger > winlimit_integer ) )
            && !g_is_maxrounds_vote_map )
        {
            g_is_maxrounds_extend = false;
            
            VOTE_START_ROUNDS_DELAY
        }
    }
    
    DEBUG_LOGGER( 32, "Team_Win: string_team_winner = %s, winlimit_integer = %d, \
            wins_CT_trigger = %d, wins_Terrorist_trigger = %d", \
            string_team_winner, winlimit_integer, wins_CT_trigger, wins_Terrorist_trigger )
}

public round_end()
{
    new maxrounds_number;
    new current_rounds_trigger
    
    g_total_rounds_played++
    
    maxrounds_number = get_pcvar_num( g_maxrounds_pointer )
    
    if( maxrounds_number )
    {
        current_rounds_trigger = g_total_rounds_played + VOTE_START_ROUNDS
        
        if( ( current_rounds_trigger > maxrounds_number )
            && !g_is_maxrounds_vote_map )
        {
            g_is_maxrounds_extend = true;
            
            VOTE_START_ROUNDS_DELAY
        }
    }
    
    DEBUG_LOGGER( 32, "Round_End:  maxrounds_number = %d, \
            g_total_rounds_played = %d, current_rounds_trigger = %d", \
            maxrounds_number, g_total_rounds_played, current_rounds_trigger )
    
    if( g_is_last_round )
    {
        if( g_isTimeToChangeLevel ) // when time runs out, end at the current round end
        {
            intermission_display()
        }
        else // when time runs out, end at the next round end
        {
            g_isTimeToChangeLevel = true
            
            remove_task( TASKID_SHOW_LAST_ROUND_HUD )
            
            set_task( 5.0, "configure_last_round_HUD", 1 )
        }
    }
}

stock intermission_display( is_map_change_stays = false )
{
    if( g_isTimeToChangeLevel )
    {
        g_isTimeToChangeLevel = false;
        
        if( is_map_change_stays )
        {
            set_task( 5.0, "map_change_stays", TASKID_MAP_CHANGE );
        }
        else
        {
            set_task( 5.0, "map_change", TASKID_MAP_CHANGE );
        }
        
        // freeze the game and show the scoreboard
        message_begin( MSG_ALL, SVC_INTERMISSION );
        message_end();
    }
}

public start_voting_by_rounds()
{
    vote_startDirector( false )
}

stock reset_rounds_scores()
{
    g_is_maxrounds_vote_map = false;
    g_is_maxrounds_extend   = false;
    
    g_total_rounds_played   = -1
    g_total_terrorists_wins = 0
    g_total_CT_wins         = 0
}

public plugin_end()
{
    restore_server_cvars_for_test
    map_restoreOriginalTimeLimit()
    
    ArrayDestroy( g_tests_idsAndNames )
    ArrayDestroy( g_tests_delayed_ids )
    ArrayDestroy( g_tests_failure_ids )
}

public vote_setupEnd()
{
    DEBUG_LOGGER( 4, "%32s mp_timelimit: %f  g_originalTimelimit: %f", \
            "vote_setupEnd( in )", get_cvar_float( "mp_timelimit" ), g_originalTimelimit )
    
    g_originalTimelimit = get_cvar_float( "mp_timelimit" );
    g_originalMaxRounds = get_pcvar_num( g_maxrounds_pointer )
    g_originalWinLimit  = get_pcvar_num( g_winlimit_pointer )
    
    setup_vote_manageEnd_task()
    
    DEBUG_LOGGER( 2, "%32s mp_timelimit: %f  g_originalTimelimit: %f", \
            "vote_setupEnd( out )", get_cvar_float( "mp_timelimit" ), g_originalTimelimit )
}

/**
 * Setup the main task that schedules the end map voting and allow round finish feature.
 */
stock setup_vote_manageEnd_task()
{
    if( !task_exists( TASKID_VOTE_MANAGEEND ) )
    {
        set_task( 15.0, "vote_manageEnd", TASKID_VOTE_MANAGEEND, _, _, "b" );
    }
}

/**
 * Indicates which action to take when it is detected
 * that the server has been restarted.
 * 0 - stay on the map the server started with
 * 1 - change to the map that was being played when the server was reset
 * 2 - change to what would have been the next map had the server not
 *     been restarted ( if the next map isn't known, this acts like 3 )
 * 3 - start an early map vote after the first two minutes
 * 4 - change to a randomly selected map from your nominatable map list
 */
public srv_handleStart()
{
    // this is the key that tells us if this server has been restarted or not
    set_cvar_num( "gal_server_starting", 0 );
    
    // take the defined "server start" action
    new startAction = get_pcvar_num( cvar_srvStart );
    
    if( startAction )
    {
        new nextMap[ 32 ];
        
        if( startAction == SRV_START_CURRENTMAP
            || startAction == SRV_START_NEXTMAP )
        {
            new filename[ 256 ];
            formatex( filename, sizeof( filename ) - 1, "%s/info.dat", DIR_DATA );
            
            new file = fopen( filename, "rt" );
            
            if( file )  // !feof( file )
            {
                fgets( file, nextMap, sizeof( nextMap ) - 1 );
                
                if( startAction == SRV_START_NEXTMAP )
                {
                    nextMap[ 0 ] = 0;
                    fgets( file, nextMap, sizeof( nextMap ) - 1 );
                }
            }
            fclose( file );
        }
        else if( startAction == SRV_START_RANDOMMAP )
        {
            // pick a random map from allowable nominations
            
            // if noms aren't allowed, the nomination list hasn't already been loaded
            if( get_pcvar_num( cvar_nomPlayerAllowance ) == 0 )
            {
                map_loadNominationList();
            }
            
            if( g_nominationMapCnt )
            {
                ArrayGetString( g_nominationMap, random_num( 0, g_nominationMapCnt - 1 ), nextMap, sizeof( nextMap ) - 1 );
            }
        }
        
        trim( nextMap );
        
        if( nextMap[ 0 ]
            && is_map_valid( nextMap ) )
        {
            server_cmd( "changelevel %s", nextMap );
        }
        else
        {
            vote_manageEarlyStart();
        }
    }
}

/**
 * Action of srv_handleStart to take when it is detected that the server has been
 *   restarted. 3 - start an early map vote after the first two minutes.
 */
stock vote_manageEarlyStart()
{
    g_voteStatus |= VOTE_IS_EARLY;
    
    set_task( 120.0, "vote_startDirector", TASKID_VOTE_STARTDIRECTOR );
}

stock map_setNext( nextMap[] )
{
    // set the queryable cvar
    set_cvar_string( "amx_nextmap", nextMap );
    
    // update our data file
    new filename[ 256 ];
    formatex( filename, sizeof( filename ) - 1, "%s/info.dat", DIR_DATA );
    
    new file = fopen( filename, "wt" );
    
    if( file )
    {
        fprintf( file, "%s", g_currentMap );
        fprintf( file, "^n%s", nextMap );
        fclose( file );
    }
    else
    {
        //error
    }
}

public vote_manageEnd()
{
    new secondsLeft = get_timeleft();
    
    // are we ready to start an "end of map" vote?
    if( ( secondsLeft < START_VOTEMAP_MIN_TIME )
        && ( secondsLeft > START_VOTEMAP_MAX_TIME )
        && !g_is_maxrounds_vote_map
        && get_pcvar_num( cvar_endOfMapVote ) )
    {
        vote_startDirector( false );
    }
    
    // are we managing the end of the map?
    if( secondsLeft < 30
        && secondsLeft > 0
        && !g_is_last_round )
    {
        map_manageEnd();
    }
}

public map_manageEnd()
{
    DEBUG_LOGGER( 2, "%32s mp_timelimit: %f", "map_manageEnd(in)", get_cvar_float( "mp_timelimit" ) )
    
    get_cvar_string( "amx_nextmap", g_nextmap, sizeof( g_nextmap ) - 1 );
    
    if( get_pcvar_num( cvar_endOnRound ) == 1 ) // when time runs out, end at the current round end
    {
        g_is_last_round       = true;
        g_isTimeToChangeLevel = true;
        
        client_print_color_internal( 0, "^1%L %L %L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED",
                LANG_PLAYER, "GAL_CHANGE_NEXTROUND", LANG_PLAYER, "GAL_NEXTMAP", g_nextmap )
        
        prevent_map_change()
    }
    else if( get_pcvar_num( cvar_endOnRound ) == 2 ) // when time runs out, end at the next round end
    {
        g_is_last_round = true;
        
        // This is to avoid have a extra round at special mods where time limit is equal the
        // round timer.
        if( get_cvar_float( "mp_roundtime" ) > 8 )
        {
            g_isTimeToChangeLevel = true;
            
            client_print_color_internal( 0, "^1%L %L %L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED",
                    LANG_PLAYER, "GAL_CHANGE_NEXTROUND", LANG_PLAYER, "GAL_NEXTMAP", g_nextmap )
        }
        else
        {
            client_print_color_internal( 0, "^1%L %L",
                    LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED", LANG_PLAYER, "GAL_NEXTMAP", g_nextmap );
        }
        
        prevent_map_change()
    }
    
    configure_last_round_HUD( bool:get_pcvar_num( cvar_endOnRound_msg ) )
    
    DEBUG_LOGGER( 2, "%32s mp_timelimit: %f", "map_manageEnd(out)", get_cvar_float( "mp_timelimit" ) )
}

public configure_last_round_HUD( bool:is_to_show )
{
    if( is_to_show )
    {
        set_task( 1.0, "show_last_round_HUD", TASKID_SHOW_LAST_ROUND_HUD, _, _, "b" )
    }
}

public show_last_round_HUD()
{
    set_hudmessage( 255, 255, 255, 0.15, 0.15, 0, 0.0, 1.0, 0.1, 0.1, 1 )
    
    if( g_isTimeToChangeLevel )
    {
        show_hudmessage( 0, "%L ^n%L", LANG_PLAYER, "GAL_CHANGE_NEXTROUND",
                LANG_PLAYER, "GAL_NEXTMAP", g_nextmap )
    }
    else
    {
        show_hudmessage( 0, "%L ^n%L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED",
                LANG_PLAYER, "GAL_NEXTMAP", g_nextmap )
    }
}

stock prevent_map_change()
{
    if( get_realplayersnum() >= get_pcvar_num( cvar_endOnRound_players ) )
    {
        save_time_limit()
        
        // prevent the map from ending automatically
        server_cmd( "mp_timelimit 0" );
    }
}

public map_loadRecentList()
{
    new filename[ 256 ];
    formatex( filename, sizeof( filename ) - 1, "%s/recentmaps.dat", DIR_DATA );
    
    new file = fopen( filename, "rt" );
    
    if( file )
    {
        new buffer[ 32 ];
        
        while( !feof( file ) )
        {
            fgets( file, buffer, sizeof( buffer ) - 1 );
            trim( buffer );
            
            if( buffer[ 0 ] )
            {
                if( g_cntRecentMap == get_pcvar_num( cvar_banRecent ) )
                {
                    break;
                }
                copy( g_recentMap[ g_cntRecentMap++ ], sizeof( buffer ) - 1, buffer );
            }
        }
        fclose( file );
    }
}

public map_writeRecentList()
{
    new filename[ 256 ];
    formatex( filename, sizeof( filename ) - 1, "%s/recentmaps.dat", DIR_DATA );
    
    new file = fopen( filename, "wt" );
    
    if( file )
    {
        fprintf( file, "%s", g_currentMap );
        
        for( new idxMap = 0; idxMap < get_pcvar_num( cvar_banRecent ) - 1; ++idxMap )
        {
            fprintf( file, "^n%s", g_recentMap[ idxMap ] );
        }
        
        fclose( file );
    }
}

public map_loadFillerList( filename[] )
{
    return map_populateList( g_fillerMap, filename );
}

public cmd_rockthevote( player_id )
{
    client_print_color_internal( player_id, "^1%L", player_id, "GAL_CMD_RTV" );
    
    vote_rock( player_id );
    return PLUGIN_CONTINUE;
}

public cmd_nominations( player_id )
{
    client_print_color_internal( player_id, "^1%L", player_id, "GAL_CMD_NOMS" );
    
    nomination_list( player_id );
    return PLUGIN_CONTINUE;
}

public cmd_listrecent( player_id )
{
    switch( get_pcvar_num( cvar_banRecentStyle ) )
    {
        case 1:
        {
            new msg[ 101 ], msgIdx;
            
            for( new idx = 0; idx < g_cntRecentMap; ++idx )
            {
                msgIdx += format( msg[ msgIdx ], sizeof( msg ) - 1 - msgIdx, ", %s", g_recentMap[ idx ] );
            }
        #if AMXX_VERSION_NUM < 183
            new players_ids[ 32 ]
            
            new playerIndex_idsCounter
            
            get_players( players_ids, playerIndex_idsCounter, "ch" );
            
            for( new i = 0; i < playerIndex_idsCounter; i++ )
            {
                client_print_color_internal( players_ids[ i ], "^1%L: %s", players_ids[ i ],
                        "GAL_MAP_RECENTMAPS", msg[ 2 ] );
            }
        #else
            client_print_color_internal( 0, "^1%L: %s", LANG_PLAYER, "GAL_MAP_RECENTMAPS", msg[ 2 ] );
        #endif
        }
        case 2:
        {
            for( new idx = 0; idx < g_cntRecentMap; ++idx )
            {
            #if AMXX_VERSION_NUM < 183
                new players_ids[ 32 ]
                
                new playerIndex_idsCounter
                
                get_players( players_ids, playerIndex_idsCounter, "ch" );
                
                for( new i = 0; i < playerIndex_idsCounter; i++ )
                {
                    client_print_color_internal( players_ids[ i ], "^1%L ( %i ): %s", players_ids[ i ],
                            "GAL_MAP_RECENTMAP", idx + 1, g_recentMap[ idx ] );
                }
            #else
                client_print_color_internal( 0, "^1%L ( %i ): %s", LANG_PLAYER, "GAL_MAP_RECENTMAP",
                        idx + 1, g_recentMap[ idx ] );
            #endif
            }
        }
    }
    
    return PLUGIN_HANDLED;
}

/**
 * Called when need to start a vote map, where the command line arg1:
 *    -nochange: extend the current map, aka, Keep Current Map, will to do the real extend.
 *    -restart: extend the current map, aka, Keep Current Map restart the server at the current map.
 */
public cmd_startVote( player_id, level, cid )
{
    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        return PLUGIN_HANDLED;
    }
    
    if( g_voteStatus & VOTE_IN_PROGRESS )
    {
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_VOTE_INPROGRESS" );
    }
    else
    {
        g_isTimeToChangeLevel = true;
        
        if( read_argc() == 2 )
        {
            new vote_display_task_argument[ 32 ];
            read_args( vote_display_task_argument, sizeof( vote_display_task_argument ) - 1 );
            
            if( equali( vote_display_task_argument, "-nochange" ) )
            {
                g_is_to_cancel_end_vote = true;
                g_isTimeToChangeLevel   = false;
            }
            
            if( equali( vote_display_task_argument, "-restart" ) )
            {
                g_isTimeToRestart = true;
            }
        }
        vote_startDirector( true );
    }
    
    return PLUGIN_HANDLED;
}

stock map_populateList( Array:mapArray, mapFilename[] )
{
    // clear the map array in case we're reusing it
    ArrayClear( mapArray );
    
    // load the array with maps
    new mapCnt;
    
    if( !equal( mapFilename, "*" )
        && !equal( mapFilename, "#" ) )
    {
        new file = fopen( mapFilename, "rt" );
        
        if( file )
        {
            new buffer[ 32 ];
            
            while( !feof( file ) )
            {
                fgets( file, buffer, sizeof( buffer ) - 1 );
                trim( buffer );
                
                if( buffer[ 0 ]
                    && !equal( buffer, "//", 2 )
                    && !equal( buffer, ";", 1 )
                    && is_map_valid( buffer ) )
                {
                    ArrayPushString( mapArray, buffer );
                    ++mapCnt;
                    DEBUG_LOGGER( 4, "map_populateList(...) buffer = %s", buffer )
                }
            }
            fclose( file );
        }
        else
        {
            log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilename );
        }
    }
    else
    {
        if( equal( mapFilename, "*" ) )
        {
            // no file provided, assuming contents of "maps" folder
            new dir, mapName[ 32 ];
            dir = open_dir( "maps", mapName, sizeof( mapName ) - 1 );
            
            if( dir )
            {
                new lenMapName;
                
                while( next_file( dir, mapName, sizeof( mapName ) - 1 ) )
                {
                    lenMapName = strlen( mapName );
                    
                    if( lenMapName > 4
                        && equali( mapName[ lenMapName - 4 ], ".bsp", 4 ) )
                    {
                        mapName[ lenMapName - 4 ] = '^0';
                        
                        if( is_map_valid( mapName ) )
                        {
                            ArrayPushString( mapArray, mapName );
                            ++mapCnt;
                        }
                    }
                }
                close_dir( dir );
            }
            else
            {
                // directory not found, wtf?
                log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_MAPS_FOLDERMISSING" );
            }
        }
        else
        {
            get_cvar_string( "mapcyclefile", mapFilename, 255 );
            new file = fopen( mapFilename, "rt" );
            
            if( file )
            {
                new buffer[ 32 ];
                
                while( !feof( file ) )
                {
                    fgets( file, buffer, sizeof( buffer ) - 1 );
                    trim( buffer );
                    
                    if( buffer[ 0 ]
                        && !equal( buffer, "//", 2 )
                        && !equal( buffer, ";", 1 )
                        && is_map_valid( buffer ) )
                    {
                        ArrayPushString( mapArray, buffer );
                        ++mapCnt;
                    }
                }
                fclose( file );
            }
            else
            {
                log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilename );
            }
        }
    }
    return mapCnt;
}

public map_loadNominationList()
{
    new filename[ 256 ];
    get_pcvar_string( cvar_nomMapFile, filename, sizeof( filename ) - 1 );
    
    g_nominationMapCnt = map_populateList( g_nominationMap, filename );
}

public cmd_createMapFile( player_id, level, cid )
{
    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        return PLUGIN_HANDLED;
    }
    
    new cntArg = read_argc() - 1;
    
    switch( cntArg )
    {
        case 1:
        {
            new arg1[ 256 ];
            read_argv( 1, arg1, sizeof( arg1 ) - 1 );
            remove_quotes( arg1 );
            
            new mapName[ MAX_MAPNAME_LEN + 5 ];    // map name is 31 ( i.e. MAX_MAPNAME_LEN ), ".bsp" is 4, string terminator is 1.
            new dir, file, mapCnt, lenMapName;
            
            dir = open_dir( "maps", mapName, sizeof( mapName ) - 1 );
            
            if( dir )
            {
                new filename[ 256 ];
                formatex( filename, sizeof( filename ) - 1, "%s/%s", DIR_CONFIGS, arg1 );
                
                file = fopen( filename, "wt" );
                
                if( file )
                {
                    mapCnt = 0;
                    
                    while( next_file( dir, mapName, sizeof( mapName ) - 1 ) )
                    {
                        lenMapName = strlen( mapName );
                        
                        if( lenMapName > 4
                            && equali( mapName[ lenMapName - 4 ], ".bsp", 4 ) )
                        {
                            mapName[ lenMapName - 4 ] = '^0';
                            
                            if( is_map_valid( mapName ) )
                            {
                                mapCnt++;
                                fprintf( file, "%s^n", mapName );
                            }
                        }
                    }
                    fclose( file );
                    con_print( player_id, "%L", LANG_SERVER, "GAL_CREATIONSUCCESS", filename, mapCnt );
                }
                else
                {
                    con_print( player_id, "%L", LANG_SERVER, "GAL_CREATIONFAILED", filename );
                }
                close_dir( dir );
            }
            else
            {
                // directory not found, wtf?
                con_print( player_id, "%L", LANG_SERVER, "GAL_MAPSFOLDERMISSING" );
            }
        }
        default:
        {
            // inform of correct usage
            con_print( player_id, "%L", player_id, "GAL_CMD_CREATEFILE_USAGE1" );
            con_print( player_id, "%L", player_id, "GAL_CMD_CREATEFILE_USAGE2" );
        }
    }
    return PLUGIN_HANDLED;
}

stock map_loadEmptyCycleList()
{
    new filename[ 256 ];
    get_pcvar_string( cvar_emptyMapFile, filename, sizeof( filename ) - 1 );
    
    g_emptyMapCnt = map_populateList( g_emptyCycleMap, filename );
    
    DEBUG_LOGGER( 4, "map_loadEmptyCycleList() g_emptyMapCnt = %d", g_emptyMapCnt )
}

public map_loadPrefixList()
{
    new filename[ 256 ];
    formatex( filename, sizeof( filename ) - 1, "%s/prefixes.ini", DIR_CONFIGS );
    
    new file = fopen( filename, "rt" );
    
    if( file )
    {
        new buffer[ 16 ];
        
        while( !feof( file ) )
        {
            fgets( file, buffer, sizeof( buffer ) - 1 );
            
            if( buffer[ 0 ]
                && !equal( buffer, "//", 2 ) )
            {
                if( g_mapPrefixCnt <= MAX_PREFIX_CNT )
                {
                    trim( buffer );
                    copy( g_mapPrefix[ g_mapPrefixCnt++ ], sizeof( buffer ) - 1, buffer );
                }
                else
                {
                    log_error( AMX_ERR_BOUNDS, "%L", LANG_SERVER, "GAL_PREFIXES_TOOMANY", MAX_PREFIX_CNT, filename );
                    break;
                }
            }
        }
        fclose( file );
    }
    else
    {
        log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_PREFIXES_NOTFOUND", filename );
    }
    return PLUGIN_HANDLED;
}

public event_game_commencing()
{
    // make sure the reset time is the original time limit
    // ( can be skewed if map was previously extended )
    map_restoreOriginalTimeLimit();
    reset_rounds_scores()
    
    setup_vote_manageEnd_task()
    
    DEBUG_LOGGER( 32, "^n AT: event_game_commencing" )
}

stock map_getIdx( text[] )
{
    new map[ MAX_MAPNAME_LEN + 1 ];
    new mapIdx;
    new nominationMap[ 32 ];
    
    for( new prefixIdx = 0; prefixIdx < g_mapPrefixCnt; ++prefixIdx )
    {
        formatex( map, sizeof( map ) - 1, "%s%s", g_mapPrefix[ prefixIdx ], text );
        
        for( mapIdx = 0; mapIdx < g_nominationMapCnt; ++mapIdx )
        {
            ArrayGetString( g_nominationMap, mapIdx, nominationMap, sizeof( nominationMap ) - 1 );
            
            if( equal( map, nominationMap ) )
            {
                return mapIdx;
            }
        }
    }
    return -1;
}

public cmd_say( player_id )
{
    //-----
    // generic say handler to determine if we need to act on what was said
    //-----
    
    static text[ 70 ], arg1[ 32 ], arg2[ 32 ], arg3[ 2 ];
    read_args( text, sizeof( text ) - 1 );
    remove_quotes( text );
    arg1[ 0 ] = '^0';
    arg2[ 0 ] = '^0';
    arg3[ 0 ] = '^0';
    parse( text, arg1, sizeof( arg1 ) - 1, arg2, sizeof( arg2 ) - 1, arg3, sizeof( arg3 ) - 1 );
    
    // if the chat line has more than 2 words, we're not interested at all
    if( arg3[ 0 ] == 0 )
    {
        new idxMap;
        
        // if the chat line contains 1 word, it could be a map or a one-word command
        if( arg2[ 0 ] == 0 ) // "say [rtv|rockthe<anything>vote]"
        {
            if( ( get_pcvar_num( cvar_rtvCommands ) & RTV_CMD_SHORTHAND
                  && equali( arg1, "rtv" ) )
                || ( ( get_pcvar_num( cvar_rtvCommands ) & RTV_CMD_DYNAMIC
                       && equali( arg1, "rockthe", 7 )
                       && equali( arg1[ strlen( arg1 ) - 4 ], "vote" ) ) ) )
            {
                vote_rock( player_id );
                return PLUGIN_HANDLED;
            }
            else if( get_pcvar_num( cvar_nomPlayerAllowance ) )
            {
                if( equali( arg1, "noms" ) )
                {
                    nomination_list( player_id );
                    return PLUGIN_HANDLED;
                }
                else
                {
                    idxMap = map_getIdx( arg1 );
                    
                    if( idxMap >= 0 )
                    {
                        nomination_toggle( player_id, idxMap );
                        return PLUGIN_HANDLED;
                    }
                }
            }
        }
        else if( get_pcvar_num( cvar_nomPlayerAllowance ) )  // "say <nominate|nom|cancel> <map>"
        {
            if( equali( arg1, "nominate" )
                || equali( arg1, "nom" ) )
            {
                nomination_attempt( player_id, arg2 );
                return PLUGIN_HANDLED;
            }
            else if( equali( arg1, "cancel" ) )
            {
                // bpj -- allow ambiguous cancel in which case a menu of their nominations is shown
                idxMap = map_getIdx( arg2 );
                
                if( idxMap >= 0 )
                {
                    nomination_cancel( player_id, idxMap );
                    return PLUGIN_HANDLED;
                }
            }
        }
    }
    return PLUGIN_CONTINUE;
}

stock nomination_attempt( player_id, nomination[] ) // ( playerName[], &phraseIdx, matchingSegment[] )
{
    // all map names are stored as lowercase, so normalize the nomination
    strtolower( nomination );
    
    // assume there'll be more than one match ( because we're lazy ) and starting building the match menu
    //menu_destroy( g_nominationMatchesMenu[player_id] );
    g_nominationMatchesMenu[ player_id ] = menu_create( "Nominate Map", "nomination_handleMatchChoice" );
    
    // gather all maps that match the nomination
    new mapIdx, nominationMap[ 32 ], matchCnt = 0, matchIdx = -1, info[ 1 ], choice[ 64 ], disabledReason[ 16 ];
    
    for( mapIdx = 0; mapIdx < g_nominationMapCnt
         && matchCnt <= MAX_NOM_MATCH_CNT; ++mapIdx )
    {
        ArrayGetString( g_nominationMap, mapIdx, nominationMap, sizeof( nominationMap ) - 1 );
        
        if( contain( nominationMap, nomination ) > -1 )
        {
            matchCnt++;
            matchIdx = mapIdx;    // store in case this is the only match
            
            // there may be a much better way of doing this, but I didn't feel like
            // storing the matches and mapIdx's only to loop through them again
            info[ 0 ] = mapIdx;
            
            // in most cases, the map will be available for selection, so assume that's the case here
            disabledReason[ 0 ] = 0;
            
            // disable if the map has already been nominated
            if( nomination_getPlayer( mapIdx ) )
            {
                formatex( disabledReason, sizeof( disabledReason ) - 1, "%L", player_id, "GAL_MATCH_NOMINATED" );
            }
            // disable if the map is too recent
            else if( map_isTooRecent( nominationMap ) )
            {
                formatex( disabledReason, sizeof( disabledReason ) - 1, "%L", player_id, "GAL_MATCH_TOORECENT" );
            }
            else if( equal( g_currentMap, nominationMap ) )
            {
                formatex( disabledReason, sizeof( disabledReason ) - 1, "%L", player_id, "GAL_MATCH_CURRENTMAP" );
            }
            
            formatex( choice, sizeof( choice ) - 1, "%s %s", nominationMap, disabledReason );
            menu_additem( g_nominationMatchesMenu[ player_id ], choice, info, ( disabledReason[ 0 ] == 0 ) ? 0 : ( 1 << 26 ) );
        }
    }
    
    // handle the number of matches
    switch( matchCnt )
    {
        case 0:
        {
            // no matches; pity the poor fool
            client_print_color_internal( player_id, "^1%L", player_id, "GAL_NOM_FAIL_NOMATCHES", nomination );
        }
        case 1:
        {
            // one match?! omg, this is just like awesome
            map_nominate( player_id, matchIdx );
        }
        default:
        {
            // this is kinda sexy; we put up a menu of the matches for them to pick the right one
            client_print_color_internal( player_id, "^1%L", player_id, "GAL_NOM_MATCHES", nomination );
            
            if( matchCnt == MAX_NOM_MATCH_CNT )
            {
                client_print_color_internal( player_id, "^1%L", player_id, "GAL_NOM_MATCHES_MAX",
                        MAX_NOM_MATCH_CNT, MAX_NOM_MATCH_CNT );
            }
            menu_display( player_id, g_nominationMatchesMenu[ player_id ] );
        }
    }
}

public nomination_handleMatchChoice( player_id, menu, item )
{
    if( item < 0 )
    {
        return PLUGIN_CONTINUE;
    }
    
    // Get item info
    new mapIdx, info[ 1 ];
    new access, callback;
    
    menu_item_getinfo( g_nominationMatchesMenu[ player_id ], item, access, info, 1, _, _, callback );
    
    mapIdx = info[ 0 ];
    map_nominate( player_id, mapIdx );
    
    return PLUGIN_HANDLED;
}

stock nomination_getPlayer( idxMap )
{
    // check if the map has already been nominated
    new idxNomination;
    new playerNominationMax = min( get_pcvar_num( cvar_nomPlayerAllowance ), MAX_NOMINATION_CNT );
    
    for( new idPlayer = 1; idPlayer <= MAX_PLAYER_CNT; ++idPlayer )
    {
        for( idxNomination = 1; idxNomination <= playerNominationMax; ++idxNomination )
        {
            if( idxMap == g_nomination[ idPlayer ][ idxNomination ] )
            {
                return idPlayer;
            }
        }
    }
    return 0;
}

stock nomination_toggle( player_id, idxMap )
{
    new idNominator = nomination_getPlayer( idxMap );
    
    if( idNominator == player_id )
    {
        nomination_cancel( player_id, idxMap );
    }
    else
    {
        map_nominate( player_id, idxMap, idNominator );
    }
}

stock nomination_cancel( player_id, idxMap )
{
    // cancellations can only be made if a vote isn't already in progress
    if( g_voteStatus & VOTE_IN_PROGRESS )
    {
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_CANCEL_FAIL_INPROGRESS" );
        return;
    }
    // and if the outcome of the vote hasn't already been determined
    else if( g_voteStatus & VOTE_IS_OVER )
    {
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_CANCEL_FAIL_VOTEOVER" );
        return;
    }
    
    new bool:nominationFound, idxNomination;
    new playerNominationMax = min( get_pcvar_num( cvar_nomPlayerAllowance ), MAX_NOMINATION_CNT );
    
    for( idxNomination = 1; idxNomination <= playerNominationMax; ++idxNomination )
    {
        if( g_nomination[ player_id ][ idxNomination ] == idxMap )
        {
            nominationFound = true;
            break;
        }
    }
    
    new mapName[ 32 ];
    ArrayGetString( g_nominationMap, idxMap, mapName, sizeof( mapName ) - 1 );
    
    if( nominationFound )
    {
        g_nomination[ player_id ][ idxNomination ] = -1;
        g_nominationCnt--;
        
        nomination_announceCancellation( mapName );
    }
    else
    {
        new idNominator = nomination_getPlayer( idxMap );
        
        if( idNominator )
        {
            new name[ 32 ];
            get_user_name( idNominator, name, 31 );
            
            client_print_color_internal( player_id, "^1%L", player_id, "GAL_CANCEL_FAIL_SOMEONEELSE",
                    mapName, name );
        }
        else
        {
            client_print_color_internal( player_id, "^1%L", player_id, "GAL_CANCEL_FAIL_WASNOTYOU", mapName );
        }
    }
}

stock map_nominate( player_id, idxMap, idNominator = -1 )
{
    // nominations can only be made if a vote isn't already in progress
    if( g_voteStatus & VOTE_IN_PROGRESS )
    {
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_NOM_FAIL_INPROGRESS" );
        return;
    }
    // and if the outcome of the vote hasn't already been determined
    else if( g_voteStatus & VOTE_IS_OVER )
    {
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_NOM_FAIL_VOTEOVER" );
        return;
    }
    
    new mapName[ 32 ];
    ArrayGetString( g_nominationMap, idxMap, mapName, sizeof( mapName ) - 1 );
    
    // players can not nominate the current map
    if( equal( g_currentMap, mapName ) )
    {
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_NOM_FAIL_CURRENTMAP", g_currentMap );
        return;
    }
    
    // players may not be able to nominate recently played maps
    if( map_isTooRecent( mapName ) )
    {
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_NOM_FAIL_TOORECENT", mapName );
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_NOM_FAIL_TOORECENT_HLP" );
        return;
    }
    
    // check if the map has already been nominated
    if( idNominator == -1 )
    {
        idNominator = nomination_getPlayer( idxMap );
    }
    
    if( idNominator == 0 )
    {
        // determine the number of nominations the player already made
        // and grab an open slot with the presumption that the player can make the nomination
        new nominationCnt       = 0, idxNominationOpen, idxNomination;
        new playerNominationMax = min( get_pcvar_num( cvar_nomPlayerAllowance ), MAX_NOMINATION_CNT );
        
        for( idxNomination = 1; idxNomination <= playerNominationMax; ++idxNomination )
        {
            if( g_nomination[ player_id ][ idxNomination ] >= 0 )
            {
                nominationCnt++;
            }
            else
            {
                idxNominationOpen = idxNomination;
            }
        }
        
        if( nominationCnt == playerNominationMax )
        {
            new nominatedMaps[ 256 ], buffer[ 32 ];
            
            for( idxNomination = 1; idxNomination <= playerNominationMax; ++idxNomination )
            {
                idxMap = g_nomination[ player_id ][ idxNomination ];
                ArrayGetString( g_nominationMap, idxMap, buffer, sizeof( buffer ) - 1 );
                format( nominatedMaps, sizeof( nominatedMaps ) - 1, "%s%s%s", nominatedMaps, ( idxNomination == 1 ) ? "" : ", ", buffer );
            }
            
            client_print_color_internal( player_id, "^1%L", player_id, "GAL_NOM_FAIL_TOOMANY",
                    playerNominationMax, nominatedMaps );
            
            client_print_color_internal( player_id, "^1%L", player_id, "GAL_NOM_FAIL_TOOMANY_HLP" );
        }
        else
        {
            // otherwise, allow the nomination
            g_nomination[ player_id ][ idxNominationOpen ] = idxMap;
            g_nominationCnt++;
            map_announceNomination( player_id, mapName );
            
            client_print_color_internal( player_id, "^1%L", player_id, "GAL_NOM_GOOD_HLP" );
        }
    }
    else if( idNominator == player_id )
    {
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_NOM_FAIL_ALREADY", mapName );
    }
    else
    {
        new name[ 32 ];
        get_user_name( idNominator, name, 31 );
        
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_NOM_FAIL_SOMEONEELSE", mapName, name );
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_NOM_FAIL_SOMEONEELSE_HLP" );
    }
}

public nomination_list( player_id )
{
    new idxNomination, idxMap; //, hudMessage[512];
    new msg[ 101 ], mapCnt;
    new playerNominationMax = min( get_pcvar_num( cvar_nomPlayerAllowance ), MAX_NOMINATION_CNT );
    new mapName[ 32 ];
    
    for( new idPlayer = 1; idPlayer <= MAX_PLAYER_CNT; ++idPlayer )
    {
        for( idxNomination = 1; idxNomination <= playerNominationMax; ++idxNomination )
        {
            idxMap = g_nomination[ idPlayer ][ idxNomination ];
            
            if( idxMap >= 0 )
            {
                ArrayGetString( g_nominationMap, idxMap, mapName, sizeof( mapName ) - 1 );
                format( msg, sizeof( msg ) - 1, "%s, %s", msg, mapName );
                
                if( ++mapCnt == 4 )     // list 4 maps per chat line
                {
                #if AMXX_VERSION_NUM < 183
                    new players_ids[ 32 ]
                    
                    new playerIndex_idsCounter
                    
                    get_players( players_ids, playerIndex_idsCounter, "ch" );
                    
                    for( new i = 0; i < playerIndex_idsCounter; i++ )
                    {
                        client_print_color_internal( players_ids[ i ], "^1%L: %s", players_ids[ i ],
                                "GAL_NOMINATIONS", msg[ 2 ] );
                    }
                #else
                    client_print_color_internal( 0, "^1%L: %s", LANG_PLAYER, "GAL_NOMINATIONS",
                            msg[ 2 ] );
                #endif
                    mapCnt   = 0;
                    msg[ 0 ] = 0;
                }
            }
        }
    }
    
    if( msg[ 0 ] )
    {
    #if AMXX_VERSION_NUM < 183
        new players_ids[ 32 ]
        
        new playerIndex_idsCounter
        
        get_players( players_ids, playerIndex_idsCounter, "ch" );
        
        for( new i = 0; i < playerIndex_idsCounter; i++ )
        {
            client_print_color_internal( players_ids[ i ], "^1%L: %s", players_ids[ i ],
                    "GAL_NOMINATIONS", msg[ 2 ] );
        }
    #else
        client_print_color_internal( 0, "^1%L: %s", LANG_PLAYER, "GAL_NOMINATIONS", msg[ 2 ] );
    #endif
    }
    else
    {
    #if AMXX_VERSION_NUM < 183
        new players_ids[ 32 ]
        
        new playerIndex_idsCounter
        
        get_players( players_ids, playerIndex_idsCounter, "ch" );
        
        for( new i = 0; i < playerIndex_idsCounter; i++ )
        {
            client_print_color_internal( players_ids[ i ], "^1%L: %L", players_ids[ i ], "GAL_NOMINATIONS",
                    players_ids[ i ], "NONE" );
        }
    #else
        client_print_color_internal( 0, "^1%L: %L", LANG_PLAYER, "GAL_NOMINATIONS",
                LANG_PLAYER, "NONE" );
    #endif
    }
}

public unlock_voting()
{
    g_is_voting_locked = false
}

public vote_startDirector( bool:forced )
{
    new choicesLoaded
    new voteDuration
    
    if( ( ( g_voteStatus & VOTE_IN_PROGRESS )
          && !( g_voteStatus & VOTE_IS_RUNOFF ) )
        || ( g_is_voting_locked
             && !( g_voteStatus & VOTE_IS_RUNOFF ) )
        || g_is_to_cancel_end_vote )
    {
        DEBUG_LOGGER( 1, "At vote_startDirector --- The voting was canceled. g_voteStatus=%d, \
                g_is_voting_locked=%d, g_is_to_cancel_end_vote=%d", \
                g_voteStatus, g_is_voting_locked, g_is_to_cancel_end_vote )
        return
    }
    
    if( g_voteStatus & VOTE_IS_RUNOFF )
    {
        vote_loadRunoffChoices();
        
        choicesLoaded      = g_totalVoteOptions_temp
        g_totalVoteOptions = g_totalVoteOptions_temp
        
        voteDuration = get_pcvar_num( cvar_runoffDuration );
        
        DEBUG_LOGGER( 16, "At vote_startDirector --- Runoff map1: %s, Runoff map2: %s --- choicesLoaded: %d", \
                g_mapsVoteMenuNames[ 0 ], g_mapsVoteMenuNames[ 1 ], choicesLoaded )
        
        DEBUG_LOGGER( 4, "   [RUNOFF VOTE CHOICES ( %i )]", choicesLoaded )
    }
    else
    {
        // make it known that a vote is in progress
        g_voteStatus |= VOTE_IN_PROGRESS;
        
        g_is_map_extension_allowed = get_cvar_float( "mp_timelimit" ) < get_pcvar_float( cvar_extendmapMax )
        
        g_is_voting_locked = true
        set_task( 120.0, "unlock_voting", TASKID_UNLOCK_VOTING );
        
        // stop RTV reminders
        remove_task( TASKID_REMINDER );
        
        if( forced )
        {
            g_voteStatus |= VOTE_FORCED;
        }
        
        choicesLoaded = vote_loadChoices();
        voteDuration  = get_pcvar_num( cvar_voteDuration );
        
        DEBUG_LOGGER( 4, "   [PRIMARY VOTE CHOICES ( %i )]", choicesLoaded )
        
        if( choicesLoaded )
        {
            // clear all nominations
            nomination_clearAll();
        }
    }

#if IS_DEBUG_ENABLED > 0
    voteDuration   = 5
    g_voteDuration = 5
#endif
    
    if( choicesLoaded )
    {
        // alphabetize the maps
        SortCustom2D( g_mapsVoteMenuNames, choicesLoaded, "sort_stringsi" );

#if IS_DEBUG_ENABLED > 0
        for( new dbgChoice = 0; dbgChoice < choicesLoaded; dbgChoice++ )
        {
            DEBUG_LOGGER( 4, "      %i. %s", dbgChoice + 1, g_mapsVoteMenuNames[ dbgChoice ] )
        }
#endif
        
        // mark the players who are in this vote for use later
        new player[ 32 ], playerCnt;
        get_players( player, playerCnt, "ch" );    // skip bots and hltv
        
        for( new idxPlayer = 0; idxPlayer < playerCnt; ++idxPlayer )
        {
            g_voted[ player[ idxPlayer ] ] = false;
        }
        
        // make perfunctory announcement: "get ready to choose a map"
        if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_GETREADYTOCHOOSE ) )
        {
            client_cmd( 0, "spk ^"get red( e80 ) ninety( s45 ) to check( e20 ) use bay( s18 ) mass( e42 ) cap( s50 )^"" );
        }
        
        // announce the pending vote countdown from 7 to 1
        set_task( 1.0, "vote_countdownPendingVote", TASKID_VOTE_COUNTDOWNPENDINGVOTE, _, _, "a", 7 );
        
        // display the map choices
        set_task( 8.5, "vote_handleDisplay", TASKID_VOTE_HANDLEDISPLAY );
        
        // display the vote outcome
        if( get_pcvar_num( cvar_voteStatus ) )
        {
            new vote_display_task_argument[ 3 ] = { -1, -1, false }; // indicates it's the end of vote display
            set_task( 8.5 + float( voteDuration ) + 1.0, "vote_display", TASKID_VOTE_DISPLAY, vote_display_task_argument, 3 );
            set_task( 8.5 + float( voteDuration ) + 6.0, "vote_expire", TASKID_VOTE_EXPIRE );
        }
        else
        {
            set_task( 8.5 + float( voteDuration ) + 3.0, "vote_expire", TASKID_VOTE_EXPIRE );
        }
    }
    else
    {
    #if AMXX_VERSION_NUM < 183
        new players_ids[ 32 ]
        
        new playerIndex_idsCounter
        
        get_players( players_ids, playerIndex_idsCounter, "ch" );
        
        for( new i = 0; i < playerIndex_idsCounter; i++ )
        {
            client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ], "GAL_VOTE_NOMAPS" );
        }
    #else
        client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_VOTE_NOMAPS" );
    #endif
    }

#if IS_DEBUG_ENABLED > 0
    DEBUG_LOGGER( 4, "" )
    DEBUG_LOGGER( 4, "   [PLAYER CHOICES]" )
#endif
}

public vote_countdownPendingVote()
{
    static countdown = 7;
    
    // visual countdown
    set_hudmessage( 0, 222, 50, -1.0, 0.13, 0, 1.0, 0.94, 0.0, 0.0, -1 );
    show_hudmessage( 0, "%L", LANG_PLAYER, "GAL_VOTE_COUNTDOWN", countdown );
    
    // audio countdown
    if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_COUNTDOWN ) )
    {
        new word[ 6 ];
        num_to_word( countdown, word, 5 );
        
        client_cmd( 0, "spk ^"fvox/%s^"", word );
    }
    
    // decrement the countdown
    countdown--;
    
    if( countdown == 0 )
    {
        countdown = 7;
    }
}

stock vote_addNominations()
{
    DEBUG_LOGGER( 4, "   [NOMINATIONS ( %i )]", g_nominationCnt )
    
    if( g_nominationCnt )
    {
        // set how many total nominations we can use in this vote
        new maxNominations    = get_pcvar_num( cvar_nomQtyUsed );
        new slotsAvailable    = g_choiceMax - g_totalVoteOptions;
        new voteNominationMax = ( maxNominations ) ? min( maxNominations, slotsAvailable ) : slotsAvailable;
        
        // set how many total nominations each player is allowed
        new playerNominationMax = min( get_pcvar_num( cvar_nomPlayerAllowance ), MAX_NOMINATION_CNT );
        
        // add as many nominations as we can
        // [TODO: develop a better method of determining which nominations make the cut; either FIFO or random]
        new idxMap, player_id, mapName[ 32 ];

#if IS_DEBUG_ENABLED > 0
        new nominator_id, playerName[ 32 ];
        
        for( new idxNomination = playerNominationMax; idxNomination >= 1; --idxNomination )
        {
            for( player_id = 1; player_id <= MAX_PLAYER_CNT; ++player_id )
            {
                idxMap = g_nomination[ player_id ][ idxNomination ];
                
                if( idxMap >= 0 )
                {
                    ArrayGetString( g_nominationMap, idxMap, mapName, sizeof( mapName ) - 1 );
                    nominator_id = nomination_getPlayer( idxMap );
                    get_user_name( nominator_id, playerName, sizeof( playerName ) - 1 );
                    
                    DEBUG_LOGGER( 4, "      %-32s %s", mapName, playerName )
                }
            }
        }
        DEBUG_LOGGER( 4, "" )
#endif
        
        for( new idxNomination = playerNominationMax; idxNomination >= 1; --idxNomination )
        {
            for( player_id = 1; player_id <= MAX_PLAYER_CNT; ++player_id )
            {
                idxMap = g_nomination[ player_id ][ idxNomination ];
                
                if( idxMap >= 0 )
                {
                    ArrayGetString( g_nominationMap, idxMap, mapName, sizeof( mapName ) - 1 );
                    copy( g_mapsVoteMenuNames[ g_totalVoteOptions++ ], sizeof( g_mapsVoteMenuNames[] ) - 1, mapName );
                    
                    if( g_totalVoteOptions == voteNominationMax )
                    {
                        break;
                    }
                }
            }
            
            if( g_totalVoteOptions == voteNominationMax )
            {
                break;
            }
        }
    }
}

stock vote_addFiller()
{
    if( g_totalVoteOptions == g_choiceMax )
    {
        return;
    }
    
    // grab the name of the filler file
    new filename[ 256 ];
    get_cvar_string( "mapcyclefile", filename, sizeof( filename ) - 1 );
    
    // create an array of files that will be pulled from
    new fillerFile[ 8 ][ 256 ];
    new mapsPerGroup[ 8 ], groupCnt;
    
    if( !equal( filename, "*" ) )
    {
        // determine what kind of file it's being used as
        new file = fopen( filename, "rt" );
        
        if( file )
        {
            new buffer[ 16 ];
            fgets( file, buffer, sizeof( buffer ) - 1 );
            trim( buffer );
            fclose( file );
            
            if( equali( buffer, "[groups]" ) )
            {
                DEBUG_LOGGER( 8, " " )
                DEBUG_LOGGER( 8, "this is a [groups] file" )
                // read the filler file to determine how many groups there are ( max of 8 )
                new groupIdx;
                
                file = fopen( filename, "rt" );
                
                while( !feof( file ) )
                {
                    fgets( file, buffer, sizeof( buffer ) - 1 );
                    trim( buffer );
                    DEBUG_LOGGER( 8, "buffer: %s   isdigit: %i   groupCnt: %i  ", buffer, \
                            isdigit( buffer[ 0 ] ), groupCnt )
                    
                    if( isdigit( buffer[ 0 ] ) )
                    {
                        if( groupCnt < 8 )
                        {
                            groupIdx                 = groupCnt++;
                            mapsPerGroup[ groupIdx ] = str_to_num( buffer );
                            formatex( fillerFile[ groupIdx ], sizeof( fillerFile[] ) - 1,
                                    "%s/%i.ini", DIR_CONFIGS, groupCnt )
                            DEBUG_LOGGER( 8, "fillerFile: %s", fillerFile[ groupIdx ] )
                        }
                        else
                        {
                            log_error( AMX_ERR_BOUNDS, "%L", LANG_SERVER, "GAL_GRP_FAIL_TOOMANY", filename );
                            break;
                        }
                    }
                }
                
                fclose( file );
                
                if( groupCnt == 0 )
                {
                    log_error( AMX_ERR_GENERAL, "%L", LANG_SERVER, "GAL_GRP_FAIL_NOCOUNTS", filename );
                    return;
                }
            }
            else
            {
                // we presume it's a listing of maps, ala mapcycle.txt
                copy( fillerFile[ 0 ], sizeof( filename ) - 1, filename );
                mapsPerGroup[ 0 ] = 8;
                groupCnt          = 1;
            }
        }
        else
        {
            log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_FILLER_NOTFOUND", fillerFile );
        }
    }
    else
    {
        // we'll be loading all maps in the /maps folder
        copy( fillerFile[ 0 ], sizeof( filename ) - 1, filename );
        mapsPerGroup[ 0 ] = 8;
        groupCnt          = 1;
    }
    
    // fill remaining slots with random maps from each filler file, as much as possible
    new mapCnt, mapKey, allowedCnt, unsuccessfulCnt, choiceIdx, mapName[ 32 ];
    
    for( new groupIdx = 0; groupIdx < groupCnt; ++groupIdx )
    {
        mapCnt = map_loadFillerList( fillerFile[ groupIdx ] );
        DEBUG_LOGGER( 8, "[%i] groupCnt:%i   mapCnt: %i   g_totalVoteOptions: %i   \
                g_choiceMax: %i   fillerFile: %s", groupIdx, groupCnt, mapCnt, \
                g_totalVoteOptions, g_choiceMax, fillerFile[ groupIdx ] )
        
        if( ( g_totalVoteOptions < g_choiceMax )
            && mapCnt )
        {
            unsuccessfulCnt = 0;
            allowedCnt      = min( min( mapsPerGroup[ groupIdx ], g_choiceMax - g_totalVoteOptions ), mapCnt );
            DEBUG_LOGGER( 8, "[%i] allowedCnt: %i   mapsPerGroup: %i   Max-Cnt: %i", groupIdx, \
                    allowedCnt, mapsPerGroup[ groupIdx ], g_choiceMax - g_totalVoteOptions )
            
            for( choiceIdx = 0; choiceIdx < allowedCnt; ++choiceIdx )
            {
                mapKey = random_num( 0, mapCnt - 1 );
                ArrayGetString( g_fillerMap, mapKey, mapName, sizeof( mapName ) - 1 );
                DEBUG_LOGGER( 8, "[%i] choiceIdx: %i   allowedCnt: %i   mapKey: %i   mapName: %s", \
                        groupIdx, choiceIdx, allowedCnt, mapKey, mapName )
                unsuccessfulCnt = 0;
                
                while( ( map_isInMenu( mapName )
                         || equal( g_currentMap, mapName )
                         || map_isTooRecent( mapName )
                         || prefix_isInMenu( mapName ) )
                       && unsuccessfulCnt < mapCnt )
                {
                    unsuccessfulCnt++;
                    
                    if( ++mapKey == mapCnt )
                    {
                        mapKey = 0;
                    }
                    ArrayGetString( g_fillerMap, mapKey, mapName, sizeof( mapName ) - 1 );
                }
                
                if( unsuccessfulCnt == mapCnt )
                {
                    //print_colored( 0, "unsuccessfulCnt: %i  mapCnt: %i", unsuccessfulCnt, mapCnt );
                    // there aren't enough maps in this filler file to continue adding anymore
                    break;
                }
                
                //print_colored( 0, "mapIdx: %i  map: %s", mapIdx, mapName );
                copy( g_mapsVoteMenuNames[ g_totalVoteOptions++ ], sizeof( g_mapsVoteMenuNames[] ) - 1, mapName );
                DEBUG_LOGGER( 8, "[%i] mapName: %s   unsuccessfulCnt: %i   mapCnt: %i   \
                        g_totalVoteOptions: %i", \
                        groupIdx, mapName, unsuccessfulCnt, mapCnt, g_totalVoteOptions )
            }
        }
    }
}

stock vote_loadChoices()
{
    vote_addNominations();
    vote_addFiller();
    
    return g_totalVoteOptions;
}

stock vote_loadRunoffChoices()
{
    DEBUG_LOGGER( 16, "At vote_loadRunoffChoices --- Runoff map1: %s, Runoff map2: %s", \
            g_mapsVoteMenuNames[ g_arrayOfRunOffChoices[ 0 ] ], \
            g_mapsVoteMenuNames[ g_arrayOfRunOffChoices[ 1 ] ] )
    
    new runOffNameChoices[ 2 ][ MAX_MAPNAME_LEN + 1 ];
    copy( runOffNameChoices[ 0 ], sizeof( runOffNameChoices[] ) - 1, g_mapsVoteMenuNames[ g_arrayOfRunOffChoices[ 0 ] ] );
    copy( runOffNameChoices[ 1 ], sizeof( runOffNameChoices[] ) - 1, g_mapsVoteMenuNames[ g_arrayOfRunOffChoices[ 1 ] ] );
    
    copy( g_mapsVoteMenuNames[ 0 ], sizeof( g_mapsVoteMenuNames[] ) - 1, runOffNameChoices[ 0 ] );
    copy( g_mapsVoteMenuNames[ 1 ], sizeof( g_mapsVoteMenuNames[] ) - 1, runOffNameChoices[ 1 ] );
}

public vote_handleDisplay()
{
    // announce: "time to choose"
    if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_TIMETOCHOOSE ) )
    {
        client_cmd( 0, "spk Gman/Gman_Choose%i", random_num( 1, 2 ) );
    }
    
    if( g_voteStatus & VOTE_IS_RUNOFF )
    {
        g_voteDuration = get_pcvar_num( cvar_runoffDuration );
    }
    else
    {
        g_voteDuration = get_pcvar_num( cvar_voteDuration );
    }

#if IS_DEBUG_ENABLED > 0
    g_voteDuration = 5
#endif
    
    if( get_pcvar_num( cvar_voteStatus )
        && get_pcvar_num( cvar_voteStatusType ) == SHOWSTATUSTYPE_PERCENTAGE )
    {
        copy( g_totalVoteAtMapType, sizeof( g_totalVoteAtMapType ) - 1, "%" );
    }
    
    if( get_cvar_num( "gal_debug" ) & 4 )
    {
        set_task( 2.0, "dbg_fakeVotes", TASKID_DBG_FAKEVOTES );
    }
    
    // make sure the display is constructed from scratch
    g_refreshVoteStatus = true;
    
    // ensure the vote status doesn't indicate expired
    g_voteStatus &= ~VOTE_HAS_EXPIRED;
    
    new vote_display_task_argument[ 3 ];
    vote_display_task_argument[ 0 ] = true;
    vote_display_task_argument[ 1 ] = 0;
    vote_display_task_argument[ 2 ] = false;
    
    if( get_pcvar_num( cvar_voteStatus ) == SHOWSTATUS_VOTE )
    {
        set_task( 1.0, "vote_display", TASKID_VOTE_DISPLAY, vote_display_task_argument, sizeof( vote_display_task_argument ), "a", g_voteDuration );
    }
    else
    {
        set_task( 1.0, "vote_display", TASKID_VOTE_DISPLAY, vote_display_task_argument, sizeof( vote_display_task_argument ) );
    }
}

public vote_display( vote_display_task_argument[ 3 ] )
{
    static allKeys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 |
                     MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9 | MENU_KEY_0;
    
    static keys, voteStatus[ 512 ], g_totalVoteAtMap[ 16 ];
    
    new updateTimeRemaining = vote_display_task_argument[ 0 ];
    new player_id           = vote_display_task_argument[ 1 ];

#if IS_DEBUG_ENABLED > 0
    new snuff = ( player_id > 0 ) ? g_snuffDisplay[ player_id ] : -1;
    
    DEBUG_LOGGER( 4, "   [votedisplay( )] player_id: %i  updateTimeRemaining: %i\
        unsnuffDisplay: %i  g_snuffDisplay: %i  g_refreshVoteStatus: %i\
        g_totalVoteOptions: %i  len( g_vote ): %i  len( voteStatus ): %i", \
            vote_display_task_argument[ 1 ], vote_display_task_argument[ 0 ], \
            vote_display_task_argument[ 2 ], snuff, g_refreshVoteStatus, \
            g_totalVoteOptions, strlen( g_vote ), strlen( voteStatus ) )
#endif
    
    if( player_id > 0
        && g_snuffDisplay[ player_id ] )
    {
        new unsnuffDisplay = vote_display_task_argument[ 2 ];
        
        if( unsnuffDisplay )
        {
            g_snuffDisplay[ player_id ] = false;
        }
        else
        {
            return;
        }
    }
    
    new isVoteOver = ( updateTimeRemaining == -1
                       && player_id == -1 );
    new charCnt;
    
    if( g_refreshVoteStatus
        || isVoteOver )
    {
        new voteCnt;
        
        // wipe the previous vote status clean
        voteStatus[ 0 ] = 0;
        keys            = MENU_KEY_0;
        
        // add the header
        if( isVoteOver )
        {
            charCnt = formatex( voteStatus, sizeof( voteStatus ) - 1, "%s%L^n", CLR_YELLOW, LANG_SERVER, "GAL_RESULT" );
        }
        else
        {
            charCnt = formatex( voteStatus, sizeof( voteStatus ) - 1, "%s%L^n", CLR_YELLOW, LANG_SERVER, "GAL_CHOOSE" );
        }
        
        // add maps to the menu
        for( new choiceIdx = 0; choiceIdx < g_totalVoteOptions; ++choiceIdx )
        {
            voteCnt = g_arrayOfMapsWithVotesNumber[ choiceIdx ];
            getTotalVotesAtMap( g_totalVoteAtMap, sizeof( g_totalVoteAtMap ) - 1, voteCnt );
            
            charCnt += formatex( voteStatus[ charCnt ], sizeof( voteStatus ) - 1 - charCnt, "^n%s%i. %s%s%s",
                    CLR_RED, choiceIdx + 1, CLR_WHITE, g_mapsVoteMenuNames[ choiceIdx ], g_totalVoteAtMap );
            
            keys |= ( 1 << choiceIdx );
        }
        
        new allowStay = ( g_voteStatus & VOTE_IS_EARLY );
        new isRunoff  = ( g_voteStatus & VOTE_IS_RUNOFF );
        
        new bool:allowExtend = ( IS_FINAL_VOTE
                                 && !isRunoff )
        
        if( g_isTimeToChangeLevel
            && !isRunoff )
        {
            allowExtend = false;
            allowStay   = true;
        }
        
        if( g_isRunOffNeedingKeepCurrentMap )
        {
            // if it is a end map RunOff, then it is a extend button, not a keep current map button
            if( IS_FINAL_VOTE )
            {
                allowExtend = true;
            }
            else
            {
                allowExtend = false;
            }
            
            allowStay = true;
        }
        
        // add optional menu item
        if( g_is_map_extension_allowed )
        {
            if( allowExtend
                || allowStay )
            {
                // if it's not a runoff vote, add a space between the maps and the additional option
                if( g_voteStatus & VOTE_IS_RUNOFF == 0 )
                {
                    charCnt += formatex( voteStatus[ charCnt ], sizeof( voteStatus ) - 1 - charCnt, "^n" );
                }
                
                getTotalVotesAtMap( g_totalVoteAtMap, sizeof( g_totalVoteAtMap ) - 1, g_arrayOfMapsWithVotesNumber[ g_totalVoteOptions ] );
                
                if( allowExtend )
                {
                    new extend_step = 15
                    new extend_option_type[ 32 ]
                    
                    // add the "Extend Map" menu item.
                    if( g_is_maxrounds_vote_map )
                    {
                        extend_step = get_pcvar_num( cvar_extendmapStepRounds )
                        copy( extend_option_type, charsmax( extend_option_type ), "GAL_OPTION_EXTEND_ROUND" )
                    }
                    else
                    {
                        extend_step = floatround( get_pcvar_float( cvar_extendmapStep ) )
                        copy( extend_option_type, charsmax( extend_option_type ), "GAL_OPTION_EXTEND" )
                    }
                    
                    charCnt += formatex( voteStatus[ charCnt ], sizeof( voteStatus ) - 1 - charCnt,
                            "^n%s%i. %s%L%s", CLR_RED, g_totalVoteOptions + 1, CLR_WHITE, LANG_SERVER,
                            extend_option_type, g_currentMap, extend_step, g_totalVoteAtMap );
                }
                else
                {
                    // add the "Stay Here" menu item
                    charCnt += formatex( voteStatus[ charCnt ], sizeof( voteStatus ) - 1 - charCnt,
                            "^n%s%i. %s%L%s", CLR_RED, g_totalVoteOptions + 1,
                            CLR_WHITE, LANG_SERVER, "GAL_OPTION_STAY", g_totalVoteAtMap );
                }
                
                keys |= ( 1 << g_totalVoteOptions );
            }
            
            // make a copy of the virgin menu
            new cleanCharCnt = copy( g_vote, sizeof( g_vote ) - 1, voteStatus );
            
            // append a "None" option on for people to choose if they don't like any other choice
            formatex( g_vote[ cleanCharCnt ], sizeof( g_vote ) - 1 - cleanCharCnt,
                    "^n^n%s0. %s%L", CLR_RED, CLR_WHITE, LANG_SERVER, "GAL_OPTION_NONE" );
            
            charCnt += formatex( voteStatus[ charCnt ], sizeof( voteStatus ) - 1 - charCnt, "^n^n" );
            
            g_refreshVoteStatus = false;
        }
    }
    
    static voteFooter[ 32 ];
    
    if( updateTimeRemaining
        && get_pcvar_num( cvar_voteExpCountdown ) )
    {
        charCnt = copy( voteFooter, sizeof( voteFooter ) - 1, "^n^n" );
        
        g_voteDuration--;
        formatex( voteFooter[ charCnt ], sizeof( voteFooter ) - 1 - charCnt, "%s%L: %s%i",
                CLR_GREY, LANG_SERVER, "GAL_TIMELEFT", CLR_RED, g_voteDuration );
    }
    
    // create the different displays
    static menuClean[ 512 ], menuDirty[ 512 ];
    menuClean[ 0 ] = 0;
    menuDirty[ 0 ] = 0;
    
    formatex( menuClean, sizeof( menuClean ) - 1, "%s%s", g_vote, voteFooter );
    
    if( !isVoteOver )
    {
        formatex( menuDirty, sizeof( menuDirty ) - 1, "%s%s", voteStatus, voteFooter );
    }
    else
    {
        formatex( menuDirty, sizeof( menuDirty ) - 1, "%s^n^n%s%L", voteStatus, CLR_YELLOW, LANG_SERVER, "GAL_VOTE_ENDED" );
    }
    
    new menuid, menukeys;
    
    // display the vote
    new showStatus = get_pcvar_num( cvar_voteStatus );
    
    if( player_id > 0 )
    {
        // optionally display to single player that just voted
        if( showStatus == SHOWSTATUS_VOTE )
        {
            new name[ 32 ];
            get_user_name( player_id, name, 31 );
            
            DEBUG_LOGGER( 4, "    [%s ( dirty, just voted )]", name )
            DEBUG_LOGGER( 4, "        %s", menuDirty )
            
            get_user_menu( player_id, menuid, menukeys );
            
            if( menuid == 0
                || menuid == g_menuChooseMap )
            {
                show_menu( player_id, allKeys, menuDirty, max( 1, g_voteDuration ), MENU_CHOOSEMAP );
            }
        }
    }
    else
    {
        // display to everyone
        new players[ 32 ], playerCnt;
        get_players( players, playerCnt, "ch" ); // skip bots and hltv
        
        for( new playerIdx = 0; playerIdx < playerCnt; ++playerIdx )
        {
            player_id = players[ playerIdx ];
            
            if( g_voted[ player_id ] == false
                && !isVoteOver )
            {
                if( playerIdx == 0 )
                {
                    new name[ 32 ];
                    get_user_name( player_id, name, 31 );
                    
                    DEBUG_LOGGER( 4, "    [%s ( clean )]", name )
                    DEBUG_LOGGER( 4, "        %s", menuClean )
                }
                
                get_user_menu( player_id, menuid, menukeys );
                
                if( menuid == 0
                    || menuid == g_menuChooseMap )
                {
                    show_menu( player_id, keys, menuClean, g_voteDuration, MENU_CHOOSEMAP );
                }
            }
            else
            {
                if( ( isVoteOver
                      && showStatus )
                    || ( showStatus == SHOWSTATUS_VOTE
                         && g_voted[ player_id ] ) )
                {
                    if( playerIdx == 0 )
                    {
                        new name[ 32 ];
                        get_user_name( player_id, name, 31 );
                        
                        DEBUG_LOGGER( 4, "    [%s ( dirty )]", name )
                        DEBUG_LOGGER( 4, "        %s", menuDirty )
                    }
                    
                    get_user_menu( player_id, menuid, menukeys );
                    
                    if( menuid == 0
                        || menuid == g_menuChooseMap )
                    {
                        show_menu( player_id, allKeys, menuDirty, ( isVoteOver ) ? 5 : max( 1, g_voteDuration ), MENU_CHOOSEMAP );
                    }
                }
            }
            
            if( player_id == 1 )
            {
                DEBUG_LOGGER( 4, "" )
            }
        }
    }
}

stock getTotalVotesAtMap( g_totalVoteAtMap[], g_totalVoteAtMapLen, voteCnt )
{
    if( voteCnt
        && get_pcvar_num( cvar_voteStatusType ) == SHOWSTATUSTYPE_PERCENTAGE )
    {
        voteCnt = percent( voteCnt, g_totalVotesCounted );
    }
    
    if( get_pcvar_num( cvar_voteStatus )
        && voteCnt )
    {
        formatex( g_totalVoteAtMap, g_totalVoteAtMapLen, " %s( %i%s )", CLR_GREY, voteCnt, g_totalVoteAtMapType );
    }
    else
    {
        g_totalVoteAtMap[ 0 ] = 0;
    }
}

public vote_expire()
{
    g_voteStatus |= VOTE_HAS_EXPIRED;

#if IS_DEBUG_ENABLED > 0
    DEBUG_LOGGER( 4, "" )
    DEBUG_LOGGER( 4, "   [VOTE RESULT]" )
    new g_totalVoteAtMap[ 16 ];
    
    for( new userVoteMapChoiceIndex = 0; userVoteMapChoiceIndex <= g_totalVoteOptions; ++userVoteMapChoiceIndex )
    {
        getTotalVotesAtMap( g_totalVoteAtMap, sizeof( g_totalVoteAtMap ) - 1,
                g_arrayOfMapsWithVotesNumber[ userVoteMapChoiceIndex ] );
        
        DEBUG_LOGGER( 4, "      %2i/%3i  %i. %s", \
                g_arrayOfMapsWithVotesNumber[ userVoteMapChoiceIndex ], g_totalVoteAtMap, \
                userVoteMapChoiceIndex, g_mapsVoteMenuNames[ userVoteMapChoiceIndex ] )
    }
    DEBUG_LOGGER( 4, "" )
#endif
    
    g_vote[ 0 ] = 0;
    
    // determine the number of votes for 1st and 2nd place
    new numberOfVotesAtFirstPlace, numberOfVotesAtSecondPlace, totalVotes;
    
    for( new userVoteMapChoiceIndex = 0;
         userVoteMapChoiceIndex <= g_totalVoteOptions; ++userVoteMapChoiceIndex )
    {
        totalVotes += g_arrayOfMapsWithVotesNumber[ userVoteMapChoiceIndex ];
        
        if( numberOfVotesAtFirstPlace < g_arrayOfMapsWithVotesNumber[ userVoteMapChoiceIndex ] )
        {
            numberOfVotesAtSecondPlace = numberOfVotesAtFirstPlace;
            numberOfVotesAtFirstPlace  = g_arrayOfMapsWithVotesNumber[ userVoteMapChoiceIndex ];
        }
        else if( numberOfVotesAtSecondPlace < g_arrayOfMapsWithVotesNumber[ userVoteMapChoiceIndex ] )
        {
            numberOfVotesAtSecondPlace = g_arrayOfMapsWithVotesNumber[ userVoteMapChoiceIndex ];
        }
    }
    
    // determine which maps are in 1st and 2nd place
    new firstPlaceChoices[ MAX_MAPS_IN_VOTE + 1 ], numberOfMapsAtFirstPosition;
    new secondPlaceChoices[ MAX_MAPS_IN_VOTE + 1 ], numberOfMapsAtSecondPosition;
    
    for( new userVoteMapChoiceIndex = 0; userVoteMapChoiceIndex <= g_totalVoteOptions; ++userVoteMapChoiceIndex )
    {
        DEBUG_LOGGER( 16, "At g_arrayOfMapsWithVotesNumber[%d] = %d ", userVoteMapChoiceIndex, \
                g_arrayOfMapsWithVotesNumber[ userVoteMapChoiceIndex ] )
        
        if( g_arrayOfMapsWithVotesNumber[ userVoteMapChoiceIndex ] == numberOfVotesAtFirstPlace )
        {
            // numberOfMapsAtFirstPosition retain the number of draw maps at first position
            firstPlaceChoices[ numberOfMapsAtFirstPosition++ ] = userVoteMapChoiceIndex;
        }
        else if( g_arrayOfMapsWithVotesNumber[ userVoteMapChoiceIndex ] == numberOfVotesAtSecondPlace )
        {
            secondPlaceChoices[ numberOfMapsAtSecondPosition++ ] = userVoteMapChoiceIndex;
        }
    }
    
    // At for: g_totalVoteOptions: 5, numberOfMapsAtFirstPosition: 3, numberOfMapsAtSecondPosition: 0
    DEBUG_LOGGER( 16, "At for: g_totalVoteOptions: %d, numberOfMapsAtFirstPosition: %d, \
            numberOfMapsAtSecondPosition: %d", \
            g_totalVoteOptions, numberOfMapsAtFirstPosition, numberOfMapsAtSecondPosition )
    
    // announce the outcome
    new winnerVoteMapIndex;
    
    if( numberOfVotesAtFirstPlace )
    {
        // start a runoff vote, if needed
        if( get_pcvar_num( cvar_runoffEnabled )
            && !( g_voteStatus & VOTE_IS_RUNOFF ) )
        {
            // if the top vote getting map didn't receive over 50% of the votes cast, start runoff vote
            if( numberOfVotesAtFirstPlace <= totalVotes / 2 )
            {
                // announce runoff voting requirement
            #if AMXX_VERSION_NUM < 183
                new players_ids[ 32 ]
                
                new playerIndex_idsCounter
                
                get_players( players_ids, playerIndex_idsCounter, "ch" );
                
                for( new i = 0; i < playerIndex_idsCounter; i++ )
                {
                    client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ],
                            "GAL_RUNOFF_REQUIRED" );
                }
            #else
                client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_RUNOFF_REQUIRED" );
            #endif
                
                if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_RUNOFFREQUIRED ) )
                {
                    client_cmd( 0, "spk ^"run officer( e40 ) voltage( e30 ) accelerating( s70 ) \
                            is required^"" );
                }
                
                // let the server know the next vote will be a runoff
                g_voteStatus |= VOTE_IS_RUNOFF;
                
                if( numberOfMapsAtFirstPosition > 2 )
                {
                    DEBUG_LOGGER( 16, "0 - firstPlaceChoices[ numberOfMapsAtFirstPosition - 1 ] : %d", \
                            firstPlaceChoices[ numberOfMapsAtFirstPosition - 1 ] )
                    
                    // determine the two choices that will be facing off
                    new firstChoiceIndex
                    new secondChoiceIndex
                    
                    firstChoiceIndex  = random_num( 0, numberOfMapsAtFirstPosition - 1 );
                    secondChoiceIndex = random_num( 0, numberOfMapsAtFirstPosition - 1 );
                    
                    DEBUG_LOGGER( 16, "1 - At: firstChoiceIndex: %d, secondChoiceIndex: %d", \
                            firstChoiceIndex, secondChoiceIndex )
                    
                    if( firstChoiceIndex == secondChoiceIndex )
                    {
                        if( secondChoiceIndex - 1 < 0 )
                        {
                            secondChoiceIndex = secondChoiceIndex + 1;
                        }
                        else
                        {
                            secondChoiceIndex = secondChoiceIndex - 1;
                        }
                    }
                    
                    // if firstPlaceChoices[ numberOfMapsAtFirstPosition - 1 ]  is equal to g_totalVoteOptions
                    // then it option is not a valid map, it is the keep current map option, and must be
                    // informed it to the vote_display function, to show the 1 map options and the keep current map.
                    if( firstPlaceChoices[ firstChoiceIndex ] == g_totalVoteOptions )
                    {
                        g_isRunOffNeedingKeepCurrentMap = true
                        firstChoiceIndex--
                        g_totalVoteOptions_temp = 1;
                    }
                    else if( firstPlaceChoices[ secondChoiceIndex ] == g_totalVoteOptions )
                    {
                        g_isRunOffNeedingKeepCurrentMap = true
                        secondChoiceIndex--
                        g_totalVoteOptions_temp = 1;
                    }
                    else
                    {
                        g_totalVoteOptions_temp = 2;
                    }
                    
                    if( firstChoiceIndex == secondChoiceIndex )
                    {
                        if( secondChoiceIndex - 1 < 0 )
                        {
                            secondChoiceIndex = secondChoiceIndex + 1;
                        }
                        else
                        {
                            secondChoiceIndex = secondChoiceIndex - 1;
                        }
                    }
                    
                    DEBUG_LOGGER( 16, "2 - At: firstChoiceIndex: %d, secondChoiceIndex: %d", \
                            firstChoiceIndex, secondChoiceIndex )
                    
                    g_arrayOfRunOffChoices[ 0 ] = firstPlaceChoices[ firstChoiceIndex ];
                    g_arrayOfRunOffChoices[ 1 ] = firstPlaceChoices[ secondChoiceIndex ];
                    
                    DEBUG_LOGGER( 16, "At GAL_RESULT_TIED1 --- Runoff map1: %s, Runoff map2: %s", \
                            g_mapsVoteMenuNames[ g_arrayOfRunOffChoices[ 0 ] ], \
                            g_mapsVoteMenuNames[ g_arrayOfRunOffChoices[ 1 ] ] )
                
                #if AMXX_VERSION_NUM < 183
                    new players_ids[ 32 ]
                    
                    new playerIndex_idsCounter
                    
                    get_players( players_ids, playerIndex_idsCounter, "ch" );
                    
                    for( new i = 0; i < playerIndex_idsCounter; i++ )
                    {
                        client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ], "GAL_RESULT_TIED1", numberOfMapsAtFirstPosition );
                    }
                #else
                    client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_RESULT_TIED1", \
                            numberOfMapsAtFirstPosition )
                #endif
                }
                else if( numberOfMapsAtFirstPosition == 2 )
                {
                    if( firstPlaceChoices[ 0 ] == g_totalVoteOptions )
                    {
                        g_isRunOffNeedingKeepCurrentMap = true
                        g_arrayOfRunOffChoices[ 0 ]     = firstPlaceChoices[ 1 ];
                        g_totalVoteOptions_temp         = 1;
                    }
                    else if( firstPlaceChoices[ 1 ] == g_totalVoteOptions )
                    {
                        g_isRunOffNeedingKeepCurrentMap = true
                        g_arrayOfRunOffChoices[ 0 ]     = firstPlaceChoices[ 0 ];
                        g_totalVoteOptions_temp         = 1;
                    }
                    else
                    {
                        g_totalVoteOptions_temp     = 2;
                        g_arrayOfRunOffChoices[ 0 ] = firstPlaceChoices[ 0 ];
                        g_arrayOfRunOffChoices[ 1 ] = firstPlaceChoices[ 1 ];
                    }
                    
                    DEBUG_LOGGER( 16, "At numberOfMapsAtFirstPosition == 2 --- Runoff map1: %s, \
                            Runoff map2: %s", \
                            g_mapsVoteMenuNames[ g_arrayOfRunOffChoices[ 0 ] ], \
                            g_mapsVoteMenuNames[ g_arrayOfRunOffChoices[ 1 ] ] )
                }
                else if( numberOfMapsAtSecondPosition == 1 )
                {
                    if( firstPlaceChoices[ 0 ] == g_totalVoteOptions )
                    {
                        g_isRunOffNeedingKeepCurrentMap = true
                        g_arrayOfRunOffChoices[ 0 ]     = secondPlaceChoices[ 0 ];
                        g_totalVoteOptions_temp         = 1;
                    }
                    else if( secondPlaceChoices[ 0 ] == g_totalVoteOptions )
                    {
                        g_isRunOffNeedingKeepCurrentMap = true
                        g_arrayOfRunOffChoices[ 0 ]     = firstPlaceChoices[ 0 ];
                        g_totalVoteOptions_temp         = 1;
                    }
                    else
                    {
                        g_totalVoteOptions_temp     = 2;
                        g_arrayOfRunOffChoices[ 0 ] = firstPlaceChoices[ 0 ];
                        g_arrayOfRunOffChoices[ 1 ] = secondPlaceChoices[ 0 ];
                    }
                    
                    DEBUG_LOGGER( 16, "At numberOfMapsAtSecondPosition == 1 --- Runoff map1: %s, \
                            Runoff map2: %s", \
                            g_mapsVoteMenuNames[ g_arrayOfRunOffChoices[ 0 ] ], \
                            g_mapsVoteMenuNames[ g_arrayOfRunOffChoices[ 1 ] ] )
                }
                else
                {
                    new randonNumber = random_num( 0, numberOfMapsAtSecondPosition - 1 )
                    
                    if( firstPlaceChoices[ 0 ] == g_totalVoteOptions )
                    {
                        g_isRunOffNeedingKeepCurrentMap = true
                        g_arrayOfRunOffChoices[ 0 ]     = secondPlaceChoices[ randonNumber ];
                        g_totalVoteOptions_temp         = 1;
                    }
                    else if( secondPlaceChoices[ randonNumber ] == g_totalVoteOptions )
                    {
                        g_isRunOffNeedingKeepCurrentMap = true
                        g_arrayOfRunOffChoices[ 0 ]     = firstPlaceChoices[ 0 ];
                        g_totalVoteOptions_temp         = 1;
                    }
                    else
                    {
                        g_totalVoteOptions_temp     = 2;
                        g_arrayOfRunOffChoices[ 0 ] = firstPlaceChoices[ 0 ];
                        g_arrayOfRunOffChoices[ 1 ] = secondPlaceChoices[ randonNumber ];
                    }
                    
                    DEBUG_LOGGER( 16, "At numberOfMapsAtSecondPosition == 1 ELSE --- Runoff map1: %s, \
                            Runoff map2: %s", \
                            g_mapsVoteMenuNames[ g_arrayOfRunOffChoices[ 0 ] ], \
                            g_mapsVoteMenuNames[ g_arrayOfRunOffChoices[ 1 ] ] )
                
                #if AMXX_VERSION_NUM < 183
                    new players_ids[ 32 ]
                    
                    new playerIndex_idsCounter
                    
                    get_players( players_ids, playerIndex_idsCounter, "ch" );
                    
                    for( new i = 0; i < playerIndex_idsCounter; i++ )
                    {
                        client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ],
                                "GAL_RESULT_TIED2", numberOfMapsAtSecondPosition );
                    }
                #else
                    client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_RESULT_TIED2",
                            numberOfMapsAtSecondPosition );
                #endif
                }
                // clear all the votes
                vote_resetStats();
                
                // start the runoff vote
                set_task( 5.0, "vote_startDirector", TASKID_VOTE_STARTDIRECTOR );
                
                return;
            }
        }
        
        // if there is a tie for 1st, randomly select one as the winner
        if( numberOfMapsAtFirstPosition > 1 )
        {
            winnerVoteMapIndex = firstPlaceChoices[ random_num( 0, numberOfMapsAtFirstPosition - 1 ) ];
        
        #if AMXX_VERSION_NUM < 183
            new players_ids[ 32 ]
            
            new playerIndex_idsCounter
            
            get_players( players_ids, playerIndex_idsCounter, "ch" );
            
            for( new i = 0; i < playerIndex_idsCounter; i++ )
            {
                client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ],
                        "GAL_WINNER_TIED", numberOfMapsAtFirstPosition );
            }
        #else
            client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_WINNER_TIED",
                    numberOfMapsAtFirstPosition );
        #endif
        }
        else
        {
            winnerVoteMapIndex = firstPlaceChoices[ 0 ];
        }
        
        // winnerVoteMapIndex == g_totalVoteOptions, means that it it keep current map option, then
        // here we keep the current map or extend current map
        if( winnerVoteMapIndex == g_totalVoteOptions )
        {
            if( g_voteStatus & VOTE_IS_EARLY )
            {
                // "stay here" won
            #if AMXX_VERSION_NUM < 183
                new players_ids[ 32 ]
                
                new playerIndex_idsCounter
                
                get_players( players_ids, playerIndex_idsCounter, "ch" );
                
                for( new i = 0; i < playerIndex_idsCounter; i++ )
                {
                    client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ],
                            "GAL_WINNER_STAY" );
                }
            #else
                client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_WINNER_STAY" );
            #endif
                
                // clear all the votes
                vote_resetStats();
                
                // no longer is an early vote
                g_voteStatus &= ~VOTE_IS_EARLY;
            }
            else
            {
                if( g_isTimeToRestart )
                {
                    g_isTimeToRestart = false;
                    
                    // "stay here" won
                    #if AMXX_VERSION_NUM < 183
                    new players_ids[ 32 ]
                    
                    new playerIndex_idsCounter
                    
                    get_players( players_ids, playerIndex_idsCounter, "ch" );
                    
                    for( new i = 0; i < playerIndex_idsCounter; i++ )
                    {
                        client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ],
                                "GAL_WINNER_STAY" );
                    }
                    #else
                    client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_WINNER_STAY" );
                    #endif
                    
                    // no longer is an early vote
                    g_voteStatus &= ~VOTE_IS_EARLY;
                    
                    intermission_display( true )
                }
                else
                {
                    if( g_isTimeToChangeLevel )
                    {
                        // "stay here" won
                        g_isTimeToChangeLevel = false;
                    
                    #if AMXX_VERSION_NUM < 183
                        new players_ids[ 32 ]
                        
                        new playerIndex_idsCounter
                        
                        get_players( players_ids, playerIndex_idsCounter, "ch" );
                        
                        for( new i = 0; i < playerIndex_idsCounter; i++ )
                        {
                            client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ],
                                    "GAL_WINNER_STAY" );
                        }
                    #else
                        client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_WINNER_STAY" );
                    #endif
                    }
                    else
                    {
                        // "extend map" won
                        if( g_is_maxrounds_vote_map )
                        {
                        #if AMXX_VERSION_NUM < 183
                            new players_ids[ 32 ]
                            
                            new playerIndex_idsCounter
                            
                            get_players( players_ids, playerIndex_idsCounter, "ch" );
                            
                            for( new i = 0; i < playerIndex_idsCounter; i++ )
                            {
                                client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ],
                                        "GAL_WINNER_EXTEND_ROUND", get_pcvar_num( cvar_extendmapStepRounds ) );
                            }
                        #else
                            client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_WINNER_EXTEND_ROUND",
                                    get_pcvar_num( cvar_extendmapStepRounds ) );
                        #endif
                        }
                        else
                        {
                        #if AMXX_VERSION_NUM < 183
                            new players_ids[ 32 ]
                            
                            new playerIndex_idsCounter
                            
                            get_players( players_ids, playerIndex_idsCounter, "ch" );
                            
                            for( new i = 0; i < playerIndex_idsCounter; i++ )
                            {
                                client_print_color_internal( players_ids[ i ], "^1%L",
                                        players_ids[ i ], "GAL_WINNER_EXTEND",
                                        floatround( get_pcvar_float( cvar_extendmapStep ) ) );
                            }
                        #else
                            client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_WINNER_EXTEND",
                                    floatround( get_pcvar_float( cvar_extendmapStep ) ) );
                        #endif
                        }
                        
                        map_extend();
                    }
                }
            }
        }
        else
        {
            map_setNext( g_mapsVoteMenuNames[ winnerVoteMapIndex ] );
            server_exec();
        
        #if AMXX_VERSION_NUM < 183
            new players_ids[ 32 ]
            
            new playerIndex_idsCounter
            
            get_players( players_ids, playerIndex_idsCounter, "ch" );
            
            for( new i = 0; i < playerIndex_idsCounter; i++ )
            {
                client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ], "GAL_NEXTMAP",
                        g_mapsVoteMenuNames[ winnerVoteMapIndex ] );
            }
        #else
            client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_NEXTMAP",
                    g_mapsVoteMenuNames[ winnerVoteMapIndex ] );
        #endif
            
            intermission_display()
            
            g_voteStatus |= VOTE_IS_OVER;
        }
    }
    else
    {
        // the initial nextmap
        new initialNextMap[ MAX_MAPNAME_LEN + 1 ];
        get_cvar_string( "amx_nextmap", initialNextMap, sizeof( initialNextMap ) - 1 );
    
    #if AMXX_VERSION_NUM < 183
        new players_ids[ 32 ]
        
        new playerIndex_idsCounter
        
        get_players( players_ids, playerIndex_idsCounter, "ch" );
        
        for( new i = 0; i < playerIndex_idsCounter; i++ )
        {
            client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ],
                    "GAL_WINNER_RANDOM", initialNextMap );
        }
    #else
        client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_WINNER_RANDOM", initialNextMap );
    #endif
        
        intermission_display()
        
        g_voteStatus |= VOTE_IS_OVER;
    }
    
    g_isRunOffNeedingKeepCurrentMap = false;
    g_refreshVoteStatus             = true;
    
    // vote is no longer in progress
    g_voteStatus &= ~VOTE_IN_PROGRESS;
    vote_resetStats();
    
    // if we were in a runoff mode, get out of it
    g_voteStatus &= ~VOTE_IS_RUNOFF;
}

stock map_extend()
{
    DEBUG_LOGGER( 2, "%32s mp_timelimit: %f  g_rtvWait: %f  extendmapStep: %f", "map_extend( in )", \
            get_cvar_float( "mp_timelimit" ), g_rtvWait, get_pcvar_float( cvar_extendmapStep ) )
    
    // reset the "rtv wait" time, taking into consideration the map extension
    if( g_rtvWait )
    {
        g_rtvWait = get_cvar_float( "mp_timelimit" ) + g_rtvWait;
    }
    
    save_time_limit()
    
    // do that actual map extension
    if( g_is_maxrounds_vote_map )
    {
        new extendmap_step_rounds = get_pcvar_num( cvar_extendmapStepRounds )
        
        if( g_is_maxrounds_extend )
        {
            set_cvar_num( "mp_maxrounds", get_pcvar_num( g_maxrounds_pointer ) + extendmap_step_rounds );
            set_cvar_num( "mp_winlimit", 0 );
            
            g_is_maxrounds_extend = false;
        }
        else
        {
            set_cvar_num( "mp_maxrounds", 0 );
            set_cvar_num( "mp_winlimit", get_pcvar_num( g_winlimit_pointer ) + extendmap_step_rounds );
        }
        set_cvar_float( "mp_timelimit", 0.0 );
        
        server_exec()
        g_is_maxrounds_vote_map = false
    }
    else
    {
        set_cvar_num( "mp_maxrounds", 0 );
        set_cvar_num( "mp_winlimit", 0 );
        set_cvar_float( "mp_timelimit", get_cvar_float( "mp_timelimit" ) + get_pcvar_float( cvar_extendmapStep ) );
        
        server_exec();
    }
    
    // clear vote stats
    vote_resetStats();
    
    DEBUG_LOGGER( 2, "%32s mp_timelimit: %f  g_rtvWait: %f  extendmapStep: %f", "map_extend( out )", \
            get_cvar_float( "mp_timelimit" ), g_rtvWait, get_pcvar_float( cvar_extendmapStep ) )
}

stock save_time_limit()
{
    if( !g_isTimeLimitChanged )
    {
        g_isTimeLimitChanged = true;
        
        g_originalTimelimit = get_cvar_float( "mp_timelimit" )
        g_originalMaxRounds = get_pcvar_num( g_maxrounds_pointer )
        g_originalWinLimit  = get_pcvar_num( g_winlimit_pointer )
    }
}

stock vote_resetStats()
{
    g_totalVoteOptions  = 0;
    g_totalVotesCounted = 0;
    
    arrayset( g_arrayOfMapsWithVotesNumber, 0, MAX_MAPS_IN_VOTE + 1 );
    
    // reset everyones' rocks
    arrayset( g_rockedVote, false, sizeof( g_rockedVote ) );
    g_rockedVoteCnt = 0;
    
    // reset everyones' votes
    arrayset( g_voted, false, sizeof( g_voted ) );
}

stock map_isInMenu( map[] )
{
    for( new userVoteMapChoiceIndex = 0; userVoteMapChoiceIndex < g_totalVoteOptions; ++userVoteMapChoiceIndex )
    {
        if( equal( map, g_mapsVoteMenuNames[ userVoteMapChoiceIndex ] ) )
        {
            return true;
        }
    }
    return false;
}

stock prefix_isInMenu( map[] )
{
    if( get_pcvar_num( cvar_voteUniquePrefixes ) )
    {
        new tentativePrefix[ 8 ], existingPrefix[ 8 ], junk[ 8 ];
        
        strtok( map, tentativePrefix, sizeof( tentativePrefix ) - 1, junk, sizeof( junk ) - 1, '_', 1 );
        
        for( new userVoteMapChoiceIndex = 0; userVoteMapChoiceIndex < g_totalVoteOptions;
             ++userVoteMapChoiceIndex )
        {
            strtok( g_mapsVoteMenuNames[ userVoteMapChoiceIndex ], existingPrefix,
                    sizeof( existingPrefix ) - 1, junk, sizeof( junk ) - 1, '_', 1 );
            
            if( equal( tentativePrefix, existingPrefix ) )
            {
                return true;
            }
        }
    }
    return false;
}

stock map_isTooRecent( map[] )
{
    if( get_pcvar_num( cvar_banRecent ) )
    {
        for( new idxBannedMap = 0; idxBannedMap < g_cntRecentMap; ++idxBannedMap )
        {
            if( equal( map, g_recentMap[ idxBannedMap ] ) )
            {
                return true;
            }
        }
    }
    return false;
}

public vote_handleChoice( player_id, key )
{
    if( g_voteStatus & VOTE_HAS_EXPIRED )
    {
        client_cmd( player_id, "^"slot%i^"", key + 1 );
        return;
    }
    
    g_snuffDisplay[ player_id ] = true;
    
    if( g_voted[ player_id ] == false )
    {
        new name[ 32 ];
        
        if( get_pcvar_num( cvar_voteAnnounceChoice ) )
        {
            get_user_name( player_id, name, sizeof( name ) - 1 );
        }
        get_user_name( player_id, name, sizeof( name ) - 1 );
        
        // confirm the player's choice
        if( key == 9 )
        {
            DEBUG_LOGGER( 4, "      %-32s ( none )", name )
            
            if( get_pcvar_num( cvar_voteAnnounceChoice ) )
            {
            #if AMXX_VERSION_NUM < 183
                new players_ids[ 32 ]
                
                new playerIndex_idsCounter
                
                get_players( players_ids, playerIndex_idsCounter, "ch" );
                
                for( new i = 0; i < playerIndex_idsCounter; i++ )
                {
                    client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ],
                            "GAL_CHOICE_NONE_ALL", name );
                }
            #else
                client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_CHOICE_NONE_ALL", name );
            #endif
            }
            else
            {
                client_print_color_internal( player_id, "^1%L", player_id, "GAL_CHOICE_NONE" );
            }
        }
        else
        {
            // increment votes cast count
            g_totalVotesCounted++;
            
            if( key == g_totalVoteOptions )
            {
                // only display the "none" vote if we haven't already voted ( we can make it here from the vote status menu too )
                if( g_voted[ player_id ] == false )
                {
                    DEBUG_LOGGER( 4, "      %-32s ( extend )", name )
                    
                    if( get_pcvar_num( cvar_voteAnnounceChoice ) )
                    {
                    #if AMXX_VERSION_NUM < 183
                        new players_ids[ 32 ]
                        
                        new playerIndex_idsCounter
                        
                        get_players( players_ids, playerIndex_idsCounter, "ch" );
                        
                        for( new i = 0; i < playerIndex_idsCounter; i++ )
                        {
                            client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ],
                                    "GAL_CHOICE_EXTEND_ALL", name );
                        }
                    #else
                        client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_CHOICE_EXTEND_ALL", name );
                    #endif
                    }
                    else
                    {
                        client_print_color_internal( player_id, "^1%L", player_id, "GAL_CHOICE_EXTEND" );
                    }
                }
            }
            else
            {
                DEBUG_LOGGER( 4, "      %-32s %s", name, g_mapsVoteMenuNames[ key ] )
                
                if( get_pcvar_num( cvar_voteAnnounceChoice ) )
                {
                #if AMXX_VERSION_NUM < 183
                    new players_ids[ 32 ]
                    
                    new playerIndex_idsCounter
                    
                    get_players( players_ids, playerIndex_idsCounter, "ch" );
                    
                    for( new i = 0; i < playerIndex_idsCounter; i++ )
                    {
                        client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ],
                                "GAL_CHOICE_MAP_ALL", name, g_mapsVoteMenuNames[ key ] );
                    }
                #else
                    client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_CHOICE_MAP_ALL", name,
                            g_mapsVoteMenuNames[ key ] );
                #endif
                }
                else
                {
                    client_print_color_internal( player_id, "^1%L", player_id, "GAL_CHOICE_MAP",
                            g_mapsVoteMenuNames[ key ] );
                }
            }
            
            // register the player's choice giving extra weight to admin votes
            new voteWeight = get_pcvar_num( cvar_voteWeight );
            
            if( voteWeight > 1
                && has_flag( player_id, g_voteWeightFlags ) )
            {
                g_arrayOfMapsWithVotesNumber[ key ] += voteWeight;
                g_totalVotesCounted                 += ( voteWeight - 1 );
                
                client_print_color_internal( player_id, "^1L", player_id, "GAL_VOTE_WEIGHTED", voteWeight );
            }
            else
            {
                g_arrayOfMapsWithVotesNumber[ key ]++;
            }
        }
        g_voted[ player_id ] = true;
        g_refreshVoteStatus  = true;
    }
    else
    {
        client_cmd( player_id, "^"slot%i^"", key + 1 );
    }
    
    // display the vote again, with status
    if( get_pcvar_num( cvar_voteStatus ) == SHOWSTATUS_VOTE )
    {
        new vote_display_task_argument[ 3 ];
        vote_display_task_argument[ 0 ] = false;
        vote_display_task_argument[ 1 ] = player_id;
        vote_display_task_argument[ 2 ] = true;
        
        set_task( 0.1, "vote_display", TASKID_VOTE_DISPLAY, vote_display_task_argument, sizeof( vote_display_task_argument ) );
    }
}

stock Float:map_getMinutesElapsed()
{
    DEBUG_LOGGER( 2, "%32s mp_timelimit: %f", "map_getMinutesElapsed( in/out )", \
            get_cvar_float( "mp_timelimit" ) )
    
    return get_cvar_float( "mp_timelimit" ) - ( float( get_timeleft() ) / 60.0 );
}

public vote_rock( player_id )
{
    // if an early vote is pending, don't allow any rocks
    if( g_voteStatus & VOTE_IS_EARLY )
    {
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_ROCK_FAIL_PENDINGVOTE" );
        return;
    }
    
    new Float:minutesElapsed = map_getMinutesElapsed();
    
    // if the player is the only one on the server, bring up the vote immediately
    if( get_realplayersnum() == 1
        && minutesElapsed > floatmin( 2.0, g_rtvWait ) )
    {
        vote_startDirector( true );
        return;
    }
    
    // make sure enough time has gone by on the current map
    if( g_rtvWait )
    {
        if( minutesElapsed < g_rtvWait )
        {
            client_print_color_internal( player_id, "^1%L", player_id, "GAL_ROCK_FAIL_TOOSOON",
                    floatround( g_rtvWait - minutesElapsed, floatround_ceil ) );
            return;
        }
    }
    
    // rocks can only be made if a vote isn't already in progress
    if( g_voteStatus & VOTE_IN_PROGRESS )
    {
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_ROCK_FAIL_INPROGRESS" );
        return;
    }
    // and if the outcome of the vote hasn't already been determined
    else if( g_voteStatus & VOTE_IS_OVER )
    {
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_ROCK_FAIL_VOTEOVER" );
        return;
    }
    
    // determine how many total rocks are needed
    new rocksNeeded = vote_getRocksNeeded();
    
    // make sure player hasn't already rocked the vote
    if( g_rockedVote[ player_id ] )
    {
        client_print_color_internal( player_id, "^1%L", player_id, "GAL_ROCK_FAIL_ALREADY",
                rocksNeeded - g_rockedVoteCnt );
        
        rtv_remind( TASKID_REMINDER + player_id );
        return;
    }
    
    // allow the player to rock the vote
    g_rockedVote[ player_id ] = true;
    
    client_print_color_internal( player_id, "^1%L", player_id, "GAL_ROCK_SUCCESS" );
    
    // make sure the rtv reminder timer has stopped
    if( task_exists( TASKID_REMINDER ) )
    {
        remove_task( TASKID_REMINDER );
    }
    
    // determine if there have been enough rocks for a vote yet
    if( ++g_rockedVoteCnt >= rocksNeeded )
    {
        // announce that the vote has been rocked
    #if AMXX_VERSION_NUM < 183
        new players_ids[ 32 ]
        
        new playerIndex_idsCounter
        
        get_players( players_ids, playerIndex_idsCounter, "ch" );
        
        for( new i = 0; i < playerIndex_idsCounter; i++ )
        {
            client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ], "GAL_ROCK_ENOUGH" );
        }
    #else
        client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_ROCK_ENOUGH" );
    #endif
        
        // start up the vote director
        vote_startDirector( true );
    }
    else
    {
        // let the players know how many more rocks are needed
        rtv_remind( TASKID_REMINDER );
        
        if( get_pcvar_num( cvar_rtvReminder ) )
        {
            // initialize the rtv reminder timer to repeat how many rocks are still needed, at regular intervals
            set_task( get_pcvar_float( cvar_rtvReminder ) * 60.0, "rtv_remind", TASKID_REMINDER, _, _, "b" );
        }
    }
}

stock vote_unrock( player_id )
{
    if( g_rockedVote[ player_id ] )
    {
        g_rockedVote[ player_id ] = false;
        g_rockedVoteCnt--;
        // and such
    }
}

stock vote_getRocksNeeded()
{
    return floatround( get_pcvar_float( cvar_rtvRatio ) * float( get_realplayersnum() ), floatround_ceil );
}

public rtv_remind( param )
{
    new player_id = param - TASKID_REMINDER;
    
    // let the players know how many more rocks are needed
    client_print_color_internal( player_id, "^1%L", LANG_PLAYER, "GAL_ROCK_NEEDMORE",
            vote_getRocksNeeded() - g_rockedVoteCnt );
}

// change to the map
public map_change()
{
    // restore the map's timelimit, just in case we had changed it
    map_restoreOriginalTimeLimit();
    
    // grab the name of the map we're changing to
    new map[ MAX_MAPNAME_LEN + 1 ];
    get_cvar_string( "amx_nextmap", map, sizeof( map ) - 1 );
    
    g_isTimeToChangeLevel = false;
    
    // verify we're changing to a valid map
    if( !is_map_valid( map ) )
    {
        // probably admin did something dumb like changed the map time limit below
        // the time remaining in the map, thus making the map over immediately.
        // since the next map is unknown, just restart the current map.
        copy( map, sizeof( map ) - 1, g_currentMap );
    }
    server_cmd( "changelevel %s", map );
}

public map_change_stays()
{
    server_cmd( "changelevel %s", g_currentMap );
}

public cmd_HL1_votemap( player_id )
{
    if( get_pcvar_num( cvar_cmdVotemap ) == 0 )
    {
        con_print( player_id, "%L", player_id, "GAL_DISABLED" );
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

public cmd_HL1_listmaps( player_id )
{
    switch( get_pcvar_num( cvar_cmdListmaps ) )
    {
        case 0:
        {
            con_print( player_id, "%L", player_id, "GAL_DISABLED" );
        }
        case 2:
        {
            map_listAll( player_id );
        }
        default:
        {
            return PLUGIN_CONTINUE;
        }
    }
    return PLUGIN_HANDLED;
}

public map_listAll( player_id )
{
    static lastMapDisplayed[ MAX_PLAYER_CNT + 1 ][ 2 ];
    
    // determine if the player has requested a listing before
    new userid = get_user_userid( player_id );
    
    if( userid != lastMapDisplayed[ player_id ][ LISTMAPS_USERID ] )
    {
        lastMapDisplayed[ player_id ][ LISTMAPS_USERID ] = 0;
    }
    
    new command[ 32 ];
    read_argv( 0, command, sizeof( command ) - 1 );
    
    new arg1[ 8 ], start;
    new mapCount = get_pcvar_num( cvar_listmapsPaginate );
    
    if( mapCount )
    {
        if( read_argv( 1, arg1, sizeof( arg1 ) - 1 ) )
        {
            if( arg1[ 0 ] == '*' )
            {
                // if the last map previously displayed belongs to the current user,
                // start them off there, otherwise, start them at 1
                if( lastMapDisplayed[ player_id ][ LISTMAPS_USERID ] )
                {
                    start = lastMapDisplayed[ player_id ][ LISTMAPS_LAST ] + 1;
                }
                else
                {
                    start = 1;
                }
            }
            else
            {
                start = str_to_num( arg1 );
            }
        }
        else
        {
            start = 1;
        }
        
        if( player_id == 0
            && read_argc() == 3
            && read_argv( 2, arg1, sizeof( arg1 ) - 1 ) )
        {
            mapCount = str_to_num( arg1 );
        }
    }
    
    if( start < 1 )
    {
        start = 1;
    }
    
    if( start >= g_nominationMapCnt )
    {
        start = g_nominationMapCnt - 1;
    }
    
    new end = mapCount ? start + mapCount - 1 : g_nominationMapCnt;
    
    if( end > g_nominationMapCnt )
    {
        end = g_nominationMapCnt;
    }
    
    // this enables us to use 'command *' to get the next group of maps, when paginated
    lastMapDisplayed[ player_id ][ LISTMAPS_USERID ] = userid;
    lastMapDisplayed[ player_id ][ LISTMAPS_LAST ]   = end - 1;
    
    con_print( player_id, "^n----- %L -----", player_id, "GAL_LISTMAPS_TITLE", g_nominationMapCnt );
    
    new nominated[ 64 ], nominator_id, name[ 32 ], mapName[ 32 ], idx;
    
    for( idx = start - 1; idx < end; idx++ )
    {
        nominator_id = nomination_getPlayer( idx );
        
        if( nominator_id )
        {
            get_user_name( nominator_id, name, sizeof( name ) - 1 );
            formatex( nominated, sizeof( nominated ) - 1, "%L", player_id, "GAL_NOMINATEDBY", name );
        }
        else
        {
            nominated[ 0 ] = 0;
        }
        ArrayGetString( g_nominationMap, idx, mapName, sizeof( mapName ) - 1 );
        con_print( player_id, "%3i: %s  %s", idx + 1, mapName, nominated );
    }
    
    if( mapCount
        && mapCount < g_nominationMapCnt )
    {
        con_print( player_id, "----- %L -----", player_id, "GAL_LISTMAPS_SHOWING", start, idx, g_nominationMapCnt );
        
        if( end < g_nominationMapCnt )
        {
            con_print( player_id, "----- %L -----", player_id, "GAL_LISTMAPS_MORE", command, end + 1, command );
        }
    }
}

stock con_print( player_id, message[], { Float, Sql, Result, _ }: ... )
{
    new consoleMessage[ 256 ];
    vformat( consoleMessage, sizeof( consoleMessage ) - 1, message, 3 );
    
    if( player_id )
    {
        new authid[ 32 ];
        get_user_authid( player_id, authid, 31 );
        
        if( !equal( authid, "STEAM_ID_LAN" ) )
        {
            console_print( player_id, consoleMessage );
            return;
        }
    }
    
    server_print( consoleMessage );
}

#if AMXX_VERSION_NUM < 183
public client_disconnect( player_id )
#else
public client_disconnected( player_id )
#endif
{
    g_voted[ player_id ] = false;
    
    // un-rock the vote
    vote_unrock( player_id );
    
    if( get_pcvar_num( cvar_unnominateDisconnected ) )
    {
        new idxMap
        new nominationCnt
        new playerNominationMax
        
        new mapName[ 32 ]
        new nominatedMaps[ 256 ]
        
        // cancel player's nominations
        playerNominationMax = min( get_pcvar_num( cvar_nomPlayerAllowance ), MAX_NOMINATION_CNT );
        
        for( new idxNomination = 1; idxNomination <= playerNominationMax; ++idxNomination )
        {
            idxMap = g_nomination[ player_id ][ idxNomination ];
            
            if( idxMap >= 0 )
            {
                ArrayGetString( g_nominationMap, idxMap, mapName, sizeof( mapName ) - 1 );
                nominationCnt++;
                format( nominatedMaps, sizeof( nominatedMaps ) - 1, "%s%s, ", nominatedMaps, mapName );
                g_nomination[ player_id ][ idxNomination ] = -1;
            }
        }
        
        if( nominationCnt )
        {
            // strip the extraneous ", " from the string
            nominatedMaps[ strlen( nominatedMaps ) - 2 ] = 0;
            
            // inform the masses that the maps are no longer nominated
            nomination_announceCancellation( nominatedMaps );
        }
    }
    
    new dbg_playerCnt = get_realplayersnum() - 1;
    DEBUG_LOGGER( 2, "%32s dbg_playerCnt:%i", "client_disconnect( )", dbg_playerCnt )
    
    if( dbg_playerCnt <= 0 )
    {
        srv_handleEmpty();
    }
}

public client_connect( player_id )
{
    set_pcvar_num( cvar_emptyCycle, 0 );
    
    vote_unrock( player_id );
}

/**
 *  Called when the last server player disconnect. This changes the map even if we are at a
 *  map that is on the empty list. This function is different than srv_initEmptyCheck, which
 *  just change the map if it is not on a map at empty list.
 */
stock srv_handleEmpty()
{
    DEBUG_LOGGER( 2, "%32s mp_timelimit: %f  g_originalTimelimit: %f", "srv_handleEmpty(in)", \
            get_cvar_float( "mp_timelimit" ), g_originalTimelimit )
    
    if( g_originalTimelimit != get_cvar_float( "mp_timelimit" ) )
    {
        // it's possible that the map has been extended at least once. that
        // means that if someone comes into the server, the time limit will
        // be the extended time limit rather than the normal time limit. bad.
        // reset the original time limit
        map_restoreOriginalTimeLimit();
    }
    
    // might be utilizing "empty server" feature
    if( g_isUsingEmptyCycle
        && g_emptyMapCnt )
    {
        srv_startEmptyCountdown();
    }
    DEBUG_LOGGER( 2, "g_isUsingEmptyCycle = %d, g_emptyMapCnt = %d", g_isUsingEmptyCycle, \
            g_emptyMapCnt )
    
    DEBUG_LOGGER( 2, "%32s mp_timelimit: %f  g_originalTimelimit: %f", "srv_handleEmpty(out)", \
            get_cvar_float( "mp_timelimit" ), g_originalTimelimit )
}

/**
 * Start a empty map count down just when the last player disconnect.
 * If the map just entered at the map at the empty list, stays at it.
 */
public srv_initEmptyCheck()
{
    if( ( get_realplayersnum() ) == 0
        && !get_pcvar_num( cvar_emptyCycle ) )
    {
        srv_startEmptyCountdown();
    }
    g_isUsingEmptyCycle = true;
}

stock srv_startEmptyCountdown()
{
    new waitMinutes = get_pcvar_num( cvar_emptyWait );
    
    if( waitMinutes )
    {
        set_task( float( waitMinutes * 60 ), "srv_startEmptyCycle", TASKID_EMPTYSERVER );
    }
}

public srv_startEmptyCycle()
{
    // stop this system at the next map, due we already be at a popular map
    set_pcvar_num( cvar_emptyCycle, 1 );
    
    // set the next map from the empty cycle list,
    // or the first one, if the current map isn't part of the cycle
    new nextMap[ 32 ]
    
    new mapIdx = map_getNext( g_emptyCycleMap, g_currentMap, nextMap );
    
    map_setNext( nextMap );
    
    // if the current map isn't part of the empty cycle,
    // immediately change to next map that is
    if( mapIdx == -1 )
    {
        map_change();
    }
}

stock map_getNext( Array:mapArray, currentMap[], nextMap[ 32 ] )
{
    new thisMap[ 32 ]
    
    new nextmapIdx = 0
    new returnVal  = -1
    new mapCnt     = ArraySize( mapArray )
    
    for( new mapIdx = 0; mapIdx < mapCnt; mapIdx++ )
    {
        ArrayGetString( mapArray, mapIdx, thisMap, sizeof( thisMap ) - 1 );
        
        if( equal( currentMap, thisMap ) )
        {
            if( mapIdx == mapCnt - 1 )
            {
                nextmapIdx = 0
            }
            else
            {
                nextmapIdx = mapIdx + 1
            }
            returnVal = nextmapIdx;
            break;
        }
    }
    ArrayGetString( mapArray, nextmapIdx, nextMap, sizeof( nextMap ) - 1 );
    
    return returnVal;
}

public client_putinserver( player_id )
{
    if( ( g_voteStatus & VOTE_IS_EARLY )
        && !is_user_bot( player_id )
        && !is_user_hltv( player_id ) )
    {
        set_task( 20.0, "srv_announceEarlyVote", player_id );
    }
}

public srv_announceEarlyVote( player_id )
{
    if( is_user_connected( player_id ) )
    {
        client_print_color_internal( player_id, "^4%L", player_id, "GAL_VOTE_EARLY" );
    }
}

stock nomination_announceCancellation( nominations[] )
{
#if AMXX_VERSION_NUM < 183
    new players_ids[ 32 ]
    
    new playerIndex_idsCounter
    
    get_players( players_ids, playerIndex_idsCounter, "ch" );
    
    for( new i = 0; i < playerIndex_idsCounter; i++ )
    {
        client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ],
                "GAL_CANCEL_SUCCESS", nominations );
    }
#else
    client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_CANCEL_SUCCESS", nominations );
#endif
}

stock nomination_clearAll()
{
    for( new idxPlayer = 1; idxPlayer <= MAX_PLAYER_CNT; idxPlayer++ )
    {
        for( new idxNomination = 1; idxNomination <= MAX_NOMINATION_CNT; idxNomination++ )
        {
            g_nomination[ idxPlayer ][ idxNomination ] = -1;
        }
    }
    g_nominationCnt = 0;
}

stock map_announceNomination( player_id, map[] )
{
    new name[ 32 ];
    get_user_name( player_id, name, sizeof( name ) - 1 );

#if AMXX_VERSION_NUM < 183
    new players_ids[ 32 ]
    
    new playerIndex_idsCounter
    
    get_players( players_ids, playerIndex_idsCounter, "ch" );
    
    for( new i = 0; i < playerIndex_idsCounter; i++ )
    {
        client_print_color_internal( players_ids[ i ], "^1%L", players_ids[ i ], "GAL_NOM_SUCCESS",
                name, map );
    }
#else
    client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_NOM_SUCCESS", name, map );
#endif
}

#if AMXX_VERSION_NUM < 180
stock has_flag( player_id, flags[] )
{
    return ( get_user_flags( player_id ) & read_flags( flags ) );
}
#endif

public sort_stringsi( const elem1[], const elem2[], const array[], data[], data_size )
{
    return strcmp( elem1, elem2, 1 );
}

stock get_realplayersnum()
{
    new players[ 32 ], playerCnt;
    get_players( players, playerCnt, "ch" );
    
    return playerCnt;
}

stock percent( is, of )
{
    return ( of != 0 ) ? floatround( floatmul( float( is ) / float( of ), 100.0 ) ) : 0;
}

/**
 * Print colored text to a given player_id. It has to be called to each player using its player_id
 * instead of 'LANG_PLAYER' constant. Just use the 'LANG_PLAYER' constant when using this function
 * to display to all players.
 *
 * If you are at the Amx Mod X 1.8.2, you can call this function using the player_id as 0. But it
 * will use more resources to decode its arguments. To be more optimized you must call it to every
 * player on the server, to display the colored message to all players. Example:
 * @code{.cpp}
 * #if AMXX_VERSION_NUM < 183
 *     new players_ids[ 32 ]
 *
 *     new playerIndex_idsCounter
 *
 *     get_players( players_ids, playerIndex_idsCounter, "ch" );
 *
 *     for( new i = 0; i < playerIndex_idsCounter; i++ )
 *     {
 *         client_print_color_internal( players_ids[ i ], "^1%L %L %L",
 *                 players_ids[ i ], "LANG_A", players_ids[ i ], "LANG_B",
 *                 players_ids[ i ], "LANG_C", any_variable_used_on_LANG_C )
 *     }
 * #else
 *     client_print_color_internal( 0, "^1%L %L %L", LANG_PLAYER, "LANG_A",
 *             LANG_PLAYER, "LANG_B", LANG_PLAYER, "LANG_C", any_variable_used_on_LANG_C );
 * #endif
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
    new formated_message[ MAX_COLOR_MESSAGE ]
    
    if( g_is_supported_color_chat )
    {
#if AMXX_VERSION_NUM < 183
        if( player_id )
        {
            vformat( formated_message, charsmax( formated_message ), message, 3 )
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
                        
                        DEBUG_LOGGER( 64, "Player_Id: %d, formated_message: %s, GetLangTransKey( \
                                formated_message ) != TransKey_Bad: %d", player_id, formated_message, \
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
                    PRINT_COLORED_MESSAGE( player_id, formated_message )
                }
                else
                {
                    client_print( player_id, print_chat, message )
                }
                
                DEBUG_LOGGER( 64, "( in ) Player_Id: %d, Chat printed: %s", player_id, formated_message )
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
    DEBUG_LOGGER( 64, "( out ) Player_Id: %d, Chat printed: %s", player_id, formated_message )
}

/**
 * ConnorMcLeod's [Dyn Native] ColorChat v0.3.2 (04 jul 2013) register_dictionary_colored function:
 *   https://forums.alliedmods.net/showthread.php?p=851160
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
    format( szFileName, charsmax( szFileName ), "%s/lang/%s", szFileName, filename );
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
            strbreak( szBuffer, szKey, charsmax( szKey ), szTranslation, charsmax( szTranslation ) );
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

stock map_restoreOriginalTimeLimit()
{
    DEBUG_LOGGER( 2, "%32s mp_timelimit: %f  g_originalTimelimit: %f", "map_restoreOriginalTimeLimit( in )", \
            get_cvar_float( "mp_timelimit" ), g_originalTimelimit )
    
    if( g_isTimeLimitChanged )
    {
        server_cmd( "mp_timelimit %f", g_originalTimelimit )
        server_cmd( "mp_maxrounds %d", g_originalMaxRounds )
        server_cmd( "mp_winlimit %d", g_originalWinLimit )
        
        server_exec();
        g_isTimeLimitChanged = false;
    }
    
    DEBUG_LOGGER( 2, "%32s mp_timelimit: %f  g_originalTimelimit: %f", "map_restoreOriginalTimeLimit( out )", \
            get_cvar_float( "mp_timelimit" ), g_originalTimelimit )
}

public dbg_fakeVotes()
{
    if( !( g_voteStatus & VOTE_IS_RUNOFF ) )
    {
        g_arrayOfMapsWithVotesNumber[ 0 ] += 2;     // map 1
        g_arrayOfMapsWithVotesNumber[ 1 ] += 2;     // map 2
        g_arrayOfMapsWithVotesNumber[ 2 ] += 0;     // map 3
        g_arrayOfMapsWithVotesNumber[ 3 ] += 0;     // map 4
        g_arrayOfMapsWithVotesNumber[ 4 ] += 0;     // map 5
        g_arrayOfMapsWithVotesNumber[ 5 ] += 2;    // extend option
        
        g_totalVotesCounted = g_arrayOfMapsWithVotesNumber[ 0 ] + g_arrayOfMapsWithVotesNumber[ 1 ] +
                              g_arrayOfMapsWithVotesNumber[ 2 ] + g_arrayOfMapsWithVotesNumber[ 3 ] +
                              g_arrayOfMapsWithVotesNumber[ 4 ] + g_arrayOfMapsWithVotesNumber[ 5 ];
    }
    else if( g_voteStatus & VOTE_IS_RUNOFF )
    {
        g_arrayOfMapsWithVotesNumber[ 0 ] += 2;     // choice 1
        g_arrayOfMapsWithVotesNumber[ 1 ] += 2;     // choice 2
        
        g_totalVotesCounted = g_arrayOfMapsWithVotesNumber[ 0 ] + g_arrayOfMapsWithVotesNumber[ 1 ];
    }
}

/**
 * This function run all tests that are listed at it. Every test that is created must
 * to be called here to it register itself at the Test System and perform the testing.
 */
stock runTests()
{
    new test_name[ SHORT_STRING ]
    
    DEBUG_LOGGER( 1, "^n^n    Executing the 'Galileo Reloaded' Tests: ^n" )
    
    save_server_cvasr_for_test()
    
    ALL_TESTS_TO_EXECUTE
    
    DEBUG_LOGGER( 1, "^n    %d tests succeed.^n    %d tests failed.", g_totalSuccessfulTests, \
            g_totalFailureTests )
    
    if( ArraySize( g_tests_failure_ids ) )
    {
        DEBUG_LOGGER( 1, "^n    The following tests failed:" )
    }
    
    for( new i = 0; i < ArraySize( g_tests_failure_ids ); i++ )
    {
        ArrayGetString( g_tests_idsAndNames, ArrayGetCell( g_tests_failure_ids, i ) - 1,
                test_name, charsmax( test_name ) )
        
        DEBUG_LOGGER( 1, "       %s", test_name )
    }
    
    if( g_max_delay_result )
    {
        DEBUG_LOGGER( 1, "^n    The following tests are waiting until %d seconds to finish:", \
                g_max_delay_result )
    }
    
    for( new i = 0; i < ArraySize( g_tests_delayed_ids ); i++ )
    {
        ArrayGetString( g_tests_idsAndNames, ArrayGetCell( g_tests_delayed_ids, i ) - 1,
                test_name, charsmax( test_name ) )
        
        DEBUG_LOGGER( 1, "       %s", test_name )
    }
    
    if( g_max_delay_result )
    {
        set_task( g_max_delay_result + 1.0, "show_delayed_results" )
        DEBUG_LOGGER( 1, "^n    Finished Tests First Step Execution.^n^n" )
    }
    else
    {
        restore_server_cvars_for_test()
        DEBUG_LOGGER( 1, "^n    Finished 'Galileo Reloaded' Tests Execution.^n^n" )
    }
}

/**
 * This is executed at the end of the delayed tests execution to show its results and restore any
 * cvars variable change.
 */
public show_delayed_results()
{
    new test_name[ SHORT_STRING ]
    
    DEBUG_LOGGER( 1, "^n^n    Showing 'Galileo Reloaded' Tests Delayed Results..." )
    
    DEBUG_LOGGER( 1, "^n    %d tests succeed.^n    %d tests failed.", g_totalSuccessfulTests, \
            g_totalFailureTests )
    
    if( ArraySize( g_tests_failure_ids ) )
    {
        DEBUG_LOGGER( 1, "^n    The following tests failed:" )
    }
    
    for( new i = 0; i < ArraySize( g_tests_failure_ids ); i++ )
    {
        ArrayGetString( g_tests_idsAndNames, ArrayGetCell( g_tests_failure_ids, i ) - 1,
                test_name, charsmax( test_name ) )
        
        DEBUG_LOGGER( 1, "       %s", test_name )
    }
    
    DEBUG_LOGGER( 1, "^n    Finished 'Galileo Reloaded' Tests Execution. ^n^n" )
    
    // clean the testing
    cancel_voting()
    restore_server_cvars_for_test()
}

/**
 * This is the first thing called when a test begin running. It function is to let the
 * Test System know that the test exists and then know how to handle it using
 * the test_id.
 *
 * @param max_delay_result the max delay time to finish test execution.
 * @param test_name the test name to register
 *
 * @return test_id an integer that refers it at the Test System.
 */
stock register_test( max_delay_result, test_name[] )
{
    g_totalSuccessfulTests++
    
    new totalTests = g_totalSuccessfulTests + g_totalFailureTests
    
    ArrayPushString( g_tests_idsAndNames, test_name )
    DEBUG_LOGGER( 1, "    Executing test %d with %d delay - %s ", totalTests, max_delay_result, \
            test_name )
    
    if( g_max_delay_result < max_delay_result )
    {
        g_max_delay_result = max_delay_result
    }
    
    if( max_delay_result )
    {
        ArrayPushCell( g_tests_delayed_ids, totalTests )
    }
    
    return totalTests
}

/**
 * Informs the Test System that the test failed and why.
 *
 * @test_id the test_id at the Test System
 * @failure_reason the reason why the test failed
 * @any a variable number of formatting parameters
 */
stock set_test_failure_internal( test_id, failure_reason[], any: ... )
{
    g_totalSuccessfulTests--
    g_totalFailureTests++
    
    static formated_message[ 256 ]
    
    vformat( formated_message, charsmax( formated_message ), failure_reason, 3 )
    
    ArrayPushCell( g_tests_failure_ids, test_id )
    DEBUG_LOGGER( 1, "       Test failure! %s", formated_message )
}

/**
 * This is a simple test to verify the basic registering test functionality.
 */
stock test_register_test()
{
    new test_id = register_test( 0, "test_register_test" )
    
    if( g_totalSuccessfulTests != 1 )
    {
        SET_TEST_FAILURE( test_id, "g_totalSuccessfulTests must be 1 (it was %d)", \
                g_totalSuccessfulTests )
    }
    
    if( test_id != 1 )
    {
        SET_TEST_FAILURE( test_id, "test_id must be 1 (it was %d)", test_id )
    }
    
    new first_test_name[ 64 ]
    ArrayGetString( g_tests_idsAndNames, 0, first_test_name, charsmax( first_test_name ) )
    
    if( !equal( first_test_name, "test_register_test" ) )
    {
        SET_TEST_FAILURE( test_id, "first_test_name must be 'test_register_test' (it was %s)", \
                first_test_name )
    }
}

/**
 * Test for client connect cvar_emptyCycle behavior.
 */
stock test_gal_in_empty_cycle1()
{
    new test_id = register_test( 0, "test_gal_in_empty_cycle1" )
    
    set_pcvar_num( cvar_emptyCycle, 1 )
    client_connect( 1 )
    
    if( get_pcvar_num( cvar_emptyCycle ) )
    {
        SET_TEST_FAILURE( test_id, "test_gal_in_empty_cycle1() cvar_emptyCycle must be 0 (it was %d)", \
                get_pcvar_num( cvar_emptyCycle ) )
    }
    
    set_pcvar_num( cvar_emptyCycle, 0 )
    client_connect( 1 )
    
    if( get_pcvar_num( cvar_emptyCycle ) )
    {
        SET_TEST_FAILURE( test_id, "test_gal_in_empty_cycle1() cvar_emptyCycle must be 0 (it was %d)", \
                get_pcvar_num( cvar_emptyCycle ) )
    }
}

/**
 * This 1º case test if the current map isn't part of the empty cycle, immediately change to next map
 * that is.
 */
stock test_gal_in_empty_cycle2()
{
    new test_id              = register_test( 0, "test_gal_in_empty_cycle2" )
    new Array: emptyCycleMap = ArrayCreate( 32 );
    
    ArrayPushString( emptyCycleMap, "de_dust2" )
    ArrayPushString( emptyCycleMap, "de_inferno" )
    
    // set the next map from the empty cycle list,
    // or the first one, if the current map isn't part of the cycle
    new nextMap[ 32 ]
    
    new mapIdx = map_getNext( emptyCycleMap, "de_dust2", nextMap );
    
    if( !equal( nextMap, "de_inferno" ) )
    {
        SET_TEST_FAILURE( test_id, "test_gal_in_empty_cycle2() nextMap must be 'de_inferno' \
                (it was %s)", nextMap )
    }
    
    // if the current map isn't part of the empty cycle,
    // immediately change to next map that is
    if( mapIdx == -1 )
    {
        SET_TEST_FAILURE( test_id, "test_gal_in_empty_cycle2() mapIdx must NOT be '-1' \
                (it was %d)", mapIdx )
    }
}

/**
 * This 2º case test if the current map isn't part of the empty cycle, immediately change to next map
 * that is.
 */
stock test_gal_in_empty_cycle3()
{
    new test_id              = register_test( 0, "test_gal_in_empty_cycle3" )
    new Array: emptyCycleMap = ArrayCreate( 32 );
    
    ArrayPushString( emptyCycleMap, "de_dust2" )
    ArrayPushString( emptyCycleMap, "de_inferno" )
    ArrayPushString( emptyCycleMap, "de_dust4" )
    
    // set the next map from the empty cycle list,
    // or the first one, if the current map isn't part of the cycle
    new nextMap[ 32 ]
    
    new mapIdx = map_getNext( emptyCycleMap, "de_inferno", nextMap );
    
    if( !equal( nextMap, "de_dust4" ) )
    {
        SET_TEST_FAILURE( test_id, "test_gal_in_empty_cycle3() nextMap must be 'de_dust4' \
                (it was %s)", nextMap )
    }
    
    // if the current map isn't part of the empty cycle,
    // immediately change to next map that is
    if( mapIdx == -1 )
    {
        SET_TEST_FAILURE( test_id, "test_gal_in_empty_cycle3() mapIdx must NOT be '-1' \
                (it was %d)", mapIdx )
    }
}

/**
 * This 3º case test if the current map isn't part of the empty cycle, immediately change to next map
 * that is.
 */
stock test_gal_in_empty_cycle4()
{
    new test_id              = register_test( 0, "test_gal_in_empty_cycle4" )
    new Array: emptyCycleMap = ArrayCreate( 32 );
    
    ArrayPushString( emptyCycleMap, "de_dust2" )
    ArrayPushString( emptyCycleMap, "de_inferno" )
    ArrayPushString( emptyCycleMap, "de_dust4" )
    
    // set the next map from the empty cycle list,
    // or the first one, if the current map isn't part of the cycle
    new nextMap[ 32 ]
    
    new mapIdx = map_getNext( emptyCycleMap, "de_dust", nextMap );
    
    if( !equal( nextMap, "de_dust2" ) )
    {
        SET_TEST_FAILURE( test_id, "test_gal_in_empty_cycle4() nextMap must be 'de_dust2' \
                (it was %s)", nextMap )
    }
    
    // if the current map isn't part of the empty cycle,
    // immediately change to next map that is
    if( !( mapIdx == -1 ) )
    {
        SET_TEST_FAILURE( test_id, "test_gal_in_empty_cycle4() mapIdx must be '-1' \
                (it was %d)", mapIdx )
    }
}

/**
 * This is the vote_startDirector() tests chain beginning. Because the vote_startDirector() cannot
 * to be tested simultaneously.
 *
 * Then, all tests that involves the vote_startDirector() chain, must to be executed sequencially
 * after this chain end.
 *
 * This is the 1º chain test, and test if the cvar 'amx_extendmap_max' functionality is working
 * properly.
 */
stock test_is_map_extension_allowed1()
{
    new test_id = register_test( 23, "test_is_map_extension_allowed1" )
    
    if( g_is_map_extension_allowed )
    {
        SET_TEST_FAILURE( test_id, "g_is_map_extension_allowed must be 0 (it was %d)", \
                g_is_map_extension_allowed )
    }
    
    if( !g_refreshVoteStatus )
    {
        SET_TEST_FAILURE( test_id, "g_refreshVoteStatus must be 1 (it was %d)", \
                g_is_map_extension_allowed )
    }
    
    cancel_voting()
    vote_startDirector( false )
    
    if( !g_is_map_extension_allowed )
    {
        SET_TEST_FAILURE( test_id, "g_is_map_extension_allowed must be 1 (it was %d)", \
                g_is_map_extension_allowed )
    }
    
    set_task( 10.0, "test_is_map_extension_allowed2", test_id )
    g_refreshVoteStatus = true;
}

/**
 * This is the 2º test at vote_startDirector() chain and must add 10.0 seconds to the total time
 * execution.
 */
public test_is_map_extension_allowed2( test_id )
{
    if( g_refreshVoteStatus )
    {
        SET_TEST_FAILURE( test_id, "g_refreshVoteStatus must be 0 (it was %d)", \
                g_is_map_extension_allowed )
    }
    
    set_pcvar_float( cvar_extendmapMax, 10.0 )
    set_cvar_float( "mp_timelimit", 20.0 )

#if IS_DEBUG_ENABLED > 0
    client_print_color_internal( 0, "^1%L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED" );
#endif
    
    cancel_voting()
    vote_startDirector( false )
    
    if( g_is_map_extension_allowed )
    {
        SET_TEST_FAILURE( test_id, "g_is_map_extension_allowed must be 0 (it was %d)", \
                g_is_map_extension_allowed )
    }
    
    set_task( 10.0, "test_is_map_extension_allowed3", test_id )
    g_refreshVoteStatus = false;
}

/**
 * This is the 3º test at vote_startDirector() chain and must add 3 seconds to the total time
 * execution.
 *
 * This tests if the end map voting is starting automatically at the end of map due time limit
 * expiration.
 */
public test_is_map_extension_allowed3( test_id )
{
    if( !g_refreshVoteStatus )
    {
        SET_TEST_FAILURE( test_id, "g_refreshVoteStatus must be 1 (it was %d)", \
                g_is_map_extension_allowed )
    }
    
    cancel_voting()
    
    set_task( 3.0, "test_is_map_extension_allowed4", test_id )
}

/**
 * This is the 4º test at vote_startDirector() chain and must add 0 seconds to the total time
 * execution.
 *
 * This tests if the end map voting is starting automatically at the end of map due time limit
 * expiration.
 */
public test_is_map_extension_allowed4( test_id )
{
    new secondsLeft = get_timeleft();
    
    set_cvar_float( "mp_timelimit", (
                ( get_cvar_float( "mp_timelimit" ) ) * 60 - secondsLeft
                + START_VOTEMAP_MIN_TIME - 10 ) / 60 )
    
    vote_manageEnd()
    
    if( !g_is_voting_locked )
    {
        SET_TEST_FAILURE( test_id, "vote_startDirector() does not started!" )
    }
}

/**
 * Every time a cvar is changed during the tests, it must be saved here to a global test variable
 * to be restored at the restore_server_cvars_for_test(), which is executed at the end of all
 * tests execution. This is executed before the first rest run.
 */
stock save_server_cvasr_for_test()
{
    g_is_test_changed_cvars = true
    
    test_extendmap_max = get_pcvar_float( cvar_extendmapMax )
    test_mp_timelimit  = get_cvar_float( "mp_timelimit" )
}

/**
 * This is executed at the end of all tests execution to restore server variables changes.
 */
stock restore_server_cvars_for_test()
{
    if( g_is_test_changed_cvars )
    {
        g_is_test_changed_cvars = false
        
        set_pcvar_float( cvar_extendmapMax, test_extendmap_max )
        set_cvar_float( "mp_timelimit", test_mp_timelimit )
    }
}

/**
 * Immediately stops any vote in progress.
 */
stock cancel_voting()
{
    remove_task( TASKID_START_VOTING_BY_ROUNDS )
    remove_task( TASKID_UNLOCK_VOTING )
    remove_task( TASKID_VOTE_COUNTDOWNPENDINGVOTE )
    remove_task( TASKID_VOTE_DISPLAY )
    remove_task( TASKID_VOTE_HANDLEDISPLAY )
    remove_task( TASKID_VOTE_EXPIRE )
    remove_task( TASKID_DBG_FAKEVOTES )
    remove_task( TASKID_VOTE_STARTDIRECTOR )
    remove_task( TASKID_MAP_CHANGE )
    
    g_is_voting_locked = false
    g_voteStatus       = 0
    
    vote_resetStats()
}

/**
 * Write debug messages to server's console accordantly with cvar gal_debug.
 * If gal_debug 1 or more higher, the voting and runoff times are set to 5 seconds.
 *
 * @param mode the debug mode level:
 *           ( 0 ) 0 disabled all debug.
 *           ( 1 ) 1 displays basic debug messages.
 *           ( 10 ) 2 displays players disconnect, how many remaining, and multiple time limits
 *                          changes and restores.
 *           ( 100 ) 4 displays maps events as: choices, votes, nominations, and the calls to
 *                          map_populateList( Array:mapArray, mapFilename[] ).
 *           ( 1000 ) 8 displays vote_loadChoices( ) and actions at vote_startDirector
 *           ( 10000 ) 16 displays messages related to RunOff voting
 *           ( 100000 ) 32 displays messages related to the rounds end map voting
 *           ( 1000000 ) 64 displays messages related client_print_color_internal(...)
 *           ( 1111111 ) 127 displays all debug logs levels at server console.
 *
 * @param text the debug message, if omitted its default value is ""
 * @param any the variable number of formatting parameters
 */
stock debugMesssageLogger( const mode, const text[] = "", { Float, Sql, Result, _ }: ... )
{
    g_debug_level = get_cvar_num( "gal_debug" );
    
    if( mode & g_debug_level )
    {
        // format the text as needed
        new formattedText[ 1024 ];
        format_args( formattedText, 1023, 1 );
        
        server_print( "%s", formattedText )
        client_print( 0, print_console, "%s", formattedText )
    }
    
    // not needed but gets rid of stupid compiler error
    if( text[ 0 ] == 0 )
    {
        return;
    }
}
