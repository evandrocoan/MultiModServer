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
 * yourgamemod/mapcycles/gungame.ini
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
 * 4. The file (opcional) "yourgamemod/mapcycles/gungame.ini" contains the mapcycle used when 
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
 * https://github.com/Addonszz/Addons_zz/issues
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
new is_debug = false

new menu_total_pages
new g_menuPosition[33]
new g_menuname[] = "VOTE MOD MENU"
new g_votemodcount[MAXMODS]
new g_fileMsg[MAXMODS][SHORT_STRING]// Per-mod Mod msg Names
new g_fileCfgs[MAXMODS][SHORT_STRING]// Per-mod Mod cfg Names
new g_modnames[MAXMODS][SHORT_STRING]// Per-mod Mod Names
new g_filemaps[MAXMODS][LONG_STRING]// Per-mod Maps Files
new g_fileplugins[MAXMODS][LONG_STRING]// Per-mod Plugin Files

new g_coloredmenus
new g_modcount = 0// integer with configured mods count
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

new alertMultiMod[BIG_STRING] = ";Configuration files of Multi-Mod System^n//\
which is run every time the server starts and defines which mods are enabled.^n//\
This file is managed automatically by multi-mod_core.sma plugin^n//\
and any modification will be discarded in the activation of some mod.^n^n"

new helpAmx_addonszz[LONG_STRING] = "^n^namx_multimodz help 1           | for help.^n^n"

new cmdsAvailables1[LONG_STRING] = "^namx_multimodz help 1    | To show this help.^n\
amx_multimodz disableMods 1   | To deactivate any active Mod.^n\
amx_votemod    | To force a votemod.^n\
say nextmod     | To see which is the next mod."

new cmdsAvailables2[LONG_STRING] = "say_team nextmod    | To see which is the next mod.^n\
say currentmod    | To see which is the current mod.^n\
say votemod     | To try start a vote mod.^n\
say_team votemod     | To try start a vote mod."

// Contains the file which will be saved which mod is activated at boot server
new configFile[LONG_STRING]

// Contains the address of the configurations folder amx mod x
new configFolder[LONG_STRING]

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

    gp_mode = register_cvar("amx_multimod_mode", "0") // 0=auto ; 1=mapchooser ; 2=galileo
    gp_mintime = register_cvar("amx_mintime", "10")
    gp_allowedvote = register_cvar("amx_multimod_voteallowed", "1")

    // Setup folder addresses
    get_configsdir(configFolder, charsmax(configFolder))

    register_clcmd("amx_votemod", "start_vote", ADMIN_MAP, "Vote for the next mod")
    register_clcmd("say nextmod", "user_nextmod")
    register_clcmd("say_team nextmod", "user_nextmod")
    register_clcmd("say currentmod", "user_currentmod")
    register_clcmd("say_team currentmod", "user_currentmod")
    register_clcmd("say votemod", "user_votemod")
    register_clcmd("say_team votemod", "user_votemod")
    register_concmd("amx_multimodz", "receiveCommand", ADMIN_RCON, helpAmx_addonszz )

    formatex(MenuName, charsmax(MenuName), "%L", LANG_PLAYER, "MM_VOTE")
    register_menucmd(register_menuid(g_menuname), BIG_STRING - 1, "player_vote")
    g_coloredmenus = colored_menus()
    totalVotes = 0
    g_nextmodid = 1
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
    new Arg2[64]

    //Get the command arguments from the console
    read_argv(1, Arg1, 63)
    read_argv(2, Arg2, 63)

    if( primitiveFunctions( Arg1, id ) )
    {   
        new modid = getModID( Arg1 )

        if( modid != -1 )
        {   
            set_multimod( modid )
            modActivatedMsg( modid )
        } else
        {   
            new error[128]="^nERROR!! Mod invalid or a configuration file is missing!"
            printMessage( error, 0 )
            printHelp( id )
        }
    }
    return PLUGIN_HANDLED
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
        disableMods( 0 )
        resourceActivatedMsg("disableMods")
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

    client_print( id, print_console , cmdsAvailables1 )
    client_print( id, print_console , cmdsAvailables2 )
    server_print( cmdsAvailables1 )
    server_print( cmdsAvailables2 )

    for( new i = 3; i <= g_modcount; i++ )
    {   
        formatex( text, charsmax(text), "amx_multimodz %s %s    | to use %s",
        g_fileplugins[i], g_fileCfgs[i], g_modnames[i] )

        client_print( id, print_console , text )
        server_print( text )
    }
    client_print( id, print_console , "^n" )
    server_print( "^n" )
}

