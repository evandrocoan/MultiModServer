/* * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * AMX Super Menu
 * Devloped/Maintained by Yami Kaitou
 * Last Update: 09/13/2008
 * 
 * Minimum Requirements
 * AMX Mod X 1.8.0
 * AMX Super 3.7
 * 
 * Credits
 * AMX Mod X Dev Team (for their plmenu.amxx plugin)
 * bmann|420 (for creating the AMX Super plugin)
 * |PJ|Shorty (for assisting me in finding out the get_concmd function)
 * If I forgot you, let me know what you did and I will add you
 * 
 * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * AMX Mod X script.
 *
 *   AMX Super Menu (amx_super_menu.sma)
 *   Copyright (C) 2008 ProjectYami (Yami Kaitou)
 *
 *   This program is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU General Public License
 *   as published by the Free Software Foundation; either version 2
 *   of the License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 *   In addition, as a special exception, the author gives permission to
 *   link the code of this program with the Half-Life Game Engine ("HL
 *   Engine") and Modified Game Libraries ("MODs") developed by Valve,
 *   L.L.C ("Valve"). You must obey the GNU General Public License in all
 *   respects for all of the code used other than the HL Engine and MODs
 *   from Valve. If you modify this file, you may extend this exception
 *   to your version of the file, but you are not obligated to do so. If
 *   you do not wish to do so, delete this exception statement from your
 *   version.
 * * * * * * * * * * * * * * * * * * * * * * * * * * */
 
#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>

#define PLUGIN	"AMX_Super Menu"
#define AUTHOR	"Yami Kaitou"
#define VERSION	"0.8.1"

enum 
{
	alltalk = 1,
	lock,
	unlock,
	extend,
	gravity,
	fire,
	flash,
	disarm,
	rocket,
	uberslap,
	revive,
	quit,
	drug,
	teamswap,
	heal,
	armor,
	stack,
	bury,
	unbury,
	slay,
	god,
	noclip,
	speed,
	unammo,
	swap,
	givemoney,
	takemoney,
	badaim,
	gag,
	ungag,
	maxvalue
}

new g_mainmenu, g_alltalkmenu, g_extendmenu, g_gravitymenu, menufunc;
new g_menuPosition[33], g_menuPlayers[33][35], g_menuPlayersNum[33], g_menuProperties[33], g_menuProperties2[33], g_menuPlayerName[33][32], g_menu[33];
new menuname[64];
new allkeys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9;
new Callback;
new g_money[33];
new Array:valueArray, accessLevel[maxvalue];

new menuCmd[][128] = 
{
	"status",
	"amx_alltalk %s",
	"amx_lock %s",
	"amx_unlock %s",
	"amx_extend %s",
	"amx_gravity %s",
	"amx_fire ^"%s^"",
	"amx_flash ^"%s^"",
	"amx_disarm ^"%s^"",
	"amx_rocket ^"%s^"",
	"amx_uberslap ^"%s^"",
	"amx_revive ^"%s^"",
	"amx_quit ^"%s^"",
	"amx_drug ^"%s^"",
	"amx_teamswap",
	"amx_heal ^"%s^" %d",
	"amx_armor ^"%s^" %d",
	"amx_stack ^"%s^" %d",
	"amx_bury ^"%s^"",
	"amx_unbury ^"%s^"",
	"amx_slay2 ^"%s^" %d",
	"amx_godmode ^"%s^" %d",
	"amx_noclip ^"%s^" %d",
	"amx_speed ^"%s^" %d",
	"amx_unammo ^"%s^" %d",
	"amx_swap ^"%s^" ^"%s^"",
	"amx_givemoney ^"%s^" %d",
	"amx_takemoney ^"%s^" %d",
	"amx_badaim ^"%s^" %d 0",
	"amx_gag ^"%s^" %s %d",
	"amx_ungag ^"%s^""
};

