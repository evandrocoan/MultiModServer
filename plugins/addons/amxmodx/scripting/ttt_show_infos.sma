#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <ttt>

new g_iCached[2], g_iKilledWho[33][33], g_pCommandMenuID1, g_pCommandMenuID2, g_iPlayerStates[33][2];
new const g_szIconNames[][] = 
{
	"suicide", "p228", "", "scout", "hegrenade", "xm1014", "c4", "mac10", "aug", "hegrenade", "elite", "fiveseven",
	"ump45", "sg550", "galil", "famas", "usp", "glock18", "awp", "mp5navy", "m249", "m3", "m4a1", "tmp", "g3sg1", "hegrenade",
	"deagle", "sg552", "ak47", "crowbar", "p90", "0", "1", "2", "3"
};

new const g_szColors[][] = 
{
	"#848284", // grey
	"#fc0204", // red
	"#0402fc", // blue
	"#048204", // green
	"#E211F5", // purple
	"#F57011"  // orange
};

public plugin_precache()
{
	static icon[32];
	for(new i = 0; i <= charsmax(g_szIconNames); i++)
	{
		if(i < 5 && strlen(g_szIconNames[i]) < 3) continue;
		formatex(icon, charsmax(icon), "gfx/ttt/%s.gif", g_szIconNames[i]);
		precache_generic(icon);
	}
}

public plugin_init()
{
	register_plugin("[TTT] Show infos", TTT_VERSION, TTT_AUTHOR);

	// register_clcmd("say /tttme", "ttt_show_me");
	// register_clcmd("say_team /tttme", "ttt_show_me");
	g_pCommandMenuID1 = ttt_command_add("/me");
	g_pCommandMenuID2 = ttt_command_add("Last states");

	RegisterHamPlayer(Ham_Killed, "Ham_Killed_post", 1);
}

public ttt_command_selected(id, menuid, name[])
{
	if(g_pCommandMenuID1 == menuid)
		ttt_show_me(id);
	else if(g_pCommandMenuID2 == menuid)
		show_last_states(id);
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_PREPARING || gamemode == GAME_RESTARTING || gamemode == GAME_STARTED)
	{
		new num, id;
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];
			reset_player(id);
			if(gamemode == GAME_STARTED)
				swap_player_states(id);
		}

		if(gamemode == GAME_STARTED)
			g_iCached[1] = false;
	}
}

public client_putinserver(id)
{
	g_iPlayerStates[id][0] = -1;
	g_iPlayerStates[id][1] = -1;
	reset_player(id, id);
}

stock swap_player_states(id)
{
	g_iPlayerStates[id][0] = g_iPlayerStates[id][1];
	g_iPlayerStates[id][1] = ttt_get_playerstate(id);
}

stock reset_player(id, other = 0)
{
	new num, player;
	static players[32];
	get_players(players, num);
	for(--num; num >= 0; num--)
	{
		player = players[num];
		g_iKilledWho[id][player] = false;
		if(other)
		{
			g_iKilledWho[player][id] = false;
		}
	}
}

public ttt_winner(team)
{
	g_iCached[0] = false;
	g_iCached[1] = false;
	new num, id;
	static players[32];
	get_players(players, num);
	for(--num; num >= 0; num--)
	{
		id = players[num];
		client_cmd(id, "-attack");
		client_cmd(id, "-attack2");
		show_motd_winner(id);
	}
}

public ttt_showinfo(id, target)
{
	new mode = ttt_get_gamemode(); 
	if(!is_user_alive(target) && is_user_alive(id) &&  mode != GAME_ENDED && mode != GAME_OFF)
		show_motd_info(id, target);
}

public ttt_show_me(id)
{
	if(ttt_get_gamemode() == GAME_OFF)
		return;

	if(!is_user_alive(id))
	{
		const SIZE = 1536;
		static msg[SIZE+1];
		new len;

		len += formatex(msg[len], SIZE - len, "<html><head><meta charset='utf-8'><style>body{background:#ebf3f8 no-repeat center top;}</style></head><body>");
		len += formatex(msg[len], SIZE - len, "</br><center><h2>%L</h2></center>", id, "TTT_WINNER_LINE7");

		new num, player, count, alive_state;
		static players[32], name[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			player = players[num];
			if(g_iKilledWho[id][player])
			{
				count++;
				alive_state = ttt_get_alivestate(player);
				get_user_name(player, name, charsmax(name));
				len += formatex(msg[len], SIZE - len, "<b style='color:%s'>[%L] %s</b></br>", g_szColors[alive_state], id, special_names[alive_state], name);
			}
		}

		if(!count) len += formatex(msg[len], SIZE - len, "%L", id, "TTT_WINNER_LINE6");
		len += formatex(msg[len], SIZE - len, "</body></html>");

		show_motd(id, msg, "");
	}
	else client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ALIVE");
}