/**
 * Given a modPluginFile like "plugins-predator.txt", finds its plugins internals mod id.
 */
public getModID( modPluginFile[] )
{   
    new modID = 0

    for(; modID <= g_modcount; modID++ )
    {   
        if( equal( modPluginFile, g_fileplugins[modID] ) )
        {   
            return modID
        }
    }
    return -1
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
 * The currentmod.ini stores the current mod id. If -1 is stored, then there is no mod 
 * actually active.
 */
public loadCurrentMod()
{   
    new currentModFile[LONG_STRING]
    new currentModID_String[SHORT_STRING]
    new ilen

    formatex(currentModFile, charsmax(currentModFile), "%s/multimod/currentmod.ini", configFolder)
    read_file(currentModFile, 0, currentModID_String, charsmax(currentModID_String), ilen )
    build_first_mods()
    load_cfg()

    // if -1, there is no mod active
    if( !equal( currentModID_String, "-1" ) )
    {   
        new currentModID = str_to_num( currentModID_String ) + 2
        set_multimod( currentModID )
    } else
    {   
        set_multimod( 1 )
    }
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
    formatex( g_filemaps[g_modcount], SHORT_STRING - 1, "none.ini" )
    formatex( g_fileplugins[g_modcount], SHORT_STRING - 1, "none.txt" )
    formatex( g_fileMsg[g_modcount], SHORT_STRING - 1, "nobe.cfg" )

    g_modcount++

    formatex( g_modnames[g_modcount], SHORT_STRING - 1, "No mod - Disable Mod" )
    formatex( g_fileCfgs[g_modcount], SHORT_STRING - 1, "none.cfg" )
    formatex( g_filemaps[g_modcount], SHORT_STRING - 1, "none.ini" )
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

    formatex(szFilename, charsmax(szFilename), "%s/multimod/multimod.ini", configFolder)

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
            //and configfilename (szCfg)
            strtok(szData, szModName, charsmax(szModName), szTemp, charsmax(szTemp), ':', 0)
            strtok(szTemp, szTag, charsmax(szTag), szCfg, charsmax(szCfg), ':', 0)

            if( equal(szModName, g_multimod) )
            {   
                copy(g_currentmod, charsmax(g_currentmod), szModName)
                g_currentmodid = g_modcount

                if( is_debug )
                {   
                    server_print("[AMX MultiMod] %L", LANG_PLAYER, "MM_WILL_BE",
                    g_multimod, szTag, szCfg)
                }
            }
            //stores at memory multi-dimensionals arrrays: the cfgfilename, modname, 
            //filemapsname and plugin_modname
            formatex(g_modnames[g_modcount], SHORT_STRING - 1, "%s", szModName)
            formatex(g_fileCfgs[g_modcount], SHORT_STRING - 1, "%s", szCfg)
            formatex(g_filemaps[g_modcount], SHORT_STRING - 1, "mapcycles/%s.ini", szTag)
            formatex(g_fileplugins[g_modcount], SHORT_STRING - 1, "plugins-%s.txt", szTag)
            formatex(g_fileMsg[g_modcount], SHORT_STRING - 1, "%s.cfg", szTag)

            //print at server console each mod loaded
            if( is_debug )
            {   
                server_print( "[AMX MOD Loaded] %d %s - %s %s %s %s", g_modcount - 2,
                g_modnames[g_modcount], g_fileplugins[g_modcount], g_fileCfgs[g_modcount],
                g_filemaps[g_modcount], g_fileMsg[g_modcount] )
            }
        }
    }
    fclose(f)
    set_task(10.0, "check_task", TASK_VOTEMOD, "", 0, "b")
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
 * Set the current game mod and changes the mapcycle, if and only if it was created.
 * 
 * @param modid the mod index.
 */
