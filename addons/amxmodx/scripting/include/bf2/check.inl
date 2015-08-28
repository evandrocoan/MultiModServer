//Bf2 Rank Mod check File
//Contains all the badge/rank etc checking functions.


#if defined bf2_check_included
  #endinput
#endif
#define bf2_check_included

public check_level(id) 
{
	
	new stats[8],bodyhits[8],prevrank;
	new ranked=get_user_stats(id, stats, bodyhits)
	
	prevrank=g_PlayerRank[id];
	new newrank;

	BadgeCount(id);
	
	for (new counter=0; counter<MAX_RANKS; counter++)
	{	
		if (totalkills[id]>=floatround(float(RANKXP[counter])*get_pcvar_float(g_xp_multiplier)))
		{
			newrank=counter;	
		
		}
		else
		{
			counter=MAX_RANKS;
		}

	}

	g_PlayerRank[id]=newrank;

	switch (g_PlayerRank[id])
	{
	case 7: 
		if (numofbadges[id]>5)
			g_PlayerRank[id]=17;
	case 8:
		if (numofbadges[id]>11)
			g_PlayerRank[id]=18;
	case 15:
		if (numofbadges[id]==18)
			g_PlayerRank[id]=19;
	case 16: 
		if (ranked==1)
			g_PlayerRank[id]=20; //Promote to General if Number 1 ranked.
		else if (numofbadges[id]!=18)
			g_PlayerRank[id]=15; //If they don't have all badges demote back to brigadier Gen
	}


		

	if (newplayer[id])
	{
		client_print(id,print_chat,"[BF2]Your rank of %s has been loaded",RANKS[g_PlayerRank[id]]);
		client_cmd(id, "spk %s", g_Sound1);
		newplayer[id]=false;

	}
	else if (is_ranked_higher(g_PlayerRank[id],prevrank))
	{
		client_print(id,print_chat,"[BF2]You have been promoted to the rank of %s",RANKS[g_PlayerRank[id]])
		client_cmd(id, "spk %s", g_Sound1);
		ranking_officer_check(id);
		
	}	
	else if (g_PlayerRank[id]!=prevrank && !is_ranked_higher(g_PlayerRank[id],prevrank))
	{
		client_print(id,print_chat,"[BF2]You have been demoted to the rank of %s",RANKS[g_PlayerRank[id]])
	}

	if (is_ranked_higher(g_PlayerRank[id],highestrankserver))
	{
		highestrankserver=g_PlayerRank[id]
		new line[100],name[30]
		get_user_name(id,name,29)
		line[0] = 0x04;
		format(line[1],98,"%s is now the top ranked in the server at rank %s",name,RANKS[highestrankserver])
		format(highestrankservername,29,name)
		ShowColorMessage(highestrank,MSG_BROADCAST,line)
	}
}

public BadgeCount(id)
{
	numofbadges[id]=0;
	
	for (new counter=0; counter<MAX_BADGES; counter++)
	{
		numofbadges[id]=numofbadges[id]+g_PlayerBadges[id][counter]
	}

}

public badge_check_loop()
{
	
	new players[32],num;	

	get_players(players,num,"cg")

	for (new counter=0; counter<num; counter++)
	{
		check_badges(players[counter]);
	}

}

