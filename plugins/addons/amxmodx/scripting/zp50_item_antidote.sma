/*================================================================================
	
	---------------------------
	-*- [ZP] Item: Antidote -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#define ITEM_NAME "Antidote"
#define ITEM_COST 15

#include <amxmodx>
#include <zp50_items>
#include <zp50_gamemodes>

new g_ItemID
new g_GameModeInfectionID
new g_GameModeMultiID
new cvar_deathmatch, cvar_respawn_after_last_human
new g_AntidotesTaken, cvar_antidote_round_limit

public plugin_init()
{
	register_plugin("[ZP] Item: Antidote", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	g_ItemID = zp_items_register(ITEM_NAME, ITEM_COST)
	cvar_antidote_round_limit = register_cvar("zp_antidote_round_limit", "5")
}

public plugin_cfg()
{
	g_GameModeInfectionID = zp_gamemodes_get_id("Infection Mode")
	g_GameModeMultiID = zp_gamemodes_get_id("Multiple Infection Mode")
	cvar_deathmatch = get_cvar_pointer("zp_deathmatch")
	cvar_respawn_after_last_human = get_cvar_pointer("zp_respawn_after_last_human")
}

public event_round_start()
{
	g_AntidotesTaken = 0
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_ItemID)
		return ZP_ITEM_AVAILABLE;
	
	// Antidote only available during infection modes
	new current_mode = zp_gamemodes_get_current()
	if (current_mode != g_GameModeInfectionID && current_mode != g_GameModeMultiID)
		return ZP_ITEM_DONT_SHOW;
	
	// Antidote only available to zombies
	if (!zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW;
	
	// Display remaining item count for this round
	static text[32]
	formatex(text, charsmax(text), "[%d/%d]", g_AntidotesTaken, get_pcvar_num(cvar_antidote_round_limit))
	zp_items_menu_text_add(text)
	
	// Antidote not available to last zombie
	if (zp_core_get_zombie_count() == 1)
		return ZP_ITEM_NOT_AVAILABLE;
	
	// Deathmatch mode enabled, respawn after last human disabled, and only one human left
	if (cvar_deathmatch && get_pcvar_num(cvar_deathmatch) && cvar_respawn_after_last_human
	&& !get_pcvar_num(cvar_respawn_after_last_human) && zp_core_get_human_count() == 1)
		return ZP_ITEM_NOT_AVAILABLE;
	
	// Reached antidote limit for this round
	if (g_AntidotesTaken >= get_pcvar_num(cvar_antidote_round_limit))
		return ZP_ITEM_NOT_AVAILABLE;
	
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_ItemID)
		return;
	
	// Make player cure himself
	zp_core_cure(id, id)
	g_AntidotesTaken++
}
