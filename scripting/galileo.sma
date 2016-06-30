/*********************** Licensing *******************************************************
*
*   Copyright 2008-2010 @ Brad Jones
*   Copyright 2015-2016 @ Addons zz
*   Copyright 2004-2016 @ AMX Mod X Development Team
*
*   Plugin Thread: https://forums.alliedmods.net/showthread.php?t=273019
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



/**
 * This version number must be synced with "githooks/GALILEO_VERSION.txt" for manual edition.
 * To update them automatically, use: ./githooks/updateVersion.sh [major | minor | patch | build]
 */
new const PLUGIN_VERSION[] = "v2.6.1-98";


/** This is to view internal program data while execution. See the function 'debugMesssageLogger(...)'
 * and the variable 'g_debug_level' for more information. Default value: 0
 *
 * 0   - Disables this feature.
 *
 * 1   - Normal/basic debugging/depuration.
 *
 * 2   - a) To skip the 'pendingVoteCountdown()'.
 *       b) Set the vote runoff time to 5 seconds.
 *       c) Run the Unit Tests and print their out put results.
 *
 * 4   - a) To create fake votes. See the function 'create_fakeVotes()'.
 *       b) To create fake players count. See the function 'get_realplayersnum()'.
 *
 * 8   - Enable DEBUG_LEVEL 1 and all its debugging/depuration available.
 *
 * 15  - Levels 1, 2, 4 and 8.
 */
#define DEBUG_LEVEL 8



#define DEBUG_LEVEL_NORMAL        1
#define DEBUG_LEVEL_UNIT_TEST     2
#define DEBUG_LEVEL_FAKE_VOTES    4
#define DEBUG_LEVEL_CRITICAL_MODE 8


#include <amxmodx>
#include <amxmisc>
#pragma semicolon 1


#if DEBUG_LEVEL & ( DEBUG_LEVEL_NORMAL | DEBUG_LEVEL_CRITICAL_MODE )
    #define DEBUG
    #define LOGGER(%1) debugMesssageLogger( %1 )
    
    /**
     * 0    - Disabled all debug.
     *
     * 1    - Displays basic debug messages.
     *
     * 2    - a) Players disconnecting and total number.
     *        b) Multiple time limits changes and restores.
     *
     * 4    - a) Maps events.
     *        b) Vote choices.
     *        c) Nominations.
     *        d) Calls to map_populateList(4).
     *
     * 8    - a) Loaded vote choices.
     *        b) Minplayers-whitelist debugging.
     *        c) Actions at vote_startDirector(1).
     *
     * 16   - Runoff voting.
     * 32   - Rounds end map voting.
     * 64   - Debug for the color_print(...) function.
     * 128  - Functions entrances messages.
     * 255  - Enables all debug logging levels.
     */
    new g_debug_level = 1 + 4 + 8 + 16;
    
    
    /**
     * Write debug messages accordantly with the gal_debug level.
     *
     * @param mode the debug mode level, see the variable 'g_debug_level' for the levels.
     * @param text the debug message, if omitted its default value is ""
     * @param any the variable number of formatting parameters
     * 
     * @see the stock writeToTheDebugFile( log_file[], formated_message[] ) for the output log "_galileo.log".
     */
    stock debugMesssageLogger( mode, message[] = "", any: ... )
    {
        if( mode & g_debug_level )
        {
            static formated_message[ 384 ];
            vformat( formated_message, charsmax( formated_message ), message, 3 );
            
            writeToTheDebugFile( "_galileo.log", formated_message );
        }
    }
#else
    #define LOGGER(%1) allowToUseSemicolonOnMacrosEnd()

#endif



#if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST
    /**
     * Contains all unit tests to execute.
     */
    #define ALL_TESTS_TO_EXECUTE() \
    do \
    { \
        test_register_test(); \
        test_gal_in_empty_cycle_case1(); \
        test_gal_in_empty_cycle_case2(); \
        test_gal_in_empty_cycle_case3(); \
        test_gal_in_empty_cycle_case4(); \
        test_is_map_extension_allowed(); \
        test_loadCurrentBlackList_case1(); \
        test_loadCurrentBlackList_case2(); \
        test_loadCurrentBlackList_case3(); \
    } while( g_dummy_value )
    
    /**
     * Call the internal function to perform its task and stop the current test execution to avoid
     * double failure at the test control system.
     */
    #define SET_TEST_FAILURE(%1) \
    do \
    { \
        set_test_failure_private( %1 ); \
        if( g_current_test_evaluation ) \
        { \
            return; \
        } \
    } while( g_dummy_value )
    
    /**
     * Write debug messages to server's console and log file.
     *
     * @param text the debug message, if omitted its default value is ""
     * @param any the variable number of formatting parameters
     */
    stock print_logger( message[] = "", any: ... )
    {
        static formated_message[ 384 ];
        vformat( formated_message, charsmax( formated_message ), message, 2 );
        
        writeToTheDebugFile( "_galileo.log", formated_message );
    }
    
    
    /**
     * Test unit variables related to the DEBUG_LEVEL_UNIT_TEST 2.
     */
    new g_max_delay_result;
    new g_totalSuccessfulTests;
    new g_totalFailureTests;
    
    new Array: g_tests_idsAndNames;
    new Array: g_tests_failure_ids;
    new Array: g_tests_failure_reasons;
    
    new bool: g_is_test_changed_cvars;
    new bool: g_current_test_evaluation;
    new bool: g_areTheUnitTestsRunning;
    
    new g_test_current_time;
    new g_test_whiteListFilePath[ 128 ];
#endif



/**
 * Write messages to the debug log file on 'addons/amxmodx/logs'.
 * 
 * @param log_file               the log file name.
 * @param formated_message       the formatted message to write down to the debug log file.
 */
#if DEBUG_LEVEL >= DEBUG_LEVEL_NORMAL
    stock writeToTheDebugFile( log_file[], formated_message[] )
    {
        static Float:gameTime;
        
        gameTime = get_gametime();
        log_to_file( log_file, "{%3.4f} %s", gameTime, formated_message );
    }
#endif


#if AMXX_VERSION_NUM < 183
    new g_user_msgid;
#endif


#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif


/**
 * Dummy value used to use the do...while() statements to allow the semicolon ';' use at macros endings.
 */
new g_dummy_value = 0;

stock allowToUseSemicolonOnMacrosEnd()
{
}


#define TASKID_REMINDER                   52691153
#define TASKID_SHOW_LAST_ROUND_HUD        52691052
#define TASKID_DELETE_USERS_MENUS         72748052
#define TASKID_PREVENT_INFITY_GAME        82448699
#define TASKID_EMPTYSERVER                98176977
#define TASKID_START_VOTING_BY_ROUNDS     52691160
#define TASKID_START_VOTING_BY_TIMER      72681180
#define TASKID_PROCESS_LAST_ROUND         42691173
#define TASKID_VOTE_HANDLEDISPLAY         52691264
#define TASKID_VOTE_DISPLAY               52691165
#define TASKID_VOTE_EXPIRE                52691166
#define TASKID_PENDING_VOTE_COUNTDOWN     13464364
#define TASKID_DBG_FAKEVOTES              52691167
#define TASKID_VOTE_STARTDIRECTOR         52691168
#define TASKID_MAP_CHANGE                 52691169
#define TASKID_FINISH_GAME_WITH_HALF_TIME 52559169

#define RTV_CMD_STANDARD  1
#define RTV_CMD_SHORTHAND 2
#define RTV_CMD_DYNAMIC   4

#define MAX_LONG_STRING              256
#define MAX_COLOR_MESSAGE            192
#define MAX_SHORT_STRING             64
#define MAX_NOMINATION_TRIE_KEY_SIZE 48

#define SOUND_GETREADYTOCHOOSE 1
#define SOUND_COUNTDOWN        2
#define SOUND_TIMETOCHOOSE     4
#define SOUND_RUNOFFREQUIRED   8

#define MAPFILETYPE_SINGLE 1
#define MAPFILETYPE_GROUPS 2

#define SHOW_STATUS_NEVER      0
#define SHOW_STATUS_AFTER_VOTE 1
#define SHOW_STATUS_AT_END     2
#define SHOW_STATUS_ALWAYS     3

#define STATUS_TYPE_COUNT      1
#define STATUS_TYPE_PERCENTAGE 2

#define HIDE_AFTER_USER_VOTE           0
#define ALWAYS_KEEP_SHOWING            1
#define CONVERT_IT_TO_CANCEL_LAST_VOTE 2

#define ANNOUNCE_CHOICE_PLAYERS 1
#define ANNOUNCE_CHOICE_ADMINS  2

#define MAX_PREFIX_COUNT     32
#define MAX_RECENT_MAP_COUNT 16

#define MAX_MAPS_IN_VOTE              8
#define MAX_NOMINATION_COUNT          8
#define MAX_OPTIONS_IN_VOTE           9
#define MAX_STANDARD_MAP_COUNT        25
#define MAX_SERVER_RESTART_ACCEPTABLE 10

#define MAX_MAPNAME_LENGHT     64
#define MAX_FILE_PATH_LENGHT   128
#define MAX_PLAYER_NAME_LENGHT 48
#define MAX_NOM_MATCH_COUNT    1000
#define MAX_PLAYERS_COUNT      MAX_PLAYERS + 1

#define VOTE_IS_IN_PROGRESS 1
#define VOTE_IS_FORCED      2
#define VOTE_IS_RUNOFF      4
#define VOTE_IS_OVER        8
#define VOTE_IS_EARLY       16
#define VOTE_IS_EXPIRED     32

#define SERVER_START_CURRENTMAP                1
#define SERVER_START_NEXTMAP                   2
#define SERVER_START_MAPVOTE                   3
#define SERVER_START_RANDOMMAP                 4
#define SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR 2

#define LISTMAPS_USERID 0
#define LISTMAPS_LAST   1

#define START_VOTEMAP_MIN_TIME 151
#define START_VOTEMAP_MAX_TIME 129

#define VOTE_ROUND_START_MIN_DELAY 500
#define VOTE_ROUND_START_MAX_DELAY START_VOTEMAP_MIN_TIME


/**
 * Give a 4 minutes range to try detecting the round start, to avoid buy old buy weapons menu
 * override.
 *
 * @param seconds     how many seconds are reaming to the map end.
 */
#define VOTE_ROUND_START_DETECTION_DELAYED(%1) \
    ( %1 < VOTE_ROUND_START_MIN_DELAY \
      && %1 > VOTE_ROUND_START_MAX_DELAY )

/**
 * To start the end map voting near the map time limit expiration.
 */
#define IS_TIME_TO_START_THE_END_OF_MAP_VOTING(%1) \
    ( %1 < START_VOTEMAP_MIN_TIME \
      && %1 > START_VOTEMAP_MAX_TIME )

/**
 * The rounds number before the mp_maxrounds/mp_winlimit to be reached to start the map voting.
 */
#define VOTE_START_ROUNDS 4

/**
 * The frags/kills number before the mp_fraglimit to be reached and to start the map voting.
 */
#define VOTE_START_FRAGS 15

/**
 * Specifies how much time to delay the voting start after the round start.
 */
#define VOTE_ROUND_START_SECONDS_DELAY() ( get_pcvar_num( cvar_mp_freezetime ) + 20.0 )

/**
 * Start a map voting delayed after the mp_maxrounds or mp_winlimit minimum to be reached.
 */
#define VOTE_START_ROUND_DELAY() \
do \
{ \
    set_task( VOTE_ROUND_START_SECONDS_DELAY(), "start_voting_by_rounds", TASKID_START_VOTING_BY_ROUNDS ); \
} while( g_dummy_value )

/**
 * Verifies if a voting is or was already processed.
 */
#define IS_END_OF_MAP_VOTING_GOING_ON() \
    ( g_voteStatus & VOTE_IS_IN_PROGRESS \
      || g_voteStatus & VOTE_IS_OVER )

/**
 * Boolean check for the whitelist feature.
 */
#define IS_WHITELIST_ENABLED() \
    ( get_pcvar_num( cvar_whitelistMinPlayers ) == 1 \
      || get_realplayersnum() < get_pcvar_num( cvar_whitelistMinPlayers ) )

/**
 * Boolean check for the nominations minimum players controlling feature.
 */
#define IS_NOMINATION_MININUM_PLAYERS_CONTROL_ENABLED() \
    ( get_realplayersnum() < get_pcvar_num( cvar_voteMinPlayers ) \
      && get_pcvar_num( cvar_NomMinPlayersControl ) )

/**
 * Convert colored strings codes '!g for green', '!y for yellow', '!t for team'.
 *
 * @param string[]       a string pointer to be converted.
 */
#define INSERT_COLOR_TAGS(%1) \
do \
{ \
    replace_all( %1, charsmax( %1 ), "!g", "^4" ); \
    replace_all( %1, charsmax( %1 ), "!t", "^3" ); \
    replace_all( %1, charsmax( %1 ), "!n", "^1" ); \
    replace_all( %1, charsmax( %1 ), "!y", "^1" ); \
} while( g_dummy_value )

/**
 * Remove the colored strings codes '^4 for green', '^1 for yellow', '^3 for team' and
 * '^2 for unknown'.
 *
 * @param string[]       a string pointer to be formatted.
 */
#define REMOVE_COLOR_TAGS(%1) \
do \
{ \
    replace_all( %1, charsmax( %1 ), "^1", "" ); \
    replace_all( %1, charsmax( %1 ), "^2", "" ); \
    replace_all( %1, charsmax( %1 ), "^3", "" ); \
    replace_all( %1, charsmax( %1 ), "^4", "" ); \
} while( g_dummy_value )

/**
 * Print to the users chat, a colored chat message.
 *
 * @param player_id     a player id from 1 to MAX_PLAYERS
 * @param message       a colored formatted string message. At the AMXX 182 it must start within
 *                      one color code as found on REMOVE_COLOR_TAGS(1) above macro. Example:
 *                      "^1Hi! I am a ^3 colored message".
 */
#define PRINT_COLORED_MESSAGE(%1,%2) \
do \
{ \
    message_begin( MSG_ONE_UNRELIABLE, g_user_msgid, _, %1 ); \
    write_byte( %1 ); \
    write_string( %2 ); \
    message_end(); \
} while( g_dummy_value )

/**
 * Get the player name. If the player is not connected, uses "Unknown Dude" as its name.
 * 
 * @param player_id          the player id
 * @param name_string        a string pointer to hold the player name.
 */
#define GET_USER_NAME(%1,%2) \
do \
{ \
    if( is_user_connected( %1 ) ) \
    { \
        get_user_name( %1, %2, charsmax( %2 ) ); \
    } \
    else \
    { \
        copy( %2, charsmax( %2 ), "Unknown Dude" ); \
    } \
} while( g_dummy_value )

/**
 * Game cvars.
 */
new cvar_mp_freezetime;
new cvar_mp_winlimit;
new cvar_mp_fraglimit;
new cvar_mp_maxrounds;
new cvar_mp_timelimit;
new cvar_mp_roundtime;
new cvar_mp_chattime;
new cvar_sv_maxspeed;


/**
 * Server cvars
 */
new cvar_extendmapAllowStayType;
new cvar_nextMapChangeAnnounce;
new cvar_disabledValuePointer;
new cvar_isToShowVoteCounter;
new cvar_isToShowNoneOption;
new cvar_voteShowNoneOptionType;
new cvar_isExtendmapOrderAllowed;
new cvar_coloredChatEnabled;
new cvar_isToStopEmptyCycle;
new cvar_unnominateDisconnected;
new cvar_endOnRound;
new cvar_endOfMapVoteStart;
new cvar_endOnRoundRtv;
new cvar_endOnRound_msg;
new cvar_voteWeight;
new cvar_voteWeightFlags;
new cvar_maxMapExtendTime;
new cvar_extendmapStepMinutes;
new cvar_extendmapStepRounds;
new cvar_extendmapAllowStay;
new cvar_endOfMapVote;
new cvar_isToAskForEndOfTheMapVote;
new cvar_emptyWait;
new cvar_isEmptyCycleServerChange;
new cvar_emptyMapFilePath;
new cvar_rtvMinutesWait;
new cvar_rtvWaitRounds;
new cvar_rtvWaitAdmin;
new cvar_rtvRatio;
new cvar_rtvCommands;
new cvar_cmdVotemap;
new cvar_cmdListmaps;
new cvar_listmapsPaginate;
new cvar_recentMapsBannedNumber;
new cvar_banRecentStyle;
new cvar_voteDuration;
new cvar_nomMapFilePath;
new cvar_nomPrefixes;
new cvar_nomQtyUsed;
new cvar_nomPlayerAllowance;
new cvar_isToShowExpCountdown;
new cvar_isEndMapCountdown;
new cvar_voteMapChoiceCount;
new cvar_voteAnnounceChoice;
new cvar_voteUniquePrefixes;
new cvar_rtvReminder;
new cvar_serverStartAction;
new cvar_gameCrashRecreationAction;
new cvar_serverTimeLimitRestart;
new cvar_serverMaxroundsRestart;
new cvar_serverWinlimitRestart;
new cvar_runoffEnabled;
new cvar_runoffDuration;
new cvar_showVoteStatus;
new cvar_showVoteStatusType;
new cvar_isToReplaceByVoteMenu;
new cvar_soundsMute;
new cvar_voteMapFilePath;
new cvar_voteMinPlayers;
new cvar_NomMinPlayersControl;
new cvar_voteMinPlayersMapFilePath;
new cvar_whitelistMinPlayers;
new cvar_voteWhiteListMapFilePath;


/**
 * Various Artists
 */
new const LAST_EMPTY_CYCLE_FILE_NAME[]      = "lastEmptyCycleMapName.dat";
new const CURRENT_AND_NEXTMAP_FILE_NAME[]   = "currentAndNextmapNames.dat";
new const LAST_CHANGE_MAP_FILE_NAME[]       = "lastChangedMapName.dat";
new const CHOOSE_MAP_MENU_NAME[]            = "gal_menuChooseMap";
new const CHOOSE_MAP_MENU_QUESTION[]        = "chooseMapQuestion";
new const GAME_CRASH_RECREATION_FLAG_FILE[] = "gameCrashRecreationAction.txt";

new bool:g_isVotingByTimer;
new bool:g_isTimeToResetGame;
new bool:g_isTimeToResetRounds;
new bool:g_isUsingEmptyCycle;
new bool:g_isRunOffNeedingKeepCurrentMap;
new bool:g_isExtendmapAllowStay;
new bool:g_isToShowNoneOption;
new bool:g_isToShowExpCountdown;
new bool:g_isToShowVoteCounter;
new bool:g_isToRefreshVoteStatus;
new bool:g_isEmptyCycleMapConfigured;
new bool:g_isColoredChatEnabled;
new bool:g_isMaxfragsExtend;
new bool:g_isMaxroundsExtend;
new bool:g_isVotingByRounds;
new bool:g_isRtvLastRound;
new bool:g_isTheLastGameRound;
new bool:g_isTimeToChangeLevel;
new bool:g_isTimeToRestart;
new bool:g_isEndGameLimitsChanged;
new bool:g_isMapExtensionAllowed;
new bool:g_isColorChatSupported;
new bool:g_isGameFinalVoting;
new bool:g_isOnMaintenanceMode;
new bool:g_isToCreateGameCrashFlag;

new Float:g_rtvMinutesWait;
new Float:g_originalTimelimit;
new Float:g_original_sv_maxspeed;

/**
 * Holds the Empty Cycle Map List feature maps used when the server is empty for some time to
 * change the map to a popular one.
 */
new Array:g_emptyCycleMapsList;

/**
 * Stores the players nominations until MAX_NOMINATION_COUNT for each player.
 */
new Trie:g_playersNominations;

/**
 * Stores the nominators id by a given map index. It is to find out the player id given the nominated
 * map index.
 */
new Trie:g_nominationMapsTrie;

/**
 * Enumeration used to create access the "g_nominationMapsTrie" values. It is untagged to be able to
 * pass it throw an TrieSetArray.
 */
enum _:MapNominationsType
{
    MapNominationsPlayerId,
    MapNominationsNominationIndex
}

new Array:g_fillerMaps;
new Array:g_nominationMapsArray;

new g_originalMaxRounds;
new g_originalWinLimit;
new g_originalFragLimit;
new g_showVoteStatusType;
new g_extendmapStepRounds;
new g_extendmapStepMinutes;
new g_extendmapAllowStayType;
new g_showVoteStatus;
new g_voteShowNoneOptionType;
new g_pendingVoteCountdown;
new g_lastRroundCountdown;
new g_rtvWaitAdminNumber;
new g_emptyCycleMapsNumber;
new g_recentMapCount;
new g_nominationMapCount;
new g_rtvCommands;
new g_rtvWaitRounds;
new g_rockedVoteCount;
new g_winLimitInteger;
new g_maxRoundsNumber;
new g_fragLimitNumber;
new g_greatestKillerFrags;
new g_timeLimitNumber;

new g_roundsPlayedNumber;
new g_totalTerroristsWins;
new g_totalCtWins;
new g_totalVoteOptions;
new g_totalVoteOptionsTemp;

new g_maxVotingChoices;
new g_voteStatus;
new g_voteDuration;
new g_totalVotesCounted;

new COLOR_RED   [ 3 ]; // \r
new COLOR_WHITE [ 3 ]; // \w
new COLOR_YELLOW[ 3 ]; // \y
new COLOR_GREY  [ 3 ]; // \d

new g_mapPrefixCount = 1;

/**
 * Nextmap sub-plugin global variables.
 */
new g_cvar_mp_chattime;
new g_cvar_amx_nextmap;
new g_cvar_mp_friendlyfire;
new g_nextMapCyclePosition;

new g_arrayOfRunOffChoices[ 2 ];
new g_voteStatus_symbol   [ 3 ];
new g_voteWeightFlags     [ 32 ];
new g_voteStatusClean     [ 512 ];

new g_configsDirPath [ MAX_FILE_PATH_LENGHT ];
new g_dataDirPath    [ MAX_FILE_PATH_LENGHT ];

/**
 * Nextmap sub-plugin global variables.
 */
new g_nextMapName      [ MAX_MAPNAME_LENGHT ];
new g_currentMapName   [ MAX_MAPNAME_LENGHT ];
new g_mapCycleFilePath [ MAX_FILE_PATH_LENGHT ];

new g_nextMap                   [ MAX_MAPNAME_LENGHT ];
new g_currentMap                [ MAX_MAPNAME_LENGHT ];
new g_playerVotedOption         [ MAX_PLAYERS_COUNT ];
new g_playerVotedWeight         [ MAX_PLAYERS_COUNT ];
new g_generalUsePlayersMenuId   [ MAX_PLAYERS_COUNT ];
new g_playersKills              [ MAX_PLAYERS_COUNT ];
new g_arrayOfMapsWithVotesNumber[ MAX_OPTIONS_IN_VOTE ];


new Array:g_currentMenuMapIndexForPlayers[ MAX_PLAYERS_COUNT ];

new bool:g_isPlayerVoted            [ MAX_PLAYERS_COUNT ] = { true, ... };
new bool:g_isPlayerParticipating    [ MAX_PLAYERS_COUNT ] = { true, ... };
new bool:g_isPlayerSeeingTheVoteMenu[ MAX_PLAYERS_COUNT ];
new bool:g_isPlayerCancelledVote    [ MAX_PLAYERS_COUNT ];
new bool:g_answeredForEndOfMapVote  [ MAX_PLAYERS_COUNT ];
new bool:g_rockedVote               [ MAX_PLAYERS_COUNT ];

new g_mapPrefixes       [ MAX_PREFIX_COUNT ][ 16 ];
new g_recentMaps        [ MAX_RECENT_MAP_COUNT ][ MAX_MAPNAME_LENGHT ];
new g_votingMapNames    [ MAX_OPTIONS_IN_VOTE ][ MAX_MAPNAME_LENGHT ];

new g_nominationCount;
new g_chooseMapMenuId;
new g_chooseMapQuestionMenuId;

public plugin_init()
{
#if DEBUG_LEVEL & DEBUG_LEVEL_CRITICAL_MODE
    g_debug_level = 1048575;
#endif
    
    register_plugin( "Galileo", PLUGIN_VERSION, "Brad Jones/Addons zz" );
    LOGGER( 1, "^n^n^n^nGALILEO PLUGIN VERSION %s INITIATING...", PLUGIN_VERSION );
    
    cvar_maxMapExtendTime        = register_cvar( "amx_extendmap_max", "90" );
    cvar_extendmapStepMinutes    = register_cvar( "amx_extendmap_step", "15" );
    cvar_extendmapStepRounds     = register_cvar( "amx_extendmap_step_rounds", "30" );
    cvar_extendmapAllowStay      = register_cvar( "amx_extendmap_allow_stay", "0" );
    cvar_isExtendmapOrderAllowed = register_cvar( "amx_extendmap_allow_order", "0" );
    cvar_extendmapAllowStayType  = register_cvar( "amx_extendmap_allow_stay_type", "0" );
    
    register_cvar( "gal_server_starting", "1", FCVAR_SPONLY );
    register_cvar( "gal_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY );
    
#if DEBUG_LEVEL >= DEBUG_LEVEL_NORMAL
    new debug_level[ 128 ];
    formatex( debug_level, charsmax( debug_level ), "%d | %d", g_debug_level, DEBUG_LEVEL );
    
    LOGGER( 1, "gal_debug_level: %s", debug_level );
    register_cvar( "gal_debug_level", debug_level, FCVAR_SERVER | FCVAR_SPONLY );
#endif
    
    cvar_disabledValuePointer      = register_cvar( "gal_disabled_value_pointer", "0", FCVAR_SPONLY );
    cvar_nextMapChangeAnnounce     = register_cvar( "gal_nextmap_change", "1" );
    cvar_isToShowVoteCounter       = register_cvar( "gal_vote_show_counter", "0" );
    cvar_isToShowNoneOption        = register_cvar( "gal_vote_show_none", "0" );
    cvar_voteShowNoneOptionType    = register_cvar( "gal_vote_show_none_type", "0" );
    cvar_coloredChatEnabled        = register_cvar( "gal_colored_chat_enabled", "0", FCVAR_SPONLY );
    cvar_isToStopEmptyCycle        = register_cvar( "gal_in_empty_cycle", "0", FCVAR_SPONLY );
    cvar_unnominateDisconnected    = register_cvar( "gal_unnominate_disconnected", "0" );
    cvar_endOnRound                = register_cvar( "gal_endonround", "1" );
    cvar_endOfMapVoteStart         = register_cvar( "gal_endofmapvote_start", "0" );
    cvar_endOnRoundRtv             = register_cvar( "gal_endonround_rtv", "0" );
    cvar_endOnRound_msg            = register_cvar( "gal_endonround_msg", "0" );
    cvar_voteWeight                = register_cvar( "gal_vote_weight", "1" );
    cvar_voteWeightFlags           = register_cvar( "gal_vote_weightflags", "y" );
    cvar_cmdVotemap                = register_cvar( "gal_cmd_votemap", "0" );
    cvar_cmdListmaps               = register_cvar( "gal_cmd_listmaps", "2" );
    cvar_listmapsPaginate          = register_cvar( "gal_listmaps_paginate", "10" );
    cvar_recentMapsBannedNumber    = register_cvar( "gal_banrecent", "3" );
    cvar_banRecentStyle            = register_cvar( "gal_banrecentstyle", "1" );
    cvar_endOfMapVote              = register_cvar( "gal_endofmapvote", "1" );
    cvar_isToAskForEndOfTheMapVote = register_cvar( "gal_endofmapvote_ask", "0" );
    cvar_emptyWait                 = register_cvar( "gal_emptyserver_wait", "0" );
    cvar_isEmptyCycleServerChange  = register_cvar( "gal_emptyserver_change", "0" );
    cvar_emptyMapFilePath          = register_cvar( "gal_emptyserver_mapfile", "" );
    cvar_serverStartAction         = register_cvar( "gal_srv_start", "0" );
    cvar_gameCrashRecreationAction = register_cvar( "gal_game_crash_recreation", "0" );
    cvar_serverTimeLimitRestart    = register_cvar( "gal_srv_timelimit_restart", "0" );
    cvar_serverMaxroundsRestart    = register_cvar( "gal_srv_maxrounds_restart", "0" );
    cvar_serverWinlimitRestart     = register_cvar( "gal_srv_winlimit_restart", "0" );
    cvar_rtvCommands               = register_cvar( "gal_rtv_commands", "3" );
    cvar_rtvMinutesWait            = register_cvar( "gal_rtv_wait", "10" );
    cvar_rtvWaitRounds             = register_cvar( "gal_rtv_wait_rounds", "5" );
    cvar_rtvWaitAdmin              = register_cvar( "gal_rtv_wait_admin", "0" );
    cvar_rtvRatio                  = register_cvar( "gal_rtv_ratio", "0.60" );
    cvar_rtvReminder               = register_cvar( "gal_rtv_reminder", "2" );
    cvar_nomPlayerAllowance        = register_cvar( "gal_nom_playerallowance", "2" );
    cvar_nomMapFilePath            = register_cvar( "gal_nom_mapfile", "*" );
    cvar_nomPrefixes               = register_cvar( "gal_nom_prefixes", "1" );
    cvar_nomQtyUsed                = register_cvar( "gal_nom_qtyused", "0" );
    cvar_voteDuration              = register_cvar( "gal_vote_duration", "15" );
    cvar_isToShowExpCountdown      = register_cvar( "gal_vote_expirationcountdown", "1" );
    cvar_isEndMapCountdown         = register_cvar( "gal_endonround_countdown", "0" );
    cvar_voteMapChoiceCount        = register_cvar( "gal_vote_mapchoices", "5" );
    cvar_voteAnnounceChoice        = register_cvar( "gal_vote_announcechoice", "1" );
    cvar_showVoteStatus            = register_cvar( "gal_vote_showstatus", "1" );
    cvar_isToReplaceByVoteMenu     = register_cvar( "gal_vote_replace_menu", "0" );
    cvar_showVoteStatusType        = register_cvar( "gal_vote_showstatustype", "3" );
    cvar_voteUniquePrefixes        = register_cvar( "gal_vote_uniqueprefixes", "0" );
    cvar_runoffEnabled             = register_cvar( "gal_runoff_enabled", "0" );
    cvar_runoffDuration            = register_cvar( "gal_runoff_duration", "10" );
    cvar_soundsMute                = register_cvar( "gal_sounds_mute", "0" );
    cvar_voteMapFilePath           = register_cvar( "gal_vote_mapfile", "*" );
    cvar_voteMinPlayers            = register_cvar( "gal_vote_minplayers", "0" );
    cvar_NomMinPlayersControl      = register_cvar( "gal_nom_minplayers_control", "0" );
    cvar_voteMinPlayersMapFilePath = register_cvar( "gal_vote_minplayers_mapfile", "" );
    cvar_whitelistMinPlayers       = register_cvar( "gal_whitelist_minplayers", "0" );
    cvar_voteWhiteListMapFilePath  = register_cvar( "gal_vote_whitelist_mapfile", "" );
    
    nextmap_plugin_init();
    configureEndGameCvars();
    configureTheVotingMenus();
    
    register_dictionary( "common.txt" );
    register_dictionary_colored( "galileo.txt" );
    
    register_logevent( "game_commencing_event", 2, "0=World triggered", "1=Game_Commencing" );
    register_logevent( "team_win_event",        6, "0=Team" );
    register_logevent( "round_restart_event",   2, "0=World triggered", "1&Restart_Round_" );
    register_logevent( "round_start_event",     2, "1=Round_Start" );
    register_logevent( "round_end_event",       2, "1=Round_End" );
    
    register_clcmd( "say", "cmd_say", -1 );
    register_clcmd( "say_team", "cmd_say", -1 );
    register_clcmd( "votemap", "cmd_HL1_votemap" );
    register_clcmd( "listmaps", "cmd_HL1_listmaps" );
    
    register_concmd( "gal_startvote", "cmd_startVote", ADMIN_MAP );
    register_concmd( "gal_cancelvote", "cmd_cancelVote", ADMIN_MAP );
    register_concmd( "gal_createmapfile", "cmd_createMapFile", ADMIN_RCON );
    register_concmd( "gal_command_maintenance", "cmd_maintenanceMode", ADMIN_RCON );
    
    LOGGER( 1, "I AM EXITING PLUGIN_INIT(0)..." );
    LOGGER( 1, "" );
}

stock configureEndGameCvars()
{
    LOGGER( 128, "I AM ENTERING ON configureEndGameCvars(0)" );
    
    // mp_maxrounds
    if( !( cvar_mp_maxrounds = get_cvar_pointer( "mp_maxrounds" ) ) )
    {
        cvar_mp_maxrounds = cvar_disabledValuePointer;
    }
    
    // mp_fraglimit
    if( !( cvar_mp_fraglimit = get_cvar_pointer( "mp_fraglimit" ) ) )
    {
        cvar_mp_fraglimit = cvar_disabledValuePointer;
    }
    else
    {
        register_event( "DeathMsg", "client_death_event", "a" );
    }
    
    // mp_winlimit
    if( !( cvar_mp_winlimit = get_cvar_pointer( "mp_winlimit" ) ) )
    {
        cvar_mp_winlimit = cvar_disabledValuePointer;
    }
    
    // mp_freezetime
    if( !( cvar_mp_freezetime = get_cvar_pointer( "mp_freezetime" ) ) )
    {
        cvar_mp_freezetime = cvar_disabledValuePointer;
    }
    
    // mp_timelimit
    if( !( cvar_mp_timelimit = get_cvar_pointer( "mp_timelimit" ) ) )
    {
        cvar_mp_timelimit = cvar_disabledValuePointer;
    }
    
    // mp_roundtime
    if( !( cvar_mp_roundtime = get_cvar_pointer( "mp_roundtime" ) ) )
    {
        cvar_mp_roundtime = cvar_disabledValuePointer;
    }
    
    // mp_chattime
    if( !( cvar_mp_chattime = get_cvar_pointer( "mp_chattime" ) ) )
    {
        cvar_mp_chattime = cvar_disabledValuePointer;
    }
    
    // sv_maxspeed
    if( !( cvar_sv_maxspeed = get_cvar_pointer( "sv_maxspeed" ) ) )
    {
        cvar_sv_maxspeed = cvar_disabledValuePointer;
    }
}

stock configureTheVotingMenus()
{
    LOGGER( 128, "I AM ENTERING ON configureTheVotingMenus(0)" );
    
    g_chooseMapMenuId         = register_menuid( CHOOSE_MAP_MENU_NAME );
    g_chooseMapQuestionMenuId = register_menuid( CHOOSE_MAP_MENU_QUESTION );
    
    register_menucmd( g_chooseMapMenuId, MENU_KEY_1 | MENU_KEY_2 |
            MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 |
            MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9 | MENU_KEY_0,
            "vote_handleChoice" );
    
    register_menucmd( g_chooseMapQuestionMenuId, MENU_KEY_6 | MENU_KEY_0, "handleEndOfTheMapVoteChoice" );
}

/**
 * Called when all plugins went through plugin_init(). When this forward is called, most plugins
 * should have registered their cvars and commands already.
 */
public plugin_cfg()
{
    LOGGER( 128, "I AM ENTERING ON plugin_cfg(0)" );
    
#if AMXX_VERSION_NUM < 183
    // If some exception happened before this, all color_print(...) messages will cause native
    // error 10, on the AMXX 182. It is because, the execution flow will not reach here, then
    // the player "g_user_msgid" will be be initialized.
    g_user_msgid = get_user_msgid( "SayText" );
#endif
    
    resetRoundsScores();
    loadPluginSetttings();
    initializeGlobalArrays();
    
    LOGGER( 4, "" );
    LOGGER( 4, " The current map is [%s].", g_currentMap );
    LOGGER( 4, " The next map is [%s]", g_nextMap );
    LOGGER( 4, "" );
    
    cacheCvarsValues();
    configureRTV();
    configureServerStart();
    configureServerMapChange();
    
#if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST
    configureTheUnitTests();
#endif

    LOGGER( 1, "I AM EXITING PLUGIN_CFG(0)..." );
    LOGGER( 1, "" );
}

stock loadPluginSetttings()
{
    LOGGER( 128, "I AM ENTERING ON loadPluginSetttings(0)" );
    
    new writtenSize;
    g_isColorChatSupported = ( is_running( "czero" )
                               || is_running( "cstrike" ) );
    
    if( colored_menus() )
    {
        copy( COLOR_RED, 2, "\r" );
        copy( COLOR_WHITE, 2, "\w" );
        copy( COLOR_YELLOW, 2, "\y" );
        copy( COLOR_GREY, 2, "\d" );
    }
    
    writtenSize = get_configsdir( g_configsDirPath, charsmax( g_configsDirPath ) );
    copy( g_configsDirPath[ writtenSize ], charsmax( g_configsDirPath ) - writtenSize, "/galileo" );
    
    writtenSize = get_datadir( g_dataDirPath, charsmax( g_dataDirPath ) );
    copy( g_dataDirPath[ writtenSize ], charsmax( g_dataDirPath ) - writtenSize, "/galileo" );
    
    if( !dir_exists( g_dataDirPath )
        && mkdir( g_dataDirPath ) )
    {
        LOGGER( 1, "AMX_ERR_NOTFOUND, %L", LANG_SERVER, "GAL_CREATIONFAILED", g_dataDirPath );
        log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_CREATIONFAILED", g_dataDirPath );
    }
    
    LOGGER( 1, "( loadPluginSetttings ) g_configsDirPath: %s, g_dataDirPath: %s,", \
                                        g_configsDirPath,     g_dataDirPath );
    
    server_cmd( "exec %s/galileo.cfg", g_configsDirPath );
    server_exec();
}

stock initializeGlobalArrays()
{
    LOGGER( 128, "I AM ENTERING ON initializeGlobalArrays(0)" );
    
    get_pcvar_string( cvar_voteWeightFlags, g_voteWeightFlags, charsmax( g_voteWeightFlags ) );
    get_cvar_string( "amx_nextmap", g_nextMap, charsmax( g_nextMap ) );
    get_mapname( g_currentMap, charsmax( g_currentMap ) );
    
    g_nominationMapsTrie  = TrieCreate();
    g_playersNominations  = TrieCreate();
    g_fillerMaps          = ArrayCreate( MAX_MAPNAME_LENGHT );
    g_nominationMapsArray = ArrayCreate( MAX_MAPNAME_LENGHT );
    
    // initialize nominations table
    nomination_clearAll();
    
    if( get_pcvar_num( cvar_recentMapsBannedNumber ) )
    {
        register_clcmd( "say recentmaps", "cmd_listrecent", 0 );
        
        map_loadRecentList();
        
        if( !( get_cvar_num( "gal_server_starting" )
               && get_pcvar_num( cvar_serverStartAction ) ) )
        {
            map_writeRecentList();
        }
    }
}

stock cacheCvarsValues()
{
    LOGGER( 128, "I AM ENTERING ON cacheCvarsValues(0)" );
    
    g_rtvCommands            = get_pcvar_num( cvar_rtvCommands );
    g_extendmapStepRounds    = get_pcvar_num( cvar_extendmapStepRounds );
    g_extendmapStepMinutes   = get_pcvar_num( cvar_extendmapStepMinutes );
    g_extendmapAllowStayType = get_pcvar_num( cvar_extendmapAllowStayType );
    g_showVoteStatus         = get_pcvar_num( cvar_showVoteStatus );
    g_voteShowNoneOptionType = get_pcvar_num( cvar_voteShowNoneOptionType );
    g_showVoteStatusType     = get_pcvar_num( cvar_showVoteStatusType );
    
    g_isColoredChatEnabled = get_pcvar_num( cvar_coloredChatEnabled ) != 0;
    g_isExtendmapAllowStay = get_pcvar_num( cvar_extendmapAllowStay ) != 0;
    g_isToShowNoneOption   = get_pcvar_num( cvar_isToShowNoneOption ) != 0;
    g_isToShowVoteCounter  = get_pcvar_num( cvar_isToShowVoteCounter ) != 0;
    g_isToShowExpCountdown = get_pcvar_num( cvar_isToShowExpCountdown ) != 0;
    
    g_maxVotingChoices = max( min( MAX_OPTIONS_IN_VOTE, get_pcvar_num( cvar_voteMapChoiceCount ) ), 2 );
}

stock configureRTV()
{
    LOGGER( 128, "I AM ENTERING ON configureRTV(0)" );
    
    g_rtvMinutesWait = get_pcvar_float( cvar_rtvMinutesWait );
    g_rtvWaitRounds  = get_pcvar_num( cvar_rtvWaitRounds );
    
    if( g_rtvCommands & RTV_CMD_STANDARD )
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
}

stock configureServerStart()
{
    LOGGER( 128, "I AM ENTERING ON configureServerStart(0)" );
    
    if( get_pcvar_num( cvar_gameCrashRecreationAction ) )
    {
        g_isToCreateGameCrashFlag = true;
    }
    else
    {
        g_isToCreateGameCrashFlag = false;
    }
    
    if( get_cvar_num( "gal_server_starting" ) )
    {
        new backupMapsFilePath[ MAX_FILE_PATH_LENGHT ];
        formatex( backupMapsFilePath, charsmax( backupMapsFilePath ), "%s/%s", g_dataDirPath, CURRENT_AND_NEXTMAP_FILE_NAME );
        
        if( file_exists( backupMapsFilePath ) )
        {
            handleServerStart( backupMapsFilePath );
        }
        else
        {
            saveCurrentAndNextMapNames( g_nextMap );
        }
    }
    else // update the current and next map names every server start
    {
        saveCurrentAndNextMapNames( g_nextMap );
    }
}

/**
 * Setup the main task that schedules the end map voting and allow round finish feature.
 */
stock configureServerMapChange()
{
    LOGGER( 128, "I AM ENTERING ON configureServerMapChange(0)" );
    
    if( get_pcvar_num( cvar_emptyWait )
        || get_pcvar_num( cvar_isEmptyCycleServerChange ) )
    {
        g_emptyCycleMapsList = ArrayCreate( MAX_MAPNAME_LENGHT );
        map_loadEmptyCycleList();
        
        if( get_pcvar_num( cvar_emptyWait ) )
        {
            set_task( 60.0, "inicializeEmptyCycleFeature" );
        }
    }
    
    set_task( 15.0, "vote_manageEnd", _, _, _, "b" );
}

public team_win_event()
{
    LOGGER( 128, "I AM ENTERING ON team_win_event(0)" );
    
    new wins_Terrorist_trigger;
    new wins_CT_trigger;
    new string_team_winner[ 16 ];
    
    read_logargv( 1, string_team_winner, charsmax( string_team_winner ) );
    
    if( string_team_winner[ 0 ] == 'T' )
    {
        g_totalTerroristsWins++;
    }
    else if( string_team_winner[ 0 ] == 'C' )
    {
        g_totalCtWins++;
    }
    
    g_winLimitInteger = get_pcvar_num( cvar_mp_winlimit );
    
    if( g_winLimitInteger )
    {
        wins_CT_trigger        = g_totalCtWins + VOTE_START_ROUNDS;
        wins_Terrorist_trigger = g_totalTerroristsWins + VOTE_START_ROUNDS;
        
        if( ( ( wins_CT_trigger > g_winLimitInteger )
              || ( wins_Terrorist_trigger > g_winLimitInteger ) )
            && !IS_END_OF_MAP_VOTING_GOING_ON() )
        {
            g_isMaxroundsExtend = false;
            
            VOTE_START_ROUND_DELAY();
        }
    }
    
    LOGGER( 32, "( team_win_event ) | string_team_winner = %s, \
            g_winLimitInteger = %d, wins_CT_trigger = %d, wins_Terrorist_trigger = %d", \
                                      string_team_winner, \
            g_winLimitInteger,      wins_CT_trigger,      wins_Terrorist_trigger );
}

public start_voting_by_rounds()
{
    LOGGER( 128, "I AM ENTERING ON start_voting_by_rounds(0) | get_pcvar_num( cvar_endOfMapVote ): %d", \
            get_pcvar_num( cvar_endOfMapVote ) );
    
    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_isVotingByRounds = true;
        vote_startDirector( false );
    }
}

