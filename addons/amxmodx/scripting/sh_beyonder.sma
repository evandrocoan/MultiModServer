#include <amxmodx> 
#include <fun> 
#include <engine> 
#include <superheromod> 

// Beyonder - BASED ON Vexds anim 

// CVARS 
// beyonder_level 
// beyonder_cooldown 
// beyonder_maxtime 

// VARIABLES 
new gHeroName[]="Beyonder" 
new bool:g_hasBeyonderPower[SH_MAXSLOTS+1] 
new beyonder[33]
new Float:beyonder_frame[33] 
new Float:beyonder_fstep[33] 
new Float:last_frame 
new beyonder_seq[32]
new Beyonderisdead[33] = false
new pIsDucking[33]
new DoOnce[33]
//---------------------------------------------------------------------------------------------- 
public plugin_init() 
{ 
// Plugin Info 
register_plugin("SUPERHERO Beyonder","3.0","Freecode/AssKicR") 

// FIRE THE EVENT TO CREATE THIS SUPERHERO! 
register_cvar("beyonder_level", "6" ) 
shCreateHero(gHeroName, "Fake Player", "Make a fake ilussion of a player", true, "beyonder_level" ) 

// 0 = unlimited... 
register_cvar("beyonder_cooldown", "0") 

// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS) 

// KEY DOWN 
register_srvcmd("beyonder_kd", "beyonder_kd") 
shRegKeyDown(gHeroName, "beyonder_kd") 
// INIT 
register_srvcmd("beyonder_init", "beyonder_init") 
shRegHeroInit(gHeroName, "beyonder_init") 

register_event("ResetHUD","newRound","b") 
register_event("DeathMsg", "beyonder_death", "a")

set_task(0.01,"check_duck",0,"",0,"b")
set_task(0.1,"FakeThink",0,"",0,"b")


// DEFAULT THE CVARS 
} 
//---------------------------------------------------------------------------------------------- 
public beyonder_death()
{
	new id=read_data(2)
	if (!Beyonderisdead[id]) {
		Beyonderisdead[id]=true
		beyonder_frame[id]=0.0
	}
	return PLUGIN_CONTINUE 
}
//---------------------------------------------------------------------------------------------- 
public newRound(id)
{
//  gPlayerUltimateUsed[id]=false

  if (!g_hasBeyonderPower[id]) return PLUGIN_CONTINUE
  gPlayerUltimateUsed[id]=false

  if (beyonder[id]) 
  {
	if (!Beyonderisdead[id]) {
		Beyonderisdead[id]=true
		beyonder_frame[id]=0.0
	}
  }
  return PLUGIN_CONTINUE
}
//---------------------------------------------------------------------------------------------- 
public beyonder_init() { 
	new temp[6] 
	// First Argument is an id 
	read_argv(1,temp,5) 
	new id=str_to_num(temp) 

	// 2nd Argument is 0 or 1 depending on whether the id has beyonder man powers 
	read_argv(2,temp,5) 
	new hasPowers=str_to_num(temp) 

	if ( hasPowers ) {
		g_hasBeyonderPower[id]=true
		Beyonderisdead[id]=false
	}else{
		g_hasBeyonderPower[id]=false
		if (!Beyonderisdead[id]) {
			Beyonderisdead[id]=true
			beyonder_frame[id]=0.0
		}
	}
} 
//---------------------------------------------------------------------------------------------- 
public beyonder_makeil(id) 
{ 
new Float:b_orig[3] 

if( beyonder[id] ) {
	if (!Beyonderisdead[id]) {
	Beyonderisdead[id]=true
	beyonder_frame[id]=0.0
	}
	return PLUGIN_CONTINUE 
}


//Spawning beyonder infront of a player 
new originplayer[3], originlook[3], aimvec[3] 

get_user_origin(id, originplayer) 
get_user_origin(id, originlook, 2) 


new distance[2] 

distance[0] = originlook[0]-originplayer[0] 
distance[1] = originlook[1]-originplayer[1] 


new unitsinfront = 80 

aimvec[0]=originplayer[0]+(unitsinfront*distance[0])/sqrt(distance[0]*distance[0]+distance[1]*distance[1]) 
aimvec[1]=originplayer[1]+(unitsinfront*distance[1])/sqrt(distance[0]*distance[0]+distance[1]*distance[1]) 
aimvec[2]=originplayer[2] 

b_orig[0] = float(aimvec[0]); 
b_orig[1] = float(aimvec[1]); 
b_orig[2] = float(aimvec[2]); 

beyonder[id] = create_entity("info_target") 
entity_set_string(beyonder[id], EV_SZ_classname, "fake_player") 

new model[32],modelchange[128]
get_user_info(id,"model",model,31)
format(modelchange,127,"models/player/%s/%s.mdl",model,model)
client_print(id,print_chat,"You Spawned A Fake with model %s",model) //DEBUG MESSAGE
entity_set_model(beyonder[id], modelchange)

entity_set_origin(beyonder[id], b_orig) 

new Float:MinBox[3] 
new Float:MaxBox[3] 

if (pIsDucking[id]) {
	MinBox[0] = -20.0 
	MinBox[1] = -20.0 
	MinBox[2] = -20.0 
	MaxBox[0] = 20.0 
	MaxBox[1] = 20.0 
	MaxBox[2] = 40.0 
}else{
	MinBox[0] = -20.0 
	MinBox[1] = -20.0 
	MinBox[2] = -40.0 
	MaxBox[0] = 20.0 
	MaxBox[1] = 20.0 
	MaxBox[2] = 40.0 
}
entity_set_vector(beyonder[id],EV_VEC_mins, MinBox) 
entity_set_vector(beyonder[id],EV_VEC_maxs, MaxBox) 
beyonder_seq[id]=0
new Float:tmpVec[3] 
tmpVec[0] = 40.0;   tmpVec[1] = 40.0; tmpVec[2] = 80.0
entity_set_vector(beyonder[id],EV_VEC_size,tmpVec)

entity_set_float(beyonder[id], EV_FL_health,99999200.0) 
entity_set_float(beyonder[id], EV_FL_takedamage, 1.0) 
entity_set_float(beyonder[id], EV_FL_dmg_take, 1.0)

entity_set_int(beyonder[id], EV_INT_solid, 2) 
entity_set_int(beyonder[id], EV_INT_movetype, 4) 
entity_set_byte(beyonder[id], EV_BYTE_controller1, 200) //Head direction, doesnt work 

return PLUGIN_CONTINUE 
} 
//---------------------------------------------------------------------------------------------- 
public server_frame() { 
	new id; 
	new Float:vel[3] 
	new Float:speed 
	new Float:new_frame = get_gametime() 
	new Float:newAngle[3] 
	new Float:orig[3]

	new Float:framerate = 30.0; 

	if( (new_frame - last_frame) < ( 1.0 / framerate) )  
	return PLUGIN_CONTINUE 

	last_frame = new_frame 


	for( id=0; id<(SH_MAXSLOTS+1); id++) { 
		if( beyonder[id] ) 
		{ 
		//check health and remove entity with some effects       
		new Float:health = entity_get_float(beyonder[id],EV_FL_health) 
		if( health <= 99999100.0 ) {
			new Float:MinBox[3] 
			new Float:MaxBox[3] 
			if (pIsDucking[id]) {
				MinBox[0] = 0.0 
				MinBox[1] = 0.0 
				MinBox[2] = -20.0 //change to -40 for standing models
				MaxBox[0] = 0.0 
				MaxBox[1] = 0.0 
				MaxBox[2] = 0.0 
			}else{
				MinBox[0] = 0.0 
				MinBox[1] = 0.0 
				MinBox[2] = -40.0 //change to -20 for crouching models
				MaxBox[0] = 0.0 
				MaxBox[1] = 0.0 
				MaxBox[2] = 0.0 
			}
			entity_set_vector(beyonder[id],EV_VEC_mins, MinBox) 
			entity_set_vector(beyonder[id],EV_VEC_maxs, MaxBox) 
			
			if (!Beyonderisdead[id]) {
			Beyonderisdead[id]=true
			beyonder_frame[id] = 0.0
			} 
		} 
		new Float:vRetVector[3]
		entity_get_vector(id, EV_VEC_v_angle, vRetVector)
		vRetVector[0]=float(0)
		entity_set_vector(beyonder[id], EV_VEC_angles, vRetVector)


		//Select sequence depending from speed 
		entity_get_vector(beyonder[id], EV_VEC_velocity, vel) 
		if( vel[0] != 0.0 && vel[1] != 0.0) { 
			vel[2] = 0.0
			vector_to_angle(vel, newAngle); 
			entity_set_vector(beyonder[id], EV_VEC_angles, newAngle) 
		} 

		vel[2] = 0.0 
		speed = vector_length(vel)
		//client_print(id,print_center,"Beyonder speed = %f ",speed)
//********************************************** NEVER CALLED **********************************************
		if( speed <= 5 && beyonder_seq[id] != 1 && !pIsDucking[id] && !Beyonderisdead[id]) // select idle sequence 
		{ 
			if (DoOnce[id]) {
				entity_get_vector(beyonder[id],EV_VEC_origin,orig)
				orig[2]=orig[2]+20
				entity_set_vector(beyonder[id],EV_VEC_origin,orig)
				DoOnce[id]=false
			}
			beyonder_seq[id] = 1
			entity_set_int(beyonder[id], EV_INT_sequence, 1)
			new Float:MinBox[3] 
			new Float:MaxBox[3] 

			MinBox[0] = -20.0 
			MinBox[1] = -20.0 
			MinBox[2] = -40.0 
			MaxBox[0] = 20.0 
			MaxBox[1] = 20.0 
			MaxBox[2] = 40.0 

			entity_set_vector(beyonder[id],EV_VEC_mins, MinBox) 
			entity_set_vector(beyonder[id],EV_VEC_maxs, MaxBox) 

			new Float:tmpVec[3] 
			tmpVec[0] = 40.0;   tmpVec[1] = 40.0; tmpVec[2] = 80.0
			entity_set_vector(beyonder[id],EV_VEC_size,tmpVec)
		}
		else if( speed <= 5 && beyonder_seq[id] != 2 && pIsDucking[id] && !Beyonderisdead[id]) // select idle duck sequence  
		{ 
			if (DoOnce[id]) {
				entity_get_vector(beyonder[id],EV_VEC_origin,orig)
				orig[2]=orig[2]-20
				entity_set_vector(beyonder[id],EV_VEC_origin,orig)
				DoOnce[id]=false
			}
			beyonder_seq[id] = 2 
			entity_set_int(beyonder[id], EV_INT_sequence, 2)
			new Float:MinBox[3] 
			new Float:MaxBox[3] 

			MinBox[0] = -20.0 
			MinBox[1] = -20.0 
			MinBox[2] = -20.0 
			MaxBox[0] = 20.0 
			MaxBox[1] = 20.0 
			MaxBox[2] = 40.0 

			entity_set_vector(beyonder[id],EV_VEC_mins, MinBox) 
			entity_set_vector(beyonder[id],EV_VEC_maxs, MaxBox) 

			new Float:tmpVec[3] 
			tmpVec[0] = 40.0;   tmpVec[1] = 40.0; tmpVec[2] = 80.0
			entity_set_vector(beyonder[id],EV_VEC_size,tmpVec)
		}
		else if( speed >= 6 && beyonder_seq[id] != 4 && !pIsDucking[id] && !Beyonderisdead[id]) //run sequence 
		{ 
			if (DoOnce[id]) {
				entity_get_vector(beyonder[id],EV_VEC_origin,orig)
				orig[2]=orig[2]+20
				entity_set_vector(beyonder[id],EV_VEC_origin,orig)
				DoOnce[id]=false
			}
			beyonder_seq[id] = 4 
			entity_set_int(beyonder[id], EV_INT_sequence, 4)
			new Float:MinBox[3] 
			new Float:MaxBox[3] 

			MinBox[0] = -20.0 
			MinBox[1] = -20.0 
			MinBox[2] = -40.0 
			MaxBox[0] = 20.0 
			MaxBox[1] = 20.0 
			MaxBox[2] = 40.0 

			entity_set_vector(beyonder[id],EV_VEC_mins, MinBox) 
			entity_set_vector(beyonder[id],EV_VEC_maxs, MaxBox) 

			new Float:tmpVec[3] 
			tmpVec[0] = 40.0;   tmpVec[1] = 40.0; tmpVec[2] = 80.0
			entity_set_vector(beyonder[id],EV_VEC_size,tmpVec)
		} 
		else if( speed >= 6 && beyonder_seq[id] != 5 && pIsDucking[id] && !Beyonderisdead[id]) //run duck sequence 
		{ 
			if (DoOnce[id]) {
				entity_get_vector(beyonder[id],EV_VEC_origin,orig)
				orig[2]=orig[2]-20
				entity_set_vector(beyonder[id],EV_VEC_origin,orig)
				DoOnce[id]=false
			}
			beyonder_seq[id] = 5 
			entity_set_int(beyonder[id], EV_INT_sequence, 5)
			new Float:MinBox[3] 
			new Float:MaxBox[3] 

			MinBox[0] = -20.0 
			MinBox[1] = -20.0 
			MinBox[2] = -20.0 
			MaxBox[0] = 20.0 
			MaxBox[1] = 20.0 
			MaxBox[2] = 40.0 

			entity_set_vector(beyonder[id],EV_VEC_mins, MinBox) 
			entity_set_vector(beyonder[id],EV_VEC_maxs, MaxBox) 

			new Float:tmpVec[3] 
			tmpVec[0] = 40.0;   tmpVec[1] = 40.0; tmpVec[2] = 80.0
			entity_set_vector(beyonder[id],EV_VEC_size,tmpVec)
		}
//********************************************** NEVER CALLED END **********************************************
		else if (Beyonderisdead[id] && pIsDucking[id]) 
		{
			entity_set_int(beyonder[id], EV_INT_sequence, 94)
		}
		else if (Beyonderisdead[id] && !pIsDucking[id]) 
		{
			entity_set_int(beyonder[id], EV_INT_sequence, 86)
		}

		beyonder_fstep[id] = 5.0 
		beyonder_frame[id] += beyonder_fstep[id] 

		if( beyonder_frame[id] >= 254.0 && Beyonderisdead[id]) {
			entity_get_vector(beyonder[id],EV_VEC_origin,orig) 
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
			write_byte(11) 
			write_coord(floatround(orig[0])) 
			write_coord(floatround(orig[1])) 
			write_coord(floatround(orig[2])) 
			message_end() 
			client_print(id,print_chat,"Your fake died")
			remove_entity(beyonder[id])
			beyonder[id] = 0
			Beyonderisdead[id]=false
		}
		else if( beyonder_frame[id] >= 254.0 ) beyonder_frame[id] = 0.0 

		//client_print(0,print_center,"id = %f",beyonder_frame[id]); 
		entity_set_float(beyonder[id], EV_FL_frame, beyonder_frame[id]) 

		} 
	}
	return PLUGIN_CONTINUE 
} 
//---------------------------------------------------------------------------------------------- 
public plugin_precache() 
{ 
precache_model("models/player/leet/leet.mdl") 
precache_model("models/player/arctic/arctic.mdl") 
precache_model("models/player/guerilla/guerilla.mdl") 
precache_model("models/player/terror/terror.mdl") 

precache_model("models/player/gign/gign.mdl") 
precache_model("models/player/sas/sas.mdl") 
precache_model("models/player/gsg9/gsg9.mdl") 
precache_model("models/player/urban/urban.mdl") 

precache_model("models/player/vip/vip.mdl") 

return PLUGIN_CONTINUE 
} 
//---------------------------------------------------------------------------------------------- 
// RESPOND TO KEYDOWN 
public beyonder_kd() { 
	new temp[6] 

	// First Argument is an id with NightCrawler Powers! 
	read_argv(1,temp,5) 
	new id=str_to_num(temp) 

	if ( !is_user_alive(id) ) return PLUGIN_HANDLED 

	// Let them know they already used their ultimate if they have 
	if ( !g_hasBeyonderPower[id] ) return PLUGIN_HANDLED

	if (!Beyonderisdead[id]) {
		beyonder_makeil(id) 
	}
	return PLUGIN_HANDLED 
} 
//------------------------------------------------------------------------------------------ 
public check_duck() { 
  
	for(new i = 1; i <= get_maxplayers(); ++i) { 
		if (is_user_alive(i)) {
			if (!Beyonderisdead[i]) {
				if (get_user_button(i)&IN_DUCK) { 
					if (!pIsDucking[i]) {
						pIsDucking[i]=true
						DoOnce[i]=true
					}
				}else{
					if (pIsDucking[i]) {
						pIsDucking[i]=false
						DoOnce[i]=true
					}
				}
			}

		}
	}
	return PLUGIN_CONTINUE 
}

