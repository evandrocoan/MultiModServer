//Bf2 Rank Mod CSDM File
//Only used if CSDM is going to be run on the server. CSDM only functions..


#if defined bf2_csdm_included
  #endinput
#endif
#define bf2_csdm_included

public csdm_PostSpawn(player, bool:fake)
{
	if (!get_pcvar_num(g_badges_active) || !is_user_alive(player))
		return;

	set_task(0.5, "give_userweapon", player);

}

//Called after a player is physically respawned, 
// and after all spawn handling is completed.
forward csdm_PostSpawn(player, bool:fake);