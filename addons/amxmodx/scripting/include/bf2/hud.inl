//Bf2 Rank Mod HUD File
//Contains all the HUD functions.


#if defined bf2_hud_included
  #endinput
#endif
#define bf2_hud_included

//Show an announcement display

public Announcement(id)
{
	if (!get_pcvar_num(g_bf2_active))
		return;	
	
	client_print(id, print_chat, "[BF2]This server is running Battlefield 2 Rank mod. Say /bf2menu for more Info")
}

//Prepares Information for the hud to be shown

public ShowHUD(id) 
{ 
	if (!get_pcvar_num(g_bf2_active) || !is_user_alive(id))
		return;	

	new rank=g_PlayerRank[id];

	switch (rank)
	{
		case 16,19,20: rank=15;
		case 17: rank=7;
		case 18: rank=8;
	}

	nextrank[id]=floatround(float(RANKXP[(rank+1)])*get_pcvar_float(g_xp_multiplier))

	DisplayHUD(id)
		
	return;
}

//Displays the HUD to the user

public DisplayHUD(id)
{
	if (!is_user_alive(id) || is_user_bot(id))
		return;

	new HUD[64]
	
	if (!get_pcvar_num(g_badges_active))
	{
		format(HUD, 63, "[BF2]Points: %d/%d Rank: %s ",totalkills[id],nextrank[id],RANKS[g_PlayerRank[id]])
		message_begin(MSG_ONE_UNRELIABLE, gmsgStatusText, {0,0,0}, id) 
		write_byte(0) 
		write_string(HUD)
		message_end()
	}
	else
	{	
		format(HUD, 63, "[BF2]Points: %d/%d Badges: %d Rank: %s ",totalkills[id],nextrank[id],numofbadges[id],RANKS[g_PlayerRank[id]])
		message_begin(MSG_ONE_UNRELIABLE, gmsgStatusText, {0,0,0}, id) 
		write_byte(0) 
		write_string(HUD)
		message_end()
	}


}