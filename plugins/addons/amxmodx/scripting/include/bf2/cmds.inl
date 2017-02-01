//Bf2 Rank Mod Commands File
//Contains all the client command functions


#if defined bf2_cmds_included
  #endinput
#endif
#define bf2_cmds_included

//Public menu / say commands. Help motds etc..

public show_rankhelp(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE	

	new tempstring[100];
	new motd[2048];
	new Float:xpmult=get_pcvar_float(g_xp_multiplier)

	new kills

	format(motd,2048,"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong>")
	format(tempstring,100,"Rank Kill Table</strong><br><br>")
	add(motd,2048,tempstring);

	for (new counter=0; counter<(MAX_RANKS-1); counter++)
	{
		kills=floatround(float(RANKXP[counter])*xpmult)
		format(tempstring,100,"%s - %d",RANKS[counter],kills)
		add(motd,2048,tempstring);
		add(motd,2048,"<br>");
	}

	format(tempstring,100,"<br><b>Special Ranks</b><br><br>")
	add(motd,2048,tempstring);
	
	format(tempstring,100,"%s - Requires %s and 6 Badges",RANKS[17],RANKS[7])
	add(motd,2048,tempstring);
	add(motd,2048,"<br>");
	
	format(tempstring,100,"%s - Requires %s and 12 Badges",RANKS[18],RANKS[8])
	add(motd,2048,tempstring);
	add(motd,2048,"<br>");

	format(tempstring,100,"%s - Requires %s and 18 Badges",RANKS[19],RANKS[15])
	add(motd,2048,tempstring);
	add(motd,2048,"<br>");

	format(tempstring,100,"%s - Requires %s",RANKS[16],RANKS[19])
	add(motd,2048,tempstring);
	add(motd,2048,"<br>");

	format(tempstring,100,"%s - Requires %s and Top Ranked overall",RANKS[20],RANKS[16])
	add(motd,2048,tempstring);
	add(motd,2048,"<br>");

	add(motd,2048,"</font></body></html>");

	show_motd(id,motd,"Player Info")

	Bf2menu(id)	

	return PLUGIN_CONTINUE
}

public show_server_stats(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE	

	new tempstring[100];
	new motd[2048];	
	new names[4][30];

	get_user_name(highestrankid,names[0],29)

	format(motd,2048,"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong>")
	format(tempstring,100,"Current Stats</strong><br><br>")
	add(motd,2048,tempstring);

	format(tempstring,100,"Highest Ranked - %s %s<br><br>",RANKS[highestrank],names[0])
	add(motd,2048,tempstring);

	format(tempstring,100,"<strong>Server Stats</strong><br><br>")
	add(motd,2048,tempstring);

	format(tempstring,100,"Highest Ranked - %s %s<br><br>",RANKS[highestrankserver],highestrankservername)
	add(motd,2048,tempstring);
	format(tempstring,100,"Most Kills - %s %i<br><br>",mostkillsname,mostkills)
	add(motd,2048,tempstring);
	format(tempstring,100,"Most Wins - %s %i<br><br>",mostwinsname,mostwins)
	add(motd,2048,tempstring);
	add(motd,2048,"</font></body></html>");

	show_motd(id,motd,"Server Stats")

	Bf2menu(id)	

	return PLUGIN_CONTINUE


}

public show_badgehelp(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE
	
	new url[100]
	get_pcvar_string(g_help_url,url,99)

	if (equal(url,""))
	{
		format(configfile,199,"%s/bf2/badges1.html",configsdir)	
		show_motd(id, configfile)
	}
	else
	{
		format(configfile,199,"%s/badges1web.html",url)	
		show_motd(id, configfile)
	}

	Bf2menu(id)

	return PLUGIN_CONTINUE	
}

public show_badgehelp2(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE
	
	new url[100]
	get_pcvar_string(g_help_url,url,99)

	if (equal(url,""))
	{
		format(configfile,199,"%s/bf2/badges2.html",configsdir)	
		show_motd(id, configfile)
	}
	else
	{
		format(configfile,199,"%s/badges2web.html",url)	
		show_motd(id, configfile)
	}
	
	Bf2menu(id)	

	return PLUGIN_CONTINUE
}

public show_badgehelp3(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE
	
	new url[100]
	get_pcvar_string(g_help_url,url,99)

	if (equal(url,""))
	{
		format(configfile,199,"%s/bf2/badges3.html",configsdir)	
		show_motd(id, configfile)
	}
	else
	{
		format(configfile,199,"%s/badges3web.html",url)	
		show_motd(id, configfile)
	}
	
	Bf2menu(id)	

	return PLUGIN_CONTINUE
}

