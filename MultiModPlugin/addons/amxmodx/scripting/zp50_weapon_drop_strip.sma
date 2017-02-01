/*================================================================================
	
	------------------------------
	-*- [ZP] Weapon Drop/Strip -*-
	------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core>

// CS Player CBase Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_ACTIVE_ITEM = 373

// HACK: pev_ field used to store additional ammo on weapons
const PEV_ADDITIONAL_AMMO = pev_iuser1

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const GRENADES_WEAPONS_BIT_SUM = (1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)

// Ammo IDs for weapons
new const AMMOID[] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10,
			1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }

// Ammo Type Names for weapons
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
			"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }

#define PRIMARY_ONLY 1
#define SECONDARY_ONLY 2
#define PRIMARY_AND_SECONDARY 3
#define GRENADES_ONLY 4

new cvar_zombie_drop_weapons, cvar_zombie_strip_weapons, cvar_zombie_strip_grenades, cvar_zombie_strip_armor
new cvar_zombie_block_pickup
new cvar_remove_dropped_weapons

public plugin_init()
{
	register_plugin("[ZP] Weapon Drop/Strip", ZP_VERSION_STRING, "ZP Dev Team")
	
	cvar_zombie_drop_weapons = register_cvar("zp_zombie_drop_weapons", "3") // 1-primary only // 2-secondary only // 3-both
	cvar_zombie_strip_weapons = register_cvar("zp_zombie_strip_weapons", "0") // 1-primary only // 2-secondary only // 3-both
	cvar_zombie_strip_grenades = register_cvar("zp_zombie_strip_grenades", "1")
	cvar_zombie_strip_armor = register_cvar("zp_zombie_strip_armor", "1")
	cvar_zombie_block_pickup = register_cvar("zp_zombie_block_pickup", "1")
	cvar_remove_dropped_weapons = register_cvar("zp_remove_dropped_weapons", "0")
	
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_AddPlayerItem, "player", "fw_AddPlayerItem")
	RegisterHamBots(Ham_AddPlayerItem, "fw_AddPlayerItem")
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
}

public zp_fw_core_infect(id, attacker)
{
	// Drop weapons?
	switch (get_pcvar_num(cvar_zombie_drop_weapons))
	{
		case PRIMARY_ONLY: drop_weapons(id, PRIMARY_ONLY)
		case SECONDARY_ONLY: drop_weapons(id, SECONDARY_ONLY)
		case PRIMARY_AND_SECONDARY:
		{
			drop_weapons(id, PRIMARY_ONLY)
			drop_weapons(id, SECONDARY_ONLY)
		}
	}
	
	// Strip weapons?
	switch (get_pcvar_num(cvar_zombie_strip_weapons))
	{
		case PRIMARY_ONLY: strip_weapons(id, PRIMARY_ONLY)
		case SECONDARY_ONLY: strip_weapons(id, SECONDARY_ONLY)
		case PRIMARY_AND_SECONDARY:
		{
			strip_weapons(id, PRIMARY_ONLY)
			strip_weapons(id, SECONDARY_ONLY)
		}
	}
	
	// Strip grenades?
	if (get_pcvar_num(cvar_zombie_strip_grenades))
		strip_weapons(id, GRENADES_ONLY)
	
	// Strip armor?
	if (get_pcvar_num(cvar_zombie_strip_armor))
		cs_set_user_armor(id, 0, CS_ARMOR_NONE)
}

// Forward Set Model
public fw_SetModel(entity, const model[])
{
	// We don't care
	if (strlen(model) < 8)
		return;
	
	// Remove weapons?
	if (get_pcvar_float(cvar_remove_dropped_weapons) > 0.0)
	{
		// Get entity's classname
		new classname[10]
		pev(entity, pev_classname, classname, charsmax(classname))
		
		// Check if it's a weapon box
		if (equal(classname, "weaponbox"))
		{
			// They get automatically removed when thinking
			set_pev(entity, pev_nextthink, get_gametime() + get_pcvar_float(cvar_remove_dropped_weapons))
			return;
		}
	}
}

// Ham Weapon Touch Forward
public fw_TouchWeapon(weapon, id)
{
	// Block weapon pickup for zombies?
	if (get_pcvar_num(cvar_zombie_block_pickup) && is_user_alive(id) && zp_core_is_zombie(id))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Weapon Pickup Forward
public fw_AddPlayerItem(id, weapon_ent)
{
	// HACK: Retrieve our custom extra ammo from the weapon
	new extra_ammo = pev(weapon_ent, PEV_ADDITIONAL_AMMO)
	
	// If present
	if (extra_ammo)
	{
		// Get weapon's id
		new weaponid = cs_get_weapon_id(weapon_ent)
		
		// Add to player's bpammo
		ExecuteHamB(Ham_GiveAmmo, id, extra_ammo, AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
		set_pev(weapon_ent, PEV_ADDITIONAL_AMMO, 0)
	}
}

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	new weapons[32], num_weapons, index, index2, weaponid, weaponid2, dropammo = true
	get_user_weapons(id, weapons, num_weapons)
	
	// Loop through them and drop primaries or secondaries
	for (index = 0; index < num_weapons; index++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[index]
		
		if ((dropwhat == PRIMARY_ONLY && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		|| (dropwhat == SECONDARY_ONLY && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon entity
			new wname[32], weapon_ent
			get_weaponname(weaponid, wname, charsmax(wname))
			weapon_ent = fm_find_ent_by_owner(-1, wname, id)
			
			// Check if another weapon uses same type of ammo first
			for (index2 = 0; index2 < num_weapons; index2++)
			{
				// Prevent re-indexing the array
				weaponid2 = weapons[index2]
				
				// Only check weapons that we are not going to drop
				if ((dropwhat == PRIMARY_ONLY && ((1<<weaponid2) & SECONDARY_WEAPONS_BIT_SUM))
				|| (dropwhat == SECONDARY_ONLY && ((1<<weaponid2) & PRIMARY_WEAPONS_BIT_SUM)))
				{
					if (AMMOID[weaponid2] == AMMOID[weaponid])
						dropammo = false
				}
			}
			
			// Drop weapon's BP Ammo too?
			if (dropammo)
			{
				// Hack: store weapon bpammo on PEV_ADDITIONAL_AMMO
				set_pev(weapon_ent, PEV_ADDITIONAL_AMMO, cs_get_user_bpammo(id, weaponid))
				cs_set_user_bpammo(id, weaponid, 0)
			}
			
			// Player drops the weapon
			engclient_cmd(id, "drop", wname)
		}
	}
}

// Strip primary/secondary/grenades
stock strip_weapons(id, stripwhat)
{
	// Get user weapons
	new weapons[32], num_weapons, index, weaponid
	get_user_weapons(id, weapons, num_weapons)
	
	// Loop through them and drop primaries or secondaries
	for (index = 0; index < num_weapons; index++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[index]
		
		if ((stripwhat == PRIMARY_ONLY && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		|| (stripwhat == SECONDARY_ONLY && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
		|| (stripwhat == GRENADES_ONLY && ((1<<weaponid) & GRENADES_WEAPONS_BIT_SUM)))
		{
			// Get weapon name
			new wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))
			
			// Strip weapon and remove bpammo
			ham_strip_weapon(id, wname)
			cs_set_user_bpammo(id, weaponid, 0)
		}
	}
}

stock ham_strip_weapon(index, const weapon[])
{
	// Get weapon id
	new weaponid = get_weaponid(weapon)
	if (!weaponid)
		return false;
	
	// Get weapon entity
	new weapon_ent = fm_find_ent_by_owner(-1, weapon, index)
	if (!weapon_ent)
		return false;
	
	// If it's the current weapon, retire first
	new current_weapon_ent = fm_cs_get_current_weapon_ent(index)
	new current_weapon = pev_valid(current_weapon_ent) ? cs_get_weapon_id(current_weapon_ent) : -1
	if (current_weapon == weaponid)
		ExecuteHamB(Ham_Weapon_RetireWeapon, weapon_ent)
	
	// Remove weapon from player
	if (!ExecuteHamB(Ham_RemovePlayerItem, index, weapon_ent))
		return false;
	
	// Kill weapon entity and fix pev_weapons bitsum
	ExecuteHamB(Ham_Item_Kill, weapon_ent)
	set_pev(index, pev_weapons, pev(index, pev_weapons) & ~(1<<weaponid))
	return true;
}

// Find entity by its owner (from fakemeta_util)
stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) { /* keep looping */ }
	return entity;
}

// Get User Current Weapon Entity
stock fm_cs_get_current_weapon_ent(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM);
}