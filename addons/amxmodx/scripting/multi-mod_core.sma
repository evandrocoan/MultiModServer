/*********************** Licensing *******************************************************
 * Multi-Mod Core
 *
 * by Addons zz
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or (at
 *  your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  General Public License for more details.
 *
 *  This plugins was originally written by JoRoPiTo. The original can only load 10 mods and 
 *  display a vote Mod Menu of its 10, does not save the active mod. Now, after lot work, 
 *  it can load until 100 mods and display a vote Mod Menu of its 100 Mods and save the loaded mod.
 *  Original Plugin: "multimod.sma"
 *  https://forums.alliedmods.net/showthread.php?t=95568
 *
 ************************ Introduction ***************************************************
 * How it works? 
 * When remaining 5 minutes to end round, this plugins launches a vote to 
 * choose which mod will be played at the next map. If less than 30% voted, the game keep 
 * the current mod or keep disabled if there is no Mod enabled. The first to options of 
 * the vote menu are: "1. Keep Current Mod" and "2. No mod - Disable Mod". The others are 
 * until 100 Mods loaded from "multimod.ini" file. Beyound 100 this votemenu will not display
 * then, or change de compiler constant "#define MAXMODS 100" inside the plugin.
 * 
 * The "multi-mod_core.sma" Its waits the user choose to activate one Mod, by vote menu, 
 * or by command line. It saves the current active mod and keep it active forever or until 
 * some other mod is activate or your disable the active mod by "amx_multimodz disableMods 1" 
 * command line. 
 * 
 * The "Multi-Mod Core" works completely diffent from the original "MultiMod Manager". 
 * It keeps your original "plugins.ini" and add a new custom set of ones (the Mod) to the 
 * current game without changing the original "plugins.ini".  
 * Its too made the votemod keep the current mod if less than 30% of players voted. 
 * There is compatibility with the (AMXX Team) "multi-mod_mapchooser.sma" replacement previded here. 
 * There is compatibility too, with the the original "galileo.sma":
 * https://forums.alliedmods.net/showthread.php?t=77391
 * 
 *****************************************************************************************
 * Requirements
 * Amx Mod X 1.8.x
 * Tested with Counter-Strike, and it is supposed to work with others mods Amx Mod X
 * 
 * Cvars
 * amx_mintime 10   // Minimum time to play before players can make MOD voting
 * amx_multimod_mode 0   // Compatibility mode 0 [auto] ; 1 [mapachooser_multimod] ; 2 [Galileo]
 * amx_multimod_voteallowed 1   // enable (1) or disable (0) multimod voting.
 * 
 * Commands
 * amx_multimodz      //Command line control of multimod system
 * amx_votemod    //Admin only command to launch MOD & MAP voting
 * say nextmod    //Check which MOD will be running in next map
 * say_team nextmod   //Check which MOD will be running in next map
 * say currentmod     //Check which MOD is running in the current map
 * say votemod      //Player command to launch MOD & MAP voting
 * say_team votemod       //Player command to launch MOD & MAP voting
 * 
 *********************** Deepening ******************************************************
 * 
 * The command "amx_multimodz help 1" display the acceptable inputs and loaded mods 
 * from the file "addons/amxmodx/configs/multimod/multimod.ini". There is 2 built-in operatins 
 * beyond mods activation: "amx_multimodz help 1" and "amx_multimodz disableMods 1". 
 * Respectively to: Shows help and Disable any active mod.
 * 
 * The command line "amx_multimodz help 1", or "amx_multimodz a a", or "amx_multimodz 1 1", 
 * or anything with 2 parameters that are not valid commands, shows help options with 
 * its 2 built-in and all loaded mods from multimod.ini config file.
 * 
 * Example of usage of "amx_multimodz help 1":
 * amx_multimodz help 1
 * amx_multimodz disableMods 1     | To deactivate any loaded mod.
 * amx_votemod    | To force a votemod.
 * say nextmod     | To see which is the next mod.
 * say_team nextmod    | To see which is the next mod.
 * say currentmod    | To see which is the current mod.
 * say votemod     | To try start a vote mod.
 * say_team votemod     | To try start a vote mod.
 * amx_multimodz plugins-shero.txt plugins-shero.cfg    | to use Super Heros
 * amx_multimodz plugins-warcraft.txt plugins-warcraft.cfg    | to use Warcraft Ultimate Mod 3
 * amx_multimodz plugins-predator.txt plugins-predator.cfg    | to use Predator Mod_b2
 * amx_multimodz plugins-knife.txt plugins-knife.cfg    | to use Knife Arena Mod
 * amx_multimodz plugins-zp50Money.txt plugins-zp50Money.cfg    | to use Zombie Money Mod
 * amx_multimodz plugins-zp50Ammo.txt plugins-zp50Ammo.cfg    | to use Zombie Pack Ammo Mod
 * amx_multimodz plugins-csdm.txt plugins-csdm.cfg    | to use CS-DM (DeathMatch)
 * amx_multimodz plugins-gungame.txt plugins-gungame.cfg    | to use Gun Game Mod
 * amx_multimodz plugins-dragon.txt plugins-dragon.cfg    | to use Dragon Ball Mod
 * 
 ********************************** Installation *****************************************
 * To install it:
 * 1. Download the files "multi-mod_core.sma" and "gamemod_resources.zip". Optionally, 
 * "multi-mod_mapchooser.sma" at Downloads section, or the original Galileo.
 * 
 * 2. Then unzip the content of "yourgamemod" from "plugin_resources.zip", to your gamemod folder. 
 * 
 * 3. Compile the files "multi-mod_core.sma" and put the compiled file "multi-mod_core.amxx" to 
 * your plugins folder at "yourgamemod/addons/amxmodx/plugins".
 * 
 * 4. Put the next line to your "plugins.ini" file at "yourgamemod/addons/amxmodx/configs" and 
 * disable the original "mapchooser.amxx":
 * multi-mod_core.amxx
 * 
 * 5. Put the next line to your "amxx.cfg" file at "yourgamemod/addons/amxmodx/configs":
 * exec addons/amxmodx/configs/multiMod.cfg
 * 
 * 6. Configure your own mods at "yourgamemod/addons/amxmodx/configs/multimod/multimod.ini" as 
 * follow:
 * 
 * --- Example of: yourgamemod/addons/amxmodx/configs/multimod/multimod.ini ------
 * 
 * ;[mode name]:[mod tag]:[custom cvars cfg file]
 * [Gun Game]:[gungame]:[plugins-gungame.cfg]
 * 
 * -------------- And you have to create the files:----------------------------
 * 
 * yourgamemod/addons/amxmodx/configs/multimod/mods/plugins-gungame.txt
 * yourgamemod/addons/amxmodx/configs/multimod/mods/plugins-gungame.cfg
 * 
 * (Optinal)
 * yourgamemod/addons/amxmodx/configs/multimod/msg/gungame.cfg
 * yourgamemod/mapcycles/gungame.txt
 * 
 * -------------- Explanations of created files above -------------------------
 * 
 * 1. The file "yourgamemod/mods/plugins-gungame.txt" contains the plugins that compose the Mod.
 * 
 * 2. The file "yourgamemod/mods/plugins-gungame.cfg" contains yours special configuration, like:
 *    amxx pause amx_adminmodel
 *    sv_gravity 850
 * 
 * 3. The file (opcional) "yourgamemod/addons/amxmodx/configs/multimod/msg/gungame.cfg" contains 
 * commands that are executed when a mod is actived by the command line "amx_multimodz". 
 * Usually it contains a command to restart the server, like "amx_countdown 5 restart". 
 * Example of "yourgamemod/addons/amxmodx/configs/multimod/msg/gungame.cfg":
 *    amx_execall speak ambience/ratchant
 *    amx_tsay ocean Zoobie Ammo Pack Mod sera Ativado no proximo restart!!!!
 *    amx_tsay blue Zoobie Ammo Pack Mod sera Ativado no proximo restart!!!!
 *    amx_tsay cyan Zoobie Ammo Pack Mod sera Ativado no proximo restart!!!!
 *    amx_tsay ocean Zoobie Ammo Pack Mod sera Ativado no proximo restart!!!!
 *    amx_countdown 5 restart
 * OBS: 
 * The command "amx_countdown" needs the special plugin called "Countdown Exec" by "SniperBeamer". 
 *    https://forums.alliedmods.net/showthread.php?t=62879
 * The command "amx_execall" needs a special plugins called "Exec" by "ToXiC".
 *    https://forums.alliedmods.net/showthread.php?p=3313
 * 
 * 4. The file (opcional) "yourgamemod/mapcycles/gungame.txt" contains the mapcycle used when 
 * gungame mod is active.
 * 
 * ----------------------- Change Log -----------------------------------------
 * v5.0
 *   Added program code documentation.
 *   Added exception/error handling to everything.
 *   Developed a multi-page votemod menu system to display until 100 mods.
 *   Added a currentmod.ini file to save current active mod id and load it at server start.
 *   Changes the mapcycle, if and only if a custom mod mapcycle was created.
 *   Made the votemod keep the current mod if less than 30% of players voted.
 *   Made "Extend current map" right after choose, not to restart the game at the current map.
 *   Made the "currentmod.ini" store mod ids related to the mods order at "multimod.ini".
 *   Fixed current mod message is displaying "Next Mod: ".
 *   Made "Next Mod: " message display there is no actived mod, when there is not.
 *   When the min vote time is not reached/disabled, display e message informing that.
 * v5.0.0.1
 *   Fixed error message when the vote mod choose keep current mod.
 * v5.0.0.2
 *   Fixed documentation and reformatted a small part of the code.
 * v5.0.1
 *   Improved code using compiler constants with formatex.
 * v6.0
 *   Added new command 'amx_multimods modShortName', to enable/disable any mod, loaded or not, 
 *      straight restarting the server (silent mod).
 *   Added short mod name activation to the command 'amx_multimodz modShortName'.
 *
 * ------------ Credits ------------------------------------------------------
 * 
 *   fysiks: The first to realize the idea of "multimod.sma" and some code improvements.
 *   joropito: The idea/program developer of "multimod.sma" from version v0.1 to v2.3
 *   crazyeffect: Colaborate with multilangual support of "multimod.sma"
 *   dark vador 008: Time and server for testing under czero "multimod.sma"
 *   Addons zz: The "multi-mod_core.sma" developer.
 *   
 * ------------ TODO ----------------------------------------------------------
 * 
 *   
 * 
 ****************************************************************************************
 *
 * For any problems with this plugin visit
 * https://github.com/Addonszz/AddonsMultiMod/issues
 * for support.
 *
 ****************************************************************************************
 */

