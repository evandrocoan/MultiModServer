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
new const PLUGIN_VERSION[] = "v3.2.6-331";

/**
 * Change this value from 0 to 1, to use the Whitelist feature as a Blacklist feature.
 */
#define IS_TO_USE_BLACKLIST_INSTEAD_OF_WHITELIST 0

/**
 * Enables the support the Sven Coop 'mp_nextmap_cycle' cvar and vote map start by the Ham_Use
 * "game_end". It will require the '<hamsandwich>' module.
 */
#define IS_TO_ENABLE_SVEN_COOP_SUPPPORT 1

/**
 * Change this value from 0 to 1, to disable the colored text message (chat messages).
 */
#define IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES 1



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
 * 0   - Disables this feature.
 *
 * 1   - Normal/basic debugging/depuration.
 *
 * 2   - a) Run the NORMAL Unit Tests on the server start.
 *       b) To skip the 'pendingVoteCountdown()'.
 *       c) Set the vote runoff time to 5 seconds.
 *
 * 4   - Run the DELAYED Unit Tests.
 *
 * 8   - a) To create fake votes. See the function 'create_fakeVotes()'.
 *       b) To create fake players count. See the function 'get_realplayersnum()'.
 *
 * 16   - Enable DEBUG_LEVEL 1 and all its debugging/depuration available.
 *
 * 32  - Run the manual test on server start.
 *
 * 63  - Enable the levels 1, 2, 4, 8, 16 and 32.
 *
 * Default value: 0
 */
#define DEBUG_LEVEL 16+4+8+2


/**
 * How much players use when the debugging level 'DEBUG_LEVEL_FAKE_VOTES' is enabled.
 */
#define FAKE_PLAYERS_NUMBER_FOR_DEBUGGING 1

/**
 * Debugging level configurations.
 */
#define DEBUG_LEVEL_NORMAL            1
#define DEBUG_LEVEL_UNIT_TEST_NORMAL  2
#define DEBUG_LEVEL_UNIT_TEST_DELAYED 4
#define DEBUG_LEVEL_FAKE_VOTES        8
#define DEBUG_LEVEL_CRITICAL_MODE     16
#define DEBUG_LEVEL_MANUAL_TEST_START 32

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
    new const DEBUGGER_OUTPUT_LOG_FILE_NAME[] = "_galileo.log";

    /**
     * Write messages to the debug log file on 'addons/amxmodx/logs'.
     *
     * @param log_file               the log file name.
     * @param formated_message       the formatted message to write down to the debug log file.
     */
    stock writeToTheDebugFile( const log_file[], const formated_message[] )
    {
        static lastRun;
        new    currentTime;

        currentTime = tickcount();

        log_to_file( log_file, "{%.3f %d %5d %4d} %s", get_gametime(), heapspace(), currentTime, currentTime - lastRun, formated_message );
        lastRun = currentTime;
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
     * 32   - Rounds end map voting.
     * 64   - Debug for the color_print(...) function.
     * 128  - Functions entrances messages.
     * 255  - Enables all debug logging levels.
     */
    new g_debug_level = 1 + 4 + 8 + 16;

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
            static formated_message[ MAX_BIG_BOSS_STRING ];
            vformat( formated_message, charsmax( formated_message ), message, 3 );

            writeToTheDebugFile( DEBUGGER_OUTPUT_LOG_FILE_NAME, formated_message );
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
#if DEBUG_LEVEL >= DEBUG_LEVEL_NORMAL
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
        test_getUniqueRandom_load();
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
     * Used to know when the Unit Tests are running.
     */
    new bool:g_test_isTheUnitTestsRunning;

    /**
     * Run the manual call Unit Tests, by 'say run' and 'say_team run'.
     */
    public inGameTestsToExecute( player_id )
    {
        LOGGER( 128, "I AM ENTERING ON inGameTestsToExecute(1) player_id: %d", player_id )

        // Save the game cvars
        g_test_isTheUnitTestsRunning ? player_id : saveServerCvarsForTesting();

        for( new i = 0; i < 1000; i++ )
        {
            for( new i = 0; i < 1000; i++ )
            {
            }

            // LOGGER( 1, "Current i is: %d", i )
        }

        test_getUniqueRandom_load();
        // test_nominateAndUnnominate_load();
        // test_loadVoteChoices_cases();
        //test_colorChatLimits( player_id );
        //test_unnominatedDisconnected( player_id );
        //test_announceVoteBlockedMap_a();
        //test_announceVoteBlockedMap_c();

        // Restore the game cvars
        g_test_isTheUnitTestsRunning ? player_id : printTheUnitTestsResults();
    }

    /**
     * Accept all maps as valid while running the unit tests.
     */
    #define IS_MAP_VALID(%1) ( g_test_isTheUnitTestsRunning || IS_MAP_VALID_BSP( %1 ) )

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
            LOGGER( 1, "    ( SET_TEST_FAILURE ) Just returning/bloking." ) \
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

    new Trie: g_test_failureIdsTrie;
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
#endif

/**
 * Register the color chat necessary variables, if it is enabled.
 */
#if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES > 0
    new bool:g_isColorChatSupported;
    new bool:g_isColoredChatEnabled;

    #define IS_COLORED_CHAT_ENABLED() ( g_isColorChatSupported && g_isColoredChatEnabled )

    #if AMXX_VERSION_NUM < 183
        new g_user_msgid;
    #endif

    new cvar_coloredChatEnabled;
#endif

/**
 * General Constants.
 */
#define LISTMAPS_USERID   0
#define LISTMAPS_LAST_MAP 1

#define RTV_CMD_STANDARD  1
#define RTV_CMD_SHORTHAND 2
#define RTV_CMD_DYNAMIC   4

#define MAPFILETYPE_SINGLE 1
#define MAPFILETYPE_GROUPS 2

#define VOTE_IS_IN_PROGRESS 1
#define VOTE_IS_FORCED      2
#define VOTE_IS_RUNOFF      4
#define VOTE_IS_OVER        8
#define VOTE_IS_EARLY       16
#define VOTE_IS_EXPIRED     32

#define SOUND_GETREADYTOCHOOSE 1
#define SOUND_COUNTDOWN        2
#define SOUND_TIMETOCHOOSE     4
#define SOUND_RUNOFFREQUIRED   8

#define SHOW_STATUS_NEVER      0
#define SHOW_STATUS_AFTER_VOTE 1
#define SHOW_STATUS_AT_END     2
#define SHOW_STATUS_ALWAYS     3

#define STATUS_TYPE_COUNT      1
#define STATUS_TYPE_PERCENTAGE 2

#define ANNOUNCE_CHOICE_PLAYERS 1
#define ANNOUNCE_CHOICE_ADMINS  2

#define NONE_OPTION_HIDE_AFTER_USER_VOTE        0
#define NONE_OPTION_ALWAYS_KEEP_SHOWING         1
#define CONVERT_NONE_OPTION_TO_CANCEL_LAST_VOTE 2

#define MAX_PREFIX_COUNT              32
#define MAX_OPTIONS_IN_VOTE           9
#define MAX_MENU_ITEMS_PER_PAGE       8
#define MAX_NOM_MENU_ITEMS_PER_PAGE   7
#define MAX_STANDARD_MAP_COUNT        25
#define MAX_SERVER_RESTART_ACCEPTABLE 10
#define MAX_NOM_MATCH_COUNT           1000
#define MAX_PLAYERS_COUNT             MAX_PLAYERS + 1

#define SERVER_START_CURRENTMAP                     1
#define SERVER_START_NEXTMAP                        2
#define SERVER_START_MAPVOTE                        3
#define SERVER_START_RANDOMMAP                      4
#define SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR      2
#define DELAY_TO_WAIT_THE_SERVER_CVARS_TO_BE_LOADED 50.0

/**
 * The rounds number before the mp_maxrounds/mp_winlimit to be reached to start the map voting.
 */
#define VOTE_START_ROUNDS 4

/**
 * The periodic task created on 'configureServerMapChange(0)' use this intervals in seconds to
 * start checking for an end map voting start.
 */
#define START_VOTEMAP_MIN_TIME ( 41 + g_totalVoteTime )
#define START_VOTEMAP_MAX_TIME ( 9 + g_totalVoteTime )



// In-place Macros
// ###############################################################################################

/**
 * The frags/kills number before the mp_fraglimit to be reached and to start the map voting.
 */
#define VOTE_START_FRAGS() \
    ( g_fragLimitNumber > 50 ? 30 : 15 )
//

/**
 * Specifies how much time to delay the voting start after the round start.
 */
#define ROUND_VOTING_START_SECONDS_DELAY() \
    ( get_pcvar_num( cvar_mp_freezetime ) + 15 )
//

/**
 * Determine whether the server is on an acceptable time to start a map voting on the middle of the
 * round and to start the end map voting near the map time limit expiration.
 *
 * @param secondsRemaining     how many seconds are remaining to the map end.
 */
#define IS_TIME_TO_START_THE_END_OF_MAP_VOTING(%1) \
    ( get_pcvar_num( cvar_endOfMapVote ) \
      && %1 < START_VOTEMAP_MIN_TIME \
      && %1 > START_VOTEMAP_MAX_TIME \
      && !get_pcvar_num( cvar_endOfMapVoteStart ) \
      && !IS_END_OF_MAP_VOTING_GOING_ON() )
//

/**
 * Start a map voting delayed after the mp_maxrounds or mp_winlimit minimum to be reached.
 */
#define START_VOTING_BY_MIDDLE_ROUND_DELAY() \
    set_task( float( ROUND_VOTING_START_SECONDS_DELAY() ), "start_voting_by_rounds", TASKID_START_VOTING_BY_ROUNDS );
//

/**
 * Verifies if a voting is or was already processed.
 */
#define IS_END_OF_MAP_VOTING_GOING_ON() \
    ( g_voteStatus & VOTE_IS_IN_PROGRESS \
      || g_voteStatus & VOTE_IS_OVER )
//

/**
 * Boolean check for the Whitelist feature. The Whitelist feature specifies the time where the maps
 * are allowed to be added to the voting list as fillers after the nominations being loaded.
 */
#define IS_WHITELIST_ENABLED() \
    ( get_pcvar_num( cvar_whitelistMinPlayers ) == 1 \
      || get_realplayersnum() < get_pcvar_num( cvar_whitelistMinPlayers ) )
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
    ( get_realplayersnum() < get_pcvar_num( cvar_voteMinPlayers ) \
      && get_pcvar_num( cvar_nomMinPlayersControl ) )
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
    replace_all( %1, charsmax( %1 ), "!g", "^4" ); \
    replace_all( %1, charsmax( %1 ), "!t", "^3" ); \
    replace_all( %1, charsmax( %1 ), "!n", "^1" ); \
    replace_all( %1, charsmax( %1 ), "!y", "^1" ); \
}

/**
 * Remove the colored strings codes '^4 for green', '^1 for yellow', '^3 for team' and
 * '^2 for unknown'.
 *
 * @param string[]       a string pointer to be formatted.
 */
#define REMOVE_CODE_COLOR_TAGS(%1) \
{ \
    replace_all( %1, charsmax( %1 ), "^4", "" ); \
    replace_all( %1, charsmax( %1 ), "^3", "" ); \
    replace_all( %1, charsmax( %1 ), "^2", "" ); \
    replace_all( %1, charsmax( %1 ), "^1", "" ); \
}

/**
 * Remove the colored strings codes '!g for green', '!y for yellow', '!t for team' and
 * '!n for unknown'.
 *
 * @param string[]       a string pointer to be formatted.
 */
#define REMOVE_LETTER_COLOR_TAGS(%1) \
{ \
    replace_all( %1, charsmax( %1 ), "!g", "" ); \
    replace_all( %1, charsmax( %1 ), "!t", "" ); \
    replace_all( %1, charsmax( %1 ), "!n", "" ); \
    replace_all( %1, charsmax( %1 ), "!y", "" ); \
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
 * Check whether a line not a commentary, empty and if it is a valid map by IS_MAP_VALID(1).
 *
 * @param currentLine a string within the line to check.
 */
#define IS_IT_A_VALID_MAP_LINE(%1) \
    ( %1[ 0 ] \
      && !equal( %1, "//", 2 ) \
      && !equal( %1, ";", 1 ) \
      && IS_MAP_VALID( %1 ) )

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
    LOGGER( 128, "I AM ENTERING ON TRY_TO_APPLY(2) | objectIndentifation: %d", %2 ) \
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
    LOGGER( 128, "I AM ENTERING ON DESTROY_PLAYER_NEW_MENU_TYPE(1) | menu_id: %d", %1 ) \
    if( %1 ) \
    { \
        menu_destroy( %1 ); \
        %1 = 0; \
    } \
}

/**
 * Same as TRY_TO_APPLY(2), but the second argument must to be a two Dimensional Dynamic Array.
 */
stock destroy_two_dimensional_array( Array:outerArray )
{
    LOGGER( 128, "I AM ENTERING ON destroy_two_dimensional_array(1) | arrayIndentifation: %d", outerArray )

    if( outerArray )
    {
        new innerArray;
        new size = ArraySize( outerArray );

        for( new index = 0; index < size; index++ )
        {
            innerArray = ArrayGetCell( outerArray, index );
            TRY_TO_APPLY( ArrayDestroy, Array:innerArray )
        }

        TRY_TO_APPLY( ArrayDestroy, outerArray )
    }
}


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
    TASKID_DELETE_USERS_MENUS,
    TASKID_PREVENT_INFITY_GAME,
    TASKID_EMPTYSERVER,
    TASKID_START_VOTING_BY_ROUNDS,
    TASKID_START_VOTING_BY_TIMER,
    TASKID_PROCESS_LAST_ROUND,
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
new cvar_unnominateDisconnected;
new cvar_endOnRound;
new cvar_endOfMapVote;
new cvar_endOfMapVoteStart;
new cvar_endOnRoundRtv;
new cvar_endOnRound_msg;
new cvar_voteWeight;
new cvar_voteWeightFlags;
new cvar_maxMapExtendTime;
new cvar_extendmapStepMinutes;
new cvar_extendmapStepRounds;
new cvar_extendmapStepFrags;
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
new cvar_serverFraglimitRestart;
new cvar_runoffEnabled;
new cvar_runoffDuration;
new cvar_runoffRatio;
new cvar_runoffMapchoices;
new cvar_showVoteStatus;
new cvar_showVoteStatusType;
new cvar_isToReplaceByVoteMenu;
new cvar_soundsMute;
new cvar_voteMapFilePath;
new cvar_voteMinPlayers;
new cvar_nomMinPlayersControl;
new cvar_voteMinPlayersMapFilePath;
new cvar_whitelistMinPlayers;
new cvar_isWhiteListNomBlock;
new cvar_isWhiteListBlockOut;
new cvar_voteWhiteListMapFilePath;


/**
 * Various Artists.
 */
new const LAST_EMPTY_CYCLE_FILE_NAME[]      = "lastEmptyCycleMapName.dat";
new const CURRENT_AND_NEXTMAP_FILE_NAME[]   = "currentAndNextmapNames.dat";
new const LAST_CHANGE_MAP_FILE_NAME[]       = "lastChangedMapName.dat";
new const RECENT_BAN_MAPS_FILE_NAME[]       = "recentMaps.dat";
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
new bool:g_isEmptyCycleMapConfigured;
new bool:g_isMaxroundsExtend;
new bool:g_isVotingByRounds;
new bool:g_isVotingByFrags;
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

new Float:g_rtvWaitMinutes;
new Float:g_originalTimelimit;
new Float:g_original_sv_maxspeed;


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
new Array:g_recentListMapsArray;
new Trie: g_recentMapsTrie;

/**
 * Contains the loaded current loaded Whilelist from the array `g_whitelistFileArray` for the
 * Whilelist Out Block Feature `cvar_isWhiteListBlockOut`.
 */
new Array:g_whitelistArray;

/**
 * Contains all the loaded valid lines from the Whitelist file contents.
 */
new Array:g_whitelistFileArray;

/**
 * Contains all the allowed maps to be added as nominations or as voting map fillers.
 */
new Trie: g_whitelistTrie;

/**
 * Contains all the blocked maps to be added as nominations or as voting map fillers.
 */
new Trie: g_blackListForWhiteListTrie;

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
new Array:g_voteNorPlayerFillerPathsArray;

/**
 * Contains how much maps per map group file to load.
 */
new Array:g_minMaxMapsPerGroupToUseArray;
new Array:g_norMaxMapsPerGroupToUseArray;

/**
 * Contains a Dynamic Array of Dynamic Arrays. Each one of the sub-arrays contains the maps loaded
 * from the Array `g_voteMinPlayerFillerPathsArray` for each of the its paths receptively.
 */
new Array:g_minPlayerFillerMapGroupArrays;
new Array:g_norPlayerFillerMapGroupArrays;

/**
 * Create a new type to perform the switch between the Minimum Players feature and the Normal
 * Voting map filling.
 */
enum fillersFilePathType
{
    fillersFilePaths_MininumPlayers,
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
new g_lastRroundCountdown;
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
new g_voteDuration;
new g_totalVotesCounted;

new COLOR_RED   [ 3 ]; // \r
new COLOR_WHITE [ 3 ]; // \w
new COLOR_YELLOW[ 3 ]; // \y
new COLOR_GREY  [ 3 ]; // \d

new g_mapPrefixCount = 1;

new g_voteStatus_symbol   [ 3 ];
new g_voteWeightFlags     [ 32 ];
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


new g_nextMapName               [ MAX_MAPNAME_LENGHT  ];
new g_currentMapName            [ MAX_MAPNAME_LENGHT  ];
new g_playerVotedOption         [ MAX_PLAYERS_COUNT   ];
new g_playerVotedWeight         [ MAX_PLAYERS_COUNT   ];
new g_generalUsePlayersMenuIds  [ MAX_PLAYERS_COUNT   ];
new g_recentMapsMenuPages       [ MAX_PLAYERS_COUNT   ];
new g_nominationPlayersMenuPages[ MAX_PLAYERS_COUNT   ];
new g_playersKills              [ MAX_PLAYERS_COUNT   ];
new g_arrayOfMapsWithVotesNumber[ MAX_OPTIONS_IN_VOTE ];

new bool:g_isPlayerVoted            [ MAX_PLAYERS_COUNT ] = { true, ... };
new bool:g_isPlayerParticipating    [ MAX_PLAYERS_COUNT ] = { true, ... };
new bool:g_isPlayerSeeingTheVoteMenu[ MAX_PLAYERS_COUNT ];
new bool:g_isPlayerCancelledVote    [ MAX_PLAYERS_COUNT ];
new bool:g_answeredForEndOfMapVote  [ MAX_PLAYERS_COUNT ];
new bool:g_rockedVote               [ MAX_PLAYERS_COUNT ];

new g_mapPrefixes                [ MAX_PREFIX_COUNT    ][ 16                      ];
new g_votingMapNames             [ MAX_OPTIONS_IN_VOTE ][ MAX_MAPNAME_LENGHT      ];
new g_menuMapIndexForPlayerArrays[ MAX_PLAYERS_COUNT   ][ MAX_NOM_MENU_ITEMS_PER_PAGE ];

new g_chooseMapMenuId;
new g_chooseMapQuestionMenuId;


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
    LOGGER( 1, "^n^n^n^n^n^n^n^n^n^n^n%s PLUGIN VERSION %s INITIATING...", PLUGIN_NAME, PLUGIN_VERSION )

    cvar_extendmapStepMinutes    = register_cvar ( "amx_extendmap_step"           , "15" );
    cvar_maxMapExtendTime        = register_cvar ( "amx_extendmap_max"            , "90" );
    cvar_extendmapStepRounds     = register_cvar ( "amx_extendmap_step_rounds"    , "30" );
    cvar_extendmapStepFrags      = register_cvar ( "amx_extendmap_step_frags"     , "60" );
    cvar_fragLimitSupport        = register_cvar ( "gal_mp_fraglimit_support"     , "0"  );
    cvar_extendmapAllowStay      = register_cvar ( "amx_extendmap_allow_stay"     , "0"  );
    cvar_extendmapAllowStayType  = register_cvar ( "amx_extendmap_allow_stay_type", "0"  );
    cvar_isExtendmapOrderAllowed = register_cvar ( "amx_extendmap_allow_order"    , "0"  );

    // print the current used debug information
#if DEBUG_LEVEL & ( DEBUG_LEVEL_NORMAL | DEBUG_LEVEL_CRITICAL_MODE )
    new debug_level[ MAX_SHORT_STRING ];
    formatex( debug_level, charsmax( debug_level ), "%d | %d", g_debug_level, DEBUG_LEVEL );

    LOGGER( 1, "gal_debug_level: %s", debug_level )
    register_cvar( "gal_debug_level", debug_level, FCVAR_SERVER | FCVAR_SPONLY );
#endif

