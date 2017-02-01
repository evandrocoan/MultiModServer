#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <cs_teams_api>
#include <timer_controller>
#include <ttt>

#define TASK_SURVIVAL			1111
#define TASK_ORPHEU				2222
#define m_bitsDamageType		76
#define m_flPainShock			108
#define OFFSET_LINUX_WEAPONS	4
#define OFFSET_LINUX_PLAYERS	5

enum
{
	KARMA_KILL,
	KARMA_DMG
}

new const g_szGameModes[GAME_MODE][] =
{
	"unset",
	"off",
	"preparing",
	"restarting",
	"started",
	"ended"
};

const DMG_SOMETHING = DMG_GENERIC | DMG_SLASH | DMG_BURN 
	| DMG_FREEZE | DMG_FALL | DMG_BLAST | DMG_SHOCK | DMG_DROWN 
	| DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_ACID;
	
// RESETABLE
new g_iGlobalInfo[GLOBAL_INFO], g_iSpecialCount[PLAYER_CLASS], g_iRoundSpecial[PLAYER_CLASS];
new g_iPlayerData[33][PLAYER_DATA];
new g_iMultiCount = 1, g_iMultiSeconds = 1;
new Trie:g_tCvarsToFile, g_iTrieSize;
//
// NON RESETABLE
new cvar_traitors, cvar_detectives, cvar_karma_damage,
	cvar_preparation_time, cvar_karma_multi, cvar_karma_start,
	cvar_credits_tra_start, cvar_credits_tra_count, cvar_credits_tra_detkill, cvar_credits_tra_countkill,
	cvar_credits_det_start, cvar_credits_tra_repeat, cvar_damage_modifier,
	cvar_credits_det_bonussurv, cvar_credits_det_survtime, cvar_show_deathmessage, cvar_detective_glow;
new g_pMsgTeamInfo, g_pMsgScreenFade, g_iGameModeForward, g_iPluginCfgForward;
new Float:g_fFreezeTime, Float:g_fRoundTime, Float:g_fRoundStart;
new g_iMaxDetectives, g_iMaxTraitors, g_iMaxPlayers;
new g_iExceptionItems[10] = {-2, -2, ...};
//

public plugin_init()
{
	register_plugin("[TTT] Core", TTT_VERSION, TTT_AUTHOR);
	register_cvar("ttt_server_version", TTT_VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY);

	cvar_traitors				= mynew_register_cvar("ttt_traitors",				"4",	"One Traitor on X players. (Default: 4)");
	cvar_detectives				= mynew_register_cvar("ttt_detectives",				"6",	"One Detective on X players. (Default: 6)");
	cvar_preparation_time		= mynew_register_cvar("ttt_preparation_time",		"10",	"Preparation time before game start. (Default: 10)");
	cvar_credits_tra_start		= mynew_register_cvar("ttt_credits_tra_start",		"2",	"Number of credits Traitor has when starting game. (Default: 2)");
	cvar_credits_tra_count		= mynew_register_cvar("ttt_credits_tra_count",		"0.25",	"Percentage of players to kill to get extra credits. (Default: 0.25)");
	cvar_credits_tra_repeat		= mynew_register_cvar("ttt_credits_tra_repeat",		"1",	"Repeat percentage kills till all are killed. (Default: 1)");
	cvar_credits_tra_detkill	= mynew_register_cvar("ttt_credits_tra_detkill",	"1",	"Number of credits for killing a Detective. (Default: 1)");
	cvar_credits_tra_countkill	= mynew_register_cvar("ttt_credits_tra_countkill",	"1",	"Number of credits to give for percentage kills. (Default: 1)");
	cvar_credits_det_start		= mynew_register_cvar("ttt_credits_det_start",		"1",	"Number of credits Detective has when starting game. (Default: 1)");
	cvar_credits_det_bonussurv	= mynew_register_cvar("ttt_credits_det_bonussurv",	"1",	"Number of credits to give for surviving time. (Default: 1)");
	cvar_credits_det_survtime	= mynew_register_cvar("ttt_credits_det_survtime",	"45.0",	"Every X seconds give credits. (Default: 45.0)");
	cvar_karma_damage			= mynew_register_cvar("ttt_karma_damage",			"0.25",	"Karma modifier dealing damage. (Default: 0.25)");
	cvar_karma_multi			= mynew_register_cvar("ttt_karma_multi",			"50",	"Karma modifier for killing. (Default: 50)");
	cvar_karma_start			= mynew_register_cvar("ttt_karma_start",			"500",	"Starting karma. (Default: 500)");
	cvar_show_deathmessage		= mynew_register_cvar("ttt_show_deathmessage",		"abeg",	"Show deathmessages to: a=NONE, b=TRAITOR, c=DETECTIVE, d=INNOCENT, e=DEAD, f=SPECIAL, g=victim, h=killer. (Default: abeg)");
	cvar_damage_modifier		= mynew_register_cvar("ttt_damage_modifier",		"1.0",	"Modifies karma based damage. (Default: 1.0)");
	cvar_detective_glow			= mynew_register_cvar("ttt_detective_glow",			"1",	"Should detective also be glowing? (Default: 1)");

	g_pMsgScreenFade	= get_user_msgid("ScreenFade");
	g_pMsgTeamInfo		= get_user_msgid("TeamInfo");

	register_event("TextMsg", "Event_RoundRestart", "a", "2&#Game_C", "2&#Game_w");
	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	register_event("DeathMsg", "Event_DeathMsg", "a");
	register_logevent("Event_EndPreptime", 2, "1=Round_Start");
	register_logevent("Event_EndRound", 2, "1=Round_End");

	register_forward(FM_AddToFullPack, "Forward_AddToFullPack_post", 1);

	RegisterHamPlayer(Ham_Killed, "Ham_Killed_pre", 0);
	RegisterHamPlayer(Ham_Killed, "Ham_Killed_post", 1);
	RegisterHamPlayer(Ham_TakeDamage, "Ham_TakeDamage_pre", 0);
	RegisterHamPlayer(Ham_TakeDamage, "Ham_TakeDamage_post", 1);
	RegisterHamPlayer(Ham_TraceAttack, "Ham_TraceAttack_pre", 0);

	g_iGameModeForward = CreateMultiForward("ttt_gamemode", ET_IGNORE, FP_CELL);
	g_iPluginCfgForward = CreateMultiForward("ttt_plugin_cfg", ET_IGNORE);

	g_iMaxPlayers = get_maxplayers();
	#if AMXX_VERSION_NUM < 183
	register_dictionary("ttt_c.txt");
	register_dictionary("ttt_addons_c.txt");
	#else
	register_dictionary("ttt.txt");
	register_dictionary("ttt_addons.txt");
	#endif
}

