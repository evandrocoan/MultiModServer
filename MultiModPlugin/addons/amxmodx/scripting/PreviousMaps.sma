/* This plugin saves each played map in an SQL database (tried with MySQL). Upon requests from players through
   /previousmap and /previousmap_list commands, the plugin will show them which maps were played
   prior to the current map being played. In order to avoid unnecessary lag due to overloaded data
   in the database, this plugin will delete records (previos maps records) that are older than
   10 days from the database
   
   Player commands:-
   /previousmap: Displays the previous map played (before the current one)
   /previousmap_list Displays the last 10 maps played including time of change.
   
   */

#include <amxmodx>
#include <amxmisc>
#include <sqlx>

#define PLUGIN "Previous Maps"
#define VERSION "1.0"
#define AUTHOR "DPT"

new SErrorCode[512]

new fpreviousmap[25]

new Handle:SQLConnection
new Handle:SQLTuple
new motd[1024]


public plugin_init()
 {
	new Host[64],User[64],Pass[64],Db[64]
	new ErrorCode


	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	get_cvar_string("amx_sql_host",Host,63)
	get_cvar_string("amx_sql_user",User,63)
	get_cvar_string("amx_sql_pass",Pass,63)
	get_cvar_string("amx_sql_db",Db,63)
	
	SQLTuple = SQL_MakeDbTuple(Host,User,Pass,Db)
	
	SQLConnection = SQL_Connect(SQLTuple,ErrorCode,SErrorCode,511)
	
	if(SQLConnection == Empty_Handle) set_fail_state(SErrorCode)
	
	register_clcmd("say /previousmap", "Show_PreviousMap");
	
	register_clcmd("say /previousmap_list", "Show_PreviousMapList");
	
	new Handle:query1 = SQL_PrepareQuery(SQLConnection,"CREATE TABLE IF NOT EXISTS previous_maps (id int(11) NOT NULL AUTO_INCREMENT, map_name varchar(25) DEFAULT NULL, time_date datetime DEFAULT NULL, PRIMARY KEY (id))")

	SQL_Execute(query1);
				
	Load_PreviousMaps()
	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

string:Load_PreviousMaps()
{
	new Handle:query1 = SQL_PrepareQuery(SQLConnection, "SELECT map_name, DATE_FORMAT(time_date, '%%l:%%i %%p %%d %%M') AS time_date FROM previous_maps ORDER BY id DESC LIMIT 0,10");
	
	SQL_Execute(query1);
		
	new map_name[26]
	new time_date[30]
	new len,a = 0;
	
	len = format(motd, 1023,"<body bgcolor=#000000><font color=#FFB000><pre>")
	len += format(motd[len], 1023-len,"%s %-22.22s %3s^n", "#", "Map Name", "Time")
	
	while(SQL_MoreResults(query1))
	{
        
	SQL_ReadResult(query1, 0, map_name, 25)
	
	if (a == 0)
	{
	SQL_ReadResult(query1, 0, fpreviousmap, 25)	
	}
	
	SQL_ReadResult(query1, 1, time_date, 29)
	
	len += format(motd[len], 1023-len,"%d %-22.22s %s^n", a+1, map_name, time_date)
         
	a++;
	SQL_NextRow(query1)
	}

    	len += format(motd[len], 1023-len,"</body></font></pre>")
	
	SQL_FreeHandle(query1)
	
	
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public Show_PreviousMapList(id)
{
	show_motd(id, motd, "The Last 10 Maps Played")
	
	return PLUGIN_CONTINUE
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public Show_PreviousMap(id)
{
	client_print(id,print_chat,"[Previous Maps] The previous map was: %s", fpreviousmap)
	
	return PLUGIN_CONTINUE
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public plugin_end()
{
	new mapname[26]
	new deleted_rows
	
	get_mapname(mapname, 25);
	
	new Handle:query1 = SQL_PrepareQuery(SQLConnection, "INSERT INTO previous_maps VALUES(NULL, '%s', NOW())", mapname);

	SQL_Execute(query1);

	new Handle:query2 = SQL_PrepareQuery(SQLConnection, "DELETE FROM previous_maps WHERE DATE(time_date) < CURDATE() - INTERVAL 10 DAY");
	
	SQL_Execute(query2);
	
	deleted_rows = SQL_AffectedRows(query2)
	
	if (deleted_rows > 0) log_amx("%d previous map records have been deleted from the database (older than 10 days)", deleted_rows);
	
	SQL_FreeHandle(SQLConnection);
	
	SQL_FreeHandle(query2);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
