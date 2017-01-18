#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define m_iJoinedState 121
#define JOINSTATE_INGAME 5

#define m_iUserPrefs 510
#define PREFS_VGUIMENUS (1<<0)

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#define HasVGUIMenus(%1) (get_pdata_int(%1, m_iUserPrefs) & PREFS_VGUIMENUS)
#define SetVGUIMenus(%1) set_pdata_int(%1, m_iUserPrefs, (get_pdata_int(%1, m_iUserPrefs) | PREFS_VGUIMENUS))
#define RemoveVGUIMenus(%1) set_pdata_int(%1, m_iUserPrefs, (get_pdata_int(%1, m_iUserPrefs) & ~PREFS_VGUIMENUS))

#define GetBit(%1,%2) (%1 &   (1 << (%2 & 31)))
#define SetBit(%1,%2)  %1 |=  (1 << (%2 & 31))
#define DelBit(%1,%2)  %1 &= ~(1 << (%2 & 31))

enum BalanceMethod {
	Balance_Off,
	Balance_Spec,
	Balance_Transfer,
	Balance_Kick
};

#define VGUIMENU_ARG_MENUID 1
#define VGUIMENU_MENUID_TEAMSELECT 2

new gVGUIMenus;

new gCvarImmunity;
new gCvarImmunityFlag;
new gCvarAutoTeam;
new gCvarAutoFavor;
new gCvarAutoClass[CsTeams];
new gCvarAllowSwitch;
new gCvarLimit[CsTeams];
new gCvarRatio[CsTeams];
new gCvarBalance;

new gLimitTeams;

new Trie:gBalanceMethods;

new gMsgIdShowMenu;

new gMaxPlayers;

/**

Change log

v0.0.7
Tried to fix the `Player out of range error`:
L 01/17/2017 - 18:32:41: [CSTRIKE] Player out of range (0)
L 01/17/2017 - 18:32:41: [AMXX] Displaying debug trace (plugin "teams_manager.amxx")
L 01/17/2017 - 18:32:41: [AMXX] Run time error 10: native error (native "cs_set_user_team")
L 01/17/2017 - 18:32:41: [AMXX]    [0] teams_manager.sma::Transfer (line 606)
L 01/17/2017 - 18:32:41: [AMXX]    [1] teams_manager.sma::TaskCheckTeams (line 344)

 */

public plugin_init() {
	register_plugin("Teams Manager AIO", "0.0.7", "Exolent");

	register_clcmd("jointeam", "CmdJoinTeam");
	register_clcmd("chooseteam", "CmdChooseTeam");

	register_message(get_user_msgid("VGUIMenu"), "MessageVGUIMenu");
	register_message((gMsgIdShowMenu = get_user_msgid("ShowMenu")), "MessageShowMenu");

	register_menucmd(register_menuid("Team_Select", 1), (1<<0|1<<1|1<<4|1<<5|1<<9), "MenuTeamSelect");

	register_menucmd(register_menuid("CT_Select", 1), (1<<0|1<<1|1<<2|1<<3|1<<4), "MenuModelSelect");
	register_menucmd(register_menuid("Terrorist_Select", 1), (1<<0|1<<1|1<<2|1<<3|1<<4), "MenuModelSelect");

	register_event("HLTV", "EventNewRound", "a", "1=0", "2=0");
	register_event("TextMsg", "EventRestartRound", "a", "2&#Game_w", "2&#Game_C");
	register_logevent("EventRoundEnd", 2, "1=Round_End");

	gCvarImmunity = register_cvar("team_immunity", "0");
	gCvarImmunityFlag = register_cvar("team_immunity_flag", "a");

	gCvarAutoTeam = register_cvar("team_autojoin_team", "0");
	gCvarAutoFavor = register_cvar("team_autojoin_favor", "0");
	gCvarAutoClass[CS_TEAM_T]  = register_cvar("team_autojoin_class_t",  "5");
	gCvarAutoClass[CS_TEAM_CT] = register_cvar("team_autojoin_class_ct", "5");

	gCvarAllowSwitch = register_cvar("team_allow_switch", "1");

	gCvarLimit[CS_TEAM_T]  = register_cvar("team_limit_t",  "32");
	gCvarLimit[CS_TEAM_CT] = register_cvar("team_limit_ct", "32");

	gCvarRatio[CS_TEAM_T]  = register_cvar("team_ratio_t",  "1");
	gCvarRatio[CS_TEAM_CT] = register_cvar("team_ratio_ct", "1");

	gCvarBalance = register_cvar("team_balance", "off");

	gBalanceMethods = TrieCreate();
	TrieSetCell(gBalanceMethods, "no", Balance_Off);
	TrieSetCell(gBalanceMethods, "off", Balance_Off);
	TrieSetCell(gBalanceMethods, "none", Balance_Off);
	TrieSetCell(gBalanceMethods, "spec", Balance_Spec);
	TrieSetCell(gBalanceMethods, "spectate", Balance_Spec);
	TrieSetCell(gBalanceMethods, "spectater", Balance_Spec);
	TrieSetCell(gBalanceMethods, "spectator", Balance_Spec);
	TrieSetCell(gBalanceMethods, "move", Balance_Transfer);
	TrieSetCell(gBalanceMethods, "switch", Balance_Transfer);
	TrieSetCell(gBalanceMethods, "transfer", Balance_Transfer);
	TrieSetCell(gBalanceMethods, "kick", Balance_Kick);

	gMaxPlayers = get_maxplayers();

	new mp_limitteams = get_cvar_pointer("mp_limitteams");

	gLimitTeams = clamp(get_pcvar_num(mp_limitteams), 0, gMaxPlayers);

	if(gLimitTeams == gMaxPlayers) {
		gLimitTeams = 0;
	}

	set_pcvar_num(mp_limitteams, 0);
	set_cvar_num("mp_autoteambalance", 0);
}

