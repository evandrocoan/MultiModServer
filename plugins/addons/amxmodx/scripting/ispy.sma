new const PLUGINNAME[] = "I Spy"
new const VERSION[] = "0.7.2"
new const AUTHOR[] = "jghg & Girthesniper"
/*
Copyleft 2003-2004
http://www.amxmodx.org/forums/viewtopic.php?p=3439#3439
( old page at djeyl.net: http://djeyl.net/forum/index.php?showtopic=14459 )

  I Spy:
  ******
  Once in a while (amx_ispyodds) one guy in one of
  the teams will get disguised to look as the enemy
  team, spawned in the enemy spawn area, and given
  the message in center "YOU ARE THE SPY!!!".
  This person will remain spy until he dies,
  or the round ends. If the enemy team kills the spy,
  the team will get notified that there was a spy
  on the team, and the spy will undisguise as he
  falls dead.
  Spy will get a USP, ammo, grenades and armor,
  free of charge.
  A minimum number of MINIMUMMEMBERSINTEAM team
  members must be in a team before a spy will
  infiltrate it.

  cvars: amx_ispyodds (% chance of someone
		 becoming spy in a round)
  commands: amx_ispymodel (admin command for
            toggling the actual change of model
			for spy. Defaults to YES/ON/1)
			Was made for debug purposes, so
			you won't need it.

  Install
  -------
  As usual. If you don't know how, maybe you don't
  have what it takes.
  Besides, this plugin *requires*
  the following custom module: jghg2.
  You can find the latest versions
  to download of these from amxmodx.org's Modules
  forum.

  Releases
  --------
  2003-05-19:	v0.1		- First release. Enjoy.
                		As there are some troubles
				with setting the angle of a
				person, that feature is not
				included just yet... Hopefully
				it will be in the next release.

  2003-05-19:   v0.2
                		- amx_ispyhelp command added.
				- ispy/007.wav added. You must
				have this file! Download
				from plugin thread:
				http://amxmod.net/forums/viewtopic.php?p=92140

  2003-05-20:	v0.3
				- Spy's spawning angle should
				now be the same as the
				spawning point's angle. (go figure)
				- If you had any previous version
				you must update the Vexd module!

  2003-05-24:	v0.4
				- Disconnects any client that
				does not use the original
				player models.
				- Added missions for spy.
				Currently there are only assassinate
				mission, to try out for a while...

  2003-05-24:	v0.5
				- Pointing at a player will now
				always show name in brown colour.
				Will show more info for players
				on own team AND spy (!), but
				only the name for enemy team.

  2003-06-05:	v0.6
				- Updated to work with newest Vexd module
				You will need the newest module for this
				to work.
				- Bots never change models.
				- Changed spy mission hud channel...
				Sometimes (quite often) it was not shown.
				- Removed some debug messages in console
				for this version.

  2004-03-19:	v0.7
				- Updated to compile with AMX Mod X.
  2004-03-23:	v0.7.1
  				- Updated includes to use AMXX ones...

  2004-05-04    v0.7.2
				- Converted .wav file to .mp3
				- Updated use for mp3 play back

*/
#include <amxmodx>
#include <fun>
#include <cstrike>
#include <engine>
#include <amxmisc>

#define MINIMUMMEMBERSINTEAM 3
#define MAXPLAYERSINENGINE 32
#define TEAM_T 1
#define TEAM_CT 2

#define HMCHAN_NOTIFYBONUS 3456
#define HMCHAN_BRIEFING 125

#define TEAM_OFFSET	119

enum MISSIONTYPE {ASSASSINATE = 0,PROTECT,DELIVER}

new spy, spyWas
new MISSIONTYPE:mission
new bool:missionSuccess = false
new missionTarget[1]
new bonuses[MAXPLAYERSINENGINE][1] // right now only one field, 100 extra hp in slot 0, 2nd dimension.
// CT models: sas, gign, gsg9, urban
// T models: arctic, guerilla, leet, terror
new CTModels[4][] = {"sas","gign","gsg9","urban"}
new TModels[4][] = {"arctic","guerilla","leet","terror"}
//new spawnEntString[2][] = {"info_player_start","info_player_deathmatch"}
new alreadyCalledThisRound = false
new bool:rolled = false
new bool:changeModel = true
new bool:addedBonusesThisRound = false
new friend[33]
new gmsgStatusText

