/*******************************************************************
*    Enemy Radar
*
*  by AdaskoMX 2008
*
*  Registered CVARs:
*
*  amx_erenabled	plugin enable / disable
*			DEFAULT SETTING: 1 (enabled)
*  amx_ertime		for how long enemy's last known position
*			will be visible on radar
*			DEFAULT SETTING: 4 (seconds)
*  amx_erradiocmds	if set to 1, after radio commands will be
*			automatically called in a few situations
*			DEFAULT SETTING: 1 (on)
*  amx_ershowmsg	number of seconds of showing hud message
*			about recent enemy in current sector
*			if set to 0, no message will be shown
*			DEFAULT SETTING: 10 (seconds)
*  amx_ershowattacker	if set to 1, enemy's position will be
*			visible on radar even without eye contact
*			DEFAULT SETTING: 0 (off)
*
*******************************************************************/

// temporarily
#define ENEMY_MSG "Enemy has been seen in this sector"

#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#define INTERVAL 0.5
#define FRQ (1 / INTERVAL)

#define PLUGIN "Enemy Radar"
#define VERSION "1.32"
#define AUTHOR "AdaskoMX"

#pragma semicolon 1

#define ENEMY_POS 62520
#define R_BACKUP 0
#define R_ENEMYSPOTTED 1
#define R_TAKINGFIRE 2

new m_fakeHostage, m_fakeHostageDie;
new enemy_origin[32][3];
new e_o_time[32], billyWasHere[32], friends[32], CsTeams:reportedAs[32],
	spottedInt[32], radioBan[32], bool:reported[32], teamRadioBan[CsTeams];

new PLUGIN_ENABLED, TIME_ON_RADAR, SHOW_ATTACKER, RADIO_CMDS, SHOW_WARNING;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	PLUGIN_ENABLED = register_cvar("amx_erenabled", "1", FCVAR_SERVER);
	TIME_ON_RADAR = register_cvar("amx_ertime", "4");
	SHOW_ATTACKER = register_cvar("amx_ershowattacker", "0");
	RADIO_CMDS = register_cvar("amx_erradiocmds", "1");
	SHOW_WARNING = register_cvar("amx_ershowmsg", "10");

	register_event("StatusValue","setTeam","be","1=1");
	register_event("StatusValue", "showStatus", "be", "1=2", "2!0");
	register_event("StatusValue", "hideStatus", "be", "1=1", "2=0");
	register_event("Damage","damage","b","2!0","3=0","4!0");
	register_event("HLTV", "newRound", "a", "1=0", "2=0");
	register_event("DeathMsg", "death", "a");

	m_fakeHostage = get_user_msgid("HostagePos");
	m_fakeHostageDie = get_user_msgid("HostageK");

	set_task(INTERVAL, "showEnemies", _, _, _, "b");
	return PLUGIN_CONTINUE;
}

public hideStatus(id) {
	if ( task_exists(ENEMY_POS + id) )
		remove_task(ENEMY_POS + id);
	return PLUGIN_CONTINUE;
}

public updatePos(param[]) {
	if( !get_pcvar_num(PLUGIN_ENABLED) )
		return PLUGIN_CONTINUE;

	if( friends[param[0] - 1] == 1 || (!is_user_alive(param[0]) && !param[2]) || !is_user_alive(param[1]) ) {
		hideStatus(param[0]);
	} else {
		get_user_origin(param[1], enemy_origin[param[1] - 1]);
		e_o_time[param[1] - 1] = floatround(get_pcvar_num(TIME_ON_RADAR) * FRQ);
		billyWasHere[param[1] - 1] = floatround(get_pcvar_num(SHOW_WARNING) * FRQ);
	}
	reported[param[0] - 1] = true;

	return PLUGIN_CONTINUE;
}

public setTeam(id) {
	friends[id - 1] = read_data(2);
}

radio(id, type, maxBan = 0, banFor = 8) {
	new CsTeams:team = cs_get_user_team(id);
	
	if(radioBan[id - 1] > maxBan || teamRadioBan[team] > maxBan) {
		return ;
	}
	
	new rcmd[11];
	switch(type) {
		case R_BACKUP: rcmd = "needbackup";
		case R_ENEMYSPOTTED: rcmd = "enemyspot";
		case R_TAKINGFIRE : rcmd = "takingfire";
	}
	engclient_cmd(id, rcmd);
	radioBan[id - 1] = banFor;
	teamRadioBan[team] = 4;
}

public showStatus(id) {
	if( !get_pcvar_num(PLUGIN_ENABLED) )
		return PLUGIN_CONTINUE;

	new param[3], CsTeams:tmp;
	param[0] = id;
	param[1] = read_data(2);
	if(param[1] < 1 || param[1] > 32)
		return PLUGIN_CONTINUE;
	
	param[2] = 0;
	
	if (friends[id - 1] == 2) {
		updatePos(param);
		tmp = cs_get_user_team(param[1]);
		if(tmp != reportedAs[param[1] - 1] && get_pcvar_num(RADIO_CMDS)) {
			if(spottedInt[id - 1]) {
				radio(id, R_BACKUP, 8, 12);
			} else if(!radioBan[id - 1]) {
				radio(id, R_ENEMYSPOTTED);
			}
			spottedInt[id - 1] = 4;

			reportedAs[param[1] - 1] = tmp;
		}
		set_task(0.2, "updatePos", ENEMY_POS + id, param, 3, "b");
	}
	return PLUGIN_CONTINUE;
}

