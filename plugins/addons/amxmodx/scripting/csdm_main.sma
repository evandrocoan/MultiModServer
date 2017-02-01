/**
 * csdm_main.sma
 * Allows for Counter-Strike to be played as DeathMatch.
 *
 * CSDM Main - Main plugin to communicate with module
 *
 * (C)2003-2006 David "BAILOPAN" Anderson
 *
 *  Give credit where due.
 *  Share the source - it sets you free
 *  http://www.opensource.org/
 *  http://www.gnu.org/
 */
 
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csdm>

new D_PLUGIN[]	= "CSDM Main"
new D_ACCESS	= ADMIN_MAP

#define CSDM_OPTIONS_TOTAL		2

new bool:g_StripWeapons = true
new bool:g_RemoveBomb = true
new g_StayTime
new g_drop_fwd
new g_options[CSDM_OPTIONS_TOTAL]

//new g_MenuPages[33]
new g_MainMenu = -1

public plugin_natives()
{
	register_native("csdm_main_menu", "native_main_menu")
	register_native("csdm_set_mainoption", "__csdm_allow_option")
	register_native("csdm_fwd_drop", "__csdm_fwd_drop")
	register_library("csdm_main")
}

public native_main_menu(id, num)
{
	return g_MainMenu
}

public __csdm_allow_option(id, num)
{
	new option = get_param(1)
	
	if (option <= 0 || option >= CSDM_OPTIONS_TOTAL)
	{
		log_error(AMX_ERR_NATIVE, "Invalid option number: %d", option)
		return 0
	}
	
	g_options[option] = get_param(2)
	
	return 1
}

public __csdm_fwd_drop(id, num)
{
	new id = get_param(1)
	new wp = get_param(2)
	new name[32]
	
	get_string(3, name, 31)
	
	return run_drop(id, wp, name)	
}

public csdm_Init(const version[])
{
	if (version[0] == 0)
	{
		set_fail_state("CSDM failed to load.")
		return
	}
}

public csdm_CfgInit()
{	
	csdm_reg_cfg("settings", "read_cfg")
}