public addbonuses() {
	new allPlayers[32], allPlayersCount
	get_players(allPlayers,allPlayersCount,"a")
	for (new i = 0;i < allPlayersCount;i++) {
		//client_print(allPlayers[i],print_chat,"DEBUG: You have %d rounds of rewards left.",bonuses[allPlayers[i] - 1][0])
		// Check 100 extra hp field...
		if (bonuses[allPlayers[i] - 1][0] > 0) {
			// Add 100 extra hp to this player.
			set_user_health(allPlayers[i],get_user_health(allPlayers[i]) + 100)
			// Decrease bonuses left...
			bonuses[allPlayers[i] - 1][0]--
			// Inform player?
			set_hudmessage(50,240,50,-1.0,0.0,2,6.0,4.0,0.1,1.5,HMCHAN_NOTIFYBONUS)
			show_hudmessage(allPlayers[i],"100 extra health added in reward of successful mission. Rewards left: %d",bonuses[allPlayers[i] - 1][0])
		}
	}
}

public newround_event() {
	if (alreadyCalledThisRound)
		return PLUGIN_CONTINUE

	// Add bonuses for successful spies
	if (!addedBonusesThisRound) {
		//client_print(0,print_chat,"DEBUG: Adding bonuses in a second...")
		set_task(1.0,"addbonuses")
		addedBonusesThisRound = true
	}

	if (!rolled) {
		new rolledNumber = random_num(1,100)
		rolled = true
		if (rolledNumber > get_cvar_num("amx_ispyodds")) {
			//client_print(0,print_chat,"[I SPY DEBUG] No spy this round!")
			//console_print(0,"[I SPY DEBUG] No spy this round (%d>%d)",rolledNumber,get_cvar_num("amx_ispyodds"))
			spy = 0
			alreadyCalledThisRound = true

			return PLUGIN_CONTINUE
		}
	}

	new players[32]
	new aliveCTs, aliveTs, allCTs, allTs
	get_players(players,aliveCTs,"ae","CT")
	get_players(players,allCTs,"e","CT")
	if (aliveCTs != allCTs) {
		return PLUGIN_CONTINUE
	}

	get_players(players,aliveTs,"ae","TERRORIST")
	get_players(players,allTs,"e","TERRORIST")
	if (aliveTs != allTs) {
		return PLUGIN_CONTINUE
	}

	alreadyCalledThisRound = true

	new maxPlayers = get_maxplayers()
	new team = random_num(TEAM_T,TEAM_CT)
	new bool:checkOtherTeam = false
	new teamPlayers[32], enemyPlayers[32]
	new teamPlayersFound, enemyPlayersFound
	new i = 0

	do {
		switch (team) {
			case TEAM_T: {
				i++
				// A terrorist will become a spy at the CTs
				get_players(enemyPlayers,enemyPlayersFound,"e","CT")
				if (enemyPlayersFound < MINIMUMMEMBERSINTEAM) {
					checkOtherTeam = true
					team = TEAM_CT
				}
				else
					get_players(teamPlayers,teamPlayersFound,"e","TERRORIST")
			}
			case TEAM_CT: {
				i++
				// A CT will become a spy at the terrorists'
				get_players(enemyPlayers,enemyPlayersFound,"e","TERRORIST")
				if (enemyPlayersFound < MINIMUMMEMBERSINTEAM) {
					checkOtherTeam = true
					team = TEAM_T
				}
				else
					get_players(teamPlayers,teamPlayersFound,"e","CT")
			}
		}
	}
	while (checkOtherTeam && i < 2)

	if (teamPlayersFound < 1 && enemyPlayersFound < MINIMUMMEMBERSINTEAM) { //|| enemyPlayersFound >= maxPlayers / 2) {
		//client_print(0,print_chat,"[I SPY DEBUG] enemyPlayersFound(%d) is less than MINIMUMMEMBERS(%d), or",enemyPlayersFound,MINIMUMMEMBERSINTEAM)
		//client_print(0,print_chat,"they are equal to or over maxPlayers / 2(%d).",maxPlayers / 2)
		server_print("[I SPY DEBUG] enemyPlayersFound(%d) is less than MINIMUMMEMBERS(%d), or",enemyPlayersFound,MINIMUMMEMBERSINTEAM)
		server_print("they are equal to or over maxPlayers / 2(%d) Or no players in first team.",maxPlayers / 2)
		return PLUGIN_CONTINUE
	}

	//console_print(0,"i(%d) team(%d) teamPlayersFound(%d) enemyPlayersFound(%d)",i,team,teamPlayersFound,enemyPlayersFound)

	// This far, the spy's team is in "team", 1 for T, 2 for CT.
	// Randomize a player, the spy, from 0 to playersFound in players[].
	// He will first have his model changed to some of the opposing team's,
	// and then teleported to one free info_player_start/deathmatch point.
	// Check the spawn point's origin against all enemies' origins,
	// and spawn the spy where there is no enemy. Also set the angle
	// of the spy here.
	new realteamplayers[32], foundPlayers

	if (team == TEAM_T)
		get_players(realteamplayers, foundPlayers, "ace", "TERRORIST") // ace = find alive real players matching team
	else
		get_players(realteamplayers, foundPlayers, "ace", "CT")

	if (foundPlayers == 0) {
		server_print("No alive players in spies' team...")
		return PLUGIN_CONTINUE // No alive real players! Quit...
	}

	spy = realteamplayers[random_num(0, foundPlayers - 1)]
	//spy = teamPlayers[random_num(0,teamPlayersFound - 1)]
	new spyName[30]
	get_user_name(spy,spyName,29)
	//client_print(0,print_chat,"[I SPY DEBUG] %s is becoming spy for team %d...",spyName,team)
	//console_print(0,"[I SPY DEBUG] %s is becoming spy for team %d...",spyName,team)

	/* Old teleport part commented away..!
	const maxSpawns = 128
	new spawnPoints[maxSpawns]
	//new spawnsFound = find_entity(0,classname,spawnEntString[team - 1],spawnPoints,maxSpawns - 1)
	new ent = 0, spawnsFound = 0
	do {
		ent = find_ent_by_class(ent, spawnEntString[team - 1])
		if (ent != 0) {
			spawnPoints[spawnsFound] = ent
			spawnsFound++
		}
	}
	while (ent && spawnsFound < maxSpawns)

	new bool:foundFreeSpawn
	new Float:spawnOrigin[3]
	new Float:vicinity = 90.0 // 96 is playerheight (I think, could be wrong)
	new ii
	new playersInVicinity
	new entList[1]

	for (ii = 0;ii < spawnsFound && !foundFreeSpawn;ii++) {
		entity_get_vector(spawnPoints[ii], EV_VEC_origin, spawnOrigin)

		// Is this origin free? Search vicinity for "player"s
		playersInVicinity = find_sphere_class(0, "player", vicinity, entList, 1, spawnOrigin) // find_ent_sphere(0, spawnOrigin, vicinity, "player", entList, 0)

		if (playersInVicinity == 0)
			foundFreeSpawn = true
		else {
			foundFreeSpawn = false
			console_print(0,"[I SPY DEBUG] Found %d players in vicinity of spawn point %d.",playersInVicinity,spawnPoints[ii])
		}

	}

	if (!foundFreeSpawn) {
		// Didn't find a free spawn spot. Quit...
		client_print(0,print_chat,"[I SPY DEBUG] Didn't find a free spawn spot.")
		console_print(0,"[I SPY DEBUG] Didn't find a free spawn spot.")
		return PLUGIN_CONTINUE
	}
	else
		console_print(0,"[I SPY DEBUG] Found a free spawn spot on ii=(%d) (try #%d).",ii - 1,ii)
	*/

	// Disguise
	if (!is_user_bot(spy) && changeModel) {
		if (team == TEAM_T)
			cs_set_user_model(spy,CTModels[random_num(0,3)]) // T change to CT
		else
			cs_set_user_model(spy,TModels[random_num(0,3)]) // CT change to T
	}

	// Moved teleport to a set_task, as it seems this was
	// done a little early sometimes, maybe before player
	// got "teleported" to normal spawn.
	new parm[1]
	/*
	parm[0] = floatround(spawnOrigin[0])
	parm[1] = floatround(spawnOrigin[1])
	parm[2] = floatround(spawnOrigin[2])
	parm[3] = spawnPoints[ii]
	*/
	parm[0] = team

	set_task(0.01,"teleportspy",0,parm,1)

	//Sets format for hudmessage.
	//native set_hudmessage(red=200, green=100, blue=0,
	//Float:x=-1.0, Float:y=0.35, effects=0, Float:fxtime=6.0,
	//Float:holdtime=12.0, Float:fadeintime=0.1, Float:fadeouttime=0.2,channel=4);

	client_cmd(spy,"mp3 play sound/ispy/007.mp3")
	//client_print(spy,print_chat,"[I SPY] YOU ARE THE SPY!!!")
	console_print(0,"[I SPY DEBUG] %s became the spy!",spyName)

	// Find out what mission type spy will have.
	// Assassinate/Protect/Deliver Weapon
	// Assassinate: Spy must kill victim. If anyone else
	// kills victim, mission is failed.
	// Protect: Spy must see to it that some guy
	// on his team survives the round. Maybe check
	// that the spy is close enough sometimes, or has some
	// kind of interaction with the protectee.
	// Deliver Weapon: Steal a specified weapon from
	// a specified enemy. Deliver it to another team player
	// or maybe to a spawn point? Weapon must remain there
	// until round is over (spy can stand in the spot, armed
	// with that weapon, to defend himself). In endround event
	// checks where that weapon is, and if inside the proper
	// area, succeeds.

	// Randomize mission type
	//new MISSIONTYPE:mission = MISSIONTYPE:random_num(0,2)
	// right now only mission type assassinate:
	mission = ASSASSINATE

	switch (mission) {
		case ASSASSINATE: {
			// Randomize a target player in enemy team
			missionTarget[0] = enemyPlayers[random_num(0,enemyPlayersFound - 1)]
			new targetName[30]
			get_user_name(missionTarget[0],targetName,29)

			// Send mission briefing to spy.
			new briefing[] = "YOU ARE THE SPY!!!^nMISSION BRIEFING: You must find and kill %s. If you do not, we can't confirm the kill and the mission will be failed. Good luck."
			set_hudmessage(50,240,50,-1.0,0.4,2,1.0,4.0,0.1,1.5,HMCHAN_BRIEFING)
			//set_hudmessage(0, 100, 0, -1.0, 0.65, 2, 0.02, 10.0, 0.01, 0.1, 2)
			show_hudmessage(spy,briefing,targetName,targetName)
			client_print(spy,print_chat,"MISSION BRIEFING: You must find and kill %s! Good luck.",targetName)
		}
		case PROTECT: {
		}
		case DELIVER: {
		}
	}

	return PLUGIN_CONTINUE
}

