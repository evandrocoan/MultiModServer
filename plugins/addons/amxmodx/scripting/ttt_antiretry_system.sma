#include <amxmodx>
#include <sqlx>
#include <ttt>

#pragma defclasslib sqlite sqlite
new Handle:g_pSqlTuple;
new g_szUserIP[33][20];
new cvar_antiretry, g_iDataBaseType;

public plugin_init()
{
	register_plugin("[TTT] AntiRetry system", TTT_VERSION, TTT_AUTHOR);

	cvar_antiretry 	= my_register_cvar("ttt_antiretry", "2", "AntiRetry 0/1/2 off/MySQL/Sqlite. (Default: 2)");
}

public plugin_cfg()
	set_task(0.1, "delayed_plugin_cfg");

public delayed_plugin_cfg()
{
	MySQL_Init();
}

public plugin_end()
{
	table_clear();
	if(g_pSqlTuple)
		SQL_FreeHandle(g_pSqlTuple);
}

public client_putinserver(id)
{
	g_szUserIP[id][0] = EOS;
	if(is_user_bot(id))
		return;

	get_user_ip(id, g_szUserIP[id], charsmax(g_szUserIP[]), 1);
	MySQL_Load(id);
}

public client_disconnect(id)
{
	MySQL_Save(id);
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_RESTARTING)
	{
		table_clear();
		new num;
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
			table_insert(players[num]);
	}
}

public MySQL_Init()
{
	g_iDataBaseType = get_pcvar_num(cvar_antiretry);
	if(g_iDataBaseType == 1)
	{
		new host[64], user[33], pass[32], db[32];
		get_cvar_string("amx_sql_host", host, charsmax(host));
		get_cvar_string("amx_sql_user", user, charsmax(user));
		get_cvar_string("amx_sql_pass", pass, charsmax(pass));
		get_cvar_string("amx_sql_db", db, charsmax(db));
		g_pSqlTuple = SQL_MakeDbTuple(host, user, pass, db);
	}
	else if(g_iDataBaseType == 2)
	{
		SQL_SetAffinity("sqlite");
		g_pSqlTuple = SQL_MakeDbTuple("localhost", "root", "", "ttt_antiretry");

	}
	else set_fail_state("[TTT] CVAR set wrongly, plugin turning off!");

	new error[128];
	new code, Handle:connection = SQL_Connect(g_pSqlTuple, code, error, charsmax(error));
	if(connection == Empty_Handle)
		set_fail_state(error);

	new Handle:queries;
	if(g_iDataBaseType == 1)
	{
		queries = SQL_PrepareQuery(connection, 
			"CREATE TABLE IF NOT EXISTS ttt_antiretry(\
				id int unsigned NOT NULL AUTO_INCREMENT, \
				ip varchar(20) UNIQUE NOT NULL default '', \
				karma int(8), \
				warnings_s int(3), \
				warnings_i int(3), \
				punish int(3), \
				PRIMARY KEY (id)\
			);"
		);
	}
	else if(g_iDataBaseType == 2)
	{
		queries = SQL_PrepareQuery(connection, 
			"CREATE TABLE IF NOT EXISTS ttt_antiretry(\
				id INTEGER PRIMARY KEY, \
				ip CHAR(20) UNIQUE NOT NULL DEFAULT '', \
				karma INTEGER, \
				warnings_s INTEGER, \
				warnings_i INTEGER, \
				punish INTEGER\
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
	table_clear();
}

public MySQL_Load(id)
{
	new data[2];
	data[0] = id;

	static temp[96];
	formatex(temp, charsmax(temp), "SELECT * FROM ttt_antiretry WHERE ip = ^"%s^";", g_szUserIP[id]);
	SQL_ThreadQuery(g_pSqlTuple, "MySQL_LoadData", temp, data, 1);
}

public MySQL_Save(id)
{
	if(!g_szUserIP[id][0])
		return;

	static warnings[TTT_WARNINGS];
	ttt_get_warnings(id, warnings);
	static temp[192];
	if(warnings[WARN_BANNED])
		formatex(temp, charsmax(temp), "UPDATE ttt_antiretry SET karma = '500', warnings_s = '0', warnings_i = '0', punish = '0' WHERE ip = ^"%s^";", g_szUserIP[id]);
	else formatex(temp, charsmax(temp), "UPDATE ttt_antiretry SET karma = '%d', warnings_s = '%d', warnings_i = '%d', punish = '%d' WHERE ip = ^"%s^";", ttt_get_playerdata(id, PD_KARMATEMP), warnings[WARN_SPECIAL], warnings[WARN_INNOCENT], warnings[WARN_PUNISH], g_szUserIP[id]);

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
		static warnings[TTT_WARNINGS];
		new karma = SQL_ReadResult(query, 2);
		new warnings_s = SQL_ReadResult(query, 3);
		new warnings_i = SQL_ReadResult(query, 4);
		new punish = SQL_ReadResult(query, 5);

		if(karma > 0)
		{
			ttt_set_playerdata(id, PD_KARMATEMP, karma);
			ttt_set_playerdata(id, PD_KARMA, karma);
		}

		if(warnings_s > 0)
			warnings[WARN_SPECIAL] = warnings_s;
		if(warnings_i > 0)
			warnings[WARN_INNOCENT] = warnings_i;
		if(punish > 0)
			warnings[WARN_PUNISH] = true;

		ttt_set_warnings(id, warnings);
		SQL_FreeHandle(query);
	}
	else
	{
		SQL_FreeHandle(query);
		table_insert(id);
	}

	return PLUGIN_HANDLED;
}

public MySQL_FreeHandle(failstate, Handle:query, error[], errcode, data[], datasize)
{
	SQL_FreeHandle(query);
	return PLUGIN_HANDLED;
}

stock table_clear()
{
	if(g_pSqlTuple)
	{
		if(g_iDataBaseType == 1)
			SQL_ThreadQuery(g_pSqlTuple, "MySQL_FreeHandle", "TRUNCATE TABLE ttt_antiretry;");
		else if(g_iDataBaseType == 2)
			SQL_ThreadQuery(g_pSqlTuple, "MySQL_FreeHandle", "DELETE FROM ttt_antiretry;");
	}
}

stock table_insert(id)
{
	static warnings[TTT_WARNINGS];
	ttt_get_warnings(id, warnings);
	static temp[192];
	formatex(temp, charsmax(temp), "INSERT INTO ttt_antiretry (ip, karma, warnings_s, warnings_i, punish) VALUES (^"%s^", '%d', '%d', '%d', '%d');", g_szUserIP[id], ttt_get_playerdata(id, PD_KARMATEMP), warnings[WARN_SPECIAL], warnings[WARN_INNOCENT], warnings[WARN_PUNISH]);
	SQL_ThreadQuery(g_pSqlTuple, "MySQL_FreeHandle", temp);
}