public plugin_end()
	set_game_state(GAME_PREPARING);

public plugin_natives()
{
	register_library("ttt");
	register_native("ttt_get_roundtime",	"_get_roundtime");
	register_native("ttt_get_playerdata",	"_get_playerdata");
	register_native("ttt_set_playerdata",	"_set_playerdata");
	register_native("ttt_get_globalinfo",	"_get_globalinfo");
	register_native("ttt_set_globalinfo",	"_set_globalinfo");
	register_native("ttt_set_playerstate",	"_set_playerstate");
	register_native("ttt_set_gamemode",		"_set_gamemode");
	register_native("ttt_get_specialcount",	"_get_specialcount");
	register_native("ttt_register_cvar",	"_register_cvar");
	register_native("ttt_add_exception",	"_add_exception");
	register_native("ttt_find_exception",	"_find_exception");
}

public plugin_cfg()
{
	auto_exec_config(TTT_CONFIGFILE);
	g_fRoundTime = get_pcvar_float(get_cvar_pointer("mp_roundtime"));
	TrieDestroy(g_tCvarsToFile);

	new ret;
	ExecuteForward(g_iPluginCfgForward, ret);
}

public client_disconnect(id)
{
	set_task(0.5, "reset_client", id);
	set_special_state(id, PC_NONE);
}

public client_putinserver(id)
{
	// if(is_user_bot(id))
	// 	server_cmd("kick #%i %s", get_user_userid(id), "Bot player!");

	reset_client(id);
	g_iPlayerData[id][PD_KILLEDBY] = -1;
	set_task(11.0, "startup_info", id);

	new karma = get_pcvar_num(cvar_karma_start);
	g_iPlayerData[id][PD_KARMATEMP] = karma;
	g_iPlayerData[id][PD_KARMA] = karma;
}

public startup_info(id)
{
	if(get_game_state() == GAME_STARTED && !is_user_alive(id))
	{
		set_special_state(id, PC_DEAD);
		Show_All();
	}

	// Please don't remove this :)
	client_print_color(id, print_team_default, "%s Mod created by ^3%s^1, ^4skype:guskis1^1, version: ^3%s^1!", TTT_TAG, TTT_AUTHOR, TTT_VERSION);
}

public Event_RoundRestart()
{
	if(get_game_state() != GAME_RESTARTING)
	{
		reset_all();
		set_game_state(GAME_RESTARTING);
	}
}

public Event_HLTV()
{
	if(get_game_state() != GAME_PREPARING)
	{
		new cvar = get_pcvar_num(cvar_preparation_time);
		if(!cvar)
			set_pcvar_num(cvar_preparation_time, cvar = 1);
		g_fFreezeTime = float(cvar);
		set_task(0.1, "set_timer");

		g_fRoundTime = get_pcvar_float(get_cvar_pointer("mp_roundtime"));
		g_fRoundStart = get_gametime();
		reset_all();

		set_game_state(GAME_PREPARING);
	}
}

public set_timer()
	RoundTimerSet(0, get_pcvar_num(cvar_preparation_time));