public client_disconnect(id) {
	CheckVGUIMenus(id);
}

public CmdJoinTeam(id) {
	if(Immune(id)) {
		return PLUGIN_CONTINUE;
	}

	if(!get_pcvar_num(gCvarAllowSwitch) && cs_get_user_team(id)/* != CS_TEAM_UNASSIGNED */) {
		return PLUGIN_HANDLED;
	}

	new arg[11];
	read_argv(1, arg, charsmax(arg));

	if(is_str_num(arg)) {
		new team = str_to_num(arg);

		switch(team) {
			case 1, 2: {
				if(!CanJoinTeam(id, team)) {
					return PLUGIN_HANDLED;
				}
			}
			case 5: {
				if(CanJoinTeam(id, 1)) {
					if(CanJoinTeam(id, 2)) {
						new favor = get_pcvar_num(gCvarAutoFavor);

						if(favor == 1 || favor == 2) {
							arg[0] = favor + '0';
							arg[1] = 0;

							ForceJoinTeam(id, arg, true);

							return PLUGIN_HANDLED;
						}

						return PLUGIN_CONTINUE;
					}

					ForceJoinTeam(id, "1", true);
				}
				else if(CanJoinTeam(id, 2)) {
					ForceJoinTeam(id, "2", true);
				}

				return PLUGIN_HANDLED;
			}
		}
	}

	return PLUGIN_CONTINUE;
}