public start_voting_by_timer()
{
    LOGGER( 128, "I AM ENTERING ON start_voting_by_timer(0) | get_pcvar_num( cvar_endOfMapVote ): %d", \
            get_pcvar_num( cvar_endOfMapVote ) );
    
    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_isVotingByTimer = true;
        vote_startDirector( false );
    }
}

public round_start_event()
{
    LOGGER( 128, "I AM ENTERING ON round_start_event(0)" );
    
    if( VOTE_ROUND_START_DETECTION_DELAYED( get_timeleft() )
        && get_pcvar_num( cvar_endOfMapVoteStart )
        && !task_exists( TASKID_START_VOTING_BY_TIMER ) )
    {
        set_task( VOTE_ROUND_START_SECONDS_DELAY(), "start_voting_by_timer", TASKID_START_VOTING_BY_TIMER );
    }
    
    if( g_isTimeToResetRounds )
    {
        g_isTimeToResetRounds = false;
        set_task( 1.0, "resetRoundsScores" );
    }
    
    if( g_isTimeToResetGame )
    {
        g_isTimeToResetGame = false;
        set_task( 1.0, "map_restoreEndGameCvars" );
    }
}

public client_death_event()
{
    LOGGER( 128, "I AM ENTERING ON client_death_event(0)" );
    
    static frags;
    static killerId;
    
    killerId = read_data( 1 );
    
    if( killerId )
    {
        if( ( ( ( frags = ++g_playersKills[ killerId ] ) + VOTE_START_FRAGS ) > g_fragLimitNumber )
            && !IS_END_OF_MAP_VOTING_GOING_ON() )
        {
            g_isMaxfragsExtend = true;
            VOTE_START_ROUND_DELAY();
        }
        
        if( frags > g_greatestKillerFrags )
        {
            g_greatestKillerFrags = frags;
        }
    }
}

public round_end_event()
{
    LOGGER( 128, "I AM ENTERING ON round_end_event(0)" );
    new current_rounds_trigger;
    
    g_roundsPlayedNumber++;
    g_maxRoundsNumber = get_pcvar_num( cvar_mp_maxrounds );
    
    if( g_maxRoundsNumber )
    {
        current_rounds_trigger = g_roundsPlayedNumber + VOTE_START_ROUNDS;
        
        if( ( current_rounds_trigger > g_maxRoundsNumber )
            && !IS_END_OF_MAP_VOTING_GOING_ON() )
        {
            g_isMaxroundsExtend = true;
            
            VOTE_START_ROUND_DELAY();
        }
    }
    
    endGameWatchdog();
    LOGGER( 32, "( round_end_event ) | g_maxRoundsNumber = %d, \
            g_roundsPlayedNumber = %d, current_rounds_trigger = %d", \
                                       g_maxRoundsNumber, \
            g_roundsPlayedNumber,      current_rounds_trigger );
}

stock endGameWatchdog()
{
    LOGGER( 128, "I AM ENTERING ON endGameWatchdog(0)" );
    
    g_fragLimitNumber = get_pcvar_num( cvar_mp_fraglimit );
    g_timeLimitNumber = get_pcvar_num( cvar_mp_timelimit );
    
    if( g_isTheLastGameRound )
    {
        if( g_isTimeToChangeLevel
            || g_isRtvLastRound ) // when time runs out, end map at the current round end
        {
            g_isTimeToChangeLevel = true;
            g_isRtvLastRound      = false;
            g_isTheLastGameRound     = false;
            
            remove_task( TASKID_SHOW_LAST_ROUND_HUD );
            set_task( 6.0, "process_last_round", TASKID_PROCESS_LAST_ROUND );
        }
        else // when time runs out, end map at the next round end
        {
            g_isTimeToChangeLevel = true;
            
            remove_task( TASKID_SHOW_LAST_ROUND_HUD );
            set_task( 5.0, "configure_last_round_HUD", TASKID_PROCESS_LAST_ROUND );
        }
    }
}

public process_last_round()
{
    LOGGER( 128, "I AM ENTERING ON process_last_round(0)" );
    
    if( g_isRtvLastRound )
    {
        configure_last_round_HUD();
    }
    else if( get_pcvar_num( cvar_isEndMapCountdown )
             && g_isTimeToChangeLevel )
    {
        g_lastRroundCountdown = 6;
        set_task( 1.0, "process_last_round_counting", TASKID_PROCESS_LAST_ROUND, _, _, "a", 6 );
    }
    else
    {
        intermission_display();
    }
}

public process_last_round_counting()
{
    LOGGER( 128, "I AM ENTERING ON process_last_round_counting(0)" );
    new real_number = g_lastRroundCountdown - 1;
    
    if( real_number )
    {
        // visual countdown
        set_hudmessage( 255, 10, 10, -1.0, 0.13, 0, 1.0, 0.94, 0.0, 0.0, -1 );
        show_hudmessage( 0, "%d %L...", real_number, LANG_PLAYER, "GAL_TIMELEFT" );
        
        // audio countdown
        if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_COUNTDOWN ) )
        {
            new word[ 6 ];
            num_to_word( real_number, word, 5 );
            
            client_cmd( 0, "spk ^"fvox/%s^"", word );
        }
    }
    
    // decrement the countdown
    g_lastRroundCountdown--;
    
    if( g_lastRroundCountdown == 0 )
    {
        intermission_display();
    }
}

stock intermission_display()
{
    LOGGER( 128, "I AM ENTERING ON intermission_display(0)" );
    
    if( g_isTimeToChangeLevel )
    {
        new Float:mp_chattime = get_pcvar_float( cvar_mp_chattime );
        
        if( mp_chattime > 12 )
        {
            mp_chattime = 12.0;
        }
        
        if( g_isTimeToRestart )
        {
            set_task( mp_chattime, "map_change_stays", TASKID_MAP_CHANGE );
        }
        else
        {
            set_task( mp_chattime, "map_change", TASKID_MAP_CHANGE );
        }
        
        // freeze the game and show the scoreboard
        if( get_pcvar_num( cvar_isEndMapCountdown ) )
        {
            g_isTimeToResetGame    = true; // reset the game ending if there is a restart round.
            g_original_sv_maxspeed = get_pcvar_float( cvar_sv_maxspeed );
            
            set_pcvar_float( cvar_sv_maxspeed, 0.0 );
            
            client_cmd( 0, "slot1" );
            client_cmd( 0, "drop weapon_c4" );
            client_cmd( 0, "drop" );
            client_cmd( 0, "drop" );
            
            client_cmd( 0, "sgren" );
            client_cmd( 0, "hegren" );
            
            client_cmd( 0, "+showscores" );
            client_cmd( 0, "speak ^"loading environment on to your computer^"" );
        }
        else
        {
            message_begin( MSG_ALL, SVC_INTERMISSION );
            message_end();
        }
    }
}

/**
 * Return whether the gaming is on going.
 */
stock is_there_game_commencing()
{
    LOGGER( 128, "I AM ENTERING ON is_there_game_commencing(0)" );
    new players[ 32 ];
    
    new players_count;
    new CT_count = 0;
    new TR_count = 0;
    
    get_players( players, players_count );
    
    for( new player_index = 0; player_index < players_count; player_index++ )
    {
        switch( get_user_team( players[ player_index ] ) )
        {
            case 1:
            {
                TR_count++; // terror
            }
            case 2:
            {
                CT_count++; // ct
            }
        }
        
        if( CT_count && TR_count )
        {
            return true;
        }
    }
    
    return false;
}

/**
 * Reset rounds scores every game restart event. This relies on that the 'game_commencing_event()'
 * is not triggered by the 'round_restart_event()'. This use 'is_there_game_commencing()' to determine
 * if it must restore the time limit by calling 'game_commencing_event()', when there is none game
 * on going, to avoid the infinity time limit due the allow last round finish feature.
 */
public round_restart_event()
{
    LOGGER( 128, "I AM ENTERING ON round_restart_event(0)" );
    
    if( g_isEndGameLimitsChanged
        && is_there_game_commencing()
        && ( ( get_pcvar_num( cvar_mp_timelimit )
               && get_pcvar_num( cvar_serverTimeLimitRestart ) )
             || ( get_pcvar_num( cvar_mp_maxrounds )
                  && get_pcvar_num( cvar_serverMaxroundsRestart ) )
             || ( get_pcvar_num( cvar_mp_winlimit )
                  && get_pcvar_num( cvar_serverWinlimitRestart ) ) ) )
    {
        g_isTimeToResetRounds = true;
        
        cancelVoting( true );
    }
    else
    {
        game_commencing_event();
    }
}

/**
 * Make sure the reset time is the original time limit.
 */
public game_commencing_event()
{
    LOGGER( 128, "I AM ENTERING ON game_commencing_event(0)" );
    
    g_isTimeToResetGame   = true;
    g_isTimeToResetRounds = true;
    
    cancelVoting( true );
}

/**
 * Reset the round ending, if it is in progress.
 */
stock resetRoundEnding()
{
    LOGGER( 128, "I AM ENTERING ON resetRoundEnding(0)" );
    
    g_isTimeToChangeLevel = false;
    g_isTimeToRestart     = false;
    g_isRtvLastRound      = false;
    g_isTheLastGameRound     = false;
    
    remove_task( TASKID_SHOW_LAST_ROUND_HUD );
    client_cmd( 0, "-showscores" );
}

stock saveRoundEnding( roundEndStatus[] )
{
    LOGGER( 128, "I AM ENTERING ON saveRoundEnding(1) | roundEndStatus: %d, %d, %d, %d", \
            roundEndStatus[ 0 ], roundEndStatus[ 1 ], roundEndStatus[ 2 ], roundEndStatus[ 3 ] );
    
    roundEndStatus[ 0 ] = g_isTimeToChangeLevel;
    roundEndStatus[ 1 ] = g_isTimeToRestart;
    roundEndStatus[ 2 ] = g_isRtvLastRound;
    roundEndStatus[ 3 ] = g_isTheLastGameRound;
}

stock restoreRoundEnding( roundEndStatus[] )
{
    LOGGER( 128, "I AM ENTERING ON restoreRoundEnding(1) | roundEndStatus: %d, %d, %d, %d", \
            roundEndStatus[ 0 ], roundEndStatus[ 1 ], roundEndStatus[ 2 ], roundEndStatus[ 3 ] );
    
    g_isTimeToChangeLevel = bool:roundEndStatus[ 0 ];
    g_isTimeToRestart     = bool:roundEndStatus[ 1 ];
    g_isRtvLastRound      = bool:roundEndStatus[ 2 ];
    g_isTheLastGameRound  = bool:roundEndStatus[ 3 ];
}

public resetRoundsScores()
{
    LOGGER( 128, "I AM ENTERING ON resetRoundsScores(0)" );
    
    if( get_pcvar_num( cvar_serverTimeLimitRestart )
        || get_pcvar_num( cvar_serverWinlimitRestart )
        || get_pcvar_num( cvar_serverMaxroundsRestart ) )
    {
        saveEndGameLimits();
        
        if( get_pcvar_num( cvar_mp_timelimit )
            && get_pcvar_num( cvar_serverTimeLimitRestart ) )
        {
            new new_timelimit =
            (
                floatround( get_pcvar_num( cvar_mp_timelimit ) - map_getMinutesElapsed(),
                            floatround_floor )
                +
                get_pcvar_num( cvar_serverTimeLimitRestart ) - 1
            );
            
            if( new_timelimit > 0 )
            {
                set_pcvar_num( cvar_mp_timelimit, new_timelimit );
            }
        }
        
        if( get_pcvar_num( cvar_mp_winlimit )
            && get_pcvar_num( cvar_serverWinlimitRestart ) )
        {
            new new_winlimit =
            (
                get_pcvar_num( cvar_mp_winlimit ) - max( g_totalTerroristsWins, g_totalCtWins )
                +
                get_pcvar_num( cvar_serverWinlimitRestart ) - 1
            );
            
            if( new_winlimit > 0 )
            {
                set_pcvar_num( cvar_mp_winlimit, new_winlimit );
            }
        }
        
        if( get_pcvar_num( cvar_mp_maxrounds )
            && get_pcvar_num( cvar_serverMaxroundsRestart ) )
        {
            new new_maxrounds = ( get_pcvar_num( cvar_mp_maxrounds ) - g_roundsPlayedNumber
                                  + get_pcvar_num( cvar_serverMaxroundsRestart ) - 1 );
            
            if( new_maxrounds > 0 )
            {
                set_pcvar_num( cvar_mp_maxrounds, new_maxrounds );
            }
        }
    }
    
    g_totalTerroristsWins = 0;
    g_totalCtWins         = 0;
    g_roundsPlayedNumber   = -1;
}

public configure_last_round_HUD()
{
    LOGGER( 128, "I AM ENTERING ON configure_last_round_HUD(0)" );
    
    if( get_pcvar_num( cvar_endOnRound_msg ) )
    {
        set_task( 1.0, "show_last_round_HUD", TASKID_SHOW_LAST_ROUND_HUD, _, _, "b" );
    }
}

public show_last_round_HUD()
{
    LOGGER( 128, "I AM ENTERING ON show_last_round_HUD(0)" );
    
    set_hudmessage( 255, 255, 255, 0.15, 0.15, 0, 0.0, 1.0, 0.1, 0.1, 1 );
    static last_round_message[ MAX_COLOR_MESSAGE ];

#if AMXX_VERSION_NUM < 183
    static player_id;
    static playerIndex;
    static playersCount;
    static players[ MAX_PLAYERS ];
#endif
    
    last_round_message[ 0 ] = '^0';
    
    if( g_isTimeToChangeLevel
        || g_isRtvLastRound )
    {
        // This is because the Amx Mod X 1.8.2 is not recognizing the player LANG_PLAYER when it is
        // formatted before with formatex(...)
    #if AMXX_VERSION_NUM < 183
        get_players( players, playersCount, "ch" );
        
        for( playerIndex = 0; playerIndex < playersCount; playerIndex++ )
        {
            player_id = players[ playerIndex ];
            
            formatex( last_round_message, charsmax( last_round_message ), "%L ^n%L",
                    player_id, "GAL_CHANGE_NEXTROUND",  player_id, "GAL_NEXTMAP", g_nextMap );
            
            REMOVE_COLOR_TAGS( last_round_message );
            show_hudmessage( player_id, last_round_message );
        }
    #else
        formatex( last_round_message, charsmax( last_round_message ), "%L ^n%L",
                LANG_PLAYER, "GAL_CHANGE_NEXTROUND",  LANG_PLAYER, "GAL_NEXTMAP", g_nextMap );
        
        REMOVE_COLOR_TAGS( last_round_message );
        show_hudmessage( 0, last_round_message );
    #endif
    }
    else
    {
    #if AMXX_VERSION_NUM < 183
        get_players( players, playersCount, "ch" );
        
        for( playerIndex = 0; playerIndex < playersCount; playerIndex++ )
        {
            player_id = players[ playerIndex ];
            formatex( last_round_message, charsmax( last_round_message ), "%L", player_id, "GAL_CHANGE_TIMEEXPIRED" );
            
            REMOVE_COLOR_TAGS( last_round_message );
            show_hudmessage( player_id, last_round_message );
        }
    #else
        formatex( last_round_message, charsmax( last_round_message ), "%L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED" );
        
        REMOVE_COLOR_TAGS( last_round_message );
        show_hudmessage( 0, last_round_message );
    #endif
    }
}

public plugin_end()
{
    LOGGER( 32, "" );
    LOGGER( 32, "" );
    LOGGER( 32, "" );
    LOGGER( 32, "I AM ENTERING ON plugin_end(0). THE END OF THE PLUGIN LIFE!" );
    
    map_restoreEndGameCvars();
    new gameCrashActionFilePath[ MAX_FILE_PATH_LENGHT ];
    
    generateGameCrashActionFilePath( gameCrashActionFilePath, charsmax( gameCrashActionFilePath ) );
    delete_file( gameCrashActionFilePath );
    
    if( g_emptyCycleMapsList )
    {
        ArrayDestroy( g_emptyCycleMapsList );
    }
    
    if( g_fillerMaps )
    {
        ArrayDestroy( g_fillerMaps );
    }
    
    if( g_nominationMapsArray )
    {
        ArrayDestroy( g_nominationMapsArray );
    }
    
    if( g_playersNominations )
    {
        TrieDestroy( g_playersNominations );
    }
    
    if( g_nominationMapsTrie )
    {
        TrieDestroy( g_nominationMapsTrie );
    }
    
    // Clear the dynamic array menus, just to be sure.
    for( new currentIndex = 0; currentIndex < MAX_PLAYERS_COUNT; ++currentIndex )
    {
        clearMenuMapIndexForPlayers( currentIndex );
    }
    
    // Clean the unit tests data 
#if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST
    restore_server_cvars_for_test();
    
    if( g_tests_idsAndNames )
    {
        ArrayDestroy( g_tests_idsAndNames );
    }
    
    if( g_tests_failure_ids )
    {
        ArrayDestroy( g_tests_failure_ids );
    }
    
    if( g_tests_failure_reasons )
    {
        ArrayDestroy( g_tests_failure_reasons );
    }
#endif
}

/**
 * Indicates which action to take when it is detected that the server
 * has been 'externally restarted'. By 'externally restarted', is mean to
 * say the Computer's Operational System (Linux) or Server Manager (HLSW),
 * used the server command 'quit' and reopened the server.
 *
 * 0 - stay on the map the server started with
 * 1 - change to the map that was being played when the server was reset
 * 2 - change to what would have been the next map had the server not
 *     been restarted ( if the next map isn't known, this acts like 3 )
 * 3 - start an early map vote after the first two minutes
 * 4 - change to a randomly selected map from your nominatable map list
 */
public handleServerStart( backupMapsFilePath[] )
{
    LOGGER( 128, "I AM ENTERING ON handleServerStart(1) | backupMapsFilePath: %s", backupMapsFilePath );
    new startAction;
    
    // this is the key that tells us if this server has been restarted or not
    set_cvar_num( "gal_server_starting", 0 );
    
    // take the defined "server start" action
    startAction = get_pcvar_num( cvar_serverStartAction );
    
    if( !isHandledGameCrashAction( startAction )
        && startAction )
    {
        new mapToChange[ MAX_MAPNAME_LENGHT ];
        
        if( startAction == SERVER_START_CURRENTMAP
            || startAction == SERVER_START_NEXTMAP )
        {
            new backupMapsFile = fopen( backupMapsFilePath, "rt" );
            
            if( backupMapsFile )
            {
                fgets( backupMapsFile, mapToChange, charsmax( mapToChange ) );
                
                if( startAction == SERVER_START_NEXTMAP )
                {
                    mapToChange[ 0 ] = '^0';
                    fgets( backupMapsFile, mapToChange, charsmax( mapToChange )  );
                }
                
                trim( mapToChange );
                fclose( backupMapsFile );
            }
        }
        else if( startAction == SERVER_START_RANDOMMAP ) // pick a random map from allowable nominations
        {
            // if noms aren't allowed, the nomination list hasn't already been loaded
            if( get_pcvar_num( cvar_nomPlayerAllowance ) == 0 )
            {
                map_loadNominationList();
            }
            
            if( g_nominationMapCount )
            {
                ArrayGetString
                (
                    g_nominationMapsArray, random_num( 0, g_nominationMapCount - 1 ),
                    mapToChange, charsmax( mapToChange )
                );
            }
        }
        
        configureTheMapcycleSystem( mapToChange, charsmax( mapToChange ) );
        
        if( mapToChange[ 0 ]
            && is_map_valid( mapToChange ) )
        {
            if( !equali( mapToChange, g_currentMap ) )
            {
                serverChangeLevel( mapToChange );
            }
        }
        else // startAction == SERVER_START_MAPVOTE
        {
            vote_manageEarlyStart();
        }
    }
}

/**
 * 
 * @return true when the crashing was properly handled, false otherwise.
 */
public isHandledGameCrashAction( &startAction )
{
    LOGGER( 128, "I AM ENTERING ON isHandledGameCrashAction(1) | startAction: %d", startAction );
    
    new gameCrashAction;
    new gameCrashActionFilePath[ MAX_FILE_PATH_LENGHT ];
    
    gameCrashAction = get_pcvar_num( cvar_gameCrashRecreationAction );
    generateGameCrashActionFilePath( gameCrashActionFilePath, charsmax( gameCrashActionFilePath ) );
    
    if( gameCrashAction
        && file_exists( gameCrashActionFilePath ) )
    {
        delete_file( gameCrashActionFilePath );
        
        switch( gameCrashAction )
        {
            case 1: // The server will not change to the last map.
            {
                startAction = SERVER_START_NEXTMAP;
            }
            case 2: // The server will start a vote changing the map.
            {
                startAction = SERVER_START_MAPVOTE;
            }
            case 3: // The server will start a vote after the half of the time-left.
            {
                // Wait until the mp_timelimit, etc cvars, to be loaded from the configuration file.
                set_task( 10.0, "setGameToFinishAtHalfTime", TASKID_FINISH_GAME_WITH_HALF_TIME );
            }
        }
    }
    
    return false;
}

stock generateGameCrashActionFilePath( gameCrashActionFilePath[], charsmaxGameCrashActionFilePath )
{
    LOGGER( 128, "I AM ENTERING ON gameCrashActionFilePath(2) | charsmaxGameCrashActionFilePath: %d", charsmaxGameCrashActionFilePath );
    
    formatex( gameCrashActionFilePath, charsmaxGameCrashActionFilePath, "%s/%s", g_dataDirPath, GAME_CRASH_RECREATION_FLAG_FILE );
    LOGGER( 1, "( generateGameCrashActionFilePath ) | gameCrashActionFilePath: %s", gameCrashActionFilePath );
}

/**
 * Save the mp_maxrounds, etc and set them to half of it.
 */
public setGameToFinishAtHalfTime()
{
    LOGGER( 128, "I AM ENTERING ON setGameToFinishAtHalfTime(0)" );
    
    saveEndGameLimits();
    g_isToCreateGameCrashFlag = false; // force to use only the '1/SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR' time.
    
    set_pcvar_float( cvar_mp_timelimit, g_originalTimelimit / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );
    set_pcvar_num(   cvar_mp_maxrounds, g_originalMaxRounds / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );
    set_pcvar_num(   cvar_mp_winlimit,  g_originalWinLimit  / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );
    set_pcvar_num(   cvar_mp_fraglimit, g_originalFragLimit / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );
}

/**
 * To configure the mapcycle system and to detect if the last MAX_SERVER_RESTART_ACCEPTABLE restarts
 * was to the same map. If so, change to the next map right after it.
 */
stock configureTheMapcycleSystem( currentMap[], currentMapCharsMax )
{
    LOGGER( 128, "I AM ENTERING ON configureTheMapcycleSystem(2) | currentMap: %s", currentMap );
    
    new possibleNextMapPosition;
    new restartsOnTheCurrentMap;
    
    new Array:mapcycleFileList;
    new possibleNextMap[ MAX_MAPNAME_LENGHT ];
    
    mapcycleFileList        = ArrayCreate( MAX_MAPNAME_LENGHT );
    restartsOnTheCurrentMap = getRestartsOnTheCurrentMap( currentMap );
    
    map_populateList( mapcycleFileList, g_mapCycleFilePath, charsmax( g_mapCycleFilePath ) );
    possibleNextMapPosition = map_getNext( mapcycleFileList, currentMap, possibleNextMap );
    
    LOGGER( 4, "( configureTheMapcycleSystem ) possibleNextMapPosition: %d, \
            restartsOnTheCurrentMap: %d, currentMap: %s, possibleNextMap: %s", \
                                               possibleNextMapPosition, \
            restartsOnTheCurrentMap,     currentMap,     possibleNextMap );
    
    if( possibleNextMapPosition != -1 )
    {
        if( restartsOnTheCurrentMap > MAX_SERVER_RESTART_ACCEPTABLE )
        {
            new possibleCurrentMap    [ MAX_MAPNAME_LENGHT ];
            new lastMapChangedFilePath[ MAX_FILE_PATH_LENGHT ];
            
            copy( possibleCurrentMap, charsmax( possibleCurrentMap ), possibleNextMap );
            possibleNextMapPosition = map_getNext( mapcycleFileList, possibleCurrentMap, possibleNextMap );
            
            if( possibleNextMapPosition != -1 )
            {
                configureTheNextMapPlugin( possibleNextMapPosition, possibleNextMap );
            }
            
            copy( currentMap, currentMapCharsMax, possibleCurrentMap );
            
            // Clear the old data
            formatex( lastMapChangedFilePath, charsmax( lastMapChangedFilePath ), "%s/%s", g_dataDirPath, LAST_CHANGE_MAP_FILE_NAME );
            
            if( file_exists( lastMapChangedFilePath ) )
            {
                delete_file( lastMapChangedFilePath );
            }
            
            write_file( lastMapChangedFilePath, "nothing_to_be_added_by^n0" );
            log_message( "" );
            log_message( "The server is jumping to the next map after the current map due \
                    more than %d restarts on the map %s.", MAX_SERVER_RESTART_ACCEPTABLE, currentMap );
            log_message( "" );
        }
        else
        {
            configureTheNextMapPlugin( possibleNextMapPosition, possibleNextMap );
            LOGGER( 4, "( configureTheMapcycleSystem ) restartsOnTheCurrentMap < MAX_SERVER_RESTART_ACCEPTABLE" );
            LOGGER( 4, "" );
        }
    }
    else
    {
        configureTheNextMapPlugin( 0, possibleNextMap );
        LOGGER( 4, "( configureTheMapcycleSystem ) configureTheNextMapPlugin( 0, possibleNextMap )" );
        LOGGER( 4, "" );
    }
    
    ArrayDestroy( mapcycleFileList );
}

stock configureTheNextMapPlugin( possibleNextMapPosition, possibleNextMap[] )
{
    LOGGER( 128 + 4, "I AM ENTERING ON configureTheNextMapPlugin(2) | \
            possibleNextMapPosition: %d, possibleNextMap: %s", \
            possibleNextMapPosition,     possibleNextMap );
    
    g_nextMapCyclePosition = possibleNextMapPosition;
    
    setNextMap( possibleNextMap );
    saveCurrentMapCycleSetting();
}

stock getRestartsOnTheCurrentMap( mapToChange[] )
{
    LOGGER( 128, "I AM ENTERING ON getRestartsOnTheCurrentMap(1) | mapToChange: %s", mapToChange );
    
    new lastMapChangedFile;
    new lastMapChangedCount;
    
    new lastMapChangedName       [ MAX_MAPNAME_LENGHT ];
    new lastMapChangedFilePath   [ MAX_FILE_PATH_LENGHT ];
    new lastMapChangedCountString[ 10 ];
    
    formatex( lastMapChangedFilePath, charsmax( lastMapChangedFilePath ), "%s/%s", g_dataDirPath, LAST_CHANGE_MAP_FILE_NAME );
    
    if( !( lastMapChangedFile = fopen( lastMapChangedFilePath, "rt" ) ) )
    {
        if( file_exists( lastMapChangedFilePath ) )
        {
            delete_file( lastMapChangedFilePath );
        }
        
        write_file( lastMapChangedFilePath, "nothing_to_be_added_by^n0" );
    }
    
    LOGGER( 4, "( getRestartsOnTheCurrentMap ) lastMapChangedFilePath: %s, mapToChange: %s", \
                                               lastMapChangedFilePath,     mapToChange );
    
    if( lastMapChangedFile )
    {
        fgets( lastMapChangedFile, lastMapChangedName, charsmax( lastMapChangedName ) );
        fgets( lastMapChangedFile, lastMapChangedCountString, charsmax( lastMapChangedCountString ) );
        
        fclose( lastMapChangedFile );
        trim( lastMapChangedName );
        trim( lastMapChangedCountString );
        
        lastMapChangedCount = str_to_num( lastMapChangedCountString );
        lastMapChangedFile  = fopen( lastMapChangedFilePath, "wt" );
        
        fprintf( lastMapChangedFile, "%s", mapToChange );
        LOGGER( 4, "( getRestartsOnTheCurrentMap ) lastMapChangedName: %s, \
                lastMapChangedCountString: %s, lastMapChangedCount: %d", \
                                                   lastMapChangedName, \
                lastMapChangedCountString,     lastMapChangedCount );
        
        if( equali( mapToChange, lastMapChangedName ) )
        {
            ++lastMapChangedCount;
            
            fprintf( lastMapChangedFile, "^n%d", lastMapChangedCount );
            LOGGER( 4, "( getRestartsOnTheCurrentMap ) mapToChange is equal to lastMapChangedName." );
        }
        else
        {
            lastMapChangedCount = 0;
            
            fprintf( lastMapChangedFile, "^n0" );
            LOGGER( 4, "( getRestartsOnTheCurrentMap ) mapToChange is NOT equal to lastMapChangedName." );
        }
        
        fclose( lastMapChangedFile );
    }
    
    return lastMapChangedCount;
}

