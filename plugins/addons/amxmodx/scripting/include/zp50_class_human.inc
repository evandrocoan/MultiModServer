#if defined _zp50_class_human_included
  #endinput
#endif
#define _zp50_class_human_included

#include <zp50_core>
#include <zp50_class_human_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_class_human
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_class_human
	#endif
#else
	#pragma library zp50_class_human
#endif


/**
 * Returns a player's current human class ID.
 *
 * @param id		Player index.
 * @return			Internal human class ID, or ZP_INVALID_HUMAN_CLASS if not yet chosen.
 */
native zp_class_human_get_current(id)

/**
 * Returns a player's next human class ID (for the next infection).
 *
 * @param id		Player index.
 * @return			Internal human class ID, or ZP_INVALID_HUMAN_CLASS if not yet chosen.
 */
native zp_class_human_get_next(id)

/**
 * Sets a player's next human class ID (for the next infection).
 *
 * @param id		Player index.
 * @param classid	A valid human class ID.
 * @return			True on success, false otherwise.
 */
native zp_class_human_set_next(id, classid)

/**
 * Returns the default maximum health for a specific human class.
 *
 * Note: does not take into account any kind of HP bonuses.
 *
 * @param id		Player index.
 * @param classid	A valid human class ID.
 * @return			Maximum amount of health points, -1 on error.
 */
native zp_class_human_get_max_health(id, classid)

/**
 * Registers a custom class which will be added to the human classes menu of ZP.
 *
 * Note: The returned human class ID can be later used to identify
 * the class when calling the zp_get_user_human_class() natives.
 *
 * @param name			Caption to display on the menu.
 * @param description	Brief description of the class.
 * @param health		Class health.
 * @param speed			Class maxspeed (can be a multiplier).
 * @param gravity		Class gravity multiplier.
 * @return				An internal human class ID, or ZP_INVALID_HUMAN_CLASS on failure.
 */
native zp_class_human_register(const name[], const description[], health, Float:speed, Float:gravity)

/**
 * Registers a custom player model for a given human class.
 *
 * @param classid		A valid human class ID.
 * @param model			Player model's short name.
 * @return				True on success, false otherwise.
 */
native zp_class_human_register_model(classid, const model[])

/**
 * Returns a human class' ID.
 *
 * @param name		Class name to look for.
 * @return			Internal human class ID, or ZP_INVALID_HUMAN_CLASS if not found.
 */
native zp_class_human_get_id(const real_name[])

/**
 * Returns a human class' name.
 *
 * @param classid	A valid human class ID.
 * @param name		The buffer to store the string in.
 * @param len		Character size of the output buffer.
 * @return			True on success, false otherwise.
 */
native zp_class_human_get_name(classid, name[], len)

/**
 * Returns a human class' real name (used when registering the class).
 *
 * @param classid	A valid human class ID.
 * @param name		The buffer to store the string in.
 * @param len		Character size of the output buffer.
 * @return			True on success, false otherwise.
 */
native zp_class_human_get_real_name(classid, real_name[], len)

/**
 * Returns a human class' description.
 *
 * @param classid		A valid human class ID.
 * @param description	The buffer to store the string in.
 * @param len			Character size of the output buffer.
 * @return				True on success, false otherwise.
 */
native zp_class_human_get_desc(classid, description[], len)

/**
 * Returns number of registered human classes.
 *
 * @return			Human class count.
 */
native zp_class_human_get_count()

/**
 * Shows menu with available human classes to a player.
 *
 * @param id		Player index.
 */
native zp_class_human_show_menu(id)

/**
 * Appends text to a class being displayed on the human classes menu.
 * Use this on the class select pre forward.
 *
 * @param text		Additional text to display.
 */
native zp_class_human_menu_text_add(const text[])

/**
 * Called when determining whether a class should be available to a player.
 *
 * Possible return values are:
 *	- ZP_CLASS_AVAILABLE (show in menu, allow selection)
 *	- ZP_CLASS_NOT_AVAILABLE (show in menu, don't allow selection)
 *	- ZP_CLASS_DONT_SHOW (don't show in menu, don't allow selection)
 *
 * @param id			Player index.
 * @param classid		Internal human class ID.
 */
forward zp_fw_class_human_select_pre(id, classid)

/**
 * Called right after a player selects a class from the menu.
 *
 * @param id			Player index.
 * @param classid		Internal human class ID.
 */
forward zp_fw_class_human_select_post(id, classid)
