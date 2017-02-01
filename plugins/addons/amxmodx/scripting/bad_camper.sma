/* 
	Title:	Bad Camper
	Author:	Brad Jones

	Current Version:	1.4.239
	Release Date:			2008-JUL-21

	This plugin will automatically punish players who camp for too long.

	There can be a combination of punishments that get applied to the player.  Punishments
	start when the player's camping meter reaches 80%.  They get worse at 90%.  They finally
	come to a crescendo at 100%.

	This plugin to be the successor to the great AntiCamping Advanced plugin.
	http://amxmodx.org/forums/viewtopic.php?t=751

	Original design inspiration, many concepts, and code came from "AntiCamping Advanced".
	http://amxmodx.org/forums/viewtopic.php?t=751


	INSTALLATION

		File Locations:
		
			.\gamemod\addons\amxmodx\plugins\bad_camper.amxx
			
		Modules:
		
			fun (required)
			cstrike (required only if utilizing money reduction punishment)
			csx (required if running Counter-Strike or Counter-Strike: Condition Zero)
			dodx (required if running DoD)
			tfcx (required if running TFC)
			
	
	OPTIONS (CVARs)

		badcamper_punish <iFlags>
	
			Specifies how a player is to be punished when they camp too long.
			A value of 0 will disable this plugin.

			The flags are additive.
			 1: Slap
			 2: Health Reduction
			 4: Sound (set sound via "badcamper_sound" CVAR)
			 8: Blind
			16: Money Reduction (requires CSTRIKE module)
			32: Snark Attack (requires Monster Mod)
			
			The default is 12 (snore and blind).

		badcamper_sound <iFlag>
		
			Specifies the sound to use as a punishment when the "badcamper_punish" flag includes
			the sound punishment.
			
			1: Snore
			2: Heartbeat
			
			The default is 1.

		badcamper_money <iPercentage>
		
			Specifies the percentage of money taken away when a player's meter reaches 100% when
			using the "money reduction" punishment.
			
			The default is 10 percent.

		badcamper_limit <iSeconds>
		
			Specifies the number of seconds a player can camp in one spot before their 
			camping meter will reach 100%.

			The default is 35 seconds.

		badcamper_display <iPercentage>
		
			Specifies the percentage at which the meter is displayed to the player.
			Valid values range from 0 (never show) to 100.

			The default is 1 percent.

		badcamper_show_spec <0|1>
				
				Specifies whether to allow spectators to see other player's meters.
				
				The default is 1, to allow it.			
			
		badcamper_check_all <0|1>
		
			Specifies whether only the team with the current primary objective should be
			checked for camping or if both teams should.
			
			0: only check the team with the current primary objective
			1: always check both teams
			
			The default is 1.
			
			The current primary objective is defined as follows:
			
				- if the map is not a "de" map, the CTs have the primary objective
				- if the map is a "de" map and the bomb hasn't been planted, the Ts have the primary objective
				- if the map is a "de" map and the bomb has been planted, the CTs have the primary objective
				
		badcamper_immunity_flags <cAccessLevels>
		
			Specifies the access level flags needed for a player to have immunity. Immunity is achieved by
			standing completely still and not looking around for approximately 6 seconds.  The camp meter 
			will  still increase until it reaches 65% or more at which time it'll stop until they move or 
			look around again.  If the meter is already at 80% or higher, the meter won't stop.
			
			Set this CVAR to blank to disallow immunity.
			
			For available flags, http://wiki.amxmodx.org/index.php/Adding_Admins_%28AMX_Mod_X%29#Access_Levels
		
			The default is blank (no immunity).
			
			A common value, when admin immunity is desired, is to use the "a" flag (ADMIN_IMMUNITY).
		
		badcamper_start <iSeconds>
		
			Specifies how many seconds after the freeze time ends each round that the 
			meter will start.

			The default is 4 seconds.

			Note that camping is checked every 2 seconds so any value you put in here will 
			effectively be rounded as such.

		badcamper_damage_reset <iResetType>
		
			Specifies if the attacker's or defender's meter gets reset when the player is
			injured by another.

			0: No meters are reset.
			1: The attacker's meter is reset.
			2: The defender's meter is reset.
			3: Both meters are reset.
			
			The default is 3.

		badcamper_damage_restart <iSeconds>
		
			Specifies how many seconds after a player either gives or receives damage that the 
			meter will restart.

			The default is 4 seconds.

			Note that camping is checked every 2 seconds so any value you put in here will 
			effectively be rounded up as such.

		badcamper_health <iHealthPoints>

			Specifies how many points of health to remove from the player every 2 seconds 
			once their meter reaches 100%.

			The default is 10 health points.

		badcamper_allow <iPlayerCount|iPlayerPercent%>
		
			Specifies when a team that is being checked for camping is allowed to camp.  
			A value of 0 doesn't allow a team to camp.

			The default is 0.

			The value can either be expressed as a straight count or as a percentage.
			If the value is being expressed as a percentage, "%" has to follow the value.  
			Examples below.  If the value is a count, players can camp when the number of 
			living players on their team falls to this value or lower.  If the value is a 
			percentage, players can camp when the percentage of living players on their team 
			is at this value or lower when compared to the living players on the other team.

			Examples:

				badcamper_allow 2

					Pretty straight-forward. Once there are 2 or fewer players left alive on 
					your team, you can camp.

				badcamper_allow 40%
				
					More powerful and complex. Once your team comprises of living players that 
					is 40% or less than the number of living players on the other team, you can 
					camp.  For instance (assume your team is listed first) the following match-ups 
					would allow your team to camp: 1v4, 2v5, 3v8, 4v12, 5v13, 6v15.

		badcamper_min_players <players>
		
			Specifies the minimum number of players that have to be connected to the server 
			before players are allowed to camp.

			The default is 0 players.

			This CVAR affects both "badcamper_check_all" and "badcamper_allow" functionality.
			
		badcamper_announce <announcementType>
		
			Specifies how to announce to the opposite team that a player is camping.
			
			0: Make no announcement.
			1: Announce via chat.
			2: Announce via HUD.
			3: Announce via chat and HUD.
			
			The default is 3.
			

	COMMANDS
	
		badcamper list
		
			Lists the punishments in the console and indicates which of them are active.


	CHANGE LOG
	
		2008-JUL-21  1.4.239
		
			! Compatible with AMXX 1.80 or higher only.
			- Fixed issue where the spectator meter would display in the spectated player's language
			  rather than the spectator's language.

		2007-AUG-04	 1.4
		
			- Added CVAR to aid in debugging; allows meter to run when only one person is on server.
			- Removed BugBlatter's "Monster Mod" support. Rationale being that players could crash 
			  your server by typing "meta list" in their console when using it.
			- All snarks are now killed at the end of each round, if using Snark punishment.
			- Fixed discrepancy between documentation and code. Changed "badcamper_announce" CVAR to 
				default to 3, as per the documenation.
			- Fixed issue where HLTV was counting as a player, thus affecting when camping is checked.
			- The camp meter will now affect bots that camp.
				Oh, and if your bot camps, you need a new bot or better waypoint files.
			- Fixed discrepancy between documenation and code.  Changed who can camp (based on 
				objectives)	when not on a map with a bomb site. Changed from everyone can to only Ts can.

		2007-APR-03	 1.3b
		
			- Fixed issue where screen would go sideways if health reduction punishment was used.
	
		2007-APR-02	 1.3a
		
			- Fixed dumb bug that kinda broke everything else. 
				Note to self: Don't make changes right before releasing.
	
		2007-APR-02	 1.3	
		
			! Compatible with AMXX 1.71 or higher only.
			! The 'csx', 'dodx', or 'tfcx' module has to be enabled, depending on what 
				game mod you are running.
			- Added DoD (tested) and TFC (untested) mod support.
			- Made more code optimizations.
			- Defuser's meter will now be paused when bomb is being defused.
			- Planter's meter will be more accurately paused than in previous versions.
				Previous versions would pause the player's meter for the full time it would
				take to plant the bomb, even if they stopped planting in the meantime.
			- Altered method of specifying admin immunity from define to CVAR.
			- Replaced badcamper_immunity CVAR with badcamper_immunity_flags.
			- Fixed overlapping "so and so is now camping" messages.
			- Added option to allow spectators to see players' meters. Default is to show the meter.
			- Fixed meter not always obeying "based on objectives" team. (thanks sasdad and arkshine!)
			- Fixed issue with ATAC 3.x whereas the health reduction could cause a player to get TAs.
	
		2006-MAR-12	 1.2
		
			! Compatible with AMXX 1.70 or higher only.
			! The 'fakemeta' module needs to be enabled.
			- Fixed issue where round end cleanup would not be performed if the round
				was restarted as opposed to ending normally.
			- Fixed "index out of bounds" error.
			- Auto-detects if you're using the supplied "Monster" metamod. If you are using
				a different version of "Monster", reverts to less fine control over snarks.
			- Removed need to recompile if using this plugin in a game mod other than
				Counter-Strike.
			- Removed need to recompile if using the "Snark Attack" punishment. Now, if you
				indicate to use "snark attack" as a punishment, but you don't have "Monster"
				installed, you'll get errors in your log files.
			- Disabled meter when there is only one person on the server. This is useful
				for when you want to sit on your server while waiting for others to join.
			- Implemented more accurate way of detecting if the map was a bomb map.
			- Optimized the code to use less CPU usage.

		2005-DEC-10	 1.1	
			
			- Added "Snark attack" punishment. Requires "Monster Mod" to be installed.
			- Changed "Slap" punishment to increase in power as the meter gets higher.
				Note that when slapped, the player may actually get slapped far enough 
				that it would lower the player's meter.
			- Added "badcamper_money" CVAR to specify what percentage of money to take
				away at 100% when using the "money reduction" punishment. Defaults to 
				10% as was the case before the option was introduced.
			- Added "badcamper_damage_reset" CVAR flag that specifies the meter(s) to 
				reset when a player is attacked. Defaults to both attacker and defender
				having their meter reset as was the case before the option was introduced.
			- Replaced "snore" punishment with "sound" punishment. The type of sound can
				be defined by a new CVAR, "badcamper_sound". There are two types of
				sounds, "snore" (default value) and "heartbeat".
			- Fixed bug where if a player's meter was 100% and the blind punishment was
				being used, when the player attacked or was attacked by another, the blind 
				player would stay blind instead of regaining vision immediately.
			- Added "badcamper list" command that lists available punishments and 
				indicates which are currently active (active as per the badcamper_punish CVAR).
			- Added "badcamper_announce" CVAR flag to indicate how to announce that a player
				is camping and then when the player stops camping. Will announce the 
				name of the camper at 90% and then again when the meter gets below 80%. 
				Options are to print as chat, as a HUD message, both, or neither.
			- Fixed bug where the CVAR 'badcamper_allow' had no effect, thus if set to a
				value higher than 0 a team would still never be allowed to camp.

		2005-SEP-24	 1.0	
		
			- Initial release.

*/


