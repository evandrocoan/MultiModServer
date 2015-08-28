#if defined _zp50_random_spawn_included
  #endinput
#endif
#define _zp50_random_spawn_included

#include <zp50_core>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_random_spawn
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_random_spawn
	#endif
#else
	#pragma library zp50_random_spawn
#endif


/**
 * Moves a player to a random spawn point.
 *
 * @param id			Player index.
 * @param csdmspawns	Ue CSDM spawn points instead of map defaults.
 */
native zp_random_spawn_do(id, csdmspawns = true)