public teleportspy(parm[1]) {
	new team = parm[0]
	/*
	new Float:spawnAngle[3]

	entity_get_vector(parm[3],EV_VEC_angles,spawnAngle)
	entity_set_vector(spy,EV_VEC_angles,spawnAngle)

	new origin[3]
	origin[0] = parm[0]
	origin[1] = parm[1]
	origin[2] = parm[2]
	set_user_origin(spy,origin)
	*/

	// Instead of setting origin, change team and spawn, then change team back...
	server_print("Spy will be spawned: %d, team offset: %d, team: %d", spy, TEAM_OFFSET, team)
	if (team == TEAM_T)
		cs_set_user_team(spy, TEAM_CT) // set_offset(spy, TEAM_OFFSET, TEAM_CT) //
	else
		cs_set_user_team(spy, TEAM_T) // set_offset(spy, TEAM_OFFSET, TEAM_T) //

	// Spawn spy
	spawn(spy)
	// Set team back
	//set_offset(spy, TEAM_OFFSET, team) // 
	cs_set_user_team(spy, team)

	// Give some stuff, must be given after teleport,
	// or spy wont catch'em.
	give_item(spy, "item_assaultsuit")
	set_user_armor(spy,100)

	new wpnList[32]
	new number
	new foundUSP = false
	get_user_weapons(spy,wpnList,number)
	for (new iii = 0;iii < number && !foundUSP;iii++) {
		if (wpnList[iii] == CSW_USP)
			foundUSP = true
	}

	if (!foundUSP)
		give_item(spy,"weapon_usp")

	if (team == TEAM_CT)
		give_item(spy,"item_thighpack")

	give_item(spy,"weapon_hegrenade")
	give_item(spy,"weapon_flashbang")
	give_item(spy,"weapon_flashbang")
	give_item(spy,"weapon_smokegrenade")
	give_item(spy,"ammo_45acp")
	give_item(spy,"ammo_45acp")
	give_item(spy,"ammo_45acp")
	give_item(spy,"ammo_45acp")
	give_item(spy,"ammo_45acp")
	give_item(spy,"ammo_45acp")
}