new cmds[][64] = 
{
	"nothing",
	"amx_alltalk",
	"amx_lock",
	"amx_unlock",
	"amx_extend",
	"amx_gravity",
	"amx_fire",
	"amx_flash",
	"amx_disarm",
	"amx_rocket",
	"amx_uberslap",
	"amx_revive",
	"amx_quit",
	"amx_drug",
	"amx_teamswap",
	"amx_heal",
	"amx_armor",
	"amx_stack",
	"amx_bury",
	"amx_unbury",
	"amx_slay2",
	"amx_godmode",
	"amx_noclip",
	"amx_speed",
	"amx_unammo",
	"amx_swap",
	"amx_givemoney",
	"amx_takemoney",
	"amx_badaim",
	"amx_gag",
	"amx_ungag"
};

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("amx_super_menu",VERSION,FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY);
	menufunc = register_cvar("supermenu_func", "0");
	register_dictionary("amx_super_menu.txt");
	register_dictionary("common.txt");
	
	// Register New Menus
	format(menuname, charsmax(menuname), "%L", LANG_PLAYER, "AMXSUPER_MENU0");
	g_mainmenu = menu_create(menuname, "mainMenu");
	format(menuname, charsmax(menuname), "%L", LANG_PLAYER, "AMXSUPER_MENU1");
	g_alltalkmenu = menu_create(menuname, "alltalkMenu");
	format(menuname, charsmax(menuname), "%L", LANG_PLAYER, "AMXSUPER_MENU4");
	g_extendmenu = menu_create(menuname, "extendMenu");
	format(menuname, charsmax(menuname), "%L", LANG_PLAYER, "AMXSUPER_MENU5");
	g_gravitymenu = menu_create(menuname, "gravityMenu");
	
	// Register Callbacks
	Callback = menu_makecallback("menu_callback");	
	
	// Register Old Menus
	register_menucmd(register_menuid("Lock Menu"), allkeys, "lockMenu");
	register_menucmd(register_menuid("Player1 Menu"), allkeys, "player1Menu");
	register_menucmd(register_menuid("Player2 Menu"), allkeys, "player2Menu");
	register_menucmd(register_menuid("Gag Menu"), allkeys, "gagMenu");
	
	register_clcmd("say", "handle_say");
	register_clcmd("say_team", "handle_say");
	register_concmd("supermenu", "handle_cmd", ADMIN_MENU, " - Bring up the menu for AMX_Super");
	register_concmd("amx_supermenu", "handle_cmd", ADMIN_MENU, " - Bring up the menu for AMX_Super");
	register_concmd("supermenu_edit", "handle_cmd", ADMIN_MENU, " - Allows you to edit the values the menu displays");
	register_concmd("amx_supermenu_edit", "handle_cmd", ADMIN_MENU, " - Allows you to edit the values the menu displays");
	
	arrayset(accessLevel, -2, maxvalue);
	valueArray = ArrayCreate(1, maxvalue);
	
}

public plugin_cfg()
{
	new index = 0, cmd[64], flags, info[128], flag = 52428799, k;
	new max = get_concmdsnum(flag);
	
	while (index <= max)
	{
		get_concmd(index++, cmd, charsmax(cmd), flags, info, charsmax(info), flag);
		
		k = 1;
		while (k < maxvalue && !equal(cmd, cmds[k])) k++;
		
		if (k != maxvalue) accessLevel[k] = flags;
	}
	
	for (new k = 0; k <= maxvalue; k++)
		ArrayPushCell(Array:valueArray, 0);
	
	build_arrays();
	build_menu();
	
	set_task(1.1, "addToMenuFront");
}

public addToMenuFront()
{
	new PluginFileName[64];
	
	get_plugin(-1, PluginFileName, charsmax(PluginFileName));
	new cvarflags;
	new cmd[32];

	if (strcmp(cmd, "amx_supermenu") != 0)
	{
		// this should never happen, but just incase!
		cvarflags = ADMIN_MENU;
	}

	AddMenuItem("Amx Super Menu", "amx_supermenu", cvarflags, PluginFileName);
}

