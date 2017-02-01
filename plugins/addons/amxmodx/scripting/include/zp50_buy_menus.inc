#if defined _zp50_buy_menus_included
  #endinput
#endif
#define _zp50_buy_menus_included

#include <zp50_core>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_buy_menus
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_buy_menus
	#endif
#else
	#pragma library zp50_buy_menus
#endif


/**
 * Shows available buy menus for player and enables them
 * back again if automatic weapon selection was enabled.
 *
 * @param id		Player index.
 */
native zp_buy_menus_show(id)
