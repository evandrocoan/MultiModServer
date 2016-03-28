#if defined _weapon_chance_included
	#endinput
#endif

#define _weapon_chance_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib weapon_chance
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib weapon_chance
	#endif
#else
	#pragma library weapon_chance
#endif

/* 
 * Adds an item to the chance list when player spawns
 * 
 * @param		teams - The team value for the item (use WC_TEAMS_* constant)
 * @param		chance - The percentage of getting the item (0-100)
 * @param		announce - true to tell all players if player got item, false to only tell the player who got it
 * 
 * @return		Returns a unique item index (item_id)
 * 
 */
enum
{
	WC_TEAMS_ALL,
	WC_TEAMS_T,
	WC_TEAMS_CT
};
native wc_add(const teams, const chance, const bool:announce);

/* 
 * Called when the core plugin is given player the item
 * 
 * @param		player_id - The index of player who is getting the item
 * @param		item_id - The item index
 * 
 * @return		PLUGIN_HANDLED will stop the item from being given, PLUGIN_CONTINUE will say it was given to player
 * 
 */
forward wc_give_item(player_id, item_id);

/* 
 * Called when the core plugin is checking if player has item
 * 
 * @param		player_id - The index of player to check for the item
 * @param		item_id - The item index
 * 
 * @return		1 if player has item, 0 otherwise
 * 
 */
forward wc_has_item(player_id, item_id);

/* 
 * Called when the core plugin needs the name of the item being given
 * 
 * @param		player_id - The index of player who is getting the item
 * @param		item_id - The item index
 * @param		message - The string that needs to be formatted
 * 
 * @return		No return
 * 
 */
forward wc_format_message(player_id, item_id, message[64]);
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
