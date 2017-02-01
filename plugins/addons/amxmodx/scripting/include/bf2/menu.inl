//Bf2 Rank Mod menu File
//Contains all the menu checking functions.


#if defined bf2_menu_included
  #endinput
#endif
#define bf2_menu_included

public Bf2menu(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE
    
	new menu = menu_create("\rBFHQ: Choose Option:", "menu_handler")
 
	menu_additem(menu, "\wHelp Menu", "0", 0)
	menu_additem(menu, "\wStats Menu", "1", 0)
	menu_additem(menu, "\wAdmin Menu", "2", ADMIN_LEVEL)
	menu_additem(menu, "\wReset your Stats", "3", 0)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)

	menuselection[id]=MENU_MAIN

	menu_display(id, menu, 0)

	return PLUGIN_CONTINUE 
}

public helpmenu(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE
    
	new menu = menu_create("\rBFHQ: Help Menu:", "menu_handler")
 
	menu_additem(menu, "\wDisplay Help", "0", 0)
	menu_additem(menu, "\wDisplay Badge Help 1", "1", 0)
	menu_additem(menu, "\wDisplay Badge Help 2", "2", 0)
	menu_additem(menu, "\wDisplay Badge Help 3", "3", 0)
	menu_additem(menu, "\wDisplay Rank Table", "4", 0)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)

	menuselection[id]=MENU_HELP

	menu_display(id, menu, 0)

	return PLUGIN_CONTINUE
}

public playerlist(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE
    
	new menu = menu_create("\rBFHQ: Choose Player:", "menu_handler")
 
	new players[32],num
	get_players(players,num,"h")
	new name[30]
	new player
	new tempstring[32]
	new idarray[3]
	
	for (new i=0; i<num; i++)
	{
		player=players[i]
		get_user_name(player,name,29)
		formatex(tempstring,49,"\w%s",name)
		formatex(idarray,2,"%i",player)
		menu_additem(menu, tempstring, idarray, 0)
	}

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)

	menuselection[id]=MENU_PLAYER

	menu_display(id, menu, 0)

	return PLUGIN_CONTINUE
}

public statsmenu(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE
    
	new menu = menu_create("\rBFHQ: Stats Menu:", "menu_handler")
 
	menu_additem(menu, "\wShow Player List", "0", 0)
	menu_additem(menu, "\wDisplay your Badges", "1", 0)
	menu_additem(menu, "\wDisplay your Stats", "2", 0)
	menu_additem(menu, "\wDisplay Server Stats", "3", 0)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)

	menuselection[id]=MENU_STATS

	menu_display(id, menu, 0)

	return PLUGIN_CONTINUE  
}

public confirmmenu(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE
    
	new menu = menu_create("\rAre you sure?:", "menu_handler")
 
	menu_additem(menu, "\wYes, Reset all my Stats", "0", 0)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)

	menuselection[id]=MENU_CONFIRM

	menu_display(id, menu, 0)
	
	return PLUGIN_CONTINUE 
}

public confirmmenuadmin(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE
    
	new menu = menu_create("\rAre you sure?:", "menu_handler")
 
	menu_additem(menu, "\wYes, Reset all server Stats", "0", ADMIN_RESET)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)

	menuselection[id]=MENU_CONFIRMADMIN

	menu_display(id, menu, 0)

	return PLUGIN_CONTINUE
}

public adminmenu(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE
	
	new menu = menu_create("\rBFHQ: Admin Menu:", "menu_handler")
 
	menu_additem(menu, "\wAward a Badge to a Player", "0", ADMIN_LEVEL)
	menu_additem(menu, "\wAward Kills to a Player", "1", ADMIN_LEVEL)
	menu_additem(menu, "\wReset Server Stats", "2", ADMIN_RESET)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)

	menuselection[id]=MENU_ADMIN

	menu_display(id, menu, 0)

	return PLUGIN_CONTINUE 
}

