#include <amxmodx>
#include <hamsandwich>
#include <sqlx>
#include <ttt>

#pragma defclasslib sqlite sqlite
#pragma dynamic 32768
new const g_iPointValue[PLAYER_STATS-1] =
{
	100,      // Game winning kills
	150,      // Kills as Innocent // Right ones
	100,      // Kills as Detective
	100,      // Kills as Traitor
	-100,     // Team kills
	10,       // Times innocent
	10,       // Times detective
	10,       // Times traitor
	50,       // Bomb planted
	50,       // Bomb exploded
	50        // Bomb defused
};            

new g_iPlayerStats[33][PLAYER_STATS], g_szPlayerName[33][40], cvar_stats, g_pCommandMenuID1, g_pCommandMenuID2;
new Handle:g_pSqlTuple, Trie:g_tTop10Players[10];

public plugin_init()
{
	register_plugin("[TTT] Stats System", TTT_VERSION, TTT_AUTHOR);

	cvar_stats = my_register_cvar("ttt_stats", "2", "Stats 0/1/2 off/MySQL/Sqlite. (Default: 2)");
	// register_clcmd("say /ttttop", "show_top10");
	// register_clcmd("say_team /ttttop", "show_top10");
	// register_clcmd("say /tttstats", "show_stats");
	// register_clcmd("say_team /tttstats", "show_stats");

	g_pCommandMenuID1 = ttt_command_add("Top 10");
	g_pCommandMenuID2 = ttt_command_add("Your stats");

	RegisterHamPlayer(Ham_Killed, "Ham_Killed_post", 1);
}

public plugin_cfg()
	set_task(0.1, "delayed_plugin_cfg");

public delayed_plugin_cfg()
{
	MySQL_Init();
	for(new i = 0; i < 10; i++)
		g_tTop10Players[i] = TrieCreate();
	MySQL_TOP10();
}

public plugin_natives()
{
	register_library("ttt");
	register_native("ttt_set_stats", "_set_stats");
	register_native("ttt_get_stats", "_get_stats");
}

public plugin_end()
{
	if(g_pSqlTuple)
		SQL_FreeHandle(g_pSqlTuple);
	for(new i = 0; i < 10; i++)
		TrieDestroy(g_tTop10Players[i]);
}

public ttt_command_selected(id, menuid, name[])
{
	if(g_pCommandMenuID1 == menuid)
		show_top10(id);
	else if(g_pCommandMenuID2 == menuid)
		show_stats(id);
}

public client_putinserver(id)
{
	reset_client(id);
	g_szPlayerName[id][0] = EOS;
	if(is_user_bot(id))
		return;

	get_user_name(id, g_szPlayerName[id], charsmax(g_szPlayerName[]));
	escape_mysql(g_szPlayerName[id], charsmax(g_szPlayerName[]));
	MySQL_Load(id);
}

public client_disconnect(id)
{
	MySQL_Save(id);
	reset_client(id);
	g_szPlayerName[id][0] = EOS;
}

public client_infochanged(id)
{
	if(!is_user_connected(id))
		return;

	static newname[40], oldname[32];
	get_user_name(id, oldname, charsmax(oldname));
	get_user_info(id, "name", newname, charsmax(newname));

	if(!equali(newname, oldname))
	{
		reset_client(id);
		g_szPlayerName[id] = newname;
		escape_mysql(g_szPlayerName[id], charsmax(g_szPlayerName[]));
		MySQL_Load(id);
	}
}

public MySQL_Init()
{
	new cvar = get_pcvar_num(cvar_stats);
	if(cvar == 1)
	{
		new host[64], user[33], pass[32], db[32];
		get_cvar_string("amx_sql_host", host, charsmax(host));
		get_cvar_string("amx_sql_user", user, charsmax(user));
		get_cvar_string("amx_sql_pass", pass, charsmax(pass));
		get_cvar_string("amx_sql_db", db, charsmax(db));
		g_pSqlTuple = SQL_MakeDbTuple(host, user, pass, db);
	}
	else if(cvar == 2)
	{
		SQL_SetAffinity("sqlite");
		g_pSqlTuple = SQL_MakeDbTuple("localhost", "root", "", "ttt_stats");

	}
	else set_fail_state("[TTT] CVAR set wrongly, plugin turning off!");

	new error[128];
	new code, Handle:connection = SQL_Connect(g_pSqlTuple, code, error, charsmax(error));
	if(connection == Empty_Handle)
		set_fail_state(error);

	new Handle:queries;
	if(cvar == 1)
	{
		queries = SQL_PrepareQuery(connection, 
			"CREATE TABLE IF NOT EXISTS ttt_stats(\
				id int unsigned NOT NULL AUTO_INCREMENT, \
				player_name varchar(40) UNIQUE NOT NULL default '', \
				gwk int(10), \
				kills_i int(10), \
				kills_d int(10), \
				kills_t int(10), \
				rdm int(10), \
				innocent int(15), \
				detective int(10), \
				traitor int(10), \
				bomb_planted int(10), \
				bomb_exploded int(10), \
				bomb_defused int(10), \
				total_points int(32), \
				PRIMARY KEY (id)\
			);"
		);
	}
	else if(cvar == 2)
	{
		queries = SQL_PrepareQuery(connection, 
			"CREATE TABLE IF NOT EXISTS ttt_stats(\
				id INTEGER PRIMARY KEY, \
				player_name CHAR(40) UNIQUE NOT NULL default '', \
				gwk INTEGER, \
				kills_i INTEGER, \
				kills_d INTEGER, \
				kills_t INTEGER, \
				rdm INTEGER, \
				innocent INTEGER, \
				detective INTEGER, \
				traitor INTEGER, \
				bomb_planted INTEGER, \
				bomb_exploded INTEGER, \
				bomb_defused INTEGER, \
				total_points INTEGER\
			);"
		);
	}

	if(!SQL_Execute(queries))
	{
		SQL_QueryError(queries, error, charsmax(error));
		set_fail_state(error);
	}

	SQL_FreeHandle(queries);
	SQL_FreeHandle(connection); 
}