    register_cvar( "gal_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY );

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
    cvar_endOnRound                = register_cvar( "gal_endonround"              , "1"    );
    cvar_endOnRoundRtv             = register_cvar( "gal_endonround_rtv"          , "0"    );
    cvar_endOnRound_msg            = register_cvar( "gal_endonround_msg"          , "0"    );
    cvar_isEndMapCountdown         = register_cvar( "gal_endonround_countdown"    , "0"    );
    cvar_showVoteStatus            = register_cvar( "gal_vote_showstatus"         , "1"    );
    cvar_showVoteStatusType        = register_cvar( "gal_vote_showstatustype"     , "3"    );
    cvar_isToReplaceByVoteMenu     = register_cvar( "gal_vote_replace_menu"       , "0"    );
    cvar_isToShowNoneOption        = register_cvar( "gal_vote_show_none"          , "0"    );
    cvar_voteShowNoneOptionType    = register_cvar( "gal_vote_show_none_type"     , "0"    );
    cvar_isToShowExpCountdown      = register_cvar( "gal_vote_expirationcountdown", "1"    );
    cvar_isToShowVoteCounter       = register_cvar( "gal_vote_show_counter"       , "0"    );
    cvar_isToAskForEndOfTheMapVote = register_cvar( "gal_endofmapvote_ask"        , "0"    );
    cvar_serverStartAction         = register_cvar( "gal_srv_start"               , "0"    );
    cvar_gameCrashRecreationAction = register_cvar( "gal_game_crash_recreation"   , "0"    );
    cvar_serverTimeLimitRestart    = register_cvar( "gal_srv_timelimit_restart"   , "0"    );
    cvar_serverMaxroundsRestart    = register_cvar( "gal_srv_maxrounds_restart"   , "0"    );
    cvar_serverWinlimitRestart     = register_cvar( "gal_srv_winlimit_restart"    , "0"    );
    cvar_serverFraglimitRestart    = register_cvar( "gal_srv_fraglimit_restart"   , "0"    );
    cvar_endOfMapVote              = register_cvar( "gal_endofmapvote"            , "1"    );
    cvar_endOfMapVoteStart         = register_cvar( "gal_endofmapvote_start"      , "0"    );
    cvar_nextMapChangeAnnounce     = register_cvar( "gal_nextmap_change"          , "1"    );
    cvar_nextMapChangeVotemap      = register_cvar( "gal_nextmap_votemap"         , "0"    );
    cvar_voteMapChoiceCount        = register_cvar( "gal_vote_mapchoices"         , "6"    );
    cvar_voteDuration              = register_cvar( "gal_vote_duration"           , "15"   );
    cvar_voteMapFilePath           = register_cvar( "gal_vote_mapfile"            , "*"    );
    cvar_voteMinPlayers            = register_cvar( "gal_vote_minplayers"         , "0"    );
    cvar_nomMinPlayersControl      = register_cvar( "gal_nom_minplayers_control"  , "0"    );
    cvar_voteMinPlayersMapFilePath = register_cvar( "gal_vote_minplayers_mapfile" , ""     );
    cvar_whitelistMinPlayers       = register_cvar( "gal_whitelist_minplayers"    , "0"    );
    cvar_isWhiteListNomBlock       = register_cvar( "gal_whitelist_nom_block"     , "0"    );
    cvar_isWhiteListBlockOut       = register_cvar( "gal_whitelist_block_out"     , "0"    );
    cvar_voteWhiteListMapFilePath  = register_cvar( "gal_vote_whitelist_mapfile"  , ""     );
    cvar_voteUniquePrefixes        = register_cvar( "gal_vote_uniqueprefixes"     , "0"    );
    cvar_nomPlayerAllowance        = register_cvar( "gal_nom_playerallowance"     , "2"    );
    cvar_nomMapFilePath            = register_cvar( "gal_nom_mapfile"             , "*"    );
    cvar_nomPrefixes               = register_cvar( "gal_nom_prefixes"            , "1"    );
    cvar_nomQtyUsed                = register_cvar( "gal_nom_qtyused"             , "0"    );
    cvar_unnominateDisconnected    = register_cvar( "gal_unnominate_disconnected" , "0"    );
    cvar_voteAnnounceChoice        = register_cvar( "gal_vote_announcechoice"     , "1"    );
    cvar_emptyServerWaitMinutes    = register_cvar( "gal_emptyserver_wait"        , "0"    );
    cvar_isEmptyCycleByMapChange   = register_cvar( "gal_emptyserver_change"      , "0"    );
    cvar_emptyMapFilePath          = register_cvar( "gal_emptyserver_mapfile"     , ""     );
    cvar_soundsMute                = register_cvar( "gal_sounds_mute"             , "0"    );

    // Enables the colored chat control cvar.
#if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES > 0
    cvar_coloredChatEnabled = register_cvar( "gal_colored_chat_enabled", "0", FCVAR_SPONLY );
#endif

    // Not a configurable cvar, this is used instead of the `localinfo`.
    cvar_isFirstServerStart   = register_cvar( "gal_server_starting", "1", FCVAR_SPONLY );
    cvar_isToStopEmptyCycle   = register_cvar( "gal_in_empty_cycle" , "0", FCVAR_SPONLY );

    // This is a general pointer used for cvars not registered on the game.
    cvar_disabledValuePointer = register_cvar( "gal_disabled_value_pointer", "0", FCVAR_SPONLY );

    nextmap_plugin_init();
    configureEndGameCvars();
    configureTheVotingMenus();
    configureSpecificGameModFeature();

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
     * Register the color chat 'g_user_msgid' variable, if it is enabled.
     */
#if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES > 0
#if AMXX_VERSION_NUM < 183
    // If some exception happened before this, all color_print(...) messages will cause native
    // error 10, on the AMXX 182. It is because, the execution flow will not reach here, then
    // the player "g_user_msgid" will be be initialized.
    g_user_msgid = get_user_msgid( "SayText" );
#endif
#endif

    // setup some server settings
    loadPluginSetttings();
    initializeGlobalArrays();

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
    configureServerStart();
    configureServerMapChange();
    loadMapFiles();

    // Configure the Unit Tests, when they are activate.
#if DEBUG_LEVEL >= DEBUG_LEVEL_NORMAL
    saveCurrentTestsTimeStamp();
    configureTheUnitTests();
#endif

    LOGGER( 1, "    I AM EXITING plugin_cfg(0)..." )
    LOGGER( 1, "" )
}

stock configureSpecificGameModFeature()
{
    /**
     * If it is enabled, Load whether the color chat is supported by the current Game Modification.
     */
#if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES > 0
    g_isColorChatSupported = ( is_running( "czero" )
                               || is_running( "cstrike" ) );
#endif

    /**
     * Register the voting start call from the Sven Coop game.
     */
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

stock configureEndGameCvars()
{
    LOGGER( 128, "I AM ENTERING ON configureEndGameCvars(0)" )

    tryToGetGameModCvar( cvar_mp_maxrounds,  "mp_maxrounds" );
    tryToGetGameModCvar( cvar_mp_winlimit,   "mp_winlimit" );
    tryToGetGameModCvar( cvar_mp_freezetime, "mp_freezetime" );
    tryToGetGameModCvar( cvar_mp_timelimit,  "mp_timelimit" );
    tryToGetGameModCvar( cvar_mp_roundtime,  "mp_roundtime" );
    tryToGetGameModCvar( cvar_mp_chattime,   "mp_chattime" );
    tryToGetGameModCvar( cvar_sv_maxspeed,   "sv_maxspeed" );
}

stock tryToGetGameModCvar( &cvar_to_get, cvar_name[] )
{
    LOGGER( 0, "I AM ENTERING ON tryToGetGameModCvar(2) | cvar_to_get: %d, cvar_name: %s", cvar_to_get, cvar_name )

    if( !( cvar_to_get = get_cvar_pointer( cvar_name ) ) )
    {
        cvar_to_get = cvar_disabledValuePointer;
    }
}

stock configureTheVotingMenus()
{
    LOGGER( 128, "I AM ENTERING ON configureTheVotingMenus(0)" )

    g_chooseMapMenuId         = register_menuid( CHOOSE_MAP_MENU_NAME );
    g_chooseMapQuestionMenuId = register_menuid( CHOOSE_MAP_MENU_QUESTION );

    register_menucmd( g_chooseMapMenuId, MENU_KEY_1 | MENU_KEY_2 |
            MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 |
            MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9 | MENU_KEY_0,
            "vote_handleChoice" );

    register_menucmd( g_chooseMapQuestionMenuId, MENU_KEY_6 | MENU_KEY_0, "handleEndOfTheMapVoteChoice" );
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
}

stock initializeGlobalArrays()
{
    LOGGER( 128, "I AM ENTERING ON initializeGlobalArrays(0)" )

    g_reverseSearchNominationsTrie = TrieCreate();
    g_forwardSearchNominationsTrie = TrieCreate();
    g_nominationLoadedMapsTrie     = TrieCreate();

    g_nominatedMapsArray        = ArrayCreate();
    g_nominationLoadedMapsArray = ArrayCreate( MAX_MAPNAME_LENGHT );

    // initialize nominations table
    nomination_clearAll();

    // load the weighted votes flags
    get_pcvar_string( cvar_voteWeightFlags, g_voteWeightFlags, charsmax( g_voteWeightFlags ) );

    if( get_pcvar_num( cvar_recentMapsBannedNumber ) )
    {
        g_recentMapsTrie      = TrieCreate();
        g_recentListMapsArray = ArrayCreate( MAX_MAPNAME_LENGHT );

        map_loadRecentList();
        register_clcmd( "say recentmaps", "cmd_listrecent", 0 );

        if( !( get_pcvar_num( cvar_isFirstServerStart )
               && get_pcvar_num( cvar_serverStartAction ) ) )
        {
            map_writeRecentList();
        }
    }
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

stock configureServerStart()
{
    LOGGER( 128, "I AM ENTERING ON configureServerStart(0)" )

    if( get_pcvar_num( cvar_gameCrashRecreationAction ) )
    {
        g_isToCreateGameCrashFlag = true;
    }

    if( get_pcvar_num( cvar_isFirstServerStart ) )
    {
        new backupMapsFilePath[ MAX_FILE_PATH_LENGHT ];
        formatex( backupMapsFilePath, charsmax( backupMapsFilePath ), "%s/%s", g_dataDirPath, CURRENT_AND_NEXTMAP_FILE_NAME );

        if( file_exists( backupMapsFilePath ) )
        {
            handleServerStart( backupMapsFilePath );
        }
        else
        {
            saveCurrentAndNextMapNames( g_nextMapName );
        }
    }
    else // update the current and next map names every server start
    {
        saveCurrentAndNextMapNames( g_nextMapName );
    }
}

/**
 * To cache some high used server cvars.
 */
public cacheCvarsValues()
{
    LOGGER( 128, "I AM ENTERING ON cacheCvarsValues(0)" )
    g_totalVoteTime = howManySecondsLastMapTheVoting();

    g_rtvCommands            = get_pcvar_num( cvar_rtvCommands            );
    g_extendmapStepRounds    = get_pcvar_num( cvar_extendmapStepRounds    );
    g_extendmapStepFrags     = get_pcvar_num( cvar_extendmapStepFrags     );
    g_extendmapStepMinutes   = get_pcvar_num( cvar_extendmapStepMinutes   );
    g_extendmapAllowStayType = get_pcvar_num( cvar_extendmapAllowStayType );
    g_showVoteStatus         = get_pcvar_num( cvar_showVoteStatus         );
    g_voteShowNoneOptionType = get_pcvar_num( cvar_voteShowNoneOptionType );
    g_showVoteStatusType     = get_pcvar_num( cvar_showVoteStatusType     );
    g_fragLimitNumber        = get_pcvar_num( cvar_mp_fraglimit           );
    g_timeLimitNumber        = get_pcvar_num( cvar_mp_timelimit           );

    /**
     * If it is enabled, cache whether the coloring is enabled by its cvar.
     */
#if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES > 0
    g_isColoredChatEnabled = get_pcvar_num( cvar_coloredChatEnabled ) != 0;
#endif

    g_isExtendmapAllowStay      = get_pcvar_num( cvar_extendmapAllowStay   ) != 0;
    g_isToShowNoneOption        = get_pcvar_num( cvar_isToShowNoneOption   ) != 0;
    g_isToShowVoteCounter       = get_pcvar_num( cvar_isToShowVoteCounter  ) != 0;
    g_isToShowExpCountdown      = get_pcvar_num( cvar_isToShowExpCountdown ) != 0;
    g_isVirtualFragLimitSupport = get_pcvar_num( cvar_fragLimitSupport     ) != 0;

    g_maxVotingChoices = max( min( MAX_OPTIONS_IN_VOTE, get_pcvar_num( cvar_voteMapChoiceCount ) ), 2 );
}

/**
 * Setup the main task that schedules the end map voting and allow round finish feature.
 */
stock configureServerMapChange()
{
    LOGGER( 128, "I AM ENTERING ON configureServerMapChange(0)" )

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

    set_task( 15.0, "vote_manageEnd", _, _, _, "b" );
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
    LOGGER( 128, "I AM ENTERING ON handleServerStart(1) | backupMapsFilePath: %s", backupMapsFilePath )
    new startAction;

    // this is the key that tells us if this server has been restarted or not
    set_pcvar_num( cvar_isFirstServerStart, 0 );
    LOGGER( 2, "( handleServerStart ) IS CHANGING THE CVAR 'gal_server_starting' to '%d'.", 0 )

    // take the defined "server start" action
    startAction = get_pcvar_num( cvar_serverStartAction );
    isHandledGameCrashAction( startAction );

    if( startAction )
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
                loadNominationList();
            }

            new nominationsMapsCount = ArraySize( g_nominationLoadedMapsArray );

            if( nominationsMapsCount )
            {
                ArrayGetString
                (
                    g_nominationLoadedMapsArray, random_num( 0, nominationsMapsCount - 1 ),
                    mapToChange, charsmax( mapToChange )
                );
            }
        }

        configureTheMapcycleSystem( mapToChange, charsmax( mapToChange ) );

        if( mapToChange[ 0 ]
            && IS_MAP_VALID( mapToChange ) )
        {
            if( !equali( mapToChange, g_currentMapName ) )
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
    LOGGER( 128, "I AM ENTERING ON isHandledGameCrashAction(1) | startAction: %d", startAction )

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
    LOGGER( 128, "I AM ENTERING ON gameCrashActionFilePath(2) | charsmaxGameCrashActionFilePath: %d", charsmaxGameCrashActionFilePath )

    formatex( gameCrashActionFilePath, charsmaxGameCrashActionFilePath, "%s/%s", g_dataDirPath, GAME_CRASH_RECREATION_FLAG_FILE );
    LOGGER( 1, "( generateGameCrashActionFilePath ) | gameCrashActionFilePath: %s", gameCrashActionFilePath )
}

/**
 * Save the mp_maxrounds, etc and set them to half of it.
 */
public setGameToFinishAtHalfTime()
{
    LOGGER( 128, "I AM ENTERING ON setGameToFinishAtHalfTime(0)" )
    saveEndGameLimits();

    set_pcvar_float( cvar_mp_timelimit, g_originalTimelimit / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );
    set_pcvar_num(   cvar_mp_maxrounds, g_originalMaxRounds / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );
    set_pcvar_num(   cvar_mp_winlimit,  g_originalWinLimit  / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );
    set_pcvar_num(   cvar_mp_fraglimit, g_originalFragLimit / SERVER_GAME_CRASH_ACTION_RATIO_DIVISOR );

    LOGGER( 2, "( setGameToFinishAtHalfTime ) IS CHANGING THE CVAR 'mp_timelimit' to '%f'.", get_pcvar_float( cvar_mp_timelimit ) )
    LOGGER( 2, "( setGameToFinishAtHalfTime ) IS CHANGING THE CVAR 'mp_fraglimit' to '%d'.", get_pcvar_num( cvar_mp_fraglimit ) )
    LOGGER( 2, "( setGameToFinishAtHalfTime ) IS CHANGING THE CVAR 'mp_maxrounds' to '%d'.", get_pcvar_num( cvar_mp_maxrounds ) )
    LOGGER( 2, "( setGameToFinishAtHalfTime ) IS CHANGING THE CVAR 'mp_winlimit' to '%d'.", get_pcvar_num( cvar_mp_winlimit ) )
}

/**
 * To configure the mapcycle system and to detect if the last MAX_SERVER_RESTART_ACCEPTABLE restarts
 * was to the same map. If so, change to the next map right after it.
 */
stock configureTheMapcycleSystem( currentMap[], currentMapLength )
{
    LOGGER( 128, "I AM ENTERING ON configureTheMapcycleSystem(2) | currentMap: %s", currentMap )

    new possibleNextMapPosition;
    new restartsOnTheCurrentMap;
    new Array:mapcycleFileListArray;

    new possibleNextMap [ MAX_MAPNAME_LENGHT ];
    new mapcycleFilePath[ MAX_FILE_PATH_LENGHT ];

    mapcycleFileListArray   = ArrayCreate( MAX_MAPNAME_LENGHT );
    restartsOnTheCurrentMap = getRestartsOnTheCurrentMap( currentMap );

    get_pcvar_string( cvar_mapcyclefile, mapcycleFilePath, charsmax( mapcycleFilePath ) );
    map_populateList( mapcycleFileListArray, mapcycleFilePath, charsmax( mapcycleFilePath ) );

    possibleNextMapPosition = map_getNext( mapcycleFileListArray, currentMap, possibleNextMap );

    LOGGER( 4, "( configureTheMapcycleSystem ) possibleNextMapPosition: %d", possibleNextMapPosition )
    LOGGER( 4, "( configureTheMapcycleSystem ) restartsOnTheCurrentMap: %d, currentMap: %s, possibleNextMap: %s", \
            restartsOnTheCurrentMap, currentMap, possibleNextMap )

    if( possibleNextMapPosition != -1 )
    {
        if( restartsOnTheCurrentMap > MAX_SERVER_RESTART_ACCEPTABLE )
        {
            new possibleCurrentMap    [ MAX_MAPNAME_LENGHT ];
            new lastMapChangedFilePath[ MAX_FILE_PATH_LENGHT ];

            copy( possibleCurrentMap, charsmax( possibleCurrentMap ), possibleNextMap );
            possibleNextMapPosition = map_getNext( mapcycleFileListArray, possibleCurrentMap, possibleNextMap );

            if( possibleNextMapPosition != -1 )
            {
                configureTheNextMapPlugin( possibleNextMapPosition, possibleNextMap, mapcycleFilePath );
            }

            // Clear the old data
            copy( currentMap, currentMapLength, possibleCurrentMap );
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
            configureTheNextMapPlugin( possibleNextMapPosition, possibleNextMap, mapcycleFilePath );
            LOGGER( 4, "( configureTheMapcycleSystem ) restartsOnTheCurrentMap < MAX_SERVER_RESTART_ACCEPTABLE" )
            LOGGER( 4, "" )
        }
    }
    else
    {
        configureTheNextMapPlugin( 0, possibleNextMap, mapcycleFilePath );
        LOGGER( 4, "( configureTheMapcycleSystem ) configureTheNextMapPlugin( 0, possibleNextMap )" )
        LOGGER( 4, "" )
    }

    ArrayDestroy( mapcycleFileListArray );
}

stock configureTheNextMapPlugin( possibleNextMapPosition, possibleNextMap[], mapcycleFilePath[] )
{
    LOGGER( 128 + 4, "I AM ENTERING ON configureTheNextMapPlugin(2) | possibleNextMapPosition: %d, possibleNextMap: %s", \
            possibleNextMapPosition, possibleNextMap )

    g_nextMapCyclePosition = possibleNextMapPosition;

    setNextMap( possibleNextMap, false );
    saveCurrentMapCycleSetting( mapcycleFilePath );
}

stock getRestartsOnTheCurrentMap( mapToChange[] )
{
    LOGGER( 128, "I AM ENTERING ON getRestartsOnTheCurrentMap(1) | mapToChange: %s", mapToChange )

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
            lastMapChangedFilePath, mapToChange )

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
        LOGGER( 4, "( getRestartsOnTheCurrentMap ) lastMapChangedName: %s", lastMapChangedName )
        LOGGER( 4, "( getRestartsOnTheCurrentMap ) lastMapChangedCountString: %s, lastMapChangedCount: %d", \
                lastMapChangedCountString, lastMapChangedCount )

        if( equali( mapToChange, lastMapChangedName ) )
        {
            ++lastMapChangedCount;

            fprintf( lastMapChangedFile, "^n%d", lastMapChangedCount );
            LOGGER( 4, "( getRestartsOnTheCurrentMap ) mapToChange is equal to lastMapChangedName." )
        }
        else
        {
            lastMapChangedCount = 0;

            fprintf( lastMapChangedFile, "^n0" );
            LOGGER( 4, "( getRestartsOnTheCurrentMap ) mapToChange is not equal to lastMapChangedName." )
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
    LOGGER( 128, "I AM ENTERING ON vote_manageEarlyStart(0)" )

    g_voteStatus |= VOTE_IS_EARLY;
    set_task( 120.0, "startNonForcedVoting", TASKID_VOTE_STARTDIRECTOR );
}

public startNonForcedVoting()
{
    LOGGER( 128, "I AM ENTERING ON startNonForcedVoting(0)" )
    vote_startDirector( false );
}

stock setNextMap( nextMapName[], bool:isToUpdateTheCvar = true )
{
    LOGGER( 128, "I AM ENTERING ON setNextMap(1) | nextMapName: %s", nextMapName )

    if( IS_MAP_VALID( nextMapName ) )
    {
        // set the queryable cvar
        if( isToUpdateTheCvar
            || !( get_pcvar_num( cvar_nextMapChangeAnnounce )
                  && get_pcvar_num( cvar_endOfMapVote ) ) )
        {
            LOGGER( 2, "( setNextMap ) IS CHANGING THE CVAR 'amx_nextmap' to '%s'.", nextMapName )
            set_pcvar_string( cvar_amx_nextmap, nextMapName );
        }

        copy( g_nextMapName, charsmax( g_nextMapName ), nextMapName );

        // update our data file
        saveCurrentAndNextMapNames( nextMapName );
        LOGGER( 2, "( setNextMap ) IS CHANGING THE global variable g_nextMapName to '%s'.", nextMapName )
    }
    else
    {
        LOGGER( 1, "AMX_ERR_PARAMS, %s, was tried to set a invalid next-map!", nextMapName )
        log_error( AMX_ERR_PARAMS, "%s, was tried to set a invalid next-map!", nextMapName );
    }
}

stock saveCurrentAndNextMapNames( nextMapName[] )
{
    LOGGER( 128, "I AM ENTERING ON saveCurrentAndNextMapNames(1) | nextMapName: %s", nextMapName )

    new backupMapsFile;
    new backupMapsFilePath[ MAX_FILE_PATH_LENGHT ];

    formatex( backupMapsFilePath, charsmax( backupMapsFilePath ), "%s/%s", g_dataDirPath, CURRENT_AND_NEXTMAP_FILE_NAME );
    backupMapsFile = fopen( backupMapsFilePath, "wt" );

    if( backupMapsFile )
    {
        fprintf( backupMapsFile, "%s", g_currentMapName );
        fprintf( backupMapsFile, "^n%s", nextMapName );
        fclose( backupMapsFile );
    }
}

public map_loadRecentList()
{
    LOGGER( 128, "I AM ENTERING ON map_loadRecentList(0)" )
    new recentMapsFilePath[ MAX_FILE_PATH_LENGHT ];

    formatex( recentMapsFilePath, charsmax( recentMapsFilePath ), "%s/%s", g_dataDirPath, RECENT_BAN_MAPS_FILE_NAME );
    new recentMapsFileDescriptor = fopen( recentMapsFilePath, "rt" );

    if( recentMapsFileDescriptor )
    {
        new recentMapName[ MAX_MAPNAME_LENGHT ];
        new maxRecentMapsBans = get_pcvar_num( cvar_recentMapsBannedNumber );

        while( !feof( recentMapsFileDescriptor ) )
        {
            fgets( recentMapsFileDescriptor, recentMapName, charsmax( recentMapName ) );
            trim( recentMapName );

            if( recentMapName[ 0 ]
                && IS_MAP_VALID( recentMapName ) )
            {
                if( g_recentMapCount == maxRecentMapsBans )
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

public map_writeRecentList()
{
    LOGGER( 128, "I AM ENTERING ON map_writeRecentList(0)" )

    new Trie:mapCycleMapsTrie;
    new bool:isOnlyRecentMapcycleMaps;
    new recentMapsFileDescriptor;

    new recentMapName        [ MAX_MAPNAME_LENGHT ];
    new recentMapsFilePath   [ MAX_FILE_PATH_LENGHT ];
    new voteMapsFilerFilePath[ MAX_FILE_PATH_LENGHT ];

    formatex( recentMapsFilePath, charsmax( recentMapsFilePath ), "%s/%s", g_dataDirPath, RECENT_BAN_MAPS_FILE_NAME );
    isOnlyRecentMapcycleMaps = get_pcvar_num( cvar_isOnlyRecentMapcycleMaps ) != 0;

    if( isOnlyRecentMapcycleMaps )
    {
        get_pcvar_string( cvar_voteMapFilePath, voteMapsFilerFilePath, charsmax( voteMapsFilerFilePath ) );

        // '*' is and invalid because it already allow all server maps.
        if( !equal( voteMapsFilerFilePath, "*" ) )
        {
            mapCycleMapsTrie = TrieCreate();

            // This call is only to load the 'mapCycleMapsTrie'
            map_populateList( _, voteMapsFilerFilePath, charsmax( voteMapsFilerFilePath ), mapCycleMapsTrie );
        }
        else
        {
            isOnlyRecentMapcycleMaps = false;
        }
    }

    recentMapsFileDescriptor = fopen( recentMapsFilePath, "wt" );

    if( recentMapsFileDescriptor )
    {
        if( !TrieKeyExists( g_recentMapsTrie, g_currentMapName ) )
        {
            if( isOnlyRecentMapcycleMaps )
            {
                if( TrieKeyExists( mapCycleMapsTrie, g_currentMapName ) )
                {
                    fprintf( recentMapsFileDescriptor, "%s^n", g_currentMapName );
                }
            }
            else
            {
                fprintf( recentMapsFileDescriptor, "%s^n", g_currentMapName );
            }
        }

        for( new mapIndex = 0; mapIndex < g_recentMapCount; ++mapIndex )
        {
            ArrayGetString( g_recentListMapsArray, mapIndex, recentMapName, charsmax( recentMapName ) );

            if( isOnlyRecentMapcycleMaps )
            {
                if( TrieKeyExists( mapCycleMapsTrie, recentMapName ) )
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
    }

    TRY_TO_APPLY( TrieDestroy, mapCycleMapsTrie )
}

stock loadWhiteListFileFromFile( &Array:whitelistArray, whiteListFilePath[] )
{
    LOGGER( 128, "I AM ENTERING ON loadWhiteListFileFromFile(2) | whitelistArray: %d, whiteListFilePath: %s", \
            whitelistArray,  whiteListFilePath )

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
    LOGGER( 1, "I AM EXITING loadWhiteListFileFromFile(2) | whitelistArray: %d", whitelistArray )
}

stock processLoadedMapFileFromFile( &Array:playerFillerMapsArray, &Array:fillersFilePathsArray )
{
    LOGGER( 128, "I AM ENTERING ON processLoadedMapFileFromFile(2) groupCount: %d", ArraySize( fillersFilePathsArray ) )
    new fillerFilePath[ MAX_FILE_PATH_LENGHT ];

    new Array:fillerMapsArray;
    new groupCount = ArraySize( fillersFilePathsArray );

    // fill remaining slots with random maps from each filler file, as much as possible
    for( new groupIndex = 0; groupIndex < groupCount; ++groupIndex )
    {
        fillerMapsArray = ArrayCreate( MAX_MAPNAME_LENGHT );
        ArrayGetString(  fillersFilePathsArray, groupIndex, fillerFilePath, charsmax( fillerFilePath ) );

        map_populateList( fillerMapsArray, fillerFilePath, charsmax( fillerFilePath ) );
        ArrayPushCell( playerFillerMapsArray, fillerMapsArray );

        LOGGER( 8, "[%i] groupCount: %i, filersMapCount: %i", groupIndex, groupCount, ArraySize( fillerMapsArray ) )
        LOGGER( 8, "     fillersFilePaths[%i]: %s", groupIndex, fillerFilePath )
    }
}

stock loadMapFiles()
{
    LOGGER( 128, "I AM ENTERING ON loadMapFiles(0)" )
    new mapFilerFilePath[ MAX_FILE_PATH_LENGHT ];

    TRY_TO_APPLY( ArrayDestroy, g_whitelistFileArray )
    TRY_TO_APPLY( ArrayDestroy, g_voteMinPlayerFillerPathsArray )
    TRY_TO_APPLY( ArrayDestroy, g_voteNorPlayerFillerPathsArray )
    TRY_TO_APPLY( ArrayDestroy, g_minMaxMapsPerGroupToUseArray )
    TRY_TO_APPLY( ArrayDestroy, g_norMaxMapsPerGroupToUseArray )

    destroy_two_dimensional_array( g_norPlayerFillerMapGroupArrays );
    destroy_two_dimensional_array( g_minPlayerFillerMapGroupArrays );

    g_whitelistFileArray = ArrayCreate( MAX_LONG_STRING );

    g_voteMinPlayerFillerPathsArray = ArrayCreate( MAX_MAPNAME_LENGHT );
    g_minPlayerFillerMapGroupArrays = ArrayCreate();
    g_minMaxMapsPerGroupToUseArray  = ArrayCreate();

    g_voteNorPlayerFillerPathsArray = ArrayCreate( MAX_MAPNAME_LENGHT );
    g_norPlayerFillerMapGroupArrays = ArrayCreate();
    g_norMaxMapsPerGroupToUseArray  = ArrayCreate();

    LOGGER( 4, "" )
    get_pcvar_string( cvar_voteWhiteListMapFilePath, mapFilerFilePath, charsmax( mapFilerFilePath ) );
    loadWhiteListFileFromFile( g_whitelistFileArray, mapFilerFilePath );

    LOGGER( 4, "" )
    get_pcvar_string( cvar_voteMinPlayersMapFilePath, mapFilerFilePath, charsmax( mapFilerFilePath ) );
    loadMapGroupsFeatureFile( mapFilerFilePath, g_voteMinPlayerFillerPathsArray, g_minMaxMapsPerGroupToUseArray );

    LOGGER( 4, "" )
    get_pcvar_string( cvar_voteMapFilePath, mapFilerFilePath, charsmax( mapFilerFilePath ) );
    loadMapGroupsFeatureFile( mapFilerFilePath, g_voteNorPlayerFillerPathsArray, g_norMaxMapsPerGroupToUseArray );

    LOGGER( 4, "" )
    processLoadedMapFileFromFile( g_minPlayerFillerMapGroupArrays, g_voteMinPlayerFillerPathsArray );
    processLoadedMapFileFromFile( g_norPlayerFillerMapGroupArrays, g_voteNorPlayerFillerPathsArray );

    LOGGER( 4, "" )
    LOGGER( 4, "", debugLoadedMapFileFromFile( g_minPlayerFillerMapGroupArrays, g_minMaxMapsPerGroupToUseArray ) )
    LOGGER( 4, "", debugLoadedMapFileFromFile( g_norPlayerFillerMapGroupArrays, g_norMaxMapsPerGroupToUseArray ) )

    LOGGER( 4, "( loadMapFiles ) Maps Files Loaded." )
    LOGGER( 4, "" )
    LOGGER( 4, "" )
}

stock debugLoadedMapFileFromFile( &Array:playerFillerMapsArray, &Array:maxMapsPerGroupToUseArray )
{
    LOGGER( 128, "I AM ENTERING ON debugLoadedMapFileFromFile(3) groupCount: %d", ArraySize( playerFillerMapsArray ) )

    new Array:fillerMapsArray;
    new fillerMap[ MAX_FILE_PATH_LENGHT ];

    new groupCount = ArraySize( playerFillerMapsArray );

    // fill remaining slots with random maps from each filler file, as much as possible
    for( new groupIndex = 0; groupIndex < groupCount; ++groupIndex )
    {
        fillerMapsArray = ArrayGetCell( playerFillerMapsArray, groupIndex );

        LOGGER( 8, "[%i] maxMapsPerGroupToUse: %i, filersMapCount: %i", groupIndex, \
                ArrayGetCell( maxMapsPerGroupToUseArray, groupIndex ), ArraySize( fillerMapsArray ) )

        for( new mapIndex = 0; mapIndex < ArraySize( fillerMapsArray ) && mapIndex < 10; mapIndex++ )
        {
            ArrayGetString( fillerMapsArray, mapIndex, fillerMap, charsmax( fillerMap ) );
            LOGGER( 8, "   fillerMap[%i]: %s", mapIndex, fillerMap )
        }
    }

    return 0;
}

stock loadMapGroupsFeatureFile( mapFilerFilePath[], &Array:mapFilersPathArray, &Array:maxMapsPerGroupToUse )
{
    LOGGER( 128, "I AM ENTERING ON loadMapGroupsFeatureFile(0), mapFilerFilePath: %s", mapFilerFilePath )

    // The mapFilerFilePaths '*' and '#' disables The Map Groups Feature.
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
                            LOGGER( 1, "AMX_ERR_BOUNDS, %L", LANG_SERVER, "GAL_GRP_FAIL_TOOMANY", mapFilerFilePath )
                            log_error( AMX_ERR_BOUNDS, "%L", LANG_SERVER, "GAL_GRP_FAIL_TOOMANY", mapFilerFilePath );

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
    LOGGER( 0, "I AM ENTERING ON client_death_event(0)" )

    if( g_fragLimitNumber )
    {
        new killerId = read_data( 1 );

        if( killerId < MAX_PLAYERS_COUNT
            && killerId > 0 )
        {
            new frags;

            if( ( ( ( frags = ++g_playersKills[ killerId ] ) + VOTE_START_FRAGS() ) > g_fragLimitNumber )
                && !IS_END_OF_MAP_VOTING_GOING_ON() )
            {
                if( get_pcvar_num( cvar_endOfMapVote ) )
                {
                    g_isVotingByFrags = true;
                    vote_startDirector( false );
                }
            }

            if( frags > g_greatestKillerFrags )
            {
                g_greatestKillerFrags = frags;

                if( g_isVirtualFragLimitSupport
                    && g_greatestKillerFrags > g_fragLimitNumber - 1 )
                {
                    try_to_manage_map_end( true );
                }
            }
        }
    }
}

/**
 * Predict if this will be the last round and allow to start the voting.
 * Give time range to try detecting the round start, to avoid the old buy weapons menu override.
 * This is called every round start and determines whether this round should be used to perform
 * the map voting.
 *
 * @param secondsRemaining     how many seconds are remaining to the map end.
 */
stock isToStartTheVotingOnThisRound( secondsRemaining )
{
    LOGGER( 128, "I AM ENTERING ON isToStartTheVotingOnThisRound(1) secondsRemaining: %d", secondsRemaining )

    LOGGER( 32, "( isToStartTheVotingOnThisRound ) task_exists: %d", task_exists( TASKID_START_VOTING_BY_TIMER ) )
    LOGGER( 32, "( isToStartTheVotingOnThisRound ) cvar_endOfMapVote: %d", get_pcvar_num( cvar_endOfMapVote ) )

    if( get_pcvar_num( cvar_endOfMapVote )
        && !task_exists( TASKID_START_VOTING_BY_TIMER ) )
    {
        new roundsRemaining;

        // Make sure there are enough data to operate, otherwise set an invalid data.
        if( g_totalRoundsSavedTimes > 7 )
        {
            roundsRemaining = howManyRoundsAreRemaining( secondsRemaining - g_totalVoteTime );
        }
        else
        {
            roundsRemaining = 10;
        }

        LOGGER( 32, "( isToStartTheVotingOnThisRound ) roundsRemaining: %d", roundsRemaining )
        LOGGER( 32, "( isToStartTheVotingOnThisRound ) g_isTheLastGameRound: %d", g_isTheLastGameRound )
        LOGGER( 32, "( isToStartTheVotingOnThisRound ) g_isThePenultGameRound: %d", g_isThePenultGameRound )
        LOGGER( 32, "( isToStartTheVotingOnThisRound ) g_totalRoundsSavedTimes: %d", g_totalRoundsSavedTimes )
        LOGGER( 32, "( isToStartTheVotingOnThisRound ) cvar_endOnRound: %d", get_pcvar_num( cvar_endOnRound ) )
        LOGGER( 32, "( isToStartTheVotingOnThisRound ) cvar_endOfMapVoteStart: %d", get_pcvar_num( cvar_endOfMapVoteStart ) )

        switch( get_pcvar_num( cvar_endOfMapVoteStart ) )
        {
            // `cvar_endOnRound`: When time runs out, end at the current round end.
            // `cvar_endOfMapVoteStart`: To start the voting on the last round to be played.
            case 1:
            {
                if( get_pcvar_num( cvar_endOnRound ) )
                {
                    if( g_isTheLastGameRound )
                    {
                        LOGGER( 1, "    ( isToStartTheVotingOnThisRound ) Returning true." )
                        return true;
                    }
                }
                else if( roundsRemaining == 0 )
                {
                    LOGGER( 1, "    ( isToStartTheVotingOnThisRound ) Returning true." )
                    return true;
                }
            }
            // `cvar_endOnRound`: When time runs out, end at the next round end.
            // `cvar_endOfMapVoteStart`: To start the voting on the round before the last.
            case 2:
            {
                if( get_pcvar_num( cvar_endOnRound ) )
                {
                    if( g_isThePenultGameRound )
                    {
                        LOGGER( 1, "    ( isToStartTheVotingOnThisRound ) Returning true." )
                        return true;
                    }
                }
                else if( roundsRemaining == 2 )
                {
                    LOGGER( 1, "    ( isToStartTheVotingOnThisRound ) Returning true." )
                    return true;
                }
            }
            // `cvar_endOnRound`: Do not applies.
            // `cvar_endOfMapVoteStart`: To start the voting on the round before the last of the last.
            case 3:
            {
                if( get_pcvar_num( cvar_endOnRound ) )
                {
                    if( roundsRemaining < 2 )
                    {
                        LOGGER( 1, "    ( isToStartTheVotingOnThisRound ) Returning true." )
                        return true;
                    }
                }
                else if( roundsRemaining < 4 )
                {
                    LOGGER( 1, "    ( isToStartTheVotingOnThisRound ) Returning true." )
                    return true;
                }
            }
        }
    }

    LOGGER( 1, "    ( isToStartTheVotingOnThisRound ) Just returning false." )
    return false;
}

stock howManySecondsLastMapTheVoting()
{
    LOGGER( 128, "I AM ENTERING ON howManySecondsLastMapTheVoting(0)" )
    new voteTime;

    // Until the pendingVoteCountdown(0) to finish takes 7.0 + 1.0 + 1.0 seconds.
    voteTime = 7 + 1 + 1;

    // After, it takes more the `g_voteDuration` until the the close vote function to be called.
    // Let us assume the worst case, then always will be performed a runoff voting.
    voteTime = voteTime + get_pcvar_num( cvar_voteDuration );
    voteTime = voteTime + get_pcvar_num( cvar_runoffDuration );

    // When the voting is closed on closeVoting(0), take more 6 seconds until the result to be counted.
    // And more 3 seconds until the runoff voting to start.
    // Then we need to count again those 7.0 + 1.0 + 1.0 until the pendingVoteCountdown(0) and the
    // other 6 seconds until the runoff voting results to be counted.
    voteTime = voteTime + 6 + 3 + 7 + 1 + 1 + 6;

    LOGGER( 1, "    ( howManySecondsLastMapTheVoting ) Returning the vote total time: %d", voteTime )
    return voteTime;
}

stock howManyRoundsAreRemaining( secondsRemaining )
{
    LOGGER( 128, "I AM ENTERING ON howManyRoundsAreRemaining(2), g_roundAverageTime: %d", g_roundAverageTime )
    LOGGER( 1, "    ( howManyRoundsAreRemaining ) Returning rounds remaining: %d", secondsRemaining / g_roundAverageTime )

    return secondsRemaining / g_roundAverageTime;
}

public round_start_event()
{
    LOGGER( 128, "I AM ENTERING ON round_start_event(0)" )

    if( isToStartTheVotingOnThisRound( get_timeleft() ) )
    {
        set_task( float( ROUND_VOTING_START_SECONDS_DELAY() ), "start_voting_by_timer", TASKID_START_VOTING_BY_TIMER );
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

    g_roundStartTime = floatround( get_gametime(), floatround_ceil );
}

public team_win_event()
{
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

        if( ( ( wins_CT_trigger > g_winLimitInteger )
              || ( wins_Terrorist_trigger > g_winLimitInteger ) )
            && !IS_END_OF_MAP_VOTING_GOING_ON() )
        {
            g_isMaxroundsExtend = false;
            START_VOTING_BY_MIDDLE_ROUND_DELAY()
        }

        if( g_totalCtWins > g_winLimitInteger - 2
            || g_totalTerroristsWins > g_winLimitInteger - 2 )
        {
            try_to_manage_map_end();
        }
    }

    LOGGER( 32, "( team_win_event ) | string_team_winner: %s", string_team_winner )
    LOGGER( 32, "( team_win_event ) | g_winLimitInteger: %d, wins_CT_trigger: %d, wins_Terrorist_trigger: %d", \
            g_winLimitInteger, wins_CT_trigger, wins_Terrorist_trigger )
}

public round_end_event()
{
    LOGGER( 128, "I AM ENTERING ON round_end_event(0)" )

    new current_rounds_trigger;
    g_totalRoundsPlayed++;

    saveTheRoundTime();
    g_maxRoundsNumber = get_pcvar_num( cvar_mp_maxrounds );

    if( g_maxRoundsNumber )
    {
        current_rounds_trigger = g_totalRoundsPlayed + VOTE_START_ROUNDS;

        if( ( current_rounds_trigger > g_maxRoundsNumber )
            && !IS_END_OF_MAP_VOTING_GOING_ON() )
        {
            g_isMaxroundsExtend = true;
            START_VOTING_BY_MIDDLE_ROUND_DELAY()
        }

        if( g_totalRoundsPlayed > g_maxRoundsNumber - 2 )
        {
            try_to_manage_map_end();
        }
    }

    if( !( g_voteStatus & VOTE_IS_IN_PROGRESS ) )
    {
        // If this is called when the voting is going on, it will cause the voting to be cut
        // and will force the map to immediately change to the next map on the map cycle.
        endRoundWatchdog();
    }

    LOGGER( 32, "( round_end_event ) | g_maxRoundsNumber: %d", g_maxRoundsNumber )
    LOGGER( 32, "( round_end_event ) | g_totalRoundsPlayed: %d, current_rounds_trigger: %d", \
            g_totalRoundsPlayed, current_rounds_trigger )
}

stock saveTheRoundTime()
{
    LOGGER( 128, "I AM ENTERING ON saveTheRoundTime(0)" )
    new roundEndTime = floatround( get_gametime(), floatround_ceil ) - g_roundStartTime;

    // Rounds taking less than 10 seconds does not seem to fit.
    if( roundEndTime > 10 )
    {
        static lastSavedRound;
        static roundPlayedTimes[ 20 ];

        // To keep the latest round data up to date.
        roundPlayedTimes[ lastSavedRound ] = roundEndTime;
        g_roundAverageTime                 = roundPlayedTimes[ 0 ];

        lastSavedRound = ( lastSavedRound + 1 ) % sizeof roundPlayedTimes;
        g_totalRoundsSavedTimes + 1 > sizeof roundPlayedTimes ? g_totalRoundsSavedTimes : g_totalRoundsSavedTimes++;

        for( new index = 1; index < g_totalRoundsSavedTimes; index++ )
        {
            g_roundAverageTime = ( g_roundAverageTime + roundPlayedTimes[ index ] ) / 2;
        }

        LOGGER( 32, "( saveTheRoundTime ) lastSavedRound: %d", lastSavedRound )
        LOGGER( 32, "( saveTheRoundTime ) g_roundAverageTime: %d", g_roundAverageTime )
        LOGGER( 32, "( saveTheRoundTime ) g_totalRoundsSavedTimes: %d", g_totalRoundsSavedTimes )
    }

    LOGGER( 32, "( saveTheRoundTime ) roundEndTime: %d", roundEndTime )
}

stock try_to_manage_map_end( bool:isToImmediatelyChangeLevel = false )
{
    LOGGER( 128, "I AM ENTERING ON try_to_manage_map_end(1) isToImmediatelyChangeLevel: %d", isToImmediatelyChangeLevel )

    if( g_isOnMaintenanceMode )
    {
        prevent_map_change();
        color_print( 0, "%L", LANG_PLAYER, "GAL_CHANGE_MAINTENANCE" );
    }
    else if( !( g_isTheLastGameRound
                || g_isThePenultGameRound ) )
    {
        new bool:areThereEnoughPlayers = get_realplayersnum() >= get_pcvar_num( cvar_endOnRound_msg );

        if( !areThereEnoughPlayers
            && isToImmediatelyChangeLevel )
        {
            try_to_process_last_round( isToImmediatelyChangeLevel );
        }
        else if( !map_manageEnd()
                 && isToImmediatelyChangeLevel )
        {
            try_to_process_last_round( isToImmediatelyChangeLevel );
        }
    }
}

public map_manageEnd()
{
    LOGGER( 128, "I AM ENTERING ON map_manageEnd(0)" )
    LOGGER( 2, "%32s mp_timelimit: %f, get_realplayersnum: %d", "map_manageEnd(in)", \
            get_pcvar_float( cvar_mp_timelimit ), get_realplayersnum() )

    switch( get_pcvar_num( cvar_endOnRound ) )
    {
        // when time runs out, end at the current round end
        case 1:
        {
            g_isTheLastGameRound = true;
            prevent_map_change();

            color_print( 0, "%L %L %L",
                    LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED", LANG_PLAYER, "GAL_CHANGE_NEXTROUND", LANG_PLAYER, "GAL_NEXTMAP", g_nextMapName );
        }
        // when time runs out, end at the next round end
        case 2:
        {
            prevent_map_change();

            // This is to avoid have a extra round at special mods where time limit is equal the
            // round timer.
            if( get_pcvar_float( cvar_mp_roundtime ) > 8.0 )
            {
                g_isTheLastGameRound = true;
                color_print( 0, "%L %L %L",
                        LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED", LANG_PLAYER, "GAL_CHANGE_NEXTROUND", LANG_PLAYER, "GAL_NEXTMAP", g_nextMapName );
            }
            else
            {
                g_isThePenultGameRound = true;
                color_print( 0, "%L %L",
                        LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED", LANG_PLAYER, "GAL_NEXTMAP", g_nextMapName );
            }
        }
        default:
        {
            LOGGER( 1, "    ( map_manageEnd ) Just returning and blocking the end management." )
            return false;
        }
    }

    configure_last_round_HUD();
    LOGGER( 2, "%32s mp_timelimit: %f, get_realplayersnum: %d", "map_manageEnd(out)", \
            get_pcvar_float( cvar_mp_timelimit ), get_realplayersnum() )

    LOGGER( 1, "    ( map_manageEnd ) Just returning and allowing the end management." )
    return true;
}

stock prevent_map_change()
{
    LOGGER( 128, "I AM ENTERING ON prevent_map_change(0)" )
    saveEndGameLimits();

    // If somehow the cvar_mp_roundtime does not exist, it will point to a cvar within zero
    new Float:roundTimeMinutes = get_pcvar_float( cvar_mp_roundtime );

    // Prevent the map from ending automatically.
    set_pcvar_float( cvar_mp_timelimit, 0.0 );
    set_pcvar_num(   cvar_mp_maxrounds, 0   );
    set_pcvar_num(   cvar_mp_winlimit,  0   );
    set_pcvar_num(   cvar_mp_fraglimit, 0   );

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
 * Called on the round_end_event(). This is the place to change the map when the variables
 * `g_isThePenultGameRound` and `g_isTheLastGameRound` are set to true.
 */
stock endRoundWatchdog()
{
    LOGGER( 128, "I AM ENTERING ON endRoundWatchdog(0)" )

    // When the voting is in progress, does not update these cvars.
    g_fragLimitNumber = get_pcvar_num( cvar_mp_fraglimit );
    g_timeLimitNumber = get_pcvar_num( cvar_mp_timelimit );

    // When time runs out, end map at the current round end.
    if( g_isTheLastGameRound )
    {
        remove_task( TASKID_SHOW_LAST_ROUND_HUD );
        set_task( 6.0, "process_last_round_by_set_task", TASKID_PROCESS_LAST_ROUND );
    }
    else if( g_isThePenultGameRound )
    {
        // When time runs out, end map at the next round end.
        g_isTheLastGameRound = true;

        // Set it to false because later we first could try to check this before `g_isTheLastGameRound`
        // resulting on an infinity loop.
        g_isThePenultGameRound = false;

        remove_task( TASKID_SHOW_LAST_ROUND_HUD );
        set_task( 5.0, "configure_last_round_HUD", TASKID_PROCESS_LAST_ROUND );
    }
}

/**
 * Used to call try_to_process_last_round(1) without setting its default parameter `isToImmediatelyChangeLevel`
 * to true, when calling it from a set_task() function within a task id.
 *
 * This is because when a set_task() has a task id, will will pass its task id as the first parameter.
 */
public process_last_round_by_set_task()
{
    LOGGER( 128, "I AM ENTERING ON process_last_round_by_set_task(0)" )
    try_to_process_last_round();
}

/**
 * This is a fail safe to not allow map changes if must there be a map voting and it was not
 * finished/performed yet.
 */
stock try_to_process_last_round( bool:isToImmediatelyChangeLevel = false )
{
    LOGGER( 128, "I AM ENTERING ON try_to_process_last_round(0)" )
    new bool:allowMapChange;

    if( g_voteStatus & VOTE_IS_OVER )
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
        process_last_round( isToImmediatelyChangeLevel );
    }
}

/**
 * To perform the switch between the straight intermission_processing(0) and the last_round_countdown(0).
 *
 * This is used to be called from the computeVotes(0) end voting function. To call process_last_round(1)
 * with the variable `g_isToChangeMapOnVotingEnd` properly set.
 */
stock process_last_round( bool:isToImmediatelyChangeLevel = false )
{
    LOGGER( 128, "I AM ENTERING ON process_last_round(1)" )

    if( g_isTheLastGameRound
        || isToImmediatelyChangeLevel )
    {
        if( get_pcvar_num( cvar_isEndMapCountdown ) )
        {
            g_lastRroundCountdown = 6;
            set_task( 1.0, "last_round_countdown", TASKID_PROCESS_LAST_ROUND, _, _, "a", 6 );
        }
        else
        {
            intermission_processing();
        }
    }
}

stock intermission_processing()
{
    LOGGER( 128, "I AM ENTERING ON intermission_processing(0)" )
    new Float:mp_chattime = get_intermission_chattime();

    // Choose how to change the level.
    if( g_isTimeToRestart )
    {
        set_task( mp_chattime, "map_change_stays", TASKID_MAP_CHANGE );
    }
    else
    {
        set_task( mp_chattime, "map_change", TASKID_MAP_CHANGE );
    }

    show_intermission( mp_chattime );
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

    return mp_chattime;
}

/**
 * Freeze the game and show the scoreboard.
 */
stock show_intermission( Float:mp_chattime )
{
    LOGGER( 128, "I AM ENTERING ON show_intermission(1) mp_chattime: %f", mp_chattime )

    if( get_pcvar_num( cvar_isEndMapCountdown ) )
    {
        LOGGER( 128, " ( show_intermission ) dropping weapons." )

        g_isTimeToResetGame    = true; // reset the game ending if there is a restart round.
        g_original_sv_maxspeed = get_pcvar_float( cvar_sv_maxspeed );

        set_task( mp_chattime - 0.5, "intermission_hold", TASKID_INTERMISSION_HOLD );
        intermission_effects();
    }
    else
    {
        LOGGER( 128, " ( show_intermission ) do not dropping weapons." )
        intermission_hold();
    }
}

public intermission_hold()
{
    LOGGER( 128, "I AM ENTERING ON intermission_hold(0)" )

    message_begin( MSG_ALL, SVC_INTERMISSION );
    message_end();
}

stock intermission_effects()
{
    LOGGER( 128, "I AM ENTERING ON intermission_effects(0)" )

    set_pcvar_float( cvar_sv_maxspeed, 0.0 );
    LOGGER( 2, "( intermission_effects ) IS CHANGING THE CVAR 'sv_maxspeed' to '%f'.", get_pcvar_float( cvar_sv_maxspeed ) )

    client_cmd( 0, "slot1" );
    client_cmd( 0, "drop weapon_c4" );
    client_cmd( 0, "drop" );
    client_cmd( 0, "drop" );

    client_cmd( 0, "sgren" );
    client_cmd( 0, "hegren" );

    client_cmd( 0, "+showscores" );
    client_cmd( 0, "speak ^"loading environment on to your computer^"" );
}

public last_round_countdown()
{
    LOGGER( 128, "I AM ENTERING ON last_round_countdown(0)" )
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
        intermission_processing();
    }
}

public configure_last_round_HUD()
{
    LOGGER( 128, "I AM ENTERING ON configure_last_round_HUD(0)" )

    if( get_pcvar_num( cvar_endOnRound_msg ) )
    {
        set_task( 1.0, "show_last_round_HUD", TASKID_SHOW_LAST_ROUND_HUD, _, _, "b" );
    }
}

public show_last_round_HUD()
{
    LOGGER( 0, "I AM ENTERING ON show_last_round_HUD(0)" )

    set_hudmessage( 255, 255, 255, 0.15, 0.15, 0, 0.0, 1.0, 0.1, 0.1, 1 );
    static last_round_message[ MAX_COLOR_MESSAGE ];

#if AMXX_VERSION_NUM < 183
    new    player_id;
    new    playerIndex;
    new    playersCount;
    static players[ MAX_PLAYERS ];
#endif

    last_round_message[ 0 ] = '^0';

    if( g_isTheLastGameRound )
    {
        // This is because the Amx Mod X 1.8.2 is not recognizing the player LANG_PLAYER when it is
        // formatted before with formatex(...)
    #if AMXX_VERSION_NUM < 183
        get_players( players, playersCount, "ch" );

        for( playerIndex = 0; playerIndex < playersCount; playerIndex++ )
        {
            player_id = players[ playerIndex ];

            formatex( last_round_message, charsmax( last_round_message ), "%L ^n%L",
                    player_id, "GAL_CHANGE_NEXTROUND",  player_id, "GAL_NEXTMAP", g_nextMapName );

            REMOVE_CODE_COLOR_TAGS( last_round_message )
            show_hudmessage( player_id, last_round_message );
        }
    #else
        formatex( last_round_message, charsmax( last_round_message ), "%L ^n%L",
                LANG_PLAYER, "GAL_CHANGE_NEXTROUND",  LANG_PLAYER, "GAL_NEXTMAP", g_nextMapName );

        REMOVE_CODE_COLOR_TAGS( last_round_message )
        show_hudmessage( 0, last_round_message );
    #endif
    }
    else // if( g_isThePenultGameRound ) // Here `g_isThePenultGameRound` will always be true
    {
    #if AMXX_VERSION_NUM < 183
        get_players( players, playersCount, "ch" );

        for( playerIndex = 0; playerIndex < playersCount; playerIndex++ )
        {
            player_id = players[ playerIndex ];
            formatex( last_round_message, charsmax( last_round_message ), "%L", player_id, "GAL_CHANGE_TIMEEXPIRED" );

            REMOVE_CODE_COLOR_TAGS( last_round_message )
            show_hudmessage( player_id, last_round_message );
        }
    #else
        formatex( last_round_message, charsmax( last_round_message ), "%L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED" );

        REMOVE_CODE_COLOR_TAGS( last_round_message )
        show_hudmessage( 0, last_round_message );
    #endif
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

    g_isTheLastGameRound       = false;
    g_isTimeToRestart          = false;
    g_isThePenultGameRound     = false;
    g_isToChangeMapOnVotingEnd = false;

    remove_task( TASKID_SHOW_LAST_ROUND_HUD );
    client_cmd( 0, "-showscores" );
}

stock saveRoundEnding( bool:roundEndStatus[] )
{
    LOGGER( 128, "I AM ENTERING ON saveRoundEnding(1) | roundEndStatus: %d, %d, %d, %d", \
            roundEndStatus[ 0 ], roundEndStatus[ 1 ], roundEndStatus[ 2 ], roundEndStatus[ 3 ] )

    roundEndStatus[ 0 ] = g_isTheLastGameRound;
    roundEndStatus[ 1 ] = g_isTimeToRestart;
    roundEndStatus[ 2 ] = g_isThePenultGameRound;
    roundEndStatus[ 3 ] = g_isToChangeMapOnVotingEnd;
}

stock restoreRoundEnding( bool:roundEndStatus[] )
{
    LOGGER( 128, "I AM ENTERING ON restoreRoundEnding(1) | roundEndStatus: %d, %d, %d, %d", \
            roundEndStatus[ 0 ], roundEndStatus[ 1 ], roundEndStatus[ 2 ], roundEndStatus[ 3 ] )

    g_isTheLastGameRound       = roundEndStatus[ 0 ];
    g_isTimeToRestart          = roundEndStatus[ 1 ];
    g_isThePenultGameRound     = roundEndStatus[ 2 ];
    g_isToChangeMapOnVotingEnd = roundEndStatus[ 3 ];
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
                set_pcvar_num( %2, serverCvarValue ); \
            } \
        } \
    } \
}

public resetRoundsScores()
{
    LOGGER( 128 + 2, "I AM ENTERING ON resetRoundsScores(0)" )
    LOGGER( 2, "( resetRoundsScores ) TRYING to change the cvar %15s to '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOGGER( 2, "( resetRoundsScores ) TRYING to change the cvar %15s to '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOGGER( 2, "( resetRoundsScores ) TRYING to change the cvar %15s to '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOGGER( 2, "( resetRoundsScores ) TRYING to change the cvar %15s to '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )

    new serverLimiterValue;

    CALCULATE_NEW_GAME_LIMIT( cvar_serverTimeLimitRestart, cvar_mp_timelimit, map_getMinutesElapsedInteger() )
    CALCULATE_NEW_GAME_LIMIT( cvar_serverWinlimitRestart, cvar_mp_winlimit, max( g_totalTerroristsWins, g_totalCtWins ) )
    CALCULATE_NEW_GAME_LIMIT( cvar_serverMaxroundsRestart, cvar_mp_maxrounds, g_totalRoundsPlayed )
    CALCULATE_NEW_GAME_LIMIT( cvar_serverFraglimitRestart, cvar_mp_fraglimit, g_greatestKillerFrags )

    // Reset the plugin internal limiter counters.
    g_totalTerroristsWins = 0;
    g_totalCtWins         = 0;
    g_totalRoundsPlayed   = -1;
    g_greatestKillerFrags = 0;

    LOGGER( 2, "( resetRoundsScores ) CHECKOUT the cvar %-23s is '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOGGER( 2, "( resetRoundsScores ) CHECKOUT the cvar %-23s is '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOGGER( 2, "( resetRoundsScores ) CHECKOUT the cvar %-23s is '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOGGER( 2, "( resetRoundsScores ) CHECKOUT the cvar %-23s is '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )
    LOGGER( 1, "    I AM EXITING ON resetRoundsScores(0)" )
}

stock map_populateList( Array:mapArray = Invalid_Array, mapFilePath[], mapFilePathLength, Trie:fillerMapTrie = Invalid_Trie )
{
    LOGGER( 128, "I AM ENTERING ON map_populateList(4) | mapFilePath: %s", mapFilePath )

    // load the array with maps
    new mapCount;

    // clear the map array in case we're reusing it
    TRY_TO_APPLY( ArrayClear, mapArray )
    TRY_TO_APPLY( TrieClear, fillerMapTrie )

    if( !equal( mapFilePath, "*" )
        && !equal( mapFilePath, "#" ) )
    {
        LOGGER( 4, "" )
        LOGGER( 4, "    map_populateList(...) Loading the PASSED FILE! mapFilePath: %s", mapFilePath )
        mapCount = loadMapFileList( mapArray, mapFilePath, fillerMapTrie );
    }
    else if( equal( mapFilePath, "*" ) )
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

    LOGGER( 1, "    I AM EXITING map_populateList(4) mapCount: %d", mapCount )
    return mapCount;
}

stock loadMapFileList( Array:mapArray, mapFilePath[], Trie:fillerMapTrie )
{
    LOGGER( 128, "I AM ENTERING ON loadMapFileList(3) | mapFilePath: %s", mapFilePath )

    new mapCount;
    new mapFileDescriptor = fopen( mapFilePath, "rt" );

    if( mapFileDescriptor )
    {
        new loadedMapName[ MAX_MAPNAME_LENGHT ];

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

        if( mapCount < 2 )
        {
            new parsedLines;
            new writePosition;
            new readLines[ MAX_BIG_BOSS_STRING ];

            fseek( mapFileDescriptor, SEEK_SET, 0 );

            while( !feof( mapFileDescriptor )
                   && parsedLines < 11 )
            {
                parsedLines++;
                fgets( mapFileDescriptor, loadedMapName, charsmax( loadedMapName ) );

                if( writePosition < charsmax( readLines ) )
                {
                    writePosition += copy( readLines[ writePosition ], charsmax( readLines ) - writePosition, loadedMapName );
                }
            }

            LOGGER( 1, "( loadMapFileList ) Error %d, Not valid/enough(%d) maps found: %s^n", AMX_ERR_NOTFOUND, mapCount, readLines )
            log_error( AMX_ERR_NOTFOUND, "Not valid/enough(%d) maps found: %s^n", mapCount, readLines );
        }

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

/**
 * When the debug mode `DEBUG_LEVEL` is enabled, the map_populateList(4) will show up to this maps
 * loaded from the server.
 */
#define MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST 10

stock loadMapFileListComplete( mapFileDescriptor, Array:mapArray, Trie:fillerMapTrie )
{
    LOGGER( 128, "I AM ENTERING ON loadMapsFolderDirectoryComplete(3) | mapFileDescriptor: %d", mapFileDescriptor )

    new mapCount;
    new loadedMapName[ MAX_MAPNAME_LENGHT ];

    while( !feof( mapFileDescriptor ) )
    {
        fgets( mapFileDescriptor, loadedMapName, charsmax( loadedMapName ) );
        trim( loadedMapName );

        if( IS_IT_A_VALID_MAP_LINE( loadedMapName ) )
        {
            TrieSetCell( fillerMapTrie, loadedMapName, mapCount );
            ArrayPushString( mapArray, loadedMapName );

        #if defined DEBUG
            if( mapCount < MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST )
            {
                LOGGER( 4, "( loadMapFileList ) %d, loadedMapName: %s", mapCount + 1, loadedMapName )
            }
        #endif

            ++mapCount;
        }
    }

    return mapCount;
}

stock loadMapFileListArray( mapFileDescriptor, Array:mapArray )
{
    LOGGER( 128, "I AM ENTERING ON loadMapsFolderDirectoryComplete(3) | mapFileDescriptor: %d", mapFileDescriptor )

    new mapCount;
    new loadedMapName[ MAX_MAPNAME_LENGHT ];

    while( !feof( mapFileDescriptor ) )
    {
        fgets( mapFileDescriptor, loadedMapName, charsmax( loadedMapName ) );
        trim( loadedMapName );

        if( IS_IT_A_VALID_MAP_LINE( loadedMapName ) )
        {
            ArrayPushString( mapArray, loadedMapName );

        #if defined DEBUG
            if( mapCount < MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST )
            {
                LOGGER( 4, "( loadMapFileList ) %d, loadedMapName: %s", mapCount + 1, loadedMapName )
            }
        #endif

            ++mapCount;
        }
    }

    return mapCount;
}

stock loadMapFileListTrie( mapFileDescriptor, Trie:fillerMapTrie )
{
    LOGGER( 128, "I AM ENTERING ON loadMapsFolderDirectoryComplete(3) | mapFileDescriptor: %d", mapFileDescriptor )

    new mapCount;
    new loadedMapName[ MAX_MAPNAME_LENGHT ];

    while( !feof( mapFileDescriptor ) )
    {
        fgets( mapFileDescriptor, loadedMapName, charsmax( loadedMapName ) );
        trim( loadedMapName );

        if( IS_IT_A_VALID_MAP_LINE( loadedMapName ) )
        {
            TrieSetCell( fillerMapTrie, loadedMapName, mapCount );

        #if defined DEBUG
            if( mapCount < MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST )
            {
                LOGGER( 4, "( loadMapFileList ) %d, loadedMapName: %s", mapCount + 1, loadedMapName )
            }
        #endif

            ++mapCount;
        }
    }

    return mapCount;
}

stock loadMapsFolderDirectory( Array:mapArray, Trie:fillerMapTrie )
{
    LOGGER( 128, "I AM ENTERING ON loadMapsFolderDirectory(2) | Array:mapArray: %d", mapArray )

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
    LOGGER( 128, "I AM ENTERING ON loadMapsFolderDirectoryComplete(3) | directoryDescriptor: %d", directoryDescriptor )

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

            #if defined DEBUG
                if( mapCount < MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST )
                {
                    LOGGER( 4, "( loadMapsFolderDirectory ) %d, loadedMapName: %s", mapCount + 1, loadedMapName )
                }
            #endif

                ++mapCount;
            }
        }
    }

    return mapCount;
}

stock loadMapsFolderDirectoryArray( directoryDescriptor, Array:mapArray )
{
    LOGGER( 128, "I AM ENTERING ON loadMapsFolderDirectoryArray(2) | directoryDescriptor: %d", directoryDescriptor )

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

            #if defined DEBUG
                if( mapCount < MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST )
                {
                    LOGGER( 4, "( loadMapsFolderDirectory ) %d, loadedMapName: %s", mapCount + 1, loadedMapName )
                }
            #endif

                ++mapCount;
            }
        }
    }

    return mapCount;
}

stock loadMapsFolderDirectoryTrie( directoryDescriptor, Trie:fillerMapTrie )
{
    LOGGER( 128, "I AM ENTERING ON loadMapsFolderDirectoryTrie(2) | directoryDescriptor: %d", directoryDescriptor )

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

            #if defined DEBUG
                if( mapCount < MAX_MAPS_TO_SHOW_ON_MAP_POPULATE_LIST )
                {
                    LOGGER( 4, "( loadMapsFolderDirectory ) %d, loadedMapName: %s", mapCount + 1, loadedMapName )
                }
            #endif

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

stock isToLoadTheNextWhiteListGroup( &isToLoadTheseMaps, currentHour, startHour, endHour, isWhiteList = false )
{
    LOGGER( 0, "I AM ENTERING ON isToLoadTheNextWhiteListGroup(5) | startHour: %d, endHour: %d", startHour, endHour )

    if( startHour == endHour
        && endHour == currentHour )
    {
        LOGGER( 8, "( isToLoadTheNextWhiteListGroup ) startHour == endHour: %d", startHour )

        // Manual fix needed to convert 5-5 to 05:00:00 until 05:59:59, instead of all day long.
    #if IS_TO_USE_BLACKLIST_INSTEAD_OF_WHITELIST > 0
        isToLoadTheseMaps = isWhiteList;
    #else
        isToLoadTheseMaps = !isWhiteList;
    #endif
    }
    //           5          3
    else if( startHour > endHour )
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
            LOGGER( 0, "( isToLoadTheNextWhiteListGroup ) startHour > endHour && ( currentHour < startHour && currentHour > endHour )" )
            isToLoadTheseMaps = !isWhiteList;
        }
        //               6           5
        else // if( currentHour > startHour )
        {
            LOGGER( 0, "( isToLoadTheNextWhiteListGroup ) startHour > endHour && ( currentHour > startHour || currentHour < endHour )" )
            isToLoadTheseMaps = isWhiteList;
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
            LOGGER( 0, "( isToLoadTheNextWhiteListGroup ) startHour < endHour && ( currentHour > endHour || currentHour < startHour )" )
            isToLoadTheseMaps = !isWhiteList;
        }
        //              4            3
        else // if( currentHour > startHour )
        {
            LOGGER( 0, "( isToLoadTheNextWhiteListGroup ) startHour < endHour && ( currentHour < endHour || currentHour > startHour )" )
            isToLoadTheseMaps = isWhiteList;
        }
    }

    LOGGER( 8, "( isToLoadTheNextWhiteListGroup ) %2d >  %2d     : %2d", startHour, endHour, startHour > endHour )
    LOGGER( 8, "( isToLoadTheNextWhiteListGroup ) %2d >= %2d > %2d: %2d", \
            startHour, currentHour, endHour, \
            startHour >= currentHour && currentHour > endHour )

    LOGGER( 8, "( isToLoadTheNextWhiteListGroup ) %2d <  %2d     : %2d", startHour, endHour, startHour < endHour )
    LOGGER( 8, "( isToLoadTheNextWhiteListGroup ) %2d <= %2d < %2d: %2d, isToLoadTheseMaps: %d", \
            startHour, currentHour, endHour, \
            startHour <= currentHour && currentHour < endHour, isToLoadTheseMaps )
}

/**
 * Standardize the hours from 0 until 23.
 */
stock standardizeTheHoursForWhitelist( &currentHour, &startHour, &endHour )
{
    LOGGER( 0, "I AM ENTERING ON standardizeTheHoursForWhitelist(3) | currentHour: %d, startHour: %d, endHour: %d", \
            currentHour, startHour, endHour )

    if( startHour > 23
        || startHour < 0 )
    {
        LOGGER( 8, "( isToLoadTheNextWhiteListGroup ) startHour: %d, will became 0.", startHour )
        startHour = 0;
    }

    if( endHour > 23
        || endHour < 0 )
    {
        LOGGER( 8, "( isToLoadTheNextWhiteListGroup ) endHour: %d, will became 0.", endHour )
        endHour = 0;
    }

    if( currentHour > 23
        || currentHour < 0 )
    {
        LOGGER( 8, "( isToLoadTheNextWhiteListGroup ) currentHour: %d, will became 0.", currentHour )
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
stock convertWhitelistToBlacklist( &startHour, &endHour )
{
    LOGGER( 0, "I AM ENTERING ON convertWhitelistToBlacklist(2) | startHour: %d, endHour: %d", startHour, endHour )
    new backup;

    backup    = ( endHour + 1 > 23? 0 : endHour + 1 );
    endHour   = ( startHour - 1 < 0? 23 : startHour - 1 );
    startHour = backup;
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
        if( !g_whitelistTrie )
        {
            loadTheWhiteListFeature();
        }
    }
    else
    {
        if( !g_blackListForWhiteListTrie )
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

    if( get_pcvar_num( cvar_isWhiteListBlockOut ) )
    {
        loadWhiteListFile( currentHour, g_whitelistTrie, g_whitelistFileArray, true, g_whitelistArray );
    }
    else
    {
        loadWhiteListFile( currentHour, g_blackListForWhiteListTrie, g_whitelistFileArray );
    }
}

stock loadWhiteListFile( currentHour, &Trie:listTrie, Array:whitelistFileArray, bool:isWhiteList = false, &Array:listArray = Invalid_Array )
{
    LOGGER( 128, "I AM ENTERING ON loadWhiteListFile(5) | currentHour: %d, listTrie: %d", currentHour, listTrie )

    if( whitelistFileArray )
    {
        new startHour;
        new endHour;

        new linesCount;
        new bool:isToLoadTheseMaps;

        new currentLine    [ MAX_MAPNAME_LENGHT ];
        new startHourString[ MAX_MAPNAME_LENGHT / 2 ];
        new endHourString  [ MAX_MAPNAME_LENGHT / 2 ];

        setupLoadWhiteListParams( isWhiteList, listTrie, listArray );
        linesCount = ArraySize( whitelistFileArray );

        for( new lineIndex = 0; lineIndex < linesCount; lineIndex++ )
        {
            ArrayGetString( whitelistFileArray, lineIndex, currentLine, charsmax( currentLine ) );

            if( currentLine[ 0 ] == '['
                && isdigit( currentLine[ 1 ] ) )
            {
                // remove line delimiters [ and ]
                replace_all( currentLine, charsmax( currentLine ), "[", "" );
                replace_all( currentLine, charsmax( currentLine ), "]", "" );

                // Invert it to change the 'If we are %s these hours...' LOGGER(...) message accordantly.
            #if IS_TO_USE_BLACKLIST_INSTEAD_OF_WHITELIST > 0
                isWhiteList = !isWhiteList;
            #endif

                LOGGER( 8, "( loadWhiteListFile ) " )
                LOGGER( 8, "( loadWhiteListFile ) If we are %s these hours, we must load these maps:", \
                        ( isWhiteList? "between" : "outside" ) )
                LOGGER( 8, "( loadWhiteListFile ) currentLine: %s (currentHour: %d)", currentLine, currentHour )

                // broke the current line
                strtok( currentLine,
                        startHourString, charsmax( startHourString ),
                        endHourString, charsmax( endHourString ),
                        '-', 0 );

                startHour = str_to_num( startHourString );
                endHour   = str_to_num( endHourString );

                standardizeTheHoursForWhitelist( currentHour, startHour, endHour );

                // Revert the variable 'isWhiteList' change and calculates whether to load the Blacklist/Whitelist or not.
            #if IS_TO_USE_BLACKLIST_INSTEAD_OF_WHITELIST > 0
                isWhiteList = !isWhiteList;
                convertWhitelistToBlacklist( startHour, endHour );
            #endif
                isToLoadTheNextWhiteListGroup( isToLoadTheseMaps, currentHour, startHour, endHour, isWhiteList );
                continue;
            }
            else if( !isToLoadTheseMaps )
            {
                continue;
            }
            else
            {
                LOGGER( 8, "( loadWhiteListFile ) Trying to add: %s", currentLine )

                if( IS_MAP_VALID( currentLine ) )
                {
                    LOGGER( 8, "( loadWhiteListFile ) OK!")
                    TrieSetCell( listTrie, currentLine, 0 );

                    if( isWhiteList )
                    {
                        ArrayPushString( listArray, currentLine );
                    }
                }
            }
        }
    }

    LOGGER( 1, "    I AM EXITING loadWhiteListFile(5) | listArray: %d, whitelistFileArray: %d", listArray, whitelistFileArray )
}

stock setupLoadWhiteListParams( bool:isWhiteList, &Trie:listTrie, &Array:listArray )
{
    LOGGER( 128, "I AM ENTERING ON setupLoadWhiteListParams(3) | isWhiteList: %d", isWhiteList )

    if( listTrie )
    {
        TrieClear( listTrie );
    }
    else
    {
        listTrie = TrieCreate();
    }

    if( isWhiteList )
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

    if( get_realplayersnum() < get_pcvar_num( cvar_voteMinPlayers ) )
    {
        return fillersFilePaths_MininumPlayers;
    }

    return fillersFilePaths_NormalPlayers;
}

stock processLoadedMapsFile( fillersFilePathType:fillersFilePathEnum, blockedMapsBuffer[], &announcementShowedTimes )
{
    LOGGER( 128, "I AM ENTERING ON processLoadedMapsFile(3) | fillersFilePathEnum: %d, announcementShowedTimes: %d", \
            fillersFilePathEnum, announcementShowedTimes )

    new groupCount;
    new choiceIndex;
    new allowedFilersCount;
    new maxMapsPerGroupToUse;

    new Array:fillerMapsArray;
    new Array:fillerMapGroupsArrays;
    new Array:maxMapsPerGroupToUseArray;
    new mapName[ MAX_MAPNAME_LENGHT ];

    switch( fillersFilePathEnum )
    {
        case fillersFilePaths_MininumPlayers:
        {
            fillerMapGroupsArrays     = g_minPlayerFillerMapGroupArrays;
            maxMapsPerGroupToUseArray = g_minMaxMapsPerGroupToUseArray;
        }
        case fillersFilePaths_NormalPlayers:
        {
            fillerMapGroupsArrays     = g_norPlayerFillerMapGroupArrays;
            maxMapsPerGroupToUseArray = g_norMaxMapsPerGroupToUseArray;
        }
    }

    new mapIndex;
    new filersMapCount;
    new unsuccessfulCount;
    new currentBlockerStrategy;

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

    new maxVotingChoices = g_isMapExtensionAllowed ?
            ( g_maxVotingChoices >= MAX_OPTIONS_IN_VOTE ? g_maxVotingChoices - 1 : g_maxVotingChoices ) : g_maxVotingChoices;

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
                ArrayGetString( fillerMapsArray, mapIndex, mapName, charsmax( mapName ) );

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

                    if( ++mapIndex >= filersMapCount )
                    {
                        mapIndex = 0;
                    }

                    unsuccessfulCount++;
                    ArrayGetString( fillerMapsArray, mapIndex, mapName, charsmax( mapName ) );

                    LOGGER( 0, "", debug_vote_map_selection( choiceIndex, mapName, useWhitelistOutBlock, \
                            isWhiteListOutBlock, useEqualiCurrentMap, unsuccessfulCount, currentBlockerStrategy, \
                            useIsPrefixInMenu, useMapIsTooRecent, blockedFillersMapTrie ) )
                }

                if( isWhitelistEnabled
                    && !isWhiteListOutBlock
                    && TrieKeyExists( g_blackListForWhiteListTrie, mapName ) )
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

                copy( g_votingMapNames[ g_totalVoteOptions ], charsmax( g_votingMapNames[] ), mapName );
                g_totalVoteOptions++;

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
    LOGGER( 0, "I AM ENTERING ON debug_vote_map_selection(10) | choiceIndex: %d", choiceIndex )
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
            ( useWhitelistOutBlock? TrieKeyExists( blockedFillersMapTrie, mapName ) : false ), \
            ( isWhiteListOutBlock? !TrieKeyExists( g_whitelistTrie, mapName ) : false ) )

    LOGGER( 8, "          useMapIsTooRecent: %d, useIsPrefixInMenu: %d, useEqualiCurrentMap: %d", \
            useMapIsTooRecent, useIsPrefixInMenu, useEqualiCurrentMap )

    LOGGER( 8, "          currentBlockerStrategy: %d, unsuccessfulCount:%d, useWhitelistOutBlock: %d", \
            currentBlockerStrategy, unsuccessfulCount, useWhitelistOutBlock )

    return 0;
}

stock vote_addFillers( blockedMapsBuffer[], &announcementShowedTimes = 0 )
{
    LOGGER( 128, "I AM ENTERING ON vote_addFillers(2) | announcementShowedTimes: %d", announcementShowedTimes )

    new maxVotingChoices = g_isMapExtensionAllowed ?
            ( g_maxVotingChoices >= MAX_OPTIONS_IN_VOTE ? g_maxVotingChoices - 1 : g_maxVotingChoices ) : g_maxVotingChoices;

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
    LOGGER( 128, "I AM ENTERING ON vote_addNominations(2) | announcementShowedTimes: %d", announcementShowedTimes )
    new bool:isFillersMapUsingMinplayers;

    // Try to add the nominations, if there are nominated maps.
    new nominatedMapsCount = ArraySize( g_nominatedMapsArray );

    if( nominatedMapsCount )
    {
        new Trie:whitelistMapTrie;

        new mapIndex;
        new mapName[ MAX_MAPNAME_LENGHT ];

        // Note: The Map Groups Feature will not work with the Minimum Players Feature when adding
        // nominations, as we do not load the Map Groups Feature. But the Map Groups Feature will
        // work fine with the Minimum Players Feature when filling the vote menu.
        if( IS_NOMINATION_MININUM_PLAYERS_CONTROL_ENABLED() )
        {
            new mapFilerFilePath[ MAX_FILE_PATH_LENGHT ];
            get_pcvar_string( cvar_voteMinPlayersMapFilePath, mapFilerFilePath, charsmax( mapFilerFilePath ) );

            // '*' is and invalid blacklist for voting, because it would block all server maps.
            if( equal( mapFilerFilePath, "*" ) )
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

        new maxVotingChoices = g_isMapExtensionAllowed ?
                ( g_maxVotingChoices >= MAX_OPTIONS_IN_VOTE ? g_maxVotingChoices - 1 : g_maxVotingChoices ) : g_maxVotingChoices;

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
                ArrayGetString( g_nominationLoadedMapsArray, mapIndex, mapName, charsmax( mapName ) );
                LOGGER( 4, "( vote_addNominations ) g_nominationLoadedMapsArray.mapIndex: %d, mapName: %s", mapIndex, mapName )

                if( isFillersMapUsingMinplayers
                    && !TrieKeyExists( whitelistMapTrie, mapName ) )
                {
                    LOGGER( 8, "    The map: %s, was blocked by the minimum players map setting.", mapName )
                    announceVoteBlockedMap( mapName, blockedMapsBuffer, "GAL_FILLER_BLOCKED", announcementShowedTimes );

                    continue;
                }

                copy( g_votingMapNames[ g_totalVoteOptions ], charsmax( g_votingMapNames[] ), mapName );
                g_totalVoteOptions++;

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

stock loadNormalVoteChoices()
{
    LOGGER( 128, "I AM ENTERING ON loadNormalVoteChoices(0)" )

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

    g_voteDuration = get_pcvar_num( cvar_voteDuration );

    LOGGER( 4, "" )
    LOGGER( 4, "I AM EXITING ON loadNormalVoteChoices(0) | g_totalVoteOptions: %d", g_totalVoteOptions )
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
    LOGGER( 128, "I AM ENTERING ON announceVoteBlockedMap(4) | announcementShowedTimes: %d, \
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
    LOGGER( 128, "I AM ENTERING ON flushVoteBlockedMaps(3) | announcementShowedTimes: %d, ", announcementShowedTimes )
    LOGGER( 128, "blockedMapsBuffer: %s",  blockedMapsBuffer )

    if( blockedMapsBuffer[ 0 ] )
    {
        if( announcementShowedTimes == 1 )
        {
            color_print( 0, "%L", LANG_PLAYER, flushAnnouncement, 0, 0 );
        }

    #if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES == 0
        REMOVE_CODE_COLOR_TAGS( blockedMapsBuffer )
    #endif
        color_print( 0, "%L", LANG_PLAYER, "GAL_MATCHING", blockedMapsBuffer[ 3 ] );

        announcementShowedTimes++;
        blockedMapsBuffer[ 0 ] = '^0';
    }
}

stock computeNextWhiteListLoadTime( seconds, bool:isSecondsLeft = true )
{
    LOGGER( 128, "I AM ENTERING ON computeNextWhiteListLoadTime(2) | seconds: %d, isSecondsLeft: %d", seconds, isSecondsLeft )
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

    LOGGER( 1, "I AM EXITING computeNextWhiteListLoadTime(2) | g_whitelistNomBlockTime: %d, secondsForReload: %d", g_whitelistNomBlockTime, secondsForReload )
}

public start_voting_by_rounds()
{
    LOGGER( 128, "I AM ENTERING ON start_voting_by_rounds(0) | get_pcvar_num( cvar_endOfMapVote ): %d", \
            get_pcvar_num( cvar_endOfMapVote ) )

    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_isVotingByRounds = true;
        vote_startDirector( false );
    }
}

public start_voting_by_timer()
{
    LOGGER( 128, "I AM ENTERING ON start_voting_by_timer(0) | get_pcvar_num( cvar_endOfMapVote ): %d", \
            get_pcvar_num( cvar_endOfMapVote ) )

    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_isVotingByTimer = true;
        vote_startDirector( false );
    }
}

public startVotingByGameEngineCall()
{
    LOGGER( 128, "I AM ENTERING ON startVotingByGameEngineCall(0) | get_pcvar_num( cvar_endOfMapVote ): %d", \
            get_pcvar_num( cvar_endOfMapVote ) )

    if( get_pcvar_num( cvar_endOfMapVote ) )
    {
        g_isToChangeMapOnVotingEnd = true;
        vote_startDirector( false );
    }
}

public vote_manageEnd()
{
    LOGGER( 0, "I AM ENTERING ON vote_manageEnd(0) | get_realplayersnum: %d", get_realplayersnum() )
    new secondsLeft = get_timeleft();

    if( secondsLeft )
    {
        // are we ready to start an "end of map" vote?
        if( IS_TIME_TO_START_THE_END_OF_MAP_VOTING( secondsLeft ) )
        {
            start_voting_by_timer();
        }

        // are we managing the end of the map?
        if( secondsLeft < 30
            && secondsLeft > 0 )
        {
            // try_to_manage_map_end() cannot be called with true, otherwise it will change the map
            // before the last seconds to be finished.
            try_to_manage_map_end();
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
    LOGGER( 0, "I AM ENTERING ON handle_game_crash_recreation(1) | secondsLeft: %d", secondsLeft )

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

stock approvedTheVotingStart( bool:is_forced_voting )
{
    LOGGER( 128, "I AM ENTERING ON approvedTheVotingStart(1) | is_forced_voting: %d, get_realplayersnum: %d", \
            is_forced_voting, get_realplayersnum() )

    if( get_pcvar_num( cvar_nextMapChangeVotemap )
        && get_pcvar_num( cvar_nextMapChangeAnnounce )
        && !is_forced_voting )
    {
        new nextMapFlag[ 128 ];
        new nextMapName[ MAX_MAPNAME_LENGHT ];

        formatex( nextMapFlag, charsmax( nextMapFlag ), "%L", LANG_SERVER, "GAL_NEXTMAP_UNKNOWN" );
        REMOVE_CODE_COLOR_TAGS( nextMapFlag )

        get_pcvar_string( cvar_amx_nextmap, nextMapName, charsmax( nextMapName ) );

        if( !equali( nextMapFlag, nextMapName, strlen( nextMapName ) ) )
        {
            LOGGER( 1, "    ( approvedTheVotingStart ) Returning false due the `gal_nextmap_votemap` feature." )
            return false;
        }
    }

    // block the voting on some not allowed situations/cases
    if( get_realplayersnum() == 0
        || ( g_voteStatus & VOTE_IS_IN_PROGRESS
             && !( g_voteStatus & VOTE_IS_RUNOFF ) )
        || ( !is_forced_voting
             && g_voteStatus & VOTE_IS_OVER ) )
    {
        LOGGER( 1, "    ( approvedTheVotingStart ) g_voteStatus: %d, g_voteStatus & VOTE_IS_OVER: %d", \
                g_voteStatus, g_voteStatus & VOTE_IS_OVER != 0 )

    #if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED )
        if( g_test_isTheUnitTestsRunning )
        {
            LOGGER( 1, "    ( approvedTheVotingStart ) Returning true on the if !g_test_isTheUnitTestsRunning, \
                    cvar_isEmptyCycleByMapChange: %d.", get_pcvar_num( cvar_isEmptyCycleByMapChange ) )
            return true;
        }
    #endif

        if( get_realplayersnum() == 0 )
        {
            if( get_pcvar_num( cvar_isEmptyCycleByMapChange ) )
            {
                startEmptyCycleSystem();
            }

            if( g_voteStatus & VOTE_IS_IN_PROGRESS )
            {
                cancelVoting();
            }
        }

        LOGGER( 1, "    ( approvedTheVotingStart ) Returning false on the big blocker." )
        return false;
    }

    // allow a new forced voting while the map is ending
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

    // If the voting menu deletion task is running, remove it the delete the menus right now.
    if( remove_task( TASKID_DELETE_USERS_MENUS ) )
    {
        vote_resetStats();
    }

    LOGGER( 1, "    ( approvedTheVotingStart ) Returning true, due passed by all requirements." )
    return true;
}

stock printVotingMaps( votingMapsCount )
{
    LOGGER( 128, "I AM ENTERING ON printVotingMaps(1) votingMapsCount: %d", votingMapsCount )

    for( new index = 0; index < votingMapsCount; index++ )
    {
        LOGGER( 16, "( printVotingMaps ) Voting map %d: %s", index, g_votingMapNames[ index ] )
    }

    return 0;
}

stock loadRunOffVoteChoices()
{
    LOGGER( 128, "I AM ENTERING ON loadRunOffVoteChoices(0)" )
    new runoffChoice[ MAX_OPTIONS_IN_VOTE ][ MAX_MAPNAME_LENGHT ];

    // Create a clean copy to not copy overridden maps
    for( new mapIndex = 0; mapIndex < g_totalVoteOptions; mapIndex++ )
    {
        copy( runoffChoice[ mapIndex ], charsmax( runoffChoice[] ), g_votingMapNames[ g_arrayOfRunOffChoices[ mapIndex ] ] );
    }

    // Load runoff choices
    for( new mapIndex = 0; mapIndex < g_totalVoteOptions; mapIndex++ )
    {
        copy( g_votingMapNames[ mapIndex ], charsmax( g_votingMapNames[] ), runoffChoice[ mapIndex ] );
    }

    g_voteDuration = get_pcvar_num( cvar_runoffDuration );
    LOGGER( 0, "", printVotingMaps( g_totalVoteOptions ) )
}

stock configureVotingStart( bool:is_forced_voting )
{
    LOGGER( 128, "I AM ENTERING ON configureVotingStart(1) | is_forced_voting: %d", is_forced_voting )

    // update cached data for the new voting
    cacheCvarsValues();

    // make it known that a vote is in progress
    g_voteStatus |= VOTE_IS_IN_PROGRESS;

    // Set the voting status to forced
    if( is_forced_voting )
    {
        g_voteStatus |= VOTE_IS_FORCED;
    }

    // Max rounds/frags vote map does not have a max rounds extension limit as mp_timelimit
    if( g_isVotingByRounds
        || g_isVotingByFrags )
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
                              || g_isVotingByTimer
                              || g_isVotingByFrags )
                            && !is_forced_voting );

    // stop RTV reminders
    remove_task( TASKID_RTV_REMINDER );
}

stock vote_startDirector( bool:is_forced_voting )
{
    LOGGER( 128, "I AM ENTERING ON vote_startDirector(1) | is_forced_voting: %d", is_forced_voting )

    if( !approvedTheVotingStart( is_forced_voting ) )
    {
        LOGGER( 1, "    ( vote_startDirector ) Just Returning/blocking, the voting was not approved." )
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
        color_print( 0, "%L", LANG_PLAYER, "GAL_VOTE_NOMAPS" );
        finalizeVoting();
    }

    LOGGER( 4, "" )
    LOGGER( 4, "    ( vote_startDirector|out ) g_isTheLastGameRound: %d", g_isTheLastGameRound )
    LOGGER( 4, "    ( vote_startDirector|out ) g_isTimeToRestart: %d, g_voteStatus & VOTE_IS_FORCED: %d", \
            g_isTimeToRestart, g_voteStatus & VOTE_IS_FORCED != 0 )
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
    SortCustom2D( g_votingMapNames, g_totalVoteOptions, "sort_stringsi" );

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

    // Set_task 1.0 + pendingVoteCountdown 1.0
    handleChoicesDelay = 7.0 + 1.0 + 1.0;

    // Make perfunctory announcement: "get ready to choose a map"
    if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_GETREADYTOCHOOSE ) )
    {
        client_cmd( 0, "spk ^"get red( e80 ) ninety( s45 ) to check( e20 ) \
                use bay( s18 ) mass( e42 ) cap( s50 )^"" );
    }

    // Announce the pending vote countdown from 7 to 1
    g_pendingVoteCountdown = 7;
    set_task( 1.0, "pendingVoteCountdown", TASKID_PENDING_VOTE_COUNTDOWN, _, _, "a", 7 );
#endif

    // Set debug options
    LOGGER( 0, "", configureVoteDisplayDebugging() )

    // Display the map choices, 1 second from now
    set_task( handleChoicesDelay, "vote_handleDisplay", TASKID_VOTE_HANDLEDISPLAY );
}

stock configureVoteDisplayDebugging()
{
    // Force a right vote duration for the Unit Tests run
#if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED )
    g_voteDuration = 5;
#endif

    // To create fake votes when needed
#if DEBUG_LEVEL & DEBUG_LEVEL_FAKE_VOTES
    set_task( 2.0, "create_fakeVotes", TASKID_DBG_FAKEVOTES );
#endif

    // Print the voting map options
#if defined DEBUG
    new voteOptions = ( g_totalVoteOptions == 1? 2 : g_totalVoteOptions );

    LOGGER( 4, "" )
    LOGGER( 4, "" )
    LOGGER( 4, "   [PLAYER CHOICES]" )

    for( new dbgChoice = 0; dbgChoice < voteOptions; dbgChoice++ )
    {
        LOGGER( 4, "      %i. %s", dbgChoice + 1, g_votingMapNames[ dbgChoice ] )
    }
#endif

    return 0;
}

public pendingVoteCountdown()
{
    LOGGER( 128, "I AM ENTERING ON pendingVoteCountdown(0)" )

    if( get_pcvar_num( cvar_isToAskForEndOfTheMapVote )
        && !( g_voteStatus & VOTE_IS_RUNOFF ) )
    {
        displayEndOfTheMapVoteMenu( 0 );
    }

    // visual countdown,
    // Add a new cvar as `gal_text_messages_mute` (gal_sounds_mute)
    // issue: https://github.com/evandrocoan/Galileo/issues/31
    // if( !( get_pcvar_num( cvar_textMessagesMute ) & VISUAL_COUNTDOWN ) )
    // {
    //     set_hudmessage( 0, 222, 50, -1.0, 0.13, 0, 1.0, 0.94, 0.0, 0.0, -1 );
    //     show_hudmessage( 0, "%L", LANG_PLAYER, "GAL_VOTE_COUNTDOWN", g_pendingVoteCountdown );
    // }

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
    LOGGER( 128, "I AM ENTERING ON displayEndOfTheMapVoteMenu(1) | player_id: %d", player_id )

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
        menu_body   [ 0 ] = '^0';
        menu_counter[ 0 ] = '^0';

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
            menuKeys = MENU_KEY_1;
        }

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

        LOGGER( 4, " ( displayEndOfTheMapVoteMenu| for ) menu_body: %s", menu_body )
        LOGGER( 4, "    menu_id:%d, menuKeys: %d, isVoting: %d, playerAnswered:%d, \
                player_id: %d, playerIndex: %d", menu_id, menuKeys, isVoting, playerAnswered, \
                player_id, playerIndex )

        LOGGER( 4, "    playersCount: %d, g_pendingVoteCountdown: %d, menu_counter: %s", \
                playersCount, g_pendingVoteCountdown, menu_counter )
    }

    LOGGER( 4, "%48s", " ( displayEndOfTheMapVoteMenu| out )" )
}

public handleEndOfTheMapVoteChoice( player_id, pressedKeyCode )
{
    LOGGER( 128, "I AM ENTERING ON handleEndOfTheMapVoteChoice(2) | player_id: %d, pressedKeyCode: %d", \
            player_id, pressedKeyCode )

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

            LOGGER( 1, "    ( handleEndOfTheMapVoteChoice ) Returning PLUGIN_HANDLED" )
            return PLUGIN_HANDLED;
        }
    }

    g_answeredForEndOfMapVote[ player_id ] = true;
    set_task( 0.1, "displayEndOfTheMapVoteMenu", player_id );

    LOGGER( 1, "    ( handleEndOfTheMapVoteChoice ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

public vote_handleDisplay()
{
    LOGGER( 128, "I AM ENTERING ON vote_handleDisplay(0)" )

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
    set_task( 0.9, "voteExpire" );

    set_task( 1.0, "vote_display", TASKID_VOTE_DISPLAY, argument, sizeof argument, "a", 3 );
    set_task( 5.5, "computeVotes", TASKID_VOTE_EXPIRE );
}

public voteExpire()
{
    LOGGER( 128, "I AM ENTERING ON voteExpire(0)" )
    g_voteStatus |= VOTE_IS_EXPIRED;
}

public sort_stringsi( const elem1[], const elem2[], const array[], data[], data_size )
{
    LOGGER( 128, "I AM ENTERING ON sort_stringsi(5) | elem1: %15s, elem2: %15s, array: %10s, data: %10s, \
            data_size: %3d",                          elem1,       elem2,       array,       data, \
            data_size )

    return strcmp( elem1, elem2, 1 );
}

public vote_display( argument[ 2 ] )
{
    LOGGER( 4, "I AM ENTERING ON vote_display(1) | updateTimeRemaining: %d, player_id: %d", argument[ 0 ], argument[ 1 ] )
    new menuKeys;

    static voteStatus  [ MAX_BIG_BOSS_STRING - 100 ];
    static menuClean   [ MAX_BIG_BOSS_STRING ]; // menu showed while voting
    static menuDirty   [ MAX_BIG_BOSS_STRING ]; // menu showed after voted
    static voteMapLine [ MAX_MAPNAME_LENGHT + 32 ];

    new player_id           = argument[ 1 ];
    new copiedChars         = 0;
    new updateTimeRemaining = argument[ 0 ];

    new bool:isVoteOver   = g_voteStatus & VOTE_IS_EXPIRED != 0;
    new bool:noneIsHidden = ( g_isToShowNoneOption
                              && !g_voteShowNoneOptionType
                              && !isVoteOver );

    if( updateTimeRemaining )
    {
        g_voteDuration--;
    }

    LOGGER( 4, "  ( votedisplay ) player_id: %i, updateTimeRemaining: %i", argument[ 1 ], argument[ 0 ]  )
    LOGGER( 4, "  ( votedisplay ) g_totalVoteOptions: %i, strlen( g_voteStatusClean ): %i", \
            g_totalVoteOptions, strlen( g_voteStatusClean )  )

    // wipe the previous vote status
    voteStatus[ 0 ] = '^0';

    // register the 'None' option key
    if( g_isToShowNoneOption
        && !isVoteOver )
    {
        menuKeys = MENU_KEY_0;
    }

    // add maps to the menu
    for( new choiceIndex = 0; choiceIndex < g_totalVoteOptions; ++choiceIndex )
    {
        computeVoteMapLine( voteMapLine, charsmax( voteMapLine ), choiceIndex );

        copiedChars += formatex( voteStatus[ copiedChars ], charsmax( voteStatus ) - copiedChars,
                "^n%s%i. %s%s%s",
                COLOR_RED, choiceIndex + 1, COLOR_WHITE,
                g_votingMapNames[ choiceIndex ], voteMapLine );

        menuKeys |= ( 1 << choiceIndex );
    }

    // This is to optionally display to single player that just voted or never saw the menu.
    // This function is called with the correct player id only after the player voted or by the
    // 'tryToShowTheVotingMenu(0)' function call.
    if( player_id > 0 )
    {
        menuKeys = addExtensionStayOption( player_id, copiedChars, voteStatus,
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

            menuKeys = addExtensionStayOption( player_id, copiedChars, voteStatus,
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

stock addExtensionStayOption( player_id, copiedChars, voteStatus[], voteStatusLenght, menuKeys )
{
    LOGGER( 4, "I AM ENTERING ON calculateExtensionOption(6) | player_id: %d, copiedChars: %d, \
            voteStatus: %s, ^nvoteStatusLenght: %d, menuKeys: %d", player_id, copiedChars, \
            voteStatus, voteStatusLenght, menuKeys )

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

    LOGGER( 4, "    ( vote_handleDisplay ) Add optional menu item | allowStay: %d, allowExtend: %d, \
           g_isExtendmapAllowStay: %d", allowStay, allowExtend, g_isExtendmapAllowStay )

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
            else if( g_isVotingByFrags )
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
                    "^n%s%i. %s%L%s",
                    COLOR_RED, g_totalVoteOptions + 1,
                    COLOR_WHITE, player_id,
                    extend_option_type, g_currentMapName,
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
                        g_currentMapName, voteMapLine );
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

    // Make a copy of the virgin menu, using the first player's menu as base. This causes all
    // the subsequent clean menus being displayed on the first player language.
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
            voteStatus, menuDirty, menuDirtySize, noneIsHidden )

    new bool:isToShowUndo;
    static   voteFooter[ MAX_SHORT_STRING ];
    static   menuHeader[ MAX_SHORT_STRING / 2 ];
    static   noneOption[ MAX_SHORT_STRING / 2 ];

    menuDirty  [ 0 ] = '^0';
    noneOption [ 0 ] = '^0';
    isToShowUndo     = ( player_id > 0 \
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
            voteFooterSize: %d", player_id, voteFooter, voteFooterSize )

    new copiedChars;
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
            noneOption: %s, noneOptionSize: %d", player_id, isToShowUndo, noneOption, noneOptionSize )

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
                case NONE_OPTION_HIDE_AFTER_USER_VOTE:
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
                case NONE_OPTION_ALWAYS_KEEP_SHOWING, CONVERT_NONE_OPTION_TO_CANCEL_LAST_VOTE:
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
            menuCleanSize: %d", player_id, menuClean, menuCleanSize )

    new bool:isToShowUndo;
    static   voteFooter[ MAX_SHORT_STRING ];
    static   menuHeader[ MAX_SHORT_STRING / 2 ];
    static   noneOption[ MAX_SHORT_STRING / 2 ];

    menuClean  [ 0 ] = '^0';
    noneOption [ 0 ] = '^0';
    isToShowUndo     = ( player_id > 0
                         && g_voteShowNoneOptionType == CONVERT_NONE_OPTION_TO_CANCEL_LAST_VOTE
                         && g_isPlayerVoted[ player_id ]
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
    LOGGER( 4, "I AM ENTERING ON display_vote_menu(4) | menuType: %d, player_id: %d, \
            menuBody: %s, menuKeys: %d", menuType, player_id, menuBody, menuKeys )

    if( isPlayerAbleToSeeTheVoteMenu( player_id ) )
    {
        show_menu( player_id, menuKeys, menuBody,
                ( menuType ? g_voteDuration : max( 2, g_voteDuration ) ),
                CHOOSE_MAP_MENU_NAME );
    }
}

stock isPlayerAbleToSeeTheVoteMenu( player_id )
{
    LOGGER( 4, "I AM ENTERING ON isPlayerAbleToSeeTheVoteMenu(1) | player_id: %d", player_id )

    new menu_id;
    new menukeys_unused;

    get_user_menu( player_id, menu_id, menukeys_unused );

    return ( menu_id == 0
             || menu_id == g_chooseMapMenuId
             || get_pcvar_num( cvar_isToReplaceByVoteMenu ) != 0 );
}

public vote_handleChoice( player_id, key )
{
    LOGGER( 128, "I AM ENTERING ON vote_handleChoice(2) | player_id: %d, key: %d", player_id, key )

    if( g_voteStatus & VOTE_IS_EXPIRED )
    {
        client_cmd( player_id, "^"slot%i^"", key + 1 );

        LOGGER( 1, "    ( vote_handleChoice ) Just Returning/blocking, slot key pressed." )
        return;
    }

    if( !g_isPlayerVoted[ player_id ] )
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
        new argument[ 2 ];

        argument[ 0 ] = false;
        argument[ 1 ] = player_id;

        set_task( 0.1, "vote_display", TASKID_VOTE_DISPLAY, argument, sizeof argument );
    }
}

stock cancel_player_vote( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cancel_player_vote(1) | player_id: %d", player_id )
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
    LOGGER( 128, "I AM ENTERING ON register_vote(2) | player_id: %d, pressedKeyCode: %d", player_id, pressedKeyCode )

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
    LOGGER( 128, "I AM ENTERING ON announceRegistedVote(2) | player_id: %d, pressedKeyCode: %d", player_id, pressedKeyCode )

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

stock computeVoteMapLine( voteMapLine[], voteMapLineLength, voteIndex )
{
    LOGGER( 0, "I AM ENTERING ON computeVoteMapLine(3) | voteMapLine: %s, voteMapLineLength: %d, \
            voteIndex: %d", voteMapLine, voteMapLineLength, voteIndex )

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

    LOGGER( 0, " ( computeVoteMapLine ) | g_showVoteStatus: %d, g_showVoteStatusType: %d, voteCountNumber: %d", \
            g_showVoteStatus, g_showVoteStatusType, voteCountNumber )
}

stock showPlayersVoteResult()
{
    LOGGER( 128, "I AM ENTERING ON showPlayersVoteResult(0)" )
    new voteMapLine[ 32 ];

    LOGGER( 4, "" )
    LOGGER( 4, "   [VOTE RESULT]" )

    for( new playerVoteMapChoiceIndex = 0; playerVoteMapChoiceIndex <= g_totalVoteOptions;
         ++playerVoteMapChoiceIndex )
    {
        computeVoteMapLine( voteMapLine, charsmax( voteMapLine ), playerVoteMapChoiceIndex );

        LOGGER( 4, "      %2i/%-2i, %i. %s", \
                g_arrayOfMapsWithVotesNumber[ playerVoteMapChoiceIndex ], g_totalVotesCounted, \
                playerVoteMapChoiceIndex, g_votingMapNames[ playerVoteMapChoiceIndex ] )
    }

    LOGGER( 4, "" )
    return 0;
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
stock getUniqueRandomInteger( sequence, maximum )
{
    LOGGER( 128, "I AM ENTERING ON getUniqueRandomInteger(2) maximum: %d", maximum )
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

            LOGGER( 1, "    ( getUniqueRandomInteger ) %d. Just Returning the random integer: %d", sequence, randomInteger )
            return randomInteger;
        }
    }

    LOGGER( 1, "    ( getUniqueRandomInteger ) %d. Just Returning the random integer: %d", sequence, -1 )
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

    maxVotingChoices = min( MAX_OPTIONS_IN_VOTE, get_pcvar_num( cvar_runoffMapchoices ) );
    maxVotingChoices = max( min( maxVotingChoices, numberOfMapsAtFirstPosition ), 2 );

    originalTotalVotingOptions = g_totalVoteOptions;
    g_totalVoteOptions         = maxVotingChoices;

    // Get an unique identification for the seed sequence value
    seedValue = abs( get_systime() );

    for( new voteOptionIndex = 0; voteOptionIndex < maxVotingChoices; voteOptionIndex++ )
    {
        randomInteger = getUniqueRandomInteger( seedValue, maxVotingChoices );

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

    // announce runoff voting requirement
    color_print( 0, "%L", LANG_PLAYER, "GAL_RUNOFF_REQUIRED" );

    if( !( get_pcvar_num( cvar_soundsMute ) & SOUND_RUNOFFREQUIRED ) )
    {
        client_cmd( 0, "spk ^"run officer( e40 ) voltage( e30 ) accelerating( s70 ) \
                is required^"" );
    }

    // let the server know the next vote will be a runoff
    g_voteStatus |= VOTE_IS_RUNOFF;

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
    set_task( 3.0, "startNonForcedVoting", TASKID_VOTE_STARTDIRECTOR );
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

    // determine the number of votes for 1st and 2nd places
    for( playerVoteMapChoiceIndex = 0; playerVoteMapChoiceIndex < g_totalVoteOptions;
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
    for( playerVoteMapChoiceIndex = 0; playerVoteMapChoiceIndex < g_totalVoteOptions;
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
    LOGGER( 16, "g_totalVoteOptions: %d, numberOfMapsAtFirstPosition: %d, numberOfMapsAtSecondPosition: %d", \
            g_totalVoteOptions, numberOfMapsAtFirstPosition, numberOfMapsAtSecondPosition )

    LOGGER( 1, "    ( determineTheVotingFirstChoices ) g_isTheLastGameRound: %d", g_isTheLastGameRound )
    LOGGER( 1, "    ( determineTheVotingFirstChoices ) g_isTimeToRestart: %d, g_voteStatus & VOTE_IS_FORCED: %d", \
            g_isTimeToRestart, g_voteStatus & VOTE_IS_FORCED != 0 )
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

    // announce the outcome
    if( numberOfVotesAtFirstPlace )
    {
        // if the top vote getting map didn't receive over 50% of the votes cast, to start a runoff vote
        if( get_pcvar_num( cvar_runoffEnabled )
            && !( g_voteStatus & VOTE_IS_RUNOFF )
            && numberOfVotesAtFirstPlace <= g_totalVotesCounted * get_pcvar_float( cvar_runoffRatio ) )
        {
            startRunoffVoting( firstPlaceChoices, secondPlaceChoices, numberOfMapsAtFirstPosition,
                    numberOfMapsAtSecondPosition );

            LOGGER( 1, "    ( computeVotes ) Just Returning/blocking, its runoff time." )
            return;
        }

        chooseTheVotingMapWinner( firstPlaceChoices, numberOfMapsAtFirstPosition );
    }
    else // the execution flow gets here when anybody voted for next map
    {
        chooseRandomVotingWinner();
    }

    LOGGER( 1, "    ( computeVotes|out ) g_isTheLastGameRound: %d", g_isTheLastGameRound )
    LOGGER( 1, "    ( computeVotes|out ) g_isTimeToRestart: %d, g_voteStatus & VOTE_IS_FORCED: %d", \
            g_isTimeToRestart, g_voteStatus & VOTE_IS_FORCED != 0 )

    finalizeVoting();
}

stock chooseTheVotingMapWinner( firstPlaceChoices[], numberOfMapsAtFirstPosition )
{
    LOGGER( 128, "I AM ENTERING ON chooseTheVotingMapWinner(2)" )
    new winnerVoteMapIndex;

    // if there is a tie for 1st, randomly select one as the winner
    if( numberOfMapsAtFirstPosition > 1 )
    {
        winnerVoteMapIndex = firstPlaceChoices[ random_num( 0, numberOfMapsAtFirstPosition - 1 ) ];
        color_print( 0, "%L", LANG_PLAYER, "GAL_WINNER_TIED", numberOfMapsAtFirstPosition );
    }
    else
    {
        winnerVoteMapIndex = firstPlaceChoices[ 0 ];
    }

    LOGGER( 1, "    ( chooseTheVotingMapWinner ) g_isTheLastGameRound: %d ", g_isTheLastGameRound )
    LOGGER( 1, "    ( chooseTheVotingMapWinner ) g_isTimeToRestart: %d, g_voteStatus & VOTE_IS_FORCED: %d", \
            g_isTimeToRestart, g_voteStatus & VOTE_IS_FORCED != 0 )

    // winnerVoteMapIndex == g_totalVoteOptions, means the 'Stay Here' option.
    // Then, here we keep the current map or extend current map.
    if( winnerVoteMapIndex == g_totalVoteOptions )
    {
        if( !g_isGameFinalVoting // "stay here" won and the map mustn't be restarted.
            && !g_isTimeToRestart )
        {
            color_print( 0, "%L", LANG_PLAYER, "GAL_WINNER_STAY" );
        }
        else if( !g_isGameFinalVoting // "stay here" won and the map must be restarted.
                 && g_isTimeToRestart )
        {
            color_print( 0, "%L", LANG_PLAYER, "GAL_WINNER_STAY" );
            process_last_round( g_isToChangeMapOnVotingEnd );
        }
        else if( g_isGameFinalVoting ) // "extend map" won
        {
            if( g_isVotingByRounds )
            {
                color_print( 0, "%L", LANG_PLAYER, "GAL_WINNER_EXTEND_ROUND", g_extendmapStepRounds );
            }
            else if( g_isVotingByFrags )
            {
                color_print( 0, "%L", LANG_PLAYER, "GAL_WINNER_EXTEND_FRAGS", g_extendmapStepFrags );
            }
            else
            {
                color_print( 0, "%L", LANG_PLAYER, "GAL_WINNER_EXTEND", g_extendmapStepMinutes );
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

        color_print( 0, "%L", LANG_PLAYER, "GAL_NEXTMAP", g_nextMapName );
        process_last_round( g_isToChangeMapOnVotingEnd );

        g_voteStatus |= VOTE_IS_OVER;
    }
}

stock chooseRandomVotingWinner()
{
    if( !get_pcvar_num( cvar_isExtendmapOrderAllowed ) )
    {
        new winnerVoteMapIndex;
        winnerVoteMapIndex = random_num( 0, g_totalVoteOptions - 1 );

        setNextMap( g_votingMapNames[ winnerVoteMapIndex ] );
        color_print( 0, "%L", LANG_PLAYER, "GAL_WINNER_RANDOM", g_nextMapName );
    }
    else
    {
        color_print( 0, "%L", LANG_PLAYER, "GAL_WINNER_ORDERED", g_nextMapName );
    }

    process_last_round( g_isToChangeMapOnVotingEnd );
    g_voteStatus |= VOTE_IS_OVER;
}

/**
 * Restore global variables to is default state. This is to be ready for a new voting.
 */
stock finalizeVoting()
{
    LOGGER( 128, "I AM ENTERING ON finalizeVoting(0)" )

    g_isVotingByTimer               = false;
    g_isVotingByRounds              = false;
    g_isVotingByFrags               = false;
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
    LOGGER( 128, "I AM ENTERING ON Float:map_getMinutesElapsed(0) | mp_timelimit: %f", get_pcvar_float( cvar_mp_timelimit ) )
    return get_pcvar_float( cvar_mp_timelimit ) - ( float( get_timeleft() ) / 60.0 );
}

stock map_getMinutesElapsedInteger()
{
    LOGGER( 128, "I AM ENTERING ON Float:map_getMinutesElapsed(0) | mp_timelimit: %f", get_pcvar_float( cvar_mp_timelimit ) )

    // While the Unit Tests are running, to force a specific time.
#if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED )
    if( g_test_isTheUnitTestsRunning )
    {
        return g_test_gameElapsedTime;
    }
#endif
    return get_pcvar_num( cvar_mp_timelimit ) - ( get_timeleft() / 60 );
}

stock map_extend()
{
    LOGGER( 128, "I AM ENTERING ON map_extend(0)" )
    LOGGER( 2, "%32s g_rtvWaitMinutes: %f, g_extendmapStepMinutes: %d", "map_extend( in )", g_rtvWaitMinutes, g_extendmapStepMinutes )
    LOGGER( 2, "( map_extend ) TRYING to change the cvar %15s to '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOGGER( 2, "( map_extend ) TRYING to change the cvar %15s to '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOGGER( 2, "( map_extend ) TRYING to change the cvar %15s to '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOGGER( 2, "( map_extend ) TRYING to change the cvar %15s to '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )

    // reset the "rtv wait" time, taking into consideration the map extension
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

    saveEndGameLimits();

    // do that actual map extension
    if( g_isVotingByRounds )
    {
        set_pcvar_num( cvar_mp_fraglimit, 0 );
        set_pcvar_float( cvar_mp_timelimit, 0.0 );

        if( g_isMaxroundsExtend )
        {
            set_pcvar_num( cvar_mp_maxrounds, get_pcvar_num( cvar_mp_maxrounds ) + g_extendmapStepRounds );
            set_pcvar_num( cvar_mp_winlimit, 0 );
        }
        else
        {
            set_pcvar_num( cvar_mp_maxrounds, 0 );
            set_pcvar_num( cvar_mp_winlimit, get_pcvar_num( cvar_mp_winlimit ) + g_extendmapStepRounds );
        }
    }
    else if( g_isVotingByFrags )
    {
        set_pcvar_num( cvar_mp_maxrounds, 0 );
        set_pcvar_num( cvar_mp_winlimit, 0 );
        set_pcvar_float( cvar_mp_timelimit, 0.0 );
        set_pcvar_num( cvar_mp_fraglimit, get_pcvar_num( cvar_mp_fraglimit ) + g_extendmapStepFrags );
    }
    else
    {
        set_pcvar_num( cvar_mp_fraglimit, 0 );
        set_pcvar_num( cvar_mp_maxrounds, 0 );
        set_pcvar_num( cvar_mp_winlimit, 0 );
        set_pcvar_float( cvar_mp_timelimit, get_pcvar_float( cvar_mp_timelimit ) + g_extendmapStepMinutes );
    }

    LOGGER( 2, "( map_extend ) CHECKOUT the cvar %23s is '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOGGER( 2, "( map_extend ) CHECKOUT the cvar %23s is '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOGGER( 2, "( map_extend ) CHECKOUT the cvar %23s is '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOGGER( 2, "( map_extend ) CHECKOUT the cvar %23s is '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )
    LOGGER( 2, "%32s g_rtvWaitMinutes: %f, g_extendmapStepMinutes: %d", "map_extend( out )", g_rtvWaitMinutes, g_extendmapStepMinutes )
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
    restoreOriginalServerMaxSpeed();

    LOGGER( 2, "( map_restoreEndGameCvars ) TRYING to change the cvar %15s to '%f'.", "'mp_timelimit'", get_pcvar_float( cvar_mp_timelimit ) )
    LOGGER( 2, "( map_restoreEndGameCvars ) TRYING to change the cvar %15s to '%d'.", "'mp_fraglimit'", get_pcvar_num( cvar_mp_fraglimit ) )
    LOGGER( 2, "( map_restoreEndGameCvars ) TRYING to change the cvar %15s to '%d'.", "'mp_maxrounds'", get_pcvar_num( cvar_mp_maxrounds ) )
    LOGGER( 2, "( map_restoreEndGameCvars ) TRYING to change the cvar %15s to '%d'.", "'mp_winlimit'", get_pcvar_num( cvar_mp_winlimit ) )

    if( g_isEndGameLimitsChanged )
    {
        g_isEndGameLimitsChanged = false;

        set_pcvar_float( cvar_mp_timelimit, g_originalTimelimit );
        set_pcvar_num(   cvar_mp_maxrounds, g_originalMaxRounds );
        set_pcvar_num(   cvar_mp_winlimit,  g_originalWinLimit  );
        set_pcvar_num(   cvar_mp_fraglimit, g_originalFragLimit );

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
    LOGGER( 128, "I AM ENTERING ON restoreOriginalServerMaxSpeed(0)" )

    if( g_original_sv_maxspeed )
    {
        set_pcvar_float( cvar_sv_maxspeed, g_original_sv_maxspeed );
        LOGGER( 2, "( restoreOriginalServerMaxSpeed ) IS CHANGING THE CVAR 'sv_maxspeed' to '%f'.", g_original_sv_maxspeed )

        g_original_sv_maxspeed = 0.0;
    }
}

stock map_isInMenu( map[] )
{
    LOGGER( 0, "I AM ENTERING ON map_isInMenu(1) | map: %s", map )

    for( new playerVoteMapChoiceIndex = 0;
         playerVoteMapChoiceIndex < g_totalVoteOptions; ++playerVoteMapChoiceIndex )
    {
        if( equali( map, g_votingMapNames[ playerVoteMapChoiceIndex ] ) )
        {
            LOGGER( 0, "    ( map_isInMenu ) Returning true." )
            return true;
        }
    }

    LOGGER( 0, "    ( map_isInMenu ) Returning false." )
    return false;
}

stock isPrefixInMenu( map[] )
{
    LOGGER( 0, "I AM ENTERING ON isPrefixInMenu(1) | map: %s", map )

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
            LOGGER( 0, "    ( isPrefixInMenu ) Returning true." )
            return true;
        }
    }

    LOGGER( 0, "    ( isPrefixInMenu ) Returning false." )
    return false;
}

/**
 * Everybody who call this, must to check whether the recent maps are loaded or not. To do so, just
 * do 'if(g_recentMapCount)'.
 */
stock map_isTooRecent( map[] )
{
    LOGGER( 0, "I AM ENTERING ON map_isTooRecent(1) | map: %s", map )
    LOGGER( 0, "    ( map_isTooRecent ) Returning TrieKeyExists: %d", TrieKeyExists( g_recentMapsTrie, map ) )

    return TrieKeyExists( g_recentMapsTrie, map );
}

stock is_to_block_RTV( player_id )
{
    LOGGER( 128, "I AM ENTERING ON is_to_block_RTV(2) | player_id: %d", player_id )

    // If time-limit is 0, minutesElapsed will always be 0.
    new Float:minutesElapsed;

    // If an early vote is pending, don't allow any rocks
    if( g_voteStatus & VOTE_IS_EARLY )
    {
        color_print( player_id, "%L", player_id, "GAL_ROCK_FAIL_PENDINGVOTE" );
        LOGGER( 1, "    ( is_to_block_RTV ) Just Returning/blocking, the early voting is pending." )
    }

    // Rocks can only be made if a vote isn't already in progress
    else if( g_voteStatus & VOTE_IS_IN_PROGRESS )
    {
        color_print( player_id, "%L", player_id, "GAL_ROCK_FAIL_INPROGRESS" );
        LOGGER( 1, "    ( is_to_block_RTV ) Just Returning/blocking, the voting is in progress." )
    }

    // If the outcome of the vote hasn't already been determined
    else if( g_voteStatus & VOTE_IS_OVER )
    {
        color_print( player_id, "%L", player_id, "GAL_ROCK_FAIL_VOTEOVER" );
        LOGGER( 1, "    ( is_to_block_RTV ) Just Returning/blocking, the voting is over." )
    }

    // Cannot rock when admins are online
    else if( get_pcvar_num( cvar_rtvWaitAdmin )
             && g_rtvWaitAdminNumber > 0 )
    {
        color_print( player_id, "%L", player_id, "GAL_ROCK_WAIT_ADMIN" );
        LOGGER( 1, "    ( is_to_block_RTV ) Just Returning/blocking, cannot rock when admins are online." )
    }

    // If the player is the only one on the server, bring up the vote immediately
    else if( get_realplayersnum() == 1 )
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
    LOGGER( 128, "I AM ENTERING ON vote_rock(1) | map: %d", player_id )
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
        && get_realplayersnum() >= endOnRoundRtv )
    {
        g_isToChangeMapOnVotingEnd = true;
    }
    else
    {
        g_isTheLastGameRound = true;
    }

    configureRtvVotingType();
    vote_startDirector( false );
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
    LOGGER( 128, "I AM ENTERING ON configureRtvVotingType(0)" )

    new minutes_left    = get_timeleft() / 20; // Uses 20 instead of 60 to be more a fair amount
    new maxrounds_left  = get_pcvar_num( cvar_mp_maxrounds ) - g_totalRoundsPlayed;
    new winlimit_left   = get_pcvar_num( cvar_mp_winlimit ) - max( g_totalCtWins, g_totalTerroristsWins );
    new fragslimit_left = get_pcvar_num( cvar_mp_fraglimit ) - g_greatestKillerFrags;

    if( ( minutes_left > maxrounds_left
          && maxrounds_left > 0 )
        || ( minutes_left > winlimit_left
             && winlimit_left > 0 ) )
    {
        g_isVotingByRounds = true;

        // the variable 'g_isMaxroundsExtend' is forced to false because it could not be always false.
        if( maxrounds_left >= winlimit_left )
        {
            g_isMaxroundsExtend = true;
        }
        else
        {
            g_isMaxroundsExtend = false;
        }

    } else if( minutes_left > fragslimit_left
               && fragslimit_left > 0 )
    {
        g_isVotingByFrags = true;
    }
}

stock vote_unrockTheVote( player_id )
{
    LOGGER( 128, "I AM ENTERING ON vote_unrockTheVote(1) | player_id: %d", player_id )

    if( g_rockedVote[ player_id ] )
    {
        g_rockedVote[ player_id ] = false;
        g_rockedVoteCount--;
    }
}

stock vote_getRocksNeeded()
{
    LOGGER( 128, "I AM ENTERING ON vote_getRocksNeeded(0)" )
    return floatround( get_pcvar_float( cvar_rtvRatio ) * float( get_realplayersnum() ), floatround_ceil );
}

public rtv_remind( param )
{
    LOGGER( 128, "I AM ENTERING ON rtv_remind(1) | param: %d", param )
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

stock serverChangeLevel( mapName[] )
{
    LOGGER( 128, "I AM ENTERING ON serverChangeLevel(1) | mapName: %s", mapName )

#if AMXX_VERSION_NUM < 183
    server_cmd( "changelevel %s", mapName );
#else
    engine_changelevel( mapName );
#endif
}

public cmd_HL1_votemap( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_HL1_votemap(1) | player_id: %d", player_id )

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
    LOGGER( 128, "I AM ENTERING ON cmd_HL1_listmaps(1) | player_id: %d", player_id )

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
    LOGGER( 128, "I AM ENTERING ON map_listAll(1) | player_id: %d", player_id )
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

        ArrayGetString( g_nominationLoadedMapsArray, mapIndex, mapName, charsmax( mapName ) );
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
    LOGGER( 128, "I AM ENTERING ON color_console_print(...) | player_id: %d, message: %s...", player_id, message )
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

public client_authorized( player_id )
{
    LOGGER( 128, "I AM ENTERING ON client_authorized(1) | player_id: %d", player_id )
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
    LOGGER( 128, "I AM ENTERING ON client_disconnected(1) | player_id: %d", player_id )

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
    LOGGER( 128, "I AM ENTERING ON unnominatedDisconnectedPlayer(1) | player_id: %d", player_id )

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

            ArrayGetString( g_nominationLoadedMapsArray, mapIndex, mapName, charsmax( mapName ) );
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
    new playersCount = get_realplayersnum();

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

    LOGGER( 2, "I AM EXITING ON isToHandleRecentlyEmptyServer(0) | g_isUsingEmptyCycle = %d, \
            g_emptyCycleMapsNumber = %d", g_isUsingEmptyCycle, g_emptyCycleMapsNumber )
}

/**
 * Inicializes the empty cycle server feature at map starting.
 */
public inicializeEmptyCycleFeature()
{
    LOGGER( 128, "I AM ENTERING ON inicializeEmptyCycleFeature(0)" )

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
        setNextMap( nextMapName, false );
    }

    return mapIndex;
}

stock getLastEmptyCycleMap( lastEmptyCycleMap[ MAX_MAPNAME_LENGHT ] )
{
    LOGGER( 128, "I AM ENTERING ON getLastEmptyCycleMap(1) | lastEmptyCycleMap: %s", lastEmptyCycleMap )

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
    LOGGER( 128, "I AM ENTERING ON setLastEmptyCycleMap(1) | lastEmptyCycleMap: %s", lastEmptyCycleMap )

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
 * @param mapArray      the dynamic array with the map list to search
 * @param currentMap    the string printer to the current map name
 * @param nextMapName   the string pointer which will receive the next map
 *
 * @return mapIndex     the nextMapName index in the mapArray. -1 if not found a nextMapName.
 */
stock map_getNext( Array:mapArray, currentMap[], nextMapName[ MAX_MAPNAME_LENGHT ] )
{
    LOGGER( 128, "I AM ENTERING ON map_getNext(3) | currentMap: %s", currentMap )
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
        ArrayGetString( mapArray, nextmapIndex, nextMapName, charsmax( nextMapName ) );
    }
    else
    {
        log_amx( "WARNING: Your 'mapcyclefile' server variable is invalid!" );
        LOGGER( 1, "WARNING: Your 'mapcyclefile' server variable is invalid!" )

        copy( nextMapName, charsmax( nextMapName ), "your_mapcycle_file_is_empty" );
    }

    return returnValue;
}

public client_putinserver( player_id )
{
    LOGGER( 128, "I AM ENTERING ON client_putinserver(1) | player_id: %d", player_id )

    if( ( g_voteStatus & VOTE_IS_EARLY )
        && !is_user_bot( player_id )
        && !is_user_hltv( player_id ) )
    {
        set_task( 20.0, "srv_announceEarlyVote", player_id );
    }
}

public srv_announceEarlyVote( player_id )
{
    LOGGER( 128, "I AM ENTERING ON srv_announceEarlyVote(1) | player_id: %d", player_id )

    if( is_user_connected( player_id ) )
    {
        color_print( player_id, "%L", player_id, "GAL_VOTE_EARLY" );
    }
}

stock nomination_announceCancellation( nominations[] )
{
    LOGGER( 128, "I AM ENTERING ON nomination_announceCancellation(1) | nominations: %s", nominations )
    color_print( 0, "%L", LANG_PLAYER, "GAL_CANCEL_SUCCESS", nominations );
}

stock nomination_clearAll()
{
    LOGGER( 128, "I AM ENTERING ON nomination_clearAll(0)" )

    TrieClear( g_reverseSearchNominationsTrie );
    TrieClear( g_forwardSearchNominationsTrie );

    ArrayClear( g_nominatedMapsArray );
}

stock map_announceNomination( player_id, map[] )
{
    LOGGER( 128, "I AM ENTERING ON map_announceNomination(2) | player_id: %d, map: %s", player_id, map )
    new player_name[ MAX_PLAYER_NAME_LENGHT ];

    GET_USER_NAME( player_id, player_name )
    color_print( 0, "%L", LANG_PLAYER, "GAL_NOM_SUCCESS", player_name, map );
}

public cmd_rockthevote( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_rockthevote(1) | player_id: %d", player_id )

    color_print( player_id, "%L", player_id, "GAL_CMD_RTV" );
    vote_rock( player_id );

    LOGGER( 1, "    ( cmd_rockthevote ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

public cmd_nominations( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_nominations(1) | player_id: %d", player_id )

    color_print( player_id, "%L", player_id, "GAL_CMD_NOMS" );
    nomination_list();

    LOGGER( 1, "    ( cmd_nominations ) Returning PLUGIN_CONTINUE" )
    return PLUGIN_CONTINUE;
}

public cmd_listrecent( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_listrecent(1) | player_id: %d", player_id )

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
    LOGGER( 128, "I AM ENTERING ON showRecentMapsListMenu(1) | player_id: %d", player_id )

    new mapIndex;
    new itemsCount;

    new recentMapName[ MAX_MAPNAME_LENGHT ];
    new menuOptionString[ 64 ];

    // We starting building the menu
    TRY_TO_APPLY( menu_destroy, g_generalUsePlayersMenuIds[ player_id ] )

    if( ( mapIndex = g_recentMapsMenuPages[ player_id ] * MAX_MENU_ITEMS_PER_PAGE ) )
    {
        mapIndex = mapIndex - 1;
    }

    itemsCount = 0;

    // Calculate how much pages there are available.
    new currentPageNumber = g_recentMapsMenuPages[ player_id ];
    new lastPageNumber    = ( ( g_recentMapCount / MAX_MENU_ITEMS_PER_PAGE )
                        + ( ( ( g_recentMapCount % MAX_MENU_ITEMS_PER_PAGE ) > 0 ) ? 1 : 0 ) );

    // To create the menu
#if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES > 0
    formatex( menuOptionString, charsmax( menuOptionString ),
            IS_COLORED_CHAT_ENABLED() ? "%L\R%d /%d" : "%L  %d /%d",
            player_id, "GAL_MAP_RECENTMAPS", currentPageNumber + 1, lastPageNumber );
#else
    formatex( menuOptionString, charsmax( menuOptionString ), "%L  %d /%d", player_id, "GAL_MAP_RECENTMAPS",
            currentPageNumber + 1, lastPageNumber );
#endif

    g_generalUsePlayersMenuIds[ player_id ] = menu_create( menuOptionString, "cmd_listrecent_handler" );

    // Disables the menu paging.
    menu_setprop( g_generalUsePlayersMenuIds[ player_id ], MPROP_PERPAGE, 0 );

    // Configure the menu buttons.
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_EXITNAME, g_generalUsePlayersMenuIds[ player_id ], "EXIT" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_NEXTNAME, g_generalUsePlayersMenuIds[ player_id ], "MORE" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_BACKNAME, g_generalUsePlayersMenuIds[ player_id ], "BACK" )

    // Add the menu items.
    for( ; mapIndex < g_recentMapCount && itemsCount < MAX_MENU_ITEMS_PER_PAGE; ++mapIndex, ++itemsCount )
    {
        LOGGER( 4, "( showRecentMapsListMenu ) mapIndex: %d", mapIndex )
        ArrayGetString( g_recentListMapsArray, mapIndex, recentMapName, charsmax( recentMapName ) );

        menu_additem( g_generalUsePlayersMenuIds[ player_id ], recentMapName );
        LOGGER( 4, "( showRecentMapsListMenu ) recentMapName: %s", recentMapName )
    }

    LOGGER( 4, "( showRecentMapsListMenu ) itemsCount: %d, mapIndex: %d", itemsCount, mapIndex )
    addMenuMoreBackOptions( player_id, menuOptionString, mapIndex < g_recentMapCount, currentPageNumber > 0, itemsCount );

    // To display the menu.
    menu_display( player_id, g_generalUsePlayersMenuIds[ player_id ] );
}

stock addMenuMoreBackOptions( player_id, menuOptionString[], bool:isToEnableMoreButton, bool:isToEnableBackButton, itemsCount )
{
    LOGGER( 128, "I AM ENTERING ON addMenuMoreBackOptions(5) | isToEnableMoreButton: %d, \
            isToEnableBackButton: %d", isToEnableMoreButton, isToEnableBackButton )

    // Force the menu control options to be present on the keys 8 (more), 9 (back) and 0 (exit).
    while( itemsCount < MAX_MENU_ITEMS_PER_PAGE )
    {
        itemsCount++;
        formatex( menuOptionString, MAX_SHORT_STRING - 1, "%L", player_id, "OFF" );
        menu_additem( g_generalUsePlayersMenuIds[ player_id ], menuOptionString, _, 1 << 26 );

        // When using slot=1 this might break your menu. To achieve this functionality
        // menu_addblank2() should be used (AMXX 183 only).
        // menu_addblank( g_generalUsePlayersMenuIds[ player_id ], 1 );
    }

    // Add some space from the control options and format the more button within the LANG file.
    menu_addblank( g_generalUsePlayersMenuIds[ player_id ], 0 );
    formatex( menuOptionString, MAX_SHORT_STRING - 1, "%L", player_id, "MORE" );

    // If there are more maps, add the more option
    if( isToEnableMoreButton )
    {
        menu_additem( g_generalUsePlayersMenuIds[ player_id ], menuOptionString, _, 0 );
    }
    else
    {
        menu_additem( g_generalUsePlayersMenuIds[ player_id ], menuOptionString, _, 1 << 26 );
    }

    // If we are on the first page, disable the back option and to add the exit button.
    if( isToEnableBackButton )
    {
        formatex( menuOptionString, MAX_SHORT_STRING - 1, "%L", player_id, "BACK" );
        menu_additem( g_generalUsePlayersMenuIds[ player_id ], menuOptionString, _, 0 );
    }
    else
    {
        // To add the exit button
        formatex( menuOptionString, MAX_SHORT_STRING - 1, "%L", player_id, "EXIT" );
        menu_additem( g_generalUsePlayersMenuIds[ player_id ], menuOptionString, _, 0 );
    }
}

public cmd_listrecent_handler( player_id, menu, item )
{
    LOGGER( 128, "I AM ENTERING ON cmd_listrecent_handler(3) | player_id: %d, menu: %d, item: %d", player_id, menu, item )

    // Let go to destroy the menu and clean some memory. As the menu is not paginated, the item 9
    // is the key 0 on the keyboard. Also, the item 8 is the key 9; 7, 8; 6, 7; 5, 6; 4, 5; etc.
    if( item < 0
        || ( item == 9
             && g_recentMapsMenuPages[ player_id ] == 0 ) )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )

        LOGGER( 1, "    ( cmd_listrecent_handler ) Just Returning PLUGIN_HANDLED, as menu is destroyed." )
        return PLUGIN_HANDLED;
    }

    // If the 0 button item is hit, and we are not on the first page, we must to perform the back option.
    if( item == 9
        && g_recentMapsMenuPages[ player_id ] > 0 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )
        g_recentMapsMenuPages[ player_id ] ? g_recentMapsMenuPages[ player_id ]-- : player_id;

        // We need to delay the menu show up on 0.2 seconds to avoid players lagging the server by DOS attack.
        set_task( 0.2, "showRecentMapsListMenu", player_id );

        LOGGER( 1, "    ( cmd_listrecent_handler ) Just Returning PLUGIN_HANDLED, doing the back button." )
        return PLUGIN_HANDLED;
    }

    // If the 9 button item is hit, and we are on some page not the last one, we must to perform the more option.
    if( item == 8 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )
        g_recentMapsMenuPages[ player_id ]++;

        // We need to delay the menu show up on 0.2 seconds to avoid players lagging the server by DOS attack.
        set_task( 0.2, "showRecentMapsListMenu", player_id );

        LOGGER( 1, "    ( cmd_listrecent_handler ) Just Returning PLUGIN_HANDLED, doing the more button." )
        return PLUGIN_HANDLED;
    }

    // Just keep showing the menu until the exit button is pressed.
    menu_display( player_id, g_generalUsePlayersMenuIds[ player_id ] );

    LOGGER( 1, "    ( cmd_listrecent_handler ) Just Returning PLUGIN_HANDLED." )
    return PLUGIN_HANDLED;
}

public cmd_cancelVote( player_id, level, cid )
{
    LOGGER( 128, "I AM ENTERING ON cmd_cancelVote(3) | player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOGGER( 1, "    ( cmd_cancelVote ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }

    cancelVoting( true );

    LOGGER( 1, "    ( cmd_cancelVote ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

/**
 * Called when need to start a vote map, where the command line first argument could be:
 *    -nochange: extend the current map, aka, Keep Current Map, will to do the real extend.
 *    -restart: extend the current map, aka, Keep Current Map restart the server at the current map.
 */
public cmd_startVote( player_id, level, cid )
{
    LOGGER( 128, "I AM ENTERING ON cmd_startVote(3) | player_id: %d, level: %d, cid: %d", player_id, level, cid )

    if( !cmd_access( player_id, level, cid, 1 ) )
    {
        LOGGER( 1, "    ( cmd_startVote ) Returning PLUGIN_HANDLED" )
        return PLUGIN_HANDLED;
    }

    if( g_voteStatus & VOTE_IS_IN_PROGRESS )
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

            if( equali( argument, "-restart", 4 ) )
            {
                g_isTimeToRestart = true;
            }

            LOGGER( 8, "( cmd_startVote ) equal( %s, '-restart', 4 )? %d", argument, equal( argument, "-restart", 4 ) )
        }

        LOGGER( 8, "( cmd_startVote ) g_isTimeToRestart? %d, g_isToChangeMapOnVotingEnd? %d, \
                g_voteStatus & VOTE_IS_FORCED: %d", g_isTimeToRestart, g_isToChangeMapOnVotingEnd, \
                g_voteStatus & VOTE_IS_FORCED != 0 )

        vote_startDirector( true );
    }

    LOGGER( 1, "    ( cmd_startVote ) Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

public cmd_createMapFile( player_id, level, cid )
{
    LOGGER( 128, "I AM ENTERING ON cmd_createMapFile(3) | player_id: %d, level: %d, cid: %d", player_id, level, cid )

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
            new mapFileName[ MAX_MAPNAME_LENGHT ];

            read_argv( 1, mapFileName, charsmax( mapFileName ) );
            remove_quotes( mapFileName );

            // map name is MAX_MAPNAME_LENGHT, .bsp: 4 + string terminator: 1 = 5
            new loadedMapName[ MAX_MAPNAME_LENGHT + 5 ];

            new directoryDescriptor;
            new mapFileDescriptor;
            new mapCount;
            new mapNameLength;

            directoryDescriptor = open_dir( "maps", loadedMapName, charsmax( loadedMapName )  );

            if( directoryDescriptor )
            {
                new mapFilePath[ MAX_FILE_PATH_LENGHT ];

                formatex( mapFilePath, charsmax( mapFilePath ), "%s/%s", g_configsDirPath, mapFileName );
                mapFileDescriptor = fopen( mapFilePath, "wt" );

                if( mapFileDescriptor )
                {
                    mapCount = 0;

                    while( next_file( directoryDescriptor, loadedMapName, charsmax( loadedMapName ) ) )
                    {
                        mapNameLength = strlen( loadedMapName );

                        if( mapNameLength > 4
                            && equali( loadedMapName[ mapNameLength - 4 ], ".bsp", 4 ) )
                        {
                            loadedMapName[ mapNameLength - 4 ] = '^0';

                            if( IS_MAP_VALID( loadedMapName ) )
                            {
                                mapCount++;
                                fprintf( mapFileDescriptor, "%s^n", loadedMapName );
                            }
                        }
                    }

                    fclose( mapFileDescriptor );
                    console_print( player_id, "%L", player_id, "GAL_CREATIONSUCCESS", mapFilePath, mapCount );
                }
                else
                {
                    console_print( player_id, "%L", player_id, "GAL_CREATIONFAILED", mapFilePath );
                }

                close_dir( directoryDescriptor );
            }
            else
            {
                // directory not found, wtf?
                console_print( player_id, "%L", player_id, "GAL_MAPSFOLDERMISSING" );
            }
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

/**
 * Called when need to start a vote map, where the command line first argument could be:
 *    -nochange: extend the current map, aka, Keep Current Map, will to do the real extend.
 *    -restart: extend the current map, aka, Keep Current Map restart the server at the current map.
 */
public cmd_maintenanceMode( player_id, level, cid )
{
    LOGGER( 128, "I AM ENTERING ON cmd_maintenanceMode(3) | player_id: %d, level: %d, cid: %d", player_id, level, cid )

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

/**
 * Generic say handler to determine if we need to act on what was said.
 */
public cmd_say( player_id )
{
    LOGGER( 128, "I AM ENTERING ON cmd_say(1) | player_id: %s", player_id )

    new prefix_index;
    new thirdWord[ 2 ];

    static sentence  [ 70 ];
    static firstWord [ 32 ];
    static secondWord[ 32 ];

    sentence  [ 0 ] = '^0';
    firstWord [ 0 ] = '^0';
    secondWord[ 0 ] = '^0';

    read_args( sentence, charsmax( sentence ) );
    remove_quotes( sentence );

    parse( sentence,
            firstWord, charsmax( firstWord ),
            secondWord, charsmax( secondWord ),
            thirdWord, charsmax( thirdWord ) );

    LOGGER( 4, "( cmd_say ) sentence: %s, firstWord: %s, secondWord: %s, thirdWord: %s", \
            sentence, firstWord, secondWord, thirdWord )

    // if the chat line has more than 2 words, we're not interested at all
    if( thirdWord[ 0 ] == '^0' )
    {
        LOGGER( 4, "( cmd_say ) the thirdWord is empty." )
        new mapIndex;

        // if the chat line contains 1 word, it could be a map or a one-word command as
        // "say [rtv|rockthe<anything>vote]"
        if( secondWord[ 0 ] == '^0' )
        {
            LOGGER( 4, "( cmd_say ) the secondWord is empty." )

            if( ( g_rtvCommands & RTV_CMD_SHORTHAND
                  && equali( firstWord, "rtv" ) )
                || ( g_rtvCommands & RTV_CMD_DYNAMIC
                     && equali( firstWord, "rockthe", 7 )
                     && equali( firstWord[ strlen( firstWord ) - 4 ], "vote" )
                     && !( g_rtvCommands & RTV_CMD_STANDARD ) ) )
            {
                LOGGER( 4, "( cmd_say ) running vote_rock( player_id ); player_id: %s", player_id )
                vote_rock( player_id );

                LOGGER( 1, "    ( cmd_say ) Just Returning PLUGIN_HANDLED, vote_rock(1) chosen." )
                return PLUGIN_HANDLED;
            }
            else if( get_pcvar_num( cvar_nomPlayerAllowance ) )
            {
                LOGGER( 4, "( cmd_say ) on the 1 word: else if( cvar_nomPlayerAllowance ), \
                        get_pcvar_num( cvar_nomPlayerAllowance ): %d", get_pcvar_num( cvar_nomPlayerAllowance ) )

                if( equali( firstWord, "noms" )
                    || equali( firstWord, "nominations" ) )
                {
                    nomination_list();

                    LOGGER( 1, "    ( cmd_say ) Just Returning PLUGIN_HANDLED, nomination_list(0) chosen." )
                    return PLUGIN_HANDLED;
                }
                else
                {
                    mapIndex = getSurMapNameIndex( firstWord );

                    if( mapIndex >= 0 )
                    {
                        nomination_toggle( player_id, mapIndex );

                        LOGGER( 1, "    ( cmd_say ) Just Returning PLUGIN_HANDLED, nomination_toggle(2) chosen." )
                        return PLUGIN_HANDLED;
                    }
                    else if( strlen( firstWord ) > 5
                             && equali( firstWord, "nom", 3 )
                             && equali( firstWord[ strlen( firstWord ) - 4 ], "menu" ) )
                    {
                        nomination_menu( player_id );

                        LOGGER( 1, "    ( cmd_say ) Just Returning PLUGIN_HANDLED, nomination_menu(1) chosen." )
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
                                    firstWord, g_mapPrefixes[ prefix_index ], containi( firstWord, g_mapPrefixes[ prefix_index ] ) )

                            if( containi( firstWord, g_mapPrefixes[ prefix_index ] ) > -1 )
                            {
                                nomination_menu( player_id );

                                LOGGER( 1, "    ( cmd_say ) Just Returning PLUGIN_HANDLED, nomination_menu(1) chosen." )
                                return PLUGIN_HANDLED;
                            }
                        }
                    }

                    LOGGER( 4, "( cmd_say ) equali(%s, 'nom', 3)? %d, strlen(%s) > 5? %d", \
                            firstWord, equali( firstWord, "nom", 3 ), \
                            firstWord, strlen( firstWord ) > 5 )
                }
            }
        }
        else if( get_pcvar_num( cvar_nomPlayerAllowance ) )  // "say <nominate|nom|cancel> <map>"
        {
            if( equali( firstWord, "nominate" )
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

                LOGGER( 1, "    ( cmd_say ) Just Returning PLUGIN_HANDLED, nominationAttemptWithNamePart(2): %s", secondWord )
                return PLUGIN_HANDLED;
            }
            else if( equali( firstWord, "cancel" ) )
            {
                // bpj -- allow ambiguous cancel in which case a menu of their nominations is shown
                mapIndex = getSurMapNameIndex( secondWord );

                if( mapIndex >= 0 )
                {
                    nomination_cancel( player_id, mapIndex );

                    LOGGER( 1, "    ( cmd_say ) Just Returning PLUGIN_HANDLED, nomination cancel option chosen." )
                    return PLUGIN_HANDLED;
                }
            }
        }
    }

    LOGGER( 1, "    ( cmd_say ) Just Returning PLUGIN_CONTINUE, as reached the handler end." )
    return PLUGIN_CONTINUE;
}

/**
 * Used to allow the menu nomination_menu(1) to have parameters within a default value.
 * It is because public functions are not allow to have a default value and we need this function
 * be public to allow it to be called from a set_task().
 */
public nomination_menuHook( player_id )
{
    LOGGER( 128, "I AM ENTERING ON nomination_menuHook(1) | currentPage: %d", g_nominationPlayersMenuPages[ player_id ] )
    nomination_menu( player_id );
}

/**
 * Gather all maps that match the nomination.
 */
stock nomination_menu( player_id )
{
    LOGGER( 128, "I AM ENTERING ON nomination_menu(1) | player_id: %d", player_id )

    // Clear the last menu, if exists
    DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )

    new itemsCount;
    new nominationsMapsCount;

    // Start nomination menu variables
    new      mapIndex;
    new bool:isRecentMapNomAllowed;
    new bool:isWhiteListNomBlock;

    new choice        [ MAX_MAPNAME_LENGHT + 32 ];
    new nominationMap [ MAX_MAPNAME_LENGHT ];
    new disabledReason[ MAX_SHORT_STRING ];

    isRecentMapNomAllowed = ( g_recentMapCount
                              && get_pcvar_num( cvar_recentNomMapsAllowance ) == 0 );
    isWhiteListNomBlock   = ( IS_WHITELIST_ENABLED()
                              && IS_TO_HOURLY_LOAD_THE_WHITELIST() );

    // Not loaded?
    if( isWhiteListNomBlock )
    {
        tryToLoadTheWhiteListFeature();
    }
    // end nomination menu variables

    nominationsMapsCount = ArraySize( g_nominationLoadedMapsArray );

    // The first page contains by default the `Cancel All Nominations` option, then the first page
    // will get one less item due the `Cancel All Nominations` option.
    if( g_nominationPlayersMenuPages[ player_id ] == 0 )
    {
        mapIndex   = 0;
        itemsCount = 1;
    }
    else
    {
        mapIndex   = g_nominationPlayersMenuPages[ player_id ] * MAX_NOM_MENU_ITEMS_PER_PAGE - 1;
        itemsCount = 0;
    }

    // Calculate how much pages there are available.
    new currentPageNumber = g_nominationPlayersMenuPages[ player_id ];
    new lastPageNumber    = ( ( ( nominationsMapsCount + 1 ) / MAX_NOM_MENU_ITEMS_PER_PAGE )
                        + ( ( ( ( nominationsMapsCount + 1 ) % MAX_NOM_MENU_ITEMS_PER_PAGE ) > 0 ) ? 1 : 0 ) );

    // To create the menu
#if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES > 0
    formatex( disabledReason, charsmax( disabledReason ),
            IS_COLORED_CHAT_ENABLED() ? "%L\R%d /%d" : "%L  %d /%d",
            player_id, "GAL_LISTMAPS_TITLE", currentPageNumber + 1, lastPageNumber );
#else
    formatex( disabledReason, charsmax( disabledReason ), "%L  %d /%d", player_id, "GAL_LISTMAPS_TITLE",
            currentPageNumber + 1, lastPageNumber );
#endif

    g_generalUsePlayersMenuIds[ player_id ] = menu_create( disabledReason, "nomination_handleMatchChoice" );

    // The first menu item, 'Cancel All Your Nominations.
    if( currentPageNumber < 1 )
    {
        formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_NOM_CANCEL_OPTION" );
        menu_additem( g_generalUsePlayersMenuIds[ player_id ], disabledReason, _, 0 );

        // Add some space from the cancel option.
        // menu_addblank( g_generalUsePlayersMenuIds[ player_id ], 0 );
    }

    // Disables the menu paging.
    menu_setprop( g_generalUsePlayersMenuIds[ player_id ], MPROP_PERPAGE, 0 );

    // Configure the menu buttons.
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_EXITNAME, g_generalUsePlayersMenuIds[ player_id ], "EXIT" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_NEXTNAME, g_generalUsePlayersMenuIds[ player_id ], "MORE" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_BACKNAME, g_generalUsePlayersMenuIds[ player_id ], "BACK" )

    for( ; mapIndex < nominationsMapsCount && itemsCount < MAX_NOM_MENU_ITEMS_PER_PAGE; mapIndex++ )
    {
        ArrayGetString( g_nominationLoadedMapsArray, mapIndex, nominationMap, charsmax( nominationMap ) );
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
            else if( isRecentMapNomAllowed
                     && map_isTooRecent( nominationMap ) )
            {
                formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_TOORECENT" );
            }
            else if( equali( g_currentMapName, nominationMap ) )
            {
                formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_CURRENTMAP" );
            }
            else if( isWhiteListNomBlock
                     && ( ( g_blackListForWhiteListTrie
                            && TrieKeyExists( g_blackListForWhiteListTrie, nominationMap ) )
                          || ( g_whitelistTrie
                               && !TrieKeyExists( g_whitelistTrie, nominationMap ) ) ) )
            {
                formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_WHITELIST" );
            }

            formatex( choice, charsmax( choice ), "%s %s", nominationMap, disabledReason );
            LOGGER( 4, "( nomination_menu ) choice: %s", choice )

            menu_additem( g_generalUsePlayersMenuIds[ player_id ], choice, _,
                    ( disabledReason[ 0 ] == '^0' ? 0 : ( 1 << 26 ) ) );

        } // end the menu entry item calculation.

    } // end for 'mapIndex'.

    LOGGER( 4, "( nominationAttemptWithNamePart ) itemsCount: %d, mapIndex: %d", itemsCount, mapIndex )

    addMenuMoreBackExitOptions( player_id, disabledReason, mapIndex < nominationsMapsCount, currentPageNumber > 0, itemsCount );
    menu_display( player_id, g_generalUsePlayersMenuIds[ player_id ] );
}

/**
 * Used to allow the menu nominationAttemptWithNamePart(2) to have parameters within a default value.
 * It is because public functions are not allow to have a default value and we need this function
 * be public to allow it to be called from a set_task().
 */
public nominationAttemptWithNameHook( parameters[] )
{
    LOGGER( 128, "I AM ENTERING ON nominationAttemptWithNameHook(2) | startSearchIndex: %d", parameters[ 1 ] )
    nominationAttemptWithNamePart( parameters[ 0 ], parameters[ 1 ] );
}

/**
 * Gather all maps that match the g_nominationPartialNameAttempt[ player_id ].
 *
 * @note ( playerName[], &phraseIdx, matchingSegment[] )
 */
stock nominationAttemptWithNamePart( player_id, startSearchIndex = 0 )
{
    LOGGER( 128, "I AM ENTERING ON nominationAttemptWithNamePart(2) | startSearchIndex: %d", startSearchIndex )

    // Clear the last menu, if exists
    DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )

    new matchIndex;
    new itemsCount;
    new nominationsMapsCount;

    // Start nomination menu variables
    new      mapIndex;
    new bool:isRecentMapNomAllowed;
    new bool:isWhiteListNomBlock;

    new choice        [ MAX_MAPNAME_LENGHT + 32 ];
    new nominationMap [ MAX_MAPNAME_LENGHT ];
    new disabledReason[ MAX_SHORT_STRING ];

    isRecentMapNomAllowed = ( g_recentMapCount
                              && get_pcvar_num( cvar_recentNomMapsAllowance ) == 0 );
    isWhiteListNomBlock   = ( IS_WHITELIST_ENABLED()
                              && IS_TO_HOURLY_LOAD_THE_WHITELIST() );

    // Not loaded?
    if( isWhiteListNomBlock )
    {
        tryToLoadTheWhiteListFeature();
    }
    // end nomination menu variables

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
#if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES > 0
    formatex( disabledReason, charsmax( disabledReason ),
            IS_COLORED_CHAT_ENABLED() ? "%L\R%d/%d" : "%L %d /%d",
            player_id, "GAL_LISTMAPS_TITLE", currentPageNumber + 1, lastPageNumber );
#else
    formatex( disabledReason, charsmax( disabledReason ), "%L %d /%d", player_id, "GAL_LISTMAPS_TITLE",
            currentPageNumber + 1, lastPageNumber );
#endif

    g_generalUsePlayersMenuIds[ player_id ] = menu_create( disabledReason, "nomination_handlePartialMatch" );

    // Disables the menu paging.
    menu_setprop( g_generalUsePlayersMenuIds[ player_id ], MPROP_PERPAGE, 0 );

    // Configure the menu buttons.
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_EXITNAME, g_generalUsePlayersMenuIds[ player_id ], "EXIT" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_NEXTNAME, g_generalUsePlayersMenuIds[ player_id ], "MORE" )
    // SET_MENU_LANG_STRING_PROPERTY( MPROP_BACKNAME, g_generalUsePlayersMenuIds[ player_id ], "BACK" )

    for( mapIndex = startSearchIndex; mapIndex < nominationsMapsCount && itemsCount < MAX_NOM_MENU_ITEMS_PER_PAGE; ++mapIndex )
    {
        ArrayGetString( g_nominationLoadedMapsArray, mapIndex, nominationMap, charsmax( nominationMap ) );

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
                else if( isRecentMapNomAllowed
                         && map_isTooRecent( nominationMap ) )
                {
                    formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_TOORECENT" );
                }
                else if( equali( g_currentMapName, nominationMap ) )
                {
                    formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_CURRENTMAP" );
                }
                else if( isWhiteListNomBlock
                         && ( ( g_blackListForWhiteListTrie
                                && TrieKeyExists( g_blackListForWhiteListTrie, nominationMap ) )
                              || ( g_whitelistTrie
                                   && !TrieKeyExists( g_whitelistTrie, nominationMap ) ) ) )
                {
                    formatex( disabledReason, charsmax( disabledReason ), "%L", player_id, "GAL_MATCH_WHITELIST" );
                }

                formatex( choice, charsmax( choice ), "%s %s", nominationMap, disabledReason );
                LOGGER( 4, "( nominationAttemptWithNamePart ) choice: %s", choice )

                menu_additem( g_generalUsePlayersMenuIds[ player_id ], choice, _,
                        ( disabledReason[ 0 ] == '^0' ? 0 : ( 1 << 26 ) ) );

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
                DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )
            }
            case 1:
            {
                // one match?! omg, this is just like awesome
                map_nominate( player_id, matchIndex );

                // Destroys the menu, as is was not used.
                DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )
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
        addMenuMoreBackExitOptions( player_id, disabledReason, mapIndex < nominationsMapsCount, bool:currentPageNumber, itemsCount );

        menu_display( player_id, g_generalUsePlayersMenuIds[ player_id ] );
    }
}

stock addMenuMoreBackExitOptions( player_id, disabledReason[], bool:isToEnableMoreButton, bool:isToEnableBackButton, itemsCount )
{
    LOGGER( 128, "I AM ENTERING ON addMenuMoreBackExitOptions(5) | isToEnableMoreButton: %d, \
            isToEnableBackButton: %d", isToEnableMoreButton, isToEnableBackButton )

    // Force the menu control options to be present on the keys 8 (more), 9 (back) and 0 (exit).
    while( itemsCount < MAX_NOM_MENU_ITEMS_PER_PAGE )
    {
        itemsCount++;
        formatex( disabledReason, MAX_SHORT_STRING - 1, "%L", player_id, "OFF" );
        menu_additem( g_generalUsePlayersMenuIds[ player_id ], disabledReason, _, 1 << 26 );

        // When using slot=1 this might break your menu. To achieve this functionality
        // menu_addblank2() should be used (AMXX 183 only).
        // menu_addblank( g_generalUsePlayersMenuIds[ player_id ], 1 );
    }

    // Add some space from the control options and format the back button within the LANG file.
    menu_addblank( g_generalUsePlayersMenuIds[ player_id ], 0 );
    formatex( disabledReason, MAX_SHORT_STRING - 1, "%L", player_id, "BACK" );

    // If we are on the first page, disable the back option.
    if( isToEnableBackButton )
    {
        menu_additem( g_generalUsePlayersMenuIds[ player_id ], disabledReason, _, 0 );
    }
    else
    {
        menu_additem( g_generalUsePlayersMenuIds[ player_id ], disabledReason, _, 1 << 26 );
    }

    formatex( disabledReason, MAX_SHORT_STRING - 1, "%L", player_id, "MORE" );

    // If there are more maps, add the more option
    if( isToEnableMoreButton )
    {
        menu_additem( g_generalUsePlayersMenuIds[ player_id ], disabledReason, _, 0 );
    }
    else
    {
        menu_additem( g_generalUsePlayersMenuIds[ player_id ], disabledReason, _, 1 << 26 );
    }

    // To add the exit button
    formatex( disabledReason, MAX_SHORT_STRING - 1, "%L", player_id, "EXIT" );
    menu_additem( g_generalUsePlayersMenuIds[ player_id ], disabledReason, _, 0 );
}

/**
 * This menu handler is a little different because it handles two similar menus. The
 * 'nomination_menu(1)' and the 'nominationAttemptWithNamePart(2)'. They would be very similar
 * handlers, then was just build one function instead of two alike.
 */
public nomination_handleMatchChoice( player_id, menu, item )
{
    LOGGER( 128, "I AM ENTERING ON nomination_handleMatchChoice(1) | player_id: %d, menu: %d, item: %d", player_id, menu, item )

    // Let go to destroy the menu and clean some memory. As the menu is not paginated, the item 9
    // is the key 0 on the keyboard. Also, the item 8 is the key 9; 7, 8; 6, 7; 5, 6; 4, 5; etc.
    if( item < 0
        || item == 9 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )

        LOGGER( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, the menu is destroyed." )
        return PLUGIN_HANDLED;
    }

    // Due the first menu option to be 'Cancel all your Nominations', close the menu but if and
    // only if we are on the menu's first page.
    if( item == 0
        && g_nominationPlayersMenuPages[ player_id ] == 0 )
    {
        unnominatedDisconnectedPlayer( player_id );
        DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )

        LOGGER( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, the nominations were cancelled." )
        return PLUGIN_HANDLED;
    }

    // If the 8 button item is hit, and we are not on the first page, we must to perform the back option.
    if( item == 7 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )
        g_nominationPlayersMenuPages[ player_id ] ? g_nominationPlayersMenuPages[ player_id ]-- : player_id;

        // We need to delay the menu show up on 0.2 seconds to avoid players lagging the server by DOS attack.
        set_task( 0.2, "nomination_menuHook", player_id );

        LOGGER( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, doing the back button." )
        return PLUGIN_HANDLED;
    }

    // If the 9 button item is hit, and we are on some page not the last one, we must to perform the more option.
    if( item == 8 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )
        g_nominationPlayersMenuPages[ player_id ]++;

        // We need to delay the menu show up on 0.2 seconds to avoid players lagging the server by DOS attack.
        set_task( 0.2, "nomination_menuHook", player_id );

        LOGGER( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, doing the more button." )
        return PLUGIN_HANDLED;
    }

    // Due the first nomination menu option to be 'Cancel all your Nominations', take one item less 'item - 1'.
    // We are using the 'nomination_menu(1)'
    item = convert_septal_to_decimal( g_nominationPlayersMenuPages[ player_id ] * 10 + item ) - 1;

    map_nominate( player_id, item );
    DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )

    LOGGER( 1, "    ( nomination_handleMatchChoice ) Just Returning PLUGIN_HANDLED, successful nomination." )
    return PLUGIN_HANDLED;
}

public nomination_handlePartialMatch( player_id, menu, item )
{
    LOGGER( 128, "I AM ENTERING ON nomination_handlePartialMatch(1) | player_id: %d, menu: %d, item: %d", player_id, menu, item )

    // Let go to destroy the menu and clean some memory. As the menu is not paginated, the item 9
    // is the key 0 on the keyboard. Also, the item 8 is the key 9; 7, 8; 6, 7; 5, 6; 4, 5; etc.
    if( item < 0
        || item == 9 )
    {
        DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )

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
        DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )

        // We need to delay the menu show up on 0.2 seconds to avoid players lagging the server by DOS attack.
        set_task( 0.2, "nominationAttemptWithNameHook", _, arguments, sizeof arguments );

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
        DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )

        // We need to delay the menu show up on 0.2 seconds to avoid players lagging the server by DOS attack.
        set_task( 0.2, "nominationAttemptWithNameHook", _, arguments, sizeof arguments );

        LOGGER( 1, "    ( nomination_handlePartialMatch ) Just Returning PLUGIN_HANDLED, doing the more button." )
        return PLUGIN_HANDLED;
    }

    // We are using the 'nominationAttemptWithNamePart(2)'
    item = g_menuMapIndexForPlayerArrays[ player_id ][ item ];

    map_nominate( player_id, item );
    DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ player_id ] )

    LOGGER( 1, "    ( nomination_handlePartialMatch ) Just Returning PLUGIN_HANDLED, successful nomination." )
    return PLUGIN_HANDLED;
}

/**
 * Given a number on the base 7, calculates and return the equivalent decimal number (base 10).
 */
stock convert_septal_to_decimal( septal_number )
{
    LOGGER( 128, "I AM ENTERING ON convert_septal_to_decimal(1) | septal_number: %d", septal_number )
    new remainder;

    new decimal = 0;
    new index   = 0;

    while( septal_number != 0 )
    {
        remainder      = septal_number % 10;
        septal_number /= 10;
        decimal       += remainder * power( 7, index );

        ++index;
    }

    LOGGER( 1, "    ( convert_septal_to_decimal ) Returning decimal: %d", decimal )
    return decimal;
}

/**
 * Given a number on the base 8, calculates and return the equivalent decimal number (base 10).
 */
stock convert_octal_to_decimal( octal_number )
{
    LOGGER( 128, "I AM ENTERING ON convert_octal_to_decimal(1) | octal_number: %d", octal_number )
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
    LOGGER( 128, "I AM ENTERING ON nomination_getPlayer(1) | mapIndex: %d", mapIndex )

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
    LOGGER( 0, "I AM ENTERING ON getPlayerNominationMapIndex(2) | player_id: %d, nominationIndex: %d", player_id, nominationIndex )

    new trieKey             [ MAX_NOMINATION_TRIE_KEY_SIZE ];
    new playerNominationData[ MAX_OPTIONS_IN_VOTE ];

    createPlayerNominationKey( player_id, trieKey, charsmax( trieKey ) );

    if( TrieKeyExists( g_forwardSearchNominationsTrie, trieKey ) )
    {
        TrieGetArray( g_forwardSearchNominationsTrie, trieKey, playerNominationData, sizeof playerNominationData );
    }
    else
    {
        LOGGER( 0, "    ( getPlayerNominationMapIndex ) Returning playerNominationData[nominationIndex]: %d", -1 )
        return -1;
    }

    LOGGER( 0, "    ( getPlayerNominationMapIndex ) Returning playerNominationData[nominationIndex]: %d", \
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
    LOGGER( 128, "I AM ENTERING ON setPlayerNominationMapIndex(3) | player_id: %d, nominationIndex: %d, mapIndex: %d", \
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
    LOGGER( 128, "I AM ENTERING ON updateNominationsForwardSearch(3) | player_id: %d, \
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
    LOGGER( 128, "I AM ENTERING ON updateNominationsReverseSearch(4) | player_id: %d, \
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
    LOGGER( 128, "I AM ENTERING ON countPlayerNominations(2) | player_id: %d, openNominationIndex: %d", \
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
    LOGGER( 0, "I AM ENTERING ON createPlayerNominationKey(3) | player_id: %d, trieKeyLength: %d", \
            player_id, trieKeyLength )

    new ipSize;
    ipSize = get_user_ip( player_id, trieKey, trieKeyLength );

    if( !ipSize )
    {
        ipSize += formatex( trieKey[ ipSize ], trieKeyLength - ipSize, "id%d-", player_id );
    }

    get_user_authid( player_id, trieKey[ ipSize ], trieKeyLength - ipSize );
    LOGGER( 0, "( createPlayerNominationKey ) player_id: %d, trieKey: %s,", player_id, trieKey )
}

stock nomination_toggle( player_id, mapIndex )
{
    LOGGER( 128, "I AM ENTERING ON nomination_toggle(2) | player_id: %d, mapIndex: %d", player_id, mapIndex )
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
    LOGGER( 128, "I AM ENTERING ON nomination_cancel(2) | player_id: %d, mapIndex: %d", player_id, mapIndex )

    if( !is_to_block_map_nomination( player_id, {0} ) )
    {
        new mapNominationData[ MapNominationsType ];

        new trieKey[ MAX_NOMINATION_TRIE_KEY_SIZE ];
        new mapName[ MAX_MAPNAME_LENGHT ];

        num_to_str( mapIndex, trieKey, charsmax( trieKey ) );
        ArrayGetString( g_nominationLoadedMapsArray, mapIndex, mapName, charsmax( mapName ) );

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
    LOGGER( 128, "I AM ENTERING ON is_to_block_map_nomination(2) | player_id: %d, mapName: %d", player_id, mapName )

    // nominations can only be made if a vote isn't already in progress
    if( g_voteStatus & VOTE_IS_IN_PROGRESS )
    {
        color_print( player_id, "%L", player_id, "GAL_NOM_FAIL_INPROGRESS" );
        LOGGER( 1, "    ( is_to_block_map_nomination ) Just Returning/blocking, the voting is in progress." )
    }

    // and if the outcome of the vote hasn't already been determined
    else if( g_voteStatus & VOTE_IS_OVER )
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
             && !get_pcvar_num( cvar_recentNomMapsAllowance ) )
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
    LOGGER( 128, "I AM ENTERING ON map_nominate(2) | player_id: %d, mapIndex: %d", player_id, mapIndex )
    new mapName[ MAX_MAPNAME_LENGHT ];

    // get the nominated map name
    ArrayGetString( g_nominationLoadedMapsArray, mapIndex, mapName, charsmax( mapName ) );
    LOGGER( 4, "( map_nominate ) mapIndex: %d, mapName: %s", mapIndex, mapName )

    if( !is_to_block_map_nomination( player_id, mapName ) )
    {
        if( IS_WHITELIST_ENABLED()
            && IS_TO_HOURLY_LOAD_THE_WHITELIST() )
        {
            // Not loaded?
            tryToLoadTheWhiteListFeature();

            if( ( g_blackListForWhiteListTrie
                  && TrieKeyExists( g_blackListForWhiteListTrie, mapName ) )
                || ( g_whitelistTrie
                     && !TrieKeyExists( g_whitelistTrie, mapName ) ) )
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
    LOGGER( 128, "I AM ENTERING ON try_to_add_the_nomination(3) | player_id: %d, mapIndex: %d, mapName: %s", \
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
        ArrayGetString( g_nominationLoadedMapsArray, mapIndex, nominatedMapName, charsmax( nominatedMapName ) );

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
            ArrayGetString( g_nominationLoadedMapsArray, mapIndex, mapName, charsmax( mapName ) );

            if( copiedChars )
            {
                copiedChars += copy( mapsList[ copiedChars ], charsmax( mapsList ) - copiedChars, "^1, ^4" );
            }

            copiedChars += copy( mapsList[ copiedChars ], charsmax( mapsList ) - copiedChars, mapName );

            if( ++nomMapCount == 4 )     // list 4 maps per chat line
            {
                #if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES == 0
                    REMOVE_CODE_COLOR_TAGS( mapsList )
                    color_print( 0, "%L: %s", LANG_PLAYER, "GAL_NOMINATIONS", mapsList );
                #else
                    color_print( 0, "%L: ^4%s", LANG_PLAYER, "GAL_NOMINATIONS", mapsList );
                #endif

                nomMapCount   = 0;
                mapsList[ 0 ] = '^0';
            }
        }
    }

    if( mapsList[ 0 ] )
    {
    #if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES == 0
        REMOVE_CODE_COLOR_TAGS( mapsList )
        color_print( 0, "%L: %s", LANG_PLAYER, "GAL_NOMINATIONS", mapsList );
    #else
        color_print( 0, "%L: ^4%s", LANG_PLAYER, "GAL_NOMINATIONS", mapsList );
    #endif
    }
    else
    {
        color_print( 0, "%L: %L", LANG_PLAYER, "GAL_NOMINATIONS", LANG_PLAYER, "NONE" );
    }
}

stock getSurMapNameIndex( mapSurName[] )
{
    LOGGER( 128, "I AM ENTERING ON getSurMapNameIndex(1) | mapSurName: %s", mapSurName )
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

stock get_realplayersnum()
{
    LOGGER( 0, "I AM ENTERING ON get_realplayersnum(0)" )
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
    LOGGER( 0, "I AM ENTERING ON percent(2) | is: %d, of: %d", is, of )
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
    LOGGER( 128, "I AM ENTERING ON color_print(...) | player_id: %d, message: %s...", player_id, message )
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
#if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES == 0 && AMXX_VERSION_NUM > 182
    vformat( formated_message, charsmax( formated_message ), message, 3 );
    LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, formated_message )

    client_print( player_id, print_chat, formated_message );

#else
    #if AMXX_VERSION_NUM < 183
        if( player_id )
        {
        #if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES > 0
            if( IS_COLORED_CHAT_ENABLED() )
            {
                formated_message[ 0 ] = '^1';
                vformat( formated_message[ 1 ], charsmax( formated_message ) - 1, message, 3 );

                LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, formated_message )
                PRINT_COLORED_MESSAGE( player_id, formated_message )
            }
            else
            {
                vformat( formated_message, charsmax( formated_message ), message, 3 );
                LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, formated_message )

                REMOVE_CODE_COLOR_TAGS( formated_message )
                client_print( player_id, print_chat, formated_message );
            }
        #else
            vformat( formated_message, charsmax( formated_message ), message, 3 );
            LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, formated_message )

            client_print( player_id, print_chat, formated_message );
        #endif
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

            #if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES > 0
                if( IS_COLORED_CHAT_ENABLED() )
                {
                    formated_message[ 0 ] = '^1';
                    vformat( formated_message[ 1 ], charsmax( formated_message ) - 1, message, 3 );

                    LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, formated_message )
                    PRINT_COLORED_MESSAGE( player_id, formated_message )
                }
                else
                {
                    vformat( formated_message, charsmax( formated_message ), message, 3 );
                    LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, formated_message )

                    REMOVE_CODE_COLOR_TAGS( formated_message )
                    client_print( player_id, print_chat, formated_message );
                }
            #else
                vformat( formated_message, charsmax( formated_message ), message, 3 );
                LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, formated_message )

                client_print( player_id, print_chat, formated_message );
            #endif
            }

            ArrayDestroy( multi_lingual_indexes_array );
        }
    #else // this else only works for AMXX 183 or superior, due noted bug above.

        vformat( formated_message, charsmax( formated_message ), message, 3 );
        LOGGER( 64, "( color_print ) [in] player_id: %d, Chat printed: %s...", player_id, formated_message )

        if( IS_COLORED_CHAT_ENABLED() )
        {
            client_print_color( player_id, print_team_default, formated_message );
        }
        else
        {
            REMOVE_CODE_COLOR_TAGS( formated_message )
            client_print( player_id, print_chat, formated_message );
        }
    #endif
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
    LOGGER( 128, "I AM ENTERING ON register_dictionary_colored(1) | dictionaryFile: %s", dictionaryFile )

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
            strtok( currentReadLine[ 1 ], langTypeAcronym, charsmax( langTypeAcronym ), currentReadLine, 1, ']' );
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
            #if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES > 0
                INSERT_COLOR_TAGS( langTranslationText )
            #else
                REMOVE_LETTER_COLOR_TAGS( langTranslationText )
            #endif

                LOGGER( 0, "lang: %s, Id: %d, Text: %s", langTypeAcronym, translationKeyId, langTranslationText )
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
    LOGGER( 128, "I AM ENTERING ON cancelVoting(1) | isToDoubleReset: %d", isToDoubleReset )

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
    remove_task( TASKID_INTERMISSION_HOLD );
    remove_task( TASKID_PROCESS_LAST_ROUND );
    remove_task( TASKID_SHOW_LAST_ROUND_HUD );
    remove_task( TASKID_FINISH_GAME_TIME_BY_HALF );

    finalizeVoting();
    resetRoundEnding();
    delete_users_menus( isToDoubleReset );

    g_voteStatus &= ~VOTE_IS_IN_PROGRESS;
    g_voteStatus &= ~VOTE_IS_FORCED;
    g_voteStatus &= ~VOTE_IS_RUNOFF;

    // g_voteStatus &= ~VOTE_IS_OVER;
    // g_voteStatus &= ~VOTE_IS_EARLY;
    // g_voteStatus &= ~VOTE_IS_EXPIRED;
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
    arrayset( g_arrayOfMapsWithVotesNumber, 0, sizeof g_arrayOfMapsWithVotesNumber );

    if( !( g_voteStatus & VOTE_IS_RUNOFF ) )
    {
        g_totalVoteOptions = 0;
        clearTheVotingMenu();

        arrayset( g_isPlayerParticipating, true, sizeof g_isPlayerParticipating );
    }

    arrayset( g_isPlayerCancelledVote, false, sizeof g_isPlayerCancelledVote );
    arrayset( g_answeredForEndOfMapVote, false, sizeof g_answeredForEndOfMapVote );
    arrayset( g_isPlayerSeeingTheVoteMenu, false, sizeof g_isPlayerSeeingTheVoteMenu );

    arrayset( g_playerVotedOption, 0, sizeof g_playerVotedOption );
    arrayset( g_playerVotedWeight, 0, sizeof g_playerVotedWeight );
}

stock clearTheVotingMenu()
{
    g_totalVoteOptions = 0;

    for( new currentIndex = 0; currentIndex < sizeof g_votingMapNames; ++currentIndex )
    {
        LOGGER( 8, "Cleaning g_votingMapNames[%d]: %s", currentIndex, g_votingMapNames[ currentIndex ] )

        g_votingMapNames [ currentIndex ][ 0 ] = '^0';
        g_arrayOfRunOffChoices[ currentIndex ] = 0;
    }
}

stock delete_users_menus( bool:isToDoubleReset )
{
    LOGGER( 128, "I AM ENTERING ON delete_users_menus(1) | isToDoubleReset: %d", isToDoubleReset )

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

public plugin_end()
{
    LOGGER( 32, "" )
    LOGGER( 32, "" )
    LOGGER( 32, "" )
    LOGGER( 32, "I AM ENTERING ON plugin_end(0). THE END OF THE PLUGIN LIFE!" )

    new currentIndex;
    new gameCrashActionFilePath[ MAX_FILE_PATH_LENGHT ];

    map_restoreEndGameCvars();

    destroy_two_dimensional_array( g_norPlayerFillerMapGroupArrays );
    destroy_two_dimensional_array( g_minPlayerFillerMapGroupArrays );

    // Clean the unit tests data
#if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_MANUAL_TEST_START | DEBUG_LEVEL_UNIT_TEST_DELAYED )
    TRY_TO_APPLY( ArrayDestroy, g_test_idsAndNamesArray )
    TRY_TO_APPLY( ArrayDestroy, g_test_failureIdsArray )
    TRY_TO_APPLY( ArrayDestroy, g_test_failureReasonsArray )
    TRY_TO_APPLY( TrieDestroy, g_test_failureIdsTrie )
#endif

    // Clear Dynamic Arrays
    // ############################################################################################
    TRY_TO_APPLY( ArrayDestroy, g_emptyCycleMapsArray )
    TRY_TO_APPLY( ArrayDestroy, g_nominationLoadedMapsArray )
    TRY_TO_APPLY( ArrayDestroy, g_recentListMapsArray )
    TRY_TO_APPLY( ArrayDestroy, g_whitelistArray )
    TRY_TO_APPLY( ArrayDestroy, g_nominatedMapsArray )

    TRY_TO_APPLY( ArrayDestroy, g_voteMinPlayerFillerPathsArray )
    TRY_TO_APPLY( ArrayDestroy, g_voteNorPlayerFillerPathsArray )
    TRY_TO_APPLY( ArrayDestroy, g_minMaxMapsPerGroupToUseArray )
    TRY_TO_APPLY( ArrayDestroy, g_norMaxMapsPerGroupToUseArray )

    // Clear Dynamic Tries
    // ############################################################################################
    TRY_TO_APPLY( TrieDestroy, g_forwardSearchNominationsTrie )
    TRY_TO_APPLY( TrieDestroy, g_reverseSearchNominationsTrie )
    TRY_TO_APPLY( TrieDestroy, g_whitelistTrie )
    TRY_TO_APPLY( TrieDestroy, g_recentMapsTrie )
    TRY_TO_APPLY( TrieDestroy, g_blackListForWhiteListTrie )
    TRY_TO_APPLY( TrieDestroy, g_nominationLoadedMapsTrie )

    // Clear the dynamic arras, just to be sure.
    for( currentIndex = 0; currentIndex < MAX_PLAYERS_COUNT; ++currentIndex )
    {
        // To clear each one separately to improve the debugging sight.
        TRY_TO_APPLY( ArrayDestroy, g_partialMatchFirstPageItems[ currentIndex ] )
    }

    // Clear the dynamic menus, just to be sure.
    for( currentIndex = 0; currentIndex < MAX_PLAYERS_COUNT; ++currentIndex )
    {
        // To clear each one separately to improve the debugging sight.
        DESTROY_PLAYER_NEW_MENU_TYPE( g_generalUsePlayersMenuIds[ currentIndex ] )
    }

    // Clear game crash action flag file for a new game.
    generateGameCrashActionFilePath( gameCrashActionFilePath, charsmax( gameCrashActionFilePath ) );
    delete_file( gameCrashActionFilePath );
}

/**
 * If the IS_MAP_VALID check failed, check the end of the string for the `.bsp` extension.
 */
stock is_map_valid_bsp_check( mapName[] )
{
    new lenght = strlen( mapName ) - 4;

    // The mapName was too short to possibly house the .bsp extension
    if( lenght < 0 )
    {
        LOGGER( 0, "    ( is_map_valid_bsp_check ) Returning false. [lenght < 0]" )
        return false;
    }

    if( equali( mapName[ lenght ], ".bsp" ) )
    {
        // If the ending was .bsp, then cut it off.
        // As the string is by reference, so this copies back to the loaded text.
        mapName[ lenght ] = '^0';

        // Recheck
        if( is_map_valid( mapName ) )
        {
            LOGGER( 0, "    ( is_map_valid_bsp_check ) Returning true. [is_map_valid]" )
            return true;
        }
    }

    LOGGER( 0, "    ( is_map_valid_bsp_check ) Returning false. " )
    return false;
}



// ################################## AMX MOD X NEXTMAP PLUGIN ###################################

public nextmap_plugin_init()
{
    LOGGER( 128, "I AM ENTERING ON nextmap_plugin_init(0)" )

    pause( "acd", "nextmap.amxx" );
    register_event( "30", "changeMap", "a" );
    register_dictionary( "nextmap.txt" );

    register_clcmd( "say nextmap", "sayNextMap", 0, "- displays nextmap" );
    register_clcmd( "say currentmap", "sayCurrentMap", 0, "- display current map" );

    cvar_amx_nextmap     = register_cvar( "amx_nextmap", "", FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_SPONLY );
    cvar_mp_chattime     = get_cvar_pointer( "mp_chattime" );
    cvar_mp_friendlyfire = get_cvar_pointer( "mp_friendlyfire" );
    cvar_mapcyclefile    = get_cvar_pointer( "mapcyclefile" );

    if( cvar_mp_friendlyfire )
    {
        register_clcmd( "say ff", "sayFFStatus", 0, "- display friendly fire status" );
    }

    loadNextMapPluginSetttings();
}

stock loadNextMapPluginSetttings()
{
    new mapcycleCurrentIndex   [ MAX_MAPNAME_LENGHT ];
    new lastMapcycleFilePath   [ MAX_FILE_PATH_LENGHT ];
    new currentMapcycleFilePath[ MAX_FILE_PATH_LENGHT ];
    new tockenMapcycleAndPosion[ MAX_MAPNAME_LENGHT + MAX_FILE_PATH_LENGHT ];

    get_mapname( g_currentMapName, charsmax( g_currentMapName ) );
    get_pcvar_string( cvar_mapcyclefile, currentMapcycleFilePath, charsmax( currentMapcycleFilePath ) );

    // The from the local info, the map token saved on the last server map.
    get_localinfo( "lastmapcycle", tockenMapcycleAndPosion, charsmax( tockenMapcycleAndPosion ) );

    parse( tockenMapcycleAndPosion, lastMapcycleFilePath, charsmax( lastMapcycleFilePath ),
                                     mapcycleCurrentIndex, charsmax( mapcycleCurrentIndex ) );

    if( !equali( currentMapcycleFilePath, lastMapcycleFilePath ) )
    {
        g_nextMapCyclePosition = 0;    // mapcyclefile has been changed - go from first
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

    // Increments by 1, the global variable 'g_nextMapCyclePosition', or set its to 1.
    readMapCycle( currentMapcycleFilePath, g_nextMapName, charsmax( g_nextMapName ) );
    LOGGER( 2, "( nextmap_plugin_init ) IS CHANGING THE CVAR 'amx_nextmap' to '%s'.", g_nextMapName )

    if( get_pcvar_num( cvar_nextMapChangeAnnounce )
        && get_pcvar_num( cvar_endOfMapVote ) )
    {
        new nextMapName[ 128 ];
        formatex( nextMapName, charsmax( nextMapName ), "%L", LANG_SERVER, "GAL_NEXTMAP_UNKNOWN" );

        REMOVE_CODE_COLOR_TAGS( nextMapName )
        set_pcvar_string( cvar_amx_nextmap, nextMapName );
    }
    else
    {
        set_pcvar_string( cvar_amx_nextmap, g_nextMapName );
    }

    saveCurrentMapCycleSetting( currentMapcycleFilePath );
}

/**
 * The variable 'g_nextMapCyclePosition' is updated also at 'handleServerStart()', to refresh the
 * new settings.
 *
 * @param mapcycleFilePath         the current map-cycle file path.
 */
stock saveCurrentMapCycleSetting( mapcycleFilePath[] )
{
    LOGGER( 128, "I AM ENTERING ON saveCurrentMapCycleSetting(0)" )
    new tockenMapcycleAndPosion[ MAX_MAPNAME_LENGHT + MAX_FILE_PATH_LENGHT ];

    formatex( tockenMapcycleAndPosion, charsmax( tockenMapcycleAndPosion ), "%s %d",
            mapcycleFilePath, g_nextMapCyclePosition );

    // save lastmapcycle settings
    set_localinfo( "lastmapcycle", tockenMapcycleAndPosion );
    set_localinfo( "galileo_lastmap", g_currentMapName );
}

stock getNextMapName( nextMapName[], maxChars )
{
    LOGGER( 128, "I AM ENTERING ON getNextMapName(2) | maxChars: %d", maxChars )
    new lenght = get_pcvar_string( cvar_amx_nextmap, nextMapName, maxChars );

    if( IS_MAP_VALID( nextMapName ) )
    {
        LOGGER( 4, "    ( getNextMapName ) Returning lenght: %d, nextMapName: %s", lenght, nextMapName )
        return lenght;
    }

    lenght = copy( nextMapName, maxChars, g_nextMapName );
    set_pcvar_string( cvar_amx_nextmap, g_nextMapName );

    LOGGER( 2, "( getNextMapName ) IS CHANGING THE CVAR 'amx_nextmap' to '%s'.", g_nextMapName )
    LOGGER( 1, "    ( getNextMapName ) Returning lenght: %d, nextMapName: %s", lenght, nextMapName )
    return lenght;
}

public sayNextMap()
{
    LOGGER( 128, "I AM ENTERING ON sayNextMap(0)" )

    new nextMapName[ MAX_MAPNAME_LENGHT ];
    get_pcvar_string( cvar_amx_nextmap, nextMapName, charsmax( nextMapName ) );

    if( get_pcvar_num( cvar_nextMapChangeAnnounce )
        && get_pcvar_num( cvar_endOfMapVote )
        && !( g_voteStatus & VOTE_IS_OVER ) )
    {
        if( g_voteStatus & VOTE_IS_IN_PROGRESS )
        {
            color_print( 0, "%L %L", LANG_PLAYER, "NEXT_MAP", LANG_PLAYER, "GAL_NEXTMAP_VOTING" );
        }
        else
        {
            color_print( 0, "%L %L", LANG_PLAYER, "NEXT_MAP", LANG_PLAYER, "GAL_NEXTMAP_UNKNOWN" );
        }
    }
    else
    {
    #if IS_TO_ENABLE_THE_COLORED_TEXT_MESSAGES > 0
        color_print( 0, "%L ^4%s", LANG_PLAYER, "NEXT_MAP", nextMapName );
    #else
        color_print( 0, "%L %s", LANG_PLAYER, "NEXT_MAP", nextMapName );
    #endif
    }

    LOGGER( 4, "( sayNextMap ) cvar_endOfMapVote: %d, cvar_nextMapChangeAnnounce: %d", \
            get_pcvar_num( cvar_endOfMapVote ), get_pcvar_num( cvar_nextMapChangeAnnounce ) )

    LOGGER( 1, "    ( sayNextMap ) Just Returning PLUGIN_HANDLED" )
    return PLUGIN_HANDLED;
}

public sayCurrentMap()
{
    LOGGER( 128, "I AM ENTERING ON sayCurrentMap(0)" )
    client_print( 0, print_chat, "%L: %s", LANG_PLAYER, "PLAYED_MAP", g_currentMapName );
}

public sayFFStatus()
{
    LOGGER( 128, "I AM ENTERING ON sayFFStatus(0)" )

    client_print( 0, print_chat, "%L: %L",
            LANG_PLAYER, "FRIEND_FIRE",
            LANG_PLAYER, get_pcvar_num( cvar_mp_friendlyfire ) ? "ON" : "OFF" );
}

public delayedChange( param[] )
{
    LOGGER( 128, "I AM ENTERING ON delayedChange(1) | param: %s", param )

    if( cvar_mp_chattime )
    {
        // It will be a positive value because here we are restoring the increment did on changeMap(0)
        // just below.
        new Float:mp_chattime = get_pcvar_float( cvar_mp_chattime ) - 2.0;

        set_pcvar_float( cvar_mp_chattime, mp_chattime );
        LOGGER( 2, "( delayedChange ) IS CHANGING THE CVAR 'mp_chattime' to '%f'.", get_pcvar_float( cvar_mp_chattime ) )
    }

    serverChangeLevel( param );
}

/**
 * This function call is only triggered by the game event register_event( "30", "changeMap", "a" ).
 */
public changeMap()
{
    LOGGER( 128, "I AM ENTERING ON changeMap(0)" )

    new Float:chattime;
    new nextmap_name[ MAX_MAPNAME_LENGHT ];

    // mp_chattime defaults to 10 in other mods
    chattime = cvar_mp_chattime ? get_pcvar_float( cvar_mp_chattime ) : 10.0;

    if( cvar_mp_chattime )
    {
        // make sure mp_chattime is long
        set_pcvar_float( cvar_mp_chattime, chattime + 2.0 );
        LOGGER( 2, "( changeMap ) IS CHANGING THE CVAR 'mp_chattime' to '%f'.", chattime + 2.0 )
    }

    new lenght = getNextMapName( nextmap_name, charsmax( nextmap_name ) ) + 1;
    set_task( chattime, "delayedChange", 0, nextmap_name, lenght ); // change with 1.5 sec. delay
}

stock bool:isAValidMap( mapname[] )
{
    LOGGER( 128, "I AM ENTERING ON isAValidMap(1) | mapname: %s", mapname )

    if( IS_MAP_VALID( mapname ) )
    {
        LOGGER( 0, "    ( isAValidMap ) Returning true. [IS_MAP_VALID]" )
        return true;
    }

    // If the IS_MAP_VALID check failed, check the end of the string
    new lenght = strlen( mapname ) - 4;

    // The mapname was too short to possibly house the .bsp extension
    if( lenght < 0 )
    {
        LOGGER( 0, "    ( isAValidMap ) Returning false. [lenght < 0]" )
        return false;
    }

    if( equali( mapname[ lenght ], ".bsp" ) )
    {
        // If the ending was .bsp, then cut it off.
        // the string is by reference, so this copies back to the loaded text.
        mapname[ lenght ] = '^0';

        // recheck
        if( IS_MAP_VALID( mapname ) )
        {
            LOGGER( 0, "    ( isAValidMap ) Returning true. [IS_MAP_VALID]" )
            return true;
        }
    }

    LOGGER( 0, "    ( isAValidMap ) Returning false." )
    return false;
}

readMapCycle( mapcycleFilePath[], nextMapName[], nextMapNameMaxchars )
{
    LOGGER( 128, "I AM ENTERING ON readMapCycle(3) | mapcycleFilePath: %s", mapcycleFilePath )
    new textLength;

    new currentReadLine [ MAX_MAPNAME_LENGHT ];
    new firstMapcycleMap[ MAX_MAPNAME_LENGHT ];

    new mapsProcessedNumber    = 0;
    new currentLineToReadIndex = 0;

    if( file_exists( mapcycleFilePath ) )
    {
        while( read_file( mapcycleFilePath, currentLineToReadIndex++, currentReadLine, charsmax( currentReadLine ), textLength ) )
        {
            if( !isAValidMap( currentReadLine ) )
            {
                continue;
            }

            if( !mapsProcessedNumber )
            {
                copy( firstMapcycleMap, charsmax( firstMapcycleMap ), currentReadLine );
            }

            if( ++mapsProcessedNumber > g_nextMapCyclePosition )
            {
                copy( nextMapName, nextMapNameMaxchars, currentReadLine );
                g_nextMapCyclePosition = mapsProcessedNumber;

                LOGGER( 1, "    ( readMapCycle ) Just returning/blocking on 'mapsProcessedNumber > g_nextMapCyclePosition'." )
                return;
            }
        }
    }

    if( mapsProcessedNumber )
    {
        copy( nextMapName, nextMapNameMaxchars, firstMapcycleMap );
    }
    else
    {
        LOGGER( 1, "WARNING: Couldn't find a valid map or the file doesn't exist (file ^"%s^")", mapcycleFilePath )
        log_amx( "WARNING: Couldn't find a valid map or the file doesn't exist (file ^"%s^")", mapcycleFilePath );

        copy( nextMapName, nextMapNameMaxchars, g_currentMapName );
    }

    LOGGER( 4, "( readMapCycle ) | nextMapName: %s, nextMapNameMaxchars: %d", nextMapName, nextMapNameMaxchars )
    g_nextMapCyclePosition = 1;
}



// ################################## BELOW HERE ONLY GOES DEBUG/TEST CODE ###################################
#if DEBUG_LEVEL & DEBUG_LEVEL_FAKE_VOTES
    public create_fakeVotes()
    {
        LOGGER( 128, "I AM ENTERING ON create_fakeVotes(0)" )
        writeToTheDebugFile( DEBUGGER_OUTPUT_LOG_FILE_NAME, "Creating fake votes..." );

        if( g_voteStatus & VOTE_IS_RUNOFF )
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
        g_test_failureIdsArray     = ArrayCreate( 1 );
        g_test_failureReasonsArray = ArrayCreate( MAX_LONG_STRING );
        g_test_idsAndNamesArray    = ArrayCreate( MAX_SHORT_STRING );

        // delay needed to wait the 'server.cfg' run to load its saved cvars
        if( !get_pcvar_num( cvar_isFirstServerStart ) )
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

    #if DEBUG_LEVEL & ( DEBUG_LEVEL_UNIT_TEST_NORMAL | DEBUG_LEVEL_UNIT_TEST_DELAYED )
        saveServerCvarsForTesting();
    #endif

        // Run the normal tests.
    #if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST_NORMAL
        normalTestsToExecute();
    #endif

        // Run the delayed tests.
    #if DEBUG_LEVEL & DEBUG_LEVEL_UNIT_TEST_DELAYED
        g_test_maxDelayResult = 1;
        set_task( 0.5, "dalayedTestsToExecute" );
    #endif

        // Run the manual tests.
    #if DEBUG_LEVEL & DEBUG_LEVEL_MANUAL_TEST_START
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
            print_logger( "    After '%d' runtime seconds... Executing the %s's Unit Tests delayed until at least %d seconds: ",
                                     computeTheTestElapsedTime(),          PLUGIN_NAME,          g_test_maxDelayResult );
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
            new lastFailure      = ( numberOfFailures? ArrayGetCell( g_test_failureIdsArray, numberOfFailures - 1 ) : 0 );

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
                print_logger( "FALILED!" );
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

        new test_name[ MAX_SHORT_STRING ];
        new testsNumber = ArraySize( g_test_idsAndNamesArray );

        print_logger( "" );
        print_logger( "" );
        print_logger( "" );
        print_logger( "    The following tests were executed: " );
        print_logger( "" );

        for( new test_index = 0; test_index < testsNumber; test_index++ )
        {
            ArrayGetString( g_test_idsAndNamesArray, test_index, test_name, charsmax( test_name ) );
            print_logger( "       %3d. %s", test_index + 1, test_name );
        }
    }

    stock print_tests_failure()
    {
        LOGGER( 0, "I AM ENTERING ON print_tests_failure(0)" )

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
        LOGGER( 0, "I AM ENTERING ON setTestFailure(...) | test_id: %d, isFailure: %d, \
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
        LOGGER( 0, "I AM ENTERING ON register_test(2) | max_delay_result: %d, test_name: %s", max_delay_result, test_name )
        ArrayPushString( g_test_idsAndNamesArray, test_name );

        // All the normal Unit Tests will be finished when the Delayed Unit Test begin.
        if( !g_test_maxDelayResult )
        {
            displaysLastTestOk();
        }

        g_test_testsNumber++;
        print_logger( "        EXECUTING TEST %d WITH %d SECONDS DELAY - %s ", g_test_testsNumber, max_delay_result, test_name );

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
     * @param mapFileListPath      the path to the mapFileList.
     * @param mapFileList          the variable number of maps.
     */
    stock helper_mapFileListLoad( mapFileListPath[], ... )
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
            for( currentIndex = 1; currentIndex < argumentsNumber; ++currentIndex )
            {
                stringIndex = 0;

                while( ( currentMap[ stringIndex ] = getarg( currentIndex, stringIndex++ ) ) )
                {
                }

                currentMap[ stringIndex ] = '^0';
                fprintf( fileDescriptor, "%s^n", currentMap );
            }

            fclose( fileDescriptor );
        }
    }

    /**
     * To clear the normal game nominations.
     */
    stock helper_clearNominationsData()
    {
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
    // ###########################################################################################

    /**
     * This is the 'vote_startDirector(1)' tests chain beginning. Because the 'vote_startDirector(1)' cannot
     * to be tested simultaneously. Then, all tests that involves the 'vote_startDirector(1)' chain, must
     * to be executed sequentially after this chain end.
     *
     * This is the 1º chain test.
     *
     * Tests if the cvar 'amx_extendmap_max' functionality is working properly for a successful case.
     */
    stock test_isMapExtensionAvowed_case1()
    {
        new errorMessage[ MAX_LONG_STRING ];

        // Temporarily disables the `gal_nextmap_votemap` feature, as we are not testing it right now.
        set_pcvar_num( cvar_nextMapChangeVotemap, 0 );

        new chainDelay = 2 + 2 + 1 + 1 + 1;
        new test_id    = register_test( chainDelay, "test_isMapExtensionAvowed_case1" );

        set_pcvar_float( cvar_maxMapExtendTime, 20.0 );
        set_pcvar_float( cvar_mp_timelimit, 10.0 );

        vote_startDirector( false );

        formatex( errorMessage, charsmax( errorMessage ), "g_isMapExtensionAllowed must be 1 (it was %d)", g_isMapExtensionAllowed );
        SET_TEST_FAILURE( test_id, !g_isMapExtensionAllowed, errorMessage )

        displaysLastTestOk();
        set_task( 2.0, "test_isMapExtensionAvowed_case2", chainDelay );
    }

    /**
     * This is the 2º test at vote_startDirector() chain.
     *
     * Tests if the cvar 'amx_extendmap_max' functionality is working properly for a failure case.
     */
    public test_isMapExtensionAvowed_case2( chainDelay )
    {
        new errorMessage[ MAX_LONG_STRING ];
        new test_id = register_test( chainDelay, "test_isMapExtensionAvowed_case2" );

        formatex( errorMessage, charsmax( errorMessage ), "g_isMapExtensionAllowed must be 1 (it was %d)", g_isMapExtensionAllowed );
        SET_TEST_FAILURE( test_id, !g_isMapExtensionAllowed, errorMessage )

        color_print( 0, "%L", LANG_PLAYER, "GAL_CHANGE_TIMEEXPIRED" );
        cancelVoting();

        set_pcvar_float( cvar_maxMapExtendTime, 10.0 );
        set_pcvar_float( cvar_mp_timelimit, 20.0 );

        vote_startDirector( false );

        formatex( errorMessage, charsmax( errorMessage ), "g_isMapExtensionAllowed must be 0 (it was %d)", g_isMapExtensionAllowed );
        SET_TEST_FAILURE( test_id, g_isMapExtensionAllowed, errorMessage )

        displaysLastTestOk();
        set_task( 2.0, "test_endOfMapVotingStart_case1", chainDelay );
    }

    /**
     * This is the 3º test at vote_startDirector() chain.
     *
     * Tests if the end map voting is starting automatically at the end of map due time limit expiration.
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

        set_pcvar_float( cvar_mp_timelimit,
                ( get_pcvar_float( cvar_mp_timelimit ) * 60
                  - secondsLeft
                  + START_VOTEMAP_MAX_TIME + 7 )
                / 60 );

        LOGGER( 32, "timelimit: %d", floatround( get_pcvar_float( cvar_mp_timelimit ) * 60 ) )
        LOGGER( 32, "START_VOTEMAP_MIN_TIME: %d", START_VOTEMAP_MIN_TIME )
        LOGGER( 32, "START_VOTEMAP_MAX_TIME: %d", START_VOTEMAP_MAX_TIME )

        displaysLastTestOk();
        set_task( 1.0, "test_endOfMapVotingStart_case2", chainDelay );
    }

    /**
     * This is the 4º test at vote_startDirector() chain.
     *
     * Tests if the end map voting is starting automatically at the end of map due time limit expiration.
     */
    public test_endOfMapVotingStart_case2( chainDelay )
    {
        new test_id = register_test( chainDelay, "test_endOfMapVotingStart_case2" );

        vote_manageEnd();
        SET_TEST_FAILURE( test_id, !( g_voteStatus & VOTE_IS_IN_PROGRESS ), "vote_startDirector() does not started!" )

        set_pcvar_float( cvar_mp_timelimit, 20.0 );
        cancelVoting();

        displaysLastTestOk();
        set_task( 1.0, "test_endOfMapVotingStop_case1", chainDelay );
    }

    /**
     * This is the 5º test at vote_startDirector() chain.
     *
     * Tests if the end map voting is not starting automatically at the end of map due time limit expiration.
     */
    public test_endOfMapVotingStop_case1( chainDelay )
    {
        new test_id = register_test( chainDelay, "test_endOfMapVotingStop_case1" );

        vote_manageEnd();
        SET_TEST_FAILURE( test_id, ( g_voteStatus & VOTE_IS_IN_PROGRESS ) != 0, "vote_startDirector() does started!" )

        set_pcvar_float( cvar_mp_timelimit, 1.0 );
        cancelVoting();

        displaysLastTestOk();
        set_task( 1.0, "test_endOfMapVotingStop_case2", chainDelay );
    }

    /**
     * This is the 6º test at vote_startDirector() chain.
     *
     * Tests if the end map voting is not starting automatically at the end of map due time limit expiration.
     */
    public test_endOfMapVotingStop_case2( chainDelay )
    {
        new test_id = register_test( chainDelay, "test_endOfMapVotingStop_case2" );

        vote_manageEnd();
        SET_TEST_FAILURE( test_id, ( g_voteStatus & VOTE_IS_IN_PROGRESS ) != 0, "vote_startDirector() does started!" )

        set_pcvar_float( cvar_mp_timelimit, 20.0 );
        //cancelVoting();

        displaysLastTestOk();
        //set_task( 1.0, "test_exampleModel_case1", chainDelay );
    }

    /**
     * This is the 7º test at vote_startDirector() chain.
     *
     * Tests if the ... this is model to create new tests. Duplicate this example code and
     * uncomment the test code body and its caller on the last test chain case just above here.
     * You need also to to go the first test and add to the variable 'chainDelay' how much time
     * this and its consecutives tests will take to execute.
     */
    /*public test_exampleModel_case1( chainDelay )
    {
        new test_id = register_test( chainDelay, "test_exampleModel_case1" );

        // Teste coding here...

        // Clear the voting for a new test to begin.
        // cancelVoting();

        // Displays this test OK here, because if it gets until this instruction, it was successful.
        displaysLastTestOk();

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
        client_authorized( 1 );

        formatex( errorMessage, charsmax( errorMessage ), "cvar_isToStopEmptyCycle must be 0 (it was %d)", get_pcvar_num( cvar_isToStopEmptyCycle ) );
        SET_TEST_FAILURE( test_id, get_pcvar_num( cvar_isToStopEmptyCycle ) != 0, errorMessage )

        set_pcvar_num( cvar_isToStopEmptyCycle, 0 );
        client_authorized( 1 );

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

        test_mapGetNext_case( testMapListArray, "de_dust", "de_dust2", 0 );      // case 1
        test_mapGetNext_case( testMapListArray, "de_dust2", "de_inferno", 1 );   // case 2
        test_mapGetNext_case( testMapListArray, "de_inferno", "de_dust4", 2 );   // case 3
        test_mapGetNext_case( testMapListArray, "de_inferno2", "de_dust2", -1 ); // case 4

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
     * This is a configuration loader for the 'loadWhiteListFile(4)' function testing.
     */
    public test_loadCurrentBlackList_load()
    {
        helper_mapFileListLoad
        (
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
            "de_dust13"
        );
    }

    /**
     * To call the general test handler 'test_loadCurrentBlacklist_case(3)' using test scenario cases.
     */
    public test_loadCurrentBlackList_cases()
    {
        test_loadCurrentBlackList_load();

        test_loadCurrentBlacklist_case( 12, "de_dust2", "de_dust7" ); // case 1
        test_loadCurrentBlacklist_case( 23, "de_dust5", "de_dust4" ); // case 2
        test_loadCurrentBlacklist_case( 23, "de_dust7", "de_dust2" ); // case 3
        test_loadCurrentBlacklist_case( 24, "de_dust4", "de_dust1" ); // case 4
        test_loadCurrentBlacklist_case( 23, "de_dust7", "de_dust8" ); // case 5
        test_loadCurrentBlacklist_case( 22, "de_dust8", "de_dust7" ); // case 6
        test_loadCurrentBlacklist_case( 23, "de_dust5", "de_dust1" ); // case 7
        test_loadCurrentBlacklist_case( 23, "de_dust6", "de_dust2" ); // case 8
        test_loadCurrentBlacklist_case( 23, "de_dust7", "de_dust3" ); // case 9
        test_loadCurrentBlacklist_case( 23, "de_dust5", "de_dust4" ); // case 10
        test_loadCurrentBlacklist_case( 2, "de_dust6", "de_dust11" ); // case 11
        test_loadCurrentBlacklist_case( 4, "de_dust13", "de_dust4" ); // case 12
    }

    /**
     * This is a general test handler for the function 'loadWhiteListFile(4)'.
     *
     * @param hour             the current hour.
     * @param map_existent     the map name to exist.
     * @param not_existent     the map name to does not exist.
     */
#if IS_TO_USE_BLACKLIST_INSTEAD_OF_WHITELIST > 0
    stock test_loadCurrentBlacklist_case( hour, not_existent[], map_existent[] )
#else
    stock test_loadCurrentBlacklist_case( hour, map_existent[], not_existent[] )
#endif
    {
        static currentCaseNumber = 0;
        currentCaseNumber++;

        new testName    [ MAX_SHORT_STRING ];
        new errorMessage[ MAX_LONG_STRING ];

        formatex( testName, charsmax( testName ), "test_loadCurrentBlacklist_case%d", currentCaseNumber );
        new test_id = register_test( 0, testName );

        new Trie: blackListTrie      = TrieCreate();
        new Array:whitelistFileArray = ArrayCreate( MAX_LONG_STRING );

        loadWhiteListFileFromFile( whitelistFileArray, g_test_whiteListFilePath );
        loadWhiteListFile( hour, blackListTrie, whitelistFileArray );

        formatex( errorMessage, charsmax( errorMessage ), "The map '%s' must to be present on the trie, but it was not!", map_existent );
        SET_TEST_FAILURE( test_id, !TrieKeyExists( blackListTrie, map_existent ), errorMessage )

        formatex( errorMessage, charsmax( errorMessage ), "The map '%s' must not to be present on the trie, but it was!", not_existent );
        SET_TEST_FAILURE( test_id, TrieKeyExists( blackListTrie, not_existent ), errorMessage )

        TrieDestroy( blackListTrie );
        ArrayDestroy( whitelistFileArray );
    }

    /**
     * To call the general test handler 'test_resetRoundsScores_case(4)' using test scenario cases.
     */
    stock test_resetRoundsScores_cases()
    {
        test_resetRoundsScores_loader( 90, 60, 31, 60  ); // case 1, 90 - 60 + 31 - 1 = 60
        test_resetRoundsScores_loader( 90, 20, 31, 100 ); // case 2, 90 - 20 + 31 - 1 = 100
        test_resetRoundsScores_loader( 20, 15, 11, 15  ); // case 3, 20 - 15 + 11 - 1 = 15
        test_resetRoundsScores_loader( 60, 50, 1, 10 );   // case 4, 60 - 50 + 1  - 1 = 10
        test_resetRoundsScores_loader( 60, 59, 1, 1 );    // case 5, 60 - 59 + 1  - 1 = 1
        test_resetRoundsScores_loader( 60, 60, 1, 60 );   // case 6, 60 - 60 + 1  - 1 = 60
        test_resetRoundsScores_loader( 60, 59, 0, 60 );   // case 7, 60 - 59 + 0  - 1 = 60
        test_resetRoundsScores_loader( 60, 20, 0, 60 );   // case 8, 60 - 20 + 0  - 1 = 60
        test_resetRoundsScores_loader( 60, 80, 10, 60 );  // case 9, 60 - 80 + 10 - 1 = 60
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
        static currentCaseNumber = 0;
        currentCaseNumber++;

        new test_id;
        new testName[ MAX_SHORT_STRING ];

        formatex( testName, charsmax( testName ), "test_resetRoundsScores_case%d", currentCaseNumber );
        test_id  = register_test( 0, testName );

        test_resetRoundsScores_case( test_id, cvar_serverTimeLimitRestart, cvar_mp_timelimit, elapsedValue, aimResult, defaultCvarValue, defaultLimiterValue );
        test_resetRoundsScores_case( test_id, cvar_serverWinlimitRestart,  cvar_mp_winlimit, elapsedValue, aimResult, defaultCvarValue, defaultLimiterValue );
        test_resetRoundsScores_case( test_id, cvar_serverMaxroundsRestart, cvar_mp_maxrounds, elapsedValue, aimResult, defaultCvarValue, defaultLimiterValue );
        test_resetRoundsScores_case( test_id, cvar_serverFraglimitRestart, cvar_mp_fraglimit, elapsedValue, aimResult, defaultCvarValue, defaultLimiterValue );
    }

    /**
     * This is a general test handler for the function 'resetRoundsScores(0)'.
     *
     * @param test_id                 the current case, test identification number.
     * @param limiterCvarPointer      the 'gal_srv_..._restart' pointer
     * @param serverCvarPointer       the game cvar pointer as 'cvar_mp_timelimit'.
     *
     * @note see the stock test_resetRoundsScores_loader(4) for the other parameters.
     */
    stock test_resetRoundsScores_case( test_id, limiterCvarPointer, serverCvarPointer, elapsedValue, aimResult, defaultCvarValue, defaultLimiterValue )
    {
        new changeResult;
        new errorMessage[ MAX_LONG_STRING ];

        g_test_gameElapsedTime = elapsedValue;
        g_totalTerroristsWins  = elapsedValue;
        g_totalCtWins          = elapsedValue;
        g_totalRoundsPlayed   = elapsedValue;
        g_greatestKillerFrags  = elapsedValue;

        set_pcvar_num( limiterCvarPointer, defaultLimiterValue );
        set_pcvar_num( serverCvarPointer, defaultCvarValue );

        // It is expected the 'changeResult' to be 'defaultCvarValue' - 'elapsedValue' + 'defaultLimiterValue' - 1
        resetRoundsScores();
        changeResult = get_pcvar_num( serverCvarPointer );

        formatex( errorMessage, charsmax( errorMessage ), "The aim result '%d' was not achieved! The result was %d.", aimResult, changeResult );
        SET_TEST_FAILURE( test_id, changeResult != aimResult, errorMessage )
    }

    /**
     * This is a configuration loader for the 'loadNormalVoteChoices(0)' function testing.
     */
    stock test_loadVoteChoices_load()
    {
        // Enable all settings
        set_pcvar_string( cvar_voteMapFilePath, g_test_voteMapFilePath );
        set_pcvar_string( cvar_voteWhiteListMapFilePath, g_test_whiteListFilePath );
        set_pcvar_string( cvar_voteMinPlayersMapFilePath, g_test_minPlayersFilePath );

        set_pcvar_num( cvar_whitelistMinPlayers  , 1 );
        set_pcvar_num( cvar_voteMinPlayers       , 1 );
        set_pcvar_num( cvar_isWhiteListNomBlock  , 0 );
        set_pcvar_num( cvar_isWhiteListBlockOut  , 0 );
        set_pcvar_num( cvar_nomMinPlayersControl , 1 );
        set_pcvar_num( cvar_nomPlayerAllowance   , 2 );
        set_pcvar_num( cvar_voteMapChoiceCount   , 5 );
        set_pcvar_num( cvar_nomQtyUsed           , 0 );

        cacheCvarsValues();
    }

    /**
     * To call the general test handler 'test_loadVoteChoices_serie(1)' using test series.
     */
    stock test_loadVoteChoices_cases()
    {
        test_loadVoteChoices_load();

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
            LOGGER( 1, "g_votingMapNames[%d]: %s", currentIndex, g_votingMapNames[ currentIndex ] )
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
                    "The map '%s' %s be present on the voting map menu.", mapToCheck, ( isToBePresent? "must to" : "MUST NOT to" ) );
            SET_TEST_FAILURE( test_id, isMapPresent != isToBePresent, errorMessage )
        }
    }

    /**
     * PART 1: Nominates some maps and create the vote map file and minimum players map file.
     */
    stock test_loadVoteChoices_serie_a()
    {
        helper_loadNominations( "de_rain", "de_inferno", "as_trunda" );

        helper_mapFileListLoad( g_test_voteMapFilePath   , "de_dust1", "de_dust2" );
        helper_mapFileListLoad( g_test_minPlayersFilePath, "de_rain" , "de_nuke" );
        helper_mapFileListLoad( g_test_whiteListFilePath , "[0-23]"  , "de_rain", "de_nuke" );

        // Enables the minimum players feature.
        g_test_aimedPlayersNumber = 0;

        // To force the Whitelist to be reloaded.
        loadMapFiles();
        loadTheWhiteListFeature();
        loadNormalVoteChoices();

        test_loadVoteChoices_case( "de_rain", "de_inferno", 'a' ); // case 1
        test_loadVoteChoices_case( "de_nuke", "as_trunda" );       // case 2
    }

    /**
     * PART 2: Force the minimum players feature to work.
     */
    stock test_loadVoteChoices_serie_b()
    {
        helper_loadNominations( "de_rain", "de_inferno", "as_trunda" );

        helper_mapFileListLoad( g_test_voteMapFilePath   , "de_dust1", "de_dust2" );
        helper_mapFileListLoad( g_test_minPlayersFilePath, "de_rain" , "de_nuke" );
        helper_mapFileListLoad( g_test_whiteListFilePath , "[0-23]"  , "de_rain", "de_nuke" );

        // Disables the minimum players feature.
        g_test_aimedPlayersNumber = 5;

        // To force the Whitelist to be reloaded.
        loadMapFiles();
        loadTheWhiteListFeature();
        loadNormalVoteChoices();

        test_loadVoteChoices_case( "de_rain"   , "de_nuke", 'b' ); // case 1
        test_loadVoteChoices_case( "de_inferno", "de_nuke" );      // case 2
        test_loadVoteChoices_case( "as_trunda" , "de_nuke" );      // case 3
    }

    /**
     * PART 3: Load more maps nominations and disable the minimum players feature.
     */
    stock test_loadVoteChoices_serie_c()
    {
        helper_loadNominations( "de_dust2002v2005_forEver2009", "de_dust2002v2005_forEver2010", "de_dust2002v2005_forEver2011",
                                       "de_dust2002v2005_forEver2012", "de_dust2002v2005_forEver2013", "de_dust2002v2005_forEver2014",
                                       "de_dust2002v2005_forEver2015", "de_dust2002v2005_forEver2016", "de_dust2002v2005_forEver2017" );

        helper_mapFileListLoad( g_test_voteMapFilePath   , "de_dust1", "de_dust2" );
        helper_mapFileListLoad( g_test_minPlayersFilePath, "de_rats" , "de_train" );
        helper_mapFileListLoad( g_test_whiteListFilePath , "[0-23]"  , "de_rats", "de_train" );

        // Enables the minimum players feature.
        g_test_aimedPlayersNumber = 0;

        // To force the Whitelist to be reloaded.
        loadMapFiles();
        loadTheWhiteListFeature();
        loadNormalVoteChoices();

        test_loadVoteChoices_case( "de_rats" , "de_dust2002v2005_forEver2009", 'c' ); // case 1
        test_loadVoteChoices_case( "de_train", "de_dust2002v2005_forEver2010" );      // case 2
        test_loadVoteChoices_case( "de_train", "de_dust2002v2005_forEver2011" );      // case 3
        test_loadVoteChoices_case( "de_rats" , "de_dust2002v2005_forEver2012" );      // case 4
    }

    /**
     * PART 4: Enable the minimum players feature.
     */
    stock test_loadVoteChoices_serie_d()
    {
        helper_loadNominations( "de_rain", "de_inferno", "as_trunda" );

        helper_mapFileListLoad( g_test_voteMapFilePath   , "de_dust1", "de_dust2" );
        helper_mapFileListLoad( g_test_minPlayersFilePath, "de_rain" , "de_nuke" );
        helper_mapFileListLoad( g_test_whiteListFilePath , "[0-23]"  , "de_rain", "de_nuke" );

        // Disables the minimum players feature.
        g_test_aimedPlayersNumber = 5;

        // To force the Whitelist to be reloaded.
        loadMapFiles();
        loadTheWhiteListFeature();
        loadNormalVoteChoices();

        test_loadVoteChoices_case( "de_rain"   , "", 'd' );   // case 1
        test_loadVoteChoices_case( "de_inferno", "de_nuke" ); // case 2
        test_loadVoteChoices_case( "as_trunda" , "de_nuke" ); // case 3
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
        helper_mapFileListLoad( g_test_nomMapFilePath, "de_test_dust1", "de_test_dust2", "de_test_dust3", "de_test_dust4" );
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
     * To test the stock getUniqueRandomIntegers(2).
     */
    stock test_getUniqueRandom_load()
    {
        test_getUniqueRandomInteger( 0  ); // Case 1
        test_getUniqueRandomInteger( 1  ); // Case 2
        test_getUniqueRandomInteger( 30 ); // Case 3
        test_getUniqueRandomInteger( 31 ); // Case 4

        test_getUniqueRandomInteger( 31 ); // Case 5
        test_getUniqueRandomInteger( 30 ); // Case 6
        test_getUniqueRandomInteger( 1  ); // Case 7
        test_getUniqueRandomInteger( 0  ); // Case 8
    }

    stock test_getUniqueRandomInteger( max_value )
    {
        new errorMessage[ MAX_LONG_STRING ];
        new test_id = test_registerSeriesNaming( "test_getUniqueRandomInteger", 'a' );

        new trieSize;
        new sortedInterger;

        new sortedIntergerString[ 6 ];
        new Trie:sortedIntegers = TrieCreate();

        static sequence = -1;
        sequence++;

        for( new index = 0; index < max_value + 3 ; index++ )
        {
            sortedInterger = getUniqueRandomInteger( sequence, max_value );
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
        new const string[] = "ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ ABCDEFGHIJKLMNOPQRSTUVWXZ";

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

        if( !g_test_isTheUnitTestsRunning )
        {
            g_test_isTheUnitTestsRunning = true;

            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "" );
            print_logger( "    Executing the %s's Unit Tests: ", PLUGIN_NAME );
            print_logger( "" );

            cleanTheUnitTestsData();
            saveCurrentTestsTimeStamp();

            get_pcvar_string( cvar_nomMapFilePath, test_nomMapFilePath, charsmax( test_nomMapFilePath ) );
            get_pcvar_string( cvar_voteMapFilePath, test_voteMapFilePath, charsmax( test_voteMapFilePath ) );
            get_pcvar_string( cvar_voteWhiteListMapFilePath, test_voteWhiteListMapFilePath, charsmax( test_voteWhiteListMapFilePath ) );
            get_pcvar_string( cvar_voteMinPlayersMapFilePath, test_voteMinPlayersMapFilePath, charsmax( test_voteMinPlayersMapFilePath ) );

            test_rtvRatio                = get_pcvar_float( cvar_rtvRatio );
            test_extendMapMaximum        = get_pcvar_float( cvar_maxMapExtendTime );
            test_mp_timelimit            = get_pcvar_float( cvar_mp_timelimit     );

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
        }

        LOGGER( 2, "    %38s cvar_mp_timelimit: %f  test_mp_timelimit: %f   g_originalTimelimit: %f", \
                "saveServerCvarsForTesting( out )", get_pcvar_float( cvar_mp_timelimit ), test_mp_timelimit, g_originalTimelimit )
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
            g_test_isTheUnitTestsRunning = false;

            g_originalTimelimit = 0.0;
            g_originalMaxRounds = 0;
            g_originalWinLimit  = 0;
            g_originalFragLimit = 0;

            set_pcvar_string( cvar_nomMapFilePath           , test_nomMapFilePath            );
            set_pcvar_string( cvar_voteMapFilePath          , test_voteMapFilePath           );
            set_pcvar_string( cvar_voteWhiteListMapFilePath , test_voteWhiteListMapFilePath  );
            set_pcvar_string( cvar_voteMinPlayersMapFilePath, test_voteMinPlayersMapFilePath );

            set_pcvar_float( cvar_rtvRatio        , test_rtvRatio );
            set_pcvar_float( cvar_maxMapExtendTime, test_extendMapMaximum );
            set_pcvar_float( cvar_mp_timelimit    , test_mp_timelimit     );

            set_pcvar_num( cvar_mp_winlimit           , test_mp_winlimit            );
            set_pcvar_num( cvar_mp_maxrounds          , test_mp_maxrounds           );
            set_pcvar_num( cvar_mp_fraglimit          , test_mp_fraglimit           );
            set_pcvar_num( cvar_serverTimeLimitRestart, test_serverTimeLimitRestart );
            set_pcvar_num( cvar_serverWinlimitRestart , test_serverWinlimitRestart  );
            set_pcvar_num( cvar_serverMaxroundsRestart, test_serverMaxroundsRestart );
            set_pcvar_num( cvar_serverFraglimitRestart, test_serverFraglimitRestart );

            set_pcvar_num( cvar_whitelistMinPlayers , test_whitelistMinPlayers  );
            set_pcvar_num( cvar_isWhiteListNomBlock , test_isWhiteListNomBlock  );
            set_pcvar_num( cvar_isWhiteListBlockOut , test_isWhiteListBlockOut  );
            set_pcvar_num( cvar_voteMinPlayers      , test_voteMinPlayers       );
            set_pcvar_num( cvar_nomMinPlayersControl, test_NomMinPlayersControl );
            set_pcvar_num( cvar_nomQtyUsed          , test_nomQtyUsed           );
            set_pcvar_num( cvar_voteMapChoiceCount  , test_voteMapChoiceCount   );
            set_pcvar_num( cvar_nomPlayerAllowance  , test_nomPlayerAllowance   );
            set_pcvar_num( cvar_nextMapChangeVotemap, test_nextMapChangeVotemap );
            set_pcvar_num( cvar_endOfMapVoteStart   , test_endOfMapVoteStart    );
        }

        // Clear tests results.
        resetRoundsScores();
        cancelVoting();

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
    }
#endif


