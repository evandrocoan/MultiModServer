#if defined _zp50_class_survivor_included
  #endinput
#endif
#define _zp50_class_survivor_included

#include <zp50_class_human>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_class_survivor
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_class_survivor
	#endif
#else
	#pragma library zp50_class_survivor
#endif


/**
 * Returns whether a player is a Survivor.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native zp_class_survivor_get(id)

/**
 * Forces a player to become a Survivor.
 *
 * @param id		Player index.
 * @return			True on success, false otherwise.
 */
native zp_class_survivor_set(id)

/**
 * Returns number of alive survivors.
 *
 * @return		Survivor count.
 */
native zp_class_survivor_get_count()