public check_badges(id)
{

	if ((!get_pcvar_num(g_bf2_active)) || (!get_pcvar_num(g_badges_active)))
		return;


	
	new bool:badgegained=false;
	
	new weaponkillsround;
	new weaponhsround;
	new wroundstats[8],wroundbodyhits[8],wstats[8],wbodyhits[8];
	new currentbadge=0;
	new kills;

	new roundkills[8];

	wroundstats[0]=0;
	wroundstats[2]=0;
	get_user_rstats(id,roundkills,wroundbodyhits);
		
	//only check for new badges if the user got a kill. Will save lots of wasted processing time.
	//Exception is explosives badge. May have been earned without kill. Ah well they can wait till they next get a kill
	if (roundkills[0]) 
	{
		client_print(id,print_chat,"[BF2]Checking for earned badges now...")	


		//knife badge section
		currentbadge=g_PlayerBadges[id][BADGE_KNIFE];
		wroundstats[0]=0;
		wroundstats[2]=0;
		get_user_wrstats(id,CSW_KNIFE,wroundstats,wroundbodyhits);

		kills=knifekills[id];

		switch (currentbadge)
		{
		case LEVEL_NONE:	

			if (wroundstats[0]>1)
			{
				g_PlayerBadges[id][BADGE_KNIFE]=LEVEL_BASIC; //Basic Knife Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_KNIFE][LEVEL_BASIC])
				badgegained=true;
			}
		case LEVEL_BASIC:
			if (kills>49)
			{
				g_PlayerBadges[id][BADGE_KNIFE]=LEVEL_VETERAN; //Veteran Knife Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_KNIFE][LEVEL_VETERAN])
				badgegained=true;
			}
		case LEVEL_VETERAN:
			if ((wroundstats[0]>2) && (wroundstats[2]>0) && (kills>99))
			{
				g_PlayerBadges[id][BADGE_KNIFE]=LEVEL_EXPERT; //Expert Knife Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_KNIFE][LEVEL_EXPERT])
				badgegained=true;
			}
	
		}
		//End knife section

		//Pistol badge section
		currentbadge=g_PlayerBadges[id][BADGE_PISTOL];
		
		if (currentbadge!=LEVEL_BASIC) //don't bother getting round stats if badge = 1 because no round based checks needed for level 2
		{

			weaponkillsround=0;
			weaponhsround=0;		

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_DEAGLE,wroundstats,wroundbodyhits);
			weaponkillsround=wroundstats[0];
			weaponhsround=wroundstats[2];

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_ELITE,wroundstats,wroundbodyhits);
			weaponkillsround+=wroundstats[0];
			weaponhsround+=wroundstats[2];

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_P228,wroundstats,wroundbodyhits);
			weaponkillsround+=wroundstats[0];
			weaponhsround+=wroundstats[2];

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_FIVESEVEN,wroundstats,wroundbodyhits);
			weaponkillsround+=wroundstats[0];
			weaponhsround+=wroundstats[2];
		
			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_USP,wroundstats,wroundbodyhits);
			weaponkillsround+=wroundstats[0];
			weaponhsround+=wroundstats[2];
		
			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_GLOCK18,wroundstats,wroundbodyhits);
			weaponkillsround+=wroundstats[0];
			weaponhsround+=wroundstats[2];
		}

		kills=pistolkills[id];

		switch (currentbadge)
		{
		case LEVEL_NONE:	

			if (weaponkillsround>2)
			{
				g_PlayerBadges[id][BADGE_PISTOL]=LEVEL_BASIC; //Basic Pistol Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_PISTOL][LEVEL_BASIC])
				badgegained=true;
			}
		case LEVEL_BASIC:
			if (kills>99)
			{
				g_PlayerBadges[id][BADGE_PISTOL]=LEVEL_VETERAN; //Veteran Pistol Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_PISTOL][LEVEL_VETERAN])
				badgegained=true;
			}
		case LEVEL_VETERAN:
			if ((weaponkillsround>3) && (weaponhsround>1) && (kills>199))
			{
				g_PlayerBadges[id][BADGE_PISTOL]=LEVEL_EXPERT; //Expert Pistol Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_PISTOL][LEVEL_EXPERT])
				badgegained=true;
			}
	
		}	
		//End Pistol section


		//Assault badge section
		currentbadge=g_PlayerBadges[id][BADGE_ASSAULT];
		wstats[0]=0;	
		wstats[4]=0;
		wstats[5]=0;
		wroundstats[0]=0;
		
		get_user_stats(id,wstats,wbodyhits);
	
		new acc = floatround((float(wstats[5])/float(wstats[4]))*100);
		accuracy[id]=acc;

		switch (currentbadge)
		{
		case LEVEL_NONE:	
			if (roundkills[0]>3)
			{
				g_PlayerBadges[id][BADGE_ASSAULT]=LEVEL_BASIC; //Basic Assault Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_ASSAULT][LEVEL_BASIC])
				badgegained=true;
			}
		case LEVEL_BASIC:
			if (acc>24)
			{
				g_PlayerBadges[id][BADGE_ASSAULT]=LEVEL_VETERAN; //Veteran Assault Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_ASSAULT][LEVEL_VETERAN])
				badgegained=true;
			}
		case LEVEL_VETERAN:
			if ((roundkills[0]>4) && (roundkills[2]>2) && (totalkills[id]>1999))
			{
				g_PlayerBadges[id][BADGE_ASSAULT]=LEVEL_EXPERT; //Expert Assault Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_ASSAULT][LEVEL_EXPERT])
				badgegained=true;
			}
	
		}
		//End Assault section
		

		//Sniper badge section
		currentbadge=g_PlayerBadges[id][BADGE_SNIPER];


		if (currentbadge!=LEVEL_BASIC) //don't bother getting round stats if badge = 1 because no round based checks needed for level 2
		{
			weaponkillsround=0;
			weaponhsround=0;

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_AWP,wroundstats,wroundbodyhits);
			weaponkillsround=wroundstats[0];
			weaponhsround=wroundstats[2];

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_SCOUT,wroundstats,wroundbodyhits);
			weaponkillsround+=wroundstats[0];
			weaponhsround+=wroundstats[2];

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_G3SG1,wroundstats,wroundbodyhits);
			weaponkillsround+=wroundstats[0];
			weaponhsround+=wroundstats[2];

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_SG550,wroundstats,wroundbodyhits);
			weaponkillsround+=wroundstats[0];
			weaponhsround+=wroundstats[2];
		}
		
		kills=sniperkills[id];
	
		switch (currentbadge)
		{
		case LEVEL_NONE:	

			if (weaponkillsround>2)
			{
				g_PlayerBadges[id][BADGE_SNIPER]=LEVEL_BASIC; //Basic Sniper Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_SNIPER][LEVEL_BASIC])
				badgegained=true;
			}
		case LEVEL_BASIC:
			if (kills>99)
			{
				g_PlayerBadges[id][BADGE_SNIPER]=LEVEL_VETERAN; //Veteran Sniper Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_SNIPER][LEVEL_VETERAN])
				badgegained=true;
			}
		case LEVEL_VETERAN:
			if ((weaponkillsround>3) && (weaponhsround>0) && (kills>199))
			{
				g_PlayerBadges[id][BADGE_SNIPER]=LEVEL_EXPERT; //Expert Sniper Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_SNIPER][LEVEL_EXPERT])
				badgegained=true;
			}
	
		}
		//End Sniper section

		//Support badge section
		currentbadge=g_PlayerBadges[id][BADGE_SUPPORT];
		wroundstats[0]=0;
		wroundstats[2]=0;		
		get_user_wrstats(id,CSW_M249,wroundstats,wroundbodyhits);

		kills=parakills[id];

		switch (currentbadge)
		{
		case LEVEL_NONE:	

			if (wroundstats[0]>1)
			{
				g_PlayerBadges[id][BADGE_SUPPORT]=LEVEL_BASIC; //Basic Support Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_SUPPORT][LEVEL_BASIC])
				badgegained=true;
			}
		case LEVEL_BASIC:
			if (kills>99)
			{
				g_PlayerBadges[id][BADGE_SUPPORT]=LEVEL_VETERAN; //Veteran Support Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_SUPPORT][LEVEL_VETERAN])
				badgegained=true;
			}
		case LEVEL_VETERAN:
			if ((wroundstats[0]>3) && (wroundstats[2]>0) && (kills>199))
			{
				g_PlayerBadges[id][BADGE_SUPPORT]=LEVEL_EXPERT; //Expert Support Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_SUPPORT][LEVEL_EXPERT])
				badgegained=true;
			}
	
		}
		//End support section

		//Explosives badge section
		currentbadge=g_PlayerBadges[id][BADGE_EXPLOSIVES];

		switch (currentbadge)
		{
		case LEVEL_NONE:
			if (grenadekills[id]>29)
			{
				g_PlayerBadges[id][BADGE_EXPLOSIVES]=LEVEL_BASIC; //Basic Explosives Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_EXPLOSIVES][LEVEL_BASIC])
				badgegained=true;
			}
		case LEVEL_BASIC:
			if (grenadekills[id]>99)
			{
				g_PlayerBadges[id][BADGE_EXPLOSIVES]=LEVEL_VETERAN; //Veteran Explosives Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_EXPLOSIVES][LEVEL_VETERAN])
				badgegained=true;
			}
		case LEVEL_VETERAN:
			if (grenadekills[id]>199)
			{
				g_PlayerBadges[id][BADGE_EXPLOSIVES]=LEVEL_EXPERT; //Expert Explosives Badge
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_EXPLOSIVES][LEVEL_EXPERT])
				badgegained=true;
			}
	
		}
		//End Explosives section

		//Shotgun badge section
		currentbadge=g_PlayerBadges[id][BADGE_SHOTGUN];


		if (currentbadge!=LEVEL_BASIC) //don't bother getting round stats if badge = 1 because no round based checks needed for level 2
		{
			weaponkillsround=0;
			weaponhsround=0;

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_XM1014,wroundstats,wroundbodyhits);
			weaponkillsround=wroundstats[0];
			weaponhsround=wroundstats[2];

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_M3,wroundstats,wroundbodyhits);
			weaponkillsround+=wroundstats[0];
			weaponhsround+=wroundstats[2];
		}
		
		kills=shotgunkills[id];
	
		switch (currentbadge)
		{
		case LEVEL_NONE:	

			if (weaponkillsround>2)
			{
				g_PlayerBadges[id][BADGE_SHOTGUN]=LEVEL_BASIC;
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_SHOTGUN][LEVEL_BASIC])
				badgegained=true;
			}
		case LEVEL_BASIC:
			if (kills>99)
			{
				g_PlayerBadges[id][BADGE_SHOTGUN]=LEVEL_VETERAN;
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_SHOTGUN][LEVEL_VETERAN])
				badgegained=true;
			}
		case LEVEL_VETERAN:
			if ((weaponkillsround>3) && (weaponhsround>0) && (kills>199))
			{
				g_PlayerBadges[id][BADGE_SHOTGUN]=LEVEL_EXPERT;
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_SHOTGUN][LEVEL_EXPERT])
				badgegained=true;
			}
	
		}
		//End Shotgun section


		//SMG badge section
		currentbadge=g_PlayerBadges[id][BADGE_SMG];


		if (currentbadge!=LEVEL_BASIC) //don't bother getting round stats if badge = 1 because no round based checks needed for level 2
		{
			weaponkillsround=0;
			weaponhsround=0;

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_MAC10,wroundstats,wroundbodyhits);
			weaponkillsround=wroundstats[0];
			weaponhsround=wroundstats[2];

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_UMP45,wroundstats,wroundbodyhits);
			weaponkillsround+=wroundstats[0];
			weaponhsround+=wroundstats[2];

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_MP5NAVY,wroundstats,wroundbodyhits);
			weaponkillsround+=wroundstats[0];
			weaponhsround+=wroundstats[2];

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_TMP,wroundstats,wroundbodyhits);
			weaponkillsround+=wroundstats[0];
			weaponhsround+=wroundstats[2];

			wroundstats[0]=0;
			wroundstats[2]=0;
			get_user_wrstats(id,CSW_P90,wroundstats,wroundbodyhits);
			weaponkillsround+=wroundstats[0];
			weaponhsround+=wroundstats[2];
		}
		
		kills=smgkills[id];
	
		switch (currentbadge)
		{
		case LEVEL_NONE:	

			if (weaponkillsround>2)
			{
				g_PlayerBadges[id][BADGE_SMG]=LEVEL_BASIC;
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_SMG][LEVEL_BASIC])
				badgegained=true;
			}
		case LEVEL_BASIC:
			if (kills>99)
			{
				g_PlayerBadges[id][BADGE_SMG]=LEVEL_VETERAN;
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_SMG][LEVEL_VETERAN])
				badgegained=true;
			}
		case LEVEL_VETERAN:
			if ((weaponkillsround>3) && (weaponhsround>0) && (kills>199))
			{
				g_PlayerBadges[id][BADGE_SMG]=LEVEL_EXPERT;
				client_print(id,print_chat,"[BF2]You have been awarded %s Badge",BADGES[BADGE_SMG][LEVEL_EXPERT])
				badgegained=true;
			}
	
		}
		//End SMG section

		if (badgegained)
		{
			client_cmd(id, "spk %s", g_Sound2);
			save_badges(id)
		}
	}
	
}

