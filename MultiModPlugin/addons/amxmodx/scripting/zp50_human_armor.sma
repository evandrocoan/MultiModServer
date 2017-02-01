/*================================================================================
	
	------------------------
	-*- [ZP] Human Armor -*-
	------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>

// CS Player PData Offsets (win32)
const OFFSET_PAINSHOCK = 108 // ConnorMcLeod

// Some constants
const DMG_HEGRENADE = (1<<24)

// CS sounds
new const g_sound_armor_hit[] = "player/bhit_helmet-1.wav"

new cvar_human_armor_protect, cvar_human_armor_default
new cvar_armor_protect_nemesis, cvar_survivor_armor_protect

public plugin_init()
{
	register_plugin("[ZP] Human Armor", ZP_VERSION_STRING, "ZP Dev Team")
	
	cvar_human_armor_protect = register_cvar("zp_human_armor_protect", "1")
	cvar_human_armor_default = register_cvar("zp_human_armor_default", "0")
	
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
		cvar_armor_protect_nemesis = register_cvar("zp_armor_protect_nemesis", "1")
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
		cvar_survivor_armor_protect = register_cvar("zp_survivor_armor_protect", "1")
	
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

public plugin_precache()
{
	precache_sound(g_sound_armor_hit)
}

public zp_fw_core_cure_post(id, attacker)
{
	new Float:armor
	pev(id, pev_armorvalue, armor)
	
	if (armor < get_pcvar_float(cvar_human_armor_default))
		set_pev(id, pev_armorvalue, get_pcvar_float(cvar_human_armor_default))
}

// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Zombie attacking human...
	if (zp_core_is_zombie(attacker) && !zp_core_is_zombie(victim))
	{
		// Ignore damage coming from a HE grenade (bugfix)
		if (damage_type & DMG_HEGRENADE)
			return HAM_IGNORED;
		
		// Does human armor need to be reduced before infecting/damaging?
		if (!get_pcvar_num(cvar_human_armor_protect))
			return HAM_IGNORED;
		
		// Should armor protect against nemesis attacks?
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && !get_pcvar_num(cvar_armor_protect_nemesis) && zp_class_nemesis_get(attacker))
			return HAM_IGNORED;
		
		// Should armor protect survivor too?
		if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && !get_pcvar_num(cvar_survivor_armor_protect) && zp_class_survivor_get(victim))
			return HAM_IGNORED;
		
		// Get victim armor
		static Float:armor
		pev(victim, pev_armorvalue, armor)
		
		// If he has some, block damage and reduce armor instead
		if (armor > 0.0)
		{
			emit_sound(victim, CHAN_BODY, g_sound_armor_hit, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			if (armor - damage > 0.0)
				set_pev(victim, pev_armorvalue, armor - damage)
			else
				cs_set_user_armor(victim, 0, CS_ARMOR_NONE)
			
			// Block damage, but still set the pain shock offset
			set_pdata_float(victim, OFFSET_PAINSHOCK, 0.5)
			return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}