/*================================================================================
	
	-----------------------------
	-*- [ZP] Custom Buy Menus -*-
	-----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <zp50_core>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#include <zp50_colorchat>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Buy Menu: Primary and Secondary Weapons
new const primary_items[][] = { "weapon_galil", "weapon_famas", "weapon_m4a1", "weapon_ak47", "weapon_sg552", "weapon_aug", "weapon_scout",
				"weapon_m3", "weapon_xm1014", "weapon_tmp", "weapon_mac10", "weapon_ump45", "weapon_mp5navy", "weapon_p90" }
new const secondary_items[][] = { "weapon_glock18", "weapon_usp", "weapon_p228", "weapon_deagle", "weapon_fiveseven", "weapon_elite" }

// Buy Menu: Grenades
new const grenades_items[][] = { "weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade" }

#define WEAPONITEM_MAX_LENGTH 32

new Array:g_primary_items
new Array:g_secondary_items
new Array:g_grenades_items

// Primary and Secondary Weapon Names
new const WEAPONNAMES[][] = { "", "P228 Compact", "", "Schmidt Scout", "HE Grenade", "XM1014 M4", "", "Ingram MAC-10", "Steyr AUG A1",
			"Smoke Grenade", "Dual Elite Berettas", "FiveseveN", "UMP 45", "SG-550 Auto-Sniper", "IMI Galil", "Famas",
			"USP .45 ACP Tactical", "Glock 18C", "AWP Magnum Sniper", "MP5 Navy", "M249 Para Machinegun",
			"M3 Super 90", "M4A1 Carbine", "Schmidt TMP", "G3SG1 Auto-Sniper", "Flashbang", "Desert Eagle .50 AE",
			"SG-552 Commando", "AK-47 Kalashnikov", "", "ES P90" }

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }

// Ammo IDs for weapons
new const AMMOID[] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10,
			1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }

// Ammo Type Names for weapons
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
			"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }

// HACK: pev_ field used to store additional ammo on weapons
const PEV_ADDITIONAL_AMMO = pev_iuser1

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const GRENADES_WEAPONS_BIT_SUM = (1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)

#define PRIMARY_ONLY 1
#define SECONDARY_ONLY 2
#define PRIMARY_AND_SECONDARY 3
#define GRENADES_ONLY 4

// For weapon buy menu handlers
#define WPN_STARTID g_MenuData[id][0]
#define WPN_MAXIDS ArraySize(g_primary_items)
#define WPN_SELECTION (g_MenuData[id][0]+key)
#define WPN_AUTO_ON g_MenuData[id][1]
#define WPN_AUTO_PRI g_MenuData[id][2]
#define WPN_AUTO_SEC g_MenuData[id][3]
#define WPN_AUTO_GREN g_MenuData[id][4]

#define MAXPLAYERS 32

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

// Menu selections
const MENU_KEY_AUTOSELECT = 7
const MENU_KEY_BACK = 7
const MENU_KEY_NEXT = 8
const MENU_KEY_EXIT = 9

// Menu keys
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

// CS Player CBase Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_ACTIVE_ITEM = 373

new g_CanBuyPrimary
new g_CanBuySecondary
new g_CanBuyGrenades
new g_MenuData[MAXPLAYERS+1][5]
new Float:g_BuyTimeStart[MAXPLAYERS+1]

new cvar_random_primary, cvar_random_secondary, cvar_random_grenades
new cvar_buy_custom_time, cvar_buy_custom_primary, cvar_buy_custom_secondary, cvar_buy_custom_grenades
new cvar_give_all_grenades

public plugin_init()
{
	register_plugin("[ZP] Custom Buy Menus", ZP_VERSION_STRING, "ZP Dev Team")
	
	cvar_random_primary = register_cvar("zp_random_primary", "0")
	cvar_random_secondary = register_cvar("zp_random_secondary", "0")
	cvar_random_grenades = register_cvar("zp_random_grenades", "0")
	
	cvar_buy_custom_time = register_cvar("zp_buy_custom_time", "15")
	cvar_buy_custom_primary = register_cvar("zp_buy_custom_primary", "1")
	cvar_buy_custom_secondary = register_cvar("zp_buy_custom_secondary", "1")
	cvar_buy_custom_grenades = register_cvar("zp_buy_custom_grenades", "0")
	
	cvar_give_all_grenades = register_cvar("zp_give_all_grenades", "1")
	
	register_clcmd("say /buy", "clcmd_buy")
	register_clcmd("say buy", "clcmd_buy")
	register_clcmd("say /guns", "clcmd_buy")
	register_clcmd("say guns", "clcmd_buy")
	
	// Menus
	register_menu("Buy Menu Primary", KEYSMENU, "menu_buy_primary")
	register_menu("Buy Menu Secondary", KEYSMENU, "menu_buy_secondary")
	register_menu("Buy Menu Grenades", KEYSMENU, "menu_buy_grenades")
}

public plugin_precache()
{
	// Initialize arrays
	g_primary_items = ArrayCreate(WEAPONITEM_MAX_LENGTH, 1)
	g_secondary_items = ArrayCreate(WEAPONITEM_MAX_LENGTH, 1)
	g_grenades_items = ArrayCreate(WEAPONITEM_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Buy Menu Weapons", "PRIMARY", g_primary_items)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Buy Menu Weapons", "SECONDARY", g_secondary_items)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Buy Menu Weapons", "GRENADES", g_grenades_items)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_primary_items) == 0)
	{
		for (index = 0; index < sizeof primary_items; index++)
			ArrayPushString(g_primary_items, primary_items[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Buy Menu Weapons", "PRIMARY", g_primary_items)
	}
	if (ArraySize(g_secondary_items) == 0)
	{
		for (index = 0; index < sizeof secondary_items; index++)
			ArrayPushString(g_secondary_items, secondary_items[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Buy Menu Weapons", "SECONDARY", g_secondary_items)
	}
	if (ArraySize(g_grenades_items) == 0)
	{
		for (index = 0; index < sizeof grenades_items; index++)
			ArrayPushString(g_grenades_items, grenades_items[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Buy Menu Weapons", "GRENADES", g_grenades_items)
	}
}

public plugin_natives()
{
	register_library("zp50_buy_menus")
	register_native("zp_buy_menus_show", "native_buy_menus_show")
	
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

public native_buy_menus_show(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	clcmd_buy(id)
	return true;
}

public clcmd_buy(id)
{
	if (WPN_AUTO_ON)
	{
		zp_colored_print(id, "%L", id, "BUY_ENABLED")
		WPN_AUTO_ON = 0
	}
	
	// Player dead or zombie
	if (!is_user_alive(id) || zp_core_is_zombie(id))
		return;
	
	show_available_buy_menus(id)
}

public client_disconnect(id)
{
	WPN_AUTO_ON = 0
	WPN_STARTID = 0
}

public zp_fw_core_cure_post(id, attacker)
{
	// Buyzone time starts when player is set to human
	g_BuyTimeStart[id] = get_gametime()
	
	// Task added so that previous weapons are dropped on spawn event (bugfix)
	remove_task(id)
	set_task(0.1, "human_weapons", id)
}

public human_weapons(id)
{
	// Player dead or zombie
	if (!is_user_alive(id) || zp_core_is_zombie(id))
		return;
	
	// Survivor automatically gets his own weapon
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
	{
		flag_unset(g_CanBuyPrimary, id)
		flag_unset(g_CanBuySecondary, id)
		flag_unset(g_CanBuyGrenades, id)
		return;
	}
	
	// Random weapons settings
	if (get_pcvar_num(cvar_random_primary))
		buy_primary_weapon(id, random_num(0, ArraySize(g_primary_items) - 1))
	if (get_pcvar_num(cvar_random_secondary))
		buy_secondary_weapon(id, random_num(0, ArraySize(g_secondary_items) - 1))
	if (get_pcvar_num(cvar_random_grenades))
		buy_grenades(id, random_num(0, ArraySize(g_grenades_items) - 1))
	
	// Custom buy menus
	if (get_pcvar_num(cvar_buy_custom_primary))
	{
		flag_set(g_CanBuyPrimary, id)
		
		if (is_user_bot(id))
			buy_primary_weapon(id, random_num(0, ArraySize(g_primary_items) - 1))
		else if (WPN_AUTO_ON)
			buy_primary_weapon(id, WPN_AUTO_PRI)
	}
	if (get_pcvar_num(cvar_buy_custom_secondary))
	{
		flag_set(g_CanBuySecondary, id)
		
		if (is_user_bot(id))
			buy_secondary_weapon(id, random_num(0, ArraySize(g_secondary_items) - 1))
		else if (WPN_AUTO_ON)
			buy_secondary_weapon(id, WPN_AUTO_SEC)
	}
	if (get_pcvar_num(cvar_buy_custom_grenades))
	{
		flag_set(g_CanBuyGrenades, id)
		
		if (is_user_bot(id))
			buy_grenades(id, random_num(0, ArraySize(g_grenades_items) - 1))
		else if (WPN_AUTO_ON)
			buy_grenades(id, WPN_AUTO_GREN)
	}
	
	// Open available buy menus
	show_available_buy_menus(id)
	
	// Automatically give all grenades?
	if (get_pcvar_num(cvar_give_all_grenades))
	{
		// Strip first
		strip_weapons(id, GRENADES_ONLY)
		new index
		for (index = 0; index < ArraySize(g_grenades_items); index++)
			buy_grenades(id, index)
	}
}

// Shows the next available buy menu
show_available_buy_menus(id)
{
	if (flag_get(g_CanBuyPrimary, id))
		show_menu_buy_primary(id)
	else if (flag_get(g_CanBuySecondary, id))
		show_menu_buy_secondary(id)
	else if (flag_get(g_CanBuyGrenades, id))
		show_menu_buy_grenades(id)
}

// Buy Menu Primary
show_menu_buy_primary(id)
{
	new menu_time = floatround(g_BuyTimeStart[id] + get_pcvar_float(cvar_buy_custom_time) - get_gametime())
	if (menu_time <= 0)
	{
		zp_colored_print(id, "%L", id, "BUY_MENU_TIME_EXPIRED")
		return;
	}
	
	static menu[300], weapon_name[32]
	new len, index, maxloops = min(WPN_STARTID+7, WPN_MAXIDS)
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\y%L \r[%d-%d]^n^n", id, "MENU_BUY1_TITLE", WPN_STARTID+1, min(WPN_STARTID+7, WPN_MAXIDS))
	
	// 1-7. Weapon List
	for (index = WPN_STARTID; index < maxloops; index++)
	{
		ArrayGetString(g_primary_items, index, weapon_name, charsmax(weapon_name))
		len += formatex(menu[len], charsmax(menu) - len, "\r%d.\w %s^n", index-WPN_STARTID+1, WEAPONNAMES[get_weaponid(weapon_name)])
	}
	
	// 8. Auto Select
	len += formatex(menu[len], charsmax(menu) - len, "^n\r8.\w %L \y[%L]", id, "MENU_AUTOSELECT", id, (WPN_AUTO_ON) ? "MOTD_ENABLED" : "MOTD_DISABLED")
	
	// 9. Next/Back - 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r9.\w %L/%L^n^n\r0.\w %L", id, "MENU_NEXT", id, "MENU_BACK", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, menu_time, "Buy Menu Primary")
}

// Buy Menu Secondary
show_menu_buy_secondary(id)
{
	new menu_time = floatround(g_BuyTimeStart[id] + get_pcvar_float(cvar_buy_custom_time) - get_gametime())
	if (menu_time <= 0)
	{
		zp_colored_print(id, "%L", id, "BUY_MENU_TIME_EXPIRED")
		return;
	}
	
	static menu[250], weapon_name[32]
	new len, index, maxloops = ArraySize(g_secondary_items)
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\y%L^n", id, "MENU_BUY2_TITLE")
	
	// 1-6. Weapon List
	for (index = 0; index < maxloops; index++)
	{
		ArrayGetString(g_secondary_items, index, weapon_name, charsmax(weapon_name))
		len += formatex(menu[len], charsmax(menu) - len, "^n\r%d.\w %s", index+1, WEAPONNAMES[get_weaponid(weapon_name)])
	}
	
	// 8. Auto Select
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r8.\w %L \y[%L]", id, "MENU_AUTOSELECT", id, (WPN_AUTO_ON) ? "MOTD_ENABLED" : "MOTD_DISABLED")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w %L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, menu_time, "Buy Menu Secondary")
}

// Buy Menu Grenades
show_menu_buy_grenades(id)
{
	new menu_time = floatround(g_BuyTimeStart[id] + get_pcvar_float(cvar_buy_custom_time) - get_gametime())
	if (menu_time <= 0)
	{
		zp_colored_print(id, "%L", id, "BUY_MENU_TIME_EXPIRED")
		return;
	}
	
	static menu[250], weapon_name[32]
	new len, index, maxloops = ArraySize(g_grenades_items)
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\y%L^n", id, "MENU_BUY3_TITLE")
	
	// 1-3. Item List
	for (index = 0; index < maxloops; index++)
	{
		ArrayGetString(g_grenades_items, index, weapon_name, charsmax(weapon_name))
		len += formatex(menu[len], charsmax(menu) - len, "^n\r%d.\w %s", index+1, WEAPONNAMES[get_weaponid(weapon_name)])
	}
	
	// 8. Auto Select
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r8.\w %L \y[%L]", id, "MENU_AUTOSELECT", id, (WPN_AUTO_ON) ? "MOTD_ENABLED" : "MOTD_DISABLED")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w %L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, menu_time, "Buy Menu Grenades")
}

// Buy Menu Primary
public menu_buy_primary(id, key)
{
	// Player dead or zombie or already bought primary
	if (!is_user_alive(id) || zp_core_is_zombie(id) || !flag_get(g_CanBuyPrimary, id))
		return PLUGIN_HANDLED;
	
	// Special keys / weapon list exceeded
	if (key >= MENU_KEY_AUTOSELECT || WPN_SELECTION >= WPN_MAXIDS)
	{
		switch (key)
		{
			case MENU_KEY_AUTOSELECT: // toggle auto select
			{
				WPN_AUTO_ON = 1 - WPN_AUTO_ON
			}
			case MENU_KEY_NEXT: // next/back
			{
				if (WPN_STARTID+7 < WPN_MAXIDS)
					WPN_STARTID += 7
				else
					WPN_STARTID = 0
			}
			case MENU_KEY_EXIT: // exit
			{
				return PLUGIN_HANDLED;
			}
		}
		
		// Show buy menu again
		show_menu_buy_primary(id)
		return PLUGIN_HANDLED;
	}
	
	// Store selected weapon id
	WPN_AUTO_PRI = WPN_SELECTION
	
	// Buy primary weapon
	buy_primary_weapon(id, WPN_AUTO_PRI)
	
	// Show next buy menu
	show_available_buy_menus(id)
	
	return PLUGIN_HANDLED;
}

// Buy Primary Weapon
buy_primary_weapon(id, selection)
{
	// Drop previous primary weapon
	drop_weapons(id, PRIMARY_ONLY)
	
	// Get weapon's id
	static weapon_name[32]
	ArrayGetString(g_primary_items, selection, weapon_name, charsmax(weapon_name))
	new weaponid = get_weaponid(weapon_name)
	
	// Give the new weapon and full ammo
	give_item(id, weapon_name)
	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
	
	// Primary bought
	flag_unset(g_CanBuyPrimary, id)
}

// Buy Menu Secondary
public menu_buy_secondary(id, key)
{
	// Player dead or zombie or already bought secondary
	if (!is_user_alive(id) || zp_core_is_zombie(id) || !flag_get(g_CanBuySecondary, id))
		return PLUGIN_HANDLED;
	
	// Special keys / weapon list exceeded
	if (key >= ArraySize(g_secondary_items))
	{
		// Toggle autoselect
		if (key == MENU_KEY_AUTOSELECT)
			WPN_AUTO_ON = 1 - WPN_AUTO_ON
		
		// Reshow menu unless user exited
		if (key != MENU_KEY_EXIT)
			show_menu_buy_secondary(id)
		
		return PLUGIN_HANDLED;
	}
	
	// Store selected weapon id
	WPN_AUTO_SEC = key
	
	// Buy secondary weapon
	buy_secondary_weapon(id, key)
	
	// Show next buy menu
	show_available_buy_menus(id)
	
	return PLUGIN_HANDLED;
}

// Buy Secondary Weapon
buy_secondary_weapon(id, selection)
{
	// Drop previous secondary weapon
	drop_weapons(id, SECONDARY_ONLY)
	
	// Get weapon's id
	static weapon_name[32]
	ArrayGetString(g_secondary_items, selection, weapon_name, charsmax(weapon_name))
	new weaponid = get_weaponid(weapon_name)
	
	// Give the new weapon and full ammo
	give_item(id, weapon_name)
	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
	
	// Secondary bought
	flag_unset(g_CanBuySecondary, id)
}

// Buy Menu Grenades
public menu_buy_grenades(id, key)
{
	// Player dead or zombie or already bought grenades
	if (!is_user_alive(id) || zp_core_is_zombie(id) || !flag_get(g_CanBuyGrenades, id))
		return PLUGIN_HANDLED;
	
	// Special keys / weapon list exceeded
	if (key >= ArraySize(g_grenades_items))
	{
		// Toggle autoselect
		if (key == MENU_KEY_AUTOSELECT)
			WPN_AUTO_ON = 1 - WPN_AUTO_ON
		
		// Reshow menu unless user exited
		if (key != MENU_KEY_EXIT)
			show_menu_buy_grenades(id)
		
		return PLUGIN_HANDLED;
	}
	
	// Store selected grenade
	WPN_AUTO_GREN = key
	
	// Buy selected grenade
	buy_grenades(id, key)
	
	return PLUGIN_HANDLED;
}

// Buy Grenades
buy_grenades(id, selection)
{
	// Give the new weapon
	static weapon_name[32]
	ArrayGetString(g_grenades_items, selection, weapon_name, charsmax(weapon_name))
	give_item(id, weapon_name)
	
	// Grenades bought
	flag_unset(g_CanBuyGrenades, id)
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