#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <fun>
#include <ttt>

#define m_bitsDamageType 	76

new g_iWarnings[33][TTT_WARNINGS], g_pCommandMenuID;
new cvar_warnings_innocent, cvar_warnings_special, cvar_warnings_punishment, cvar_warnings_bantime,
	cvar_warnings_continued, cvar_warnings_players, cvar_warnings_blind_time, cvar_warnings_minkarma;

new g_pMsgScreeFade;

public plugin_init()
{
	register_plugin("[TTT] Warning system", TTT_VERSION, TTT_AUTHOR);

	cvar_warnings_special		= my_register_cvar("ttt_warnings_special",		"2",	"Max warnings for killing Traitor or Detective wrongly, for example, Detective kills Detective. (Default: 2)");
	cvar_warnings_innocent		= my_register_cvar("ttt_warnings_innocent",		"3",	"Max warnings for killing Innocent wrongly. (Default: 3)");
	cvar_warnings_continued		= my_register_cvar("ttt_warnings_continued",	"3",	"Max continued warnings for killing wrongly, for example, kill wrongly Innocent, Detective, Innocent. (Default: 3)");
	cvar_warnings_punishment	= my_register_cvar("ttt_warnings_punishment",	"cdf",	"Punishment types: a=kick, b=ban, c=remove karma, d=hp to 1, e=blind, f=bad aim, g=ban on low karma. (Default: cdf)");
	cvar_warnings_bantime		= my_register_cvar("ttt_warnings_bantime",		"60",	"Ban time if ttt_ar_warnings_punishment has B. (Default: 60)");
	cvar_warnings_players		= my_register_cvar("ttt_warnings_players",		"5",	"Minimum players to start warn them. (Default: 5)");
	cvar_warnings_blind_time	= my_register_cvar("ttt_warnings_blind_time",	"60",	"Blind time in seconds. (Default: 60)");
	cvar_warnings_minkarma		= my_register_cvar("ttt_warnings_minkarma",		"300",	"Ban if karma <= X. (Default: 300)");

	// register_clcmd("say /tttwarns", "check_warnings");
	// register_clcmd("say_team /tttwarns", "check_warnings");
	g_pCommandMenuID = ttt_command_add("Warnings");

	RegisterHamPlayer(Ham_Killed, "Ham_Killed_post", 1);
	RegisterHamPlayer(Ham_Spawn, "Ham_Spawn_pre", 0);
	register_forward(FM_TraceLine, "Forward_TraceLine_post", 1);

	g_pMsgScreeFade = get_user_msgid("ScreenFade");
}

public plugin_natives()
{
	register_library("ttt");
	register_native("ttt_get_warnings", "_get_warnings");
	register_native("ttt_set_warnings", "_set_warnings");
}

public ttt_command_selected(id, menuid, name[])
{
	if(g_pCommandMenuID == menuid)
		check_warnings(id);
}

public client_putinserver(id)
{
	reset_client(id);
}

public Ham_Spawn_pre(id)
{
	if(g_iWarnings[id][WARN_PUNISH])
	{
		ttt_set_playerdata(id, PD_KARMA, 1);
		ttt_set_playerdata(id, PD_KARMATEMP, 1);
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_PUNISHMENT1");
		reset_client(id);
	}
	else check_warnings(id);
}

public Ham_Killed_post(victim, killer, shouldgib)
{
	if(!is_user_connected(killer))
		killer = ttt_find_valid_killer(victim, killer);

	if(!is_user_connected(killer) || killer == victim || ttt_return_check(victim) || ttt_is_exception(victim))
		return;

	new state_killer = ttt_get_playerstate(killer), state_victim = ttt_get_playerdata(victim, PD_KILLEDSTATE);
	if(state_killer == PC_TRAITOR && state_victim == PC_TRAITOR)
		add_warnings(killer, state_killer, state_victim, 0);
	else if((state_killer == PC_DETECTIVE && state_victim == PC_DETECTIVE) || (state_killer == PC_INNOCENT && state_victim == PC_DETECTIVE))
		add_warnings(killer, state_killer, state_victim, 0);
	else if((state_killer == PC_INNOCENT && state_victim == PC_INNOCENT) || (state_killer == PC_DETECTIVE && state_victim == PC_INNOCENT))
		add_warnings(killer, state_killer, state_victim, 1);
	else g_iWarnings[killer][WARN_CONTINUED] = 0;
}