public Event_EndRound()
{
	if(get_game_state() != GAME_ENDED)
	{
		reset_all();
		set_game_state(GAME_ENDED);
	}
}

public Event_EndPreptime()
{
	if(task_exists(TASK_ORPHEU))
		remove_task(TASK_ORPHEU);
	set_task(float(get_pcvar_num(cvar_preparation_time)), "do_the_magic", TASK_ORPHEU);
}

public do_the_magic()
{
	RoundTimerSet(floatround(g_fRoundTime));

	new num;
	static players[32];
	get_players(players, num);
	ttt_log_to_file(LOG_DEFAULT, "Current player count %d", num);

	if(num < 3)
	{
		set_game_state(GAME_OFF);
		client_print_color(0, print_team_default, "%s %L", TTT_TAG, LANG_PLAYER, "TTT_MODOFF1");
		return;
	}

	new trai = get_pcvar_num(cvar_traitors), dete = get_pcvar_num(cvar_detectives);
	g_iMaxTraitors = (num/trai);
	if(!g_iMaxTraitors)
		g_iMaxTraitors = 1;

	g_iMaxDetectives = (num/dete);
	if(g_iMaxTraitors+g_iMaxDetectives>num)
	{
		set_pcvar_num(cvar_detectives, 8);
		set_pcvar_num(cvar_traitors, 4);
		g_iMaxTraitors = (num/trai);

		if(!g_iMaxTraitors)
			g_iMaxTraitors = 1;
	
		g_iMaxDetectives = (num/dete);
		client_print_color(0, print_team_default, "%s %L", TTT_TAG, LANG_PLAYER, "TTT_MODOFF2");
	}
	while(specials_needed() != 0)
		pick_specials();

	new id;
	for(--num; num >= 0; num--)
	{
		id = players[num];
		if(!is_user_alive(id)) continue;
		g_iPlayerData[id][PD_KARMA] = g_iPlayerData[id][PD_KARMATEMP];

		if(get_special_state(id) != PC_DETECTIVE && get_special_state(id) != PC_TRAITOR)
		{
			screen_fade(id, PC_INNOCENT);
			set_special_state(id, PC_INNOCENT);
			cs_set_player_team(id, CS_TEAM_CT, false);
		}

		entity_set_float(id, EV_FL_frags, float(g_iPlayerData[id][PD_KARMA]));
		cs_set_user_deaths(id, g_iPlayerData[id][PD_KILLEDDEATHS]);
	}

	new i;
	for(i = 0; i < PLAYER_CLASS; i++)
		g_iRoundSpecial[i] = get_special_count(i);

	set_task(get_pcvar_float(cvar_credits_det_survtime), "give_survival_credits", TASK_SURVIVAL, _, _, "b");
	
	get_players(players, num);
	for(--num; num >= 0; num--)
	{
		id = players[num];
		set_fake_team(id, get_special_state(id));
	}

	set_game_state(GAME_STARTED);
}

public Event_DeathMsg()
{
	new killer = read_data(1); 
	new victim = read_data(2);
	static weapon[16];
	read_data(4, weapon, charsmax(weapon));

	if(is_user_connected(killer))
	{
		static newweap[32];
		g_iPlayerData[victim][PD_KILLEDBY] = killer;
		g_iPlayerData[killer][PD_KILLCOUNT]++;
		formatex(newweap, charsmax(newweap), "weapon_%s", weapon);
		g_iPlayerData[victim][PD_KILLEDWEAP] = get_weaponid(newweap);
	}

	static cvar[10];
	get_pcvar_string(cvar_show_deathmessage, cvar, charsmax(cvar));
	if(cvar[0])
		ttt_make_deathmsg(killer, victim, read_data(3), weapon, read_flags(cvar));

	if(equali(weapon, "worldspawn"))
		g_iPlayerData[victim][PD_KILLEDWEAP] = DEATHS_SUICIDE;
}

public Ham_Killed_pre(victim, killer, shouldgib)
{
	if(my_return_check(victim))
		return HAM_IGNORED;

	if(get_pdata_int(victim, m_bitsDamageType) & DMG_SOMETHING)
		add_death_info(victim, killer, get_pdata_int(victim, m_bitsDamageType, 5));

	g_iPlayerData[victim][PD_KILLEDSTATE] = get_special_state(victim);
	g_iPlayerData[victim][PD_KILLEDTIME] = floatround(floatmul(g_fRoundTime, 60.0) - get_round_time());
	g_iPlayerData[victim][PD_KILLEDDEATHS]++;

	set_special_state(victim, PC_DEAD);
	return HAM_HANDLED;
}

public add_death_info(victim, killer, dmg)
{
	new msg = get_deathmessage(0, dmg);
	if(is_user_connected(killer))
	{
		g_iPlayerData[victim][PD_KILLEDBY] = killer;
		g_iPlayerData[killer][PD_KILLCOUNT]++;
	}
	else g_iPlayerData[victim][PD_KILLEDBY] = msg;

	g_iPlayerData[victim][PD_KILLEDWEAP] = msg;
}