/**
 * Action from handleServerStart to take when it is detected that the server has been
 * restarted. 3 - start an early map vote after the first two minutes.
 */
stock vote_manageEarlyStart()
{
    LOGGER( 128, "I AM ENTERING ON vote_manageEarlyStart(0)" );
    
    g_voteStatus |= VOTE_IS_EARLY;
    set_task( 120.0, "startNonForcedVoting", TASKID_VOTE_STARTDIRECTOR );
}

public startNonForcedVoting()
{
    LOGGER( 128, "I AM ENTERING ON startNonForcedVoting(0)" );
    vote_startDirector( false );
}

stock setNextMap( nextMap[] )
{
    LOGGER( 128, "I AM ENTERING ON setNextMap(1) | nextMap: %s", nextMap );
    
    // set the queryable cvar
    set_pcvar_string( g_cvar_amx_nextmap, nextMap );
    copy( g_nextMap, charsmax( g_nextMap ), nextMap );
    
    // update our data file
    saveCurrentAndNextMapNames( nextMap );
}

stock saveCurrentAndNextMapNames( nextMap[] )
{
    LOGGER( 128, "I AM ENTERING ON saveCurrentAndNextMapNames(1) | nextMap: %s", nextMap );
    
    new backupMapsFile;
    new backupMapsFilePath[ MAX_FILE_PATH_LENGHT ];
    
    formatex( backupMapsFilePath, charsmax( backupMapsFilePath ), "%s/%s", g_dataDirPath, CURRENT_AND_NEXTMAP_FILE_NAME );
    backupMapsFile = fopen( backupMapsFilePath, "wt" );
    
    if( backupMapsFile )
    {
        fprintf( backupMapsFile, "%s", g_currentMap );
        fprintf( backupMapsFile, "^n%s", nextMap );
        fclose( backupMapsFile );
    }
}

public vote_manageEnd()
{
    LOGGER( 0, "I AM ENTERING ON vote_manageEnd(0)" );
    new secondsLeft = get_timeleft();
    
    // are we ready to start an "end of map" vote?
    if( IS_TIME_TO_START_THE_END_OF_MAP_VOTING( secondsLeft )
        && !IS_END_OF_MAP_VOTING_GOING_ON() )
    {
        start_voting_by_timer();
    }
    
    if( g_isToCreateGameCrashFlag
        && (  g_timeLimitNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR > secondsLeft / 60
           || g_fragLimitNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR > g_greatestKillerFrags
           || g_maxRoundsNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR > g_roundsPlayedNumber
           || g_winLimitInteger / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR > g_totalTerroristsWins + g_totalCtWins ) )
    {
        new gameCrashActionFilePath[ MAX_FILE_PATH_LENGHT ];
        g_isToCreateGameCrashFlag = false;
        
        generateGameCrashActionFilePath( gameCrashActionFilePath, charsmax( gameCrashActionFilePath ) );
        write_file( gameCrashActionFilePath, "Game Crash Action Flag File^n^nSee the cvar 'gal_game_crash_recreation'.^nDo not delete it." );
    }
    
    // are we managing the end of the map?
    if( secondsLeft < 30
        && secondsLeft > 0
        && !g_isTheLastGameRound
        && get_realplayersnum() >= get_pcvar_num( cvar_endOnRound_msg ) )
    {
        map_manageEnd();
    }
}

