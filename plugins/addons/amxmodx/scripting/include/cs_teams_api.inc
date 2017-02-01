#if defined _cs_teams_api_included
  #endinput
#endif
#define _cs_teams_api_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib cs_teams_api
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib cs_teams_api
	#endif
#else
	#pragma library cs_teams_api
#endif

#include <cstrike>

/**
 * Sets a player's team.
 *
 * @param id			Player index.
 * @param team			CS_TEAM_ constant.
 * @param update		Whether to update team on scoreboard.
 */
native cs_set_player_team(id, CsTeams:team, update = true)
