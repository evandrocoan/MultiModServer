#include <amxmodx> 
#include <fun>
#include <cstrike>
#include <engine> 
#include <superheromod>

// The Terminator!

// CVARS
// terminator_level # = What level is he avalible (def=0)
// terminator_gravity = What is his Gravity... (def=2.0)
// terminator_armor = How much AP does he have (def=125)
// terminator_health = How much HP does he have (def=150)
// terminator_speed = How slow is he when having a M3/autoshotty(def=200)
// terminator_saveskin = Save the stolen skin through the rounds (def=0)
// terminator_getm3 = Get a free M3 (def=1)
// terminator_ammo = Unlimited M3 ammo?? (def=0)
// terminator_dropwpn = Drop old M3 when getting new M3 (def=0)

// VARIABLES
new gHeroName[]="Terminator"
new gHasTermPower[SH_MAXSLOTS+1]

new gmsgFade 
new bool:NightVisionUse[33] 

new pl_origins[33][3] 
new bool:pl_carmouflaged[33] = {false,...} 
new bool:pl_taken[33] = {false,...} 

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Terminator","1.00","AssKicR")
 
	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	if ( isDebugOn() ) server_print("Attempting to create terminator Hero")
	if ( !cvar_exists("terminator_level") ) register_cvar("terminator_level", "0")
	shCreateHero(gHeroName, "Power", "Steal the skin of dead people & Red NVGs", true, "terminator_level" )
	
	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("terminator_init", "terminator_init")
	shRegHeroInit(gHeroName, "terminator_init")

	// KEYDOWN 
	register_srvcmd("terminator_kd", "terminator_kd") 
	shRegKeyDown(gHeroName, "terminator_kd") 
	
	register_event("ResetHUD","new_round","b")
	register_event("DeathMsg","player_die","a") 

	// NightVision 
	register_clcmd("nightvision","ToggleNVG") 
	gmsgFade = get_user_msgid("ScreenFade") 

	// DEFAULT THE CVARS
	register_cvar("terminator_gravity", "2.00" )	//Gravity...
	register_cvar("terminator_armor", "125")		//How much AP does he have
	register_cvar("terminator_health", "150")		//How much HP does he have
	register_cvar("terminator_speed", "200" )		//How slow is he when having a M3/autoshotty
	register_cvar("terminator_saveskin", "0" )		//Save the stolen skin through the rounds
	register_cvar("terminator_getm3", "1" )			//Get a free M3
	register_cvar("terminator_ammo", "0" )			//Unlimited M3 ammo??
	register_cvar("terminator_dropwpn", "0" )		//Drop when getting new M3

	shSetMaxHealth(gHeroName, "terminator_health" )
	shSetMinGravity(gHeroName, "terminator_gravity" )
	shSetMaxArmor(gHeroName, "terminator_armor" )
	shSetMaxSpeed(gHeroName, "terminator_speed", "[21][22]" )
}
//----------------------------------------------------------------------------------------------
public terminator_init() { 
	new temp[128] 
	// First Argument is an id 
	read_argv(1,temp,5) 
	new id=str_to_num(temp) 

	// 2nd Argument is 0 or 1 depending on whether the id has Som-Gokus powers 
	read_argv(2,temp,5) 
	new hasPowers=str_to_num(temp) 
	gHasTermPower[id]=(hasPowers != 0)

	if (!gHasTermPower[id]) {
		shRemHealthPower(id)
		shRemArmorPower(id)
		shRemSpeedPower(id)
		shRemGravityPower(id)
		StopNVG(id)
	  }
	} 
//----------------------------------------------------------------------------------------------
public client_connect(id) // reset some settings 
{ 
   gHasTermPower[id] = false // cannot use NightVision 
} 
//---------------------------------------------------------------------------------------------- 
public client_disconnect(id) 
{ 
   if (NightVisionUse[id]) StopNVG(id) // stop NightVision 
} 
//---------------------------------------------------------------------------------------------- 

