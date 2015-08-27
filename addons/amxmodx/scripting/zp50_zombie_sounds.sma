/*================================================================================
	
	--------------------------
	-*- [ZP] Zombie Sounds -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_zombie_pain[][] = { "zombie_plague/zombie_pain1.wav" , "zombie_plague/zombie_pain2.wav" , "zombie_plague/zombie_pain3.wav" , "zombie_plague/zombie_pain4.wav" , "zombie_plague/zombie_pain5.wav" }
new const sound_nemesis_pain[][] = { "zombie_plague/nemesis_pain1.wav" , "zombie_plague/nemesis_pain2.wav" , "zombie_plague/nemesis_pain3.wav" }
new const sound_zombie_die[][] = { "zombie_plague/zombie_die1.wav" , "zombie_plague/zombie_die2.wav" , "zombie_plague/zombie_die3.wav" , "zombie_plague/zombie_die4.wav" , "zombie_plague/zombie_die5.wav" }
new const sound_zombie_fall[][] = { "zombie_plague/zombie_fall1.wav" }
new const sound_zombie_miss_slash[][] = { "weapons/knife_slash1.wav" , "weapons/knife_slash2.wav" }
new const sound_zombie_miss_wall[][] = { "weapons/knife_hitwall1.wav" }
new const sound_zombie_hit_normal[][] = { "weapons/knife_hit1.wav" , "weapons/knife_hit2.wav" , "weapons/knife_hit3.wav" , "weapons/knife_hit4.wav" }
new const sound_zombie_hit_stab[][] = { "weapons/knife_stab.wav" }
new const sound_zombie_idle[][] = { "nihilanth/nil_now_die.wav" , "nihilanth/nil_slaves.wav" , "nihilanth/nil_alone.wav" , "zombie_plague/zombie_brains1.wav" , "zombie_plague/zombie_brains2.wav" }
new const sound_zombie_idle_last[][] = { "nihilanth/nil_thelast.wav" }

#define SOUND_MAX_LENGTH 64

// Custom sounds
new Array:g_sound_zombie_pain
new Array:g_sound_nemesis_pain
new Array:g_sound_zombie_die
new Array:g_sound_zombie_fall
new Array:g_sound_zombie_miss_slash
new Array:g_sound_zombie_miss_wall
new Array:g_sound_zombie_hit_normal
new Array:g_sound_zombie_hit_stab
new Array:g_sound_zombie_idle
new Array:g_sound_zombie_idle_last

#define TASK_IDLE_SOUNDS 100
#define ID_IDLE_SOUNDS (taskid - TASK_IDLE_SOUNDS)

new cvar_zombie_sounds_pain, cvar_zombie_sounds_attack, cvar_zombie_sounds_idle

public plugin_init()
{
	register_plugin("[ZP] Zombie Sounds", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	
	cvar_zombie_sounds_pain = register_cvar("zp_zombie_sounds_pain", "1")
	cvar_zombie_sounds_attack = register_cvar("zp_zombie_sounds_attack", "1")
	cvar_zombie_sounds_idle = register_cvar("zp_zombie_sounds_idle", "1")
}

public plugin_precache()
{
	// Initialize arrays
	g_sound_zombie_pain = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_nemesis_pain = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_die = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_fall = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_miss_slash = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_miss_wall = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_hit_normal = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_hit_stab = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_idle = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_zombie_idle_last = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE PAIN", g_sound_zombie_pain)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "NEMESIS PAIN", g_sound_nemesis_pain)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE DIE", g_sound_zombie_die)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE FALL", g_sound_zombie_fall)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE MISS SLASH", g_sound_zombie_miss_slash)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE MISS WALL", g_sound_zombie_miss_wall)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE HIT NORMAL", g_sound_zombie_hit_normal)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE HIT STAB", g_sound_zombie_hit_stab)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE IDLE", g_sound_zombie_idle)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE IDLE LAST", g_sound_zombie_idle_last)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_zombie_pain) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_pain; index++)
			ArrayPushString(g_sound_zombie_pain, sound_zombie_pain[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE PAIN", g_sound_zombie_pain)
	}
	if (ArraySize(g_sound_nemesis_pain) == 0)
	{
		for (index = 0; index < sizeof sound_nemesis_pain; index++)
			ArrayPushString(g_sound_nemesis_pain, sound_nemesis_pain[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "NEMESIS PAIN", g_sound_nemesis_pain)
	}
	if (ArraySize(g_sound_zombie_die) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_die; index++)
			ArrayPushString(g_sound_zombie_die, sound_zombie_die[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE DIE", g_sound_zombie_die)
	}
	if (ArraySize(g_sound_zombie_fall) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_fall; index++)
			ArrayPushString(g_sound_zombie_fall, sound_zombie_fall[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE FALL", g_sound_zombie_fall)
	}
	if (ArraySize(g_sound_zombie_miss_slash) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_miss_slash; index++)
			ArrayPushString(g_sound_zombie_miss_slash, sound_zombie_miss_slash[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE MISS SLASH", g_sound_zombie_miss_slash)
	}
	if (ArraySize(g_sound_zombie_miss_wall) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_miss_wall; index++)
			ArrayPushString(g_sound_zombie_miss_wall, sound_zombie_miss_wall[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE MISS WALL", g_sound_zombie_miss_wall)
	}
	if (ArraySize(g_sound_zombie_hit_normal) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_hit_normal; index++)
			ArrayPushString(g_sound_zombie_hit_normal, sound_zombie_hit_normal[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE HIT NORMAL", g_sound_zombie_hit_normal)
	}
	if (ArraySize(g_sound_zombie_hit_stab) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_hit_stab; index++)
			ArrayPushString(g_sound_zombie_hit_stab, sound_zombie_hit_stab[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE HIT STAB", g_sound_zombie_hit_stab)
	}
	if (ArraySize(g_sound_zombie_idle) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_idle; index++)
			ArrayPushString(g_sound_zombie_idle, sound_zombie_idle[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE IDLE", g_sound_zombie_idle)
	}
	if (ArraySize(g_sound_zombie_idle_last) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_idle_last; index++)
			ArrayPushString(g_sound_zombie_idle_last, sound_zombie_idle_last[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE IDLE LAST", g_sound_zombie_idle_last)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_zombie_pain); index++)
	{
		ArrayGetString(g_sound_zombie_pain, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
	{
		for (index = 0; index < ArraySize(g_sound_nemesis_pain); index++)
		{
			ArrayGetString(g_sound_nemesis_pain, index, sound, charsmax(sound))
			precache_sound(sound)
		}
	}	
	for (index = 0; index < ArraySize(g_sound_zombie_die); index++)
	{
		ArrayGetString(g_sound_zombie_die, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_zombie_fall); index++)
	{
		ArrayGetString(g_sound_zombie_fall, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_zombie_miss_slash); index++)
	{
		ArrayGetString(g_sound_zombie_miss_slash, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_zombie_miss_wall); index++)
	{
		ArrayGetString(g_sound_zombie_miss_wall, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_zombie_hit_normal); index++)
	{
		ArrayGetString(g_sound_zombie_hit_normal, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_zombie_hit_stab); index++)
	{
		ArrayGetString(g_sound_zombie_hit_stab, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_zombie_idle); index++)
	{
		ArrayGetString(g_sound_zombie_idle, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_zombie_idle_last); index++)
	{
		ArrayGetString(g_sound_zombie_idle_last, index, sound, charsmax(sound))
		precache_sound(sound)
	}
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

// Emit Sound Forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Replace these next sounds for zombies only
	if (!is_user_connected(id) || !zp_core_is_zombie(id))
		return FMRES_IGNORED;
	
	static sound[SOUND_MAX_LENGTH]
	if (get_pcvar_num(cvar_zombie_sounds_pain))
	{
		// Zombie being hit
		if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
		{
			// Nemesis Class loaded?
			if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
			{
				ArrayGetString(g_sound_nemesis_pain, random_num(0, ArraySize(g_sound_nemesis_pain) - 1), sound, charsmax(sound))
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			ArrayGetString(g_sound_zombie_pain, random_num(0, ArraySize(g_sound_zombie_pain) - 1), sound, charsmax(sound))
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
		
		// Zombie dies
		if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
		{
			ArrayGetString(g_sound_zombie_die, random_num(0, ArraySize(g_sound_zombie_die) - 1), sound, charsmax(sound))
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
		
		// Zombie falls off
		if (sample[10] == 'f' && sample[11] == 'a' && sample[12] == 'l' && sample[13] == 'l')
		{
			ArrayGetString(g_sound_zombie_fall, random_num(0, ArraySize(g_sound_zombie_fall) - 1), sound, charsmax(sound))
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	}
	
	if (get_pcvar_num(cvar_zombie_sounds_attack))
	{
		// Zombie attacks with knife
		if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
		{
			if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // slash
			{
				ArrayGetString(g_sound_zombie_miss_slash, random_num(0, ArraySize(g_sound_zombie_miss_slash) - 1), sound, charsmax(sound))
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
			{
				if (sample[17] == 'w') // wall
				{
					ArrayGetString(g_sound_zombie_miss_wall, random_num(0, ArraySize(g_sound_zombie_miss_wall) - 1), sound, charsmax(sound))
					emit_sound(id, channel, sound, volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
				else
				{
					ArrayGetString(g_sound_zombie_hit_normal, random_num(0, ArraySize(g_sound_zombie_hit_normal) - 1), sound, charsmax(sound))
					emit_sound(id, channel, sound, volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
			}
			if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
			{
				ArrayGetString(g_sound_zombie_hit_stab, random_num(0, ArraySize(g_sound_zombie_hit_stab) - 1), sound, charsmax(sound))
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
		}
	}
	
	return FMRES_IGNORED;
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Remove idle sounds task
	remove_task(victim+TASK_IDLE_SOUNDS)
}

public client_disconnect(id)
{
	// Remove idle sounds task
	remove_task(id+TASK_IDLE_SOUNDS)
}

public zp_fw_core_infect_post(id, attacker)
{
	// Remove previous tasks
	remove_task(id+TASK_IDLE_SOUNDS)
	
	// Nemesis Class loaded?
	if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library) || !zp_class_nemesis_get(id))
	{
		// Idle sounds?
		if (get_pcvar_num(cvar_zombie_sounds_idle))
			set_task(random_float(50.0, 70.0), "zombie_idle_sounds", id+TASK_IDLE_SOUNDS, _, _, "b")
	}
}

public zp_fw_core_cure_post(id, attacker)
{
	// Remove idle sounds task
	remove_task(id+TASK_IDLE_SOUNDS)
}

// Play idle zombie sounds
public zombie_idle_sounds(taskid)
{
	static sound[SOUND_MAX_LENGTH]
	
	// Last zombie?
	if (zp_core_is_last_zombie(ID_IDLE_SOUNDS))
	{
		ArrayGetString(g_sound_zombie_idle_last, random_num(0, ArraySize(g_sound_zombie_idle_last) - 1), sound, charsmax(sound))
		emit_sound(ID_IDLE_SOUNDS, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else
	{
		ArrayGetString(g_sound_zombie_idle, random_num(0, ArraySize(g_sound_zombie_idle) - 1), sound, charsmax(sound))
		emit_sound(ID_IDLE_SOUNDS, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}