public plugin_init()
{
	register_plugin(D_PLUGIN, CSDM_VERSION, "CSDM Team")
	
	register_clcmd("say respawn", "say_respawn")
	register_clcmd("say /respawn", "say_respawn")
	
	register_concmd("csdm_enable", "csdm_enable", D_ACCESS, "Enables CSDM")
	register_concmd("csdm_disable", "csdm_disable", D_ACCESS, "Disables CSDM")
	register_concmd("csdm_ctrl", "csdm_ctrl", D_ACCESS, "")
	register_concmd("csdm_reload", "csdm_reload", D_ACCESS, "Reloads CSDM Config")
	register_clcmd("csdm_menu", "csdm_menu", ADMIN_MENU, "CSDM Menu")
	register_clcmd("drop", "hook_drop")
	
	register_concmd("csdm_cache", "cacheInfo", ADMIN_MAP, "Shows cache information")
	
	AddMenuItem("CSDM Menu", "csdm_menu", D_ACCESS, D_PLUGIN)
	g_MainMenu = menu_create("CSDM Menu", "use_csdm_menu")
	
	new callback = menu_makecallback("hook_item_display")
	menu_additem(g_MainMenu, "Enable/Disable", "csdm_ctrl", D_ACCESS, callback)
	menu_additem(g_MainMenu, "Reload Config", "csdm_reload", D_ACCESS)
	
	g_drop_fwd = CreateMultiForward("csdm_HandleDrop", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
}

public cacheInfo(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
		
	new ar[6]
	csdm_cache(ar)
	
	console_print(id, "[CSDM] Free tasks: respawn=%d, findweapon=%d", ar[0], ar[5])
	console_print(id, "[CSDM] Weapon removal cache: %d total, %d live", ar[4], ar[3])
	console_print(id, "[CSDM] Live tasks: %d (%d free)", ar[2], ar[1])
	
	return PLUGIN_HANDLED
}

public hook_drop(id)
{
	if (!csdm_active())
	{
		return
	}
	
	if (!is_user_connected(id))
	{
		return
	}
	
	new wp, c, a, name[24]
	if (cs_get_user_shield(id))
	{
		//entirely different...
		wp = -1
		copy(name, 23, "weapon_shield")
	} else {
		if (read_argc() <= 1)
		{
			wp = get_user_weapon(id, c, a)
		} else {
			read_argv(1, name, 23)
			wp = getWepId(name)
		}
	}

	run_drop(id, wp, name)
}

run_drop(id, wp, const name[])
{
	new ret
	ExecuteForward(g_drop_fwd, ret, id, wp, 0)
	
	if (ret == CSDM_DROP_REMOVE)
	{
		new _name[24]
		if (name[0] == 0)
		{
			get_weaponname(wp, _name, 23)
		}
		csdm_remove_weapon(id, _name, 0, 1)
		return 1
	} else if (ret == CSDM_DROP_IGNORE) {
		return 0
	}
	
	if (g_StayTime > 20 || g_StayTime < 0)
	{
		return 0
	}
	
	if (wp)
	{
		remove_weapon(id, wp)
		return 1
	}
	
	return 0
}

public csdm_PostDeath(killer, victim, headshot, const weapon[])
{
	if (g_StayTime > 20 || g_StayTime < 0)
		return PLUGIN_CONTINUE

	new weapons[MAX_WEAPONS], num, name[24]
	new wp, slot, ret

	get_user_weapons(victim, weapons, num)

	for (new i=0; i<num; i++)
	{
		wp = weapons[i]
		slot = g_WeaponSlots[wp]

		ExecuteForward(g_drop_fwd, ret, victim, wp, 1)

		if (ret == CSDM_DROP_REMOVE)
		{
			get_weaponname(wp, name, 23)
			csdm_remove_weapon(victim, name, 0, 1)
		} else if (ret == CSDM_DROP_IGNORE) {
			continue
		} else {
			if (slot == SLOT_PRIMARY || slot == SLOT_SECONDARY || slot == SLOT_C4)
			{
				remove_weapon(victim, wp)
			}
		}
	}
	
	if (cs_get_user_shield(victim))
	{
		ExecuteForward(g_drop_fwd, ret, victim, -1, 1)
		if (ret == CSDM_DROP_REMOVE)
		{
			csdm_remove_weapon(victim, "weapon_shield", 0, 1)
		} else if (ret == CSDM_DROP_IGNORE) {
			/* do nothing */
		} else {
			remove_weapon(victim, -1)
		}
	}
	
	return PLUGIN_CONTINUE
}

public csdm_PreSpawn(player, bool:fake)
{
	//we'll just have to back out for now
	if (cs_get_user_shield(player))
	{
		return
	}
	new team = get_user_team(player)
	if (g_StripWeapons)
	{
		if (team == _TEAM_T)
		{
			if (cs_get_user_shield(player))
			{
				drop_with_shield(player, CSW_GLOCK18)
			} else {
				csdm_force_drop(player, "weapon_glock18")
			}
		} else if (team == _TEAM_CT) {
			if (cs_get_user_shield(player))
			{
				drop_with_shield(player, CSW_USP)
			} else {
				csdm_force_drop(player, "weapon_usp")
			}
		}
	}
	if (team == _TEAM_T)
	{
		if (g_RemoveBomb)
		{
			new weapons[MAX_WEAPONS], num
			get_user_weapons(player, weapons, num)
			for (new i=0; i<num; i++)
			{
				if (weapons[i] == CSW_C4)
				{
					if (cs_get_user_shield(player))
					{
						drop_with_shield(player, CSW_C4)
					} else {
						csdm_force_drop(player, "weapon_c4")
					}
					break
				}
			}
		}
	}
}

remove_weapon(id, wp)
{
	new name[24]
	
	if (wp == -1)
	{
		copy(name, 23, "weapon_shield")
	} else {
		get_weaponname(wp, name, 23)
	}

	if ((wp == CSW_C4) && g_RemoveBomb)
	{	
		csdm_remove_weapon(id, name, 0, 1)
	} else {
		if (wp != CSW_C4)
		{
			csdm_remove_weapon(id, name, g_StayTime, 1)
		}
	}
}

public hook_item_display(player, menu, item)
{
	new paccess, command[24], call
	
	menu_item_getinfo(menu, item, paccess, command, 23, _, 0, call)
	
	if (equali(command, "csdm_ctrl"))
	{
		if (!csdm_active())
		{
			menu_item_setname(menu, item, "Enable")
		} else {
			menu_item_setname(menu, item, "Disable")
		}
	}
}

public read_cfg(readAction, line[], section[])
{
	if (readAction == CFG_READ)
	{
		new setting[24], sign[3], value[32];

		parse(line, setting, 23, sign, 2, value, 31);
		
		if (equali(setting, "strip_weapons"))
		{
			g_StripWeapons = str_to_num(value) ? true : false
		} else if (equali(setting, "weapons_stay")) {
			g_StayTime = str_to_num(value)
		} else if (equali(setting, "spawnmode")) {
			new var = csdm_setstyle(value)
			if (var)
			{
				log_amx("CSDM spawn mode set to %s", value)
			} else {
				log_amx("CSDM spawn mode %s not found", value)
			}
		} else if (equali(setting, "remove_bomb")) {
			g_RemoveBomb = str_to_num(value) ? true : false
		} else if (equali(setting, "enabled")) {
			csdm_set_active(str_to_num(value))
		} else if (equali(setting, "spawn_wait_time")) {
			csdm_set_spawnwait(str_to_float(value))
		}
	}
}

public csdm_reload(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
		
	new file[33] = ""
	if (read_argc() >= 2)
	{
		read_argv(1, file, 32)
	}
		
	if (csdm_reload_cfg(file))
	{
		client_print(id, print_chat, "[CSDM] Config file reloaded.")
	} else {
		client_print(id, print_chat, "[CSDM] Unable to find config file.")
	}
		
	return PLUGIN_HANDLED
}

public csdm_menu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	menu_display(id, g_MainMenu, 0)
	
	return PLUGIN_HANDLED
}

