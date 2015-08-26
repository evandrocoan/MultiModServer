/*================================================================================
	
	----------------------
	-*- [ZP] Main Menu -*-
	----------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#define LIBRARY_BUYMENUS "zp50_buy_menus"
#include <zp50_buy_menus>
#define LIBRARY_ZOMBIECLASSES "zp50_class_zombie"
#include <zp50_class_zombie>
#define LIBRARY_HUMANCLASSES "zp50_class_human"
#include <zp50_class_human>
#define LIBRARY_ITEMS "zp50_items"
#include <zp50_items>
#define LIBRARY_ADMIN_MENU "zp50_admin_menu"
#include <zp50_admin_menu>
#define LIBRARY_RANDOMSPAWN "zp50_random_spawn"
#include <zp50_random_spawn>
#include <zp50_colorchat>

#define TASK_WELCOMEMSG 100

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

// Menu keys
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_ChooseTeamOverrideActive

new cvar_buy_custom_primary, cvar_buy_custom_secondary, cvar_buy_custom_grenades
new cvar_random_spawning

public plugin_init()
{
	register_plugin("[ZP] Main Menu", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	register_clcmd("chooseteam", "clcmd_chooseteam")
	
	register_clcmd("say /zpmenu", "clcmd_zpmenu")
	register_clcmd("say zpmenu", "clcmd_zpmenu")
	
	// Menus
	register_menu("Main Menu", KEYSMENU, "menu_main")
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_BUYMENUS) || equal(module, LIBRARY_ZOMBIECLASSES) || equal(module, LIBRARY_HUMANCLASSES) || equal(module, LIBRARY_ITEMS) || equal(module, LIBRARY_ADMIN_MENU) || equal(module, LIBRARY_RANDOMSPAWN))
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
	cvar_buy_custom_primary = get_cvar_pointer("zp_buy_custom_primary")
	cvar_buy_custom_secondary = get_cvar_pointer("zp_buy_custom_secondary")
	cvar_buy_custom_grenades = get_cvar_pointer("zp_buy_custom_grenades")
	cvar_random_spawning = get_cvar_pointer("zp_random_spawning_csdm")
}

// Event Round Start
public event_round_start()
{
	// Show main menu message
	remove_task(TASK_WELCOMEMSG)
	set_task(2.0, "task_welcome_msg", TASK_WELCOMEMSG)
}

// Welcome Message Task
public task_welcome_msg()
{
	zp_colored_print(0, "==== ^x04Zombie Plague %s^x01 ====", ZP_VERSION_STR_LONG)
	zp_colored_print(0, "%L", LANG_PLAYER, "NOTICE_INFO1")
}

public clcmd_chooseteam(id)
{
	if (flag_get(g_ChooseTeamOverrideActive, id))
	{
		show_menu_main(id)
		return PLUGIN_HANDLED;
	}
	
	flag_set(g_ChooseTeamOverrideActive, id)
	return PLUGIN_CONTINUE;
}

public clcmd_zpmenu(id)
{
	show_menu_main(id)
}

public client_putinserver(id)
{
	flag_set(g_ChooseTeamOverrideActive, id)
}

// Main Menu
show_menu_main(id)
{
	static menu[250]
	new len
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\yZombie Plague %s^n^n", ZP_VERSION_STR_LONG)
	
	// 1. Buy menu
	if (LibraryExists(LIBRARY_BUYMENUS, LibType_Library) && (get_pcvar_num(cvar_buy_custom_primary)
	|| get_pcvar_num(cvar_buy_custom_secondary) || get_pcvar_num(cvar_buy_custom_grenades)) && is_user_alive(id))
		len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "MENU_BUY")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d1. %L^n", id, "MENU_BUY")
	
	// 2. Extra Items
	if (LibraryExists(LIBRARY_ITEMS, LibType_Library) && is_user_alive(id))
		len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L^n", id, "MENU_EXTRABUY")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d2. %L^n", id, "MENU_EXTRABUY")
	
	// 3. Zombie class
	if (LibraryExists(LIBRARY_ZOMBIECLASSES, LibType_Library) && zp_class_zombie_get_count() > 1)
		len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L^n", id, "MENU_ZCLASS")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d3. %L^n", id, "MENU_ZCLASS")
	
	// 4. Human class
	if (LibraryExists(LIBRARY_HUMANCLASSES, LibType_Library) && zp_class_human_get_count() > 1)
		len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L^n", id, "MENU_HCLASS")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d4. %L^n", id, "MENU_HCLASS")
	
	// 5. Unstuck
	if (LibraryExists(LIBRARY_RANDOMSPAWN, LibType_Library) && is_user_alive(id))
		len += formatex(menu[len], charsmax(menu) - len, "\r5.\w %L^n", id, "MENU_UNSTUCK")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d5. %L^n", id, "MENU_UNSTUCK")
	
	// 6. Help
	len += formatex(menu[len], charsmax(menu) - len, "\r6.\w %L^n^n", id, "MENU_INFO")
	
	// 7. Choose Team
	len += formatex(menu[len], charsmax(menu) - len, "\r7.\w %L^n^n", id, "MENU_CHOOSE_TEAM")
	
	// 9. Admin menu
	if (LibraryExists(LIBRARY_ADMIN_MENU, LibType_Library) && is_user_admin(id))
		len += formatex(menu[len], charsmax(menu) - len, "\r9.\w %L", id, "MENU_ADMIN")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d9. %L", id, "MENU_ADMIN")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w %L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "Main Menu")
}

// Main Menu
public menu_main(id, key)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	switch (key)
	{
		case 0: // Buy Menu
		{
			// Custom buy menus enabled?
			if (LibraryExists(LIBRARY_BUYMENUS, LibType_Library) && (get_pcvar_num(cvar_buy_custom_primary)
			|| get_pcvar_num(cvar_buy_custom_secondary) || get_pcvar_num(cvar_buy_custom_grenades)))
			{
				// Check whether the player is able to buy anything
				if (is_user_alive(id))
					zp_buy_menus_show(id)
				else
					zp_colored_print(id, "%L", id, "CANT_BUY_WEAPONS_DEAD")
			}
			else
				zp_colored_print(id, "%L", id, "CUSTOM_BUY_DISABLED")
		}
		case 1: // Extra Items
		{
			// Items enabled?
			if (LibraryExists(LIBRARY_ITEMS, LibType_Library))
			{
				// Check whether the player is able to buy anything
				if (is_user_alive(id))
					zp_items_show_menu(id)
				else
					zp_colored_print(id, "%L", id, "CANT_BUY_ITEMS_DEAD")
			}
			else
				zp_colored_print(id, "%L", id, "CMD_NOT_EXTRAS")
		}
		case 2: // Zombie Classes
		{
			if (LibraryExists(LIBRARY_ZOMBIECLASSES, LibType_Library) && zp_class_zombie_get_count() > 1)
				zp_class_zombie_show_menu(id)
			else
				zp_colored_print(id, "%L", id, "CMD_NOT_ZCLASSES")
		}
		case 3: // Human Classes
		{
			if (LibraryExists(LIBRARY_HUMANCLASSES, LibType_Library) && zp_class_human_get_count() > 1)
				zp_class_human_show_menu(id)
			else
				zp_colored_print(id, "%L", id, "CMD_NOT_HCLASSES")
		}
		case 4:
		{
			// Check if player is stuck
			if (LibraryExists(LIBRARY_RANDOMSPAWN, LibType_Library) && is_user_alive(id))
			{
				if (is_player_stuck(id))
				{
					// Move to an initial spawn
					if (get_pcvar_num(cvar_random_spawning))
						zp_random_spawn_do(id, true) // random spawn (including CSDM)
					else
						zp_random_spawn_do(id, false) // regular spawn
				}
				else
					zp_colored_print(id, "%L", id, "CMD_NOT_STUCK")
			}
			else
				zp_colored_print(id, "%L", id, "CMD_NOT")
		}
		case 5: // Help Menu
		{
			show_help(id)
		}
		case 6: // Menu override
		{
			flag_unset(g_ChooseTeamOverrideActive, id)
			client_cmd(id, "chooseteam")
		}
		case 8: // Admin Menu
		{
			if (LibraryExists(LIBRARY_ADMIN_MENU, LibType_Library) && is_user_admin(id))
				zp_admin_menu_show(id)
			else
				zp_colored_print(id, "%L", id, "NO_ADMIN_MENU")
		}
	}
	
	return PLUGIN_HANDLED;
}

// Help MOTD
show_help(id)
{
	static motd[1024]
	new len
	
	len += formatex(motd[len], charsmax(motd) - len, "%L", id, "MOTD_INFO11", "Zombie Plague Mod", ZP_VERSION_STR_LONG, "ZP Dev Team")
	len += formatex(motd[len], charsmax(motd) - len, "%L", id, "MOTD_INFO12")
	
	show_motd(id, motd)
}

// Check if a player is stuck (credits to VEN)
stock is_player_stuck(id)
{
	static Float:originF[3]
	pev(id, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}