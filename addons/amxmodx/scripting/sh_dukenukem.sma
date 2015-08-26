#include <amxmod.inc> 
#include <xtrafun> 
#include <superheromod.inc> 

// dukenukem! - Credits AssKicR & Scarzzurs/The_Unbound & {HOJ} Batman

// CVARS 
// dukenukem_radius     # distance of people affected by blast 
// dukenukem_fuse       # of seconds before dukenukem blows Up 
// dukenukem_level 


// VARIABLES 
new gHeroName[]="Duke Nukem" 
new bool:gHasDukePowers[SH_MAXSLOTS+1] 
//new BOMB_FUSE = 15        // fuse time (can be changed) 
//new BOMBKILL_RANGE = 250  // killing radius of bomb. (96 is playerheight) 

new smoke 
new white 
new fire 
new IsDukeBomb[33] 
//---------------------------------------------------------------------------------------------- 
public plugin_init() 
{ 
  // Plugin Info 
  register_plugin("SUPERHERO Duke Nukem","1.14.4","AssKicR") 

  // FIRE THE EVENT TO CREATE THIS SUPERHERO! 
  register_cvar("dukenukem_level", "0" ) 
  shCreateHero(gHeroName, "Nuke", "if ur enemys get 2 close 2 u just blow them up!", true, "dukenukem_level" ) 

  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS) 
  register_event("ResetHUD","newRound","b")
  register_event("DeathMsg","death","a") 

  // KEY DOWN 
  register_srvcmd("dukenukem_kd", "dukenukem_kd") 
  shRegKeyDown(gHeroName, "dukenukem_kd") 

  register_event("Damage", "dukenukem_damage", "b", "2!0")

  // INIT 
  register_srvcmd("dukenukem_init", "dukenukem_init") 
  shRegHeroInit(gHeroName, "dukenukem_init") 

  // DEFAULT THE CVARS 
  // dukenukem_radius     # distance of people affected by blast 
  // dukenukem_fuse       # of seconds before dukenukem blows Up 
  register_cvar("dukenukem_cooldown", "45" )
  register_cvar("dukenukem_radius", "300" ) 
  register_cvar("dukenukem_fuse", "0" )
  register_cvar("dukenukem_maxdamage", "125" )   
  set_task(1.0,"DukeBomb_timer",0,"",0,"b") //forever loop
} 
//---------------------------------------------------------------------------------------------- 
public plugin_precache() 
{ 
   smoke = precache_model("sprites/steam1.spr") 
   white = precache_model("sprites/white.spr") 
   fire = precache_model("sprites/explode1.spr") 
   precache_sound( "buttons/blip2.wav") 
   precache_sound( "misc/yousuck.wav" )
} 
//---------------------------------------------------------------------------------------------- 
public dukenukem_init() 
{ 
  new temp[6] 
  // First Argument is an id 
  read_argv(1,temp,5) 
  new id=str_to_num(temp) 

  // 2nd Argument is 0 or 1 depending on whether the id has dukenukem powers 
  read_argv(2,temp,5) 
  new hasPowers=str_to_num(temp) 

  gHasDukePowers[id]=(hasPowers!=0) 

} 
//---------------------------------------------------------------------------------------------- 
public dukenukem_damage(id)
{
  if (!shModActive() || !gHasDukePowers[id] ) return PLUGIN_CONTINUE

  //new damage = read_data(2)
  new weapon, bodypart, attacker = get_user_attacker(id,weapon,bodypart)
    
  if ( is_user_alive(id) && !is_user_alive(attacker) && id != attacker )
  {
   client_cmd(attacker, "spk misc/yousuck.wav")
  }
  return PLUGIN_CONTINUE
}
//---------------------------------------------------------------------------------------------- 
public explode( vec1[3] )
{ 
   // blast circles 
   message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1) 
   write_byte( 21 ) 
   write_coord(vec1[0]) 
   write_coord(vec1[1]) 
   write_coord(vec1[2] + 16) 
   write_coord(vec1[0]) 
   write_coord(vec1[1]) 
   write_coord(vec1[2] + 1936) 
   write_short( white ) 
   write_byte( 0 ) // startframe 
   write_byte( 0 ) // framerate 
   write_byte( 2 ) // life 2 
   write_byte( 20 ) // width 16 
   write_byte( 0 ) // noise 
   write_byte( 188 ) // r 
   write_byte( 220 ) // g 
   write_byte( 255 ) // b 
   write_byte( 255 ) //brightness 
   write_byte( 0 ) // speed 
   message_end() 

   //Explosion2 
   message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
   write_byte( 12 ) 
   write_coord(vec1[0]) 
   write_coord(vec1[1]) 
   write_coord(vec1[2]) 
   write_byte( 188 ) // byte (scale in 0.1's) 188 
   write_byte( 10 ) // byte (framerate) 
   message_end() 

   //TE_Explosion 
   message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1) 
   write_byte( 3 ) 
   write_coord(vec1[0]) 
   write_coord(vec1[1]) 
   write_coord(vec1[2]) 
   write_short( fire ) 
   write_byte( 60 ) // byte (scale in 0.1's) 188 
   write_byte( 10 ) // byte (framerate) 
   write_byte( 0 ) // byte flags 
   message_end() 


   //Smoke 
   message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1) 
   write_byte( 5 ) // 5 
   write_coord(vec1[0]) 
   write_coord(vec1[1]) 
   write_coord(vec1[2]) 
   write_short( smoke ) 
   write_byte( 10 )  // 2 
   write_byte( 10 )  // 10 
   message_end() 

} 
//---------------------------------------------------------------------------------------------- 
public death()
{
  new id = read_data(2)
  if ( IsDukeBomb[id] > 0 ) BlowUp(id)
}
//---------------------------------------------------------------------------------------------- 
public DukeBomb_check(id)
{
  emit_sound(id,CHAN_ITEM, "buttons/blip2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) 
  IsDukeBomb[id] -= 1
         
  if (IsDukeBomb[id] == 0 ) 
  {
    BlowUp(id)
  }
  else
  {
    // Decrement the counter
    set_hudmessage(0, 100, 200, 0.05, 0.65, 2, 0.02, 1.0, 0.01, 0.1, 2) 
    show_hudmessage(id,"You will explode in %d seconds.",IsDukeBomb[id]) 
           
    // Say Time Remaining to the User Only.
    if ( IsDukeBomb[id] == 11 ) client_cmd(id,"spk ^"fvox/remaining^"") 
    if ( IsDukeBomb[id] < 11 )
    {
      new temp[48] 
      num_to_word(IsDukeBomb[id],temp,47) 
      client_cmd(id,"spk ^"fvox/%s^"",temp) 
    }
  }
}
//---------------------------------------------------------------------------------------------- 
public DukeBomb_timer()
{ 
   // new maxpl= get_maxplayers()
   // Testing maxplayers
   for(new id = 1; id <= SH_MAXSLOTS; id++) 
   { 
      if (IsDukeBomb[id] > 0) DukeBomb_check(id)
   }
} 
//---------------------------------------------------------------------------------------------- 
public BlowUp(id)
{ 
   new damage, multiplier
   new distanceBetween
   IsDukeBomb[id] = 0 
   
   new name[32] 
   get_user_name(id,name,31) 
   set_user_rendering(id,kRenderFxNone,255,255,255, kRenderNormal,16);
   set_hudmessage(0, 100, 200, 0.05, 0.65, 2, 0.02, 1.0, 0.01, 0.1, 2) 
   show_hudmessage(0,"%s has exploded.",name) 
   new FFOn= get_cvar_num("mp_friendlyfire")
   new origin[3] 
   get_user_origin(id,origin)
   
   explode(origin) // blowup even if dead
   
   // new maxpl = get_maxplayers() 
   for(new a = 1; a <= SH_MAXSLOTS; a++) 
   { 
     if( is_user_alive(a) && ( get_user_team(id) != get_user_team(a) || FFOn!= 0 || a==id ) )
     {
       new origin1[3]
       get_user_origin(a,origin1) 
     
       distanceBetween = get_distance(origin, origin1 )
       if( distanceBetween < get_cvar_num("dukenukem_radius") )
       {
         multiplier=get_cvar_num("dukenukem_maxdamage")*get_cvar_num("dukenukem_maxdamage")/get_cvar_num("dukenukem_radius")
         damage=(get_cvar_num("dukenukem_radius")-distanceBetween)*multiplier
         damage=sqrt(damage)
         if ( a==id ) damage=100     
         shExtraDamage(a, id, damage, "Nukem Bomb")
       } // distance
     } // alive
   } // loop    
} 
//---------------------------------------------------------------------------------------------- 
public newRound(id) 
{ 
  gPlayerUltimateUsed[id]=false
  IsDukeBomb[id]=0
  return PLUGIN_HANDLED 
} 
//---------------------------------------------------------------------------------------------- 
// RESPOND TO KEYDOWN 
public dukenukem_kd() 
{ 
  new temp[6] 

  if ( !hasRoundStarted() ) return PLUGIN_HANDLED 

  // First Argument is an id with dukenukem Powers! 
  read_argv(1,temp,5) 
  new id=str_to_num(temp) 
  if ( !is_user_alive(id) ) return PLUGIN_HANDLED 

  debugMessage("dukenukem Power") 

  // Let them know they already used their ultimate if they have 
  if ( gPlayerUltimateUsed[id] ) 
  { 
    playSoundDenySelect(id) 
    return PLUGIN_HANDLED 
  } 

// Start Timer
  new DukeCooldown=get_cvar_num("dukenukem_cooldown")
  ultimateTimer(id, DukeCooldown * 1.0)
  gPlayerUltimateUsed[id]=true 

  new player = id 
  IsDukeBomb[player] = get_cvar_num("dukenukem_fuse") 
  return PLUGIN_HANDLED 
} 
//---------------------------------------------------------------------------------------------- 
public client_connect(id)
{ 
   IsDukeBomb[id] = 0 
   return PLUGIN_CONTINUE 
} 
//---------------------------------------------------------------------------------------------- 
public client_disconnect(id)
{ 
   IsDukeBomb[id] = 0 
   return PLUGIN_CONTINUE 
}
//----------------------------------------------------------------------------------------------