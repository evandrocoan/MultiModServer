#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <cs_teams_api>
#include <fun>
#include <ttt>

#define m_iNumSpawns 365

public plugin_init()
{
	register_plugin("[TTT] Join team management", TTT_VERSION, TTT_AUTHOR);

	register_message(get_user_msgid("ShowMenu"), "Message_ShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "Message_VGUIMenu");

	register_clcmd("chooseteam", "cmd_chooseteam");
	register_clcmd("jointeam", "cmd_chooseteam");
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_STARTED)
	{
		new num, id;
		static players[32];
		get_players(players, num, "bh");
		for(--num; num >= 0; num--)
		{
			id = players[num];
			set_pdata_int(id, m_iNumSpawns, 1);
		}
	}

	if(gamemode == GAME_ENDED)
		set_task(0.1, "randomize_teams");
}

public client_putinserver(id)
{
	if(ttt_get_gamemode() == GAME_STARTED && !is_user_bot(id))
		set_pdata_int(id, m_iNumSpawns, 1);
}

public Message_ShowMenu(msgid, dest, id)
{
	static MenuCode[22];
	get_msg_arg_string(4, MenuCode, charsmax(MenuCode));
	if(equal(MenuCode, "#Team_Select") || equal(MenuCode, "#Team_Select_Spect") || equal(MenuCode, "#IG_Team_Select") || equal(MenuCode, "#IG_Team_Select_Spect"))
	{
		join_team(id, msgid);
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public Message_VGUIMenu(msgid, dest, id)
{
	if(get_msg_arg_int(1) != 2)
		return PLUGIN_CONTINUE;

	join_team(id, msgid);
	return PLUGIN_HANDLED;
}

public join_team(id, msg)
{
	new param[2];
	param[0] = msg;
	set_task(0.1, "handle_join", id, param, sizeof(param));
}

public handle_join(param[], id)
{
	if(!is_user_connected(id))
		return;

	new block = get_msg_block(param[0]);
	set_msg_block(param[0], BLOCK_SET);

	new num, numCT;
	static players[32];
	get_players(players, num, "e", "TERRORIST");
	get_players(players, numCT, "e", "CT");

	if(numCT > num)
		engclient_cmd(id, "jointeam", "1");
	else engclient_cmd(id, "jointeam", "2");
	
	engclient_cmd(id, "joinclass", "1");
	set_msg_block(param[0], block);
}

public cmd_chooseteam(id)
	return PLUGIN_HANDLED;

public randomize_teams()
{
	if(ttt_get_gamemode() != GAME_ENDED)
		return;

	static players[32];
	new num, rannum, count[2], id, counter, jailmap = ttt_is_jailmap();
	get_players(players, num);

	for(--num; num >= 0; num--)
	{
		id = players[num];
		if(jailmap)
		{
			if(counter >= 3)
			{
				counter++;
				cs_set_player_team(id, CS_TEAM_CT, true);
			}
			else cs_set_player_team(id, CS_TEAM_T, true);
			continue;
		}

		rannum = random_num(1, 2);
		cs_set_player_team(id, CsTeams:rannum, true);
		count[rannum-1]++;
	}

	if(jailmap)
		return;

	get_players(players, num);
	new diffcount = abs(count[1]-count[0]);
	while(diffcount > 1)
	{
		id = players[random(num)];
		if(is_user_connected(id))
		{
			if(count[1] > count[0])
			{
				if(cs_get_user_team(id) != CS_TEAM_T)
				{
					cs_set_player_team(id, CS_TEAM_T, true);
					count[0]++;
					count[1]--;
					diffcount--;
				}
			}
			else
			{
				if(cs_get_user_team(id) != CS_TEAM_CT)
				{
					cs_set_player_team(id, CS_TEAM_CT, true);
					count[0]--;
					count[1]++;
					diffcount--;
				}
			}
		}
	}
}