public bool:is_ranked_higher(rank1,rank2)
{
	if (RANKORDER[rank1]>RANKORDER[rank2])
		return true
	
	return false
}

public ranking_officer_check(id)
{
	if (!is_ranked_higher(g_PlayerRank[id],highestrank))
		return PLUGIN_CONTINUE

	highestrank = g_PlayerRank[id]
	highestrankid = id
	new name[30]
	get_user_name(id,name,29)
	new line[100]
	line[0] = 0x04;
	format(line[1],99,"%s is now the ranking officer at rank %s",name,RANKS[highestrank])
	ShowColorMessage(highestrank,MSG_BROADCAST,line)


	return PLUGIN_CONTINUE	
}

public ranking_officer_disconnect()
{
	new players[32],num,player
	get_players(players,num,"h")

	highestrank=0
	highestrankid=0

	for (new i=0; i<num; i++)
	{
		player=players[i]
		if (is_ranked_higher(g_PlayerRank[player],highestrank))
		{
			highestrank = g_PlayerRank[player]
			highestrankid = player
		}
	}
	
	if (!highestrank)
		return;

	new name[30]
	get_user_name(highestrankid,name,29)
	new line[100]
	line[0] = 0x04;
	format(line[1],99,"%s is now the ranking officer at rank %s",name,RANKS[highestrank])
	ShowColorMessage(highestrank,MSG_BROADCAST,line)
}

