/*================================================================================
	
	-----------------------------
	-*- [ZP] Ambience Effects -*-
	-----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <amx_settings_api>
#include <zp50_core_const>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

#define FOG_VALUE_MAX_LENGTH 16

new g_ambience_rain = 0
new g_ambience_snow = 0
new g_ambience_fog = 1
new g_ambience_fog_density[FOG_VALUE_MAX_LENGTH] = "0.0018"
new g_ambience_fog_color[FOG_VALUE_MAX_LENGTH] = "128 128 128"

new const g_ambience_ents[][] = { "env_fog", "env_rain", "env_snow" }

new g_fwSpawn

public plugin_init()
{
	register_plugin("[ZP] Ambience Effects", ZP_VERSION_STRING, "ZP Dev Team")
	unregister_forward(FM_Spawn, g_fwSpawn)
}

public plugin_precache()
{
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weather Effects", "FOG DENSITY", g_ambience_fog_density, charsmax(g_ambience_fog_density)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weather Effects", "FOG DENSITY", g_ambience_fog_density)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weather Effects", "FOG COLOR", g_ambience_fog_color, charsmax(g_ambience_fog_color)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weather Effects", "FOG COLOR", g_ambience_fog_color)
	
	if (!amx_load_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "FOG", g_ambience_fog))
		amx_save_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "FOG", g_ambience_fog)
	if (!amx_load_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "SNOW", g_ambience_snow))
		amx_save_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "SNOW", g_ambience_snow)
	if (!amx_load_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "RAIN", g_ambience_rain))
		amx_save_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "RAIN", g_ambience_rain)
	
	if (g_ambience_fog)
	{
		new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
		if (pev_valid(ent))
		{
			fm_set_kvd(ent, "density", g_ambience_fog_density, "env_fog")
			fm_set_kvd(ent, "rendercolor", g_ambience_fog_color, "env_fog")
		}
	}
	if (g_ambience_rain)
		engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"))
	if (g_ambience_snow)
		engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"))
	
	// Prevent gameplay entities from spawning
	g_fwSpawn = register_forward(FM_Spawn, "fw_Spawn")
}

// Entity Spawn Forward
public fw_Spawn(entity)
{
	// Invalid entity
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	// Get classname
	new classname[32]
	pev(entity, pev_classname, classname, charsmax(classname))
	
	// Check whether it needs to be removed
	new index
	for (index = 0; index < sizeof g_ambience_ents; index++)
	{
		if (equal(classname, g_ambience_ents[index]))
		{
			engfunc(EngFunc_RemoveEntity, entity)
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

// Set an entity's key value (from fakemeta_util)
stock fm_set_kvd(entity, const key[], const value[], const classname[])
{
	set_kvd(0, KV_ClassName, classname)
	set_kvd(0, KV_KeyName, key)
	set_kvd(0, KV_Value, value)
	set_kvd(0, KV_fHandled, 0)

	dllfunc(DLLFunc_KeyValue, entity, 0)
}