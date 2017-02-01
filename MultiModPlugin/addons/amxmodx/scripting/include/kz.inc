/**
 * (C)2006 teame06
 * Kz Jump Plugin v0.b
 */

#if defined _kz_included
  #endinput
#endif
#define _kz_included

#include <fakemeta>
#include <cstrike>

#pragma library kz

// Do not edit
#define KZ_VERSION 			"0.08b"

/* states for kz_Init */
enum
{
	_OFF = 0,
	_ON = 1
};

enum // kz_ColorChat
{
	normal = 0, // Yellow
	team, // Team color. CT will be blue, Terrorist will be Red.
	green // Green.
}

forward kz_Init(kz_state);

// Called when the player pushes the start button.
forward kz_StartClimb(player);

// Called when the player pushes the end button.
forward kz_FinishClimb(player, time, cp_count, gc_count); // time is in seconds.

// Called when player resets the timer
forward kz_ResetClimb(player);

// return 1 or 0
native IsPlayerStarted(player);

// return 1 or 0
native IsPlayerFinished(player);

native IsPlayerPause(player);

native SetPlayerPause(player, mode = 0);

native SetPlayerNotSolid(player);

native SetPlayerSolid(player);

native kz_ColorChat(player, color_type, const message[], {Float,Sql,Result,_}:...);

native kz_ShowSyncHudMsg(player, r, g, b, Float:x, Float:y, const msg[], {Float,Sql,Result,_}:...);

// Taken GabenMod by Basic-Master. Good function to.
stock register_saycmd(saycommand[], function[], flags, info[])
{
	new temp[64];
	format(temp, 63, "say /%s", saycommand);
	register_clcmd(temp, function, flags, info);
	format(temp, 63, "say .%s", saycommand);
	register_clcmd(temp, function, flags, info);
	format(temp, 63, "say_team /%s", saycommand);
	register_clcmd(temp, function, flags, info);
	format(temp, 63, ".%s", saycommand);
	register_clcmd(temp, function, flags, info);
	format(temp, 63, "/%s", saycommand);
	register_clcmd(temp, function, flags, info);
}

// From GabenMod by Basic Master.
stock set_keyvalue(ent, key[], value[])
{
	new classname[32];
	pev(ent, pev_classname, classname, 31);
	set_kvd(0, KV_ClassName, classname);
	set_kvd(0, KV_KeyName, key);
	set_kvd(0, KV_Value, value);
	set_kvd(0, KV_fHandled, 0);

	dllfunc(DLLFunc_KeyValue, ent, 0);
}

// Taken from fakemeta_utils.inc.
stock _fm_give_item(index, const item[])
{
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0;

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item));

	if (!pev_valid(ent))
		return 0;

	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);

	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save)
		return ent;

	engfunc(EngFunc_RemoveEntity, ent);

	return -1;
}

stock _get_brush_entity_origin(ent, Float:orig[3]) // Taken from the engine stock
{
	new Float:Min[3], Float:Max[3];
	pev(ent, pev_mins, Min);
	pev(ent, pev_maxs, Max);

	orig[0] = (Min[0] + Max[0]) * 0.5;
	orig[1] = (Min[1] + Max[1]) * 0.5;
	orig[2] = (Min[2] + Max[2]) * 0.5;

	return 1;
}

// From GabenMod by Basic-Master
stock IsPlayerValid(player)
{
	if (!player || !pev_valid(player))
		return 0;
	if (!is_user_connected(player) || !is_user_alive(player))
		return 0;

	if (cs_get_user_team(player) != CS_TEAM_CT && cs_get_user_team(player) != CS_TEAM_T)
		return 0;

	return 1;
}

#pragma semicolon 1