#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <cstrike>	// don't worry if you're not running cstrike, it's all good
#include <csx>			// don't worry if you're not running cstrike, it's all good

#pragma semicolon 1

#define TASKID_CHECK_CAMPING 85809473

#define DBG_METER_ON_1	1

#define SND_STOP (1<<5)

#define TEAM1 1
#define TEAM2	2

// Player Flags
#define METER_PAUSE		 1
#define METER_IGNORE		2
#define PLAYER_BLIND		4
#define PLAYER_SOUND		8
#define CAMPER_ANNOUNCED 16

#define FADE_IN	(1<<0)
#define FADE_OUT	(1<<1)
#define FADE_HOLD (1<<2)

#define FADE_LENGTH_PERM (1<<0)

#define PUNISH_SLAP			  1
#define PUNISH_HEALTH		  2
#define PUNISH_SOUND		  4
#define PUNISH_BLIND		  8
#define PUNISH_MONEY		16
#define PUNISH_SNARKS	 32

#define ANNOUNCE_CHAT 1
#define ANNOUNCE_HUD  2

#define SOUNDTYPE_SNORE	  1
#define SOUNDTYPE_HEARTBEAT 2

#define DMG_RESET_DEFENDER 1
#define DMG_RESET_ATTACKER 2

#define TOLERANCE_DEFENDING 180
#define TOLERANCE_ATTACKING 220

