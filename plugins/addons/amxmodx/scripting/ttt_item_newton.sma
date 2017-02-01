#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <cs_weapons_api>
#include <amx_settings_api>
#include <ttt>

#define WEAPON_CSWID CSW_FIVESEVEN
#define WEAPON_NAME "weapon_fiveseven"
#define m_bitsDamageType 76

new g_iItemID, g_iWasPushed[33];
new g_szModels[3][TTT_FILELENGHT];
new cvar_weapon_damage, cvar_weapon_speed, cvar_weapon_ammo, cvar_weapon_clip, cvar_weapon_price, cvar_weapon_reload, cvar_weapon_recoil, cvar_weapon_force;

public plugin_precache()
{
	precache_sound("weapons/sfpistol_clipin.wav");
	precache_sound("weapons/sfpistol_clipout.wav");
	precache_sound("weapons/sfpistol_draw.wav");
	precache_sound("weapons/sfpistol_idle.wav");
	precache_sound("weapons/sfpistol_shoot_end.wav");
	precache_sound("weapons/sfpistol_shoot_start.wav");
	precache_sound("weapons/sfpistol_shoot1.wav");

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Newton Launcher", "MODEL_V", g_szModels[0], charsmax(g_szModels[])))
	{
		g_szModels[0] = "models/ttt/v_newton.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Newton Launcher", "MODEL_V", g_szModels[0]);
	}
	precache_model(g_szModels[0]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Newton Launcher", "MODEL_P", g_szModels[1], charsmax(g_szModels[])))
	{
		g_szModels[1] = "models/ttt/p_newton.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Newton Launcher", "MODEL_P", g_szModels[1]);
	}
	precache_model(g_szModels[1]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Newton Launcher", "MODEL_W", g_szModels[2], charsmax(g_szModels[])))
	{
		g_szModels[2] = "models/ttt/w_newton.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Newton Launcher", "MODEL_W", g_szModels[2]);
	}
	precache_model(g_szModels[2]);
}

public plugin_init()
{
	register_plugin("[TTT] Item: Newton Launcher", TTT_VERSION, TTT_AUTHOR);

	cvar_weapon_clip	= my_register_cvar("ttt_newton_clip",	"1",	"Newton Launcher clip ammo. (Default: 1)");
	cvar_weapon_ammo	= my_register_cvar("ttt_newton_ammo",	"10",	"Newton Launcher backpack ammo. (Default: 10)");
	cvar_weapon_speed	= my_register_cvar("ttt_newton_speed",	"2.0",	"Newton Launcher attack speed delay. (Default: 2.0)");
	cvar_weapon_damage	= my_register_cvar("ttt_newton_damage",	"0.0",	"Newton Launcher damage multiplier. (Default: 0.0)");
	cvar_weapon_reload	= my_register_cvar("ttt_newton_reload",	"2.0",	"Newton Launcher reload speed. (Default: 2.0)");
	cvar_weapon_recoil	= my_register_cvar("ttt_newton_recoil",	"0.0",	"Newton Launcher recoil. (Default: 0.0)");
	cvar_weapon_force	= my_register_cvar("ttt_newton_force",	"100.0","Newton Launcher force. (Default: 100.0)");
	cvar_weapon_price	= my_register_cvar("ttt_price_newton",	"1",	"Newton Launcher price. (Default: 1)");

	RegisterHamPlayer(Ham_Killed, "Ham_Killed_pre", 0);
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID16");
	g_iItemID = ttt_buymenu_add(name, get_pcvar_num(cvar_weapon_price), PC_TRAITOR);
	ttt_add_exception(g_iItemID);
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

public Ham_Killed_pre(victim, killer, shouldgib)
{
	if(!is_user_connected(killer) && g_iWasPushed[victim])
	{
		ttt_set_playerdata(victim, PD_KILLEDBYITEM, g_iItemID);	
		SetHamParamEntity(2, g_iWasPushed[victim]);
	}

	g_iWasPushed[victim] = false;
}

public cswa_damage(weapon_id, victim, attacker, Float:damage)
{
	if(get_weapon_edict(weapon_id, REPL_CSWA_ITEMID) == g_iItemID)
	{
		new Float:push[3], Float:velocity[3];
		entity_get_vector(victim, EV_VEC_velocity, velocity);
		create_velocity_vector(victim, attacker, push);
		push[0] += velocity[0];
		push[1] += velocity[1];
		entity_set_vector(victim, EV_VEC_velocity, push);
		g_iWasPushed[victim] = attacker;
	}
}

stock create_velocity_vector(victim, attacker, Float:velocity[3])
{
	if(!is_user_alive(victim) || !is_user_alive(attacker))
		return 0;

	new Float:vicorigin[3];
	new Float:attorigin[3];
	entity_get_vector(victim   , EV_VEC_origin , vicorigin);
	entity_get_vector(attacker , EV_VEC_origin , attorigin);

	new Float:origin2[3];
	origin2[0] = vicorigin[0] - attorigin[0];
	origin2[1] = vicorigin[1] - attorigin[1];

	new Float:largestnum = 0.0;

	if(floatabs(origin2[0]) > largestnum)
		largestnum = floatabs(origin2[0]);
	if(floatabs(origin2[1]) > largestnum)
		largestnum = floatabs(origin2[1]);

	origin2[0] /= largestnum;
	origin2[1] /= largestnum;

	velocity[0] = ( origin2[0] * (get_pcvar_float(cvar_weapon_force) * 3000) ) / entity_range(victim, attacker);
	velocity[1] = ( origin2[1] * (get_pcvar_float(cvar_weapon_force) * 3000) ) / entity_range(victim, attacker);
	if(velocity[0] <= 20.0 || velocity[1] <= 20.0)
		velocity[2] = random_float(400.0, 575.0);

	return 1;
}