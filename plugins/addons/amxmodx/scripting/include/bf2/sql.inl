//Bf2 Rank Mod SQL File
//Contains subroutines for all SQL features.


#if defined bf2_sql_included
  #endinput
#endif
#define bf2_sql_included

//Load details for sql..

public sql_init()
{
	new Host[64],User[64],Pass[64],Db[64]     
	
	//Get the host name, pw etc..
	get_cvar_string("amx_sql_host",Host,63)     
	get_cvar_string("amx_sql_user",User,63)     
	get_cvar_string("amx_sql_pass",Pass,63)     
	get_cvar_string("amx_sql_db",Db,63)         

	g_SqlTuple = SQL_MakeDbTuple(Host,User,Pass,Db)
	g_SqlTuple2 = SQL_MakeDbTuple(Host,User,Pass,Db)      

	//Try and find existing table and if not create one
	copy(g_Cache,511,"CREATE TABLE IF NOT EXISTS bf2ranks (playerid VARCHAR(35),badge1 TINYINT(4),badge2 TINYINT(4),badge3 TINYINT(4),badge4 TINYINT(4),badge5 TINYINT(4),badge6 TINYINT(4), knife SMALLINT(6),pistol SMALLINT(6),sniper SMALLINT(6),support SMALLINT(6),kills INT(11),defuses INT(11),plants INT(11),explosions INT(11),PRIMARY KEY (playerid))")     
	SQL_ThreadQuery(g_SqlTuple,"TableHandle",g_Cache)

	copy(g_Cache,511,"CREATE TABLE IF NOT EXISTS bf2ranks2 (playerid VARCHAR(35),badge7 TINYINT(4),badge8 TINYINT(4), shotgun SMALLINT(6),smg SMALLINT(6),rifle SMALLINT(6),grenade SMALLINT(6),gold INT(11),silver INT(11),bronze INT(11),highestrank VARCHAR(35),mostkills VARCHAR(35),mostwins VARCHAR(35), PRIMARY KEY (playerid))")     
	SQL_ThreadQuery(g_SqlTuple2,"TableHandle",g_Cache)

}

//Load all data from the sql table for given use

public sql_load(id)     
{
	//New player joined. Load their row from the table

	format(g_Cache,511,"SELECT badge1,badge2,badge3,badge4,badge5,badge6,knife,pistol,sniper,support,kills,defuses,plants,explosions FROM bf2ranks WHERE playerid='%s'",authid[id])
	new index[3];
	format(index,2,"%d",id)
	SQL_ThreadQuery(g_SqlTuple,"SelectHandle",g_Cache,index,3)

	format(g_Cache,511,"SELECT badge7,badge8,shotgun,smg,rifle,grenade,gold,silver,bronze FROM bf2ranks2 WHERE playerid='%s'",authid[id])
	format(index,2,"%d",id)
	SQL_ThreadQuery(g_SqlTuple2,"SelectHandle2",g_Cache,index,3)
}

public sql_server_load()     
{
	//Load server Data

	//Gold,silver and bronze store the highestrank,mostkills and mostwins values repectively. The other 3 are the names
	format(g_Cache,511,"SELECT gold,silver,bronze,highestrank,mostkills,mostwins FROM bf2ranks2 WHERE playerid='Server'")
	SQL_ThreadQuery(g_SqlTuple2,"SelectHandleServer",g_Cache)
}

//Save given users data to the sql table