public set_multimod(modid)
{   
    g_currentmodid = modid

    if( modid == 1 ) // "Keep Current Mod"
    {   
        return
    }
    if( modid == 2 ) // "No mod - Disable Mod"
    {   
        disableMods( 0 )
    }
    if( !( ( modid == 1 ) || ( modid == 2 ) ) )
    {   
        server_print( "Setting multimod to %i - %s", modid - 2, g_modnames[modid] )
        set_localinfo( "amx_multimod", g_modnames[modid] )
        activateMod( g_fileplugins[modid], g_fileCfgs[modid], alertMultiMod )

        if( file_exists( g_filemaps[modid] ) )
        {   
            set_localinfo( "lastmapcycle", g_filemaps[modid] )
            set_pcvar_string( gp_mapcyclefile, g_filemaps[modid] )
        }
        configMapManager( modid )
    }
}

/**
 * Given a modid, salves it to file "currentmod.ini".
 */
saveCurrentMod( modid )
{   
    new modidString[SHORT_STRING]
    new arqCurrentMod[LONG_STRING]

    formatex( arqCurrentMod, charsmax(configFolder), "%s/multimod/currentmod.ini", configFolder )

    if ( file_exists( arqCurrentMod ) )
    {   
        delete_file( arqCurrentMod )
    }
    modid = modid - 2

    formatex( modidString, charsmax(modidString), "%d", modid )
    write_file( arqCurrentMod, modidString )
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
                new error[128]="^nERROR!! MULTIMOD_MAPCHOOSER NOT FOUND!^n"
                client_print( 0, print_console , error )
                server_print( error )
            }
        }
    }
}

/**
 * Deactive any loaded/active mod.
 * 
 * @param id the players id to display the deactivation messages.
 */
public disableMods( id )
{   
    new arquivoPluginsMulti[LONG_STRING]
    new arquivoCurrentMod[LONG_STRING]

    formatex( arquivoPluginsMulti, charsmax(configFolder), "%s/plugins-multi.ini", configFolder )
    formatex( arquivoCurrentMod, charsmax(configFolder), "%s/multimod/currentmod.ini", configFolder )
    formatex( configFile, charsmax(configFolder), "%s/multiMod.cfg", configFolder )

    if( file_exists( arquivoCurrentMod ) )
    {   
        delete_file( arquivoCurrentMod )
    }
    if( file_exists( configFile ) )
    {   
        delete_file( configFile )
    }
    if( file_exists( arquivoPluginsMulti ) )
    {   
        delete_file( arquivoPluginsMulti )
    }
    write_file( configFile, alertMultiMod )
    write_file( arquivoPluginsMulti, alertMultiMod )
    write_file( arquivoCurrentMod, "-1" )

    printMessage( "The mod will be deactived at next server restart.", id )
}

/**
 * Actives a mod by its configs files.
 * 
 * @param ArqPlugin the file containing the original plugin to be installed.
 * @param ArqConfig the file that contains the special plugin settings being activated.
 * @param Alert the message will be written at the beginning of the plugin file and configuration.
 *
 * Throws = ERROR !! Any configuration file is missing!
 */
