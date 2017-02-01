/*================================================================================
	
	---------------------------------
	-*- [ZP] Human Unlimited Ammo -*-
	---------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <zp50_core>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>

// CS Player CBase Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_ACTIVE_ITEM = 373

// Weapon IDs for ammo types
new const AMMOWEAPON[] = { 0, CSW_AWP, CSW_SCOUT, CSW_M249, CSW_AUG, CSW_XM1014, CSW_MAC10, CSW_FIVESEVEN, CSW_DEAGLE,
			CSW_P228, CSW_ELITE, CSW_FLASHBANG, CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_C4 }

// Ammo Type Names for weapons
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
			"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }

// Max Clip for weapons
new const MAXCLIP[] = { -1, 13, -1, 10, -1, 7, -1, 30, 30, -1, 30, 20, 25, 30, 35, 25, 12, 20,
			10, 30, 100, 8, 30, 30, 20, -1, 7, 30, 30, -1, 50 }

// BP Ammo Refill task
#define REFILL_WEAPONID args[0]

new g_MsgAmmoPickup

new cvar_human_unlimited_ammo, cvar_survivor_unlimited_ammo

public plugin_init()
{
	register_plugin("[ZP] Human Unlimited Ammo", ZP_VERSION_STRING, "ZP Dev Team")
	
	cvar_human_unlimited_ammo = register_cvar("zp_human_unlimited_ammo", "0") // 1-bp ammo // 2-clip ammo
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
		cvar_survivor_unlimited_ammo = register_cvar("zp_survivor_unlimited_ammo", "1") // 1-bp ammo // 2-clip ammo
	
	register_event("AmmoX", "event_ammo_x", "be")
	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")
	
	g_MsgAmmoPickup = get_user_msgid("AmmoPickup")
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

// BP Ammo update
public event_ammo_x(id)
{
	// Not alive or not human
	if (!is_user_alive(id) || zp_core_is_zombie(id))
		return;
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
	{
		// Unlimited BP ammo enabled for survivor?
		if (get_pcvar_num(cvar_survivor_unlimited_ammo) < 1)
			return;
	}
	else
	{
		// Unlimited BP ammo enabled for humans?
		if (get_pcvar_num(cvar_human_unlimited_ammo) < 1)
			return;
	}
	
	// Get ammo type
	new type = read_data(1)
	
	// Unknown ammo type
	if (type >= sizeof AMMOWEAPON)
		return;
	
	// Get weapon's id
	new weapon = AMMOWEAPON[type]
	
	// Primary and secondary only
	if (MAXBPAMMO[weapon] <= 2)
		return;
	
	// Get ammo amount
	new amount = read_data(2)
	
	// Unlimited BP Ammo
	if (amount < MAXBPAMMO[weapon])
	{
		// The BP Ammo refill code causes the engine to send a message, but we
		// can't have that in this forward or we risk getting some recursion bugs.
		// For more info see: https://bugs.alliedmods.net/show_bug.cgi?id=3664
		new args[1]
		args[0] = weapon
		set_task(0.1, "refill_bpammo", id, args, sizeof args)
	}
}

// Refill BP Ammo Task
public refill_bpammo(const args[], id)
{
	// Player died or turned into a zombie
	if (!is_user_alive(id) || zp_core_is_zombie(id))
		return;
	
	new block_status = get_msg_block(g_MsgAmmoPickup)
	set_msg_block(g_MsgAmmoPickup, BLOCK_ONCE)
	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[REFILL_WEAPONID], AMMOTYPE[REFILL_WEAPONID], MAXBPAMMO[REFILL_WEAPONID])
	set_msg_block(g_MsgAmmoPickup, block_status)
}

// Current Weapon info
public message_cur_weapon(msg_id, msg_dest, msg_entity)
{
	// Not alive or not human
	if (!is_user_alive(msg_entity) || zp_core_is_zombie(msg_entity))
		return;
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(msg_entity))
	{
		// Unlimited Clip ammo enabled for humans?
		if (get_pcvar_num(cvar_survivor_unlimited_ammo) < 2)
			return;
	}
	else
	{
		// Unlimited Clip ammo enabled for humans?
		if (get_pcvar_num(cvar_human_unlimited_ammo) < 2)
			return;
	}
	
	// Not an active weapon
	if (get_msg_arg_int(1) != 1)
		return;
	
	// Get weapon's id
	new weapon = get_msg_arg_int(2)
	
	// Primary and secondary only
	if (MAXBPAMMO[weapon] <= 2)
		return;
	
	// Max out clip ammo
	new weapon_ent = fm_cs_get_current_weapon_ent(msg_entity)
	if (pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, MAXCLIP[weapon])
	
	// HUD should show full clip all the time
	set_msg_arg_int(3, get_msg_argtype(3), MAXCLIP[weapon])
}

// Get User Current Weapon Entity
stock fm_cs_get_current_weapon_ent(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM);
}