public roundend_event() {
	rolled = false
	alreadyCalledThisRound = false
	addedBonusesThisRound = false
	if (spy == 0) {
		//client_print(0,print_chat,"[I SPY] No one was spy this round...")
		//console_print(0,"[I SPY] No one was a spy this round...")
		return PLUGIN_CONTINUE
	}
	else if (spy < 0) {
		//console_print(0,"[I SPY] A spy already got killed and you know it :-)...")
		debrief(spyWas)
		// do nothing more
	}
	else if (spy > 0 && !is_user_alive(spy)) {
		// Spy has been killed, but probably the death_event got a runtime error
		// or maybe the spy dropped? Need to undisguise.
		new spyName[30]
		get_user_name(spy,spyName,29)
		client_print(0,print_chat,"[I SPY] %s was the spy this round. Too bad he got killed.",spyName)
		//console_print(0,"[I SPY] %s was the spy this round. Too bad he got killed",spyName)
		undisguise()

		debrief(spy)
	}
	else if (spy > 0) {
		new spyName[30]
		get_user_name(spy,spyName,29)
		client_print(0,print_chat,"[I SPY] %s was the spy this round, and you didn't even notice!",spyName)
		//console_print(0,"[I SPY] %s was the spy this round, and you didn't even notice!",spyName)
		undisguise()

		debrief(spy)
	}

	// Reset stuff
	spy = 0
	missionSuccess = false
	return PLUGIN_CONTINUE
}