public Ham_Killed_post(victim, killer, shouldgib)
{
	if(!is_user_connected(killer))
		killer = ttt_find_valid_killer(victim, killer);

	if(!is_user_connected(killer) || ttt_get_gamemode() == GAME_ENDED)
		return HAM_IGNORED;

	g_iKilledWho[killer][victim] = ttt_get_alivestate(victim);
	return HAM_HANDLED;
}

public show_motd_winner(id)
{
	if(!is_user_connected(id) || ttt_get_gamemode() == GAME_OFF)
		return;

	const SIZE = 1536;
	static wholemsg[SIZE+1], msg[SIZE+1], motdname[64], staticsize;
	new zum, len;
	if(!g_iCached[0])
	{
		new i, highest, num, killedstate, currentstate;
		new name[32], Traitors[256], Detectives[256], suicide[128], kills[128], c4[70], out[64], players[32];

		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			i = players[num];

			killedstate = ttt_get_alivestate(i);
			currentstate = ttt_get_playerstate(i);
			get_user_name(i, name, charsmax(name));

			if(currentstate == PC_TRAITOR || killedstate == PC_TRAITOR)
				format(Traitors, charsmax(Traitors), "%s, %s", name, Traitors);

			if(currentstate == PC_DETECTIVE || killedstate == PC_DETECTIVE)
				format(Detectives, charsmax(Detectives), "%s, %s", name, Detectives);

			if(ttt_get_playerdata(i, PD_KILLEDBY) == 3005)
				format(suicide, charsmax(suicide), "%s, %s", name, suicide);

			if(ttt_get_playerdata(i, PD_C4EXPLODED))
				format(c4, charsmax(c4), "%s, %s", name, c4);

			if(ttt_get_playerdata(i, PD_KILLCOUNT) > highest)
			{
				if(currentstate != PC_DEAD)
					zum = currentstate;
				else zum = killedstate;

				highest = ttt_get_playerdata(i, PD_KILLCOUNT);
				formatex(kills, charsmax(kills), "%L", LANG_SERVER, "TTT_WINNER_LINE4", g_szColors[zum], LANG_SERVER, special_names[zum], name, highest);
			}
		}

		if(strlen(Traitors) > 2)
			Traitors[strlen(Traitors)-2] = '^0';

		if(strlen(Detectives) > 2)
			Detectives[strlen(Detectives)-2] = '^0';

		if(strlen(suicide) > 2)
			suicide[strlen(suicide)-2] = '^0';

		if(strlen(c4) > 2)
			c4[strlen(c4)-2] = '^0';

		new winner = ttt_get_winner();
		if(winner == PC_DETECTIVE)
			winner++;

		if(winner == PC_TRAITOR)
			formatex(out, charsmax(out), "%L", LANG_SERVER, "TTT_TWIN");
		else if(winner == PC_INNOCENT)
			formatex(out, charsmax(out), "%L", LANG_SERVER, "TTT_IWIN");

		len += formatex(msg[len], SIZE - len, "<html><head><meta charset='utf-8'><style>body{background:#ebf3f8 url('gfx/ttt/%d.gif') no-repeat center top;}</style></head><body>", winner);
		len += formatex(msg[len], SIZE - len, "</br><center><h1>%s</h1></center>", out);

		if(strlen(Detectives) > 0)
			len += formatex(msg[len], SIZE - len, "<b style='color:%s'>%L: %s</b><br/>", g_szColors[PC_DETECTIVE], LANG_SERVER, special_names[PC_DETECTIVE], Detectives);
		len += formatex(msg[len], SIZE - len, "<b style='color:%s'>%L: %s</b><br/><br/>", g_szColors[PC_TRAITOR], LANG_SERVER, special_names[PC_TRAITOR], Traitors);

		if(strlen(kills) > 0)
			len += formatex(msg[len], SIZE - len, "%s<br/>", kills);

		if(strlen(suicide) > 0)
			len += formatex(msg[len], SIZE - len, "<b style='color:%s'>%L<br/>", g_szColors[PC_SPECIAL], LANG_SERVER, "TTT_WINNER_LINE2", suicide);

		if(strlen(c4) > 0)
			len += formatex(msg[len], SIZE - len, "<b style='color:%s'>%L<br/>", g_szColors[PC_SPECIAL], LANG_SERVER, "TTT_WINNER_LINE3", c4);

		formatex(motdname, charsmax(motdname), "%L", LANG_SERVER, "TTT_WINNER_LINE1");
		g_iCached[0] = true;
		staticsize = len;
	}
	len = staticsize;
	formatex(wholemsg, charsmax(msg), "%s", msg);

	// len += formatex(wholemsg[len], SIZE - len, "%L</br>", LANG_SERVER, "TTT_WINNER_LINE7");
	new num, player, count, alive_state;
	static players[32], name[32];
	get_players(players, num);
	for(--num; num >= 0; num--)
	{
		player = players[num];
		if(g_iKilledWho[id][player])
		{
			count++;
			alive_state = ttt_get_alivestate(player);
			get_user_name(player, name, charsmax(name));
			len += formatex(wholemsg[len], SIZE - len, "%L <b style='color:%s'>[%L] %s</b></br>", LANG_SERVER, "TTT_WINNER_LINE7", g_szColors[alive_state], LANG_SERVER, special_names[alive_state], name);
		}
	}

	if(!count) formatex(wholemsg[len], SIZE - len, "%L", id, "TTT_WINNER_LINE6");
	
	new karma = ttt_get_playerdata(id, PD_KARMA), karmatemp = ttt_get_playerdata(id, PD_KARMATEMP);
	zum = ttt_get_alivestate(id);
	len += formatex(wholemsg[len], SIZE - len, "%L<br/>", LANG_SERVER, "TTT_WINNER_LINE5", g_szColors[zum], karma, g_szColors[zum], karmatemp-karma, g_szColors[zum], karmatemp);
	len += formatex(wholemsg[len], SIZE - len, "</body></html>");

	show_motd(id, wholemsg, motdname);
	wholemsg[0] = '^0';
}