public award_check()
{
	//Run on SVC_INTERMISSION (Map change)
	//Find the top three Fragging players and award them with a star

	new players[32],num
	get_players(players,num,"h")

	new tempfrags,id

	new swapfrags,swapid

	new starfrags[3] //0 - Bronze / 1 - Silver / 2 - Gold
	new starid[3]

	for (new i=0; i<num; i++)
	{
		id=players[i]
		tempfrags=get_user_frags(id)
		if (tempfrags>starfrags[0])
		{
			starfrags[0]=tempfrags
			starid[0]=id
			if (tempfrags>starfrags[1])
			{
				swapfrags=starfrags[1]
				swapid=starid[1]
				starfrags[1]=tempfrags
				starid[1]=id
				starfrags[0]=swapfrags
				starid[0]=swapid

				if (tempfrags>starfrags[2])
				{
					swapfrags=starfrags[2]
					swapid=starid[2]
					starfrags[2]=tempfrags
					starid[2]=id
					starfrags[1]=swapfrags
					starid[1]=swapid
				}
			}	
		}
		
		save_badges(id)
	}
		
	new winner=starid[2]
	new bool:newleader=false;

	if (!winner)
		return;

	//We now should have our three awards

	bronze[starid[0]]++
	silver[starid[1]]++
	gold[winner]++

	save_badges(starid[0])
	save_badges(starid[1])
	save_badges(winner)

	new name[30];
	get_user_name(starid[2],name,29)

	if (gold[winner]>mostwins)
	{
		mostwins=gold[winner]
		newleader=true
		format(mostwinsname,29,name)
	}

	server_save()

	new line[100]
	line[0] = 0x04;
	format(line[1],98,"Congratulations to the award Winners!")
	ShowColorMessage(starid[2],MSG_BROADCAST,line)

	line[0] = 0x04;

	get_user_name(starid[0],name,29)
	line[0] = 0x04;
	format(line[1],99,"%s - Bronze Medal - %i Kills",name,starfrags[0])
	ShowColorMessage(starid[2],MSG_BROADCAST,line)

	get_user_name(starid[1],name,29)
	line[0] = 0x04;
	format(line[1],99,"%s - Silver Medal - %i Kills",name,starfrags[1])
	ShowColorMessage(starid[2],MSG_BROADCAST,line)

	get_user_name(starid[2],name,29)

	if (newleader)
		format(line[1],98,"%s - Gold Medal - %i Kills - Win Leader",name,starfrags[2])
	else
		format(line[1],98,"%s - Gold Medal - %i Kills",name,starfrags[2])
	
	ShowColorMessage(starid[2],MSG_BROADCAST,line)
}

ShowColorMessage(id, type, message[])
{
	message_begin(type, gmsgSayText, _, id);
	write_byte(id)		
	write_string(message);
	message_end();	
}