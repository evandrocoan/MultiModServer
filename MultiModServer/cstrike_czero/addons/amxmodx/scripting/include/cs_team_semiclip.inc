/**
 * Team Semiclip 3.1.0
 *
 * This file is provided as is (no warranties).
 */

#if defined _tsc_included
  #endinput
#endif
#define _tsc_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib cs_team_semiclip
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib cs_team_semiclip
	#endif
#else
	#pragma library cs_team_semiclip
#endif

/**
 * For set_module_filter()
 */
#define LIBRARY_TSC "cs_team_semiclip"


/**
 * Get if player is in special rendering.
 * 
 * @param id		Player index. [1-32]
 * @return			True if it is, false otherwise, or -1 on failure.
 */
native tsc_get_user_rendering(id)


/**
 * Set on player, special renders.
 * 
 * @param id		Player index. [1-32]
 * @param special	Special renders on/off. [0-1]
 * @param fx		look amxconst.inc -> Render for set_user_rendering [0-20]
 * @param r			Set red color. [0-255]
 * @param g			Set green color. [0-255]
 * @param b			Set blue color. [0-255]
 * @param render	look amxconst.inc -> Render for set_user_rendering [0-5]
 * @param amount	Set amount. [0-255]
 * @return			True if it is, false otherwise, or -1 on failure.
 */
native tsc_set_user_rendering(id, special = 0, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)


/**
 * Return if player is in semiclip.
 * 
 * @param id		Player index. [1-32}
 * @return			True if it is, false otherwise, or -1 on failure.
 */
native tsc_get_user_semiclip(id)


/**
 * Return if player is in anti boost with other player.
 *
 * When other player is NULL = 0 when only return
 * if id is in anti boost with someone.
 * 
 * @param id		Player index. [1-32}
 * @param other		Other player index. [1-32}
 * @return			True if it is, false otherwise, or -1 on failure.
 */
native tsc_get_user_anti_boost(id, other = 0)
