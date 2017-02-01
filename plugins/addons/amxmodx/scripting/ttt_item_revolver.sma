#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <cs_weapons_api>
#include <amx_settings_api>
#include <ttt>

#define WEAPON_CSWID CSW_DEAGLE
#define WEAPON_NAME "weapon_deagle"

new g_iItemID;
new g_szModels[3][TTT_FILELENGHT];
new cvar_weapon_damage, cvar_weapon_speed, cvar_weapon_ammo, cvar_weapon_clip, cvar_weapon_price, cvar_weapon_reload, cvar_weapon_recoil;

public plugin_precache()
{
	precache_sound("weapons/bull_draw.wav");
	precache_sound("weapons/bull_reload.wav");

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Pocket Revolver", "MODEL_V", g_szModels[0], charsmax(g_szModels[])))
	{
		g_szModels[0] = "models/ttt/v_colt.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Pocket Revolver", "MODEL_V", g_szModels[0]);
	}
	precache_model(g_szModels[0]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Pocket Revolver", "MODEL_P", g_szModels[1], charsmax(g_szModels[])))
	{
		g_szModels[1] = "models/ttt/p_colt.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Pocket Revolver", "MODEL_P", g_szModels[1]);
	}
	precache_model(g_szModels[1]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Pocket Revolver", "MODEL_W", g_szModels[2], charsmax(g_szModels[])))
	{
		g_szModels[2] = "models/ttt/w_colt.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Pocket Revolver", "MODEL_W", g_szModels[2]);
	}
	precache_model(g_szModels[2]);
}

public plugin_init()
{
	register_plugin("[TTT] Item: Pocket revolver", TTT_VERSION, TTT_AUTHOR);

	cvar_weapon_clip	= my_register_cvar("ttt_revolver_clip",		"6",	"Pocket Revolver clip ammo. (Default: 6)");
	cvar_weapon_ammo	= my_register_cvar("ttt_revolver_ammo",		"0",	"Pocket Revolver backpack ammo. (Default: 0)");
	cvar_weapon_speed	= my_register_cvar("ttt_revolver_speed",	"1.3",	"Pocket Revolver attack speed delay. (Default: 1.3)");
	cvar_weapon_damage	= my_register_cvar("ttt_revolver_damage",	"0.0",	"Pocket Revolver damage multiplier. (Default: 0.0)");
	cvar_weapon_reload	= my_register_cvar("ttt_revolver_reload",	"0.0",	"Pocket Revolver reload speed. (Default: 0.0)");
	cvar_weapon_recoil	= my_register_cvar("ttt_revolver_recoil",	"0.0",	"Pocket Revolver recoil. (Default: 0.0)");
	cvar_weapon_price	= my_register_cvar("ttt_price_revolver",	"3",	"Pocket Revolver price. (Default: 3)");
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID13");
	g_iItemID = ttt_buymenu_add(name, get_pcvar_num(cvar_weapon_price), PC_DETECTIVE);
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

public cswa_damage(weapon_id, victim, attacker, Float:damage)
{
	if(get_weapon_edict(weapon_id, REPL_CSWA_ITEMID) == g_iItemID)
	{
		ExecuteHamB(Ham_Killed, victim, attacker, 2);
	}
}