public map_manageEnd()
{
    LOGGER( 128, "I AM ENTERING ON map_manageEnd(0)" );
    LOGGER( 2, "%32s mp_timelimit: %f", "map_manageEnd(in)", get_pcvar_float( cvar_mp_timelimit ) );
    
    switch( get_pcvar_num( cvar_endOnRound ) )
    {
        case 1: // when time runs out, end at the current round end
        {
            g_isTheLastGameRound     = true;
            g_isTimeToChangeLevel = true;
            
            color_print( 0, "^1%L %L %L",
                    LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED", LANG_PLAYER, "GAL_CHANGE_NEXTROUND", LANG_PLAYER, "GAL_NEXTMAP", g_nextMap );
            
            prevent_map_change();
        }
        case 2: // when time runs out, end at the next round end
        {
            g_isTheLastGameRound = true;
            
            // This is to avoid have a extra round at special mods where time limit is equal the
            // round timer.
            if( get_pcvar_float( cvar_mp_roundtime ) > 8.0 )
            {
                g_isTimeToChangeLevel = true;
                
                color_print( 0, "^1%L %L %L",
                        LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED", LANG_PLAYER, "GAL_CHANGE_NEXTROUND", LANG_PLAYER, "GAL_NEXTMAP", g_nextMap );
            }
            else
            {
                color_print( 0, "^1%L %L",
                        LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED", LANG_PLAYER, "GAL_NEXTMAP", g_nextMap );
            }
            
            prevent_map_change();
        }
    }
    
    configure_last_round_HUD();
    LOGGER( 2, "%32s mp_timelimit: %f", "map_manageEnd(out)", get_pcvar_float( cvar_mp_timelimit ) );
}

stock prevent_map_change()
{
    LOGGER( 128, "I AM ENTERING ON prevent_map_change(0)" );
    
    new Float:roundTimeMinutes;
    saveEndGameLimits();
    
    // Prevent the map from ending automatically.
    server_cmd( "mp_timelimit 0" );
    
    // Prevent the map from being played indefinitely.
    if( g_isTimeToChangeLevel )
    {
        roundTimeMinutes = 9.0;
    }
    else
    {
        if( ( roundTimeMinutes = get_pcvar_float( cvar_mp_roundtime ) ) > 0 )
        {
            roundTimeMinutes *= 3.0;
        }
        else
        {
            roundTimeMinutes = 9.0;
        }
    }
    
    set_task( roundTimeMinutes * 60, "map_restoreEndGameCvars", TASKID_PREVENT_INFITY_GAME );
}

public map_loadRecentList()
{
    LOGGER( 128, "I AM ENTERING ON map_loadRecentList(0)" );
    
    new recentMapsFilePath[ MAX_FILE_PATH_LENGHT ];
    formatex( recentMapsFilePath, charsmax( recentMapsFilePath ), "%s/recentmaps.dat", g_dataDirPath );
    
    new recentMapsFile = fopen( recentMapsFilePath, "rt" );
    
    if( recentMapsFile )
    {
        new recentMapName[ MAX_MAPNAME_LENGHT ];
        new maxRecentMapsBans = min( get_pcvar_num( cvar_recentMapsBannedNumber ), MAX_RECENT_MAP_COUNT );
        
        while( !feof( recentMapsFile ) )
        {
            fgets( recentMapsFile, recentMapName, charsmax( recentMapName ) );
            trim( recentMapName );
            
            if( recentMapName[ 0 ] )
            {
                if( g_recentMapCount == maxRecentMapsBans )
                {
                    break;
                }
                copy( g_recentMaps[ g_recentMapCount++ ], charsmax( recentMapName ), recentMapName );
            }
        }
        fclose( recentMapsFile );
    }
}

public map_writeRecentList()
{
    LOGGER( 128, "I AM ENTERING ON map_writeRecentList(0)" );
    
    new recentMapsFile;
    new recentMapsFilePath[ MAX_FILE_PATH_LENGHT ];
    
    formatex( recentMapsFilePath, charsmax( recentMapsFilePath ), "%s/recentmaps.dat", g_dataDirPath );
    recentMapsFile = fopen( recentMapsFilePath, "wt" );
    
    if( recentMapsFile )
    {
        fprintf( recentMapsFile, "%s", g_currentMap );
        
        for( new mapIndex = 0; mapIndex < get_pcvar_num( cvar_recentMapsBannedNumber ) - 1; ++mapIndex )
        {
            fprintf( recentMapsFile, "^n%s", g_recentMaps[ mapIndex ] );
        }
        
        fclose( recentMapsFile );
    }
}

public cmd_rockthevote( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_rockthevote(1) | player_id: %d", player_id );
    
    color_print( player_id, "^1%L", player_id, "GAL_CMD_RTV" );
    vote_rock( player_id );
    
    return PLUGIN_HANDLED;
}

public cmd_nominations( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_nominations(1) | player_id: %d", player_id );
    
    color_print( player_id, "^1%L", player_id, "GAL_CMD_NOMS" );
    nomination_list();
    
    return PLUGIN_CONTINUE;
}

public cmd_listrecent( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_listrecent(1) | player_id: %d", player_id );
    
    switch( get_pcvar_num( cvar_banRecentStyle ) )
    {
        case 1:
        {
            new copiedChars;
            new recentMaps[ 101 ];
            
            for( new map_index = 0; map_index < g_recentMapCount; ++map_index )
            {
                copiedChars += formatex( recentMaps[ copiedChars ], charsmax( recentMaps ) - copiedChars,
                        ", %s", g_recentMaps[ map_index ] );
            }
            
            color_print( 0, "^1%L: %s", LANG_PLAYER, "GAL_MAP_RECENTMAPS", recentMaps[ 2 ] );
        }
        case 2:
        {
            for( new map_index = 0; map_index < g_recentMapCount; ++map_index )
            {
                color_print( 0, "^1%L ( %i ): %s",
                        LANG_PLAYER, "GAL_MAP_RECENTMAP", map_index + 1, g_recentMaps[ map_index ] );
            }
        }
        case 3:
        {
            new recent_maps_menu_name[ 64 ];
            
            // assume there'll be more than one match ( because we're lazy ) and starting building the match menu
            if( g_generalUsePlayersMenuId[ player_id ] )
            {
                menu_destroy( g_generalUsePlayersMenuId[ player_id ] );
            }
            
            formatex( recent_maps_menu_name, charsmax( recent_maps_menu_name ), "%L", player_id, "GAL_MAP_RECENTMAPS" );
            g_generalUsePlayersMenuId[ player_id ] = menu_create( recent_maps_menu_name, "cmd_listrecent_handler" );
            
            for( new map_index = 0; map_index < g_recentMapCount; ++map_index )
            {
                menu_additem( g_generalUsePlayersMenuId[ player_id ], g_recentMaps[ map_index ] );
            }
            
            menu_display( player_id, g_generalUsePlayersMenuId[ player_id ] );
        }
    }
    
    return PLUGIN_HANDLED;
}

public cmd_listrecent_handler( player_id, menu, item )
{
    LOGGER( 1, "( cmd_listrecent_handler ) | player_id: %d, menu: %d, item: %d", player_id, menu, item );
    
    if( item < 0 )
    {
        return PLUGIN_CONTINUE;
    }
    
    menu_display( player_id, g_generalUsePlayersMenuId[ player_id ] );
    return PLUGIN_HANDLED;
}

public cmd_cancelVote( player_id, level, cid )
{
    LOGGER( 1, "( cmd_cancelVote ) player_id: %d, level: %d, cid: %d", player_id, level, cid );
    
    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        return PLUGIN_HANDLED;
    }
    
    cancelVoting( true );
    return PLUGIN_HANDLED;
}

/**
 * Called when need to start a vote map, where the command line first argument could be:
 *    -nochange: extend the current map, aka, Keep Current Map, will to do the real extend.
 *    -restart: extend the current map, aka, Keep Current Map restart the server at the current map.
 */
public cmd_startVote( player_id, level, cid )
{
    LOGGER( 1, "( cmd_startVote ) player_id: %d, level: %d, cid: %d", player_id, level, cid );
    
    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        return PLUGIN_HANDLED;
    }
    
    if( g_voteStatus & VOTE_IS_IN_PROGRESS )
    {
        color_print( player_id, "^1%L", player_id, "GAL_VOTE_INPROGRESS" );
    }
    else
    {
        g_isTimeToChangeLevel = true;
        
        if( read_argc() == 2 )
        {
            new argument[ 32 ];
            
            read_args( argument, charsmax( argument ) );
            remove_quotes( argument );
            
            if( equali( argument, "-nochange" ) )
            {
                g_isTimeToChangeLevel = false;
            }
            
            if( equali( argument, "-restart", 4 ) )
            {
                g_isTimeToRestart = true;
            }
            
            LOGGER( 1, "( cmd_startVote ) equal( %s, '-restart', 4 )? %d", \
                                argument, equal( argument, "-restart", 4 ) );
        }
        
        LOGGER( 1, "( cmd_startVote ) g_isTimeToRestart? %d, \
                g_isTimeToChangeLevel? %d, g_voteStatus & VOTE_IS_FORCED: %d", \
                                      g_isTimeToRestart, \
                g_isTimeToChangeLevel,     g_voteStatus & VOTE_IS_FORCED != 0 );
        
        vote_startDirector( true );
    }
    
    return PLUGIN_HANDLED;
}

public cmd_createMapFile( player_id, level, cid )
{
    LOGGER( 1, "( cmd_createMapFile ) | player_id: %d, level: %d, cid: %d", player_id, level, cid );
    
    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        return PLUGIN_HANDLED;
    }
    
    new argumentsNumber = read_argc() - 1;
    
    switch( argumentsNumber )
    {
        case 1:
        {
            new mapFileName[ MAX_MAPNAME_LENGHT ];
            read_argv( 1, mapFileName, charsmax( mapFileName ) );
            remove_quotes( mapFileName );
            
            // map name is MAX_MAPNAME_LENGHT, .bsp: 4 + string terminator: 1 = 5
            new loadedMapName[ MAX_MAPNAME_LENGHT + 5 ];
            
            new dir;
            new mapFile;
            new mapCount;
            new mapNameLength;
            
            dir = open_dir( "maps", loadedMapName, charsmax( loadedMapName )  );
            
            if( dir )
            {
                new mapFilePath[ MAX_FILE_PATH_LENGHT ];
                formatex( mapFilePath, charsmax( mapFilePath ), "%s/%s", g_configsDirPath, mapFileName );
                
                mapFile = fopen( mapFilePath, "wt" );
                
                if( mapFile )
                {
                    mapCount = 0;
                    
                    while( next_file( dir, loadedMapName, charsmax( loadedMapName ) ) )
                    {
                        mapNameLength = strlen( loadedMapName );
                        
                        if( mapNameLength > 4
                            && equali( loadedMapName[ mapNameLength - 4 ], ".bsp", 4 ) )
                        {
                            loadedMapName[ mapNameLength - 4 ] = '^0';
                            
                            if( is_map_valid( loadedMapName ) )
                            {
                                mapCount++;
                                fprintf( mapFile, "%s^n", loadedMapName );
                            }
                        }
                    }
                    fclose( mapFile );
                    con_print( player_id, "%L", player_id, "GAL_CREATIONSUCCESS", mapFilePath, mapCount );
                }
                else
                {
                    con_print( player_id, "%L", player_id, "GAL_CREATIONFAILED", mapFilePath );
                }
                close_dir( dir );
            }
            else
            {
                // directory not found, wtf?
                con_print( player_id, "%L", player_id, "GAL_MAPSFOLDERMISSING" );
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

/**
 * Called when need to start a vote map, where the command line first argument could be:
 *    -nochange: extend the current map, aka, Keep Current Map, will to do the real extend.
 *    -restart: extend the current map, aka, Keep Current Map restart the server at the current map.
 */
public cmd_maintenanceMode( player_id, level, cid )
{
    LOGGER( 1, "( cmd_maintenanceMode ) player_id: %d, level: %d, cid: %d", player_id, level, cid );
    
    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        return PLUGIN_HANDLED;
    }
    
    if( g_isOnMaintenanceMode )
    {
        g_isOnMaintenanceMode = false;
        color_print( player_id, "^1%L", player_id, "GAL_CHANGE_MAINTENANCE_STATE", player_id, "GAL_CHANGE_MAINTENANCE_OFF" );
    }
    else
    {
        g_isOnMaintenanceMode = true;
        color_print( player_id, "^1%L", player_id, "GAL_CHANGE_MAINTENANCE_STATE", player_id, "GAL_CHANGE_MAINTENANCE_ON" );
    }
    
    return PLUGIN_HANDLED;
}

stock map_populateList( Array:mapArray, mapFilePath[], mapFilePathMaxChars, Trie:fillerMapTrie = Invalid_Trie )
{
    LOGGER( 128, "I AM ENTERING ON map_populateList(4) | mapFilePath: %s", mapFilePath );
    
    // load the array with maps
    new mapCount;
    
    // clear the map array in case we're reusing it
    ArrayClear( mapArray );
    
    if( !equal( mapFilePath, "*" )
        && !equal( mapFilePath, "#" ) )
    {
        LOGGER( 4, "" );
        LOGGER( 4, "    map_populateList(...) Loading the PASSED FILE! mapFilePath: %s", mapFilePath );
        mapCount = loadMapFileList( mapArray, mapFilePath, fillerMapTrie );
    }
    else if( equal( mapFilePath, "*" ) )
    {
        LOGGER( 4, "" );
        LOGGER( 4, "    map_populateList(...) Loading the MAP FOLDER! mapFilePath: %s", mapFilePath );
        mapCount = loadMapsFolderDirectory( mapArray, fillerMapTrie );
    }
    else
    {
        get_cvar_string( "mapcyclefile", mapFilePath, mapFilePathMaxChars );
        
        LOGGER( 4, "" );
        LOGGER( 4, "    map_populateList(...) Loading the MAPCYCLE! mapFilePath: %s", mapFilePath );
        mapCount = loadMapFileList( mapArray, mapFilePath, fillerMapTrie );
    }
    
    return mapCount;
}

stock loadMapFileList( Array:mapArray, mapFilePath[], Trie:fillerMapTrie )
{
    LOGGER( 128, "I AM ENTERING ON loadMapFileList(3) | mapFilePath: %s", mapFilePath );
    
    new mapCount;
    new mapFile = fopen( mapFilePath, "rt" );

#if defined DEBUG
    new current_index = -1;
#endif
    
    if( mapFile )
    {
        new loadedMapName[ MAX_MAPNAME_LENGHT ];
        
        while( !feof( mapFile ) )
        {
            fgets( mapFile, loadedMapName, charsmax( loadedMapName ) );
            trim( loadedMapName );
            
            if( loadedMapName[ 0 ]
                && !equal( loadedMapName, "//", 2 )
                && !equal( loadedMapName, ";", 1 )
                && is_map_valid( loadedMapName ) )
            {
                if( fillerMapTrie )
                {
                    TrieSetCell( fillerMapTrie, loadedMapName, 0 );
                }
                
                LOGGER( 4, "map_populateList() %d, loadedMapName: %s", ++current_index, loadedMapName );
                ArrayPushString( mapArray, loadedMapName );
                
                ++mapCount;
            }
        }
        
        fclose( mapFile );
        LOGGER( 4, "" );
    }
    else
    {
        LOGGER( 1, "AMX_ERR_NOTFOUND, %L", LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilePath );
        log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilePath );
    }
    
    return mapCount;
}

stock loadMapsFolderDirectory( Array:mapArray, Trie:fillerMapTrie )
{
    LOGGER( 128, "I AM ENTERING ON map_populateList(2) | Array:mapArray: %d", mapArray );
    
    new mapCount;
    new loadedMapName[ MAX_MAPNAME_LENGHT ];
    
    new dir = open_dir( "maps", loadedMapName, charsmax( loadedMapName ) );
    
    if( dir )
    {
        new mapNameLength;
        
        while( next_file( dir, loadedMapName, charsmax( loadedMapName ) ) )
        {
            mapNameLength = strlen( loadedMapName );
            
            if( mapNameLength > 4
                && equali( loadedMapName[ mapNameLength - 4 ], ".bsp", 4 ) )
            {
                loadedMapName[ mapNameLength - 4 ] = '^0';
                
                if( is_map_valid( loadedMapName ) )
                {
                    if( fillerMapTrie )
                    {
                        TrieSetCell( fillerMapTrie, loadedMapName, 0 );
                    }
                    
                    ArrayPushString( mapArray, loadedMapName );
                    ++mapCount;
                }
            }
        }
        
        close_dir( dir );
    }
    else
    {
        // directory not found, wtf?
        LOGGER( 1, "AMX_ERR_NOTFOUND, %L", LANG_SERVER, "GAL_MAPS_FOLDERMISSING" );
        log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_MAPS_FOLDERMISSING" );
    }
    
    return mapCount;
}

public map_loadNominationList()
{
    LOGGER( 128, "I AM ENTERING ON map_loadNominationList(0)" );
    
    new nomMapFilePath[ MAX_FILE_PATH_LENGHT ];
    get_pcvar_string( cvar_nomMapFilePath, nomMapFilePath, charsmax( nomMapFilePath ) );
    
    LOGGER( 4, "( map_loadNominationList() ) cvar_nomMapFilePath: %s", nomMapFilePath );
    g_nominationMapCount = map_populateList( g_nominationMapsArray, nomMapFilePath, charsmax( nomMapFilePath ) );
}

stock map_loadEmptyCycleList()
{
    LOGGER( 128, "I AM ENTERING ON map_loadEmptyCycleList(0)" );
    
    new emptyCycleFilePath[ MAX_FILE_PATH_LENGHT ];
    get_pcvar_string( cvar_emptyMapFilePath, emptyCycleFilePath, charsmax( emptyCycleFilePath ) );
    
    g_emptyCycleMapsNumber = map_populateList( g_emptyCycleMapsList, emptyCycleFilePath, charsmax( emptyCycleFilePath ) );
    LOGGER( 4, "( map_loadEmptyCycleList ) g_emptyCycleMapsNumber = %d", g_emptyCycleMapsNumber );
}

public map_loadPrefixList()
{
    LOGGER( 128, "I AM ENTERING ON map_loadPrefixList(0)" );
    
    new prefixesFile;
    new prefixesFilePath[ MAX_FILE_PATH_LENGHT ];
    
    formatex( prefixesFilePath, charsmax( prefixesFilePath ), "%s/prefixes.ini", g_configsDirPath );
    prefixesFile = fopen( prefixesFilePath, "rt" );
    
    if( prefixesFile )
    {
        new loadedMapPrefix[ 16 ];
        
        while( !feof( prefixesFile ) )
        {
            fgets( prefixesFile, loadedMapPrefix, charsmax( loadedMapPrefix ) );
            
            if( loadedMapPrefix[ 0 ]
                && !equal( loadedMapPrefix, "//", 2 ) )
            {
                if( g_mapPrefixCount <= MAX_PREFIX_COUNT )
                {
                    trim( loadedMapPrefix );
                    copy( g_mapPrefixes[ g_mapPrefixCount++ ], charsmax( loadedMapPrefix ), loadedMapPrefix );
                }
                else
                {
                    LOGGER( 1, "AMX_ERR_BOUNDS, %L", LANG_SERVER, "GAL_PREFIXES_TOOMANY", MAX_PREFIX_COUNT, prefixesFilePath );
                    log_error( AMX_ERR_BOUNDS, "%L", LANG_SERVER, "GAL_PREFIXES_TOOMANY", MAX_PREFIX_COUNT, prefixesFilePath );
                    
                    break;
                }
            }
        }
        fclose( prefixesFile );
    }
    else
    {
        LOGGER( 1, "AMX_ERR_NOTFOUND, %L", LANG_SERVER, "GAL_PREFIXES_NOTFOUND", prefixesFilePath );
        log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_PREFIXES_NOTFOUND", prefixesFilePath );
    }
    
    return PLUGIN_HANDLED;
}

stock getSurMapNameIndex( mapSurName[] )
{
    LOGGER( 128, "I AM ENTERING ON getSurMapNameIndex(1) | mapSurName: %s", mapSurName );
    
    new mapIndex;
    new map          [ MAX_MAPNAME_LENGHT ];
    new nominationMap[ MAX_MAPNAME_LENGHT ];
    
    for( new prefixIndex = 0; prefixIndex < g_mapPrefixCount; ++prefixIndex )
    {
        formatex( map, charsmax( map ), "%s%s", g_mapPrefixes[ prefixIndex ], mapSurName );
        
        for( mapIndex = 0; mapIndex < g_nominationMapCount; ++mapIndex )
        {
            ArrayGetString( g_nominationMapsArray, mapIndex, nominationMap, charsmax( nominationMap ) );
            
            if( equali( map, nominationMap ) )
            {
                return mapIndex;
            }
        }
    }
    
    return -1;
}

/**
 * Generic say handler to determine if we need to act on what was said.
 */
public cmd_say( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_say(1) | player_id: %s", player_id );
    
    static sentence   [ 70 ];
    static firstWord  [ 32 ];
    static secondWord [ 32 ];
    static thirdWord  [ 2 ];
    
    static prefix_index;
    
    sentence   [ 0 ] = '^0';
    firstWord  [ 0 ] = '^0';
    secondWord [ 0 ] = '^0';
    thirdWord  [ 0 ] = '^0';
    
    read_args( sentence, charsmax( sentence ) );
    remove_quotes( sentence );
    
    parse( sentence,
            firstWord, charsmax( firstWord ),
            secondWord, charsmax( secondWord ),
            thirdWord, charsmax( thirdWord ) );
    
    LOGGER( 4, "( cmd_say ) sentence: %s, firstWord: %s, secondWord: %s, thirdWord: %s", \
                            sentence,     firstWord,     secondWord,     thirdWord );
    
    // if the chat line has more than 2 words, we're not interested at all
    if( thirdWord[ 0 ] == '^0' )
    {
        new mapIndex;
        LOGGER( 4, "( cmd_say ) the thirdWord is empty." );
        
        // if the chat line contains 1 word, it could be a map or a one-word command as
        // "say [rtv|rockthe<anything>vote]"
        if( secondWord[ 0 ] == '^0' )
        {
            LOGGER( 4, "( cmd_say ) the secondWord is empty." );
            
            if( ( g_rtvCommands & RTV_CMD_SHORTHAND
                  && equali( firstWord, "rtv" ) )
                || ( g_rtvCommands & RTV_CMD_DYNAMIC
                     && equali( firstWord, "rockthe", 7 )
                     && equali( firstWord[ strlen( firstWord ) - 4 ], "vote" )
                     && !( g_rtvCommands & RTV_CMD_STANDARD ) ) )
            {
                LOGGER( 4, "( cmd_say ) running vote_rock( player_id ); player_id: %s", player_id );
                
                vote_rock( player_id );
                return PLUGIN_HANDLED;
            }
            else if( get_pcvar_num( cvar_nomPlayerAllowance ) )
            {
                LOGGER( 4, "( cmd_say ) on the 1 word: else if( cvar_nomPlayerAllowance ), \
                        get_pcvar_num( cvar_nomPlayerAllowance ): %d", \
                        get_pcvar_num( cvar_nomPlayerAllowance ) );
                
                if( equali( firstWord, "noms" )
                    || equali( firstWord, "nominations" ) )
                {
                    nomination_list();
                    return PLUGIN_HANDLED;
                }
                else
                {
                    mapIndex = getSurMapNameIndex( firstWord );
                    
                    if( mapIndex >= 0 )
                    {
                        nomination_toggle( player_id, mapIndex );
                        return PLUGIN_HANDLED;
                    }
                    else if( strlen( firstWord ) > 5
                             && equali( firstWord, "nom", 3 )
                             && equali( firstWord[ strlen( firstWord ) - 4 ], "menu" ) )
                    {
                        nomination_menu( player_id );
                        return PLUGIN_HANDLED;
                    }
                    else // if contains a prefix
                    {
                        for( prefix_index = 0; prefix_index < g_mapPrefixCount; prefix_index++ )
                        {
                            LOGGER( 4, "( cmd_say ) firstWord: %s, \
                                    g_mapPrefixes[%d]: %s, \
                                    containi( %s, %s )? %d", \
                                    firstWord, \
                                    prefix_index, g_mapPrefixes[ prefix_index ], \
                                    firstWord, g_mapPrefixes[ prefix_index ], containi( firstWord, g_mapPrefixes[ prefix_index ] ) );
                            
                            if( containi( firstWord, g_mapPrefixes[ prefix_index ] ) > -1 )
                            {
                                nomination_menu( player_id );
                                return PLUGIN_HANDLED;
                            }
                        }
                    }
                    
                    LOGGER( 4, "( cmd_say ) equali(%s, 'nom', 3)? %d, strlen(%s) > 5? %d", \
                                 firstWord, equali( firstWord, "nom", 3 ), \
                                 firstWord, strlen( firstWord ) > 5 );
                }
            }
        }
        else if( get_pcvar_num( cvar_nomPlayerAllowance ) )  // "say <nominate|nom|cancel> <map>"
        {
            if( equali( firstWord, "nominate" )
                || equali( firstWord, "nom" ) )
            {
                nominationAttemptWithNamePart( player_id, secondWord );
                return PLUGIN_HANDLED;
            }
            else if( equali( firstWord, "cancel" ) )
            {
                // bpj -- allow ambiguous cancel in which case a menu of their nominations is shown
                mapIndex = getSurMapNameIndex( secondWord );
                
                if( mapIndex >= 0 )
                {
                    nomination_cancel( player_id, mapIndex );
                    return PLUGIN_HANDLED;
                }
            }
        }
    }
    
    return PLUGIN_CONTINUE;
}

stock buildTheNominationsMenu( player_id )
{
    LOGGER( 128, "I AM ENTERING ON buildTheNominationsMenu(1) | player_id: %d", player_id );
    
    new nominations_menu_name[ 64 ];
    new nomination_cancel_option[ 64 ];
    
    // assume there'll be more than one match ( because we're lazy ) and starting building the match menu
    if( g_generalUsePlayersMenuId[ player_id ] )
    {
        menu_destroy( g_generalUsePlayersMenuId[ player_id ] );
    }
    
    clearMenuMapIndexForPlayers( player_id );
    formatex( nominations_menu_name, charsmax( nominations_menu_name ), "%L", player_id, "GAL_LISTMAPS_TITLE" );
    
    formatex( nomination_cancel_option, charsmax( nomination_cancel_option ), "%L", player_id, "GAL_NOM_CANCEL_OPTION" );
    g_generalUsePlayersMenuId[ player_id ] = menu_create( nominations_menu_name, "nomination_handleMatchChoice" );

    menu_additem( g_generalUsePlayersMenuId[ player_id ], nomination_cancel_option, { 0 }, 0 );
    menu_addblank( g_generalUsePlayersMenuId[ player_id ], 0 );
}

stock nomination_menu( player_id )
{
    LOGGER( 128, "I AM ENTERING ON nomination_menu(1) | player_id: %d", player_id );
    
    // gather all maps that match the nomination
    new mapIndex;
    
    new info          [ 1 ];
    new choice        [ MAX_MAPNAME_LENGHT + 32 ];
    new nominationMap [ MAX_MAPNAME_LENGHT ];
    new disabledReason[ 16 ];
    
    buildTheNominationsMenu( player_id );
    
    for( mapIndex = 0; mapIndex < g_nominationMapCount; mapIndex++ )
    {
        info[ 0 ] = mapIndex;
        ArrayGetString( g_nominationMapsArray, mapIndex, nominationMap, charsmax( nominationMap ) );
        
        // in most cases, the map will be available for selection, so assume that's the case here
        disabledReason[ 0 ] = '^0';
        
        if( nomination_getPlayer( mapIndex ) ) // disable if the map has already been nominated
        {
            formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_NOMINATED" );
        }
        else if( map_isTooRecent( nominationMap ) ) // disable if the map is too recent
        {
            formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_TOORECENT" );
        }
        else if( equali( g_currentMap, nominationMap ) ) // disable if the map is the current map
        {
            formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_CURRENTMAP" );
        }
        
        formatex( choice, charsmax( choice ), "%s %s", nominationMap, disabledReason );
        LOGGER( 0, "( nomination_menu ) choice: %s, info[0]: %d", choice, info[ 0 ] );
        
        menu_additem( g_generalUsePlayersMenuId[ player_id ], choice, info,
                ( disabledReason[ 0 ] == '^0' ? 0 : ( 1 << 26 ) ) );
    }
    
    menu_display( player_id, g_generalUsePlayersMenuId[ player_id ] );
}

// ( playerName[], &phraseIdx, matchingSegment[] )
stock nominationAttemptWithNamePart( player_id, partialNameAttempt[] )
{
    LOGGER( 128, "I AM ENTERING ON nominationAttemptWithNamePart(1) | player_id: %d, partialNameAttempt: %s", player_id, partialNameAttempt );
    
    // gather all maps that match the partialNameAttempt
    new mapIndex;
    
    new matchCnt = 0;
    new matchIdx = -1;
    
    new info          [ 1 ];
    new choice        [ MAX_MAPNAME_LENGHT + 32 ];
    new nominationMap [ MAX_MAPNAME_LENGHT ];
    new disabledReason[ 16 ];
    
    // all map names are stored as lowercase, so normalize the partialNameAttempt
    strtolower( partialNameAttempt );
    buildTheNominationsMenu( player_id );
    
    if( !g_currentMenuMapIndexForPlayers[ player_id ] )
    {
        g_currentMenuMapIndexForPlayers[ player_id ] = ArrayCreate( 1 );
    }
    else
    {
        ArrayClear( g_currentMenuMapIndexForPlayers[ player_id ] );
    }
    
    // Add a dummy value due the first map option to be 'Cancel all your Nominations'.
    ArrayPushCell( g_currentMenuMapIndexForPlayers[ player_id ], 0 );
    
    for( mapIndex = 0; mapIndex < g_nominationMapCount
         && matchCnt <= MAX_NOM_MATCH_COUNT; ++mapIndex )
    {
        ArrayGetString( g_nominationMapsArray, mapIndex, nominationMap, charsmax( nominationMap ) );
        
        if( containi( nominationMap, partialNameAttempt ) > -1 )
        {
            // Store in case this is the only match
            matchIdx = mapIndex;
            
            // Save the map index for the current menu position
            ArrayPushCell( g_currentMenuMapIndexForPlayers[ player_id ], mapIndex );
            
            matchCnt++;
            
            // there may be a much better way of doing this, but I didn't feel like
            // storing the matches and mapIndex's only to loop through them again
            info[ 0 ] = mapIndex;
            
            // in most cases, the map will be available for selection, so assume that's the case here
            disabledReason[ 0 ] = '^0';
            
            if( nomination_getPlayer( mapIndex ) ) // disable if the map has already been nominated
            {
                formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_NOMINATED" );
            }
            else if( map_isTooRecent( nominationMap ) ) // disable if the map is too recent
            {
                formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_TOORECENT" );
            }
            else if( equali( g_currentMap, nominationMap ) ) // disable if the map is the current map
            {
                formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_CURRENTMAP" );
            }
            formatex( choice, charsmax( choice ), "%s %s", nominationMap, disabledReason );
            
            menu_additem( g_generalUsePlayersMenuId[ player_id ], choice, info,
                    ( disabledReason[ 0 ] == '^0' ? 0 : ( 1 << 26 ) ) );
        }
    }
    
    // handle the number of matches
    switch( matchCnt )
    {
        case 0:
        {
            // no matches; pity the poor fool
            color_print( player_id, "^1%L", player_id, "GAL_NOM_FAIL_NOMATCHES", partialNameAttempt );
        }
        case 1:
        {
            // one match?! omg, this is just like awesome
            map_nominate( player_id, matchIdx );
        }
        default:
        {
            // this is kinda sexy; we put up a menu of the matches for them to pick the right one
            if( matchCnt >= MAX_NOM_MATCH_COUNT )
            {
                color_print( player_id, "^1%L", player_id, "GAL_NOM_MATCHES_MAX", MAX_NOM_MATCH_COUNT, MAX_NOM_MATCH_COUNT );
            }
            
            color_print( player_id, "^1%L", player_id, "GAL_NOM_MATCHES", partialNameAttempt );
            menu_display( player_id, g_generalUsePlayersMenuId[ player_id ] );
        }
    }
}

public nomination_handleMatchChoice( player_id, menu, item )
{
    LOGGER( 128, "I AM ENTERING ON nomination_handleMatchChoice(1) | player_id: %d, menu: %d, item: %d", player_id, menu, item );
    
    if( item < 0 )
    {
        clearMenuMapIndexForPlayers( player_id );
        return PLUGIN_CONTINUE;
    }
    
    // Due the first menu option to be 'Cancel all your Nominations'.
    if( item == 0 )
    {
        unnominatedDisconnectedPlayer( player_id );
        clearMenuMapIndexForPlayers( player_id );
        
        return PLUGIN_HANDLED;
    }
    
    // If we are using the nominationAttemptWithNamePart().
    if( g_currentMenuMapIndexForPlayers[ player_id ] )
    {
        item = ArrayGetCell( g_currentMenuMapIndexForPlayers[ player_id ], item );
    }
    else // we are using the nomination_menu()
    {
        // Due the first menu option to be 'Cancel all your Nominations', take one item less 'item - 1'.
        item--;
    }
    
    // debugging menu info tracker
#if defined DEBUG
    new access;
    new callback;
    
    new info[ 1 ];
    LOGGER( 4, "( nomination_handleMatchChoice ) item: %d, player_id: %d, menu: %d, \
            g_currentMenuMapIndexForPlayers[player_id]: %d", \
            item + 1, player_id, menu, g_currentMenuMapIndexForPlayers[ player_id ] );
    
    // Get item info
    menu_item_getinfo( g_generalUsePlayersMenuId[ player_id ], item + 1, access, info, 1, _, _, callback );
    
    LOGGER( 4, "( nomination_handleMatchChoice ) info[0]: %d, access: %d, \
            g_generalUsePlayersMenuId[player_id]: %d", \
            info[ 0 ], access, g_generalUsePlayersMenuId[ player_id ] );
#endif
    
    map_nominate( player_id, item );
    clearMenuMapIndexForPlayers( player_id );
    
    return PLUGIN_HANDLED;
}

stock clearMenuMapIndexForPlayers( player_id )
{
    LOGGER( 128, "I AM ENTERING ON clearMenuMapIndexForPlayers(1) | player_id: %d", player_id );
    
    if( g_currentMenuMapIndexForPlayers[ player_id ] )
    {
        ArrayDestroy( g_currentMenuMapIndexForPlayers[ player_id ] );
    }
}

/**
 * Check if the map has already been nominated.
 * 
 * @return 0 when the map is not nominated, or the player nominator id.
 */
stock nomination_getPlayer( mapIndex )
{
    LOGGER( 128, "I AM ENTERING ON nomination_getPlayer(1) | mapIndex: %d", mapIndex );
    
    new trieKey          [ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new mapNominationData[ MapNominationsType ];
    
    num_to_str( mapIndex, trieKey, charsmax( trieKey ) );
    LOGGER( 4, "( nomination_getPlayer ) trieKey: %s", trieKey );
    
    if( TrieKeyExists( g_nominationMapsTrie, trieKey ) )
    {
        TrieGetArray( g_nominationMapsTrie, trieKey, mapNominationData, sizeof mapNominationData );
        
        return mapNominationData[ MapNominationsPlayerId ];
    }
    
    return 0;
}

/**
 * Gets the nominated map index, given the player id and the nomination index.
 * 
 * @return -1 when there is no nomination, or the map nomination index.
 */
stock getPlayerNominationMapIndex( player_id, nominationIndex )
{
    LOGGER( 128, "I AM ENTERING ON getPlayerNominationMapIndex(2) | player_id: %d, nominationIndex: %d", player_id, nominationIndex );
    
    new trieKey             [ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new playerNominationData[ MAX_NOMINATION_COUNT ];
    
    createPlayerNominationKey( player_id, trieKey, charsmax( trieKey ) );
    
    if( TrieKeyExists( g_playersNominations, trieKey ) )
    {
        TrieGetArray( g_playersNominations, trieKey, playerNominationData, sizeof playerNominationData );
    }
    else
    {
        return -1;
    }
    
    return playerNominationData[ nominationIndex ];
}

/**
 * Changes the player nomination. When there is no nominations, it creates the player entry to the
 * the server nominations tables "g_nominationMapsTrie" and "g_playersNominations".
 * 
 * @param player_id             the nominator player id.
 * @param nominationIndex       @see the updateNominationsReverseSearch's nominationIndex function parameter.
 * @param mapIndex              @see the updateNominationsReverseSearch's mapIndex function parameter.
 */
stock setPlayerNominationMapIndex( player_id, nominationIndex, mapIndex )
{
    LOGGER( 128, "I AM ENTERING ON setPlayerNominationMapIndex(3) | player_id: %d, nominationIndex: %d, mapIndex: %d", player_id, nominationIndex, mapIndex );
    new originalMapIndex;
    
    new trieKey             [ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new playerNominationData[ MAX_NOMINATION_COUNT ];
    
    createPlayerNominationKey( player_id, trieKey, charsmax( trieKey ) );
    
    if( TrieKeyExists( g_playersNominations, trieKey ) )
    {
        TrieGetArray( g_playersNominations, trieKey, playerNominationData, sizeof playerNominationData );
        
        originalMapIndex                        = playerNominationData[ nominationIndex ];
        playerNominationData[ nominationIndex ] = mapIndex;
        
        TrieSetArray( g_playersNominations, trieKey, playerNominationData, sizeof playerNominationData );
    }
    else
    {
        for( new currentNominationIndex = 0;
             currentNominationIndex < MAX_NOMINATION_COUNT; ++currentNominationIndex )
        {
            playerNominationData[ currentNominationIndex ] = -1;
            LOGGER( 4, "( setPlayerNominationMapIndex ) playerNominationData[%d]: %d", \
                    currentNominationIndex, playerNominationData[ currentNominationIndex ] );
        }
        
        playerNominationData[ nominationIndex ] = mapIndex;
        TrieSetArray( g_playersNominations, trieKey, playerNominationData, sizeof playerNominationData );
    }
    
    updateNominationsReverseSearch( player_id, nominationIndex, mapIndex, originalMapIndex );
}

/**
 * Update the reverse search, i.e., to find the nominator player id given the nominated map index.
 * Each map has one, and only one nomination index.
 * 
 * @param player_id             the nominator player game id.
 * @param nominationIndex       the player's personal nominations array index.
 * @param mapIndex              the server's nomination index. Uses -1 to disable the current 
 *                                  player's personal nomination index.
 * @param originalMapIndex      the correct server's nomination index. Do not accept the wild card
 *                                  -1 as the mapIndex parameter just above.
 */
stock updateNominationsReverseSearch( player_id, nominationIndex, mapIndex, originalMapIndex )
{
    LOGGER( 128, "I AM ENTERING ON updateNominationsReverseSearch(4) | player_id: %d, \
            nominationIndex: %d, mapIndex: %d, originalMapIndex: %d",  player_id, \
            nominationIndex,     mapIndex,     originalMapIndex );
    
    new trieKey          [ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new mapNominationData[ MapNominationsType ];
    
    num_to_str( mapIndex, trieKey, charsmax( trieKey ) );
    
    if( mapIndex < 0 )
    {
        num_to_str( originalMapIndex, trieKey, charsmax( trieKey ) );
        TrieDeleteKey( g_nominationMapsTrie, trieKey );
    }
    else
    {
        mapNominationData[ MapNominationsPlayerId ]        = player_id;
        mapNominationData[ MapNominationsNominationIndex ] = nominationIndex;
        
        TrieSetArray( g_nominationMapsTrie, trieKey, mapNominationData, sizeof mapNominationData );
    }
}

stock countPlayerNominations( player_id, &nominationOpenIndex )
{
    LOGGER( 128, "I AM ENTERING ON countPlayerNominations(2) | player_id: %d, nominationOpenIndex: %d", \
                                                               player_id,     nominationOpenIndex );
    new nominationCount;
    
    new trieKey[ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new playerNominationData[ MAX_NOMINATION_COUNT ];
    
    nominationOpenIndex = 0;
    createPlayerNominationKey( player_id, trieKey, charsmax( trieKey ) );
    
    if( TrieKeyExists( g_playersNominations, trieKey ) )
    {
        TrieGetArray( g_playersNominations, trieKey, playerNominationData, sizeof playerNominationData );
        
        for( new nominationIndex = 0; nominationIndex < MAX_NOMINATION_COUNT; ++nominationIndex )
        {
            LOGGER( 4, "( countPlayerNominations ) playerNominationData[%d]: %d", \
                    nominationIndex, playerNominationData[ nominationIndex ] );
            
            if( playerNominationData[ nominationIndex ] >= 0 )
            {
                nominationCount++;
            }
            else
            {
                nominationOpenIndex = nominationCount;
                break;
            }
        }
    }
    else
    {
        return 0;
    }
    
    LOGGER( 4, "( countPlayerNominations ) nominationCount: %d, trieKey: %s, nominationOpenIndex: %d", \
                                           nominationCount,     trieKey,     nominationOpenIndex );
    return nominationCount;
}

stock createPlayerNominationKey( player_id, trieKey[], trieKeyMaxChars )
{
    LOGGER( 128, "I AM ENTERING ON createPlayerNominationKey(3) | player_id: %d, trieKey: %s, \
            trieKeyMaxChars: %d",                                 player_id,     trieKey, \
            trieKeyMaxChars );
    
    new ipSize;
    ipSize = get_user_ip( player_id, trieKey, trieKeyMaxChars );
    
    get_user_authid( player_id, trieKey[ ipSize ], trieKeyMaxChars - ipSize );
    LOGGER( 4, "( createPlayerNominationKey ) player_id: %d, trieKey: %s,", player_id, trieKey );
}

stock nomination_toggle( player_id, mapIndex )
{
    LOGGER( 128, "I AM ENTERING ON nomination_toggle(2) | player_id: %d, mapIndex: %d", player_id, mapIndex );
    new nominatorPlayerId = nomination_getPlayer( mapIndex );
    
    if( nominatorPlayerId == player_id )
    {
        nomination_cancel( player_id, mapIndex );
    }
    else
    {
        map_nominate( player_id, mapIndex, nominatorPlayerId );
    }
}

stock nomination_cancel( player_id, mapIndex )
{
    LOGGER( 128, "I AM ENTERING ON nomination_cancel(2) | player_id: %d, mapIndex: %d", player_id, mapIndex );
    
    // cancellations can only be made if a vote isn't already in progress
    if( g_voteStatus & VOTE_IS_IN_PROGRESS )
    {
        color_print( player_id, "^1%L", player_id, "GAL_CANCEL_FAIL_INPROGRESS" );
        return;
    }
    else if( g_voteStatus & VOTE_IS_OVER ) // and if the outcome of the vote hasn't already been determined
    {
        color_print( player_id, "^1%L", player_id, "GAL_CANCEL_FAIL_VOTEOVER" );
        return;
    }
    
    new trieKey          [ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new mapName          [ MAX_MAPNAME_LENGHT ];
    new mapNominationData[ MapNominationsType ];
    
    num_to_str( mapIndex, trieKey, charsmax( trieKey ) );
    ArrayGetString( g_nominationMapsArray, mapIndex, mapName, charsmax( mapName ) );
    
    // nomination found, then delete it
    if( TrieKeyExists( g_nominationMapsTrie, trieKey ) )
    {
        g_nominationCount--;
        
        TrieGetArray( g_nominationMapsTrie, trieKey, mapNominationData, sizeof mapNominationData );
        setPlayerNominationMapIndex( player_id, mapNominationData[ MapNominationsNominationIndex ], -1 );
        
        nomination_announceCancellation( mapName );
    }
    else
    {
        new nominatorPlayerId = nomination_getPlayer( mapIndex );
        
        if( nominatorPlayerId )
        {
            new player_name[ MAX_PLAYER_NAME_LENGHT ];
            
            GET_USER_NAME( nominatorPlayerId, player_name );
            color_print( player_id, "^1%L", player_id, "GAL_CANCEL_FAIL_SOMEONEELSE",
                    mapName, player_name );
        }
        else
        {
            color_print( player_id, "^1%L", player_id, "GAL_CANCEL_FAIL_WASNOTYOU",
                    mapName );
        }
    }
}

stock map_nominate( player_id, mapIndex, nominatorPlayerId = -1 )
{
    LOGGER( 128, "I AM ENTERING ON map_nominate(3) | player_id: %d, mapIndex: %d, nominatorPlayerId: %d", \
                                                     player_id,     mapIndex,     nominatorPlayerId );
    
    // nominations can only be made if a vote isn't already in progress
    if( g_voteStatus & VOTE_IS_IN_PROGRESS )
    {
        color_print( player_id, "^1%L", player_id, "GAL_NOM_FAIL_INPROGRESS" );
        return;
    }
    else if( g_voteStatus & VOTE_IS_OVER ) // and if the outcome of the vote hasn't already been determined
    {
        color_print( player_id, "^1%L", player_id, "GAL_NOM_FAIL_VOTEOVER" );
        return;
    }
    
    new mapName[ MAX_MAPNAME_LENGHT ];
    
    ArrayGetString( g_nominationMapsArray, mapIndex, mapName, charsmax( mapName ) ); // get the nominated map name
    LOGGER( 4, "( map_nominate ) mapIndex: %d, mapName: %s, ArraySize( g_nominationMapsArray ): %d,", \
            mapIndex, mapName, ArraySize( g_nominationMapsArray ) );
    
    // players can not nominate the current map
    if( equali( g_currentMap, mapName ) )
    {
        color_print( player_id, "^1%L", player_id, "GAL_NOM_FAIL_CURRENTMAP", g_currentMap );
        return;
    }
    
    // players may not be able to nominate recently played maps
    if( map_isTooRecent( mapName ) )
    {
        color_print( player_id, "^1%L", player_id, "GAL_NOM_FAIL_TOORECENT", mapName );
        color_print( player_id, "^1%L", player_id, "GAL_NOM_FAIL_TOORECENT_HLP" );
        
        return;
    }
    
    // check if the map has already been nominated
    if( nominatorPlayerId == -1 )
    {
        nominatorPlayerId = nomination_getPlayer( mapIndex );
    }
    
    // When no one nominated this map, the variable 'nominatorPlayerId' will be 0. Then here we
    // to nominate it.
    if( nominatorPlayerId == 0 )
    {
        new nominationOpenIndex;
        new maxPlayerNominations;
        
        maxPlayerNominations = min( get_pcvar_num( cvar_nomPlayerAllowance ), MAX_NOMINATION_COUNT );
        
        // When max nomination limit is reached, then we must not to allow this nomination.
        if( countPlayerNominations( player_id, nominationOpenIndex ) >= maxPlayerNominations )
        {
            new copiedChars;
            
            new nominatedMapName[ MAX_MAPNAME_LENGHT ];
            new nominatedMaps   [ MAX_COLOR_MESSAGE ];
            
            for( new nominationIndex = 0; nominationIndex < maxPlayerNominations; ++nominationIndex )
            {
                mapIndex = getPlayerNominationMapIndex( player_id, nominationIndex );
                
                ArrayGetString( g_nominationMapsArray, mapIndex, nominatedMapName, charsmax( nominatedMapName ) );
                
                if( copiedChars )
                {
                    copiedChars += copy( nominatedMaps[ copiedChars ],
                            charsmax( nominatedMaps ) - copiedChars, ", " );
                }
                
                copiedChars += copy( nominatedMaps[ copiedChars ],
                        charsmax( nominatedMaps ) - copiedChars, nominatedMapName );
            }
            
            color_print( player_id, "^1%L", player_id, "GAL_NOM_FAIL_TOOMANY", maxPlayerNominations, nominatedMaps );
            color_print( player_id, "^1%L", player_id, "GAL_NOM_FAIL_TOOMANY_HLP" );
        }
        // otherwise, allow the nomination
        else
        {
            g_nominationCount++;
            
            setPlayerNominationMapIndex( player_id, nominationOpenIndex, mapIndex );
            map_announceNomination( player_id, mapName );
            
            color_print( player_id, "^1%L", player_id, "GAL_NOM_GOOD_HLP" );
        }
        
        LOGGER( 4, "( map_nominate ) nominationOpenIndex: %d, mapName: %s", nominationOpenIndex, mapName );
    }
    // If the nominatorPlayerId is equal to the current player_id, the player is trying to nominate
    // the same map again. And it is not allowed.
    else if( nominatorPlayerId == player_id )
    {
        color_print( player_id, "^1%L", player_id, "GAL_NOM_FAIL_ALREADY", mapName );
    }
    // The player nomination is the same as some other player before. And it is not allowed.
    else
    {
        new player_name[ MAX_PLAYER_NAME_LENGHT ];
        GET_USER_NAME( nominatorPlayerId, player_name );
        
        color_print( player_id, "^1%L", player_id, "GAL_NOM_FAIL_SOMEONEELSE", mapName, player_name );
        color_print( player_id, "^1%L", player_id, "GAL_NOM_FAIL_SOMEONEELSE_HLP" );
    }
}

public nomination_list()
{
    LOGGER( 128, "I AM ENTERING ON nomination_list(0)" );
    
    new nominationIndex;
    new mapIndex;
    new nomMapCount;
    new maxPlayerNominations;
    new copiedChars;
    
    new mapsList[ 101 ];
    new mapName[ MAX_MAPNAME_LENGHT ];
    
    maxPlayerNominations = min( get_pcvar_num( cvar_nomPlayerAllowance ), MAX_NOMINATION_COUNT );
    
    for( new player_id = 1; player_id < MAX_PLAYERS_COUNT; ++player_id )
    {
        LOGGER( 4, "( nomination_list ) player_id: %d,", player_id, MAX_PLAYERS_COUNT );
        
        for( nominationIndex = 0; nominationIndex < maxPlayerNominations; ++nominationIndex )
        {
            mapIndex = getPlayerNominationMapIndex( player_id, nominationIndex );
            
            if( mapIndex >= 0 )
            {
                ArrayGetString( g_nominationMapsArray, mapIndex, mapName, charsmax( mapName ) );
                
                if( copiedChars )
                {
                    copiedChars += copy( mapsList[ copiedChars ], charsmax( mapsList ) - copiedChars, ", " );
                }
                copiedChars += copy( mapsList[ copiedChars ], charsmax( mapsList ) - copiedChars, mapName );
                
                if( ++nomMapCount == 4 )     // list 4 maps per chat line
                {
                    color_print( 0, "^1%L: %s", LANG_PLAYER, "GAL_NOMINATIONS", mapsList );
                    
                    nomMapCount   = 0;
                    mapsList[ 0 ] = '^0';
                }
            }
        }
    }
    
    if( mapsList[ 0 ] )
    {
        color_print( 0, "^1%L: %s", LANG_PLAYER, "GAL_NOMINATIONS", mapsList );
    }
    else
    {
        color_print( 0, "^1%L: %L", LANG_PLAYER, "GAL_NOMINATIONS", LANG_PLAYER, "NONE" );
    }
}

stock vote_addNominations( blockedFillerMaps[][], blockedFillerMapsMaxChars = 0 )
{
    LOGGER( 128, "I AM ENTERING ON vote_addNominations(2) | blockedFillerMapsMaxChars: %d", blockedFillerMapsMaxChars );
    LOGGER( 4, "" );
    LOGGER( 4, "   [NOMINATIONS ( %i )]", g_nominationCount );
    
    new      blockedCount;
    new bool:isFillersMapUsingMinplayers;
    
    if( g_nominationCount )
    {
        new player_id;
        new mapIndex;
        new nominationIndex;
        
        new      mapName[ MAX_MAPNAME_LENGHT ];
        new Trie:blackFillerMapTrie;
        
        if( IS_NOMINATION_MININUM_PLAYERS_CONTROL_ENABLED()
            && blockedFillerMapsMaxChars )
        {
            new mapFilerFilePath[ MAX_FILE_PATH_LENGHT ];
            get_pcvar_string( cvar_voteMinPlayersMapFilePath, mapFilerFilePath, charsmax( mapFilerFilePath ) );
            
            // '*' is and invalid blacklist for voting, because it would block all server maps.
            if( equal( mapFilerFilePath, "*" ) )
            {
                LOGGER( 1, "AMX_ERR_NOTFOUND, %L", LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilerFilePath );
                log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilerFilePath );
            }
            else
            {
                blackFillerMapTrie          = TrieCreate();
                isFillersMapUsingMinplayers = true;
                
                // This call is only to load the blackFillerMapTrie, the g_fillerMaps is ignored.
                map_populateList( g_fillerMaps, mapFilerFilePath, charsmax( mapFilerFilePath ), blackFillerMapTrie );
            }
        }
        
        // set how many total nominations we can use in this vote
        new maxNominations    = get_pcvar_num( cvar_nomQtyUsed );
        new slotsAvailable    = g_maxVotingChoices - g_totalVoteOptions;
        new voteNominationMax = ( maxNominations ) ? min( maxNominations, slotsAvailable ) : slotsAvailable;
        
        // set how many total nominations each player is allowed
        new maxPlayerNominations = min( get_pcvar_num( cvar_nomPlayerAllowance ), MAX_NOMINATION_COUNT );

    #if defined DEBUG
        new nominator_id;
        new playerName[ MAX_PLAYER_NAME_LENGHT ];
        
        for( nominationIndex = 0; nominationIndex < maxPlayerNominations; ++nominationIndex )
        {
            LOGGER( 4, "( vote_addNominations ) nominationIndex: %d, maxPlayerNominations: %d", \
                    nominationIndex, maxPlayerNominations );
            
            for( player_id = 1; player_id < MAX_PLAYERS_COUNT; ++player_id )
            {
                mapIndex = getPlayerNominationMapIndex( player_id, nominationIndex );
                
                if( mapIndex >= 0 )
                {
                    ArrayGetString( g_nominationMapsArray, mapIndex, mapName, charsmax( mapName ) );
                    
                    nominator_id = nomination_getPlayer( mapIndex );
                    GET_USER_NAME( nominator_id, playerName );
                    
                    LOGGER( 4, "      %-32s %s", mapName, playerName );
                }
            }
        }
        LOGGER( 4, "" );
    #endif
        
        // add as many nominations as we can [TODO: develop a better method of determining which
        // nominations make the cut; either FIFO or random].
        for( nominationIndex = 0; nominationIndex < maxPlayerNominations; ++nominationIndex )
        {
            LOGGER( 4, "( vote_addNominations ) nominationIndex: %d, maxPlayerNominations: %d", \
                    nominationIndex, maxPlayerNominations );
            
            for( player_id = 1; player_id < MAX_PLAYERS_COUNT; ++player_id )
            {
                mapIndex = getPlayerNominationMapIndex( player_id, nominationIndex );
                
                if( mapIndex >= 0 )
                {
                    ArrayGetString( g_nominationMapsArray, mapIndex, mapName, charsmax( mapName ) );
                    
                    if( isFillersMapUsingMinplayers
                        && !TrieKeyExists( blackFillerMapTrie, mapName ) )
                    {
                        LOGGER( 8, "    The map: %s, was blocked by the minimum players map setting.", mapName );
                        
                        if( blockedCount < MAX_NOMINATION_COUNT )
                        {
                            copy( blockedFillerMaps[ blockedCount ], blockedFillerMapsMaxChars, mapName );
                        }
                        
                        blockedCount++;
                        continue;
                    }
                    
                    copy( g_votingMapNames[ g_totalVoteOptions++ ], charsmax( g_votingMapNames[] ), mapName );
                    
                    if( g_totalVoteOptions == voteNominationMax )
                    {
                        break;
                    }
                }
            
            } // end player's nominations looking
            
            if( g_totalVoteOptions == voteNominationMax )
            {
                break;
            }
        
        } // end nomination's players looking
        
        if( blackFillerMapTrie )
        {
            TrieDestroy( blackFillerMapTrie );
        }
    
    } // end if nominations
    
    return blockedCount;
}

stock loadMapGroupsFeature( mapsPerGroup[], fillersFilePaths[][], fillersFilePathsMaxChars )
{
    LOGGER( 128, "I AM ENTERING ON loadMapGroupsFeature(3) | fillersFilePathsMaxChars: %d", fillersFilePathsMaxChars );
    
    new groupCount;
    new mapFilerFilePath[ MAX_FILE_PATH_LENGHT ];
    
    if( get_realplayersnum() < get_pcvar_num( cvar_voteMinPlayers ) )
    {
        get_pcvar_string( cvar_voteMinPlayersMapFilePath, mapFilerFilePath, charsmax( mapFilerFilePath ) );
    }
    else
    {
        get_pcvar_string( cvar_voteMapFilePath, mapFilerFilePath, charsmax( mapFilerFilePath ) );
    }
    
    if( !equal( mapFilerFilePath[ 0 ], "*" )
        && !equal( mapFilerFilePath[ 0 ], "#" ) )
    {
        // determine what kind of file it's being used as
        new mapFilerFile = fopen( mapFilerFilePath, "rt" );
        
        if( mapFilerFile )
        {
            new currentReadedLine[ 16 ];
            
            fgets( mapFilerFile, currentReadedLine, charsmax( currentReadedLine ) );
            trim( currentReadedLine );
            
            if( equali( currentReadedLine, "[groups]" ) )
            {
                LOGGER( 8, "" );
                LOGGER( 8, "this is a [groups] mapFilerFile" );
                
                // read the filler mapFilerFile to determine how many groups there are ( max of MAX_MAPS_IN_VOTE )
                while( !feof( mapFilerFile ) )
                {
                    fgets( mapFilerFile, currentReadedLine, charsmax( currentReadedLine ) );
                    trim( currentReadedLine );
                    
                    LOGGER( 8, "currentReadedLine: %s   isdigit: %i   groupCount: %i  ", \
                            currentReadedLine, isdigit( currentReadedLine[ 0 ] ), groupCount );
                    
                    if( isdigit( currentReadedLine[ 0 ] ) )
                    {
                        if( groupCount < MAX_MAPS_IN_VOTE )
                        {
                            mapsPerGroup[ groupCount ] = str_to_num( currentReadedLine );
                            formatex( fillersFilePaths[ groupCount ], fillersFilePathsMaxChars, \
                                    "%s/%i.ini", g_configsDirPath, groupCount );
                            
                            LOGGER( 8, "fillersFilePaths: %s", fillersFilePaths[ groupCount ] );
                            groupCount++;
                        }
                        else
                        {
                            LOGGER( 1, "AMX_ERR_BOUNDS, %L", LANG_SERVER, "GAL_GRP_FAIL_TOOMANY", mapFilerFilePath );
                            log_error( AMX_ERR_BOUNDS, "%L", LANG_SERVER, "GAL_GRP_FAIL_TOOMANY", mapFilerFilePath );
                            
                            break;
                        }
                    }
                }
                
                if( groupCount == 0 )
                {
                    fclose( mapFilerFile );
                    
                    LOGGER( 1, "AMX_ERR_GENERAL, %L", LANG_SERVER, "GAL_GRP_FAIL_NOCOUNTS", mapFilerFilePath );
                    log_error( AMX_ERR_GENERAL, "%L", LANG_SERVER, "GAL_GRP_FAIL_NOCOUNTS", mapFilerFilePath );
                    
                    return groupCount;
                }
            }
            else
            {
                // we presume it's a listing of maps, ala mapcycle.txt
                copy( fillersFilePaths[ 0 ], fillersFilePathsMaxChars, mapFilerFilePath );
                
                mapsPerGroup[ 0 ] = MAX_MAPS_IN_VOTE;
                groupCount        = 1;
            }
        }
        else
        {
            LOGGER( 1, "AMX_ERR_NOTFOUND, %L", LANG_SERVER, "GAL_FILLER_NOTFOUND", mapFilerFilePath );
            log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_FILLER_NOTFOUND", mapFilerFilePath );
        }
        
        fclose( mapFilerFile );
    }
    else // we'll be loading all maps in the /maps folder or the current mapcycle file
    {
        mapsPerGroup[ 0 ] = MAX_MAPS_IN_VOTE;
        groupCount        = 1;
        
        // the options '*' and '#' will be handled by 'map_populateList()' later.
        copy( fillersFilePaths[ 0 ], fillersFilePathsMaxChars, mapFilerFilePath );
    }
    
    LOGGER( 4, "( vote_addFiller ) MapsGroups Loaded, mapFilerFilePath: %s", mapFilerFilePath );
    LOGGER( 4, "" );
    LOGGER( 4, "" );
    
    return groupCount;
}

stock processLoadedMapsFile( mapsPerGroup[], groupCount, blockedCount,
                             blockedFillerMaps[][], blockedFillerMapsMaxChars,
                             fillersFilePaths[][], fillersFilePathsMaxChars )
{
    LOGGER( 128, "I AM ENTERING ON processLoadedMapsFile(7) | groupCount: %d, blockedCount: %d", \
                                                              groupCount,     blockedCount );
    
    new mapIndex;
    new choice_index;
    new filersMapCount;
    new unsuccessfulCount;
    new allowedFilersCount;
    new isWhitelistEnabled;
    
    new Trie:   blackListTrie;
    new mapName [ MAX_MAPNAME_LENGHT ];
    
    /**
     * This variable is to avoid double blocking which lead to the algorithm corruption and errors.
     */
    new Trie:blockedFillerMapsTrie;
    
    isWhitelistEnabled = IS_WHITELIST_ENABLED();
    
    if( blockedFillerMapsMaxChars )
    {
        blockedFillerMapsTrie = TrieCreate();
    }
    
    if( isWhitelistEnabled )
    {
        blackListTrie = TrieCreate();
        
        loadCurrentBlackList( blackListTrie );
    }
    
    // fill remaining slots with random maps from each filler file, as much as possible
    for( new groupIndex = 0; groupIndex < groupCount; ++groupIndex )
    {
        filersMapCount = map_populateList( g_fillerMaps, fillersFilePaths[ groupIndex ], fillersFilePathsMaxChars );
        
        LOGGER( 8, "[%i] groupCount:%i      filersMapCount: %i   g_totalVoteOptions: %i   \
                g_maxVotingChoices: %i", \
                groupIndex, groupCount,     filersMapCount,      g_totalVoteOptions, \
                g_maxVotingChoices );
        LOGGER( 8, "    fillersFilePaths[%i]: %s", groupIndex, fillersFilePaths[ groupIndex ] );
        LOGGER( 8, "" );
        
        if( g_totalVoteOptions < g_maxVotingChoices
            && filersMapCount )
        {
            allowedFilersCount = 
                    min( min( mapsPerGroup[ groupIndex ], g_maxVotingChoices - g_totalVoteOptions ),
                    filersMapCount );
            
            LOGGER( 8, "[%i] allowedFilersCount: %i   mapsPerGroup[%i]: %i   MaxCount: %i", \
                    groupIndex, allowedFilersCount, groupIndex, mapsPerGroup[ groupIndex ], \
                    g_maxVotingChoices - g_totalVoteOptions );
            
            for( choice_index = 0; choice_index < allowedFilersCount; ++choice_index )
            {
                keepSearching:
                
                unsuccessfulCount = 0;
                mapIndex          = random_num( 0, filersMapCount - 1 );
                
                ArrayGetString( g_fillerMaps, mapIndex, mapName, charsmax( mapName ) );
                
                LOGGER( 8, "  ( in ) [%i] choice_index: %i   allowedFilersCount: %i   mapIndex: %i   mapName: %s", \
                        groupIndex, choice_index, allowedFilersCount, mapIndex, mapName );
                
                while( ( map_isInMenu( mapName )
                         || equali( g_currentMap, mapName )
                         || map_isTooRecent( mapName )
                         || isPrefixInMenu( mapName )
                         || ( blockedFillerMapsMaxChars
                              && TrieKeyExists( blockedFillerMapsTrie, mapName ) ) )
                       && unsuccessfulCount < allowedFilersCount )
                {
                    LOGGER( 8, "    LOADING a new MAP! map_isInMenu: %d, mapName %s \
                            is the current map? %d, map_isTooRecent: %d,      \
                            isPrefixInMenu: %d, TrieKeyExists( blockedFillerMapsTrie, mapName ): %d", \
                            map_isInMenu( mapName ), mapName, \
                            equali( g_currentMap, mapName ), map_isTooRecent( mapName ), \
                            isPrefixInMenu( mapName ), \
                            ( blockedFillerMapsMaxChars ? TrieKeyExists( blockedFillerMapsTrie, mapName ) : false ) );
                    
                    unsuccessfulCount++;
                    
                    if( ++mapIndex == filersMapCount )
                    {
                        mapIndex = 0;
                    }
                    
                    ArrayGetString( g_fillerMaps, mapIndex, mapName, charsmax( mapName ) );
                    
                    LOGGER( 8, "    LOADED a new MAP! map_isInMenu: %d, mapName %s \
                            is the current map? %d, map_isTooRecent: %d,      \
                            isPrefixInMenu: %d, TrieKeyExists( blockedFillerMapsTrie, mapName ): %d", \
                            map_isInMenu( mapName ), mapName, \
                            equali( g_currentMap, mapName ), map_isTooRecent( mapName ), \
                            isPrefixInMenu( mapName ), \
                            ( blockedFillerMapsMaxChars ? TrieKeyExists( blockedFillerMapsTrie, mapName ) : false ) );
                }
                
                if( unsuccessfulCount >= allowedFilersCount )
                {
                    LOGGER( 8, "    unsuccessfulCount: %i  filersMapCount: %i \
                            There aren't enough maps in this filler file to continue adding anymore.", \
                                    unsuccessfulCount,     filersMapCount );
                    
                    break;
                }
                
                if( isWhitelistEnabled
                    && TrieKeyExists( blackListTrie, mapName ) )
                {
                    LOGGER( 8, "    Trying to block: %s, by the whitelist map setting.", mapName );
                    
                    if( !TrieKeyExists( blockedFillerMapsTrie, mapName ) )
                    {
                        LOGGER( 8, "    The map: %s, was blocked by the whitelist map setting.", mapName );
                        
                        if( blockedCount < MAX_NOMINATION_COUNT )
                        {
                            copy( blockedFillerMaps[ blockedCount ], blockedFillerMapsMaxChars, mapName );
                        }
                        
                        TrieSetCell( blockedFillerMapsTrie, mapName, 0 );
                        blockedCount++;
                    }
                    
                    goto keepSearching;
                }
                
                copy( g_votingMapNames[ g_totalVoteOptions ], charsmax( g_votingMapNames[] ), mapName );
                
                g_totalVoteOptions++;
                
                LOGGER( 8, "  ( out ) groupIndex: %i  map: %s, unsuccessfulCount: %i, filersMapCount: %i, g_totalVoteOptions: %i", \
                        groupIndex, mapName, unsuccessfulCount, filersMapCount, g_totalVoteOptions );
            
            } // end 'for choice_index < allowedFilersCount'
        
        } // end 'if g_totalVoteOptions < g_maxVotingChoices'
    
    } // end 'for groupIndex < groupCount'
    
    if( blackListTrie )
    {
        TrieDestroy( blackListTrie );
    }
    
    if( blockedFillerMapsTrie )
    {
        TrieDestroy( blockedFillerMapsTrie );
    }
    
    return blockedCount;
}

stock vote_addFiller( blockedFillerMaps[][], blockedFillerMapsMaxChars = 0, blockedCount = 0 )
{
    LOGGER( 128, "I AM ENTERING ON vote_addFiller(3) | blockedFillerMapsMaxChars: %d, blockedCount: %d", \
                                                       blockedFillerMapsMaxChars,     blockedCount );
    
    if( g_totalVoteOptions >= g_maxVotingChoices )
    {
        return;
    }
    
    new groupCount;
    new mapsPerGroup     [ MAX_MAPS_IN_VOTE ];
    new fillersFilePaths [ MAX_MAPS_IN_VOTE ][ MAX_FILE_PATH_LENGHT ];
    
    groupCount   = loadMapGroupsFeature( mapsPerGroup, fillersFilePaths, charsmax( fillersFilePaths[] ) );
    blockedCount = processLoadedMapsFile( mapsPerGroup,
            groupCount, blockedCount,
            blockedFillerMaps, blockedFillerMapsMaxChars,
            fillersFilePaths, charsmax( fillersFilePaths[] ) );
    
    // If there is/are blocked maps, to announce them to everybody.
    if( blockedCount )
    {
        new copiedChars;
        new mapListToPrint[ MAX_COLOR_MESSAGE ];
        
        color_print( 0, "^1%L", LANG_PLAYER, "GAL_FILLER_BLOCKED" );
        
        for( new currentIndex = 0; currentIndex < blockedCount; ++currentIndex )
        {
            copiedChars += formatex( mapListToPrint[ copiedChars ],
                    charsmax( mapListToPrint ) - copiedChars, "^1, ^4%s",
                    blockedFillerMaps[ currentIndex ] );
        }
        color_print( 0, "^1%L^1.", LANG_PLAYER, "GAL_MATCHING", mapListToPrint[ 3 ] );
        
        LOGGER( 8, "( vote_addFiller ) blockedFillerMaps[0]: %s, blockedCount: %d, copiedChars: %d, mapListToPrint: %s", \
                blockedFillerMaps[ 0 ], blockedCount, copiedChars, mapListToPrint[ 3 ] );
    }

} // end 'vote_addFiller()'

stock loadCurrentBlackList( Trie:blackListTrie )
{
    LOGGER( 128, "I AM ENTERING ON loadCurrentBlackList(1) | Trie:blackListTrie: %d", blackListTrie );
    
    new startHour;
    new endHour;
    new bool:isToSkipThisGroup;
    
    new currentHourString [ 8 ];
    new currentLine       [ MAX_MAPNAME_LENGHT ];
    new startHourString   [ MAX_MAPNAME_LENGHT / 2 ];
    new endHourString     [ MAX_MAPNAME_LENGHT / 2 ];
    new whiteListFilePath [ MAX_FILE_PATH_LENGHT ];
    
    get_time( "%H", currentHourString, charsmax( currentHourString ) );
    get_pcvar_string( cvar_voteWhiteListMapFilePath, whiteListFilePath, charsmax( whiteListFilePath ) );
    
    new currentHour   = str_to_num( currentHourString );
    new whiteListFile = fopen( whiteListFilePath, "rt" );
    
    LOGGER( 8, "( loadCurrentBlackList ) currentHour: %d, currentHourString: %s", currentHour, currentHourString );

#if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST
    if( g_test_current_time )
    {
        currentHour = g_test_current_time;
    }
#endif
    
    while( !feof( whiteListFile ) )
    {
        fgets( whiteListFile, currentLine, charsmax( currentLine ) );
        trim( currentLine );
        
        // skip commentaries while reading file
        if( currentLine[ 0 ] == '^0'
            || currentLine[ 0 ] == ';'
            || ( currentLine[ 0 ] == '/'
                 && currentLine[ 1 ] == '/' ) )
        {
            continue;
        }
        
        if( currentLine[ 0 ] == '['
            && isdigit( currentLine[ 1 ] ) )
        {
            isToSkipThisGroup = false;
            
            // remove line delimiters [ and ]
            replace_all( currentLine, charsmax( currentLine ), "[", "" );
            replace_all( currentLine, charsmax( currentLine ), "]", "" );
            
            LOGGER( 8, "( loadCurrentBlackList ) " );
            LOGGER( 8, "( loadCurrentBlackList ) currentLine: %s (currentHour: %d)", currentLine, currentHour );
            
            // broke the current line
            strtok( currentLine,
                    startHourString, charsmax( startHourString ),
                    endHourString, charsmax( endHourString ),
                    '-', 0 );
            
            startHour = str_to_num( startHourString );
            endHour   = str_to_num( endHourString );
            
            if( startHour == endHour
                || 0 > startHour > 24
                || 0 > endHour > 24
                || ( startHour == 24
                     && endHour == 0 )
                || ( startHour == 0
                     && endHour == 24 ) )
            {
                isToSkipThisGroup = true;
            }
            else if( startHour > endHour )
            {
                if( startHour >= currentHour > endHour )
                {
                    isToSkipThisGroup = true;
                }
                else
                {
                    isToSkipThisGroup = false;
                }
            }
            else // if( startHour < endHour )
            {
                if( startHour <= currentHour < endHour )
                {
                    isToSkipThisGroup = true;
                }
                else
                {
                    isToSkipThisGroup = false;
                }
            }
            
            LOGGER( 8, "( loadCurrentBlackList ) startHour > endHour: %d", startHour > endHour );
            LOGGER( 8, "( loadCurrentBlackList ) startHour >= currentHour > endHour: %d", \
                    startHour >= currentHour > endHour );
            
            LOGGER( 8, "( loadCurrentBlackList ) startHour < endHour: %d", startHour < endHour );
            LOGGER( 8, "( loadCurrentBlackList ) startHour <= currentHour < endHour: %d, \
                    isToSkipThisGroup: %d", startHour <= currentHour < endHour, isToSkipThisGroup );
            
            goto proceed;
        }
        else if( isToSkipThisGroup )
        {
            proceed:
            continue;
        }
        else
        {
            TrieSetCell( blackListTrie, currentLine, 0 );
        }
    }
    
    fclose( whiteListFile );
}

stock loadNormalVoteChoices()
{
    LOGGER( 128, "I AM ENTERING ON loadNormalVoteChoices(0)" );
    
    if( IS_NOMINATION_MININUM_PLAYERS_CONTROL_ENABLED()
        || IS_WHITELIST_ENABLED() )
    {
        new blockedCount;
        new blockedFillerMaps[ MAX_NOMINATION_COUNT ][ MAX_MAPNAME_LENGHT ];
        
        blockedCount = vote_addNominations( blockedFillerMaps, charsmax( blockedFillerMaps[] ) );
        
        LOGGER( 8, "( loadNormalVoteChoices ) blockedFillerMaps[0]: %s, \
                charsmax( blockedFillerMaps[] ): %d, blockedCount: %d", \
                blockedFillerMaps[ 0 ], charsmax( blockedFillerMaps[] ), blockedCount );
        
        vote_addFiller( blockedFillerMaps, charsmax( blockedFillerMaps[] ), blockedCount );
    }
    else
    {
        new dummyArray[][] = { { 0 } };
        
        vote_addNominations( dummyArray );
        vote_addFiller( dummyArray );
    }
    
    g_voteDuration = get_pcvar_num( cvar_voteDuration );
    
    LOGGER( 4, "" );
    LOGGER( 4, "( loadNormalVoteChoices ) g_totalVoteOptions: %d", g_totalVoteOptions );
}

stock approveTheVotingStart( bool:is_forced_voting )
{
    LOGGER( 128, "I AM ENTERING ON approveTheVotingStart(1) | is_forced_voting: %d", is_forced_voting );
    
    if( get_realplayersnum() == 0
        || ( g_voteStatus & VOTE_IS_IN_PROGRESS
             && !( g_voteStatus & VOTE_IS_RUNOFF ) )
        || ( !is_forced_voting
             && g_voteStatus & VOTE_IS_OVER ) )
    {
        LOGGER( 1, "    ( approveTheVotingStart ) g_voteStatus: %d, \
                g_voteStatus & VOTE_IS_OVER: %d, is_forced_voting: %d, \
                get_realplayersnum(): %d", \
                g_voteStatus, \
                g_voteStatus & VOTE_IS_OVER != 0, is_forced_voting, \
                get_realplayersnum() );
    
    #if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST
        // stop the compiler warning 204: symbol is assigned a value that is never used
        get_pcvar_num( cvar_isEmptyCycleServerChange );
        
        if( !g_areTheUnitTestsRunning )
        {
            LOGGER( 1, "    Returning false on if( !g_areTheUnitTestsRunning )" );
            return false;
        }
    #else
        
        if( get_realplayersnum() == 0 )
        {
            if( get_pcvar_num( cvar_isEmptyCycleServerChange ) )
            {
                startEmptyCycleSystem();
            }
            
            if( g_voteStatus & VOTE_IS_IN_PROGRESS )
            {
                cancelVoting();
            }
        }
        
        LOGGER( 1, "    Returning false on if( ... ( g_voteStatus & VOTE_IS_IN_PROGRESS ... ) ... )" );
        return false;
    #endif
    }
    
    if( is_forced_voting
        && g_voteStatus & VOTE_IS_OVER )
    {
        new bool:roundEndStatus[ 4 ];
        
        saveRoundEnding( roundEndStatus );
        cancelVoting();
        
        restoreRoundEnding( roundEndStatus );
        restoreOriginalServerMaxSpeed();
    }
    
    // the rounds start delay task could be running
    remove_task( TASKID_START_VOTING_BY_TIMER );
    
    if( remove_task( TASKID_DELETE_USERS_MENUS ) )
    {
        vote_resetStats();
    }
    
    return true;
}

stock loadRunOffVoteChoices()
{
    LOGGER( 128, "I AM ENTERING ON loadRunOffVoteChoices(0)" );
    new runoffChoice[ 2 ][ MAX_MAPNAME_LENGHT ];
    
    g_totalVoteOptions = g_totalVoteOptionsTemp;
    g_voteDuration     = get_pcvar_num( cvar_runoffDuration );
    
    // load runoff choices
    copy( runoffChoice[ 0 ], charsmax( runoffChoice[] ), g_votingMapNames[ g_arrayOfRunOffChoices[ 0 ] ] );
    copy( runoffChoice[ 1 ], charsmax( runoffChoice[] ), g_votingMapNames[ g_arrayOfRunOffChoices[ 1 ] ] );
    
    copy( g_votingMapNames[ 0 ], charsmax( g_votingMapNames[] ), runoffChoice[ 0 ] );
    copy( g_votingMapNames[ 1 ], charsmax( g_votingMapNames[] ), runoffChoice[ 1 ] );
    
    LOGGER( 16, "( loadRunOffVoteChoices ) map1: %s, map2: %s, g_totalVoteOptions: %d", \
            g_votingMapNames[ 0 ], g_votingMapNames[ 1 ], g_totalVoteOptions );
}

stock configureVotingStart( bool:is_forced_voting )
{
    LOGGER( 128, "I AM ENTERING ON configureVotingStart(1) | is_forced_voting: %d", is_forced_voting );
    
    // update cached data for the new voting.
    cacheCvarsValues();
    
    // make it known that a vote is in progress
    g_voteStatus |= VOTE_IS_IN_PROGRESS;
    
    // Set the voting status to forced
    if( is_forced_voting )
    {
        g_voteStatus |= VOTE_IS_FORCED;
    }
    
    // Max rounds vote map does not have a max rounds extension limit as mp_timelimit
    if( g_isVotingByRounds )
    {
        g_isMapExtensionAllowed = true;
    }
    else
    {
        g_isMapExtensionAllowed =
            get_pcvar_float( cvar_mp_timelimit ) < get_pcvar_float( cvar_maxMapExtendTime );
    }
    
    // configure the end voting type
    g_isGameFinalVoting = ( ( g_isVotingByRounds
                              || g_isVotingByTimer )
                            && !is_forced_voting );
    
    // stop RTV reminders
    remove_task( TASKID_REMINDER );
}

stock vote_startDirector( bool:is_forced_voting )
{
    LOGGER( 128, "I AM ENTERING ON vote_startDirector(1) | is_forced_voting: %d", is_forced_voting );
    
    if( !approveTheVotingStart( is_forced_voting ) )
    {
        return;
    }
    
    if( g_voteStatus & VOTE_IS_RUNOFF )
    {
        // to load runoff vote choices
        loadRunOffVoteChoices();
    }
    else
    {
        // to prepare the initial voting state
        configureVotingStart( is_forced_voting );
        
        // to load vote choices
        loadNormalVoteChoices();
    }
    
    if( g_totalVoteOptions )
    {
        initializeTheVoteDisplay();
    }
    else
    {
        // Vote creation failed; no maps found.
        color_print( 0, "^1%L", LANG_PLAYER, "GAL_VOTE_NOMAPS" );
    }
    
    LOGGER( 4, "   [PLAYER CHOICES]" );
    LOGGER( 4, "" );
    LOGGER( 4, "    ( vote_startDirector|out ) g_isTimeToRestart: %d, \
            g_isTimeToChangeLevel: %d, g_voteStatus & VOTE_IS_FORCED: %d", \
                                               g_isTimeToRestart, \
            g_isTimeToChangeLevel,     g_voteStatus & VOTE_IS_FORCED != 0 );
    LOGGER( 4, "" );
}

stock initializeTheVoteDisplay()
{
    LOGGER( 128, "I AM ENTERING ON initializeTheVoteDisplay(0)" );
    
    new       player_id;
    new       playersCount;
    new       players            [ MAX_PLAYERS ];
    new Float:handleChoicesDelay;
    
    // clear all nominations
    nomination_clearAll();
    
    // alphabetize the maps
    SortCustom2D( g_votingMapNames, g_totalVoteOptions, "sort_stringsi" );
    
    // print the voting map options
#if defined DEBUG
    for( new dbgChoice = 0; dbgChoice < g_totalVoteOptions; dbgChoice++ )
    {
        LOGGER( 4, "      %i. %s", dbgChoice + 1, g_votingMapNames[ dbgChoice ] );
    }
#endif
    
    // force a right vote duration for the Unit Tests run
#if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST
    g_voteDuration = 5;
#endif

    // to create fake votes when needed
#if DEBUG_LEVEL & DEBUG_LEVEL_FAKE_VOTES
    set_task( 2.0, "create_fakeVotes", TASKID_DBG_FAKEVOTES );
#endif
    
    // skip bots and hltv
    get_players( players, playersCount, "ch" );
    
    // mark the players who are in this vote for use later
    for( new playerIndex = 0; playerIndex < playersCount; ++playerIndex )
    {
        player_id = players[ playerIndex ];
        
        if( g_isPlayerParticipating[ player_id ] )
        {
            g_isPlayerVoted[ player_id ] = false;
        }
    }
    
    // adjust the choices delay for the Unit Tests run or normal work flow
#if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST
    handleChoicesDelay = 0.1;
#else
    
    // set_task 1.0 + pendingVoteCountdown 1.0
    handleChoicesDelay = 7.0 + 1.0 + 1.0;
    
    // make perfunctory announcement: "get ready to choose a map"
    if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_GETREADYTOCHOOSE ) )
    {
        client_cmd( 0, "spk ^"get red( e80 ) ninety( s45 ) to check( e20 ) \
                use bay( s18 ) mass( e42 ) cap( s50 )^"" );
    }
    
    // announce the pending vote countdown from 7 to 1
    g_pendingVoteCountdown = 7;
    set_task( 1.0, "pendingVoteCountdown", TASKID_PENDING_VOTE_COUNTDOWN, _, _, "a", 7 );
#endif
    
    // display the map choices, 1 second from now
    set_task( handleChoicesDelay, "vote_handleDisplay", TASKID_VOTE_HANDLEDISPLAY );
}

public pendingVoteCountdown()
{
    LOGGER( 128, "I AM ENTERING ON pendingVoteCountdown(0)" );
    
    if( get_pcvar_num( cvar_isToAskForEndOfTheMapVote )
        && !( g_voteStatus & VOTE_IS_RUNOFF ) )
    {
        displayEndOfTheMapVoteMenu( 0 );
    }
    
    // visual countdown
    set_hudmessage( 0, 222, 50, -1.0, 0.13, 0, 1.0, 0.94, 0.0, 0.0, -1 );
    show_hudmessage( 0, "%L", LANG_PLAYER, "GAL_VOTE_COUNTDOWN", g_pendingVoteCountdown );
    
    // audio countdown
    if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_COUNTDOWN ) )
    {
        new word[ 6 ];
        num_to_word( g_pendingVoteCountdown, word, 5 );
        
        client_cmd( 0, "spk ^"fvox/%s^"", word );
    }
    
    // decrement the countdown
    g_pendingVoteCountdown--;
}

public displayEndOfTheMapVoteMenu( player_id )
{
    LOGGER( 128, "I AM ENTERING ON displayEndOfTheMapVoteMenu(1) | player_id: %d", player_id );
    
    new menu_id;
    new menuKeys;
    new menuKeysUnused;
    new playersCount;
    new players[ MAX_PLAYERS ];
    
    new menu_body[ 256 ];
    new menu_counter[ 64 ];
    new bool:isVoting;
    new bool:playerAnswered;
    
    if( player_id > 0 )
    {
        playersCount = 1;
        players[ 0 ] = player_id;
    }
    else
    {
        get_players( players, playersCount, "ch" );
    }
    
    for( new playerIndex = 0; playerIndex < playersCount; playerIndex++ )
    {
        player_id      = players[ playerIndex ];
        isVoting       = g_isPlayerParticipating[ player_id ];
        playerAnswered = g_answeredForEndOfMapVote[ player_id ];
        
        if( !playerAnswered )
        {
            menuKeys = MENU_KEY_0 | MENU_KEY_6;
            
            formatex( menu_counter, charsmax( menu_counter ),
                    " %s(%s%d %L%s)",
                    COLOR_YELLOW, COLOR_GREY, g_pendingVoteCountdown, LANG_PLAYER, "GAL_TIMELEFT", COLOR_YELLOW );
        }
        else
        {
            menuKeys          = MENU_KEY_1;
            menu_counter[ 0 ] = '^0';
        }
        
        menu_body[ 0 ] = '^0';
        
        formatex( menu_body, charsmax( menu_body ),
                "%s%L^n^n\
                %s6. %s%L %s^n\
                %s0. %s%L",
                COLOR_YELLOW, player_id, "GAL_CHOOSE_QUESTION",
                
                COLOR_RED, ( playerAnswered ? ( isVoting ? COLOR_YELLOW : COLOR_GREY ) : COLOR_WHITE ),
                player_id, "GAL_CHOOSE_QUESTION_YES", menu_counter,
                
                COLOR_RED, ( playerAnswered ? ( !isVoting ? COLOR_YELLOW : COLOR_GREY ) : COLOR_WHITE ),
                player_id, "GAL_CHOOSE_QUESTION_NO" );
        
        get_user_menu( player_id, menu_id, menuKeysUnused );
        
        if( menu_id == 0
            || menu_id == g_chooseMapQuestionMenuId )
        {
            show_menu( player_id, menuKeys, menu_body, ( g_pendingVoteCountdown == 1 ? 1 : 2 ),
                    CHOOSE_MAP_MENU_QUESTION );
        }
        
        LOGGER( 4, " ( displayEndOfTheMapVoteMenu| for ) menu_body: %s", menu_body );
        LOGGER( 4, "    menu_id:%d, menuKeys: %d, isVoting: %d, playerAnswered:%d, \
                        player_id: %d, playerIndex: %d", \
                        menu_id,    menuKeys,     isVoting,     playerAnswered, \
                        player_id,     playerIndex );
        
        LOGGER( 4, "    playersCount: %d, g_pendingVoteCountdown: %d, menu_counter: %s", \
                        playersCount,     g_pendingVoteCountdown,     menu_counter );
    }
    
    LOGGER( 4, "%48s", " ( displayEndOfTheMapVoteMenu| out )" );
}

public handleEndOfTheMapVoteChoice( player_id, pressedKeyCode )
{
    LOGGER( 128, "I AM ENTERING ON handleEndOfTheMapVoteChoice(2) | player_id: %d, pressedKeyCode: %d", \
                                                                    player_id,     pressedKeyCode );
    
    switch( pressedKeyCode )
    {
        case 9: // pressedKeyCode 9 means the keyboard key 0
        {
            announceRegistedVote( player_id, pressedKeyCode );
            
            g_isPlayerVoted[ player_id ]         = true;
            g_isPlayerParticipating[ player_id ] = false;
        }
        case 0: // pressedKeyCode 0 means the keyboard key 1
        {
            set_task( 0.1, "displayEndOfTheMapVoteMenu", player_id );
            return PLUGIN_CONTINUE;
        }
    }
    
    g_answeredForEndOfMapVote[ player_id ] = true;
    set_task( 0.1, "displayEndOfTheMapVoteMenu", player_id );
    
    return PLUGIN_CONTINUE;
}

public vote_handleDisplay()
{
    LOGGER( 128, "I AM ENTERING ON vote_handleDisplay(0)" );
    
    // announce: "time to choose"
    if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_TIMETOCHOOSE ) )
    {
        client_cmd( 0, "spk Gman/Gman_Choose%i", random_num( 1, 2 ) );
    }
    
    if( g_showVoteStatus
        && g_showVoteStatusType & STATUS_TYPE_PERCENTAGE )
    {
        copy( g_voteStatus_symbol, charsmax( g_voteStatus_symbol ), "%" );
    }
    
    // make sure the display is constructed from scratch
    g_isToRefreshVoteStatus = true;
    
    // ensure the vote status doesn't indicate expired
    g_voteStatus &= ~VOTE_IS_EXPIRED;
    
    new argument[ 2 ] = { true, 0 };
    
    if( g_showVoteStatus == SHOW_STATUS_ALWAYS
        || g_showVoteStatus == SHOW_STATUS_AFTER_VOTE )
    {
        set_task( 1.0, "vote_display", TASKID_VOTE_DISPLAY, argument, sizeof argument, "a",
                g_voteDuration );
    }
    else // g_showVoteStatus == SHOW_STATUS_AT_END || g_showVoteStatus == SHOW_STATUS_NEVER
    {
        set_task( 1.0, "tryToShowTheVotingMenu", TASKID_VOTE_DISPLAY, _, _, "a", g_voteDuration );
    }
    
    // display the vote outcome
    set_task( float( g_voteDuration ), "closeVoting", TASKID_VOTE_EXPIRE );
}

public tryToShowTheVotingMenu()
{
    LOGGER( 128, "I AM ENTERING ON tryToShowTheVotingMenu(0)" );
    
    new player_id;
    new playersCount;
    new players[ MAX_PLAYERS ];
    
    new argument[ 2 ] = { false, 0 };
    
    get_players( players, playersCount, "ch" ); // skip bots and hltv
    
    for( new player_index; player_index < playersCount; ++player_index )
    {
        player_id = players[ player_index ];
        
        if( !g_isPlayerSeeingTheVoteMenu[ player_id ]
            && isPlayerAbleToSeeTheVoteMenu( player_id ) )
        {
            argument[ 1 ]                            = player_id;
            g_isPlayerSeeingTheVoteMenu[ player_id ] = true;
            
            vote_display( argument );
        }
    }
}

public closeVoting()
{
    LOGGER( 128, "I AM ENTERING ON closeVoting(0)" );
    new argument[ 2 ] = { false, -1 };
    
    // waits until the last voting second to finish
    set_task( 0.9, "voteExpire" );
    
    set_task( 1.0, "vote_display", TASKID_VOTE_DISPLAY, argument, sizeof argument, "a", 3 );
    set_task( 5.5, "computeVotes", TASKID_VOTE_EXPIRE );
}

public voteExpire()
{
    LOGGER( 128, "I AM ENTERING ON voteExpire(0)" );
    g_voteStatus |= VOTE_IS_EXPIRED;
}

public vote_display( argument[ 2 ] )
{
    LOGGER( 0, "I AM ENTERING ON vote_display(1) | argument[0]: %d, argument[1]: %d", argument[ 0 ], argument[ 1 ] );
    
    new player_id           = argument[ 1 ];
    new copiedChars         = 0;
    new updateTimeRemaining = argument[ 0 ];
    
    new bool:isVoteOver   = g_voteStatus & VOTE_IS_EXPIRED != 0;
    new bool:noneIsHidden = ( g_isToShowNoneOption
                              && !g_voteShowNoneOptionType
                              && !isVoteOver );
    static menuKeys;
    static voteStatus  [ 512 ];
    static voteMapLine [ MAX_MAPNAME_LENGHT ];
    static menuClean   [ 512 ]; // menu showed while voting
    static menuDirty   [ 512 ]; // menu showed after voted
    
    if( updateTimeRemaining )
    {
        g_voteDuration--;
    }
    
    LOGGER( 4, "  ( votedisplay ) player_id: %i, updateTimeRemaining: %i, \
            g_isToRefreshVoteStatus: %i,  g_totalVoteOptions: %i, len( g_voteStatusClean ): %i", \
                                  argument[ 1 ], argument[ 0 ], \
            g_isToRefreshVoteStatus,      g_totalVoteOptions,  strlen( g_voteStatusClean )  );
    
    if( g_isToRefreshVoteStatus
        || isVoteOver )
    {
        // wipe the previous vote status clean
        voteStatus[ 0 ] = '^0';
        
        // register the 'None' option key
        if( g_isToShowNoneOption
            && !isVoteOver )
        {
            menuKeys = MENU_KEY_0;
        }
        
        // add maps to the menu
        for( new choice_index = 0; choice_index < g_totalVoteOptions; ++choice_index )
        {
            computeVoteMapLine( voteMapLine, charsmax( voteMapLine ), choice_index );
            
            copiedChars += formatex( voteStatus[ copiedChars ], charsmax( voteStatus ) - copiedChars,
                    "^n%s%i. %s%s%s",
                    COLOR_RED, choice_index + 1, COLOR_WHITE,
                    g_votingMapNames[ choice_index ], voteMapLine );
            
            menuKeys |= ( 1 << choice_index );
        }
    }
    
    // This is to optionally display to single player that just voted or never saw the menu.
    // This function is called with the correct player id only after the player voted or by the
    // 'tryToShowTheVotingMenu()' function call.
    if( player_id > 0 )
    {
        menuKeys = calculateExtensionOption( player_id, isVoteOver,
                copiedChars, voteStatus,
                charsmax( voteStatus ), menuKeys );
        
        if( g_showVoteStatus == SHOW_STATUS_ALWAYS
            || g_showVoteStatus == SHOW_STATUS_AFTER_VOTE )
        {
            calculate_menu_dirt( player_id, isVoteOver, voteStatus, menuDirty, charsmax( menuDirty ), noneIsHidden );
            display_vote_menu( false, player_id, menuDirty, menuKeys );
        }
        else // g_showVoteStatus == SHOW_STATUS_NEVER || g_showVoteStatus == SHOW_STATUS_AT_END
        {
            calculate_menu_clean( player_id, menuClean, charsmax( menuClean ) );
            display_vote_menu( true, player_id, menuClean, menuKeys );
        }
    }
    else // just display to everyone
    {
        new playersCount;
        new players[ MAX_PLAYERS ];
        
        get_players( players, playersCount, "ch" ); // skip bots and hltv
        
        for( new playerIndex = 0; playerIndex < playersCount; ++playerIndex )
        {
            player_id = players[ playerIndex ];
            
            menuKeys = calculateExtensionOption( player_id, isVoteOver,
                    copiedChars, voteStatus,
                    charsmax( voteStatus ), menuKeys );
            
            if( !g_isPlayerVoted[ player_id ]
                && !isVoteOver
                && g_showVoteStatus != SHOW_STATUS_ALWAYS )
            {
                calculate_menu_clean( player_id, menuClean, charsmax( menuClean ) );
                display_vote_menu( true, player_id, menuClean, menuKeys );
            }
            else if( g_showVoteStatus == SHOW_STATUS_ALWAYS
                     || ( isVoteOver
                          && g_showVoteStatus )
                     || ( g_isPlayerVoted[ player_id ]
                          && g_showVoteStatus == SHOW_STATUS_AFTER_VOTE ) )
            {
                calculate_menu_dirt( player_id, isVoteOver, voteStatus, menuDirty, charsmax( menuDirty ), noneIsHidden );
                display_vote_menu( false, player_id, menuDirty, menuKeys );
            }
        }
    }
}

stock calculateExtensionOption( player_id, bool:isVoteOver, copiedChars, voteStatus[], voteStatusLenght,
                                menuKeys )
{
    LOGGER( 0, "I AM ENTERING ON calculateExtensionOption(6) | player_id: %d, isVoteOver: %d, \
            copiedChars: %d, voteStatus: %s, ^nvoteStatusLenght: %d, menuKeys: %d", player_id, isVoteOver, \
            copiedChars,     voteStatus,       voteStatusLenght,     menuKeys );
    
    if( g_isToRefreshVoteStatus
        || isVoteOver )
    {
        new bool:allowStay;
        new bool:allowExtend;
        
        new voteMapLine[ MAX_MAPNAME_LENGHT ];
        
        allowExtend = ( g_isGameFinalVoting
                        && !( g_voteStatus & VOTE_IS_RUNOFF ) );
        
        allowStay = ( ( g_voteStatus & VOTE_IS_EARLY
                        || g_voteStatus & VOTE_IS_FORCED )
                      && !( g_voteStatus & VOTE_IS_RUNOFF ) );
        
        if( g_isRunOffNeedingKeepCurrentMap )
        {
            // if it is a end map RunOff, then it is a extend button, not a keep current map button
            if( g_isGameFinalVoting )
            {
                allowExtend = true;
                allowStay   = false;
            }
            else
            {
                allowExtend = false;
                allowStay   = true;
            }
        }
        
        if( !g_isExtendmapAllowStay )
        {
            allowStay = false;
        }
        
        LOGGER( 4, "    ( vote_handleDisplay ) Add optional menu item | \
                allowStay: %d, allowExtend: %d, g_isExtendmapAllowStay: %d", \
                allowStay,     allowExtend,     g_isExtendmapAllowStay );
        
        // add optional menu item
        if( g_isMapExtensionAllowed
            && ( allowExtend
                 || allowStay ) )
        {
            // if it's not a runoff vote, add a space between the maps and the additional option
            if( !( g_voteStatus & VOTE_IS_RUNOFF ) )
            {
                copiedChars += formatex( voteStatus[ copiedChars ], voteStatusLenght - copiedChars, "^n" );
            }
            
            computeVoteMapLine( voteMapLine, charsmax( voteMapLine ), g_totalVoteOptions );
            
            if( allowExtend )
            {
                new extend_step = 15;
                new extend_option_type[ 32 ];
                
                // add the "Extend Map" menu item.
                if( g_isVotingByRounds )
                {
                    extend_step = g_extendmapStepRounds;
                    copy( extend_option_type, charsmax( extend_option_type ), "GAL_OPTION_EXTEND_ROUND" );
                }
                else
                {
                    extend_step = g_extendmapStepMinutes;
                    copy( extend_option_type, charsmax( extend_option_type ), "GAL_OPTION_EXTEND" );
                }
                
                copiedChars += formatex( voteStatus[ copiedChars ], voteStatusLenght - copiedChars,
                        "^n%s%i. %s%L%s",
                        COLOR_RED, g_totalVoteOptions + 1,
                        COLOR_WHITE, player_id,
                        extend_option_type, g_currentMap,
                        extend_step, voteMapLine );
            }
            else
            {
                // add the "Stay Here" menu item
                if( g_extendmapAllowStayType )
                {
                    copiedChars += formatex( voteStatus[ copiedChars ], voteStatusLenght - copiedChars,
                            "^n%s%i. %s%L%s",
                            COLOR_RED, g_totalVoteOptions + 1,
                            COLOR_WHITE, player_id, "GAL_OPTION_STAY_MAP",
                            g_currentMap, voteMapLine );
                }
                else
                {
                    copiedChars += formatex( voteStatus[ copiedChars ], voteStatusLenght - copiedChars,
                            "^n%s%i. %s%L%s",
                            COLOR_RED, g_totalVoteOptions + 1,
                            COLOR_WHITE, player_id, "GAL_OPTION_STAY",
                            voteMapLine );
                }
            }
            
            // Added the extension/stay key option (1 << 2 = key 3, 1 << 3 = key 4, ...)
            menuKeys |= ( 1 << g_totalVoteOptions );
        }
        
        g_isToRefreshVoteStatus =  g_showVoteStatus & 3 != 0;
    }
    
    // make a copy of the virgin menu
    if( g_voteStatusClean[ 0 ] == '^0' )
    {
        copy( g_voteStatusClean, charsmax( g_voteStatusClean ), voteStatus );
    }
    
    return menuKeys;
}

stock calculate_menu_dirt( player_id, bool:isVoteOver, voteStatus[], menuDirty[], menuDirtySize, bool:noneIsHidden )
{
    LOGGER( 0, "I AM ENTERING ON calculate_menu_dirt(6) | player_id: %d, isVoteOver: %d, \
            voteStatus: %s, ^nmenuDirty: %s, menuDirtySize: %d, noneIsHidden: %d", player_id, isVoteOver, \
            voteStatus,       menuDirty,     menuDirtySize,     noneIsHidden );
    
    static voteFooter[ 64 ];
    static menuHeader[ 32 ];
    static noneOption[ 32 ];
    static bool:isToShowUndo;
    
    menuDirty  [ 0 ] = '^0';
    noneOption [ 0 ] = '^0';
    isToShowUndo     = ( player_id > 0 \
                         && g_voteShowNoneOptionType == CONVERT_IT_TO_CANCEL_LAST_VOTE \
                         && g_isPlayerVoted[ player_id ] \
                         && !g_isPlayerCancelledVote[ player_id ] );
    
    computeVoteMenuFooter( player_id, voteFooter, charsmax( voteFooter ) );
    
    // to append it here to always shows it AFTER voting.
    if( isVoteOver )
    {
        // add the header
        formatex( menuHeader, charsmax( menuHeader ), "%s%L",
                COLOR_YELLOW, player_id, "GAL_RESULT" );
        
        if( g_isToShowNoneOption
            && g_voteShowNoneOptionType )
        {
            computeUndoButton( player_id, isToShowUndo, isVoteOver, noneOption, charsmax( noneOption ) );
            
            formatex( menuDirty, menuDirtySize, "%s^n%s^n^n%s%s^n^n%L",
                    menuHeader, voteStatus, noneOption, COLOR_YELLOW, player_id, "GAL_VOTE_ENDED" );
        }
        else
        {
            formatex( menuDirty, menuDirtySize, "%s^n%s^n^n%s%L",
                    menuHeader, voteStatus, COLOR_YELLOW, player_id, "GAL_VOTE_ENDED" );
        }
    }
    else
    {
        // add the header
        formatex( menuHeader, charsmax( menuHeader ), "%s%L",
                COLOR_YELLOW, player_id, "GAL_CHOOSE" );
        
        if( g_isToShowNoneOption )
        {
            computeUndoButton( player_id, isToShowUndo, isVoteOver, noneOption, charsmax( noneOption ) );
            
            // remove the extra space between 'voteStatus' and 'voteFooter', after the 'None' option is hidden
            if( noneIsHidden
                && g_isPlayerVoted[ player_id ] )
            {
                voteFooter[ 0 ] = ' ';
                voteFooter[ 1 ] = ' ';
            }
            
            formatex( menuDirty, menuDirtySize, "%s^n%s^n^n%s%s",
                    menuHeader, voteStatus, noneOption, voteFooter );
        }
        else
        {
            formatex( menuDirty, menuDirtySize, "%s^n%s%s",
                    menuHeader, voteStatus, voteFooter );
        }
    }
}

stock computeVoteMenuFooter( player_id, voteFooter[], voteFooterSize )
{
    LOGGER( 0, "I AM ENTERING ON computeVoteMenuFooter(3) | player_id: %d, voteFooter: %s, \
            voteFooterSize: %d",                            player_id,     voteFooter, \
            voteFooterSize );
    
    static copiedChars;
    copiedChars = copy( voteFooter, voteFooterSize, "^n^n" );
    
    if( g_isToShowExpCountdown )
    {
        if( ( g_voteDuration < 10
              || g_isToShowVoteCounter )
            && ( g_showVoteStatus == SHOW_STATUS_ALWAYS
                 || g_showVoteStatus == SHOW_STATUS_AFTER_VOTE ) )
        {
            if( g_voteDuration >= 0 )
            {
                formatex( voteFooter[ copiedChars ], voteFooterSize - copiedChars, "%s%L: %s%i",
                        COLOR_WHITE, player_id, "GAL_TIMELEFT", COLOR_RED, g_voteDuration + 1 );
            }
            else
            {
                formatex( voteFooter[ copiedChars ], voteFooterSize - copiedChars,
                        "%s%L", COLOR_YELLOW, player_id, "GAL_VOTE_ENDED" );
            }
        }
    }
}

stock computeUndoButton( player_id, bool:isToShowUndo, bool:isVoteOver, noneOption[], noneOptionSize )
{
    LOGGER( 0, "I AM ENTERING ON computeUndoButton(5) | player_id: %d, isToShowUndo: %d, \
            noneOption: %s, noneOptionSize: %d",        player_id,     isToShowUndo, \
            noneOption,     noneOptionSize );
    
    if( isToShowUndo )
    {
        formatex( noneOption, noneOptionSize, "%s0. %s%L",
                COLOR_RED, ( isVoteOver ? COLOR_GREY : COLOR_WHITE ),
                player_id, "GAL_OPTION_CANCEL_VOTE" );
    }
    else
    {
        if( g_isPlayerCancelledVote[ player_id ] )
        {
            if( g_isPlayerVoted[ player_id ]  )
            {
                formatex( noneOption, noneOptionSize, "%s0. %s%L",
                        COLOR_RED, COLOR_GREY, player_id, "GAL_OPTION_CANCEL_VOTE" );
            }
            else
            {
                formatex( noneOption, noneOptionSize, "%s0. %s%L",
                        COLOR_RED, COLOR_WHITE, player_id, "GAL_OPTION_NONE" );
            }
        }
        else
        {
            switch( g_voteShowNoneOptionType )
            {
                case HIDE_AFTER_USER_VOTE:
                {
                    if( g_isPlayerVoted[ player_id ] )
                    {
                        noneOption[ 0 ] = '^0';
                    }
                    else
                    {
                        formatex( noneOption, noneOptionSize, "%s0. %s%L",
                                COLOR_RED, COLOR_WHITE, player_id, "GAL_OPTION_NONE" );
                    }
                }
                case ALWAYS_KEEP_SHOWING, CONVERT_IT_TO_CANCEL_LAST_VOTE:
                {
                    formatex( noneOption, noneOptionSize, "%s0. %s%L",
                            COLOR_RED, COLOR_WHITE, player_id, "GAL_OPTION_NONE" );
                }
            }
        }
    }
}

stock calculate_menu_clean( player_id, menuClean[], menuCleanSize )
{
    LOGGER( 0, "I AM ENTERING ON calculate_menu_clean(3) | player_id: %d, menuClean: %s, \
            menuCleanSize: %d",                            player_id,     menuClean, \
            menuCleanSize );
    
    static voteFooter[ 64 ];
    static menuHeader[ 32 ];
    static noneOption[ 32 ];
    static bool:isToShowUndo;
    
    menuClean  [ 0 ] = '^0';
    noneOption [ 0 ] = '^0';
    isToShowUndo     = ( player_id > 0 \
                         && g_voteShowNoneOptionType == CONVERT_IT_TO_CANCEL_LAST_VOTE \
                         && g_isPlayerVoted[ player_id ] \
                         && !g_isPlayerCancelledVote[ player_id ] );
    
    computeVoteMenuFooter( player_id, voteFooter, charsmax( voteFooter ) );
    
    // add the header
    formatex( menuHeader, charsmax( menuHeader ), "%s%L",
            COLOR_YELLOW, player_id, "GAL_CHOOSE" );
    
    // append a "None" option on for people to choose if they don't like any other choice
    // to append it here to always shows it WHILE voting.
    if( g_isToShowNoneOption )
    {
        if( isToShowUndo )
        {
            copy( noneOption, charsmax( noneOption ), "GAL_OPTION_CANCEL_VOTE" );
        }
        else
        {
            copy( noneOption, charsmax( noneOption ), "GAL_OPTION_NONE" );
        }
        
        formatex( menuClean, menuCleanSize, "%s^n%s^n^n\
                %s0. %s%L%s",
                menuHeader, g_voteStatusClean,
                COLOR_RED, COLOR_WHITE,
                player_id, noneOption,
                voteFooter );
    }
    else
    {
        formatex( menuClean, menuCleanSize, "%s^n%s%s",
                menuHeader, g_voteStatusClean, voteFooter );
    }
}

stock display_vote_menu( bool:menuType, player_id, menuBody[], menuKeys )
{
    LOGGER( 0, "I AM ENTERING ON display_vote_menu(4) | menuType: %d, player_id: %d, \
            menuBody: %s, menuKeys: %d",                menuType,     player_id, \
            menuBody,     menuKeys );
    
#if defined DEBUG
    if( player_id == 1 )
    {
        new player_name[ MAX_PLAYER_NAME_LENGHT ];
        
        GET_USER_NAME( player_id, player_name );
        
        LOGGER( 4, "    [%s ( %s )]", player_name, ( menuType ? "clean" : "dirty" ) );
        LOGGER( 4, "        %s", menuBody );
        LOGGER( 4, "" );
    }
#endif
    
    if( isPlayerAbleToSeeTheVoteMenu( player_id ) )
    {
        show_menu( player_id, menuKeys, menuBody,
                ( menuType ? g_voteDuration : max( 2, g_voteDuration ) ),
                CHOOSE_MAP_MENU_NAME );
    }
}

stock isPlayerAbleToSeeTheVoteMenu( player_id )
{
    LOGGER( 0, "I AM ENTERING ON isPlayerAbleToSeeTheVoteMenu(1) | player_id: %d", player_id );
    
    new menu_id;
    new menukeys_unused;
    
    get_user_menu( player_id, menu_id, menukeys_unused );
    
    return ( menu_id == 0
             || menu_id == g_chooseMapMenuId
             || get_pcvar_num( cvar_isToReplaceByVoteMenu ) != 0 );
}

public vote_handleChoice( player_id, key )
{
    LOGGER( 128, "I AM ENTERING ON vote_handleChoice(2) | player_id: %d, key: %d", player_id, key );
    
    if( g_voteStatus & VOTE_IS_EXPIRED )
    {
        client_cmd( player_id, "^"slot%i^"", key + 1 );
        return;
    }
    
    if( !g_isPlayerVoted[ player_id ] )
    {
        register_vote( player_id, key );
        
        g_isToRefreshVoteStatus = true;
    }
    else if( key == 9
             && !g_isPlayerCancelledVote[ player_id ]
             && g_voteShowNoneOptionType == CONVERT_IT_TO_CANCEL_LAST_VOTE
             && g_isToShowNoneOption )
    {
        cancel_player_vote( player_id );
    }
    else
    {
        client_cmd( player_id, "^"slot%i^"", key + 1 );
    }
    
    // display the vote again, with status
    if( g_showVoteStatus == SHOW_STATUS_ALWAYS
        || g_showVoteStatus == SHOW_STATUS_AFTER_VOTE )
    {
        new argument[ 2 ];
        
        argument[ 0 ] = false;
        argument[ 1 ] = player_id;
        
        set_task( 0.1, "vote_display", TASKID_VOTE_DISPLAY, argument, sizeof argument );
    }
}

stock cancel_player_vote( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cancel_player_vote(1) | player_id: %d", player_id );
    new voteWeight = g_playerVotedWeight[ player_id ];
    
    g_isPlayerVoted[ player_id ]         = false;
    g_isPlayerParticipating[ player_id ] = true;
    g_isPlayerCancelledVote[ player_id ] = true;
    
    g_totalVotesCounted                                              -= voteWeight;
    g_arrayOfMapsWithVotesNumber[ g_playerVotedOption[ player_id ] ] -= voteWeight;
    
    g_playerVotedOption[ player_id ] -= g_playerVotedOption[ player_id ];
    g_playerVotedWeight[ player_id ] -= g_playerVotedWeight[ player_id ];
}

/**
 * Register the player's choice giving extra weight to admin votes.
 */
stock register_vote( player_id, pressedKeyCode )
{
    LOGGER( 128, "I AM ENTERING ON register_vote(2) | player_id: %d, pressedKeyCode: %d", player_id, pressedKeyCode );
    
    announceRegistedVote( player_id, pressedKeyCode );
    g_isPlayerVoted[ player_id ] = true;
    
    if( pressedKeyCode == 9 )
    {
        g_isPlayerParticipating[ player_id ] = false; // if is not interested now, at runoff wont also
        g_playerVotedOption[ player_id ]     = 0; // the None option does not integrate vote counting
        g_playerVotedWeight[ player_id ]     = 0; // the None option has no weight
    }
    else
    {
        g_isPlayerParticipating[ player_id ] = true;
        g_playerVotedOption[ player_id ]     = pressedKeyCode;
        g_playerVotedWeight[ player_id ]     = 1;
    }
    
    // pressedKeyCode 9 means the keyboard key 0 (the None option) and it does not integrate the vote
    if( pressedKeyCode != 9 )
    {
        // increment votes cast count
        g_totalVotesCounted++;
        
        new voteWeight = get_pcvar_num( cvar_voteWeight );
        
        if( voteWeight > 1
            && has_flag( player_id, g_voteWeightFlags ) )
        {
            g_playerVotedWeight[ player_id ]                = voteWeight;
            g_arrayOfMapsWithVotesNumber[ pressedKeyCode ] += voteWeight;
            g_totalVotesCounted                            += ( voteWeight - 1 );
            
            color_print( player_id, "^1%L", player_id, "GAL_VOTE_WEIGHTED", voteWeight );
        }
        else
        {
            g_arrayOfMapsWithVotesNumber[ pressedKeyCode ]++;
        }
    }
}

stock announceRegistedVote( player_id, pressedKeyCode )
{
    LOGGER( 128, "I AM ENTERING ON announceRegistedVote(2) | player_id: %d, pressedKeyCode: %d", player_id, pressedKeyCode );
    
    new player_name[ MAX_PLAYER_NAME_LENGHT ];
    new bool:isToAnnounceChoice = get_pcvar_num( cvar_voteAnnounceChoice ) != 0;
    
    if( isToAnnounceChoice )
    {
        GET_USER_NAME( player_id, player_name );
    }
    
    // confirm the player's choice (pressedKeyCode = 9 means 0 on the keyboard, 8 is 7, etc)
    if( pressedKeyCode == 9 )
    {
        LOGGER( 4, "      %-32s ( none )", player_name );
        
        if( isToAnnounceChoice )
        {
            color_print( 0, "^1%L", LANG_PLAYER, "GAL_CHOICE_NONE_ALL", player_name );
        }
        else
        {
            color_print( player_id, "^1%L", player_id, "GAL_CHOICE_NONE" );
        }
    }
    else if( pressedKeyCode == g_totalVoteOptions )
    {
        // only display the "none" vote if we haven't already voted
        // ( we can make it here from the vote status menu too )
        if( !g_isPlayerVoted[ player_id ] )
        {
            LOGGER( 4, "      %-32s ( extend )", player_name );
            
            if( g_isGameFinalVoting )
            {
                if( isToAnnounceChoice )
                {
                    color_print( 0, "^1%L", LANG_PLAYER, "GAL_CHOICE_EXTEND_ALL", player_name );
                }
                else
                {
                    color_print( player_id, "^1%L", player_id, "GAL_CHOICE_EXTEND" );
                }
            }
            else
            {
                if( isToAnnounceChoice )
                {
                    color_print( 0, "^1%L", LANG_PLAYER, "GAL_CHOICE_STAY_ALL", player_name );
                }
                else
                {
                    color_print( player_id, "^1%L", player_id, "GAL_CHOICE_STAY" );
                }
            }
        }
    }
    else
    {
        LOGGER( 4, "      %-32s %s", player_name, g_votingMapNames[ pressedKeyCode ] );
        
        if( isToAnnounceChoice )
        {
            color_print( 0, "^1%L", LANG_PLAYER, "GAL_CHOICE_MAP_ALL",
                    player_name, g_votingMapNames[ pressedKeyCode ] );
        }
        else
        {
            color_print( player_id, "^1%L", player_id, "GAL_CHOICE_MAP",
                    g_votingMapNames[ pressedKeyCode ] );
        }
    }
}

stock computeVoteMapLine( voteMapLine[], voteMapLineLength, voteIndex )
{
    LOGGER( 128, "I AM ENTERING ON computeVoteMapLine(3) | voteMapLine: %s, voteMapLineLength: %d, \
    voteIndex: %d",                                        voteMapLine,     voteMapLineLength, \
    voteIndex );
    
    new voteCountNumber = g_arrayOfMapsWithVotesNumber[ voteIndex ];
    
    if( voteCountNumber
        && g_showVoteStatus )
    {
        switch( g_showVoteStatusType )
        {
            case STATUS_TYPE_COUNT:
            {
                formatex( voteMapLine, voteMapLineLength, " %s(%s%i%s%s)",
                        COLOR_YELLOW, COLOR_GREY,
                        voteCountNumber, g_voteStatus_symbol,
                        COLOR_YELLOW );
            }
            case STATUS_TYPE_PERCENTAGE:
            {
                new votePercentNunber = percent( voteCountNumber, g_totalVotesCounted );
                
                formatex( voteMapLine, voteMapLineLength, " %s(%s%i%s%s)",
                        COLOR_YELLOW, COLOR_GREY,
                        votePercentNunber, g_voteStatus_symbol,
                        COLOR_YELLOW );
            }
            case STATUS_TYPE_PERCENTAGE | STATUS_TYPE_COUNT:
            {
                new votePercentNunber = percent( voteCountNumber, g_totalVotesCounted );
                
                formatex( voteMapLine, voteMapLineLength,
                        " %s(%s%i%s %s[%s%d%s]%s)",
                        COLOR_RED, COLOR_GREY,
                        votePercentNunber, g_voteStatus_symbol,
                        COLOR_YELLOW, COLOR_GREY,
                        voteCountNumber, COLOR_YELLOW,
                        COLOR_RED );
            }
            default:
            {
                voteMapLine[ 0 ] = '^0';
            }
        }
    }
    else
    {
        voteMapLine[ 0 ] = '^0';
    }
    
    LOGGER( 0, " ( computeVoteMapLine ) | g_showVoteStatus: %d, \
            g_showVoteStatusType: %d, voteCountNumber: %d", \
                                          g_showVoteStatus, \
            g_showVoteStatusType,     voteCountNumber );
}

public computeVotes()
{
    LOGGER( 128, "I AM ENTERING ON computeVotes(0)" );
    
    new winnerVoteMapIndex;
    new playerVoteMapChoiceIndex;
    
    new numberOfVotesAtFirstPlace;
    new numberOfVotesAtSecondPlace;
    
    // retain the number of draw maps at first and second positions
    new numberOfMapsAtFirstPosition;
    new numberOfMapsAtSecondPosition;
    
    new firstPlaceChoices[ MAX_OPTIONS_IN_VOTE ];
    new secondPlaceChoices[ MAX_OPTIONS_IN_VOTE ];

#if defined DEBUG
    new voteMapLine[ 32 ];
    
    LOGGER( 4, "" );
    LOGGER( 4, "   [VOTE RESULT]" );
    
    for( playerVoteMapChoiceIndex = 0; playerVoteMapChoiceIndex <= g_totalVoteOptions;
         ++playerVoteMapChoiceIndex )
    {
        computeVoteMapLine( voteMapLine, charsmax( voteMapLine ), playerVoteMapChoiceIndex );
        
        LOGGER( 4, "      %2i/%3i  %i. %s", \
                g_arrayOfMapsWithVotesNumber[ playerVoteMapChoiceIndex ], \
                g_totalVotesCounted, \
                playerVoteMapChoiceIndex, \
                g_votingMapNames[ playerVoteMapChoiceIndex ] );
    }
    
    LOGGER( 4, "" );
#endif
    
    // determine the number of votes for 1st and 2nd places
    for( playerVoteMapChoiceIndex = 0; playerVoteMapChoiceIndex <= g_totalVoteOptions;
         ++playerVoteMapChoiceIndex )
    {
        if( numberOfVotesAtFirstPlace < g_arrayOfMapsWithVotesNumber[ playerVoteMapChoiceIndex ] )
        {
            numberOfVotesAtSecondPlace = numberOfVotesAtFirstPlace;
            numberOfVotesAtFirstPlace  = g_arrayOfMapsWithVotesNumber[ playerVoteMapChoiceIndex ];
        }
        else if( numberOfVotesAtSecondPlace < g_arrayOfMapsWithVotesNumber[ playerVoteMapChoiceIndex ] )
        {
            numberOfVotesAtSecondPlace = g_arrayOfMapsWithVotesNumber[ playerVoteMapChoiceIndex ];
        }
    }
    
    // determine which maps are in 1st and 2nd places
    for( playerVoteMapChoiceIndex = 0; playerVoteMapChoiceIndex <= g_totalVoteOptions;
         ++playerVoteMapChoiceIndex )
    {
        LOGGER( 16, "Inside the for to determine which maps are in 1st and 2nd places, \
                g_arrayOfMapsWithVotesNumber[%d] = %d ", \
                playerVoteMapChoiceIndex, \
                g_arrayOfMapsWithVotesNumber[ playerVoteMapChoiceIndex ] );
        
        if( g_arrayOfMapsWithVotesNumber[ playerVoteMapChoiceIndex ] == numberOfVotesAtFirstPlace )
        {
            firstPlaceChoices[ numberOfMapsAtFirstPosition++ ] = playerVoteMapChoiceIndex;
        }
        else if( g_arrayOfMapsWithVotesNumber[ playerVoteMapChoiceIndex ] == numberOfVotesAtSecondPlace )
        {
            secondPlaceChoices[ numberOfMapsAtSecondPosition++ ] = playerVoteMapChoiceIndex;
        }
    }
    
    // At for: g_totalVoteOptions: 5, numberOfMapsAtFirstPosition: 3, numberOfMapsAtSecondPosition: 0
    LOGGER( 16, "After for to determine which maps are in 1st and 2nd places, \
            g_totalVoteOptions: %d, \
            numberOfMapsAtFirstPosition: %d, \
            numberOfMapsAtSecondPosition: %d", \
            g_totalVoteOptions, numberOfMapsAtFirstPosition, numberOfMapsAtSecondPosition );
    
    LOGGER( 1, "    ( computeVotes|middle ) g_isTimeToRestart: %d,\
            g_isTimeToChangeLevel: %d \
            g_voteStatus & VOTE_IS_FORCED: %d", \
            g_isTimeToRestart, g_isTimeToChangeLevel, g_voteStatus & VOTE_IS_FORCED != 0 );
    
    // announce the outcome
    if( numberOfVotesAtFirstPlace )
    {
        // if the top vote getting map didn't receive over 50% of the votes cast, to start a runoff vote
        if( get_pcvar_num( cvar_runoffEnabled )
            && !( g_voteStatus & VOTE_IS_RUNOFF )
            && numberOfVotesAtFirstPlace <= g_totalVotesCounted / 2 )
        {
            // announce runoff voting requirement
            color_print( 0, "^1%L", LANG_PLAYER, "GAL_RUNOFF_REQUIRED" );
            
            if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_RUNOFFREQUIRED ) )
            {
                client_cmd( 0, "spk ^"run officer( e40 ) voltage( e30 ) accelerating( s70 ) \
                        is required^"" );
            }
            
            // let the server know the next vote will be a runoff
            g_voteStatus |= VOTE_IS_RUNOFF;
            
            if( numberOfMapsAtFirstPosition > 2 )
            {
                LOGGER( 16, "( numberOfMapsAtFirstPosition > 2 ) --- \
                        firstPlaceChoices[ numberOfMapsAtFirstPosition - 1 ] : %d", \
                        firstPlaceChoices[ numberOfMapsAtFirstPosition - 1 ] );
                
                // determine the two choices that will be facing off
                new firstChoiceIndex;
                new secondChoiceIndex;
                
                firstChoiceIndex  = random_num( 0, numberOfMapsAtFirstPosition - 1 );
                secondChoiceIndex = random_num( 0, numberOfMapsAtFirstPosition - 1 );
                
                LOGGER( 16, "( numberOfMapsAtFirstPosition > 2 ) --- \
                        firstChoiceIndex: %d, secondChoiceIndex: %d", \
                        firstChoiceIndex, secondChoiceIndex );
                
                if( firstChoiceIndex == secondChoiceIndex )
                {
                    if( secondChoiceIndex - 1 < 0 )
                    {
                        ++secondChoiceIndex;
                    }
                    else
                    {
                        --secondChoiceIndex;
                    }
                }
                
                /**
                 * If firstPlaceChoices[ numberOfMapsAtFirstPosition - 1 ]  is equal to
                 * g_totalVoteOptions then it option is not a valid map, it is the keep current
                 * map option, and must be informed it to the vote_display function, to show the
                 * 1 map options and the keep current map.
                 */
                if( firstPlaceChoices[ firstChoiceIndex ] == g_totalVoteOptions )
                {
                    g_totalVoteOptionsTemp          = 1;
                    g_arrayOfRunOffChoices[ 0 ]     = firstPlaceChoices[ secondChoiceIndex ];
                    g_isRunOffNeedingKeepCurrentMap = true;
                }
                else if( firstPlaceChoices[ secondChoiceIndex ] == g_totalVoteOptions )
                {
                    g_totalVoteOptionsTemp          = 1;
                    g_arrayOfRunOffChoices[ 0 ]     = firstPlaceChoices[ firstChoiceIndex ];
                    g_isRunOffNeedingKeepCurrentMap = true;
                }
                else
                {
                    g_totalVoteOptionsTemp      = 2;
                    g_arrayOfRunOffChoices[ 0 ] = firstPlaceChoices[ firstChoiceIndex ];
                    g_arrayOfRunOffChoices[ 1 ] = firstPlaceChoices[ secondChoiceIndex ];
                }
                
                LOGGER( 16, "( numberOfMapsAtFirstPosition > 2 ) --- \
                        firstChoiceIndex: %d, secondChoiceIndex: %d", \
                        firstChoiceIndex, secondChoiceIndex );
                LOGGER( 16, "( numberOfMapsAtFirstPosition > 2 ) --- GAL_RESULT_TIED1 --- \
                        Runoff map1: %s, Runoff map2: %s", \
                        g_votingMapNames[ g_arrayOfRunOffChoices[ 0 ] ], \
                        g_votingMapNames[ g_arrayOfRunOffChoices[ 1 ] ] );
                
                color_print( 0, "^1%L", LANG_PLAYER, "GAL_RESULT_TIED1", numberOfMapsAtFirstPosition );
            }
            else if( numberOfMapsAtFirstPosition == 2 )
            {
                if( firstPlaceChoices[ 0 ] == g_totalVoteOptions )
                {
                    g_isRunOffNeedingKeepCurrentMap = true;
                    g_arrayOfRunOffChoices[ 0 ]     = firstPlaceChoices[ 1 ];
                    g_totalVoteOptionsTemp          = 1;
                }
                else if( firstPlaceChoices[ 1 ] == g_totalVoteOptions )
                {
                    g_isRunOffNeedingKeepCurrentMap = true;
                    g_arrayOfRunOffChoices[ 0 ]     = firstPlaceChoices[ 0 ];
                    g_totalVoteOptionsTemp          = 1;
                }
                else
                {
                    g_totalVoteOptionsTemp      = 2;
                    g_arrayOfRunOffChoices[ 0 ] = firstPlaceChoices[ 0 ];
                    g_arrayOfRunOffChoices[ 1 ] = firstPlaceChoices[ 1 ];
                }
                
                LOGGER( 16, "( numberOfMapsAtFirstPosition == 2 ) --- Runoff map1: %s, \
                        Runoff map2: %s, g_totalVoteOptions: %d", \
                        g_votingMapNames[ g_arrayOfRunOffChoices[ 0 ] ], \
                        g_votingMapNames[ g_arrayOfRunOffChoices[ 1 ] ], \
                        g_totalVoteOptions );
            }
            else if( numberOfMapsAtSecondPosition == 1 )
            {
                if( firstPlaceChoices[ 0 ] == g_totalVoteOptions )
                {
                    g_isRunOffNeedingKeepCurrentMap = true;
                    g_arrayOfRunOffChoices[ 0 ]     = secondPlaceChoices[ 0 ];
                    g_totalVoteOptionsTemp          = 1;
                }
                else if( secondPlaceChoices[ 0 ] == g_totalVoteOptions )
                {
                    g_isRunOffNeedingKeepCurrentMap = true;
                    g_arrayOfRunOffChoices[ 0 ]     = firstPlaceChoices[ 0 ];
                    g_totalVoteOptionsTemp          = 1;
                }
                else
                {
                    g_totalVoteOptionsTemp      = 2;
                    g_arrayOfRunOffChoices[ 0 ] = firstPlaceChoices[ 0 ];
                    g_arrayOfRunOffChoices[ 1 ] = secondPlaceChoices[ 0 ];
                }
                
                LOGGER( 16, "( numberOfMapsAtSecondPosition == 1 ) --- \
                        Runoff map1: %s, Runoff map2: %s", \
                        g_votingMapNames[ g_arrayOfRunOffChoices[ 0 ] ], \
                        g_votingMapNames[ g_arrayOfRunOffChoices[ 1 ] ] );
            }
            else // numberOfMapsAtFirstPosition == 1 && numberOfMapsAtSecondPosition > 1
            {
                new randonNumber = random_num( 0, numberOfMapsAtSecondPosition - 1 );
                
                if( firstPlaceChoices[ 0 ] == g_totalVoteOptions )
                {
                    g_isRunOffNeedingKeepCurrentMap = true;
                    g_arrayOfRunOffChoices[ 0 ]     = secondPlaceChoices[ randonNumber ];
                    g_totalVoteOptionsTemp          = 1;
                }
                else if( secondPlaceChoices[ randonNumber ] == g_totalVoteOptions )
                {
                    g_isRunOffNeedingKeepCurrentMap = true;
                    g_arrayOfRunOffChoices[ 0 ]     = firstPlaceChoices[ 0 ];
                    g_totalVoteOptionsTemp          = 1;
                }
                else
                {
                    g_totalVoteOptionsTemp      = 2;
                    g_arrayOfRunOffChoices[ 0 ] = firstPlaceChoices[ 0 ];
                    g_arrayOfRunOffChoices[ 1 ] = secondPlaceChoices[ randonNumber ];
                }
                
                LOGGER( 16, "( numberOfMapsAtFirstPosition == 1 && numberOfMapsAtSecondPosition > 1 ) --- \
                        Runoff map1: %s, Runoff map2: %s", \
                        g_votingMapNames[ g_arrayOfRunOffChoices[ 0 ] ], \
                        g_votingMapNames[ g_arrayOfRunOffChoices[ 1 ] ] );
                
                color_print( 0, "^1%L", LANG_PLAYER, "GAL_RESULT_TIED2", numberOfMapsAtSecondPosition );
            }
            
            // clear all the votes
            vote_resetStats();
            
            // start the runoff vote, vote_startDirector
            set_task( 3.0, "startNonForcedVoting", TASKID_VOTE_STARTDIRECTOR );
            
            return;
        }
        
        // if there is a tie for 1st, randomly select one as the winner
        if( numberOfMapsAtFirstPosition > 1 )
        {
            winnerVoteMapIndex = firstPlaceChoices[ random_num( 0, numberOfMapsAtFirstPosition - 1 ) ];
            
            color_print( 0, "^1%L", LANG_PLAYER, "GAL_WINNER_TIED", numberOfMapsAtFirstPosition );
        }
        else
        {
            winnerVoteMapIndex = firstPlaceChoices[ 0 ];
        }
        
        LOGGER( 1, "    ( computeVotes|moreover ) g_isTimeToRestart: %d, \
                g_isTimeToChangeLevel: %d \
                g_voteStatus & VOTE_IS_FORCED: %d", \
                                                  g_isTimeToRestart, \
                g_isTimeToChangeLevel, \
                g_voteStatus & VOTE_IS_FORCED != 0 );
        
        // winnerVoteMapIndex == g_totalVoteOptions, means the 'Stay Here' option.
        // Then, here we keep the current map or extend current map.
        if( winnerVoteMapIndex == g_totalVoteOptions )
        {
            if( !g_isGameFinalVoting // "stay here" won and the map mustn't be restarted.
                && !g_isTimeToRestart )
            {
                color_print( 0, "^1%L", LANG_PLAYER, "GAL_WINNER_STAY" );
            }
            else if( !g_isGameFinalVoting // "stay here" won and the map must be restarted.
                     && g_isTimeToRestart )
            {
                color_print( 0, "^1%L", LANG_PLAYER, "GAL_WINNER_STAY" );
                
                process_last_round();
            }
            else if( g_isGameFinalVoting ) // "extend map" won
            {
                if( g_isVotingByRounds )
                {
                    color_print( 0, "^1%L", LANG_PLAYER, "GAL_WINNER_EXTEND_ROUND", g_extendmapStepRounds );
                }
                else
                {
                    color_print( 0, "^1%L", LANG_PLAYER, "GAL_WINNER_EXTEND", g_extendmapStepMinutes );
                }
                
                map_extend();
            }
            
            resetRoundEnding();
            
            // no longer is an early vote
            g_voteStatus &= ~VOTE_IS_EARLY;
            g_voteStatus &= ~VOTE_IS_FORCED;
        }
        else // the execution flow gets here when the winner option is not keep/extend map
        {
            setNextMap( g_votingMapNames[ winnerVoteMapIndex ] );
            server_exec();
            
            color_print( 0, "^1%L", LANG_PLAYER, "GAL_NEXTMAP", g_nextMap );
            
            process_last_round();
            
            g_voteStatus |= VOTE_IS_OVER;
        }
    }
    else // the execution flow gets here when anybody voted for next map
    {
        if( !get_pcvar_num( cvar_isExtendmapOrderAllowed ) )
        {
            winnerVoteMapIndex = random_num( 0, g_totalVoteOptions - 1 );
            
            setNextMap( g_votingMapNames[ winnerVoteMapIndex ] );
        }
        
        color_print( 0, "^1%L", LANG_PLAYER, "GAL_WINNER_RANDOM", g_nextMap );
        process_last_round();
        
        g_voteStatus |= VOTE_IS_OVER;
    }
    
    LOGGER( 1, "    ( computeVotes|out ) g_isTimeToRestart: %d, \
            g_isTimeToChangeLevel: %d \
            g_voteStatus & VOTE_IS_FORCED: %d", \
                                         g_isTimeToRestart, \
            g_isTimeToChangeLevel, \
            g_voteStatus & VOTE_IS_FORCED != 0 );
    
    finalizeVoting();
}

