#include <amxmod.inc>
#include <superheromod.inc>
#include <amxmisc>

new gHeroName[]="Dreadnought"
new bool:gHasRocketPower[SH_MAXSLOTS+1]
new sprSmoke
new sprWhite
//----------------------------------------------------------------------------------------------
public plugin_init()
{
  // Plugin Info
  register_plugin("SUPERHERO Dreadnought","1.0","SRGrty")
 
  // FIRE THE EVENT TO CREATE THIS SUPERHERO!
  if (!cvar_exists("Rocket_level")) register_cvar("Rocket_level", "9" )
  shCreateHero(gHeroName, "Rocket", "Turn someone into a rocket to make them explode!", false, "Rocket_level" )

  // INIT
  register_srvcmd("Rocket_init", "Rocket_init")
  shRegHeroInit(gHeroName, "Rocket_init")
    
  register_event("ResetHUD","newRound","b")
  register_event("Damage", "Rocket_damage", "b", "2!0")
  
  // DEFAULT THE CVARS
  register_cvar("Rocket_cooldown", "300.0" )
  register_cvar("Rocket_health", "50" )
  register_cvar("Rocket_kill", "1" )
  register_cvar("Rocket_damage", "75" )
}
//----------------------------------------------------------------------------------------------
public plugin_precache()   {  
	sprSmoke = precache_model("sprites/steam1.spr")
	sprWhite = precache_model( "sprites/white.spr" )
	precache_sound("weapons/rocketfire1.wav")
	precache_sound("weapons/rocket1.wav")

	return PLUGIN_CONTINUE 
} 
//----------------------------------------------------------------------------------------------
public Rocket_init()
{
  new temp[128]
  // First Argument is an id
  read_argv(1,temp,5)
  new id=str_to_num(temp)
  
  // 2nd Argument is 0 or 1 depending on whether the id has Rocket powers
  read_argv(2,temp,5)
  new hasPower=str_to_num(temp)
  
  gHasRocketPower[id]=(hasPower!=0) 
}
//----------------------------------------------------------------------------------------------
public Rocket_damage(id)
{
  if (!shModActive()) return PLUGIN_CONTINUE

  new weapon, bodypart, attacker = get_user_attacker(id,weapon,bodypart)
    
  // Let them know they already used their ultimate if they have
  if ( gPlayerUltimateUsed[id]  || !gHasRocketPower[id] )
    return PLUGIN_HANDLED 

  if ( is_user_alive(id) && id != attacker )
  {
    // Start Timer
    new RocketCooldown=get_cvar_num("Rocket_cooldown")
    ultimateTimer(id, RocketCooldown * 1.0)
    Dread_rocket(id, attacker)
  }
    
  return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public Dread_rocket(id, victim)   {
	
	new origin[3], name[32] 
	set_user_gravity(victim,-0.50)
	get_user_origin(victim, origin)
	get_user_name(victim, name , 31) 
	origin[2] += 192 
	set_user_origin(victim, origin)
	emit_sound(victim, CHAN_VOICE, "weapons/rocket1.wav", 1.0, 0.5, 0, PITCH_NORM)

	
	if ( is_user_alive(victim) )   {   /*If user is alive create effects and user_kill */
		new vec1[3]
		get_user_origin(victim,vec1)
		
		// blast circles
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY, vec1 )
		write_byte( 21 )
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] + 16)
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] + 1936)
		write_short( sprWhite )
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
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
		write_byte( 12 )
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2])
		write_byte( 188 ) // byte (scale in 0.1's) 188
		write_byte( 10 ) // byte (framerate)
		message_end()
		
		//Smoke
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY, vec1 )
		write_byte( 5 ) // 5
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2])
		write_short( sprSmoke )
		write_byte( 10 )  // 2
		write_byte( 10 )  // 10
		message_end()
		new damage = get_cvar_num("Rocket_damage")
		if (get_cvar_num("Rocket_kill")==1){
		user_kill(victim,1)
		}else{
		user_slap(victim, damage)
		}
	}
			 
	
	//stop_sound
	emit_sound(victim, CHAN_VOICE, "weapons/rocket1.wav", 0.0, 0.0, (1<<5), PITCH_NORM)
	
	set_user_maxspeed(victim,1.0)	
	set_user_gravity(victim,1.00)

	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public newRound(id) 
{ 
  gPlayerUltimateUsed[id]=false
  if (gHasRocketPower[id]==true){
  set_user_health(id, get_user_health(id) - get_cvar_num("Rocket_health"))
  }
  return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------