public MySQL_Load(id)
{
	new data[2];
	data[0] = id;

	static temp[96];
	format(temp, charsmax(temp), "SELECT * FROM ttt_stats WHERE player_name = ^"%s^"", g_szPlayerName[id]);
	SQL_ThreadQuery(g_pSqlTuple, "MySQL_LoadData", temp, data, 1);
}

public MySQL_Save(id)
{
	if(!g_szPlayerName[id][0])
		return;

	count_points(id);
	static temp[512];
	format(temp, charsmax(temp), "UPDATE ttt_stats SET gwk = '%d', kills_i = '%d', kills_d = '%d', kills_t = '%d', rdm = '%d', innocent = '%d', detective = '%d', traitor = '%d', bomb_planted = '%d', bomb_exploded = '%d', bomb_defused = '%d', total_points = '%d' WHERE player_name = ^"%s^"",
	g_iPlayerStats[id][STATS_GWK], g_iPlayerStats[id][STATS_KILLS_I], g_iPlayerStats[id][STATS_KILLS_D], g_iPlayerStats[id][STATS_KILLS_T], g_iPlayerStats[id][STATS_RDM], g_iPlayerStats[id][STATS_INN], g_iPlayerStats[id][STATS_DET], g_iPlayerStats[id][STATS_TRA], g_iPlayerStats[id][STATS_BOMBP], g_iPlayerStats[id][STATS_BOMBE], g_iPlayerStats[id][STATS_BOMBD], g_iPlayerStats[id][STATS_POINTS], g_szPlayerName[id]);

	SQL_ThreadQuery(g_pSqlTuple, "MySQL_FreeHandle", temp);
}

public MySQL_LoadData(failstate, Handle:query, error[], code, data[], datasize)
{
	if(failstate == TQUERY_CONNECT_FAILED)
		log_amx("[TTT] Load - Could not connect to SQL database.  [%d] %s", code, error);
	else if(failstate == TQUERY_QUERY_FAILED)
		log_amx("[TTT] Load query failed. [%d] %s", code, error);

	new id = data[0];
	if(!is_user_connected(id))
	{
		SQL_FreeHandle(query);
		return PLUGIN_HANDLED;
	}

	if(SQL_NumResults(query) > 0) 
	{
		for(new i = 0; i < PLAYER_STATS; i++)
			g_iPlayerStats[id][i] = SQL_ReadResult(query, i+2);
	}
	else table_insert(id);
	SQL_FreeHandle(query);

	return PLUGIN_HANDLED;
}

public MySQL_FreeHandle(failstate, Handle:query, error[], errcode, data[], datasize)
{
	SQL_FreeHandle(query);
	return PLUGIN_HANDLED;
}

public MySQL_TOP10()
{
	SQL_ThreadQuery(g_pSqlTuple, "MySQL_TOP10Load", "SELECT * FROM ttt_stats ORDER BY total_points DESC LIMIT 10");
}

