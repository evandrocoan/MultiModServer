#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <cs_weapons_api>
#include <ttt>
#include <xs>
#include <amx_settings_api>

#define MAX_C4 5

new const g_szC4Sounds[][] =
{
	"weapons/c4_beep1.wav",
	"weapons/c4_beep2.wav",
	"weapons/c4_beep3.wav",
	"weapons/c4_beep4.wav",
	"weapons/c4_beep5.wav",
	"radio/bombdef.wav",
	"radio/bombpl.wav",
	"weapons/c4_plant.wav"	
};

new const g_szC4Sprite[] = "sprites/ttt/c4_sprite.spr";

enum _:C4INFO
{
	C4STORED,
	C4ENT,
	C4SUB,
	C4TIME,
	C4OWNER
}

new g_iC4Info[MAX_C4][C4INFO], g_iItem_C4, g_iC4Time[33], g_iSetupItem[33] = {-1, -1, ...};
new cvar_c4_maxtime, cvar_c4_mintime, cvar_c4_default, cvar_c4_elapsed, cvar_price_c4;
new g_iC4Sync[MAX_C4], Float:g_fWaitTime[33], g_iC4Sprite, g_iItemBought, g_pBombStatusForward;

public plugin_precache()
{
	// Create_BombTarget();
	new sprites[TTT_FILELENGHT];
	if(!amx_load_setting_string(TTT_SETTINGSFILE, "C4", "Sprite", sprites, charsmax(sprites)))
	{
		amx_save_setting_string(TTT_SETTINGSFILE, "C4", "Sprite", g_szC4Sprite);
		g_iC4Sprite = precache_model(g_szC4Sprite);
	}
	else g_iC4Sprite = precache_model(sprites);
}

public plugin_init()
{
	register_plugin("[TTT] Item: C4", TTT_VERSION, TTT_AUTHOR);

	cvar_c4_default	= my_register_cvar("ttt_c4_default",	"45",	"Default timer for C4. (Default: 45)");
	cvar_c4_maxtime	= my_register_cvar("ttt_c4_maxtime",	"180",	"Max timer for C4. (Default: 180)");
	cvar_c4_mintime	= my_register_cvar("ttt_c4_mintime",	"30",	"Min timer for C4. (Default: 30)");
	cvar_c4_elapsed	= my_register_cvar("ttt_c4_elapsed", 	"45",	"Min round time elapsed to plant C4. (Default: 45)");
	cvar_price_c4	= my_register_cvar("ttt_price_c4", 		"3",	"C4 price. (Default: 3)");

	register_logevent("Event_C4_Att", 3, "2=Dropped_The_Bomb");
	register_logevent("Event_C4_Att", 3, "2=Got_The_Bomb");

	register_forward(FM_EmitSound, "Forward_EmitSound_pre", 0);
	register_forward(FM_CmdStart, "Forward_CmdStart_pre", 0);
	register_think(TTT_C4_SUB, "C4_Think");
	RegisterHamPlayer(Ham_Killed, "Ham_Killed_post", 1);

	g_pBombStatusForward = CreateMultiForward("ttt_bomb_status", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);

	register_clcmd("Set_C4Timer", "C4Timer");
	for(new i = 0; i <= charsmax(g_iC4Sync); i++)
		g_iC4Sync[i] = CreateHudSyncObj();
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID0");
	g_iItem_C4 = ttt_buymenu_add(name, get_pcvar_num(cvar_price_c4), PC_TRAITOR);
	ttt_add_exception(g_iItem_C4);
}

public client_putinserver(id)
	g_iC4Time[id] = get_pcvar_num(cvar_c4_default);

public Ham_Killed_post(victim, killer)
{
	new ent = find_ent_by_model(-1, "weaponbox", "models/w_backpack.mdl");
	if(is_valid_ent(ent))
		remove_entity(ent);
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_ENDED || gamemode == GAME_RESTARTING)
	{
		set_pcvar_num(get_cvar_pointer("mp_c4timer"), get_pcvar_num(cvar_c4_default));
		remove_entity_name("func_bomb_target");
		remove_entity_name("info_bomb_target");
	}
	
	if(gamemode == GAME_PREPARING || gamemode == GAME_RESTARTING)
	{
		Create_BombTarget();

		if(!g_iItemBought)
			return;

		c4_clear_all();
		new num, id, cvar = get_pcvar_num(cvar_c4_default);
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];
			g_iSetupItem[id] = -1;
			g_iC4Time[id] = cvar;
		}
		g_iItemBought = false;
	}
}

public ttt_item_selected(id, item, name[], price)
{
	new cvar = get_pcvar_num(cvar_c4_elapsed);
	if(g_iItem_C4 == item)
	{
		if(ttt_get_roundtime() > float(cvar))
		{
			engclient_cmd(id, "drop", "weapon_c4");
			ham_give_weapon(id, "weapon_c4");
			set_attrib(id);
			cs_set_user_plant(id, 1);
			client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_ITEM_C41");

			g_iItemBought = true;
			return PLUGIN_HANDLED;
		}
		else client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM_C42", name, cvar);
	}

	return PLUGIN_CONTINUE;
}

