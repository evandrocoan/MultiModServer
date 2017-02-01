/*================================================================================
	
	-----------------------------
	-*- [ZP] Game Mode: Swarm -*-
	-----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <amx_settings_api>
#include <zp50_gamemodes>
#include <zp50_deathmatch>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_swarm[][] = { "ambience/the_horror2.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_swarm

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 20
#define HUD_EVENT_G 255
#define HUD_EVENT_B 20

new g_MaxPlayers
new g_HudSync

new cvar_swarm_chance, cvar_swarm_min_players
new cvar_swarm_show_hud, cvar_swarm_sounds
new cvar_swarm_allow_respawn

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Swarm", ZP_VERSION_STRING, "ZP Dev Team")
	zp_gamemodes_register("Swarm Mode")
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_swarm_chance = register_cvar("zp_swarm_chance", "20")
	cvar_swarm_min_players = register_cvar("zp_swarm_min_players", "0")
	cvar_swarm_show_hud = register_cvar("zp_swarm_show_hud", "1")
	cvar_swarm_sounds = register_cvar("zp_swarm_sounds", "1")
	cvar_swarm_allow_respawn = register_cvar("zp_swarm_allow_respawn", "0")
	
	// Initialize arrays
	g_sound_swarm = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND SWARM", g_sound_swarm)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_swarm) == 0)
	{
		for (index = 0; index < sizeof sound_swarm; index++)
			ArrayPushString(g_sound_swarm, sound_swarm[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND SWARM", g_sound_swarm)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_swarm); index++)
	{
		ArrayGetString(g_sound_swarm, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
}

// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_swarm_allow_respawn))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_swarm_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_swarm_min_players))
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_start()
{
	new id
	
	// Turn every Terrorist into a zombie
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Not alive
		if (!is_user_alive(id))
			continue;
		
		// Not a Terrorist
		if (cs_get_user_team(id) != CS_TEAM_T)
			continue;
		
		// Turn into a zombie
		zp_core_infect(id, 0)
	}
	
	// Play swarm sound
	if (get_pcvar_num(cvar_swarm_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_swarm, random_num(0, ArraySize(g_sound_swarm) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_swarm_show_hud))
	{
		// Show Swarm HUD notice
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_SWARM")
	}
}

// Plays a sound on clients
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}