public MySQL_TOP10Load(failstate, Handle:query, error[], errcode, data[], datasize)
{
	if(failstate == TQUERY_CONNECT_FAILED)
		log_amx("[TTT] Load - Could not connect to SQL database.  [%d] %s", errcode, error);
	else if(failstate == TQUERY_QUERY_FAILED)
		log_amx("[TTT] Load query failed. [%d] %s", errcode, error);

	new result = SQL_NumResults(query);
	if(result) 
	{
		for(new num[3], j, i = 0; i < result; i++)
		{
			static name[32];
			SQL_ReadResult(query, 1, name, charsmax(name));
			#if AMXX_VERSION_NUM >= 183
			TrieSetString(g_tTop10Players[i], "1", name, true);
			#else
			TrieSetString(g_tTop10Players[i], "1", name);
			#endif
			
			for(j = 2; j < 14; j++)
			{
				num_to_str(j, num, charsmax(num));
				#if AMXX_VERSION_NUM >= 183
				TrieSetCell(g_tTop10Players[i], num, SQL_ReadResult(query, j), true);
				#else
				TrieSetCell(g_tTop10Players[i], num, SQL_ReadResult(query, j));
				#endif
			}
			SQL_NextRow(query);
		}
	}
	SQL_FreeHandle(query);

	return PLUGIN_HANDLED;
}

public show_top10(id)
{
	const SIZE = 1536;
	static msg[SIZE+1], motdname[64], cached;
	if(!cached)
	{
		new len;
		len += formatex(msg[len], SIZE - len, "<html><head><style>table,td,th { border:1px solid black; border-collapse:collapse; }</style></head><body bgcolor='#ebf3f8'><table style='width:748px'>");
		len += formatex(msg[len], SIZE - len, "<th>Nr.</th><th>Name</th><th>Points</th><th>GWK</th><th>Kills as I</th><th>Kills as D</th><th>Kills as T</th><th>Team kills</th>");
		
		static name[32], value;
		for(new i = 0; i < 10; i++)
		{
			len += formatex(msg[len], SIZE - len, "<tr>");
			len += formatex(msg[len], SIZE - len, "<td>%d.</td>", i+1);

			TrieGetString(g_tTop10Players[i], "1", name, charsmax(name));
			len += formatex(msg[len], SIZE - len, "<td>%s</td>", name);

			TrieGetCell(g_tTop10Players[i], "13", value);
			len += formatex(msg[len], SIZE - len, "<td>%d</td>", value);

			TrieGetCell(g_tTop10Players[i], "2", value);
			len += formatex(msg[len], SIZE - len, "<td>%d</td>", value);
			TrieGetCell(g_tTop10Players[i], "3", value);
			len += formatex(msg[len], SIZE - len, "<td>%d</td>", value);
			TrieGetCell(g_tTop10Players[i], "4", value);
			len += formatex(msg[len], SIZE - len, "<td>%d</td>", value);
			TrieGetCell(g_tTop10Players[i], "5", value);
			len += formatex(msg[len], SIZE - len, "<td>%d</td>", value);
			TrieGetCell(g_tTop10Players[i], "6", value);
			len += formatex(msg[len], SIZE - len, "<td>%d</td>", value);

			len += formatex(msg[len], SIZE - len, "</tr>");
		}
		len += formatex(msg[len], SIZE - len, "</table></body></html>");
		formatex(motdname, charsmax(motdname), "Stats");
		cached = true;
	}
	show_motd(id, msg, motdname);
}

public show_stats(id)
{
	if(is_user_alive(id) && ttt_get_gamemode() == GAME_STARTED)
	{
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ALIVE");
		return;
	}

	count_points(id);
	const SIZE = 1536;
	static msg[SIZE+1], motdname[64];

	new len;
	len += formatex(msg[len], SIZE - len, "<html><head><style>table,td,th { border:1px solid black; border-collapse:collapse; }</style></head><body bgcolor='#ebf3f8'><table style='width:748px'>");
	len += formatex(msg[len], SIZE - len, "<th>Name</th><th>Points</th><th>GWK</th><th>Kills as I</th><th>Kills as D</th><th>Kills as T</th><th>Team kills</th>");

	len += formatex(msg[len], SIZE - len, "<tr><td>%s</td>", g_szPlayerName[id]);
	len += formatex(msg[len], SIZE - len, "<td>%d</td>", g_iPlayerStats[id][STATS_POINTS]);

	len += formatex(msg[len], SIZE - len, "<td>%d</td>", g_iPlayerStats[id][STATS_GWK]);
	len += formatex(msg[len], SIZE - len, "<td>%d</td>", g_iPlayerStats[id][STATS_KILLS_I]);
	len += formatex(msg[len], SIZE - len, "<td>%d</td>", g_iPlayerStats[id][STATS_KILLS_D]);
	len += formatex(msg[len], SIZE - len, "<td>%d</td>", g_iPlayerStats[id][STATS_KILLS_T]);
	len += formatex(msg[len], SIZE - len, "<td>%d</td>", g_iPlayerStats[id][STATS_RDM]);
	len += formatex(msg[len], SIZE - len, "</tr></table></body></html>");
	formatex(motdname, charsmax(motdname), "Stats");

	show_motd(id, msg, motdname);
}

stock reset_client(id)
{
	for(new i = 0; i < PLAYER_STATS; i++)
		g_iPlayerStats[id][i] = 0;
}

