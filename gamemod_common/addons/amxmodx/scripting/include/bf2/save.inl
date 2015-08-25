//Bf2 Rank Mod save File
//Contains all the saving/loading functions


#if defined bf2_save_included
  #endinput
#endif
#define bf2_save_included


#if !defined SQL
public vault_load(id)
{	
	new vaultkey[64], vaultdata[256]; 
	new TimeStamp;

	formatex(vaultkey,63,"BF2-%s",authid[id]);

	g_PlayerRank[id]=0
	g_PlayerBadges[id][0]=0
	g_PlayerBadges[id][1]=0
	g_PlayerBadges[id][2]=0
	g_PlayerBadges[id][3]=0
	g_PlayerBadges[id][4]=0
	g_PlayerBadges[id][5]=0
	g_PlayerBadges[id][6]=0
	g_PlayerBadges[id][7]=0
	knifekills[id]=0
	pistolkills[id]=0
	sniperkills[id]=0
	parakills[id]=0
	totalkills[id]=0
	defuses[id]=0
	plants[id]=0
	explosions[id]=0
	accuracy[id]=0
	
	smgkills[id]=0
	shotgunkills[id]=0
	riflekills[id]=0;
	grenadekills[id]=0;

	bronze[id]=0;
	silver[id]=0;
	gold[id]=0;


    	if(nvault_lookup(g_Vault, vaultkey, vaultdata, sizeof(vaultdata) - 1, TimeStamp ))
    	{
		
		new str_badge[6][5],str_knife[8],str_pistol[8],str_sniper[8],str_para[8],str_total[8],str_defuses[8],str_plants[8],str_explosions[8]
        	
		replace_all(vaultdata,253,"#"," ")

		parse(vaultdata,str_badge[0],4,str_badge[1],4,str_badge[2],4,str_badge[3],4,str_badge[4],4,str_badge[5],4,str_knife,7,str_pistol,7,str_sniper,7,str_para,7,str_total,7,str_defuses,7,str_plants,7,str_explosions,7)      
        	
		g_PlayerBadges[id][0] = str_to_num(str_badge[0])
        	g_PlayerBadges[id][1] = str_to_num(str_badge[1])
        	g_PlayerBadges[id][2] = str_to_num(str_badge[2])      
        	g_PlayerBadges[id][3] = str_to_num(str_badge[3])
        	g_PlayerBadges[id][4] = str_to_num(str_badge[4])
        	g_PlayerBadges[id][5] = str_to_num(str_badge[5])
		knifekills[id] = str_to_num(str_knife)
		pistolkills[id] = str_to_num(str_pistol)
		sniperkills[id] = str_to_num(str_sniper)
		parakills[id] = str_to_num(str_para)
		totalkills[id] = str_to_num(str_total)
		defuses[id] = str_to_num(str_defuses)
		plants[id] = str_to_num(str_plants)
		explosions[id] = str_to_num(str_explosions)

    	}

	formatex(vaultkey,63,"BF2-2-%s",authid[id]);

	if(nvault_lookup(g_Vault, vaultkey, vaultdata, sizeof(vaultdata) - 1, TimeStamp ))
    	{
		new str_badge2[2][5];
	
		new str_shotgun[8],str_smg[8],str_rifle[8],str_grenade[8],str_gold[8],str_silver[8],str_bronze[8]
        	
		replace_all(vaultdata,253,"#"," ")

		parse(vaultdata,str_badge2[0],4,str_badge2[1],4,str_shotgun,7,str_smg,7,str_rifle,7,str_grenade,7,str_gold,7,str_silver,7,str_bronze,7)

		g_PlayerBadges[id][6] = str_to_num(str_badge2[0])
        	g_PlayerBadges[id][7] = str_to_num(str_badge2[1])
		shotgunkills[id] = str_to_num(str_shotgun)
		smgkills[id] = str_to_num(str_smg)
		riflekills[id] = str_to_num(str_rifle)
		grenadekills[id] = str_to_num(str_grenade)
		gold[id] = str_to_num(str_gold)
		silver[id] = str_to_num(str_silver)
		bronze[id] = str_to_num(str_bronze)
    	}

	for (new i=0; i<MAX_BADGES; i++)
	{
		if (g_PlayerBadges[id][i]>3)
			g_PlayerBadges[id][i]=3

		if (g_PlayerBadges[id][i]<0)
			g_PlayerBadges[id][i]=0	

	}
}
#endif


public load_badges(id) 
{
	#if defined SQL
	if(SQLenabled)
	{
		sql_load(id)
	}
	#else
		vault_load(id)
	#endif

	new numofbadges;

	for (new counter=0; counter<MAX_BADGES; counter++)
	{
		numofbadges=numofbadges+g_PlayerBadges[id][counter]
	}
	
	client_print(id,print_chat,"[BF2] %d Badges have been loaded",numofbadges);
}

