/* Fakemeta Utilities
*
* by VEN
*
* This file is provided as is (no warranties).
*
* Reduced by pRED* to provide with the bf2 rank mod package. Makes it easier to compile without finding fakemeta util first
*/

#if !defined _fakemeta_included
	#include <fakemeta>
#endif

#if defined _fakemeta_util_included
	#endinput
#endif
#if defined _fakemeta_util_mini_included
	#endinput
#endif
#define _fakemeta_util_mini_included

#include <xs>

// based on KoST's port, upgraded version fits into the macros
#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))
/* stock fm_create_entity(const classname[])
	return engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname)) */

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) {
	new Float:RenderColor[3]
	RenderColor[0] = float(r)
	RenderColor[1] = float(g)
	RenderColor[2] = float(b)

	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, RenderColor)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))

	return 1
}

stock fm_give_item(index, const item[]) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0

	new ent = fm_create_entity(item)
	if (!pev_valid(ent))
		return 0

	new Float:origin[3]
	pev(index, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)

	new save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, index)
	if (pev(ent, pev_solid) != save)
		return ent

	engfunc(EngFunc_RemoveEntity, ent)

	return -1
}