/**
 * Restore global variables to is default state. This is to be ready for a new voting.
 */
stock finalizeVoting()
{
    LOGGER( 128, "I AM ENTERING ON finalizeVoting(0)" );
    
    g_isVotingByTimer               = false;
    g_isVotingByRounds              = false;
    g_isRunOffNeedingKeepCurrentMap = false;
    
    // vote is no longer in progress
    g_voteStatus &= ~VOTE_IS_IN_PROGRESS;
    
    // if we were in a runoff mode, get out of it
    g_voteStatus &= ~VOTE_IS_RUNOFF;
    
    // this must be called after 'g_voteStatus &= ~VOTE_IS_RUNOFF' above
    vote_resetStats();
}

stock Float:map_getMinutesElapsed()
{
    LOGGER( 128, "I AM ENTERING ON Float:map_getMinutesElapsed(0)" );
    
    LOGGER( 2, "%32s mp_timelimit: %f", "map_getMinutesElapsed( in/out )", get_pcvar_float( cvar_mp_timelimit ) );
    return get_pcvar_float( cvar_mp_timelimit ) - ( float( get_timeleft() ) / 60.0 );
}

stock map_extend()
{
    LOGGER( 128, "I AM ENTERING ON map_extend(0)" );
    LOGGER( 2, "%32s mp_timelimit: %f  g_rtvMinutesWait: %f  extendmapStep: %d", \
            "map_extend( in )", \
            get_pcvar_float( cvar_mp_timelimit ), g_rtvMinutesWait, g_extendmapStepMinutes );
    
    // reset the "rtv wait" time, taking into consideration the map extension
    if( g_rtvMinutesWait )
    {
        g_rtvMinutesWait += get_pcvar_float( cvar_mp_timelimit );
        g_rtvWaitRounds  += get_pcvar_num( cvar_mp_maxrounds );
    }
    
    saveEndGameLimits();
    
    // do that actual map extension
    if( g_isVotingByRounds )
    {
        new extendmap_step_rounds = g_extendmapStepRounds;
        
        if( g_isMaxroundsExtend )
        {
            set_pcvar_num( cvar_mp_maxrounds, get_pcvar_num( cvar_mp_maxrounds ) + extendmap_step_rounds );
            set_pcvar_num( cvar_mp_winlimit, 0 );
        }
        else
        {
            set_pcvar_num( cvar_mp_maxrounds, 0 );
            set_pcvar_num( cvar_mp_winlimit, get_pcvar_num( cvar_mp_winlimit ) + extendmap_step_rounds );
        }
        
        set_pcvar_float( cvar_mp_timelimit, 0.0 );
    }
    else
    {
        set_pcvar_num( cvar_mp_maxrounds, 0 );
        set_pcvar_num( cvar_mp_winlimit, 0 );
        set_pcvar_float( cvar_mp_timelimit, get_pcvar_float( cvar_mp_timelimit ) + g_extendmapStepMinutes );
    }
    
    server_exec();
    LOGGER( 2, "%32s mp_timelimit: %f  g_rtvMinutesWait: %f  extendmapStep: %d", \
            "map_extend( out )", \
            get_pcvar_float( cvar_mp_timelimit ), g_rtvMinutesWait, g_extendmapStepMinutes );
}

