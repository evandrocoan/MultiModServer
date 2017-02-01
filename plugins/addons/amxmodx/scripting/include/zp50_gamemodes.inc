#if defined _zp50_gamemodes_included
  #endinput
#endif
#define _zp50_gamemodes_included

#include <zp50_core>
#include <zp50_gamemodes_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_gamemodes
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_gamemodes
	#endif
#else
	#pragma library zp50_gamemodes
#endif


/**
 * Registers a new game mode.
 *
 * @param name		Game mode name.
 * @return			An internal game mode ID, or ZP_INVALID_GAME_MODE on failure.
 */
native zp_gamemodes_register(const name[])

/**
 * Sets a default game mode (to start if no other game mode can been started).
 *
 * @param game_mode_id		A valid game mode ID.
 * @return					True on success, false otherwise.
 */
native zp_gamemodes_set_default(game_mode_id)

/**
 * Returns default game mode.
 *
 * @return					A valid game mode ID.
 */
native zp_gamemodes_get_default()

/**
 * Returns game mode that was chosen for the current round.
 *
 * @return			An internal game mode ID, or ZP_NO_GAME_MODE.
 */
native zp_gamemodes_get_chosen()

/**
 * Returns game mode that is currently in progress.
 *
 * @return			An internal game mode ID, or ZP_NO_GAME_MODE.
 */
native zp_gamemodes_get_current()

/**
 * Returns a game mode's ID.
 *
 * @param name		Game mode name to look for.
 * @return			Internal game mode ID, or ZP_INVALID_GAME_MODE if not found.
 */
native zp_gamemodes_get_id(const name[])

/**
 * Returns a game mode's name.
 *
 * @param game_mode_id	A valid game mode ID.
 * @param name			The buffer to store the string in.
 * @param len			Character size of the output buffer.
 * @return				True on success, false otherwise.
 */
native zp_gamemodes_get_name(game_mode_id, name[], len)

/**
 * Forces a game mode to start.
 *
 * @param game_mode_id		A valid game mode ID.
 * @param target_player		Player ID to be passed to game mode (optional).
 * @return					True on success, false if game mode can't start.
 */
native zp_gamemodes_start(game_mode_id, target_player = RANDOM_TARGET_PLAYER)

/**
 * Returns number of registered game modes.
 *
 * @return			Game mode count.
 */
native zp_gamemodes_get_count()

/**
 * Sets whether zombies can infect humans for the current game mode.
 *
 * @param allow			True to allow, false otherwise.
 */
native zp_gamemodes_set_allow_infect(allow = true)

/**
 * Returns whether zombies are allowed to infect humans for the current game mode.
 *
 * @return			True if allowed, false otherwise.
 */
native zp_gamemodes_get_allow_infect()

/**
 * Called when ZP tries to choose a game mode for the current
 * round. Returning PLUGIN_HANDLED here will tell the game modes
 * manager that your mode can't be chosen (useful to set custom
 * conditions, like a min amount of players, etc.)
 *
 * @param game_mode_id		Internal game mode ID.
 * @param skipchecks		True when mode is being started by an admin.
 */
forward zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)

/**
 * Called when a game mode is chosen for the current round.
 *
 * @param game_mode_id		Internal ID for the game mode that was chosen.
 * @param target_player		Player ID passed to game mode (can be RANDOM_TARGET_PLAYER).
 */
forward zp_fw_gamemodes_choose_post(game_mode_id, target_player)

/**
 * Called when a game mode starts.
 *
 * @param game_mode_id		Internal ID for the game mode that was started.
 */
forward zp_fw_gamemodes_start(game_mode_id)

/**
 * Called when a game mode ends.
 *
 * Note: this can pass ZP_NO_GAME_MODE (if no game mode was in progress).
 *
 * @param game_mode_id		Internal ID for the game mode that ended.
 */
forward zp_fw_gamemodes_end(game_mode_id)