#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Multi-Mod Core"
#define VERSION "5.0.1"
#define AUTHOR "Addons zz"

#define MULTIMOD_MAPCHOOSER "multi-mod_mapchooser.amxx"
#define TASK_VOTEMOD 2487002
#define TASK_CHVOMOD 2487004
#define MAXMODS 100
#define BIG_STRING 2048
#define LONG_STRING 256
#define SHORT_STRING 64
#define MENU_ITEMS_PER_PAGE    8

// Enables debug server console messages.
new g_is_debug = false

new g_menu_total_pages
new g_menuPosition[33]
new g_menuname[] = "VOTE MOD MENU"
new g_votemodcount[MAXMODS]
new g_modShortName[MAXMODS][SHORT_STRING]// Per-mod short Names
new g_fileMsg[MAXMODS][SHORT_STRING]// Per-mod Mod msg Names
new g_fileCfgs[MAXMODS][SHORT_STRING]// Per-mod Mod cfg Names
new g_modnames[MAXMODS][SHORT_STRING]// Per-mod Mod Names
new g_filemaps[MAXMODS][LONG_STRING]// Per-mod Maps Files
new g_fileplugins[MAXMODS][LONG_STRING]// Per-mod Plugin Files

new g_coloredmenus
new g_modcount = 0 // integer with configured mods count, that is pre increment, so first mod is 1
new g_alreadyvoted
new gp_allowedvote
new g_nextmodid
new g_currentmodid
new g_multimod[SHORT_STRING]
new g_nextmap[SHORT_STRING]
new g_currentmod[SHORT_STRING]
new totalVotes

new gp_mintime
new gp_voteanswers
new gp_timelimit

new gp_mode
new gp_mapcyclefile

new g_alertMultiMod[BIG_STRING] = ";Configuration files of Multi-Mod System^n//\
which is run every time the server starts and defines which mods are enabled.^n//\
This file is managed automatically by multi-mod_core.sma plugin^n//\
and any modification will be discarded in the activation of some mod.^n^n"

new g_helpAmx_multimodz[LONG_STRING] = "help 1           | for help.^n"
new g_helpAmx_multimods[LONG_STRING] = "shortModName 1           | Enable/Disable ^n\
any mod, loaded or not, straight restarting the server (silent mod).^n"

new g_cmdsAvailables1[LONG_STRING] = "^namx_multimodz help 1    | To show this help.^n\
amx_multimodz disableMods 1   | To deactivate any active Mod.^n\
amx_votemod    | To force a votemod.^n\
say nextmod     | To see which is the next mod."

new g_cmdsAvailables2[LONG_STRING] = "say_team nextmod    | To see which is the next mod.^n\
say currentmod    | To see which is the current mod.^n\
say votemod     | To try start a vote mod.^n\
say_team votemod     | To try start a vote mod."

