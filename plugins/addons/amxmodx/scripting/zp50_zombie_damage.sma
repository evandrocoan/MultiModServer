/*================================================================================
	
	--------------------------
	-*- [ZP] Zombie Damage -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>

new cvar_zombie_defense, cvar_zombie_hitzones

public plugin_init()
{
	register_plugin("[ZP] Zombie Damage", ZP_VERSION_STRING, "ZP Dev Team")
	
	cvar_zombie_defense = register_cvar("zp_zombie_defense", "0.75")
	cvar_zombie_hitzones = register_cvar("zp_zombie_hitzones", "0")
	
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHamBots(Ham_TraceAttack, "fw_TraceAttack")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
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

// Ham Trace Attack Forward
public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// Zombie custom hitzones disabled
	if (!get_pcvar_num(cvar_zombie_hitzones))
		return HAM_IGNORED;
	
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Not bullet damage or victim isn't a zombie
	if (!(damage_type & DMG_BULLET) || !zp_core_is_zombie(victim))
		return HAM_IGNORED;
	
	// Check whether we hit an allowed one
	if (!(get_pcvar_num(cvar_zombie_hitzones) & (1<<get_tr2(tracehandle, TR_iHitgroup))))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Human attacking zombie...
	if (!zp_core_is_zombie(attacker) && zp_core_is_zombie(victim))
	{
		// Ignore for Nemesis
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(attacker))
			return HAM_IGNORED;
		
		// Armor multiplier for the final damage
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_zombie_defense))
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}
