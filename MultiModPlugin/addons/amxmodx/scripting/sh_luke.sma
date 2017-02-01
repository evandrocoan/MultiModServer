#include <amxmodx>
#include <cstrike>
#include <superheromod.inc>

// Luke Skywalker 

//Credits -- Ludvig Van for Original Lightsaber code

// VARIABLES

new gHeroName[]="Luke Skywalker"
new bool:g_hasLukePower[SH_MAXSLOTS+1]
new saber 
new ls_stat[33]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Luke Skywalker","1.00","AssKicR")
 
	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	if (!cvar_exists("luke_level")) register_cvar("luke_level", "0" )
	shCreateHero(gHeroName, "Ligthsaber", "Kill Your Enemies With The Mighty Powers Of The Force!", true, "luke_level" )
	
	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	register_event("ResetHUD","newRound","b")

	// KEY DOWN
	register_srvcmd("luke_kd", "luke_kd")
	shRegKeyDown(gHeroName, "luke_kd")
	
	// INIT
	register_srvcmd("luke_init", "luke_init")
	shRegHeroInit(gHeroName, "luke_init")

	if (!cvar_exists("luke_sabertime")) register_cvar("luke_sabertime", "20.0" )
	if (!cvar_exists("luke_sabermode")) register_cvar("luke_sabermode", "2" ) //1=Only Kills Enemies 2=Kills Enemies And Frienlies
	if (!cvar_exists("luke_cooldown")) register_cvar("luke_cooldown", "20" )
	
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	saber = precache_model("sprites/laserbeam.spr")
	precache_sound("ambience/zapmachine.wav")
	precache_sound("vox/_period.wav")

	return PLUGIN_CONTINUE 
}
//----------------------------------------------------------------------------------------------
public luke_init()
{
	new temp[6]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)
	
	// 2nd Argument is 0 or 1 depending on whether the id has Luke Skywalker powers
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)
	
	g_hasLukePower[id]=(hasPowers!=0)

}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
	gPlayerUltimateUsed[id]=false
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public luke_kd() 
{ 
	new temp[6]
	
	if ( !hasRoundStarted() ) return PLUGIN_HANDLED
	
	// First Argument is an id with luke Powers!
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( gPlayerUltimateUsed[id] )
	{
		playSoundDenySelect(id)
		return PLUGIN_HANDLED 
	}	

	if (!g_hasLukePower[id]) return PLUGIN_CONTINUE
	if ((is_user_alive(id)==0) || (ls_stat[id] != 0) ){
//		client_print(id,print_console,"[AMX] You cannot use a light saber when you are dead or have an active one already")
		return PLUGIN_HANDLED
	}

	new tid[5]
	tid[0] = id
	if (get_cvar_num("luke_sabermode")==1) {
	tid[1] = 1
	}
	if (get_cvar_num("luke_sabermode")==2){
	tid[1] = 2 
	}
	tid[2] = 0	 // vcolors[a][0] 
	tid[3] = 255 // vcolors[a][1] Commeted out, 0,255,0 = green that you wanted
	tid[4] = 0	 // vcolors[a][2]
	new repeats = (get_cvar_num("luke_sabertime")*10)
	set_task(0.1,"lightsaber",0,tid,5,"a",repeats)
	set_task(float(get_cvar_num("luke_sabertime")),"ls_off",413,tid,1)
//	set_task(20.0,"ls_off",413,tid,1)
	ls_stat[id] = 1
	emit_sound(id,CHAN_ITEM, "ambience/zapmachine.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	gPlayerUltimateUsed[id]=true
	ultimateTimer(id, get_cvar_num("luke_sabertime")+get_cvar_num("luke_cooldown") * 1.0)

	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public ls_off(id[]){
	ls_stat[id[0]] = 0
	emit_sound(id[0],CHAN_ITEM, "vox/_period.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	return PLUGIN_CONTINUE	
}
//----------------------------------------------------------------------------------------------
public lightsaber(id[]){
	if(is_user_alive(id[0]) == 0)
		return PLUGIN_CONTINUE
	new vec[3] 
	new aimvec[3] 
	new lseffvec[3]
	new length
	new speed = 65 
	get_user_origin(id[0],vec,1) 
	get_user_origin(id[0],aimvec,2) 
	lseffvec[0]=aimvec[0]-vec[0] 
	lseffvec[1]=aimvec[1]-vec[1] 
	lseffvec[2]=aimvec[2]-vec[2] 
	length=sqrt(lseffvec[0]*lseffvec[0]+lseffvec[1]*lseffvec[1]+lseffvec[2]*lseffvec[2]) 
	lseffvec[0]=lseffvec[0]*speed/length 
	lseffvec[1]=lseffvec[1]*speed/length 
	lseffvec[2]=lseffvec[2]*speed/length 

	new vorigin[3]
	new maxpl = get_maxplayers() +1
	new teama[32],teamv[32]
	get_user_team(id[0],teama,31)
	for(new a = 1; a < maxpl; a++) {			
		if(is_user_alive(a) != 0){
			get_user_origin(a,vorigin)
			if (get_distance(vec,vorigin)<100){				
				if(a != id[0]){
					get_user_team(a,teamv,31)
					if(!equal(teama,teamv,2)){
						if(id[1] != 0){
							user_kill(a,1)
							set_user_frags(id[0], get_user_frags(id[0])+1) 
							cs_set_user_money(id[0], cs_get_user_money(id[0])+150)
							shAddXP(id[0], a, 1)
							client_print(a,print_chat,"[AMX] The power of the force has killed you.")
							//Public Hummiliaton
							message_begin( MSG_ALL, get_user_msgid("DeathMsg"),{0,0,0},0)
							write_byte(id[0])
							write_byte(a)
							write_byte(0)
							write_string("Lightsaber")
							message_end()
							//Save Hummiliation
							new namea[24],namev[24],authida[20],authidv[20]
							//Info On Attacker
							get_user_name(id[0],namea,23) 
							get_user_team(id[0],teama,7) 
							get_user_authid(id[0],authida,19) 
							 //Info On Victim
							get_user_name(a,namev,23) 
							get_user_team(a,teamv,7) 
							get_user_authid(a,authidv,19)
							 //Log This Kill
							log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"Lightsaber^"", 
							namea,get_user_userid(id[0]),authida,teama,namev,get_user_userid(a),authidv,teamv)
						}
					}
					else if(id[1] == 2){
						user_kill(a,1)
						set_user_frags(id[0], get_user_frags(id[0])-1) 
						cs_set_user_money(id[0], cs_get_user_money(id[0])-500, 0)
						shAddXP(id[0], a, -1)
						client_print(a,print_chat,"[AMX] The power of the force has killed you.")
						//Public Hummiliaton
						message_begin( MSG_ALL, get_user_msgid("DeathMsg"),{0,0,0},0)
						write_byte(id[0])
						write_byte(a)
						write_byte(0)
						write_string("Lightsaber")
						message_end()
						//Save Hummiliation
						new namea[24],namev[24],authida[20],authidv[20]
						//Info On Attacker
						get_user_name(id[0],namea,23) 
						get_user_team(id[0],teama,7) 
						get_user_authid(id[0],authida,19) 
						//Info On Victim
						get_user_name(a,namev,23) 
						get_user_team(a,teamv,7) 
						get_user_authid(a,authidv,19)
						//Log This Kill
						log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"Lightsaber^"", 
						namea,get_user_userid(id[0]),authida,teama,namev,get_user_userid(a),authidv,teamv)
					}						
				}						
			}
		}
	}

	// beam effect between point and entity
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
	write_byte ( 1 )		 //TE_BEAMENTPOINT 1	
	write_short (id[0])		 // ent 
	write_coord (lseffvec[0]+vec[0])//end position 
	write_coord (lseffvec[1]+vec[1])
	write_coord (lseffvec[2]+vec[2]+10)
	write_short (saber)	// sprite 
	write_byte (0)			 // start frame 
	write_byte (15)			// frame rate in 0.1's 
	write_byte (1)		 // byte (life in 0.1's 
	write_byte (20)			// line width in 0.1's
	write_byte (5)			// noise amplitude in 0.01's 
	write_byte (id[2])			 // RGB color
	write_byte (id[3])
	write_byte (id[4])
	write_byte (255)		 // brightness
	write_byte (10)			// scroll speed in 0.1's
	message_end() 
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public client_connect(id)
{ 
	 ls_stat[id] = 0 
	 return PLUGIN_CONTINUE 
} 
//---------------------------------------------------------------------------------------------- 
public client_disconnect(id)
{ 
	 ls_stat[id] = 0 
	 return PLUGIN_CONTINUE 
}
//----------------------------------------------------------------------------------------------