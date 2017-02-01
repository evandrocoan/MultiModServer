/*================================================================================
	
	-------------------------------------
	-*- [CS] Weapons Restrict API 0.4 -*-
	-------------------------------------
	
	- Allows easily restricting player's weapons in CS and CZ
	- ToDo: PODBots support?? (does engclient_cmd work for them?)
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define MAXPLAYERS 32
#define NO_WEAPON 0

// CS Weapon CBase Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux
const OFFSET_NEXTPRIMARYATTACK = 46
const OFFSET_NEXTSECONDARYATTACK = 47

// CS Player CBase Offsets (win32)
const OFFSET_ACTIVE_ITEM = 373
const OFFSSET_NEXTATTACK = 83

// Weapon entity names
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const GRENADES_WEAPONS_BIT_SUM = (1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)
const OTHER_WEAPONS_BIT_SUM = (1<<CSW_KNIFE)|(1<<CSW_C4)

#define flag_get(%1,%2)		(%1 & (1 << (%2 & 31)))
#define flag_set(%1,%2)		%1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2)	%1 &= ~(1 << (%2 & 31))

new g_HasWeaponRestrictions
new g_AllowedWeaponsBitsum[MAXPLAYERS+1]
new g_DefaultAllowedWeapon[MAXPLAYERS+1]

public plugin_init()
{
	register_plugin("[CS] Weapons Restrict API", "0.4", "WiLS")
	
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
}

public plugin_natives()
{
	register_library("cs_weap_restrict_api")
	register_native("cs_set_player_weap_restrict", "native_set_player_weap_restrict")
	register_native("cs_get_player_weap_restrict", "native_get_player_weap_restrict")
}

public native_set_player_weap_restrict(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id)
		return false;
	}
	
	new set = get_param(2)
	
	if (!set)
	{
		// Player doesn't have weapon restrictions, no need to reset
		if (!flag_get(g_HasWeaponRestrictions, id))
			return true;
		
		flag_unset(g_HasWeaponRestrictions, id)
		
		// Re-deploy current weapon, to unlock weapon's firing if we were blocking it
		new current_weapon_ent = fm_cs_get_current_weapon_ent(id)
		if (pev_valid(current_weapon_ent)) ExecuteHamB(Ham_Item_Deploy, current_weapon_ent)
		return true;
	}
	
	new allowed_bitsum = get_param(3)
	new allowed_default = get_param(4)
	
	if (!(allowed_bitsum & PRIMARY_WEAPONS_BIT_SUM) && !(allowed_bitsum & SECONDARY_WEAPONS_BIT_SUM)
		&& !(allowed_bitsum & GRENADES_WEAPONS_BIT_SUM) && !(allowed_bitsum & OTHER_WEAPONS_BIT_SUM))
	{
		// Bitsum does not contain any weapons, set allowed default weapon to NO_WEAPON
		allowed_default = NO_WEAPON
	}
	else if (!(allowed_bitsum & (1<<allowed_default)))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Default allowed weapon must be in allowed weapons bitsum")
		return false;
	}
	
	flag_set(g_HasWeaponRestrictions, id)
	g_AllowedWeaponsBitsum[id] = allowed_bitsum
	g_DefaultAllowedWeapon[id] = allowed_default
	
	// Update weapon restrictions
	new current_weapon_ent = fm_cs_get_current_weapon_ent(id)
	if (pev_valid(current_weapon_ent)) fw_Item_Deploy_Post(current_weapon_ent)
	return true;
}

public native_get_player_weap_restrict(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id)
		return false;
	}
	
	if (!flag_get(g_HasWeaponRestrictions, id))
		return false;
	
	set_param_byref(2, g_AllowedWeaponsBitsum[id])
	set_param_byref(3, g_DefaultAllowedWeapon[id])
	return true;
}

public client_disconnect(id)
{
	flag_unset(g_HasWeaponRestrictions, id)
}

public fw_Item_Deploy_Post(weapon_ent)
{
	// Get weapon's owner
	new owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	// Owner not valid or does not have any restrictions set
	if (!is_user_alive(owner) || !flag_get(g_HasWeaponRestrictions, owner))
		return;
	
	// Get weapon's id
	new weaponid = cs_get_weapon_id(weapon_ent)
	
	// Owner not holding an allowed weapon
	if (!((1<<weaponid) & g_AllowedWeaponsBitsum[owner]))
	{
		new weapons[32], num
		new current_weapons_bitsum = get_user_weapons(owner, weapons, num)
		
		if (current_weapons_bitsum & (1 << g_DefaultAllowedWeapon[owner]))
		{
			// Switch to default weapon
			engclient_cmd(owner, WEAPONENTNAMES[g_DefaultAllowedWeapon[owner]])
		}
		else
		{
			// Otherwise, block weapon firing and hide current weapon
			block_and_hide_weapon(owner)
		}
	}
}

// Prevent player from firing and hide current weapon model
block_and_hide_weapon(id)
{
	fm_cs_set_user_next_attack(id, 99999.0)
	set_pev(id, pev_viewmodel2, "")
	set_pev(id, pev_weaponmodel2, "")
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

// Get User Current Weapon Entity
stock fm_cs_get_current_weapon_ent(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM);
}

stock fm_cs_set_user_next_attack(id, Float:next_attack)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return false;
	
	set_pdata_float(id, OFFSSET_NEXTATTACK, next_attack)
	return true;
}

// ConnorMcLeod
// 99999.0 = 27hours, should be enough.
// want to block attack1 ?
//set_pdata_float(weapon_ent, OFFSET_NEXTPRIMARYATTACK, 99999.0, OFFSET_LINUX_WEAPONS)
// want to block attack2 ?
//set_pdata_float(weapon_ent, OFFSET_NEXTSECONDARYATTACK, 99999.0, OFFSET_LINUX_WEAPONS)
// also want to block +use ? (may block other things as impulse(impulse are put in a queue))
//set_pdata_float(owner, OFFSSET_NEXTATTACK, 99999.0)