public csdm_ctrl(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	csdm_set_active( csdm_active() ? 0 : 1 )
	client_print(id, print_chat, "CSDM active changed.")
	
	return PLUGIN_HANDLED
}

public use_csdm_menu(id, menu, item)
{
	if (item < 0)
		return PLUGIN_CONTINUE
	
	new command[24], paccess, call
	if (!menu_item_getinfo(g_MainMenu, item, paccess, command, 23, _, 0, call))
	{
		log_amx("Error: csdm_menu_item() failed (menu %d) (page %d) (item %d)", g_MainMenu, 0, item)
		return PLUGIN_HANDLED
	}
	if (paccess && !(get_user_flags(id) & paccess))
	{
		client_print(id, print_chat, "You do not have access to this menu option.")
		return PLUGIN_HANDLED
	}
	
	client_cmd(id, command)
	
	return PLUGIN_HANDLED
}

public csdm_enable(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	csdm_set_active(1)
	client_print(id, print_chat, "CSDM enabled.")
	
	return PLUGIN_HANDLED	
}

public csdm_disable(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	csdm_set_active(0)
	client_print(id, print_chat, "CSDM disabled.")
	
	return PLUGIN_HANDLED	
}

public say_respawn(id)
{
	if (g_options[CSDM_OPTION_SAYRESPAWN] == CSDM_SET_DISABLED)
	{
		client_print(id, print_chat, "[CSDM] This command is disabled!")
		return PLUGIN_HANDLED
	}
	
	if (!is_user_alive(id) && csdm_active())
	{
		new team = get_user_team(id)
		if (team == _TEAM_T || team == _TEAM_CT)
		{
			csdm_respawn(id)
		}
	}
	
	return PLUGIN_CONTINUE
}