public ttt_bomb_status(id, status, ent)
{
	if(status == BS_DEFUSED && is_valid_ent(ent))
		c4_clear_one(c4_get(C4ENT, ent));
}

public Event_C4_Att()
{
	new id = get_loguser_index();
	set_attrib(id);
	set_task(0.4, "set_attrib", id);
}

public set_attrib(id)
{
	if(is_user_alive(id))
		cs_set_user_submodel(id, 0);

	set_attrib_all(id, 0);
}

public Forward_CmdStart_pre(id, handle)
{
	if(!g_iItemBought || ttt_get_playerstate(id) != PC_TRAITOR || !is_holding_c4(id))
		return;

	static button;
	button = get_uc(handle, UC_Buttons);
	static oldbutton;
	oldbutton = entity_get_int(id, EV_INT_oldbuttons);
	if((button & IN_ATTACK2) && !(oldbutton & IN_ATTACK2))
	{
		set_uc(handle, UC_Buttons, button & ~IN_ATTACK2);
		client_cmd(id, "messagemode Set_C4Timer");
	}
}

public Forward_EmitSound_pre(ent, channel, const sound[])
{
	if(!g_iItemBought)
		return FMRES_HANDLED;

	for(new i = 0; i < sizeof(g_szC4Sounds); i++)
		if(equali(sound, g_szC4Sounds[i]))
			return FMRES_SUPERCEDE;

	return FMRES_HANDLED;
}

public Create_BombTarget()
{
	new NewBombTarget = create_entity("func_bomb_target");
	DispatchSpawn(NewBombTarget);
	entity_set_size(NewBombTarget, Float:{-8191.0, -8191.0, -8191.0}, Float:{8191.0, 8191.0, 8191.0});
}

public bomb_planted(id)
{
	new ent = create_entity("info_target");
	entity_set_string(ent, EV_SZ_classname, TTT_C4_SUB);

	set_task(0.5, "set_attrib", id);
	set_task(0.1, "set_c4_info", id);

	new Float:fOrigin[3];
	entity_get_vector(id, EV_VEC_origin, fOrigin);

	new Float:fVelocity[3];
	velocity_by_aim(id, 54, fVelocity);

	if(fVelocity[2] < -28.0)
		return;

	new Float:fTraceEnd[3];
	xs_vec_add(fVelocity, fOrigin, fTraceEnd);

	new Float:fTraceResult[3];
	trace_line(id, fOrigin, fTraceEnd, fTraceResult);

	new Float:fNormal[3];
	if(trace_normal(id, fOrigin, fTraceEnd, fNormal) < 1)
		return;

	new c4 = -1, Float:fNewOrigin[3], Float:fAngles[3];
	while((c4 = find_ent_by_model(c4, "grenade", "models/w_c4.mdl")))
	{
		if(!is_valid_ent(c4) || entity_get_int(c4, EV_INT_movetype) == MOVETYPE_FLY 
		|| (entity_get_int(c4, EV_INT_flags) & FL_ONGROUND))
			continue;

		entity_set_int(c4, EV_INT_movetype, MOVETYPE_FLY);

		fNewOrigin[0] = fTraceResult[0] + (fNormal[0] * -0.01);
		fNewOrigin[1] = fTraceResult[1] + (fNormal[1] * -0.01);
		fNewOrigin[2] = fTraceResult[2] +  fNormal[2] + 8.000;
		entity_set_origin(c4, fNewOrigin);

		vector_to_angle(fNormal, fAngles);
		fAngles[0] -= 180.0, fAngles[1] -= 90.0, fAngles[2] -= 90.0;

		entity_set_vector(c4, EV_VEC_angles, fAngles);
		entity_set_float(c4, EV_FL_fuser1, 1.0);
		entity_set_float(c4, EV_FL_dmg, 1.0);
	}
}

public set_c4_info(id)
{
	if(ttt_return_check(id))
		return;

	new c4 = -1, c4id, ret;
	static out[32];
	formatex(out, charsmax(out), "%L", id, "TTT_ITEM_ID0");
	while((c4 = find_ent_by_model(c4, "grenade", "models/w_c4.mdl")))
	{
		if(is_valid_ent(c4) && !entity_get_int(c4, EV_INT_iuser1))
		{
			ExecuteForward(g_pBombStatusForward, ret, id, BS_PLANTED, c4);
			if(!g_iC4Time[id])
				g_iC4Time[id] = get_pcvar_num(cvar_c4_default);

			c4id = c4_store(c4);
			entity_set_int(c4, EV_INT_iuser1, id);
			entity_set_edict(c4, EV_ENT_owner, id);

			g_iC4Info[c4id][C4OWNER] = id;
			g_iC4Info[c4id][C4TIME] = g_iC4Time[id];
			g_iSetupItem[id] = ttt_item_setup_add(g_iItem_C4, c4, 120, id, 0, 1, out); //ITEM: ID, ENT, TIMER, OWNER, TRACER, ACTIVE, NAME

			cs_set_c4_explode_time(c4, get_gametime()+ float(g_iC4Info[c4id][C4TIME]) + 0.9);
		}
	}

	new sub_c4 = -1;
	while((sub_c4 = find_ent_by_class(sub_c4, TTT_C4_SUB)))
	{
		if(is_valid_ent(sub_c4) && !entity_get_int(sub_c4, EV_INT_iuser1))
		{
			g_iC4Info[c4id][C4SUB] = sub_c4;
			entity_set_int(sub_c4, EV_INT_iuser1, id);
			entity_set_float(sub_c4, EV_FL_nextthink, get_gametime() + 0.9);
		}
	}
}