public server_load()
{
	#if defined SQL
	if(SQLenabled)
	{
		sql_server_load()
	}
	#else
		vault_server_load()
	#endif



}

public server_save()
{
	#if defined SQL
	if(SQLenabled)
	{
		sql_server_save()
	}
	#else
		vault_server_save()
	#endif
}
#if !defined SQL
public vault_server_save() 
{
    	new vaultkey[64],vaultdata[256]

    	formatex(vaultkey,63,"BF2-ServerData")
    	formatex(vaultdata,255,"%i#^"%s^"#%i#^"%s^"#%i#^"%s^"",highestrankserver,highestrankservername,mostkills,mostkillsname,mostwins,mostwinsname)

	nvault_set(g_Vault,vaultkey,vaultdata)

    	return PLUGIN_CONTINUE;	
}

public vault_server_load()
{	
	new vaultkey[64], vaultdata[256]; 
	new TimeStamp;

	formatex(vaultkey,63,"BF2-ServerData");

    	if(nvault_lookup(g_Vault, vaultkey, vaultdata, sizeof(vaultdata) - 1, TimeStamp ))
    	{	
		new str_rank[8],str_kills[8],str_wins[8]
        	
		replace_all(vaultdata,253,"#"," ")

		parse(vaultdata,str_rank,7,highestrankservername,29,str_kills,7,mostkillsname,29,str_wins,7,mostwinsname,29)      
		        	
		highestrankserver = str_to_num(str_rank)
		mostkills = str_to_num(str_kills)
		mostwins = str_to_num(str_wins)
    	}
}
#endif

public save_badges(id) 
{
	#if defined SQL
	if(SQLenabled)
	{
		sql_save(id)
		return PLUGIN_CONTINUE;
	}
	#else
 
    	if(equal(authid[id],"") || equal(authid[id],"STEAM_ID_PENDING")) 
        	return PLUGIN_HANDLED
    
    	new vaultkey[64],vaultdata[256]

    	formatex(vaultkey,63,"BF2-%s",authid[id])
    	formatex(vaultdata,255,"%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i",g_PlayerBadges[id][0],g_PlayerBadges[id][1],g_PlayerBadges[id][2],g_PlayerBadges[id][3],g_PlayerBadges[id][4],g_PlayerBadges[id][5],knifekills[id],pistolkills[id],sniperkills[id],parakills[id],totalkills[id],defuses[id],plants[id],explosions[id])

	nvault_set(g_Vault,vaultkey,vaultdata)

  	formatex(vaultkey,63,"BF2-2-%s",authid[id])
    	formatex(vaultdata,255,"%i#%i#%i#%i#%i#%i#%i#%i#%i",g_PlayerBadges[id][6],g_PlayerBadges[id][7],shotgunkills[id],smgkills[id],riflekills[id],grenadekills[id],gold[id],silver[id],bronze[id])
    
	nvault_set(g_Vault,vaultkey,vaultdata)

	#endif
   
    	return PLUGIN_CONTINUE;	
}

public reset_stats(id)
{
	g_PlayerRank[id]=0
	g_PlayerBadges[id][0]=0
	g_PlayerBadges[id][1]=0
	g_PlayerBadges[id][2]=0
	g_PlayerBadges[id][3]=0
	g_PlayerBadges[id][4]=0
	g_PlayerBadges[id][5]=0
	g_PlayerBadges[id][6]=0
	g_PlayerBadges[id][7]=0
	knifekills[id]=0
	pistolkills[id]=0
	sniperkills[id]=0
	parakills[id]=0
	totalkills[id]=0
	defuses[id]=0
	plants[id]=0
	explosions[id]=0
	accuracy[id]=0

	smgkills[id]=0
	shotgunkills[id]=0
	riflekills[id]=0;
	grenadekills[id]=0;

	bronze[id]=0;
	silver[id]=0;
	gold[id]=0;

	save_badges(id)
}

public reset_all_stats(id)
{
	if (!(get_user_flags(id) & ADMIN_RESET))
	{
		client_print(id,print_chat,"You do not have access to this command")
		console_print(id,"You do not have access to this command")

		return PLUGIN_CONTINUE
	}

	new players[32],num
	get_players(players,num,"h")
	
	for (new i=0; i<num; i++)
	{
		reset_stats(players[i])
	}

	#if defined SQL
	if (SQLenabled)
	{	
		format(g_Cache,511,"TRUNCATE TABLE bf2ranks")
		SQL_ThreadQuery(g_SqlTuple,"QueryHandle",g_Cache)
	}
	#else
	nvault_prune(g_Vault, 0, get_systime())
	#endif

	new adminauthid[35]
	get_user_authid (id,adminauthid,34)

	log_amx("[BF2-ADMIN]Full Stats Reset by Admin %s",adminauthid)

	return PLUGIN_CONTINUE
}
#if !defined SQL
public vault_init()
{
	g_Vault=nvault_open("bf2data")
	server_load();
}
#endif