public activateMod( arqPlugin[], arqConfig[], alerta[] )
{   
    new filePluginRead[LONG_STRING]
    new filePluginWrite[LONG_STRING]
    new fileConfigRead[LONG_STRING]
    new fileConfigWrite[LONG_STRING]

    formatex( filePluginRead, charsmax(configFolder), "%s/multimod/mods/%s", configFolder, arqPlugin )
    formatex( fileConfigRead, charsmax(configFolder), "%s/multimod/mods/%s", configFolder, arqConfig )
    formatex( filePluginWrite, charsmax(configFolder), "%s/plugins-multi.ini", configFolder )
    formatex( fileConfigWrite, charsmax(configFolder), "%s/multiMod.cfg", configFolder )

    if( file_exists(filePluginRead) & file_exists(fileConfigRead)
    & file_exists(filePluginWrite) & file_exists(fileConfigWrite) )
    {   
        copyFiles( filePluginRead, filePluginWrite, alerta )
        copyFiles( fileConfigRead, fileConfigWrite, alerta )
        saveCurrentMod( g_currentmodid )
    } else
    {   
        new error[128]="ERROR!! Some config file is missing!"
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
public modActivatedMsg( modid )
{   
    new mensagem[LONG_STRING]
    formatex( mensagem, charsmax(mensagem), "The mod ( %s ) will be actived at next server restart.",
    g_modnames[modid] )

    printMessage( mensagem, 0 )
    server_cmd( "exec %s/multimod/msg/%s", configFolder, g_fileMsg[modid] )
}

/**
 * Displays a message to all server player about a command line Resource active with "amx_multimodz".
 * 
 * @param nomeDoRecurso the name of the actived resource. OBS: Its must match the file msg 
 *    name at "multimod/msg" folder.
 */
public resourceActivatedMsg( nomeDoRecurso[] )
{   
    new mensagem[LONG_STRING]
    formatex( mensagem, charsmax(mensagem), "The mod ( %s ) will be actived at next server restart.",
    nomeDoRecurso )

    printMessage( mensagem, 0 )
    server_cmd( "exec %s/multimod/msg/%s.cfg", configFolder, nomeDoRecurso )
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
    if( !gp_allowedvote )
    {   
        client_print( id, print_chat, "Vote mod is currently disabled!" )
        return PLUGIN_HANDLED
    }
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
    if(timeleft < 120 || timeleft > 380)
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

    if( is_debug )
    {   
        set_task( 6.0, "check_vote", TASK_CHVOMOD )
    } else
    {   
        set_task( 65.0, "check_vote", TASK_CHVOMOD )
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

    // calc. menu_total_pages
    if( ( g_menusNumber % MENU_ITEMS_PER_PAGE ) > 0 )
    {   
        menu_total_pages = ( g_menusNumber / MENU_ITEMS_PER_PAGE ) + 1
    } else
    {   
        menu_total_pages = ( g_menusNumber / MENU_ITEMS_PER_PAGE )
    }

    // calc. Menu titles
    if( g_coloredmenus )
    {   
        current_write_position = formatex( menu_body, charsmax(menu_body), "\y%L: \R%d/%d\w^n^n",
        LANG_PLAYER, "MM_CHOOSE", menu_current_page + 1, menu_total_pages )
    } else
    {   
        current_write_position = formatex( menu_body, charsmax(menu_body), "%L: %d/%d^n^n",
        LANG_PLAYER, "MM_CHOOSE", menu_current_page + 1, menu_total_pages )
    }

    // calc. the number of current_page_itens
    if( menu_total_pages == menu_current_page + 1 )
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
        if( menu_total_pages == menu_current_page + 1 )
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
        if( menu_total_pages != menu_current_page + 1 )
        {   
            current_write_position += formatex( menu_body[current_write_position],
            BIG_STRING - current_write_position, "^n9. More...^n" )
        }
    }

    if( is_debug )
    {   
        new debug_player_name[64]
        get_user_name( id, debug_player_name, 63 )

        server_print( "Player: %s^nMenu body %s ^nMenu name: %s ^nMenu valid keys: %i",
        debug_player_name, menu_body, g_menuname, menu_valid_keys )

        show_menu( id, menu_valid_keys, menu_body, 5, g_menuname )
    } else
    {   
        show_menu( id, menu_valid_keys, menu_body, 60, g_menuname )
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
    if( is_debug )
    {   
        server_print( "Key before switch: %d", key )
    }
    /* 
     * Well, I dont know why, but it doesnt even matter, how hard you try...
     * You press the key 0, you gets 9 here.
     * You press the key 1, you gets 0 here.
     * You press the key 2, you gets 1 here.
     * You press the key 3, you gets 2 here.
     * You press the key 4, you gets 3 here.
     * You press the key 5, you gets 4 here.
     * You press the key 6, you gets 5 here.
     * You press the key 7, you gets 6 here.
     * You press the key 8, you gets 7 here.
     * You press the key 9, you gets 8 here.
     * So here, i made the switch back.
     */
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
    if( is_debug )
    {   
        server_print( "Key after switch: %d", key )
    }

    if( key == 9 )
    {   
        if( g_menuPosition[id] + 1 != menu_total_pages )
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
        set_multimod(mostVoted)

        new mensagem[LONG_STRING]
        formatex( mensagem, charsmax(mensagem), "%L", LANG_PLAYER, "MM_VOTEMOD",
        g_modnames[ mostVoted ])

        client_print( 0, print_chat, mensagem )
        server_print( mensagem )
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