#define MAX_PLAYER_CNT	 32
#define MAX_COORDTYPE_CNT  2
#define MAX_VECTOR_CNT	  4
#define MAX_COORD_CNT		3

#define COORDTYPE_BODY 0
#define COORDTYPE_EYES 1

new g_coordsBody[MAX_PLAYER_CNT + 1][MAX_VECTOR_CNT][MAX_COORD_CNT];
new g_coordsEyes[MAX_PLAYER_CNT + 1][MAX_VECTOR_CNT][MAX_COORD_CNT];
new g_meter[MAX_PLAYER_CNT + 1], g_playerFlags[MAX_PLAYER_CNT + 1], g_snarkCnt[MAX_PLAYER_CNT + 1];
new g_bombPlanter, bool:g_bombPlanted;
new g_bombDefuser;
new g_msgFade, g_mapHasBomb;
new g_cstrike;
new g_immunityFlags[32];
new g_maxPlayers;
new g_campMeterMsgSync, g_isCampingMsgSync;

// declare CVAR pointers
new g_cvarDebug, g_cvarPunish, g_cvarLimit, g_cvarDisplay, g_cvarCheckAll, g_cvarShowSpec;
new g_cvarStart, g_cvarDamageReset, g_cvarDamageRestart, g_cvarHealth, g_cvarMoney;
new g_cvarMinPlayers, g_cvarAllow, g_cvarAnnounce, g_cvarSound, g_cvarImmunityFlags;

public plugin_natives()
{
	set_module_filter("filter_module");
	set_native_filter("filter_native");
}