public get_deathmessage(id, dmg)
{
	if(!id)
	{
		if(dmg & DMG_GENERIC)
			dmg = DEATHS_GENERIC;
		else if(dmg & DMG_SLASH)
			dmg = DEATHS_SLASH;
		else if(dmg & DMG_BURN)
			dmg = DEATHS_BURN;
		else if(dmg & DMG_FREEZE)
			dmg = DEATHS_FREEZE;
		else if(dmg & DMG_FALL)
			dmg = DEATHS_FALL;
		else if(dmg & DMG_BLAST)
			dmg = DEATHS_BLAST;
		else if(dmg & DMG_SHOCK)
			dmg = DEATHS_SHOCK;
		else if(dmg & DMG_DROWN)
			dmg = DEATHS_DROWN;
		else if(dmg & DMG_NERVEGAS)
			dmg = DEATHS_NERVEGAS;
		else if(dmg & DMG_POISON)
			dmg = DEATHS_POISON;
		else if(dmg & DMG_RADIATION)
			dmg = DEATHS_RADIATION;
		else if(dmg & DMG_ACID)
			dmg = DEATHS_ACID;
		else dmg = DEATHS_SUICIDE;
	}
	else dmg = g_iPlayerData[id][PD_KILLEDWEAP];

	return dmg;
}

public Ham_Killed_post(victim, killer, shouldgib)
{
	if(my_return_check(victim))
		return;

	if(!is_user_connected(killer))
	{
		killer = find_valid_killer(victim, killer);
	}

	new bonus;
	static players[32], name[32];
	if(float(get_special_count(PC_DEAD)+get_special_count(PC_TRAITOR)-g_iRoundSpecial[PC_TRAITOR])/float(g_iRoundSpecial[PC_INNOCENT]+g_iRoundSpecial[PC_DETECTIVE])
	> get_pcvar_float(cvar_credits_tra_count) * g_iMultiCount)
	{
		new num, i;
		bonus = get_pcvar_num(cvar_credits_tra_countkill);
		get_players(players, num, "a");
		for(--num; num >= 0; num--)
		{
			i = players[num];

			if(get_special_state(i) == PC_TRAITOR)
			{
				g_iPlayerData[i][PD_CREDITS] += bonus;
				client_print_color(i, print_team_default, "%s %L", TTT_TAG, i, "TTT_AWARD1", bonus, floatround(get_pcvar_float(cvar_credits_tra_count)* g_iMultiCount*100), i, special_names[PC_INNOCENT]);
			}
		}

		if(get_pcvar_num(cvar_credits_tra_repeat))
			g_iMultiCount++;
		else g_iMultiCount = 100;
	}

	if(is_user_connected(killer))
	{
		new killer_state = get_special_alive(killer), victim_state = get_special_alive(victim);
		if(killer_state == PC_TRAITOR && victim_state == PC_DETECTIVE)
		{
			bonus = get_pcvar_num(cvar_credits_tra_detkill);
			g_iPlayerData[killer][PD_CREDITS] += bonus;
			get_user_name(victim, name, charsmax(name));
			client_print_color(killer, print_team_default, "%s %L", TTT_TAG, killer, "TTT_AWARD2", bonus, killer, special_names[PC_DETECTIVE], name);
		}

		if(killer != victim)
		{
			get_user_name(victim, name, charsmax(name));
			if(killer_state == PC_INNOCENT || killer_state == PC_DETECTIVE)
				client_print_color(killer, print_team_default, "%s %L", TTT_TAG, killer, "TTT_KILLED2", name);
			else if(killer_state == PC_TRAITOR || victim_state == PC_TRAITOR)
				client_print_color(killer, print_team_default, "%s %L", TTT_TAG, killer, "TTT_KILLED3", name, killer, special_names[victim_state]);

			get_user_name(killer, name, charsmax(name));
			client_print_color(victim, print_team_default, "%s %L", TTT_TAG, victim, "TTT_KILLED1", name, victim, special_names[killer_state]);
		}
	}

	new killed_item = killed_with_item(victim);
	if(killed_item)
	{
		if(is_user_connected(killer))
		{
			if(victim != killer && get_special_alive(killer) != get_special_alive(victim))
				karma_modifier(killer, victim, KARMA_KILL);
		}
	}
	else karma_modifier(killer, victim, KARMA_KILL);

	if(!killed_item && (!is_user_connected(killer) || killer == victim))
		client_print_color(victim, print_team_default, "%s %L", TTT_TAG, victim, "TTT_SUICIDE");

	set_task(0.1, "Show_All");
}

public find_valid_killer(victim, killer)
{
	new new_killer = get_player_data(victim, PD_KILLEDBY);
	return new_killer ? new_killer : killer;
}

