/*================================================================================
	
	---------------------------------
	-*- [ZP] Item: Infection Bomb -*-
	---------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#define ITEM_NAME "Infection Bomb"
#define ITEM_COST 20

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_weap_models_api>
#include <zp50_items>
#include <zp50_gamemodes>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_grenade_infect_explode[][] = { "zombie_plague/grenade_infect.wav" }
new const sound_grenade_infect_player[][] = { "scientist/scream20.wav" , "scientist/scream22.wav" , "scientist/scream05.wav" }

#define MODEL_MAX_LENGTH 64
#define SOUND_MAX_LENGTH 64
#define SPRITE_MAX_LENGTH 64

// Models
new g_model_grenade_infect[MODEL_MAX_LENGTH] = "models/zombie_plague/v_grenade_infect.mdl"

// Sprites
new g_sprite_grenade_trail[SPRITE_MAX_LENGTH] = "sprites/laserbeam.spr"
new g_sprite_grenade_ring[SPRITE_MAX_LENGTH] = "sprites/shockwave.spr"

new Array:g_sound_grenade_infect_explode
new Array:g_sound_grenade_infect_player

// Explosion radius for custom grenades
const Float:NADE_EXPLOSION_RADIUS = 240.0

// HACK: pev_ field used to store custom nade types and their values
const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_INFECTION = 1111

new g_trailSpr, g_exploSpr

new g_ItemID
new g_GameModeInfectionID
new g_GameModeMultiID
new g_InfectionBombCounter, cvar_infection_bomb_round_limit

public plugin_init()
{
	register_plugin("[ZP] Item: Infection Bomb", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	
	g_ItemID = zp_items_register(ITEM_NAME, ITEM_COST)
	cvar_infection_bomb_round_limit = register_cvar("zp_infection_bomb_round_limit", "3")
}

public plugin_precache()
{
	// Initialize arrays
	g_sound_grenade_infect_explode = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_grenade_infect_player = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE INFECT EXPLODE", g_sound_grenade_infect_explode)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE INFECT PLAYER", g_sound_grenade_infect_player)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_grenade_infect_explode) == 0)
	{
		for (index = 0; index < sizeof sound_grenade_infect_explode; index++)
			ArrayPushString(g_sound_grenade_infect_explode, sound_grenade_infect_explode[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE INFECT EXPLODE", g_sound_grenade_infect_explode)
	}
	if (ArraySize(g_sound_grenade_infect_player) == 0)
	{
		for (index = 0; index < sizeof sound_grenade_infect_player; index++)
			ArrayPushString(g_sound_grenade_infect_player, sound_grenade_infect_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE INFECT PLAYER", g_sound_grenade_infect_player)
	}
	
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "GRENADE INFECT", g_model_grenade_infect, charsmax(g_model_grenade_infect)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "GRENADE INFECT", g_model_grenade_infect)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "TRAIL", g_sprite_grenade_trail, charsmax(g_sprite_grenade_trail)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "TRAIL", g_sprite_grenade_trail)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "RING", g_sprite_grenade_ring, charsmax(g_sprite_grenade_ring)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "RING", g_sprite_grenade_ring)
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_grenade_infect_explode); index++)
	{
		ArrayGetString(g_sound_grenade_infect_explode, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_grenade_infect_player); index++)
	{
		ArrayGetString(g_sound_grenade_infect_player, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	
	// Precache models
	precache_model(g_model_grenade_infect)
	g_trailSpr = precache_model(g_sprite_grenade_trail)
	g_exploSpr = precache_model(g_sprite_grenade_ring)
}

public plugin_cfg()
{
	g_GameModeInfectionID = zp_gamemodes_get_id("Infection Mode")
	g_GameModeMultiID = zp_gamemodes_get_id("Multiple Infection Mode")
}

public event_round_start()
{
	g_InfectionBombCounter = 0
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_ItemID)
		return ZP_ITEM_AVAILABLE;
	
	// Infection bomb only available during infection modes
	new current_mode = zp_gamemodes_get_current()
	if (current_mode != g_GameModeInfectionID && current_mode != g_GameModeMultiID)
		return ZP_ITEM_DONT_SHOW;
	
	// Infection bomb only available to zombies
	if (!zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW;
	
	// Display remaining item count for this round
	static text[32]
	formatex(text, charsmax(text), "[%d/%d]", g_InfectionBombCounter, get_pcvar_num(cvar_infection_bomb_round_limit))
	zp_items_menu_text_add(text)
	
	// Reached infection bomb limit for this round
	if (g_InfectionBombCounter >= get_pcvar_num(cvar_infection_bomb_round_limit))
		return ZP_ITEM_NOT_AVAILABLE;
	
	// Player already owns infection bomb
	if (user_has_weapon(id, CSW_HEGRENADE))
		return ZP_ITEM_NOT_AVAILABLE;
	
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_ItemID)
		return;
	
	// Give infection bomb
	give_item(id, "weapon_hegrenade")
	g_InfectionBombCounter++
}

public zp_fw_core_cure(id, attacker)
{
	// Remove custom grenade model
	cs_reset_player_view_model(id, CSW_HEGRENADE)
}

public zp_fw_core_infect_post(id, attacker)
{
	// Set custom grenade model
	cs_set_player_view_model(id, CSW_HEGRENADE, g_model_grenade_infect)
}

// Forward Set Model
public fw_SetModel(entity, const model[])
{
	// We don't care
	if (strlen(model) < 8)
		return;
	
	// Narrow down our matches a bit
	if (model[7] != 'w' || model[8] != '_')
		return;
	
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Grenade not yet thrown
	if (dmgtime == 0.0)
		return;
	
	// Grenade's owner isn't zombie?
	if (!zp_core_is_zombie(pev(entity, pev_owner)))
		return;
	
	// HE Grenade
	if (model[9] == 'h' && model[10] == 'e')
	{
		// Give it a glow
		fm_set_rendering(entity, kRenderFxGlowShell, 0, 200, 0, kRenderNormal, 16);
		
		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(entity) // entity
		write_short(g_trailSpr) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(0) // r
		write_byte(200) // g
		write_byte(0) // b
		write_byte(200) // brightness
		message_end()
		
		// Set grenade type on the thrown grenade entity
		set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_INFECTION)
	}
}

// Ham Grenade Think Forward
public fw_ThinkGrenade(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return HAM_IGNORED;
	
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Check if it's time to go off
	if (dmgtime > get_gametime())
		return HAM_IGNORED;
	
	// Check if it's one of our custom nades
	switch (pev(entity, PEV_NADE_TYPE))
	{
		case NADE_TYPE_INFECTION: // Infection Bomb
		{
			infection_explode(entity)
			return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}

// Infection Bomb Explosion
infection_explode(ent)
{
	// Round ended
	if (zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
	{
		// Get rid of the grenade
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}
	
	// Get origin
	static Float:origin[3]
	pev(ent, pev_origin, origin)
	
	// Make the explosion
	create_blast(origin)
	
	// Infection nade explode sound
	static sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_sound_grenade_infect_explode, random_num(0, ArraySize(g_sound_grenade_infect_explode) - 1), sound, charsmax(sound))
	emit_sound(ent, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Get attacker
	new attacker = pev(ent, pev_owner)
	
	// Infection bomb owner disconnected or not zombie anymore?
	if (!is_user_connected(attacker) || !zp_core_is_zombie(attacker))
	{
		// Get rid of the grenade
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}
	
	// Collisions
	new victim = -1
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, origin, NADE_EXPLOSION_RADIUS)) != 0)
	{
		// Only effect alive humans
		if (!is_user_alive(victim) || zp_core_is_zombie(victim))
			continue;
		
		// Last human is killed
		if (zp_core_get_human_count() == 1)
		{
			ExecuteHamB(Ham_Killed, victim, attacker, 0)
			continue;
		}
		
		// Turn into zombie
		zp_core_infect(victim, attacker)
		
		// Victim's sound
		ArrayGetString(g_sound_grenade_infect_player, random_num(0, ArraySize(g_sound_grenade_infect_player) - 1), sound, charsmax(sound))
		emit_sound(victim, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	// Get rid of the grenade
	engfunc(EngFunc_RemoveEntity, ent)
}

// Infection Bomb: Green Blast
create_blast(const Float:origin[3])
{
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+385.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(200) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+470.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(200) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+555.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(200) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

// Set entity's rendering type (from fakemeta_util)
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}