public filter_module(const module[])
{
	return (equal(module, "cstrike") || equal(module, "csx")) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

public filter_native(const name[], index, trap)
{
	return (!trap) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
} 

public plugin_precache()
{	
	if (get_cvar_num("badcamper_sound") & SOUNDTYPE_SNORE) precache_sound("misc/snore.wav");
	precache_sound("player/heartbeat1.wav");

	return PLUGIN_CONTINUE;
}

public plugin_init()
{	
	new pluginVersion[] = "1.4 beta";
	
	register_plugin("Bad Camper", pluginVersion, "Brad Jones");

	register_cvar("badcamper_version", pluginVersion, FCVAR_SERVER|FCVAR_SPONLY);
	g_cvarDebug = register_cvar("badcamper_debug", "0");

	register_dictionary("bad_camper.txt");
	
	register_concmd("badcamper", "cmd_list", ADMIN_CVAR, "- lists available punishments and indicates which are active");
	
	g_cvarPunish				= register_cvar("badcamper_punish", "12");  // is camping to be punished and if so, how
	g_cvarLimit			 		= register_cvar("badcamper_limit", "35");  // seconds allowed to camp
	g_cvarDisplay		  	= register_cvar("badcamper_display", "1"); // at what percentage to display meter
	g_cvarCheckAll		 	= register_cvar("badcamper_check_all", "1"); // check both teams or just team with primary objective
	g_cvarStart			 		= register_cvar("badcamper_start", "4.0"); // number of seconds after the start of a round that the meter starts
	g_cvarDamageReset	 	= register_cvar("badcamper_damage_reset", "3"); // flag that indicates which meter(s) get reset upon a player attack
	g_cvarDamageRestart = register_cvar("badcamper_damage_restart", "4.0"); // number of seconds after giving or taking damage that the meter restarts
	g_cvarHealth				= register_cvar("badcamper_health", "10");  // health taken if 'health reduction' punishment flag set (at 100% camp meter)
	g_cvarMoney			 		= register_cvar("badcamper_money", "10"); // percentage of player's money taken if 'money reduction' punishment flag set (at 100% camp meter)
	g_cvarMinPlayers	  = register_cvar("badcamper_min_players", "0"); // minimum players before camping is allowed
	g_cvarAllow			 		= register_cvar("badcamper_allow", "0"); // when is camping allowed
	g_cvarAnnounce		 	= register_cvar("badcamper_announce", "3"); // announce a player's camping status
	g_cvarSound			 		= register_cvar("badcamper_sound", "1"); // type of sound to play when "badcamper_punish" includes the sound punishment
	g_cvarImmunityFlags = register_cvar("badcamper_immunity_flags", ""); // which access levels have immunity
	g_cvarShowSpec		 	= register_cvar("badcamper_show_spec", "1");	// let spectators see a player's meter?
}

public plugin_cfg()
{
	g_msgFade = get_user_msgid("ScreenFade");
	g_maxPlayers = get_maxplayers();
	g_isCampingMsgSync = CreateHudSyncObj();
	g_campMeterMsgSync = CreateHudSyncObj();
	
	get_pcvar_string(g_cvarImmunityFlags, g_immunityFlags, 31);

	if (module_exists("cstrike"))
	{
		g_cstrike = true;

//		register_event("StatusValue","set_spec_target","bd","1=2"); // from Kost
		register_event("SpecHealth2", "meter_display_spec_clear", "bd");
		register_event("BarTime", "event_bartime", "b");
		register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
		register_logevent("event_round_start", 2, "1=Round_Start");
		register_logevent("event_round_end", 2, "1=Round_End");
		register_logevent("event_round_end", 2, "1&Restart_Round_");
		
		g_mapHasBomb = engfunc(EngFunc_FindEntityByString,-1, "classname", "func_bomb_target");
	}
	else if (module_exists("dodx"))
	{
		register_event("RoundState", "event_round_start", "a", "1=1");
		register_event("RoundState", "event_round_end", "a", "1>2");
		register_event("ResetSens", "flags_reset", "b");
	}
}

public cmd_list(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED;
	
	new punishmentFlags = get_pcvar_num(g_cvarPunish);
	new punishSlap[32], punishHealth[32], punishSound[32], punishBlind[32], punishMoney[32], punishSnarks[32];

	// List each of the punishments available and indicate which of them are currently active.
	formatex(punishSlap,	31, "%5i %-1.1s%L",  1, (punishmentFlags & PUNISH_SLAP) ? "*" : "",	LANG_SERVER, "PUNISH_SLAP") ;
	formatex(punishHealth, 31, "%5i %-1.1s%L",  2, (punishmentFlags & PUNISH_HEALTH) ? "*" : "", LANG_SERVER, "PUNISH_HEALTH");
	formatex(punishSound,  31, "%5i %-1.1s%L (%L)",  4, (punishmentFlags & PUNISH_SOUND) ? "*" : "",  LANG_SERVER, "PUNISH_SOUND", LANG_SERVER, (get_pcvar_num(g_cvarSound) & SOUNDTYPE_SNORE) ? "SOUND_SNORE" : "SOUND_HEART");
	formatex(punishBlind,  31, "%5i %-1.1s%L",  8, (punishmentFlags & PUNISH_BLIND) ? "*" : "",  LANG_SERVER, "PUNISH_BLIND");
	formatex(punishMoney,  31, "%5i %-1.1s%L", 16, (punishmentFlags & PUNISH_MONEY) ? "*" : "",  LANG_SERVER, "PUNISH_MONEY");
	formatex(punishSnarks, 31, "%5i %-1.1s%L", 32, (punishmentFlags & PUNISH_SNARKS) ? "*" : "", LANG_SERVER, "PUNISH_SNARKS");
	
	if (id)
	{
		client_print(id, print_console, "%s", punishSlap);
		client_print(id, print_console, "%s", punishHealth);
		client_print(id, print_console, "%s", punishSound);
		client_print(id, print_console, "%s", punishBlind);
		client_print(id, print_console, "%s", punishMoney);
		client_print(id, print_console, "%s", punishSnarks);
	}
	else
	{
		server_print("%s", punishSlap);
		server_print("%s", punishHealth);
		server_print("%s", punishSound);
		server_print("%s", punishBlind);
		server_print("%s", punishMoney);
		server_print("%s", punishSnarks);
	}
	return PLUGIN_HANDLED;
}

public check_camping()
{	
	/* don't check, if the plugin is disabled */
	new punishmentFlags = get_pcvar_num(g_cvarPunish);
	if (punishmentFlags == 0) return;
	
	/* don't check, if there is only one player on server */
	new players[32], playerCnt;
	get_players(players, playerCnt, "ch");	// don't include bots or hltv
	if (playerCnt == 1 && !(get_pcvar_num(g_cvarDebug) && DBG_METER_ON_1)) return;

	/* determine acceptable camping values */
	new allowCampValue = get_pcvar_num(g_cvarAllow);
	new s_allowCampValue[8];
	new bool:allowCampByRatio;

	if (allowCampValue > 0)
	{
		get_pcvar_string(g_cvarAllow, s_allowCampValue, 7);
		allowCampByRatio = (contain(s_allowCampValue, "%") ==-1) ? false : true;
		allowCampValue = (allowCampByRatio) ? clamp(allowCampValue, 1, 100) : clamp(allowCampValue, 1, 32);
	}

	/* determine if either team is allowed to camp */
	new bool:allowTeamCamp[3] = {false, ...}; // using elements 1 and 2 to correspond to the values for TEAM1 and TEAM2
	new playerCnt_team1, playerCnt_team2, teamID, id;

	get_players(players, playerCnt, "h"); // don't include hltv
	if (playerCnt >= get_pcvar_num(g_cvarMinPlayers))
	{
		// based on their objective ...
		if (!get_pcvar_num(g_cvarCheckAll) && g_cstrike)
		{
			if (!g_mapHasBomb)
				allowTeamCamp[TEAM1] = true;
			else if (g_bombPlanted)
				allowTeamCamp[TEAM1] = true;
			else
				allowTeamCamp[TEAM2] = true;
		}

		// ... and based on calculated camp allowance
		if (allowCampValue > 0)
		{
			// get living player counts for each team
			get_players(players, playerCnt, "ah");	// skip dead players and hltv
			for (new playerIdx = 0; playerIdx < playerCnt; ++playerIdx)
			{
				id = players[playerIdx];
				teamID = get_user_team(id);
				if (teamID == TEAM1)
					playerCnt_team1++;
				else if (teamID == TEAM2)
					playerCnt_team2++;
			}

			if (allowCampByRatio)
			{
				// allow camp per ratio of players on player's team to players on other team
				if (!allowTeamCamp[TEAM1]) allowTeamCamp[TEAM1] = allowCampValue >= percent(playerCnt_team1, playerCnt_team2);
				if (!allowTeamCamp[TEAM2]) allowTeamCamp[TEAM2] = allowCampValue >= percent(playerCnt_team2, playerCnt_team1);
			}
			else
			{
				// allow camp per straight player count
				if (!allowTeamCamp[TEAM1]) allowTeamCamp[TEAM1] = (allowCampValue >= playerCnt_team1);
				if (!allowTeamCamp[TEAM2]) allowTeamCamp[TEAM2] = (allowCampValue >= playerCnt_team2);
			}
		}
	}

	/* handle each player's camping needs */
	new stdDev, campTolerance;
	new prevMeter, bool:punishCamper, Float:punishPercentage;
	new announceCampStatus = get_pcvar_num(g_cvarAnnounce);

	get_players(players, playerCnt, "ah");	// skip dead players and hltv
	for (new playerIdx = 0; playerIdx < playerCnt; ++playerIdx)
	{
		id = players[playerIdx];
		
		// pause the meter (don't cycle coords) if needed
		if (g_playerFlags[id] & METER_PAUSE) continue;
		
		// insert the current location of the player
		coords_insert(id, COORDTYPE_BODY);
		
		// ignore the meter if the player can legally camp or the player's meter is being ignored
		teamID = get_user_team(id);
		if (allowTeamCamp[teamID] || g_playerFlags[id] & METER_IGNORE) continue;

		// ignore if this player meets the immunity requirements
		if (has_flag(id, g_immunityFlags))
		{
			// insert the current coords of where the player's shot would hit, i.e. where the player is looking
			coords_insert(id, COORDTYPE_EYES);

			if (standing_still(id) && !looking_around(id) && g_meter[id] >= 65 && g_meter[id] < 80) continue;
		}

		// grab the standard deviation from the player coords
		stdDev = coords_stdv(id);

		// grab the camping tolerance based on current objective
		campTolerance = (!g_mapHasBomb || g_bombPlanted) ? TOLERANCE_ATTACKING : TOLERANCE_DEFENDING;
		
		// grab the current meter percentage
		prevMeter = g_meter[id];
		
		// add new percentage points to the meter
		g_meter[id] += (campTolerance- stdDev) / get_pcvar_num(g_cvarLimit);

		// ensure the meter falls within bounds		
		g_meter[id] = clamp(g_meter[id], 0, 100);

		// if the meter is trending down, give the player some love
		if (g_meter[id] < prevMeter)
		{
			if (g_meter[id] < 80)
			{
				// help the meter find it's way down
				g_meter[id]-= (prevMeter- g_meter[id]) / 3;
				
				if (prevMeter >= 80)
				{
					// ensure player isn't still being punished
					punish_stop_all(id);
					
					// announce that the player is no longer camping
					if (announceCampStatus && g_playerFlags[id] & CAMPER_ANNOUNCED) camper_announcement(id, false);
				}
			}
		}

		// determine how severe the punishment should be, if at all
		punishCamper = true; // now prove me wrong
		if (g_meter[id] == 100)		 punishPercentage = 1.00;
		else if (g_meter[id] >= 90) punishPercentage = 0.50;
		else if (g_meter[id] >= 80) punishPercentage = 0.10;
		else punishCamper = false;
		
		// punish the vile camper
		if (punishCamper)
		{
			if (punishmentFlags & PUNISH_SLAP)	 punish_slap(id, punishPercentage);
			if (punishmentFlags & PUNISH_HEALTH) punish_health_reduction(id, punishPercentage);
			if (punishmentFlags & PUNISH_BLIND)  punish_blind(id, punishPercentage);
			if (punishmentFlags & PUNISH_SOUND)  punish_sound(id, punishPercentage);
			if (punishmentFlags & PUNISH_MONEY)  punish_money_reduction(id, punishPercentage);
			if (punishmentFlags & PUNISH_SNARKS) punish_snark_attack(id, punishPercentage);

			// announce that the player is camping
			if (g_meter[id] >= 90 && !(g_playerFlags[id] & CAMPER_ANNOUNCED)) camper_announcement(id, true);
		}

		// let them know how long they've camped
		meter_display(id);
	}
}

camper_announcement(id, bool:isCamping)
{
	// announce to the opposite team this player's camping status
	new camperName[32];
	get_user_name(id, camperName, 31);
	
	new camperTeam = get_user_team(id);

	new announcementType = get_pcvar_num(g_cvarAnnounce);	
	if (announcementType)
	{
		new msgAnnouncement[16];
		copy(msgAnnouncement, 15, (isCamping) ? "CAMPING_STARTED" : "CAMPING_STOPPED");

		new playerId, announcement[64];
	
		for (playerId = 1; playerId <= g_maxPlayers; playerId++)
		{
			if (is_user_connected(playerId) && get_user_team(playerId) != camperTeam)
			{
				formatex(announcement, 63, "%L", playerId, msgAnnouncement, camperName);
				
				if (announcementType & ANNOUNCE_CHAT)
					client_print(playerId, print_chat, "[BADCAMPER] %s", announcement);
	
				if (announcementType & ANNOUNCE_HUD)
				{
					set_hudmessage(100, 100, 255,-1.0, 0.88, 0, 1.0, 6.0, 0.1, 0.1,-1);
					ShowSyncHudMsg(playerId, g_isCampingMsgSync, "%s", announcement);
				}
			}
		}			
		g_playerFlags[id] += (isCamping) ? CAMPER_ANNOUNCED :-CAMPER_ANNOUNCED;
	}
}

punish_health_reduction(id, Float:punishPercentage)
{
	set_pev(id, pev_dmg_inflictor, id);
//	set_pev(id, pev_health, get_user_health(id)- floatround(get_pcvar_float(g_cvarHealth) * punishPercentage)); <-- apparently this does bad things
	set_user_health(id, get_user_health(id)- floatround(get_pcvar_float(g_cvarHealth) * punishPercentage));
}

punish_sound(id, Float:punishPercentage)
{
	new soundFile[32];
	formatex(soundFile, 31, (get_pcvar_num(g_cvarSound) & SOUNDTYPE_SNORE) ? "misc/snore.wav" : "player/heartbeat1.wav");
	
	emit_sound(id, CHAN_VOICE, soundFile, punishPercentage, ATTN_NORM, 0, PITCH_NORM);
	if (!(g_playerFlags[id] & PLAYER_SOUND)) g_playerFlags[id] += PLAYER_SOUND;
}

punish_sound_stop(id)
{
	new soundFile[32];
	formatex(soundFile, 31, (get_pcvar_num(g_cvarSound) & SOUNDTYPE_SNORE) ? "misc/snore.wav" : "player/heartbeat1.wav");

	emit_sound(id, CHAN_VOICE, soundFile, 0.0, ATTN_NORM, 0, PITCH_NORM);
	if (g_playerFlags[id] & PLAYER_SOUND) g_playerFlags[id]-= PLAYER_SOUND;
}

punish_slap(id, Float:punishPercentage)
{
	for (new slapCnt = 1; slapCnt <= floatround(3.0 * punishPercentage, floatround_ceil); slapCnt++)
		user_slap(id, 0);
}

punish_money_reduction(id, Float:punishPercentage)
{
	if (g_cstrike)
	{
		new Float:lossPercentage = (get_pcvar_float(g_cvarMoney) / 100.0) * punishPercentage;
		new Float:currentMoney = float(cs_get_user_money(id));
		new reducedMoney = floatround(currentMoney- (currentMoney * lossPercentage));
		cs_set_user_money(id, reducedMoney);
	}
}

public meter_display(id)
{
	new displayMeter = get_pcvar_num(g_cvarDisplay);
	
	if (displayMeter > 0 && g_meter[id] >= displayMeter)
	{
		new r, g, b;
		
		if (g_meter[id] > 90)
			r = 255;
		else if (g_meter[id] > 80)
		{
			r = 255; 
			g = 100;
		}
		else if (g_meter[id] > 50) 
		{
			r = 255;
			g = 255;
		}
		else if (g_meter[id] > 20) 
			g = 255; 
		else 
			b = 255;

		set_hudmessage(r, g, b,-1.0, 0.85, 0, 1.0, 2.0, 0.1, 0.1,-1);
		ShowSyncHudMsg(id, g_campMeterMsgSync, "%L", id, "CAMP_METER", g_meter[id]);
		
		// if allowed and there's anyone specing this player, go ahead and show them the meter too
		if (g_cvarShowSpec)
		{
			new playerCnt, players[MAX_PLAYER_CNT], id_spectator;
			get_players(players, playerCnt, "bch");	// skip alive players, bots, and hltv
			for (new playerIdx = 0; playerIdx < playerCnt; ++playerIdx)
			{
				id_spectator = players[playerIdx];
				
				if (pev(id_spectator, pev_iuser2) == id)
				{
					ShowSyncHudMsg(id_spectator, g_campMeterMsgSync, "%L", id_spectator, "CAMP_METER", g_meter[id]);
				}				
			}
		}
	}
}

public standing_still(id)
{
	return vectors_same(id, COORDTYPE_BODY);
}

public looking_around(id)
{
	return !vectors_same(id, COORDTYPE_EYES);
}

public vectors_same(id, coordType)
{
	new curCoords[MAX_COORD_CNT], coordIdx;

	// grab the current coordinates
	for (coordIdx = 0; coordIdx < MAX_COORD_CNT; ++coordIdx)
		curCoords[coordIdx] = (coordType == COORDTYPE_BODY) ? g_coordsBody[id][0][coordIdx] : g_coordsEyes[id][0][coordIdx];

	for (new vectorIdx = 1; vectorIdx < MAX_VECTOR_CNT; ++vectorIdx)
		for (coordIdx = 0; coordIdx < MAX_COORD_CNT; ++coordIdx)
			if (curCoords[coordIdx] != ((coordType == COORDTYPE_BODY) ? g_coordsBody[id][vectorIdx][coordIdx] : g_coordsEyes[id][vectorIdx][coordIdx])) 
				return false;
	
	return true;
}

public coords_stdv(id)
{
	// get the total variance of all the coords
	new sum, avg, variance, varianceTot;
	new coordIdx, vectorIdx;

	for (coordIdx = 0; coordIdx < MAX_COORD_CNT; ++coordIdx)
	{
		// initialize our working variables
		sum = 0;
		variance = 0;
		
		// get the average of the coordinate
		for (vectorIdx = 0; vectorIdx < MAX_VECTOR_CNT; ++vectorIdx)
			sum += g_coordsBody[id][vectorIdx][coordIdx];
	
		avg = sum / MAX_VECTOR_CNT;
		
		// get the variance of the coordinate
		for (vectorIdx = 0; vectorIdx < MAX_VECTOR_CNT; ++vectorIdx)
			variance += power(g_coordsBody[id][vectorIdx][coordIdx]- avg, 2);
	
		variance = variance / (MAX_VECTOR_CNT- 1);
		
		// increment the total variance of all coordinates
		varianceTot += variance;
	}

	// return the standard deviation (std dev = the square root of the variance)
	return sqroot(varianceTot);
}

public coords_insert(id, coordType)
{
	// move each vector up one level, making room at the bottom for the new coords
	for (new vectorIdx = MAX_VECTOR_CNT- 1; vectorIdx > 0;--vectorIdx)
	{	
		for (new coordIdx = 0; coordIdx < MAX_COORD_CNT; ++coordIdx)
		{
			if (coordType == COORDTYPE_BODY)
				g_coordsBody[id][vectorIdx][coordIdx] = g_coordsBody[id][vectorIdx- 1][coordIdx];
			else
				g_coordsEyes[id][vectorIdx][coordIdx] = g_coordsEyes[id][vectorIdx- 1][coordIdx];
		}
	}
	
	// now that space is cleared for them, insert the current coords into the lowest vector
	if (is_user_connected(id))
	{
		if (coordType == COORDTYPE_BODY)
			get_user_origin(id, g_coordsBody[id][0], 0);
		else
			get_user_origin(id, g_coordsEyes[id][0], 3);
	}
}

public punish_snark_attack(id, Float:punishPercentage)
{
	new maxSnarkCnt = floatround(punishPercentage * 16.0);

	if (g_snarkCnt[id] < maxSnarkCnt)
	{
		// send the snarks out, two at a time
		server_cmd("monster snark #%i", id);
		server_cmd("monster snark #%i", id);
	
		g_snarkCnt[id] += 2;
	}
}

public punish_blind(id, Float:punishPercentage)
{
	new duration = (punishPercentage == 1.0) ? FADE_LENGTH_PERM : 1<<12;
	new holdTime = (punishPercentage == 1.0) ? FADE_LENGTH_PERM : 1<<8;
	new fadeType = (punishPercentage == 1.0) ? FADE_HOLD : FADE_IN;
	new blindness = 127 + floatround(128.0 * punishPercentage);
	
	if (is_user_alive(id))
	{
		if (!(g_playerFlags[id] & PLAYER_BLIND)) g_playerFlags[id] += PLAYER_BLIND;
			
		message_begin(MSG_ONE, g_msgFade, {0,0,0}, id); // use the magic #1 for "one client" 
		write_short(duration); // fade lasts this long duration 
		write_short(holdTime); // fade lasts this long hold time 
		write_short(fadeType); // fade type 
		write_byte(0); // fade red 
		write_byte(0); // fade green 
		write_byte(0); // fade blue  
		write_byte(blindness); // fade alpha  
		message_end(); 
	}	
}

public punish_blind_stop(id)
{
	if (g_playerFlags[id] & PLAYER_BLIND) g_playerFlags[id]-= PLAYER_BLIND;

	message_begin(MSG_ONE, g_msgFade, {0,0,0}, id); // use the magic #1 for "one client"  
	write_short(1<<12); // fade lasts this long duration  
	write_short(1<<8); // fade lasts this long hold time  
	write_short(FADE_OUT); // fade type
	write_byte(0); // fade red  
	write_byte(0); // fade green  
	write_byte(0); // fade blue	 
	write_byte(255); // fade alpha	 
	message_end();	
}

public meter_dmg_reset(id)
{
	// forgive previous camping transgressions
	punish_stop_all(id);
	g_meter[id] = 0;
	g_playerFlags[id] = 0;
	
	// the player has been through enough trauma (getting or giving damage)
	// so let's just ignore the camp meter for awhile
	meter_ignore(id);
	
	remove_task(id);
	set_task(get_pcvar_float(g_cvarDamageRestart), "meter_unignore", id);
}

public meter_pause(id)
{
	if (!(g_playerFlags[id] & METER_PAUSE)) g_playerFlags[id] += METER_PAUSE;
}

public meter_ignore(id)
{
	if (!(g_playerFlags[id] & METER_IGNORE)) g_playerFlags[id] += METER_IGNORE;
}

public meter_unpause(id)
{
	if (g_playerFlags[id] & METER_PAUSE) g_playerFlags[id]-= METER_PAUSE;
}

public meter_unignore(id)
{
	if (g_playerFlags[id] & METER_IGNORE) g_playerFlags[id]-= METER_IGNORE;
}

public start_checking()
{
	for (new id = 1; id <= 32; id++)
		meter_unignore(id);
}

public bomb_planting(planter)
{
	g_bombPlanter = planter;
	meter_pause(planter);
}

public event_bartime(id)
{
	if (read_data(1) == 0)
	{
		if (id == g_bombPlanter)
			g_bombPlanter = 0;
		else if (id == g_bombDefuser)
			g_bombDefuser = 0;
		else
			return;
			
		meter_unpause(id);
	}
}

public bomb_planted(planter)
{
	g_bombPlanter = 0;
	g_bombPlanted = true;
	meter_unpause(planter);
}

public bomb_defusing(defuser)
{
	g_bombDefuser = defuser;
	meter_pause(defuser);
}

public bomb_defused(defuser)
{	
	g_bombDefuser = 0;	
	meter_unpause(defuser);
}

public client_damage(attacker, victim, damage, wpnindex, hitplace, TA)
{
	if (attacker && victim && attacker != victim && !TA) 
	{
		new damageResetFlag = get_pcvar_num(g_cvarDamageReset);
		if (damageResetFlag & DMG_RESET_DEFENDER) 
			meter_dmg_reset(victim);
		if (damageResetFlag & DMG_RESET_ATTACKER) 
			meter_dmg_reset(attacker);
	}
}

public event_round_end()
{
	// stop checking for camping
	remove_task(TASKID_CHECK_CAMPING);
}

public event_new_round()
{
	// make sure any straggling monsters are sent away to a better place
	if (get_pcvar_num(g_cvarPunish) & PUNISH_SNARKS)
	{
		monsters_kill();
	}
}

public event_round_start()
{	
	g_bombPlanted = false;

	if (get_pcvar_num(g_cvarPunish))
	{
		// reset all the flags
		for (new id = 1; id <= 32; id++)
		{
			flags_reset(id);
			meter_ignore(id);
		}
		set_task(get_pcvar_float(g_cvarStart), "start_checking");
		set_task(2.0, "check_camping", TASKID_CHECK_CAMPING, _, _, "b");
	}
}

monsters_kill()
{
	// this function will kill ALL monsters on the map, it doesn't make a distinction
	// between monsters spawned by THIS plugin and monsters spawned some other way.
	// if it's a monster, it'll be killed.
	new Float:health;
	new maxEntities = global_get(glb_maxEntities);
	for (new entity = 1; entity < maxEntities; ++entity)
	{
		if (pev_valid(entity) && pev(entity, pev_flags) & FL_MONSTER)
		{
			set_pev(entity, pev_dmg_inflictor, 0);	// set the damage inflictor to "world"
			pev(entity, pev_health, health);				// grab the monster's current health
			set_pev(entity, pev_health, 0.0);				// kill the monster by taking away all it's health //pev_fuser4
		}
	}
}

public flags_reset(id)
{
	g_meter[id] = 0;
	g_playerFlags[id] = 0;
	g_snarkCnt[id] = 0;
	coords_reset(id);
}

public coords_reset(id)
{
	for (new vectorIdx = 0; vectorIdx < MAX_VECTOR_CNT; vectorIdx++)
		coords_insert(id, COORDTYPE_BODY);
}

public punish_stop_all(id)
{
	if (g_playerFlags[id] & PLAYER_BLIND) punish_blind_stop(id);
	if (g_playerFlags[id] & PLAYER_SOUND) punish_sound_stop(id);
	g_snarkCnt[id] = 0;
}

percent(is, of)
{
	return (of != 0) ? floatround(floatmul(float(is)/float(of), 100.0)) : 0;
}

/*
stock debug_log(const textID[] = "", const text[] = "", {Float,Sql,Result,_}:...)
{	
	new debugger = get_cvar_num("badcamper_debug");
	if (debugger || debugger ==-1)
	{
		// format the text as needed
		new formattedText[1024];
		format_args(formattedText, 1023, 1);
		// if there's a text identifier, add it
		if (textID[0])
			format(formattedText, 1023, "[%s] %s", textID, formattedText);
		// log text to file
		log_to_file("_badcamper.log", formattedText);
		// if there's someone to show text to, do so
		if (debugger && is_user_connected(debugger))
			client_print(debugger, print_chat, formattedText);
	}
	// not needed but gets rid of stupid compiler error
	if (text[0] == 0) return;
}
*/

/*
stock has_flag(id, flags[])
{
	return (get_user_flags(id) & read_flags(flags));
}
*/

public meter_display_spec_clear(id)
{
	ClearSyncHud(id, g_campMeterMsgSync);
}