stock saveEndGameLimits()
{
    LOGGER( 128, "I AM ENTERING ON saveEndGameLimits(0)" );
    
    if( !g_isEndGameLimitsChanged )
    {
        g_isEndGameLimitsChanged = true;
        
        g_originalTimelimit = get_pcvar_float( cvar_mp_timelimit );
        g_originalMaxRounds = get_pcvar_num(   cvar_mp_maxrounds );
        g_originalWinLimit  = get_pcvar_num(   cvar_mp_winlimit );
        g_originalFragLimit = get_pcvar_num(   cvar_mp_fraglimit );
    }
}

stock map_isInMenu( map[] )
{
    LOGGER( 128, "I AM ENTERING ON map_isInMenu(1) | map: %s", map );
    
    for( new playerVoteMapChoiceIndex = 0;
         playerVoteMapChoiceIndex < g_totalVoteOptions; ++playerVoteMapChoiceIndex )
    {
        if( equali( map, g_votingMapNames[ playerVoteMapChoiceIndex ] ) )
        {
            return true;
        }
    }
    
    return false;
}

stock isPrefixInMenu( map[] )
{
    LOGGER( 128, "I AM ENTERING ON isPrefixInMenu(1) | map: %s", map );
    
    if( get_pcvar_num( cvar_voteUniquePrefixes ) )
    {
        new junk[ 8 ];
        new possiblePrefix[ 8 ];
        new existingPrefix[ 8 ]; 
        
        strtok( map, possiblePrefix, charsmax( possiblePrefix ), junk, charsmax( junk ), '_', 1 );
        
        for( new playerVoteMapChoiceIndex = 0;
             playerVoteMapChoiceIndex < g_totalVoteOptions; ++playerVoteMapChoiceIndex )
        {
            strtok( g_votingMapNames[ playerVoteMapChoiceIndex ],
                    existingPrefix, charsmax( existingPrefix ),
                    junk, charsmax( junk ),
                    '_', 1 );
            
            if( equali( possiblePrefix, existingPrefix ) )
            {
                return true;
            }
        }
    }
    
    return false;
}

stock map_isTooRecent( map[] )
{
    LOGGER( 128, "I AM ENTERING ON map_isTooRecent(1) | map: %s", map );
    
    if( get_pcvar_num( cvar_recentMapsBannedNumber ) )
    {
        for( new bannedMapIndex = 0; bannedMapIndex < g_recentMapCount; ++bannedMapIndex )
        {
            if( equali( map, g_recentMaps[ bannedMapIndex ] ) )
            {
                return true;
            }
        }
    }
    
    return false;
}

/**
 * This function choose what RTV's type will be used to 'rock the vote'. The types are:
 * 1) Per rounds.
 * 1.1) Is by mp_winlimit expiration proximity?
 * 1.2) Is by mp_maxrounds expiration proximity?
 * 2) Per minutes.
 *
 * These data are used to display the voting menu and proper set the voting flow. This use the
 * default voting type to timer if the rounds ending are disabled.
 */
