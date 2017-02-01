#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <amx_settings_api>
#include <ttt>

#define XO_WEAPON					4
#define m_pPlayer					41
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack		47
#define m_flTimeWeaponIdle			48

enum _:TYPE
{
	K_NONE,
	K_TEMP,
	K_ON
}

new g_szModels[3][TTT_FILELENGHT];
new const Float:g_szDroppedSize[][3] =
{
	{-20.0, -20.0, -5.0},
	{20.0, 20.0, 5.0}
};

new g_iKnifeType[33], g_iItem_Knife, g_iNadeVelocity[33][2];
new cvar_dmgmult, cvar_pattack_rate, cvar_sattack_rate, cvar_pattack_recoil,
	cvar_sattack_recoil, cvar_price_knife, cvar_knife_glow, cvar_knife_velocity, cvar_knife_bounce;

public plugin_precache()
{
	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Knife", "MODEL_V", g_szModels[0], charsmax(g_szModels[])))
	{
		g_szModels[0] = "models/v_knife.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Knife", "MODEL_V", g_szModels[0]);
	}
	precache_model(g_szModels[0]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Knife", "MODEL_P", g_szModels[1], charsmax(g_szModels[])))
	{
		g_szModels[1] = "models/p_knife.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Knife", "MODEL_P", g_szModels[1]);
	}
	precache_model(g_szModels[1]);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Knife", "MODEL_W", g_szModels[2], charsmax(g_szModels[])))
	{
		g_szModels[2] = "models/ttt/w_throwingknife.mdl";
		amx_save_setting_string(TTT_SETTINGSFILE, "Knife", "MODEL_W", g_szModels[2]);
	}
	precache_model(g_szModels[2]);
}

public plugin_init()
{
	register_plugin("[TTT] Item: Knife", TTT_VERSION, TTT_AUTHOR);

	cvar_dmgmult		= my_register_cvar("ttt_knife_multi",				"11.0",	"Knife damage multiplier. (Default: 11.0)");
	cvar_pattack_rate	= my_register_cvar("ttt_knife_primary_rate",		"0.6",	"Knife primary attack speed multiplier. (Default: 0.6)");
	cvar_sattack_rate	= my_register_cvar("ttt_knife_secondary_rate", 		"1.3",	"Knife secondary attack speed multiplier. (Default: 1.3)");
	cvar_pattack_recoil	= my_register_cvar("ttt_knife_primary_recoil", 		"-3.6",	"Knife primary recoil multiplier. (Default: -3.6)");
	cvar_sattack_recoil	= my_register_cvar("ttt_knife_secondary_recoil",	"-5.0", "Knife secondary recoil multiplier. (Default: -5.0)");
	cvar_knife_glow		= my_register_cvar("ttt_knife_glow",				"1",	"Knife glow when thrown. (Default: 1)");
	cvar_knife_velocity	= my_register_cvar("ttt_knife_velocity",			"1500",	"Knife throwing speed. (Default: 1500)");
	cvar_knife_bounce	= my_register_cvar("ttt_knife_bounce",				"0",	"Knife should bounce from walls? (Default: 0)");
	cvar_price_knife	= my_register_cvar("ttt_price_knife",				"3",	"Knife price. (Default: 3)");

	register_think("grenade", "Think_Grenade");
	register_touch("grenade", "*", "Touch_Grenade");

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_smokegrenade", "Ham_PrimaryAttack_Grenade_pre", 0);
	RegisterHam(Ham_Killed, "player", "Ham_Killed_pre", 0);
	RegisterHamPlayer(Ham_TakeDamage, "Ham_TakeDamage_pre", 0);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "Ham_PrimaryAttack_post", 1);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "Ham_SecondaryAttack_post", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "Ham_Item_Deploy_post", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_smokegrenade", "Ham_Item_Deploy_Grenade_post", 1);

	register_clcmd("drop", "clcmd_drop");
	register_clcmd("weapon_knife", "clcmd_knife");
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID11");
	g_iItem_Knife = ttt_buymenu_add(name, get_pcvar_num(cvar_price_knife), PC_TRAITOR);
}

