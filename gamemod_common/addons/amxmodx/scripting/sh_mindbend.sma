#include <amxmod.inc>
#include <xtrafun>
#include <superheromod.inc>

// Dr. Mindbender

// CVARS
// mindbender_level
// mindbender_cooldown  -- How long time between each time if is used

// VARIABLES
new gHeroName[]="Dr. Mindbender"
new bool:gHasMindbenderPowers[SH_MAXSLOTS+1]
new gSpriteLightning
//----------------------------------------------------------------------------------------------
public plugin_init()
{
  // Plugin Info
  register_plugin("SUPERHERO Dr. Mindbender","1.14.4","Necroscope")
 
  // FIRE THE EVENT TO CREATE THIS SUPERHERO!
  if ( isDebugOn() ) server_print("Attempting to create Mindbender")
  register_cvar("mindbender_level", "5" )
  shCreateHero(gHeroName, "Mental Control", "Make player switch to knife", false, "mindbender_level" )
  
  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
  // INIT
  register_srvcmd("mindbender_init", "mindbender_init")
  shRegHeroInit(gHeroName, "mindbender_init")
  // GET MORE GUNZ!
  register_event("ResetHUD","newRound","b")
  register_event("Damage", "mindbender_damage", "b", "2!0")

  // DEFAULT THE CVARS
  register_cvar("mindbender_cooldown", "15" )
  register_cvar("mindbender_stuntime", "5" )
  register_cvar("mindbender_stunspeed", "50" )
} 
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
  precache_sound("ambience/deadsignal1.wav")
  gSpriteLightning = precache_model("sprites/lgtning.spr")
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
  gPlayerUltimateUsed[id]=false
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public mindbender_init()
{
  new temp[128]
  // First Argument is an id
  read_argv(1,temp,5)
  new id=str_to_num(temp)
  
  // 2nd Argument is 0 or 1 depending on whether the id has wolverine skills
  read_argv(2,temp,5)
  new hasPowers=str_to_num(temp)

  if ( hasPowers )
   gHasMindbenderPowers[id]=true
  else
   gHasMindbenderPowers[id]=false  
}
//----------------------------------------------------------------------------------------------
public mindbender_damage(id)
{
  if (!shModActive() || !gHasMindbenderPowers[id] || gPlayerUltimateUsed[id] ) return PLUGIN_CONTINUE

  new damage = read_data(2)
  new weapon, bodypart, attacker = get_user_attacker(id,weapon,bodypart)
  
  if ( is_user_alive(id) && id != attacker )
  {
    // Start Timer
    new MindbenderCooldown=get_cvar_num("mindbender_cooldown")
    ultimateTimer(id, MindbenderCooldown * 1.0)
    // Forceweapon Switch
    playSound(id)
    playSound(attacker)
    mindbender_switch(id,attacker)
  }
  setScreenFlash(attacker, 200, 200, 200, 10, damage )  //Screen Flash
    
  return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public mindbender_switch(id,victim)
{ 
  new name[32]
  new BenderStunTime=get_cvar_num("mindbender_stuntime")
  new BenderStunSpeed=get_cvar_num("mindbender_stunspeed")
  lightning_effect(id, victim, 10)
  engclient_cmd(victim,"weapon_knife")
  shStun(victim, BenderStunTime)
  set_user_maxspeed(victim, BenderStunSpeed * 1.0)
  
  get_user_name(victim,name,31)
}
//----------------------------------------------------------------------------------------------
public lightning_effect(id, targetid, linewidth)
{
  	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( 8 );
	write_short(id);	// start entity
	write_short(targetid);	// entity
	write_short(gSpriteLightning );	// model
	write_byte( 0 ); // starting frame
	write_byte( 15 );  // frame rate
	write_byte( 8 );  // life
	write_byte( linewidth );  // line width
	write_byte( 10 );  // noise amplitude
	write_byte( 100 );	// r, g, b
	write_byte( 100 );	// r, g, b
	write_byte( 255 );	// r, g, b
	write_byte( 255 );	// brightness
	write_byte( 0 );	// scroll speed
	message_end();
}
//----------------------------------------------------------------------------------------------
public playSound(id)
{
  new parm[1]
  parm[0]=id
  
  emit_sound(id, CHAN_AUTO, "ambience/deadsignal1.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH)
  set_task(1.5,"stopSound", 0, parm, 1)
} 
//----------------------------------------------------------------------------------------------
public stopSound(parm[])
{
  new sndStop=(1<<5)
  emit_sound(parm[0], CHAN_AUTO, "ambience/deadsignal1.wav", 1.0, ATTN_NORM, sndStop, PITCH_NORM)
}
//----------------------------------------------------------------------------------------------