public C4Timer(id)
{
	static number[32];
	read_argv(1, number, charsmax(number));

	new time_min = get_pcvar_num(cvar_c4_mintime), time_max = get_pcvar_num(cvar_c4_maxtime);
	if(is_str_num(number))
	{
		new time_cur = str_to_num(number);
		if(time_min <= time_cur <= time_max)
		{
			g_iC4Time[id] = time_cur;
			client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_C42", time_cur);
		}
		else client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_C41", time_min, time_max);
	}
	else client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_C41", time_min, time_max);

	return PLUGIN_HANDLED;
}

public C4_Think(ent)
{
	if(!g_iItemBought || !is_valid_ent(ent))
		return;

	// TIME
	new id = entity_get_int(ent, EV_INT_iuser1), c4id = c4_get(C4SUB, ent);
	set_c4_counter(id, g_iC4Info[c4id][C4TIME], c4id);
	g_iC4Info[c4id][C4TIME]--;

	if(!is_valid_ent(g_iC4Info[c4id][C4ENT]))
	{
		ttt_set_playerdata(id, PD_C4EXPLODED, true);

		entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1000.0);
		// c4_clear_one(c4id);
		new ret;
		ExecuteForward(g_pBombStatusForward, ret, id, BS_BOMBED, g_iC4Info[c4id][C4ENT]);
	}
	else entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0);

	// DNA
	static data[SETUP_DATA];
	ttt_item_setup_get(g_iSetupItem[id], data);
	if(data[SETUP_ITEMTIME] > 0)
	{
		data[SETUP_ITEMTIME]--;
		ttt_item_setup_update(g_iSetupItem[id], data);
	}
}

public client_PostThink(id)
{
	if(!g_iItemBought || !is_user_alive(id) || g_fWaitTime[id] + 0.1 > get_gametime() || ttt_get_playerstate(id) != PC_TRAITOR)
		return;

	g_fWaitTime[id] = get_gametime();
	static Float:origin[3];
	for(new i = 0; i < MAX_C4; i++)
	{
		if(g_iC4Info[i][C4STORED] && is_valid_ent(g_iC4Info[i][C4ENT]))
		{
			entity_get_vector(g_iC4Info[i][C4ENT], EV_VEC_origin, origin);
			origin[2] +=30.0;
			create_icon_origin(id, origin, g_iC4Sprite, 1);
		}
	}
}

public set_c4_counter(id, time, move)
{
	if(time > 0)
	{
		new num, i;
		static players[32], name[32];
		get_user_name(id, name, charsmax(name));
		get_players(players, num, "c");
		for(--num; num >= 0; num--)
		{
			i = players[num];
			if(ttt_get_playerstate(i) == PC_TRAITOR || ttt_get_playerstate(i) == PC_DEAD)
			{
				set_hudmessage(255, 50, 0, 0.02, 0.2+(0.03*move), 0, 6.0, 1.1, 0.0, 0.0, -1);
				ShowSyncHudMsg(i, g_iC4Sync[move], "[%s C4 EXPLODES IN = %d]", name, time);
			}
		}
	}
}

stock c4_store(c4)
{
	for(new i = 0; i < MAX_C4; i++)
	{
		if(!g_iC4Info[i][C4STORED])
		{
			g_iC4Info[i][C4STORED] = 1;
			g_iC4Info[i][C4ENT] = c4;
			return i;
		}
	}

	return -1;
}

stock c4_get(find, what)
{
	for(new i = 0; i < MAX_C4; i++)
	{
		if(g_iC4Info[i][find] == what)
			return i;
	}

	return -1;
}

stock c4_clear_all()
{
	for(new i = 0; i < MAX_C4; i++)
	{
		c4_clear_one(i);
	}
}

stock c4_clear_one(index)
{
	new cvar = get_pcvar_num(cvar_c4_default);
	for(new i = 0; i < C4INFO; i++)
	{
		if(i == C4ENT || i == C4SUB)
		{
			c4_remove_ent(g_iC4Info[index][i]);
			g_iC4Info[index][i] = 0;
		}
		if(i == C4TIME)
			g_iC4Info[index][i] = cvar;
		else g_iC4Info[index][i] = 0;
	}
}

stock c4_remove_ent(ent)
{
	if(is_valid_ent(ent))
		remove_entity(ent);
}

stock get_loguser_index()
{
	static loguser[80], name[32];
	read_logargv(0, loguser, charsmax(loguser));
	parse_loguser(loguser, name, charsmax(name));

	return get_user_index(name);
}

stock is_holding_c4(id)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_C4 && !is_holding_dna_scanner(id))
		return 1;

	return 0;
}