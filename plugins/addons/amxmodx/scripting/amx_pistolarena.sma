/**************************************************************
*
*   Insane Pistol Arena X - By Knekter
*   Copyright (C) 2004, MCProductions
*
***************************************************************
*
*   I. INTRODUCTION
*
*   Insane pistol arena was first created by me over a year
*   ago.  Once steam came out I grew tired of making plugins
*   and I stopped playing HL all together.  Soon after Valve
*   took WON down and CS 1.5 was lost all together.  I
*   decided that it was time for a change and I came back
*   and started playing again.  It wasn't as bad as I thought.
*   Now im scripting again and I decided to fix this plugin
*   so it would be more efficient with less code.  I hope
*   you like what I have done!
*
***************************************************************
*
*   II. USAGE
*
*   To start the pistol arena you need to have at least
*   ADMIN_SLAY capabilities.  Once you are ready to start
*   simply type in the console 'amx_pistolarena on' and the
*   plugin will do the rest.  To turn the plugin off type
*   in the console 'amx_pistolarena off'.  To change the fun
*   functions of the plugins refer to the CVARS below.
*
***************************************************************
*
*   III. CVARS
*
*   amx_pistolarena_glow        <1=on/0=off>
*   amx_pistolarena_armor       <0 to 500>
*   amx_pistolarena_health      <100 to 250>
*   amx_pistolarena_gravity     <1 to 800>
*   amx_pistolarena_maxspeed    <320 to 700>
*
***************************************************************
*
*   IV. REQUIREMENTS
*
*   This plugin requires the fun and cstrike module to be
*   running on your server.
*
***************************************************************
*
*   V. INCLUDES STRINGS AND VARIABLES
*
***************************************************************/

#include <amxmodx>
#include <cstrike>
#include <fun>


new PLUGIN[]    =   "Insane Pistol Arena X"
new AUTHOR[]    =   "Knekter"
new VERSION[]   =   "0.5"

new GLOW[]      =   "amx_pistolarena_glow"
new ARMOR[]     =   "amx_pistolarena_armor"
new HEALTH[]    =   "amx_pistolarena_health"
new GRAVITY[]   =   "amx_pistolarena_gravity"
new MAXSPEED[]  =   "amx_pistolarena_maxspeed"

new bool:gArena = false

/**************************************************************
*
*   VI. ENJOY!
*
***************************************************************/

public start_arena(id) {

    new name[32]
    get_user_name(id, name, 32)

    if(!(get_user_flags(id) & ADMIN_SLAY)) {

        client_print(id, print_chat, "[AMXX] You do not have access to this command.")
        log_amx("[AMXX] Player %s attempted to start pistol arena", name)
        return PLUGIN_HANDLED

    } else if(read_argc() < 2) {

        console_print(id, "[AMXX] Command usage: amx_pistolarena <on/off>")
        return PLUGIN_HANDLED
    }

    new arg[3]
    read_argv(1, arg, 3)

    if(equal(arg, "off", 3) && gArena == true) {

        gArena = false
        set_cvar_num("sv_gravity", 800)
        set_cvar_num("sv_restartround", 3)

        set_hudmessage(0, 255, 0, -1.0, 0.3, 0, 1.0, 5.0, 0.1, 0.2, 4)
        show_hudmessage(0,"The pistol arena has been disabled!")

        log_amx("[AMXX] Pistol arena has been disabled by %s", name)

        return PLUGIN_HANDLED

    } else if(equal(arg, "on", 2) && gArena == false) {

        gArena = true
        set_cvar_num("sv_restartround", 3)

        set_hudmessage(0, 255, 0, -1.0, 0.3, 0, 1.0, 5.0, 0.1, 0.2, 4)
        show_hudmessage(0,"The pistol arena has been enabled!")

        log_amx("[AMXX] Pistol arena has been enabled by %s", name)

        return PLUGIN_HANDLED
    }

    return PLUGIN_HANDLED
}

public round_start() {

    if(gArena == false)
        return PLUGIN_HANDLED

    set_user_arena()

    return PLUGIN_HANDLED
}

