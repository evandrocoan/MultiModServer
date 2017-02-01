/*================================================================================
	
	---------------------------------
	-*- [ZP] Items Manager: Money -*-
	---------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <zp50_items>

public plugin_init()
{
	register_plugin("[ZP] Items Manager: Money", ZP_VERSION_STRING, "ZP Dev Team")
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// Ignore item costs?
	if (ignorecost)
		return ZP_ITEM_AVAILABLE;
	
	// Get current and required money
	new current_money = cs_get_user_money(id)
	new required_money = zp_items_get_cost(itemid)
	
	// Not enough money
	if (current_money < required_money)
		return ZP_ITEM_NOT_AVAILABLE;
	
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	// Ignore item costs?
	if (ignorecost)
		return;
	
	// Get current and required money
	new current_money = cs_get_user_money(id)
	new required_money = zp_items_get_cost(itemid)
	
	// Deduct item's money after purchase event
	cs_set_user_money(id, current_money - required_money)
}