public damage(id)
{
	if( !get_pcvar_num(PLUGIN_ENABLED) )
		return PLUGIN_CONTINUE;

	new dmg = read_data(2);
	new param[3], weapon;
	param[0] = get_user_attacker(id, weapon);
	if(param[0] < 1 || param[0] > 32)
		return PLUGIN_CONTINUE;
	param[1] = id;
	param[2] = 1;
	
	if(cs_get_user_team(id) == cs_get_user_team(param[0]))
		return PLUGIN_CONTINUE;

	new attackerHP, victimHP;
	
	if(get_pcvar_num(RADIO_CMDS) && weapon != CSW_HEGRENADE && weapon != CSW_KNIFE) {
		victimHP = get_user_health(id);
		attackerHP = get_user_health(param[0]);
		if((dmg > 50 || victimHP < 20) && victimHP < attackerHP) {
			radio(id, R_BACKUP, 4, 12);
		}
		if((dmg < 40 && attackerHP < 30) && victimHP > attackerHP) {
			radio(param[0], R_TAKINGFIRE, 4, 12);
		}
	}
	updatePos(param);
	if(get_pcvar_num(SHOW_ATTACKER)) {
		param[1] = param[0];
		param[0] = id;
		updatePos(param);
	}
	return PLUGIN_CONTINUE;
}

public death(){
	hideStatus(read_data(2));
	return PLUGIN_CONTINUE;
}

public newRound(){
	for( new i; i < 32; i ++) {
		hideStatus(i);
		enemy_origin[i] = {0, 0, 0};
		reportedAs[i] = CS_TEAM_UNASSIGNED;
		spottedInt[i] = 0;
		e_o_time[i] = 0;
		billyWasHere[i] = 0;
		reported[i] = false;
	}
	return PLUGIN_CONTINUE;
}

showOnRadar(id, pid, i) {
	message_begin(MSG_ONE_UNRELIABLE, m_fakeHostage, {0,0,0}, id);
	write_byte(id);
	write_byte(i);
	write_coord(enemy_origin[pid - 1][0]);
	write_coord(enemy_origin[pid - 1][1]);
	write_coord(enemy_origin[pid - 1][2]);
	message_end();

	message_begin(MSG_ONE_UNRELIABLE, m_fakeHostageDie, {0,0,0}, id);
	write_byte(i);
	message_end();
}

reportEnemy(id) {
	if(!reported[id - 1]) {
		set_hudmessage(255, 0, 0, 0.7, 0.7, 0, 1.0, 3.0, 0.2, 1.0, 3);
		show_hudmessage(id, ENEMY_MSG);
	} else reported[id - 1] = true;
}

public showEnemies() {
	if( !get_pcvar_num(PLUGIN_ENABLED) )
		return PLUGIN_CONTINUE;

	new players[32], num, i, j, id, pid, CsTeams:team, cnt;
	new pos1[3], pos2[3], bool:repp;
	get_players(players, num, "a");
	
	for( i = 0; i < 32; i ++) {
		if(e_o_time[i])
			e_o_time[i] --;
	}
	if(teamRadioBan[CS_TEAM_T]) teamRadioBan[CS_TEAM_T] --;
	if(teamRadioBan[CS_TEAM_CT]) teamRadioBan[CS_TEAM_CT] --;

	for( i = 0; i < num; i ++) {
		id = players[i];

		if(billyWasHere[id - 1])
			billyWasHere[id - 1] --;
		if(spottedInt[id - 1])
			spottedInt[id - 1] --;
		if(radioBan[id - 1])
			radioBan[id - 1] --;
		
		team = cs_get_user_team(id);
		if(team != CS_TEAM_T && team != CS_TEAM_CT)
			continue;
		cnt = 10;
		repp = false;
		for (j = 0; j < num; j ++ ) {
			pid = players[j];
			
			if( id != pid && cs_get_user_team(pid) != team) {
				if(billyWasHere[pid - 1] > 0) {
					get_user_origin(id, pos1);
					pos2 = enemy_origin[pid - 1];

					if(abs(pos1[2] - pos2[2]) < 150) {
						pos1[2] = pos2[2];
						if(get_distance(pos1, pos2) < 400) {
							repp = true;
							reportEnemy(id);
						}
					}
				}

				if(e_o_time[pid - 1] > 0) {
					cnt ++;
					showOnRadar(id, pid, cnt);
				}
			}
		}
		if(!repp) reported[id - 1] = false;
	}
	return PLUGIN_CONTINUE;
}