public debrief(id) {
	// Debrief on mission.
	set_hudmessage(50,240,50,-1.0,-1.0,1,1.0,8.0,0.1,1.5,HMCHAN_BRIEFING)
	if (missionSuccess == true) {
		new debriefing[] = "You carried out your mission successfully!^nYou will be rewarded.^n^nOver and out."
		//native set_hudmessage(red=200, green=100, blue=0,
		//Float:x=-1.0, Float:y=0.35, effects=0, Float:fxtime=6.0,
		//Float:holdtime=12.0, Float:fadeintime=0.1, Float:fadeouttime=0.2,channel=4);
		show_hudmessage(id,debriefing)
		client_print(0,print_chat,"[I SPY] The spy successfully completed his mission and will be rewarded for that.")
		//console_print(0,"[I SPY] The spy successfully completed his mission and will be rewarded for that.")
	}
	else {
		new debriefing[] = "You failed to complete your secret mission. Shame on you!"
		show_hudmessage(id,debriefing)
		client_print(0,print_chat,"[I SPY] The spy did not complete his mission. Shame on him!")
		//console_print(0,"[I SPY] The spy did not complete his mission. Shame on him!")

		// Heheh
		if (is_user_alive(id)) {
			new slapDmg = 10
			if (get_user_health(id) <= slapDmg)
				slapDmg = 0
			user_slap(id,slapDmg,1)
		}
	}
}

