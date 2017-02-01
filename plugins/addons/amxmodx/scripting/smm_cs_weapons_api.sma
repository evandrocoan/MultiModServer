#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <engine>
#include <xs>
#include <cs_weapons_api>
#include <cs_weapons_api_stocks>

#if AMXX_VERSION_NUM < 183
	stock HamHook:RegisterHamPlayer(Ham:function, const Callback[], Post=0)
		return RegisterHam(function, "player", Callback, Post);
#endif

#define OFFSET_LINUX_WEAPONS 4
#define OFFSET_LINUX_PLAYERS 5

#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack		47
#define m_flTimeWeaponIdle			48
#define m_fInReload					54
#define m_fInSpecialReload			55
#define m_flNextAttack				83

//#define set_weapon_string(%1, %2, %3)		entity_set_string(%1, %2, %3)
//#define set_weapon_float(%1, %2, %3)		entity_set_float(%1, %2, %3)
//#define set_weapon_integer(%1, %2, %3)		entity_set_int(%1, %2, %3)
//#define set_weapon_edict(%1, %2, %3)		entity_set_edict(%1, %2, %3)
//
//#define get_weapon_string(%1, %2, %3, %4)	entity_get_string(%1, %2, %3, %4)
//#define get_weapon_float(%1, %2)			entity_get_float(%1, %2)
//#define get_weapon_integer(%1, %2)			entity_get_int(%1, %2)
//#define get_weapon_edict(%1, %2)			entity_get_edict(%1, %2)

new const m_rgpPlayerItems_CWeaponBox[6] = {34, 35, ...};

new const g_szWeaponsList[][] = 
{
	"", "weapon_p228", "weapon_shield", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10", "weapon_aug",
	"weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas",
	"weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp",
	"weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90"
};

new g_pKilledForward, g_pDamageForward;
new g_iShouldGive[33], g_iWeaponRegister[sizeof(g_szWeaponsList)];

public plugin_precache()
{
	RegisterHamPlayer(Ham_Killed, "Ham_Killed_pre", 0);
	RegisterHamPlayer(Ham_TakeDamage, "Ham_TakeDamage_pre", 0);
	RegisterHamPlayer(Ham_AddPlayerItem, "Ham_AddPlayerItem_pre", 0);

	// CAUSE CRASH IN INIT
	for(new i = 1; i < sizeof(g_szWeaponsList); i++)
	{
		RegisterHam(Ham_Item_Holster, g_szWeaponsList[i], "Ham_Item_Holster_pre", 0);
		RegisterHam(Ham_Item_Deploy, g_szWeaponsList[i], "Ham_Item_Deploy_pre", 0);
	}
}

