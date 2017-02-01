#if defined _cs_weap_restrict_api_included
  #endinput
#endif
#define _cs_weap_restrict_api_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib cs_weap_restrict_api
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib cs_weap_restrict_api
	#endif
#else
	#pragma library cs_weap_restrict_api
#endif

/**
 * Enables/disables weapon restrictions for a specific player.
 *
 * Note: if you pass an empty bitsum, all weapons will be restricted.
 *
 * @param id					Player index.
 * @param set					True to enable, false to remove restrictions.
 * @param allowed_bitsum		Bitsum containing allowed weapons.
 * @param allowed_default		Default allowed weapon to switch back to. (in CSW_ format)
 */
native cs_set_player_weap_restrict(id, set, allowed_bitsum = 0, allowed_default = 0)

/**
 * Returns whether a player has weapon restrictions enabled. In the case
 * that he does, also returns allowed_bistum and allowed_default (by referenced).
 *
 * @param id					Player index.
 * @param allowed_bitsum		Bitsum containing allowed weapons.
 * @param allowed_default		Default allowed weapon to switch back to. (in CSW_ format)
 * @return						True if restrictions are enabled, false otherwise.
 */
native cs_get_player_weap_restrict(id, &allowed_bitsum=0, &allowed_default=0)