// Contains the address of the configurations folder amx mod x
new g_configFolder[LONG_STRING]

/**
 * Register plugin commands and load configurations.
 */
public plugin_init()
{   
    new MenuName[SHORT_STRING]

    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_cvar("MultiModManager", VERSION, FCVAR_SERVER|FCVAR_SPONLY)
    register_dictionary("mapchooser.txt")
    register_dictionary("multimod.txt")
    //set_localinfo( "isFirstTimeLoadMapCycle", "1" );

    gp_mode = register_cvar("amx_multimod_mode", "0") // 0=auto ; 1=mapchooser ; 2=galileo
    gp_mintime = register_cvar("amx_mintime", "10")
    gp_allowedvote = register_cvar("amx_multimod_voteallowed", "1")

    // Setup folder addresses
    get_configsdir(g_configFolder, charsmax(g_configFolder))

    register_clcmd("amx_votemod", "start_vote", ADMIN_MAP, "Vote for the next mod")
    register_clcmd("say nextmod", "user_nextmod")
    register_clcmd("say_team nextmod", "user_nextmod")
    register_clcmd("say currentmod", "user_currentmod")
    register_clcmd("say_team currentmod", "user_currentmod")
    register_clcmd("say votemod", "user_votemod")
    register_clcmd("say_team votemod", "user_votemod")

    register_concmd("amx_multimodz", "receiveCommand", ADMIN_RCON, g_helpAmx_multimodz )
    register_concmd("amx_multimods", "receiveCommandSilent", ADMIN_RCON, g_helpAmx_multimods )

    formatex(MenuName, charsmax(MenuName), "%L", LANG_PLAYER, "MM_VOTE")
    register_menucmd(register_menuid(g_menuname), BIG_STRING - 1, "player_vote")
    g_coloredmenus = colored_menus()
    totalVotes = 0
    g_nextmodid = 1
}

/**
 * Makes auto configuration about mapchooser plugin, switching between multi-mod_mapchooser and 
 * galileo. 
 * Gets current game mods cvars pointer to this program global variables.
 * Adjust the localinfo variable that store the current mod loaded, reading the current mod file.
 */
public plugin_cfg()
{   
    gp_voteanswers = get_cvar_pointer("amx_vote_answers")
    gp_timelimit = get_cvar_pointer("mp_timelimit")
    gp_mapcyclefile = get_cvar_pointer("mapcyclefile")
    get_localinfo("amx_multimod", g_multimod, charsmax(g_multimod))

    switchMapManager()
    loadCurrentMod()

    if( !gp_allowedvote )
    {
        set_task(15.0, "check_task", TASK_VOTEMOD, "", 0, "b")
    }
}

/**
 * Process the input command "amx_multimodz OPITON1 OPITON2".
 * 
 *  @param id - will hold the players id who started the command
 *  @param level - will hold the access level of the command
 *  @param cid - will hold the commands internal id 
 */
public receiveCommand(id, level, cid)
{   
    //Make sure this user is an admin
    if (!cmd_access(id, level, cid, 3))
    {   
        return PLUGIN_HANDLED
    }
    new Arg1[64]

    //Get the command arguments from the console
    read_argv(1, Arg1, 63)

    if( primitiveFunctions( Arg1, id ) )
    {   
        new modid = getModID( Arg1 )

        if( modid != -1 ) // modid is -1 if it is specified a invalid mod at Arg1 above
        {   
            configureMultimod( modid )
            msgModActivated( modid )

        } else
        {   
            new error[128]="ERROR at receiveCommand!! Mod invalid or a configuration file is missing!"
            printMessage( error, 0 )
            printHelp( id )
        }
    }
    return PLUGIN_HANDLED
}

/**
 * Given a mod short name like "predator", finds its plugins internals mod id.
 * 
 * @param shortName the mod short name.
 */
public getModID( shortName[] )
{   
    for( new modID = 3; modID <= g_modcount; modID++ )
    {   
        if( equal( shortName, g_modShortName[modID] ) )
        {   
            return modID
        }
    }
    return -1
}

/**
 * Check the activation of the function of  disableMods and help.
 *
 * @return true if was not asked for a primitive function, false otherwise.
 */
public primitiveFunctions( Arg1[], id )
{   
    if( equal( Arg1, "disableMods" ) )
    {   
        disableMods()

        printMessage( "The mod will be deactivated at next server restart.", id )
        msgResourceActivated("disableMods")

        return false
    }
    if( equal( Arg1, "help" ) )
    {   
        printHelp( id )
        return false
    }
    return true
}

/**
 * Given a playerd id, prints to him and at server console the help about the command 
 * "amx_multimodz".
 */
public printHelp( id )
{   
    new text[LONG_STRING]

    client_print( id, print_console , g_cmdsAvailables1 )
    client_print( id, print_console , g_cmdsAvailables2 )
    server_print( g_cmdsAvailables1 )
    server_print( g_cmdsAvailables2 )

    for( new i = 3; i <= g_modcount; i++ )
    {   
        formatex( text, charsmax(text), "amx_multimodz %s 1   | to use %s",
                g_modShortName[i], g_modnames[i] )

        client_print( id, print_console , text )
        server_print( text )
    }
    client_print( id, print_console , "^n" )
    server_print( "^n" )
}

/**
 * Process the input command "amx_multimodz OPITON1 OPITON2". 
 * Straight restarting the server, (silent mod) and changes and configures the mapcycle if 
 *   there is one
 * 
 *  @param id - will hold the players id who started the command
 *  @param level - will hold the access level of the command
 *  @param cid - will hold the commands internal id 
 */
