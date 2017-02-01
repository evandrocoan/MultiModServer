#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <fun>
#include <ttt>
#include <amx_settings_api>

enum _:HPSTATION
{
	CHARGE,
	ENT
}

new g_iHPStation[33][HPSTATION], g_iHasHPStation[33], g_iItem_Backpack[33], g_iSetupItem[33] = {-1, -1, ...};
new cvar_price_hp, g_iItem_HPStation, g_Msg_StatusIcon, g_iItemBought;
new g_szHPStationModel[TTT_FILELENGHT];

public plugin_precache()
{
	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Health/Death Station", "MODEL", g_szHPStationModel, charsmax(g_szHPStationModel)))
	{
		g_szHPStationModel = "models/ttt/hpbox.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Health/Death Station", "MODEL", g_szHPStationModel);
	}

	precache_model(g_szHPStationModel);
}

public plugin_init()
{
	register_plugin("[TTT] Item: HP Station", TTT_VERSION, TTT_AUTHOR);
	
	cvar_price_hp = my_register_cvar("ttt_price_hp", "2", "HealthStation price. (Default: 2)");
	RegisterHamPlayer(Ham_ObjectCaps, "Ham_ObjectCaps_pre", 0);
	RegisterHamPlayer(Ham_Killed, "Ham_Killed_pre", 0);

	register_think(TTT_HPSTATION, "HPStation_Think");
	g_Msg_StatusIcon = get_user_msgid("StatusIcon");
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID4");
	g_iItem_HPStation = ttt_buymenu_add(name, get_pcvar_num(cvar_price_hp), PC_DETECTIVE);
}

public ttt_gamemode(gamemode)
{
	if(!g_iItemBought)
		return;

	if(gamemode == GAME_ENDED || gamemode == GAME_RESTARTING)
		remove_entity_name(TTT_HPSTATION);

	if(gamemode == GAME_PREPARING || gamemode == GAME_RESTARTING)
	{
		new num, id;
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];
			g_iItem_Backpack[id] = -1;
			g_iSetupItem[id] = -1;
			g_iHPStation[id][CHARGE] = 0;
			g_iHPStation[id][ENT] = 0;
			g_iHasHPStation[id] = false;
			remove_all(id);
		}
		g_iItemBought = false;
	}
}

public ttt_item_selected(id, item, name[], price)
{
	if(g_iItem_HPStation == item)
	{
		if(g_iHPStation[id][CHARGE] < 1)
		{
			g_iHPStation[id][CHARGE] = random_num(50, 200);
			g_iHasHPStation[id] = true;
			client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_ITEM_BACKPACK", name);
			g_iItem_Backpack[id] = ttt_backpack_add(id, name);
			g_iItemBought = true;
			
			return PLUGIN_HANDLED;
		}
		else client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM1", name);
	}

	return PLUGIN_CONTINUE;
}

public ttt_item_backpack(id, item, name[])
{
	if(g_iHasHPStation[id] && g_iItem_Backpack[id] == item)
	{
		new origin1[3], origin2[3];
		get_user_origin(id, origin1, 3);
		get_user_origin(id, origin2, 0);
		new dist = get_distance(origin1, origin2);
		if(40 < dist < 100)
		{
			g_iHasHPStation[id] = false;
			hp_station_create(id, origin1, name);
			return PLUGIN_HANDLED;
		}
		else
		{
			client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_TOOFARCLOSE", name);
			ttt_backpack_show(id);
		}
	}

	return PLUGIN_CONTINUE;
}

public Ham_Killed_pre(victim, killer, gibs)
{
	remove_all(victim);
}

