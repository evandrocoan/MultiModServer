#include <amxmodx>

enum
{
	TEAM_NONE = 0,
	TEAM_T,
	TEAM_CT,
	TEAM_SPEC,
	
	MAX_TEAMS
};
new const g_cTeamChars[MAX_TEAMS] =
{
	'U',
	'T',
	'C',
	'S'
};
new const g_sTeamNums[MAX_TEAMS][] =
{
	"0",
	"1",
	"2",
	"3"
};
new const g_sClassNums[MAX_TEAMS][] =
{
	"1",
	"2",
	"3",
	"4"
};

// Old Style Menus
stock const FIRST_JOIN_MSG[] =		"#Team_Select";
stock const FIRST_JOIN_MSG_SPEC[] =	"#Team_Select_Spect";
stock const INGAME_JOIN_MSG[] =		"#IG_Team_Select";
stock const INGAME_JOIN_MSG_SPEC[] =	"#IG_Team_Select_Spect";
const iMaxLen = sizeof(INGAME_JOIN_MSG_SPEC);

// New VGUI Menus
stock const VGUI_JOIN_TEAM_NUM =		2;

new g_iTeam[33];
new g_iPlayers[MAX_TEAMS];

new tjm_join_team;
new tjm_switch_team;
new tjm_class[MAX_TEAMS];
new tjm_block_change;

