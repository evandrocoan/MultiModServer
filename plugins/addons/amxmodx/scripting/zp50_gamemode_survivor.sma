/*================================================================================
	
	--------------------------------
	-*- [ZP] Game Mode: Survivor -*-
	--------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amx_settings_api>
#include <zp50_gamemodes>
#include <zp50_class_survivor>
#include <zp50_deathmatch>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_survivor[][] = { "zombie_plague/survivor1.wav" , "zombie_plague/survivor2.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_survivor

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 20
#define HUD_EVENT_G 20
#define HUD_EVENT_B 255

new g_MaxPlayers
new g_HudSync
new g_TargetPlayer

new cvar_survivor_chance, cvar_survivor_min_players
new cvar_survivor_show_hud, cvar_survivor_sounds
new cvar_survivor_allow_respawn

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Survivor", ZP_VERSION_STRING, "ZP Dev Team")
	zp_gamemodes_register("Survivor Mode")
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_survivor_chance = register_cvar("zp_survivor_chance", "20")
	cvar_survivor_min_players = register_cvar("zp_survivor_min_players", "0")
	cvar_survivor_show_hud = register_cvar("zp_survivor_show_hud", "1")
	cvar_survivor_sounds = register_cvar("zp_survivor_sounds", "1")
	cvar_survivor_allow_respawn = register_cvar("zp_survivor_allow_respawn", "0")
	
	// Initialize arrays
	g_sound_survivor = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND SURVIVOR", g_sound_survivor)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_survivor) == 0)
	{
		for (index = 0; index < sizeof sound_survivor; index++)
			ArrayPushString(g_sound_survivor, sound_survivor[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND SURVIVOR", g_sound_survivor)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_survivor); index++)
	{
		ArrayGetString(g_sound_survivor, index, sound, charsmax(sound))
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
	if (!get_pcvar_num(cvar_survivor_allow_respawn))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	// Always respawn as zombie on survivor rounds
	zp_core_respawn_as_zombie(id, true)
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_survivor_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_survivor_min_players))
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_post(game_mode_id, target_player)
{
	// Pick player randomly?
	g_TargetPlayer = (target_player == RANDOM_TARGET_PLAYER) ? GetRandomAlive(random_num(1, GetAliveCount())) : target_player
}

public zp_fw_gamemodes_start()
{
	// Turn player into survivor
	zp_class_survivor_set(g_TargetPlayer)
	
	// Turn the remaining players into zombies
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Not alive
		if (!is_user_alive(id))
			continue;
		
		// Survivor or already a zombie
		if (zp_class_survivor_get(id) || zp_core_is_zombie(id))
			continue;
		
		zp_core_infect(id)
	}
	
	// Play Survivor sound
	if (get_pcvar_num(cvar_survivor_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_survivor, random_num(0, ArraySize(g_sound_survivor) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_survivor_show_hud))
	{
		// Show Survivor HUD notice
		new name[32]
		get_user_name(g_TargetPlayer, name, charsmax(name))
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_SURVIVOR", name)
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

// Get Random Alive -returns index of alive player number target_index -
GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}