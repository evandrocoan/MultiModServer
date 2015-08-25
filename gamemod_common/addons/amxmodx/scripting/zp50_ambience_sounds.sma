/*================================================================================
	
	----------------------------
	-*- [ZP] Ambience Sounds -*-
	----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amx_settings_api>
#include <zp50_gamemodes>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

#define TASK_AMBIENCESOUNDS 100

new Array:g_ambience_sounds_handle
new Array:g_ambience_durations_handle

public plugin_init()
{
	register_plugin("[ZP] Ambience Sonds", ZP_VERSION_STRING, "ZP Dev Team")
	register_event("30", "event_intermission", "a")
}

public plugin_precache()
{
	g_ambience_sounds_handle = ArrayCreate(1, 1)
	g_ambience_durations_handle = ArrayCreate(1, 1)
	
	new index, modename[32], key[64]
	for (index = 0; index < zp_gamemodes_get_count(); index++)
	{
		zp_gamemodes_get_name(index, modename, charsmax(modename))
		
		new Array:ambience_sounds = ArrayCreate(64, 1)
		formatex(key, charsmax(key), "SOUNDS (%s)", modename)
		amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Ambience Sounds", key, ambience_sounds)
		if (ArraySize(ambience_sounds) > 0)
		{
			// Precache ambience sounds
			new sound_index, sound[128]
			for (sound_index = 0; sound_index < ArraySize(ambience_sounds); sound_index++)
			{
				ArrayGetString(ambience_sounds, sound_index, sound, charsmax(sound))
				if (equal(sound[strlen(sound)-4], ".mp3"))
				{
					format(sound, charsmax(sound), "sound/%s", sound)
					precache_generic(sound)
				}
				else
					precache_sound(sound)
			}
		}
		else
		{
			ArrayDestroy(ambience_sounds)
			amx_save_setting_string(ZP_SETTINGS_FILE, "Ambience Sounds", key, "")
		}
		ArrayPushCell(g_ambience_sounds_handle, ambience_sounds)
		
		new Array:ambience_durations = ArrayCreate(1, 1)
		formatex(key, charsmax(key), "DURATIONS (%s)", modename)
		amx_load_setting_int_arr(ZP_SETTINGS_FILE, "Ambience Sounds", key, ambience_durations)
		if (ArraySize(ambience_durations) <= 0)
		{
			ArrayDestroy(ambience_durations)
			amx_save_setting_string(ZP_SETTINGS_FILE, "Ambience Sounds", key, "")
		}
		ArrayPushCell(g_ambience_durations_handle, ambience_durations)
	}
}

// Event Map Ended
public event_intermission()
{
	// Remove ambience sounds task
	remove_task(TASK_AMBIENCESOUNDS)
}

public zp_fw_gamemodes_end()
{
	// Stop ambience sounds
	remove_task(TASK_AMBIENCESOUNDS)
}

public zp_fw_gamemodes_start()
{
	// Start ambience sounds after a mode begins
	remove_task(TASK_AMBIENCESOUNDS)
	set_task(2.0, "ambience_sound_effects", TASK_AMBIENCESOUNDS)
}

// Ambience Sound Effects Task
public ambience_sound_effects(taskid)
{
	// Play a random sound depending on game mode
	new current_game_mode = zp_gamemodes_get_current()
	new Array:sounds_handle = ArrayGetCell(g_ambience_sounds_handle, current_game_mode)
	new Array:durations_handle = ArrayGetCell(g_ambience_durations_handle, current_game_mode)
	
	// No ambience sounds loaded for this mode
	if (sounds_handle == Invalid_Array || durations_handle == Invalid_Array)
		return;
	
	// Get random sound from array
	new sound[64], iRand, duration
	iRand = random_num(0, ArraySize(sounds_handle) - 1)
	ArrayGetString(sounds_handle, iRand, sound, charsmax(sound))
	duration = ArrayGetCell(durations_handle, iRand)
	
	// Play it on clients
	PlaySoundToClients(sound)
	
	// Set the task for when the sound is done playing
	set_task(float(duration), "ambience_sound_effects", TASK_AMBIENCESOUNDS)
}

// Plays a sound on clients
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}
