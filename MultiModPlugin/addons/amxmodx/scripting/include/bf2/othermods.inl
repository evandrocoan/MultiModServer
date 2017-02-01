//Bf2 Rank Mod Flag MOd File
//Contains all the functions for bf2 to register flag scoring from CS flag mod.


#if defined bf2_flag_included
  #endinput
#endif
#define bf2_flag_included

public csf_flag_taken(id)
{
	if ( get_playersnum() < get_pcvar_num(g_flag_min_players) ) return

	new tempkills = get_pcvar_num(g_flag_kills)

	if ( tempkills < 1 ) return

	totalkills[id] += tempkills

	DisplayHUD(id)
	client_print(id, print_chat, "[BF2] You received %d BF2 kills for capturing the flag", tempkills)
}

public csf_round_won(id)
{
	if ( get_playersnum() < get_pcvar_num(g_flag_min_players) ) return

	new tempkills = get_pcvar_num(g_flag_round_kills)

	if ( tempkills < 1 ) return

	totalkills[id] += tempkills
	DisplayHUD(id)

	client_print(id, print_chat, "[BF2] Your team received %d BF2 kills for winning the flag round", tempkills)
}

public csf_match_won(id)
{
	if ( get_playersnum() < get_pcvar_num(g_flag_min_players) ) return

	new tempkills = get_pcvar_num(g_flag_match_kills)

	if ( tempkills < 1 ) return

	totalkills[id] += tempkills
	DisplayHUD(id)

	client_print(id, print_chat, "[BF2] Your team received %d BF2 kills for winning the flag match", tempkills)
}