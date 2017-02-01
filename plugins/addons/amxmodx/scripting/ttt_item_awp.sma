#include <amxmodx>
#include <engine>
#include <cs_weapons_api>
#include <amx_settings_api>
#include <ttt>

#define WEAPON_CSWID CSW_AWP
#define WEAPON_NAME "weapon_awp"

new g_iItemID;
new g_szModels[3][TTT_FILELENGHT];
new cvar_weapon_damage, cvar_weapon_speed, cvar_weapon_ammo, cvar_weapon_clip, cvar_weapon_price, cvar_weapon_reload, cvar_weapon_recoil;

public plugin_precache()
{
	if(!amx_load_setting_string(TTT_SETTINGSFILE, "AWP", "MODEL_V", g_szModels[0], charsmax(g_szModels[])))
	{
		g_szModels[0] = "models/v_awp.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "AWP", "MODEL_V", g_szModels[0]);
	}
	precache_model(g_szModels[0]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "AWP", "MODEL_P", g_szModels[1], charsmax(g_szModels[])))
	{
		g_szModels[1] = "models/p_awp.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "AWP", "MODEL_P", g_szModels[1]);
	}
	precache_model(g_szModels[1]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "AWP", "MODEL_W", g_szModels[2], charsmax(g_szModels[])))
	{
		g_szModels[2] = "models/w_awp.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "AWP", "MODEL_W", g_szModels[2]);
	}
	precache_model(g_szModels[2]);
}

public plugin_init()
{
	register_plugin("[TTT] Item: AWP", TTT_VERSION, TTT_AUTHOR);

	cvar_weapon_clip	= my_register_cvar("ttt_awp_clip",		"1",	"AWP clip ammo. (Default: 1)");
	cvar_weapon_ammo	= my_register_cvar("ttt_awp_ammo",		"15",	"AWP backpack ammo. (Default: 15)");
	cvar_weapon_speed	= my_register_cvar("ttt_awp_speed",		"0.0",	"AWP attack speed delay. (Default: 0.0)");
	cvar_weapon_damage	= my_register_cvar("ttt_awp_damage",	"1.0",	"AWP damage multiplier. (Default: 1.0)");
	cvar_weapon_reload	= my_register_cvar("ttt_awp_reload",	"0.0",	"AWP reloadspeed delay. (Default: 0.0)");
	cvar_weapon_recoil	= my_register_cvar("ttt_awp_recoil",	"0.0",	"AWP recoil multiplier. (Default: 0.0)");
	cvar_weapon_price	= my_register_cvar("ttt_price_awp",		"1",	"AWP price. (Default: 1)");
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID15");
	g_iItemID = ttt_buymenu_add(name, get_pcvar_num(cvar_weapon_price), PC_TRAITOR);
}

public ttt_item_selected(id, item, name[], price)
{
	if(g_iItemID == item)
	{
		if(user_has_weapon(id, WEAPON_CSWID))
			engclient_cmd(id, "drop", WEAPON_NAME);

		static data[STOREABLE_STRUCTURE];
		if(!data[STRUCT_CSWA_CSW])
		{
			data[STRUCT_CSWA_ITEMID] = g_iItemID;
			data[STRUCT_CSWA_CSW] = WEAPON_CSWID;
			data[STRUCT_CSWA_CLIP] = get_pcvar_num(cvar_weapon_clip);
			data[STRUCT_CSWA_MAXCLIP] = get_pcvar_num(cvar_weapon_clip);
			data[STRUCT_CSWA_AMMO] = get_pcvar_num(cvar_weapon_ammo);
			data[STRUCT_CSWA_STACKABLE] = true;
			data[STRUCT_CSWA_SILENCED] = -1;
			data[STRUCT_CSWA_SPEEDDELAY] = _:get_pcvar_float(cvar_weapon_speed);
			data[STRUCT_CSWA_DAMAGE] = _:get_pcvar_float(cvar_weapon_damage);
			data[STRUCT_CSWA_RELOADTIME] = _:get_pcvar_float(cvar_weapon_reload);
			data[STRUCT_CSWA_RECOIL] = _:get_pcvar_float(cvar_weapon_recoil);
			data[STRUCT_CSWA_MODEL_V] = g_szModels[0];
			data[STRUCT_CSWA_MODEL_P] = g_szModels[1];
			data[STRUCT_CSWA_MODEL_W] = g_szModels[2];
		}

		cswa_give_specific(id, data);

		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_ITEM5");
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}