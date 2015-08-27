/*================================================================================
	
	---------------------------
	-*- [ZP] Grenade: Frost -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_weap_models_api>
#include <cs_ham_bots_api>
#include <zp50_core>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_grenade_frost_explode[][] = { "warcraft3/frostnova.wav" }
new const sound_grenade_frost_player[][] = { "warcraft3/impalehit.wav" }
new const sound_grenade_frost_break[][] = { "warcraft3/impalelaunch1.wav" }

#define MODEL_MAX_LENGTH 64
#define SOUND_MAX_LENGTH 64
#define SPRITE_MAX_LENGTH 64

// Models
new g_model_grenade_frost[MODEL_MAX_LENGTH] = "models/zombie_plague/v_grenade_frost.mdl"

// Sprites
new g_sprite_grenade_trail[SPRITE_MAX_LENGTH] = "sprites/laserbeam.spr"
new g_sprite_grenade_ring[SPRITE_MAX_LENGTH] = "sprites/shockwave.spr"
new g_sprite_grenade_glass[SPRITE_MAX_LENGTH] = "models/glassgibs.mdl"

new Array:g_sound_grenade_frost_explode
new Array:g_sound_grenade_frost_player
new Array:g_sound_grenade_frost_break

#define GRAVITY_HIGH 999999.9
#define GRAVITY_NONE 0.000001

#define TASK_FROST_REMOVE 100
#define ID_FROST_REMOVE (taskid - TASK_FROST_REMOVE)

#define MAXPLAYERS 32

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

// Hack to be able to use Ham_Player_ResetMaxSpeed (by joaquimandrade)
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame

// Explosion radius for custom grenades
const Float:NADE_EXPLOSION_RADIUS = 240.0

// HACK: pev_ field used to store custom nade types and their values
const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_FROST = 3333

// Some constants
const UNIT_SECOND = (1<<12)
const BREAK_GLASS = 0x01
const FFADE_IN = 0x0000
const FFADE_STAYOUT = 0x0004

// Custom Forwards
enum _:TOTAL_FORWARDS
{
	FW_USER_FREEZE_PRE = 0,
	FW_USER_UNFROZEN
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_IsFrozen
new Float:g_FrozenGravity[MAXPLAYERS+1]
new g_FrozenRenderingFx[MAXPLAYERS+1]
new Float:g_FrozenRenderingColor[MAXPLAYERS+1][3]
new g_FrozenRenderingRender[MAXPLAYERS+1]
new Float:g_FrozenRenderingAmount[MAXPLAYERS+1]

new g_MsgDamage, g_MsgScreenFade
new g_trailSpr, g_exploSpr, g_glassSpr

new cvar_grenade_frost_duration, cvar_grenade_frost_hudicon

public plugin_init()
{
	register_plugin("[ZP] Grenade: Frost", ZP_VERSION_STRING, "ZP Dev Team")
	
	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "fw_ResetMaxSpeed_Post", 1)
	RegisterHamBots(Ham_Player_ResetMaxSpeed, "fw_ResetMaxSpeed_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHamBots(Ham_TraceAttack, "fw_TraceAttack")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	
	g_MsgDamage = get_user_msgid("Damage")
	g_MsgScreenFade = get_user_msgid("ScreenFade")
	
	cvar_grenade_frost_duration = register_cvar("zp_grenade_frost_duration", "3")
	cvar_grenade_frost_hudicon = register_cvar("zp_grenade_frost_hudicon", "1")
	
	g_Forwards[FW_USER_FREEZE_PRE] = CreateMultiForward("zp_fw_grenade_frost_pre", ET_CONTINUE, FP_CELL)
	g_Forwards[FW_USER_UNFROZEN] = CreateMultiForward("zp_fw_grenade_frost_unfreeze", ET_IGNORE, FP_CELL)
}

public plugin_natives()
{
	register_library("zp50_grenade_frost")
	register_native("zp_grenade_frost_get", "native_grenade_frost_get")
	register_native("zp_grenade_frost_set", "native_grenade_frost_set")
}

public native_grenade_frost_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return flag_get_boolean(g_IsFrozen, id);
}

public native_grenade_frost_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new set = get_param(2)
	
	// Unfreeze
	if (!set)
	{
		// Not frozen
		if (!flag_get(g_IsFrozen, id))
			return true;
		
		// Remove freeze right away and stop the task
		remove_freeze(id+TASK_FROST_REMOVE)
		remove_task(id+TASK_FROST_REMOVE)
		return true;
	}
	
	return set_freeze(id);
}

public plugin_precache()
{
	// Initialize arrays
	g_sound_grenade_frost_explode = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_grenade_frost_player = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_grenade_frost_break = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE FROST EXPLODE", g_sound_grenade_frost_explode)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE FROST PLAYER", g_sound_grenade_frost_player)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE FROST BREAK", g_sound_grenade_frost_break)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_grenade_frost_explode) == 0)
	{
		for (index = 0; index < sizeof sound_grenade_frost_explode; index++)
			ArrayPushString(g_sound_grenade_frost_explode, sound_grenade_frost_explode[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE FROST EXPLODE", g_sound_grenade_frost_explode)
	}
	if (ArraySize(g_sound_grenade_frost_player) == 0)
	{
		for (index = 0; index < sizeof sound_grenade_frost_player; index++)
			ArrayPushString(g_sound_grenade_frost_player, sound_grenade_frost_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE FROST PLAYER", g_sound_grenade_frost_player)
	}
	if (ArraySize(g_sound_grenade_frost_break) == 0)
	{
		for (index = 0; index < sizeof sound_grenade_frost_break; index++)
			ArrayPushString(g_sound_grenade_frost_break, sound_grenade_frost_break[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE FROST BREAK", g_sound_grenade_frost_break)
	}
	
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "GRENADE FROST", g_model_grenade_frost, charsmax(g_model_grenade_frost)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "GRENADE FROST", g_model_grenade_frost)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "TRAIL", g_sprite_grenade_trail, charsmax(g_sprite_grenade_trail)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "TRAIL", g_sprite_grenade_trail)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "RING", g_sprite_grenade_ring, charsmax(g_sprite_grenade_ring)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "RING", g_sprite_grenade_ring)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "GLASS", g_sprite_grenade_glass, charsmax(g_sprite_grenade_glass)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "GLASS", g_sprite_grenade_glass)
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_grenade_frost_explode); index++)
	{
		ArrayGetString(g_sound_grenade_frost_explode, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_grenade_frost_player); index++)
	{
		ArrayGetString(g_sound_grenade_frost_player, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_grenade_frost_break); index++)
	{
		ArrayGetString(g_sound_grenade_frost_break, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	
	// Precache models
	precache_model(g_model_grenade_frost)
	g_trailSpr = precache_model(g_sprite_grenade_trail)
	g_exploSpr = precache_model(g_sprite_grenade_ring)
	g_glassSpr = precache_model(g_sprite_grenade_glass)
}

public zp_fw_core_cure_post(id, attacker)
{
	// Set custom grenade model
	cs_set_player_view_model(id, CSW_FLASHBANG, g_model_grenade_frost)
	
	// If frozen, remove freeze after player is cured
	if (flag_get(g_IsFrozen, id))
	{
		// Update gravity and rendering values first
		ApplyFrozenGravity(id)
		ApplyFrozenRendering(id)
		
		// Remove freeze right away and stop the task
		remove_freeze(id+TASK_FROST_REMOVE)
		remove_task(id+TASK_FROST_REMOVE)
	}
}

public zp_fw_core_infect(id, attacker)
{
	// Remove custom grenade model
	cs_reset_player_view_model(id, CSW_FLASHBANG)
}

public zp_fw_core_infect_post(id, attacker)
{
	// If frozen, update gravity and rendering
	if (flag_get(g_IsFrozen, id))
	{
		ApplyFrozenGravity(id)
		ApplyFrozenRendering(id)
	}
}

public client_disconnect(id)
{
	flag_unset(g_IsFrozen, id)
	remove_task(id+TASK_FROST_REMOVE)
}

public fw_ResetMaxSpeed_Post(id)
{
	// Dead or not frozen
	if (!is_user_alive(id) || !flag_get(g_IsFrozen, id))
		return;
	
	// Prevent from moving
	set_user_maxspeed(id, 1.0)
}

// Ham Trace Attack Forward
public fw_TraceAttack(victim, attacker)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Block damage while frozen, as it makes killing zombies too easy
	if (flag_get(g_IsFrozen, victim))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Take Damage Forward (needed to block explosion damage too)
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Block damage while frozen, as it makes killing zombies too easy
	if (flag_get(g_IsFrozen, victim))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Frozen player being killed (usually caused by a 3rd party plugin, e.g. lasermines)
	if (flag_get(g_IsFrozen, victim))
	{
		// Remove freeze right away and stop the task
		remove_freeze(victim+TASK_FROST_REMOVE)
		remove_task(victim+TASK_FROST_REMOVE)
	}
}

// Forward Player PreThink
public fw_PlayerPreThink(id)
{
	// Not alive or not frozen
	if (!is_user_alive(id) || !flag_get(g_IsFrozen, id))
		return;
	
	// Stop motion
	set_pev(id, pev_velocity, Float:{0.0,0.0,0.0})
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
	
	// Grenade's owner is zombie?
	if (zp_core_is_zombie(pev(entity, pev_owner)))
		return;
	
	// Flashbang
	if (model[9] == 'f' && model[10] == 'l')
	{
		// Give it a glow
		fm_set_rendering(entity, kRenderFxGlowShell, 0, 100, 200, kRenderNormal, 16);
		
		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(entity) // entity
		write_short(g_trailSpr) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(0) // r
		write_byte(100) // g
		write_byte(200) // b
		write_byte(200) // brightness
		message_end()
		
		// Set grenade type on the thrown grenade entity
		set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_FROST)
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
		case NADE_TYPE_FROST: // Frost Grenade
		{
			frost_explode(entity)
			return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}

// Frost Grenade Explosion
frost_explode(ent)
{
	// Get origin
	static Float:origin[3]
	pev(ent, pev_origin, origin)
	
	// Make the explosion
	create_blast3(origin)
	
	// Frost nade explode sound
	static sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_sound_grenade_frost_explode, random_num(0, ArraySize(g_sound_grenade_frost_explode) - 1), sound, charsmax(sound))
	emit_sound(ent, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Collisions
	new victim = -1
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, origin, NADE_EXPLOSION_RADIUS)) != 0)
	{
		// Only effect alive zombies
		if (!is_user_alive(victim) || !zp_core_is_zombie(victim))
			continue;
		
		set_freeze(victim)
	}
	
	// Get rid of the grenade
	engfunc(EngFunc_RemoveEntity, ent)
}

set_freeze(victim)
{
	// Already frozen
	if (flag_get(g_IsFrozen, victim))
		return false;
	
	// Allow other plugins to decide whether player should be frozen or not
	ExecuteForward(g_Forwards[FW_USER_FREEZE_PRE], g_ForwardResult, victim)
	if (g_ForwardResult >= PLUGIN_HANDLED)
	{
		// Get player's origin
		static origin2[3]
		get_user_origin(victim, origin2)
		
		// Broken glass sound
		static sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_grenade_frost_break, random_num(0, ArraySize(g_sound_grenade_frost_break) - 1), sound, charsmax(sound))
		emit_sound(victim, CHAN_BODY, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		// Glass shatter
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin2)
		write_byte(TE_BREAKMODEL) // TE id
		write_coord(origin2[0]) // x
		write_coord(origin2[1]) // y
		write_coord(origin2[2]+24) // z
		write_coord(16) // size x
		write_coord(16) // size y
		write_coord(16) // size z
		write_coord(random_num(-50, 50)) // velocity x
		write_coord(random_num(-50, 50)) // velocity y
		write_coord(25) // velocity z
		write_byte(10) // random velocity
		write_short(g_glassSpr) // model
		write_byte(10) // count
		write_byte(25) // life
		write_byte(BREAK_GLASS) // flags
		message_end()
		
		return false;
	}
	
	// Freeze icon?
	if (get_pcvar_num(cvar_grenade_frost_hudicon))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgDamage, _, victim)
		write_byte(0) // damage save
		write_byte(0) // damage take
		write_long(DMG_DROWN) // damage type - DMG_FREEZE
		write_coord(0) // x
		write_coord(0) // y
		write_coord(0) // z
		message_end()
	}
	
	// Set frozen flag
	flag_set(g_IsFrozen, victim)
	
	// Freeze sound
	static sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_sound_grenade_frost_player, random_num(0, ArraySize(g_sound_grenade_frost_player) - 1), sound, charsmax(sound))
	emit_sound(victim, CHAN_BODY, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Add a blue tint to their screen
	message_begin(MSG_ONE, g_MsgScreenFade, _, victim)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(FFADE_STAYOUT) // fade type
	write_byte(0) // red
	write_byte(50) // green
	write_byte(200) // blue
	write_byte(100) // alpha
	message_end()
	
	// Update player entity rendering
	ApplyFrozenRendering(victim)
	
	// Block gravity
	ApplyFrozenGravity(victim)
	
	// Update player's maxspeed
	ExecuteHamB(Ham_Player_ResetMaxSpeed, victim)
	
	// Set a task to remove the freeze
	set_task(get_pcvar_float(cvar_grenade_frost_duration), "remove_freeze", victim+TASK_FROST_REMOVE)
	return true;
}

ApplyFrozenGravity(id)
{
	// Get current gravity
	new Float:gravity = get_user_gravity(id)
	
	// Already set, no worries...
	if (gravity == GRAVITY_HIGH || gravity == GRAVITY_NONE)
		return;
	
	// Save player's old gravity
	g_FrozenGravity[id] = gravity
	
	// Prevent from jumping
	if (pev(id, pev_flags) & FL_ONGROUND)
		set_user_gravity(id, GRAVITY_HIGH) // set really high
	else
		set_user_gravity(id, GRAVITY_NONE) // no gravity
}

ApplyFrozenRendering(id)
{
	// Get current rendering
	new rendering_fx = pev(id, pev_renderfx)
	new Float:rendering_color[3]
	pev(id, pev_rendercolor, rendering_color)
	new rendering_render = pev(id, pev_rendermode)
	new Float:rendering_amount
	pev(id, pev_renderamt, rendering_amount)
	
	// Already set, no worries...
	if (rendering_fx == kRenderFxGlowShell && rendering_color[0] == 0.0 && rendering_color[1] == 100.0
		&& rendering_color[2] == 200.0 && rendering_render == kRenderNormal && rendering_amount == 25.0)
		return;
	
	// Save player's old rendering	
	g_FrozenRenderingFx[id] = pev(id, pev_renderfx)
	pev(id, pev_rendercolor, g_FrozenRenderingColor[id])
	g_FrozenRenderingRender[id] = pev(id, pev_rendermode)
	pev(id, pev_renderamt, g_FrozenRenderingAmount[id])
	
	// Light blue glow while frozen
	fm_set_rendering(id, kRenderFxGlowShell, 0, 100, 200, kRenderNormal, 25)
}

// Remove freeze task
public remove_freeze(taskid)
{
	// Remove frozen flag
	flag_unset(g_IsFrozen, ID_FROST_REMOVE)
	
	// Restore gravity
	set_pev(ID_FROST_REMOVE, pev_gravity, g_FrozenGravity[ID_FROST_REMOVE])
	
	// Update player's maxspeed
	ExecuteHamB(Ham_Player_ResetMaxSpeed, ID_FROST_REMOVE)
	
	// Restore rendering
	fm_set_rendering_float(ID_FROST_REMOVE, g_FrozenRenderingFx[ID_FROST_REMOVE], g_FrozenRenderingColor[ID_FROST_REMOVE], g_FrozenRenderingRender[ID_FROST_REMOVE], g_FrozenRenderingAmount[ID_FROST_REMOVE])
	
	// Gradually remove screen's blue tint
	message_begin(MSG_ONE, g_MsgScreenFade, _, ID_FROST_REMOVE)
	write_short(UNIT_SECOND) // duration
	write_short(0) // hold time
	write_short(FFADE_IN) // fade type
	write_byte(0) // red
	write_byte(50) // green
	write_byte(200) // blue
	write_byte(100) // alpha
	message_end()
	
	// Broken glass sound
	static sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_sound_grenade_frost_break, random_num(0, ArraySize(g_sound_grenade_frost_break) - 1), sound, charsmax(sound))
	emit_sound(ID_FROST_REMOVE, CHAN_BODY, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Get player's origin
	static origin[3]
	get_user_origin(ID_FROST_REMOVE, origin)
	
	// Glass shatter
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_BREAKMODEL) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]+24) // z
	write_coord(16) // size x
	write_coord(16) // size y
	write_coord(16) // size z
	write_coord(random_num(-50, 50)) // velocity x
	write_coord(random_num(-50, 50)) // velocity y
	write_coord(25) // velocity z
	write_byte(10) // random velocity
	write_short(g_glassSpr) // model
	write_byte(10) // count
	write_byte(25) // life
	write_byte(BREAK_GLASS) // flags
	message_end()
	
	ExecuteForward(g_Forwards[FW_USER_UNFROZEN], g_ForwardResult, ID_FROST_REMOVE)
}

// Frost Grenade: Freeze Blast
create_blast3(const Float:originF[3])
{
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+385.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(100) // green
	write_byte(200) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+470.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(100) // green
	write_byte(200) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(100) // green
	write_byte(200) // blue
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

// Set entity's rendering type (float parameters version)
stock fm_set_rendering_float(entity, fx = kRenderFxNone, Float:color[3], render = kRenderNormal, Float:amount = 16.0)
{
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, amount)
}