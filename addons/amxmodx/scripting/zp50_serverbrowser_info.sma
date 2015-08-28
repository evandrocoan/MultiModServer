/*================================================================================
	
	--------------------------------
	-*- [ZP] Server Broswer Info -*-
	--------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <zp50_core>

new g_ModName[64]

public plugin_init()
{
	register_plugin("[ZP] Server Browser Info", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_forward(FM_GetGameDescription, "fw_GetGameDescription")
	formatex(g_ModName, charsmax(g_ModName), "Zombie Plague %s", ZP_VERSION_STR_LONG)
}

// Forward Get Game Description
public fw_GetGameDescription()
{
	// Return the mod name so it can be easily identified
	forward_return(FMV_STRING, g_ModName)
	
	return FMRES_SUPERCEDE;
}