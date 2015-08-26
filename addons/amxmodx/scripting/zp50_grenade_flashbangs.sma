/*================================================================================
	
	--------------------------------
	-*- [ZP] Grenade: Flashbangs -*-
	--------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_core>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>

new cvar_grenade_flashbang_color_R, cvar_grenade_flashbang_color_G, cvar_grenade_flashbang_color_B
new cvar_grenade_flashbang_nemesis

public plugin_init()
{
	register_plugin("[ZP] Grenade: Flashbangs", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_message(get_user_msgid("ScreenFade"), "message_screenfade")
	
	cvar_grenade_flashbang_color_R = register_cvar("zp_grenade_flashbang_color_R", "0")
	cvar_grenade_flashbang_color_G = register_cvar("zp_grenade_flashbang_color_G", "150")
	cvar_grenade_flashbang_color_B = register_cvar("zp_grenade_flashbang_color_B", "0")
	
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
		cvar_grenade_flashbang_nemesis = register_cvar("zp_grenade_flashbang_nemesis", "0")
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

// Make flashbangs only affect zombies
public message_screenfade(msg_id, msg_dest, msg_entity)
{
	// Is this a flashbang?
	if (get_msg_arg_int(4) != 255 || get_msg_arg_int(5) != 255 || get_msg_arg_int(6) != 255 || get_msg_arg_int(7) < 200)
		return PLUGIN_CONTINUE;
	
	// Block for humans
	if (!zp_core_is_zombie(msg_entity))
		return PLUGIN_HANDLED;
	
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(msg_entity) && !get_pcvar_num(cvar_grenade_flashbang_nemesis))
		return PLUGIN_HANDLED;
	
	// Set flash color
	set_msg_arg_int(4, get_msg_argtype(4), get_pcvar_num(cvar_grenade_flashbang_color_R))
	set_msg_arg_int(5, get_msg_argtype(5), get_pcvar_num(cvar_grenade_flashbang_color_G))
	set_msg_arg_int(6, get_msg_argtype(6), get_pcvar_num(cvar_grenade_flashbang_color_B))
	return PLUGIN_CONTINUE;
}