public sql_save(id)
{
	//Player has left. Update their row in the table

	if (statsloaded[id]>=2) //only save if they correctly loaded both table data
	{
		format(g_Cache,511,"UPDATE bf2ranks SET badge1=%i,badge2=%i,badge3=%i,badge4=%i,badge5=%i,badge6=%i, knife=%i, pistol=%i, sniper=%i, support=%i, kills=%i, defuses=%i, plants=%i, explosions=%i WHERE playerid=^"%s^"" ,g_PlayerBadges[id][0],g_PlayerBadges[id][1],g_PlayerBadges[id][2],g_PlayerBadges[id][3],g_PlayerBadges[id][4],g_PlayerBadges[id][5],knifekills[id],pistolkills[id],sniperkills[id],parakills[id],totalkills[id],defuses[id],plants[id],explosions[id],authid[id])
		SQL_ThreadQuery(g_SqlTuple,"QueryHandle",g_Cache)

		format(g_Cache,511,"UPDATE bf2ranks2 SET badge7=%i,badge8=%i, shotgun=%i, smg=%i, rifle=%i, grenade=%i, gold=%i, silver=%i, bronze=%i WHERE playerid=^"%s^"" ,g_PlayerBadges[id][6],g_PlayerBadges[id][7],shotgunkills[id],smgkills[id],riflekills[id],grenadekills[id],gold[id],silver[id],bronze[id],authid[id])
		SQL_ThreadQuery(g_SqlTuple2,"QueryHandle",g_Cache)
	}
}

public sql_server_save()
{
	//Save server Data
	replace_all(highestrankservername, 29, "'", "\'" );
	replace_all(mostkillsname, 29, "'", "\'" );
	replace_all(mostwinsname, 29, "'", "\'" );
	format(g_Cache,511,"UPDATE bf2ranks2 SET gold=%i,silver=%i,bronze=%i,highestrank='%s',mostkills='%s',mostwins='%s' WHERE playerid=^"Server^"" ,highestrankserver,mostkills,mostwins,highestrankservername,mostkillsname,mostwinsname)
	SQL_ThreadQuery(g_SqlTuple2,"QueryHandle",g_Cache)
}

//Return Function for the open/create table query

public TableHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{ 
   	//Check for errors on loading the table (connection probs etc)

	if(FailState)     
	{         
		if(FailState == TQUERY_CONNECT_FAILED)                      
			log_amx("Table - Could not connect to SQL database.  [%d] %s", Errcode, Error);         
		else if(FailState == TQUERY_QUERY_FAILED)                      
			log_amx("Table Query failed. [%d] %s", Errcode, Error);

		SQLenabled=false;
		                 
		return 0;     
	}          
	SQLenabled=true;
	
	if (!mostwins)
		server_load();

        return PLUGIN_CONTINUE 
} 

//Return Function for the save data query

public QueryHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{     
	//Check for errors when making a write to table query

	if(FailState)     
	{         
		if(FailState == TQUERY_CONNECT_FAILED)                      
			log_amx("Save - Could not connect to SQL database.  [%d] %s", Errcode, Error);         
		else if(FailState == TQUERY_QUERY_FAILED)                      
			log_amx("Save Query failed. [%d] %s", Errcode, Error);                 
		return 0;     
	}       

	return PLUGIN_CONTINUE 
} 


//Return Function for the select query

public SelectHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{     
	//Check for errors and then process loading from table queries
	new id=str_to_num(Data)
	
	if(FailState)     
	{         
		if(FailState == TQUERY_CONNECT_FAILED)                      
			log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);         
		else if(FailState == TQUERY_QUERY_FAILED)                      
			log_amx("Load Query failed. [%d] %s", Errcode, Error);                 
		return 0;     
	}

	statsloaded[id]++
	
	if (!SQL_MoreResults(Query)) // No more results - User not found, create them a blank entry in the table. and zero their variables
	{
		for (new counter=0; counter<6; counter++)
		{	
			g_PlayerBadges[id][counter] = 0 ;             
		}
		knifekills[id]=0
		pistolkills[id]=0
		sniperkills[id]=0
		parakills[id]=0
		totalkills[id]=0
		defuses[id]=0
		plants[id]=0
		explosions[id]=0

		format(g_Cache,511,"INSERT INTO bf2ranks VALUES('%s','0','0','0','0','0','0','0','0','0','0','0','0','0','0')",authid[id]);
		SQL_ThreadQuery(g_SqlTuple,"QueryHandle",g_Cache)
		return PLUGIN_CONTINUE;
	}

	//Player must have been found. Loop through and load the columns into the global vars
	for (new counter=0; counter<6; counter++)
	{	
		g_PlayerBadges[id][counter] = SQL_ReadResult(Query,counter)              
	}

	knifekills[id]=SQL_ReadResult(Query,6)
	pistolkills[id]=SQL_ReadResult(Query,7)
	sniperkills[id]=SQL_ReadResult(Query,8)
	parakills[id]=SQL_ReadResult(Query,9)
	totalkills[id]=SQL_ReadResult(Query,10)
	defuses[id]=SQL_ReadResult(Query,11)
	plants[id]=SQL_ReadResult(Query,12)
	explosions[id]=SQL_ReadResult(Query,13)


	
	return PLUGIN_CONTINUE 
}