public plugin_init()
{
	register_plugin("CS Weapons API", "1.0.0", "GuskiS");

	register_event("WeapPickup", "Event_WeapPickup", "be");
	register_forward(FM_SetModel, "Forward_SetModel_pre", 0);
	register_touch("weaponbox", "player", "Touch_WeaponBox");

	g_pKilledForward = CreateMultiForward("cswa_killed", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	g_pDamageForward = CreateMultiForward("cswa_damage", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_FLOAT);
}

public plugin_natives()
{
	register_library("cs_weapons_api");
	register_native("cswa_give_specific", "_give_specific");
	register_native("cswa_give_normal", "_give_normal");
}

public client_disconnect(id)
{
	if(task_exists(id))
		remove_task(id);
}

public Touch_WeaponBox(ent, id)
{
	//log_amx("TOUCH %d - %d", ent, id);
	if(!is_user_alive(id) || !is_valid_ent(ent))
		return PLUGIN_CONTINUE;

	if(get_pdata_cbase(ent, m_rgpPlayerItems_CWeaponBox[5], OFFSET_LINUX_WEAPONS) > 0 && user_has_weapon(id, CSW_C4))
		return PLUGIN_HANDLED;

	if(!(entity_get_int(ent, EV_INT_flags) & FL_ONGROUND))
		return PLUGIN_CONTINUE;

	new weapon_ent = weapon_in_box(ent);
	if(weapon_ent && user_has_weapon(id, cs_get_weapon_id(weapon_ent)))
		return PLUGIN_CONTINUE;

	if(get_weapon_edict(weapon_ent, REPL_CSWA_SET) == 2)
	{
		if(get_weapon_edict(weapon_ent, REPL_CSWA_STACKABLE) && check_player_slot(id, weapon_ent))
		{
			static array[STOREABLE_STRUCTURE];
			get_weapon_array(weapon_ent, array);
			new newent = give_user_specific(id, array[STRUCT_CSWA_CSW], array[STRUCT_CSWA_CLIP], array[STRUCT_CSWA_AMMO], array[STRUCT_CSWA_SILENCED]);
			set_weapon_array(newent, array);
			show_weapon(id, g_szWeaponsList[array[STRUCT_CSWA_CSW]]);

			call_think(ent);
			return PLUGIN_HANDLED;
		}
	}
	else if(get_weapon_edict(weapon_ent, REPL_CSWA_SET) == 1)
	{
		new special, count = count_player_weapons(id, ExecuteHam(Ham_Item_ItemSlot, weapon_ent), special);
		if(!count && special)
		{
			give_user_normal(id, cs_get_weapon_id(weapon_ent), cs_get_weapon_ammo(weapon_ent), get_weapon_integer(weapon_ent, REPL_CSWA_AMMO));
			call_think(ent);
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public Forward_SetModel_pre(ent, model[])
{
	// log_amx("SETMODEL %d - %s", ent, model);
	if(!is_valid_ent(ent))
		return FMRES_IGNORED;

	static classname[32];
	entity_get_string(ent, EV_SZ_classname, classname, charsmax(classname));
	if(!equal(classname, "weaponbox") && !equal(classname, "grenade"))
		return FMRES_IGNORED;

	new weapon_ent = weapon_in_box(ent);
	if(!weapon_ent)
		return FMRES_IGNORED;

	if(get_weapon_edict(weapon_ent, REPL_CSWA_SET) != 2)
		return FMRES_IGNORED;

	static model[64];
	get_weapon_string(weapon_ent, REPL_CSWA_MODEL_W, model, charsmax(model));
	entity_set_model(ent, model);
	return FMRES_SUPERCEDE;
}

public Ham_Killed_pre(victim, killer, shouldgib)
{
	//log_amx("KILLED %d - %d", victim, killer);
	if(is_user_alive(killer))
	{
		new ent = find_ent_by_owner(-1, g_szWeaponsList[get_user_weapon(killer)], killer);
		if(get_weapon_edict(ent, REPL_CSWA_SET) == 2)
		{
			new ret;
			ExecuteForward(g_pKilledForward, ret, ent, victim, killer);
		}

		//engclient_cmd(victim, "drop", WPN_WEAP);
	}

	return HAM_IGNORED;
}

public Ham_TakeDamage_pre(victim, inflictor, attacker, Float:damage, bits)
{
	//log_amx("TAKEDAMAGE %d - %d", victim, attacker);
	if(is_user_alive(inflictor) && attacker == inflictor)
	{
		new ent = find_ent_by_owner(-1, g_szWeaponsList[get_user_weapon(inflictor)], inflictor);
		if(get_weapon_edict(ent, REPL_CSWA_SET) == 2)
		{
			new Float:newdamage = get_weapon_float(ent, REPL_CSWA_DAMAGE);
			if(newdamage > -0.01)
			{
				SetHamParamFloat(4, damage * newdamage);
				new ret;
				ExecuteForward(g_pDamageForward, ret, ent, victim, attacker, damage);
				return HAM_HANDLED;
			}
		}
	}

	return HAM_IGNORED;
}

public Ham_AddPlayerItem_pre(id, ent)
{
	//log_amx("ADDPLAYERITEM %d - %d", id, ent);
	if(!is_user_alive(id) || !is_valid_ent(ent))
		return;

	new weapon_id = cs_get_weapon_id(ent);
	if(no_ammo_weapon(weapon_id))
		return;

	if(get_weapon_edict(ent, REPL_CSWA_SET) == 2)
	{
		cs_set_weapon_ammo(ent, get_weapon_integer(ent, REPL_CSWA_CLIP));
		cs_set_user_bpammo(id, weapon_id, get_weapon_integer(ent, REPL_CSWA_AMMO));
	}
	else
	{
		if(get_weapon_edict(ent, REPL_CSWA_SET) == 0)
		{
			set_weapon_integer(ent, REPL_CSWA_AMMO, cs_get_user_bpammo(id, weapon_id));
			set_weapon_edict(ent, REPL_CSWA_SET, true);
		}
		else g_iShouldGive[id] = weapon_id;
	}
}

public Ham_Item_Holster_pre(ent)
{
	//log_amx("HOLSTER %d", ent);
	if(is_valid_ent(ent) && !is_user_connected(ent))
	{
		new owner = get_weapon_owner(ent);
		if(is_user_alive(owner))
			remove_ammo(owner, ent);
	}
}

public Ham_Item_Deploy_pre(ent)
{
	//log_amx("DEPLOY %d", ent);
	if(is_valid_ent(ent) && !is_user_connected(ent))
	{
		new owner = get_weapon_owner(ent);
		if(is_user_alive(owner))
			give_ammo(owner, ent);
	}
}

public Ham_Item_Deploy_post(ent)
{
	//log_amx("DEPLOY POST %d", ent);
	if(is_valid_ent(ent) && !is_user_connected(ent))
	{
		new owner = get_weapon_owner(ent);
		if(is_user_alive(owner) && get_weapon_edict(ent, REPL_CSWA_SET) == 2)
		{
			static model[64];
			get_weapon_string(ent, REPL_CSWA_MODEL_V, model, charsmax(model));
			entity_set_string(owner, EV_SZ_viewmodel, model);
			get_weapon_string(ent, REPL_CSWA_MODEL_P, model, charsmax(model));
			entity_set_string(owner, EV_SZ_weaponmodel, model);
		}
	}
}

public Ham_PrimaryAttack_post(ent)
{
	if(!is_valid_ent(ent))
		return;

	//log_amx("ATTACK POST %d", ent);
	new weapon_id = cs_get_weapon_id(ent);
	if(no_ammo_weapon(weapon_id))
		return;

	new id = get_weapon_owner(ent);
	if(is_user_alive(id) && get_weapon_edict(ent, REPL_CSWA_SET) == 2 && cs_get_weapon_ammo(ent))
	{
		new Float:recoil = get_weapon_float(ent, REPL_CSWA_RECOIL);
		if(recoil)
		{
			new Float:angle[3];
			entity_get_vector(id, EV_VEC_punchangle, angle);
			xs_vec_mul_scalar(angle, recoil, angle);
			entity_set_vector(id, EV_VEC_punchangle, angle);
		}

		new Float:speed = get_weapon_float(ent, REPL_CSWA_SPEEDDELAY);
		if(speed) //&& delay * speed > 0.0)
		{
			set_pdata_float(id, m_flNextAttack, get_pdata_float(id, m_flNextAttack, OFFSET_LINUX_PLAYERS) * speed, OFFSET_LINUX_PLAYERS);
			set_pdata_float(ent, m_flNextPrimaryAttack, get_pdata_float(ent, m_flNextPrimaryAttack, OFFSET_LINUX_WEAPONS) * speed, OFFSET_LINUX_WEAPONS);
			set_pdata_float(ent, m_flNextSecondaryAttack, get_pdata_float(ent, m_flNextSecondaryAttack, OFFSET_LINUX_WEAPONS) * speed, OFFSET_LINUX_WEAPONS);
			set_pdata_float(ent, m_flTimeWeaponIdle, get_pdata_float(ent, m_flTimeWeaponIdle, OFFSET_LINUX_WEAPONS) * speed, OFFSET_LINUX_WEAPONS);
		}
	}
}

public Ham_Item_PostFrame_pre(ent) 
{
	//log_amx("FRAME %d", ent);
	if(!is_valid_ent(ent) || !is_reloading(ent))
		return HAM_IGNORED;

	if(get_weapon_edict(ent, REPL_CSWA_SET) != 2)
		return HAM_IGNORED;

	new weapon_id = cs_get_weapon_id(ent);
	if(no_ammo_weapon(weapon_id))
		return HAM_IGNORED;

	new id = get_weapon_owner(ent);
	if(!is_user_alive(id))
		return HAM_IGNORED;

	if(!can_reload(id, ent))
	{
		set_pdata_int(ent, m_fInReload, false, OFFSET_LINUX_WEAPONS);
		set_pdata_int(ent, m_fInSpecialReload, false, OFFSET_LINUX_WEAPONS);
		UTIL_PlayWeaponAnimation(id, 0);
		return HAM_SUPERCEDE;
	}

	if(get_pdata_float(id, m_flNextAttack, OFFSET_LINUX_PLAYERS) <= 0.0)
	{
		new csw = cs_get_weapon_id(ent);
		new clip = cs_get_weapon_ammo(ent);
		new ammo = cs_get_user_bpammo(id, csw);
		new difference = min(get_weapon_integer(ent, REPL_CSWA_MAXCLIP) - clip, ammo);
		if(get_pdata_int(ent, m_fInReload, OFFSET_LINUX_WEAPONS))
		{
			cs_set_user_bpammo(id, csw, ammo - difference);
			cs_set_weapon_ammo(ent, clip + difference);
			set_pdata_int(ent, m_fInReload, false, OFFSET_LINUX_WEAPONS);

			return HAM_HANDLED;
		}
		else if(get_pdata_int(ent, m_fInSpecialReload, OFFSET_LINUX_WEAPONS) == 1)
		{
			if(cs_get_weapon_ammo(ent) >= get_weapon_integer(ent, REPL_CSWA_MAXCLIP))
			{
				set_pdata_int(ent, m_fInSpecialReload, false, OFFSET_LINUX_WEAPONS);
				return HAM_HANDLED;
			}
		}
	}

	return HAM_IGNORED;
}

public Ham_Weapon_Reload_pre(ent) 
{
	//log_amx("RELOAD %d", ent);
	if(!is_valid_ent(ent) || !is_reloading(ent))
		return HAM_IGNORED;

	if(get_weapon_edict(ent, REPL_CSWA_SET) != 2)
		return HAM_IGNORED;

	new weapon_id = cs_get_weapon_id(ent);
	if(no_ammo_weapon(weapon_id))
		return HAM_IGNORED;

	new id = get_weapon_owner(ent);
	if(!is_user_alive(id))
		return HAM_IGNORED;

	if(!can_reload(id, ent))
	{
		if(weapon_id == CSW_M3 || weapon_id == CSW_XM1014)
			set_pdata_int(ent, m_fInSpecialReload, false, OFFSET_LINUX_WEAPONS);
		else set_pdata_int(ent, m_fInReload, false, OFFSET_LINUX_WEAPONS);
		UTIL_PlayWeaponAnimation(id, 0);
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public Ham_Weapon_Reload_post(ent) 
{
	//log_amx("RELOAD POST %d", ent);
	if(!is_valid_ent(ent) || !is_reloading(ent))
		return;

	if(get_weapon_edict(ent, REPL_CSWA_SET) != 2)
		return;

	new weapon_id = cs_get_weapon_id(ent);
	if(no_ammo_weapon(weapon_id))
		return;

	new id = get_weapon_owner(ent);
	if(!is_user_alive(id))
		return;

	new Float:reload = get_weapon_float(ent, REPL_CSWA_RELOADTIME);
	if(reload != 0.0)
	{
		if(weapon_id == CSW_M3 || weapon_id == CSW_XM1014)
			set_pdata_int(ent, m_fInSpecialReload, true, OFFSET_LINUX_WEAPONS);
		else
		{ 
			set_pdata_int(ent, m_fInReload, true, OFFSET_LINUX_WEAPONS);
			set_pdata_float(id, m_flNextAttack, reload, OFFSET_LINUX_PLAYERS);
			set_pdata_float(ent, m_flTimeWeaponIdle, reload, OFFSET_LINUX_WEAPONS);
		}
	}
	if(!can_reload(id, ent))
		UTIL_PlayWeaponAnimation(id, 0);

	if(reload < 0.0 && weapon_id == CSW_M3 || weapon_id == CSW_XM1014)
	{
		new csw = cs_get_weapon_id(ent);
		new clip = cs_get_weapon_ammo(ent);
		new ammo = cs_get_user_bpammo(id, csw);
		new difference = min(get_weapon_integer(ent, REPL_CSWA_MAXCLIP) - clip, ammo);
		cs_set_user_bpammo(id, csw, ammo - difference);
		cs_set_weapon_ammo(ent, clip + difference);
		set_pdata_int(ent, m_fInSpecialReload, false, OFFSET_LINUX_WEAPONS);
		reload *= (-1.0);
		set_pdata_float(ent, m_flTimeWeaponIdle, reload, OFFSET_LINUX_WEAPONS);
		set_pdata_float(id, m_flNextAttack, reload, OFFSET_LINUX_PLAYERS);
		set_pdata_float(ent, m_flNextPrimaryAttack, reload, OFFSET_LINUX_WEAPONS);
		set_pdata_float(ent, m_flNextSecondaryAttack, reload, OFFSET_LINUX_WEAPONS);
	}
}

stock can_reload(id, ent)
	return cs_get_user_bpammo(id, cs_get_weapon_id(ent)) > 0 && cs_get_weapon_ammo(ent) < get_weapon_integer(ent, REPL_CSWA_MAXCLIP);

stock is_reloading(ent)
	return get_pdata_int(ent, m_fInReload, OFFSET_LINUX_WEAPONS) || get_pdata_int(ent, m_fInSpecialReload, OFFSET_LINUX_WEAPONS);

public Event_WeapPickup(id)
{
	//log_amx("WEAPPICKUP %d", id);
	if(is_user_alive(id) && g_iShouldGive[id] == read_data(1))
	{
		if(no_ammo_weapon(g_iShouldGive[id]))
			return;

		new ent = find_ent_by_owner(-1, g_szWeaponsList[g_iShouldGive[id]], id);
		cs_set_user_bpammo(id, g_iShouldGive[id], get_weapon_integer(ent, REPL_CSWA_AMMO));
		g_iShouldGive[id] = false;
	}
}

stock remove_ammo(id, ent)
{
	//log_amx("REMOVE_AMMO %d - %d", id, ent);
	new weapon_id = cs_get_weapon_id(ent);
	if(no_ammo_weapon(weapon_id))
		return;

	set_weapon_integer(ent, REPL_CSWA_AMMO, cs_get_user_bpammo(id, weapon_id));
	set_weapon_integer(ent, REPL_CSWA_CLIP, cs_get_weapon_ammo(ent));

	cs_set_user_bpammo(id, weapon_id, 0);
}

stock give_ammo(id, ent)
{
	//log_amx("GIVE_AMMO %d - %d", id, ent);
	new weapon_id = cs_get_weapon_id(ent);
	if(no_ammo_weapon(weapon_id))
		return;

	cs_set_user_bpammo(id, weapon_id, get_weapon_integer(ent, REPL_CSWA_AMMO));
}

stock weapon_in_box(ent)
{
	for(new weapon, i = 1; i < 6; i++)
	{
		weapon = get_pdata_cbase(ent, m_rgpPlayerItems_CWeaponBox[i], OFFSET_LINUX_WEAPONS);
		if(weapon > 0)
			return weapon;
	}
	
	return 0;
}

stock give_user_specific(id, csw, clip, ammo, silenced)
{
	if(is_user_alive(id))
	{
		new weap_ent = ham_give_weapon(id, g_szWeaponsList[csw]);
		if(weap_ent)
		{
			if(silenced > -1) cs_set_weapon_silen(weap_ent, 1, 0);
			if(ammo > -1) cs_set_user_bpammo(id, csw, ammo);
			if(clip > -1) cs_set_weapon_ammo(weap_ent, clip);
			return weap_ent;
		}
	}

	return 0;
}

stock give_user_normal(id, csw, clip, ammo, show = 0)
{
	if(is_user_alive(id))
	{
		new weapon_ent = ham_give_weapon(id, g_szWeaponsList[csw]);
		cs_set_user_bpammo(id, csw, ammo);
		if(clip > -1)
			cs_set_weapon_ammo(weapon_ent, clip);
		set_weapon_integer(weapon_ent, REPL_CSWA_AMMO, ammo);
		set_weapon_edict(weapon_ent, REPL_CSWA_SET, 1);

		if(show)
			show_weapon(id, g_szWeaponsList[csw]);
		return weapon_ent;
	}

	return 0;
}

stock count_player_weapons(id, slot, &special)
{
	new count;
	for(new ent, i = 1; i < sizeof(g_szWeaponsList); i++)
	{
		if(g_iWeaponSlots[i] == slot && user_has_weapon(id, i))
		{
			ent = find_ent_by_owner(-1, g_szWeaponsList[i], id);
			if(ent)
			{
				if(get_weapon_edict(ent, REPL_CSWA_SET) == 1)
					count++;
				else if(get_weapon_edict(ent, REPL_CSWA_SET) == 2)
					special++;
			}
		}
	}

	return count;
}

stock get_weapon_array(ent, data[])
{
	get_weapon_string(ent, REPL_CSWA_MODEL_V, data[STRUCT_CSWA_MODEL_V], charsmax(data[STRUCT_CSWA_MODEL_V]));
	get_weapon_string(ent, REPL_CSWA_MODEL_P, data[STRUCT_CSWA_MODEL_P], charsmax(data[STRUCT_CSWA_MODEL_P]));
	get_weapon_string(ent, REPL_CSWA_MODEL_W, data[STRUCT_CSWA_MODEL_W], charsmax(data[STRUCT_CSWA_MODEL_W]));
	data[STRUCT_CSWA_SPEEDDELAY]	= _:get_weapon_float(ent, REPL_CSWA_SPEEDDELAY);
	data[STRUCT_CSWA_DAMAGE]		= _:get_weapon_float(ent, REPL_CSWA_DAMAGE);
	data[STRUCT_CSWA_RELOADTIME]	= _:get_weapon_float(ent, REPL_CSWA_RELOADTIME);
	data[STRUCT_CSWA_RECOIL]		= _:get_weapon_float(ent, REPL_CSWA_RECOIL);
	data[STRUCT_CSWA_CLIP]			= get_weapon_integer(ent, REPL_CSWA_CLIP);
	data[STRUCT_CSWA_MAXCLIP]		= get_weapon_integer(ent, REPL_CSWA_MAXCLIP);
	data[STRUCT_CSWA_AMMO]			= get_weapon_integer(ent, REPL_CSWA_AMMO);
	data[STRUCT_CSWA_STACKABLE]		= get_weapon_edict(ent, REPL_CSWA_STACKABLE);
	data[STRUCT_CSWA_SILENCED]		= get_weapon_edict(ent, REPL_CSWA_SILENCED);
	data[STRUCT_CSWA_SET]			= get_weapon_edict(ent, REPL_CSWA_SET);
	data[STRUCT_CSWA_ITEMID]		= get_weapon_edict(ent, REPL_CSWA_ITEMID);
	data[STRUCT_CSWA_CSW]			= cs_get_weapon_id(ent);
}

stock set_weapon_array(ent, data[])
{
	set_weapon_string(ent, REPL_CSWA_MODEL_V, data[STRUCT_CSWA_MODEL_V]);
	set_weapon_string(ent, REPL_CSWA_MODEL_P, data[STRUCT_CSWA_MODEL_P]);
	set_weapon_string(ent, REPL_CSWA_MODEL_W, data[STRUCT_CSWA_MODEL_W]);
	set_weapon_float(ent, REPL_CSWA_SPEEDDELAY, data[STRUCT_CSWA_SPEEDDELAY]);
	set_weapon_float(ent, REPL_CSWA_DAMAGE, data[STRUCT_CSWA_DAMAGE]);
	set_weapon_float(ent, REPL_CSWA_RELOADTIME, data[STRUCT_CSWA_RELOADTIME]);
	set_weapon_float(ent, REPL_CSWA_RECOIL, data[STRUCT_CSWA_RECOIL]);
	set_weapon_integer(ent, REPL_CSWA_CLIP, data[STRUCT_CSWA_CLIP]);
	set_weapon_integer(ent, REPL_CSWA_MAXCLIP, data[STRUCT_CSWA_MAXCLIP]);
	set_weapon_integer(ent, REPL_CSWA_AMMO, data[STRUCT_CSWA_AMMO]);
	set_weapon_edict(ent, REPL_CSWA_STACKABLE, data[STRUCT_CSWA_STACKABLE]);
	set_weapon_edict(ent, REPL_CSWA_SILENCED, data[STRUCT_CSWA_SILENCED]);
	set_weapon_edict(ent, REPL_CSWA_SET, data[STRUCT_CSWA_SET]);
	set_weapon_edict(ent, REPL_CSWA_ITEMID, data[STRUCT_CSWA_ITEMID]);
}

// API YAY
public _give_specific(plugin, params)
{
	if(params != 3)
		return -1;

	new id = get_param(1);
	if(!is_user_alive(id))
		return -1;

	new data[STOREABLE_STRUCTURE];
	get_array(2, data, charsmax(data));
	new csw = data[STRUCT_CSWA_CSW];
	if(!g_iWeaponRegister[csw])
	{
		RegisterHam(Ham_Weapon_PrimaryAttack, g_szWeaponsList[csw], "Ham_PrimaryAttack_post", 1);
		RegisterHam(Ham_Weapon_Reload, g_szWeaponsList[csw], "Ham_Weapon_Reload_pre", 0);
		RegisterHam(Ham_Weapon_Reload, g_szWeaponsList[csw], "Ham_Weapon_Reload_post", 1);
		RegisterHam(Ham_Item_PostFrame, g_szWeaponsList[csw], "Ham_Item_PostFrame_pre", 0);
		RegisterHam(Ham_Item_Deploy, g_szWeaponsList[csw], "Ham_Item_Deploy_post", 1);
		g_iWeaponRegister[csw] = true;
	}

	new ent = give_user_specific(id, data[STRUCT_CSWA_CSW], data[STRUCT_CSWA_CLIP], data[STRUCT_CSWA_AMMO], data[STRUCT_CSWA_SILENCED]);
	if(ent)
	{
		data[STRUCT_CSWA_SET] = 2;
		set_weapon_array(ent, data);

		if(get_param(3))
			show_weapon(id, g_szWeaponsList[csw]);
		return ent;
	}

	return 0;
}

public _give_normal(plugin, params)
{
	if(params != 5)
		return -1;

	return give_user_normal(get_param(1), get_param(2), get_param(3), get_param(4), get_param(5));
}