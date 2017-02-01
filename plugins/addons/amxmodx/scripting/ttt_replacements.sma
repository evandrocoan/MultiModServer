#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <ttt>
#include <amx_settings_api>
#include <cs_weapons_api>

#define LINUX_WEAPON_OFF			4
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack		47
#define m_flNextHudTextArgs			198

new g_szCrowbarModel[2][TTT_FILELENGHT];
new g_szGrenadeModel[3][TTT_FILELENGHT];
new const g_szCrowbarSound[][] = {"weapons/cbar_hitbod2.wav", "weapons/cbar_hitbod1.wav", "weapons/bullet_hit2.wav",  "weapons/cbar_miss1.wav"};
new const g_szHeadShotSound[][] = {"player/headshot1.wav", "player/headshot2.wav", "player/headshot3.wav"};
new g_szPlayerModel[32], g_iKnifeID = -1;

public plugin_precache()
{
// PLAYER
	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Player model", "MODEL", g_szPlayerModel, charsmax(g_szPlayerModel)))
	{
		g_szPlayerModel = "terror";
		amx_save_setting_string(TTT_SETTINGSFILE, "Player model", "MODEL", g_szPlayerModel);
	}

	new model[TTT_FILELENGHT];
	formatex(model, charsmax(model), "models/player/%s/%s.mdl", g_szPlayerModel, g_szPlayerModel);
	precache_model(model);
// END

// CROWBAR
	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Crowbar", "MODEL_V", g_szCrowbarModel[0], charsmax(g_szCrowbarModel[])))
	{
		g_szCrowbarModel[0] = "models/ttt/v_crowbar.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Crowbar", "MODEL_V", g_szCrowbarModel[0]);
	}
	precache_model(g_szCrowbarModel[0]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Crowbar", "MODEL_P", g_szCrowbarModel[1], charsmax(g_szCrowbarModel[])))
	{
		g_szCrowbarModel[1] = "models/ttt/p_crowbar.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Crowbar", "MODEL_P", g_szCrowbarModel[1]);
	}
	precache_model(g_szCrowbarModel[1]);
// END

// GRENADE
	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Grenade", "MODEL_V", g_szGrenadeModel[0], charsmax(g_szGrenadeModel[])))
	{
		g_szGrenadeModel[0] = "models/ttt/v_hegrenade.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Grenade", "MODEL_V", g_szGrenadeModel[0]);
	}
	precache_model(g_szGrenadeModel[0]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Grenade", "MODEL_P", g_szGrenadeModel[1], charsmax(g_szGrenadeModel[])))
	{
		g_szGrenadeModel[1] = "models/ttt/p_hegrenade.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Grenade", "MODEL_P", g_szGrenadeModel[1]);
	}
	precache_model(g_szGrenadeModel[1]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Grenade", "MODEL_W", g_szGrenadeModel[2], charsmax(g_szGrenadeModel[])))
	{
		g_szGrenadeModel[2] = "models/ttt/w_hegrenade.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Grenade", "MODEL_W", g_szGrenadeModel[2]);
	}
	precache_model(g_szGrenadeModel[2]);
// END

	new i;
	for(i = 0; i <= charsmax(g_szCrowbarSound); i++)
		precache_sound(g_szCrowbarSound[i]);

	for(i = 0; i <= charsmax(g_szHeadShotSound); i++)
		precache_sound(g_szHeadShotSound[i]);
}

public plugin_init()
{
	register_plugin("[TTT] Replacements", TTT_VERSION, TTT_AUTHOR);

	new const g_szBlockSet[][] =
	{
		"BombDrop",
		"BombPickup",
		"DeathMsg",
		"ScoreInfo",
		"Radar",
		"Money"
	};

	new const g_szMessageBlock[][] =
	{
		"ScoreAttrib",
		"TextMsg",
		"SendAudio",
		"Scenario",
		"StatusIcon"
	};
	new i;
	for(i = 0; i <= charsmax(g_szBlockSet); i++)
		set_msg_block(get_user_msgid(g_szBlockSet[i]), BLOCK_SET);

	for(i = 0; i <= charsmax(g_szMessageBlock); i++)
		register_message(get_user_msgid(g_szMessageBlock[i]), "Block_Messages");

	register_message(get_user_msgid("HudTextArgs"), "Block_HudTextArgs");

	register_forward(FM_EmitSound, "Forward_EmitSound_pre", 0);
	register_forward(FM_GetGameDescription, "Forward_GetGameDescription_pre", 0);

	RegisterHamPlayer(Ham_Spawn, "Ham_Spawn_post", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "Ham_Knife_Deploy_post", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "Ham_He_Deploy_post", 1);

	register_clcmd("drop", "clcmd_drop");
}