public SelectHandle2(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{     
	//Check for errors and then process loading from table queries
	new id=str_to_num(Data)
	
	if(FailState)     
	{         
		if(FailState == TQUERY_CONNECT_FAILED)                      
			log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);         
		else if(FailState == TQUERY_QUERY_FAILED)                      
			log_amx("Load Query failed. [%d] %s", Errcode, Error);                 
		return 0;     
	}

	statsloaded[id]++
	
	if (!SQL_MoreResults(Query)) // No more results - User not found, create them a blank entry in the table. and zero their variables
	{
		for (new counter=6; counter<8; counter++)
		{	
			g_PlayerBadges[id][counter] = 0 ;             
		}
		shotgunkills[id]=0
		smgkills[id]=0
		riflekills[id]=0
		grenadekills[id]=0
		gold[id]=0
		silver[id]=0
		bronze[id]=0

		format(g_Cache,511,"INSERT INTO bf2ranks2 VALUES('%s','0','0','0','0','0','0','0','0','0','0','0','0')",authid[id]);
		SQL_ThreadQuery(g_SqlTuple2,"QueryHandle",g_Cache)
		return PLUGIN_CONTINUE;
	}

	//Player must have been found. Loop through and load the columns into the global vars

	g_PlayerBadges[id][6] = SQL_ReadResult(Query,0)  
	g_PlayerBadges[id][7] = SQL_ReadResult(Query,1)  
	shotgunkills[id]=SQL_ReadResult(Query,2)
	smgkills[id]=SQL_ReadResult(Query,3)
	riflekills[id]=SQL_ReadResult(Query,4)
	grenadekills[id]=SQL_ReadResult(Query,5)
	gold[id]=SQL_ReadResult(Query,6)
	silver[id]=SQL_ReadResult(Query,7)
	bronze[id]=SQL_ReadResult(Query,8)
	
	return PLUGIN_CONTINUE 
}

public SelectHandleServer(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{     
	//Check for errors and then process loading from table queries
	
	if(FailState)     
	{         
		if(FailState == TQUERY_CONNECT_FAILED)                      
			log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);         
		else if(FailState == TQUERY_QUERY_FAILED)                      
			log_amx("Load Query failed. [%d] %s", Errcode, Error);                 
		return 0;     
	}
	
	if (!SQL_MoreResults(Query)) // No more results - User not found, create them a blank entry in the table. and zero their variables
	{

		highestrankserver = 0
		mostkills = 0
		mostkillsid = 0
		mostwins = 0

		format(g_Cache,511,"INSERT INTO bf2ranks2 VALUES('Server','0','0','0','0','0','0','0','0','0','0','0','0')");
		SQL_ThreadQuery(g_SqlTuple,"QueryHandle",g_Cache)
		return PLUGIN_CONTINUE;
	}

	highestrankserver = SQL_ReadResult(Query,0)
	mostkills = SQL_ReadResult(Query,1)
	mostwins = SQL_ReadResult(Query,2)
	SQL_ReadResult(Query,3,highestrankservername,29)
	SQL_ReadResult(Query,4,mostkillsname,29)
	SQL_ReadResult(Query,5,mostwinsname,29)
	

	
	return PLUGIN_CONTINUE 
}