public badgemenu(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE

  	new menu = menu_create("\rBFHQ: Select Badge:", "menu_handler")
 
	menu_additem(menu, "\wKnife Combat", "0", ADMIN_LEVEL)
	menu_additem(menu, "\wPistol Combat", "1", ADMIN_LEVEL)
	menu_additem(menu, "\wAssault Combat", "2", ADMIN_LEVEL)
	menu_additem(menu, "\wSniper Combat", "3", ADMIN_LEVEL)
	menu_additem(menu, "\wSupport Combat", "4", ADMIN_LEVEL)
	menu_additem(menu, "\wExplosives Ordinance", "5", ADMIN_LEVEL)
	menu_additem(menu, "\wShotgun Combat", "6", ADMIN_LEVEL)
	menu_additem(menu, "\wSMG Combat", "7", ADMIN_LEVEL)
  
	menu_setprop(menu, MPROP_PERPAGE, 0)
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
  
	menuselection[id]=MENU_BADGE

	menu_display(id, menu, 0)

	return PLUGIN_CONTINUE
}

public badgelevelmenu(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return PLUGIN_CONTINUE

   	new menu = menu_create("\rBFHQ: Select Level:", "menu_handler")
 
	menu_additem(menu, "\wNone", "0", ADMIN_LEVEL)
	menu_additem(menu, "\wBasic", "1", ADMIN_LEVEL)
	menu_additem(menu, "\wVeteran", "2", ADMIN_LEVEL)
	menu_additem(menu, "\wExpert", "3", ADMIN_LEVEL)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
  
	menuselection[id]=MENU_LEVEL

	menu_display(id, menu, 0)
	
	return PLUGIN_CONTINUE
}

public menu_handler(id,menu,item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	new data[6], iName[64]
	new access, callback

	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)


	if (!(get_user_flags(id) & access) && access)
		return PLUGIN_HANDLED


	new key=str_to_num(data)

	switch (menuselection[id])
	{
		case MENU_BADGE:
		{
  			menuselected[id][0]=0
			menuselected[id][1]=key
			badgelevelmenu(id)
		}
		case MENU_LEVEL:
		{
			menuselected[id][2]=key

			playerlist(id)
		}
		case MENU_ADMIN:
		{
			switch (key)
			{
				case 0:	badgemenu(id)
				case 1:
				{
					menuselected[id][0]=1
					playerlist(id)
				}
				case 2: confirmmenuadmin(id)
			}
		}
		case MENU_MAIN:
		{
			switch (key)
			{
				case 0: helpmenu(id)
				case 1:	statsmenu(id)
				case 2:	adminmenu(id)
				case 3: confirmmenu(id)
			}
		}
		case MENU_STATS:
		{
			switch (key)
			{
				case 0: cmd_who(id)
				case 1:	
				{
					display_badges(id,id)
				}
				case 2:	show_stats(id)
				case 3: show_server_stats(id)
			}
		}
		case MENU_HELP:
		{
			switch (key)
			{
				case 0: cmd_help(id)
				case 1:	show_badgehelp(id)
				case 2:	show_badgehelp2(id)
				case 3: show_badgehelp3(id)
				case 4:	show_rankhelp(id)
			}
		}
		case MENU_CONFIRM:
		{
			switch (key)
			{
				case 0: reset_stats(id)
			}
		}
		case MENU_CONFIRMADMIN:
		{
			switch (key)
			{
				case 0: reset_all_stats(id)
			}
		}
		case MENU_PLAYER:
		{
			if (menuselected[id][0]==0) //User selected a badge
			{
				new name[30]
				get_user_name(key,name,29)
				new badge=menuselected[id][1]
				new level=menuselected[id][2]
				g_PlayerBadges[key][badge]=level
				client_print(id,print_chat,"[BF2]%s badge has been awarded to %s",BADGES[badge][level],name)
				save_badges(key)
				DisplayHUD(key)
				
				new adminauthid[35]
				new awardauthid[35]
				get_user_authid (id,adminauthid,34)
				get_user_authid (key,awardauthid,34)

				log_amx("[BF2-ADMIN]Admin %s awarded badge %s to player %s",adminauthid,BADGES[badge][level],awardauthid)
			}
			else //Kills
			{
				new name[30]
				get_user_name(key,name,29)
				new kills=menuselected[id][1]
				totalkills[key]+=kills
				client_print(id,print_chat,"[BF2]%d kills have been awarded to %s",kills,name)
				save_badges(key)
				DisplayHUD(key)
				
				new adminauthid[35]
				new awardauthid[35]
				get_user_authid (id,adminauthid,34)
				get_user_authid (key,awardauthid,34)

				log_amx("[BF2-ADMIN]Admin %s awarded %i kills to player %s",adminauthid,kills,awardauthid)
			}
		}
	}

   	menu_destroy(menu)
    
	return PLUGIN_HANDLED
}