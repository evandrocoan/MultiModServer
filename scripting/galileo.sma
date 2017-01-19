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



// Configuration Main Definitions
// ###############################################################################################

/**
 * This version number must be synced with "githooks/GALILEO_SMA_VERSION.txt" for manual edition.
 * To update them automatically, use: ./githooks/updateVersion.sh [major | minor | patch | build]
 */
new const PLUGIN_NAME[]    = "Galileo";
new const PLUGIN_AUTHOR[]  = "Brad Jones/Addons zz";
new const PLUGIN_VERSION[] = "v4.2.0-567";

/**
 * Enables the support to Sven Coop 'mp_nextmap_cycle' cvar and vote map start by the Ham_Use
 * "game_end". It will require the '<hamsandwich>' module.
 */
#define IS_TO_ENABLE_SVEN_COOP_SUPPPORT 1

/**
 * Change this value from 1 to 0, to disable Re-HLDS and Re-Amx Mod X support. If you disable the
 * support, and you are using the Re-HLDS and Re-Amx Mod X, you server may crash.
 */
#define IS_TO_ENABLE_RE_HLDS_RE_AMXMODX_SUPPORT 1



// Debugger Main Definitions
// ###############################################################################################

/**
 * This is to view internal program data while execution. See the function 'debugMesssageLogger(...)'
 * and the variable 'g_debug_level' for more information. Usage example, to enables several levels:
 * #define DEBUG_LEVEL 1+2+4+16
 *
 * @note when the 'DEBUG_LEVEL_FAKE_VOTES' is activated, usually the voting will be approved
 * because it creates also a fake players count. So, do not enable 'DEBUG_LEVEL_FAKE_VOTES'
 * if you do not want the map voting starting on an empty server.
 *
 * 0    - Disables this feature.
 *
 * 1    - Normal/basic debugging/depuration.
 *
 * 2    - a) Run the NORMAL Unit Tests on the server start.
 *        b) To skip the 'pendingVoteCountdown()'.
 *        c) Set the vote runoff time to 5 seconds.
 *
 * 4    - Run the DELAYED Unit Tests.
 *
 * 8    - a) To create fake votes. See the function 'create_fakeVotes()'.
 *        b) To create fake players count. See the function 'get_real_players_number()'.
 *
 * 16   - Enable DEBUG_LEVEL 1 and all its debugging/depuration available.
 *
 * 32   - a) Run the MANUAL test on server start.
 *        b) To skip the 'pendingVoteCountdown()'.
 *        c) Set the vote runoff time to 5 seconds.
 *
 * 64   - Disable the LOGGER() while running the Unit Tests.
 *
 * 127  - Enable the levels 1, 2, 4, 8, 16, 32 and 64.
 *
 * Default value: 0
 */
#define DEBUG_LEVEL 16


/**
 * How much players use when the debugging level 'DEBUG_LEVEL_FAKE_VOTES' is enabled.
 */
#define FAKE_PLAYERS_NUMBER_FOR_DEBUGGING 3

/**
 * When the debug mode `DEBUG_LEVEL` is enabled, the map_populateList(4) will show up to this maps
 * loaded from the server.
 */
#define MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST 10

/**
 * Debugging level configurations.
 */
#define DEBUG_LEVEL_NORMAL            1
#define DEBUG_LEVEL_UNIT_TEST_NORMAL  2
#define DEBUG_LEVEL_UNIT_TEST_DELAYED 4
#define DEBUG_LEVEL_FAKE_VOTES        8
#define DEBUG_LEVEL_CRITICAL_MODE     16
#define DEBUG_LEVEL_MANUAL_TEST_START 32
#define DEBUG_LEVEL_DISABLE_TEST_LOGS 64

/**
 * Common strings sizes used around the plugin.
 */
#define MAX_LONG_STRING              256
#define MAX_COLOR_MESSAGE            190
#define MAX_SHORT_STRING             64
#define MAX_BIG_BOSS_STRING          512
#define MAX_NOMINATION_TRIE_KEY_SIZE 48
#define MAX_MAPNAME_LENGHT           64
#define MAX_FILE_PATH_LENGHT         128
#define MAX_PLAYER_NAME_LENGHT       48

/**
 * Necessary modules.
 */
#include <amxmodx>
#include <amxmisc>
#include <fun>

/**
 * Force the use of semicolons on every statements.
 */
#pragma semicolon 1

/**
 * Global Debugging tools used on any 'DEBUG_LEVEL'.
 */
#if DEBUG_LEVEL >= DEBUG_LEVEL_NORMAL
    /**
     * The file on the './addons/amxmodx/logs' folder, to save the debugging text output.
     */
    new const DEBUGGER_OUTPUT_LOG_FILE_NAME[] = "_galileo_log.txt";

    /**
     * Used to know when the Unit Tests are running.
     */
    new bool:g_test_isTheUnitTestsRunning;

    /**
     * Allow the Manual Unit Tests to disable LOGGER() debugging messages when the level
     * DEBUG_LEVEL_DISABLE_TEST_LOGS is enabled.
     */
    new bool:g_test_isToDisableLogging;

    /**
     * Write messages to the debug log file on 'addons/amxmodx/logs'.
     *
     * @param log_file               the log file name.
     * @param formated_message       the formatted message to write down to the debug log file.
     */
    stock writeToTheDebugFile( const log_file[], const formated_message[] )
    {
        new currentTime;
        static lastRun;

        currentTime = tickcount();

        log_to_file( log_file, "{%.3f %d %5d %4d} %s", get_gametime(), heapspace(), currentTime, currentTime - lastRun, formated_message );
        lastRun = currentTime;

        // Removes the compiler warning `warning 203: symbol is never used` with some DEBUG levels.
        if( g_test_isTheUnitTestsRunning && g_test_isToDisableLogging ) { }
        if( DEBUGGER_OUTPUT_LOG_FILE_NAME[0] ) { }
    }
#endif

/**
 * Setup the debugging tools when they are used/necessary.
 */
#if DEBUG_LEVEL & ( DEBUG_LEVEL_NORMAL | DEBUG_LEVEL_CRITICAL_MODE )
    #define DEBUG
    #define LOGGER(%1) debugMesssageLogger( %1 );

    /**
     * 0    - Disabled all debug output print.
     *
     * 1    - Displays basic debug messages.
     *
     * 2    - a) Players disconnecting and total number.
     *        b) Multiple time limits changes and restores.
     *        c) Cvars changes (mp_chattime, mp_timelimit, etc)
     *
     * 4    - a) Maps events.
     *        b) Vote choices.
     *        c) Nominations.
     *        d) Calls to map_populateList(4).
     *
     * 8    - a) Loaded vote choices.
     *        b) Minplayers-Whitelist debugging.
     *        c) Actions at vote_startDirector(1).
     *
     * 16   - Runoff voting.
     *
     * 32   - Rounds end map voting.
     *
     * 64   - Debug for the color_print(...) function.
     *
     * 128  - Functions entrances messages.
     *
     * 256  - High called functions calls.
     *
     * 511  - Enables all debug logging levels.
     */
    new g_debug_level = 1+2+4+8+16+32+64+128;

    /**
     * Write debug messages accordantly with the 'g_debug_level' variable.
     *
     * @param mode the debug mode level, see the variable 'g_debug_level' for the levels.
     * @param text the debug message, if omitted its default value is ""
     * @param any the variable number of formatting parameters
     *
     * @see the stock writeToTheDebugFile( log_file[], formated_message[] ) for the output log
     *      'DEBUGGER_OUTPUT_LOG_FILE_NAME'.
     */
    stock debugMesssageLogger( const mode, const message[] = "", any:... )
    {
        if( mode & g_debug_level )
        {
        #if DEBUG_LEVEL & DEBUG_LEVEL_DISABLE_TEST_LOGS
            if( !g_test_isToDisableLogging )
            {
                static formated_message[ MAX_BIG_BOSS_STRING ];
                vformat( formated_message, charsmax( formated_message ), message, 3 );

                writeToTheDebugFile( DEBUGGER_OUTPUT_LOG_FILE_NAME, formated_message );
            }
        #else
            static formated_message[ MAX_BIG_BOSS_STRING ];
            vformat( formated_message, charsmax( formated_message ), message, 3 );

            writeToTheDebugFile( DEBUGGER_OUTPUT_LOG_FILE_NAME, formated_message );
        #endif
        }
    }
#else
    #define LOGGER(%1)

#endif



// Unit Tests Main Definitions
// ###############################################################################################

/**
 * Setup the Unit Tests when they are used/necessary.
 */
#if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED )
    /**
     * Contains all imediates unit tests to execute.
     */
    stock normalTestsToExecute()
    {
        LOGGER( 128, "I AM ENTERING ON normalTestsToExecute(0)" )

        test_registerTest();
        test_isInEmptyCycle();
        test_mapGetNext_cases();
        test_loadCurrentBlackList_cases();
        test_resetRoundsScores_cases();
        test_loadVoteChoices_cases();
        test_nominateAndUnnominate_load();
        test_RTVAndUnRTV_load();
        test_getUniqueRandomBasic_load();
        test_getUniqueRandomInt_load();
        test_whatGameEndingTypeIt_load();
        test_convertNumericBase_load();
        test_setCorrectMenuPage_load();
        test_strictValidMapsTrie_load();
        test_populateListOnSeries_load1();
        test_populateListOnSeries_load2();
        test_populateListOnSeries_load3();
        test_GET_MAP_NAME_load();
        test_GET_MAP_INFO_load();
        test_SortCustomSynced2D();
    }

    /**
     * Contains all delayed unit tests to execute.
     */
    public dalayedTestsToExecute()
    {
        LOGGER( 128, "I AM ENTERING ON dalayedTestsToExecute(0)" )
        test_isMapExtensionAvowed_case1();
    }

    /**
     * Run the manual call Unit Tests, by 'say run' and 'say_team run'.
     */
    public inGameTestsToExecute( player_id )
    {
        LOGGER( 128, "I AM ENTERING ON inGameTestsToExecute(1) player_id: %d", player_id )

        // Save the game cvars?
        if( !g_test_isTheUnitTestsRunning ) saveServerCvarsForTesting();

        for( new i = 0; i < 1000; i++ )
        {
            for( new i = 0; i < 1000; i++ )
            {
            }

            // LOGGER( 1, "Current i is: %d", i )
        }

        test_loadCurrentBlackList_cases();
        // test_SortCustomSynced2D();
        // test_GET_MAP_INFO_load();
        // test_GET_MAP_NAME_load();
        // test_populateListOnSeries_load1();
        // test_populateListOnSeries_load2();
        // test_populateListOnSeries_load3();
        // test_setCorrectMenuPage_load();
        // test_convertNumericBase_load();
        // test_whatGameEndingTypeIt_load();
        // test_getUniqueRandomInt_load();
        // test_getUniqueRandomBasic_load();
        // test_nominateAndUnnominate_load();
        // test_loadVoteChoices_cases();
        //test_colorChatLimits( player_id );
        //test_unnominatedDisconnected( player_id );
        //test_announceVoteBlockedMap_a();
        //test_announceVoteBlockedMap_c();

        // Restore the game cvars
        if( g_test_isTheUnitTestsRunning ) printTheUnitTestsResults();
    }

    /**
     * Accept all maps as valid while running the unit tests.
     */
    #define IS_MAP_VALID(%1) ( isAllowedValidMapByTheUnitTests(%1) || !g_test_isToUseStrictValidMaps && IS_MAP_VALID_BSP( %1 ) )

    /**
     * Call the internal function to perform its task and stop the current test execution to avoid
     * double failure at the test control system.
     *
     * @see the stock 'setTestFailure(3)'.
     */
    #define SET_TEST_FAILURE(%1) \
    { \
        if( setTestFailure( %1 ) ) \
        { \
            LOGGER( 1, "    ( SET_TEST_FAILURE ) Just returning/blocking." ) \
            return; \
        } \
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
        static formated_message[ MAX_BIG_BOSS_STRING ];
        vformat( formated_message, charsmax( formated_message ), message, 2 );

        writeToTheDebugFile( DEBUGGER_OUTPUT_LOG_FILE_NAME, formated_message );
    }

    /**
     * Test unit variables related to the DEBUG_LEVEL_UNIT_TESTs.
     */
    new g_test_maxDelayResult;
    new g_test_testsNumber;
    new g_test_failureNumber;
    new g_test_lastMaxDelayResult;
    new g_lastNormalTestToExecuteId;

    new bool: g_test_isToUseStrictValidMaps;
    new Trie: g_test_failureIdsTrie;
    new Trie: g_test_strictValidMapsTrie;
    new Array:g_test_failureIdsArray;
    new Array:g_test_idsAndNamesArray;
    new Array:g_test_failureReasonsArray;

    new g_test_lastTimeStamp;
    new g_test_aimedPlayersNumber;
    new g_test_gameElapsedTime;
    new g_test_startDayInteger;

    new g_test_printedMessage[ MAX_COLOR_MESSAGE ];

    new g_test_nomMapFilePath[]     = "test_nomMapFilePath.txt";
    new g_test_voteMapFilePath[]    = "test_voteFilePathTestFile.txt";
    new g_test_whiteListFilePath[]  = "test_loadCurrentBlackList.txt";
    new g_test_minPlayersFilePath[] = "test_minimumPlayersTestFile.txt";

#else
    #define IS_MAP_VALID(%1) ( IS_MAP_VALID_BSP( %1 ) )

#endif



// In-place Main Constants
// ###############################################################################################

/**
 * Defines the maximum players number, when it is not specified for olders AMXX versions.
 */
#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

/**
 * Includes the Sven Coop required module for support.
 */
#if IS_TO_ENABLE_SVEN_COOP_SUPPPORT > 0
    #include <hamsandwich>
    new cvar_mp_nextmap_cycle;
#endif

/**
 * Register the color chat necessary variables.
 */
new bool:g_isColorChatSupported;
new bool:g_isColoredChatEnabled;

/**
 * On the first server start, we do not know whether the color chat is allowed/enabled. This is due
 * the register register_dictionary_colored(1) to be called on plugin_init(0) and the settings being
 * loaded only at plugin_cfg(0).
 */
#define IS_COLORED_CHAT_ENABLED() \
    ( g_isColorChatSupported \
      && g_isColoredChatEnabled )

#if AMXX_VERSION_NUM < 183
    new g_user_msgid;
#endif

new cvar_coloredChatEnabled;

/**
 * Switch between the AMXX 182 and 183 deprecated/bugged functions.
 */
#if AMXX_VERSION_NUM < 183
    #define STR_TOKEN strtok
#else
    #define STR_TOKEN strtok2
#endif

/**
 * General Constants.
 */
#define MAX_INTEGER  2147483647
#define MIN_INTEGER -2147483648

#define FRAGS_BY_ROUND_AVERAGE   13
#define SECONDS_BY_ROUND_AVERAGE 100

#define LISTMAPS_USERID   0
#define LISTMAPS_LAST_MAP 1

#define RUNOFF_ENABLED 1
#define RUNOFF_EXTEND  2

#define FIRST_SERVER_START  2
#define SECOND_SERVER_START 1
#define AFTER_READ_MAPCYCLE 0

#define END_OF_MAP_VOTE_ASK      1
#define END_OF_MAP_VOTE_ANNOUNCE 2

#define VOTE_TIME_SEC      1.0
#define VOTE_TIME_HUD_1    7.0
#define VOTE_TIME_HUD_2    5.0
#define VOTE_TIME_ANNOUNCE 10.0
#define VOTE_TIME_RUNOFF   3.0
#define VOTE_TIME_COUNT    5.5

#define RTV_CMD_STANDARD              1
#define RTV_CMD_SHORTHAND             2
#define RTV_CMD_DYNAMIC               4
#define RTV_CMD_SINGLE_PLAYER_DISABLE 8

#define MAPFILETYPE_SINGLE 1
#define MAPFILETYPE_GROUPS 2

#define IS_TO_RTV_WAIT_ADMIN     1
#define IS_TO_RTV_NOT_ALLOW_STAY 2

#define IS_DISABLED_VOTEMAP_EXIT        1
#define IS_DISABLED_VOTEMAP_INTRO       2
#define IS_DISABLED_VOTEMAP_RUNOFF      4
#define IS_DISABLED_VOTEMAP_EXTENSION   8
#define IS_ENABLED_VOTEMAP_NOMINATIONS  16

#define MAP_CHANGES_AT_THE_NEXT_ROUND_START  0
#define MAP_CHANGES_AT_THE_CURRENT_ROUND_END 1

#define IS_MAP_MAPCHANGE_COUNTDOWN      1
#define IS_MAP_MAPCHANGE_DROP_WEAPONS   2
#define IS_MAP_MAPCHANGE_FREEZE_PLAYERS 4
#define IS_MAP_MAPCHANGE_BUY_GRENADES   8
#define IS_MAP_MAPCHANGE_FRIENDLY_FIRE  16

#define IS_BY_TIMER    1
#define IS_BY_FRAGS    2
#define IS_BY_ROUNDS   4
#define IS_BY_WINLIMIT 8

#define IS_VOTE_IN_PROGRESS 1
#define IS_FORCED_VOTE      2
#define IS_RUNOFF_VOTE      4
#define IS_VOTE_OVER        8
#define IS_EARLY_VOTE       16
#define IS_VOTE_EXPIRED     32
#define IS_RTV_VOTE         64

#define IS_TO_LOAD_THE_FIRST_MAP_SERIES 1
#define IS_TO_LOAD_ALL_THE_MAP_SERIES   2
#define IS_TO_LOAD_EXPLICIT_MAP_SERIES  4

#define SOUND_GET_READY_TO_CHOOSE 1
#define SOUND_COUNTDOWN           2
#define SOUND_TIME_TO_CHOOSE      4
#define SOUND_RUNOFF_REQUIRED     8
#define SOUND_MAPCHANGE           16

#define HUD_CHANGELEVEL_COUNTDOWN 1
#define HUD_VOTE_VISUAL_COUNTDOWN 2
#define HUD_CHANGELEVEL_ANNOUNCE  4
#define HUD_VOTE_RESULTS_ANNOUNCE 8
#define HUD_TIMELEFT_ANNOUNCE     16

#define SHOW_STATUS_NEVER             0
#define SHOW_STATUS_AFTER_VOTE        1
#define SHOW_STATUS_AT_END            2
#define SHOW_STATUS_ALWAYS            3
#define SHOW_STATUS_ALWAYS_UNTIL_VOTE 4

#define END_AT_RIGHT_NOW             0
#define END_AT_THE_CURRENT_ROUND_END 1
#define END_AT_THE_NEXT_ROUND_END    2

#define STATUS_TYPE_COUNT      1
#define STATUS_TYPE_PERCENTAGE 2

#define ANNOUNCE_CHOICE_PLAYERS 1
#define ANNOUNCE_CHOICE_ADMINS  2

#define HIDE_AFTER_USER_VOTE_NONE_OPTION        0
#define ALWAYS_KEEP_SHOWING_NONE_OPTION         1
#define CONVERT_NONE_OPTION_TO_CANCEL_LAST_VOTE 2

#define MAX_PREFIX_COUNT              32
#define MAX_OPTIONS_IN_VOTE           9
#define MAX_MENU_ITEMS_PER_PAGE       8
#define MAX_NOM_MENU_ITEMS_PER_PAGE   7
#define MAX_STANDARD_MAP_COUNT        25
#define MAX_NOM_MATCH_COUNT           1000
#define MAX_PLAYERS_COUNT             MAX_PLAYERS + 1

#define SERVER_START_CURRENTMAP                     1
#define SERVER_START_NEXTMAP                        2
#define SERVER_START_MAPVOTE                        3
#define SERVER_START_RANDOMMAP                      4
#define SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR      2
#define DELAY_TO_WAIT_THE_SERVER_CVARS_TO_BE_LOADED 50.0

/**
 * Used on the count `++g_showLastRoundHudCounter % LAST_ROUND_HUD_SHOW_INTERVAL > 6`, called each second.
 */
#define LAST_ROUND_HUD_SHOW_INTERVAL 30

/**
 * Highly and directly impact on the server change level performance.
 *
 * If your server is hosted under an SSD (Solid State Disk), a value high as 20 will take up to 10 or 20 seconds to
 * complete the change level for a mapcycle within 800 maps.
 *
 * If your server is hosted under an HD (Hard Disk), a value high as 20 will take up to 60 or 120 seconds to
 * complete the change level for a mapcycle within 800 maps.
 */
#define MAX_NON_SEQUENCIAL_MAPS_ON_THE_SERIE 3

/**
 * Define how many times the server can crash on a map, before that map to be ignored and to select
 * the next map on the map cycle to be played. The counter starts on 0.
 */
#define MAX_SERVER_RESTART_ACCEPTABLE 3

/**
 * Defines the interval where the periodic tasks as map_manageEnd(0) and vote_manageEnd(0) will be
 * checked.
 */
#define PERIODIC_CHECKING_INTERVAL 15

/**
 * The rounds number before the mp_maxrounds/mp_winlimit to be reached to start the map voting. This
 * constant is equivalent to the `START_VOTEMAP_MIN_TIME` and `START_VOTEMAP_MAX_TIME` concepts.
 *
 * Make sure this is big enough, because the rounds could be finish pretty fast and the game may end
 * before it, as this option only takes effect and the `cvar_endOnRound` and `cvar_endOfMapVoteStart`
 * are not handling the map end.
 */
#define VOTE_START_ROUNDS 4

/**
 * The rounds number required to be reached to allow predict if this will be the last round and
 * allow to start the voting.
 */
#define MIN_ROUND_TIME_DELAY        10
#define MIN_VOTE_START_ROUNDS_DELAY 1

/**
 * The periodic task created on 'configureServerMapChange(0)' use this intervals in seconds to
 * start checking for an end map voting start.
 */
#define START_VOTEMAP_MIN_TIME ( g_totalVoteTime + PERIODIC_CHECKING_INTERVAL + 3 )
#define START_VOTEMAP_MAX_TIME ( g_totalVoteTime )



// In-place Macros
// ###############################################################################################

/**
 * If this is called when the voting or the round ending is going on, it will cause the voting/round
 * ending to be cut and will force the map to immediately change to the next map.
 */
#define IS_ABLE_TO_PERFORMED_A_MAP_CHANGE() \
    ( !task_exists( TASKID_PROCESS_LAST_ROUND_COUNT ) \
      || !task_exists( TASKID_INTERMISSION_HOLD ) \
      || !( g_voteStatus & IS_VOTE_IN_PROGRESS ) \
      || !g_isTheRoundEndWhileVoting )

/**
 * This indicates the players minimum number necessary to allow the last round to be finished when
 * the time runs out.
 */
#define ARE_THERE_ENOUGH_PLAYERS_FOR_MANAGE_END() \
    ( get_real_players_number() >= get_pcvar_num( cvar_endOnRoundMininum ) )
//

/**
 * The frags/kills number before the mp_fraglimit to be reached and to start the map voting.
 */
#define VOTE_START_FRAGS() \
    ( g_fragLimitNumber > 30 ? 20 : 10 )
//

/**
 * Specifies how much time to delay the voting start after the round start.
 */
#define ROUND_VOTING_START_SECONDS_DELAY() \
    ( get_pcvar_num( cvar_mp_freezetime ) + PERIODIC_CHECKING_INTERVAL - 5 \
      + ( g_roundAverageTime > 2 * g_totalVoteTime ? g_totalVoteTime / 5 : 1 ) )
//

/**
 * Start a map voting delayed after the mp_maxrounds or mp_winlimit minimum to be reached.
 */
#define START_VOTING_BY_MIDDLE_ROUND_DELAY(%1) \
    set_task( float( ROUND_VOTING_START_SECONDS_DELAY() ), %1, TASKID_START_VOTING_DELAYED );
//

/**
 * Verifies if a voting is or was already processed.
 */
#define IS_END_OF_MAP_VOTING_GOING_ON() \
    ( g_voteStatus & ( IS_VOTE_IN_PROGRESS | IS_VOTE_OVER ) )
//

/**
 * Verifies if the round time is too big. If the map time is too big, makes not sense to wait to
 * start the map voting and will probably not to start the voting.
 */
#define IS_THE_ROUND_TIME_TOO_BIG() \
    ( get_pcvar_num( cvar_mp_roundtime ) > 8 \
      && g_roundAverageTime > 300 )
//

/**
 * Boolean check for the Whitelist feature. The Whitelist feature specifies the time where the maps
 * are allowed to be added to the voting list as fillers after the nominations being loaded.
 */
#define IS_WHITELIST_ENABLED() \
    ( get_pcvar_num( cvar_whitelistMinPlayers ) == 1 \
      || get_real_players_number() < get_pcvar_num( cvar_whitelistMinPlayers ) )
//

/**
 * Boolean check to know whether the Whitelist should be loaded every hour.
 */
#define IS_TO_HOURLY_LOAD_THE_WHITELIST() \
    ( get_pcvar_num( cvar_isWhiteListNomBlock ) )
//

/**
 * Boolean check for the nominations minimum players controlling feature. When there are less
 * players than cvar 'cvar_voteMinPlayers' value on the server, use a different map file list
 * specified at the cvar 'gal_vote_minplayers_mapfile' to fill the map voting as map fillers
 * instead of the cvar 'gal_vote_mapfile' map file list.
 */
#define IS_NOMINATION_MININUM_PLAYERS_CONTROL_ENABLED() \
    ( get_real_players_number() < get_pcvar_num( cvar_voteMinPlayers ) \
      && get_pcvar_num( cvar_nomMinPlayersControl ) )
//

/**
 * When it is set the maximum voting options as 9, we need to give space to the `Stay Here` and
 * `Extend` on the voting menu, calculating how many voting choices are allowed to be used,
 * considering whether the voting map extension option is being showed or not.
 */
#define MAX_VOTING_CHOICES() \
    ( g_isMapExtensionAllowed ? \
        ( g_maxVotingChoices >= MAX_OPTIONS_IN_VOTE ? \
            g_maxVotingChoices - 1 : g_maxVotingChoices ) : g_maxVotingChoices )
//

/**
 * Return whether is to allow a crash search on this server start or not.
 */
#define IS_TO_ALLOW_A_CRASH_SEARCH(%1) \
    ( file_exists( modeFlagFilePath ) \
      && !( DEBUG_LEVEL & DEBUG_LEVEL_FAKE_VOTES ) )
//

/**
 * Used to determine whether a map is blocked by the Whitelist feature.
 *
 * @param isWhitelistEnabled     whether or not is to allow the Whitelist blockage.
 * @param mapNameToCheck         the map name to be verified if the map list checking is enabled.
 */
#define IS_WHITELIST_BLOCKING(%1,%2) \
    ( %1 \
      && ( ( g_blacklistTrie \
             && TrieKeyExists( g_blacklistTrie, %2 ) ) \
           || ( g_whitelistTrie \
                && !TrieKeyExists( g_whitelistTrie, %2 ) ) ) )
//



// Global Macro Expansions
// ###############################################################################################

/**
 * Convert colored strings codes '!g for green', '!y for yellow', '!t for team'.
 *
 * @param string[]       a string pointer to be converted.
 */
#define INSERT_COLOR_TAGS(%1) \
{ \
    replace_all( %1, MAX_COLOR_MESSAGE - 1, "!g", "^4" ); \
    replace_all( %1, MAX_COLOR_MESSAGE - 1, "!t", "^3" ); \
    replace_all( %1, MAX_COLOR_MESSAGE - 1, "!n", "^1" ); \
    replace_all( %1, MAX_COLOR_MESSAGE - 1, "!y", "^1" ); \
}

/**
 * Remove the colored strings codes '^4 for green', '^1 for yellow', '^3 for team' and
 * '^2 for unknown'.
 *
 * @param string[]       a string pointer to be formatted.
 */
#define REMOVE_CODE_COLOR_TAGS(%1) \
{ \
    replace_all( %1, MAX_COLOR_MESSAGE - 1, "^4", "" ); \
    replace_all( %1, MAX_COLOR_MESSAGE - 1, "^3", "" ); \
    replace_all( %1, MAX_COLOR_MESSAGE - 1, "^2", "" ); \
    replace_all( %1, MAX_COLOR_MESSAGE - 1, "^1", "" ); \
}

/**
 * Remove the colored strings codes '!g for green', '!y for yellow', '!t for team' and
 * '!n for unknown'.
 *
 * @param string[]       a string pointer to be formatted.
 */
#define REMOVE_LETTER_COLOR_TAGS(%1) \
{ \
    replace_all( %1, MAX_COLOR_MESSAGE - 1, "!g", "" ); \
    replace_all( %1, MAX_COLOR_MESSAGE - 1, "!t", "" ); \
    replace_all( %1, MAX_COLOR_MESSAGE - 1, "!n", "" ); \
    replace_all( %1, MAX_COLOR_MESSAGE - 1, "!y", "" ); \
}

/**
 * Print to the users chat, a colored chat message.
 *
 * @param player_id     a player id from 1 to MAX_PLAYERS
 * @param message       a colored formatted string message. At the AMXX 182 it must start within
 *                      one color code as found on REMOVE_CODE_COLOR_TAGS(1) above macro. Example:
 *                      "^1Hi! I am a ^3 colored message".
 */
#define PRINT_COLORED_MESSAGE(%1,%2) \
{ \
    message_begin( MSG_ONE_UNRELIABLE, g_user_msgid, _, %1 ); \
    write_byte( %1 ); \
    write_string( %2 ); \
    message_end(); \
}

/**
 * Get the player name. If the player is not connected, uses "Unknown Dude" as its name.
 *
 * @param player_id          the player id
 * @param name_string        a string pointer to hold the player name.
 */
#define GET_USER_NAME(%1,%2) \
{ \
    if( is_user_connected( %1 ) ) \
    { \
        get_user_name( %1, %2, charsmax( %2 ) ); \
    } \
    else \
    { \
        copy( %2, charsmax( %2 ), "Unknown Dude" ); \
    } \
}

/**
 * Helper to adjust the menus options 'back', 'next' and exit. This requires prior definition of
 * the variables 'menuOptionString[ MAX_SHORT_STRING ] and 'player_id', where the player id must
 * point to the player identification number which will see the menu.
 *
 * @param propertyConstant        one of the new menu property constants
 * @param menuId                  the menu identification number
 * @param langConstantName        the dictionary registered LANG constant
 */
#define SET_MENU_LANG_STRING_PROPERTY(%1,%2,%3) \
{ \
    formatex( menuOptionString, charsmax( menuOptionString ), "%L", player_id, %3 ); \
    menu_setprop( %2, %1, menuOptionString ); \
}

/**
 * Accept a map as valid, even when they end with `.bsp`.
 */
#define IS_MAP_VALID_BSP(%1) ( is_map_valid( %1 ) || is_map_valid_bsp_check( %1 ) )

/**
 * Split the map name from a string.
 *
 * @param textLine   a string containing a map name at the first part
 * @param mapName    a string to save the map extracted
 */
#define GET_MAP_NAME_LEFT(%2,%3) \
{ \
    STR_TOKEN( %2,                   %3, MAX_MAPNAME_LENGHT - 1, \
               __g_getMapNameRightToken, MAX_MAPNAME_LENGHT - 1, ' ' ); \
}

/**
 * Split the map info from a string.
 *
 * @param textLine   a string containing a map info at the second part
 * @param mapName    a string to save the map extracted
 */
#define GET_MAP_INFO_RIGHT(%2,%3) \
{ \
    STR_TOKEN( %2, __g_getMapNameRightToken, MAX_MAPNAME_LENGHT - 1, \
               %3                          , MAX_MAPNAME_LENGHT - 1, ' ' ); \
}

/**
 * Internal variables used by the GET_MAP_NAME(3) and GET_MAP_INFO(3) macros.
 * By conversion, never ever a Trie will store together the map information/info,
 * only the map name as the hash key.
 */
new __g_getMapNameInputLine [ MAX_MAPNAME_LENGHT ];
new __g_getMapNameRightToken[ MAX_MAPNAME_LENGHT ];

/**
 * Retrieves a map name from a Dynamic Array of maps.
 *
 * @param mapArray       a Dynamic Array of maps
 * @param mapIndex       an valid index on the `mapArray` parameter
 * @param mapName        a string to store the map name
 */
#define GET_MAP_NAME(%1,%2,%3) \
{ \
    ArrayGetString( %1, %2, __g_getMapNameInputLine, MAX_MAPNAME_LENGHT - 1 ); \
    GET_MAP_NAME_LEFT( __g_getMapNameInputLine, %3 ) \
}

/**
 * Retrieves a map name from a Dynamic Array of maps.
 *
 * @param mapArray       a Dynamic Array of maps
 * @param mapIndex       an valid index on the `mapArray` parameter
 * @param mapName        a string to store the map name
 */
#define GET_MAP_INFO(%1,%2,%3) \
{ \
    ArrayGetString( %1, %2, __g_getMapNameInputLine, MAX_MAPNAME_LENGHT - 1 ); \
    GET_MAP_INFO_RIGHT( __g_getMapNameInputLine, %3 ) \
}

/**
 * Check whether a line not a commentary, empty and if it is a valid map by IS_MAP_VALID(1).
 *
 * @param currentLine a string within the line to check.
 */
#define IS_IT_A_VALID_MAP_LINE(%1) \
    ( %1[ 0 ] \
      && !equal( %1, "//", 2 ) \
      && !equal( %1, ";", 1 ) )

/**
 * General handler to assist object property applying and keep the code clear. This only need
 * to be used with destructors/cleaners which does not support uninitialized handlers, requiring
 * an if pre-checking.
 *
 * @param objectHandler           the object handler to be called.
 * @param objectIndentifation     the object identification number to be destroyed.
 */
#define TRY_TO_APPLY(%1,%2) \
{ \
    LOGGER( 128, "I AM ENTERING ON TRY_TO_APPLY(2) objectIndentifation: %d", %2 ) \
    if( %2 ) \
    { \
        %1( %2 ); \
    } \
}

/**
 * Check whether the menu exists, call menu_destroy(1) and set the menu to id to 0.
 *
 * @param menu_id_variable    a variable within the player menu to be destroyed.
 */
#define DESTROY_PLAYER_NEW_MENU_TYPE(%1) \
{ \
    LOGGER( 128, "I AM ENTERING ON DESTROY_PLAYER_NEW_MENU_TYPE(1) menu_id: %d", %1 ) \
    if( %1 ) \
    { \
        menu_destroy( %1 ); \
        %1 = 0; \
    } \
}

/**
 * Check whether the menu exists, call menu_destroy(1) and set the menu to id to 0.
 *
 * @param menu_id_variable    a variable within the player menu to be destroyed.
 */
#define TOGGLE_BIT_FLAG_ON_OFF(%1,%2) \
{ \
    LOGGER( 256, "I AM ENTERING ON TOGGLE_BIT_FLAG_ON_OFF(2) mask: %d, flag: %d", %1, %2 ) \
    %1 & %2 ? ( %1 &= ~%2 ) : ( %1 |= %2 ); \
}

/**
 * Calculate which is the number of the last menu page.
 *
 * @param totalMenuItems     how many items there are on the menu
 * @param menuItemPerPage    how much items there are on each menu's page
 */
#define GET_LAST_PAGE_NUMBER(%1,%2) \
        ( ( ( %1 + 1 ) / %2 ) \
    + ( ( ( ( %1 + 1 ) % %2 ) > 0 ) ? 1 : 0 ) );



// General Global Variables
// ###############################################################################################

/**
 * Dummy value used on conditional statements to allow statements as always true or false.
 */
new const bool:g_dummy_value = false;

/**
 * Task ids are 100000 apart.
 */
enum (+= 100000)
{
    TASKID_RTV_REMINDER = 100000, // start with 100000
    TASKID_SHOW_LAST_ROUND_HUD,
    TASKID_SHOW_LAST_ROUND_MESSAGE,
    TASKID_DELETE_USERS_MENUS,
    TASKID_DELETE_USERS_MENUS_CARE,
    TASKID_PREVENT_INFITY_GAME,
    TASKID_EMPTYSERVER,
    TASKID_START_VOTING_DELAYED,
    TASKID_PROCESS_LAST_ROUND,
    TASKID_DISPLAY_REMAINING_TIME,
    TASKID_PROCESS_LAST_ROUND_COUNT,
    TASKID_PROCESS_LAST_ROUNDCHANGE,
    TASKID_VOTE_HANDLEDISPLAY,
    TASKID_VOTE_DISPLAY,
    TASKID_VOTE_EXPIRE,
    TASKID_PENDING_VOTE_COUNTDOWN,
    TASKID_DBG_FAKEVOTES,
    TASKID_VOTE_STARTDIRECTOR,
    TASKID_MAP_CHANGE,
    TASKID_INTERMISSION_HOLD,
    TASKID_FINISH_GAME_TIME_BY_HALF,
}


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
new cvar_mp_friendlyfire;
new cvar_sv_maxspeed;


/**
 * Server cvars.
 */
new cvar_extendmapAllowStayType;
new cvar_nextMapChangeAnnounce;
new cvar_nextMapChangeVotemap;
new cvar_disabledValuePointer;
new cvar_isFirstServerStart;
new cvar_isToShowVoteCounter;
new cvar_isToShowNoneOption;
new cvar_voteShowNoneOptionType;
new cvar_isExtendmapOrderAllowed;
new cvar_isToStopEmptyCycle;
new cvar_successfullLevels;
new cvar_unnominateDisconnected;
new cvar_endOnRound;
new cvar_endOnRoundChange;
new cvar_endOfMapVote;
new cvar_endOfMapVoteExpiration;
new cvar_endOfMapVoteStart;
new cvar_endOnRoundRtv;
new cvar_endOnRoundMininum;
new cvar_voteWeight;
new cvar_voteWeightFlags;
new cvar_maxMapExtendTime;
new cvar_extendmapStepMinutes;
new cvar_extendmapStepRounds;
new cvar_maxMapExtendRounds;
new cvar_extendmapStepFrags;
new cvar_maxMapExtendFrags;
new cvar_fragLimitSupport;
new cvar_extendmapAllowStay;
new cvar_isToAskForEndOfTheMapVote;
new cvar_emptyServerWaitMinutes;
new cvar_isEmptyCycleByMapChange;
new cvar_emptyMapFilePath;
new cvar_rtvWaitMinutes;
new cvar_rtvWaitRounds;
new cvar_rtvWaitFrags;
new cvar_rtvWaitAdmin;
new cvar_rtvRatio;
new cvar_rtvCommands;
new cvar_cmdVotemap;
new cvar_cmdListmaps;
new cvar_listmapsPaginate;
new cvar_recentMapsBannedNumber;
new cvar_recentNomMapsAllowance;
new cvar_isOnlyRecentMapcycleMaps;
new cvar_banRecentStyle;
new cvar_voteDuration;
new cvar_nomMapFilePath;
new cvar_nomPrefixes;
new cvar_nomQtyUsed;
new cvar_nomPlayerAllowance;
new cvar_nomCleaning;
new cvar_isToShowExpCountdown;
new cvar_isEndMapCountdown;
new cvar_voteMapChoiceCount;
new cvar_voteMapChoiceNext;
new cvar_voteAnnounceChoice;
new cvar_voteUniquePrefixes;
new cvar_rtvReminder;
new cvar_serverStartAction;
new cvar_serverMoveCursor;
new cvar_gameCrashRecreationAction;
new cvar_serverTimeLimitRestart;
new cvar_serverMaxroundsRestart;
new cvar_serverWinlimitRestart;
new cvar_serverFraglimitRestart;
new cvar_runoffEnabled;
new cvar_runoffDuration;
new cvar_runoffRatio;
new cvar_runoffMapchoices;
new cvar_showVoteStatus;
new cvar_showVoteStatusType;
new cvar_isToReplaceByVoteMenu;
new cvar_soundsMute;
new cvar_hudsHide;
new cvar_voteMapFilePath;
new cvar_voteMinPlayers;
new cvar_voteMidPlayers;
new cvar_nomMinPlayersControl;
new cvar_voteMinPlayersMapFilePath;
new cvar_voteMidPlayersMapFilePath;
new cvar_whitelistType;
new cvar_whitelistMinPlayers;
new cvar_isWhiteListNomBlock;
new cvar_isWhiteListBlockOut;
new cvar_voteWhiteListMapFilePath;
new cvar_coloredChatPrefix;


/**
 * Various Artists.
 */
new const MAP_FOLDER_LOAD_FLAG[]            = "*";
new const MAP_CYCLE_LOAD_FLAG[]             = "#";
new const GAL_VOTEMAP_MENU_COMMAND[]        = "galmenu";
new const LAST_EMPTY_CYCLE_FILE_NAME[]      = "lastEmptyCycleMapName.dat";
new const CURRENT_AND_NEXTMAP_FILE_NAME[]   = "currentAndNextmapNames.dat";
new const LAST_CHANGE_MAP_FILE_NAME[]       = "lastChangedMapName.dat";
new const RECENT_BAN_MAPS_FILE_NAME[]       = "recentMaps.dat";
new const CHOOSE_MAP_MENU_NAME[]            = "gal_menuChooseMap";
new const CHOOSE_MAP_MENU_QUESTION[]        = "chooseMapQuestion";
new const CHOOSE_VOTEMAP_MENU_QUESTION[]    = "chooseVoteMapQuestion";
new const GAME_CRASH_RECREATION_FLAG_FILE[] = "gameCrashRecreationAction.txt";
new const TO_STOP_THE_CRASH_SEARCH[]        = "delete_this_to_stop_the_crash_search.txt";
new const MAPS_WHERE_THE_SERVER_CRASHED[]   = "maps_where_the_server_probably_crashed.txt";

new bool:g_isTheRoundEndWhileVoting;
new bool:g_isTimeToResetGame;
new bool:g_isTimeToResetRounds;
new bool:g_isUsingEmptyCycle;
new bool:g_isRunOffNeedingKeepCurrentMap;
new bool:g_isExtendmapAllowStay;
new bool:g_isToShowNoneOption;
new bool:g_isToShowSubMenu;
new bool:g_isToShowExpCountdown;
new bool:g_isToShowVoteCounter;
new bool:g_isEmptyCycleMapConfigured;
new bool:g_isTheLastGameRound;
new bool:g_isThePenultGameRound;
new bool:g_isToChangeMapOnVotingEnd;
new bool:g_isVirtualFragLimitSupport;
new bool:g_isTimeToRestart;
new bool:g_isEndGameLimitsChanged;
new bool:g_isMapExtensionAllowed;
new bool:g_isGameFinalVoting;
new bool:g_isOnMaintenanceMode;
new bool:g_isToCreateGameCrashFlag;
new bool:g_isToRestoreFriendlyFire;

new Float:g_rtvWaitMinutes;
new Float:g_originalTimelimit;
new Float:g_original_sv_maxspeed;
new Float:g_originalChatTime;


/**
 * Holds the Empty Cycle Map List feature maps used when the server is empty for some time to
 * change the map to a popular one.
 */
new Array:g_emptyCycleMapsArray;

/**
 * Stores all the player's nominations indexes within a array of the size MAX_OPTIONS_IN_VOTE,
 * for the given trieKey by createPlayerNominationKey(3).
 *
 * Each player's nomination index is the index to the array `g_nominationLoadedMapsArray` containing
 * all the nomination maps available to be nominated.
 */
new Trie:g_forwardSearchNominationsTrie;

/**
 * Stores the nominator's `MapNominationsType` enum by a given map index. It is used to find out
 * the data stored by the `MapNominationsType` enum for the given nominated map index.
 */
new Trie:g_reverseSearchNominationsTrie;

/**
 * Enumeration used to create access to `g_reverseSearchNominationsTrie` values. It is an untagged type to
 * allow it to be passed through the TrieSetArray(3).
 *
 * The `MapNomination_PlayerId`        saves the id of the player which nominated the map.
 * The `MapNomination_NominatedIndex`  saves the nomination index on the `g_nominatedMapsArray`.
 * The `MapNomination_NominationIndex` saves the player's personal nominations array index.
 */
enum _:MapNominationsType
{
    MapNomination_PlayerId,
    MapNomination_NominatedIndex,
    MapNomination_NominationIndex
}

/**
 * A simple list to keep track of the nominated maps managed by `g_forwardSearchNominationsTrie` and
 * `g_reverseSearchNominationsTrie`.
 */
new Array:g_nominatedMapsArray;

/**
 * The ban recent maps variables.
 */
new Trie: g_recentMapsTrie;
new Array:g_recentListMapsArray;

/**
 * Contains the current loaded Whilelist from the array `g_whitelistFileArray` for the Whilelist Out Block
 * feature `cvar_isWhiteListBlockOut`.
 */
new Array:g_whitelistArray;

/**
 * Contains all the loaded valid lines from the Whitelist file contents.
 */
new Array:g_whitelistFileArray;

/**
 * Contains all the loaded valid maps for the `gal_srv_move_cursor` feature. If the feature is disabled,
 * it contains only the normal/usual loaded maps from the map cycle file.
 */
new Trie:g_mapcycleFileListTrie;
new Array:g_mapcycleFileListArray;

/**
 * Contains all the allowed maps to be added as nominations or as voting map fillers.
 */
new Trie: g_whitelistTrie;

/**
 * Contains all the blocked maps to be added as nominations or as voting map fillers.
 */
new Trie: g_blacklistTrie;

/**
 * Contains all loaded nominations maps from the nomination file list.
 */
new Array:g_nominationLoadedMapsArray;

/**
 * Contains all loaded nominations maps from the nomination file list, for fast search.
 */
new Trie:g_nominationLoadedMapsTrie;

/**
 * Contains the paths to the voting fillers files.
 */
new Array:g_voteMinPlayerFillerPathsArray;
new Array:g_voteMidPlayerFillerPathsArray;
new Array:g_voteNorPlayerFillerPathsArray;

/**
 * Contains how much maps per map group file to load.
 */
new Array:g_minMaxMapsPerGroupToUseArray;
new Array:g_midMaxMapsPerGroupToUseArray;
new Array:g_norMaxMapsPerGroupToUseArray;

/**
 * Contains a Dynamic Array of Dynamic Arrays. Each one of the sub-arrays contains the maps loaded
 * from the Array `g_voteMinPlayerFillerPathsArray` for each of the its paths receptively.
 */
new Array:g_minPlayerFillerMapGroupArrays;
new Array:g_midPlayerFillerMapGroupArrays;
new Array:g_norPlayerFillerMapGroupArrays;

/**
 * Create a new type to perform the switch between the Minimum Players feature and the Normal
 * Voting map filling.
 */
enum fillersFilePathType
{
    fillersFilePaths_MininumPlayers,
    fillersFilePaths_MiddlePlayers,
    fillersFilePaths_NormalPlayers
}

/**
 * Saves the partial nomination map name attempt to allow the partial nomination menu to be build
 * by demand.
 */
new g_nominationPartialNameAttempt[ MAX_PLAYERS_COUNT   ][ MAX_MAPNAME_LENGHT      ];

/**
 * Saves the last partial nomination menu map index to allow the menu to be rewind to the last
 * visited page.
 */
new Array:g_partialMatchFirstPageItems[ MAX_PLAYERS_COUNT ];

/**
 * Indicates whether the player already saw the first partial nomination menu page. This is useful
 * when the player rewind to the first partial nomination menu page.
 */
new bool:g_isSawPartialMatchFirstPage[ MAX_PLAYERS_COUNT ];

/**
 * Create a new type to perform the switch between voting by rounds, time or frags limit.
 */
enum GameEndingType
{
    GameEndingType_ByNothing,
    GameEndingType_ByWinLimit,
    GameEndingType_ByMaxRounds,
    GameEndingType_ByTimeLimit,
    GameEndingType_ByFragLimit
}

/**
 * This is the `GameEndingType` context returned by whatGameEndingTypeItIs(0) when the global variable
 * `g_isGameEndingTypeContextSaved` is set to true by map_manageEnd(0).
 */
new bool:g_isGameEndingTypeContextSaved;
new GameEndingType:g_gameEndingTypeContextSaved;

new g_timeLeftContextSaved;
new g_maxRoundsContextSaved;
new g_winLimitContextSaved;
new g_fragLimitContextSaved;

/**
 * Not saving these contexts on saveGameEndingTypeContext(0) will for the last round map change to fail
 * on several configurations set by `cvar_endOnRound` and `cvar_endOfMapVoteStart`.
 */
new bool:g_isTheLastGameRoundContext;
new bool:g_isThePenultGameRoundContext;


new g_totalRoundsSavedTimes;
new g_roundAverageTime;
new g_totalVoteTime;
new g_roundStartTime;
new g_originalMaxRounds;
new g_originalWinLimit;
new g_originalFragLimit;
new g_showVoteStatusType;
new g_extendmapStepRounds;
new g_extendmapStepFrags;
new g_extendmapStepMinutes;
new g_extendmapAllowStayType;
new g_showVoteStatus;
new g_voteShowNoneOptionType;
new g_pendingVoteCountdown;
new g_showLastRoundHudCounter;
new g_pendingMapVoteCountdown;
new g_lastRoundCountdown;
new g_rtvWaitAdminNumber;
new g_emptyCycleMapsNumber;
new g_recentMapCount;
new g_rtvCommands;
new g_rtvWaitRounds;
new g_rtvWaitFrags;
new g_rockedVoteCount;
new g_winLimitInteger;
new g_maxRoundsNumber;
new g_fragLimitNumber;
new g_greatestKillerFrags;
new g_timeLimitNumber;
new g_totalRoundsPlayed;
new g_whitelistNomBlockTime;

new g_totalTerroristsWins;
new g_totalCtWins;
new g_totalVoteOptions;

new g_maxVotingChoices;
new g_voteStatus;
new g_voteMapStatus;
new g_endVotingType;
new g_voteMapInvokerPlayerId;
new g_votingSecondsRemaining;
new g_totalVotesCounted;

new COLOR_RED   [ 3 ]; // \r
new COLOR_WHITE [ 3 ]; // \w
new COLOR_YELLOW[ 3 ]; // \y
new COLOR_GREY  [ 3 ]; // \d

new g_mapPrefixCount = 1;

new g_voteWeightFlags     [ 32 ];
new g_voteStatus_symbol   [ 3  ];
new g_coloredChatPrefix   [ 16 ];
new g_arrayOfRunOffChoices[ MAX_OPTIONS_IN_VOTE ];
new g_voteStatusClean     [ MAX_BIG_BOSS_STRING ];

new g_configsDirPath[ MAX_FILE_PATH_LENGHT ];
new g_dataDirPath   [ MAX_FILE_PATH_LENGHT ];


/**
 * Nextmap sub-plugin global variables.
 */
new cvar_amx_nextmap;
new cvar_mapcyclefile;
new g_nextMapCyclePosition;


new g_invokerVoteMapNameToDecide[ MAX_MAPNAME_LENGHT  ];
new g_nextMapName               [ MAX_MAPNAME_LENGHT  ];
new g_currentMapName            [ MAX_MAPNAME_LENGHT  ];
new g_playerVotedOption         [ MAX_PLAYERS_COUNT   ];
new g_playerVotedWeight         [ MAX_PLAYERS_COUNT   ];
new g_voteMapMenuPages          [ MAX_PLAYERS_COUNT   ];
new g_recentMapsMenuPages       [ MAX_PLAYERS_COUNT   ];
new g_nominationPlayersMenuPages[ MAX_PLAYERS_COUNT   ];
new g_playersKills              [ MAX_PLAYERS_COUNT   ];
new g_arrayOfMapsWithVotesNumber[ MAX_OPTIONS_IN_VOTE ];

new bool:g_isPlayerVoted            [ MAX_PLAYERS_COUNT ] = { true , ... };
new bool:g_isPlayerParticipating    [ MAX_PLAYERS_COUNT ] = { true , ... };
new bool:g_isPlayerClosedTheVoteMenu[ MAX_PLAYERS_COUNT ];
new bool:g_isPlayerSeeingTheSubMenu [ MAX_PLAYERS_COUNT ];
new bool:g_isPlayerSeeingTheVoteMenu[ MAX_PLAYERS_COUNT ];
new bool:g_isPlayerCancelledVote    [ MAX_PLAYERS_COUNT ];
new bool:g_answeredForEndOfMapVote  [ MAX_PLAYERS_COUNT ];
new bool:g_rockedVote               [ MAX_PLAYERS_COUNT ];

new g_mapPrefixes                [ MAX_PREFIX_COUNT    ][ 16                      ];
new g_votingMapNames             [ MAX_OPTIONS_IN_VOTE ][ MAX_MAPNAME_LENGHT      ];
new g_votingMapInfos             [ MAX_OPTIONS_IN_VOTE ][ MAX_MAPNAME_LENGHT      ];
new g_menuMapIndexForPlayerArrays[ MAX_PLAYERS_COUNT   ][ MAX_NOM_MENU_ITEMS_PER_PAGE ];

new g_chooseMapMenuId;
new g_chooseMapQuestionMenuId;
new g_chooseVoteMapQuestionMenuId;


/**
 * Called just after server activation.
 *
 * Good place to initialize most of the plugin, such as registering
 * cvars, commands or forwards, creating data structures for later use, or
 * generating and loading other required configurations.
 */
public plugin_init()
{
#if DEBUG_LEVEL & DEBUG_LEVEL_CRITICAL_MODE
    g_debug_level = 1048575;
#endif

    register_plugin( PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR );
    LOGGER( 1, "^n^n^n^n^n^n^n^n^n^n^n^n%s PLUGIN VERSION %s INITIATING...", PLUGIN_NAME, PLUGIN_VERSION )

    LOGGER( 1, "( plugin_init )" )
    LOGGER( 1, "( plugin_init ) AMXX_VERSION_NUM:                         %d", AMXX_VERSION_NUM )
    LOGGER( 1, "( plugin_init ) IS_TO_ENABLE_SVEN_COOP_SUPPPORT:          %d", IS_TO_ENABLE_SVEN_COOP_SUPPPORT )
    LOGGER( 1, "( plugin_init ) FAKE_PLAYERS_NUMBER_FOR_DEBUGGING:        %d", FAKE_PLAYERS_NUMBER_FOR_DEBUGGING )
    LOGGER( 1, "( plugin_init ) MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST:    %d", MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST )
    LOGGER( 1, "( plugin_init ) IS_TO_ENABLE_RE_HLDS_RE_AMXMODX_SUPPORT:  %d", IS_TO_ENABLE_RE_HLDS_RE_AMXMODX_SUPPORT )

    cvar_extendmapStepMinutes    = register_cvar ( "amx_extendmap_step"           , "15" );
    cvar_maxMapExtendTime        = register_cvar ( "amx_extendmap_max"            , "90" );
    cvar_extendmapStepRounds     = register_cvar ( "amx_extendmap_step_rounds"    , "30" );
    cvar_maxMapExtendRounds      = register_cvar ( "amx_extendmap_max_rounds"     , "0"  );
    cvar_fragLimitSupport        = register_cvar ( "gal_mp_fraglimit_support"     , "0"  );
    cvar_extendmapStepFrags      = register_cvar ( "amx_extendmap_step_frags"     , "60" );
    cvar_maxMapExtendFrags       = register_cvar ( "amx_extendmap_max_frags"      , "0"  );
    cvar_extendmapAllowStay      = register_cvar ( "amx_extendmap_allow_stay"     , "0"  );
    cvar_extendmapAllowStayType  = register_cvar ( "amx_extendmap_allow_stay_type", "0"  );
    cvar_isExtendmapOrderAllowed = register_cvar ( "amx_extendmap_allow_order"    , "0"  );

    register_cvar( "gal_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY );

    // print the current used debug information
#if DEBUG_LEVEL & ( DEBUG_LEVEL_NORMAL | DEBUG_LEVEL_CRITICAL_MODE )
    new debug_level[ MAX_SHORT_STRING ];
    formatex( debug_level, charsmax( debug_level ), "%d | %d", g_debug_level, DEBUG_LEVEL );

    LOGGER( 1, "( plugin_init ) gal_debug_level: %s", debug_level )
    register_cvar( "gal_debug_level", debug_level, FCVAR_SERVER | FCVAR_SPONLY );
#endif

    cvar_cmdVotemap                = register_cvar( "gal_cmd_votemap"             , "0"    );
    cvar_cmdListmaps               = register_cvar( "gal_cmd_listmaps"            , "2"    );
    cvar_listmapsPaginate          = register_cvar( "gal_listmaps_paginate"       , "10"   );
    cvar_recentMapsBannedNumber    = register_cvar( "gal_banrecent"               , "3"    );
    cvar_recentNomMapsAllowance    = register_cvar( "gal_recent_nom_maps"         , "0"    );
    cvar_isOnlyRecentMapcycleMaps  = register_cvar( "gal_banrecent_mapcycle"      , "0"    );
    cvar_banRecentStyle            = register_cvar( "gal_banrecentstyle"          , "1"    );
    cvar_rtvCommands               = register_cvar( "gal_rtv_commands"            , "3"    );
    cvar_rtvWaitMinutes            = register_cvar( "gal_rtv_wait"                , "10"   );
    cvar_rtvWaitRounds             = register_cvar( "gal_rtv_wait_rounds"         , "5"    );
    cvar_rtvWaitFrags              = register_cvar( "gal_rtv_wait_frags"          , "20"   );
    cvar_rtvWaitAdmin              = register_cvar( "gal_rtv_wait_admin"          , "0"    );
    cvar_rtvRatio                  = register_cvar( "gal_rtv_ratio"               , "0.60" );
    cvar_rtvReminder               = register_cvar( "gal_rtv_reminder"            , "2"    );
    cvar_runoffEnabled             = register_cvar( "gal_runoff_enabled"          , "0"    );
    cvar_runoffDuration            = register_cvar( "gal_runoff_duration"         , "10"   );
    cvar_runoffRatio               = register_cvar( "gal_runoff_ratio"            , "0.5"  );
    cvar_runoffMapchoices          = register_cvar( "gal_runoff_mapchoices"       , "2"    );
    cvar_voteWeight                = register_cvar( "gal_vote_weight"             , "1"    );
    cvar_voteWeightFlags           = register_cvar( "gal_vote_weightflags"        , "y"    );
    cvar_showVoteStatus            = register_cvar( "gal_vote_showstatus"         , "1"    );
    cvar_showVoteStatusType        = register_cvar( "gal_vote_showstatustype"     , "3"    );
    cvar_isToReplaceByVoteMenu     = register_cvar( "gal_vote_replace_menu"       , "0"    );
    cvar_isToShowNoneOption        = register_cvar( "gal_vote_show_none"          , "0"    );
    cvar_voteShowNoneOptionType    = register_cvar( "gal_vote_show_none_type"     , "0"    );
    cvar_isToShowExpCountdown      = register_cvar( "gal_vote_expirationcountdown", "1"    );
    cvar_isToShowVoteCounter       = register_cvar( "gal_vote_show_counter"       , "0"    );
    cvar_isToAskForEndOfTheMapVote = register_cvar( "gal_endofmapvote_ask"        , "0"    );
    cvar_serverStartAction         = register_cvar( "gal_srv_start"               , "0"    );
    cvar_serverMoveCursor          = register_cvar( "gal_srv_move_cursor"         , "0"    );
    cvar_gameCrashRecreationAction = register_cvar( "gal_game_crash_recreation"   , "0"    );
    cvar_serverTimeLimitRestart    = register_cvar( "gal_srv_timelimit_restart"   , "0"    );
    cvar_serverMaxroundsRestart    = register_cvar( "gal_srv_maxrounds_restart"   , "0"    );
    cvar_serverWinlimitRestart     = register_cvar( "gal_srv_winlimit_restart"    , "0"    );
    cvar_serverFraglimitRestart    = register_cvar( "gal_srv_fraglimit_restart"   , "0"    );
    cvar_endOfMapVote              = register_cvar( "gal_endofmapvote"            , "1"    );
    cvar_endOfMapVoteExpiration    = register_cvar( "gal_endofmapvote_expiration" , "1"    );
    cvar_endOfMapVoteStart         = register_cvar( "gal_endofmapvote_start"      , "0"    );
    cvar_nextMapChangeAnnounce     = register_cvar( "gal_nextmap_change"          , "1"    );
    cvar_nextMapChangeVotemap      = register_cvar( "gal_nextmap_votemap"         , "0"    );
    cvar_endOnRound                = register_cvar( "gal_endonround"              , "1"    );
    cvar_endOnRoundChange          = register_cvar( "gal_endonround_change"       , "1"    );
    cvar_endOnRoundRtv             = register_cvar( "gal_endonround_rtv"          , "0"    );
    cvar_endOnRoundMininum         = register_cvar( "gal_endonround_msg"          , "0"    );
    cvar_isEndMapCountdown         = register_cvar( "gal_endonround_countdown"    , "0"    );
    cvar_voteMapChoiceCount        = register_cvar( "gal_vote_mapchoices"         , "5"    );
    cvar_voteMapChoiceNext         = register_cvar( "gal_vote_mapchoices_next"    , "0"    );
    cvar_voteDuration              = register_cvar( "gal_vote_duration"           , "15"   );
    cvar_voteMapFilePath           = register_cvar( "gal_vote_mapfile"            , "*"    );
    cvar_voteMinPlayers            = register_cvar( "gal_vote_minplayers"         , "0"    );
    cvar_voteMidPlayers            = register_cvar( "gal_vote_midplayers"         , "0"    );
    cvar_nomMinPlayersControl      = register_cvar( "gal_nom_minplayers_control"  , "0"    );
    cvar_voteMinPlayersMapFilePath = register_cvar( "gal_vote_minplayers_mapfile" , ""     );
    cvar_voteMidPlayersMapFilePath = register_cvar( "gal_vote_midplayers_mapfile" , ""     );
    cvar_whitelistType             = register_cvar( "gal_whitelist_type"          , "0"    );
    cvar_whitelistMinPlayers       = register_cvar( "gal_whitelist_minplayers"    , "0"    );
    cvar_isWhiteListNomBlock       = register_cvar( "gal_whitelist_nom_block"     , "0"    );
    cvar_isWhiteListBlockOut       = register_cvar( "gal_whitelist_block_out"     , "0"    );
    cvar_voteWhiteListMapFilePath  = register_cvar( "gal_vote_whitelist_mapfile"  , ""     );
    cvar_voteUniquePrefixes        = register_cvar( "gal_vote_uniqueprefixes"     , "0"    );
    cvar_nomPlayerAllowance        = register_cvar( "gal_nom_playerallowance"     , "2"    );
    cvar_nomCleaning               = register_cvar( "gal_nom_cleaning"            , "1"    );
    cvar_nomMapFilePath            = register_cvar( "gal_nom_mapfile"             , "*"    );
    cvar_nomPrefixes               = register_cvar( "gal_nom_prefixes"            , "1"    );
    cvar_nomQtyUsed                = register_cvar( "gal_nom_qtyused"             , "0"    );
    cvar_unnominateDisconnected    = register_cvar( "gal_unnominate_disconnected" , "0"    );
    cvar_voteAnnounceChoice        = register_cvar( "gal_vote_announcechoice"     , "1"    );
    cvar_emptyServerWaitMinutes    = register_cvar( "gal_emptyserver_wait"        , "0"    );
    cvar_isEmptyCycleByMapChange   = register_cvar( "gal_emptyserver_change"      , "0"    );
    cvar_emptyMapFilePath          = register_cvar( "gal_emptyserver_mapfile"     , ""     );
    cvar_soundsMute                = register_cvar( "gal_sounds_mute"             , "0"    );
    cvar_hudsHide                  = register_cvar( "gal_sounds_hud"              , "0"    );
    cvar_coloredChatPrefix         = register_cvar( "gal_colored_chat_prefix"     , ""     );

    // Enables the colored chat control cvar.
    cvar_coloredChatEnabled = register_cvar( "gal_colored_chat_enabled", "0", FCVAR_SPONLY );

    // Not a configurable cvar, this is used instead of the `localinfo`.
    //
    // When `cvar_isFirstServerStart` set set to 2 we are on the first server start period. If this
    // is set to 1, we are on the beginning of the second server map change level.
    cvar_isFirstServerStart = register_cvar( "gal_server_starting"    , "2", FCVAR_SPONLY );
    cvar_isToStopEmptyCycle = register_cvar( "gal_in_empty_cycle"     , "0", FCVAR_SPONLY );
    cvar_successfullLevels  = register_cvar( "gal_successfull_levels" , "0", FCVAR_SPONLY );

    // This is a general pointer used for cvars not registered on the game.
    cvar_disabledValuePointer = register_cvar( "gal_disabled_value_pointer", "0", FCVAR_SPONLY );

    configureEndGameCvars();
    nextmapPluginInit();
    timeleftPluginInit();
    configureTheVotingMenus();
    configureSpecificGameModFeature();

    register_dictionary( "common.txt" );
    register_dictionary( "cmdmenu.txt" );
    register_dictionary( "mapsmenu.txt" );
    register_dictionary( "adminvote.txt" );
    register_dictionary_colored( "galileo.txt" );

    register_event( "HLTV", "new_round_event", "a", "1=0", "2=0");
    register_logevent( "game_commencing_event", 2, "0=World triggered", "1=Game_Commencing" );
    register_logevent( "team_win_event",        6, "0=Team" );
    register_logevent( "round_restart_event",   2, "0=World triggered", "1&Restart_Round_" );
    register_logevent( "round_start_event",     2, "1=Round_Start" );
    register_logevent( "round_end_event",       2, "1=Round_End" );

    register_clcmd( "say", "cmd_say", -1 );
    register_clcmd( "say_team", "cmd_say", -1 );
    register_clcmd( "votemap", "cmd_HL1_votemap" );
    register_clcmd( "listmaps", "cmd_HL1_listmaps" );
    register_clcmd( "gal_votemap", "cmd_voteMap", ADMIN_MAP );

    register_concmd( "gal_startvote", "cmd_startVote", ADMIN_MAP );
    register_concmd( "gal_cancelvote", "cmd_cancelVote", ADMIN_MAP );
    register_concmd( "gal_changelevel", "cmd_changeLevel", ADMIN_MAP );
    register_concmd( "gal_createmapfile", "cmd_createMapFile", ADMIN_RCON );
    register_concmd( "gal_command_maintenance", "cmd_maintenanceMode", ADMIN_RCON );
    register_concmd( "gal_looking_for_crashes", "cmd_lookingForCrashes", ADMIN_RCON );

    LOGGER( 1, "    I AM EXITING plugin_init(0)..." )
    LOGGER( 1, "" )
}

/**
 * Called when all plugins went through plugin_init(). When this forward is called, most plugins
 * should have registered their cvars and commands already.
 */
public plugin_cfg()
{
    LOGGER( 128, "I AM ENTERING ON plugin_cfg(0)" )

    /**
     * Register the color chat 'g_user_msgid' variable, for the AMXX 182.
     */
#if AMXX_VERSION_NUM < 183
    // If some exception happened before this, all color_print(...) messages will cause native
    // error 10, on the AMXX 182. It is because, the execution flow will not reach here, then
    // the player "g_user_msgid" will be be initialized.
    g_user_msgid = get_user_msgid( "SayText" );
#endif

    // Load the initial settings
    loadPluginSetttings();
    initializeGlobalArrays();
    loadNextMapPluginSetttings();

    LOGGER( 4, "" )
    LOGGER( 4, "" )

    // the 'mp_fraglimitCvarSupport(0)' could register a new cvar, hence only call 'cacheCvarsValues' them after it.
    mp_fraglimitCvarSupport();
    cacheCvarsValues();
    resetRoundsScores();

    // re-cache later to wait load some late server configurations, as the per-map configs.
    set_task( DELAY_TO_WAIT_THE_SERVER_CVARS_TO_BE_LOADED, "cacheCvarsValues" );

    LOGGER( 4, "" )
    LOGGER( 4, " The current map is [%s].", g_currentMapName )
    LOGGER( 4, " The next map is [%s]", g_nextMapName )
    LOGGER( 4, "" )

    configureTheRTVFeature();
    configureTheWhiteListFeature();

    LOGGER( 4, "" )
    LOGGER( 4, "" )

    configureServerStart();
    configureServerMapChange();

    cacheCvarsValues();
    loadMapFiles();

    // Configure the Unit Tests, when they are activate.
#if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED )
    configureTheUnitTests();
#endif

    // Used to loop through all server maps looking for crashing ones
    runTheServerMapCrashSearch();

    LOGGER( 1, "    I AM EXITING plugin_cfg(0)..." )
    LOGGER( 1, "" )
}

stock runTheServerMapCrashSearch()
{
    new modeFlagFilePath[ MAX_FILE_PATH_LENGHT ];
    formatex( modeFlagFilePath, charsmax( modeFlagFilePath ), "%s/%s", g_dataDirPath, TO_STOP_THE_CRASH_SEARCH );

    if( IS_TO_ALLOW_A_CRASH_SEARCH( modeFlagFilePath ) )
    {
        new Float:delay;

        new successfullLevels;
        new currentDate[ MAX_SHORT_STRING ];

        get_time( "%m/%d/%Y - %H:%M:%S", currentDate, charsmax( currentDate ) );
        successfullLevels = get_pcvar_num( cvar_successfullLevels );

        server_print( "^n%s", currentDate );
        server_print( "The current map is: %s", g_currentMapName );
        server_print( "The next map will be: %s", g_nextMapName );
        server_print( "Successfully completed server change levels without crash: %d^n", successfullLevels );

        // Allow the admin to connect to the server and to disable the command `gal_looking_for_crashes`.
        delay = get_real_players_number() ? 100.0 : 7.0;
        server_print( "The server is changing level in %d seconds!", floatround( delay, floatround_floor ) );

        set_pcvar_num( cvar_mp_chattime, 3 );
        set_pcvar_num( cvar_serverMoveCursor, 0 );
        set_pcvar_num( cvar_successfullLevels, successfullLevels + 1 );

        set_task( delay, "changeMapIntermission" );
        set_pcvar_string( cvar_mapcyclefile, modeFlagFilePath );
    }
}

stock configureSpecificGameModFeature()
{
    // If it is enabled, Load whether the color chat is supported by the current Game Modification.
    g_isColorChatSupported = ( is_running( "czero" )
                               || is_running( "cstrike" ) );

    // On the first server start, we do not know whether the color chat is allowed/enabled. This is due
    // the register register_dictionary_colored(1) to be called on plugin_init(0) and the settings being
    // loaded only at plugin_cfg(0).
    g_isColoredChatEnabled = get_pcvar_num( cvar_coloredChatEnabled ) != 0;

    // Register the voting start call from the Sven Coop game.
#if IS_TO_ENABLE_SVEN_COOP_SUPPPORT > 0
    if( is_running("svencoop") )
    {
        RegisterHam( Ham_Use, "game_end", "startVotingByGameEngineCall", false );
    }
#endif

    if( colored_menus() )
    {
        copy( COLOR_RED, 2, "\r" );
        copy( COLOR_WHITE, 2, "\w" );
        copy( COLOR_YELLOW, 2, "\y" );
        copy( COLOR_GREY, 2, "\d" );
    }
}

/**
 * All these cvars must to be set using the tryToSetGameModCvarNum(2), tryToSetGameModCvarString(2)
 * and tryToSetGameModCvarFloat(2) functions.
 */
stock configureEndGameCvars()
{
    LOGGER( 128, "I AM ENTERING ON configureEndGameCvars(0)" )

    tryToGetGameModCvar( cvar_mp_maxrounds    , "mp_maxrounds"     );
    tryToGetGameModCvar( cvar_mp_winlimit     , "mp_winlimit"      );
    tryToGetGameModCvar( cvar_mp_freezetime   , "mp_freezetime"    );
    tryToGetGameModCvar( cvar_mp_timelimit    , "mp_timelimit"     );
    tryToGetGameModCvar( cvar_mp_roundtime    , "mp_roundtime"     );
    tryToGetGameModCvar( cvar_mp_chattime     , "mp_chattime"      );
    tryToGetGameModCvar( cvar_mp_friendlyfire , "mp_friendlyfire"  );
    tryToGetGameModCvar( cvar_sv_maxspeed     , "sv_maxspeed"      );
    tryToGetGameModCvar( cvar_mapcyclefile    , "mapcyclefile"     );

#if IS_TO_ENABLE_SVEN_COOP_SUPPPORT > 0
    tryToGetGameModCvar( cvar_mp_nextmap_cycle, "mp_nextmap_cycle" );
#endif
}

stock tryToGetGameModCvar( &cvar_to_get, cvar_name[] )
{
    LOGGER( 128, "I AM ENTERING ON tryToGetGameModCvar(2) cvar_to_get: %d, cvar_name: %s", cvar_to_get, cvar_name )

    if( !( cvar_to_get = get_cvar_pointer( cvar_name ) ) )
    {
        cvar_to_get = cvar_disabledValuePointer;
    }

    LOGGER( 1, "    ( tryToGetGameModCvar ) %s is cvar_to_get: %d", cvar_name, cvar_to_get )
}

stock configureTheVotingMenus()
{
    LOGGER( 128, "I AM ENTERING ON configureTheVotingMenus(0)" )

    g_chooseMapMenuId             = register_menuid( CHOOSE_MAP_MENU_NAME );
    g_chooseMapQuestionMenuId     = register_menuid( CHOOSE_MAP_MENU_QUESTION );
    g_chooseVoteMapQuestionMenuId = register_menuid( CHOOSE_VOTEMAP_MENU_QUESTION );

    register_menucmd( g_chooseMapMenuId, MENU_KEY_0 | MENU_KEY_1 |
               MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 |
               MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9,
               "vote_handleChoice" );

    register_menucmd( g_chooseMapQuestionMenuId, MENU_KEY_6 | MENU_KEY_0, "handleEndOfTheMapVoteChoice" );
    register_menucmd( g_chooseVoteMapQuestionMenuId, MENU_KEY_1 | MENU_KEY_3 | MENU_KEY_5, "handleVoteMapActionMenu" );
}

stock loadPluginSetttings()
{
    LOGGER( 128, "I AM ENTERING ON loadPluginSetttings(0)" )
    new writtenSize;

    writtenSize = get_configsdir( g_configsDirPath, charsmax( g_configsDirPath ) );
    copy( g_configsDirPath[ writtenSize ], charsmax( g_configsDirPath ) - writtenSize, "/galileo" );

    writtenSize = get_datadir( g_dataDirPath, charsmax( g_dataDirPath ) );
    copy( g_dataDirPath[ writtenSize ], charsmax( g_dataDirPath ) - writtenSize, "/galileo" );

    if( !dir_exists( g_dataDirPath )
        && mkdir( g_dataDirPath ) )
    {
        LOGGER( 1, "AMX_ERR_NOTFOUND, %L", LANG_SERVER, "GAL_CREATIONFAILED", g_dataDirPath )
        log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_CREATIONFAILED", g_dataDirPath );
    }

    LOGGER( 1, "( loadPluginSetttings ) g_configsDirPath: %s, g_dataDirPath: %s,", g_configsDirPath, g_dataDirPath )

    server_cmd( "exec %s/galileo.cfg", g_configsDirPath );
    server_exec();

    new modeFlagFilePath[ MAX_FILE_PATH_LENGHT ];
    formatex( modeFlagFilePath, charsmax( modeFlagFilePath ), "%s/%s", g_dataDirPath, TO_STOP_THE_CRASH_SEARCH );

    if( IS_TO_ALLOW_A_CRASH_SEARCH( modeFlagFilePath ) )
    {

    }
}

stock initializeGlobalArrays()
{
    LOGGER( 128, "I AM ENTERING ON initializeGlobalArrays(0)" )

    g_whitelistFileArray = ArrayCreate( MAX_LONG_STRING );

    g_nominatedMapsArray        = ArrayCreate();
    g_nominationLoadedMapsArray = ArrayCreate( MAX_MAPNAME_LENGHT );

    g_reverseSearchNominationsTrie = TrieCreate();
    g_forwardSearchNominationsTrie = TrieCreate();
    g_nominationLoadedMapsTrie     = TrieCreate();

    g_voteMinPlayerFillerPathsArray = ArrayCreate( MAX_MAPNAME_LENGHT );
    g_minPlayerFillerMapGroupArrays = ArrayCreate();
    g_minMaxMapsPerGroupToUseArray  = ArrayCreate();

    g_voteMidPlayerFillerPathsArray = ArrayCreate( MAX_MAPNAME_LENGHT );
    g_midPlayerFillerMapGroupArrays = ArrayCreate();
    g_midMaxMapsPerGroupToUseArray  = ArrayCreate();

    g_voteNorPlayerFillerPathsArray = ArrayCreate( MAX_MAPNAME_LENGHT );
    g_norPlayerFillerMapGroupArrays = ArrayCreate();
    g_norMaxMapsPerGroupToUseArray  = ArrayCreate();

    g_recentMapsTrie      = TrieCreate();
    g_recentListMapsArray = ArrayCreate( MAX_MAPNAME_LENGHT );
}

/**
 * The cvars as 'mp_fraglimit' is registered only the first time the server starts. This function
 * setup the 'mp_fraglimit' support on all Game Modifications.
 */
stock mp_fraglimitCvarSupport()
{
    LOGGER( 128, "I AM ENTERING ON mp_fraglimitCvarSupport(0)" )

    // mp_fraglimit
    new exists_mp_fraglimit_cvar = cvar_exists( "mp_fraglimit" );
    LOGGER( 32, "( mp_fraglimitCvarSupport ) exists_mp_fraglimit_cvar: %d", exists_mp_fraglimit_cvar )

    if( exists_mp_fraglimit_cvar )
    {
        register_event( "DeathMsg", "client_death_event", "a" );
        cvar_mp_fraglimit = get_cvar_pointer( "mp_fraglimit" );
    }
    else if( get_pcvar_num( cvar_fragLimitSupport ) )
    {
        register_event( "DeathMsg", "client_death_event", "a" );
        cvar_mp_fraglimit = register_cvar( "mp_fraglimit", "0", FCVAR_SERVER );
    }
    else
    {
        cvar_mp_fraglimit = cvar_disabledValuePointer;
    }

    LOGGER( 1, "( mp_fraglimitCvarSupport ) cvar_disabledValuePointer: %d", cvar_disabledValuePointer )
    LOGGER( 1, "( mp_fraglimitCvarSupport ) mp_fraglimit is cvar_to_get: %d", cvar_mp_fraglimit )
}

stock configureTheRTVFeature()
{
    LOGGER( 128, "I AM ENTERING ON configureTheRTVFeature(0)" )

    g_rtvWaitMinutes = get_pcvar_float( cvar_rtvWaitMinutes );
    g_rtvWaitRounds  = get_pcvar_num( cvar_rtvWaitRounds );
    g_rtvWaitFrags   = get_pcvar_num( cvar_rtvWaitFrags );

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

        loadNominationList();
    }

    LOGGER( 4, "" )
    LOGGER( 4, "" )
}

stock configureTheWhiteListFeature()
{
    LOGGER( 128, "I AM ENTERING ON configureTheWhiteListFeature(0)" )

    if( IS_WHITELIST_ENABLED()
        && IS_TO_HOURLY_LOAD_THE_WHITELIST() )
    {
        computeNextWhiteListLoadTime( 1, false );
        loadTheWhiteListFeature();
    }
}

/**
 * To cache some high used server cvars.
 */
public cacheCvarsValues()
{
    LOGGER( 128, "I AM ENTERING ON cacheCvarsValues(0)" )

    g_rtvCommands               = get_pcvar_num( cvar_rtvCommands            );
    g_extendmapStepRounds       = get_pcvar_num( cvar_extendmapStepRounds    );
    g_extendmapStepFrags        = get_pcvar_num( cvar_extendmapStepFrags     );
    g_extendmapStepMinutes      = get_pcvar_num( cvar_extendmapStepMinutes   );
    g_extendmapAllowStayType    = get_pcvar_num( cvar_extendmapAllowStayType );
    g_showVoteStatus            = get_pcvar_num( cvar_showVoteStatus         );
    g_voteShowNoneOptionType    = get_pcvar_num( cvar_voteShowNoneOptionType );
    g_showVoteStatusType        = get_pcvar_num( cvar_showVoteStatusType     );
    g_fragLimitNumber           = get_pcvar_num( cvar_mp_fraglimit           );
    g_timeLimitNumber           = get_pcvar_num( cvar_mp_timelimit           );

    g_isExtendmapAllowStay      = get_pcvar_num( cvar_extendmapAllowStay   ) != 0;
    g_isToShowNoneOption        = get_pcvar_num( cvar_isToShowNoneOption   ) == 1;
    g_isToShowSubMenu           = get_pcvar_num( cvar_isToShowNoneOption   ) == 2;
    g_isToShowVoteCounter       = get_pcvar_num( cvar_isToShowVoteCounter  ) != 0;
    g_isToShowExpCountdown      = get_pcvar_num( cvar_isToShowExpCountdown ) != 0;
    g_isVirtualFragLimitSupport = get_pcvar_num( cvar_fragLimitSupport     ) != 0;

    // load the weighted votes flags and chat prefix.
    get_pcvar_string( cvar_voteWeightFlags, g_voteWeightFlags, charsmax( g_voteWeightFlags ) );
    get_pcvar_string( cvar_coloredChatPrefix, g_coloredChatPrefix, charsmax( g_coloredChatPrefix ) );

    //Do not put it before the variable `g_isColoredChatEnabled` caching.
    if( IS_COLORED_CHAT_ENABLED() )
    {
        INSERT_COLOR_TAGS( g_coloredChatPrefix )
    }
    else
    {
        REMOVE_CODE_COLOR_TAGS( g_coloredChatPrefix )
    }

    g_maxVotingChoices = max( min( MAX_OPTIONS_IN_VOTE, get_pcvar_num( cvar_voteMapChoiceCount ) ), 2 );

    // It need to be cached after loading all the cvars
    g_totalVoteTime = howManySecondsLastMapTheVoting();
}

/**
 * Setup the main task that schedules the end map voting and allow round finish feature.
 */
stock configureServerMapChange()
{
    LOGGER( 128, "I AM ENTERING ON configureServerMapChange(0)" )

    if( IS_WHITELIST_BLOCKING( IS_WHITELIST_ENABLED(), g_nextMapName ) )
    {
        new currentNextMap[ MAX_MAPNAME_LENGHT ];

        log_amx( "configureServerMapChange: %s: %L", g_nextMapName, LANG_SERVER, "GAL_MATCH_WHITELIST" );
        LOGGER( 8, "    ( configureServerMapChange ) %s: %L", g_nextMapName, LANG_SERVER, "GAL_MATCH_WHITELIST" )

        copy( currentNextMap, charsmax( currentNextMap ), g_nextMapName );
        map_getNext( g_mapcycleFileListArray, currentNextMap, g_nextMapName );

        // Need to be called to trigger special behaviors.
        setNextMap( g_currentMapName, g_nextMapName );
    }

    if( get_pcvar_num( cvar_emptyServerWaitMinutes )
        || get_pcvar_num( cvar_isEmptyCycleByMapChange ) )
    {
        g_emptyCycleMapsArray = ArrayCreate( MAX_MAPNAME_LENGHT );
        map_loadEmptyCycleList();

        if( get_pcvar_num( cvar_emptyServerWaitMinutes ) )
        {
            set_task( 60.0, "inicializeEmptyCycleFeature" );
        }
    }

    set_task( float( PERIODIC_CHECKING_INTERVAL ), "vote_manageEnd", _, _, _, "b" );
}

/**
 * Notice that this whole algorithm is only ran at the first time the server start, to set properly
 * the last where the server was before to be closed or crash.
 *
 * I must also to read them on the server start, as currently is being done, because I need to
 * set up whether we need to change level now or not.
 */
stock configureServerStart()
{
    LOGGER( 128, "I AM ENTERING ON configureServerStart(0)" )
    new startAction;

    if( get_pcvar_num( cvar_gameCrashRecreationAction ) )
    {
        g_isToCreateGameCrashFlag = true;
    }

    // take the defined "server start" action
    startAction = get_pcvar_num( cvar_serverStartAction );

    // To update the current and next map names every server start. This setup must to be run only
    // at the first time the server is started.
    if( startAction )
    {
        if( get_pcvar_num( cvar_isFirstServerStart ) == FIRST_SERVER_START )
        {
            new backupMapsFilePath[ MAX_FILE_PATH_LENGHT ];
            formatex( backupMapsFilePath, charsmax( backupMapsFilePath ), "%s/%s", g_dataDirPath, CURRENT_AND_NEXTMAP_FILE_NAME );

            // If the data file does not exists yet, we cannot handle the server start.
            if( file_exists( backupMapsFilePath ) )
            {
                handleServerStart( backupMapsFilePath, startAction );
            }
            else
            {
                // These data, are already loaded by the loadNextMapPluginSetttings(0) function call.
                saveCurrentAndNextMapNames( g_currentMapName, g_nextMapName, true );
            }
        }
        else
        {
            // Save the current and next map name when the server admin does something like `amx_map`, and the
            // server did not crash on the selected map, the setTheCurrentAndNextMapSettings(0) cannot update
            // what are the correct current and next map names, because it is only called a the plugin_end(0).
            saveCurrentAndNextMapNames( g_currentMapName, g_nextMapName, true );
        }
    }
    else
    {
        // The level `FIRST_SERVER_START` is only meant to be used by the `startAction`, therefore
        // when the `startAction` is disable we must to set it to the seconds level `SECOND_SERVER_START`.
        set_pcvar_num( cvar_isFirstServerStart, SECOND_SERVER_START );

        LOGGER( 2, "( configureServerStart ) IS CHANGING THE CVAR 'gal_server_starting' to '%d'.", \
                get_pcvar_num( cvar_isFirstServerStart ) )
    }
}

/**
 * I must to set next the current and next map at plugin_end(0), because if the next map changed by
 * a normal server change level, the current and next map names will not be updated.
 *
 * It is impossible to detect to which map the server was changed when the server admin does `amx_map`
 * or any other command to change the level to a specific map.
 *
 * However we do not need to worry about such commands because if the admin does so, the map will be
 * changed to the map just before they were, when the change level command to be performed.
 */
stock setTheCurrentAndNextMapSettings()
{
    LOGGER( 128, "I AM ENTERING ON setTheCurrentAndNextMapSettings(0)" )

    // Must not to be run only at the first time the server is started, because the setup call to
    // saveCurrentAndNextMapNames(3) does not need to be performed at the server first start as we
    // are only reading the last data set, instead of setting new data to it.
    if( get_pcvar_num( cvar_serverStartAction )
        && get_pcvar_num( cvar_isFirstServerStart ) != FIRST_SERVER_START )
    {
        new nextMapName   [ MAX_MAPNAME_LENGHT ];
        new currentMapName[ MAX_MAPNAME_LENGHT ];

        // Remember, this is called at plugin_end(0), so the next map will became the the current map.
        getNextMapName( currentMapName, charsmax( currentMapName ) );

        // These data does not need to be synced/updated with `g_nextMapCyclePosition` because they
        // are only used at the first time the server is started. Moreover, at the first time the
        // server has started, these data will be used the find out the correct value for the
        // variable `g_nextMapCyclePosition` use.
        if( map_getNext( g_mapcycleFileListArray, currentMapName, nextMapName ) == -1 )
        {
            // If we cannot find a valid next map, set it as the current map. Therefore when the
            // readMapCycle(3) to start looking for a new next map, it will automatically take the
            // first map, as is does not allow the current map to be set as the next map.
            saveCurrentAndNextMapNames( currentMapName, currentMapName );
        }
        else
        {
            saveCurrentAndNextMapNames( currentMapName, nextMapName );
        }
    }

    // This is the key that tells us if this server has been started or not. Note it is important to
    // perform this switch only after the instructions call.
    switch( get_pcvar_num( cvar_isFirstServerStart ) )
    {
        case FIRST_SERVER_START:
        {
            set_pcvar_num( cvar_isFirstServerStart, SECOND_SERVER_START );
        }
        default:
        {
            set_pcvar_num( cvar_isFirstServerStart, AFTER_READ_MAPCYCLE );
        }
    }

    LOGGER( 2, "( setTheCurrentAndNextMapSettings ) IS CHANGING THE CVAR 'gal_server_starting' to '%d'.", \
            get_pcvar_num( cvar_isFirstServerStart ) )
}

/**
 * Indicates which action to take when it is detected that the server
 * has been 'externally restarted'. By 'externally restarted', is mean to
 * say the Computer's Operational System (Linux) or Server Manager (HLSW),
 * used the server command 'quit' and reopened the server.
 *
 * 0 - stay on the map the server started with
 *
 * 1 - change to the map that was being played when the server was reset
 *
 * 2 - change to what would have been the next map had the server not
 *     been restarted ( if the next map isn't known, this acts like 3 )
 *
 * 3 - start an early map vote after the first two minutes
 *
 * 4 - change to a randomly selected map from your nominatable map list
 */
public handleServerStart( backupMapsFilePath[], startAction )
{
    LOGGER( 128, "I AM ENTERING ON handleServerStart(1) backupMapsFilePath: %s", backupMapsFilePath )
    isHandledGameCrashAction( startAction );

    new mapToChange[ MAX_MAPNAME_LENGHT ];
    new nextMapName[ MAX_MAPNAME_LENGHT ];

    new mapCyclePosition;
    new mapCyclePositionString[ 10 ];

    if( startAction == SERVER_START_CURRENTMAP
        || startAction == SERVER_START_NEXTMAP )
    {
        new backupMapsFile = fopen( backupMapsFilePath, "rt" );

        if( backupMapsFile )
        {
            fgets( backupMapsFile, mapToChange, charsmax( mapToChange ) );
            fgets( backupMapsFile, nextMapName, charsmax( nextMapName )  );
            fgets( backupMapsFile, mapCyclePositionString, charsmax( mapCyclePositionString ) );

            trim( mapToChange );
            trim( nextMapName );
            trim( mapCyclePositionString );

            mapCyclePosition = str_to_num( mapCyclePositionString );

            if( startAction == SERVER_START_NEXTMAP )
            {
                copy( mapToChange, charsmax( mapToChange ), nextMapName );

                // If there is not found a next map, the current map name on `nextMapName` will to be
                // set as the first map cycle map name.
                map_getNext( g_mapcycleFileListArray, mapToChange, nextMapName );
            }

            fclose( backupMapsFile );
        }
    }
    else if( startAction == SERVER_START_RANDOMMAP ) // pick a random map from allowable nominations
    {
        // if noms aren't allowed, the nomination list hasn't already been loaded
        if( get_pcvar_num( cvar_nomPlayerAllowance ) == 0 )
        {
            loadNominationList();
        }

        new nominationsMapsCount = ArraySize( g_nominationLoadedMapsArray );

        if( nominationsMapsCount )
        {
            GET_MAP_NAME( g_nominationLoadedMapsArray, random_num( 0, nominationsMapsCount - 1 ), mapToChange )
        }
    }

    // When this is called more than `MAX_SERVER_RESTART_ACCEPTABLE` on the same mapToChange, we
    // know crash trouble is probably expecting us.
    configureTheMapcycleSystem( mapToChange, nextMapName, mapCyclePosition );

    if( mapToChange[ 0 ] )
    {
        if( IS_MAP_VALID( mapToChange ) )
        {
            // If the default started server map is the last current map, we need to set the server
            // state as already restarted.
            if( equali( mapToChange, g_currentMapName ) )
            {
                // If we got here, the level was `FIRST_SERVER_START`, and as we are not changing
                // the map, we must to set it to the next level `SECOND_SERVER_START`.
                set_pcvar_num( cvar_isFirstServerStart, SECOND_SERVER_START );
                LOGGER( 2, "( handleServerStart ) IS CHANGING THE CVAR 'gal_server_starting' to '%d'.", SECOND_SERVER_START )
            }
            else
            {
                serverChangeLevel( mapToChange );
            }
        }
        else
        {
            LOGGER( 1, "WARNING, Invalid map read from the current and next map file: ^"%s^"", mapToChange )
            log_amx(   "WARNING, Invalid map read from the current and next map file: ^"%s^"", mapToChange );
        }
    }
    else // startAction == SERVER_START_MAPVOTE
    {
        vote_manageEarlyStart();
    }
}

/**
 * To detect if the last MAX_SERVER_RESTART_ACCEPTABLE restarts was to the same map. If so, change
 * to the next map right after it.
 *
 * @param mapToChange is the first map read from `currentAndNextmapNames.dat`, i.e., the supposed last current map.
 */
stock configureTheMapcycleSystem( mapToChange[], possibleNextMap[], possibleNextMapPosition )
{
    LOGGER( 128, "I AM ENTERING ON configureTheMapcycleSystem(2) mapToChange: %s", mapToChange )
    new restartsOnTheCurrentMap = getRestartsOnTheCurrentMap( mapToChange );

    LOGGER( 4, "( configureTheMapcycleSystem ) mapToChange: %s", mapToChange )
    LOGGER( 4, "( configureTheMapcycleSystem ) possibleNextMap: %s", possibleNextMap )
    LOGGER( 4, "( configureTheMapcycleSystem ) restartsOnTheCurrentMap: %d", restartsOnTheCurrentMap )

    // Set the new current map as the actual next map.
    if( restartsOnTheCurrentMap > MAX_SERVER_RESTART_ACCEPTABLE )
    {
        new lastMapChangedFile;

        LOGGER( 4, "( configureTheMapcycleSystem ) restartsOnTheCurrentMap > MAX_SERVER_RESTART_ACCEPTABLE" )
        LOGGER( 4, "" )

        setThisMapAsPossibleCrashingMap( mapToChange );

        // This is the possibleCurrentMap because if the current map is restarted too much, this possibleCurrentMap
        // will the the mapToChange, which in seconds will became the current map.
        new possibleCurrentMap    [ MAX_MAPNAME_LENGHT ];
        new lastMapChangedFilePath[ MAX_FILE_PATH_LENGHT ];

        // Get a new next map on the map cycle.
        if( equali( mapToChange, possibleNextMap ) )
        {
            possibleNextMapPosition = 0;

            if( ArraySize( g_mapcycleFileListArray ) > 1 )
            {
                GET_MAP_NAME( g_mapcycleFileListArray, 0, possibleCurrentMap )
                GET_MAP_NAME( g_mapcycleFileListArray, 1, possibleNextMap    )

                configureTheNextMapPlugin( possibleCurrentMap, possibleNextMap, 1, true );
            }
            else
            {
                log_amx(   "WARNING: Your 'mapcyclefile' server variable is invalid!" );
                LOGGER( 1, "WARNING: Your 'mapcyclefile' server variable is invalid!" )

                copy( possibleCurrentMap, MAX_MAPNAME_LENGHT - 1, g_currentMapName );
                copy( possibleNextMap   , MAX_MAPNAME_LENGHT - 1, g_currentMapName );

                // If there is not any map, just to do setup it by default the first server's map.
                configureTheNextMapPlugin( possibleCurrentMap, possibleNextMap, 0, true );
            }
        }
        else
        {
            copy( possibleCurrentMap, charsmax( possibleCurrentMap ), possibleNextMap );
            possibleNextMapPosition = map_getNext( g_mapcycleFileListArray, possibleCurrentMap, possibleNextMap );

            // Update the current map to the next map.
            copy( mapToChange, MAX_MAPNAME_LENGHT - 1, possibleCurrentMap );
            configureTheNextMapPlugin( possibleCurrentMap, possibleNextMap, possibleNextMapPosition, true );
        }

        // Clear the old data
        LOGGER( 4, "" )
        formatex( lastMapChangedFilePath, charsmax( lastMapChangedFilePath ), "%s/%s", g_dataDirPath, LAST_CHANGE_MAP_FILE_NAME );

        if( ( lastMapChangedFile = fopen( lastMapChangedFilePath, "wt" ) ) )
        {
            fprintf( lastMapChangedFile, "nothing_to_be_added_by^n0^n" );
            fclose( lastMapChangedFile );
        }
        else
        {
            LOGGER( 1, "ERROR, configureTheMapcycleSystem: Couldn't open the file to write (file ^"%s^")", lastMapChangedFilePath )
            log_amx(   "ERROR, configureTheMapcycleSystem: Couldn't open the file to write (file ^"%s^")", lastMapChangedFilePath );
        }

        log_message( "" );
        log_message( "The server is jumping to the next map after the current map due more than %d restarts on the map %s.",
                MAX_SERVER_RESTART_ACCEPTABLE, mapToChange );

        log_message( "" );
    }
    else
    {
        configureTheNextMapPlugin( mapToChange, possibleNextMap, possibleNextMapPosition );
        LOGGER( 4, "( configureTheMapcycleSystem ) restartsOnTheCurrentMap < MAX_SERVER_RESTART_ACCEPTABLE" )
        LOGGER( 4, "" )
    }
}

stock setThisMapAsPossibleCrashingMap( mapName[] )
{
    LOGGER( 128, "I AM ENTERING ON setThisMapAsPossibleCrashingMap(1) mapName: %s", mapName )

    new serverCrashedMapsFile;
    new serverCrashedMapsFilePath[ MAX_FILE_PATH_LENGHT ];

    formatex( serverCrashedMapsFilePath, charsmax( serverCrashedMapsFilePath ), "%s/%s", g_dataDirPath, MAPS_WHERE_THE_SERVER_CRASHED );

    if( !( serverCrashedMapsFile = fopen( serverCrashedMapsFilePath, "a+" ) ) )
    {
        LOGGER( 1, "ERROR, setThisMapAsPossibleCrashingMap: Couldn't open the file (file ^"%s^")", serverCrashedMapsFilePath )
        log_amx(   "ERROR, setThisMapAsPossibleCrashingMap: Couldn't open the file (file ^"%s^")", serverCrashedMapsFilePath );
    }
    else
    {
        fprintf( serverCrashedMapsFile, "%s^n", mapName );
        fclose( serverCrashedMapsFile );
    }
}

/**
 * When we are setting the `possibleNextMapPosition` to 0, we are restarting the map cycle from its
 * first position. This happens every time we complete a map cycle full loop.
 *
 * However, this function is only called at the first time the server started, so not setting anything
 * implies on already starting the map cycle from its first position.
 */
stock configureTheNextMapPlugin( possibleCurrentMap[], possibleNextMap[], possibleNextMapPosition, bool:forceUpdateFile = false )
{
    LOGGER( 128, "I AM ENTERING ON configureTheNextMapPlugin(4)" )

    LOGGER( 4, "( configureTheNextMapPlugin ) forceUpdateFile: %d", forceUpdateFile )
    LOGGER( 4, "( configureTheNextMapPlugin ) possibleNextMap: %s",  possibleNextMap )
    LOGGER( 4, "( configureTheNextMapPlugin ) possibleCurrentMap: %s",  possibleCurrentMap )
    LOGGER( 4, "( configureTheNextMapPlugin ) possibleNextMapPosition: %d", possibleNextMapPosition )

    if( ( g_nextMapCyclePosition = possibleNextMapPosition ) )
    {
        new mapcycleFilePath[ MAX_FILE_PATH_LENGHT ];
        get_pcvar_string( cvar_mapcyclefile, mapcycleFilePath, charsmax( mapcycleFilePath ) );

        setNextMap( possibleCurrentMap, possibleNextMap, true, forceUpdateFile );
        saveCurrentMapCycleSetting( mapcycleFilePath );
    }
}

stock getRestartsOnTheCurrentMap( mapToChange[] )
{
    LOGGER( 128, "I AM ENTERING ON getRestartsOnTheCurrentMap(1) mapToChange: %s", mapToChange )

    new lastMapChangedFile;
    new lastMapChangedCount;

    new lastMapChangedName       [ MAX_MAPNAME_LENGHT ];
    new lastMapChangedFilePath   [ MAX_FILE_PATH_LENGHT ];
    new lastMapChangedCountString[ 10 ];

    formatex( lastMapChangedFilePath, charsmax( lastMapChangedFilePath ), "%s/%s", g_dataDirPath, LAST_CHANGE_MAP_FILE_NAME );

    LOGGER( 4, "( getRestartsOnTheCurrentMap ) mapToChange: %s,", mapToChange )
    LOGGER( 4, "( getRestartsOnTheCurrentMap ) lastMapChangedFilePath: %s", lastMapChangedFilePath )

    if( ( lastMapChangedFile = fopen( lastMapChangedFilePath, "rt" ) ) )
    {
        fgets( lastMapChangedFile, lastMapChangedName       , charsmax( lastMapChangedName        ) );
        fgets( lastMapChangedFile, lastMapChangedCountString, charsmax( lastMapChangedCountString ) );

        fclose( lastMapChangedFile );

        trim( mapToChange );
        trim( lastMapChangedName );
        trim( lastMapChangedCountString );

        lastMapChangedCount = str_to_num( lastMapChangedCountString );

        // If it got here, it could be opened for reading, but could not be opened for writing as in ready on files.
        if( ( lastMapChangedFile = fopen( lastMapChangedFilePath, "wt" ) ) )
        {
            fprintf( lastMapChangedFile, "%s^n", mapToChange );

            if( equali( mapToChange, lastMapChangedName ) )
            {
                ++lastMapChangedCount;
                LOGGER( 4, "( getRestartsOnTheCurrentMap ) mapToChange is equal to lastMapChangedName." )
            }
            else
            {
                lastMapChangedCount = 0;
                LOGGER( 4, "( getRestartsOnTheCurrentMap ) mapToChange is not equal to lastMapChangedName." )
            }

            fprintf( lastMapChangedFile, "%d^n", lastMapChangedCount );
            fclose( lastMapChangedFile );
        }
        else
        {
            LOGGER( 1, "ERROR, getRestartsOnTheCurrentMap: Couldn't open the file to write (file ^"%s^")", lastMapChangedFilePath )
            log_amx(   "ERROR, getRestartsOnTheCurrentMap: Couldn't open the file to write (file ^"%s^")", lastMapChangedFilePath );
        }

        LOGGER( 4, "( getRestartsOnTheCurrentMap ) lastMapChangedName: %s", lastMapChangedName )
        LOGGER( 4, "( getRestartsOnTheCurrentMap ) lastMapChangedCount: %d", lastMapChangedCount )
        LOGGER( 4, "( getRestartsOnTheCurrentMap ) lastMapChangedCountString: %s", lastMapChangedCountString )
    }
    else
    {
        LOGGER( 1, "ERROR, getRestartsOnTheCurrentMap: Couldn't open the file to read (file ^"%s^")", lastMapChangedFilePath )
        log_amx(   "ERROR, getRestartsOnTheCurrentMap: Couldn't open the file to read (file ^"%s^")", lastMapChangedFilePath );

        if( ( lastMapChangedFile = fopen( lastMapChangedFilePath, "wt" ) ) )
        {
            fprintf( lastMapChangedFile, "nothing_to_be_added_by^n0^n" );
            fclose( lastMapChangedFile );
        }
        else
        {
            LOGGER( 1, "ERROR, getRestartsOnTheCurrentMap: Couldn't open the file to write (file ^"%s^")", lastMapChangedFilePath )
            log_amx(   "ERROR, getRestartsOnTheCurrentMap: Couldn't open the file to write (file ^"%s^")", lastMapChangedFilePath );
        }

    }

    LOGGER( 1, "    ( getRestartsOnTheCurrentMap ) Returning lastMapChangedCount: %d", lastMapChangedCount )
    return lastMapChangedCount;
}

/**
 * Internally set the next map on `g_nextMapName` and save to the file `currentAndNextmapNames.dat`,
 * the current map name and the here provided nextMapName.
 */
stock setNextMap( currentMapName[], nextMapName[], bool:isToUpdateTheCvar = true, bool:forceUpdateFile = false )
{
    LOGGER( 128, "I AM ENTERING ON setNextMap(4) nextMapName: %s", nextMapName )

    // While the `IS_DISABLED_VOTEMAP_EXIT` bit flag is set, we cannot allow any decisions.
    if( g_voteMapStatus & IS_DISABLED_VOTEMAP_EXIT )
    {
        // We do not need to open the menu here, because on the vote end context, a setNextMap(4) function
        // call is always proceed by a process_last_round(2) function call, which will open the final choice
        // vote menu.
        copy( g_invokerVoteMapNameToDecide, charsmax( g_invokerVoteMapNameToDecide ), nextMapName );

        LOGGER( 1, "    ( setNextMap ) Just returning/blocking, g_voteMapStatus: %d", g_voteMapStatus )
        return;
    }

    if( IS_MAP_VALID( nextMapName ) )
    {
        // set the queryable cvar
        if( isToUpdateTheCvar
            || !( get_pcvar_num( cvar_nextMapChangeAnnounce )
                  && get_pcvar_num( cvar_endOfMapVote ) ) )
        {
            LOGGER( 2, "( setNextMap ) IS CHANGING THE CVAR 'amx_nextmap' to '%s'.", nextMapName )
            set_pcvar_string( cvar_amx_nextmap, nextMapName );

        #if IS_TO_ENABLE_SVEN_COOP_SUPPPORT > 0
            tryToSetGameModCvarString( cvar_mp_nextmap_cycle, nextMapName );
        #endif
        }

        // Allow to send the variable `g_nextMapName` to the function setNextMap(4).
        if( !equali( g_nextMapName, nextMapName ) )
        {
            copy( g_nextMapName, charsmax( g_nextMapName ), nextMapName );
        }

        // update our data file
        saveCurrentAndNextMapNames( currentMapName, nextMapName, forceUpdateFile );
        LOGGER( 2, "( setNextMap ) IS CHANGING THE global variable g_nextMapName to '%s'.", nextMapName )
    }
    else
    {
        LOGGER( 1, "AMX_ERR_PARAMS, %s, was tried to set a invalid next-map!", nextMapName )
        log_error( AMX_ERR_PARAMS, "%s, was tried to set a invalid next-map!", nextMapName );
    }
}

/**
 * The parameter `forceUpdateFile` is used only when we need to set the `CURRENT_AND_NEXTMAP_FILE_NAME`
 * at the first time we started the server. As by the book, we only read the `CURRENT_AND_NEXTMAP_FILE_NAME`
 * data at the server start.
 *
 * The next map written to the file `currentAndNextmapNames.dat` is currently used for the option
 * `startAction == SERVER_START_NEXTMAP` and debugging purposes.
 */
stock saveCurrentAndNextMapNames( currentMapName[], nextMapName[], bool:forceUpdateFile = false )
{
    LOGGER( 128, "I AM ENTERING ON saveCurrentAndNextMapNames(3) currentMapName: %s, nextMapName: %s", currentMapName, nextMapName )

    // We do not need to check whether the `cvar_serverStartAction` is enabled or not, because the
    // execution flow only gets here when it is enabled.
    if( get_pcvar_num( cvar_isFirstServerStart ) != FIRST_SERVER_START
        || forceUpdateFile )
    {
        new backupMapsFile;
        new backupMapsFilePath[ MAX_FILE_PATH_LENGHT ];

        formatex( backupMapsFilePath, charsmax( backupMapsFilePath ), "%s/%s", g_dataDirPath, CURRENT_AND_NEXTMAP_FILE_NAME );
        backupMapsFile = fopen( backupMapsFilePath, "wt" );

        if( backupMapsFile )
        {
            trim( nextMapName );
            trim( currentMapName );

            fprintf( backupMapsFile, "%s^n", currentMapName );
            fprintf( backupMapsFile, "%s^n", nextMapName );
            fprintf( backupMapsFile, "%d^n", g_nextMapCyclePosition );

            fclose( backupMapsFile );
        }
    }
}

/**
 *
 * @return true when the crashing was properly handled, false otherwise.
 */
public isHandledGameCrashAction( &startAction )
{
    LOGGER( 128, "I AM ENTERING ON isHandledGameCrashAction(1) startAction: %d", startAction )

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
                // disable any other server start action
                startAction = 0;

                // force to use only the '1/SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR' time, i.e.,
                // stop creating an infinity loop of half of half...
                g_isToCreateGameCrashFlag = false;

                // Wait until the mp_timelimit, etc cvars, to be loaded from the configuration file.
                set_task( DELAY_TO_WAIT_THE_SERVER_CVARS_TO_BE_LOADED + 10.0, "setGameToFinishAtHalfTime", TASKID_FINISH_GAME_TIME_BY_HALF );
            }
        }
    }
}

stock generateGameCrashActionFilePath( gameCrashActionFilePath[], charsmaxGameCrashActionFilePath )
{
    LOGGER( 128, "I AM ENTERING ON gameCrashActionFilePath(2) charsmaxGameCrashActionFilePath: %d", charsmaxGameCrashActionFilePath )

    formatex( gameCrashActionFilePath, charsmaxGameCrashActionFilePath, "%s/%s", g_dataDirPath, GAME_CRASH_RECREATION_FLAG_FILE );
    LOGGER( 1, "( generateGameCrashActionFilePath ) gameCrashActionFilePath: %s", gameCrashActionFilePath )
}

/**
 * Save the mp_maxrounds, etc and set them to half of it.
 */
public setGameToFinishAtHalfTime()
{
    LOGGER( 128, "I AM ENTERING ON setGameToFinishAtHalfTime(0)" )
    saveEndGameLimits();

    tryToSetGameModCvarFloat( cvar_mp_timelimit, g_originalTimelimit / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );
    tryToSetGameModCvarNum(   cvar_mp_maxrounds, g_originalMaxRounds / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );
    tryToSetGameModCvarNum(   cvar_mp_winlimit,  g_originalWinLimit  / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );
    tryToSetGameModCvarNum(   cvar_mp_fraglimit, g_originalFragLimit / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );

    LOGGER( 2, "( setGameToFinishAtHalfTime ) IS CHANGING THE CVAR 'mp_timelimit' to '%f'.", get_pcvar_float( cvar_mp_timelimit ) )
    LOGGER( 2, "( setGameToFinishAtHalfTime ) IS CHANGING THE CVAR 'mp_fraglimit' to '%d'.", get_pcvar_num( cvar_mp_fraglimit ) )
    LOGGER( 2, "( setGameToFinishAtHalfTime ) IS CHANGING THE CVAR 'mp_maxrounds' to '%d'.", get_pcvar_num( cvar_mp_maxrounds ) )
    LOGGER( 2, "( setGameToFinishAtHalfTime ) IS CHANGING THE CVAR 'mp_winlimit' to '%d'.", get_pcvar_num( cvar_mp_winlimit ) )
}

/**
 * Load the recent ban map from the file. If the number of valid maps loaded is lower than the
 * number of map loaded to fill the vote menu, not all the maps will be loaded.
 *
 * This also restrict the number of maps to be write to the file `RECENT_BAN_MAPS_FILE_NAME` as if
 * not all maps have been loaded here, on them will be written down to the file on
 * writeRecentMapsBanList(0).
 */
public map_loadRecentBanList( loadedMapsCount )
{
    LOGGER( 128, "I AM ENTERING ON map_loadRecentBanList(1) loadedMapsCount: %d", loadedMapsCount )
    new recentMapsFilePath[ MAX_FILE_PATH_LENGHT ];

    formatex( recentMapsFilePath, charsmax( recentMapsFilePath ), "%s/%s", g_dataDirPath, RECENT_BAN_MAPS_FILE_NAME );
    new recentMapsFileDescriptor = fopen( recentMapsFilePath, "rt" );

    if( recentMapsFileDescriptor )
    {
        new recentMapName[ MAX_MAPNAME_LENGHT ];

        new maxRecentMapsBans = get_pcvar_num( cvar_recentMapsBannedNumber );
        new maxVotingChoices  = g_maxVotingChoices + 3;

        if( maxRecentMapsBans + maxVotingChoices > loadedMapsCount )
        {
            maxRecentMapsBans = maxRecentMapsBans - maxVotingChoices;
        }

        LOGGER( 4, "( map_loadRecentBanList ) maxVotingChoices: %d", maxVotingChoices )
        LOGGER( 4, "( map_loadRecentBanList ) maxRecentMapsBans: %d", maxRecentMapsBans )

        while( !feof( recentMapsFileDescriptor ) )
        {
            fgets( recentMapsFileDescriptor, recentMapName, charsmax( recentMapName ) );
            trim( recentMapName );

            if( recentMapName[ 0 ]
                && IS_MAP_VALID( recentMapName ) )
            {
                if( g_recentMapCount >= maxRecentMapsBans )
                {
                    break;
                }

                if( !TrieKeyExists( g_recentMapsTrie, recentMapName ) )
                {
                    ArrayPushString( g_recentListMapsArray, recentMapName );
                    TrieSetCell( g_recentMapsTrie, recentMapName, 0 );

                    g_recentMapCount++;
                }
            }
        }

        fclose( recentMapsFileDescriptor );
    }
}

stock writeRecentMapsBanList()
{
    LOGGER( 128, "I AM ENTERING ON writeRecentMapsBanList()")

    new recentMapName     [ MAX_MAPNAME_LENGHT ];
    new recentMapsFilePath[ MAX_FILE_PATH_LENGHT ];

    formatex( recentMapsFilePath, charsmax( recentMapsFilePath ), "%s/%s", g_dataDirPath, RECENT_BAN_MAPS_FILE_NAME );
    new recentMapsFileDescriptor = fopen( recentMapsFilePath, "wt" );

    if( recentMapsFileDescriptor )
    {
        new bool:isOnlyRecentMapcycleMaps = get_pcvar_num( cvar_isOnlyRecentMapcycleMaps ) != 0;
        LOGGER( 4, "( writeRecentMapsBanList ) isOnlyRecentMapcycleMaps: %s", isOnlyRecentMapcycleMaps )

        // Do not ban repeated maps
        if( !TrieKeyExists( g_recentMapsTrie, g_currentMapName ) )
        {
            // Add the current map to the ban list
            if( isOnlyRecentMapcycleMaps )
            {
                // Only ban if the map is on the current map cycle. Not writing it to the file, means not banning.
                if( TrieKeyExists( g_mapcycleFileListTrie, g_currentMapName ) )
                {
                    fprintf( recentMapsFileDescriptor, "%s^n", g_currentMapName );
                }
            }
            else
            {
                fprintf( recentMapsFileDescriptor, "%s^n", g_currentMapName );
            }
        }

        // Add the others banned maps to the ban list
        for( new mapIndex = 0; mapIndex < g_recentMapCount; ++mapIndex )
        {
            ArrayGetString( g_recentListMapsArray, mapIndex, recentMapName, charsmax( recentMapName ) );

            if( isOnlyRecentMapcycleMaps )
            {
                if( TrieKeyExists( g_mapcycleFileListTrie, recentMapName ) )
                {
                    fprintf( recentMapsFileDescriptor, "%s^n", recentMapName );
                }
            }
            else
            {
                fprintf( recentMapsFileDescriptor, "%s^n", recentMapName );
            }
        }

        fclose( recentMapsFileDescriptor );
        LOGGER( 0, "", printRecentBanFile( recentMapsFilePath ) )
    }
    else
    {
        LOGGER( 1, "WARNING, writeRecentMapsBanList: Couldn't find a valid map or the file doesn't exist (file ^"%s^")", recentMapsFilePath )
        log_amx(   "WARNING, writeRecentMapsBanList: Couldn't find a valid map or the file doesn't exist (file ^"%s^")", recentMapsFilePath );
    }
}

stock printRecentBanFile( recentMapsFilePath[] )
{
    LOGGER( 128, "I AM ENTERING ON printRecentBanFile(1) recentMapsFilePath: %s", recentMapsFilePath )

    new loadedMapName[ MAX_MAPNAME_LENGHT ];
    new mapFileDescriptor = fopen( recentMapsFilePath, "rt" );

    while( !feof( mapFileDescriptor ) )
    {
        fgets( mapFileDescriptor, loadedMapName, charsmax( loadedMapName ) );
        trim( loadedMapName );

    #if defined DEBUG
        static mapCount;

        if( mapCount++ < MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST
            && !( g_debug_level & 256 ) )
        {
            LOGGER( 4, "( printRecentBanFile ) %d, loadedMapName: %s", mapCount, loadedMapName )
        }

        LOGGER( 256, "( printRecentBanFile ) %d, loadedMapName: %s", mapCount, loadedMapName )
    #endif
    }

    fclose( mapFileDescriptor );
    return 0;
}

stock loadWhiteListFileFromFile( &Array:whitelistArray, whiteListFilePath[] )
{
    LOGGER( 128, "I AM ENTERING ON loadWhiteListFileFromFile(2) whitelistArray: %d", whitelistArray)
    LOGGER( 8, "( loadWhiteListFileFromFile ) whiteListFilePath: %s", whiteListFilePath )

    new whiteListFileDescriptor;
    new currentLine[ MAX_LONG_STRING ];

    if( !( whiteListFileDescriptor = fopen( whiteListFilePath, "rt" ) ) )
    {
        LOGGER( 8, "ERROR! Invalid file descriptor. whiteListFileDescriptor: %d, whiteListFilePath: %s", \
                whiteListFileDescriptor, whiteListFilePath )
    }

    while( !feof( whiteListFileDescriptor ) )
    {
        fgets( whiteListFileDescriptor, currentLine, charsmax( currentLine ) );
        trim( currentLine );

        // skip commentaries while reading file
        if( currentLine[ 0 ] == '^0'
            || currentLine[ 0 ] == ';'
            || ( currentLine[ 0 ] == '/'
                 && currentLine[ 1 ] == '/' ) )
        {
            continue;
        }
        else
        {
            LOGGER( 8, "( loadWhiteListFileFromFile ) Adding the currentLine: %s", currentLine )
            ArrayPushString( whitelistArray, currentLine );
        }
    }

    fclose( whiteListFileDescriptor );
    LOGGER( 1, "I AM EXITING loadWhiteListFileFromFile(2) whitelistArray: %d", whitelistArray )
}

stock processLoadedGroupMapFileFrom( &Array:playerFillerMapsArray, &Array:fillersFilePathsArray )
{
    LOGGER( 128, "I AM ENTERING ON processLoadedGroupMapFileFrom(2) groupCount: %d", ArraySize( fillersFilePathsArray ) )

    new loadedMapsTotal;
    new fillerFilePath[ MAX_FILE_PATH_LENGHT ];

    new Array:fillerMapsArray;
    new groupCount = ArraySize( fillersFilePathsArray );

    // fill remaining slots with random maps from each filler file, as much as possible
    for( new groupIndex = 0; groupIndex < groupCount; ++groupIndex )
    {
        fillerMapsArray = ArrayCreate( MAX_MAPNAME_LENGHT );
        ArrayGetString( fillersFilePathsArray, groupIndex, fillerFilePath, charsmax( fillerFilePath ) );

        loadedMapsTotal += map_populateList( fillerMapsArray, fillerFilePath, charsmax( fillerFilePath ) );
        ArrayPushCell( playerFillerMapsArray, fillerMapsArray );

        LOGGER( 8, "[%i] groupCount: %i, filersMapCount: %i", groupIndex, groupCount, ArraySize( fillerMapsArray ) )
        LOGGER( 8, "     fillersFilePaths[%i]: %s", groupIndex, fillerFilePath )
    }

    return loadedMapsTotal;
}

stock loadMapFiles()
{
    LOGGER( 128, "I AM ENTERING ON loadMapFiles(0)" )

    // To clear them, in case we are reloading it.
    TRY_TO_APPLY( ArrayClear, g_whitelistFileArray )

    TRY_TO_APPLY( ArrayClear, g_voteMidPlayerFillerPathsArray )
    TRY_TO_APPLY( ArrayClear, g_midMaxMapsPerGroupToUseArray )

    TRY_TO_APPLY( ArrayClear, g_voteMinPlayerFillerPathsArray )
    TRY_TO_APPLY( ArrayClear, g_minMaxMapsPerGroupToUseArray )

    TRY_TO_APPLY( ArrayClear, g_voteNorPlayerFillerPathsArray )
    TRY_TO_APPLY( ArrayClear, g_norMaxMapsPerGroupToUseArray )

    destroy_two_dimensional_array( g_norPlayerFillerMapGroupArrays, false );
    destroy_two_dimensional_array( g_minPlayerFillerMapGroupArrays, false );
    destroy_two_dimensional_array( g_midPlayerFillerMapGroupArrays, false );

    // To start loading the files.
    new loadedCount[ 3 ];
    new mapFilerFilePath[ MAX_FILE_PATH_LENGHT ];

    LOGGER( 4, "" )
    get_pcvar_string( cvar_voteWhiteListMapFilePath, mapFilerFilePath, charsmax( mapFilerFilePath ) );
    loadWhiteListFileFromFile( g_whitelistFileArray, mapFilerFilePath );

    LOGGER( 4, "" )
    get_pcvar_string( cvar_voteMinPlayersMapFilePath, mapFilerFilePath, charsmax( mapFilerFilePath ) );
    loadMapGroupsFeatureFile( mapFilerFilePath, g_voteMinPlayerFillerPathsArray, g_minMaxMapsPerGroupToUseArray );

    LOGGER( 4, "" )
    get_pcvar_string( cvar_voteMidPlayersMapFilePath, mapFilerFilePath, charsmax( mapFilerFilePath ) );
    loadMapGroupsFeatureFile( mapFilerFilePath, g_voteMidPlayerFillerPathsArray, g_midMaxMapsPerGroupToUseArray );

    LOGGER( 4, "" )
    get_pcvar_string( cvar_voteMapFilePath, mapFilerFilePath, charsmax( mapFilerFilePath ) );
    loadMapGroupsFeatureFile( mapFilerFilePath, g_voteNorPlayerFillerPathsArray, g_norMaxMapsPerGroupToUseArray );

    // To process the loaded files to let them ready for immediate use.
    LOGGER( 4, "" )
    loadedCount[ 0 ] = processLoadedGroupMapFileFrom( g_minPlayerFillerMapGroupArrays, g_voteMinPlayerFillerPathsArray );
    loadedCount[ 1 ] = processLoadedGroupMapFileFrom( g_midPlayerFillerMapGroupArrays, g_voteMidPlayerFillerPathsArray );
    loadedCount[ 2 ] = processLoadedGroupMapFileFrom( g_norPlayerFillerMapGroupArrays, g_voteNorPlayerFillerPathsArray );

    LOGGER( 4, "" )
    LOGGER( 4, "", debugLoadedGroupMapFileFrom( g_minPlayerFillerMapGroupArrays, g_minMaxMapsPerGroupToUseArray ) )
    LOGGER( 4, "", debugLoadedGroupMapFileFrom( g_midPlayerFillerMapGroupArrays, g_midMaxMapsPerGroupToUseArray ) )
    LOGGER( 4, "", debugLoadedGroupMapFileFrom( g_norPlayerFillerMapGroupArrays, g_norMaxMapsPerGroupToUseArray ) )

    // Load the ban recent maps feature
    if( get_pcvar_num( cvar_recentMapsBannedNumber ) )
    {
        // If we are only banning the maps on the map cycle, we should consider its size instead of
        // the voting filler's size.
        if( get_pcvar_num( cvar_isOnlyRecentMapcycleMaps ) )
        {
            map_loadRecentBanList( ArraySize( g_mapcycleFileListArray ) );
        }
        else
        {
            map_loadRecentBanList( loadedCount[ 2 ] );
        }

        register_clcmd( "say recentmaps", "cmd_listrecent", 0 );

        // Do nothing if the map will be instantly changed
        if( !( get_pcvar_num( cvar_isFirstServerStart ) == FIRST_SERVER_START
               && get_pcvar_num( cvar_serverStartAction ) ) )
        {
            writeRecentMapsBanList();
        }
    }

    LOGGER( 4, "( loadMapFiles ) Maps Files Loaded." )
    LOGGER( 4, "" )
    LOGGER( 4, "" )
}

stock debugLoadedGroupMapFileFrom( &Array:playerFillerMapsArray, &Array:maxMapsPerGroupToUseArray )
{
    LOGGER( 128, "I AM ENTERING ON debugLoadedGroupMapFileFrom(3) groupCount: %d", ArraySize( playerFillerMapsArray ) )

    new arraySize;
    new Array:fillerMapsArray;
    new fillerMap[ MAX_MAPNAME_LENGHT ];

    new groupCount = ArraySize( playerFillerMapsArray );

    // fill remaining slots with random maps from each filler file, as much as possible
    for( new groupIndex = 0; groupIndex < groupCount; ++groupIndex )
    {
        fillerMapsArray = ArrayGetCell( playerFillerMapsArray, groupIndex );
        arraySize = ArraySize( fillerMapsArray );

        LOGGER( 8, "[%i] maxMapsPerGroupToUse: %i, filersMapCount: %i", groupIndex, \
                ArrayGetCell( maxMapsPerGroupToUseArray, groupIndex ), arraySize )

        for( new mapIndex = 0; mapIndex < arraySize && mapIndex < 10; mapIndex++ )
        {
            GET_MAP_NAME( fillerMapsArray, mapIndex, fillerMap )
            LOGGER( 8, "   fillerMap[%i]: %s", mapIndex, fillerMap )
        }
    }

    return 0;
}

stock loadMapGroupsFeatureFile( mapFilerFilePath[], &Array:mapFilersPathArray, &Array:maxMapsPerGroupToUse )
{
    LOGGER( 128, "I AM ENTERING ON loadMapGroupsFeatureFile(0), mapFilerFilePath: %s", mapFilerFilePath )

    // The mapFilerFilePaths '*' and '#' disables The Map Groups Feature.
    if( !equal( mapFilerFilePath[ 0 ], MAP_FOLDER_LOAD_FLAG )
        && !equal( mapFilerFilePath[ 0 ], MAP_CYCLE_LOAD_FLAG ) )
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
                new groupCount;
                new fillerFilePath[ MAX_MAPNAME_LENGHT ];

                LOGGER( 8, "" )
                LOGGER( 8, "this is a [groups] mapFilerFile" )

                // read the filler mapFilerFile to determine how many groups there are ( max of MAX_OPTIONS_IN_VOTE )
                while( !feof( mapFilerFile ) )
                {
                    fgets( mapFilerFile, currentReadedLine, charsmax( currentReadedLine ) );
                    trim( currentReadedLine );

                    LOGGER( 8, "currentReadedLine: %s   isdigit: %i   groupCount: %i  ", \
                            currentReadedLine, isdigit( currentReadedLine[ 0 ] ), groupCount )

                    if( isdigit( currentReadedLine[ 0 ] ) )
                    {
                        if( groupCount < MAX_OPTIONS_IN_VOTE )
                        {
                            groupCount++;

                            ArrayPushCell( maxMapsPerGroupToUse, str_to_num( currentReadedLine ) );
                            formatex( fillerFilePath, charsmax( fillerFilePath ), "%s/%i.ini", g_configsDirPath, groupCount );

                            ArrayPushString( mapFilersPathArray, fillerFilePath );
                            LOGGER( 8, "fillersFilePaths: %s", fillerFilePath )
                        }
                        else
                        {
                            LOGGER( 1, "AMX_ERR_BOUNDS, %L %L", LANG_SERVER, "GAL_GRP_FAIL_TOOMANY", \
                                    mapFilerFilePath, LANG_SERVER, "GAL_GRP_FAIL_TOOMANY_2" )

                            log_error( AMX_ERR_BOUNDS, "%L %L", LANG_SERVER, "GAL_GRP_FAIL_TOOMANY",
                                    mapFilerFilePath, LANG_SERVER, "GAL_GRP_FAIL_TOOMANY_2" );

                            break;
                        }
                    }
                }

                if( groupCount == 0 )
                {
                    LOGGER( 1, "AMX_ERR_GENERAL, %L", LANG_SERVER, "GAL_GRP_FAIL_NOCOUNTS", mapFilerFilePath )
                    log_error( AMX_ERR_GENERAL, "%L", LANG_SERVER, "GAL_GRP_FAIL_NOCOUNTS", mapFilerFilePath );

                    fclose( mapFilerFile );
                    goto loadTheDefaultMapFile;
                }
            }
            // we presume it's a listing of maps, ala mapcycle.txt
            else
            {
                fclose( mapFilerFile );
                goto loadTheDefaultMapFile;
            }
        }
        else
        {
            LOGGER( 1, "AMX_ERR_NOTFOUND, %L", LANG_SERVER, "GAL_FILLER_NOTFOUND", mapFilerFilePath )
            log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_FILLER_NOTFOUND", mapFilerFilePath );

            fclose( mapFilerFile );
            goto loadTheDefaultMapFile;
        }

        fclose( mapFilerFile );
    }
    // we'll be loading all maps in the /maps folder or the current mapcycle file
    else
    {
        loadTheDefaultMapFile:

        // the options `*` and `#` will be handled by map_populateList(4) later.
        ArrayPushString( mapFilersPathArray, mapFilerFilePath );
        ArrayPushCell( maxMapsPerGroupToUse, MAX_OPTIONS_IN_VOTE );
    }

    LOGGER( 4, "( loadMapGroupsFeatureFile ) MapsGroups Loaded, mapFilerFilePath: %s", mapFilerFilePath )
    LOGGER( 4, "" )
    LOGGER( 4, "" )
}

public client_death_event()
{
    LOGGER( 256, "I AM ENTERING ON client_death_event(0)" )

    if( g_fragLimitNumber )
    {
        new killerId = read_data( 1 );

        if( killerId < MAX_PLAYERS_COUNT
            && killerId > 0 )
        {
            new frags;

            if( ( ( frags = ++g_playersKills[ killerId ] ) + VOTE_START_FRAGS() ) > g_fragLimitNumber
                && isTimeToStartTheEndOfMapVoting() )
            {
                start_voting_by_frags();
            }

            if( frags > g_greatestKillerFrags )
            {
                g_greatestKillerFrags = frags;

                // This is already protected by a `!IS_END_OF_MAP_VOTING_GOING_ON()`. This `? 2 : 1`
                // condition allow Galileo to manage the round end, if it is enabled. Otherwise let
                // the actual game mod to do it. If the support is not virtual but the `mp_fraglimitCvarSupport`,
                // the try_to_manage_map_end(1) to perform it.
                if( g_isVirtualFragLimitSupport
                    && g_greatestKillerFrags > g_fragLimitNumber - ( get_pcvar_num( cvar_endOnRound ) ? 2 : 1 ) )
                {
                    try_to_manage_map_end( true );
                }
            }
        }
    }
}

/**
 * Switches between the `cvar_endOnRound` and `cvar_endOfMapVoteStart` options cases.
 *
 * case 1:
 * `cvar_endOnRound`: When time runs out, end at the current round end.
 * `cvar_endOfMapVoteStart`: To start the voting on the last round to be played.
 *
 * case 2:
 * `cvar_endOnRound`: When time runs out, end at the next round end.
 * `cvar_endOfMapVoteStart`: To start the voting on the round before the last.
 *
 * case 3:
 * `cvar_endOnRound`: Do not applies.
 * `cvar_endOfMapVoteStart`: To start the voting on the round before the last of the last.
 *
 * @param roundsRemaining         how many rounds are remaining to the map end.
 */
stock chooseTheEndOfMapStartOption( roundsRemaining )
{
    LOGGER( 128, "I AM ENTERING ON chooseTheEndOfMapStartOption(1) roundsRemaining: %d", roundsRemaining )
    new endOfMapVoteStart = get_pcvar_num( cvar_endOfMapVoteStart );

    switch( get_pcvar_num( cvar_endOnRound ) )
    {
        case END_AT_RIGHT_NOW:
        {
            // Sum +1 to start it earlier as the cannot block the map changing.
            if( endOfMapVoteStart
                && roundsRemaining < endOfMapVoteStart + 1 )
            {
                LOGGER( 1, "    ( chooseTheEndOfMapStartOption ) 1. Returning true." )
                return true;
            }
        }
        case END_AT_THE_CURRENT_ROUND_END:
        {
            if( ( g_isGameEndingTypeContextSaved ? g_isTheLastGameRoundContext : g_isTheLastGameRound )
                || ( endOfMapVoteStart
                   && roundsRemaining < endOfMapVoteStart ) )
            {
                LOGGER( 1, "    ( chooseTheEndOfMapStartOption ) 2. Returning true." )
                return true;
            }
        }
        case END_AT_THE_NEXT_ROUND_END:
        {
            switch( endOfMapVoteStart )
            {
                case 1:
                {
                    if( ( g_isGameEndingTypeContextSaved ? g_isTheLastGameRoundContext : g_isTheLastGameRound )
                        || ( endOfMapVoteStart
                           && roundsRemaining < endOfMapVoteStart ) )
                    {
                        LOGGER( 1, "    ( chooseTheEndOfMapStartOption ) 3. Returning true." )
                        return true;
                    }
                }
                case 2:
                {
                    if( ( g_isGameEndingTypeContextSaved ? g_isThePenultGameRoundContext : g_isThePenultGameRound )
                        || ( endOfMapVoteStart
                             && roundsRemaining < endOfMapVoteStart ) )
                    {
                        LOGGER( 1, "    ( chooseTheEndOfMapStartOption ) 4. Returning true." )
                        return true;
                    }
                }
                default:
                {
                    if( endOfMapVoteStart
                        && roundsRemaining < endOfMapVoteStart )
                    {
                        LOGGER( 1, "    ( chooseTheEndOfMapStartOption ) 5. Returning true." )
                        return true;
                    }
                }
            }
        }
    }

    LOGGER( 1, "    ( chooseTheEndOfMapStartOption ) Returning false." )
    return false;
}

/**
 * Predict if this will be the last round and allow to start the voting. Give time range to try
 * detecting the round start, to avoid the old buy weapons menu override. This is called every
 * round start and determines whether this round should be used to perform the map voting.
 *
 * If this is called between the team_win_event(0) and the round_end_event(0)? This cannot to be
 * called otherwise the seconds passed since the round started will be out of date.
 *
 * @param secondsRemaining         how many seconds are remaining to the map end.
 */
stock isToStartTheVotingOnThisRound( secondsRemaining, GameEndingType:gameEndingType )
{
    LOGGER( 128, "I AM ENTERING ON isToStartTheVotingOnThisRound(2) secondsRemaining: %d", secondsRemaining )

    if( get_pcvar_num( cvar_endOfMapVote )
        && !task_exists( TASKID_START_VOTING_DELAYED ) )
    {
        new secondsPassed;

        // Reduce the total time due the PERIODIC_CHECKING_INTERVAL error.
        if( secondsRemaining > 0 )
        {
            if( ( secondsPassed = secondsRemaining - PERIODIC_CHECKING_INTERVAL ) < 1 )
            {
                secondsPassed = 1;
            }
        }

        LOGGER( 0, "", debugIsTimeToStartTheEndOfMap( secondsRemaining, 256 ) )

        new roundsRemaining = howManyRoundsAreRemaining( secondsPassed, gameEndingType );
        return chooseTheEndOfMapStartOption( roundsRemaining );
    }

    LOGGER( 1, "    ( isToStartTheVotingOnThisRound ) Just returning false." )
    return false;
}

stock howManySecondsLastMapTheVoting()
{
    LOGGER( 128, "I AM ENTERING ON howManySecondsLastMapTheVoting(0)" )
    new Float:voteTime;

    // Until the pendingVoteCountdown(0) to finish takes getVoteAnnouncementTime() + VOTE_TIME_SEC + VOTE_TIME_SEC seconds.
    voteTime = getVoteAnnouncementTime() + VOTE_TIME_SEC + VOTE_TIME_SEC;

    // After, it takes more the `g_votingSecondsRemaining` until the the close vote function to be called.
    voteTime += get_pcvar_float( cvar_voteDuration );

    // When the voting is closed on closeVoting(0), take more VOTE_TIME_COUNT seconds until the result to be counted.
    voteTime += VOTE_TIME_COUNT;

    // Let us assume the worst case, then always will be performed a runoff voting.
    if( get_pcvar_num( cvar_runoffEnabled ) == RUNOFF_ENABLED )
    {
        voteTime = voteTime + voteTime + get_pcvar_float( cvar_runoffDuration ) + VOTE_TIME_RUNOFF;
    }

    LOGGER( 1, "    ( howManySecondsLastMapTheVoting ) Returning the vote total time: %f", voteTime )
    return floatround( voteTime, floatround_ceil );
}

/**
 * This function choose which round round ending type it is and count how many rounds there are.
 * The types are:
 *
 *     1) Per rounds.
 *     2) Is by mp_winlimit expiration proximity?
 *     3) Is by mp_maxrounds expiration proximity?
 *     4) Per minutes.
 */
stock howManyRoundsAreRemaining( secondsRemaining, GameEndingType:whatGameEndingType )
{
    LOGGER( 128, "I AM ENTERING ON howManyRoundsAreRemaining(2), g_roundAverageTime: %d", g_roundAverageTime )

    switch( whatGameEndingType )
    {
        case GameEndingType_ByMaxRounds:
        {
            return ( g_isGameEndingTypeContextSaved ?
                     g_maxRoundsContextSaved : get_pcvar_num( cvar_mp_maxrounds ) ) - g_totalRoundsPlayed;
        }
        case GameEndingType_ByWinLimit:
        {
            return ( g_isGameEndingTypeContextSaved ?
                     g_winLimitContextSaved : get_pcvar_num( cvar_mp_winlimit ) ) - max( g_totalCtWins, g_totalTerroristsWins );
        }
        case GameEndingType_ByFragLimit:
        {
            new roundsLeftBy_frags = ( g_isGameEndingTypeContextSaved ?
                                       g_fragLimitContextSaved : get_pcvar_num( cvar_mp_fraglimit ) ) - g_greatestKillerFrags;

            getRoundsRemainingBy( _, roundsLeftBy_frags );
            return roundsLeftBy_frags;
        }
        case GameEndingType_ByTimeLimit:
        {
            // The secondsRemaining is already correctly updated by the `g_isGameEndingTypeContextSaved`.
            new roundsLeftBy_time = secondsRemaining;

            getRoundsRemainingBy( roundsLeftBy_time );
            return roundsLeftBy_time;
        }
    }

    LOGGER( 1, "    ( howManyRoundsAreRemaining ) Returning MAX_INTEGER: %d", MAX_INTEGER )
    return MAX_INTEGER;
}

stock getRoundsRemainingBy( &by_time = 0, &by_frags = 0 )
{
    LOGGER( 128, "I AM ENTERING ON getRoundsRemainingBy(2), by_time: %d, by_frags: %d", by_time, by_frags )

    if( by_time  < 1 ) by_time  = 1;
    if( by_frags < 1 ) by_frags = 1;

    // Make sure there are enough data to operate, otherwise set valid data.
    if( g_totalRoundsSavedTimes > MIN_VOTE_START_ROUNDS_DELAY )
    {
        // Avoid zero division
        if( g_roundAverageTime )
        {
            by_time = by_time / g_roundAverageTime;
        }
        else
        {
            by_time = by_time / SECONDS_BY_ROUND_AVERAGE;
        }

        // Avoid zero division
        if( g_greatestKillerFrags
            && g_totalRoundsPlayed )
        {
            new integerDivision = g_greatestKillerFrags / g_totalRoundsPlayed;
            by_frags = by_frags / ( integerDivision ? integerDivision : FRAGS_BY_ROUND_AVERAGE );
        }
        else
        {
            by_frags = by_frags / FRAGS_BY_ROUND_AVERAGE;
        }
    }
    else
    {
        by_time  = by_time / SECONDS_BY_ROUND_AVERAGE;
        by_frags = by_frags / FRAGS_BY_ROUND_AVERAGE;
    }
}

/**
 * Wrapper to call switchEndingGameType(10) without repeating the same `if` code everywhere.
 */
#define SWITCH_ENDING_GAME_TYPE_RETURN(%0,%1,%2,%3,%4,%5,%6,%7,%8,%9) \
{ \
    gameType = switchEndingGameType( %0, %1, %2, %3, %4, %5, %6, %7, %8, %9 ); \
    if( gameType != GameEndingType_ByNothing ) \
    { \
        LOGGER( 1, "    ( SWITCH_ENDING_GAME_TYPE_RETURN ) Returning GameEndingType: %d", gameType ) \
        return gameType; \
    } \
}

stock GameEndingType:whatGameEndingTypeItIs()
{
    LOGGER( 128, "I AM ENTERING ON whatGameEndingTypeItIs(0)" )
    new GameEndingType:gameType;

    new by_time;
    new by_frags;
    new by_winlimit;
    new by_maxrounds;

    new cv_time;
    new cv_frags;
    new cv_maxrounds;
    new cv_winlimit;

    cv_winlimit  = get_pcvar_num( cvar_mp_winlimit  );
    cv_maxrounds = get_pcvar_num( cvar_mp_maxrounds );
    cv_time      = get_pcvar_num( cvar_mp_timelimit );
    cv_frags     = get_pcvar_num( cvar_mp_fraglimit );

    by_time      = get_timeleft();
    by_frags     = cv_frags     - g_greatestKillerFrags;
    by_maxrounds = cv_maxrounds - g_totalRoundsPlayed;
    by_winlimit  = cv_winlimit  - max( g_totalCtWins, g_totalTerroristsWins );

    getRoundsRemainingBy( by_time, by_frags );
    LOGGER( 0, "", debugWhatGameEndingTypeItIs( by_maxrounds, by_time, by_winlimit, by_frags, 256 ) )

    // Check whether there is any allowed combination.
    SWITCH_ENDING_GAME_TYPE_RETURN( by_winlimit    , cv_winlimit , by_time    , cv_time      , \
            by_maxrounds, cv_maxrounds, by_frags   , cv_frags    , GameEndingType_ByWinLimit , false )
    SWITCH_ENDING_GAME_TYPE_RETURN( by_maxrounds   , cv_maxrounds, by_time    , cv_time      , \
            by_winlimit , cv_winlimit , by_frags   , cv_frags    , GameEndingType_ByMaxRounds, false )
    SWITCH_ENDING_GAME_TYPE_RETURN( by_time        , cv_time     , by_winlimit, cv_winlimit  , \
            by_maxrounds, cv_maxrounds, by_frags   , cv_frags    , GameEndingType_ByTimeLimit, false )
    SWITCH_ENDING_GAME_TYPE_RETURN( by_frags       , cv_frags    , by_time    , cv_time      , \
            by_maxrounds, cv_maxrounds, by_winlimit, cv_winlimit , GameEndingType_ByFragLimit, false )

    // Allow self return for the first matching slot, as there are not combinations at all.
    SWITCH_ENDING_GAME_TYPE_RETURN( cv_winlimit    , cv_winlimit , cv_time    , cv_time      , \
            cv_maxrounds, cv_maxrounds, cv_frags   , cv_frags    , GameEndingType_ByWinLimit , true )
    SWITCH_ENDING_GAME_TYPE_RETURN( cv_maxrounds   , cv_maxrounds, cv_time    , cv_time      , \
            cv_winlimit , cv_winlimit , cv_frags   , cv_frags    , GameEndingType_ByMaxRounds, true )
    SWITCH_ENDING_GAME_TYPE_RETURN( cv_time        , cv_time     , cv_winlimit, cv_winlimit  , \
            cv_maxrounds, cv_maxrounds, cv_frags   , cv_frags    , GameEndingType_ByTimeLimit, true )
    SWITCH_ENDING_GAME_TYPE_RETURN( cv_frags       , cv_frags    , cv_time    , cv_time      , \
            cv_maxrounds, cv_maxrounds, cv_winlimit, cv_winlimit , GameEndingType_ByFragLimit, true )

    LOGGER( 256, "    ( whatGameEndingTypeItIs ) Returning: %d", GameEndingType_ByNothing )
    return GameEndingType_ByNothing;
}

stock GameEndingType:switchEndingGameType( by_maxrounds, cv_maxrounds, by_time, cv_time, by_winlimit, cv_winlimit,
                                           by_frags, cv_frags, GameEndingType:type, bool:allowSelfReturn )
{
    LOGGER( 256, "I AM ENTERING ON switchEndingGameType(10) GameEndingType: %d", type )

    // If the cvar original value is set to a zero value, the round will never ended by such cvar.
    if( cv_maxrounds > 0 )
    {
        // If the `if-else` chain is not cut once the higher order is evaluated, it will be able to
        // fall under the wrong entrance type, as lower the level, more the restrictions are lost.
        if( cv_time > 0
            && cv_winlimit > 0
            && cv_frags > 0 )
        {
            if( by_time > by_maxrounds
                && by_winlimit > by_maxrounds
                && by_frags > by_maxrounds )
            {
                LOGGER( 256, "    ( switchEndingGameType ) 1" )
                return type;
            }
        }
        else if( cv_time > 0
                 && cv_winlimit > 0 )
        {
            if( by_time > by_maxrounds
                && by_winlimit > by_maxrounds )
            {
                LOGGER( 256, "    ( switchEndingGameType ) 2" )
                return type;
            }
        }
        else if( cv_time > 0
                 && cv_frags > 0 )
        {
            if( by_time > by_maxrounds
                && by_frags > by_maxrounds )
            {
                LOGGER( 256, "    ( switchEndingGameType ) 3" )
                return type;
            }
        }
        else if( cv_winlimit > 0
                 && cv_frags > 0 )
        {
            if( by_winlimit > by_maxrounds
                && by_frags > by_maxrounds )
            {
                LOGGER( 256, "    ( switchEndingGameType ) 4" )
                return type;
            }
        }
        // If the `by_maxrounds` did not fall in any of these above traps to fall out the `if-else` chain,
        // it is safe to let if free from this point towards.
        else if( cv_time > 0
                 && by_time > by_maxrounds )
        {
            LOGGER( 256, "    ( switchEndingGameType ) 5" )
            return type;
        }
        else if( cv_winlimit > 0
                 && by_winlimit > by_maxrounds )
        {
            LOGGER( 256, "    ( switchEndingGameType ) 6" )
            return type;
        }
        else if( cv_frags > 0
                 && by_frags > by_maxrounds )
        {
            LOGGER( 256, "    ( switchEndingGameType ) 7" )
            return type;
        }
        else if( allowSelfReturn )
        {
            LOGGER( 256, "    ( switchEndingGameType ) 8" )
            return type;
        }
    }

    LOGGER( 256, "    ( switchEndingGameType ) Returning GameEndingType_ByNothing: %d", GameEndingType_ByNothing )
    return GameEndingType_ByNothing;
}

stock debugWhatGameEndingTypeItIs( rounds_left_by_maxrounds, rounds_left_by_time, rounds_left_by_winlimit,
                                   rounds_left_by_frags, debugLevel )
{
    LOGGER( debugLevel, "I AM ENTERING ON debugWhatGameEndingTypeItIs(5)" )

    LOGGER( debugLevel, "" )
    LOGGER( debugLevel, "( debugWhatGameEndingTypeItIs ) cv_winlimit: %2d", get_pcvar_num( cvar_mp_winlimit  ) )
    LOGGER( debugLevel, "( debugWhatGameEndingTypeItIs ) cv_maxrounds: %0d", get_pcvar_num( cvar_mp_maxrounds ) )
    LOGGER( debugLevel, "( debugWhatGameEndingTypeItIs ) cv_time: %6f", get_pcvar_float( cvar_mp_timelimit ) )
    LOGGER( debugLevel, "( debugWhatGameEndingTypeItIs ) cv_frags: %5d", get_pcvar_num( cvar_mp_fraglimit ) )

    LOGGER( debugLevel, "( debugWhatGameEndingTypeItIs )" )
    LOGGER( debugLevel, "( debugWhatGameEndingTypeItIs ) rounds_left_by_winlimit: %2d", rounds_left_by_winlimit )
    LOGGER( debugLevel, "( debugWhatGameEndingTypeItIs ) rounds_left_by_maxrounds: %0d", rounds_left_by_maxrounds )
    LOGGER( debugLevel, "( debugWhatGameEndingTypeItIs ) rounds_left_by_time: %6d", rounds_left_by_time )
    LOGGER( debugLevel, "( debugWhatGameEndingTypeItIs ) rounds_left_by_frags: %5d", rounds_left_by_frags )

    LOGGER( debugLevel, "( debugWhatGameEndingTypeItIs )" )
    LOGGER( debugLevel, "( debugWhatGameEndingTypeItIs ) GameEndingType_ByWinLimit: %2d", GameEndingType_ByWinLimit )
    LOGGER( debugLevel, "( debugWhatGameEndingTypeItIs ) GameEndingType_ByMaxRounds: %d", GameEndingType_ByMaxRounds )
    LOGGER( debugLevel, "( debugWhatGameEndingTypeItIs ) GameEndingType_ByTimeLimit: %d", GameEndingType_ByTimeLimit )
    LOGGER( debugLevel, "( debugWhatGameEndingTypeItIs ) GameEndingType_ByFragLimit: %d", GameEndingType_ByFragLimit )

    LOGGER( debugLevel, "" )
    return 0;
}

stock debugIsTimeToStartTheEndOfMap( secondsRemaining, debugLevel )
{
    LOGGER( 128, "I AM ENTERING ON debugIsTimeToStartTheEndOfMap(2)" )
    new taskExist = task_exists( TASKID_START_VOTING_DELAYED );

    LOGGER( debugLevel, "" )
    LOGGER( debugLevel, "( debugIsTimeToStartTheEndOfMap ) task_exists TASKID_START_VOTING_DELAYED: %d", taskExist )
    LOGGER( debugLevel, "( debugIsTimeToStartTheEndOfMap ) g_isTheLastGameRound: %d", g_isTheLastGameRound )
    LOGGER( debugLevel, "( debugIsTimeToStartTheEndOfMap ) g_isThePenultGameRound: %d", g_isThePenultGameRound )
    LOGGER( debugLevel, "( debugIsTimeToStartTheEndOfMap ) debugLevel: %d", debugLevel )
    LOGGER( debugLevel, "( debugIsTimeToStartTheEndOfMap ) secondsRemaining: %d", secondsRemaining )
    LOGGER( debugLevel, "( debugIsTimeToStartTheEndOfMap ) cvar_endOnRound: %d", get_pcvar_num( cvar_endOnRound ) )
    LOGGER( debugLevel, "( debugIsTimeToStartTheEndOfMap ) cvar_endOfMapVote: %d", get_pcvar_num( cvar_endOfMapVote ) )
    LOGGER( debugLevel, "( debugIsTimeToStartTheEndOfMap ) cvar_endOfMapVoteStart: %d", get_pcvar_num( cvar_endOfMapVoteStart ) )
    LOGGER( debugLevel, "( debugIsTimeToStartTheEndOfMap ) START_VOTEMAP_MIN_TIME: %d",  START_VOTEMAP_MIN_TIME )
    LOGGER( debugLevel, "( debugIsTimeToStartTheEndOfMap ) START_VOTEMAP_MAX_TIME: %d",  START_VOTEMAP_MAX_TIME )
    LOGGER( debugLevel, "( debugIsTimeToStartTheEndOfMap ) g_totalRoundsSavedTimes: %d", g_totalRoundsSavedTimes )
    LOGGER( debugLevel, "( debugIsTimeToStartTheEndOfMap ) PERIODIC_CHECKING_INTERVAL: %d", PERIODIC_CHECKING_INTERVAL )
    LOGGER( debugLevel, "( debugIsTimeToStartTheEndOfMap ) MIN_VOTE_START_ROUNDS_DELAY: %d", MIN_VOTE_START_ROUNDS_DELAY )
    LOGGER( debugLevel, "( debugIsTimeToStartTheEndOfMap ) IS_END_OF_MAP_VOTING_GOING_ON(): %d", IS_END_OF_MAP_VOTING_GOING_ON() )
    LOGGER( debugLevel, "" )

    return 0;
}

/**
 * Determine whether the server is on an acceptable time to start a map voting on the middle of the
 * round and to start the end map voting near the map time limit expiration.
 *
 * When other features as `cvar_endOfMapVoteStart` and `cvar_endOnRound` are not enabled, then
 * we must to start the voting right away when the minimum necessary time comes.
 *
 * As we only periodically check to whether to start the map voting each 15 seconds, we must to set
 * the minimum check as: g_votingSecondsRemaining + 15 seconds + 1
 */
stock isTimeToStartTheEndOfMapVoting()
{
    LOGGER( 256, "I AM ENTERING ON isTimeToStartTheEndOfMapVoting(0) secondsRemaining: %d", get_timeleft() )
    LOGGER( 0, "", debugIsTimeToStartTheEndOfMap( get_timeleft(), 32 ) )

    if( !IS_END_OF_MAP_VOTING_GOING_ON()
        && !task_exists( TASKID_START_VOTING_DELAYED )
        && get_pcvar_num( cvar_endOfMapVote ) )
    {
        //     If the `cvar_endOfMapVoteStart` is not enabled, we must to start a map voting right now
        // because the time is ending and the `cvar_endOfMapVoteStart` will not be able to start a map
        // voting.
        //
        //     If the `cvar_endOnRound` is not enabled we must to start the voting right now because
        // there will be no round end waiting and once the `secondsRemaining` are finished, the map
        // will change whether the voting is complete or not.
        //     This is not the case when the `cvar_endOnRound` is enabled. If the voting is not finish
        // when the round is end, a new extra round will be played. If the map time is too big, makes
        // no sense to wait and will probably not to start the voting.
        //
        //     Let suppose the `cvar_endOnRound` is set to 1, and right now the the time left is 20, and
        // there are remaining 30 seconds to finish the round. If this is called, it should do nothing
        // because as the `cvar_endOnRound` is enabled, the voting will be scheduled by map_manageEnd(0).
        //
        if( !ARE_THERE_ENOUGH_PLAYERS_FOR_MANAGE_END()
           || !get_pcvar_num( cvar_endOfMapVoteStart )
           || !get_pcvar_num( cvar_endOnRound )
           || IS_THE_ROUND_TIME_TOO_BIG() )
        {
            LOGGER( 256, "    ( isTimeToStartTheEndOfMapVoting ) Just returning true." )
            return true;
        }
    }

    LOGGER( 256, "    ( isTimeToStartTheEndOfMapVoting ) Just returning false." )
    return false;
}

/**
 * This only handles the voting starting by limit expiration.
 *
 * The map will not accept to change when the voting is running due the restriction on
 * try_to_process_last_round(2). On the cases where that restriction does not have effect, the
 * voting will already have been started by vote_manageEnd(0) when the maximum allowed time comes.
 */
stock tryToStartTheVotingOnThisRound()
{
    LOGGER( 128, "I AM ENTERING ON tryToStartTheVotingOnThisRound(0)" )

    new timeLeft;
    new GameEndingType:gameEndingType;

    // If the context was deleted by map_manageEnd(0) due the limit expiration, we need to used the saved
    // context, before they being deleted to prevent the map from changing.
    if( g_isGameEndingTypeContextSaved )
    {
        timeLeft       = g_timeLeftContextSaved;
        gameEndingType = g_gameEndingTypeContextSaved;
    }
    else
    {
        timeLeft       = get_timeleft();
        gameEndingType = whatGameEndingTypeItIs();
    }

    if( isToStartTheVotingOnThisRound( timeLeft, gameEndingType ) )
    {
        switch( gameEndingType )
        {
            case GameEndingType_ByWinLimit:
            {
                set_task( float( ROUND_VOTING_START_SECONDS_DELAY() ), "start_voting_by_winlimit", TASKID_START_VOTING_DELAYED );
            }
            case GameEndingType_ByMaxRounds:
            {
                set_task( float( ROUND_VOTING_START_SECONDS_DELAY() ), "start_voting_by_maxrounds", TASKID_START_VOTING_DELAYED );
            }
            case GameEndingType_ByFragLimit:
            {
                set_task( float( ROUND_VOTING_START_SECONDS_DELAY() ), "start_voting_by_frags", TASKID_START_VOTING_DELAYED );
            }
            default:
            {
                set_task( float( ROUND_VOTING_START_SECONDS_DELAY() ), "start_voting_by_timer", TASKID_START_VOTING_DELAYED );
            }
        }
    }
}

/**
 * Called before the freeze time to start counting. This event is not called for the first game round.
 */
public new_round_event()
{
    LOGGER( 128, "I AM ENTERING ON new_round_event(0)" )
    tryToStartTheVotingOnThisRound();

    if( IS_ABLE_TO_PERFORMED_A_MAP_CHANGE() )
    {
        if( g_isTheLastGameRound )
        {
            if( get_pcvar_num( cvar_endOnRoundChange ) == MAP_CHANGES_AT_THE_NEXT_ROUND_START )
            {
                try_to_process_last_round();
            }
        }
    }
}

/**
 * Called after the freeze time to stop counting.
 */
public round_start_event()
{
    LOGGER( 128, "I AM ENTERING ON round_start_event(0)" )

    g_roundStartTime = floatround( get_gametime(), floatround_ceil );

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

    // Lazy update the game ending context, after the round_start_event(0) to be completed.
    g_isTheRoundEndWhileVoting = false;

    if( g_isThePenultGameRoundContext && g_isThePenultGameRound )
    {
        g_isTheLastGameRoundContext   = true;
        g_isThePenultGameRoundContext = false;
    }
}

public team_win_event()
{
    LOGGER( 128, "" )
    LOGGER( 128, "" )
    LOGGER( 128, "I AM ENTERING ON team_win_event(0)" )

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

        if( ( wins_CT_trigger > g_winLimitInteger
              || wins_Terrorist_trigger > g_winLimitInteger )
            && isTimeToStartTheEndOfMapVoting() )
        {
            START_VOTING_BY_MIDDLE_ROUND_DELAY( "start_voting_by_winlimit" )
        }

        if( g_totalCtWins > g_winLimitInteger - 2
            || g_totalTerroristsWins > g_winLimitInteger - 2 )
        {
            try_to_manage_map_end();
        }
    }

    if( g_voteStatus & IS_VOTE_IN_PROGRESS )
    {
        g_isTheRoundEndWhileVoting = true;
    }

    LOGGER( 0, "", debugTeamWinEvent( string_team_winner, wins_CT_trigger, wins_Terrorist_trigger ) )
}

stock debugTeamWinEvent( string_team_winner[], wins_CT_trigger, wins_Terrorist_trigger )
{
    LOGGER( 32, "I AM ENTERING ON debugTeamWinEvent(3)" )

    LOGGER( 32, "( debugTeamWinEvent )" )
    LOGGER( 32, "( debugTeamWinEvent ) string_team_winner: %s", string_team_winner )
    LOGGER( 32, "( debugTeamWinEvent ) g_winLimitInteger: %d", g_winLimitInteger )
    LOGGER( 32, "( debugTeamWinEvent ) wins_CT_trigger: %d", wins_CT_trigger )
    LOGGER( 32, "( debugTeamWinEvent ) wins_Terrorist_trigger: %d", wins_Terrorist_trigger )
    LOGGER( 32, "( debugTeamWinEvent ) g_isGameEndingTypeContextSaved: %d", g_isGameEndingTypeContextSaved )
    LOGGER( 32, "( debugTeamWinEvent ) g_gameEndingTypeContextSaved: %d", g_gameEndingTypeContextSaved )
    LOGGER( 32, "( debugTeamWinEvent ) g_timeLeftContextSaved: %d", g_timeLeftContextSaved )
    LOGGER( 32, "( debugTeamWinEvent ) g_maxRoundsContextSaved: %d", g_maxRoundsContextSaved )
    LOGGER( 32, "( debugTeamWinEvent ) g_winLimitContextSaved: %d", g_winLimitContextSaved )
    LOGGER( 32, "( debugTeamWinEvent ) g_fragLimitContextSaved: %d", g_fragLimitContextSaved )
    LOGGER( 32, "( debugTeamWinEvent ) g_isTheLastGameRound: %d", g_isTheLastGameRound )
    LOGGER( 32, "( debugTeamWinEvent ) g_isTheLastGameRoundContext: %d", g_isTheLastGameRoundContext )
    LOGGER( 32, "( debugTeamWinEvent ) g_isThePenultGameRound: %d", g_isThePenultGameRound )
    LOGGER( 32, "( debugTeamWinEvent ) g_isThePenultGameRoundContext: %d", g_isThePenultGameRoundContext )
    LOGGER( 32, "( debugTeamWinEvent )" )

    return 0;
}

/**
 * Called on the round_end_event(). This is the place to change the map when the variables
 * `g_isThePenultGameRound` and `g_isTheLastGameRound` are set to true.
 */
stock endRoundWatchdog()
{
    LOGGER( 128, "I AM ENTERING ON endRoundWatchdog(0)" )
    new bool:endOfMapVoteExpiration = get_pcvar_num( cvar_endOfMapVoteExpiration ) != 0;

    // Just update their values when calling this function.
    g_fragLimitNumber = get_pcvar_num( cvar_mp_fraglimit );
    g_timeLimitNumber = get_pcvar_num( cvar_mp_timelimit );

    if( endOfMapVoteExpiration
        && g_voteStatus & IS_VOTE_OVER )
    {
        // Make the map to change immediately.
        g_isTheLastGameRound   = true;
        g_isThePenultGameRound = false;
    }

    // Always remove this, if set up.
    remove_task( TASKID_SHOW_LAST_ROUND_HUD );

    // This is what changes the map on the next round. The last round has ended and the map will change about now.
    if( g_isTheLastGameRound )
    {
        // When time runs out, end map at the current round end.
        if( endOfMapVoteExpiration
            || get_pcvar_num( cvar_endOnRoundChange ) == MAP_CHANGES_AT_THE_CURRENT_ROUND_END )
        {
            try_to_process_last_round();
        }
    }
    else if( g_isThePenultGameRound )
    {
        // When time runs out, end map at the next round end.
        g_isTheLastGameRound = true;

        // Set it to false because later we first could try to check this before `g_isTheLastGameRound`
        // resulting on an infinity loop.
        g_isThePenultGameRound = false;

        set_task( 5.0, "configure_last_round_HUD", TASKID_PROCESS_LAST_ROUND );
    }
}

public round_end_event()
{
    LOGGER( 128, "I AM ENTERING ON round_end_event(0)" )
    new current_rounds_trigger;

    g_totalRoundsPlayed++;
    saveTheRoundTime();

    // Get the updated value.
    g_maxRoundsNumber = get_pcvar_num( cvar_mp_maxrounds );

    if( g_maxRoundsNumber )
    {
        current_rounds_trigger = g_totalRoundsPlayed + VOTE_START_ROUNDS;

        if( current_rounds_trigger > g_maxRoundsNumber
            && isTimeToStartTheEndOfMapVoting() )
        {
            START_VOTING_BY_MIDDLE_ROUND_DELAY( "start_voting_by_maxrounds" )
        }

        if( g_totalRoundsPlayed > g_maxRoundsNumber - 2 )
        {
            try_to_manage_map_end();
        }
    }

    // If this is called when the voting is going on, it will cause the voting to be cut
    // and will force the map to immediately change to the next map on the map cycle.
    if( IS_ABLE_TO_PERFORMED_A_MAP_CHANGE() )
    {
        endRoundWatchdog();
    }

    if( g_voteStatus & IS_VOTE_IN_PROGRESS )
    {
        g_isTheRoundEndWhileVoting = true;
    }

    LOGGER( 32, "( round_end_event ) g_maxRoundsNumber: %d", g_maxRoundsNumber )
    LOGGER( 32, "( round_end_event ) g_totalRoundsPlayed: %d, current_rounds_trigger: %d", \
            g_totalRoundsPlayed, current_rounds_trigger )
}

stock saveTheRoundTime()
{
    LOGGER( 128, "I AM ENTERING ON saveTheRoundTime(0)" )
    new roundTotalTime = floatround( get_gametime(), floatround_ceil ) - g_roundStartTime;

    // Rounds taking less than 10 seconds does not seem to fit.
    if( roundTotalTime > MIN_ROUND_TIME_DELAY )
    {
        static lastSavedRound;
        static roundPlayedTimes[ 5 ];

        // To keep the latest round data up to date.
        roundPlayedTimes[ lastSavedRound ] = roundTotalTime;

        // Increments the counter until 20, and stops it as our array has only 20 slots.
        if( g_totalRoundsSavedTimes < sizeof roundPlayedTimes )
        {
            g_totalRoundsSavedTimes++;
        }

        // Calculate the rounds average times.
        g_roundAverageTime = roundPlayedTimes[ 0 ];

        for( new index = 1; index < g_totalRoundsSavedTimes; index++ )
        {
            g_roundAverageTime = g_roundAverageTime + roundPlayedTimes[ index ];
        }

        LOGGER( 32, "( saveTheRoundTime ) Total Sum: %d", g_roundAverageTime )
        g_roundAverageTime = ( g_roundAverageTime / g_totalRoundsSavedTimes ) + 1;

        // Updates the next position to be inserted.
        lastSavedRound = ( lastSavedRound + 1 ) % sizeof roundPlayedTimes;

        LOGGER( 32, "( saveTheRoundTime ) lastSavedRound: %d", lastSavedRound )
        LOGGER( 32, "( saveTheRoundTime ) g_roundAverageTime: %d", g_roundAverageTime )
        LOGGER( 32, "( saveTheRoundTime ) g_totalRoundsSavedTimes: %d", g_totalRoundsSavedTimes )
    }

    LOGGER( 32, "( saveTheRoundTime ) roundTotalTime: %d", roundTotalTime )
}

stock try_to_manage_map_end( bool:isFragLimitEnd = false )
{
    LOGGER( 128, "I AM ENTERING ON try_to_manage_map_end()" )

    if( g_isOnMaintenanceMode )
    {
        prevent_map_change();
        color_print( 0, "%L", LANG_PLAYER, "GAL_CHANGE_MAINTENANCE" );
    }
    else if( !( g_isTheLastGameRound
                || g_isThePenultGameRound ) )
    {
        // Do not invert the order of these conditional statements, otherwise it will break everything.
        if( !ARE_THERE_ENOUGH_PLAYERS_FOR_MANAGE_END()
            || !map_manageEnd() )
        {
            try_to_process_last_round( isFragLimitEnd );
        }
    }
}

/**
 *     This must to be called to perform the delayed map start vote, when the variables
 * g_isTheLastGameRound/g_isThePenultGameRound are set to true. Therefore, it would set the task
 * to start the map voting considering how many seconds from this round already have been played.
 *
 *     Also, at the same time, the vote_manageEnd(0) must to attempt to start the voting in case
 * the time to end the map or the round? Here we need to take care of:
 *
 *     1. If the time will end in 70 seconds, but the map will hold due `cvar_endOnRound`, we do not
 *        necessary need to start the map voting, as the map may last longer as 200 seconds.
 *     2. Moreover, we just to need to take the `g_roundAverageTime` and the `g_roundStartTime`
 *        and calculate how much time is left on the round. Then pass it to:
 *        isTimeToStartTheEndOfMapVoting( roundSecondsLeft )
 *
 *     Now, if the round end before the voting to complete, the endRoundWatchdog(0) will not be
 * called and the a extra round will be played. But if we are not using the `cvar_endOnRound` feature?
 *
 *         We do not wait to start the map voting, and to start the it right when the remaining time
 *     reaches the `g_votingSecondsRemaining` time. But as we only periodically check to whether to start
 *     the map voting each 15 seconds, we must to set the maximum check start as `g_votingSecondsRemaining`
 *     and the minimum start check as `g_votingSecondsRemaining + 15 seconds + 3`. These values are defined
 *     by the constants `START_VOTEMAP_MAX_TIME` and `START_VOTEMAP_MIN_TIME`, respectively.
 *
 *     Now the the average round time is shorter than the total voting time, we must to
 * start a map voting, otherwise we could get an extra round being played. This case also
 * must to be handled by tryToStartTheVotingOnThisRound(0), to start the voting on round before
 * the actual last round.
 */
public map_manageEnd()
{
    LOGGER( 128, "I AM ENTERING ON map_manageEnd(0)" )
    LOGGER( 2, "%32s mp_timelimit: %f, get_real_players_number: %d", "map_manageEnd(in)", \
            get_pcvar_float( cvar_mp_timelimit ), get_real_players_number() )

    switch( get_pcvar_num( cvar_endOnRound ) )
    {
        // when time runs out, end at the current round end
        case END_AT_THE_CURRENT_ROUND_END:
        {
            g_isTheLastGameRound = true;
        }
        // when time runs out, end at the next round end
        case END_AT_THE_NEXT_ROUND_END:
        {
            // This is to avoid have a extra round at special mods where time limit is equal the
            // round timer.
            if( get_pcvar_float( cvar_mp_roundtime ) > 8.0 )
            {
                g_isTheLastGameRound = true;
            }
            else
            {
                g_isThePenultGameRound = true;
            }
        }
        default:
        {
            LOGGER( 1, "    ( map_manageEnd ) Just returning and blocking the end management." )
            return false;
        }
    }

    // This could be or not the last round to be played. If this is the last round, it means the
    // feature `cvar_endOnRound` is enabled. Otherwise the voting would have been started when the
    // time left get on the minimum time set by `g_totalVoteTime`.
    //
    // We need to check it after to call prevent_map_change(0), otherwise we will not be able to
    // calculate whether to start the voting on this round correctly. The point around here is,
    //
    //     1. If the voting was not started yet.
    //     2. And the mapping is ending.
    //     3. The `cvar_endOfMapVoteStart` predicted this is not the correct last round to start voting.
    //
    saveGameEndingTypeContext();

    // These must to be called after saveGameEndingTypeContext(0), otherwise it will invalid its
    // required data as `mp_timelimit`, `mp_fraglimit` and etc.
    prevent_map_change();
    configure_last_round_HUD();

    LOGGER( 2, "%32s mp_timelimit: %f, get_real_players_number: %d", "map_manageEnd(out)", \
            get_pcvar_float( cvar_mp_timelimit ), get_real_players_number() )

    LOGGER( 1, "    ( map_manageEnd ) Just returning and allowing the end management." )
    return true;
}

stock saveGameEndingTypeContext()
{
    LOGGER( 128, "I AM ENTERING ON saveGameEndingTypeContext(0)" )
    g_isGameEndingTypeContextSaved = true;

    // Save a round time which will force the voting to start immediately by howManyRoundsAreRemaining(2).
    g_gameEndingTypeContextSaved = whatGameEndingTypeItIs();

    g_timeLeftContextSaved  = get_timeleft() ? MIN_ROUND_TIME_DELAY - 1 : 0;
    g_maxRoundsContextSaved = get_pcvar_num( cvar_mp_maxrounds );
    g_winLimitContextSaved  = get_pcvar_num( cvar_mp_winlimit );
    g_fragLimitContextSaved = get_pcvar_num( cvar_mp_fraglimit );

    // We need to save this variables because they are set at the round end before the new round start.
    g_isTheLastGameRoundContext   = g_isTheLastGameRound;
    g_isThePenultGameRoundContext = g_isThePenultGameRound;
}

stock prevent_map_change()
{
    LOGGER( 128, "I AM ENTERING ON prevent_map_change(0)" )
    saveEndGameLimits();

    // If somehow the cvar_mp_roundtime does not exist, it will point to a cvar within zero
    new Float:roundTimeMinutes = get_pcvar_float( cvar_mp_roundtime );

    // Prevent the map from ending automatically.
    tryToSetGameModCvarFloat( cvar_mp_timelimit, 0.0 );
    tryToSetGameModCvarNum(   cvar_mp_maxrounds, 0   );
    tryToSetGameModCvarNum(   cvar_mp_winlimit,  0   );
    tryToSetGameModCvarNum(   cvar_mp_fraglimit, 0   );

    LOGGER( 2, "( prevent_map_change ) IS CHANGING THE CVAR %-22s to '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOGGER( 2, "( prevent_map_change ) IS CHANGING THE CVAR %-22s to '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOGGER( 2, "( prevent_map_change ) IS CHANGING THE CVAR %-22s to '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOGGER( 2, "( prevent_map_change ) IS CHANGING THE CVAR %-22s to '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )

    // Prevent the map from being played indefinitely. We do not need to check here for the
    // `g_isThePenultGameRound` because it is being properly handled on endRoundWatchdog(0).
    if( g_isTheLastGameRound
        || !( roundTimeMinutes > 0.1 ) )
    {
        roundTimeMinutes = 9.0;
    }
    else
    {
        roundTimeMinutes *= 3.0;
    }

    cacheCvarsValues();
    set_task( roundTimeMinutes * 60, "map_restoreEndGameCvars", TASKID_PREVENT_INFITY_GAME );
}

/**
 * This is a fail safe to not allow map changes if must there be a map voting and it was not
 * finished/performed yet.
 */
stock try_to_process_last_round( bool:isFragLimitEnd = false )
{
    LOGGER( 128, "I AM ENTERING ON try_to_process_last_round(0)" )
    new bool:allowMapChange;

    if( g_voteStatus & IS_VOTE_OVER )
    {
        allowMapChange = true;
    }
    else
    {
        if( get_pcvar_num( cvar_endOfMapVote ) )
        {
            allowMapChange = false;
        }
        else
        {
            allowMapChange = true;
        }
    }

    if( allowMapChange )
    {
        process_last_round( g_isTheLastGameRound || isFragLimitEnd );
    }
}

/**
 * To perform the switch between the straight intermission_processing(0) and the last_round_countdown(0).
 *
 * This is used to be called from the computeVotes(0) end voting function, there to call process_last_round(2)
 * with the variable `g_isToChangeMapOnVotingEnd` properly set.
 */
stock process_last_round( bool:isToImmediatelyChangeLevel, bool:isCountDownAllowed = true )
{
    LOGGER( 128, "I AM ENTERING ON process_last_round(2) isToImmediatelyChangeLevel: %d", isToImmediatelyChangeLevel )

    // While the `IS_DISABLED_VOTEMAP_EXIT` bit flag is set, we cannot allow any decisions
    if( g_voteMapStatus & IS_DISABLED_VOTEMAP_EXIT )
    {
        // When this is called, there is not anyone else trying to show action menu, therefore
        // invoke it before returning.
        openTheVoteMapActionMenu();

        LOGGER( 1, "    ( process_last_round ) Just returning/blocking, g_voteMapStatus: %d", g_voteMapStatus )
        return;
    }

    if( isToImmediatelyChangeLevel )
    {
        if( isCountDownAllowed
            && get_pcvar_num( cvar_isEndMapCountdown ) & IS_MAP_MAPCHANGE_COUNTDOWN )
        {
            if( !task_exists( TASKID_PROCESS_LAST_ROUND_COUNT ) )
            {
                new nextMapName[ MAX_MAPNAME_LENGHT ];
                new totalTime = 6;

                g_lastRoundCountdown = totalTime;
                set_task( 1.0, "last_round_countdown", TASKID_PROCESS_LAST_ROUND_COUNT, _, _, "a", totalTime );

                get_pcvar_string( cvar_amx_nextmap, nextMapName, charsmax( nextMapName ) );
                color_print( 0, "%L...", LANG_PLAYER, "DMAP_MAP_CHANGING_IN2", nextMapName, totalTime );
            }
        }
        else
        {
            intermission_processing( isCountDownAllowed );
        }
    }
    else if( g_isTheLastGameRound
             || g_isThePenultGameRound )
    {
        // To restart the HUD counter to force it to show up, to announce the results.
        new showDelay = 8;

        g_showLastRoundHudCounter = LAST_ROUND_HUD_SHOW_INTERVAL - showDelay;
        set_task( float( showDelay ) + 2, "show_last_round_message", TASKID_SHOW_LAST_ROUND_MESSAGE );
    }
}

stock intermission_processing( bool:isCountDownAllowed = true )
{
    LOGGER( 128, "I AM ENTERING ON intermission_processing(0)" )
    new Float:mp_chattime = isCountDownAllowed ? get_intermission_chattime() : 0.1;

    // Choose how to change the level.
    if( g_isTimeToRestart )
    {
        set_task( mp_chattime, "map_change_stays", TASKID_MAP_CHANGE );
    }
    else
    {
        set_task( mp_chattime, "map_change", TASKID_MAP_CHANGE );
    }

    if( isCountDownAllowed ) show_intermission( mp_chattime );
}

stock Float:get_intermission_chattime()
{
    LOGGER( 128, "I AM ENTERING ON get_intermission_chattime(0)" )
    new Float:mp_chattime = get_pcvar_float( cvar_mp_chattime );

    // Make sure the `mp_chattime` is long enough.
    if( mp_chattime > 12 )
    {
        mp_chattime = 12.0;
    }
    else if( mp_chattime < 2.0 )
    {
        mp_chattime = 2.0;
    }

    return mp_chattime + 1.0;
}

/**
 * Freeze the game and show the scoreboard.
 */
stock show_intermission( Float:mp_chattime )
{
    LOGGER( 128, "I AM ENTERING ON show_intermission(1) mp_chattime: %f", mp_chattime )
    new endGameType = get_pcvar_num( cvar_isEndMapCountdown );

    if( endGameType )
    {
        set_task( mp_chattime - 0.5, "intermission_hold", TASKID_INTERMISSION_HOLD );
        intermission_effects( endGameType, mp_chattime );
    }
    else
    {
        LOGGER( 4, " ( show_intermission ) Do nothing, just change the map." )
        intermission_hold();
    }
}

public intermission_hold()
{
    LOGGER( 128, "I AM ENTERING ON intermission_hold(0)" )

    message_begin( MSG_ALL, SVC_INTERMISSION );
    message_end();
}

stock intermission_effects( endGameType, Float:mp_chattime )
{
    LOGGER( 128, "I AM ENTERING ON intermission_effects(1) endGameType: %d", endGameType )

    if( endGameType & IS_MAP_MAPCHANGE_FREEZE_PLAYERS )
    {
        g_original_sv_maxspeed = get_pcvar_float( cvar_sv_maxspeed );
        tryToSetGameModCvarFloat( cvar_sv_maxspeed, 0.0 );

        LOGGER( 2, "( intermission_effects ) IS CHANGING THE CVAR 'sv_maxspeed' to '%f'.", get_pcvar_float( cvar_sv_maxspeed ) )
    }

    if( cvar_mp_friendlyfire
        && endGameType & IS_MAP_MAPCHANGE_FRIENDLY_FIRE )
    {
        if( ( g_isToRestoreFriendlyFire = get_pcvar_num( cvar_mp_friendlyfire ) == 0 ) )
        {
            tryToSetGameModCvarNum( cvar_mp_friendlyfire, 1 );
        }

        LOGGER( 2, "( intermission_effects ) IS CHANGING THE CVAR 'mp_friendlyfire' to '%d'.", get_pcvar_num( cvar_mp_friendlyfire ) )
    }

    if( endGameType & ( IS_MAP_MAPCHANGE_DROP_WEAPONS | IS_MAP_MAPCHANGE_BUY_GRENADES ) )
    {
        new player_id;
        new playersCount;

        new players[32];
        get_players( players, playersCount, "ah" );

        for( --playersCount; playersCount > -1; playersCount-- )
        {
            player_id = players[ playersCount ];

            if( endGameType & IS_MAP_MAPCHANGE_DROP_WEAPONS )
            {
                strip_user_weapons( player_id );
                give_item( player_id, "weapon_knife" );
            }

            if( endGameType & IS_MAP_MAPCHANGE_BUY_GRENADES )
            {
                give_item( player_id, "weapon_smokegrenade" );
                give_item( player_id, "weapon_flashbang" );
                give_item( player_id, "weapon_hegrenade" );
            }
        }
    }

    client_cmd( 0, "+showscores" );

    // Check also if there is not enough time to play it
    if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_MAPCHANGE )
        && mp_chattime > 3.0 )
    {
        client_cmd( 0, "speak ^"loading environment on to your computer^"" );
    }
}

public last_round_countdown()
{
    LOGGER( 128, "I AM ENTERING ON last_round_countdown(0) g_lastRoundCountdown: %d", g_lastRoundCountdown )
    new real_number = g_lastRoundCountdown - 1;

    if( real_number )
    {
        // visual countdown
        if( !( get_pcvar_num( cvar_hudsHide ) & HUD_CHANGELEVEL_COUNTDOWN ) )
        {
            new nextMapName[ MAX_MAPNAME_LENGHT ];
            get_pcvar_string( cvar_amx_nextmap, nextMapName, charsmax( nextMapName ) );

            set_hudmessage( 255, 10, 10, -1.0, 0.13, 0, 1.0, 0.94, 0.0, 0.0, -1 );
            show_hudmessage( 0, "%L...", LANG_PLAYER, "DMAP_MAP_CHANGING_IN1", nextMapName, real_number );
        }

        // audio countdown
        if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_COUNTDOWN ) )
        {
            new word[ 6 ];
            num_to_word( real_number, word, 5 );

            client_cmd( 0, "spk ^"fvox/%s^"", word );
        }
    }

    // decrement the countdown
    g_lastRoundCountdown--;

    if( g_lastRoundCountdown == 0 )
    {
        intermission_processing();
    }
}

public configure_last_round_HUD()
{
    LOGGER( 128, "I AM ENTERING ON configure_last_round_HUD(0)" )

    if( !( get_pcvar_num( cvar_hudsHide ) & HUD_CHANGELEVEL_ANNOUNCE ) )
    {
        remove_task( TASKID_SHOW_LAST_ROUND_HUD );
        set_task( 7.0, "setup_last_round_HUD", TASKID_SHOW_LAST_ROUND_HUD );
    }

    show_last_round_message();
}

public setup_last_round_HUD()
{
    LOGGER( 128, "I AM ENTERING ON setup_last_round_HUD(0) g_showLastRoundHudCounter: %d", g_showLastRoundHudCounter )

    g_showLastRoundHudCounter = 0;
    set_task( 1.0, "show_last_round_HUD", TASKID_SHOW_LAST_ROUND_HUD, _, _, "b" );
}

public show_last_round_message()
{
    LOGGER( 128, "I AM ENTERING ON show_last_round_message(0)" )

    new nextMapName[ MAX_MAPNAME_LENGHT ];
    get_pcvar_string( cvar_amx_nextmap, nextMapName, charsmax( nextMapName ) );

    if( g_voteStatus & IS_VOTE_OVER )
    {
        if( g_isTheLastGameRound
            && !g_isToChangeMapOnVotingEnd )
        {
            color_print( 0, "%L %L %L",
                    LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED2",
                    LANG_PLAYER, "GAL_CHANGE_NEXTROUND",
                    LANG_PLAYER, "GAL_NEXTMAP2", nextMapName );
        }
        else if( g_isThePenultGameRound )
        {
            color_print( 0, "%L %L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED2", LANG_PLAYER, "GAL_NEXTMAP2", nextMapName );
        }
    }
    else if( g_isTheLastGameRound
             || g_isThePenultGameRound )
    {
        color_print( 0, "%L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED2" );
    }
}

public show_last_round_HUD()
{
    LOGGER( 256, "I AM ENTERING ON show_last_round_HUD(0)" )

    if( ++g_showLastRoundHudCounter % LAST_ROUND_HUD_SHOW_INTERVAL > 7 )
    {
        return;
    }

    // On the Amx Mod X 1.8.2 is not recognizing the player LANG_PLAYER when it is formatted before
    // with formatex(...)
    //
    // formatex( last_round_message, charsmax( last_round_message ), "%L^n%L",
    //         player_id, "GAL_CHANGE_NEXTROUND",  player_id, "GAL_NEXTMAP2", nextMapName );
    // REMOVE_CODE_COLOR_TAGS( last_round_message )
    // show_hudmessage( player_id, last_round_message );
    //
    set_hudmessage( 255, 255, 255, 0.15, 0.15, 0, 0.0, 1.0, 0.1, 0.1, 1 );

    new nextMapName[ MAX_MAPNAME_LENGHT ];
    get_pcvar_string( cvar_amx_nextmap, nextMapName, charsmax( nextMapName ) );

    if( g_voteStatus & IS_VOTE_OVER )
    {
        if( g_isTheLastGameRound
            && !g_isToChangeMapOnVotingEnd )
        {
            show_hudmessage( 0, "%L^n%L", LANG_PLAYER, "GAL_CHANGE_NEXTROUND",  LANG_PLAYER, "GAL_NEXTMAP1", nextMapName );
        }
        else if( g_isTheLastGameRound
                 || g_isThePenultGameRound )
        {
            show_hudmessage( 0, "%L^n%L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED1", LANG_PLAYER, "GAL_NEXTMAP1", nextMapName );
        }
    }
    else if( g_isTheLastGameRound
             || g_isThePenultGameRound )
    {
        show_hudmessage( 0, "%L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED1" );
    }
}

/**
 * Return whether the gaming is on going.
 */
stock is_there_game_commencing()
{
    LOGGER( 128, "I AM ENTERING ON is_there_game_commencing(0)" )
    new players[ 32 ];

    new players_count;
    get_players( players, players_count );

    new CT_count = 0;
    new TR_count = 0;

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
            LOGGER( 1, "    ( is_there_game_commencing ) Returning true." )
            return true;
        }
    }

    LOGGER( 1, "    ( is_there_game_commencing ) Returning false." )
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
    LOGGER( 128, "I AM ENTERING ON round_restart_event(0)" )

    // Enable a new voting, as a new game is starting
    g_voteStatus &= ~IS_VOTE_OVER;
    g_voteStatus &= ~IS_EARLY_VOTE;
    g_voteStatus &= ~IS_VOTE_EXPIRED;

    if( g_isEndGameLimitsChanged
        && is_there_game_commencing()
        && ( ( get_pcvar_num( cvar_mp_timelimit )
               && get_pcvar_num( cvar_serverTimeLimitRestart ) )
             || ( get_pcvar_num( cvar_mp_maxrounds )
                  && get_pcvar_num( cvar_serverMaxroundsRestart ) )
             || ( get_pcvar_num( cvar_mp_winlimit )
                  && get_pcvar_num( cvar_serverWinlimitRestart ) )
             || ( get_pcvar_num( cvar_mp_fraglimit )
                  && get_pcvar_num( cvar_serverFraglimitRestart ) ) ) )
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
    LOGGER( 128, "I AM ENTERING ON game_commencing_event(0)" )

    g_isTimeToResetGame   = true;
    g_isTimeToResetRounds = true;

    cancelVoting( true );
}

/**
 * Reset the round ending, if it is in progress.
 */
stock resetRoundEnding()
{
    LOGGER( 128, "I AM ENTERING ON resetRoundEnding(0)" )

    // Each one of these entries must to be saved on saveRoundEnding(1) and restored at restoreRoundEnding(1).
    g_isTheLastGameRound           = false;
    g_isTimeToRestart              = false;
    g_isThePenultGameRound         = false;
    g_isTheRoundEndWhileVoting     = false;
    g_isToChangeMapOnVotingEnd     = false;
    g_isGameEndingTypeContextSaved = false;

    remove_task( TASKID_SHOW_LAST_ROUND_HUD );
    client_cmd( 0, "-showscores" );
}

stock saveRoundEnding( bool:roundEndStatus[] )
{
    LOGGER( 128, "I AM ENTERING ON saveRoundEnding(1) roundEndStatus: %d, %d, %d, %d", \
            roundEndStatus[ 0 ], roundEndStatus[ 1 ], roundEndStatus[ 2 ], roundEndStatus[ 3 ] )

    roundEndStatus[ 0 ] = g_isTheLastGameRound;
    roundEndStatus[ 1 ] = g_isTimeToRestart;
    roundEndStatus[ 2 ] = g_isThePenultGameRound;
    roundEndStatus[ 3 ] = g_isToChangeMapOnVotingEnd;
    roundEndStatus[ 4 ] = g_isTheRoundEndWhileVoting;
}

stock restoreRoundEnding( bool:roundEndStatus[] )
{
    LOGGER( 128, "I AM ENTERING ON restoreRoundEnding(1) roundEndStatus: %d, %d, %d, %d", \
            roundEndStatus[ 0 ], roundEndStatus[ 1 ], roundEndStatus[ 2 ], roundEndStatus[ 3 ] )

    g_isTheLastGameRound       = roundEndStatus[ 0 ];
    g_isTimeToRestart          = roundEndStatus[ 1 ];
    g_isThePenultGameRound     = roundEndStatus[ 2 ];
    g_isToChangeMapOnVotingEnd = roundEndStatus[ 3 ];
    g_isTheRoundEndWhileVoting = roundEndStatus[ 4 ];
}

/**
 * Try to set the new game limits as specified by the cvars 'gal_srv_..._restart' feature. This
 * macro requires the integer variable 'serverLimiterValue' defined before the use of this macro.
 *
 * @param limiterCvarPointer      the 'gal_srv_..._restart' pointer
 * @param serverCvarPointer       the game cvar pointer as 'cvar_mp_timelimit'.
 * @param limiterOffset           the current game limit as an integer. Example: 'map_getMinutesElapsedInteger(0)'.
 */
#define CALCULATE_NEW_GAME_LIMIT(%1,%2,%3) \
{ \
    serverLimiterValue = get_pcvar_num( %1 ); \
    if( serverLimiterValue ) \
    { \
        new serverCvarValue = get_pcvar_num( %2 ); \
        if( serverCvarValue ) \
        { \
            serverCvarValue = serverCvarValue - %3 + serverLimiterValue - 1; \
            if( serverCvarValue > 0 ) \
            { \
                saveEndGameLimits(); \
                tryToSetGameModCvarNum( %2, serverCvarValue ); \
            } \
        } \
    } \
}

public resetRoundsScores()
{
    LOGGER( 128 + 2, "I AM ENTERING ON resetRoundsScores(0)" )
    LOGGER( 2, "( resetRoundsScores ) TRYING to change the cvar %15s from '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOGGER( 2, "( resetRoundsScores ) TRYING to change the cvar %15s from '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOGGER( 2, "( resetRoundsScores ) TRYING to change the cvar %15s from '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOGGER( 2, "( resetRoundsScores ) TRYING to change the cvar %15s from '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )

    new serverLimiterValue;

    CALCULATE_NEW_GAME_LIMIT( cvar_serverTimeLimitRestart, cvar_mp_timelimit, map_getMinutesElapsedInteger() )
    CALCULATE_NEW_GAME_LIMIT( cvar_serverWinlimitRestart , cvar_mp_winlimit , max( g_totalTerroristsWins, g_totalCtWins ) )
    CALCULATE_NEW_GAME_LIMIT( cvar_serverMaxroundsRestart, cvar_mp_maxrounds, g_totalRoundsPlayed )
    CALCULATE_NEW_GAME_LIMIT( cvar_serverFraglimitRestart, cvar_mp_fraglimit, g_greatestKillerFrags )

    // Reset the plugin internal limiter counters.
    g_totalTerroristsWins = 0;
    g_totalCtWins         = 0;
    g_totalRoundsPlayed   = -1;
    g_greatestKillerFrags = 0;

    LOGGER( 2, "( resetRoundsScores ) CHECKOUT the cvar %-25s is '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOGGER( 2, "( resetRoundsScores ) CHECKOUT the cvar %-25s is '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOGGER( 2, "( resetRoundsScores ) CHECKOUT the cvar %-25s is '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOGGER( 2, "( resetRoundsScores ) CHECKOUT the cvar %-25s is '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )
    LOGGER( 1, "    I AM EXITING ON resetRoundsScores(0)" )
}

stock map_populateList( Array:mapArray = Invalid_Array, mapFilePath[], mapFilePathLength, Trie:fillerMapTrie = Invalid_Trie )
{
    LOGGER( 128, "I AM ENTERING ON map_populateList(4) mapFilePath: %s", mapFilePath )

    // load the array with maps
    new mapCount;

    // If there is a map file to load
    if( mapFilePath[ 0 ] )
    {
        new bool:isMapFolderLoad = equali( mapFilePath, MAP_FOLDER_LOAD_FLAG ) != 0;

        // clear the map array in case we're reusing it
        TRY_TO_APPLY( ArrayClear, mapArray )
        TRY_TO_APPLY( TrieClear, fillerMapTrie )

        if( !isMapFolderLoad
            && !equal( mapFilePath, MAP_CYCLE_LOAD_FLAG ) )
        {
            LOGGER( 4, "" )
            LOGGER( 4, "    map_populateList(...) Loading the PASSED FILE! mapFilePath: %s", mapFilePath )
            mapCount = loadMapFileList( mapArray, mapFilePath, fillerMapTrie );
        }
        else if( isMapFolderLoad )
        {
            LOGGER( 4, "" )
            LOGGER( 4, "    map_populateList(...) Loading the MAP FOLDER! mapFilePath: %s", mapFilePath )
            mapCount = loadMapsFolderDirectory( mapArray, fillerMapTrie );
        }
        else
        {
            get_cvar_string( "mapcyclefile", mapFilePath, mapFilePathLength );

            LOGGER( 4, "" )
            LOGGER( 4, "    map_populateList(...) Loading the MAPCYCLE! mapFilePath: %s", mapFilePath )
            mapCount = loadMapFileList( mapArray, mapFilePath, fillerMapTrie );
        }
    }

    LOGGER( 1, "    I AM EXITING map_populateList(4) mapCount: %d", mapCount )
    return mapCount;
}

stock checkIfThereEnoughMapPopulated( mapCount, mapFileDescriptor )
{
    LOGGER( 128, "I AM ENTERING ON checkIfThereEnoughMapPopulated(2) mapCount: %d", mapCount )

    if( mapCount < 2 )
    {
        new parsedLines;
        new writePosition;

        new readLines    [ MAX_BIG_BOSS_STRING ];
        new loadedMapName[ MAX_MAPNAME_LENGHT ];

        fseek( mapFileDescriptor, SEEK_SET, 0 );

        while( !feof( mapFileDescriptor )
               && parsedLines < 11 )
        {
            parsedLines++;

            fgets( mapFileDescriptor, loadedMapName, charsmax( loadedMapName ) );
            trim( loadedMapName );

            if( writePosition < charsmax( readLines ) )
            {
                writePosition += copy( readLines[ writePosition ], charsmax( readLines ) - writePosition, loadedMapName );
            }
        }

        LOGGER( 1, "( loadMapFileList ) Error %d, Not valid/enough(%d) maps found: %s^n", AMX_ERR_NOTFOUND, mapCount, readLines )
        log_error( AMX_ERR_NOTFOUND, "Not valid/enough(%d) maps found: %s^n", mapCount, readLines );
    }
}

stock loadMapFileList( Array:mapArray, mapFilePath[], Trie:fillerMapTrie )
{
    LOGGER( 128, "I AM ENTERING ON loadMapFileList(3) mapFilePath: %s", mapFilePath )

    new mapCount;
    new mapFileDescriptor = fopen( mapFilePath, "rt" );

    if( mapFileDescriptor )
    {
        // Removing the if's from the loop to improve speed
        if( mapArray
            && fillerMapTrie )
        {
            mapCount = loadMapFileListComplete( mapFileDescriptor, mapArray, fillerMapTrie );
        }
        else if( mapArray )
        {
            mapCount = loadMapFileListArray( mapFileDescriptor, mapArray );
        }
        else // if( fillerMapTrie )
        {
            mapCount = loadMapFileListTrie( mapFileDescriptor, fillerMapTrie );
        }

        checkIfThereEnoughMapPopulated( mapCount, mapFileDescriptor );

        fclose( mapFileDescriptor );
        LOGGER( 4, "" )
    }
    else
    {
        LOGGER( 1, "( loadMapFileList ) Error %d, %L", AMX_ERR_NOTFOUND, LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilePath )
        log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilePath );
    }

    return mapCount;
}

stock loadMapFileListComplete( mapFileDescriptor, Array:mapArray, Trie:fillerMapTrie )
{
    LOGGER( 128, "I AM ENTERING ON loadMapFileListComplete(2) mapFileDescriptor: %d", mapFileDescriptor )

    new mapCount;
    new loadedMapLine[ MAX_MAPNAME_LENGHT ];
    new loadedMapName[ MAX_MAPNAME_LENGHT ];

    while( !feof( mapFileDescriptor ) )
    {
        fgets( mapFileDescriptor, loadedMapLine, charsmax( loadedMapLine ) );
        trim( loadedMapLine );

        if( IS_IT_A_VALID_MAP_LINE( loadedMapLine ) )
        {
            GET_MAP_NAME_LEFT( loadedMapLine, loadedMapName )

            if( IS_MAP_VALID( loadedMapName ) )
            {
                TrieSetCell( fillerMapTrie, loadedMapName, mapCount );
                ArrayPushString( mapArray, loadedMapLine );

                LOGGER( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapLine ) )
                ++mapCount;
            }
        }
    }

    return mapCount;
}

stock loadMapFileListArray( mapFileDescriptor, Array:mapArray )
{
    LOGGER( 128, "I AM ENTERING ON loadMapFileListArray(2) mapFileDescriptor: %d", mapFileDescriptor )

    new mapCount;
    new loadedMapName[ MAX_MAPNAME_LENGHT ];
    new loadedMapLine[ MAX_MAPNAME_LENGHT ];

    while( !feof( mapFileDescriptor ) )
    {
        fgets( mapFileDescriptor, loadedMapLine, charsmax( loadedMapLine ) );
        trim( loadedMapLine );

        if( IS_IT_A_VALID_MAP_LINE( loadedMapLine ) )
        {
            GET_MAP_NAME_LEFT( loadedMapLine, loadedMapName )

            if( IS_MAP_VALID( loadedMapName ) )
            {
                ArrayPushString( mapArray, loadedMapLine );

                LOGGER( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapLine ) )
                ++mapCount;
            }
        }
    }

    return mapCount;
}

stock loadMapFileListTrie( mapFileDescriptor, Trie:fillerMapTrie )
{
    LOGGER( 128, "I AM ENTERING ON loadMapFileListTrie(2) mapFileDescriptor: %d", mapFileDescriptor )

    new mapCount;
    new loadedMapName[ MAX_MAPNAME_LENGHT ];
    new loadedMapLine[ MAX_MAPNAME_LENGHT ];

    while( !feof( mapFileDescriptor ) )
    {
        fgets( mapFileDescriptor, loadedMapLine, charsmax( loadedMapLine ) );
        trim( loadedMapLine );

        if( IS_IT_A_VALID_MAP_LINE( loadedMapLine ) )
        {
            GET_MAP_NAME_LEFT( loadedMapLine, loadedMapName )

            if( IS_MAP_VALID( loadedMapName ) )
            {
                TrieSetCell( fillerMapTrie, loadedMapName, mapCount );

                LOGGER( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapLine ) )
                ++mapCount;
            }
        }
    }

    return mapCount;
}

stock loadMapsFolderDirectory( Array:mapArray, Trie:fillerMapTrie )
{
    LOGGER( 128, "I AM ENTERING ON loadMapsFolderDirectory(2) Array:mapArray: %d", mapArray )

    new mapCount;
    new directoryDescriptor;

    new parentDirectorUnused[ 5 ];
    directoryDescriptor = open_dir( "maps", parentDirectorUnused, charsmax( parentDirectorUnused ) );

    // Removing the if's from the loop to improve speed
    if( directoryDescriptor )
    {
        if( mapArray
            && fillerMapTrie )
        {
            mapCount = loadMapsFolderDirectoryComplete( directoryDescriptor, mapArray, fillerMapTrie );
        }
        else if( mapArray )
        {
            mapCount = loadMapsFolderDirectoryArray( directoryDescriptor, mapArray );
        }
        else // if( fillerMapTrie )
        {
            mapCount = loadMapsFolderDirectoryTrie( directoryDescriptor, fillerMapTrie );
        }

        close_dir( directoryDescriptor );
    }
    else
    {
        // directory not found, wtf?
        LOGGER( 1, "( loadMapsFolderDirectory ) Error %d, %L", AMX_ERR_NOTFOUND, LANG_SERVER, "GAL_MAPS_FOLDERMISSING" )
        log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_MAPS_FOLDERMISSING" );
    }

    return mapCount;
}

stock loadMapsFolderDirectoryComplete( directoryDescriptor, Array:mapArray, Trie:fillerMapTrie )
{
    LOGGER( 128, "I AM ENTERING ON loadMapsFolderDirectoryComplete(3) directoryDescriptor: %d", directoryDescriptor )

    new mapCount;
    new mapNameLength;
    new loadedMapName[ MAX_MAPNAME_LENGHT ];

    while( next_file( directoryDescriptor, loadedMapName, charsmax( loadedMapName ) ) )
    {
        mapNameLength = strlen( loadedMapName );

        if( mapNameLength > 4
            && equali( loadedMapName[ mapNameLength - 4 ], ".bsp", 4 ) )
        {
            loadedMapName[ mapNameLength - 4 ] = '^0';

            if( IS_MAP_VALID( loadedMapName ) )
            {
                TrieSetCell( fillerMapTrie, loadedMapName, mapCount );
                ArrayPushString( mapArray, loadedMapName );

                LOGGER( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapName ) )
                ++mapCount;
            }
        }
    }

    return mapCount;
}

stock loadMapsFolderDirectoryArray( directoryDescriptor, Array:mapArray )
{
    LOGGER( 128, "I AM ENTERING ON loadMapsFolderDirectoryArray(2) directoryDescriptor: %d", directoryDescriptor )

    new mapCount;
    new mapNameLength;
    new loadedMapName[ MAX_MAPNAME_LENGHT ];

    while( next_file( directoryDescriptor, loadedMapName, charsmax( loadedMapName ) ) )
    {
        mapNameLength = strlen( loadedMapName );

        if( mapNameLength > 4
            && equali( loadedMapName[ mapNameLength - 4 ], ".bsp", 4 ) )
        {
            loadedMapName[ mapNameLength - 4 ] = '^0';

            if( IS_MAP_VALID( loadedMapName ) )
            {
                ArrayPushString( mapArray, loadedMapName );

                LOGGER( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapName ) )
                ++mapCount;
            }
        }
    }

    return mapCount;
}

stock loadMapsFolderDirectoryTrie( directoryDescriptor, Trie:fillerMapTrie )
{
    LOGGER( 128, "I AM ENTERING ON loadMapsFolderDirectoryTrie(2) directoryDescriptor: %d", directoryDescriptor )

    new mapCount;
    new mapNameLength;
    new loadedMapName[ MAX_MAPNAME_LENGHT ];

    while( next_file( directoryDescriptor, loadedMapName, charsmax( loadedMapName ) ) )
    {
        mapNameLength = strlen( loadedMapName );

        if( mapNameLength > 4
            && equali( loadedMapName[ mapNameLength - 4 ], ".bsp", 4 ) )
        {
            loadedMapName[ mapNameLength - 4 ] = '^0';

            if( IS_MAP_VALID( loadedMapName ) )
            {
                TrieSetCell( fillerMapTrie, loadedMapName, mapCount );

                LOGGER( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapName ) )
                ++mapCount;
            }
        }
    }

    return mapCount;
}

public loadNominationList()
{
    LOGGER( 128, "I AM ENTERING ON loadNominationList(0)" )

    new nomMapFilePath[ MAX_FILE_PATH_LENGHT ];
    get_pcvar_string( cvar_nomMapFilePath, nomMapFilePath, charsmax( nomMapFilePath ) );

    LOGGER( 4, "( loadNominationList() ) cvar_nomMapFilePath: %s", nomMapFilePath )
    map_populateList( g_nominationLoadedMapsArray, nomMapFilePath, charsmax( nomMapFilePath ), g_nominationLoadedMapsTrie );
}

stock map_loadEmptyCycleList()
{
    LOGGER( 128, "I AM ENTERING ON map_loadEmptyCycleList(0)" )

    new emptyCycleFilePath[ MAX_FILE_PATH_LENGHT ];
    get_pcvar_string( cvar_emptyMapFilePath, emptyCycleFilePath, charsmax( emptyCycleFilePath ) );

    g_emptyCycleMapsNumber = map_populateList( g_emptyCycleMapsArray, emptyCycleFilePath, charsmax( emptyCycleFilePath ) );
    LOGGER( 4, "( map_loadEmptyCycleList ) g_emptyCycleMapsNumber: %d", g_emptyCycleMapsNumber )
}

public map_loadPrefixList()
{
    LOGGER( 128, "I AM ENTERING ON map_loadPrefixList(0)" )

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
                    LOGGER( 1, "AMX_ERR_BOUNDS, %L", LANG_SERVER, "GAL_PREFIXES_TOOMANY", MAX_PREFIX_COUNT, prefixesFilePath )
                    log_error( AMX_ERR_BOUNDS, "%L", LANG_SERVER, "GAL_PREFIXES_TOOMANY", MAX_PREFIX_COUNT, prefixesFilePath );

                    break;
                }
            }
        }
        fclose( prefixesFile );
    }
    else
    {
        LOGGER( 1, "AMX_ERR_NOTFOUND, %L", LANG_SERVER, "GAL_PREFIXES_NOTFOUND", prefixesFilePath )
        log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_PREFIXES_NOTFOUND", prefixesFilePath );
    }
}

/**
 * By default, the Whitelist understand a period as 5-5 being 05:00:00 until 05:59:59, and a period
 * as 5-6 being 05:00:00 until 06:59:59.
 *
 * 0 - To convert 5-5 to 05:00:00 until 05:59:59.
 * 1 - I want to 5-5 to be all day long.
 *
 * To disable this feature, set this cvar to 0
 *
 * When the Whitelist ` gal_whitelist_hourly_set` says [0-0] it means it will allow them from 00:00:00 until 00:59:59
 * When the Whitelist `!gal_whitelist_hourly_set` says [0-0] it means it will block them from 00:00:00 until 23:59:59
 *
 * As we may notice, the current whitelist feature is full featured and the `gal_whitelist_hourly_set` is obsolete.
 * To force the Whitelist to block them from 00:00:00 until 23:59:59, we need to set it as {0-0}.
 *
 * For the `gal_whitelist_block_out` option 0 - Allow all maps outside the Whitelist rule.
 *
 *     To block, we need   to load them.
 *     To allow, we cannot to load them.
 *
 * How do I block a map?
 * If I load the map from the file to the `Trie`, I will block it on that hour and allow all the others loaded.
 *
 * For the `gal_whitelist_block_out` option 1 - Block all maps outside the Whitelist rule.
 *
 *     To block, we cannot to load them.
 *     To allow, we need   to load them.
 *
 * How do I block a map?
 * If I load the map from the file to the `Trie`, I will allow it on that hour and block all the others not loaded.
 *
 * @note the hours parameters `startHour` and `endHour` must to be already normalized by standardizeTheHoursForWhitelist(3).
 */
stock bool:isToLoadNextWhiteListGroupOpen( currentHour, startHour, endHour, bool:isBlackList = false )
{
    LOGGER( 256, "I AM ENTERING ON isToLoadNextWhiteListGroupOpen(4) currentHour: %d", currentHour )
    LOGGER( 256, "( isToLoadNextWhiteListGroupOpen ) startHour: %d, endHour: %d", startHour, endHour )
    new bool:isToLoadTheseMaps;

    // Here handle all the cases when the start hour is equals to the end hour.
    if( startHour == endHour )
    {
        LOGGER( 8, "( isToLoadNextWhiteListGroupOpen ) startHour == endHour: %d", startHour )

        // Manual fix needed to convert 5-5 to 05:00:00 until 05:59:59, instead of all day long.
        if( endHour == currentHour )
        {
            isToLoadTheseMaps = isBlackList;
        }
        else
        {
            isToLoadTheseMaps = !isBlackList;
        }
    }
    else
    {
        isToLoadTheseMaps = isToLoadNextWhiteListEndProcess( currentHour, startHour, endHour, isBlackList );
    }

    LOGGER( 0, "", debugIsToLoadNextWhiteListGroup( currentHour, startHour, endHour, isToLoadTheseMaps ) )
    return isToLoadTheseMaps;
}

stock bool:isToLoadNextWhiteListGroupClose( currentHour, startHour, endHour, bool:isBlackList = false )
{
    LOGGER( 256, "I AM ENTERING ON isToLoadNextWhiteListGroupClose(4) currentHour: %d", currentHour )
    LOGGER( 256, "( isToLoadNextWhiteListGroupClose ) startHour: %d, endHour: %d", startHour, endHour )

    new bool:isToLoadTheseMaps;
    new bool:isDecreased = false;

    if( startHour != endHour )
    {
        isDecreased = true;

        if( endHour == 0 )
        {
            endHour = 23;
        }
        else
        {
            endHour -= 1;
        }
    }

    LOGGER( 256, "( isToLoadNextWhiteListGroupClose ) startHour: %d, endHour: %d", startHour, endHour )

    // Here handle all the cases when the start hour is equals to the end hour.
    if( startHour == endHour )
    {
        LOGGER( 8, "( isToLoadNextWhiteListGroupClose ) startHour == endHour: %d", startHour )

        // Manual set needed to convert 5-5 to always block a map. Now 0-23 is 00:00:00 until 22:59:59,
        // and there is not way to allow a map from 00:00:00 until 23:59:59.
        if( isDecreased
            && endHour == currentHour )
        {
            isToLoadTheseMaps = isBlackList;
        }
        else
        {
            isToLoadTheseMaps = !isBlackList;
        }
    }
    else
    {
        isToLoadTheseMaps = isToLoadNextWhiteListEndProcess( currentHour, startHour, endHour, isBlackList );
    }

    LOGGER( 0, "", debugIsToLoadNextWhiteListGroup( currentHour, startHour, endHour, isToLoadTheseMaps ) )
    return isToLoadTheseMaps;
}

stock bool:isToLoadNextWhiteListEndProcess( currentHour, startHour, endHour, bool:isBlackList )
{
    LOGGER( 256, "I AM ENTERING ON isToLoadNextWhiteListEndProcess(4)" )

    //      5          3
    if( startHour > endHour )
    {
        // 5  > 3
        // 23 > 1
        // 22 > 12
        // 24 > 23
        //
        // On this cases, we to go from one day to another, always. So we need to be able to
        // calculate whether the current hour is between these. Doing ( 24 - startHour - endHour )
        // here, we got how much hours there are between them.
        //
        // On 5-3, the possible value(s) for current hour: 4
        //
        //      4             5
        if( currentHour < startHour
        //         4           3
            && currentHour > endHour )
        {
            LOGGER( 256, "( isToLoadNextWhiteListEndProcess ) 1. Returning: %d", !isBlackList )
            return !isBlackList;
        }
        //               6           5
        else // if( currentHour > startHour )
        {
            LOGGER( 256, "( isToLoadNextWhiteListEndProcess ) 2. Returning: %d", isBlackList )
            return isBlackList;
        }
    }
    //             3          5
    else // if( startHour < endHour )
    {
        // 3  < 5
        // 1  < 23
        // 12 < 22
        // 23 < 24
        //
        // On this cases, we to go from the same day to the same day, always. So we need to be able
        // to calculate whether the current hour is between these.
        //
        // On 3-5, the possible value(s) for current hour: 6, 7, ..., 1, 2
        //
        //      6            5
        if( currentHour > endHour
        //          2           3
            || currentHour < startHour )
        {
            LOGGER( 256, "( isToLoadNextWhiteListEndProcess ) 3. Returning: %d", !isBlackList )
            return !isBlackList;
        }
        //              4            3
        else // if( currentHour > startHour )
        {
            LOGGER( 256, "( isToLoadNextWhiteListEndProcess ) 4. Returning: %d", isBlackList )
            return isBlackList;
        }
    }

    LOGGER( 256, "    ( isToLoadNextWhiteListEndProcess ) Returning false." )
    return false;
}

stock debugIsToLoadNextWhiteListGroup( currentHour, startHour, endHour, isToLoadTheseMaps )
{
    LOGGER( 8, "( debugIsToLoadNextWhiteListGroup ) %2d >  %2d     : %2d", startHour, endHour, startHour > endHour )
    LOGGER( 8, "( debugIsToLoadNextWhiteListGroup ) %2d >= %2d > %2d: %2d", \
            startHour, currentHour, endHour, \
            startHour >= currentHour && currentHour > endHour )

    LOGGER( 8, "( debugIsToLoadNextWhiteListGroup ) %2d <  %2d     : %2d", startHour, endHour, startHour < endHour )
    LOGGER( 8, "( debugIsToLoadNextWhiteListGroup ) %2d <= %2d < %2d: %2d, isToLoadTheseMaps: %d", \
            startHour, currentHour, endHour, \
            startHour <= currentHour && currentHour < endHour, isToLoadTheseMaps )

    return 0;
}

/**
 * Standardize the hours from 0 until 23.
 */
stock standardizeTheHoursForWhitelist( &currentHour, &startHour, &endHour )
{
    LOGGER( 256, "I AM ENTERING ON standardizeTheHoursForWhitelist(3) currentHour: %d, startHour: %d, endHour: %d", \
            currentHour, startHour, endHour )

    if( startHour > 23
        || startHour < 0 )
    {
        LOGGER( 8, "( standardizeTheHoursForWhitelist ) startHour: %d, will became 0.", startHour )
        startHour = 0;
    }

    if( endHour > 23
        || endHour < 0 )
    {
        LOGGER( 8, "( standardizeTheHoursForWhitelist ) endHour: %d, will became 0.", endHour )
        endHour = 0;
    }

    if( currentHour > 23
        || currentHour < 0 )
    {
        LOGGER( 8, "( standardizeTheHoursForWhitelist ) currentHour: %d, will became 0.", currentHour )
        currentHour = 0;
    }
}

/**
 * Now [1-2] specifies the time you want to block them; from 1:00 (am) until 2:59 (am).
 *
 * This changes:
 * From 1:00 until 2:59
 * to
 * From 3:00 until 0:59
 */
//                                     1         2
//                                     3         0
stock bool:convertWhitelistToBlacklist( &startHour, &endHour )
{
    LOGGER( 256, "I AM ENTERING ON convertWhitelistToBlacklist(2)" )
    new backup;

    backup    = ( endHour   + 1 > 23 ? 0  : endHour   + 1 );
    endHour   = ( startHour - 1 < 0  ? 23 : startHour - 1 );
    startHour = backup;

    LOGGER( 256, "( convertWhitelistToBlacklist ) startHour: %d, endHour: %d", startHour, endHour )

    if( startHour == 0
        && endHour == 23 )
    {
        startHour = 0;
        endHour   = 0;

        LOGGER( 256, "    ( convertWhitelistToBlacklist ) Returning true." )
        return true;
    }

    LOGGER( 256, "    ( convertWhitelistToBlacklist ) Returning false." )
    return false;
}

/**
 * This must to be called only when is possible that the Whitelist feature is not loaded by its
 * first time. For example, when the cvar 'cvar_isWhiteListNomBlock' is enabled after the server
 * start.
 *
 * @note It must to be protected by an 'IS_WHITELIST_ENABLED()' evaluation.
 */
stock tryToLoadTheWhiteListFeature()
{
    if( get_pcvar_num( cvar_isWhiteListBlockOut ) )
    {
        // Loads all the allowed maps to be added as nominations or as voting map fillers.
        if( !g_whitelistTrie )
        {
            loadTheWhiteListFeature();
        }
    }
    else
    {
        // Loads all the blocked maps to be added as nominations or as voting map fillers.
        if( !g_blacklistTrie )
        {
            loadTheWhiteListFeature();
        }
    }

    if( IS_TO_HOURLY_LOAD_THE_WHITELIST() )
    {
        computeNextWhiteListLoadTime( floatround( get_gametime(), floatround_ceil ), false );
    }
}

/**
 * This must to be called always is needed to update the Whitelist loaded maps, or when it is the
 * first time the Whitelist feature is loaded.
 *
 * @note It must to be protected by an 'IS_WHITELIST_ENABLED()' evaluation.
 */
stock loadTheWhiteListFeature()
{
    LOGGER( 128, "I AM ENTERING ON loadTheWhiteListFeature(0)" )

    new currentHour;
    new currentHourString[ 8 ];

    get_time( "%H", currentHourString, charsmax( currentHourString ) );
    currentHour = str_to_num( currentHourString );

    // When the `cvar_whitelistType` is set to true, the `cvar_isWhiteListBlockOut` must to loas as a Whitelist.
    new bool:whitelistType = get_pcvar_num( cvar_whitelistType ) != 0;

    if( get_pcvar_num( cvar_isWhiteListBlockOut ) )
    {
        loadWhiteListFile( currentHour, g_whitelistTrie, g_whitelistFileArray, !whitelistType, g_whitelistArray );
    }
    else if( whitelistType )
    {
        loadWhiteListFile( currentHour, g_blacklistTrie, g_whitelistFileArray, true );
    }
    else
    {
        loadWhiteListFile( currentHour, g_blacklistTrie, g_whitelistFileArray, false );
    }
}

/**
 * The parameters `listTrie` and `listArray` must to be passed by as reference because they are created
 * internally by this function on setupLoadWhiteListParams(3).
 */
stock loadWhiteListFile( currentHour, &Trie:listTrie, Array:whitelistFileArray, bool:isBlackList, &Array:listArray = Invalid_Array )
{
    LOGGER( 128, "I AM ENTERING ON loadWhiteListFile(5) currentHour: %d, listTrie: %d", currentHour, listTrie )

    if( whitelistFileArray )
    {
        new startHour;
        new endHour;
        new linesCount;

        new bool:isToLoadTheseMaps;
        new bool:isWhiteListBlockOut;

        new mapName        [ MAX_MAPNAME_LENGHT ];
        new currentLine    [ MAX_MAPNAME_LENGHT ];
        new startHourString[ MAX_MAPNAME_LENGHT / 2 ];
        new endHourString  [ MAX_MAPNAME_LENGHT / 2 ];

        linesCount          = ArraySize( whitelistFileArray );
        isWhiteListBlockOut = get_pcvar_num( cvar_isWhiteListBlockOut ) != 0;

        setupLoadWhiteListParams( isWhiteListBlockOut, listTrie, listArray );

        for( new lineIndex = 0; lineIndex < linesCount; lineIndex++ )
        {
            ArrayGetString( whitelistFileArray, lineIndex, currentLine, charsmax( currentLine ) );

            if( whiteListHourlySet( '[', currentLine, startHourString, endHourString, isBlackList, currentHour, startHour, endHour ) )
            {
                isToLoadTheseMaps = isToLoadNextWhiteListGroupOpen( currentHour, startHour, endHour, isBlackList );
                continue;
            }
            else if( whiteListHourlySet( '{', currentLine, startHourString, endHourString, isBlackList, currentHour, startHour, endHour ) )
            {
                isToLoadTheseMaps = isToLoadNextWhiteListGroupClose( currentHour, startHour, endHour, isBlackList );
                continue;
            }
            else if( !isToLoadTheseMaps )
            {
                continue;
            }
            else
            {
                LOGGER( 8, "( loadWhiteListFile ) Trying to add: %s", currentLine )
                GET_MAP_NAME_LEFT( currentLine, mapName )

                if( IS_MAP_VALID( mapName ) )
                {
                    LOGGER( 8, "( loadWhiteListFile ) %d. OK! ", listTrie )
                    TrieSetCell( listTrie, mapName, lineIndex );

                    if( listArray )
                    {
                        ArrayPushString( listArray, currentLine );
                    }
                }
            }
        }
    }

    LOGGER( 1, "    I AM EXITING loadWhiteListFile(5) listArray: %d, whitelistFileArray: %d", listArray, whitelistFileArray )
}

stock whiteListHourlySet( trigger, currentLine[], startHourString[], endHourString[], &isBlackList, &currentHour, &startHour, &endHour )
{
    LOGGER( 256, "I AM ENTERING ON whiteListHourlySet(4) trigger: %c", trigger )

    if( currentLine[ 0 ] == trigger
        && isdigit( currentLine[ 1 ] ) )
    {
        // remove line delimiters [ and ]
        replace_all( currentLine, MAX_MAPNAME_LENGHT - 1, "[", "" );
        replace_all( currentLine, MAX_MAPNAME_LENGHT - 1, "{", "" );
        replace_all( currentLine, MAX_MAPNAME_LENGHT - 1, "}", "" );
        replace_all( currentLine, MAX_MAPNAME_LENGHT - 1, "]", "" );

        LOGGER( 8, "( whiteListHourlySet ) " )
        LOGGER( 8, "( whiteListHourlySet ) If we are %s these hours, we must load these maps:", ( isBlackList? "between" : "outside" ) )
        LOGGER( 8, "( whiteListHourlySet ) currentLine: %s (currentHour: %d)", currentLine, currentHour )

        // broke the current line
        STR_TOKEN( currentLine ,
                startHourString, MAX_MAPNAME_LENGHT / 2,
                endHourString  , MAX_MAPNAME_LENGHT / 2, '-', 0 );

        startHour = str_to_num( startHourString );
        endHour   = str_to_num( endHourString );

        standardizeTheHoursForWhitelist( currentHour, startHour, endHour );
        LOGGER( 256, "    ( whiteListHourlySet ) Returning true for: %s", currentLine )
        return true;
    }

    LOGGER( 256, "    ( whiteListHourlySet ) Returning false for: %s", currentLine )
    return false;
}

stock setupLoadWhiteListParams( bool:isWhiteListBlockOut, &Trie:listTrie, &Array:listArray )
{
    LOGGER( 128, "I AM ENTERING ON setupLoadWhiteListParams(3) isWhiteListBlockOut: %d", isWhiteListBlockOut )
    LOGGER( 128, "( setupLoadWhiteListParams ) listTrie: %d, listArray: %d", listTrie, listArray )

    if( listTrie )
    {
        TrieClear( listTrie );
    }
    else
    {
        listTrie = TrieCreate();
    }

    if( isWhiteListBlockOut )
    {
        // clear the map array in case we're reusing it
        if( listArray )
        {
            ArrayClear( listArray );
        }
        else
        {
            listArray = ArrayCreate( MAX_MAPNAME_LENGHT );
        }
    }
}

stock loadMapGroupsFeature()
{
    LOGGER( 128, "I AM ENTERING ON loadMapGroupsFeature(0)" )
    new realPlayersNumber = get_real_players_number();

    if( realPlayersNumber > 0 )
    {
        new voteMininumPlayers = get_pcvar_num( cvar_voteMinPlayers );
        new voteMiddlePlayers  = get_pcvar_num( cvar_voteMidPlayers );

        if( realPlayersNumber < voteMininumPlayers )
        {
            return fillersFilePaths_MininumPlayers;
        }
        else if( voteMiddlePlayers > voteMininumPlayers
                 && realPlayersNumber < voteMiddlePlayers )
        {
            return fillersFilePaths_MiddlePlayers;
        }
    }

    return fillersFilePaths_NormalPlayers;
}

stock processLoadedMapsFile( fillersFilePathType:fillersFilePathEnum, blockedMapsBuffer[], &announcementShowedTimes )
{
    LOGGER( 128, "I AM ENTERING ON processLoadedMapsFile(3) fillersFilePathEnum: %d, announcementShowedTimes: %d", \
            fillersFilePathEnum, announcementShowedTimes )

    new groupCount;
    new choiceIndex;
    new allowedFilersCount;
    new maxMapsPerGroupToUse;

    new Array:fillerMapsArray;
    new Array:fillerMapGroupsArrays;
    new Array:maxMapsPerGroupToUseArray;
    new mapName[ MAX_MAPNAME_LENGHT ];
    new mapInfo[ MAX_MAPNAME_LENGHT ];

    switch( fillersFilePathEnum )
    {
        case fillersFilePaths_MininumPlayers:
        {
            fillerMapGroupsArrays     = g_minPlayerFillerMapGroupArrays;
            maxMapsPerGroupToUseArray = g_minMaxMapsPerGroupToUseArray;
        }
        case fillersFilePaths_MiddlePlayers:
        {
            fillerMapGroupsArrays     = g_midPlayerFillerMapGroupArrays;
            maxMapsPerGroupToUseArray = g_midMaxMapsPerGroupToUseArray;
        }
        default: // case fillersFilePaths_NormalPlayers:
        {
            fillerMapGroupsArrays     = g_norPlayerFillerMapGroupArrays;
            maxMapsPerGroupToUseArray = g_norMaxMapsPerGroupToUseArray;
        }
    }

    new mapIndex;
    new filersMapCount;
    new unsuccessfulCount;
    new currentBlockerStrategy;

    new Array:randomGenaratorHolder = ArrayCreate();

    new bool:isWhitelistEnabled   = IS_WHITELIST_ENABLED();
    new bool:useEqualiCurrentMap  = true;
    new bool:useWhitelistOutBlock = isWhitelistEnabled;
    new bool:useIsPrefixInMenu    = get_pcvar_num( cvar_voteUniquePrefixes ) != 0;
    new bool:useMapIsTooRecent    = ( g_recentMapCount
                                      && get_pcvar_num( cvar_recentMapsBannedNumber ) != 0 );
    new bool:isWhiteListOutBlock  = ( isWhitelistEnabled
                                      && get_pcvar_num( cvar_isWhiteListBlockOut ) != 0 );

    /**
     * This variable is to avoid double blocking which lead to the algorithm corruption and errors.
     */
    new Trie:blockedFillersMapTrie;

    if( useWhitelistOutBlock )
    {
        blockedFillersMapTrie = TrieCreate();
    }

    groupCount = ArraySize( fillerMapGroupsArrays );
    LOGGER( 4, "( processLoadedMapsFile ) groupCount: %d, fillerMapGroupsArrays: %d", groupCount, fillerMapGroupsArrays )

    // The Whitelist Out Block feature disables The Map Groups Feature.
    if( isWhiteListOutBlock )
    {
        LOGGER( 4, "( processLoadedMapsFile ) Disabling the MapsGroups Feature due isWhiteListOutBlock" )

    #if AMXX_VERSION_NUM < 183
        groupCount = ArraySize( fillerMapGroupsArrays );

        while( groupCount > 1 )
        {
            groupCount--;

            ArrayDeleteItem( maxMapsPerGroupToUseArray, groupCount );
            fillerMapsArray = ArrayGetCell( fillerMapGroupsArrays, groupCount );

            ArrayDeleteItem( fillerMapGroupsArrays, groupCount );
            TRY_TO_APPLY( ArrayDestroy, fillerMapsArray )
        }
    #else
        groupCount = 1;
        ArrayResize( fillerMapGroupsArrays    , groupCount );
        ArrayResize( maxMapsPerGroupToUseArray, groupCount );
    #endif
    }

    new maxVotingChoices = MAX_VOTING_CHOICES();

    // fill remaining slots with random maps from each filler file, as much as possible
    for( new groupIndex = 0; groupIndex < groupCount; ++groupIndex )
    {
        if( isWhitelistEnabled )
        {
            // Not loaded?
            tryToLoadTheWhiteListFeature();

            // The Whitelist out block feature, disables The Map Groups Feature.
            if( isWhiteListOutBlock )
            {
                LOGGER( 0, "", print_is_white_list_out_block() )

                fillerMapsArray      = g_whitelistArray;
                useWhitelistOutBlock = false;
            }
            else
            {
                fillerMapsArray = ArrayGetCell( fillerMapGroupsArrays, groupIndex );
            }
        }
        else
        {
            fillerMapsArray = ArrayGetCell( fillerMapGroupsArrays, groupIndex );
        }

        filersMapCount = ArraySize( fillerMapsArray );

        LOGGER( 8, "" )
        LOGGER( 8, "[%i] groupCount:%i, filersMapCount: %i,  g_totalVoteOptions: %i, maxVotingChoices: %i", \
                groupIndex, groupCount, filersMapCount, g_totalVoteOptions, maxVotingChoices )

        if( filersMapCount
            && g_totalVoteOptions < maxVotingChoices )
        {
            maxMapsPerGroupToUse = ArrayGetCell( maxMapsPerGroupToUseArray, groupIndex );
            allowedFilersCount   = min( min(
                                             maxMapsPerGroupToUse, maxVotingChoices - g_totalVoteOptions
                                           ), filersMapCount );

            LOGGER( 8, "[%i] allowedFilersCount: %i   maxMapsPerGroupToUse[%i]: %i", groupIndex, \
                    allowedFilersCount, groupIndex, maxMapsPerGroupToUse )
            LOGGER( 8, "" )
            LOGGER( 8, "" )

            for( choiceIndex = 0; choiceIndex < allowedFilersCount; ++choiceIndex )
            {
                unsuccessfulCount      = 0;
                currentBlockerStrategy = -1;

                keepSearching:

                mapIndex = random_num( 0, filersMapCount - 1 );
                GET_MAP_NAME( fillerMapsArray, mapIndex, mapName )

                LOGGER( 8, "( in  ) [%i] choiceIndex: %i, mapIndex: %i, mapName: %s, unsuccessfulCount: %i, g_totalVoteOptions: %i", \
                        groupIndex, choiceIndex, mapIndex, mapName, unsuccessfulCount, g_totalVoteOptions )

                while( map_isInMenu( mapName )
                       || (
                            useEqualiCurrentMap
                            && equali( g_currentMapName, mapName )
                          )
                       || (
                            useWhitelistOutBlock
                            && TrieKeyExists( blockedFillersMapTrie, mapName )
                          )
                       || (
                            useMapIsTooRecent
                            && map_isTooRecent( mapName )
                          )
                       || (
                            useIsPrefixInMenu
                            && isPrefixInMenu( mapName )
                          )
                     )
                {
                    // Some spacing
                    LOGGER( 8, "" )
                    LOGGER( 0, "", debug_vote_map_selection( choiceIndex, mapName, useWhitelistOutBlock, \
                            isWhiteListOutBlock, useEqualiCurrentMap, unsuccessfulCount, currentBlockerStrategy, \
                            useIsPrefixInMenu, useMapIsTooRecent, blockedFillersMapTrie ) )

                    // Heuristics to try to approximate the maximum menu map numbers, when there are just
                    // a few maps to fill the voting menu and there are a lot of filler restrictions.
                    if( unsuccessfulCount >= filersMapCount )
                    {
                        switch( ++currentBlockerStrategy )
                        {
                            case 0:
                            {
                                useIsPrefixInMenu = false;
                            }
                            case 1:
                            {
                                useMapIsTooRecent = false;
                            }
                            case 2:
                            {
                                if( isWhiteListOutBlock )
                                {
                                    LOGGER( 8, "" )
                                    LOGGER( 8, "" )
                                    LOGGER( 8, "WARNING! This BlockerStrategy case is not used by the isWhiteListOutBlock." )
                                    LOGGER( 8, "" )
                                    LOGGER( 8, "" )

                                    ++currentBlockerStrategy;
                                    goto isWhiteListOutBlockExitCase;
                                }

                                useWhitelistOutBlock = false;
                            }
                            case 3:
                            {
                                isWhiteListOutBlockExitCase:
                                useEqualiCurrentMap = false;
                            }
                            default:
                            {
                                LOGGER( 8, "" )
                                LOGGER( 8, "" )
                                LOGGER( 8, "WARNING! unsuccessfulCount: %i, filersMapCount: %i", unsuccessfulCount, filersMapCount )
                                LOGGER( 8, "" )
                                LOGGER( 8, "" )

                                goto exitSearch;
                            }
                        }

                        unsuccessfulCount = 0;
                    }

                    ++mapIndex;

                    if( mapIndex >= filersMapCount )
                    {
                        mapIndex = 0;
                    }

                    unsuccessfulCount++;
                    GET_MAP_NAME( fillerMapsArray, mapIndex, mapName )

                    LOGGER( 0, "", debug_vote_map_selection( choiceIndex, mapName, useWhitelistOutBlock, \
                            isWhiteListOutBlock, useEqualiCurrentMap, unsuccessfulCount, currentBlockerStrategy, \
                            useIsPrefixInMenu, useMapIsTooRecent, blockedFillersMapTrie ) )
                }

                if( isWhitelistEnabled
                    && !isWhiteListOutBlock
                    && TrieKeyExists( g_blacklistTrie, mapName ) )
                {
                    LOGGER( 8, "    Trying to block: %s, by the whitelist map setting...", mapName )

                    if( !TrieKeyExists( blockedFillersMapTrie, mapName ) )
                    {
                        LOGGER( 8, "    BLOCKED!" )

                        TrieSetCell( blockedFillersMapTrie, mapName, 0 );
                        announceVoteBlockedMap( mapName, blockedMapsBuffer, "GAL_FILLER_BLOCKED", announcementShowedTimes );
                    }

                    goto keepSearching;
                }

                GET_MAP_INFO( fillerMapsArray, mapIndex, mapInfo )
                addMapToTheVotingMenu( mapName, mapInfo );

                LOGGER( 8, "" )
                LOGGER( 8, "( out ) [%i] choiceIndex: %i, mapIndex: %i, mapName: %s, unsuccessfulCount: %i, g_totalVoteOptions: %i", \
                        groupIndex, choiceIndex, mapIndex, mapName, unsuccessfulCount, g_totalVoteOptions )
                LOGGER( 8, "" )
                LOGGER( 8, "" )
            }

            if( g_dummy_value )
            {
                exitSearch:

                LOGGER( 8, "" )
                LOGGER( 8, "" )
                LOGGER( 8, "WARNING! There aren't enough maps in this filler file to continue adding anymore." )
                LOGGER( 8, "" )
                LOGGER( 8, "" )
            }
        }
    }

    TRY_TO_APPLY( TrieDestroy, blockedFillersMapTrie )
    TRY_TO_APPLY( ArrayDestroy, randomGenaratorHolder )
}

stock print_is_white_list_out_block()
{
    LOGGER( 128, "I AM ENTERING ON print_is_white_list_out_block(2)" )

    new mapName[ MAX_MAPNAME_LENGHT ];
    new filersMapCount = ArraySize( g_whitelistArray );

    LOGGER( 8, "" )
    LOGGER( 8, "( print_is_white_list_out_block|FOR in)" )

    for( new currentMapIndex = 0; currentMapIndex < filersMapCount; ++currentMapIndex )
    {
        ArrayGetString( g_whitelistArray, currentMapIndex, mapName, charsmax( mapName ) );
        LOGGER( 8, "( print_is_white_list_out_block|FOR ) g_whitelistArray[%d]: %s", currentMapIndex, mapName )
    }

    LOGGER( 8, "( print_is_white_list_out_block|FOR out)" )

    return 0;
}

stock debug_vote_map_selection( choiceIndex, mapName[], useWhitelistOutBlock, isWhiteListOutBlock,
                                useEqualiCurrentMap, unsuccessfulCount, currentBlockerStrategy,
                                useIsPrefixInMenu, useMapIsTooRecent, Trie:blockedFillersMapTrie )
{
    LOGGER( 256, "I AM ENTERING ON debug_vote_map_selection(10) choiceIndex: %d", choiceIndex )
    new type[5];

    static isIncrementTime = 0;
    static currentMapIndex = 0;
    static lastchoiceIndex = 0;

    // Reset the currentMapIndex map counting after a successful map addition.
    if( choiceIndex != lastchoiceIndex )
    {
        currentMapIndex = 0;
        lastchoiceIndex = choiceIndex;
    }

    // Alternate between `in` and `out` to get a debugging loop entrance and exit behavior.
    if( isIncrementTime++ % 2 == 0 )
    {
        currentMapIndex++;
        copy( type, charsmax( type ), "in" );
    }
    else
    {
        copy( type, charsmax( type ), "out" );
    }

    LOGGER( 8, "%d. ( debug_vote_map_selection|while_%s ) mapName: %s, map_isInMenu: %d, is_theCurrentMap: %d, \
            map_isTooRecent: %d", currentMapIndex, type, mapName, map_isInMenu( mapName ), \
            equali( g_currentMapName, mapName ), ( g_recentMapCount? map_isTooRecent( mapName ) : 0 ) )

    LOGGER( 8, "          isPrefixInMenu: %d, TrieKeyExists( blockedFillersMapTrie ): %d, \
            !TrieKeyExists( g_whitelistTrie ): %d", isPrefixInMenu( mapName ), \
            ( useWhitelistOutBlock?  TrieKeyExists( blockedFillersMapTrie, mapName ) : false ), \
            ( isWhiteListOutBlock ? !TrieKeyExists( g_whitelistTrie      , mapName ) : false ) )

    LOGGER( 8, "          useMapIsTooRecent: %d, useIsPrefixInMenu: %d, useEqualiCurrentMap: %d", \
            useMapIsTooRecent, useIsPrefixInMenu, useEqualiCurrentMap )

    LOGGER( 8, "          currentBlockerStrategy: %d, unsuccessfulCount:%d, useWhitelistOutBlock: %d", \
            currentBlockerStrategy, unsuccessfulCount, useWhitelistOutBlock )

    return 0;
}

stock vote_addFillers( blockedMapsBuffer[], &announcementShowedTimes = 0 )
{
    LOGGER( 128, "I AM ENTERING ON vote_addFillers(2) announcementShowedTimes: %d", announcementShowedTimes )

    new maxVotingChoices = MAX_VOTING_CHOICES();

    if( g_totalVoteOptions < maxVotingChoices )
    {
        new fillersFilePathEnum = loadMapGroupsFeature();
        processLoadedMapsFile( fillersFilePathType:fillersFilePathEnum, blockedMapsBuffer, announcementShowedTimes );
    }
    else
    {
        LOGGER( 8, " ( vote_addFillers ) maxVotingChoices: %d", maxVotingChoices )
        LOGGER( 8, " ( vote_addFillers ) g_maxVotingChoices: %d", g_maxVotingChoices )
        LOGGER( 8, " ( vote_addFillers ) g_totalVoteOptions: %d", g_totalVoteOptions )
        LOGGER( 1, "    ( vote_addFillers ) Just Returning/blocking, the voting list is filled." )
    }
}

stock vote_addNominations( blockedMapsBuffer[], &announcementShowedTimes = 0 )
{
    LOGGER( 128, "I AM ENTERING ON vote_addNominations(2) announcementShowedTimes: %d", announcementShowedTimes )
    new bool:isFillersMapUsingMinplayers;

    // Try to add the nominations, if there are nominated maps.
    new nominatedMapsCount = ArraySize( g_nominatedMapsArray );

    if( nominatedMapsCount )
    {
        new Trie:whitelistMapTrie;

        new mapIndex;
        new mapName[ MAX_MAPNAME_LENGHT ];
        new mapInfo[ MAX_MAPNAME_LENGHT ];

        // Note: The Map Groups Feature will not work with the Minimum Players Feature when adding
        // nominations, as we do not load the Map Groups Feature. But the Map Groups Feature will
        // work fine with the Minimum Players Feature when filling the vote menu.
        if( IS_NOMINATION_MININUM_PLAYERS_CONTROL_ENABLED() )
        {
            new mapFilerFilePath[ MAX_FILE_PATH_LENGHT ];
            get_pcvar_string( cvar_voteMinPlayersMapFilePath, mapFilerFilePath, charsmax( mapFilerFilePath ) );

            // '*' is invalid blacklist for voting, because it would block all server maps.
            if( equal( mapFilerFilePath, MAP_FOLDER_LOAD_FLAG ) )
            {
                LOGGER( 1, "AMX_ERR_NOTFOUND, %L", LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilerFilePath )
                log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilerFilePath );
            }
            else
            {
                whitelistMapTrie            = TrieCreate();
                isFillersMapUsingMinplayers = true;

                // This call is only to load the 'whitelistMapTrie'
                map_populateList( _, mapFilerFilePath, charsmax( mapFilerFilePath ), whitelistMapTrie );
            }
        }

        new maxVotingChoices = MAX_VOTING_CHOICES();

        // set how many total nominations we can use in this vote
        new maxNominations    = get_pcvar_num( cvar_nomQtyUsed );
        new slotsAvailable    = maxVotingChoices - g_totalVoteOptions;
        new voteNominationMax = ( maxNominations ) ? min( maxNominations, slotsAvailable ) : slotsAvailable;

        // print the players nominations for debug
        LOGGER( 4, "( vote_addNominations ) nominatedMapsCount", nominatedMapsCount, show_all_players_nominations() )

        // Add as many nominations as we can by FIFO
        for( new nominationIndex = 0; nominationIndex < nominatedMapsCount; ++nominationIndex )
        {
            mapIndex = ArrayGetCell( g_nominatedMapsArray, nominationIndex );

            if( mapIndex > -1 )
            {
                GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, mapName )
                LOGGER( 4, "( vote_addNominations ) g_nominationLoadedMapsArray.mapIndex: %d, mapName: %s", mapIndex, mapName )

                if( isFillersMapUsingMinplayers
                    && !TrieKeyExists( whitelistMapTrie, mapName ) )
                {
                    LOGGER( 8, "    The map: %s, was blocked by the minimum players map setting.", mapName )
                    announceVoteBlockedMap( mapName, blockedMapsBuffer, "GAL_FILLER_BLOCKED", announcementShowedTimes );

                    continue;
                }

                GET_MAP_INFO( g_nominationLoadedMapsArray, mapIndex, mapInfo )
                addMapToTheVotingMenu( mapName, mapInfo );

                if( g_totalVoteOptions == voteNominationMax )
                {
                    break;
                }
            }

        } // end nomination's players looking

        TRY_TO_APPLY( TrieDestroy, whitelistMapTrie )

    } // end if nominations

    LOGGER( 4, "" )
    LOGGER( 4, "" )
}

stock show_all_players_nominations()
{
    LOGGER( 128, "I AM ENTERING ON show_all_players_nominations(0)" )

    new mapIndex;
    new nominator_id;

    new mapName   [ MAX_MAPNAME_LENGHT ];
    new playerName[ MAX_PLAYER_NAME_LENGHT ];

    // set how many total nominations each player is allowed
    new maxPlayerNominations = min( get_pcvar_num( cvar_nomPlayerAllowance ), MAX_OPTIONS_IN_VOTE );

    for( new nominationIndex = 0; nominationIndex < maxPlayerNominations; ++nominationIndex )
    {
        LOGGER( 4, "" )
        LOGGER( 4, "" )
        LOGGER( 4, "( vote_addNominations ) nominationIndex: %d, maxPlayerNominations: %d", \
                nominationIndex, maxPlayerNominations )

        for( new player_id = 1; player_id < MAX_PLAYERS_COUNT; ++player_id )
        {
            mapIndex = getPlayerNominationMapIndex( player_id, nominationIndex );

            if( mapIndex >= 0 )
            {
                ArrayGetString( g_nominationLoadedMapsArray, mapIndex, mapName, charsmax( mapName ) );
                nominator_id = nomination_getPlayer( mapIndex );

                GET_USER_NAME( nominator_id, playerName )
                LOGGER( 4, "      %-32s %s", mapName, playerName )
            }
        }
    }

    return 0;
}

stock loadOnlyNominationVoteChoices()
{
    if( IS_NOMINATION_MININUM_PLAYERS_CONTROL_ENABLED()
        || IS_WHITELIST_ENABLED() )
    {
        new announcementShowedTimes = 1;
        new blockedMapsBuffer[ MAX_COLOR_MESSAGE ];

        vote_addNominations( blockedMapsBuffer, announcementShowedTimes );
        flushVoteBlockedMaps( blockedMapsBuffer, "GAL_FILLER_BLOCKED", announcementShowedTimes );
    }
    else
    {
        new dummyArray[] = 0;
        vote_addNominations( dummyArray );
    }
}

stock loadTheDefaultVotingChoices()
{
    LOGGER( 128, "I AM ENTERING ON loadTheDefaultVotingChoices(0)" )

    // To add the next map to the voting menu, if enabled.
    if( get_pcvar_num( cvar_voteMapChoiceNext ) )
    {
        new mapIndex;
        new mapInfo[ MAX_MAPNAME_LENGHT ];

        if( TrieKeyExists( g_mapcycleFileListTrie, g_nextMapName ) )
        {
            TrieGetCell(  g_mapcycleFileListTrie , g_nextMapName, mapIndex );
            GET_MAP_INFO( g_mapcycleFileListArray, mapIndex     , mapInfo  )
        }

        addMapToTheVotingMenu( g_nextMapName, mapInfo );
    }

    if( IS_NOMINATION_MININUM_PLAYERS_CONTROL_ENABLED()
        || IS_WHITELIST_ENABLED() )
    {
        new announcementShowedTimes = 1;
        new blockedMapsBuffer[ MAX_COLOR_MESSAGE ];

        vote_addNominations( blockedMapsBuffer, announcementShowedTimes );
        vote_addFillers( blockedMapsBuffer, announcementShowedTimes );

        flushVoteBlockedMaps( blockedMapsBuffer, "GAL_FILLER_BLOCKED", announcementShowedTimes );
    }
    else
    {
        new dummyArray[] = 0;

        vote_addNominations( dummyArray );
        vote_addFillers( dummyArray );
    }

    g_votingSecondsRemaining = get_pcvar_num( cvar_voteDuration );

    LOGGER( 4, "" )
    LOGGER( 4, "I AM EXITING ON loadTheDefaultVotingChoices(0) g_totalVoteOptions: %d", g_totalVoteOptions )
}

/**
 * Announce the Minplayers-Whitelist blocked maps.
 *
 * @param mapToAnnounce          a map which was blocked.
 * @param blockedMapsBuffer      the output string to be printed.
 *
 * @note It does not immediately print the called map. The output occurs when the buffer is full.
 */
stock announceVoteBlockedMap( mapToAnnounce[], blockedMapsBuffer[], flushAnnouncement[], &announcementShowedTimes )
{
    LOGGER( 128, "I AM ENTERING ON announceVoteBlockedMap(4) announcementShowedTimes: %d, \
            mapToAnnounce: %s, ", announcementShowedTimes, mapToAnnounce )

    if( announcementShowedTimes
        && announcementShowedTimes < 3 )
    {
        static copiedChars;

        // Reset the characters counter for the output flush.
        if( !blockedMapsBuffer[ 0 ] )
        {
            copiedChars = 0;
        }

        copiedChars += copy( blockedMapsBuffer[ copiedChars ], MAX_COLOR_MESSAGE - 1 - copiedChars, "^1, ^4" );
        copiedChars += copy( blockedMapsBuffer[ copiedChars ], MAX_COLOR_MESSAGE - 1 - copiedChars, mapToAnnounce );

        // Calculate whether to flush now or not.
        if( copiedChars > MAX_COLOR_MESSAGE - MAX_MAPNAME_LENGHT )
        {
            flushVoteBlockedMaps( blockedMapsBuffer, flushAnnouncement, announcementShowedTimes );
        }
    }
}

/**
 * Print the current blocked maps buffer, if there are any maps on it.
 *
 * @param blockedMapsBuffer     the formatted maps list to be printed.
 */
stock flushVoteBlockedMaps( blockedMapsBuffer[], flushAnnouncement[], &announcementShowedTimes )
{
    LOGGER( 128, "I AM ENTERING ON flushVoteBlockedMaps(3) announcementShowedTimes: %d, ", announcementShowedTimes )
    LOGGER( 128, "blockedMapsBuffer: %s",  blockedMapsBuffer )

    if( blockedMapsBuffer[ 0 ] )
    {
        if( announcementShowedTimes == 1 )
        {
            color_print( 0, "%L", LANG_PLAYER, flushAnnouncement, 0, 0 );
        }

        if( !IS_COLORED_CHAT_ENABLED() ) REMOVE_CODE_COLOR_TAGS( blockedMapsBuffer )
        color_print( 0, "%L", LANG_PLAYER, "GAL_MATCHING", blockedMapsBuffer[ 3 ] );

        announcementShowedTimes++;
        blockedMapsBuffer[ 0 ] = '^0';
    }
}

stock computeNextWhiteListLoadTime( seconds, bool:isSecondsLeft = true )
{
    LOGGER( 128, "I AM ENTERING ON computeNextWhiteListLoadTime(2) seconds: %d, isSecondsLeft: %d", seconds, isSecondsLeft )
    new secondsForReload;

    // This is tricky as 'seconds' could be 0, when there is no time-limit.
    if( seconds )
    {
        new currentHour;
        new currentMinute;
        new currentSecond;

        time( currentHour, currentMinute, currentSecond );
        secondsForReload = ( 3600 - ( currentMinute * 60 + currentSecond ) );

        if( isSecondsLeft )
        {
            // Here, when the 'secondsForReload' is greater than 'seconds', we will change map before
            // the next reload, then when do not need to reload on this current server session.
            if( seconds < secondsForReload )
            {
                g_whitelistNomBlockTime = 0;
            }
            else
            {
                g_whitelistNomBlockTime = seconds - secondsForReload + 1;
            }
        }
        else
        {
            // Here on '!isSecondsLeft', we do not know when there will be a map change, then we
            // just set the next time where the current hour will end.
            g_whitelistNomBlockTime = secondsForReload + seconds;
        }
    }
    else
    {
        g_whitelistNomBlockTime = 1000;

        LOGGER( 1, "ERROR: The seconds parameter on 'computeNextWhiteListLoadTime(1)' function is zero!" )
        log_amx( "ERROR: The seconds parameter on 'computeNextWhiteListLoadTime(1)' function is zero!" );
    }

    LOGGER( 1, "I AM EXITING computeNextWhiteListLoadTime(2) g_whitelistNomBlockTime: %d, secondsForReload: %d", g_whitelistNomBlockTime, secondsForReload )
}

/**
 * Action from handleServerStart to take when it is detected that the server has been
 * restarted. 3 - start an early map vote after the first two minutes.
 */
stock vote_manageEarlyStart()
{
    LOGGER( 128, "I AM ENTERING ON vote_manageEarlyStart(0) g_voteStatus: %d", g_voteStatus )
    g_voteStatus |= IS_EARLY_VOTE;

    set_task( 120.0, "startNonForcedVoting", TASKID_VOTE_STARTDIRECTOR );
}

public startNonForcedVoting()
{
    LOGGER( 128, "I AM ENTERING ON startNonForcedVoting(0) g_endVotingType: %d", g_endVotingType )
    vote_startDirector( false );
}

public start_voting_by_winlimit()
{
    LOGGER( 128, "I AM ENTERING ON start_voting_by_winlimit(0) g_endVotingType: %d", g_endVotingType)
    LOGGER( 32, "( start_voting_by_winlimit ) get_pcvar_num( cvar_endOfMapVote ): %d", get_pcvar_num( cvar_endOfMapVote ) )

    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_endVotingType |= IS_BY_WINLIMIT;

        resetVoteTypeGlobals();
        vote_startDirector( false );
    }
}

public start_voting_by_maxrounds()
{
    LOGGER( 128, "I AM ENTERING ON start_voting_by_maxrounds(0) g_endVotingType: %d", g_endVotingType)
    LOGGER( 32, "( start_voting_by_maxrounds ) get_pcvar_num( cvar_endOfMapVote ): %d", get_pcvar_num( cvar_endOfMapVote ) )

    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_endVotingType |= IS_BY_ROUNDS;

        resetVoteTypeGlobals();
        vote_startDirector( false );
    }
}

public start_voting_by_frags()
{
    LOGGER( 128, "I AM ENTERING ON start_voting_by_frags(0) g_endVotingType: %d", g_endVotingType)
    LOGGER( 32, "( start_voting_by_frags ) get_pcvar_num( cvar_endOfMapVote ): %d", get_pcvar_num( cvar_endOfMapVote ) )

    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_endVotingType |= IS_BY_FRAGS;

        resetVoteTypeGlobals();
        vote_startDirector( false );
    }
}

public start_voting_by_timer()
{
    LOGGER( 128, "I AM ENTERING ON start_voting_by_timer(0) g_endVotingType: %d", g_endVotingType)
    LOGGER( 32, "( start_voting_by_timer ) get_pcvar_num( cvar_endOfMapVote ): %d", get_pcvar_num( cvar_endOfMapVote ) )

    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_endVotingType |= IS_BY_TIMER;

        resetVoteTypeGlobals();
        vote_startDirector( false );
    }
}

public startVotingByGameEngineCall()
{
    LOGGER( 128, "I AM ENTERING ON startVotingByGameEngineCall(0) g_endVotingType: %d", g_endVotingType)
    LOGGER( 32, "( startVotingByGameEngineCall ) get_pcvar_num( cvar_endOfMapVote ): %d", get_pcvar_num( cvar_endOfMapVote ) )

    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_isToChangeMapOnVotingEnd = true;

        resetVoteTypeGlobals();
        vote_startDirector( false );
    }
}

public vote_manageEnd()
{
    LOGGER( 256, "I AM ENTERING ON vote_manageEnd(0) get_real_players_number: %d", get_real_players_number() )
    new secondsLeft = get_timeleft();

    if( secondsLeft )
    {
        // are we managing the end of the map?
        if( secondsLeft < 30
            && secondsLeft > 0 )
        {
            // This cannot trigger the map change, otherwise it will change the map before the last
            // seconds to be finished.
            try_to_manage_map_end();
        }

        // are we ready to start an "end of map" vote?
        if( secondsLeft < START_VOTEMAP_MIN_TIME
            && secondsLeft > START_VOTEMAP_MAX_TIME
            && isTimeToStartTheEndOfMapVoting() )
        {
            start_voting_by_timer();
        }
    }

    // Update the Whitelist maps when its the right time, configured by 'computeNextWhiteListLoadTime(2)'.
    if( g_whitelistNomBlockTime )
    {
        new secondsElapsed;
        secondsElapsed = floatround( get_gametime(), floatround_ceil );

        if( g_whitelistNomBlockTime < secondsElapsed )
        {
            computeNextWhiteListLoadTime( secondsElapsed, false );
            loadTheWhiteListFeature();
        }
    }

    handle_game_crash_recreation( secondsLeft );
}

/**
 * Handle the action to take immediately after half of the time-left or rounds-left passed
 * when using the 'Game Server Crash Recreation' Feature.
 */
stock handle_game_crash_recreation( secondsLeft )
{
    LOGGER( 256, "I AM ENTERING ON handle_game_crash_recreation(1) secondsLeft: %d", secondsLeft )
    static showCounter;

    // PERIODIC_CHECKING_INTERVAL = 15 seconds, 15 * 50 = 750 = 12.5 minutes
    if( ++showCounter % 50 < 1 )
    {
        if( !( get_pcvar_num( cvar_hudsHide ) & HUD_TIMELEFT_ANNOUNCE ) )
        {
            new displayTime = 7;
            set_hudmessage( 255, 255, 255, 0.15, 0.15, 0, 0.0, float( displayTime ), 0.1, 0.1, 1 );

            switch( whatGameEndingTypeItIs() )
            {
                case GameEndingType_ByMaxRounds:
                {
                    new roundsLeft = get_pcvar_num( cvar_mp_maxrounds ) - g_totalRoundsPlayed;
                    show_hudmessage( 0, "%L:^n%d:%2d %L", LANG_PLAYER, "TIME_LEFT", roundsLeft, LANG_PLAYER, "GAL_OPTION_NAME_ROUND" );
                }
                case GameEndingType_ByWinLimit:
                {
                    new winLeft = get_pcvar_num( cvar_mp_winlimit ) - max( g_totalCtWins, g_totalTerroristsWins );
                    show_hudmessage( 0, "%L:^n%d:%2d %L", LANG_PLAYER, "TIME_LEFT", winLeft, LANG_PLAYER, "GAL_OPTION_NAME_ROUND" );
                }
                case GameEndingType_ByFragLimit:
                {
                    new fragsLeft = get_pcvar_num( cvar_mp_fraglimit ) - g_greatestKillerFrags;
                    show_hudmessage( 0, "%L:^n%d:%2d %L", LANG_PLAYER, "TIME_LEFT", fragsLeft, LANG_PLAYER, "GAL_OPTION_NAME_FRAGS" );
                }
                case GameEndingType_ByTimeLimit:
                {
                    set_task( 1.0, "displayRemainingTime", TASKID_DISPLAY_REMAINING_TIME, _, _, "a", displayTime );
                }
                default:
                {
                    show_hudmessage( 0, "%L:^n%L", LANG_PLAYER, "TIME_LEFT", LANG_PLAYER, "NO_T_LIMIT" );
                }
            }
        }
    }

    if( g_isToCreateGameCrashFlag
        && (  g_timeLimitNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_timeLimitNumber - secondsLeft / 60
           || g_fragLimitNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_greatestKillerFrags
           || g_maxRoundsNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_totalRoundsPlayed + 1
           || g_winLimitInteger / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_totalTerroristsWins + g_totalCtWins ) )
    {
        new gameCrashActionFilePath[ MAX_FILE_PATH_LENGHT ];

        // stop creating this file unnecessarily
        g_isToCreateGameCrashFlag = false;

        LOGGER( 32, "( vote_manageEnd )  %d/%d < %d: %d", \
                g_timeLimitNumber, SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR, g_timeLimitNumber - secondsLeft / 60, \
                g_timeLimitNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_timeLimitNumber - secondsLeft / 60)

        LOGGER( 32, "( vote_manageEnd )  %d/%d < %d: %d", \
                g_fragLimitNumber, SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR, g_greatestKillerFrags, \
                g_fragLimitNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_greatestKillerFrags )

        LOGGER( 32, "( vote_manageEnd )  %d/%d < %d: %d", \
                g_maxRoundsNumber, SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR, g_totalRoundsPlayed + 1, \
                g_maxRoundsNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_totalRoundsPlayed + 1 )

        LOGGER( 32, "( vote_manageEnd )  %d/%d < %d: %d", \
                g_winLimitInteger, SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR, g_totalTerroristsWins + g_totalCtWins, \
                g_winLimitInteger / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_totalTerroristsWins + g_totalCtWins )

        generateGameCrashActionFilePath( gameCrashActionFilePath, charsmax( gameCrashActionFilePath ) );
        write_file( gameCrashActionFilePath, "Game Crash Action Flag File^n^nSee the cvar \
                'gal_game_crash_recreation'.^nDo not delete it." );
    }
}

public displayRemainingTime()
{
    new timeLeft = get_timeleft();
    new seconds  = timeLeft % 60;
    new minutes  = floatround( ( timeLeft - seconds ) / 60.0 );

    set_hudmessage( 255, 255, 255, 0.15, 0.15, 0, 0.0, 1.1, 0.1, 0.1, 1 );
    show_hudmessage( 0, "%L:^n%d: %2d %L", LANG_PLAYER, "TIME_LEFT", minutes, seconds, LANG_PLAYER, "MINUTES" );
}

stock bool:approvedTheVotingStart( bool:is_forced_voting )
{
    LOGGER( 128, "I AM ENTERING ON approvedTheVotingStart(1) is_forced_voting: %d, get_real_players_number: %d", \
            is_forced_voting, get_real_players_number() )

    if( get_pcvar_num( cvar_nextMapChangeVotemap )
        && !is_forced_voting )
    {
        new nextMapFlag[ 128 ];
        new nextMapName[ MAX_MAPNAME_LENGHT ];

        formatex( nextMapFlag, charsmax( nextMapFlag ), "%L", LANG_SERVER, "GAL_NEXTMAP_UNKNOWN" );
        REMOVE_CODE_COLOR_TAGS( nextMapFlag )

        new bool:isNextMapChangeAnnounce = get_pcvar_num( cvar_nextMapChangeAnnounce ) != 0;
        get_pcvar_string( cvar_amx_nextmap, nextMapName, charsmax( nextMapName ) );

        if( isNextMapChangeAnnounce
            && !equali( nextMapFlag, nextMapName, strlen( nextMapName ) )
            || !isNextMapChangeAnnounce
               && !equali( g_nextMapName, nextMapName, strlen( nextMapName ) ) )
        {
            // The voting is over, i.e., must to be performed.
            g_voteStatus |= IS_VOTE_OVER;

            LOGGER( 1, "    ( approvedTheVotingStart ) Returning false due the `gal_nextmap_votemap` feature." )
            return false;
        }
    }

    // block the voting on some not allowed situations/cases
    if( get_real_players_number() == 0
        || ( g_voteStatus & IS_VOTE_IN_PROGRESS
             && !( g_voteStatus & IS_RUNOFF_VOTE ) )
        || ( !is_forced_voting
             && g_voteStatus & IS_VOTE_OVER ) )
    {
        LOGGER( 1, "    ( approvedTheVotingStart ) g_voteStatus: %d, g_voteStatus & IS_VOTE_OVER: %d", \
                g_voteStatus, g_voteStatus & IS_VOTE_OVER != 0 )

    #if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED )
        if( g_test_isTheUnitTestsRunning )
        {
            LOGGER( 1, "    ( approvedTheVotingStart ) Returning true on the if !g_test_isTheUnitTestsRunning, \
                    cvar_isEmptyCycleByMapChange: %d.", get_pcvar_num( cvar_isEmptyCycleByMapChange ) )
            return true;
        }
    #endif

        if( get_real_players_number() == 0 )
        {
            if( get_pcvar_num( cvar_isEmptyCycleByMapChange ) )
            {
                startEmptyCycleSystem();
            }

            if( g_voteStatus & IS_VOTE_IN_PROGRESS )
            {
                cancelVoting();
            }
        }

        LOGGER( 1, "    ( approvedTheVotingStart ) Returning false on the big blocker." )
        return false;
    }

    // allow a new forced voting while the map is ending
    if( is_forced_voting
        && g_voteStatus & IS_VOTE_OVER )
    {
        new bool:roundEndStatus[ 4 ];

        saveRoundEnding( roundEndStatus );
        cancelVoting();

        restoreRoundEnding( roundEndStatus );
        restoreOriginalServerMaxSpeed();
    }

    // the rounds start delay task could be running
    remove_task( TASKID_START_VOTING_DELAYED );

    // If the voting menu deletion task is running, remove it then delete the menus right now.
    if( remove_task( TASKID_DELETE_USERS_MENUS ) )
    {
        vote_resetStats();
    }

    LOGGER( 1, "    ( approvedTheVotingStart ) Returning true, due passed by all requirements." )
    return true;
}

stock printVotingMaps( mapNames[][], mapInfos[][], votingMapsCount = MAX_OPTIONS_IN_VOTE )
{
    LOGGER( 128, "I AM ENTERING ON printVotingMaps(3) votingMapsCount: %d", votingMapsCount )

    for( new index = 0; index < votingMapsCount; index++ )
    {
        LOGGER( 16, "( printVotingMaps ) Voting map %d: %s %s", index, mapNames[ index ], mapInfos[ index ] )
    }

    LOGGER( 16, "" )
    LOGGER( 16, "" )

    // Removes the compiler warning `warning 203: symbol is never used` with some DEBUG levels.
    if( mapNames[ 0 ][ 0 ] && mapInfos[ 0 ][ 0 ] ) { }

    return 0;
}

stock loadRunOffVoteChoices()
{
    LOGGER( 128, "I AM ENTERING ON loadRunOffVoteChoices(0)" )

    new runoffChoiceName[ MAX_OPTIONS_IN_VOTE ][ MAX_MAPNAME_LENGHT ];
    new runoffChoiceInfo[ MAX_OPTIONS_IN_VOTE ][ MAX_MAPNAME_LENGHT ];

    // Create a clean copy to not copy overridden maps
    for( new mapIndex = 0; mapIndex < g_totalVoteOptions; mapIndex++ )
    {
        copy( runoffChoiceName[ mapIndex ], charsmax( runoffChoiceName[] ), g_votingMapNames[ g_arrayOfRunOffChoices[ mapIndex ] ] );
        copy( runoffChoiceInfo[ mapIndex ], charsmax( runoffChoiceInfo[] ), g_votingMapInfos[ g_arrayOfRunOffChoices[ mapIndex ] ] );
    }

    // Load runoff choices
    for( new mapIndex = 0; mapIndex < g_totalVoteOptions; mapIndex++ )
    {
        copy( g_votingMapNames[ mapIndex ], charsmax( g_votingMapNames[] ), runoffChoiceName[ mapIndex ] );
        copy( g_votingMapInfos[ mapIndex ], charsmax( g_votingMapInfos[] ), runoffChoiceInfo[ mapIndex ] );
    }

    g_votingSecondsRemaining = get_pcvar_num( cvar_runoffDuration );
    LOGGER( 0, "", printVotingMaps(  g_votingMapNames, g_votingMapInfos, g_totalVoteOptions ) )
}

stock configureVotingStart( bool:is_forced_voting )
{
    LOGGER( 128, "I AM ENTERING ON configureVotingStart(1) is_forced_voting: %d", is_forced_voting )

    // update cached data for the new voting
    cacheCvarsValues();

    // make it known that a vote is in progress
    g_voteStatus |= IS_VOTE_IN_PROGRESS;

    // Set the voting status to forced
    if( is_forced_voting )
    {
        g_voteStatus |= IS_FORCED_VOTE;
    }

    configureTheExtensionOption( is_forced_voting );

    LOGGER( 4, "( configureVotingStart ) g_voteStatus: %d, ", g_voteStatus )
    LOGGER( 4, "( configureVotingStart ) g_voteMapStatus: %d, ", g_voteMapStatus )

    // stop RTV reminders
    remove_task( TASKID_RTV_REMINDER );
}

/**
 * To allow show the extension option as `Stay Here` and `Extend` and to set the end voting type.
 */
stock configureTheExtensionOption( bool:is_forced_voting )
{
    LOGGER( 128, "I AM ENTERING ON configureTheExtensionOption(1) is_forced_voting: %d", is_forced_voting )
    new Float:cache;

    // If we cannot find anything cancelling/blocking the map extension, allow it by the default.
    if( g_voteMapStatus & IS_DISABLED_VOTEMAP_EXTENSION )
    {
        g_isMapExtensionAllowed = false;
    }
    else if( g_voteStatus & IS_RTV_VOTE
             && get_pcvar_num( cvar_rtvWaitAdmin ) & IS_TO_RTV_NOT_ALLOW_STAY )
    {
        g_isMapExtensionAllowed = false;
    }
    else if( g_endVotingType & IS_BY_FRAGS
             && ( cache = Float:get_pcvar_num( cvar_maxMapExtendFrags ) ) )
    {
        g_isMapExtensionAllowed =
                get_pcvar_num( cvar_mp_fraglimit ) < cache;
    }
    else if( g_endVotingType & IS_BY_ROUNDS
             && ( cache = Float:get_pcvar_num( cvar_maxMapExtendRounds ) ) )
    {
        g_isMapExtensionAllowed =
                get_pcvar_num( cvar_mp_maxrounds ) < cache;
    }
    else if( g_endVotingType & IS_BY_WINLIMIT
             && ( cache = get_pcvar_float( cvar_maxMapExtendRounds ) ) )
    {
        g_isMapExtensionAllowed =
                get_pcvar_num( cvar_mp_winlimit ) < cache;
    }
    else if( g_endVotingType & IS_BY_TIMER
             && ( cache = get_pcvar_float( cvar_maxMapExtendTime ) ) )
    {
        g_isMapExtensionAllowed =
                get_pcvar_float( cvar_mp_timelimit ) < cache;
    }
    else
    {
        g_isMapExtensionAllowed = true;
    }

    g_isGameFinalVoting = ( ( g_endVotingType & IS_BY_ROUNDS
                              || g_endVotingType & IS_BY_WINLIMIT
                              || g_endVotingType & IS_BY_TIMER
                              || g_endVotingType & IS_BY_FRAGS )
                            && !is_forced_voting );

    LOGGER( 4, "( configureTheExtensionOption ) g_isGameFinalVoting: %d, ", g_isGameFinalVoting )
    LOGGER( 4, "( configureTheExtensionOption ) g_isMapExtensionAllowed: %d, ", g_isMapExtensionAllowed )
}

/**
 * Any voting not started by `cvar_endOfMapVoteStart`, `cvar_endOnRound` or ending limit expiration,
 * is a forced voting.
 */
stock vote_startDirector( bool:is_forced_voting )
{
    LOGGER( 128, "I AM ENTERING ON vote_startDirector(1) is_forced_voting: %d", is_forced_voting )

    if( !approvedTheVotingStart( is_forced_voting ) )
    {
        LOGGER( 1, "    ( vote_startDirector ) Just Returning/blocking, the voting was not approved." )
        return;
    }

    if( g_voteStatus & IS_RUNOFF_VOTE )
    {
        // to load runoff vote choices
        loadRunOffVoteChoices();
    }
    else
    {
        // Clear the cmd_startVote(3) map settings just in case they where loaded.
        // Clean it just to be sure as the voteMapMenuBuilder() could let it filled.
        clearTheVotingMenu();
        g_voteMapStatus = 0;

        // to prepare the initial voting state
        configureVotingStart( is_forced_voting );

        // to load vote choices
        loadTheDefaultVotingChoices();
    }

    // Show up the voting menu
    if( g_totalVoteOptions )
    {
        initializeTheVoteDisplay();
    }
    else
    {
        // Vote creation failed; no maps found.
        color_print( 0, "%L", LANG_PLAYER, "GAL_VOTE_NOMAPS" );
        finalizeVoting();
    }

    LOGGER( 4, "" )
    LOGGER( 4, "    ( vote_startDirector|out ) g_isTheLastGameRound: %d", g_isTheLastGameRound )
    LOGGER( 4, "    ( vote_startDirector|out ) g_isTimeToRestart: %d, g_voteStatus & IS_FORCED_VOTE: %d", \
            g_isTimeToRestart, g_voteStatus & IS_FORCED_VOTE != 0 )
}

/**
 * Sort static the static array `array[]` and keep the array `arraySync` updated with it.
 *
 * @param array        a sorted two-dimensional static array
 * @param arraySync    a synced two-dimensional static array with the first parameter `array[][]`
 * @param elementSize  the size of the elements to be inserted
 */
stock SortCustomSynced2D( array[][], arraySync[][], arraySize )
{
    LOGGER( 128, "I AM ENTERING ON SortCustomSynced2D(3) arraySize: %d", arraySize )
    LOGGER( 0, "", printVotingMaps( array, arraySync ) )

    new outerIndex;
    new innerIndex;

    new tempElement    [ MAX_MAPNAME_LENGHT ];
    new tempElementSync[ MAX_MAPNAME_LENGHT ];

    for( outerIndex = 0; outerIndex < arraySize; outerIndex++ )
    {
        for( innerIndex = outerIndex + 1; innerIndex < arraySize; innerIndex++ )
        {
            if( strcmp( array[ outerIndex ], array[ innerIndex ] ) > 0 )
            {
                copy( tempElement    , charsmax( tempElement     ), array    [ outerIndex ] );
                copy( tempElementSync, charsmax( tempElementSync ), arraySync[ outerIndex ] );

                copy( array    [ outerIndex ], charsmax( tempElement ), array    [ innerIndex ] );
                copy( arraySync[ outerIndex ], charsmax( tempElement ), arraySync[ innerIndex ] );

                copy( array    [ innerIndex ], charsmax( tempElement     ), tempElement     );
                copy( arraySync[ innerIndex ], charsmax( tempElementSync ), tempElementSync );
            }
        }
    }

    LOGGER( 0, "", printVotingMaps( array, arraySync ) )
}

stock initializeTheVoteDisplay()
{
    LOGGER( 128, "I AM ENTERING ON initializeTheVoteDisplay(0)" )

    new player_id;
    new playersCount;

    new players[ MAX_PLAYERS ];
    new Float:handleChoicesDelay;

    // Clear all nominations
    nomination_clearAll();

    // Alphabetize the maps
    SortCustomSynced2D( g_votingMapNames, g_votingMapInfos, g_totalVoteOptions );

    // Skip bots and hltv
    get_players( players, playersCount, "ch" );

    // Mark the players who are in this vote for use later
    for( new playerIndex = 0; playerIndex < playersCount; ++playerIndex )
    {
        player_id = players[ playerIndex ];

        if( g_isPlayerParticipating[ player_id ] )
        {
            g_isPlayerVoted[ player_id ] = false;
        }
    }

    // Adjust the choices delay for the Unit Tests run or normal work flow
#if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED )
    handleChoicesDelay = 0.1;
#else

    if( g_voteMapStatus & IS_DISABLED_VOTEMAP_INTRO )
    {
        handleChoicesDelay = 0.1;
    }
    else
    {
        // Set_task 1.0 + pendingVoteCountdown 1.0
        handleChoicesDelay = VOTE_TIME_SEC + VOTE_TIME_SEC + getVoteAnnouncementTime();

        // Make perfunctory announcement: "get ready to choose a map"
        if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_GET_READY_TO_CHOOSE ) )
        {
            client_cmd( 0, "spk ^"get red( e80 ) ninety( s45 ) to check( e20 ) \
                    use bay( s18 ) mass( e42 ) cap( s50 )^"" );
        }

        // Announce the pending vote countdown from 7 | 5 to 1
        if( get_pcvar_num( cvar_isToAskForEndOfTheMapVote ) & END_OF_MAP_VOTE_ANNOUNCE )
        {
            set_task( VOTE_TIME_ANNOUNCE, "announceThePendingVote", TASKID_PENDING_VOTE_COUNTDOWN );
            announceThePendingVoteTime( VOTE_TIME_ANNOUNCE + VOTE_TIME_HUD_2 );
        }
        else
        {
            // Visual countdown
            announceThePendingVote();
            announceThePendingVoteTime( VOTE_TIME_HUD_1 );
        }
    }
#endif

    // Force a right vote duration for the Unit Tests run
#if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED )
    g_votingSecondsRemaining = 5;
#endif

    // To create fake votes when needed
#if DEBUG_LEVEL & DEBUG_LEVEL_FAKE_VOTES
    set_task( 2.0, "create_fakeVotes", TASKID_DBG_FAKEVOTES );
#endif

    // Set debug options
    LOGGER( 0, "", configureVoteDisplayDebugging() )

    // Display the map choices, 1 second from now
    set_task( handleChoicesDelay, "vote_handleDisplay", TASKID_VOTE_HANDLEDISPLAY );
}

stock announceThePendingVoteTime( Float:time )
{
    LOGGER( 128, "I AM ENTERING ON announceThePendingVoteTime(1) time: %f", time )

    new targetTime = floatround( time, floatround_floor );
    color_print( 0, "%L", LANG_PLAYER, "DMAP_NEXTMAP_VOTE_REMAINING2", targetTime );

    // If there is enough time
    if( targetTime > VOTE_TIME_HUD_1
        && !( get_pcvar_num( cvar_hudsHide ) & HUD_VOTE_VISUAL_COUNTDOWN ) )
    {
        set_hudmessage( 0, 222, 50, -1.0, 0.13, 1, 1.0, 5.94, 0.0, 0.0, -1 );
        show_hudmessage( 0, "%L", LANG_PLAYER, "DMAP_NEXTMAP_VOTE_REMAINING1", targetTime );
    }
}

public announceThePendingVote()
{
    LOGGER( 128, "I AM ENTERING ON announceThePendingVote(0)" )

    if( get_pcvar_num( cvar_isToAskForEndOfTheMapVote ) & END_OF_MAP_VOTE_ANNOUNCE )
    {
        g_pendingVoteCountdown = floatround( VOTE_TIME_HUD_2, floatround_floor ) + 1;
    }
    else
    {
        g_pendingVoteCountdown = floatround( VOTE_TIME_HUD_1, floatround_floor ) + 1;
    }

    set_task( VOTE_TIME_SEC, "pendingVoteCountdown", TASKID_PENDING_VOTE_COUNTDOWN, _, _, "a", g_pendingVoteCountdown );
}

stock Float:getVoteAnnouncementTime()
{
    LOGGER( 128, "I AM ENTERING ON getVoteAnnouncementTime(0)" )

    if( get_pcvar_num( cvar_isToAskForEndOfTheMapVote ) & END_OF_MAP_VOTE_ANNOUNCE )
    {
        return VOTE_TIME_ANNOUNCE + VOTE_TIME_HUD_2;
    }

    return VOTE_TIME_HUD_1;
}

stock configureVoteDisplayDebugging()
{
    // Print the voting map options
    new voteOptions = ( g_totalVoteOptions == 1 ? 2 : g_totalVoteOptions );

    LOGGER( 4, "" )
    LOGGER( 4, "" )
    LOGGER( 4, "   [PLAYER CHOICES]" )

    for( new dbgChoice = 0; dbgChoice < voteOptions; dbgChoice++ )
    {
        LOGGER( 4, "      %i. %s %s", dbgChoice + 1, g_votingMapNames[ dbgChoice ], g_votingMapInfos[ dbgChoice ] )
    }

    return 0;
}

public pendingVoteCountdown()
{
    LOGGER( 128, "I AM ENTERING ON pendingVoteCountdown(0) g_pendingVoteCountdown: %d", g_pendingVoteCountdown )

    if( get_pcvar_num( cvar_isToAskForEndOfTheMapVote ) & END_OF_MAP_VOTE_ASK
        && !( g_voteStatus & IS_RUNOFF_VOTE ) )
    {
        displayEndOfTheMapVoteMenu( 0 );
    }

    // We increase it 1 more, and remove it later to allow the displayEndOfTheMapVoteMenu(1) to automatically
    // select the Yes option when the counter hits 1.
    if( g_pendingVoteCountdown > 1 )
    {
        // visual countdown
        if( !( get_pcvar_num( cvar_hudsHide ) & HUD_VOTE_VISUAL_COUNTDOWN ) )
        {
            set_hudmessage( 0, 222, 50, -1.0, 0.13, 0, 1.0, 0.94, 0.0, 0.0, -1 );
            show_hudmessage( 0, "%L", LANG_PLAYER, "GAL_VOTE_COUNTDOWN", g_pendingVoteCountdown - 1 );
        }

        // audio countdown
        if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_COUNTDOWN ) )
        {
            new word[ 6 ];
            num_to_word( g_pendingVoteCountdown - 1, word, 5 );

            client_cmd( 0, "spk ^"fvox/%s^"", word );
        }
    }

    // decrement the countdown
    g_pendingVoteCountdown--;
}

public displayEndOfTheMapVoteMenu( player_id )
{
    LOGGER( 128, "I AM ENTERING ON displayEndOfTheMapVoteMenu(1) player_id: %d", player_id )

    static menu_body   [ MAX_LONG_STRING ];
    static menu_counter[ MAX_SHORT_STRING ];

    new menu_id;
    new menuKeys;
    new menuKeysUnused;
    new playersCount;
    new players[ MAX_PLAYERS ];

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
        // If the player does not has completely closed the menu for good.
        if( !g_isPlayerClosedTheVoteMenu[ ( player_id = players[ playerIndex ] ) ] )
        {
            isVoting       = g_isPlayerParticipating[ player_id ];
            playerAnswered = g_answeredForEndOfMapVote[ player_id ] || g_pendingVoteCountdown < 2;

            menu_body   [ 0 ] = '^0';
            menu_counter[ 0 ] = '^0';

            if( !playerAnswered )
            {
                menuKeys = MENU_KEY_0 | MENU_KEY_6;

                formatex( menu_counter, charsmax( menu_counter ),
                        " %s(%s%d %L%s)",
                        COLOR_YELLOW, COLOR_GREY, g_pendingVoteCountdown - 1, LANG_PLAYER, "GAL_TIMELEFT", COLOR_YELLOW );
            }
            else
            {
                // The close for good option key
                menuKeys = MENU_KEY_0;
            }

            formatex( menu_body, charsmax( menu_body ),
                    "%s%L^n^n\
                    %s6. %s%L %s^n\
                    %s0. %s%L",
                    COLOR_YELLOW, player_id, "GAL_CHOOSE_QUESTION",

                    COLOR_RED, ( playerAnswered ? ( isVoting ? COLOR_YELLOW : COLOR_GREY ) : COLOR_WHITE ),
                    player_id, "GAL_CHOOSE_QUESTION_YES", menu_counter,

                    COLOR_RED, ( playerAnswered ? ( !isVoting ? COLOR_YELLOW : COLOR_GREY ) : COLOR_WHITE ),
                    player_id, ( playerAnswered && !isVoting ? "GAL_OPTION_NONE_VOTE" : "GAL_CHOOSE_QUESTION_NO" ) );

            get_user_menu( player_id, menu_id, menuKeysUnused );

            if( menu_id == 0
                || menu_id == g_chooseMapQuestionMenuId )
            {
                show_menu( player_id, menuKeys, menu_body, ( g_pendingVoteCountdown == 1 ? 1 : 2 ), CHOOSE_MAP_MENU_QUESTION );
            }

            LOGGER( 4, " ( displayEndOfTheMapVoteMenu| for ) menu_body: %s", menu_body )
            LOGGER( 4, "    menu_id:%d, menuKeys: %d, isVoting: %d, playerAnswered:%d, \
                    player_id: %d, playerIndex: %d", menu_id, menuKeys, isVoting, playerAnswered, \
                    player_id, playerIndex )

            LOGGER( 4, "    playersCount: %d, g_pendingVoteCountdown: %d, menu_counter: %s", \
                    playersCount, g_pendingVoteCountdown, menu_counter )
        }
    }

    LOGGER( 4, "%48s", " ( displayEndOfTheMapVoteMenu| out )" )
}

public handleEndOfTheMapVoteChoice( player_id, pressedKeyCode )
{
    LOGGER( 128, "I AM ENTERING ON handleEndOfTheMapVoteChoice(2) player_id: %d, pressedKeyCode: %d", \
            player_id, pressedKeyCode )

    // pressedKeyCode 0 means the keyboard key 1
    if( !g_answeredForEndOfMapVote[ player_id ]
         && pressedKeyCode == 9 )
    {
        announceRegistedVote( player_id, pressedKeyCode );

        g_isPlayerVoted[ player_id ]         = true;
        g_isPlayerParticipating[ player_id ] = false;
    }
    else if( g_answeredForEndOfMapVote[ player_id ]
             && !g_isPlayerParticipating[ player_id ]
             && pressedKeyCode == 9 )
    {
        g_isPlayerClosedTheVoteMenu[ player_id ] = true;

        LOGGER( 1, "    ( handleEndOfTheMapVoteChoice ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }

    g_answeredForEndOfMapVote[ player_id ] = true;

    // displayEndOfTheMapVoteMenu( player_id );
    set_task( 0.1, "displayEndOfTheMapVoteMenu", player_id );

    LOGGER( 1, "    ( handleEndOfTheMapVoteChoice ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

public vote_handleDisplay()
{
    LOGGER( 128, "I AM ENTERING ON vote_handleDisplay(0)" )

    // announce: "time to choose"
    if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_TIME_TO_CHOOSE ) )
    {
        client_cmd( 0, "spk Gman/Gman_Choose%i", random_num( 1, 2 ) );
    }

    if( g_showVoteStatus
        && g_showVoteStatusType & STATUS_TYPE_PERCENTAGE )
    {
        copy( g_voteStatus_symbol, charsmax( g_voteStatus_symbol ), "%" );
    }

    // ensure the vote status doesn't indicate expired
    g_voteStatus &= ~IS_VOTE_EXPIRED;

    new argument[ 2 ] = { true, 0 };

    if( g_showVoteStatus == SHOW_STATUS_ALWAYS
        || g_showVoteStatus == SHOW_STATUS_AFTER_VOTE
        || g_showVoteStatus == SHOW_STATUS_ALWAYS_UNTIL_VOTE )
    {
        set_task( 1.0, "vote_display", TASKID_VOTE_DISPLAY, argument, sizeof argument, "a", g_votingSecondsRemaining );
    }
    else // g_showVoteStatus == SHOW_STATUS_AT_END || g_showVoteStatus == SHOW_STATUS_NEVER
    {
        set_task( 1.0, "tryToShowTheVotingMenu", TASKID_VOTE_DISPLAY, _, _, "a", g_votingSecondsRemaining );
    }

    // display the vote outcome
    set_task( float( g_votingSecondsRemaining ), "closeVoting", TASKID_VOTE_EXPIRE );
}

public tryToShowTheVotingMenu()
{
    LOGGER( 128, "I AM ENTERING ON tryToShowTheVotingMenu(0)" )

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

            // Allow lazy players to see the menu when the `SHOW_STATUS_ALWAYS` is not set.
            vote_display( argument );
        }
    }
}

public closeVoting()
{
    LOGGER( 128, "I AM ENTERING ON closeVoting(0)" )
    new argument[ 2 ] = { false, -1 };

    // waits until the last voting second to finish
    set_task( VOTE_TIME_SEC - 0.1, "voteExpire" );
    set_task( VOTE_TIME_SEC, "vote_display", TASKID_VOTE_DISPLAY, argument, sizeof argument, "a", 3 );

    // set_task( 1.5, "delete_users_menus_care", TASKID_DELETE_USERS_MENUS_CARE );
    set_task( VOTE_TIME_COUNT, "computeVotes", TASKID_VOTE_EXPIRE );
}

public voteExpire()
{
    LOGGER( 128, "I AM ENTERING ON voteExpire(0)" )
    g_voteStatus |= IS_VOTE_EXPIRED;

    // This is necessary because the SubVote Menu is not closing automatically when the voting finishes,
    // then the voting results are being displayed forcing the SubMenu to looks like it is not closing
    // never and ever, but actually it is just being displayed 3 times as it was the voting results.
    arrayset( g_isPlayerSeeingTheSubMenu, false, sizeof g_isPlayerSeeingTheSubMenu );
}

/**
 * This function is called with the correct player id only after the player voted or by the
 * 'tryToShowTheVotingMenu(0)' function call.
 */
public vote_display( argument[ 2 ] )
{
    LOGGER( 4, "I AM ENTERING ON vote_display(1)" )

    new menuKeys;
    static voteStatus    [ MAX_BIG_BOSS_STRING - 100 ];
    static mapVotingCount[ MAX_MAPNAME_LENGHT + 32 ];

    new copiedChars         = 0;
    new player_id           = argument[ 1 ];
    new updateTimeRemaining = argument[ 0 ];
    new bool:isVoteOver     = g_voteStatus & IS_VOTE_EXPIRED != 0;
    new bool:noneIsHidden   = ( g_isToShowNoneOption
                                && !g_voteShowNoneOptionType
                                && !isVoteOver );

    // Update time remaining
    updateTimeRemaining ? g_votingSecondsRemaining-- : 0;

    LOGGER( 4, "  ( votedisplay ) player_id: %d", argument[ 1 ]  )
    LOGGER( 4, "  ( votedisplay ) updateTimeRemaining: %d", argument[ 0 ]  )
    LOGGER( 4, "  ( votedisplay ) g_totalVoteOptions: %d", g_totalVoteOptions )
    LOGGER( 4, "  ( votedisplay ) g_votingSecondsRemaining: %d", g_votingSecondsRemaining )
    LOGGER( 4, "  ( votedisplay ) strlen( g_voteStatusClean ): %d", strlen( g_voteStatusClean )  )

    // wipe the previous vote status
    voteStatus[ 0 ] = '^0';

    // register the 'None' option key
    g_isToShowSubMenu || ( g_isToShowNoneOption && !isVoteOver ) ? ( menuKeys = MENU_KEY_0 ) : 0;

    // add maps to the menu
    for( new choiceIndex = 0; choiceIndex < g_totalVoteOptions; ++choiceIndex )
    {
        computeMapVotingCount( mapVotingCount, charsmax( mapVotingCount ), choiceIndex );

        copiedChars += formatex( voteStatus[ copiedChars ], charsmax( voteStatus ) - copiedChars,
               "^n%s%d.%s %s\
                %s\
                %s%s",
                COLOR_RED, choiceIndex + 1, COLOR_WHITE, g_votingMapNames[ choiceIndex ],
                g_votingMapInfos[ choiceIndex ][ 0 ] ? " " : "",
                g_votingMapInfos[ choiceIndex ], mapVotingCount );

        menuKeys |= ( 1 << choiceIndex );
    }

    // Make a copy of the virgin menu, using the first player's menu as base. To not make this
    // causes all the subsequent clean menus being displayed on the first player language, we do not
    // save it after adding the first LANG constant from the multilingual dictionary.
    if( g_voteStatusClean[ 0 ] == '^0' )
    {
        copy( g_voteStatusClean, charsmax( g_voteStatusClean ), voteStatus );
    }

    // This is to optionally display to single player that just voted or never saw the menu.
    // This function is called with the correct player id only after the player voted or by the
    // 'tryToShowTheVotingMenu(0)' function call.
    if( player_id > 0 )
    {
        if( g_isPlayerClosedTheVoteMenu[ player_id ] )
        {
            // Do nothing
        }
        else if( g_isToShowSubMenu
                 && g_isPlayerSeeingTheSubMenu[ player_id ] )
        {
            dispaly_the_vote_sub_menu( player_id );
        }
        else if( g_showVoteStatus == SHOW_STATUS_ALWAYS
                 || g_showVoteStatus == SHOW_STATUS_AFTER_VOTE )
        {
            menuKeys = addExtensionOption( player_id, copiedChars, voteStatus, charsmax( voteStatus ), menuKeys );
            display_menu_dirt( player_id, menuKeys, isVoteOver, noneIsHidden, voteStatus );
        }
        else if( g_showVoteStatus != SHOW_STATUS_ALWAYS_UNTIL_VOTE )
        {
            // g_showVoteStatus == SHOW_STATUS_NEVER || g_showVoteStatus == SHOW_STATUS_AT_END
            display_menu_clean( player_id, menuKeys );
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

            if( g_isPlayerClosedTheVoteMenu[ player_id ] )
            {
                continue;
            }
            else if( g_isToShowSubMenu
                     && g_isPlayerSeeingTheSubMenu[ player_id ] )
            {
                dispaly_the_vote_sub_menu( player_id );
            }
            else
            {
                if( !g_isPlayerVoted[ player_id ]
                    && !isVoteOver
                    && g_showVoteStatus != SHOW_STATUS_ALWAYS
                    && g_showVoteStatus != SHOW_STATUS_ALWAYS_UNTIL_VOTE )
                {
                    display_menu_clean( player_id, menuKeys );
                }
                else if( g_showVoteStatus == SHOW_STATUS_ALWAYS
                         || ( g_showVoteStatus == SHOW_STATUS_ALWAYS_UNTIL_VOTE
                              && !g_isPlayerVoted[ player_id ] )
                         || ( isVoteOver
                              && g_showVoteStatus )
                         || ( g_isPlayerVoted[ player_id ]
                              && g_showVoteStatus == SHOW_STATUS_AFTER_VOTE ) )
                {
                    menuKeys = addExtensionOption( player_id, copiedChars, voteStatus, charsmax( voteStatus ), menuKeys );
                    display_menu_dirt( player_id, menuKeys, isVoteOver, noneIsHidden, voteStatus );
                }
            }
        }
    }
}

stock dispaly_the_vote_sub_menu( player_id )
{
    LOGGER( 128, "I AM ENTERING ON dispaly_the_vote_sub_menu(1) player_id: %d", player_id )
    static menu_body[ MAX_LONG_STRING ];

    new      menuKeys    = MENU_KEY_0 | MENU_KEY_5;
    new bool:canVoteNone = !g_isPlayerVoted[ player_id ];
    new bool:canCancel   = !g_isPlayerCancelledVote[ player_id ] && g_isPlayerVoted[ player_id ];

    menuKeys |= canVoteNone ? MENU_KEY_1 : 0;
    menuKeys |= canCancel   ? MENU_KEY_3 : 0;

    menu_body[ 0 ] = '^0';

    formatex( menu_body, charsmax( menu_body ),
           "%s%L^n^n\
            %s1.%s %L^n\
            %s3.%s %L^n\
            %s5.%s %L^n\
            ^n%s0.%s %L",
            COLOR_YELLOW, player_id, "CMD_MENU",
            COLOR_RED, canVoteNone ? COLOR_WHITE : COLOR_GREY, player_id, "GAL_OPTION_NONE_VOTE",
            COLOR_RED, canCancel   ? COLOR_WHITE : COLOR_GREY, player_id, "GAL_OPTION_CANCEL_VOTE",
            COLOR_RED, COLOR_WHITE, player_id, "EXIT",
            COLOR_RED, COLOR_WHITE, player_id, "BACK",
            player_id );

    display_vote_menu( true, player_id, menu_body, menuKeys );
    LOGGER( 4, "%48s", " ( dispaly_the_vote_sub_menu| out )" )
}

stock processSubMenuKeyHit( player_id, key )
{
    switch( key )
    {
        case 0: // key 1
        {
            // None option
            register_vote( player_id, 9 );
        }
        case 2: // key 3
        {
            // Cancel vote option
            if( !g_isPlayerCancelledVote[ player_id ] )
            {
                cancel_player_vote( player_id );
            }
        }
        case 4: // key 5
        {
            // Exit option
            g_isPlayerClosedTheVoteMenu[ player_id ] = true;
            return;
        }
    }

    reshowTheVoteMenu( player_id );
}

stock addExtensionOption( player_id, copiedChars, voteStatus[], voteStatusLenght, menuKeys, bool:isToAddResults = true )
{
    LOGGER( 4, "I AM ENTERING ON calculateExtensionOption(6) player_id: %d", player_id )
    LOGGER( 4, "( calculateExtensionOption ) voteStatusLenght: %d, menuKeys: %d", voteStatusLenght, menuKeys )
    LOGGER( 4, "( calculateExtensionOption ) copiedChars: %d, voteStatus: %s",  copiedChars, voteStatus )

    new bool:allowStay;
    new bool:allowExtend;
    new mapVotingCount[ MAX_MAPNAME_LENGHT ];

    allowExtend = ( g_isGameFinalVoting
                    && !( g_voteStatus & IS_RUNOFF_VOTE ) );

    allowStay = ( g_isMapExtensionAllowed
                  && !( g_voteStatus & IS_RUNOFF_VOTE ) );

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

    LOGGER( 4, "    ( vote_handleDisplay ) Add optional menu item allowStay: %d, allowExtend: %d, \
           g_isExtendmapAllowStay: %d", allowStay, allowExtend, g_isExtendmapAllowStay )

    // add optional menu item
    if( g_isMapExtensionAllowed
        && ( allowExtend
             || allowStay ) )
    {
        // if it's not a runoff vote, add a space between the maps and the additional option
        if( !( g_voteStatus & IS_RUNOFF_VOTE ) )
        {
            copiedChars += formatex( voteStatus[ copiedChars ], voteStatusLenght - copiedChars, "^n" );
        }

        computeMapVotingCount( mapVotingCount, charsmax( mapVotingCount ), g_totalVoteOptions, isToAddResults );

        // The extension option has priority over the stay here option.
        if( allowExtend )
        {
            new extend_step = 15;
            new extend_option_type[ 32 ];

            // add the "Extend Map" menu item.
            if( g_endVotingType & ( IS_BY_ROUNDS | IS_BY_WINLIMIT ) )
            {
                extend_step = g_extendmapStepRounds;
                copy( extend_option_type, charsmax( extend_option_type ), "GAL_OPTION_EXTEND_ROUND" );
            }
            else if( g_endVotingType & IS_BY_FRAGS )
            {
                extend_step = g_extendmapStepFrags;
                copy( extend_option_type, charsmax( extend_option_type ), "GAL_OPTION_EXTEND_FRAGS" );
            }
            else
            {
                extend_step = g_extendmapStepMinutes;
                copy( extend_option_type, charsmax( extend_option_type ), "GAL_OPTION_EXTEND" );
            }

            copiedChars += formatex( voteStatus[ copiedChars ], voteStatusLenght - copiedChars,
                   "^n%s%i. \
                    %s%L\
                    %s",
                    COLOR_RED, g_totalVoteOptions + 1,
                    COLOR_WHITE, player_id, extend_option_type, g_currentMapName, extend_step,
                    mapVotingCount );
        }
        else
        {
            // add the "Stay Here" menu item
            if( g_extendmapAllowStayType )
            {
                copiedChars += formatex( voteStatus[ copiedChars ], voteStatusLenght - copiedChars,
                       "^n%s%i. \
                        %s%L\
                        %s",
                        COLOR_RED, g_totalVoteOptions + 1,
                        COLOR_WHITE, player_id, "GAL_OPTION_STAY_MAP", g_currentMapName,
                        mapVotingCount );
            }
            else
            {
                copiedChars += formatex( voteStatus[ copiedChars ], voteStatusLenght - copiedChars,
                       "^n%s%i. \
                        %s%L\
                        %s",
                        COLOR_RED, g_totalVoteOptions + 1,
                        COLOR_WHITE, player_id, "GAL_OPTION_STAY",
                        mapVotingCount );
            }
        }

        // Added the extension/stay key option (1 << 2 = key 3, 1 << 3 = key 4, ...)
        menuKeys |= ( 1 << g_totalVoteOptions );
    }

    return menuKeys;
}

stock display_menu_dirt( player_id, menuKeys, bool:isVoteOver, bool:noneIsHidden, voteStatus[] )
{
    LOGGER( 256, "I AM ENTERING ON display_menu_dirt(6) player_id: %d", player_id )
    LOGGER( 256, "( display_menu_dirt ) isVoteOver: %d, voteStatus: %s", isVoteOver, voteStatus )
    LOGGER( 256, "( display_menu_dirt ) menuKeys: %s, noneIsHidden: %d", menuKeys, noneIsHidden )

    new bool:isToShowUndo;
    new bool:isToAddExtraLine;

    // menu showed after voted
    static menuDirty[ MAX_BIG_BOSS_STRING ];

    static voteFooter[ MAX_SHORT_STRING ];
    static menuHeader[ MAX_SHORT_STRING / 2 ];
    static noneOption[ MAX_SHORT_STRING / 2 ];

    menuDirty  [ 0 ] = '^0';
    noneOption [ 0 ] = '^0';
    isToAddExtraLine = ( g_voteStatus & IS_RUNOFF_VOTE
                         || !g_isMapExtensionAllowed );

    isToShowUndo = ( player_id > 0 \
                     && g_voteShowNoneOptionType == CONVERT_NONE_OPTION_TO_CANCEL_LAST_VOTE \
                     && g_isPlayerVoted[ player_id ] \
                     && !g_isPlayerCancelledVote[ player_id ] );

    computeVoteMenuFooter( player_id, voteFooter, charsmax( voteFooter ) );

    // to append it here to always shows it AFTER voting.
    if( isVoteOver )
    {
        // add the header
        formatex( menuHeader, charsmax( menuHeader ), "%s%L",
                COLOR_YELLOW, player_id, "GAL_RESULT" );

        if( g_isToShowSubMenu )
        {
            if( isToAddExtraLine )
            {
                copy( noneOption, charsmax( noneOption ), "^n" );
            }
            else
            {
                copy( noneOption, charsmax( noneOption ), "" );
            }

            formatex( menuDirty, charsmax( menuDirty ),
                   "%s^n%s^n\
                    %s%s0.%s %L^n^n\
                    %s%L",
                    menuHeader, voteStatus,
                    noneOption, COLOR_RED, COLOR_WHITE, player_id, "CMD_MENU",
                    COLOR_YELLOW, player_id, "GAL_VOTE_ENDED" );
        }
        else if( g_isToShowNoneOption
                 && g_voteShowNoneOptionType )
        {
            computeUndoButton( player_id, isToShowUndo, isVoteOver, noneOption, charsmax( noneOption ) );

            formatex( menuDirty, charsmax( menuDirty ),
                   "%s^n%s^n\
                    %s^n^n\
                    %s%L",
                    menuHeader, voteStatus,
                    noneOption,
                    COLOR_YELLOW, player_id, "GAL_VOTE_ENDED" );
        }
        else
        {
            formatex( menuDirty, charsmax( menuDirty ),
                   "%s^n%s^n^n\
                    %s%L",
                    menuHeader, voteStatus,
                    COLOR_YELLOW, player_id, "GAL_VOTE_ENDED" );
        }
    }
    else
    {
        // add the header
        formatex( menuHeader, charsmax( menuHeader ), "%s%L",
                COLOR_YELLOW, player_id, "GAL_CHOOSE" );

        if( g_isToShowSubMenu )
        {
            if( isToAddExtraLine )
            {
                copy( noneOption, charsmax( noneOption ), "^n" );
            }
            else
            {
                copy( noneOption, charsmax( noneOption ), "" );
            }

            formatex( menuDirty, charsmax( menuDirty ),
                   "%s^n%s^n\
                    %s%s0.%s %L\
                    %s",
                    menuHeader, voteStatus,
                    noneOption, COLOR_RED, COLOR_WHITE, player_id, "CMD_MENU",
                    voteFooter );
        }
        else if( g_isToShowNoneOption )
        {
            computeUndoButton( player_id, isToShowUndo, isVoteOver, noneOption, charsmax( noneOption ) );

            // remove the extra space between 'voteStatus' and 'voteFooter', after the 'None' option is hidden
            if( noneIsHidden
                && g_isPlayerVoted[ player_id ] )
            {
                voteFooter[ 0 ] = ' ';
                voteFooter[ 1 ] = ' ';
            }

            formatex( menuDirty, charsmax( menuDirty ),
                   "%s^n%s^n\
                    %s\
                    %s",
                    menuHeader, voteStatus,
                    noneOption,
                    voteFooter );
        }
        else
        {
            formatex( menuDirty, charsmax( menuDirty ),
                   "%s^n%s\
                    %s",
                    menuHeader, voteStatus,
                    voteFooter );
        }
    }

    // Show the dirt menu to the player
    display_vote_menu( false, player_id, menuDirty, menuKeys );
}

stock computeVoteMenuFooter( player_id, voteFooter[], voteFooterSize )
{
    LOGGER( 256, "I AM ENTERING ON computeVoteMenuFooter(3) player_id: %d", player_id )
    LOGGER( 256, "( computeVoteMenuFooter ) voteFooter: %s, voteFooterSize: %d", voteFooter, voteFooterSize )

    new copiedChars;
    copiedChars = copy( voteFooter, voteFooterSize, "^n^n" );

    if( g_isToShowExpCountdown )
    {
        if( ( g_votingSecondsRemaining < 10
              || g_isToShowVoteCounter )
            && ( g_showVoteStatus == SHOW_STATUS_AFTER_VOTE
                 || g_showVoteStatus == SHOW_STATUS_ALWAYS
                 || g_showVoteStatus == SHOW_STATUS_ALWAYS_UNTIL_VOTE ) )
        {
            if( g_votingSecondsRemaining >= 0 )
            {
                formatex( voteFooter[ copiedChars ], voteFooterSize - copiedChars, "%s%L: %s%i",
                        COLOR_WHITE, player_id, "GAL_TIMELEFT", COLOR_RED, g_votingSecondsRemaining + 1 );
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
    LOGGER( 256, "I AM ENTERING ON computeUndoButton(5) player_id: %d", player_id )
    LOGGER( 256, "( computeUndoButton ) isToShowUndo: %d", isToShowUndo )
    LOGGER( 256, "( computeUndoButton ) noneOption: %s, noneOptionSize: %d", noneOption, noneOptionSize )

    new bool:isToAddExtraLine = ( g_voteStatus & IS_RUNOFF_VOTE
                                  || !g_isMapExtensionAllowed );

    if( isToShowUndo )
    {
        formatex( noneOption, noneOptionSize,
               "%s%s\
                0. %s%L",
                isToAddExtraLine ? "^n"       : ""           , COLOR_RED,
                ( isVoteOver     ? COLOR_GREY : COLOR_WHITE ), player_id, "GAL_OPTION_CANCEL_VOTE" );
    }
    else
    {
        if( g_isPlayerCancelledVote[ player_id ] )
        {
            if( g_isPlayerVoted[ player_id ]  )
            {
                formatex( noneOption, noneOptionSize,
                       "%s%s\
                        0. %s%L",
                        isToAddExtraLine ? "^n" : "", COLOR_RED,
                        COLOR_GREY, player_id, "GAL_OPTION_CANCEL_VOTE" );
            }
            else
            {
                formatex( noneOption, noneOptionSize,
                       "%s%s\
                        0. %s%L",
                        isToAddExtraLine ? "^n"       : ""           , COLOR_RED,
                        ( isVoteOver     ? COLOR_GREY : COLOR_WHITE ), player_id, "GAL_OPTION_NONE" );
            }
        }
        else
        {
            switch( g_voteShowNoneOptionType )
            {
                case HIDE_AFTER_USER_VOTE_NONE_OPTION:
                {
                    if( g_isPlayerVoted[ player_id ] )
                    {
                        noneOption[ 0 ] = '^0';
                    }
                    else
                    {
                        formatex( noneOption, noneOptionSize,
                               "%s%s\
                                0. %s%L",
                                isToAddExtraLine ? "^n"       : ""           , COLOR_RED,
                                ( isVoteOver     ? COLOR_GREY : COLOR_WHITE ), player_id, "GAL_OPTION_NONE" );
                    }
                }
                case ALWAYS_KEEP_SHOWING_NONE_OPTION, CONVERT_NONE_OPTION_TO_CANCEL_LAST_VOTE:
                {
                    formatex( noneOption, noneOptionSize,
                           "%s%s\
                            0. %s%L",
                            isToAddExtraLine ? "^n"       : ""           , COLOR_RED,
                            ( isVoteOver     ? COLOR_GREY : COLOR_WHITE ), player_id, "GAL_OPTION_NONE" );
                }
            }
        }
    }
}

stock display_menu_clean( player_id, menuKeys )
{
    LOGGER( 256, "I AM ENTERING ON display_menu_clean(2) player_id: %d", player_id )
    LOGGER( 256, "( display_menu_clean ) menuKeys: %d", menuKeys )

    new bool:isToShowUndo;
    new bool:isToAddExtraLine;

    // menu showed while voting
    static menuClean[ MAX_BIG_BOSS_STRING ];

    static voteFooter   [ MAX_SHORT_STRING ];
    static voteExtension[ MAX_SHORT_STRING ];
    static menuHeader   [ MAX_SHORT_STRING / 2 ];
    static noneOption   [ MAX_SHORT_STRING / 2 ];

    menuClean  [ 0 ] = '^0';
    noneOption [ 0 ] = '^0';
    isToAddExtraLine = ( g_voteStatus & IS_RUNOFF_VOTE
                         || !g_isMapExtensionAllowed );

    isToShowUndo = ( player_id > 0
                     && g_voteShowNoneOptionType == CONVERT_NONE_OPTION_TO_CANCEL_LAST_VOTE
                     && g_isPlayerVoted[ player_id ]
                     && !g_isPlayerCancelledVote[ player_id ] );

    computeVoteMenuFooter( player_id, voteFooter, charsmax( voteFooter ) );
    menuKeys = addExtensionOption( player_id, 0, voteExtension, charsmax( voteExtension ), menuKeys, false );

    // Add the header
    formatex( menuHeader, charsmax( menuHeader ), "%s%L",
            COLOR_YELLOW, player_id, "GAL_CHOOSE" );

    // Append a "None" option on for people to choose if they don't like any other choice to append
    // it here to always shows it WHILE voting.
    if( g_isToShowSubMenu )
    {
        if( isToAddExtraLine )
        {
            copy( noneOption, charsmax( noneOption ), "^n" );
        }
        else
        {
            copy( noneOption, charsmax( noneOption ), "" );
        }

        formatex( menuClean, charsmax( menuClean ),
               "%s^n%s^n\
                %s^n\
                %s%s0.%s %L^n\
                %s",
                menuHeader, g_voteStatusClean,
                voteExtension,
                noneOption, COLOR_RED, COLOR_WHITE, player_id, "CMD_MENU",
                voteFooter );
    }
    else if( g_isToShowNoneOption )
    {
        if( isToShowUndo )
        {
            copy( noneOption, charsmax( noneOption ), "GAL_OPTION_CANCEL_VOTE" );
        }
        else
        {
            copy( noneOption, charsmax( noneOption ), "GAL_OPTION_NONE" );
        }

        formatex( menuClean, charsmax( menuClean ),
               "%s^n%s^n\
                %s^n\
                %s%s0. %s%L\
                %s",
                menuHeader, g_voteStatusClean,
                voteExtension,
                isToAddExtraLine ? "^n" : "", COLOR_RED, COLOR_WHITE, player_id, noneOption,
                voteFooter );
    }
    else
    {
        formatex( menuClean, charsmax( menuClean ),
               "%s^n%s\
                %s^n\
                %s",
                menuHeader, g_voteStatusClean,
                voteExtension,
                voteFooter );
    }

    // Show the dirt menu to the player
    display_vote_menu( true, player_id, menuClean, menuKeys );
}

stock display_vote_menu( bool:menuType, player_id, menuBody[], menuKeys )
{
    LOGGER( 128, "I AM ENTERING ON display_vote_menu(4) menuType: %d", menuType )
    LOGGER( 4, "( display_vote_menu ) player_id: %d", player_id )
    LOGGER( 4, "( display_vote_menu ) menuBody: %s, menuKeys: %d", menuBody, menuKeys )

    if( isPlayerAbleToSeeTheVoteMenu( player_id ) )
    {
        show_menu( player_id, menuKeys, menuBody,
                ( menuType ? g_votingSecondsRemaining : max( 2, g_votingSecondsRemaining ) ),
                CHOOSE_MAP_MENU_NAME );
    }
}

stock isPlayerAbleToSeeTheVoteMenu( player_id )
{
    LOGGER( 128, "I AM ENTERING ON isPlayerAbleToSeeTheVoteMenu(1) player_id: %d", player_id )

    new menu_id;
    new menuKeys_unused;

    get_user_menu( player_id, menu_id, menuKeys_unused );

    return ( menu_id == 0
             || menu_id == g_chooseMapMenuId
             || get_pcvar_num( cvar_isToReplaceByVoteMenu ) != 0 );
}

public vote_handleChoice( player_id, key )
{
    LOGGER( 128, "I AM ENTERING ON vote_handleChoice(2) player_id: %d, key: %d", player_id, key )

    if( g_voteStatus & IS_VOTE_EXPIRED )
    {
        client_cmd( player_id, "^"slot%i^"", key + 1 );

        LOGGER( 1, "    ( vote_handleChoice ) Just Returning/blocking, slot key pressed." )
        return;
    }

    if( g_isToShowSubMenu
        && key == 9 )
    {
        if( g_isPlayerSeeingTheSubMenu[ player_id ] )
        {
            g_isPlayerSeeingTheSubMenu[ player_id ] = false;
        }
        else
        {
            g_isPlayerSeeingTheSubMenu[ player_id ] = true;
        }

        reshowTheVoteMenu( player_id );
        return;
    }
    else if( g_isPlayerSeeingTheSubMenu[ player_id ] )
    {
        processSubMenuKeyHit( player_id, key );
        return;
    }
    else if( !g_isPlayerVoted[ player_id ] )
    {
        register_vote( player_id, key );
    }
    else if( key == 9
             && !g_isPlayerCancelledVote[ player_id ]
             && g_voteShowNoneOptionType == CONVERT_NONE_OPTION_TO_CANCEL_LAST_VOTE
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
        reshowTheVoteMenu( player_id );
    }
    else if( g_isPlayerVoted[ player_id ]
             && g_showVoteStatus == SHOW_STATUS_ALWAYS_UNTIL_VOTE
             && isPlayerAbleToSeeTheVoteMenu( player_id ) )
    {
        // Some times the menu does not exit after voting. So, override manually.
        show_menu( player_id, 1, ".", 1, CHOOSE_MAP_MENU_NAME );
    }
}

stock reshowTheVoteMenu( player_id )
{
    new argument[ 2 ];

    argument[ 0 ] = false;
    argument[ 1 ] = player_id;

    set_task( 0.1, "vote_display", TASKID_VOTE_DISPLAY, argument, sizeof argument );
}

stock cancel_player_vote( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cancel_player_vote(1) player_id: %d", player_id )
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
    LOGGER( 128, "I AM ENTERING ON register_vote(2) player_id: %d, pressedKeyCode: %d", player_id, pressedKeyCode )

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

            color_print( player_id, "%L", player_id, "GAL_VOTE_WEIGHTED", voteWeight );
        }
        else
        {
            g_arrayOfMapsWithVotesNumber[ pressedKeyCode ]++;
        }
    }
}

stock announceRegistedVote( player_id, pressedKeyCode )
{
    LOGGER( 128, "I AM ENTERING ON announceRegistedVote(2) player_id: %d, pressedKeyCode: %d", player_id, pressedKeyCode )

    new player_name[ MAX_PLAYER_NAME_LENGHT ];
    new bool:isToAnnounceChoice = get_pcvar_num( cvar_voteAnnounceChoice ) != 0;

    if( isToAnnounceChoice )
    {
        GET_USER_NAME( player_id, player_name )
    }

    // confirm the player's choice (pressedKeyCode = 9 means 0 on the keyboard, 8 is 7, etc)
    if( pressedKeyCode == 9 )
    {
        LOGGER( 4, "      %-32s ( none )", player_name )

        if( isToAnnounceChoice )
        {
            color_print( 0, "%L", LANG_PLAYER, "GAL_CHOICE_NONE_ALL", player_name );
        }
        else
        {
            color_print( player_id, "%L", player_id, "GAL_CHOICE_NONE" );
        }
    }
    else if( pressedKeyCode == g_totalVoteOptions )
    {
        // only display the "none" vote if we haven't already voted
        // ( we can make it here from the vote status menu too )
        if( !g_isPlayerVoted[ player_id ] )
        {
            LOGGER( 4, "      %-32s ( extend )", player_name )

            if( g_isGameFinalVoting )
            {
                if( isToAnnounceChoice )
                {
                    color_print( 0, "%L", LANG_PLAYER, "GAL_CHOICE_EXTEND_ALL", player_name );
                }
                else
                {
                    color_print( player_id, "%L", player_id, "GAL_CHOICE_EXTEND" );
                }
            }
            else
            {
                if( isToAnnounceChoice )
                {
                    color_print( 0, "%L", LANG_PLAYER, "GAL_CHOICE_STAY_ALL", player_name );
                }
                else
                {
                    color_print( player_id, "%L", player_id, "GAL_CHOICE_STAY" );
                }
            }
        }
    }
    else
    {
        LOGGER( 4, "      %-32s %s", player_name, g_votingMapNames[ pressedKeyCode ] )

        if( isToAnnounceChoice )
        {
            color_print( 0, "%L", LANG_PLAYER, "GAL_CHOICE_MAP_ALL",
                    player_name, g_votingMapNames[ pressedKeyCode ] );
        }
        else
        {
            color_print( player_id, "%L", player_id, "GAL_CHOICE_MAP",
                    g_votingMapNames[ pressedKeyCode ] );
        }
    }
}

stock computeMapVotingCount( mapVotingCount[], mapVotingCountLength, voteIndex, bool:isToAddResults = true )
{
    LOGGER( 256, "I AM ENTERING ON computeMapVotingCount(3) mapVotingCount: %s, mapVotingCountLength: %d, \
            voteIndex: %d", mapVotingCount, mapVotingCountLength, voteIndex )

    new voteCountNumber = g_arrayOfMapsWithVotesNumber[ voteIndex ];

    if( voteCountNumber
        && isToAddResults
        && g_showVoteStatus )
    {
        switch( g_showVoteStatusType )
        {
            case STATUS_TYPE_COUNT:
            {
                formatex( mapVotingCount, mapVotingCountLength, " %s(%s%i%s%s)",
                        COLOR_YELLOW, COLOR_GREY,
                        voteCountNumber, g_voteStatus_symbol,
                        COLOR_YELLOW );
            }
            case STATUS_TYPE_PERCENTAGE:
            {
                new votePercentNunber = percent( voteCountNumber, g_totalVotesCounted );

                formatex( mapVotingCount, mapVotingCountLength, " %s(%s%i%s%s)",
                        COLOR_YELLOW, COLOR_GREY,
                        votePercentNunber, g_voteStatus_symbol,
                        COLOR_YELLOW );
            }
            case STATUS_TYPE_PERCENTAGE | STATUS_TYPE_COUNT:
            {
                new votePercentNunber = percent( voteCountNumber, g_totalVotesCounted );

                formatex( mapVotingCount, mapVotingCountLength,
                        " %s(%s%i%s %s[%s%d%s]%s)",
                        COLOR_RED, COLOR_GREY,
                        votePercentNunber, g_voteStatus_symbol,
                        COLOR_YELLOW, COLOR_GREY,
                        voteCountNumber, COLOR_YELLOW,
                        COLOR_RED );
            }
            default:
            {
                mapVotingCount[ 0 ] = '^0';
            }
        }
    }
    else
    {
        mapVotingCount[ 0 ] = '^0';
    }

    LOGGER( 256, " ( computeMapVotingCount ) g_showVoteStatus: %d, g_showVoteStatusType: %d, voteCountNumber: %d", \
            g_showVoteStatus, g_showVoteStatusType, voteCountNumber )
}

stock showPlayersVoteResult()
{
    LOGGER( 128, "I AM ENTERING ON showPlayersVoteResult(0)" )
    new mapVotingCount[ 32 ];

    LOGGER( 4, "" )
    LOGGER( 4, "   [VOTE RESULT]" )

    for( new playerVoteMapChoiceIndex = 0; playerVoteMapChoiceIndex <= g_totalVoteOptions;
         ++playerVoteMapChoiceIndex )
    {
        computeMapVotingCount( mapVotingCount, charsmax( mapVotingCount ), playerVoteMapChoiceIndex );

        LOGGER( 4, "      %2i/%-2i, %i. %s %s", \
                g_arrayOfMapsWithVotesNumber[ playerVoteMapChoiceIndex ], g_totalVotesCounted, \
                playerVoteMapChoiceIndex, g_votingMapNames[ playerVoteMapChoiceIndex ], \
                g_votingMapInfos[ playerVoteMapChoiceIndex ] )
    }

    LOGGER( 4, "" )
    return 0;
}

/**
 * Get unique random numbers between a minimum until maximum. For now this function is used on the
 * source code. It is here for historical purposes only. It was previously created for use but its
 * used was deprecated. Now it can be used for implementation comparison between its sister function
 * getUniqueRandomIntegerBasic(2) just bellow.
 *
 * If the `maximum`'s change between the function calls, the unique random number sequence will be
 * restarted to this new maximum value. Also after the maximum value been reached, the random unique
 * sequence will be restarted and a new unique random number sequence will be generated.
 *
 * If your `maximum` parameter value is not 0, you can to reset the sequence manually just to calling
 * this function as `getUniqueRandomInteger( holder )` or using some the `maximum` parameter value.
 * The random generated range is:
 *
 *     minimum <= return value <= maximum
 *
 * 1. Do not forgot the call ArrayCreate() for the `holder` parameter before calling this function,
 *    and to call ArrayDestroy(1) for the `holder` parameter after you finished using this function.
 * 2. Do not change the minimum value without changing at the same time the maximum value, otherwise
 *    you will still get number at the old minimum value starting range.
 * 3. This algorithm complexity is linear `O( n )` for the first call and when the random generated
 *    sequence is restarted. The further function calls has constant `O( 1 )` complexity.
 *
 * @param holder      an initially empty Dynamic Array used for internal purposes.
 * @param minimum     the inclusive lower bound limit, i.e., the minimum value to be sorted.
 * @param maximum     the inclusive upper bound limit, i.e., the maximum value to be sorted.
 * @param restart     if false, the sequence will not be automatically restarted and will to start
 *                    returning the value -1;
 *
 * @return an unique random integer until the `maximum` parameter value.
 */
stock getUniqueRandomInteger( Array:holder, minimum = MIN_INTEGER, maximum = MIN_INTEGER, restart = true )
{
    LOGGER( 128, "I AM ENTERING ON getUniqueRandomInteger(2) range: %d-%d", minimum, maximum )
    static lastMaximum = MIN_INTEGER;

    new randomIndex;
    new returnValue;
    new holderSize = ArraySize( holder );

    if( lastMaximum != maximum
        || ( restart
             && holderSize < 1 ) )
    {
        LOGGER( 1, "( getUniqueRandomInteger ) Reseting the sequence, ArraySize: %d", holderSize )

        lastMaximum = maximum;
        ArrayClear( holder );

        for( new index = minimum; index <= maximum; index++ )
        {
            ArrayPushCell( holder, index );
        }

        holderSize = ArraySize( holder );
    }
    else if( holderSize < 1 )
    {
        return -1;
    }

    LOGGER( 1, "( getUniqueRandomInteger ) ArraySize: %d", ArraySize( holder ) )
    --holderSize;

    // Get a unique random value
    randomIndex = random_num( 0, holderSize );
    returnValue = ArrayGetCell( holder, randomIndex );

    // Swap the random value from the middle of the array to the last position, reduces the removal
    // complexity from linear `O( n )` to constant `O( 1 )`.
    ArraySwap( holder, randomIndex, holderSize );
    ArrayDeleteItem( holder, holderSize );

    LOGGER( 1, "    ( getUniqueRandomInteger ) %d. Just Returning the random integer: %d", holderSize, returnValue )
    return returnValue;
}

/**
 * Get unique random positive numbers between 0 until 31. If the `maximum`'s parameter value
 * provided is greater than 31, the generated numbers will not be unique. The range is:
 *
 *     0 <= return value <= maximum <= 31
 *
 * @param sequence     a random positive number to reset the current unique return values.
 * @param maximum      the upper bound limit, i.e., the maximum value to be sorted.
 *
 * @return -1 when there are not new unique positive numbers to return.
 */
stock getUniqueRandomIntegerBasic( sequence, maximum )
{
    LOGGER( 128, "I AM ENTERING ON getUniqueRandomIntegerBasic(2) maximum: %d", maximum )
    static maximumBitField;

    static lastSequence   = -1;
    static sortedIntegers = 0;

    if( lastSequence != sequence )
    {
        lastSequence    = sequence;
        sortedIntegers  = 0;
        maximumBitField = 0;

        for( new index = 0; index < maximum + 1; index++ )
        {
            maximumBitField |= ( 1 << index );
        }
    }

    new randomInteger;

    // Keep looping while there is numbers that haven't yet been selected.
    while( sortedIntegers != maximumBitField )
    {
        randomInteger = random_num( 0, maximum );

        // If the number has not yet been selected yet
        if( !( sortedIntegers & ( 1 << randomInteger ) ) )
        {
            // Set bit on the sortedIntegers bit-field, so the integer will now be considered selected
            sortedIntegers |= ( 1 << randomInteger );

            LOGGER( 1, "    ( getUniqueRandomIntegerBasic ) %d. Just Returning the random integer: %d", sequence, randomInteger )
            return randomInteger;
        }
    }

    LOGGER( 1, "    ( getUniqueRandomIntegerBasic ) %d. Just Returning the random integer: %d", sequence, -1 )
    return -1;
}

stock printIntegerArray( level, integerArray[], arrayName[], integerArraySize )
{
    LOGGER( 128, "I AM ENTERING ON printIntegerArray(4) integerArraySize: %d", integerArraySize )

    for( new index = 0; index < integerArraySize; index++ )
    {
        LOGGER( level, "( printIntegerArray ) %s: %d", arrayName, integerArray[ index ] )
    }

    return 0;
}

stock printRunOffMaps( runOffMapsCount )
{
    LOGGER( 128, "I AM ENTERING ON printRunOffMaps(1) runOffMapsCount: %d", runOffMapsCount )

    for( new index = 0; index < runOffMapsCount; index++ )
    {
        LOGGER( 16, "( printRunOffMaps ) RunOff map %d: %s", index, g_votingMapNames[ g_arrayOfRunOffChoices[ index ] ] )
    }

    return 0;
}

stock handleMoreThanTwoMapsAtFirst( firstPlaceChoices[], numberOfMapsAtFirstPosition )
{
    LOGGER( 128, "I AM ENTERING ON handleMoreThanTwoMapsAtFirst(2)" )
    LOGGER( 0, "", printIntegerArray( 16, firstPlaceChoices, "firstPlaceChoices", numberOfMapsAtFirstPosition ) )

    new seedValue;
    new randomInteger;
    new maxVotingChoices;
    new originalTotalVotingOptions;

    // This only valid for the runoff voting. Do not use MAX_VOTING_CHOICES(0) here.
    maxVotingChoices = min( MAX_OPTIONS_IN_VOTE, get_pcvar_num( cvar_runoffMapchoices ) );
    maxVotingChoices = max( min( maxVotingChoices, numberOfMapsAtFirstPosition ), 2 );

    originalTotalVotingOptions = g_totalVoteOptions;
    g_totalVoteOptions         = maxVotingChoices;

    // Get an unique identification for the seed sequence value
    seedValue = abs( get_systime() );

    for( new voteOptionIndex = 0; voteOptionIndex < maxVotingChoices; voteOptionIndex++ )
    {
        randomInteger = getUniqueRandomIntegerBasic( seedValue, maxVotingChoices );

        // If firstPlaceChoices[ numberOfMapsAtFirstPosition - 1 ]  is equal to
        // g_totalVoteOptions then it option is not a valid map, it is the keep current
        // map option, and must be informed it to the vote_display function, to show the
        // 1 map options and the keep current map.
        if( firstPlaceChoices[ randomInteger ] == originalTotalVotingOptions )
        {
            g_totalVoteOptions--;
            g_isRunOffNeedingKeepCurrentMap = true;
        }

        g_arrayOfRunOffChoices[ voteOptionIndex ] = firstPlaceChoices[ randomInteger ];
    }

    LOGGER( 16, "( handleMoreThanTwoMapsAtFirst ) Number of Maps at First Position > 2" )
    LOGGER( 0, "", printRunOffMaps( g_totalVoteOptions ) )

    color_print( 0, "%L", LANG_PLAYER, "GAL_RESULT_TIED1", numberOfMapsAtFirstPosition );
}

stock startRunoffVoting( firstPlaceChoices[], secondPlaceChoices[], numberOfMapsAtFirstPosition,
                         numberOfMapsAtSecondPosition )
{
    LOGGER( 128, "I AM ENTERING ON startRunoffVoting(4)" )
    new votePercent = floatround( 100 * get_pcvar_float( cvar_runoffRatio ), floatround_ceil );

    // announce runoff voting requirement
    color_print( 0, "%L", LANG_PLAYER, "GAL_RUNOFF_REQUIRED", votePercent );

    if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_RUNOFF_REQUIRED ) )
    {
        client_cmd( 0, "spk ^"run officer( e40 ) voltage( e30 ) accelerating( s70 ) \
                is required^"" );
    }

    // let the server know the next vote will be a runoff
    g_voteStatus |= IS_RUNOFF_VOTE;

    if( numberOfMapsAtFirstPosition > 2 )
    {
        handleMoreThanTwoMapsAtFirst( firstPlaceChoices, numberOfMapsAtFirstPosition );
    }
    else if( numberOfMapsAtFirstPosition == 2 )
    {
        handleTwoMapsAtFirstPosition( firstPlaceChoices );
    }
    // If `numberOfMapsAtFirstPosition` is not greater than 2, neither equal to 2, therefore it is 1.
    else if( numberOfMapsAtSecondPosition == 1 )
    {
        handleOneMapAtSecondPosition( firstPlaceChoices, secondPlaceChoices );
    }
    else // numberOfMapsAtFirstPosition == 1 && numberOfMapsAtSecondPosition > 1
    {
        handleOneMapAtFirstPosition( firstPlaceChoices, secondPlaceChoices, numberOfMapsAtSecondPosition );
    }

    // clear all the votes
    vote_resetStats();

    // start the runoff vote, vote_startDirector
    set_task( VOTE_TIME_RUNOFF, "startNonForcedVoting", TASKID_VOTE_STARTDIRECTOR );
}

stock handleTwoMapsAtFirstPosition( firstPlaceChoices[] )
{
    LOGGER( 128, "I AM ENTERING ON handleTwoMapsAtFirstPosition(1)" )

    if( firstPlaceChoices[ 0 ] == g_totalVoteOptions )
    {
        g_isRunOffNeedingKeepCurrentMap = true;
        g_arrayOfRunOffChoices[ 0 ]     = firstPlaceChoices[ 1 ];
        g_totalVoteOptions              = 1;
    }
    else if( firstPlaceChoices[ 1 ] == g_totalVoteOptions )
    {
        g_isRunOffNeedingKeepCurrentMap = true;
        g_arrayOfRunOffChoices[ 0 ]     = firstPlaceChoices[ 0 ];
        g_totalVoteOptions              = 1;
    }
    else
    {
        g_totalVoteOptions          = 2;
        g_arrayOfRunOffChoices[ 0 ] = firstPlaceChoices[ 0 ];
        g_arrayOfRunOffChoices[ 1 ] = firstPlaceChoices[ 1 ];
    }

    LOGGER( 16, "( handleTwoMapsAtFirstPosition ) Number of Maps at First Position == 2" )
    LOGGER( 0, "", printRunOffMaps( g_totalVoteOptions ) )
}

stock handleOneMapAtSecondPosition( firstPlaceChoices[], secondPlaceChoices[] )
{
    LOGGER( 128, "I AM ENTERING ON handleOneMapAtSecondPosition(2)" )

    if( firstPlaceChoices[ 0 ] == g_totalVoteOptions )
    {
        g_isRunOffNeedingKeepCurrentMap = true;
        g_arrayOfRunOffChoices[ 0 ]     = secondPlaceChoices[ 0 ];
        g_totalVoteOptions              = 1;
    }
    else if( secondPlaceChoices[ 0 ] == g_totalVoteOptions )
    {
        g_isRunOffNeedingKeepCurrentMap = true;
        g_arrayOfRunOffChoices[ 0 ]     = firstPlaceChoices[ 0 ];
        g_totalVoteOptions              = 1;
    }
    else
    {
        g_totalVoteOptions          = 2;
        g_arrayOfRunOffChoices[ 0 ] = firstPlaceChoices[ 0 ];
        g_arrayOfRunOffChoices[ 1 ] = secondPlaceChoices[ 0 ];
    }

    LOGGER( 16, "( handleOneMapAtSecondPosition ) Number of Maps at Second Position == 1" )
    LOGGER( 0, "", printRunOffMaps( g_totalVoteOptions ) )
}

/**
 * Do not implement the feature below here in:
 *
 *     Another CVAR for the number of maps to be included in runoff voting.
 *     https://github.com/addonszz/Galileo/issues/33
 *
 * It is because it will cause complications as when there is only one player at the server. If the
 * player vote for one map, it will cause this option to be triggered:
 *
 *     numberOfMapsAtFirstPosition == 1 && numberOfMapsAtSecondPosition > 1
 *
 * And then a run off voting would be triggered when there is only one player at the server.
 */
stock handleOneMapAtFirstPosition( firstPlaceChoices[], secondPlaceChoices[], numberOfMapsAtSecondPosition )
{
    LOGGER( 128, "I AM ENTERING ON handleOneMapAtFirstPosition(3)" )
    new randonNumber = random_num( 0, numberOfMapsAtSecondPosition - 1 );

    if( firstPlaceChoices[ 0 ] == g_totalVoteOptions )
    {
        g_isRunOffNeedingKeepCurrentMap = true;
        g_arrayOfRunOffChoices[ 0 ]     = secondPlaceChoices[ randonNumber ];
        g_totalVoteOptions              = 1;
    }
    else if( secondPlaceChoices[ randonNumber ] == g_totalVoteOptions )
    {
        g_isRunOffNeedingKeepCurrentMap = true;
        g_arrayOfRunOffChoices[ 0 ]     = firstPlaceChoices[ 0 ];
        g_totalVoteOptions              = 1;
    }
    else
    {
        g_totalVoteOptions          = 2;
        g_arrayOfRunOffChoices[ 0 ] = firstPlaceChoices[ 0 ];
        g_arrayOfRunOffChoices[ 1 ] = secondPlaceChoices[ randonNumber ];
    }

    LOGGER( 16, "( handleOneMapAtFirstPosition ) Number of Maps at First Position == 1 && At Second Position > 1" )
    LOGGER( 0, "", printRunOffMaps( g_totalVoteOptions ) )

    color_print( 0, "%L", LANG_PLAYER, "GAL_RESULT_TIED2", numberOfMapsAtSecondPosition );
}

stock determineTheVotingFirstChoices( firstPlaceChoices[], secondPlaceChoices[], &numberOfVotesAtFirstPlace,
                                      &numberOfVotesAtSecondPlace, &numberOfMapsAtFirstPosition,
                                      &numberOfMapsAtSecondPosition )
{
    LOGGER( 128, "I AM ENTERING ON determineTheVotingFirstChoices(6)" )

    new playerVoteMapChoiceIndex;
    new bool:isRunoffVoting = ( g_voteStatus & IS_RUNOFF_VOTE ) != 0;

    // Determine how much maps it should look up to, considering whether there is the option
    // `Stay Here` or `Extend` displayed on the voting menu.
    new maxVotingChoices = g_totalVoteOptions >= MAX_OPTIONS_IN_VOTE ? g_totalVoteOptions :
            ( g_isMapExtensionAllowed && !isRunoffVoting ? ( g_totalVoteOptions + 1 ) :
                ( g_isRunOffNeedingKeepCurrentMap        ? ( g_totalVoteOptions + 1 ) : g_totalVoteOptions ) );

    // determine the number of votes for 1st and 2nd places
    for( playerVoteMapChoiceIndex = 0; playerVoteMapChoiceIndex < maxVotingChoices;
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
    for( playerVoteMapChoiceIndex = 0; playerVoteMapChoiceIndex < maxVotingChoices;
         ++playerVoteMapChoiceIndex )
    {
        LOGGER( 16, "Inside the for to determine which maps are in 1st and 2nd places, \
                g_arrayOfMapsWithVotesNumber[%d] = %d ", playerVoteMapChoiceIndex, \
                g_arrayOfMapsWithVotesNumber[ playerVoteMapChoiceIndex ] )

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
    LOGGER( 16, "After for to determine which maps are in 1st and 2nd places." )
    LOGGER( 16, "maxVotingChoices: %d, isRunoffVoting: %d", maxVotingChoices, isRunoffVoting )
    LOGGER( 16, "g_totalVoteOptions: %d", g_totalVoteOptions )
    LOGGER( 16, "numberOfMapsAtFirstPosition: %d", numberOfMapsAtFirstPosition )
    LOGGER( 16, "numberOfMapsAtSecondPosition: %d", numberOfMapsAtSecondPosition )

    LOGGER( 1, "( determineTheVotingFirstChoices ) g_isTheLastGameRound: %d", g_isTheLastGameRound )
    LOGGER( 1, "( determineTheVotingFirstChoices ) g_isTimeToRestart: %d", g_isTimeToRestart )
    LOGGER( 1, "( determineTheVotingFirstChoices ) g_voteStatus & IS_FORCED_VOTE: %d", g_voteStatus & IS_FORCED_VOTE != 0 )
}

public computeVotes()
{
    LOGGER( 128, "I AM ENTERING ON computeVotes(0)" )
    LOGGER( 0, "", showPlayersVoteResult() )

    new numberOfVotesAtFirstPlace;
    new numberOfVotesAtSecondPlace;

    // retain the number of draw maps at first and second positions
    new numberOfMapsAtFirstPosition;
    new numberOfMapsAtSecondPosition;

    new firstPlaceChoices [ MAX_OPTIONS_IN_VOTE ];
    new secondPlaceChoices[ MAX_OPTIONS_IN_VOTE ];

    determineTheVotingFirstChoices( firstPlaceChoices, secondPlaceChoices, numberOfVotesAtFirstPlace,
            numberOfVotesAtSecondPlace, numberOfMapsAtFirstPosition, numberOfMapsAtSecondPosition );

    new runoffEnabled= get_pcvar_num( cvar_runoffEnabled );

    // announce the outcome
    if( numberOfVotesAtFirstPlace )
    {
        // if the top vote getting map didn't receive over 50% of the votes cast, to start a runoff vote
        if( numberOfVotesAtFirstPlace <= g_totalVotesCounted * get_pcvar_float( cvar_runoffRatio ) )
        {
            if( runoffEnabled == RUNOFF_ENABLED
                && !( g_voteStatus & IS_RUNOFF_VOTE )
                && !( g_voteMapStatus & IS_DISABLED_VOTEMAP_RUNOFF ) )
            {
                startRunoffVoting( firstPlaceChoices, secondPlaceChoices, numberOfMapsAtFirstPosition,
                        numberOfMapsAtSecondPosition );

                LOGGER( 1, "    ( computeVotes ) Just Returning/blocking, its runoff starting." )
                return;
            }
            else if( runoffEnabled == RUNOFF_EXTEND )
            {
                map_extend( "GAL_WINNER_NO_ONE_VOTED" );
                LOGGER( 1, "( computeVotes ) Its runoff extending." )
            }
            else
            {
                chooseTheVotingMapWinner( firstPlaceChoices, numberOfMapsAtFirstPosition );
            }
        }
        else
        {
            chooseTheVotingMapWinner( firstPlaceChoices, numberOfMapsAtFirstPosition );
        }
    }
    else // the execution flow gets here when anybody voted for next map
    {
        chooseRandomVotingWinner();
    }

    LOGGER( 1, "    ( computeVotes|out ) g_isTheLastGameRound: %d", g_isTheLastGameRound )
    LOGGER( 1, "    ( computeVotes|out ) g_isTimeToRestart: %d, g_voteStatus & IS_FORCED_VOTE: %d", \
            g_isTimeToRestart, g_voteStatus & IS_FORCED_VOTE != 0 )

    finalizeVoting();
}

stock chooseTheVotingMapWinner( firstPlaceChoices[], numberOfMapsAtFirstPosition )
{
    LOGGER( 128, "I AM ENTERING ON chooseTheVotingMapWinner(2)" )
    new winnerVoteMapIndex;

    // If there is a tie for 1st, randomly select one as the winner
    if( numberOfMapsAtFirstPosition > 1 )
    {
        // This message and others like it, does not need a HUD because they are not the last ones
        // to be displayed, i.e., soon a new ending message within a HUD will be show.
        winnerVoteMapIndex = firstPlaceChoices[ random_num( 0, numberOfMapsAtFirstPosition - 1 ) ];
        color_print( 0, "%L", LANG_PLAYER, "GAL_WINNER_TIED", numberOfMapsAtFirstPosition );
    }
    else
    {
        winnerVoteMapIndex = firstPlaceChoices[ 0 ];
    }

    LOGGER( 1, "    ( chooseTheVotingMapWinner ) g_isTheLastGameRound: %d ", g_isTheLastGameRound )
    LOGGER( 1, "    ( chooseTheVotingMapWinner ) g_isTimeToRestart: %d, g_voteStatus & IS_FORCED_VOTE: %d", \
            g_isTimeToRestart, g_voteStatus & IS_FORCED_VOTE != 0 )

    // winnerVoteMapIndex == g_totalVoteOptions, means the 'Stay Here' option.
    // Then, here we keep the current map or extend current map.
    if( winnerVoteMapIndex == g_totalVoteOptions )
    {
        if( !g_isGameFinalVoting // "stay here" won and the map mustn't be restarted.
            && !g_isTimeToRestart )
        {
            // While the `IS_DISABLED_VOTEMAP_EXIT` bit flag is set, we cannot allow any decisions
            if( g_voteMapStatus & IS_DISABLED_VOTEMAP_EXIT )
            {
                // When the stay here option is called, there is anyone else trying to show action menu,
                // therefore invoke it before continuing.
                openTheVoteMapActionMenu();
                LOGGER( 1, "    ( chooseTheVotingMapWinner ) Just opened the menu due g_voteMapStatus: %d", g_voteMapStatus )
            }

            color_print( 0, "%L: %L", LANG_PLAYER, "DMAP_MAP_EXTENDED", LANG_PLAYER, "GAL_WINNER_STAY2" );
            toShowTheMapStayHud( "GAL_VOTE_ENDED", "DMAP_MAP_EXTENDED", "GAL_WINNER_STAY1" );

            // However here, none decisions are being made. Anyways, we cannot block the execution
            // right here without executing the remaining code.
            noLongerIsAnEarlyVoting();
        }
        else if( !g_isGameFinalVoting // "stay here" won and the map must be restarted.
                 && g_isTimeToRestart )
        {
            // This message does not need HUD's because immediately the map will be changed immediately.
            color_print( 0, "%L", LANG_PLAYER, "GAL_WINNER_STAY2" );

            noLongerIsAnEarlyVoting();
            process_last_round( g_isToChangeMapOnVotingEnd, false );
        }
        else if( g_isGameFinalVoting ) // "extend map" won
        {
            map_extend( "GAL_VOTE_ENDED" );
        }
    }
    else // The execution flow gets here when the winner option is not keep/extend map
    {
        setNextMap( g_currentMapName, g_votingMapNames[ winnerVoteMapIndex ] );
        server_exec();

        g_voteStatus |= IS_VOTE_OVER;

        color_print( 0, "%L: %L", LANG_PLAYER, "DMAP_MAP_EXTENDED", LANG_PLAYER, "GAL_NEXTMAP2", g_nextMapName );
        toShowTheMapNextHud( "GAL_VOTE_ENDED", "DMAP_MAP_EXTENDED", "GAL_NEXTMAP1", g_nextMapName );

        process_last_round( g_isToChangeMapOnVotingEnd );
    }
}

stock noLongerIsAnEarlyVoting()
{
    LOGGER( 128, "I AM ENTERING ON noLongerIsAnEarlyVoting(0)" )

    // We are extending the map as result of the voting outcome, so reset the ending round variables.
    resetRoundEnding();

    // no longer is an early or forced voting
    g_voteStatus &= ~IS_EARLY_VOTE;
    g_voteStatus &= ~IS_FORCED_VOTE;
}

stock chooseRandomVotingWinner()
{
    LOGGER( 128, "I AM ENTERING ON chooseRandomVotingWinner(1) isExtendmapOrderAllowed: %d", get_pcvar_num( cvar_isExtendmapOrderAllowed ) )

    switch( get_pcvar_num( cvar_isExtendmapOrderAllowed ) )
    {
        // 1 - follow your current map-cycle order
        case 1:
        {
            g_voteStatus |= IS_VOTE_OVER;

            color_print( 0, "%L. %L", LANG_PLAYER, "GAL_WINNER_NO_ONE_VOTED", LANG_PLAYER, "GAL_WINNER_ORDERED2", g_nextMapName );
            toShowTheMapNextHud( "GAL_WINNER_NO_ONE_VOTED", "DMAP_MAP_EXTENDED", "GAL_WINNER_ORDERED1", g_nextMapName );

            // Need to be called to trigger special behaviors.
            setNextMap( g_currentMapName, g_nextMapName );
            process_last_round( g_isToChangeMapOnVotingEnd );
        }
        // 2 - extend the current map
        case 2:
        {
            // When called, to trigger the special behaviors.
            map_extend( "GAL_WINNER_NO_ONE_VOTED" );
        }
        // 0 - choose a random map from the current voting map list, as next map
        default:
        {
            g_voteStatus |= IS_VOTE_OVER;

            new winnerVoteMapIndex = random_num( 0, g_totalVoteOptions - 1 );
            setNextMap( g_currentMapName, g_votingMapNames[ winnerVoteMapIndex ] );

            color_print( 0, "%L. %L", LANG_PLAYER, "GAL_WINNER_NO_ONE_VOTED", LANG_PLAYER, "GAL_WINNER_RANDOM2", g_nextMapName );
            toShowTheMapNextHud( "GAL_WINNER_NO_ONE_VOTED", "DMAP_MAP_EXTENDED", "GAL_WINNER_RANDOM1", g_nextMapName );

            process_last_round( g_isToChangeMapOnVotingEnd );
        }
    }
}

stock resetVoteTypeGlobals()
{
    LOGGER( 128, "I AM ENTERING ON resetVoteTypeGlobals(0)" )

    g_endVotingType                 = 0;
    g_isRunOffNeedingKeepCurrentMap = false;
}

/**
 * Restore global variables to is default state. This is to be ready for a new voting.
 */
stock finalizeVoting()
{
    LOGGER( 128, "I AM ENTERING ON finalizeVoting(0)" )
    resetVoteTypeGlobals();

    // vote is no longer in progress
    g_voteStatus &= ~IS_VOTE_IN_PROGRESS;

    // if we were in a runoff or RTV mode, get out of it
    g_voteStatus &= ~IS_RUNOFF_VOTE;
    g_voteStatus &= ~IS_RTV_VOTE;

    // this must be called after 'g_voteStatus &= ~IS_RUNOFF_VOTE' above
    vote_resetStats();
}

stock Float:map_getMinutesElapsed()
{
    LOGGER( 128, "I AM ENTERING ON Float:map_getMinutesElapsed(0) mp_timelimit: %f", get_pcvar_float( cvar_mp_timelimit ) )
    return get_pcvar_float( cvar_mp_timelimit ) - ( float( get_timeleft() ) / 60.0 );
}

stock map_getMinutesElapsedInteger()
{
    LOGGER( 128, "I AM ENTERING ON Float:map_getMinutesElapsed(0) mp_timelimit: %f", get_pcvar_float( cvar_mp_timelimit ) )

    // While the Unit Tests are running, to force a specific time.
#if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED )
    if( g_test_isTheUnitTestsRunning )
    {
        return g_test_gameElapsedTime;
    }
#endif
    return get_pcvar_num( cvar_mp_timelimit ) - ( get_timeleft() / 60 );
}

stock toAnnounceTheMapExtension( lang[] )
{
    LOGGER( 128, "I AM ENTERING ON toAnnounceTheMapExtension(1) lang: %s", lang )

    if( g_endVotingType & ( IS_BY_ROUNDS | IS_BY_WINLIMIT ) )
    {
        color_print( 0, "%L %L", LANG_PLAYER, lang, LANG_PLAYER, "GAL_WINNER_EXTEND_ROUND2", g_extendmapStepRounds );
        toShowTheMapExtensionHud( lang, "DMAP_MAP_EXTENDED", "GAL_WINNER_EXTEND_ROUND1", g_extendmapStepRounds );
    }
    else if( g_endVotingType & IS_BY_FRAGS )
    {
        color_print( 0, "%L %L", LANG_PLAYER, lang, LANG_PLAYER, "GAL_WINNER_EXTEND_FRAGS2", g_extendmapStepFrags );
        toShowTheMapExtensionHud( lang, "DMAP_MAP_EXTENDED", "GAL_WINNER_EXTEND_FRAGS1", g_extendmapStepFrags );
    }
    else
    {
        color_print( 0, "%L %L", LANG_PLAYER, lang, LANG_PLAYER, "GAL_WINNER_EXTEND2", g_extendmapStepMinutes );
        toShowTheMapExtensionHud( lang, "DMAP_MAP_EXTENDED", "GAL_WINNER_EXTEND1", g_extendmapStepMinutes );
    }
}

stock toShowTheMapExtensionHud( lang1[], lang2[], lang3[], extend )
{
    LOGGER( 128, "I AM ENTERING ON toShowTheMapExtensionHud(4) lang2: %s, lang3: %s, extend: %d", lang2, lang3, extend )

    if( !( get_pcvar_num( cvar_hudsHide ) & HUD_VOTE_RESULTS_ANNOUNCE ) )
    {
        set_hudmessage( 150, 120, 0, -1.0, 0.13, 0, 1.0, 6.94, 0.0, 0.0, -1 );
        show_hudmessage( 0, "%L. %L:^n%L", LANG_PLAYER, lang1, LANG_PLAYER, lang2, LANG_PLAYER, lang3, extend );
    }
}

stock toShowTheMapStayHud( lang1[], lang2[], lang3[] )
{
    LOGGER( 128, "I AM ENTERING ON toShowTheMapStayHud(3) lang1: %s, lang2: %s, lang3: %s", lang1, lang2, lang3 )

    if( !( get_pcvar_num( cvar_hudsHide ) & HUD_VOTE_RESULTS_ANNOUNCE ) )
    {
        set_hudmessage( 150, 120, 0, -1.0, 0.13, 0, 1.0, 6.94, 0.0, 0.0, -1 );
        show_hudmessage( 0, "%L. %L:^n%L", LANG_PLAYER, lang1, LANG_PLAYER, lang2, LANG_PLAYER, lang3 );
    }
}

stock toShowTheMapNextHud( lang1[], lang2[], lang3[], map[] )
{
    LOGGER( 128, "I AM ENTERING ON toShowTheMapNextHud(4) lang1: %s, lang2: %s, lang3: %s", lang1, lang2, lang3 )

    if( !( get_pcvar_num( cvar_hudsHide ) & HUD_VOTE_RESULTS_ANNOUNCE ) )
    {
        set_hudmessage( 150, 120, 0, -1.0, 0.13, 0, 1.0, 6.94, 0.0, 0.0, -1 );
        show_hudmessage( 0, "%L. %L:^n%L", LANG_PLAYER, lang1, LANG_PLAYER, lang2, LANG_PLAYER, lang3, map );
    }
}

stock map_extend( lang[] )
{
    LOGGER( 128, "I AM ENTERING ON map_extend(1)" )
    LOGGER( 2, "%32s g_rtvWaitMinutes: %f, g_extendmapStepMinutes: %d", "map_extend( in )", g_rtvWaitMinutes, g_extendmapStepMinutes )

    // While the `IS_DISABLED_VOTEMAP_EXIT` bit flag is set, we cannot allow any decisions.
    if( g_voteMapStatus & IS_DISABLED_VOTEMAP_EXIT )
    {
        color_print( 0, "%L: %L", LANG_PLAYER, "DMAP_MAP_EXTENDED", LANG_PLAYER, "GAL_WINNER_STAY2" );
        toShowTheMapExtensionHud( "GAL_VOTE_ENDED", "DMAP_MAP_EXTENDED", "GAL_WINNER_STAY1", 0 );

        // When the map extension is called, there is anyone else trying to show action menu,
        // therefore invoke it before returning.
        openTheVoteMapActionMenu();

        LOGGER( 1, "    ( map_extend ) Just returning/blocking, g_voteMapStatus: %d", g_voteMapStatus )
        return;
    }

    toAnnounceTheMapExtension( lang );
    noLongerIsAnEarlyVoting();

    LOGGER( 2, "( map_extend ) TRYING to change the cvar %15s to '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOGGER( 2, "( map_extend ) TRYING to change the cvar %15s to '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOGGER( 2, "( map_extend ) TRYING to change the cvar %15s to '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOGGER( 2, "( map_extend ) TRYING to change the cvar %15s to '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )

    // Remove the fail safe, as we are extending the map. The fail safe could be running if the
    // `cvar_endOfMapVoteStart` failed to predict the correct last round to start voting, the voting
    // could have been started on the map_manageEnd(0) function. Then the fail safe will be running,
    // but if the map extension was the voting winner option, then we must to disable the fail safe
    // as we do not need it anymore.
    remove_task( TASKID_PREVENT_INFITY_GAME );
    remove_task( TASKID_SHOW_LAST_ROUND_HUD );
    resetTheRtvWaitTime();

    saveEndGameLimits();
    doTheActualMapExtension();

    LOGGER( 2, "    ( map_extend ) CHECKOUT the cvar %19s is '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOGGER( 2, "    ( map_extend ) CHECKOUT the cvar %19s is '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOGGER( 2, "    ( map_extend ) CHECKOUT the cvar %19s is '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOGGER( 2, "    ( map_extend ) CHECKOUT the cvar %19s is '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )
    LOGGER( 2, "%32s g_rtvWaitMinutes: %f, g_extendmapStepMinutes: %d", "map_extend( out )", g_rtvWaitMinutes, g_extendmapStepMinutes )
}

/**
 * Reset the "rtv wait" time, taking into consideration the map extension.
 */
stock resetTheRtvWaitTime()
{
    LOGGER( 128, "I AM ENTERING ON resetTheRtvWaitTime(0)" )

    if( g_rtvWaitMinutes )
    {
        g_rtvWaitMinutes += get_pcvar_float( cvar_mp_timelimit );
    }

    if( g_rtvWaitRounds )
    {
        g_rtvWaitRounds += get_pcvar_num( cvar_mp_maxrounds );
    }

    if( g_rtvWaitFrags )
    {
        g_rtvWaitFrags += get_pcvar_num( cvar_mp_fraglimit );
    }
}

stock doTheActualMapExtension()
{
    LOGGER( 128, "I AM ENTERING ON doTheActualMapExtension(0)" )

    if( g_endVotingType & IS_BY_ROUNDS )
    {
        tryToSetGameModCvarNum(   cvar_mp_maxrounds, get_pcvar_num( cvar_mp_maxrounds ) + g_extendmapStepRounds );
        tryToSetGameModCvarNum(   cvar_mp_winlimit , 0 );
        tryToSetGameModCvarNum(   cvar_mp_fraglimit, 0 );
        tryToSetGameModCvarFloat( cvar_mp_timelimit, 0.0 );
    }
    else if( g_endVotingType & IS_BY_WINLIMIT )
    {
        tryToSetGameModCvarNum(   cvar_mp_maxrounds, 0  );
        tryToSetGameModCvarNum(   cvar_mp_winlimit , get_pcvar_num( cvar_mp_winlimit ) + g_extendmapStepRounds );
        tryToSetGameModCvarNum(   cvar_mp_fraglimit, 0 );
        tryToSetGameModCvarFloat( cvar_mp_timelimit, 0.0 );
    }
    else if( g_endVotingType & IS_BY_FRAGS )
    {
        tryToSetGameModCvarNum(   cvar_mp_maxrounds, 0   );
        tryToSetGameModCvarNum(   cvar_mp_winlimit , 0   );
        tryToSetGameModCvarNum(   cvar_mp_fraglimit, get_pcvar_num( cvar_mp_fraglimit ) + g_extendmapStepFrags );
        tryToSetGameModCvarFloat( cvar_mp_timelimit, 0.0 );
    }
    else
    {
        tryToSetGameModCvarNum(   cvar_mp_maxrounds, 0 );
        tryToSetGameModCvarNum(   cvar_mp_winlimit , 0 );
        tryToSetGameModCvarNum(   cvar_mp_fraglimit, 0 );
        tryToSetGameModCvarFloat( cvar_mp_timelimit, get_pcvar_float( cvar_mp_timelimit ) + g_extendmapStepMinutes );
    }
}

stock saveEndGameLimits()
{
    LOGGER( 128, "I AM ENTERING ON saveEndGameLimits(0)" )

    if( !g_isEndGameLimitsChanged )
    {
        g_isEndGameLimitsChanged = true;

        g_originalTimelimit = get_pcvar_float( cvar_mp_timelimit );
        g_originalMaxRounds = get_pcvar_num(   cvar_mp_maxrounds );
        g_originalWinLimit  = get_pcvar_num(   cvar_mp_winlimit  );
        g_originalFragLimit = get_pcvar_num(   cvar_mp_fraglimit );

        LOGGER( 2, "( saveEndGameLimits ) SAVING the cvar %15s to '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
        LOGGER( 2, "( saveEndGameLimits ) SAVING the cvar %15s to '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
        LOGGER( 2, "( saveEndGameLimits ) SAVING the cvar %15s to '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
        LOGGER( 2, "( saveEndGameLimits ) SAVING the cvar %15s to '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )
    }
}

public map_restoreEndGameCvars()
{
    LOGGER( 128 + 2, "I AM ENTERING ON map_restoreEndGameCvars(0)" )

    restoreTheChatTime();
    restoreOriginalServerMaxSpeed();

    LOGGER( 2, "( map_restoreEndGameCvars ) TRYING to change the cvar %15s to '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOGGER( 2, "( map_restoreEndGameCvars ) TRYING to change the cvar %15s to '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOGGER( 2, "( map_restoreEndGameCvars ) TRYING to change the cvar %15s to '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOGGER( 2, "( map_restoreEndGameCvars ) TRYING to change the cvar %15s to '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )

    if( g_isEndGameLimitsChanged )
    {
        g_isEndGameLimitsChanged = false;

        tryToSetGameModCvarFloat( cvar_mp_timelimit, g_originalTimelimit );
        tryToSetGameModCvarNum(   cvar_mp_maxrounds, g_originalMaxRounds );
        tryToSetGameModCvarNum(   cvar_mp_winlimit , g_originalWinLimit  );
        tryToSetGameModCvarNum(   cvar_mp_fraglimit, g_originalFragLimit );

        LOGGER( 2, "( map_restoreEndGameCvars ) RESTORING the cvar %-22s to '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
        LOGGER( 2, "( map_restoreEndGameCvars ) RESTORING the cvar %-22s to '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
        LOGGER( 2, "( map_restoreEndGameCvars ) RESTORING the cvar %-22s to '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
        LOGGER( 2, "( map_restoreEndGameCvars ) RESTORING the cvar %-22s to '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )

        // restore to the original/right values
        g_rtvWaitMinutes = get_pcvar_float( cvar_rtvWaitMinutes );
        g_rtvWaitRounds  = get_pcvar_num(   cvar_rtvWaitRounds  );
        g_rtvWaitFrags   = get_pcvar_num(   cvar_rtvWaitFrags   );
    }

    cacheCvarsValues();
    LOGGER( 1, "    I AM EXITING ON map_restoreEndGameCvars(0)" )
}

stock restoreOriginalServerMaxSpeed()
{
    LOGGER( 128, "I AM ENTERING ON restoreOriginalServerMaxSpeed(0) g_original_sv_maxspeed: %f", g_original_sv_maxspeed )

    if( floatround( g_original_sv_maxspeed, floatround_floor ) )
    {
        tryToSetGameModCvarFloat( cvar_sv_maxspeed, g_original_sv_maxspeed );
        LOGGER( 2, "( restoreOriginalServerMaxSpeed ) IS CHANGING THE CVAR 'sv_maxspeed' to '%f'.", g_original_sv_maxspeed )

        g_original_sv_maxspeed = 0.0;
    }

    if( cvar_mp_friendlyfire
        && g_isToRestoreFriendlyFire )
    {
        tryToSetGameModCvarNum( cvar_mp_friendlyfire, 0 );
        LOGGER( 2, "( restoreOriginalServerMaxSpeed ) IS CHANGING THE CVAR 'mp_friendlyfire' to '%d'.", get_pcvar_num( cvar_mp_friendlyfire ) )

        g_isToRestoreFriendlyFire = false;
    }
}

stock map_isInMenu( map[] )
{
    LOGGER( 256, "I AM ENTERING ON map_isInMenu(1) map: %s", map )

    for( new playerVoteMapChoiceIndex = 0;
         playerVoteMapChoiceIndex < g_totalVoteOptions; ++playerVoteMapChoiceIndex )
    {
        if( equali( map, g_votingMapNames[ playerVoteMapChoiceIndex ] ) )
        {
            LOGGER( 256, "    ( map_isInMenu ) Returning true." )
            return true;
        }
    }

    LOGGER( 256, "    ( map_isInMenu ) Returning false." )
    return false;
}

stock removeMapFromTheVotingMenu( mapName[] )
{
    LOGGER( 1, "I AM ENTERING ON removeMapFromTheVotingMenu(1) map: %s", mapName )
    new index;

    for( ; index < g_totalVoteOptions; index++ )
    {
        if( equali( mapName, g_votingMapNames[ index ] ) )
        {
            LOGGER( 4, "( removeMapFromTheVotingMenu ) Removing map: %s", mapName )

            g_votingMapNames[ index ][ 0 ] = '^0';
            g_votingMapInfos[ index ][ 0 ] = '^0';

            g_totalVoteOptions--;
            break;
        }
    }

    // Shift the entries to not mess with everything depending on the `g_totalVoteOptions` size.
    for( ; index < g_totalVoteOptions; index++ )
    {
        copy( g_votingMapNames[ index ], charsmax( g_votingMapNames[] ), g_votingMapNames[ index + 1 ] );
        copy( g_votingMapInfos[ index ], charsmax( g_votingMapInfos[] ), g_votingMapInfos[ index + 1 ] );
    }
}

stock addMapToTheVotingMenu( mapName[], mapInfo[] )
{
    LOGGER( 1, "I AM ENTERING ON addMapToTheVotingMenu(1) map: %s, mapInfo: %s", mapName, mapInfo )

    if( !map_isInMenu( mapName ) )
    {
        copy( g_votingMapNames[ g_totalVoteOptions ], charsmax( g_votingMapNames[] ), mapName );
        copy( g_votingMapInfos[ g_totalVoteOptions ], charsmax( g_votingMapInfos[] ), mapInfo );

        g_totalVoteOptions++;
    }
}

stock isPrefixInMenu( map[] )
{
    LOGGER( 256, "I AM ENTERING ON isPrefixInMenu(1) map: %s", map )

    new junk[ 8 ];
    new possiblePrefix[ 8 ];
    new existingPrefix[ 8 ];

    STR_TOKEN( map, possiblePrefix, charsmax( possiblePrefix ), junk, charsmax( junk ), '_', 1 );

    for( new playerVoteMapChoiceIndex = 0;
         playerVoteMapChoiceIndex < g_totalVoteOptions; ++playerVoteMapChoiceIndex )
    {
        STR_TOKEN( g_votingMapNames[ playerVoteMapChoiceIndex ],
                existingPrefix, charsmax( existingPrefix ),
                junk          , charsmax( junk )          , '_', 1 );

        if( equali( possiblePrefix, existingPrefix ) )
        {
            LOGGER( 256, "    ( isPrefixInMenu ) Returning true." )
            return true;
        }
    }

    LOGGER( 256, "    ( isPrefixInMenu ) Returning false." )
    return false;
}

/**
 * Everybody who call this, must to check whether the recent maps are loaded or not. To do so, just
 * do 'if(g_recentMapCount)'.
 */
stock map_isTooRecent( map[] )
{
    LOGGER( 256, "I AM ENTERING ON map_isTooRecent(1) map: %s", map )
    LOGGER( 256, "    ( map_isTooRecent ) Returning TrieKeyExists: %d", TrieKeyExists( g_recentMapsTrie, map ) )

    return TrieKeyExists( g_recentMapsTrie, map );
}

stock is_to_block_RTV( player_id )
{
    LOGGER( 128, "I AM ENTERING ON is_to_block_RTV(1) player_id: %d", player_id )

    // If time-limit is 0, minutesElapsed will always be 0.
    new Float:minutesElapsed;

    // If an early vote is pending, don't allow any rocks
    if( g_voteStatus & IS_EARLY_VOTE )
    {
        color_print( player_id, "%L", player_id, "GAL_ROCK_FAIL_PENDINGVOTE" );
        LOGGER( 1, "    ( is_to_block_RTV ) Just Returning/blocking, the early voting is pending." )
    }

    // Rocks can only be made if a vote isn't already in progress
    else if( g_voteStatus & IS_VOTE_IN_PROGRESS )
    {
        color_print( player_id, "%L", player_id, "GAL_ROCK_FAIL_INPROGRESS" );
        LOGGER( 1, "    ( is_to_block_RTV ) Just Returning/blocking, the voting is in progress." )
    }

    // If the outcome of the vote hasn't already been determined
    else if( g_voteStatus & IS_VOTE_OVER )
    {
        color_print( player_id, "%L", player_id, "GAL_ROCK_FAIL_VOTEOVER" );
        LOGGER( 1, "    ( is_to_block_RTV ) Just Returning/blocking, the voting is over." )
    }

    // Cannot rock when admins are online
    else if( get_pcvar_num( cvar_rtvWaitAdmin ) & IS_TO_RTV_WAIT_ADMIN
             && g_rtvWaitAdminNumber > 0 )
    {
        color_print( player_id, "%L", player_id, "GAL_ROCK_WAIT_ADMIN" );
        LOGGER( 1, "    ( is_to_block_RTV ) Just Returning/blocking, cannot rock when admins are online." )
    }

    // If the player is the only one on the server, bring up the vote immediately
    else if( get_real_players_number() == 1
             && !( g_rtvCommands & RTV_CMD_SINGLE_PLAYER_DISABLE ) )
    {
        start_rtvVote();
        LOGGER( 1, "    ( is_to_block_RTV ) Just Returning/blocking, the voting started." )
    }

    // Make sure enough time has gone by on the current map
    else if( g_rtvWaitMinutes
             && ( minutesElapsed = map_getMinutesElapsed() )
             && minutesElapsed < g_rtvWaitMinutes )
    {
        new remaining_time = floatround( g_rtvWaitMinutes - minutesElapsed, floatround_ceil );

        color_print( player_id, "%L", player_id, "GAL_ROCK_FAIL_TOOSOON", remaining_time );
        LOGGER( 1, "    ( is_to_block_RTV ) Just Returning/blocking, too soon to rock by minutes." )
    }

    // Make sure enough rounds has gone by on the current map
    else if( g_rtvWaitRounds
             && g_totalRoundsPlayed < g_rtvWaitRounds )
    {
        new remaining_rounds = g_rtvWaitRounds - g_totalRoundsPlayed;

        color_print( player_id, "%L", player_id, "GAL_ROCK_FAIL_TOOSOON_ROUNDS", remaining_rounds );
        LOGGER( 1, "    ( is_to_block_RTV ) Just Returning/blocking, too soon to rock by rounds." )
    }

    // Make sure enough frags has gone by on the current map
    else if( g_rtvWaitFrags
             && g_greatestKillerFrags < g_rtvWaitFrags )
    {
        new remaining_frags =  g_rtvWaitFrags - g_greatestKillerFrags;

        color_print( player_id, "%L", player_id, "GAL_ROCK_FAIL_TOOSOON_FRAGS", remaining_frags );
        LOGGER( 1, "    ( is_to_block_RTV ) Just Returning/blocking, too soon to rock by frags." )
    }
    else
    {
        LOGGER( 1, "    ( is_to_block_RTV ) Just Returning/allowing, the RTV." )
        return false;
    }

    return true;
}

public vote_rock( player_id )
{
    LOGGER( 128, "I AM ENTERING ON vote_rock(1) player_id: %d", player_id )
    new rocksNeeded;

    if( !is_to_block_RTV( player_id )
        && compute_the_RTV_vote( player_id, ( rocksNeeded = vote_getRocksNeeded() ) ) )
    {
        try_to_start_the_RTV( rocksNeeded );
    }
}

/**
 * Allow the player to rock the vote.
 */
stock compute_the_RTV_vote( player_id, rocksNeeded )
{
    // make sure player hasn't already rocked the vote
    if( g_rockedVote[ player_id ] )
    {
        color_print( player_id, "%L", player_id, "GAL_ROCK_FAIL_ALREADY", rocksNeeded - g_rockedVoteCount );
        rtv_remind( TASKID_RTV_REMINDER + player_id );

        LOGGER( 1, "    ( vote_rock ) Just Returning/blocking, already rocked the vote." )
        return false;
    }

    g_rockedVote[ player_id ] = true;
    color_print( player_id, "%L", player_id, "GAL_ROCK_SUCCESS" );

    LOGGER( 1, "    ( vote_rock ) Just Returning/blocking, accepting rock the vote." )
    return true;
}

/**
 * Determine if there have been enough rocks for a vote yet.
 */
stock try_to_start_the_RTV( rocksNeeded )
{
    // make sure the rtv reminder timer has stopped
    if( task_exists( TASKID_RTV_REMINDER ) )
    {
        remove_task( TASKID_RTV_REMINDER );
    }

    if( ++g_rockedVoteCount >= rocksNeeded )
    {
        // announce that the vote has been rocked
        color_print( 0, "%L", LANG_PLAYER, "GAL_ROCK_ENOUGH" );

        // start up the vote director
        start_rtvVote();
    }
    else
    {
        // let the players know how many more rocks are needed
        rtv_remind( TASKID_RTV_REMINDER );

        if( get_pcvar_num( cvar_rtvReminder ) )
        {
            // initialize the rtv reminder timer to repeat how many
            // rocks are still needed, at regular intervals
            set_task( get_pcvar_float( cvar_rtvReminder ) * 60.0, "rtv_remind", TASKID_RTV_REMINDER, _, _, "b" );
        }
    }
}

/**
 * Indicates when a map should end after the RTV voting is finished.
 * If selected a value higher than 0, cvar_endOnRoundRtv indicates also the players
 * minimum number necessary to allow the last round to be finished when
 * the time runs out.
 * For example, if cvar_endOnRoundRtv value is set to 2, and there are only 1 player
 * on the server, the round will end immediately.
 */
stock start_rtvVote()
{
    LOGGER( 128, "I AM ENTERING ON start_rtvVote(0)" )
    new endOnRoundRtv = get_pcvar_num( cvar_endOnRoundRtv );

    if( endOnRoundRtv
        && get_real_players_number() >= endOnRoundRtv )
    {
        g_isTheLastGameRound = true;
    }
    else
    {
        g_isToChangeMapOnVotingEnd = true;
    }

    g_voteStatus |= IS_RTV_VOTE;

    // Just to be sure
    resetVoteTypeGlobals();

    // Any voting not started by `cvar_endOfMapVoteStart`, `cvar_endOnRound` or ending limit expiration,
    // is a forced voting.
    vote_startDirector( true );
}

stock vote_unrockTheVote( player_id )
{
    LOGGER( 128, "I AM ENTERING ON vote_unrockTheVote(1) player_id: %d", player_id )

    if( g_rockedVote[ player_id ] )
    {
        g_rockedVote[ player_id ] = false;
        g_rockedVoteCount--;
    }
}

stock vote_getRocksNeeded()
{
    LOGGER( 128, "I AM ENTERING ON vote_getRocksNeeded(0)" )
    return floatround( get_pcvar_float( cvar_rtvRatio ) * float( get_real_players_number() ), floatround_ceil );
}

public rtv_remind( param )
{
    LOGGER( 128, "I AM ENTERING ON rtv_remind(1) param: %d", param )
    new player_id = param - TASKID_RTV_REMINDER;

    // let the players know how many more rocks are needed
    color_print( player_id, "%L", LANG_PLAYER, "GAL_ROCK_NEEDMORE", vote_getRocksNeeded() - g_rockedVoteCount );
}

// change to the map
public map_change()
{
    LOGGER( 128, "I AM ENTERING ON map_change(0)" )

    // grab the name of the map we're changing to
    new map[ MAX_MAPNAME_LENGHT ];
    get_cvar_string( "amx_nextmap", map, charsmax( map ) );

    resetRoundEnding();

    // verify we're changing to a valid map
    if( !IS_MAP_VALID( map ) )
    {
        // probably admin did something dumb like changed the map time limit below
        // the time remaining in the map, thus making the map over immediately.
        // since the next map is unknown, just restart the current map.
        copy( map, charsmax( map ), g_currentMapName );
    }

    serverChangeLevel( map );
}

public map_change_stays()
{
    LOGGER( 128, "I AM ENTERING ON map_change_stays(0)" )
    resetRoundEnding();

    LOGGER( 4, "( map_change_stays ) g_currentMapName: %s", g_currentMapName )
    serverChangeLevel( g_currentMapName );
}

public serverChangeLevel( mapName[] )
{
    LOGGER( 128, "I AM ENTERING ON serverChangeLevel(1) mapName: %s", mapName )

    LOGGER( 4, "( serverChangeLevel ) AMXX_VERSION_NUM: %d", AMXX_VERSION_NUM )
    LOGGER( 4, "( serverChangeLevel ) IS_TO_ENABLE_RE_HLDS_RE_AMXMODX_SUPPORT: %d", IS_TO_ENABLE_RE_HLDS_RE_AMXMODX_SUPPORT )

#if AMXX_VERSION_NUM < 183 || IS_TO_ENABLE_RE_HLDS_RE_AMXMODX_SUPPORT > 0
    server_cmd( "changelevel %s", mapName );
#else
    engine_changelevel( mapName );
#endif

    LOGGER( 1, "    I AM EXITING serverChangeLevel(1)..." )
    LOGGER( 1, "" )
}

public cmd_HL1_votemap( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_HL1_votemap(1) player_id: %d", player_id )

    if( get_pcvar_num( cvar_cmdVotemap ) == 0 )
    {
        console_print( player_id, "%L", player_id, "GAL_DISABLED" );

        LOGGER( 1, "    ( cmd_HL1_votemap ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }

    LOGGER( 1, "    ( cmd_HL1_votemap ) Returning PLUGIN_CONTINUE" )
    return PLUGIN_CONTINUE;
}

public cmd_HL1_listmaps( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_HL1_listmaps(1) player_id: %d", player_id )

    switch( get_pcvar_num( cvar_cmdListmaps ) )
    {
        case 0:
        {
            console_print( player_id, "%L", player_id, "GAL_DISABLED" );
        }
        case 2:
        {
            map_listAll( player_id );
        }
        default:
        {
            LOGGER( 1, "    ( cmd_HL1_listmaps ) Returning PLUGIN_CONTINUE" )
            return PLUGIN_CONTINUE;
        }
    }

    LOGGER( 1, "    ( cmd_HL1_listmaps ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

public map_listAll( player_id )
{
    LOGGER( 128, "I AM ENTERING ON map_listAll(1) player_id: %d", player_id )
    static lastMapDisplayed[ MAX_MAPNAME_LENGHT ][ 2 ];

    new start;
    new userid;
    new mapPerPage;

    new command  [ 32 ];
    new parameter[ 8 ];

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
        if( read_argv( 1, parameter, charsmax( parameter ) ) )
        {
            if( parameter[ 0 ] == '*' )
            {
                // if the last map previously displayed belongs to the current user,
                // start them off there, otherwise, start them at 1
                if( lastMapDisplayed[ player_id ][ LISTMAPS_USERID ] )
                {
                    start = lastMapDisplayed[ player_id ][ LISTMAPS_LAST_MAP ] + 1;
                }
                else
                {
                    start = 1;
                }
            }
            else
            {
                start = str_to_num( parameter );
            }
        }
        else
        {
            start = 1;
        }

        if( player_id == 0
            && read_argc() == 3
            && read_argv( 2, parameter, charsmax( parameter ) ) )
        {
            mapPerPage = str_to_num( parameter );
        }
    }

    if( start < 1 )
    {
        start = 1;
    }

    new nominationsMapsCount = ArraySize( g_nominationLoadedMapsArray );

    if( start >= nominationsMapsCount )
    {
        start = nominationsMapsCount - 1;
    }

    new end = mapPerPage ? start + mapPerPage - 1 : nominationsMapsCount;

    if( end > nominationsMapsCount )
    {
        end = nominationsMapsCount;
    }

    // this enables us to use 'command *' to get the next group of maps, when paginated
    lastMapDisplayed[ player_id ][ LISTMAPS_LAST_MAP ]   = end - 1;
    lastMapDisplayed[ player_id ][ LISTMAPS_USERID ] = userid;

    console_print( player_id, "^n----- %L -----", player_id, "GAL_LISTMAPS_TITLE", nominationsMapsCount );

    // Second part start
    new mapIndex;
    new nominator_id;

    new mapName    [ MAX_MAPNAME_LENGHT ];
    new nominated  [ MAX_PLAYER_NAME_LENGHT + 32 ];
    new player_name[ MAX_PLAYER_NAME_LENGHT ];

    for( mapIndex = start - 1; mapIndex < end; mapIndex++ )
    {
        nominator_id = nomination_getPlayer( mapIndex );

        if( nominator_id )
        {
            GET_USER_NAME( nominator_id, player_name )
            formatex( nominated, charsmax( nominated ), "%L", player_id, "GAL_NOMINATEDBY", player_name );
        }
        else
        {
            nominated[ 0 ] = '^0';
        }

        GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, mapName )
        console_print( player_id, "%3i: %s  %s", mapIndex + 1, mapName, nominated );
    }

    if( mapPerPage
        && mapPerPage < nominationsMapsCount )
    {
        console_print( player_id, "----- %L -----", player_id, "GAL_LISTMAPS_SHOWING",
                start, mapIndex, nominationsMapsCount );

        if( end < nominationsMapsCount )
        {
            console_print( player_id, "----- %L -----", player_id, "GAL_LISTMAPS_MORE",
                    command, end + 1, command );
        }
    }
}

/**
 * Remove the color tags form the message before print it to the given player console.
 *
 * @param player_id         the player id.
 * @param message[]         the text formatting rules to display.
 * @param any               the variable number of formatting parameters.
 */
stock no_color_print( const player_id, const message[], any:... )
{
    LOGGER( 128, "I AM ENTERING ON color_console_print(...) player_id: %d, message: %s...", player_id, message )
    new formated_message[ MAX_COLOR_MESSAGE ];

    vformat( formated_message, charsmax( formated_message ), message, 3 );
    REMOVE_CODE_COLOR_TAGS( formated_message )

    console_print( player_id, formated_message );
}

stock restartEmptyCycle()
{
    LOGGER( 128, "I AM ENTERING ON restartEmptyCycle(0)" )
    set_pcvar_num( cvar_isToStopEmptyCycle, 0 );

    LOGGER( 2, "( restartEmptyCycle ) IS CHANGING THE CVAR 'gal_in_empty_cycle' to '%d'.", 0 )
    remove_task( TASKID_EMPTYSERVER );
}

/**
 * The reamxmodx is requiring more parameters to allow a call to `client_authorized()` from the
 * Unit Test. So, the stock client_authorized_stock(1) is just a shadow of the client_authorized(1)
 * just to allow to perform the Unit tests.
 */
#define CLIENT_AUTHORIZED_MACRO(%1) \
{ \
    LOGGER( 128, "I AM ENTERING ON client_authorized(1) player_id: %d", %1 ) \
    restartEmptyCycle(); \
    if( get_user_flags( %1 ) & ADMIN_MAP ) \
    { \
        g_rtvWaitAdminNumber++; \
    } \
}

stock client_authorized_stock( player_id )
{
    CLIENT_AUTHORIZED_MACRO( player_id )
}

public client_authorized( player_id )
{
    CLIENT_AUTHORIZED_MACRO( player_id )
}

#if AMXX_VERSION_NUM < 183
    public client_disconnect( player_id )
#else
    public client_disconnected( player_id )
#endif
{
    LOGGER( 128, "I AM ENTERING ON client_disconnected(1) player_id: %d", player_id )
    if( is_user_bot( player_id ) ) return;

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
    LOGGER( 128, "I AM ENTERING ON unnominatedDisconnectedPlayer(1) player_id: %d", player_id )

    new mapIndex;
    new maxPlayerNominations;
    new announcementShowedTimes;

    new mapName          [ MAX_MAPNAME_LENGHT ];
    new blockedMapsBuffer[ MAX_COLOR_MESSAGE ];

    // cancel player's nominations and print what was cancelled.
    maxPlayerNominations    = min( get_pcvar_num( cvar_nomPlayerAllowance ), MAX_OPTIONS_IN_VOTE );
    announcementShowedTimes = 1;

    for( new nominationIndex = 0; nominationIndex < maxPlayerNominations; ++nominationIndex )
    {
        mapIndex = getPlayerNominationMapIndex( player_id, nominationIndex );

        if( mapIndex >= 0 )
        {
            setPlayerNominationMapIndex( player_id, nominationIndex, -1 );

            GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, mapName )
            announceVoteBlockedMap( mapName, blockedMapsBuffer, "GAL_FILLER_BLOCKED", announcementShowedTimes );
        }
    }

    flushVoteBlockedMaps( blockedMapsBuffer, "GAL_CANCEL_SUCCESS", announcementShowedTimes );
}

/**
 * If the empty cycle feature was initialized by 'inicializeEmptyCycleFeature()' function, this
 * function to start the empty cycle map change system, when the last server player disconnect.
 */
stock isToHandleRecentlyEmptyServer()
{
    LOGGER( 128, "I AM ENTERING ON isToHandleRecentlyEmptyServer(0)" )
    new playersCount = get_real_players_number();

    LOGGER( 2, "( isToHandleRecentlyEmptyServer ) mp_timelimit: %f, g_originalTimelimit: %f, playersCount: %d", \
            get_pcvar_float( cvar_mp_timelimit ), g_originalTimelimit, playersCount )

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

    LOGGER( 2, "I AM EXITING ON isToHandleRecentlyEmptyServer(0) g_isUsingEmptyCycle = %d, \
            g_emptyCycleMapsNumber = %d", g_isUsingEmptyCycle, g_emptyCycleMapsNumber )
}

/**
 * Inicializes the empty cycle server feature at map starting.
 */
public inicializeEmptyCycleFeature()
{
    LOGGER( 128, "I AM ENTERING ON inicializeEmptyCycleFeature(0)" )

    if( get_real_players_number() == 0 )
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
    LOGGER( 128, "I AM ENTERING ON startEmptyCycleCountdown(0)" )
    new waitMinutes = get_pcvar_num( cvar_emptyServerWaitMinutes );

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
    LOGGER( 128, "I AM ENTERING ON configureNextEmptyCycleMap(0)" )
    new mapIndex;

    new nextMapName      [ MAX_MAPNAME_LENGHT ];
    new lastEmptyCycleMap[ MAX_MAPNAME_LENGHT ];

    mapIndex = map_getNext( g_emptyCycleMapsArray, g_currentMapName, nextMapName );

    if( !g_isEmptyCycleMapConfigured )
    {
        g_isEmptyCycleMapConfigured = true;

        getLastEmptyCycleMap( lastEmptyCycleMap );
        map_getNext( g_emptyCycleMapsArray, lastEmptyCycleMap, nextMapName );

        setLastEmptyCycleMap( nextMapName );
        setNextMap( g_currentMapName, nextMapName, false );
    }

    return mapIndex;
}

stock getLastEmptyCycleMap( lastEmptyCycleMap[ MAX_MAPNAME_LENGHT ] )
{
    LOGGER( 128, "I AM ENTERING ON getLastEmptyCycleMap(1) lastEmptyCycleMap: %s", lastEmptyCycleMap )

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
    LOGGER( 128, "I AM ENTERING ON setLastEmptyCycleMap(1) lastEmptyCycleMap: %s", lastEmptyCycleMap )

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
    LOGGER( 128, "I AM ENTERING ON startEmptyCycleSystem(0)" )

    // stop this system at the next map, due we already be at a popular map
    set_pcvar_num( cvar_isToStopEmptyCycle, 1 );
    LOGGER( 2, "( startEmptyCycleSystem ) IS CHANGING THE CVAR 'gal_in_empty_cycle' to '%d'.", 1 )

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
 * If there is not found a next map, the current map name on `nextMapName` will to be set as the
 * first map cycle map name.
 *
 * @param mapArray      the dynamic array with the map list to search
 * @param currentMap    the string printer to the current map name
 * @param nextMapName   the string pointer which will receive the next map
 *
 * @return mapIndex     the nextMapName index in the mapArray. -1 if not found a nextMapName.
 */
stock map_getNext( Array:mapArray, currentMap[], nextMapName[] )
{
    LOGGER( 128, "I AM ENTERING ON map_getNext(3) currentMap: %s", currentMap )

    new thisMap[ MAX_MAPNAME_LENGHT ];
    new bool:isWhitelistEnabled = IS_WHITELIST_ENABLED();

    new nextmapIndex = 0;
    new returnValue  = -1;
    new mapCount     = ArraySize( mapArray );

    for( new currentMapIndex = 0; currentMapIndex < mapCount; currentMapIndex++ )
    {
        GET_MAP_NAME( mapArray, currentMapIndex, thisMap )

        if( equali( currentMap, thisMap ) )
        {
            // When the current map is the last one, the next map is the first maps on the map cycle.
            if( currentMapIndex == mapCount - 1 )
            {
                nextmapIndex = 0;
            }
            else
            {
                nextmapIndex = currentMapIndex + 1;
            }

            GET_MAP_NAME( mapArray, nextmapIndex, nextMapName )

            if( IS_WHITELIST_BLOCKING( isWhitelistEnabled, nextMapName ) )
            {
                copy( currentMap, MAX_MAPNAME_LENGHT - 1, nextMapName );
                continue;
            }

            returnValue = nextmapIndex;
            break;
        }
    }

    if( mapCount > 0
        && returnValue > -1 )
    {
        GET_MAP_NAME( mapArray, nextmapIndex, nextMapName )
    }
    else
    {
        log_amx(   "WARNING: Your 'mapcyclefile' server variable is invalid!" );
        LOGGER( 1, "WARNING: Your 'mapcyclefile' server variable is invalid!" )

        copy( nextMapName, MAX_MAPNAME_LENGHT - 1, g_currentMapName );
    }

    LOGGER( 1, "    ( map_getNext ) Returning mapIndex: %d, nextMapName: %s", returnValue, nextMapName )
    return returnValue;
}

public client_putinserver( player_id )
{
    LOGGER( 128, "I AM ENTERING ON client_putinserver(1) player_id: %d", player_id )

    if( ( g_voteStatus & IS_EARLY_VOTE )
        && !is_user_bot( player_id )
        && !is_user_hltv( player_id ) )
    {
        set_task( 20.0, "srv_announceEarlyVote", player_id );
    }
}

public srv_announceEarlyVote( player_id )
{
    LOGGER( 128, "I AM ENTERING ON srv_announceEarlyVote(1) player_id: %d", player_id )

    if( is_user_connected( player_id ) )
    {
        color_print( player_id, "%L", player_id, "GAL_VOTE_EARLY" );
    }
}

stock nomination_announceCancellation( nominations[] )
{
    LOGGER( 128, "I AM ENTERING ON nomination_announceCancellation(1) nominations: %s", nominations )
    color_print( 0, "%L", LANG_PLAYER, "GAL_CANCEL_SUCCESS", nominations );
}

stock nomination_clearAll()
{
    LOGGER( 128, "I AM ENTERING ON nomination_clearAll(0)" )

    if( get_pcvar_num( cvar_nomCleaning ) )
    {
        TrieClear( g_reverseSearchNominationsTrie );
        TrieClear( g_forwardSearchNominationsTrie );

        ArrayClear( g_nominatedMapsArray );
    }
}

stock map_announceNomination( player_id, map[] )
{
    LOGGER( 128, "I AM ENTERING ON map_announceNomination(2) player_id: %d, map: %s", player_id, map )
    new player_name[ MAX_PLAYER_NAME_LENGHT ];

    GET_USER_NAME( player_id, player_name )
    color_print( 0, "%L", LANG_PLAYER, "GAL_NOM_SUCCESS", player_name, map );
}

public cmd_rockthevote( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_rockthevote(1) player_id: %d", player_id )

    color_print( player_id, "%L", player_id, "GAL_CMD_RTV" );
    vote_rock( player_id );

    LOGGER( 1, "    ( cmd_rockthevote ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

public cmd_nominations( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_nominations(1) player_id: %d", player_id )

    color_print( player_id, "%L", player_id, "GAL_CMD_NOMS" );
    nomination_list();

    LOGGER( 1, "    ( cmd_nominations ) Returning PLUGIN_CONTINUE" )
    return PLUGIN_CONTINUE;
}

public cmd_listrecent( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_listrecent(1) player_id: %d", player_id )

    switch( get_pcvar_num( cvar_banRecentStyle ) )
    {
        case 1:
        {
            new copiedChars;
            new recentMapName    [ MAX_MAPNAME_LENGHT ];
            new recentMapsMessage[ MAX_COLOR_MESSAGE ];

            for( new mapIndex = 0; mapIndex < g_recentMapCount; ++mapIndex )
            {
                ArrayGetString( g_recentListMapsArray, mapIndex, recentMapName, charsmax( recentMapName ) );

                if( copiedChars < charsmax( recentMapsMessage ) )
                {
                    copiedChars += formatex( recentMapsMessage[ copiedChars ],
                            charsmax( recentMapsMessage ) - copiedChars, ", %s", recentMapName );
                }
                else
                {
                    break;
                }
            }

            color_print( 0, "%L: %s", LANG_PLAYER, "GAL_MAP_RECENTMAPS", recentMapsMessage[ 2 ] );
        }
        case 2:
        {
            new recentMapName[ MAX_MAPNAME_LENGHT ];

            for( new mapIndex = 0; mapIndex < g_recentMapCount && mapIndex < 5; ++mapIndex )
            {
                ArrayGetString( g_recentListMapsArray, mapIndex, recentMapName, charsmax( recentMapName ) );

                color_print( 0, "%L ( %i ): %s",
                        LANG_PLAYER, "GAL_MAP_RECENTMAP", mapIndex + 1, recentMapName );
            }
        }
        case 3:
        {
            showRecentMapsListMenu( player_id );
        }
    }

    LOGGER( 1, "    ( cmd_listrecent ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

public showRecentMapsListMenu( player_id )
{
    LOGGER( 128, "I AM ENTERING ON showRecentMapsListMenu(1) player_id: %d", player_id )

    new mapIndex;
    new itemsCount;

    new recentMapName[ MAX_MAPNAME_LENGHT ];
    new menuOptionString[ 64 ];

    // Calculate how much pages there are available.
    new currentPageNumber = g_recentMapsMenuPages[ player_id ];
    new lastPageNumber    = GET_LAST_PAGE_NUMBER( g_recentMapCount, MAX_MENU_ITEMS_PER_PAGE )

    // To create the menu
    formatex( menuOptionString, charsmax( menuOptionString ),
            IS_COLORED_CHAT_ENABLED() ? "%L\R%d /%d" : "%L  %d /%d",
            player_id, "GAL_MAP_RECENTMAPS", currentPageNumber + 1, lastPageNumber );

    new menu = menu_create( menuOptionString, "cmd_listrecent_handler" );

    // Disables the menu paging.
    menu_setprop( menu, MPROP_PERPAGE, 0 );

    // Configure the menu buttons.
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_EXITNAME, menu, "EXIT" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_NEXTNAME, menu, "MORE" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_BACKNAME, menu, "BACK" )

    if( ( mapIndex = currentPageNumber * MAX_MENU_ITEMS_PER_PAGE ) )
    {
        mapIndex = mapIndex - 1;
    }

    // Add the menu items.
    for( ; mapIndex < g_recentMapCount && itemsCount < MAX_MENU_ITEMS_PER_PAGE; ++mapIndex, ++itemsCount )
    {
        LOGGER( 4, "( showRecentMapsListMenu ) mapIndex: %d", mapIndex )
        ArrayGetString( g_recentListMapsArray, mapIndex, recentMapName, charsmax( recentMapName ) );

        menu_additem( menu, recentMapName );
        LOGGER( 4, "( showRecentMapsListMenu ) recentMapName: %s", recentMapName )
    }

    LOGGER( 4, "( showRecentMapsListMenu ) itemsCount: %d, mapIndex: %d", itemsCount, mapIndex )
    addMenuMoreBackOptions( menu, player_id, menuOptionString, mapIndex < g_recentMapCount, currentPageNumber > 0, itemsCount );

    // To display the menu.
    menu_display( player_id, menu );
}

stock addMenuMoreBackOptions( menu, player_id, menuOptionString[], bool:isToEnableMoreButton, bool:isToEnableBackButton, itemsCount )
{
    LOGGER( 128, "I AM ENTERING ON addMenuMoreBackOptions(5) isToEnableMoreButton: %d, \
            isToEnableBackButton: %d", isToEnableMoreButton, isToEnableBackButton )

    // Force the menu control options to be present on the keys 8 (more), 9 (back) and 0 (exit).
    while( itemsCount < MAX_MENU_ITEMS_PER_PAGE )
    {
        itemsCount++;
        formatex( menuOptionString, MAX_SHORT_STRING - 1, "%L", player_id, "OFF" );
        menu_additem( menu, menuOptionString, _, 1 << 26 );

        // When using slot=1 this might break your menu. To achieve this functionality
        // menu_addblank2() should be used (AMXX 183 only).
        // menu_addblank( menu, 1 );
    }

    // Add some space from the control options and format the more button within the LANG file.
    menu_addblank( menu, 0 );
    formatex( menuOptionString, MAX_SHORT_STRING - 1, "%L", player_id, "MORE" );

    // If there are more maps, add the more option
    if( isToEnableMoreButton )
    {
        menu_additem( menu, menuOptionString, _, 0 );
    }
    else
    {
        menu_additem( menu, menuOptionString, _, 1 << 26 );
    }

    // If we are on the first page, disable the back option and to add the exit button.
    if( isToEnableBackButton )
    {
        formatex( menuOptionString, MAX_SHORT_STRING - 1, "%L", player_id, "BACK" );
        menu_additem( menu, menuOptionString, _, 0 );
    }
    else
    {
        // To add the exit button
        formatex( menuOptionString, MAX_SHORT_STRING - 1, "%L", player_id, "EXIT" );
        menu_additem( menu, menuOptionString, _, 0 );
    }
}

public cmd_listrecent_handler( player_id, menu, item )
{
    LOGGER( 128, "I AM ENTERING ON cmd_listrecent_handler(3) player_id: %d, menu: %d, item: %d", player_id, menu, item )

    // Let go to destroy the menu and clean some memory. As the menu is not paginated, the item 9
    // is the key 0 on the keyboard. Also, the item 8 is the key 9; 7, 8; 6, 7; 5, 6; 4, 5; etc.
    if( item < 0
        || ( item == 9
             && g_recentMapsMenuPages[ player_id ] == 0 ) )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        LOGGER( 1, "    ( cmd_listrecent_handler ) Just Returning PLUGIN_HANDLED, as menu is destroyed." )
        return PLUGIN_HANDLED;
    }

    // If the 0 button item is hit, and we are not on the first page, we must to perform the back option.
    if( item == 9
        && g_recentMapsMenuPages[ player_id ] > 0 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        g_recentMapsMenuPages[ player_id ] ? g_recentMapsMenuPages[ player_id ]-- : 0;

        // Try to block/difficult players from performing the Denial Of Server attack.
        // showRecentMapsListMenu( player_id );
        set_task( 0.1, "showRecentMapsListMenu", player_id );

        LOGGER( 1, "    ( cmd_listrecent_handler ) Just Returning PLUGIN_HANDLED, doing the back button." )
        return PLUGIN_HANDLED;
    }

    // If the 9 button item is hit, and we are on some page not the last one, we must to perform the more option.
    if( item == 8 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        g_recentMapsMenuPages[ player_id ]++;

        // Try to block/difficult players from performing the Denial Of Server attack.
        // showRecentMapsListMenu( player_id );
        set_task( 0.1, "showRecentMapsListMenu", player_id );

        LOGGER( 1, "    ( cmd_listrecent_handler ) Just Returning PLUGIN_HANDLED, doing the more button." )
        return PLUGIN_HANDLED;
    }

    // Just keep showing the menu until the exit button is pressed.
    menu_display( player_id, menu );

    LOGGER( 1, "    ( cmd_listrecent_handler ) Just Returning PLUGIN_HANDLED." )
    return PLUGIN_HANDLED;
}

public cmd_changeLevel( player_id, level, cid )
{
    LOGGER( 128, "I AM ENTERING ON cmd_changeLevel(3) player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOGGER( 1, "    ( cmd_changeLevel ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }

    new argumentsCount = read_argc();

    if( argumentsCount > 1 )
    {
        new arguments[ MAX_BIG_BOSS_STRING ];

        read_args( arguments, charsmax( arguments ) );
        remove_quotes( arguments );

        LOGGER( 8, "( cmd_changeLevel ) " )
        LOGGER( 8, "( cmd_changeLevel ) argumentsCount: %d, arguments: %s", argumentsCount, arguments )

        if( containi( arguments, "now" ) > -1 )
        {
            process_last_round( true, false );
        }
        else
        {
            process_last_round( true );
        }
    }
    else
    {
        process_last_round( true );
    }

    LOGGER( 1, "    ( cmd_changeLevel ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

public cmd_cancelVote( player_id, level, cid )
{
    LOGGER( 128, "I AM ENTERING ON cmd_cancelVote(3) player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOGGER( 1, "    ( cmd_cancelVote ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }

    // If the are on debug mode, just to erase everything, as may be there something overlapping.
#if defined DEBUG
    cancelVoting( true );

    // To avoid the warning unreachable code.
    if( !g_dummy_value )
    {
        LOGGER( 1, "    ( cmd_cancelVote ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }
#endif

    if( g_voteStatus & IS_VOTE_IN_PROGRESS )
    {
        color_print( 0, "%L", LANG_SERVER, "VOT_CANC" );
        cancelVoting( true );
    }
    else
    {
        color_print( 0, "%L", LANG_SERVER, "NO_VOTE_CANC" );
    }

    LOGGER( 1, "    ( cmd_cancelVote ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

stock bool:approvedTheVotingStartLight()
{
    LOGGER( 128, "I AM ENTERING ON approvedTheVotingStartLight(1) get_real_players_number: %d", \
            get_real_players_number() )

    // block the voting on some not allowed situations/cases
    if( get_real_players_number() == 0)
    {
        LOGGER( 1, "    ( approvedTheVotingStartLight ) Returning false 0 players on the server." )
        return false;
    }

    // the rounds start delay task could be running
    remove_task( TASKID_START_VOTING_DELAYED );

    // If the voting menu deletion task is running, remove it then delete the menus right now.
    if( remove_task( TASKID_DELETE_USERS_MENUS ) )
    {
        vote_resetStats();
    }

    LOGGER( 1, "    ( approvedTheVotingStart ) Returning true, due passed by all requirements." )
    return true;
}

/**
 * It will receive a list of maps and will to perform a map voting as if it was an automatic or
 * forced one. The only difference would be the maps it will use. Instead of random, they will
 * the the maps passed to the command `gal_votemap map1 map2 map3 ... map9`.
 *
 * Issue: Add the command `gal_votemap` https://github.com/addonszz/Galileo/issues/48
 */
public cmd_voteMap( player_id, level, cid )
{
    LOGGER( 128, "I AM ENTERING ON cmd_voteMap(3) player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOGGER( 1, "    ( cmd_voteMap ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }

    // There is a real strange `Run time error 5: memory access` bug around these declarations,
    // if you use the approvedTheVotingStart(1) instead of the approvedTheVotingStartLight(1)!
    if( g_voteStatus & IS_VOTE_IN_PROGRESS )
    {
        color_print( player_id, "%L", player_id, "GAL_VOTE_INPROGRESS" );
    }
    else if( approvedTheVotingStartLight() )
    {
        new argumentsCount;
        new arguments[ MAX_BIG_BOSS_STRING ];

        read_args( arguments, charsmax( arguments ) );
        remove_quotes( arguments );

        argumentsCount = read_argc();
        log_amx( "%L: %s", LANG_SERVER, "GAL_VOTE_START", arguments );

        LOGGER( 8, "( cmd_voteMap ) " )
        LOGGER( 8, "( cmd_voteMap ) arguments: %s", arguments )

        if( argumentsCount > 2 )
        {
            new argument[ MAX_MAPNAME_LENGHT  ];
            new bool:isWhitelistEnabled = IS_WHITELIST_ENABLED();

            // Not loaded?
            tryToLoadTheWhiteListFeature();

            // If the voteMapMenuBuilder(1) added some maps, they will be around here, but we do not
            // want to them be here as this is a full spec command.
            clearTheVotingMenu();

            // The initial settings setup
            g_voteMapStatus                   = IS_DISABLED_VOTEMAP_EXIT;
            g_invokerVoteMapNameToDecide[ 0 ] = '^0';

            // To start from 1 because the first argument 0, is the command line name `gal_startvote`.
            for( new index = 1; index < argumentsCount; index++ )
            {
                read_argv( index, argument, charsmax( argument ) );
                LOGGER( 8, "( cmd_voteMap ) argument[%d]: %s", index, argument )

                if( IS_WHITELIST_BLOCKING( isWhitelistEnabled, argument ) )
                {
                    console_print( player_id, "%s: %L", argument, player_id, "GAL_MATCH_WHITELIST" );
                    LOGGER( 8, "    ( cmd_voteMap ) %s: %L", argument, player_id, "GAL_MATCH_WHITELIST" )

                    goto invalid_map_provited;
                }
                else if( IS_MAP_VALID( argument ) )
                {
                    LOGGER( 8, "    ( cmd_voteMap ) argument is a valid map." )
                    addMapToTheVotingMenu( argument, "" );
                }
                else if( -1 < containi( argument, "nointro" ) < 2 )
                {
                    LOGGER( 8, "    ( cmd_voteMap ) Entering on argument `nointro`" )
                    g_voteMapStatus |= IS_DISABLED_VOTEMAP_INTRO;
                }
                else if( -1 < containi( argument, "norunoff" ) < 2  )
                {
                    LOGGER( 8, "    ( cmd_voteMap ) Entering on argument `norunoff`" )
                    g_voteMapStatus |= IS_DISABLED_VOTEMAP_RUNOFF;
                }
                else if( -1 < containi( argument, "noextension" ) < 2 )
                {
                    LOGGER( 8, "    ( cmd_voteMap ) Entering on argument `noextension`" )
                    g_voteMapStatus |= IS_DISABLED_VOTEMAP_EXTENSION;
                }
                else if( -1 < containi( argument, "loadnominations" ) < 2 )
                {
                    LOGGER( 8, "    ( cmd_voteMap ) Entering on argument `loadnominations`" )

                    // Load on the nominations maps.
                    loadOnlyNominationVoteChoices();
                }
                else
                {
                    showGalVoteMapHelp( player_id, index, argument );
                    invalid_map_provited:

                    // If this was just called but not within the sufficient maps, the menu will contain
                    // invalid maps, therefore clean it just to be sure.
                    clearTheVotingMenu();

                    // As should not be any invalid arguments, we do allow to keep going on, otherwise
                    // we would have to use a buffers loader as on announceVoteBlockedMap(4) and
                    // flushVoteBlockedMaps(3) to avoid the client overflow when too many how arguments
                    // are passed by.
                    LOGGER( 1, "    ( cmd_voteMap ) Returning PLUGIN_HANDLED" )
                    return PLUGIN_HANDLED;
                }
            }

            LOGGER( 8, "    ( cmd_voteMap ) g_voteMapStatus: %d", g_voteMapStatus )
            startVoteMapVoting( player_id );
        }
        else
        {
            showGalVoteMapHelp( player_id );
        }
    }

    LOGGER( 1, "    ( cmd_voteMap ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

stock startVoteMapVoting( player_id )
{
    LOGGER( 128, "I AM ENTERING ON startVoteMapVoting(1) player_id: %s", player_id )

    if( g_totalVoteOptions > 1 )
    {
        // Load the voting time
        g_votingSecondsRemaining = get_pcvar_num( cvar_voteDuration );

        // Save the invoker id to use it later when we get the outcome result
        g_voteMapInvokerPlayerId = player_id;

        // to prepare the initial voting state, forcing the start up.
        configureVotingStart( true );

        // Show up the voting menu
        initializeTheVoteDisplay();
    }
    else
    {
        // Vote creation failed; no maps found.
        color_print( 0, "%L", LANG_PLAYER, "GAL_VOTE_NOMAPS" );

        finalizeVoting();
        showGalVoteMapHelp( player_id );
    }
}

/**
 * This is the `gal_votemap` admin's command line help displayer.
 */
stock showGalVoteMapHelp( player_id, index = 0, argument[] = {0} )
{
    LOGGER( 128, "I AM ENTERING ON showGalVoteMapHelp(1) argument: %s", argument )

    if( argument[ 0 ] )
    {
        console_print( player_id,
                "^nThe argument `%d=%s` could not be recognized as a valid map or option.", index, argument );
    }

    // It was necessary to split the message up to 190 characters due the output print being cut.
    console_print( player_id,
           "Examples:\
            ^ngal_votemap map1 map2 map3 map4 ... map9 -nointro -noextension -norunoff" );

    console_print( player_id,
           "gal_votemap map1 map2 map3 map4 ... map9\
            ^ngal_votemap map1 map2 map3 -nointro -noextension" );

    console_print( player_id,
           "gal_votemap map1 map2 -nointro\
            ^ngal_votemap map1 map2 -loadnominations\
            ^ngal_votemap map1 map2" );
}

/**
 * This is the main `say galmenu` builder called from the cmd_say(1) handler.
 */
stock voteMapMenuBuilder( player_id )
{
    LOGGER( 128, "I AM ENTERING ON voteMapMenuBuilder(0) player_id: %d", player_id )

    // The initial settings setup
    g_voteMapStatus                   = IS_DISABLED_VOTEMAP_EXIT;
    g_invokerVoteMapNameToDecide[ 0 ] = '^0';

    displayVoteMapMenuHook( player_id );
}

/**
 * Due there are several first menu options, take `VOTEMAP_FIRST_PAGE_ITEMS_COUNTING` items less.
 */
#define VOTEMAP_FIRST_PAGE_ITEMS_COUNTING 4

/**
 * Used to allow the menu displayVoteMapMenu(1) to have parameters within a default value.
 * It is because public functions are not allow to have a default value and we need this function
 * be public to allow it to be called from a set_task().
 */
public displayVoteMapMenuHook( player_id )
{
    LOGGER( 128, "I AM ENTERING ON displayVoteMapMenuHook(1) currentPage: %d", g_voteMapMenuPages[ player_id ] )
    displayVoteMapMenu( player_id );
}

/**
 * This is the main menu `say galmenu` builder.
 */
stock displayVoteMapMenu( player_id )
{
    LOGGER( 128, "I AM ENTERING ON displayVoteMapMenu(1) player_id: %d", player_id )

    new mapIndex;
    new itemsCount;
    new nominationsMapsCount;

    new choice        [ MAX_MAPNAME_LENGHT + 32 ];
    new nominationMap [ MAX_MAPNAME_LENGHT ];
    new selectedMap   [ MAX_SHORT_STRING ];
    new disabledReason[ MAX_SHORT_STRING ];

    nominationsMapsCount  = ArraySize( g_nominationLoadedMapsArray );

    // Calculate how much pages there are available.
    new currentPageNumber = g_voteMapMenuPages[ player_id ];
    new lastPageNumber    = ( ( ( nominationsMapsCount + 1 ) / MAX_NOM_MENU_ITEMS_PER_PAGE )
                        + ( ( ( ( nominationsMapsCount + 1 ) % MAX_NOM_MENU_ITEMS_PER_PAGE ) > 0 ) ? 1 : 0 ) );

    // To create the menu
    formatex( disabledReason, charsmax( disabledReason ),
            IS_COLORED_CHAT_ENABLED() ? "%L\R%d /%d" : "%L  %d /%d",
            player_id, "GAL_LISTMAPS_TITLE", currentPageNumber + 1, lastPageNumber );

    new menu = menu_create( disabledReason, "handleDisplayVoteMap" );

    // The first page contains by default options, then the first page will get one less items due
    // the extra options.
    if( currentPageNumber < 1 )
    {
        new bool:isOn;
        formatex( selectedMap, charsmax( selectedMap ), "%s%L", COLOR_YELLOW, player_id, "GAL_CHOICE_MAP", 0, 0 );

        mapIndex   = 0;
        itemsCount = 4;

        isOn = g_voteMapStatus & IS_DISABLED_VOTEMAP_INTRO != 0;
        formatex( disabledReason, charsmax( disabledReason ), "-nointro %s", isOn ? selectedMap : {0} );
        menu_additem( menu, disabledReason, _, 0 );

        isOn = g_voteMapStatus & IS_DISABLED_VOTEMAP_RUNOFF != 0;
        formatex( disabledReason, charsmax( disabledReason ), "-norunoff %s", isOn ? selectedMap : {0} );
        menu_additem( menu, disabledReason, _, 0 );

        isOn = g_voteMapStatus & IS_DISABLED_VOTEMAP_EXTENSION != 0;
        formatex( disabledReason, charsmax( disabledReason ), "-noextension %s", isOn ? selectedMap : {0} );
        menu_additem( menu, disabledReason, _, 0 );

        isOn = g_voteMapStatus & IS_ENABLED_VOTEMAP_NOMINATIONS != 0;
        formatex( disabledReason, charsmax( disabledReason ), "-loadnominations %s", isOn ? selectedMap : {0} );
        menu_additem( menu, disabledReason, _, isOn ? ( 1 << 26 ) : 0 );

        // Add some space from the last option.
        // menu_addblank( menu, 0 );
    }
    else
    {
        // Due there are several first menu options, take `VOTEMAP_FIRST_PAGE_ITEMS_COUNTING` items less.
        mapIndex   = currentPageNumber * MAX_NOM_MENU_ITEMS_PER_PAGE - VOTEMAP_FIRST_PAGE_ITEMS_COUNTING;
        itemsCount = 0;
    }

    // Disables the menu paging.
    menu_setprop( menu, MPROP_PERPAGE, 0 );

    // Configure the menu buttons.
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_EXITNAME, menu, "EXIT" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_NEXTNAME, menu, "MORE" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_BACKNAME, menu, "BACK" )

    new bool:isWhitelistEnabled = IS_WHITELIST_ENABLED();

    // Not loaded?
    tryToLoadTheWhiteListFeature();

    for( ; mapIndex < nominationsMapsCount && itemsCount < MAX_NOM_MENU_ITEMS_PER_PAGE; mapIndex++ )
    {
        GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, nominationMap )
        itemsCount++;

        // Start the menu entry item calculation
        {
            // in most cases, the map will be available for selection, so assume that's the case here
            selectedMap   [ 0 ] = '^0';
            disabledReason[ 0 ] = '^0';

            // disable if the map has already been nominated
            if( map_isInMenu( nominationMap ) )
            {
                formatex( selectedMap, charsmax( selectedMap ), "%s%L", COLOR_YELLOW, player_id, "GAL_MATCH_NOMINATED" );
            }
            else if( g_totalVoteOptions > 8 )
            {
                formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_GRP_FAIL_TOOMANY_2" );
            }
            else if( equali( g_currentMapName, nominationMap ) )
            {
                formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_CURRENTMAP" );
            }
            else if( IS_WHITELIST_BLOCKING( isWhitelistEnabled, nominationMap ) )
            {
                formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_WHITELIST" );
            }

            formatex( choice, charsmax( choice ), "%s %s %s", nominationMap, selectedMap, disabledReason );
            LOGGER( 4, "( displayVoteMapMenu ) choice: %s", choice )

            menu_additem( menu, choice, _, ( disabledReason[ 0 ] == '^0' ? 0 : ( 1 << 26 ) ) );

        } // end the menu entry item calculation.

    } // end for 'mapIndex'.

    LOGGER( 4, "( displayVoteMapMenu ) itemsCount: %d, mapIndex: %d", itemsCount, mapIndex )

    addMenuMoreBackStartOptions( menu, player_id, disabledReason, mapIndex < nominationsMapsCount, currentPageNumber > 0, itemsCount );
    menu_display( player_id, menu );
}

stock addMenuMoreBackStartOptions( menu, player_id, disabledReason[], bool:isToEnableMoreButton, bool:isToEnableBackButton, itemsCount )
{
    LOGGER( 128, "I AM ENTERING ON addMenuMoreBackStartOptions(5) isToEnableMoreButton: %d", isToEnableMoreButton )
    addMenuMoreBackButtons( menu, player_id, disabledReason, isToEnableMoreButton, isToEnableBackButton, itemsCount );

    // To add the exit button
    if( g_totalVoteOptions > 1 )
    {
        formatex( disabledReason, MAX_SHORT_STRING - 1, "%L%s (%d)", player_id, "CMD_MENU", COLOR_YELLOW, g_totalVoteOptions );
        menu_additem( menu, disabledReason, _, 0 );
    }
    else
    {
        formatex( disabledReason, MAX_SHORT_STRING - 1, "%L%s (%d)", player_id, "EXIT", COLOR_GREY, g_totalVoteOptions );
        menu_additem( menu, disabledReason, _, 0 );
    }
}

/**
 * This is the `say galmenu` main menu handler.
 */
public handleDisplayVoteMap( player_id, menu, item )
{
    LOGGER( 128, "I AM ENTERING ON handleDisplayVoteMap(3) player_id: %d, menu: %d, item: %d", player_id, menu, item )

    // Let go to destroy the menu and clean some memory. As the menu is not paginated, the item 9
    // is the key 0 on the keyboard. Also, the item 8 is the key 9; 7, 8; 6, 7; 5, 6; 4, 5; etc.
    if( item < 0
        || ( item == 9
             && g_totalVoteOptions < 2 ) )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        LOGGER( 1, "    ( handleDisplayVoteMap ) Just Returning PLUGIN_HANDLED, the menu is destroyed." )
        return PLUGIN_HANDLED;
    }

    // To start the voting
    if( item == 9
        && g_totalVoteOptions > 1 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        displayVoteMapMenuCommands( player_id );

        LOGGER( 1, "    ( handleDisplayVoteMap ) Just Returning PLUGIN_HANDLED, starting the voting." )
        return PLUGIN_HANDLED;
    }

    // If the 8 button item is hit, and we are not on the first page, we must to perform the back option.
    if( item == 7 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        g_voteMapMenuPages[ player_id ] ? g_voteMapMenuPages[ player_id ]-- : 0;

        // Try to block/difficult players from performing the Denial Of Server attack.
        // displayVoteMapMenuHook( player_id );
        set_task( 0.1, "displayVoteMapMenuHook", player_id );

        LOGGER( 1, "    ( handleDisplayVoteMap ) Just Returning PLUGIN_HANDLED, doing the back button." )
        return PLUGIN_HANDLED;
    }

    // If the 9 button item is hit, and we are on some page not the last one, we must to perform the more option.
    if( item == 8 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        g_voteMapMenuPages[ player_id ]++;

        // Try to block/difficult players from performing the Denial Of Server attack.
        // displayVoteMapMenuHook( player_id );
        set_task( 0.1, "displayVoteMapMenuHook", player_id );

        LOGGER( 1, "    ( handleDisplayVoteMap ) Just Returning PLUGIN_HANDLED, doing the more button." )
        return PLUGIN_HANDLED;
    }

    // Due the firsts items to be specials, intercept them, but if and only if we are on the menu's first page.
    if( g_voteMapMenuPages[ player_id ] == 0
        && item < 4 )
    {
        switch( item )
        {
            // pressedKeyCode 0 means the keyboard key 1
            case 0:
            {
                LOGGER( 8, "    ( cmd_voteMap ) Entering on argument `nointro`" )
                TOGGLE_BIT_FLAG_ON_OFF( g_voteMapStatus, IS_DISABLED_VOTEMAP_INTRO )
            }
            case 1:
            {
                LOGGER( 8, "    ( cmd_voteMap ) Entering on argument `norunoff`" )
                TOGGLE_BIT_FLAG_ON_OFF( g_voteMapStatus, IS_DISABLED_VOTEMAP_RUNOFF )
            }
            case 2:
            {
                LOGGER( 8, "    ( cmd_voteMap ) Entering on argument `noextension`" )
                TOGGLE_BIT_FLAG_ON_OFF( g_voteMapStatus, IS_DISABLED_VOTEMAP_EXTENSION )
            }
            case 3:
            {
                // Load on the nominations maps.
                loadOnlyNominationVoteChoices();

                // This option cannot be undone, to reduce the code complexity.
                g_voteMapStatus |= IS_ENABLED_VOTEMAP_NOMINATIONS;
                LOGGER( 8, "    ( cmd_voteMap ) Entering on argument `loadnominations`" )
            }
        }
    }
    else
    {
        new mapName[ MAX_MAPNAME_LENGHT ];
        new mapInfo[ MAX_MAPNAME_LENGHT ];
        new pageSeptalNumber = convert_numeric_base( g_voteMapMenuPages[ player_id ], 10, MAX_NOM_MENU_ITEMS_PER_PAGE );

        // Due there are several first menu options, take `VOTEMAP_FIRST_PAGE_ITEMS_COUNTING` items less.
        item = convert_numeric_base( pageSeptalNumber * 10, MAX_NOM_MENU_ITEMS_PER_PAGE, 10 ) + item - VOTEMAP_FIRST_PAGE_ITEMS_COUNTING;

        GET_MAP_NAME( g_nominationLoadedMapsArray, item, mapName )
        GET_MAP_INFO( g_nominationLoadedMapsArray, item, mapInfo )

        // Toggle it if enabled
        map_isInMenu( mapName ) ? removeMapFromTheVotingMenu( mapName ) : addMapToTheVotingMenu( mapName, mapInfo );
    }

    DESTROY_PLAYER_NEW_MENU_TYPE( menu )

    // displayVoteMapMenuHook( player_id );
    set_task( 0.1, "displayVoteMapMenuHook", player_id );

    LOGGER( 1, "    ( handleDisplayVoteMap ) Just Returning PLUGIN_HANDLED, successful nomination." )
    return PLUGIN_HANDLED;
}

/**
 * Used to select indexes values at the array `g_votingMapNames` instead of the usual array, when we're
 * are on the submenu `Commands Menu`.
 */
#define VOTEMAP_VOTING_MAP_NAMES_INDEX_FLAG -2

/**
 * This is the secondary `say galmenu` builder. It is used to choose to cancel the personal voting,
 * start it or see the added maps.
 */
public displayVoteMapMenuCommands( player_id )
{
    LOGGER( 128, "I AM ENTERING ON displayVoteMapMenuCommands(1) player_id: %d", player_id )

    new mapIndex;
    new info[ 1 ];

    new choice          [ MAX_SHORT_STRING ];
    new menuOptionString[ MAX_SHORT_STRING ];

    // To create the menu
    formatex( choice, charsmax( choice ), "%L", player_id, "CMD_MENU" );
    new menu = menu_create( choice, "handleDisplayVoteMapCommands" );

    // The first menus items
    formatex( choice, charsmax( choice ), "%L%s (%d)", player_id, "GAL_VOTE_START", COLOR_YELLOW, g_totalVoteOptions );
    menu_additem( menu, choice, { -1 }, g_totalVoteOptions > 1 ? 0 : ( 1 << 26 ) );

    formatex( choice, charsmax( choice ), "%L", player_id, "EXIT" );
    menu_additem( menu, choice, { -1 }, 0 );

    formatex( choice, charsmax( choice ), "%L", player_id, "CANC_VOTE" );
    menu_additem( menu, choice, { -1 }, g_totalVoteOptions > 0 ? 0 : ( 1 << 26 ) );

    formatex( choice, charsmax( choice ), "%L", player_id, "GAL_VOTE_GO_TO_PAGE" );
    menu_additem( menu, choice, { -1 }, 0 );

    // Add some space from the first menu options.
    // menu_addblank( menu, 0 );

    // Configure the menu buttons.
    SET_MENU_LANG_STRING_PROPERTY( MPROP_EXITNAME, menu, "GAL_LISTMAPS_TITLE" )
    SET_MENU_LANG_STRING_PROPERTY( MPROP_NEXTNAME, menu, "MORE" )
    SET_MENU_LANG_STRING_PROPERTY( MPROP_BACKNAME, menu, "BACK" )

    for( mapIndex = 0; mapIndex < g_totalVoteOptions; mapIndex++ )
    {
        if( g_votingMapNames[ mapIndex ][ 0 ] )
        {
            info[ 0 ] = VOTEMAP_VOTING_MAP_NAMES_INDEX_FLAG - mapIndex;
            formatex( choice, charsmax( choice ), "%s%s %L", g_votingMapNames[ mapIndex ], COLOR_YELLOW, player_id, "GAL_MATCH_NOMINATED" );

            LOGGER( 4, "( displayVoteMapMenuCommands ) choice: %s, info[0]: %d", choice, info[ 0 ] )
            menu_additem( menu, choice, info, 0 );
        }
    }

    // The exit option is not showing up at the button 0, but on 9! This forces it to.
    while( mapIndex + 3 < MAX_NOM_MENU_ITEMS_PER_PAGE )
    {
        mapIndex++;
        formatex( menuOptionString, MAX_SHORT_STRING - 1, "%L", player_id, "OFF" );
        menu_additem( menu, menuOptionString, _, 1 << 26 );

        // When using slot=1 this might break your menu. To achieve this functionality
        // menu_addblank2() should be used (AMXX 183 only).
        // menu_addblank( menu, 1 );
    }

    menu_display( player_id, menu );
}

/**
 * This is the secondary `say galmenu` handler.
 */
public handleDisplayVoteMapCommands( player_id, menu, item )
{
    LOGGER( 128, "I AM ENTERING ON handleDisplayVoteMapCommands(3) player_id: %d, menu: %d, item: %d", player_id, menu, item )

    if( item == MENU_EXIT )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        displayVoteMapMenu( player_id );

        LOGGER( 1, "    ( handleDisplayVoteMapCommands ) Just Returning PLUGIN_HANDLED, returning to the main menu." )
        return PLUGIN_HANDLED;
    }

    if( item < 0 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        LOGGER( 1, "    ( handleDisplayVoteMapCommands ) Just Returning PLUGIN_HANDLED, the menu is destroyed." )
        return PLUGIN_HANDLED;
    }

    if( item == 0 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        startVoteMapVoting( player_id );

        LOGGER( 1, "    ( handleDisplayVoteMapCommands ) Just Returning PLUGIN_HANDLED, starting the voting." )
        return PLUGIN_HANDLED;
    }

    if( item == 1 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        LOGGER( 1, "    ( handleDisplayVoteMapCommands ) Just Returning PLUGIN_HANDLED, starting the voting." )
        return PLUGIN_HANDLED;
    }

    if( item == 2 )
    {
        clearTheVotingMenu();
        g_voteMapMenuPages[ player_id ] = 0;

        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        LOGGER( 1, "    ( handleDisplayVoteMapCommands ) Just Returning PLUGIN_HANDLED, cleaning the voting." )
        return PLUGIN_HANDLED;
    }

    if( item == 3 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        client_cmd( player_id, "messagemode ^"say %s^"", GAL_VOTEMAP_MENU_COMMAND );

        LOGGER( 1, "    ( handleDisplayVoteMapCommands ) Just Returning PLUGIN_HANDLED, opening go to page." )
        return PLUGIN_HANDLED;
    }

    // debugging menu info tracker
    LOGGER( 4, "", debug_nomination_match_choice( player_id, menu, item ) )

    new access;
    new callback;

    new info[ 1 ];
    new mapName[ MAX_MAPNAME_LENGHT ];
    new mapInfo[ MAX_MAPNAME_LENGHT ];

    menu_item_getinfo( menu, item, access, info, sizeof info, _, _, callback );

    if( info[ 0 ] > -1 )
    {
        GET_MAP_NAME( g_nominationLoadedMapsArray, info[0], mapName )
        GET_MAP_INFO( g_nominationLoadedMapsArray, info[0], mapInfo )

        // Toggle it if enabled
        map_isInMenu( mapName ) ? removeMapFromTheVotingMenu( mapName ) : addMapToTheVotingMenu( mapName, mapInfo );
    }
    else
    {
        new mapIndex = abs( info[ 0 ] ) + VOTEMAP_VOTING_MAP_NAMES_INDEX_FLAG;

        if( g_votingMapNames[ mapIndex ][ 0 ] )
        {
            removeMapFromTheVotingMenu( g_votingMapNames[ mapIndex ] );
        }
    }

    // Before re-creating the menu within the updated data, we need to wait for it be destroyed.
    // Try to block/difficult players from performing the Denial Of Server attack.
    DESTROY_PLAYER_NEW_MENU_TYPE( menu )

    // displayVoteMapMenuCommands( player_id );
    set_task( 0.1, "displayVoteMapMenuCommands", player_id );

    LOGGER( 1, "    ( handleDisplayVoteMapCommands ) Just Returning PLUGIN_HANDLED, the menu is showed again." )
    return PLUGIN_HANDLED;
}

stock debug_nomination_match_choice( player_id, menu, item )
{
    LOGGER( 128, "I AM ENTERING ON debug_nomination_match_choice(3) player_id: %d, menu: %d, item: %d", player_id, menu, item )

    new access;
    new callback;

    new info[ 1 ];
    LOGGER( 4, "( debug_nomination_match_choice ) item: %d, player_id: %d, menu: %d, \
            g_menuMapIndexForPlayerArrays[player_id]: %d", \
            item, player_id, menu, g_menuMapIndexForPlayerArrays[ player_id ] )

    // Get item info
    menu_item_getinfo( menu, item, access, info, sizeof info, _, _, callback );
    LOGGER( 4, "( debug_nomination_match_choice ) info[0]: %d, access: %d, menu%d", info[ 0 ], access, menu )

    return 0;
}

/**
 * This set up the `say galmenu` final admin's choice builder.
 */
stock openTheVoteMapActionMenu()
{
    LOGGER( 128, "I AM ENTERING ON openTheVoteMapActionMenu(0) player_id: %d", g_voteMapInvokerPlayerId )

    g_pendingMapVoteCountdown = get_pcvar_num( cvar_voteDuration ) + 120;
    set_task( 1.0, "displayTheVoteMapActionMenu", TASKID_PENDING_VOTE_COUNTDOWN, _, _, "a", g_pendingMapVoteCountdown );
}

/**
 * This is the `say galmenu` final admin's choice builder.
 */
public displayTheVoteMapActionMenu()
{
    LOGGER( 128, "I AM ENTERING ON displayTheVoteMapActionMenu(0) player_id: %d", g_voteMapInvokerPlayerId )
    new player_id = g_voteMapInvokerPlayerId;

    if( is_user_connected( player_id )
        && --g_pendingMapVoteCountdown > 0 )
    {
        new winnerMap   [ MAX_MAPNAME_LENGHT ];
        new menu_body   [ MAX_LONG_STRING    ];
        new menu_counter[ MAX_SHORT_STRING   ];

        new menu_id;
        new menuKeys;
        new menuKeysUnused;
        new bool:allowChange = g_invokerVoteMapNameToDecide[ 0 ] != 0;

        // To change the keys, go also to configureTheVotingMenus(0)
        menuKeys = MENU_KEY_1;

        // If the g_invokerVoteMapNameToDecide is empty, then the winner map is the stay here option.
        if( allowChange )
        {
            menuKeys |= MENU_KEY_3 | MENU_KEY_5;
            formatex( winnerMap, charsmax( winnerMap ), "%s", g_invokerVoteMapNameToDecide );
        }
        else
        {
            formatex( winnerMap, charsmax( winnerMap ), "%L", player_id, "GAL_OPTION_STAY" );
        }

        formatex( menu_counter, charsmax( menu_counter ),
                " %s(%s%d %L%s)",
                COLOR_YELLOW, COLOR_GREY, g_pendingMapVoteCountdown, LANG_PLAYER, "GAL_TIMELEFT", COLOR_YELLOW );

        formatex( menu_body, charsmax( menu_body ),
               "\
                %L%s: %s%s^n\
                %s%L^n\
                ^n%s1.%s %L %s\
                ^n%s3.%s %L %s\
                ^n%s5.%s %L\
                ",
                player_id, "THE_RESULT", COLOR_RED, COLOR_WHITE, winnerMap,
                COLOR_YELLOW, player_id, "WANT_CONTINUE",
                COLOR_RED, COLOR_WHITE, player_id, "CANC_VOTE", menu_counter,
                COLOR_RED, allowChange ? COLOR_WHITE : COLOR_GREY, player_id, "CHANGE_MAP_TO"              , winnerMap,
                COLOR_RED, allowChange ? COLOR_WHITE : COLOR_GREY, player_id, "GAL_OPTION_CANCEL_PARTIALLY", winnerMap,
                0 );

        get_user_menu( player_id, menu_id, menuKeysUnused );

        if( menu_id == 0
            || menu_id == g_chooseVoteMapQuestionMenuId )
        {
            show_menu( player_id, menuKeys, menu_body, ( g_pendingMapVoteCountdown == 1 ? 1 : 2 ),
                    CHOOSE_VOTEMAP_MENU_QUESTION );
        }

        LOGGER( 4, "( displayTheVoteMapActionMenu ) menu_body: %s", menu_body )
        LOGGER( 4, "    menu_id: %d, menuKeys: %d, ", menu_id, menuKeys )
        LOGGER( 4, "    g_pendingMapVoteCountdown: %d", g_pendingMapVoteCountdown )
    }
    else
    {
        // To perform the default action automatically, nothing is answered.
        handleVoteMapActionMenu( player_id, 0 );
    }

    LOGGER( 4, "%48s", " ( displayTheVoteMapActionMenu| out )" )
}

/**
 * This is the `say galmenu` final admin's choice handler.
 */
public handleVoteMapActionMenu( player_id, pressedKeyCode )
{
    LOGGER( 128, "I AM ENTERING ON handleVoteMapActionMenu(2) player_id: %d, pressedKeyCode: %d", \
            player_id, pressedKeyCode )

    // Allow the result outcome to be processed
    g_voteMapStatus = 0;

    // Stop the menu from showing up again
    remove_task( TASKID_PENDING_VOTE_COUNTDOWN );

    switch( pressedKeyCode )
    {
        // pressedKeyCode 0 means the keyboard key 1
        case 0:
        {
            // If we are rejecting the results, allow a new map end voting to start
            g_voteStatus &= ~IS_VOTE_OVER;

            if( g_invokerVoteMapNameToDecide[ 0 ] )
            {
                color_print( 0, "%L. %L: %s", LANG_PLAYER, "RESULT_REF", LANG_PLAYER, "VOT_CANC", g_invokerVoteMapNameToDecide );
            }

            toShowTheMapNextHud( "RESULT_REF", "VOT_CANC", "GAL_OPTION_STAY_MAP", g_currentMapName );
        }
        case 2:
        {
            if( g_invokerVoteMapNameToDecide[ 0 ] )
            {
                // The end of map count countdown will immediately start, so there is not point int showing any messages.
                setNextMap( g_currentMapName, g_invokerVoteMapNameToDecide );
                process_last_round( true );
            }
        }
        case 4:
        {
            // Only set the next map
            if( g_invokerVoteMapNameToDecide[ 0 ] )
            {
                color_print( 0, "%L. %L: %s", LANG_PLAYER, "RESULT_ACC", LANG_PLAYER, "VOTE_SUCCESS", g_invokerVoteMapNameToDecide );
                toShowTheMapNextHud( "RESULT_ACC", "DMAP_MAP_EXTENDED", "GAL_WINNER_ORDERED1", g_invokerVoteMapNameToDecide );

                setNextMap( g_currentMapName, g_invokerVoteMapNameToDecide );
            }
        }
    }

    LOGGER( 1, "    ( handleEndOfTheMapVoteChoice ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

/**
 * Called when need to start a vote map, where the command line first argument could be:
 *    -nochange: extend the current map, aka, Keep Current Map, will to do the real extend.
 *    -restart: extend the current map, aka, Keep Current Map restart the server at the current map.
 */
public cmd_startVote( player_id, level, cid )
{
    LOGGER( 128, "I AM ENTERING ON cmd_startVote(3) player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOGGER( 1, "    ( cmd_startVote ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }

    if( g_voteStatus & IS_VOTE_IN_PROGRESS )
    {
        color_print( player_id, "%L", player_id, "GAL_VOTE_INPROGRESS" );
    }
    else
    {
        g_isToChangeMapOnVotingEnd = true;

        if( read_argc() == 2 )
        {
            new argument[ 32 ];

            read_args( argument, charsmax( argument ) );
            remove_quotes( argument );

            if( equali( argument, "-nochange" ) )
            {
                g_isToChangeMapOnVotingEnd = false;
            }
            else if( equali( argument, "-restart", 4 ) )
            {
                g_isTimeToRestart = true;
            }

            LOGGER( 8, "( cmd_startVote ) equal( %s, '-restart', 4 )? %d", argument, equal( argument, "-restart", 4 ) )
        }

        LOGGER( 8, "( cmd_startVote ) g_isTimeToRestart? %d, g_isToChangeMapOnVotingEnd? %d, \
                g_voteStatus & IS_FORCED_VOTE: %d", g_isTimeToRestart, g_isToChangeMapOnVotingEnd, \
                g_voteStatus & IS_FORCED_VOTE != 0 )

        vote_startDirector( true );
    }

    LOGGER( 1, "    ( cmd_startVote ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

public cmd_createMapFile( player_id, level, cid )
{
    LOGGER( 128, "I AM ENTERING ON cmd_createMapFile(3) player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOGGER( 1, "    ( cmd_createMapFile ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }

    new argumentsNumber = read_argc() - 1;

    switch( argumentsNumber )
    {
        case 1:
        {
            new mapFileName[ MAX_MAPNAME_LENGHT   ];
            new mapFilePath[ MAX_FILE_PATH_LENGHT ];

            read_argv( 1, mapFileName, charsmax( mapFileName ) );
            remove_quotes( mapFileName );

            formatex( mapFilePath, charsmax( mapFilePath ), "%s/%s", g_configsDirPath, mapFileName );
            createMapFileFromAllServerMaps( player_id, mapFilePath );
        }
        default:
        {
            // inform of correct usage
            console_print( player_id, "%L", player_id, "GAL_CMD_CREATEFILE_USAGE1" );
            console_print( player_id, "%L", player_id, "GAL_CMD_CREATEFILE_USAGE2" );
        }
    }

    LOGGER( 1, "    ( cmd_createMapFile ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

stock createMapFileFromAllServerMaps( player_id, mapFilePath[] )
{
    LOGGER( 128, "I AM ENTERING ON createMapFileFromAllServerMaps(2) player_id: %d, mapFilePath: %s", player_id, mapFilePath )

    // map name is MAX_MAPNAME_LENGHT, .bsp: 4 + string terminator: 1 = 5
    new loadedMapName[ MAX_MAPNAME_LENGHT + 5 ];

    new directoryDescriptor = open_dir( "maps", loadedMapName, charsmax( loadedMapName )  );

    if( directoryDescriptor )
    {
        new mapFileDescriptor = fopen( mapFilePath, "wt" );

        if( mapFileDescriptor )
        {
            new mapCount;
            new mapNameLength;

            new Array:allMapsArray = ArrayCreate( MAX_MAPNAME_LENGHT );

            while( next_file( directoryDescriptor, loadedMapName, charsmax( loadedMapName ) ) )
            {
                mapNameLength = strlen( loadedMapName );

                if( mapNameLength > 4
                    && equali( loadedMapName[ mapNameLength - 4 ], ".bsp", 4 ) )
                {
                    loadedMapName[ mapNameLength - 4 ] = '^0';

                    if( IS_MAP_VALID( loadedMapName ) )
                    {
                        ArrayPushString( allMapsArray, loadedMapName );
                    }
                }
            }

            mapCount = ArraySize( allMapsArray );
            ArraySort( allMapsArray, "sort_stringsi" );

            for( new index = 0; index < mapCount; index++ )
            {
                ArrayGetString( allMapsArray, index, loadedMapName, charsmax( loadedMapName) );
                fprintf( mapFileDescriptor, "%s^n", loadedMapName );
            }

            fclose( mapFileDescriptor );
            ArrayDestroy( allMapsArray );

            console_print( player_id, "%L", player_id, "GAL_CREATIONSUCCESS", mapFilePath, mapCount );
        }
        else
        {
            console_print( player_id, "%L", player_id, "GAL_CREATIONFAILED", mapFilePath );
            LOGGER( 1, "ERROR: %L", LANG_SERVER, "GAL_CREATIONFAILED", mapFilePath )
        }

        close_dir( directoryDescriptor );
    }
    else
    {
        // directory not found, wtf?
        console_print( player_id, "%L", player_id, "GAL_MAPSFOLDERMISSING" );
        LOGGER( 1, "ERROR: %L", LANG_SERVER, "GAL_MAPSFOLDERMISSING" )
    }
}

public sort_stringsi( Array:array, elem1, elem2, data[], data_size )
{
    LOGGER( 256, "I AM ENTERING ON sort_stringsi(5) array: %d, elem1: %d, elem2: %d", array, elem1, elem2 )

    new map1[ MAX_MAPNAME_LENGHT ];
    new map2[ MAX_MAPNAME_LENGHT ];

    ArrayGetString( array, elem1, map1, charsmax( map1 ) );
    ArrayGetString( array, elem2, map2, charsmax( map2 ) );

    LOGGER( 256, "    ( sort_stringsi ) Returning %s > %s: %d", map1, map2, strcmp( map1, map2, 1 ) )
    return strcmp( map1, map2, 1 );
}

public cmd_maintenanceMode( player_id, level, cid )
{
    LOGGER( 128, "I AM ENTERING ON cmd_maintenanceMode(3) player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOGGER( 1, "    ( cmd_maintenanceMode ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }

    // Always print to the console for logging, because it is a important event.
    if( g_isOnMaintenanceMode )
    {
        g_isOnMaintenanceMode = false;
        map_restoreEndGameCvars();

        color_print( 0, "%L", LANG_PLAYER, "GAL_CHANGE_MAINTENANCE_STATE", LANG_PLAYER, "GAL_CHANGE_MAINTENANCE_OFF" );
        no_color_print( player_id, "%L", player_id, "GAL_CHANGE_MAINTENANCE_STATE", player_id, "GAL_CHANGE_MAINTENANCE_OFF" );
    }
    else
    {
        g_isOnMaintenanceMode = true;

        color_print( 0, "%L", LANG_PLAYER, "GAL_CHANGE_MAINTENANCE_STATE", LANG_PLAYER, "GAL_CHANGE_MAINTENANCE_ON" );
        no_color_print( player_id, "%L", player_id, "GAL_CHANGE_MAINTENANCE_STATE", player_id, "GAL_CHANGE_MAINTENANCE_ON" );
    }

    LOGGER( 1, "    ( cmd_maintenanceMode ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

public cmd_lookingForCrashes( player_id, level, cid )
{
    LOGGER( 128, "I AM ENTERING ON cmd_lookingForCrashes(3) player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOGGER( 1, "    ( cmd_lookingForCrashes ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }

    new crashedMapsFile;

    new modeFlagFilePath   [ MAX_FILE_PATH_LENGHT ];
    new crashedMapsFilePath[ MAX_FILE_PATH_LENGHT ];

    formatex( modeFlagFilePath, charsmax( modeFlagFilePath ), "%s/%s", g_dataDirPath, TO_STOP_THE_CRASH_SEARCH );
    formatex( crashedMapsFilePath, charsmax( crashedMapsFilePath ), "%s/%s", g_dataDirPath, MAPS_WHERE_THE_SERVER_CRASHED );

    if( file_exists( modeFlagFilePath ) )
    {
        delete_file( modeFlagFilePath );

        if( ( crashedMapsFile = fopen( crashedMapsFilePath, "rt" ) ) )
        {
            new mapLoaded[ MAX_MAPNAME_LENGHT ];

            log_amx( "Stopping the server crash change...^nContents of the file: ^n%s^n", crashedMapsFilePath);
            server_print( "Stopping the server crash change...^nContents of the file: ^n%s^n", crashedMapsFilePath );

            client_print( player_id, print_console, "Stopping the server crash change...^n\
                    See your server console or the server file:^n%s^n", crashedMapsFilePath);

            while( !feof( crashedMapsFile ) )
            {
                fgets( crashedMapsFile, mapLoaded, charsmax( mapLoaded ) );

                trim( mapLoaded );
                server_print( "%s^n", mapLoaded );
            }

            fclose( crashedMapsFile );
        }
        else
        {
            LOGGER( 1, "ERROR, Couldn't open the file ^"%s^")", crashedMapsFilePath )
            log_amx(   "ERROR, Couldn't open the file ^"%s^")", crashedMapsFilePath );
        }
    }
    else
    {
        new message[ MAX_LONG_STRING ];

        formatex( message, charsmax( message ), "^nStarting the crash maps search. This will check all your server maps." );
        log_amx( message );

        console_print( player_id, message );
        console_print( player_id, "To stop the search, run this command again or delete the file" );

        if( ( crashedMapsFile = fopen( crashedMapsFilePath, "a+" ) ) )
        {
            new currentDate[ MAX_SHORT_STRING ];
            get_time( "%m/%d/%Y - %H:%M:%S", currentDate, charsmax( currentDate ) );

            fprintf( crashedMapsFile, "^n^n%s^n", currentDate );
            fclose( crashedMapsFile );

            createMapFileFromAllServerMaps( player_id, modeFlagFilePath );
            runTheServerMapCrashSearch();
        }
        else
        {
            LOGGER( 1, "ERROR, Couldn't create the file ^"%s^")", crashedMapsFilePath )
            log_amx(   "ERROR, Couldn't create the file ^"%s^")", crashedMapsFilePath );
        }
    }

    LOGGER( 1, "    ( cmd_lookingForCrashes ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

/**
 * Generic say handler to determine if we need to act on what was said.
 */
public cmd_say( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_say(1) player_id: %s", player_id )
    new thirdWord[ 2 ];

    static sentence  [ 70 ];
    static firstWord [ 32 ];
    static secondWord[ 32 ];

    sentence  [ 0 ] = '^0';
    firstWord [ 0 ] = '^0';
    secondWord[ 0 ] = '^0';

    read_args( sentence, charsmax( sentence ) );
    remove_quotes( sentence );

    parse( sentence  ,
           firstWord , charsmax( firstWord  ),
           secondWord, charsmax( secondWord ),
           thirdWord , charsmax( thirdWord  ) );

    LOGGER( 4, "( cmd_say ) sentence: %s, firstWord: %s, secondWord: %s, thirdWord: %s", \
            sentence, firstWord, secondWord, thirdWord )

    // if the chat line has more than 2 words, we're not interested at all
    if( thirdWord[ 0 ] == '^0' )
    {
        new userFlags = get_user_flags( player_id );
        LOGGER( 4, "( cmd_say ) the thirdWord is empty." )

        // if the chat line contains 1 word, it could be a map or a one-word command as
        // "say [rtv|rockthe<anything>vote]"
        if( secondWord[ 0 ] == '^0' )
        {
            LOGGER( 4, "( cmd_say ) the secondWord is empty." )

            if( userFlags & ADMIN_MAP
                && containi( firstWord, GAL_VOTEMAP_MENU_COMMAND ) > -1 )
            {
                // Calculate how much pages there are available.
                new nominationsMapsCount = ArraySize( g_nominationLoadedMapsArray );
                new lastPageNumber       = GET_LAST_PAGE_NUMBER( nominationsMapsCount, MAX_NOM_MENU_ITEMS_PER_PAGE )

                setCorrectMenuPage( player_id, firstWord, g_voteMapMenuPages, lastPageNumber );
                voteMapMenuBuilder( player_id );

                LOGGER( 1, "    ( cmd_say ) Just Returning PLUGIN_HANDLED, voteMapMenuBuilder(1) chosen." )
                return PLUGIN_HANDLED;
            }
            else if( ( g_rtvCommands & RTV_CMD_SHORTHAND
                       && equali( firstWord, "rtv" ) )
                     || ( g_rtvCommands & RTV_CMD_DYNAMIC
                          && equali( firstWord, "rockthe", 7 )
                          && equali( firstWord[ strlen( firstWord ) - 4 ], "vote" )
                          && !( g_rtvCommands & RTV_CMD_STANDARD ) ) )
            {
                vote_rock( player_id );

                LOGGER( 1, "    ( cmd_say ) Just Returning PLUGIN_HANDLED, vote_rock(1) chosen." )
                return PLUGIN_HANDLED;
            }
            else if( get_pcvar_num( cvar_nomPlayerAllowance ) )
            {
                if( sayHandlerForOneNomWords( player_id, firstWord ) ) return PLUGIN_HANDLED;
            }
        }
        else if( userFlags & ADMIN_MAP
                 && equali( firstWord, GAL_VOTEMAP_MENU_COMMAND ) )
        {
            // Calculate how much pages there are available.
            new nominationsMapsCount = ArraySize( g_nominationLoadedMapsArray );
            new lastPageNumber       = GET_LAST_PAGE_NUMBER( nominationsMapsCount, MAX_NOM_MENU_ITEMS_PER_PAGE )

            setCorrectMenuPage( player_id, secondWord, g_voteMapMenuPages, lastPageNumber );
            voteMapMenuBuilder( player_id );

            LOGGER( 1, "    ( cmd_say ) Just Returning PLUGIN_HANDLED, voteMapMenuBuilder(1) chosen." )
            return PLUGIN_HANDLED;
        }
        else if( get_pcvar_num( cvar_nomPlayerAllowance ) )  // "say <nominate|nom|cancel> <map>"
        {
            if( sayHandlerForTwoNomWords( player_id, firstWord, secondWord ) ) return PLUGIN_HANDLED;
        }
    }

    LOGGER( 1, "    ( cmd_say ) Just Returning PLUGIN_CONTINUE, as reached the handler end." )
    return PLUGIN_CONTINUE;
}

stock sayHandlerForOneNomWords( player_id, firstWord[] )
{
    LOGGER( 128, "I AM ENTERING ON sayHandlerForOneNomWords(3)" )
    LOGGER( 4, "( sayHandlerForOneNomWords ) on the 1 word: else if( cvar_nomPlayerAllowance ), \
            get_pcvar_num( cvar_nomPlayerAllowance ): %d", get_pcvar_num( cvar_nomPlayerAllowance ) )

    if( equali( firstWord, "noms" )
        || equali( firstWord, "nominations" ) )
    {
        nomination_list();

        LOGGER( 1, "    ( sayHandlerForOneNomWords ) Just Returning PLUGIN_HANDLED, nomination_list(0) chosen." )
        return true;
    }
    else
    {
        new mapIndex = getSurMapNameIndex( firstWord );

        if( mapIndex >= 0 )
        {
            nomination_toggle( player_id, mapIndex );

            LOGGER( 1, "    ( sayHandlerForOneNomWords ) Just Returning PLUGIN_HANDLED, nomination_toggle(2) chosen." )
            return true;
        }
        else if( strlen( firstWord ) > 5
                 && equali( firstWord, "nom", 3 )
                 && containi( firstWord, "menu" ) > 1 )
        {
            // Calculate how much pages there are available.
            new nominationsMapsCount = ArraySize( g_nominationLoadedMapsArray );
            new lastPageNumber       = GET_LAST_PAGE_NUMBER( nominationsMapsCount, MAX_NOM_MENU_ITEMS_PER_PAGE )

            setCorrectMenuPage( player_id, firstWord, g_nominationPlayersMenuPages, lastPageNumber );
            nomination_menu( player_id );

            LOGGER( 1, "    ( sayHandlerForOneNomWords ) Just Returning PLUGIN_HANDLED, nomination_menu(1) chosen." )
            return true;
        }
        else // if contains a prefix
        {
            for( new prefix_index = 0; prefix_index < g_mapPrefixCount; prefix_index++ )
            {
                LOGGER( 4, "( sayHandlerForOneNomWords ) firstWord: %s, \
                        g_mapPrefixes[%d]: %s, \
                        containi( %s, %s )? %d", \
                        firstWord, \
                        prefix_index, g_mapPrefixes[ prefix_index ], \
                        firstWord, g_mapPrefixes[ prefix_index ], containi( firstWord, g_mapPrefixes[ prefix_index ] ) )

                if( containi( firstWord, g_mapPrefixes[ prefix_index ] ) > -1 )
                {
                    nomination_menu( player_id );

                    LOGGER( 1, "    ( sayHandlerForOneNomWords ) Just Returning PLUGIN_HANDLED, nomination_menu(1) chosen." )
                    return true;
                }
            }
        }

        LOGGER( 4, "( sayHandlerForOneNomWords ) equali(%s, 'nom', 3)? %d, strlen(%s) > 5? %d", \
                firstWord, equali( firstWord, "nom", 3 ), \
                firstWord, strlen( firstWord ) > 5 )
    }

    LOGGER( 1, "    ( sayHandlerForOneNomWords ) Just Returning false." )
    return false;
}

stock sayHandlerForTwoNomWords( player_id, firstWord[], secondWord[] )
{
    LOGGER( 128, "I AM ENTERING ON sayHandlerForTwoNomWords(3)" )

    if( strlen( firstWord ) > 5
        && equali( firstWord, "nom", 3 )
        && equali( firstWord[ strlen( firstWord ) - 4 ], "menu" ) )
    {
        // Calculate how much pages there are available.
        new nominationsMapsCount = ArraySize( g_nominationLoadedMapsArray );
        new lastPageNumber       = GET_LAST_PAGE_NUMBER( nominationsMapsCount, MAX_NOM_MENU_ITEMS_PER_PAGE )

        setCorrectMenuPage( player_id, secondWord, g_nominationPlayersMenuPages, lastPageNumber );
        nomination_menu( player_id );

        LOGGER( 1, "    ( sayHandlerForTwoNomWords ) Just Returning PLUGIN_HANDLED, nomination_menu(1) chosen." )
        return true;
    }
    else if( equali( firstWord, "nominate" )
             || equali( firstWord, "nom" ) )
    {
        strtolower( secondWord );
        g_isSawPartialMatchFirstPage[ player_id ] = false;

        if( g_partialMatchFirstPageItems[ player_id ] )
        {
            ArrayClear( g_partialMatchFirstPageItems[ player_id ] );
        }
        else
        {
            g_partialMatchFirstPageItems[ player_id ] = ArrayCreate();
        }

        copy( g_nominationPartialNameAttempt[ player_id ], charsmax( g_nominationPartialNameAttempt[] ), secondWord );
        nominationAttemptWithNamePart( player_id );

        LOGGER( 1, "    ( sayHandlerForTwoNomWords ) Just Returning PLUGIN_HANDLED, nominationAttemptWithNamePart(2): %s", secondWord )
        return true;
    }
    else if( equali( firstWord, "cancel" ) )
    {
        // bpj -- allow ambiguous cancel in which case a menu of their nominations is shown
        new mapIndex = getSurMapNameIndex( secondWord );

        if( mapIndex >= 0 )
        {
            nomination_cancel( player_id, mapIndex );

            LOGGER( 1, "    ( sayHandlerForTwoNomWords ) Just Returning PLUGIN_HANDLED, nomination cancel option chosen." )
            return true;
        }
    }

    LOGGER( 1, "    ( sayHandlerForTwoNomWords ) Just Returning false." )
    return false;
}

/**
 * Remove all the text from the string, except the first digits chain, to allow to open the menu
 * as `say galmenuPageNumber`. For example: `say galmenu50`.
 */
stock setCorrectMenuPage( player_id, pageString[], menuPages[], pagesCount )
{
    LOGGER( 128, "I AM ENTERING ON setCorrectMenuPage(4) pageString: %s, pagesCount: %d", pageString, pagesCount )

    if( strlen( pageString ) > 0 )
    {
        new searchIndex;
        new resultIndex;

        // Find the index `searchIndex` of the first digit on the string.
        while( pageString[ searchIndex ]
               && !isdigit( pageString[ searchIndex ] ) )
        {
            pageString[ 0 ]           = pageString[ searchIndex ];
            pageString[ searchIndex ] = '^0';

            searchIndex++;
        }

        LOGGER( 4, "( setCorrectMenuPage ) 1. pageString: %s", pageString )

        // When the page number start with a digit, we would erase all the string if not doing this.
        if( searchIndex == 0
            && isdigit( pageString[ 0 ] ) )
        {
            LOGGER( 4, "( setCorrectMenuPage ) 2. searchIndex: %d", searchIndex )

            do
            {
                searchIndex++;

            } while( isdigit( pageString[ searchIndex ] ) );

            pageString[ searchIndex ] = '^0';
        }
        else if( isdigit( pageString[ searchIndex ] ) )
        {
            LOGGER( 4, "( setCorrectMenuPage ) 3. searchIndex: %d", searchIndex )

            do
            {
                pageString[ resultIndex ] = pageString[ searchIndex ];
                pageString[ searchIndex ] = '^0';

                searchIndex++;
                resultIndex++;

            } while( isdigit( pageString[ searchIndex ] ) );
        }
        else
        {
            LOGGER( 4, "( setCorrectMenuPage ) 4. searchIndex: %d", searchIndex )
            pageString[ searchIndex ] = '^0';
        }
    }

    LOGGER( 4, "( setCorrectMenuPage ) 5. pageString: %s", pageString )

    // The pages index, start on 0
    if( isdigit( pageString[ 0 ] ) )
    {
        new targetPage = str_to_num( pageString );
        menuPages[ player_id ] = ( pagesCount > targetPage ? targetPage : pagesCount ) - 1;
    }
}

/**
 * Used to allow the menu nomination_menu(1) to have parameters within a default value.
 * It is because public functions are not allow to have a default value and we need this function
 * be public to allow it to be called from a set_task().
 */
public nomination_menuHook( player_id )
{
    LOGGER( 128, "I AM ENTERING ON nomination_menuHook(1) currentPage: %d", g_nominationPlayersMenuPages[ player_id ] )
    nomination_menu( player_id );
}

/**
 * Due there are several first menu options, take `VOTEMAP_FIRST_PAGE_ITEMS_COUNTING` items less.
 */
#define NOMINATION_FIRST_PAGE_ITEMS_COUNTING 1

stock getRecentMapsAndWhiteList( player_id, &isRecentMapNomBlocked, &isWhiteListNomBlock )
{
    isWhiteListNomBlock = ( IS_WHITELIST_ENABLED()
                            && IS_TO_HOURLY_LOAD_THE_WHITELIST() );

    // Not loaded?
    if( isWhiteListNomBlock )
    {
        tryToLoadTheWhiteListFeature();
    }

    switch( get_pcvar_num( cvar_recentNomMapsAllowance ) )
    {
        case 1:
        {
            isRecentMapNomBlocked = false;
        }
        case 2:
        {
            isRecentMapNomBlocked = !( get_user_flags( player_id ) & ADMIN_MAP );
        }
        default:
        {
            isRecentMapNomBlocked = true;
        }
    }
}

#define startNominationMenuVariables(%1) \
    new      mapIndex; \
    new bool:isRecentMapNomBlocked; \
    new bool:isWhiteListNomBlock; \
    new choice        [ MAX_MAPNAME_LENGHT + 32 ]; \
    new nominationMap [ MAX_MAPNAME_LENGHT ]; \
    new disabledReason[ MAX_SHORT_STRING ]; \
    getRecentMapsAndWhiteList( %1, isRecentMapNomBlocked, isWhiteListNomBlock )

/**
 * Gather all maps that match the nomination.
 */
stock nomination_menu( player_id )
{
    LOGGER( 128, "I AM ENTERING ON nomination_menu(1) player_id: %d", player_id )

    new itemsCount;
    new nominationsMapsCount;

    startNominationMenuVariables( player_id );
    nominationsMapsCount = ArraySize( g_nominationLoadedMapsArray );

    // Calculate how much pages there are available.
    new currentPageNumber = g_nominationPlayersMenuPages[ player_id ];
    new lastPageNumber    = GET_LAST_PAGE_NUMBER( nominationsMapsCount, MAX_NOM_MENU_ITEMS_PER_PAGE )

    // To create the menu
    formatex( disabledReason, charsmax( disabledReason ),
            IS_COLORED_CHAT_ENABLED() ? "%L\R%d /%d" : "%L  %d /%d",
            player_id, "GAL_LISTMAPS_TITLE", currentPageNumber + 1, lastPageNumber );

    new menu = menu_create( disabledReason, "nomination_handleMatchChoice" );

    // The first menu item, 'Cancel All Your Nominations.
    if( currentPageNumber < 1 )
    {
        formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_NOM_CANCEL_OPTION" );
        menu_additem( menu, disabledReason, _, 0 );

        // Add some space from the cancel option.
        // menu_addblank( menu, 0 );
    }

    // Disables the menu paging.
    menu_setprop( menu, MPROP_PERPAGE, 0 );

    // Configure the menu buttons.
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_EXITNAME, menu, "EXIT" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_NEXTNAME, menu, "MORE" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_BACKNAME, menu, "BACK" )

    // The first page contains by default the `Cancel All Nominations` option, then the first page
    // will get one less item due the `Cancel All Nominations` option.
    if( currentPageNumber == 0 )
    {
        mapIndex   = 0;
        itemsCount = 1;
    }
    else
    {
        // Due there are several first menu options, take `VOTEMAP_FIRST_PAGE_ITEMS_COUNTING` items less.
        mapIndex   = currentPageNumber * MAX_NOM_MENU_ITEMS_PER_PAGE - NOMINATION_FIRST_PAGE_ITEMS_COUNTING;
        itemsCount = 0;
    }

    for( ; mapIndex < nominationsMapsCount && itemsCount < MAX_NOM_MENU_ITEMS_PER_PAGE; mapIndex++ )
    {
        GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, nominationMap )
        itemsCount++;

        // Start the menu entry item calculation:
        // 'nomination_menu(1)' and 'nominationAttemptWithNamePart(2)'.
        {
            // in most cases, the map will be available for selection, so assume that's the case here
            disabledReason[ 0 ] = '^0';

            // disable if the map has already been nominated
            if( nomination_getPlayer( mapIndex ) )
            {
                formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_NOMINATED" );
            }
            else if( isRecentMapNomBlocked
                     && map_isTooRecent( nominationMap ) )
            {
                formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_TOORECENT" );
            }
            else if( equali( g_currentMapName, nominationMap ) )
            {
                formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_CURRENTMAP" );
            }
            else if( IS_WHITELIST_BLOCKING( isWhiteListNomBlock, nominationMap ) )
            {
                formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_WHITELIST" );
            }

            formatex( choice, charsmax( choice ), "%s %s", nominationMap, disabledReason );
            LOGGER( 4, "( nomination_menu ) choice: %s", choice )

            menu_additem( menu, choice, _, ( disabledReason[ 0 ] == '^0' ? 0 : ( 1 << 26 ) ) );

        } // end the menu entry item calculation.

    } // end for 'mapIndex'.

    LOGGER( 4, "( nominationAttemptWithNamePart ) itemsCount: %d, mapIndex: %d", itemsCount, mapIndex )

    addMenuMoreBackExitOptions( menu, player_id, disabledReason, mapIndex < nominationsMapsCount, currentPageNumber > 0, itemsCount );
    menu_display( player_id, menu );
}

/**
 * Used to allow the menu nominationAttemptWithNamePart(2) to have parameters within a default value.
 * It is because public functions are not allow to have a default value and we need this function
 * be public to allow it to be called from a set_task().
 */
public nominationAttemptWithNameHook( parameters[] )
{
    LOGGER( 128, "I AM ENTERING ON nominationAttemptWithNameHook(2) startSearchIndex: %d", parameters[ 1 ] )
    nominationAttemptWithNamePart( parameters[ 0 ], parameters[ 1 ] );
}

/**
 * Gather all maps that match the g_nominationPartialNameAttempt[ player_id ].
 *
 * @note ( playerName[], &phraseIdx, matchingSegment[] )
 */
stock nominationAttemptWithNamePart( player_id, startSearchIndex = 0 )
{
    LOGGER( 128, "I AM ENTERING ON nominationAttemptWithNamePart(2) startSearchIndex: %d", startSearchIndex )

    new matchIndex;
    new itemsCount;
    new nominationsMapsCount;

    startNominationMenuVariables( player_id );

    matchIndex           = -1;
    nominationsMapsCount = ArraySize( g_nominationLoadedMapsArray );

    // Calculate how much pages there are available.
    new currentPageNumber = ArraySize( g_partialMatchFirstPageItems[ player_id ] );
    new lastPageNumber    = 1;

    // We cannot know how much pages there are without counting all the partial matches search,
    // so here we try to estimate how much pages there are.
    if( currentPageNumber > 0 )
    {
        lastPageNumber = ArrayGetCell( g_partialMatchFirstPageItems[ player_id ], currentPageNumber - 1 );
        lastPageNumber = ( ( nominationsMapsCount - lastPageNumber ) / MAX_NOM_MENU_ITEMS_PER_PAGE ) + currentPageNumber;
    }

    // To create the menu
    formatex( disabledReason, charsmax( disabledReason ),
            IS_COLORED_CHAT_ENABLED() ? "%L\R%d/%d" : "%L %d /%d",
            player_id, "GAL_LISTMAPS_TITLE", currentPageNumber + 1, lastPageNumber );

    new menu = menu_create( disabledReason, "nomination_handlePartialMatch" );

    // Disables the menu paging.
    menu_setprop( menu, MPROP_PERPAGE, 0 );

    // Configure the menu buttons.
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_EXITNAME, menu, "EXIT" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_NEXTNAME, menu, "MORE" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_BACKNAME, menu, "BACK" )

    for( mapIndex = startSearchIndex; mapIndex < nominationsMapsCount && itemsCount < MAX_NOM_MENU_ITEMS_PER_PAGE; ++mapIndex )
    {
        GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, nominationMap )

        if( containi( nominationMap, g_nominationPartialNameAttempt[ player_id ] ) > -1 )
        {
            // Store in case this is the only match
            matchIndex = mapIndex;

            // Save the map index for the current menu position
            g_menuMapIndexForPlayerArrays[ player_id ][ itemsCount ] = mapIndex;
            itemsCount++;

            // Start the menu entry item calculation:
            // 'nomination_menu(1)' and 'nominationAttemptWithNamePart(2)'.
            {
                // in most cases, the map will be available for selection, so assume that's the case here
                disabledReason[ 0 ] = '^0';

                // disable if the map has already been nominated
                if( nomination_getPlayer( mapIndex ) )
                {
                    formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_NOMINATED" );
                }
                else if( isRecentMapNomBlocked
                         && map_isTooRecent( nominationMap ) )
                {
                    formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_TOORECENT" );
                }
                else if( equali( g_currentMapName, nominationMap ) )
                {
                    formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_CURRENTMAP" );
                }
                else if( IS_WHITELIST_BLOCKING( isWhiteListNomBlock, nominationMap ) )
                {
                    formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_WHITELIST" );
                }

                formatex( choice, charsmax( choice ), "%s %s", nominationMap, disabledReason );
                LOGGER( 4, "( nominationAttemptWithNamePart ) choice: %s", choice )

                menu_additem( menu, choice, _, ( disabledReason[ 0 ] == '^0' ? 0 : ( 1 << 26 ) ) );

            } // end the menu entry item calculation.

        }  // end if 'containi'.

    } // end for 'mapIndex'.

    new lastPosition = ArraySize( g_partialMatchFirstPageItems[ player_id ] ) - 1;

    LOGGER( 4, "( nominationAttemptWithNamePart ) mapIndex: %d", mapIndex)
    LOGGER( 4, "( nominationAttemptWithNamePart ) itemsCount: %d, lastPosition: %d", itemsCount, lastPosition )

    // If the last position is negative, then there is not last position, moreover this is the
    // first call to nominationAttemptWithNamePart(3), then it means there any or one matches for
    // the partial map name nomination.
    if( lastPosition < 0
        && itemsCount < 2 )
    {
        // handle the number of matches
        switch( itemsCount )
        {
            case 0:
            {
                // no matches; pity the poor fool
                color_print( player_id, "%L", player_id, "GAL_NOM_FAIL_NOMATCHES", g_nominationPartialNameAttempt[ player_id ] );

                // Destroys the menu, as is was not used.
                DESTROY_PLAYER_NEW_MENU_TYPE( menu )
            }
            case 1:
            {
                // one match?! omg, this is just like awesome
                map_nominate( player_id, matchIndex );

                // Destroys the menu, as is was not used.
                DESTROY_PLAYER_NEW_MENU_TYPE( menu )
            }
        }
    }
    else
    {
        // this is kinda sexy; we put up a menu of the matches for them to pick the right one
        if( itemsCount >= MAX_NOM_MATCH_COUNT )
        {
            color_print( player_id, "%L", player_id, "GAL_NOM_MATCHES_MAX", MAX_NOM_MATCH_COUNT, MAX_NOM_MATCH_COUNT );
        }

        if( !g_isSawPartialMatchFirstPage[ player_id ] )
        {
            g_isSawPartialMatchFirstPage[ player_id ] = true;
            color_print( player_id, "%L", player_id, "GAL_NOM_MATCHES", g_nominationPartialNameAttempt[ player_id ] );
        }

        // Old behavior: If this function is called within this parameter true, it means this is
        // the seconds time we are trying to show the same last page, so instead of showing an
        // empty page, we show the same page, but within the more button disabled.
        addMenuMoreBackExitOptions( menu, player_id, disabledReason, mapIndex < nominationsMapsCount, bool:currentPageNumber, itemsCount );

        menu_display( player_id, menu );
    }
}

stock addMenuMoreBackExitOptions( menu, player_id, disabledReason[], bool:isToEnableMoreButton, bool:isToEnableBackButton, itemsCount )
{
    LOGGER( 128, "I AM ENTERING ON addMenuMoreBackExitOptions(5) isToEnableMoreButton: %d, \
            isToEnableBackButton: %d", isToEnableMoreButton, isToEnableBackButton )

    addMenuMoreBackButtons( menu, player_id, disabledReason, isToEnableMoreButton, isToEnableBackButton, itemsCount );

    // To add the exit button
    formatex( disabledReason, MAX_SHORT_STRING - 1, "%L", player_id, "EXIT" );
    menu_additem( menu, disabledReason, _, 0 );
}

stock addMenuMoreBackButtons( menu, player_id, disabledReason[], bool:isToEnableMoreButton, bool:isToEnableBackButton, itemsCount )
{
    LOGGER( 128, "I AM ENTERING ON addMenuMoreBackButtons(5) isToEnableBackButton: %d", isToEnableBackButton )

    // Force the menu control options to be present on the keys 8 (more), 9 (back) and 0 (exit).
    while( itemsCount < MAX_NOM_MENU_ITEMS_PER_PAGE )
    {
        itemsCount++;
        formatex( disabledReason, MAX_SHORT_STRING - 1, "%L", player_id, "OFF" );
        menu_additem( menu, disabledReason, _, 1 << 26 );

        // When using slot=1 this might break your menu. To achieve this functionality
        // menu_addblank2() should be used (AMXX 183 only).
        // menu_addblank( menu, 1 );
    }

    // Add some space from the control options and format the back button within the LANG file.
    menu_addblank( menu, 0 );
    formatex( disabledReason, MAX_SHORT_STRING - 1, "%L", player_id, "BACK" );

    // If we are on the first page, disable the back option.
    if( isToEnableBackButton )
    {
        menu_additem( menu, disabledReason, _, 0 );
    }
    else
    {
        menu_additem( menu, disabledReason, _, 1 << 26 );
    }

    formatex( disabledReason, MAX_SHORT_STRING - 1, "%L", player_id, "MORE" );

    // If there are more maps, add the more option
    if( isToEnableMoreButton )
    {
        menu_additem( menu, disabledReason, _, 0 );
    }
    else
    {
        menu_additem( menu, disabledReason, _, 1 << 26 );
    }
}

/**
 * This menu handler is a little different because it handles two similar menus. The
 * 'nomination_menu(1)' and the 'nominationAttemptWithNamePart(2)'. They would be very similar
 * handlers, then was just build one function instead of two alike.
 */
public nomination_handleMatchChoice( player_id, menu, item )
{
    LOGGER( 128, "I AM ENTERING ON nomination_handleMatchChoice(1) player_id: %d, menu: %d, item: %d", player_id, menu, item )

    // Let go to destroy the menu and clean some memory. As the menu is not paginated, the item 9
    // is the key 0 on the keyboard. Also, the item 8 is the key 9; 7, 8; 6, 7; 5, 6; 4, 5; etc.
    if( item < 0
        || item == 9 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        LOGGER( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, the menu is destroyed." )
        return PLUGIN_HANDLED;
    }

    // Due the first menu option to be 'Cancel all your Nominations', close the menu but if and
    // only if we are on the menu's first page.
    if( item == 0
        && g_nominationPlayersMenuPages[ player_id ] == 0 )
    {
        unnominatedDisconnectedPlayer( player_id );
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        LOGGER( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, the nominations were cancelled." )
        return PLUGIN_HANDLED;
    }

    // If the 8 button item is hit, and we are not on the first page, we must to perform the back option.
    if( item == 7 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        g_nominationPlayersMenuPages[ player_id ] ? g_nominationPlayersMenuPages[ player_id ]-- : 0;

        // Try to block/difficult players from performing the Denial Of Server attack.
        // set_task( 0.1, "nomination_menuHook", player_id );
        nomination_menuHook( player_id );

        LOGGER( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, doing the back button." )
        return PLUGIN_HANDLED;
    }

    // If the 9 button item is hit, and we are on some page not the last one, we must to perform the more option.
    if( item == 8 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        g_nominationPlayersMenuPages[ player_id ]++;

        // Try to block/difficult players from performing the Denial Of Server attack.
        // nomination_menuHook( player_id );
        set_task( 0.1, "nomination_menuHook", player_id );

        LOGGER( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, doing the more button." )
        return PLUGIN_HANDLED;
    }

    // Due the first nomination menu option to be 'Cancel all your Nominations', take one item less 'item - 1'.
    new pageSeptalNumber = convert_numeric_base( g_nominationPlayersMenuPages[ player_id ], 10, MAX_NOM_MENU_ITEMS_PER_PAGE );
    item = convert_numeric_base( pageSeptalNumber * 10, MAX_NOM_MENU_ITEMS_PER_PAGE, 10 ) + item - NOMINATION_FIRST_PAGE_ITEMS_COUNTING;

    map_nominate( player_id, item );
    DESTROY_PLAYER_NEW_MENU_TYPE( menu )

    LOGGER( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, successful nomination." )
    return PLUGIN_HANDLED;
}

/**
 * These menus does not use the `info[]` parameter allowed by the new menu style because in the
 * previous implementation of this menu, where a single menu within all the map entries was build.
 * There the `info[]` option on AMXX 182 as getting wrong indexes about after the menu entry 200.
 * So, a implementation to pass the indexes using global variables was created.
 *
 * Now as the menu has at most only 10 entries, such bug would not to apply. However I prefer to keep
 * this implementation for historical reasons  and as it is already functional and its properly of
 * remembering on which page the menu was closed previously is properly working.
 *
 * The new menus built after this using the `on demand approach` are already using the `info[]` option
 * from the new menus style. For its implementation, see the function: displayVoteMapMenuCommands(1)
 */
public nomination_handlePartialMatch( player_id, menu, item )
{
    LOGGER( 128, "I AM ENTERING ON nomination_handlePartialMatch(1) player_id: %d, menu: %d, item: %d", player_id, menu, item )

    // Let go to destroy the menu and clean some memory. As the menu is not paginated, the item 9
    // is the key 0 on the keyboard. Also, the item 8 is the key 9; 7, 8; 6, 7; 5, 6; 4, 5; etc.
    if( item < 0
        || item == 9 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        LOGGER( 1, "    ( nomination_handlePartialMatch ) Just Returning PLUGIN_HANDLED, the menu is destroyed." )
        return PLUGIN_HANDLED;
    }

    // If the 8 button item is hit, and we are not on the first page, we must to perform the back option.
    if( item == 7 )
    {
        new arguments[ 2 ];
        new lastPosition = ArraySize( g_partialMatchFirstPageItems[ player_id ] ) - 1;

        // We are already on the first page or something like that.
        if( lastPosition < 0 )
        {
            arguments[ 1 ] = 0;
        }
        else
        {
            arguments[ 1 ] = ArrayGetCell( g_partialMatchFirstPageItems[ player_id ], lastPosition );
        }

        ArrayDeleteItem( g_partialMatchFirstPageItems[ player_id ], lastPosition );

        arguments[ 0 ] = player_id;
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        // Try to block/difficult players from performing the Denial Of Server attack.
        // nominationAttemptWithNameHook( arguments );
        set_task( 0.1, "nominationAttemptWithNameHook", _, arguments, sizeof arguments );

        LOGGER( 1, "    ( nomination_handlePartialMatch ) Just Returning PLUGIN_HANDLED, doing the back button." )
        return PLUGIN_HANDLED;
    }

    // If the 9 button item is hit, and we are on some page not the last one, we must to perform the more option.
    if( item == 8 )
    {
        new arguments[ 2 ];

        arguments[ 0 ] = player_id;
        arguments[ 1 ] = g_menuMapIndexForPlayerArrays[ player_id ][ MAX_NOM_MENU_ITEMS_PER_PAGE - 1 ] + 1;

        ArrayPushCell( g_partialMatchFirstPageItems[ player_id ], g_menuMapIndexForPlayerArrays[ player_id ][ 0 ] );
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        // Try to block/difficult players from performing the Denial Of Server attack.
        // nominationAttemptWithNameHook( arguments );
        set_task( 0.1, "nominationAttemptWithNameHook", _, arguments, sizeof arguments );

        LOGGER( 1, "    ( nomination_handlePartialMatch ) Just Returning PLUGIN_HANDLED, doing the more button." )
        return PLUGIN_HANDLED;
    }

    // We are using the 'nominationAttemptWithNamePart(2)'
    item = g_menuMapIndexForPlayerArrays[ player_id ][ item ];

    map_nominate( player_id, item );
    DESTROY_PLAYER_NEW_MENU_TYPE( menu )

    LOGGER( 1, "    ( nomination_handlePartialMatch ) Just Returning PLUGIN_HANDLED, successful nomination." )
    return PLUGIN_HANDLED;
}

/**
 * Given a number on a certain base until 10, calculates and return the equivalent number on another
 * base until 10.
 *
 * @param origin_number    the number to be converted.
 * @param origin_base      the base where `origin_number` is on.
 * @param destiny_base     the base where `origin_number` is to be converted to.
 */
stock convert_numeric_base( origin_number, origin_base, destiny_base )
{
    LOGGER( 128, "I AM ENTERING ON convert_numeric_base(1) number: %d (%d->%d)", \
            origin_number, origin_base, destiny_base )

    new integer;
    new Array:digits;

    digits  = toDigitsRepresentation( origin_number, 10 );
    // printDynamicArrayCells( digits );

    integer = fromDigitsRepresentation( digits, origin_base );
    ArrayDestroy( digits );

    digits  = toDigitsRepresentation( integer, destiny_base );
    // printDynamicArrayCells( digits );

    integer = fromDigitsRepresentation( digits, 10 );
    ArrayDestroy( digits );

    LOGGER( 1, "    ( convert_numeric_base ) Returning integer: %d", integer )
    return integer;
}

/**
 * Read an digits Dynamic Array at its given base and return an integer representation.
 *
 * @param digits           a Dynamic Array within the digits of inputed number on the specified base.
 * @param origin_base      the base where `digits` are represented.
 *
 * return an integer representation inputed number on the specified base.
 */
stock fromDigitsRepresentation( Array:digits, origin_base )
{
    new integer;
    new arraySize = ArraySize( digits );

    for( new index = 0; index < arraySize; index ++ )
    {
        integer = integer * origin_base + ArrayGetCell( digits, index );
    }

    return integer;
}

/**
 * Create an Dynamic Array within of the decimal number at its given base.
 *
 * @param origin_number    a decimal number to be converted.
 * @param origin_base      the base where `origin_number` is to be converted to.
 *
 * return a Dynamic Array within the digits of inputed number on the specified base.
 */
stock Array:toDigitsRepresentation( origin_number, origin_base )
{
    new Array:digits = ArrayCreate();

    ArrayPushCell( digits, origin_number % origin_base );
    origin_number = origin_number / origin_base;

    while( origin_number > 0 )
    {
        ArrayInsertCellBefore( digits, 0, origin_number % origin_base );
        origin_number = origin_number / origin_base;
    }

    return digits;
}

/**
 * Given a number on the base 8, calculates and return the equivalent decimal number (base 10).
 */
stock convert_octal_to_decimal( octal_number )
{
    LOGGER( 128, "I AM ENTERING ON convert_octal_to_decimal(1) octal_number: %d", octal_number )
    new remainder;

    new decimal = 0;
    new index   = 0;

    while( octal_number != 0 )
    {
        remainder     = octal_number % 10;
        octal_number /= 10;
        decimal      += remainder * power( 8, index );

        ++index;
    }

    LOGGER( 1, "    ( convert_octal_to_decimal ) Returning decimal: %d", decimal )
    return decimal;
}

/**
 * Check if the map has already been nominated.
 *
 * @param  mapIndex   the map index desired.
 *
 * @return 0          when the map is not nominated, or the player nominator id.
 */
stock nomination_getPlayer( mapIndex )
{
    LOGGER( 128, "I AM ENTERING ON nomination_getPlayer(1) mapIndex: %d", mapIndex )

    new trieKey          [ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new mapNominationData[ MapNominationsType ];

    num_to_str( mapIndex, trieKey, charsmax( trieKey ) );
    LOGGER( 4, "( nomination_getPlayer ) trieKey: %s", trieKey )

    if( TrieKeyExists( g_reverseSearchNominationsTrie, trieKey ) )
    {
        TrieGetArray( g_reverseSearchNominationsTrie, trieKey, mapNominationData, sizeof mapNominationData );

        if( mapNominationData[ MapNomination_NominationIndex ] > -1 )
        {
            LOGGER( 1, "    ( nomination_getPlayer ) Returning mapNominationData[MapNomination_PlayerId]: %d", \
                   mapNominationData[ MapNomination_PlayerId ] )
            return mapNominationData[ MapNomination_PlayerId ];
        }
    }

    LOGGER( 1, "    ( nomination_getPlayer ) Returning mapNominationData[MapNomination_PlayerId]: %d", 0 )
    return 0;
}

/**
 * Gets the nominated map index, given the player id and the nomination index.
 *
 * @return -1 when there is no nomination, otherwise the map nomination index.
 */
stock getPlayerNominationMapIndex( player_id, nominationIndex )
{
    LOGGER( 256, "I AM ENTERING ON getPlayerNominationMapIndex(2) player_id: %d, nominationIndex: %d", player_id, nominationIndex )

    new trieKey             [ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new playerNominationData[ MAX_OPTIONS_IN_VOTE ];

    createPlayerNominationKey( player_id, trieKey, charsmax( trieKey ) );

    if( TrieKeyExists( g_forwardSearchNominationsTrie, trieKey ) )
    {
        TrieGetArray( g_forwardSearchNominationsTrie, trieKey, playerNominationData, sizeof playerNominationData );
    }
    else
    {
        LOGGER( 256, "    ( getPlayerNominationMapIndex ) Returning playerNominationData[nominationIndex]: %d", -1 )
        return -1;
    }

    LOGGER( 256, "    ( getPlayerNominationMapIndex ) Returning playerNominationData[nominationIndex]: %d", \
           playerNominationData[ nominationIndex ] )
    return playerNominationData[ nominationIndex ];
}

/**
 * Changes the player nomination. When there is no nominations, it creates the player entry to the
 * the server nominations tables `g_reverseSearchNominationsTrie`, `g_forwardSearchNominationsTrie` and
 * `g_nominatedMapsArray`.
 *
 * @param player_id             the nominator player id.
 * @param nominationIndex       @see the updateNominationsReverseSearch's nominationIndex function parameter.
 * @param mapIndex              @see the updateNominationsReverseSearch's mapIndex function parameter.
 */
stock setPlayerNominationMapIndex( player_id, nominationIndex, mapIndex )
{
    LOGGER( 128, "I AM ENTERING ON setPlayerNominationMapIndex(3) player_id: %d, nominationIndex: %d, mapIndex: %d", \
            player_id, nominationIndex, mapIndex )

    if( nominationIndex < MAX_OPTIONS_IN_VOTE )
    {
        new originalMapIndex = updateNominationsForwardSearch( player_id, nominationIndex, mapIndex );
        updateNominationsReverseSearch( player_id, nominationIndex, mapIndex, originalMapIndex );
    }
    else
    {
        LOGGER( 1, "AMX_ERR_BOUNDS: %d. Was tried to set a wrong nomination bound index: %d", AMX_ERR_BOUNDS, nominationIndex )
        log_error( AMX_ERR_BOUNDS, "Was tried to set a wrong nomination bound index: %d", nominationIndex );
    }
}

stock updateNominationsForwardSearch( player_id, nominationIndex, mapIndex )
{
    LOGGER( 128, "I AM ENTERING ON updateNominationsForwardSearch(3) player_id: %d, \
            nominationIndex: %d, mapIndex: %d",  player_id, nominationIndex, mapIndex )

    // new openNominationIndex;
    // LOGGER( 1, "^n^n^ncountPlayerNominations: %d", countPlayerNominations( player_id, openNominationIndex ) )

    new originalMapIndex;
    new trieKey                 [ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new playerNominationsIndexes[ MAX_OPTIONS_IN_VOTE ];

    createPlayerNominationKey( player_id, trieKey, charsmax( trieKey ) );

    if( TrieKeyExists( g_forwardSearchNominationsTrie, trieKey ) )
    {
        TrieGetArray( g_forwardSearchNominationsTrie, trieKey, playerNominationsIndexes, sizeof playerNominationsIndexes );
        originalMapIndex = playerNominationsIndexes[ nominationIndex ];

        playerNominationsIndexes[ nominationIndex ] = mapIndex;
        TrieSetArray( g_forwardSearchNominationsTrie, trieKey, playerNominationsIndexes, sizeof playerNominationsIndexes );
    }
    else
    {
        for( new currentNominationIndex = 0; currentNominationIndex < MAX_OPTIONS_IN_VOTE; ++currentNominationIndex )
        {
            playerNominationsIndexes[ currentNominationIndex ] = -1;
        }

        playerNominationsIndexes[ nominationIndex ] = mapIndex;
        TrieSetArray( g_forwardSearchNominationsTrie, trieKey, playerNominationsIndexes, sizeof playerNominationsIndexes );
    }

    // LOGGER( 1, "^n^n^ncountPlayerNominations: %d", countPlayerNominations( player_id, openNominationIndex ) )
    LOGGER( 1, "    ( updateNominationsForwardSearch ) Returning originalMapIndex: %d", originalMapIndex )
    return originalMapIndex;
}

/**
 * Update the reverse search. It is used to find out the data stored by the `MapNominationsType`
 * enum for the given nominated map index.
 *
 * Note:
 * 1. Each map has one, and only one nomination index.
 * 2. The `originalMapIndex` is the position of the last nomination to be replaced.
 *
 * @param player_id             the nominator player game id.
 * @param nominationIndex       the player's personal nominations array index.
 *
 * @param mapIndex              the server's nomination index. Uses -1 to disable the current
 *                              player's personal nomination index.
 *
 * @param originalMapIndex      the correct server's nomination index. Do not accept the wild card
 *                              -1 as the mapIndex parameter just above.
 */
stock updateNominationsReverseSearch( player_id, nominationIndex, mapIndex, originalMapIndex )
{
    LOGGER( 128, "I AM ENTERING ON updateNominationsReverseSearch(4) player_id: %d, \
            nominationIndex: %d, mapIndex: %d, originalMapIndex: %d",  player_id, \
            nominationIndex,     mapIndex,     originalMapIndex )

    new nominatedIndex;
    LOGGER( 4, "( updateNominationsReverseSearch|in  ) ArraySize(g_nominatedMapsArray): %d", ArraySize( g_nominatedMapsArray ) )

    new trieKey[ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new mapNominationData[ MapNominationsType ];

    if( mapIndex < 0 )
    {
        num_to_str( originalMapIndex, trieKey, charsmax( trieKey ) );

        // If the trie key exists, disable it on the `g_nominatedMapsArray` current position, and
        // if it does not exist to do nothing as the behavior for non existing trie is already
        // disabled.
        if( TrieKeyExists( g_reverseSearchNominationsTrie, trieKey ) )
        {
            TrieGetArray( g_reverseSearchNominationsTrie, trieKey, mapNominationData, sizeof mapNominationData );

            // If it is already disabled do not double disable it
            if( mapNominationData[ MapNomination_NominationIndex ] > -1 )
            {
                nominatedIndex = mapNominationData[ MapNomination_NominatedIndex ];
                mapNominationData[ MapNomination_NominationIndex ] = -1;

                ArraySetCell( g_nominatedMapsArray, nominatedIndex, -1 );
                TrieSetArray( g_reverseSearchNominationsTrie, trieKey, mapNominationData, sizeof mapNominationData );
            }
        }
    }
    else
    {
        num_to_str( mapIndex, trieKey, charsmax( trieKey ) );

        if( TrieKeyExists( g_reverseSearchNominationsTrie, trieKey ) )
        {
            TrieGetArray( g_reverseSearchNominationsTrie, trieKey, mapNominationData, sizeof mapNominationData );

            mapNominationData[ MapNomination_PlayerId ]        = player_id;
            mapNominationData[ MapNomination_NominationIndex ] = nominationIndex;

            nominatedIndex = mapNominationData[ MapNomination_NominatedIndex ];
            ArraySetCell( g_nominatedMapsArray, nominatedIndex, mapIndex );
        }
        else
        {
            nominatedIndex = ArraySize( g_nominatedMapsArray );
            ArrayPushCell( g_nominatedMapsArray, mapIndex );

            mapNominationData[ MapNomination_PlayerId ]        = player_id;
            mapNominationData[ MapNomination_NominatedIndex ]  = nominatedIndex;
            mapNominationData[ MapNomination_NominationIndex ] = nominationIndex;
        }

        TrieSetArray( g_reverseSearchNominationsTrie, trieKey, mapNominationData, sizeof mapNominationData );
    }

    LOGGER( 4, "( updateNominationsReverseSearch|out ) ArraySize(g_nominatedMapsArray): %d", ArraySize( g_nominatedMapsArray ) )
}

stock countPlayerNominations( player_id, &openNominationIndex )
{
    LOGGER( 128, "I AM ENTERING ON countPlayerNominations(2) player_id: %d, openNominationIndex: %d", \
            player_id, openNominationIndex )

    new nominationCount;
    LOGGER( 4, "( countPlayerNominations ) ArraySize(g_nominatedMapsArray): %d", ArraySize( g_nominatedMapsArray ) )

    new trieKey[ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new playerNominationData[ MAX_OPTIONS_IN_VOTE ];

    openNominationIndex = 0;
    createPlayerNominationKey( player_id, trieKey, charsmax( trieKey ) );

    if( TrieKeyExists( g_forwardSearchNominationsTrie, trieKey ) )
    {
        TrieGetArray( g_forwardSearchNominationsTrie, trieKey, playerNominationData, sizeof playerNominationData );

        for( new nominationIndex = 0; nominationIndex < MAX_OPTIONS_IN_VOTE; ++nominationIndex )
        {
            LOGGER( 4, "( countPlayerNominations ) playerNominationData[%d]: %d", \
                    nominationIndex, playerNominationData[ nominationIndex ] )

            if( playerNominationData[ nominationIndex ] < 0 )
            {
                openNominationIndex = nominationCount;
            }
            else
            {
                nominationCount++;
            }
        }
    }
    else
    {
        nominationCount = 0;
    }

    LOGGER( 4, "( countPlayerNominations ) nominationCount: %d, trieKey: %s, openNominationIndex: %d", \
            nominationCount, trieKey, openNominationIndex )

    return nominationCount;
}

stock createPlayerNominationKey( player_id, trieKey[], trieKeyLength )
{
    LOGGER( 256, "I AM ENTERING ON createPlayerNominationKey(3) player_id: %d, trieKeyLength: %d", \
            player_id, trieKeyLength )

    new ipSize;
    ipSize = get_user_ip( player_id, trieKey, trieKeyLength );

    if( !ipSize )
    {
        ipSize += formatex( trieKey[ ipSize ], trieKeyLength - ipSize, "id%d-", player_id );
    }

    get_user_authid( player_id, trieKey[ ipSize ], trieKeyLength - ipSize );
    LOGGER( 256, "( createPlayerNominationKey ) player_id: %d, trieKey: %s,", player_id, trieKey )
}

stock nomination_toggle( player_id, mapIndex )
{
    LOGGER( 128, "I AM ENTERING ON nomination_toggle(2) player_id: %d, mapIndex: %d", player_id, mapIndex )
    new nominatorPlayerId = nomination_getPlayer( mapIndex );

    if( nominatorPlayerId == player_id )
    {
        nomination_cancel( player_id, mapIndex );
    }
    else
    {
        map_nominate( player_id, mapIndex );
    }
}

stock nomination_cancel( player_id, mapIndex )
{
    LOGGER( 128, "I AM ENTERING ON nomination_cancel(2) player_id: %d, mapIndex: %d", player_id, mapIndex )

    if( !is_to_block_map_nomination( player_id, {0} ) )
    {
        new mapNominationData[ MapNominationsType ];

        new trieKey[ MAX_NOMINATION_TRIE_KEY_SIZE ];
        new mapName[ MAX_MAPNAME_LENGHT ];

        num_to_str( mapIndex, trieKey, charsmax( trieKey ) );
        GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, mapName )

        // Nomination found, then delete it. It is more probably you will only try to cancel your
        // own nominations.
        // This is why we do not re-use the `mapNominationData[ MapNomination_PlayerId ]` just below,
        // in place of the nomination_getPlayer(1).
        if( TrieKeyExists( g_reverseSearchNominationsTrie, trieKey ) )
        {
            TrieGetArray( g_reverseSearchNominationsTrie, trieKey, mapNominationData, sizeof mapNominationData );
            new nominationIndex = mapNominationData[ MapNomination_NominationIndex ];

            if( nominationIndex > -1
                && mapNominationData[ MapNomination_PlayerId ] == player_id )
            {
                setPlayerNominationMapIndex( player_id, nominationIndex, -1 );
                nomination_announceCancellation( mapName );
            }
            else
            {
                goto nomination_cancel_not_you;
            }
        }
        else
        {
            nomination_cancel_not_you:
            new nominatorPlayerId = nomination_getPlayer( mapIndex );

            // If the nominator is not playing on the server and its nominations are not removed, this
            // retrieval will fail. Therefore we would need to save their names, to properly present it.
            // So to KISS it, let show the wrong name and the `It is not nominated yet` message.
            if( nominatorPlayerId
                && nominatorPlayerId != player_id )
            {
                new player_name[ MAX_PLAYER_NAME_LENGHT ];

                GET_USER_NAME( nominatorPlayerId, player_name )
                color_print( player_id, "%L", player_id, "GAL_CANCEL_FAIL_SOMEONEELSE", mapName, player_name );
            }
            else
            {
                color_print( player_id, "%L", player_id, "GAL_CANCEL_FAIL_WASNOTYOU", mapName );
            }
        }
    }
}

stock is_to_block_map_nomination( player_id, mapName[] )
{
    LOGGER( 128, "I AM ENTERING ON is_to_block_map_nomination(2) player_id: %d, mapName: %d", player_id, mapName )

    // nominations can only be made if a vote isn't already in progress
    if( g_voteStatus & IS_VOTE_IN_PROGRESS )
    {
        color_print( player_id, "%L", player_id, "GAL_NOM_FAIL_INPROGRESS" );
        LOGGER( 1, "    ( is_to_block_map_nomination ) Just Returning/blocking, the voting is in progress." )
    }

    // and if the outcome of the vote hasn't already been determined
    else if( g_voteStatus & IS_VOTE_OVER )
    {
        color_print( player_id, "%L", player_id, "GAL_NOM_FAIL_VOTEOVER" );
        LOGGER( 1, "    ( is_to_block_map_nomination ) Just Returning/blocking, the voting is over." )
    }

    // players can not nominate the current map
    else if( mapName[0]
             && equali( g_currentMapName, mapName ) )
    {
        color_print( player_id, "%L", player_id, "GAL_NOM_FAIL_CURRENTMAP", g_currentMapName );
        LOGGER( 1, "    ( is_to_block_map_nomination ) Just Returning/blocking, cannot nominate the current map." )
    }

    // players may not be able to nominate recently played maps
    else if( mapName[0]
             && g_recentMapCount
             && map_isTooRecent( mapName )
             && ( ( get_pcvar_num( cvar_recentNomMapsAllowance ) == 2
                    && !( get_user_flags( player_id ) & ADMIN_MAP ) )
                  || get_pcvar_num( cvar_recentNomMapsAllowance ) == 0 ) )
    {
        color_print( player_id, "%L", player_id, "GAL_NOM_FAIL_TOORECENT", mapName );
        color_print( player_id, "%L", player_id, "GAL_NOM_FAIL_TOORECENT_HLP" );
        LOGGER( 1, "    ( is_to_block_map_nomination ) Just Returning/blocking, cannot nominate recent maps." )
    }
    else
    {
        LOGGER( 1, "    ( is_to_block_map_nomination ) Just Returning/allowing, the map nominations." )
        return false;
    }

    return true;
}

stock map_nominate( player_id, mapIndex )
{
    LOGGER( 128, "I AM ENTERING ON map_nominate(2) player_id: %d, mapIndex: %d", player_id, mapIndex )
    new mapName[ MAX_MAPNAME_LENGHT ];

    // get the nominated map name
    GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, mapName )
    LOGGER( 4, "( map_nominate ) mapIndex: %d, mapName: %s", mapIndex, mapName )

    if( !is_to_block_map_nomination( player_id, mapName ) )
    {
        new bool:isWhiteListNomBlock = ( IS_WHITELIST_ENABLED()
                                         && IS_TO_HOURLY_LOAD_THE_WHITELIST() );

        if( isWhiteListNomBlock )
        {
            // Not loaded?
            tryToLoadTheWhiteListFeature();

            if( IS_WHITELIST_BLOCKING( isWhiteListNomBlock, mapName ) )
            {
                color_print( player_id, "%L", player_id, "GAL_NOM_FAIL_WHITELIST", mapName );
                LOGGER( 1, "    ( map_nominate ) The map: %s, was blocked by the whitelist map setting.", mapName )
                return;
            }
        }

        try_to_add_the_nomination( player_id, mapIndex, mapName );
    }
}

stock try_to_add_the_nomination( player_id, mapIndex, mapName[] )
{
    LOGGER( 128, "I AM ENTERING ON try_to_add_the_nomination(3) player_id: %d, mapIndex: %d, mapName: %s", \
            player_id, mapIndex, mapName )

    // check if the map has already been nominated
    new nominatorPlayerId = nomination_getPlayer( mapIndex );

    // When no one nominated this map, the variable 'nominatorPlayerId' will be 0. Then here we
    // to nominate it.
    if( nominatorPlayerId == 0 )
    {
        add_my_nomination( player_id, mapIndex, mapName );
    }
    else if( nominatorPlayerId == player_id )
    {
        // If the nominatorPlayerId is equal to the current player_id, the player is trying to nominate
        // the same map again. And it is not allowed.
        color_print( player_id, "%L", player_id, "GAL_NOM_FAIL_ALREADY", mapName );
    }
    else
    {
        // The player nomination is the same as some other player before. And it is not allowed.
        new player_name[ MAX_PLAYER_NAME_LENGHT ];
        GET_USER_NAME( nominatorPlayerId, player_name )

        color_print( player_id, "%L", player_id, "GAL_NOM_FAIL_SOMEONEELSE", mapName, player_name );
        color_print( player_id, "%L", player_id, "GAL_NOM_FAIL_SOMEONEELSE_HLP" );
    }
}

stock add_my_nomination( player_id, mapIndex, mapName[] )
{
    LOGGER( 128, "I AM ENTERING ON add_my_nomination(0) player_id: %d, mapIndex: %d, mapName: %s", \
            player_id, mapIndex, mapName )

    new openNominationIndex;
    new maxPlayerNominations = min( get_pcvar_num( cvar_nomPlayerAllowance ), MAX_OPTIONS_IN_VOTE );

    // When max nomination limit is reached, then we must not to allow this nomination.
    if( countPlayerNominations( player_id, openNominationIndex ) >= maxPlayerNominations )
    {
        show_my_nominated_maps( player_id, maxPlayerNominations );
    }
    else
    {
        // otherwise, allow the nomination
        setPlayerNominationMapIndex( player_id, openNominationIndex, mapIndex );

        map_announceNomination( player_id, mapName );
        color_print( player_id, "%L", player_id, "GAL_NOM_GOOD_HLP" );
    }

    LOGGER( 4, "( try_to_add_the_nomination ) openNominationIndex: %d, mapName: %s", openNominationIndex, mapName )
}

stock show_my_nominated_maps( player_id, maxPlayerNominations )
{
    LOGGER( 128, "I AM ENTERING ON show_my_nominated_maps(2) player_id: %d, maxPlayerNominations: %d", \
            player_id, maxPlayerNominations )

    new mapIndex;
    new copiedChars;

    new nominatedMaps   [ MAX_COLOR_MESSAGE ];
    new nominatedMapName[ MAX_MAPNAME_LENGHT ];

    for( new nominationIndex = 0; nominationIndex < maxPlayerNominations; ++nominationIndex )
    {
        mapIndex = getPlayerNominationMapIndex( player_id, nominationIndex );
        GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, nominatedMapName )

        if( copiedChars )
        {
            copiedChars += copy( nominatedMaps[ copiedChars ],
                    charsmax( nominatedMaps ) - copiedChars, ", " );
        }

        copiedChars += copy( nominatedMaps[ copiedChars ],
                charsmax( nominatedMaps ) - copiedChars, nominatedMapName );
    }

    color_print( player_id, "%L", player_id, "GAL_NOM_FAIL_TOOMANY", maxPlayerNominations, nominatedMaps );
    color_print( player_id, "%L", player_id, "GAL_NOM_FAIL_TOOMANY_HLP" );
}

/**
 * Print to chat all players nominations available. This is usually called by 'say noms'.
 */
public nomination_list()
{
    LOGGER( 128, "I AM ENTERING ON nomination_list(0)" )

    new mapIndex;
    new copiedChars;
    new nomMapCount;

    new mapsList[ 101 ];
    new mapName [ MAX_MAPNAME_LENGHT ];

    new nominatedMapsCount = ArraySize( g_nominatedMapsArray );

    for( new nominationIndex = 0; nominationIndex < nominatedMapsCount; ++nominationIndex )
    {
        mapIndex = ArrayGetCell( g_nominatedMapsArray, nominationIndex );

        if( mapIndex > -1 )
        {
            GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, mapName )

            if( copiedChars )
            {
                copiedChars += copy( mapsList[ copiedChars ], charsmax( mapsList ) - copiedChars, "^1, ^4" );
            }

            copiedChars += copy( mapsList[ copiedChars ], charsmax( mapsList ) - copiedChars, mapName );

            if( ++nomMapCount == 4 )     // list 4 maps per chat line
            {
                if( IS_COLORED_CHAT_ENABLED() )
                {
                    color_print( 0, "%L: ^4%s", LANG_PLAYER, "GAL_NOMINATIONS", mapsList );
                }
                else
                {
                    REMOVE_CODE_COLOR_TAGS( mapsList )
                    color_print( 0, "%L: %s", LANG_PLAYER, "GAL_NOMINATIONS", mapsList );
                }

                nomMapCount   = 0;
                mapsList[ 0 ] = '^0';
            }
        }
    }

    if( mapsList[ 0 ] )
    {
        if( IS_COLORED_CHAT_ENABLED() )
        {
            color_print( 0, "%L: ^4%s", LANG_PLAYER, "GAL_NOMINATIONS", mapsList );
        }
        else
        {
            REMOVE_CODE_COLOR_TAGS( mapsList )
            client_print( 0, print_chat, "%L: %s", LANG_PLAYER, "GAL_NOMINATIONS", mapsList );
        }
    }
    else
    {
        if( IS_COLORED_CHAT_ENABLED() )
        {
            color_print( 0, "%L: ^4%L", LANG_PLAYER, "GAL_NOMINATIONS", LANG_PLAYER, "NONE" );
        }
        else
        {
            client_print( 0, print_chat, "%L: %L", LANG_PLAYER, "GAL_NOMINATIONS", LANG_PLAYER, "NONE"  );
        }
    }
}

stock getSurMapNameIndex( mapSurName[] )
{
    LOGGER( 128, "I AM ENTERING ON getSurMapNameIndex(1) mapSurName: %s", mapSurName )
    new map[ MAX_MAPNAME_LENGHT ];

    for( new prefixIndex = 0; prefixIndex < g_mapPrefixCount; ++prefixIndex )
    {
        formatex( map, charsmax( map ), "%s%s", g_mapPrefixes[ prefixIndex ], mapSurName );

        if( TrieKeyExists( g_nominationLoadedMapsTrie, map ) )
        {
            new mapIndex;
            TrieGetCell( g_nominationLoadedMapsTrie, map, mapIndex );

            LOGGER( 1, "    ( getSurMapNameIndex ) Just Returning, mapIndex: %d", mapIndex )
            return mapIndex;
        }
    }

    LOGGER( 1, "    ( getSurMapNameIndex ) Just Returning, mapIndex: %d", -1 )
    return -1;
}

stock get_real_players_number()
{
    LOGGER( 256, "I AM ENTERING ON get_real_players_number(0)" )
    new playersCount;

    new players[ MAX_PLAYERS ];
    get_players( players, playersCount, "ch" );

#if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED ) \
    && DEBUG_LEVEL & DEBUG_LEVEL_FAKE_VOTES
    if( g_test_isTheUnitTestsRunning )
    {
        return g_test_aimedPlayersNumber;
    }

    return FAKE_PLAYERS_NUMBER_FOR_DEBUGGING;
#else
    #if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED )
        if( g_test_isTheUnitTestsRunning )
        {
            return g_test_aimedPlayersNumber;
        }

        return playersCount;
    #else
        #if DEBUG_LEVEL & DEBUG_LEVEL_FAKE_VOTES
            return FAKE_PLAYERS_NUMBER_FOR_DEBUGGING;
        #else
            return playersCount;
        #endif
    #endif
#endif
}

stock percent( is, of )
{
    LOGGER( 256, "I AM ENTERING ON percent(2) is: %d, of: %d", is, of )
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
 *         color_print( g_colored_player_id, "%L %L %L",
 *                 g_colored_player_id, "LANG_A", g_colored_player_id, "LANG_B",
 *                 g_colored_player_id, "LANG_C", any_variable_used_on_LANG_C )
 *     }
 * #else
 *     color_print( 0, "%L %L %L", LANG_PLAYER, "LANG_A",
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
 * @param player_id          the player id.
 * @param message[]          the text formatting rules to display.
 * @param any                the variable number of formatting parameters.
 *
 * @see <a href="https://www.amxmodx.org/api/amxmodx/client_print_color">client_print_color</a>
 * for Amx Mod X 1.8.3 or superior.
 */
stock color_print( const player_id, const message[], any:... )
{
    LOGGER( 128, "I AM ENTERING ON color_print(...) player_id: %d, message: %s...", player_id, message )
    new formated_message[ MAX_COLOR_MESSAGE ];

#if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED )
    g_test_printedMessage[ 0 ] = '^0';

    vformat( g_test_printedMessage, charsmax( g_test_printedMessage ), message, 3 );
    LOGGER( 64, "( color_print ) player_id: %d, g_test_printedMessage: %s", player_id, g_test_printedMessage )
#endif

    /**
     * Bug; On AMXX 1.8.2, disabling the color chat, make all messages to all players being on the
     * server language, instead of the player language. This is a AMXX 1.8.2 bug only. There is a
     * way to overcome this. It is to print a message to each player, as the colored print does.
     */
#if AMXX_VERSION_NUM < 183
    if( player_id )
    {
        if( IS_COLORED_CHAT_ENABLED() )
        {
            // On the AMXX 182, all the colored messaged must to start within a color.
            formated_message[ 0 ] = '^1';
            vformat( formated_message[ 1 ], charsmax( formated_message ) - 1, message, 3 );

            new message[ MAX_COLOR_MESSAGE ];

            if( g_coloredChatPrefix[ 0 ] )
            {
                formatex( message, charsmax( message ), "^1%s^1%s", g_coloredChatPrefix, formated_message[ 1 ] );

                LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, message )
                PRINT_COLORED_MESSAGE( player_id, message )
            }
            else
            {
                LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, formated_message )
                PRINT_COLORED_MESSAGE( player_id, formated_message )
            }
        }
        else
        {
            vformat( formated_message, charsmax( formated_message ), message, 3 );
            LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, formated_message )

            REMOVE_CODE_COLOR_TAGS( formated_message )
            client_print( player_id, print_chat, "%s%s", g_coloredChatPrefix, formated_message );
        }
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
            LOGGER( 64, "    ( color_print ) Returning on playersCount: %d...", playersCount )
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

        LOGGER( 64, "( color_print ) playersCount: %d, params_number: %d...", playersCount, params_number )

        // ML can be used
        if( params_number > 3 )
        {
            for( argument_index = 2; argument_index < params_number; argument_index++ )
            {
                LOGGER( 64, "( color_print ) getarg(%d): %d", argument_index, getarg( argument_index, 0 ) )

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

                    LOGGER( 64, "( color_print ) player_id: %d, formated_message: %s", \
                            player_id, formated_message )

                    LOGGER( 64, "( color_print ) GetLangTransKey( formated_message ) != TransKey_Bad: %d, \
                          multi_lingual_constants_number: %d, string_index: %d...", \
                          GetLangTransKey( formated_message ) != TransKey_Bad, \
                          multi_lingual_constants_number, string_index )

                    if( GetLangTransKey( formated_message ) != TransKey_Bad )
                    {
                        // Store that argument as LANG_PLAYER so we can alter it later
                        ArrayPushCell( multi_lingual_indexes_array, argument_index++ );

                        // Update ML array, so we'll know 1st if ML is used,
                        // 2nd how many arguments we have to change
                        multi_lingual_constants_number++;
                    }

                    LOGGER( 64, "( color_print ) argument_index (after ArrayPushCell): %d...", argument_index )
                }
            }
        }

        LOGGER( 64, "( color_print ) multi_lingual_constants_number: %d...", multi_lingual_constants_number )

        for( --playersCount; playersCount >= 0; --playersCount )
        {
            player_id = players[ playersCount ];

            if( multi_lingual_constants_number )
            {
                for( argument_index = 0; argument_index < multi_lingual_constants_number; argument_index++ )
                {
                    LOGGER( 64, "( color_print ) argument_index: %d, player_id: %d, \
                            ArrayGetCell( %d, %d ): %d...", \
                            argument_index, player_id, \
                            multi_lingual_indexes_array, argument_index, \
                            ArrayGetCell( multi_lingual_indexes_array, argument_index ) )

                    // Set all LANG_PLAYER args to player index ( = player_id )
                    // so we can format the text for that specific player
                    setarg( ArrayGetCell( multi_lingual_indexes_array, argument_index ), _, player_id );
                }
            }

            if( IS_COLORED_CHAT_ENABLED() )
            {
                // On the AMXX 182, all the colored messaged must to start within a color.
                formated_message[ 0 ] = '^1';
                vformat( formated_message[ 1 ], charsmax( formated_message ) - 1, message, 3 );

                new message[ MAX_COLOR_MESSAGE ];

                if( g_coloredChatPrefix[ 0 ] )
                {
                    formatex( message, charsmax( message ), "^1%s^1%s", g_coloredChatPrefix, formated_message[ 1 ] );

                    LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, message )
                    PRINT_COLORED_MESSAGE( player_id, message )
                }
                else
                {
                    LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, formated_message )
                    PRINT_COLORED_MESSAGE( player_id, formated_message )
                }
            }
            else
            {
                vformat( formated_message, charsmax( formated_message ), message, 3 );
                LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, formated_message )

                REMOVE_CODE_COLOR_TAGS( formated_message )
                client_print( player_id, print_chat, "%s%s", g_coloredChatPrefix, formated_message );
            }
        }

        ArrayDestroy( multi_lingual_indexes_array );
    }
#else // this else only works for AMXX 183 or superior, due noted bug above.

    vformat( formated_message, charsmax( formated_message ), message, 3 );
    LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, formated_message )

    if( IS_COLORED_CHAT_ENABLED() )
    {
        client_print_color( player_id, print_team_default, "%s^1%s", g_coloredChatPrefix, formated_message );
    }
    else
    {
        REMOVE_CODE_COLOR_TAGS( formated_message )
        client_print( player_id, print_chat, "%s%s", g_coloredChatPrefix, formated_message );
    }
#endif

    LOGGER( 64, "( color_print ) [out] player_id: %d, Chat printed: %s...", player_id, formated_message )
}

/**
 * ConnorMcLeod's [Dyn Native] ColorChat v0.3.2 (04 jul 2013) register_dictionary_colored function:
 *   <a href="https://forums.alliedmods.net/showthread.php?p=851160">ColorChat v0.3.2</a>
 *
 * @param dictionaryFile the dictionary file name including its file extension.
 */
stock register_dictionary_colored( const dictionaryFile[] )
{
    LOGGER( 128, "I AM ENTERING ON register_dictionary_colored(1) dictionaryFile: %s", dictionaryFile )

    if( !register_dictionary( dictionaryFile ) )
    {
        LOGGER( 1, "    Returning 0 on if( !register_dictionary(%s) )", dictionaryFile )
        return 0;
    }

    new dictionaryFilePath[ MAX_FILE_PATH_LENGHT ];

    get_localinfo( "amxx_datadir", dictionaryFilePath, charsmax( dictionaryFilePath ) );
    formatex( dictionaryFilePath, charsmax( dictionaryFilePath ), "%s/lang/%s", dictionaryFilePath, dictionaryFile );

    // DO not SEPARE/SPLIT THIS DECLARATION in: new var; var = fopen... or it can crash some servers.
    new dictionaryFile = fopen( dictionaryFilePath, "rt" );

    if( !dictionaryFile )
    {
        log_amx( "Failed to open %s", dictionaryFilePath );
        LOGGER( 1, "    Returning 0 on if( !dictionaryFile ), Failed to open: %s", dictionaryFilePath )
        return 0;
    }

    new TransKey:translationKeyId;

    new langTypeAcronym    [ 3 ];
    new currentReadLine    [ MAX_BIG_BOSS_STRING ];
    new langConstantName   [ MAX_SHORT_STRING ];
    new langTranslationText[ MAX_LONG_STRING ];

    while( !feof( dictionaryFile ) )
    {
        fgets( dictionaryFile, currentReadLine, charsmax( currentReadLine ) );
        trim( currentReadLine );

        if( currentReadLine[ 0 ] == '[' )
        {
            STR_TOKEN( currentReadLine[ 1 ], langTypeAcronym, charsmax( langTypeAcronym ), currentReadLine, 1, ']' );
        }
        else if( currentReadLine[ 0 ] )
        {
        #if AMXX_VERSION_NUM < 183
            strbreak( currentReadLine, langConstantName, charsmax( langConstantName ), langTranslationText, charsmax( langTranslationText ) );
        #else
            argbreak( currentReadLine, langConstantName, charsmax( langConstantName ), langTranslationText, charsmax( langTranslationText ) );
        #endif

            translationKeyId = GetLangTransKey( langConstantName );

            if( translationKeyId != TransKey_Bad )
            {
                if( IS_COLORED_CHAT_ENABLED() )
                {
                    INSERT_COLOR_TAGS( langTranslationText )
                }
                else
                {
                    REMOVE_LETTER_COLOR_TAGS( langTranslationText )
                }

                LOGGER( 256, "lang: %s, Id: %d, Text: %s", langTypeAcronym, translationKeyId, langTranslationText )
                AddTranslation( langTypeAcronym, translationKeyId, langTranslationText[ 2 ] );
            }
        }
    }

    fclose( dictionaryFile );
    return 1;
}

/**
 * Immediately stops any vote in progress.
 */
stock cancelVoting( bool:isToDoubleReset = false )
{
    LOGGER( 128, "I AM ENTERING ON cancelVoting(1) isToDoubleReset: %d", isToDoubleReset )

    remove_task( TASKID_START_VOTING_DELAYED );
    remove_task( TASKID_DELETE_USERS_MENUS );
    remove_task( TASKID_DELETE_USERS_MENUS_CARE );
    remove_task( TASKID_VOTE_DISPLAY );
    remove_task( TASKID_PREVENT_INFITY_GAME );
    remove_task( TASKID_DBG_FAKEVOTES );
    remove_task( TASKID_VOTE_HANDLEDISPLAY );
    remove_task( TASKID_VOTE_EXPIRE );
    remove_task( TASKID_VOTE_STARTDIRECTOR );
    remove_task( TASKID_PENDING_VOTE_COUNTDOWN );
    remove_task( TASKID_MAP_CHANGE );
    remove_task( TASKID_INTERMISSION_HOLD );
    remove_task( TASKID_DISPLAY_REMAINING_TIME );
    remove_task( TASKID_PROCESS_LAST_ROUND );
    remove_task( TASKID_PROCESS_LAST_ROUND_COUNT );
    remove_task( TASKID_PROCESS_LAST_ROUNDCHANGE );
    remove_task( TASKID_SHOW_LAST_ROUND_HUD );
    remove_task( TASKID_SHOW_LAST_ROUND_MESSAGE );
    remove_task( TASKID_FINISH_GAME_TIME_BY_HALF );

    finalizeVoting();
    resetRoundEnding();
    delete_users_menus( isToDoubleReset );

    // Disables the flags without to invalid a last voting outcome results.
    g_voteStatus &= ~IS_VOTE_IN_PROGRESS;
    g_voteStatus &= ~IS_FORCED_VOTE;
    g_voteStatus &= ~IS_RUNOFF_VOTE;
}

/**
 * To prepare for a new runoff voting or partially to prepare for a complete new voting. If it is
 * not a runoff voting, 'finalizeVoting()' must be called before this.
 */
public vote_resetStats()
{
    LOGGER( 128, "I AM ENTERING ON vote_resetStats(0)" )

    g_voteStatusClean[ 0 ] = '^0';
    g_totalVotesCounted    = 0;
    g_pendingVoteCountdown = 7;

    // reset everyones' rocks.
    g_rockedVoteCount = 0;
    arrayset( g_rockedVote, false, sizeof g_rockedVote );

    // reset everyones' votes
    arrayset( g_isPlayerVoted, true, sizeof g_isPlayerVoted );

    if( !( g_voteStatus & IS_RUNOFF_VOTE ) )
    {
        g_totalVoteOptions = 0;
        clearTheVotingMenu();

        arrayset( g_isPlayerParticipating, true, sizeof g_isPlayerParticipating );
    }

    arrayset( g_isPlayerCancelledVote, false, sizeof g_isPlayerCancelledVote );
    arrayset( g_answeredForEndOfMapVote, false, sizeof g_answeredForEndOfMapVote );
    arrayset( g_isPlayerSeeingTheSubMenu, false, sizeof g_isPlayerSeeingTheSubMenu );
    arrayset( g_isPlayerSeeingTheVoteMenu, false, sizeof g_isPlayerSeeingTheVoteMenu );
    arrayset( g_isPlayerClosedTheVoteMenu, false, sizeof g_isPlayerClosedTheVoteMenu );

    arrayset( g_playerVotedOption, 0, sizeof g_playerVotedOption );
    arrayset( g_playerVotedWeight, 0, sizeof g_playerVotedWeight );
    arrayset( g_arrayOfMapsWithVotesNumber, 0, sizeof g_arrayOfMapsWithVotesNumber );
}

stock clearTheVotingMenu()
{
    g_totalVoteOptions = 0;

    for( new currentIndex = 0; currentIndex < sizeof g_votingMapNames; ++currentIndex )
    {
        LOGGER( 8, "Cleaning g_votingMapNames[%d]: %s", currentIndex, g_votingMapNames[ currentIndex ] )
        g_arrayOfRunOffChoices[ currentIndex ] = 0;

        g_votingMapNames[ currentIndex ][ 0 ] = '^0';
        g_votingMapInfos[ currentIndex ][ 0 ] = '^0';
    }
}

public delete_users_menus_care()
{
    LOGGER( 128, "I AM ENTERING ON delete_users_menus_care(0)" )
    delete_users_menus();
}

stock delete_user_menu( player_id )
{
    LOGGER( 128, "I AM ENTERING ON delete_user_menu(1) player_id: %d", player_id )

    new menu_id;
    new menuKeys;
    new menuKeys_unused;
    new failureMessage[ 128 ];

    menuKeys  = MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4;
    menuKeys |= MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9;

    get_user_menu( player_id, menu_id, menuKeys_unused );

    if( g_isPlayerSeeingTheSubMenu[ player_id ]
        || menu_id == g_chooseMapMenuId
        || menu_id == g_chooseMapQuestionMenuId )
    {
        // formatex( failureMessage, charsmax( failureMessage ), "%L", player_id, "GAL_VOTE_ENDED" );
        formatex( failureMessage, charsmax( failureMessage ), "Closing the Menu..." );
        show_menu( player_id, menuKeys, failureMessage, 2, CHOOSE_MAP_MENU_NAME );
    }
}

stock delete_users_menus( bool:isToDoubleReset = false )
{
    LOGGER( 128, "I AM ENTERING ON delete_users_menus(1) isToDoubleReset: %d", isToDoubleReset )

    new menu_id;
    new player_id;
    new playersCount;
    new menuKeys;
    new menuKeys_unused;

    new players       [ MAX_PLAYERS ];
    new failureMessage[ 128 ];

    menuKeys  = MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4;
    menuKeys |= MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9;

    get_players( players, playersCount, "ch" );

    if( isToDoubleReset )
    {
        set_task( 6.0, "vote_resetStats", TASKID_DELETE_USERS_MENUS );
    }

    for( new player_index; player_index < playersCount; ++player_index )
    {
        player_id = players[ player_index ];
        get_user_menu( player_id, menu_id, menuKeys_unused );

        if( menu_id == g_chooseMapMenuId
            || menu_id == g_chooseMapQuestionMenuId )
        {
            formatex( failureMessage, charsmax( failureMessage ), "%L", player_id, "GAL_VOTE_ENDED" );
            show_menu( player_id, menuKeys, failureMessage, isToDoubleReset ? 5 : 2, CHOOSE_MAP_MENU_NAME );
        }
    }
}

stock tryToSetGameModCvarFloat( cvarPointer, Float:value )
{
    LOGGER( 128, "I AM ENTERING ON tryToSetGameModCvarFloat(2) cvarPointer: %d, value: %f", cvarPointer, value )
    LOGGER( 1, "    ( tryToSetGameModCvarNum ) cvar_disabledValuePointer: %d", cvar_disabledValuePointer )

    if( cvarPointer != cvar_disabledValuePointer )
    {
        LOGGER( 2, "    ( tryToSetGameModCvarFloat ) IS CHANGING THE CVAR '%d' to '%f'.", cvarPointer, value )
        set_pcvar_float( cvarPointer, value );
    }
}

stock tryToSetGameModCvarNum( cvarPointer, num )
{
    LOGGER( 128, "I AM ENTERING ON tryToSetGameModCvarNum(2) cvarPointer: %d, num: %d", cvarPointer, num )
    LOGGER( 1, "    ( tryToSetGameModCvarNum ) cvar_disabledValuePointer: %d", cvar_disabledValuePointer )

    if( cvarPointer != cvar_disabledValuePointer )
    {
        LOGGER( 2, "    ( tryToSetGameModCvarNum ) IS CHANGING THE CVAR '%d' to '%d'.", cvarPointer, num )
        set_pcvar_num( cvarPointer, num );
    }
}

stock tryToSetGameModCvarString( cvarPointer, string[] )
{
    LOGGER( 128, "I AM ENTERING ON tryToSetGameModCvarString(2) cvarPointer: %d, string: %s", cvarPointer, string )
    LOGGER( 1, "    ( tryToSetGameModCvarNum ) cvar_disabledValuePointer: %d", cvar_disabledValuePointer )

    if( cvarPointer != cvar_disabledValuePointer )
    {
        LOGGER( 2, "    ( tryToSetGameModCvarString ) IS CHANGING THE CVAR '%d' to '%s'.", cvarPointer, string )
        set_pcvar_string( cvarPointer, string );
    }
}

public plugin_end()
{
    LOGGER( 32, "" )
    LOGGER( 32, "" )
    LOGGER( 32, "" )
    LOGGER( 32, "I AM ENTERING ON plugin_end(0). THE END OF THE PLUGIN LIFE!" )

#if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED )
    // Just in case the Unit Tests are running while changing level.
    restoreServerCvarsFromTesting();

    // Clean the unit tests data
    TRY_TO_APPLY( TrieDestroy, g_test_failureIdsTrie )
    TRY_TO_APPLY( TrieDestroy, g_test_strictValidMapsTrie )

    TRY_TO_APPLY( ArrayDestroy, g_test_idsAndNamesArray )
    TRY_TO_APPLY( ArrayDestroy, g_test_failureIdsArray )
    TRY_TO_APPLY( ArrayDestroy, g_test_failureReasonsArray )
#endif

    new currentIndex;
    new gameCrashActionFilePath[ MAX_FILE_PATH_LENGHT ];

    setTheCurrentAndNextMapSettings();
    map_restoreEndGameCvars();

    // Clear Dynamic Arrays
    // ############################################################################################
    destroy_two_dimensional_array( g_norPlayerFillerMapGroupArrays );
    destroy_two_dimensional_array( g_minPlayerFillerMapGroupArrays );
    destroy_two_dimensional_array( g_midPlayerFillerMapGroupArrays );

    TRY_TO_APPLY( ArrayDestroy, g_emptyCycleMapsArray )
    TRY_TO_APPLY( ArrayDestroy, g_mapcycleFileListArray )
    TRY_TO_APPLY( ArrayDestroy, g_nominationLoadedMapsArray )
    TRY_TO_APPLY( ArrayDestroy, g_recentListMapsArray )
    TRY_TO_APPLY( ArrayDestroy, g_whitelistArray )
    TRY_TO_APPLY( ArrayDestroy, g_nominatedMapsArray )

    TRY_TO_APPLY( ArrayDestroy, g_voteMinPlayerFillerPathsArray )
    TRY_TO_APPLY( ArrayDestroy, g_voteMidPlayerFillerPathsArray )
    TRY_TO_APPLY( ArrayDestroy, g_voteNorPlayerFillerPathsArray )

    TRY_TO_APPLY( ArrayDestroy, g_minMaxMapsPerGroupToUseArray )
    TRY_TO_APPLY( ArrayDestroy, g_midMaxMapsPerGroupToUseArray )
    TRY_TO_APPLY( ArrayDestroy, g_norMaxMapsPerGroupToUseArray )

    // Clear Dynamic Tries
    // ############################################################################################
    TRY_TO_APPLY( TrieDestroy, g_forwardSearchNominationsTrie )
    TRY_TO_APPLY( TrieDestroy, g_reverseSearchNominationsTrie )

    TRY_TO_APPLY( TrieDestroy, g_whitelistTrie )
    TRY_TO_APPLY( TrieDestroy, g_recentMapsTrie )
    TRY_TO_APPLY( TrieDestroy, g_mapcycleFileListTrie )

    TRY_TO_APPLY( TrieDestroy, g_blacklistTrie )
    TRY_TO_APPLY( TrieDestroy, g_nominationLoadedMapsTrie )

    // Clear the dynamic arras, just to be sure.
    for( currentIndex = 0; currentIndex < MAX_PLAYERS_COUNT; ++currentIndex )
    {
        // To clear each one separately to improve the debugging sight.
        TRY_TO_APPLY( ArrayDestroy, g_partialMatchFirstPageItems[ currentIndex ] )
    }

    // Clear game crash action flag file for a new game.
    generateGameCrashActionFilePath( gameCrashActionFilePath, charsmax( gameCrashActionFilePath ) );
    delete_file( gameCrashActionFilePath );
}

/**
 * Same as TRY_TO_APPLY(2), but the second argument must to be a two Dimensional Dynamic Array.
 *
 * @param outerArray                   a Dynamic Array within several Dynamic Arrays.
 * @param isToDestroyTheOuterArray     whether to destroy or clear the `outerArray` provided.
 */
stock destroy_two_dimensional_array( Array:outerArray, bool:isToDestroyTheOuterArray = true )
{
    LOGGER( 128, "I AM ENTERING ON destroy_two_dimensional_array(1) arrayIndentifation: %d", outerArray )

    if( outerArray )
    {
        new innerArray;
        new size = ArraySize( outerArray );

        for( new index = 0; index < size; index++ )
        {
            innerArray = ArrayGetCell( outerArray, index );
            TRY_TO_APPLY( ArrayDestroy, Array:innerArray )
        }

        if( isToDestroyTheOuterArray )
        {
            TRY_TO_APPLY( ArrayDestroy, outerArray )
        }
        else
        {
            TRY_TO_APPLY( ArrayClear, outerArray )
        }
    }
}

/**
 * If the IS_MAP_VALID check failed, check the end of the string for the `.bsp` extension.
 */
stock is_map_valid_bsp_check( mapName[] )
{
    new length = strlen( mapName ) - 4;

    // The mapName was too short to possibly house the .bsp extension
    if( length < 0 )
    {
        LOGGER( 256, "    ( is_map_valid_bsp_check ) Returning false, %s length < 0.", mapName )
        return false;
    }

    if( equali( mapName[ length ], ".bsp" ) )
    {
        // If the ending was .bsp, then cut it off.
        // As the string is by reference, so this copies back to the loaded text.
        mapName[ length ] = '^0';

        // Recheck
        if( is_map_valid( mapName ) )
        {
            LOGGER( 256, "    ( is_map_valid_bsp_check ) Returning true, %s", mapName )
            return true;
        }
    }

    LOGGER( 256, "    ( is_map_valid_bsp_check ) Returning false, %s", mapName )
    return false;
}

/**
 * Configure the print indexes padding and max line length in characters.
 */
#define MAX_CELL_LENGHT    20
#define MAX_MESSAGE_LENGHT 80

stock printDynamicArrayCells( Array:array )
{
    // server_print( "" );

    new indexString      [ 8                  ];
    new elementString    [ 8                  ];
    new cellString       [ MAX_CELL_LENGHT    ];
    new cellStringsBuffer[ MAX_MESSAGE_LENGHT ];

    new arraySize = ArraySize( array );

    for( new index = 0; index < arraySize; index++ )
    {
        // Create a cellString within a trailing comma
        formatex( indexString  , charsmax( indexString )  , "(%d) "    , index                        );
        formatex( elementString, charsmax( elementString ), "%d, "     , ArrayGetCell( array, index ) );
        formatex( cellString   , charsmax( cellString )   , "%7s %-9s" , indexString, elementString   );

        // Add a new cellString to the output buffer and flushes it when it full
        announceCellString( cellString, cellStringsBuffer );
    }

    // Flush the last cells
    flushCellStrings( cellStringsBuffer );
    // server_print( "" );
}

/**
 * Announce cells to the server console.
 *
 * @param cellStringAnnounce     a cell as string.
 * @param cellStringsBuffer      the output string to be printed.
 *
 * @note It does not immediately print the cell, the output occurs when the buffer is full.
 */
stock announceCellString( cellStringAnnounce[], cellStringsBuffer[] )
{
    static copiedChars;

    // Reset the characters counter for the output flush
    if( !cellStringsBuffer[ 0 ] )
    {
        copiedChars = 0;
    }

    // Add the cellString to the buffer
    copiedChars += copy( cellStringsBuffer[ copiedChars ], MAX_MESSAGE_LENGHT - 1 - copiedChars, cellStringAnnounce );

    // Calculate whether to flush now or not
    if( copiedChars > MAX_MESSAGE_LENGHT - MAX_CELL_LENGHT )
    {
        flushCellStrings( cellStringsBuffer );
    }
}

/**
 * Print the current buffer, if there are any cellStrings on it.
 *
 * @param cellStringsBuffer     the formatted cellStrings list to be printed.
 */
stock flushCellStrings( cellStringsBuffer[] )
{
    if( cellStringsBuffer[ 0 ] )
    {
        // Print the message
        server_print( "%-13s%s", "Array Cells: ", cellStringsBuffer[ 0 ]  );

        // Clear the buffer
        cellStringsBuffer[ 0 ] = '^0';
    }
}



// ################################## AMX MOD X NEXTMAP PLUGIN ###################################

public nextmapPluginInit()
{
    LOGGER( 128, "I AM ENTERING ON nextmapPluginInit(0)" )

    pause( "acd", "nextmap.amxx" );
    register_event( "30", "changeMap", "a" );
    register_dictionary( "nextmap.txt" );

    register_clcmd( "say nextmap", "sayNextMap", 0, "- displays nextmap" );
    register_clcmd( "say currentmap", "sayCurrentMap", 0, "- display current map" );

    cvar_amx_nextmap = register_cvar( "amx_nextmap", "", FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_SPONLY );

    if( cvar_mp_friendlyfire )
    {
        register_clcmd( "say ff", "sayFFStatus", 0, "- display friendly fire status" );
    }
}

stock loadTheNextMapFile( mapcycleFilePath[], mapcycleFilePathLength )
{
    LOGGER( 128, "I AM ENTERING ON loadNextMapPluginSetttings(2)" )
    get_pcvar_string( cvar_mapcyclefile, mapcycleFilePath, mapcycleFilePathLength );

    g_mapcycleFileListTrie  = TrieCreate();
    g_mapcycleFileListArray = ArrayCreate( MAX_MAPNAME_LENGHT );

    map_populateListOnSeries( g_mapcycleFileListArray, g_mapcycleFileListTrie, mapcycleFilePath );
    LOGGER( 0, "", printDynamicArrayMaps( g_mapcycleFileListArray, 256 ) )
}

stock printDynamicArrayMaps( Array:populatedArray, debugLevel )
{
    LOGGER( debugLevel, "I AM ENTERING ON printDynamicArrayMaps(1) array id: %d", populatedArray )

    new mapName[ MAX_MAPNAME_LENGHT ];
    new size = ArraySize( populatedArray );

    for( new index = 0; index < size; index++ )
    {
        ArrayGetString( populatedArray, index, mapName, charsmax( mapName ) );
        LOGGER( debugLevel, "index: %d, mapName: %s", index, mapName )
    }

    return 0;
}

/**
 * If the map cycles are loaded on the plugin_init(0), and the setting `gal_srv_move_cursor`, is
 * loaded only at the forward plugin_cfg(0). This ways we need to load both and discard the one
 * which was not necessary later when the settings are loaded on the plugin_cfg(0).
 *
 * Therefore we will get a completely wrong `g_nextMapCyclePosition` value which will mess with
 * everything, was the `gal_srv_move_cursor` feature makes both map cycle with different indexes.
 */
stock readMapCycle( mapcycleFilePath[], nextMapName[], nextMapNameMaxchars )
{
    LOGGER( 128, "I AM ENTERING ON readMapCycle(3) mapcycleFilePath: %s", mapcycleFilePath )

    new mapsProcessedNumber;
    new loadedMapName[ MAX_MAPNAME_LENGHT ];

    new mapCycleMapsCount = ArraySize( g_mapcycleFileListArray );

    if( mapCycleMapsCount )
    {
        for( new mapIndex = 0; mapIndex < mapCycleMapsCount; mapIndex++ )
        {
            GET_MAP_NAME( g_mapcycleFileListArray, mapIndex, loadedMapName )

            // Block the next map cvar to be set to the current map.
            if( ++mapsProcessedNumber > g_nextMapCyclePosition
                && !equali( g_currentMapName, loadedMapName ) )
            {
                copy( nextMapName, nextMapNameMaxchars, loadedMapName );
                LOGGER( 1, "( readMapCycle ) loadedMapName: %s", loadedMapName )
                LOGGER( 1, "( readMapCycle ) g_nextMapCyclePosition: %d", g_nextMapCyclePosition )

                g_nextMapCyclePosition = mapsProcessedNumber;
                LOGGER( 1, "( readMapCycle ) mapsProcessedNumber: %d", mapsProcessedNumber )

                LOGGER( 1, "    ( readMapCycle ) Just returning/blocking on 'mapsProcessedNumber > g_nextMapCyclePosition'." )
                return;
            }
        }

        // It it gets here, we are restarting the map cycle and starting following it from the first line.
        GET_MAP_NAME( g_mapcycleFileListArray, 0, nextMapName )
    }
    else
    {
        LOGGER( 1, "WARNING, readMapCycle: Couldn't find a valid map or the file doesn't exist (file ^"%s^")", mapcycleFilePath )
        log_amx(   "WARNING, readMapCycle: Couldn't find a valid map or the file doesn't exist (file ^"%s^")", mapcycleFilePath );

        copy( nextMapName, nextMapNameMaxchars, g_currentMapName );
    }

    LOGGER( 4, "( readMapCycle ) nextMapName: %s, nextMapNameMaxchars: %d", nextMapName, nextMapNameMaxchars )

    // Setting it to 1 will cause the next map to be `g_mapcycleFileListArray[1]` map.
    g_nextMapCyclePosition = 1;
}

stock loadNextMapPluginSetttings()
{
    LOGGER( 128, "I AM ENTERING ON loadNextMapPluginSetttings(0)" )

    new mapcycleCurrentIndex   [ MAX_MAPNAME_LENGHT ];
    new lastMapcycleFilePath   [ MAX_FILE_PATH_LENGHT ];
    new currentMapcycleFilePath[ MAX_FILE_PATH_LENGHT ];
    new tockenMapcycleAndPosion[ MAX_MAPNAME_LENGHT + MAX_FILE_PATH_LENGHT ];

    // Load the full map cycle if, considering whether the feature `gal_srv_move_cursor` is enabled or not.
    loadTheNextMapFile( currentMapcycleFilePath, charsmax( currentMapcycleFilePath ) );

    // The from the local info, the map token saved on the last server map.
    get_mapname( g_currentMapName, charsmax( g_currentMapName ) );
    get_localinfo( "lastmapcycle", tockenMapcycleAndPosion, charsmax( tockenMapcycleAndPosion ) );

    parse( tockenMapcycleAndPosion, lastMapcycleFilePath, charsmax( lastMapcycleFilePath ),
                                    mapcycleCurrentIndex, charsmax( mapcycleCurrentIndex ) );

    LOGGER( 2, "( loadNextMapPluginSetttings ) mapcycleCurrentIndex: %d", mapcycleCurrentIndex )
    LOGGER( 2, "( loadNextMapPluginSetttings ) lastMapcycleFilePath: %s", lastMapcycleFilePath )
    LOGGER( 2, "( loadNextMapPluginSetttings ) tockenMapcycleAndPosion: %s", tockenMapcycleAndPosion )
    LOGGER( 2, "( loadNextMapPluginSetttings ) currentMapcycleFilePath: %s", currentMapcycleFilePath )

    // mapcyclefile has been changed - go from first
    if( !equali( currentMapcycleFilePath, lastMapcycleFilePath ) )
    {
        g_nextMapCyclePosition = 0;
    }
    else
    {
        new lastMap[ MAX_MAPNAME_LENGHT ];

        g_nextMapCyclePosition = str_to_num( mapcycleCurrentIndex );
        get_localinfo( "galileo_lastmap", lastMap, charsmax( lastMap ) );

        if( equali( g_currentMapName, lastMap ) )
        {
            g_nextMapCyclePosition--;
        }
    }

    // Get the last next map set on the first server start
    if( get_pcvar_num( cvar_serverStartAction )
        && get_pcvar_num( cvar_isFirstServerStart ) == SECOND_SERVER_START )
    {
        // This is the key that tells us if this server has been started or not.
        set_pcvar_num( cvar_isFirstServerStart, AFTER_READ_MAPCYCLE );
        LOGGER( 2, "( loadNextMapPluginSetttings ) IS CHANGING THE CVAR 'gal_server_starting' to '%d'.", AFTER_READ_MAPCYCLE )

        get_pcvar_string( cvar_amx_nextmap, g_nextMapName, charsmax( g_nextMapName ) );

        if( IS_MAP_VALID( g_nextMapName ) )
        {
            LOGGER( 4, "( loadNextMapPluginSetttings ) g_nextMapName: %s", g_nextMapName )
        }
    }
    else
    {
        // Increments by 1, the global variable 'g_nextMapCyclePosition', or set its value to 1.
        readMapCycle( currentMapcycleFilePath, g_nextMapName, charsmax( g_nextMapName ) );
    }

    if( get_pcvar_num( cvar_nextMapChangeAnnounce )
        && get_pcvar_num( cvar_endOfMapVote ) )
    {
        new nextMapName[ 128 ];
        formatex( nextMapName, charsmax( nextMapName ), "%L", LANG_SERVER, "GAL_NEXTMAP_UNKNOWN" );

        REMOVE_CODE_COLOR_TAGS( nextMapName )
        set_pcvar_string( cvar_amx_nextmap, nextMapName );

    #if IS_TO_ENABLE_SVEN_COOP_SUPPPORT > 0
        tryToSetGameModCvarString( cvar_mp_nextmap_cycle, nextMapName );
    #endif
    }
    else
    {
        set_pcvar_string( cvar_amx_nextmap, g_nextMapName );
        LOGGER( 2, "( nextmapPluginInit ) IS CHANGING THE CVAR 'amx_nextmap' to '%s'.", g_nextMapName )

    #if IS_TO_ENABLE_SVEN_COOP_SUPPPORT > 0
        tryToSetGameModCvarString( cvar_mp_nextmap_cycle, g_nextMapName );
    #endif
    }

    saveCurrentMapCycleSetting( currentMapcycleFilePath );
}

/**
 * The variable 'g_nextMapCyclePosition' is updated also at 'handleServerStart(0)', to refresh the
 * new settings.
 *
 * @param mapcycleFilePath         the current map-cycle file path.
 */
stock saveCurrentMapCycleSetting( mapcycleFilePath[] )
{
    LOGGER( 128, "I AM ENTERING ON saveCurrentMapCycleSetting(1) mapcycleFilePath: %s", mapcycleFilePath )
    new tockenMapcycleAndPosion[ MAX_MAPNAME_LENGHT + MAX_FILE_PATH_LENGHT ];

    formatex( tockenMapcycleAndPosion, charsmax( tockenMapcycleAndPosion ), "%s %d", mapcycleFilePath, g_nextMapCyclePosition );
    LOGGER( 2, "( saveCurrentMapCycleSetting ) tockenMapcycleAndPosion: %s", tockenMapcycleAndPosion )

    // save lastmapcycle settings
    set_localinfo( "lastmapcycle", tockenMapcycleAndPosion );
    set_localinfo( "galileo_lastmap", g_currentMapName );
}

stock getNextMapName( nextMapName[], maxChars )
{
    LOGGER( 128, "I AM ENTERING ON getNextMapName(2) maxChars: %d", maxChars )
    new length = get_pcvar_string( cvar_amx_nextmap, nextMapName, maxChars );

    if( IS_MAP_VALID( nextMapName ) )
    {
        LOGGER( 4, "    ( getNextMapName ) Returning length: %d, nextMapName: %s", length, nextMapName )
        return length;
    }

    length = copy( nextMapName, maxChars, g_nextMapName );
    set_pcvar_string( cvar_amx_nextmap, g_nextMapName );

    LOGGER( 2, "( getNextMapName ) IS CHANGING THE CVAR 'amx_nextmap' to '%s'.", g_nextMapName )
    LOGGER( 1, "    ( getNextMapName ) Returning length: %d, nextMapName: %s", length, nextMapName )
    return length;
}

public sayNextMap()
{
    LOGGER( 128, "I AM ENTERING ON sayNextMap(0)" )
    new nextMapName[ MAX_MAPNAME_LENGHT ];

    get_pcvar_string( cvar_amx_nextmap, nextMapName, charsmax( nextMapName ) );

    if( get_pcvar_num( cvar_nextMapChangeAnnounce )
        && get_pcvar_num( cvar_endOfMapVote )
        && !( g_voteStatus & IS_VOTE_OVER ) )
    {
        if( g_voteStatus & IS_VOTE_IN_PROGRESS )
        {
            color_print( 0, "%L %L", LANG_PLAYER, "NEXT_MAP", LANG_PLAYER, "GAL_NEXTMAP_VOTING" );
        }
        else if( get_pcvar_num( cvar_nextMapChangeVotemap ) )
        {
            new nextMapFlag[ 128 ];
            new nextMapName[ MAX_MAPNAME_LENGHT ];

            formatex( nextMapFlag, charsmax( nextMapFlag ), "%L", LANG_SERVER, "GAL_NEXTMAP_UNKNOWN" );
            REMOVE_CODE_COLOR_TAGS( nextMapFlag )

            get_pcvar_string( cvar_amx_nextmap, nextMapName, charsmax( nextMapName ) );

            // If the values are not equal, it means the next map was changed by the admin, then
            // we must to show the changed map.
            if( !equali( nextMapFlag, nextMapName, strlen( nextMapName ) ) )
            {
                goto show_the_nextmap_cvar;
            }
            else
            {
                goto gal_nextmap_unknown;
            }
        }
        else
        {
            gal_nextmap_unknown:
            color_print( 0, "%L %L", LANG_PLAYER, "NEXT_MAP", LANG_PLAYER, "GAL_NEXTMAP_UNKNOWN" );
        }
    }
    else
    {
        show_the_nextmap_cvar:

        if( IS_COLORED_CHAT_ENABLED() )
        {
            color_print( 0, "%L ^4%s", LANG_PLAYER, "NEXT_MAP", nextMapName );
        }
        else
        {
            client_print( 0, print_chat, "%L %s", LANG_PLAYER, "NEXT_MAP", nextMapName );
        }
    }

    LOGGER( 4, "( sayNextMap ) cvar_endOfMapVote: %d, cvar_nextMapChangeAnnounce: %d", \
            get_pcvar_num( cvar_endOfMapVote ), get_pcvar_num( cvar_nextMapChangeAnnounce ) )

    LOGGER( 1, "    ( sayNextMap ) Just Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

public sayCurrentMap()
{
    LOGGER( 128, "I AM ENTERING ON sayCurrentMap(0)" )

    if( IS_COLORED_CHAT_ENABLED() )
    {
        color_print( 0, "%L ^4%s", LANG_PLAYER, "PLAYED_MAP", g_currentMapName );
    }
    else
    {
        client_print( 0, print_chat, "%L: %s", LANG_PLAYER, "PLAYED_MAP", g_currentMapName );
    }
}

public sayFFStatus()
{
    LOGGER( 128, "I AM ENTERING ON sayFFStatus(0)" )

    if( IS_COLORED_CHAT_ENABLED() )
    {
        color_print( 0, "%L: ^4%L",
                LANG_PLAYER, "FRIEND_FIRE",
                LANG_PLAYER, get_pcvar_num( cvar_mp_friendlyfire ) ? "ON" : "OFF" );
    }
    else
    {
        client_print( 0, print_chat, "%L: %L",
                LANG_PLAYER, "FRIEND_FIRE",
                LANG_PLAYER, get_pcvar_num( cvar_mp_friendlyfire ) ? "ON" : "OFF" );
    }
}

public changeMapIntermission()
{
    LOGGER( 128, "I AM ENTERING ON changeMapIntermission(0)" )

    intermission_hold();
    changeMap();
}

/**
 * If the game to be faster the us to change the level we must to restore the the `cvar_mp_chattime`
 * on plugin_end(0).
 */
stock restoreTheChatTime()
{
    LOGGER( 128, "I AM ENTERING ON restoreTheChatTime(0) g_originalChatTime: %f", g_originalChatTime )

    if( floatround( g_originalChatTime, floatround_floor ) )
    {
        LOGGER( 2, "( restoreTheChatTime ) IS CHANGING THE CVAR 'mp_chattime' to '%f'.", g_originalChatTime )
        tryToSetGameModCvarFloat( cvar_mp_chattime, g_originalChatTime );

        g_originalChatTime = 0.0;
    }
}

/**
 * This function call is only triggered by the game event register_event( "30", "changeMap", "a" ).
 */
public changeMap()
{
    LOGGER( 128, "I AM ENTERING ON changeMap(0)" )

    new Float:chatTime;
    new nextmap_name[ MAX_MAPNAME_LENGHT ];

    // mp_chattime defaults to 10 in other mods
    if( cvar_mp_chattime )
    {
        chatTime           = get_pcvar_float( cvar_mp_chattime );
        g_originalChatTime = chatTime;

        // make sure mp_chattime is long
        tryToSetGameModCvarFloat( cvar_mp_chattime, chatTime + 2.0 );
        LOGGER( 2, "( changeMap ) IS CHANGING THE CVAR 'mp_chattime' to '%f'.", chatTime + 2.0 )
    }

    new length = getNextMapName( nextmap_name, charsmax( nextmap_name ) ) + 1;

    // change with 1.5 sec. delay
    set_task( chatTime, "serverChangeLevel", 0, nextmap_name, length );
}

stock bool:isAValidMap( mapname[] )
{
    LOGGER( 128, "I AM ENTERING ON isAValidMap(1) mapname: %s", mapname )

    if( IS_MAP_VALID( mapname ) )
    {
        LOGGER( 256, "    ( isAValidMap ) Returning true." )
        return true;
    }

    // If the IS_MAP_VALID check failed, check the end of the string
    new length = strlen( mapname ) - 4;

    // The mapname was too short to possibly house the .bsp extension
    if( length < 0 )
    {
        LOGGER( 256, "    ( isAValidMap ) Returning false. [length < 0]" )
        return false;
    }

    if( equali( mapname[ length ], ".bsp" ) )
    {
        // If the ending was .bsp, then cut it off.
        // the string is by reference, so this copies back to the loaded text.
        mapname[ length ] = '^0';

        // recheck
        if( IS_MAP_VALID( mapname ) )
        {
            LOGGER( 256, "    ( isAValidMap ) Returning true." )
            return true;
        }
    }

    LOGGER( 256, "    ( isAValidMap ) Returning false." )
    return false;
}

stock getTheCurrentSerieForTheMap( mapNameDirt[], mapNameClean[] )
{
    LOGGER( 256, "I AM ENTERING ON getTheCurrentSerieForTheMap(2) mapNameDirt: %s", mapNameDirt )
    new mapNameLength = strlen( mapNameDirt );

    if( mapNameLength > 1 )
    {
        new searchIndex = mapNameLength - 1;

        // Move backwards until the number ends.
        while( searchIndex > -1
               && isdigit( mapNameDirt[ searchIndex ] ) )
        {
            // Removes the current series number from the map name.
            mapNameClean[ searchIndex ] = '^0';
            searchIndex--;
        }

        LOGGER( 256, "mapNameClean: %s", mapNameClean )

        // If its not a map name only within digits on its name, continues the algorithm.
        if( searchIndex > -1 )
        {
            new resultIndex;

            // Moves forward to the last know digit.
            searchIndex++;

            // Move forward until finish copying the number to the beginning of the string.
            while( isdigit( mapNameDirt[ searchIndex ] ) )
            {
                mapNameDirt[ resultIndex ] = mapNameDirt[ searchIndex ];
                mapNameDirt[ searchIndex ] = '^0';

                searchIndex++;
                resultIndex++;
            }

            // Null terminates the string, cutting everything else which are not digits.
            mapNameDirt[ resultIndex ] = '^0';
        }
    }

    LOGGER( 256, "( getTheCurrentSerieForTheMap ) mapNameDirt: %s", mapNameDirt )

    // We just to return the next map on the series instead of the current one, which is already loaded.
    if( isdigit( mapNameDirt[ 0 ] ) )
    {
        LOGGER( 256, "    ( getTheCurrentSerieForTheMap ) Returning: %d", str_to_num( mapNameDirt ) + 1 )
        return str_to_num( mapNameDirt ) + 1;
    }

    // We are returning 0 because someone may try to start their map series naming at 0.
    LOGGER( 256, "    ( getTheCurrentSerieForTheMap ) Returning 0, no number found." )

    return 0;
}

stock isThereNextMapOnTheSerie( &currentSerie, mapNameClean[], nextMapName[] )
{
    LOGGER( 256, "I AM ENTERING ON isThereNextMapOnTheSerie(3) mapNameClean: %s", mapNameClean )
    new currentForwardLook;

    // Look forward to be able to find more spaced sequences as `de_dust2002` and `de_dust2015`.
    do
    {
        formatex( nextMapName, MAX_MAPNAME_LENGHT - 1, "%s%d", mapNameClean, currentSerie );

        if( IS_MAP_VALID( nextMapName ) )
        {
            LOGGER( 256, "    ( isThereNextMapOnTheSerie ) Returning: 1, currentSerie: %d", currentSerie )
            return true;
        }

        // Moves the pointer to the next serie, if it still not find the valid map.
        currentSerie++;

    } while( currentForwardLook++ < MAX_NON_SEQUENCIAL_MAPS_ON_THE_SERIE );

    LOGGER( 256, "    ( isThereNextMapOnTheSerie ) Returning: false" )
    return false;
}

stock loadTheCursorOnMapSeries( Array:mapArray, Trie:mapTrie, Trie:loadedMapSeriesTrie, currentMapName[],
                                nextMapName[] , &mapCount   , cursorOnMapSeries )
{
    LOGGER( 256, "I AM ENTERING ON loadTheCursorOnMapSeries(7) currentMapName: %s", currentMapName )
    new currentSerie;

    new mapNameDirt [ MAX_MAPNAME_LENGHT ];
    new mapNameClean[ MAX_MAPNAME_LENGHT ];

    copy( mapNameDirt, charsmax( mapNameDirt ), currentMapName );
    copy( mapNameClean, charsmax( mapNameClean ), currentMapName );

    // If we are loading only map series starting at 1, block the execution if the initial serie is
    // greater than 2, because this function returns the next map on the series, then if the current
    // serie is 1, it will return 2. Therefore we must to allow it accordantly to the settings.
    if( ( currentSerie = getTheCurrentSerieForTheMap( mapNameDirt, mapNameClean ) ) > 2
        && cursorOnMapSeries & IS_TO_LOAD_EXPLICIT_MAP_SERIES )
    {
        LOGGER( 256, "    ( loadTheCursorOnMapSeries ) Returning/Blocking the execution." )
        return;
    }

    // Series longer than this size will not be considered.
    new maximumSerie = currentSerie + 3000;

    // We do not need to check for the `IS_TO_LOAD_ALL_THE_MAP_SERIES`, because we will always
    // being loading all the series, when any bit flag on `cursorOnMapSeries` is set, but the
    // Trie `loadedMapSeriesTrie` is not set.
    //
    // If the execution flow get until this point, it is certain there is some bit set on the
    // variable `cursorOnMapSeries`.
    if( loadedMapSeriesTrie )
    {
        // Do not reload the series if it was loaded before.
        if( !TrieKeyExists( loadedMapSeriesTrie, mapNameClean ) )
        {
            while( isThereNextMapOnTheSerie( currentSerie, mapNameClean, nextMapName )
                   && currentSerie < maximumSerie )
            {
                TrieSetCell( loadedMapSeriesTrie, mapNameClean, mapCount );

                TrieSetCell( mapTrie, nextMapName, mapCount );
                ArrayPushString( mapArray, nextMapName );

                LOGGER( 256, "( loadTheCursorOnMapSeries ) nextMapName: %s", nextMapName )

                // Moves the pointer to the next serie.
                currentSerie++;
                mapCount++;
            }
        }
    }
    else
    {
        while( isThereNextMapOnTheSerie( currentSerie, mapNameClean, nextMapName )
               && currentSerie < maximumSerie )
        {
            TrieSetCell( mapTrie, nextMapName, mapCount );
            ArrayPushString( mapArray, nextMapName );

            LOGGER( 256, "( loadTheCursorOnMapSeries ) nextMapName: %s", nextMapName )

            // Moves the pointer to the next serie.
            currentSerie++;
            mapCount++;
        }
    }
}

stock printUntilTheNthLoadedMap( mapIndex, mapName[] )
{
    // There is not point in adding the entry statement to this function as its purpose is only to
    // print few lines as possible.
    LOGGER( 0, "I AM ENTERING ON loadMapFileSeriesListArray(2)" )

    if( mapIndex < MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST )
    {
        LOGGER( 4, "( printUntilTheNthLoadedMap ) %d, loadedMapLine: %s", mapIndex, mapName )
    }

    return 0;
}

stock loadMapFileSeriesListArray( mapFileDescriptor, Array:mapArray, Trie:mapTrie, Trie:loadedMapSeriesTrie, cursorOnMapSeries )
{
    LOGGER( 128, "I AM ENTERING ON loadMapFileSeriesListArray(5) mapFileDescriptor: %d", mapFileDescriptor )

    new mapCount;
    new nextMapName  [ MAX_MAPNAME_LENGHT ];
    new loadedMapName[ MAX_MAPNAME_LENGHT ];
    new loadedMapLine[ MAX_MAPNAME_LENGHT ];

    while( !feof( mapFileDescriptor ) )
    {
        fgets( mapFileDescriptor, loadedMapLine, charsmax( loadedMapLine ) );
        trim( loadedMapLine );

        if( IS_IT_A_VALID_MAP_LINE( loadedMapLine ) )
        {
            GET_MAP_NAME_LEFT( loadedMapLine, loadedMapName )

            if( IS_MAP_VALID( loadedMapName ) )
            {
                TrieSetCell( mapTrie, loadedMapName, mapCount );
                ArrayPushString( mapArray, loadedMapLine );

                LOGGER( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapLine ) )

                if( cursorOnMapSeries )
                {
                    loadTheCursorOnMapSeries( mapArray, mapTrie, loadedMapSeriesTrie, loadedMapName,
                            nextMapName, mapCount, cursorOnMapSeries );
                }

                ++mapCount;
            }
        }
    }

    LOGGER( 1, "    ( loadMapFileSeriesListArray ) Returning mapCount: %d", mapCount )
    return mapCount;
}

stock loadMapFileListOnSeries( Array:mapArray, Trie:mapTrie, mapFilePath[] )
{
    LOGGER( 128, "I AM ENTERING ON loadMapFileListOnSeries(3) mapFilePath: %s", mapFilePath )

    new mapCount;
    new mapFileDescriptor = fopen( mapFilePath, "rt" );

    if( mapFileDescriptor )
    {
        new Trie:loadedMapSeriesTrie;
        new cursorOnMapSeries = get_pcvar_num( cvar_serverMoveCursor );

        // If the `IS_TO_LOAD_ALL_THE_MAP_SERIES` is set, it overrides the `IS_TO_LOAD_THE_FIRST_MAP_SERIES`
        // bit flag.
        if( cursorOnMapSeries & IS_TO_LOAD_THE_FIRST_MAP_SERIES
            && !( cursorOnMapSeries & IS_TO_LOAD_ALL_THE_MAP_SERIES ) )
        {
            loadedMapSeriesTrie = TrieCreate();
        }

        if( mapArray
            && mapTrie )
        {
            mapCount = loadMapFileSeriesListArray( mapFileDescriptor, mapArray, mapTrie, loadedMapSeriesTrie, cursorOnMapSeries );
        }

        TRY_TO_APPLY( TrieDestroy, loadedMapSeriesTrie )
        checkIfThereEnoughMapPopulated( mapCount, mapFileDescriptor );

        fclose( mapFileDescriptor );
        LOGGER( 4, "" )
    }
    else
    {
        LOGGER( 1, "( loadMapFileListOnSeries ) Error %d, %L", AMX_ERR_NOTFOUND, LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilePath )
        log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilePath );
    }

    LOGGER( 1, "    ( loadMapFileListOnSeries ) Returning mapCount: %d", mapCount )
    return mapCount;
}

/**
 * This function supposes map cycle as:
 *
 *     de_dust
 *     de_inferno
 *     de_chateal
 *     de_dust2
 *     de_nuke
 *
 * And will understand it as being:
 *
 *     de_dust
 *     de_dust2
 *     de_dust3
 *     de_dust4
 *     de_inferno
 *     de_chateal
 *     de_dust2
 *     de_nuke
 *
 * So the `mapsProcessedNumber` will count `de_dust4` as being the position 4 and `de_inferno` as being
 * the position 5, while in fact, `de_dust4` does not exist on the map cycle file, and the `de_inferno`
 * being actually on the position 2.
 */
stock map_populateListOnSeries( Array:mapArray, Trie:mapTrie, mapFilePath[] )
{
    LOGGER( 128, "I AM ENTERING ON map_populateListOnSeries(3) mapFilePath: %s", mapFilePath )

    // load the array with maps
    new mapCount;

    // If there is a map file to load
    if( mapFilePath[ 0 ] )
    {
        // clear the map array in case we're reusing it
        TRY_TO_APPLY( ArrayClear, mapArray )
        TRY_TO_APPLY( TrieClear , mapTrie )

        LOGGER( 4, "" )
        LOGGER( 4, "    map_populateListOnSeries(...) Loading the PASSED FILE! mapFilePath: %s", mapFilePath )

        mapCount = loadMapFileListOnSeries( mapArray, mapTrie, mapFilePath );
    }

    LOGGER( 1, "    I AM EXITING map_populateListOnSeries(3) mapCount: %d", mapCount )
    return mapCount;
}



// ################################## AMX MOD X TIMELEFT PLUGIN ###################################
//
// vim: set ts=4 sw=4 tw=99 noet:
//
// AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
// Copyright (C) The AMX Mod X Development Team.
//
// This software is licensed under the GNU General Public License, version 3 or higher.
// Additional exceptions apply. For full license details, see LICENSE.txt or visit:
//     https://alliedmods.net/amxmodx-license

//
// TimeLeft Plugin
//

const TASK_TIMEREMAIN_SHORT = 8648458;    // 0.8s repeat task
const TASK_TIMEREMAIN_LARGE = 34543;      // 1.0s repeat task

// time display flags
const TD_BOTTOM_WHITE_TEXT        = 1;     // a - display white text on bottom
const TD_USE_VOICE                = 2;     // b - use voice
const TD_NO_REMAINING_VOICE       = 4;     // c - don't add "remaining" (only in voice)
const TD_NO_HOURS_MINS_SECS_VOICE = 8;     // d - don't add "hours/minutes/seconds" (only in voice)
const TD_SHOW_SPEAK_VALUES_BELOW  = 16;    // e - show/speak if current time is less than this set in parameter

new g_LastTime;
new g_CountDown;
new g_Switch;
new g_TimeSet[ 32 ][ 2 ];

// pcvars
new g_amx_timeleft;
new g_amx_time_voice;

public timeleftPluginInit()
{
    LOGGER( 128, "I AM ENTERING ON timeleftPluginInit(0)" )

    g_amx_time_voice = register_cvar( "amx_time_voice", "1" );
    g_amx_timeleft   = register_cvar( "amx_timeleft", "00:00", FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_UNLOGGED | FCVAR_SPONLY );

    register_clcmd( "say timeleft", "sayTimeLeft", 0, "- displays timeleft" );
    register_clcmd( "say thetime", "sayTheTime", 0, "- displays current time" );

    set_task( 0.8, "timeRemain", TASK_TIMEREMAIN_SHORT, _, _, "b" );

    register_srvcmd( "amx_time_display", "setDisplaying" );
    register_dictionary( "timeleft.txt" );
}

public sayTheTime( id )
{
    LOGGER( 128, "I AM ENTERING ON sayTheTime(1) id: %d", id )

    if( get_pcvar_num( g_amx_time_voice ) )
    {
        new mhours[ 6 ], mmins[ 6 ], whours[ 32 ], wmins[ 32 ], wpm[ 6 ];

        get_time( "%H", mhours, charsmax( mhours ) );
        get_time( "%M", mmins, charsmax( mmins ) );

        new mins = str_to_num( mmins );
        new hrs  = str_to_num( mhours );

        if( mins )
        {
            num_to_word( mins, wmins, charsmax( wmins ) );
        }
        else
        {
            wmins[ 0 ] = EOS;
        }

        if( hrs < 12 )
        {
            wpm = "am ";
        }
        else
        {
            if( hrs > 12 )
            {
                hrs -= 12;
            }

            wpm = "pm ";
        }

        if( hrs )
        {
            num_to_word( hrs, whours, charsmax( whours ) );
        }
        else
        {
            whours = "twelve ";
        }

        client_cmd( id, "spk ^"fvox/time_is_now %s_period %s%s^"", whours, wmins, wpm );
    }

    new ctime[ 64 ];

    get_time( "%m/%d/%Y - %H:%M:%S", ctime, charsmax( ctime ) );
    client_print( 0, print_chat, "%L:   %s", LANG_PLAYER, "THE_TIME", ctime );

    return PLUGIN_CONTINUE;
}

public sayTimeLeft( id )
{
    LOGGER( 128, "I AM ENTERING ON sayTimeLeft(1) id: %d", id )

    switch( whatGameEndingTypeItIs() )
    {
        case GameEndingType_ByMaxRounds:
        {
            sayRoundsLeft( id );
        }
        case GameEndingType_ByWinLimit:
        {
            sayWinLimitLeft( id );
        }
        case GameEndingType_ByFragLimit:
        {
            sayFragsLeft( id );
        }
        case GameEndingType_ByTimeLimit:
        {
            sayTimeLeftOn( id );
        }
        default:
        {
            if( IS_COLORED_CHAT_ENABLED() )
            {
                color_print( 0, "^4%L:^1 %L", LANG_PLAYER, "TIME_LEFT", LANG_PLAYER, "NO_T_LIMIT" );
            }
            else
            {
                client_print( 0, print_chat, "%L: %L", LANG_PLAYER, "TIME_LEFT", LANG_PLAYER, "NO_T_LIMIT" );
            }
        }
    }

    return PLUGIN_CONTINUE;
}

stock sayRoundsLeft( id )
{
    LOGGER( 128, "I AM ENTERING ON sayRoundsLeft(1) id: %d", id )
    new roundsLeft = get_pcvar_num( cvar_mp_maxrounds ) - g_totalRoundsPlayed;

    if( get_pcvar_num( g_amx_time_voice ) )
    {
        speakRemainingInterger( id, roundsLeft );
    }

    if( IS_COLORED_CHAT_ENABLED() )
    {
        color_print( 0, "^4%L:^1 %d %L", LANG_PLAYER, "TIME_LEFT", roundsLeft, LANG_PLAYER, "GAL_OPTION_NAME_ROUND" );
    }
    else
    {
        client_print( 0, print_chat, "%L: %d %L", LANG_PLAYER, "TIME_LEFT", roundsLeft, LANG_PLAYER, "GAL_OPTION_NAME_ROUND" );
    }
}

stock sayWinLimitLeft( id )
{
    LOGGER( 128, "I AM ENTERING ON sayWinLimitLeft(1) id: %d", id )
    new winLeft = get_pcvar_num( cvar_mp_winlimit ) - max( g_totalCtWins, g_totalTerroristsWins );

    if( get_pcvar_num( g_amx_time_voice ) )
    {
        speakRemainingInterger( id, winLeft );
    }

    if( IS_COLORED_CHAT_ENABLED() )
    {
        color_print( 0, "^4%L:^1 %d %L", LANG_PLAYER, "TIME_LEFT", winLeft, LANG_PLAYER, "GAL_OPTION_NAME_ROUND" );
    }
    else
    {
        client_print( 0, print_chat, "%L: %d %L", LANG_PLAYER, "TIME_LEFT", winLeft, LANG_PLAYER, "GAL_OPTION_NAME_ROUND" );
    }
}

stock sayFragsLeft( id )
{
    LOGGER( 128, "I AM ENTERING ON sayFragsLeft(1) id: %d", id )
    new fragsLeft = get_pcvar_num( cvar_mp_fraglimit ) - g_greatestKillerFrags;

    if( get_pcvar_num( g_amx_time_voice ) )
    {
        speakRemainingInterger( id, fragsLeft );
    }

    if( IS_COLORED_CHAT_ENABLED() )
    {
        color_print( 0, "^4%L:^1 %d %L", LANG_PLAYER, "TIME_LEFT", fragsLeft, LANG_PLAYER, "GAL_OPTION_NAME_FRAGS" );
    }
    else
    {
        client_print( 0, print_chat, "%L: %d %L", LANG_PLAYER, "TIME_LEFT", fragsLeft, LANG_PLAYER, "GAL_OPTION_NAME_FRAGS" );
    }
}

stock sayTimeLeftOn( id )
{
    LOGGER( 128, "I AM ENTERING ON sayTimeLeftOn(1) id: %d", id )
    new timeLeft = get_timeleft();

    if( get_pcvar_num( g_amx_time_voice ) )
    {
        new speakText[ MAX_COLOR_MESSAGE ];

        setTimeVoice( speakText, charsmax( speakText ), 0, timeLeft );
        client_cmd( id, "%s", speakText );
    }

    if( IS_COLORED_CHAT_ENABLED() )
    {
        color_print( 0, "^4%L:^1 %d:%02d %L", LANG_PLAYER, "TIME_LEFT", ( timeLeft / 60 ), ( timeLeft % 60 ), LANG_PLAYER, "MINUTES" );
    }
    else
    {
        client_print( 0, print_chat, "%L: %d:%02d %L", LANG_PLAYER, "TIME_LEFT", ( timeLeft / 60 ), ( timeLeft % 60 ), LANG_PLAYER, "MINUTES" );
    }
}

stock speakRemainingInterger( id, integer )
{
    LOGGER( 128, "I AM ENTERING ON speakRemainingInterger(2) id: %d, integer: %d", id, integer )
    new speakText[ MAX_COLOR_MESSAGE ];

    num_to_word( integer, speakText, charsmax( speakText ) );
    client_cmd( id, "spk ^"vox/%s remaining^"", speakText );
}

stock setTimeText( text[], len, tmlf, id )
{
    LOGGER( 128, "I AM ENTERING ON setTimeText(4) text: %s, len: %d, tmlf: %d, id: %d", text, len, tmlf, id )

    new secs = tmlf % 60;
    new mins = tmlf / 60;

    if( secs == 0 )
    {
        formatex( text, len, "%d %L", mins, id, ( mins > 1 ) ? "MINUTES" : "MINUTE" );
    }
    else if( mins == 0 )
    {
        formatex( text, len, "%d %L", secs, id, ( secs > 1 ) ? "SECONDS" : "SECOND" );
    }
    else
    {
        formatex( text, len, "%d %L %d %L", mins, id, ( mins > 1 ) ? "MINUTES" : "MINUTE", secs, id, ( secs > 1 ) ? "SECONDS" : "SECOND" );
    }
}

stock setTimeVoice( text[], len, flags, tmlf )
{
    LOGGER( 128, "I AM ENTERING ON setTimeVoice(4) text: %s, len: %d, flags: %d, tmlf: %d", text, len, flags, tmlf )

    new temp[ 7 ][ 32 ];
    new secs = tmlf % 60;
    new mins = tmlf / 60;

    // for (new a = 0;a < 7;++a) // we just created it, already null
    // temp[a][0] = 0

    if( secs > 0 )
    {
        num_to_word( secs, temp[ 4 ], charsmax( temp[] ) );

        if( ~flags & TD_NO_HOURS_MINS_SECS_VOICE )
        {
            /* there is no "second" in default hl */
            temp[ 5 ] = "seconds ";
        }
    }

    if( mins > 59 )
    {
        new hours = mins / 60;

        num_to_word( hours, temp[ 0 ], charsmax( temp[] ) );

        if( ~flags & TD_NO_HOURS_MINS_SECS_VOICE )
        {
            temp[ 1 ] = "hours ";
        }

        mins = mins % 60;
    }

    if( mins > 0 )
    {
        num_to_word( mins, temp[ 2 ], charsmax( temp[] ) );

        if( ~flags & TD_NO_HOURS_MINS_SECS_VOICE )
        {
            temp[ 3 ] = "minutes ";
        }
    }

    if( ~flags & TD_NO_REMAINING_VOICE )
    {
        temp[ 6 ] = "remaining ";
    }

    return formatex( text, len, "spk ^"vox/%s%s%s%s%s%s%s^"", temp[ 0 ], temp[ 1 ], temp[ 2 ], temp[ 3 ], temp[ 4 ], temp[ 5 ], temp[ 6 ] );
}

stock findDispFormat( _time )
{
    LOGGER( 256, "I AM ENTERING ON findDispFormat(1) _time: %d", _time )

    // For the map to change, because somehow the game time left returned by the engine is sometimes
    // a littler bigger as 10 seconds, than the correct time left returned by get_timeleft(0).
    if( _time == 1 )
    {
        set_task( 1.2, "changeMapIntermission", TASKID_PROCESS_LAST_ROUNDCHANGE );
    }

    // it is important to check i<sizeof BEFORE g_TimeSet[i][0] to prevent out of bound error
    for( new i = 0; i < sizeof( g_TimeSet ) && g_TimeSet[ i ][ 0 ]; ++i )
    {
        if( g_TimeSet[ i ][ 1 ] & TD_SHOW_SPEAK_VALUES_BELOW )
        {
            if( g_TimeSet[ i ][ 0 ] > _time )
            {
                if( !g_Switch )
                {
                    g_CountDown = g_Switch = _time;

                    remove_task( TASK_TIMEREMAIN_SHORT );
                    set_task( 1.0, "timeRemain", TASK_TIMEREMAIN_LARGE, "", 0, "b" );
                }

                return i;
            }
        }
        else if( g_TimeSet[ i ][ 0 ] == _time )
        {
            return i;
        }
    }

    return -1;
}

public setDisplaying()
{
    LOGGER( 128, "I AM ENTERING ON setDisplaying(0)" )

    new arg  [ 32 ];
    new num  [ 32 ];
    new flags[ 32 ];

    new argc = read_argc() - 1;
    new i    = 0;

    while( i < argc && i < sizeof( g_TimeSet ) )
    {
        read_argv( i + 1, arg, charsmax( arg ) );
        parse( arg, flags, charsmax( flags ), num, charsmax( num ) );

        g_TimeSet[ i ][ 0 ] = str_to_num( num );
        g_TimeSet[ i ][ 1 ] = read_flags( flags );

        i++;
    }

    if( i < sizeof( g_TimeSet ) )
    {
        // has to be zeroed in case command is sent twice
        g_TimeSet[ i ][ 0 ] = 0;
    }

    return PLUGIN_HANDLED;
}

public timeRemain()
{
    LOGGER( 256, "I AM ENTERING ON timeRemain(0)")

    new gmtm = get_timeleft();
    new tmlf = g_Switch ? --g_CountDown : gmtm;
    new stimel[ 12 ];

    formatex( stimel, charsmax( stimel ), "%02d:%02d", gmtm / 60, gmtm % 60 );
    set_pcvar_string( g_amx_timeleft, stimel );

    if( g_Switch && gmtm > g_Switch )
    {
        remove_task( TASK_TIMEREMAIN_LARGE );
        g_Switch = 0;
        set_task( 0.8, "timeRemain", TASK_TIMEREMAIN_SHORT, _, _, "b" );

        return;
    }

    if( tmlf > 0 && g_LastTime != tmlf )
    {
        g_LastTime = tmlf;
        new tm_set = findDispFormat( tmlf );

        if( tm_set != -1 )
        {
            new flags = g_TimeSet[ tm_set ][ 1 ];
            new arg[ 128 ];

            if( flags & TD_BOTTOM_WHITE_TEXT )
            {
                new players[ MAX_PLAYERS ], pnum, plr;

                get_players( players, pnum, "c" );

                // yes this is correct flag, just because message should be shorter if it is shown every seconds
                if( flags & TD_SHOW_SPEAK_VALUES_BELOW )
                {
                    set_hudmessage( 255, 255, 255, -1.0, 0.85, 0, 0.0, 1.1, 0.1, 0.5, -1 );
                }
                else
                {
                    set_hudmessage( 255, 255, 255, -1.0, 0.85, 0, 0.0, 3.0, 0.0, 0.5, -1 );
                }

                for( new i = 0; i < pnum; i++ )
                {
                    plr = players[ i ];
                    setTimeText( arg, charsmax( arg ), tmlf, plr );
                    show_hudmessage( plr, "%s", arg );
                }
            }

            if( flags & TD_USE_VOICE )
            {
                setTimeVoice( arg, charsmax( arg ), flags, tmlf );
                client_cmd( 0, "%s", arg );
            }
        }
    }
}



// ################################## BELOW HERE ONLY GOES DEBUG/TEST CODE ###################################
#if DEBUG_LEVEL & DEBUG_LEVEL_FAKE_VOTES
    public create_fakeVotes()
    {
        LOGGER( 128, "I AM ENTERING ON create_fakeVotes(0)" )
        writeToTheDebugFile( DEBUGGER_OUTPUT_LOG_FILE_NAME, "Creating fake votes..." );

        if( g_voteStatus & IS_RUNOFF_VOTE )
        {
            g_arrayOfMapsWithVotesNumber[ 0 ] += 2;     // choice 1
            g_arrayOfMapsWithVotesNumber[ 1 ] += 2;     // choice 2

            g_totalVotesCounted = g_arrayOfMapsWithVotesNumber[ 0 ] + g_arrayOfMapsWithVotesNumber[ 1 ];
        }
        else
        {
            g_arrayOfMapsWithVotesNumber[ 0 ] += 0;     // map 1
            g_arrayOfMapsWithVotesNumber[ 1 ] += 2;     // map 2
            g_arrayOfMapsWithVotesNumber[ 2 ] += 2;     // map 3
            g_arrayOfMapsWithVotesNumber[ 3 ] += 2;     // map 4
            g_arrayOfMapsWithVotesNumber[ 4 ] += 0;     // map 5

            if( g_isExtendmapAllowStay
                || g_isGameFinalVoting )
            {
                g_arrayOfMapsWithVotesNumber[ 5 ] += 0;    // extend option
            }

            g_totalVotesCounted = g_arrayOfMapsWithVotesNumber[ 0 ] + g_arrayOfMapsWithVotesNumber[ 1 ] +
                                  g_arrayOfMapsWithVotesNumber[ 2 ] + g_arrayOfMapsWithVotesNumber[ 3 ] +
                                  g_arrayOfMapsWithVotesNumber[ 4 ] + g_arrayOfMapsWithVotesNumber[ 5 ];
        }
    }
#endif



// The Unit Tests execution
#if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED )
    stock configureTheUnitTests()
    {
        LOGGER( 128, "I AM ENTERING ON configureTheUnitTests(0)" )

        register_clcmd( "say run", "inGameTestsToExecute", -1 );
        register_clcmd( "say_team run", "inGameTestsToExecute", -1 );

        register_concmd( "run", "inGameTestsToExecute" );
        register_concmd( "runall", "runTests" );

        register_clcmd( "say runall", "runTests", -1 );
        register_clcmd( "say_team runall", "runTests", -1 );

        g_test_failureIdsTrie      = TrieCreate();
        g_test_strictValidMapsTrie = TrieCreate();

        g_test_failureIdsArray     = ArrayCreate( 1 );
        g_test_failureReasonsArray = ArrayCreate( MAX_LONG_STRING );
        g_test_idsAndNamesArray    = ArrayCreate( MAX_SHORT_STRING );

        // delay needed to wait the 'server.cfg' run to load its saved cvars
        if( !( get_pcvar_num( cvar_serverStartAction )
               && get_pcvar_num( cvar_isFirstServerStart ) == FIRST_SERVER_START ) )
        {
            set_task( 2.0, "runTests" );
        }
        else
        {
            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "    The Unit Tests are going to run only after the first server start." );
            print_logger( "    gal_server_starting: %d", get_pcvar_num( cvar_isFirstServerStart ) );
            print_logger( "" );
            print_logger( "" );
        }
    }

    /**
     * Compute how many days are elapsed since 1st January of 2000.
     *
     * @param currentDayInteger     the current day from this year (1-366).
     * @param currentYearInteger    the current year (2016).
     */
    #define GET_CURRENT_BASED_DAY(%1,%2) ( ( %2 - 2000 ) * 366 + %1 )

    /**
     * Calculates how much time took to run the Unit Tests. For this to work, the stock
     * 'saveCurrentTestsTimeStamp(0)' must to be called on the beginning of the tests.
     *
     * @return seconds        how much seconds are elapsed, or -1 on when the time-stamp is null.
     */
    stock computeTheTestElapsedTime()
    {
        if( g_test_lastTimeStamp )
        {
            new hour;
            new minute;
            new second;
            new delayResulted;

            time( hour, minute, second );

            new currentDayInteger;
            new currentYearInteger;
            new rawTimeData[ 10 ];

            get_time("%j", rawTimeData, charsmax( rawTimeData ) );
            currentDayInteger  = str_to_num( rawTimeData );

            get_time("%Y", rawTimeData, charsmax( rawTimeData ) );
            currentYearInteger = str_to_num( rawTimeData );

            delayResulted     = hour * 3600 + minute * 60 + second - g_test_lastTimeStamp + 1;
            currentDayInteger = GET_CURRENT_BASED_DAY( currentDayInteger, currentYearInteger );

            if( g_test_startDayInteger != currentDayInteger )
            {
                // end  - start = delay
                // 1:59 - 1:55  =   4
                // 2:05 - 1:59  = -54 plus + 1 * 60 =  6 seconds (correct)
                // 3:05 - 1:59  = -54 plus + 2 * 60 = 66 seconds (correct)
                return delayResulted + ( currentDayInteger - g_test_startDayInteger ) * 86400;
            }

            return delayResulted;
        }

        return -1;
    }

    /**
     * Save a time-stamp when the Unit Tests started to run.
     */
    stock saveCurrentTestsTimeStamp()
    {
        if( !g_test_lastTimeStamp )
        {
            new hour;
            new minute;
            new second;

            time( hour, minute, second );

            new currentDayInteger;
            new currentYearInteger;
            new rawTimeData[ 10 ];

            get_time("%j", rawTimeData, charsmax( rawTimeData ) );
            currentDayInteger  = str_to_num( rawTimeData );

            get_time("%Y", rawTimeData, charsmax( rawTimeData ) );
            currentYearInteger = str_to_num( rawTimeData );

            g_test_lastTimeStamp   = hour * 3600 + minute * 60 + second;
            g_test_startDayInteger = GET_CURRENT_BASED_DAY( currentDayInteger, currentYearInteger );
        }
    }

    /**
     * Clean old Unit Tests execution run data.
     */
    stock cleanTheUnitTestsData()
    {
        g_test_testsNumber        = 0;
        g_test_failureNumber      = 0;
        g_test_maxDelayResult     = 0;
        g_test_lastMaxDelayResult = 0;
        g_test_aimedPlayersNumber = 0;
        g_test_gameElapsedTime    = 0;

        ArrayClear( g_test_idsAndNamesArray );
        ArrayClear( g_test_failureIdsArray );
        ArrayClear( g_test_failureReasonsArray );
        TrieClear( g_test_failureIdsTrie );
    }

    /**
     * This function run all tests that are listed at it. Every test that is created must to be called
     * here to register itself at the Test System and perform the testing.
     */
    public runTests()
    {
        LOGGER( 128, "I AM ENTERING ON runTests(0)" )
        saveCurrentTestsTimeStamp();

    #if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_UNIT_TEST_DELAYED )
        saveServerCvarsForTesting();
    #endif

        // Run the normal tests.
    #if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST_NORMAL
        normalTestsToExecute();
    #endif

        // Run the delayed tests.
    #if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST_DELAYED
        g_test_maxDelayResult       = 1;
        g_lastNormalTestToExecuteId = g_test_testsNumber;

        set_task( 0.5, "dalayedTestsToExecute" );
    #endif

        // Run the manual tests.
    #if DEBUG_LEVEL & DEBUG_LEVEL_MANUAL_TEST_START && !( DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_UNIT_TEST_DELAYED ) )
        print_logger( "" );
        print_logger( "" );
        print_logger( "" );
        inGameTestsToExecute( 0 );
    #endif

        // displays the OK to the last test.
    #if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST_NORMAL
        displaysLastTestOk();
    #endif

        if( g_test_maxDelayResult )
        {
        #if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST_NORMAL
            print_all_tests_executed();
            print_tests_failure();

            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "    After '%d' runtime seconds... Executing the %s's Unit Tests delayed until at least %d seconds: ",
                                     computeTheTestElapsedTime(),          PLUGIN_NAME,          g_test_maxDelayResult );
            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
        #endif
            g_test_lastMaxDelayResult = g_test_maxDelayResult;
            set_task( g_test_maxDelayResult + 1.0, "show_delayed_results" );
        }
        else
        {
        #if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST_NORMAL
            printTheUnitTestsResults();
        #endif
        }
    }

    stock print_tests_results_count()
    {
        print_logger( "" );
        print_logger( "    Finished the %s's Unit Tests execution after '%d' seconds.", PLUGIN_NAME, computeTheTestElapsedTime() );
        print_logger( "" );
        print_logger( "" );

        // Clear the time-stamp.
        g_test_lastTimeStamp = 0;
    }

    /**
     * This is executed at the end of the delayed tests execution to show its results and restore any
     * cvars variable change.
     */
    public show_delayed_results()
    {
        LOGGER( 128, "I AM ENTERING ON show_delayed_results(0)" )
        new nextCheckTime = g_test_maxDelayResult - g_test_lastMaxDelayResult;

        // All delayed tests finished.
        if( nextCheckTime < 1 )
        {
            displaysLastTestOk();
            printTheUnitTestsResults();
        }
        else
        {
            // There are new tests waiting to be performed, then reschedule a new result output.
            g_test_lastMaxDelayResult = g_test_maxDelayResult;
            set_task( nextCheckTime + 1.0, "show_delayed_results" );
        }
    }

    stock printTheUnitTestsResults()
    {
    #if DEBUG_LEVEL & DEBUG_LEVEL_MANUAL_TEST_START
        displaysLastTestOk();
    #endif

        // clean the testing
        print_logger( "" );
        print_logger( "" );
        print_logger( "" );
        print_logger( "" );
        print_logger( "" );
        print_logger( "Cleaning the tests configurations..." );
        restoreServerCvarsFromTesting();

        print_all_tests_executed();
        print_tests_failure();
        print_tests_results_count();
    }

    stock displaysLastTestOk()
    {
        if( g_test_testsNumber > 0 )
        {
            new lastTestId       = ( g_test_testsNumber );
            new numberOfFailures = ArraySize( g_test_failureIdsArray );
            new lastFailure      = ( numberOfFailures ? ArrayGetCell( g_test_failureIdsArray, numberOfFailures - 1 ) : 0 );

            LOGGER( 1, "( displaysLastTestOk ) numberOfFailures: %d, lastFailure: %d, lastTestId: %d", \
                    numberOfFailures, lastFailure, lastTestId )

            if( !numberOfFailures
                || lastFailure != lastTestId )
            {
                print_logger( "OK!" );
                print_logger( "" );
                print_logger( "" );
            }
            else if( lastFailure == lastTestId  )
            {
                print_logger( "FAILED!" );
                print_logger( "" );
                print_logger( "" );
                print_logger( "" );

                // Blocks the delayed Unit Tests to run, because the chain is broke.
                return false;
            }
        }

        return true;
    }

    stock print_all_tests_executed()
    {
        LOGGER( 128, "I AM ENTERING ON print_all_tests_executed(0)" )

        new trieKey[ 10 ];
        new test_name[ MAX_SHORT_STRING ];
        new testsNumber = ArraySize( g_test_idsAndNamesArray );

        print_logger( "" );
        print_logger( "" );
        print_logger( "" );
        print_logger( "    The following tests were successfully executed: " );
        print_logger( "" );

        for( new test_index = 0; test_index < testsNumber; test_index++ )
        {
            num_to_str( test_index + 1, trieKey, charsmax( trieKey ) );

            if( !TrieKeyExists( g_test_failureIdsTrie, trieKey ) )
            {
                ArrayGetString( g_test_idsAndNamesArray, test_index, test_name, charsmax( test_name ) );
                print_logger( "       %3d. %s", test_index + 1, test_name );
            }
        }
    }

    stock print_tests_failure()
    {
        LOGGER( 256, "I AM ENTERING ON print_tests_failure(0)" )

        new test_id;
        new test_name[ MAX_SHORT_STRING ];
        new failure_reason[ MAX_LONG_STRING ];

        new failureTestsNumber = ArraySize( g_test_failureIdsArray );

        if( failureTestsNumber )
        {
            print_logger( "" );
            print_logger( "" );
            print_logger( "    The following %s's Unit Tests failed: ", PLUGIN_NAME );
            print_logger( "" );

            for( new failure_index = 0; failure_index < failureTestsNumber; failure_index++ )
            {
                test_id = ArrayGetCell( g_test_failureIdsArray, failure_index );

                ArrayGetString( g_test_idsAndNamesArray, test_id - 1, test_name, charsmax( test_name ) );
                ArrayGetString( g_test_failureReasonsArray, failure_index, failure_reason, charsmax( failure_reason ) );

                print_logger( "       %3d. %s: %s", test_id, test_name, failure_reason );
            }
        }

        print_logger( "" );
        print_logger( "    %d tests succeed.", g_test_testsNumber - g_test_failureNumber );
        print_logger( "    %d tests failed.", g_test_failureNumber );
    }

    /**
     * Informs the Test System that the test failed and why.
     *
     * @param test_id              the test_id at the Test System
     * @param isFailure            a boolean value setting whether the failure status is true.
     * @param failure_reason       the reason why the test failed
     */
    stock setTestFailure( test_id, bool:isFailure, failure_reason[] )
    {
        LOGGER( 256, "I AM ENTERING ON setTestFailure(...) test_id: %d, isFailure: %d, \
                failure_reason: %s", test_id, isFailure, failure_reason )

        new trieKey[ 10 ];
        num_to_str( test_id, trieKey, charsmax( trieKey ) );

        if( isFailure
            && !TrieKeyExists( g_test_failureIdsTrie, trieKey ) )
        {
            g_test_failureNumber++;

            ArrayPushCell( g_test_failureIdsArray, test_id );
            TrieSetCell( g_test_failureIdsTrie, trieKey, 0 );

            ArrayPushString( g_test_failureReasonsArray, failure_reason );
            print_logger( "       TEST FAILURE! %s", failure_reason );

            return true;
        }

        return false;
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
        LOGGER( 256, "I AM ENTERING ON register_test(2) max_delay_result: %d, test_name: %s", max_delay_result, test_name )
        ArrayPushString( g_test_idsAndNamesArray, test_name );

        // All the normal Unit Tests will be finished when the Delayed Unit Test begin. This is used
        // to not show a OK, after to print the Normal Unit Tests Results.
        if( g_lastNormalTestToExecuteId != g_test_testsNumber )
        {
            displaysLastTestOk();
        }

        g_test_testsNumber++;
        print_logger( "        EXECUTING TEST %d AFTER %d WITH UNTIL %d SECONDS DELAYED - %s ",
                g_test_testsNumber, computeTheTestElapsedTime(), max_delay_result, test_name );

        if( g_test_maxDelayResult < max_delay_result )
        {
            g_test_maxDelayResult = max_delay_result;
        }

        return g_test_testsNumber;
    }

    /**
     * Register a test series naming, used to easily allow to distinguish between tests names.
     * Example, this:
     * 1. test_loadVoteChoices.aa_case1
     * 2. test_loadVoteChoices.aa_case2
     * 3. test_loadVoteChoices.bb.bb_case1
     * 4. test_loadVoteChoices.bb.bb_case2
     *
     * Instead of this:
     * 1. test_loadVoteChoices.a_case1
     * 2. test_loadVoteChoices.a_case2
     * 3. test_loadVoteChoices.b_case1
     * 4. test_loadVoteChoices.b_case2
     *
     * @param seriesName       the current test name.
     * @param newSeries        a char as the new test series start. The default is to use the last serie.
     */
    stock test_registerSeriesNaming( seriesName[], newSeries = 0 )
    {
        new currentIndex;
        new testName[ MAX_SHORT_STRING ];

        static indentation;
        static currentSerie;
        static currentCaseNumber;
        static intentationLevel[ MAX_SHORT_STRING ];

        currentCaseNumber++;

        if( newSeries
            && newSeries != currentSerie )
        {
            currentSerie      = newSeries;
            indentation       = ( ( currentSerie - 'a' + 1 ) * 3 ) % 15;
            currentCaseNumber = 1;

            for( currentIndex = 0; currentIndex < indentation; ++currentIndex )
            {
                if( currentIndex % 3 == 0 )
                {
                    intentationLevel[ currentIndex ] = '.';
                }
                else
                {
                    intentationLevel[ currentIndex ] = currentSerie;
                }
            }

            intentationLevel[ currentIndex ] = '^0';
        }

        formatex( testName, charsmax( testName ), "%s%s_case%d", seriesName, intentationLevel, currentCaseNumber );
        return register_test( 0, testName );
    }

    /**
     * When the global variable `g_test_isToUseStrictValidMaps` is set to, this looks for maps as being
     * valid from the global Trie `g_test_strictValidMapsTrie`.
     *
     * This is useful to create any map environment you want to perform the Unit Testing. See the
     * function helper_loadStrictValidMapsTrie() to load the global Trie `g_test_strictValidMapsTrie`
     * with the maps you want to be valid.
     */
    stock isAllowedValidMapByTheUnitTests( mapName[] )
    {
        if( g_test_isToUseStrictValidMaps )
        {
            return TrieKeyExists( g_test_strictValidMapsTrie, mapName );
        }

        return g_test_isTheUnitTestsRunning;
    }




    // Here below to start the manual Unit Tests
    // ###########################################################################################

    /**
     * Load the specified nominations into the system.
     *
     * @param nominations      the variable number of maps nominations.
     */
    stock helper_loadNominations( ... )
    {
        new stringIndex;
        new argumentsNumber;
        new currentMap[ MAX_MAPNAME_LENGHT ];

        static playerId    = 1;
        static optionIndex = 0;

        argumentsNumber = numargs();

        // To load the maps passed as arguments
        for( new currentIndex = 0; currentIndex < argumentsNumber; ++currentIndex )
        {
            stringIndex = 0;

            if( playerId > MAX_PLAYERS )
            {
                playerId = 1;
                ++optionIndex;

                if( optionIndex > 2 )
                {
                    optionIndex = 0;
                }
            }

            while( ( currentMap[ stringIndex ] = getarg( currentIndex, stringIndex++ ) ) )
            {
            }

            currentMap[ stringIndex ] = '^0';
            ArrayPushString( g_nominationLoadedMapsArray, currentMap );

            setPlayerNominationMapIndex( playerId++, optionIndex, currentIndex );
        }
    }

    /**
     * To create a map file list on the specified file path on the disk.
     *
     * @param replace              true if is to replace `[` `]` by `{` `}`, false if not.
     * @param mapFileListPath      the path to the mapFileList.
     * @param mapFileList          the variable number of maps.
     */
    stock helper_mapFileListLoad( bool:replace, mapFileListPath[], ... )
    {
        new stringIndex;
        new currentIndex;
        new fileDescriptor;
        new currentMap[ MAX_MAPNAME_LENGHT ];

        delete_file( mapFileListPath );
        fileDescriptor = fopen( mapFileListPath, "wt" );

        if( fileDescriptor )
        {
            new argumentsNumber = numargs();

            // To load the maps passed as arguments
            for( currentIndex = 2; currentIndex < argumentsNumber; ++currentIndex )
            {
                stringIndex = 0;

                while( ( currentMap[ stringIndex ] = getarg( currentIndex, stringIndex++ ) ) )
                {
                }

                currentMap[ stringIndex ] = '^0';

                if( replace )
                {
                    replace_all( currentMap, charsmax( currentMap ), "[", "{" );
                    replace_all( currentMap, charsmax( currentMap ), "]", "{" );
                }

                fprintf( fileDescriptor, "%s^n", currentMap );
            }

            fclose( fileDescriptor );
        }
    }

    /**
     * To clean and load the global `g_test_strictValidMapsTrie` within the passed maps as arguments.
     *
     * @param mapFileList          the variable number of maps.
     */
    stock helper_loadStrictValidMapsTrie( ... )
    {
        new stringIndex;
        new currentIndex;
        new currentMap[ MAX_MAPNAME_LENGHT ];

        new argumentsNumber = numargs();
        TRY_TO_APPLY( TrieClear, g_test_strictValidMapsTrie )

        // To load the maps passed as arguments
        for( currentIndex = 0; currentIndex < argumentsNumber; ++currentIndex )
        {
            stringIndex = 0;

            while( ( currentMap[ stringIndex ] = getarg( currentIndex, stringIndex++ ) ) )
            {
            }

            currentMap[ stringIndex ] = '^0';
            TrieSetCell( g_test_strictValidMapsTrie, currentMap, currentIndex );
        }
    }

    /**
     * To clear the normal game nominations.
     */
    stock helper_clearNominationsData()
    {
        set_pcvar_num( cvar_nomCleaning, 1 );

        clearTheVotingMenu();
        nomination_clearAll();

        // Clear the nominations file loaded maps
        ArrayClear( g_nominationLoadedMapsArray );
    }

    /**
     * Load the specified nominations into a specific player.
     *
     * @param player_id        the player id to receive the nominations.
     * @param nominations      the variable number of maps nominations.
     */
    stock helper_unnominated_nomsLoad( player_id, ... )
    {
        new stringIndex;
        new argumentsNumber;
        new currentMap[ MAX_MAPNAME_LENGHT ];

        argumentsNumber = numargs() - 1;

        // To load the maps passed as arguments
        for( new currentIndex = 0; currentIndex < argumentsNumber; ++currentIndex )
        {
            stringIndex = 0;

            while( ( currentMap[ stringIndex ] = getarg( currentIndex + 1, stringIndex++ ) ) )
            {
            }

            currentMap[ stringIndex ] = '^0';
            ArrayPushString( g_nominationLoadedMapsArray, currentMap );

            if( currentIndex < MAX_OPTIONS_IN_VOTE )
            {
                setPlayerNominationMapIndex( player_id, currentIndex, currentIndex );
            }
        }
    }




    // Here below to start the Delayed Unit Tests code
    //
    // This is the 'vote_startDirector(1)' tests chain beginning. Because the 'vote_startDirector(1)' cannot
    // to be tested simultaneously. Then, all tests that involves the 'vote_startDirector(1)' chain, must
    // to be executed sequentially after this chain end. This is the 1º chain test.
    // ###########################################################################################

    /**
     * 1. Tests if the cvar 'amx_extendmap_max' functionality is working properly for a successful case.
     */
    stock test_isMapExtensionAvowed_case1()
    {
        new errorMessage[ MAX_LONG_STRING ];

        // Temporarily disables the `gal_nextmap_votemap` feature, as we are not testing it right now.
        set_pcvar_num( cvar_nextMapChangeVotemap, 0 );

        new chainDelay = 2 + 2 + 1 + 1 + 1;
        new test_id    = register_test( chainDelay, "test_isMapExtensionAvowed_case1" );

        set_pcvar_float( cvar_maxMapExtendTime, 20.0 );
        tryToSetGameModCvarFloat( cvar_mp_timelimit, 10.0 );

        g_endVotingType |= IS_BY_TIMER;
        vote_startDirector( false );

        formatex( errorMessage, charsmax( errorMessage ), "g_isMapExtensionAllowed must be 1 (it was %d)", g_isMapExtensionAllowed );
        SET_TEST_FAILURE( test_id, !g_isMapExtensionAllowed, errorMessage )

        set_task( 2.0, "test_isMapExtensionAvowed_case2", chainDelay );
    }

    /**
     * 2. Tests if the cvar 'amx_extendmap_max' functionality is working properly for a failure case.
     */
    public test_isMapExtensionAvowed_case2( chainDelay )
    {
        new test_id;
        new errorMessage[ MAX_LONG_STRING ];

        test_id = register_test( chainDelay, "test_isMapExtensionAvowed_case2" );

        formatex( errorMessage, charsmax( errorMessage ), "g_isMapExtensionAllowed must be 1 (it was %d)", g_isMapExtensionAllowed );
        SET_TEST_FAILURE( test_id, !g_isMapExtensionAllowed, errorMessage )

        color_print( 0, "%L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED2" );
        cancelVoting();

        // Case 3
        test_id = register_test( chainDelay, "test_isMapExtensionAvowed_case3" );

        set_pcvar_float( cvar_maxMapExtendTime, 10.0 );
        tryToSetGameModCvarFloat( cvar_mp_timelimit, 20.0 );

        g_endVotingType |= IS_BY_TIMER;
        vote_startDirector( false );

        formatex( errorMessage, charsmax( errorMessage ), "g_isMapExtensionAllowed must be 0 (it was %d)", g_isMapExtensionAllowed );
        SET_TEST_FAILURE( test_id, g_isMapExtensionAllowed, errorMessage )

        set_task( 2.0, "test_endOfMapVotingStart_case1", chainDelay );
    }

    /**
     * 3. Tests if the end map voting is starting automatically at the end of map due time limit expiration.
     */
    public test_endOfMapVotingStart_case1( chainDelay )
    {
        new test_id;
        new secondsLeft;

        // When the `gal_endofmapvote_start` feature is enabled, will will not allow a votemap
        // by time limit expiration.
        set_pcvar_num( cvar_endOfMapVoteStart, 0 );

        new errorMessage[ MAX_LONG_STRING ];
        test_id = register_test( chainDelay, "test_endOfMapVotingStart_case1" );

        formatex( errorMessage, charsmax( errorMessage ), "g_isMapExtensionAllowed must be 0 (it was %d)", g_isMapExtensionAllowed );
        SET_TEST_FAILURE( test_id, g_isMapExtensionAllowed, errorMessage )

        cancelVoting();
        secondsLeft = get_timeleft();

        tryToSetGameModCvarFloat( cvar_mp_timelimit,
                ( get_pcvar_float( cvar_mp_timelimit ) * 60
                  - secondsLeft
                  + START_VOTEMAP_MAX_TIME + PERIODIC_CHECKING_INTERVAL )
                / 60 );

        LOGGER( 32, "( test_endOfMapVotingStart_case1 ) timelimit: %d", floatround( get_pcvar_float( cvar_mp_timelimit ) * 60 ) )
        LOGGER( 32, "( test_endOfMapVotingStart_case1 ) START_VOTEMAP_MIN_TIME: %d", START_VOTEMAP_MIN_TIME )
        LOGGER( 32, "( test_endOfMapVotingStart_case1 ) START_VOTEMAP_MAX_TIME: %d", START_VOTEMAP_MAX_TIME )

        set_task( 1.0, "test_endOfMapVotingStart_case2", chainDelay );
    }

    /**
     * 4. Tests if the end map voting is starting automatically at the end of map due time limit expiration.
     */
    public test_endOfMapVotingStart_case2( chainDelay )
    {
        new test_id = register_test( chainDelay, "test_endOfMapVotingStart_case2" );

        vote_manageEnd();
        SET_TEST_FAILURE( test_id, !( g_voteStatus & IS_VOTE_IN_PROGRESS ), "vote_startDirector() does not started!" )

        tryToSetGameModCvarFloat( cvar_mp_timelimit, 20.0 );
        cancelVoting();

        set_task( 1.0, "test_endOfMapVotingStop_case1", chainDelay );
    }

    /**
     * 5. Tests if the end map voting is not starting automatically at the end of map due time limit expiration.
     */
    public test_endOfMapVotingStop_case1( chainDelay )
    {
        new test_id = register_test( chainDelay, "test_endOfMapVotingStop_case1" );

        vote_manageEnd();
        SET_TEST_FAILURE( test_id, ( g_voteStatus & IS_VOTE_IN_PROGRESS ) != 0, "vote_startDirector() does started!" )

        tryToSetGameModCvarFloat( cvar_mp_timelimit, 2.0 );
        cancelVoting();

        set_task( 1.0, "test_endOfMapVotingStop_case2", chainDelay );
    }

    /**
     * 6. Tests if the end map voting is not starting automatically at the end of map due time limit expiration.
     */
    public test_endOfMapVotingStop_case2( chainDelay )
    {
        new test_id = register_test( chainDelay, "test_endOfMapVotingStop_case2" );

        vote_manageEnd();
        SET_TEST_FAILURE( test_id, ( g_voteStatus & IS_VOTE_IN_PROGRESS ) != 0, "vote_startDirector() does started!" )

        tryToSetGameModCvarFloat( cvar_mp_timelimit, 20.0 );
        //cancelVoting();

        //set_task( 1.0, "test_exampleModel_case1", chainDelay );
    }

    /**
     * 7. Tests if the ... this is model to create new tests. Duplicate this example code and
     * uncomment the test code body and its caller on the last test chain case just above here.
     * You need also to to go the first test and add to the variable 'chainDelay' how much time
     * this and its consecutive tests will take to execute.
     */
    /*public test_exampleModel_case1( chainDelay )
    {
        new test_id = register_test( chainDelay, "test_exampleModel_case1" );

        // Teste coding here...

        // Clear the voting for a new test to begin.
        // cancelVoting();

        // Call the next chain test.
        set_task( 1.0, "test_exampleModel_case2", chainDelay );
    }*/




    // Place new 'vote_startDirector(1)' chain tests above here.
    // ############################################################################################

    /**
     * This is a simple test to verify the basic registering test functionality.
     */
    stock test_registerTest()
    {
        new test_id;
        new errorMessage   [ MAX_LONG_STRING ];
        new first_test_name[ MAX_SHORT_STRING ];

        test_id = register_test( 0, "test_registerTest" );

        formatex( errorMessage, charsmax( errorMessage ), "g_test_testsNumber must be 1 (it was %d)", g_test_testsNumber );
        SET_TEST_FAILURE( test_id, g_test_testsNumber != 1, errorMessage )

        formatex( errorMessage, charsmax( errorMessage ), "test_id must be 1 (it was %d)", test_id );
        SET_TEST_FAILURE( test_id, test_id != 1, errorMessage )

        ArrayGetString( g_test_idsAndNamesArray, 0, first_test_name, charsmax( first_test_name ) );

        formatex( errorMessage, charsmax( errorMessage ), "first_test_name must be 'test_registerTest' (it was %s)", first_test_name );
        SET_TEST_FAILURE( test_id, !equal( first_test_name, "test_registerTest" ), errorMessage )
    }

    /**
     * Test for client connect cvar_isToStopEmptyCycle behavior.
     */
    stock test_isInEmptyCycle()
    {
        new errorMessage[ MAX_LONG_STRING ];
        new test_id = register_test( 0, "test_isInEmptyCycle" );

        set_pcvar_num( cvar_isToStopEmptyCycle, 1 );
        client_authorized_stock( .player_id = 1  );

        formatex( errorMessage, charsmax( errorMessage ), "cvar_isToStopEmptyCycle must be 0 (it was %d)", get_pcvar_num( cvar_isToStopEmptyCycle ) );
        SET_TEST_FAILURE( test_id, get_pcvar_num( cvar_isToStopEmptyCycle ) != 0, errorMessage )

        set_pcvar_num( cvar_isToStopEmptyCycle, 0 );
        client_authorized_stock( .player_id = 1 );

        formatex( errorMessage, charsmax( errorMessage ), "cvar_isToStopEmptyCycle must be 0 (it was %d)", get_pcvar_num( cvar_isToStopEmptyCycle ) );
        SET_TEST_FAILURE( test_id, get_pcvar_num( cvar_isToStopEmptyCycle ) != 0, errorMessage )
    }

    /**
     * To call the general test handler 'test_mapGetNext_case(4)' using test scenario cases.
     */
    stock test_mapGetNext_cases()
    {
        new Array:testMapListArray = ArrayCreate( MAX_MAPNAME_LENGHT );

        ArrayPushString( testMapListArray, "de_dust2" );
        ArrayPushString( testMapListArray, "de_inferno" );
        ArrayPushString( testMapListArray, "de_dust4" );
        ArrayPushString( testMapListArray, "de_dust" );

        test_mapGetNext_case( testMapListArray, "de_dust", "de_dust2", 0 );      // Case 1
        test_mapGetNext_case( testMapListArray, "de_dust2", "de_inferno", 1 );   // Case 2
        test_mapGetNext_case( testMapListArray, "de_inferno", "de_dust4", 2 );   // Case 3
        test_mapGetNext_case( testMapListArray, "de_inferno2", "de_dust2", -1 ); // Case 4

        ArrayDestroy( testMapListArray );
    }

    /**
     * This is a general test handler for the function 'map_getNext(3)'.
     *
     * @param testMapListArray        an Array with a map-cycle for loading
     * @param currentMap              an string as the current map
     * @param nextMapAim              an string as the desired next map
     * @param mapIndexAim             the desired next map index
     */
    stock test_mapGetNext_case( Array:testMapListArray, currentMap[], nextMapAim[], mapIndexAim )
    {
        static currentCaseNumber = 0;
        currentCaseNumber++;

        new test_id;
        new mapIndex;
        new nextMapName [ MAX_MAPNAME_LENGHT ];
        new testName    [ MAX_SHORT_STRING ];
        new errorMessage[ MAX_LONG_STRING ];

        formatex( testName, charsmax( testName ), "test_mapGetNext_case%d", currentCaseNumber );

        test_id  = register_test( 0, testName );
        mapIndex = map_getNext( testMapListArray, currentMap, nextMapName );

        formatex( errorMessage, charsmax( errorMessage ), "The nextMapName must to be '%s'! But it was %s.", nextMapAim, nextMapName );
        SET_TEST_FAILURE( test_id, !equal( nextMapName, nextMapAim ), errorMessage )

        formatex( errorMessage, charsmax( errorMessage ), "The mapIndex must to be %d! But it was %d.", mapIndexAim, mapIndex );
        SET_TEST_FAILURE( test_id, mapIndex != mapIndexAim, errorMessage )
    }

    /**
     * To call the general test handler 'test_isToLoadBlacklist_case(3)' using test scenario cases.
     */
    stock test_loadNextWhiteListGroupOpen( s, bool:t )
    {
        // To block them (Blacklist), we need   to load them when we are between 23-0 (23:00:00-0:59:59).
        // To allow them (Whitelist), we cannot to load them when we are between 23-0 (23:00:00-0:59:59).
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=23, .startHour=23, .endHour=0  ); // Case 1
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=0 , .startHour=23, .endHour=0  ); // Case 2
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=1 , .startHour=23, .endHour=0  ); // Case 3
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=12, .startHour=23, .endHour=0  ); // Case 4
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=11, .startHour=23, .endHour=0  ); // Case 5
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=13, .startHour=23, .endHour=0  ); // Case 6
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=22, .startHour=23, .endHour=0  ); // Case 7

        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=0 , .startHour=1 , .endHour=23 ); // Case 8
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=1 , .startHour=1 , .endHour=23 ); // Case 9
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=2 , .startHour=1 , .endHour=23 ); // Case 10
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=12, .startHour=1 , .endHour=23 ); // Case 11
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=22, .startHour=1 , .endHour=23 ); // Case 12
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=23, .startHour=1 , .endHour=23 ); // Case 13

        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=12, .startHour=12, .endHour=22 ); // Case 14
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=13, .startHour=12, .endHour=22 ); // Case 15
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=17, .startHour=12, .endHour=22 ); // Case 16
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=22, .startHour=12, .endHour=22 ); // Case 17
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=11, .startHour=12, .endHour=22 ); // Case 18
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=5 , .startHour=12, .endHour=22 ); // Case 19
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=9 , .startHour=12, .endHour=22 ); // Case 20
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=23, .startHour=12, .endHour=22 ); // Case 21
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=0 , .startHour=12, .endHour=22 ); // Case 22

        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=23, .startHour=23, .endHour=5  ); // Case 23
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=0 , .startHour=23, .endHour=5  ); // Case 24
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=1 , .startHour=23, .endHour=5  ); // Case 25
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=2 , .startHour=23, .endHour=5  ); // Case 26
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=4 , .startHour=23, .endHour=5  ); // Case 27
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=5 , .startHour=23, .endHour=5  ); // Case 28
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=22, .startHour=23, .endHour=5  ); // Case 29
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=21, .startHour=23, .endHour=5  ); // Case 30
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=6 , .startHour=23, .endHour=5  ); // Case 31
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=7 , .startHour=23, .endHour=5  ); // Case 32
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=7 , .startHour=23, .endHour=5  ); // Case 33
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=12, .startHour=23, .endHour=5  ); // Case 34

        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=4 , .startHour=5 , .endHour=3  ); // Case 35
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=5 , .startHour=5 , .endHour=3  ); // Case 36
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=6 , .startHour=5 , .endHour=3  ); // Case 37
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=15, .startHour=5 , .endHour=3  ); // Case 38
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=3 , .startHour=5 , .endHour=3  ); // Case 39
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=2 , .startHour=5 , .endHour=3  ); // Case 40

        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=0 , .startHour=0 , .endHour=0  ); // Case 41
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=1 , .startHour=0 , .endHour=0  ); // Case 42
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=2 , .startHour=0 , .endHour=0  ); // Case 43
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=23, .startHour=0 , .endHour=0  ); // Case 44
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=22, .startHour=0 , .endHour=0  ); // Case 45
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=true , .currentHour=12, .startHour=0 , .endHour=0  ); // Case 46

        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=0 , .startHour=0 , .endHour=23 ); // Case 47
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=23, .startHour=0 , .endHour=23 ); // Case 48
        test_isToLoadBlacklist_case( s, t, false, .isToLoad=false, .currentHour=12, .startHour=0 , .endHour=23 ); // Case 49
    }

    /**
     * To call the general test handler 'test_isToLoadBlacklist_case(3)' using test scenario cases.
     */
    stock test_loadNextWhiteListGroupClos( s, bool:t )
    {
        // To block them (Blacklist), we need   to load them when we are between 23-0 (23:00:00-23:59:59).
        // To allow them (Whitelist), we cannot to load them when we are between 23-0 (23:00:00-23:59:59).
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=23, .startHour=23, .endHour=0  ); // Case 1
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=0 , .startHour=23, .endHour=0  ); // Case 2
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=1 , .startHour=23, .endHour=0  ); // Case 3
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=12, .startHour=23, .endHour=0  ); // Case 4
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=11, .startHour=23, .endHour=0  ); // Case 5
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=13, .startHour=23, .endHour=0  ); // Case 6
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=22, .startHour=23, .endHour=0  ); // Case 7

        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=0 , .startHour=1 , .endHour=23 ); // Case 8
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=1 , .startHour=1 , .endHour=23 ); // Case 9
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=2 , .startHour=1 , .endHour=23 ); // Case 10
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=12, .startHour=1 , .endHour=23 ); // Case 11
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=22, .startHour=1 , .endHour=23 ); // Case 12
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=3 , .startHour=1 , .endHour=23 ); // Case 13

        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=12, .startHour=12, .endHour=22 ); // Case 14
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=13, .startHour=12, .endHour=22 ); // Case 15
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=17, .startHour=12, .endHour=22 ); // Case 16
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=22, .startHour=12, .endHour=22 ); // Case 17
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=11, .startHour=12, .endHour=22 ); // Case 18
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=5 , .startHour=12, .endHour=22 ); // Case 19
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=9 , .startHour=12, .endHour=22 ); // Case 20
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=23, .startHour=12, .endHour=22 ); // Case 21
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=0 , .startHour=12, .endHour=22 ); // Case 22

        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=23, .startHour=23, .endHour=5  ); // Case 23
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=0 , .startHour=23, .endHour=5  ); // Case 24
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=1 , .startHour=23, .endHour=5  ); // Case 25
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=2 , .startHour=23, .endHour=5  ); // Case 26
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=4 , .startHour=23, .endHour=5  ); // Case 27
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=5 , .startHour=23, .endHour=5  ); // Case 28
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=22, .startHour=23, .endHour=5  ); // Case 29
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=21, .startHour=23, .endHour=5  ); // Case 30
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=6 , .startHour=23, .endHour=5  ); // Case 31
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=7 , .startHour=23, .endHour=5  ); // Case 32
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=7 , .startHour=23, .endHour=5  ); // Case 33
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=12, .startHour=23, .endHour=5  ); // Case 34

        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=4 , .startHour=5 , .endHour=3  ); // Case 35
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=5 , .startHour=5 , .endHour=3  ); // Case 36
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=6 , .startHour=5 , .endHour=3  ); // Case 37
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=15, .startHour=5 , .endHour=3  ); // Case 38
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=3 , .startHour=5 , .endHour=3  ); // Case 39
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=2 , .startHour=5 , .endHour=3  ); // Case 40

        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=0 , .startHour=0 , .endHour=0  ); // Case 41
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=1 , .startHour=0 , .endHour=0  ); // Case 42
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=2 , .startHour=0 , .endHour=0  ); // Case 43
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=23, .startHour=0 , .endHour=0  ); // Case 44
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=22, .startHour=0 , .endHour=0  ); // Case 45
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=12, .startHour=0 , .endHour=0  ); // Case 46

        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=0 , .startHour=0 , .endHour=23 ); // Case 47
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=true , .currentHour=23, .startHour=0 , .endHour=23 ); // Case 48
        test_isToLoadBlacklist_case( s, t, true, .isToLoad=false, .currentHour=12, .startHour=0 , .endHour=23 ); // Case 49
    }

    /**
     * This is a general test handler for the function 'isToLoadNextWhiteListGroupOpen(4)'.
     *
     * @param currentHour      the current hour.
     * @param isToLoad         whether the sequence should be loaded by the given `currentHour`.
     */
    stock test_isToLoadBlacklist_case( s, bool:isBlackList, bool:isClose, bool:isToLoad, currentHour, startHour, endHour )
    {
        new test_id;
        new bool:loadResult;
        new errorMessage[ MAX_LONG_STRING ];

        if( isBlackList ) isToLoad = !isToLoad;
        test_id = test_registerSeriesNaming( "test_isToLoadBlacklist", s );

        if( isClose )
        {
            loadResult = isToLoadNextWhiteListGroupClose( currentHour, startHour, endHour, isBlackList );
        }
        else
        {
            loadResult = isToLoadNextWhiteListGroupOpen( currentHour, startHour, endHour, isBlackList );
        }

        formatex( errorMessage, charsmax( errorMessage ), "The hour %2d must %sto be loaded at [%d-%d]!",
                currentHour, ( isToLoad ? "" : "not " ), startHour, endHour );

        SET_TEST_FAILURE( test_id, loadResult != isToLoad, errorMessage )
    }

    /**
     * This is a configuration loader for the 'loadWhiteListFile(4)' function testing.
     */
    stock test_loadCurrentBlackList_load( bool:replace = false )
    {
        helper_mapFileListLoad
        (
            replace,
            g_test_whiteListFilePath,
            "[23-24]"  ,
            "de_dust1" ,
            "de_dust2" ,
            "de_dust3" ,
            "[1-23]"   ,
            "de_dust4" ,
            "[12-22]"  ,
            "de_dust5" ,
            "de_dust6" ,
            "de_dust7" ,
            "[23-05]"  ,
            "de_dust8" ,
            "de_dust9" ,
            "de_dust10",
            "[5-3]"    ,
            "de_dust11",
            "de_dust12",
            "de_dust13",
            "[0-0]"    ,
            "de_dust14",
            "de_dust15",
            "de_dust16",
            "[0-23]"   ,
            "de_dust17",
            "de_dust18"
        );
    }

    /**
     * To call the general test handler 'test_loadCurrentBlacklist_case(3)' using test scenario cases.
     */
    stock test_loadCurrentBlackList_cases()
    {
        test_loadCurrentBlackList_load();

        test_loadNextWhiteListGroupClos( 'a', true  );
        test_loadNextWhiteListGroupClos( 'b', false );

        test_loadNextWhiteListGroupOpen( 'c', false );
        test_loadNextWhiteListGroupOpen( 'a', true  );

        test_loadCurrentBlacklistMaps( 'b', false );
        test_loadCurrentBlacklistMaps( 'c', true  );
    }

    stock test_loadCurrentBlacklistMaps( s, bool:isBlackList )
    {
        test_loadCurrentBlacklist_case( s, isBlackList, 12, "de_dust2" , "de_dust7"  ); // Case 1/2
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust5" , "de_dust4"  ); // Case 3/4
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust7" , "de_dust2"  ); // Case 5/6
        test_loadCurrentBlacklist_case( s, isBlackList, 24, "de_dust4" , "de_dust1"  ); // Case 7/8
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust7" , "de_dust8"  ); // Case 9/10
        test_loadCurrentBlacklist_case( s, isBlackList, 22, "de_dust8" , "de_dust7"  ); // Case 11/12
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust5" , "de_dust1"  ); // Case 13/14
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust6" , "de_dust2"  ); // Case 15/16
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust7" , "de_dust3"  ); // Case 17/18
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust5" , "de_dust4"  ); // Case 19/20
        test_loadCurrentBlacklist_case( s, isBlackList, 2 , "de_dust6" , "de_dust11" ); // Case 21/22
        test_loadCurrentBlacklist_case( s, isBlackList, 4 , "de_dust13", "de_dust4"  ); // Case 23/24

        test_loadCurrentBlacklist_case( s, isBlackList, 0 , "", "de_dust14" ); // Case 25
        test_loadCurrentBlacklist_case( s, isBlackList, 0 , "", "de_dust15" ); // Case 26
        test_loadCurrentBlacklist_case( s, isBlackList, 0 , "", "de_dust16" ); // Case 27

        test_loadCurrentBlacklist_case( s, isBlackList, 1 , "de_dust14", "" ); // Case 28
        test_loadCurrentBlacklist_case( s, isBlackList, 1 , "de_dust15", "" ); // Case 29
        test_loadCurrentBlacklist_case( s, isBlackList, 1 , "de_dust16", "" ); // Case 30
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust14", "" ); // Case 31
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust15", "" ); // Case 32
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust16", "" ); // Case 33
        test_loadCurrentBlacklist_case( s, isBlackList, 12, "de_dust14", "" ); // Case 34
        test_loadCurrentBlacklist_case( s, isBlackList, 12, "de_dust15", "" ); // Case 35
        test_loadCurrentBlacklist_case( s, isBlackList, 12, "de_dust16", "" ); // Case 36

        test_loadCurrentBlacklist_case( s, isBlackList, 1 , "", "de_dust17" ); // Case 37
        test_loadCurrentBlacklist_case( s, isBlackList, 1 , "", "de_dust18" ); // Case 38
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "", "de_dust17" ); // Case 39
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "", "de_dust18" ); // Case 40
        test_loadCurrentBlacklist_case( s, isBlackList, 12, "", "de_dust17" ); // Case 41
        test_loadCurrentBlacklist_case( s, isBlackList, 12, "", "de_dust18" ); // Case 42
    }

    /**
     * This is a general test handler for the function 'loadWhiteListFile(4)'.
     *
     * @param s                a char within the current test series.
     * @param isBlackList      whether is is a Whitelist or Blacklist test.
     * @param currentHour      the current hour.
     * @param map_existent     the map name to exist.
     * @param not_existent     the map name to does not exist.
     */
    stock test_loadCurrentBlacklist_case( s, bool:isBlackList, currentHour, not_existent[], map_existent[] )
    {
        if( isBlackList )
        {
            test_loadCurrentBlacklist_caseT( s, isBlackList, currentHour, map_existent, not_existent );
        }
        else
        {
            test_loadCurrentBlacklist_caseT( s, isBlackList, currentHour, not_existent, map_existent);
        }
    }

    stock test_loadCurrentBlacklist_caseT( s, bool:isBlackList, currentHour, map_existent[], not_existent[] )
    {
        new test_id;
        new errorMessage[ MAX_LONG_STRING ];

        new Trie: blackListTrie      = TrieCreate();
        new Array:whitelistFileArray = ArrayCreate( MAX_LONG_STRING );

        loadWhiteListFileFromFile( whitelistFileArray, g_test_whiteListFilePath );
        loadWhiteListFile( currentHour, blackListTrie, whitelistFileArray, isBlackList );

        if( map_existent[ 0 ] )
        {
            test_id = test_registerSeriesNaming( "test_loadCurrentBlacklist", s );

            formatex( errorMessage, charsmax( errorMessage ), "The map '%s' must to be present on the trie, but it was not!", map_existent );
            SET_TEST_FAILURE( test_id, !TrieKeyExists( blackListTrie, map_existent ), errorMessage )
        }

        if( not_existent[ 0 ] )
        {
            test_id = test_registerSeriesNaming( "test_loadCurrentBlacklist", s );

            formatex( errorMessage, charsmax( errorMessage ), "The map '%s' must not to be present on the trie, but it was!", not_existent );
            SET_TEST_FAILURE( test_id, TrieKeyExists( blackListTrie, not_existent ), errorMessage )
        }

        TrieDestroy( blackListTrie );
        ArrayDestroy( whitelistFileArray );
    }

    /**
     * To call the general test handler 'test_resetRoundsScores_case(4)' using test scenario cases.
     */
    stock test_resetRoundsScores_cases()
    {
        // Register the cvar `mp_fraglimit` if is not yet registered.
        set_pcvar_num( cvar_fragLimitSupport       , 1 );
        mp_fraglimitCvarSupport();

        test_resetRoundsScores_loader( 90, 60, 31, 60  ); // Case  1-4 , 90 - 60 + 31 - 1 = 60
        test_resetRoundsScores_loader( 90, 20, 31, 100 ); // Case  5-8 , 90 - 20 + 31 - 1 = 100
        test_resetRoundsScores_loader( 20, 15, 11, 15  ); // Case  9-12, 20 - 15 + 11 - 1 = 15
        test_resetRoundsScores_loader( 60, 50, 1 , 10  ); // Case 13-16, 60 - 50 + 1  - 1 = 10
        test_resetRoundsScores_loader( 60, 59, 1 , 1   ); // Case 17-20, 60 - 59 + 1  - 1 = 1
        test_resetRoundsScores_loader( 60, 60, 1 , 60  ); // Case 21-24, 60 - 60 + 1  - 1 = 60
        test_resetRoundsScores_loader( 60, 59, 0 , 60  ); // Case 25-28, 60 - 59 + 0  - 1 = 60
        test_resetRoundsScores_loader( 60, 20, 0 , 60  ); // Case 29-32, 60 - 20 + 0  - 1 = 60
        test_resetRoundsScores_loader( 60, 80, 10, 60  ); // Case 33-36, 60 - 80 + 10 - 1 = 60
    }

    /**
     * Load the test to all cvars on range.
     *
     * @param defaultCvarValue        the default game cvar value to be used.
     * @param elapsedValue            an elapsed game integer value.
     * @param defaultLimiterValue     the default limiter cvar value to be used.
     * @param aimResult               the expected result after the operation to complete.
     */
    stock test_resetRoundsScores_loader( defaultCvarValue, elapsedValue, defaultLimiterValue, aimResult )
    {
        test_resetRoundsScores_case( cvar_serverTimeLimitRestart, cvar_mp_timelimit, elapsedValue, aimResult,
                defaultCvarValue, defaultLimiterValue );

        test_resetRoundsScores_case( cvar_serverWinlimitRestart ,  cvar_mp_winlimit, elapsedValue, aimResult,
                defaultCvarValue, defaultLimiterValue );

        test_resetRoundsScores_case( cvar_serverMaxroundsRestart, cvar_mp_maxrounds, elapsedValue, aimResult,
                defaultCvarValue, defaultLimiterValue );

        test_resetRoundsScores_case( cvar_serverFraglimitRestart, cvar_mp_fraglimit, elapsedValue, aimResult,
                defaultCvarValue, defaultLimiterValue );
    }

    /**
     * This is a general test handler for the function 'resetRoundsScores(0)'.
     *
     * @param limiterCvarPointer      the 'gal_srv_..._restart' pointer
     * @param serverCvarPointer       the game cvar pointer as 'cvar_mp_timelimit'.
     *
     * @note see the stock test_resetRoundsScores_loader(4) for the other parameters.
     */
    stock test_resetRoundsScores_case( limiterCvarPointer, serverCvarPointer, elapsedValue,
                                       aimResult, defaultCvarValue, defaultLimiterValue )
    {
        new test_id;
        new testName[ MAX_SHORT_STRING ];

        new changeResult;
        new errorMessage[ MAX_LONG_STRING ];

        static currentCaseNumber = 0;
        currentCaseNumber++;

        formatex( testName, charsmax( testName ), "test_resetRoundsScores_case%d", currentCaseNumber );
        test_id  = register_test( 0, testName );

        g_test_gameElapsedTime = elapsedValue;
        g_totalTerroristsWins  = elapsedValue;
        g_totalCtWins          = elapsedValue;
        g_totalRoundsPlayed    = elapsedValue;
        g_greatestKillerFrags  = elapsedValue;

        tryToSetGameModCvarNum( limiterCvarPointer, defaultLimiterValue );
        tryToSetGameModCvarNum( serverCvarPointer , defaultCvarValue );

        // It is expected the 'changeResult' to be 'defaultCvarValue' - 'elapsedValue' + 'defaultLimiterValue' - 1
        resetRoundsScores();
        changeResult = get_pcvar_num( serverCvarPointer );

        formatex( errorMessage, charsmax( errorMessage ), "The aim result '%d' was not achieved! The result was %d.", aimResult, changeResult );
        SET_TEST_FAILURE( test_id, changeResult != aimResult, errorMessage )
    }

    /**
     * To call the general test handler 'test_loadVoteChoices_serie(1)' using test series, the
     * `loadTheDefaultVotingChoices(0)` function testing.
     */
    stock test_loadVoteChoices_cases()
    {
        // Enable all settings and to perform the configuration loading
        set_pcvar_string( cvar_voteMapFilePath, g_test_voteMapFilePath );
        set_pcvar_string( cvar_voteWhiteListMapFilePath, g_test_whiteListFilePath );
        set_pcvar_string( cvar_voteMinPlayersMapFilePath, g_test_minPlayersFilePath );

        set_pcvar_num( cvar_whitelistMinPlayers  , 1 );
        set_pcvar_num( cvar_voteMinPlayers       , 2 );
        set_pcvar_num( cvar_isWhiteListNomBlock  , 0 );
        set_pcvar_num( cvar_isWhiteListBlockOut  , 0 );
        set_pcvar_num( cvar_nomMinPlayersControl , 2 );
        set_pcvar_num( cvar_nomPlayerAllowance   , 2 );
        set_pcvar_num( cvar_voteMapChoiceCount   , 5 );
        set_pcvar_num( cvar_nomQtyUsed           , 0 );

        cacheCvarsValues();

        // If 'g_test_aimedPlayersNumber < cvar_voteMinPlayers', enables the minimum players feature.
        g_test_aimedPlayersNumber = 0;

        test_loadVoteChoices_serie( 'a' );
        test_loadVoteChoices_serie( 'b' );
        test_loadVoteChoices_serie( 'c' );
        test_loadVoteChoices_serie( 'd' );
    }

    /**
     * Run a test serie and clean its results.
     */
    stock test_loadVoteChoices_serie( currentSerie )
    {
        // Clear all loaded maps.
        helper_clearNominationsData();

        switch( currentSerie )
        {
            case 'a':
            {
                test_loadVoteChoices_serie_a();
            }
            case 'b':
            {
                test_loadVoteChoices_serie_b();
            }
            case 'c':
            {
                test_loadVoteChoices_serie_c();
            }
            case 'd':
            {
                test_loadVoteChoices_serie_d();
            }
        }

        // To print the voting menu for analysis.
        for( new currentIndex = 0; currentIndex < sizeof g_votingMapNames; ++currentIndex )
        {
            LOGGER( 1, "g_votingMapNames[%d]: %s %s", currentIndex, g_votingMapNames[ currentIndex ], g_votingMapInfos[ currentIndex ] )
        }
    }

    /**
     * Checks whether the voting menu is properly loaded given some maps.
     *
     * @param requiredMap      a map to be on the menu.
     * @param blockedMap       a map to not be on the menu.
     * @param newSeries        a char as the new test series start. The default is to use the last serie.
     */
    stock test_loadVoteChoices_case( requiredMap[], blockedMap[], newSeries = 0 )
    {
        new test_id = test_registerSeriesNaming( "test_loadVoteChoices", newSeries );

        test_loadVoteChoices_check( test_id, requiredMap, true );
        test_loadVoteChoices_check( test_id, blockedMap, false );
    }

    /**
     * @see test_loadVoteChoices_case(3).
     */
    stock test_loadVoteChoices_check( test_id, mapToCheck[], bool:isToBePresent )
    {
        new bool:isMapPresent;
        new      currentIndex;
        new      errorMessage[ MAX_LONG_STRING ];

        if( mapToCheck[ 0 ] )
        {
            for( currentIndex = 0; currentIndex < sizeof g_votingMapNames; ++currentIndex )
            {
                if( equali( g_votingMapNames[ currentIndex ], mapToCheck ) )
                {
                    isMapPresent = true;
                }
            }

            formatex( errorMessage, charsmax( errorMessage ),
                    "The map '%s' %s be present on the voting map menu.", mapToCheck, ( isToBePresent ? "must to" : "MUST NOT to" ) );
            SET_TEST_FAILURE( test_id, isMapPresent != isToBePresent, errorMessage )
        }
    }

    /**
     * PART 1: Nominates some maps and create the vote map file and minimum players map file.
     */
    stock test_loadVoteChoices_serie_a()
    {
        helper_loadNominations( "de_rain", "de_inferno", "as_trunda" );

        helper_mapFileListLoad( false, g_test_voteMapFilePath   , "de_dust1", "de_dust2" );
        helper_mapFileListLoad( false, g_test_minPlayersFilePath, "de_rain" , "de_nuke" );
        helper_mapFileListLoad( false, g_test_whiteListFilePath , "[0-23]"  , "de_rain", "de_nuke" );

        // Forced the minimum players feature map to be loaded.
        g_test_aimedPlayersNumber = 1;

        // To force the Whitelist to be reloaded.
        loadMapFiles();
        loadTheWhiteListFeature();
        loadTheDefaultVotingChoices();

        test_loadVoteChoices_case( "de_rain", "de_inferno", 'a' ); // Case 1
        test_loadVoteChoices_case( "de_nuke", "as_trunda" );       // Case 2
    }

    /**
     * PART 2: Force the minimum players feature to work.
     */
    stock test_loadVoteChoices_serie_b()
    {
        helper_loadNominations( "de_rain", "de_inferno", "as_trunda" );

        helper_mapFileListLoad( false, g_test_voteMapFilePath   , "de_dust1", "de_dust2" );
        helper_mapFileListLoad( false, g_test_minPlayersFilePath, "de_rain" , "de_nuke" );
        helper_mapFileListLoad( false, g_test_whiteListFilePath , "[0-23]"  , "de_rain", "de_nuke" );

        // Disables the minimum players feature.
        g_test_aimedPlayersNumber = 5;

        // To force the Whitelist to be reloaded.
        loadMapFiles();
        loadTheWhiteListFeature();
        loadTheDefaultVotingChoices();

        test_loadVoteChoices_case( "de_rain"   , "de_nuke", 'b' ); // Case 1
        test_loadVoteChoices_case( "de_inferno", "de_nuke" );      // Case 2
        test_loadVoteChoices_case( "as_trunda" , "de_nuke" );      // Case 3
    }

    /**
     * PART 3: Load more maps nominations and disable the minimum players feature.
     */
    stock test_loadVoteChoices_serie_c()
    {
        helper_loadNominations( "de_dust2002v2005_forEver2009", "de_dust2002v2005_forEver2010", "de_dust2002v2005_forEver2011",
                                       "de_dust2002v2005_forEver2012", "de_dust2002v2005_forEver2013", "de_dust2002v2005_forEver2014",
                                       "de_dust2002v2005_forEver2015", "de_dust2002v2005_forEver2016", "de_dust2002v2005_forEver2017" );

        helper_mapFileListLoad( false, g_test_voteMapFilePath   , "de_dust1", "de_dust2" );
        helper_mapFileListLoad( false, g_test_minPlayersFilePath, "de_rats" , "de_train" );
        helper_mapFileListLoad( false, g_test_whiteListFilePath , "[0-23]"  , "de_rats", "de_train" );

        // Forced the minimum players feature map to be loaded.
        g_test_aimedPlayersNumber = 1;

        // To force the Whitelist to be reloaded.
        loadMapFiles();
        loadTheWhiteListFeature();
        loadTheDefaultVotingChoices();

        test_loadVoteChoices_case( "de_rats" , "de_dust2002v2005_forEver2009", 'c' ); // Case 1
        test_loadVoteChoices_case( "de_train", "de_dust2002v2005_forEver2010" );      // Case 2
        test_loadVoteChoices_case( "de_train", "de_dust2002v2005_forEver2011" );      // Case 3
        test_loadVoteChoices_case( "de_rats" , "de_dust2002v2005_forEver2012" );      // Case 4
    }

    /**
     * PART 4: Enable the minimum players feature.
     */
    stock test_loadVoteChoices_serie_d()
    {
        helper_loadNominations( "de_rain", "de_inferno", "as_trunda" );

        helper_mapFileListLoad( false, g_test_voteMapFilePath   , "de_dust1", "de_dust2" );
        helper_mapFileListLoad( false, g_test_minPlayersFilePath, "de_rain" , "de_nuke" );
        helper_mapFileListLoad( false, g_test_whiteListFilePath , "[0-23]"  , "de_rain", "de_nuke" );

        // Disables the minimum players feature.
        g_test_aimedPlayersNumber = 5;

        // To force the Whitelist to be reloaded.
        loadMapFiles();
        loadTheWhiteListFeature();
        loadTheDefaultVotingChoices();

        test_loadVoteChoices_case( "de_rain"   , "", 'd' );   // Case 1
        test_loadVoteChoices_case( "de_inferno", "de_nuke" ); // Case 2
        test_loadVoteChoices_case( "as_trunda" , "de_nuke" ); // Case 3
    }

    /**
     * This case happens when the map was previously nominated and cancelled by someone else
     * and then nominated again by the same person or someone else.
     *
     * Also test whether the unnominatedDisconnectedPlayer(1) forward is cleaning the players
     * nominations correctly.
     */
    stock test_nominateAndUnnominate_load()
    {
        helper_clearNominationsData();
        set_pcvar_string( cvar_nomMapFilePath, g_test_nomMapFilePath );

        // Player cannot nominate the current map, so if you are on one fo these maps, the test will fail.
        helper_mapFileListLoad( false, g_test_nomMapFilePath, "de_test_dust1", "de_test_dust2", "de_test_dust3", "de_test_dust4" );
        loadNominationList();

        // Nominations functions:
        //
        // nomination_cancel( player_id, mapIndex )
        // nomination_toggle( player_id, mapIndex )
        // map_nominate( player_id, mapIndex )
        // countPlayerNominations( player_id, &openNominationIndex )
        // nomination_list()

        // Add a nomination for the player 1
        test_nominateAndUnnominate( .player_id = 1, .map_index = 0, .total_Nom = 1, .action = 'a' ); // Case 1

        // Failed, you already nominated it
        test_nominateAndUnnominate( .player_id = 1, .map_index = 0, .total_Nom = 1, .action = 'a' ); // Case 2

        // Remove the nomination for the player 1
        test_nominateAndUnnominate( .player_id = 1, .map_index = 0, .total_Nom = 0, .action = 'r' ); // Case 3

        // Add 2 nominations
        test_nominateAndUnnominate( .player_id = 1, .map_index = 0, .total_Nom = 1, .action = 'a' ); // Case 4
        test_nominateAndUnnominate( .player_id = 1, .map_index = 1, .total_Nom = 2, .action = 'a' ); // Case 5

        // Remove 4
        test_nominateAndUnnominate( .player_id = 1, .map_index = 0, .total_Nom = 1, .action = 'r' ); // Case 6
        test_nominateAndUnnominate( .player_id = 1, .map_index = 1, .total_Nom = 0, .action = 'r' ); // Case 7
        test_nominateAndUnnominate( .player_id = 1, .map_index = 1, .total_Nom = 0, .action = 'r' ); // Case 8
        test_nominateAndUnnominate( .player_id = 1, .map_index = 0, .total_Nom = 0, .action = 'r' ); // Case 9

        // test whether the unnominatedDisconnectedPlayer(1) forward is cleaning the players
        // nominations correctly. Add 2 nominations
        test_nominateAndUnnominate( .player_id = 1, .map_index = 0, .total_Nom = 1, .action = 'a' ); // Case 10
        test_nominateAndUnnominate( .player_id = 1, .map_index = 1, .total_Nom = 2, .action = 'a' ); // Case 11

        unnominatedDisconnectedPlayer( 1 );
        test_nominateAndUnnominate( .player_id = 1, .map_index = 0, .total_Nom = 0, .action = 'n' ); // Case 12
    }

    /**
     * Create one case test for the nomination system based on its parameters passed by the
     * test_nominateAndUnnominate_load(0) loader function.
     */
    stock test_nominateAndUnnominate( player_id, map_index, total_Nom, action )
    {
        new openNominationIndex;
        new errorMessage[ MAX_LONG_STRING ];

        new test_id = test_registerSeriesNaming( "test_nominateAndUnnominate", 'a' );

        switch( action )
        {
            case 'a':
            {
                map_nominate( player_id, map_index );
            }
            case 'r':
            {
                nomination_cancel( player_id, map_index );
            }
        }

        nomination_list();

        // Count how much nominations that player has
        new nominationsCount = countPlayerNominations( player_id, openNominationIndex );

        formatex( errorMessage, charsmax( errorMessage ), "Must to be %d nominations, instead of %d.", total_Nom, nominationsCount );
        SET_TEST_FAILURE( test_id, nominationsCount != total_Nom, errorMessage )
    }

    /**
     * To test the RTV feature.
     */
    stock test_RTVAndUnRTV_load()
    {
        // RTVs functions:
        //
        // vote_rock( player_id )
        // vote_unrockTheVote( player_id )

        g_rtvWaitMinutes     = 0.0;
        g_rtvWaitRounds      = 0;
        g_rtvWaitFrags       = 0;
        g_rtvWaitAdminNumber = 0;

        g_test_aimedPlayersNumber = 6;
        set_pcvar_float( cvar_rtvRatio, 0.5 );

        // Add a RTV for the player 1
        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 1, .action = 'a' ); // Case
        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 1, .action = 'a' ); // Case
        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 1, .action = 'a' ); // Case

        test_RTVAndUnRTV( .player_id = 2, .total_RTVs = 2, .action = 'a' ); // Case
        test_RTVAndUnRTV( .player_id = 2, .total_RTVs = 2, .action = 'a' ); // Case
        test_RTVAndUnRTV( .player_id = 2, .total_RTVs = 1, .action = 'r' ); // Case
        test_RTVAndUnRTV( .player_id = 2, .total_RTVs = 1, .action = 'r' ); // Case

        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 0, .action = 'r' ); // Case
        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 0, .action = 'r' ); // Case
        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 0, .action = 'r' ); // Case
        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 0, .action = 'r' ); // Case

        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 1, .action = 'a' ); // Case
        test_RTVAndUnRTV( .player_id = 2, .total_RTVs = 2, .action = 'a' ); // Case
        test_RTVAndUnRTV( .player_id = 3, .total_RTVs = 3, .action = 'a' ); // Case

        cancelVoting();
        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 0, .action = 'n' ); // Case
    }

    /**
     * Create one case test for the RTV feature based on its parameters passed by the
     * test_RTVAndUnRTV_load(0) loader function.
     */
    stock test_RTVAndUnRTV( player_id, total_RTVs, action )
    {
        new errorMessage[ MAX_LONG_STRING ];
        new test_id = test_registerSeriesNaming( "test_RTVAndUnRTV", 'b' );

        switch( action )
        {
            case 'a':
            {
                vote_rock( player_id );
            }
            case 'r':
            {
                vote_unrockTheVote( player_id );
            }
        }

        formatex( errorMessage, charsmax( errorMessage ), "Must to be %d RTVs, instead of %d.", total_RTVs, g_rockedVoteCount );
        SET_TEST_FAILURE( test_id, g_rockedVoteCount != total_RTVs, errorMessage )
    }

    /**
     * To test the stock getUniqueRandomIntegerBasic(2).
     */
    stock test_getUniqueRandomBasic_load()
    {
        test_getUniqueRandomIntBasic( 0  ); // Case 1
        test_getUniqueRandomIntBasic( 1  ); // Case 2
        test_getUniqueRandomIntBasic( 30 ); // Case 3
        test_getUniqueRandomIntBasic( 31 ); // Case 4

        test_getUniqueRandomIntBasic( 31 ); // Case 5
        test_getUniqueRandomIntBasic( 30 ); // Case 6
        test_getUniqueRandomIntBasic( 1  ); // Case 7
        test_getUniqueRandomIntBasic( 0  ); // Case 8
    }

    /**
     * Create one case test for the stock getUniqueRandomIntegerBasic(2) and getUniqueRandomInteger(4)
     * based on its parameters passed by the test_getUniqueRandomBasic_load(0) and test_getUniqueRandomInteger(0)
     * loader functions.
     */
    stock test_getUniqueRandomIntBasic( max_value, Array:holder = Invalid_Array )
    {
        new errorMessage[ MAX_LONG_STRING ];
        new test_id = test_registerSeriesNaming( "test_getUniqueRandomIntBasic", 'a' );

        TRY_TO_APPLY( getUniqueRandomInteger, holder )
        static sequence = -1;

        new trieSize;
        new sortedInterger;

        new sortedIntergerString[ 6 ];
        new Trie:sortedIntegers = TrieCreate();

        sequence++;

        for( new index = 0; index < max_value + 3 ; index++ )
        {
            if( holder )
            {
                sortedInterger = getUniqueRandomInteger( holder, 0, max_value, false );
            }
            else
            {
                sortedInterger = getUniqueRandomIntegerBasic( sequence, max_value );
            }

            num_to_str( sortedInterger, sortedIntergerString, charsmax( sortedIntergerString ) );

            formatex( errorMessage, charsmax( errorMessage ), "The integer %d, must not to be sorted twice.", sortedInterger );
            SET_TEST_FAILURE( test_id, TrieKeyExists( sortedIntegers, sortedIntergerString ) && sortedInterger != -1, errorMessage )

            if( !TrieKeyExists( sortedIntegers, sortedIntergerString ) )
            {
                TrieSetCell( sortedIntegers, sortedIntergerString, index ) ? trieSize++ : trieSize;
            }
        }

        formatex( errorMessage, charsmax( errorMessage ), "The TrieSize must to be %d, instead of %d.", max_value + 2, trieSize );
        SET_TEST_FAILURE( test_id, trieSize != max_value + 2, errorMessage )

        TrieDestroy( sortedIntegers );
    }

    /**
     * To test the stock getUniqueRandomInteger(3).
     */
    stock test_getUniqueRandomInt_load()
    {
        new Array:holder = ArrayCreate();

        test_getUniqueRandomIntBasic( 0 , holder ); // Case 1
        test_getUniqueRandomIntBasic( 1 , holder ); // Case 2
        test_getUniqueRandomIntBasic( 30, holder ); // Case 3
        test_getUniqueRandomIntBasic( 31, holder ); // Case 4

        test_getUniqueRandomIntBasic( 31, holder ); // Case 5
        test_getUniqueRandomIntBasic( 30, holder ); // Case 6
        test_getUniqueRandomIntBasic( 1 , holder ); // Case 7
        test_getUniqueRandomIntBasic( 0 , holder ); // Case 8

        test_getUniqueRandomInteger( holder, 0, 0  ); // Case 9
        test_getUniqueRandomInteger( holder, 0, 1  ); // Case 10
        test_getUniqueRandomInteger( holder, 0, 30 ); // Case 11
        test_getUniqueRandomInteger( holder, 0, 31 ); // Case 12

        test_getUniqueRandomInteger( holder, 0, 31 ); // Case 13
        test_getUniqueRandomInteger( holder, 0, 30 ); // Case 14
        test_getUniqueRandomInteger( holder, 0, 1  ); // Case 15
        test_getUniqueRandomInteger( holder, 0, 0  ); // Case 16

        ArrayDestroy( holder );
    }

    /**
     * Create one case test for the stock getUniqueRandomInteger(0) based on its parameters passed
     * by the test_getUniqueRandom_load2(0) loader function.
     */
    stock test_getUniqueRandomInteger( Array:holder, min_value, max_value )
    {
        new errorMessage[ MAX_LONG_STRING ];
        new test_id = test_registerSeriesNaming( "test_getUniqueRandomInteger", 'c' );

        new trieSize;
        new sortedInterger;

        new sortedIntergerString[ 6 ];
        new Trie:sortedIntegers = TrieCreate();
        new randomCount         = max_value - min_value + 1;

        static sequence = -1;
        sequence++;

        for( new index = 0; index < max_value + 1 ; index++ )
        {
            sortedInterger = getUniqueRandomInteger( holder, min_value, max_value );
            num_to_str( sortedInterger, sortedIntergerString, charsmax( sortedIntergerString ) );

            formatex( errorMessage, charsmax( errorMessage ), "The integer %d, must not to be sorted twice.", sortedInterger );
            SET_TEST_FAILURE( test_id, TrieKeyExists( sortedIntegers, sortedIntergerString ), errorMessage )

            if( !TrieKeyExists( sortedIntegers, sortedIntergerString ) )
            {
                TrieSetCell( sortedIntegers, sortedIntergerString, index ) ? trieSize++ : 0;
            }
        }

        formatex( errorMessage, charsmax( errorMessage ), "The TrieSize must to be %d, instead of %d.", max_value, trieSize );
        SET_TEST_FAILURE( test_id, trieSize != randomCount, errorMessage )

        LOGGER( 1, "" )

        for( new index = 0; index < max_value + 1 ; index++ )
        {
            sortedInterger = getUniqueRandomInteger( holder, min_value, max_value );
            num_to_str( sortedInterger, sortedIntergerString, charsmax( sortedIntergerString ) );

            formatex( errorMessage, charsmax( errorMessage ), "The integer %d, must to be sorted twice.", sortedInterger );
            SET_TEST_FAILURE( test_id, !TrieKeyExists( sortedIntegers, sortedIntergerString ), errorMessage )

            if( !TrieKeyExists( sortedIntegers, sortedIntergerString ) )
            {
                TrieSetCell( sortedIntegers, sortedIntergerString, index ) ? trieSize++ : 0;
            }
        }

        formatex( errorMessage, charsmax( errorMessage ), "The TrieSize must to be %d, instead of %d.", max_value, trieSize );
        SET_TEST_FAILURE( test_id, trieSize != randomCount, errorMessage )

        TrieDestroy( sortedIntegers );
    }

    /**
     * To test the stock whatGameEndingTypeItIs(0).
     */
    stock test_whatGameEndingTypeIt_load()
    {
        new GameEndingType:tNone   = GameEndingType_ByNothing;
        new GameEndingType:tLimit  = GameEndingType_ByTimeLimit;
        new GameEndingType:tWins   = GameEndingType_ByWinLimit;
        new GameEndingType:tRounds = GameEndingType_ByMaxRounds;
        new GameEndingType:tFrags  = GameEndingType_ByFragLimit;

        test_whatGameEndingTypeIt( .cvarW=1, .win=100, .trs= 20, .result=tWins ); // Case 1
        test_whatGameEndingTypeIt( .cvarW=1, .win=100, .trs=  0, .result=tWins ); // Case 2
        test_whatGameEndingTypeIt( .cvarW=1, .win=100, .trs=101, .result=tWins ); // Case 3
        test_whatGameEndingTypeIt( .cvarW=1, .win=  0, .trs=101, .result=tNone ); // Case 4
        test_whatGameEndingTypeIt( .cvarW=1, .win=  0, .trs=  0, .result=tNone ); // Case 5

        test_whatGameEndingTypeIt( .cvarM=1, .max=100, .played= 20, .result=tRounds ); // Case 6
        test_whatGameEndingTypeIt( .cvarM=1, .max=100, .played=  0, .result=tRounds ); // Case 7
        test_whatGameEndingTypeIt( .cvarM=1, .max=100, .played=101, .result=tRounds ); // Case 8
        test_whatGameEndingTypeIt( .cvarM=1, .max=  0, .played=101, .result=tNone   ); // Case 9
        test_whatGameEndingTypeIt( .cvarM=1, .max=  0, .played=  0, .result=tNone   ); // Case 10

        test_whatGameEndingTypeIt( .cvarT=1, .time=100.0, .limit=60.0* 20, .result=tLimit ); // Case 11
        test_whatGameEndingTypeIt( .cvarT=1, .time=100.0, .limit=60.0*  3, .result=tLimit ); // Case 12
        test_whatGameEndingTypeIt( .cvarT=1, .time=100.0, .limit=60.0*101, .result=tLimit ); // Case 13
        test_whatGameEndingTypeIt( .cvarT=1, .time=  0.0, .limit=60.0*101, .result=tNone  ); // Case 14
        test_whatGameEndingTypeIt( .cvarT=1, .time=  0.0, .limit=60.0*  0, .result=tNone  ); // Case 15

        test_whatGameEndingTypeIt( .cvarF=1, .frag=100, .frags= 20, .result=tFrags ); // Case 16
        test_whatGameEndingTypeIt( .cvarF=1, .frag=100, .frags=  0, .result=tFrags ); // Case 17
        test_whatGameEndingTypeIt( .cvarF=1, .frag=100, .frags=101, .result=tFrags ); // Case 18
        test_whatGameEndingTypeIt( .cvarF=1, .frag=  0, .frags=101, .result=tNone  ); // Case 19
        test_whatGameEndingTypeIt( .cvarF=1, .frag=  0, .frags=  0, .result=tNone  ); // Case 20

        test_whatGameEndingTypeIt( .cvarT=1, .time=100.0, .limit=100*60.0, .result=tLimit  ); // Case 21
        test_whatGameEndingTypeIt( .cvarM=1, .max=50    , .played=101    , .result=tRounds ); // Case 22

        test_whatGameEndingTypeIt( .cvarM=1, .max=200   , .played=100   ,
                                   .cvarT=1, .time=100.0, .limit=60.0*50, .result=tLimit ); // Case 23

        test_whatGameEndingTypeIt( .cvarM=1, .max=200   , .played=100   ,
                                   .cvarW=1, .win=20    , .cts=5        , .trs=0,
                                   .cvarT=1, .time=100.0, .limit=60.0*50, .result=tWins ); // Case 24

        test_whatGameEndingTypeIt( .cvarM=1, .max=200   , .played=100   ,
                                   .cvarW=1, .win=20    , .cts=5        , .trs=0,
                                   .cvarF=1, .frag=30   , .frags=5      ,
                                   .cvarT=1, .time=100.0, .limit=60.0*50, .result=tFrags ); // Case 25

        test_whatGameEndingTypeIt( .cvarW=1 , .win=20    , .cts=5        , .trs=0,
                                   .cvarM=1 , .max=200   , .played=100   ,
                                   .cvarT=1 , .time=100.0, .limit=60.0*10,
                                   .cvarF=1 , .frag=30   , .frags=5      ,
                                   .mean=210, .saved=10  , .result=tLimit  ); // Case 26
    }

    /**
     * Create one case test for the stock whatGameEndingTypeItIs(0) based on its parameters passed
     * by the test_whatGameEndingTypeIt_load(0) loader function.
     */
    stock test_whatGameEndingTypeIt( cvarW=0, win=0         , cts=0          , trs=0,
                                     cvarM=0, max=0         , played=0       ,
                                     cvarT=0, Float:time=0.0, Float:limit=0.0,
                                     cvarF=0, frag=0        , frags=0        ,
                                     mean=0 , saved=0       , GameEndingType:result )
    {
        new GameEndingType:gameType;

        new errorMessage[ MAX_LONG_STRING ];
        new test_id = test_registerSeriesNaming( "test_whatGameEndingTypeIt", 'b' );

        g_roundAverageTime      = mean;
        g_totalRoundsSavedTimes = saved;
        g_totalRoundsPlayed     = played;
        g_totalCtWins           = cts;
        g_totalTerroristsWins   = trs;
        g_greatestKillerFrags   = frags;

        tryToSetGameModCvarNum(   cvar_mp_winlimit , cvarW ? win  : 0   );
        tryToSetGameModCvarNum(   cvar_mp_maxrounds, cvarM ? max  : 0   );
        tryToSetGameModCvarFloat( cvar_mp_timelimit, cvarT ? time : 0.0 );
        tryToSetGameModCvarNum(   cvar_mp_fraglimit, cvarF ? frag : 0   );

        LOGGER( 32, "( test_whatGameEndingTypeIt ) timelimit: %d", floatround( get_pcvar_float( cvar_mp_timelimit ) * 60 ) )

        if( time > 0.0 )
        {
            tryToSetGameModCvarFloat( cvar_mp_timelimit,
                    ( get_pcvar_float( cvar_mp_timelimit ) * 60
                      - get_timeleft()
                      + limit
                    ) / 60 );
        }

        LOGGER( 32, "( test_whatGameEndingTypeIt ) timelimit: %d", floatround( get_pcvar_float( cvar_mp_timelimit ) * 60 ) )

        gameType = whatGameEndingTypeItIs();

        formatex( errorMessage, charsmax( errorMessage ), "The GameEndingType must to be %d, instead of %d.", result, gameType );
        SET_TEST_FAILURE( test_id, gameType != result, errorMessage )
    }

    /**
     * To test the stock convert_numeric_base(3).
     */
    stock test_convertNumericBase_load()
    {
        test_convertNumericBase( .origin_number = 10  , .origin_base = 7 , .destiny_base = 10, .expected = 7    ); // Case 1
        test_convertNumericBase( .origin_number = 10  , .origin_base = 6 , .destiny_base = 10, .expected = 6    ); // Case 2
        test_convertNumericBase( .origin_number = 10  , .origin_base = 5 , .destiny_base = 10, .expected = 5    ); // Case 3
        test_convertNumericBase( .origin_number = 10  , .origin_base = 8 , .destiny_base = 10, .expected = 8    ); // Case 4
        test_convertNumericBase( .origin_number = 10  , .origin_base = 9 , .destiny_base = 10, .expected = 9    ); // Case 5
        test_convertNumericBase( .origin_number = 10  , .origin_base = 10, .destiny_base = 10, .expected = 10   ); // Case 6
        test_convertNumericBase( .origin_number = 11  , .origin_base = 7 , .destiny_base = 9 , .expected = 8    ); // Case 7
        test_convertNumericBase( .origin_number = 2462, .origin_base = 7 , .destiny_base = 9 , .expected = 1238 ); // Case 8
        test_convertNumericBase( .origin_number = 1238, .origin_base = 9 , .destiny_base = 7 , .expected = 2462 ); // Case 9
    }

    /**
     * Create one case test for the stock convert_numeric_base(0) based on its parameters passed
     * by the test_convertNumericBase_load(0) loader function.
     */
    stock test_convertNumericBase( origin_number, origin_base, destiny_base, expected )
    {
        new errorMessage[ MAX_LONG_STRING ];
        new test_id = test_registerSeriesNaming( "test_convertNumericBase", 'a' );

        new result = convert_numeric_base( origin_number, origin_base, destiny_base );

        formatex( errorMessage, charsmax( errorMessage ),
                "Converting the number %d on base %d to base %d must to be %d, instead of %d.",
                origin_number, origin_base, destiny_base, expected, result );

        SET_TEST_FAILURE( test_id, result != expected, errorMessage )
    }

    /**
     * To test the stock setCorrectMenuPage(4).
     */
    stock test_setCorrectMenuPage_load()
    {
        test_setCorrectMenuPage( .pageString="noPagesHere", .pagesCount=5  , .expectedPage=0  ); // Case 1
        test_setCorrectMenuPage( .pageString="pages5Here" , .pagesCount=5  , .expectedPage=4  ); // Case 2
        test_setCorrectMenuPage( .pageString="5Here"      , .pagesCount=5  , .expectedPage=4  ); // Case 3
        test_setCorrectMenuPage( .pageString="6Here"      , .pagesCount=5  , .expectedPage=4  ); // Case 4
        test_setCorrectMenuPage( .pageString="menuCute6"  , .pagesCount=5  , .expectedPage=4  ); // Case 5
        test_setCorrectMenuPage( .pageString="menuCute4"  , .pagesCount=5  , .expectedPage=3  ); // Case 6
        test_setCorrectMenuPage( .pageString="50"         , .pagesCount=120, .expectedPage=49 ); // Case 7
    }

    /**
     * Create one case test for the stock setCorrectMenuPage(4) based on its parameters passed
     * by the test_setCorrectMenuPage_load(0) loader function.
     */
    stock test_setCorrectMenuPage( pageString[], pagesCount, expectedPage )
    {
        new menuPages   [ 2 ];
        new pageString2 [ 64 ];
        new errorMessage[ MAX_LONG_STRING ];

        new player_id = 1;
        new test_id   = test_registerSeriesNaming( "test_convertNumericBase", 'b' );

        copy( pageString2, charsmax( pageString2 ), pageString );
        setCorrectMenuPage( player_id, pageString, menuPages, pagesCount );

        formatex( errorMessage, charsmax( errorMessage ),
                "The converted page `%s` must to be %d, instead of %d (%s).",
                pageString2, expectedPage, menuPages[ player_id ], pageString );

        SET_TEST_FAILURE( test_id, menuPages[ player_id ] != expectedPage, errorMessage )
    }

    /**
     * Tests if the function helper_loadStrictValidMapsTrie() is properly loading its maps bytes
     * isAllowedValidMapByTheUnitTests(1).
     */
    stock test_strictValidMapsTrie_load()
    {
        g_test_isToUseStrictValidMaps = true;

        helper_mapFileListLoad( false, g_test_voteMapFilePath, "de_dust1", "de_dust2", "de_nuke", "de_dust2" );
        helper_loadStrictValidMapsTrie( "de_dust1", "de_dust2", "de_dust5", "de_dust6", "de_nuke" );

        test_strictValidMapsTrie( "de_dust1" ); // Case 1
        test_strictValidMapsTrie( "de_dust2" ); // Case 2
        test_strictValidMapsTrie( "de_dust5" ); // Case 3
        test_strictValidMapsTrie( "de_dust6" ); // Case 4
        test_strictValidMapsTrie( "de_nuke"  ); // Case 5

        test_strictValidMapsTrie( "de_nuke2", true ); // Case 6
        test_strictValidMapsTrie( "de_dust" , true ); // Case 7
        test_strictValidMapsTrie( "de_dust3", true ); // Case 8
        test_strictValidMapsTrie( "de_dust4", true ); // Case 9

        g_test_isToUseStrictValidMaps = false;
    }

    /**
     * Create one case test for the stock isAllowedValidMapByTheUnitTests(1) based on its parameters passed
     * by the test_strictValidMapsTrie_load(0) loader function.
     */
    stock test_strictValidMapsTrie( mapName[], bool:isNotToBe = false )
    {
        new test_id = test_registerSeriesNaming( "test_strictValidMapsTrie", 'a' );
        new errorMessage[ MAX_LONG_STRING ];

        formatex( errorMessage, charsmax( errorMessage ), "The map `%s` must %sto be loaded on the trie.",
                mapName, isNotToBe ? "not " : "" );
        SET_TEST_FAILURE( test_id, TrieKeyExists( g_test_strictValidMapsTrie, mapName ) == isNotToBe, errorMessage )
    }

    /**
     * To prepare the test_populateListOnSeries_load1(0) tests files and settings.
     */
    stock test_populateListOnSeries_build( cursorOnMapSeries, Array:populatedArray, Trie:populatedTrie, expectedSize )
    {
        new test_id = test_registerSeriesNaming( "test_populateListOnSeries", 'e' );

        helper_mapFileListLoad( false, g_test_voteMapFilePath, "de_dust1", "de_dust2", "de_nuke", "de_dust2" );
        helper_loadStrictValidMapsTrie( "de_dust1", "de_dust2", "de_dust5", "de_dust6", "de_nuke" );

        // Set the settings accordantly to what is being tests on this Unit Test.
        set_pcvar_num( cvar_serverMoveCursor, cursorOnMapSeries );

        new errorMessage[ MAX_LONG_STRING ];
        new mapCount = map_populateListOnSeries( populatedArray, populatedTrie, g_test_voteMapFilePath );

        for( new index = 0; index < ArraySize( populatedArray ); index++ )
        {
            ArrayGetString( populatedArray, index, errorMessage, charsmax( errorMessage ) );
            LOGGER( 1, "populatedArray index: %d, mapName: %s", index, errorMessage )
        }

        formatex( errorMessage, charsmax( errorMessage ), "The map populatedArray size must to be %d, instead of %d.",
                expectedSize, mapCount );
        SET_TEST_FAILURE( test_id, mapCount != expectedSize, errorMessage )
    }

    /**
     * Tests if the function map_populateListOnSeries(3) is properly loading the maps series.
     */
    stock test_populateListOnSeries_load1()
    {
        new Trie:populatedTrie   = TrieCreate();
        new Array:populatedArray = ArrayCreate( MAX_MAPNAME_LENGHT );

        g_test_isToUseStrictValidMaps = true;
        test_populateListOnSeries_build( 1, populatedArray, populatedTrie, 7 ); // Case 1

        test_populateListOnSeries( populatedArray, {0}    , "de_dust1", false ); // Case 2
        test_populateListOnSeries( populatedArray, {1,4,6}, "de_dust2", false ); // Case 3
        test_populateListOnSeries( populatedArray, {2}    , "de_dust5", false ); // Case 4
        test_populateListOnSeries( populatedArray, {3}    , "de_dust6", false ); // Case 5
        test_populateListOnSeries( populatedArray, {5}    , "de_nuke" , false ); // Case 6

        test_populateListOnSeries( populatedArray, _      , "de_nuke2", true  ); // Case 7
        test_populateListOnSeries( populatedArray, _      , "de_dust" , true  ); // Case 8
        test_populateListOnSeries( populatedArray, _      , "de_dust3", true  ); // Case 9
        test_populateListOnSeries( populatedArray, _      , "de_dust4", true  ); // Case 10

        TrieDestroy( populatedTrie );
        ArrayDestroy( populatedArray );

        g_test_isToUseStrictValidMaps = false;
    }

    /**
     * Tests if the function map_populateListOnSeries(3) is properly loading the maps series.
     */
    stock test_populateListOnSeries_load2()
    {
        new Trie:populatedTrie   = TrieCreate();
        new Array:populatedArray = ArrayCreate( MAX_MAPNAME_LENGHT );

        g_test_isToUseStrictValidMaps = true;
        test_populateListOnSeries_build( 2, populatedArray, populatedTrie, 11 ); // Case 11

        test_populateListOnSeries( populatedArray, {0}     , "de_dust1", false ); // Case 12
        test_populateListOnSeries( populatedArray, {1,4, 8}, "de_dust2", false ); // Case 13
        test_populateListOnSeries( populatedArray, {2,5, 9}, "de_dust5", false ); // Case 14
        test_populateListOnSeries( populatedArray, {3,6,10}, "de_dust6", false ); // Case 15
        test_populateListOnSeries( populatedArray, {7}     , "de_nuke" , false ); // Case 16

        test_populateListOnSeries( populatedArray, _       , "de_nuke2", true  ); // Case 17
        test_populateListOnSeries( populatedArray, _       , "de_dust" , true  ); // Case 18
        test_populateListOnSeries( populatedArray, _       , "de_dust3", true  ); // Case 19
        test_populateListOnSeries( populatedArray, _       , "de_dust4", true  ); // Case 20

        g_test_isToUseStrictValidMaps = false;

        TrieDestroy( populatedTrie );
        ArrayDestroy( populatedArray );
    }

    /**
     * Tests if the function map_populateListOnSeries(3) is properly loading the maps series.
     */
    stock test_populateListOnSeries_load3()
    {
        new Trie:populatedTrie   = TrieCreate();
        new Array:populatedArray = ArrayCreate( MAX_MAPNAME_LENGHT );

        g_test_isToUseStrictValidMaps = true;
        test_populateListOnSeries_build( 6, populatedArray, populatedTrie, 7 ); // Case 1

        test_populateListOnSeries( populatedArray, {0}    , "de_dust1", false ); // Case 2
        test_populateListOnSeries( populatedArray, {1,4,6}, "de_dust2", false ); // Case 3
        test_populateListOnSeries( populatedArray, {2}    , "de_dust5", false ); // Case 4
        test_populateListOnSeries( populatedArray, {3}    , "de_dust6", false ); // Case 5
        test_populateListOnSeries( populatedArray, {5}    , "de_nuke" , false ); // Case 6

        test_populateListOnSeries( populatedArray, _      , "de_nuke2", true  ); // Case 7
        test_populateListOnSeries( populatedArray, _      , "de_dust" , true  ); // Case 8
        test_populateListOnSeries( populatedArray, _      , "de_dust3", true  ); // Case 9
        test_populateListOnSeries( populatedArray, _      , "de_dust4", true  ); // Case 10

        TrieDestroy( populatedTrie );
        ArrayDestroy( populatedArray );

        g_test_isToUseStrictValidMaps = false;
    }

    /**
     * Create one case test for the stock map_populateListOnSeries(3) based on its parameters passed
     * by the test_populateListOnSeries_load1(0) loader function.
     */
    stock test_populateListOnSeries( Array:populatedArray, expectedIndexes[]={0}, mapName[], bool:isNotToBe = false  )
    {
        new test_id = test_registerSeriesNaming( "test_populateListOnSeries", 'e' );

        new expectedIndex;
        new bool:isOnTheArray;
        new errorMessage[ MAX_LONG_STRING ];

        for( new index = 0; index < ArraySize( populatedArray ); index++ )
        {
            GET_MAP_NAME( populatedArray, index, errorMessage )

            if( equali( errorMessage, mapName ) != 0 )
            {
                isOnTheArray = true;

                formatex( errorMessage, charsmax( errorMessage ), "The map `%s` must be at the index %d, instead of %d.",
                        mapName, expectedIndexes[ expectedIndex ], index );
                SET_TEST_FAILURE( test_id, index != expectedIndexes[ expectedIndex ], errorMessage )

                ++expectedIndex;
            }
        }

        formatex( errorMessage, charsmax( errorMessage ), "The map `%s` must %sto be loaded on the array.",
                mapName, isNotToBe ? "not " : "" );
        SET_TEST_FAILURE( test_id, isOnTheArray == isNotToBe, errorMessage )
    }

    /**
     * Tests if the function map_populateListOnSeries(3) is properly loading the maps series.
     */
    stock test_GET_MAP_NAME_load()
    {
        new Array:populatedArray = ArrayCreate( MAX_MAPNAME_LENGHT );

        ArrayPushString( populatedArray, "de_dust1 bute by" );
        ArrayPushString( populatedArray, "de_dust2" );
        ArrayPushString( populatedArray, "de_nuke" );
        ArrayPushString( populatedArray, "cs_office data" );

        test_GET_MAP_NAME( populatedArray, 0, "de_dust1" , "bute by" ); // Case 1
        test_GET_MAP_NAME( populatedArray, 1, "de_dust2" , ""        ); // Case 3
        test_GET_MAP_NAME( populatedArray, 2, "de_nuke"  , ""        ); // Case 5
        test_GET_MAP_NAME( populatedArray, 3, "cs_office", "data"    ); // Case 7

        ArrayDestroy( populatedArray );
    }

    /**
     * Create one case test for the macros GET_MAP_NAME(3) and GET_MAP_INFO(3), based on its parameters
     * passed by the test_GET_MAP_NAME_load(0) loader function.
     */
    stock test_GET_MAP_NAME( Array:populatedArray, index, mapNameExpected[], mapInfoExpected[] )
    {
        new test_id;
        new mapName     [ MAX_MAPNAME_LENGHT ];
        new errorMessage[ MAX_LONG_STRING ];

        test_id = test_registerSeriesNaming( "test_GET_MAP_NAME", 'd' ); // Case 1
        GET_MAP_NAME( populatedArray, index, mapName )

        formatex( errorMessage, charsmax( errorMessage ), "The map name must to be %s, instead of %s.",
                mapNameExpected, mapName );
        SET_TEST_FAILURE( test_id, !equali( mapName, mapNameExpected ), errorMessage )

        test_id = test_registerSeriesNaming( "test_GET_MAP_NAME", 'd' ); // Case 2
        GET_MAP_INFO( populatedArray, index, mapName )

        formatex( errorMessage, charsmax( errorMessage ), "The map info must to be %s, instead of %s.",
                mapInfoExpected, mapName );
        SET_TEST_FAILURE( test_id, !equali( mapName, mapInfoExpected ), errorMessage )
    }

    /**
     * Tests if menu maps informations are being properly loaded into a normal/usual map voting menu.
     */
    stock test_GET_MAP_INFO_load()
    {
        // Enable all settings and to perform the configuration loading
        set_pcvar_string( cvar_voteMapFilePath          , g_test_voteMapFilePath    );
        set_pcvar_string( cvar_voteWhiteListMapFilePath , g_test_whiteListFilePath  );
        set_pcvar_string( cvar_voteMinPlayersMapFilePath, g_test_minPlayersFilePath );

        set_pcvar_num( cvar_whitelistMinPlayers  , 1 );
        set_pcvar_num( cvar_voteMinPlayers       , 2 );
        set_pcvar_num( cvar_isWhiteListNomBlock  , 0 );
        set_pcvar_num( cvar_isWhiteListBlockOut  , 0 );
        set_pcvar_num( cvar_nomMinPlayersControl , 2 );
        set_pcvar_num( cvar_nomPlayerAllowance   , 2 );
        set_pcvar_num( cvar_voteMapChoiceCount   , 5 );
        set_pcvar_num( cvar_nomQtyUsed           , 0 );

        cacheCvarsValues();

        // If 'g_test_aimedPlayersNumber < cvar_voteMinPlayers', enables the minimum players feature.
        g_test_aimedPlayersNumber = 5;

        helper_mapFileListLoad( false, g_test_voteMapFilePath   , "de_dust1 info1", "de_dust2noInfo", "de_dust2 info1 info2" );
        helper_mapFileListLoad( false, g_test_minPlayersFilePath, "de_rats"       , "de_train" );
        helper_mapFileListLoad( false, g_test_whiteListFilePath , "[0-23]"        , "de_rats", "de_train" );

        // To force the Whitelist to be reloaded.
        loadMapFiles();
        loadTheWhiteListFeature();
        loadTheDefaultVotingChoices();

        printVotingMaps( g_votingMapNames, g_votingMapInfos );

        test_GET_MAP_INFO( "de_dust1"       , "info1", true  );   // Case 1
        test_GET_MAP_INFO( "de_dust1"       , "info1", true  );   // Case 3
        test_GET_MAP_INFO( "de_dust2noInfo" , ""     , true  );   // Case 5
        test_GET_MAP_INFO( "de_dust2noInfo2", "Info" , false );   // Case 7
        test_GET_MAP_INFO( "de_dust"        , "info" , false );   // Case 9
    }

    /**
     * Checks whether the voting menu is properly loaded given some maps.
     *
     * @param requiredMap      a map name to be on the menu
     * @param requiredInfo     a map info to be on the menu
     * @param toBe             true if the information should be present, false otherwise
     */
    stock test_GET_MAP_INFO( requiredMap[], requiredInfo[], bool:toBe )
    {
        new test_id;

        test_id = test_registerSeriesNaming( "test_GET_MAP_INFO", 'a' ); // Case 1
        test_GET_MAP_INFO_check( test_id, requiredMap , true , toBe );

        test_id = test_registerSeriesNaming( "test_GET_MAP_INFO", 'a' ); // Case 2
        test_GET_MAP_INFO_check( test_id, requiredInfo, false, toBe );
    }

    /**
     * @see test_GET_MAP_INFO(2).
     */
    stock test_GET_MAP_INFO_check( test_id, textToCheck[], bool:is, bool:toBe )
    {
        new bool:isMapPresent;
        new      currentIndex;
        new      errorMessage[ MAX_LONG_STRING ];

        if( textToCheck[ 0 ] )
        {
            if( is )
            {
                for( currentIndex = 0; currentIndex < sizeof g_votingMapNames; ++currentIndex )
                {
                    if( equali( g_votingMapNames[ currentIndex ], textToCheck ) )
                    {
                        isMapPresent = true;
                    }
                }
            }
            else
            {
                for( currentIndex = 0; currentIndex < sizeof g_votingMapInfos; ++currentIndex )
                {
                    if( equali( g_votingMapInfos[ currentIndex ], textToCheck ) )
                    {
                        isMapPresent = true;
                    }
                }
            }

            formatex( errorMessage, charsmax( errorMessage ),
                    "The %s '%s' must %sto be present on the voting map menu.", is ? "name" : "info", textToCheck, toBe ? "" : "not " );
            SET_TEST_FAILURE( test_id, isMapPresent != toBe, errorMessage )
        }
    }

    /**
     * Tests if the function SortCustomSynced2D(3) is properly sorting the maps.
     */
    stock test_SortCustomSynced2D()
    {
        new expected    [ MAX_MAPNAME_LENGHT ];
        new errorMessage[ MAX_LONG_STRING    ];

        new position;
        new test_id = test_registerSeriesNaming( "test_SortCustomSynced2D", 'd' );

        new votingMaps[ MAX_OPTIONS_IN_VOTE ][ MAX_MAPNAME_LENGHT ];
        new votingInfo[ MAX_OPTIONS_IN_VOTE ][ MAX_MAPNAME_LENGHT ];

        copy( votingMaps[ 0 ], charsmax( votingMaps[] ), "de_dust2" );
        copy( votingMaps[ 1 ], charsmax( votingMaps[] ), "de_dust1" );
        copy( votingMaps[ 2 ], charsmax( votingMaps[] ), "de_nuke"  );
        copy( votingMaps[ 3 ], charsmax( votingMaps[] ), "cs_nuke"  );

        copy( votingInfo[ 0 ], charsmax( votingInfo[] ), " []"         );
        copy( votingInfo[ 1 ], charsmax( votingInfo[] ), "() de_dust1" );
        copy( votingInfo[ 2 ], charsmax( votingInfo[] ), "de_nuke"     );
        copy( votingInfo[ 3 ], charsmax( votingInfo[] ), "[ cs_nuke ]" );

        SortCustomSynced2D( votingMaps, votingInfo, 4 );

        position = 0;
        copy( expected, charsmax( expected ), "cs_nuke" );
        formatex( errorMessage, charsmax( errorMessage ),
                 "The position %d must to be %s, instead of %s.", position, expected, votingMaps[ position ] );
        SET_TEST_FAILURE( test_id, !equali( expected, votingMaps[ position ] ), errorMessage )

        position = 1;
        copy( expected, charsmax( expected ), "de_dust1" );
        formatex( errorMessage, charsmax( errorMessage ),
                 "The position %d must to be %s, instead of %s.", position, expected, votingMaps[ position ] );
        SET_TEST_FAILURE( test_id, !equali( expected, votingMaps[ position ] ), errorMessage )

        position = 2;
        copy( expected, charsmax( expected ), "de_dust2" );
        formatex( errorMessage, charsmax( errorMessage ),
                 "The position %d must to be %s, instead of %s.", position, expected, votingMaps[ position ] );
        SET_TEST_FAILURE( test_id, !equali( expected, votingMaps[ position ] ), errorMessage )

        position = 3;
        copy( expected, charsmax( expected ), "de_nuke" );
        formatex( errorMessage, charsmax( errorMessage ),
                 "The position %d must to be %s, instead of %s.", position, expected, votingMaps[ position ] );
        SET_TEST_FAILURE( test_id, !equali( expected, votingMaps[ position ] ), errorMessage )
    }




    // Here below to start the manual Unit Tests
    // ###########################################################################################

    /**
     * Calls the 'test_loadVoteChoices_load(1)' series case 'a' for manual testing, and seeing the
     * outputted string by 'announceVoteBlockedMap(4)'.
     */
    stock test_announceVoteBlockedMap_a()
    {
        test_loadVoteChoices_load();
        test_loadVoteChoices_serie( 'a' );
    }

    /**
     * Calls the 'test_loadVoteChoices_load(1)' series case 'c' for manual testing.
     *
     * @see test_announceVoteBlockedMap_a(0).
     */
    stock test_announceVoteBlockedMap_c()
    {
        test_loadVoteChoices_load();
        test_loadVoteChoices_serie( 'c' );
    }

    /**
     * Create some nominations the force to remove them by the 'unnominatedDisconnectedPlayer(1)',
     * for manual testing.
     */
    stock test_unnominatedDisconnected( player_id )
    {
        helper_clearNominationsData();
        set_pcvar_num( cvar_nomPlayerAllowance, 9 );

        helper_unnominated_nomsLoad( player_id, "de_dust2002v2005_forEver2009", "de_dust2002v2005_forEver2010",
                                              "de_dust2002v2005_forEver2011", "de_dust2002v2005_forEver2012",
                                              "de_dust2002v2005_forEver2013", "de_dust2002v2005_forEver2014",
                                              "de_dust2002v2005_forEver2015", "de_dust2002v2005_forEver2016" );

        unnominatedDisconnectedPlayer( player_id );
    }

    /**
     * Manual test for the maximum chat message send to the server players.
     */
    stock test_colorChatLimits( player_id )
    {
        new const string[] = "ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ \
                ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ \
                ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ \
                ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ";

        color_print( 0, string );
        color_print( player_id, string );

        new formats[ MAX_BIG_BOSS_STRING ];
        copy( formats, charsmax( formats ), "My big formatter: %s" );

        color_print( 0, formats, string );
        color_print( player_id, formats, string );
    }




    // Here below to start the server changed cvars backups to be restored after the unit tests end.
    // ###########################################################################################

    new Float:test_extendMapMaximum;
    new Float:test_mp_timelimit;
    new Float:test_rtvRatio;

    new test_mp_winlimit;
    new test_mp_maxrounds;
    new test_mp_fraglimit;
    new test_serverTimeLimitRestart;
    new test_serverWinlimitRestart;
    new test_serverMaxroundsRestart;
    new test_serverFraglimitRestart;
    new test_whitelistMinPlayers;
    new test_isWhiteListNomBlock;
    new test_isWhiteListBlockOut;
    new test_voteMinPlayers;
    new test_NomMinPlayersControl;
    new test_nomQtyUsed;
    new test_voteMapChoiceCount;
    new test_nomPlayerAllowance;
    new test_nextMapChangeVotemap;
    new test_endOfMapVoteStart;
    new test_nomCleaning;
    new test_serverMoveCursor;
    new test_mp_fraglimitCvarSupport;

    new test_nomMapFilePath           [ MAX_FILE_PATH_LENGHT ];
    new test_voteMapFilePath          [ MAX_FILE_PATH_LENGHT ];
    new test_voteWhiteListMapFilePath [ MAX_FILE_PATH_LENGHT ];
    new test_voteMinPlayersMapFilePath[ MAX_FILE_PATH_LENGHT ];

    /**
     * Every time a cvar is changed during the tests, it must be saved here to a global test variable
     * to be restored at the 'restoreServerCvarsFromTesting(0)', which is executed at the end of all
     * tests execution.
     *
     * This is executed before the first rest run.
     */
    stock saveServerCvarsForTesting()
    {
        LOGGER( 128, "I AM ENTERING ON saveServerCvarsForTesting(0)" )
        LOGGER( 2, "    %38s cvar_mp_timelimit: %f  test_mp_timelimit: %f   g_originalTimelimit: %f", \
                "saveServerCvarsForTesting( in )", get_pcvar_float( cvar_mp_timelimit ), test_mp_timelimit, g_originalTimelimit )

        if( !g_test_isTheUnitTestsRunning )
        {
            g_test_isToDisableLogging    = true;
            g_test_isTheUnitTestsRunning = true;

            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "    Executing the %s's Unit Tests: ", PLUGIN_NAME );
            print_logger( "" );
            print_logger( "" );

            cleanTheUnitTestsData();
            saveCurrentTestsTimeStamp();

            get_pcvar_string( cvar_nomMapFilePath, test_nomMapFilePath, charsmax( test_nomMapFilePath ) );
            get_pcvar_string( cvar_voteMapFilePath, test_voteMapFilePath, charsmax( test_voteMapFilePath ) );
            get_pcvar_string( cvar_voteWhiteListMapFilePath, test_voteWhiteListMapFilePath, charsmax( test_voteWhiteListMapFilePath ) );
            get_pcvar_string( cvar_voteMinPlayersMapFilePath, test_voteMinPlayersMapFilePath, charsmax( test_voteMinPlayersMapFilePath ) );

            test_rtvRatio                = get_pcvar_float( cvar_rtvRatio             );
            test_extendMapMaximum        = get_pcvar_float( cvar_maxMapExtendTime     );
            test_mp_timelimit            = get_pcvar_float( cvar_mp_timelimit         );

            test_mp_winlimit             = get_pcvar_num( cvar_mp_winlimit            );
            test_mp_maxrounds            = get_pcvar_num( cvar_mp_maxrounds           );
            test_mp_fraglimit            = get_pcvar_num( cvar_mp_fraglimit           );
            test_serverTimeLimitRestart  = get_pcvar_num( cvar_serverTimeLimitRestart );
            test_serverWinlimitRestart   = get_pcvar_num( cvar_serverWinlimitRestart  );
            test_serverMaxroundsRestart  = get_pcvar_num( cvar_serverMaxroundsRestart );
            test_serverFraglimitRestart  = get_pcvar_num( cvar_serverFraglimitRestart );

            test_whitelistMinPlayers     = get_pcvar_num( cvar_whitelistMinPlayers    );
            test_isWhiteListNomBlock     = get_pcvar_num( cvar_isWhiteListNomBlock    );
            test_isWhiteListBlockOut     = get_pcvar_num( cvar_isWhiteListBlockOut    );
            test_voteMinPlayers          = get_pcvar_num( cvar_voteMinPlayers         );
            test_NomMinPlayersControl    = get_pcvar_num( cvar_nomMinPlayersControl   );
            test_nomQtyUsed              = get_pcvar_num( cvar_nomQtyUsed             );
            test_voteMapChoiceCount      = get_pcvar_num( cvar_voteMapChoiceCount     );
            test_nomPlayerAllowance      = get_pcvar_num( cvar_nomPlayerAllowance     );
            test_nextMapChangeVotemap    = get_pcvar_num( cvar_nextMapChangeVotemap   );
            test_endOfMapVoteStart       = get_pcvar_num( cvar_endOfMapVoteStart      );
            test_nomCleaning             = get_pcvar_num( cvar_nomCleaning            );
            test_serverMoveCursor        = get_pcvar_num( cvar_serverMoveCursor       );
            test_mp_fraglimitCvarSupport = get_pcvar_num( cvar_fragLimitSupport       );
        }
    }

    /**
     * This is executed after all tests executions, to restore the server variables changes.
     */
    stock restoreServerCvarsFromTesting()
    {
        LOGGER( 128, "I AM ENTERING ON restoreServerCvarsFromTesting(0)" )
        LOGGER( 2, "    %38s cvar_mp_timelimit: %f  test_mp_timelimit: %f  g_originalTimelimit: %f", \
                "restoreServerCvarsFromTesting( in )", get_pcvar_float( cvar_mp_timelimit ), test_mp_timelimit, g_originalTimelimit )

        if( g_test_isTheUnitTestsRunning )
        {
            map_restoreEndGameCvars();
            g_test_isTheUnitTestsRunning   = false;

            g_originalTimelimit = 0.0;
            g_originalMaxRounds = 0;
            g_originalWinLimit  = 0;
            g_originalFragLimit = 0;

            tryToSetGameModCvarFloat( cvar_mp_timelimit     , test_mp_timelimit              );

            tryToSetGameModCvarNum( cvar_mp_winlimit        , test_mp_winlimit               );
            tryToSetGameModCvarNum( cvar_mp_maxrounds       , test_mp_maxrounds              );
            tryToSetGameModCvarNum( cvar_mp_fraglimit       , test_mp_fraglimit              );

            set_pcvar_string( cvar_nomMapFilePath           , test_nomMapFilePath            );
            set_pcvar_string( cvar_voteMapFilePath          , test_voteMapFilePath           );
            set_pcvar_string( cvar_voteWhiteListMapFilePath , test_voteWhiteListMapFilePath  );
            set_pcvar_string( cvar_voteMinPlayersMapFilePath, test_voteMinPlayersMapFilePath );

            set_pcvar_float( cvar_rtvRatio             , test_rtvRatio         );
            set_pcvar_float( cvar_maxMapExtendTime     , test_extendMapMaximum );

            set_pcvar_num( cvar_serverTimeLimitRestart , test_serverTimeLimitRestart );
            set_pcvar_num( cvar_serverWinlimitRestart  , test_serverWinlimitRestart  );
            set_pcvar_num( cvar_serverMaxroundsRestart , test_serverMaxroundsRestart );
            set_pcvar_num( cvar_serverFraglimitRestart , test_serverFraglimitRestart );

            set_pcvar_num( cvar_whitelistMinPlayers    , test_whitelistMinPlayers     );
            set_pcvar_num( cvar_isWhiteListNomBlock    , test_isWhiteListNomBlock     );
            set_pcvar_num( cvar_isWhiteListBlockOut    , test_isWhiteListBlockOut     );
            set_pcvar_num( cvar_voteMinPlayers         , test_voteMinPlayers          );
            set_pcvar_num( cvar_nomMinPlayersControl   , test_NomMinPlayersControl    );
            set_pcvar_num( cvar_nomQtyUsed             , test_nomQtyUsed              );
            set_pcvar_num( cvar_voteMapChoiceCount     , test_voteMapChoiceCount      );
            set_pcvar_num( cvar_nomPlayerAllowance     , test_nomPlayerAllowance      );
            set_pcvar_num( cvar_nextMapChangeVotemap   , test_nextMapChangeVotemap    );
            set_pcvar_num( cvar_endOfMapVoteStart      , test_endOfMapVoteStart       );
            set_pcvar_num( cvar_nomCleaning            , test_nomCleaning             );
            set_pcvar_num( cvar_serverMoveCursor       , test_serverMoveCursor        );
            set_pcvar_num( cvar_fragLimitSupport       , test_mp_fraglimitCvarSupport );
        }

        // Clear tests results.
        resetRoundsScores();
        cancelVoting();
        g_totalRoundsSavedTimes = 0;

        // Reload unloaded features.
        loadMapFiles();
        loadNominationList();
        loadTheWhiteListFeature();

        // Clean tests files.
        delete_file( g_test_voteMapFilePath );
        delete_file( g_test_whiteListFilePath );
        delete_file( g_test_minPlayersFilePath );

        LOGGER( 2, "    %38s cvar_mp_timelimit: %f  test_mp_timelimit: %f  g_originalTimelimit: %f", \
                "restoreServerCvarsFromTesting( out )", get_pcvar_float( cvar_mp_timelimit ), test_mp_timelimit, g_originalTimelimit )

        // Only to disable the Unit Tests running, after all the print being outputted due the `DEBUG_LEVEL_DISABLE_TEST_LOGS` level.
        g_test_isToDisableLogging = false;
    }
#endif