public FakeThink() 
{    
   new aimvec[3] 
   new origin[3]    
   new Float:temp[3] 
   new avgFactor = 3
   new mVelo[3] 
   new iNewVelocity[3]     
   new speed = 300;    
   new length, velocityvec[3]    
   new id; 


   for(id=0; id<32; id++) 
   { 
      if( beyonder[id]) 
      { 

         get_user_origin(id,aimvec) 

         entity_get_vector(beyonder[id], EV_VEC_origin, temp) 
         origin[0] = floatround(temp[0]) 
         origin[1] = floatround(temp[1]) 
         origin[2] = floatround(temp[2]) + 30 

         if( get_distance(origin,aimvec) > 150 ) 
         {    
			if (get_distance(origin,aimvec) > 450 ) avgFactor = 2

			entity_get_vector(beyonder[id], EV_VEC_velocity, temp) 
			mVelo[0] = floatround(temp[0]) 
			mVelo[1] = floatround(temp[1]) 
			mVelo[2] = floatround(temp[2]) 

			entity_get_vector(beyonder[id], EV_VEC_velocity, temp) 
			mVelo[0] = floatround(temp[0]) 
			mVelo[1] = floatround(temp[1]) 
			mVelo[2] = floatround(temp[2]) 
			 

			velocityvec[0]=aimvec[0]-origin[0] 
			velocityvec[1]=aimvec[1]-origin[1] 
			velocityvec[2]=aimvec[2]-origin[2] 
			length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2]) 
			velocityvec[0]=velocityvec[0]*speed/length 
			velocityvec[1]=velocityvec[1]*speed/length 
			velocityvec[2]=velocityvec[2]*speed/length 

			iNewVelocity[0] = (velocityvec[0] + (mVelo[0] * (avgFactor-1) ) ) / avgFactor 
			iNewVelocity[1] = (velocityvec[1] + (mVelo[1] * (avgFactor-1) ) ) / avgFactor 
			iNewVelocity[2] = (velocityvec[2] + (mVelo[2] * (avgFactor-1) ) ) / avgFactor 
			//iNewVelocity[2] = 0; 
			 
			temp[0] = float(iNewVelocity[0]) 
			temp[1] = float(iNewVelocity[1]) 
			temp[2] = float(iNewVelocity[2]) 

			entity_set_vector(beyonder[id], EV_VEC_velocity, temp) 
         } 
/*         else 
         { 
			temp[0] = 0.0 
			temp[1] = 0.0 
			temp[2] = 0.0 
			entity_set_vector(beyonder[id], EV_VEC_velocity, temp) 
         } */

      } 
   } 
} 