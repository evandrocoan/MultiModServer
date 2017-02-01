/*
*   _______     _      _  __          __
*  | _____/    | |    | | \ \   __   / /
*  | |         | |    | |  | | /  \ | |
*  | |         | |____| |  | |/ __ \| |
*  | |   ___   | ______ |  |   /  \   |
*  | |  |_  |  | |    | |  |  /    \  |
*  | |    | |  | |    | |  | |      | |
*  | |____| |  | |    | |  | |      | |
*  |_______/   |_|    |_|  \_/      \_/
*
*
*
*  Last Edited: 12-31-07
*
*  ============
*   Changelog:
*  ============
*
*  v2.0
*    -Added ML
*
*  v1.2
*    -Fixed Bugs
*    -Optimized Code
*
*  v1.0
*    -Initial Release
*
*/

#define VERSION	"2.0"

#include <amxmodx>
#include <amxmisc>
#include <cstrike>

new tag[32]
new bool:CT
new limitteams
new autoteambalance

public plugin_init()
{
	register_plugin("Clan Vs. All",VERSION,"GHW_Chronic")
	register_concmd("amx_clanvsall","clanvsall",ADMIN_MENU," Clan Vs. Everyone Else <Clan Tag> <Clan Team: CT or T> ")
	register_concmd("amx_unclanvsall","unclanvsall",ADMIN_MENU," Allows People To Join Other Teams Again. ")

	register_dictionary("GHW_Clan_vs_All.txt")
}

public unclanvsall(id,level,cid)
{
	if(!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}

	set_cvar_num("mp_autoteambalance",autoteambalance)
	set_cvar_num("mp_limitteams",limitteams)

	console_print(id,"[AMXX] %L",id,"MSG_DEACTIVATE_CONSOLE")

	if(get_cvar_num("amx_show_activity")>1)
	{
		new aName[32]
		get_user_name(id,aName,31)
		client_print(0,print_chat,"[AMXX] %L",0,"MSG_DEACTIVATE_CHAT2",aName,tag)
	}
	else
		client_print(0,print_chat,"[AMXX] %L",0,"MSG_DEACTIVATE_CHAT1",tag)

	remove_task(1337)
	return PLUGIN_HANDLED
}

public clanvsall(id,level,cid)
{
	if(!cmd_access(id,level,cid,3))
	{
		return PLUGIN_HANDLED
	}

	new arg1[32]
	new arg2[32]
	read_argv(1,arg1,31)
	read_argv(2,arg2,31)

	if(equali(arg2,"CT")) CT=true
	else if(equali(arg2,"T")) CT=false
	else
	{
		console_print(id,"Invalid Team")
		return PLUGIN_HANDLED
	}

	format(tag,31,"%s",arg1)

	console_print(id,"[AMXX] %L",id,"MSG_DEACTIVATE_CONSOLE")

	if(get_cvar_num("amx_show_activity")>1)
	{
		new aName[32]
		get_user_name(id,aName,31)
		client_print(0,print_chat,"[AMXX] %L",0,"MSG_ACTIVATE_CHAT2",aName,tag)
	}
	else
		client_print(0,print_chat,"[AMXX] %L",0,"MSG_ACTIVATE_CHAT1",tag)

	limitteams = get_cvar_num("mp_limitteams")
	autoteambalance = get_cvar_num("mp_autoteambalance")
	set_cvar_num("mp_autoteambalance",0)
	set_cvar_num("mp_limitteams",0)

	checkteams()
	set_task(0.5,"checkteams",1337,"",0,"b")

	set_cvar_num("sv_restartround",1)
	return PLUGIN_HANDLED
}

public checkteams()
{
	static name[32], i, num, Player[32]
	get_players(Player,num)
	for(i=0;i<num;i++)
	{
		get_user_name(Player[i],name,31)
		if(containi(name,tag)!=-1)
		{
			if(CT && cs_get_user_team(Player[i])==CS_TEAM_T) cs_set_user_team(Player[i],CS_TEAM_CT)
			else if(!CT && cs_get_user_team(Player[i])==CS_TEAM_CT) cs_set_user_team(Player[i],CS_TEAM_T)
		}
		else
		{
			if(CT && cs_get_user_team(Player[i])==CS_TEAM_CT) cs_set_user_team(Player[i],CS_TEAM_T)
			else if(!CT && cs_get_user_team(Player[i])==CS_TEAM_T) cs_set_user_team(Player[i],CS_TEAM_CT)
		}
	}
}
