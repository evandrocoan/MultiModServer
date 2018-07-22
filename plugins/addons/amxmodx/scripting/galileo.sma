/*********************** Licensing *******************************************************
*
*   Copyright 2008-2010 @ Brad Jones
*   Copyright 2015-2018 @ Addons zz
*   Copyright 2004-2017 @ AMX Mod X Development Team
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
new const PLUGIN_VERSION[] = "v5.9.1-926";

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
 * and the variable 'g_debug_level' for more information. Usage example, to enable several levels:
 * #define DEBUG_LEVEL 1+2+4+16
 *
 * @note when the 'DEBUG_LEVEL_FAKE_VOTES' is activated, usually the voting will be approved
 * because it creates also a fake players count. So, do not enable 'DEBUG_LEVEL_FAKE_VOTES'
 * if you do not want the map voting starting on an empty server.
 *
 * 0   - Disables this feature.
 *
 * 1   - Normal/basic debugging/depuration.
 *
 * 2   - Run the NORMAL Unit Tests on the server start.
 *
 * 4   - Run the DELAYED Unit Tests on the server start.
 *
 * 8   - a) To create fake votes. See the function 'create_fakeVotes()'.
 *       b) Set the vote time to 5 seconds.
 *       c) To skip the 'pendingVoteCountdown()'.
 *       d) To create fake players count. See the function 'get_real_players_number()'.
 *
 * 16  - Enable DEBUG_LEVEL 1 and all its debugging/depuration available.
 *
 * 32  - Run the MANUAL test on server start.
 *
 * 64  - Disable the LOG() while running the Unit Tests.
 *
 * 127 - Enable the levels 1, 2, 4, 8, 16, 32 and 64.
 *
 * Default value: 0
 */
#define DEBUG_LEVEL 0


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
 * Some times we need to run a different code when performing Unit Tests as unnecessary delays.
 */
#define ARE_WE_RUNNING_UNIT_TESTS \
    ( DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED ) )

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
    new bool:g_test_areTheUnitTestsRunning;

    /**
     * Allow the Manual Unit Tests to disable LOG() debugging messages when the level
     * DEBUG_LEVEL_DISABLE_TEST_LOGS is enabled. Initialize it with true to allow the server to be
     * logging from its first start.
     */
    new bool:g_test_isToEnableLogging = true;

    /**
     * Write messages to the debug log file on 'addons/amxmodx/logs'.
     *
     * @param log_file               the log file name.
     * @param formatted_message       the formatted message to write down to the debug log file.
     */
    stock writeToTheDebugFile( const log_file[], const formatted_message[] )
    {
        new currentTime;
        static lastRun;

        currentTime = tickcount();

        log_to_file( log_file, "{%.3f %d %5d %4d} %s", get_gametime(), heapspace(), currentTime, currentTime - lastRun, formatted_message );
        lastRun = currentTime;

        // Removes the compiler warning `warning 203: symbol is never used` with some DEBUG levels.
        if( g_test_areTheUnitTestsRunning && g_test_isToEnableLogging && DEBUGGER_OUTPUT_LOG_FILE_NAME[0] ) { }
    }
#endif

/**
 * Setup the debugging tools when they are used/necessary.
 */
#if DEBUG_LEVEL & ( DEBUG_LEVEL_NORMAL | DEBUG_LEVEL_CRITICAL_MODE )
    #define DEBUG
    #define LOG(%1) debugMesssageLogger( %1 );

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
     *        c) Actions at startTheVoting(1).
     *
     * 16   - Runoff voting.
     *
     * 32   - Rounds end map voting.
     *
     * 64   - Debug for the color_chat(...) function.
     *
     * 128  - Functions entrances messages.
     *
     * 256  - High called functions calls.
     *
     * 511  - Enables all debug logging levels.
     */
    new g_debug_level = 1+128;

    /**
     * Write debug messages accordantly with the 'g_debug_level' variable.
     *
     * @param mode the debug mode level, see the variable 'g_debug_level' for the levels.
     * @param text the debug message, if omitted its default value is ""
     * @param any the variable number of formatting parameters
     *
     * @see the stock writeToTheDebugFile( log_file[], formatted_message[] ) for the output log
     *      'DEBUGGER_OUTPUT_LOG_FILE_NAME'.
     */
    stock debugMesssageLogger( const mode, const message[] = "", any:... )
    {
        if( mode & g_debug_level )
        {
        #if DEBUG_LEVEL & DEBUG_LEVEL_DISABLE_TEST_LOGS
            if( g_test_isToEnableLogging )
            {
                static formatted_message[ MAX_BIG_BOSS_STRING ];
                vformat( formatted_message, charsmax( formatted_message ), message, 3 );

                writeToTheDebugFile( DEBUGGER_OUTPUT_LOG_FILE_NAME, formatted_message );
            }
        #else
            static formatted_message[ MAX_BIG_BOSS_STRING ];
            vformat( formatted_message, charsmax( formatted_message ), message, 3 );

            writeToTheDebugFile( DEBUGGER_OUTPUT_LOG_FILE_NAME, formatted_message );
        #endif
        }
    }
#else
    #define LOG(%1)

#endif



// Unit Tests Main Definitions
// ###############################################################################################

/**
 * Setup the Unit Tests when they are used/necessary.
 */
#if ARE_WE_RUNNING_UNIT_TESTS
    /**
     * Contains all imediates unit tests to execute.
     */
    stock normalTestsToExecute()
    {
        LOG( 128, "I AM ENTERING ON normalTestsToExecute(0)" )

        test_registerTest();
        test_isInEmptyCycle();
        test_mapGetNext_cases();
        test_loadCurrentBlackList_cases();
        test_resetRoundsScores_cases();
        test_loadVoteChoices_cases();
        test_nominateAndUnnominate_load();
        test_RTVAndUnRTV_load();
        test_negativeRTVValues_load();
        test_getUniqueRandomBasic_load();
        test_getUniqueRandomInt_load();
        test_whatGameEndingTypeIt_load();
        test_convertNumericBase_load();
        test_setCorrectMenuPage_load();
        test_strictValidMapsTrie_load();
        test_populateListOnSeries_load();
        test_GET_MAP_NAME_load();
        test_GET_MAP_INFO_load();
        test_SortCustomSynced2D();
        test_configureTheNextMap();
        test_handleServerStart();
        test_endOfMapVoting();
    }

    /**
     * Contains all delayed unit tests to execute.
     */
    public dalayedTestsToExecute()
    {
        LOG( 128, "I AM ENTERING ON dalayedTestsToExecute(0)" )
        // Currently there are none Delayed Unit Tests Created.
    }

    /**
     * Run the manual call Unit Tests, by 'say run' and 'say_team run'.
     */
    public inGameTestsToExecute( player_id )
    {
        LOG( 128, "I AM ENTERING ON inGameTestsToExecute(1) player_id: %d", player_id )

        // Save the game cvars?
        if( !g_test_areTheUnitTestsRunning ) saveServerCvarsForTesting();

        for( new i = 0; i < 1000; i++ )
        {
            for( new i = 0; i < 1000; i++ )
            {
            }

            // LOG( 1, "Current i is: %d", i )
        }

        // test_RTVAndUnRTV_load();
        // test_negativeRTVValues_load();
        // test_endOfMapVoting();
        // test_handleServerStart();
        // test_mapGetNext_cases();
        // test_configureTheNextMap();
        // test_loadCurrentBlackList_cases();
        // test_SortCustomSynced2D();
        // test_GET_MAP_INFO_load();
        // test_GET_MAP_NAME_load();
        test_populateListOnSeries_load();
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
        if( g_test_areTheUnitTestsRunning ) printTheUnitTestsResults();
    }

    /**
     * Wrapper to avoid passing a low used default parameter on the start of the function call.
     */
    #define HELPER_MAP_FILE_LIST_LOAD(%1) helper_mapFileListLoadReplace( false, %1 );
    #define HELPER_MAP_FILE_LIST_LOAD2(%1) helper_mapFileListLoadReplace2( false, %1 );

    /**
     * Accept all maps as valid while running the unit tests.
     */
    #define IS_MAP_VALID(%1) ( isAllowedValidMapByTheUnitTests(%1) || !g_test_isToUseStrictValidMaps && IS_MAP_VALID_BSP( %1 ) )

    /**
     * Shorts the error message line. It requires the variable `errorMessage[ MAX_LONG_STRING ]`
     * to be declared before it.
     *
     * Usage example:
     *
     *      ERR( "The expected result must to be %d, instead of %d.", expected, test_result )
     */
    #define ERR(%1) formatex( errorMessage, charsmax( errorMessage ), %1 );

    /**
     * Call the internal function to perform its task and stop the current test execution to avoid
     * double failure at the test control system. This is to be used instead of setTestFailure(1)
     * when 2 consecutive tests use the same `test_id`.
     *
     * @see also the stock setTestFailure(3)
     */
    #define SET_TEST_FAILURE(%1) \
    { \
        if( setTestFailure( %1 ) ) \
        { \
            LOG( 1, "    ( SET_TEST_FAILURE ) Just returning/blocking." ) \
            return; \
        } \
    }

    /**
     * Write debug messages to server's console and log file.
     *
     * @param message      the debug message, if omitted its default value is ""
     * @param any          the variable number of formatting parameters
     *
     * @see the also stock writeToTheDebugFile( log_file[], formatted_message[] ) for the output log
     *      `DEBUGGER_OUTPUT_LOG_FILE_NAME`.
     */
    stock print_logger( const message[] = "", any:... )
    {
        static formatted_message[ MAX_BIG_BOSS_STRING ];
        vformat( formatted_message, charsmax( formatted_message ), message, 2 );

        writeToTheDebugFile( DEBUGGER_OUTPUT_LOG_FILE_NAME, formatted_message );
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
 *
 * When we put the color tags inside the plugin, we need to check whether the color chat is enabled.
 */
#define IS_COLORED_CHAT_ENABLED() \
    ( g_isColorChatSupported \
      && g_isColoredChatEnabled )
//

/**
 * Accordingly to `https://wiki.alliedmods.net/Half-life_1_game_events#HLTV`, only some mods support
 * this game event.
 */
#define IS_NEW_ROUND_EVENT_SUPPORTED() \
    ( g_isColorChatSupported || g_isDayOfDefeat )
//

/**
 * The cvar `gal_colored_chat_enabled` to enable or disable the colored chat messages.
 */
new cvar_coloredChatEnabled;
new g_user_msgid;

/**
 * Switch between the AMXX 182 and 183 deprecated/bugged functions.
 */
#if AMXX_VERSION_NUM < 183
    #define str_token strtok
    #define str_break strbreak
#else
    #define str_token strtok2
    #define str_break argbreak
#endif

/**
 * General Constants for the cvar `gal_general_options` options.
 */
#define MUTE_MESSAGES_SPAMMING          1
#define VOTE_WAIT_FOR_ROUND_END         2
#define DO_NOT_ALPHABETIZE_VOTEMAP_MENU 4

#define MAX_INTEGER  2147483647
#define MIN_INTEGER -2147483648

#define LISTMAPS_USERID   0
#define LISTMAPS_LAST_MAP 1

#define COMMAND_VOTEMAP_DISABLED  1
#define COMMAND_LISTMAPS_DISABLED 1

#define RUNOFF_ENABLED 1
#define RUNOFF_EXTEND  2

#define VOTE_MININUM_PLAYERS_REQUIRED 1
#define VOTE_MIDDLE_PLAYERS_REQUIRED  2

#define FIRST_SERVER_START  2
#define SECOND_SERVER_START 1
#define AFTER_READ_MAPCYCLE 0

#define END_OF_MAP_VOTE_ASK             1
#define END_OF_MAP_VOTE_ANNOUNCE1       2
#define END_OF_MAP_VOTE_ANNOUNCE2       4
#define END_OF_MAP_VOTE_NO_ANNOUNCEMENT 8

#define VOTE_TIME_SEC       1.0
#define VOTE_TIME_HUD1      7.0
#define VOTE_TIME_HUD2      5.0
#define VOTE_TIME_ANNOUNCE1 10.0
#define VOTE_TIME_ANNOUNCE2 5.0
#define VOTE_TIME_RUNOFF    3.0
#define VOTE_TIME_COUNT     5.5

#define RTV_CMD_STANDARD               1
#define RTV_CMD_SHORTHAND              2
#define RTV_CMD_DYNAMIC                4
#define RTV_CMD_SINGLE_PLAYER_DISABLE  8
#define RTV_CMD_EXTENSION_WAIT_DISABLE 16

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
#define IS_TO_LOAD_ALTERNATE_MAP_SERIES 8

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

#define MAX_PREFIX_SIZE               16
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
 * The value used when the voting time is set to 0.
 */
#define INFINITY_VOTING_TIME_VALUE 20

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
#define MAX_SERVER_RESTART_ACCEPTABLE 1

/**
 * The rounds number before the mp_maxrounds/mp_winlimit to be reached to start the map voting. This
 * constant is equivalent to the `START_VOTEMAP_MIN_TIME` and `START_VOTEMAP_MAX_TIME` concepts.
 *
 * Make sure this is big enough, because the rounds could be finish pretty fast and the game may end
 * before it, as this option only takes effect and the `cvar_endOnRound` and `cvar_endOfMapVoteStart`
 * are not handling the map end.
 */
#define VOTE_START_ROUNDS ( IS_THE_ROUND_AVERAGE_TIME_TOO_SHORT() ? 10 : ( IS_THE_ROUND_AVERAGE_TIME_SHORT() ? 7 : 4 ) )

/**
 * Calculates whether to start the map voting due map closing time.
 *
 * @param fragsRemaining     how much frags are remaining to finish the map.
 */
#define IS_TO_START_THE_VOTE_BY_FRAGS(%1) ( %1 < ( g_fragLimitNumber > 30 ? 20 : 12 ) )

/**
 * The rounds number required to be reached to allow predict if this will be the last round and
 * allow to start the voting.
 */
#define MIN_ROUND_TIME_DELAY         10
#define FRAGS_BY_ROUND_AVERAGE       7
#define SECONDS_BY_ROUND_AVERAGE     70
#define MIN_VOTE_START_ROUNDS_DELAY  1
#define MAX_SAVED_ROUNDS_FOR_AVERAGE 5

/**
 * Every time an operation close to the call to map_manageEnd(0) need to be performed on the cvars
 * `mp_timelimit`, `mp_fraglimit`, `mp_maxrounds` and `mp_winlimit`, this macro must to be used to
 * retrieve the correct cvar value, otherwise it will probably get the value 0 and go nuts.
 */
#define GAME_ENDING_CONTEXT_SAVED(%1,%2) ( ( g_isGameEndingTypeContextSaved ) ? ( %1 ) : ( %2 ) )

/**
 * The periodic task created on 'configureServerStart(1)' use this intervals in seconds to
 * start checking for an end map voting start. Defines the interval where the periodic tasks
 * as map_manageEnd(0) and vote_manageEnd(0) will be checked.
 */
#define PERIODIC_CHECKING_INTERVAL 15
#define START_VOTEMAP_MIN_TIME     ( g_totalVoteTime + PERIODIC_CHECKING_INTERVAL + 3 )
#define START_VOTEMAP_MAX_TIME     ( g_totalVoteTime )



// In-place Macros
// ###############################################################################################

/**
 * Accept a map as valid, even when they end with `.bsp`.
 *
 * @param mapName the map name to check
 * @return true when the `mapName` is a valid engine map, false otherwise
 */
#define IS_MAP_VALID_BSP(%1) \
    ( is_map_valid( %1 ) || is_map_valid_bsp_check( %1 ) )
//

/**
 * If the cvar `gal_server_players_count` is enabled, we must ignore the spectators team on
 * Counter-Strike. If colored chat is supported, we are running Counter-Strike, therefore there are
 * the CT/TR teams.
 *
 * @return true if the spectators team must be ignored, false otherwise
 */
#define IS_TO_IGNORE_SPECTATORS() \
    ( g_isColorChatSupported \
      && get_pcvar_num( cvar_serverPlayersCount ) )
//

/**
 * Control whether the players commands are going to be displayed to everybody or just him.
 *
 * @param true if the message/command should be blocked (PLUGIN_HANDLED), false otherwise (PLUGIN_CONTINUE)
 * @return `PLUGIN_HANDLED` or `PLUGIN_CONTINUE`, accordantly to the settings set by the cvar
 */
#define IS_TO_MUTE(%1) \
    ( ( %1 && ( get_pcvar_num( cvar_generalOptions ) & MUTE_MESSAGES_SPAMMING ) ) ? PLUGIN_HANDLED : PLUGIN_CONTINUE )
//

/**
 * Determine whether there will be a alternate vote option as `Stay Here`/`Extend Map` or not.
 *
 * @return true when the map extension is allowed right now, false otherwise
 */
#define IS_MAP_EXTENSION_ALLOWED() \
    ( ( g_isMapExtensionAllowed && g_isGameFinalVoting ) \
      || ( g_isExtendmapAllowStay && !g_isGameFinalVoting ) )
//

/**
 * Determines whether a new empty line should be added near the voting menu footer.
 *
 * The last rule `g_totalVoteOptions == 1 && !g_isRunOffNeedingKeepCurrentMap` is used when the
 * voting is not an runoff voting, therefore there is only 1 map on the voting menu. At the moment,
 * this could happens when the voting is started by the `gal_votemap`/`say galmenu` command.
 *
 * @return true when a new line must be added, false otherwise
 */
#define IS_TO_ADD_VOTE_MENU_NEW_LINE() \
    ( ( g_voteStatus & IS_RUNOFF_VOTE ) \
      || !IS_MAP_EXTENSION_ALLOWED() \
      || ( g_totalVoteOptions == 1 \
           && !g_isRunOffNeedingKeepCurrentMap ) )
//

/**
 * Determines whether undo vote button should be added to the voting menu footer.
 *
 * @return true when the undo button must be added, false otherwise
 */
#define IS_TO_ADD_VOTE_MENU_UNDO_BUTTON() \
    ( ( player_id > 0 ) \
      && ( g_voteShowNoneOptionType == CONVERT_NONE_OPTION_TO_CANCEL_LAST_VOTE ) \
      && ( g_isPlayerVoted[ player_id ] ) \
      && ( !g_isPlayerCancelledVote[ player_id ] ) )
//

/**
 * When there are enough rounds played and the round average time is neither even half to the vote
 * total time, it is pretty pointless the try start the voting at the round start.
 *
 * @return true when the round average time is too small/low/short, false otherwise
 */
#define IS_THE_ROUND_AVERAGE_TIME_TOO_SHORT() \
    ( g_totalRoundsSavedTimes > MAX_SAVED_ROUNDS_FOR_AVERAGE - 2 \
      && g_roundAverageTime < g_totalVoteTime / 2 )
//

/**
 * When there are some rounds played and the round average time is just smaller than the to the vote
 * total time, we need to try start the voting at the round start on round before the actual point as
 * the voting will extend from one round to the other round.
 *
 * @return true when the round average time is just small/low/short, false otherwise
 */
#define IS_THE_ROUND_AVERAGE_TIME_SHORT() \
    ( g_totalRoundsSavedTimes > MIN_VOTE_START_ROUNDS_DELAY \
      && g_roundAverageTime < g_totalVoteTime )
//

/**
 * If this is called when the voting or the round ending is going on, it will cause the voting/round
 * ending to be cut and will force the map to immediately change to the next map.
 *
 * @return true when we can perform a map change, i.e, it is allowed right now, false otherwise
 */
#define IS_ABLE_TO_PERFORM_A_MAP_CHANGE() \
    ( !task_exists( TASKID_PROCESS_LAST_ROUND_COUNT ) \
      || !task_exists( TASKID_INTERMISSION_HOLD ) \
      || !( g_voteStatus & IS_VOTE_IN_PROGRESS ) \
      || !g_isTheRoundEndWhileVoting )
//

/**
 * This indicates the players minimum number necessary to allow the last round to be finished when
 * the time runs out.
 *
 * @return true when we must to wait for the round to end, false otherwise
 */
#define ARE_THERE_ENOUGH_PLAYERS_FOR_MANAGE_END() \
    ( get_real_players_number() >= get_pcvar_num( cvar_endOnRoundMininum ) )
//

/**
 * Specifies how much time to delay the voting start after the round start.
 *
 * @return an integer, how many seconds to wait
 */
#define ROUND_VOTING_START_SECONDS_DELAY() \
    ( get_pcvar_num( cvar_mp_freezetime ) + PERIODIC_CHECKING_INTERVAL \
      - ( get_pcvar_num( cvar_isToAskForEndOfTheMapVote ) & END_OF_MAP_VOTE_ANNOUNCE1 ? 5 : 0 ) \
      + ( g_roundAverageTime > 2 * g_totalVoteTime / 3 ? g_totalVoteTime / 5 : 1 ) )
//

/**
 * Verifies if a voting is or was already processed.
 *
 * @return true when the voting is completely finished or running on, false otherwise
 */
#define IS_END_OF_MAP_VOTING_GOING_ON() \
    ( g_voteStatus & ( IS_VOTE_IN_PROGRESS | IS_VOTE_OVER ) )
//

/**
 * Verifies if the round time is too big. If the map time is too big or near zero, makes not sense
 * to wait to start the map voting and will probably not to start the voting.
 *
 * @return true when the round time is too big/long/tall, false otherwise
 */
#define IS_THE_ROUND_TIME_TOO_BIG(%1) \
    ( ( %1 > 8.0 \
        && g_roundAverageTime > 300 ) \
      || %1 < 0.5 )
//

/**
 * Boolean check for the Whitelist feature. The Whitelist feature specifies the time where the maps
 * are allowed to be added to the voting list as fillers after the nominations being loaded.
 *
 * @return true when the Whitelist feature is enabled, false otherwise
 */
#define IS_WHITELIST_ENABLED() \
    ( get_pcvar_num( cvar_whitelistMinPlayers ) == 1 \
      || get_real_players_number() < get_pcvar_num( cvar_whitelistMinPlayers ) )
//

/**
 * Boolean check for the nominations minimum players controlling feature. When there are less
 * players than cvar 'cvar_voteMinPlayers' value on the server, use a different map file list
 * specified at the cvar 'gal_vote_minplayers_mapfile' to fill the map voting as map fillers
 * instead of the cvar 'gal_vote_mapfile' map file list.
 *
 * @return true when the Nomination Minimum Players feature is enabled, false otherwise
 */
#define IS_NOMINATION_MININUM_PLAYERS_CONTROL_ENABLED() \
    ( get_real_players_number() < get_pcvar_num( cvar_voteMinPlayers ) \
      && get_pcvar_num( cvar_nomMinPlayersControl ) )
//

/**
 * When it is set the maximum voting options as 9, we need to give space to the `Stay Here` and
 * `Extend` on the voting menu, calculating how many voting choices are allowed to be used,
 * considering whether the voting map extension option is being showed or not.
 *
 * @return an integer, how many voting choices are allowed, i.e., its maximum value
 */
#define MAX_VOTING_CHOICES() \
    ( IS_MAP_EXTENSION_ALLOWED() ? \
        ( g_maxVotingChoices >= MAX_OPTIONS_IN_VOTE ? \
            g_maxVotingChoices - 1 : g_maxVotingChoices ) : g_maxVotingChoices )
//

/**
 * Return whether is to allow a crash search on this server start or not.
 *
 * @return true when the crash map search is enabled/allowed, false otherwise
 */
#define IS_TO_ALLOW_A_CRASH_SEARCH(%1) \
    ( file_exists( modeFlagFilePath ) \
      && !( DEBUG_LEVEL & DEBUG_LEVEL_FAKE_VOTES ) )
//

/**
 * Used to determine whether a map is blocked by the Whitelist feature.
 *
 * @param isWhitelistEnabled     whether or not is to allow the Whitelist blockage
 * @param mapNameToCheck         the map name to be verified if the map list checking is enabled
 * @return true when the `mapNameToCheck` is blocked by the Whitelist feature, false otherwise
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
 * Start a map voting delayed after the mp_maxrounds or mp_winlimit minimum to be reached.
 */
#define START_VOTING_BY_MIDDLE_ROUND_DELAY(%1) \
    set_task( float( ROUND_VOTING_START_SECONDS_DELAY() ), %1, TASKID_START_VOTING_DELAYED );

/**
 * Used to set a the voting time to a variable.
 */
#define SET_VOTING_TIME_TO(%1,%2) \
{ \
    if( ( %1 = get_pcvar_num( %2 ) ) < 5 ) \
    { \
        %1 = INFINITY_VOTING_TIME_VALUE; \
    } \
}

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
 * @param name_string        a string pointer to hold the player name
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
 * Split the map name from a string.
 *
 * @param textLine   a string containing a map name at the first part
 * @param mapName    a string to save the map extracted
 */
#define GET_MAP_NAME_LEFT(%2,%3) \
{ \
    str_token( %2,                   %3, MAX_MAPNAME_LENGHT - 1, \
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
    str_token( %2, __g_getMapNameRightToken, MAX_MAPNAME_LENGHT - 1, \
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
      && %1[ 1 ] != ';' \
      && !equal( %1, "//", 2 ) )

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
    LOG( 128, "I AM ENTERING ON TRY_TO_APPLY(2) objectIndentifation: %d", %2 ) \
    if( %2 ) \
    { \
        %1( %2 ); \
    } \
}

/**
 * General handler to assist object property applying and keep the code clear. This only need
 * to be used with cleaners and creators handlers.
 *
 * @param objectHandler           the object handler to be called for cleaning.
 * @param objectIndentifation     the object identification number to be used.
 * @param objectHandlerCreator    the object handler to be called for creation.
 */
#define TRY_TO_CLEAN(%1,%2,%3) \
{ \
    LOG( 128, "I AM ENTERING ON TRY_TO_CLEAN(3) objectIndentifation: %d", %2 ) \
    if( %2 ) \
    { \
        %1( %2 ); \
    } \
    else \
    { \
        %2 = %3; \
    } \
}

/**
 * Wrapper to allow use the destroy_two_dimensional_array(2) as a cleaner on the TRY_TO_CLEAN(2).
 */
#define clear_two_dimensional_array(%1) destroy_two_dimensional_array( %1, false )

/**
 * Check whether the menu exists, call menu_destroy(1) and set the menu to id to 0.
 *
 * @param menu_id_variable    a variable within the player menu to be destroyed.
 */
#define DESTROY_PLAYER_NEW_MENU_TYPE(%1) \
{ \
    LOG( 128, "I AM ENTERING ON DESTROY_PLAYER_NEW_MENU_TYPE(1) menu_id: %d", %1 ) \
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
    LOG( 256, "I AM ENTERING ON TOGGLE_BIT_FLAG_ON_OFF(2) mask: %d, flag: %d", %1, %2 ) \
    %1 & %2 ? ( %1 &= ~%2 ) : ( %1 |= %2 ); \
}

/**
 * Calculate which is the number of the last menu page.
 *
 * @param totalMenuItems     how many items there are on the menu
 * @param menuItemPerPage    how much items there are on each menu's page
 * @return an integer, as the page number
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
    TASKID_NOMINATION_PARTIAL,
    TASKID_PENDING_VOTE_COUNTDOWN,
    TASKID_DBG_FAKEVOTES,
    TASKID_START_THE_VOTING,
    TASKID_MAP_CHANGE,
    TASKID_INTERMISSION_HOLD,
    TASKID_FINISH_GAME_TIME_BY_HALF,
    TASKID_BLOCK_NEW_VOTING_START,
    TASKID_SERVER_CHANGE_LEVEL,
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
new cvar_endOnRoundMax;
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
new cvar_serverPlayersCount;
new cvar_emptyMapFilePath;
new cvar_rtvWaitMinutes;
new cvar_rtvWaitRounds;
new cvar_rtvWaitFrags;
new cvar_rtvWaitAdmin;
new cvar_rtvRatio;
new cvar_rtvRocks;
new cvar_rtvCommands;
new cvar_cmdVotemap;
new cvar_cmdListmaps;
new cvar_listmapsPaginate;
new cvar_recentMapsBannedNumber;
new cvar_recentNomMapsAllowance;
new cvar_isOnlyRecentMapcycleMaps;
new cvar_banRecentStyle;
new cvar_voteDuration;
new cvar_voteMinimun;
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
new cvar_generalOptions;
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
new const MAP_FOLDER_LOAD_FLAG              = '*';
new const MAP_CYCLE_LOAD_FLAG               = '#';
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
new const CANNOT_START_VOTE_SPECTATORS[]    = "Cannot start the voting. The cvar `gal_server_players_count` \
                                                is not supported on this Game Mod.";

new bool:g_isDayOfDefeat;
new bool:g_isRunningSvenCoop;
new bool:g_isServerShuttingDown;
new bool:g_isMapExtensionPeriodRunning;
new bool:g_isTheRoundEndWhileVoting;
new bool:g_isTheRoundEnded;
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
 *
 * Currently only the `g_minPlayerFillerMapGroupTrie` is used, so the others Dynamic Arrays do not
 * need a Trie as pair.
 */
new Trie:g_minPlayerFillerMapGroupTrie;
new Array:g_minPlayerFillerMapGroupArrays;

new Array:g_midPlayerFillerMapGroupArrays;
new Array:g_norPlayerFillerMapGroupArrays;

/**
 * Create a new type to perform the switch between the Minimum Players feature and the Normal
 * Voting map filling.
 */
enum FillersFilePathType
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
new Float:g_timeLimitContextSaved;
new g_maxRoundsContextSaved;
new g_winLimitContextSaved;
new g_fragLimitContextSaved;

/**
 * Not saving these contexts on saveGameEndingTypeContext(0) will for the last round map change to fail
 * on several configurations set by `cvar_endOnRound` and `cvar_endOfMapVoteStart`.
 */
new bool:g_isTheLastGameRoundContext;
new bool:g_isThePenultGameRoundContext;

/**
 * The array indexes used on the saveRoundEnding(1) and restoreRoundEnding(1).
 */
enum SaveRoundEnding
{
    SaveRoundEnding_LastRound,
    SaveRoundEnding_RestartTime,
    SaveRoundEnding_PenultRound,
    SaveRoundEnding_VotingEnd,
    SaveRoundEnding_WhileVoting
}


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
new g_rtvCommands;
new g_rtvWaitRounds;
new g_rtvWaitFrags;
new g_rockedVoteCount;
new g_winLimitNumber;
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
new cvar_gal_mapcyclefile;
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

new g_mapPrefixes                [ MAX_PREFIX_COUNT    ][ MAX_PREFIX_SIZE         ];
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
    LOG( 1, "^n^n^n^n^n^n^n^n^n^n^n^n%s PLUGIN VERSION %s INITIATING...", PLUGIN_NAME, PLUGIN_VERSION )

    LOG( 1, "( plugin_init )" )
    LOG( 1, "( plugin_init ) AMXX_VERSION_NUM:                         %d", AMXX_VERSION_NUM )
    LOG( 1, "( plugin_init ) AMXX_VERSION_STR:                         %s", AMXX_VERSION_STR )
    LOG( 1, "( plugin_init ) IS_TO_ENABLE_SVEN_COOP_SUPPPORT:          %d", IS_TO_ENABLE_SVEN_COOP_SUPPPORT )
    LOG( 1, "( plugin_init ) FAKE_PLAYERS_NUMBER_FOR_DEBUGGING:        %d", FAKE_PLAYERS_NUMBER_FOR_DEBUGGING )
    LOG( 1, "( plugin_init ) MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST:    %d", MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST )
    LOG( 1, "( plugin_init ) IS_TO_ENABLE_RE_HLDS_RE_AMXMODX_SUPPORT:  %d", IS_TO_ENABLE_RE_HLDS_RE_AMXMODX_SUPPORT )
    LOG( 1, "( plugin_init )" )

    cvar_serverStartAction         = register_cvar( "gal_srv_start"                , "0"    );
    cvar_serverMoveCursor          = register_cvar( "gal_srv_move_cursor"          , "0"    );
    cvar_gameCrashRecreationAction = register_cvar( "gal_game_crash_recreation"    , "0"    );
    cvar_serverTimeLimitRestart    = register_cvar( "gal_srv_timelimit_restart"    , "0"    );
    cvar_serverMaxroundsRestart    = register_cvar( "gal_srv_maxrounds_restart"    , "0"    );
    cvar_serverWinlimitRestart     = register_cvar( "gal_srv_winlimit_restart"     , "0"    );
    cvar_serverFraglimitRestart    = register_cvar( "gal_srv_fraglimit_restart"    , "0"    );
    cvar_endOfMapVote              = register_cvar( "gal_endofmapvote"             , "1"    );
    cvar_endOfMapVoteExpiration    = register_cvar( "gal_endofmapvote_expiration"  , "0"    );
    cvar_endOfMapVoteStart         = register_cvar( "gal_endofmapvote_start"       , "0"    );
    cvar_nextMapChangeAnnounce     = register_cvar( "gal_nextmap_change"           , "0"    );
    cvar_nextMapChangeVotemap      = register_cvar( "gal_nextmap_votemap"          , "1"    );
    cvar_voteMapChoiceCount        = register_cvar( "gal_vote_mapchoices"          , "5"    );
    cvar_voteMapChoiceNext         = register_cvar( "gal_vote_mapchoices_next"     , "1"    );
    cvar_voteDuration              = register_cvar( "gal_vote_duration"            , "30"   );
    cvar_voteMinimun               = register_cvar( "gal_vote_minimum"             , "0"    );
    cvar_voteMapFilePath           = register_cvar( "gal_vote_mapfile"             , "#"    );
    cvar_voteMinPlayers            = register_cvar( "gal_vote_minplayers"          , "0"    );
    cvar_voteMidPlayers            = register_cvar( "gal_vote_midplayers"          , "0"    );
    cvar_nomMinPlayersControl      = register_cvar( "gal_nom_minplayers_control"   , "0"    );
    cvar_voteMinPlayersMapFilePath = register_cvar( "gal_vote_minplayers_mapfile"  , ""     );
    cvar_voteMidPlayersMapFilePath = register_cvar( "gal_vote_midplayers_mapfile"  , ""     );
    cvar_runoffEnabled             = register_cvar( "gal_runoff_enabled"           , "0"    );
    cvar_runoffDuration            = register_cvar( "gal_runoff_duration"          , "20"   );
    cvar_runoffRatio               = register_cvar( "gal_runoff_ratio"             , "0.5"  );
    cvar_runoffMapchoices          = register_cvar( "gal_runoff_mapchoices"        , "2"    );
    cvar_nomPlayerAllowance        = register_cvar( "gal_nom_playerallowance"      , "0"    );
    cvar_nomCleaning               = register_cvar( "gal_nom_cleaning"             , "1"    );
    cvar_nomMapFilePath            = register_cvar( "gal_nom_mapfile"              , "*"    );
    cvar_nomPrefixes               = register_cvar( "gal_nom_prefixes"             , "1"    );
    cvar_nomQtyUsed                = register_cvar( "gal_nom_qtyused"              , "0"    );
    cvar_unnominateDisconnected    = register_cvar( "gal_unnominate_disconnected"  , "1"    );
    cvar_recentMapsBannedNumber    = register_cvar( "gal_banrecent"                , "0"    );
    cvar_recentNomMapsAllowance    = register_cvar( "gal_recent_nom_maps"          , "0"    );
    cvar_isOnlyRecentMapcycleMaps  = register_cvar( "gal_banrecent_mapcycle"       , "0"    );
    cvar_banRecentStyle            = register_cvar( "gal_banrecentstyle"           , "3"    );

    register_cvar( "gal_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY );

    // print the current used debug information
#if DEBUG_LEVEL & ( DEBUG_LEVEL_NORMAL | DEBUG_LEVEL_CRITICAL_MODE )
    new debug_level[ MAX_SHORT_STRING ];
    formatex( debug_level, charsmax( debug_level ), "%d | %d", g_debug_level, DEBUG_LEVEL );

    LOG( 1, "( plugin_init ) gal_debug_level: %s", debug_level )
    register_cvar( "gal_debug_level", debug_level, FCVAR_SERVER | FCVAR_SPONLY );
#endif

    cvar_endOnRoundRtv             = register_cvar( "gal_endonround_rtv"           , "0"    );
    cvar_rtvCommands               = register_cvar( "gal_rtv_commands"             , "0"    );
    cvar_rtvWaitMinutes            = register_cvar( "gal_rtv_wait"                 , "10"   );
    cvar_rtvWaitRounds             = register_cvar( "gal_rtv_wait_rounds"          , "5"    );
    cvar_rtvWaitFrags              = register_cvar( "gal_rtv_wait_frags"           , "10"   );
    cvar_rtvWaitAdmin              = register_cvar( "gal_rtv_wait_admin"           , "0"    );
    cvar_rtvRatio                  = register_cvar( "gal_rtv_ratio"                , "0.60" );
    cvar_rtvRocks                  = register_cvar( "gal_rtv_rocks"                , "0"    );
    cvar_rtvReminder               = register_cvar( "gal_rtv_reminder"             , "2"    );
    cvar_whitelistType             = register_cvar( "gal_whitelist_type"           , "0"    );
    cvar_whitelistMinPlayers       = register_cvar( "gal_whitelist_minplayers"     , "0"    );
    cvar_isWhiteListNomBlock       = register_cvar( "gal_whitelist_nom_block"      , "0"    );
    cvar_isWhiteListBlockOut       = register_cvar( "gal_whitelist_block_out"      , "0"    );
    cvar_voteWhiteListMapFilePath  = register_cvar( "gal_vote_whitelist_mapfile"   , ""     );
    cvar_voteUniquePrefixes        = register_cvar( "gal_vote_uniqueprefixes"      , "0"    );
    cvar_extendmapStepMinutes      = register_cvar( "gal_extendmap_step_min"       , "15"   );
    cvar_maxMapExtendTime          = register_cvar( "gal_extendmap_max_min"        , "1"    );
    cvar_extendmapStepRounds       = register_cvar( "gal_extendmap_step_rounds"    , "20"   );
    cvar_maxMapExtendRounds        = register_cvar( "gal_extendmap_max_rounds"     , "1"    );
    cvar_fragLimitSupport          = register_cvar( "gal_mp_fraglimit_support"     , "0"    );
    cvar_extendmapStepFrags        = register_cvar( "gal_extendmap_step_frags"     , "30"   );
    cvar_maxMapExtendFrags         = register_cvar( "gal_extendmap_max_frags"      , "1"    );
    cvar_extendmapAllowStay        = register_cvar( "gal_extendmap_allow_stay"     , "0"    );
    cvar_extendmapAllowStayType    = register_cvar( "gal_extendmap_allow_stay_type", "0"    );
    cvar_isExtendmapOrderAllowed   = register_cvar( "gal_extendmap_allow_order"    , "1"    );
    cvar_showVoteStatus            = register_cvar( "gal_vote_showstatus"          , "4"    );
    cvar_showVoteStatusType        = register_cvar( "gal_vote_showstatustype"      , "2"    );
    cvar_isToReplaceByVoteMenu     = register_cvar( "gal_vote_replace_menu"        , "1"    );
    cvar_isToShowNoneOption        = register_cvar( "gal_vote_show_none"           , "0"    );
    cvar_voteWeight                = register_cvar( "gal_vote_weight"              , "0"    );
    cvar_voteWeightFlags           = register_cvar( "gal_vote_weightflags"         , "y"    );
    cvar_voteShowNoneOptionType    = register_cvar( "gal_vote_show_none_type"      , "2"    );
    cvar_isToShowExpCountdown      = register_cvar( "gal_vote_expirationcountdown" , "0"    );
    cvar_isToShowVoteCounter       = register_cvar( "gal_vote_show_counter"        , "1"    );
    cvar_voteAnnounceChoice        = register_cvar( "gal_vote_announcechoice"      , "0"    );
    cvar_generalOptions            = register_cvar( "gal_general_options"          , "0"    );
    cvar_isToAskForEndOfTheMapVote = register_cvar( "gal_endofmapvote_ask"         , "0"    );
    cvar_cmdVotemap                = register_cvar( "gal_cmd_votemap"              , "1"    );
    cvar_cmdListmaps               = register_cvar( "gal_cmd_listmaps"             , "1"    );
    cvar_listmapsPaginate          = register_cvar( "gal_listmaps_paginate"        , "10"   );
    cvar_emptyServerWaitMinutes    = register_cvar( "gal_emptyserver_wait"         , "0"    );
    cvar_isEmptyCycleByMapChange   = register_cvar( "gal_emptyserver_change"       , "0"    );
    cvar_serverPlayersCount        = register_cvar( "gal_server_players_count"     , "0"    );
    cvar_emptyMapFilePath          = register_cvar( "gal_emptyserver_mapfile"      , ""     );
    cvar_soundsMute                = register_cvar( "gal_sounds_mute"              , "27"   );
    cvar_hudsHide                  = register_cvar( "gal_sounds_hud"               , "31"   );
    cvar_coloredChatEnabled        = register_cvar( "gal_colored_chat_enabled"     , "0"    );
    cvar_coloredChatPrefix         = register_cvar( "gal_colored_chat_prefix"      , ""     );
    cvar_endOnRound                = register_cvar( "gal_endonround"               , "0"    );
    cvar_endOnRoundMax             = register_cvar( "gal_endonround_max"           , "9"    );
    cvar_endOnRoundMininum         = register_cvar( "gal_endonround_msg"           , "0"    );
    cvar_endOnRoundChange          = register_cvar( "gal_endonround_change"        , "1"    );
    cvar_isEndMapCountdown         = register_cvar( "gal_endonround_countdown"     , "0"    );

    // These are NOT configurable cvars. Do not change/use them. These are used instead of the `localinfo`.
    //
    // When `cvar_isFirstServerStart` set set to 2 we are on the first server start period. If this
    // is set to 1, we are on the beginning of the second server map change level.
    cvar_isFirstServerStart = register_cvar( "gal_server_starting"    , "2", FCVAR_SPONLY );
    cvar_isToStopEmptyCycle = register_cvar( "gal_in_empty_cycle"     , "0", FCVAR_SPONLY );
    cvar_successfullLevels  = register_cvar( "gal_successfull_levels" , "0", FCVAR_SPONLY );

    // This is a general pointer used for cvars not registered on the game.
    cvar_gal_mapcyclefile     = register_cvar( "gal_mapcyclefile"          , "" , FCVAR_SERVER );
    cvar_disabledValuePointer = register_cvar( "gal_disabled_value_pointer", "0", FCVAR_SPONLY );

    // This are default behaviors independent of any setting to be enabled.
    configureEndGameCvars();
    nextmapPluginInit();
    timeleftPluginInit();
    configureTheVotingMenus();
    configureSpecificGameModFeature();

    // Register the HLTV for the supported game mods.
    if( IS_NEW_ROUND_EVENT_SUPPORTED() )
    {
        register_event( "HLTV", "new_round_event", "a", "1=0", "2=0" );
    }

    // This are default behaviors independent of any setting to be enabled.
    register_logevent( "game_commencing_event", 2, "0=World triggered", "1=Game_Commencing" );
    register_logevent( "team_win_event",        6, "0=Team" );
    register_logevent( "round_restart_event",   2, "0=World triggered", "1&Restart_Round_" );
    register_logevent( "round_start_event",     2, "1=Round_Start" );
    register_logevent( "round_end_event",       2, "1=Round_End" );

    // This are default behaviors independent of any setting to be enabled.
    register_concmd( "gal_startvote", "cmd_startVote", ADMIN_MAP );
    register_concmd( "gal_cancelvote", "cmd_cancelVote", ADMIN_MAP );
    register_concmd( "gal_changelevel", "cmd_changeLevel", ADMIN_MAP );
    register_concmd( "gal_createmapfile", "cmd_createMapFile", ADMIN_RCON );
    register_concmd( "gal_maintenance_mode", "cmd_maintenanceMode", ADMIN_RCON );
    register_concmd( "gal_look_for_crashes", "cmd_lookForCrashes", ADMIN_RCON );

    LOG( 1, "    I AM EXITING plugin_init(0)..." )
    LOG( 1, "" )
}

/**
 * Called when all plugins went through plugin_init(). When this forward is called, most plugins
 * should have registered their cvars and commands already.
 */
public plugin_cfg()
{
    LOG( 128, "I AM ENTERING ON plugin_cfg(0)" )
    get_mapname( g_currentMapName, charsmax( g_currentMapName ) );

    /**
     * Register the color chat 'g_user_msgid' variable. Note, if some exception happened before
     * this, all color_chat() messages will cause native error 10, on the AMXX 182. It is because,
     * the execution flow will not reach here, then the player "g_user_msgid" will be be
     * initialized.
     */
    g_user_msgid = get_user_msgid( "SayText" );

    // Load the initial settings
    loadPluginSetttings();

    // Need to be called after the `IS_COLORED_CHAT_ENABLED()` settings load on loadPluginSetttings(0).
    loadLangFiles();
    loadMapFiles();

    LOG( 4, "" )
    LOG( 4, "" )

    // The 'mp_fraglimitCvarSupport(0)' could register a new cvar, hence only call cacheCvarsValuesIgnored(0) them after it.
    mp_fraglimitCvarSupport();
    cacheCvarsValuesIgnored();
    resetRoundsScores();

    LOG( 0, "", printTheCurrentAndNextMapNames() )

    // Used to loop through all server maps looking for crashing ones
    configureServerStart();
    runTheServerMapCrashSearch();

    // Configure the Unit Tests, when they are activate.
#if ARE_WE_RUNNING_UNIT_TESTS
    configureTheUnitTests();
#endif

    LOG( 1, "    I AM EXITING plugin_cfg(0)..." )
    LOG( 1, "" )
}

stock loadLangFiles()
{
    LOG( 128, "I AM ENTERING ON loadLangFiles(0)" )

    g_isColoredChatEnabled = get_pcvar_num( cvar_coloredChatEnabled ) != 0;
    register_dictionary_colored( "galileo.txt" );

    register_dictionary( "common.txt" );
    register_dictionary( "cmdmenu.txt" );
    register_dictionary( "mapsmenu.txt" );
    register_dictionary( "adminvote.txt" );
}

stock runTheServerMapCrashSearch()
{
    LOG( 128, "I AM ENTERING ON runTheServerMapCrashSearch(0)" )

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

        // Allow the admin to connect to the server and to disable the command `gal_look_for_crashes`.
        delay = get_real_players_number() ? 100.0 : 7.0;
        server_print( "The server is changing level in %d seconds!", floatround( delay, floatround_floor ) );

        set_pcvar_num( cvar_mp_chattime, 3 );
        set_pcvar_num( cvar_serverMoveCursor, 0 );
        set_pcvar_num( cvar_successfullLevels, successfullLevels + 1 );

        set_task( delay, "changeMapIntermission" );
        set_pcvar_string( cvar_mapcyclefile, modeFlagFilePath );
    }
}

/**
 * After the settings being loaded, the `gal_mapcyclefile` setting will be overridden and the crash
 * search will be broken. Then this function restores its correct value.
 */
stock restoreModeFlagFilePath()
{
    LOG( 128, "I AM ENTERING ON restoreModeFlagFilePath(0)" )

    new modeFlagFilePath[ MAX_FILE_PATH_LENGHT ];
    formatex( modeFlagFilePath, charsmax( modeFlagFilePath ), "%s/%s", g_dataDirPath, TO_STOP_THE_CRASH_SEARCH );

    if( IS_TO_ALLOW_A_CRASH_SEARCH( modeFlagFilePath ) )
    {
        set_pcvar_num( cvar_serverStartAction, 1 );
        set_pcvar_string( cvar_mapcyclefile, modeFlagFilePath );
    }
}

/**
 * On the first server start, we do not know whether the color chat is allowed/enabled. This is due
 * the register register_dictionary_colored(1) to be called on plugin_init(0) and the settings being
 * loaded only at plugin_cfg(0).
 */
stock configureSpecificGameModFeature()
{
    LOG( 128, "I AM ENTERING ON configureSpecificGameModFeature(0)" )

    g_isDayOfDefeat        = !!is_running("dod");
    g_isRunningSvenCoop    = !!is_running("svencoop");
    g_isColorChatSupported = ( is_running( "czero" ) || is_running( "cstrike" ) );

    // Register the voting start call from the Sven Coop game.
#if IS_TO_ENABLE_SVEN_COOP_SUPPPORT > 0
    if( g_isRunningSvenCoop )
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
    LOG( 128, "I AM ENTERING ON configureEndGameCvars(0)" )

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
    LOG( 128, "I AM ENTERING ON tryToGetGameModCvar(2) cvar_to_get: %d, cvar_name: %s", cvar_to_get, cvar_name )

    if( !( cvar_to_get = get_cvar_pointer( cvar_name ) ) )
    {
        cvar_to_get = cvar_disabledValuePointer;
    }

    LOG( 1, "    ( tryToGetGameModCvar ) %s is cvar_to_get: %d", cvar_name, cvar_to_get )
}

stock configureTheVotingMenus()
{
    LOG( 128, "I AM ENTERING ON configureTheVotingMenus(0)" )

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
    LOG( 128, "I AM ENTERING ON loadPluginSetttings(0)" )
    new writtenSize;

    writtenSize = get_configsdir( g_configsDirPath, charsmax( g_configsDirPath ) );
    copy( g_configsDirPath[ writtenSize ], charsmax( g_configsDirPath ) - writtenSize, "/galileo" );

    writtenSize = get_datadir( g_dataDirPath, charsmax( g_dataDirPath ) );
    copy( g_dataDirPath[ writtenSize ], charsmax( g_dataDirPath ) - writtenSize, "/galileo" );

    if( !dir_exists( g_dataDirPath )
        && mkdir( g_dataDirPath ) )
    {
        LOG( 1, "AMX_ERR_NOTFOUND, Could not create: %s", g_dataDirPath )
        log_error( AMX_ERR_NOTFOUND, "Could not create: %s", g_dataDirPath );
    }

    LOG( 1, "( loadPluginSetttings ) g_configsDirPath: %s, g_dataDirPath: %s,", g_configsDirPath, g_dataDirPath )

    server_cmd( "exec %s/galileo.cfg", g_configsDirPath );
    server_exec();

    registerTheMapCycleCvar();
    restoreModeFlagFilePath();

    server_exec();
    cacheCvarsValues( true );
}

/**
 * The cvars as 'mp_fraglimit' is registered only the first time the server starts. This function
 * setup the 'mp_fraglimit' support on all Game Modifications.
 */
stock mp_fraglimitCvarSupport()
{
    LOG( 128, "I AM ENTERING ON mp_fraglimitCvarSupport(0)" )

    // mp_fraglimit
    new exists_mp_fraglimit_cvar = cvar_exists( "mp_fraglimit" );
    LOG( 32, "( mp_fraglimitCvarSupport ) exists_mp_fraglimit_cvar: %d", exists_mp_fraglimit_cvar )

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

    LOG( 1, "( mp_fraglimitCvarSupport ) cvar_disabledValuePointer: %d", cvar_disabledValuePointer )
    LOG( 1, "( mp_fraglimitCvarSupport ) mp_fraglimit is cvar_to_get: %d", cvar_mp_fraglimit )

    // re-cache later to wait load some late server configurations, as the per-map configs.
    set_task( DELAY_TO_WAIT_THE_SERVER_CVARS_TO_BE_LOADED, "cacheCvarsValuesPublic" );
}

/**
 * Used to allow the menu cacheCvarsValues(1) to have parameters within a default value. It is
 * because public functions are not allow to have a default value and we need this function be
 * public to allow it to be called from a set_task().
 */
public cacheCvarsValuesPublic()
{
    LOG( 128, "I AM ENTERING ON cacheCvarsValuesPublic(0)" )
    cacheCvarsValues();
}

/**
 * To cache some high used server cvars.
 *
 * @param ignoreUnregistred     whether retrieve the settings dependent cvars or not.
 *
 * @see cacheCvarsValuesIgnored(0)
 */
stock cacheCvarsValues( ignoreUnregistred=false )
{
    LOG( 128, "I AM ENTERING ON cacheCvarsValues(1)" )

    // RTV wait time
    g_rtvWaitRounds  = get_pcvar_num( cvar_rtvWaitRounds    );
    g_rtvWaitFrags   = get_pcvar_num( cvar_rtvWaitFrags     );
    g_rtvWaitMinutes = get_pcvar_float( cvar_rtvWaitMinutes );

    if( !ignoreUnregistred )
    {
        cacheCvarsValuesIgnored();
    }

    g_rtvCommands            = get_pcvar_num( cvar_rtvCommands            );
    g_extendmapStepRounds    = get_pcvar_num( cvar_extendmapStepRounds    );
    g_extendmapStepFrags     = get_pcvar_num( cvar_extendmapStepFrags     );
    g_extendmapStepMinutes   = get_pcvar_num( cvar_extendmapStepMinutes   );
    g_extendmapAllowStayType = get_pcvar_num( cvar_extendmapAllowStayType );
    g_showVoteStatus         = get_pcvar_num( cvar_showVoteStatus         );
    g_voteShowNoneOptionType = get_pcvar_num( cvar_voteShowNoneOptionType );
    g_showVoteStatusType     = get_pcvar_num( cvar_showVoteStatusType     );
    g_maxRoundsNumber        = get_pcvar_num( cvar_mp_maxrounds           );
    g_winLimitNumber         = get_pcvar_num( cvar_mp_winlimit            );
    g_timeLimitNumber        = get_pcvar_num( cvar_mp_timelimit           );

    g_isExtendmapAllowStay   = get_pcvar_num( cvar_extendmapAllowStay   ) != 0;
    g_isToShowNoneOption     = get_pcvar_num( cvar_isToShowNoneOption   ) == 1;
    g_isToShowSubMenu        = get_pcvar_num( cvar_isToShowNoneOption   ) == 2;
    g_isToShowVoteCounter    = get_pcvar_num( cvar_isToShowVoteCounter  ) != 0;
    g_isToShowExpCountdown   = get_pcvar_num( cvar_isToShowExpCountdown ) != 0;

    get_pcvar_string( cvar_voteWeightFlags, g_voteWeightFlags, charsmax( g_voteWeightFlags ) );
    g_maxVotingChoices = max( min( MAX_OPTIONS_IN_VOTE, get_pcvar_num( cvar_voteMapChoiceCount ) ), 2 );

    // It need to be cached after loading all the cvars, because it use some of them.
    g_totalVoteTime = howManySecondsLastMapTheVoting();
}

/**
 * Some cvars are not registered right after the settings are loaded because these cvars are
 * settings dependents.
 */
stock cacheCvarsValuesIgnored()
{
    LOG( 128, "I AM ENTERING ON cacheCvarsValuesIgnored(0)" )
    g_fragLimitNumber = get_pcvar_num( cvar_mp_fraglimit );

    //Do not put it before the variable `g_isColoredChatEnabled` caching.
    get_pcvar_string( cvar_coloredChatPrefix, g_coloredChatPrefix, charsmax( g_coloredChatPrefix ) );

    if( IS_COLORED_CHAT_ENABLED() )
    {
        INSERT_COLOR_TAGS( g_coloredChatPrefix )
    }
    else
    {
        REMOVE_LETTER_COLOR_TAGS( g_coloredChatPrefix )
    }

    LOG( 1, "( cacheCvarsValuesIgnored ) g_coloredChatPrefix: %s", g_coloredChatPrefix )
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
    LOG( 128, "I AM ENTERING ON configureServerStart(0)" )
    new startAction;

    set_task( float( PERIODIC_CHECKING_INTERVAL ), "vote_manageEnd", _, _, _, "b" );

    // If these two settings are disabled, there is not need to these handlers.
    if( get_pcvar_num( cvar_rtvCommands )
        || get_pcvar_num( cvar_nomPlayerAllowance ) )
    {
        register_clcmd( "say",      "cmd_say", -1 );
        register_clcmd( "say_team", "cmd_say", -1 );
    }

    if( get_pcvar_num( cvar_cmdVotemap  ) != COMMAND_VOTEMAP_DISABLED  ) register_clcmd( "votemap" , "cmd_HL1_votemap"  );
    if( get_pcvar_num( cvar_cmdListmaps ) != COMMAND_LISTMAPS_DISABLED ) register_clcmd( "listmaps", "cmd_HL1_listmaps" );

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
        // This cvar is only required when the start action is enabled.
        register_srvcmd( "quit2", "cmd_quit2" );

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
                // These data, are already loaded by the configureTheNextMapSetttings(1) function call.
                trim( g_nextMapName );
                trim( g_currentMapName );

                saveCurrentAndNextMapNames( g_currentMapName, g_nextMapName, true );
            }
        }
        else
        {
            // Save the current and next map name when the server admin does something like `amx_map`, and the
            // server did not crash on the selected map, the setTheCurrentAndNextMapSettings(0) cannot update
            // what are the correct current and next map names, because it is only called a the plugin_end(0).
            trim( g_nextMapName );
            trim( g_currentMapName );

            saveCurrentAndNextMapNames( g_currentMapName, g_nextMapName, true );
        }
    }
    else
    {
        // The level `FIRST_SERVER_START` is only meant to be used by the `startAction`, therefore
        // when the `startAction` is disabled we must to set it to the seconds level `SECOND_SERVER_START`.
        set_pcvar_num( cvar_isFirstServerStart, SECOND_SERVER_START );

        LOG( 2, "( configureServerStart ) IS CHANGING THE CVAR 'gal_server_starting' to '%d'.", \
                get_pcvar_num( cvar_isFirstServerStart ) )
    }
}

/**
 * I must to set next the current and next map at plugin_end(0), because if the next map changed by
 * a normal server change level, the current and next map names will not be updated. It is impossible
 * to detect to which map the server was changed when the server admin does `amx_map` or any other
 * command to change the level to a specific map. However we do not need to worry about such commands
 * because if the admin does so, the map will be changed to the map just before they were when the
 * change level command to be performed.
 *
 * Sadly this function is being called when the server's admin is calling `rcon quit`. It means that
 * on the next time the server start, it will be on the next map instead of the current map. To fix
 * this, we need to detect here if this function is being called when the server admin the command
 * `rcon quit`.
 *
 * Therefore, we register the server command `quit` setting the global variable `g_isServerShuttingDown`
 * to true and returning `PLUGIN_CONTINUE`. But this first one is not working. Looks list only Orpheu
 * can hook this. For now I am registering the command `quit2` which setup the global variable
 * `g_isServerShuttingDown` and call the server command `quit`.
 *
 * This is an example to blocking the rcon command:
 *
 * #include <amxmodx>
 * #include <orpheu>
 *
 * public plugin_init()
 * {
 *     OrpheuRegisterHook( OrpheuGetFunction( "SV_Rcon" ), "On_Rcon_Pre", OrpheuHookPre )
 * }
 *
 * public OrpheuHookReturn:On_Rcon_Pre()
 * {
 *     g_isServerShuttingDown = true;
 *     return OrpheuIgnored
 * }
 *
 * ************************************************************************************************
 *
 * Algorithm o detect the quit command: (Not implemented, Not finished)
 *
 * 1. Update only at server start the new file `lastServerStartMapName.dat`
 *
 * 2. So if the map name on `lastServerStartMapName.dat` is different that the current map name on
 *    `currentAndNextmapNames.dat`, the server crashed on change level or the server admin used the
 *    command `quit` on the server console.
 *
 *    2.a) If the server crashed on change level, we still want to go back to that map on
 *         `currentAndNextmapNames.dat` until `MAX_SERVER_RESTART_ACCEPTABLE`.
 *    2.b) If the server admin just used the command `quit`, we want to go back to the map the
 *         file `lastServerStartMapName.dat`.
 *
 * 3. If  if the map name on `lastServerStartMapName.dat` is equal that the current map name on
 *    `currentAndNextmapNames.dat`, the server can crashed while playing the that map. This case is
 *    the same on `2.a)`, we still want to come back to that map `lastServerStartMapName.dat` until
 *    the MAX_SERVER_RESTART_ACCEPTABLE.
 */
stock setTheCurrentAndNextMapSettings()
{
    LOG( 128, "I AM ENTERING ON setTheCurrentAndNextMapSettings(0)" )
    LOG( 4, "( setTheCurrentAndNextMapSettings ) g_isServerShuttingDown: %d", g_isServerShuttingDown )

    if( g_isServerShuttingDown )
    {
        g_isServerShuttingDown = false;
    }
    else
    {
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
            if( map_getNext( g_mapcycleFileListArray, currentMapName, nextMapName, "mapcyclefile" ) == -1 )
            {
                // If we cannot find a valid next map, set it as the current map. Therefore when the
                // getNextMapByPosition(5) to start looking for a new next map, it will automatically take the
                // first map, as is does not allow the current map to be set as the next map.
                trim( currentMapName );
                saveCurrentAndNextMapNames( currentMapName, currentMapName );
            }
            else
            {
                trim( nextMapName );
                trim( currentMapName );

                saveCurrentAndNextMapNames( currentMapName, nextMapName );
            }
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

    LOG( 2, "( setTheCurrentAndNextMapSettings ) IS CHANGING THE CVAR 'gal_server_starting' to '%d'.", \
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
    LOG( 128, "I AM ENTERING ON handleServerStart(2) backupMapsFilePath: %s", backupMapsFilePath )
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
            fgets( backupMapsFile, mapToChange           , charsmax( mapToChange            ) );
            fgets( backupMapsFile, nextMapName           , charsmax( nextMapName            ) );
            fgets( backupMapsFile, mapCyclePositionString, charsmax( mapCyclePositionString ) );
            fclose( backupMapsFile );

            trim( mapToChange );
            trim( nextMapName );
            trim( mapCyclePositionString );

            mapCyclePosition = str_to_num( mapCyclePositionString );

            if( startAction == SERVER_START_NEXTMAP )
            {
                copy( mapToChange, charsmax( mapToChange ), nextMapName );

                // If there is not found a next map, the current map name on `nextMapName` will to be
                // set as the first map cycle map name.
                map_getNext( g_mapcycleFileListArray, mapToChange, nextMapName, "mapcyclefile" );
            }
        }
        else
        {
            doAmxxLog( "ERROR, handleServerStart: Could not open the file backupMapsFilePath ^"%s^"", backupMapsFilePath );
        }
    }
    else if( startAction == SERVER_START_RANDOMMAP ) // pick a random map from allowable nominations
    {
        // If noms aren't allowed, the nomination list hasn't already been loaded
        if( get_pcvar_num( cvar_nomPlayerAllowance ) == 0 )
        {
            new mapFilePath[ MAX_FILE_PATH_LENGHT ];
            loadNominationList( mapFilePath );
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
                LOG( 2, "( handleServerStart ) IS CHANGING THE CVAR 'gal_server_starting' to '%d'.", SECOND_SERVER_START )
            }
            else
            {
                // When the Unit Tests are running, we do not want to or can wait anything.
            #if ARE_WE_RUNNING_UNIT_TESTS
                if( g_test_areTheUnitTestsRunning )
                {
                    serverChangeLevel( mapToChange );
                }
                else
                {
                    set_task( 2.0, "serverChangeLevel", _, mapToChange, charsmax( mapToChange ) );
                }
            #else
                // Create a small delay to let other plugins to do their stuff/breath.
                set_task( 2.0, "serverChangeLevel", _, mapToChange, charsmax( mapToChange ) );
            #endif
            }
        }
        else
        {
            doAmxxLog( "WARNING, handleServerStart: Invalid map read from the current and next map file ^"%s^"", mapToChange );
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
    LOG( 128, "I AM ENTERING ON configureTheMapcycleSystem(2) mapToChange: %s", mapToChange )
    trim( mapToChange );

    new restartsOnTheCurrentMap;
    new crashingMap[ MAX_MAPNAME_LENGHT ];

    copy( crashingMap, charsmax( crashingMap ), mapToChange );
    restartsOnTheCurrentMap = getRestartsOnTheCurrentMap( mapToChange );

    LOG( 4, "( configureTheMapcycleSystem ) mapToChange: %s", mapToChange )
    LOG( 4, "( configureTheMapcycleSystem ) possibleNextMap: %s", possibleNextMap )
    LOG( 4, "( configureTheMapcycleSystem ) restartsOnTheCurrentMap: %d", restartsOnTheCurrentMap )

    // Set the new current map as the actual next map.
    if( restartsOnTheCurrentMap > MAX_SERVER_RESTART_ACCEPTABLE )
    {
        new lastMapChangedFile;

        LOG( 4, "( configureTheMapcycleSystem ) restartsOnTheCurrentMap > MAX_SERVER_RESTART_ACCEPTABLE" )
        LOG( 4, "" )

        setThisMapAsPossibleCrashingMap( crashingMap );

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
                doAmxxLog( "WARNING, configureTheMapcycleSystem: Your ^"mapcyclefile^" server variable is invalid!" );

                copy( possibleCurrentMap, MAX_MAPNAME_LENGHT - 1, g_currentMapName );
                copy( possibleNextMap   , MAX_MAPNAME_LENGHT - 1, g_currentMapName );

                // If there is not any map, just to do setup it by default the first server's map.
                configureTheNextMapPlugin( possibleCurrentMap, possibleNextMap, 0, true );
            }
        }
        else
        {
            // I do like the map_getNext(4) behavior. I prefer using getNextMapByPosition(5).
            copy( possibleCurrentMap, charsmax( possibleCurrentMap ), possibleNextMap );

            // possibleNextMapPosition = map_getNext( g_mapcycleFileListArray, possibleCurrentMap, possibleNextMap, "mapcyclefile" );
            possibleNextMapPosition = getNextMapByPosition( g_mapcycleFileListArray, possibleNextMap, g_nextMapCyclePosition );

            // Update the current map to the next map.
            copy( mapToChange, MAX_MAPNAME_LENGHT - 1, possibleCurrentMap );
            configureTheNextMapPlugin( possibleCurrentMap, possibleNextMap, possibleNextMapPosition, true );
        }

        // Clear the old data
        LOG( 4, "" )
        formatex( lastMapChangedFilePath, charsmax( lastMapChangedFilePath ), "%s/%s", g_dataDirPath, LAST_CHANGE_MAP_FILE_NAME );

        if( ( lastMapChangedFile = fopen( lastMapChangedFilePath, "wt" ) ) )
        {
            fprintf( lastMapChangedFile, "nothing_to_be_added_by^n0^n" );
            fclose( lastMapChangedFile );
        }
        else
        {
            doAmxxLog( "ERROR, configureTheMapcycleSystem: Couldn't open the file to write ^"%s^"", lastMapChangedFilePath );
        }

        doAmxxLog( "" );
        doAmxxLog( "The server is jumping to the next map after the current map due more than %d restarts on the map ^"%s^"",
                MAX_SERVER_RESTART_ACCEPTABLE, crashingMap );

        doAmxxLog( "" );
    }
    else
    {
        configureTheNextMapPlugin( mapToChange, possibleNextMap, possibleNextMapPosition );
        LOG( 4, "( configureTheMapcycleSystem ) restartsOnTheCurrentMap < MAX_SERVER_RESTART_ACCEPTABLE" )
        LOG( 4, "" )
    }
}

stock setThisMapAsPossibleCrashingMap( const mapName[] )
{
    LOG( 128, "I AM ENTERING ON setThisMapAsPossibleCrashingMap(1) mapName: %s", mapName )

    new serverCrashedMapsFile;
    new serverCrashedMapsFilePath[ MAX_FILE_PATH_LENGHT ];

    formatex( serverCrashedMapsFilePath, charsmax( serverCrashedMapsFilePath ), "%s/%s", g_dataDirPath, MAPS_WHERE_THE_SERVER_CRASHED );

    if( !( serverCrashedMapsFile = fopen( serverCrashedMapsFilePath, "a+" ) ) )
    {
        doAmxxLog( "ERROR, setThisMapAsPossibleCrashingMap: Couldn't open the file ^"%s^"", serverCrashedMapsFilePath );
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
    LOG( 128, "I AM ENTERING ON configureTheNextMapPlugin(4)" )

    LOG( 4, "( configureTheNextMapPlugin ) forceUpdateFile: %d", forceUpdateFile )
    LOG( 4, "( configureTheNextMapPlugin ) possibleNextMap: %s",  possibleNextMap )
    LOG( 4, "( configureTheNextMapPlugin ) possibleCurrentMap: %s",  possibleCurrentMap )
    LOG( 4, "( configureTheNextMapPlugin ) possibleNextMapPosition: %d", possibleNextMapPosition )

    if( possibleNextMapPosition )
    {
        new mapcycleFilePath[ MAX_FILE_PATH_LENGHT ];
        get_pcvar_string( cvar_mapcyclefile, mapcycleFilePath, charsmax( mapcycleFilePath ) );

        setNextMap( possibleCurrentMap, possibleNextMap, true, forceUpdateFile );
        saveCurrentMapCycleSetting( g_currentMapName, mapcycleFilePath, possibleNextMapPosition );
    }
}

stock getRestartsOnTheCurrentMap( const mapToChange[] )
{
    LOG( 128, "I AM ENTERING ON getRestartsOnTheCurrentMap(1) mapToChange: %s", mapToChange )

    new lastMapChangedFile;
    new lastMapChangedCount;

    new lastMapChangedName       [ MAX_MAPNAME_LENGHT ];
    new lastMapChangedFilePath   [ MAX_FILE_PATH_LENGHT ];
    new lastMapChangedCountString[ 10 ];

    formatex( lastMapChangedFilePath, charsmax( lastMapChangedFilePath ), "%s/%s", g_dataDirPath, LAST_CHANGE_MAP_FILE_NAME );

    LOG( 4, "( getRestartsOnTheCurrentMap ) mapToChange: %s,", mapToChange )
    LOG( 4, "( getRestartsOnTheCurrentMap ) lastMapChangedFilePath: %s", lastMapChangedFilePath )

    if( ( lastMapChangedFile = fopen( lastMapChangedFilePath, "rt" ) ) )
    {
        fgets( lastMapChangedFile, lastMapChangedName       , charsmax( lastMapChangedName        ) );
        fgets( lastMapChangedFile, lastMapChangedCountString, charsmax( lastMapChangedCountString ) );

        fclose( lastMapChangedFile );

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
                LOG( 4, "( getRestartsOnTheCurrentMap ) mapToChange is equal to lastMapChangedName." )
            }
            else
            {
                lastMapChangedCount = 0;
                LOG( 4, "( getRestartsOnTheCurrentMap ) mapToChange is not equal to lastMapChangedName." )
            }

            fprintf( lastMapChangedFile, "%d^n", lastMapChangedCount );
            fclose( lastMapChangedFile );
        }
        else
        {
            doAmxxLog( "ERROR, getRestartsOnTheCurrentMap: Couldn't open the file to write ^"%s^"", lastMapChangedFilePath );
        }

        LOG( 4, "( getRestartsOnTheCurrentMap ) lastMapChangedName: %s", lastMapChangedName )
        LOG( 4, "( getRestartsOnTheCurrentMap ) lastMapChangedCount: %d", lastMapChangedCount )
        LOG( 4, "( getRestartsOnTheCurrentMap ) lastMapChangedCountString: %s", lastMapChangedCountString )
    }
    else
    {
        doAmxxLog( "ERROR, getRestartsOnTheCurrentMap: Couldn't open the file to read ^"%s^"", lastMapChangedFilePath );

        if( ( lastMapChangedFile = fopen( lastMapChangedFilePath, "wt" ) ) )
        {
            fprintf( lastMapChangedFile, "nothing_to_be_added_by^n0^n" );
            fclose( lastMapChangedFile );
        }
        else
        {
            doAmxxLog( "ERROR, getRestartsOnTheCurrentMap: Couldn't open the file to write ^"%s^"", lastMapChangedFilePath );
        }

    }

    LOG( 1, "    ( getRestartsOnTheCurrentMap ) Returning lastMapChangedCount: %d", lastMapChangedCount )
    return lastMapChangedCount;
}

/**
 * Internally set the next map on `g_nextMapName` and save to the file `currentAndNextmapNames.dat`,
 * the current map name and the here provided nextMapName.
 *
 * @param currentMapName     the current map the server is playing
 * @param nextMapName        the next map the server will be playing
 * @param isToUpdateTheCvar  true if is to change the cvar `amx_nextmap` to the `nextMapName`,
 *                           otherwise false
 * @param forceUpdateFile    true if is to update current and next map names saved on the
 *                           `currentAndNextmapNames.dat` file, otherwise false
 */
stock setNextMap( currentMapName[], nextMapName[], bool:isToUpdateTheCvar = true, bool:forceUpdateFile = false )
{
    LOG( 128, "I AM ENTERING ON setNextMap(4) nextMapName: %s", nextMapName )

    // While the `IS_DISABLED_VOTEMAP_EXIT` bit flag is set, we cannot allow any decisions.
    if( g_voteMapStatus & IS_DISABLED_VOTEMAP_EXIT )
    {
        // We do not need to open the menu here, because on the vote end context, a setNextMap(4) function
        // call is always proceed by a process_last_round(2) function call, which will open the final choice
        // vote menu.
        copy( g_invokerVoteMapNameToDecide, charsmax( g_invokerVoteMapNameToDecide ), nextMapName );

        LOG( 1, "    ( setNextMap ) Just returning/blocking, g_voteMapStatus: %d", g_voteMapStatus )
        return;
    }

    if( IS_MAP_VALID( nextMapName ) )
    {
        // set the queryable cvar
        if( isToUpdateTheCvar
            || !( get_pcvar_num( cvar_nextMapChangeAnnounce )
                  && get_pcvar_num( cvar_endOfMapVote ) ) )
        {
            LOG( 2, "( setNextMap ) IS CHANGING THE CVAR 'amx_nextmap' to '%s'.", nextMapName )
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
        trim( nextMapName );
        trim( currentMapName );

        saveCurrentAndNextMapNames( currentMapName, nextMapName, forceUpdateFile );
        LOG( 2, "( setNextMap ) IS CHANGING THE global variable g_nextMapName to '%s'.", nextMapName )
    }
    else
    {
        LOG( 1, "AMX_ERR_PARAMS, %s, was tried to set a invalid next-map!", nextMapName )
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
stock saveCurrentAndNextMapNames( const currentMapName[], const nextMapName[], bool:forceUpdateFile = false )
{
    LOG( 128, "I AM ENTERING ON saveCurrentAndNextMapNames(3) currentMapName: %s, nextMapName: %s", currentMapName, nextMapName )

    // We do not need to check whether the `cvar_serverStartAction` is enabled or not, because the
    // execution flow only gets here when it is enabled.
    if( get_pcvar_num( cvar_isFirstServerStart ) != FIRST_SERVER_START
        || forceUpdateFile )
    {
        new backupMapsFile;
        new backupMapsFilePath[ MAX_FILE_PATH_LENGHT ];

        get_pcvar_string( cvar_mapcyclefile, backupMapsFilePath, charsmax( backupMapsFilePath ) );

        // We need to pass the `g_currentMapName` because the `currentMapName` to this call on the plugin_end(0)
        // is the former next map, instead of the current map. We need it to be the former next map in case of
        // a server crash, however the map cycle setting must to be save with the actual current map name.
        saveCurrentMapCycleSetting( g_currentMapName, backupMapsFilePath, g_nextMapCyclePosition );
        formatex( backupMapsFilePath, charsmax( backupMapsFilePath ), "%s/%s", g_dataDirPath, CURRENT_AND_NEXTMAP_FILE_NAME );

        if( ( backupMapsFile = fopen( backupMapsFilePath, "wt" ) ) )
        {
            fprintf( backupMapsFile, "%s^n", currentMapName );
            fprintf( backupMapsFile, "%s^n", nextMapName );
            fprintf( backupMapsFile, "%d^n", g_nextMapCyclePosition );

            fclose( backupMapsFile );
        }
        else
        {
            doAmxxLog( "ERROR, saveCurrentAndNextMapNames: Could not open the file backupMapsFilePath ^"%s^"", backupMapsFilePath );
        }
    }
}

/**
 *
 * @return true when the crashing was properly handled, false otherwise.
 */
public isHandledGameCrashAction( &startAction )
{
    LOG( 128, "I AM ENTERING ON isHandledGameCrashAction(1) startAction: %d", startAction )

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
    LOG( 128, "I AM ENTERING ON gameCrashActionFilePath(2) charsmaxGameCrashActionFilePath: %d", charsmaxGameCrashActionFilePath )

    formatex( gameCrashActionFilePath, charsmaxGameCrashActionFilePath, "%s/%s", g_dataDirPath, GAME_CRASH_RECREATION_FLAG_FILE );
    LOG( 1, "( generateGameCrashActionFilePath ) gameCrashActionFilePath: %s", gameCrashActionFilePath )
}

/**
 * Save the mp_maxrounds, etc and set them to half of it.
 */
public setGameToFinishAtHalfTime()
{
    LOG( 128, "I AM ENTERING ON setGameToFinishAtHalfTime(0)" )
    saveEndGameLimits();

    tryToSetGameModCvarFloat( cvar_mp_timelimit, g_originalTimelimit / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );
    tryToSetGameModCvarNum(   cvar_mp_maxrounds, g_originalMaxRounds / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );
    tryToSetGameModCvarNum(   cvar_mp_winlimit,  g_originalWinLimit  / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );
    tryToSetGameModCvarNum(   cvar_mp_fraglimit, g_originalFragLimit / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );

    LOG( 2, "( setGameToFinishAtHalfTime ) IS CHANGING THE CVAR 'mp_timelimit' to '%f'.", get_pcvar_float( cvar_mp_timelimit ) )
    LOG( 2, "( setGameToFinishAtHalfTime ) IS CHANGING THE CVAR 'mp_fraglimit' to '%d'.", get_pcvar_num( cvar_mp_fraglimit ) )
    LOG( 2, "( setGameToFinishAtHalfTime ) IS CHANGING THE CVAR 'mp_maxrounds' to '%d'.", get_pcvar_num( cvar_mp_maxrounds ) )
    LOG( 2, "( setGameToFinishAtHalfTime ) IS CHANGING THE CVAR 'mp_winlimit' to '%d'.", get_pcvar_num( cvar_mp_winlimit ) )
}

/**
 * Load the recent ban map from the file. If the number of valid maps loaded is lower than the
 * number of map loaded to fill the vote menu, not all the maps will be loaded.
 *
 * This also restrict the number of maps to be write to the file `RECENT_BAN_MAPS_FILE_NAME` as if
 * not all maps have been loaded here, on them will be written down to the file on
 * writeRecentMapsBanList(0).
 *
 * @param maximumLoadMapsCount    how many maps are loaded from the main map file list.
 */
public map_loadRecentBanList( maximumLoadMapsCount )
{
    LOG( 128, "I AM ENTERING ON map_loadRecentBanList(1) maximumLoadMapsCount: %d", maximumLoadMapsCount )

    new loadedMapsCount;
    new recentMapsFilePath[ MAX_FILE_PATH_LENGHT ];

    formatex( recentMapsFilePath, charsmax( recentMapsFilePath ), "%s/%s", g_dataDirPath, RECENT_BAN_MAPS_FILE_NAME );
    new recentMapsFileDescriptor = fopen( recentMapsFilePath, "rt" );

    if( recentMapsFileDescriptor )
    {
        new recentMapName[ MAX_MAPNAME_LENGHT ];

        // loads 6 maps to ban on `maxRecentMapsBans`
        new maxRecentMapsBans = get_pcvar_num( cvar_recentMapsBannedNumber );

        // load the total voting choices on `maxVotingChoices` as 6, supposing your voting menu has 6 maps
        new maxVotingChoices  = g_maxVotingChoices;

        // So, `maximumLoadMapsCount` is 10 (10 maps in my .txt file), therefore 10 > 6 (maxVotingChoices)
        if( maximumLoadMapsCount > maxVotingChoices )
        {
            // 6 + 6 > 10 =: 12 > 10
            if( maxRecentMapsBans + maxVotingChoices > maximumLoadMapsCount )
            {
                // Therefore the banned maps count will be 10 - 6 = 4
                maxRecentMapsBans = maximumLoadMapsCount - maxVotingChoices;
            }
        }
        else
        {
            maxRecentMapsBans = 0;
        }

        LOG( 4, "( map_loadRecentBanList ) maxVotingChoices: %d", maxVotingChoices )
        LOG( 4, "( map_loadRecentBanList ) maxRecentMapsBans: %d", maxRecentMapsBans )

        while( !feof( recentMapsFileDescriptor ) )
        {
            fgets( recentMapsFileDescriptor, recentMapName, charsmax( recentMapName ) );
            trim( recentMapName );

            if( recentMapName[ 0 ]
                && IS_MAP_VALID( recentMapName ) )
            {
                if( loadedMapsCount >= maxRecentMapsBans )
                {
                    break;
                }

                // Avoid banning twice the same map.
                if( !TrieKeyExists( g_recentMapsTrie, recentMapName ) )
                {
                    ArrayPushString( g_recentListMapsArray, recentMapName );
                    TrieSetCell( g_recentMapsTrie, recentMapName, 0 );

                    loadedMapsCount++;
                }
            }
        }

        fclose( recentMapsFileDescriptor );
    }

    LOG( 1, "    ( map_loadRecentBanList ) Returning loadedMapsCount: %d", loadedMapsCount )
    return loadedMapsCount;
}

stock writeRecentMapsBanList( loadedMapsCount )
{
    LOG( 128, "I AM ENTERING ON writeRecentMapsBanList(1) g_recentListMapsArray: %d", g_recentListMapsArray )

    new recentMapName     [ MAX_MAPNAME_LENGHT ];
    new recentMapsFilePath[ MAX_FILE_PATH_LENGHT ];

    formatex( recentMapsFilePath, charsmax( recentMapsFilePath ), "%s/%s", g_dataDirPath, RECENT_BAN_MAPS_FILE_NAME );
    new recentMapsFileDescriptor = fopen( recentMapsFilePath, "wt" );

    if( recentMapsFileDescriptor )
    {
        new bool:isOnlyRecentMapcycleMaps = get_pcvar_num( cvar_isOnlyRecentMapcycleMaps ) != 0;
        LOG( 4, "( writeRecentMapsBanList ) isOnlyRecentMapcycleMaps: %s", isOnlyRecentMapcycleMaps )

        // Do not repeatedly ban maps
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
        for( new mapIndex = 0; mapIndex < loadedMapsCount; ++mapIndex )
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
        LOG( 0, "", debugPrintRecentBanFile( recentMapsFilePath ) )
    }
    else
    {
        doAmxxLog( "WARNING, writeRecentMapsBanList: Couldn't find a valid map or the file doesn't exist ^"%s^"", recentMapsFilePath );
    }
}

stock debugPrintRecentBanFile( recentMapsFilePath[] )
{
    LOG( 128, "I AM ENTERING ON debugPrintRecentBanFile(1) recentMapsFilePath: %s", recentMapsFilePath )

    new loadedMapName[ MAX_MAPNAME_LENGHT ];
    new mapFileDescriptor = fopen( recentMapsFilePath, "rt" );

    while( !feof( mapFileDescriptor ) )
    {
        fgets( mapFileDescriptor, loadedMapName, charsmax( loadedMapName ) );
        trim( loadedMapName );

        static mapCount;

        if( mapCount++ < MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST
            && !( g_debug_level & 256 ) )
        {
            LOG( 4, "( debugPrintRecentBanFile ) %d, loadedMapName: %s", mapCount, loadedMapName )
        }

        LOG( 256, "( debugPrintRecentBanFile ) %d, loadedMapName: %s", mapCount, loadedMapName )
    }

    fclose( mapFileDescriptor );
    return 0;
}

stock loadWhiteListFileFromFile( &Array:whitelistArray, whiteListFilePath[] )
{
    LOG( 128, "I AM ENTERING ON loadWhiteListFileFromFile(2) whitelistArray: %d", whitelistArray)
    LOG( 8, "( loadWhiteListFileFromFile ) whiteListFilePath: %s", whiteListFilePath )

    new loadedCount;
    new whiteListFileDescriptor;
    new currentLine[ MAX_LONG_STRING ];

    TRY_TO_CLEAN( ArrayClear, whitelistArray, ArrayCreate( MAX_LONG_STRING ) )

    if( !( whiteListFileDescriptor = fopen( whiteListFilePath, "rt" ) ) )
    {
        LOG( 8, "ERROR! Invalid file descriptor. whiteListFileDescriptor: %d, whiteListFilePath: %s", \
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
            LOG( 8, "( loadWhiteListFileFromFile ) Adding the currentLine: %s", currentLine )
            ArrayPushString( whitelistArray, currentLine );

            loadedCount++;
        }
    }

    fclose( whiteListFileDescriptor );
    LOG( 1, "I AM EXITING loadWhiteListFileFromFile(2) whitelistArray: %d", whitelistArray )

    LOG( 1, "    ( loadWhiteListFileFromFile ) Returning loadedCount: %d", loadedCount )
    return loadedCount;
}

stock processLoadedGroupMapFileFrom( Array:playerFillerMapsArray, Array:fillersFilePathsArray,
                                     Trie:minPlayerFillerMapGroupTrie=Invalid_Trie, bool:isToClearTheTrie=true )
{
    LOG( 128, "I AM ENTERING ON processLoadedGroupMapFileFrom(2) groupCount: %d", ArraySize( fillersFilePathsArray ) )

    new loadedMapsTotal;
    new fillerFilePath[ MAX_FILE_PATH_LENGHT ];

    new Array:fillerMapsArray;
    new groupCount = ArraySize( fillersFilePathsArray );

    // fill remaining slots with random maps from each filler file, as much as possible
    for( new groupIndex = 0; groupIndex < groupCount; ++groupIndex )
    {
        fillerMapsArray = ArrayCreate( MAX_MAPNAME_LENGHT );
        ArrayGetString( fillersFilePathsArray, groupIndex, fillerFilePath, charsmax( fillerFilePath ) );

        loadedMapsTotal += map_populateList( fillerMapsArray, fillerFilePath, minPlayerFillerMapGroupTrie, isToClearTheTrie );
        ArrayPushCell( playerFillerMapsArray, fillerMapsArray );

        LOG( 8, "[%i] groupCount: %i, filersMapCount: %i", groupIndex, groupCount, ArraySize( fillerMapsArray ) )
        LOG( 8, "     fillersFilePaths[%i]: %s", groupIndex, fillerFilePath )
    }

    return loadedMapsTotal;
}

/**
 *  To start loading the files.
 */
stock loadMapFiles( bool:readMapCycle = true )
{
    LOG( 128, "I AM ENTERING ON loadMapFiles(1)" )

    enum LoadMapFilesTypes
    {
        t_Whitelist,
        t_MininumPlayers,
        t_MiddlePlayers,
        t_NormalPlayers
    }

    new loadedCount     [ LoadMapFilesTypes ];
    new mapFilerFilePath[ MAX_FILE_PATH_LENGHT ];

    // The Whitelist list must to be loaded as the fist thing as the configureTheNextMapSetttings(1)
    // need it to be loaded. And the configureTheNextMapSetttings(1) must to be the seconds thing to
    // be loaded because the everything else depends on it being properly set up.
    loadedCount[ t_Whitelist ] = configureTheWhiteListFeature( mapFilerFilePath );
    if( readMapCycle ) configureTheNextMapSetttings( mapFilerFilePath );

    loadedCount[ t_MininumPlayers ] = configureTheMinPlayersFeature( mapFilerFilePath );
    loadedCount[ t_MiddlePlayers  ] = configureTheMidPlayersFeature( mapFilerFilePath );
    loadedCount[ t_NormalPlayers  ] = configureTheNorPlayersFeature( mapFilerFilePath );

    configureTheRTVFeature( mapFilerFilePath );
    configureServerMapChange( mapFilerFilePath );
    loadTheBanRecentMapsFeature( loadedCount[ t_NormalPlayers ] );

    LOG( 4, "( loadMapFiles ) Maps Files Loaded." )
    LOG( 4, "" )
    LOG( 4, "" )
}

/**
 * @param mapFilerFilePath any string trash variable with length MAX_FILE_PATH_LENGHT
 */
stock configureTheRTVFeature( mapFilerFilePath[] )
{
    LOG( 128, "I AM ENTERING ON configureTheRTVFeature(1): %s", mapFilerFilePath )

    if( g_rtvCommands & RTV_CMD_STANDARD )
    {
        register_clcmd( "say rockthevote", "cmd_rockthevote", 0 );
    }

    if( get_pcvar_num( cvar_nomPlayerAllowance ) )
    {
        register_clcmd( "gal_votemap", "cmd_voteMap", ADMIN_MAP );
        register_clcmd( "say nominations", "cmd_nominations", 0, "- displays current nominations for next map" );
        register_concmd( "gal_listmaps", "map_listAll" );

        if( get_pcvar_num( cvar_nomPrefixes ) )
        {
            map_loadPrefixList( mapFilerFilePath );
        }

        loadNominationList( mapFilerFilePath );
    }

    LOG( 4, "" )
    LOG( 4, "" )
}

/**
 * Setup the main task that schedules the end map voting and allow round finish feature.
 *
 * @param mapFilerFilePath any string trash variable with length MAX_FILE_PATH_LENGHT
 */
stock configureServerMapChange( emptyCycleFilePath[] )
{
    LOG( 128, "I AM ENTERING ON configureServerMapChange(1): %s", emptyCycleFilePath )

    if( IS_WHITELIST_BLOCKING( IS_WHITELIST_ENABLED(), g_nextMapName ) )
    {
        new currentNextMap[ MAX_MAPNAME_LENGHT ];
        doAmxxLog( "( configureServerMapChange ) %s: %L", g_nextMapName, LANG_SERVER, "GAL_MATCH_WHITELIST" );

        copy( currentNextMap, charsmax( currentNextMap ), g_nextMapName );
        map_getNext( g_mapcycleFileListArray, currentNextMap, g_nextMapName, "mapcyclefile" );

        // Need to be called to trigger special behaviors.
        setNextMap( g_currentMapName, g_nextMapName );
    }

    if( get_pcvar_num( cvar_emptyServerWaitMinutes )
        || get_pcvar_num( cvar_isEmptyCycleByMapChange ) )
    {
        map_loadEmptyCycleList( emptyCycleFilePath );

        if( get_pcvar_num( cvar_emptyServerWaitMinutes ) )
        {
            set_task( 60.0, "inicializeEmptyCycleFeature" );
        }
    }
}

/**
 * @param mapFilerFilePath any string trash variable with length MAX_FILE_PATH_LENGHT
 */
stock configureTheNorPlayersFeature( mapFilerFilePath[] )
{
    LOG( 128, "I AM ENTERING ON configureTheNorPlayersFeature(1): %s", mapFilerFilePath )

    new loadedCount;
    get_pcvar_string( cvar_voteMapFilePath, mapFilerFilePath, MAX_FILE_PATH_LENGHT - 1 );

    if( mapFilerFilePath[ 0 ] )
    {
        if( file_exists( mapFilerFilePath )
            || mapFilerFilePath[ 0 ] == MAP_CYCLE_LOAD_FLAG
            || mapFilerFilePath[ 0 ] == MAP_FOLDER_LOAD_FLAG )
        {
            LOG( 4, "" )
            TRY_TO_CLEAN( clear_two_dimensional_array, g_norPlayerFillerMapGroupArrays, ArrayCreate() )

            TRY_TO_CLEAN( ArrayClear, g_voteNorPlayerFillerPathsArray, ArrayCreate( MAX_MAPNAME_LENGHT ) )
            TRY_TO_CLEAN( ArrayClear, g_norMaxMapsPerGroupToUseArray , ArrayCreate() )

            loadMapGroupsFeatureFile( mapFilerFilePath, g_voteNorPlayerFillerPathsArray, g_norMaxMapsPerGroupToUseArray );
            loadedCount = processLoadedGroupMapFileFrom( g_norPlayerFillerMapGroupArrays, g_voteNorPlayerFillerPathsArray );

            LOG( 4, "", debugLoadedGroupMapFileFrom( g_norPlayerFillerMapGroupArrays, g_norMaxMapsPerGroupToUseArray ) )
        }
        else
        {
            doAmxxLog( "ERROR, configureTheNorPlayersFeature: Could not open the file ^"%s^"", mapFilerFilePath );
        }
    }

    LOG( 1, "    ( configureTheNorPlayersFeature ) Returning loadedCount: %d", loadedCount )
    return loadedCount;
}

/**
 * @param mapFilerFilePath any string trash variable with length MAX_FILE_PATH_LENGHT
 */
stock configureTheMidPlayersFeature( mapFilerFilePath[] )
{
    LOG( 128, "I AM ENTERING ON configureTheMidPlayersFeature(1): %s", mapFilerFilePath )
    new loadedCount;

    if( get_pcvar_num( cvar_voteMidPlayers ) > VOTE_MIDDLE_PLAYERS_REQUIRED )
    {
        get_pcvar_string( cvar_voteMidPlayersMapFilePath, mapFilerFilePath, MAX_FILE_PATH_LENGHT - 1 );

        if( mapFilerFilePath[ 0 ] )
        {
            if( file_exists( mapFilerFilePath )
                || mapFilerFilePath[ 0 ] == MAP_CYCLE_LOAD_FLAG )
            {
                LOG( 4, "" )
                TRY_TO_CLEAN( clear_two_dimensional_array, g_midPlayerFillerMapGroupArrays, ArrayCreate() )

                TRY_TO_CLEAN( ArrayClear, g_voteMidPlayerFillerPathsArray, ArrayCreate( MAX_MAPNAME_LENGHT ) )
                TRY_TO_CLEAN( ArrayClear, g_midMaxMapsPerGroupToUseArray , ArrayCreate() )

                loadMapGroupsFeatureFile( mapFilerFilePath, g_voteMidPlayerFillerPathsArray, g_midMaxMapsPerGroupToUseArray );
                loadedCount = processLoadedGroupMapFileFrom( g_midPlayerFillerMapGroupArrays, g_voteMidPlayerFillerPathsArray );

                LOG( 4, "", debugLoadedGroupMapFileFrom( g_midPlayerFillerMapGroupArrays, g_midMaxMapsPerGroupToUseArray ) )
            }
            else
            {
                doAmxxLog( "ERROR, configureTheMidPlayersFeature: Could not open the file ^"%s^"", mapFilerFilePath );
            }
        }
    }

    LOG( 1, "    ( configureTheMidPlayersFeature ) Returning loadedCount: %d", loadedCount )
    return loadedCount;
}

/**
 * @param mapFilerFilePath any string trash variable with length MAX_FILE_PATH_LENGHT
 */
stock configureTheMinPlayersFeature( mapFilerFilePath[] )
{
    LOG( 128, "I AM ENTERING ON configureTheMinPlayersFeature(1): %s", mapFilerFilePath )
    new loadedCount;

    if( get_pcvar_num( cvar_voteMinPlayers ) > VOTE_MININUM_PLAYERS_REQUIRED )
    {
        get_pcvar_string( cvar_voteMinPlayersMapFilePath, mapFilerFilePath, MAX_FILE_PATH_LENGHT - 1 );

        if( mapFilerFilePath[ 0 ] )
        {
            if( file_exists( mapFilerFilePath )
                || mapFilerFilePath[ 0 ] == MAP_CYCLE_LOAD_FLAG )
            {
                LOG( 4, "" )
                TRY_TO_CLEAN( clear_two_dimensional_array, g_minPlayerFillerMapGroupArrays, ArrayCreate() )
                TRY_TO_CLEAN( TrieClear, g_minPlayerFillerMapGroupTrie , TrieCreate() )

                TRY_TO_CLEAN( ArrayClear, g_voteMinPlayerFillerPathsArray, ArrayCreate( MAX_MAPNAME_LENGHT ) )
                TRY_TO_CLEAN( ArrayClear, g_minMaxMapsPerGroupToUseArray , ArrayCreate() )

                loadMapGroupsFeatureFile( mapFilerFilePath, g_voteMinPlayerFillerPathsArray, g_minMaxMapsPerGroupToUseArray );

                loadedCount = processLoadedGroupMapFileFrom( g_minPlayerFillerMapGroupArrays,
                        g_voteMinPlayerFillerPathsArray, g_minPlayerFillerMapGroupTrie, false );

                LOG( 4, "", debugLoadedGroupMapFileFrom( g_minPlayerFillerMapGroupArrays, g_minMaxMapsPerGroupToUseArray ) )
            }
            else
            {
                doAmxxLog( "ERROR, configureTheMinPlayersFeature: Could not open the file ^"%s^"", mapFilerFilePath );
            }
        }
    }

    LOG( 1, "    ( configureTheMinPlayersFeature ) Returning loadedCount: %d", loadedCount )
    return loadedCount;
}

/**
 * @param mapFilerFilePath any string trash variable with length MAX_FILE_PATH_LENGHT
 */
stock configureTheWhiteListFeature( mapFilerFilePath[] )
{
    LOG( 128, "I AM ENTERING ON configureTheWhiteListFeature(1): %s", mapFilerFilePath )
    new loadedCount;

    if( IS_WHITELIST_ENABLED() )
    {
        LOG( 4, "" )

        get_pcvar_string( cvar_voteWhiteListMapFilePath, mapFilerFilePath, MAX_FILE_PATH_LENGHT - 1 );
        loadedCount = loadWhiteListFileFromFile( g_whitelistFileArray, mapFilerFilePath );

        computeNextWhiteListLoadTime( 1, false );
        loadTheWhiteListFeature();
    }

    LOG( 1, "    ( configureTheWhiteListFeature ) Returning loadedCount: %d", loadedCount )
    return loadedCount;
}

/**
 * Create the recent maps cvar and load the banned file list form the file system.
 *
 * @param maximumLoadMapsCount    how many maps are loaded from the main map file list.
 */
stock loadTheBanRecentMapsFeature( maximumLoadMapsCount )
{
    LOG( 128, "I AM ENTERING ON loadTheBanRecentMapsFeature(1)" )
    new loadedCount;

    if( get_pcvar_num( cvar_recentMapsBannedNumber ) )
    {
        TRY_TO_CLEAN( TrieClear, g_recentMapsTrie, TrieCreate() )
        TRY_TO_CLEAN( ArrayClear, g_recentListMapsArray, ArrayCreate( MAX_MAPNAME_LENGHT ) )

        // If we are only banning the maps on the map cycle, we should consider its size instead of
        // the voting filler's size.
        if( get_pcvar_num( cvar_isOnlyRecentMapcycleMaps ) )
        {
            loadedCount = map_loadRecentBanList( ArraySize( g_mapcycleFileListArray ) );
        }
        else
        {
            loadedCount = map_loadRecentBanList( maximumLoadMapsCount );
        }

        register_clcmd( "say recentmaps", "cmd_listrecent", 0 );

        // Do nothing if the map will be instantly changed
        if( get_pcvar_num( cvar_isFirstServerStart ) != FIRST_SERVER_START
            || !get_pcvar_num( cvar_serverStartAction ) )
        {
            writeRecentMapsBanList( loadedCount );
        }
    }

    LOG( 1, "    ( loadTheBanRecentMapsFeature ) Returning loadedCount: %d", loadedCount )
    return loadedCount;
}

stock debugLoadedGroupMapFileFrom( &Array:playerFillerMapsArray, &Array:maxMapsPerGroupToUseArray )
{
    LOG( 128, "I AM ENTERING ON debugLoadedGroupMapFileFrom(2) groupCount: %d", ArraySize( playerFillerMapsArray ) )

    new arraySize;
    new Array:fillerMapsArray;
    new fillerMap[ MAX_MAPNAME_LENGHT ];

    new groupCount = ArraySize( playerFillerMapsArray );

    // fill remaining slots with random maps from each filler file, as much as possible
    for( new groupIndex = 0; groupIndex < groupCount; ++groupIndex )
    {
        fillerMapsArray = ArrayGetCell( playerFillerMapsArray, groupIndex );
        arraySize = ArraySize( fillerMapsArray );

        LOG( 8, "[%i] maxMapsPerGroupToUse: %i, filersMapCount: %i", groupIndex, \
                ArrayGetCell( maxMapsPerGroupToUseArray, groupIndex ), arraySize )

        for( new mapIndex = 0; mapIndex < arraySize && mapIndex < 10; mapIndex++ )
        {
            GET_MAP_NAME( fillerMapsArray, mapIndex, fillerMap )
            LOG( 8, "   fillerMap[%i]: %s", mapIndex, fillerMap )
        }
    }

    return 0;
}

stock loadMapGroupsFeatureFile( mapFilerFilePath[], &Array:mapFilersPathArray, &Array:maxMapsPerGroupToUse )
{
    LOG( 128, "I AM ENTERING ON loadMapGroupsFeatureFile(3), mapFilerFilePath: %s", mapFilerFilePath )

    // The mapFilerFilePaths '*' and '#' disables The Map Groups Feature.
    if( mapFilerFilePath[ 0 ] != MAP_FOLDER_LOAD_FLAG
        && mapFilerFilePath[ 0 ] != MAP_CYCLE_LOAD_FLAG )
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

                LOG( 8, "" )
                LOG( 8, "this is a [groups] mapFilerFile" )

                // read the filler mapFilerFile to determine how many groups there are ( max of MAX_OPTIONS_IN_VOTE )
                while( !feof( mapFilerFile ) )
                {
                    fgets( mapFilerFile, currentReadedLine, charsmax( currentReadedLine ) );
                    trim( currentReadedLine );

                    LOG( 8, "currentReadedLine: %s   isdigit: %i   groupCount: %i  ", \
                            currentReadedLine, isdigit( currentReadedLine[ 0 ] ), groupCount )

                    if( isdigit( currentReadedLine[ 0 ] ) )
                    {
                        if( groupCount < MAX_OPTIONS_IN_VOTE )
                        {
                            groupCount++;

                            ArrayPushCell( maxMapsPerGroupToUse, str_to_num( currentReadedLine ) );
                            formatex( fillerFilePath, charsmax( fillerFilePath ), "%s/%i.ini", g_configsDirPath, groupCount );

                            ArrayPushString( mapFilersPathArray, fillerFilePath );
                            LOG( 8, "fillersFilePaths: %s", fillerFilePath )
                        }
                        else
                        {
                            LOG( 1, "AMX_ERR_BOUNDS, %L %L", LANG_SERVER, "GAL_GRP_FAIL_TOOMANY", \
                                    mapFilerFilePath, LANG_SERVER, "GAL_GRP_FAIL_TOOMANY_2" )

                            log_error( AMX_ERR_BOUNDS, "%L %L", LANG_SERVER, "GAL_GRP_FAIL_TOOMANY",
                                    mapFilerFilePath, LANG_SERVER, "GAL_GRP_FAIL_TOOMANY_2" );

                            break;
                        }
                    }
                }

                if( groupCount == 0 )
                {
                    LOG( 1, "AMX_ERR_GENERAL, %L", LANG_SERVER, "GAL_GRP_FAIL_NOCOUNTS", mapFilerFilePath )
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

            fclose( mapFilerFile );
        }
        else
        {
            LOG( 1, "AMX_ERR_NOTFOUND, %L", LANG_SERVER, "GAL_FILLER_NOTFOUND", mapFilerFilePath )
            log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_FILLER_NOTFOUND", mapFilerFilePath );

            goto loadTheDefaultMapFile;
        }
    }
    // we'll be loading all maps in the /maps folder or the current mapcycle file
    else
    {
        loadTheDefaultMapFile:

        // the options `*` and `#` will be handled by map_populateList(4) later.
        ArrayPushString( mapFilersPathArray, mapFilerFilePath );
        ArrayPushCell( maxMapsPerGroupToUse, MAX_OPTIONS_IN_VOTE );
    }

    LOG( 4, "( loadMapGroupsFeatureFile ) MapsGroups Loaded, mapFilerFilePath: %s", mapFilerFilePath )
    LOG( 4, "" )
    LOG( 4, "" )
}

/**
 * This event is not registered by mp_fraglimitCvarSupport(0) if the game does not support the
 * `mp_fraglimit` cvar natively or if the `cvar_fragLimitSupport` virtual support is not enabled.
 */
public client_death_event()
{
    LOG( 256, "I AM ENTERING ON client_death_event(0)" )
    new killerId = read_data( 1 );

    if( killerId < MAX_PLAYERS_COUNT
        && killerId > 0 )
    {
        new frags;

        if( ( frags = ++g_playersKills[ killerId ] ) > g_greatestKillerFrags )
        {
            g_greatestKillerFrags = frags;

            if( g_fragLimitNumber )
            {
                new endOfMapVote = get_pcvar_num( cvar_endOfMapVote );

                if( IS_TO_START_THE_VOTE_BY_FRAGS( g_fragLimitNumber - g_greatestKillerFrags )
                    && isTimeToStartTheEndOfMapVoting( endOfMapVote ) )
                {
                    start_voting_by_frags();
                }

                // This `? 2 : 1` condition allow Galileo to manage the round end, if it is enabled. Otherwise let
                // the actual game mod to do it. If the support is not virtual but the `mp_fraglimitCvarSupport`,
                // the try_to_manage_map_end(1) will to perform the map change.
                if( g_greatestKillerFrags > g_fragLimitNumber - ( endOfMapVote ? 2 : 1 ) )
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
    LOG( 128, "I AM ENTERING ON chooseTheEndOfMapStartOption(1) roundsRemaining: %d", roundsRemaining )
    new endOfMapVoteStart = get_pcvar_num( cvar_endOfMapVoteStart );

    switch( get_pcvar_num( cvar_endOnRound ) )
    {
        case END_AT_RIGHT_NOW:
        {
            // Sum +1 to start it earlier as the cannot block the map changing.
            if( endOfMapVoteStart
                && roundsRemaining < endOfMapVoteStart + 1 )
            {
                LOG( 1, "    ( chooseTheEndOfMapStartOption ) 1. Returning true." )
                return true;
            }
        }
        case END_AT_THE_CURRENT_ROUND_END:
        {
            if( GAME_ENDING_CONTEXT_SAVED( g_isTheLastGameRoundContext, g_isTheLastGameRound )
                || ( endOfMapVoteStart
                   && roundsRemaining < endOfMapVoteStart ) )
            {
                LOG( 1, "    ( chooseTheEndOfMapStartOption ) 2. Returning true." )
                return true;
            }
        }
        case END_AT_THE_NEXT_ROUND_END:
        {
            switch( endOfMapVoteStart )
            {
                case 1:
                {
                    if( GAME_ENDING_CONTEXT_SAVED( g_isTheLastGameRoundContext, g_isTheLastGameRound )
                        || ( endOfMapVoteStart
                           && roundsRemaining < endOfMapVoteStart ) )
                    {
                        LOG( 1, "    ( chooseTheEndOfMapStartOption ) 3. Returning true." )
                        return true;
                    }
                }
                case 2:
                {
                    if( GAME_ENDING_CONTEXT_SAVED( g_isThePenultGameRoundContext, g_isThePenultGameRound )
                        || ( endOfMapVoteStart
                             && roundsRemaining < endOfMapVoteStart ) )
                    {
                        LOG( 1, "    ( chooseTheEndOfMapStartOption ) 4. Returning true." )
                        return true;
                    }
                }
                default:
                {
                    if( endOfMapVoteStart
                        && roundsRemaining < endOfMapVoteStart )
                    {
                        LOG( 1, "    ( chooseTheEndOfMapStartOption ) 5. Returning true." )
                        return true;
                    }
                }
            }
        }
    }

    LOG( 1, "    ( chooseTheEndOfMapStartOption ) Returning false." )
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
    LOG( 128, "I AM ENTERING ON isToStartTheVotingOnThisRound(2) secondsRemaining: %d", secondsRemaining )

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

        LOG( 0, "", debugIsTimeToStartTheEndOfMap( secondsRemaining, 256 ) )

        new roundsRemaining = howManyRoundsAreRemaining( secondsPassed, gameEndingType );
        return chooseTheEndOfMapStartOption( roundsRemaining );
    }

    LOG( 1, "    ( isToStartTheVotingOnThisRound ) Just returning false." )
    return false;
}

/**
 * Calculates how time time the voting last.
 *
 * @param isToIncludeRunoff       whether to include the `runoff` time in the total. Its default value is true.
 * @return the total voting time in seconds.
 */
stock howManySecondsLastMapTheVoting( bool:isToIncludeRunoff = true )
{
    LOG( 128, "I AM ENTERING ON howManySecondsLastMapTheVoting(0)" )

    new temp;
    new Float:voteTime;

    // Until the pendingVoteCountdown(0) to finish takes getVoteAnnouncementTime() + VOTE_TIME_SEC + VOTE_TIME_SEC seconds.
    voteTime = getVoteAnnouncementTime( get_pcvar_num( cvar_isToAskForEndOfTheMapVote ) ) + VOTE_TIME_SEC + VOTE_TIME_SEC;

    // After, it takes more the `g_votingSecondsRemaining` until the the close vote function to be called.
    SET_VOTING_TIME_TO( temp, cvar_voteDuration )
    voteTime += temp;

    // When the voting is closed on closeVoting(0), take more VOTE_TIME_COUNT seconds until the result to be counted.
    voteTime += VOTE_TIME_COUNT;

    // Let us assume the worst case, then always will be performed a runoff voting.
    if( get_pcvar_num( cvar_runoffEnabled ) == RUNOFF_ENABLED
        && isToIncludeRunoff )
    {
        SET_VOTING_TIME_TO( temp, cvar_runoffDuration )
        voteTime = voteTime + voteTime + temp + VOTE_TIME_RUNOFF;
    }

    LOG( 1, "    ( howManySecondsLastMapTheVoting ) Returning the vote total time: %f", voteTime )
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
    LOG( 128, "I AM ENTERING ON howManyRoundsAreRemaining(2), g_roundAverageTime: %d", g_roundAverageTime )
    new avoidExtraRound;

    if( IS_THE_ROUND_AVERAGE_TIME_TOO_SHORT() )
    {
        avoidExtraRound = -2;
    }
    else if( IS_THE_ROUND_AVERAGE_TIME_SHORT() )
    {
        avoidExtraRound = -1;
    }

    switch( whatGameEndingType )
    {
        case GameEndingType_ByMaxRounds:
        {
            return GAME_ENDING_CONTEXT_SAVED( g_maxRoundsContextSaved, get_pcvar_num( cvar_mp_maxrounds ) )
                    - g_totalRoundsPlayed - 1 + avoidExtraRound;
        }
        case GameEndingType_ByWinLimit:
        {
            return GAME_ENDING_CONTEXT_SAVED( g_winLimitContextSaved, get_pcvar_num( cvar_mp_winlimit ) )
                    - max( g_totalCtWins, g_totalTerroristsWins ) - 1 + avoidExtraRound;
        }
        case GameEndingType_ByFragLimit:
        {
            new roundsLeftBy_frags = GAME_ENDING_CONTEXT_SAVED( g_fragLimitContextSaved, get_pcvar_num( cvar_mp_fraglimit ) )
                    - g_greatestKillerFrags;

            getRoundsRemainingBy( _, roundsLeftBy_frags );
            return roundsLeftBy_frags + avoidExtraRound;
        }
        case GameEndingType_ByTimeLimit:
        {
            // The secondsRemaining is already correctly updated by the `g_isGameEndingTypeContextSaved`.
            new roundsLeftBy_time = secondsRemaining;

            getRoundsRemainingBy( roundsLeftBy_time );
            return roundsLeftBy_time + avoidExtraRound;
        }
    }

    LOG( 1, "    ( howManyRoundsAreRemaining ) Returning MAX_INTEGER: %d", MAX_INTEGER )
    return MAX_INTEGER;
}

stock getRoundsRemainingBy( &by_time = 0, &by_frags = 0 )
{
    LOG( 128, "I AM ENTERING ON getRoundsRemainingBy(2), by_time: %d, by_frags: %d", by_time, by_frags )

    if( by_time  < 1 ) by_time  = 1;
    if( by_frags < 1 ) by_frags = 1;

    // Make sure there are enough data to operate, otherwise set valid data.
    if( g_totalRoundsSavedTimes > MIN_VOTE_START_ROUNDS_DELAY )
    {
        // Avoid zero division
        if( g_roundAverageTime )
        {
            by_time = by_time / g_roundAverageTime - 1;
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

            if( integerDivision )
            {
                by_frags = by_frags / integerDivision - 1;
            }
            else
            {
                by_frags = by_frags / FRAGS_BY_ROUND_AVERAGE;
            }
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

stock debugWhatGameEndingTypeItIs( rounds_left_by_maxrounds, rounds_left_by_time, rounds_left_by_winlimit,
                                   rounds_left_by_frags, debugLevel )
{
    LOG( debugLevel, "I AM ENTERING ON debugWhatGameEndingTypeItIs(5)" )

    LOG( debugLevel, "" )
    LOG( debugLevel, "( whatGameEndingTypeItIs ) cv_winlimit: %2d", get_pcvar_num( cvar_mp_winlimit  ) )
    LOG( debugLevel, "( whatGameEndingTypeItIs ) cv_maxrounds: %0d", get_pcvar_num( cvar_mp_maxrounds ) )
    LOG( debugLevel, "( whatGameEndingTypeItIs ) cv_time: %6f", get_pcvar_float( cvar_mp_timelimit ) )
    LOG( debugLevel, "( whatGameEndingTypeItIs ) cv_frags: %5d", get_pcvar_num( cvar_mp_fraglimit ) )

    LOG( debugLevel, "( whatGameEndingTypeItIs )" )
    LOG( debugLevel, "( whatGameEndingTypeItIs ) rounds_left_by_winlimit: %2d", rounds_left_by_winlimit )
    LOG( debugLevel, "( whatGameEndingTypeItIs ) rounds_left_by_maxrounds: %0d", rounds_left_by_maxrounds )
    LOG( debugLevel, "( whatGameEndingTypeItIs ) rounds_left_by_time: %6d", rounds_left_by_time )
    LOG( debugLevel, "( whatGameEndingTypeItIs ) rounds_left_by_frags: %5d", rounds_left_by_frags )

    LOG( debugLevel, "( whatGameEndingTypeItIs )" )
    LOG( debugLevel, "( whatGameEndingTypeItIs ) GameEndingType_ByWinLimit: %2d", GameEndingType_ByWinLimit )
    LOG( debugLevel, "( whatGameEndingTypeItIs ) GameEndingType_ByMaxRounds: %d", GameEndingType_ByMaxRounds )
    LOG( debugLevel, "( whatGameEndingTypeItIs ) GameEndingType_ByTimeLimit: %d", GameEndingType_ByTimeLimit )
    LOG( debugLevel, "( whatGameEndingTypeItIs ) GameEndingType_ByFragLimit: %d", GameEndingType_ByFragLimit )

    LOG( debugLevel, "" )
    return 0;
}

/**
 * Wrapper to call switchEndingGameType(10) without repeating the same `if` code everywhere.
 */
#define SWITCH_ENDING_GAME_TYPE_RETURN(%0,%1,%2,%3,%4,%5,%6,%7,%8,%9) \
{ \
    gameType = switchEndingGameType( %0, %1, %2, %3, %4, %5, %6, %7, %8, %9 ); \
    if( gameType != GameEndingType_ByNothing ) \
    { \
        LOG( 1, "    ( SWITCH_ENDING_GAME_TYPE_RETURN ) Returning GameEndingType: %d", gameType ) \
        return gameType; \
    } \
}

stock GameEndingType:whatGameEndingTypeItIs()
{
    LOG( 128, "I AM ENTERING ON whatGameEndingTypeItIs(0)" )
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
    LOG( 0, "", debugWhatGameEndingTypeItIs( by_maxrounds, by_time, by_winlimit, by_frags, 256 ) )

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

    LOG( 256, "    ( whatGameEndingTypeItIs ) Returning: %d", GameEndingType_ByNothing )
    return GameEndingType_ByNothing;
}

stock GameEndingType:switchEndingGameType( by_maxrounds, cv_maxrounds, by_time, cv_time, by_winlimit, cv_winlimit,
                                           by_frags, cv_frags, GameEndingType:type, bool:allowSelfReturn )
{
    LOG( 256, "I AM ENTERING ON switchEndingGameType(10) GameEndingType: %d", type )

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
                LOG( 256, "    ( switchEndingGameType ) 1" )
                return type;
            }
        }
        else if( cv_time > 0
                 && cv_winlimit > 0 )
        {
            if( by_time > by_maxrounds
                && by_winlimit > by_maxrounds )
            {
                LOG( 256, "    ( switchEndingGameType ) 2" )
                return type;
            }
        }
        else if( cv_time > 0
                 && cv_frags > 0 )
        {
            if( by_time > by_maxrounds
                && by_frags > by_maxrounds )
            {
                LOG( 256, "    ( switchEndingGameType ) 3" )
                return type;
            }
        }
        else if( cv_winlimit > 0
                 && cv_frags > 0 )
        {
            if( by_winlimit > by_maxrounds
                && by_frags > by_maxrounds )
            {
                LOG( 256, "    ( switchEndingGameType ) 4" )
                return type;
            }
        }
        // If the `by_maxrounds` did not fall in any of these above traps to fall out the `if-else` chain,
        // it is safe to let if free from this point towards.
        else if( cv_time > 0
                 && by_time > by_maxrounds )
        {
            LOG( 256, "    ( switchEndingGameType ) 5" )
            return type;
        }
        else if( cv_winlimit > 0
                 && by_winlimit > by_maxrounds )
        {
            LOG( 256, "    ( switchEndingGameType ) 6" )
            return type;
        }
        else if( cv_frags > 0
                 && by_frags > by_maxrounds )
        {
            LOG( 256, "    ( switchEndingGameType ) 7" )
            return type;
        }
        else if( allowSelfReturn )
        {
            LOG( 256, "    ( switchEndingGameType ) 8" )
            return type;
        }
    }

    LOG( 256, "    ( switchEndingGameType ) Returning GameEndingType_ByNothing: %d", GameEndingType_ByNothing )
    return GameEndingType_ByNothing;
}

stock debugIsTimeToStartTheEndOfMap( secondsRemaining, debugLevel )
{
    LOG( 128, "I AM ENTERING ON debugIsTimeToStartTheEndOfMap(2)" )
    new taskExist = task_exists( TASKID_START_VOTING_DELAYED );

    LOG( debugLevel, "" )
    LOG( debugLevel, "( isTimeToStartTheEndOfMapVoting ) task_exists TASKID_START_VOTING_DELAYED: %d", taskExist )
    LOG( debugLevel, "( isTimeToStartTheEndOfMapVoting ) g_isTheLastGameRound: %d", g_isTheLastGameRound )
    LOG( debugLevel, "( isTimeToStartTheEndOfMapVoting ) g_isThePenultGameRound: %d", g_isThePenultGameRound )
    LOG( debugLevel, "( isTimeToStartTheEndOfMapVoting ) debugLevel: %d", debugLevel )
    LOG( debugLevel, "( isTimeToStartTheEndOfMapVoting ) secondsRemaining: %d", secondsRemaining )
    LOG( debugLevel, "( isTimeToStartTheEndOfMapVoting ) cvar_endOnRound: %d", get_pcvar_num( cvar_endOnRound ) )
    LOG( debugLevel, "( isTimeToStartTheEndOfMapVoting ) cvar_endOfMapVote: %d", get_pcvar_num( cvar_endOfMapVote ) )
    LOG( debugLevel, "( isTimeToStartTheEndOfMapVoting ) cvar_endOfMapVoteStart: %d", get_pcvar_num( cvar_endOfMapVoteStart ) )
    LOG( debugLevel, "( isTimeToStartTheEndOfMapVoting ) START_VOTEMAP_MIN_TIME: %d",  START_VOTEMAP_MIN_TIME )
    LOG( debugLevel, "( isTimeToStartTheEndOfMapVoting ) START_VOTEMAP_MAX_TIME: %d",  START_VOTEMAP_MAX_TIME )
    LOG( debugLevel, "( isTimeToStartTheEndOfMapVoting ) g_totalRoundsSavedTimes: %d", g_totalRoundsSavedTimes )
    LOG( debugLevel, "( isTimeToStartTheEndOfMapVoting ) PERIODIC_CHECKING_INTERVAL: %d", PERIODIC_CHECKING_INTERVAL )
    LOG( debugLevel, "( isTimeToStartTheEndOfMapVoting ) MIN_VOTE_START_ROUNDS_DELAY: %d", MIN_VOTE_START_ROUNDS_DELAY )
    LOG( debugLevel, "( isTimeToStartTheEndOfMapVoting ) IS_END_OF_MAP_VOTING_GOING_ON(): %d", IS_END_OF_MAP_VOTING_GOING_ON() )
    LOG( debugLevel, "" )

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
stock isTimeToStartTheEndOfMapVoting( endOfMapVote )
{
    LOG( 256, "I AM ENTERING ON isTimeToStartTheEndOfMapVoting(1) secondsRemaining: %d", get_timeleft() )
    LOG( 0, "", debugIsTimeToStartTheEndOfMap( get_timeleft(), 32 ) )

    if( !IS_END_OF_MAP_VOTING_GOING_ON()
        && !task_exists( TASKID_START_VOTING_DELAYED )
        && endOfMapVote )
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
           || IS_THE_ROUND_TIME_TOO_BIG( get_pcvar_float( cvar_mp_roundtime ) )
           || IS_THE_ROUND_AVERAGE_TIME_TOO_SHORT() )
        {
            LOG( 256, "    ( isTimeToStartTheEndOfMapVoting ) Just returning true." )
            return true;
        }
    }

    LOG( 256, "    ( isTimeToStartTheEndOfMapVoting ) Just returning false." )
    return false;
}

/**
 * This only handles the voting starting by limit expiration.
 *
 * The map will not accept to change when the voting is running due the restriction on
 * try_to_process_last_round(2). On the cases where that restriction does not have effect, the
 * voting will already have been started by vote_manageEnd(0) when the maximum allowed time comes.
 */
stock tryToStartTheVotingOnThisRound( startDelay )
{
    LOG( 128, "I AM ENTERING ON tryToStartTheVotingOnThisRound(1) startDelay: %d", startDelay )

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
                set_task( float( startDelay ), "start_voting_by_winlimit", TASKID_START_VOTING_DELAYED );
            }
            case GameEndingType_ByMaxRounds:
            {
                set_task( float( startDelay ), "start_voting_by_maxrounds", TASKID_START_VOTING_DELAYED );
            }
            case GameEndingType_ByFragLimit:
            {
                set_task( float( startDelay ), "start_voting_by_frags", TASKID_START_VOTING_DELAYED );
            }
            default:
            {
                set_task( float( startDelay ), "start_voting_by_timer", TASKID_START_VOTING_DELAYED );
            }
        }
    }
}

stock debugTeamWinEvent( string_team_winner[], wins_CT_trigger, wins_Terrorist_trigger )
{
    LOG( 32, "( team_win_event )" )
    LOG( 32, "( team_win_event ) string_team_winner: %s", string_team_winner )
    LOG( 32, "( team_win_event ) g_winLimitNumber: %d", g_winLimitNumber )
    LOG( 32, "( team_win_event ) wins_CT_trigger: %d", wins_CT_trigger )
    LOG( 32, "( team_win_event ) wins_Terrorist_trigger: %d", wins_Terrorist_trigger )
    LOG( 32, "( team_win_event ) g_isGameEndingTypeContextSaved: %d", g_isGameEndingTypeContextSaved )
    LOG( 32, "( team_win_event ) g_gameEndingTypeContextSaved: %d", g_gameEndingTypeContextSaved )
    LOG( 32, "( team_win_event ) g_timeLeftContextSaved: %d", g_timeLeftContextSaved )
    LOG( 32, "( team_win_event ) g_maxRoundsContextSaved: %d", g_maxRoundsContextSaved )
    LOG( 32, "( team_win_event ) g_winLimitContextSaved: %d", g_winLimitContextSaved )
    LOG( 32, "( team_win_event ) g_fragLimitContextSaved: %d", g_fragLimitContextSaved )
    LOG( 32, "( team_win_event ) g_isTheLastGameRound: %d", g_isTheLastGameRound )
    LOG( 32, "( team_win_event ) g_isTheLastGameRoundContext: %d", g_isTheLastGameRoundContext )
    LOG( 32, "( team_win_event ) g_isThePenultGameRound: %d", g_isThePenultGameRound )
    LOG( 32, "( team_win_event ) g_isThePenultGameRoundContext: %d", g_isThePenultGameRoundContext )
    LOG( 32, "( team_win_event )" )

    return 0;
}

public team_win_event()
{
    LOG( 128, "" )
    LOG( 128, "" )
    LOG( 128, "I AM ENTERING ON team_win_event(0)" )

    new wins_Terrorist_trigger;
    new wins_CT_trigger;
    new string_team_winner[ 16 ];

    g_isTheRoundEnded = true;
    read_logargv( 1, string_team_winner, charsmax( string_team_winner ) );

    if( string_team_winner[ 0 ] == 'T' )
    {
        g_totalTerroristsWins++;
    }
    else if( string_team_winner[ 0 ] == 'C' )
    {
        g_totalCtWins++;
    }

    g_winLimitNumber = get_pcvar_num( cvar_mp_winlimit );

    if( g_winLimitNumber )
    {
        wins_CT_trigger        = g_totalCtWins + VOTE_START_ROUNDS;
        wins_Terrorist_trigger = g_totalTerroristsWins + VOTE_START_ROUNDS;

        if( ( wins_CT_trigger > g_winLimitNumber
              || wins_Terrorist_trigger > g_winLimitNumber )
            && isTimeToStartTheEndOfMapVoting( get_pcvar_num( cvar_endOfMapVote ) ) )
        {
            START_VOTING_BY_MIDDLE_ROUND_DELAY( "start_voting_by_winlimit" )
        }

        if( g_totalCtWins > g_winLimitNumber - 2
            || g_totalTerroristsWins > g_winLimitNumber - 2 )
        {
            try_to_manage_map_end();
        }
    }

    if( g_voteStatus & IS_VOTE_IN_PROGRESS )
    {
        g_isTheRoundEndWhileVoting = true;
    }

    LOG( 0, "", debugTeamWinEvent( string_team_winner, wins_CT_trigger, wins_Terrorist_trigger ) )
}

public round_end_event()
{
    LOG( 128, "I AM ENTERING ON round_end_event(0)" )

    new current_rounds_trigger;
    saveTheRoundTime();

    g_isTheRoundEnded = true;
    g_totalRoundsPlayed++;

    // Get the updated value.
    g_maxRoundsNumber = get_pcvar_num( cvar_mp_maxrounds );

    // Also update their values when calling this function.
    g_fragLimitNumber = get_pcvar_num( cvar_mp_fraglimit );
    g_timeLimitNumber = get_pcvar_num( cvar_mp_timelimit );

    if( g_maxRoundsNumber )
    {
        current_rounds_trigger = g_totalRoundsPlayed + VOTE_START_ROUNDS;

        if( current_rounds_trigger > g_maxRoundsNumber
            && isTimeToStartTheEndOfMapVoting( get_pcvar_num( cvar_endOfMapVote ) ) )
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
    if( IS_ABLE_TO_PERFORM_A_MAP_CHANGE() )
    {
        endRoundWatchdog();
    }

    if( g_voteStatus & IS_VOTE_IN_PROGRESS )
    {
        g_isTheRoundEndWhileVoting = true;
    }

    LOG( 32, "( round_end_event ) g_maxRoundsNumber: %d", g_maxRoundsNumber )
    LOG( 32, "( round_end_event ) g_totalRoundsPlayed: %d, current_rounds_trigger: %d", \
            g_totalRoundsPlayed, current_rounds_trigger )
}

/**
 * Called on the round_end_event(). This is the place to change the map when the variables
 * `g_isThePenultGameRound` and `g_isTheLastGameRound` are set to true.
 */
stock endRoundWatchdog()
{
    LOG( 128, "I AM ENTERING ON endRoundWatchdog(0)" )
    new bool:endOfMapVoteExpiration = get_pcvar_num( cvar_endOfMapVoteExpiration ) != 0;

    if( endOfMapVoteExpiration
        && g_voteStatus & IS_VOTE_OVER )
    {
        // Make the map to change immediately.
        g_isTheLastGameRound   = true;
        g_isThePenultGameRound = false;
    }

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

stock saveTheRoundTime()
{
    LOG( 128, "I AM ENTERING ON saveTheRoundTime(0)" )
    new roundTotalTime = floatround( get_gametime(), floatround_ceil ) - g_roundStartTime;

    // Rounds taking less than 10 seconds does not seem to fit.
    if( roundTotalTime > MIN_ROUND_TIME_DELAY )
    {
        static lastSavedRound;
        static roundPlayedTimes[ MAX_SAVED_ROUNDS_FOR_AVERAGE ];

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

        LOG( 32, "( saveTheRoundTime ) Total Sum: %d", g_roundAverageTime )
        g_roundAverageTime = ( g_roundAverageTime / g_totalRoundsSavedTimes ) + 1;

        // Updates the next position to be inserted.
        lastSavedRound = ( lastSavedRound + 1 ) % sizeof roundPlayedTimes;

        LOG( 32, "( saveTheRoundTime ) lastSavedRound: %d", lastSavedRound )
        LOG( 32, "( saveTheRoundTime ) g_roundAverageTime: %d", g_roundAverageTime )
        LOG( 32, "( saveTheRoundTime ) g_totalRoundsSavedTimes: %d", g_totalRoundsSavedTimes )
    }

    LOG( 32, "( saveTheRoundTime ) roundTotalTime: %d", roundTotalTime )
}

/**
 * Called before the freeze time to start counting. This event is not called for the first game round.
 */
public new_round_event()
{
    LOG( 128, "I AM ENTERING ON new_round_event(0)" )
    tryToStartTheVotingOnThisRound( ROUND_VOTING_START_SECONDS_DELAY() );

    if( g_isTheLastGameRound
        && IS_ABLE_TO_PERFORM_A_MAP_CHANGE()
        && get_pcvar_num( cvar_endOnRoundChange ) == MAP_CHANGES_AT_THE_NEXT_ROUND_START )
    {
        try_to_process_last_round();
    }
}

/**
 * Called after the freeze time to stop counting.
 */
public round_start_event()
{
    LOG( 128, "I AM ENTERING ON round_start_event(0)" )

    // Provide the new_round_event(0) support for HLTV non supported game mods.
    if( !IS_NEW_ROUND_EVENT_SUPPORTED() )
    {
        new_round_event();
    }

    g_isTheRoundEnded = false;
    g_roundStartTime  = floatround( get_gametime(), floatround_ceil );

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

stock try_to_manage_map_end( bool:isFragLimitEnd = false )
{
    LOG( 128, "I AM ENTERING ON try_to_manage_map_end()" )

    if( g_isOnMaintenanceMode )
    {
        prevent_map_change();
        color_chat( 0, "%L", LANG_PLAYER, "GAL_CHANGE_MAINTENANCE" );
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
 * This is a fail safe to not allow map changes if must there be a map voting and it was not
 * finished/performed yet.
 */
stock try_to_process_last_round( bool:isFragLimitEnd = false )
{
    LOG( 128, "I AM ENTERING ON try_to_process_last_round(0)" )
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
 * must to be handled by tryToStartTheVotingOnThisRound(1), to start the voting on round before
 * the actual last round.
 */
public map_manageEnd()
{
    LOG( 128, "I AM ENTERING ON map_manageEnd(0)" )
    LOG( 2, "%32s mp_timelimit: %f", "map_manageEnd(in)", get_pcvar_float( cvar_mp_timelimit ) )

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
            LOG( 1, "    ( map_manageEnd ) Just returning and blocking the end management." )
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

    LOG( 2, "%32s mp_timelimit: %f", "map_manageEnd(out)", get_pcvar_float( cvar_mp_timelimit ) )
    LOG( 1, "    ( map_manageEnd ) Just returning and allowing the end management." )
    return true;
}

stock saveGameEndingTypeContext()
{
    LOG( 128, "I AM ENTERING ON saveGameEndingTypeContext(0)" )
    g_isGameEndingTypeContextSaved = true;

    // Save a round time which will force the voting to start immediately by howManyRoundsAreRemaining(2).
    g_gameEndingTypeContextSaved = whatGameEndingTypeItIs();

    g_timeLeftContextSaved  = get_timeleft() ? MIN_ROUND_TIME_DELAY - 1 : 0;
    g_timeLimitContextSaved = get_pcvar_float( cvar_mp_timelimit );
    g_maxRoundsContextSaved = get_pcvar_num( cvar_mp_maxrounds );
    g_winLimitContextSaved  = get_pcvar_num( cvar_mp_winlimit );
    g_fragLimitContextSaved = get_pcvar_num( cvar_mp_fraglimit );

    // We need to save this variables because they are set at the round end before the new round start.
    g_isTheLastGameRoundContext   = g_isTheLastGameRound;
    g_isThePenultGameRoundContext = g_isThePenultGameRound;
}

/**
 * This need to prevent the map changing at least for the voting time plus 1 minutes when the
 * `gal_endonround` feature is enabled and blocking the map end. This is because it allows the
 * voting to start very close, may be even after this blocker function to be called.
 */
stock prevent_map_change()
{
    LOG( 128, "I AM ENTERING ON prevent_map_change(0)" )
    saveEndGameLimits();

    // If somehow the cvar_mp_roundtime does not exist, it will point to a cvar within zero
    new Float:roundTimeMinutes    = get_pcvar_float( cvar_mp_roundtime );
    new Float:maxRoundTimeMinutes = get_pcvar_float( cvar_endOnRoundMax );

    // Prevent the map from ending automatically.
    tryToSetGameModCvarFloat( cvar_mp_timelimit, 0.0 );
    tryToSetGameModCvarNum(   cvar_mp_maxrounds, 0   );
    tryToSetGameModCvarNum(   cvar_mp_winlimit,  0   );
    tryToSetGameModCvarNum(   cvar_mp_fraglimit, 0   );

    LOG( 2, "( prevent_map_change ) IS CHANGING THE CVAR %-22s to '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOG( 2, "( prevent_map_change ) IS CHANGING THE CVAR %-22s to '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOG( 2, "( prevent_map_change ) IS CHANGING THE CVAR %-22s to '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOG( 2, "( prevent_map_change ) IS CHANGING THE CVAR %-22s to '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )

    if( ( maxRoundTimeMinutes < 1 )
        || ( ( maxRoundTimeMinutes * 60.0 ) < ( g_totalVoteTime + 60.0 ) ) )
    {
        maxRoundTimeMinutes = ( float( g_totalVoteTime ) / 60.0 ) + 1.0;
    }

    // Prevent the map from being played indefinitely. We do not need to check here for the
    // `g_isThePenultGameRound` because it is being properly handled on endRoundWatchdog(0).
    if( g_isTheLastGameRound
        || ( roundTimeMinutes < 0.1 )
        || ( ( roundTimeMinutes * 3.0 ) > maxRoundTimeMinutes ) )
    {
        roundTimeMinutes = maxRoundTimeMinutes;
    }
    else
    {
        roundTimeMinutes *= 3.0;
    }

    LOG( 2, "( prevent_map_change ) g_totalVoteTime:     %d", g_totalVoteTime )
    LOG( 2, "( prevent_map_change ) roundTimeMinutes:    %f", roundTimeMinutes )
    LOG( 2, "( prevent_map_change ) maxRoundTimeMinutes: %f", maxRoundTimeMinutes )

    cacheCvarsValues();
    set_task( roundTimeMinutes * 60, "map_restoreEndGameCvars", TASKID_PREVENT_INFITY_GAME );
}

/**
 * To perform the switch between the straight intermission_processing(0) and the last_round_countdown(0).
 *
 * This is used to be called from the computeVotes(0) end voting function, there to call process_last_round(2)
 * with the variable `g_isToChangeMapOnVotingEnd` properly set.
 */
stock process_last_round( bool:isToImmediatelyChangeLevel, bool:isCountDownAllowed = true )
{
    LOG( 128, "I AM ENTERING ON process_last_round(2) isToImmediatelyChangeLevel: %d", isToImmediatelyChangeLevel )

    // While the `IS_DISABLED_VOTEMAP_EXIT` bit flag is set, we cannot allow any decisions
    if( g_voteMapStatus & IS_DISABLED_VOTEMAP_EXIT )
    {
        // When this is called, there is not anyone else trying to show action menu, therefore
        // invoke it before returning.
        openTheVoteMapActionMenu();

        LOG( 1, "    ( process_last_round ) Just returning/blocking, g_voteMapStatus: %d", g_voteMapStatus )
        return;
    }

    if( isToImmediatelyChangeLevel )
    {
        if( isCountDownAllowed
            && get_pcvar_num( cvar_isEndMapCountdown ) & IS_MAP_MAPCHANGE_COUNTDOWN )
        {
            // If somehow this is called twice, do nothing on the second time.
            if( !task_exists( TASKID_PROCESS_LAST_ROUND_COUNT ) )
            {
                new totalTime;
                new freezeTime;
                new nextMapName[ MAX_MAPNAME_LENGHT ];

                // IF there is a freeze time, and it is not too much big.
                if( ( freezeTime = get_pcvar_num( cvar_mp_freezetime ) )
                    && freezeTime < 15 )
                {
                    // If true, this was trigged on the new round.
                    if( abs( floatround( get_gametime(), floatround_ceil ) - g_roundStartTime ) <= freezeTime + 3 )
                    {
                        totalTime = freezeTime;
                    }
                    else
                    {
                        // On Counter-Strike Condition Zero, 5 seems to be the time between the round end/start events.
                        totalTime = freezeTime + 5;
                    }
                }
                else
                {
                    // If there is not freeze time, just do a countdown from 6.
                    totalTime = 6;
                }

                g_lastRoundCountdown = totalTime;

                remove_task( TASKID_SHOW_LAST_ROUND_HUD );
                set_task( 1.0, "last_round_countdown", TASKID_PROCESS_LAST_ROUND_COUNT, _, _, "a", totalTime );

                get_pcvar_string( cvar_amx_nextmap, nextMapName, charsmax( nextMapName ) );
                color_chat( 0, "%L...", LANG_PLAYER, "DMAP_MAP_CHANGING_IN2", nextMapName, totalTime );
            }
        }
        else
        {
            remove_task( TASKID_SHOW_LAST_ROUND_HUD );
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
    LOG( 128, "I AM ENTERING ON intermission_processing(0)" )
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
    LOG( 128, "I AM ENTERING ON get_intermission_chattime(0)" )
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
    LOG( 128, "I AM ENTERING ON show_intermission(1) mp_chattime: %f", mp_chattime )
    new endGameType = get_pcvar_num( cvar_isEndMapCountdown );

    if( endGameType )
    {
        set_task( mp_chattime - 0.5, "intermission_hold", TASKID_INTERMISSION_HOLD );
        intermission_effects( endGameType, mp_chattime );
    }
    else
    {
        LOG( 4, " ( show_intermission ) Do nothing, just change the map." )
        intermission_hold();
    }
}

public intermission_hold()
{
    LOG( 128, "I AM ENTERING ON intermission_hold(0)" )

    message_begin( MSG_ALL, SVC_INTERMISSION );
    message_end();
}

stock intermission_effects( endGameType, Float:mp_chattime )
{
    LOG( 128, "I AM ENTERING ON intermission_effects(1) endGameType: %d", endGameType )

    if( endGameType & IS_MAP_MAPCHANGE_FREEZE_PLAYERS )
    {
        g_original_sv_maxspeed = get_pcvar_float( cvar_sv_maxspeed );
        tryToSetGameModCvarFloat( cvar_sv_maxspeed, 0.0 );

        LOG( 2, "( intermission_effects ) IS CHANGING THE CVAR 'sv_maxspeed' to '%f'.", get_pcvar_float( cvar_sv_maxspeed ) )
    }

    if( cvar_mp_friendlyfire
        && endGameType & IS_MAP_MAPCHANGE_FRIENDLY_FIRE )
    {
        if( ( g_isToRestoreFriendlyFire = get_pcvar_num( cvar_mp_friendlyfire ) == 0 ) )
        {
            tryToSetGameModCvarNum( cvar_mp_friendlyfire, 1 );
        }

        LOG( 2, "( intermission_effects ) IS CHANGING THE CVAR 'mp_friendlyfire' to '%d'.", get_pcvar_num( cvar_mp_friendlyfire ) )
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
    LOG( 128, "I AM ENTERING ON last_round_countdown(0) g_lastRoundCountdown: %d", g_lastRoundCountdown )
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
    LOG( 128, "I AM ENTERING ON configure_last_round_HUD(0)" )

    if( !( get_pcvar_num( cvar_hudsHide ) & HUD_CHANGELEVEL_ANNOUNCE ) )
    {
        remove_task( TASKID_SHOW_LAST_ROUND_HUD );
        set_task( 7.0, "setup_last_round_HUD", TASKID_SHOW_LAST_ROUND_HUD );
    }

    show_last_round_message();
}

public setup_last_round_HUD()
{
    LOG( 128, "I AM ENTERING ON setup_last_round_HUD(0) g_showLastRoundHudCounter: %d", g_showLastRoundHudCounter )

    g_showLastRoundHudCounter = 0;
    set_task( 1.0, "show_last_round_HUD", TASKID_SHOW_LAST_ROUND_HUD, _, _, "b" );
}

public show_last_round_message()
{
    LOG( 128, "I AM ENTERING ON show_last_round_message(0)" )

    new nextMapName[ MAX_MAPNAME_LENGHT ];
    get_pcvar_string( cvar_amx_nextmap, nextMapName, charsmax( nextMapName ) );

    if( g_voteStatus & IS_VOTE_OVER )
    {
        if( g_isTheLastGameRound
            && !g_isToChangeMapOnVotingEnd )
        {
            color_chat( 0, "%L %L", \
                    LANG_PLAYER, "GAL_CHANGE_NEXTROUND", \
                    LANG_PLAYER, "GAL_NEXTMAP2", nextMapName );
        }
        else if( g_isThePenultGameRound )
        {
            color_chat( 0, "%L %L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED2", LANG_PLAYER, "GAL_NEXTMAP2", nextMapName );
        }
    }
    else if( g_isTheLastGameRound
             || g_isThePenultGameRound )
    {
        color_chat( 0, "%L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED2" );
    }
}

public show_last_round_HUD()
{
    LOG( 256, "I AM ENTERING ON show_last_round_HUD(0)" )

    if( ++g_showLastRoundHudCounter % LAST_ROUND_HUD_SHOW_INTERVAL > 6
        || g_isTheRoundEnded )
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
    LOG( 128, "I AM ENTERING ON is_there_game_commencing(0)" )
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
            LOG( 1, "    ( is_there_game_commencing ) Returning true." )
            return true;
        }
    }

    LOG( 1, "    ( is_there_game_commencing ) Returning false." )
    return false;
}

/**
 * Enable a new voting, as a new game is starting
 */
stock enableNewVoting()
{
    LOG( 128, "I AM ENTERING ON enableNewVoting(0)" )

    g_voteStatus &= ~IS_VOTE_OVER;
    g_voteStatus &= ~IS_EARLY_VOTE;
    g_voteStatus &= ~IS_VOTE_EXPIRED;
}

/**
 * Reset rounds scores every game restart event. This relies on that the 'game_commencing_event()'
 * is not triggered by the 'round_restart_event()'. This use 'is_there_game_commencing()' to determine
 * if it must restore the time limit by calling 'game_commencing_event()', when there is none game
 * on going, to avoid the infinity time limit due the allow last round finish feature.
 */
public round_restart_event()
{
    LOG( 128, "I AM ENTERING ON round_restart_event(0)" )
    enableNewVoting();

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
    LOG( 128, "I AM ENTERING ON game_commencing_event(0)" )

#if ARE_WE_RUNNING_UNIT_TESTS
    if( get_gametime() < 100
        && ( get_playersnum( 1 )
             || g_test_areTheUnitTestsRunning ) )
    {
        LOG( 1, "^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n" )
        LOG( 1, "There are players on the server!" )
        LOG( 1, "^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n^n" )
    }
    else
    {
        g_isTimeToResetGame   = true;
        g_isTimeToResetRounds = true;
    }
#else
    g_isTimeToResetGame   = true;
    g_isTimeToResetRounds = true;
#endif

    enableNewVoting();
    cancelVoting( true );
}

/**
 * Reset the round ending, if it is in progress.
 */
stock resetRoundEnding()
{
    LOG( 128, "I AM ENTERING ON resetRoundEnding(0)" )

    // Each one of these entries must to be saved on saveRoundEnding(1) and restored at restoreRoundEnding(1).
    g_isTheLastGameRound       = false;
    g_isTimeToRestart          = false;
    g_isThePenultGameRound     = false;
    g_isTheRoundEndWhileVoting = false;
    g_isToChangeMapOnVotingEnd = false;

    remove_task( TASKID_SHOW_LAST_ROUND_HUD );
    client_cmd( 0, "-showscores" );
}

stock saveRoundEnding( bool:roundEndStatus[ SaveRoundEnding ] )
{
    LOG( 128, "I AM ENTERING ON saveRoundEnding(1)" )
    LOG( 32, "( saveRoundEnding ) roundEndStatus[0]: %d", roundEndStatus[ SaveRoundEnding_LastRound   ] )
    LOG( 32, "( saveRoundEnding ) roundEndStatus[1]: %d", roundEndStatus[ SaveRoundEnding_RestartTime ] )
    LOG( 32, "( saveRoundEnding ) roundEndStatus[2]: %d", roundEndStatus[ SaveRoundEnding_PenultRound ] )

    roundEndStatus[ SaveRoundEnding_LastRound   ] = g_isTheLastGameRound;
    roundEndStatus[ SaveRoundEnding_RestartTime ] = g_isTimeToRestart;
    roundEndStatus[ SaveRoundEnding_PenultRound ] = g_isThePenultGameRound;
    roundEndStatus[ SaveRoundEnding_VotingEnd   ] = g_isToChangeMapOnVotingEnd;
    roundEndStatus[ SaveRoundEnding_WhileVoting ] = g_isTheRoundEndWhileVoting;
}

stock restoreRoundEnding( bool:roundEndStatus[ SaveRoundEnding ] )
{
    LOG( 128, "I AM ENTERING ON restoreRoundEnding(1)" )
    LOG( 32, "( restoreRoundEnding ) roundEndStatus[0]: %d", roundEndStatus[ SaveRoundEnding_LastRound   ] )
    LOG( 32, "( restoreRoundEnding ) roundEndStatus[1]: %d", roundEndStatus[ SaveRoundEnding_RestartTime ] )
    LOG( 32, "( restoreRoundEnding ) roundEndStatus[2]: %d", roundEndStatus[ SaveRoundEnding_PenultRound ] )

    g_isTheLastGameRound       = bool:roundEndStatus[ SaveRoundEnding_LastRound   ];
    g_isTimeToRestart          = bool:roundEndStatus[ SaveRoundEnding_RestartTime ];
    g_isThePenultGameRound     = bool:roundEndStatus[ SaveRoundEnding_PenultRound ];
    g_isToChangeMapOnVotingEnd = bool:roundEndStatus[ SaveRoundEnding_VotingEnd   ];
    g_isTheRoundEndWhileVoting = bool:roundEndStatus[ SaveRoundEnding_WhileVoting ];
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
    LOG( 128 + 2, "I AM ENTERING ON resetRoundsScores(0)" )
    LOG( 2, "( resetRoundsScores ) TRYING to change the cvar %15s from '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOG( 2, "( resetRoundsScores ) TRYING to change the cvar %15s from '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOG( 2, "( resetRoundsScores ) TRYING to change the cvar %15s from '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOG( 2, "( resetRoundsScores ) TRYING to change the cvar %15s from '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )

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

    LOG( 2, "( resetRoundsScores ) CHECKOUT the cvar %-25s is '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOG( 2, "( resetRoundsScores ) CHECKOUT the cvar %-25s is '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOG( 2, "( resetRoundsScores ) CHECKOUT the cvar %-25s is '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOG( 2, "( resetRoundsScores ) CHECKOUT the cvar %-25s is '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )
    LOG( 1, "    I AM EXITING ON resetRoundsScores(0)" )
}

stock map_populateList( Array:mapArray=Invalid_Array, mapFilePath[],
                        Trie:fillerMapTrie=Invalid_Trie, bool:isToClearTheTrie=true,
                        bool:isToLoadDuplicatedMaps=true )
{
    LOG( 128, "I AM ENTERING ON map_populateList(5) mapFilePath: %s", mapFilePath )

    // load the array with maps
    new mapCount;

    // If there is a map file to load
    if( mapFilePath[ 0 ] )
    {
        if( file_exists( mapFilePath )
            || mapFilePath[ 0 ] == MAP_CYCLE_LOAD_FLAG
            || mapFilePath[ 0 ] == MAP_FOLDER_LOAD_FLAG )
        {
            new Trie:duplicatedMaps;
            new bool:isMapFolderLoad;

            if( !isToLoadDuplicatedMaps ) duplicatedMaps = TrieCreate();
            isMapFolderLoad = ( mapFilePath[ 0 ] == MAP_FOLDER_LOAD_FLAG );

            // clear the map array in case we're reusing it
            TRY_TO_APPLY( ArrayClear, mapArray )

            // Not always we want to discard the loaded maps
            if( isToClearTheTrie ) TRY_TO_APPLY( TrieClear, fillerMapTrie )

            if( !isMapFolderLoad
                && mapFilePath[ 0 ] != MAP_CYCLE_LOAD_FLAG )
            {
                LOG( 4, "" )
                LOG( 4, "    map_populateList(...) Loading the PASSED FILE! mapFilePath: %s", mapFilePath )
                mapCount = loadMapFileList( mapArray, mapFilePath, fillerMapTrie, duplicatedMaps );
            }
            else if( isMapFolderLoad )
            {
                LOG( 4, "" )
                LOG( 4, "    map_populateList(...) Loading the MAP FOLDER! mapFilePath: %s", mapFilePath )
                mapCount = loadMapsFolderDirectory( mapArray, fillerMapTrie );
            }
            else
            {
                get_cvar_string( "mapcyclefile", mapFilePath, MAX_FILE_PATH_LENGHT - 1 );

                LOG( 4, "" )
                LOG( 4, "    map_populateList(...) Loading the MAPCYCLE! mapFilePath: %s", mapFilePath )
                mapCount = loadMapFileList( mapArray, mapFilePath, fillerMapTrie, duplicatedMaps );
            }

            TRY_TO_APPLY( TrieDestroy, duplicatedMaps )
        }
        else
        {
            doAmxxLog( "ERROR, map_populateList: Could not open the file ^"%s^"", mapFilePath );
        }
    }

    LOG( 1, "    I AM EXITING map_populateList(4) mapCount: %d", mapCount )
    return mapCount;
}

stock checkIfThereEnoughMapPopulated( mapCount, mapFileDescriptor, mapFilePath[] )
{
    LOG( 128, "I AM ENTERING ON checkIfThereEnoughMapPopulated(2) mapCount: %d", mapCount )

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

        LOG( 1, "( checkIfThereEnoughMapPopulated ) Not valid/enough(%d) maps found in: %s", mapCount, mapFilePath )
        LOG( 1, "( checkIfThereEnoughMapPopulated ) ERROR %d, readLines: %s^n", AMX_ERR_NOTFOUND, readLines )

        log_error( AMX_ERR_NOTFOUND, "Not valid/enough(%d) maps found in: %s", mapCount, mapFilePath );
        log_error( AMX_ERR_NOTFOUND, "readLines: %s^n", readLines );
    }
}

stock loadMapFileList( Array:mapArray, mapFilePath[], Trie:fillerMapTrie, Trie:duplicatedMaps )
{
    LOG( 128, "I AM ENTERING ON loadMapFileList(4) mapFilePath: %s", mapFilePath )

    new mapCount;
    new mapFileDescriptor = fopen( mapFilePath, "rt" );

    if( mapFileDescriptor )
    {
        // Removing the if's from the loop to improve speed
        if( mapArray
            && fillerMapTrie )
        {
            mapCount = loadMapFileListComplete( mapFileDescriptor, mapArray, fillerMapTrie, duplicatedMaps );
        }
        else if( mapArray )
        {
            mapCount = loadMapFileListArray( mapFileDescriptor, mapArray, duplicatedMaps );
        }
        else if( fillerMapTrie )
        {
            mapCount = loadMapFileListTrie( mapFileDescriptor, fillerMapTrie, duplicatedMaps );
        }
        else
        {
            LOG( 1, "( loadMapFileList ) An invalid map descriptors %d/%d!^n", mapArray, fillerMapTrie )
            log_error( AMX_ERR_PARAMS, "loadMapFileList: An invalid map descriptor %d/%d!^n", mapArray, fillerMapTrie );
        }

        checkIfThereEnoughMapPopulated( mapCount, mapFileDescriptor, mapFilePath );

        fclose( mapFileDescriptor );
        LOG( 4, "" )
    }
    else
    {
        LOG( 1, "( loadMapFileList ) ERROR %d, %L", AMX_ERR_NOTFOUND, LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilePath )
        log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilePath );
    }

    return mapCount;
}

stock loadMapFileListComplete( mapFileDescriptor, Array:mapArray, Trie:fillerMapTrie, Trie:duplicatedMaps )
{
    LOG( 128, "I AM ENTERING ON loadMapFileListComplete(2) mapFileDescriptor: %d", mapFileDescriptor )

    new mapCount;
    new loadedMapLine[ MAX_MAPNAME_LENGHT ];
    new loadedMapName[ MAX_MAPNAME_LENGHT ];

    if( duplicatedMaps )
    {
        while( !feof( mapFileDescriptor ) )
        {
            fgets( mapFileDescriptor, loadedMapLine, charsmax( loadedMapLine ) );
            trim( loadedMapLine );

            if( IS_IT_A_VALID_MAP_LINE( loadedMapLine ) )
            {
                GET_MAP_NAME_LEFT( loadedMapLine, loadedMapName )

                if( IS_MAP_VALID( loadedMapName ) )
                {
                    strtolower( loadedMapName );

                    if( !TrieKeyExists( duplicatedMaps, loadedMapName ) )
                    {
                        TrieSetCell( duplicatedMaps, loadedMapName, mapCount );
                        TrieSetCell( fillerMapTrie, loadedMapName, mapCount );

                        ArrayPushString( mapArray, loadedMapLine );
                        LOG( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapLine ) )

                        ++mapCount;
                    }
                }
            }
        }
    }
    else
    {
        while( !feof( mapFileDescriptor ) )
        {
            fgets( mapFileDescriptor, loadedMapLine, charsmax( loadedMapLine ) );
            trim( loadedMapLine );

            if( IS_IT_A_VALID_MAP_LINE( loadedMapLine ) )
            {
                GET_MAP_NAME_LEFT( loadedMapLine, loadedMapName )

                if( IS_MAP_VALID( loadedMapName ) )
                {
                    strtolower( loadedMapName );
                    TrieSetCell( fillerMapTrie, loadedMapName, mapCount );

                    ArrayPushString( mapArray, loadedMapLine );
                    LOG( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapLine ) )

                    ++mapCount;
                }
            }
        }
    }

    return mapCount;
}

stock loadMapFileListArray( mapFileDescriptor, Array:mapArray, Trie:duplicatedMaps )
{
    LOG( 128, "I AM ENTERING ON loadMapFileListArray(2) mapFileDescriptor: %d", mapFileDescriptor )

    new mapCount;
    new loadedMapName[ MAX_MAPNAME_LENGHT ];
    new loadedMapLine[ MAX_MAPNAME_LENGHT ];

    if( duplicatedMaps )
    {
        while( !feof( mapFileDescriptor ) )
        {
            fgets( mapFileDescriptor, loadedMapLine, charsmax( loadedMapLine ) );
            trim( loadedMapLine );

            if( IS_IT_A_VALID_MAP_LINE( loadedMapLine ) )
            {
                GET_MAP_NAME_LEFT( loadedMapLine, loadedMapName )

                if( IS_MAP_VALID( loadedMapName ) )
                {
                    strtolower( loadedMapName );

                    if( !TrieKeyExists( duplicatedMaps, loadedMapName ) )
                    {
                        ArrayPushString( mapArray, loadedMapLine );
                        TrieSetCell( duplicatedMaps, loadedMapName, mapCount );

                        LOG( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapLine ) )
                        ++mapCount;
                    }
                }
            }
        }
    }
    else
    {
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
                    LOG( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapLine ) )

                    ++mapCount;
                }
            }
        }
    }

    return mapCount;
}

stock loadMapFileListTrie( mapFileDescriptor, Trie:fillerMapTrie, Trie:duplicatedMaps )
{
    LOG( 128, "I AM ENTERING ON loadMapFileListTrie(2) mapFileDescriptor: %d", mapFileDescriptor )

    new mapCount;
    new loadedMapName[ MAX_MAPNAME_LENGHT ];
    new loadedMapLine[ MAX_MAPNAME_LENGHT ];

    if( duplicatedMaps )
    {
        while( !feof( mapFileDescriptor ) )
        {
            fgets( mapFileDescriptor, loadedMapLine, charsmax( loadedMapLine ) );
            trim( loadedMapLine );

            if( IS_IT_A_VALID_MAP_LINE( loadedMapLine ) )
            {
                GET_MAP_NAME_LEFT( loadedMapLine, loadedMapName )

                if( IS_MAP_VALID( loadedMapName ) )
                {
                    strtolower( loadedMapName );

                    if( !TrieKeyExists( duplicatedMaps, loadedMapName ) )
                    {
                        TrieSetCell( duplicatedMaps, loadedMapName, mapCount );
                        TrieSetCell( fillerMapTrie, loadedMapName, mapCount );

                        LOG( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapLine ) )
                        ++mapCount;
                    }
                }
            }
        }
    }
    else
    {
        while( !feof( mapFileDescriptor ) )
        {
            fgets( mapFileDescriptor, loadedMapLine, charsmax( loadedMapLine ) );
            trim( loadedMapLine );

            if( IS_IT_A_VALID_MAP_LINE( loadedMapLine ) )
            {
                GET_MAP_NAME_LEFT( loadedMapLine, loadedMapName )

                if( IS_MAP_VALID( loadedMapName ) )
                {
                    strtolower( loadedMapName );
                    TrieSetCell( fillerMapTrie, loadedMapName, mapCount );

                    LOG( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapLine ) )
                    ++mapCount;
                }
            }
        }
    }

    return mapCount;
}

stock loadMapsFolderDirectory( Array:mapArray, Trie:fillerMapTrie )
{
    LOG( 128, "I AM ENTERING ON loadMapsFolderDirectory(2) Array:mapArray: %d", mapArray )

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
        else if( fillerMapTrie )
        {
            mapCount = loadMapsFolderDirectoryTrie( directoryDescriptor, fillerMapTrie );
        }
        else
        {
            LOG( 1, "( loadMapsFolderDirectory ) An invalid map descriptors %d/%d!^n", mapArray, fillerMapTrie )
            log_error( AMX_ERR_PARAMS, "loadMapsFolderDirectory: An invalid map descriptor %d/%d!^n", mapArray, fillerMapTrie );
        }

        close_dir( directoryDescriptor );
    }
    else
    {
        // directory not found, wtf?
        LOG( 1, "( loadMapsFolderDirectory ) ERROR %d, %L", AMX_ERR_NOTFOUND, LANG_SERVER, "GAL_MAPS_FOLDERMISSING" )
        log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_MAPS_FOLDERMISSING" );
    }

    return mapCount;
}

stock loadMapsFolderDirectoryComplete( directoryDescriptor, Array:mapArray, Trie:fillerMapTrie )
{
    LOG( 128, "I AM ENTERING ON loadMapsFolderDirectoryComplete(3) directoryDescriptor: %d", directoryDescriptor )

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
                strtolower( loadedMapName );

                TrieSetCell( fillerMapTrie, loadedMapName, mapCount );
                LOG( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapName ) )

                ++mapCount;
            }
        }
    }

    return mapCount;
}

stock loadMapsFolderDirectoryArray( directoryDescriptor, Array:mapArray )
{
    LOG( 128, "I AM ENTERING ON loadMapsFolderDirectoryArray(2) directoryDescriptor: %d", directoryDescriptor )

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
                LOG( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapName ) )

                ++mapCount;
            }
        }
    }

    return mapCount;
}

stock loadMapsFolderDirectoryTrie( directoryDescriptor, Trie:fillerMapTrie )
{
    LOG( 128, "I AM ENTERING ON loadMapsFolderDirectoryTrie(2) directoryDescriptor: %d", directoryDescriptor )

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
                strtolower( loadedMapName );
                TrieSetCell( fillerMapTrie, loadedMapName, mapCount );

                LOG( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapName ) )
                ++mapCount;
            }
        }
    }

    return mapCount;
}

public loadNominationList( nomMapFilePath[] )
{
    LOG( 128, "I AM ENTERING ON loadNominationList(1)" )

    TRY_TO_CLEAN( ArrayClear, g_nominatedMapsArray       , ArrayCreate()                     )
    TRY_TO_CLEAN( ArrayClear, g_nominationLoadedMapsArray, ArrayCreate( MAX_MAPNAME_LENGHT ) )

    TRY_TO_CLEAN( TrieClear, g_reverseSearchNominationsTrie, TrieCreate() )
    TRY_TO_CLEAN( TrieClear, g_forwardSearchNominationsTrie, TrieCreate() )
    TRY_TO_CLEAN( TrieClear, g_nominationLoadedMapsTrie    , TrieCreate() )

    get_pcvar_string( cvar_nomMapFilePath, nomMapFilePath, MAX_FILE_PATH_LENGHT - 1 );
    LOG( 4, "( loadNominationList ) cvar_nomMapFilePath: %s", nomMapFilePath )

    map_populateList( g_nominationLoadedMapsArray, nomMapFilePath, g_nominationLoadedMapsTrie );
    LOG( 1, "    ( loadNominationList ) loadedCount:                 %d", ArraySize( g_nominationLoadedMapsArray ) )
    LOG( 1, "    ( loadNominationList ) g_nominationLoadedMapsArray: %d", g_nominationLoadedMapsArray )
}

/**
 * Currently the empty cycle behavior is based on the function map_getNext(4). Therefore this is a
 * problem because it will create infinity empty cycle loops between duplicated maps on the empty
 * map cycle.
 *
 * So here I have to options:
 * a) change all the empty cycle algorithm
 * b) do not load duplicated maps.
 *
 * As anyone until now complained about this behavior, I choose the former as easier to implement.
 */
stock map_loadEmptyCycleList( emptyCycleFilePath[] )
{
    LOG( 128, "I AM ENTERING ON map_loadEmptyCycleList(1)" )

    TRY_TO_CLEAN( ArrayClear, g_emptyCycleMapsArray, ArrayCreate( MAX_MAPNAME_LENGHT ) )
    get_pcvar_string( cvar_emptyMapFilePath, emptyCycleFilePath, MAX_FILE_PATH_LENGHT - 1 );

    map_populateList( g_emptyCycleMapsArray, emptyCycleFilePath, .isToLoadDuplicatedMaps=false );
    LOG( 4, "( map_loadEmptyCycleList ) loadedCount: %d", ArraySize( g_emptyCycleMapsArray ) )
}

public map_loadPrefixList( prefixesFilePath[] )
{
    LOG( 128, "I AM ENTERING ON map_loadPrefixList(1) g_mapPrefixCount: %d", g_mapPrefixCount )
    new prefixesFile;

    // To clear old values in case of reloading.
    g_mapPrefixCount = 0;

    formatex( prefixesFilePath, MAX_FILE_PATH_LENGHT - 1, "%s/prefixes.ini", g_configsDirPath );
    prefixesFile = fopen( prefixesFilePath, "rt" );

    if( prefixesFile )
    {
        new loadedMapPrefix[ MAX_PREFIX_SIZE ];

        while( !feof( prefixesFile ) )
        {
            fgets( prefixesFile, loadedMapPrefix, charsmax( loadedMapPrefix ) );
            trim( loadedMapPrefix );

            if( loadedMapPrefix[ 0 ]
                && loadedMapPrefix[ 0 ] != ';'
                && !equal( loadedMapPrefix, "//", 2 ) )
            {
                if( g_mapPrefixCount < MAX_PREFIX_COUNT )
                {
                    copy( g_mapPrefixes[ g_mapPrefixCount++ ], charsmax( loadedMapPrefix ), loadedMapPrefix );
                }
                else
                {
                    LOG( 1, "AMX_ERR_BOUNDS, %L", LANG_SERVER, "GAL_PREFIXES_TOOMANY", MAX_PREFIX_COUNT, prefixesFilePath )
                    log_error( AMX_ERR_BOUNDS, "%L", LANG_SERVER, "GAL_PREFIXES_TOOMANY", MAX_PREFIX_COUNT, prefixesFilePath );

                    break;
                }
            }
        }

        fclose( prefixesFile );
    }
    else
    {
        LOG( 1, "AMX_ERR_NOTFOUND, %L", LANG_SERVER, "GAL_PREFIXES_NOTFOUND", prefixesFilePath )
        log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_PREFIXES_NOTFOUND", prefixesFilePath );
    }

    LOG( 1, "    ( map_loadPrefixList ) g_mapPrefixCount: %d", g_mapPrefixCount )
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
    LOG( 256, "I AM ENTERING ON isToLoadNextWhiteListGroupOpen(4) currentHour: %d", currentHour )
    LOG( 256, "( isToLoadNextWhiteListGroupOpen ) startHour: %d, endHour: %d", startHour, endHour )
    new bool:isToLoadTheseMaps;

    // Here handle all the cases when the start hour is equals to the end hour.
    if( startHour == endHour )
    {
        LOG( 8, "( isToLoadNextWhiteListGroupOpen ) startHour == endHour: %d", startHour )

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

    LOG( 0, "", debugIsToLoadNextWhiteListGroup( currentHour, startHour, endHour, isToLoadTheseMaps ) )
    return isToLoadTheseMaps;
}

stock bool:isToLoadNextWhiteListGroupClose( currentHour, startHour, endHour, bool:isBlackList = false )
{
    LOG( 256, "I AM ENTERING ON isToLoadNextWhiteListGroupClose(4) currentHour: %d", currentHour )
    LOG( 256, "( isToLoadNextWhiteListGroupClose ) startHour: %d, endHour: %d", startHour, endHour )

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

    LOG( 256, "( isToLoadNextWhiteListGroupClose ) startHour: %d, endHour: %d", startHour, endHour )

    // Here handle all the cases when the start hour is equals to the end hour.
    if( startHour == endHour )
    {
        LOG( 8, "( isToLoadNextWhiteListGroupClose ) startHour == endHour: %d", startHour )

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

    LOG( 0, "", debugIsToLoadNextWhiteListGroup( currentHour, startHour, endHour, isToLoadTheseMaps ) )
    return isToLoadTheseMaps;
}

stock bool:isToLoadNextWhiteListEndProcess( currentHour, startHour, endHour, bool:isBlackList )
{
    LOG( 256, "I AM ENTERING ON isToLoadNextWhiteListEndProcess(4)" )

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
            LOG( 256, "( isToLoadNextWhiteListEndProcess ) 1. Returning: %d", !isBlackList )
            return !isBlackList;
        }
        //               6           5
        else // if( currentHour > startHour )
        {
            LOG( 256, "( isToLoadNextWhiteListEndProcess ) 2. Returning: %d", isBlackList )
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
            LOG( 256, "( isToLoadNextWhiteListEndProcess ) 3. Returning: %d", !isBlackList )
            return !isBlackList;
        }
        //              4            3
        else // if( currentHour > startHour )
        {
            LOG( 256, "( isToLoadNextWhiteListEndProcess ) 4. Returning: %d", isBlackList )
            return isBlackList;
        }
    }

    // This is in fact unreachable code and the AMXX 183 know that, but he AMXX 182 don't.
#if AMXX_VERSION_NUM < 183
    LOG( 256, "    ( isToLoadNextWhiteListEndProcess ) Returning false." )
    return false;
#endif
}

stock debugIsToLoadNextWhiteListGroup( currentHour, startHour, endHour, isToLoadTheseMaps )
{
    LOG( 8, "( debugIsToLoadNextWhiteListGroup ) %2d >  %2d     : %2d", startHour, endHour, startHour > endHour )
    LOG( 8, "( debugIsToLoadNextWhiteListGroup ) %2d >= %2d > %2d: %2d", \
            startHour, currentHour, endHour, \
            startHour >= currentHour && currentHour > endHour )

    LOG( 8, "( debugIsToLoadNextWhiteListGroup ) %2d <  %2d     : %2d", startHour, endHour, startHour < endHour )
    LOG( 8, "( debugIsToLoadNextWhiteListGroup ) %2d <= %2d < %2d: %2d, isToLoadTheseMaps: %d", \
            startHour, currentHour, endHour, \
            startHour <= currentHour && currentHour < endHour, isToLoadTheseMaps )

    return 0;
}

/**
 * Standardize the hours from 0 until 23.
 */
stock standardizeTheHoursForWhitelist( &currentHour, &startHour, &endHour )
{
    LOG( 256, "I AM ENTERING ON standardizeTheHoursForWhitelist(3) currentHour: %d, startHour: %d, endHour: %d", \
            currentHour, startHour, endHour )

    if( startHour > 23
        || startHour < 0 )
    {
        LOG( 8, "( standardizeTheHoursForWhitelist ) startHour: %d, will became 0.", startHour )
        startHour = 0;
    }

    if( endHour > 23
        || endHour < 0 )
    {
        LOG( 8, "( standardizeTheHoursForWhitelist ) endHour: %d, will became 0.", endHour )
        endHour = 0;
    }

    if( currentHour > 23
        || currentHour < 0 )
    {
        LOG( 8, "( standardizeTheHoursForWhitelist ) currentHour: %d, will became 0.", currentHour )
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
    LOG( 256, "I AM ENTERING ON convertWhitelistToBlacklist(2)" )
    new backup;

    backup    = ( endHour   + 1 > 23 ? 0  : endHour   + 1 );
    endHour   = ( startHour - 1 < 0  ? 23 : startHour - 1 );
    startHour = backup;

    LOG( 256, "( convertWhitelistToBlacklist ) startHour: %d, endHour: %d", startHour, endHour )

    if( startHour == 0
        && endHour == 23 )
    {
        startHour = 0;
        endHour   = 0;

        LOG( 256, "    ( convertWhitelistToBlacklist ) Returning true." )
        return true;
    }

    LOG( 256, "    ( convertWhitelistToBlacklist ) Returning false." )
    return false;
}

/**
 * This must to be called always is needed to update the Whitelist loaded maps, or when it is the
 * first time the Whitelist feature is loaded.
 *
 * @note It must to be protected by an 'IS_WHITELIST_ENABLED()' evaluation.
 */
stock loadTheWhiteListFeature()
{
    LOG( 128, "I AM ENTERING ON loadTheWhiteListFeature(0)" )

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
    LOG( 128, "I AM ENTERING ON loadWhiteListFile(5) currentHour: %d, listTrie: %d", currentHour, listTrie )

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
                LOG( 8, "( loadWhiteListFile ) Trying to add: %s", currentLine )
                GET_MAP_NAME_LEFT( currentLine, mapName )

                if( IS_MAP_VALID( mapName ) )
                {
                    LOG( 8, "( loadWhiteListFile ) %d. OK! ", listTrie )
                    TrieSetCell( listTrie, mapName, lineIndex );

                    if( listArray )
                    {
                        ArrayPushString( listArray, currentLine );
                    }
                }
            }
        }
    }
    else
    {
        LOG( 1, "( loadWhiteListFile ) An invalid map descriptors %d/%d!^n", whitelistFileArray, listTrie )
        log_error( AMX_ERR_PARAMS, "loadWhiteListFile: An invalid map descriptor %d/%d!^n", whitelistFileArray, listTrie );
    }

    LOG( 1, "    I AM EXITING loadWhiteListFile(5) listArray: %d, whitelistFileArray: %d", listArray, whitelistFileArray )
}

stock whiteListHourlySet( trigger, currentLine[], startHourString[], endHourString[], &isBlackList, &currentHour, &startHour, &endHour )
{
    LOG( 256, "I AM ENTERING ON whiteListHourlySet(4) trigger: %c", trigger )

    if( currentLine[ 0 ] == trigger
        && isdigit( currentLine[ 1 ] ) )
    {
        // remove line delimiters [ and ]
        replace_all( currentLine, MAX_MAPNAME_LENGHT - 1, "[", "" );
        replace_all( currentLine, MAX_MAPNAME_LENGHT - 1, "{", "" );
        replace_all( currentLine, MAX_MAPNAME_LENGHT - 1, "}", "" );
        replace_all( currentLine, MAX_MAPNAME_LENGHT - 1, "]", "" );

        LOG( 8, "( whiteListHourlySet ) " )
        LOG( 8, "( whiteListHourlySet ) If we are %s these hours, we must load these maps:", ( isBlackList? "between" : "outside" ) )
        LOG( 8, "( whiteListHourlySet ) currentLine: %s (currentHour: %d)", currentLine, currentHour )

        // broke the current line
        str_token( currentLine ,
                startHourString, MAX_MAPNAME_LENGHT / 2,
                endHourString  , MAX_MAPNAME_LENGHT / 2, '-', 0 );

        startHour = str_to_num( startHourString );
        endHour   = str_to_num( endHourString );

        standardizeTheHoursForWhitelist( currentHour, startHour, endHour );
        LOG( 256, "    ( whiteListHourlySet ) Returning true for: %s", currentLine )
        return true;
    }

    LOG( 256, "    ( whiteListHourlySet ) Returning false for: %s", currentLine )
    return false;
}

stock setupLoadWhiteListParams( bool:isWhiteListBlockOut, &Trie:listTrie, &Array:listArray )
{
    LOG( 128, "I AM ENTERING ON setupLoadWhiteListParams(3) isWhiteListBlockOut: %d", isWhiteListBlockOut )
    LOG( 8, "( setupLoadWhiteListParams ) listTrie: %d, listArray: %d", listTrie, listArray )

    if( listTrie )
    {
        TRY_TO_APPLY( TrieClear, listTrie )
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
            TRY_TO_APPLY( ArrayClear, listArray )
        }
        else
        {
            listArray = ArrayCreate( MAX_MAPNAME_LENGHT );
        }
    }
}

stock FillersFilePathType:loadMapGroupsFeature()
{
    LOG( 128, "I AM ENTERING ON loadMapGroupsFeature(0)" )
    new realPlayersNumber = get_real_players_number();

    if( realPlayersNumber > 0 )
    {
        new voteMininumPlayers = get_pcvar_num( cvar_voteMinPlayers );
        new voteMiddlePlayers  = get_pcvar_num( cvar_voteMidPlayers );

        LOG( 4, "( loadMapGroupsFeature ) realPlayersNumber:       %d", realPlayersNumber )
        LOG( 4, "( loadMapGroupsFeature ) voteMininumPlayers:      %s", voteMininumPlayers )
        LOG( 4, "( loadMapGroupsFeature ) voteMiddlePlayers:       %s", voteMiddlePlayers )

        if( realPlayersNumber < voteMininumPlayers
            && voteMininumPlayers > VOTE_MININUM_PLAYERS_REQUIRED )
        {
            return fillersFilePaths_MininumPlayers;
        }
        else if( voteMiddlePlayers > voteMininumPlayers
                 && realPlayersNumber < voteMiddlePlayers
                 && voteMiddlePlayers > VOTE_MIDDLE_PLAYERS_REQUIRED )
        {
            return fillersFilePaths_MiddlePlayers;
        }
    }

    return fillersFilePaths_NormalPlayers;
}

stock processLoadedMapsFile( FillersFilePathType:fillersFilePathEnum, blockedMapsBuffer[], &announcementShowedTimes )
{
    LOG( 128, "I AM ENTERING ON processLoadedMapsFile(3)" )
    LOG( 4, "( processLoadedMapsFile ) fillersFilePathEnum:     %d", fillersFilePathEnum )
    LOG( 4, "( processLoadedMapsFile ) announcementShowedTimes: %d", announcementShowedTimes )
    LOG( 4, "( processLoadedMapsFile ) blockedMapsBuffer:       %s", blockedMapsBuffer )

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
    new bool:isWhiteListOutBlock  = ( isWhitelistEnabled
                                      && get_pcvar_num( cvar_isWhiteListBlockOut ) != 0 );
    new bool:useMapIsTooRecent    = ( g_recentListMapsArray
                                      && ArraySize( g_recentListMapsArray )
                                      && get_pcvar_num( cvar_recentMapsBannedNumber ) != 0 );

    /**
     * This variable is to avoid double blocking which lead to the algorithm corruption and errors.
     */
    new Trie:blockedFillersMapTrie;

    if( useWhitelistOutBlock )
    {
        blockedFillersMapTrie = TrieCreate();
    }

    groupCount = ArraySize( fillerMapGroupsArrays );
    LOG( 4, "( processLoadedMapsFile ) groupCount: %d, fillerMapGroupsArrays: %d", groupCount, fillerMapGroupsArrays )

    // The Whitelist Out Block feature disables The Map Groups Feature.
    if( isWhiteListOutBlock )
    {
        LOG( 4, "( processLoadedMapsFile ) Disabling the MapsGroups Feature due isWhiteListOutBlock" )

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
            // The Whitelist out block feature, disables The Map Groups Feature.
            if( isWhiteListOutBlock )
            {
                LOG( 0, "", print_is_white_list_out_block() )

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

        LOG( 8, "" )
        LOG( 8, "[%i] groupCount:%i, filersMapCount: %i,  g_totalVoteOptions: %i, maxVotingChoices: %i", \
                groupIndex, groupCount, filersMapCount, g_totalVoteOptions, maxVotingChoices )

        if( filersMapCount
            && g_totalVoteOptions < maxVotingChoices )
        {
            maxMapsPerGroupToUse = ArrayGetCell( maxMapsPerGroupToUseArray, groupIndex );
            allowedFilersCount   = min( min(
                                             maxMapsPerGroupToUse, maxVotingChoices - g_totalVoteOptions
                                           ), filersMapCount );

            LOG( 8, "[%i] allowedFilersCount: %i   maxMapsPerGroupToUse[%i]: %i", groupIndex, \
                    allowedFilersCount, groupIndex, maxMapsPerGroupToUse )
            LOG( 8, "" )
            LOG( 8, "" )

            for( choiceIndex = 0; choiceIndex < allowedFilersCount; ++choiceIndex )
            {
                unsuccessfulCount      = 0;
                currentBlockerStrategy = -1;

                keepSearching:

                mapIndex = random_num( 0, filersMapCount - 1 );
                GET_MAP_NAME( fillerMapsArray, mapIndex, mapName )

                LOG( 8, "( in  ) [%i] choiceIndex: %i, mapIndex: %i, mapName: %s, unsuccessfulCount: %i, g_totalVoteOptions: %i", \
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
                    LOG( 8, "" )
                    LOG( 0, "", debug_vote_map_selection( choiceIndex, mapName, useWhitelistOutBlock, \
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
                                    LOG( 8, "" )
                                    LOG( 8, "" )
                                    LOG( 8, "WARNING! This BlockerStrategy case is not used by the isWhiteListOutBlock." )
                                    LOG( 8, "" )
                                    LOG( 8, "" )

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
                                LOG( 8, "" )
                                LOG( 8, "" )
                                LOG( 8, "WARNING! unsuccessfulCount: %i, filersMapCount: %i", unsuccessfulCount, filersMapCount )
                                LOG( 8, "" )
                                LOG( 8, "" )

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

                    LOG( 0, "", debug_vote_map_selection( choiceIndex, mapName, useWhitelistOutBlock, \
                            isWhiteListOutBlock, useEqualiCurrentMap, unsuccessfulCount, currentBlockerStrategy, \
                            useIsPrefixInMenu, useMapIsTooRecent, blockedFillersMapTrie ) )
                }

                if( isWhitelistEnabled
                    && !isWhiteListOutBlock
                    && TrieKeyExists( g_blacklistTrie, mapName ) )
                {
                    LOG( 8, "    Trying to block: %s, by the whitelist map setting...", mapName )

                    if( !TrieKeyExists( blockedFillersMapTrie, mapName ) )
                    {
                        LOG( 8, "    BLOCKED!" )

                        TrieSetCell( blockedFillersMapTrie, mapName, 0 );
                        announceVoteBlockedMap( mapName, blockedMapsBuffer, "GAL_FILLER_BLOCKED", announcementShowedTimes );
                    }

                    goto keepSearching;
                }

                GET_MAP_INFO( fillerMapsArray, mapIndex, mapInfo )
                addMapToTheVotingMenu( mapName, mapInfo );

                LOG( 8, "" )
                LOG( 8, "( out ) [%i] choiceIndex: %i, mapIndex: %i, mapName: %s, unsuccessfulCount: %i, g_totalVoteOptions: %i", \
                        groupIndex, choiceIndex, mapIndex, mapName, unsuccessfulCount, g_totalVoteOptions )
                LOG( 8, "" )
                LOG( 8, "" )
            }

            if( g_dummy_value )
            {
                exitSearch:

                LOG( 8, "" )
                LOG( 8, "" )
                LOG( 8, "WARNING! There aren't enough maps in this filler file to continue adding anymore." )
                LOG( 8, "" )
                LOG( 8, "" )
            }
        }
    }

    TRY_TO_APPLY( TrieDestroy, blockedFillersMapTrie )
    TRY_TO_APPLY( ArrayDestroy, randomGenaratorHolder )
}

stock print_is_white_list_out_block()
{
    LOG( 128, "I AM ENTERING ON print_is_white_list_out_block(2)" )

    new mapName[ MAX_MAPNAME_LENGHT ];
    new filersMapCount = ArraySize( g_whitelistArray );

    LOG( 8, "" )
    LOG( 8, "( print_is_white_list_out_block|FOR in)" )

    for( new currentMapIndex = 0; currentMapIndex < filersMapCount; ++currentMapIndex )
    {
        ArrayGetString( g_whitelistArray, currentMapIndex, mapName, charsmax( mapName ) );
        LOG( 8, "( print_is_white_list_out_block|FOR ) g_whitelistArray[%d]: %s", currentMapIndex, mapName )
    }

    LOG( 8, "( print_is_white_list_out_block|FOR out)" )

    return 0;
}

stock debug_vote_map_selection( choiceIndex, mapName[], useWhitelistOutBlock, isWhiteListOutBlock,
                                useEqualiCurrentMap, unsuccessfulCount, currentBlockerStrategy,
                                useIsPrefixInMenu, useMapIsTooRecent, Trie:blockedFillersMapTrie )
{
    LOG( 256, "I AM ENTERING ON debug_vote_map_selection(10) choiceIndex: %d", choiceIndex )
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

    LOG( 8, "%d. ( debug_vote_map_selection|while_%s ) mapName: %s, map_isInMenu: %d, is_theCurrentMap: %d, \
            map_isTooRecent: %d", currentMapIndex, type, mapName, map_isInMenu( mapName ), \
            equali( g_currentMapName, mapName ), map_isTooRecent( mapName ) )

    LOG( 8, "          isPrefixInMenu: %d, TrieKeyExists( blockedFillersMapTrie ): %d, \
            !TrieKeyExists( g_whitelistTrie ): %d", isPrefixInMenu( mapName ), \
            ( useWhitelistOutBlock?  TrieKeyExists( blockedFillersMapTrie, mapName ) : false ), \
            ( isWhiteListOutBlock ? !TrieKeyExists( g_whitelistTrie      , mapName ) : false ) )

    LOG( 8, "          useMapIsTooRecent: %d, useIsPrefixInMenu: %d, useEqualiCurrentMap: %d", \
            useMapIsTooRecent, useIsPrefixInMenu, useEqualiCurrentMap )

    LOG( 8, "          currentBlockerStrategy: %d, unsuccessfulCount:%d, useWhitelistOutBlock: %d", \
            currentBlockerStrategy, unsuccessfulCount, useWhitelistOutBlock )

    return 0;
}

stock vote_addFillers( blockedMapsBuffer[], &announcementShowedTimes = 0 )
{
    LOG( 128, "I AM ENTERING ON vote_addFillers(2) announcementShowedTimes: %d", announcementShowedTimes )
    new maxVotingChoices = MAX_VOTING_CHOICES();

    if( g_totalVoteOptions < maxVotingChoices )
    {
        new FillersFilePathType:fillersFilePathEnum = loadMapGroupsFeature();
        processLoadedMapsFile( fillersFilePathEnum, blockedMapsBuffer, announcementShowedTimes );
    }
    else
    {
        LOG( 8, " ( vote_addFillers ) maxVotingChoices: %d", maxVotingChoices )
        LOG( 8, " ( vote_addFillers ) g_maxVotingChoices: %d", g_maxVotingChoices )
        LOG( 8, " ( vote_addFillers ) g_totalVoteOptions: %d", g_totalVoteOptions )
        LOG( 1, "    ( vote_addFillers ) Just Returning/blocking, the voting list is filled." )
    }
}

stock vote_addNominations( blockedMapsBuffer[], &announcementShowedTimes = 0 )
{
    LOG( 128, "I AM ENTERING ON vote_addNominations(2) announcementShowedTimes: %d", announcementShowedTimes )
    new nominatedMapsCount;

    // Try to add the nominations, if there are nominated maps.
    if( g_nominatedMapsArray
        && ( nominatedMapsCount = ArraySize( g_nominatedMapsArray ) ) )
    {
        LOG( 128, "( vote_addNominations ) nominatedMapsCount: %d", nominatedMapsCount )
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
            if( !mapFilerFilePath[ 0 ]
                || mapFilerFilePath[ 0 ] == MAP_FOLDER_LOAD_FLAG )
            {
                LOG( 1, "AMX_ERR_NOTFOUND, %L", LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilerFilePath )
                log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilerFilePath );
            }
            else
            {
                whitelistMapTrie = g_minPlayerFillerMapGroupTrie;
            }
        }

        new maxVotingChoices = MAX_VOTING_CHOICES();

        // set how many total nominations we can use in this vote
        new maxNominations    = get_pcvar_num( cvar_nomQtyUsed );
        new slotsAvailable    = maxVotingChoices - g_totalVoteOptions;
        new voteNominationMax = ( maxNominations ) ? min( maxNominations, slotsAvailable ) : slotsAvailable;

        // print the players nominations for debug
        LOG( 4, "( vote_addNominations ) nominatedMapsCount", nominatedMapsCount, show_all_players_nominations() )

        // Add as many nominations as we can by FIFO
        for( new nominationIndex = 0; nominationIndex < nominatedMapsCount; ++nominationIndex )
        {
            if( ( mapIndex = ArrayGetCell( g_nominatedMapsArray, nominationIndex ) ) < 0 )
            {
                continue;
            }
            else
            {
                GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, mapName )
                LOG( 4, "( vote_addNominations ) g_nominationLoadedMapsArray.mapIndex: %d, mapName: %s", mapIndex, mapName )

                if( whitelistMapTrie
                    && !TrieKeyExists( whitelistMapTrie, mapName ) )
                {
                    LOG( 8, "    The map: %s, was blocked by the minimum players map setting.", mapName )
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

    } // end if nominations

    LOG( 4, "" )
    LOG( 4, "" )
}

stock show_all_players_nominations()
{
    LOG( 128, "I AM ENTERING ON show_all_players_nominations(0)" )

    new mapIndex;
    new nominator_id;

    new mapName   [ MAX_MAPNAME_LENGHT ];
    new playerName[ MAX_PLAYER_NAME_LENGHT ];

    // set how many total nominations each player is allowed
    new maxPlayerNominations = min( get_pcvar_num( cvar_nomPlayerAllowance ), MAX_OPTIONS_IN_VOTE );

    for( new nominationIndex = 0; nominationIndex < maxPlayerNominations; ++nominationIndex )
    {
        LOG( 4, "" )
        LOG( 4, "" )
        LOG( 4, "( show_all_players_nominations ) nominationIndex:             %d", nominationIndex )
        LOG( 4, "( show_all_players_nominations ) maxPlayerNominations:        %d", maxPlayerNominations )
        LOG( 4, "( show_all_players_nominations ) g_nominationLoadedMapsArray: %d", g_nominationLoadedMapsArray )
        LOG( 4, "( show_all_players_nominations ) ArraySize:                   %d", ArraySize( g_nominationLoadedMapsArray ) )

        for( new player_id = 1; player_id < MAX_PLAYERS_COUNT; ++player_id )
        {
            if( ( mapIndex = getPlayerNominationMapIndex( player_id, nominationIndex ) ) < 0 )
            {
                continue;
            }
            else
            {
                ArrayGetString( g_nominationLoadedMapsArray, mapIndex, mapName, charsmax( mapName ) );
                nominator_id = nomination_getPlayer( mapIndex );

                GET_USER_NAME( nominator_id, playerName )
                LOG( 4, "      %-32s %s", mapName, playerName )
            }
        }
    }

    return 0;
}

stock loadOnlyNominationVoteChoices()
{
    LOG( 128, "I AM ENTERING ON loadOnlyNominationVoteChoices(0)" )

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
    LOG( 128, "I AM ENTERING ON loadTheDefaultVotingChoices(0)" )

    // To add the next map to the voting menu, if enabled.
    if( get_pcvar_num( cvar_voteMapChoiceNext )
        && !equali( g_currentMapName, g_nextMapName )
        && !map_isTooRecent( g_nextMapName ) )
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

    SET_VOTING_TIME_TO( g_votingSecondsRemaining, cvar_voteDuration )

    LOG( 4, "    ( loadTheDefaultVotingChoices ) g_totalVoteOptions: %d", g_totalVoteOptions )
    return g_totalVoteOptions;
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
    LOG( 128, "I AM ENTERING ON announceVoteBlockedMap(4) announcementShowedTimes: %d, \
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
    LOG( 128, "I AM ENTERING ON flushVoteBlockedMaps(3) announcementShowedTimes: %d, ", announcementShowedTimes )
    LOG( 8, "blockedMapsBuffer: %s",  blockedMapsBuffer )

    if( blockedMapsBuffer[ 0 ] )
    {
        if( announcementShowedTimes == 1 )
        {
            color_chat( 0, "%L", LANG_PLAYER, flushAnnouncement, 0, 0 );
        }

        color_chat( 0, "%L", LANG_PLAYER, "GAL_MATCHING", blockedMapsBuffer[ 3 ] );

        announcementShowedTimes++;
        blockedMapsBuffer[ 0 ] = '^0';
    }
}

stock computeNextWhiteListLoadTime( seconds, bool:isSecondsLeft = true )
{
    LOG( 128, "I AM ENTERING ON computeNextWhiteListLoadTime(2) seconds: %d, isSecondsLeft: %d", seconds, isSecondsLeft )
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
        doAmxxLog( "ERROR, computeNextWhiteListLoadTime: The seconds parameter is zero!" );
    }

    LOG( 1, "I AM EXITING computeNextWhiteListLoadTime(2) g_whitelistNomBlockTime: %d, secondsForReload: %d", g_whitelistNomBlockTime, secondsForReload )
}

/**
 * Action from handleServerStart to take when it is detected that the server has been
 * restarted. 3 - start an early map vote after the first two minutes.
 */
stock vote_manageEarlyStart()
{
    LOG( 128, "I AM ENTERING ON vote_manageEarlyStart(0) g_voteStatus: %d", g_voteStatus )
    g_voteStatus |= IS_EARLY_VOTE;

    set_task( 120.0, "startNonForcedVoting", TASKID_START_THE_VOTING );
}

public startNonForcedVoting()
{
    LOG( 128, "I AM ENTERING ON startNonForcedVoting(0) g_endVotingType: %d", g_endVotingType )
    startTheVoting( false );
}

public start_voting_by_winlimit()
{
    LOG( 128, "I AM ENTERING ON start_voting_by_winlimit(0) g_endVotingType: %d", g_endVotingType)
    LOG( 32, "( start_voting_by_winlimit ) get_pcvar_num( cvar_endOfMapVote ): %d", get_pcvar_num( cvar_endOfMapVote ) )

    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_endVotingType |= IS_BY_WINLIMIT;
        startTheVoting( false );
    }
}

public start_voting_by_maxrounds()
{
    LOG( 128, "I AM ENTERING ON start_voting_by_maxrounds(0) g_endVotingType: %d", g_endVotingType)
    LOG( 32, "( start_voting_by_maxrounds ) get_pcvar_num( cvar_endOfMapVote ): %d", get_pcvar_num( cvar_endOfMapVote ) )

    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_endVotingType |= IS_BY_ROUNDS;
        startTheVoting( false );
    }
}

public start_voting_by_frags()
{
    LOG( 128, "I AM ENTERING ON start_voting_by_frags(0) g_endVotingType: %d", g_endVotingType)
    LOG( 32, "( start_voting_by_frags ) get_pcvar_num( cvar_endOfMapVote ): %d", get_pcvar_num( cvar_endOfMapVote ) )

    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_endVotingType |= IS_BY_FRAGS;
        startTheVoting( false );
    }
}

public start_voting_by_timer()
{
    LOG( 128, "I AM ENTERING ON start_voting_by_timer(0) g_endVotingType: %d", g_endVotingType)
    LOG( 32, "( start_voting_by_timer ) get_pcvar_num( cvar_endOfMapVote ): %d", get_pcvar_num( cvar_endOfMapVote ) )

    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_endVotingType |= IS_BY_TIMER;
        startTheVoting( false );
    }
}

public startVotingByGameEngineCall()
{
    LOG( 128, "I AM ENTERING ON startVotingByGameEngineCall(0) g_endVotingType: %d", g_endVotingType)
    LOG( 32, "( startVotingByGameEngineCall ) get_pcvar_num( cvar_endOfMapVote ): %d", get_pcvar_num( cvar_endOfMapVote ) )

    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_isToChangeMapOnVotingEnd = true;
        startTheVoting( false );
    }
}

public vote_manageEnd()
{
    LOG( 256, "I AM ENTERING ON vote_manageEnd(0)" )
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

        LOG( 256, "( vote_manageEnd ) START_VOTEMAP_MIN_TIME: %d", START_VOTEMAP_MIN_TIME )
        LOG( 256, "( vote_manageEnd ) START_VOTEMAP_MAX_TIME: %d", START_VOTEMAP_MAX_TIME )

        // Are we ready to start an "end of map" vote?
        if( secondsLeft < START_VOTEMAP_MIN_TIME
            && secondsLeft > START_VOTEMAP_MAX_TIME )
        {
            new endOfMapVote = get_pcvar_num( cvar_endOfMapVote );

            // Here we tread a special case. There were not enough rounds saved, but we already hit
            // the vote_manageEnd(0) which is only called on the last seconds of the map. Then just
            // to start the voting right now, to allow one round maps.
            //
            // Note: Only timed maps are susceptible to this problem, maps guided by fraglimit,
            // maxrounds and winlimit are good to go.
            if( isTimeToStartTheEndOfMapVoting( endOfMapVote )
                || ( endOfMapVote
                     && !g_isTheRoundEnded
                     && g_totalRoundsSavedTimes < MIN_VOTE_START_ROUNDS_DELAY + 1 ) )
            {
                start_voting_by_timer();
            }
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

    periodicTimeLeftHandleChecking( secondsLeft );
}

stock periodicTimeLeftHandleChecking( secondsLeft )
{
    LOG( 256, "I AM ENTERING ON periodicTimeLeftHandleChecking(1) secondsLeft: %d", secondsLeft )

    showRemainingTimeUntilVoting();
    create_game_crash_recreation( secondsLeft );
}

stock showRemainingTimeUntilVoting()
{
    LOG( 128, "I AM ENTERING ON showRemainingTimeUntilVoting(0)" )

    static showCounter;
    const trigger_count = 750 / PERIODIC_CHECKING_INTERVAL;

    // PERIODIC_CHECKING_INTERVAL = 15 seconds, 15 * 50 = 750 = 12.5 minutes
    if( ++showCounter % trigger_count < 1 )
    {
        new displayTime = 7;
        set_hudmessage( 255, 255, 255, 0.15, 0.15, 0, 0.0, float( displayTime ), 0.1, 0.1, 1 );

        switch( whatGameEndingTypeItIs() )
        {
            case GameEndingType_ByMaxRounds:
            {
                new roundsLeft = get_pcvar_num( cvar_mp_maxrounds ) - g_totalRoundsPlayed;

                if( roundsLeft > 0 )
                {
                    if( !( get_pcvar_num( cvar_hudsHide ) & HUD_TIMELEFT_ANNOUNCE ) )
                    {
                        show_hudmessage( 0, "%L:^n%d %L", LANG_PLAYER, "TIME_LEFT", roundsLeft, LANG_PLAYER, "GAL_ROUNDS" );
                    }

                    color_chat( 0, "%L %L...", LANG_PLAYER, "GAL_VOTE_COUNTDOWN", roundsLeft, LANG_PLAYER, "GAL_ROUNDS" );
                }
            }
            case GameEndingType_ByWinLimit:
            {
                new winLeft = get_pcvar_num( cvar_mp_winlimit ) - max( g_totalCtWins, g_totalTerroristsWins );

                if( winLeft > 0 )
                {
                    if( !( get_pcvar_num( cvar_hudsHide ) & HUD_TIMELEFT_ANNOUNCE ) )
                    {
                        show_hudmessage( 0, "%L:^n%d %L", LANG_PLAYER, "TIME_LEFT", winLeft, LANG_PLAYER, "GAL_ROUNDS" );
                    }

                    color_chat( 0, "%L %L...", LANG_PLAYER, "GAL_VOTE_COUNTDOWN", winLeft, LANG_PLAYER, "GAL_ROUNDS" );
                }
            }
            case GameEndingType_ByFragLimit:
            {
                new fragsLeft = get_pcvar_num( cvar_mp_fraglimit ) - g_greatestKillerFrags;

                if( fragsLeft > 0 )
                {
                    if( !( get_pcvar_num( cvar_hudsHide ) & HUD_TIMELEFT_ANNOUNCE ) )
                    {
                        show_hudmessage( 0, "%L:^n%d %L", LANG_PLAYER, "TIME_LEFT", fragsLeft, LANG_PLAYER, "GAL_FRAGS" );
                    }

                    color_chat( 0, "%L %L...", LANG_PLAYER, "GAL_VOTE_COUNTDOWN", fragsLeft, LANG_PLAYER, "GAL_FRAGS" );
                }
            }
            case GameEndingType_ByTimeLimit:
            {
                new timeLeft = get_timeleft() - g_totalVoteTime;

                if( !( get_pcvar_num( cvar_hudsHide ) & HUD_TIMELEFT_ANNOUNCE ) )
                {
                    set_task( 1.0, "displayRemainingTime", TASKID_DISPLAY_REMAINING_TIME, _, _, "a", displayTime );
                }

                if( timeLeft > 0 )
                {
                    color_chat( 0, "%L %L...", LANG_PLAYER, "GAL_VOTE_COUNTDOWN", ( timeLeft ) / 60, LANG_PLAYER, "GAL_MINUTES" );
                }
            }
            default:
            {
                if( !( get_pcvar_num( cvar_hudsHide ) & HUD_TIMELEFT_ANNOUNCE ) )
                {
                    show_hudmessage( 0, "%L:^n%L", LANG_PLAYER, "TIME_LEFT", LANG_PLAYER, "NO_T_LIMIT" );
                }

                color_chat( 0, "^4%L:^1 %L...", LANG_PLAYER, "TIME_LEFT", LANG_PLAYER, "NO_T_LIMIT" );
            }
        }
    }
}

public displayRemainingTime()
{
    LOG( 128, "I AM ENTERING ON displayRemainingTime(0)" )

    new timeLeft = get_timeleft();
    new seconds  = timeLeft % 60;
    new minutes  = floatround( ( timeLeft - seconds ) / 60.0 );

    set_hudmessage( 255, 255, 255, 0.15, 0.15, 0, 0.0, 1.1, 0.1, 0.1, 1 );
    show_hudmessage( 0, "%L:^n%d: %2d %L", LANG_PLAYER, "TIME_LEFT", minutes, seconds, LANG_PLAYER, "MINUTES" );
}

/**
 * Handle the action to take immediately after half of the time-left or rounds-left passed
 * when using the 'Game Server Crash Recreation' Feature.
 */
stock create_game_crash_recreation( secondsLeft )
{
    LOG( 128, "I AM ENTERING ON create_game_crash_recreation(0)" )

    if( g_isToCreateGameCrashFlag
        && (  g_timeLimitNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_timeLimitNumber - secondsLeft / 60
           || g_fragLimitNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_greatestKillerFrags
           || g_maxRoundsNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_totalRoundsPlayed + 1
           || g_winLimitNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_totalTerroristsWins + g_totalCtWins ) )
    {
        new gameCrashActionFilePath[ MAX_FILE_PATH_LENGHT ];

        // stop creating this file unnecessarily
        g_isToCreateGameCrashFlag = false;

        LOG( 32, "( vote_manageEnd )  %d/%d < %d: %d", \
                g_timeLimitNumber, SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR, g_timeLimitNumber - secondsLeft / 60, \
                g_timeLimitNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_timeLimitNumber - secondsLeft / 60 )

        LOG( 32, "( vote_manageEnd )  %d/%d < %d: %d", \
                g_fragLimitNumber, SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR, g_greatestKillerFrags, \
                g_fragLimitNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_greatestKillerFrags )

        LOG( 32, "( vote_manageEnd )  %d/%d < %d: %d", \
                g_maxRoundsNumber, SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR, g_totalRoundsPlayed + 1, \
                g_maxRoundsNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_totalRoundsPlayed + 1 )

        LOG( 32, "( vote_manageEnd )  %d/%d < %d: %d", \
                g_winLimitNumber, SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR, g_totalTerroristsWins + g_totalCtWins, \
                g_winLimitNumber / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR < g_totalTerroristsWins + g_totalCtWins )

        generateGameCrashActionFilePath( gameCrashActionFilePath, charsmax( gameCrashActionFilePath ) );
        write_file( gameCrashActionFilePath, "Game Crash Action Flag File^n^nSee the cvar \
                'gal_game_crash_recreation'.^nDo not delete it." );
    }
}

stock bool:approveTheVotingStart( bool:is_forced_voting )
{
    LOG( 128, "I AM ENTERING ON approveTheVotingStart(1)" )
    new playersCount = get_real_players_number();

    LOG( 4, "( approveTheVotingStart ) is_forced_voting:          %d", is_forced_voting )
    LOG( 4, "( approveTheVotingStart ) cvar_nextMapChangeVotemap: %d", get_pcvar_num( cvar_nextMapChangeVotemap ) )

    if( get_pcvar_num( cvar_nextMapChangeVotemap )
        && !is_forced_voting )
    {
        new nextMapFlag[ 128 ];
        new nextMapName[ MAX_MAPNAME_LENGHT ];

        formatex( nextMapFlag, charsmax( nextMapFlag ), "%L", LANG_SERVER, "GAL_NEXTMAP_UNKNOWN" );
        REMOVE_CODE_COLOR_TAGS( nextMapFlag )

        new bool:isNextMapChangeAnnounce = get_pcvar_num( cvar_nextMapChangeAnnounce ) != 0;
        get_pcvar_string( cvar_amx_nextmap, nextMapName, charsmax( nextMapName ) );

        LOG( 4, "( approveTheVotingStart ) nextMapFlag:             %s", nextMapFlag )
        LOG( 4, "( approveTheVotingStart ) nextMapName:             %s", nextMapName )
        LOG( 4, "( approveTheVotingStart ) g_nextMapName:           %s", g_nextMapName )
        LOG( 4, "( approveTheVotingStart ) isNextMapChangeAnnounce: %d", isNextMapChangeAnnounce )

        if( isNextMapChangeAnnounce
            && !equali( nextMapFlag, nextMapName, strlen( nextMapName ) )
            || !isNextMapChangeAnnounce
               && !equali( g_nextMapName, nextMapName, strlen( nextMapName ) ) )
        {
            // The voting is over, i.e., must to be performed.
            g_voteStatus |= IS_VOTE_OVER;

            LOG( 1, "    ( approveTheVotingStart ) Returning false due the `gal_nextmap_votemap` feature." )
            return false;
        }
    }

    // block the voting on some not allowed situations/cases
    if( playersCount == 0
        || g_voteStatus & IS_VOTE_IN_PROGRESS
        || g_voteStatus & IS_RUNOFF_VOTE
        || ( !is_forced_voting
             && g_voteStatus & IS_VOTE_OVER ) )
    {
        LOG( 1, "( approveTheVotingStart ) g_voteStatus: %d", g_voteStatus )
        LOG( 1, "( approveTheVotingStart ) g_voteStatus & IS_VOTE_OVER: %d", g_voteStatus & IS_VOTE_OVER != 0 )

    #if ARE_WE_RUNNING_UNIT_TESTS
        if( g_test_areTheUnitTestsRunning )
        {
            LOG( 1, "    ( approveTheVotingStart ) Returning true on the if !g_test_areTheUnitTestsRunning" )
            return true;
        }
    #endif

        LOG( 1, "( approveTheVotingStart ) cvar_isEmptyCycleByMapChange: %d", get_pcvar_num( cvar_isEmptyCycleByMapChange ) )

        // Start the empty cycle on the end of the map, if this feature is enabled
        if( playersCount == 0 )
        {
            if( get_pcvar_num( cvar_isEmptyCycleByMapChange ) )
            {
                startEmptyCycleSystem();
            }

            // If there are 0 players, announce the voting will never start.
            if( IS_TO_IGNORE_SPECTATORS() )
            {
                color_chat( 0, CANNOT_START_VOTE_SPECTATORS );
                server_print( CANNOT_START_VOTE_SPECTATORS );
            }

            // If somehow the voting is going on, disables it
            if( g_voteStatus & IS_VOTE_IN_PROGRESS )
            {
                cancelVoting();
            }
        }

        LOG( 1, "    ( approveTheVotingStart ) Returning false on the big blocker." )
        return false;
    }

    // allow a new forced voting while the map is ending
    if( is_forced_voting
        && g_voteStatus & IS_VOTE_OVER )
    {
        new bool:roundEndStatus[ SaveRoundEnding ];

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

    if( g_isMapExtensionPeriodRunning
        && !is_forced_voting )
    {
        LOG( 1, "    ( approveTheVotingStart ) Returning false, block the new voting after the map extension." )
        return false;
    }

    LOG( 1, "    ( approveTheVotingStart ) Returning true, due passed by all requirements." )
    return true;
}

stock bool:approveTheRunoffVotingStart()
{
    LOG( 128, "I AM ENTERING ON approveTheRunoffVotingStart(0)" )

    // block the voting on some not allowed situations/cases
    if( get_real_players_number() == 0
        || ( g_voteStatus & IS_VOTE_OVER )
        || !( g_voteStatus & IS_RUNOFF_VOTE ) )
    {
        LOG( 1, "    ( approveTheRunoffVotingStart ) g_voteStatus: %d", g_voteStatus )
        LOG( 1, "    ( approveTheRunoffVotingStart ) g_voteStatus & IS_VOTE_OVER: %d", g_voteStatus & IS_VOTE_OVER != 0 )

    #if ARE_WE_RUNNING_UNIT_TESTS
        if( g_test_areTheUnitTestsRunning )
        {
            LOG( 1, "    ( approveTheRunoffVotingStart ) Returning true on the if !g_test_areTheUnitTestsRunning" )
            LOG( 1, "    ( approveTheRunoffVotingStart ) cvar_isEmptyCycleByMapChange: %d", get_pcvar_num( cvar_isEmptyCycleByMapChange ) )
            return true;
        }
    #endif

        LOG( 1, "    ( approveTheRunoffVotingStart ) Returning false on the first blocker." )
        return false;
    }

    LOG( 1, "    ( approveTheRunoffVotingStart ) Returning true, due passed by all requirements." )
    return true;
}

stock printVotingMaps( mapNames[][], mapInfos[][], votingMapsCount = MAX_OPTIONS_IN_VOTE )
{
    LOG( 128, "I AM ENTERING ON printVotingMaps(3) votingMapsCount: %d", votingMapsCount )

    for( new index = 0; index < votingMapsCount; index++ )
    {
        LOG( 16, "( printVotingMaps ) Voting map %d: %s %s", index, mapNames[ index ], mapInfos[ index ] )
    }

    LOG( 16, "" )
    LOG( 16, "" )

    // Removes the compiler warning `warning 203: symbol is never used` with some DEBUG levels.
    if( mapNames[ 0 ][ 0 ] && mapInfos[ 0 ][ 0 ] ) { }

    return 0;
}

stock loadRunOffVoteChoices()
{
    LOG( 128, "I AM ENTERING ON loadRunOffVoteChoices(0)" )

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

    SET_VOTING_TIME_TO( g_votingSecondsRemaining, cvar_runoffDuration )
    LOG( 0, "", printVotingMaps(  g_votingMapNames, g_votingMapInfos, g_totalVoteOptions ) )

    LOG( 1, "    ( loadRunOffVoteChoices ) g_totalVoteOptions: %d", g_totalVoteOptions )
    return g_totalVoteOptions;
}

stock configureVotingStart( bool:is_forced_voting )
{
    LOG( 128, "I AM ENTERING ON configureVotingStart(1) is_forced_voting: %d", is_forced_voting )

    // update cached data for the new voting
    cacheCvarsValues();

    // make it known that a vote is in progress
    g_voteStatus |= IS_VOTE_IN_PROGRESS;

    // Make sure this is not pointing to anything before the voting.
    g_invokerVoteMapNameToDecide[ 0 ] = '^0';

    // Set the voting status to forced
    if( is_forced_voting )
    {
        g_voteStatus |= IS_FORCED_VOTE;
    }

    configureTheExtensionOption( is_forced_voting );

    LOG( 4, "( configureVotingStart ) g_voteStatus: %d, ", g_voteStatus )
    LOG( 4, "( configureVotingStart ) g_voteMapStatus: %d, ", g_voteMapStatus )

    // stop RTV reminders
    remove_task( TASKID_RTV_REMINDER );
}

/**
 * To allow show the extension option as `Stay Here` and `Extend` and to set the end voting type.
 */
stock configureTheExtensionOption( bool:is_forced_voting )
{
    LOG( 128, "I AM ENTERING ON configureTheExtensionOption(1) is_forced_voting: %d", is_forced_voting )

    //
    if( g_voteMapStatus & IS_DISABLED_VOTEMAP_EXTENSION )
    {
        LOG( 4, "( configureTheExtensionOption ) 1. " )
        g_isMapExtensionAllowed = false;
    }

    //
    else if( g_voteStatus & IS_RTV_VOTE
             && get_pcvar_num( cvar_rtvWaitAdmin ) & IS_TO_RTV_NOT_ALLOW_STAY )
    {
        LOG( 4, "( configureTheExtensionOption ) 2. cvar_rtvWaitAdmin: %d", get_pcvar_num( cvar_rtvWaitAdmin ) )
        g_isMapExtensionAllowed = false;
    }

    // When this is set to true, we must allow the extension. Otherwise we would not get here never
    // as the extend option was previously showed.
    else if( g_isRunOffNeedingKeepCurrentMap )
    {
        LOG( 4, "( configureTheExtensionOption ) 3. g_isRunOffNeedingKeepCurrentMap: %d", g_isRunOffNeedingKeepCurrentMap )
        g_isMapExtensionAllowed = true;
    }

    //
    else if( g_endVotingType & IS_BY_FRAGS )
    {
        new maxMapExtendFrags = get_pcvar_num( cvar_maxMapExtendFrags );

        LOG( 4, "( configureTheExtensionOption ) 4. maxMapExtendFrags:    %d", maxMapExtendFrags )
        LOG( 4, "( configureTheExtensionOption ) cvar_mp_fraglimit:       %d", get_pcvar_num( cvar_mp_fraglimit ) )
        LOG( 4, "( configureTheExtensionOption ) g_fragLimitContextSaved: %d", g_fragLimitContextSaved )

        g_isMapExtensionAllowed =
                ( GAME_ENDING_CONTEXT_SAVED( g_fragLimitContextSaved, get_pcvar_num( cvar_mp_fraglimit ) ) < maxMapExtendFrags
                  || maxMapExtendFrags == 0 );
    }

    //
    else if( g_endVotingType & IS_BY_ROUNDS )
    {
        new maxMapExtendRounds = get_pcvar_num( cvar_maxMapExtendRounds );

        LOG( 4, "( configureTheExtensionOption ) 5. maxMapExtendRounds:   %d", maxMapExtendRounds )
        LOG( 4, "( configureTheExtensionOption ) cvar_mp_maxrounds:       %d", get_pcvar_num( cvar_mp_maxrounds ) )
        LOG( 4, "( configureTheExtensionOption ) g_maxRoundsContextSaved: %d", g_maxRoundsContextSaved )

        g_isMapExtensionAllowed =
                ( GAME_ENDING_CONTEXT_SAVED( g_maxRoundsContextSaved, get_pcvar_num( cvar_mp_maxrounds ) ) < maxMapExtendRounds
                  || maxMapExtendRounds == 0 );
    }

    //
    else if( g_endVotingType & IS_BY_WINLIMIT )
    {
        new maxMapExtendRounds = get_pcvar_num( cvar_maxMapExtendRounds );

        LOG( 4, "( configureTheExtensionOption ) 6. maxMapExtendRounds:  %d", maxMapExtendRounds )
        LOG( 4, "( configureTheExtensionOption ) cvar_mp_winlimit:       %d", get_pcvar_num( cvar_mp_winlimit ) )
        LOG( 4, "( configureTheExtensionOption ) g_winLimitContextSaved: %d", g_winLimitContextSaved )

        g_isMapExtensionAllowed =
                ( GAME_ENDING_CONTEXT_SAVED( g_winLimitContextSaved, get_pcvar_num( cvar_mp_winlimit ) ) < maxMapExtendRounds
                  || maxMapExtendRounds == 0 );
    }

    //
    else if( g_endVotingType & IS_BY_TIMER )
    {
        new maxMapExtendTime = get_pcvar_num( cvar_maxMapExtendTime );

        LOG( 4, "( configureTheExtensionOption ) 7. maxMapExtendTime:     %d", maxMapExtendTime )
        LOG( 4, "( configureTheExtensionOption ) cvar_mp_timelimit:       %f", get_pcvar_num( cvar_mp_timelimit ) )
        LOG( 4, "( configureTheExtensionOption ) g_timeLimitContextSaved: %d", g_timeLimitContextSaved )

        g_isMapExtensionAllowed =
                ( GAME_ENDING_CONTEXT_SAVED( g_timeLimitContextSaved, get_pcvar_float( cvar_mp_timelimit ) ) < maxMapExtendTime
                  || maxMapExtendTime == 0 );
    }

    // If we cannot find anything allowing it, block it by the default.
    else
    {
        LOG( 4, "( configureTheExtensionOption ) 8. g_isMapExtensionAllowed: %d", g_isMapExtensionAllowed )
        g_isMapExtensionAllowed = false;
    }

    // Determine whether the voting is whether forced or automatically started.
    g_isGameFinalVoting = ( ( g_endVotingType & IS_BY_ROUNDS
                              || g_endVotingType & IS_BY_WINLIMIT
                              || g_endVotingType & IS_BY_TIMER
                              || g_endVotingType & IS_BY_FRAGS )
                            && !is_forced_voting );

    // Log some data resulted
    LOG( 4, "( configureTheExtensionOption )" )
    LOG( 4, "( configureTheExtensionOption ) g_endVotingType:         %d", g_endVotingType )
    LOG( 4, "( configureTheExtensionOption ) g_voteMapStatus:         %d", g_voteMapStatus )
    LOG( 4, "( configureTheExtensionOption ) is_forced_voting:        %d", is_forced_voting )
    LOG( 4, "( configureTheExtensionOption ) g_isGameFinalVoting:     %d", g_isGameFinalVoting )
    LOG( 4, "( configureTheExtensionOption ) g_isMapExtensionAllowed: %d", g_isMapExtensionAllowed )
}

/**
 * Any voting not started by `cvar_endOfMapVoteStart`, `cvar_endOnRound` or ending limit expiration,
 * is a forced voting.
 */
stock startTheVoting( bool:is_forced_voting )
{
    LOG( 128, "I AM ENTERING ON startTheVoting(1) is_forced_voting: %d", is_forced_voting )

    if( !approveTheVotingStart( is_forced_voting ) )
    {
        LOG( 1, "    ( startTheVoting ) Just Returning/blocking, the voting was not approved." )
        return;
    }

    // Clear the cmd_startVote(3) map settings just in case they where loaded.
    // Clean it just to be sure as the voteMapMenuBuilder() could let it filled.
    clearTheVotingMenu();
    g_voteMapStatus = 0;

    // to prepare the initial voting state
    configureVotingStart( is_forced_voting );

    // To load vote choices  and show up the voting menu
    if( loadTheDefaultVotingChoices() )
    {
        initializeTheVoteDisplay();
    }
    else
    {
        // Vote creation failed; no maps found.
        color_chat( 0, "%L", LANG_PLAYER, "GAL_VOTE_NOMAPS" );
        finalizeVoting();
    }

    LOG( 4, "" )
    LOG( 4, "    ( startTheVoting|out ) g_isTheLastGameRound:          %d", g_isTheLastGameRound )
    LOG( 4, "    ( startTheVoting|out ) g_isTimeToRestart:             %d", g_isTimeToRestart )
    LOG( 4, "    ( startTheVoting|out ) g_voteStatus & IS_FORCED_VOTE: %d", g_voteStatus & IS_FORCED_VOTE != 0 )
}

/**
 * Any voting not started by `cvar_endOfMapVoteStart`, `cvar_endOnRound` or ending limit expiration,
 * is a forced voting.
 */
public startTheRunoffVoting()
{
    LOG( 128, "I AM ENTERING ON startTheRunoffVoting(0)" )

    if( !approveTheRunoffVotingStart() )
    {
        LOG( 1, "    ( startTheRunoffVoting ) Just Returning/blocking, the voting was not approved." )
        return;
    }

    // To load runoff vote choices and show up the voting menu
    if( loadRunOffVoteChoices() )
    {
        initializeTheVoteDisplay();
    }
    else
    {
        // Vote creation failed; no maps found.
        color_chat( 0, "%L", LANG_PLAYER, "GAL_VOTE_NOMAPS" );
        finalizeVoting();
    }

    LOG( 4, "" )
    LOG( 4, "    ( startTheRunoffVoting|out ) g_isTheLastGameRound:          %d", g_isTheLastGameRound )
    LOG( 4, "    ( startTheRunoffVoting|out ) g_isTimeToRestart:             %d", g_isTimeToRestart )
    LOG( 4, "    ( startTheRunoffVoting|out ) g_voteStatus & IS_FORCED_VOTE: %d", g_voteStatus & IS_FORCED_VOTE != 0 )
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
    LOG( 128, "I AM ENTERING ON SortCustomSynced2D(3) arraySize: %d", arraySize )
    LOG( 0, "", printVotingMaps( array, arraySync ) )

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

    LOG( 0, "", printVotingMaps( array, arraySync ) )
}

stock initializeTheVoteDisplay()
{
    LOG( 128, "I AM ENTERING ON initializeTheVoteDisplay(0)" )

    new player_id;
    new playersCount;

    new players[ MAX_PLAYERS ];
    new Float:handleChoicesDelay;

    // Clear all nominations
    nomination_clearAll();

    // Alphabetize the maps
    if( !( get_pcvar_num( cvar_generalOptions ) & DO_NOT_ALPHABETIZE_VOTEMAP_MENU ) )
    {
        SortCustomSynced2D( g_votingMapNames, g_votingMapInfos, g_totalVoteOptions );
    }

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
#if DEBUG_LEVEL & DEBUG_LEVEL_FAKE_VOTES
    g_votingSecondsRemaining = 5;
    handleChoicesDelay       = 0.1;
#else
    new isToAskForEndOfTheMapVote;
    isToAskForEndOfTheMapVote = get_pcvar_num( cvar_isToAskForEndOfTheMapVote );

    if( g_voteMapStatus & IS_DISABLED_VOTEMAP_INTRO
        || isToAskForEndOfTheMapVote & END_OF_MAP_VOTE_NO_ANNOUNCEMENT )
    {
        handleChoicesDelay = 0.1;
    }
    else
    {
        // Set_task 1.0 + pendingVoteCountdown 1.0
        handleChoicesDelay = VOTE_TIME_SEC + VOTE_TIME_SEC + getVoteAnnouncementTime( isToAskForEndOfTheMapVote );

        // Make perfunctory announcement: "get ready to choose a map"
        if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_GET_READY_TO_CHOOSE ) )
        {
            client_cmd( 0, "spk ^"get red( e80 ) ninety( s45 ) to check( e20 ) \
                    use bay( s18 ) mass( e42 ) cap( s50 )^"" );
        }

        // Announce the pending vote countdown from 7 | 5 to 1
        if( isToAskForEndOfTheMapVote & END_OF_MAP_VOTE_ANNOUNCE1 )
        {
            if( isToAskForEndOfTheMapVote & END_OF_MAP_VOTE_ANNOUNCE2 )
            {
                set_task( VOTE_TIME_ANNOUNCE2, "announceThePendingVote", TASKID_PENDING_VOTE_COUNTDOWN );
                announceThePendingVoteTime( VOTE_TIME_ANNOUNCE2 + VOTE_TIME_HUD2 );
            }
            else
            {
                set_task( VOTE_TIME_ANNOUNCE1, "announceThePendingVote", TASKID_PENDING_VOTE_COUNTDOWN );
                announceThePendingVoteTime( VOTE_TIME_ANNOUNCE1 + VOTE_TIME_HUD1 );
            }
        }
        else
        {
            // Visual countdown
            announceThePendingVote();
            announceThePendingVoteTime( VOTE_TIME_HUD1 );
        }
    }
#endif

    // To create fake votes when needed
#if DEBUG_LEVEL & DEBUG_LEVEL_FAKE_VOTES
    set_task( 2.0, "create_fakeVotes", TASKID_DBG_FAKEVOTES );
#endif

    // Set debug options
    LOG( 0, "", configureVoteDisplayDebugging() )

    // Display the map choices, 1 second from now
    set_task( handleChoicesDelay, "vote_handleDisplay", TASKID_VOTE_HANDLEDISPLAY );
}

stock announceThePendingVoteTime( Float:time )
{
    LOG( 128, "I AM ENTERING ON announceThePendingVoteTime(1) time: %f", time )

    new targetTime = floatround( time, floatround_floor );
    color_chat( 0, "%L", LANG_PLAYER, "DMAP_NEXTMAP_VOTE_REMAINING2", targetTime );

    // If there is enough time
    if( targetTime > 4
        && !( get_pcvar_num( cvar_hudsHide ) & HUD_VOTE_VISUAL_COUNTDOWN ) )
    {
        set_hudmessage( 0, 222, 50, -1.0, 0.13, 1, 1.0, 4.94, 0.0, 0.0, -1 );
        show_hudmessage( 0, "%L", LANG_PLAYER, "DMAP_NEXTMAP_VOTE_REMAINING1", targetTime );
    }
}

public announceThePendingVote()
{
    LOG( 128, "I AM ENTERING ON announceThePendingVote(0)" )

    if( get_pcvar_num( cvar_isToAskForEndOfTheMapVote ) & END_OF_MAP_VOTE_ANNOUNCE1 )
    {
        g_pendingVoteCountdown = floatround( VOTE_TIME_HUD2, floatround_floor ) + 1;
    }
    else
    {
        g_pendingVoteCountdown = floatround( VOTE_TIME_HUD1, floatround_floor ) + 1;
    }

    set_task( VOTE_TIME_SEC, "pendingVoteCountdown", TASKID_PENDING_VOTE_COUNTDOWN, _, _, "a", g_pendingVoteCountdown );
}

stock Float:getVoteAnnouncementTime( isToAskForEndOfTheMapVote )
{
    LOG( 128, "I AM ENTERING ON getVoteAnnouncementTime(0)" )

    if( isToAskForEndOfTheMapVote & END_OF_MAP_VOTE_NO_ANNOUNCEMENT )
    {
        return 1.0;
    }
    else
    {
        if( isToAskForEndOfTheMapVote & END_OF_MAP_VOTE_ANNOUNCE1 )
        {
            if( isToAskForEndOfTheMapVote & END_OF_MAP_VOTE_ANNOUNCE2 )
            {
                return VOTE_TIME_ANNOUNCE2 + VOTE_TIME_HUD2;
            }
            else
            {
                return VOTE_TIME_ANNOUNCE1 + VOTE_TIME_HUD2;
            }
        }
    }

    return VOTE_TIME_HUD1;
}

stock configureVoteDisplayDebugging()
{
    // Print the voting map options
    new voteOptions = ( g_totalVoteOptions == 1 ? 2 : g_totalVoteOptions );

    LOG( 4, "" )
    LOG( 4, "" )
    LOG( 4, "   [PLAYER CHOICES]" )

    for( new dbgChoice = 0; dbgChoice < voteOptions; dbgChoice++ )
    {
        LOG( 4, "      %i. %s %s", dbgChoice + 1, g_votingMapNames[ dbgChoice ], g_votingMapInfos[ dbgChoice ] )
    }

    return 0;
}

public pendingVoteCountdown()
{
    LOG( 128, "I AM ENTERING ON pendingVoteCountdown(0) g_pendingVoteCountdown: %d", g_pendingVoteCountdown )

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
    LOG( 128, "I AM ENTERING ON displayEndOfTheMapVoteMenu(1) player_id: %d", player_id )

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

            LOG( 4, " ( displayEndOfTheMapVoteMenu| for ) menu_body: %s", menu_body )
            LOG( 4, "    menu_id:%d, menuKeys: %d, isVoting: %d, playerAnswered:%d, \
                    player_id: %d, playerIndex: %d", menu_id, menuKeys, isVoting, playerAnswered, \
                    player_id, playerIndex )

            LOG( 4, "    playersCount: %d, g_pendingVoteCountdown: %d, menu_counter: %s", \
                    playersCount, g_pendingVoteCountdown, menu_counter )
        }
    }

    LOG( 4, "%48s", " ( displayEndOfTheMapVoteMenu| out )" )
}

public handleEndOfTheMapVoteChoice( player_id, pressedKeyCode )
{
    LOG( 128, "I AM ENTERING ON handleEndOfTheMapVoteChoice(2) player_id: %d, pressedKeyCode: %d", \
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

        LOG( 1, "    ( handleEndOfTheMapVoteChoice ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }

    g_answeredForEndOfMapVote[ player_id ] = true;

    // displayEndOfTheMapVoteMenu( player_id );
    set_task( 0.1, "displayEndOfTheMapVoteMenu", player_id );

    LOG( 1, "    ( handleEndOfTheMapVoteChoice ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

public vote_handleDisplay()
{
    LOG( 128, "I AM ENTERING ON vote_handleDisplay(0)" )

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

    if( g_showVoteStatus == SHOW_STATUS_ALWAYS
        || g_showVoteStatus == SHOW_STATUS_AFTER_VOTE
        || g_showVoteStatus == SHOW_STATUS_ALWAYS_UNTIL_VOTE )
    {
        new argument[ 2 ] = { true, 0 };
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
    LOG( 128, "I AM ENTERING ON tryToShowTheVotingMenu(0)" )

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
    LOG( 128, "I AM ENTERING ON closeVoting(0)" )
    new argument[ 2 ] = { false, -1 };

    // waits until the last voting second to finish
    set_task( VOTE_TIME_SEC - 0.1, "voteExpire" );
    set_task( VOTE_TIME_SEC, "vote_display", TASKID_VOTE_DISPLAY, argument, sizeof argument, "a", 3 );

    // set_task( 1.5, "delete_users_menus_care", TASKID_DELETE_USERS_MENUS_CARE );
    set_task( VOTE_TIME_COUNT, "computeVotes", TASKID_VOTE_EXPIRE );
}

public voteExpire()
{
    LOG( 128, "I AM ENTERING ON voteExpire(0)" )
    g_voteStatus |= IS_VOTE_EXPIRED;

    // For the results to show up on the `Voting Results` menu.
    if( !g_showVoteStatusType
        && g_showVoteStatus )
    {
        g_showVoteStatusType = STATUS_TYPE_PERCENTAGE;
    }

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
    LOG( 4, "I AM ENTERING ON vote_display(1)" )
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
    if( updateTimeRemaining ) g_votingSecondsRemaining--;

    LOG( 4, "  ( votedisplay ) player_id: %d", argument[ 1 ]  )
    LOG( 4, "  ( votedisplay ) g_voteStatus: %d", g_voteStatus )
    LOG( 4, "  ( votedisplay ) updateTimeRemaining: %d", argument[ 0 ]  )
    LOG( 4, "  ( votedisplay ) g_totalVoteOptions: %d", g_totalVoteOptions )
    LOG( 4, "  ( votedisplay ) g_votingSecondsRemaining: %d", g_votingSecondsRemaining )
    LOG( 4, "  ( votedisplay ) strlen( g_voteStatusClean ): %d", strlen( g_voteStatusClean )  )

    // wipe the previous vote status
    voteStatus[ 0 ] = '^0';

    // register the 'None' option key
    if( g_isToShowSubMenu || ( g_isToShowNoneOption && !isVoteOver ) ) menuKeys = MENU_KEY_0;

    // add maps to the menu
    for( new choiceIndex = 0; choiceIndex < g_totalVoteOptions; ++choiceIndex )
    {
        menuKeys |= ( 1 << choiceIndex );
        computeMapVotingCount( mapVotingCount, charsmax( mapVotingCount ), choiceIndex );

        copiedChars += formatex( voteStatus[ copiedChars ], charsmax( voteStatus ) - copiedChars,
               "^n%s%d.%s %s\
                %s\
                %s%s",
                COLOR_RED, choiceIndex + 1, COLOR_WHITE, g_votingMapNames[ choiceIndex ],
                g_votingMapInfos[ choiceIndex ][ 0 ] ? " " : "",
                g_votingMapInfos[ choiceIndex ], mapVotingCount );
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

        // skip bots and hltv
        get_players( players, playersCount, "ch" );

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
    LOG( 128, "I AM ENTERING ON dispaly_the_vote_sub_menu(1) player_id: %d", player_id )
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
    LOG( 4, "%48s", " ( dispaly_the_vote_sub_menu| out )" )
}

stock processSubMenuKeyHit( player_id, key )
{
    LOG( 4, "I AM ENTERING ON processSubMenuKeyHit(2) player_id: %d, key: %d", player_id, key )

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
    LOG( 4, "I AM ENTERING ON addExtensionOption(6) player_id: %d", player_id )
    LOG( 4, "( addExtensionOption ) voteStatusLenght: %d, menuKeys: %d, copiedChars: %d", voteStatusLenght, menuKeys, copiedChars )

    new bool:allowStay;
    new bool:allowExtend;

    allowExtend = ( g_isGameFinalVoting
                    && !( g_voteStatus & IS_RUNOFF_VOTE ) );

    allowStay = ( g_isExtendmapAllowStay
                  && !g_isGameFinalVoting
                  && !( g_voteStatus & IS_RUNOFF_VOTE ) );

    // We need to clear the remaining status, otherwise it can show up unwanted.
    // https://forums.alliedmods.net/showthread.php?p=2522088#post2522088
    voteStatus[ copiedChars ] = '^0';

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

    LOG( 4, "( addExtensionOption ) g_isGameFinalVoting:        %d",  g_isGameFinalVoting )
    LOG( 4, "( addExtensionOption ) g_isMapExtensionAllowed:    %d",  g_isMapExtensionAllowed )
    LOG( 4, "( addExtensionOption ) IS_MAP_EXTENSION_ALLOWED(): %d",  IS_MAP_EXTENSION_ALLOWED() )
    LOG( 4, "( addExtensionOption ) allowStay: %d, allowExtend: %d, g_isExtendmapAllowStay: %d", \
            allowStay, allowExtend, g_isExtendmapAllowStay )

    // add optional menu item
    if( ( IS_MAP_EXTENSION_ALLOWED()
          || g_isRunOffNeedingKeepCurrentMap )
        && ( allowExtend
             || allowStay ) )
    {
        new mapVotingCount[ MAX_MAPNAME_LENGHT ];

        // We need to add a new line when `g_isRunOffNeedingKeepCurrentMap` is set to true, because
        // each map menu entry (on this case the extension option) must to start adding a new line.
        new bool:isToAddExtraLine = ( g_totalVoteOptions != 1
                                      || g_isRunOffNeedingKeepCurrentMap );

        // If it's not a runoff vote, add a space between the maps and the additional option.
        // Because it is a run off voting we must to put a space because there are usually only 2
        // items, therefore it would be awkward view/menu.
        if( !( g_voteStatus & IS_RUNOFF_VOTE ) )
        {
            copiedChars += formatex( voteStatus[ copiedChars ], voteStatusLenght - copiedChars, "^n" );
        }

        computeMapVotingCount( mapVotingCount, charsmax( mapVotingCount ), g_totalVoteOptions, isToAddResults );

        // The extension option has priority over the stay here option.
        if( allowExtend )
        {
            LOG( 4, "( addExtensionOption ) g_endVotingType: %d",  g_endVotingType )

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
                   "%s%s%i. \
                    %s%L\
                    %s",
                    isToAddExtraLine ? "^n" : "", COLOR_RED, g_totalVoteOptions + 1,
                    COLOR_WHITE, player_id, extend_option_type, g_currentMapName, extend_step,
                    mapVotingCount );
        }
        else
        {
            LOG( 4, "( addExtensionOption ) g_extendmapAllowStayType: %d",  g_extendmapAllowStayType )

            // add the "Stay Here" menu item
            if( g_extendmapAllowStayType )
            {
                copiedChars += formatex( voteStatus[ copiedChars ], voteStatusLenght - copiedChars,
                       "%s%s%i. \
                        %s%L\
                        %s",
                        isToAddExtraLine ? "^n" : "", COLOR_RED, g_totalVoteOptions + 1,
                        COLOR_WHITE, player_id, "GAL_OPTION_STAY_MAP", g_currentMapName,
                        mapVotingCount );
            }
            else
            {
                copiedChars += formatex( voteStatus[ copiedChars ], voteStatusLenght - copiedChars,
                       "%s%s%i. \
                        %s%L\
                        %s",
                        isToAddExtraLine ? "^n" : "", COLOR_RED, g_totalVoteOptions + 1,
                        COLOR_WHITE, player_id, "GAL_OPTION_STAY",
                        mapVotingCount );
            }
        }

        // When these options are enabled, it is required a new line at this ending for proper spacing.
        if( g_isToShowNoneOption || g_isToShowSubMenu )
        {
            copiedChars += formatex( voteStatus[ copiedChars ], voteStatusLenght - copiedChars, "^n" );
        }

        // Added the extension/stay key option (1 << 2 = key 3, 1 << 3 = key 4, ...)
        menuKeys |= ( 1 << g_totalVoteOptions );
    }

    LOG( 256, "    ( addExtensionOption ) Returning menuKeys: %d", menuKeys )
    return menuKeys;
}

stock display_menu_dirt( player_id, menuKeys, bool:isVoteOver, bool:noneIsHidden, voteStatus[] )
{
    LOG( 256, "I AM ENTERING ON display_menu_dirt(5) player_id: %d", player_id )
    LOG( 256, "( display_menu_dirt ) menuKeys: %d, noneIsHidden: %d, isVoteOver: %d", menuKeys, noneIsHidden, isVoteOver )

    new bool:isToShowUndo;
    new bool:isToAddExtraLine;

    // menu showed after voted
    static menuDirty[ MAX_BIG_BOSS_STRING ];

    static voteFooter[ MAX_SHORT_STRING ];
    static menuHeader[ MAX_SHORT_STRING / 2 ];
    static noneOption[ MAX_SHORT_STRING / 2 ];

    menuDirty  [ 0 ] = '^0';
    noneOption [ 0 ] = '^0';

    isToAddExtraLine = IS_TO_ADD_VOTE_MENU_NEW_LINE();
    isToShowUndo     = IS_TO_ADD_VOTE_MENU_UNDO_BUTTON();

    computeVoteMenuFooter( player_id, voteFooter, charsmax( voteFooter ) );

    // to append it here to always shows it AFTER voting.
    if( isVoteOver )
    {
        // add the header
        formatex( menuHeader, charsmax( menuHeader ), "%s%L",
                COLOR_YELLOW, player_id, "GAL_RESULT" );

        // When these options are enabled, it is required a new line at this ending for proper spacing.
        #define DISPLAY_MENU_ENDED_MESSAGE() \
            ( g_isToShowNoneOption || g_isToShowSubMenu ) ? "" : "^n", COLOR_YELLOW, player_id, "GAL_VOTE_ENDED"

        if( g_isToShowSubMenu )
        {
            formatex( menuDirty, charsmax( menuDirty ),
                   "%s^n%s\
                    %s%s0.%s %L^n^n\
                    %s%s%L",
                    menuHeader, voteStatus,
                    isToAddExtraLine ? "^n" : "", COLOR_RED, COLOR_WHITE, player_id, "CMD_MENU",
                    DISPLAY_MENU_ENDED_MESSAGE() );
        }
        else if( g_isToShowNoneOption
                 && g_voteShowNoneOptionType )
        {
            computeUndoButton( player_id, isToShowUndo, isVoteOver, noneOption, charsmax( noneOption ) );

            formatex( menuDirty, charsmax( menuDirty ),
                   "%s^n%s\
                    %s^n^n\
                    %s%s%L",
                    menuHeader, voteStatus,
                    noneOption,
                    DISPLAY_MENU_ENDED_MESSAGE() );
        }
        else
        {
            formatex( menuDirty, charsmax( menuDirty ),
                   "%s^n%s^n\
                    %s%s%L",
                    menuHeader, voteStatus,
                    DISPLAY_MENU_ENDED_MESSAGE() );
        }
    }
    else
    {
        // add the header
        formatex( menuHeader, charsmax( menuHeader ), "%s%L", COLOR_YELLOW, player_id, "GAL_CHOOSE" );

        if( g_isToShowSubMenu )
        {
            formatex( menuDirty, charsmax( menuDirty ),
                   "%s^n%s\
                    %s%s0.%s %L\
                    %s",
                    menuHeader, voteStatus,
                    isToAddExtraLine ? "^n" : "", COLOR_RED, COLOR_WHITE, player_id, "CMD_MENU",
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
                   "%s^n%s\
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

/**
 * Based on how many seconds are remaining, calculates the vote menu `Time Remaining` seconds. It
 * also displays that the voting has ended when the timer is negative, however this option seems to
 * be deprecated. Therefore the actual `GAL_VOTE_ENDED` is displayed by display_menu_dirt(5).
 */
stock computeVoteMenuFooter( player_id, voteFooter[], voteFooterSize )
{
    LOG( 256, "I AM ENTERING ON computeVoteMenuFooter(3) player_id: %d", player_id )
    LOG( 256, "( computeVoteMenuFooter ) voteFooterSize: %d", voteFooterSize )

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
                formatex( voteFooter, voteFooterSize, "^n^n%s%L: %s%i",
                        COLOR_WHITE, player_id, "GAL_TIMELEFT", COLOR_RED, g_votingSecondsRemaining + 1 );
            }
            else
            {
                formatex( voteFooter, voteFooterSize, "^n^n%s%L", COLOR_YELLOW, player_id, "GAL_VOTE_ENDED" );
            }
        }
    }
}

stock computeUndoButton( player_id, bool:isToShowUndo, bool:isVoteOver, noneOption[], noneOptionSize )
{
    LOG( 256, "I AM ENTERING ON computeUndoButton(5) player_id: %d", player_id )
    new bool:isToAddExtraLine;

    LOG( 256, "( computeUndoButton ) isToShowUndo: %d", isToShowUndo )
    LOG( 256, "( computeUndoButton ) noneOption: %s, noneOptionSize: %d", noneOption, noneOptionSize )

    isToAddExtraLine = IS_TO_ADD_VOTE_MENU_NEW_LINE();

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
    LOG( 256, "I AM ENTERING ON display_menu_clean(2) player_id: %d", player_id )
    LOG( 256, "( display_menu_clean ) menuKeys: %d", menuKeys )

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

    isToAddExtraLine = IS_TO_ADD_VOTE_MENU_NEW_LINE();
    isToShowUndo     = IS_TO_ADD_VOTE_MENU_UNDO_BUTTON();

    computeVoteMenuFooter( player_id, voteFooter, charsmax( voteFooter ) );
    menuKeys = addExtensionOption( player_id, 0, voteExtension, charsmax( voteExtension ), menuKeys, false );

    // Add the header
    formatex( menuHeader, charsmax( menuHeader ), "%s%L", COLOR_YELLOW, player_id, "GAL_CHOOSE" );

    // Append a "None" option on for people to choose if they don't like any other choice to append
    // it here to always shows it WHILE voting.
    if( g_isToShowSubMenu )
    {
        formatex( menuClean, charsmax( menuClean ),
               "%s^n%s\
                %s\
                %s%s0.%s %L\
                %s",
                menuHeader, g_voteStatusClean,
                voteExtension,
                isToAddExtraLine ? "^n" : "", COLOR_RED, COLOR_WHITE, player_id, "CMD_MENU",
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
               "%s^n%s\
                %s\
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
                %s\
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
    LOG( 128, "I AM ENTERING ON display_vote_menu(4) menuType: %d", menuType )

    // Displays only the menu for the player id equals 1, to not pollute the log too much. Only
    // comment the if when you want to be able to see every players menus.
#if defined DEBUG
    if( player_id == 1 )
    {
        LOG( 4, "( display_vote_menu ) player_id: %d", player_id )
        LOG( 4, "( display_vote_menu ) menuBody: %s, menuKeys: %d", menuBody, menuKeys )
    }
#endif

    if( isPlayerAbleToSeeTheVoteMenu( player_id ) )
    {
        show_menu( player_id, menuKeys, menuBody,
                ( menuType ? g_votingSecondsRemaining : max( 2, g_votingSecondsRemaining ) ),
                CHOOSE_MAP_MENU_NAME );
    }
}

stock isPlayerAbleToSeeTheVoteMenu( player_id )
{
    LOG( 128, "I AM ENTERING ON isPlayerAbleToSeeTheVoteMenu(1) player_id: %d", player_id )

    new menu_id;
    new menuKeys_unused;

    get_user_menu( player_id, menu_id, menuKeys_unused );

    return ( menu_id == 0
             || menu_id == g_chooseMapMenuId
             || get_pcvar_num( cvar_isToReplaceByVoteMenu ) != 0 );
}

public vote_handleChoice( player_id, key )
{
    LOG( 128, "I AM ENTERING ON vote_handleChoice(2) player_id: %d, key: %d", player_id, key )

    if( g_voteStatus & IS_VOTE_EXPIRED )
    {
        client_cmd( player_id, "^"slot%i^"", key + 1 );

        LOG( 1, "    ( vote_handleChoice ) Just Returning/blocking, pressing the slot key:", key + 1 )
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
        LOG( 1, "    ( vote_handleChoice ) Just Returning/blocking, seeing the submenu." )
        return;
    }
    else if( g_isPlayerSeeingTheSubMenu[ player_id ] )
    {
        processSubMenuKeyHit( player_id, key );
        LOG( 1, "    ( vote_handleChoice ) Just Returning/blocking, submenu command selected." )
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
        LOG( 1, "( vote_handleChoice ) Pressing the slot key: %d", key + 1 )
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

    LOG( 1, "    I AM EXITING vote_handleChoice(2)..." )
    LOG( 1, "" )
}

stock reshowTheVoteMenu( player_id )
{
    LOG( 128, "I AM ENTERING ON reshowTheVoteMenu(1) player_id: %d", player_id )
    new argument[ 2 ];

    argument[ 0 ] = false;
    argument[ 1 ] = player_id;

    set_task( 0.1, "vote_display", TASKID_VOTE_DISPLAY, argument, sizeof argument );
}

stock cancel_player_vote( player_id )
{
    LOG( 128, "I AM ENTERING ON cancel_player_vote(1) player_id: %d", player_id )
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
    LOG( 128, "I AM ENTERING ON register_vote(2) player_id: %d, pressedKeyCode: %d", player_id, pressedKeyCode )

    announceRegistedVote( player_id, pressedKeyCode );
    g_isPlayerVoted[ player_id ] = true;

    if( pressedKeyCode == 9 )
    {
        g_playerVotedWeight[ player_id ]     = 0;     // the None option has no weight
        g_playerVotedOption[ player_id ]     = 0;     // the None option does not integrate vote counting
        g_isPlayerParticipating[ player_id ] = false; // if is not interested now, at runoff wont also
    }
    else
    {
        g_playerVotedWeight[ player_id ]     = 1;
        g_playerVotedOption[ player_id ]     = pressedKeyCode;
        g_isPlayerParticipating[ player_id ] = true;
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

            color_chat( player_id, "%L", player_id, "GAL_VOTE_WEIGHTED", voteWeight );
        }
        else
        {
            g_arrayOfMapsWithVotesNumber[ pressedKeyCode ]++;
        }
    }
}

stock announceRegistedVote( player_id, pressedKeyCode )
{
    LOG( 128, "I AM ENTERING ON announceRegistedVote(2) player_id: %d, pressedKeyCode: %d", player_id, pressedKeyCode )

    new player_name[ MAX_PLAYER_NAME_LENGHT ];
    new bool:isToAnnounceChoice = get_pcvar_num( cvar_voteAnnounceChoice ) != 0;

    if( isToAnnounceChoice )
    {
        GET_USER_NAME( player_id, player_name )
    }

    // confirm the player's choice (pressedKeyCode = 9 means 0 on the keyboard, 8 is 7, etc)
    if( pressedKeyCode == 9 )
    {
        LOG( 4, "      %-32s ( none )", player_name )

        if( isToAnnounceChoice )
        {
            color_chat( 0, "%L", LANG_PLAYER, "GAL_CHOICE_NONE_ALL", player_name );
        }
        else
        {
            color_chat( player_id, "%L", player_id, "GAL_CHOICE_NONE" );
        }
    }
    else if( pressedKeyCode == g_totalVoteOptions )
    {
        // only display the "none" vote if we haven't already voted
        // ( we can make it here from the vote status menu too )
        if( !g_isPlayerVoted[ player_id ] )
        {
            LOG( 4, "      %-32s ( extend )", player_name )

            if( g_isGameFinalVoting )
            {
                if( isToAnnounceChoice )
                {
                    color_chat( 0, "%L", LANG_PLAYER, "GAL_CHOICE_EXTEND_ALL", player_name );
                }
                else
                {
                    color_chat( player_id, "%L", player_id, "GAL_CHOICE_EXTEND" );
                }
            }
            else
            {
                if( isToAnnounceChoice )
                {
                    color_chat( 0, "%L", LANG_PLAYER, "GAL_CHOICE_STAY_ALL", player_name );
                }
                else
                {
                    color_chat( player_id, "%L", player_id, "GAL_CHOICE_STAY" );
                }
            }
        }
    }
    else
    {
        LOG( 4, "      %-32s %s", player_name, g_votingMapNames[ pressedKeyCode ] )

        if( isToAnnounceChoice )
        {
            color_chat(0, "%L", LANG_PLAYER, "GAL_CHOICE_MAP_ALL", \
                    player_name, g_votingMapNames[ pressedKeyCode ] );
        }
        else
        {
            color_chat( player_id, "%L", player_id, "GAL_CHOICE_MAP", \
                    g_votingMapNames[ pressedKeyCode ] );
        }
    }
}

stock computeMapVotingCount( mapVotingCount[], mapVotingCountLength, voteIndex, bool:isToAddResults = true )
{
    LOG( 256, "I AM ENTERING ON computeMapVotingCount(3) mapVotingCount: %s, mapVotingCountLength: %d, \
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

    LOG( 256, " ( computeMapVotingCount ) g_showVoteStatus: %d, g_showVoteStatusType: %d, voteCountNumber: %d", \
            g_showVoteStatus, g_showVoteStatusType, voteCountNumber )
}

stock showPlayersVoteResult()
{
    LOG( 128, "I AM ENTERING ON showPlayersVoteResult(0)" )
    new mapVotingCount[ 32 ];

    LOG( 4, "" )
    LOG( 4, "   [VOTE RESULT]" )

    for( new playerVoteMapChoiceIndex = 0; playerVoteMapChoiceIndex <= g_totalVoteOptions;
         ++playerVoteMapChoiceIndex )
    {
        computeMapVotingCount( mapVotingCount, charsmax( mapVotingCount ), playerVoteMapChoiceIndex );

        LOG( 4, "      %2i/%-2i, %i. %s %s", \
                g_arrayOfMapsWithVotesNumber[ playerVoteMapChoiceIndex ], g_totalVotesCounted, \
                playerVoteMapChoiceIndex, g_votingMapNames[ playerVoteMapChoiceIndex ], \
                g_votingMapInfos[ playerVoteMapChoiceIndex ] )
    }

    LOG( 4, "" )
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
    LOG( 128, "I AM ENTERING ON getUniqueRandomInteger(2) range: %d-%d", minimum, maximum )
    static lastMaximum = MIN_INTEGER;

    new randomIndex;
    new returnValue;
    new holderSize = ArraySize( holder );

    if( lastMaximum != maximum
        || ( restart
             && holderSize < 1 ) )
    {
        LOG( 1, "( getUniqueRandomInteger ) Reseting the sequence, ArraySize: %d", holderSize )

        lastMaximum = maximum;
        TRY_TO_APPLY( ArrayClear, holder )

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

    LOG( 1, "( getUniqueRandomInteger ) ArraySize: %d", ArraySize( holder ) )
    --holderSize;

    // Get a unique random value
    randomIndex = random_num( 0, holderSize );
    returnValue = ArrayGetCell( holder, randomIndex );

    // Swap the random value from the middle of the array to the last position, reduces the removal
    // complexity from linear `O( n )` to constant `O( 1 )`.
    ArraySwap( holder, randomIndex, holderSize );
    ArrayDeleteItem( holder, holderSize );

    LOG( 1, "    ( getUniqueRandomInteger ) %d. Just Returning the random integer: %d", holderSize, returnValue )
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
    LOG( 128, "I AM ENTERING ON getUniqueRandomIntegerBasic(2) maximum: %d", maximum )
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

            LOG( 1, "    ( getUniqueRandomIntegerBasic ) %d. Just Returning the random integer: %d", sequence, randomInteger )
            return randomInteger;
        }
    }

    LOG( 1, "    ( getUniqueRandomIntegerBasic ) %d. Just Returning the random integer: %d", sequence, -1 )
    return -1;
}

stock printIntegerArray( level, integerArray[], arrayName[], integerArraySize )
{
    LOG( 128, "I AM ENTERING ON printIntegerArray(4) integerArraySize: %d", integerArraySize )

    for( new index = 0; index < integerArraySize; index++ )
    {
        LOG( level, "( printIntegerArray ) %s: %d", arrayName, integerArray[ index ] )
    }

    return 0;
}

stock printRunOffMaps( runOffMapsCount )
{
    LOG( 128, "I AM ENTERING ON printRunOffMaps(1) runOffMapsCount: %d", runOffMapsCount )

    for( new index = 0; index < runOffMapsCount; index++ )
    {
        LOG( 16, "( printRunOffMaps ) RunOff map %d: %s", index, g_votingMapNames[ g_arrayOfRunOffChoices[ index ] ] )
    }

    return 0;
}

/**
 * This case is triggered when there are more than 1 map at the first position.
 *
 * It also implements the feature on: https://github.com/addonszz/Galileo/issues/33, for the cvar
 * `cvar_runoffMapchoices` on this case.
 */
stock handleMoreThanTwoMapsAtFirst( firstPlaceChoices[], numberOfMapsAtFirstPosition )
{
    LOG( 128, "I AM ENTERING ON handleMoreThanTwoMapsAtFirst(2)" )
    LOG( 0, "", printIntegerArray( 16, firstPlaceChoices, "firstPlaceChoices", numberOfMapsAtFirstPosition ) )

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

    LOG( 16, "( handleMoreThanTwoMapsAtFirst ) Number of Maps at First Position > 2" )
    LOG( 0, "", printRunOffMaps( g_totalVoteOptions ) )

    color_chat( 0, "%L", LANG_PLAYER, "GAL_RESULT_TIED1", numberOfMapsAtFirstPosition );
}

stock configureTheRunoffVoting( firstPlaceChoices[], secondPlaceChoices[], numberOfMapsAtFirstPosition,
                         numberOfMapsAtSecondPosition )
{
    LOG( 128, "I AM ENTERING ON configureTheRunoffVoting(4)" )
    new votePercent = floatround( 100 * get_pcvar_float( cvar_runoffRatio ), floatround_ceil );

    // announce runoff voting requirement
    color_chat( 0, "%L", LANG_PLAYER, "GAL_RUNOFF_REQUIRED", votePercent );

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

    // start the runoff vote
    set_task( VOTE_TIME_RUNOFF, "startTheRunoffVoting", TASKID_START_THE_VOTING );
}

/**
 * This case is triggered when there are 2 map at the first position.
 */
stock handleTwoMapsAtFirstPosition( firstPlaceChoices[] )
{
    LOG( 128, "I AM ENTERING ON handleTwoMapsAtFirstPosition(1)" )

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

    LOG( 16, "( handleTwoMapsAtFirstPosition ) Number of Maps at First Position == 2" )
    LOG( 0, "", printRunOffMaps( g_totalVoteOptions ) )
}

/**
 * This case is triggered when there is 1 map at the first and another on the second position.
 */
stock handleOneMapAtSecondPosition( firstPlaceChoices[], secondPlaceChoices[] )
{
    LOG( 128, "I AM ENTERING ON handleOneMapAtSecondPosition(2)" )

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

    LOG( 16, "( handleOneMapAtSecondPosition ) Number of Maps at Second Position == 1" )
    LOG( 0, "", printRunOffMaps( g_totalVoteOptions ) )
}

/**
 * This case is triggered when there are 1 map at the first position, but several on the second
 * position.
 */
stock handleOneMapAtFirstPosition( firstPlaceChoices[], secondPlaceChoices[], numberOfMapsAtSecondPosition )
{
    LOG( 128, "I AM ENTERING ON handleOneMapAtFirstPosition(3)" )
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

    LOG( 16, "( handleOneMapAtFirstPosition ) Number of Maps at First Position == 1 && At Second Position > 1" )
    LOG( 0, "", printRunOffMaps( g_totalVoteOptions ) )

    color_chat( 0, "%L", LANG_PLAYER, "GAL_RESULT_TIED2", numberOfMapsAtSecondPosition );
}

stock determineTheVotingFirstChoices( firstPlaceChoices[], secondPlaceChoices[],
                                      &numberOfMapsAtFirstPosition, &numberOfMapsAtSecondPosition )
{
    LOG( 128, "I AM ENTERING ON determineTheVotingFirstChoices(4)" )

    new numberOfVotesAtFirstPlace;
    new numberOfVotesAtSecondPlace;

    new playerVoteMapChoiceIndex;
    new bool:isRunoffVoting = ( g_voteStatus & IS_RUNOFF_VOTE ) != 0;

    // Determine how much maps it should look up to, considering whether there is the option
    // `Stay Here` or `Extend` displayed on the voting menu.
    new maxVotingChoices = g_totalVoteOptions >= MAX_OPTIONS_IN_VOTE ? g_totalVoteOptions :
            ( IS_MAP_EXTENSION_ALLOWED() && !isRunoffVoting ? ( g_totalVoteOptions + 1 ) :
                ( g_isRunOffNeedingKeepCurrentMap           ? ( g_totalVoteOptions + 1 ) : g_totalVoteOptions ) );

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
        LOG( 16, "Inside the for to determine which maps are in 1st and 2nd places, \
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
    LOG( 16, "After for to determine which maps are in 1st and 2nd places." )
    LOG( 16, "" )
    LOG( 16, "maxVotingChoices: %d, isRunoffVoting: %d", maxVotingChoices, isRunoffVoting )
    LOG( 16, "g_totalVoteOptions: %d", g_totalVoteOptions )
    LOG( 16, "" )
    LOG( 16, "numberOfVotesAtFirstPlace: %d", numberOfVotesAtFirstPlace )
    LOG( 16, "numberOfVotesAtSecondPlace: %d", numberOfVotesAtSecondPlace )
    LOG( 16, "" )
    LOG( 16, "numberOfMapsAtFirstPosition: %d", numberOfMapsAtFirstPosition )
    LOG( 16, "numberOfMapsAtSecondPosition: %d", numberOfMapsAtSecondPosition )
    LOG( 16, "" )
    LOG( 1, "( determineTheVotingFirstChoices ) g_isTheLastGameRound: %d", g_isTheLastGameRound )
    LOG( 1, "( determineTheVotingFirstChoices ) g_isTimeToRestart: %d", g_isTimeToRestart )
    LOG( 1, "( determineTheVotingFirstChoices ) g_voteStatus & IS_FORCED_VOTE: %d", g_voteStatus & IS_FORCED_VOTE != 0 )

    return numberOfVotesAtFirstPlace;
}

public computeVotes()
{
    LOG( 128, "I AM ENTERING ON computeVotes(0)" )
    LOG( 0, "", showPlayersVoteResult() )

    new runoffEnabled;
    new numberOfVotesAtFirstPlace;

    // retain the number of draw maps at first and second positions
    new numberOfMapsAtFirstPosition;
    new numberOfMapsAtSecondPosition;

    new firstPlaceChoices [ MAX_OPTIONS_IN_VOTE ];
    new secondPlaceChoices[ MAX_OPTIONS_IN_VOTE ];

    runoffEnabled = get_pcvar_num( cvar_runoffEnabled );

    numberOfVotesAtFirstPlace = determineTheVotingFirstChoices( firstPlaceChoices,
            secondPlaceChoices, numberOfMapsAtFirstPosition, numberOfMapsAtSecondPosition );

    LOG( 1, "( computeVotes ) cvar_voteMinimun:    %d", get_pcvar_num( cvar_voteMinimun ) )
    LOG( 1, "( computeVotes ) g_totalVotesCounted: %d", g_totalVotesCounted )

    // announce the outcome
    if( numberOfVotesAtFirstPlace
        && g_totalVotesCounted > get_pcvar_num( cvar_voteMinimun ) )
    {
        LOG( 1, "( computeVotes ) On if(numberOfVotesAtFirstPlace)" )

        // if the top vote getting map didn't receive over 50% of the votes cast, to start a runoff vote
        if( numberOfVotesAtFirstPlace <= g_totalVotesCounted * get_pcvar_float( cvar_runoffRatio ) )
        {
            LOG( 1, "( computeVotes ) On cvar_runoffRatio" )

            if( runoffEnabled == RUNOFF_ENABLED
                && !( g_voteStatus & IS_RUNOFF_VOTE )
                && !( g_voteMapStatus & IS_DISABLED_VOTEMAP_RUNOFF ) )
            {
                configureTheRunoffVoting( firstPlaceChoices, secondPlaceChoices, numberOfMapsAtFirstPosition,
                        numberOfMapsAtSecondPosition );

                LOG( 1, "    ( computeVotes ) Just Returning/blocking, its runoff starting." )
                return;
            }
            else if( runoffEnabled == RUNOFF_EXTEND
                     && IS_MAP_EXTENSION_ALLOWED() )
            {
                performRunoffExtending();
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

    LOG( 1, "    ( computeVotes|out ) g_isTheLastGameRound: %d", g_isTheLastGameRound )
    LOG( 1, "    ( computeVotes|out ) g_isTimeToRestart: %d, g_voteStatus & IS_FORCED_VOTE: %d", \
            g_isTimeToRestart, g_voteStatus & IS_FORCED_VOTE != 0 )

    finalizeVoting();
}

/**
 * Allow it only on a end map voting.
 */
stock performRunoffExtending()
{
    LOG( 128, "I AM ENTERING ON performRunoffExtending(0)" )

    if( g_isGameFinalVoting )
    {
        map_extend( "GAL_RUNOFF_REQUIRED_TOP" );
    }
    else
    {
        stayHereWon( "GAL_RUNOFF_REQUIRED_TOP" );
    }
}

stock stayHereWon( const reason[] )
{
    LOG( 128, "I AM ENTERING ON stayHereWon(0)" )

    color_chat( 0, "%L: %L", LANG_PLAYER, reason, LANG_PLAYER, "GAL_WINNER_STAY2" );
    toShowTheMapStayHud( "GAL_VOTE_ENDED", reason, "GAL_WINNER_STAY1" );

    // However here, none decisions are being made. Anyways, we cannot block the execution
    // right here without executing the remaining code.
    noLongerIsAnEarlyVoting();
}

stock chooseTheVotingMapWinner( firstPlaceChoices[], numberOfMapsAtFirstPosition )
{
    LOG( 128, "I AM ENTERING ON chooseTheVotingMapWinner(2)" )
    new winnerVoteMapIndex;

    // If there is a tie for 1st, randomly select one as the winner
    if( numberOfMapsAtFirstPosition > 1 )
    {
        // This message and others like it, does not need a HUD because they are not the last ones
        // to be displayed, i.e., soon a new ending message within a HUD will be show.
        winnerVoteMapIndex = firstPlaceChoices[ random_num( 0, numberOfMapsAtFirstPosition - 1 ) ];
        color_chat( 0, "%L", LANG_PLAYER, "GAL_WINNER_TIED", numberOfMapsAtFirstPosition );
    }
    else
    {
        winnerVoteMapIndex = firstPlaceChoices[ 0 ];
    }

    LOG( 1, "    ( chooseTheVotingMapWinner ) g_isTheLastGameRound: %d ", g_isTheLastGameRound )
    LOG( 1, "    ( chooseTheVotingMapWinner ) g_isTimeToRestart: %d, g_voteStatus & IS_FORCED_VOTE: %d", \
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
                LOG( 1, "    ( chooseTheVotingMapWinner ) Just opened the menu due g_voteMapStatus: %d", g_voteMapStatus )
            }

            stayHereWon( "DMAP_MAP_EXTENDED1" );
        }
        else if( !g_isGameFinalVoting // "stay here" won and the map must be restarted.
                 && g_isTimeToRestart )
        {
            // This message does not need HUD's because immediately the map will be changed immediately.
            color_chat( 0, "%L", LANG_PLAYER, "GAL_WINNER_STAY2" );

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

        // When it is a `gal_votemap` we need to print its map winner, instead of the `g_nextMapName`.
        if( g_invokerVoteMapNameToDecide[ 0 ] )
        {
            color_chat( 0, "%L: %L", LANG_PLAYER, "DMAP_MAP_EXTENDED1", LANG_PLAYER, "GAL_NEXTMAP2", g_invokerVoteMapNameToDecide );
            toShowTheMapNextHud( "GAL_VOTE_ENDED", "DMAP_MAP_EXTENDED1", "GAL_NEXTMAP1", g_invokerVoteMapNameToDecide );
        }
        else
        {
            color_chat( 0, "%L: %L", LANG_PLAYER, "DMAP_MAP_EXTENDED1", LANG_PLAYER, "GAL_NEXTMAP2", g_nextMapName );
            toShowTheMapNextHud( "GAL_VOTE_ENDED", "DMAP_MAP_EXTENDED1", "GAL_NEXTMAP1", g_nextMapName );
        }

        process_last_round( g_isToChangeMapOnVotingEnd );
    }
}

stock noLongerIsAnEarlyVoting()
{
    LOG( 128, "I AM ENTERING ON noLongerIsAnEarlyVoting(0)" )

    // We are extending the map as result of the voting outcome, so reset the ending round variables.
    resetRoundEnding();

    // No longer is an early or forced voting
    g_voteStatus &= ~IS_EARLY_VOTE;
    g_voteStatus &= ~IS_FORCED_VOTE;
}

stock chooseRandomVotingWinner()
{
    LOG( 128, "I AM ENTERING ON chooseRandomVotingWinner(1) isExtendmapOrderAllowed: %d", get_pcvar_num( cvar_isExtendmapOrderAllowed ) )

    switch( get_pcvar_num( cvar_isExtendmapOrderAllowed ) )
    {
        // 1 - follow your current map-cycle order
        case 1:
        {
            g_voteStatus |= IS_VOTE_OVER;

            color_chat( 0, "%L. %L", LANG_PLAYER, "GAL_WINNER_NO_ONE_VOTED", LANG_PLAYER, "GAL_WINNER_ORDERED2", g_nextMapName );
            toShowTheMapNextHud( "GAL_WINNER_NO_ONE_VOTED", "DMAP_MAP_EXTENDED1", "GAL_WINNER_ORDERED1", g_nextMapName );

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

            color_chat( 0, "%L. %L", LANG_PLAYER, "GAL_WINNER_NO_ONE_VOTED", LANG_PLAYER, "GAL_WINNER_RANDOM2", g_nextMapName );
            toShowTheMapNextHud( "GAL_WINNER_NO_ONE_VOTED", "DMAP_MAP_EXTENDED1", "GAL_WINNER_RANDOM1", g_nextMapName );

            process_last_round( g_isToChangeMapOnVotingEnd );
        }
    }
}

stock resetVoteTypeGlobals()
{
    LOG( 128, "I AM ENTERING ON resetVoteTypeGlobals(0)" )

    g_endVotingType                 = 0;
    g_isRunOffNeedingKeepCurrentMap = false;
}

/**
 * Restore global variables to is default state. This is to be ready for a new voting.
 */
stock finalizeVoting()
{
    LOG( 128, "I AM ENTERING ON finalizeVoting(0)" )

    // As the voting has ended, reset the voting ending type.
    resetVoteTypeGlobals();

    // We cannot or need not the saved context anymore, as it is only used to start/setup the voting.
    g_isGameEndingTypeContextSaved = false;

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
    LOG( 128, "I AM ENTERING ON Float:map_getMinutesElapsed(0) mp_timelimit: %f", get_pcvar_float( cvar_mp_timelimit ) )
    return get_pcvar_float( cvar_mp_timelimit ) - ( float( get_timeleft() ) / 60.0 );
}

stock map_getMinutesElapsedInteger()
{
    LOG( 128, "I AM ENTERING ON Float:map_getMinutesElapsed(0) mp_timelimit: %f", get_pcvar_float( cvar_mp_timelimit ) )

    // While the Unit Tests are running, to force a specific time.
#if ARE_WE_RUNNING_UNIT_TESTS
    if( g_test_areTheUnitTestsRunning )
    {
        return g_test_gameElapsedTime;
    }
#endif
    return get_pcvar_num( cvar_mp_timelimit ) - ( get_timeleft() / 60 );
}

stock toAnnounceTheMapExtension( const lang[] )
{
    LOG( 128, "I AM ENTERING ON toAnnounceTheMapExtension(1) lang: %s", lang )

    if( g_endVotingType & ( IS_BY_ROUNDS | IS_BY_WINLIMIT ) )
    {
        color_chat( 0, "%L %L", LANG_PLAYER, lang, LANG_PLAYER, "GAL_WINNER_EXTEND_ROUND2", g_extendmapStepRounds );
        toShowTheMapExtensionHud( lang, "DMAP_MAP_EXTENDED1", "GAL_WINNER_EXTEND_ROUND1", g_extendmapStepRounds );
    }
    else if( g_endVotingType & IS_BY_FRAGS )
    {
        color_chat( 0, "%L %L", LANG_PLAYER, lang, LANG_PLAYER, "GAL_WINNER_EXTEND_FRAGS2", g_extendmapStepFrags );
        toShowTheMapExtensionHud( lang, "DMAP_MAP_EXTENDED1", "GAL_WINNER_EXTEND_FRAGS1", g_extendmapStepFrags );
    }
    else
    {
        color_chat( 0, "%L %L", LANG_PLAYER, lang, LANG_PLAYER, "GAL_WINNER_EXTEND2", g_extendmapStepMinutes );
        toShowTheMapExtensionHud( lang, "DMAP_MAP_EXTENDED1", "GAL_WINNER_EXTEND1", g_extendmapStepMinutes );
    }
}

stock toShowTheMapExtensionHud( const lang1[], const lang2[], const lang3[], extend_step )
{
    LOG( 128, "I AM ENTERING ON toShowTheMapExtensionHud(4) lang2: %s, lang3: %s, extend_step: %d", lang2, lang3, extend_step )

    if( !( get_pcvar_num( cvar_hudsHide ) & HUD_VOTE_RESULTS_ANNOUNCE ) )
    {
        set_hudmessage( 150, 120, 0, -1.0, 0.13, 0, 1.0, 6.94, 0.0, 0.0, -1 );

        // If our lang is `GAL_RUNOFF_REQUIRED_TOP`, we cannot include the lang `DMAP_MAP_EXTENDED1`
        // otherwise the message will be too big and will break a line which should not.
        if( equali( lang1, "GAL_RUNOFF_REQUIRED_TOP" ) )
        {
            show_hudmessage( 0, "%L:^n%L", LANG_PLAYER, lang1, LANG_PLAYER, lang3, extend_step );
        }
        else
        {
            show_hudmessage( 0, "%L. %L:^n%L", LANG_PLAYER, lang1, LANG_PLAYER, lang2, LANG_PLAYER, lang3, extend_step );
        }
    }
}

stock toShowTheMapStayHud( const lang1[], const lang2[], const lang3[] )
{
    LOG( 128, "I AM ENTERING ON toShowTheMapStayHud(3) lang1: %s, lang2: %s, lang3: %s", lang1, lang2, lang3 )

    if( !( get_pcvar_num( cvar_hudsHide ) & HUD_VOTE_RESULTS_ANNOUNCE ) )
    {
        set_hudmessage( 150, 120, 0, -1.0, 0.13, 0, 1.0, 6.94, 0.0, 0.0, -1 );

        // If our lang is `GAL_RUNOFF_REQUIRED_TOP`, we cannot include the lang `DMAP_MAP_EXTENDED1`
        // otherwise the message will be too big and will break a line which should not.
        if( equali( lang2, "GAL_RUNOFF_REQUIRED_TOP" ) )
        {
            show_hudmessage( 0, "%L:^n%L", LANG_PLAYER, lang2, LANG_PLAYER, lang3 );
        }
        else
        {
            show_hudmessage( 0, "%L. %L:^n%L", LANG_PLAYER, lang1, LANG_PLAYER, lang2, LANG_PLAYER, lang3 );
        }
    }
}

stock toShowTheMapNextHud( const lang1[], const lang2[], const lang3[], map[] )
{
    LOG( 128, "I AM ENTERING ON toShowTheMapNextHud(4) lang1: %s, lang2: %s, lang3: %s", lang1, lang2, lang3 )

    // The end of map count countdown will immediately start, so there is not point int showing any messages.
    if( !g_isToChangeMapOnVotingEnd
        && !( get_pcvar_num( cvar_hudsHide ) & HUD_VOTE_RESULTS_ANNOUNCE ) )
    {
        set_hudmessage( 150, 120, 0, -1.0, 0.13, 0, 1.0, 6.94, 0.0, 0.0, -1 );
        show_hudmessage( 0, "%L. %L:^n%L", LANG_PLAYER, lang1, LANG_PLAYER, lang2, LANG_PLAYER, lang3, map );
    }
}

stock map_extend( const lang[] )
{
    LOG( 128, "I AM ENTERING ON map_extend(1)" )
    LOG( 2, "%32s g_rtvWaitMinutes: %f, g_extendmapStepMinutes: %d", "map_extend( in )", g_rtvWaitMinutes, g_extendmapStepMinutes )

    // While the `IS_DISABLED_VOTEMAP_EXIT` bit flag is set, we cannot allow any decisions.
    if( g_voteMapStatus & IS_DISABLED_VOTEMAP_EXIT )
    {
        color_chat( 0, "%L: %L", LANG_PLAYER, "DMAP_MAP_EXTENDED1", LANG_PLAYER, "GAL_WINNER_STAY2" );
        toShowTheMapExtensionHud( "GAL_VOTE_ENDED", "DMAP_MAP_EXTENDED1", "GAL_WINNER_STAY1", 0 );

        // When the map extension is called, there is anyone else trying to show action menu,
        // therefore invoke it before returning.
        openTheVoteMapActionMenu();

        LOG( 1, "    ( map_extend ) Just returning/blocking, g_voteMapStatus: %d", g_voteMapStatus )
        return;
    }

    LOG( 2, "( map_extend ) TRYING to change the cvar %15s from '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOG( 2, "( map_extend ) TRYING to change the cvar %15s from '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOG( 2, "( map_extend ) TRYING to change the cvar %15s from '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOG( 2, "( map_extend ) TRYING to change the cvar %15s from '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )

    saveEndGameLimits();
    resetTheRtvWaitTime();
    doTheActualMapExtension();

    // Remove the fail safe, as we are extending the map. The fail safe could be running if the
    // `cvar_endOfMapVoteStart` failed to predict the correct last round to start voting, the voting
    // could have been started on the map_manageEnd(0) function. Then the fail safe will be running,
    // but if the map extension was the voting winner option, then we must to disable the fail safe
    // as we do not need it anymore.
    remove_task( TASKID_PREVENT_INFITY_GAME );
    remove_task( TASKID_SHOW_LAST_ROUND_HUD );

    blockNewVotingToStart();
    toAnnounceTheMapExtension( lang );
    noLongerIsAnEarlyVoting();

    LOG( 2, "    ( map_extend ) CHECKOUT the cvar %19s is '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOG( 2, "    ( map_extend ) CHECKOUT the cvar %19s is '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOG( 2, "    ( map_extend ) CHECKOUT the cvar %19s is '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOG( 2, "    ( map_extend ) CHECKOUT the cvar %19s is '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )
    LOG( 2, "%32s g_rtvWaitMinutes: %f, g_extendmapStepMinutes: %d", "map_extend( out )", g_rtvWaitMinutes, g_extendmapStepMinutes )
}

/**
 * There are several folks trying to start the voting, but they are blocked when the voting status is
 * set as over, however when the extension option wins, the vote status is not set as over to allow a
 * new voting when the extension time to expires.
 *
 * To fix the voting starting right again after the map extension, blocking it by 2 minutes should be
 * big enough to not block the new voting after the map extension time expires.
 */
stock blockNewVotingToStart()
{
    LOG( 128, "I AM ENTERING ON blockNewVotingToStart(0)" )

    g_isMapExtensionPeriodRunning = true;
    set_task( 120.0, "unblockNewVotingToStart", TASKID_BLOCK_NEW_VOTING_START );
}

public unblockNewVotingToStart()
{
    LOG( 128, "I AM ENTERING ON unblockNewVotingToStart(0)" )
    g_isMapExtensionPeriodRunning = false;
}

/**
 * Reset the "rtv wait" time, taking into consideration the map extension.
 *
 * This must to be called before the doTheActualMapExtension(0)!
 */
stock resetTheRtvWaitTime()
{
    LOG( 128, "I AM ENTERING ON resetTheRtvWaitTime(0)" )
    LOG( 2, "( resetTheRtvWaitTime ) g_rtvWaitFrags:   %d", g_rtvWaitFrags )
    LOG( 2, "( resetTheRtvWaitTime ) g_rtvWaitRounds:  %d", g_rtvWaitRounds )
    LOG( 2, "( resetTheRtvWaitTime ) g_rtvWaitMinutes: %f", g_rtvWaitMinutes )

    if( !( g_rtvCommands & RTV_CMD_EXTENSION_WAIT_DISABLE ) )
    {
        if( g_rtvWaitMinutes )
        {
            g_rtvWaitMinutes += GAME_ENDING_CONTEXT_SAVED( g_timeLimitContextSaved, get_pcvar_float( cvar_mp_timelimit ) );
        }

        if( g_rtvWaitRounds )
        {
            new cache = GAME_ENDING_CONTEXT_SAVED( g_maxRoundsContextSaved, get_pcvar_num( cvar_mp_maxrounds ) );

            if( cache )
            {
                g_rtvWaitRounds += cache;
            }
            else if( ( cache = GAME_ENDING_CONTEXT_SAVED( g_winLimitContextSaved, get_pcvar_num( cvar_mp_winlimit ) ) ) )
            {
                g_rtvWaitRounds += cache;
            }
        }

        if( g_rtvWaitFrags )
        {
            g_rtvWaitFrags += GAME_ENDING_CONTEXT_SAVED( g_fragLimitContextSaved, get_pcvar_num( cvar_mp_fraglimit ) );
        }
    }

    LOG( 2, "( resetTheRtvWaitTime ) g_rtvWaitFrags:   %d", g_rtvWaitFrags )
    LOG( 2, "( resetTheRtvWaitTime ) g_rtvWaitRounds:  %d", g_rtvWaitRounds )
    LOG( 2, "( resetTheRtvWaitTime ) g_rtvWaitMinutes: %f", g_rtvWaitMinutes )
}

stock doTheActualMapExtension()
{
    LOG( 128, "I AM ENTERING ON doTheActualMapExtension(0)" )

    // Stop the map changing on a forced voting.
    g_isToChangeMapOnVotingEnd = false;

    if( g_endVotingType & IS_BY_ROUNDS )
    {
        new total = GAME_ENDING_CONTEXT_SAVED( g_maxRoundsContextSaved, get_pcvar_num( cvar_mp_maxrounds ) );

        tryToSetGameModCvarNum(   cvar_mp_maxrounds, total + g_extendmapStepRounds );
        tryToSetGameModCvarNum(   cvar_mp_winlimit , 0 );
        tryToSetGameModCvarNum(   cvar_mp_fraglimit, 0 );
        tryToSetGameModCvarFloat( cvar_mp_timelimit, 0.0 );
    }
    else if( g_endVotingType & IS_BY_WINLIMIT )
    {
        new total = GAME_ENDING_CONTEXT_SAVED( g_winLimitContextSaved, get_pcvar_num( cvar_mp_winlimit ) );

        tryToSetGameModCvarNum(   cvar_mp_maxrounds, 0  );
        tryToSetGameModCvarNum(   cvar_mp_winlimit , total + g_extendmapStepRounds );
        tryToSetGameModCvarNum(   cvar_mp_fraglimit, 0 );
        tryToSetGameModCvarFloat( cvar_mp_timelimit, 0.0 );
    }
    else if( g_endVotingType & IS_BY_FRAGS )
    {
        new total = GAME_ENDING_CONTEXT_SAVED( g_fragLimitContextSaved, get_pcvar_num( cvar_mp_fraglimit ) );

        tryToSetGameModCvarNum(   cvar_mp_maxrounds, 0   );
        tryToSetGameModCvarNum(   cvar_mp_winlimit , 0   );
        tryToSetGameModCvarNum(   cvar_mp_fraglimit, total + g_extendmapStepFrags );
        tryToSetGameModCvarFloat( cvar_mp_timelimit, 0.0 );
    }
    else
    {
        new Float:total = GAME_ENDING_CONTEXT_SAVED( g_timeLimitContextSaved, get_pcvar_float( cvar_mp_timelimit ) );

        tryToSetGameModCvarNum(   cvar_mp_maxrounds, 0 );
        tryToSetGameModCvarNum(   cvar_mp_winlimit , 0 );
        tryToSetGameModCvarNum(   cvar_mp_fraglimit, 0 );
        tryToSetGameModCvarFloat( cvar_mp_timelimit, total + g_extendmapStepMinutes );
    }
}

stock saveEndGameLimits()
{
    LOG( 128, "I AM ENTERING ON saveEndGameLimits(0)" )

    if( !g_isEndGameLimitsChanged )
    {
        g_isEndGameLimitsChanged = true;

        g_originalTimelimit = get_pcvar_float( cvar_mp_timelimit );
        g_originalMaxRounds = get_pcvar_num(   cvar_mp_maxrounds );
        g_originalWinLimit  = get_pcvar_num(   cvar_mp_winlimit  );
        g_originalFragLimit = get_pcvar_num(   cvar_mp_fraglimit );

        LOG( 2, "( saveEndGameLimits ) SAVING the cvar %15s to '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
        LOG( 2, "( saveEndGameLimits ) SAVING the cvar %15s to '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
        LOG( 2, "( saveEndGameLimits ) SAVING the cvar %15s to '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
        LOG( 2, "( saveEndGameLimits ) SAVING the cvar %15s to '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )
    }
}

public map_restoreEndGameCvars()
{
    LOG( 128 + 2, "I AM ENTERING ON map_restoreEndGameCvars(0)" )

    restoreTheChatTime();
    restoreOriginalServerMaxSpeed();

    LOG( 2, "( map_restoreEndGameCvars ) TRYING to change the cvar %15s from '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOG( 2, "( map_restoreEndGameCvars ) TRYING to change the cvar %15s from '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOG( 2, "( map_restoreEndGameCvars ) TRYING to change the cvar %15s from '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOG( 2, "( map_restoreEndGameCvars ) TRYING to change the cvar %15s from '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )

    if( g_isEndGameLimitsChanged )
    {
        g_isEndGameLimitsChanged = false;

        tryToSetGameModCvarFloat( cvar_mp_timelimit, g_originalTimelimit );
        tryToSetGameModCvarNum(   cvar_mp_maxrounds, g_originalMaxRounds );
        tryToSetGameModCvarNum(   cvar_mp_winlimit , g_originalWinLimit  );
        tryToSetGameModCvarNum(   cvar_mp_fraglimit, g_originalFragLimit );

        LOG( 2, "( map_restoreEndGameCvars ) RESTORING the cvar %-24s to '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
        LOG( 2, "( map_restoreEndGameCvars ) RESTORING the cvar %-24s to '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
        LOG( 2, "( map_restoreEndGameCvars ) RESTORING the cvar %-24s to '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
        LOG( 2, "( map_restoreEndGameCvars ) RESTORING the cvar %-24s to '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )

        // restore to the original/right values
        g_rtvWaitMinutes = get_pcvar_float( cvar_rtvWaitMinutes );
        g_rtvWaitRounds  = get_pcvar_num(   cvar_rtvWaitRounds  );
        g_rtvWaitFrags   = get_pcvar_num(   cvar_rtvWaitFrags   );
    }

    cacheCvarsValues();
    LOG( 1, "    I AM EXITING ON map_restoreEndGameCvars(0)" )
}

stock restoreOriginalServerMaxSpeed()
{
    LOG( 128, "I AM ENTERING ON restoreOriginalServerMaxSpeed(0) g_original_sv_maxspeed: %f", g_original_sv_maxspeed )

    if( floatround( g_original_sv_maxspeed, floatround_floor ) )
    {
        tryToSetGameModCvarFloat( cvar_sv_maxspeed, g_original_sv_maxspeed );
        LOG( 2, "( restoreOriginalServerMaxSpeed ) IS CHANGING THE CVAR 'sv_maxspeed' to '%f'.", g_original_sv_maxspeed )

        g_original_sv_maxspeed = 0.0;
    }

    if( cvar_mp_friendlyfire
        && g_isToRestoreFriendlyFire )
    {
        tryToSetGameModCvarNum( cvar_mp_friendlyfire, 0 );
        LOG( 2, "( restoreOriginalServerMaxSpeed ) IS CHANGING THE CVAR 'mp_friendlyfire' to '%d'.", get_pcvar_num( cvar_mp_friendlyfire ) )

        g_isToRestoreFriendlyFire = false;
    }
}

stock map_isInMenu( map[] )
{
    LOG( 256, "I AM ENTERING ON map_isInMenu(1) map: %s", map )

    for( new playerVoteMapChoiceIndex = 0;
         playerVoteMapChoiceIndex < g_totalVoteOptions; ++playerVoteMapChoiceIndex )
    {
        if( equali( map, g_votingMapNames[ playerVoteMapChoiceIndex ] ) )
        {
            LOG( 256, "    ( map_isInMenu ) Returning true." )
            return true;
        }
    }

    LOG( 256, "    ( map_isInMenu ) Returning false." )
    return false;
}

stock removeMapFromTheVotingMenu( mapName[] )
{
    LOG( 1, "I AM ENTERING ON removeMapFromTheVotingMenu(1) map: %s", mapName )
    new index;

    for( ; index < g_totalVoteOptions; index++ )
    {
        if( equali( mapName, g_votingMapNames[ index ] ) )
        {
            LOG( 4, "( removeMapFromTheVotingMenu ) Removing map: %s", mapName )

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
    LOG( 1, "I AM ENTERING ON addMapToTheVotingMenu(1) map: %s, mapInfo: %s", mapName, mapInfo )

    if( !map_isInMenu( mapName ) )
    {
        copy( g_votingMapNames[ g_totalVoteOptions ], charsmax( g_votingMapNames[] ), mapName );
        copy( g_votingMapInfos[ g_totalVoteOptions ], charsmax( g_votingMapInfos[] ), mapInfo );

        g_totalVoteOptions++;
    }
}

stock isPrefixInMenu( map[] )
{
    LOG( 256, "I AM ENTERING ON isPrefixInMenu(1) map: %s", map )

    new junk[ 8 ];
    new possiblePrefix[ 8 ];
    new existingPrefix[ 8 ];

    str_token( map, possiblePrefix, charsmax( possiblePrefix ), junk, charsmax( junk ), '_', 1 );

    for( new playerVoteMapChoiceIndex = 0;
         playerVoteMapChoiceIndex < g_totalVoteOptions; ++playerVoteMapChoiceIndex )
    {
        str_token( g_votingMapNames[ playerVoteMapChoiceIndex ],
                existingPrefix, charsmax( existingPrefix ),
                junk          , charsmax( junk )          , '_', 1 );

        if( equali( possiblePrefix, existingPrefix ) )
        {
            LOG( 256, "    ( isPrefixInMenu ) Returning true." )
            return true;
        }
    }

    LOG( 256, "    ( isPrefixInMenu ) Returning false." )
    return false;
}

stock map_isTooRecent( map[] )
{
    LOG( 256, "I AM ENTERING ON map_isTooRecent(1) map: %s", map )

    if( g_recentMapsTrie )
    {
        LOG( 256, "    ( map_isTooRecent ) Returning TrieKeyExists: %d", TrieKeyExists( g_recentMapsTrie, map ) )
        return TrieKeyExists( g_recentMapsTrie, map );
    }

    return false;
}

stock announcerockFailToosoon( player_id, Float:minutesElapsed )
{
    LOG( 128, "I AM ENTERING ON announcerockFailToosoon(1) minutesElapsed: %d", minutesElapsed )
    new remaining_time;

    // It will be 2 minutes because there is not point to calculate whether it will be 1 or 2 minutes.
    if( g_isMapExtensionPeriodRunning )
    {
        remaining_time = 2;
    }
    else
    {
        remaining_time = floatround( g_rtvWaitMinutes - minutesElapsed, floatround_ceil );
    }

    color_chat( player_id, "%L", player_id, "GAL_ROCK_FAIL_TOOSOON", remaining_time );
    LOG( 1, "    ( announcerockFailToosoon ) Just Returning/blocking, too soon to rock by minutes." )
}

stock debugRtvVote()
{
    new players_number = get_real_players_number();

    LOG( 4, "( is_to_block_RTV ) g_voteStatus:            %d", g_voteStatus )
    LOG( 4, "( is_to_block_RTV ) g_rtvCommands:           %d", g_rtvCommands )
    LOG( 4, "( is_to_block_RTV ) g_timeLimitNumber:       %d", g_timeLimitNumber )
    LOG( 4, "( is_to_block_RTV ) g_fragLimitNumber:       %d", g_fragLimitNumber )
    LOG( 4, "( is_to_block_RTV ) g_rtvWaitMinutes:        %f", g_rtvWaitMinutes )
    LOG( 4, "( is_to_block_RTV ) g_maxRoundsNumber:       %d", g_maxRoundsNumber )
    LOG( 4, "( is_to_block_RTV ) g_winLimitNumber:        %d", g_winLimitNumber )
    LOG( 4, "( is_to_block_RTV ) g_rtvWaitRounds:         %d", g_rtvWaitRounds )
    LOG( 4, "( is_to_block_RTV ) g_totalRoundsPlayed:     %d", g_totalRoundsPlayed )
    LOG( 4, "( is_to_block_RTV ) g_rtvWaitFrags:          %d", g_rtvWaitFrags )
    LOG( 4, "( is_to_block_RTV ) g_greatestKillerFrags    %d", g_greatestKillerFrags )
    LOG( 4, "( is_to_block_RTV ) g_rtvWaitAdminNumber:    %d", g_rtvWaitAdminNumber )
    LOG( 4, "( is_to_block_RTV ) cvar_rtvWaitAdmin:       %d", get_pcvar_num( cvar_rtvWaitAdmin ) )
    LOG( 4, "( is_to_block_RTV ) get_real_players_number: %d", players_number )

    return 0;
}

stock is_to_block_RTV( player_id )
{
    LOG( 128, "I AM ENTERING ON is_to_block_RTV(1) player_id: %d", player_id )
    LOG( 0, "", debugRtvVote() )

    // If time-limit is 0, minutesElapsed will always be 0.
    new Float:minutesElapsed;
    new playerTeam;

    // If an early vote is pending, don't allow any rocks
    if( g_voteStatus & IS_EARLY_VOTE )
    {
        color_chat( player_id, "%L", player_id, "GAL_ROCK_FAIL_PENDINGVOTE" );
        LOG( 1, "    ( is_to_block_RTV ) Just Returning/blocking, the early voting is pending." )
    }

    // Rocks can only be made if a vote isn't already in progress
    else if( g_voteStatus & IS_VOTE_IN_PROGRESS )
    {
        color_chat( player_id, "%L", player_id, "GAL_ROCK_FAIL_INPROGRESS" );
        LOG( 1, "    ( is_to_block_RTV ) Just Returning/blocking, the voting is in progress." )
    }

    // If the outcome of the vote hasn't already been determined
    else if( g_voteStatus & IS_VOTE_OVER )
    {
        color_chat( player_id, "%L", player_id, "GAL_ROCK_FAIL_VOTEOVER" );
        LOG( 1, "    ( is_to_block_RTV ) Just Returning/blocking, the voting is over." )
    }

    // Cannot rock when admins are online
    else if( get_pcvar_num( cvar_rtvWaitAdmin ) & IS_TO_RTV_WAIT_ADMIN
             && g_rtvWaitAdminNumber > 0 )
    {
        color_chat( player_id, "%L", player_id, "GAL_ROCK_WAIT_ADMIN" );
        LOG( 1, "    ( is_to_block_RTV ) Just Returning/blocking, cannot rock when admins are online." )
    }

    // If the player is the only one on the server, bring up the vote immediately
    else if( get_real_players_number() == 1
             && !( g_rtvCommands & RTV_CMD_SINGLE_PLAYER_DISABLE ) )
    {
        start_rtvVote();
        LOG( 1, "    ( is_to_block_RTV ) Just Returning/blocking, the voting started." )
    }

    // Make sure enough time has gone by on the current map
    else if( ( g_timeLimitNumber
               || g_fragLimitNumber )
             && g_rtvWaitMinutes
             && ( minutesElapsed = map_getMinutesElapsed() )
             && minutesElapsed < g_rtvWaitMinutes )
    {
        announcerockFailToosoon( player_id, minutesElapsed );
    }

    // Make sure enough rounds has gone by on the current map
    else if( ( g_maxRoundsNumber
               || g_winLimitNumber )
             && g_rtvWaitRounds
             && g_totalRoundsPlayed < g_rtvWaitRounds )
    {
        new remaining_rounds = g_rtvWaitRounds - g_totalRoundsPlayed;

        color_chat( player_id, "%L", player_id, "GAL_ROCK_FAIL_TOOSOON_ROUNDS", remaining_rounds );
        LOG( 1, "    ( is_to_block_RTV ) Just Returning/blocking, too soon to rock by rounds." )
    }

    // Make sure enough frags has gone by on the current map
    else if( g_rtvWaitFrags
             && g_greatestKillerFrags < g_rtvWaitFrags )
    {
        new remaining_frags =  g_rtvWaitFrags - g_greatestKillerFrags;

        color_chat( player_id, "%L", player_id, "GAL_ROCK_FAIL_TOOSOON_FRAGS", remaining_frags );
        LOG( 1, "    ( is_to_block_RTV ) Just Returning/blocking, too soon to rock by frags." )
    }

    // Make sure the spectators team is allowed to RTV
    // 0 - UNASSIGNED
    // 1 - TERRORIST
    // 2 - CT
    // 3 - SPECTATOR
    else if( IS_TO_IGNORE_SPECTATORS()
             && ( ( playerTeam = get_user_team( player_id ) ) != 1
                  && playerTeam != 2 ) )
    {
        color_chat( player_id, "%L", player_id, "GAL_ROCK_WAIT_SPECTATOR" );
        LOG( 1, "    ( is_to_block_RTV ) Just Returning/blocking, the player is on the spectators team." )
    }

    // Allow the Rock The Vote
    else
    {
        LOG( 1, "    ( is_to_block_RTV ) Just Returning/allowing, the RTV." )
        return false;
    }

    // Block the Rock The Vote
    return true;
}

public vote_rock( player_id )
{
    LOG( 128, "I AM ENTERING ON vote_rock(1) player_id: %d", player_id )

    if( !is_to_block_RTV( player_id ) )
    {
        try_to_start_the_RTV( vote_getRocksNeeded(), !compute_the_RTV_vote( player_id ) );
    }
}

/**
 * Allow the player to rock the vote.
 *
 * @return true when the vote is computed, false otherwise.
 */
stock compute_the_RTV_vote( player_id )
{
    LOG( 128, "I AM ENTERING ON compute_the_RTV_vote(2)" )
    LOG( 4, "( compute_the_RTV_vote ) player_id:   %d", player_id )

    // make sure player hasn't already rocked the vote
    if( g_rockedVote[ player_id ] )
    {
        color_chat( player_id, "%L", player_id, "GAL_ROCK_FAIL_ALREADY", vote_getRocksNeeded() );
        rtv_remind( TASKID_RTV_REMINDER + player_id );

        LOG( 1, "    ( compute_the_RTV_vote ) Just Returning/blocking, already rocked the vote." )
        return false;
    }

    g_rockedVoteCount++;
    g_rockedVote[ player_id ] = true;

    color_chat( player_id, "%L", player_id, "GAL_ROCK_SUCCESS" );
    LOG( 1, "    ( compute_the_RTV_vote ) Just Returning/blocking, accepting rock the vote." )

    return true;
}

/**
 * Determine if there have been enough rocks for a vote yet.
 *
 * @param rocksNeeded   how many RTVs are necessary/required to start the voting
 * @param silent        whether or not to announce by chat how many RTVs are remaining to start the voting
 */
stock try_to_start_the_RTV( rocksNeeded, bool:silent=false )
{
    LOG( 128, "I AM ENTERING ON try_to_start_the_RTV(2)" )

    LOG( 4, "( try_to_start_the_RTV ) silent:            %d", silent )
    LOG( 4, "( try_to_start_the_RTV ) rocksNeeded:       %d", rocksNeeded )
    LOG( 4, "( try_to_start_the_RTV ) g_rockedVoteCount: %d", g_rockedVoteCount )

    // make sure the rtv reminder timer has stopped
    if( task_exists( TASKID_RTV_REMINDER ) )
    {
        remove_task( TASKID_RTV_REMINDER );
    }

    // If there are 0 players, the voting will never start.
    if( IS_TO_IGNORE_SPECTATORS()
        && get_real_players_number() == 0 )
    {
        color_chat( 0, CANNOT_START_VOTE_SPECTATORS );
    }
    else
    {
        if( rocksNeeded < 1 )
        {
            // announce that the vote has been rocked
            color_chat( 0, "%L", LANG_PLAYER, "GAL_ROCK_ENOUGH" );

            // start up the vote director
            start_rtvVote();
        }
        else if( !silent )
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
    LOG( 128, "I AM ENTERING ON start_rtvVote(0)" )
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

    // Set the RTV voting status and remember, the RTV voting does not need to set the `g_endVotingType`
    // because there is no map extension option, only `Stay Here` for forced voting as RTV.
    g_voteStatus |= IS_RTV_VOTE;

    // Any voting not started by `cvar_endOfMapVoteStart` or ending limit expiration, is a forced voting.
    startTheVoting( true );
}

stock vote_unrockTheVote( player_id )
{
    LOG( 128, "I AM ENTERING ON vote_unrockTheVote(1) player_id: %d", player_id )

    if( g_rockedVote[ player_id ] )
    {
        g_rockedVoteCount--;
        g_rockedVote[ player_id ] = false;
    }

    try_to_start_the_RTV( vote_getRocksNeeded(), true );
}

/**
 * Consider how may RTV votes are required to start the voting. If 0, the voting must to start
 * immediately.
 *
 * @return how many RTVs there necessary to start the voting
 */
stock vote_getRocksNeeded()
{
    LOG( 128, "I AM ENTERING ON vote_getRocksNeeded(0)" )
    new rocks_needed;
    new rocks_required;

    if( ( rocks_required = get_pcvar_num( cvar_rtvRocks ) ) > 0 )
    {
        LOG( 4, "( vote_getRocksNeeded ) rocks_required:    %d", rocks_required )

        // Ensure a valid limit
        if( rocks_required > MAX_PLAYERS ) rocks_required = 31;
        rocks_needed = rocks_required - g_rockedVoteCount;
    }
    else
    {
        // Calculate how many rocks are necessary
        rocks_required = floatround( get_pcvar_float( cvar_rtvRatio ) * float( get_real_players_number() ), floatround_ceil );
        LOG( 4, "( vote_getRocksNeeded ) rocks_required:    %d", rocks_required )

        // Ensure there are a valid count
        if( rocks_required < 1 ) rocks_required = 1;
        rocks_needed = rocks_required - g_rockedVoteCount;

        LOG( 4, "( vote_getRocksNeeded ) cvar_rtvRatio:     %f", get_pcvar_float( cvar_rtvRatio ) )
    }

    LOG( 4, "( vote_getRocksNeeded ) rocks_needed:      %d", rocks_needed )
    LOG( 4, "( vote_getRocksNeeded ) g_rockedVoteCount: %d", g_rockedVoteCount )

    // Ensure positive values
    if( rocks_needed < 0 ) rocks_needed = 0;

    LOG( 4, "    ( vote_getRocksNeeded ) Returning: %d", rocks_needed )
    return rocks_needed;
}

public rtv_remind( param )
{
    LOG( 128, "I AM ENTERING ON rtv_remind(1) param: %d", param )
    new player_id = param - TASKID_RTV_REMINDER;

    // let the players know how many more rocks are needed
    color_chat( player_id, "%L", LANG_PLAYER, "GAL_ROCK_NEEDMORE", vote_getRocksNeeded() );
}

// change to the map
public map_change()
{
    LOG( 128, "I AM ENTERING ON map_change(0)" )

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
    LOG( 128, "I AM ENTERING ON map_change_stays(0)" )
    resetRoundEnding();

    LOG( 4, "( map_change_stays ) g_currentMapName: %s", g_currentMapName )
    serverChangeLevel( g_currentMapName );
}

public serverChangeLevel( mapName[] )
{
    LOG( 128, "I AM ENTERING ON serverChangeLevel(1)" )

    LOG( 4, "( serverChangeLevel ) mapName:          %s", mapName )
    LOG( 4, "( serverChangeLevel ) AMXX_VERSION_NUM: %d", AMXX_VERSION_NUM )
    LOG( 4, "( serverChangeLevel ) IS_TO_ENABLE_RE_HLDS_RE_AMXMODX_SUPPORT: %d", IS_TO_ENABLE_RE_HLDS_RE_AMXMODX_SUPPORT )

#if ARE_WE_RUNNING_UNIT_TESTS
    if( g_test_areTheUnitTestsRunning )
    {
        if( IS_MAP_VALID( mapName ) )
        {
            copy( g_currentMapName, charsmax( g_currentMapName ), mapName );
        }
        else
        {
            new length = strlen( mapName );
            copy( g_currentMapName[ length ], charsmax( g_currentMapName ) - length, "_invalid_map" );
        }

        LOG( 1, "    I AM EXITING serverChangeLevel(1)... g_currentMapName: %s", g_currentMapName )
        LOG( 1, "" )
        return;
    }
#endif

#if AMXX_VERSION_NUM < 183 || IS_TO_ENABLE_RE_HLDS_RE_AMXMODX_SUPPORT > 0
    server_cmd( "changelevel %s", mapName );
#else
    engine_changelevel( mapName );
#endif

    LOG( 1, "    I AM EXITING serverChangeLevel(1)..." )
    LOG( 1, "" )
}

/**
 * The default engine console `votemap command` customization.
 */
public cmd_HL1_votemap( player_id )
{
    LOG( 128, "I AM ENTERING ON cmd_HL1_votemap(1) player_id: %d", player_id )

    if( get_pcvar_num( cvar_cmdVotemap ) == 0 )
    {
        console_print( player_id, "%L", player_id, "GAL_DISABLED" );

        LOG( 1, "    ( cmd_HL1_votemap ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }

    LOG( 1, "    ( cmd_HL1_votemap ) Returning PLUGIN_CONTINUE" )
    return PLUGIN_CONTINUE;
}

/**
 * The default engine console `listmaps` command customization.
 */
public cmd_HL1_listmaps( player_id )
{
    LOG( 128, "I AM ENTERING ON cmd_HL1_listmaps(1) player_id: %d", player_id )

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
            LOG( 1, "    ( cmd_HL1_listmaps ) Returning PLUGIN_CONTINUE" )
            return PLUGIN_CONTINUE;
        }
    }

    LOG( 1, "    ( cmd_HL1_listmaps ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

/**
 * Properly list all server maps at the user console.
 */
public map_listAll( player_id )
{
    LOG( 128, "I AM ENTERING ON map_listAll(1) player_id: %d", player_id )
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
stock no_color_console( const player_id, const message[], any:... )
{
    LOG( 128, "I AM ENTERING ON color_console_print(...) player_id: %d, message: `%s`", player_id, message )
    new formatted_message[ MAX_COLOR_MESSAGE ];

    vformat( formatted_message, charsmax( formatted_message ), message, 3 );
    REMOVE_CODE_COLOR_TAGS( formatted_message )

    console_print( player_id, formatted_message );
}

stock restartEmptyCycle()
{
    LOG( 128, "I AM ENTERING ON restartEmptyCycle(0)" )
    set_pcvar_num( cvar_isToStopEmptyCycle, 0 );

    LOG( 2, "( restartEmptyCycle ) IS CHANGING THE CVAR 'gal_in_empty_cycle' to '%d'.", 0 )
    remove_task( TASKID_EMPTYSERVER );
}

/**
 * The reamxmodx is requiring more parameters to allow a call to `client_authorized()` from the
 * Unit Test. So, the stock client_authorized_stock(1) is just a shadow of the client_authorized(1)
 * just to allow to perform the Unit tests.
 */
#define CLIENT_AUTHORIZED_MACRO(%1) \
{ \
    LOG( 128, "I AM ENTERING ON client_authorized(1) player_id: %d", %1 ) \
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

/**
 * I do not know whether client_disconnected(1) will present the same problem as CLIENT_AUTHORIZED_MACRO(1)
 * macro just above fixes, so I put it on a stock just for precaution.
 */
stock clientDisconnected( player_id )
{
    LOG( 128, "I AM ENTERING ON clientDisconnected(1) player_id: %d [%d|%d]", player_id, get_playersnum(), get_real_players_number() )
    if( is_user_bot( player_id ) ) return;

    if( get_user_flags( player_id ) & ADMIN_MAP )
    {
        g_rtvWaitAdminNumber--;
    }

    // Always unrock the vote, otherwise the server may start a new map vote and for the map to
    // change immediately when the `approveTheVotingStart(1)` reach on the `gal_nextmap_votemap`
    // feature, which triggers the `startEmptyCycleSystem(0)`.
    vote_unrockTheVote( player_id );

    if( get_pcvar_num( cvar_unnominateDisconnected ) )
    {
        unnominatedDisconnectedPlayer( player_id );
    }

    isToHandleRecentlyEmptyServer();
}

#if AMXX_VERSION_NUM < 183
    public client_disconnect( player_id )
#else
    public client_disconnected( player_id )
#endif
{
    LOG( 128, "I AM ENTERING ON client_disconnected(1) player_id: %d", player_id )
    clientDisconnected( player_id );
}

stock unnominatedDisconnectedPlayer( player_id )
{
    LOG( 128, "I AM ENTERING ON unnominatedDisconnectedPlayer(1) player_id: %d", player_id )

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
        if( ( mapIndex = getPlayerNominationMapIndex( player_id, nominationIndex ) ) < 0 )
        {
            continue;
        }
        else
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
    LOG( 128, "I AM ENTERING ON isToHandleRecentlyEmptyServer(0)" )
    new playersCount = get_real_players_number();

    LOG( 2, "( isToHandleRecentlyEmptyServer ) mp_timelimit: %f, g_originalTimelimit: %f, playersCount: %d", \
            get_pcvar_float( cvar_mp_timelimit ), g_originalTimelimit, playersCount )

    if( playersCount == 0 )
    {
        if( g_originalTimelimit != get_pcvar_float( cvar_mp_timelimit ) )
        {
            // It's possible that the map has been extended at least once. That
            // means that if someone comes into the server, the time limit will
            // be the extended time limit rather than the normal time limit, bad.
            // Reset the original time limit
            map_restoreEndGameCvars();
        }

        // If it is utilizing "empty server" feature, to start it.
        if( g_isUsingEmptyCycle
            && g_emptyCycleMapsArray
            && ArraySize( g_emptyCycleMapsArray ) )
        {
            startEmptyCycleCountdown();
        }
    }

    LOG( 2, "I AM EXITING ON isToHandleRecentlyEmptyServer(0) g_isUsingEmptyCycle = %d, \
            g_emptyCycleMapsArray: %d", g_isUsingEmptyCycle, g_emptyCycleMapsArray )
}

/**
 * Inicializes the empty cycle server feature at map starting.
 */
public inicializeEmptyCycleFeature()
{
    LOG( 128, "I AM ENTERING ON inicializeEmptyCycleFeature(0)" )

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
    LOG( 128, "I AM ENTERING ON startEmptyCycleCountdown(0)" )
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
    LOG( 128, "I AM ENTERING ON configureNextEmptyCycleMap(0)" )
    new mapIndex;

    new nextMapName      [ MAX_MAPNAME_LENGHT ];
    new lastEmptyCycleMap[ MAX_MAPNAME_LENGHT ];

    mapIndex = map_getNext( g_emptyCycleMapsArray, g_currentMapName, nextMapName, "empty_cycle_maps" );

    if( !g_isEmptyCycleMapConfigured )
    {
        g_isEmptyCycleMapConfigured = true;

        getLastEmptyCycleMap( lastEmptyCycleMap );
        map_getNext( g_emptyCycleMapsArray, lastEmptyCycleMap, nextMapName, "empty_cycle_maps" );

        setLastEmptyCycleMap( nextMapName );
        setNextMap( g_currentMapName, nextMapName );
    }

    LOG( 128, "    ( configureNextEmptyCycleMap ) mapIndex: %d", mapIndex )
    return mapIndex;
}

stock getLastEmptyCycleMap( lastEmptyCycleMap[ MAX_MAPNAME_LENGHT ] )
{
    LOG( 128, "I AM ENTERING ON getLastEmptyCycleMap(1) lastEmptyCycleMap: %s", lastEmptyCycleMap )

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
    LOG( 128, "I AM ENTERING ON setLastEmptyCycleMap(1) lastEmptyCycleMap: %s", lastEmptyCycleMap )

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
    LOG( 128, "I AM ENTERING ON startEmptyCycleSystem(0)" )

    // stop this system at the next map, due we already be at a popular map
    set_pcvar_num( cvar_isToStopEmptyCycle, 1 );
    LOG( 2, "( startEmptyCycleSystem ) IS CHANGING THE CVAR 'gal_in_empty_cycle' to '%d'.", 1 )

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
stock map_getNext( Array:mapArray, const currentMap[], nextMapName[], const caller[] )
{
    LOG( 128, "I AM ENTERING ON map_getNext(4) currentMap: %s", currentMap )
    new bool:isWhitelistBlocking;

    new mapCount;
    new nextmapIndex;

    new returnValue = -1;
    new thisMap[ MAX_MAPNAME_LENGHT ];

    if( mapArray ) mapCount = ArraySize( mapArray );
    new bool:isWhitelistEnabled = IS_WHITELIST_ENABLED();

    for( new currentMapIndex = 0; currentMapIndex < mapCount; currentMapIndex++ )
    {
        GET_MAP_NAME( mapArray, currentMapIndex, thisMap )

        if( isWhitelistBlocking
            || equali( currentMap, thisMap ) )
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
                doAmxxLog( "WARNING, map_getNext: The Whitelist feature is blocking the map ^"%s^"", nextMapName );

                isWhitelistBlocking = true;
                continue;
            }

            returnValue = nextmapIndex;
            break;
        }
    }

    if( isWhitelistBlocking )
    {
        if( mapCount > 0
            && returnValue > -1 )
        {
            GET_MAP_NAME( mapArray, nextmapIndex, nextMapName )
        }
        else
        {
            doAmxxLog( "WARNING, map_getNext: Your ^"%s^" server variable does not contain valid maps by the Whitelist feature!", caller );
            copy( nextMapName, MAX_MAPNAME_LENGHT - 1, g_currentMapName );
        }
    }
    else
    {
        if( mapCount > 0 )
        {
            GET_MAP_NAME( mapArray, nextmapIndex, nextMapName )
        }
        else
        {
            doAmxxLog( "WARNING, map_getNext: Your ^"%s^" server variable map file does not contain valid maps!", caller );
            copy( nextMapName, MAX_MAPNAME_LENGHT - 1, g_currentMapName );
        }
    }

    LOG( 1, "    ( map_getNext ) Returning mapIndex: %d, nextMapName: %s", returnValue, nextMapName )
    return returnValue;
}

public client_putinserver( player_id )
{
    LOG( 128, "I AM ENTERING ON client_putinserver(1) player_id: %d", player_id )

    if( ( g_voteStatus & IS_EARLY_VOTE )
        && !is_user_bot( player_id )
        && !is_user_hltv( player_id ) )
    {
        set_task( 20.0, "srv_announceEarlyVote", player_id );
    }
}

public srv_announceEarlyVote( player_id )
{
    LOG( 128, "I AM ENTERING ON srv_announceEarlyVote(1) player_id: %d", player_id )

    if( is_user_connected( player_id ) )
    {
        color_chat( player_id, "%L", player_id, "GAL_VOTE_EARLY" );
    }
}

stock nomination_announceCancellation( nominations[] )
{
    LOG( 128, "I AM ENTERING ON nomination_announceCancellation(1) nominations: %s", nominations )
    color_chat( 0, "%L", LANG_PLAYER, "GAL_CANCEL_SUCCESS", nominations );
}

stock nomination_clearAll()
{
    LOG( 128, "I AM ENTERING ON nomination_clearAll(0)" )

    if( get_pcvar_num( cvar_nomCleaning ) )
    {
        TRY_TO_APPLY( TrieClear, g_reverseSearchNominationsTrie )
        TRY_TO_APPLY( TrieClear, g_forwardSearchNominationsTrie )

        TRY_TO_APPLY( ArrayClear, g_nominatedMapsArray )
    }
}

stock map_announceNomination( player_id, map[] )
{
    LOG( 128, "I AM ENTERING ON map_announceNomination(2) player_id: %d, map: %s", player_id, map )
    new player_name[ MAX_PLAYER_NAME_LENGHT ];

    GET_USER_NAME( player_id, player_name )
    color_chat( 0, "%L", LANG_PLAYER, "GAL_NOM_SUCCESS", player_name, map );
}

/**
 * The command `say rockthevote`.
 */
public cmd_rockthevote( player_id )
{
    LOG( 128, "I AM ENTERING ON cmd_rockthevote(1) player_id: %d", player_id )

    // Suggests to use `say rtv` and call the actual rock the vote function vote_rock(1).
    color_chat( player_id, "%L", player_id, "GAL_CMD_RTV" );
    vote_rock( player_id );

    LOG( 1, "    ( cmd_rockthevote ) Returning PLUGIN_CONTINUE" )
    return PLUGIN_CONTINUE;
}

/**
 * The command `say nominations`.
 */
public cmd_nominations( player_id )
{
    LOG( 128, "I AM ENTERING ON cmd_nominations(1) player_id: %d", player_id )

    // Suggests to use `say noms` and call the actual rock the vote function nomination_list().
    color_chat( player_id, "%L", player_id, "GAL_CMD_NOMS" );
    nomination_list();

    LOG( 1, "    ( cmd_nominations ) Returning PLUGIN_CONTINUE" )
    return PLUGIN_CONTINUE;
}

/**
 * The command `quit2`. See also setTheCurrentAndNextMapSettings(0).
 */
public cmd_quit2()
{
    LOG( 128, "I AM ENTERING ON cmd_quit2(0)" )
    g_isServerShuttingDown = true;

    server_cmd( "quit" );
    return PLUGIN_CONTINUE;
}

/**
 * The command `gal_startvote`, used when need to start a forced vote map.
 */
public cmd_startVote( player_id, level, cid )
{
    LOG( 128, "I AM ENTERING ON cmd_startVote(3) player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOG( 1, "    ( cmd_startVote ) Returning PLUGIN_CONTINUE" )
        return PLUGIN_CONTINUE;
    }

    if( g_voteStatus & IS_VOTE_IN_PROGRESS )
    {
        color_chat( player_id, "%L", player_id, "GAL_VOTE_INPROGRESS" );
    }
    else
    {
        new waitTime;
        new argument[ 32 ];

        g_isToChangeMapOnVotingEnd = true;
        read_args( argument, charsmax( argument ) );

        if( read_argc() < 3 )
        {
            // When `false`, block the the map change when the option `VOTE_WAIT_FOR_ROUND_END` is set.
            new bool:isChangeOnRoundEnd;
            remove_quotes( argument );

            if( strlen( argument ) > 0 )
            {
                if( equali( argument, "-nochange" ) )
                {
                    g_isToChangeMapOnVotingEnd = false;
                }
                else if( equali( argument, "-restart", 4 ) )
                {
                    g_isTimeToRestart = true;
                }
                else if( equali( argument, "-roundend", 4 ) )
                {
                    g_isTheLastGameRound = true;
                    g_isToChangeMapOnVotingEnd = false;
                }
                else if( ( isChangeOnRoundEnd = ( equali( argument, "-now", 4 ) != 1 ) ) )
                {
                    // Do nothing here, just break the if chain.
                }
                else
                {
                    goto showHelp;
                }
            }

            // Force the map change at the current round end, instead of immediately.
            if( isChangeOnRoundEnd
                && get_pcvar_num( cvar_generalOptions ) & VOTE_WAIT_FOR_ROUND_END )
            {
                g_isTheLastGameRound = true;
                g_isToChangeMapOnVotingEnd = false;
            }

            LOG( 8, "( cmd_startVote ) isChangeOnRoundEnd: %d", isChangeOnRoundEnd )
            LOG( 8, "( cmd_startVote ) g_isTimeToRestart: %d", g_isTimeToRestart )
            LOG( 8, "( cmd_startVote ) g_isTheLastGameRound: %d, argument: %s", g_isTheLastGameRound, argument )
            LOG( 8, "( cmd_startVote ) g_isToChangeMapOnVotingEnd: %d, g_voteStatus: %d", g_isToChangeMapOnVotingEnd, g_voteStatus )

            waitTime = floatround( getVoteAnnouncementTime( get_pcvar_num( cvar_isToAskForEndOfTheMapVote ) ), floatround_ceil );
            console_print( player_id, "%L", player_id, "GAL_VOTE_COUNTDOWN", waitTime );

            startTheVoting( true );
        }
        else
        {
            showHelp:
            console_print( player_id, "^nThe argument `%s` could not be recognized as a valid option.", argument );

            // It was necessary to split the message up to 190 characters due the output print being cut.
            console_print( player_id,
                   "Examples:\
                    ^ngal_votemap\
                    ^ngal_votemap -now\
                    ^ngal_votemap -nochange\
                    ^ngal_votemap -restart\
                    ^ngal_votemap -roundend\
                    " );
        }
    }

    LOG( 1, "    ( cmd_startVote ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

/**
 * The command `gal_createmapfile`.
 */
public cmd_createMapFile( player_id, level, cid )
{
    LOG( 128, "I AM ENTERING ON cmd_createMapFile(3) player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOG( 1, "    ( cmd_createMapFile ) Returning PLUGIN_CONTINUE" )
        return PLUGIN_CONTINUE;
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

    LOG( 1, "    ( cmd_createMapFile ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

stock createMapFileFromAllServerMaps( player_id, mapFilePath[] )
{
    LOG( 128, "I AM ENTERING ON createMapFileFromAllServerMaps(2) player_id: %d, mapFilePath: %s", player_id, mapFilePath )

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
            LOG( 1, "ERROR: %L", LANG_SERVER, "GAL_CREATIONFAILED", mapFilePath )
        }

        close_dir( directoryDescriptor );
    }
    else
    {
        // directory not found, wtf?
        console_print( player_id, "%L", player_id, "GAL_MAPSFOLDERMISSING" );
        LOG( 1, "ERROR: %L", LANG_SERVER, "GAL_MAPSFOLDERMISSING" )
    }
}

public sort_stringsi( Array:array, elem1, elem2, data[], data_size )
{
    LOG( 256, "I AM ENTERING ON sort_stringsi(5) array: %d, elem1: %d, elem2: %d", array, elem1, elem2 )

    new map1[ MAX_MAPNAME_LENGHT ];
    new map2[ MAX_MAPNAME_LENGHT ];

    ArrayGetString( array, elem1, map1, charsmax( map1 ) );
    ArrayGetString( array, elem2, map2, charsmax( map2 ) );

    LOG( 256, "    ( sort_stringsi ) Returning %s > %s: %d", map1, map2, strcmp( map1, map2, true ) )
    return strcmp( map1, map2, true );
}

/**
 * The command `gal_maintenance_mode`.
 */
public cmd_maintenanceMode( player_id, level, cid )
{
    LOG( 128, "I AM ENTERING ON cmd_maintenanceMode(3) player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOG( 1, "    ( cmd_maintenanceMode ) Returning PLUGIN_CONTINUE" )
        return PLUGIN_CONTINUE;
    }

    // Always print to the console for logging, because it is a important event.
    if( g_isOnMaintenanceMode )
    {
        g_isOnMaintenanceMode = false;
        map_restoreEndGameCvars();

        color_chat( 0, "%L", LANG_PLAYER, "GAL_CHANGE_MAINTENANCE_STATE", LANG_PLAYER, "GAL_CHANGE_MAINTENANCE_OFF" );
        no_color_console( player_id, "%L", player_id, "GAL_CHANGE_MAINTENANCE_STATE", player_id, "GAL_CHANGE_MAINTENANCE_OFF" );
    }
    else
    {
        g_isOnMaintenanceMode = true;

        color_chat( 0, "%L", LANG_PLAYER, "GAL_CHANGE_MAINTENANCE_STATE", LANG_PLAYER, "GAL_CHANGE_MAINTENANCE_ON" );
        no_color_console( player_id, "%L", player_id, "GAL_CHANGE_MAINTENANCE_STATE", player_id, "GAL_CHANGE_MAINTENANCE_ON" );
    }

    LOG( 1, "    ( cmd_maintenanceMode ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

/**
 * The command `gal_look_for_crashes`.
 */
public cmd_lookForCrashes( player_id, level, cid )
{
    LOG( 128, "I AM ENTERING ON cmd_lookForCrashes(3) player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOG( 1, "    ( cmd_lookForCrashes ) Returning PLUGIN_CONTINUE" )
        return PLUGIN_CONTINUE;
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
            doAmxxLog( "Stopping the server crash change...^nContents of the file: ^n^"%s^"^n", crashedMapsFilePath);

            console_print( player_id, "Stopping the server crash change...^n\
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
            doAmxxLog( "ERROR, cmd_lookForCrashes: Couldn't open the file ^"%s^"", crashedMapsFilePath );
        }
    }
    else
    {
        new message[ MAX_LONG_STRING ];

        formatex( message, charsmax( message ), "^nStarting the crash maps search. This will check all your server maps." );
        doAmxxLog( message );

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
            doAmxxLog( "ERROR, cmd_lookForCrashes: Couldn't create the file ^"%s^"", crashedMapsFilePath );
        }
    }

    LOG( 1, "    ( cmd_lookForCrashes ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

/**
 * Generic say handler to determine if we need to act on what was said.
 *
 * This need to be registered only if the RTV and Nominations are enabled.
 */
public cmd_say( player_id )
{
    LOG( 128, "I AM ENTERING ON cmd_say(1) player_id: %s", player_id )

    new bool:status;
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

    LOG( 4, "( cmd_say ) sentence: %s, firstWord: %s, secondWord: %s, thirdWord: %s", \
            sentence, firstWord, secondWord, thirdWord )

    // if the chat line has more than 2 words, we're not interested at all
    if( thirdWord[ 0 ] == '^0' )
    {
        new userFlags          = get_user_flags( player_id );
        new nomPlayerAllowance = get_pcvar_num( cvar_nomPlayerAllowance );

        LOG( 4, "( cmd_say ) the thirdWord is empty, userFlags: %d", userFlags )

        strtolower( firstWord );
        strtolower( secondWord );

        // if the chat line contains 1 word, it could be a map or a one-word command as
        // "say [rtv|rockthe<anything>vote]"
        if( secondWord[ 0 ] == '^0' )
        {
            LOG( 4, "( cmd_say ) the secondWord is empty. Handling: '%s'.", firstWord )

            if( nomPlayerAllowance
                && userFlags & ADMIN_MAP
                && containi( firstWord, GAL_VOTEMAP_MENU_COMMAND ) > -1 )
            {
                // Calculate how much pages there are available.
                new nominationsMapsCount = ArraySize( g_nominationLoadedMapsArray );
                new lastPageNumber       = GET_LAST_PAGE_NUMBER( nominationsMapsCount, MAX_NOM_MENU_ITEMS_PER_PAGE )

                setCorrectMenuPage( player_id, firstWord, g_voteMapMenuPages, lastPageNumber );
                voteMapMenuBuilder( player_id );

                status = true;
            }
            else if( ( g_rtvCommands & RTV_CMD_SHORTHAND
                       && equali( firstWord, "rtv" ) )
                     || ( g_rtvCommands & RTV_CMD_DYNAMIC
                          && equali( firstWord, "rockthe", 7 )
                          && equali( firstWord[ strlen( firstWord ) - 4 ], "vote" )
                          && !( g_rtvCommands & RTV_CMD_STANDARD ) ) )
            {
                vote_rock( player_id );
                status = true;
            }
            else if( nomPlayerAllowance )
            {
                status = sayHandlerForOneNomWords( player_id, firstWord );
            }
        }
        else if( nomPlayerAllowance
                 && userFlags & ADMIN_MAP
                 && equali( firstWord, GAL_VOTEMAP_MENU_COMMAND ) )
        {
            // Calculate how much pages there are available.
            new nominationsMapsCount = ArraySize( g_nominationLoadedMapsArray );
            new lastPageNumber       = GET_LAST_PAGE_NUMBER( nominationsMapsCount, MAX_NOM_MENU_ITEMS_PER_PAGE )

            setCorrectMenuPage( player_id, secondWord, g_voteMapMenuPages, lastPageNumber );
            voteMapMenuBuilder( player_id );

            status = true;
        }
        else if( nomPlayerAllowance )  // "say <nominate|nom|cancel> <map>"
        {
            status = sayHandlerForTwoNomWords( player_id, firstWord, secondWord );
        }
    }

    LOG( 1, "    ( cmd_say ) Just returning %s, as reached the handler end.", \
           IS_TO_MUTE( status ) ? "PLUGIN_HANDLED" : "PLUGIN_CONTINUE" )
    return IS_TO_MUTE( status );
}

/**
 * Handles one user word said on chat.
 *
 * @return true when it is performed some nomination command, false otherwise
 */
stock bool:sayHandlerForOneNomWords( player_id, firstWord[] )
{
    LOG( 128, "I AM ENTERING ON sayHandlerForOneNomWords(2)" )
    LOG( 4, "( sayHandlerForOneNomWords ) get_pcvar_num( cvar_nomPlayerAllowance ): %d", get_pcvar_num( cvar_nomPlayerAllowance ) )

    if( equali( firstWord, "noms" )
        || equali( firstWord, "nominations" ) )
    {
        nomination_list();

        LOG( 1, "    ( sayHandlerForOneNomWords ) Just returning true, nomination_list(0) chosen." )
        return true;
    }
    else
    {
        new mapIndex = getMapNameIndex( firstWord );

        if( mapIndex >= 0 )
        {
            nomination_toggle( player_id, mapIndex );

            LOG( 1, "    ( sayHandlerForOneNomWords ) Just returning true, nomination_toggle(2) chosen." )
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

            LOG( 1, "    ( sayHandlerForOneNomWords ) Just returning true, nomination_menu(1) chosen." )
            return true;
        }
        else // if contains a prefix
        {
            for( new prefix_index = 0; prefix_index < g_mapPrefixCount; prefix_index++ )
            {
                LOG( 4, "( sayHandlerForOneNomWords ) firstWord: %s, \
                        g_mapPrefixes[%d]: %s, \
                        containi( %s, %s )? %d", \
                        firstWord, \
                        prefix_index, g_mapPrefixes[ prefix_index ], \
                        firstWord, g_mapPrefixes[ prefix_index ], containi( firstWord, g_mapPrefixes[ prefix_index ] ) )

                if( containi( firstWord, g_mapPrefixes[ prefix_index ] ) > -1 )
                {
                    buildNominationPartNameAttempt( player_id, g_mapPrefixes[ prefix_index ] );

                    LOG( 1, "    ( sayHandlerForOneNomWords ) Just returning true, nomination_menu(1) chosen." )
                    return true;
                }
            }
        }

        LOG( 4, "( sayHandlerForOneNomWords ) equali(%s, 'nom', 3)? %d, strlen(%s) > 5? %d", \
                firstWord, equali( firstWord, "nom", 3 ), \
                firstWord, strlen( firstWord ) > 5 )
    }

    LOG( 1, "    ( sayHandlerForOneNomWords ) Just returning false." )
    return false;
}

/**
 * Handles two user word said on chat.
 *
 * @return true when it is performed some nomination command, false otherwise
 */
stock bool:sayHandlerForTwoNomWords( player_id, firstWord[], secondWord[] )
{
    LOG( 128, "I AM ENTERING ON sayHandlerForTwoNomWords(3)" )

    if( strlen( firstWord ) > 5
        && equali( firstWord, "nom", 3 )
        && equali( firstWord[ strlen( firstWord ) - 4 ], "menu" ) )
    {
        // Calculate how much pages there are available.
        new nominationsMapsCount = ArraySize( g_nominationLoadedMapsArray );
        new lastPageNumber       = GET_LAST_PAGE_NUMBER( nominationsMapsCount, MAX_NOM_MENU_ITEMS_PER_PAGE )

        setCorrectMenuPage( player_id, secondWord, g_nominationPlayersMenuPages, lastPageNumber );
        nomination_menu( player_id );

        LOG( 1, "    ( sayHandlerForTwoNomWords ) Just returning true, nomination_menu(1) chosen." )
        return true;
    }
    else if( equali( firstWord, "nominate" )
             || equali( firstWord, "nom" ) )
    {
        buildNominationPartNameAttempt( player_id, secondWord );

        LOG( 1, "    ( sayHandlerForTwoNomWords ) Just returning true, nominationAttemptWithNamePart(2): %s", secondWord )
        return true;
    }
    else if( equali( firstWord, "cancel" ) )
    {
        new mapIndex = getMapNameIndex( secondWord );

        if( mapIndex >= 0 )
        {
            nomination_cancel( player_id, mapIndex );

            LOG( 1, "    ( sayHandlerForTwoNomWords ) Just returning true, nomination cancel option chosen." )
            return true;
        }
    }

    LOG( 1, "    ( sayHandlerForTwoNomWords ) Just returning false." )
    return false;
}

/**
 * Remove all the text from the string, except the first digits chain, to allow to open the menu
 * as `say galmenuPageNumber`. For example: `say galmenu50`.
 */
stock setCorrectMenuPage( player_id, pageString[], menuPages[], pagesCount )
{
    LOG( 128, "I AM ENTERING ON setCorrectMenuPage(4) pageString: %s, pagesCount: %d", pageString, pagesCount )

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

        LOG( 4, "( setCorrectMenuPage ) 1. pageString: %s", pageString )

        // When the page number start with a digit, we would erase all the string if not doing this.
        if( searchIndex == 0
            && isdigit( pageString[ 0 ] ) )
        {
            LOG( 4, "( setCorrectMenuPage ) 2. searchIndex: %d", searchIndex )

            do
            {
                searchIndex++;

            } while( isdigit( pageString[ searchIndex ] ) );

            pageString[ searchIndex ] = '^0';
        }
        else if( isdigit( pageString[ searchIndex ] ) )
        {
            LOG( 4, "( setCorrectMenuPage ) 3. searchIndex: %d", searchIndex )

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
            LOG( 4, "( setCorrectMenuPage ) 4. searchIndex: %d", searchIndex )
            pageString[ searchIndex ] = '^0';
        }
    }

    LOG( 4, "( setCorrectMenuPage ) 5. pageString: %s", pageString )

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
    LOG( 128, "I AM ENTERING ON nomination_menuHook(1) currentPage: %d", g_nominationPlayersMenuPages[ player_id ] )
    nomination_menu( player_id );
}

/**
 * Due there are several first menu options, take `VOTEMAP_FIRST_PAGE_ITEMS_COUNTING` items less.
 */
#define NOMINATION_FIRST_PAGE_ITEMS_COUNTING 1

stock getRecentMapsAndWhiteList( player_id, &isRecentMapNomBlocked, &isWhiteListNomBlock )
{
    isWhiteListNomBlock = ( IS_WHITELIST_ENABLED()
                            && get_pcvar_num( cvar_isWhiteListNomBlock ) );

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
    getRecentMapsAndWhiteList( %1, isRecentMapNomBlocked, isWhiteListNomBlock )

/**
 * Gather all maps that match the nomination.
 */
stock nomination_menu( player_id )
{
    LOG( 128, "I AM ENTERING ON nomination_menu(1) player_id: %d", player_id )

    new itemsCount;
    new nominationsMapsCount;

    new choice        [ MAX_MAPNAME_LENGHT + 32 ];
    new nominationMap [ MAX_MAPNAME_LENGHT ];
    new disabledReason[ MAX_SHORT_STRING ];

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
            LOG( 4, "( nomination_menu ) choice: %s", choice )

            menu_additem( menu, choice, _, ( disabledReason[ 0 ] == '^0' ? 0 : ( 1 << 26 ) ) );

        } // end the menu entry item calculation.

    } // end for 'mapIndex'.

    LOG( 4, "( nominationAttemptWithNamePart ) itemsCount: %d, mapIndex: %d", itemsCount, mapIndex )

    addMenuMoreBackExitOptions( menu, player_id, disabledReason, mapIndex < nominationsMapsCount, currentPageNumber > 0, itemsCount );
    menu_display( player_id, menu );
}

/**
 * This must to be called every time the Partial Nomination Menu will be show to the player for the
 * first time, i.e., when this is called from the forward cmd_say(1) handler.
 */
stock buildNominationPartNameAttempt( player_id, secondWord[] )
{
    LOG( 128, "I AM ENTERING ON buildNominationPartNameAttempt(2)" )

    if( task_exists( TASKID_NOMINATION_PARTIAL + player_id ) )
    {
        LOG( 4, "( buildNominationPartNameAttempt ) Blocking, the task already exists!" )
        return;
    }

    strtolower( secondWord );
    g_isSawPartialMatchFirstPage[ player_id ] = false;

    if( g_partialMatchFirstPageItems[ player_id ] )
    {
        TRY_TO_APPLY( ArrayClear, g_partialMatchFirstPageItems[ player_id ] )
    }
    else
    {
        g_partialMatchFirstPageItems[ player_id ] = ArrayCreate();
    }

    copy( g_nominationPartialNameAttempt[ player_id ], charsmax( g_nominationPartialNameAttempt[] ), secondWord );
    nominationAttemptWithNamePart( player_id );
}

/**
 * Used to allow the menu nominationAttemptWithNamePart(2) to have parameters within a default value.
 * It is because public functions are not allow to have a default value and we need this function
 * be public to allow it to be called from a set_task().
 */
public nominationAttemptWithNameHook( parameters[] )
{
    LOG( 128, "I AM ENTERING ON nominationAttemptWithNameHook(2) startSearchIndex: %d", parameters[ 1 ] )
    nominationAttemptWithNamePart( parameters[ 0 ], parameters[ 1 ] );
}

/**
 * Gather all maps that match the g_nominationPartialNameAttempt[ player_id ].
 *
 * @note ( playerName[], &phraseIdx, matchingSegment[] )
 */
stock nominationAttemptWithNamePart( player_id, startSearchIndex = 0 )
{
    LOG( 128, "I AM ENTERING ON nominationAttemptWithNamePart(2) startSearchIndex: %d", startSearchIndex )

    new itemsCount;
    new nominationsMapsCount;
    new menuGeneralItem[ MAX_SHORT_STRING ];

    startNominationMenuVariables( player_id );
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
    formatex( menuGeneralItem, charsmax( menuGeneralItem ),
            IS_COLORED_CHAT_ENABLED() ? "%L\R%d/%d" : "%L %d /%d",
            player_id, "GAL_LISTMAPS_TITLE", currentPageNumber + 1, lastPageNumber );

    new menu = menu_create( menuGeneralItem, "nomination_handlePartialMatch" );

    // Disables the menu paging.
    menu_setprop( menu, MPROP_PERPAGE, 0 );

    // Configure the menu buttons.
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_EXITNAME, menu, "EXIT" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_NEXTNAME, menu, "MORE" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_BACKNAME, menu, "BACK" )

    new arguments[ 9 ];

    arguments[ 0 ] = player_id;
    arguments[ 1 ] = mapIndex;
    arguments[ 2 ] = itemsCount;
    arguments[ 3 ] = startSearchIndex;
    arguments[ 4 ] = nominationsMapsCount;
    arguments[ 5 ] = isWhiteListNomBlock;
    arguments[ 6 ] = isRecentMapNomBlocked;
    arguments[ 7 ] = menu;
    arguments[ 8 ] = currentPageNumber;

    fillThePartialNominationMenu( arguments );
}

/**
 * This menu is pretty expensive and cannot let be running free. If the server has too much maps,
 * this will cause lag if this task is not split along the time when a single menu page is not filled
 * until the `MAX_NOM_MATCH_COUNT`.
 */
public fillThePartialNominationMenu( argumentsIn[] )
{
    LOG( 128, "I AM ENTERING ON fillThePartialNominationMenu(1)" )

    LOG( 4, "( fillThePartialNominationMenu ) player_id:             %d", argumentsIn[ 0 ] )
    LOG( 4, "( fillThePartialNominationMenu ) mapIndex:              %d", argumentsIn[ 1 ] )
    LOG( 4, "( fillThePartialNominationMenu ) itemsCount:            %d", argumentsIn[ 2 ] )
    LOG( 4, "( fillThePartialNominationMenu ) startSearchIndex:      %d", argumentsIn[ 3 ] )
    LOG( 4, "( fillThePartialNominationMenu ) nominationsMapsCount:  %d", argumentsIn[ 4 ] )
    LOG( 4, "( fillThePartialNominationMenu ) isWhiteListNomBlock:   %d", argumentsIn[ 5 ] )
    LOG( 4, "( fillThePartialNominationMenu ) isRecentMapNomBlocked: %d", argumentsIn[ 6 ] )
    LOG( 4, "( fillThePartialNominationMenu ) menu:                  %d", argumentsIn[ 7 ] )
    LOG( 4, "( fillThePartialNominationMenu ) currentPageNumber:     %d", argumentsIn[ 8 ] )

    new const player_id             = argumentsIn[ 0 ];
    new mapIndex                    = argumentsIn[ 1 ];
    new itemsCount                  = argumentsIn[ 2 ];
    new const startSearchIndex      = argumentsIn[ 3 ];
    new const nominationsMapsCount  = argumentsIn[ 4 ];
    new const isWhiteListNomBlock   = argumentsIn[ 5 ];
    new const isRecentMapNomBlocked = argumentsIn[ 6 ];
    new const menu                  = argumentsIn[ 7 ];
    new const currentPageNumber     = argumentsIn[ 8 ];

    // I am not using argumentsIn, because after the first call, all its values are trashed.
    new argumentsOut[ 9 ];
    new endSearchIndex = startSearchIndex + MAX_NOM_MATCH_COUNT;

    new choice        [ MAX_MAPNAME_LENGHT + 32 ];
    new nominationMap [ MAX_MAPNAME_LENGHT ];
    new disabledReason[ MAX_SHORT_STRING ];

    for( mapIndex = startSearchIndex; mapIndex < nominationsMapsCount && itemsCount < MAX_NOM_MENU_ITEMS_PER_PAGE; ++mapIndex )
    {
        if( mapIndex < endSearchIndex )
        {
            GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, nominationMap )

            if( containi( nominationMap, g_nominationPartialNameAttempt[ player_id ] ) > -1 )
            {
                // Save the map index for the current menu position
                g_menuMapIndexForPlayerArrays[ player_id ][ itemsCount ] = mapIndex;
                itemsCount++;

                // Start the menu entry item calculation:
                // 'nomination_menu(1)' and 'fillThePartialNominationMenu(2)'.
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
                    LOG( 4, "( fillThePartialNominationMenu ) choice: %s", choice )

                    menu_additem( menu, choice, _, ( disabledReason[ 0 ] == '^0' ? 0 : ( 1 << 26 ) ) );

                } // end the menu entry item calculation.

            } // end if 'containi'.

        }
        else
        {
            argumentsOut[ 0 ] = player_id;
            argumentsOut[ 1 ] = mapIndex;
            argumentsOut[ 2 ] = itemsCount;
            argumentsOut[ 3 ] = endSearchIndex;
            argumentsOut[ 4 ] = nominationsMapsCount;
            argumentsOut[ 5 ] = isWhiteListNomBlock;
            argumentsOut[ 6 ] = isRecentMapNomBlocked;
            argumentsOut[ 7 ] = menu;
            argumentsOut[ 8 ] = currentPageNumber;

            set_task( 1.0, "fillThePartialNominationMenu", TASKID_NOMINATION_PARTIAL + player_id, argumentsOut, sizeof argumentsOut );

            // The map search could take some time, as there are more than MAX_NOM_MATCH_COUNT unsuccessful matches.
            if( endSearchIndex == MAX_NOM_MATCH_COUNT )
            {
                color_chat( player_id, "%L", player_id, "GAL_NOM_MATCHES_MAX",
                        nominationsMapsCount / MAX_NOM_MATCH_COUNT, MAX_NOM_MATCH_COUNT );
            }

            // Block the menu from displaying before the search goes through all the possible items.
            return;
        }

    } // end for 'mapIndex'.

    new lastPosition = ArraySize( g_partialMatchFirstPageItems[ player_id ] ) - 1;

    LOG( 4, "( fillThePartialNominationMenu ) mapIndex: %d", mapIndex)
    LOG( 4, "( fillThePartialNominationMenu ) itemsCount: %d, lastPosition: %d", itemsCount, lastPosition )

    // If the last position is negative, then there is not last position, moreover this is the
    // first call to fillThePartialNominationMenu(3), then it means there any or one matches for
    // the partial map name nomination.
    if( lastPosition < 0
        && itemsCount < 1 )
    {
        // no matches; pity the poor fool
        color_chat( player_id, "%L", player_id, "GAL_NOM_FAIL_NOMATCHES", g_nominationPartialNameAttempt[ player_id ] );

        // Destroys the menu, as is was not used.
        TRY_TO_APPLY( menu_destroy, menu )
    }
    else
    {
        // this is kinda sexy; we put up a menu of the matches for them to pick the right one
        if( !g_isSawPartialMatchFirstPage[ player_id ] )
        {
            g_isSawPartialMatchFirstPage[ player_id ] = true;
            color_chat( player_id, "%L", player_id, "GAL_NOM_MATCHES", g_nominationPartialNameAttempt[ player_id ] );
        }

        // Old behavior: If this function is called within this parameter true, it means this is
        // the seconds time we are trying to show the same last page, so instead of showing an
        // empty page, we show the same page, but within the more button disabled.
        addMenuMoreBackExitOptions( menu, player_id, disabledReason, mapIndex < nominationsMapsCount, bool:currentPageNumber, itemsCount );

        menu_display( player_id, menu );
    }
}

stock addMenuMoreBackExitOptions( menu, player_id, menuGeneralItem[], bool:isToEnableMoreButton, bool:isToEnableBackButton, itemsCount )
{
    LOG( 128, "I AM ENTERING ON addMenuMoreBackExitOptions(5) isToEnableMoreButton: %d, \
            isToEnableBackButton: %d", isToEnableMoreButton, isToEnableBackButton )

    addMenuMoreBackButtons( menu, player_id, menuGeneralItem, isToEnableMoreButton, isToEnableBackButton, itemsCount );

    // To add the exit button
    formatex( menuGeneralItem, MAX_SHORT_STRING - 1, "%L", player_id, "EXIT" );
    menu_additem( menu, menuGeneralItem, _, 0 );
}

stock addMenuMoreBackButtons( menu, player_id, menuGeneralItem[], bool:isToEnableMoreButton, bool:isToEnableBackButton, itemsCount )
{
    LOG( 128, "I AM ENTERING ON addMenuMoreBackButtons(5) isToEnableBackButton: %d", isToEnableBackButton )

    // Force the menu control options to be present on the keys 8 (more), 9 (back) and 0 (exit).
    while( itemsCount < MAX_NOM_MENU_ITEMS_PER_PAGE )
    {
        itemsCount++;
        formatex( menuGeneralItem, MAX_SHORT_STRING - 1, "%L", player_id, "OFF" );
        menu_additem( menu, menuGeneralItem, _, 1 << 26 );

        // When using slot=1 this might break your menu. To achieve this functionality
        // menu_addblank2() should be used (AMXX 183 only).
        // menu_addblank( menu, 1 );
    }

    // Add some space from the control options and format the back button within the LANG file.
    menu_addblank( menu, 0 );
    formatex( menuGeneralItem, MAX_SHORT_STRING - 1, "%L", player_id, "BACK" );

    // If we are on the first page, disable the back option.
    if( isToEnableBackButton )
    {
        menu_additem( menu, menuGeneralItem, _, 0 );
    }
    else
    {
        menu_additem( menu, menuGeneralItem, _, 1 << 26 );
    }

    formatex( menuGeneralItem, MAX_SHORT_STRING - 1, "%L", player_id, "MORE" );

    // If there are more maps, add the more option
    if( isToEnableMoreButton )
    {
        menu_additem( menu, menuGeneralItem, _, 0 );
    }
    else
    {
        menu_additem( menu, menuGeneralItem, _, 1 << 26 );
    }
}

/**
 * This menu handler uses the convert_numeric_base(3) instead of menu_item_getinfo() to allow easy
 * conversion to the olde menu style, and also because it is working fine as it is.
 */
public nomination_handleMatchChoice( player_id, menu, item )
{
    LOG( 128, "I AM ENTERING ON nomination_handleMatchChoice(1) player_id: %d, menu: %d, item: %d", player_id, menu, item )

    // Let go to destroy the menu and clean some memory. As the menu is not paginated, the item 9
    // is the key 0 on the keyboard. Also, the item 8 is the key 9; 7, 8; 6, 7; 5, 6; 4, 5; etc.
    if( item < 0
        || item == 9 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        LOG( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, the menu is destroyed." )
        return PLUGIN_HANDLED;
    }

    // Due the first menu option to be 'Cancel all your Nominations', close the menu but if and
    // only if we are on the menu's first page.
    if( item == 0
        && g_nominationPlayersMenuPages[ player_id ] == 0 )
    {
        unnominatedDisconnectedPlayer( player_id );
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        LOG( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, the nominations were cancelled." )
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

        LOG( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, doing the back button." )
        return PLUGIN_HANDLED;
    }

    // If the 9 button item is hit, and we are on some page not the last one, we must to perform the more option.
    if( item == 8 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        g_nominationPlayersMenuPages[ player_id ]++;

        // Try to block/difficult players from performing the Denial Of Server attack.
        // set_task( 0.1, "nomination_menuHook", player_id );
        nomination_menuHook( player_id );

        LOG( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, doing the more button." )
        return PLUGIN_HANDLED;
    }

    // Due the first nomination menu option to be 'Cancel all your Nominations', take one item less 'item - 1'.
    new pageSeptalNumber = convert_numeric_base( g_nominationPlayersMenuPages[ player_id ], 10, MAX_NOM_MENU_ITEMS_PER_PAGE );
    item = convert_numeric_base( pageSeptalNumber * 10, MAX_NOM_MENU_ITEMS_PER_PAGE, 10 ) + item - NOMINATION_FIRST_PAGE_ITEMS_COUNTING;

    map_nominate( player_id, item );
    DESTROY_PLAYER_NEW_MENU_TYPE( menu )

    LOG( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, successful nomination." )
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
    LOG( 128, "I AM ENTERING ON nomination_handlePartialMatch(1) player_id: %d, menu: %d, item: %d", player_id, menu, item )

    // Let go to destroy the menu and clean some memory. As the menu is not paginated, the item 9
    // is the key 0 on the keyboard. Also, the item 8 is the key 9; 7, 8; 6, 7; 5, 6; 4, 5; etc.
    if( item < 0
        || item == 9 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        LOG( 1, "    ( nomination_handlePartialMatch ) Just Returning PLUGIN_HANDLED, the menu is destroyed." )
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
        // set_task( 0.1, "nominationAttemptWithNameHook", _, arguments, sizeof arguments );
        nominationAttemptWithNameHook( arguments );

        LOG( 1, "    ( nomination_handlePartialMatch ) Just Returning PLUGIN_HANDLED, doing the back button." )
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
        // set_task( 0.1, "nominationAttemptWithNameHook", _, arguments, sizeof arguments );
        nominationAttemptWithNameHook( arguments );

        LOG( 1, "    ( nomination_handlePartialMatch ) Just Returning PLUGIN_HANDLED, doing the more button." )
        return PLUGIN_HANDLED;
    }

    // We are using the 'nominationAttemptWithNamePart(2)'
    item = g_menuMapIndexForPlayerArrays[ player_id ][ item ];

    map_nominate( player_id, item );
    DESTROY_PLAYER_NEW_MENU_TYPE( menu )

    LOG( 1, "    ( nomination_handlePartialMatch ) Just Returning PLUGIN_HANDLED, successful nomination." )
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
    LOG( 128, "I AM ENTERING ON convert_numeric_base(3) number: %d (%d->%d)", \
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

    LOG( 1, "    ( convert_numeric_base ) Returning integer: %d", integer )
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
    LOG( 128, "I AM ENTERING ON fromDigitsRepresentation(2) origin_base: %d", origin_base )

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
    LOG( 128, "I AM ENTERING ON toDigitsRepresentation(2) origin_number: %d -> %d", origin_number, origin_base )
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
    LOG( 128, "I AM ENTERING ON convert_octal_to_decimal(1) octal_number: %d", octal_number )
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

    LOG( 1, "    ( convert_octal_to_decimal ) Returning decimal: %d", decimal )
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
    LOG( 128, "I AM ENTERING ON nomination_getPlayer(1) mapIndex: %d", mapIndex )

    new trieKey          [ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new mapNominationData[ MapNominationsType ];

    num_to_str( mapIndex, trieKey, charsmax( trieKey ) );
    LOG( 4, "( nomination_getPlayer ) trieKey: %s", trieKey )

    if( TrieKeyExists( g_reverseSearchNominationsTrie, trieKey ) )
    {
        TrieGetArray( g_reverseSearchNominationsTrie, trieKey, mapNominationData, sizeof mapNominationData );

        if( mapNominationData[ MapNomination_NominationIndex ] > -1 )
        {
            LOG( 1, "    ( nomination_getPlayer ) Returning mapNominationData[MapNomination_PlayerId]: %d", \
                   mapNominationData[ MapNomination_PlayerId ] )
            return mapNominationData[ MapNomination_PlayerId ];
        }
    }

    LOG( 1, "    ( nomination_getPlayer ) Returning mapNominationData[MapNomination_PlayerId]: %d", 0 )
    return 0;
}

/**
 * Gets the nominated map index, given the player id and the nomination index.
 *
 * @return -1 when there is no nomination, otherwise the map nomination index.
 */
stock getPlayerNominationMapIndex( player_id, nominationIndex )
{
    LOG( 256, "I AM ENTERING ON getPlayerNominationMapIndex(2) player_id: %d, nominationIndex: %d", player_id, nominationIndex )

    new trieKey             [ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new playerNominationData[ MAX_OPTIONS_IN_VOTE ];

    createPlayerNominationKey( player_id, trieKey, charsmax( trieKey ) );

    if( TrieKeyExists( g_forwardSearchNominationsTrie, trieKey ) )
    {
        TrieGetArray( g_forwardSearchNominationsTrie, trieKey, playerNominationData, sizeof playerNominationData );
    }
    else
    {
        LOG( 256, "    ( getPlayerNominationMapIndex ) Returning playerNominationData[nominationIndex]: %d", -1 )
        return -1;
    }

    LOG( 256, "    ( getPlayerNominationMapIndex ) Returning playerNominationData[nominationIndex]: %d", \
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
    LOG( 128, "I AM ENTERING ON setPlayerNominationMapIndex(3) player_id: %d, nominationIndex: %d, mapIndex: %d", \
            player_id, nominationIndex, mapIndex )

    if( nominationIndex < MAX_OPTIONS_IN_VOTE )
    {
        new originalMapIndex = updateNominationsForwardSearch( player_id, nominationIndex, mapIndex );
        updateNominationsReverseSearch( player_id, nominationIndex, mapIndex, originalMapIndex );
    }
    else
    {
        LOG( 1, "AMX_ERR_BOUNDS: %d. Was tried to set a wrong nomination bound index: %d", AMX_ERR_BOUNDS, nominationIndex )
        log_error( AMX_ERR_BOUNDS, "Was tried to set a wrong nomination bound index: %d", nominationIndex );
    }
}

stock updateNominationsForwardSearch( player_id, nominationIndex, mapIndex )
{
    LOG( 128, "I AM ENTERING ON updateNominationsForwardSearch(3) player_id: %d, \
            nominationIndex: %d, mapIndex: %d",  player_id, nominationIndex, mapIndex )

    // new openNominationIndex;
    // LOG( 1, "^n^n^ncountPlayerNominations: %d", countPlayerNominations( player_id, openNominationIndex ) )

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

    // LOG( 1, "^n^n^ncountPlayerNominations: %d", countPlayerNominations( player_id, openNominationIndex ) )
    LOG( 1, "    ( updateNominationsForwardSearch ) Returning originalMapIndex: %d", originalMapIndex )
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
    LOG( 128, "I AM ENTERING ON updateNominationsReverseSearch(4) player_id: %d, \
            nominationIndex: %d, mapIndex: %d, originalMapIndex: %d",  player_id, \
            nominationIndex,     mapIndex,     originalMapIndex )

    new nominatedIndex;
    LOG( 4, "( updateNominationsReverseSearch|in  ) ArraySize(g_nominatedMapsArray): %d", ArraySize( g_nominatedMapsArray ) )

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

    LOG( 4, "( updateNominationsReverseSearch|out ) ArraySize(g_nominatedMapsArray): %d", ArraySize( g_nominatedMapsArray ) )
}

stock countPlayerNominations( player_id, &openNominationIndex )
{
    LOG( 128, "I AM ENTERING ON countPlayerNominations(2) player_id: %d, openNominationIndex: %d", \
            player_id, openNominationIndex )

    new nominationCount;
    LOG( 4, "( countPlayerNominations ) ArraySize(g_nominatedMapsArray): %d", ArraySize( g_nominatedMapsArray ) )

    new trieKey[ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new playerNominationData[ MAX_OPTIONS_IN_VOTE ];

    openNominationIndex = 0;
    createPlayerNominationKey( player_id, trieKey, charsmax( trieKey ) );

    if( TrieKeyExists( g_forwardSearchNominationsTrie, trieKey ) )
    {
        TrieGetArray( g_forwardSearchNominationsTrie, trieKey, playerNominationData, sizeof playerNominationData );

        for( new nominationIndex = 0; nominationIndex < MAX_OPTIONS_IN_VOTE; ++nominationIndex )
        {
            LOG( 4, "( countPlayerNominations ) playerNominationData[%d]: %d", \
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

    LOG( 4, "( countPlayerNominations ) nominationCount: %d, trieKey: %s, openNominationIndex: %d", \
            nominationCount, trieKey, openNominationIndex )

    return nominationCount;
}

stock createPlayerNominationKey( player_id, trieKey[], trieKeyLength )
{
    LOG( 256, "I AM ENTERING ON createPlayerNominationKey(3) player_id: %d, trieKeyLength: %d", \
            player_id, trieKeyLength )

    new ipSize;
    ipSize = get_user_ip( player_id, trieKey, trieKeyLength );

    if( !ipSize )
    {
        ipSize += formatex( trieKey[ ipSize ], trieKeyLength - ipSize, "id%d-", player_id );
    }

    get_user_authid( player_id, trieKey[ ipSize ], trieKeyLength - ipSize );
    LOG( 256, "( createPlayerNominationKey ) player_id: %d, trieKey: %s,", player_id, trieKey )
}

stock nomination_toggle( player_id, mapIndex )
{
    LOG( 128, "I AM ENTERING ON nomination_toggle(2) player_id: %d, mapIndex: %d", player_id, mapIndex )
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
    LOG( 128, "I AM ENTERING ON nomination_cancel(2) player_id: %d, mapIndex: %d", player_id, mapIndex )

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
                color_chat( player_id, "%L", player_id, "GAL_CANCEL_FAIL_SOMEONEELSE", mapName, player_name );
            }
            else
            {
                color_chat( player_id, "%L", player_id, "GAL_CANCEL_FAIL_WASNOTYOU", mapName );
            }
        }
    }
}

stock is_to_block_map_nomination( player_id, mapName[] )
{
    LOG( 128, "I AM ENTERING ON is_to_block_map_nomination(2) player_id: %d, mapName: %d", player_id, mapName )

    // nominations can only be made if a vote isn't already in progress
    if( g_voteStatus & IS_VOTE_IN_PROGRESS )
    {
        color_chat( player_id, "%L", player_id, "GAL_NOM_FAIL_INPROGRESS" );
        LOG( 1, "    ( is_to_block_map_nomination ) Just Returning/blocking, the voting is in progress." )
    }

    // and if the outcome of the vote hasn't already been determined
    else if( g_voteStatus & IS_VOTE_OVER )
    {
        color_chat( player_id, "%L", player_id, "GAL_NOM_FAIL_VOTEOVER" );
        LOG( 1, "    ( is_to_block_map_nomination ) Just Returning/blocking, the voting is over." )
    }

    // players can not nominate the current map
    else if( mapName[0]
             && equali( g_currentMapName, mapName ) )
    {
        color_chat( player_id, "%L", player_id, "GAL_NOM_FAIL_CURRENTMAP", g_currentMapName );
        LOG( 1, "    ( is_to_block_map_nomination ) Just Returning/blocking, cannot nominate the current map." )
    }

    // players may not be able to nominate recently played maps
    else if( mapName[0]
             && g_recentListMapsArray
             && ArraySize( g_recentListMapsArray )
             && map_isTooRecent( mapName )
             && ( ( get_pcvar_num( cvar_recentNomMapsAllowance ) == 2
                    && !( get_user_flags( player_id ) & ADMIN_MAP ) )
                  || get_pcvar_num( cvar_recentNomMapsAllowance ) == 0 ) )
    {
        color_chat( player_id, "%L", player_id, "GAL_NOM_FAIL_TOORECENT", mapName );
        color_chat( player_id, "%L", player_id, "GAL_NOM_FAIL_TOORECENT_HLP" );
        LOG( 1, "    ( is_to_block_map_nomination ) Just Returning/blocking, cannot nominate recent maps." )
    }
    else
    {
        LOG( 1, "    ( is_to_block_map_nomination ) Just Returning/allowing, the map nominations." )
        return false;
    }

    return true;
}

stock map_nominate( player_id, mapIndex )
{
    LOG( 128, "I AM ENTERING ON map_nominate(2) player_id: %d, mapIndex: %d", player_id, mapIndex )
    new mapName[ MAX_MAPNAME_LENGHT ];

    // get the nominated map name
    GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, mapName )
    LOG( 4, "( map_nominate ) mapIndex: %d, mapName: %s", mapIndex, mapName )

    if( !is_to_block_map_nomination( player_id, mapName ) )
    {
        new bool:isWhiteListNomBlock = ( IS_WHITELIST_ENABLED()
                                         && get_pcvar_num( cvar_isWhiteListNomBlock ) );

        if( isWhiteListNomBlock )
        {
            if( IS_WHITELIST_BLOCKING( isWhiteListNomBlock, mapName ) )
            {
                color_chat( player_id, "%L", player_id, "GAL_NOM_FAIL_WHITELIST", mapName );
                LOG( 1, "    ( map_nominate ) The map: %s, was blocked by the whitelist map setting.", mapName )
                return;
            }
        }

        try_to_add_the_nomination( player_id, mapIndex, mapName );
    }
}

stock try_to_add_the_nomination( player_id, mapIndex, mapName[] )
{
    LOG( 128, "I AM ENTERING ON try_to_add_the_nomination(3) player_id: %d, mapIndex: %d, mapName: %s", \
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
        color_chat( player_id, "%L", player_id, "GAL_NOM_FAIL_ALREADY", mapName );
    }
    else
    {
        // The player nomination is the same as some other player before. And it is not allowed.
        new player_name[ MAX_PLAYER_NAME_LENGHT ];
        GET_USER_NAME( nominatorPlayerId, player_name )

        color_chat( player_id, "%L", player_id, "GAL_NOM_FAIL_SOMEONEELSE", mapName, player_name );
        color_chat( player_id, "%L", player_id, "GAL_NOM_FAIL_SOMEONEELSE_HLP" );
    }
}

stock add_my_nomination( player_id, mapIndex, mapName[] )
{
    LOG( 128, "I AM ENTERING ON add_my_nomination(0) player_id: %d, mapIndex: %d, mapName: %s", \
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
        color_chat( player_id, "%L", player_id, "GAL_NOM_GOOD_HLP" );
    }

    LOG( 4, "( try_to_add_the_nomination ) openNominationIndex: %d, mapName: %s", openNominationIndex, mapName )
}

stock show_my_nominated_maps( player_id, maxPlayerNominations )
{
    LOG( 128, "I AM ENTERING ON show_my_nominated_maps(2) player_id: %d, maxPlayerNominations: %d", \
            player_id, maxPlayerNominations )

    new mapIndex;
    new copiedChars;

    new nominatedMaps   [ MAX_COLOR_MESSAGE ];
    new nominatedMapName[ MAX_MAPNAME_LENGHT ];

    for( new nominationIndex = 0; nominationIndex < maxPlayerNominations; ++nominationIndex )
    {
        if( ( mapIndex = getPlayerNominationMapIndex( player_id, nominationIndex ) ) < 0 )
        {
            continue;
        }

        GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, nominatedMapName )

        if( copiedChars )
        {
            copiedChars += copy( nominatedMaps[ copiedChars ],
                    charsmax( nominatedMaps ) - copiedChars, ", " );
        }

        copiedChars += copy( nominatedMaps[ copiedChars ],
                charsmax( nominatedMaps ) - copiedChars, nominatedMapName );
    }

    color_chat( player_id, "%L", player_id, "GAL_NOM_FAIL_TOOMANY", maxPlayerNominations, nominatedMaps );
    color_chat( player_id, "%L", player_id, "GAL_NOM_FAIL_TOOMANY_HLP" );
}

/**
 * Print to chat all players nominations available. This is usually called by 'say noms'.
 */
public nomination_list()
{
    LOG( 128, "I AM ENTERING ON nomination_list(0)" )

    new mapIndex;
    new copiedChars;
    new nomMapCount;

    /**
     * Used to avoid an empty list to be showed to the player. Bug reported on:
     * https://forums.alliedmods.net/showpost.php?p=2520787&postcount=677
     */
    new bool:isFlushed;

    new mapsList[ 101 ];
    new mapName [ MAX_MAPNAME_LENGHT ];

    new nominatedMapsCount = ArraySize( g_nominatedMapsArray );

    for( new nominationIndex = 0; nominationIndex < nominatedMapsCount; ++nominationIndex )
    {
        if( ( mapIndex = ArrayGetCell( g_nominatedMapsArray, nominationIndex ) ) < 0 )
        {
            continue;
        }
        else
        {
            // list 4 maps per chat line
            if( nomMapCount == 4 )
            {
                isFlushed = true;
                printNominationList( mapsList );

                copiedChars = 0;
                nomMapCount = 0;
            }

            ++nomMapCount;
            GET_MAP_NAME( g_nominationLoadedMapsArray, mapIndex, mapName )

            if( copiedChars )
            {
                copiedChars += copy( mapsList[ copiedChars ], charsmax( mapsList ) - copiedChars, "^1, ^4" );
            }

            copiedChars += copy( mapsList[ copiedChars ], charsmax( mapsList ) - copiedChars, mapName );
        }
    }

    printNominationList( mapsList, isFlushed );
}

/**
 * Print a nomination map list to the user. When the list is empty, it does show no nominations
 * available.
 *
 * param mapsList      the list of maps to be printed to the user.
 * @param isFlushed    whether the list has already been printed to the user after the `say noms` command.
 */
stock printNominationList( mapsList[], isFlushed=false )
{
    LOG( 128, "I AM ENTERING ON printNominationList(2)" )
    LOG( 128, "( printNominationList ) isFlushed: %d", isFlushed )
    LOG( 128, "( printNominationList ) mapsList:  %s", mapsList )

    if( mapsList[ 0 ] )
    {
        color_chat( 0, "%L: ^4%s", LANG_PLAYER, "GAL_NOMINATIONS", mapsList );
        mapsList[ 0 ] = '^0';
    }
    else if( !isFlushed )
    {
        color_chat( 0, "%L: ^4%L", LANG_PLAYER, "GAL_NOMINATIONS", LANG_PLAYER, "NONE" );
    }
}

stock getMapNameIndex( mapName[] )
{
    LOG( 128, "I AM ENTERING ON getMapNameIndex(1) mapName: %s", mapName )

    if( TrieKeyExists( g_nominationLoadedMapsTrie, mapName ) )
    {
        new mapIndex;
        TrieGetCell( g_nominationLoadedMapsTrie, mapName, mapIndex );

        LOG( 1, "    ( getMapNameIndex ) Just Returning, mapIndex: %d (mapName)", mapIndex )
        return mapIndex;
    }

    LOG( 1, "    ( getMapNameIndex ) Just Returning, mapIndex: %d", -1 )
    return -1;
}

/**
 * The command `say recentmaps` and its menu implementation.
 */
public cmd_listrecent( player_id )
{
    LOG( 128, "I AM ENTERING ON cmd_listrecent(1) player_id: %d", player_id )
    new recentMapCount;

    if( g_recentListMapsArray
        && ( recentMapCount = ArraySize( g_recentListMapsArray ) ) > 0 )
    {
        switch( get_pcvar_num( cvar_banRecentStyle ) )
        {
            case 1:
            {
                new copiedChars;
                new recentMapName    [ MAX_MAPNAME_LENGHT ];
                new recentMapsMessage[ MAX_COLOR_MESSAGE ];

                for( new mapIndex = 0; mapIndex < recentMapCount; ++mapIndex )
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

                color_chat( 0, "%L: %s", LANG_PLAYER, "GAL_MAP_RECENTMAPS", recentMapsMessage[ 2 ] );
            }
            case 2:
            {
                new recentMapName[ MAX_MAPNAME_LENGHT ];

                for( new mapIndex = 0; mapIndex < recentMapCount && mapIndex < 5; ++mapIndex )
                {
                    ArrayGetString( g_recentListMapsArray, mapIndex, recentMapName, charsmax( recentMapName ) );

                    color_chat( 0, "%L ( %i );: %s", \
                            LANG_PLAYER, "GAL_MAP_RECENTMAP", mapIndex + 1, recentMapName );
                }
            }
            case 3:
            {
                showRecentMapsListMenu( player_id );
            }
        }
    }

    LOG( 1, "    ( cmd_listrecent ) Returning PLUGIN_CONTINUE" )
    return PLUGIN_CONTINUE;
}

/**
 * Build and displays the `say recentmaps` menu.
 */
public showRecentMapsListMenu( player_id )
{
    LOG( 128, "I AM ENTERING ON showRecentMapsListMenu(1) player_id: %d", player_id )

    new mapIndex;
    new itemsCount;

    new recentMapName[ MAX_MAPNAME_LENGHT ];
    new menuOptionString[ 64 ];

    // Calculate how much pages there are available.
    new recentMapCount    = ArraySize( g_recentListMapsArray );
    new currentPageNumber = g_recentMapsMenuPages[ player_id ];
    new lastPageNumber    = GET_LAST_PAGE_NUMBER( recentMapCount, MAX_MENU_ITEMS_PER_PAGE )

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
    for( ; mapIndex < recentMapCount && itemsCount < MAX_MENU_ITEMS_PER_PAGE; ++mapIndex, ++itemsCount )
    {
        LOG( 4, "( showRecentMapsListMenu ) mapIndex: %d", mapIndex )
        ArrayGetString( g_recentListMapsArray, mapIndex, recentMapName, charsmax( recentMapName ) );

        menu_additem( menu, recentMapName );
        LOG( 4, "( showRecentMapsListMenu ) recentMapName: %s", recentMapName )
    }

    LOG( 4, "( showRecentMapsListMenu ) itemsCount: %d, mapIndex: %d", itemsCount, mapIndex )
    addMenuMoreBackOptions( menu, player_id, menuOptionString, mapIndex < recentMapCount, currentPageNumber > 0, itemsCount );

    // To display the menu.
    menu_display( player_id, menu );
}

stock addMenuMoreBackOptions( menu, player_id, menuOptionString[], bool:isToEnableMoreButton, bool:isToEnableBackButton, itemsCount )
{
    LOG( 128, "I AM ENTERING ON addMenuMoreBackOptions(5) isToEnableMoreButton: %d, \
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

/**
 * This menu handler uses the convert_numeric_base(3) instead of menu_item_getinfo() to allow easy
 * conversion to the olde menu style, and also because it is working fine as it is.
 */
public cmd_listrecent_handler( player_id, menu, item )
{
    LOG( 128, "I AM ENTERING ON cmd_listrecent_handler(3) player_id: %d, menu: %d, item: %d", player_id, menu, item )

    // Let go to destroy the menu and clean some memory. As the menu is not paginated, the item 9
    // is the key 0 on the keyboard. Also, the item 8 is the key 9; 7, 8; 6, 7; 5, 6; 4, 5; etc.
    if( item < 0
        || ( item == 9
             && g_recentMapsMenuPages[ player_id ] == 0 ) )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        LOG( 1, "    ( cmd_listrecent_handler ) Just Returning PLUGIN_HANDLED, as menu is destroyed." )
        return PLUGIN_HANDLED;
    }

    // If the 0 button item is hit, and we are not on the first page, we must to perform the back option.
    if( item == 9
        && g_recentMapsMenuPages[ player_id ] > 0 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        g_recentMapsMenuPages[ player_id ] ? g_recentMapsMenuPages[ player_id ]-- : 0;

        // Try to block/difficult players from performing the Denial Of Server attack.
        // set_task( 0.1, "showRecentMapsListMenu", player_id );
        showRecentMapsListMenu( player_id );

        LOG( 1, "    ( cmd_listrecent_handler ) Just Returning PLUGIN_HANDLED, doing the back button." )
        return PLUGIN_HANDLED;
    }

    // If the 9 button item is hit, and we are on some page not the last one, we must to perform the more option.
    if( item == 8 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        g_recentMapsMenuPages[ player_id ]++;

        // Try to block/difficult players from performing the Denial Of Server attack.
        // set_task( 0.1, "showRecentMapsListMenu", player_id );
        showRecentMapsListMenu( player_id );

        LOG( 1, "    ( cmd_listrecent_handler ) Just Returning PLUGIN_HANDLED, doing the more button." )
        return PLUGIN_HANDLED;
    }

    // Just keep showing the menu until the exit button is pressed.
    menu_display( player_id, menu );

    LOG( 1, "    ( cmd_listrecent_handler ) Just Returning PLUGIN_HANDLED." )
    return PLUGIN_HANDLED;
}

/**
 * The command `gal_changelevel`.
 */
public cmd_changeLevel( player_id, level, cid )
{
    LOG( 128, "I AM ENTERING ON cmd_changeLevel(3) player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOG( 1, "    ( cmd_changeLevel ) Returning PLUGIN_CONTINUE" )
        return PLUGIN_CONTINUE;
    }

    new argumentsCount = read_argc();

    if( argumentsCount > 1 )
    {
        new arguments[ MAX_BIG_BOSS_STRING ];

        read_args( arguments, charsmax( arguments ) );
        remove_quotes( arguments );

        LOG( 8, "( cmd_changeLevel ) " )
        LOG( 8, "( cmd_changeLevel ) argumentsCount: %d, arguments: %s", argumentsCount, arguments )

        // Immediately change the level, instead of wait the changing count down, if it is enabled.
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

    LOG( 1, "    ( cmd_changeLevel ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

/**
 * The command `gal_cancelvote`.
 */
public cmd_cancelVote( player_id, level, cid )
{
    LOG( 128, "I AM ENTERING ON cmd_cancelVote(3) player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOG( 1, "    ( cmd_cancelVote ) Returning PLUGIN_CONTINUE" )
        return PLUGIN_CONTINUE;
    }

    // If the are on debug mode, just to erase everything, as may be there something overlapping.
#if defined DEBUG
    cancelVoting( true );

    // To avoid the warning unreachable code.
    if( !g_dummy_value )
    {
        LOG( 1, "    ( cmd_cancelVote ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }
#endif

    if( g_voteStatus & IS_VOTE_IN_PROGRESS )
    {
        color_chat( 0, "%L", LANG_SERVER, "VOT_CANC" );
        cancelVoting( true );
    }
    else
    {
        color_chat( 0, "%L", LANG_SERVER, "NO_VOTE_CANC" );
    }

    LOG( 1, "    ( cmd_cancelVote ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

stock bool:approveTheVotingStartLight()
{
    LOG( 128, "I AM ENTERING ON approveTheVotingStartLight(0)" )

    // block the voting on some not allowed situations/cases
    if( get_real_players_number() == 0)
    {
        LOG( 1, "    ( approveTheVotingStartLight ) Returning false 0 players on the server." )
        return false;
    }

    // the rounds start delay task could be running
    remove_task( TASKID_START_VOTING_DELAYED );

    // If the voting menu deletion task is running, remove it then delete the menus right now.
    if( remove_task( TASKID_DELETE_USERS_MENUS ) )
    {
        vote_resetStats();
    }

    LOG( 1, "    ( approveTheVotingStart ) Returning true, due passed by all requirements." )
    return true;
}

/**
 * The command `gal_votemap`. It will receive a list of maps and will to perform a map voting as if
 * it was an automatic or forced one. The only difference would be the maps it will use. Instead of
 * random, they will the the maps passed to the command `gal_votemap map1 map2 map3 ... map9`.
 *
 * Issue: Add the command `gal_votemap` https://github.com/addonszz/Galileo/issues/48
 */
public cmd_voteMap( player_id, level, cid )
{
    LOG( 128, "I AM ENTERING ON cmd_voteMap(3) player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOG( 1, "    ( cmd_voteMap ) Returning PLUGIN_CONTINUE" )
        return PLUGIN_CONTINUE;
    }

    // There is a real strange `Run time error 5: memory access` bug around these declarations,
    // if you use the approveTheVotingStart(1) instead of the approveTheVotingStartLight(1)!
    if( g_voteStatus & IS_VOTE_IN_PROGRESS )
    {
        color_chat( player_id, "%L", player_id, "GAL_VOTE_INPROGRESS" );
    }
    else if( approveTheVotingStartLight() )
    {
        new argumentsCount;
        new arguments[ MAX_BIG_BOSS_STRING ];

        read_args( arguments, charsmax( arguments ) );
        remove_quotes( arguments );

        argumentsCount = read_argc();
        log_amx( "%L: %s", LANG_SERVER, "GAL_VOTE_START", arguments );

        LOG( 8, "( cmd_voteMap ) " )
        LOG( 8, "( cmd_voteMap ) arguments: %s", arguments )

        if( argumentsCount > 1
            && g_isExtendmapAllowStay
            || argumentsCount > 2 )
        {
            new argument[ MAX_MAPNAME_LENGHT  ];
            new bool:isWhitelistEnabled = IS_WHITELIST_ENABLED();

            // If the voteMapMenuBuilder(1) added some maps, they will be around here, but we do not
            // want to them be here as this is a full spec command.
            clearTheVotingMenu();

            // The initial settings setup
            g_voteMapStatus = IS_DISABLED_VOTEMAP_EXIT;

            // To start from 1 because the first argument 0, is the command line name `gal_startvote`.
            for( new index = 1; index < argumentsCount; index++ )
            {
                new cache;

                read_argv( index, argument, charsmax( argument ) );
                LOG( 8, "( cmd_voteMap ) argument[%d]: %s", index, argument )

                if( IS_WHITELIST_BLOCKING( isWhitelistEnabled, argument ) )
                {
                    console_print( player_id, "%s: %L", argument, player_id, "GAL_MATCH_WHITELIST" );
                    LOG( 8, "    ( cmd_voteMap ) %s: %L", argument, player_id, "GAL_MATCH_WHITELIST" )

                    // We do not need to print help, as the Whilelist message is clear.
                    goto invalid_map_provited;
                }
                else if( IS_MAP_VALID( argument ) )
                {
                    LOG( 8, "    ( cmd_voteMap ) argument is a valid map." )
                    addMapToTheVotingMenu( argument, "" );
                }
                else if( -1 < ( cache = containi( argument, "nointro" ) )
                         && cache < 2 )
                {
                    LOG( 8, "    ( cmd_voteMap ) Entering on argument `nointro`" )
                    g_voteMapStatus |= IS_DISABLED_VOTEMAP_INTRO;
                }
                else if( -1 < ( cache = containi( argument, "norunoff" ) )
                         && cache < 2 )
                {
                    LOG( 8, "    ( cmd_voteMap ) Entering on argument `norunoff`" )
                    g_voteMapStatus |= IS_DISABLED_VOTEMAP_RUNOFF;
                }
                else if( -1 < ( cache = containi( argument, "noextension" ) )
                         && cache < 2 )
                {
                    LOG( 8, "    ( cmd_voteMap ) Entering on argument `noextension`" )
                    g_voteMapStatus |= IS_DISABLED_VOTEMAP_EXTENSION;
                }
                else if( -1 < ( cache = containi( argument, "loadnominations" ) )
                         && cache < 2 )
                {
                    LOG( 8, "    ( cmd_voteMap ) Entering on argument `loadnominations`" )

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
                    LOG( 1, "    ( cmd_voteMap ) Returning PLUGIN_HANDLED" )
                    return PLUGIN_HANDLED;
                }
            }

            LOG( 8, "    ( cmd_voteMap ) g_voteMapStatus: %d", g_voteMapStatus )
            startVoteMapVoting( player_id );
        }
        else
        {
            showGalVoteMapHelp( player_id );
        }
    }

    LOG( 1, "    ( cmd_voteMap ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

stock startVoteMapVoting( player_id )
{
    LOG( 128, "I AM ENTERING ON startVoteMapVoting(1) player_id: %s", player_id )

    if( g_totalVoteOptions > 0
        && !( g_voteMapStatus & IS_DISABLED_VOTEMAP_EXTENSION )
        && g_isExtendmapAllowStay
        || g_totalVoteOptions > 1 )
    {
        // Load the voting time
        SET_VOTING_TIME_TO( g_votingSecondsRemaining, cvar_voteDuration )

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
        color_chat( 0, "%L", LANG_PLAYER, "GAL_VOTE_NOMAPS" );

        finalizeVoting();
        showGalVoteMapHelp( player_id );
    }
}

/**
 * This is the `gal_votemap` admin's command line help displayer.
 */
stock showGalVoteMapHelp( player_id, index = 0, argument[] = {0} )
{
    LOG( 128, "I AM ENTERING ON showGalVoteMapHelp(1) argument: %s", argument )

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
    LOG( 128, "I AM ENTERING ON voteMapMenuBuilder(0) player_id: %d", player_id )

    // The initial settings setup
    g_voteMapStatus = IS_DISABLED_VOTEMAP_EXIT;

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
    LOG( 128, "I AM ENTERING ON displayVoteMapMenuHook(1) currentPage: %d", g_voteMapMenuPages[ player_id ] )
    displayVoteMapMenu( player_id );
}

/**
 * This is the main menu `say galmenu` builder.
 */
stock displayVoteMapMenu( player_id )
{
    LOG( 128, "I AM ENTERING ON displayVoteMapMenu(1) player_id: %d", player_id )

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
            LOG( 4, "( displayVoteMapMenu ) choice: %s", choice )

            menu_additem( menu, choice, _, ( disabledReason[ 0 ] == '^0' ? 0 : ( 1 << 26 ) ) );

        } // end the menu entry item calculation.

    } // end for 'mapIndex'.

    LOG( 4, "( displayVoteMapMenu ) itemsCount: %d, mapIndex: %d", itemsCount, mapIndex )

    addMenuMoreBackStartOptions( menu, player_id, disabledReason, mapIndex < nominationsMapsCount, currentPageNumber > 0, itemsCount );
    menu_display( player_id, menu );
}

stock addMenuMoreBackStartOptions( menu, player_id, disabledReason[], bool:isToEnableMoreButton, bool:isToEnableBackButton, itemsCount )
{
    LOG( 128, "I AM ENTERING ON addMenuMoreBackStartOptions(5) isToEnableMoreButton: %d", isToEnableMoreButton )
    addMenuMoreBackButtons( menu, player_id, disabledReason, isToEnableMoreButton, isToEnableBackButton, itemsCount );

    // To add the exit button
    if( g_totalVoteOptions > 0
        && !( g_voteMapStatus & IS_DISABLED_VOTEMAP_EXTENSION )
        && g_isExtendmapAllowStay
        || g_totalVoteOptions > 1 )
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
 *
 * This menu handler uses the convert_numeric_base(3) instead of menu_item_getinfo() to allow easy
 * conversion to the olde menu style, and also because it is working fine as it is.
 */
public handleDisplayVoteMap( player_id, menu, item )
{
    LOG( 128, "I AM ENTERING ON handleDisplayVoteMap(3) player_id: %d, menu: %d, item: %d", player_id, menu, item )

    // Let go to destroy the menu and clean some memory. As the menu is not paginated, the item 9
    // is the key 0 on the keyboard. Also, the item 8 is the key 9; 7, 8; 6, 7; 5, 6; 4, 5; etc.
    if( item < 0
        || ( item == 9
             && !( g_totalVoteOptions > 0
                   && !( g_voteMapStatus & IS_DISABLED_VOTEMAP_EXTENSION )
                   && g_isExtendmapAllowStay
                   || g_totalVoteOptions > 1 ) ) )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        LOG( 1, "    ( handleDisplayVoteMap ) Just Returning PLUGIN_HANDLED, the menu is destroyed." )
        return PLUGIN_HANDLED;
    }

    // To start the voting
    if( item == 9
        && ( g_totalVoteOptions > 0
             && !( g_voteMapStatus & IS_DISABLED_VOTEMAP_EXTENSION )
             && g_isExtendmapAllowStay
             || g_totalVoteOptions > 1 ) )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        displayVoteMapMenuCommands( player_id );

        LOG( 1, "    ( handleDisplayVoteMap ) Just Returning PLUGIN_HANDLED, starting the voting." )
        return PLUGIN_HANDLED;
    }

    switch( item )
    {
        // If the 8 button item is hit, and we are not on the first page, we must to perform the back option.
        case 7:
        {
            DESTROY_PLAYER_NEW_MENU_TYPE( menu )
            g_voteMapMenuPages[ player_id ] ? g_voteMapMenuPages[ player_id ]-- : 0;

            // Try to block/difficult players from performing the Denial Of Server attack.
            // set_task( 0.1, "displayVoteMapMenuHook", player_id );
            displayVoteMapMenuHook( player_id );

            LOG( 1, "    ( handleDisplayVoteMap ) Just Returning PLUGIN_HANDLED, doing the back button." )
            return PLUGIN_HANDLED;
        }
        // If the 9 button item is hit, and we are on some page not the last one, we must to perform the more option.
        case 8:
        {
            DESTROY_PLAYER_NEW_MENU_TYPE( menu )
            g_voteMapMenuPages[ player_id ]++;

            // Try to block/difficult players from performing the Denial Of Server attack.
            // set_task( 0.1, "displayVoteMapMenuHook", player_id );
            displayVoteMapMenuHook( player_id );

            LOG( 1, "    ( handleDisplayVoteMap ) Just Returning PLUGIN_HANDLED, doing the more button." )
            return PLUGIN_HANDLED;
        }
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
                LOG( 8, "    ( cmd_voteMap ) Entering on argument `nointro`" )
                TOGGLE_BIT_FLAG_ON_OFF( g_voteMapStatus, IS_DISABLED_VOTEMAP_INTRO )
            }
            case 1:
            {
                LOG( 8, "    ( cmd_voteMap ) Entering on argument `norunoff`" )
                TOGGLE_BIT_FLAG_ON_OFF( g_voteMapStatus, IS_DISABLED_VOTEMAP_RUNOFF )
            }
            case 2:
            {
                LOG( 8, "    ( cmd_voteMap ) Entering on argument `noextension`" )
                TOGGLE_BIT_FLAG_ON_OFF( g_voteMapStatus, IS_DISABLED_VOTEMAP_EXTENSION )
            }
            case 3:
            {
                // Load on the nominations maps.
                loadOnlyNominationVoteChoices();

                // This option cannot be undone, to reduce the code complexity.
                g_voteMapStatus |= IS_ENABLED_VOTEMAP_NOMINATIONS;
                LOG( 8, "    ( cmd_voteMap ) Entering on argument `loadnominations`" )
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

    LOG( 1, "    ( handleDisplayVoteMap ) Just Returning PLUGIN_HANDLED, successful nomination." )
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
    LOG( 128, "I AM ENTERING ON displayVoteMapMenuCommands(1) player_id: %d", player_id )

    new mapIndex;
    new info[ 1 ];

    new choice          [ MAX_SHORT_STRING ];
    new menuOptionString[ MAX_SHORT_STRING ];

    // To create the menu
    formatex( choice, charsmax( choice ), "%L", player_id, "CMD_MENU" );
    new menu = menu_create( choice, "handleDisplayVoteMapCommands" );

    // The first menus items
    formatex( choice, charsmax( choice ), "%L%s (%d)", player_id, "GAL_VOTE_START", COLOR_YELLOW, g_totalVoteOptions );
    menu_additem( menu, choice, { -1 }, g_totalVoteOptions > 0
                                        && g_isExtendmapAllowStay
                                        && !( g_voteMapStatus & IS_DISABLED_VOTEMAP_EXTENSION )
                                        || g_totalVoteOptions > 1 ? 0 : ( 1 << 26 ) );

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

            LOG( 4, "( displayVoteMapMenuCommands ) choice: %s, info[0]: %d", choice, info[ 0 ] )
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
 *
 * This menu handler uses the menu_item_getinfo() instead of convert_numeric_base(3) because it was
 * recently written and there is not need to use the old menu's style with specific handler.
 */
public handleDisplayVoteMapCommands( player_id, menu, item )
{
    LOG( 128, "I AM ENTERING ON handleDisplayVoteMapCommands(3) player_id: %d, menu: %d, item: %d", player_id, menu, item )

    if( item == MENU_EXIT )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )
        displayVoteMapMenu( player_id );

        LOG( 1, "    ( handleDisplayVoteMapCommands ) Just Returning PLUGIN_HANDLED, returning to the main menu." )
        return PLUGIN_HANDLED;
    }

    if( item < 0 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( menu )

        LOG( 1, "    ( handleDisplayVoteMapCommands ) Just Returning PLUGIN_HANDLED, the menu is destroyed." )
        return PLUGIN_HANDLED;
    }

    switch( item )
    {
        case 0:
        {
            DESTROY_PLAYER_NEW_MENU_TYPE( menu )
            startVoteMapVoting( player_id );

            LOG( 1, "    ( handleDisplayVoteMapCommands ) Just Returning PLUGIN_HANDLED, starting the voting." )
            return PLUGIN_HANDLED;
        }
        case 1:
        {
            DESTROY_PLAYER_NEW_MENU_TYPE( menu )

            LOG( 1, "    ( handleDisplayVoteMapCommands ) Just Returning PLUGIN_HANDLED, exit the menu." )
            return PLUGIN_HANDLED;
        }
        case 2:
        {
            clearTheVotingMenu();
            g_voteMapMenuPages[ player_id ] = 0;

            DESTROY_PLAYER_NEW_MENU_TYPE( menu )

            LOG( 1, "    ( handleDisplayVoteMapCommands ) Just Returning PLUGIN_HANDLED, cleaning the voting." )
            return PLUGIN_HANDLED;
        }
        case 3:
        {
            DESTROY_PLAYER_NEW_MENU_TYPE( menu )
            client_cmd( player_id, "messagemode ^"say %s^"", GAL_VOTEMAP_MENU_COMMAND );

            LOG( 1, "    ( handleDisplayVoteMapCommands ) Just Returning PLUGIN_HANDLED, opening go to page." )
            return PLUGIN_HANDLED;
        }
    }

    // debugging menu info tracker
    LOG( 4, "", debug_nomination_match_choice( player_id, menu, item ) )

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
    DESTROY_PLAYER_NEW_MENU_TYPE( menu )

    // Try to block/difficult players from performing the Denial Of Server attack.
    // set_task( 0.1, "displayVoteMapMenuCommands", player_id );
    displayVoteMapMenuCommands( player_id );

    LOG( 1, "    ( handleDisplayVoteMapCommands ) Just Returning PLUGIN_HANDLED, the menu is showed again." )
    return PLUGIN_HANDLED;
}

stock debug_nomination_match_choice( player_id, menu, item )
{
    LOG( 128, "I AM ENTERING ON debug_nomination_match_choice(3) player_id: %d, menu: %d, item: %d", player_id, menu, item )

    new access;
    new callback;

    new info[ 1 ];
    LOG( 4, "( debug_nomination_match_choice ) item: %d, player_id: %d, menu: %d, \
            g_menuMapIndexForPlayerArrays[player_id]: %d", \
            item, player_id, menu, g_menuMapIndexForPlayerArrays[ player_id ] )

    // Get item info
    menu_item_getinfo( menu, item, access, info, sizeof info, _, _, callback );
    LOG( 4, "( debug_nomination_match_choice ) info[0]: %d, access: %d, menu%d", info[ 0 ], access, menu )

    return 0;
}

/**
 * This set up the `say galmenu` final admin's choice builder.
 */
stock openTheVoteMapActionMenu()
{
    LOG( 128, "I AM ENTERING ON openTheVoteMapActionMenu(0) player_id: %d", g_voteMapInvokerPlayerId )

    g_pendingMapVoteCountdown = get_pcvar_num( cvar_voteDuration ) + 120;
    set_task( 1.0, "displayTheVoteMapActionMenu", TASKID_PENDING_VOTE_COUNTDOWN, _, _, "a", g_pendingMapVoteCountdown );
}

/**
 * This is the `say galmenu` final admin's choice builder.
 */
public displayTheVoteMapActionMenu()
{
    LOG( 128, "I AM ENTERING ON displayTheVoteMapActionMenu(0) player_id: %d", g_voteMapInvokerPlayerId )
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
                COLOR_YELLOW, COLOR_GREY, g_pendingMapVoteCountdown, player_id, "GAL_TIMELEFT", COLOR_YELLOW );

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

        LOG( 4, "( displayTheVoteMapActionMenu ) menu_body: %s", menu_body )
        LOG( 4, "    menu_id: %d, menuKeys: %d, ", menu_id, menuKeys )
        LOG( 4, "    g_pendingMapVoteCountdown: %d", g_pendingMapVoteCountdown )
    }
    else
    {
        // To perform the default action automatically, nothing is answered.
        handleVoteMapActionMenu( player_id, 0 );
    }

    LOG( 4, "%48s", " ( displayTheVoteMapActionMenu| out )" )
}

/**
 * This is the `say galmenu` final admin's choice handler.
 */
public handleVoteMapActionMenu( player_id, pressedKeyCode )
{
    LOG( 128, "I AM ENTERING ON handleVoteMapActionMenu(2) player_id: %d, pressedKeyCode: %d", \
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

            // Then this is empty, the winner was stay here, and this result has already been announced.
            if( g_invokerVoteMapNameToDecide[ 0 ] )
            {
                color_chat( 0, "%L. %L: %s", LANG_PLAYER, "RESULT_REF", LANG_PLAYER, "VOT_CANC", g_invokerVoteMapNameToDecide );
                toShowTheMapNextHud( "RESULT_REF", "VOT_CANC", "GAL_OPTION_STAY_MAP", g_currentMapName );
            }
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
                color_chat( 0, "%L. %L: %s", LANG_PLAYER, "RESULT_ACC", LANG_PLAYER, "VOTE_SUCCESS", g_invokerVoteMapNameToDecide );
                toShowTheMapNextHud( "RESULT_ACC", "DMAP_MAP_EXTENDED1", "GAL_WINNER_ORDERED1", g_invokerVoteMapNameToDecide );

                setNextMap( g_currentMapName, g_invokerVoteMapNameToDecide );
            }
        }
    }

    LOG( 1, "    ( handleEndOfTheMapVoteChoice ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

stock get_real_players_number()
{
    LOG( 256, "I AM ENTERING ON get_real_players_number(0) get_playersnum: %d", get_playersnum() )

    new playersCount;
    new players[ MAX_PLAYERS ];

    if( IS_TO_IGNORE_SPECTATORS() )
    {
        new temp;

        get_players( players, temp, "che", "CT" );
        LOG( 256, "( get_real_players_number ) playersCount(CT): %d", temp )
        playersCount += temp;

        get_players( players, temp, "che", "TERRORIST" );
        LOG( 256, "( get_real_players_number ) playersCount(TERRORIST): %d", temp )
        playersCount += temp;

    #if defined DEBUG
        get_players( players, temp, "che", "SPECTATOR" );
        LOG( 256, "( get_real_players_number ) playersCount(SPECTATOR): %d", temp )

        get_players( players, temp, "che", "UNASSIGNED" );
        LOG( 256, "( get_real_players_number ) playersCount(UNASSIGNED): %d", temp )
    #endif
    }
    else
    {
        get_players( players, playersCount, "ch" );
    }

    LOG( 256, "( get_real_players_number ) playersCount: %d", playersCount )

#if ARE_WE_RUNNING_UNIT_TESTS && DEBUG_LEVEL & DEBUG_LEVEL_FAKE_VOTES
    if( g_test_areTheUnitTestsRunning )
    {
        return g_test_aimedPlayersNumber;
    }

    return FAKE_PLAYERS_NUMBER_FOR_DEBUGGING;
#else
    #if ARE_WE_RUNNING_UNIT_TESTS
        if( g_test_areTheUnitTestsRunning )
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
    LOG( 256, "I AM ENTERING ON percent(2) is: %d, of: %d", is, of )
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
 * If you run this function on a Game Mod that do not support colored messages, they will be
 * displayed as normal messages without any errors or bad formats.
 *
 * This allow you to use '!g for green', '!y for yellow', '!t for team' color with LANGs at a
 * register_dictionary_colored file. Otherwise use '^1', '^2', '^3' and '^4'.
 *
 * @param player_id          the player id.
 * @param lang_formatting    the text formatting rules to display.
 * @param any                the variable number of formatting parameters.
 *
 * @see <a href="https://forums.alliedmods.net/showthread.php?t=297484">vformat() ignoring user language</a>
 */
stock color_chat( const player_id, const lang_formatting[], any:... )
{
    LOG( 128, "I AM ENTERING ON color_chat()" )
    LOG( 64, "( color_chat ) IS_COLORED_CHAT_ENABLED(): %d `%s`", IS_COLORED_CHAT_ENABLED(), g_coloredChatPrefix )
    LOG( 64, "( color_chat ) player_id: %d, lang_formatting: `%s`", player_id, lang_formatting )

    const first_lang_parameter_position = 3;
    new formatted_message[ MAX_COLOR_MESSAGE ];

    if( player_id )
    {
        if( IS_COLORED_CHAT_ENABLED() )
        {
            // Here all the colored messaged must to start within a color.
            formatted_message[ 0 ] = '^1';
            vformat( formatted_message[ 1 ], charsmax( formatted_message ) - 1, lang_formatting, first_lang_parameter_position );

            if( g_coloredChatPrefix[ 0 ] )
            {
                new message[ MAX_COLOR_MESSAGE ];
                formatex( message, charsmax( message ), "^1%s^1%s", g_coloredChatPrefix, formatted_message[ 1 ] );

                LOG( 64, "( color_chat ) [in] player_id: %d, Chat printed: `%s`", player_id, message )
                PRINT_COLORED_MESSAGE( player_id, message )
            }
            else
            {
                PRINT_COLORED_MESSAGE( player_id, formatted_message )
            }
        }
        else
        {
            vformat( formatted_message, charsmax( formatted_message ), lang_formatting, first_lang_parameter_position );

            REMOVE_CODE_COLOR_TAGS( formatted_message )
            client_print( player_id, print_chat, "%s%s", g_coloredChatPrefix, formatted_message );
        }
    }
    else
    {
        new playersCount;
        new players[ MAX_PLAYERS ];

        // Get the server players skipping the bots
        get_players( players, playersCount, "c" );

        // Figure out if at least 1 player is connected, so we don't execute useless code
        if( !playersCount )
        {
            LOG( 64, "    ( color_chat ) Returning on playersCount: %d...", playersCount )
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

        LOG( 64, "( color_chat ) playersCount: %d, params_number: %d...", playersCount, params_number )

        // ML can be used
        if( params_number > first_lang_parameter_position )
        {
            for( argument_index = first_lang_parameter_position - 1; argument_index < params_number; argument_index++ )
            {
                LOG( 64, "( color_chat ) getarg(%d): %d", argument_index, getarg( argument_index, 0 ) )

                // retrieve original param value and check if it's LANG_PLAYER value
                if( getarg( argument_index ) == LANG_PLAYER )
                {
                    string_index = 0;

                    // as LANG_PLAYER == -1, check if next param string is a registered language translation
                    while( ( formatted_message[ string_index ] =
                                 getarg( argument_index + 1, string_index++ ) ) )
                    {
                    }

                    // Closes the open string
                    formatted_message[ string_index ] = '^0';

                    LOG( 64, "( color_chat ) LANG name: %s, GetLangTransKey(): %d, TransKey_Bad: %d", \
                            formatted_message, GetLangTransKey( formatted_message ), TransKey_Bad )

                    if( GetLangTransKey( formatted_message ) != TransKey_Bad )
                    {
                        // Store that argument as LANG_PLAYER so we can alter it later
                        LOG( 64, "( color_chat ) Pushing argument_index: %d", argument_index )
                        ArrayPushCell( multi_lingual_indexes_array, argument_index++ );

                        // Update ML array, so we'll know 1st if ML is used, 2nd how many arguments we have to change
                        multi_lingual_constants_number++;
                    }
                }
            }
        }

        LOG( 64, "( color_chat ) multi_lingual_constants_number: %d...", multi_lingual_constants_number )

        for( --playersCount; playersCount >= 0; --playersCount )
        {
            player_id = players[ playersCount ];

            if( multi_lingual_constants_number )
            {
                for( argument_index = 0; argument_index < multi_lingual_constants_number; argument_index++ )
                {
                    LOG( 64, "( color_chat ) player_id: %d, argument_index: %d, ArrayGetCell(%d,%d): %d", \
                            player_id, argument_index, \
                            multi_lingual_indexes_array, argument_index, ArrayGetCell( multi_lingual_indexes_array, argument_index ) )

                    // Set all LANG_PLAYER args to player index ( = player_id ), so we can format the text for that specific player
                    setarg( ArrayGetCell( multi_lingual_indexes_array, argument_index ), _, player_id );
                }
            }

            if( IS_COLORED_CHAT_ENABLED() )
            {
                // Here all the colored messaged must to start within a color.
                formatted_message[ 0 ] = '^1';
                vformat( formatted_message[ 1 ], charsmax( formatted_message ) - 1, lang_formatting, first_lang_parameter_position );

                if( g_coloredChatPrefix[ 0 ] )
                {
                    new message[ MAX_COLOR_MESSAGE ];
                    formatex( message, charsmax( message ), "^1%s^1%s", g_coloredChatPrefix, formatted_message[ 1 ] );

                    LOG( 64, "( color_chat ) 1. [out] colored message: `%s`", message )
                    PRINT_COLORED_MESSAGE( player_id, message )
                }
                else
                {
                    LOG( 64, "( color_chat ) 2. [out] colored message: `%s`", formatted_message )
                    PRINT_COLORED_MESSAGE( player_id, formatted_message )
                }
            }
            else
            {
                vformat( formatted_message, charsmax( formatted_message ), lang_formatting, first_lang_parameter_position );
                REMOVE_CODE_COLOR_TAGS( formatted_message )

                LOG( 64, "( color_chat ) 3. [out] uncolored message: `%s`", formatted_message )
                client_print( player_id, print_chat, "%s%s", g_coloredChatPrefix, formatted_message );
            }
        }

        ArrayDestroy( multi_lingual_indexes_array );
    }
}

/**
 * ConnorMcLeod's [Dyn Native] ColorChat v0.3.2 (04 jul 2013) register_dictionary_colored function:
 *   <a href="https://forums.alliedmods.net/showthread.php?p=851160">ColorChat v0.3.2</a>
 *
 * @param dictionaryFile the dictionary file name including its file extension.
 */
stock register_dictionary_colored( const dictionaryFile[] )
{
    LOG( 128, "I AM ENTERING ON register_dictionary_colored(1) dictionaryFile: %s", dictionaryFile )

    if( !register_dictionary( dictionaryFile ) )
    {
        LOG( 1, "    Returning 0 on if( !register_dictionary(%s) )", dictionaryFile )
        return 0;
    }

    new dictionaryFilePath[ MAX_FILE_PATH_LENGHT ];

    get_localinfo( "amxx_datadir", dictionaryFilePath, charsmax( dictionaryFilePath ) );
    formatex( dictionaryFilePath, charsmax( dictionaryFilePath ), "%s/lang/%s", dictionaryFilePath, dictionaryFile );

    // DO not SEPARE/SPLIT THIS DECLARATION in: new var; var = fopen... or it can crash some servers.
    new dictionaryFile = fopen( dictionaryFilePath, "rt" );

    if( !dictionaryFile )
    {
        doAmxxLog( "ERROR, register_dictionary_colored: Failed to open ^"%s^"", dictionaryFilePath );
        LOG( 1, "    Returning 0 on if( !dictionaryFile ), Failed to open ^"%s^"", dictionaryFilePath )

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
            str_token( currentReadLine[ 1 ], langTypeAcronym, charsmax( langTypeAcronym ), currentReadLine, 1, ']' );
        }
        else if( currentReadLine[ 0 ] )
        {
            str_break( currentReadLine, langConstantName, charsmax( langConstantName ), langTranslationText, charsmax( langTranslationText ) );
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

                // LOG( 256, "lang: %s, Id: %d, Text: %s", langTypeAcronym, translationKeyId, langTranslationText )
                AddTranslation( langTypeAcronym, translationKeyId, langTranslationText[ 2 ] );
            }
        }
    }

    fclose( dictionaryFile );
    return 1;
}

/**
 * Immediately stops any vote in progress. It keeps the `IS_VOTE_OVER` flag to maintain any older
 * voting valid after the cancellation.
 */
stock cancelVoting( bool:isToDoubleReset = false )
{
    LOG( 128, "I AM ENTERING ON cancelVoting(1) isToDoubleReset: %d", isToDoubleReset )

    remove_task( TASKID_START_VOTING_DELAYED );
    remove_task( TASKID_DELETE_USERS_MENUS );
    remove_task( TASKID_DELETE_USERS_MENUS_CARE );
    remove_task( TASKID_VOTE_DISPLAY );
    remove_task( TASKID_PREVENT_INFITY_GAME );
    remove_task( TASKID_DBG_FAKEVOTES );
    remove_task( TASKID_VOTE_HANDLEDISPLAY );
    remove_task( TASKID_VOTE_EXPIRE );
    remove_task( TASKID_START_THE_VOTING );
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

    g_isMapExtensionPeriodRunning = false;

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
    LOG( 128, "I AM ENTERING ON vote_resetStats(0)" )

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
    LOG( 128, "I AM ENTERING ON clearTheVotingMenu(0)" )
    g_totalVoteOptions = 0;

    for( new currentIndex = 0; currentIndex < sizeof g_votingMapNames; ++currentIndex )
    {
        LOG( 8, "Cleaning g_votingMapNames[%d]: %s", currentIndex, g_votingMapNames[ currentIndex ] )
        g_arrayOfRunOffChoices[ currentIndex ] = 0;

        g_votingMapNames[ currentIndex ][ 0 ] = '^0';
        g_votingMapInfos[ currentIndex ][ 0 ] = '^0';
    }
}

public delete_users_menus_care()
{
    LOG( 128, "I AM ENTERING ON delete_users_menus_care(0)" )
    delete_users_menus();
}

stock delete_user_menu( player_id )
{
    LOG( 128, "I AM ENTERING ON delete_user_menu(1) player_id: %d", player_id )

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
    LOG( 128, "I AM ENTERING ON delete_users_menus(1) isToDoubleReset: %d", isToDoubleReset )

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
    LOG( 1, "" )
    LOG( 128, "I AM ENTERING ON tryToSetGameModCvarFloat(2) cvarPointer: %d, value: %f", cvarPointer, value )
    LOG( 1, "    ( tryToSetGameModCvarNum ) cvar_disabledValuePointer: %d", cvar_disabledValuePointer )

    if( cvarPointer != cvar_disabledValuePointer )
    {
        LOG( 2, "    ( tryToSetGameModCvarFloat ) IS CHANGING THE CVAR '%d' to '%f'.", cvarPointer, value )
        set_pcvar_float( cvarPointer, value );
    }
}

stock tryToSetGameModCvarNum( cvarPointer, num )
{
    LOG( 1, "" )
    LOG( 128, "I AM ENTERING ON tryToSetGameModCvarNum(2) cvarPointer: %d, num: %d", cvarPointer, num )
    LOG( 1, "    ( tryToSetGameModCvarNum ) cvar_disabledValuePointer: %d", cvar_disabledValuePointer )

    if( cvarPointer != cvar_disabledValuePointer )
    {
        LOG( 2, "    ( tryToSetGameModCvarNum ) IS CHANGING THE CVAR '%d' to '%d'.", cvarPointer, num )
        set_pcvar_num( cvarPointer, num );
    }
}

stock tryToSetGameModCvarString( cvarPointer, string[] )
{
    LOG( 1, "" )
    LOG( 128, "I AM ENTERING ON tryToSetGameModCvarString(2) cvarPointer: %d, string: %s", cvarPointer, string )
    LOG( 1, "    ( tryToSetGameModCvarNum ) cvar_disabledValuePointer: %d", cvar_disabledValuePointer )

    if( cvarPointer != cvar_disabledValuePointer )
    {
        LOG( 2, "    ( tryToSetGameModCvarString ) IS CHANGING THE CVAR '%d' to '%s'.", cvarPointer, string )
        set_pcvar_string( cvarPointer, string );
    }
}

public plugin_end()
{
    LOG( 32, "" )
    LOG( 32, "" )
    LOG( 32, "" )
    LOG( 32, "I AM ENTERING ON plugin_end(0). THE END OF THE PLUGIN LIFE!" )

#if ARE_WE_RUNNING_UNIT_TESTS
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
 * To print on the server console the current and next map names aligned. Output example:
 *
 * L 01/23/2017 - 00:40:44: {1.000 15768 778942    1}
 * L 01/23/2017 - 00:40:44: {1.000 15768 778943    1}
 * L 01/23/2017 - 00:40:44: {1.000 15764 778945    2}  The current map is [ cs_italy    ]
 * L 01/23/2017 - 00:40:44: {1.000 15764 778946    1}  The  next   map is [ cs_italy_cz ]
 * L 01/23/2017 - 00:40:44: {1.000 15768 778948    2}
 * L 01/23/2017 - 00:40:44: {1.000 15768 778949    1}
 *
 * There is not point in adding the entry statement to this function as its purpose is only to
 * print few lines as possible.
 */
stock printTheCurrentAndNextMapNames()
{
    LOG( 0, "I AM ENTERING ON printTheCurrentAndNextMapNames(0)" )

    new nextMap   [ MAX_MAPNAME_LENGHT ];
    new currentMap[ MAX_MAPNAME_LENGHT ];

    copy( nextMap, charsmax( nextMap ), g_nextMapName );
    copy( currentMap, charsmax( currentMap ), g_currentMapName );

    new nextLength    = strlen( nextMap );
    new currentLength = strlen( currentMap );
    new maximumLength = max( nextLength, currentLength );

    while( nextLength    < maximumLength ) nextMap  [ nextLength++    ] = ' ';
    while( currentLength < maximumLength )currentMap[ currentLength++ ] = ' ';

    nextMap   [ nextLength    ] = '^0';
    currentMap[ currentLength ] = '^0';

    LOG( 4, "" )
    LOG( 4, "" )
    LOG( 4, " The current map is [ %s ]", currentMap )
    LOG( 4, " The  next   map is [ %s ]", nextMap )
    LOG( 4, "" )
    LOG( 4, "" )

    return 0;
}

/**
 * Call the AMXX logger log_amx() and the internal debugger using the same logging message.
 *
 * @param text the debug message, if omitted its default value is ""
 * @param any the variable number of formatting parameters
 */
stock doAmxxLog( const message[] = "", any:... )
{
    static formatted_message[ MAX_LONG_STRING ];
    vformat( formatted_message, charsmax( formatted_message ), message, 2 );

    LOG( 1, formatted_message )
    log_amx( formatted_message );
}

/**
 * Same as TRY_TO_APPLY(2), but the second argument must to be a two Dimensional Dynamic Array.
 *
 * @param outerArray                   a Dynamic Array within several Dynamic Arrays.
 * @param isToDestroyTheOuterArray     whether to destroy or clear the `outerArray` provided.
 */
stock destroy_two_dimensional_array( Array:outerArray, bool:isToDestroyTheOuterArray = true )
{
    LOG( 128, "I AM ENTERING ON destroy_two_dimensional_array(1) arrayIndentifation: %d", outerArray )

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
        LOG( 256, "    ( is_map_valid_bsp_check ) Returning false, %s length < 0.", mapName )
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
            LOG( 256, "    ( is_map_valid_bsp_check ) Returning true, %s", mapName )
            return true;
        }
    }

    LOG( 256, "    ( is_map_valid_bsp_check ) Returning false, %s", mapName )
    return false;
}

/**
 * There is not point in adding the entry statement to this function as its purpose is only to
 * print few lines as possible.
 */
stock printUntilTheNthLoadedMap( mapIndex, mapName[] )
{
    if( mapIndex < MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST )
    {
        LOG( 4, "( printUntilTheNthLoadedMap ) %d, loadedMapLine: %s", mapIndex, mapName )
    }

    return 0;
}

stock printDynamicArrayMaps( Array:populatedArray, debugLevel )
{
    LOG( debugLevel, "I AM ENTERING ON printDynamicArrayMaps(1) array id: %d", populatedArray )

    new mapName[ MAX_MAPNAME_LENGHT ];
    new size = ArraySize( populatedArray );

    for( new index = 0; index < size; index++ )
    {
        ArrayGetString( populatedArray, index, mapName, charsmax( mapName ) );
        LOG( debugLevel, "index: %d, mapName: %s", index, mapName )
    }

    // Fix warning 203: symbol is never used: "debugLevel" with some debug levels, but this must not
    // to be called with `DEBUG_LEVEL` 0, as this function is for debug purposes only.
#if DEBUG_LEVEL > 0
    debugLevel++;
#endif
    return 0;
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
    LOG( 128, "I AM ENTERING ON nextmapPluginInit(0)" )

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

stock loadTheNextMapFile( mapcycleFilePath[], &Array:mapcycleFileListArray, &Trie:mapcycleFileListTrie )
{
    LOG( 128, "I AM ENTERING ON loadTheNextMapFile(3): %s", mapcycleFilePath )
    new mapCount;

    TRY_TO_CLEAN( TrieClear, mapcycleFileListTrie, TrieCreate() )
    TRY_TO_CLEAN( ArrayClear, mapcycleFileListArray, ArrayCreate( MAX_MAPNAME_LENGHT ) )

    mapCount = map_populateListOnSeries( mapcycleFileListArray, mapcycleFileListTrie, mapcycleFilePath );
    LOG( 0, "", printDynamicArrayMaps( mapcycleFileListArray, 256 ) )

    LOG( 1, "    ( loadTheNextMapFile ) Returning mapCount: %d", mapCount )
    return mapCount;
}

stock getNextMapLocalInfoToken( currentMapcycleFilePath[] )
{
    LOG( 128, "I AM ENTERING ON getNextMapLocalInfoToken(1) currentMapcycleFilePath: %s", currentMapcycleFilePath )
    new nextMapCyclePosition;

    new mapcycleCurrentIndex   [ MAX_MAPNAME_LENGHT ];
    new lastMapcycleFilePath   [ MAX_FILE_PATH_LENGHT ];
    new tockenMapcycleAndPosion[ MAX_MAPNAME_LENGHT + MAX_FILE_PATH_LENGHT ];

    // Take from the local info, the map token saved on the last server map.
    get_localinfo( "lastmapcycle", tockenMapcycleAndPosion, charsmax( tockenMapcycleAndPosion ) );

    parse( tockenMapcycleAndPosion, lastMapcycleFilePath, charsmax( lastMapcycleFilePath ),
                                    mapcycleCurrentIndex, charsmax( mapcycleCurrentIndex ) );

    LOG( 2, "( getNextMapLocalInfoToken ) mapcycleCurrentIndex:    %s", mapcycleCurrentIndex    )
    LOG( 2, "( getNextMapLocalInfoToken ) lastMapcycleFilePath:    %s", lastMapcycleFilePath    )
    LOG( 2, "( getNextMapLocalInfoToken ) tockenMapcycleAndPosion: %s", tockenMapcycleAndPosion )
    LOG( 2, "( getNextMapLocalInfoToken ) currentMapcycleFilePath: %s", currentMapcycleFilePath )

    // This acts on when the server is restarted. As the next map position is set when reading
    // the map cycle file, we need to undo it in order to keep the original next map before restart.
    if( equali( currentMapcycleFilePath, lastMapcycleFilePath ) )
    {
        nextMapCyclePosition = str_to_num( mapcycleCurrentIndex );
    }
    else
    {
        // If the mapcyclefile has been changed, go from the first map on the map cycle.
        nextMapCyclePosition = 0;
    }

    LOG( 2, "    ( getNextMapLocalInfoToken ) Returning nextMapCyclePosition: %d", nextMapCyclePosition )
    return nextMapCyclePosition;
}

/**
 * The default cvar `mapcyclefile` seems to crash the game if you have more of 489 maps in
 * `mapcycle.txt`file. Therefore, you can use this cvar instead of the default `mapcyclefile` cvar
 * if you want to have more map on your map cycle file.
 */
stock registerTheMapCycleCvar()
{
    LOG( 128, "I AM ENTERING ON registerTheMapCycleCvar(0)" )

    new mapcycleFilePath[ MAX_FILE_PATH_LENGHT ];
    get_pcvar_string( cvar_gal_mapcyclefile, mapcycleFilePath, charsmax( mapcycleFilePath ) );

    if( mapcycleFilePath[ 0 ] )
    {
        if( file_exists( mapcycleFilePath ) )
        {
            cvar_mapcyclefile = cvar_gal_mapcyclefile;
        }
        else
        {
            doAmxxLog( "ERROR, registerTheMapCycleCvar: Couldn't open the file to read ^"%s^"", mapcycleFilePath );
        }
    }
}

/**
 * If we were playing a map series map `cs_map1`, and due an RTV voting was started a new series as
 * `de_map1`, we need to set the next map as `de_map2` instead of `cs_map1`. Also, after the series
 * to be finished we must to be able to return to the next map after the original series `cs_map1`.
 *
 * @param currentMapcycleFilePath any string trash variable with length MAX_FILE_PATH_LENGHT
 */
stock configureTheNextMapSetttings( currentMapcycleFilePath[] )
{
    LOG( 128, "I AM ENTERING ON configureTheNextMapSetttings(1): %s", currentMapcycleFilePath )
    new mapCount;
    new nextMapCyclePosition;

    // Load the full map cycle considering whether the feature `gal_srv_move_cursor` is enabled or not.
    get_pcvar_string( cvar_mapcyclefile, currentMapcycleFilePath, MAX_FILE_PATH_LENGHT - 1 );
    mapCount = loadTheNextMapFile( currentMapcycleFilePath, g_mapcycleFileListArray, g_mapcycleFileListTrie );

    nextMapCyclePosition = getNextMapLocalInfoToken( currentMapcycleFilePath );
    configureTheAlternateSeries( g_mapcycleFileListArray, nextMapCyclePosition );

    setTheNextMapCvarFlag( g_nextMapName );
    saveCurrentMapCycleSetting( g_currentMapName, currentMapcycleFilePath, nextMapCyclePosition );

    LOG( 1, "    ( configureTheNextMapSetttings ) Returning mapCount: %d", mapCount )
    return mapCount;
}

stock getLastNextMapFromServerStart( Array:mapcycleFileListArray, nextMapName[], &nextMapCyclePosition )
{
    LOG( 128, "I AM ENTERING ON getLastNextMapFromServerStart(3) nextMapCyclePosition: %d", nextMapCyclePosition )

    // Get the last next map set on the first server start.
    if( get_pcvar_num( cvar_serverStartAction )
        && get_pcvar_num( cvar_isFirstServerStart ) == SECOND_SERVER_START )
    {
        // This is the key that tells us if this server has been started or not.
        set_pcvar_num( cvar_isFirstServerStart, AFTER_READ_MAPCYCLE );
        LOG( 2, "( getLastNextMapFromServerStart ) IS CHANGING THE CVAR 'gal_server_starting' to '%d'.", AFTER_READ_MAPCYCLE )

        get_pcvar_string( cvar_amx_nextmap, nextMapName, MAX_MAPNAME_LENGHT - 1 );

        // Block the next map name being read as the current map name on the server start.
        if( equali( nextMapName, g_currentMapName ) )
        {
            goto getAnotherNextMapName;
        }

        if( IS_MAP_VALID( nextMapName ) )
        {
            LOG( 4, "( getLastNextMapFromServerStart ) nextMapName: %s", nextMapName )
        }
    }
    else
    {
        getAnotherNextMapName:
        getNextMapByPosition( mapcycleFileListArray, g_nextMapName, nextMapCyclePosition );
    }
}

stock configureTheAlternateSeries( Array:mapcycleFileListArray, &nextMapCyclePosition )
{
    LOG( 4, "" )
    LOG( 128, "I AM ENTERING ON configureTheAlternateSeries(2)" )

    new bool:isTheServerRestarting;
    new lastMap[ MAX_MAPNAME_LENGHT ];

    get_localinfo( "galileo_lastmap", lastMap, charsmax( lastMap ) );

    LOG( 4, "( configureTheAlternateSeries ) lastMap:              %s", lastMap              )
    LOG( 4, "( configureTheAlternateSeries ) g_currentMapName:     %s", g_currentMapName     )
    LOG( 4, "( configureTheAlternateSeries ) nextMapCyclePosition: %d", nextMapCyclePosition )

    // If successful, the tryToRunAnAlternateSeries(4) is already freezing the map cycle position.
    if( ( isTheServerRestarting = !!equali( g_currentMapName, lastMap ) ) )
    {
        nextMapCyclePosition = getMapIndexBefore( mapcycleFileListArray, nextMapCyclePosition, 1 );
    }

    getLastNextMapFromServerStart( mapcycleFileListArray, g_nextMapName, nextMapCyclePosition );

    LOG( 4, "" )
    LOG( 4, "" )
    LOG( 4, "" )
    LOG( 4, "" )
    LOG( 4, "" )

    if( tryToRunAnAlternateSeries( mapcycleFileListArray, g_currentMapName, g_nextMapName, nextMapCyclePosition ) )
    {
        // If the server is restarting, the map cycle position was already decreased just above.
        if( !isTheServerRestarting )
        {
            // Block the map cycle growing resetting it to its old value. This must to be called until
            // we exit the alternate series we are running on.
            --nextMapCyclePosition;
        }
    }

    LOG( 2, "    ( configureTheAlternateSeries ) Returning nextMapCyclePosition: %d", nextMapCyclePosition )
    LOG( 4, "" )
    LOG( 4, "" )
    LOG( 4, "" )
    LOG( 4, "" )
    LOG( 4, "" )
}

/**
 * Start following the series by its dynamically generated name instead of using the virtual map cycle
 * file list.
 *
 * When we should follow a different next map than the `defaultNextMapName` parameter, it set the `defaultNextMapName`
 * parameter to the next map it should follow and freeze the map cycle position.
 *
 * Otherwise does keep it and do not freeze the map cycle position `defaultNextMapCyclePosition` decreasing its value.
 *
 * @param currentMapName                 this is the map name which was just changed by the RTV or server Admin.
 * @param defaultNextMapName             the next map based on the position read from last `defaultNextMapCyclePosition` value.
 * @param defaultNextMapCyclePosition    the default position of the next map of current `defaultNextMapName`.
 *
 * @return true when the map cycle position need to be decreased, false otherwise.
 */
stock tryToRunAnAlternateSeries( Array:mapcycleFileListArray, currentMapName[], defaultNextMapName[], &defaultNextMapCyclePosition )
{
    LOG( 128, "I AM ENTERING ON tryToRunAnAlternateSeries(4)" )

    LOG( 4, "( tryToRunAnAlternateSeries ) currentMapName:              %s", currentMapName              )
    LOG( 4, "( tryToRunAnAlternateSeries ) defaultNextMapName:          %s", defaultNextMapName          )
    LOG( 4, "( tryToRunAnAlternateSeries ) defaultNextMapCyclePosition: %d", defaultNextMapCyclePosition )
    LOG( 4, "" )

    if( get_pcvar_num( cvar_serverMoveCursor ) & IS_TO_LOAD_ALTERNATE_MAP_SERIES )
    {
        new currentMapSerie;
        new defaultNextMapSeries;

        new possibleNextMap      [ MAX_MAPNAME_LENGHT ];

        new currentMapNameClean       [ MAX_MAPNAME_LENGHT ];
        new defaultNextMapNameClean   [ MAX_MAPNAME_LENGHT ];

        copy( currentMapNameClean       , charsmax( currentMapNameClean        ), currentMapName        );
        copy( defaultNextMapNameClean   , charsmax( defaultNextMapNameClean    ), defaultNextMapName    );

        currentMapSerie      = getTheCurrentSerieForTheMap( currentMapNameClean );
        defaultNextMapSeries = getTheCurrentSerieForTheMap( defaultNextMapNameClean );

        LOG( 4, "" )
        LOG( 4, "( tryToRunAnAlternateSeries ) currentMapName:        %s", currentMapName        )
        LOG( 4, "( tryToRunAnAlternateSeries ) defaultNextMapName:    %s", defaultNextMapName    )
        LOG( 4, "" )

        // If both clear names are equal, the current map and the next map set are on the same series.
        // When the `mapcycleFileListArray` size is less than  and the current map name is the same as
        // the next map name, it means there are not valid maps on the map cycle.
        // Therefore we can check for an alternate series.
        if( equali( currentMapNameClean, defaultNextMapNameClean )
            && !( equali( currentMapName, defaultNextMapName )
                  && ArraySize( mapcycleFileListArray ) < 1 ) )
        {
            LOG( 1, "( tryToRunAnAlternateSeries ) Returning/blocking, the current map and the next map set are on the same series." )
            LOG( 1, "    ( tryToRunAnAlternateSeries ) Returning false." )
            return false;
        }

        // Being successful means we are on a different series than the series set on the map cycle, and the series
        // is not finished yet. Therefore we must to keep following it until it ends, instead of the map cycle.
        if( areWeRunningAnAlternateSeries( currentMapNameClean, currentMapSerie, possibleNextMap ) )
        {
            // Only if the isThereNextMapOnTheSerie(3) is successful, we set the map name on the returning variable.
            copy( defaultNextMapName, MAX_MAPNAME_LENGHT - 1, possibleNextMap );

            // We only need to move it to the end of the `defaultCurrentMapName` only one time, and while doing it
            // we cannot move back the `defaultNextMapCyclePosition` cursor.
            if( tryToMoveTheMapCycleCursor( mapcycleFileListArray, defaultNextMapSeries,
                                            defaultNextMapNameClean, defaultNextMapCyclePosition ) )
            {
                LOG( 1, "    ( tryToRunAnAlternateSeries ) Returning true." )
                return true;
            }
        }
    }

    LOG( 1, "    ( tryToRunAnAlternateSeries ) Returning false." )
    return false;
}

/**
 * Properly set the map `possibleNextMap` when we are on an valid alternate map series.
 *
 * Returns true when the current playing map is out of the range of the saved map cycle range and
 * respecting the `IS_TO_LOAD_EXPLICIT_MAP_SERIES` start map rule.
 *
 * Returns false when the current playing map is inside of the range of the saved map cycle or
 * is not respecting the `IS_TO_LOAD_EXPLICIT_MAP_SERIES` start map rule.
 */
stock bool:areWeRunningAnAlternateSeries( const currentMapNameClean[], currentMapSerie, possibleNextMap[] )
{
    LOG( 128, "I AM ENTERING ON areWeRunningAnAlternateSeries(3)" )

    new cursorOnMapSeries;
    new bool:isAnAlternateSeries;

    cursorOnMapSeries   = get_pcvar_num( cvar_serverMoveCursor );
    isAnAlternateSeries = isThereNextMapOnTheSerie( currentMapSerie, currentMapNameClean, possibleNextMap );

    // When the `IS_TO_LOAD_ALL_THE_MAP_SERIES` is set, it overrides the `IS_TO_LOAD_THE_FIRST_MAP_SERIES` bit flag.
    if( cursorOnMapSeries & IS_TO_LOAD_EXPLICIT_MAP_SERIES
        || cursorOnMapSeries & IS_TO_LOAD_THE_FIRST_MAP_SERIES
           && !( cursorOnMapSeries & IS_TO_LOAD_ALL_THE_MAP_SERIES ) )
    {
        new lastMapName     [ MAX_MAPNAME_LENGHT ];
        new lastMapNameClean[ MAX_MAPNAME_LENGHT ];

        get_localinfo( "galileo_lastmap", lastMapName, charsmax( lastMapName ) );
        copy( lastMapNameClean, charsmax( lastMapNameClean ), lastMapName );

        getTheCurrentSerieForTheMap( lastMapNameClean );

        LOG( 4, "" )
        LOG( 4, "( areWeRunningAnAlternateSeries ) lastMapName:         %s", lastMapName         )
        LOG( 4, "( areWeRunningAnAlternateSeries ) currentMapNameClean: %s", currentMapNameClean )
        LOG( 4, "" )

        if( currentMapSerie > 2
            && !equali( currentMapNameClean, lastMapNameClean ) )
        {
            LOG( 2, "    ( areWeRunningAnAlternateSeries ) Returning false." )
            return false;
        }
    }

    LOG( 2, "    ( areWeRunningAnAlternateSeries ) Returning %d.", isAnAlternateSeries )
    return isAnAlternateSeries;
}
/**
 * Returns true when are on a series and should not load the next map following the current map.
 *
 * Returns false when the current map is already from the map cycle series, or when the current alternate
 * series is over by getting on its last map and the map cycle should be followed instead.
 *
 * @return true when the cursor was not moved, false otherwise.
 */
stock bool:tryToMoveTheMapCycleCursor( Array:mapcycleFileListArray, defaultNextMapSeries,
                                       const defaultNextMapNameClean[], &defaultNextMapCyclePosition )
{
    LOG( 128, "I AM ENTERING ON tryToMoveTheMapCycleCursor(4)" )
    new defaultCurrentMapIndex;

    new lastMapName          [ MAX_MAPNAME_LENGHT ];
    new defaultCurrentMapName[ MAX_MAPNAME_LENGHT ];

    // The index on `defaultNextMapCyclePosition` is 3 maps ahead the last map
    defaultCurrentMapIndex = getMapIndexBefore( mapcycleFileListArray, defaultNextMapCyclePosition, 3 );
    getNextMapByPosition( mapcycleFileListArray, defaultCurrentMapName, defaultCurrentMapIndex, false, false );

    get_localinfo( "galileo_lastmap", lastMapName, charsmax( lastMapName ) );

    LOG( 4, "" )
    LOG( 4, "( tryToMoveTheMapCycleCursor ) lastMapName:            %s", lastMapName            )
    LOG( 4, "( tryToMoveTheMapCycleCursor ) defaultCurrentMapName:  %s", defaultCurrentMapName  )
    LOG( 4, "( tryToMoveTheMapCycleCursor ) defaultCurrentMapIndex: %d", defaultCurrentMapIndex )

    // If the last map name is not the same as the defaultCurrentMapName, we already moved the cursor.
    if( equali( lastMapName, defaultCurrentMapName ) )
    {
        new cursorOnMapSeries;
        new defaultCurrentMapNameClean[ MAX_MAPNAME_LENGHT ];

        cursorOnMapSeries = get_pcvar_num( cvar_serverMoveCursor );

        copy( defaultCurrentMapNameClean, charsmax( defaultCurrentMapNameClean ), defaultCurrentMapName );
        getTheCurrentSerieForTheMap( defaultCurrentMapNameClean );

        // When the `IS_TO_LOAD_ALL_THE_MAP_SERIES` is set, it overrides the `IS_TO_LOAD_THE_FIRST_MAP_SERIES` bit flag.
        if( cursorOnMapSeries & IS_TO_LOAD_EXPLICIT_MAP_SERIES
            || cursorOnMapSeries & IS_TO_LOAD_THE_FIRST_MAP_SERIES
               && !( cursorOnMapSeries & IS_TO_LOAD_ALL_THE_MAP_SERIES ) )
        {
            new processedMaps;

            new maximumTries;
            new lastMapSerie;

            new lastDefaultCurrentMapName     [ MAX_MAPNAME_LENGHT ];
            new lastDefaultCurrentMapNameClean[ MAX_MAPNAME_LENGHT ];

            maximumTries = ArraySize( mapcycleFileListArray );

            do
            {
                // Get the map before the `defaultCurrentMapNameClean` to verify whether they belong to the
                // same series and if so, we must to move the cursor.
                defaultCurrentMapIndex = getMapIndexBefore( mapcycleFileListArray, defaultCurrentMapIndex, 1 );
                getNextMapByPosition( mapcycleFileListArray, lastDefaultCurrentMapName, defaultCurrentMapIndex, false, false );

                copy( lastDefaultCurrentMapNameClean, charsmax( lastDefaultCurrentMapNameClean ), lastDefaultCurrentMapName );

                // If the current serie is 1, it will return 2.
                lastMapSerie = getTheCurrentSerieForTheMap( lastDefaultCurrentMapNameClean );

                LOG( 4, "" )
                LOG( 4, "( tryToMoveTheMapCycleCursor ) processedMaps:                  %d", processedMaps                  )
                LOG( 4, "( tryToMoveTheMapCycleCursor ) defaultCurrentMapNameClean:     %s", defaultCurrentMapNameClean     )
                LOG( 4, "( tryToMoveTheMapCycleCursor ) lastDefaultCurrentMapNameClean: %s", lastDefaultCurrentMapNameClean )
                LOG( 4, "" )

                if( lastMapSerie < 3
                    && equali( defaultCurrentMapNameClean, lastDefaultCurrentMapNameClean ) )
                {
                    goto approvedSeries;
                }

            } while( processedMaps++ < maximumTries
                     && equali( defaultCurrentMapNameClean, lastDefaultCurrentMapNameClean ) );

            LOG( 2, "    ( tryToMoveTheMapCycleCursor ) 1. Returning true." )
            return true;
        }

        approvedSeries:

        LOG( 4, "" )
        LOG( 4, "( tryToMoveTheMapCycleCursor ) defaultCurrentMapNameClean: %s", defaultCurrentMapNameClean )
        LOG( 4, "( tryToMoveTheMapCycleCursor ) defaultNextMapNameClean:    %s", defaultNextMapNameClean    )
        LOG( 4, "" )

        // Here we do not update the `defaultNextMapCyclePosition` to the next map beyond the last valid serie,
        // to be able to return to follow the map cycle when the new series is over.
        if( equali( defaultCurrentMapNameClean, defaultNextMapNameClean ) )
        {
            moveTheCursorToTheLastMap( mapcycleFileListArray, defaultCurrentMapNameClean, defaultNextMapCyclePosition );

            LOG( 2, "    ( tryToMoveTheMapCycleCursor ) 2. Returning false." )
            return false;
        }
        else if( isThereNextMapOnTheSerie( defaultNextMapSeries, defaultNextMapNameClean, lastMapName ) )
        {
            moveTheCursorToTheLastMap( mapcycleFileListArray, defaultNextMapNameClean, defaultNextMapCyclePosition );

            LOG( 2, "    ( tryToMoveTheMapCycleCursor ) 3. Returning false." )
            return false;
        }
    }

    LOG( 2, "    ( tryToMoveTheMapCycleCursor ) 4. Returning true." )
    return true;
}

/**
 * Move the current map cycle position to the end of the current series. If it is already on the end
 * or there is not series for the current position, it does nothing, i.e., get stuck where it is now.
 *
 * @param defaultNextMapCyclePosition    is pointing the next map of the default next map on the `defaultCurrentMapNameClean` series.
 */
stock moveTheCursorToTheLastMap( Array:mapcycleFileListArray, const defaultCurrentMapNameClean[], &defaultNextMapCyclePosition )
{
    LOG( 128, "I AM ENTERING ON moveTheCursorToTheLastMap(3)" )

    new maximumTries;
    new processedMaps;

    new nextMapCyclePosition;
    new defaultNextOfNextMapNameClean[ MAX_MAPNAME_LENGHT ];

    maximumTries         = ArraySize( mapcycleFileListArray );
    nextMapCyclePosition = getMapIndexBefore( mapcycleFileListArray, defaultNextMapCyclePosition, 1 );

    getNextMapByPosition( mapcycleFileListArray, defaultNextOfNextMapNameClean, nextMapCyclePosition, false, false );

    // If the current serie is 1, it will return 2.
    nextMapCyclePosition = getTheCurrentSerieForTheMap( defaultNextOfNextMapNameClean );

    LOG( 4, "( moveTheCursorToTheLastMap ) nextMapCyclePosition:          %d", nextMapCyclePosition          )
    LOG( 4, "( moveTheCursorToTheLastMap ) defaultNextMapCyclePosition:   %d", defaultNextMapCyclePosition   )
    LOG( 4, "" )
    LOG( 4, "( moveTheCursorToTheLastMap ) defaultCurrentMapNameClean:    %s", defaultCurrentMapNameClean    )
    LOG( 4, "( moveTheCursorToTheLastMap ) defaultNextOfNextMapNameClean: %s", defaultNextOfNextMapNameClean )
    LOG( 4, "" )
    LOG( 2, "( moveTheCursorToTheLastMap ) Moving the cursor..." )

    // Make sure we are incrementing the sequence on the right series.
    if( equali( defaultCurrentMapNameClean, defaultNextOfNextMapNameClean ) )
    {
        while( processedMaps++ < maximumTries
               && isThereNextMapOnTheSerie( nextMapCyclePosition, defaultCurrentMapNameClean, defaultNextOfNextMapNameClean ) )
        {
            nextMapCyclePosition++;
            defaultNextMapCyclePosition++;

            LOG( 4, "( moveTheCursorToTheLastMap ) nextMapCyclePosition:          %d", nextMapCyclePosition )
            LOG( 4, "( moveTheCursorToTheLastMap ) defaultNextMapCyclePosition:   %d", defaultNextMapCyclePosition )
            LOG( 4, "( moveTheCursorToTheLastMap ) defaultNextOfNextMapNameClean: %s", defaultNextOfNextMapNameClean )
        }
    }

    LOG( 2, "    ( moveTheCursorToTheLastMap ) Returning defaultNextMapCyclePosition: %d", defaultNextMapCyclePosition )
}

/**
 * The `nextMapCyclePosition` is pointing to the actual next map, but we need the index to the map
 * before the next map.
 */
stock getMapIndexBefore( Array:mapcycleFileListArray, nextMapCyclePosition, shifting )
{
    LOG( 128, "I AM ENTERING ON getMapIndexBefore(3) nextMapCyclePosition: %d", nextMapCyclePosition )
    new mapIndexBefore;

    if( mapcycleFileListArray
        && ( mapIndexBefore = ( nextMapCyclePosition - shifting ) ) < 0 )
    {
        // If is it negative, we want to the last map on the array `g_mapcycleFileListArray`.
        if( ( mapIndexBefore = ( ArraySize( mapcycleFileListArray ) - abs( mapIndexBefore ) ) ) < 0 )
        {
            mapIndexBefore = 0;
        }
    }

    LOG( 2, "    ( getMapIndexBefore ) Returning mapIndexBefore: %d", mapIndexBefore )
    return mapIndexBefore;
}

/**
 * Increments by 1, the global variable 'g_nextMapCyclePosition', or set its value to 1.
 *
 * If the map cycles are loaded on the plugin_init(0), and the setting `gal_srv_move_cursor`, is
 * loaded only at the forward plugin_cfg(0). This ways we need to load both and discard the one
 * which was not necessary later when the settings are loaded on the plugin_cfg(0).
 *
 * Therefore we will get a completely wrong `g_nextMapCyclePosition` value which will mess with
 * everything, was the `gal_srv_move_cursor` feature makes both map cycle with different indexes.
 *
 * @param &nextMapCyclePosition     is the next map position following actual next map.
 * @param isUseTheCurrentMapRule    use or not the current map set blocking rule.
 */
stock getNextMapByPosition( Array:mapcycleFileListArray, nextMapName[], &nextMapCyclePosition,
                            bool:isUseTheCurrentMapRule=true, bool:isToIncrementThePosition=true )
{
    LOG( 128, "I AM ENTERING ON getNextMapByPosition(5)" )
    LOG( 4, "( getNextMapByPosition ) nextMapCyclePosition: %d", nextMapCyclePosition )
    LOG( 4, "( getNextMapByPosition ) isUseTheCurrentMapRule: %d", isUseTheCurrentMapRule )
    LOG( 4, "( getNextMapByPosition ) isToIncrementThePosition: %d", isToIncrementThePosition )

    new mapsProcessedNumber;
    new loadedMapName[ MAX_MAPNAME_LENGHT ];

    new mapCycleMapsCount       = ArraySize( mapcycleFileListArray );
    new bool:isWhitelistEnabled = IS_WHITELIST_ENABLED();

    if( mapCycleMapsCount )
    {
        do
        {
            ++mapsProcessedNumber;

            // After reaching the end of the list, start from the first item.
            if( nextMapCyclePosition >= mapCycleMapsCount )
            {
                LOG( 1, "WARNING, getNextMapByPosition: Restarting the map cycle at: %d", nextMapCyclePosition )
                nextMapCyclePosition = 0;

                continue;
            }

            GET_MAP_NAME( mapcycleFileListArray, nextMapCyclePosition, loadedMapName )

            // Sets the index of the next map of the current next map.
            if( isToIncrementThePosition ) ++nextMapCyclePosition;

            // Block the next map cvar to be set to the current map.
            if( isUseTheCurrentMapRule
                && equali( g_currentMapName, loadedMapName ) )
            {
                LOG( 1, "WARNING, getNextMapByPosition: Blocking because this is the currentMap: %s!", loadedMapName )
                continue;
            }
            else if( IS_WHITELIST_BLOCKING( isWhitelistEnabled, loadedMapName ) )
            {
                LOG( 1, "WARNING, getNextMapByPosition: The Whitelist feature is blocking: %s!", loadedMapName )
                continue;
            }

            copy( nextMapName, MAX_MAPNAME_LENGHT - 1, loadedMapName );

            LOG( 4, "( getNextMapByPosition ) nextMapName: %s,", nextMapName )
            LOG( 4, "    ( getNextMapByPosition ) Just returning nextMapCyclePosition: %d", nextMapCyclePosition )

            return nextMapCyclePosition;

        } while( mapsProcessedNumber < mapCycleMapsCount );

        goto setTheCurrentMap;
    }
    else
    {
        setTheCurrentMap:

        // This warning cannot be throw when it is being called from the configureTheAlternateSeries(2), which
        // is trying to calculate the correct next map.
        if( isToIncrementThePosition )
        {
            doAmxxLog( "WARNING, getNextMapByPosition: The current map will probably be set as the next map." );
        }

        nextMapCyclePosition = 0;
        copy( nextMapName, MAX_MAPNAME_LENGHT - 1, g_currentMapName );
    }

    LOG( 4, "( getNextMapByPosition ) nextMapName: %s,", nextMapName )
    LOG( 4, "    ( getNextMapByPosition ) Just returning nextMapCyclePosition: %d", nextMapCyclePosition )

    return nextMapCyclePosition;
}

stock setTheNextMapCvarFlag( nextMapName[] )
{
    LOG( 128, "I AM ENTERING ON setTheNextMapCvarFlag(1) nextMapName: %s", nextMapName )

    if( get_pcvar_num( cvar_nextMapChangeAnnounce )
        && get_pcvar_num( cvar_endOfMapVote ) )
    {
        new nextMapFlag[ 128 ];
        formatex( nextMapFlag, charsmax( nextMapFlag ), "%L", LANG_SERVER, "GAL_NEXTMAP_UNKNOWN" );

        REMOVE_CODE_COLOR_TAGS( nextMapFlag )
        set_pcvar_string( cvar_amx_nextmap, nextMapFlag );

    #if IS_TO_ENABLE_SVEN_COOP_SUPPPORT > 0
        tryToSetGameModCvarString( cvar_mp_nextmap_cycle, nextMapFlag );
    #endif
    }
    else
    {
        set_pcvar_string( cvar_amx_nextmap, nextMapName );
        LOG( 2, "( setTheNextMapCvarFlag ) IS CHANGING THE CVAR 'amx_nextmap' to '%s'.", nextMapName )

    #if IS_TO_ENABLE_SVEN_COOP_SUPPPORT > 0
        tryToSetGameModCvarString( cvar_mp_nextmap_cycle, nextMapName );
    #endif
    }
}

/**
 * The variable 'g_nextMapCyclePosition' is updated also at 'handleServerStart(0)', to refresh the
 * new settings.
 *
 * @param mapcycleFilePath         the current map-cycle file path.
 */
stock saveCurrentMapCycleSetting( const currentMapName[], const mapcycleFilePath[], nextMapCyclePosition )
{
    LOG( 128, "I AM ENTERING ON saveCurrentMapCycleSetting(3)" )

    // At some extreme situations, this can be se to a negative value and we cannot allow it to be saved as it.
    if( ( g_nextMapCyclePosition = nextMapCyclePosition ) < 0 )
    {
        g_nextMapCyclePosition = nextMapCyclePosition = 0;
    }

    new tockenMapcycleAndPosion[ MAX_MAPNAME_LENGHT + MAX_FILE_PATH_LENGHT ];
    formatex( tockenMapcycleAndPosion, charsmax( tockenMapcycleAndPosion ), "%s %d", mapcycleFilePath, nextMapCyclePosition );

    LOG( 2, "( saveCurrentMapCycleSetting ) currentMapName: %s", currentMapName )
    LOG( 2, "( saveCurrentMapCycleSetting ) tockenMapcycleAndPosion: %s", tockenMapcycleAndPosion )

    // save lastmapcycle settings
    set_localinfo( "lastmapcycle"   , tockenMapcycleAndPosion );
    set_localinfo( "galileo_lastmap", currentMapName );
}

stock getNextMapName( nextMapName[], maxChars )
{
    LOG( 128, "I AM ENTERING ON getNextMapName(2) maxChars: %d", maxChars )
    new length = get_pcvar_string( cvar_amx_nextmap, nextMapName, maxChars );

    if( IS_MAP_VALID( nextMapName ) )
    {
        LOG( 4, "    ( getNextMapName ) Returning length: %d, nextMapName: %s", length, nextMapName )
        return length;
    }

    length = copy( nextMapName, maxChars, g_nextMapName );
    set_pcvar_string( cvar_amx_nextmap, g_nextMapName );

    LOG( 2, "( getNextMapName ) IS CHANGING THE CVAR 'amx_nextmap' to '%s'.", g_nextMapName )
    LOG( 1, "    ( getNextMapName ) Returning length: %d, nextMapName: %s", length, nextMapName )
    return length;
}

public sayNextMap()
{
    LOG( 128, "I AM ENTERING ON sayNextMap(0)" )
    new nextMapName[ MAX_MAPNAME_LENGHT ];

    get_pcvar_string( cvar_amx_nextmap, nextMapName, charsmax( nextMapName ) );

    if( get_pcvar_num( cvar_nextMapChangeAnnounce )
        && get_pcvar_num( cvar_endOfMapVote )
        && !( g_voteStatus & IS_VOTE_OVER ) )
    {
        if( g_voteStatus & IS_VOTE_IN_PROGRESS )
        {
            color_chat( 0, "%L %L", LANG_PLAYER, "NEXT_MAP", LANG_PLAYER, "GAL_NEXTMAP_VOTING" );
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
            color_chat( 0, "%L %L", LANG_PLAYER, "NEXT_MAP", LANG_PLAYER, "GAL_NEXTMAP_UNKNOWN" );
        }
    }
    else
    {
        show_the_nextmap_cvar:
        color_chat( 0, "%L ^4%s", LANG_PLAYER, "NEXT_MAP", nextMapName );
    }

    LOG( 4, "( sayNextMap ) cvar_endOfMapVote: %d, cvar_nextMapChangeAnnounce: %d", \
            get_pcvar_num( cvar_endOfMapVote ), get_pcvar_num( cvar_nextMapChangeAnnounce ) )

    LOG( 1, "    ( sayNextMap ) Just Returning PLUGIN_CONTINUE" )
    return PLUGIN_CONTINUE;
}

public sayCurrentMap()
{
    LOG( 128, "I AM ENTERING ON sayCurrentMap(0)" )
    color_chat( 0, "%L:^4 %s", LANG_PLAYER, "PLAYED_MAP", g_currentMapName );
}

public sayFFStatus()
{
    LOG( 128, "I AM ENTERING ON sayFFStatus(0)" )

    color_chat( 0, "%L: ^4%L", \
            LANG_PLAYER, "FRIEND_FIRE", \
            LANG_PLAYER, get_pcvar_num( cvar_mp_friendlyfire ) ? "ON" : "OFF" );
}

public changeMapIntermission()
{
    LOG( 128, "I AM ENTERING ON changeMapIntermission(0)" )

    intermission_hold();
    changeMap();
}

/**
 * If the game to be faster the us to change the level we must to restore the the `cvar_mp_chattime`
 * on plugin_end(0).
 */
stock restoreTheChatTime()
{
    LOG( 128, "I AM ENTERING ON restoreTheChatTime(0) g_originalChatTime: %f", g_originalChatTime )

    if( floatround( g_originalChatTime, floatround_floor ) )
    {
        LOG( 2, "( restoreTheChatTime ) IS CHANGING THE CVAR 'mp_chattime' to '%f'.", g_originalChatTime )
        tryToSetGameModCvarFloat( cvar_mp_chattime, g_originalChatTime );

        g_originalChatTime = 0.0;
    }
}

/**
 * This function call is only triggered by the game event register_event( "30", "changeMap", "a" ).
 *
 * The task `TASKID_SERVER_CHANGE_LEVEL` cannot be removed to stop the map change, because when this
 * is called by the game, there is not turning back and the map will change anyways.
 *
 * This event can be called twice, one by th game engine (not turning back), and the other by me.
 * The former is due the game engine call could take some seconds more to happen, then it would mess
 * with the change timing. Therefore I call it just to be sure the deadline is missed.
 */
public changeMap()
{
    LOG( 128, "I AM ENTERING ON changeMap(0)" )
    new nextmap_name[ MAX_MAPNAME_LENGHT ];

    // mp_chattime defaults to 10 in other mods
    new Float:chatTime = 8.0;

    // So only set/save the chat time at its first called time.
    if( cvar_mp_chattime
        && !floatround( g_originalChatTime, floatround_floor ) )
    {
        chatTime           = get_pcvar_float( cvar_mp_chattime );
        g_originalChatTime = chatTime;

        // make sure mp_chattime is long
        tryToSetGameModCvarFloat( cvar_mp_chattime, chatTime + 2.0 );
        LOG( 2, "( changeMap ) IS CHANGING THE CVAR 'mp_chattime' to '%f'.", chatTime + 2.0 )
    }

    // If this task is already running, just do nothing by here.
    if( !task_exists( TASKID_SERVER_CHANGE_LEVEL ) )
    {
        new length = getNextMapName( nextmap_name, charsmax( nextmap_name ) ) + 1;

        // change with 1.5 sec. delay
        set_task( chatTime, "serverChangeLevel", TASKID_SERVER_CHANGE_LEVEL, nextmap_name, length );
    }
}

stock bool:isAValidMap( mapname[] )
{
    LOG( 128, "I AM ENTERING ON isAValidMap(1) mapname: %s", mapname )

    if( IS_MAP_VALID( mapname ) )
    {
        LOG( 256, "    ( isAValidMap ) Returning true." )
        return true;
    }

    // If the IS_MAP_VALID check failed, check the end of the string
    new length = strlen( mapname ) - 4;

    // The mapname was too short to possibly house the .bsp extension
    if( length < 0 )
    {
        LOG( 256, "    ( isAValidMap ) Returning false. [length < 0]" )
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
            LOG( 256, "    ( isAValidMap ) Returning true." )
            return true;
        }
    }

    LOG( 256, "    ( isAValidMap ) Returning false." )
    return false;
}

stock getTheCurrentSerieForTheMap( mapNameClean[] )
{
    LOG( 256, "" )
    LOG( 256, "I AM ENTERING ON getTheCurrentSerieForTheMap(1) mapNameClean: %s", mapNameClean )

    new mapNameLength;
    new mapNameDirt[ MAX_MAPNAME_LENGHT ];

    mapNameLength = strlen( mapNameClean );
    copy( mapNameDirt, charsmax( mapNameDirt ), mapNameClean );

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

        LOG( 256, "( getTheCurrentSerieForTheMap ) mapNameClean: %s", mapNameClean )

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

    LOG( 256, "( getTheCurrentSerieForTheMap ) mapNameDirt: %s", mapNameDirt )

    // We just to return the next map on the series instead of the current one, which is already loaded.
    if( isdigit( mapNameDirt[ 0 ] ) )
    {
        LOG( 256, "    ( getTheCurrentSerieForTheMap ) Returning: %d", str_to_num( mapNameDirt ) + 1 )
        return str_to_num( mapNameDirt ) + 1;
    }

    // We are returning 0 because someone may try to start their map series naming at 0.
    LOG( 256, "    ( getTheCurrentSerieForTheMap ) Returning 0, no number found." )

    return 0;
}

stock bool:isThereNextMapOnTheSerie( &currentSerie, const mapNameClean[], nextMapName[] )
{
    LOG( 256, "I AM ENTERING ON isThereNextMapOnTheSerie(3) mapNameClean: %s", mapNameClean )
    new currentForwardLook;

    // Look forward to be able to find more spaced sequences as `de_dust2002` and `de_dust2015`.
    do
    {
        formatex( nextMapName, MAX_MAPNAME_LENGHT - 1, "%s%d", mapNameClean, currentSerie );

        if( IS_MAP_VALID( nextMapName ) )
        {
            LOG( 256, "    ( isThereNextMapOnTheSerie ) Returning: true, nextMapName: %s", nextMapName )
            return true;
        }

        // Moves the pointer to the next serie, if it still not find the valid map.
        currentSerie++;

    } while( currentForwardLook++ < MAX_NON_SEQUENCIAL_MAPS_ON_THE_SERIE );

    LOG( 256, "    ( isThereNextMapOnTheSerie ) Returning: false" )
    return false;
}

stock loadTheCursorOnMapSeries( Array:mapArray, Trie:mapTrie, Trie:loadedMapSeriesTrie, currentMapName[],
                                nextMapName[] , &mapCount   , const cursorOnMapSeries )
{
    LOG( 256, "I AM ENTERING ON loadTheCursorOnMapSeries(7) currentMapName: %s", currentMapName )
    new currentSerie;

    new mapNameClean[ MAX_MAPNAME_LENGHT ];
    copy( mapNameClean, charsmax( mapNameClean ), currentMapName );

    // If we are loading only map series starting at 1, block the execution if the initial serie is
    // greater than 2, because this function returns the next map on the series, then if the current
    // serie is 1, it will return 2. Therefore we must to allow it accordantly to the settings.
    if( ( ( currentSerie = getTheCurrentSerieForTheMap( mapNameClean ) ) > 2 )
        && ( cursorOnMapSeries & IS_TO_LOAD_EXPLICIT_MAP_SERIES ) )
    {
        LOG( 256, "    ( loadTheCursorOnMapSeries ) Returning/Blocking the execution." )
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

                LOG( 256, "( loadTheCursorOnMapSeries ) nextMapName: %s", nextMapName )

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

            LOG( 256, "( loadTheCursorOnMapSeries ) nextMapName: %s", nextMapName )

            // Moves the pointer to the next serie.
            currentSerie++;
            mapCount++;
        }
    }
}

stock loadMapFileSeriesListArray( mapFileDescriptor, Array:mapArray, Trie:mapTrie, Trie:loadedMapSeriesTrie, const cursorOnMapSeries )
{
    LOG( 128, "I AM ENTERING ON loadMapFileSeriesListArray(5) mapFileDescriptor: %d", mapFileDescriptor )

    new mapCount;
    new nextMapName  [ MAX_MAPNAME_LENGHT ];
    new loadedMapName[ MAX_MAPNAME_LENGHT ];
    new loadedMapLine[ MAX_MAPNAME_LENGHT ];

    LOG( 8, "( loadMapFileSeriesListArray ) cursorOnMapSeries:   %d", cursorOnMapSeries   )
    LOG( 8, "( loadMapFileSeriesListArray ) loadedMapSeriesTrie: %d", loadedMapSeriesTrie )

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

                LOG( 0, "", printUntilTheNthLoadedMap( mapCount, loadedMapLine ) )

                // We only load the map cycle as series when it is set the `IS_TO_LOAD_THE_FIRST_MAP_SERIES`
                // or `IS_TO_LOAD_ALL_THE_MAP_SERIES` bit flags.
                if( cursorOnMapSeries & ( IS_TO_LOAD_THE_FIRST_MAP_SERIES | IS_TO_LOAD_ALL_THE_MAP_SERIES ) )
                {
                    loadTheCursorOnMapSeries( mapArray, mapTrie, loadedMapSeriesTrie, loadedMapName,
                            nextMapName, mapCount, cursorOnMapSeries );
                }

                ++mapCount;
            }
        }
    }

    LOG( 1, "    ( loadMapFileSeriesListArray ) Returning mapCount: %d", mapCount )
    return mapCount;
}

stock loadMapFileListOnSeries( Array:mapArray, Trie:mapTrie, mapFilePath[] )
{
    LOG( 128, "I AM ENTERING ON loadMapFileListOnSeries(3) mapFilePath: %s", mapFilePath )

    new mapCount;
    new mapFileDescriptor = fopen( mapFilePath, "rt" );

    if( mapFileDescriptor )
    {
        new Trie:loadedMapSeriesTrie;
        new const cursorOnMapSeries = get_pcvar_num( cvar_serverMoveCursor );

        // When the `IS_TO_LOAD_ALL_THE_MAP_SERIES` is set, it overrides the `IS_TO_LOAD_THE_FIRST_MAP_SERIES` bit flag.
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
        checkIfThereEnoughMapPopulated( mapCount, mapFileDescriptor, mapFilePath );

        fclose( mapFileDescriptor );
        LOG( 4, "" )
    }
    else
    {
        LOG( 1, "( loadMapFileListOnSeries ) ERROR %d, %L", AMX_ERR_NOTFOUND, LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilePath )
        log_error( AMX_ERR_NOTFOUND, "%L", LANG_SERVER, "GAL_MAPS_FILEMISSING", mapFilePath );
    }

    LOG( 1, "    ( loadMapFileListOnSeries ) Returning mapCount: %d", mapCount )
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
    LOG( 128, "I AM ENTERING ON map_populateListOnSeries(3) mapFilePath: %s", mapFilePath )

    // load the array with maps
    new mapCount;

    // If there is a map file to load
    if( mapFilePath[ 0 ] )
    {
        if( file_exists( mapFilePath ) )
        {
            // clear the map array in case we're reusing it
            TRY_TO_APPLY( ArrayClear, mapArray )
            TRY_TO_APPLY( TrieClear , mapTrie )

            LOG( 4, "" )
            LOG( 4, "    map_populateListOnSeries(...) Loading the PASSED FILE! mapFilePath: %s", mapFilePath )

            mapCount = loadMapFileListOnSeries( mapArray, mapTrie, mapFilePath );
        }
        else
        {
            doAmxxLog( "ERROR, map_populateListOnSeries: Could not open the file ^"%s^"", mapFilePath );
        }
    }

    LOG( 1, "    I AM EXITING map_populateListOnSeries(3) mapCount: %d", mapCount )
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
    LOG( 128, "I AM ENTERING ON timeleftPluginInit(0)" )

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
    LOG( 128, "I AM ENTERING ON sayTheTime(1) id: %d", id )

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

    color_chat( 0, "^4%L:^1 %s", LANG_PLAYER, "THE_TIME", ctime );

    LOG( 1, "    ( sayTheTime ) Returning PLUGIN_CONTINUE" )
    return PLUGIN_CONTINUE;
}

public sayTimeLeft( id )
{
    LOG( 128, "I AM ENTERING ON sayTimeLeft(1) id: %d", id )

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
            color_chat( 0, "^4%L:^1 %L", LANG_PLAYER, "TIME_LEFT", LANG_PLAYER, "NO_T_LIMIT" );
        }
    }

    return PLUGIN_CONTINUE;
}

stock sayRoundsLeft( id )
{
    LOG( 128, "I AM ENTERING ON sayRoundsLeft(1) id: %d", id )
    new roundsLeft = get_pcvar_num( cvar_mp_maxrounds ) - g_totalRoundsPlayed;

    if( get_pcvar_num( g_amx_time_voice ) )
    {
        speakRemainingInterger( id, roundsLeft );
    }

    color_chat( 0, "^4%L:^1 %d %L", LANG_PLAYER, "TIME_LEFT", roundsLeft, LANG_PLAYER, "GAL_ROUNDS" );
}

stock sayWinLimitLeft( id )
{
    LOG( 128, "I AM ENTERING ON sayWinLimitLeft(1) id: %d", id )
    new winLeft = get_pcvar_num( cvar_mp_winlimit ) - max( g_totalCtWins, g_totalTerroristsWins );

    if( get_pcvar_num( g_amx_time_voice ) )
    {
        speakRemainingInterger( id, winLeft );
    }

    color_chat( 0, "^4%L:^1 %d %L", LANG_PLAYER, "TIME_LEFT", winLeft, LANG_PLAYER, "GAL_ROUNDS" );
}

stock sayFragsLeft( id )
{
    LOG( 128, "I AM ENTERING ON sayFragsLeft(1) id: %d", id )
    new fragsLeft = get_pcvar_num( cvar_mp_fraglimit ) - g_greatestKillerFrags;

    if( get_pcvar_num( g_amx_time_voice ) )
    {
        speakRemainingInterger( id, fragsLeft );
    }

    color_chat( 0, "^4%L:^1 %d %L", LANG_PLAYER, "TIME_LEFT", fragsLeft, LANG_PLAYER, "GAL_FRAGS" );
}

stock sayTimeLeftOn( id )
{
    LOG( 128, "I AM ENTERING ON sayTimeLeftOn(1) id: %d", id )
    new timeLeft = get_timeleft();

    if( get_pcvar_num( g_amx_time_voice ) )
    {
        new speakText[ MAX_COLOR_MESSAGE ];

        setTimeVoice( speakText, charsmax( speakText ), 0, timeLeft );
        client_cmd( id, "%s", speakText );
    }

    color_chat( 0, "^4%L:^1 %d:%02d %L", LANG_PLAYER, "TIME_LEFT", ( timeLeft / 60 ), ( timeLeft % 60 ), LANG_PLAYER, "MINUTES" );
}

stock speakRemainingInterger( id, integer )
{
    LOG( 128, "I AM ENTERING ON speakRemainingInterger(2) id: %d, integer: %d", id, integer )
    new speakText[ MAX_COLOR_MESSAGE ];

    num_to_word( integer, speakText, charsmax( speakText ) );
    client_cmd( id, "spk ^"vox/%s remaining^"", speakText );
}

stock setTimeText( text[], len, tmlf, id )
{
    LOG( 128, "I AM ENTERING ON setTimeText(4) text: %s, len: %d, tmlf: %d, id: %d", text, len, tmlf, id )

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
    LOG( 128, "I AM ENTERING ON setTimeVoice(4) text: %s, len: %d, flags: %d, tmlf: %d", text, len, flags, tmlf )

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
    LOG( 256, "I AM ENTERING ON findDispFormat(1) _time: %d", _time )

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
    LOG( 128, "I AM ENTERING ON setDisplaying(0)" )

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
    LOG( 256, "I AM ENTERING ON timeRemain(0)")

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
        LOG( 128, "I AM ENTERING ON create_fakeVotes(0)" )
        writeToTheDebugFile( DEBUGGER_OUTPUT_LOG_FILE_NAME, "Creating fake votes..." );

        if( g_voteStatus & IS_RUNOFF_VOTE )
        {
            g_arrayOfMapsWithVotesNumber[ 0 ] += 1;     // choice 1
            g_arrayOfMapsWithVotesNumber[ 1 ] += 1;     // choice 2

            g_totalVotesCounted = g_arrayOfMapsWithVotesNumber[ 0 ] + g_arrayOfMapsWithVotesNumber[ 1 ];
        }
        else
        {
            g_arrayOfMapsWithVotesNumber[ 0 ] += 0;     // map 1
            g_arrayOfMapsWithVotesNumber[ 1 ] += 1;     // map 2
            g_arrayOfMapsWithVotesNumber[ 2 ] += 0;     // map 3
            g_arrayOfMapsWithVotesNumber[ 3 ] += 0;     // map 4
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
#if ARE_WE_RUNNING_UNIT_TESTS
    stock configureTheUnitTests()
    {
        LOG( 128, "I AM ENTERING ON configureTheUnitTests(0)" )

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

        TRY_TO_APPLY( ArrayClear, g_test_idsAndNamesArray )
        TRY_TO_APPLY( ArrayClear, g_test_failureIdsArray )
        TRY_TO_APPLY( ArrayClear, g_test_failureReasonsArray )
        TRY_TO_APPLY( TrieClear, g_test_failureIdsTrie )
    }

    /**
     * This function run all tests that are listed at it. Every test that is created must to be called
     * here to register itself at the Test System and perform the testing.
     */
    public runTests()
    {
        LOG( 128, "I AM ENTERING ON runTests(0)" )
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
            print_all_tests_executed( false );
            print_tests_failure();

            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "    After '%d' runtime seconds... Executing the %s's Unit Tests delayed until at least %d seconds: ",
                                     computeTheTestElapsedTime(),          PLUGIN_NAME,                    g_test_maxDelayResult );
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
        LOG( 128, "I AM ENTERING ON show_delayed_results(0)" )
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

            LOG( 1, "( displaysLastTestOk ) numberOfFailures: %d, lastFailure: %d, lastTestId: %d", \
                    numberOfFailures, lastFailure, lastTestId )

            if( !numberOfFailures
                || lastFailure != lastTestId )
            {
                if( g_test_isToEnableLogging
                    && ( DEBUG_LEVEL & 1 ) )
                {
                    print_logger( "OK!" );
                    print_logger( "" );
                    print_logger( "" );
                }
            }
            else if( lastFailure == lastTestId  )
            {
                if( g_test_isToEnableLogging
                    && ( DEBUG_LEVEL & 1 ) )
                {
                    print_logger( "FAILED!" );
                    print_logger( "" );
                    print_logger( "" );
                    print_logger( "" );
                }

                // Blocks the delayed Unit Tests to run, because the chain is broke.
                return false;
            }
        }

        return true;
    }

    stock print_all_tests_executed( bool:isToPrintAllTests = true )
    {
        LOG( 128, "I AM ENTERING ON print_all_tests_executed(1)" )

        if( isToPrintAllTests
            && g_test_isToEnableLogging )
        {
        #if !( DEBUG_LEVEL & DEBUG_LEVEL_DISABLE_TEST_LOGS )
            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "    The following tests were successfully executed: " );
            print_logger( "" );

            new trieKey[ 10 ];
            new test_name[ MAX_SHORT_STRING ];
            new testsNumber = ArraySize( g_test_idsAndNamesArray );

            for( new test_index = 0; test_index < testsNumber; test_index++ )
            {
                num_to_str( test_index + 1, trieKey, charsmax( trieKey ) );

                if( !TrieKeyExists( g_test_failureIdsTrie, trieKey ) )
                {
                    ArrayGetString( g_test_idsAndNamesArray, test_index, test_name, charsmax( test_name ) );
                    print_logger( "       %3d. %s", test_index + 1, test_name );
                }
            }
        #endif
        }
    }

    stock print_tests_failure()
    {
        LOG( 256, "I AM ENTERING ON print_tests_failure(0)" )

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
     * Informs the Test System that the test failed and why. This is to be used directly instead of
     * SET_TEST_FAILURE(1) when 2 consecutive tests use different `test_id`'s.
     *
     * @param test_id              the test_id at the Test System
     * @param isFailure            a boolean value setting whether the failure status is true.
     * @param failure_reason       the reason why the test failed
     */
    stock setTestFailure( test_id, bool:isFailure, failure_reason[] )
    {
        LOG( 256, "I AM ENTERING ON setTestFailure(...) test_id: %d, isFailure: %d, \
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

            if( g_test_isToEnableLogging )
            {
                print_logger( "       TEST FAILURE! %s", failure_reason );
            }

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
        LOG( 256, "I AM ENTERING ON register_test(2) max_delay_result: %d, test_name: %s", max_delay_result, test_name )
        ArrayPushString( g_test_idsAndNamesArray, test_name );

        // All the normal Unit Tests will be finished when the Delayed Unit Test begin. This is used
        // to not show a OK, after to print the Normal Unit Tests Results.
        if( g_lastNormalTestToExecuteId != g_test_testsNumber )
        {
            displaysLastTestOk();
        }

        g_test_testsNumber++;

        if( g_test_isToEnableLogging
            && ( DEBUG_LEVEL & 1 ) )
        {
            print_logger( "        EXECUTING TEST %d AFTER %d WITH UNTIL %d SECONDS DELAYED - %s ",
                    g_test_testsNumber, computeTheTestElapsedTime(), max_delay_result, test_name );
        }

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
            currentCaseNumber = 1;

            if( ( indentation = ( ( currentSerie - 'a' + 1 ) * 3 ) % 15 ) == 0 )
            {
                indentation = 3;
            }

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




    // Here below to start the Unit Tests help functions.
    // ###########################################################################################

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

        return g_test_areTheUnitTestsRunning;
    }

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

        new Array:argumentMapsArray = ArrayCreate( MAX_MAPNAME_LENGHT );

        helper_clearNominationsData();
        argumentsNumber = numargs();

        // To get the maps passed as arguments
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
            ArrayPushString( argumentMapsArray, currentMap );

            LOG( 256, "    ( helper_loadNominations ) currentMap[%d]: %s", currentIndex, currentMap )
        }

        set_pcvar_string( cvar_nomMapFilePath, g_test_nomMapFilePath );
        HELPER_MAP_FILE_LIST_LOAD2( g_test_nomMapFilePath, argumentMapsArray )

        LOG( 4, "( helper_loadNominations ) file '%s' exists: %d", g_test_nomMapFilePath, file_exists( g_test_nomMapFilePath ) )

        new mapFilePath[ MAX_FILE_PATH_LENGHT ];
        loadNominationList( mapFilePath );

        // To load the maps passed as arguments as nominations
        for( new currentIndex = 0; currentIndex < argumentsNumber; ++currentIndex )
        {
            ArrayGetString( argumentMapsArray, currentIndex, currentMap, charsmax( currentMap ) );
            setPlayerNominationMapIndex( playerId++, optionIndex, currentIndex );
        }

        LOG( 4, "( helper_loadNominations ) g_nominationLoadedMapsArray: %d", g_nominationLoadedMapsArray )
        LOG( 4, "( helper_loadNominations ) ArraySize:                   %d", ArraySize( g_nominationLoadedMapsArray ) )

        ArrayDestroy( argumentMapsArray );
    }

    /**
     * To create a map file list on the specified file path on the disk.
     *
     * @param replace              true if is to replace `[` `]` by `{` `}`, false if not.
     * @param mapFileListPath      the path to the mapFileList.
     * @param mapFileList          the variable number of maps.
     */
    stock helper_mapFileListLoadReplace( bool:replace, mapFileListPath[], ... )
    {
        new stringIndex;
        new currentIndex;
        new fileDescriptor;
        new currentMap[ MAX_MAPNAME_LENGHT ];

        // delete_file( mapFileListPath );
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
     * To create a map file list on the specified file path on the disk.
     *
     * @param replace              true if is to replace `[` `]` by `{` `}`, false if not.
     * @param mapFileListPath      the path to the mapFileList.
     * @param mapFileListArray     an Dynamic Array within a variable number of maps.
     */
    stock helper_mapFileListLoadReplace2( bool:replace=false, mapFileListPath[], Array:mapFileListArray )
    {
        new currentIndex;
        new fileDescriptor;
        new currentMap[ MAX_MAPNAME_LENGHT ];

        // delete_file( mapFileListPath );
        fileDescriptor = fopen( mapFileListPath, "wt" );

        if( fileDescriptor )
        {
            new argumentsNumber = ArraySize( mapFileListArray );

            // To load the maps passed as arguments
            for( currentIndex = 0; currentIndex < argumentsNumber; ++currentIndex )
            {
                ArrayGetString( mapFileListArray, currentIndex, currentMap, charsmax( currentMap ) );

                if( replace )
                {
                    replace_all( currentMap, charsmax( currentMap ), "[", "{" );
                    replace_all( currentMap, charsmax( currentMap ), "]", "{" );
                }

                LOG( 256, "    ( helper_mapFileListLoadReplace2 ) currentMap[%d]: %s", currentIndex, currentMap )
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
        TRY_TO_APPLY( ArrayClear, g_nominationLoadedMapsArray )
    }

    stock toPrintTheVotingMenuForAnalysis()
    {
        for( new currentIndex = 0; currentIndex < sizeof g_votingMapNames; ++currentIndex )
        {
            LOG( 1, "g_votingMapNames[%d]: %s %s", currentIndex, g_votingMapNames[ currentIndex ], g_votingMapInfos[ currentIndex ] )
        }
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
    // This is the 'startTheVoting(1)' tests chain beginning. Because the 'startTheVoting(1)' cannot
    // to be tested simultaneously. Then, all tests that involves the 'startTheVoting(1)' chain, must
    // to be executed sequentially after this chain end. This is the 1º chain test.
    // ###########################################################################################

    /**
     * 1. Tests if the ... this is model to create new tests. Duplicate this example code and
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




    // Place new 'startTheVoting(1)' chain tests above here.
    // ############################################################################################

    /**
     * This is a simple test to verify the basic registering test functionality.
     */
    stock test_registerTest()
    {
        new test_id;
        new errorMessage   [ MAX_LONG_STRING ];
        new first_test_name[ MAX_SHORT_STRING ];

        test_id = register_test( 0, "test_registerTest_case1" );
        ERR( "g_test_testsNumber must be 1 (it was %d)", g_test_testsNumber )
        setTestFailure( test_id, g_test_testsNumber != 1, errorMessage );

        test_id = register_test( 0, "test_registerTest_case2" );
        ERR( "test_id must be 2 (it was %d)", test_id )
        setTestFailure( test_id, test_id != 2, errorMessage );

        ArrayGetString( g_test_idsAndNamesArray, 0, first_test_name, charsmax( first_test_name ) );

        test_id = register_test( 0, "test_registerTest_case3" );
        ERR( "first_test_name must be 'test_registerTest_case1' (it was %s)", first_test_name )
        setTestFailure( test_id, !equali( first_test_name, "test_registerTest_case1" ), errorMessage );
    }

    /**
     * Test for client connect cvar_isToStopEmptyCycle behavior.
     */
    stock test_isInEmptyCycle()
    {
        new test_id;
        new errorMessage[ MAX_LONG_STRING ];

        set_pcvar_num( cvar_isToStopEmptyCycle, 1 );
        client_authorized_stock( .player_id = 1  );

        test_id = register_test( 0, "test_isInEmptyCycle1" );
        ERR( "cvar_isToStopEmptyCycle must be 0 (it was %d)", get_pcvar_num( cvar_isToStopEmptyCycle ) )
        setTestFailure( test_id, get_pcvar_num( cvar_isToStopEmptyCycle ) != 0, errorMessage );

        set_pcvar_num( cvar_isToStopEmptyCycle, 0 );
        client_authorized_stock( .player_id = 1 );

        test_id = register_test( 0, "test_isInEmptyCycle2" );
        ERR( "cvar_isToStopEmptyCycle must be 0 (it was %d)", get_pcvar_num( cvar_isToStopEmptyCycle ) )
        setTestFailure( test_id, get_pcvar_num( cvar_isToStopEmptyCycle ) != 0, errorMessage );
    }

    /**
     * To call the general test handler 'test_mapGetNext_case(4)' using test scenario cases.
     */
    stock test_mapGetNext_cases()
    {
        new Array:testMapListArray = ArrayCreate( MAX_MAPNAME_LENGHT );

        ArrayPushString( testMapListArray, "de_dust2"   );
        ArrayPushString( testMapListArray, "de_inferno" );
        ArrayPushString( testMapListArray, "de_dust4"   );
        ArrayPushString( testMapListArray, "de_dust"    );

        test_mapGetNext_case( testMapListArray, "de_dust"    , "de_dust2"  ,  0 ); // Case 1
        test_mapGetNext_case( testMapListArray, "de_dust2"   , "de_inferno",  1 ); // Case 2
        test_mapGetNext_case( testMapListArray, "de_inferno" , "de_dust4"  ,  2 ); // Case 3
        test_mapGetNext_case( testMapListArray, "de_inferno2", "de_dust2"  , -1 ); // Case 4

        ArrayDestroy( testMapListArray );
    }

    /**
     * This is a general test handler for the function 'map_getNext(4)'.
     *
     * @param testMapListArray        an Array with a map-cycle for loading
     * @param currentMap              an string as the current map
     * @param nextMapAim              an string as the desired next map
     * @param mapIndexAim             the desired next map index
     */
    stock test_mapGetNext_case( Array:testMapListArray, const currentMap[], const nextMapAim[], mapIndexAim )
    {
        static currentCaseNumber = 0;

        new test_id;
        new mapIndex;
        new nextMapName [ MAX_MAPNAME_LENGHT ];
        new testName    [ MAX_SHORT_STRING ];
        new errorMessage[ MAX_LONG_STRING ];

        formatex( testName, charsmax( testName ), "test_mapGetNext_case%d", ++currentCaseNumber );
        test_id  = register_test( 0, testName );

        mapIndex = map_getNext( testMapListArray, currentMap, nextMapName, "test_mapGetNext_case" );

        ERR( "The nextMapName must to be '%s'! But it was %s.", nextMapAim, nextMapName )
        setTestFailure( test_id, !equali( nextMapName, nextMapAim ), errorMessage );

        formatex( testName, charsmax( testName ), "test_mapGetNext_case%d", ++currentCaseNumber );
        test_id  = register_test( 0, testName );

        ERR( "The mapIndex must to be %d! But it was %d.", mapIndexAim, mapIndex )
        setTestFailure( test_id, mapIndex != mapIndexAim, errorMessage );
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

        ERR( "The hour %2d must %sto be loaded at [%d-%d]!", currentHour, ( isToLoad ? "" : "not " ), startHour, endHour )
        setTestFailure( test_id, loadResult != isToLoad, errorMessage );
    }

    /**
     * This is a configuration loader for the 'loadWhiteListFile(4)' function testing.
     */
    stock test_loadCurrentBlackList_load( bool:replace )
    {
        helper_mapFileListLoadReplace
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

        test_loadNextWhiteListGroupClos( 'a', true  );
        test_loadNextWhiteListGroupClos( 'b', false );

        test_loadNextWhiteListGroupOpen( 'c', false );
        test_loadNextWhiteListGroupOpen( 'a', true  );

        test_loadCurrentBlackList_load( false );

        test_loadCurrentBlacklistMapsOp( 'c', false );
        test_loadCurrentBlacklistMapsOp( 'a', true  );

        test_loadCurrentBlackList_load( true );

        test_loadCurrentBlacklistMapsCl( 'b', false );
        test_loadCurrentBlacklistMapsCl( 'd', true  );
    }

    stock test_loadCurrentBlacklistMapsCl( s, bool:isBlackList )
    {
        test_loadCurrentBlacklist_case( s, isBlackList, 12, "de_dust2" , "de_dust7"  ); // Case 1/2
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust4" , ""          ); // Case 3/4
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust5" , ""          ); // Case 3/4
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust7" , "de_dust2"  ); // Case 5/6
        test_loadCurrentBlacklist_case( s, isBlackList, 24, "de_dust1" , ""          ); // Case 7/8
        test_loadCurrentBlacklist_case( s, isBlackList, 24, "de_dust4" , ""          ); // Case 7/8
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust7" , "de_dust8"  ); // Case 9/10
        test_loadCurrentBlacklist_case( s, isBlackList, 22, "de_dust7" , ""          ); // Case 11/12
        test_loadCurrentBlacklist_case( s, isBlackList, 22, "de_dust8" , ""          ); // Case 11/12
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust5" , "de_dust1"  ); // Case 13/14
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust6" , "de_dust2"  ); // Case 15/16
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust7" , "de_dust3"  ); // Case 17/18
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust4" , ""          ); // Case 19/20
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust5" , ""          ); // Case 19/20
        test_loadCurrentBlacklist_case( s, isBlackList, 2 , "de_dust6" , "de_dust11" ); // Case 21/22
        test_loadCurrentBlacklist_case( s, isBlackList, 4 , "de_dust13", "de_dust4"  ); // Case 23/24

        test_loadCurrentBlacklist_case( s, isBlackList, 0 , "de_dust14", ""          ); // Case 25
        test_loadCurrentBlacklist_case( s, isBlackList, 0 , "de_dust15", ""          ); // Case 26
        test_loadCurrentBlacklist_case( s, isBlackList, 0 , "de_dust16", ""          ); // Case 27

        test_loadCurrentBlacklist_case( s, isBlackList, 1 , "de_dust14", ""          ); // Case 28
        test_loadCurrentBlacklist_case( s, isBlackList, 1 , "de_dust15", ""          ); // Case 29
        test_loadCurrentBlacklist_case( s, isBlackList, 1 , "de_dust16", ""          ); // Case 30
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust14", ""          ); // Case 31
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust15", ""          ); // Case 32
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust16", ""          ); // Case 33
        test_loadCurrentBlacklist_case( s, isBlackList, 12, "de_dust14", ""          ); // Case 34
        test_loadCurrentBlacklist_case( s, isBlackList, 12, "de_dust15", ""          ); // Case 35
        test_loadCurrentBlacklist_case( s, isBlackList, 12, "de_dust16", ""          ); // Case 36

        test_loadCurrentBlacklist_case( s, isBlackList, 1 , ""         , "de_dust17" ); // Case 37
        test_loadCurrentBlacklist_case( s, isBlackList, 1 , ""         , "de_dust18" ); // Case 38
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust17", ""          ); // Case 39
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust18", ""          ); // Case 40
        test_loadCurrentBlacklist_case( s, isBlackList, 12, ""         , "de_dust17" ); // Case 41
        test_loadCurrentBlacklist_case( s, isBlackList, 12, ""         , "de_dust18" ); // Case 42
    }

    stock test_loadCurrentBlacklistMapsOp( s, bool:isBlackList )
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

        test_loadCurrentBlacklist_case( s, isBlackList, 0 , ""         , "de_dust14" ); // Case 25
        test_loadCurrentBlacklist_case( s, isBlackList, 0 , ""         , "de_dust15" ); // Case 26
        test_loadCurrentBlacklist_case( s, isBlackList, 0 , ""         , "de_dust16" ); // Case 27

        test_loadCurrentBlacklist_case( s, isBlackList, 1 , "de_dust14", ""          ); // Case 28
        test_loadCurrentBlacklist_case( s, isBlackList, 1 , "de_dust15", ""          ); // Case 29
        test_loadCurrentBlacklist_case( s, isBlackList, 1 , "de_dust16", ""          ); // Case 30
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust14", ""          ); // Case 31
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust15", ""          ); // Case 32
        test_loadCurrentBlacklist_case( s, isBlackList, 23, "de_dust16", ""          ); // Case 33
        test_loadCurrentBlacklist_case( s, isBlackList, 12, "de_dust14", ""          ); // Case 34
        test_loadCurrentBlacklist_case( s, isBlackList, 12, "de_dust15", ""          ); // Case 35
        test_loadCurrentBlacklist_case( s, isBlackList, 12, "de_dust16", ""          ); // Case 36

        test_loadCurrentBlacklist_case( s, isBlackList, 1 , ""         , "de_dust17" ); // Case 37
        test_loadCurrentBlacklist_case( s, isBlackList, 1 , ""         , "de_dust18" ); // Case 38
        test_loadCurrentBlacklist_case( s, isBlackList, 23, ""         , "de_dust17" ); // Case 39
        test_loadCurrentBlacklist_case( s, isBlackList, 23, ""         , "de_dust18" ); // Case 40
        test_loadCurrentBlacklist_case( s, isBlackList, 12, ""         , "de_dust17" ); // Case 41
        test_loadCurrentBlacklist_case( s, isBlackList, 12, ""         , "de_dust18" ); // Case 42
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

    stock test_loadCurrentBlacklist_caseT( serie, bool:isBlackList, currentHour, map_existent[], not_existent[] )
    {
        new test_id;
        new errorMessage[ MAX_LONG_STRING ];

        new Trie: blackListTrie      = TrieCreate();
        new Array:whitelistFileArray = ArrayCreate( MAX_LONG_STRING );

        loadWhiteListFileFromFile( whitelistFileArray, g_test_whiteListFilePath );
        loadWhiteListFile( currentHour, blackListTrie, whitelistFileArray, isBlackList );

        if( map_existent[ 0 ] )
        {
            test_id = test_registerSeriesNaming( "test_loadCurrentBlacklist", serie );

            ERR( "The map '%s' must to be present on the trie, but it was not!", map_existent )
            setTestFailure( test_id, !TrieKeyExists( blackListTrie, map_existent ), errorMessage );
        }

        if( not_existent[ 0 ] )
        {
            test_id = test_registerSeriesNaming( "test_loadCurrentBlacklist", serie );

            ERR( "The map '%s' must not to be present on the trie, but it was!", not_existent )
            setTestFailure( test_id, TrieKeyExists( blackListTrie, not_existent ), errorMessage );
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
        set_pcvar_num( cvar_fragLimitSupport, 1 );
        mp_fraglimitCvarSupport();

        g_test_isToUseStrictValidMaps = true;

        test_resetRoundsScores_loader( 90, 60, 31, 60  ); // Case  1-4 , 90 - 60 + 31 - 1 = 60
        test_resetRoundsScores_loader( 90, 20, 31, 100 ); // Case  5-8 , 90 - 20 + 31 - 1 = 100
        test_resetRoundsScores_loader( 20, 15, 11, 15  ); // Case  9-12, 20 - 15 + 11 - 1 = 15
        test_resetRoundsScores_loader( 60, 50, 1 , 10  ); // Case 13-16, 60 - 50 + 1  - 1 = 10
        test_resetRoundsScores_loader( 60, 59, 1 , 1   ); // Case 17-20, 60 - 59 + 1  - 1 = 1
        test_resetRoundsScores_loader( 60, 60, 1 , 60  ); // Case 21-24, 60 - 60 + 1  - 1 = 60
        test_resetRoundsScores_loader( 60, 59, 0 , 60  ); // Case 25-28, 60 - 59 + 0  - 1 = 60
        test_resetRoundsScores_loader( 60, 20, 0 , 60  ); // Case 29-32, 60 - 20 + 0  - 1 = 60
        test_resetRoundsScores_loader( 60, 80, 10, 60  ); // Case 33-36, 60 - 80 + 10 - 1 = 60

        g_test_isToUseStrictValidMaps = false;
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

        ERR( "The aim result '%d' was not achieved! The result was %d.", aimResult, changeResult )
        setTestFailure( test_id, changeResult != aimResult, errorMessage );
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

        test_loadVoteChoices_serie_a();
        test_loadVoteChoices_serie_b();
        test_loadVoteChoices_serie_c();
        test_loadVoteChoices_serie_d();
    }

    /**
     * PART 1: Nominates some maps and create the vote map file and minimum players map file.
     */
    stock test_loadVoteChoices_serie_a()
    {
        HELPER_MAP_FILE_LIST_LOAD( g_test_voteMapFilePath   , "de_dust1", "de_dust2" )
        HELPER_MAP_FILE_LIST_LOAD( g_test_minPlayersFilePath, "de_rain" , "de_nuke" )
        HELPER_MAP_FILE_LIST_LOAD( g_test_whiteListFilePath , "[0-23]"  , "de_rain", "de_nuke" )

        // Forced the minimum players feature map to be loaded.
        g_test_aimedPlayersNumber = 1;

        // To force the lists to be reloaded.
        loadMapFiles( false );

        helper_loadNominations( "de_rain", "de_inferno", "as_trunda" );
        loadTheDefaultVotingChoices();

        test_loadVoteChoices_case( "de_rain", "de_inferno", 'a' ); // Case 1
        test_loadVoteChoices_case( "de_nuke", "as_trunda" );       // Case 2
    }

    /**
     * PART 2: Force the minimum players feature to work.
     */
    stock test_loadVoteChoices_serie_b()
    {
        HELPER_MAP_FILE_LIST_LOAD( g_test_voteMapFilePath   , "de_dust1", "de_dust2" )
        HELPER_MAP_FILE_LIST_LOAD( g_test_minPlayersFilePath, "de_rain" , "de_nuke" )
        HELPER_MAP_FILE_LIST_LOAD( g_test_whiteListFilePath , "[0-23]"  , "de_rain", "de_nuke" )

        // Disables the minimum players feature.
        g_test_aimedPlayersNumber = 5;

        // To force the lists to be reloaded.
        loadMapFiles( false );

        helper_loadNominations( "de_rain", "de_inferno", "as_trunda" );
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
        HELPER_MAP_FILE_LIST_LOAD( g_test_voteMapFilePath   , "de_dust1", "de_dust2" )
        HELPER_MAP_FILE_LIST_LOAD( g_test_minPlayersFilePath, "de_rats" , "de_train" )
        HELPER_MAP_FILE_LIST_LOAD( g_test_whiteListFilePath , "[0-23]"  , "de_rats", "de_train" )

        // Forced the minimum players feature map to be loaded.
        g_test_aimedPlayersNumber = 1;

        // To force the lists to be reloaded.
        loadMapFiles( false );

        helper_loadNominations( "de_dust2002v2005_forEver2009", "de_dust2002v2005_forEver2010", "de_dust2002v2005_forEver2011",
                                       "de_dust2002v2005_forEver2012", "de_dust2002v2005_forEver2013", "de_dust2002v2005_forEver2014",
                                       "de_dust2002v2005_forEver2015", "de_dust2002v2005_forEver2016", "de_dust2002v2005_forEver2017" );
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
        HELPER_MAP_FILE_LIST_LOAD( g_test_voteMapFilePath   , "de_dust1", "de_dust2" )
        HELPER_MAP_FILE_LIST_LOAD( g_test_minPlayersFilePath, "de_rain" , "de_nuke" )
        HELPER_MAP_FILE_LIST_LOAD( g_test_whiteListFilePath , "[0-23]"  , "de_rain", "de_nuke" )

        // Disables the minimum players feature.
        g_test_aimedPlayersNumber = 5;

        // To force the lists to be reloaded.
        loadMapFiles( false );

        helper_loadNominations( "de_rain", "de_inferno", "as_trunda" );
        loadTheDefaultVotingChoices();

        test_loadVoteChoices_case( "de_rain"   , "", 'd' );   // Case 1
        test_loadVoteChoices_case( "de_inferno", "de_nuke" ); // Case 2
        test_loadVoteChoices_case( "as_trunda" , "de_nuke" ); // Case 3
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
        test_loadVoteChoices_check( newSeries, requiredMap, true );
        test_loadVoteChoices_check( newSeries, blockedMap, false );
    }

    /**
     * @see test_loadVoteChoices_case(3)
     */
    stock test_loadVoteChoices_check( newSeries, mapToCheck[], bool:isToBePresent )
    {
        new bool:isMapPresent;
        new      currentIndex;
        new      errorMessage[ MAX_LONG_STRING ];

        new test_id = test_registerSeriesNaming( "test_loadVoteChoices", newSeries );
        toPrintTheVotingMenuForAnalysis();

        if( mapToCheck[ 0 ] )
        {
            for( currentIndex = 0; currentIndex < sizeof g_votingMapNames; ++currentIndex )
            {
                if( equali( g_votingMapNames[ currentIndex ], mapToCheck ) )
                {
                    isMapPresent = true;
                }
            }

            ERR( "The map '%s' %s be present on the voting map menu.", mapToCheck, ( isToBePresent ? "must to" : "MUST NOT to" ) )
            setTestFailure( test_id, isMapPresent != isToBePresent, errorMessage );
        }
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
        HELPER_MAP_FILE_LIST_LOAD( g_test_nomMapFilePath, "de_test_dust1", "de_test_dust2", "de_test_dust3", "de_test_dust4" )

        new mapFilePath[ MAX_FILE_PATH_LENGHT ];
        loadNominationList( mapFilePath );

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

        ERR( "Must to be %d nominations, instead of %d.", total_Nom, nominationsCount )
        setTestFailure( test_id, nominationsCount != total_Nom, errorMessage );
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

        g_test_aimedPlayersNumber = 7;
        set_pcvar_float( cvar_rtvRatio, 0.5 );
        set_pcvar_num( cvar_serverPlayersCount, 0 );

        // Add a RTV for the player 1
        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 1, .action = 'a' ); // Case 1
        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 1, .action = 'a' ); // Case 2
        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 1, .action = 'a' ); // Case 3

        test_RTVAndUnRTV( .player_id = 2, .total_RTVs = 2, .action = 'a' ); // Case 4
        test_RTVAndUnRTV( .player_id = 2, .total_RTVs = 2, .action = 'a' ); // Case 5
        test_RTVAndUnRTV( .player_id = 2, .total_RTVs = 1, .action = 'r' ); // Case 6
        test_RTVAndUnRTV( .player_id = 2, .total_RTVs = 1, .action = 'r' ); // Case 7

        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 0, .action = 'r' ); // Case 8
        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 0, .action = 'r' ); // Case 9
        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 0, .action = 'r' ); // Case 10
        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 0, .action = 'r' ); // Case 11

        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 1, .action = 'a' ); // Case 12
        test_RTVAndUnRTV( .player_id = 2, .total_RTVs = 2, .action = 'a' ); // Case 13
        test_RTVAndUnRTV( .player_id = 3, .total_RTVs = 3, .action = 'a' ); // Case 14

        cancelVoting();
        test_RTVAndUnRTV( .player_id = 1, .total_RTVs = 0, .action = '.' ); // Case 15
    }

    /**
     * To test the RTV feature. Simulates a non-RTV vote player disconnecting.
     */
    stock test_negativeRTVValues_load()
    {
        g_rtvWaitMinutes     = 0.0;
        g_rtvWaitRounds      = 0;
        g_rtvWaitFrags       = 0;
        g_rtvWaitAdminNumber = 0;

        set_pcvar_float( cvar_rtvRatio, 0.5 );

        // Add RTV votes for some players
        g_test_aimedPlayersNumber = 10;
        vote_rock( 1 );
        vote_rock( 2 );
        vote_rock( 3 );
        vote_rock( 4 );

        test_negativeRTVValues(  7, 1 ); // Case 1
        test_negativeRTVValues(  8, 1 ); // Case 2 <- The voting must to start here therefore reset the count
        test_negativeRTVValues(  9, 4 ); // Case 3
        test_negativeRTVValues( 10, 4 ); // Case 4
    }

    /**
     * Create one case test for the RTV feature based on its parameters passed by the
     * test_negativeRTVValues_load(0) loader function.
     */
    stock test_negativeRTVValues( playerToDisconnect, aimRtvCount )
    {
        new test_id;
        new readRtvCount;

        new errorMessage[ MAX_LONG_STRING ];
        test_id = test_registerSeriesNaming( "test_negativeRTVValues", 'c' );

        clientDisconnected( playerToDisconnect );

        // It is expected to the voting to start sometimes, therefore we must properly close it.
        if( g_voteStatus & IS_VOTE_IN_PROGRESS )
        {
            cancelVoting();
        }

        readRtvCount = vote_getRocksNeeded();
        g_test_aimedPlayersNumber = g_test_aimedPlayersNumber - 1;

        ERR( "Must to be %d RTVs needed, instead of %d.", aimRtvCount, readRtvCount )
        setTestFailure( test_id, aimRtvCount != readRtvCount, errorMessage );
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

        ERR( "Must to be %d RTVs, instead of %d.", total_RTVs, g_rockedVoteCount )
        setTestFailure( test_id, g_rockedVoteCount != total_RTVs, errorMessage );
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
        new test_id;
        new errorMessage[ MAX_LONG_STRING ];

        TRY_TO_APPLY( getUniqueRandomInteger, holder )
        static sequence = -1;

        new trieSize;
        new sortedInterger;

        new sortedIntergerString[ 6 ];
        new Trie:sortedIntegers = TrieCreate();

        sequence++;
        test_id = test_registerSeriesNaming( "test_getUniqueRandomIntBasic", 'a' );

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

            ERR( "The integer %d, must not to be sorted twice.", sortedInterger )
            setTestFailure( test_id, TrieKeyExists( sortedIntegers, sortedIntergerString ) && sortedInterger != -1, errorMessage );

            if( !TrieKeyExists( sortedIntegers, sortedIntergerString ) )
            {
                TrieSetCell( sortedIntegers, sortedIntergerString, index ) ? trieSize++ : trieSize;
            }
        }

        test_id = test_registerSeriesNaming( "test_getUniqueRandomIntBasic", 'a' );
        ERR( "The TrieSize must to be %d, instead of %d.", max_value + 2, trieSize )
        setTestFailure( test_id, trieSize != max_value + 2, errorMessage );

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
        new test_id;
        new errorMessage[ MAX_LONG_STRING ];

        new trieSize;
        new sortedInterger;

        new sortedIntergerString[ 6 ];
        new Trie:sortedIntegers = TrieCreate();
        new randomCount         = max_value - min_value + 1;

        static sequence = -1;
        sequence++;

        test_id = test_registerSeriesNaming( "test_getUniqueRandomInteger", 'c' );

        for( new index = 0; index < max_value + 1 ; index++ )
        {
            sortedInterger = getUniqueRandomInteger( holder, min_value, max_value );
            num_to_str( sortedInterger, sortedIntergerString, charsmax( sortedIntergerString ) );

            ERR( "The integer %d, must not to be sorted twice.", sortedInterger )
            setTestFailure( test_id, TrieKeyExists( sortedIntegers, sortedIntergerString ), errorMessage );

            if( !TrieKeyExists( sortedIntegers, sortedIntergerString ) )
            {
                TrieSetCell( sortedIntegers, sortedIntergerString, index ) ? trieSize++ : 0;
            }
        }

        test_id = test_registerSeriesNaming( "test_getUniqueRandomInteger", 'c' );
        ERR( "The TrieSize must to be %d, instead of %d.", max_value, trieSize )
        setTestFailure( test_id, trieSize != randomCount, errorMessage );

        LOG( 1, "" )
        test_id = test_registerSeriesNaming( "test_getUniqueRandomInteger", 'c' );

        for( new index = 0; index < max_value + 1 ; index++ )
        {
            sortedInterger = getUniqueRandomInteger( holder, min_value, max_value );
            num_to_str( sortedInterger, sortedIntergerString, charsmax( sortedIntergerString ) );

            ERR( "The integer %d, must to be sorted twice.", sortedInterger )
            setTestFailure( test_id, !TrieKeyExists( sortedIntegers, sortedIntergerString ), errorMessage );

            if( !TrieKeyExists( sortedIntegers, sortedIntergerString ) )
            {
                TrieSetCell( sortedIntegers, sortedIntergerString, index ) ? trieSize++ : 0;
            }
        }

        test_id = test_registerSeriesNaming( "test_getUniqueRandomInteger", 'c' );
        ERR( "The TrieSize must to be %d, instead of %d.", max_value, trieSize )
        setTestFailure( test_id, trieSize != randomCount, errorMessage );

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

        LOG( 32, "( test_whatGameEndingTypeIt ) timelimit: %d", floatround( get_pcvar_float( cvar_mp_timelimit ) * 60 ) )

        if( time > 0.0 )
        {
            tryToSetGameModCvarFloat( cvar_mp_timelimit,
                    ( get_pcvar_float( cvar_mp_timelimit ) * 60
                      - get_timeleft()
                      + limit
                    ) / 60 );
        }

        LOG( 32, "( test_whatGameEndingTypeIt ) timelimit: %d", floatround( get_pcvar_float( cvar_mp_timelimit ) * 60 ) )

        gameType = whatGameEndingTypeItIs();

        ERR( "The GameEndingType must to be %d, instead of %d.", result, gameType )
        setTestFailure( test_id, gameType != result, errorMessage );
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

        ERR( "Converting the number %d on base %d to base %d must to be %d, instead of %d.", \
                origin_number, origin_base, destiny_base, expected, result )

        setTestFailure( test_id, result != expected, errorMessage );
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

        ERR( "The converted page `%s` must to be %d, instead of %d (%s).", \
                pageString2, expectedPage, menuPages[ player_id ], pageString )

        setTestFailure( test_id, menuPages[ player_id ] != expectedPage, errorMessage );
    }

    /**
     * Tests if the function helper_loadStrictValidMapsTrie() is properly loading its maps bytes
     * isAllowedValidMapByTheUnitTests(1).
     */
    stock test_strictValidMapsTrie_load()
    {
        g_test_isToUseStrictValidMaps = true;

        HELPER_MAP_FILE_LIST_LOAD( g_test_voteMapFilePath, "de_dust1", "de_dust2", "de_nuke", "de_dust2" )
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

        ERR( "The map `%s` must %sto be loaded on the trie.", mapName, isNotToBe ? "not " : "" )
        setTestFailure( test_id, TrieKeyExists( g_test_strictValidMapsTrie, mapName ) == isNotToBe, errorMessage );
    }

    /**
     * To prepare the test_populateListOnSeries_loada(0) tests files and settings.
     */
    stock test_populateListOnSeries_build( s, Array:populatedArray, Trie:populatedTrie, expectedSize, bool:isFull )
    {
        new test_id;
        new mapCount;

        new errorMessage[ MAX_LONG_STRING ];
        test_id = test_registerSeriesNaming( isFull ? "test_configureTheNextMap" : "test_populateListOnSeries", s );

        HELPER_MAP_FILE_LIST_LOAD( g_test_voteMapFilePath, "de_dust1", "de_dust2", "de_nuke", "de_dust2" )
        helper_loadStrictValidMapsTrie( "de_dust1", "de_dust2", "de_dust5", "de_dust6", "de_nuke" );

        g_test_isToUseStrictValidMaps = true;

        if( isFull )
        {
            set_pcvar_string( cvar_mapcyclefile, g_test_voteMapFilePath );
            mapCount = configureTheNextMapSetttings( errorMessage );
        }
        else
        {
            mapCount = map_populateListOnSeries( populatedArray, populatedTrie, g_test_voteMapFilePath );
        }

        g_test_isToUseStrictValidMaps = false;

        for( new index = 0; index < ArraySize( populatedArray ); index++ )
        {
            ArrayGetString( populatedArray, index, errorMessage, charsmax( errorMessage ) );
            LOG( 1, "populatedArray index: %d, mapName: %s", index, errorMessage )
        }

        ERR( "The map populatedArray size must to be %d, instead of %d.", expectedSize, mapCount )
        setTestFailure( test_id, mapCount != expectedSize, errorMessage );
    }

    stock test_populateListOnSeries_load()
    {
        test_populateListOnSeries_loada( 'a' );
        test_populateListOnSeries_loadb( 'b' );
        test_populateListOnSeries_loadc( 'c' );
    }

    /**
     * Tests if the function map_populateListOnSeries(3) is properly loading the maps series.
     */
    stock test_populateListOnSeries_loada( s, bool:is=false )
    {
        new Trie:populatedTrie   = TrieCreate();
        new Array:populatedArray = ArrayCreate( MAX_MAPNAME_LENGHT );

        // Set the settings accordantly to what is being tests on this Unit Test.
        set_pcvar_num( cvar_serverMoveCursor, 1 );

        test_populateListOnSeries_build( s, populatedArray, populatedTrie, .expectedSize=7, .isFull=is ); // Case 1

        test_populateListOnSeries( s, populatedArray, {0}    , "de_dust1", false, is ); // Case  2-3
        test_populateListOnSeries( s, populatedArray, {1,4,6}, "de_dust2", false, is ); // Case  4-5
        test_populateListOnSeries( s, populatedArray, {2}    , "de_dust5", false, is ); // Case  6-7
        test_populateListOnSeries( s, populatedArray, {3}    , "de_dust6", false, is ); // Case  8-9
        test_populateListOnSeries( s, populatedArray, {5}    , "de_nuke" , false, is ); // Case 10-11

        test_populateListOnSeries( s, populatedArray, {-1}   , "de_nuke2", true , is ); // Case 12-13
        test_populateListOnSeries( s, populatedArray, {-1}   , "de_dust" , true , is ); // Case 14-15
        test_populateListOnSeries( s, populatedArray, {-1}   , "de_dust3", true , is ); // Case 16-17
        test_populateListOnSeries( s, populatedArray, {-1}   , "de_dust4", true , is ); // Case 18-19

        TrieDestroy( populatedTrie );
        ArrayDestroy( populatedArray );
    }

    /**
     * Tests if the function map_populateListOnSeries(3) is properly loading the maps series.
     */
    stock test_populateListOnSeries_loadb( s, bool:is=false )
    {
        new Trie:populatedTrie   = TrieCreate();
        new Array:populatedArray = ArrayCreate( MAX_MAPNAME_LENGHT );

        // Set the settings accordantly to what is being tests on this Unit Test.
        set_pcvar_num( cvar_serverMoveCursor, 2 );

        test_populateListOnSeries_build( s, populatedArray, populatedTrie, .expectedSize=11, .isFull=is ); // Case 1

        test_populateListOnSeries( s, populatedArray, {0}     , "de_dust1", false, is ); // Case  2-3
        test_populateListOnSeries( s, populatedArray, {1,4, 8}, "de_dust2", false, is ); // Case  4-5
        test_populateListOnSeries( s, populatedArray, {2,5, 9}, "de_dust5", false, is ); // Case  6-7
        test_populateListOnSeries( s, populatedArray, {3,6,10}, "de_dust6", false, is ); // Case  8-9
        test_populateListOnSeries( s, populatedArray, {7}     , "de_nuke" , false, is ); // Case 10-11

        test_populateListOnSeries( s, populatedArray, {-1}    , "de_nuke2", true , is ); // Case 12-13
        test_populateListOnSeries( s, populatedArray, {-1}    , "de_dust" , true , is ); // Case 14-15
        test_populateListOnSeries( s, populatedArray, {-1}    , "de_dust3", true , is ); // Case 16-17
        test_populateListOnSeries( s, populatedArray, {-1}    , "de_dust4", true , is ); // Case 18-19

        TrieDestroy( populatedTrie );
        ArrayDestroy( populatedArray );
    }

    /**
     * Tests if the function map_populateListOnSeries(3) is properly loading the maps series.
     */
    stock test_populateListOnSeries_loadc( s, bool:is=false )
    {
        new Trie:populatedTrie   = TrieCreate();
        new Array:populatedArray = ArrayCreate( MAX_MAPNAME_LENGHT );

        // Set the settings accordantly to what is being tests on this Unit Test.
        set_pcvar_num( cvar_serverMoveCursor, 6 );

        test_populateListOnSeries_build( s, populatedArray, populatedTrie, .expectedSize=7, .isFull=is ); // Case 1

        test_populateListOnSeries( s, populatedArray, {0}    , "de_dust1", false, is ); // Case  2-3
        test_populateListOnSeries( s, populatedArray, {1,4,6}, "de_dust2", false, is ); // Case  4-5
        test_populateListOnSeries( s, populatedArray, {2}    , "de_dust5", false, is ); // Case  6-7
        test_populateListOnSeries( s, populatedArray, {3}    , "de_dust6", false, is ); // Case  8-9
        test_populateListOnSeries( s, populatedArray, {5}    , "de_nuke" , false, is ); // Case 10-11

        test_populateListOnSeries( s, populatedArray, {-1}   , "de_nuke2", true , is ); // Case 12-13
        test_populateListOnSeries( s, populatedArray, {-1}   , "de_dust" , true , is ); // Case 14-15
        test_populateListOnSeries( s, populatedArray, {-1}   , "de_dust3", true , is ); // Case 16-17
        test_populateListOnSeries( s, populatedArray, {-1}   , "de_dust4", true , is ); // Case 18-19

        TrieDestroy( populatedTrie );
        ArrayDestroy( populatedArray );
    }

    /**
     * Create one case test for the stock map_populateListOnSeries(3) based on its parameters passed
     * by the test_populateListOnSeries_loada(0) loader function.
     */
    stock test_populateListOnSeries( s, Array:populatedArray, expectedIndexes[], mapName[], bool:isNotToBe, isFull  )
    {
        new test_id;
        new arraySize;
        new expectedIndex;

        new bool:isOnTheArray;
        new errorMessage[ MAX_LONG_STRING ];

        test_id = test_registerSeriesNaming( isFull ? "test_configureTheNextMap" : "test_populateListOnSeries", s );
        printDynamicArrayMaps( populatedArray, 1);

        if( isFull ) populatedArray = g_mapcycleFileListArray;
        arraySize = ArraySize( populatedArray );

        for( new index = 0; index < arraySize; index++ )
        {
            GET_MAP_NAME( populatedArray, index, errorMessage )
            LOG( 1, "mapName: %s, errorMessage: %s: equally: %d", mapName, errorMessage, equali( errorMessage, mapName ) != 0 )

            if( equali( errorMessage, mapName ) != 0 )
            {
                LOG( 1, "Inside equali, eyah" )
                isOnTheArray = true;

                ERR( "The map `%10s` must be at the index %d, instead of %d.", mapName, expectedIndexes[ expectedIndex ], index )
                setTestFailure( test_id, index != expectedIndexes[ expectedIndex ], errorMessage );

                ++expectedIndex;
            }
        }

        test_id = test_registerSeriesNaming( isFull ? "test_configureTheNextMap" : "test_populateListOnSeries", s );
        ERR( "The map `%10s` must %sto be loaded on the array.", mapName, isNotToBe ? "not " : "" )
        setTestFailure( test_id, isOnTheArray == isNotToBe, errorMessage );
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

        ERR( "The map name must to be %s, instead of %s.", mapNameExpected, mapName )
        setTestFailure( test_id, !equali( mapName, mapNameExpected ), errorMessage );

        test_id = test_registerSeriesNaming( "test_GET_MAP_NAME", 'd' ); // Case 2
        GET_MAP_INFO( populatedArray, index, mapName )

        ERR( "The map info must to be %s, instead of %s.", mapInfoExpected, mapName )
        setTestFailure( test_id, !equali( mapName, mapInfoExpected ), errorMessage );
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

        HELPER_MAP_FILE_LIST_LOAD( g_test_voteMapFilePath   , "de_dust1 info1", "de_dust2noInfo", "de_dust2 info1 info2" )
        HELPER_MAP_FILE_LIST_LOAD( g_test_minPlayersFilePath, "de_rats"       , "de_train" )
        HELPER_MAP_FILE_LIST_LOAD( g_test_whiteListFilePath , "[0-23]"        , "de_rats", "de_train" )

        // To force the lists to be reloaded.
        loadMapFiles( false );
        loadTheDefaultVotingChoices();

        printVotingMaps( g_votingMapNames, g_votingMapInfos );

        test_GET_MAP_INFO( "de_dust1"       , "info1", true  );   // Case 1/2
        test_GET_MAP_INFO( "de_dust1"       , "info1", true  );   // Case 3/4
        test_GET_MAP_INFO( "de_dust2noInfo" , ""     , true  );   // Case 5/6
        test_GET_MAP_INFO( "de_dust2noInfo2", "Info" , false );   // Case 7/8
        test_GET_MAP_INFO( "de_dust"        , "info" , false );   // Case 9/10
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
     * @see test_GET_MAP_INFO(2)
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

            ERR( "The %s '%s' must %sto be present on the voting map menu.", is ? "name" : "info", textToCheck, toBe ? "" : "not " )
            setTestFailure( test_id, isMapPresent != toBe, errorMessage );
        }
    }

    /**
     * Tests if the function SortCustomSynced2D(3) is properly sorting the maps.
     */
    stock test_SortCustomSynced2D()
    {
        new votingMaps [ MAX_OPTIONS_IN_VOTE ][ MAX_MAPNAME_LENGHT ];
        new votingInfos[ MAX_OPTIONS_IN_VOTE ][ MAX_MAPNAME_LENGHT ];

        copy( votingMaps[ 0 ], charsmax( votingMaps[] ), "de_dust2" );
        copy( votingMaps[ 1 ], charsmax( votingMaps[] ), "de_dust1" );
        copy( votingMaps[ 2 ], charsmax( votingMaps[] ), "de_nuke"  );
        copy( votingMaps[ 3 ], charsmax( votingMaps[] ), "cs_nuke2" );

        copy( votingInfos[ 0 ], charsmax( votingInfos[] ), " []"         );
        copy( votingInfos[ 1 ], charsmax( votingInfos[] ), "() de_dust1" );
        copy( votingInfos[ 2 ], charsmax( votingInfos[] ), "de_nuke"     );
        copy( votingInfos[ 3 ], charsmax( votingInfos[] ), "[ cs_nuke ]" );

        SortCustomSynced2D( votingMaps, votingInfos, 4 );

        test_SortCustomSynced2D_case( 0, "cs_nuke2" , "[ cs_nuke ]", votingMaps, votingInfos ); // Case 1/2
        test_SortCustomSynced2D_case( 1, "de_dust1", "() de_dust1" , votingMaps, votingInfos ); // Case 3/4
        test_SortCustomSynced2D_case( 2, "de_dust2", " []"         , votingMaps, votingInfos ); // Case 5/6
        test_SortCustomSynced2D_case( 3, "de_nuke" , "de_nuke"     , votingMaps, votingInfos ); // Case 7/8
    }

    /**
     * Create one case test for the stock SortCustomSynced2D(1) based on its parameters passed
     * by the test_SortCustomSynced2D(0) loader function.
     */
    stock test_SortCustomSynced2D_case( expectedPosition, expectedMap[], expectedInfo[], votingMaps[][], votingInfos[][] )
    {
        new test_id;
        new errorMessage[ MAX_LONG_STRING ];

        test_id = test_registerSeriesNaming( "test_SortCustomSynced2D", 'd' );

        ERR( "The expectedPosition %d must to be %s, instead of %s.", expectedPosition, expectedMap, votingMaps[ expectedPosition ] )
        setTestFailure( test_id, !equali( expectedMap, votingMaps[ expectedPosition ] ), errorMessage );

        test_id = test_registerSeriesNaming( "test_SortCustomSynced2D", 'd' );

        ERR( "The expectedPosition %d must to be %s, instead of %s.", expectedPosition, expectedInfo, votingInfos[ expectedPosition ] )
        setTestFailure( test_id, !equali( expectedInfo, votingInfos[ expectedPosition ] ), errorMessage );
    }

    /**
     * Tests if the function configureTheNextMapSetttings(1) is properly setting the next map.
     */
    stock test_configureTheNextMap()
    {
        set_pcvar_num( cvar_whitelistMinPlayers, 0 );

        test_populateListOnSeries_loada( 'a', true ); // Case 1-19
        test_populateListOnSeries_loadb( 'b', true ); // Case 1-19
        test_populateListOnSeries_loadc( 'c', true ); // Case 1-19

        test_configureTheNextMap_loadd( 'd' ); // Case 1-32
        test_configureTheNextMap_loade( 'e' ); // Case 1-58
        test_configureTheNextMap_loadf( 'f' ); // Case 1-48
        test_configureTheNextMap_loadg( 'g' ); // Case 1-20
        test_configureTheNextMap_loadh( 'h' ); // Case 1-18
        test_configureTheNextMap_loadi( 'i' ); // Case 1-4
    }

    /**
     * Create one case test for the stock configureTheNextMapSetttings(1) based on its parameters passed
     * by the test_configureTheNextMap(0) loader function.
     *
     * When the last played map `lastMap` is equal to to `cmA`, the `posB` will be decremented by 1 unit because
     * this situation only happens at map restart, and as here we are readding the the `posE` which points
     * to the next map of the current next map, we need to decrement it to keep the next map from cycling
     * through all the map cycle just because the server admin is doing the `restart` command.
     *
     * The `posE` variable points to the next map of the next map of the current map `cmA`.
     *
     * @param cmA     current map name       after  to call saveCurrentMapCycleSetting(3).
     * @param npE     next map name expected after  to call saveCurrentMapCycleSetting(3) [Expected Next Map].
     * @param posE    the map cycle position after  to call saveCurrentMapCycleSetting(3) [Expected Position].
     */
    stock test_configureTheNextMap_case( s, cmA[], npE[], posE, expectedSize )
    {
        new test_id;

        new lastMap     [ MAX_MAPNAME_LENGHT ];
        new errorMessage[ MAX_LONG_STRING    ];

        set_pcvar_string( cvar_amx_nextmap, cmA );

        copy( g_nextMapName, charsmax( g_nextMapName ), cmA );
        copy( g_currentMapName, charsmax( g_currentMapName ), cmA );

        get_localinfo( "galileo_lastmap", lastMap, charsmax( lastMap ) );
        saveCurrentMapCycleSetting( lastMap, g_test_voteMapFilePath, g_nextMapCyclePosition );

        test_loadTheNextMapPluginMaps( expectedSize );

        test_id = test_registerSeriesNaming( "test_configureTheNextMap", s ); // Case 1
        ERR( "The nextMapName must to be %s, instead of %s.", npE, g_nextMapName )
        setTestFailure( test_id, !equali( npE, g_nextMapName ), errorMessage );

        test_id = test_registerSeriesNaming( "test_configureTheNextMap", s ); // Case 2
        ERR( "The map cycle position must to be %d, instead of %d.", posE, g_nextMapCyclePosition )
        setTestFailure( test_id, posE != g_nextMapCyclePosition, errorMessage );
    }

    /**
     * See the functions test_configureTheNextMap_load(1) 1, 2, 3, 4 and 5 to now how the map cycle
     * will be filled by the given options.
     */
    stock test_loadTheNextMapPluginMaps( expectedSize )
    {
        new mapFilePath[ MAX_FILE_PATH_LENGHT ];

        switch( expectedSize )
        {
            case 5:
            {
                set_pcvar_num( cvar_serverMoveCursor, 14 );

                HELPER_MAP_FILE_LIST_LOAD( g_test_voteMapFilePath, "de_dust2", "cs_italy_cz", "de_dust2_fundo", "de_dust_cz" )
                helper_loadStrictValidMapsTrie( "de_dust", "de_dust2", "de_dust3", "de_dust4", "cs_italy_cz", "de_dust2_fundo",
                                                "de_dust2_fundo2", "de_dust_cz", "aim_headshot", "aim_headshot2" );
            }
            case 8:
            {
                set_pcvar_num( cvar_serverMoveCursor, 14 );

                HELPER_MAP_FILE_LIST_LOAD( g_test_voteMapFilePath, "de_dust", "cs_italy_cz", "de_dust2_fundo", "de_dust_cz" )
                helper_loadStrictValidMapsTrie( "de_dust", "de_dust2", "de_dust3", "de_dust4", "cs_italy_cz", "de_dust2_fundo",
                                                "de_dust2_fundo2", "de_dust_cz" );
            }
            case 11:
            {
                set_pcvar_num( cvar_serverMoveCursor, 2 );

                HELPER_MAP_FILE_LIST_LOAD( g_test_voteMapFilePath, "de_dust1", "de_dust2", "de_nuke", "de_dust2" )
                helper_loadStrictValidMapsTrie( "de_dust1", "de_dust2", "de_dust5", "de_dust6", "de_nuke" );
            }
            case 13:
            {
                set_pcvar_num( cvar_serverMoveCursor, 10 );

                HELPER_MAP_FILE_LIST_LOAD( g_test_voteMapFilePath, "de_dust1", "cs_play", "aim_dumb", \
                                           "de_nuke", "de_rage0", "go_girl" )

                helper_loadStrictValidMapsTrie( "de_dust0", "de_dust1", "de_dust2", "de_dust5", "cs_play", "aim_dumb",
                                                "de_nuke", "de_nuke1", "de_nuke2", "de_rage0", "de_rage1", "de_rage2",
                                                "de_rage3", "go_girl" );
            }
        }

        set_pcvar_string( cvar_mapcyclefile, g_test_voteMapFilePath );
        g_test_isToUseStrictValidMaps = true;

        assert configureTheNextMapSetttings( mapFilePath ) == expectedSize;
        g_test_isToUseStrictValidMaps = false;
    }

    /**
     * Test the cvar `gal_srv_move_cursor` set as 2.
     */
    stock test_configureTheNextMap_loadd( s )
    {
        // Setting the `cvar_serverMoveCursor` as 2 will load the map cycle on the as:
        //
        //  0. de_dust1
        //  1. de_dust2
        //  2. de_dust5
        //  3. de_dust6
        //  4. de_dust2
        //  5. de_dust5
        //  6. de_dust6
        //  7. de_nuke
        //  8. de_dust2
        //  9. de_dust5
        // 10. de_dust6
        new expectedSize = 11;

        // Set the initial settings to start the tests.
        saveCurrentMapCycleSetting( "de_dust1", g_test_voteMapFilePath, 1 );

        test_configureTheNextMap_case( s, "de_dust0", "de_dust2", 2 , expectedSize ); // Case  1-2
        test_configureTheNextMap_case( s, "de_dust0", "de_dust2", 2 , expectedSize ); // Case  3-4
        test_configureTheNextMap_case( s, "de_dust1", "de_dust5", 3 , expectedSize ); // Case  5-6
        test_configureTheNextMap_case( s, "de_dust1", "de_dust5", 3 , expectedSize ); // Case  7-8
        test_configureTheNextMap_case( s, "de_dust2", "de_dust6", 4 , expectedSize ); // Case  9-10
        test_configureTheNextMap_case( s, "de_dust2", "de_dust6", 4 , expectedSize ); // Case 11-12
        test_configureTheNextMap_case( s, "de_dust6", "de_dust2", 5 , expectedSize ); // Case 13-14
        test_configureTheNextMap_case( s, "de_dust2", "de_dust5", 6 , expectedSize ); // Case 15-16
        test_configureTheNextMap_case( s, "de_dust5", "de_dust6", 7 , expectedSize ); // Case 17-18
        test_configureTheNextMap_case( s, "de_dust5", "de_dust6", 7 , expectedSize ); // Case 19-20
        test_configureTheNextMap_case( s, "de_dust6", "de_nuke" , 8 , expectedSize ); // Case 21-22
        test_configureTheNextMap_case( s, "de_nuke" , "de_dust2", 9 , expectedSize ); // Case 23-24
        test_configureTheNextMap_case( s, "de_dust2", "de_dust5", 10, expectedSize ); // Case 25-26
        test_configureTheNextMap_case( s, "de_dust5", "de_dust6", 11, expectedSize ); // Case 27-28
        test_configureTheNextMap_case( s, "de_dust6", "de_dust1", 1 , expectedSize ); // Case 29-30
        test_configureTheNextMap_case( s, "de_dust1", "de_dust2", 2 , expectedSize ); // Case 31-32
    }

    /**
     * Test the cvar `gal_srv_move_cursor` set as 10.
     */
    stock test_configureTheNextMap_loade( s )
    {
        // Setting the `expectedSize` as 13 will load the map cycle as:
        //
        // 0.  de_dust1
        // 1.  de_dust2
        // 2.  de_dust5
        // 3.  cs_play
        // 4.  aim_dumb
        // 5.  de_nuke
        // 6.  de_nuke1
        // 7.  de_nuke2
        // 8.  de_rage0
        // 9.  de_rage1
        // 10. de_rage2
        // 11. de_rage3
        // 12. go_girl
        new expectedSize = 13;

        // Set the initial settings to start the first complete loop tests.
        saveCurrentMapCycleSetting( "de_dust1", g_test_voteMapFilePath, 2 );

        // Keep it stuck while doing restart map.
        test_configureTheNextMap_case( s, "de_dust1", "de_dust2", 2 , expectedSize ); // Case  1-2
        test_configureTheNextMap_case( s, "de_dust1", "de_dust2", 2 , expectedSize ); // Case  3-4
        test_configureTheNextMap_case( s, "de_dust1", "de_dust2", 2 , expectedSize ); // Case  5-6

        // Here we do a serie switch. Now the position pointer will be moved to the last
        // last position on the series the next map position must to be froze until some
        // of the switched series to be complete.
        test_configureTheNextMap_case( s, "de_nuke" , "de_nuke1", 3 , expectedSize ); // Case  7-8
        test_configureTheNextMap_case( s, "de_nuke" , "de_nuke1", 3 , expectedSize ); // Case  9-10
        test_configureTheNextMap_case( s, "de_nuke1", "de_nuke2", 3 , expectedSize ); // Case 11-12
        test_configureTheNextMap_case( s, "de_nuke1", "de_nuke2", 3 , expectedSize ); // Case 13-14

        // Now we are about to finish the serie and will return to follow the map cycle.
        test_configureTheNextMap_case( s, "de_nuke2", "cs_play" , 4 , expectedSize ); // Case 15-16
        test_configureTheNextMap_case( s, "de_nuke2", "cs_play" , 4 , expectedSize ); // Case 17-18
        test_configureTheNextMap_case( s, "de_nuke2", "cs_play" , 4 , expectedSize ); // Case 19-20
        test_configureTheNextMap_case( s, "cs_play" , "aim_dumb", 5 , expectedSize ); // Case 21-22
        test_configureTheNextMap_case( s, "aim_dumb", "de_nuke" , 6 , expectedSize ); // Case 23-24
        test_configureTheNextMap_case( s, "de_nuke" , "de_nuke1", 7 , expectedSize ); // Case 25-26
        test_configureTheNextMap_case( s, "de_nuke1", "de_nuke2", 8 , expectedSize ); // Case 27-28
        test_configureTheNextMap_case( s, "de_nuke2", "de_rage0", 9 , expectedSize ); // Case 29-30
        test_configureTheNextMap_case( s, "de_rage0", "de_rage1", 10, expectedSize ); // Case 31-32
        test_configureTheNextMap_case( s, "de_rage1", "de_rage2", 11, expectedSize ); // Case 33-34
        test_configureTheNextMap_case( s, "de_rage2", "de_rage3", 12, expectedSize ); // Case 35-36
        test_configureTheNextMap_case( s, "de_rage3", "go_girl" , 13, expectedSize ); // Case 37-38
        test_configureTheNextMap_case( s, "go_girl" , "de_dust1", 1 , expectedSize ); // Case 39-40

        // We must to also skip the `de_dust` series, otherwise the map cycle will never
        // follow unless the `de_dust` series is followed.
        test_configureTheNextMap_case( s, "de_nuke" , "de_nuke1", 3 , expectedSize ); // Case 41-42
        test_configureTheNextMap_case( s, "de_rage0", "de_rage1", 3 , expectedSize ); // Case 43-44
        test_configureTheNextMap_case( s, "de_rage1", "de_rage2", 3 , expectedSize ); // Case 45-46
        test_configureTheNextMap_case( s, "de_nuke" , "de_nuke1", 3 , expectedSize ); // Case 47-48
        test_configureTheNextMap_case( s, "de_nuke1", "de_nuke2", 3 , expectedSize ); // Case 49-50
        test_configureTheNextMap_case( s, "de_nuke2", "cs_play" , 4 , expectedSize ); // Case 51-52
        test_configureTheNextMap_case( s, "cs_play" , "aim_dumb", 5 , expectedSize ); // Case 53-54
        test_configureTheNextMap_case( s, "aim_dumb", "de_nuke" , 6 , expectedSize ); // Case 55-56
        test_configureTheNextMap_case( s, "de_nuke" , "de_nuke1", 7 , expectedSize ); // Case 57-58
    }

    /**
     * Test the cvar `gal_srv_move_cursor` set as 10, using an alternating series test from the above.
     */
    stock test_configureTheNextMap_loadf( s )
    {
        // Setting the `expectedSize` as 13 will load the map cycle as the load2 above.
        new expectedSize = 13;

        // Set the initial settings to start the first complete loop tests.
        saveCurrentMapCycleSetting( "cs_play", g_test_voteMapFilePath, 5 );

        // If the RTV never stop coming, the map cycle position will be stuck for a long
        // time, but if the series switches come back to the original series it did come
        // from...
        test_configureTheNextMap_case( s, "cs_play" , "aim_dumb", 5 , expectedSize ); // Case  1-2
        test_configureTheNextMap_case( s, "aim_dumb", "de_nuke" , 6 , expectedSize ); // Case  3-4
        test_configureTheNextMap_case( s, "de_nuke" , "de_nuke1", 7 , expectedSize ); // Case  5-6
        test_configureTheNextMap_case( s, "de_dust1", "de_dust2", 8 , expectedSize ); // Case  7-8
        test_configureTheNextMap_case( s, "de_dust2", "de_dust5", 8 , expectedSize ); // Case  9-10
        test_configureTheNextMap_case( s, "de_dust2", "de_dust5", 8 , expectedSize ); // Case 11-12

        // we will to start following the map cycle again because for example here, the
        // index 8 is the map `de_rage0` and it will hit the current map blocker forcing
        // it to move to the new next of the next map.
        test_configureTheNextMap_case( s, "de_rage0", "de_rage1", 10, expectedSize ); // Case 13-14
        test_configureTheNextMap_case( s, "de_rage1", "de_rage2", 11, expectedSize ); // Case 15-16
        test_configureTheNextMap_case( s, "de_dust1", "de_dust2", 12, expectedSize ); // Case 17-18
        test_configureTheNextMap_case( s, "de_dust2", "de_dust5", 12, expectedSize ); // Case 19-20

        // The map cycle position will to start being updated again after some series
        // to get finished.
        test_configureTheNextMap_case( s, "de_dust5", "go_girl" , 13, expectedSize ); // Case 21-22
        test_configureTheNextMap_case( s, "go_girl" , "de_dust1", 1 , expectedSize ); // Case 23-24

        // Here we do the same test as before, but now we allow the serie to finish
        // naturally instead of by RTV.
        saveCurrentMapCycleSetting( "cs_play", g_test_voteMapFilePath, 5 );

        test_configureTheNextMap_case( s, "cs_play" , "aim_dumb", 5 , expectedSize ); // Case 25-26
        test_configureTheNextMap_case( s, "aim_dumb", "de_nuke" , 6 , expectedSize ); // Case 27-28
        test_configureTheNextMap_case( s, "de_nuke" , "de_nuke1", 7 , expectedSize ); // Case 29-30
        test_configureTheNextMap_case( s, "de_dust1", "de_dust2", 8 , expectedSize ); // Case 31-32
        test_configureTheNextMap_case( s, "de_dust2", "de_dust5", 8 , expectedSize ); // Case 33-34
        test_configureTheNextMap_case( s, "de_dust2", "de_dust5", 8 , expectedSize ); // Case 35-36

        test_configureTheNextMap_case( s, "de_dust5", "de_rage0", 9 , expectedSize ); // Case 37-38
        test_configureTheNextMap_case( s, "de_rage0", "de_rage1", 10, expectedSize ); // Case 39-40
        test_configureTheNextMap_case( s, "de_rage1", "de_rage2", 11, expectedSize ); // Case 41-42
        test_configureTheNextMap_case( s, "de_rage2", "de_rage3", 12, expectedSize ); // Case 43-44

        test_configureTheNextMap_case( s, "de_rage3", "go_girl" , 13, expectedSize ); // Case 45-46
        test_configureTheNextMap_case( s, "go_girl" , "de_dust1", 1 , expectedSize ); // Case 47-48
    }

    /**
     * Test the cvar `gal_srv_move_cursor` set as 14.
     *
     * When the option `IS_TO_LOAD_EXPLICIT_MAP_SERIES` is set, the moveTheCursorToTheLastMap cannot
     * move the cursor until the series end, if there are valid maps but the series does not started
     * at 0 or 1.
     */
    stock test_configureTheNextMap_loadg( s )
    {
        // Setting the `expectedSize` as 5 will load the map cycle as:
        //
        // 0. de_dust2
        // 1. cs_italy_cz
        // 2. de_dust2_fundo
        // 3. de_dust2_fundo2
        // 4. de_dust_cz
        new expectedSize = 5;

        // Set the initial settings to start the first complete loop tests.
        saveCurrentMapCycleSetting( "de_dust", g_test_voteMapFilePath, 1 );

        // Here we start the map on an alternate series and the map cycle position must to be frozen.
        test_configureTheNextMap_case( s, "de_dust"        , "de_dust2"       , 1, expectedSize ); // Case  1-2
        test_configureTheNextMap_case( s, "de_dust2"       , "de_dust3"       , 1, expectedSize ); // Case  3-4
        test_configureTheNextMap_case( s, "de_dust3"       , "de_dust4"       , 1, expectedSize ); // Case  5-6

        // Here we finish the alternate series and the map cycle must to free.
        test_configureTheNextMap_case( s, "de_dust4"       , "cs_italy_cz"    , 2, expectedSize ); // Case  7-8
        test_configureTheNextMap_case( s, "cs_italy_cz"    , "de_dust2_fundo" , 3, expectedSize ); // Case  9-10
        test_configureTheNextMap_case( s, "de_dust2_fundo" , "de_dust2_fundo2", 4, expectedSize ); // Case 11-12
        test_configureTheNextMap_case( s, "de_dust2_fundo2", "de_dust_cz"     , 5, expectedSize ); // Case 13-14
        test_configureTheNextMap_case( s, "de_dust_cz"     , "de_dust2"       , 1, expectedSize ); // Case 15-16
        test_configureTheNextMap_case( s, "de_dust2"       , "cs_italy_cz"    , 2, expectedSize ); // Case 17-18
        test_configureTheNextMap_case( s, "cs_italy_cz"    , "de_dust2_fundo" , 3, expectedSize ); // Case 19-20
    }

    /**
     * Test the cvar `gal_srv_move_cursor` set as 14, using an alternating series test from the above.
     */
    stock test_configureTheNextMap_loadh( s )
    {
        // Setting the `expectedSize` as 8 will load the map cycle as:
        //
        // 0. de_dust
        // 1. de_dust2
        // 2. de_dust3
        // 3. de_dust4
        // 4. cs_italy_cz
        // 5. de_dust2_fundo
        // 6. de_dust2_fundo2
        // 7. de_dust_cz
        new expectedSize = 8;

        // Set the initial settings to start the first complete loop tests.
        saveCurrentMapCycleSetting( "de_dust", g_test_voteMapFilePath, 1 );

        // To do a complete loop.
        test_configureTheNextMap_case( s, "de_dust"        , "de_dust2"       , 2, expectedSize ); // Case  1-2
        test_configureTheNextMap_case( s, "de_dust2"       , "de_dust3"       , 3, expectedSize ); // Case  3-4
        test_configureTheNextMap_case( s, "de_dust3"       , "de_dust4"       , 4, expectedSize ); // Case  5-6
        test_configureTheNextMap_case( s, "de_dust2_fundo" , "de_dust2_fundo2", 4, expectedSize ); // Case  7-8
        test_configureTheNextMap_case( s, "de_dust2_fundo2", "cs_italy_cz"    , 5, expectedSize ); // Case  9-10
        test_configureTheNextMap_case( s, "cs_italy_cz"    , "de_dust2_fundo" , 6, expectedSize ); // Case 11-12
        test_configureTheNextMap_case( s, "de_dust2_fundo" , "de_dust2_fundo2", 7, expectedSize ); // Case 13-14
        test_configureTheNextMap_case( s, "de_dust2_fundo2", "de_dust_cz"     , 8, expectedSize ); // Case 15-16
        test_configureTheNextMap_case( s, "de_dust_cz"     , "de_dust"        , 1, expectedSize ); // Case 17-18
    }

    stock test_configureTheNextMap_loadi( s )
    {
        // Setting the `expectedSize` as 5 will load the map cycle as:
        //
        // 0. de_dust2
        // 1. cs_italy_cz
        // 2. de_dust2_fundo
        // 3. de_dust2_fundo2
        // 4. de_dust_cz
        new expectedSize = 5;

        // Set the initial settings to start the first complete loop tests.
        saveCurrentMapCycleSetting( "aim_headshot", g_test_voteMapFilePath, 0 );

        new backupMapsFilePath[ MAX_FILE_PATH_LENGHT ];
        formatex( backupMapsFilePath, charsmax( backupMapsFilePath ), "%s/%s", g_dataDirPath, CURRENT_AND_NEXTMAP_FILE_NAME );

        copy( g_nextMapName, charsmax( g_nextMapName ), "aim_headshot" );
        copy( g_currentMapName, charsmax( g_currentMapName ), "aim_headshot2" );

        delete_file( backupMapsFilePath );
        saveCurrentAndNextMapNames( g_currentMapName, g_nextMapName, true );

        test_configureTheNextMap_case( s, "aim_headshot" , "aim_headshot2", 0, expectedSize ); // Case
        test_configureTheNextMap_case( s, "de_dust2"     , "cs_italy_cz"  , 2, expectedSize ); // Case

    }

    /**
     * Tests if the function handleServerStart(2) is properly setting the start map.
     */
    stock test_handleServerStart()
    {
        // Setting the `expectedSize` as 8 will load the map cycle as:
        //
        // 0. de_dust
        // 1. de_dust2
        // 2. de_dust3
        // 3. de_dust4
        // 4. cs_italy_cz
        // 5. de_dust2_fundo
        // 6. de_dust2_fundo2
        // 7. de_dust_cz
        new startAction  = 1;
        new expectedSize = 8;
        test_loadTheNextMapPluginMaps( expectedSize );

        test_handleServerStart_case( startAction, "de_dust", "de_dust2", 6 ); // Case 1-3
        test_handleServerStart_case( startAction, "de_dust", "de_dust3", 6 ); // Case 4-6

        // Force mark the map as crashing.
        for( new index = -1; index < MAX_SERVER_RESTART_ACCEPTABLE; ++index )
        {
            test_handleServerStart_case( startAction, "some_map1", "de_dust3", 6 ); // Cases 7-13
        }

        // It is expected to the map cycle position to go from 3 to 4.
        test_handleServerStart_case( startAction, "some_map1", "de_dust4", 4, .iA=true, .iP=3 ); // Case 14-15
    }

    /**
     * Create one case test for the stock handleServerStart(1) based on its parameters passed
     * by the test_handleServerStart(0) loader function.
     *
     * @param sA       the start action option to be used on this test.
     * @param cmnE     the current map name        expected after the test to run.
     * @param nmnE     the next map cycle name     expected after the test to run.
     * @param nmpE     the next map cycle position expected after the test to run.
     * @param iA       whether or not is to advance the expected next map.
     * @param iP       the initial position to set the `g_nextMapCyclePosition` after saving the `nmpE`.
     */
    stock test_handleServerStart_case( const sA, const cmnE[], const nmnE[], const nmpE, const iA=false, const iP=2 )
    {
        new test_id;
        new nextMapPositon;

        new errorMessage   [ MAX_LONG_STRING ];
        new nextMapExpected[ MAX_MAPNAME_LENGHT ];

        // Set the initial settings to start the tests.
        nextMapPositon         = nmpE;
        g_nextMapCyclePosition = nmpE;

        copy( nextMapExpected, charsmax( nextMapExpected ), nmnE );
        saveCurrentAndNextMapNames( cmnE, nmnE, true );

        // Clear the initial settings to let the handleServerStart(2) set up them.
        g_nextMapCyclePosition = iP;
        copy( g_currentMapName, charsmax( g_currentMapName ), "some_map1" );
        copy( g_nextMapName   , charsmax( g_nextMapName    ), "some_map2" );

        formatex( errorMessage, charsmax( errorMessage ), "%s/%s", g_dataDirPath, CURRENT_AND_NEXTMAP_FILE_NAME );
        handleServerStart( errorMessage, sA );

        // The current map was ignored due to much restarts.
        if( iA )
        {
            test_id = test_registerSeriesNaming( "test_handleServerStart", 'a' );
            ERR( "The current map name must to be %s, instead of %s.", nmnE, g_currentMapName )
            setTestFailure( test_id, !equali( nmnE, g_currentMapName ), errorMessage );

            // After doing this function call, the compiler is corrupting the variable `cmnE`, so we cannot just
            // do `copy( cmnE, MAX_MAPNAME_LENGHT - 1, nmnE );`. We cannot use `cmnE` after call this.
            // And yes, the variable `cmnE` is neither passed to getNextMapByPosition(5), but it still being corrupted
            // anyways. This is the same problem as in the cmd_voteMap(3) call to approveTheVotingStart(1).
            getNextMapByPosition( g_mapcycleFileListArray, nextMapExpected, nextMapPositon );
        }
        else
        {
            test_id = test_registerSeriesNaming( "test_handleServerStart", 'a' );
            ERR( "The current map name must to be %s, instead of %s.", cmnE, g_currentMapName )
            setTestFailure( test_id, !equali( cmnE, g_currentMapName ), errorMessage );
        }

        test_id = test_registerSeriesNaming( "test_handleServerStart", 'a' );
        ERR( "The next map position must to be %d, instead of %d.", nmpE, g_nextMapCyclePosition )
        setTestFailure( test_id, nmpE != g_nextMapCyclePosition, errorMessage );

        test_id = test_registerSeriesNaming( "test_handleServerStart", 'a' );
        ERR( "The next map name must to be %s, instead of %s.", nmnE, g_nextMapName )
        setTestFailure( test_id, !equali( nmnE, g_nextMapName ), errorMessage );
    }

    stock test_endOfMapVoting()
    {
        test_isMapExtensionAvowed_case1( 'a' ); // Cases 1
        test_isMapExtensionAvowed_case2( 'b' ); // Cases 2/3
        test_endOfMapVotingStart_case3( 'c' );  // Cases 4
        test_endOfMapVotingStart_case4( 'd' );  // Cases 5
        test_endOfMapVotingStop_case5( 'e' );   // Cases 6
        test_endOfMapVoting_case6( 'f' );       // Cases 7
        test_endOfMapVotingStop_case7( 'g' );   // Cases 8
    }

    /**
     * Tests if the cvar 'amx_extendmap_max' functionality is working properly for a successful case.
     */
    stock test_isMapExtensionAvowed_case1( s )
    {
        new test_id;
        new errorMessage[ MAX_LONG_STRING ];

        // Temporarily disables the `gal_nextmap_votemap` feature, as we are not testing it right now.
        set_pcvar_num( cvar_nextMapChangeVotemap, 0 );

        // Set the voting time accordantly to what is expected on the tests.
        set_pcvar_num( cvar_voteDuration  , 30 );
        set_pcvar_num( cvar_runoffDuration, 20 );

        test_id = test_registerSeriesNaming( "test_endOfMapVoting", s );

        set_pcvar_float( cvar_maxMapExtendTime, 20.0 );
        tryToSetGameModCvarFloat( cvar_mp_timelimit, 10.0 );

        g_endVotingType |= IS_BY_TIMER;
        startTheVoting( false );

        ERR( "g_isMapExtensionAllowed must be 1, instead of %d.", g_isMapExtensionAllowed && g_isGameFinalVoting )
        setTestFailure( test_id, !( g_isMapExtensionAllowed && g_isGameFinalVoting ), errorMessage );
    }

    /**
     * Tests if the cvar 'amx_extendmap_max' functionality is working properly for a failure case.
     */
    public test_isMapExtensionAvowed_case2( s )
    {
        new test_id;
        new errorMessage[ MAX_LONG_STRING ];

        // Case 2
        test_id = test_registerSeriesNaming( "test_endOfMapVoting", s );

        ERR( "g_isMapExtensionAllowed must be 1, instead of %d.", g_isMapExtensionAllowed && g_isGameFinalVoting )
        setTestFailure( test_id, !( g_isMapExtensionAllowed && g_isGameFinalVoting ), errorMessage );

        color_chat( 0, "%L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED2" );
        cancelVoting();

        // Case 3
        test_id = test_registerSeriesNaming( "test_endOfMapVoting", s );

        set_pcvar_float( cvar_maxMapExtendTime, 10.0 );
        tryToSetGameModCvarFloat( cvar_mp_timelimit, 20.0 );

        g_endVotingType |= IS_BY_TIMER;
        startTheVoting( false );

        ERR( "g_isMapExtensionAllowed must be 0, instead of was %d.", g_isMapExtensionAllowed && g_isGameFinalVoting )
        setTestFailure( test_id, g_isMapExtensionAllowed && g_isGameFinalVoting, errorMessage );
    }

    /**
     * Tests if the end map voting is starting automatically at the end of map due time limit expiration.
     */
    public test_endOfMapVotingStart_case3( s )
    {
        new test_id;
        new secondsLeft;

        // When the `gal_endofmapvote_start` feature is enabled, will will not allow a votemap
        // by time limit expiration.
        set_pcvar_num( cvar_endOfMapVoteStart, 0 );

        new errorMessage[ MAX_LONG_STRING ];
        test_id = test_registerSeriesNaming( "test_endOfMapVoting", s );

        ERR( "g_isMapExtensionAllowed must be 0, instead of %d.", g_isMapExtensionAllowed && g_isGameFinalVoting )
        setTestFailure( test_id, g_isMapExtensionAllowed && g_isGameFinalVoting, errorMessage );

        cancelVoting();
        secondsLeft = get_timeleft();

        tryToSetGameModCvarFloat( cvar_mp_timelimit,
                ( get_pcvar_float( cvar_mp_timelimit ) * 60
                  - secondsLeft
                  + START_VOTEMAP_MAX_TIME + PERIODIC_CHECKING_INTERVAL - 5 )
                / 60 );

        LOG( 32, "( test_endOfMapVotingStart_case3 ) timelimit: %d", floatround( get_pcvar_float( cvar_mp_timelimit ) * 60 ) )
        LOG( 32, "( test_endOfMapVotingStart_case3 ) START_VOTEMAP_MIN_TIME: %d", START_VOTEMAP_MIN_TIME )
        LOG( 32, "( test_endOfMapVotingStart_case3 ) START_VOTEMAP_MAX_TIME: %d", START_VOTEMAP_MAX_TIME )
    }

    /**
     * Tests if the end map voting is starting automatically at the end of map due time limit expiration.
     */
    public test_endOfMapVotingStart_case4( s )
    {
        new test_id = test_registerSeriesNaming( "test_endOfMapVoting", s );

        vote_manageEnd();
        setTestFailure( test_id, !( g_voteStatus & IS_VOTE_IN_PROGRESS ),
                "The end map voting is not starting automatically at the end of map due time limit expiration." );

        tryToSetGameModCvarFloat( cvar_mp_timelimit, 20.0 );
        cancelVoting();
    }

    /**
     * Tests if the end map voting is not starting automatically at the end of map due time limit expiration.
     */
    public test_endOfMapVotingStop_case5( s )
    {
        new test_id = test_registerSeriesNaming( "test_endOfMapVoting", s );

        vote_manageEnd();
        setTestFailure( test_id, ( g_voteStatus & IS_VOTE_IN_PROGRESS ) != 0,
                "The end map voting is starting automatically at the end of map due time limit expiration." );

        cancelVoting();
    }

    /**
     * Tests if the end map voting is not starting again right after if the extension option wins.
     */
    public test_endOfMapVoting_case6( s )
    {
        new test_id = test_registerSeriesNaming( "test_endOfMapVoting", s );

        // Extend the current map, instead of perform a runoff voting
        set_pcvar_num( cvar_runoffEnabled, 2 );
        vote_manageEnd();

        // Add votes to the Extend Option
        g_arrayOfMapsWithVotesNumber[ 5 ] += 2;// extend option
        g_totalVotesCounted = 2;

        // Get the voting results.
        computeVotes();

        // Try to start a voting again
        vote_manageEnd();
        tryToStartTheVotingOnThisRound( 1 );

        setTestFailure( test_id, ( g_voteStatus & IS_VOTE_IN_PROGRESS ) != 0,
                "The end map voting is starting again right after if the extension option wins." );

        tryToSetGameModCvarFloat( cvar_mp_timelimit, 20.0 );
        cancelVoting();
    }

    /**
     * Tests if the end map voting is not starting automatically at the end of map due time limit expiration.
     */
    public test_endOfMapVotingStop_case7( s )
    {
        new test_id = test_registerSeriesNaming( "test_endOfMapVoting", s );

        vote_manageEnd();
        setTestFailure( test_id, ( g_voteStatus & IS_VOTE_IN_PROGRESS ) != 0,
                "The end map voting is starting automatically at the end of map due time limit expiration." );

        cancelVoting();
    }




    // Here below to start the manual Unit Tests
    // ###########################################################################################

    /**
     * Tests if the function functionNameExample(1) is properly setting the next map.
     */
    stock test_functionNameExample()
    {
        // This is a model test loader
        test_functionNameExample_case( .expected=5 ) // Case 1
    }

    /**
     * Create one case test for the stock functionNameExample(1) based on its parameters passed
     * by the test_functionNameExample(0) loader function.
     */
    stock test_functionNameExample_case( expected )
    {
        new test_id;
        new errorMessage[ MAX_LONG_STRING ];

        test_id = test_registerSeriesNaming( "test_functionNameExample", 'a' );

        // This is a model test case
        test_result = someTesting();

        ERR( "The expected result must to be %d, instead of %d.", expected, test_result )
        setTestFailure( test_id, expected != test_result, errorMessage );
    }

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
     * @see test_announceVoteBlockedMap_a(0)
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

        color_chat( 0, team, string );
        color_chat( player_id, team, string );

        new formats[ MAX_BIG_BOSS_STRING ];
        copy( formats, charsmax( formats ), "My big formatter: %s" );

        color_chat( 0, team, formats, string );
        color_chat( player_id, team, formats, string );
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
    new test_serverPlayersCount;
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
    new test_voteDuration;
    new test_runoffDuration;

    new test_galileo_lastmap [ MAX_MAPNAME_LENGHT ];
    new test_amx_nextmap     [ MAX_MAPNAME_LENGHT ];
    new test_g_nextMapName   [ MAX_MAPNAME_LENGHT ];
    new test_g_currentMapName[ MAX_MAPNAME_LENGHT ];

    new test_lastmapcycle             [ MAX_MAPNAME_LENGHT ];
    new test_mapcyclefile             [ MAX_FILE_PATH_LENGHT ];
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
        LOG( 128, "I AM ENTERING ON saveServerCvarsForTesting(0)" )
        LOG( 2, "    %38s cvar_mp_timelimit: %f  test_mp_timelimit: %f   g_originalTimelimit: %f", \
                "saveServerCvarsForTesting( in )", get_pcvar_float( cvar_mp_timelimit ), test_mp_timelimit, g_originalTimelimit )

        if( !g_test_areTheUnitTestsRunning )
        {
            new backupMapsFilePathOld[ MAX_FILE_PATH_LENGHT ];
            new backupMapsFilePathNew[ MAX_FILE_PATH_LENGHT ];

            formatex( backupMapsFilePathOld, charsmax( backupMapsFilePathOld ),
                    "%s/%s", g_dataDirPath, CURRENT_AND_NEXTMAP_FILE_NAME );

            formatex( backupMapsFilePathNew, charsmax( backupMapsFilePathNew ),
                    "%s/%s%s", g_dataDirPath, "old", CURRENT_AND_NEXTMAP_FILE_NAME );

            rename_file( backupMapsFilePathOld, backupMapsFilePathNew, 1 );

            g_test_isToEnableLogging      = !( DEBUG_LEVEL & DEBUG_LEVEL_DISABLE_TEST_LOGS );
            g_test_areTheUnitTestsRunning = true;

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

            copy( test_g_nextMapName   , charsmax( test_g_nextMapName )   , g_nextMapName    );
            copy( test_g_currentMapName, charsmax( test_g_currentMapName ), g_currentMapName );

            get_localinfo( "lastmapcycle"   , test_lastmapcycle   , charsmax( test_lastmapcycle )    );
            get_localinfo( "galileo_lastmap", test_galileo_lastmap, charsmax( test_galileo_lastmap ) );

            get_pcvar_string( cvar_amx_nextmap              , test_amx_nextmap              , charsmax( test_amx_nextmap )               );
            get_pcvar_string( cvar_mapcyclefile             , test_mapcyclefile             , charsmax( test_mapcyclefile )              );
            get_pcvar_string( cvar_nomMapFilePath           , test_nomMapFilePath           , charsmax( test_nomMapFilePath )            );
            get_pcvar_string( cvar_voteMapFilePath          , test_voteMapFilePath          , charsmax( test_voteMapFilePath )           );
            get_pcvar_string( cvar_voteWhiteListMapFilePath , test_voteWhiteListMapFilePath , charsmax( test_voteWhiteListMapFilePath )  );
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

            test_serverPlayersCount      = get_pcvar_num( cvar_serverPlayersCount     );
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
            test_voteDuration            = get_pcvar_num( cvar_voteDuration           );
            test_runoffDuration          = get_pcvar_num( cvar_runoffDuration         );
        }
    }

    /**
     * This is executed after all tests executions, to restore the server variables changes.
     */
    stock restoreServerCvarsFromTesting()
    {
        LOG( 128, "I AM ENTERING ON restoreServerCvarsFromTesting(0)" )
        LOG( 2, "    %38s cvar_mp_timelimit: %f  test_mp_timelimit: %f  g_originalTimelimit: %f", \
                "restoreServerCvarsFromTesting( in )", get_pcvar_float( cvar_mp_timelimit ), test_mp_timelimit, g_originalTimelimit )

        if( g_test_areTheUnitTestsRunning )
        {
            new backupMapsFilePathOld[ MAX_FILE_PATH_LENGHT ];
            new backupMapsFilePathNew[ MAX_FILE_PATH_LENGHT ];

            map_restoreEndGameCvars();

            g_originalTimelimit = 0.0;
            g_originalMaxRounds = 0;
            g_originalWinLimit  = 0;
            g_originalFragLimit = 0;

            g_test_areTheUnitTestsRunning = false;
            tryToSetGameModCvarFloat( cvar_mp_timelimit, test_mp_timelimit );

            tryToSetGameModCvarNum( cvar_mp_winlimit , test_mp_winlimit  );
            tryToSetGameModCvarNum( cvar_mp_maxrounds, test_mp_maxrounds );
            tryToSetGameModCvarNum( cvar_mp_fraglimit, test_mp_fraglimit );

            formatex( backupMapsFilePathOld, charsmax( backupMapsFilePathOld ), "%s/%s%s",
                    g_dataDirPath, "old", CURRENT_AND_NEXTMAP_FILE_NAME );

            formatex( backupMapsFilePathNew, charsmax( backupMapsFilePathNew ), "%s/%s",
                    g_dataDirPath, CURRENT_AND_NEXTMAP_FILE_NAME );

            delete_file( backupMapsFilePathNew );
            rename_file( backupMapsFilePathOld, backupMapsFilePathNew, 1 );

            set_pcvar_float( cvar_rtvRatio        , test_rtvRatio );
            set_pcvar_float( cvar_maxMapExtendTime, test_extendMapMaximum );

            set_localinfo( "lastmapcycle"   , test_lastmapcycle );
            set_localinfo( "galileo_lastmap", test_galileo_lastmap );

            copy( g_nextMapName   , charsmax( g_nextMapName )   , test_g_nextMapName    );
            copy( g_currentMapName, charsmax( g_currentMapName ), test_g_currentMapName );

            set_pcvar_num( cvar_serverTimeLimitRestart , test_serverTimeLimitRestart  );
            set_pcvar_num( cvar_serverWinlimitRestart  , test_serverWinlimitRestart   );
            set_pcvar_num( cvar_serverMaxroundsRestart , test_serverMaxroundsRestart  );
            set_pcvar_num( cvar_serverFraglimitRestart , test_serverFraglimitRestart  );

            set_pcvar_num( cvar_serverPlayersCount     , test_serverPlayersCount      );
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
            set_pcvar_num( cvar_voteDuration           , test_voteDuration            );
            set_pcvar_num( cvar_runoffDuration         , test_runoffDuration          );

            set_pcvar_string( cvar_amx_nextmap              , test_amx_nextmap               );
            set_pcvar_string( cvar_mapcyclefile             , test_mapcyclefile              );
            set_pcvar_string( cvar_nomMapFilePath           , test_nomMapFilePath            );
            set_pcvar_string( cvar_voteMapFilePath          , test_voteMapFilePath           );
            set_pcvar_string( cvar_voteWhiteListMapFilePath , test_voteWhiteListMapFilePath  );
            set_pcvar_string( cvar_voteMinPlayersMapFilePath, test_voteMinPlayersMapFilePath );
        }

        // Clear tests results.
        resetRoundsScores();
        cancelVoting();

        // We need to manually reset because cancelVoting(0) cannot completely zero it
        g_voteStatus            = 0;
        g_totalRoundsSavedTimes = 0;

        // Reload unloaded features.
        loadMapFiles( false );

        // Clean tests files.
        delete_file( g_test_voteMapFilePath );
        delete_file( g_test_whiteListFilePath );
        delete_file( g_test_minPlayersFilePath );

        LOG( 2, "    %38s cvar_mp_timelimit: %f  test_mp_timelimit: %f  g_originalTimelimit: %f", \
                "restoreServerCvarsFromTesting( out )", get_pcvar_float( cvar_mp_timelimit ), \
                test_mp_timelimit, g_originalTimelimit )

        // Only to enable the logging, after all the print being outputted due the `DEBUG_LEVEL_DISABLE_TEST_LOGS` level.
        g_test_isToEnableLogging = true;
    }
#endif