public cmd_say(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE	

	new Arg1[31]
	read_args(Arg1, 30)
	remove_quotes(Arg1)
    
	if (!((equal(Arg1, "/whois",6)) || (equal(Arg1, "/whostats",6))))
		return PLUGIN_CONTINUE

	if (equal(Arg1, "/whostats",6))
	{
    
		new player = cmd_target(id, Arg1[10], 0)
        
		if (!player)
		{
			client_print(id,print_chat, "[BF2]Sorry, player %s could not be found or targetted!", Arg1[10])
			return PLUGIN_CONTINUE
		}


		display_stats(id,player)
		
		return PLUGIN_CONTINUE
	}

	new player = cmd_target(id, Arg1[7], 0)
        
	if (!player)
	{

		client_print(id,print_chat, "[BF2]Sorry, player %s could not be found or targetted!", Arg1[7])
		return PLUGIN_CONTINUE
	}
	
	display_badges(id,player)
	
	return PLUGIN_CONTINUE
}

public display_badges(id,badgeid)
{
	new name[30];
	get_user_name(badgeid,name,29);
	
	new tempstring[100];
	new motd[2048];

	format(motd,2048,"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong><b>")
	format(tempstring,100,"Rank and Badge Stats for Player %s </strong></b>", name)
	add(motd,2048,tempstring);
	add(motd,2048,"<br><br>");
	format(tempstring,100,"Players Rank: %s",RANKS[g_PlayerRank[badgeid]])
	add(motd,2048,tempstring);
	add(motd,2048,"<br>");

	if (!get_pcvar_num(g_badges_active))
	{
		add(motd,2048,"</font></body></html>");
		show_motd(id,motd,"Player Info")
		
		return PLUGIN_CONTINUE;	
	}

	add(motd,2048,"Current Badges Owned: <br>");

	for (new counter=0; counter<MAX_BADGES; counter++)
	{
		if(g_PlayerBadges[badgeid][counter]!=0)
		{
			format(tempstring,100,"&nbsp;-%s",BADGES[counter][g_PlayerBadges[badgeid][counter]])
			add(motd,2048,tempstring);
			format(tempstring,100,"&nbsp;-%s<br>",BADGEINFO[counter])
			add(motd,2048,tempstring);
		}
	}
	
	add(motd,2048,"</font></body></html>");

	show_motd(id,motd,"Player Info")

	Bf2menu(id)
    	
 	return PLUGIN_CONTINUE	
	
	
	
}

public cmd_who(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE	

	new tempstring[100],players[32],num,tempname[30];
	new motd[2048];

	format(motd,204,"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong><b>Player Listings</strong></b><br><br>")

	get_players(players,num);

	for (new counter=0; counter<num; counter++)
	{
		get_user_name(players[counter],tempname,29);
		format(tempstring,100,"Player %s - Rank: %s<br>",tempname,RANKS[g_PlayerRank[players[counter]]])
		add(motd,2048,tempstring);

	}
	add(motd,2048,"</font></body></html>")
	
	show_motd(id,motd,"Player List");

	Bf2menu(id)
	
	return PLUGIN_CONTINUE

}

public cmd_help(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE
	
	new url[100]
	get_pcvar_string(g_help_url,url,99)

	if (equal(url,""))
	{
		format(configfile,199,"%s/bf2/help.html",configsdir)	
		show_motd(id, configfile)
	}
	else
	{
		format(configfile,199,"%s/helpweb.html",url)	
		show_motd(id, configfile)
	}

	Bf2menu(id)	

	return PLUGIN_CONTINUE

}

public show_stats(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE	

	display_stats(id,id)

	Bf2menu(id)
	
	return PLUGIN_CONTINUE

}