public Ham_ObjectCaps_pre(id)
{
	if(!g_iItemBought || !is_user_alive(id) || id == entity_get_int(id, EV_INT_iuser2) || !(get_user_button(id) & IN_USE) || task_exists(id) || ttt_return_check(id))
		return HAM_IGNORED;
		
	new ent, body;
	get_user_aiming(id, ent, body);

	if(ent > 0 && entity_range(id, ent) < 50.0)
	{
		static classname[32];
		entity_get_string(ent, EV_SZ_classname, classname, charsmax(classname));
		if(equal(classname, TTT_HPSTATION))
		{
			new health = get_user_health(id);
			if(health >= 100)
			{
				remove_all(id);
				return HAM_IGNORED;
			}

			static name[32];
			get_user_name(id, name, charsmax(name));
			ttt_log_to_file(LOG_ITEM, "%s started healing, HP: %d", name, health);

			g_iHPStation[id][ENT] = ent;
			set_task(0.1, "hp_station_use", id, _, _, "b");
			return HAM_HANDLED;
		}
	}

	return HAM_IGNORED;
}

public hp_station_create(id, origin[3], name[])
{
	new ent = create_entity("info_target");
	entity_set_string(ent, EV_SZ_classname, TTT_HPSTATION);
	
	entity_set_model(ent, g_szHPStationModel);
	entity_set_size(ent, Float:{ -5.0, -5.0, 0.0 }, Float:{ 5.0, 5.0, 5.0 });

	entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);
	
	new Float:fOrigin[3];
	IVecFVec(origin, fOrigin);
	entity_set_origin(ent, fOrigin);
	drop_to_floor(ent);
	entity_set_int(ent, EV_INT_renderfx, kRenderFxGlowShell);

	new Float:colors[3];
	colors[0] = random_float(1.0, 255.0);
	colors[1] = random_float(1.0, 255.0);
	colors[2] = random_float(1.0, 255.0);

	entity_set_vector(ent, EV_VEC_rendercolor, colors);
	entity_set_int(ent, EV_INT_iuser1, id);

	g_iSetupItem[id] = ttt_item_setup_add(g_iItem_HPStation, ent, 120, id, 0, 1, name); //ITEM: ID, ENT, TIMER, OWNER, TRACER, ACTIVE, name
	g_iHPStation[id][ENT] = ent;

	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0);
}

public HPStation_Think(ent)
{
	if(!g_iItemBought || !is_valid_ent(ent))
		return;

	new id = entity_get_int(ent, EV_INT_iuser1);
	static data[SETUP_DATA];
	ttt_item_setup_get(g_iSetupItem[id], data);

	if(data[SETUP_ITEMTIME] != 0)
	{
		data[SETUP_ITEMTIME]--;
		ttt_item_setup_update(g_iSetupItem[id], data);
		entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0);
	}
	else entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1000.0);
}

public hp_station_use(id)
{
	new ent = g_iHPStation[id][ENT];

	if(is_valid_ent(ent))
	{
		show_healicon(id);
		new owner = entity_get_int(ent, EV_INT_iuser1);
		new health = get_user_health(id) +1;

		set_user_health(id, health);
		g_iHPStation[owner][CHARGE]--;

		if(g_iHPStation[owner][CHARGE] < 1)
		{
			remove_entity(ent);
			remove_all(id);
		}

		if(health > 99 || !is_user_alive(id))
			remove_all(id);
	}
	else remove_all(id);

	if(!(get_user_button(id) & IN_USE))
		remove_all(id);

	if(is_valid_ent(ent))
	{
		if(entity_range(id, ent) < 50.0)
			remove_all(id);
	}
}

stock remove_all(id)
{
	if(task_exists(id))
	{
		remove_task(id);
		reset_icons(id);
		static name[32];
		get_user_name(id, name, charsmax(name));
		ttt_log_to_file(LOG_ITEM, "%s ended healing, HP: %d", name, get_user_health(id));
	}
}

stock show_healicon(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_StatusIcon, {0,0,0}, id);
	write_byte(1);
	write_string("cross");
	write_byte(0);
	write_byte(255);
	write_byte(0);
	message_end();
}

stock reset_icons(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_StatusIcon, {0,0,0}, id);
	write_byte(0);
	write_string("cross");
	message_end();		
}