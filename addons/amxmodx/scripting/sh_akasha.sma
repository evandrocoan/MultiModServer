#include <amxmod> 
#include <superheromod>

// Akasha - Queen of the Damned
//			 by Mydas

/* CVARS
akasha_level     - guess
akasha_hpgain    - amount of health she regenerates per corpse
akasha_threshold - number of corpses akasha must eat to gain xp she would gain killing the last corpse. if set to 1, she will level very fast
*/

// based on "Terminator" (AssKicR) and "Alien Grunt" ([ LiToVietBoi ] & [SiN])

// VARIABLES
new gHeroName[]="Akasha"
new gHasAkashaPowers[SH_MAXSLOTS+1]

new pl_origins[SH_MAXSLOTS+1][3] 
new bool:corpse_used[SH_MAXSLOTS+1] = {false,...} 
new gMaxHealth[SH_MAXSLOTS+1]
new corpses[SH_MAXSLOTS+1]


public plugin_init()
{
	register_plugin("SUPERHERO Akasha","1.00","Mydas")
 
	if ( !cvar_exists("akasha_level") ) register_cvar("akasha_level", "6")
	shCreateHero(gHeroName, "Unholiness", "Suck life and experience out of corpses; then turn them into zombies", true, "akasha_level" )
	
	// INIT
	register_srvcmd("akasha_init", "akasha_init")
	shRegHeroInit(gHeroName, "akasha_init")

	// KEYDOWN 
	register_srvcmd("akasha_kd", "akasha_kd") 
	shRegKeyDown(gHeroName, "akasha_kd") 
	
	register_event("ResetHUD","newRound","b")
	register_event("DeathMsg","player_die","a") 

	register_srvcmd("akasha_maxhealth", "akasha_maxhealth")
	shRegMaxHealth(gHeroName, "akasha_maxhealth" )

	// DEFAULT THE CVARS
	register_cvar("akasha_hpgain", "30" )	
	register_cvar("akasha_threshold", "3")	

}

public akasha_init() 
{ 
	new temp[128] 
	read_argv(1,temp,5) 
	new id=str_to_num(temp) 
	read_argv(2,temp,5) 
	new hasPowers=str_to_num(temp) 
	gHasAkashaPowers[id]=(hasPowers != 0)
	gMaxHealth[id] = 100
	corpses[id] = 0
} 

public akasha_kd() 
{ 
	if ( !hasRoundStarted() ) return PLUGIN_HANDLED 
	new temp[6]
  
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( !is_user_alive(id) ) return PLUGIN_HANDLED 
	if ( !gHasAkashaPowers[id] ) return PLUGIN_HANDLED 

	new cur_origin[3],players[SH_MAXSLOTS],pl_num=0,dist,last_dist=99999,last_id, name[41]
	get_user_origin(id,cur_origin,0) 
	get_players(players,pl_num,"b") 
	if (pl_num>0) { 
		for (new i=0;i<pl_num;i++) { 
				dist = get_distance(cur_origin,pl_origins[players[i]]) 
				if ((dist<last_dist)&&(!corpse_used[players[i]])) { 
					last_id = players[i] 
					last_dist = dist 
			} 
		} 
		if (last_dist<100) {
			corpse_used[last_id] = true 
			shAddHPs(id, get_cvar_num("akasha_hpgain"), gMaxHealth[id] )
			corpses[id]+=1
			if (corpses[id]>=get_cvar_num("akasha_threshold")) {
				corpses[id]=0
				shAddXP(id, last_id, 1)
			}
//			set_user_rendering(last_id, kRenderFxFadeSlow, 255, 255, 255, kRenderTransColor, 4)
			get_user_name(last_id, name, 40)
			revive(id)
			client_print(id,print_chat,"[akasha] You drained %s's corpse and turned it into a zombie", name) 
			return PLUGIN_CONTINUE 
		} 
	} 
	client_print(id,print_chat,"[Akasha] There is no corpse nearby") 
	playSoundDenySelect(id)
	return PLUGIN_CONTINUE 
} 

public player_die() 
{ 
//	new killer = read_data(1)
	new victim = read_data(2) 
	get_user_origin(victim,pl_origins[victim],0) 
	return PLUGIN_CONTINUE 
}

public newRound(id)
{ 
// de scos totzi zombies de pe harta ?
	corpse_used[id] = false
	return PLUGIN_CONTINUE 
} 

public revive(id)
{ 
   if ( gHasAkashaPowers[id] && is_user_alive(id) ) 
   { 
           new cmd[128]
           format(cmd, 127, "monster zombie #%i", id )
           server_cmd(cmd)
   } 
   return PLUGIN_CONTINUE
}

public akasha_maxhealth()
{
	new id[6]
	new health[9]

	read_argv(1,id,5)
	read_argv(2,health,8)

	gMaxHealth[str_to_num(id)] = str_to_num(health)
}