public terminator_getwpn(id){
	if (get_cvar_num("terminator_getm3")==1) {
		shGiveWeapon(id,"weapon_m3")
	}
	return PLUGIN_CONTINUE 
} 
//----------------------------------------------------------------------------------------------
public terminator_kd() { 
	if ( !hasRoundStarted() ) return PLUGIN_HANDLED 
	new temp[6]
  
	// First Argument is an id with terminator Powers!
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( !is_user_alive(id) ) return PLUGIN_HANDLED 
	if ( !gHasTermPower[id] ) return PLUGIN_HANDLED 

	new cur_origin[3],players[32],pl_num=0,dist,last_dist=99999,last_id,model[32] 
	get_user_origin(id,cur_origin,0) 
	get_players(players,pl_num,"b") 
	if (pl_num>0) { 
		for (new i=0;i<pl_num;i++) { 
			if (players[i]!=id) { 
				dist = get_distance(cur_origin,pl_origins[players[i]]) 
				if (dist<last_dist) { 
					last_id = players[i] 
					last_dist = dist 
				} 
			} 
		} 
		if (last_dist<80) { 
			if (pl_taken[last_id]) { 
				client_print(id,print_chat,"[Terminator] These clothes have already been taken.") 
				return PLUGIN_CONTINUE 
			} 
			get_user_info(last_id,"model",model,31) 
			cs_set_user_model(id, model) 
			pl_carmouflaged[id] = true 
			pl_taken[last_id] = true 
			emit_sound(id,CHAN_VOICE,"items/tr_kevlar.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) 
			client_print(id,print_chat,"[Terminator] You are now looking like a %s",model) 
			return PLUGIN_CONTINUE 
		} 
	} 
	client_print(id,print_chat,"[Terminator] There is no corpse nearby to get clothes from") 
	return PLUGIN_CONTINUE 
} 
//----------------------------------------------------------------------------------------------
public player_die() { 
	new killer = read_data(1)
	new victim = read_data(2) 
	get_user_origin(victim,pl_origins[victim],0) 
	if (get_cvar_num("terminator_saveskin")!=1) {
		if (pl_carmouflaged[victim]) { 
			cs_reset_user_model(victim) 
		} 
	}
	if (gHasTermPower[victim]) {
		new name[33]
		get_user_name(victim,name,32)
		client_print(killer,print_chat,"%s: I'l be back!!!",name)
	}
	return PLUGIN_CONTINUE 
} 
//----------------------------------------------------------------------------------------------
public new_round(id){ 
	if (get_cvar_num("terminator_saveskin")!=1) {
		if (pl_carmouflaged[id]) { 
			cs_reset_user_model(id) 
			pl_carmouflaged[id] = false 
		} 
	}
	if (NightVisionUse[id]) StopNVG(id) // stop NightVision 
	pl_taken[id] = false
	if (gHasTermPower[id]) {
		terminator_getwpn(id)
	}
	return PLUGIN_CONTINUE 
} 
//----------------------------------------------------------------------------------------------
public plugin_precache(){ 
	precache_sound( "items/tr_kevlar.wav") 
	precache_sound( "items/nvg_on.wav" )
	precache_sound( "items/nvg_off.wav" )
	return PLUGIN_CONTINUE 
} 
//----------------------------------------------------------------------------------------------
public changeWeapon(id)
{
    if ( !gHasTermPower[id] || !shModActive() ) return PLUGIN_CONTINUE
    new clip, ammo
    new wpn_id=get_user_weapon(id, clip, ammo);
    new wpn[32]

    if ( wpn_id!=CSW_M3 ) return PLUGIN_CONTINUE
    
    // Never Run Out of Ammo on M3!
    //server_print("STATUS ID=%d CLIP=%d, AMMO=%d WPN=%d", id, clip, ammo, wpn_id)
    if ( clip == 0 )
    {
      //server_print("INVOKING TERMINATOR MODE! ID=%d CLIP=%d, AMMO=%d WPN=%d", id, clip, ammo, wpn_id)
      get_weaponname(wpn_id,wpn,31)
      //highly recommend droppging weapon - buggy without it!
      if ( get_cvar_num("terminator_dropwpn")!=0 ) engclient_cmd(id,"drop",wpn)  //TEST
      give_item(id,wpn)
      engclient_cmd(id, wpn ) 
      shResetSpeed(id)
    }
    return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------- 
public ToggleNVG(id) 
{ 
   if (!gHasTermPower[id] || !shModActive() ) return PLUGIN_CONTINUE
   if (NightVisionUse[id]) StopNVG(id) 
   else StartNVG(id) 

   return PLUGIN_HANDLED 
} 
//---------------------------------------------------------------------------------------------- 
public StartNVG(id) // NightVision code by Lazy (a little bit modified) 
{ 
   if ( !gHasTermPower[id] || !shModActive() ) return PLUGIN_CONTINUE
   new player[32] 
   get_user_name(id,player,32) 

   emit_sound(id,CHAN_ITEM,"items/nvg_on.wav",1.0,ATTN_NORM,0,PITCH_NORM) 
   set_task(0.1,"RunNVG",id+100,player,32,"b") // another task id for each player 
   set_task(0.1,"RunNVG2",id+200,player,32,"b") 
   NightVisionUse[id] = true 

   return PLUGIN_HANDLED 
} 
//---------------------------------------------------------------------------------------------- 
public StopNVG(id) 
{ 
   emit_sound(id,CHAN_ITEM,"items/nvg_off.wav",1.0,ATTN_NORM,0,PITCH_NORM) 

   remove_task(id+100) 
   remove_task(id+200) 
   NightVisionUse[id] = false 

   return PLUGIN_HANDLED 
} 
//---------------------------------------------------------------------------------------------- 
public RunNVG(player[]) 
{ 
   new id = get_user_index(player) 
   new origin[3] 
   get_user_origin(id,origin) 

   message_begin(MSG_ONE,SVC_TEMPENTITY,{0,0,0},id) 

   write_byte(27) 

   write_coord(origin[0]) 
   write_coord(origin[1]) 
   write_coord(origin[2]) 

   write_byte(125) 

   write_byte(230) 
   write_byte(0) 
   write_byte(0) 

   write_byte(1) 
   write_byte(10) 

   message_end() 
} 
//---------------------------------------------------------------------------------------------- 
public RunNVG2(player[]) 
{ 
   new id = get_user_index(player) 

   message_begin(MSG_ONE,gmsgFade,{0,0,0},id) 

   write_short(1000) 
   write_short(1000) 
   write_short(1<<12) 

   write_byte(230) 
   write_byte(0) 
   write_byte(0) 

   write_byte(150) 

   message_end() 
} 
//----------------------------------------------------------------------------------------------