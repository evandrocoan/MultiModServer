#include <amxmodx>
#include <ttt>

new cvar_price_fake, cvar_max_count;
new g_iCurrentCount, g_iItemID, g_pMsgTeamInfo;

public plugin_init()
{
	register_plugin("[TTT] Item: Fake Detective", TTT_VERSION, TTT_AUTHOR);
	cvar_max_count	= my_register_cvar("ttt_fake_max_count",	"1",	"Fake detective max count. (Default: 1)");
	cvar_price_fake	= my_register_cvar("ttt_price_fake",		"2",	"Fake detective price. (Default: 2)");

	g_pMsgTeamInfo	= get_user_msgid("TeamInfo");
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_FAKEDETECTIVE");
	g_iItemID = ttt_buymenu_add(name, get_pcvar_num(cvar_price_fake), PC_TRAITOR);
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_ENDED || gamemode == GAME_RESTARTING)
		g_iCurrentCount = 0;
}

public ttt_item_selected(id, item, name[], price)
{
	if(g_iItemID == item)
	{
		if(ttt_get_specialcount(PC_DETECTIVE))
		{
			if(g_iCurrentCount < get_pcvar_num(cvar_max_count))
			{
				set_fake_team(id);
				ttt_set_playerdata(id, PD_FAKESTATE, PC_DETECTIVE);
				g_iCurrentCount++;
				client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_FAKEDETECTIVE1", id, special_names[PC_DETECTIVE]);
				return PLUGIN_HANDLED;
			}
			else client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_FAKEDETECTIVE2", g_iCurrentCount, name);
		}
		else client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_FAKEDETECTIVE4", id, special_names[PC_DETECTIVE], name);
	}

	return PLUGIN_CONTINUE;
}

stock set_fake_team(id)
{
	new num, i;
	static players[32], name[32];
	get_players(players, num);
	get_user_name(id, name, charsmax(name));

	for(--num; num >= 0; num--)
	{
		i = players[num];
		message_begin(MSG_ONE_UNRELIABLE, g_pMsgTeamInfo, _, i);
		write_byte(id);
		write_string("CT");
		message_end();

		if(id != i && ttt_get_playerstate(i) == PC_TRAITOR)
			client_print_color(i, print_team_default, "%s %L", TTT_TAG, id, "TTT_FAKEDETECTIVE3", name, id, special_names[PC_DETECTIVE]);
	}
}