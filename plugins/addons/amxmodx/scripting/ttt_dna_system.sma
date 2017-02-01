#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <cs_weapons_api>
#include <ttt>
#include <xs>

new const DNA_TRACE[] = "sprites/ttt/dna_trace.spr";
new const DNA_CALL[] = "sprites/ttt/dna_call.spr";

new g_iBodyEnts[33], g_iBodyCount;
new g_iTracing[33], Float:g_fTracingOrigin[33][3], Float:g_fWaitTime[33], g_iBackpack[33];
new g_iTraceSprite, g_iCallSprite, g_Msg_BarTime, g_Max_Players;

public plugin_precache()
{
	g_iTraceSprite = precache_model(DNA_TRACE);
	g_iCallSprite = precache_model(DNA_CALL);
}

public plugin_init()
{
	register_plugin("[TTT] DNA System", TTT_VERSION, TTT_AUTHOR);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_c4", "Ham_PrimaryAttack_pre", 0);

	g_Msg_BarTime	=	get_user_msgid("BarTime");
	g_Max_Players	=	get_maxplayers();
}

public client_disconnect(id)
{
	ttt_clear_bodydata(g_iTracing[id]);
	g_iTracing[id] = 0;
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_ENDED || gamemode == GAME_RESTARTING)
	{
		for(new i = 0; i < g_iBodyCount; i++)
			g_iBodyEnts[i] = false;
		g_iBodyCount = 0;
	}

	if(gamemode == GAME_PREPARING || gamemode == GAME_STARTED || gamemode == GAME_RESTARTING)
	{

		new num, id;
		static players[32], out[TTT_ITEMLENGHT];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];

			if(gamemode == GAME_PREPARING || gamemode == GAME_RESTARTING)
			{
				if(is_user_connected(g_iTracing[id]))
					ttt_clear_bodydata(g_iTracing[id]);

				g_iTracing[id] = false;
				g_iBackpack[id] = -1;
			}

			if(gamemode == GAME_STARTED && ttt_get_playerstate(id) != PC_DETECTIVE)
			{
				formatex(out, charsmax(out), "%L", id, "TTT_CALLDETECTIVE");
				g_iBackpack[id] = ttt_backpack_add(id, out);
			}
		}
	}
}

public ttt_spawnbody(owner, ent)
{
	g_iBodyEnts[g_iBodyCount] = ent;
	g_iBodyCount++;
}

public ttt_item_backpack(id, item, name[])
{
	if(g_iBackpack[id] == item)
	{
		new ent = find_dead_body_1d(id, g_iBodyEnts, g_iBodyCount);
		if(ent)
		{
			new victim = entity_get_int(ent, EV_INT_iuser1);
			if(!ttt_get_playerdata(victim, PD_IDENTIFIED))
			{
				if(ttt_get_bodydata(victim, BODY_CALLD))
					client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_CALLDETECTIVE3", id, "TTT_DEADBODY");
				else
				{
					ttt_set_bodydata(victim, BODY_CALLD, 1);
					client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_CALLDETECTIVE2", id, "TTT_DEADBODY");
				}
			}
		}
		else client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_NOBODY", id, "TTT_DEADBODY");
		ttt_backpack_show(id);
	}

	return PLUGIN_CONTINUE;
}

public Ham_PrimaryAttack_pre(ent)
{
	new id = entity_get_edict(ent, EV_ENT_owner);
	if(!is_user_alive(id) || ttt_get_gamemode() == GAME_OFF || ttt_get_gamemode() == GAME_ENDED || id == entity_get_int(id, EV_INT_iuser2))
		return HAM_IGNORED;

	if(is_holding_dna_scanner(id))
	{
		used_mouse2(id);
		return HAM_SUPERCEDE;
	}

	return HAM_HANDLED;
}

