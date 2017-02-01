#if defined _zp50_admin_commands_included
  #endinput
#endif
#define _zp50_admin_commands_included

#include <zp50_core>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_admin_commands
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_admin_commands
	#endif
#else
	#pragma library zp50_admin_commands
#endif


/**
 * Manually executes admin command: zp_zombie.
 *
 * @param id		Admin player index.
 * @param player	Target player index.
 * @return			True on success, false otherwise.
 */
native zp_admin_commands_zombie(id, player)

/**
 * Manually executes admin command: zp_human.
 *
 * @param id		Admin player index.
 * @param player	Target player index.
 * @return			True on success, false otherwise.
 */
native zp_admin_commands_human(id, player)

/**
 * Manually executes admin command: zp_nemesis.
 *
 * @param id		Admin player index.
 * @param player	Target player index.
 * @return			True on success, false otherwise.
 */
native zp_admin_commands_nemesis(id, player)

/**
 * Manually executes admin command: zp_survivor.
 *
 * @param id		Admin player index.
 * @param player	Target player index.
 * @return			True on success, false otherwise.
 */
native zp_admin_commands_survivor(id, player)

/**
 * Manually executes admin command: zp_respawn.
 *
 * @param id		Admin player index.
 * @param player	Target player index.
 * @return			True on success, false otherwise.
 */
native zp_admin_commands_respawn(id, player)

/**
 * Manually executes admin command: zp_start_game_mode.
 *
 * @param id				Admin player index.
 * @param game_mode_id		A valid game mode ID.
 * @return					True on success, false otherwise.
 */
native zp_admin_commands_start_mode(id, game_mode_id)
