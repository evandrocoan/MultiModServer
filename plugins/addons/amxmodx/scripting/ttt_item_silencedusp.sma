#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <cs_weapons_api>
#include <amx_settings_api>
#include <ttt>

#define OFFSET_LINUX_WEAPONS		4
#define m_iPlayer					41
#define m_flNextSecondaryAttack		47

#define WEAPON_CSWID CSW_USP
#define WEAPON_NAME "weapon_usp"

new g_iItemID;
new g_szModels[3][TTT_FILELENGHT];
new cvar_weapon_damage, cvar_weapon_speed, cvar_weapon_ammo, cvar_weapon_clip, cvar_weapon_price, cvar_weapon_reload, cvar_weapon_recoil;

public plugin_precache()
{
	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Silenced USP", "MODEL_V", g_szModels[0], charsmax(g_szModels[])))
	{
		g_szModels[0] = "models/ttt/v_silencedusp.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Silenced USP", "MODEL_V", g_szModels[0]);
	}
	precache_model(g_szModels[0]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Silenced USP", "MODEL_P", g_szModels[1], charsmax(g_szModels[])))
	{
		g_szModels[1] = "models/ttt/p_silencedusp.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Silenced USP", "MODEL_P", g_szModels[1]);
	}
	precache_model(g_szModels[1]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Silenced USP", "MODEL_W", g_szModels[2], charsmax(g_szModels[])))
	{
		g_szModels[2] = "models/ttt/w_silencedusp.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Silenced USP", "MODEL_W", g_szModels[2]);
	}
	precache_model(g_szModels[2]);
}

public plugin_init()
{
	register_plugin("[TTT] Item: Silent USP", TTT_VERSION, TTT_AUTHOR);

	cvar_weapon_clip	= my_register_cvar("ttt_usp_clip",		"10",	"Silenced USP clip ammo. (Default: 10)");
	cvar_weapon_ammo	= my_register_cvar("ttt_usp_ammo",		"50",	"Silenced USP backpack ammo. (Default: 50)");
	cvar_weapon_speed	= my_register_cvar("ttt_usp_speed",		"0.9",	"Silenced USP attack speed delay. (Default: 0.9)");
	cvar_weapon_damage	= my_register_cvar("ttt_usp_damage",	"2.0",	"Silenced USP damage multiplier. (Default: 2.0)");
	cvar_weapon_reload	= my_register_cvar("ttt_usp_reload",	"0.0",	"Silenced USP reload speed. (Default: 0.0)");
	cvar_weapon_recoil	= my_register_cvar("ttt_usp_recoil",	"0.0",	"Silenced USP recoil. (Default: 0.0)");
	cvar_weapon_price	= my_register_cvar("ttt_price_usp",		"2",	"Silenced USP price. (Default: 2)");

	RegisterHam(Ham_Weapon_SecondaryAttack, WEAPON_NAME, "Ham_SecondaryAttack_pre", 0);
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID10");
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
			data[STRUCT_CSWA_SILENCED] = true;
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

public Ham_SecondaryAttack_pre(ent)
{
	if(!is_valid_ent(ent))
		return HAM_IGNORED;
		
	new id = get_pdata_cbase(ent, m_iPlayer, OFFSET_LINUX_WEAPONS);
	if(is_user_alive(id) && !ttt_return_check(id))
	{
		new ent = find_ent_by_owner(-1, WEAPON_NAME, id);
		if(get_weapon_edict(ent, REPL_CSWA_SET) == 2 && get_weapon_edict(ent, REPL_CSWA_ITEMID) == g_iItemID)
		{
			set_pdata_float(ent, m_flNextSecondaryAttack, 9999.0, OFFSET_LINUX_WEAPONS);
			return HAM_SUPERCEDE;
		}
	}

	return HAM_IGNORED;
}