public display_stats(id,statsid)
{
	new tempstring[100];
	new motd[2048];
	new stats[8],bodyhits[8];
	new ranked=get_user_stats(statsid, stats, bodyhits)
	new tempname[30]
	get_user_name(statsid,tempname,29)

	format(motd,2048,"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong><b>%s Current Weapon Stats - Updated at Round end</strong></b><br><br>",tempname)

	format(tempstring,100,"Global Kills - %d<br>",totalkills[statsid])
	add(motd,2048,tempstring);
	format(tempstring,100,"Global Knife Kills - %d<br>",knifekills[statsid])
	add(motd,2048,tempstring);
	format(tempstring,100,"Global Pistol Kills - %d<br>",pistolkills[statsid])
	add(motd,2048,tempstring);
	format(tempstring,100,"Global M249 Kills - %d<br>",parakills[statsid])
	add(motd,2048,tempstring);
	format(tempstring,100,"Global Sniper Kills - %d<br>",sniperkills[statsid])
	add(motd,2048,tempstring);
	format(tempstring,100,"Global Rifle Kills - %d<br>",riflekills[statsid])
	add(motd,2048,tempstring);
	format(tempstring,100,"Global Shotgun Kills - %d<br>",shotgunkills[statsid])
	add(motd,2048,tempstring);
	format(tempstring,100,"Global SMG Kills - %d<br>",smgkills[statsid])
	add(motd,2048,tempstring);
	format(tempstring,100,"Global Accuracy - %d percent<br>",accuracy[statsid])
	add(motd,2048,tempstring);
	format(tempstring,100,"Global Bomb Plants - %d<br>",plants[statsid])
	add(motd,2048,tempstring);
	format(tempstring,100,"Global Bomb Explosions - %d<br>",explosions[statsid])
	add(motd,2048,tempstring);
	format(tempstring,100,"Global Bomb Defuses - %d<br>",defuses[statsid])
	add(motd,2048,tempstring);
	format(tempstring,100,"Global Grenade Kills - %d<br>",grenadekills[statsid])
	add(motd,2048,tempstring);
	format(tempstring,100,"Current Player Ranked - %d<br>",ranked)
	add(motd,2048,tempstring);
	format(tempstring,100,"Medals Earned: Gold %d, Silver %d, Bronze %d<br>",gold[statsid],silver[statsid],bronze[statsid])
	add(motd,2048,tempstring);

	add(motd,2048,"</font></body></html>")
	
	show_motd(id,motd,"Current Weapon Stats");

}

//Admin only commands below here


//Gives badge to specified player
public add_badge(id,level,cid)
{
	if (!cmd_access(id, level, cid, 4))
        return PLUGIN_HANDLED
 
	new Arg1[24]
	new Arg2[4]
	new Arg3[4]

	
	read_argv(1, Arg1, 23)
	read_argv(2, Arg2, 3)
	read_argv(3, Arg3, 3)

	new badge = str_to_num(Arg2)
	new level = str_to_num(Arg3)

	new player = cmd_target(id, Arg1, 0)
          
	if (!player || (level>3) || (level<0) || (badge>7) || (badge<0))
        {
			console_print(id, "Sorry, player %s could not be found or targetted!, Or invalid badge/level", Arg1)
			return PLUGIN_HANDLED
	} else {
			g_PlayerBadges[player][badge]=level;
			client_print(id,print_chat,"[BF2]%s badge has been awarded to %s",BADGES[badge][level],Arg1)
			save_badges(player)
			DisplayHUD(player)
        }

	new adminauthid[35]
	new awardauthid[35]
	get_user_authid (id,adminauthid,34)
	get_user_authid (player,awardauthid,34)

	log_amx("[BF2-ADMIN]Admin %s awarded badge %s to player %s",adminauthid,BADGES[badge][level],awardauthid)
	
	return PLUGIN_HANDLED

}

//Gives kills to specified player
public add_kills(id,level,cid)
{
	if (!cmd_access(id, level, cid, 3))
        	return PLUGIN_HANDLED
 
     	new Arg1[24]
     	new Arg2[6]
    
     	read_argv(1, Arg1, 23)
     	read_argv(2, Arg2, 5)

     	new kills = str_to_num(Arg2)

	new player = cmd_target(id, Arg1, 0)
          
	if (!player)
        {
			console_print(id, "Sorry, player %s could not be found or targetted!", Arg1)
			return PLUGIN_HANDLED
        } else {
			totalkills[player]+=kills
			client_print(id,print_chat,"[BF2]%d kills have been awarded to %s",kills,Arg1)
			save_badges(player)
			DisplayHUD(player)
        }

	new adminauthid[35]
	new awardauthid[35]
	get_user_authid (id,adminauthid,34)
	get_user_authid (player,awardauthid,34)

	log_amx("[BF2-ADMIN]Admin %s awarded %i kills to player %s",adminauthid,kills,awardauthid)
	
	return PLUGIN_HANDLED

}