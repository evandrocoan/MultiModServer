#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <cs_weapons_api>
#include <amx_settings_api>
#include <fun>
#include <ttt>

#define WEAPON_CSWID CSW_DEAGLE
#define WEAPON_NAME "weapon_deagle"

new g_iItemID, g_pMsgScreenFade;
new g_szModels[3][TTT_FILELENGHT];
new cvar_weapon_damage, cvar_weapon_speed, cvar_weapon_ammo, cvar_weapon_clip, cvar_weapon_price, cvar_weapon_reload, cvar_weapon_recoil;
new g_iGlowing[33], g_iAlreadyShot[33];

public plugin_precache()
{
	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Golden Gun", "MODEL_V", g_szModels[0], charsmax(g_szModels[])))
	{
		g_szModels[0] = "models/ttt/v_golden.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Golden Gun", "MODEL_V", g_szModels[0]);
	}
	precache_model(g_szModels[0]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Golden Gun", "MODEL_P", g_szModels[1], charsmax(g_szModels[])))
	{
		g_szModels[1] = "models/ttt/p_golden.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Golden Gun", "MODEL_P", g_szModels[1]);
	}
	precache_model(g_szModels[1]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Golden Gun", "MODEL_W", g_szModels[2], charsmax(g_szModels[])))
	{
		g_szModels[2] = "models/ttt/w_golden.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Golden Gun", "MODEL_W", g_szModels[2]);
	}
	precache_model(g_szModels[2]);
}

public plugin_init()
{
	register_plugin("[TTT] Item: Golden Gun", TTT_VERSION, TTT_AUTHOR);

	cvar_weapon_clip	= my_register_cvar("ttt_golden_clip",	"1",	"Golden Gun clip ammo. (Default: 1)");
	cvar_weapon_ammo	= my_register_cvar("ttt_golden_ammo",	"0",	"Golden Gun backpack ammo. (Default: 0)");
	cvar_weapon_speed	= my_register_cvar("ttt_golden_speed",	"0.1",	"Golden Gun attack speed delay. (Default: 0.1)");
	cvar_weapon_damage	= my_register_cvar("ttt_golden_damage",	"0.0",	"Golden Gun damage multiplier. (Default: 0.0)");
	cvar_weapon_reload	= my_register_cvar("ttt_golden_reload",	"0.0",	"Golden Gun reload speed. (Default: 0.0)");
	cvar_weapon_recoil	= my_register_cvar("ttt_golden_recoil",	"0.0",	"Golden Gun recoil. (Default: 0.0)");
	cvar_weapon_price	= my_register_cvar("ttt_price_golden",	"2",	"Golden Gun price. (Default: 2)");

	g_pMsgScreenFade	= get_user_msgid("ScreenFade");
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID14");
	g_iItemID = ttt_buymenu_add(name, get_pcvar_num(cvar_weapon_price), PC_DETECTIVE);
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_PREPARING || gamemode == GAME_RESTARTING)
	{
		new num, id;
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];
			g_iAlreadyShot[id] = false;
			if(g_iGlowing[id])
			{
				g_iGlowing[id] = false;
				set_user_rendering(id);
			}
		}
	}
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

		g_iAlreadyShot[id] = false;
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_ITEM5");
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public cswa_damage(weapon_id, victim, attacker, Float:damage)
{
	if(!g_iAlreadyShot[attacker] && get_weapon_edict(weapon_id, REPL_CSWA_ITEMID) == g_iItemID)
	{
		static name[2][32];
		get_user_name(attacker, name[0], charsmax(name[]));

		new player_state = ttt_get_playerstate(victim);
		if(player_state == PC_TRAITOR)
			ExecuteHamB(Ham_Killed, victim, attacker, 2);
		else if(player_state == PC_INNOCENT)
		{
			g_iGlowing[victim] = true;
			screen_fade(victim);
			set_user_rendering(victim, kRenderFxGlowShell, g_iTeamColors[player_state][0], g_iTeamColors[player_state][1], g_iTeamColors[player_state][2], kRenderNormal, 30);
			client_print_color(victim, print_team_default, "%s %L", TTT_TAG, victim, "TTT_ITEM_GOLDEN", victim, special_names[PC_INNOCENT], victim, special_names[ttt_get_playerstate(attacker)], name[0]);
		}

		get_user_name(victim, name[1], charsmax(name[]));
		ttt_log_to_file(LOG_ITEM, "%s used %L on [%L] %s", name[0], LANG_PLAYER, "TTT_ITEM_ID14", LANG_PLAYER, special_names[player_state], name[1]);
		g_iAlreadyShot[attacker] = true;
	}
}

stock screen_fade(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_pMsgScreenFade, _, id);
	write_short(FixedUnsigned16(1.0, 1<<12));
	write_short(0);
	write_short((SF_FADE_MODULATE)); //flags (SF_FADE_IN + SF_FADE_ONLYONE) (SF_FADEOUT)
	write_byte(g_iTeamColors[PC_INNOCENT][0]);
	write_byte(g_iTeamColors[PC_INNOCENT][1]);
	write_byte(g_iTeamColors[PC_INNOCENT][2]);
	write_byte(180);
	message_end();
}