public receiveCommandSilent(id, level, cid)
{   
    //Make sure this user is an admin
    if (!cmd_access(id, level, cid, 3))
    {   
        return PLUGIN_HANDLED
    }

    new Arg1[64]

    //Get the command arguments from the console
    read_argv(1, Arg1, 63)

    if( equal( Arg1, "disableMods" ) )
    {   
        disableMods()

        // freeze the game and show the scoreboard
        message_begin(MSG_ALL, SVC_INTERMISSION);
        message_end();

        new mensagem[LONG_STRING]
        formatex( mensagem, charsmax(mensagem), "The mod activate will be deactivated at next \
                server restart.", Arg1 )

        printMessage( mensagem, 0 )
        set_task(5.0, "restartTheServer");

    } else {
        activateModSilent( Arg1 )

        // freeze the game and show the scoreboard
        message_begin(MSG_ALL, SVC_INTERMISSION);
        message_end();

        new mensagem[LONG_STRING]
        formatex( mensagem, charsmax(mensagem), "The mod ( %s ) will be activated at next \
                server restart.", Arg1 )

        printMessage( mensagem, 0 )
        set_task(5.0, "restartTheServer");
    } 

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
 * The 'currentmod.ini' and 'currentmodsilent.ini', at multimod folder, stores the current 
 *   mod actually active and the current mod was activated by silent mode, respectively. 
 * When 'currentmod.ini' stores 0, 'currentmodsilent.ini' defines the current mod. 
 * When 'currentmod.ini' stores anything that is not 0, 'currentmod.ini' defines the current mod.
 */
public loadCurrentMod()
{   
    new currentModFile[LONG_STRING]
    new currentModSilentFile[LONG_STRING]

    new currentModID_String[SHORT_STRING]
    new currentModSilentFile_String[SHORT_STRING]
    new ilen

    formatex(currentModFile, charsmax(currentModFile), "%s/multimod/currentmod.ini", g_configFolder)
    formatex(currentModSilentFile, charsmax(currentModFile), "%s/multimod/currentmodsilent.ini", g_configFolder)

    read_file(currentModFile, 0, currentModID_String, charsmax(currentModID_String), ilen )
    read_file(currentModSilentFile, 0, currentModSilentFile_String, charsmax(currentModSilentFile_String), ilen )

    build_first_mods()
    load_cfg()

    // If -1, there is no mod active. If 0, the current mod was activated by silent mode
    if( !( equal( currentModID_String, "-1" ) || equal( currentModID_String, "0" ) ) )
    {   
        new currentModID = str_to_num( currentModID_String ) + 2
        configureMultimod( currentModID )

    } else if ( equal( currentModID_String, "0" ) )
    {   
        activateModSilent( currentModSilentFile_String )

    } else 
    {
        configureMultimod( 2 )
    }
}

/**
 * Given a modid, salves it to file "currentmod.ini", at multimod folder.
 * 
 * @param the mod id.
 */
saveCurrentMod( modid )
{   
    new modidString[SHORT_STRING]
    new arqCurrentMod[LONG_STRING]

    formatex( arqCurrentMod, charsmax(g_configFolder), "%s/multimod/currentmod.ini", g_configFolder )

    if ( file_exists( arqCurrentMod ) )
    {   
        delete_file( arqCurrentMod )
    }
    modid = modid - 2

    formatex( modidString, charsmax(modidString), "%d", modid )
    write_file( arqCurrentMod, modidString )
}

/**
 *  Saves the current silent mod activated to file "currentmodsilent.ini", at multimod folder.
 *
 * @param Arg1 the mod short name. Ex: surf.
 */
public saveCurrentModSilent( Arg1[] )
{
    new arqCurrentMod[LONG_STRING]

    formatex( arqCurrentMod, charsmax(g_configFolder), "%s/multimod/currentmodsilent.ini", g_configFolder )

    if( file_exists( arqCurrentMod ) )
    {   
        delete_file( arqCurrentMod )
    }
    write_file( arqCurrentMod, Arg1 )
}

/**
 * Set the current game mod and changes the mapcycle, if and only if it was created. 
 * 
 * @param modid the mod index.
 */
public configureMultimod( modid )
{   
    g_currentmodid = modid

    if( modid == 1 ) // "Keep Current Mod", it is necessary when silent mode is used.
    {   
        return
    }
    if( modid == 2 ) // "No mod - Disable Mod", it is necessary at user votes.
    {   
        disableMods()
    }
    if( !( ( modid == 1 ) || ( modid == 2 ) ) )
    {   
        activateMod( modid  )
    }
    configDailyMaps( modid )
    configMapManager( modid )
}

/**
 * Makes at votemod menu, display the first mod as the option: "Keep Current Mod". And at 
 * votemod menu, display the second mod as the option: "No mod - Disable Mod".
 */
public build_first_mods()
{   
    g_modcount++

    formatex( g_modnames[g_modcount], SHORT_STRING - 1, "Keep Current Mod" )
    formatex( g_fileCfgs[g_modcount], SHORT_STRING - 1, "none.cfg" )
    formatex( g_filemaps[g_modcount], SHORT_STRING - 1, "none.txt" )
    formatex( g_fileplugins[g_modcount], SHORT_STRING - 1, "none.txt" )
    formatex( g_fileMsg[g_modcount], SHORT_STRING - 1, "nobe.cfg" )

    g_modcount++

    formatex( g_modnames[g_modcount], SHORT_STRING - 1, "No mod - Disable Mod" )
    formatex( g_fileCfgs[g_modcount], SHORT_STRING - 1, "none.cfg" )
    formatex( g_filemaps[g_modcount], SHORT_STRING - 1, "none.txt" )
    formatex( g_fileplugins[g_modcount], SHORT_STRING - 1, "none.txt" )
    formatex( g_fileMsg[g_modcount], SHORT_STRING - 1, "nobe.cfg" )
}

/**
 * Loads the config file "multimod.ini" and all mods stored there.
 */
public load_cfg()
{   
    g_alreadyvoted = false
    new szData[LONG_STRING]
    new szFilename[LONG_STRING]

    formatex(szFilename, charsmax(szFilename), "%s/multimod/multimod.ini", g_configFolder)

    new f = fopen(szFilename, "rt")
    new szTemp[SHORT_STRING],szModName[SHORT_STRING], szTag[SHORT_STRING], szCfg[SHORT_STRING]

    while(!feof(f))
    {   
        fgets(f, szData, charsmax(szData))
        trim(szData)

        // skip commentaries while reading file
        if(!szData[0] || szData[0] == ';' || (szData[0] == '/' && szData[1] == '/'))
        {   
            continue
        }

        if(szData[0] == '[')
        {   
            g_modcount++

            // remove line delimiters [ and ]
            replace_all(szData, charsmax(szData), "[", "")
            replace_all(szData, charsmax(szData), "]", "")

            //broke the current config line, in modname (szModName), modtag (szTag) 
            //and configfilename (szCfg) (unused)
            strtok(szData, szModName, charsmax(szModName), szTemp, charsmax(szTemp), ':', 0)
            strtok(szTemp, szTag, charsmax(szTag), szCfg, charsmax(szCfg), ':', 0)

            //stores at memory multi-dimensionals arrrays: the cfgfilename, modname, 
            //filemapsname and plugin_modname
            formatex( g_modnames[g_modcount], SHORT_STRING - 1, "%s", szModName )
            formatex( g_modShortName[g_modcount], SHORT_STRING - 1, "%s", szTag )
            formatex( g_fileCfgs[g_modcount], SHORT_STRING - 1, "%s.cfg", szTag )
            formatex( g_filemaps[g_modcount], SHORT_STRING - 1, "%s", mapCyclePathCoder( szTag) )
            formatex( g_fileplugins[g_modcount], SHORT_STRING - 1, "%s.txt", szTag )
            formatex( g_fileMsg[g_modcount], SHORT_STRING - 1, "%s.cfg", szTag )

            if( equal(szModName, g_multimod) )
            {   
                copy(g_currentmod, charsmax(g_currentmod), szModName)
                g_currentmodid = g_modcount

                if( g_is_debug )
                {   
                    server_print("[AMX MultiMod] %L", LANG_PLAYER, "MM_WILL_BE",
                    g_multimod, szTag, szCfg)
                }
            }

            //print at server console each mod loaded
            if( g_is_debug )
            {   
                server_print( "[AMX MOD Loaded] %d %s - %s %s %s %s", g_modcount - 2,
                g_modnames[g_modcount], g_fileplugins[g_modcount], g_fileCfgs[g_modcount],
                g_filemaps[g_modcount], g_fileMsg[g_modcount] )
            }
        }
    }
    fclose(f)
}

/**
 * Gets the first map to load after mod active. If the map file doesn't exist, keep the current 
 * map as the first map to load after mod active.
 */
public get_firstmap(modid)
{   
    new ilen

    if(!file_exists(g_filemaps[modid]))
    {   
        get_mapname(g_nextmap, charsmax(g_nextmap))
    }
    else
    {   
        read_file(g_filemaps[modid], 0, g_nextmap, charsmax(g_nextmap), ilen)
    }
}

/**
 * Makes the autoswitch between mapchooser and galileo. If both are active, prevails galieo.
 */
public switchMapManager()
{   
    if(!get_pcvar_num(gp_mode))
    {   
        if(find_plugin_byfile( MULTIMOD_MAPCHOOSER ) != -1)
        {   
            set_pcvar_num(gp_mode, 1)
        }
        if(find_plugin_byfile( "galileo.amxx" ) != -1)
        {   
            set_pcvar_num(gp_mode, 2)
        }
    }
}

/**
 * Setup the map manager to work with votemod menu.
 */
public configMapManager(modid)
{   
    switch(get_pcvar_num(gp_mode))
    {   
        case 2:
        {   
            new galileo_mapfile = get_cvar_pointer( "gal_vote_mapfile" )

            if( galileo_mapfile )
            {   
                if( file_exists( g_filemaps[modid] ) )
                {   
                    set_pcvar_string( galileo_mapfile, g_filemaps[modid] )
                }
            }
        }
        case 1:
        {   
            if( callfunc_begin("plugin_init", MULTIMOD_MAPCHOOSER ) == 1 )
            {   
                callfunc_end()
            } else
            {   
                new error[128]="ERROR at configMapManager!! MULTIMOD_MAPCHOOSER NOT FOUND!^n"
                client_print( 0, print_console , error )
                server_print( error )
            }
        }
    }
}

/**
 * Setup the map manager to work with votemod menu at Silent mode. That is, configures
 *  the compatibility with galileo, MULTIMOD_MAPCHOOSER and daily_maps, because 
 *  now there is no modid, hence because the mod is not loaded from the mod file configs.
 * 
 * @param Arg1 the mapcycle file name with extension and path. Ex: mapcycles/surf.txt
 */
public configMapManagerSilent( Arg1[] )
{   
    if( file_exists( Arg1 ) )
    {   
        new galileo_mapfile = get_cvar_pointer( "gal_vote_mapfile" )

        if( galileo_mapfile )
        {           
            set_pcvar_string( galileo_mapfile, Arg1 )
        }
    }

    if( callfunc_begin("plugin_init", MULTIMOD_MAPCHOOSER ) == 1 )
    {   
        callfunc_end()
    }
}

/**
 * Hard code the mapcycle file location.
 * 
 * @param Arg1 the mapcycle file name without extension and path. Ex: surf
 *
 * @return the mapcycle file name with extension and path. Ex: mapcycles/surf.txt
 */
public mapCyclePathCoder( Arg1[] )
{   
    new mapcycleTemp[SHORT_STRING]
    formatex( mapcycleTemp, SHORT_STRING - 1, "mapcycles/%s.txt", Arg1 )

    return mapcycleTemp
}

/**
 * Hard code the plugin file location.
 * 
 * @param Arg1 the file name without path. Ex: surf.txt
 *
 * @return the file path with extension. Ex: mapcycles/surf.txt
 */
public filePluginPathCoder( modid )
{   
    new temp[ charsmax( g_configFolder ) + 1 ]
    formatex( temp, charsmax( g_configFolder ),"%s/multimod/plugins/%s", g_configFolder, g_fileplugins[modid] )

    return temp
}

/**
 * Hard code the plugin file location.
 * 
 * @param Arg1 the file name without path. Ex: surf.txt
 *
 * @return the file path with extension. Ex: mapcycles/surf.txt
 */
public fileCFGPathCoder( modid )
{   
    new temp[ charsmax( g_configFolder ) + 1 ]
    formatex( temp, charsmax(g_configFolder), "%s/multimod/cfg/%s", g_configFolder, g_fileCfgs[modid] )

    return temp
}

/**
 * Change the game global variable at localinfo, isFirstTimeLoadMapCycle to 1, after 
 *   the first map load if  there is a game mod mapcycle file. Or to 2 if there is not.
 * The isFirstTimeLoadMapCycle is used by daily_maps.sma to know if there is a 
 *   game mod mapcycle.
 *
 * @param modid current mod id.
 */
public configDailyMaps( modid )
{
    new isFirstTime[32]
    get_localinfo( "isFirstTimeLoadMapCycle", isFirstTime, charsmax( isFirstTime ) );
    new isFirstTimeNum = str_to_num( isFirstTime )

    if( file_exists( g_filemaps[modid] ) )
    {   
        if( isFirstTimeNum  == 0 )
        {
            //server_print("^n^n^n^n^n%d^n^n", isFirstTimeNum)
            set_localinfo( "isFirstTimeLoadMapCycle", "1" );
            set_localinfo( "lastmapcycle", g_filemaps[modid] )
            set_pcvar_string( gp_mapcyclefile, g_filemaps[modid] )
        }
    } else 
    {
        set_localinfo( "isFirstTimeLoadMapCycle", "2" );
    }
}

/**
 * Change the game global variable at localinfo, isFirstTimeLoadMapCycle to 1, after 
 *   the first map load if  there is a game mod mapcycle file. Or to 2 if there is not.
 * The isFirstTimeLoadMapCycle is used by daily_maps.sma to know if there is a 
 *   game mod mapcycle.
 *
 * @param Arg1 the mapcycle file name with extension and path. Ex: mapcycles/surf.txt
 */
public configDailyMapsSilent( Arg1[] )
{
    new isFirstTime[32]
    get_localinfo( "isFirstTimeLoadMapCycle", isFirstTime, charsmax( isFirstTime ) );
    new isFirstTimeNum = str_to_num( isFirstTime )

    if( file_exists( Arg1 ) )
    {   
        if( isFirstTimeNum  == 0 )
        {
            //server_print("^n^n^n^n^n%d^n^n", isFirstTimeNum)
            set_localinfo( "isFirstTimeLoadMapCycle", "1" );
            set_localinfo( "lastmapcycle", Arg1 )
            set_pcvar_string( gp_mapcyclefile, Arg1 )
        }
    } else 
    {
        set_localinfo( "isFirstTimeLoadMapCycle", "2" );
    }
}

/**
 * Deactive any loaded/active mod.
 * 
 * @param id the players id to display the deactivation messages.
 */
public disableMods()
{   
    new currentModShortName[ SHORT_STRING ]
    get_localinfo( "amx_multimod", currentModShortName, charsmax( currentModShortName ) );
    
    new arquivoCurrentModShortName[ LONG_STRING ]
    new arquivoPluginsMulti[LONG_STRING]
    new arquivoCurrentMod[LONG_STRING]
    new arquivoCurrentModSilent[LONG_STRING]
    new configFile[LONG_STRING]

    formatex( arquivoCurrentModShortName, charsmax(g_configFolder), "%s/multimod/latecfg/%.cfg", g_configFolder, currentModShortName )
    formatex( arquivoPluginsMulti, charsmax(g_configFolder), "%s/plugins-multi.ini", g_configFolder )
    formatex( arquivoCurrentMod, charsmax(g_configFolder), "%s/multimod/currentmod.ini", g_configFolder ) 
    formatex( arquivoCurrentModSilent, charsmax(g_configFolder), "%s/multimod/currentmodsilent.ini", g_configFolder )
    formatex( configFile, charsmax(g_configFolder), "%s/multimod/multimod.cfg", g_configFolder )

    if( file_exists( arquivoCurrentModShortName ) )
    {   
        new mensagem[LONG_STRING]
        formatex( mensagem, charsmax(mensagem), "Executing the deactivation mod \
                configuration file ( %s ).", arquivoCurrentModShortName )

        printMessage( mensagem, 0 )
        server_cmd( "exec %s", arquivoCurrentModShortName )
    }

    if( file_exists( arquivoCurrentMod ) )
    {   
        delete_file( arquivoCurrentMod )
    }

    if( file_exists( configFile ) )
    {   
        delete_file( configFile )
    }

    if( file_exists( arquivoCurrentModSilent ) )
    {   
        delete_file( arquivoCurrentModSilent )
    }

    if( file_exists( arquivoPluginsMulti ) )
    {   
        delete_file( arquivoPluginsMulti )
    }

    write_file( configFile, g_alertMultiMod )
    write_file( arquivoPluginsMulti, g_alertMultiMod )
    write_file( arquivoCurrentModSilent, "" )
    write_file( arquivoCurrentMod, "-1" )
}

/**
 * Actives a mod by its configs files.
 * 
 * @param modid the mod id to active.
 *
 * Throws = ERROR !! Any configuration file is missing!
 */
public activateMod( modid )
{   
    new filePluginRead[LONG_STRING]
    new filePluginWrite[LONG_STRING]
    new fileConfigRead[LONG_STRING]
    new fileConfigWrite[LONG_STRING]

    copy( filePluginRead, charsmax(filePluginRead), filePluginPathCoder( modid ) )
    copy( fileConfigRead, charsmax(fileConfigRead), fileCFGPathCoder( modid ) )

    formatex( filePluginWrite, charsmax(filePluginWrite), "%s/plugins-multi.ini", g_configFolder )
    formatex( fileConfigWrite, charsmax(fileConfigWrite), "%s/multimod/multimod.cfg", g_configFolder )

    if( file_exists(filePluginRead) & file_exists(fileConfigRead) )
    {   
        disableMods()

        copyFiles( filePluginRead, filePluginWrite, g_alertMultiMod )
        copyFiles( fileConfigRead, fileConfigWrite, g_alertMultiMod )

        saveCurrentMod( modid )

        server_print( "Setting multimod to %i - %s", modid - 2, g_modnames[modid] )
        set_localinfo( "amx_multimod", g_modShortName[modid] )
    } else
    {   
        new error[128]="ERROR at activateMod!! Mod invalid or a configuration file is missing!"
        printMessage( error, 0 )
    }
}

/**
 * Actives a mod by its configs files silently and straight restat the server. That is, change 
 *   the current mod to 'Keep Current Mod', the active the mods by its file name exists.
 * 
 * @param Arg1 the mod short name to active. Ex: surf
 *
 * Throws = ERROR !! Any configuration file is missing!
 */
public activateModSilent( Arg1[] )
{   
    new filePluginRead[LONG_STRING]
    new filePluginWrite[LONG_STRING]
    new fileConfigRead[LONG_STRING]
    new fileConfigWrite[LONG_STRING]

    formatex( filePluginRead, charsmax(filePluginRead), "%s/multimod/plugins/%s.txt", g_configFolder, Arg1 )
    formatex( fileConfigRead, charsmax(fileConfigRead), "%s/multimod/cfg/%s.cfg", g_configFolder, Arg1 )
    formatex( filePluginWrite, charsmax(filePluginWrite), "%s/plugins-multi.ini", g_configFolder )
    formatex( fileConfigWrite, charsmax(fileConfigWrite), "%s/multimod/multimod.cfg", g_configFolder )

    if( file_exists(filePluginRead) & file_exists(fileConfigRead) )
    {   
        new mapCycleFile[SHORT_STRING] 

        disableMods()

        copyFiles( filePluginRead, filePluginWrite, g_alertMultiMod )
        copyFiles( fileConfigRead, fileConfigWrite, g_alertMultiMod )

        copy( mapCycleFile, charsmax(SHORT_STRING), mapCyclePathCoder( Arg1 ) )
        
        configMapManagerSilent( mapCycleFile )
        configDailyMapsSilent( mapCycleFile )

        g_currentmodid = 1
        saveCurrentMod( 2 )
        saveCurrentModSilent( Arg1 )

        server_print( "Setting multimod to %s", Arg1 )
        set_localinfo( "amx_multimod", Arg1 )
    } else
    {   
        new error[128]="ERROR at activateModSilent!! Mod invalid or a configuration file is missing!"
        printMessage( error, 0 )
    }
}

/**
 * Copy the arquivoFonte to arquivoDestino, replacing the existing file destination and
 * adding to its beginning the contents of the String textoInicial.
 */
public copyFiles( arquivoFonte[], arquivoDestino[], textoInicial[] )
{   
    if ( file_exists( arquivoDestino ) )
    {   
        delete_file( arquivoDestino )
    }
    write_file( arquivoDestino, textoInicial, 0 )

    new arquivoFontePointer = fopen( arquivoFonte, "rt" )
    new Text[512];

    while ( !feof( arquivoFontePointer ) )
    {   
        fgets( arquivoFontePointer, Text, sizeof(Text) - 1 )
        trim(Text)
        write_file( arquivoDestino, Text, -1)
    }
    fclose( arquivoFontePointer )
}

/**
 * Copies the contents of ArquivoFonte to the beginning of arquivoDestino.
 */
public copyFiles2( arquivoFonte[], arquivoDestino[] )
{   
    new arquivoFontePointer = fopen( arquivoFonte, "rt" )
    new Text[512];

    while ( !feof( arquivoFontePointer ) )
    {   
        fgets( arquivoFontePointer, Text, sizeof(Text) - 1 )
        trim(Text)
        write_file( arquivoDestino, Text, -1 )
    }
    fclose( arquivoFontePointer )
}

/**
 * Displays a message to all server players about a command line Mod active with "amx_multimodz".
 * 
 * @param modid the actived mod id.
 */
public msgModActivated( modid )
{   
    new mensagem[LONG_STRING]
    formatex( mensagem, charsmax(mensagem), "The mod ( %s ) will be activated at next server restart.",
    g_modnames[modid] )

    printMessage( mensagem, 0 )
    server_cmd( "exec %s/multimod/msg/%s", g_configFolder, g_fileMsg[modid] )
}

/**
 * Displays a message to all server player about a command line Resource active with "amx_multimodz".
 * 
 * @param nomeDoRecurso the name of the actived resource. OBS: Its must match the file msg 
 *    name at "multimod/msg" folder.
 */
public msgResourceActivated( nomeDoRecurso[] )
{   
    new mensagem[LONG_STRING]
    formatex( mensagem, charsmax(mensagem), "The mod ( %s ) will be activated at next server restart.",
    nomeDoRecurso )

    printMessage( mensagem, 0 )
    server_cmd( "exec %s/multimod/%s.cfg", g_configFolder, nomeDoRecurso )
}

/**
 * Displays a message to a specific server player id.
 */
public printMessage( mensagem[], id )
{   
    client_print( id, print_chat, mensagem )
    client_print( id, print_center , mensagem )
    client_print( id, print_console , mensagem )
    server_print( mensagem )
}

/**
 * Displays a message to a specific server player showing the mod id as the next mod to be loaded.
 * 
 * @param id the player id
 */
public user_nextmod(id)
{   
    client_print(0, print_chat, "%L", LANG_PLAYER, "MM_NEXTMOD", g_modnames[g_nextmodid])
    return PLUGIN_HANDLED
}

/**
 * Displays a message to a specific server player show the mod id as current mod.
 * 
 * @param id the player id
 */
public user_currentmod(id)
{   
    client_print(0, print_chat, "The game current mod is: %s", g_modnames[ g_currentmodid ] )
    return PLUGIN_HANDLED
}

/**
 * Called with "say votemod". Checks:
 *    If users can invoke votation.
 *    If its already voted.
 */
public user_votemod(id)
{   
    if( g_alreadyvoted )
    {   
        client_print(0, print_chat, "%L", LANG_PLAYER, "MM_VOTEMOD", g_modnames[g_nextmodid])
        return PLUGIN_HANDLED
    }
    new Float:elapsedTime = get_pcvar_float(gp_timelimit) - (float(get_timeleft()) / 60.0)
    new Float:minTime
    minTime = get_pcvar_float(gp_mintime)

    if(elapsedTime < minTime)
    {   
        client_print( id, print_chat, "[AMX MultiMod] %L", LANG_PLAYER, "MM_PL_WAIT",
        floatround(minTime - elapsedTime, floatround_ceil) )

        return PLUGIN_HANDLED
    }
    new timeleft = get_timeleft()

    if(timeleft < 180)
    {   
        client_print( id, print_chat, "You can't start a vote mod while the timeleft is %d seconds",
        timeleft )

        return PLUGIN_HANDLED
    }
    start_vote()
    return PLUGIN_HANDLED
}

public check_task()
{   
    new timeleft = get_timeleft()
    if(timeleft < 300 || timeleft > 330)
    {   
        return
    }
    start_vote()
}

/**
 * Start multi mod votation.
 * 
 * If a new votation was invoked:
 *   Restart votation count.
 *   Restart votation players menu position.
 */
public start_vote()
{   
    g_alreadyvoted = true
    remove_task(TASK_VOTEMOD)
    remove_task(TASK_CHVOMOD)

    for( new i = 0; i < 33; i++ )
    {   
        g_menuPosition[i] = 0
    }

    for( new i = 0; i < MAXMODS; i++ )
    {   
        g_votemodcount[i] = 0
    }

    display_votemod_menu( 0, 0 )
    client_cmd(0, "spk Gman/Gman_Choose2")

    if( g_is_debug )
    {   
        set_task( 6.0, "check_vote", TASK_CHVOMOD )
    } else
    {   
        set_task( 30.0, "check_vote", TASK_CHVOMOD )
    }
}

/**
 * Create the vote mod menu multi pages.
 * 
 * @param id the player id to display the menu.
 * @param menu_current_page the number of the current menu page to draw the menu.
 */
public display_votemod_menu( id, menu_current_page )
{   
    if( menu_current_page < 0 )
    {   
        return
    }

    new menu_body[BIG_STRING]
    new menu_valid_keys
    new current_write_position
    new current_page_itens
    new g_menusNumber = g_modcount

    // calc. g_menu_total_pages
    if( ( g_menusNumber % MENU_ITEMS_PER_PAGE ) > 0 )
    {   
        g_menu_total_pages = ( g_menusNumber / MENU_ITEMS_PER_PAGE ) + 1
    } else
    {   
        g_menu_total_pages = ( g_menusNumber / MENU_ITEMS_PER_PAGE )
    }

    // calc. Menu titles
    if( g_coloredmenus )
    {   
        current_write_position = formatex( menu_body, charsmax(menu_body), "\y%L: \R%d/%d\w^n^n",
        LANG_PLAYER, "MM_CHOOSE", menu_current_page + 1, g_menu_total_pages )
    } else
    {   
        current_write_position = formatex( menu_body, charsmax(menu_body), "%L: %d/%d^n^n",
        LANG_PLAYER, "MM_CHOOSE", menu_current_page + 1, g_menu_total_pages )
    }

    // calc. the number of current_page_itens
    if( g_menu_total_pages == menu_current_page + 1 )
    {   
        current_page_itens = g_menusNumber % MENU_ITEMS_PER_PAGE
    } else
    {   
        current_page_itens = MENU_ITEMS_PER_PAGE
    }

    // calc. the current page menu body
    new for_index = 0
    new mod_vote_id

    for( new vote_mod_code = menu_current_page * 10;
    vote_mod_code < menu_current_page * 10 + current_page_itens; vote_mod_code++ )
    {   
        mod_vote_id = convert_octal_to_decimal( vote_mod_code )

        current_write_position += formatex( menu_body[ current_write_position ],
        BIG_STRING - current_write_position , "%d. %s^n", for_index + 1,
        g_modnames[ mod_vote_id + 1] )

        g_votemodcount[ mod_vote_id ] = 0
        for_index++
    }

    // create valid keys ( 0 to 9 )
    menu_valid_keys = MENU_KEY_0
    for( new i = 0; i < 9; i++ )
    {   
        menu_valid_keys |= (1<<i)
    }
    menu_valid_keys |= MENU_KEY_9

    // calc. the final page buttons
    if ( menu_current_page )
    {   
        if( g_menu_total_pages == menu_current_page + 1 )
        {   
            current_write_position += formatex( menu_body[current_write_position],
            BIG_STRING - current_write_position, "^n0. Back" )
        } else
        {   
            current_write_position += formatex( menu_body[current_write_position],
            BIG_STRING - current_write_position, "^n9. More...^n0. Back" )
        }
    } else
    {   
        if( g_menu_total_pages != menu_current_page + 1 )
        {   
            current_write_position += formatex( menu_body[current_write_position],
            BIG_STRING - current_write_position, "^n9. More...^n" )
        }
    }

    if( g_is_debug )
    {   
        new debug_player_name[64]
        get_user_name( id, debug_player_name, 63 )

        server_print( "Player: %s^nMenu body %s ^nMenu name: %s ^nMenu valid keys: %i",
        debug_player_name, menu_body, g_menuname, menu_valid_keys )

        show_menu( id, menu_valid_keys, menu_body, 5, g_menuname )
    } else
    {   
        show_menu( id, menu_valid_keys, menu_body, 25, g_menuname )
    }
}

/**
 * Given a vote_mod_code (octal number), calculates and return the mod internal id 
 * (decimal number).
 */
public convert_octal_to_decimal( octal_number )
{   
    new decimal = 0
    new i = 0
    new remainder

    while( octal_number != 0 )
    {   
        remainder = octal_number % 10
        octal_number /= 10
        decimal += remainder * power(8, i);
        ++i
    }
    return decimal;
}

/**
 * Compute a player mod vote.
 * 
 * @param id the player id
 * @param key the player pressed/option key.
 */
public player_vote(id, key)
{   
    if( g_is_debug )
    {   
        server_print( "Key before switch: %d", key )
    }
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
    if( g_is_debug )
    {   
        server_print( "Key after switch: %d", key )
    }

    if( key == 9 )
    {   
        if( g_menuPosition[id] + 1 != g_menu_total_pages )
        {   
            display_votemod_menu(id, ++g_menuPosition[id])
        } else
        {   
            display_votemod_menu(id, g_menuPosition[id])
        }
    } else
    {   
        if( key == 0 )
        {   
            if( g_menuPosition[id] != 0 )
            {   
                display_votemod_menu(id, --g_menuPosition[id])
            } else
            {   
                display_votemod_menu(id, g_menuPosition[id])
            }
        } else
        {   
            new mod_vote_id = get_mod_vote_id( g_menuPosition[id], key )

            if( mod_vote_id <= g_modcount && get_pcvar_num( gp_voteanswers) )
            {   
                new player[SHORT_STRING]
                new mensagem[LONG_STRING]

                get_user_name(id, player, charsmax(player))
                formatex( mensagem, charsmax(mensagem), "%L", LANG_PLAYER, "X_CHOSE_X", player,
                g_modnames[ mod_vote_id ] )

                client_print( 0, print_chat, mensagem )
                server_print( mensagem )

                g_votemodcount[ mod_vote_id ]++
            } else
            {   
                display_votemod_menu(id, g_menuPosition[id])
            }
        }

    }
}

/**
 * Given a current_menu_page and a current_pressed_key, returns internal the vote mod id.
 * 
 * @param current_menu_page the current page of player vote menu.
 * @param current_pressed_key the key pressed by the player to vote.
 */
public get_mod_vote_id( current_menu_page, current_pressed_key )
{   
    new vote_mod_code = current_menu_page * 10 + current_pressed_key
    new mod_vote_id = convert_octal_to_decimal( vote_mod_code )

    return mod_vote_id
}

/**
 * Start computing the mod votation.
 */
public check_vote()
{   
    new mostVoted = 1

    for(new a = 0; a <= g_modcount; a++)
    {   
        if(g_votemodcount[mostVoted] < g_votemodcount[a])
        {   
            mostVoted = a
        }
        totalVotes = totalVotes + g_votemodcount[a]
    }
    displayVoteResults( mostVoted, totalVotes )
}

/**
 * Calculates the minimum votes required and print to server users the mod voting results.
 * 
 * @param mostVoted most voted mod id.
 * @param totalVotes the number total of votes.
 */
public displayVoteResults( mostVoted, totalVotes )
{   
    new playerMin = playersPlaying( 0.3 )
    server_print( "Total Mod Votes: %d  | Player Min: %d  | Most Voted: %s",
    totalVotes, playerMin, g_modnames[ mostVoted ] )

    if( totalVotes > playerMin )
    {   
        g_nextmodid = mostVoted
        configureMultimod(mostVoted)

        new mensagem[LONG_STRING]
        formatex( mensagem, charsmax(mensagem), "%L", LANG_PLAYER, "MM_VOTEMOD",
        g_modnames[ mostVoted ])

        client_print( 0, print_chat, mensagem )
        server_print( mensagem )

        server_cmd( "exec %s/multimod/votefinished.cfg", g_configFolder )
    } else
    {   
        new mensagem[LONG_STRING]
        formatex( mensagem, charsmax(mensagem), "The vote did not reached the required minimum! \
        The next mod remains: %s", g_modnames[ g_currentmodid ])

        client_print(0, print_chat, mensagem)
        server_print( mensagem )
    }
    totalVotes = 0
}

/**
 * Returns the percent of player playing at game server, skipping bots and spectators.
 * 
 * @param a percent of the total playing players, in decimal. Example for 30%: 0.3
 * 
 * @return an integer of the parameter percent of players
 */
public playersPlaying( Float:percent )
{   
    new players[ 32 ]
    new players_count
    new count = 0

    // get the players in the server skipping bots
    get_players( players, players_count, "c" )

    for( new i = 1; i <= players_count; i++ )
    {   
        switch( get_user_team( i ) )
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
