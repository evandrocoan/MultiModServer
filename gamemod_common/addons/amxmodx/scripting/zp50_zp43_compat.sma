/*================================================================================
	
	-------------------------------------------
	-*- [ZP] ZP 4.3 Subplugin Compatibility -*-
	-------------------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_player_models_api>
#include <zp50_class_zombie>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#include <zp50_gamemodes>
#define LIBRARY_FLASHLIGHT "zp50_flashlight"
#include <zp50_flashlight>
#define LIBRARY_EXTRAITEMS "zp50_items"
#include <zp50_items>
#define LIBRARY_AMMOPACKS "zp50_ammopacks"
#include <zp50_ammopacks>
#define LIBRARY_GRENADE_FROST "zp50_grenade_frost"
#include <zp50_grenade_frost>

#define CS_MONEY_LIMIT 16000
#define is_user_valid(%1) (1 <= %1 <= g_MaxPlayers)

#define ZP_EXTRAITEMS_FILE "zp_extraitems.ini"
#define CLAWMODEL_PATH "models/zombie_plague/%s"

#define ZP_TEAM_ANY 0
#define ZP_TEAM_ZOMBIE (1<<0)
#define ZP_TEAM_HUMAN (1<<1)
#define ZP_TEAM_NEMESIS (1<<2)
#define ZP_TEAM_SURVIVOR (1<<3)
new const ZP_TEAM_NAMES[][] = { "ZOMBIE , HUMAN", "ZOMBIE", "HUMAN", "ZOMBIE , HUMAN", "NEMESIS",
			"ZOMBIE , NEMESIS", "HUMAN , NEMESIS", "ZOMBIE , HUMAN , NEMESIS",
			"SURVIVOR", "ZOMBIE , SURVIVOR", "HUMAN , SURVIVOR", "ZOMBIE , HUMAN , SURVIVOR",
			"NEMESIS , SURVIVOR", "ZOMBIE , NEMESIS , SURVIVOR", "HUMAN, NEMESIS, SURVIVOR",
			"ZOMBIE , HUMAN , NEMESIS , SURVIVOR" }

enum
{
	MODE_CUSTOM = 0,
	MODE_INFECTION,
	MODE_NEMESIS,
	MODE_SURVIVOR,
	MODE_SWARM,
	MODE_MULTI,
	MODE_PLAGUE
}

// There was a bug with ZP 4.3 round end forward: it passed ZP_TEAM_ZOMBIE
// and ZP_TEAM_HUMAN instead of WIN_ZOMBIES and WIN_HUMANS. This is not
// fixed here either in order to keep better backwards compatibility.
#define WIN_NO_ONE 0
#define WIN_ZOMBIES ZP_TEAM_ZOMBIE
#define WIN_HUMANS ZP_TEAM_HUMAN

#define ZP_PLUGIN_HANDLED 97

enum _:TOTAL_FORWARDS
{
	FW_ROUND_STARTED = 0,
	FW_ROUND_ENDED,
	FW_USER_INFECT_ATTEMPT,
	FW_USER_INFECTED_PRE,
	FW_USER_INFECTED_POST,
	FW_USER_HUMANIZE_ATTEMPT,
	FW_USER_HUMANIZED_PRE,
	FW_USER_HUMANIZED_POST,
	FW_EXTRA_ITEM_SELECTED,
	FW_USER_UNFROZEN,
	FW_USER_LAST_ZOMBIE,
	FW_USER_LAST_HUMAN
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_MaxPlayers

new cvar_ammopack_to_money_enable, cvar_ammopack_to_money_ratio
new cvar_zombie_first_hp_multiplier

new g_GameModeInfectionID, g_GameModeMultiID, g_GameModeNemesisID, g_GameModeSurvivorID, g_GameModeSwarmID, g_GameModePlagueID
new g_ModeStarted

new Array:g_ItemID, Array:g_ItemTeams

public plugin_init()
{
	register_plugin("[ZP] ZP 4.3 Subplugin Compatibility", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	g_MaxPlayers = get_maxplayers()
	
	cvar_ammopack_to_money_enable = register_cvar("zp_ammopack_to_money_enable", "1")
	cvar_ammopack_to_money_ratio = register_cvar("zp_ammopack_to_money_ratio", "160") // 1 Ammo Pack = $ 160
	cvar_zombie_first_hp_multiplier = get_cvar_pointer("zp_zombie_first_hp_multiplier")
	
	// Forwards
	g_Forwards[FW_ROUND_STARTED] = CreateMultiForward("zp_round_started", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_ROUND_ENDED] = CreateMultiForward("zp_round_ended", ET_IGNORE, FP_CELL)
	g_Forwards[FW_USER_INFECT_ATTEMPT] = CreateMultiForward("zp_user_infect_attempt", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_INFECTED_PRE] = CreateMultiForward("zp_user_infected_pre", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_INFECTED_POST] = CreateMultiForward("zp_user_infected_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_HUMANIZE_ATTEMPT] = CreateMultiForward("zp_user_humanize_attempt", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_HUMANIZED_PRE] = CreateMultiForward("zp_user_humanized_pre", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_HUMANIZED_POST] = CreateMultiForward("zp_user_humanized_post", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_EXTRA_ITEM_SELECTED] = CreateMultiForward("zp_extra_item_selected", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_UNFROZEN] = CreateMultiForward("zp_user_unfrozen", ET_IGNORE, FP_CELL)
	g_Forwards[FW_USER_LAST_ZOMBIE] = CreateMultiForward("zp_user_last_zombie", ET_IGNORE, FP_CELL)
	g_Forwards[FW_USER_LAST_HUMAN] = CreateMultiForward("zp_user_last_human", ET_IGNORE, FP_CELL)
}

public plugin_precache()
{
	// For subplugins that check if ZP is enabled
	register_cvar("zp_on", "1", FCVAR_SERVER|FCVAR_SPONLY)
}

public event_round_start()
{
	g_ModeStarted = false
}

public zp_fw_gamemodes_start(game_mode_id)
{
	if (game_mode_id == g_GameModeInfectionID)
	{
		// Get first zombie index
		new player_index = 1
		while ((!is_user_alive(player_index) || !zp_core_is_zombie(player_index)) && player_index <= g_MaxPlayers)
			player_index++
		
		if (player_index > g_MaxPlayers)
		{
			abort(AMX_ERR_GENERAL, "ERROR - first zombie index not found!")
			player_index = 0
		}
		
		ExecuteForward(g_Forwards[FW_ROUND_STARTED], g_ForwardResult, MODE_INFECTION, player_index)
	}
	else if (game_mode_id == g_GameModeMultiID)
	{
		ExecuteForward(g_Forwards[FW_ROUND_STARTED], g_ForwardResult, MODE_MULTI, 0)
	}
	else if (game_mode_id == g_GameModeNemesisID)
	{
		// Get nemesis index
		new player_index = 1
		while ((!is_user_alive(player_index) || !zp_class_nemesis_get(player_index)) && player_index <= g_MaxPlayers)
			player_index++
		
		if (player_index > g_MaxPlayers)
		{
			abort(AMX_ERR_GENERAL, "ERROR - nemesis index not found!")
			player_index = 0
		}
		
		ExecuteForward(g_Forwards[FW_ROUND_STARTED], g_ForwardResult, MODE_NEMESIS, player_index)
	}
	else if (game_mode_id == g_GameModeSurvivorID)
	{
		// Get survivor index
		new player_index = 1
		while ((!is_user_alive(player_index) || !zp_class_survivor_get(player_index)) && player_index <= g_MaxPlayers)
			player_index++
		
		if (player_index > g_MaxPlayers)
		{
			abort(AMX_ERR_GENERAL, "ERROR - survivor index not found!")
			player_index = 0
		}
		
		ExecuteForward(g_Forwards[FW_ROUND_STARTED], g_ForwardResult, MODE_SURVIVOR, player_index)
	}
	else if (game_mode_id == g_GameModeSwarmID)
	{
		ExecuteForward(g_Forwards[FW_ROUND_STARTED], g_ForwardResult, MODE_SWARM, 0)
	}
	else if (game_mode_id == g_GameModePlagueID)
	{
		ExecuteForward(g_Forwards[FW_ROUND_STARTED], g_ForwardResult, MODE_PLAGUE, 0)
	}
	else
	{
		// Custom game mode started, pass MODE_CUSTOM (0) as mode parameter
		ExecuteForward(g_Forwards[FW_ROUND_STARTED], g_ForwardResult, MODE_CUSTOM, 0)
	}
	
	g_ModeStarted = true
}

public zp_fw_gamemodes_end(game_mode_id)
{
	if (!zp_core_get_zombie_count())
		ExecuteForward(g_Forwards[FW_ROUND_ENDED], g_ForwardResult, WIN_HUMANS)
	else if (!zp_core_get_human_count())
		ExecuteForward(g_Forwards[FW_ROUND_ENDED], g_ForwardResult, WIN_ZOMBIES)
	else
		ExecuteForward(g_Forwards[FW_ROUND_ENDED], g_ForwardResult, WIN_NO_ONE)
}

public zp_fw_core_infect_pre(id, attacker)
{
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
		ExecuteForward(g_Forwards[FW_USER_INFECT_ATTEMPT], g_ForwardResult, id, attacker, true)
	else
		ExecuteForward(g_Forwards[FW_USER_INFECT_ATTEMPT], g_ForwardResult, id, attacker, false)
	
	if (g_ForwardResult >= ZP_PLUGIN_HANDLED && g_ModeStarted && zp_core_get_zombie_count() > 0)
		return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public zp_fw_core_infect(id, attacker)
{
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
		ExecuteForward(g_Forwards[FW_USER_INFECTED_PRE], g_ForwardResult, id, attacker, true)
	else
		ExecuteForward(g_Forwards[FW_USER_INFECTED_PRE], g_ForwardResult, id, attacker, false)
}

public zp_fw_core_infect_post(id, attacker)
{
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
		ExecuteForward(g_Forwards[FW_USER_INFECTED_POST], g_ForwardResult, id, attacker, true)
	else
		ExecuteForward(g_Forwards[FW_USER_INFECTED_POST], g_ForwardResult, id, attacker, false)
}

public zp_fw_core_cure_pre(id, attacker)
{
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
		ExecuteForward(g_Forwards[FW_USER_HUMANIZE_ATTEMPT], g_ForwardResult, id, true)
	else
		ExecuteForward(g_Forwards[FW_USER_HUMANIZE_ATTEMPT], g_ForwardResult, id, false)
	
	if (g_ForwardResult >= ZP_PLUGIN_HANDLED && g_ModeStarted && zp_core_get_human_count() > 0)
		return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public zp_fw_core_cure(id, attacker)
{
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
		ExecuteForward(g_Forwards[FW_USER_HUMANIZED_PRE], g_ForwardResult, id, true)
	else
		ExecuteForward(g_Forwards[FW_USER_HUMANIZED_PRE], g_ForwardResult, id, false)
}

public zp_fw_core_cure_post(id, attacker)
{
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
		ExecuteForward(g_Forwards[FW_USER_HUMANIZED_POST], g_ForwardResult, id, true)
	else
		ExecuteForward(g_Forwards[FW_USER_HUMANIZED_POST], g_ForwardResult, id, false)
}

public zp_fw_items_select_post(id, itemid)
{
	ExecuteForward(g_Forwards[FW_EXTRA_ITEM_SELECTED], g_ForwardResult, id, itemid)
	if (g_ForwardResult >= ZP_PLUGIN_HANDLED)
	{
		// Item purchase was blocked, restore player's money/ammo packs
		new item_cost = zp_items_get_cost(itemid)
		
		if (LibraryExists(LIBRARY_AMMOPACKS, LibType_Library))
			zp_ammopacks_set(id, zp_ammopacks_get(id) + item_cost)
		else
			cs_set_user_money(id, cs_get_user_money(id) + item_cost, 0)
	}
}

public zp_fw_grenade_frost_unfreeze(id)
{
	ExecuteForward(g_Forwards[FW_USER_UNFROZEN], g_ForwardResult, id)
}

public zp_fw_core_last_zombie(id)
{
	ExecuteForward(g_Forwards[FW_USER_LAST_ZOMBIE], g_ForwardResult, id)
}

public zp_fw_core_last_human(id)
{
	ExecuteForward(g_Forwards[FW_USER_LAST_HUMAN], g_ForwardResult, id)
}

public plugin_cfg()
{
	g_GameModeInfectionID = zp_gamemodes_get_id("Infection Mode")
	g_GameModeMultiID = zp_gamemodes_get_id("Multiple Infection Mode")
	g_GameModeNemesisID = zp_gamemodes_get_id("Nemesis Mode")
	g_GameModeSurvivorID = zp_gamemodes_get_id("Survivor Mode")
	g_GameModeSwarmID = zp_gamemodes_get_id("Swarm Mode")
	g_GameModePlagueID = zp_gamemodes_get_id("Plague Mode")
}

public plugin_natives()
{
	register_library("zp50_zp43_compat")
	
	// Natives
	register_native("zp_get_user_zombie", "native_get_user_zombie")
	register_native("zp_get_user_nemesis", "native_get_user_nemesis")
	register_native("zp_get_user_survivor", "native_get_user_survivor")
	register_native("zp_get_user_first_zombie", "native_get_user_first_zombie")
	register_native("zp_get_user_last_zombie", "native_get_user_last_zombie")
	register_native("zp_get_user_last_human", "native_get_user_last_human")
	register_native("zp_get_user_zombie_class", "native_get_user_zombie_class")
	register_native("zp_get_user_next_class", "native_get_user_next_class")
	register_native("zp_set_user_zombie_class", "native_set_user_zombie_class")
	register_native("zp_get_user_ammo_packs", "native_get_user_ammo_packs")
	register_native("zp_set_user_ammo_packs", "native_set_user_ammo_packs")
	register_native("zp_get_zombie_maxhealth", "native_get_zombie_maxhealth")
	register_native("zp_get_user_batteries", "native_get_user_batteries")
	register_native("zp_set_user_batteries", "native_set_user_batteries")
	register_native("zp_get_user_nightvision", "native_get_user_nightvision")
	register_native("zp_set_user_nightvision", "native_set_user_nightvision")
	register_native("zp_infect_user", "native_infect_user")
	register_native("zp_disinfect_user", "native_disinfect_user")
	register_native("zp_make_user_nemesis", "native_make_user_nemesis")
	register_native("zp_make_user_survivor", "native_make_user_survivor")
	register_native("zp_respawn_user", "native_respawn_user")
	register_native("zp_force_buy_extra_item", "native_force_buy_extra_item")
	register_native("zp_override_user_model", "native_override_user_model")
	register_native("zp_has_round_started", "native_has_round_started")
	register_native("zp_is_nemesis_round", "native_is_nemesis_round")
	register_native("zp_is_survivor_round", "native_is_survivor_round")
	register_native("zp_is_swarm_round", "native_is_swarm_round")
	register_native("zp_is_plague_round", "native_is_plague_round")
	register_native("zp_get_zombie_count", "native_get_zombie_count")
	register_native("zp_get_human_count", "native_get_human_count")
	register_native("zp_get_nemesis_count", "native_get_nemesis_count")
	register_native("zp_get_survivor_count", "native_get_survivor_count")
	register_native("zp_register_extra_item", "native_register_extra_item")
	register_native("zp_register_zombie_class", "native_register_zombie_class")
	register_native("zp_get_extra_item_id", "native_get_extra_item_id")
	register_native("zp_get_zombie_class_id", "native_get_zombie_class_id")
	register_native("zp_get_zombie_class_info", "native_get_zombie_class_info")
	
	// Initialize dynamic arrays
	g_ItemID = ArrayCreate(1, 1)
	g_ItemTeams = ArrayCreate(1, 1)
	
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_SURVIVOR) || equal(module, LIBRARY_EXTRAITEMS) || equal(module, LIBRARY_FLASHLIGHT) || equal(module, LIBRARY_AMMOPACKS) || equal(module, LIBRARY_GRENADE_FROST))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public native_get_user_zombie(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return zp_core_is_zombie(id);
}

public native_get_user_nemesis(plugin_id, num_params)
{
	if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library))
		return false;
	
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return zp_class_nemesis_get(id);
}

public native_get_user_survivor(plugin_id, num_params)
{
	if (!LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
		return false;
	
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return zp_class_survivor_get(id);
}

public native_get_user_first_zombie(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return zp_core_is_first_zombie(id);
}

public native_get_user_last_zombie(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return zp_core_is_last_zombie(id);
}

public native_get_user_last_human(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return zp_core_is_last_human(id);
}

public native_get_user_zombie_class(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return zp_class_zombie_get_current(id);
}

public native_get_user_next_class(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return zp_class_zombie_get_next(id);
}

public native_set_user_zombie_class(plugin_id, num_params)
{
	new id = get_param(1)
	new classid = get_param(2)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return zp_class_zombie_set_next(id, classid);
}

public native_get_user_ammo_packs(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	if (LibraryExists(LIBRARY_AMMOPACKS, LibType_Library))
		return zp_ammopacks_get(id);
	
	if (!get_pcvar_num(cvar_ammopack_to_money_enable))
		return -1;
	
	return cs_get_user_money(id) / get_pcvar_num(cvar_ammopack_to_money_ratio);
}

public native_set_user_ammo_packs(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new amount = get_param(2)
	
	if (LibraryExists(LIBRARY_AMMOPACKS, LibType_Library))
		return zp_ammopacks_set(id, amount);
	
	if (!get_pcvar_num(cvar_ammopack_to_money_enable))
		return false;
	
	new money = min(amount * get_pcvar_num(cvar_ammopack_to_money_ratio), CS_MONEY_LIMIT)
	cs_set_user_money(id, money)
	return true;
}

public native_get_zombie_maxhealth(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	new classid = zp_class_zombie_get_current(id)
	
	if (classid == ZP_INVALID_ZOMBIE_CLASS)
		return -1;
	
	if (cvar_zombie_first_hp_multiplier && zp_core_is_first_zombie(id))
		return floatround(float(zp_class_zombie_get_max_health(id, classid)) * get_pcvar_float(cvar_zombie_first_hp_multiplier));
	
	return zp_class_zombie_get_max_health(id, classid);
}

public native_get_user_batteries(plugin_id, num_params)
{
	if (!LibraryExists(LIBRARY_FLASHLIGHT, LibType_Library))
		return -1;
	
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return zp_flashlight_get_charge(id);
}

public native_set_user_batteries(plugin_id, num_params)
{
	if (!LibraryExists(LIBRARY_FLASHLIGHT, LibType_Library))
		return false;
	
	new id = get_param(1)
	new charge = get_param(2)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return zp_flashlight_set_charge(id, charge);
}

public native_get_user_nightvision(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return cs_get_user_nvg(id);
}

public native_set_user_nightvision(plugin_id, num_params)
{
	new id = get_param(1)
	new set = get_param(2)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	cs_set_user_nvg(id, set)
	return true;
}

public native_infect_user(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new attacker = get_param(2)
	
	if (attacker && !is_user_alive(attacker))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", attacker)
		return false;
	}
	
	if (attacker)
		return zp_core_infect(id, attacker);
	new silent = get_param(3)
	return zp_core_infect(id, silent ? 0 : id);
}

public native_disinfect_user(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new silent = get_param(2)
	return zp_core_cure(id, silent ? 0 : id);
}

public native_make_user_nemesis(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return zp_class_nemesis_set(id);
}

public native_make_user_survivor(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return zp_class_survivor_set(id);
}

public native_respawn_user(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	// Respawn not allowed
	if (!allowed_respawn(id))
		return false;
	
	new team = get_param(2)
	
	if (team == ZP_TEAM_ZOMBIE)
		zp_core_respawn_as_zombie(id, true)
	else
		zp_core_respawn_as_zombie(id, false)
	
	// Respawn!
	ExecuteHamB(Ham_CS_RoundRespawn, id)
	return true;
}

// Checks if a player is allowed to respawn
allowed_respawn(id)
{
	if (is_user_alive(id))
		return false;
	
	new CsTeams:team = cs_get_user_team(id)
	
	if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
		return false;
	
	return true;
}

public native_force_buy_extra_item(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new itemid = get_param(2)
	new ignorecost = get_param(3)
	return zp_items_force_buy(id, itemid, ignorecost);
}

public native_override_user_model(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new new_model[32]
	get_string(2, new_model, charsmax(new_model))
	
	cs_set_player_model(id, new_model)
	return true;
}

public native_has_round_started(plugin_id, num_params)
{
	if (!g_ModeStarted)
	{
		if (zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
			return 0; // not started
		
		return 2; // starting
	}
	return 1; // started
}

public native_is_nemesis_round(plugin_id, num_params)
{
	return (zp_gamemodes_get_current() == g_GameModeNemesisID);
}

public native_is_survivor_round(plugin_id, num_params)
{
	return (zp_gamemodes_get_current() == g_GameModeSurvivorID);
}

public native_is_swarm_round(plugin_id, num_params)
{
	return (zp_gamemodes_get_current() == g_GameModeSwarmID);
}

public native_is_plague_round(plugin_id, num_params)
{
	return (zp_gamemodes_get_current() == g_GameModePlagueID);
}

public native_get_zombie_count(plugin_id, num_params)
{
	return zp_core_get_zombie_count();
}

public native_get_human_count(plugin_id, num_params)
{
	return zp_core_get_human_count();
}

public native_get_nemesis_count(plugin_id, num_params)
{
	return zp_class_nemesis_get_count();
}

public native_get_survivor_count(plugin_id, num_params)
{
	return zp_class_survivor_get_count();
}

public native_register_extra_item(plugin_id, num_params)
{
	if (!LibraryExists(LIBRARY_EXTRAITEMS, LibType_Library))
		return -1;
	
	new name[32]
	get_string(1, name, charsmax(name))
	new cost = get_param(2)
	
	new itemid = zp_items_register(name, cost)
	if (itemid < 0) return itemid;
	
	// Item Teams
	new teams_bitsum = get_param(3)
	if (teams_bitsum == ZP_TEAM_ANY) teams_bitsum = (ZP_TEAM_ZOMBIE|ZP_TEAM_HUMAN) // backwards compatibility
	
	// Load/save teams
	new teams_string[64]
	if (!amx_load_setting_string(ZP_EXTRAITEMS_FILE, name, "TEAMS", teams_string, charsmax(teams_string)))
		amx_save_setting_string(ZP_EXTRAITEMS_FILE, name, "TEAMS", ZP_TEAM_NAMES[teams_bitsum])
	else
	{
		teams_bitsum = 0
		if (contain(teams_string, ZP_TEAM_NAMES[ZP_TEAM_ZOMBIE]) != -1)
			teams_bitsum |= ZP_TEAM_ZOMBIE
		if (contain(teams_string, ZP_TEAM_NAMES[ZP_TEAM_HUMAN]) != -1)
			teams_bitsum |= ZP_TEAM_HUMAN
		if (contain(teams_string, ZP_TEAM_NAMES[ZP_TEAM_NEMESIS]) != -1)
			teams_bitsum |= ZP_TEAM_NEMESIS
		if (contain(teams_string, ZP_TEAM_NAMES[ZP_TEAM_SURVIVOR]) != -1)
			teams_bitsum |= ZP_TEAM_SURVIVOR
	}
	
	// Add ZP team restrictions
	ArrayPushCell(g_ItemID, itemid)
	ArrayPushCell(g_ItemTeams, teams_bitsum)
	return itemid;
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// Is this our item?
	new index
	for (index = 0; index < ArraySize(g_ItemID); index++)
		if (itemid == ArrayGetCell(g_ItemID, index)) break;
	
	// This is not our item (loop reaching its end condition means no matches)
	if (index >= ArraySize(g_ItemID))
		return ZP_ITEM_AVAILABLE;
	
	// Get team restrictions
	new teams_bitsum = ArrayGetCell(g_ItemTeams, index)
	
	// Check team restrictions
	if (zp_core_is_zombie(id))
	{
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
		{
			if (!(teams_bitsum & ZP_TEAM_NEMESIS))
				return ZP_ITEM_DONT_SHOW;
		}
		else
		{
			if (!(teams_bitsum & ZP_TEAM_ZOMBIE))
				return ZP_ITEM_DONT_SHOW;
		}
	}
	else
	{
		if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
		{
			if (!(teams_bitsum & ZP_TEAM_SURVIVOR))
				return ZP_ITEM_DONT_SHOW;
		}
		else
		{
			if (!(teams_bitsum & ZP_TEAM_HUMAN))
				return ZP_ITEM_DONT_SHOW;
		}
	}
	
	return ZP_ITEM_AVAILABLE;
}

public native_register_zombie_class(plugin_id, num_params)
{
	new name[32], desc[32], model[32], clawmodel[64]
	get_string(1, name, charsmax(name))
	get_string(2, desc, charsmax(desc))
	get_string(3, model, charsmax(model))
	get_string(4, clawmodel, charsmax(clawmodel))
	format(clawmodel, charsmax(clawmodel), CLAWMODEL_PATH, clawmodel)
	new health = get_param(5)
	new Float:speed = float(get_param(6))
	new Float:gravity = get_param_f(7)
	new Float:knockback = get_param_f(8)
	new classid = zp_class_zombie_register(name, desc, health, speed, gravity)
	if (classid < 0) return classid;
	zp_class_zombie_register_model(classid, model)
	zp_class_zombie_register_claw(classid, clawmodel)
	zp_class_zombie_register_kb(classid, knockback)
	return classid;
}

public native_get_extra_item_id(plugin_id, num_params)
{
	if (!LibraryExists(LIBRARY_EXTRAITEMS, LibType_Library))
		return -1;
	
	new name[32]
	get_string(1, name, charsmax(name))
	return zp_items_get_id(name);
}

public native_get_zombie_class_id(plugin_id, num_params)
{
	new name[32]
	get_string(1, name, charsmax(name))
	return zp_class_zombie_get_id(name);
}

public native_get_zombie_class_info(plugin_id, num_params)
{
	new classid = get_param(1)
	new info[32], len = get_param(3)
	new result = zp_class_zombie_get_desc(classid, info, len)
	if (!result) return false;
	set_string(2, info, len)
	return true;
}
