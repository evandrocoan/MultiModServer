/*================================================================================
	
	----------------------------
	-*- [ZP] Pain Shock Free -*-
	----------------------------
	
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
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>

// CS Player PData Offsets (win32)
const OFFSET_PAINSHOCK = 108 // ConnorMcLeod

new cvar_painshockfree_zombie, cvar_painshockfree_human, cvar_painshockfree_nemesis, cvar_painshockfree_survivor

public plugin_init()
{
	register_plugin("[ZP] Pain Shock Free", ZP_VERSION_STRING, "ZP Dev Team")
	
	cvar_painshockfree_zombie = register_cvar("zp_painshockfree_zombie", "1") // 1-all // 2-first only // 3-last only
	cvar_painshockfree_human = register_cvar("zp_painshockfree_human", "0") // 1-all // 2-last only
	
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
		cvar_painshockfree_nemesis = register_cvar("zp_painshockfree_nemesis", "0")
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
		cvar_painshockfree_survivor = register_cvar("zp_painshockfree_survivor", "1")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage_Post", 1)
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

// Ham Take Damage Post Forward
public fw_TakeDamage_Post(victim)
{
	// Is zombie?
	if (zp_core_is_zombie(victim))
	{
		// Nemesis Class loaded?
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(victim))
		{
			if (!get_pcvar_num(cvar_painshockfree_nemesis)) return;
		}
		else
		{
			// Check if zombie should be pain shock free
			switch (get_pcvar_num(cvar_painshockfree_zombie))
			{
				case 0: return;
				case 2: if (!zp_core_is_first_zombie(victim)) return;
				case 3: if (!zp_core_is_last_zombie(victim)) return;
			}
		}
	}
	else
	{
		// Survivor Class loaded?
		if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(victim))
		{
			if (!get_pcvar_num(cvar_painshockfree_survivor)) return;
		}
		else
		{
			// Check if human should be pain shock free
			switch (get_pcvar_num(cvar_painshockfree_human))
			{
				case 0: return;
				case 2: if (!zp_core_is_last_human(victim)) return;
			}
		}
	}
	
	// Set pain shock free offset
	set_pdata_float(victim, OFFSET_PAINSHOCK, 1.0)
}