public undisguise() {
	if (spy && is_user_connected(spy) && !is_user_bot(spy) && changeModel)
		cs_reset_user_model(spy)
}

public death_event() {
	// Check if there is a spy, or quit
	if (spy <= 0)
		return PLUGIN_CONTINUE

	// Sometimes run time error 10 on next line (read_data(2))
	new victim_id = read_data(2)

	// Assassinate mission check.
	if (mission == ASSASSINATE && victim_id == missionTarget[0]) {
		//client_print(0,print_chat,"DEBUG: Running I Spy assassinate check...")
		//console_print(0,"DEBUG: Running I Spy assassinate check...")
		new WTI, targetKiller = get_user_attacker(victim_id,WTI)
		if (targetKiller != spy) {
			//client_print(0,print_chat,"DEBUG: No, spy is not killer.")
			console_print(0,"DEBUG: No, spy is not killer of target.")
			// bad things happen? may need to reset stuff here later, like who's target etc
		}
		else {
			// Obviously our spy killed the target.
			// Great job, 007. Set spy as eligible for
			// rewards...
			//client_print(0,print_chat,"DEBUG: Spy killed target! Adding 5 to slot %d",spy - 1)
			new name[40]
			get_user_name(spy,name,39)
			console_print(0,"DEBUG: Spy killed target! Adding 5 to slot %d (%d,%s)",spy - 1,spy,name)
			bonuses[spy - 1][0] += 5 // Five extra rounds of 100 extra hp added to current spy's account.
			missionSuccess = true
		}
		return PLUGIN_CONTINUE
	}

 	if (victim_id != spy || victim_id < 1 || victim_id > get_maxplayers()) {
		return PLUGIN_CONTINUE
	}

	new weaponTypeId
	new spyKiller = get_user_attacker(victim_id,weaponTypeId)
	new weaponName[31]
	get_weaponname(weaponTypeId,weaponName,30)

	new spyKillerName[31]
	get_user_name(spyKiller,spyKillerName,30)
	new spyName[31]
	get_user_name(spy,spyName,30)
	client_print(0,print_chat,"[I SPY] %s and his %s somehow found out that %s was a spy, and annihilated him!",spyKillerName,weaponName,spyName)
	console_print(0,"[I SPY] %s and his %s somehow found out that %s was a spy, and annihilated him!",spyKillerName,weaponName,spyName)

	undisguise()

	// Only enemy team hears this. Spy team could hear something else...
	new spyTeam = get_user_team(spy)
	//console_print(0,"[I SPY] Spy's team was %d!",spyTeam)
	new teamMates[32]
	new teamMembers
	new teamName[10]
	if (spyTeam == TEAM_T)
		format(teamName,10,"CT")
	else
		format(teamName,3,"TERRORIST")
	get_players(teamMates,teamMembers,"e",teamName)
	for (new i = 0;i < teamMembers;i++) {
		client_cmd(teamMates[i],"spk ^"unauthorized personnel in perimeter terminated^"")
	}
	//get_players(players,num,"ae","CT")
	//client_cmd(0,"spk ^"unauthorized personnel presence in perimeter detected, the intruder is terminated^"")

	// Set to -1 to mark that there were a spy, but he got killed.
	spyWas = spy
	spy = -1

	return PLUGIN_CONTINUE
}

public togglechangemodel(id,level,cid) {
	if (!cmd_access(id,level,cid,1)) {
		return PLUGIN_CONTINUE
	}

	changeModel = !changeModel

	if (id > 0) {
		if (changeModel)
			client_print(id,print_console,"[I SPY] Spies' models WILL be changed.")
		else
			client_print(id,print_console,"[I SPY] Spies' models will NOT be changed.")
	}
	else {
		if (changeModel)
			console_print(0,"[I SPY] Spies' models WILL be changed.")
		else
			console_print(0,"[I SPY] Spies' models will NOT be changed.")
	}

	if (!is_user_bot(spy) && !changeModel && spy > 0) {
		cs_reset_user_model(spy)
	}

	return PLUGIN_HANDLED
}