public killed_with_item(victim)
{
	new item = get_player_data(victim, PD_KILLEDBYITEM);
	static const size = sizeof(g_iExceptionItems);
	for(new i = 0; i < size; i++)
	{
		if(g_iExceptionItems[i] == item)
			return 1;
	}

	return 0;
}

public Show_All()
{
	if(get_game_state() == GAME_STARTED)
	{
		new num, i, specstate;
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			i = players[num];

			specstate = get_special_state(i);
			if(specstate == PC_DEAD || specstate == PC_NONE)
			{
				set_attrib_special(i, 1, PC_TRAITOR, PC_NONE, PC_DEAD);
				if(!g_iPlayerData[i][PD_SCOREBOARD])
					set_attrib_special(i, 0, PC_INNOCENT, PC_DETECTIVE);
			}
		}
	}
}

public Ham_TakeDamage_pre(victim, inflictor, attacker, Float:damage, bits)
{
	if(!my_return_check(attacker))
	{
		new Float:modifier = g_iPlayerData[attacker][PD_KARMA]/1000.0;
		if(modifier > 0.05 && damage > 0.1)
		{
			damage *= (modifier*get_pcvar_float(cvar_damage_modifier));
			if(cs_get_user_team(attacker) != cs_get_user_team(victim))
				damage *= 0.35;

			if(damage < 1.0)
				damage = 1.0;
		}
		else damage = 0.0;

		SetHamParamFloat(4, damage);
		return HAM_HANDLED;
	}

	return HAM_IGNORED;
}

public Ham_TakeDamage_post(victim, inflictor, attacker, Float:damage, bits)
{
	if(!my_return_check(attacker))
	{
		if(damage > 0.1)
		{
			if(victim != attacker)
				karma_modifier(attacker, victim, KARMA_DMG);
		}
		else set_pdata_float(victim, m_flPainShock, 1.0, OFFSET_LINUX_PLAYERS);
	}
}

