#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <ttt>
#include <amx_settings_api>

new g_iHasDeathStation[33], g_iSetupItem[33] = {-1, -1, ...}, g_iItem_Backpack[33];
new cvar_price_ds, g_iItem_DeathStation, g_iItemBought;
new g_szDeathStationModel[TTT_FILELENGHT];

public plugin_precache()
{

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Health/Death Station", "MODEL", g_szDeathStationModel, charsmax(g_szDeathStationModel)))
	{
		g_szDeathStationModel = "models/ttt/hpbox.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Health/Death Station", "MODEL", g_szDeathStationModel);
	}

	precache_model(g_szDeathStationModel);
}

public plugin_init()
{
	register_plugin("[TTT] Item: Death Station", TTT_VERSION, TTT_AUTHOR);

	cvar_price_ds = my_register_cvar("ttt_price_ds", "2", "DeathStation price. (Default: 2)");

	register_think(TTT_DEATHSTATION, "DeathStation_Think");
	register_forward(FM_EmitSound, "Forward_EmitSound_pre", 0);
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID8");
	g_iItem_DeathStation = ttt_buymenu_add(name, get_pcvar_num(cvar_price_ds), PC_TRAITOR);
	ttt_add_exception(g_iItem_DeathStation);
}

public ttt_gamemode(gamemode)
{
	if(!g_iItemBought)
		return;

	if(gamemode == GAME_ENDED || gamemode == GAME_RESTARTING)
		remove_entity_name(TTT_DEATHSTATION);

	if(gamemode == GAME_PREPARING || gamemode == GAME_RESTARTING)
	{
		new num, id;
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];
			g_iHasDeathStation[id] = false;
			g_iItem_Backpack[id] = -1;
			g_iSetupItem[id] = -1;
		}
		g_iItemBought = false;
	}
}

public ttt_item_selected(id, item, name[], price)
{
	if(g_iItem_DeathStation == item)
	{
		g_iHasDeathStation[id] = true;
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_ITEM_BACKPACK", name);
		g_iItem_Backpack[id] = ttt_backpack_add(id, name);
		g_iItemBought = true;
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public ttt_item_backpack(id, item, name[])
{
	if(g_iHasDeathStation[id] && g_iItem_Backpack[id] == item)
	{
		new origin1[3], origin2[3];
		get_user_origin(id, origin1, 3);
		get_user_origin(id, origin2, 0);
		new dist = get_distance(origin1, origin2);
	
		if(40 < dist < 100)
		{
			g_iHasDeathStation[id] = false;
			death_station_create(id, origin1, name);
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

public Forward_EmitSound_pre(id, channel, sample[])
{
	if(!g_iItemBought || !is_user_alive(id) || ttt_return_check(id))
		return;

	if(equal(sample, "common/wpn_denyselect.wav"))
	{
		new ent, body;
		get_user_aiming(id, ent, body, 50);
		if(ent > 0)
		{
			static classname[32];
			entity_get_string(ent, EV_SZ_classname, classname, charsmax(classname));
			if(equal(classname, TTT_DEATHSTATION))
			{
				ttt_set_playerdata(id, PD_KILLEDBYITEM, g_iItem_DeathStation);
				ExecuteHamB(Ham_Killed, id, entity_get_int(ent, EV_INT_iuser1), 2);
			}
		}
	}
}

public death_station_create(id, origin[3], name[])
{
	new ent = create_entity("info_target");
	entity_set_string(ent, EV_SZ_classname, TTT_DEATHSTATION);

	entity_set_model(ent, g_szDeathStationModel);
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

	g_iSetupItem[id] = ttt_item_setup_add(g_iItem_DeathStation, ent, 120, id, 0, 1, name); //ITEM: ID, ENT, TIMER, OWNER, TRACER, ACTIVE, NAME
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0);
}

public DeathStation_Think(ent)
{
	if(!g_iItemBought)
		return;

	new id = entity_get_int(ent, EV_INT_iuser1);
	if(g_iSetupItem[id] == -1)
		return;

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