public client_disconnect(id)
{
	change_knife_holding(id, K_NONE);
	g_iNadeVelocity[id][0] = false;
	g_iNadeVelocity[id][1] = false;
}

public change_knife_holding(id, type)
{
	ttt_set_playerdata(id, PD_HOLDINGITEM, type == K_ON ? g_iItem_Knife : -1);
	ttt_set_playerdata(id, PD_ITEMSTATE, type);
	g_iKnifeType[id] = type;
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_ENDED || gamemode == GAME_RESTARTING)
	{
		move_grenade();
		new num, id;
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];
			g_iNadeVelocity[id][0] = false;
			g_iNadeVelocity[id][1] = false;

			if(is_user_alive(id) && g_iKnifeType[id] == K_ON)
				reset_user_knife(id);
			change_knife_holding(id, K_NONE);
		}
	}
}

public ttt_item_selected(id, item, name[], price)
{
	if(g_iItem_Knife == item)
	{
		if(get_user_weapon(id) == CSW_KNIFE)
			strip_knife(id, K_ON);
		else change_knife_holding(id, K_TEMP);

		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_ITEM5");
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public clcmd_drop(id)
{
	if(check_player_knife(id))
	{
		clcmd_throw(id, 64, 1);
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public clcmd_throw(id, vel, value)
{
	new ent;
	if(!user_has_weapon(id, CSW_SMOKEGRENADE))
		ent = ham_give_weapon(id, "weapon_smokegrenade", 1);
	else ent = find_ent_by_owner(-1, "weapon_smokegrenade", id);

	g_iNadeVelocity[id][0] = vel;
	g_iNadeVelocity[id][1] = value;
	ExecuteHamB(Ham_Weapon_PrimaryAttack, ent);
	set_pdata_float(ent, m_flTimeWeaponIdle, 0.0, XO_WEAPON);
	ExecuteHam(Ham_Weapon_WeaponIdle, ent);

	static name[32];
	get_user_name(id, name, charsmax(name));
	ttt_log_to_file(LOG_ITEM, "%s a throwed %L", name, LANG_PLAYER, "TTT_ITEM_ID11");
}

public clcmd_knife(id)
{
	if(get_user_weapon(id) == CSW_KNIFE)
	{
		if(g_iKnifeType[id] == K_ON)
			strip_knife(id, K_TEMP);
		else if(g_iKnifeType[id] == K_TEMP)
			strip_knife(id, K_ON);
	}
}

public grenade_throw(id, ent, nade)
{
	if(nade == CSW_SMOKEGRENADE && is_user_alive(id) && g_iKnifeType[id] == K_ON)
	{
		static Float:velocity[3];
		VelocityByAim(id, g_iNadeVelocity[id][0], velocity);
		if(g_iNadeVelocity[id][1])
		{
			static Float:origin[3];
			entity_get_vector(id, EV_VEC_origin, origin);
			origin[0] += velocity[0];
			origin[1] += velocity[1];
			entity_set_origin(ent, origin);
		}

		entity_set_vector(ent, EV_VEC_velocity, velocity);
		entity_set_int(ent, EV_INT_iuser4, id);
		entity_set_float(ent, EV_FL_nextthink, get_gametime()+0.01);
		if(get_pcvar_num(cvar_knife_glow))
			UTIL_SetRendering(ent, kRenderFxGlowShell, Float:{255.0, 0.0, 0.0}, _, 50.0);

		entity_set_model(ent, g_szModels[2]);
		strip_knife(id, K_NONE);
		ham_strip_weapon(id, "weapon_smokegrenade");
	}
}

public Think_Grenade(ent)
{
	if(!is_valid_ent(ent) || GetGrenadeType(ent) != CSW_SMOKEGRENADE || !entity_get_int(ent, EV_INT_iuser4) || ttt_get_gamemode() != GAME_STARTED)
		return;

	static Float:origin[3], Float:velocity[3], Float:angles[3];
	entity_get_vector(ent, EV_VEC_origin, origin);

	if(entity_get_int(ent, EV_INT_flags) & FL_ONGROUND)
	{
		entity_set_vector(ent, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
		entity_set_size(ent, g_szDroppedSize[0], g_szDroppedSize[1]);
		entity_get_vector(ent, EV_VEC_angles, angles);

		angles[0] = 270.0;
		entity_set_vector(ent, EV_VEC_angles, angles);
		if(engfunc(EngFunc_PointContents, origin) == CONTENTS_SKY)
			give_knife(entity_get_int(ent, EV_INT_iuser4), ent);
	}
	else
	{
		entity_get_vector(ent, EV_VEC_velocity, velocity);
		vector_to_angle(velocity, angles);
		angles[0] += 270.0;
		entity_set_vector(ent, EV_VEC_angles, angles);
		origin[2]-=15.0;
	}

	if(is_valid_ent(ent))
		entity_set_float(ent, EV_FL_dmgtime, get_gametime() + 999999.0);
}

public Touch_Grenade(nade, id)
{
	if(!is_valid_ent(nade) || GetGrenadeType(nade) != CSW_SMOKEGRENADE
		|| !entity_get_int(nade, EV_INT_iuser4)|| ttt_get_gamemode() != GAME_STARTED)
		return PLUGIN_CONTINUE;

	if(is_user_alive(id))
	{
		new owner = entity_get_edict(nade, EV_ENT_owner);
		if(!owner)
		{
			give_knife(id, nade);
			return PLUGIN_HANDLED;
		}
		else
		{
			if(owner == id)
				return PLUGIN_CONTINUE;

			emit_sound(id, CHAN_AUTO, "weapons/knife_hit4.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
			ExecuteHam(Ham_TakeDamage, id, owner, owner, 150.0, DMG_SLASH);
			entity_set_vector(nade, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
			entity_set_edict(nade, EV_ENT_owner, 0);
			drop_to_floor(nade);

			return PLUGIN_HANDLED;
		}
	}
	else
	{
		entity_set_edict(nade, EV_ENT_owner, 0);
		if(get_pcvar_num(cvar_knife_bounce))
		{
			static Float:velocity[3];
			entity_get_vector(nade, EV_VEC_velocity, velocity);
			if(velocity[2] > 0.0)
			{
				velocity[2] = -(velocity[2]/2.0);
				entity_set_vector(nade, EV_VEC_velocity, velocity);
			}

			return PLUGIN_HANDLED;
		}
		else
		{
			entity_set_vector(nade, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
			emit_sound(nade, CHAN_AUTO, "weapons/knife_hit4.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
			return PLUGIN_HANDLED;
		}
	}
}

public Ham_Killed_pre(victim, killer, shouldgib)
{
	if(is_user_connected(killer) && check_player_knife(killer))
		ttt_set_playerdata(victim, PD_KILLEDBYITEM, g_iItem_Knife);

	change_knife_holding(victim, K_NONE);
}

public Ham_PrimaryAttack_post(ent)
{
	new id;
	if(!is_valid_ent(ent) || !(id = check_player_knife(ent)))
		return;

	attack_post(id, ent, get_pcvar_float(cvar_pattack_rate), get_pcvar_float(cvar_pattack_recoil));
	clcmd_throw(id, get_pcvar_num(cvar_knife_velocity), 0);
}

public Ham_SecondaryAttack_post(ent)
{
	new id;
	if(!is_valid_ent(ent) || !(id = check_player_knife(ent)))
		return;

	attack_post(id, ent, get_pcvar_float(cvar_sattack_rate), get_pcvar_float(cvar_sattack_recoil));
}

public Ham_Item_Deploy_post(ent)
{
	if(!is_valid_ent(ent))
		return;

	new id = get_pdata_cbase(ent, m_pPlayer, XO_WEAPON);
	if(is_user_alive(id) && g_iKnifeType[id] == K_ON)
	{
		entity_set_string(id, EV_SZ_viewmodel, g_szModels[0]);
		entity_set_string(id, EV_SZ_weaponmodel, g_szModels[1]);
		attack_post(id, ent, 0.5, 0.0);
	}
}

public Ham_Item_Deploy_Grenade_post(ent)
{
	if(!is_valid_ent(ent))
		return;

	new id = get_pdata_cbase(ent, m_pPlayer, XO_WEAPON);
	if(is_user_alive(id) && g_iKnifeType[id] == K_ON)
	{
		entity_set_string(id, EV_SZ_viewmodel, g_szModels[0]);
		entity_set_string(id, EV_SZ_weaponmodel, g_szModels[1]);
		attack_post(id, ent, 0.5, 0.0);
	}
}

public Ham_PrimaryAttack_Grenade_pre(ent)
{
	if(!is_valid_ent(ent))
		return;

	new id = get_pdata_cbase(ent, m_pPlayer, XO_WEAPON);
	if(is_user_alive(id) && g_iKnifeType[id] == K_ON)
	{
		set_pdata_float(ent, m_flTimeWeaponIdle, 0.0, XO_WEAPON);
		ExecuteHam(Ham_Weapon_WeaponIdle, ent);
	}
}

public Ham_TakeDamage_pre(victim, inflictor, attacker, Float:damage, damage_bits)
{	
	if(victim == attacker || !is_user_connected(attacker) || !is_user_alive(inflictor))
		return HAM_IGNORED;

	if(g_iKnifeType[attacker] == K_ON && inflictor == attacker && get_user_weapon(attacker) == CSW_KNIFE)
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult));

	return HAM_HANDLED;
}

public give_knife(id, knife)
{
	strip_knife(id, K_ON);
	emit_sound(id, CHAN_WEAPON, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	if(is_valid_ent(knife))
		entity_set_origin(knife, Float:{-8191.0, -8191.0, -8191.0});
		// remove_entity(knife);
}

public attack_post(id, knife, Float:flRate, Float:cvar)
{
	set_pdata_float(knife, m_flNextPrimaryAttack, flRate, XO_WEAPON);
	set_pdata_float(knife, m_flNextSecondaryAttack, flRate, XO_WEAPON);
	set_pdata_float(knife, m_flTimeWeaponIdle, flRate, XO_WEAPON);

	if(cvar > 0.0)
	{
		static Float:flPunchAngle[3];
		flPunchAngle[0] = cvar;

		entity_set_vector(id, EV_VEC_punchangle, flPunchAngle);
	}
}

public strip_knife(id, type)
{
	change_knife_holding(id, type);
	reset_user_knife(id);
}

public reset_user_knife(id)
{
	if(user_has_weapon(id, CSW_KNIFE))
		ExecuteHamB(Ham_Item_Deploy, find_ent_by_owner(-1, "weapon_knife", id));

	engclient_cmd(id, "weapon_knife");
	UTIL_PlayWeaponAnimation(id, 3);

	emessage_begin(MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), _, id);
	ewrite_byte(1);
	ewrite_byte(CSW_KNIFE);
	ewrite_byte(-1);
	emessage_end();
}

stock UTIL_PlayWeaponAnimation(const id, const seq)
{
	entity_set_int(id, EV_INT_weaponanim, seq);

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id);
	write_byte(seq);
	write_byte(entity_get_int(id, EV_INT_body));
	message_end();
}

stock UTIL_SetRendering(ent, kRenderFx=kRenderFxNone, {Float,_}:fVecColor[3] = {0.0,0.0,0.0}, kRender=kRenderNormal, Float:flAmount=0.0)
{
	if(is_valid_ent(ent))
	{
		entity_set_int(ent, EV_INT_renderfx, kRenderFx);
		entity_set_vector(ent, EV_VEC_rendercolor, fVecColor);
		entity_set_int(ent, EV_INT_rendermode, kRender);
		entity_set_float(ent, EV_FL_renderamt, flAmount);
	}
}

stock GetGrenadeType(ent)
{
	if (get_pdata_int(ent, 96) & (1<<8))
		return CSW_C4;

	new bits = get_pdata_int(ent, 114);
	if (bits & (1<<0))
		return CSW_HEGRENADE;
	else if (bits & (1<<1))
		return CSW_SMOKEGRENADE;
	else if (!bits)
		return CSW_FLASHBANG;

	return 0;
}

stock check_player_knife(id)
{
	if(!is_user_connected(id))
		id = get_pdata_cbase(id, m_pPlayer, XO_WEAPON);

	if(is_user_alive(id) && g_iKnifeType[id] == K_ON && get_user_weapon(id) == CSW_KNIFE)
		return id;

	return 0;
}
