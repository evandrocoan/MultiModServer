#include <amxmodx>
#include <cstrike>

enum MONEY_TYPE
{
	TEAM = 0,
	SHARE,
	
	MAX_TYPE
}

new cvar_enable

static const PLUGIN_NAME[] 	= "Team Money"
static const PLUGIN_AUTHOR[] 	= "Cheap_Suit"
static const PLUGIN_VERSION[]	= "1.0"

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_NAME, PLUGIN_VERSION, FCVAR_SPONLY|FCVAR_SERVER)
	cvar_enable = register_cvar("amx_teammoney", "1")
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
}

public Event_NewRound() if(get_pcvar_num(cvar_enable))
	set_task(0.1, "task_NewRound")
	
public task_NewRound()
{
	new Players[32], iNum = 0, i, iTeamMoney[MONEY_TYPE:MAX_TYPE] = 0
	
	get_players(Players, iNum, "ae", "TERRORIST")
	
	if(iNum > 0)
	{
		for(i = 0; i < iNum; ++i) 
			iTeamMoney[TEAM] += cs_get_user_money(Players[i])
	
		iTeamMoney[SHARE] = iTeamMoney[TEAM] / iNum
		
		for(i = 0; i < iNum; ++i)
		{
			cs_set_user_money(Players[i], iTeamMoney[SHARE], 1)
			client_print(Players[i], print_chat, "* Team Money: $%d   |   Share: $%d", iTeamMoney[TEAM], iTeamMoney[SHARE])
		}
	}
		
	iTeamMoney[TEAM] = 0, iTeamMoney[SHARE] = 0, iNum = 0
	
	get_players(Players, iNum, "ae", "CT")
	
	if(iNum > 0)
	{
		for(i = 0; i < iNum; ++i) 
			iTeamMoney[TEAM] += cs_get_user_money(Players[i])
	
		iTeamMoney[SHARE] = iTeamMoney[TEAM] / iNum
		
		for(i = 0; i < iNum; ++i)
		{
			cs_set_user_money(Players[i], iTeamMoney[SHARE], 1)
			client_print(Players[i], print_chat, "* Team Money: $%d   |   Share: $%d", iTeamMoney[TEAM], iTeamMoney[SHARE])
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1252\\ deff0\\ deflang1033{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
