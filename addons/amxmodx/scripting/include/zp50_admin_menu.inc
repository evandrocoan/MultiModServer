#if defined _zp50_admin_menu_included
  #endinput
#endif
#define _zp50_admin_menu_included

#include <zp50_core>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_admin_menu
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_admin_menu
	#endif
#else
	#pragma library zp50_admin_menu
#endif


/**
 * Shows admin menu to a specific player. Commands will only
 * be available if player has the required admin flags.
 *
 * @param id		Player index.
 */
native zp_admin_menu_show(id)