public plugin_precache() {
	precache_sound("ispy/007.mp3")
	//precache_sound("player/heartbeat1.wav")

	/* you can use other force modes but only for models */
	force_unmodified(force_exactfile,{0,0,0},{0,0,0},"models/player/arctic/arctic.mdl")
	force_unmodified(force_exactfile,{0,0,0},{0,0,0},"models/player/gign/gign.mdl")
	force_unmodified(force_exactfile,{0,0,0},{0,0,0},"models/player/gsg9/gsg9.mdl")
	force_unmodified(force_exactfile,{0,0,0},{0,0,0},"models/player/guerilla/guerilla.mdl")
	force_unmodified(force_exactfile,{0,0,0},{0,0,0},"models/player/leet/leet.mdl")
	force_unmodified(force_exactfile,{0,0,0},{0,0,0},"models/player/sas/sas.mdl")
	force_unmodified(force_exactfile,{0,0,0},{0,0,0},"models/player/terror/terror.mdl")
	force_unmodified(force_exactfile,{0,0,0},{0,0,0},"models/player/urban/urban.mdl")
	force_unmodified(force_exactfile,{0,0,0},{0,0,0},"models/player/vip/vip.mdl")

	/* probably is already set to 1.0 */
	set_cvar_float("mp_consistency",1.0)

	/* give some output */
	server_print("Forcing unmodified files activated in I Spy.")
}

public showhelp(id) {
	new title[] = "I Spy help page"
	show_motd(id, "Randomly, sometimes someone on a team will become a spy, spawning in the enemy team spawn area, disguised to look exactly like the enemy. The spy will remain disguised until the round ends, or it gets killed. The spy will have a mission, which must be carried out before the end of the round. If the mission is successful, the spy will be rewarded.", title)
}

public client_disconnect(id) {
	// Reset bonus, if player disconnects.
	if (bonuses[id - 1][0] != 0)
		bonuses[id - 1][0] = 0
}

public show_name(id) {
	new name[32]
	new pointId = read_data(2)
	get_user_name(pointId,name,31)
	new buffer[64]
	format(buffer,63,"%s",name)


	if (friend[id] == 1 || pointId == spy || !is_user_alive(id)) {
		new clip, ammo, wpnid = get_user_weapon(pointId,clip,ammo)
		new wpnname[32]
		get_weaponname(wpnid,wpnname,31)
		format(buffer,63,"[ispy] %s: %d HP, %d AP, %s",name,get_user_health(pointId),get_user_armor(pointId),wpnname[7])
    }
	else {
		format(buffer,63,"[ispy] %s",name)
	}

	message_begin(MSG_ONE,gmsgStatusText,{0,0,0},id)
	write_byte(1)
	write_string(buffer)
	message_end()

	return PLUGIN_CONTINUE
}

public set_team(id) {
	friend[id] = read_data(2)

	return PLUGIN_CONTINUE
}

public hide_status(id) {
	message_begin(MSG_ONE,gmsgStatusText,{0,0,0},id)
	write_byte(1)
	write_string("")
	message_end()

	return PLUGIN_CONTINUE
}

public plugin_init() {
	register_plugin(PLUGINNAME,VERSION,AUTHOR)

	// New round event
	register_event("ResetHUD","newround_event", "b")

	// Round ending events
	register_event("SendAudio","roundend_event","a","2=%!MRAD_terwin","2=%!MRAD_ctwin","2=%!MRAD_rounddraw")
	register_event("TextMsg","roundend_event","a","2&#Game_C","2&#Game_w")

	// Death event
	register_event("DeathMsg","death_event","a")

	// Point at someone event?
	gmsgStatusText = get_user_msgid("StatusText")

	register_event("StatusValue","set_team","be","1=1")
	register_event("StatusValue","show_name","be","1=2","2!0")
	register_event("StatusValue","hide_status","be","1=1","2=0")

	register_concmd("amx_ispymodel","togglechangemodel",ADMIN_LEVEL_H,": toggles the change of model for spies.")

	register_clcmd("amx_ispyhelp","showhelp",0,": displays help on I Spy.")

	register_cvar("amx_ispyodds","10")
}