public clcmd_drop(id)
{
	if(get_user_weapon(id) == CSW_C4)
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

public cswa_killed(ent, victim, killer)
{
	ttt_set_playerdata(victim, PD_KILLEDBYITEM, get_weapon_edict(ent, REPL_CSWA_ITEMID));
}

public grenade_throw(id, ent, nade)
{
	if(nade == CSW_HEGRENADE && is_user_alive(id))
	{
		if(entity_get_float(ent, EV_FL_dmgtime) != 0.0)
			entity_set_model(ent, g_szGrenadeModel[2]);
	}
}

public Block_Messages(msgid, dest, id)
{
	if(get_msg_args() > 1)
	{
		static message[128];
		if(get_msg_args() == 5)
			get_msg_arg_string(5, message, charsmax(message));

		if(equal(message, "#Fire_in_the_hole"))
			return PLUGIN_HANDLED;

		get_msg_arg_string(2, message, charsmax(message));
		if(equal(message, "%!MRAD_BOMBPL") || equal(message, "%!MRAD_BOMBDEF") || equal(message, "%!MRAD_terwin") || equal(message, "%!MRAD_ctwin") || equal(message, "%!MRAD_FIREINHOLE"))
			return PLUGIN_HANDLED;

		if(equal(message, "#Killed_Teammate") || equal(message, "#Game_teammate_kills") || equal(message, "#Game_teammate_attack") || equal(message, "#C4_Plant_At_Bomb_Spot"))
			return PLUGIN_HANDLED;

		if(equal(message, "#Bomb_Planted") || equal(message, "#Game_bomb_drop") || equal(message, "#Game_bomb_pickup") || equal(message, "#Got_bomb") || equal(message, "#C4_Plant_Must_Be_On_Ground"))
			return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public Block_HudTextArgs(msgid, dest, id)
{
	set_pdata_float(id, m_flNextHudTextArgs, 0.0);	
	return PLUGIN_HANDLED;
}

public Forward_GetGameDescription_pre()
{
	forward_return(FMV_STRING, "Trouble in Terrorist Town");
	return FMRES_SUPERCEDE;
}

public Forward_EmitSound_pre(id, channel, sample[])
{
	if(!is_user_connected(id))
		return FMRES_IGNORED;

	if(equal(sample, "player/bhit_helmet-1.wav"))
	{
		emit_sound(id, CHAN_BODY, g_szHeadShotSound[random_num(0, 2)], 1.0, ATTN_NORM, 0, PITCH_NORM);
		return FMRES_SUPERCEDE;
	}

	if((equal(sample, "player/die", 10) || equal(sample, "player/death6.wav")) && !is_user_alive(id) && ttt_get_playerdata(id, PD_KILLEDBYITEM) > -1)
		return FMRES_SUPERCEDE;

	if(g_iKnifeID == -1)
	{
		new name[TTT_ITEMLENGHT];
		formatex(name, charsmax(name), "%L", LANG_SERVER, "TTT_ITEM_ID11");
		g_iKnifeID = ttt_get_item_id(name);
	}

	if(equal(sample, "weapons/knife_", 14) && ttt_get_playerdata(id, PD_HOLDINGITEM) != g_iKnifeID)
	{
		switch(sample[17])
		{
			case('b'): emit_sound(id, CHAN_WEAPON, g_szCrowbarSound[0], 1.0, ATTN_NORM, 0, PITCH_NORM);
			case('w'): emit_sound(id, CHAN_WEAPON, g_szCrowbarSound[1], 1.0, ATTN_NORM, 0, PITCH_LOW);
			case('s'): emit_sound(id, CHAN_WEAPON, g_szCrowbarSound[3], 1.0, ATTN_NORM, 0, PITCH_NORM);
			case('1', '2'): emit_sound(id, CHAN_WEAPON, g_szCrowbarSound[2], random_float(0.5, 1.0), ATTN_NORM, 0, PITCH_NORM);
		}
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public Ham_Spawn_post(id)
{
	if(is_user_alive(id))
	{
		// CAUSES NAME CHANGE MESSAGE TO DISAPPEAR, WTF?
		static model[20];
		cs_get_user_model(id, model, charsmax(model));

		if(!equal(model, g_szPlayerModel))
			cs_set_user_model(id, g_szPlayerModel);
	}
}

public Ham_Knife_Deploy_post(ent)
{
	new id = get_weapon_owner(ent);
	if(is_user_alive(id))
	{
		entity_set_string(id, EV_SZ_viewmodel, g_szCrowbarModel[0]);
		entity_set_string(id, EV_SZ_weaponmodel, g_szCrowbarModel[1]);
	}
}

public Ham_He_Deploy_post(ent)
{
	new id = get_weapon_owner(ent);
	if(is_user_alive(id))
	{
		entity_set_string(id, EV_SZ_viewmodel, g_szGrenadeModel[0]);
		entity_set_string(id, EV_SZ_weaponmodel, g_szGrenadeModel[1]);
	}
}