#if defined _cswa_included
	#endinput
#endif
#define _cswa_included

#pragma semicolon 1

stock set_weapon_string(ent, type, array[])		entity_set_string(ent, type, array);
stock set_weapon_float(ent, type, Float:val)	entity_set_float(ent, type, val);
stock set_weapon_integer(ent, type, val)		entity_set_int(ent, type, val);
stock set_weapon_edict(ent, type, val)			entity_set_edict(ent, type, val);

stock get_weapon_string(ent, type, array[], size)	entity_get_string(ent, type, array, size);
stock Float:get_weapon_float(ent, type)				return entity_get_float(ent, type);
stock get_weapon_integer(ent, type)					return entity_get_int(ent, type);
stock get_weapon_edict(ent, type)					return entity_get_edict(ent, type);

enum _:STOREABLE_REPLACEMENTS
{
	REPL_CSWA_CLIP			= EV_INT_iuser1,
	REPL_CSWA_MAXCLIP		= EV_INT_iuser2,
	REPL_CSWA_AMMO			= EV_INT_iuser3,
	//EV_INT_iuser4,

	REPL_CSWA_SPEEDDELAY	= EV_FL_fuser1,
	REPL_CSWA_DAMAGE		= EV_FL_fuser2,
	REPL_CSWA_RELOADTIME	= EV_FL_fuser3,
	REPL_CSWA_RECOIL		= EV_FL_fuser4,

	REPL_CSWA_STACKABLE		= EV_ENT_euser1,
	REPL_CSWA_SILENCED		= EV_ENT_euser2,
	REPL_CSWA_SET			= EV_ENT_euser3,
	REPL_CSWA_ITEMID		= EV_ENT_euser4,

	//EV_SZ_noise,
	REPL_CSWA_MODEL_V		= EV_SZ_noise1,
	REPL_CSWA_MODEL_P		= EV_SZ_noise2,
	REPL_CSWA_MODEL_W		= EV_SZ_noise3
}

enum _:STOREABLE_STRUCTURE
{
	STRUCT_CSWA_CSW,
	STRUCT_CSWA_CLIP,
	STRUCT_CSWA_MAXCLIP,
	STRUCT_CSWA_AMMO,
	STRUCT_CSWA_STACKABLE,
	STRUCT_CSWA_SILENCED,
	STRUCT_CSWA_SET,
	STRUCT_CSWA_ITEMID,
	Float:STRUCT_CSWA_SPEEDDELAY,
	Float:STRUCT_CSWA_DAMAGE,
	Float:STRUCT_CSWA_RELOADTIME,
	Float:STRUCT_CSWA_RECOIL,
	STRUCT_CSWA_MODEL_V[64],
	STRUCT_CSWA_MODEL_P[64],
	STRUCT_CSWA_MODEL_W[64]
}

/**
 * Gives player specific weapon.
 *
 * @param id				Player index.
 * @param array[]			Array of STOREABLE_DATA enum.
 * @param show				Should show weapon?
 * @return					Weapon handle.
 */
native cswa_give_specific(id, array[], show = 0);

/**
 * Gives player normal weapon.
 *
 * @param id				Player index.
 * @param csw_id			CSW_*.
 * @param clip				Clip.
 * @param ammo				Ammo.
 * @param show				Should show weapon?
 * @return					Weapon ENTID.
 */
native cswa_give_normal(id, csw_id, clip, ammo, show = 0);

/**
 * Called when someone is killed by special weapon.
 *
 * @param weapon_id			Weapon handle.
 * @param victim			Killed player id.
 * @param killer			Killer player id.
 */
forward cswa_killed(weapon_id, victim, killer);

/**
 * Called when someone is shot at by special weapon.
 *
 * @param weapon_id			Weapon handle.
 * @param victim			Killed player id.
 * @param killer			Killer player id.
 */
forward cswa_damage(weapon_id, victim, attacker, Float:damage);