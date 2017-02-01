/* AMX Mod script.
*
* (c) Copyright 2003, Phreak
* This file is provided as is (no warranties).
*
*  This plugin opens the amx menu when you
*  say "menu" in normal chat.
*
*  setup in admin.cfg:
*  amx_menu:
*    amx_set_saymenu 0
*  amxmodmenu:
*    amx_set_saymenu 1
*  
*/

#include <amxmod>

new menu_mode = 0

public say_menu(id) {
	switch (menu_mode) {
		case 0:	client_cmd(id,"amx_menu")
		case 1: client_cmd(id,"amxmodmenu")
	}
	return PLUGIN_HANDLED
}

public setup(){
	new data[32]
	read_argv(1,data,31)
	menu_mode = strtonum(data);
	return PLUGIN_HANDLED
}

public plugin_init() {
	register_plugin("Say menu","0.2","Phreak")
	register_clcmd("say menu","say_menu",ADMIN_MENU)
	register_srvcmd("amx_set_saymenu","setup")
	return PLUGIN_CONTINUE
}