stock count_points(id)
{
	new points;
	for(new i = 0; i < PLAYER_STATS-1; i++)
		points += (g_iPlayerStats[id][i] * g_iPointValue[i]);

	g_iPlayerStats[id][STATS_POINTS] = points;
}

stock table_insert(id)
{
	static temp[512];
	format(temp, charsmax(temp), "INSERT INTO ttt_stats (player_name, gwk, kills_i, kills_d, kills_t, rdm, innocent, detective, traitor, bomb_planted, bomb_exploded, bomb_defused, total_points) VALUES (^"%s^", '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d');",
	g_szPlayerName[id], g_iPlayerStats[id][STATS_GWK], g_iPlayerStats[id][STATS_KILLS_I], g_iPlayerStats[id][STATS_KILLS_D], g_iPlayerStats[id][STATS_KILLS_T], g_iPlayerStats[id][STATS_RDM], g_iPlayerStats[id][STATS_INN], g_iPlayerStats[id][STATS_DET], g_iPlayerStats[id][STATS_TRA], g_iPlayerStats[id][STATS_BOMBP], g_iPlayerStats[id][STATS_BOMBE], g_iPlayerStats[id][STATS_BOMBD], g_iPlayerStats[id][STATS_POINTS]);
	SQL_ThreadQuery(g_pSqlTuple, "MySQL_FreeHandle", temp);
}

// API
public _set_stats(plugin, params)
{
	if(params != 3)
		return ttt_log_api_error("ttt_set_stats needs 3 params(p1: %d, p2: %d, p3: %d)", plugin, params, get_param(1), get_param(2), get_param(3));

	g_iPlayerStats[get_param(1)][get_param(2)] = get_param(3);
	return 1;
}

public _get_stats(plugin, params)
{
	if(params != 2)
		return ttt_log_api_error("ttt_get_stats needs 2 params(p1: %d, p2: %d)", plugin, params, get_param(1), get_param(2));

	return g_iPlayerStats[get_param(1)][get_param(2)];
}

// DIFFERENT STATS:
public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_STARTED)
	{
		new num, id;
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];
			switch(ttt_get_playerstate(id))
			{
				case PC_INNOCENT: g_iPlayerStats[id][STATS_INN] = g_iPlayerStats[id][STATS_INN] + 1;
				case PC_TRAITOR: g_iPlayerStats[id][STATS_TRA] = g_iPlayerStats[id][STATS_TRA] + 1;
				case PC_DETECTIVE: g_iPlayerStats[id][STATS_DET] = g_iPlayerStats[id][STATS_DET] + 1;
			}
		}
	}
}

public ttt_bomb_status(id, status, ent)
{
	switch(status)
	{
		case BS_DEFUSED: g_iPlayerStats[id][STATS_BOMBD] = g_iPlayerStats[id][STATS_BOMBD] + 1;
		case BS_PLANTED: g_iPlayerStats[id][STATS_BOMBP] = g_iPlayerStats[id][STATS_BOMBP] + 1;
		case BS_BOMBED: g_iPlayerStats[id][STATS_BOMBE] = g_iPlayerStats[id][STATS_BOMBE] + 1;
	}
}

public Ham_Killed_post(victim, killer, shouldgib)
{
	if(!is_user_connected(killer))
		killer = ttt_find_valid_killer(victim, killer);

	if(is_user_connected(killer) && victim != killer)
	{
		new killer_state = ttt_get_alivestate(killer), victim_state = ttt_get_alivestate(victim);

		switch(killer_state)
		{
			case PC_TRAITOR:
			{
				switch(victim_state)
				{
					case PC_TRAITOR: g_iPlayerStats[killer][STATS_RDM] = g_iPlayerStats[killer][STATS_RDM] + 1;
					case PC_INNOCENT, PC_DETECTIVE: g_iPlayerStats[killer][STATS_KILLS_T] = g_iPlayerStats[killer][STATS_KILLS_T] + 1;
				}
			}
			case PC_INNOCENT:
			{
				switch(victim_state)
				{
					case PC_TRAITOR: g_iPlayerStats[killer][STATS_KILLS_I] = g_iPlayerStats[killer][STATS_KILLS_I] + 1;
					case PC_INNOCENT, PC_DETECTIVE: g_iPlayerStats[killer][STATS_RDM] = g_iPlayerStats[killer][STATS_RDM] + 1;
				}
			}
			case PC_DETECTIVE:
			{
				switch(victim_state)
				{
					case PC_TRAITOR: g_iPlayerStats[killer][STATS_KILLS_D] = g_iPlayerStats[killer][STATS_KILLS_D] + 1;
					case PC_INNOCENT, PC_DETECTIVE: g_iPlayerStats[killer][STATS_RDM] = g_iPlayerStats[killer][STATS_RDM] + 1;
				}
			}
		}
	}
}
