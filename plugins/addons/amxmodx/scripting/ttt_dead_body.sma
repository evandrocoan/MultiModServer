#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <ttt>

enum (+= 1111)
{
	TASK_VICTIM = 1111
}

new g_iRoundSpecial[PLAYER_CLASS];
new g_iBodyInfo[33][BODY_DATA];
new g_pShowInfoForward, g_pCreateBodyForward, Float:g_fWaitTime[33];
new cvar_credits_det_trakill, cvar_credits_det_bonusdead, cvar_allow_scan_anytime, cvar_credits_scanned;

public plugin_init()
{
	register_plugin("[TTT] Dead Body", TTT_VERSION, TTT_AUTHOR);

	cvar_credits_det_trakill	= my_register_cvar("ttt_credits_det_trakill",	"1",	"Number of credits for killing a Traitor. (Default: 1)");
	cvar_credits_det_bonusdead	= my_register_cvar("ttt_credits_det_bonusdead",	"1",	"Number of credits for identifieing Traitor body. (Default: 1)");
	cvar_credits_scanned		= my_register_cvar("ttt_karma_scanned",			"10",	"Number of karma to give for identifieing dead body. (Default: 10)");
	cvar_allow_scan_anytime		= my_register_cvar("ttt_allow_scan_anytime",	"0",	"Can be idendified without detective? (Default: 0)");

	register_event("ClCorpse", "Event_ClCorpse", "a", "10=0");
	register_forward(FM_EmitSound, "Forward_EmitSound_pre", 0);
	RegisterHamPlayer(Ham_Killed, "Ham_Killed_post", 1);
	RegisterHamPlayer(Ham_Spawn, "Ham_Spawn_post", 1);

	g_pShowInfoForward = CreateMultiForward("ttt_showinfo", ET_IGNORE, FP_CELL, FP_CELL);
	g_pCreateBodyForward = CreateMultiForward("ttt_spawnbody", ET_IGNORE, FP_CELL, FP_CELL);
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET);
}

public plugin_natives()
{
	register_library("ttt");
	register_native("ttt_get_bodydata", "_get_bodydata");
	register_native("ttt_set_bodydata", "_set_bodydata");
	register_native("ttt_clear_bodydata", "_clear_bodydata");
}

public client_disconnect(id)
{
	if(is_valid_ent(g_iBodyInfo[id][BODY_ENTID]))
		remove_entity(g_iBodyInfo[id][BODY_ENTID]);

	reset_all(id);
}

public Ham_Spawn_post(id)
{
	if(is_user_alive(id))
	{
		if(is_valid_ent(g_iBodyInfo[id][BODY_ENTID]))
		{
			remove_entity(g_iBodyInfo[id][BODY_ENTID]);
			reset_all(id);
		}
	}
}

public Ham_Killed_post(victim, killer, shouldgib)
{
	if(pev(victim, pev_effects) & EF_NODRAW)
		g_iBodyInfo[victim][BODY_EXPLODED] = true;

	if(!is_user_connected(killer))
		killer = ttt_find_valid_killer(victim, killer);

	if(!is_user_connected(killer) || ttt_return_check(victim))
		return HAM_IGNORED;

	new Float:distance = entity_range(killer, victim);
	if(distance > 2399.0)
		distance = 2399.0;
	new timer = floatround((2400.0-distance)*(0.05));

	g_iBodyInfo[victim][BODY_TIME] = timer;
	g_iBodyInfo[victim][BODY_KILLER] = killer;
	g_iBodyInfo[victim][BODY_TRACER] = 0;
	g_iBodyInfo[victim][BODY_ACTIVE] = true;
	g_iBodyInfo[victim][BODY_CALLD] = 0;

	set_task(1.0, "reduce_time", TASK_VICTIM+victim, _, _, "b", timer);
	return HAM_HANDLED;
}

public reduce_time(taskid)
{
	new victim = taskid - TASK_VICTIM, killer = g_iBodyInfo[victim][BODY_KILLER];
	if(!is_user_alive(killer) || g_iBodyInfo[victim][BODY_TIME] < 1)
	{
		remove_task(taskid);
		return;
	}

	g_iBodyInfo[victim][BODY_TIME]--;
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_ENDED || gamemode == GAME_RESTARTING)
		remove_entity_name(TTT_DEADBODY);

	if(gamemode == GAME_PREPARING || gamemode == GAME_RESTARTING)
	{
		new num, id;
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];
			reset_all(id);
		}
	}

	if(gamemode == GAME_STARTED)
		set_task(1.0, "round_specials");
}

public reset_all(id)
{
	for(new i = 0; i < BODY_DATA; i++)
		g_iBodyInfo[id][i] = 0;
}

public round_specials()
{
	for(new i = 0; i < PLAYER_CLASS; i++)
		g_iRoundSpecial[i] = ttt_get_specialcount(i);
}

public Event_ClCorpse()
{
	new id = read_data(12);
	if(ttt_return_check(id) || g_iBodyInfo[id][BODY_EXPLODED])
		return;

	static Float:origin[3], model[32];
	read_data(1, model, charsmax(model));
	origin[0] = read_data(2)/128.0;
	origin[1] = read_data(3)/128.0;
	origin[2] = read_data(4)/128.0;
	new seq = read_data(9);

	create_body(id, origin, model, seq);
}