public Forward_TraceLine_post(Float:origin1[3], Float:origin2[3], monster, id)
{
	if(!is_user_alive(id) || !g_iWarnings[id][WARN_BADAIM])
		return FMRES_IGNORED;

	new target = get_tr(TR_pHit);
	if(!is_user_alive(target))
		return FMRES_IGNORED;

	new hitzone = (1 << get_tr(TR_iHitgroup));
	if(g_iWarnings[id][WARN_BADAIM] & hitzone)
	{
		set_tr(TR_flFraction, 1.0);
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public add_warnings(killer, state_killer, state_victim, type)
{
	new num;
	static players[32];
	get_players(players, num);
	
	if(num-1 < get_pcvar_num(cvar_warnings_players))
		return;

	if(type)
		g_iWarnings[killer][WARN_INNOCENT]++;
	else g_iWarnings[killer][WARN_SPECIAL]++;
	g_iWarnings[killer][WARN_CONTINUED]++;

	new special = get_pcvar_num(cvar_warnings_special), innocent = get_pcvar_num(cvar_warnings_innocent), continued = get_pcvar_num(cvar_warnings_continued);

	if(g_iWarnings[killer][WARN_SPECIAL] >= special || g_iWarnings[killer][WARN_INNOCENT] >= innocent || g_iWarnings[killer][WARN_CONTINUED] >= continued)
		punish_player(killer);
	else if(type == 0)
	{
		client_print_color(killer, print_team_default, "%s %L", TTT_TAG, killer, "TTT_WARNING1", killer, special_names[state_killer], killer, special_names[state_victim]);
		check_warnings(killer);
	}
}

public check_warnings(id)
{
	if(ttt_get_playerstate(id) != PC_INNOCENT)
	{
		new specialKill = get_pcvar_num(cvar_warnings_special), innocentKill = get_pcvar_num(cvar_warnings_innocent), continued = get_pcvar_num(cvar_warnings_continued);
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_WARNING2", g_iWarnings[id][WARN_SPECIAL], specialKill, id, special_names[PC_SPECIAL], g_iWarnings[id][WARN_INNOCENT], innocentKill, id, special_names[PC_INNOCENT], g_iWarnings[id][WARN_CONTINUED], continued);
	}
}

public punish_player(id)
{
	if(!is_user_connected(id))
		return;

	static cvar[10];
	get_pcvar_string(cvar_warnings_punishment, cvar, charsmax(cvar));
	if(!cvar[0])
		return;

	static const punishments[] =
	{
		(1<<0),	// a = kick,
		(1<<1),	// b = ban,
		(1<<2),	// c = remove karma,
		(1<<3),	// d = hp to 1,
		(1<<4),	// e = blind,
		(1<<5),	// f = bad aim
		(1<<6)	// g = ban low karma
	};

	new flags = read_flags(cvar);
	static const size = sizeof(punishments);
	for(new i = 0; i < size; i++)
	{
		if(flags & punishments[i])
			pick_punishment(id, i);
	}

	static name[32];
	get_user_name(id, name, charsmax(name));
	ttt_log_to_file(LOG_MISC, "%s was punished for team kills", name);
}

stock pick_punishment(killer, punishment)
{
	switch(punishment)
	{
		case 0:	server_cmd("kick #%d ^"You have been kicked from server for killing teammates!^"", get_user_userid(killer));
		case 1:
		{
			static reason[20];
			if(g_iWarnings[killer][WARN_SPECIAL] >= get_pcvar_num(cvar_warnings_special))
				formatex(reason, charsmax(reason), "PC_SPECIAL %d/%d", g_iWarnings[killer][WARN_SPECIAL], g_iWarnings[killer][WARN_SPECIAL]);
			else if(g_iWarnings[killer][WARN_INNOCENT] >= get_pcvar_num(cvar_warnings_innocent))
				formatex(reason, charsmax(reason), "PC_INNOCENT %d/%d", g_iWarnings[killer][WARN_INNOCENT], g_iWarnings[killer][WARN_INNOCENT]);
			else if(g_iWarnings[killer][WARN_CONTINUED] >= get_pcvar_num(cvar_warnings_continued))
				formatex(reason, charsmax(reason), "CONTINUED %d/%d", g_iWarnings[killer][WARN_CONTINUED], g_iWarnings[killer][WARN_CONTINUED]);

			server_cmd("amx_banip %d #%d TK:%s", get_pcvar_num(cvar_warnings_bantime), get_user_userid(killer), reason);
			g_iWarnings[killer][WARN_BANNED] = true;
		}
		case 2: g_iWarnings[killer][WARN_PUNISH] = true;
		case 3: if(is_user_alive(killer)) set_user_health(killer, 1);
		case 4: set_user_blind(killer);
		case 5: set_user_badaim(killer);
		case 6: ban_user_lowkarma(killer);
	}
}

stock set_user_badaim(id)
{
	if(task_exists(id))
		remove_task(id);

	g_iWarnings[id][WARN_BADAIM] = false;
	client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_PUNISHMENT3");
	set_task(10.0, "randomize_hitzones", id, _, _, "b");
	randomize_hitzones(id);
}

public randomize_hitzones(id)
{
	if(is_user_alive(id))
	{
		for(new i = 0; i < 3; i++)
			g_iWarnings[id][WARN_BADAIM] |= (1 << 0) | (1 << random_num(1, 7));
	}
	else if(task_exists(id))
		remove_task(id);
}

stock set_user_blind(id)
{
	if(is_user_alive(id))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_pMsgScreeFade, _, id);
		write_short(get_pcvar_num(cvar_warnings_blind_time) * 1<<12);
		write_short(4*1<<12);
		write_short(0x0000);
		write_byte(0);
		write_byte(0);
		write_byte(0);
		write_byte(255);
		message_end();
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_PUNISHMENT2");
	}
}

stock reset_client(id)
{
	for(new i = 0; i < TTT_WARNINGS; i++)
		g_iWarnings[id][i] = false;

	if(task_exists(id))
		remove_task(id);
}

stock ban_user_lowkarma(id)
{
	new karma = ttt_get_playerdata(id, PD_KARMATEMP);
	if(karma <= get_pcvar_num(cvar_warnings_minkarma))
	{
		server_cmd("amx_banip %d #%d MIN_KARMA:%d", get_pcvar_num(cvar_warnings_bantime), get_user_userid(id), karma);
		g_iWarnings[id][WARN_BANNED] = true;
	}
}

//API
public _get_warnings(plugin, params)
{
	if(params != 2)
		return ttt_log_api_error("ttt_get_warnings needs 2 params(p1: %d)", plugin, params, get_param(1));

	set_array(2, g_iWarnings[get_param(1)], TTT_WARNINGS);
	return 1;
}

public _set_warnings(plugin, params)
{
	if(params != 2)
		return ttt_log_api_error("ttt_set_warnings needs 2 params(p1: %d)", plugin, params, get_param(1));

	get_array(2, g_iWarnings[get_param(1)], TTT_WARNINGS);
	return 1;
}