public check_maxspeed(id) {

    if(gArena == false)
        return PLUGIN_HANDLED

    if(get_cvar_num(MAXSPEED) < 320)
        set_cvar_num(MAXSPEED, 320)
    else if(get_cvar_num(MAXSPEED) > 700)
        set_cvar_num(MAXSPEED, 700)

    new maxspeed = get_cvar_num(MAXSPEED)

    set_user_maxspeed(id, float(maxspeed))

    return PLUGIN_HANDLED
}

public set_user_arena() {

    new num
    new players[32]

    get_players(players, num, "a")

    if(get_cvar_num(ARMOR) < 0)
        set_cvar_num(ARMOR, 0)
    else if(get_cvar_num(ARMOR) > 500)
        set_cvar_num(ARMOR, 500)

    new armor = get_cvar_num(ARMOR)

    if(get_cvar_num(HEALTH) < 100)
        set_cvar_num(HEALTH, 100)
    else if(get_cvar_num(HEALTH) > 250)
        set_cvar_num(ARMOR, 250)

    new health = get_cvar_num(HEALTH)

    if(get_cvar_num(GRAVITY) < 1)
        set_cvar_num(GRAVITY, 1)
    else if(get_cvar_num(GRAVITY) > 800)
        set_cvar_num(GRAVITY, 800)

    set_cvar_num("sv_gravity", get_cvar_num(GRAVITY))

    if(get_cvar_num(MAXSPEED) < 320)
        set_cvar_num(MAXSPEED, 320)
    else if(get_cvar_num(MAXSPEED) > 700)
        set_cvar_num(MAXSPEED, 700)

    new maxspeed = get_cvar_num(MAXSPEED)

    if(get_cvar_num(GLOW) < 0)
        set_cvar_num(GLOW, 0)
    else if(get_cvar_num(GLOW) > 1)
        set_cvar_num(GLOW, 1)

    new glow = get_cvar_num(GLOW)

    for (new p = 0; p < num; p++) {

        new id = players[p]

        cs_set_user_money(id, 0)

        set_user_armor(id, armor)
        set_user_health(id, health)
        set_user_maxspeed(id, float(maxspeed))

        new CsTeams:team = CsTeams:cs_get_user_team(id)

        if(team == CS_TEAM_T && glow == 1)
            set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 16)
        else if(team == CS_TEAM_CT && glow == 1)
            set_user_rendering(id, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 16)

        give_item(id, "weapon_usp")
        give_item(id, "weapon_p228")
        give_item(id, "weapon_elite")
        give_item(id, "weapon_deagle")
        give_item(id, "weapon_glock18")
        give_item(id, "weapon_fiveseven")

        cs_set_user_bpammo(id, CSW_USP, 48)
        cs_set_user_bpammo(id, CSW_P228, 53)
        cs_set_user_bpammo(id, CSW_ELITE, 120)
        cs_set_user_bpammo(id, CSW_DEAGLE, 35)
        cs_set_user_bpammo(id, CSW_GLOCK18, 120)
        cs_set_user_bpammo(id, CSW_FIVESEVEN, 100)
    }

    return PLUGIN_HANDLED
}

public plugin_init() {

    register_plugin(PLUGIN, VERSION, AUTHOR)

    register_cvar("amx_pistolarena_glow", "1", FCVAR_PRINTABLEONLY)
    register_cvar("amx_pistolarena_armor", "500", FCVAR_PRINTABLEONLY)
    register_cvar("amx_pistolarena_health", "200", FCVAR_PRINTABLEONLY)
    register_cvar("amx_pistolarena_gravity", "400", FCVAR_PRINTABLEONLY)
    register_cvar("amx_pistolarena_maxspeed", "500", FCVAR_PRINTABLEONLY)

    register_concmd("amx_pistolarena", "start_arena", ADMIN_SLAY, "<on/off>")

    register_logevent("round_start", 2, "1=Round_Start")
    register_event("CurWeapon", "check_maxspeed", "be")
}

public plugin_modules() {

    require_module("cstrike")
    require_module("fun")
}