public handle_say(id)
{
	new arg[32];
	read_argv(1, arg, charsmax(arg));
	
	if (equal(arg, "/supermenu"))
	{
		menu_display(id, g_mainmenu, 0);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public handle_cmd(id, level, cid)
{
	new cmd[64];
	read_argv(0, cmd, charsmax(cmd));
		
	if (equal(cmd, "supermenu") || equal(cmd, "amx_supermenu"))
		menu_display(id, g_mainmenu, 0);
	else if (equal(cmd, "supermenu_edit") || equal(cmd, "amx_supermenu_edit"))
	{
		if (read_argc() < 2)
		{
			client_print(id, print_console, "%L", id, "AMXSUPER_NOPARM");
			client_print(id, print_console, "%L %s <menu to edit> <value1> [value2] [value3] [value4] ...", id, "USAGE", cmd);
			return PLUGIN_HANDLED;
		}
		
		new type[10], value, Array:temp = ArrayCreate();
		read_argv(1, type, charsmax(type));
		
		if (equal(type, "extend"))
			value = extend;
		else if (equal(type, "gravity"))
			value = gravity;
		else if (equal(type, "heal"))
			value = heal;
		else if (equal(type, "armor"))
			value = armor;
		else if (equal(type, "money"))
			value = givemoney;
		else if (equal(type, "badaim"))
			value = badaim;
		else if (equal(type, "gag"))
			value = gag;
		
		if (!(get_user_flags(id)&accessLevel[value]))
		{
			client_print(id, print_console, "%L", id, "NO_ACC_COM");
			return PLUGIN_HANDLED;
		}
		new msg[256], max = ArraySize(Array:ArrayGetCell(Array:valueArray, value)), k = (value == badaim) ? 2 : 0;
		if (read_argc() < 3)
		{
			client_print(id, print_console, "%L", id, "AMXSUPER_NOPARM");
			client_print(id, print_console, "%L %s %s <value1> [value2] [value3] [value4] ...", id, "USAGE", cmd, type);
			format(msg, charsmax(msg), "%d", ArrayGetCell(Array:ArrayGetCell(Array:valueArray, value), k++));
			while (k < max)
				format(msg, charsmax(msg), "%s, %d", msg, ArrayGetCell(Array:ArrayGetCell(Array:valueArray, value), k++));
			client_print(id, print_console, "%L: %s", id, "AMXSUPER_CURRENT", type, msg);
			return PLUGIN_HANDLED;
		}
		
		if (value == extend)
		{
			menu_destroy(g_extendmenu);
			
			// Recreating it and building it
			format(menuname, charsmax(menuname), "%L", LANG_PLAYER, "AMXSUPER_MENU4");
			g_extendmenu = menu_create(menuname, "extendMenu");
			
			new arg[4], k = 2;
			while (true)
			{
				read_argv(k, arg, charsmax(arg));
				if (equal(arg, "")) break;
				ArrayPushCell(temp, str_to_num(arg));
				k++;
				format(menuname, charsmax(menuname), "%L", LANG_PLAYER, "AMXSUPER_EXTEND", arg);
				menu_additem(g_extendmenu, menuname, arg);
			}
		}
		else if (value == gravity)
		{
			menu_destroy(g_gravitymenu);
			
			// Recreating it and building it
			format(menuname, charsmax(menuname), "%L", LANG_PLAYER, "AMXSUPER_MENU5");
			g_gravitymenu = menu_create(menuname, "gravityMenu");
			
			new arg[6], k = 2;
			while (true)
			{
				read_argv(k, arg, charsmax(arg));
				if (equal(arg, "")) break;
				ArrayPushCell(temp, str_to_num(arg));
				k++;
				menu_additem(g_gravitymenu, arg, arg);
			}
		}
		else
		{
			if (value == badaim)
			{
				ArrayPushCell(temp, 0);
				ArrayPushCell(temp, 1);
			}
			new arg[6], k = 2;
			while (true)
			{
				read_argv(k, arg, charsmax(arg));
				if (equal(arg, "")) break;
				ArrayPushCell(temp, str_to_num(arg));
				k++;
			}
		}
		
		max = ArraySize(temp), k = 0;
		format(msg, charsmax(msg), "%d", ArrayGetCell(temp, k++));
		while (k < max)
			format(msg, charsmax(msg), "%s, %d", msg, ArrayGetCell(temp, k++));
		client_print(id, print_console, "%L: %s", id, "AMXSUPER_CURRENT", type, msg);
		ArraySetCell(Array:valueArray, value, temp);
	}	
	return PLUGIN_HANDLED;
}

build_arrays()
{
	new Array:temp = ArrayCreate();
	for (new k = 5; k < 16; k+=5)
		ArrayPushCell(temp, k);
	for (new k = 30; k < 61; k+=15)
		ArrayPushCell(temp, k);
	ArraySetCell(Array:valueArray, extend, temp);
	
	ArrayClear(temp);
	for (new k = 0; k < 7; k++)
		ArrayPushCell(temp, k * 200);
	ArraySetCell(Array:valueArray, gravity, temp);
	
	ArrayClear(temp);
	ArrayPushCell(temp, 10);
	for (new k = 1; k < 5; k++)
		ArrayPushCell(temp, k * 25);
	ArrayPushCell(temp, 200);
	ArraySetCell(Array:valueArray, heal, temp);
	ArraySetCell(Array:valueArray, armor, temp);
	
	ArrayClear(temp);
	for (new k = 500; k < 16001; k*=2)
		ArrayPushCell(temp, k);
	ArraySetCell(Array:valueArray, givemoney, temp);
	
	ArrayClear(temp);
	ArrayPushCell(temp, 0);
	ArrayPushCell(temp, 1);
	for (new k = 5; k < 16; k+=5)
		ArrayPushCell(temp, k);
	for (new k = 30; k < 61; k+=15)
		ArrayPushCell(temp, k);
	ArraySetCell(Array:valueArray, badaim, temp);
	
	ArrayClear(temp);
	ArrayPushCell(temp, 30);
	ArrayPushCell(temp, 60);
	ArrayPushCell(temp, 300);
	for (new k = 600; k < 1801; k+=600)
		ArrayPushCell(temp, k);
	ArraySetCell(Array:valueArray, gag, temp);
}

build_menu()
{
	new value[20];
	
	// Build Main Menu
	for (new num = 1; num < maxvalue; num++)
	{
		if (num == 3 || num == 19 || num == 27 || num == 30)
			continue;
		
		new key[17], snum[3];
		format(key, charsmax(key), "AMXSUPER_MENU%d", num);
		format(snum, charsmax(snum), "%d", num);
		format(menuname, charsmax(menuname), "%L", LANG_PLAYER, key);
		if (accessLevel[num] != -2)
			menu_additem(g_mainmenu, menuname, snum, Callback);
	}
	
	// Build Alltalk Menu
	format(menuname, charsmax(menuname), "%L", LANG_PLAYER, "AMXSUPER_ENABLE");
	menu_additem(g_alltalkmenu, menuname, "1");
	format(menuname, charsmax(menuname), "%L", LANG_PLAYER, "AMXSUPER_DISABLE");
	menu_additem(g_alltalkmenu, menuname, "0");
	
	// Build Extend Menu
	for (new k = 0; k < 6; k++)
	{
		format(value, charsmax(value), "%d", ArrayGetCell(Array:ArrayGetCell(Array:valueArray, extend), k));
		format(menuname, charsmax(menuname), "%L", LANG_PLAYER, "AMXSUPER_EXTEND", value);
		menu_additem(g_extendmenu, menuname, value);
	}
	
	// Build Gravity Menu
	for (new k = 0; k < 6; k++)
	{
		format(value, charsmax(value), "%d", ArrayGetCell(Array:ArrayGetCell(Array:valueArray, gravity), k));
		menu_additem(g_gravitymenu, value, value);
	}
}

get_menu_players(&num)
{
	new temp[32], players[35], k;
	get_players(temp, num);
	
	for (k = 0; k < num; k++) players[k] = temp[k];
	
	players[k] = 33;
	players[k+1] = 34;
	players[k+2] = 35;
	num += 3;
	
	return players;
}

public menu_callback(id, menu, item)
{
	if (item < 0)
		return ITEM_DISABLED;
	
	new cmd[3], access, callback;
	menu_item_getinfo(menu, item, access, cmd,2,_,_, callback);
	
	if (get_user_flags(id)&accessLevel[str_to_num(cmd)])
		return ITEM_ENABLED;
	return ITEM_DISABLED;
}

public mainMenu(id, menu, item)
{
	if (item < 0)
		return PLUGIN_CONTINUE;
	
	new cmd[3];
	new access, callback;
	menu_item_getinfo(menu, item, access, cmd,2,_,_, callback);
	
	new num = str_to_num(cmd);
	
	g_menuProperties[id] = 0;
	g_menuPosition[id] = 0;
	
	switch(num)
	{
		case alltalk:
			menu_display(id, g_alltalkmenu, 0);
		case lock, unlock:
			displayLockMenu(id);
		case extend:
			menu_display(id, g_extendmenu, 0);
		case gravity:
			menu_display(id, g_gravitymenu, 0);
		case teamswap:
		{
			client_cmd(id, cmds[teamswap]);
			return PLUGIN_HANDLED;
		}
		case gag:
			displayGagMenu(id, 0);
		case fire, flash, disarm, rocket, uberslap, revive, quit, drug, swap:
			displayPlayer1Menu(id, 0, num);
		case heal, armor, stack, bury, unbury, slay, god, noclip, speed, unammo, givemoney, takemoney, badaim:
			displayPlayer2Menu(id, 0, num);
	}
	
	return PLUGIN_CONTINUE;
}

public alltalkMenu(id, menu, item)
{
	if (item == MENU_EXIT && get_pcvar_num(menufunc))
	{
		menu_display(id, g_mainmenu, 0);
		return PLUGIN_CONTINUE;
	}
	if (item < 0)
		return PLUGIN_CONTINUE;
	
	new cmd[3], access, callback;
	menu_item_getinfo(menu, item, access, cmd, 2,_,_, callback);
	
	client_cmd(id, menuCmd[alltalk], cmd);
	
	return PLUGIN_HANDLED;	
}

public lockMenu(id, key)
{
	new team[6];
	switch(key)
	{
		case 0:
			format(team, charsmax(team), "CT");
		case 1:
			format(team, charsmax(team), "T");
		case 2:
			format(team, charsmax(team), "Auto");
		case 3:
			format(team, charsmax(team), "Spec");
		case 4:
		{
			if (g_menuProperties[id] == lock)
				g_menuProperties[id] = unlock;
			else
				g_menuProperties[id] = lock;
			displayLockMenu(id);
			return PLUGIN_HANDLED;
		}
		case 9:
		{
			if (get_pcvar_num(menufunc))
			{
				menu_display(id, g_mainmenu, 0);
				return PLUGIN_HANDLED;
			}
		}
		default: return PLUGIN_HANDLED;
	}
	
	client_cmd(id, menuCmd[g_menuProperties[id]], team);
	
	displayLockMenu(id);
	
	return PLUGIN_HANDLED;
}

displayLockMenu(id)
{
	new menuBody[1000], line[100];
	
	format(menuBody, charsmax(menuBody), "\y");
	if (g_menuProperties[id] == lock)
		format(line, charsmax(line), "%L ^n", id, "AMXSUPER_LOCK");
	else
		format(line, charsmax(line), "%L ^n", id, "AMXSUPER_UNLOCK");
	add(menuBody, charsmax(menuBody), line);
	format(line, charsmax(line), "^n\w^n");
	add(menuBody, charsmax(menuBody), line);
	format(line, charsmax(line), "1. %L ^n", id, "AMXSUPER_TEAMCT");
	add(menuBody, charsmax(menuBody), line);
	format(line, charsmax(line), "2. %L ^n", id, "AMXSUPER_TEAMT");
	add(menuBody, charsmax(menuBody), line);
	format(line, charsmax(line), "3. %L ^n", id, "AMXSUPER_TEAMAUTO");
	add(menuBody, charsmax(menuBody), line);
	format(line, charsmax(line), "4. %L ^n", id, "AMXSUPER_TEAMSPEC");
	add(menuBody, charsmax(menuBody), line);
	if (g_menuProperties[id] == lock)
		format(line, charsmax(line), "^n5. %L ^n", id, "AMXSUPER_LOCK");
	else
		format(line, charsmax(line), "^n5. %L ^n", id, "AMXSUPER_UNLOCK");
	add(menuBody, charsmax(menuBody), line);
	format(line, charsmax(line), "^n^n0. %L", id, "EXIT");
	add(menuBody, charsmax(menuBody), line);
	new keys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5;
	
	show_menu(id, keys, menuBody, -1, "Lock Menu");
}

public extendMenu(id, menu, item)
{
	if (item == MENU_EXIT && get_pcvar_num(menufunc))
	{
		menu_display(id, g_mainmenu, 0);
		return PLUGIN_CONTINUE;
	}
	if (item < 0)
		return PLUGIN_CONTINUE;
	
	new cmd[4], access, callback;
	menu_item_getinfo(menu, item, access, cmd, 3,_,_, callback);
	
	client_cmd(id, menuCmd[extend], cmd);
	
	return PLUGIN_HANDLED;
}

public gravityMenu(id, menu, item)
{
	if (item == MENU_EXIT && get_pcvar_num(menufunc))
	{
		menu_display(id, g_mainmenu, 0);
		return PLUGIN_CONTINUE;
	}
	if (item < 0)
		return PLUGIN_CONTINUE;
	
	new cmd[5], access, callback;
	menu_item_getinfo(menu, item, access, cmd, 4,_,_, callback);
	
	client_cmd(id, menuCmd[gravity], cmd);
	
	return PLUGIN_HANDLED;
}

public player1Menu(id, key)
{
	switch (key)
	{
		case 8: displayPlayer1Menu(id, ++g_menuPosition[id], g_menu[id]);
		case 9:	displayPlayer1Menu(id, --g_menuPosition[id], g_menu[id]);
		default:
		{
			new player = g_menuPlayers[id][g_menuPosition[id] * 8 + key];
			new name[32];
			
			if (g_menu[id] != swap)
			{
				switch (player)
				{
					case 33: format(name, charsmax(name), "@ALL");
					case 34: format(name, charsmax(name), "@T");
					case 35: format(name, charsmax(name), "@CT");
					default: get_user_name(player, name, charsmax(name));
				}
				client_cmd(id, menuCmd[g_menu[id]], name);
			}
			else
			{
				if (equal(g_menuPlayerName[id], ""))
				{
					format(g_menuPlayerName[id], 31, "%s", name);
					g_menuPosition[id] = 0;
					displayPlayer1Menu(id, g_menuPosition[id], g_menu[id]);
				}
				else
				{
					client_cmd(id, menuCmd[swap], g_menuPlayerName[id], name);
					format(g_menuPlayerName[id], 31, "");
				}
			}
		}
	}
	
	displayPlayer1Menu(id, g_menuPosition[id], g_menu[id]); 
	
	return PLUGIN_HANDLED;
}

displayPlayer1Menu(id, pos, menu)
{
	if (pos < 0)
	{
		if (get_pcvar_num(menufunc))
			menu_display(id, g_mainmenu, 0);
		return;
	}
	
	g_menu[id] = menu;
	g_menuPlayers[id] = get_menu_players(g_menuPlayersNum[id]);

	new menuBody[1024];
	new b = 0;
	new i;
	new name[32];
	new start = pos * 8;
	
	if (start >= g_menuPlayersNum[id])
		start = pos = g_menuPosition[id] = 0;
	
	new key[17];
	format(key, charsmax(key), "AMXSUPER_MENU%d", menu);
	new len = format(menuBody, 1023, "\y%L\R%d/%d^n\w^n", id, key, pos + 1, (g_menuPlayersNum[id] / 8 + ((g_menuPlayersNum[id] % 8) ? 1 : 0)));
	new end = start + 8;
	new keys = MENU_KEY_0;

	if (end > g_menuPlayersNum[id])
		end = g_menuPlayersNum[id];

	for (new a = start; a < end; ++a)
	{
		i = g_menuPlayers[id][a];
		
		if (g_menu[id] != swap)
			switch (i)
			{
				case 33: format(name, charsmax(name), "%L", id, "AMXSUPER_ALL");
				case 34: format(name, charsmax(name), "%L", id, "AMXSUPER_TEAMT");
				case 35: format(name, charsmax(name), "%L", id, "AMXSUPER_TEAMCT");
				default: get_user_name(i, name, 31);
			}
		else
			get_user_name(i, name, 31);
		
		if (i < 33 && i != id && access(i, ADMIN_IMMUNITY))
		{
			++b;
			len += format(menuBody[len], 1023-len, "\d\r%d. \w%s^n\w", b, name);
		} else {
			keys |= (1<<b);
				
			if (i < 33 && is_user_admin(i))
				len += format(menuBody[len], 1023-len, "\r%d. \w%s \r*^n\w", ++b, name);
			else
				len += format(menuBody[len], 1023-len, "\r%d. \w%s^n", ++b, name);
		}
	}

	if (end != g_menuPlayersNum[id])
	{
		format(menuBody[len], 1023-len, "^n\r9. \w%L...^n\r0. \w%L", id, "MORE", id, pos ? "BACK" : "EXIT");
		keys |= MENU_KEY_9;
	}
	else
		format(menuBody[len], 1023-len, "^n\r0. \w%L", id, pos ? "BACK" : "EXIT");

	show_menu(id, keys, menuBody, -1, "Player1 Menu");
}

public player2Menu(id, key)
{
	switch (key)
	{
		case 7:
		{
			switch (g_menu[id])
			{
				case heal, armor: if (++g_menuProperties[id] > 5) g_menuProperties[id] = 0;
				case stack, god, noclip: if (++g_menuProperties[id] > 2) g_menuProperties[id] = 0;
				case slay: if (++g_menuProperties[id] > 3) g_menuProperties[id] = 1;
				case speed, unammo, bury, unbury: if (++g_menuProperties[id] > 1) g_menuProperties[id] = 0;
				case badaim: if (++g_menuProperties[id] > 7) g_menuProperties[id] = 0;
				case givemoney, takemoney:
				{
					if (++g_menuProperties[id] > 5)
					{
						g_menuProperties[id] = 0;
						if (g_money[id] == -1)
							g_money[id] = 1;
						else
							g_money[id] = -1;
					}
				}
			}
			displayPlayer2Menu(id, g_menuPosition[id], g_menu[id]);
		}
		case 8: displayPlayer2Menu(id, ++g_menuPosition[id], g_menu[id]);
		case 9: displayPlayer2Menu(id, --g_menuPosition[id], g_menu[id]);
		default:
		{
			new player = g_menuPlayers[id][g_menuPosition[id] * 7 + key];
			new name[32];
			
			switch (player)
			{
				case 33: format(name, charsmax(name), "@ALL");
				case 34: format(name, charsmax(name), "@T");
				case 35: format(name, charsmax(name), "@CT");
				default: get_user_name(player, name, charsmax(name));
			}
			
			switch (g_menu[id])
			{
				case heal, armor, badaim: client_cmd(id, menuCmd[g_menu[id]], name, ArrayGetCell(Array:ArrayGetCell(Array:valueArray, g_menu[id]), g_menuProperties[id]));
				case stack, slay, god, noclip, speed, unammo: client_cmd(id, menuCmd[g_menu[id]], name, g_menuProperties[id]);
				case givemoney, takemoney: client_cmd(id, (g_money[id] == -1) ? menuCmd[takemoney] : menuCmd[givemoney], name, ArrayGetCell(Array:ArrayGetCell(Array:valueArray, g_menu[id]), g_menuProperties[id]));
				case bury, unbury: client_cmd(id, menuCmd[bury], name);
			}
		}
	}
	
	displayPlayer2Menu(id, g_menuPosition[id], g_menu[id]);
	
	return PLUGIN_HANDLED;
}

displayPlayer2Menu(id, pos, menu)
{
	if (pos < 0)
	{
		if (get_pcvar_num(menufunc))
			menu_display(id, g_mainmenu, 0);
		return;
	}
	
	g_menu[id] = menu;
	g_menuPlayers[id] = get_menu_players(g_menuPlayersNum[id]);

	new menuBody[1024];
	new b = 0;
	new i;
	new name[32];
	new start = pos * 7;
	
	if (start >= g_menuPlayersNum[id])
		start = pos = g_menuPosition[id] = 0;
	
	new key[20];
	if (menu == bury || menu == unbury)
		format(key, charsmax(key), "\yAMXSUPER_%s", (g_menuProperties[id]) ? "UNBURY" : "BURY");
	else
		format(key, charsmax(key), "AMXSUPER_MENU%d", menu);
	new len = format(menuBody, 1023, "\y%L\R%d/%d^n\w^n", id, key, pos + 1, (g_menuPlayersNum[id] / 7 + ((g_menuPlayersNum[id] % 7) ? 1 : 0)));
	new end = start + 7;
	new keys = MENU_KEY_0;

	if (end > g_menuPlayersNum[id])
		end = g_menuPlayersNum[id];

	for (new a = start; a < end; ++a)
	{
		i = g_menuPlayers[id][a];
		
		switch (i)
		{
			case 33: format(name, charsmax(name), "%L", id, "AMXSUPER_ALL");
			case 34: format(name, charsmax(name), "%L", id, "AMXSUPER_TEAMT");
			case 35: format(name, charsmax(name), "%L", id, "AMXSUPER_TEAMCT");
			default: get_user_name(i, name, 31);
		}
		
		if (i < 33 && i != id && access(i, ADMIN_IMMUNITY))
		{
			++b;
			len += format(menuBody[len], 1023-len, "\d\r%d. \w%s^n\w", b, name);
		} else {
			keys |= (1<<b);
				
			if (i < 33 && is_user_admin(i))
				len += format(menuBody[len], 1023-len, "\r%d. \w%s \r*^n\w", ++b, name);
			else
				len += format(menuBody[len], 1023-len, "\r%d. \w%s^n", ++b, name);
		}
	}
	
	new option[20];
	if (menu == heal || menu == armor || menu == badaim || menu == givemoney || menu == takemoney)
		format(option, charsmax(option), "%d", ArrayGetCell(Array:ArrayGetCell(Array:valueArray, menu), g_menuProperties[id]));
		
	switch (menu)
	{
		case heal: len += format(menuBody[len], 1023-len, "\r8. \w%L", id, "AMXSUPER_HEAL", option);
		case armor: len += format(menuBody[len], 1023-len, "\r8. \w%L", id, "AMXSUPER_ARMOR", option);
		case stack: len += format(menuBody[len], 1023-len, "\r8. \w%L", id, "AMXSUPER_STACK", g_menuProperties[id]);
		case bury, unbury: len += format(menuBody[len], 1023-len, "\r8. \w%L", id, (g_menuProperties[id]) ? "AMXSUPER_BURY" : "AMXSUPER_UNBURY");
		case slay:
		{
			format(key, charsmax(key), "AMXSUPER_SLAY%d", g_menuProperties[id]);
			len += format(menuBody[len], 1023-len, "\r8. \w%L", id, key);
		}
		case god, noclip, speed, unammo:
		{
			format(key, charsmax(key), "AMXSUPER_GOD%d", g_menuProperties[id]);
			len += format(menuBody[len], 1023-len, "\r8. \w%L", id, key);
		}
		case badaim:
		{
			format(key, charsmax(key), "AMXSUPER_%s", (g_menuProperties[id] < 2) ? (g_menuProperties[id]) ? "GOD0" : "GOD1" : "MINS");
			if (g_menuProperties[id] < 2)
				len += format(menuBody[len], 1023-len, "\r8. \w%L", id, key);
			else
				len += format(menuBody[len], 1023-len, "\r8. \w%L", id, key, option);
		}
		case givemoney, takemoney: len += format(menuBody[len], 1023-len, "\r8. \w%L", id, (g_money[id] == -1) ? "AMXSUPER_TAKE" : "AMXSUPER_GIVE", option);
	}
	keys |= MENU_KEY_8;
		
	if (end != g_menuPlayersNum[id])
	{
		format(menuBody[len], 1023-len, "^n\r9. \w%L...^n\r0. \w%L", id, "MORE", id, pos ? "BACK" : "EXIT");
		keys |= MENU_KEY_9;
	}
	else
		format(menuBody[len], 1023-len, "^n\r0. \w%L", id, pos ? "BACK" : "EXIT");
	
	show_menu(id, keys, menuBody, -1, "Player2 Menu");
}

public gagMenu(id, key)
{
	switch (key)
	{
		case 6:
		{
			if (++g_menuProperties[id] > 5) g_menuProperties[id] = 0;
			displayGagMenu(id, g_menuPosition[id]);
		}
		case 7:
		{
			if (++g_menuProperties2[id] > 7) g_menuProperties2[id] = 0;
			displayGagMenu(id, g_menuPosition[id]);
		}
		case 8: displayGagMenu(id, ++g_menuPosition[id]);
		case 9: displayGagMenu(id, --g_menuPosition[id]);
		default:
		{
			new player = g_menuPlayers[id][g_menuPosition[id] * 6 + key];
			new name[32];
			
			switch (player)
			{
				case 33: format(name, charsmax(name), "@ALL");
				case 34: format(name, charsmax(name), "@T");
				case 35: format(name, charsmax(name), "@CT");
				default: get_user_name(player, name, charsmax(name));
			}
			
			if (g_menuProperties2[id] == 7)
				client_cmd(id, menuCmd[ungag], name);
			else
			{
				new flags[4];
				
				switch (g_menuProperties2[id])
				{
					case 0: format(flags, charsmax(flags), "a");
					case 1: format(flags, charsmax(flags), "b");
					case 2: format(flags, charsmax(flags), "c");
					case 3: format(flags, charsmax(flags), "ab");
					case 4: format(flags, charsmax(flags), "ac");
					case 5: format(flags, charsmax(flags), "bc");
					case 6: format(flags, charsmax(flags), "abc");
				}
				
				client_cmd(id, menuCmd[gag], name, flags, ArrayGetCell(Array:ArrayGetCell(Array:valueArray, g_menu[id]), g_menuProperties[id]));
			}
		}
	}
	
	displayGagMenu(id, g_menuPosition[id]);
	
	return PLUGIN_HANDLED;
}

displayGagMenu(id, pos)
{
	if (pos < 0)
	{
		if (get_pcvar_num(menufunc))
			menu_display(id, g_mainmenu, 0);
		return;
	}

	g_menuPlayers[id] = get_menu_players(g_menuPlayersNum[id]);

	new menuBody[1024];
	new b = 0;
	new i;
	new name[32];
	new start = pos * 6;
	
	if (start >= g_menuPlayersNum[id])
		start = pos = g_menuPosition[id] = 0;
	
	new key[20];
	format(key, charsmax(key), "\yAMXSUPER_MENU%d", gag);
	new len = format(menuBody, 1023, "\y%L\R%d/%d^n\w^n", id, key, pos + 1, (g_menuPlayersNum[id] / 6 + ((g_menuPlayersNum[id] % 6) ? 1 : 0)));
	new end = start + 6;
	new keys = MENU_KEY_0|MENU_KEY_7|MENU_KEY_8;

	if (end > g_menuPlayersNum[id])
		end = g_menuPlayersNum[id];

	for (new a = start; a < end; ++a)
	{
		i = g_menuPlayers[id][a];
		
		switch (i)
		{
			case 33: format(name, charsmax(name), "%L", id, "AMXSUPER_ALL");
			case 34: format(name, charsmax(name), "%L", id, "AMXSUPER_TEAMT");
			case 35: format(name, charsmax(name), "%L", id, "AMXSUPER_TEAMCT");
			default: get_user_name(i, name, 31);
		}
		
		if (i < 33 && i != id && access(i, ADMIN_IMMUNITY))
		{
			++b;
			len += format(menuBody[len], 1023-len, "\d\r%d. \w%s^n\w", b, name);
		} else {
			keys |= (1<<b);
				
			if (i < 33 && is_user_admin(i))
				len += format(menuBody[len], 1023-len, "\r%d. \w%s \r*^n\w", ++b, name);
			else
				len += format(menuBody[len], 1023-len, "\r%d. \w%s^n", ++b, name);
		}
	}
	
	new option[20];
	format(option, charsmax(option), "%d", ArrayGetCell(Array:ArrayGetCell(Array:valueArray, g_menu[id]), g_menuProperties[id]));
	len += format(menuBody[len], 1023-len, "7. %L^n", id, "AMXSUPER_SECS", option);
	
	switch (g_menuProperties2[id])
	{
		case 0: len += format(menuBody[len], 1023-len, "8. %L^n", id, "AMXSUPER_GAGA");
		case 1: len += format(menuBody[len], 1023-len, "8. %L^n", id, "AMXSUPER_GAGB");
		case 2: len += format(menuBody[len], 1023-len, "8. %L^n", id, "AMXSUPER_GAGC");
		case 3: len += format(menuBody[len], 1023-len, "8. %L & %L^n", id, "AMXSUPER_GAGA", id, "AMXSUPER_GAGB");
		case 4: len += format(menuBody[len], 1023-len, "8. %L & %L^n", id, "AMXSUPER_GAGA", id, "AMXSUPER_GAGC");
		case 5: len += format(menuBody[len], 1023-len, "8. %L & %L^n", id, "AMXSUPER_GAGB", id, "AMXSUPER_GAGC");
		case 6: len += format(menuBody[len], 1023-len, "8. %L & %L & %L^n", id, "AMXSUPER_GAGA", id, "AMXSUPER_GAGB", id, "AMXSUPER_GAGC");
		case 7: len += format(menuBody[len], 1023-len, "8. %L^n", id, "AMXSUPER_UNGAG");
	}
	
	if (end != g_menuPlayersNum[id])
	{
		format(menuBody[len], 1023-len, "^n9. %L...^n0. %L", id, "MORE", id, pos ? "BACK" : "EXIT");
		keys |= MENU_KEY_9;
	}
	else
		format(menuBody[len], 1023-len, "^n0. %L", id, pos ? "BACK" : "EXIT");

	show_menu(id, keys, menuBody, -1, "Gag Menu");
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1046\\ f0\\ fs16 \n\\ par }
*/
