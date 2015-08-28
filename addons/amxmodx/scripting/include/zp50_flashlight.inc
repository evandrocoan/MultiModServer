#if defined _zp50_flashlight_included
  #endinput
#endif
#define _zp50_flashlight_included

#include <zp50_core>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_flashlight
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_flashlight
	#endif
#else
	#pragma library zp50_flashlight
#endif


/**
 * Returns a player's custom flashlight batteries charge.
 *
 * @param id		Player index.
 * @return			Charge percent (0 to 100), or -1 if custom flashlight is disabled.
 */
native zp_flashlight_get_charge(id)

/**
 * Sets a player's custom flashlight batteries charge.
 *
 * @param id		Player index.
 * @param value		New charge percent (0 to 100).
 */
native zp_flashlight_set_charge(id, charge)