public CmdChooseTeam(id) {
	if(!Immune(id) && !get_pcvar_num(gCvarAllowSwitch) && cs_get_user_team(id)/* != CS_TEAM_UNASSIGNED */) {
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public MessageVGUIMenu(msgId, dest, id) {
	if(is_user_connected(id)
	&& !Immune(id)
	&& get_msg_arg_int(VGUIMENU_ARG_MENUID) == VGUIMENU_MENUID_TEAMSELECT) {
		if(!CheckAutoJoin(id, msgId)) {
			SetBit(gVGUIMenus, id);

			RemoveVGUIMenus(id);

			set_task(0.1, "TaskForceChooseteam", id);
		}

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public TaskForceAutoJoin(params[], id) {
	HandleAutoJoin(id, params[0], params[1]);
}

public TaskForceChooseteam(id) {
	engclient_cmd(id, "chooseteam");
}

public MessageShowMenu(msgId, dest, id) {
	if(Immune(id)) {
		return PLUGIN_CONTINUE;
	}

	new menuCode[32];
	get_msg_arg_string(4, menuCode, charsmax(menuCode));

	if(containi(menuCode, "Team_Select") > 0 && CheckAutoJoin(id, msgId)) {
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

bool:CheckAutoJoin(id, msgId) {
	new team = get_pcvar_num(gCvarAutoTeam);

	if(team == 1 || team == 2 || team == 5 || team == 6) {
		new params[2];
		params[0] = team;
		params[1] = msgId;

		set_task(0.1, "TaskForceAutoJoin", id, params, sizeof(params));

		return true;
	}

	return false;
}

public MenuTeamSelect(id, key) {
	if(Immune(id)) {
		return PLUGIN_CONTINUE;
	}

	switch(++key % 10) {
		case 1, 2: {
			if(!CanJoinTeam(id, key)) {
				engclient_cmd(id, "chooseteam");
				return PLUGIN_HANDLED;
			}
		}
		case 5: {
			if(CanJoinTeam(id, 1)) {
				if(CanJoinTeam(id, 2)) {
					new favor = get_pcvar_num(gCvarAutoFavor);

					if(favor == 1 || favor == 2) {
						new team[2];
						team[0] = favor + '0';

						ForceJoinTeam(id, team);
					}

					CheckVGUIMenus(id);

					return (1 <= favor <= 2) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
				}

				ForceJoinTeam(id, "1");
			}
			else if(CanJoinTeam(id, 2)) {
				ForceJoinTeam(id, "2");
			}

			CheckVGUIMenus(id);
			return PLUGIN_HANDLED;
		}
		case 6, 0: {
			CheckVGUIMenus(id);
		}
	}

	return PLUGIN_CONTINUE;
}

public MenuModelSelect(id, key) {
	CheckVGUIMenus(id);
}

#define TASKID_CHECK_TEAMS 100

public EventNewRound() {
	set_task(0.1, "TaskCheckTeams", TASKID_CHECK_TEAMS);
}

enum _:PlayerData {
	Player_Id,
	Player_Immunity,
	Player_Time
};

public TaskCheckTeams() {
	new BalanceMethod:balanceMethod = GetBalanceMethod();

	if(!balanceMethod) return;

	new id, i, CsTeams:team, teamPlayers[CsTeams][32][PlayerData], numPlayers[CsTeams];
	for(id = 1; id <= gMaxPlayers; id++) {
		if(is_user_connected(id)) {
			team = cs_get_user_team(id);
			i = numPlayers[team]++;

			teamPlayers[team][i][Player_Id] = id;
			teamPlayers[team][i][Player_Immunity] = Immune(id);
			teamPlayers[team][i][Player_Time] = get_user_time(id);
		}
	}

	new maxPlayers[CsTeams];
	GetMaxPlayers(numPlayers, maxPlayers);

	new bool:transferImmunity = (get_pcvar_num(gCvarImmunity) < 2);

	new CsTeams:otherTeam;
	for(team = CS_TEAM_T; team <= CS_TEAM_CT; team++) {
		i = numPlayers[team];

		SortCustom2D(teamPlayers[team], i, "SortPlayers");

		otherTeam = CS_TEAM_SPECTATOR - team;

		while(i > maxPlayers[team]) {

			// server_print( "player_id: %d, shit1: %d, shit2: %d, shit3: %d", teamPlayers[team][i][Player_Id],
			// 		0 >= ( id = teamPlayers[team][i][Player_Id] ) > MAX_PLAYERS,
			// 		0 >= ( id = teamPlayers[team][i][Player_Id] ), id > MAX_PLAYERS );

			if(!transferImmunity && teamPlayers[team][--i][Player_Immunity]
			   || 0 >= ( id = teamPlayers[team][i][Player_Id] )
			   || id > MAX_PLAYERS) {
				break;
			}

			switch(balanceMethod) {
				case Balance_Spec: {
					Transfer(id, CS_TEAM_SPECTATOR);
				}
				case Balance_Transfer: {
					if(numPlayers[otherTeam] < maxPlayers[otherTeam]) {
						Transfer(id, otherTeam);

						teamPlayers[otherTeam][numPlayers[otherTeam]++] = teamPlayers[team][i];
					} else {
						Transfer(id, CS_TEAM_SPECTATOR);
					}
				}
				case Balance_Kick: {
					server_cmd("kick #%d ^"Kicked to balance the teams^"", get_user_userid(id));
				}
			}
		}

		numPlayers[team] = i;
	}
}

public SortPlayers(player1[], player2[], players[][], data[], dataSize) {
	// first order by immunity
	new diff = player2[Player_Immunity] - player1[Player_Immunity];

	if(!diff) {
		// then order by played time
		diff = player2[Player_Time] - player1[Player_Time];
	}

	//return diff & ~((~1 >> 1) & ~1);

	return clamp(diff, -1, 1);
}

public EventRestartRound() {
	remove_task(TASKID_CHECK_TEAMS);
}

public EventRoundEnd() {
	remove_task(TASKID_CHECK_TEAMS);
}

CheckVGUIMenus(id) {
	if(GetBit(gVGUIMenus, id)) {
		DelBit(gVGUIMenus, id);

		SetVGUIMenus(id);
	}
}

bool:CanJoinTeam(id, team) {
	new numPlayers[CsTeams];
	for(new i = 1; i <= gMaxPlayers; i++) {
		if(i != id && is_user_connected(i)) {
			numPlayers[cs_get_user_team(i)]++;
		}
	}

	new maxPlayers[CsTeams];
	GetMaxPlayers(numPlayers, maxPlayers);

	return (numPlayers[CsTeams:team] < maxPlayers[CsTeams:team]);
}

GetMaxPlayers(numPlayers[CsTeams], maxPlayers[CsTeams]) {
	maxPlayers[CS_TEAM_T]  = GetLimit(_:CS_TEAM_T);
	maxPlayers[CS_TEAM_CT] = GetLimit(_:CS_TEAM_CT);

	new ratio[CsTeams];
	ratio[CS_TEAM_T]  = get_pcvar_num(gCvarRatio[CS_TEAM_T]);
	ratio[CS_TEAM_CT] = get_pcvar_num(gCvarRatio[CS_TEAM_CT]);

	if(ratio[CS_TEAM_T] > 0 && ratio[CS_TEAM_CT] > 0) {
		ReduceFraction(ratio[CS_TEAM_T], ratio[CS_TEAM_CT]);

		new ratioDiff = ratio[CS_TEAM_T] - ratio[CS_TEAM_CT];

		if(ratioDiff) {
			new totalPlayers = numPlayers[CS_TEAM_T] + numPlayers[CS_TEAM_CT];
			new ratioInterval = ratio[CS_TEAM_T] + ratio[CS_TEAM_CT];
			new ratioTotal = 0;
			new expectedPlayers[CsTeams];

			while((ratioTotal + ratioInterval) <= totalPlayers
			&& (expectedPlayers[CS_TEAM_T]  + ratio[CS_TEAM_T])  <= maxPlayers[CS_TEAM_T]
			&& (expectedPlayers[CS_TEAM_CT] + ratio[CS_TEAM_CT]) <= maxPlayers[CS_TEAM_CT]) {
				expectedPlayers[CS_TEAM_T]  += ratio[CS_TEAM_T];
				expectedPlayers[CS_TEAM_CT] += ratio[CS_TEAM_CT];

				ratioTotal += ratioInterval;
			}

			new CsTeams:largerTeam = (ratioDiff > 0) ? CS_TEAM_T : CS_TEAM_CT;

			expectedPlayers[largerTeam] += ratio[largerTeam];

			if(expectedPlayers[largerTeam] > maxPlayers[largerTeam]) {
				expectedPlayers[largerTeam] = maxPlayers[largerTeam];
			}

			maxPlayers = expectedPlayers;
		}
	}

	if(gLimitTeams) {
		if((numPlayers[CS_TEAM_T] - gLimitTeams) > numPlayers[CS_TEAM_CT]) {
			maxPlayers[CS_TEAM_T] = min(maxPlayers[CS_TEAM_T], numPlayers[CS_TEAM_CT] + gLimitTeams);
		}
		else if((numPlayers[CS_TEAM_CT] - gLimitTeams) > numPlayers[CS_TEAM_T]) {
			maxPlayers[CS_TEAM_CT] = min(maxPlayers[CS_TEAM_CT], numPlayers[CS_TEAM_T] + gLimitTeams);
		}
	}
}

GetLimit(team) {
	new limit[11];
	get_pcvar_string(gCvarLimit[CsTeams:team], limit, charsmax(limit));

	new value = is_str_num(limit) ? str_to_num(limit) : gMaxPlayers;

	if(value < 0 || value > gMaxPlayers) {
		value = gMaxPlayers;
	}

	return value;
}

ForceJoinTeam(id, team[], bool:checkVGUI = false) {
	if(checkVGUI && HasVGUIMenus(id)) {
		SetBit(gVGUIMenus, id);

		RemoveVGUIMenus(id);
	}

	new class[2];
	class[0] = get_pcvar_num(gCvarAutoClass[CsTeams:(team[0] - '0')]) + '0';

	if(!('1' <= class[0] <= '5')) {
		class[0] = '5';
	}

	DoJoin(id, gMsgIdShowMenu, team, class);

	if(checkVGUI) {
		CheckVGUIMenus(id);
	}
}

HandleAutoJoin(id, team, msgId) {
	if(team == 5) {
		if(CanJoinTeam(id, 1)) {
			if(!CanJoinTeam(id, 2)) {
				team = 1;
			} else {
				new favor = get_pcvar_num(gCvarAutoFavor);

				if(favor == 1 || favor == 2) {
					team = favor;
				} else {
					// use random instead of the engine's auto join
					// so we can know the class to auto-assign the player to
					team = random(2) + 1; //
				}
			}
		}
		else if(CanJoinTeam(id, 2)) {
			team = 2;
		} else {
			return;
		}
	}

	new teamString[2];
	teamString[0] = team + '0';

	new class = (team == 6) ? 1 : get_pcvar_num(gCvarAutoClass[CsTeams:team]);

	if(!(1 <= class <= 5)) {
		class = 5;
	}

	new classString[2];
	classString[0] = class + '0';

	DoJoin(id, msgId, teamString, classString);
}

DoJoin(id, msgId, team[], class[]) {
	new block = get_msg_block(msgId);
	set_msg_block(msgId, BLOCK_SET);

	engclient_cmd(id, "jointeam", team);

	if(team[0] != '6') {
		engclient_cmd(id, "joinclass", class);
	}

	set_msg_block(msgId, block);
}

ReduceFraction(&numerator, &denominator) {
	if(!numerator || !denominator) return;

	new maxDivisor = sqroot(min(numerator, denominator));

	for(new i = 2, j, a; i <= maxDivisor; i += a) {
		j = 0;

		while(!(numerator % i) && !(denominator % i)) {
			numerator /= i;
			denominator /= i;

			j = 1;
		}

		if(j) {
			maxDivisor = sqroot(min(numerator, denominator));
		}

		if(i == 2) a = 1;
		else if(i < 7) a = 2;
		else a = 6 - a;
	}
}

bool:Immune(id) {
	if(get_pcvar_num(gCvarImmunity)) {
		new flags[27];
		get_pcvar_string(gCvarImmunityFlag, flags, charsmax(flags));

		return bool:has_all_flags(id, flags);
	}

	return false;
}

BalanceMethod:GetBalanceMethod() {
	new methodString[32], BalanceMethod:method;
	get_pcvar_string(gCvarBalance, methodString, charsmax(methodString));

	if(is_str_num(methodString)) {
		method = BalanceMethod:str_to_num(methodString);

		if(!(Balance_Off <= method < BalanceMethod)) {
			method = GetDefaultBalanceMethod();
		}
	} else {
		strtolower(methodString);

		if(!TrieGetCell(gBalanceMethods, methodString, method)) {
			method = GetDefaultBalanceMethod();
		}
	}

	return method;
}

BalanceMethod:GetDefaultBalanceMethod() {
	set_pcvar_string(gCvarBalance, "off");

	return Balance_Off;
}

Transfer(id, CsTeams:team) {
	if(team == CS_TEAM_SPECTATOR) {
		if(is_user_alive(id)) {
			user_silentkill(id);
		}

		cs_set_user_team(id, team);
	} else {
		cs_set_user_team(id, team);

		ExecuteHamB(Ham_CS_RoundRespawn, id);
	}

	new const teamNames[CsTeams][] = {
		"", "Terrorist", "Counter-Terrorist", "Spectator"
	};

	client_print(id, print_chat, "* You were transferred to the %s team to balance the teams.", teamNames[team]);
}
