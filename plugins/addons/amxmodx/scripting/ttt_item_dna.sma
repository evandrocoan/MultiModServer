#include <amxmodx>
#include <engine>
#include <cstrike>
#include <hamsandwich>
#include <cs_weapons_api>
#include <amx_settings_api>
#include <ttt>

#define WEAPON_CSWID CSW_C4
#define WEAPON_NAME "weapon_c4"

new g_iItemID;
new g_szModels[3][TTT_FILELENGHT];
new cvar_weapon_price, g_pMsg_StatusIcon;

public plugin_precache()
{
	if(!amx_load_setting_string(TTT_SETTINGSFILE, "DNA Scanner", "MODEL_V", g_szModels[0], charsmax(g_szModels[])))
	{
		g_szModels[0] = "models/ttt/v_dnascanner.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "DNA Scanner", "MODEL_V", g_szModels[0]);
	}
	precache_model(g_szModels[0]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "DNA Scanner", "MODEL_P", g_szModels[1], charsmax(g_szModels[])))
	{
		g_szModels[1] = "models/ttt/p_dnascanner.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "DNA Scanner", "MODEL_P", g_szModels[1]);
	}
	precache_model(g_szModels[1]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "DNA Scanner", "MODEL_W", g_szModels[2], charsmax(g_szModels[])))
	{
		g_szModels[2] = "models/ttt/w_dnascanner.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "DNA Scanner", "MODEL_W", g_szModels[2]);
	}
	precache_model(g_szModels[2]);
}

public plugin_init()
{
	register_plugin("[TTT] Item: DNA Scanner", TTT_VERSION, TTT_AUTHOR);

	cvar_weapon_price = my_register_cvar("ttt_price_dna", "1", "DNA Scanner price. (Default: 1)");
	RegisterHamPlayer(Ham_Killed, "Ham_Killed_post", 1);

	g_pMsg_StatusIcon = get_user_msgid("StatusIcon");
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID5");
	g_iItemID = ttt_buymenu_add(name, get_pcvar_num(cvar_weapon_price), PC_DETECTIVE);
}

public Ham_Killed_post(victim, killer)
{
	new ent = find_ent_by_model(-1, "weaponbox", g_szModels[2]);
	if(is_valid_ent(ent))
		remove_entity(ent);
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
			data[STRUCT_CSWA_CLIP] = -1;
			data[STRUCT_CSWA_MAXCLIP] = -1;
			data[STRUCT_CSWA_AMMO] = -1;
			data[STRUCT_CSWA_STACKABLE] = -1;
			data[STRUCT_CSWA_SILENCED] = -1;
			data[STRUCT_CSWA_SPEEDDELAY] = _:-1.0;
			data[STRUCT_CSWA_DAMAGE] = _:-1.0;
			data[STRUCT_CSWA_RELOADTIME] = _:0.0;
			data[STRUCT_CSWA_RECOIL] = _:0.0;
			data[STRUCT_CSWA_MODEL_V] = g_szModels[0];
			data[STRUCT_CSWA_MODEL_P] = g_szModels[1];
			data[STRUCT_CSWA_MODEL_W] = g_szModels[2];
		}
		cswa_give_specific(id, data);

		set_dna(id);
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_ITEM5");
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

stock set_dna(id)
{
	cs_set_user_plant(id, 0);
	cs_set_user_submodel(id, 0);

	message_begin(MSG_ONE, g_pMsg_StatusIcon, _, id);
	write_byte(0);
	write_string("c4");
	message_end();

	set_attrib_all(id, 4);
}