#if defined _cs_maxspeed_api_included
  #endinput
#endif
#define _cs_maxspeed_api_included

#include <cs_maxspeed_api_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib cs_maxspeed_api
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib cs_maxspeed_api
	#endif
#else
	#pragma library cs_maxspeed_api
#endif

/**
 * Sets a player's maxspeed.
 *
 * @param id			Player index.
 * @param maxspeed		Custom maxspeed.
 * @param multiplier	Treat maxspeed as multiplier instead of absolute value.
 */
native cs_set_player_maxspeed(id, Float:maxspeed, multiplier = false)

/**
 * Resets a player's maxspeed to default CS maxspeed.
 *
 * @param id			Player index.
 */
native cs_reset_player_maxspeed(id)

// Keep this always at the bottom of this file
#include <cs_maxspeed_api_stocks>