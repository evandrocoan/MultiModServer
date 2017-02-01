/*================================================================================
	
	-------------------------
	-*- [ZP] Team Scoring -*-
	-------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amx_settings_api>
#include <zp50_gamemodes>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_win_zombies[][] = { "ambience/the_horror1.wav" , "ambience/the_horror3.wav" , "ambience/the_horror4.wav" }
new const sound_win_humans[][] = { "zombie_plague/win_humans1.wav" , "zombie_plague/win_humans2.wav" }
new const sound_win_no_one[][] = { "ambience/3dmstart.wav" }

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.12

#define SOUND_MAX_LENGTH 64

// Custom sounds
new Array:g_sound_win_zombies
new Array:g_sound_win_humans
new Array:g_sound_win_no_one

new g_ScoreHumans, g_ScoreZombies
new g_HudSync

new cvar_winner_show_hud, cvar_winner_sounds

public plugin_init()
{
	register_plugin("[ZP] Team Scoring", ZP_VERSION_STRING, "ZP Dev Team")
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	register_message(get_user_msgid("TextMsg"), "message_textmsg")
	register_message(get_user_msgid("SendAudio"), "message_sendaudio")
	
	cvar_winner_show_hud = register_cvar("zp_winner_show_hud", "1")
	cvar_winner_sounds = register_cvar("zp_winner_sounds", "1")
}

public plugin_precache()
{
	// Initialize arrays
	g_sound_win_zombies = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_win_humans = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_win_no_one = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "WIN ZOMBIES", g_sound_win_zombies)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "WIN HUMANS", g_sound_win_humans)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "WIN NO ONE", g_sound_win_no_one)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_win_zombies) == 0)
	{
		for (index = 0; index < sizeof sound_win_zombies; index++)
			ArrayPushString(g_sound_win_zombies, sound_win_zombies[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "WIN ZOMBIES", g_sound_win_zombies)
	}
	if (ArraySize(g_sound_win_humans) == 0)
	{
		for (index = 0; index < sizeof sound_win_humans; index++)
			ArrayPushString(g_sound_win_humans, sound_win_humans[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "WIN HUMANS", g_sound_win_humans)
	}
	if (ArraySize(g_sound_win_no_one) == 0)
	{
		for (index = 0; index < sizeof sound_win_no_one; index++)
			ArrayPushString(g_sound_win_no_one, sound_win_no_one[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "WIN NO ONE", g_sound_win_no_one)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_win_zombies); index++)
	{
		ArrayGetString(g_sound_win_zombies, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_win_humans); index++)
	{
		ArrayGetString(g_sound_win_humans, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_win_no_one); index++)
	{
		ArrayGetString(g_sound_win_no_one, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
}

public zp_fw_gamemodes_end()
{
	// Determine round winner, show HUD notice
	new sound[SOUND_MAX_LENGTH]
	if (!zp_core_get_zombie_count())
	{
		// Human team wins
		if (get_pcvar_num(cvar_winner_show_hud))
		{
			set_hudmessage(0, 0, 200, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1)
			ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "WIN_HUMAN")
		}
		
		if (get_pcvar_num(cvar_winner_sounds))
		{
			ArrayGetString(g_sound_win_humans, random_num(0, ArraySize(g_sound_win_humans) - 1), sound, charsmax(sound))
			PlaySoundToClients(sound, 1)
		}
		
		g_ScoreHumans++
	}
	else if (!zp_core_get_human_count())
	{
		// Zombie team wins
		if (get_pcvar_num(cvar_winner_show_hud))
		{
			set_hudmessage(200, 0, 0, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1)
			ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "WIN_ZOMBIE")
		}
		
		if (get_pcvar_num(cvar_winner_sounds))
		{
			ArrayGetString(g_sound_win_zombies, random_num(0, ArraySize(g_sound_win_zombies) - 1), sound, charsmax(sound))
			PlaySoundToClients(sound, 1)
		}
		
		g_ScoreZombies++
	}
	else
	{
		// No one wins
		if (get_pcvar_num(cvar_winner_show_hud))
		{
			set_hudmessage(0, 200, 0, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1)
			ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "WIN_NO_ONE")
		}
		
		if (get_pcvar_num(cvar_winner_sounds))
		{
			ArrayGetString(g_sound_win_no_one, random_num(0, ArraySize(g_sound_win_no_one) - 1), sound, charsmax(sound))
			PlaySoundToClients(sound, 1)
		}
	}
}

// Block some text messages
public message_textmsg()
{
	new textmsg[22]
	get_msg_arg_string(2, textmsg, charsmax(textmsg))
	
	// Game restarting/game commencing, reset scores
	if (equal(textmsg, "#Game_will_restart_in") || equal(textmsg, "#Game_Commencing"))
	{
		g_ScoreHumans = 0
		g_ScoreZombies = 0
	}
	// Block round end related messages
	else if (equal(textmsg, "#Hostages_Not_Rescued") || equal(textmsg, "#Round_Draw") || equal(textmsg, "#Terrorists_Win") || equal(textmsg, "#CTs_Win"))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

// Block CS round win audio messages, since we're playing our own instead
public message_sendaudio()
{
	new audio[17]
	get_msg_arg_string(2, audio, charsmax(audio))
	
	if(equal(audio[7], "terwin") || equal(audio[7], "ctwin") || equal(audio[7], "rounddraw"))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

// Send actual team scores (T = zombies // CT = humans)
public message_teamscore()
{
	new team[2]
	get_msg_arg_string(1, team, charsmax(team))
	
	switch (team[0])
	{
		// CT
		case 'C': set_msg_arg_int(2, get_msg_argtype(2), g_ScoreHumans)
		// Terrorist
		case 'T': set_msg_arg_int(2, get_msg_argtype(2), g_ScoreZombies)
	}
}

// Plays a sound on clients
PlaySoundToClients(const sound[], stop_sounds_first = 0)
{
	if (stop_sounds_first)
	{
		if (equal(sound[strlen(sound)-4], ".mp3"))
			client_cmd(0, "stopsound; mp3 play ^"sound/%s^"", sound)
		else
			client_cmd(0, "mp3 stop; stopsound; spk ^"%s^"", sound)
	}
	else
	{
		if (equal(sound[strlen(sound)-4], ".mp3"))
			client_cmd(0, "mp3 play ^"sound/%s^"", sound)
		else
			client_cmd(0, "spk ^"%s^"", sound)
	}
}
