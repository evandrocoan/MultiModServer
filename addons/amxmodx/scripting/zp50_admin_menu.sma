/*================================================================================
	
	-----------------------
	-*- [ZP] Admin Menu -*-
	-----------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <zp50_core>
#include <zp50_gamemodes>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#include <zp50_admin_commands>
#include <zp50_colorchat>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

#define ACCESSFLAG_MAX_LENGTH 2

// Access flags
new g_access_make_zombie[ACCESSFLAG_MAX_LENGTH] = "d"
new g_access_make_human[ACCESSFLAG_MAX_LENGTH] = "d"
new g_access_make_nemesis[ACCESSFLAG_MAX_LENGTH] = "d"
new g_access_make_survivor[ACCESSFLAG_MAX_LENGTH] = "d"
new g_access_respawn_players[ACCESSFLAG_MAX_LENGTH] = "d"
new g_access_start_game_mode[ACCESSFLAG_MAX_LENGTH] = "d"

// Admin menu actions
enum
{
	ACTION_INFECT_CURE = 0,
	ACTION_MAKE_NEMESIS,
	ACTION_MAKE_SURVIVOR,
	ACTION_RESPAWN_PLAYER,
	ACTION_START_GAME_MODE
}

// Menu keys
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

#define MAXPLAYERS 32

// For player/mode list menu handlers
#define PL_ACTION g_menu_data[id][0]
#define MENU_PAGE_PLAYERS g_menu_data[id][1]
#define MENU_PAGE_GAME_MODES g_menu_data[id][2]
new g_menu_data[MAXPLAYERS+1][3]

new g_MaxPlayers

public plugin_init()
{
	register_plugin("[ZP] Admin Menus", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_MaxPlayers = get_maxplayers()
	
	register_menu("Admin Menu", KEYSMENU, "menu_admin")
	register_clcmd("say /adminmenu", "clcmd_adminmenu")
	register_clcmd("say adminmenu", "clcmd_adminmenu")
}

public plugin_precache()
{
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE ZOMBIE", g_access_make_zombie, charsmax(g_access_make_zombie)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE ZOMBIE", g_access_make_zombie)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE HUMAN", g_access_make_human, charsmax(g_access_make_human)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE ZOMBIE", g_access_make_human)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE NEMESIS", g_access_make_nemesis, charsmax(g_access_make_nemesis)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE NEMESIS", g_access_make_nemesis)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE SURVIVOR", g_access_make_survivor, charsmax(g_access_make_survivor)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE SURVIVOR", g_access_make_survivor)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "RESPAWN PLAYERS", g_access_respawn_players, charsmax(g_access_respawn_players)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "RESPAWN PLAYERS", g_access_respawn_players)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "START GAME MODE", g_access_start_game_mode, charsmax(g_access_start_game_mode)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "START GAME MODE", g_access_start_game_mode)
}

public plugin_natives()
{
	register_library("zp50_admin_menu")
	register_native("zp_admin_menu_show", "native_admin_menu_show")
	
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_SURVIVOR))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public native_admin_menu_show(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	show_menu_admin(id)
	return true;
}

public client_disconnect(id)
{
	// Reset remembered menu pages
	MENU_PAGE_GAME_MODES = 0
	MENU_PAGE_PLAYERS = 0
}

public clcmd_adminmenu(id)
{
	show_menu_admin(id)
}

// Admin Menu
show_menu_admin(id)
{
	static menu[250]
	new len, userflags = get_user_flags(id)
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\y%L:^n^n", id, "MENU_ADMIN_TITLE")
	
	// 1. Infect/Cure command
	if (userflags & (read_flags(g_access_make_zombie) | read_flags(g_access_make_human)))
		len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "MENU_ADMIN1")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d1. %L^n", id, "MENU_ADMIN1")
	
	// 2. Nemesis command
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && (userflags & read_flags(g_access_make_nemesis)))
		len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L^n", id, "MENU_ADMIN2")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d2. %L^n", id, "MENU_ADMIN2")
	
	// 3. Survivor command
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && (userflags & read_flags(g_access_make_survivor)))
		len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L^n", id, "MENU_ADMIN3")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d3. %L^n", id, "MENU_ADMIN3")
	
	// 4. Respawn command
	if (userflags & read_flags(g_access_respawn_players))
		len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L^n", id, "MENU_ADMIN4")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d4. %L^n", id, "MENU_ADMIN4")
	
	// 5. Start Game Mode command
	if (userflags & read_flags(g_access_start_game_mode))
		len += formatex(menu[len], charsmax(menu) - len, "\r5.\w %L^n", id, "MENU_ADMIN_START_GAME_MODE")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d5. %L^n", id, "MENU_ADMIN_START_GAME_MODE")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n\r0.\w %L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "Admin Menu")
}

// Player List Menu
show_menu_player_list(id)
{
	static menu[128], player_name[32]
	new menuid, player, buffer[2], userflags = get_user_flags(id)
	
	// Title
	switch (PL_ACTION)
	{
		case ACTION_INFECT_CURE: formatex(menu, charsmax(menu), "%L\r", id, "MENU_ADMIN1")
		case ACTION_MAKE_NEMESIS: formatex(menu, charsmax(menu), "%L\r", id, "MENU_ADMIN2")
		case ACTION_MAKE_SURVIVOR: formatex(menu, charsmax(menu), "%L\r", id, "MENU_ADMIN3")
		case ACTION_RESPAWN_PLAYER: formatex(menu, charsmax(menu), "%L\r", id, "MENU_ADMIN4")
	}
	menuid = menu_create(menu, "menu_player_list")
	
	// Player List
	for (player = 0; player <= g_MaxPlayers; player++)
	{
		// Skip if not connected
		if (!is_user_connected(player))
			continue;
		
		// Get player's name
		get_user_name(player, player_name, charsmax(player_name))
		
		// Format text depending on the action to take
		switch (PL_ACTION)
		{
			case ACTION_INFECT_CURE: // Infect/Cure command
			{
				if (zp_core_is_zombie(player))
				{
					if ((userflags & read_flags(g_access_make_human)) && is_user_alive(player))
						formatex(menu, charsmax(menu), "%s \r[%L]", player_name, id, (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player)) ? "CLASS_NEMESIS" : "CLASS_ZOMBIE")
					else
						formatex(menu, charsmax(menu), "\d%s [%L]", player_name, id, (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player)) ? "CLASS_NEMESIS" : "CLASS_ZOMBIE")
				}
				else
				{
					if ((userflags & read_flags(g_access_make_zombie)) && is_user_alive(player))
						formatex(menu, charsmax(menu), "%s \y[%L]", player_name, id, (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player)) ? "CLASS_SURVIVOR" : "CLASS_HUMAN")
					else
						formatex(menu, charsmax(menu), "\d%s [%L]", player_name, id, (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player)) ? "CLASS_SURVIVOR" : "CLASS_HUMAN")
				}
			}
			case ACTION_MAKE_NEMESIS: // Nemesis command
			{
				if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && (userflags & read_flags(g_access_make_nemesis)) && is_user_alive(player) && !zp_class_nemesis_get(player))
				{
					if (zp_core_is_zombie(player))
						formatex(menu, charsmax(menu), "%s \r[%L]", player_name, id, (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player)) ? "CLASS_NEMESIS" : "CLASS_ZOMBIE")
					else
						formatex(menu, charsmax(menu), "%s \y[%L]", player_name, id, (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player)) ? "CLASS_SURVIVOR" : "CLASS_HUMAN")
				}
				else
					formatex(menu, charsmax(menu), "\d%s [%L]", player_name, id, zp_core_is_zombie(player) ? (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player)) ? "CLASS_NEMESIS" : "CLASS_ZOMBIE" : (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player)) ? "CLASS_SURVIVOR" : "CLASS_HUMAN")
			}
			case ACTION_MAKE_SURVIVOR: // Survivor command
			{
				if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && (userflags & read_flags(g_access_make_survivor)) && is_user_alive(player) && !zp_class_survivor_get(player))
				{
					if (zp_core_is_zombie(player))
						formatex(menu, charsmax(menu), "%s \r[%L]", player_name, id, (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player)) ? "CLASS_NEMESIS" : "CLASS_ZOMBIE")
					else
						formatex(menu, charsmax(menu), "%s \y[%L]", player_name, id, (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player)) ? "CLASS_SURVIVOR" : "CLASS_HUMAN")
				}
				else
					formatex(menu, charsmax(menu), "\d%s [%L]", player_name, id, zp_core_is_zombie(player) ? (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player)) ? "CLASS_NEMESIS" : "CLASS_ZOMBIE" : (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player)) ? "CLASS_SURVIVOR" : "CLASS_HUMAN")
			}
			case ACTION_RESPAWN_PLAYER: // Respawn command
			{
				if ((userflags & read_flags(g_access_respawn_players)) && allowed_respawn(player))
					formatex(menu, charsmax(menu), "%s", player_name)
				else
					formatex(menu, charsmax(menu), "\d%s", player_name)
			}
		}
		
		// Add player
		buffer[0] = player
		buffer[1] = 0
		menu_additem(menuid, menu, buffer)
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "%L", id, "MENU_BACK")
	menu_setprop(menuid, MPROP_BACKNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_NEXT")
	menu_setprop(menuid, MPROP_NEXTNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_PLAYERS = min(MENU_PAGE_PLAYERS, menu_pages(menuid)-1)
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	menu_display(id, menuid, MENU_PAGE_PLAYERS)
}

// Game Mode List Menu
show_menu_game_mode_list(id)
{
	static menu[128], transkey[64]
	new menuid, index, itemdata[2], game_mode_count = zp_gamemodes_get_count()
	
	// Title
	formatex(menu, charsmax(menu), "%L:\r", id, "MENU_INFO4")
	menuid = menu_create(menu, "menu_game_mode_list")
	
	// Item List
	for (index = 0; index < game_mode_count; index++)
	{
		// Add Game Mode Name
		zp_gamemodes_get_name(index, menu, charsmax(menu))
		
		// ML support for mode name
		formatex(transkey, charsmax(transkey), "MODENAME %s", menu)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(menu, charsmax(menu), "%L", id, transkey)
		
		itemdata[0] = index
		itemdata[1] = 0
		menu_additem(menuid, menu, itemdata)
	}
	
	// No game modes to display?
	if (menu_items(menuid) <= 0)
	{
		menu_destroy(menuid)
		return;
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "%L", id, "MENU_BACK")
	menu_setprop(menuid, MPROP_BACKNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_NEXT")
	menu_setprop(menuid, MPROP_NEXTNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_GAME_MODES = min(MENU_PAGE_GAME_MODES, menu_pages(menuid)-1)
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	menu_display(id, menuid, MENU_PAGE_GAME_MODES)
}

// Admin Menu
public menu_admin(id, key)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	new userflags = get_user_flags(id)
	
	switch (key)
	{
		case ACTION_INFECT_CURE: // Infect/Cure command
		{
			if (userflags & (read_flags(g_access_make_zombie) | read_flags(g_access_make_human)))
			{
				// Show player list for admin to pick a target
				PL_ACTION = ACTION_INFECT_CURE
				show_menu_player_list(id)
			}
			else
			{
				zp_colored_print(id, "%L", id, "CMD_NOT_ACCESS")
				show_menu_admin(id)
			}
		}
		case ACTION_MAKE_NEMESIS: // Nemesis command
		{
			if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && (userflags & read_flags(g_access_make_nemesis)))
			{
				// Show player list for admin to pick a target
				PL_ACTION = ACTION_MAKE_NEMESIS
				show_menu_player_list(id)
			}
			else
			{
				zp_colored_print(id, "%L", id, "CMD_NOT_ACCESS")
				show_menu_admin(id)
			}
		}
		case ACTION_MAKE_SURVIVOR: // Survivor command
		{
			if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && (userflags & read_flags(g_access_make_survivor)))
			{
				// Show player list for admin to pick a target
				PL_ACTION = ACTION_MAKE_SURVIVOR
				show_menu_player_list(id)
			}
			else
			{
				zp_colored_print(id, "%L", id, "CMD_NOT_ACCESS")
				show_menu_admin(id)
			}
		}
		case ACTION_RESPAWN_PLAYER: // Respawn command
		{
			if (userflags & read_flags(g_access_respawn_players))
			{
				// Show player list for admin to pick a target
				PL_ACTION = ACTION_RESPAWN_PLAYER
				show_menu_player_list(id)
			}
			else
			{
				zp_colored_print(id, "%L", id, "CMD_NOT_ACCESS")
				show_menu_admin(id)
			}
		}
		case ACTION_START_GAME_MODE: // Start Game Mode command
		{
			if (userflags & read_flags(g_access_start_game_mode))
				show_menu_game_mode_list(id)
			else
			{
				zp_colored_print(id, "%L", id, "CMD_NOT_ACCESS")
				show_menu_admin(id)
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

// Player List Menu
public menu_player_list(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		MENU_PAGE_PLAYERS = 0
		menu_destroy(menuid)
		show_menu_admin(id)
		return PLUGIN_HANDLED;
	}
	
	// Remember player's menu page
	MENU_PAGE_PLAYERS = item / 7
	
	// Retrieve player id
	new buffer[2], dummy, player
	menu_item_getinfo(menuid, item, dummy, buffer, charsmax(buffer), _, _, dummy)
	player = buffer[0]
	
	// Perform action on player
	
	// Get admin flags
	new userflags = get_user_flags(id)
	
	// Make sure it's still connected
	if (is_user_connected(player))
	{
		// Perform the right action if allowed
		switch (PL_ACTION)
		{
			case ACTION_INFECT_CURE: // Infect/Cure command
			{
				if (zp_core_is_zombie(player))
				{
					if ((userflags & read_flags(g_access_make_human)) && is_user_alive(player))
						zp_admin_commands_human(id, player)
					else
						zp_colored_print(id, "%L", id, "CMD_NOT")
				}
				else
				{
					if ((userflags & read_flags(g_access_make_zombie)) && is_user_alive(player))
						zp_admin_commands_zombie(id, player)
					else
						zp_colored_print(id, "%L", id, "CMD_NOT")
				}
			}
			case ACTION_MAKE_NEMESIS: // Nemesis command
			{
				if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && (userflags & read_flags(g_access_make_nemesis)) && is_user_alive(player) && !zp_class_nemesis_get(player))
					zp_admin_commands_nemesis(id, player)
				else
					zp_colored_print(id, "%L", id, "CMD_NOT")
			}
			case ACTION_MAKE_SURVIVOR: // Survivor command
			{
				if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && (userflags & read_flags(g_access_make_survivor)) && is_user_alive(player) && !zp_class_survivor_get(player))
					zp_admin_commands_survivor(id, player)
				else
					zp_colored_print(id, "%L", id, "CMD_NOT")
			}
			case ACTION_RESPAWN_PLAYER: // Respawn command
			{
				if ((userflags & read_flags(g_access_respawn_players)) && allowed_respawn(player))
					zp_admin_commands_respawn(id, player)
				else
					zp_colored_print(id, "%L", id, "CMD_NOT")
			}
		}
	}
	else
		zp_colored_print(id, "%L", id, "CMD_NOT")
	
	menu_destroy(menuid)
	show_menu_player_list(id)
	return PLUGIN_HANDLED;
}

// Game Mode List Menu
public menu_game_mode_list(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		MENU_PAGE_GAME_MODES = 0
		menu_destroy(menuid)
		show_menu_admin(id)
		return PLUGIN_HANDLED;
	}
	
	// Remember game modes menu page
	MENU_PAGE_GAME_MODES = item / 7
	
	// Retrieve game mode id
	new itemdata[2], dummy, game_mode_id
	menu_item_getinfo(menuid, item, dummy, itemdata, charsmax(itemdata), _, _, dummy)
	game_mode_id = itemdata[0]
	
	// Attempt to start game mode
	zp_admin_commands_start_mode(id, game_mode_id)
	
	menu_destroy(menuid)
	show_menu_game_mode_list(id)
	return PLUGIN_HANDLED;
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
