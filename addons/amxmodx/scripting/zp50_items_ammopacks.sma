/*================================================================================
	
	--------------------------------------
	-*- [ZP] Items Manager: Ammo Packs -*-
	--------------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_items>
#include <zp50_ammopacks>

public plugin_init()
{
	register_plugin("[ZP] Items Manager: Ammo Packs", ZP_VERSION_STRING, "ZP Dev Team")
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// Ignore item costs?
	if (ignorecost)
		return ZP_ITEM_AVAILABLE;
	
	// Get current and required ammo packs
	new current_ammopacks = zp_ammopacks_get(id)
	new required_ammopacks = zp_items_get_cost(itemid)
	
	// Not enough ammo packs
	if (current_ammopacks < required_ammopacks)
		return ZP_ITEM_NOT_AVAILABLE;
	
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	// Ignore item costs?
	if (ignorecost)
		return;
	
	// Get current and required ammo packs
	new current_ammopacks = zp_ammopacks_get(id)
	new required_ammopacks = zp_items_get_cost(itemid)
	
	// Deduct item's ammo packs after purchase event
	zp_ammopacks_set(id, current_ammopacks - required_ammopacks)
}
