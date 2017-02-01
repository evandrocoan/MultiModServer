//Bf2 Rank Mod forwards File
//Contains all the standard forwarded functions


#if defined bf2_forward_included
  #endinput
#endif
#define bf2_forward_included

public plugin_cfg()
{
	get_configsdir(configsdir, 199)

	//SQL
	#if defined SQL

	SQLenabled=false;

	set_task(1.0,"sql_init")

	#else
	set_task(1.0,"vault_init")

	#endif

	set_cvar_string("bf2_version",VERSION);

	set_task(10.0,"ranking_officer_disconnect")
}

public client_putinserver(id)
{
	get_user_authid(id,authid[id],31);
	
	if (equal(authid[id],pRED))
	{
		new line[100]
		line[0] = 0x04;
		format(line[1],98,"pRED* | NZ - Bf2 Rank Creator has joined the server")
		ShowColorMessage(id,MSG_BROADCAST,line)
	}

	load_badges(id);
	imobile[id]=false;
	newplayer[id]=true;
	statsloaded[id]=0

	check_level(id)

	set_task(5.0,"ranking_officer_check",id)

	set_task(20.0, "Announcement", id)
}

public client_disconnect(id)
{
	save_badges(id);
	
	if (id==highestrankid)
		set_task(2.0,"ranking_officer_disconnect")
}

public plugin_end() 
{
	server_save()

	//Free the handle thingy..
	#if defined SQL
	if (SQLenabled)	
		SQL_FreeHandle(g_SqlTuple)
	#else
		
		new prunedelay=(DAY*get_pcvar_num(g_prune_days))
		nvault_prune(g_Vault,0,get_systime(prunedelay));
	
		nvault_close(g_Vault)
	#endif
}

public plugin_precache()
{

	precache_sound(g_Sound1);
	precache_sound(g_Sound2);
	
	new bool:bError=false;
		
	for (new counter; counter<MAX_RANKS+4; counter++)
	{
		
		format(spritefile[counter],35,"sprites/bf2rankspr/%d.spr",counter)


		if ( !file_exists( spritefile[counter] ) )
		{
			log_amx( "[ERROR] Missing sprite file '%s'", spritefile[counter] );

			bError = true;
		}
	}
	
	if (!bError)
	{
		for (new counter; counter<MAX_RANKS+4; counter++)
		{
			sprite[counter] = precache_model(spritefile[counter]);
			
		}

	}
	else
	{
		set_fail_state( "Sprite files are missing, unable to load plugin" );
	}

	
}