public used_mouse2(id)
{
	if(!is_user_alive(id))
		return;

	client_cmd(id, "-attack");

	static name[2][32];
	get_user_name(id, name[0], charsmax(name[]));
	new ent = find_dead_body_1d(id, g_iBodyEnts, g_iBodyCount);
	if(ent)
	{
		new victim = entity_get_int(ent, EV_INT_iuser1);
		if(ttt_get_bodydata(victim, BODY_ACTIVE) == 1)
		{
			get_user_name(victim, name[1], charsmax(name[]));
			ttt_log_to_file(LOG_MISC, "%s started to trace DNA of %s (ent: %d)", name[0], name[1], ent);
			dna_make_it(id, victim, 0);
		}
		else client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_DNASAMPLE_MISSING");
	}
	else
	{
		new body;
		get_user_aiming(id, ent, body);
		new itemid = ttt_is_item_setup(ent);
		if(itemid > -1)
		{
			static data[SETUP_DATA];
			ttt_item_setup_get(itemid, data);
			if(data[SETUP_ITEMACTIVE])
			{
				ttt_log_to_file(LOG_MISC, "%s started to trace DNA of %d item (ent: %d)", name[0], itemid, ent);
				dna_make_it(id, ent, itemid);
			}
		}
	}
}

public dna_make_it(id, target, itemid)
{
	if(task_exists(id))
	{
		if(is_user_connected(g_iTracing[id]))
			ttt_clear_bodydata(g_iTracing[id]);

		dna_print_text(id, "TTT_DNASAMPLE2");
		remove_task(id);
	}

	g_iTracing[id] = target;

	message_begin(MSG_ONE_UNRELIABLE, g_Msg_BarTime, _, id);
	write_short(1);
	message_end();

	dna_print_text(id, "TTT_DNASAMPLE3");
	if(is_user_connected(target))
	{
		ttt_set_bodydata(target, BODY_TRACER, id);
		ttt_set_bodydata(target, BODY_ACTIVE, 0);
		ttt_set_bodydata(target, BODY_CALLD, 0);
	}
	else
	{
		static data[SETUP_DATA];
		ttt_item_setup_get(itemid, data);
		data[SETUP_ITEMTRACER] = id;
		data[SETUP_ITEMACTIVE] = 0;
		ttt_item_setup_update(itemid, data);
	}

	set_task(1.0, "dna_owner_origin", id);
}

public dna_owner_origin(id)
{
	new time, dnaowner, source = g_iTracing[id];
	if(source < 33 && source > 0)
	{
		time = ttt_get_bodydata(source, BODY_TIME);
		dnaowner = ttt_get_bodydata(source, BODY_KILLER);
	}
	else
	{
		new itemid = ttt_is_item_setup(source);

		if(itemid > -1)
		{
			static data[SETUP_DATA];
			ttt_item_setup_get(itemid, data);
			time = data[SETUP_ITEMTIME];
			dnaowner = data[SETUP_ITEMOWNER];
		}
	}

	if(!is_user_alive(dnaowner) || time < 5)
	{
		dna_print_text(id, "TTT_DNASAMPLE1");
		if(task_exists(id))
			remove_task(id);
		g_iTracing[id] = 0;
		return;
	}
	
	new Float:distance = time/0.05;
	entity_get_vector(dnaowner, EV_VEC_origin, g_fTracingOrigin[id]);
	set_task(20.0-distance/120.0, "dna_owner_origin", id);
}

public dna_print_text(id, msg[])
{
	if(is_user_connected(g_iTracing[id]))
	{
		static name[32];
		get_user_name(g_iTracing[id], name, charsmax(name));
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, msg, name);
	}
	else 
	{
		new itemid = ttt_is_item_setup(g_iTracing[id]);
		static data[SETUP_DATA];
		ttt_item_setup_get(itemid, data);
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, msg, data[SETUP_ITEMNAME]);
	}
}

public client_PostThink(id)
{
	if(!is_user_alive(id) || ttt_get_playerstate(id) != PC_DETECTIVE || g_fWaitTime[id] + 0.1 > get_gametime())
		return;

	g_fWaitTime[id] = get_gametime();
	static i, Float:origin[3];
	for(i = 1; i <= g_Max_Players; i++)
	{
		if(is_valid_ent(ttt_get_bodydata(i, BODY_ENTID)) && ttt_get_bodydata(i, BODY_CALLD))
		{
			entity_get_vector(ttt_get_bodydata(i, BODY_ENTID), EV_VEC_origin, origin);
			create_icon_origin(id, origin, g_iCallSprite, 35);
		}
	}

	if(!g_iTracing[id])
		return;

	create_icon_origin(id, g_fTracingOrigin[id], g_iTraceSprite, 35);
}