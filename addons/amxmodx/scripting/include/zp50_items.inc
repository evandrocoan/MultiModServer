#if defined _zp50_items_included
  #endinput
#endif
#define _zp50_items_included

#include <zp50_core>
#include <zp50_items_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_items
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_items
	#endif
#else
	#pragma library zp50_items
#endif


/**
 * Registers a custom item which will be added to the extra items menu of ZP.
 *
 * Note: The returned item ID can be later used to catch item
 * selection events for the zp_item_select_() forwards.
 *
 * @param name			Caption to display on the menu.
 * @param cost			Cost to display on the menu.
 * @return				An internal item ID, or ZP_INVALID_ITEM on failure.
 */
native zp_items_register(const name[], cost)

/**
 * Returns an item's ID.
 *
 * @param name		Item name to look for.
 * @return			Internal item ID, or ZP_INVALID_ITEM if not found.
 */
native zp_items_get_id(const real_name[])

/**
 * Returns an item's name.
 *
 * @param itemid	A valid item ID.
 * @param name		The buffer to store the string in.
 * @param len		Character size of the output buffer.
 * @return			True on success, false otherwise.
 */
native zp_items_get_name(itemid, name[], len)

/**
 * Returns an item's real name (used when registering the item).
 *
 * @param classid	A valid item ID.
 * @param name		The buffer to store the string in.
 * @param len		Character size of the output buffer.
 * @return			True on success, false otherwise.
 */
native zp_items_get_real_name(itemid, real_name[], len)

/**
 * Returns an item's cost.
 *
 * @param itemid		A valid item ID.
 * @return				Item's cost.
 */
native zp_items_get_cost(itemid)

/**
 * Shows menu with available extra items for player.
 *
 * @param id		Player index.
 */
native zp_items_show_menu(id)

/**
 * Forces a player to buy an extra item.
 *
 * @param id			Player index.
 * @param itemid		A valid extra item ID.
 * @param ignorecost	If set, item's cost won't be deduced from player.
 * @return				True on success, false otherwise.
 */
native zp_items_force_buy(id, itemid, ignorecost = false)

/**
 * Appends text to an item being displayed on the extra items menu.
 * Use this on the item select pre forward.
 *
 * @param text		Additional text to display.
 */
native zp_items_menu_text_add(const text[])

/**
 * Called when determining whether an item should be available to a player.
 *
 * Possible return values are:
 *	- ZP_ITEM_AVAILABLE (show in menu, allow selection)
 *	- ZP_ITEM_NOT_AVAILABLE (show in menu, don't allow selection)
 *	- ZP_ITEM_DONT_SHOW (don't show in menu, don't allow selection)
 *
 * @param id			Player index.
 * @param itemid		Internal item ID.
 * @param ignorecost	Whether item cost should be ignored.
 */
forward zp_fw_items_select_pre(id, itemid, ignorecost)

/**
 * Called after a player selected an item from the extra items menu.
 *
 * @param id			Player index.
 * @param itemid		Internal item ID.
 * @param ignorecost	Whether item cost should be ignored.
 */
forward zp_fw_items_select_post(id, itemid, ignorecost)