public Ham_TraceAttack_pre()
{
	if(get_game_state() != GAME_STARTED && get_game_state() != GAME_OFF)
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public Forward_AddToFullPack_post(es_handle, e, ent, host, hostflags, id, pSet)
{
	if(id && host != ent && is_user_connected(host) && is_user_connected(ent) && get_orig_retval())
	{
		static cvar;
		if(!cvar)
			cvar = get_pcvar_num(cvar_detective_glow);

		new entTeam = get_special_alive(ent);
		if(entTeam != PC_INNOCENT)
		{
			new hostTeam = get_special_alive(host);
			new fakeTeam = get_player_data(ent, PD_FAKESTATE);
			if(fakeTeam && hostTeam != entTeam)
				entTeam = fakeTeam;
			if(hostTeam == PC_TRAITOR || ((hostTeam == PC_DETECTIVE || hostTeam == PC_INNOCENT) && entTeam != PC_TRAITOR && cvar))
			{
				set_es(es_handle, ES_RenderFx, kRenderFxGlowShell);
				set_es(es_handle, ES_RenderColor, g_iTeamColors[entTeam]);
				set_es(es_handle, ES_RenderAmt, 35);
			}
		}
	}
}

public pick_specials()
{
	new id, num;
	static players[32];
	static name[32];

	get_players(players, num);

	while(id == 0)
	{
		id = players[random(num)];
		if(get_special_state(id) == PC_TRAITOR || get_special_state(id) == PC_DETECTIVE)
			id = 0;
	}

	new randomNum = specials_needed();
	get_user_name(id, name, charsmax(name));
	switch(randomNum)
	{
		case PC_TRAITOR:
		{
			g_iPlayerData[id][PD_CREDITS] = get_pcvar_num(cvar_credits_tra_start);
			set_special_state(id, randomNum);

			screen_fade(id, randomNum);
			ttt_log_to_file(LOG_DEFAULT, "[%L] %s choosen (ID:%d)", id, special_names[randomNum], name, id);
			cs_set_player_team(id, CS_TEAM_T, false);
		}
		case PC_DETECTIVE:
		{
			if(num >= get_pcvar_num(cvar_detectives))
			{
				g_iPlayerData[id][PD_CREDITS] = get_pcvar_num(cvar_credits_det_start);
				set_special_state(id, randomNum);

				screen_fade(id, randomNum);
				ttt_log_to_file(LOG_DEFAULT, "[%L] %s choosen (ID:%d)", id, special_names[randomNum], name, id);
				cs_set_player_team(id, CS_TEAM_CT, false);
			}
		}
		case PC_NONE: return;
	}
}

stock screen_fade(id, player_state)
{
	message_begin(MSG_ONE_UNRELIABLE, g_pMsgScreenFade, _, id);
	write_short(FixedUnsigned16(1.0, 1<<12));
	write_short(0);
	write_short((SF_FADE_MODULATE)); //flags (SF_FADE_IN + SF_FADE_ONLYONE) (SF_FADEOUT)
	write_byte(g_iTeamColors[player_state][0]);
	write_byte(g_iTeamColors[player_state][1]);
	write_byte(g_iTeamColors[player_state][2]);
	write_byte(180);
	message_end();
}

stock my_return_check(id)
{
	new game = get_game_state();
	if(!is_user_connected(id) || game == GAME_OFF || game == GAME_ENDED)
		return 1;

	return 0;
}

public specials_needed()
{
	if(g_iMaxTraitors > get_special_count(PC_TRAITOR))
		return PC_TRAITOR;
	else if(g_iMaxDetectives > get_special_count(PC_DETECTIVE))
		return PC_DETECTIVE;

	return PC_NONE;
}

public give_survival_credits()
{
	static players[32];
	new num, id, bonus = get_pcvar_num(cvar_credits_det_bonussurv);
	get_players(players, num, "a");
	for(--num; num >= 0; num--)
	{
		id = players[num];
		if(get_special_state(id) == PC_DETECTIVE)
		{
			g_iPlayerData[id][PD_CREDITS] += bonus;
			client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_AWARD4", bonus, floatround(get_pcvar_float(cvar_credits_det_survtime))*g_iMultiSeconds);
			g_iMultiSeconds++;
		}
	}
}

public reset_all()
{
	static players[32];
	new num, id, i;
	get_players(players, num);
	for(--num; num >= 0; num--)
	{
		id = players[num];

		set_special_state(id, PC_NONE);
		for(i = 0; i < PLAYER_DATA; i++)
		{
			if(i == PD_KARMA || i == PD_KARMATEMP || i == PD_KILLEDDEATHS) continue;
			if(i == PD_KILLEDBY || i == PD_KILLEDBYITEM)
				g_iPlayerData[id][i] = -1;
			else g_iPlayerData[id][i] = 0;
		}
		if(task_exists(id))
			remove_task(id);
		set_attrib_all(id, 0);
	}

	for(i = 0; i < PLAYER_CLASS; i++)
		g_iSpecialCount[i] = 0;
	//if(get_game_state() == GAME_ENDED || get_game_state() == GAME_RESTARTING)
	//	set_game_state(GAME_OFF);

	g_iMultiSeconds = 1;
	g_iMultiCount = 1;

	if(task_exists(TASK_SURVIVAL))
		remove_task(TASK_SURVIVAL);
}

public reset_client(id)
{
	for(new i = 0; i < PLAYER_DATA; i++)
	{
		if(i == PD_KILLEDBY || i == PD_KILLEDBYITEM)
			g_iPlayerData[id][i] = -1;
		else g_iPlayerData[id][i] = 0;
	}

	set_special_state(id, PC_NONE);
	set_attrib_all(id, 0);
}

public karma_modifier(attacker, victim, type)
{
	if(attacker == 0)
		attacker = victim;

	if(!is_user_connected(attacker) || !is_user_connected(victim) || get_game_state() == GAME_OFF)
		return;

	static players[32];
	new num, karmamulti, modifier;
	get_players(players, num);
	if(type == KARMA_KILL)
	{
		karmamulti = floatround(get_pcvar_num(cvar_karma_multi)*(g_iPlayerData[victim][PD_KARMATEMP]/1000.0));
		modifier = (3*(g_iMaxPlayers-1)-(num-1))/(g_iMaxPlayers-1);
	}
	else if(type == KARMA_DMG)
	{
		new Float:temp = entity_get_float(victim, EV_FL_dmg_take);
		karmamulti = floatround(temp*0.25) < 1 ? 1 : floatround(temp*get_pcvar_float(cvar_karma_damage));
		modifier = 1;
	}

	new ivictim = get_special_alive(victim);
	new iattacker = get_special_alive(attacker);

	switch(iattacker)
	{
		case PC_TRAITOR: //attacker is traitor
		{
			switch(ivictim)
			{
				case PC_TRAITOR:					g_iPlayerData[attacker][PD_KARMATEMP] -= karmamulti*modifier;
				case PC_DETECTIVE, PC_INNOCENT:		g_iPlayerData[attacker][PD_KARMATEMP] += karmamulti/modifier;
			}
		}
		case PC_DETECTIVE, PC_INNOCENT: //attacker is detective or innocent
		{
			switch(ivictim)
			{
				case PC_TRAITOR:					g_iPlayerData[attacker][PD_KARMATEMP] += karmamulti/modifier;
				case PC_DETECTIVE, PC_INNOCENT:		g_iPlayerData[attacker][PD_KARMATEMP] -= karmamulti*modifier;
			}
		}
	}

	karma_reset(attacker);
}

stock karma_reset(id)
{
	if(g_iPlayerData[id][PD_KARMATEMP] > 1000)
		g_iPlayerData[id][PD_KARMATEMP] = 1000;
	else if(g_iPlayerData[id][PD_KARMATEMP] < 1)
		g_iPlayerData[id][PD_KARMATEMP] = 0;
}

stock set_game_state(new_state)
{
	ttt_log_to_file(LOG_GAMETYPE, "[PRE ] Gamemode: %s", g_szGameModes[g_iGlobalInfo[GI_GAMEMODE]]);
	if(get_game_state() && get_game_state() < GAME_ENDED && new_state == GAME_RESTARTING)
		log_amx("[TTT] Game has restarted :( (game: %d)", get_game_state());

	g_iGlobalInfo[GI_GAMEMODE] = new_state;

	new ret;
	ExecuteForward(g_iGameModeForward, ret, new_state);
	ttt_log_to_file(LOG_GAMETYPE, "[POST] Gamemode: %s", g_szGameModes[g_iGlobalInfo[GI_GAMEMODE]]);
}

stock get_game_state()
	return g_iGlobalInfo[GI_GAMEMODE];

stock get_special_state(id)
	return g_iPlayerData[id][PD_PLAYERSTATE];

stock get_special_alive(id)
{
	if(!is_user_alive(id))
		return g_iPlayerData[id][PD_KILLEDSTATE];

	return get_special_state(id);
}

stock set_special_state(id, new_state)
{
	if(!is_user_connected(id))
		return;

	new player_state = get_special_state(id);
	if(player_state == new_state)
		return;

	set_special_count(player_state, get_special_count(player_state)-1);

	set_player_data(id, PD_PLAYERSTATE, new_state);
	set_special_count(new_state, get_special_count(new_state)+1);
}

stock set_player_data(id, pd, value)
	g_iPlayerData[id][pd] = value;

stock get_player_data(id, pd)
	return g_iPlayerData[id][pd];

stock set_special_count(special_state, count)
	g_iSpecialCount[special_state] = count;

stock get_special_count(special_state)
	return g_iSpecialCount[special_state];

stock set_fake_team(id, getstate)
{
	new num, i, specstate;
	static players[32];
	get_players(players, num);

	for(--num; num >= 0; num--)
	{
		i = players[num];
		specstate = get_special_state(i);
		switch(getstate)
		{
			case PC_INNOCENT, PC_DETECTIVE:
			{
				if(specstate == PC_DETECTIVE)
					set_fake_message(id, i, "CT");
				else set_fake_message(id, i, "TERRORIST");
			}
			case PC_TRAITOR:
			{
				if(specstate == PC_TRAITOR || specstate == PC_DETECTIVE)
				{
					set_fake_message(id, i, "CT");
					if(specstate == PC_DETECTIVE)
						set_attrib_special(i, 4, PC_TRAITOR, PC_NONE, PC_DEAD);
				}
				else set_fake_message(id, i, "TERRORIST");
			}
		}
	}
}

stock set_fake_message(id, i, msg[])
{
	message_begin(MSG_ONE_UNRELIABLE, g_pMsgTeamInfo, _, id);
	write_byte(i);
	write_string(msg);
	message_end();
}

stock Float:get_round_time()
	return get_gametime() - g_fRoundStart - g_fFreezeTime;

stock mynew_register_cvar(name[], string[], description[], flags = 0, Float:fvalue = 0.0)
{
	new_register_cvar(name, string, description);
	return register_cvar(name, string, flags, fvalue);
}

stock new_register_cvar(name[], string[], description[], plug[] = "ttt_core.amxx")
{
	static path[96];
	if(!path[0])
	{
		get_localinfo("amxx_configsdir", path, charsmax(path));
		format(path, charsmax(path), "%s/%s", path, TTT_CONFIGFILE);
	}

	new file;
	if(!g_tCvarsToFile)
		g_tCvarsToFile = TrieCreate();

	if(!file_exists(path))
	{
		file = fopen(path, "wt");
		if(!file)
			return 0;

		fprintf(file, "// Server specific.^n");
		fprintf(file, "%-32s %-8s // %-32s // %s^n", "mp_tkpunish", "0",				plug, "Disables TeamKill punishments");
		fprintf(file, "%-32s %-8s // %-32s // %s^n", "mp_friendlyfire", "1",			plug, "Enables friendly fire to attack teamnates");
		fprintf(file, "%-32s %-8s // %-32s // %s^n", "mp_limitteams", "0",				plug, "Disables team limits");
		fprintf(file, "%-32s %-8s // %-32s // %s^n", "mp_autoteambalance", "0",			plug, "Disables team limits");
		fprintf(file, "%-32s %-8s // %-32s // %s^n", "mp_freezetime", "0",				plug, "Disables freeze time on round start");
		fprintf(file, "%-32s %-8s // %-32s // %s^n", "mp_playerid", "2",				plug, "Disables team info when aiming on player");
		fprintf(file, "%-32s %-8s // %-32s // %s^n", "sv_allktalk", "1",				plug, "Enables alltalk");
		fprintf(file, "%-26s %-14s // %-32s // %s^n", "amx_statscfg", "off PlayerName",	plug, "Disables player name when aiming on player");
		fprintf(file, "^n");
		fprintf(file, "// Mod specific.^n");
	}
	else
	{
		file = fopen(path, "rt");
		if(!file)
			return 0;

		//if(!TrieGetSize(g_tCvarsToFile))
		if(!g_iTrieSize)
		{
			new newline[48];
			static line[128];
			while(!feof(file))
			{
				fgets(file, line, charsmax(line));
				if(line[0] == ';' || !line[0])
					continue;

				parse(line, newline, charsmax(newline));
				remove_quotes(newline);
				#if AMXX_VERSION_NUM >= 183
					TrieSetCell(g_tCvarsToFile, newline, 1, false);
				#else
					TrieSetCell(g_tCvarsToFile, newline, 1);
				#endif
				g_iTrieSize++;
			}
		}
		fclose(file);
		file = fopen(path, "at");
	}

	if(!TrieKeyExists(g_tCvarsToFile, name))
	{
		fprintf(file, "%-32s %-8s // %-32s // %s^n", name, string, plug, description);
		#if AMXX_VERSION_NUM >= 183
			TrieSetCell(g_tCvarsToFile, name, 1, false);
		#else
			TrieSetCell(g_tCvarsToFile, name, 1);
		#endif
		g_iTrieSize++;
	}

	fclose(file);
	return 1;
}

// API
public _set_playerstate(plugin, params)
{
	if(params != 2)
		return ttt_log_api_error("ttt_set_playerstate needs 2 params(p1: %d, p2: %d)", plugin, params, get_param(1), get_param(2));

	set_special_state(get_param(1), get_param(2));
	return 1;
}

public _set_gamemode(plugin, params)
{
	if(params != 1)
		return ttt_log_api_error("ttt_set_gamemode needs 1 param(p1: %d)", plugin, params, get_param(1));

	set_game_state(get_param(1));
	return 1;
}

public _get_specialcount(plugin, params)
{
	if(params != 1)
		return ttt_log_api_error("ttt_get_specialcount needs 1 param(p1: %d)", plugin, params, get_param(1));

	return get_special_count(get_param(1));
}

public Float:_get_roundtime()
	return get_round_time();

public _get_playerdata(plugin, params)
{
	if(params != 2)
		return ttt_log_api_error("ttt_get_playerdata needs 2 params(p1: %d, p2: %d)", plugin, params, get_param(1), get_param(2));

	return get_player_data(get_param(1), get_param(2));
}

public _set_playerdata(plugin, params)
{
	if(params != 3)
		return ttt_log_api_error("ttt_set_playerdata needs 3 params(p1: %d, p2: %d, p3: %d)", plugin, params, get_param(1), get_param(2), get_param(3));

	new id = get_param(1);
	new datatype = get_param(2);
	set_player_data(id, datatype, get_param(3));
	if(datatype == PD_KARMATEMP)
		karma_reset(id);

	return 1;
}

public _get_globalinfo(plugin, params)
{
	if(params != 1)
		return ttt_log_api_error("ttt_get_globalinfo needs 1 param(p1: %d)", plugin, params, get_param(1));

	return g_iGlobalInfo[get_param(1)];
}

public _set_globalinfo(plugin, params)
{
	if(params != 2)
		return ttt_log_api_error("ttt_set_globalinfo needs 2 params(p1: %d, p2: %d)", plugin, params, get_param(1), get_param(2));

	g_iGlobalInfo[get_param(1)] = get_param(2);
	return 1;
}

public _register_cvar(plugin, params)
{
	if(params != 3)
		return ttt_log_api_error("ttt_register_cvar needs 3 params", plugin, params);

	static name[48], string[16], pluginname[48], description[128];
	get_string(1, name, charsmax(name));
	get_string(2, string, charsmax(string));
	get_string(3, description, charsmax(description));
	get_plugin(plugin, pluginname, charsmax(pluginname));

	return new_register_cvar(name, string, description, pluginname);
}

public _add_exception(plugin, params)
{
	if(params != 1)
		return ttt_log_api_error("ttt_add_exception needs 1 param(p1: %d)", plugin, params, get_param(1));

	static const size = sizeof(g_iExceptionItems);
	for(new i = 0; i < size; i++)
	{
		if(g_iExceptionItems[i] == -2)
		{
			g_iExceptionItems[i] = get_param(1);
			return 1;
		}
	}

	return 0;
}

public _find_exception(plugin, params)
{
	if(params != 1)
		return ttt_log_api_error("ttt_find_exception needs 1 param(p1: %d)", plugin, params, get_param(1));

	new item = get_param(1);
	static const size = sizeof(g_iExceptionItems);
	for(new i = 0; i < size; i++)
	{
		if(g_iExceptionItems[i] == item)
			return 1;
	}

	return 0;
}
