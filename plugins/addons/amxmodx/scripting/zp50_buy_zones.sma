/*================================================================================
	
	---------------------
	-*- [ZP] Buyzones -*-
	---------------------
	
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
#define LIBRARY_AMMOPACKS "zp50_ammopacks"
#include <zp50_ammopacks>
#include <zp50_colorchat>

#define MAXPLAYERS 32
#define TASK_WELCOMEMSG 100

new const CS_BUYZONE_ENT[] = "func_buyzone"

// CS sounds
new const g_sound_buyammo[] = "items/9mmclip1.wav"

// CS Player CBase Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_MAPZONE = 235
const PLAYER_IN_BUYZONE = (1<<0)

// Weapon IDs for ammo types
new const AMMOWEAPON[] = { 0, CSW_AWP, CSW_SCOUT, CSW_M249, CSW_AUG, CSW_XM1014, CSW_MAC10, CSW_FIVESEVEN, CSW_DEAGLE,
			CSW_P228, CSW_ELITE, CSW_FLASHBANG, CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_C4 }

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }

// Amount of ammo to give when buying additional clips for weapons
new const BUYAMMO[] = { -1, 13, -1, 30, -1, 8, -1, 12, 30, -1, 30, 50, 12, 30, 30, 30, 12, 30,
			10, 30, 30, 8, 30, 30, 30, -1, 7, 30, 30, -1, 50 }

// Ammo Type Names for weapons
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
			"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }

new g_fwSpawn

new g_BuyzoneEnt
new Float:g_BuyTimeStart[MAXPLAYERS+1]

new cvar_buyzone_time, cvar_buyzone_humans, cvar_buyzone_zombies
new cvar_buy_ammo_human, cvar_buy_ammo_cost_ammopacks, cvar_buy_ammo_cost_money

public plugin_init()
{
	register_plugin("[ZP] Buyzones", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	unregister_forward(FM_Spawn, g_fwSpawn)
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	register_message(get_user_msgid("StatusIcon"), "message_status_icon")
	
	// Client commands
	register_clcmd("buyammo1", "clcmd_buyammo")
	register_clcmd("buyammo2", "clcmd_buyammo")
	
	cvar_buyzone_time = register_cvar("zp_buyzone_time", "15")
	cvar_buyzone_humans = register_cvar("zp_buyzone_humans", "1")
	cvar_buyzone_zombies = register_cvar("zp_buyzone_zombies", "0")
	
	cvar_buy_ammo_human = register_cvar("zp_buy_ammo_human", "1")
	cvar_buy_ammo_cost_ammopacks = register_cvar("zp_buy_ammo_cost_ammopacks", "1")
	cvar_buy_ammo_cost_money = register_cvar("zp_buy_ammo_cost_money", "100")
	
	// Bots buy ammo automatically
	register_event("AmmoX", "event_ammo_x", "be")
}

public plugin_precache()
{
	// Custom buyzone for all players
	g_BuyzoneEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, CS_BUYZONE_ENT))
	if (pev_valid(g_BuyzoneEnt))
	{
		dllfunc(DLLFunc_Spawn, g_BuyzoneEnt)
		set_pev(g_BuyzoneEnt, pev_solid, SOLID_NOT)
	}
	if (!pev_valid(g_BuyzoneEnt))
	{
		set_fail_state("Unable to spawn custom buyzone.")
		return;
	}
	
	// Prevent some entities from spawning
	g_fwSpawn = register_forward(FM_Spawn, "fw_Spawn")
	
	// Precache sounds
	precache_sound(g_sound_buyammo)
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_SURVIVOR) || equal(module, LIBRARY_AMMOPACKS))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public plugin_cfg()
{
	// Prevents CS buytime messing up ZP buytime cvar
	server_cmd("mp_buytime 99")
}

// Event Round Start
public event_round_start()
{
	// Show buyammo message?
	if (get_pcvar_num(cvar_buy_ammo_human))
	{
		remove_task(TASK_WELCOMEMSG)
		set_task(2.2, "task_welcome_msg", TASK_WELCOMEMSG)
	}
}

// Welcome Message Task
public task_welcome_msg()
{
	zp_colored_print(0, "%L", LANG_PLAYER, "NOTICE_INFO2")
}

// Bots buy ammo automatically
public event_ammo_x(id)
{
	if (!is_user_bot(id) || !is_user_alive(id) || zp_core_is_zombie(id))
		return;
	
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
	
	if (amount <= BUYAMMO[weapon])
	{
		// Task needed
		remove_task(id)
		set_task(0.1, "clcmd_buyammo", id)
	}
}

// Entity Spawn Forward
public fw_Spawn(entity)
{
	// Invalid entity
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	// Get classname
	new classname[32]
	pev(entity, pev_classname, classname, charsmax(classname))
	
	// Check whether it needs to be removed
	if (equal(classname, CS_BUYZONE_ENT))
	{
		engfunc(EngFunc_RemoveEntity, entity)
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public zp_fw_core_cure_post(id, attacker)
{
	if (get_pcvar_num(cvar_buyzone_humans) && (!LibraryExists(LIBRARY_SURVIVOR, LibType_Library) || !zp_class_survivor_get(id)))
	{
		// Buyzone time starts when player is set to human
		g_BuyTimeStart[id] = get_gametime()
	}
	else
	{
		// Buyzone time ends when player is set to human/survivor
		g_BuyTimeStart[id] = get_gametime() - get_pcvar_float(cvar_buyzone_time)
	}
}

public zp_fw_core_infect_post(id, attacker)
{
	if (get_pcvar_num(cvar_buyzone_zombies))
	{
		// Buyzone time starts when player is set to zombie
		g_BuyTimeStart[id] = get_gametime()
	}
	else
	{
		// Buyzone time ends when player is set to zombie
		g_BuyTimeStart[id] = get_gametime() - get_pcvar_float(cvar_buyzone_time)
	}
}

// Forward Player PreThink
public fw_PlayerPreThink(id)
{
	// Not alive
	if (!is_user_alive(id))
		return;
	
	// Enable custom buyzone for player during buytime, unless time expired
	if (get_gametime() < g_BuyTimeStart[id] + get_pcvar_float(cvar_buyzone_time))
		dllfunc(DLLFunc_Touch, g_BuyzoneEnt, id)
	// Remove offset immediately after buyzone time ends (bugfix)
	else if (cs_get_user_buyzone(id))
		fm_cs_set_user_buyzone_offset(id, false)
}

public message_status_icon(msg_id, msg_dest, msg_entity)
{
	if (!is_user_alive(msg_entity) || get_msg_arg_int(1) != 1)
		return;
	
	static sprite[10]
	get_msg_arg_string(2, sprite, charsmax(sprite))
	
	if (!equal(sprite, "buyzone"))
		return;
	
	if (get_gametime() < g_BuyTimeStart[msg_entity] + get_pcvar_float(cvar_buyzone_time))
		return;
	
	// Hide buyzone icon after buyzone time is over (bugfix)
	set_msg_arg_int(1, get_msg_argtype(1), 0)
}

// Buy BP Ammo
public clcmd_buyammo(id)
{
	// Setting disabled, player dead or zombie
	if (!get_pcvar_num(cvar_buy_ammo_human) || !is_user_alive(id) || zp_core_is_zombie(id))
		return;
	
	// Player standing in buyzone, allow buying weapon's ammo normally instead
	if ((get_gametime() < g_BuyTimeStart[id] + get_pcvar_float(cvar_buyzone_time)) && cs_get_user_buyzone(id))
		return;
	
	// Not enough money/ammo packs
	if (LibraryExists(LIBRARY_AMMOPACKS, LibType_Library))
	{
		if (zp_ammopacks_get(id) < get_pcvar_num(cvar_buy_ammo_cost_ammopacks))
		{
			zp_colored_print(id, "%L (%L)", id, "NOT_ENOUGH_AMMO", id, "REQUIRED_AMOUNT", get_pcvar_num(cvar_buy_ammo_cost_ammopacks))
			return;
		}
	}
	else
	{
		if (cs_get_user_money(id) < get_pcvar_num(cvar_buy_ammo_cost_money))
		{
			zp_colored_print(id, "%L (%L)", id, "NOT_ENOUGH_MONEY", id, "REQUIRED_AMOUNT", get_pcvar_num(cvar_buy_ammo_cost_money))
			return;
		}
	}
	
	// Get user weapons
	new weapons[32], num_weapons, index, weaponid, bpammo_before, refilled
	get_user_weapons(id, weapons, num_weapons)
	
	// Loop through them and give the right ammo type
	for (index = 0; index < num_weapons; index++)
	{
		// Prevents re-indexing the array
		weaponid = weapons[index]
		
		// Primary and secondary only
		if (MAXBPAMMO[weaponid] > 2)
		{
			bpammo_before = cs_get_user_bpammo(id, weaponid)
			
			// Give additional ammo
			ExecuteHamB(Ham_GiveAmmo, id, BUYAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
			
			// Check whether we actually refilled the weapon's ammo
			if (cs_get_user_bpammo(id, weaponid) - bpammo_before > 0)
				refilled = true
		}
	}
	
	// Weapons already have full ammo
	if (!refilled)
		return;
	
	// Deduce cost
	if (LibraryExists(LIBRARY_AMMOPACKS, LibType_Library))
		zp_ammopacks_set(id, zp_ammopacks_get(id) - get_pcvar_num(cvar_buy_ammo_cost_ammopacks))
	else
		cs_set_user_money(id, cs_get_user_money(id) - get_pcvar_num(cvar_buy_ammo_cost_money))
	
	// Play clip purchase sound, and notify player
	emit_sound(id, CHAN_ITEM, g_sound_buyammo, 1.0, ATTN_NORM, 0, PITCH_NORM)
	zp_colored_print(id, "%L", id, "AMMO_BOUGHT")
}

stock fm_cs_set_user_buyzone_offset(id, set = true)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return false;
	
	if (set)
		set_pdata_int(id, OFFSET_MAPZONE, get_pdata_int(id, OFFSET_MAPZONE) | PLAYER_IN_BUYZONE)
	else
		set_pdata_int(id, OFFSET_MAPZONE, get_pdata_int(id, OFFSET_MAPZONE) & ~PLAYER_IN_BUYZONE)
	return true;
}