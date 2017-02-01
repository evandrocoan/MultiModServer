/*================================================================================
	
	--------------------------
	-*- [ZP] Effects: Cure -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amx_settings_api>
#include <zp50_core>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_cure[][] = { "items/smallmedkit1.wav" }

#define SOUND_MAX_LENGTH 64

// Custom sounds
new Array:g_sound_cure

// HUD messages
#define HUD_CURE_X 0.05
#define HUD_CURE_Y 0.40
#define HUD_CURE_R 0
#define HUD_CURE_G 0
#define HUD_CURE_B 255

new g_HudSync

new cvar_cure_show_hud
new cvar_cure_sounds

public plugin_init()
{
	register_plugin("[ZP] Effects: Cure", ZP_VERSION_STRING, "ZP Dev Team")
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	cvar_cure_show_hud = register_cvar("zp_cure_show_hud", "1")
	cvar_cure_sounds = register_cvar("zp_cure_sounds", "1")
}

public plugin_precache()
{
	// Initialize arrays
	g_sound_cure = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ANTIDOTE", g_sound_cure)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_cure) == 0)
	{
		for (index = 0; index < sizeof sound_cure; index++)
			ArrayPushString(g_sound_cure, sound_cure[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ANTIDOTE", g_sound_cure)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_cure); index++)
	{
		ArrayGetString(g_sound_cure, index, sound, charsmax(sound))
		precache_sound(sound)
	}
}

public zp_fw_core_cure_post(id, attacker)
{	
	// Attacker is valid?
	if (is_user_connected(attacker))
	{
		// Antidote sound?
		if (get_pcvar_num(cvar_cure_sounds))
		{
			static sound[SOUND_MAX_LENGTH]
			ArrayGetString(g_sound_cure, random_num(0, ArraySize(g_sound_cure) - 1), sound, charsmax(sound))
			emit_sound(id, CHAN_ITEM, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		
		// Player cured himself
		if (attacker == id)
		{		
			// Show Antidote HUD notice?
			if (get_pcvar_num(cvar_cure_show_hud))
			{
				new victim_name[32]
				get_user_name(id, victim_name, charsmax(victim_name))
				set_hudmessage(HUD_CURE_R, HUD_CURE_G, HUD_CURE_B, HUD_CURE_X, HUD_CURE_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
				ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_ANTIDOTE", victim_name)
			}
		}
		else
		{
			// Show Antidote HUD notice?
			if (get_pcvar_num(cvar_cure_show_hud))
			{
				new attacker_name[32], victim_name[32]
				get_user_name(attacker, attacker_name, charsmax(attacker_name))
				get_user_name(id, victim_name, charsmax(victim_name))
				set_hudmessage(HUD_CURE_R, HUD_CURE_G, HUD_CURE_B, HUD_CURE_X, HUD_CURE_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
				ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_ANTIDOTE2", attacker_name, victim_name)
			}
		}
	}
}