public create_body(id, Float:origin[3], model[], seq)
{
	new ent = create_entity("info_target");
	g_iBodyInfo[id][BODY_ENTID] = ent;
	new ret;
	ExecuteForward(g_pCreateBodyForward, ret, id, ent);
	entity_set_string(ent, EV_SZ_classname, TTT_DEADBODY);

	static out[64];
	formatex(out, charsmax(out), "models/player/%s/%s.mdl", model, model);
	entity_set_model(ent, out);
	entity_set_origin(ent, origin);
	// entity_set_size(ent, Float:{-16.0, -16.0, -36.0}, Float:{16.0, 16.0, 36.0});
	entity_set_size(ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});

	entity_set_float(ent, EV_FL_frame, 255.0);
	entity_set_int(ent, EV_INT_sequence, seq);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);
	entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER);

	entity_set_int(ent, EV_INT_iuser1, id);

	get_user_name(id, out, charsmax(out));
	ttt_log_to_file(LOG_MISC, "Dead body for %s was created, ent: %d", out, ent);
}

public Forward_EmitSound_pre(id, channel, sample[])
{
	if(!is_user_alive(id) || ttt_return_check(id))
		return;

	if(g_fWaitTime[id] < get_gametime() && equal(sample, "common/wpn_denyselect.wav"))
	{
		new ent = find_dead_body_2d(id, g_iBodyInfo);
		g_fWaitTime[id] = get_gametime() + 1.0;
		if(is_valid_ent(ent))
			used_use(id, ent);
	}
}

public used_use(id, ent)
{
	if(!is_user_alive(id))
		return;

	new bodyowner = entity_get_int(ent, EV_INT_iuser1);
	if(!is_user_connected(bodyowner))
		return;

	new identified = ttt_get_playerdata(bodyowner, PD_IDENTIFIED);
	if(ttt_get_playerstate(id) == PC_DETECTIVE || identified || g_iRoundSpecial[PC_DETECTIVE] == 0 || get_pcvar_num(cvar_allow_scan_anytime))
	{
		if(!identified)
		{
			new scanned = get_pcvar_num(cvar_credits_scanned);
			set_attrib_all(bodyowner, 1);
			ttt_set_playerdata(bodyowner, PD_IDENTIFIED, true);
			ttt_set_playerdata(bodyowner, PD_SCOREBOARD, true);
			g_iBodyInfo[bodyowner][BODY_CALLD] = false;

			if(scanned > 0)
			{
				ttt_set_playerdata(id, PD_KARMATEMP, ttt_get_playerdata(id, PD_KARMATEMP) + scanned);
				client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_AWARD5", scanned);
			}

			if(ttt_get_playerdata(bodyowner, PD_KILLEDSTATE) == PC_TRAITOR && ttt_get_specialcount(PC_DETECTIVE) > 0)
			{
				new bonus_dead = get_pcvar_num(cvar_credits_det_bonusdead), bonus_trakill = get_pcvar_num(cvar_credits_det_trakill), credits;
				new killer = ttt_get_playerdata(bodyowner, PD_KILLEDBY);
				static name[32];
				get_user_name(bodyowner, name, charsmax(name));

				new num, i;
				static players[32];
				get_players(players, num, "a");
				for(--num; num >= 0; num--)
				{
					i = players[num];
					if(ttt_get_playerstate(i) == PC_DETECTIVE)
					{
						credits = ttt_get_playerdata(i, PD_CREDITS);
						ttt_set_playerdata(i, PD_CREDITS, credits + bonus_dead);
						client_print_color(i, print_team_default, "%s %L", TTT_TAG, i, "TTT_AWARD3", bonus_dead, i, special_names[PC_TRAITOR], name);

						if(killer == i)
						{
							ttt_set_playerdata(i, PD_CREDITS, credits + bonus_dead + bonus_trakill);
							client_print_color(i, print_team_default, "%s %L", TTT_TAG, i, "TTT_AWARD2", bonus_trakill, i, special_names[PC_TRAITOR], name);
						}
					}
				}
			}
		}
		new ret;
		ExecuteForward(g_pShowInfoForward, ret, id, bodyowner);
	}
}

public _get_bodydata(plugin, params)
{
	if(params != 2)
		return ttt_log_api_error("ttt_get_bodydata needs 2 params(p1: %d, p2: %d)", plugin, params, get_param(1), get_param(2)) -1;

	return g_iBodyInfo[get_param(1)][get_param(2)];
}

public _set_bodydata(plugin, params)
{
	if(params != 3)
		return ttt_log_api_error("ttt_set_bodydata needs 3 params(p1: %d, p2: %d, p3: %d)", plugin, params, get_param(1), get_param(2), get_param(3));

	g_iBodyInfo[get_param(1)][get_param(2)] = get_param(3);
	return 1;
}

public _clear_bodydata(plugin, params)
{
	if(params != 1)
		return ttt_log_api_error("ttt_clear_bodydata needs 1 param(p1: %d)", plugin, params, get_param(1));

	new body = get_param(1);
	if(task_exists(TASK_VICTIM+body))
		remove_task(TASK_VICTIM+body);

	for(new i = 0; i < sizeof(g_iBodyInfo[]); i++)
		g_iBodyInfo[body][i] = 0;

	return 1;
}