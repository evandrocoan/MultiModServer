/**
 * csdm_tickets.sma
 * CSDM plugin that lets you have round ticketing.
 *  Every time a player dies their team loses a ticket.  Once all their tickets are used up,
 *  they cannot respawn.
 *
 * (C)2003-2006 David "BAILOPAN" Anderson
 *
 *  Give credit where due.
 *  Share the source - it sets you free
 *  http://www.opensource.org/
 *  http://www.gnu.org/
 */
 
#include <amxmodx>
#include <amxmisc>
#include <csdm>

new bool:g_Enabled = false
new g_TeamTickets
new g_Respawns[3]

//Tampering with the author and name lines can violate the copyright
new PLUGINNAME[] = "CSDM Ticketing"
new VERSION[] = CSDM_VERSION
new AUTHORS[] = "BAILOPAN"

public csdm_Init(const version[])
{
	if (version[0] == 0)
	{
		set_fail_state("CSDM failed to load.")
		return
	}
}

public csdm_CfgInit()
{
	csdm_reg_cfg("ticketing", "read_cfg")
}

public plugin_init()
{
	register_plugin(PLUGINNAME, VERSION, AUTHORS);
	
	new menu = csdm_main_menu();
	menu_additem(menu, "", "csdm_ticketing", ADMIN_MAP)
}

public plugin_cfg()
{
	if (g_TeamTickets)
	{
		csdm_set_mainoption(CSDM_OPTION_SAYRESPAWN, CSDM_SET_DISABLED)
	}
}

public csdm_RoundRestart()
{
	g_Respawns[_TEAM_T] = 0
	g_Respawns[_TEAM_CT] = 0
}

public csdm_PostDeath(killer, victim, headshot, const weapon[])
{
	if (!g_Enabled)
		return PLUGIN_CONTINUE
		
	new team = get_user_team(victim)
	
	if (g_Respawns[team] >= g_TeamTickets)
		return PLUGIN_HANDLED
		
	g_Respawns[team]++
	
	update_views()
	
	return PLUGIN_CONTINUE
}

public csdm_PreSpawn(player, bool:fake)
{
	if (!g_Enabled || !fake)
		return PLUGIN_CONTINUE
		
	new team = get_user_team(player)
	if (g_Respawns[team] >= g_TeamTickets)
		return PLUGIN_HANDLED
		
	update_views()
	
	return PLUGIN_CONTINUE
}

update_views()
{
	//stolen from twisty
	set_hudmessage(255, 255, 255, 0.0, 0.12, 0, 6.0, 240.0, 0.1, 0.1, 4)
	new message[101]
	new ct = g_TeamTickets - g_Respawns[_TEAM_CT]
	new t = g_TeamTickets - g_Respawns[_TEAM_T]
	if (t < 0)
		t = 0
	if (ct < 0)
		ct = 0
	format(message, 100, "Round Tickets - ^nTerrorists: %d^nCounter-Terrorist Tickets: %d", t , ct)
	show_hudmessage(0, "%s", message)
}

public read_cfg(readAction, line[], section[])
{
	if (!csdm_active())
	{
		return
	}
		
	if (readAction == CFG_READ)
	{
		new setting[24], sign[3], value[32];

		parse(line, setting, 23, sign, 2, value, 31);
		
		if (equali(setting, "tickets"))
		{
			g_TeamTickets = str_to_num(value)
		} else if (equali(setting, "enabled")) {
			g_Enabled = str_to_num(value) ? true : false
		}
	}
}
