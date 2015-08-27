#if defined _zp50_core_included
  #endinput
#endif
#define _zp50_core_included

#include <zp50_core_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_core
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_core
	#endif
#else
	#pragma library zp50_core
#endif

/**
 * Returns whether a player is a zombie.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native zp_core_is_zombie(id)

/**
 * Returns whether a player is the first zombie.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native zp_core_is_first_zombie(id)

/**
 * Returns whether a player is the last zombie.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native zp_core_is_last_zombie(id)

/**
 * Returns whether a player is the last human.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native zp_core_is_last_human(id)

/**
 * Returns number of alive zombies.
 *
 * @return		Zombie count.
 */
native zp_core_get_zombie_count()

/**
 * Returns number of alive humans.
 *
 * @return		Human count.
 */
native zp_core_get_human_count()

/**
 * Turns a player into a zombie.
 *
 * @param id		Player index to be infected.
 * @param attacker	Player who triggered the infection. (optional)
 * @return			True on success, false otherwise.
 */
native zp_core_infect(id, attacker = 0)

/**
 * Turns a player into a human.
 *
 * @param id		Player index to be cured.
 * @param attacker	Player who triggered the cure. (optional)
 * @return			True on success, false otherwise.
 */
native zp_core_cure(id, attacker = 0)

/**
 * Forces a player to become a zombie/human.
 *
 * Note: use this only when previous checks need to be skipped.
 *
 * @param id		Player index to be infected/cured.
 * @return			True on success, false otherwise.
 */
native zp_core_force_infect(id)
native zp_core_force_cure(id)

/**
 * Sets whether the player will be respawned as zombie or human.
 *
 * @param id			Player index.
 * @param zombie		True to respawn as zombie, false otherwise.
 */
native zp_core_respawn_as_zombie(id, zombie = true)

/**
 * Called when a player gets infected.
 *
 * @param id		Player index who was infected.
 * @param attacker	Player who triggered the infection.
 *					(0 if not available, id = attacker if he infected himself)
 */
forward zp_fw_core_infect(id, attacker)
forward zp_fw_core_infect_post(id, attacker)

/**
 * Called when a player turns back to human.
 *
 * @param id		Player index who was cured.
 * @param attacker	Player who triggered the cure.
 *					(0 if not available, id = attacker if he cured himself)
 */
forward zp_fw_core_cure(id, attacker)
forward zp_fw_core_cure_post(id, attacker)

/**
 * Called on a player infect/cure attempt. You can block it by
 * returning PLUGIN_HANDLED in your plugin.
 *
 * @param id		Player index who is being infected/cured.
 * @param attacker	Player who is triggering the infection/cure.
 *					(0 if not available, id = attacker if he is infecting/curing himself)
 */
forward zp_fw_core_infect_pre(id, attacker)
forward zp_fw_core_cure_pre(id, attacker)

/**
 * Called when a player becomes the last zombie/human.
 *
 * Note: This is called for the first zombie too.
 *
 * @param id		Player index.
 */
forward zp_fw_core_last_zombie(id)
forward zp_fw_core_last_human(id)

/**
 * Called when a player spawns, before applying human/zombie attributes to him.
 *
 * @param id		Player index.
 */
forward zp_fw_core_spawn_post(id)
