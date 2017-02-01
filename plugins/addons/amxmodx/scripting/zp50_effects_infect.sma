/*================================================================================
	
	----------------------------
	-*- [ZP] Effects: Infect -*-
	----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <hlsdk_const>
#include <amx_settings_api>
#include <zp50_core>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_infect[][] = { "zombie_plague/zombie_infec1.wav" , "zombie_plague/zombie_infec2.wav" , "zombie_plague/zombie_infec3.wav" , "scientist/c1a0_sci_catscream.wav" , "scientist/scream01.wav" }

#define SOUND_MAX_LENGTH 64

// Custom sounds
new Array:g_sound_infect

// HUD messages
#define HUD_INFECT_X 0.05
#define HUD_INFECT_Y 0.45
#define HUD_INFECT_R 255
#define HUD_INFECT_G 0
#define HUD_INFECT_B 0

// Some constants
const UNIT_SECOND = (1<<12)
const FFADE_IN = 0x0000

new g_HudSync
new g_MsgDeathMsg, g_MsgScoreAttrib
new g_MsgScreenFade, g_MsgScreenShake, g_MsgDamage

new cvar_infect_show_hud
new cvar_infect_show_notice
new cvar_infect_sounds

new cvar_infect_screen_fade, cvar_infect_screen_fade_R, cvar_infect_screen_fade_G, cvar_infect_screen_fade_B
new cvar_infect_screen_shake
new cvar_infect_hud_icon
new cvar_infect_tracers
new cvar_infect_particles
new cvar_infect_sparkle, cvar_infect_sparkle_R, cvar_infect_sparkle_G, cvar_infect_sparkle_B

public plugin_init()
{
	register_plugin("[ZP] Effects: Infect", ZP_VERSION_STRING, "ZP Dev Team")
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MsgDeathMsg = get_user_msgid("DeathMsg")
	g_MsgScoreAttrib = get_user_msgid("ScoreAttrib")
	g_MsgScreenFade = get_user_msgid("ScreenFade")
	g_MsgScreenShake = get_user_msgid("ScreenShake")
	g_MsgDamage = get_user_msgid("Damage")
	
	cvar_infect_show_hud = register_cvar("zp_infect_show_hud", "1")
	cvar_infect_show_notice = register_cvar("zp_infect_show_notice", "1")
	cvar_infect_sounds = register_cvar("zp_infect_sounds", "1")
	
	cvar_infect_screen_fade = register_cvar("zp_infect_screen_fade", "1")
	cvar_infect_screen_fade_R = register_cvar("zp_infect_screen_fade_R", "0")
	cvar_infect_screen_fade_G = register_cvar("zp_infect_screen_fade_G", "150")
	cvar_infect_screen_fade_B = register_cvar("zp_infect_screen_fade_B", "0")
	cvar_infect_screen_shake = register_cvar("zp_infect_screen_shake", "1")
	cvar_infect_hud_icon = register_cvar("zp_infect_hud_icon", "1")
	cvar_infect_tracers = register_cvar("zp_infect_tracers", "1")
	cvar_infect_particles = register_cvar("zp_infect_particles", "1")
	cvar_infect_sparkle = register_cvar("zp_infect_sparkle", "1")
	cvar_infect_sparkle_R = register_cvar("zp_infect_sparkle_R", "0")
	cvar_infect_sparkle_G = register_cvar("zp_infect_sparkle_G", "150")
	cvar_infect_sparkle_B = register_cvar("zp_infect_sparkle_B", "0")
}

public plugin_precache()
{
	// Initialize arrays
	g_sound_infect = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE INFECT", g_sound_infect)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_infect) == 0)
	{
		for (index = 0; index < sizeof sound_infect; index++)
			ArrayPushString(g_sound_infect, sound_infect[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE INFECT", g_sound_infect)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_infect); index++)
	{
		ArrayGetString(g_sound_infect, index, sound, charsmax(sound))
		precache_sound(sound)
	}
}

public zp_fw_core_infect_post(id, attacker)
{	
	// Attacker is valid?
	if (is_user_connected(attacker))
	{
		// Infection sounds?
		if (get_pcvar_num(cvar_infect_sounds))
		{
			static sound[SOUND_MAX_LENGTH]
			ArrayGetString(g_sound_infect, random_num(0, ArraySize(g_sound_infect) - 1), sound, charsmax(sound))
			emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		
		// Player infected himself
		if (attacker == id)
		{
			// Show Infection HUD notice? (except for first zombie)
			if (get_pcvar_num(cvar_infect_show_hud) && !zp_core_is_first_zombie(id))
			{
				new victim_name[32]
				get_user_name(id, victim_name, charsmax(victim_name))
				set_hudmessage(HUD_INFECT_R, HUD_INFECT_G, HUD_INFECT_B, HUD_INFECT_X, HUD_INFECT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
				ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_INFECT", victim_name)
			}
		}
		else
		{
			// Show Infection HUD notice?
			if (get_pcvar_num(cvar_infect_show_hud))
			{
				new attacker_name[32], victim_name[32]
				get_user_name(attacker, attacker_name, charsmax(attacker_name))
				get_user_name(id, victim_name, charsmax(victim_name))
				set_hudmessage(HUD_INFECT_R, HUD_INFECT_G, HUD_INFECT_B, HUD_INFECT_X, HUD_INFECT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
				ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_INFECT2", victim_name, attacker_name)
			}
			
			// Show infection death notice?
			if (get_pcvar_num(cvar_infect_show_notice))
			{
				// Send death notice and fix the "dead" attrib on scoreboard
				SendDeathMsg(attacker, id)
				FixDeadAttrib(id)
			}
		}
	}
	
	// Infection special effects
	infection_effects(id)
}

infection_effects(id)
{
	// Screen fade?
	if (get_pcvar_num(cvar_infect_screen_fade))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
		write_short(UNIT_SECOND) // duration
		write_short(0) // hold time
		write_short(FFADE_IN) // fade type
		write_byte(get_pcvar_num(cvar_infect_screen_fade_R)) // r
		write_byte(get_pcvar_num(cvar_infect_screen_fade_G)) // g
		write_byte(get_pcvar_num(cvar_infect_screen_fade_B)) // b
		write_byte (255) // alpha
		message_end()
	}
	
	// Screen shake?
	if (get_pcvar_num(cvar_infect_screen_shake))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenShake, _, id)
		write_short(UNIT_SECOND*4) // amplitude
		write_short(UNIT_SECOND*2) // duration
		write_short(UNIT_SECOND*10) // frequency
		message_end()
	}
	
	// Infection icon?
	if (get_pcvar_num(cvar_infect_hud_icon))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgDamage, _, id)
		write_byte(0) // damage save
		write_byte(0) // damage take
		write_long(DMG_NERVEGAS) // damage type - DMG_RADIATION
		write_coord(0) // x
		write_coord(0) // y
		write_coord(0) // z
		message_end()
	}
	
	// Get player's origin
	new origin[3]
	get_user_origin(id, origin)
	
	// Tracers?
	if (get_pcvar_num(cvar_infect_tracers))
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_IMPLOSION) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]) // z
		write_byte(128) // radius
		write_byte(20) // count
		write_byte(3) // duration
		message_end()
	}
	
	// Particle burst?
	if (get_pcvar_num(cvar_infect_particles))
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_PARTICLEBURST) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]) // z
		write_short(50) // radius
		write_byte(70) // color
		write_byte(3) // duration (will be randomized a bit)
		message_end()
	}
	
	// Light sparkle?
	if (get_pcvar_num(cvar_infect_sparkle))
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_DLIGHT) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]) // z
		write_byte(20) // radius
		write_byte(get_pcvar_num(cvar_infect_sparkle_R)) // r
		write_byte(get_pcvar_num(cvar_infect_sparkle_G)) // g
		write_byte(get_pcvar_num(cvar_infect_sparkle_B)) // b
		write_byte(2) // life
		write_byte(0) // decay rate
		message_end()
	}
}

// Send Death Message for infections
SendDeathMsg(attacker, victim)
{
	message_begin(MSG_BROADCAST, g_MsgDeathMsg)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(1) // headshot flag
	write_string("infection") // killer's weapon
	message_end()
}

// Fix Dead Attrib on scoreboard
FixDeadAttrib(id)
{
	message_begin(MSG_BROADCAST, g_MsgScoreAttrib)
	write_byte(id) // id
	write_byte(0) // attrib
	message_end()
}