public show_motd_info(id, target)
{
	static name[2][32], killmsg[64];
	get_user_name(target, name[0], charsmax(name[]));
	new minutes = (ttt_get_playerdata(target, PD_KILLEDTIME) / 60) % 60;
	new seconds = ttt_get_playerdata(target, PD_KILLEDTIME) % 60;
	ttt_get_kill_message(target, ttt_get_playerdata(target, PD_KILLEDBY), killmsg, charsmax(killmsg), 0);

	const SIZE = 1536;
	static msg[SIZE+1], motdname[64];
	new len, killedstate = ttt_get_alivestate(target);
	if(killedstate > 3)
		killedstate = 0;

	len += formatex(msg[len], SIZE - len, "<html><head><meta charset='utf-8'><style>body{background:#ebf3f8 url('gfx/ttt/%d.gif') no-repeat center top;}</style></head><body>", killedstate);
	len += formatex(msg[len], SIZE - len, "</br><center><h1>%L %s</h1>", id, special_names[killedstate], name[0]);
	len += formatex(msg[len], SIZE - len, "<h1>%L</h1>", id, "TTT_INFO_LINE3", g_szColors[killedstate], ttt_get_bodydata(target, BODY_TIME));
	len += formatex(msg[len], SIZE - len, "%L <img src='gfx/ttt/%s.gif'></center>", id, "TTT_INFO_LINE2", g_szColors[killedstate], minutes, seconds, killmsg);
	len += formatex(msg[len], SIZE - len, "</body></html>");
	formatex(motdname, charsmax(motdname), "%L", id, "TTT_INFO_LINE1");

	show_motd(id, msg, motdname);

	get_user_name(id, name[1], charsmax(name[]));
	ttt_log_to_file(LOG_MISC, "%s inspected deadbody of %s", name[1], name[0]);
}

public show_last_states(id)
{
	const SIZE = 1536;
	static msg[SIZE+1], show;

	if(!g_iCached[1])
	{
		new len;
		len += formatex(msg[len], SIZE - len, "<html><head><meta charset='utf-8'><style>body{background:#ebf3f8 no-repeat center top;}</style></head><body>");

		new num, player, player_state, count[PLAYER_CLASS];
		static players[32], name[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			player = players[num];
			player_state = g_iPlayerStates[player][0];
			if(player_state > -1)
			{
				count[player_state]++;
				get_user_name(player, name, charsmax(name));
				len += formatex(msg[len], SIZE - len, "<b style='color:%s'>[%L] %s</b></br>", g_szColors[player_state], id, special_names[player_state], name);
			}
		}

		len += formatex(msg[len], SIZE - len, "</br>");
		for(new i = 0; i < PLAYER_CLASS; i++)
		{
			if(count[i])
			{
				show = true;
				len += formatex(msg[len], SIZE - len, "<b style='color:%s'>%L: %d</b></br>", g_szColors[i], id, special_names[i], count[i]);
			}
		}

		len += formatex(msg[len], SIZE - len, "</body></html>");
		g_iCached[1] = true;
	}

	if(show)
		show_motd(id, msg, "");
}