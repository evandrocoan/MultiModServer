#include <amxmodx>

#define PLUGIN 	"c4 timer"
#define VERSION "1.1"
#define AUTHOR 	"cheap_suit"

new g_c4timer
new mp_c4timer

new cvar_showteam
new cvar_flash
new cvar_sprite
new cvar_msg

new g_msg_showtimer
new g_msg_roundtime
new g_msg_scenario

#define MAX_SPRITES	2
new const g_timersprite[MAX_SPRITES][] =
{   "bombticking", "bombticking1"}
new const g_message[] = "Detonation time intiallized....."

public plugin_init()
{   
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_cvar(PLUGIN, VERSION, FCVAR_SPONLY|FCVAR_SERVER)

    cvar_showteam = register_cvar("amx_showc4timer", "3")
    cvar_flash = register_cvar("amx_showc4flash", "0")
    cvar_sprite = register_cvar("amx_showc4sprite", "1")
    cvar_msg = register_cvar("amx_showc4msg", "0")
    mp_c4timer = get_cvar_pointer("mp_c4timer")

    g_msg_showtimer = get_user_msgid("ShowTimer")
    g_msg_roundtime = get_user_msgid("RoundTime")
    g_msg_scenario = get_user_msgid("Scenario")

    register_event("HLTV", "event_hltv", "a", "1=0", "2=0")
    register_logevent("logevent_plantedthebomb", 3, "2=Planted_The_Bomb")
}

public bomb_planted()
{   
    client_cmd(0, "spk djeyl/c4powa.wav" )
}

public plugin_precache()
{   
    precache_sound("djeyl/c4powa.wav")
    precache_sound("djeyl/grenade.wav")
    precache_sound("djeyl/laugh.wav")
    precache_sound("djeyl/witch.wav")

    return PLUGIN_HANDLED
}

public bomb_explode()
{   
    new randim = random_num(0,2)

    switch(randim)
    {   
        case 0: client_cmd(0,"spk djeyl/laugh.wav")
        case 1: client_cmd(0,"spk djeyl/witch.wav")
        case 2: client_cmd(0,"spk djeyl/grenade.wav")
    }
}

public event_hltv()
g_c4timer = get_pcvar_num(mp_c4timer)

public logevent_plantedthebomb()
{   
    new showtteam = get_pcvar_num(cvar_showteam)

    static players[32], num, i
    switch(showtteam)
    {   
        case 1: get_players(players, num, "ace", "TERRORIST")
        case 2: get_players(players, num, "ace", "CT")
        case 3: get_players(players, num, "ac")
        default: return
    }
    for(i = 0; i < num; ++i) set_task(1.0, "update_timer", players[i])
}

public update_timer(id)
{   
    message_begin(MSG_ONE_UNRELIABLE, g_msg_showtimer, _, id)
    message_end()

    message_begin(MSG_ONE_UNRELIABLE, g_msg_roundtime, _, id)
    write_short(g_c4timer)
    message_end()

    message_begin(MSG_ONE_UNRELIABLE, g_msg_scenario, _, id)
    write_byte(1)
    write_string(g_timersprite[clamp(get_pcvar_num(cvar_sprite), 0, (MAX_SPRITES - 1))])
    write_byte(150)
    write_short(get_pcvar_num(cvar_flash) ? 20 : 0)
    message_end()

    if(get_pcvar_num(cvar_msg))
    {   
        set_hudmessage(255, 180, 0, 0.44, 0.87, 2, 6.0, 6.0)
        show_hudmessage(id, g_message)
    }
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
 *{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
 */