stock configureRtvVotingType()
{
    LOGGER( 128, "I AM ENTERING ON configureRtvVotingType(0)" );
    
    new minutes_left   = get_timeleft() / 60;
    new maxrounds_left = get_pcvar_num( cvar_mp_maxrounds ) - g_roundsPlayedNumber;
    new winlimit_left  = get_pcvar_num( cvar_mp_winlimit ) - max( g_totalCtWins, g_totalTerroristsWins );
    
    if( ( minutes_left > maxrounds_left
          && maxrounds_left > 0 )
        || ( minutes_left > winlimit_left
             && winlimit_left > 0 ) )
    {
        g_isVotingByRounds = true;
        
        if( maxrounds_left >= winlimit_left )
        {
            g_isMaxroundsExtend = true;
        }
        else
        {
            g_isMaxroundsExtend = false;
        }
    }
}

stock start_rtvVote()
{
    LOGGER( 128, "I AM ENTERING ON start_rtvVote(0)" );
    
    if( get_pcvar_num( cvar_endOnRoundRtv )
        && get_realplayersnum() >= get_pcvar_num( cvar_endOnRoundRtv ) )
    {
        g_isTheLastGameRound = true;
        g_isRtvLastRound  = true;
    }
    else
    {
        g_isTimeToChangeLevel = true;
    }
    
    configureRtvVotingType();
    vote_startDirector( true );
}

public vote_rock( player_id )
{
    LOGGER( 128, "I AM ENTERING ON vote_rock(1) | map: %d", player_id );
    
    // if an early vote is pending, don't allow any rocks
    if( g_voteStatus & VOTE_IS_EARLY )
    {
        color_print( player_id, "^1%L", player_id, "GAL_ROCK_FAIL_PENDINGVOTE" );
        return;
    }
    
    // rocks can only be made if a vote isn't already in progress
    if( g_voteStatus & VOTE_IS_IN_PROGRESS )
    {
        color_print( player_id, "^1%L", player_id, "GAL_ROCK_FAIL_INPROGRESS" );
        return;
    }
    else if( g_voteStatus & VOTE_IS_OVER ) // and if the outcome of the vote hasn't already been determined
    {
        color_print( player_id, "^1%L", player_id, "GAL_ROCK_FAIL_VOTEOVER" );
        return;
    }
    
    if( get_pcvar_num( cvar_rtvWaitAdmin )
        && g_rtvWaitAdminNumber > 0 )
    {
        color_print( player_id, "^1%L", player_id, "GAL_ROCK_WAIT_ADMIN" );
        return;
    }
    
    // if the player is the only one on the server, bring up the vote immediately
    if( get_realplayersnum() == 1 )
    {
        start_rtvVote();
        return;
    }
    
    new Float:minutesElapsed = map_getMinutesElapsed();
    
    // make sure enough time has gone by on the current map
    if( g_rtvMinutesWait
        && minutesElapsed
        && minutesElapsed < g_rtvMinutesWait )
    {
        color_print( player_id, "^1%L", player_id, "GAL_ROCK_FAIL_TOOSOON", floatround( g_rtvMinutesWait - minutesElapsed, floatround_ceil ) );
        
        return;
    }
    else if( g_rtvWaitRounds
             && g_roundsPlayedNumber < g_rtvWaitRounds )
    {
        color_print( player_id, "^1%L", player_id, "GAL_ROCK_FAIL_TOOSOON_ROUNDS", g_rtvWaitRounds - g_roundsPlayedNumber );
        
        return;
    }
    
    // determine how many total rocks are needed
    new rocksNeeded = vote_getRocksNeeded();
    
    // make sure player hasn't already rocked the vote
    if( g_rockedVote[ player_id ] )
    {
        color_print( player_id, "^1%L", player_id, "GAL_ROCK_FAIL_ALREADY", rocksNeeded - g_rockedVoteCount );
        
        rtv_remind( TASKID_REMINDER + player_id );
        return;
    }
    
    // allow the player to rock the vote
    g_rockedVote[ player_id ] = true;
    
    color_print( player_id, "^1%L", player_id, "GAL_ROCK_SUCCESS" );
    
    // make sure the rtv reminder timer has stopped
    if( task_exists( TASKID_REMINDER ) )
    {
        remove_task( TASKID_REMINDER );
    }
    
    // determine if there have been enough rocks for a vote yet
    if( ++g_rockedVoteCount >= rocksNeeded )
    {
        // announce that the vote has been rocked
        color_print( 0, "^1%L", LANG_PLAYER, "GAL_ROCK_ENOUGH" );
        
        // start up the vote director
        start_rtvVote();
    }
    else
    {
        // let the players know how many more rocks are needed
        rtv_remind( TASKID_REMINDER );
        
        if( get_pcvar_num( cvar_rtvReminder ) )
        {
            // initialize the rtv reminder timer to repeat how many
            // rocks are still needed, at regular intervals
            set_task( get_pcvar_float( cvar_rtvReminder ) * 60.0, "rtv_remind", TASKID_REMINDER, _, _, "b" );
        }
    }
}

stock vote_unrockTheVote( player_id )
{
    LOGGER( 128, "I AM ENTERING ON vote_unrockTheVote(1) | player_id: %d", player_id );
    
    if( g_rockedVote[ player_id ] )
    {
        g_rockedVote[ player_id ] = false;
        g_rockedVoteCount--;
        // and such
    }
}

stock vote_getRocksNeeded()
{
    LOGGER( 128, "I AM ENTERING ON vote_getRocksNeeded(0)" );
    return floatround( get_pcvar_float( cvar_rtvRatio ) * float( get_realplayersnum() ), floatround_ceil );
}

public rtv_remind( param )
{
    LOGGER( 128, "I AM ENTERING ON rtv_remind(1) | param: %d", param );
    new player_id = param - TASKID_REMINDER;
    
    // let the players know how many more rocks are needed
    color_print( player_id, "^1%L", LANG_PLAYER, "GAL_ROCK_NEEDMORE", vote_getRocksNeeded() - g_rockedVoteCount );
}

// change to the map
public map_change()
{
    LOGGER( 128, "I AM ENTERING ON map_change(0)" );
    
    // grab the name of the map we're changing to
    new map[ MAX_MAPNAME_LENGHT ];
    get_cvar_string( "amx_nextmap", map, charsmax( map ) );
    
    resetRoundEnding();
    
    // verify we're changing to a valid map
    if( !is_map_valid( map ) )
    {
        // probably admin did something dumb like changed the map time limit below
        // the time remaining in the map, thus making the map over immediately.
        // since the next map is unknown, just restart the current map.
        copy( map, charsmax( map ), g_currentMap );
    }
    
    serverChangeLevel( map );
}

public map_change_stays()
{
    LOGGER( 128, "I AM ENTERING ON map_change_stays(0)" );
    resetRoundEnding();
    
    LOGGER( 1, " ( map_change_stays ) g_currentMap: %s", g_currentMap );
    serverChangeLevel( g_currentMap );
}

stock serverChangeLevel( mapName[] )
{
    LOGGER( 128, "I AM ENTERING ON serverChangeLevel(1) | mapName: %s", mapName );
    
    if( g_isOnMaintenanceMode )
    {
        color_print( 0, "^1%L", LANG_PLAYER, "GAL_CHANGE_MAINTENANCE" );
        restoreOriginalServerMaxSpeed();
        cancelVoting();
    }
    else
    {
    #if AMXX_VERSION_NUM < 183
        server_cmd( "changelevel %s", mapName );
    #else
        engine_changelevel( mapName );
    #endif
    }
}

public cmd_HL1_votemap( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_HL1_votemap(1) | player_id: %d", player_id );
    
    if( get_pcvar_num( cvar_cmdVotemap ) == 0 )
    {
        con_print( player_id, "%L", player_id, "GAL_DISABLED" );
        return PLUGIN_HANDLED;
    }
    
    return PLUGIN_CONTINUE;
}

public cmd_HL1_listmaps( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_HL1_listmaps(1) | player_id: %d", player_id );
    
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
    LOGGER( 128, "I AM ENTERING ON map_listAll(1) | player_id: %d", player_id );
    
    new start;
    new userid;
    new mapPerPage;
    
    new    command         [ 32 ];
    new    paramenter      [ 8 ];
    static lastMapDisplayed[ MAX_MAPNAME_LENGHT ][ 2 ];
    
    // determine if the player has requested a listing before
    userid = get_user_userid( player_id );
    
    if( userid != lastMapDisplayed[ player_id ][ LISTMAPS_USERID ] )
    {
        lastMapDisplayed[ player_id ][ LISTMAPS_USERID ] = 0;
    }
    
    read_argv( 0, command, charsmax( command ) );
    mapPerPage = get_pcvar_num( cvar_listmapsPaginate );
    
    if( mapPerPage )
    {
        if( read_argv( 1, paramenter, charsmax( paramenter ) ) )
        {
            if( paramenter[ 0 ] == '*' )
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
                start = str_to_num( paramenter );
            }
        }
        else
        {
            start = 1;
        }
        
        if( player_id == 0
            && read_argc() == 3
            && read_argv( 2, paramenter, charsmax( paramenter ) ) )
        {
            mapPerPage = str_to_num( paramenter );
        }
    }
    
    if( start < 1 )
    {
        start = 1;
    }
    
    if( start >= g_nominationMapCount )
    {
        start = g_nominationMapCount - 1;
    }
    
    new end = mapPerPage ? start + mapPerPage - 1 : g_nominationMapCount;
    
    if( end > g_nominationMapCount )
    {
        end = g_nominationMapCount;
    }
    
    // this enables us to use 'command *' to get the next group of maps, when paginated
    lastMapDisplayed[ player_id ][ LISTMAPS_LAST ]   = end - 1;
    lastMapDisplayed[ player_id ][ LISTMAPS_USERID ] = userid;
    
    con_print( player_id, "^n----- %L -----", player_id, "GAL_LISTMAPS_TITLE", g_nominationMapCount );
    
    // Second part start
    new map_index;
    new nominator_id;
    
    new mapName    [ MAX_MAPNAME_LENGHT ];
    new nominated  [ MAX_PLAYER_NAME_LENGHT + 32 ];
    new player_name[ MAX_PLAYER_NAME_LENGHT ];
    
    for( map_index = start - 1; map_index < end; map_index++ )
    {
        nominator_id = nomination_getPlayer( map_index );
        
        if( nominator_id )
        {
            GET_USER_NAME( nominator_id, player_name );
            formatex( nominated, charsmax( nominated ), "%L", player_id, "GAL_NOMINATEDBY", player_name );
        }
        else
        {
            nominated[ 0 ] = '^0';
        }
        
        ArrayGetString( g_nominationMapsArray, map_index, mapName, charsmax( mapName ) );
        con_print( player_id, "%3i: %s  %s", map_index + 1, mapName, nominated );
    }
    
    if( mapPerPage
        && mapPerPage < g_nominationMapCount )
    {
        con_print( player_id, "----- %L -----", player_id, "GAL_LISTMAPS_SHOWING",
                start, map_index, g_nominationMapCount );
        
        if( end < g_nominationMapCount )
        {
            con_print( player_id, "----- %L -----", player_id, "GAL_LISTMAPS_MORE",
                    command, end + 1, command );
        }
    }
}

stock con_print( player_id, message[], { Float, Sql, Result, _ }: ... )
{
    LOGGER( 128, "I AM ENTERING ON con_print(...) | player_id: %d, message: %s", player_id, message );
    
    new consoleMessage[ MAX_LONG_STRING ];
    vformat( consoleMessage, charsmax( consoleMessage ), message, 3 );
    
    if( player_id )
    {
        new authid[ 32 ];
        
        get_user_authid( player_id, authid, charsmax( authid ) );
        console_print( player_id, consoleMessage );
        
        return;
    }
    
    server_print( consoleMessage );
}

stock restartEmptyCycle()
{
    LOGGER( 128, "I AM ENTERING ON restartEmptyCycle(0)" );
    
    set_pcvar_num( cvar_isToStopEmptyCycle, 0 );
    remove_task( TASKID_EMPTYSERVER );
}

public client_authorized( player_id )
{
    LOGGER( 128, "I AM ENTERING ON client_authorized(1) | player_id: %d", player_id );
    restartEmptyCycle();
    
    if( get_user_flags( player_id ) & ADMIN_MAP )
    {
        g_rtvWaitAdminNumber++;
    }
}

#if AMXX_VERSION_NUM < 183
    public client_disconnect( player_id )
#else
    public client_disconnected( player_id )
#endif
{
    LOGGER( 128, "I AM ENTERING ON client_disconnected(1) | player_id: %d", player_id );
    
    if( get_user_flags( player_id ) & ADMIN_MAP )
    {
        g_rtvWaitAdminNumber--;
    }
    
    vote_unrockTheVote( player_id );
    
    if( get_pcvar_num( cvar_unnominateDisconnected ) )
    {
        unnominatedDisconnectedPlayer( player_id );
    }
    
    isToHandleRecentlyEmptyServer();
}

stock unnominatedDisconnectedPlayer( player_id )
{
    LOGGER( 128, "I AM ENTERING ON unnominatedDisconnectedPlayer(1) | player_id: %d", player_id );
    
    new mapIndex;
    new nominationCount;
    new maxPlayerNominations;
    new copiedChars;
    
    new mapName      [ MAX_MAPNAME_LENGHT ];
    new nominatedMaps[ MAX_COLOR_MESSAGE ];
    
    // cancel player's nominations
    maxPlayerNominations = min( get_pcvar_num( cvar_nomPlayerAllowance ), MAX_NOMINATION_COUNT );
    
    for( new nominationIndex = 0; nominationIndex < maxPlayerNominations; ++nominationIndex )
    {
        mapIndex = getPlayerNominationMapIndex( player_id, nominationIndex );
        
        if( mapIndex >= 0 )
        {
            ++nominationCount;
            
            setPlayerNominationMapIndex( player_id, nominationIndex, -1 );
            ArrayGetString( g_nominationMapsArray, mapIndex, mapName, charsmax( mapName ) );
            
            if( copiedChars )
            {
                copiedChars += copy( nominatedMaps[ copiedChars ], charsmax( nominatedMaps ) - copiedChars, ", " );
            }
            
            copiedChars += copy( nominatedMaps[ copiedChars ], charsmax( nominatedMaps ) - copiedChars, mapName );
        }
    }
    
    if( nominationCount )
    {
        // inform the masses that the maps are no longer nominated
        nomination_announceCancellation( nominatedMaps );
    }
}

/**
 * If the empty cycle feature was initialized by 'inicializeEmptyCycleFeature()' function, this
 * function to start the empty cycle map change system, when the last server player disconnect.
 */
stock isToHandleRecentlyEmptyServer()
{
    LOGGER( 128, "I AM ENTERING ON isToHandleRecentlyEmptyServer(0)" );
    new playersCount = get_realplayersnum();
    
    LOGGER( 128, "I AM ENTERING ON isToHandleRecentlyEmptyServer(0) | mp_timelimit: %d, \
            g_originalTimelimit: %d, playersCount: %d", \
            get_pcvar_float( cvar_mp_timelimit ), g_originalTimelimit, playersCount );
    
    if( playersCount == 0 )
    {
        if( g_originalTimelimit != get_pcvar_float( cvar_mp_timelimit ) )
        {
            // it's possible that the map has been extended at least once. that
            // means that if someone comes into the server, the time limit will
            // be the extended time limit rather than the normal time limit. bad.
            // reset the original time limit
            map_restoreEndGameCvars();
        }
        
        // if it is utilizing "empty server" feature, to start it.
        if( g_isUsingEmptyCycle
            && g_emptyCycleMapsNumber )
        {
            startEmptyCycleCountdown();
        }
    }
    
    LOGGER( 2, "I AM EXITING ON isToHandleRecentlyEmptyServer(0) | g_isUsingEmptyCycle = %d, \
            g_emptyCycleMapsNumber = %d", g_isUsingEmptyCycle, g_emptyCycleMapsNumber );
}

/**
 * Inicializes the empty cycle server feature at map starting.
 */
public inicializeEmptyCycleFeature()
{
    LOGGER( 128, "I AM ENTERING ON inicializeEmptyCycleFeature(0)" );
    
    if( get_realplayersnum() == 0 )
    {
        if( get_pcvar_num( cvar_isToStopEmptyCycle ) )
        {
            configureNextEmptyCycleMap();
        }
        else
        {
            startEmptyCycleCountdown();
        }
    }
    
    g_isUsingEmptyCycle = true;
}

stock startEmptyCycleCountdown()
{
    LOGGER( 128, "I AM ENTERING ON startEmptyCycleCountdown(0)" );
    new waitMinutes = get_pcvar_num( cvar_emptyWait );
    
    if( waitMinutes )
    {
        set_task( float( waitMinutes * 60 ), "startEmptyCycleSystem", TASKID_EMPTYSERVER );
    }
}

/**
 * Set the next map from the empty cycle list, if and only if, it is not already configured.
 *
 * @return -1     if the current map is not on the empty cycle list. Otherwise anything else.
 */
stock configureNextEmptyCycleMap()
{
    LOGGER( 128, "I AM ENTERING ON configureNextEmptyCycleMap(0)" );
    new mapIndex;
    
    new nextMap          [ MAX_MAPNAME_LENGHT ];
    new lastEmptyCycleMap[ MAX_MAPNAME_LENGHT ];
    
    mapIndex = map_getNext( g_emptyCycleMapsList, g_currentMap, nextMap );
    
    if( !g_isEmptyCycleMapConfigured )
    {
        g_isEmptyCycleMapConfigured = true;
        
        getLastEmptyCycleMap( lastEmptyCycleMap );
        map_getNext( g_emptyCycleMapsList, lastEmptyCycleMap, nextMap );
        
        setLastEmptyCycleMap( nextMap );
        setNextMap( nextMap );
    }
    
    return mapIndex;
}

stock getLastEmptyCycleMap( lastEmptyCycleMap[ MAX_MAPNAME_LENGHT ] )
{
    LOGGER( 128, "I AM ENTERING ON getLastEmptyCycleMap(1) | lastEmptyCycleMap: %s", lastEmptyCycleMap );
    
    new lastEmptyCycleMapFile;
    new lastEmptyCycleMapFilePath[ MAX_FILE_PATH_LENGHT ];
    
    formatex( lastEmptyCycleMapFilePath, charsmax( lastEmptyCycleMapFilePath ), "%s/%s", g_dataDirPath, LAST_EMPTY_CYCLE_FILE_NAME );
    lastEmptyCycleMapFile = fopen( lastEmptyCycleMapFilePath, "rt" );
    
    if( lastEmptyCycleMapFile )
    {
        fgets( lastEmptyCycleMapFile, lastEmptyCycleMap, charsmax( lastEmptyCycleMap ) );
    }
}

stock setLastEmptyCycleMap( lastEmptyCycleMap[ MAX_MAPNAME_LENGHT ] )
{
    LOGGER( 128, "I AM ENTERING ON setLastEmptyCycleMap(1) | lastEmptyCycleMap: %s", lastEmptyCycleMap );
    
    new lastEmptyCycleMapFile;
    new lastEmptyCycleMapFilePath[ MAX_FILE_PATH_LENGHT ];
    
    formatex( lastEmptyCycleMapFilePath, charsmax( lastEmptyCycleMapFilePath ), "%s/%s", g_dataDirPath, LAST_EMPTY_CYCLE_FILE_NAME );
    lastEmptyCycleMapFile = fopen( lastEmptyCycleMapFilePath, "wt" );
    
    if( lastEmptyCycleMapFile )
    {
        fprintf( lastEmptyCycleMapFile, "%s", lastEmptyCycleMap );
        fclose( lastEmptyCycleMapFile );
    }
}

public startEmptyCycleSystem()
{
    LOGGER( 128, "I AM ENTERING ON startEmptyCycleSystem(0)" );
    
    // stop this system at the next map, due we already be at a popular map
    set_pcvar_num( cvar_isToStopEmptyCycle, 1 );
    
    // if the current map isn't part of the empty cycle,
    // immediately change to next map that is
    if( configureNextEmptyCycleMap() == -1 )
    {
        map_change();
    }
}

/**
 * Given a mapArray list and the currentMap, calculates the next map after the currentMap provided at
 * the mapArray. The map list to start on 0 as the first map.
 *
 * @param nextMap       the string pointer which will receive the next map
 * @param currentMap    the string printer to the current map name
 * @param mapArray      the dynamic array with the map list to search
 *
 * @return mapIndex     the nextMap index in the mapArray. -1 if not found a nextMap.
 */
stock map_getNext( Array:mapArray, currentMap[], nextMap[ MAX_MAPNAME_LENGHT ] )
{
    LOGGER( 128, "I AM ENTERING ON cmd_HL1_votemap(3) | currentMap: %s, nextMap: %s", currentMap, nextMap );
    new thisMap[ MAX_MAPNAME_LENGHT ];
    
    new nextmapIndex = 0;
    new returnValue  = -1;
    new mapCount     = ArraySize( mapArray );
    
    for( new mapIndex = 0; mapIndex < mapCount; mapIndex++ )
    {
        ArrayGetString( mapArray, mapIndex, thisMap, charsmax( thisMap ) );
        
        if( equali( currentMap, thisMap ) )
        {
            if( mapIndex == mapCount - 1 )
            {
                nextmapIndex = 0;
            }
            else
            {
                nextmapIndex = mapIndex + 1;
            }
            
            returnValue = nextmapIndex;
            break;
        }
    }
    
    if( mapCount > 0 )
    {
        ArrayGetString( mapArray, nextmapIndex, nextMap, charsmax( nextMap ) );
    }
    else
    {
        log_amx( "WARNING: Your 'mapcyclefile' server variable '%s' is invalid!", g_mapCycleFilePath );
        LOGGER( 1, "WARNING: Your 'mapcyclefile' server variable '%s' is invalid!", g_mapCycleFilePath );
        
        copy( nextMap, charsmax( nextMap ), "your_mapcycle_file_is_empty" );
    }
    
    return returnValue;
}

public client_putinserver( player_id )
{
    LOGGER( 128, "I AM ENTERING ON client_putinserver(1) | player_id: %d", player_id );
    
    if( ( g_voteStatus & VOTE_IS_EARLY )
        && !is_user_bot( player_id )
        && !is_user_hltv( player_id ) )
    {
        set_task( 20.0, "srv_announceEarlyVote", player_id );
    }
}

public srv_announceEarlyVote( player_id )
{
    LOGGER( 128, "I AM ENTERING ON srv_announceEarlyVote(1) | player_id: %d", player_id );
    
    if( is_user_connected( player_id ) )
    {
        color_print( player_id, "^4%L", player_id, "GAL_VOTE_EARLY" );
    }
}

stock nomination_announceCancellation( nominations[] )
{
    LOGGER( 128, "I AM ENTERING ON nomination_announceCancellation(1) | nominations: %s", nominations );
    color_print( 0, "^1%L", LANG_PLAYER, "GAL_CANCEL_SUCCESS", nominations );
}

stock nomination_clearAll()
{
    LOGGER( 128, "I AM ENTERING ON nomination_clearAll(0)" );
    
    TrieClear( g_nominationMapsTrie );
    TrieClear( g_playersNominations );
    
    g_nominationCount = 0;
}

stock map_announceNomination( player_id, map[] )
{
    LOGGER( 128, "I AM ENTERING ON map_announceNomination(2) | player_id: %d, map: %s", player_id, map );
    new player_name[ MAX_PLAYER_NAME_LENGHT ];
    
    GET_USER_NAME( player_id, player_name );
    color_print( 0, "^1%L", LANG_PLAYER, "GAL_NOM_SUCCESS", player_name, map );
}

public sort_stringsi( const elem1[], const elem2[], const array[], data[], data_size )
{
    LOGGER( 128, "I AM ENTERING ON sort_stringsi(5) | elem1: %s, elem2: %s, array: %s, data: %s, \
            data_size: %d",                           elem1,     elem2,     array,     data, \
            data_size );
    
    return strcmp( elem1, elem2, 1 );
}

stock get_realplayersnum()
{
    LOGGER( 128, "I AM ENTERING ON get_realplayersnum(0)" );
    
    new playersCount;
    new players[ MAX_PLAYERS ];
    
    get_players( players, playersCount, "ch" );

#if DEBUG_LEVEL & DEBUG_LEVEL_FAKE_VOTES
    return 1;
#else
    return playersCount;
#endif
}

stock percent( is, of )
{
    LOGGER( 128, "I AM ENTERING ON percent(2) | is: %d, of: %d", is, of );
    return ( of != 0 ) ? floatround( floatmul( float( is ) / float( of ), 100.0 ) ) : 0;
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
 *         color_print( g_colored_player_id, "^1%L %L %L",
 *                 g_colored_player_id, "LANG_A", g_colored_player_id, "LANG_B",
 *                 g_colored_player_id, "LANG_C", any_variable_used_on_LANG_C )
 *     }
 * #else
 *     color_print( 0, "^1%L %L %L", LANG_PLAYER, "LANG_A",
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
stock color_print( player_id, message[], any: ... )
{
    LOGGER( 128, "I AM ENTERING ON color_print(...) | player_id: %d, message: %s", player_id, message );
    
    new formated_message[ MAX_COLOR_MESSAGE ];
    formated_message[ 0 ] = '^0';
    
    if( g_isColorChatSupported
        && g_isColoredChatEnabled )
    {
    #if AMXX_VERSION_NUM < 183
        if( player_id )
        {
            vformat( formated_message, charsmax( formated_message ), message, 3 );
            LOGGER( 64, "( in ) Player_Id: %d, Chat printed: %s", player_id, formated_message );
            
            PRINT_COLORED_MESSAGE( player_id, formated_message );
        }
        else
        {
            new playersCount;
            new players[ MAX_PLAYERS ];
            
            get_players( players, playersCount, "ch" );
            
            // Figure out if at least 1 player is connected
            // so we don't execute useless code
            if( !playersCount )
            {
                LOGGER( 64, "   !playersCount. playersCount = %d", playersCount );
                return;
            }
            
            new player_id;
            new string_index;
            new argument_index;
            new multi_lingual_constants_number;
            new params_number;
            new Array:multi_lingual_indexes_array;
            
            multi_lingual_indexes_array    = ArrayCreate();
            params_number                  = numargs();
            multi_lingual_constants_number = 0;
            
            LOGGER( 64, "   playersCount: %d, params_number: %d", playersCount, params_number );
            
            if( params_number > 3 ) // ML can be used
            {
                for( argument_index = 2; argument_index < params_number; argument_index++ )
                {
                    LOGGER( 64, "   argument_index: %d, getarg( argument_index ): %s / %d", \
                            argument_index, getarg( argument_index ), getarg( argument_index ) );
                    
                    // retrieve original param value and check if it's LANG_PLAYER value
                    if( getarg( argument_index ) == LANG_PLAYER )
                    {
                        string_index = 0;
                        
                        // as LANG_PLAYER == -1, check if next param string is a registered language translation
                        while( ( formated_message[ string_index ] =
                                     getarg( argument_index + 1, string_index++ ) ) )
                        {
                        }
                        formated_message[ string_index ] = '^0';
                        
                        LOGGER( 64, "   Player_Id: %d, formated_message: %s, \
                                GetLangTransKey( formated_message ) != TransKey_Bad: %d, \
                                multi_lingual_constants_number: %d, string_index: %d", \
                                player_id, formated_message, \
                                GetLangTransKey( formated_message ) != TransKey_Bad, \
                                multi_lingual_constants_number, string_index );
                        
                        if( GetLangTransKey( formated_message ) != TransKey_Bad )
                        {
                            // Store that argument as LANG_PLAYER so we can alter it later
                            ArrayPushCell( multi_lingual_indexes_array, argument_index++ );
                            
                            // Update ML array, so we'll know 1st if ML is used,
                            // 2nd how many arguments we have to change
                            multi_lingual_constants_number++;
                        }
                        
                        LOGGER( 64, "   argument_index (after ArrayPushCell): %d", argument_index );
                    }
                }
            }
            
            LOGGER( 64, "   multi_lingual_constants_number: %d", multi_lingual_constants_number );
            
            for( --playersCount; playersCount >= 0; playersCount-- )
            {
                player_id = players[ playersCount ];
                
                if( multi_lingual_constants_number )
                {
                    for( argument_index = 0; argument_index < multi_lingual_constants_number; argument_index++ )
                    {
                        LOGGER( 64, "   argument_index: %d, player_id: %d, \
                                ArrayGetCell( %d, %d ): %d", \
                                argument_index, player_id, \
                                multi_lingual_indexes_array, argument_index, \
                                ArrayGetCell( multi_lingual_indexes_array, argument_index ) );
                        
                        // Set all LANG_PLAYER args to player index ( = player_id )
                        // so we can format the text for that specific player
                        setarg( ArrayGetCell( multi_lingual_indexes_array, argument_index ), _, player_id );
                    }
                }
                vformat( formated_message, charsmax( formated_message ), message, 3 );
                
                LOGGER( 64, "( in ) Player_Id: %d, Chat printed: %s", player_id, formated_message );
                PRINT_COLORED_MESSAGE( player_id, formated_message );
            }
            
            ArrayDestroy( multi_lingual_indexes_array );
        }
    #else
        vformat( formated_message, charsmax( formated_message ), message, 3 );
        LOGGER( 64, "( in ) Player_Id: %d, Chat printed: %s", player_id, formated_message );
        
        client_print_color( player_id, print_team_default, formated_message );
    #endif
    }
    else
    {
        vformat( formated_message, charsmax( formated_message ), message, 3 );
        LOGGER( 64, "( in ) Player_Id: %d, Chat printed: %s", player_id, formated_message );
        
        REMOVE_COLOR_TAGS( formated_message );
        client_print( player_id, print_chat, formated_message );
    }
    LOGGER( 64, "( out ) Player_Id: %d, Chat printed: %s", player_id, formated_message );
}

/**
 * ConnorMcLeod's [Dyn Native] ColorChat v0.3.2 (04 jul 2013) register_dictionary_colored function:
 *   <a href="https://forums.alliedmods.net/showthread.php?p=851160">ColorChat v0.3.2</a>
 *
 * @param dictionaryFile the dictionary file name including its file extension.
 */
stock register_dictionary_colored( const dictionaryFile[] )
{
    LOGGER( 128, "I AM ENTERING ON register_dictionary_colored(1) | dictionaryFile: %s", dictionaryFile );
    
    if( !register_dictionary( dictionaryFile ) )
    {
        LOGGER( 1, "    Returning 0 on if( !register_dictionary(%s) )", dictionaryFile );
        return 0;
    }
    
    new dictionaryFilePath[ MAX_FILE_PATH_LENGHT ];
    
    get_localinfo( "amxx_datadir", dictionaryFilePath, charsmax( dictionaryFilePath ) );
    formatex( dictionaryFilePath, charsmax( dictionaryFilePath ), "%s/lang/%s", dictionaryFilePath, dictionaryFile );
    
    // DO NOT SEPARE/SPLIT THIS DECLARATION in: new var; var = fopen... or it can crash some servers.
    new dictionaryFile = fopen( dictionaryFilePath, "rt" );
    
    if( !dictionaryFile )
    {
        log_amx( "Failed to open %s", dictionaryFilePath );
        LOGGER( 1, "    Returning 0 on if( !dictionaryFile ), Failed to open: %s", dictionaryFilePath );
        
        return 0;
    }
    
    new TransKey:iKey;
    
    new szBuffer     [ 512 ];
    new szLang       [ 3 ];
    new szKey        [ 64 ];
    new szTranslation[ MAX_LONG_STRING ];
    
    while( !feof( dictionaryFile ) )
    {
        fgets( dictionaryFile, szBuffer, charsmax( szBuffer ) );
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
                INSERT_COLOR_TAGS( szTranslation );
                AddTranslation( szLang, iKey, szTranslation[ 2 ] );
            }
        }
    }
    
    fclose( dictionaryFile );
    return 1;
}

public map_restoreEndGameCvars()
{
    LOGGER( 128 + 2, "I AM ENTERING ON map_restoreEndGameCvars(0) | mp_timelimit: %f, \
            g_originalTimelimit: %f", get_pcvar_float( cvar_mp_timelimit ), g_originalTimelimit );
    
    if( g_isEndGameLimitsChanged )
    {
        server_cmd( "mp_timelimit %f", g_originalTimelimit );
        server_cmd( "mp_maxrounds %d", g_originalMaxRounds );
        server_cmd( "mp_winlimit %d",  g_originalWinLimit );
        server_cmd( "mp_fraglimit %d", g_originalFragLimit );
        
        // restore to the original/right values
        g_rtvMinutesWait = get_pcvar_float( cvar_rtvMinutesWait );
        g_rtvWaitRounds  = get_pcvar_num( cvar_rtvWaitRounds );
        
        server_exec();
        g_isEndGameLimitsChanged = false;
    }
    
    restoreOriginalServerMaxSpeed();
    LOGGER( 2, "I AM EXITING ON map_restoreEndGameCvars(0) | mp_timelimit: %f, \
            g_originalTimelimit: %f", get_pcvar_float( cvar_mp_timelimit ), g_originalTimelimit );
}

stock restoreOriginalServerMaxSpeed()
{
    LOGGER( 128, "I AM ENTERING ON restoreOriginalServerMaxSpeed(0)" );
    
    if( g_original_sv_maxspeed )
    {
        set_pcvar_float( cvar_sv_maxspeed, g_original_sv_maxspeed );
        g_original_sv_maxspeed = 0.0;
    }
}

/**
 * Immediately stops any vote in progress.
 */
stock cancelVoting( bool:isToDoubleReset = false )
{
    LOGGER( 128, "I AM ENTERING ON cancelVoting(1) | isToDoubleReset: %d", isToDoubleReset );
    
    remove_task( TASKID_START_VOTING_BY_ROUNDS );
    remove_task( TASKID_START_VOTING_BY_TIMER );
    remove_task( TASKID_DELETE_USERS_MENUS );
    remove_task( TASKID_VOTE_DISPLAY );
    remove_task( TASKID_PREVENT_INFITY_GAME );
    remove_task( TASKID_DBG_FAKEVOTES );
    remove_task( TASKID_VOTE_HANDLEDISPLAY );
    remove_task( TASKID_VOTE_EXPIRE );
    remove_task( TASKID_VOTE_STARTDIRECTOR );
    remove_task( TASKID_PENDING_VOTE_COUNTDOWN );
    remove_task( TASKID_MAP_CHANGE );
    remove_task( TASKID_PROCESS_LAST_ROUND );
    remove_task( TASKID_SHOW_LAST_ROUND_HUD );
    remove_task( TASKID_FINISH_GAME_WITH_HALF_TIME );
    
    finalizeVoting();
    resetRoundEnding();
    delete_users_menus( isToDoubleReset );
    
    g_voteStatus = 0;
}

/**
 * To prepare for a new runoff voting or partially to prepare for a complete new voting. If it is
 * not a runoff voting, 'finalizeVoting()' must be called before this.
 */
public vote_resetStats()
{
    LOGGER( 128, "I AM ENTERING ON vote_resetStats(0)" );
    
    g_voteStatusClean[ 0 ] = '^0';
    g_totalVoteOptions     = 0;
    g_totalVotesCounted    = 0;
    g_pendingVoteCountdown = 7;
    
    arrayset( g_arrayOfMapsWithVotesNumber, 0, sizeof g_arrayOfMapsWithVotesNumber );
    
    // reset everyones' rocks.
    g_rockedVoteCount = 0;
    arrayset( g_rockedVote, false, sizeof g_rockedVote );
    
    // reset everyones' votes
    arrayset( g_isPlayerVoted, true, sizeof g_isPlayerVoted );
    
    if( !( g_voteStatus & VOTE_IS_RUNOFF ) )
    {
        arrayset( g_isPlayerParticipating, true, sizeof g_isPlayerParticipating );
    }
    
    arrayset( g_isPlayerCancelledVote, false, sizeof g_isPlayerCancelledVote );
    arrayset( g_answeredForEndOfMapVote, false, sizeof g_answeredForEndOfMapVote );
    arrayset( g_isPlayerSeeingTheVoteMenu, false, sizeof g_isPlayerSeeingTheVoteMenu );
    
    arrayset( g_playerVotedOption, 0, sizeof g_playerVotedOption );
    arrayset( g_playerVotedWeight, 0, sizeof g_playerVotedWeight );
}

