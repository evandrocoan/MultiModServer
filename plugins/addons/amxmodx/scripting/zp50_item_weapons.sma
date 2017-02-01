/*================================================================================
	
	--------------------------
	-*- [ZP] Item: Weapons -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <zp50_items>
#include <zp50_gamemodes>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Edit extra weapons cost on zp_extraitems.ini instead
#define ITEM_COST 10

// Defaults
new const weapon_names[][] = { "HE Grenade", "Flashbang", "Smoke Grenade", "AWP Magnum Sniper", "M249 Para Machinegun", "SG550 Auto-Sniper", "G3SG1 Auto-Sniper" }
new const weapon_items[][] = { "weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade", "weapon_awp", "weapon_m249", "weapon_sg550", "weapon_g3sg1" }

#define WEAPON_NAME_MAX_LENGTH 32

new Array:g_weapon_names
new Array:g_weapon_items
new Array:g_weapon_itemid

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

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

// CS Sounds
new const g_sound_buyammo[] = "items/9mmclip1.wav"

// HACK: pev_ field used to store additional ammo on weapons
const PEV_ADDITIONAL_AMMO = pev_iuser1

#define PRIMARY_ONLY 1
#define SECONDARY_ONLY 2

new cvar_survivor_weapon_block
new g_MsgAmmoPickup

public plugin_init()
{
	register_plugin("[ZP] Item: Weapons", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_MsgAmmoPickup = get_user_msgid("AmmoPickup")
	
	new index, weapon_name[32]
	for (index = 0; index < ArraySize(g_weapon_items); index++)
	{
		ArrayGetString(g_weapon_names, index, weapon_name, charsmax(weapon_name))
		ArrayPushCell(g_weapon_itemid, zp_items_register(weapon_name, ITEM_COST))
	}
}

public plugin_precache()
{
	// Initialize arrays
	g_weapon_names = ArrayCreate(WEAPON_NAME_MAX_LENGTH, 1)
	g_weapon_items = ArrayCreate(WEAPON_NAME_MAX_LENGTH, 1)
	g_weapon_itemid = ArrayCreate(1, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Extra Items: Weapons and their costs", "NAMES", g_weapon_names)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Extra Items: Weapons and their costs", "ITEMS", g_weapon_items)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_weapon_names) == 0)
	{
		for (index = 0; index < sizeof weapon_names; index++)
			ArrayPushString(g_weapon_names, weapon_names[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Extra Items: Weapons and their costs", "NAMES", g_weapon_names)
	}
	if (ArraySize(g_weapon_items) == 0)
	{
		for (index = 0; index < sizeof weapon_items; index++)
			ArrayPushString(g_weapon_items, weapon_items[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Extra Items: Weapons and their costs", "ITEMS", g_weapon_items)
	}
	
	precache_sound(g_sound_buyammo)
}

public plugin_cfg()
{
	cvar_survivor_weapon_block = get_cvar_pointer("zp_survivor_weapon_block")
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_SURVIVOR))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// Is this our item?
	new index
	for (index = 0; index < ArraySize(g_weapon_items); index++)
		if (itemid == ArrayGetCell(g_weapon_itemid, index)) break;
	
	// This is not our item (loop reaching its end condition means no matches)
	if (index >= ArraySize(g_weapon_items))
		return ZP_ITEM_AVAILABLE;
	
	// Weapons only available to humans
	if (zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW;
	
	// Weapons available to survivor?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id) && get_pcvar_num(cvar_survivor_weapon_block))
		return ZP_ITEM_DONT_SHOW;
	
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	// Is this our item?
	new index
	for (index = 0; index < ArraySize(g_weapon_items); index++)
		if (itemid == ArrayGetCell(g_weapon_itemid, index)) break;
	
	// This is not our item (loop reaching its end condition means no matches)
	if (index >= ArraySize(g_weapon_items))
		return;
	
	// Get weapon item
	new weapon_item[32]
	ArrayGetString(g_weapon_items, index, weapon_item, charsmax(weapon_item))
	
	// Get weapon's id
	new weaponid = get_weaponid(weapon_item)
	
	// Primary or secondary
	if ((1<<weaponid) & (PRIMARY_WEAPONS_BIT_SUM | SECONDARY_WEAPONS_BIT_SUM))
	{
		// Make user drop the previous one first
		drop_weapons(id, (1<<weaponid) & (PRIMARY_WEAPONS_BIT_SUM) ? PRIMARY_ONLY : SECONDARY_ONLY)
		
		// Give full BP ammo for the new one
		ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
		
		// Give weapon to player
		give_item(id, weapon_item)
	}
	// If we are giving a grenade which the user already owns
	else if (user_has_weapon(id, weaponid))
	{
		// Increase BP ammo on it instead
		cs_set_user_bpammo(id, weaponid, cs_get_user_bpammo(id, weaponid) + 1)
		
		// Flash ammo in hud
		message_begin(MSG_ONE_UNRELIABLE, g_MsgAmmoPickup, _, id)
		write_byte(AMMOID[weaponid]) // ammo id
		write_byte(1) // ammo amount
		message_end()
		
		// Play clip purchase sound
		emit_sound(id, CHAN_ITEM, g_sound_buyammo, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else
	{
		// Give weapon to player
		give_item(id, weapon_item)
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

// Find entity by its owner (from fakemeta_util)
stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) { /* keep looping */ }
	return entity;
}