public plugin_init()
{
	register_plugin("Team Join Management", "0.3", "Exolent");
	register_event("TeamInfo", "event_TeamInfo", "a");
	register_message(get_user_msgid("ShowMenu"), "message_ShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "message_VGUIMenu");
	tjm_join_team = register_cvar("tjm_join_team", "1");
	tjm_switch_team = register_cvar("tjm_switch_team", "1");
	tjm_class[TEAM_T] = register_cvar("tjm_class_t", "2");
	tjm_class[TEAM_CT] = register_cvar("tjm_class_ct", "4");
	tjm_block_change = register_cvar("tjm_block_change", "1");
}

public plugin_cfg()
{
	set_cvar_num("mp_limitteams", 32);
	set_cvar_num("sv_restart", 1);
}

public client_disconnect(id)
{
	remove_task(id);
}

public event_TeamInfo()
{
	new id = read_data(1);
	new sTeam[32], iTeam;
	read_data(2, sTeam, sizeof(sTeam) - 1);
	for(new i = 0; i < MAX_TEAMS; i++)
	{
		if(g_cTeamChars[i] == sTeam[0])
		{
			iTeam = i;
			break;
		}
	}
	
	if(g_iTeam[id] != iTeam)
	{
		g_iPlayers[g_iTeam[id]]--;
		g_iTeam[id] = iTeam;
		g_iPlayers[iTeam]++;
	}
}

public message_ShowMenu(iMsgid, iDest, id)
{
	static sMenuCode[iMaxLen];
	get_msg_arg_string(4, sMenuCode, sizeof(sMenuCode) - 1);
	if(equal(sMenuCode, FIRST_JOIN_MSG) || equal(sMenuCode, FIRST_JOIN_MSG_SPEC))
	{
		if(should_autojoin(id))
		{
			set_autojoin_task(id, iMsgid);
			return PLUGIN_HANDLED;
		}
	}
	else if(equal(sMenuCode, INGAME_JOIN_MSG) || equal(sMenuCode, INGAME_JOIN_MSG_SPEC))
	{
		if(should_autoswitch(id))
		{
			set_autoswitch_task(id, iMsgid);
			return PLUGIN_HANDLED;
		}
		else if(get_pcvar_num(tjm_block_change))
		{
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

public message_VGUIMenu(iMsgid, iDest, id)
{
	if(get_msg_arg_int(1) != VGUI_JOIN_TEAM_NUM)
	{
		return PLUGIN_CONTINUE;
	}
	
	if(should_autojoin(id))
	{
		set_autojoin_task(id, iMsgid);
		return PLUGIN_HANDLED;
	}
	else if(should_autoswitch(id))
	{
		set_autoswitch_task(id, iMsgid);
		return PLUGIN_HANDLED;
	}
	else if((TEAM_NONE < g_iTeam[id] < TEAM_SPEC) && get_pcvar_num(tjm_block_change))
	{
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public task_Autojoin(iParam[], id)
{
	new iTeam = get_new_team(get_pcvar_num(tjm_join_team));
	if(iTeam != -1)
	{
		handle_join(id, iParam[0], iTeam);
	}
}

public task_Autoswitch(iParam[], id)
{
	new iTeam = get_switch_team(id);
	if(iTeam != -1)
	{
		handle_join(id, iParam[0], iTeam);
	}
}

stock handle_join(id, iMsgid, iTeam)
{
	new iMsgBlock = get_msg_block(iMsgid);
	set_msg_block(iMsgid, BLOCK_SET);
	
	engclient_cmd(id, "jointeam", g_sTeamNums[iTeam]);
	
	new iClass = get_team_class(iTeam);
	if(1 <= iClass <= 4)
	{
		engclient_cmd(id, "joinclass", g_sClassNums[iClass - 1]);
	}
	set_msg_block(iMsgid, iMsgBlock);
}

stock get_new_team(iCvar)
{
	switch(iCvar)
	{
		case 1:
		{
			return TEAM_T;
		}
		case 2:
		{
			return TEAM_CT;
		}
		case 3:
		{
			return TEAM_SPEC;
		}
		case 4:
		{
			new iTCount = g_iPlayers[TEAM_T];
			new iCTCount = g_iPlayers[TEAM_CT];
			if(iTCount < iCTCount)
			{
				return TEAM_T;
			}
			else if(iTCount > iCTCount)
			{
				return TEAM_CT;
			}
			else
			{
				return random_num(TEAM_T, TEAM_CT);
			}
		}
	}
	return -1;
}

stock get_switch_team(id)
{
	new iTeam;
	
	new iTCount = g_iPlayers[TEAM_T];
	new iCTCount = g_iPlayers[TEAM_CT];
	switch(g_iTeam[id])
	{
		case TEAM_T: iTCount--;
		case TEAM_CT: iCTCount--;
	}
	if(iTCount < iCTCount)
	{
		iTeam = TEAM_T;
	}
	else if(iTCount > iCTCount)
	{
		iTeam = TEAM_CT;
	}
	else
	{
		iTeam = random_num(TEAM_T, TEAM_CT);
	}
	
	if(iTeam != g_iTeam[id])
	{
		return iTeam;
	}
	
	return -1;
}

stock get_team_class(iTeam)
{
	new iClass;
	if(TEAM_NONE < iTeam < TEAM_SPEC)
	{
		iClass = get_pcvar_num(tjm_class[iTeam]);
		if(iClass < 1 || iClass > 4)
		{
			iClass = random_num(1, 4);
		}
	}
	return iClass;
}

stock set_autojoin_task(id, iMsgid)
{
	new iParam[2];
	iParam[0] = iMsgid;
	set_task(0.1, "task_Autojoin", id, iParam, sizeof(iParam));
}

stock set_autoswitch_task(id, iMsgid)
{
	new iParam[2];
	iParam[0] = iMsgid;
	set_task(0.1, "task_Autoswitch", id, iParam, sizeof(iParam));
}

stock bool:should_autojoin(id)
{
	return ((5 > get_pcvar_num(tjm_join_team) > 0) && is_user_connected(id) && !(TEAM_NONE < g_iTeam[id] < TEAM_SPEC) && !task_exists(id));
}

stock bool:should_autoswitch(id)
{
	return (get_pcvar_num(tjm_switch_team) && is_user_connected(id) && (TEAM_NONE < g_iTeam[id] < TEAM_SPEC) && !task_exists(id));
}