stock delete_users_menus( bool:isToDoubleReset )
{
    LOGGER( 128, "I AM ENTERING ON delete_users_menus(1) | isToDoubleReset: %d", isToDoubleReset );
    
    new menu_id;
    new player_id;
    new playersCount;
    new menukeys_unused;
    
    new players       [ MAX_PLAYERS ];
    new failureMessage[ 128 ];
    
    get_players( players, playersCount, "ch" );
    
    if( isToDoubleReset )
    {
        set_task( 6.0, "vote_resetStats", TASKID_DELETE_USERS_MENUS );
    }
    
    for( new player_index; player_index < playersCount; ++player_index )
    {
        player_id = players[ player_index ];
        get_user_menu( player_id, menu_id, menukeys_unused );
        
        if( menu_id == g_chooseMapMenuId
            || menu_id == g_chooseMapQuestionMenuId )
        {
            formatex( failureMessage, charsmax( failureMessage ), "%L", player_id, "GAL_VOTE_ENDED" );
            show_menu( player_id, menukeys_unused, "Voting canceled!", isToDoubleReset ? 5 : 1, CHOOSE_MAP_MENU_NAME );
        }
    }
}

// ################################## AMX MOD X NEXTMAP PLUGIN ###################################

public nextmap_plugin_init()
{
    LOGGER( 128, "I AM ENTERING ON nextmap_plugin_init(0)" );
    pause( "acd", "nextmap.amxx" );
    
    register_dictionary( "nextmap.txt" );
    register_event( "30", "changeMap", "a" );
    
    register_clcmd( "say nextmap", "sayNextMap", 0, "- displays nextmap" );
    register_clcmd( "say currentmap", "sayCurrentMap", 0, "- display current map" );
    
    g_cvar_amx_nextmap     = register_cvar( "amx_nextmap", "", FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_SPONLY );
    g_cvar_mp_chattime     = get_cvar_pointer( "mp_chattime" );
    g_cvar_mp_friendlyfire = get_cvar_pointer( "mp_friendlyfire" );
    
    if( g_cvar_mp_friendlyfire )
    {
        register_clcmd( "say ff", "sayFFStatus", 0, "- display friendly fire status" );
    }
    
    get_mapname( g_currentMapName, charsmax( g_currentMapName ) );
    
    new mapcycleFilePath       [ MAX_FILE_PATH_LENGHT ];
    new mapcycleCurrentIndex   [ MAX_MAPNAME_LENGHT ];
    new tockenMapcycleAndPosion[ MAX_MAPNAME_LENGHT + MAX_FILE_PATH_LENGHT ];
    
    get_localinfo( "lastmapcycle", tockenMapcycleAndPosion, charsmax( tockenMapcycleAndPosion ) );
    
    parse( tockenMapcycleAndPosion,
            mapcycleFilePath, charsmax( mapcycleFilePath ),
            mapcycleCurrentIndex, charsmax( mapcycleCurrentIndex ) );
    
    get_cvar_string( "mapcyclefile", g_mapCycleFilePath, charsmax( g_mapCycleFilePath ) );
    
    if( !equali( g_mapCycleFilePath, mapcycleFilePath ) )
    {
        g_nextMapCyclePosition = 0;    // mapcyclefile has been changed - go from first
    }
    else
    {
        g_nextMapCyclePosition = str_to_num( mapcycleCurrentIndex );
    }
    readMapCycle( g_mapCycleFilePath, g_nextMapName, charsmax( g_nextMapName ) );
    
    set_pcvar_string( g_cvar_amx_nextmap, g_nextMapName );
    saveCurrentMapCycleSetting();
}

/**
 * The variable 'g_nextMapCyclePosition' is updated at 'handleServerStart()', to update the
 * new settings.
 */
stock saveCurrentMapCycleSetting()
{
    LOGGER( 128, "I AM ENTERING ON saveCurrentMapCycleSetting(0)" );
    new tockenMapcycleAndPosion[ MAX_MAPNAME_LENGHT + MAX_FILE_PATH_LENGHT ];
    
    formatex( tockenMapcycleAndPosion, charsmax( tockenMapcycleAndPosion ),
            "%s %d",
            g_mapCycleFilePath, g_nextMapCyclePosition );
    
    set_localinfo( "lastmapcycle", tockenMapcycleAndPosion ); // save lastmapcycle settings
}

getNextMapName( szArg[], iMax )
{
    LOGGER( 128, "I AM ENTERING ON getNextMapName(2) | szArg: %s, iMax: %d", szArg, iMax );
    new len = get_pcvar_string( g_cvar_amx_nextmap, szArg, iMax );
    
    if( ValidMap( szArg ) )
    {
        return len;
    }
    
    len = copy( szArg, iMax, g_nextMapName );
    set_pcvar_string( g_cvar_amx_nextmap, g_nextMapName );
    
    return len;
}

public sayNextMap()
{
    LOGGER( 128, "I AM ENTERING ON sayNextMap(0)" );
    
    if( get_pcvar_num( cvar_nextMapChangeAnnounce )
        && get_pcvar_num( cvar_endOfMapVote )
        && !( g_voteStatus & VOTE_IS_OVER ) )
    {
        if( g_voteStatus & VOTE_IS_IN_PROGRESS )
        {
            color_print( 0, "^1%L %L", LANG_PLAYER, "NEXT_MAP", LANG_PLAYER, "GAL_NEXTMAP_VOTING" );
        }
        else
        {
            color_print( 0, "^1%L %L", LANG_PLAYER, "NEXT_MAP", LANG_PLAYER, "GAL_NEXTMAP_UNKNOWN" );
        }
    }
    else
    {
        color_print( 0, "^1%L ^4%s", LANG_PLAYER, "NEXT_MAP", g_nextMap );
    }
    
    LOGGER( 1, "( sayNextMap ) %L %s, cvar_endOfMapVote: %d, cvar_nextMapChangeAnnounce: %d", \
            LANG_SERVER, "NEXT_MAP", g_nextMap, \
            get_pcvar_num( cvar_endOfMapVote ), \
            get_pcvar_num( cvar_nextMapChangeAnnounce ) );
    
    return PLUGIN_HANDLED;
}

public sayCurrentMap()
{
    LOGGER( 128, "I AM ENTERING ON sayCurrentMap(0)" );
    client_print( 0, print_chat, "%L: %s", LANG_PLAYER, "PLAYED_MAP", g_currentMapName );
}

public sayFFStatus()
{
    LOGGER( 128, "I AM ENTERING ON sayFFStatus(0)" );
    
    client_print( 0, print_chat, "%L: %L",
            LANG_PLAYER, "FRIEND_FIRE",
            LANG_PLAYER, get_pcvar_num( g_cvar_mp_friendlyfire ) ? "ON" : "OFF" );
}

public delayedChange( param[] )
{
    LOGGER( 128, "I AM ENTERING ON delayedChange(1) | param: %s", param );
    
    if( g_cvar_mp_chattime )
    {
        set_pcvar_float( g_cvar_mp_chattime, get_pcvar_float( g_cvar_mp_chattime ) - 2.0 );
    }
    
    serverChangeLevel( param );
}

public changeMap()
{
    LOGGER( 128, "I AM ENTERING ON changeMap(0)" );
    
    new Float:chattime;
    new       nextmap_name[ MAX_MAPNAME_LENGHT ]; 
    
    // mp_chattime defaults to 10 in other mods
    chattime = g_cvar_mp_chattime ? get_pcvar_float( g_cvar_mp_chattime ) : 10.0;
    
    if( g_cvar_mp_chattime )
    {
        set_pcvar_float( g_cvar_mp_chattime, chattime + 2.0 ); // make sure mp_chattime is long
    }
    
    new len = getNextMapName( nextmap_name, charsmax( nextmap_name ) ) + 1;
    set_task( chattime, "delayedChange", 0, nextmap_name, len ); // change with 1.5 sec. delay
}

stock bool:ValidMap( mapname[] )
{
    LOGGER( 128, "I AM ENTERING ON ValidMap(1) | mapname: %s", mapname );
    
    if( is_map_valid( mapname ) )
    {
        return true;
    }
    
    // If the is_map_valid check failed, check the end of the string
    new len = strlen( mapname ) - 4;
    
    // The mapname was too short to possibly house the .bsp extension
    if( len < 0 )
    {
        return false;
    }
    
    if( equali( mapname[ len ], ".bsp" ) )
    {
        // If the ending was .bsp, then cut it off.
        // the string is by reference, so this copies back to the loaded text.
        mapname[ len ] = '^0';
        
        // recheck
        if( is_map_valid( mapname ) )
        {
            return true;
        }
    }
    
    return false;
}

readMapCycle( mapcycleFilePath[], szNext[], iNext )
{
    LOGGER( 128, "I AM ENTERING ON mapcycleFilePath(3) | mapcycleFilePath: %s, szNext: %s, iNext: %d", \
                                                         mapcycleFilePath,     szNext,     iNext );
    new b;
    new szBuffer[ MAX_MAPNAME_LENGHT ];
    new szFirst[ MAX_MAPNAME_LENGHT ];
    
    new i     = 0;
    new iMaps = 0;
    
    if( file_exists( mapcycleFilePath ) )
    {
        while( read_file( mapcycleFilePath, i++, szBuffer, charsmax( szBuffer ), b ) )
        {
            if( !ValidMap( szBuffer ) )
            {
                continue;
            }
            
            if( !iMaps )
            {
                copy( szFirst, charsmax( szFirst ), szBuffer );
            }
            
            if( ++iMaps > g_nextMapCyclePosition )
            {
                copy( szNext, iNext, szBuffer );
                g_nextMapCyclePosition = iMaps;
                
                return;
            }
        }
    }
    
    if( !iMaps )
    {
        log_amx( "WARNING: Couldn't find a valid map or the file doesn't exist (file ^"%s^")", mapcycleFilePath );
        copy( szNext, iNext, g_currentMapName );
    }
    else
    {
        copy( szNext, iNext, szFirst );
    }
    
    g_nextMapCyclePosition = 1;
}



// ################################## BELOW HERE ONLY GOES DEBUG/TEST CODE ###################################
#if DEBUG_LEVEL & DEBUG_LEVEL_FAKE_VOTES
    public create_fakeVotes()
    {
        LOGGER( 128, "I AM ENTERING ON create_fakeVotes(0)" );
        
        if( g_voteStatus & VOTE_IS_RUNOFF )
        {
            g_arrayOfMapsWithVotesNumber[ 0 ] += 2;     // choice 1
            g_arrayOfMapsWithVotesNumber[ 1 ] += 2;     // choice 2
            
            g_totalVotesCounted = g_arrayOfMapsWithVotesNumber[ 0 ] + g_arrayOfMapsWithVotesNumber[ 1 ];
        }
        else
        {
            g_arrayOfMapsWithVotesNumber[ 0 ] += 0;     // map 1
            g_arrayOfMapsWithVotesNumber[ 1 ] += 3;     // map 2
            g_arrayOfMapsWithVotesNumber[ 2 ] += 0;     // map 3
            g_arrayOfMapsWithVotesNumber[ 3 ] += 0;     // map 4
            g_arrayOfMapsWithVotesNumber[ 4 ] += 0;     // map 5
            
            if( g_isExtendmapAllowStay || g_isGameFinalVoting )
            {
                g_arrayOfMapsWithVotesNumber[ 5 ] += 3;    // extend option
            }
            
            g_totalVotesCounted = g_arrayOfMapsWithVotesNumber[ 0 ] + g_arrayOfMapsWithVotesNumber[ 1 ] +
                                  g_arrayOfMapsWithVotesNumber[ 2 ] + g_arrayOfMapsWithVotesNumber[ 3 ] +
                                  g_arrayOfMapsWithVotesNumber[ 4 ] + g_arrayOfMapsWithVotesNumber[ 5 ];
        }
    }
#endif



#if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST
    
    stock configureTheUnitTests()
    {
        LOGGER( 128, "I AM ENTERING ON configureTheUnitTests(0)" );
        
        g_tests_failure_ids     = ArrayCreate( 1 );
        g_tests_failure_reasons = ArrayCreate( MAX_LONG_STRING );
        g_tests_idsAndNames     = ArrayCreate( MAX_SHORT_STRING );
        
        // delay needed to wait the 'server.cfg' run to load its saved cvars
        if( !get_cvar_num( "gal_server_starting" ) )
        {
            set_task( 2.0, "runTests" );
        }
        else
        {
            print_logger( "" );
            print_logger( "    The Unit Tests are going to run only after the first server start." );
            print_logger( "    gal_server_starting: %d", get_cvar_num( "gal_server_starting" ) );
            print_logger( "" );
        }
    }
    
    /**
     * This function run all tests that are listed at it. Every test that is created must to be called
     * here to register itself at the Test System and perform the testing.
     */
    public runTests()
    {
        LOGGER( 128, "I AM ENTERING ON runTests(0)" );
        
        print_logger( "" );
        print_logger( "" );
        print_logger( "    Executing the 'Galileo' Tests: " );
        print_logger( "" );
        
        g_areTheUnitTestsRunning = true;
        save_server_cvars_for_test();
        ALL_TESTS_TO_EXECUTE();
        
        print_logger( "" );
        print_logger( "    %d tests succeed.", g_totalSuccessfulTests );
        print_logger( "    %d tests failed.", g_totalFailureTests );
        
        if( g_max_delay_result )
        {
            print_logger( "" );
            print_logger( "" );
            print_logger( "    Executing the 'Galileo' delayed until %d seconds tests: ", g_max_delay_result );
            print_logger( "" );
            
            set_task( g_max_delay_result + 1.0, "show_delayed_results" );
        }
        else
        {
            // clean the testing
            cancelVoting();
            restore_server_cvars_for_test();
            
            print_all_tests_executed();
            print_tests_failure();
            
            g_areTheUnitTestsRunning = false;
        }
    }
    
    stock print_all_tests_executed()
    {
        LOGGER( 128, "I AM ENTERING ON print_all_tests_executed(0)" );
        new test_name[ MAX_SHORT_STRING ];
        
        // displays the last test OK.
        print_logger( "OK!");
        print_logger( "");
        
        if( ArraySize( g_tests_idsAndNames ) )
        {
            print_logger( "" );
            print_logger( "" );
            print_logger( "    The following tests were executed: " );
            print_logger( "" );
        }
        
        for( new test_index = 0; test_index < ArraySize( g_tests_idsAndNames ); test_index++ )
        {
            ArrayGetString( g_tests_idsAndNames, test_index, test_name, charsmax( test_name ) );
            
            print_logger( "       %3d. %s", test_index + 1, test_name );
        }
    }
    
    stock print_tests_failure()
    {
        LOGGER( 128, "I AM ENTERING ON print_tests_failure(0)" );
        
        new test_id;
        new test_name[ MAX_SHORT_STRING ];
        new failure_reason[ MAX_LONG_STRING ];
        
        if( ArraySize( g_tests_failure_ids ) )
        {
            print_logger( "" );
            print_logger( "" );
            print_logger( "    The following 'Galileo' unit tests failed: " );
            print_logger( "" );
        }
        
        for( new failure_index = 0; failure_index < ArraySize( g_tests_failure_ids ); failure_index++ )
        {
            test_id = ArrayGetCell( g_tests_failure_ids, failure_index );
            
            ArrayGetString( g_tests_idsAndNames, test_id - 1, test_name, charsmax( test_name ) );
            ArrayGetString( g_tests_failure_reasons, failure_index, failure_reason, charsmax( failure_reason ) );
            
            print_logger( "       %3d. %s: %s", test_id, test_name, failure_reason );
        }
    }
    
    /**
     * This is executed at the end of the delayed tests execution to show its results and restore any
     * cvars variable change.
     */
    public show_delayed_results()
    {
        LOGGER( 128, "I AM ENTERING ON show_delayed_results(0)" );
        
        // clean the testing
        cancelVoting();
        restore_server_cvars_for_test();
        
        print_all_tests_executed();
        print_tests_failure();
        
        print_logger( "" );
        print_logger( "    %d tests succeed.", g_totalSuccessfulTests );
        print_logger( "    %d tests failed.", g_totalFailureTests );
        print_logger( "" );
        print_logger( "    Finished 'Galileo' Tests Execution." );
        print_logger( "" );
        print_logger( "" );
        
        g_areTheUnitTestsRunning = false;
    }
    
    /**
     * This is the first thing called when a test begin running. It function is to let the Test System
     * know that the test exists and then know how to handle it using the test_id.
     *
     * @param max_delay_result        the max delay time to finish the whole test chain execution.
     * @param test_name               the test name to register
     *
     * @return test_id                an integer that refers it at the Test System.
     */
    stock register_test( max_delay_result, test_name[] )
    {
        LOGGER( 0, "I AM ENTERING ON register_test(2) | max_delay_result: %d, test_name: %s", max_delay_result, test_name );
        new totalTests;
        
        g_totalSuccessfulTests++;
        totalTests = g_totalSuccessfulTests + g_totalFailureTests;
        
        // displays the tests OK.
        if( totalTests > 0 )
        {
            print_logger( "OK!");
            print_logger( "");
        }
        
        ArrayPushString( g_tests_idsAndNames, test_name );
        print_logger( "        EXECUTING TEST %d WITH %d SECONDS DELAY - %s ", totalTests, max_delay_result, test_name );
        
        if( g_max_delay_result < max_delay_result )
        {
            g_max_delay_result = max_delay_result;
        }
        
        return totalTests;
    }
    
    /**
     * Informs the Test System that the test failed and why.
     *
     * @param test_id              the test_id at the Test System
     * @param isFailure            a boolean value setting whether the failure status is true.
     * @param failure_reason       the reason why the test failed
     * @param any                  a variable number of formatting parameters
     */
    stock set_test_failure_private( test_id, bool:isFailure, failure_reason[], any: ... )
    {
        LOGGER( 0, "I AM ENTERING ON set_test_failure_private(...) | test_id: %d, isFailure: %d, \
                failure_reason: %s",                                 test_id,     isFailure, \
                failure_reason );
        
        g_current_test_evaluation = isFailure;
        
        if( isFailure )
        {
            static formated_message[ MAX_LONG_STRING ];
            
            g_totalSuccessfulTests--;
            g_totalFailureTests++;
            
            vformat( formated_message, charsmax( formated_message ), failure_reason, 3 );
            ArrayPushCell( g_tests_failure_ids, test_id );
            
            ArrayPushString( g_tests_failure_reasons, formated_message );
            print_logger( "       TEST FAILURE! %s", formated_message );
        }
    }
    
    /**
     * This is a simple test to verify the basic registering test functionality.
     */
    stock test_register_test()
    {
        new test_id;
        new first_test_name[ 64 ];
        
        test_id = register_test( 0, "test_register_test" );
        
        SET_TEST_FAILURE( test_id, g_totalSuccessfulTests != 1, \
                "g_totalSuccessfulTests must be 1 (it was %d)", g_totalSuccessfulTests );
        
        SET_TEST_FAILURE( test_id, test_id != 1, "test_id must be 1 (it was %d)", test_id );
        ArrayGetString( g_tests_idsAndNames, 0, first_test_name, charsmax( first_test_name ) );
        
        SET_TEST_FAILURE( test_id, !equal( first_test_name, "test_register_test" ), \
                "first_test_name must be 'test_register_test' (it was %s)", first_test_name );
    }
    
    /**
     * This is the vote_startDirector() tests chain beginning. Because the vote_startDirector() cannot
     * to be tested simultaneously. Then, all tests that involves the vote_startDirector() chain, must
     * to be executed sequentially after this chain end.
     *
     * This is the 1º chain test.
     *
     * Tests if the cvar 'amx_extendmap_max' functionality is working properly for a successful case.
     */
    stock test_is_map_extension_allowed()
    {
        new chainDelay = 2 + 2 + 1 + 1 + 1;
        new test_id    = register_test( chainDelay, "test_is_map_extension_allowed" );
        
        SET_TEST_FAILURE( test_id, g_isMapExtensionAllowed, "g_isMapExtensionAllowed must be 0 (it was %d)", \
                g_isMapExtensionAllowed );
        
        set_pcvar_float( cvar_maxMapExtendTime, 20.0 );
        set_pcvar_float( cvar_mp_timelimit, 10.0 );
        
        vote_startDirector( false );
        
        SET_TEST_FAILURE( test_id, !g_isMapExtensionAllowed, "g_isMapExtensionAllowed must be 1 (it was %d)", \
                g_isMapExtensionAllowed );
        
        set_task( 2.0, "test_is_map_extension_allowed2", chainDelay );
    }
    
    /**
     * This is the 2º test at vote_startDirector() chain.
     *
     * Tests if the cvar 'amx_extendmap_max' functionality is working properly for a failure case.
     */
    public test_is_map_extension_allowed2( chainDelay )
    {
        new test_id = register_test( chainDelay, "test_is_map_extension_allowed2" );
        
        SET_TEST_FAILURE( test_id, !g_isMapExtensionAllowed, \
                "g_isMapExtensionAllowed must be 1 (it was %d)", g_isMapExtensionAllowed );
        
        color_print( 0, "^1%L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED" );
        cancelVoting();
        
        set_pcvar_float( cvar_maxMapExtendTime, 10.0 );
        set_pcvar_float( cvar_mp_timelimit, 20.0 );
        
        vote_startDirector( false );
        SET_TEST_FAILURE( test_id, g_isMapExtensionAllowed, "g_isMapExtensionAllowed must be 0 (it was %d)", g_isMapExtensionAllowed );
        
        set_task( 2.0, "test_end_of_map_voting_start_1", chainDelay );
    }
    
    /**
     * This is the 3º test at vote_startDirector() chain.
     *
     * Tests if the end map voting is starting automatically at the end of map due time limit expiration.
     */
    public test_end_of_map_voting_start_1( chainDelay )
    {
        new test_id;
        new secondsLeft;
        
        test_id = register_test( chainDelay, "test_end_of_map_voting_start_1" );
        SET_TEST_FAILURE( test_id, g_isMapExtensionAllowed, "g_isMapExtensionAllowed must be 0 (it was %d)", g_isMapExtensionAllowed );
        
        cancelVoting();
        secondsLeft = get_timeleft();
        
        set_pcvar_float( cvar_mp_timelimit,
                ( get_pcvar_float( cvar_mp_timelimit ) * 60
                  - secondsLeft
                  + START_VOTEMAP_MAX_TIME + 15 )
                / 60 );
        
        set_task( 1.0, "test_end_of_map_voting_start_2", chainDelay );
    }
    
    /**
     * This is the 4º test at vote_startDirector() chain.
     *
     * Tests if the end map voting is starting automatically at the end of map due time limit expiration.
     */
    public test_end_of_map_voting_start_2( chainDelay )
    {
        new test_id = register_test( chainDelay, "test_end_of_map_voting_start_2" );
        
        vote_manageEnd();
        SET_TEST_FAILURE( test_id, !( g_voteStatus & VOTE_IS_IN_PROGRESS ), "vote_startDirector() does not started!" );
        
        set_pcvar_float( cvar_mp_timelimit, 20.0 );
        cancelVoting();
        
        set_task( 1.0, "test_end_of_map_voting_stop_1", chainDelay );
    }
    
    /**
     * This is the 5º test at vote_startDirector() chain.
     *
     * Tests if the end map voting is NOT starting automatically at the end of map due time limit expiration.
     */
    public test_end_of_map_voting_stop_1( chainDelay )
    {
        new test_id = register_test( chainDelay, "test_end_of_map_voting_stop_1" );
        
        vote_manageEnd();
        SET_TEST_FAILURE( test_id, ( g_voteStatus & VOTE_IS_IN_PROGRESS ) != 0, "vote_startDirector() does started!" );
        
        set_pcvar_float( cvar_mp_timelimit, 1.0 );
        cancelVoting();
        
        set_task( 1.0, "test_end_of_map_voting_stop_2", chainDelay );
    }
    
    /**
     * This is the 6º test at vote_startDirector() chain.
     *
     * Tests if the end map voting is NOT starting automatically at the end of map due time limit expiration.
     */
    public test_end_of_map_voting_stop_2( chainDelay )
    {
        new test_id = register_test( chainDelay, "test_end_of_map_voting_stop_2" );
        
        vote_manageEnd();
        SET_TEST_FAILURE( test_id, ( g_voteStatus & VOTE_IS_IN_PROGRESS ) != 0, "vote_startDirector() does started!" );
        
        set_pcvar_float( cvar_mp_timelimit, 20.0 );
        cancelVoting();
        
        //set_task( 1.0, "test_end_of_map_voting_stop_____", chainDelay )
    }
    
    /**
     * Test for client connect cvar_isToStopEmptyCycle behavior.
     */
    stock test_gal_in_empty_cycle_case1()
    {
        new test_id = register_test( 0, "test_gal_in_empty_cycle_case1" );
        
        set_pcvar_num( cvar_isToStopEmptyCycle, 1 );
        client_authorized( 1 );
        
        SET_TEST_FAILURE( test_id, get_pcvar_num( cvar_isToStopEmptyCycle ) != 0, \
                "cvar_isToStopEmptyCycle must be 0 (it was %d)", get_pcvar_num( cvar_isToStopEmptyCycle ) );
        
        set_pcvar_num( cvar_isToStopEmptyCycle, 0 );
        client_authorized( 1 );
        
        SET_TEST_FAILURE( test_id, get_pcvar_num( cvar_isToStopEmptyCycle ) != 0, \
                "cvar_isToStopEmptyCycle must be 0 (it was %d)", get_pcvar_num( cvar_isToStopEmptyCycle ) );
    }
    
    /**
     * This 1º case test if the current map isn't part of the empty cycle, immediately change to next map
     * that is.
     */
    stock test_gal_in_empty_cycle_case2()
    {
        new nextMap[ MAX_MAPNAME_LENGHT ];
        
        new test_id                  = register_test( 0, "test_gal_in_empty_cycle_case2" );
        new Array: emptyCycleMapList = ArrayCreate( MAX_MAPNAME_LENGHT );
        
        ArrayPushString( emptyCycleMapList, "de_dust2" );
        ArrayPushString( emptyCycleMapList, "de_inferno" );
        
        new mapIndex = map_getNext( emptyCycleMapList, "de_dust2", nextMap );
        
        SET_TEST_FAILURE( test_id, !equal( nextMap, "de_inferno" ), "nextMap must be 'de_inferno' (it was %s)", nextMap );
        SET_TEST_FAILURE( test_id, mapIndex == -1, "mapIndex must NOT be '-1' (it was %d)", mapIndex );
        
        ArrayDestroy( emptyCycleMapList );
    }
    
    /**
     * This 2º case test if the current map isn't part of the empty cycle, immediately change to next map
     * that is.
     */
    stock test_gal_in_empty_cycle_case3()
    {
        new nextMap[ MAX_MAPNAME_LENGHT ];
        
        new test_id                  = register_test( 0, "test_gal_in_empty_cycle_case3" );
        new Array: emptyCycleMapList = ArrayCreate( MAX_MAPNAME_LENGHT );
        
        ArrayPushString( emptyCycleMapList, "de_dust2" );
        ArrayPushString( emptyCycleMapList, "de_inferno" );
        ArrayPushString( emptyCycleMapList, "de_dust4" );
        
        new mapIndex = map_getNext( emptyCycleMapList, "de_inferno", nextMap );
        
        SET_TEST_FAILURE( test_id, !equal( nextMap, "de_dust4" ), "nextMap must be 'de_dust4' (it was %s)", nextMap );
        SET_TEST_FAILURE( test_id, mapIndex == -1, "mapIndex must NOT be '-1' (it was %d)", mapIndex );
        
        ArrayDestroy( emptyCycleMapList );
    }
    
    /**
     * This 3º case test if the current map isn't part of the empty cycle, immediately change to next map
     * that is.
     */
    stock test_gal_in_empty_cycle_case4()
    {
        new nextMap[ MAX_MAPNAME_LENGHT ];
        
        new test_id                  = register_test( 0, "test_gal_in_empty_cycle_case4" );
        new Array: emptyCycleMapList = ArrayCreate( MAX_MAPNAME_LENGHT );
        
        ArrayPushString( emptyCycleMapList, "de_dust2" );
        ArrayPushString( emptyCycleMapList, "de_inferno" );
        ArrayPushString( emptyCycleMapList, "de_dust4" );
        
        new mapIndex = map_getNext( emptyCycleMapList, "de_dust", nextMap );
        
        SET_TEST_FAILURE( test_id, !equal( nextMap, "de_dust2" ), "nextMap must be 'de_dust2' (it was %s)", nextMap );
        SET_TEST_FAILURE( test_id, !( mapIndex == -1 ), "mapIndex must be '-1' (it was %d)", mapIndex );
        
        ArrayDestroy( emptyCycleMapList );
    }
    
    /**
     * This tests if the function 'loadCurrentBlackList()' 1º case is working properly.
     */
    public test_loadCurrentBlackList_case1()
    {
        new whiteListFile;
        
        new test_id            = register_test( 0, "test_loadCurrentBlackList_case1" );
        new Trie:blackListTrie = TrieCreate();
        
        copy( g_test_whiteListFilePath, charsmax( g_test_whiteListFilePath ), "test_loadCurrentBlackList.txt" );
        set_pcvar_string( cvar_voteWhiteListMapFilePath, g_test_whiteListFilePath );
        
        whiteListFile = fopen( g_test_whiteListFilePath, "wt" );
        
        if( whiteListFile )
        {
            fprintf( whiteListFile, "%s^n", "[23-24]" );
            fprintf( whiteListFile, "%s^n", "de_dust1" );
            fprintf( whiteListFile, "%s^n", "de_dust2" );
            fprintf( whiteListFile, "%s^n", "de_dust3" );
            fprintf( whiteListFile, "%s^n", "[1-23]" );
            fprintf( whiteListFile, "%s^n", "de_dust4" );
            fprintf( whiteListFile, "%s^n", "[12-22]" );
            fprintf( whiteListFile, "%s^n", "de_dust5" );
            fprintf( whiteListFile, "%s^n", "de_dust6" );
            fprintf( whiteListFile, "%s^n", "de_dust7" );
            fclose( whiteListFile );
        }
        
        g_test_current_time = 23;
        loadCurrentBlackList( blackListTrie );
        g_test_current_time = 0;
        
        SET_TEST_FAILURE( test_id, TrieKeyExists( blackListTrie, "de_dust1" ), \
                "The map 'de_dust1' must NOT to be present on the trie, but it was!" );
        SET_TEST_FAILURE( test_id, TrieKeyExists( blackListTrie, "de_dust2" ), \
                "The map 'de_dust2' must NOT to be present on the trie, but it was!" );
        SET_TEST_FAILURE( test_id, TrieKeyExists( blackListTrie, "de_dust3" ), \
                "The map 'de_dust3' must NOT to be present on the trie, but it was!" );
        
        SET_TEST_FAILURE( test_id, !TrieKeyExists( blackListTrie, "de_dust4" ), \
                "The map 'de_dust4' must to be present on the trie, but it was not!" );
        SET_TEST_FAILURE( test_id, !TrieKeyExists( blackListTrie, "de_dust5" ), \
                "The map 'de_dust5' must to be present on the trie, but it was not!" );
        SET_TEST_FAILURE( test_id, !TrieKeyExists( blackListTrie, "de_dust6" ), \
                "The map 'de_dust6' must to be present on the trie, but it was not!" );
        SET_TEST_FAILURE( test_id, !TrieKeyExists( blackListTrie, "de_dust7" ), \
                "The map 'de_dust7' must to be present on the trie, but it was not!" );
        
        TrieDestroy( blackListTrie );
    }
    
    /**
     * This tests if the function 'loadCurrentBlackList()' 2º case is working properly.
     */
    public test_loadCurrentBlackList_case2()
    {
        new test_id            = register_test( 0, "test_loadCurrentBlackList_case2" );
        new Trie:blackListTrie = TrieCreate();
        
        g_test_current_time = 22;
        loadCurrentBlackList( blackListTrie );
        g_test_current_time = 0;
        
        SET_TEST_FAILURE( test_id, TrieKeyExists( blackListTrie, "de_dust4" ), \
                "The map 'de_dust4' must NOT to be present on the trie, but it was!" );
        
        SET_TEST_FAILURE( test_id, !TrieKeyExists( blackListTrie, "de_dust5" ), \
                "The map 'de_dust5' must to be present on the trie, but it was not!" );
        
        TrieDestroy( blackListTrie );
    }
    
    /**
     * This tests if the function 'loadCurrentBlackList()' 3º case is working properly.
     */
    public test_loadCurrentBlackList_case3()
    {
        new test_id            = register_test( 0, "test_loadCurrentBlackList_case3" );
        new Trie:blackListTrie = TrieCreate();
        
        g_test_current_time = 12;
        loadCurrentBlackList( blackListTrie );
        g_test_current_time = 0;
        
        SET_TEST_FAILURE( test_id, TrieKeyExists( blackListTrie, "de_dust7" ), \
                "The map 'de_dust7' must NOT to be present on the trie, but it was!" );
        
        SET_TEST_FAILURE( test_id, !TrieKeyExists( blackListTrie, "de_dust2" ), \
                "The map 'de_dust2' must to be present on the trie, but it was not!" );
        
        TrieDestroy( blackListTrie );
        delete_file( g_test_whiteListFilePath );
    }
    
    
    
    /**
     * Server changed cvars backup to be restored after the unit tests end.
     */
    new Float:test_extendmap_max;
    new Float:test_mp_timelimit;
    
    new test_whiteListFilePath[ MAX_FILE_PATH_LENGHT ];
    
    /**
     * Every time a cvar is changed during the tests, it must be saved here to a global test variable
     * to be restored at the restore_server_cvars_for_test(), which is executed at the end of all
     * tests execution.
     *
     * This is executed before the first rest run.
     */
    stock save_server_cvars_for_test()
    {
        LOGGER( 128, "I AM ENTERING ON save_server_cvars_for_test(0)" );
        g_is_test_changed_cvars = true;
        
        test_extendmap_max = get_pcvar_float( cvar_maxMapExtendTime );
        test_mp_timelimit  = get_pcvar_float( cvar_mp_timelimit );
        
        get_pcvar_string( cvar_voteWhiteListMapFilePath, test_whiteListFilePath, charsmax( test_whiteListFilePath ) );
        
        LOGGER( 2, "    %42s cvar_mp_timelimit: %f  test_mp_timelimit: %f   g_originalTimelimit: %f", \
                "save_server_cvars_for_test( out )", \
                get_pcvar_float( cvar_mp_timelimit ), test_mp_timelimit, g_originalTimelimit );
    }
    
    /**
     * This is executed after all tests executions, to restore the server variables changes.
     */
    stock restore_server_cvars_for_test()
    {
        LOGGER( 128, "I AM ENTERING ON restore_server_cvars_for_test(0)" );
        LOGGER( 2, "    %42s cvar_mp_timelimit: %f  test_mp_timelimit: %f  g_originalTimelimit: %f", \
                "restore_server_cvars_for_test( in )", \
                get_pcvar_float( cvar_mp_timelimit ), test_mp_timelimit, g_originalTimelimit );
        
        if( g_is_test_changed_cvars )
        {
            g_is_test_changed_cvars = false;
            
            set_pcvar_float( cvar_maxMapExtendTime, test_extendmap_max );
            set_pcvar_float( cvar_mp_timelimit, test_mp_timelimit );
            
            set_pcvar_string( cvar_voteWhiteListMapFilePath, test_whiteListFilePath );
        }
        
        LOGGER( 2, "    %42s cvar_mp_timelimit: %f  test_mp_timelimit: %f  g_originalTimelimit: %f", \
                "restore_server_cvars_for_test( out )", \
                get_pcvar_float( cvar_mp_timelimit ), test_mp_timelimit, g_originalTimelimit );
    }
#endif

