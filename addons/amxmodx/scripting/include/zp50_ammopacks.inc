#if defined _zp50_ammopacks_included
  #endinput
#endif
#define _zp50_ammopacks_included

#include <zp50_core>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_ammopacks
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_ammopacks
	#endif
#else
	#pragma library zp50_ammopacks
#endif


/**
 * Returns a player's ammo pack count.
 *
 * @param id		Player index.
 * @return			Number of ammo packs owned.
 */
native zp_ammopacks_get(id)

/**
 * Sets a player's ammo pack count.
 *
 * @param id		Player index.
 * @param amount	New quantity of ammo packs owned.
 */
native zp_ammopacks_set(id, amount)
